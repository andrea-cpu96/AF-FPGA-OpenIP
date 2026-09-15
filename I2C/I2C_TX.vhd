-- I2C_TX.vhd
-- I2C byte serialiser (TX path of the I2C_Master hierarchy). Takes one byte,
-- shifts it out MSB first (I2C bit order) through parallel_to_serial and
-- reports when the byte has been sent.
-- It owns the BIT pacing (one bit per SCL falling edge) but not the bus
-- framing: START/STOP generation, the address + R/W packing, the ACK phases
-- and SDA itself belong to the I2C_Master FSM, the single owner of the bus.
-- I2C is half duplex on one shared wire, so there is deliberately no FSM
-- here: a load counter plus the SCL edge detector is all a byte needs.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity I2C_TX is
    generic (
        G_DATA_WIDTH : positive := 8
    );
    port (
        clk              : in  std_logic;
        rst_n            : in  std_logic;
        scl              : in  std_logic;                                   -- SCL from clock_div: bit pacing reference
        send             : in  std_logic;                                   -- '1': load the byte and start sending
        data_to_transmit : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0); -- byte to send (address or data)
        tx_bit           : out std_logic;                                   -- serial bit presented on the bus
        byte_done        : out std_logic;                                   -- one-clk pulse: the byte has been sent
        busy             : out std_logic                                    -- '1' while a byte is being sent
    );
end entity I2C_TX;

architecture rtl of I2C_TX is

    -- parallel_to_serial interface
    signal load       : std_logic;
    signal shift      : std_logic;
    signal data_out_b : std_logic;   -- raw serial bit from P2S (already registered)

    -- bit pacing: one bit presented per SCL falling edge
    signal count         : natural range 0 to G_DATA_WIDTH - 1 := 0;
    signal busy_reg      : std_logic := '0';
    signal byte_done_reg : std_logic := '0';

    -- SCL falling edge detector. scl comes from clock_div, generated
    -- registered inside this same clk domain, so no synchronizer is needed.
    signal scl_prev : std_logic := '1';
    signal scl_fall : std_logic := '0';

begin

    u_p2s : entity work.parallel_to_serial
        generic map (
            G_DATA_WIDTH => G_DATA_WIDTH,
            G_MSB_FIRST  => true      -- I2C sends the MSB first
        )
        port map (
            clk      => clk,
            rst_n    => rst_n,
            shift    => shift,
            load     => load,
            data_in  => data_to_transmit,
            data_out => data_out_b
        );

    -- SCL falling edge detector: one-clk-wide pulse in the system clock
    -- domain. I2C data may only change while SCL is low, so these pulses
    -- drive the whole bit pacing.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                scl_prev <= '1';
                scl_fall <= '0';
            else
                scl_prev <= scl;
                scl_fall <= (not scl) and scl_prev;
            end if;
        end if;
    end process;

    -- Bit pacing. `send` captures the byte so its MSB is presented straight
    -- away; every following SCL falling edge shifts one more bit out, and the
    -- falling edge after the last bit completes the byte:
    --   load             : MSB presented (bit G_DATA_WIDTH-1)
    --   next falls 1..7  : bits G_DATA_WIDTH-2 .. 0 presented
    --   next fall 8      : byte_done pulse (the ACK bit cell starts here)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                count         <= 0;
                busy_reg      <= '0';
                byte_done_reg <= '0';
            else
                byte_done_reg <= '0';              -- one-clk pulse
                if send = '1' then
                    count    <= 0;
                    busy_reg <= '1';
                elsif busy_reg = '1' and scl_fall = '1' then
                    if count = G_DATA_WIDTH - 1 then
                        byte_done_reg <= '1';
                        busy_reg      <= '0';
                    else
                        count <= count + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Combinational control for the serialiser: `load` captures the byte on
    -- the send pulse, `shift` presents the next bit on every falling edge in
    -- between (never on the edge that completes the byte).
    load  <= send;
    shift <= '1' when busy_reg = '1' and scl_fall = '1'
                      and count /= G_DATA_WIDTH - 1 else '0';

    -- Continuous output drivers: one driver per port. tx_bit is the P2S
    -- output, which already comes from a flip-flop.
    tx_bit    <= data_out_b;
    byte_done <= byte_done_reg;
    busy      <= busy_reg;

end architecture rtl;