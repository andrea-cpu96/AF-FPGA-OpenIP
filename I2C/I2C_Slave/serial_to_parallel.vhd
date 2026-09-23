library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Bit order is selectable, mirroring parallel_to_serial:
--   G_MSB_FIRST = false : LSB-first input (UART). The first bit received lands
--                         in position 0, so after G_DATA_WIDTH shifts the
--                         original word is rebuilt.
--   G_MSB_FIRST = true  : MSB-first input (I2C). The first bit received lands
--                         in position G_DATA_WIDTH-1, so the byte also comes
--                         out in the order it was sent. Without this the I2C
--                         byte would come out bit-reversed.
entity serial_to_parallel is
    generic (
        G_DATA_WIDTH : positive := 8;
        G_MSB_FIRST  : boolean  := false -- false: LSB-first (UART), true: MSB-first (I2C)
    );
    port (
        clk : in  std_logic;
        rst_n : in  std_logic;
        shift : in  std_logic;
        data_in : in  std_logic;
        data_out : out std_logic_vector(G_DATA_WIDTH - 1 downto 0)
    );
end entity serial_to_parallel;

architecture rtl of serial_to_parallel is

    signal q : std_logic_vector(G_DATA_WIDTH - 1 downto 0);

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                q <= (others => '0');
            elsif shift = '1' then
                if G_MSB_FIRST then
                    -- MSB first (I2C): shift left so the newest bit enters at the
                    -- LSB and the FIRST bit received ends up in the MSB.
                    q <= q(G_DATA_WIDTH - 2 downto 0) & data_in;
                else
                    -- LSB first (UART): the first received bit lands in position
                    -- 0; after G_DATA_WIDTH shifts the original word is rebuilt.
                    q <= data_in & q(G_DATA_WIDTH - 1 downto 1);
                end if;
            end if;
        end if;
    end process;
    
    data_out <= q;
end architecture rtl;