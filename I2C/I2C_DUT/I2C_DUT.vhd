-- I2C_DUT.vhd
-- Design-under-test wrapper for I2C_Master with a minimal 4-pin interface.
-- Only clk, rst_n and the open-drain I2C bus (sda/scl) are brought out; the
-- whole master interface (requests, address, data, status) is kept internal.
-- A small on-chip stimulus FSM runs the command/confirm sequence:
--   1. write the command byte 0xA8 to slave 0x3C, then -- through the
--      repeated START -- read the one-byte reply back from it (n_read = 1);
--   2. wait for the reply byte (rx_valid) and check it;
--   3. if the reply was 0xAA, start a write of 0xEE to the same slave;
--      otherwise the command phase is re-issued, so the bus keeps streaming
--      frames that can be probed directly with an oscilloscope/logic
--      analyzer. Change the constants below to run a different sequence.

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

    -- Stimulus constants: slave address, command byte, the reply that
    -- unlocks the write phase, and the confirm byte written on a match.
    constant C_SLAVE_ADDR : std_logic_vector(6 downto 0) := "0111100";  -- 7-bit slave address (0x3C)
    constant C_CMD_BYTE   : std_logic_vector(7 downto 0) := x"A8";      -- command sent to the slave
    constant C_REPLY_BYTE : std_logic_vector(7 downto 0) := x"AA";      -- expected reply byte
    constant C_DATA_BYTE  : std_logic_vector(7 downto 0) := x"EE";      -- byte written on a matching reply

    -- Stimulus FSM states:
    --   CFG_CMD : load the command-phase request (write 0xA8 + read 1 reply byte)
    --   CMD_REQ : raise w, drop it once the master takes the request (busy = '1')
    --   CMD_RUN : transaction running; capture the reply byte on rx_valid
    --   CHECK   : reply received and equal to 0xAA -> write phase, else re-issue
    --   CFG_WR  : load the confirm-phase request (write 0xEE, no read phase)
    --   WR_REQ  : raise w, drop it once the master takes the request
    --   WR_RUN  : wait for the confirm write to finish, then loop back
    type stim_state_t is (CFG_CMD, CMD_REQ, CMD_RUN, CHECK, CFG_WR, WR_REQ, WR_RUN);
    signal stim_state : stim_state_t := CFG_CMD;

    -- Internal master interface: stimulus constants and status taps
    -- (unused taps are trimmed by synthesis; still visible in simulation).
    signal w                : std_logic := '0';                            -- write request
    signal r                : std_logic := '0';                            -- read request (not used: the reply is
                                                                           -- collected inside the command transaction
                                                                           -- through the repeated-START read-back)
    signal addr             : std_logic_vector(6 downto 0) := C_SLAVE_ADDR;
    signal data_to_transmit : std_logic_vector(7 downto 0) := C_CMD_BYTE;  -- command byte / confirm byte
    signal n_write          : std_logic_vector(3 downto 0) := "0001";      -- 1 data byte in the write phase
    signal n_read           : std_logic_vector(3 downto 0) := "0001";      -- 1 reply byte after the repeated START
    signal data_to_read     : std_logic_vector(7 downto 0);                -- reply byte read from the slave
    signal tx_done          : std_logic;                                   -- status tap (not used)
    signal rx_valid         : std_logic;                                   -- pulse: a reply byte landed in data_to_read
    signal busy             : std_logic;                                   -- '1' while a transaction runs
    signal ack              : std_logic;                                   -- last sampled slave ACK

    -- Reply bookkeeping (status taps; visible in simulation, trimmed by
    -- synthesis in the real build).
    signal reply_reg : std_logic_vector(7 downto 0) := (others => '0');    -- last received reply byte
    signal got_reply : std_logic := '0';                                   -- a reply byte was received

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

    -- Stimulus FSM: command phase (write 0xA8 + read the one-byte reply),
    -- reply check, and on a 0xAA match the confirm write (0xEE). Both request
    -- states follow the w/r handshake: w is raised while the bus is idle and
    -- dropped as soon as the master takes the request (busy = '1'). A NACKed
    -- or reply-less transaction re-issues the command, so with no slave on
    -- the bus the aborted command frame still streams continuously.
    stim : process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                stim_state       <= CFG_CMD;
                w                <= '0';
                data_to_transmit <= C_CMD_BYTE;
                n_write          <= "0001";
                n_read           <= "0001";
                reply_reg        <= (others => '0');
                got_reply        <= '0';
            else
                case stim_state is

                    -- Load the command-phase request: write the command byte,
                    -- then read one reply byte (repeated-START read-back).
                    when CFG_CMD =>
                        data_to_transmit <= C_CMD_BYTE;
                        n_write          <= "0001";
                        n_read           <= "0001";
                        got_reply        <= '0';
                        stim_state       <= CMD_REQ;

                    -- Raise the request; take it back once the master is busy.
                    when CMD_REQ =>
                        w <= '1';
                        if busy = '1' then
                            w          <= '0';
                            stim_state <= CMD_RUN;
                        end if;

                    -- Wait for the transaction to finish, latching the reply
                    -- byte when it lands (rx_valid pulses while busy is still
                    -- high, well before the closing STOP).
                    when CMD_RUN =>
                        if rx_valid = '1' then
                            reply_reg <= data_to_read;
                            got_reply <= '1';
                        end if;
                        if busy = '0' then
                            stim_state <= CHECK;
                        end if;

                    -- Reply gate: only a 0xAA reply starts the confirm write.
                    when CHECK =>
                        if got_reply = '1' and reply_reg = C_REPLY_BYTE then
                            stim_state <= CFG_WR;
                        else
                            stim_state <= CFG_CMD;   -- no valid reply yet: re-issue the command
                        end if;

                    -- Load the confirm-phase request: write 0xEE, no read.
                    when CFG_WR =>
                        data_to_transmit <= C_DATA_BYTE;
                        n_write          <= "0001";
                        n_read           <= "0000";
                        stim_state       <= WR_REQ;

                    when WR_REQ =>
                        w <= '1';
                        if busy = '1' then
                            w          <= '0';
                            stim_state <= WR_RUN;
                        end if;

                    -- Confirm write done: back to the command phase, so the
                    -- bus keeps streaming the command/reply/confirm sequence.
                    when WR_RUN =>
                        if busy = '0' then
                            stim_state <= CFG_CMD;
                        end if;

                end case;
            end if;
        end if;
    end process stim;

end architecture rtl;