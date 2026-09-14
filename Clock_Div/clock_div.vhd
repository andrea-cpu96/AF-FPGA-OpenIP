-- clock_div.vhd
-- Configurable clock divider: generates a square-wave clock at clk/G_DIVIDER.
-- The enable input gates the divider: while low, the output is held low and
-- the counter is parked at 0, so the output phase restarts deterministically
-- on the first enabled period. Reusable, project-independent module.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_div is
    generic (
        G_DIVIDER : natural range 2 to natural'high := 4  -- clk_out = clk / G_DIVIDER
    );
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        enable  : in  std_logic;
        clk_out : out std_logic
    );
end entity clock_div;

architecture rtl of clock_div is

    -- Length of the high phase. Ceil(G_DIVIDER/2) keeps the period exact for
    -- odd dividers too (duty cycle (G_DIVIDER+1)/2 : G_DIVIDER/2).
    constant C_HIGH_CYCLES : natural := (G_DIVIDER + 1) / 2;

    signal counter   : natural range 0 to G_DIVIDER - 1 := 0;
    signal clk_out_r : std_logic := '0';    -- registered output: glitch-free

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                counter   <= 0;
                clk_out_r <= '0';
            elsif enable = '0' then
                counter   <= 0;
                clk_out_r <= '0';
            else
                if counter = G_DIVIDER - 1 then
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;

                -- The two toggle points can never coincide for G_DIVIDER >= 2
                -- (that would need G_DIVIDER = 1), so the assignment below is
                -- race-free.
                if counter = G_DIVIDER - 1 then
                    clk_out_r <= '1';               -- start of a new period
                elsif counter = C_HIGH_CYCLES - 1 then
                    clk_out_r <= '0';               -- end of the high phase
                end if;
            end if;
        end if;
    end process;

    clk_out <= clk_out_r;

end architecture rtl;