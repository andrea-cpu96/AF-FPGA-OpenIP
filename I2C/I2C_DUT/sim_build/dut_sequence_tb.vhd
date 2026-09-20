-- dut_sequence_tb.vhd
-- Command/confirm sequence regression for the 4-pin I2C_DUT wrapper.
-- A behavioral open-drain slave model (address 0x3C, no hierarchical access
-- to DUT internals) answers the DUT stimulus:
--   * write data bytes are ACKed and logged (0xA8 command / 0xEE confirm);
--   * read bytes return 0x55 on the FIRST read, 0xAA afterwards -- so the
--     DUT must NOT write 0xEE until it has received a 0xAA reply, and the
--     expected bus stream is:
--       write 0xA8 -> read 0x55 -> write 0xA8 (retry) -> read 0xAA ->
--       write 0xEE (confirm)
-- Checks the command value, the retry after a wrong reply, the reply values
-- the DUT actually receives, and that the 0xEE write follows a 0xAA reply.
library ieee;
use ieee.std_logic_1164.all;

entity dut_sequence_tb is
end entity dut_sequence_tb;

architecture sim of dut_sequence_tb is

    constant C_ADDR : std_logic_vector(6 downto 0) := "0111100";  -- slave address 0x3C

    signal clk      : std_logic := '0';
    signal rst_n    : std_logic := '0';
    signal finished : boolean   := false;

    -- I2C bus with external pull-ups (testbench-side, wired-AND resolution)
    signal sda : std_logic := 'H';
    signal scl : std_logic := 'H';

    -- testbench-domain copies of the bus for clean 0/1 edge detection
    signal sda_obs : std_logic;
    signal scl_obs : std_logic;

    -- slave model drive: '1' = pull SDA low (open drain)
    signal slave_low : std_logic := '0';

    -- logged transactions: toggle event + stable payload
    signal wr_toggle : std_logic := '0';
    signal wr_byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal rd_toggle : std_logic := '0';
    signal rd_byte   : std_logic_vector(7 downto 0) := (others => '0');

    -- sequence counters
    signal cmd_cnt : natural := 0;   -- 0xA8 command writes seen
    signal ee_cnt  : natural := 0;   -- 0xEE confirm writes seen
    signal rd_cnt  : natural := 0;   -- read bytes served

begin

    clk <= not clk after 10 ns when not finished else '0';   -- 50 MHz

    sda <= 'H';
    scl <= 'H';
    sda <= '0' when slave_low = '1' else 'Z';

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

    -- reset release for the DUT
    stim : process
    begin
        rst_n <= '0';
        wait for 200 ns;
        rst_n <= '1';
        wait;
    end process;

    -- Behavioral open-drain slave: shifts bytes on the SCL rising edges,
    -- drives ACK / read data on SDA just after the closing SCL falling
    -- edges. Detects START (SDA falls while SCL is high), repeated START
    -- and STOP (SDA rises while SCL is high) to frame its own byte phases.
    slave : process
        variable shift  : std_logic_vector(7 downto 0);
        variable rw     : std_logic;
        variable got_sr : boolean;
        variable in_sr  : boolean := false;
        variable rd_idx : natural := 0;
        variable reply  : std_logic_vector(7 downto 0);

        -- Wait for the next SDA transition that happens while SCL is high:
        -- SDA falling = repeated START (true), SDA rising = STOP (false).
        -- SDA transitions while SCL is low (bit-cell boundaries) are skipped.
        procedure wait_framing(got_sr : out boolean) is
        begin
            got_sr := false;
            loop
                wait until sda_obs'event;
                if scl_obs = '1' then
                    got_sr := (sda_obs = '0');
                    exit;
                end if;
            end loop;
        end procedure;
    begin
        wait until rst_n = '1';
        main : loop
            -- Wait for a START condition; after a consumed repeated START
            -- the address phase follows immediately (in_sr set below).
            if not in_sr then
                wait until sda_obs = '0' and scl_obs = '1';
            end if;
            in_sr := false;

            -- address byte: 8 cells sampled on the SCL rising edges
            for i in 7 downto 0 loop
                wait until rising_edge(scl_obs);
                shift(i) := sda_obs;
            end loop;
            rw := shift(0);

            -- address ACK cell: drive low from the closing falling edge,
            -- release at the falling edge that ends the cell
            wait until falling_edge(scl_obs);
            if shift(7 downto 1) = C_ADDR then
                slave_low <= '1';
            end if;
            wait until rising_edge(scl_obs);
            wait until falling_edge(scl_obs);
            slave_low <= '0';

            if shift(7 downto 1) /= C_ADDR then
                -- other address: NACK, wait for the STOP, back to idle
                wait_framing(got_sr);
            elsif rw = '0' then
                -- write phase: single data bytes, ACKed and logged
                loop
                    for i in 7 downto 0 loop
                        wait until rising_edge(scl_obs);
                        shift(i) := sda_obs;
                    end loop;
                    wait until falling_edge(scl_obs);
                    slave_low <= '1';          -- ACK the data byte
                    wait until rising_edge(scl_obs);
                    wait until falling_edge(scl_obs);
                    slave_low <= '0';
                    wr_byte   <= shift;
                    wr_toggle <= not wr_toggle;
                    wait_framing(got_sr);
                    exit when not got_sr;      -- STOP: transaction over
                    in_sr := true;             -- repeated START: new address phase
                    exit;
                end loop;
            else
                -- read phase: drive the reply byte, then sample the
                -- master's ACK/NACK cell
                if rd_idx = 0 then
                    reply := x"55";            -- deliberately wrong first reply
                else
                    reply := x"AA";
                end if;
                rd_idx := rd_idx + 1;
                for i in 7 downto 0 loop
                    slave_low <= not reply(i);
                    wait until rising_edge(scl_obs);
                    if i > 0 then
                        wait until falling_edge(scl_obs);
                    end if;
                end loop;
                wait until falling_edge(scl_obs);
                slave_low <= '0';
                -- master ACK/NACK cell (the DUT reads exactly one byte ->
                -- NACK expected); log the served byte
                wait until rising_edge(scl_obs);
                assert sda_obs = '1'
                    report "FAIL: master ACKed the read byte, NACK expected for a 1-byte read"
                    severity error;
                rd_byte   <= reply;
                rd_toggle <= not rd_toggle;
                wait_framing(got_sr);
                if got_sr then
                    in_sr := true;
                end if;
            end if;
        end loop main;
    end process;

    -- Log the write bytes: count the 0xA8 commands and 0xEE confirms
    monitor_wr : process
    begin
        loop
            wait until wr_toggle'event;
            wait for 1 ns;
            assert wr_byte = x"A8" or wr_byte = x"EE"
                report "FAIL: unexpected write byte on the bus"
                severity error;
            if wr_byte = x"A8" then
                cmd_cnt <= cmd_cnt + 1;
            else
                ee_cnt <= ee_cnt + 1;
            end if;
        end loop;
    end process;

    -- Log the read bytes and check the reply sequence
    monitor_rd : process
    begin
        loop
            wait until rd_toggle'event;
            wait for 1 ns;
            if rd_cnt = 0 then
                assert rd_byte = x"55"
                    report "FAIL: first reply served should be the wrong value 0x55"
                    severity error;
            else
                assert rd_byte = x"AA"
                    report "FAIL: later replies served should be 0xAA"
                    severity error;
            end if;
            rd_cnt <= rd_cnt + 1;
        end loop;
    end process;

    -- Sequence check: command, wrong reply (no confirm!), retry, 0xAA
    -- reply, then the 0xEE confirm write.
    checker : process
        variable ok : boolean := true;
    begin
        wait until rst_n = '1';

        wait until cmd_cnt >= 1 for 2 ms;
        if cmd_cnt < 1 then
            ok := false;
            report "FAIL: no 0xA8 command transaction seen" severity error;
        end if;

        wait until rd_cnt >= 1 for 2 ms;
        if rd_cnt < 1 then
            ok := false;
            report "FAIL: no reply read back after the command" severity error;
        end if;

        -- the DUT must re-issue the command after the wrong reply...
        wait until cmd_cnt >= 2 for 2 ms;
        if cmd_cnt < 2 then
            ok := false;
            report "FAIL: command not re-issued after the wrong reply" severity error;
        end if;
        -- ...and must NOT write 0xEE before the 0xAA reply
        if ee_cnt /= 0 then
            ok := false;
            report "FAIL: 0xEE confirm written before a 0xAA reply" severity error;
        end if;

        wait until rd_cnt >= 2 for 2 ms;
        if rd_cnt < 2 then
            ok := false;
            report "FAIL: no second reply read back" severity error;
        end if;

        wait until ee_cnt >= 1 for 2 ms;
        if ee_cnt < 1 then
            ok := false;
            report "FAIL: no 0xEE confirm write after the 0xAA reply" severity error;
        elsif cmd_cnt /= 2 then
            ok := false;
            report "FAIL: unexpected command count before the confirm write" severity error;
        end if;

        if ok then
            report "RESULT: PASS -- command/reply/confirm sequence verified" severity note;
        else
            report "RESULT: FAIL" severity error;
        end if;
        finished <= true;
        wait;
    end process checker;

    watchdog : process
    begin
        wait for 8 ms;
        if not finished then
            report "FAIL: sequence test timed out" severity error;
        end if;
        wait;   -- 'finished' is owned by the checker; run ends the simulation
    end process watchdog;

end architecture sim;