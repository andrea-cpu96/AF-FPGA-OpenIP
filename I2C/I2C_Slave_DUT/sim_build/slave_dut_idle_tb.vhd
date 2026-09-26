-- slave_dut_idle_tb.vhd
-- Power-up / idle guard for the 4-pin I2C_Slave_DUT wrapper (clk, rst_n, sda,
-- scl only). With NO controller on the bus nothing may ever happen: an I2C
-- target only drives a line while a frame addressed to it is running, so both
-- lines must sit at the testbench pull-up level for the whole run -- including
-- through reset and across a mid-run reset pulse.
-- Checks:
--   * during reset: no line is driven
--   * 100 us after the reset release: SDA and SCL never leave the pull-up level
--     (sampled every clk, so a one-clk glitch would be caught too)
--   * a 1 us reset pulse in the middle of the idle window: the DUT comes back
--     with both lines released and stays silent for another 50 us
-- Simulation-only file: do NOT register it in I2C_Slave_DUT.qsf.

library ieee;
use ieee.std_logic_1164.all;

entity slave_dut_idle_tb is
end entity slave_dut_idle_tb;

architecture sim of slave_dut_idle_tb is

    constant C_CLK_PERIOD : time := 20 ns;   -- 50 MHz

    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';

    -- I2C bus with external pull-ups (testbench-side). The DUT is wired through
    -- its 4 pins and nothing else.
    signal sda : std_logic := 'H';
    signal scl : std_logic := 'H';

    -- clk samples in which a line was not at the pull-up level
    signal low_samples : natural := 0;

    signal finished : boolean := false;

begin

    clk <= not clk after C_CLK_PERIOD / 2 when not finished else '0';

    sda <= 'H';
    scl <= 'H';

    dut : entity work.I2C_Slave_DUT
        generic map (
            G_SLAVE_ADDR     => "0111100",
            G_CLK_FREQ       => 50_000_000,
            G_I2C_FREQ       => 100_000,
            G_STRETCH_CYCLES => 500
        )
        port map (
            clk   => clk,
            rst_n => rst_n,
            sda   => sda,
            scl   => scl
        );

    bus_monitor : process(clk)
    begin
        if rising_edge(clk) then
            if To_X01(sda) /= '1' or To_X01(scl) /= '1' then
                low_samples <= low_samples + 1;
            end if;
        end if;
    end process;

    stim : process
        variable ok : boolean := true;
    begin
        -- Reset: the open-drain drivers must be released, not driven low.
        rst_n <= '0';
        wait for 500 ns;
        if low_samples /= 0 then
            ok := false;
            report "FAIL: a bus line was driven while reset was asserted" severity error;
        end if;

        -- Nobody addresses the DUT: it must not touch the bus at all.
        rst_n <= '1';
        wait for 100 us;
        if low_samples /= 0 then
            ok := false;
            report "FAIL: the DUT moved a bus line with no controller on the bus" severity error;
        end if;

        -- Mid-run reset pulse: back to the released idle state, still silent.
        rst_n <= '0';
        wait for 1 us;
        rst_n <= '1';
        wait for 50 us;
        if low_samples /= 0 then
            ok := false;
            report "FAIL: the DUT moved a bus line after a mid-run reset pulse" severity error;
        end if;

        if ok then
            report "RESULT: PASS -- 4-pin I2C_Slave_DUT releases both lines and never drives an un-addressed bus"
                severity note;
        else
            report "RESULT: FAIL" severity error;
        end if;

        finished <= true;
        wait;
    end process;

    watchdog : process
    begin
        wait for 500 us;
        if not finished then
            report "slave_dut_idle_tb timed out" severity failure;
        end if;
        wait;
    end process;

end architecture sim;
