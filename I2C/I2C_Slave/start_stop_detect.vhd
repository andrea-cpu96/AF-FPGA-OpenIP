-- start_stop_detect.vhd
-- I2C START / repeated-START / STOP condition detector, for the bus-monitor
-- side of an I2C link (a slave, or a master that wants to watch the bus).
--
--   START (and repeated START): SDA falls while SCL is high
--   STOP                      : SDA rises while SCL is high
--
-- The condition is what an I2C transmitter can never do on its own: data bits
-- only ever change while SCL is LOW, so an SDA transition sampled while SCL is
-- high is framing, not data.
-- Inputs are expected to be the ALREADY SYNCHRONISED bus levels (see sync_2ff),
-- never the raw pins: the sampling registers here add one more stage of
-- history, they are not a synchroniser.
-- Filtering rule: SCL must be seen high on two consecutive clk samples around
-- the SDA transition, so a bus release/rise that happens while SCL is still
-- low (the normal data handover) can never be mistaken for a condition.
-- Both outputs are FF-driven, one-clk-wide pulses. Reusable, project
-- independent module (I2C/UART-style "hold" style detector).

library ieee;
use ieee.std_logic_1164.all;

entity start_stop_detect is
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        scl       : in  std_logic;   -- synchronised SCL bus level ('1' = high)
        sda       : in  std_logic;   -- synchronised SDA bus level ('1' = released/high)
        start_det : out std_logic;   -- one-clk pulse: SDA fell while SCL was high
        stop_det  : out std_logic    -- one-clk pulse: SDA rose while SCL was high
    );
end entity start_stop_detect;

architecture rtl of start_stop_detect is

    -- One-clk history of both lines ("previous" sample of the bus).
    signal scl_d : std_logic := '1';
    signal sda_d : std_logic := '1';

    -- Combinational condition decode from the current/previous samples.
    signal sda_fall : std_logic;
    signal sda_rise : std_logic;

    -- Registered outputs (module outputs are FF-driven: glitch free).
    signal start_reg : std_logic := '0';
    signal stop_reg  : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                scl_d <= '1';
                sda_d <= '1';
            else
                scl_d <= scl;
                sda_d <= sda;
            end if;
        end if;
    end process;

    -- SCL high on both samples + a distinct SDA transition = a bus condition.
    -- `sda_fall`/`sda_rise` are mutually exclusive by construction.
    sda_fall <= '1' when scl = '1' and scl_d = '1'
                         and sda = '0' and sda_d = '1' else '0';
    sda_rise <= '1' when scl = '1' and scl_d = '1'
                         and sda = '1' and sda_d = '0' else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                start_reg <= '0';
                stop_reg  <= '0';
            else
                start_reg <= sda_fall;
                stop_reg  <= sda_rise;
            end if;
        end if;
    end process;

    start_det <= start_reg;
    stop_det  <= stop_reg;

end architecture rtl;
