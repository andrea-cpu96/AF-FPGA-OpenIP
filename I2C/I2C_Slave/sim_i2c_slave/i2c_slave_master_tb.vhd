-- i2c_slave_master_tb.vhd
-- Integration testbench: the REAL I2C_Master talks to the new I2C_Slave on one
-- shared open-drain bus with external pull-ups, with the slave's clock
-- stretching enabled (G_STRETCH_CYCLES = 500 -> 10 us holds at a 50 MHz clk,
-- twice the 5 us low phase of a 100 kHz SCL). Both features the slave adds are
-- exercised against a real controller:
--
--   1. write 2 bytes to 0x3C
--   2. write 1 byte (the "register pointer") + REPEATED START + read 2 bytes
--      -- the idiom the slave's Sr handling exists for
--   3. write to a FOREIGN address 0x51 -- the slave must stay silent (the
--      master NACKs the address and closes with STOP, no data byte sent)
--
-- Checks:
--   * data: both written bytes land on the slave's data_received (rx_valid x2),
--     both read bytes land on the master's data_to_read (rx_valid x2), and the
--     pointer byte selects the read stream
--   * the master's ack output (the sampled slave ACK) is ACK for 1 and 2 and
--     NACK for 3
--   * CLOCK STRETCHING: exactly 3 / 5 / 0 G_STRETCH_CYCLES holds, every hold
--     inside a transaction (the master is busy), and SCL really is low for all
--     of them -- the master completes every frame despite all of them
--   * REPEATED START: the slave's busy flag rises/falls exactly once for frame 2
--     (the Sr does not end the frame, no STOP in between)
--   * both lines released after every transaction
--
-- Simulation-only file: do NOT register it in I2C_Slave.qsf.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity i2c_slave_master_tb is
end entity i2c_slave_master_tb;

architecture sim of i2c_slave_master_tb is

    constant C_CLK_PERIOD : time    := 20 ns;   -- 50 MHz
    constant C_SETTLE     : natural := 20;      -- clks to let pulses/counters land

    -- Addresses
    constant C_SLAVE_ADDR : std_logic_vector(6 downto 0) := "0111100";  -- 0x3C
    constant C_OTHER_ADDR : std_logic_vector(6 downto 0) := "1010001";  -- 0x51

    -- Master write stream (one byte handed over per tx_data_done)
    constant C_MW1        : std_logic_vector(7 downto 0) := x"C5";  -- frame 1, byte 1
    constant C_MW2        : std_logic_vector(7 downto 0) := x"3A";  -- frame 1, byte 2
    constant C_POINTER    : std_logic_vector(7 downto 0) := x"42";  -- frame 2, pointer
    constant C_FOREIGN_B  : std_logic_vector(7 downto 0) := x"99";  -- frame 3, ignored

    -- Slave read stream (frame 2, selected by the pointer byte)
    constant C_SR1        : std_logic_vector(7 downto 0) := x"77";
    constant C_SR2        : std_logic_vector(7 downto 0) := x"1B";

    -- Expected stretch holds per frame
    constant C_STRETCH_F1 : natural := 3;   -- address ACK + 2 write ACKs
    constant C_STRETCH_F2 : natural := 5;   -- write address ACK, pointer ACK,
                                            -- read address ACK after the Sr and
                                            -- the master's ACK + NACK after the
                                            -- two read bytes
    constant C_STRETCH_F3 : natural := 0;   -- never addressed

    -- Slave clock stretching: 500 clk = 10 us (two SCL low phases at 100 kHz)
    constant C_STRETCH_CYCLES : natural := 500;

    signal clk     : std_logic := '0';
    signal rst_n   : std_logic := '0';
    signal sda_bus : std_logic;
    signal scl_bus : std_logic;

    -- Master interface
    signal w              : std_logic := '0';
    signal r              : std_logic := '0';
    signal addr_m         : std_logic_vector(6 downto 0) := C_SLAVE_ADDR;
    signal n_write        : std_logic_vector(3 downto 0) := "0001";
    signal n_read         : std_logic_vector(3 downto 0) := "0000";
    signal m_tx_data      : std_logic_vector(7 downto 0) := C_MW1;
    signal m_data_to_read : std_logic_vector(7 downto 0);
    signal m_tx_done      : std_logic;
    signal m_tx_data_done : std_logic;
    signal m_rx_valid     : std_logic;
    signal m_busy         : std_logic;
    signal m_ack          : std_logic;

    -- Slave interface
    signal s_tx_data       : std_logic_vector(7 downto 0) := C_SR1;
    signal s_data_received : std_logic_vector(7 downto 0);
    signal s_rx_valid      : std_logic;
    signal s_tx_done       : std_logic;
    signal s_busy          : std_logic;
    signal s_stretching    : std_logic;

    -- Checker bookkeeping
    type byte_array_t is array (0 to 7) of std_logic_vector(7 downto 0);

    signal s_rx_cnt    : natural := 0;   -- slave rx_valid pulses
    signal s_tx_cnt    : natural := 0;   -- slave tx_done pulses
    signal s_rx_hist   : byte_array_t := (others => (others => '0'));
    signal s_busy_rise : natural := 0;
    signal s_busy_fall : natural := 0;
    signal s_busy_prev : std_logic := '0';
    signal m_rx_cnt    : natural := 0;   -- master rx_valid pulses
    signal m_rx_hist   : byte_array_t := (others => (others => '0'));
    signal m_txdata_cnt : natural := 0;  -- master tx_data_done pulses

    signal stretch_cnt : natural := 0;   -- clk periods the slave held SCL low
    signal stretch_bad : natural := 0;   -- ... where SCL was not low
    signal stretch_out : natural := 0;   -- ... outside a master transaction

    signal finished : boolean := false;

    -- Host model streams (one byte per handshake pulse, like a real system)
    constant MW_STREAM : byte_array_t := (1 => C_MW2, 2 => C_POINTER,
                                          3 => C_FOREIGN_B, others => x"00");
    constant SR_STREAM : byte_array_t := (1 => C_SR2, others => x"00");
    signal mw_idx : natural range 0 to 7 := 1;
    signal sr_idx : natural range 0 to 7 := 1;

    -- Request sequencer state (the process itself is in the statement part)
    type seq_state_t is (S_CFG, S_REQ, S_RUN, S_WAIT, S_DONE);
    signal seq_state : seq_state_t := S_CFG;
    signal step      : natural range 0 to 3 := 0;
    signal wait_cnt  : natural := 0;

    file results : text open write_mode is "results.txt";

begin

    clk <= not clk after C_CLK_PERIOD / 2 when not finished else '0';

    -- One shared open-drain bus: the TB only provides the external pull-ups.
    sda_bus <= 'H';
    scl_bus <= 'H';

    -- Reset: held long enough for the checker to be listening before the first
    -- transaction can start (the master's bus-free timer is preset, so a request
    -- is taken a few clocks after the release), then released.
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
    -- Both ends of the link: the existing controller and the new target.
    ---------------------------------------------------------------------------
    master : entity work.I2C_Master
        generic map (
            G_CLK_FREQ => 50_000_000,
            G_I2C_FREQ => 100_000
        )
        port map (
            clk              => clk,
            rst_n            => rst_n,
            w                => w,
            r                => r,
            addr             => addr_m,
            data_to_transmit => m_tx_data,
            n_write          => n_write,
            n_read           => n_read,
            data_to_read     => m_data_to_read,
            tx_done          => m_tx_done,
            tx_data_done     => m_tx_data_done,
            rx_valid         => m_rx_valid,
            busy             => m_busy,
            ack              => m_ack,
            sda              => sda_bus,
            scl              => scl_bus
        );

    slave : entity work.I2C_Slave
        generic map (
            G_SLAVE_ADDR     => C_SLAVE_ADDR,
            G_CLK_FREQ       => 50_000_000,
            G_I2C_FREQ       => 100_000,
            G_STRETCH_CYCLES => C_STRETCH_CYCLES
        )
        port map (
            clk              => clk,
            rst_n            => rst_n,
            data_to_transmit => s_tx_data,
            data_received    => s_data_received,
            rx_valid         => s_rx_valid,
            tx_done          => s_tx_done,
            busy             => s_busy,
            stretch_active   => s_stretching,
            sda              => sda_bus,
            scl              => scl_bus
        );

    ---------------------------------------------------------------------------
    -- Watchers (read-only observers of both boundaries)
    ---------------------------------------------------------------------------
    slave_watch : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                s_rx_cnt    <= 0;
                s_tx_cnt    <= 0;
                s_busy_rise <= 0;
                s_busy_fall <= 0;
                s_busy_prev <= '0';
                stretch_cnt <= 0;
                stretch_bad <= 0;
                stretch_out <= 0;
            else
                if s_rx_valid = '1' then
                    if s_rx_cnt < 8 then
                        s_rx_hist(s_rx_cnt) <= s_data_received;
                    end if;
                    s_rx_cnt <= s_rx_cnt + 1;
                end if;

                if s_tx_done = '1' then
                    s_tx_cnt <= s_tx_cnt + 1;
                end if;

                if s_busy = '1' and s_busy_prev = '0' then
                    s_busy_rise <= s_busy_rise + 1;
                elsif s_busy = '0' and s_busy_prev = '1' then
                    s_busy_fall <= s_busy_fall + 1;
                end if;
                s_busy_prev <= s_busy;

                -- Clock stretching: every period of a hold must have SCL low on
                -- the real bus, and must happen inside a master transaction.
                if s_stretching = '1' then
                    stretch_cnt <= stretch_cnt + 1;
                    if To_X01(scl_bus) /= '0' then
                        stretch_bad <= stretch_bad + 1;
                    end if;
                    if m_busy /= '1' then
                        stretch_out <= stretch_out + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Master side: read bytes and write-byte handovers.
    master_watch : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                m_rx_cnt     <= 0;
                m_txdata_cnt <= 0;
            else
                if m_rx_valid = '1' then
                    if m_rx_cnt < 8 then
                        m_rx_hist(m_rx_cnt) <= m_data_to_read;
                    end if;
                    m_rx_cnt <= m_rx_cnt + 1;
                end if;

                if m_tx_data_done = '1' then
                    m_txdata_cnt <= m_txdata_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Host models, exactly the handshakes a real system would use.
    ---------------------------------------------------------------------------
    master_host : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                m_tx_data <= C_MW1;
                mw_idx    <= 1;
            elsif m_tx_data_done = '1' then
                m_tx_data <= MW_STREAM(mw_idx);
                if mw_idx < 7 then
                    mw_idx <= mw_idx + 1;
                end if;
            end if;
        end if;
    end process;

    -- The pointer byte written by the master selects the read stream.
    slave_host : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                s_tx_data <= C_SR1;
                sr_idx    <= 1;
            elsif s_rx_valid = '1' and s_data_received = C_POINTER then
                s_tx_data <= C_SR1;          -- the pointed byte is read first
                sr_idx    <= 1;
            elsif s_tx_done = '1' then
                s_tx_data <= SR_STREAM(sr_idx);
                if sr_idx < 7 then
                    sr_idx <= sr_idx + 1;
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Request sequencer: the three transactions one after the other, with the
    -- same w/r handshake discipline the I2C_DUT uses (hold the request until the
    -- master reports busy, then drop it).
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
            else
                case seq_state is

                    -- Load the request for this step (address + byte counts)
                    when S_CFG =>
                        case step is
                            when 0 =>
                                addr_m  <= C_SLAVE_ADDR;   -- write 2 bytes
                                n_write <= "0010";
                                n_read  <= "0000";
                            when 1 =>
                                addr_m  <= C_SLAVE_ADDR;   -- write 1, Sr, read 2
                                n_write <= "0001";
                                n_read  <= "0010";
                            when others =>
                                addr_m  <= C_OTHER_ADDR;   -- foreign address
                                n_write <= "0001";
                                n_read  <= "0000";
                        end case;
                        seq_state <= S_REQ;

                    -- Raise the request; drop it once the master takes it
                    when S_REQ =>
                        w <= '1';
                        if m_busy = '1' then
                            w         <= '0';
                            seq_state <= S_RUN;
                        end if;

                    when S_RUN =>
                        if m_busy = '0' then
                            wait_cnt  <= C_SETTLE;
                            seq_state <= S_WAIT;
                        end if;

                    -- Settle, then move on to the next step
                    when S_WAIT =>
                        if wait_cnt = 0 then
                            if step = 2 then
                                seq_state <= S_DONE;
                            else
                                step      <= step + 1;
                                seq_state <= S_CFG;
                            end if;
                        else
                            wait_cnt <= wait_cnt - 1;
                        end if;

                    when S_DONE =>
                        null;

                end case;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Checker: one transaction at a time, delimited by the master's busy flag.
    ---------------------------------------------------------------------------
    checker : process
        variable L   : line;
        variable ok  : boolean := true;
        variable st0 : natural;
        variable sr0 : natural;
        variable br0 : natural;
        variable bf0 : natural;
        variable mr0 : natural;
        variable td0 : natural;

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

        -- Snapshot the counters at the start of a transaction ...
        procedure frame_start is
        begin
            wait until rising_edge(m_busy);
            st0 := stretch_cnt;
            sr0 := s_rx_cnt;
            br0 := s_busy_rise;
            bf0 := s_busy_fall;
            mr0 := m_rx_cnt;
            td0 := m_txdata_cnt;
        end procedure;

        -- ... and let it finish (plus a settle window) before checking.
        procedure frame_end is
        begin
            wait until falling_edge(m_busy);
            clk_ticks(C_SETTLE);
        end procedure;
    begin
        -- Both ends are still in reset: the idle state must already be clean.
        -- The checker must be WAITING for the first frame before the reset is
        -- released, otherwise it would miss the first busy rise.
        clk_ticks(5);
        check(m_busy = '0' and s_busy = '0', "reset: a busy flag is asserted");
        check(To_X01(scl_bus) = '1' and To_X01(sda_bus) = '1',
              "reset: bus not released");

        -- ------------------------------------------------------------------
        -- Frame 1: write 2 bytes (0xC5, 0x3A) to 0x3C.
        -- ACK cells: address + 2 data bytes -> 3 stretch holds.
        -- ------------------------------------------------------------------
        frame_start;
        frame_end;

        check(s_rx_cnt - sr0 = 2, "frame 1: slave rx_valid pulse count");
        check_eq(s_rx_hist(sr0), C_MW1, "frame 1: first written byte");
        check_eq(s_rx_hist(sr0 + 1), C_MW2, "frame 1: second written byte");
        check_eq(s_data_received, C_MW2, "frame 1: slave data_received");
        check(m_txdata_cnt - td0 = 2, "frame 1: master write-byte handovers");
        check(m_ack = '0', "frame 1: master sampled a NACK");
        check(stretch_cnt - st0 = C_STRETCH_F1 * C_STRETCH_CYCLES,
              "frame 1: stretch total (3 ACK cells)");
        check(s_busy_rise - br0 = 1 and s_busy_fall - bf0 = 1,
              "frame 1: slave busy must rise and fall exactly once");
        check(m_rx_cnt = mr0, "frame 1: master read data in a write-only frame");
        check(To_X01(scl_bus) = '1' and To_X01(sda_bus) = '1',
              "frame 1: bus not released after the transaction");

        -- ------------------------------------------------------------------
        -- Frame 2: write the pointer 0x42, REPEATED START, read 2 bytes.
        -- ACK cells: address + write byte + address after Sr + read byte
        -- -> 4 stretch holds, and the slave must stay addressed across the Sr.
        -- ------------------------------------------------------------------
        frame_start;
        frame_end;

        check(s_rx_cnt - sr0 = 1, "frame 2: slave rx_valid pulse count");
        check_eq(s_rx_hist(sr0), C_POINTER, "frame 2: pointer byte written");
        check(m_rx_cnt - mr0 = 2, "frame 2: master rx_valid pulse count");
        check_eq(m_rx_hist(mr0), C_SR1, "frame 2: first byte read back");
        check_eq(m_rx_hist(mr0 + 1), C_SR2, "frame 2: second byte read back");
        check(m_txdata_cnt - td0 = 1, "frame 2: master write-byte handovers");
        check(m_ack = '0', "frame 2: master sampled a NACK on the re-address");
        check(stretch_cnt - st0 = C_STRETCH_F2 * C_STRETCH_CYCLES,
              "frame 2: stretch total (5 ACK cells over both phases)");
        check(s_busy_rise - br0 = 1 and s_busy_fall - bf0 = 1,
              "frame 2: the Sr must not end the slave frame (one busy rise/fall)");
        check(To_X01(scl_bus) = '1' and To_X01(sda_bus) = '1',
              "frame 2: bus not released after the transaction");

        -- ------------------------------------------------------------------
        -- Frame 3: a foreign address. The slave must stay silent -- no ACK, no
        -- stretch, no busy, and the master sees a NACK and closes with STOP.
        -- ------------------------------------------------------------------
        frame_start;
        frame_end;

        check(s_rx_cnt = sr0, "frame 3: slave rx_valid pulsed on a foreign frame");
        check(s_busy_rise = br0 and s_busy_fall = bf0,
              "frame 3: slave busy changed state on a foreign frame");
        check(stretch_cnt = st0, "frame 3: slave stretched a foreign frame");
        -- The master NACKs the foreign address and closes with STOP, so no data
        -- byte is ever handed over in this frame.
        check(m_txdata_cnt - td0 = 0, "frame 3: a write byte was handed over");
        check(m_ack = '1', "frame 3: master should have sampled a NACK");
        check(To_X01(scl_bus) = '1' and To_X01(sda_bus) = '1',
              "frame 3: bus not released after the transaction");

        -- Summary -----------------------------------------------------------
        check(stretch_bad = 0, "a stretch hold ran while SCL was not low");
        check(stretch_out = 0, "a stretch hold ran outside a master transaction");
        check(m_txdata_cnt = 3, "master write-byte handover total (2 + 1 + 0)");
        check(s_rx_cnt = 3, "slave rx_valid total (2 + 1 + 0)");
        check(s_tx_cnt = 2, "slave tx_done total (0 + 2 + 0)");

        if ok then
            write(L, string'("RESULT: PASS -- master/slave link: write, Sr read-back and address filtering, with "));
            write(L, C_STRETCH_CYCLES);
            write(L, string'(" clk stretch holds the master tolerated"));
        else
            write(L, string'("RESULT: FAIL"));
        end if;
        writeline(results, L);
        if ok then
            report "RESULT: PASS -- I2C_Master + I2C_Slave link verified (stretching + Sr)"
                severity note;
        else
            report "RESULT: FAIL -- see results.txt" severity error;
        end if;
        finished <= true;
        wait;
    end process;

    -- Watchdog: very loud failure if any phase hangs.
    watchdog : process
    begin
        wait for 4 ms;
        assert finished report "i2c_slave_master_tb timed out" severity failure;
        wait;
    end process;

end architecture sim;
