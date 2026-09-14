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
-- Skeleton state -- IDLE and START implemented, the other cases are empty.

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
        w     : in  std_logic;               -- write request (hold until busy = '1')
        scl   : out std_logic                -- I2C bus clock
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
    signal tx_send      : std_logic;                     -- '1': hand a byte to the serialiser
    signal tx_data      : std_logic_vector(7 downto 0);  -- byte to send: {addr(6:0), rw}
    signal tx_bit       : std_logic;                     -- serial bit presented by I2C_TX
    signal tx_byte_done : std_logic;                     -- I2C_TX: byte fully sent
    signal tx_busy      : std_logic;                     -- I2C_TX status: '1' while shifting

    -- Registered outputs (module outputs are FF driven, glitch free)
    signal sda_r  : std_logic := '1';   -- SDA idles high (open-drain pull-up)
    signal busy_r : std_logic := '0';   -- '1' while a transaction is in progress

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
            send             => tx_send,
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
                state  <= IDLE;
                sda_r  <= '1';   -- SDA released (high) on reset
                busy_r <= '0';
            else
                case state is

                    when IDLE =>
                        -- Wait for a write request, sampled on an SCL rising
                        -- edge: this leaves roughly half an SCL period of high
                        -- SCL after entry, so the SDA fall of the START
                        -- condition (registered mux, one cycle later) happens
                        -- while SCL is still high.
                        if w = '1' and scl_rise = '1' then
                            state <= START;
                        end if;

                    when START =>
                        -- sda_r is driven low by the registered output mux
                        -- while SCL is still high: that IS the START
                        -- condition. On the next SCL falling edge the address
                        -- byte is handed to I2C_TX, which presents its first
                        -- bit there (tx_send, below).
                        if scl_fall = '1' then
                            state <= ADDR_RW;
                        end if;

                    when ADDR_RW =>     -- I2C_TX sends {addr(6:0), rw}, then tx_byte_done
                        null;

                    when ACK_ADDR =>    -- release SDA, sample the slave acknowledge
                        null;

                    when DATA_W =>      -- shift out the data byte through I2C_TX
                        null;

                    when ACK_DATA =>    -- sample the slave acknowledge of the data byte
                        null;

                    when DATA_R =>      -- shift in the data byte through I2C_RX
                        null;

                    when ACK_RX =>      -- master drives ACK/NACK for the received byte
                        null;

                    when STOP =>        -- SDA rises while SCL is high
                        null;

                end case;

                -- Registered output mux (placeholder, same pattern as the
                -- UART TX framing mux): samples the framing decode of the
                -- CURRENT state, so every SDA transition is uniformly
                -- delayed by one clock and bit cells keep their width since
                -- SCL is far slower than clk. The ACK states and DATA_R release
                -- SDA to the slave; the bus driver (inout + 'Z' while
                -- receiving) arrives with the bus interface.
                case state is
                    when IDLE             => sda_r <= '1';
                    when START            => sda_r <= '0';
                    when ADDR_RW | DATA_W => sda_r <= tx_bit;
                    when ACK_ADDR | ACK_DATA => sda_r <= '1';
                    when DATA_R           => sda_r <= '1';
                    when ACK_RX           => sda_r <= '0';  -- ACK (NACK when no more bytes)
                    when STOP             => sda_r <= '1';
                end case;

                -- Registered status output
                if state = IDLE then
                    busy_r <= '0';
                else
                    busy_r <= '1';
                end if;
            end if;
        end if;
    end process;

    -- Byte handover to I2C_TX: a byte is sent on the SCL falling edge that
    -- leaves START, which is also the edge that presents the first bit of
    -- that byte on SDA.
    tx_send <= '1' when state = START and scl_fall = '1' else '0';

    -- Byte handed to the serialiser. ADDR_RW sends the packed address byte
    -- {addr(6:0), rw}; addr/rw and the data byte arrive with the user-side
    -- ports, so this is a placeholder for now.
    tx_data <= (others => '0');

end architecture rtl;
