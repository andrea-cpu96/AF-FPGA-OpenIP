-- sync_2ff.vhd
-- Two-flip-flop synchronizer: resynchronizes a single-bit asynchronous
-- level (or a signal from a foreign clock domain) into the clk domain.
-- The first flip-flop may go metastable when async_in violates clk setup/
-- hold; the second flip-flop gives the downstream logic a clean, settled
-- sample. Constant 2-cycle detection latency. Reusable, project-independent
-- module.
--
-- NOTE: deliberately NO reset — resetting the synchronizer chain is not
-- required for correctness (the chain settles within 2 clocks) and the
-- template keeps the FF pair minimal. The chain powers up at '0'.

library ieee;
use ieee.std_logic_1164.all;

entity sync_2ff is
    port (
        clk      : in  std_logic;   -- destination clock domain
        async_in : in  std_logic;   -- asynchronous (or foreign-domain) level
        sync_out : out std_logic    -- synchronized level, 2 clk latency
    );
end entity sync_2ff;

architecture rtl of sync_2ff is

    signal sync : std_logic_vector(1 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            sync <= sync(0) & async_in;   -- metastability settles by the 2nd FF
        end if;
    end process;

    sync_out <= sync(1);

end architecture rtl;
