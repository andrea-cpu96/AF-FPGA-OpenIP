-- UART_RX_tb.vhd
-- Simple serial-frame testbench for UART_RX (simulation-only, do NOT
-- register it in UART.qsf). Drives one 8N1 frame (0xA5, LSB first) on the
-- serial line and checks rx_busy / rx_valid / data_rx with a few asserts.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_UART_RX is
end entity;

architecture sim of tb_UART_RX is
    constant CLK_PERIOD : time := 20 ns;    -- 50 MHz reference clock
    constant BIT_PERIOD : time := 200 ns;   -- 10 clock cycles (divider = 10):
                                            -- divider/2 must exceed the 2-3
                                            -- clock latency of the RX input
                                            -- synchronizer (real dividers,
                                            -- e.g. 434, have ample margin)
    constant C_DATA_BITS : positive := 4;
    constant DATA_BYTE  : std_logic_vector(C_DATA_BITS - 1 downto 0) := x"A";
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal r : std_logic := '0';            -- receive request (arms the RX)
    signal data_in : std_logic := '1';      -- serial line, idle high
    signal rx_valid : std_logic;
    signal data_rx : std_logic_vector(C_DATA_BITS - 1 downto 0);
    signal rx_busy : std_logic;
    signal valid_seen : boolean := false;
    signal busy_seen : boolean := false;

    -- Simple hex-style formatter for a small configurable word.
    function to_hex(slv : std_logic_vector) return string is
        variable value : natural := 0;
    begin
        if slv'length = 0 then
            return "";
        end if;
        value := to_integer(unsigned(slv));
        return integer'image(value);
    end function;
begin
    dut : entity work.UART_RX
        generic map (G_CLK_FREQ => 100, G_BAUD => 10, G_DATA_BITS => C_DATA_BITS)
        port map (clk => clk, rst_n => rst_n, r => r, data_in => data_in,
                  rx_valid => rx_valid, data_rx => data_rx, rx_busy => rx_busy);

    clk <= not clk after CLK_PERIOD / 2;    -- free-running clock

    -- capture the RX status pulses
    mon : process(clk)
    begin
        if rising_edge(clk) then
            if rx_valid = '1' then
                valid_seen <= true;
            end if;
            if rx_busy = '1' then
                busy_seen <= true;
            end if;
        end if;
    end process;

    stim : process
    begin
        wait for 2 * CLK_PERIOD;
        rst_n <= '1';                       -- release reset (line idle high)

        wait until rising_edge(clk);
        r <= '1';                           -- arm the receiver
        wait until rising_edge(clk);
        r <= '0';                           -- RX now in WAIT_START_BIT

        -- 5 idle cycles before the start bit: the RX re-arms its tick phase
        -- on the detected (synchronized) start edge, so any gap length is
        -- legal -- the 2-3 clock delay of the input synchronizer is absorbed
        -- by the re-sync itself.
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- 8N1 frame on the serial line, one bit per BIT_PERIOD
        data_in <= '0';                     -- start bit
        wait for BIT_PERIOD;
        for i in 0 to C_DATA_BITS - 1 loop
            data_in <= DATA_BYTE(i);        -- data bits, LSB first
            wait for BIT_PERIOD;
        end loop;
        data_in <= '1';                     -- stop bit
        wait for BIT_PERIOD;

        wait for 2 * BIT_PERIOD;            -- end of frame + margin

        assert busy_seen
            report "ERROR: rx_busy never asserted (frame not detected)"
            severity error;
        assert valid_seen
            report "ERROR: rx_valid pulse not seen at end of frame"
            severity error;
        assert data_rx = DATA_BYTE
            report "ERROR: data_rx = " & to_hex(data_rx) & ", expected " &
                   to_hex(DATA_BYTE)
            severity error;
        report "UART_RX TB finished (data_rx = " & to_hex(data_rx) & ")";
        wait;                               -- end of test
    end process;
end architecture;