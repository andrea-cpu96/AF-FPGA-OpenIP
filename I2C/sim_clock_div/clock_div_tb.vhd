-- clock_div_tb.vhd
-- Self-checking testbench for clock_div.
--
-- Verifies, by sampling on rising edges (same convention as the DUT; the
-- monitor sees clk_out as it was set by the PREVIOUS edge):
--   1. clk_out period == G_DIVIDER clock cycles (rise-to-rise)
--   2. high phase == (G_DIVIDER+1)/2 cycles, so the period stays exact
--      for odd dividers too
--   3. one cycle after rst_n = '0' or enable = '0', clk_out is low and
--      stays low for the whole gated window (a high run cut short by a
--      gate is legitimate truncation and is not width-checked)
--   4. phase restart: after any gated window, clk_out rises at exactly
--      the G_DIVIDER-th enabled edge after the release edge
--   5. all re-verified after a mid-run reset and a mid-run enable drop
--
-- G_DIVIDER is a testbench generic: sim_run.do sweeps it over 2 (minimum
-- divider), 4 (even) and 5 (odd).
--
-- Simulation-only file: do NOT register it in I2C_Master.qsf.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_div_tb is
    generic (
        G_DIVIDER : natural range 2 to natural'high := 4
    );
end entity clock_div_tb;

architecture sim of clock_div_tb is

    constant CLK_PERIOD  : time := 10 ns;
    constant HIGH_CYCLES : natural := (G_DIVIDER + 1) / 2;
    constant C_STEADY    : natural := 2 * G_DIVIDER + 4;   -- >= 2 full periods

    signal sim_done : boolean := false;

    -- DUT interface
    signal clk     : std_logic := '0';
    signal rst_n   : std_logic := '0';
    signal enable  : std_logic := '1';
    signal clk_out : std_logic;

    -- checker -> summary
    signal errors : natural := 0;

begin

    ---------------------------------------------------------------
    -- DUT
    ---------------------------------------------------------------
    dut : entity work.clock_div
        generic map (
            G_DIVIDER => G_DIVIDER
        )
        port map (
            clk     => clk,
            rst_n   => rst_n,
            enable  => enable,
            clk_out => clk_out
        );

    ---------------------------------------------------------------
    -- Clock generation (stops when sim_done)
    ---------------------------------------------------------------
    clk <= not clk after CLK_PERIOD / 2 when not sim_done else '0';

    ---------------------------------------------------------------
    -- Stimulus
    ---------------------------------------------------------------
    stim : process
    begin
        -- stage 1: power-up reset held, then released
        rst_n  <= '0';
        enable <= '1';
        wait for 4 * CLK_PERIOD;
        wait until falling_edge(clk);
        rst_n <= '1';
        wait for C_STEADY * CLK_PERIOD;

        -- stage 2: mid-run reset
        wait until falling_edge(clk);
        rst_n <= '0';
        wait for 3 * CLK_PERIOD;
        wait until falling_edge(clk);
        rst_n <= '1';
        wait for C_STEADY * CLK_PERIOD;

        -- stage 3: enable gating (output parks low, phase restarts)
        wait until falling_edge(clk);
        enable <= '0';
        wait for 3 * CLK_PERIOD;
        wait until falling_edge(clk);
        enable <= '1';
        wait for C_STEADY * CLK_PERIOD;

        -- summary
        wait for 2 * CLK_PERIOD;
        sim_done <= true;
        wait for CLK_PERIOD;
        if errors = 0 then
            report "=====================================================" severity note;
            report " CLOCK_DIV TEST PASSED (G_DIVIDER = " &
                   integer'image(G_DIVIDER) & ") - 0 errors" severity note;
            report "=====================================================" severity note;
        else
            report "=====================================================" severity error;
            report " CLOCK_DIV TEST FAILED (G_DIVIDER = " &
                   integer'image(G_DIVIDER) & ") - " &
                   integer'image(errors) & " error(s)" severity error;
            report "=====================================================" severity error;
        end if;
        wait;                              -- end of test
    end process;

    ---------------------------------------------------------------
    -- Self-checking monitor (clocked, like the DUT)
    ---------------------------------------------------------------
    -- All comparisons use pre-edge values: rst_n/enable/clk_out as they
    -- were just before the edge, i.e. clk_out as set by the previous edge.
    monitor : process(clk)
        variable n           : natural  := 0;    -- enabled edges since release
        variable run_len     : natural  := 0;    -- consecutive high samples
        variable run_open    : boolean  := false;
        variable first_rise  : boolean  := true; -- no rise checked since release
        variable last_rise_n : natural  := 0;
        variable prev_gated  : boolean  := true; -- sim starts in reset
        variable gated       : boolean;
    begin
        if rising_edge(clk) then
            gated := (rst_n = '0') or (enable = '0');

            if gated then
                -- once gated, the output must be parked low
                if prev_gated and clk_out /= '0' then
                    report "ERROR: clk_out high while gated (rst_n/enable low)"
                        severity error;
                    errors <= errors + 1;
                end if;
                if run_open then
                    run_open := false;  -- high run truncated by the gate: legal
                end if;
                n := 0;                 -- the release edge re-arms the phase
                first_rise := true;
            else
                n := n + 1;             -- this is enabled edge #n

                if clk_out = '1' then
                    if not run_open then
                        -- first high sample of a run: rising edge of clk_out
                        if first_rise then
                            -- the DUT raises clk_out at the G_DIVIDER-th
                            -- enabled edge; the monitor sees it one edge later
                            if n /= G_DIVIDER + 1 then
                                report "ERROR: first clk_out rising edge at " &
                                       "enabled edge " & integer'image(n) &
                                       ", expected " &
                                       integer'image(G_DIVIDER + 1)
                                    severity error;
                                errors <= errors + 1;
                            end if;
                            first_rise := false;
                        else
                            if n - last_rise_n /= G_DIVIDER then
                                report "ERROR: clk_out period " &
                                       integer'image(n - last_rise_n) &
                                       " cycles, expected " &
                                       integer'image(G_DIVIDER)
                                    severity error;
                                errors <= errors + 1;
                            end if;
                        end if;
                        last_rise_n := n;
                        run_open := true;
                        run_len  := 1;
                    else
                        run_len := run_len + 1;
                    end if;
                else
                    if run_open then
                        -- the DUT itself ended the high run
                        if run_len /= HIGH_CYCLES then
                            report "ERROR: high phase " &
                                   integer'image(run_len) &
                                   " cycles, expected " &
                                   integer'image(HIGH_CYCLES)
                                severity error;
                            errors <= errors + 1;
                        end if;
                        run_open := false;
                    end if;
                end if;
            end if;

            prev_gated := gated;
        end if;
    end process;

end architecture sim;