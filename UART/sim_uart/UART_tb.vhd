-- UART_tb.vhd
-- Top-level loopback testbench for UART (simulation-only, do NOT register
-- it in UART.qsf). The two serial lines are wired together, so every frame
-- the master sends comes back on data_rx_buff. Two frames are checked with
-- a few asserts, in the same minimal style as the other sim_* testbenches.
--
-- NOTE: run it with a finite time (e.g. "run 6 us"), not "run -all":
-- the free-running clock keeps the simulation alive forever.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_UART is
end entity;                       -- a testbench has no ports

architecture sim of tb_UART is
    constant CLK_PERIOD : time := 20 ns;    -- 50 MHz reference clock
    constant BIT_PERIOD : time := 200 ns;   -- 10 clock cycles (divider = 10):
                                            -- divider/2 must exceed the 2-3
                                            -- clock latency of the RX input
                                            -- synchronizer
    constant C_DATA_BITS : positive := 4;
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal w : std_logic := '0';
    signal r : std_logic := '0';
    signal data_tx_buff : std_logic_vector(C_DATA_BITS - 1 downto 0) := (others => '0');
    signal data_line_rx : std_logic;
    signal tx_busy : std_logic;
    signal rx_busy : std_logic;
    signal rx_valid : std_logic;
    signal data_rx_buff : std_logic_vector(C_DATA_BITS - 1 downto 0);
    signal data_line_tx : std_logic;
    signal valid_cnt : integer := 0;

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
    dut : entity work.UART
        generic map (G_CLK_FREQ => 100, G_BAUD => 10, G_DATA_BITS => C_DATA_BITS)   -- divider = 10 = BIT_PERIOD / CLK_PERIOD
        port map (
            clk => clk, rst_n => rst_n,
            w => w, r => r,
            data_tx_buff => data_tx_buff,
            data_line_rx => data_line_rx,
            tx_busy => tx_busy, rx_busy => rx_busy,
            rx_valid => rx_valid, data_rx_buff => data_rx_buff,
            data_line_tx => data_line_tx
        );

    data_line_rx <= data_line_tx;           -- board-style loopback of the wire

    clk <= not clk after CLK_PERIOD / 2;    -- free-running clock

    mon : process(clk)                      -- count the rx_valid pulses
    begin
        if rising_edge(clk) then
            if rx_valid = '1' then
                valid_cnt <= valid_cnt + 1;
            end if;
        end if;
    end process;

    stim : process
    begin
        wait for 2 * CLK_PERIOD;
        rst_n <= '1';                       -- release reset (line idle high)
        r <= '1';                           -- arm the receiver (level, kept high)

        -- frame 1: 0xA
        data_tx_buff <= x"A";
        wait until rising_edge(clk);
        w <= '1';                           -- request transmission
        wait until rising_edge(clk);
        w <= '0';                           -- w is level-sensitive: one frame per pulse
        wait for 12 * BIT_PERIOD;           -- frame (10 bits) + margin
        assert data_rx_buff = x"A"
            report "ERROR frame 1: data_rx_buff = " & to_hex(data_rx_buff) &
                   ", expected A"
            severity error;

        -- frame 2: 0x5 (r still high: the RX re-arms automatically)
        data_tx_buff <= x"5";
        wait until rising_edge(clk);
        w <= '1';
        wait until rising_edge(clk);
        w <= '0';
        wait for 12 * BIT_PERIOD;
        assert data_rx_buff = x"5"
            report "ERROR frame 2: data_rx_buff = " & to_hex(data_rx_buff) &
                   ", expected 5"
            severity error;
        assert valid_cnt = 2
            report "ERROR: expected 2 rx_valid pulses, got " &
                   integer'image(valid_cnt)
            severity error;
        assert tx_busy = '0'
            report "ERROR: tx_busy still high at end of test"
            severity error;
        report "UART TB finished (2 frames looped back, last data_rx_buff = " &
               to_hex(data_rx_buff) & ")";
        wait;                               -- end of test
    end process;
end architecture;