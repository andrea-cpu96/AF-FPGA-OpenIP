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
-- All nine states are implemented: the write path (IDLE, START, ADDR_RW,
-- ACK_ADDR, DATA_W, ACK_DATA, STOP) and the read path (DATA_R + ACK_RX, which
-- I2C_RX serves). SCL is gated off at IDLE -- the bus is released high between
-- transactions -- and the FSM is timed on the real bus edges, so a slave
-- holding SCL low (clock stretching) simply delays every following edge.
-- Still pending: exposing transaction status on the module ports.

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
        data_to_transmit : in std_logic_vector(7 downto 0);  -- byte to write
        data_to_read : out std_logic_vector(7 downto 0);    -- last complete byte read; zero on reset
        sda   : inout std_logic;                   -- I2C bus data (open drain)
        scl   : inout std_logic                    -- I2C bus clock (open drain)
    );
end entity I2C_Master;


architecture rtl of I2C_Master is

    -- SCL divider: system clock cycles per SCL period
    constant C_DIVIDER : natural := G_CLK_FREQ / G_I2C_FREQ;

    -- START hold time, in clk cycles: after the SDA fall of the START
    -- condition, SCL stays high for half an SCL period before the first SCL
    -- fall. The free-running divider used to give the same hold.
    constant C_START_HOLD : natural := C_DIVIDER / 2;

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
    signal start_cnt : natural range 0 to C_START_HOLD := 0;

    -- Transaction FSM (one data byte per transaction for now):
    --   IDLE     : bus free, waiting for a request (w = write, r = read)
    --   START    : START condition -- SDA falls while SCL is high
    --   ADDR_RW  : shift out the address byte, {addr(6:0), rw}
    --   ACK_ADDR : release SDA and sample the slave acknowledge
    --   DATA_W   : shift out the data byte (write transaction)
    --   ACK_DATA : sample the slave acknowledge of that data byte
    --   DATA_R   : shift in the data byte (read transaction)
    --   ACK_RX   : master drives ACK/NACK for the received byte
    --   STOP     : STOP condition -- SDA rises while SCL is high
    type state_t is (IDLE, START, ADDR_RW, ACK_ADDR, DATA_W, ACK_DATA,
                     DATA_R, ACK_RX, STOP);
    signal state : state_t := IDLE;

    -- Direction of the current transaction, latched when the request is
    -- accepted. The FSM branches on it much later (ACK_ADDR decides between
    -- DATA_W and DATA_R), so it must not change mid-transaction. It is also
    -- bit 0 of the address byte: {addr(6:0), rw}.
    signal rw_reg : std_logic := '0';

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
    signal scl_rise : std_logic := '0';
    signal scl_fall : std_logic := '0';

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

    data_to_read <= rx_data_reg;

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

    -- SCL edge detector: one-clk-wide pulses in the system clock domain.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                scl_prev <= '1';
                scl_rise <= '0';
                scl_fall <= '0';
            else
                scl_prev <= scl_level;
                scl_rise <= scl_level and not scl_prev;
                scl_fall <= (not scl_level) and scl_prev;
            end if;
        end if;
    end process;

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
                        if (w = '1' or r = '1') and scl_level = '1'
                           and sda_sync = '1' then
                            rw_reg <= r;
                            state  <= START;
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
                        if start_cnt = C_START_HOLD - 1 then
                            scl_en_r  <= '1';   -- SCL pull-down from here on
                            start_cnt <= 0;
                        else
                            start_cnt <= start_cnt + 1;
                        end if;
                        if scl_fall = '1' then
                            state       <= ADDR_RW;
                            tx_send_reg <= '1';   -- hand over {addr, rw}
                            -- Leave the counter at zero: it keeps counting
                            -- during the 2 clk it takes the edge detector to
                            -- report the fall, and a frozen residue would make
                            -- the NEXT START hold shorter (or overflow the
                            -- range for small dividers).
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
                            if rw_reg = '0' then
                                state       <= DATA_W;
                                tx_send_reg <= '1';   -- hand over the data byte
                            else
                                state          <= DATA_R;
                                rx_receive_reg <= '1';  -- arm I2C_RX for the byte
                                rx_done_reg    <= '0';  -- no byte captured yet
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
                        -- cell.
                        if scl_level = '1' then
                            ack_reg <= sda_sync;
                        elsif scl_fall = '1' then
                            state <= STOP;
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
                        -- The registered output mux holds SDA low for this whole
                        -- bit cell, so the slave samples the master acknowledge:
                        -- the byte was taken. (A multi-byte read would leave SDA
                        -- released here instead -- NACK -- for the last byte.)
                        -- No sampling is needed in the master: only the edge
                        -- that ends the cell matters, and that is where the STOP
                        -- condition begins.
                        if scl_fall = '1' then
                            state <= STOP;
                        end if;

                    when STOP =>        -- SDA rises while SCL is high
                        -- sda_reg is already '1' (released) from this state's
                        -- output-mux entry, so the open-drain driver holds the
                        -- pin in 'Z'. The external pull-up therefore raises SDA
                        -- high now. Wait until SCL itself has risen high so both
                        -- lines are high -- that is the I2C STOP condition -- then
                        -- close out the transaction.
                        if scl_rise = '1' then
                            state <= IDLE;
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
                    when ADDR_RW | DATA_W => sda_reg <= tx_bit;
                    when ACK_ADDR | ACK_DATA => sda_reg <= '1';
                    when DATA_R           => sda_reg <= '1';
                    when ACK_RX           => sda_reg <= '0';  -- ACK (NACK when no more bytes)
                    when STOP             => sda_reg <= '1';
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
    tx_data <= addr & rw_reg when state = ADDR_RW else data_to_transmit;

end architecture rtl;
