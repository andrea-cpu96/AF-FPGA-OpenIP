-- I2C_Master.vhd
-- I2C master top level. Hosts the single transaction FSM of the design
-- (START/STOP framing, address + R/W field, per-byte handshakes) and the
-- reusable sub-modules it orchestrates:
--   clock_div : divides clk down to the SCL bus clock (instantiated)
--   I2C_TX    : serialises the address/data bytes     (instantiated)
--   I2C_RX    : samples data and slave-ACK bits       (pending)
-- Ownership: the bus (SDA framing) belongs to this FSM alone, because I2C is
-- half duplex on one shared wire; TX/RX only own the bit pacing of the bytes
-- they handle and report a done flag per byte.
-- SDA is an open-drain line: the master only ever pulls it low ('0') or
-- releases it ('Z'), so START/STOP, the ACK bit and the received data all rely
-- on the external pull-up.
-- IDLE, START, ADDR_RW, ACK_ADDR, DATA_W, ACK_DATA and STOP implemented;
-- the read path (DATA_R, ACK_RX, I2C_RX) are still placeholders.

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
        sda   : inout std_logic;                   -- I2C bus data (open drain)
        scl   : out std_logic                      -- I2C bus clock
    );
end entity I2C_Master;


architecture rtl of I2C_Master is

    -- SCL divider: system clock cycles per SCL period
    constant C_DIVIDER : natural := G_CLK_FREQ / G_I2C_FREQ;

    -- clock_div control. Placeholder: SCL runs continuously until the FSM
    -- gates it (state = IDLE -> bus stopped), which needs the states below
    -- to be filled in first.
    signal enable : std_logic;

    -- Divider output. scl is an out port and cannot be read back, so the
    -- bus clock is kept in this internal signal: it drives the pin and is
    -- what the edge detector looks at.
    signal scl_int : std_logic;

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

    -- Registered outputs (module outputs are FF driven, glitch free)
    signal sda_reg  : std_logic := '1';   -- SDA idles high (open-drain pull-up)
    signal busy_reg : std_logic := '0';   -- '1' while a transaction is in progress

begin

    enable <= '1';   -- placeholder: SCL always running (FSM control pending)

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

    -- SCL reaches the pin through a single continuous driver.
    scl <= scl_int;

    -- SDA reaches the pin through an open-drain driver: the master only pulls
    -- the line low and releases it otherwise, so it can never fight the slave.
    -- sda_reg = '0' -> drive low, sda_reg = '1' -> release ('Z', pulled up
    -- externally).
    sda <= '0' when sda_reg = '0' else 'Z';

    -- SDA input synchroniser (2 FF): the slave drives this line asynchronously
    -- to clk. Everything that reads SDA (the ACK sample now, the received bits
    -- later) uses this synchronised copy, never the raw pin.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                sda_meta <= '1';
                sda_sync <= '1';
            else
                sda_meta <= sda;
                sda_sync <= sda_meta;
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
            scl              => scl_int,
            send             => tx_send_reg,
            data_to_transmit => tx_data,
            tx_bit           => tx_bit,
            byte_done        => tx_byte_done,
            busy             => tx_busy
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
                scl_prev <= scl_int;
                scl_rise <= scl_int and not scl_prev;
                scl_fall <= (not scl_int) and scl_prev;
            end if;
        end if;
    end process;

    -- Transaction FSM: state and registered outputs update on the rising
    -- clock edge. The case bodies are placeholders -- each state will
    -- advance on the SCL edge pulses detected above and drive the
    -- I2C_TX/I2C_RX handshake signals accordingly.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state       <= IDLE;
                sda_reg     <= '1';   -- SDA released (high) on reset
                busy_reg    <= '0';
                tx_send_reg <= '0';
            else
                tx_send_reg <= '0';   -- one-clk pulse: set when a byte is handed over

                case state is

                    when IDLE =>
                        -- Wait for a request, sampled on an SCL rising edge:
                        -- this leaves roughly half an SCL period of high SCL
                        -- after entry, so the SDA fall of the START condition
                        -- (registered mux, one cycle later) happens while SCL
                        -- is still high. The direction is latched here (if both
                        -- w and r are high at the same time, read wins).
                        if (w = '1' or r = '1') and scl_rise = '1' then
                            rw_reg <= r;
                            state  <= START;
                        end if;

                    when START =>
                        -- sda_reg is driven low by the registered output mux
                        -- while SCL is still high: that IS the START
                        -- condition. On the next SCL falling edge the address
                        -- byte is handed to I2C_TX, which presents its first
                        -- bit there (tx_send, below).
                        if scl_fall = '1' then
                            state       <= ADDR_RW;
                            tx_send_reg <= '1';   -- hand over {addr, rw}
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
                        -- or a read (DATA_R) begins. (scl_int, not the scl port:
                        -- an out port cannot be read.)
                        if scl_int = '1' then
                            ack_reg <= sda_sync;
                        elsif scl_fall = '1' then
                            if rw_reg = '0' then
                                state       <= DATA_W;
                                tx_send_reg <= '1';   -- hand over the data byte
                            else
                                state <= DATA_R;
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
                        -- Sampled throughout the SCL high phase so even a slow
                        -- slave is caught; the FSM advances at the falling edge
                        -- that ends the ACK bit cell.
                        if scl_int = '1' then
                            ack_reg <= sda_sync;
                        elsif scl_fall = '1' then
                            state <= STOP;
                        end if;

                    when DATA_R =>      -- shift in the data byte through I2C_RX
                        null;

                    when ACK_RX =>      -- master drives ACK/NACK for the received byte
                        null;

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

    -- Open-drain SDA driver. The master only ever pulls the line low or
    -- releases it; the external pull-up raises it to '1'. This is what lets the
    -- slave drive the ACK bit: whenever the master holds sda_reg = '1' the pin
    -- goes to 'Z' and the slave owns the wire.
    sda <= '0' when sda_reg = '0' else 'Z';

end architecture rtl;
