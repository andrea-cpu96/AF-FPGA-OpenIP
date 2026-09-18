-- i2c_master_stretch_tb.vhd
-- Clock-stretching regression for I2C_Master. The slave model holds SCL low
-- through the address-ACK cell plus a fixed stretch window, then releases it;
-- the master must wait for the real bus edge before sampling the ACK and
-- clocking the data byte. Checks:
--   * the master never raises SCL while the slave holds it low
--   * the stretched ACK is still sampled correctly
--   * the data byte arrives intact on the public data_to_read output
--   * SCL and SDA are released (idle high) once the FSM is back at IDLE
library ieee;
use ieee.std_logic_1164.all;

entity i2c_master_stretch_tb is
end entity i2c_master_stretch_tb;

architecture sim of i2c_master_stretch_tb is
    constant C_ADDR   : std_logic_vector(6 downto 0) := "1010001";
    constant C_DATA   : std_logic_vector(7 downto 0) := x"2D";  -- non-palindromic
    constant C_SETTLE : time := 200 ns;

    signal clk          : std_logic := '0';
    signal rst_n        : std_logic := '0';
    signal r            : std_logic := '0';
    signal scl_bus      : std_logic;
    signal sda_bus      : std_logic;
    signal sda_low      : std_logic := '0';   -- slave pulls SDA low
    signal scl_stretch  : std_logic := '0';   -- slave holds SCL low
    signal data_to_read : std_logic_vector(7 downto 0);
    signal finished     : boolean := false;
begin
    clk <= not clk after 10 ns when not finished else '0';

    -- open-drain bus with external pull-ups: the slave only ever pulls low
    sda_bus <= 'H';
    scl_bus <= 'H';
    sda_bus <= '0' when sda_low = '1' else 'Z';
    scl_bus <= '0' when scl_stretch = '1' else 'Z';

    dut : entity work.I2C_Master
        generic map (G_CLK_FREQ => 50_000_000, G_I2C_FREQ => 100_000)
        port map (
            clk => clk, rst_n => rst_n, w => '0', r => r,
            addr => C_ADDR, data_to_transmit => x"00",
            n_write => "0000", n_read => "0001",
            data_to_read => data_to_read, sda => sda_bus, scl => scl_bus,
            tx_done => open, rx_valid => open,
            busy => open, ack => open
        );

    -- Slave: ACKs the address while stretching SCL, then sends one data byte.
    slave : process
    begin
        wait until falling_edge(sda_bus);            -- START (SCL high)
        for i in 1 to 8 loop
            wait until rising_edge(scl_bus);         -- 8 address bit cells
        end loop;
        wait until falling_edge(scl_bus);            -- ACK cell begins
        sda_low     <= '1';                          -- ACK ...
        scl_stretch <= '1';                          -- ... with SCL held low
        for i in 1 to 200 loop                       -- >= 2 us of checked stretch
            wait until rising_edge(clk);
            assert scl_bus = '0'
                report "Master raised SCL while slave was stretching" severity failure;
        end loop;
        scl_stretch <= '0';                          -- release: the bus rises now
        wait until rising_edge(scl_bus);             -- stretched rise: ACK sample
        assert To_X01(sda_bus) = '0'
            report "ACK lost across the stretch" severity failure;
        wait until falling_edge(scl_bus);            -- ACK cell ends
        sda_low <= '0';                              -- release SDA for the data byte
        for i in 7 downto 0 loop
            wait for C_SETTLE;
            sda_low <= not C_DATA(i);
            wait until rising_edge(scl_bus);
            assert To_X01(sda_bus) = C_DATA(i)
                report "Data bit corrupted on the bus" severity failure;
            wait until falling_edge(scl_bus);
        end loop;
        sda_low <= '0';
        wait;   -- master ACK + return to IDLE are checked by the stim process
    end process;

    stim : process
    begin
        wait for 100 ns;
        assert data_to_read = x"00"
            report "Read output not zero during reset" severity failure;
        rst_n <= '1';
        r <= '1';
        wait until falling_edge(sda_bus);            -- START accepted
        r <= '0';
        -- the byte may only appear on the public output once complete
        wait until (data_to_read = C_DATA) for 300 us;
        assert data_to_read = C_DATA
            report "Stretched transaction did not deliver the byte" severity failure;
        -- Single read byte = last byte: the master must NACK it (SDA stays
        -- released through the ACK cell), which is what lets the slave stop
        -- driving the line before the STOP.
        wait until falling_edge(scl_bus) for 100 us;   -- data cell ends
        wait for C_SETTLE;
        assert To_X01(sda_bus) = '1'
            report "Master did not NACK the last (only) read byte" severity failure;
        -- back at IDLE: SCL gated off, both lines released high
        wait for 30 us;
        assert scl_bus = 'H' and sda_bus = 'H'
            report "Bus not released after the transaction" severity failure;
        report "RESULT: PASS -- clock stretching tolerated, byte 2D received" severity note;
        finished <= true;
        wait;
    end process;

    watchdog : process
    begin
        wait for 1 ms;
        assert finished report "Stretch test timed out" severity failure;
        wait;
    end process;
end architecture sim;
