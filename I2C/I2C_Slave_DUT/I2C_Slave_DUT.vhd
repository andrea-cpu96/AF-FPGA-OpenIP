-- I2C_Slave_DUT.vhd
-- Board-level design-under-test wrapper for I2C_Slave -- the target-side
-- counterpart of the ../I2C_DUT/ master wrapper. Minimal 4-pin interface:
-- only clk, rst_n and the open-drain I2C bus (sda/scl) are brought out; the
-- whole byte-stream host interface of the slave (data_to_transmit /
-- data_received / rx_valid / tx_done / busy / stretch_active) is kept internal.
-- An on-chip dialogue FSM sits on top of that byte-stream interface and plays
-- the bench dialogue the FPGA must answer as an I2C target:
--   1. wait for an EXTERNAL I2C master to address this slave and WRITE the
--      command byte 0xAA (every other written byte is ignored);
--   2. once the command has been latched, the byte the master READS back is
--      0xEE -- either a plain read of the following frame, or the classic
--      write-then-read idiom (0xAA, repeated START, <addr+R>) inside one frame;
--   3. before the command arrives, reads are answered with the idle byte 0x00,
--      so the un-armed state is visible on the bus too;
--   4. when the frame that handed the 0xEE over closes (STOP, i.e. the slave's
--      busy falls), the DUT dis-arms and waits for a fresh 0xAA -- so an
--      oscilloscope / logic-analyzer capture shows the whole command/reply
--      dialogue repeating, exactly like ../I2C_DUT/ streams its frames.
-- Change the constants below to run a different dialogue; the slave itself is
-- used unmodified, with clock stretching left enabled (G_STRETCH_CYCLES).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity I2C_Slave_DUT is
    generic (
        G_SLAVE_ADDR     : std_logic_vector(6 downto 0) := "0111100"; -- 7-bit slave address (0x3C)
        G_CLK_FREQ       : natural := 50_000_000;  -- system clock [Hz]
        G_I2C_FREQ       : natural := 100_000;     -- SCL bus clock [Hz] (standard mode)
        G_STRETCH_CYCLES : natural := 500          -- SCL low hold per ACK cell [clk cycles] (0 = off)
    );
    port (
        clk   : in    std_logic;
        rst_n : in    std_logic;
        sda   : inout std_logic;             -- I2C bus data (open drain)
        scl   : inout std_logic              -- I2C bus clock (open drain)
    );
end entity I2C_Slave_DUT;

architecture rtl of I2C_Slave_DUT is

    -- Dialogue constants: the command the external master writes, the byte the
    -- DUT answers to the read that follows it, and the byte it answers while no
    -- command has arrived yet (the "not armed" reply).
    constant C_CMD_BYTE  : std_logic_vector(7 downto 0) := x"AA";  -- command written by the master
    constant C_RESP_BYTE : std_logic_vector(7 downto 0) := x"EE";  -- reply after a latched command
    constant C_IDLE_BYTE : std_logic_vector(7 downto 0) := x"00";  -- reply before the command

    -- Slave byte-stream interface (internal): the only signals the dialogue FSM
    -- drives or watches.
    signal tx_data  : std_logic_vector(7 downto 0) := C_IDLE_BYTE;  -- next byte the master reads
    signal rx_data  : std_logic_vector(7 downto 0);                 -- last byte written by the master
    signal rx_valid : std_logic;                                    -- pulse: rx_data updated
    signal tx_done  : std_logic;                                    -- pulse: a read byte was fully sent
    signal busy     : std_logic;                                    -- '1' while a frame addressed here runs

    -- Dialogue bookkeeping: the reply is a one-shot, re-armed when the frame
    -- that carried it has closed.
    signal resp_sent : std_logic := '0';   -- the 0xEE reply was handed over

begin

    -- label : entity library.entity_name(architecture_name)
    uI2C : entity work.I2C_Slave(rtl)
        generic map (
            G_SLAVE_ADDR     => G_SLAVE_ADDR,
            G_CLK_FREQ       => G_CLK_FREQ,
            G_I2C_FREQ       => G_I2C_FREQ,
            G_STRETCH_CYCLES => G_STRETCH_CYCLES
        )
        port map (
            clk              => clk,
            rst_n            => rst_n,
            data_to_transmit => tx_data,
            data_received    => rx_data,
            rx_valid         => rx_valid,
            tx_done          => tx_done,
            busy             => busy,
            stretch_active   => open,
            sda              => sda,
            scl              => scl
        );

    -- Dialogue FSM, one layer above the byte stream: the command gate (a
    -- written 0xAA arms the reply) and the one-shot reply handshake. A read
    -- before the command is answered with the idle byte, and the reply is
    -- re-armed only once the frame that carried it has closed, so the bench
    -- dialogue repeats frame after frame.
    dialogue : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                resp_sent <= '0';
                tx_data   <= C_IDLE_BYTE;
            else
                -- Command phase: the written byte equal to the command arms the
                -- reply; any other byte leaves the DUT un-armed.
                if rx_valid = '1' and rx_data = C_CMD_BYTE then
                    tx_data <= C_RESP_BYTE;
                end if;

                -- Reply handshake: the byte handed to I2C_TX is a one-shot ...
                if resp_sent = '1' and busy = '0' then
                    -- ... and the frame that carried it has closed (STOP): gate
                    -- the command again, so the next read is answered with the
                    -- idle byte until a new 0xAA arrives.
                    resp_sent <= '0';
                    tx_data   <= C_IDLE_BYTE;
                elsif tx_done = '1' then
                    resp_sent <= '1';
                end if;
            end if;
        end if;
    end process dialogue;

end architecture rtl;
