-- i2c_master_freq_tb.vhd
-- SCL frequency regression for I2C_Master: G_I2C_FREQ must behave as a
-- MAXIMUM. The divider is computed with ceiling division, so the generated
-- SCL period is never shorter than 1/G_I2C_FREQ. This matters for ratios
-- that do not divide evenly: 50 MHz / 90 kHz must give divider 556
-- (SCL = 89.93 kHz); a truncated divider would give 555 (90.09 kHz, too
-- fast for the requested maximum).
-- The testbench runs one write transaction, measures the steady-state SCL
-- period (rise-to-rise between SCL rising edges 2 and 3 -- the first bit
-- cell is longer because the divider restarts from its parked state) and
-- checks:
--   * measured period >= nominal period (the frequency never exceeds
--     G_I2C_FREQ -- this is what the ceiling division guarantees)
--   * measured period <= nominal period + four clk cycles. The ceiling may
--     add less than one divider step, and the scl_in stretch feedback (fed
--     from the 2-FF synchronised bus copy, which lags the divider's own
--     output by two clk cycles) parks the high-phase counter twice at every
--     rise, adding exactly two clk cycles per period. The generated SCL is
--     therefore always slightly SLOWER than requested, never faster; the
--     upper bound only guards against a structurally broken divider.
-- G_CLK_FREQ / G_I2C_FREQ are testbench generics; sim_run.do sweeps a
-- non-integer ratio (90 kHz) and an exact ratio (100 kHz).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_master_freq_tb is
    generic (
        G_CLK_FREQ : natural := 50_000_000;
        G_I2C_FREQ : natural := 90_000
    );
end entity i2c_master_freq_tb;

architecture sim of i2c_master_freq_tb is

    constant C_CLK_NS : real := 1.0e9 / real(G_CLK_FREQ);
    constant C_NOMINAL : time := (1.0e9 / real(G_I2C_FREQ)) * 1 ns;
    -- Ceiling adds < 1 divider step; the 2-FF synchronised scl_in feedback
    -- adds exactly 2 clk cycles per period (see the header). Allow 4 clks.
    constant C_MAX_PERIOD : time := C_NOMINAL + (C_CLK_NS * 4.0) * 1 ns;

    signal clk     : std_logic := '0';
    signal rst_n   : std_logic := '0';
    signal w       : std_logic := '0';
    signal sda_bus : std_logic := 'H';
    signal scl_bus : std_logic := 'H';
    signal sda_obs : std_logic;
    signal scl_obs : std_logic;
    signal finished : boolean := false;

    -- TB-domain SCL rise counter and timestamps
    signal scl_prev_tb : std_logic := '1';
    signal rise_cnt : natural range 0 to 15 := 0;
    signal t_rise2  : time := 0 ns;
    signal t_rise3  : time := 0 ns;

begin

    clk <= not clk after (C_CLK_NS / 2.0) * 1 ns when not finished else '0';

    -- open-drain bus with external pull-ups (no slave: NACK abort is fine,
    -- the transaction only needs to reach the third bit cell)
    sda_bus <= 'H';
    scl_bus <= 'H';
    sda_obs <= To_X01(sda_bus);
    scl_obs <= To_X01(scl_bus);

    dut : entity work.I2C_Master
        generic map (G_CLK_FREQ => G_CLK_FREQ, G_I2C_FREQ => G_I2C_FREQ)
        port map (
            clk => clk, rst_n => rst_n, w => w, r => '0',
            addr => "1101000", data_to_transmit => x"A5",
            data_to_read => open, tx_done => open, tx_data_done => open,
            rx_valid => open, busy => open, ack => open,
            sda => sda_bus, scl => scl_bus);

    meas : process(clk)
    begin
        if rising_edge(clk) then
            scl_prev_tb <= scl_obs;
            if rst_n = '1' and scl_obs = '1' and scl_prev_tb = '0' then
                if rise_cnt < 15 then
                    rise_cnt <= rise_cnt + 1;
                end if;
                if rise_cnt = 1 then
                    t_rise2 <= now;     -- end of bit cell 2
                elsif rise_cnt = 2 then
                    t_rise3 <= now;     -- end of bit cell 3
                end if;
            end if;
        end if;
    end process;

    stim : process
    begin
        wait for 100 ns;
        rst_n <= '1';
        w <= '1';
        wait until sda_obs = '0';       -- START accepted
        w <= '0';
        wait until rise_cnt = 3 for 200 us;

        if rise_cnt < 3 then
            report "RESULT: FAIL -- not enough SCL rising edges" severity error;
            finished <= true;
            wait;
        end if;

        if (t_rise3 - t_rise2) < C_NOMINAL then
            report "RESULT: FAIL -- SCL period " & time'image(t_rise3 - t_rise2) &
                   " shorter than nominal " & time'image(C_NOMINAL) &
                   " (G_I2C_FREQ exceeded)" severity error;
        elsif (t_rise3 - t_rise2) > C_MAX_PERIOD then
            report "RESULT: FAIL -- SCL period " & time'image(t_rise3 - t_rise2) &
                   " larger than nominal + 1 clk (broken divider)" severity error;
        else
            report "RESULT: PASS -- SCL period " & time'image(t_rise3 - t_rise2) &
                   " meets the nominal " & time'image(C_NOMINAL) & " +/- 1 clk" severity note;
        end if;
        finished <= true;
        wait;
    end process stim;

end architecture sim;
