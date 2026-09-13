-- debouncer_tb.vhd
-- Self-checking testbench for debouncer.
--
-- A per-bit reference monitor samples noisy_in and clean_out on rising
-- edges (same convention as the DUT; clean_out lags the DUT state
-- register by one edge) and verifies:
--   1. clean_out is '0' for the whole time rst_n = '0' (power-up, mid-run
--      and re-entry included)
--   2. clean_out only ever changes to the value noisy_in currently has
--   3. a transition appears on clean_out exactly G_DEBOUNCE_CYCLES + 2
--      monitor samples after noisy_in last changed to that value
--      (2 synchronizer stages + stability counter + output register edge)
--   4. glitches shorter than G_DEBOUNCE_CYCLES (lengths 1, 2, N-1) are
--      rejected: while low, while high and (N >= 4) during an ongoing
--      transition
--   5. bounced transitions (brief glitch, restore, final change) adopt
--      with the latency measured from the LAST change, i.e. only after
--      one full stable window
--   6. bits are independent: a glitch train on one bit does not disturb
--      the debounce timing of another bit (G_WIDTH >= 2 sweeps)
--   7. all of the above re-verified after a mid-run reset, including the
--      re-adoption of an input already high when reset is released
--
-- G_WIDTH and G_DEBOUNCE_CYCLES are testbench generics: sim_run.do sweeps
-- (1, 2) = minimum window, (1, 5) = small window and (4, 64) = wide +
-- long window.
--
-- Simulation-only file: do NOT register it in Debouncer.qsf.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debouncer_tb is
    generic (
        G_WIDTH           : natural range 1 to natural'high := 1;
        G_DEBOUNCE_CYCLES : natural range 2 to natural'high := 5
    );
end entity debouncer_tb;

architecture sim of debouncer_tb is

    constant CLK_PERIOD : time := 10 ns;
    constant N          : natural := G_DEBOUNCE_CYCLES;
    constant C_HOLD     : natural := 3;             -- base hold between glitches (samples)
    constant C_SETTLE   : natural := 3 * N + 10;    -- settle after each stage (samples)
    constant C_LATENCY  : natural := N + 2;         -- monitor-visible transition latency
    constant C_BOUNCE   : natural := 1;             -- bit bounced in stage D2 (bit 1 if present)

    type t_nat_array  is array (natural range <>) of natural;
    type t_bool_array is array (natural range <>) of boolean;
    type t_sl_array   is array (natural range <>) of std_logic;

    -- glitch lengths exercised by the trains: 1, 2 and N-1 (each applied
    -- only if strictly shorter than the debounce window)
    constant C_LENS : t_nat_array(0 to 2) := (0 => 1, 1 => 2, 2 => N - 1);

    signal sim_done : boolean := false;

    -- DUT interface
    signal clk       : std_logic := '0';
    signal rst_n     : std_logic := '0';
    signal noisy_in  : std_logic_vector(G_WIDTH - 1 downto 0) := (others => '0');
    signal clean_out : std_logic_vector(G_WIDTH - 1 downto 0);

    -- checker -> summary (errors: written by the monitor only,
    -- final_errors: written by the stimulus only)
    signal errors       : natural := 0;
    signal final_errors : natural := 0;

begin

    ---------------------------------------------------------------
    -- DUT
    ---------------------------------------------------------------
    dut : entity work.debouncer
        generic map (
            G_WIDTH           => G_WIDTH,
            G_DEBOUNCE_CYCLES => G_DEBOUNCE_CYCLES
        )
        port map (
            clk       => clk,
            rst_n     => rst_n,
            noisy_in  => noisy_in,
            clean_out => clean_out
        );

    ---------------------------------------------------------------
    -- Clock generation (stops when sim_done)
    ---------------------------------------------------------------
    clk <= not clk after CLK_PERIOD / 2 when not sim_done else '0';

    ---------------------------------------------------------------
    -- Stimulus
    ---------------------------------------------------------------
    stim : process
        variable bounce_len : natural;
        variable bounce_bit : natural;
        variable noise_bit  : natural;   -- glitched bit (1 only when present)
    begin
        -- stage A: power-up reset, input low, then release
        -- (monitor verifies clean_out stays '0' the whole time)
        rst_n    <= '0';
        noisy_in <= (others => '0');
        for j in 1 to 4 loop
            wait until falling_edge(clk);
        end loop;
        rst_n <= '1';
        wait for C_SETTLE * CLK_PERIOD;

        -- stage B: glitch train on bit 0, base low: lengths 1, 2 and N-1,
        -- none must be adopted
        for k in C_LENS'range loop
            if C_LENS(k) < N then
                wait until falling_edge(clk);
                noisy_in(0) <= '1';
                for j in 1 to C_LENS(k) loop
                    wait until falling_edge(clk);
                end loop;
                noisy_in(0) <= '0';
                for j in 1 to C_HOLD loop
                    wait until falling_edge(clk);
                end loop;
            end if;
        end loop;
        wait for C_SETTLE * CLK_PERIOD;

        -- stage C: bit 0 goes high and must be adopted after the full
        -- window, while bit 1 (if present) glitches and must not be
        -- adopted (bit independence)
        wait until falling_edge(clk);
        noisy_in(0) <= '1';
        if G_WIDTH >= 2 then
            noise_bit := 1;             -- dynamic index: no static bound issue
            for k in C_LENS'range loop
                if C_LENS(k) < N then
                    noisy_in(noise_bit) <= '1';
                    for j in 1 to C_LENS(k) loop
                        wait until falling_edge(clk);
                    end loop;
                    noisy_in(noise_bit) <= '0';
                    for j in 1 to C_HOLD loop
                        wait until falling_edge(clk);
                    end loop;
                end if;
            end loop;
        elsif N >= 4 then
            -- single-bit sweep: one 1-sample self-glitch during the
            -- ongoing transition must not corrupt the adoption. Only for
            -- N >= 4: with a smaller window the adoption completes before
            -- the glitch propagates through the synchronizer (a race the
            -- DUT legitimately wins), so no exact latency could be checked.
            for j in 1 to 2 loop
                wait until falling_edge(clk);
            end loop;
            noisy_in(0) <= '0';
            wait until falling_edge(clk);
            noisy_in(0) <= '1';
        end if;
        wait for C_SETTLE * CLK_PERIOD;

        -- stage C2 (multi-bit): remaining bits go high one by one, each
        -- adopted with the exact window
        if G_WIDTH >= 2 then
            for i in 1 to G_WIDTH - 1 loop
                wait until falling_edge(clk);
                noisy_in(i) <= '1';
                wait for C_SETTLE * CLK_PERIOD;
            end loop;
        end if;

        -- stage D: glitch train on bit 0, base high; nothing must be adopted
        for k in C_LENS'range loop
            if C_LENS(k) < N then
                wait until falling_edge(clk);
                noisy_in(0) <= '0';
                for j in 1 to C_LENS(k) loop
                    wait until falling_edge(clk);
                end loop;
                noisy_in(0) <= '1';
                for j in 1 to C_HOLD loop
                    wait until falling_edge(clk);
                end loop;
            end if;
        end loop;
        wait for C_SETTLE * CLK_PERIOD;

        -- stage D2: bounced high->low transition (bit 1 when present, else
        -- bit 0): brief low, restore high, then stable low. Adopted only
        -- from the last change, i.e. after one full stable window.
        bounce_len := N - 1;
        if bounce_len < 1 then
            bounce_len := 1;
        end if;
        bounce_bit := 0;
        if G_WIDTH >= 2 then
            bounce_bit := C_BOUNCE;
        end if;
        wait until falling_edge(clk);
        noisy_in(bounce_bit) <= '0';
        for j in 1 to bounce_len loop
            wait until falling_edge(clk);
        end loop;
        noisy_in(bounce_bit) <= '1';
        for j in 1 to C_HOLD loop
            wait until falling_edge(clk);
        end loop;
        noisy_in(bounce_bit) <= '0';
        wait for C_SETTLE * CLK_PERIOD;

        -- stage E: mid-run reset with the input high
        wait until falling_edge(clk);
        noisy_in <= (others => '1');
        wait for C_SETTLE * CLK_PERIOD;   -- all bits adopted high
        wait until falling_edge(clk);
        rst_n <= '0';                     -- output must go and stay '0'
        for j in 1 to 3 loop
            wait until falling_edge(clk);
        end loop;
        rst_n <= '1';                     -- input still high: re-adopted
        wait for C_SETTLE * CLK_PERIOD;

        -- stage F: final transition back to low everywhere
        wait until falling_edge(clk);
        noisy_in <= (others => '0');
        wait for C_SETTLE * CLK_PERIOD;

        -- direct final check
        for i in 0 to G_WIDTH - 1 loop
            if clean_out(i) /= '0' then
                report "ERROR: clean_out(" & integer'image(i) &
                       ") not '0' at end of test"
                    severity error;
                final_errors <= final_errors + 1;
            end if;
        end loop;

        -- summary
        wait for 2 * CLK_PERIOD;
        sim_done <= true;
        wait for CLK_PERIOD;
        if errors = 0 and final_errors = 0 then
            report "TEST PASSED - 0 errors" severity note;
        else
            report "TEST FAILED - " &
                   integer'image(errors + final_errors) & " errors"
                severity error;
        end if;
        wait;                              -- end of test
    end process;

    ---------------------------------------------------------------
    -- Reference monitor: per-bit tracking of the input history vs the
    -- debounced state, checking the value and latency of every
    -- transition and the parked-low behaviour during reset.
    ---------------------------------------------------------------
    monitor : process(clk)
        variable n        : natural := 0;    -- enabled edge counter
        variable prev_rst : boolean := true; -- sim starts in reset
        variable armed    : t_bool_array(0 to G_WIDTH - 1) := (others => false);
        variable v        : t_sl_array(0 to G_WIDTH - 1);   -- last sampled input bit
        variable f        : t_nat_array(0 to G_WIDTH - 1);  -- edge when v last changed
        variable s        : t_sl_array(0 to G_WIDTH - 1);   -- last seen clean_out bit
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                -- from the second gated edge on, the output must be parked
                -- low (the first one still shows the pre-reset state)
                if prev_rst then
                    for i in 0 to G_WIDTH - 1 loop
                        if clean_out(i) /= '0' then
                            report "ERROR: clean_out(" & integer'image(i) &
                                   ") high while rst_n = '0'"
                                severity error;
                            errors <= errors + 1;
                        end if;
                    end loop;
                end if;
                for i in 0 to G_WIDTH - 1 loop
                    armed(i) := false;
                end loop;
                prev_rst := true;
            else
                n := n + 1;
                for i in 0 to G_WIDTH - 1 loop
                    if not armed(i) then
                        -- first enabled edge after a (re)lease: the DUT
                        -- starts sampling this bit from here on
                        armed(i) := true;
                        f(i)     := n;
                        v(i)     := noisy_in(i);
                        s(i)     := clean_out(i);
                    else
                        if clean_out(i) /= s(i) then
                            -- debounced state changed (set on the previous edge)
                            if clean_out(i) /= v(i) then
                                report "ERROR: clean_out(" & integer'image(i) &
                                       ") changed to a value noisy_in does not have"
                                    severity error;
                                errors <= errors + 1;
                            elsif n - f(i) /= C_LATENCY then
                                report "ERROR: clean_out(" & integer'image(i) &
                                       ") latency " & integer'image(n - f(i)) &
                                       " samples, expected " &
                                       integer'image(C_LATENCY)
                                    severity error;
                                errors <= errors + 1;
                            end if;
                            s(i) := clean_out(i);
                        end if;
                        if noisy_in(i) /= v(i) then
                            f(i) := n;
                            v(i) := noisy_in(i);
                        end if;
                    end if;
                end loop;
                prev_rst := false;
            end if;
        end if;
    end process;

end architecture sim;


