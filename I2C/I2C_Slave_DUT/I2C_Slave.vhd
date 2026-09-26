-- I2C_Slave.vhd
-- I2C target (slave) top level -- the counterpart of I2C_Master. Hosts the
-- single transaction FSM of the design and orchestrates the reusable
-- sub-modules it needs:
--   sync_2ff          x2 : SCL / SDA input synchronisers (the only async inputs)
--   start_stop_detect    : START / repeated-START / STOP condition detector
--   I2C_RX               : byte de-serialiser (address + written data)
--   I2C_TX               : byte serialiser (data the master reads back)
--   scl_stretch          : CLOCK STRETCHING -- holds SCL low for a programmed
--                          number of clk cycles in every ACK bit cell
-- Ownership mirrors the master: the bus framing (open-drain SDA/SCL, the ACK
-- bits, the START / Sr / STOP interpretation) belongs to this FSM alone,
-- because I2C is half duplex on one shared wire; I2C_TX / I2C_RX only own the
-- bit pacing of one byte and report a per-byte done flag.
-- Both lines are open drain: the slave only ever pulls them low or releases
-- them, so it can never fight the master (and vice versa) -- which is exactly
-- what makes clock stretching legal.
--
-- Features / supported transactions:
--   * write : <addr+W> <data>...      every accepted byte appears on
--                                     data_received with an rx_valid pulse
--   * read  : <addr+R> <data>...      data_to_transmit is sampled per byte,
--                                     tx_done pulses when a byte is on the wire
--   * REPEATED START (Sr): a write phase followed by <Sr> + <addr+R> re-enters
--     the address phase inside the SAME frame (bus stays busy, no STOP) and
--     flips the direction -- the classic "write a register pointer, then read
--     it back" idiom. Detected by start_stop_detect while a frame is running.
--   * CLOCK STRETCHING: in the low phase of every acknowledge bit it takes
--     part in on the ACK side (address ACK, write ACK) and of the master's ACK
--     after a read byte, the slave pulls SCL low for G_STRETCH_CYCLES clk
--     cycles (0 = feature compiled out). The FSM is timed on the real bus
--     edges, so the master's own clock generator cannot end that phase early.
--   * Address filtering: only G_SLAVE_ADDR is answered; any other address gets
--     a NACK (SDA stays released) and the rest of the frame is ignored until
--     the next START.
-- Host interface: one byte at a time. `data_received` / `rx_valid` for writes,
-- `data_to_transmit` / `tx_done` for reads, `busy` and `stretch_active` as
-- status. Nothing is interpreted beyond the byte stream, so a register file,
-- FIFO or CPU bus bridge can sit on top.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity I2C_Slave is
    generic (
        G_SLAVE_ADDR     : std_logic_vector(6 downto 0) := "0111100"; -- 7-bit slave address (0x3C)
        G_CLK_FREQ       : natural := 50_000_000;  -- system clock [Hz]
        G_I2C_FREQ       : natural := 100_000;     -- SCL bus clock [Hz] (oversampling check)
        G_STRETCH_CYCLES : natural := 500          -- SCL low hold per ACK cell [clk cycles] (0 = off)
    );
    port (
        clk              : in    std_logic;
        rst_n            : in    std_logic;
        data_to_transmit : in    std_logic_vector(7 downto 0); -- byte the master reads next
        data_received    : out   std_logic_vector(7 downto 0); -- last byte written by the master
        rx_valid         : out   std_logic;   -- one-clk pulse: data_received updated
        tx_done          : out   std_logic;   -- one-clk pulse: a read byte was fully sent
        busy             : out   std_logic;   -- '1' while a frame addressed to this slave runs
        stretch_active   : out   std_logic;   -- '1' while SCL is held low (clock stretching)
        sda              : inout std_logic;   -- I2C bus data (open drain)
        scl              : inout std_logic    -- I2C bus clock (open drain)
    );
end entity I2C_Slave;

architecture rtl of I2C_Slave is

    -- SCL oversampling. The FSM must be able to see every bus level between two
    -- SCL edges (2-FF synchroniser + edge detector + one registered output
    -- stage), so the system clock has to be far faster than SCL. 16 clk per SCL
    -- period (8 per SCL phase) is the floor, asserted below.
    function oversample_ratio(clk_freq : natural; i2c_freq : natural) return natural is
    begin
        if i2c_freq = 0 then
            return 0;
        end if;
        return clk_freq / i2c_freq;
    end function;

    constant C_OVERSAMPLE : natural := oversample_ratio(G_CLK_FREQ, G_I2C_FREQ);

    -- Transaction FSM. One state per bus phase the slave has to play:
    --   IDLE      : bus released, waiting for a START
    --   ADDR      : I2C_RX captures {addr(6:0), rw} and the address is compared
    --   ACKA_OPEN : address matched -- wait for the falling edge that opens the
    --               ACK bit cell (SDA must NOT move during the last address bit)
    --   ACKA      : the address ACK cell: SDA low, SCL stretched
    --   DATA_W    : I2C_RX captures a byte written by the master
    --   ACKW_OPEN : wait for the falling edge that opens the write-byte ACK cell
    --   ACKW      : the write-byte ACK cell: SDA low, SCL stretched
    --   DATA_R    : I2C_TX shifts a byte out, SDA driven from tx_bit
    --   ACKR      : the master's ACK cell for a read byte: SDA released, SCL
    --               stretched, the master's ACK/NACK sampled while SCL is high
    type state_t is (IDLE, ADDR, ACKA_OPEN, ACKA, DATA_W, ACKW_OPEN, ACKW,
                     DATA_R, ACKR);
    signal state : state_t := IDLE;

    -- Input path: raw pins -> sync_2ff -> To_X01-normalised level -> delayed
    -- copy for the edge detector. Everything downstream reads the normalised
    -- level, never the pin ('H' is not '1' for std_logic comparisons).
    -- Only the SCL FALLING edge needs an explicit pulse: the FSM starts and
    -- ends bit cells on it, while the rising edge is consumed by I2C_RX and
    -- I2C_TX (bit pacing) and by the level-gated ACK sampling.
    signal sda_raw     : std_logic;
    signal scl_raw     : std_logic;
    signal sda_level   : std_logic := '1';
    signal scl_level   : std_logic := '1';
    signal scl_level_d : std_logic := '1';
    signal scl_fall    : std_logic;   -- one-clk pulse: SCL falling edge on the bus

    -- START / repeated-START / STOP detector (framing, not data)
    signal start_det : std_logic;
    signal stop_det  : std_logic;

    -- scl_stretch: clock-stretching request/source of the SCL pull-down
    signal stretch_req : std_logic := '0';   -- one-clk pulse: start a hold
    signal scl_low     : std_logic;          -- drive request for the SCL pull-down
    signal stretching  : std_logic;          -- status: hold running

    -- I2C_RX handshake (byte de-serialiser). I2C_RX owns the bit pacing of the
    -- received byte; the FSM only arms it and waits for the done flag.
    signal rx_receive_reg : std_logic := '0';
    signal rx_data        : std_logic_vector(7 downto 0);
    signal rx_byte_done   : std_logic;
    signal rx_data_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_valid_reg   : std_logic := '0';

    -- I2C_TX handshake (byte serialiser). I2C_TX owns the bit pacing of the
    -- transmitted byte; the FSM only hands a byte over.
    signal tx_send_reg  : std_logic := '0';
    signal tx_bit       : std_logic;
    signal tx_byte_done : std_logic;

    -- Frame decode
    signal rw_reg   : std_logic := '0';   -- R/W bit of the last address byte
    signal ack_reg  : std_logic := '1';   -- master ACK sampled on a read byte ('1' = NACK)
    signal busy_reg : std_logic := '0';   -- frame addressed to this slave running

    -- Registered bus driver (open drain: '0' = pull low, '1' = release)
    signal sda_reg : std_logic := '1';

begin

    assert G_I2C_FREQ > 0
        report "G_I2C_FREQ must be greater than zero" severity failure;
    assert C_OVERSAMPLE >= 16
        report "G_CLK_FREQ must be at least 16x G_I2C_FREQ (SCL oversampling)"
        severity failure;

    -- Status / streamed outputs
    busy           <= busy_reg;
    stretch_active <= stretching;
    rx_valid       <= rx_valid_reg;
    tx_done        <= tx_byte_done;
    data_received  <= rx_data_reg;

    ---------------------------------------------------------------------------
    -- Input synchronisers: the two bus lines are asynchronous to clk (the
    -- master drives them, and a slave release makes SCL asynchronous too).
    ---------------------------------------------------------------------------
    u_sda_sync : entity work.sync_2ff
        port map (
            clk      => clk,
            async_in => sda,
            sync_out => sda_raw
        );

    u_scl_sync : entity work.sync_2ff
        port map (
            clk      => clk,
            async_in => scl,
            sync_out => scl_raw
        );

    -- Normalised bus levels + one delayed copy for the SCL edge detector.
    -- To_X01 turns the resolved open-drain levels ('H' for a released line)
    -- into clean '0'/'1' so every downstream comparison and shift is exact.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                sda_level   <= '1';
                scl_level   <= '1';
                scl_level_d <= '1';
            else
                sda_level   <= To_X01(sda_raw);
                scl_level   <= To_X01(scl_raw);
                scl_level_d <= scl_level;
            end if;
        end if;
    end process;

    -- SCL edge pulses, derived only from registered levels (glitch free).
    scl_fall <= '1' when rst_n = '1' and scl_level = '0' and scl_level_d = '1' else '0';

    ---------------------------------------------------------------------------
    -- Framing detector: the ONLY owner of the START / repeated START / STOP
    -- interpretation. Fed with synchronised levels, so its pulses are already
    -- in the clk domain.
    ---------------------------------------------------------------------------
    u_start_stop : entity work.start_stop_detect
        port map (
            clk       => clk,
            rst_n     => rst_n,
            scl       => scl_level,
            sda       => sda_level,
            start_det => start_det,
            stop_det  => stop_det
        );

    ---------------------------------------------------------------------------
    -- Clock stretching: the low phase of every ACK cell the slave is involved
    -- in is extended by G_STRETCH_CYCLES clk cycles. scl_low only ever pulls
    -- the line down, so a hold can never fight the master's clock generator.
    ---------------------------------------------------------------------------
    u_stretch : entity work.scl_stretch
        generic map (
            G_STRETCH_CYCLES => G_STRETCH_CYCLES
        )
        port map (
            clk     => clk,
            rst_n   => rst_n,
            stretch => stretch_req,
            scl_low => scl_low,
            active  => stretching
        );

    ---------------------------------------------------------------------------
    -- Byte de-serialiser: samples one bit per SCL RISING edge (I2C data is
    -- valid while SCL is high), MSB first, from the synchronised SDA copy.
    ---------------------------------------------------------------------------
    u_rx : entity work.I2C_RX
        generic map (
            G_DATA_WIDTH => 8
        )
        port map (
            clk           => clk,
            rst_n         => rst_n,
            scl           => scl_level,
            receive       => rx_receive_reg,
            sda_in        => sda_level,
            data_received => rx_data,
            byte_done     => rx_byte_done,
            busy          => open
        );

    ---------------------------------------------------------------------------
    -- Byte serialiser: presents one bit per SCL FALLING edge, MSB first, paced
    -- on the same synchronised SCL level. The FSM still owns SDA (see the
    -- output mux), so the byte can be released the moment it is complete.
    ---------------------------------------------------------------------------
    u_tx : entity work.I2C_TX
        generic map (
            G_DATA_WIDTH => 8
        )
        port map (
            clk              => clk,
            rst_n            => rst_n,
            scl              => scl_level,
            send             => tx_send_reg,
            data_to_transmit => data_to_transmit,
            tx_bit           => tx_bit,
            byte_done        => tx_byte_done,
            busy             => open
        );

    ---------------------------------------------------------------------------
    -- Open-drain line drivers: '0' pulls the line low, anything else releases
    -- it to the external pull-up. The slave never drives a line high.
    ---------------------------------------------------------------------------
    scl <= '0' when scl_low = '1' else 'Z';
    sda <= '0' when sda_reg = '0' else 'Z';

    ---------------------------------------------------------------------------
    -- Transaction FSM. State and registered outputs update on the rising clock
    -- edge; every state advances on the REAL bus edges (the scl_fall
    -- pulses, start_det / stop_det), never on a local timer, so a phase the
    -- master stretches is simply waited out.
    ---------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state          <= IDLE;
                sda_reg        <= '1';   -- SDA released (open-drain pull-up)
                rw_reg         <= '0';
                ack_reg        <= '1';   -- NACK (idle value) until one is sampled
                busy_reg       <= '0';
                rx_receive_reg <= '0';
                rx_data_reg    <= (others => '0');
                rx_valid_reg   <= '0';
                tx_send_reg    <= '0';
                stretch_req    <= '0';
            else
                -- one-clk handshake pulses
                rx_receive_reg <= '0';
                rx_valid_reg   <= '0';
                tx_send_reg    <= '0';
                stretch_req    <= '0';

                if stop_det = '1' then
                    -- STOP: the frame is over, whatever phase it was in. The
                    -- master can only generate one while this slave has SDA
                    -- released, so returning to IDLE never cuts a drive.
                    state    <= IDLE;
                    busy_reg <= '0';
                else
                    case state is

                        -- -------------------------------------------------------
                        -- IDLE: nothing addressed to this slave, both lines
                        -- released. Only a START can move the FSM on.
                        -- -------------------------------------------------------
                        when IDLE =>
                            if start_det = '1' then
                                rx_receive_reg <= '1';   -- arm I2C_RX for {addr,rw}
                                state          <= ADDR;
                            end if;

                        -- -------------------------------------------------------
                        -- ADDR: I2C_RX captures {addr(6:0), rw} MSB first. Its
                        -- byte_done pulse lands inside the LAST address bit's
                        -- high phase, so the FSM only records what it saw there:
                        --   match    -> ACKA_OPEN: pull SDA low in the ACK cell
                        --   mismatch -> IDLE: SDA stays released, which IS the
                        --               NACK, and the frame is ignored
                        -- -------------------------------------------------------
                        when ADDR =>
                            if start_det = '1' then
                                -- a new START before the byte was complete:
                                -- restart the capture
                                rx_receive_reg <= '1';
                            elsif rx_byte_done = '1' then
                                rw_reg <= rx_data(0);
                                if rx_data(7 downto 1) = G_SLAVE_ADDR then
                                    state    <= ACKA_OPEN;
                                    busy_reg <= '1';
                                else
                                    state    <= IDLE;
                                    busy_reg <= '0';
                                end if;
                            end if;

                        -- -------------------------------------------------------
                        -- ACKA_OPEN: wait for the falling edge that opens the
                        -- address ACK cell. SDA must not move before it -- during
                        -- the last address bit's high phase a low-going SDA would
                        -- look like a START to the master.
                        -- -------------------------------------------------------
                        when ACKA_OPEN =>
                            if scl_fall = '1' then
                                stretch_req <= '1';   -- hold SCL low (stretch)
                                state       <= ACKA;
                            end if;

                        -- -------------------------------------------------------
                        -- ACKA: the address ACK cell. SDA is pulled low by the
                        -- output mux from the opening edge on, SCL is stretched.
                        -- The cell closes on the next falling edge, where the
                        -- R/W bit selects the phase:
                        --   R/W = 0 -> DATA_W: arm I2C_RX for the first byte
                        --   R/W = 1 -> DATA_R: hand the read byte to I2C_TX
                        -- -------------------------------------------------------
                        when ACKA =>
                            if scl_fall = '1' then
                                if rw_reg = '1' then
                                    tx_send_reg <= '1';
                                    state       <= DATA_R;
                                else
                                    rx_receive_reg <= '1';
                                    state          <= DATA_W;
                                end if;
                            end if;

                        -- -------------------------------------------------------
                        -- DATA_W: I2C_RX captures a byte the master writes; each
                        -- captured byte is published on data_received together
                        -- with an rx_valid pulse. A START here is a REPEATED
                        -- START inside the running frame: the master is
                        -- re-addressing, so drop the write phase and capture the
                        -- new address (and its R/W bit) from the next rise on.
                        -- -------------------------------------------------------
                        when DATA_W =>
                            if start_det = '1' then
                                rx_receive_reg <= '1';   -- re-address (Sr)
                                state          <= ADDR;
                            elsif rx_byte_done = '1' then
                                rx_data_reg  <= rx_data;
                                rx_valid_reg <= '1';
                                state        <= ACKW_OPEN;
                            end if;

                        -- -------------------------------------------------------
                        -- ACKW_OPEN: wait for the falling edge that opens the ACK
                        -- cell of the written byte (same reason as ACKA_OPEN).
                        -- -------------------------------------------------------
                        when ACKW_OPEN =>
                            if scl_fall = '1' then
                                stretch_req <= '1';
                                state       <= ACKW;
                            end if;

                        -- -------------------------------------------------------
                        -- ACKW: acknowledge the written byte -- SDA low from the
                        -- output mux, SCL stretched. The cell closes on the next
                        -- falling edge: arm I2C_RX for whatever comes next, i.e.
                        -- the next write byte (DATA_W) or, via the start_det /
                        -- stop_det handling above and in DATA_W, an Sr or a STOP.
                        -- -------------------------------------------------------
                        when ACKW =>
                            if scl_fall = '1' then
                                rx_receive_reg <= '1';
                                state          <= DATA_W;
                            end if;

                        -- -------------------------------------------------------
                        -- DATA_R: I2C_TX shifts a byte out MSB first and the
                        -- output mux drives SDA from tx_bit. tx_byte_done pulses
                        -- on the falling edge that opens the master's ACK cell:
                        -- there SDA is released and that cell is stretched, which
                        -- is also the window in which the host presents the next
                        -- byte on data_to_transmit.
                        -- -------------------------------------------------------
                        when DATA_R =>
                            if start_det = '1' then
                                -- the master aborted the read with a repeated
                                -- START: release the line and re-address
                                rx_receive_reg <= '1';
                                state          <= ADDR;
                            elsif tx_byte_done = '1' then
                                ack_reg     <= '1';      -- NACK until sampled
                                stretch_req <= '1';
                                state       <= ACKR;
                            end if;

                        -- -------------------------------------------------------
                        -- ACKR: the master's ACK cell for a read byte. SDA is
                        -- released (the master drives it), SCL is stretched, and
                        -- the ACK bit is sampled while SCL is high -- so even a
                        -- slow master is caught. At the cell's closing edge: ACK
                        -- -> hand over the next byte, NACK -> the frame is over.
                        -- -------------------------------------------------------
                        when ACKR =>
                            if scl_level = '1' then
                                ack_reg <= sda_level;
                            elsif scl_fall = '1' then
                                if ack_reg = '0' then
                                    tx_send_reg <= '1';  -- master ACK: next byte
                                    state       <= DATA_R;
                                else
                                    state    <= IDLE;    -- master NACK: done
                                    busy_reg <= '0';
                                end if;
                            end if;

                    end case;
                end if;

                ------------------------------------------------------------------
                -- Registered SDA output mux. Like the master's, it decodes the
                -- CURRENT state, so every SDA transition is uniformly delayed by
                -- one clk and bit cells keep their width (SCL is far slower than
                -- clk). It is the single owner of SDA: each state decides whether
                -- the slave pulls the line low or lets it go.
                ------------------------------------------------------------------
                case state is

                    when ACKA | ACKW =>
                        sda_reg <= '0';              -- acknowledge bit

                    when DATA_R =>
                        if tx_send_reg = '1' then
                            -- Byte being handed over: present its MSB directly.
                            -- On the first cycle after the handover I2C_TX is
                            -- still loading its registered output, so tx_bit would
                            -- still hold the previous byte's last bit.
                            sda_reg <= data_to_transmit(7);
                        elsif tx_byte_done = '1' then
                            sda_reg <= '1';          -- released: master's ACK cell
                        else
                            sda_reg <= tx_bit;
                        end if;

                    when others =>
                        sda_reg <= '1';              -- released (open-drain pull-up)

                end case;
            end if;
        end if;
    end process;

end architecture rtl;





