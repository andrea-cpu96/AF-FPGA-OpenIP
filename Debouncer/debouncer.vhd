-- debouncer.vhd
-- Debouncer for noisy digital inputs (switches, push-buttons, relays...).
-- Each input bit passes through a two-flip-flop synchronizer (metastability
-- protection) followed by a stability filter: the bit must keep the same
-- value for G_DEBOUNCE_CYCLES consecutive clk cycles before the debounced
-- output changes. Shorter glitches of any width are rejected.
-- Every bit has its own filter, so independent inputs do not interfere.
-- Reusable, project-independent module.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debouncer is
    generic (
        G_WIDTH           : natural range 1 to natural'high := 1;  -- input bit count
        G_DEBOUNCE_CYCLES : natural range 2 to natural'high := 1000 -- stability window, clk cycles
    );
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        noisy_in  : in  std_logic_vector(G_WIDTH - 1 downto 0);
        clean_out : out std_logic_vector(G_WIDTH - 1 downto 0)
    );
end entity debouncer;

architecture rtl of debouncer is

    -- One stability counter per bit: counts how long the synchronized bit has
    -- differed from the debounced state. Reaches G_DEBOUNCE_CYCLES - 1 only
    -- if the bit stayed stable for the whole window.
    type t_counter_array is array (natural range <>) of
        natural range 0 to G_DEBOUNCE_CYCLES - 1;

    signal sync_a : std_logic_vector(G_WIDTH - 1 downto 0) := (others => '0'); -- 1st synchronizer stage
    signal sync_b : std_logic_vector(G_WIDTH - 1 downto 0) := (others => '0'); -- 2nd synchronizer stage
    signal state_r  : std_logic_vector(G_WIDTH - 1 downto 0) := (others => '0'); -- debounced state
    signal counter  : t_counter_array(G_WIDTH - 1 downto 0) := (others => 0);

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                sync_a   <= (others => '0');
                sync_b   <= (others => '0');
                state_r  <= (others => '0');
                counter  <= (others => 0);
            else
                sync_a <= noisy_in;
                sync_b <= sync_a;

                for i in sync_b'range loop
                    if sync_b(i) /= state_r(i) then
                        -- Bit differs from the debounced state: count up
                        -- while it stays stable, adopt it after the window,
                        -- restart counting if it bounces.
                        if counter(i) = G_DEBOUNCE_CYCLES - 1 then
                            state_r(i) <= sync_b(i);
                            counter(i) <= 0;
                        else
                            counter(i) <= counter(i) + 1;
                        end if;
                    else
                        counter(i) <= 0;
                    end if;
                end loop;
            end if;
        end if;
    end process;

    clean_out <= state_r;

end architecture rtl;
