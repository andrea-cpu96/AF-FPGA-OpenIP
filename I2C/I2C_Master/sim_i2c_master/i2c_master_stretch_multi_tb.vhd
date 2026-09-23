-- i2c_master_stretch_multi_tb.vhd
-- Combined repeated-START + multi clock-stretching regression for I2C_Master.
-- ONE transaction that uses both features at once:
--   addr(W) + 0x55 + 0x3A + ACK .. REPEATED START .. addr(R) + 0xA7 + 0x1B
--   + 0xE4 (master NACKs the last byte) .. STOP
-- The slave stretches SCL TEN times, at ten different points of the transfer,
-- with ten different durations -- mid-cell holds as well as ACK-cell holds,
-- and holds longer than a whole SCL period (the nominal SCL period is 500 clk
-- = 10 us, so an entry above 250 clk really extends the bus low phase).
-- The slave is black-box (no hierarchical DUT access).
-- What it checks, on the wire:
--   * the master NEVER raises SCL while the slave holds it low: asserted on
--     every clock of every stretch, i.e. the bus is provably low for the whole
--     held window
--   * every scripted stretch happened exactly once and lasted at least the
--     requested number of clk cycles (str_count / str_obs, plus the per-clock
--     monitor: together they prove the low time was really extended)
--   * the transfer survives the stretching: both address bytes (with the right
--     R/W bit), both write bytes, all three read bytes, the master's ACK on
--     every read byte but the last (NACK), data_to_read and the
--     tx_done / rx_valid pulse counts
--   * the repeated START is a REAL Sr and not a STOP+START: no STOP condition
--     (an SDA rise while SCL is high) may occur between the last write ACK and
--     the Sr, and the Sr may not be generated while SCL is still stretched
--     (a timing-gap heuristic cannot be used here, the cell before the Sr is
--     stretched for 20 us)
--   * the bus is released (both lines high) once the FSM is back at IDLE
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_master_stretch_multi_tb is
end entity i2c_master_stretch_multi_tb;

architecture sim of i2c_master_stretch_multi_tb is

    constant C_ADDR : std_logic_vector(6 downto 0) := "1010001";   -- 0x51
    constant C_SETTLE : time := 200 ns;

    type mem_a is array (natural range <>) of std_logic_vector(7 downto 0);
    constant WR_BYTES : mem_a(0 to 1) := (x"55", x"3A");   -- master sends these
    constant RD_BYTES : mem_a(0 to 2) := (x"A7", x"1B", x"E4");  -- slave drives

    -- Stretch script: clk cycles the slave holds SCL low, one entry per hold.
    type int_a is array (natural range <>) of natural;
    constant C_STR_CLKS : int_a(0 to 9) := (
        300,     -- 0: middle of the first address byte (bit cell 4)
        260,     -- 1: ACK cell of the first address byte
        420,     -- 2: ACK cell of write byte 0
        700,     -- 3: middle of write byte 1 (bit cell 6)
        1000,    -- 4: ACK cell of write byte 1 -- the cell before the Sr (20 us)
        340,     -- 5: middle of the re-sent address byte (bit cell 3)
        620,     -- 6: ACK cell of the re-sent address byte
        460,     -- 7: ACK cell of read byte 0
        880,     -- 8: middle of read byte 1 (bit cell 4)
        1120);   -- 9: NACK cell of the last read byte -- the cell before STOP
    constant C_N_STRETCH : natural := 10;

    signal clk              : std_logic := '0';
    signal rst_n            : std_logic := '0';
    signal w                : std_logic := '0';
    signal n_write          : std_logic_vector(3 downto 0) := "0010";
    signal n_read           : std_logic_vector(3 downto 0) := "0011";
    signal sda_bus          : std_logic;
    signal scl_bus          : std_logic;
    signal sda_low          : std_logic := '0';   -- slave pulls SDA low
    signal data_to_transmit : std_logic_vector(7 downto 0) := (others => '0');
    signal data_to_read     : std_logic_vector(7 downto 0);
    signal tx_done          : std_logic;
    signal tx_data_done     : std_logic;
    -- TB-domain bus observation: edge pulses and the two framing conditions
    signal scl_obs      : std_logic;
    signal scl_prev_tb  : std_logic := '1';
    signal sda_prev_tb  : std_logic := '1';
    signal scl_rise_p   : std_logic;
    signal scl_fall_p   : std_logic;
    signal sr_start_ev  : std_logic;  -- SDA fell while SCL was high: START or Sr
    signal stop_cond_ev : std_logic;  -- SDA rose while SCL was high: STOP

    -- Slave model state
    type sl_t is (S_IDLE, S_ADDR, S_ACKA, S_WDATA, S_WACK,
                  S_WAIT_SR, S_RDATA, S_RACK, S_DONE);
    signal sl_st      : sl_t := S_IDLE;
    signal bit_cnt    : natural range 0 to 8 := 0;
    signal wr_idx     : natural range 0 to 3 := 0;
    signal rd_idx     : natural range 0 to 3 := 0;
    signal addr_phase : natural range 0 to 3 := 0;   -- 1 = first, 2 = after Sr
    signal addr1_byte : std_logic_vector(7 downto 0) := (others => '0');
    signal addr2_byte : std_logic_vector(7 downto 0) := (others => '0');
    signal sl_wr0     : std_logic_vector(7 downto 0) := (others => '0');
    signal sl_wr1     : std_logic_vector(7 downto 0) := (others => '0');
    signal rd_drive   : std_logic_vector(7 downto 0) := (others => '0');
    signal master_ack0 : std_logic := '0';   -- master ACK/NACK after read byte 0
    signal master_ack1 : std_logic := '0';   -- .. after read byte 1
    signal master_ack2 : std_logic := '0';   -- .. after read byte 2 (NACK wanted)
    signal ack_cnt     : natural range 0 to 7 := 0;
    signal sr_seen    : std_logic := '0';
    signal sr_win     : std_logic := '0';   -- window where a STOP would be illegal
    signal stop_seen  : std_logic := '0';   -- a STOP condition seen in that window
    signal stop_final_seen : std_logic := '0'; -- valid STOP at transaction end
    signal rel_cnt    : natural range 0 to 1023 := 0;
    signal rel_arm    : std_logic := '0';

    -- Slave clock-stretch engine
    signal str_req     : std_logic := '0';                     -- one-clk request
    signal str_len     : natural range 1 to 4095 := 1;         -- clk cycles
    signal str_hold    : std_logic := '0';                     -- hold SCL low
        signal scl_stretch_active : std_logic := '0';               -- waveform marker: slave is stretching SCL
    signal str_cnt     : natural range 0 to 4095 := 0;
    signal str_idx     : natural range 0 to C_N_STRETCH - 1 := 0;
    signal str_count   : natural range 0 to 31 := 0;           -- holds accepted
    signal str_obs     : int_a(0 to C_N_STRETCH - 1) := (others => 0);
    signal str_obs_cnt : natural range 0 to 4095 := 0;
    signal str_rel     : std_logic := '0';     -- one-clk pulse: hold released

    -- Checker bookkeeping
    signal tx_cnt     : natural range 0 to 63 := 0;
    signal rx_idx     : natural range 0 to 15 := 0;
    signal rx_hist    : mem_a(0 to 3) := (others => (others => '0'));
    signal rx_valid_d : std_logic := '0';
    signal sr_cnt     : natural range 0 to 15 := 0;   -- START/Sr events seen
    signal gap_cnt    : natural := 0;
    signal gap_arm    : std_logic := '0';             -- measuring the pre-Sr cell
    signal rx_valid         : std_logic;
    signal finished         : boolean := false;

begin
    clk <= not clk after 10 ns when not finished else '0';

    -- Open-drain bus with external pull-ups: neither side ever drives high
    sda_bus <= 'H';
    scl_bus <= 'H';
    sda_bus <= '0' when sda_low  = '1' else 'Z';
    scl_bus <= '0' when str_hold = '1' else 'Z';   -- slave clock stretching

    scl_obs <= To_X01(scl_bus);

    scl_stretch_active <= str_hold;

    edge_tb : process(clk)
    begin
        if rising_edge(clk) then
            scl_prev_tb <= scl_obs;
            sda_prev_tb <= To_X01(sda_bus);
        end if;
    end process;

    scl_rise_p  <= '1' when (scl_obs = '1' and scl_prev_tb = '0') else '0';
    scl_fall_p  <= '1' when (scl_obs = '0' and scl_prev_tb = '1') else '0';
    -- START / repeated START: SDA falls while SCL is high
    sr_start_ev <= '1' when (To_X01(sda_bus) = '0' and sda_prev_tb = '1'
                             and scl_obs = '1') else '0';
    -- STOP: SDA rises while SCL is high
    stop_cond_ev <= '1' when (To_X01(sda_bus) = '1' and sda_prev_tb = '0'
                              and scl_obs = '1') else '0';

    dut : entity work.I2C_Master
        generic map (G_CLK_FREQ => 50_000_000, G_I2C_FREQ => 100_000)
        port map (
            clk => clk, rst_n => rst_n, w => w, r => '0',
            addr => C_ADDR,
            n_write => n_write, n_read => n_read,
            data_to_transmit => data_to_transmit,
            data_to_read => data_to_read,
            tx_done => tx_done, tx_data_done => tx_data_done, rx_valid => rx_valid,
            busy => open, ack => open,
            sda => sda_bus, scl => scl_bus
        );

    -- Clock-stretch engine: turns the slave's one-clk requests into a real
    -- SCL pull-down that lasts exactly the requested number of clk cycles, and
    -- measures how long the hold actually lasted.
    stretch_eng : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                str_hold    <= '0';
                str_cnt     <= 0;
                str_count   <= 0;
                str_obs_cnt <= 0;
                str_rel     <= '0';
            else
                str_rel <= '0';   -- one-clk release pulse
                if str_req = '1' then
                    assert str_hold = '0'
                        report "Slave stretch requests overlap" severity failure;
                    assert str_count < C_N_STRETCH
                        report "More stretches than scripted" severity failure;
                    str_hold    <= '1';
                    str_cnt     <= str_len;
                    str_idx     <= str_count;
                    str_count   <= str_count + 1;
                    str_obs_cnt <= 0;
                    report "Stretch " & integer'image(str_count) & " requested, " &
                           integer'image(str_len) & " clk held low"
                        severity note;
                elsif str_hold = '1' then
                    if str_cnt <= 1 then
                        str_hold    <= '0';            -- release the clock
                        str_cnt     <= 0;
                        str_obs(str_idx) <= str_obs_cnt + 1;
                        str_rel     <= '1';
                    else
                        str_cnt     <= str_cnt - 1;
                        str_obs_cnt <= str_obs_cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- The master must never raise SCL while the slave is holding it low:
    -- checked on every clock of every stretch.
    stretch_mon : process(clk)
    begin
        if rising_edge(clk) then
            if str_hold = '1' then
                assert scl_obs = '0'
                    report "Master raised SCL while the slave was stretching it"
                    severity failure;
            end if;
        end if;
    end process;

    -- Slave: one I2C target that answers the whole transaction. It also asks
    -- for the ten scripted stretches, each one at a different point of the
    -- transfer (mid-cell holds and ACK-cell holds).
    -- Bit numbering: bit_cnt counts the bits already sampled in the current
    -- byte, so the fall inside a data state with bit_cnt = 3 closes the third
    -- bit cell -- i.e. it is the entry into the fourth cell's low phase, which
    -- is where a mid-byte hold belongs. The same fall with bit_cnt = 8 closes
    -- the byte and opens the ACK cell, which is where the ACK-cell holds
    -- belong.
    slave_fsm : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                sl_st      <= S_IDLE;
                bit_cnt    <= 0;
                wr_idx     <= 0;
                rd_idx     <= 0;
                addr_phase <= 0;
                sda_low    <= '0';
                sr_cnt     <= 0;
                ack_cnt    <= 0;
                str_req    <= '0';
            else
                -- str_req is a one-clk pulse: the slave raises it for the clock
                -- in which it wants the next hold to start and drops it again
                -- here, so it is driven by exactly one process.
                str_req <= '0';
                -- An SDA fall while SCL is high is the START condition, and the
                -- same shape mid-transaction is the repeated START: the slave
                -- (re)synchronises on it, exactly like a real target does.
                if sr_start_ev = '1' then
                    sr_cnt <= sr_cnt + 1;
                    if sl_st = S_IDLE then
                        addr_phase <= 1;
                        bit_cnt    <= 0;
                        sl_st      <= S_ADDR;
                    elsif sl_st = S_WAIT_SR then
                        addr_phase <= 2;
                        bit_cnt    <= 0;
                        sl_st      <= S_ADDR;
                        sr_seen    <= '1';
                    end if;
                end if;

                case sl_st is

                    when S_IDLE =>
                        null;   -- waiting for the first START

                    when S_ADDR =>
                        if scl_rise_p = '1' and bit_cnt < 8 then
                            if addr_phase = 1 then
                                addr1_byte(7 - bit_cnt) <= To_X01(sda_bus);
                            else
                                addr2_byte(7 - bit_cnt) <= To_X01(sda_bus);
                            end if;
                            bit_cnt <= bit_cnt + 1;
                        end if;
                        if scl_fall_p = '1' then
                            if bit_cnt = 8 then
                                -- byte complete: drive the address ACK low in
                                -- the bit cell that starts here, and stretch
                                -- this ACK cell (index 1: first address,
                                -- index 6: the address re-sent after the Sr)
                                sda_low <= '1';
                                sl_st   <= S_ACKA;
                                str_req <= '1';
                                if addr_phase = 1 then
                                    str_len <= C_STR_CLKS(1);
                                else
                                    str_len <= C_STR_CLKS(6);
                                end if;
                            elsif bit_cnt = 3 then
                                -- mid-byte hold (before the fourth bit cell)
                                str_req <= '1';
                                if addr_phase = 1 then
                                    str_len <= C_STR_CLKS(0);
                                else
                                    str_len <= C_STR_CLKS(5);
                                end if;
                            end if;
                        end if;

                    when S_ACKA =>
                        -- The slave owns SDA here (sda_low = '1' since the end of
                        -- S_ADDR): that is the address acknowledge the master
                        -- must sample. The hold on this cell is scripted once
                        -- per address phase, requested at the byte's last fall
                        -- (index 1: first address, index 6: after the Sr).
                        if scl_fall_p = '1' then
                            bit_cnt <= 0;
                            if addr_phase = 1 then
                                if addr1_byte(0) = '0' then
                                    sda_low <= '0';
                                    sl_st  <= S_WDATA;    -- write phase: data follows
                                    wr_idx <= 0;
                                else
                                    sda_low    <= not RD_BYTES(0)(7);
                                    sl_st      <= S_RDATA;  -- read phase
                                    rd_idx     <= 0;
                                    rd_drive   <= RD_BYTES(0);
                                end if;
                            else
                                if addr2_byte(0) = '1' then
                                    sda_low  <= not RD_BYTES(0)(7);
                                    sl_st    <= S_RDATA;    -- repeated START turned
                                    rd_idx   <= 0;          -- the direction to read
                                    rd_drive <= RD_BYTES(0);
                                else
                                    sda_low <= '0';
                                    sl_st  <= S_WDATA;
                                    wr_idx <= 0;
                                end if;
                            end if;
                        end if;

                    when S_WDATA =>
                        if scl_rise_p = '1' and bit_cnt < 8 then
                            if wr_idx = 0 then
                                sl_wr0(7 - bit_cnt) <= To_X01(sda_bus);
                            else
                                sl_wr1(7 - bit_cnt) <= To_X01(sda_bus);
                            end if;
                            bit_cnt <= bit_cnt + 1;
                        end if;
                        if scl_fall_p = '1' then
                            if bit_cnt = 8 then
                                sda_low <= '1';
                                sl_st   <= S_WACK;
                                -- stretch this ACK cell too (index 2: first
                                -- write byte, index 4: last write byte -- the
                                -- cell that immediately precedes the Sr)
                                str_req <= '1';
                                if wr_idx = 0 then
                                    str_len <= C_STR_CLKS(2);
                                else
                                    str_len <= C_STR_CLKS(4);
                                end if;
                            elsif bit_cnt = 3 then
                                if wr_idx = 1 then
                                    str_req <= '1';   -- mid-byte hold, 2nd byte only
                                    str_len <= C_STR_CLKS(3);
                                end if;
                            end if;
                        end if;

                    when S_WACK =>
                        -- Hold on this ACK cell is scripted for both write bytes
                        -- (index 2: first byte, index 4: the last one, i.e. the
                        -- cell that immediately precedes the repeated START).
                        if scl_fall_p = '1' then
                            sda_low <= '0';
                            bit_cnt <= 0;
                            if wr_idx < WR_BYTES'length - 1 then
                                wr_idx <= wr_idx + 1;
                                sl_st  <= S_WDATA;
                            else
                                sl_st <= S_WAIT_SR;   -- transaction is waiting for Sr
                            end if;
                        end if;

                    when S_WAIT_SR =>
                        null;   -- the Sr is handled by the START detector above

                    when S_RDATA =>
                        if scl_rise_p = '1' and bit_cnt < 8 then
                            bit_cnt <= bit_cnt + 1;
                        end if;
                        if scl_fall_p = '1' then
                            if bit_cnt = 8 then
                                sda_low <= '0';
                                sl_st   <= S_RACK;
                                if rd_idx = 0 or rd_idx = RD_BYTES'length - 1 then
                                    -- stretch the cell that follows this byte:
                                    -- index 7 (master ACK cell of the first read
                                    -- byte) or index 9 (the NACK cell of the
                                    -- last read byte, right before STOP)
                                    str_req <= '1';
                                    if rd_idx = 0 then
                                        str_len <= C_STR_CLKS(7);
                                    else
                                        str_len <= C_STR_CLKS(9);
                                    end if;
                                end if;
                            else
                                sda_low <= not rd_drive(7 - bit_cnt);
                                if bit_cnt = 4 and rd_idx = 1 then
                                    str_req <= '1';   -- mid-byte hold, 2nd read byte
                                    str_len <= C_STR_CLKS(8);
                                end if;
                            end if;
                        end if;

                    when S_RACK =>
                        -- The master ACKs every read byte but the last one, where
                        -- it must NACK so the slave releases the bus for the STOP.
                        if scl_rise_p = '1' then
                            ack_cnt <= ack_cnt + 1;
                            case rd_idx is
                                when 0 => master_ack0 <= To_X01(sda_bus);
                                when 1 => master_ack1 <= To_X01(sda_bus);
                                when others => master_ack2 <= To_X01(sda_bus);
                            end case;
                        end if;
                        if scl_fall_p = '1' then
                            if rd_idx < RD_BYTES'length - 1 then
                                rd_idx   <= rd_idx + 1;
                                rd_drive <= RD_BYTES(rd_idx + 1);
                                sda_low  <= not RD_BYTES(rd_idx + 1)(7);
                                bit_cnt  <= 0;
                                sl_st    <= S_RDATA;
                            else
                                sl_st <= S_DONE;      -- NACK: the transaction ends
                            end if;
                        end if;

                    when S_DONE =>
                        null;   -- released the bus; waiting for the STOP

                end case;
            end if;
        end if;
    end process;

    -- Streaming handshake bookkeeping: tx_done pulses once per serialized byte,
    -- rx_valid once per byte that landed in data_to_read.
    tx_cnt_p : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                tx_cnt <= 0;
            elsif tx_done = '1' then
                tx_cnt <= tx_cnt + 1;
            end if;
        end if;
    end process;

    -- data_to_read is updated on the same edge that raises rx_valid, so it is
    -- sampled one clk after the pulse.
    rx_cap_p : process(clk)
    begin
        if rising_edge(clk) then
            rx_valid_d <= rx_valid;
            if rx_valid_d = '1' then
                if rx_idx < 4 then
                    rx_hist(rx_idx) <= data_to_read;
                end if;
                rx_idx <= rx_idx + 1;
            end if;
        end if;
    end process;

    -- The held low time must really be the scripted one: measuring the window
    -- in clk cycles proves the requested stretch was not cut short, and (with
    -- the per-clock monitor above) that the master waited it out.
    str_check_p : process
    begin
        wait until rst_n = '1';
        -- let the whole transaction and all ten holds happen
        wait until sl_st = S_DONE;
        wait for 1 us;
        assert str_count = C_N_STRETCH
            report "Not all scripted stretches were requested: only " &
                   integer'image(str_count) & " of " & integer'image(C_N_STRETCH)
            severity failure;
        for i in str_obs'range loop
            assert str_obs(i) >= C_STR_CLKS(i)
                report "A clock stretch was shorter than scripted"
                severity failure;
        end loop;
        report "Stretch log: all " & integer'image(C_N_STRETCH) &
               " holds were honoured with the full duration" severity note;
        wait;
    end process;

    -- Three wire-level properties, all measured by the TB itself:
    --  1. the cell that immediately precedes the Sr is held for C_STR_CLKS(4)
    --     cycles, so the repeated START may only appear after that cell really
    --     ended. If the master timed the step on its own divider instead of the
    --     bus it would fall through early -- rejected here.
    --  2. no STOP condition (SDA rising while SCL is high) may appear between
    --     the last write ACK and the Sr: that would mean the master pretended
    --     to end the transaction and started a new one instead of repeating the
    --     START within the same transfer.
    --  3. once the slave releases a stretched clock, the master must resume it
    --     within roughly one divider period (a full low phase is 250 clk): any
    --     longer gap means the master lost the bus instead of waiting it out.
    sv_check_p : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                gap_cnt   <= 0;
                gap_arm   <= '0';
                sr_win    <= '0';
                stop_seen <= '0';
                stop_final_seen <= '0';
                rel_cnt   <= 0;
                rel_arm   <= '0';
            else
                -- (1) pre-Sr gap, armed by the hold request that starts that cell
                if str_req = '1' and str_count = 4 then
                    gap_arm <= '1';
                    gap_cnt <= 0;
                elsif gap_arm = '1' then
                    if sr_cnt = 2 then         -- the repeated START is on the wire
                        gap_arm <= '0';
                        assert gap_cnt >= C_STR_CLKS(4)
                            report "Repeated START came too early: the master did not wait for the stretched cell to end"
                            severity failure;
                    else
                        gap_cnt <= gap_cnt + 1;
                    end if;
                end if;

                -- (2) illegal-STOP window: open while the pre-Sr cell is held,
                -- closed by the Sr itself
                if sr_cnt = 2 then
                    sr_win <= '0';
                elsif str_req = '1' and str_count = 4 then
                    sr_win <= '1';
                end if;
                if sr_win = '1' and stop_cond_ev = '1' then
                    stop_seen <= '1';
                end if;
                if stop_cond_ev = '1' then
                    stop_final_seen <= '1';
                end if;

                -- (3) the master must resume SCL after the slave releases it
                if str_rel = '1' then
                    rel_arm <= '1';
                    rel_cnt <= 0;
                elsif rel_arm = '1' then
                    if scl_obs = '1' then
                        rel_arm <= '0';
                        assert rel_cnt <= 400
                            report "SCL stayed low long after the slave released it: the master did not resume"
                            severity failure;
                    else
                        rel_cnt <= rel_cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    stim : process
        -- Bounded waits: if the DUT misbehaves, the checks below report a
        -- diagnosable failure instead of hanging until the watchdog fires.
        variable v_to  : natural := 0;
        variable v_got : natural := 0;
    begin
        wait for 100 ns;
        assert data_to_read = x"00"
            report "Read output not zero during reset" severity failure;
        assert tx_done = '0' and rx_valid = '0'
            report "Handshake pulses active during reset" severity failure;
        rst_n <= '1';
        wait for C_SETTLE;

        assert scl_bus = 'H' and sda_bus = 'H'
            report "Bus not released before the transaction" severity failure;

        ------------------------------------------------------------------
        -- W2 - Sr - R3: repeated START and ten clock stretches in one run
        ------------------------------------------------------------------
        n_write <= std_logic_vector(to_unsigned(WR_BYTES'length, 4));
        n_read  <= std_logic_vector(to_unsigned(RD_BYTES'length, 4));
        data_to_transmit <= WR_BYTES(0);   -- first write byte ready up front
        w <= '1';
        wait until falling_edge(sda_bus);  -- START condition
        w <= '0';

        wait until rising_edge(tx_done);        -- 1: address byte (W) sent
        wait until rising_edge(tx_data_done);   -- 2: WR_BYTES(0) sent (stream on the data-only pulse)
        data_to_transmit <= WR_BYTES(1);        -- in time: handover is a cell away
        wait until rising_edge(tx_done);        -- 3: write phase done

        wait until rising_edge(tx_done);   -- 4: address byte (R) re-sent after Sr
        wait until sl_st = S_DONE;         -- NACK cell of the last read byte
        wait for 40 us;                    -- STOP, then back to idle
        wait for 1 us;                     -- settle the handshake counters

        ------------------------------------------------------------------
        -- Checks (all black box: everything is observed on the wire)
        ------------------------------------------------------------------
        assert scl_bus = 'H' and sda_bus = 'H'
            report "Bus not released after the transaction" severity failure;

        -- exactly one START and one repeated START, and the repeated START is a
        -- real Sr shape (SDA falls while SCL is high), otherwise the slave would
        -- never have re-addressed
        assert sr_cnt = 2
            report "Expected exactly one START and one repeated START"
            severity failure;
        assert sr_seen = '1'
            report "The repeated START did not arrive while the slave was still in the transfer (a STOP+START was used instead of Sr)"
            severity failure;
        assert stop_seen = '0'
            report "A STOP condition appeared before the repeated START"
            severity failure;
        assert stop_final_seen = '1'
            report "No valid STOP condition was observed at the end of the transaction"
            severity failure;

        assert addr1_byte = C_ADDR & '0'
            report "First address byte wrong (must be addr + W)" severity failure;
        assert addr2_byte = C_ADDR & '1'
            report "Re-sent address byte wrong (must be addr + R)" severity failure;
        assert sl_wr0 = WR_BYTES(0) and sl_wr1 = WR_BYTES(1)
            report "Write bytes wrong on the wire" severity failure;

        assert ack_cnt = 3
            report "The three read ACK/NACK cells were not all sampled"
            severity failure;
        assert master_ack0 = '0' and master_ack1 = '0'
            report "Master did not ACK a non-final read byte" severity failure;
        assert master_ack2 = '1'
            report "Master did not NACK the last read byte" severity failure;

        assert tx_cnt = 4
            report "Unexpected tx_done pulse count (addr/W + 2 write + addr/R)"
            severity failure;
        assert rx_idx = 3
            report "Unexpected rx_valid pulse count" severity failure;
        assert rx_hist(0) = RD_BYTES(0) and rx_hist(1) = RD_BYTES(1)
            report "Read bytes wrong on data_to_read" severity failure;
        assert data_to_read = RD_BYTES(2)
            report "Final data_to_read wrong" severity failure;

        report "RESULT: PASS -- W2-Sr-R3 with ten clock-stretch holds" severity note;
        finished <= true;
        wait;
    end process;

    watchdog : process
    begin
        wait for 3 ms;
        assert finished
            report "Repeated-START + clock-stretching test timed out"
            severity failure;
        wait;
    end process;

end architecture sim;
