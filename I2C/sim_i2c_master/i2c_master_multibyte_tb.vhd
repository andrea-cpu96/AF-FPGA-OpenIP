-- i2c_master_multibyte_tb.vhd
-- Multi-byte + repeated-START regression for I2C_Master (n_write/n_read
-- interface). Two scripted scenarios back to back, no reset in between:
--   1. W3        : n_write=3, n_read=0  -- plain three-byte write (bytes
--                  x"11", x"22", x"33" streamed onto data_to_transmit on
--                  the tx_done pulses)
--   2. W1-Sr-R2  : n_write=1, n_read=2 -- write x"55", REPEATED START,
--                  re-address with R/W=1, read x"C3" (master ACK) and x"7E"
--                  (master NACK on the last byte)
-- The slave is black-box (no hierarchical DUT access). It follows the
-- scripted plan (ACK every byte it receives, drive the read bytes) and
-- checks on the wire:
--   * both address bytes (7-bit addr + correct R/W bit)
--   * every written byte
--   * the master's ACK / NACK for the read bytes
--   * the repeated START itself: an SDA fall while SCL is high, occurring
--     within the same bit cell after the last write ACK (a STOP+new START
--     would be ~10 us later -- the gap check tells them apart)
-- Stim checks: tx_done / rx_valid pulse counts, the streamed read bytes,
-- and that both lines are released (idle high) after each transaction.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_master_multibyte_tb is
end entity i2c_master_multibyte_tb;

architecture sim of i2c_master_multibyte_tb is
    constant C_ADDR   : std_logic_vector(6 downto 0) := "1010001";
    constant C_SETTLE : time := 200 ns;

    type mem_a is array (0 to 3) of std_logic_vector(7 downto 0);
    constant RD_BYTES : mem_a := (x"C3", x"7E", x"00", x"00");  -- slave drives these

    signal clk              : std_logic := '0';
    signal rst_n            : std_logic := '0';
    signal w                : std_logic := '0';
    signal r                : std_logic := '0';
    signal n_write          : std_logic_vector(3 downto 0) := "0001";
    signal n_read           : std_logic_vector(3 downto 0) := "0000";
    signal sda_bus          : std_logic;
    signal scl_bus          : std_logic;
    signal sda_low          : std_logic := '0';   -- slave pulls SDA low
    signal scl_obs          : std_logic;
    signal data_to_transmit : std_logic_vector(7 downto 0) := (others => '0');
    signal data_to_read     : std_logic_vector(7 downto 0);
    signal tx_done          : std_logic;
    signal rx_valid         : std_logic;
    signal finished         : boolean := false;

    -- TB-domain SCL edge pulses and SDA history
    signal scl_prev_tb : std_logic := '1';
    signal sda_prev_tb : std_logic := '1';
    signal scl_rise_p  : std_logic;
    signal scl_fall_p  : std_logic;
    signal sr_start_ev : std_logic;   -- SDA fell while SCL was high: START or Sr

    -- Slave model state
    type sl_t is (S_IDLE, S_ADDR, S_ACKA, S_WDATA, S_WACK,
                  S_WAIT_SR, S_RDATA, S_RACK, S_DONE);
    signal sl_st     : sl_t := S_IDLE;
    signal bit_cnt   : natural range 0 to 8 := 0;
    signal wr_idx    : natural range 0 to 3 := 0;
    signal rd_idx    : natural range 0 to 3 := 0;
    signal addr_byte : std_logic_vector(7 downto 0) := (others => '0');
    signal last_rw   : std_logic := '0';
    signal rd_drive  : std_logic_vector(7 downto 0) := (others => '0');
    signal sl_wr0    : std_logic_vector(7 downto 0) := (others => '0');
    signal sl_wr1    : std_logic_vector(7 downto 0) := (others => '0');
    signal sl_wr2    : std_logic_vector(7 downto 0) := (others => '0');
    signal sl_wr3    : std_logic_vector(7 downto 0) := (others => '0');
    signal master_ack0 : std_logic := '0';
    signal master_ack1 : std_logic := '0';
    signal sr_seen   : std_logic := '0';
    signal sr_gap_ok : boolean := true;
    signal last_wr_ack_t : time := 0 ns;

    -- Checker bookkeeping
    signal tx_cnt  : natural range 0 to 63 := 0;
    signal rx_idx  : natural range 0 to 15 := 0;
    signal rx_hist : mem_a := (others => (others => '0'));
    signal rx_valid_d : std_logic := '0';
begin
    clk <= not clk after 10 ns when not finished else '0';

    -- open-drain bus with external pull-ups: the slave only ever pulls low
    sda_bus <= 'H';
    scl_bus <= 'H';
    sda_bus <= '0' when sda_low = '1' else 'Z';
    scl_obs <= To_X01(scl_bus);

    edge_tb : process(clk)
    begin
        if rising_edge(clk) then
            scl_prev_tb <= scl_obs;
            sda_prev_tb <= To_X01(sda_bus);
        end if;
    end process;

    scl_rise_p  <= '1' when (scl_obs = '1' and scl_prev_tb = '0') else '0';
    scl_fall_p  <= '1' when (scl_obs = '0' and scl_prev_tb = '1') else '0';
    sr_start_ev <= '1' when (To_X01(sda_bus) = '0' and sda_prev_tb = '1'
                             and scl_obs = '1') else '0';

    dut : entity work.I2C_Master
        generic map (G_CLK_FREQ => 50_000_000, G_I2C_FREQ => 100_000)
        port map (
            clk => clk, rst_n => rst_n, w => w, r => r,
            addr => C_ADDR,
            n_write => n_write, n_read => n_read,
            data_to_transmit => data_to_transmit,
            data_to_read => data_to_read,
            tx_done => tx_done, rx_valid => rx_valid,
            busy => open, ack => open,
            sda => sda_bus, scl => scl_bus
        );

    -- Slave: follows the scripted plan. Sr/START detection is global (an SDA
    -- fall while SCL is high), everything else paces on the TB SCL edges.
    slave : process(clk)
    begin
        if rising_edge(clk) then
            -- START or repeated START: (re)address reception begins
            if sr_start_ev = '1' then
                if sl_st = S_WAIT_SR then
                    sr_seen   <= '1';
                    -- With protocol-compliant tSU;STA the repeated START
                    -- arrives about 9.7 us after the preceding ACK edge.
                    -- Keep enough margin for the synchronous implementation,
                    -- while still rejecting a STOP + bus-free + new START.
                    sr_gap_ok <= (now - last_wr_ack_t) < 12 us;
                end if;
                bit_cnt <= 0;
                wr_idx  <= 0;
                rd_idx  <= 0;
                sl_st   <= S_ADDR;
            else
                case sl_st is

                    when S_IDLE =>
                        null;

                    when S_ADDR =>
                        if scl_rise_p = '1' then
                            addr_byte(7 - bit_cnt) <= To_X01(sda_bus);
                            bit_cnt <= bit_cnt + 1;
                        end if;
                        if scl_fall_p = '1' and bit_cnt = 8 then
                            sda_low <= '1';         -- ACK the address
                            sl_st   <= S_ACKA;
                        end if;

                    when S_ACKA =>
                        if scl_fall_p = '1' then
                            sda_low <= '0';         -- release for the data phase
                            last_rw <= addr_byte(0);
                            if addr_byte(0) = '0' then
                                bit_cnt <= 0;
                                sl_st   <= S_WDATA;
                            else
                                rd_drive <= RD_BYTES(rd_idx);
                                sda_low  <= not RD_BYTES(rd_idx)(7);  -- first data bit
                                bit_cnt  <= 0;
                                sl_st    <= S_RDATA;
                            end if;
                        end if;

                    when S_WDATA =>
                        if scl_rise_p = '1' then
                            case wr_idx is
                                when 0 => sl_wr0(7 - bit_cnt) <= To_X01(sda_bus);
                                when 1 => sl_wr1(7 - bit_cnt) <= To_X01(sda_bus);
                                when 2 => sl_wr2(7 - bit_cnt) <= To_X01(sda_bus);
                                when others => sl_wr3(7 - bit_cnt) <= To_X01(sda_bus);
                            end case;
                            bit_cnt <= bit_cnt + 1;
                        end if;
                        if scl_fall_p = '1' and bit_cnt = 8 then
                            sda_low <= '1';         -- ACK the data byte
                            sl_st   <= S_WACK;
                        end if;

                    when S_WACK =>
                        if scl_fall_p = '1' then
                            sda_low       <= '0';
                            last_wr_ack_t <= now;
                            if wr_idx + 1 < to_integer(unsigned(n_write)) then
                                wr_idx  <= wr_idx + 1;
                                bit_cnt <= 0;
                                sl_st   <= S_WDATA;
                            elsif to_integer(unsigned(n_read)) > 0 then
                                sl_st <= S_WAIT_SR;  -- next SDA fall = the Sr
                            else
                                sl_st <= S_DONE;     -- STOP follows
                            end if;
                        end if;

                    when S_WAIT_SR =>
                        null;   -- the global handler catches the repeated START

                    when S_RDATA =>
                        if scl_rise_p = '1' then
                            if bit_cnt < 8 then
                                bit_cnt <= bit_cnt + 1;
                            end if;
                        end if;
                        if scl_fall_p = '1' then
                            if bit_cnt = 8 then
                                sda_low <= '0';     -- 9th cell: release for the master's ACK/NACK
                                sl_st   <= S_RACK;
                            else
                                sda_low <= not rd_drive(7 - bit_cnt);
                            end if;
                        end if;

                    when S_RACK =>
                        if scl_rise_p = '1' then
                            if rd_idx = 0 then
                                master_ack0 <= To_X01(sda_bus);
                            else
                                master_ack1 <= To_X01(sda_bus);
                            end if;
                        end if;
                        if scl_fall_p = '1' then
                            if To_X01(sda_bus) = '0' then   -- master ACK: next read byte
                                rd_idx   <= rd_idx + 1;
                                rd_drive <= RD_BYTES(rd_idx + 1);
                                sda_low  <= not RD_BYTES(rd_idx + 1)(7);
                                bit_cnt  <= 0;
                                sl_st    <= S_RDATA;
                            else
                                sl_st <= S_DONE;            -- NACK: transaction ends
                            end if;
                        end if;

                    when S_DONE =>
                        null;   -- wait for the next START (global handler)
                end case;
            end if;
        end if;
    end process;

    -- tx_done pulse counter
    tx_cnt_p : process(clk)
    begin
        if rising_edge(clk) then
            if tx_done = '1' then
                tx_cnt <= tx_cnt + 1;
            end if;
        end if;
    end process;

    -- rx capture: data_to_read updates on the rx_valid pulse edge, so sample
    -- it one clk later
    rx_cap : process(clk)
    begin
        if rising_edge(clk) then
            rx_valid_d <= rx_valid;
            if rx_valid_d = '1' then
                rx_hist(rx_idx) <= data_to_read;
                rx_idx <= rx_idx + 1;
            end if;
        end if;
    end process;

    stim : process
        variable v_b0, v_b1, v_b2 : std_logic_vector(7 downto 0);
    begin
        wait for 100 ns;
        assert data_to_read = x"00"
            report "Read output not zero during reset" severity failure;
        rst_n <= '1';
        wait for 200 ns;

        ------------------------------------------------------------------
        -- Scenario 1: plain three-byte write (n_write=3, n_read=0)
        ------------------------------------------------------------------
        n_write <= "0011";
        n_read  <= "0000";
        data_to_transmit <= x"11";   -- D1
        w <= '1';
        wait until falling_edge(sda_bus);   -- START
        w <= '0';
        wait until rising_edge(tx_done);    -- address byte sent
        wait until rising_edge(tx_done);    -- D1 sent
        data_to_transmit <= x"22";          -- in time: D2 handover is 250 clk away
        wait until rising_edge(tx_done);    -- D2 sent
        data_to_transmit <= x"33";
        wait until rising_edge(tx_done);    -- D3 sent
        wait for 2 us;                      -- let the pulse counter latch it
        assert tx_cnt = 4
            report "Unexpected tx_done pulse count in W3" severity failure;
        wait for 40 us;                     -- STOP + idle margin
        assert scl_bus = 'H' and sda_bus = 'H'
            report "Bus not released after the W3 transaction" severity failure;
        assert sr_seen = '0'
            report "Spurious repeated START in a write-only transaction" severity failure;
        v_b0 := sl_wr0; v_b1 := sl_wr1; v_b2 := sl_wr2;  -- save (slave reuses idx 0)
        assert v_b0 = x"11" and v_b1 = x"22" and v_b2 = x"33"
            report "Written bytes mismatch on the wire" severity failure;
        assert last_rw = '0'
            report "Address phase R/W bit wrong in W3" severity failure;

        ------------------------------------------------------------------
        -- Scenario 2: W1-Sr-R2 (write pointer, repeated START, read 2 bytes)
        ------------------------------------------------------------------
        n_write <= "0001";
        n_read  <= "0010";
        data_to_transmit <= x"55";
        w <= '1';                           -- write phase first, then Sr + read
        wait until falling_edge(sda_bus);   -- START
        w <= '0';
        -- One write byte only: already on the port. The slave drives the two
        -- read bytes; the master must ACK byte 1 and NACK byte 2.
        wait for 600 us;
        assert scl_bus = 'H' and sda_bus = 'H'
            report "Bus not released after the W1-Sr-R2 transaction" severity failure;
        assert sr_seen = '1'
            report "No repeated START detected" severity failure;
        assert sr_gap_ok
            report "Gap too long: STOP+START instead of a repeated START" severity failure;
        assert last_rw = '1'
            report "Re-sent address did not carry R/W = 1" severity failure;
        assert sl_wr0 = x"55"
            report "Pointer byte mismatch on the wire" severity failure;
        assert master_ack0 = '0'
            report "Master did not ACK the first read byte" severity failure;
        assert master_ack1 = '1'
            report "Master did not NACK the last read byte" severity failure;
        assert tx_cnt = 7
            report "Unexpected tx_done pulse count (4 + addr/W + W + addr/R)" severity failure;
        assert rx_idx = 2
            report "Unexpected rx_valid pulse count" severity failure;
        assert rx_hist(0) = x"C3"
            report "First read byte wrong on data_to_read" severity failure;
        assert rx_hist(1) = x"7E"
            report "Second read byte wrong on data_to_read" severity failure;
        assert data_to_read = x"7E"
            report "Final data_to_read wrong" severity failure;

        report "RESULT: PASS -- W3 write and W1-Sr-R2 repeated START" severity note;
        finished <= true;
        wait;
    end process;

    watchdog : process
    begin
        wait for 3 ms;
        assert finished report "Multibyte test timed out" severity failure;
        wait;
    end process;

    -- TEMP-DBG-BEGIN (remove)
    dbg : process(clk)
    begin
        if rising_edge(clk) then
            if sr_start_ev = '1' then
                report "SR_EV sl_st=" & sl_t'image(sl_st) &
                       " sr_seen=" & std_logic'image(sr_seen) &
                       " nw=" & integer'image(to_integer(unsigned(n_write))) &
                       " nr=" & integer'image(to_integer(unsigned(n_read))) &
                       " wr_idx=" & integer'image(wr_idx) &
                       " rd_idx=" & integer'image(rd_idx) severity note;
            end if;
            if sl_st = S_WACK and scl_fall_p = '1' then
                report "WACK near end, nw=" & integer'image(to_integer(unsigned(n_write))) &
                       " nr=" & integer'image(to_integer(unsigned(n_read))) &
                       " wr_idx=" & integer'image(wr_idx) severity note;
            end if;
            if sl_st = S_WAIT_SR and sda_bus'event then
                report "WAIT_SR sees SDA change" severity note;
            end if;
        end if;
    end process;
    -- TEMP-DBG-END
end architecture sim;
