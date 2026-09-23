-- scl_stretch_tb.vhd
-- Self-checking testbench for scl_stretch, the clock-stretching generator.
--
-- G_STRETCH_CYCLES is a testbench generic (sim_run.do sweeps it):
--   * 0   -- feature compiled out: a trigger must never pull the line low
--   * 1   -- minimum hold (one clk period)
--   * 4   -- short hold, measured cycle-exactly
--   * 500 -- the length the I2C_Slave uses by default
--
-- Checks (a read-only monitor counts the clk periods the request is high):
--   1. reset: idle, no request
--   2. trigger -> request high for EXACTLY G_STRETCH_CYCLES clk periods
--   3. a trigger during a running hold is ignored (the hold is not restarted)
--      -- checked from G_STRETCH_CYCLES >= 4 up, the shortest hold a second
--      pulse can still land inside
--   4. the generator re-arms: a later trigger produces a second, equally long
--      hold
--   5. release is clean: `active` tracks `scl_low` and both fall together
--
-- Simulation-only file: do NOT register it in Scl_Stretch's project.

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity scl_stretch_tb is
    generic (
        G_STRETCH_CYCLES : natural := 4
    );
end entity scl_stretch_tb;

architecture sim of scl_stretch_tb is

    constant C_CLK_PERIOD : time    := 20 ns;
    constant C_SETTLE     : natural := 4;

    signal clk       : std_logic := '0';
    signal rst_n     : std_logic := '0';
    signal stretch   : std_logic := '0';
    signal scl_low   : std_logic;
    signal active    : std_logic;
    signal finished  : boolean := false;

    -- Monitor bookkeeping
    signal hold_cnt  : natural := 0;   -- clk periods seen with scl_low high
    signal holds     : natural := 0;   -- completed holds

    file results : text open write_mode is "results.txt";

begin

    clk <= not clk after C_CLK_PERIOD / 2 when not finished else '0';

    dut : entity work.scl_stretch
        generic map (
            G_STRETCH_CYCLES => G_STRETCH_CYCLES
        )
        port map (
            clk     => clk,
            rst_n   => rst_n,
            stretch => stretch,
            scl_low => scl_low,
            active  => active
        );

    -- Read-only watcher: counts the periods the pull-down request is active and
    -- the number of complete holds it has seen.
    monitor : process(clk)
        variable was_high : boolean := false;
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                hold_cnt <= 0;
                holds    <= 0;
                was_high := false;
            else
                if scl_low = '1' then
                    hold_cnt <= hold_cnt + 1;
                    was_high := true;
                elsif was_high then
                    holds    <= holds + 1;
                    was_high := false;
                end if;

                -- `active` is the status copy of the request: they never differ.
                if active /= scl_low then
                    report "ERROR: active does not track scl_low" severity error;
                end if;
            end if;
        end if;
    end process;

    stim : process
        variable L   : line;
        variable ok  : boolean := true;
        variable cnt : natural := 0;
        variable exp_holds : natural := 2;   -- holds the monitor must have seen

        procedure clk_ticks (constant n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        -- One-clk trigger pulse, applied between clk edges.
        procedure trigger is
        begin
            wait until falling_edge(clk);
            stretch <= '1';
            wait until falling_edge(clk);
            stretch <= '0';
        end procedure;

        procedure check (condition : boolean; message : string) is
        begin
            if not condition then
                ok := false;
                write(L, string'("FAIL: "));
                write(L, message);
                writeline(results, L);
            end if;
        end procedure;
    begin
        stretch <= '0';
        rst_n   <= '0';
        clk_ticks(5);
        rst_n <= '1';
        clk_ticks(5);

        -- 1. idle after reset
        check(scl_low = '0', "scl_low high after reset");
        check(active  = '0', "active high after reset");
        check(hold_cnt = 0, "hold counted after reset");

        if G_STRETCH_CYCLES = 0 then
            -- 0: the feature is compiled out -- a trigger is simply ignored.
            trigger;
            clk_ticks(20);
            check(scl_low = '0', "scl_low rose although the feature is disabled");
            check(hold_cnt = 0, "hold generated although the feature is disabled");
            check(holds = 0, "hold completed although the feature is disabled");
        else
            -- 2. one trigger -> a hold of exactly G_STRETCH_CYCLES periods
            cnt := hold_cnt;
            trigger;
            clk_ticks(G_STRETCH_CYCLES + C_SETTLE);
            check(hold_cnt - cnt = G_STRETCH_CYCLES,
                  "hold length differs from G_STRETCH_CYCLES");
            check(scl_low = '0', "request not released at the end of the hold");

            -- 3. trigger during a running hold: the hold is not restarted.
            --    A second one-clk pulse can only land inside the hold when the
            --    hold is longer than the pulse spacing, so this sub-test is
            --    only meaningful from G_STRETCH_CYCLES >= 4 up.
            if G_STRETCH_CYCLES >= 4 then
                exp_holds := 3;
                cnt := hold_cnt;
                trigger;
                clk_ticks(2);
                trigger;                        -- ignored: already holding
                clk_ticks(G_STRETCH_CYCLES + C_SETTLE);
                check(hold_cnt - cnt = G_STRETCH_CYCLES,
                      "a trigger during a hold restarted the hold");
            end if;

            -- 4. re-arm: a later trigger gives another equally long hold
            cnt := hold_cnt;
            trigger;
            clk_ticks(G_STRETCH_CYCLES + C_SETTLE);
            check(hold_cnt - cnt = G_STRETCH_CYCLES,
                  "second hold length differs from G_STRETCH_CYCLES");

            -- 5. every hold generated so far is complete and counted
            check(holds = exp_holds, "completed hold count");
        end if;

        -- Summary
        if ok then
            write(L, string'("RESULT: PASS -- hold length exact (G_STRETCH_CYCLES = "));
            write(L, G_STRETCH_CYCLES);
            write(L, string'("), re-armed, no restart while running"));
        else
            write(L, string'("RESULT: FAIL"));
        end if;
        writeline(results, L);
        if ok then
            report "RESULT: PASS -- clock stretching hold length verified"
                severity note;
        else
            report "RESULT: FAIL -- see results.txt" severity error;
        end if;
        finished <= true;
        wait;
    end process;

end architecture sim;

