-- scl_stretch.vhd
-- Programmable clock-stretch generator: holds a clock line LOW for a fixed
-- number of clk cycles after a trigger pulse, then releases it.
--
-- Built for the I2C clock-stretching feature on the target (slave) side: the
-- target pulls SCL low during the low phase of a bit cell to insert wait
-- states, and the controller's clock generator simply cannot end that low
-- phase before the release -- both sides only ever pull the line down, so
-- there is never a fight on the wire.
--
-- Open-drain by construction: `scl_low` is a pull-down REQUEST (drive '0') and
-- never a drive-high, so it can be combined with any other open-drain driver
-- on the same wire.
--
--   stretch = one-clk pulse  ->  scl_low rises for exactly G_STRETCH_CYCLES
--                                clk cycles, then falls again
--   G_STRETCH_CYCLES = 0     ->  the whole feature is compiled out: scl_low
--                                stays '0' and a pulse is ignored
-- A pulse arriving while a hold is already running is ignored (the hold is NOT
-- restarted), so every low phase the generator produces has the same, exactly
-- measurable length.
-- Reusable, project-independent module.

library ieee;
use ieee.std_logic_1164.all;

entity scl_stretch is
    generic (
        G_STRETCH_CYCLES : natural := 500   -- clk cycles SCL is held low (0 = feature off)
    );
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        stretch : in  std_logic;   -- one-clk pulse: begin a hold
        scl_low : out std_logic;   -- '1': pull the clock line low (open-drain request)
        active  : out std_logic    -- '1' while the hold is running (status)
    );
end entity scl_stretch;

architecture rtl of scl_stretch is

    -- Last counter value of a hold, guarded so G_STRETCH_CYCLES = 0 can never
    -- reach a G_STRETCH_CYCLES - 1 underflow.
    function last_cycle(stretch_cycles : natural) return natural is
    begin
        if stretch_cycles = 0 then
            return 0;
        end if;
        return stretch_cycles - 1;
    end function;

    constant C_LAST : natural := last_cycle(G_STRETCH_CYCLES);

    signal active_r : std_logic := '0';                    -- registered request
    signal count    : natural range 0 to C_LAST := 0;

begin

    -- Hold generator. Idle: waiting for a trigger. Running: count the hold out
    -- and drop the request on the last cycle, so `scl_low` is high for exactly
    -- G_STRETCH_CYCLES clk periods (count = 0 .. C_LAST).
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                active_r <= '0';
                count    <= 0;
            elsif active_r = '0' then
                if stretch = '1' and G_STRETCH_CYCLES > 0 then
                    active_r <= '1';
                    count    <= 0;
                end if;
            elsif count = C_LAST then
                active_r <= '0';
                count    <= 0;
            else
                count <= count + 1;
            end if;
        end if;
    end process;

    scl_low <= active_r;
    active  <= active_r;

end architecture rtl;
