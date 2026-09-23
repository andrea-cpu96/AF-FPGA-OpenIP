-- start_stop_detect_tb.vhd
-- Self-checking testbench for start_stop_detect, the I2C START / repeated-START
-- / STOP condition detector.
--
-- One process scripts the whole bus (SCL/SDA are driven between clk edges so
-- the DUT never races the stimulus); a monitor counts the two output pulses
-- and the stimulus asserts the expected counts after every scripted phase:
--
--   1. idle high                                  -> no pulses
--   2. data traffic with SCL LOW                  -> no pulses (normal data)
--   2b. SDA transition in the low phase, then the
--       SCL rise that starts a bit cell            -> still no pulse (filter)
--   3. START  (SDA falls while SCL is high)        -> one start pulse
--   4. a whole data byte (bits change on low)      -> no further pulses
--   5. STOP   (SDA rises while SCL is high)        -> one stop pulse
--   6. repeated START                              -> another start pulse
--   7. release and idle                            -> no further pulses
--
-- Simulation-only file: do NOT register it in Start_Stop_Detect's project.

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity start_stop_detect_tb is
end entity start_stop_detect_tb;

architecture sim of start_stop_detect_tb is

    constant C_CLK_PERIOD : time    := 20 ns;
    constant C_HALF       : natural := 10;   -- clks per scripted bus phase
    constant C_SETTLE     : natural := 4;    -- clks to let a pulse register

    signal clk       : std_logic := '0';
    signal rst_n     : std_logic := '0';
    signal scl       : std_logic := '1';
    signal sda       : std_logic := '1';
    signal start_det : std_logic;
    signal stop_det  : std_logic;

    -- Checker bookkeeping
    signal start_cnt : natural := 0;
    signal stop_cnt  : natural := 0;
    signal finished  : boolean := false;

    file results : text open write_mode is "results.txt";

begin

    clk <= not clk after C_CLK_PERIOD / 2 when not finished else '0';

    dut : entity work.start_stop_detect
        port map (
            clk       => clk,
            rst_n     => rst_n,
            scl       => scl,
            sda       => sda,
            start_det => start_det,
            stop_det  => stop_det
        );

    -- Pulse counter (read-only watcher: never drives anything).
    monitor : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                start_cnt <= 0;
                stop_cnt  <= 0;
            else
                if start_det = '1' then
                    start_cnt <= start_cnt + 1;
                end if;
                if stop_det = '1' then
                    stop_cnt <= stop_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Stimulus + checker. A single process drives every input, so the waveform
    -- can never race the sampling inside the DUT.
    ---------------------------------------------------------------------------
    stim : process
        variable L  : line;
        variable ok : boolean := true;

        procedure clk_ticks (constant n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
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

        procedure check_counts (constant s : natural; constant p : natural;
                                constant message : string) is
        begin
            clk_ticks(C_SETTLE);
            if start_cnt /= s or stop_cnt /= p then
                ok := false;
                write(L, string'("FAIL: "));
                write(L, message);
                write(L, string'(" -- start pulses "));
                write(L, start_cnt);
                write(L, string'(", expected "));
                write(L, s);
                write(L, string'("; stop pulses "));
                write(L, stop_cnt);
                write(L, string'(", expected "));
                write(L, p);
                writeline(results, L);
            end if;
        end procedure;

        -- One bit cell: data is applied while SCL is low (the I2C rule), then
        -- SCL goes high with the data stable.
        procedure bit_cell (constant b : std_logic) is
        begin
            scl <= '0'; clk_ticks(C_HALF);
            sda <= b;   clk_ticks(C_HALF);
            scl <= '1'; clk_ticks(C_HALF);
        end procedure;
    begin
        -- 1. reset, bus idle high
        rst_n <= '0';
        scl   <= '1';
        sda   <= '1';
        clk_ticks(5);
        rst_n <= '1';
        clk_ticks(5);
        check_counts(0, 0, "reset / idle must not produce conditions");

        -- 2. data traffic while SCL is low: this is what a data handover looks
        --    like, no condition may fire.
        scl <= '0'; clk_ticks(C_HALF);
        sda <= '0'; clk_ticks(C_HALF);
        sda <= '1'; clk_ticks(C_HALF);
        check_counts(0, 0, "SDA transitions in the SCL low phase");

        -- 2b. SDA falls while SCL is low and SCL then rises with SDA stable
        --     low: a bit cell starting with a zero bit -- still no condition.
        sda <= '0'; clk_ticks(C_HALF);
        scl <= '1'; clk_ticks(C_HALF);
        check_counts(0, 0, "low-phase SDA fall followed by an SCL rise");

        -- 3. START: SDA falls while SCL is high.
        scl <= '0'; clk_ticks(C_HALF);
        sda <= '1'; clk_ticks(C_HALF);
        scl <= '1'; clk_ticks(C_HALF);
        sda <= '0'; clk_ticks(C_SETTLE);
        check_counts(1, 0, "START condition");

        -- 4. one data byte, MSB first: every bit changes while SCL is low.
        for i in 7 downto 0 loop
            if (i mod 2) = 0 then
                bit_cell('1');
            else
                bit_cell('0');
            end if;
        end loop;
        check_counts(1, 0, "data byte after START");

        -- 5. STOP: SDA rises while SCL is high.
        scl <= '0'; clk_ticks(C_HALF);
        sda <= '0'; clk_ticks(C_HALF);
        scl <= '1'; clk_ticks(C_HALF);
        sda <= '1'; clk_ticks(C_SETTLE);
        check_counts(1, 1, "STOP condition");

        -- 6. repeated START: the same condition as a START, with a busy bus.
        clk_ticks(C_HALF);
        sda <= '0'; clk_ticks(C_SETTLE);
        check_counts(2, 1, "repeated START condition");

        -- 7. release the bus and stay idle: no more conditions.
        scl <= '0'; clk_ticks(C_HALF);
        sda <= '1'; clk_ticks(C_HALF);
        scl <= '1'; clk_ticks(C_HALF);
        sda <= '1'; clk_ticks(C_HALF);
        check_counts(2, 1, "released bus must stay quiet");

        -- Summary
        if ok then
            write(L, string'("RESULT: PASS -- START / repeated START / STOP "));
            write(L, string'("detected, data traffic ignored"));
        else
            write(L, string'("RESULT: FAIL"));
        end if;
        writeline(results, L);
        if ok then
            report "RESULT: PASS -- START / repeated START / STOP detected, data traffic ignored"
                severity note;
        else
            report "RESULT: FAIL -- see results.txt" severity error;
        end if;
        finished <= true;
        wait;
    end process;

end architecture sim;

