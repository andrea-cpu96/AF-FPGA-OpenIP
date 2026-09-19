-- i2c_master_tb.vhd
-- Testbench for the write-transaction path of I2C_Master.
-- Stims a write to slave addr 0x68, data 0xA5; models a slave that
-- ACKs both bytes; checks the captured SDA waveform at SCL rising edges.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity i2c_master_tb is
end entity i2c_master_tb;

architecture sim of i2c_master_tb is

    constant C_CLK_FREQ : natural := 50_000_000;
    constant C_I2C_FREQ : natural := 100_000;

    signal clk            : std_logic := '0';
    signal rst_n          : std_logic := '0';
    signal w              : std_logic := '0';
    signal r              : std_logic := '0';
    signal addr           : std_logic_vector(6 downto 0) := "1101000";
    signal data_to_transmit : std_logic_vector(7 downto 0) := x"A5";

    -- I2C bus (open-drain, wired-AND via resolved std_logic)
    signal sda_bus : std_logic := 'H';
    signal scl_bus : std_logic := 'H';
    signal scl_obs : std_logic;

    -- Slave ACK model
    signal bit_count  : natural range 0 to 9 := 0;
    signal byte_count : natural range 0 to 2 := 0;
    signal start_seen : std_logic := '0';
    signal byte_started : std_logic := '0';
    signal ack_drive : std_logic := '0';

        -- SCL edge detection (testbench domain, registered)
    signal scl_prev_tb : std_logic := '1';

    -- Waveform capture: 18 bits at SCL rising edges
    type frame_a is array (0 to 17) of std_logic;
    signal frame_sda : frame_a := (others => '1');
    signal fi : natural range 0 to 18 := 0;

    -- Result file (relative to sim_i2c_master/, where sim_run.do runs)
    file results : text open write_mode is "results.txt";

begin

    -- 50 MHz clock
    clk_proc : process
    begin
        clk <= '0'; wait for 10 ns;
        clk <= '1'; wait for 10 ns;
    end process;

    -- DUT
    dut : entity work.I2C_Master
        generic map (G_CLK_FREQ => C_CLK_FREQ, G_I2C_FREQ => C_I2C_FREQ)
        port map (
            clk              => clk,
            rst_n            => rst_n,
            w                => w,
            r                => r,
            addr             => addr,
            data_to_transmit => data_to_transmit,
            data_to_read     => open,
            tx_done          => open,
            tx_data_done     => open,
            rx_valid         => open,
            busy             => open,
            ack              => open,
            sda              => sda_bus,
                scl              => scl_bus
        );

            -- External pull-up: the master only pulls SCL low or releases it.
            scl_bus <= 'H';
            scl_obs <= To_X01(scl_bus);

    ---------------------------------------------------------------------------
    -- SCL edge detector (testbench domain)
    ---------------------------------------------------------------------------
        -- SCL edge detector (registered in testbench clk domain)
    scl_ck : process(clk)
    begin
        if rising_edge(clk) then
            scl_prev_tb <= scl_obs;
        end if;
    end process scl_ck;

    -- External pull-up: the master and slave only pull SDA low or release it.
    sda_bus <= 'H';

    ---------------------------------------------------------------------------
    -- Slave ACK model: counts bits on SCL rising edges, ACKs on bit 9
    --   bit_count: 1..9 within each byte (9 = ACK slot)
    --   byte_count: 1 = address byte ACK, 2 = data byte ACK
    ---------------------------------------------------------------------------
    slave_ck : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                bit_count  <= 0;
                byte_count <= 0;
                start_seen <= '0';
                byte_started <= '0';
                ack_drive <= '0';
            elsif start_seen = '0' then
                if sda_bus = '0' and scl_obs = '1' then
                    start_seen <= '1';
                end if;
            elsif byte_started = '0' then
                if scl_obs = '0' and scl_prev_tb = '1' then
                    byte_started <= '1';
                end if;
            else
                if scl_obs = '1' and scl_prev_tb = '0' then
                    -- SCL rising edge
                    if bit_count < 9 then
                        bit_count <= bit_count + 1;
                    end if;
                elsif scl_obs = '0' and scl_prev_tb = '1' then
                    -- Assert ACK after the eight data bits; release it after
                    -- the ACK bit cell has completed.
                    if bit_count = 8 and byte_count < 2 then
                        ack_drive <= '1';
                    elsif bit_count = 9 then
                        ack_drive <= '0';
                        bit_count <= 0;
                        if byte_count < 2 then
                            byte_count <= byte_count + 1;
                        end if;
                    else
                        null;
                    end if;
                end if;
            end if;
        end if;
    end process slave_ck;

    -- Slave drives SDA low during ACK bit cell
        sda_bus <= '0' when ack_drive = '1' else 'Z';

    ---------------------------------------------------------------------------
    -- Waveform capture: sample sda_bus on SCL rising edges
    --   18 bit-cells: 9 address bits (A6..A0 + W) + 9 data bits (D7..D0 + ACK)
    ---------------------------------------------------------------------------
    cap_ck : process
    begin
        wait until rising_edge(scl_obs);
        wait for 1 ns;
        if rst_n = '0' then
            fi <= 0;
        elsif byte_started = '1' then
            if fi < 18 then
                frame_sda(fi) <= sda_bus;
                fi <= fi + 1;
            end if;
        end if;
    end process cap_ck;

    ---------------------------------------------------------------------------
    -- Debug: report every SCL rising edge with captured data
    ---------------------------------------------------------------------------
    debug : process(clk)
        variable L : line;
    begin
        if rising_edge(clk) then
            if rst_n = '1' and scl_obs = '1' and scl_prev_tb = '0' then
                write(L, string'("["));
                write(L, now, UNIT => ns);
                write(L, string'("ns] SCL_RISE fi="));
                write(L, fi);
                write(L, string'(" sda="));
                write(L, std_logic'image(sda_bus));
                write(L, string'(" bit_count="));
                write(L, bit_count);
                write(L, string'(" byte_count="));
                write(L, byte_count);
                writeline(results, L);
            end if;
        end if;
    end process debug;



    ---------------------------------------------------------------------------
    -- Stimulus + check
    ---------------------------------------------------------------------------
    stim : process
        variable L : line;
        variable got_str : string(1 to 18);
        variable ok : boolean := true;
    begin
        -- Reset
        rst_n <= '0';
        wait for 100 ns;
        rst_n <= '1';

        -- Issue write: addr=0x68 (1101000), data=0xA5 (10100101), W=0
        w <= '1';
        addr <= "1101000";
        data_to_transmit <= x"A5";
        wait until sda_bus = '0';
        w <= '0';

        -- Wait for 18 bit-cells captured (8 address + ACK + 8 data + ACK)
        wait until fi = 18 for 500 us;

        for i in 0 to 17 loop
            if frame_sda(i) = '0' then got_str(i+1) := '0';
            else got_str(i+1) := '1';
            end if;
        end loop;

        -- Report captured frame
        write(L, string'("Captured: "));
        for i in 1 to 18 loop
            write(L, got_str(i));
        end loop;
        writeline(results, L);

        -- addr=1101000, W=0 => bits 1..8 = "11010000"
        if got_str(1 to 8) /= "11010000" then
            ok := false;
            write(L, string'("FAIL: address frame wrong"));
            writeline(results, L);
        end if;

        -- ACK after address (slave drives low) => bit 9 = '0'
        if got_str(9) /= '0' then
            ok := false;
            write(L, string'("FAIL: address ACK missing"));
            writeline(results, L);
        end if;

        -- data=10100101 => bits 10..17 = "10100101"
        if got_str(10 to 17) /= "10100101" then
            ok := false;
            write(L, string'("FAIL: data frame wrong"));
            writeline(results, L);
        end if;

        -- ACK after data; the slave model drives this low as well.
        if got_str(18) /= '0' then
            ok := false;
            write(L, string'("FAIL: data ACK missing"));
            writeline(results, L);
        end if;

        if ok then
            write(L, string'("RESULT: PASS -- write transaction correct"));
        else
            write(L, string'("RESULT: FAIL"));
        end if;
        writeline(results, L);

        -- Console output
        if ok then
            report "RESULT: PASS -- write transaction correct" severity note;
        else
            report "RESULT: FAIL -- write transaction mismatch" severity error;
        end if;

        wait;
    end process stim;

end architecture sim;
