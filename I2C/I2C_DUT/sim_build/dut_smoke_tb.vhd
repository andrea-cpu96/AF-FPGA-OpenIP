-- dut_smoke_tb.vhd
-- Smoke test for the 4-pin I2C_DUT wrapper (clk, rst_n, sda, scl only).
-- The DUT generates its own stimulus internally, so the testbench just
-- watches the bus. There is NO slave on the bus, so the address is NACKed
-- and the master must abort the transfer (I2C: no data phase after an
-- address NACK). The expected frame is therefore:
--   START, address byte + W, NACK slot (line pulled up), one SCL cell with
--   SDA held low (the STOP framing after the abort), STOP condition.
-- Checks:
--   * the START condition appears (SDA falls while SCL is high)
--   * the 10 bit cells of the aborted frame, sampled on the SCL rising
--     edges: address byte 01111000, NACK slot '1', STOP-framing cell '0'
--   * the STOP condition (SDA rises while SCL is high)
--   * tBUF: the wrapper re-issues a transaction immediately, so the next
--     START must respect the bus-free time (4.7 us) after the STOP

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dut_smoke_tb is
end entity dut_smoke_tb;

architecture sim of dut_smoke_tb is

    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';

    -- I2C bus with external pull-ups (testbench-side, wired-AND resolution)
    signal sda : std_logic := 'H';
    signal scl : std_logic := 'H';

    -- testbench-domain copies of the bus for clean 0/1 edge detection
    signal sda_obs : std_logic;
    signal scl_obs : std_logic;

    -- frame capture: SDA sampled on the SCL rising edges of the aborted
    -- transaction (8 address cells + NACK slot + STOP-framing cell)
    signal frame : std_logic_vector(1 to 10) := (others => '1');

begin

    clk <= not clk after 10 ns;   -- 50 MHz

    sda <= 'H';
    scl <= 'H';

    dut : entity work.I2C_DUT
        generic map (G_CLK_FREQ => 50_000_000, G_I2C_FREQ => 100_000)
        port map (
            clk   => clk,
            rst_n => rst_n,
            sda   => sda,
            scl   => scl
        );

    sda_obs <= To_X01(sda);
    scl_obs <= To_X01(scl);

    stim : process
        variable ok      : boolean := true;
        variable got_str : string(1 to 10);
        variable stop_t  : time := 0 ns;
    begin
        rst_n <= '0';
        wait for 200 ns;
        rst_n <= '1';

        -- START condition: SDA falls while SCL is high
        wait until sda_obs = '0' and scl_obs = '1' for 100 us;
        if not (sda_obs = '0' and scl_obs = '1') then
            report "FAIL: no START condition seen on the bus" severity error;
            ok := false;
        else
            report "OK: START condition seen" severity note;
        end if;

        -- capture the 10 SCL rising edges of the aborted frame: the 8
        -- address cells, the NACK slot and the STOP-framing cell (SDA held
        -- low while SCL runs one more pulse before the STOP)
        for i in 1 to 10 loop
            wait until scl_obs = '0' for 100 us;
            wait until scl_obs = '1' for 100 us;
            frame(i) <= To_X01(sda);
        end loop;

        -- STOP condition: SDA rises while SCL is high
        wait until sda_obs = '1' and scl_obs = '1' for 200 us;
        if not (sda_obs = '1' and scl_obs = '1') then
            report "FAIL: no STOP condition seen on the bus" severity error;
            ok := false;
        else
            stop_t := now;
            report "OK: STOP condition seen -- aborted frame correctly framed" severity note;
        end if;

        for i in 1 to 10 loop
            if frame(i) = '0' then
                got_str(i) := '0';
            else
                got_str(i) := '1';
            end if;
        end loop;
        report "Captured frame: " & got_str severity note;

        -- address 0x3C with W = 0
        if frame(1 to 8) /= "01111000" then
            report "FAIL: address byte wrong (expected 01111000)" severity error;
            ok := false;
        end if;
        -- no slave on the bus: the address slot must read NACK ...
        if frame(9) /= '1' then
            report "FAIL: address ACK slot expected '1' (NACK, no slave on the bus)" severity error;
            ok := false;
        end if;
        -- ... and the master must then abort: no data byte, SDA held low
        -- through the STOP-framing cell
        if frame(10) /= '0' then
            report "FAIL: SDA not held low in the STOP-framing cell after the address NACK" severity error;
            ok := false;
        end if;

        -- tBUF: the wrapper re-issues immediately, so the next START (SDA
        -- fall while SCL is released high) must respect the bus-free time
        -- of 4.7 us after the STOP edge
        wait until sda_obs = '0' and scl_obs = '1' for 100 us;
        if sda_obs = '0' and scl_obs = '1' then
            if (now - stop_t) < 4700 ns then
                report "FAIL: next START violates tBUF (bus-free time)" severity error;
                ok := false;
            else
                report "OK: next START respected tBUF after the STOP" severity note;
            end if;
        else
            report "FAIL: no further transaction after the STOP" severity error;
            ok := false;
        end if;

        if ok then
            report "RESULT: PASS -- 4-pin I2C_DUT emits a correct write frame" severity note;
        else
            report "RESULT: FAIL" severity error;
        end if;

        wait;
    end process stim;

end architecture sim;