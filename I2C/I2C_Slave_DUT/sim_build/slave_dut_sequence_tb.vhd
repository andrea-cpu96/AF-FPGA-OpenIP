-- slave_dut_sequence_tb.vhd
-- Command/reply regression for the 4-pin I2C_Slave_DUT wrapper (only clk, rst_n,
-- sda and scl are wired) with the REAL I2C_Master acting as the EXTERNAL
-- controller on the shared open-drain bus -- exactly the bench setup: a
-- controller (another FPGA, an MCU, a USB-to-I2C bridge ...) addresses the DUT
-- over the two wires. Nothing reaches inside the DUT: every check is made on
-- the bus and at the controller's own interface, so the testbench proves the
-- behaviour a scope / logic analyser would see.
--
-- The dialogue the DUT has to play: answer 0xEE to the read that follows the
-- 0xAA command (0x00 before that), and ask for a fresh command after each
-- reply. Frames driven by the controller:
--   1. read 1 byte from 0x3C                 -> 0x00 (no command yet)
--   2. write 0xAA to 0x3C                    -> ACKed, DUT armed
--   3. read 1 byte from 0x3C                 -> 0xEE
--   4. read 1 byte from 0x3C                 -> 0x00 (the reply is one-shot)
--   5. write 0xAA + Sr + read 2 bytes        -> 0xEE, 0xEE (same-frame idiom)
--   6. write 0xAA to a FOREIGN address 0x51  -> NACKed, must not arm the DUT
--   7. read 1 byte from 0x3C                 -> 0x00 (foreign write ignored)
--   8. write 0xAA to 0x3C                    -> ACKed (the dialogue repeats)
--   9. read 1 byte from 0x3C                 -> 0xEE
--
-- Checks per frame:
--   * the bytes the controller received, and the ACK/NACK the DUT returned
--   * the number of clock-stretch holds the DUT inserted: one per ACK cell it
--     takes part in (address ACK, write-byte ACK, the controller's ACK cell
--     after a read byte) and none at all on the foreign frame
--   * both lines released again after every STOP (open-drain discipline)
--   * no stretch hold ever ran while the controller was not in a transaction
--
-- Simulation-only file: do NOT register it in I2C_Slave_DUT.qsf.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity slave_dut_sequence_tb is
end entity slave_dut_sequence_tb;

architecture sim of slave_dut_sequence_tb is

    constant C_CLK_PERIOD : time    := 20 ns;   -- 50 MHz
    constant C_SETTLE     : natural := 40;      -- clks of quiet time after a frame

    -- Addresses
    constant C_SLAVE_ADDR   : std_logic_vector(6 downto 0) := "0111100";  -- 0x3C (DUT)
    constant C_FOREIGN_ADDR : std_logic_vector(6 downto 0) := "1010001";  -- 0x51 (nobody)

    -- The dialogue bytes the DUT answers
    constant C_CMD  : std_logic_vector(7 downto 0) := x"AA";  -- command written by the controller
    constant C_RESP : std_logic_vector(7 downto 0) := x"EE";  -- reply after a latched command
    constant C_IDLE : std_logic_vector(7 downto 0) := x"00";  -- reply before the command

    -- Clock stretching: the shipped DUT configuration
    constant C_STRETCH_CYCLES : natural := 500;  -- SCL low hold per ACK cell [clk]

    -- A stretch hold starts on the SAME SCL falling edge as the controller's own
    -- low phase, so the two run in parallel: a stretched low phase lasts
    -- max(controller low, G_STRETCH_CYCLES) -- measured here 250 clk for a plain
    -- phase and 506 clk for a stretched one. 400 clk separates the two
    -- populations cleanly, so a low phase above the threshold is exactly one ACK
    -- cell the DUT stretched.
    constant C_HOLD_THRESHOLD : natural := 400;

    constant C_N_FRAMES : natural := 9;

    signal clk     : std_logic := '0';
    signal rst_n   : std_logic := '0';
    signal sda_bus : std_logic;
    signal scl_bus : std_logic;

    -- Controller (external I2C_Master) interface
    signal w              : std_logic := '0';
    signal r              : std_logic := '0';
    signal req_rw         : std_logic := '0';   -- 1 = this step is a read request
    signal addr_c         : std_logic_vector(6 downto 0) := C_SLAVE_ADDR;
    signal n_write        : std_logic_vector(3 downto 0) := "0000";
    signal n_read         : std_logic_vector(3 downto 0) := "0001";
    signal c_tx_data      : std_logic_vector(7 downto 0) := C_CMD;
    signal c_data_to_read : std_logic_vector(7 downto 0);
    signal c_tx_done      : std_logic;
    signal c_tx_data_done : std_logic;
    signal c_rx_valid     : std_logic;
    signal c_busy         : std_logic;
    signal c_ack          : std_logic;

    -- Controller-side watchers (the only "instrumentation" of this TB: the DUT
    -- is a black box behind its 4 pins)
    type byte_array_t is array (0 to 15) of std_logic_vector(7 downto 0);
    signal c_rx_cnt  : natural := 0;   -- c_rx_valid pulses
    signal c_rx_hist : byte_array_t := (others => (others => '0'));

    -- Clock-stretch measurement, derived from the SCL level on the bus only
    signal low_run      : natural := 0;   -- clk cycles of the current SCL low phase
    signal hold_cnt     : natural := 0;   -- ACK-cell low phases the DUT stretched
    signal hold_outside : natural := 0;   -- ... of those, outside a controller transaction
    signal longest_low  : natural := 0;   -- longest stretch hold seen [clk cycles]
    signal low_phases   : natural := 0;   -- low phases measured (diagnostics)
    signal max_low      : natural := 0;   -- longest low phase, hold or not
    signal min_low      : natural := 0;   -- shortest low phase (0 = none yet)
    signal start_cnt    : natural := 0;   -- START / repeated-START phases seen
    signal start_low    : natural := 0;   -- length of those phases [clk cycles]

    -- Request sequencer
    type seq_state_t is (S_CFG, S_REQ, S_RUN, S_DONE);
    signal seq_state : seq_state_t := S_CFG;
    signal step      : natural range 0 to C_N_FRAMES - 1 := 0;
    signal wait_cnt  : natural := 0;

    signal finished : boolean := false;

    file results : text open write_mode is "results.txt";

    -- Two-digit hex formatting for the frame report notes and messages
    -- (VHDL-93 friendly: no VHDL-2008-only textIO helpers).
    function hex2 (v : std_logic_vector(7 downto 0)) return string is
        constant C_HEX : string(1 to 16) := "0123456789ABCDEF";
        variable hi    : natural := 0;
        variable lo    : natural := 0;
    begin
        for i in 7 downto 4 loop
            hi := hi * 2;
            if v(i) = '1' then
                hi := hi + 1;
            end if;
        end loop;
        for i in 3 downto 0 loop
            lo := lo * 2;
            if v(i) = '1' then
                lo := lo + 1;
            end if;
        end loop;
        return "0x" & C_HEX(hi + 1) & C_HEX(lo + 1);
    end function;

begin

    clk <= not clk after C_CLK_PERIOD / 2 when not finished else '0';

    -- One shared open-drain bus: the TB only provides the external pull-ups.
    -- The DUT is wired through its 4 pins, nothing else.
    sda_bus <= 'H';
    scl_bus <= 'H';

    ---------------------------------------------------------------------------
    -- Design under test: the slave wrapper, 4-pin interface only.
    ---------------------------------------------------------------------------
    dut : entity work.I2C_Slave_DUT
        generic map (
            G_SLAVE_ADDR     => C_SLAVE_ADDR,
            G_CLK_FREQ       => 50_000_000,
            G_I2C_FREQ       => 100_000,
            G_STRETCH_CYCLES => C_STRETCH_CYCLES
        )
        port map (
            clk   => clk,
            rst_n => rst_n,
            sda   => sda_bus,
            scl   => scl_bus
        );

    ---------------------------------------------------------------------------
    -- The external controller: the existing I2C_Master, on the same two wires.
    ---------------------------------------------------------------------------
    controller : entity work.I2C_Master
        generic map (
            G_CLK_FREQ => 50_000_000,
            G_I2C_FREQ => 100_000
        )
        port map (
            clk              => clk,
            rst_n            => rst_n,
            w                => w,
            r                => r,
            addr             => addr_c,
            data_to_transmit => c_tx_data,
            n_write          => n_write,
            n_read           => n_read,
            data_to_read     => c_data_to_read,
            tx_done          => c_tx_done,
            tx_data_done     => c_tx_data_done,
            rx_valid         => c_rx_valid,
            busy             => c_busy,
            ack              => c_ack,
            sda              => sda_bus,
            scl              => scl_bus
        );

    -- Reset: long enough for the checker to be waiting for the first frame, and
    -- for the controller's bus-free timer to be preset.
    reset_gen : process
    begin
        rst_n <= '0';
        for i in 1 to 100 loop
            wait until rising_edge(clk);
        end loop;
        rst_n <= '1';
        wait;
    end process;

    ---------------------------------------------------------------------------
    -- Controller watcher: the bytes the DUT actually sent back.
    ---------------------------------------------------------------------------
    controller_watch : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                c_rx_cnt <= 0;
            elsif c_rx_valid = '1' then
                if c_rx_cnt < 16 then
                    c_rx_hist(c_rx_cnt) <= c_data_to_read;
                end if;
                c_rx_cnt <= c_rx_cnt + 1;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Clock-stretch measurement on the bus: classify every SCL low phase by its
    -- length. The DUT is the only device that can extend an ACK-cell low phase
    -- here, so a long low phase is exactly one ACK cell it took part in.
    --
    -- One phase per frame has to be excluded: the controller's divider is parked
    -- low while the bus is idle, so the LOW PHASE THAT FOLLOWS A START (and a
    -- repeated START) is its first enabled period -- a full G_DIVIDER (~500 clk)
    -- long, i.e. as long as a stretch hold. START / Sr conditions are detected
    -- on the bus (SDA falls while SCL is high) and the next low phase is counted
    -- separately.
    ---------------------------------------------------------------------------
    stretch_watch : process(clk)
        variable sda_d       : std_logic := '1';
        variable start_phase : boolean := false;
    begin
        if rising_edge(clk) then
            -- START / repeated START on the bus: SDA falls while SCL is high
            if To_X01(sda_bus) = '0' and sda_d = '1' and To_X01(scl_bus) = '1' then
                start_phase := true;
            end if;
            sda_d := To_X01(sda_bus);

            if rst_n = '0' then
                low_run      <= 0;
                hold_cnt     <= 0;
                hold_outside <= 0;
                longest_low  <= 0;
                low_phases   <= 0;
                max_low      <= 0;
                min_low      <= 0;
                start_cnt    <= 0;
                start_low    <= 0;
            elsif To_X01(scl_bus) = '0' then
                low_run <= low_run + 1;
            else
                -- Diagnostics: every completed low phase (glitches < 10 clk are
                -- the sync-stage artefacts, not bus phases)
                if low_run >= 10 then
                    low_phases <= low_phases + 1;
                    if low_run > max_low then
                        max_low <= low_run;
                    end if;
                    if min_low = 0 or low_run < min_low then
                        min_low <= low_run;
                    end if;

                    if start_phase then
                        -- the START / Sr low phase: not an ACK cell, not a
                        -- stretch -- it is the controller's first enabled
                        -- divider period after releasing the line
                        start_cnt   <= start_cnt + 1;
                        start_low   <= low_run;
                        start_phase := false;
                    elsif low_run >= C_HOLD_THRESHOLD then
                        hold_cnt <= hold_cnt + 1;
                        if c_busy /= '1' then
                            -- a hold outside a controller transaction: the DUT
                            -- stretched a phase it was not addressed in
                            hold_outside <= hold_outside + 1;
                        end if;
                        if low_run > longest_low then
                            longest_low <= low_run;
                        end if;
                    end if;
                end if;
                low_run <= 0;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Request sequencer: the nine frames one after the other, with the w/r
    -- handshake discipline the wrappers use (raise the request, drop it once the
    -- controller reports busy, wait for the frame to end, settle, next step).
    ---------------------------------------------------------------------------
    sequencer : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                seq_state <= S_CFG;
                step      <= 0;
                wait_cnt  <= 0;
                w         <= '0';
                r         <= '0';
                req_rw    <= '0';
                c_tx_data <= C_CMD;
            else
                case seq_state is

                    -- Load the request for this step (address, byte counts and
                    -- the direction the controller has to start with).
                    when S_CFG =>
                        case step is
                            when 0 =>     -- frame 1: read 1 byte, no command yet
                                addr_c    <= C_SLAVE_ADDR;
                                n_write   <= "0000";
                                n_read    <= "0001";
                                req_rw    <= '1';
                            when 1 =>     -- frame 2: write the 0xAA command
                                addr_c    <= C_SLAVE_ADDR;
                                n_write   <= "0001";
                                n_read    <= "0000";
                                req_rw    <= '0';
                                c_tx_data <= C_CMD;
                            when 2 =>     -- frame 3: read 1 byte -> 0xEE
                                addr_c    <= C_SLAVE_ADDR;
                                n_write   <= "0000";
                                n_read    <= "0001";
                                req_rw    <= '1';
                            when 3 =>     -- frame 4: read 1 byte -> 0x00 (one-shot)
                                addr_c    <= C_SLAVE_ADDR;
                                n_write   <= "0000";
                                n_read    <= "0001";
                                req_rw    <= '1';
                            when 4 =>     -- frame 5: write 0xAA + Sr + read 2 bytes
                                addr_c    <= C_SLAVE_ADDR;
                                n_write   <= "0001";
                                n_read    <= "0010";
                                req_rw    <= '0';
                                c_tx_data <= C_CMD;
                            when 5 =>     -- frame 6: write 0xAA to a foreign address
                                addr_c    <= C_FOREIGN_ADDR;
                                n_write   <= "0001";
                                n_read    <= "0000";
                                req_rw    <= '0';
                                c_tx_data <= C_CMD;
                            when 6 =>     -- frame 7: read 1 byte -> 0x00
                                addr_c    <= C_SLAVE_ADDR;
                                n_write   <= "0000";
                                n_read    <= "0001";
                                req_rw    <= '1';
                            when 7 =>     -- frame 8: write the 0xAA command again
                                addr_c    <= C_SLAVE_ADDR;
                                n_write   <= "0001";
                                n_read    <= "0000";
                                req_rw    <= '0';
                                c_tx_data <= C_CMD;
                            when others =>-- frame 9: read 1 byte -> 0xEE again
                                addr_c    <= C_SLAVE_ADDR;
                                n_write   <= "0000";
                                n_read    <= "0001";
                                req_rw    <= '1';
                        end case;
                        seq_state <= S_REQ;

                    -- Raise the request; take it back once the controller is busy
                    when S_REQ =>
                        if req_rw = '1' then
                            r <= '1';
                        else
                            w <= '1';
                        end if;
                        if c_busy = '1' then
                            w         <= '0';
                            r         <= '0';
                            wait_cnt  <= C_SETTLE;
                            seq_state <= S_RUN;
                        end if;

                    -- Frame running: wait for the controller to close it, settle,
                    -- then move on to the next step.
                    when S_RUN =>
                        if c_busy = '0' then
                            if wait_cnt = 0 then
                                if step = C_N_FRAMES - 1 then
                                    seq_state <= S_DONE;
                                else
                                    step      <= step + 1;
                                    seq_state <= S_CFG;
                                end if;
                            else
                                wait_cnt <= wait_cnt - 1;
                            end if;
                        end if;

                    when S_DONE =>
                        null;

                end case;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Checker: one frame at a time, delimited by the controller's busy flag, so
    -- every expectation (byte read back, ACK, stretch holds) is attributed to
    -- the frame that produced it and nothing has to be inspected inside the DUT.
    ---------------------------------------------------------------------------
    checker : process
        variable L   : line;
        variable ok  : boolean := true;
        variable mr0 : natural;   -- read-byte count at the frame start
        variable ho0 : natural;   -- stretch-hold count at the frame start

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
                write(L, hex2(got));
                write(L, string'(", expected "));
                write(L, hex2(exp));
                writeline(results, L);
            end if;
        end procedure;

        -- Snapshot the counters at the start of a frame ...
        procedure frame_start is
        begin
            wait until rising_edge(c_busy);
            mr0 := c_rx_cnt;
            ho0 := hold_cnt;
        end procedure;

        -- ... and let it finish (plus a settle window) before checking.
        procedure frame_end (constant name : string) is
        begin
            wait until falling_edge(c_busy);
            clk_ticks(C_SETTLE);
            check(To_X01(scl_bus) = '1' and To_X01(sda_bus) = '1',
                  name & ": bus not released after the STOP");
        end procedure;
    begin
        -- Both ends are still in reset: the idle state must already be clean, and
        -- the checker must be waiting for the first frame before the reset is
        -- released, otherwise it would miss the first busy rise.
        clk_ticks(5);
        check(c_busy = '0', "reset: the controller is busy");
        check(To_X01(scl_bus) = '1' and To_X01(sda_bus) = '1',
              "reset: bus not released");

        -- ------------------------------------------------------------------
        -- Frame 1: read 1 byte. No command has been written yet, so the DUT
        -- must answer the idle byte; ACK cells: address + the controller's
        -- NACK after the read byte -> 2 stretch holds.
        -- ------------------------------------------------------------------
        frame_start;
        frame_end("frame 1");

        report "frame 1: read before any command -> " & hex2(c_rx_hist(mr0))
            severity note;
        check(c_rx_cnt - mr0 = 1, "frame 1: read-byte count");
        check_eq(c_rx_hist(mr0), C_IDLE,
                 "frame 1: read before the command must answer the idle byte");
        check(c_ack = '0', "frame 1: the DUT did not ACK its own address");
        check(hold_cnt - ho0 = 2,
              "frame 1: stretch holds (address ACK + read ACK cell)");

        -- ------------------------------------------------------------------
        -- Frame 2: the command. A write-only frame: the DUT must ACK both the
        -- address and the byte, arm its reply and stay silent on the bus
        -- otherwise (address ACK + write ACK -> 2 stretch holds).
        -- ------------------------------------------------------------------
        frame_start;
        frame_end("frame 2");

        report "frame 2: command 0xAA written to 0x3C" severity note;
        check(c_rx_cnt = mr0, "frame 2: unexpected read byte in a write-only frame");
        check(c_ack = '0', "frame 2: the DUT did not ACK the command");
        check(hold_cnt - ho0 = 2,
              "frame 2: stretch holds (address ACK + write ACK)");

        -- ------------------------------------------------------------------
        -- Frame 3: the read that follows the command: the DUT must answer
        -- 0xEE (address ACK + read ACK cell -> 2 stretch holds).
        -- ------------------------------------------------------------------
        frame_start;
        frame_end("frame 3");

        report "frame 3: read after the command -> " & hex2(c_rx_hist(mr0))
            severity note;
        check(c_rx_cnt - mr0 = 1, "frame 3: read-byte count");
        check_eq(c_rx_hist(mr0), C_RESP,
                 "frame 3: the DUT must answer 0xEE after the command");
        check(c_ack = '0', "frame 3: the DUT did not ACK its own address");
        check(hold_cnt - ho0 = 2,
              "frame 3: stretch holds (address ACK + read ACK cell)");

        -- ------------------------------------------------------------------
        -- Frame 4: a read right after the one that delivered 0xEE. The reply is
        -- one-shot: the DUT asks for a fresh command once the frame closed, so
        -- this read must see the idle byte again.
        -- ------------------------------------------------------------------
        frame_start;
        frame_end("frame 4");

        report "frame 4: second read -> " & hex2(c_rx_hist(mr0)) severity note;
        check(c_rx_cnt - mr0 = 1, "frame 4: read-byte count");
        check_eq(c_rx_hist(mr0), C_IDLE,
                 "frame 4: the reply must be one-shot (idle byte answered again)");
        check(hold_cnt - ho0 = 2,
              "frame 4: stretch holds (address ACK + read ACK cell)");

        -- ------------------------------------------------------------------
        -- Frame 5: the same-frame idiom -- 0xAA, repeated START, <addr+R> and
        -- two bytes read inside ONE frame. Both must be 0xEE (the DUT stays
        -- armed until the frame closes). ACK cells: address, write byte,
        -- re-address after the Sr, then one per read byte -> 5 stretch holds.
        -- ------------------------------------------------------------------
        frame_start;
        frame_end("frame 5");

        report "frame 5: write 0xAA + Sr + read 2 -> "
               & hex2(c_rx_hist(mr0)) & ", " & hex2(c_rx_hist(mr0 + 1))
            severity note;
        check(c_rx_cnt - mr0 = 2, "frame 5: read-byte count");
        check_eq(c_rx_hist(mr0), C_RESP,
                 "frame 5: first byte of the read-after-write idiom");
        check_eq(c_rx_hist(mr0 + 1), C_RESP,
                 "frame 5: last byte of the read-after-write idiom");
        check(c_ack = '0', "frame 5: the DUT did not ACK its own address");
        check(hold_cnt - ho0 = 5,
              "frame 5: stretch holds (addr + write + re-addr + 2 read ACK cells)");

        -- ------------------------------------------------------------------
        -- Frame 6: the command written to a FOREIGN address. Address filtering:
        -- the DUT must stay completely silent -- NACK, no data phase, no stretch
        -- -- so this 0xAA must not arm anything either.
        -- ------------------------------------------------------------------
        frame_start;
        frame_end("frame 6");

        report "frame 6: 0xAA written to the foreign address 0x51" severity note;
        check(c_rx_cnt = mr0, "frame 6: a read byte arrived in a foreign frame");
        check(c_ack = '1', "frame 6: the DUT must NACK a foreign address");
        check(hold_cnt = ho0, "frame 6: the DUT stretched a foreign frame");

        -- ------------------------------------------------------------------
        -- Frame 7: read again. Nothing was armed by the foreign frame, so the
        -- idle byte is the answer.
        -- ------------------------------------------------------------------
        frame_start;
        frame_end("frame 7");

        report "frame 7: read after the foreign frame -> " & hex2(c_rx_hist(mr0))
            severity note;
        check(c_rx_cnt - mr0 = 1, "frame 7: read-byte count");
        check_eq(c_rx_hist(mr0), C_IDLE,
                 "frame 7: a 0xAA sent to a foreign address must not arm the DUT");
        check(hold_cnt - ho0 = 2,
              "frame 7: stretch holds (address ACK + read ACK cell)");

        -- ------------------------------------------------------------------
        -- Frame 8: the command again -- the dialogue must be repeatable on the
        -- bench (this is what a scope/logic-analyzer capture shows over and
        -- over).
        -- ------------------------------------------------------------------
        frame_start;
        frame_end("frame 8");

        report "frame 8: command 0xAA written again" severity note;
        check(c_rx_cnt = mr0, "frame 8: unexpected read byte in a write-only frame");
        check(c_ack = '0', "frame 8: the DUT did not ACK the command");
        check(hold_cnt - ho0 = 2,
              "frame 8: stretch holds (address ACK + write ACK)");

        -- ------------------------------------------------------------------
        -- Frame 9: the matching read: 0xEE once more.
        -- ------------------------------------------------------------------
        frame_start;
        frame_end("frame 9");

        report "frame 9: read after the second command -> " & hex2(c_rx_hist(mr0))
            severity note;
        check(c_rx_cnt - mr0 = 1, "frame 9: read-byte count");
        check_eq(c_rx_hist(mr0), C_RESP,
                 "frame 9: the command/reply dialogue must repeat");
        check(hold_cnt - ho0 = 2,
              "frame 9: stretch holds (address ACK + read ACK cell)");

        -- ------------------------------------------------------------------
        -- Summary
        -- ------------------------------------------------------------------
        check(c_rx_cnt = 7,
              "controller read-byte total (1 + 1 + 1 + 2 + 1 + 1)");
        check(hold_cnt = 19,
              "stretch-hold total (one per ACK cell the DUT took part in)");
        check(hold_outside = 0,
              "a stretch hold ran while the controller was not in a transaction");
        check(start_cnt = 10,
              "START / repeated-START low phases (9 frames + the Sr in frame 5)");
        report "SCL low phases measured: " & integer'image(low_phases)
               & " (min " & integer'image(min_low) & " clk, max "
               & integer'image(max_low) & " clk) -- stretch holds "
               & integer'image(hold_cnt) & ", longest hold "
               & integer'image(longest_low) & " clk (threshold "
               & integer'image(C_HOLD_THRESHOLD) & ", stretch "
               & integer'image(C_STRETCH_CYCLES) & " clk); START phase "
               & integer'image(start_low) & " clk"
            severity note;

        if ok then
            report "RESULT: PASS -- I2C_Slave_DUT dialogue verified on the bus (0xAA written, 0xEE read back)"
                severity note;
        else
            report "RESULT: FAIL -- see results.txt" severity error;
        end if;
        finished <= true;
        wait;
    end process;

    -- Watchdog: very loud failure if any frame hangs.
    watchdog : process
    begin
        wait for 3 ms;
        if not finished then
            report "slave_dut_sequence_tb timed out" severity failure;
        end if;
        wait;
    end process;

end architecture sim;

