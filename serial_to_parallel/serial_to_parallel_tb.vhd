library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_serial_to_parallel is
    generic (
        G_MSB_FIRST : boolean := false   -- sweep in the sim run: false and true
    );
end entity;                       -- a testbench has no ports

architecture sim of tb_serial_to_parallel is
    constant C_CLK_PERIOD : time := 20 ns;   -- 50 MHz reference clock
    constant C_DATA_BITS : positive := 4;

    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal shift : std_logic := '0';
    signal data_in : std_logic;
    signal data_out : std_logic_vector(C_DATA_BITS - 1 downto 0) := (others => '0');

    -- Which source bit to place on the wire for shift number bit_index.
    function bit_index_in(bit_index : natural) return natural is
    begin
        if G_MSB_FIRST then
            return C_DATA_BITS - 1 - bit_index;   -- MSB first: first shift = MSB
        else
            return bit_index;                      -- LSB first: first shift = bit 0
        end if;
    end function;

    -- VHDL-93/2002-friendly hex string for a small vector.
    function to_hex(slv : std_logic_vector) return string is
        constant HEX_CHARS : string(1 to 16) := "0123456789ABCDEF";
    begin
        return "" & HEX_CHARS(to_integer(unsigned(slv)) + 1);
    end function;

begin
    dut : entity work.serial_to_parallel(rtl)
        generic map (G_DATA_WIDTH => C_DATA_BITS, G_MSB_FIRST => G_MSB_FIRST)
        port map (clk => clk, rst_n => rst_n, shift => shift, data_in => data_in, data_out => data_out);

    clk <= not clk after C_CLK_PERIOD / 2;  -- free-running clock

    stim : process
        -- Feed bits in LSB-first or MSB-first order depending on G_MSB_FIRST,
        -- so the byte always reconstructs in its original form.
        procedure drive_byte(constant rx_byte : in std_logic_vector(C_DATA_BITS - 1 downto 0)) is
        begin
            for bit_index in 0 to C_DATA_BITS - 1 loop
                wait until rising_edge(clk);
                data_in <= rx_byte(bit_index_in(bit_index));
                wait until rising_edge(clk);
                shift <= '1';
                wait until rising_edge(clk);
                shift <= '0';
                wait for C_CLK_PERIOD;
            end loop;
        end procedure drive_byte;

    begin
        wait for 2 * C_CLK_PERIOD;
        rst_n <= '1';                       -- release reset

        drive_byte(x"A");                  -- 1010 is NOT palindromic -> catches reversal
        wait until rising_edge(clk);
        assert data_out = x"A"
            report "A mismatch: got " & to_hex(data_out)
            severity error;

        drive_byte(x"5");                  -- 0101 -> opposite, reconstructs only when fed in order
        wait until rising_edge(clk);
        assert data_out = x"5"
            report "5 mismatch: got " & to_hex(data_out)
            severity error;

        if G_MSB_FIRST then
            report "serial_to_parallel test passed (MSB first)" severity note;
        else
            report "serial_to_parallel test passed (LSB first)" severity note;
        end if;

        wait;                              -- end of test
    end process;
end architecture;

