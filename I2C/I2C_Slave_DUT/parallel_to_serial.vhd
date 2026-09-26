-- parallel_to_serial.vhd
-- Parallel-to-Serial Converter (P2S): shifts an N-bit byte out one bit per
-- shift pulse. Bit order is selectable: LSB-first (default, UART) or
-- MSB-first (I2C). Reusable, project-independent module.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity parallel_to_serial is
    generic (
        G_DATA_WIDTH : positive := 8;
        G_MSB_FIRST  : boolean  := false -- false: LSB-first (UART), true: MSB-first (I2C)
    );
    port (
        clk : in  std_logic;
        rst_n : in  std_logic;
        shift : in  std_logic;
        load : in  std_logic;
        data_in : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
        data_out : out std_logic
    );
end entity parallel_to_serial;

architecture rtl of parallel_to_serial is
    signal data_in_load : std_logic_vector(G_DATA_WIDTH - 1 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                data_in_load <= (others => '0');
            elsif load = '1' then
                data_in_load <= data_in;
            elsif shift = '1' then
                if G_MSB_FIRST then
                    -- MSB first: shift left, '0' in at LSB
                    data_in_load <= data_in_load(G_DATA_WIDTH - 2 downto 0) & '0';
                else
                    -- LSB first: shift right, '0' in at MSB
                    data_in_load <= '0' & data_in_load(G_DATA_WIDTH - 1 downto 1);
                end if;
            end if;
        end if;
    end process;

    data_out <= data_in_load(G_DATA_WIDTH - 1) when G_MSB_FIRST
                else data_in_load(0);

end architecture rtl;