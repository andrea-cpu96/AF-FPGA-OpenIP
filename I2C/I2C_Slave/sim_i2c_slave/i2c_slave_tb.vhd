-- i2c_slave_tb.vhd
-- Standalone, self-checking testbench for I2C_Slave: a scripted open-drain
-- master BFM drives real I2C frames and every response is checked both on the
-- wire and on the DUT's host interface.
--
-- Scripted frames (slave address 0x3C = "0111100"):
--   1. write, 2 bytes (0x11, 0x59)                -> ACK per byte, rx_valid x2
--   2. read, 2 bytes (0x5A, 0xE7)                 -> master ACK, then NACK
--   3. foreign address 0x51 (+ a data byte)       -> NACK, frame ignored
--   4. write 0x42, REPEATED START, read 1 byte    -> 0x7E, ONE single busy frame
--
-- Feature checks:
--   * CLOCK STRETCHING: the DUT's stretch_active output is counted per frame and
--     must be exactly one G_STRETCH_CYCLES hold per ACK cell the slave is
--     involved in (3 / 3 / 0 / 4 holds), and SCL must really be low while
--     stretch_active is high.
--   * REPEATED START: no STOP between the write and the read phase -- the DUT's
--     busy flag never drops and the re-address with R/W = 1 is answered in the
--     same frame.
--   * REPEATED-START read-back idiom: the written "register pointer" selects the
--     byte the following read returns (simple host model).
--   * SDA HAND-OVER (glitch watchdog): every 0/1 level on sda_bus must last at
--     least C_MIN_SDA_LEVEL clk. A shorter one can only be the pull-up winning
--     a window in which no agent drives SDA -- a hand-over spike -- and fails
--     the test, so a release-before-the-slave-ACKs gap can never slip through
--     silently again.
--   * Address filtering, ACK/NACK polarity, data integrity, bus release after
--     the STOP.
--
-- The BFM honours clock stretching itself: it releases SCL and waits for the
-- REAL bus rise before sampling, exactly like a real master would.
-- SCL is clocked at 100 kHz (Standard-mode); G_STRETCH_CYCLES is a testbench
-- generic, swept by sim_run.do (0 and 500).
--
-- Simulation-only file: do NOT register it in I2C_Slave.qsf.

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity i2c_slave_tb is
    generic (
        G_STRETCH_CYCLES : natural := 500
    );
end entity i2c_slave_tb;

architecture sim of i2c_slave_tb is

    -- Bus / DUT configuration
    constant C_CLK_PERIOD : time    := 20 ns;    -- 50 MHz system clock
    constant C_HALF       : natural := 250;      -- clks per SCL phase (100 kHz)
    constant C_EDGE       : natural := 3;        -- clks between two scripted edges
    constant C_SETTLE     : natural := 6;        -- clks to let pulses/counters land
    constant C_MIN_SDA_LEVEL : natural := 50;    -- clks: any shorter sda_bus level is a
                                                 -- hand-over spike (narrowest legit level
                                                 -- is C_HALF + C_EDGE = 253 clks: START setup)

    constant C_SLAVE_ADDR : std_logic_vector(6 downto 0) := "0111100";   -- 0x3C
    constant C_ADDR_W     : std_logic_vector(7 downto 0) := "01111000";  -- 0x3C + W
    constant C_ADDR_R     : std_logic_vector(7 downto 0) := "01111001";  -- 0x3C + R
    constant C_FOREIGN_W  : std_logic_vector(7 downto 0) := "10100010";  -- 0x51 + W

    -- Frames
    constant C_WR1        : std_logic_vector(7 downto 0) := x"11";
    constant C_WR2        : std_logic_vector(7 downto 0) := x"59";
    constant C_RD1        : std_logic_vector(7 downto 0) := x"5A";
    constant C_RD2        : std_logic_vector(7 downto 0) := x"E7";
    constant C_POINTER    : std_logic_vector(7 downto 0) := x"42";  -- "register pointer"
    constant C_POINTER_RD : std_logic_vector(7 downto 0) := x"7E";  -- byte it selects

    -- Per-frame expected values
    constant C_STRETCHES_WRITE : natural := 3;  -- address ACK + 2 write ACKs
    constant C_STRETCHES_READ  : natural := 3;  -- address ACK + 2 master ACKs
    constant C_STRETCHES_SR    : natural := 4;  -- 2 ACKs per phase, write + read

    signal clk        : std_logic := '0';
    signal rst_n      : std_logic := '0';
    signal sda_bus    : std_logic;
    signal scl_bus    : std_logic;
    signal m_sda_low  : std_logic := '0';   -- master pull-downs (open drain)
    signal m_scl_low  : std_logic := '0';

    signal data_to_transmit : std_logic_vector(7 downto 0) := C_RD1;
    signal data_received    : std_logic_vector(7 downto 0);
    signal rx_valid         : std_logic;
    signal tx_done          : std_logic;
    signal busy             : std_logic;
    signal stretch_active   : std_logic;

    signal finished : boolean := false;

    file results : text open write_mode is "results.txt";

    ---------------------------------------------------------------------------
    -- Watchdog counters (read-only observers of the DUT boundary)
    ---------------------------------------------------------------------------
    type byte_array_t is array (0 to 7) of std_logic_vector(7 downto 0);

    signal stretch_cnt : natural := 0;   -- clk periods the slave held SCL low
    signal stretch_bad : natural := 0;   -- periods where SCL was not low (bug)
    signal glitch_cnt  : natural := 0;   -- sda_bus levels shorter than C_MIN_SDA_LEVEL
    signal rx_cnt      : natural := 0;   -- rx_valid pulses
    signal tx_cnt      : natural := 0;   -- tx_done pulses
    signal busy_rise   : natural := 0;   -- busy rising edges = frames start
    signal busy_fall   : natural := 0;   -- busy falling edges = frames end
    signal busy_prev   : std_logic := '0';
    signal rx_hist     : byte_array_t := (others => (others => '0'));

    -- Host model stream: the byte handed over after each tx_done (index 0 is
    -- never used -- the first read byte is loaded on reset / on the pointer
    -- write).
    constant RD_STREAM : byte_array_t := (1 => C_RD2, 2 => x"C3", others => x"00");
    signal rd_idx : natural range 0 to 7 := 1;

begin

    clk <= not clk after C_CLK_PERIOD / 2 when not finished else '0';

    -- Open-drain bus with external pull-ups: every agent only ever pulls a line
    -- low or releases it.
    sda_bus <= 'H';
    scl_bus <= 'H';
    sda_bus <= '0' when m_sda_low = '1' else 'Z';
    scl_bus <= '0' when m_scl_low = '1' else 'Z';

    dut : entity work.I2C_Slave
        generic map (
            G_SLAVE_ADDR     => C_SLAVE_ADDR,
            G_CLK_FREQ       => 50_000_000,
            G_I2C_FREQ       => 100_000,
            G_STRETCH_CYCLES => G_STRETCH_CYCLES
        )
        port map (
            clk              => clk,
            rst_n            => rst_n,
            data_to_transmit => data_to_transmit,
            data_received    => data_received,
            rx_valid         => rx_valid,
            tx_done          => tx_done,
            busy             => busy,
            stretch_active   => stretch_active,
            sda              => sda_bus,
            scl              => scl_bus
        );

    ---------------------------------------------------------------------------
    -- Watchdogs / counters (read-only observers of the DUT boundary): their
    -- signals are declared above, next to the DUT interface.
    ---------------------------------------------------------------------------
    -- Stretch watcher: counts the periods the slave declares a hold and proves
    -- the line really is low for all of them.
    stretch_watch : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                stretch_cnt <= 0;
                stretch_bad <= 0;
            elsif stretch_active = '1' then
                stretch_cnt <= stretch_cnt + 1;
                if To_X01(scl_bus) /= '0' then
                    stretch_bad <= stretch_bad + 1;
                end if;
            end if;
        end if;
    end process;

    -- Host interface watcher: pulse counters, the received byte history and the
    -- busy transitions (one rise + one fall per frame addressed to this slave).
    host_watch : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                rx_cnt    <= 0;
                tx_cnt    <= 0;
                busy_rise <= 0;
                busy_fall <= 0;
                busy_prev <= '0';
            else
                if busy = '1' and busy_prev = '0' then
                    busy_rise <= busy_rise + 1;
                elsif busy = '0' and busy_prev = '1' then
                    busy_fall <= busy_fall + 1;
                end if;
                busy_prev <= busy;

                if rx_valid = '1' then
                    if rx_cnt < 8 then
                        rx_hist(rx_cnt) <= data_received;
                    end if;
                    rx_cnt <= rx_cnt + 1;
                end if;

                if tx_done = '1' then
                    tx_cnt <= tx_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- SDA glitch watchdog: measures every completed 0/1 level on the resolved
    -- bus in clk units and counts any shorter than C_MIN_SDA_LEVEL. A level
    -- that short cannot be produced by the protocol (the narrowest legitimate
    -- one is the master's ACK-cell hand-over hold of C_EDGE + C_HALF/2 clks);
    -- it can only come from a window in which NEITHER agent drives SDA and the
    -- pull-up briefly wins -- the hand-over spike this test must never show
    -- again. The run in progress at reset release is not judged (armed),
    -- everything after rst_n is.
    glitch_watch : process(clk)
        variable lvl_v : std_logic := '1';
        variable run_v : natural   := 0;
        variable arm_v : boolean   := false;
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                lvl_v      := '1';
                run_v      := 0;
                arm_v      := false;
                glitch_cnt <= 0;
            else
                if To_X01(sda_bus) /= lvl_v then
                    if arm_v and run_v < C_MIN_SDA_LEVEL then
                        glitch_cnt <= glitch_cnt + 1;
                    end if;
                    lvl_v := To_X01(sda_bus);
                    run_v := 1;
                    arm_v := true;
                else
                    run_v := run_v + 1;
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Host model. A tiny "register pointer" behaviour: the byte written by the
    -- master selects what the next read returns; otherwise the read bytes are
    -- streamed one per tx_done, the same handover the I2C_DUT uses.
    ---------------------------------------------------------------------------
    host : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                data_to_transmit <= C_RD1;      -- first byte of the read frame
                rd_idx           <= 1;
            elsif rx_valid = '1' and data_received = C_POINTER then
                data_to_transmit <= C_POINTER_RD;
                rd_idx           <= 1;
            elsif tx_done = '1' then
                data_to_transmit <= RD_STREAM(rd_idx);
                if rd_idx < 7 then
                    rd_idx <= rd_idx + 1;
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Master BFM + checker. This single process drives the whole script through
    -- the open-drain bus signals, so nothing can race the DUT.
    ---------------------------------------------------------------------------
    stim : process
        variable L   : line;
        variable ok  : boolean := true;
        variable ack : std_logic;
        variable v   : std_logic_vector(7 downto 0);
        variable s0, r0, t0, br0, bf0 : natural;

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

        procedure check_eq (constant got : std_logic_vector(7 downto 0);
                            constant exp : std_logic_vector(7 downto 0);
                            constant message : string) is
        begin
            if got /= exp then
                ok := false;
                write(L, string'("FAIL: "));
                write(L, message);
                write(L, string'(" -- got "));
                write(L, to_bitvector(got));
                write(L, string'(", expected "));
                write(L, to_bitvector(exp));
                writeline(results, L);
            end if;
        end procedure;

        -- ---------------------------------------------------------------
        -- Framing the master generates (open drain: only pull low or release)
        -- ---------------------------------------------------------------

        -- START: SDA falls while SCL is high. SCL is left high -- the first
        -- send_bit pulls it low and opens the first bit cell.
        procedure start_cond is
        begin
            m_scl_low <= '0';                -- both lines released (idle high)
            m_sda_low <= '0';
            clk_ticks(C_HALF);
            m_sda_low <= '1';                -- SDA falls while SCL high: START
            clk_ticks(C_HALF);
        end procedure;

        -- REPEATED START: SCL is high (that ACK cell is over) and the bus stays
        -- busy -- no STOP in between, SDA just falls again while SCL is high.
        procedure repeated_start_cond is
        begin
            m_scl_low <= '1';                -- close the write ACK cell
            clk_ticks(C_EDGE);
            m_sda_low <= '0';                -- release SDA: free for the Sr
            clk_ticks(C_HALF);
            m_scl_low <= '0';                -- let SCL rise (the slave may hold it)
            wait until To_X01(scl_bus) = '1';
            clk_ticks(C_HALF);
            m_sda_low <= '1';                -- SDA falls while SCL high: Sr
            clk_ticks(C_HALF);
        end procedure;

        -- STOP: SDA low while SCL is low, then SDA rises while SCL is high.
        procedure stop_cond is
        begin
            m_scl_low <= '1';                -- close the last ACK cell
            clk_ticks(C_EDGE);
            m_sda_low <= '1';                -- SDA low first ...
            clk_ticks(C_HALF);
            m_scl_low <= '0';
            wait until To_X01(scl_bus) = '1';
            clk_ticks(C_HALF);
            m_sda_low <= '0';                -- ... then SDA rises: STOP
            clk_ticks(C_HALF);
        end procedure;

        -- ---------------------------------------------------------------
        -- Bit / byte / ACK cells
        -- ---------------------------------------------------------------

        -- One bit cell the master sends. SCL is high at entry; the bit is set up
        -- in the low phase and sampled by the receiver on the SCL rise.
        procedure send_bit (constant b : std_logic) is
        begin
            m_scl_low <= '1';                -- opening fall of the cell
            clk_ticks(C_EDGE);
            m_sda_low <= not b;              -- '0' bit = pull SDA low
            clk_ticks(C_HALF);
            m_scl_low <= '0';                -- release SCL
            wait until To_X01(scl_bus) = '1';-- wait for the REAL rise (stretch)
            clk_ticks(C_HALF);               -- high phase: sampled here
        end procedure;

        -- One byte, MSB first (I2C bit order).
        procedure send_byte (constant b : std_logic_vector(7 downto 0)) is
        begin
            for i in 7 downto 0 loop
                send_bit(b(i));
            end loop;
        end procedure;

        -- The ACK cell after a byte the master sent: SDA is released so the
        -- slave can drive the acknowledge, which is read back on the SCL rise.
        -- The master keeps its last bit driven through the first half of the
        -- low phase instead of letting go C_EDGE clks after the fall: the
        -- slave only reaches the bus ~5 clks after that fall (2-FF sync +
        -- level reg + FSM transition + registered output mux), so an early
        -- release left a short window in which NEITHER agent held SDA low and
        -- the pull-up raised a spike. Holding across the hand-over overlaps
        -- the two open-drain drives instead (both pull '0' -- always legal),
        -- and because the extra hold is taken out of the EXISTING low phase
        -- (C_EDGE + C_HALF/2 + (C_HALF - C_HALF/2) = C_EDGE + C_HALF) the
        -- bit-cell width, the slave's stretch window and the sample point at
        -- the SCL rise are all unchanged. On a NACK (foreign address) the
        -- line is simply released later inside the same low phase -- still
        -- C_HALF/2 clk before SCL rises -- so the read-back stays '1'.
        procedure read_ack (variable a : out std_logic) is
        begin
            m_scl_low <= '1';                     -- opening fall of the ACK cell
            clk_ticks(C_EDGE + C_HALF/2);         -- hold the last bit over the hand-over
            m_sda_low <= '0';                     -- release SDA: slave ACK / idle line owns it
            clk_ticks(C_HALF - C_HALF/2);         -- rest of the low phase (total unchanged)
            m_scl_low <= '0';
            wait until To_X01(scl_bus) = '1';     -- the slave's stretch ends here
            a := To_X01(sda_bus);                 -- '0' = ACK, '1' = NACK
            clk_ticks(C_HALF);
        end procedure;

        -- One byte read from the slave: every cell releases SDA and samples the
        -- line on the SCL rise (the slave drives the bit during the low phase).
        procedure receive_byte (variable b : inout std_logic_vector(7 downto 0)) is
        begin
            for i in 7 downto 0 loop
                m_scl_low <= '1';
                clk_ticks(C_EDGE);
                m_sda_low <= '0';            -- release SDA: the slave drives it
                clk_ticks(C_HALF);
                m_scl_low <= '0';
                wait until To_X01(scl_bus) = '1';
                b(i) := To_X01(sda_bus);     -- valid while SCL is high
                clk_ticks(C_HALF);
            end loop;
        end procedure;

        -- The ACK cell the master drives after a byte it received:
        -- '0' = ACK (more bytes follow), '1' = NACK (last byte).
        procedure drive_ack (constant a : std_logic) is
        begin
            m_scl_low <= '1';
            clk_ticks(C_EDGE);
            m_sda_low <= not a;              -- '0' = pull SDA low = ACK
            clk_ticks(C_HALF);
            m_scl_low <= '0';
            wait until To_X01(scl_bus) = '1';
            clk_ticks(C_HALF);
        end procedure;

    begin
        -- Reset, both lines released (idle high)
        rst_n     <= '0';
        m_sda_low <= '0';
        m_scl_low <= '0';
        clk_ticks(5);
        rst_n <= '1';
        clk_ticks(5);

        -- ------------------------------------------------------------------
        -- Frame 1: write two bytes. ACK cells taken part in: address + byte 1
        -- + byte 2 = 3 -> exactly 3 stretch holds.
        -- ------------------------------------------------------------------
        s0  := stretch_cnt;
        r0  := rx_cnt;
        t0  := tx_cnt;
        br0 := busy_rise;
        bf0 := busy_fall;

        start_cond;
        send_byte(C_ADDR_W);
        read_ack(ack);
        check(ack = '0', "frame 1: slave did not ACK its write address");
        send_byte(C_WR1);
        read_ack(ack);
        check(ack = '0', "frame 1: slave did not ACK write byte 1");
        send_byte(C_WR2);
        read_ack(ack);
        check(ack = '0', "frame 1: slave did not ACK write byte 2");
        check(busy = '1', "frame 1: busy not asserted while addressed");
        stop_cond;
        clk_ticks(C_SETTLE);

        check_eq(data_received, C_WR2, "frame 1: data_received after STOP");
        check(rx_cnt - r0 = 2, "frame 1: rx_valid pulse count");
        check_eq(rx_hist(r0), C_WR1, "frame 1: first received byte");
        check_eq(rx_hist(r0 + 1), C_WR2, "frame 1: second received byte");
        check(tx_cnt = t0, "frame 1: tx_done pulsed in a write-only frame");
        check(stretch_cnt - s0 = C_STRETCHES_WRITE * G_STRETCH_CYCLES,
              "frame 1: stretch total (3 ACK cells)");
        check(busy_rise - br0 = 1 and busy_fall - bf0 = 1,
              "frame 1: busy must rise and fall exactly once");
        check(busy = '0', "frame 1: busy still high after the STOP");
        check(To_X01(scl_bus) = '1' and To_X01(sda_bus) = '1',
              "frame 1: bus not released after the STOP");

        -- ------------------------------------------------------------------
        -- Frame 2: read two bytes. ACK cells: address ACK, then the master's
        -- ACK after byte 1 and its NACK after byte 2 = 3 stretch holds.
        -- ------------------------------------------------------------------
        s0  := stretch_cnt;
        r0  := rx_cnt;
        t0  := tx_cnt;
        br0 := busy_rise;
        bf0 := busy_fall;

        start_cond;
        send_byte(C_ADDR_R);
        read_ack(ack);
        check(ack = '0', "frame 2: slave did not ACK its read address");
        receive_byte(v);
        check_eq(v, C_RD1, "frame 2: first read byte");
        drive_ack('0');                      -- master ACK: one more byte follows
        receive_byte(v);
        check_eq(v, C_RD2, "frame 2: second read byte");
        drive_ack('1');                      -- master NACK: last byte
        stop_cond;
        clk_ticks(C_SETTLE);

        check(tx_cnt - t0 = 2, "frame 2: tx_done pulse count");
        check(rx_cnt = r0, "frame 2: rx_valid pulsed in a read-only frame");
        check(stretch_cnt - s0 = C_STRETCHES_READ * G_STRETCH_CYCLES,
              "frame 2: stretch total (3 ACK cells)");
        check(busy_rise - br0 = 1 and busy_fall - bf0 = 1,
              "frame 2: busy must rise and fall exactly once");
        check(busy = '0', "frame 2: busy still high after the STOP");
        check(To_X01(scl_bus) = '1' and To_X01(sda_bus) = '1',
              "frame 2: bus not released after the STOP");

        -- ------------------------------------------------------------------
        -- Frame 3: a foreign address must be NACKed and the whole frame
        -- ignored -- no ACK cell of this slave, so no stretch at all.
        -- ------------------------------------------------------------------
        s0  := stretch_cnt;
        r0  := rx_cnt;
        t0  := tx_cnt;
        br0 := busy_rise;
        bf0 := busy_fall;

        start_cond;
        send_byte(C_FOREIGN_W);
        read_ack(ack);
        check(ack = '1', "frame 3: slave answered a foreign address (NACK expected)");
        send_byte(x"A5");                    -- must be ignored completely
        read_ack(ack);
        check(ack = '1', "frame 3: slave ACKed a byte of a foreign frame");
        stop_cond;
        clk_ticks(C_SETTLE);

        check(stretch_cnt = s0, "frame 3: slave stretched a foreign frame");
        check(rx_cnt = r0, "frame 3: rx_valid pulsed on a foreign frame");
        check(tx_cnt = t0, "frame 3: tx_done pulsed on a foreign frame");
        check(busy_rise = br0 and busy_fall = bf0,
              "frame 3: busy changed state on a foreign frame");
        check(busy = '0', "frame 3: busy asserted on a foreign frame");
        check(To_X01(scl_bus) = '1' and To_X01(sda_bus) = '1',
              "frame 3: bus not released after the STOP");

        -- ------------------------------------------------------------------
        -- Frame 4: REPEATED START. Write the "register pointer" 0x42, then
        -- Sr + the same address with R/W = 1 and read the byte it selects.
        -- The frame must stay busy across the Sr (no STOP in between): exactly
        -- ONE busy rise/fall pair, and 4 ACK cells -> 4 stretch holds.
        -- ------------------------------------------------------------------
        s0  := stretch_cnt;
        r0  := rx_cnt;
        t0  := tx_cnt;
        br0 := busy_rise;
        bf0 := busy_fall;

        start_cond;
        send_byte(C_ADDR_W);
        read_ack(ack);
        check(ack = '0', "frame 4: slave did not ACK its write address");
        send_byte(C_POINTER);
        read_ack(ack);
        check(ack = '0', "frame 4: slave did not ACK the pointer byte");

        repeated_start_cond;                 -- Sr: the same frame continues
        send_byte(C_ADDR_R);
        read_ack(ack);
        check(ack = '0', "frame 4: slave did not ACK the re-address after Sr");
        receive_byte(v);
        check_eq(v, C_POINTER_RD, "frame 4: read-back of the pointed byte");
        drive_ack('1');                      -- NACK: a single byte is read
        stop_cond;
        clk_ticks(C_SETTLE);

        check(rx_cnt - r0 = 1, "frame 4: rx_valid pulse count");
        check_eq(rx_hist(r0), C_POINTER, "frame 4: pointer byte received");
        check(tx_cnt - t0 = 1, "frame 4: tx_done pulse count");
        check(stretch_cnt - s0 = C_STRETCHES_SR * G_STRETCH_CYCLES,
              "frame 4: stretch total (4 ACK cells over both phases)");
        check(busy_rise - br0 = 1 and busy_fall - bf0 = 1,
              "frame 4: the Sr must not end the frame (one busy rise/fall only)");
        check(busy = '0', "frame 4: busy still high after the STOP");
        check(To_X01(scl_bus) = '1' and To_X01(sda_bus) = '1',
              "frame 4: bus not released after the STOP");

        -- Summary -----------------------------------------------------------
        check(stretch_bad = 0,
              "stretch_active was high while SCL was not low");
        check(glitch_cnt = 0,
              "sda_bus glitch: a bus level lasted less than C_MIN_SDA_LEVEL clk (hand-over spike)");

        if ok then
            write(L, string'("RESULT: PASS -- write / read / Sr frames and address filtering verified, clock stretching exact (G_STRETCH_CYCLES = "));
            write(L, G_STRETCH_CYCLES);
            write(L, string'(")"));
        else
            write(L, string'("RESULT: FAIL"));
        end if;
        writeline(results, L);
        if ok then
            report "RESULT: PASS -- I2C slave frames and clock stretching verified"
                severity note;
        else
            report "RESULT: FAIL -- see results.txt" severity error;
        end if;
        finished <= true;
        wait;
    end process;

    -- Watchdog: a hang (for example a stretch that is never released) must never
    -- pass silently.
    watchdog : process
    begin
        wait for 4 ms;
        assert finished report "i2c_slave_tb timed out" severity failure;
        wait;
    end process;

end architecture sim;
