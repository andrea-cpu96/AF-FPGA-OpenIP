library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_parallel_to_serial is
    generic (
        G_MSB_FIRST : boolean := false   -- sweep in the sim run: false and true
    );
end entity;                       -- a testbench has no ports

architecture sim of tb_parallel_to_serial is
    constant C_CLK_PERIOD : time := 20 ns;   -- 50 MHz reference clock
    constant C_DATA_BITS : positive := 4;

    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal shift : std_logic := '0';
    signal load : std_logic := '0';
    signal data_in : std_logic_vector(C_DATA_BITS - 1 downto 0) := (others => '0');
    signal data_out : std_logic;

    -- index of the byte bit expected on the wire for shift number bit_index
    function bit_index_out(bit_index : natural) return natural is
    begin
        if G_MSB_FIRST then
            return C_DATA_BITS - 1 - bit_index;
        else
            return bit_index;
        end if;
    end function;
begin
    dut : entity work.parallel_to_serial
        generic map (G_DATA_WIDTH => C_DATA_BITS, G_MSB_FIRST => G_MSB_FIRST)
        port map (clk => clk, rst_n => rst_n, shift => shift, load => load, data_in => data_in, data_out => data_out);

    clk <= not clk after C_CLK_PERIOD / 2;  -- free-running clock

    stim : process
    begin
        wait for 2 * C_CLK_PERIOD;
        rst_n <= '1';                       -- release reset
        data_in <= x"A";

        wait until rising_edge(clk);        -- DUT captures data_in on rising edge of clk
        load <= '1';

        wait until rising_edge(clk);
        load <= '0';

        wait until rising_edge(clk);
        for bit_index in 0 to C_DATA_BITS - 1 loop
            assert data_out = data_in(bit_index_out(bit_index))
                report "unexpected serial bit at index " & integer'image(bit_index)
                severity error;

            shift <= '1';
            wait until rising_edge(clk);
            shift <= '0';

            wait for 2 * C_CLK_PERIOD;
        end loop;

        if G_MSB_FIRST then
            report "parallel_to_serial test passed (MSB first)" severity note;
        else
            report "parallel_to_serial test passed (LSB first)" severity note;
        end if;

        wait;                              -- end of test
    end process;
end architecture;