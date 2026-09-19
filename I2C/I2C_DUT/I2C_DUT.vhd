-- I2C_DUT.vhd
-- Design-under-test wrapper for I2C_Master with a minimal 4-pin interface.
-- Only clk, rst_n and the open-drain I2C bus (sda/scl) are brought out; the
-- whole master interface (requests, address, data, status) is kept internal.
-- A small on-chip stimulus process re-issues a write transaction (slave
-- 0x68, data 0xA5, one byte) whenever the master is idle, so the bus shows
-- a continuous stream of complete frames that can be probed directly with
-- an oscilloscope/logic analyzer. Change the constants below to measure a
-- different address or payload.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity I2C_DUT is
    generic (
        G_CLK_FREQ : natural := 50_000_000;  -- system clock [Hz]
        G_I2C_FREQ : natural := 100_000      -- SCL bus clock [Hz] (standard mode)
    );
    port (
        clk   : in    std_logic;
        rst_n : in    std_logic;
        sda   : inout std_logic;             -- I2C bus data (open drain)
        scl   : inout std_logic              -- I2C bus clock (open drain)
    );
end entity I2C_DUT;

architecture rtl of I2C_DUT is

    -- Internal master interface: stimulus constants and status taps
    -- (unused taps are trimmed by synthesis; still visible in simulation).
    signal w                : std_logic := '0';                            -- write request
    signal r                : std_logic := '0';                            -- read request (not used)
    signal addr             : std_logic_vector(6 downto 0) := "1101000";   -- 7-bit slave address (0x68)
    signal data_to_transmit : std_logic_vector(7 downto 0) := x"A5";       -- byte to write
    signal n_write          : std_logic_vector(3 downto 0) := "0001";      -- 1 data byte in the write phase
    signal n_read           : std_logic_vector(3 downto 0) := "0000";      -- no read phase
    signal data_to_read     : std_logic_vector(7 downto 0);                -- read data (not used)
    signal tx_done          : std_logic;                                   -- status tap (not used)
    signal rx_valid         : std_logic;                                   -- status tap (not used)
    signal busy             : std_logic;                                   -- '1' while a transaction runs
    signal ack              : std_logic;                                   -- last sampled slave ACK

begin

    -- label : entity library.entity_name(architecture_name)
    uI2C : entity work.I2C_Master(rtl)
        generic map (
            G_CLK_FREQ => G_CLK_FREQ,
            G_I2C_FREQ => G_I2C_FREQ
        )
        port map (
            clk              => clk,
            rst_n            => rst_n,
            w                => w,
            r                => r,
            addr             => addr,
            data_to_transmit => data_to_transmit,
            n_write          => n_write,
            n_read           => n_read,
            data_to_read     => data_to_read,
            tx_done          => tx_done,
            tx_data_done     => open,
            rx_valid         => rx_valid,
            busy             => busy,
            ack              => ack,
            sda              => sda,
            scl              => scl
        );

    -- Internal stimulus: hold w high whenever the master is idle and drop it
    -- as soon as the request is taken (busy = '1'), per the w/r handshake.
    -- The next transaction starts right after the current one completes, so
    -- the bus carries a continuous stream of identical frames.
    stim : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                w <= '0';
            elsif busy = '1' then
                w <= '0';
            else
                w <= '1';
            end if;
        end if;
    end process stim;

end architecture rtl;