-- I2C_Master.vhd
-- I2C master top level. Hosts the single transaction FSM of the design
-- (START/STOP framing, address + R/W field, per-byte handshakes) and the
-- reusable sub-modules it orchestrates:
--   clock_div : divides clk down to the SCL bus clock (instantiated)
--   I2C_TX    : serialises the address/data bytes     (instantiated)
--   I2C_RX    : de-serialises the received data byte   (instantiated)
-- Ownership: the bus (SDA framing) belongs to this FSM alone, because I2C is
-- half duplex on one shared wire; TX/RX only own the bit pacing of the bytes
-- they handle and report a done flag per byte.
-- SDA is an open-drain line: the master only ever pulls it low ('0') or
-- releases it ('Z'), so START/STOP, the ACK bit and the received data all rely
-- on the external pull-up.
-- Transaction states cover START/STOP timing, the write path (IDLE, START,
-- ADDR_RW, ACK_ADDR, DATA_W, ACK_DATA, STOP) and the read path (DATA_R + ACK_RX, which
-- I2C_RX serves). A transaction carries n_write data bytes and, through a
-- REPEATED START (RSTART re-enters START mid-transaction), n_read data bytes
-- after re-addressing the slave with R/W = 1 -- the classic "write a register
-- pointer, then read it back" idiom. data_to_transmit is streamed: update it
-- on each tx_done pulse; data_to_read is drained one byte per rx_valid pulse.
-- SCL is gated off at IDLE -- the bus is released high between transactions --
-- and the FSM is timed on the real bus edges, so a slave holding SCL low
-- (clock stretching) simply delays every following edge.
-- busy and ack expose the transaction state and most recently sampled slave ACK.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity I2C_Master is
    generic (
        G_CLK_FREQ : natural := 50_000_000;  -- system clock [Hz]
        G_I2C_FREQ : natural := 100_000      -- SCL bus clock [Hz] (standard mode)
    );
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        w     : in  std_logic;                     -- write request (hold until busy = '1')
        r     : in  std_logic;                     -- read request  (hold until busy = '1')
        addr  : in  std_logic_vector(6 downto 0);  -- 7-bit slave address
        data_to_transmit : in std_logic_vector(7 downto 0);  -- byte to write (next byte while tx_done pulses)
        n_write : in std_logic_vector(3 downto 0) := "0001"; -- data bytes in the write phase (0 = none)
        n_read  : in std_logic_vector(3 downto 0) := "0000"; -- data bytes to read after the repeated START (0 = none)
        data_to_read : out std_logic_vector(7 downto 0);    -- last complete byte read; zero on reset
        tx_done  : out std_logic;                  -- pulse: byte fully serialized -> update data_to_transmit
        rx_valid : out std_logic;                  -- pulse: a complete read byte landed in data_to_read
        busy     : out std_logic;                  -- '1' while a transaction is in progress
        ack      : out std_logic;                  -- last sampled slave ACK: '0' ACK, '1' NACK
        sda   : inout std_logic;                   -- I2C bus data (open drain)
        scl   : inout std_logic                    -- I2C bus clock (open drain)
    );
end entity I2C_Master;


architecture rtl of I2C_Master is

    -- Keep elaboration safe long enough for the parameter assertions below to
    -- report a useful error instead of failing in a divide-by-zero or invalid
    -- clock_div generic map.
    function safe_divider(clk_freq : natural; i2c_freq : natural) return positive is
        variable d : natural;
    begin
        if i2c_freq = 0 or clk_freq < 2 * i2c_freq then
            return 2;
        end if;
        d := clk_freq / i2c_freq;
        if d < 2 then
            return 2;
        end if;
        return d;
    end function;

    -- SCL divider: system clock cycles per SCL period
    constant C_DIVIDER : natural := safe_divider(G_CLK_FREQ, G_I2C_FREQ);

    -- Half-period in clk cycles.  It is used for START setup, repeated-START
    -- setup, STOP setup and the post-STOP bus-free interval.  With the default
    -- 100 kHz bus this is 250 clk cycles = 5 us.
    constant C_HALF_PERIOD : natural := (C_DIVIDER + 1) / 2;

    -- Standard-mode minimum setup is 4.7 us for repeated START and STOP.
    -- The divider's high phase is 5 us at 100 kHz, so use 94% of that phase
    -- to leave room for the synchronous edge-detection/output latency while
    -- still meeting the timing requirement.
    constant C_SETUP_HOLD : natural := (C_HALF_PERIOD * 15 + 15) / 16;

    -- clock_div control, gated by scl_en_r: the divider runs only during a
    -- transaction. clock_div parks its output low while disabled, so the
    -- first enabled period starts with a full low phase and the bit cells
    -- come out phase-aligned from there.
    signal enable : std_logic;

    -- Divider output. scl is an out port and cannot be read back, so the
    -- bus clock is kept in this internal signal: it drives the pin and is
    -- what the edge detector looks at.
    signal scl_int   : std_logic;
    signal scl_level : std_logic;

    -- SCL gate, registered. '1' during a transaction: it enables clock_div
    -- AND lets the open-drain SCL driver pull the line low. '0' at IDLE:
    -- divider parked, SCL only ever released, so the bus rests high between
    -- transactions and a slave holding SCL low (clock stretching) is never
    -- fought. Set at the end of the START hold (see START in the FSM),
    -- cleared on IDLE.
    signal scl_en_r : std_logic := '0';

    -- START hold counter: counts clk cycles in START to time the release of
    -- scl_en_r (START condition hold = half an SCL period).
    signal start_cnt : natural range 0 to C_HALF_PERIOD := 0;
    signal bus_free_cnt : natural range 0 to C_HALF_PERIOD := C_HALF_PERIOD;

    -- Transaction FSM (multi-byte, two phases per request: n_write bytes are
    -- written first, then -- through a repeated START -- n_read bytes read):
    --   IDLE     : bus free, waiting for a request (w = write, r = read)
    --   START    : START condition -- SDA falls while SCL is high
    --   ADDR_RW  : shift out the address byte, {addr(6:0), rw}
    --   ACK_ADDR : release SDA and sample the slave acknowledge
    --   DATA_W   : shift out a data byte (write phase, n_write bytes)
    --   ACK_DATA : sample the slave ACK; branch: more bytes / Sr / STOP
    --   DATA_R   : shift in a data byte (read phase, n_read bytes)
    --   ACK_RX   : master ACK (more bytes follow) or NACK (last byte)
    --   RSTART   : repeated START -- like START, but SCL is already running
    --   STOP     : STOP condition -- SDA rises while SCL is high
    type state_t is (IDLE, START, ADDR_RW, ACK_ADDR, DATA_W, ACK_DATA,
                     DATA_R, ACK_RX, RSTART, RSTART_HOLD, STOP, STOP_HOLD,
                     STOP_RELEASE);
    signal state : state_t := IDLE;

    -- Direction of the current transaction, latched when the request is
    -- accepted. The FSM branches on it much later (ACK_ADDR decides between
    -- DATA_W and DATA_R), so it must not change mid-transaction. It is also
    -- bit 0 of the address byte: {addr(6:0), rw}.
    signal rw_reg : std_logic := '0';

    -- Address is captured with the request.  The host may change addr after
    -- acceptance without corrupting the byte currently on the bus.
    signal addr_reg : std_logic_vector(6 downto 0) := (others => '0');

    -- A request is accepted once, then must be released before another
    -- transaction can start.  This prevents a held request level from
    -- retriggering immediately after STOP.
    signal request_armed : std_logic := '1';

    -- Per-phase byte counters, loaded from the n_write / n_read ports when
    -- the request is accepted. wr_left counts the write-phase bytes still to
    -- send (the current one included); rd_left the read-phase bytes still to
    -- receive. They steer the ACK_DATA / ACK_RX branches: continue the phase,
    -- go through the repeated START, or close with STOP. ACK_RX NACKs when
    -- rd_left = 1, i.e. on the LAST read byte, so the slave releases the bus.
    signal wr_left : natural range 0 to 15 := 0;
    signal rd_left : natural range 0 to 15 := 0;

    -- Slave acknowledge, sampled during the ACK bit cell: '0' = ACK, '1' = NACK
    -- (its idle value). Kept as status -- it will be exposed with the status
    -- ports, and it is what a NACK abort would branch on.
    signal ack_reg : std_logic := '1';

    -- SDA input path. The line is driven by the slave and is asynchronous to
    -- clk, so it is resynchronised (2 FF) before anything uses it: ack_reg and,
    -- later, the received data bits are sampled from sda_sync.
    signal sda_meta : std_logic := '1';
    signal sda_sync : std_logic := '1';

    -- SCL edge detector. scl_int comes from clock_div, which generates it
    -- registered inside this same clk domain, so no extra synchronizer stage
    -- is needed. scl_rise/scl_fall are one-clk-wide pulses: the FSM is timed
    -- on these, never by clocking logic with SCL itself, so the design stays
    -- single clock.
    signal scl_prev : std_logic := '1';
    signal scl_rise : std_logic;
    signal scl_fall : std_logic;

    -- I2C_TX handshake (byte serialiser). I2C_TX owns the bit pacing and
    -- reports when a byte is complete; the FSM only hands bytes over.
    signal tx_send_reg  : std_logic := '0';              -- one-clk pulse: hand a byte to the serialiser
    signal tx_data      : std_logic_vector(7 downto 0);  -- byte to send: address or data
    signal tx_bit       : std_logic;                     -- serial bit presented by I2C_TX
    signal tx_byte_done : std_logic;                     -- I2C_TX: byte fully sent
    signal tx_busy      : std_logic;                     -- I2C_TX status: '1' while shifting

    -- I2C_RX handshake (byte de-serialiser). I2C_RX owns the bit pacing of the
    -- received byte and reports when it is complete; the FSM only arms it and
    -- waits for the done flag.
    signal rx_receive_reg : std_logic := '0';              -- one-clk pulse: arm I2C_RX for one byte
    signal rx_data        : std_logic_vector(7 downto 0);  -- byte presented by I2C_RX
    signal rx_byte_done   : std_logic;                     -- I2C_RX: byte captured
    signal rx_busy        : std_logic;                     -- I2C_RX status: '1' while capturing

    -- Last complete byte read off the bus, exposed through data_to_read.
    -- Holds its value during subsequent transfers; synchronous reset clears it.
    signal rx_data_reg : std_logic_vector(7 downto 0) := (others => '0');

    -- '1' once I2C_RX reports the whole byte during DATA_R. SDA may not be
    -- touched at that moment -- the slave still drives the last data bit until
    -- its cell ends -- so this flag carries the event forward to the falling
    -- edge that closes the cell, which is where the master takes the line back.
    signal rx_done_reg : std_logic := '0';

    -- Registered outputs (module outputs are FF driven, glitch free)
    signal sda_reg  : std_logic := '1';   -- SDA idles high (open-drain pull-up)
    signal busy_reg : std_logic := '0';   -- '1' while a transaction is in progress

begin

    assert G_I2C_FREQ > 0
        report "G_I2C_FREQ must be greater than zero" severity failure;
    assert G_CLK_FREQ >= 2 * G_I2C_FREQ
        report "G_CLK_FREQ must be at least twice G_I2C_FREQ" severity failure;

    data_to_read <= rx_data_reg;
    busy         <= busy_reg;
    ack          <= ack_reg;

    -- Streaming handshakes: tx_done pulses when a byte (the address or a
    -- data byte) has been fully serialized -- update data_to_transmit for
    -- the next write byte when it fires; the FSM captures it at the next
    -- DATA_W handover, a full bit cell later. rx_valid pulses when a
    -- complete read byte has landed in data_to_read -- consume it then.
    tx_done  <= tx_byte_done;
    rx_valid <= rx_byte_done;

    -- The divider runs only while scl_en_r is high: parked (output low) at
    -- IDLE and during the START hold, phase-aligned restart on release.
    enable <= scl_en_r;

    u_clk_div : entity work.clock_div
        generic map (
            G_DIVIDER => C_DIVIDER
        )
        port map (
            clk     => clk,
            rst_n   => rst_n,
            enable  => enable,
            clk_out => scl_int
        );

    -- Open-drain SCL driver: low is actively driven, high is released to the
    -- external pull-up. The resolved bus level is used internally.
    -- scl_en_r gates the pull-down: at IDLE the line is only ever released,
    -- so the bus rests high between transactions, and while a slave holds
    -- SCL low (clock stretching) the master's "high" is just a release,
    -- never a fight.
    scl <= '0' when (scl_int = '0' and scl_en_r = '1') else 'Z';
    scl_level <= To_X01(scl);

    -- SDA reaches the pin through an open-drain driver: the master only pulls
    -- the line low and releases it otherwise, so it can never fight the slave.
    -- sda_reg = '0' -> drive low, sda_reg = '1' -> release ('Z', pulled up
    -- externally).
    sda <= '0' when sda_reg = '0' else 'Z';

    -- SDA input synchroniser (2 FF): the slave drives this line asynchronously
    -- to clk. Everything that reads SDA (the ACK sample and the received bits)
    -- uses this synchronised copy, never the raw pin.
    -- The second stage is normalised to '0'/'1' (To_X01): the open-drain bus
    -- resolves to 'H' for a released line, and 'H' is not '1' for std_logic
    -- comparisons -- a received bit would otherwise end up sitting in the RX
    -- register as a weak 'H' instead of a clean '1'. Same reason the SCL level
    -- is X01'd above.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                sda_meta <= '1';
                sda_sync <= '1';
            else
                sda_meta <= sda;
                sda_sync <= To_X01(sda_meta);
            end if;
        end if;
    end process;

    -- Byte serialiser: shifts one byte out MSB first (I2C bit order), pacing
    -- itself on the SCL falling edges. It never touches the bus framing.
    u_tx : entity work.I2C_TX
        generic map (
            G_DATA_WIDTH => 8
        )
        port map (
            clk              => clk,
            rst_n            => rst_n,
            scl              => scl_level,
            send             => tx_send_reg,
            data_to_transmit => tx_data,
            tx_bit           => tx_bit,
            byte_done        => tx_byte_done,
            busy             => tx_busy
        );

    -- Byte de-serialiser: samples one byte MSB first (I2C bit order), pacing
    -- itself on the SCL RISING edges -- data is valid then -- and fed from the
    -- synchronised SDA copy, never the raw pin. It never touches the bus
    -- framing.
    u_rx : entity work.I2C_RX
        generic map (
            G_DATA_WIDTH => 8
        )
        port map (
            clk           => clk,
            rst_n         => rst_n,
            scl           => scl_level,
            receive       => rx_receive_reg,
            sda_in        => sda_sync,
            data_received => rx_data,
            byte_done     => rx_byte_done,
            busy          => rx_busy
        );

    -- SCL edge detector: combinational pulses from the registered SCL history.
    -- This avoids an unnecessary extra clk of latency between a bus edge and
    -- the FSM response, especially at the ACK-to-data handoff.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                scl_prev <= '1';
            else
                scl_prev <= scl_level;
            end if;
        end if;
    end process;

    scl_rise <= (scl_level and not scl_prev) when rst_n = '1' else '0';
    scl_fall <= ((not scl_level) and scl_prev) when rst_n = '1' else '0';

    -- Transaction FSM: state and registered outputs update on the rising
    -- clock edge. Every state advances on the real bus edge pulses detected
    -- above (never on the raw divider output), so a slave stretching SCL
    -- simply delays the pulses and the FSM waits.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state         <= IDLE;
                sda_reg       <= '1';   -- SDA released (high) on reset
                busy_reg      <= '0';
                tx_send_reg   <= '0';
                rx_receive_reg <= '0';
                rx_data_reg   <= (others => '0');
                rx_done_reg   <= '0';
                scl_en_r      <= '0';   -- SCL released while resetting
                start_cnt     <= 0;
                bus_free_cnt  <= C_HALF_PERIOD;
                wr_left       <= 0;
                rd_left       <= 0;
                addr_reg      <= (others => '0');
                request_armed <= '1';
                ack_reg       <= '1';
            else
                tx_send_reg   <= '0';   -- one-clk pulse: set when a byte is handed over
                rx_receive_reg <= '0';  -- one-clk pulse: set when RX is armed

                -- SCL gate maintenance: off at IDLE (bus released, divider
                -- parked), on in every active state. START is the exception
                -- until its hold timer releases the gate: the decode only
                -- holds the value there, so the timer's set (inside the case
                -- below, which runs after this) wins.
                if state = IDLE then
                    scl_en_r <= '0';
                elsif state = START then
                    scl_en_r <= scl_en_r;   -- held; the START timer owns the set
                else
                    scl_en_r <= '1';
                end if;

                case state is

                    when IDLE =>
                        -- SCL is gated off here (scl_en_r = '0': bus released
                        -- high), so there are no SCL edges to wait for any
                        -- more: the request is taken as soon as the bus is
                        -- FREE, i.e. both lines released high. Waiting out
                        -- the levels also covers a slave that is still
                        -- stretching the previous transaction's last clock.
                        -- The direction is latched here (if both w and r are
                        -- high at the same time, read wins); the SDA fall of
                        -- the START condition follows one clk later, while
                        -- SCL is high. The hold counter is parked at zero so
                        -- every START times the full hold.
                        start_cnt <= 0;
                        if bus_free_cnt < C_HALF_PERIOD then
                            bus_free_cnt <= bus_free_cnt + 1;
                        end if;
                        if w = '0' and r = '0' then
                            request_armed <= '1';
                        end if;
                        if request_armed = '1' and bus_free_cnt = C_HALF_PERIOD
                           and (w = '1' or r = '1') and scl_level = '1'
                           and sda_sync = '1' then
                             rw_reg  <= r;
                             wr_left <= to_integer(unsigned(n_write));
                             rd_left <= to_integer(unsigned(n_read));
                             addr_reg <= addr;
                             request_armed <= '0';
                             state   <= START;
                        end if;

                    when START =>
                        -- sda_reg is driven low by the registered output mux
                        -- while SCL is still high: that IS the START
                        -- condition. SCL is still gated off here, so the FSM
                        -- first times out the START hold (half an SCL period,
                        -- the hold the free-running divider used to give) and
                        -- only then releases scl_en_r: the divider's
                        -- parked-low output reaches the pin and SCL falls. On
                        -- that real falling edge the address byte is handed
                        -- to I2C_TX, which presents its first bit there
                        -- (tx_send, below).
                        if start_cnt = C_HALF_PERIOD - 1 then
                            scl_en_r  <= '1';   -- SCL pull-down from here on
                            start_cnt <= 0;
                        else
                            start_cnt <= start_cnt + 1;
                        end if;
                        if scl_fall = '1' then
                            state       <= ADDR_RW;
                            tx_send_reg <= '1';   -- hand over {addr, rw}
                            -- Leave the counter at zero: it keeps counting
                            -- A fresh counter value makes every later START
                            -- timing independent of the previous transaction.
                            start_cnt   <= 0;
                        end if;

                    when ADDR_RW =>
                        -- tx_data carries {addr(6:0), rw} and I2C_TX is
                        -- shifting it out MSB first, pacing itself on the SCL
                        -- falling edges. tx_byte_done pulses on the falling
                        -- edge that completes the byte -- the start of the ACK
                        -- bit cell -- which is exactly when SDA must be handed
                        -- back to the slave for the acknowledge.
                        if tx_byte_done = '1' then
                            state <= ACK_ADDR;
                        end if;

                    when ACK_ADDR =>
                        -- SDA was released when the address byte completed (the
                        -- registered mux holds '1' here), so the slave owns the
                        -- line for this bit cell and pulls it low for ACK.
                        -- The bit is valid while SCL is high, so it is sampled
                        -- throughout the high phase -- that way even a slow
                        -- slave is caught -- and the FSM moves on at the falling
                        -- edge that ends the cell: that is where a write (DATA_W)
                        -- or a read (DATA_R) begins. Sampled on the real bus
                        -- level (scl_level, the resolved pin -- not scl_int):
                        -- during a clock stretch scl_int can be high while the
                        -- slave still holds SCL low, and the ACK must not be
                        -- read before the slave actually released the line.
                        if scl_level = '1' then
                            ack_reg <= sda_sync;
                        elsif scl_fall = '1' then
                            if ack_reg = '1' then
                                -- Address NACK: terminate cleanly without
                                -- sending any data bytes.
                                state <= STOP;
                            elsif rw_reg = '0' then
                            -- The phase counters steer the branch: enter a
                            -- data phase only if its count is non-zero (a
                            -- request with both counts at zero is a bare
                            -- address probe -> STOP).
                                if wr_left > 0 then
                                    wr_left     <= wr_left - 1;
                                    state       <= DATA_W;
                                    tx_send_reg <= '1';   -- hand over the first data byte
                                elsif rd_left > 0 then
                                    state     <= RSTART;     -- nothing to write: Sr straight to the read phase
                                    rw_reg    <= '1';
                                    start_cnt <= 0;
                                else
                                    state <= STOP;
                                end if;
                            else
                                if rd_left > 0 then
                                    state          <= DATA_R;
                                    rx_receive_reg <= '1';  -- arm I2C_RX for the byte
                                    rx_done_reg    <= '0';  -- no byte captured yet
                                else
                                    state <= STOP;
                                end if;
                            end if;
                        end if;

                    when DATA_W =>
                        -- tx_data carries data_to_transmit now (handed over on
                        -- entry, see ACK_ADDR) and I2C_TX is shifting it out.
                        -- Same handshake as the address byte: wait for the
                        -- serialiser to report the byte as sent, which is the
                        -- falling edge starting the ACK bit cell.
                        if tx_byte_done = '1' then
                            state <= ACK_DATA;
                        end if;

                    when ACK_DATA =>    -- sample the slave acknowledge of the data byte
                        -- SDA was released when the data byte completed (the
                        -- registered mux holds '1' here), so the slave owns the
                        -- line for this bit cell and pulls it low for ACK.
                        -- Sampled on the real bus level throughout the high
                        -- phase (see ACK_ADDR -- this also rides out a clock
                        -- stretch) so even a slow slave is caught; the FSM
                        -- advances at the falling edge that ends the ACK bit
                        -- cell. Three ways out: more write bytes (next DATA_W
                        -- handover), the read phase still pending (repeated
                        -- START, direction flips to R), or the transaction
                        -- ends (STOP). A NACK aborts the remaining phases.
                        if scl_level = '1' then
                            ack_reg <= sda_sync;
                        elsif scl_fall = '1' then
                            if ack_reg = '1' then
                                -- Data NACK: abort the remaining phases and
                                -- close this transaction with STOP.
                                state <= STOP;
                            elsif wr_left > 0 then
                            -- wr_left counts the write bytes not yet handed
                            -- over: hand over the next one while any remain
                            -- (this also sends the FIRST byte, right here at
                            -- the end of the address ACK cell).
                                wr_left     <= wr_left - 1;
                                state       <= DATA_W;
                                tx_send_reg <= '1';   -- hand over the next data byte
                            elsif rd_left > 0 then
                                state     <= RSTART;   -- repeated START leads to the read phase
                                rw_reg    <= '1';      -- the address byte is re-sent with R/W = 1
                                start_cnt <= 0;
                            else
                                state <= STOP;
                            end if;
                        end if;

                    when DATA_R =>
                        -- I2C_RX owns this byte: it was armed on entry (see
                        -- ACK_ADDR) and samples one bit per SCL rising edge,
                        -- MSB first, while the slave drives the line. Its
                        -- byte_done pulses on the rising edge that captures
                        -- the LAST bit, i.e. still inside the final data bit
                        -- cell, so the byte is latched and rx_done_reg is set
                        -- here, but SDA is left alone: the slave still owns it
                        -- until the falling edge that closes the cell. That
                        -- edge is where the master takes the line back for the
                        -- acknowledge, just like the TX states hand SDA over on
                        -- the edges they watch.
                        -- The byte spans G_DATA_WIDTH bit cells, so this state
                        -- must NOT leave on the first falling edge it sees --
                        -- that one only closes the first data bit. It waits for
                        -- rx_done_reg, i.e. for the whole byte.
                        if rx_byte_done = '1' then
                            rx_data_reg <= rx_data;
                            rx_done_reg <= '1';
                        end if;

                        if rx_done_reg = '1' and scl_fall = '1' then
                            state <= ACK_RX;
                        end if;

                    when ACK_RX =>
                        -- The registered output mux holds SDA low for this bit
                        -- cell while more read bytes follow (ACK), or released
                        -- on the last one (NACK -- the slave must see it to
                        -- stop driving the line). On the cell's closing edge:
                        -- more read bytes re-arm I2C_RX for the next one, a
                        -- write phase still pending goes through a repeated
                        -- START, otherwise the STOP condition begins.
                        if scl_fall = '1' then
                            if rd_left > 1 then
                                rd_left        <= rd_left - 1;
                                state          <= DATA_R;
                                rx_receive_reg <= '1';  -- arm I2C_RX for the next byte
                                rx_done_reg    <= '0';
                            elsif wr_left > 0 then
                                state     <= RSTART;   -- repeated START (e.g. R then W phase)
                                rw_reg    <= '0';      -- the address byte is re-sent with R/W = 0
                                start_cnt <= 0;
                            else
                                state <= STOP;
                            end if;
                        end if;

                    when RSTART =>
                        -- Wait for the real SCL rising edge before beginning
                        -- the repeated-START setup-time interval. SDA remains
                        -- released throughout this state.
                        if scl_rise = '1' then
                            start_cnt <= 0;
                            state     <= RSTART_HOLD;
                        end if;

                    when RSTART_HOLD =>
                        -- Hold SCL high and SDA released for at least one
                        -- half-period (5 us at 100 kHz) before pulling SDA
                        -- low. This satisfies tSU;STA for a repeated START.
                        if scl_level = '0' then
                            start_cnt <= 0;
                            state     <= RSTART;
                        elsif start_cnt = C_SETUP_HOLD - 1 then
                            start_cnt <= 0;
                            state     <= START;
                        else
                            start_cnt <= start_cnt + 1;
                        end if;

                    when STOP =>
                        -- STOP begins with SDA held low. Wait for the actual
                        -- SCL rising edge, including any clock stretching.
                        if scl_rise = '1' then
                            start_cnt <= 0;
                            state     <= STOP_HOLD;
                        end if;

                    when STOP_HOLD =>
                        -- Keep SDA low while SCL is high for the STOP setup
                        -- interval (tSU;STO), then release it to create the
                        -- actual SDA rising edge of STOP.
                        if scl_level = '0' then
                            start_cnt <= 0;
                            state     <= STOP;
                        elsif start_cnt = C_SETUP_HOLD - 1 then
                            start_cnt <= 0;
                            state     <= STOP_RELEASE;
                        else
                            start_cnt <= start_cnt + 1;
                        end if;

                    when STOP_RELEASE =>
                        -- SDA is released by the output mux in this state.
                        -- Wait until the synchronized bus level confirms the
                        -- line rose, then enter IDLE and enforce tBUF.
                        if scl_level = '1' and sda_sync = '1' then
                            bus_free_cnt <= 0;
                            state        <= IDLE;
                        end if;

                end case;

                -- Registered output mux (placeholder, same pattern as the
                -- UART TX framing mux): samples the framing decode of the
                -- CURRENT state, so every SDA transition is uniformly
                -- delayed by one clock and bit cells keep their width since
                -- SCL is far slower than clk. The ACK states and DATA_R hold SDA
                -- released ('1' -> 'Z' on the open-drain driver), so the slave
                -- owns the line for those bit cells.
                case state is
                    when IDLE             => sda_reg <= '1';
                    when START            => sda_reg <= '0';
                    when ADDR_RW | DATA_W =>
                        -- Release SDA on the falling edge that completes the
                        -- byte, so the slave owns the ACK cell immediately.
                        -- On the first cycle after tx_send_reg, I2C_TX is still
                        -- loading its registered serial output.  Use the byte
                        -- MSB directly for that cycle; otherwise a stale '1'
                        -- from tx_bit can make a short pulse before a leading
                        -- zero appears on SDA.
                        if tx_send_reg = '1' then
                            sda_reg <= tx_data(7);
                        elsif tx_byte_done = '1' then
                            sda_reg <= '1';
                        else
                            sda_reg <= tx_bit;
                        end if;
                    when ACK_ADDR =>
                        -- The slave releases SDA at the end of the address
                        -- ACK cell.  If a write byte follows, present its MSB
                        -- on that same bus-low boundary instead of waiting for
                        -- I2C_TX's registered load path; otherwise a short
                        -- released-SDA pulse appears before a leading '0'.
                        if scl_fall = '1' and rw_reg = '0' and wr_left > 0 then
                            sda_reg <= data_to_transmit(7);
                        else
                            sda_reg <= '1';
                        end if;
                    when ACK_DATA =>
                        -- Same handoff for consecutive write bytes.  The next
                        -- byte is already available on data_to_transmit when
                        -- tx_done is used as the streaming handover.
                        if scl_fall = '1' and wr_left > 0 then
                            sda_reg <= data_to_transmit(7);
                        else
                            sda_reg <= '1';
                        end if;
                    when DATA_R           =>
                        -- Select the master's ACK/NACK as DATA_R hands the
                        -- bus to ACK_RX; do not leave a one-clk SDA gap.
                        if rx_done_reg = '1' and scl_fall = '1' then
                            if rd_left > 1 then
                                sda_reg <= '0';
                            else
                                sda_reg <= '1';
                            end if;
                        else
                            sda_reg <= '1';
                        end if;
                    when ACK_RX           =>
                        -- ACK for every read byte except the last one (the
                        -- byte still counted in rd_left): the NACK tells the
                        -- slave to release SDA so the master can frame the
                        -- STOP.
                        if rd_left = 1 then
                            sda_reg <= '1';     -- NACK on the last read byte
                        else
                            sda_reg <= '0';     -- ACK, more bytes follow
                        end if;
                    when RSTART           => sda_reg <= '1';  -- released while waiting for SCL high
                    when RSTART_HOLD     => sda_reg <= '1';  -- released during tSU;STA
                    when STOP            => sda_reg <= '0';  -- hold low until SCL rises
                    when STOP_HOLD       => sda_reg <= '0';  -- hold low for tSU;STO
                    when STOP_RELEASE    => sda_reg <= '1';  -- release: the actual STOP edge
                end case;

                -- Registered status output
                if state = IDLE then
                    busy_reg <= '0';
                else
                    busy_reg <= '1';
                end if;
            end if;
        end if;
    end process;

    -- Byte handed to the serialiser. The load pulse and the state that owns the
    -- byte line up: tx_send_reg is set on the SCL falling edge that ENTERS
    -- ADDR_RW or DATA_W, so by the time I2C_TX captures the byte the registered
    -- state already selects the right one:
    --   ADDR_RW -> {addr(6:0), rw}   (slaves see A6..A0 then the R/W bit)
    --   DATA_W  -> data_to_transmit
    tx_data <= addr_reg & rw_reg when state = ADDR_RW else data_to_transmit;

end architecture rtl;
