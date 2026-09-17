-- Public read-data output regression. Models an open-drain slave, with no
-- hierarchical access to DUT internals. Bus STOP/idle timing is not tested here.
library ieee;
use ieee.std_logic_1164.all;

entity i2c_master_read_tb is
end entity i2c_master_read_tb;

architecture sim of i2c_master_read_tb is
    constant C_ADDR : std_logic_vector(6 downto 0) := "1010001";
    constant C_SETTLE : time := 200 ns;
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal r : std_logic := '0';
    signal sda_bus : std_logic;
    signal scl_bus : std_logic;
    signal slave_low : std_logic := '0';
    signal data_to_read : std_logic_vector(7 downto 0);
    signal finished : boolean := false;
begin
    clk <= not clk after 10 ns when not finished else '0';
    sda_bus <= 'H';
    scl_bus <= 'H';
    sda_bus <= '0' when slave_low = '1' else 'Z';

    dut : entity work.I2C_Master
        generic map (G_CLK_FREQ => 50_000_000, G_I2C_FREQ => 100_000)
        port map (
            clk => clk, rst_n => rst_n, w => '0', r => r,
            addr => C_ADDR, data_to_transmit => x"00",
            data_to_read => data_to_read, sda => sda_bus, scl => scl_bus
        );

    stim : process
        procedure read_byte(
            constant value : in std_logic_vector(7 downto 0);
            constant previous : in std_logic_vector(7 downto 0)
        ) is
            variable address_byte : std_logic_vector(7 downto 0);
        begin
            r <= '1';
            wait until falling_edge(sda_bus);
            assert To_X01(scl_bus) = '1'
                report "Read START did not occur while SCL was high" severity failure;
            r <= '0';
            for i in 7 downto 0 loop
                wait until rising_edge(scl_bus);
                address_byte(i) := To_X01(sda_bus);
                assert data_to_read = previous
                    report "Output changed during address transfer" severity failure;
            end loop;
            assert address_byte = (C_ADDR & '1')
                report "Incorrect read address / direction" severity failure;

            wait until falling_edge(scl_bus);
            wait for C_SETTLE;
            slave_low <= '1'; -- slave address ACK
            wait until rising_edge(scl_bus);
            wait until falling_edge(scl_bus);

            for i in 7 downto 0 loop
                wait for C_SETTLE;
                slave_low <= not value(i);
                wait until rising_edge(scl_bus);
                assert To_X01(sda_bus) = value(i)
                    report "Read data bit corrupted on bus" severity failure;
                assert data_to_read = previous
                    report "Partial byte leaked to public output" severity failure;
                wait for C_SETTLE; -- allow synchroniser, RX and latch to settle
                if i = 0 then
                    assert data_to_read = value
                        report "Completed read byte incorrect on public output" severity failure;
                else
                    assert data_to_read = previous
                        report "Public output updated before byte completion" severity failure;
                end if;
                wait until falling_edge(scl_bus);
            end loop;
            slave_low <= '0';
            wait until rising_edge(scl_bus); -- master's acknowledgement cell
            wait for C_SETTLE;
            assert data_to_read = value
                report "Acknowledgement cell corrupted received byte" severity failure;
            wait until falling_edge(scl_bus);
            -- Allow the existing FSM to finish, without assuming a valid STOP.
            for i in 1 to 1500 loop
                wait until rising_edge(clk);
                assert data_to_read = value
                    report "Completed byte not held between reads" severity failure;
            end loop;
        end procedure;
    begin
        wait for 100 ns;
        assert data_to_read = x"00"
            report "Read output not zero during reset" severity failure;
        rst_n <= '1';
        read_byte(x"65", x"00");
        read_byte(x"96", x"65");
        rst_n <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert data_to_read = x"00"
            report "Reset did not clear previously received byte" severity failure;
        report "RESULT: PASS -- public read output: 65, 96, hold and reset" severity note;
        finished <= true;
        wait;
    end process;

    watchdog : process
    begin
        wait for 1 ms;
        assert finished report "Read test timed out" severity failure;
        wait;
    end process;
end architecture sim;
