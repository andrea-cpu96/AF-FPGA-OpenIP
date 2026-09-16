-- I2C_RX.vhd
-- I2C byte de-serialiser (RX path of the I2C_Master hierarchy). Captures the
-- 8 bits the slave drives on SDA, MSB first, through serial_to_parallel and
-- reports when the byte is complete.
-- Like I2C_TX it owns the BIT pacing (one bit sampled per SCL rising edge,
-- which is when I2C data is valid) but not the bus framing: the ACK phases,
-- START/STOP and SDA itself belong to the I2C_Master FSM.
-- I2C is half duplex on one shared wire, so there is deliberately no FSM
-- here: a bit counter plus the SCL edge detector is all a byte needs.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity I2C_RX is
    generic (
        G_DATA_WIDTH : positive := 8
    );
    port (
        clk           : in  std_logic;
        rst_n         : in  std_logic;
        scl           : in  std_logic;                                   -- SCL from clock_div: bit pacing reference
        receive       : in  std_logic;                                   -- '1': start capturing a byte
        sda_in        : in  std_logic;                                   -- synchronised SDA (slave drives it)
        data_received : out std_logic_vector(G_DATA_WIDTH - 1 downto 0); -- captured byte
        byte_done     : out std_logic;                                   -- one-clk pulse: byte captured
        busy          : out std_logic                                    -- '1' while a byte is being captured
    );
end entity I2C_RX;

architecture rtl of I2C_RX is

    -- serial_to_parallel interface
    signal shift : std_logic;

    -- bit pacing: one bit sampled per SCL rising edge
    signal count         : natural range 0 to G_DATA_WIDTH - 1 := 0;
    signal busy_reg      : std_logic := '0';
    signal byte_done_reg : std_logic := '0';

    -- SCL rising edge detector. scl comes from clock_div, generated
    -- registered inside this same clk domain, so no synchronizer is needed.
    signal scl_prev : std_logic := '0';
    signal scl_rise : std_logic := '0';

begin

    -- The slave presents each data bit while SCL is low and it is valid during
    -- the following high phase, so the sample point is the SCL rising edge.
    -- serial_to_parallel shifts in at position 0 and pushes the earlier bits
    -- up, which is exactly the MSB-first order I2C uses: after G_DATA_WIDTH
    -- shifts bit 7 holds the first received bit (the MSB).
    u_s2p : entity work.serial_to_parallel
        generic map (
            G_DATA_WIDTH => G_DATA_WIDTH
        )
        port map (
            clk      => clk,
            rst_n    => rst_n,
            shift    => shift,
            data_in  => sda_in,
            data_out => data_received
        );

    -- SCL rising edge detector: one-clk-wide pulse in the system clock domain.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                scl_prev <= '0';
                scl_rise <= '0';
            else
                scl_prev <= scl;
                scl_rise <= scl and not scl_prev;
            end if;
        end if;
    end process;

    -- Bit pacing. `receive` arms the capture; every following SCL rising edge
    -- samples one more bit, and the 8th one both samples the last bit and
    -- completes the byte:
    --   receive            : armed, first bit sampled on the next SCL rise
    --   rises 1..8         : bits G_DATA_WIDTH-1 .. 0 sampled (MSB first)
    --   rise 8             : byte_done pulse (the ACK bit cell starts here)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                count         <= 0;
                busy_reg      <= '0';
                byte_done_reg <= '0';
            else
                byte_done_reg <= '0';              -- one-clk pulse
                if receive = '1' then
                    count    <= 0;
                    busy_reg <= '1';
                elsif busy_reg = '1' and scl_rise = '1' then
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

    -- Combinational shift control: sample a bit on EVERY SCL rising edge while
    -- capturing, including the edge that completes the byte -- each of the
    -- G_DATA_WIDTH bits is shifted in, so the last shift and the byte_done
    -- pulse fall on the same clock edge.
    shift <= '1' when busy_reg = '1' and scl_rise = '1' else '0';

    -- Continuous output drivers: one driver per port.
    byte_done <= byte_done_reg;
    busy      <= busy_reg;

end architecture rtl;
