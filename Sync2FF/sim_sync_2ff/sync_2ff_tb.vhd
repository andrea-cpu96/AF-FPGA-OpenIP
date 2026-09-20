-- sync_2ff_tb.vhd
-- Self-checking testbench for sync_2ff.
--
-- async_in is driven asynchronously (changes at falling edges and at
-- off-edge offsets), so every value is settled well before the sampling
-- rising edge (zero-delay RTL sim: no setup/hold modelling). The clocked
-- monitor records async_in at every rising edge — the same edge the DUT
-- samples it — and, since the DUT has a fixed 2-cycle latency, checks
-- two edges later that sync_out matches:
--   1. power-up value '0' on the first edges (template init), input quiet
--   2. constant 2-edge latency for every asynchronous transition
--   3. full pattern-tracking over a long deterministic pseudorandom
--      toggle sequence (LFSR-driven, intervals 2..5 clocks, off-edge)
--
-- Metastability itself cannot be produced in a zero-delay RTL simulation:
-- this TB verifies functionality and latency only.
--
-- Simulation-only file: do NOT register it in any Quartus .qsf.

library ieee;
use ieee.std_logic_1164.all;

entity sync_2ff_tb is
end entity sync_2ff_tb;

architecture sim of sync_2ff_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal sim_done : boolean := false;

    -- DUT interface
    signal clk      : std_logic := '0';
    signal async_in : std_logic := '0';
    signal sync_out : std_logic;

    -- checker -> summary
    signal errors : natural := 0;

begin

    ---------------------------------------------------------------
    -- DUT
    ---------------------------------------------------------------
    dut : entity work.sync_2ff
        port map (
            clk      => clk,
            async_in => async_in,
            sync_out => sync_out
        );

    ---------------------------------------------------------------
    -- Clock generation (stops when sim_done)
    ---------------------------------------------------------------
    clk <= not clk after CLK_PERIOD / 2 when not sim_done else '0';

    ---------------------------------------------------------------
    -- Stimulus (asynchronous input driver)
    ---------------------------------------------------------------
    stim : process
        -- 8-bit LFSR: deterministic pseudorandom value source
        variable lfsr : std_logic_vector(7 downto 0) := "10110001";
        variable fb   : std_logic;
    begin
        -- stage 1: input quiet at '0' — sync_out must power up '0'
        wait for 4 * CLK_PERIOD;

        -- stage 2: asynchronous raise/lower at off-edge offsets
        wait until falling_edge(clk);
        wait for 3.7 ns;                        -- mid low-phase change
        async_in <= '1';
        wait for 3 * CLK_PERIOD + 1.3 ns;
        async_in <= '0';
        wait for 2 * CLK_PERIOD + 2.1 ns;
        async_in <= '1';
        wait for 5 * CLK_PERIOD;

        -- stage 3: pseudorandom toggles, hold 2..5 clocks, off-edge
        for i in 1 to 60 loop
            fb   := lfsr(7) xor lfsr(5) xor lfsr(4) xor lfsr(3);
            lfsr := fb & lfsr(7 downto 1);
            async_in <= lfsr(0);
            wait for (2 + (i mod 4)) * CLK_PERIOD + 0.9 ns;
        end loop;

        -- let the last transition propagate through the chain
        wait for 4 * CLK_PERIOD;

        -- summary
        sim_done <= true;
        wait for CLK_PERIOD;
        if errors = 0 then
            report "=====================================================" severity note;
            report " SYNC_2FF TEST PASSED - 0 errors" severity note;
            report "=====================================================" severity note;
        else
            report "=====================================================" severity error;
            report " SYNC_2FF TEST FAILED - " &
                   integer'image(errors) & " error(s)" severity error;
            report "=====================================================" severity error;
        end if;
        wait;                              -- end of test
    end process;

    ---------------------------------------------------------------
    -- Self-checking monitor (clocked, like the DUT)
    ---------------------------------------------------------------
    -- All comparisons use pre-edge values: at edge N, sync_out is the
    -- value registered at edge N-1, i.e. async_in as sampled at edge
    -- N-2 (fixed 2-cycle latency). d1/d2 keep the async_in history.
    monitor : process(clk)
        variable n  : natural   := 0;   -- rising edges seen
        variable d1 : std_logic := '0'; -- async_in sampled 1 edge ago
        variable d2 : std_logic := '0'; -- async_in sampled 2 edges ago
    begin
        if rising_edge(clk) then
            n := n + 1;

            if sync_out /= d2 then
                report "ERROR: sync_out mismatch at edge " &
                       integer'image(n) &
                       " (sync_out = " & std_logic'image(sync_out) &
                       ", expected = " & std_logic'image(d2) &
                       " = async_in sampled 2 edges earlier)"
                    severity error;
                errors <= errors + 1;
            end if;

            d2 := d1;
            d1 := async_in;
        end if;
    end process;

end architecture sim;
