-- i2c_tx_tb.vhd
-- Testbench for the transmit path of the I2C_Master hierarchy.
-- I2C_TX serialises one byte MSB first and paces itself on the SCL falling
-- edges, exactly as the master FSM drives it: the byte is loaded on `send`
-- (its MSB is presented immediately), every following SCL falling edge
-- shifts one more bit out, and the falling edge after the last bit completes
-- the byte with byte_done -- which is where the ACK bit cell starts.
-- Checks, per byte:
--   * the MSB is out right after the load (no stale level, no gap)
--   * bit order MSB first: the serial bit sampled at the end of every low
--     phase (what a slave samples on the following rising edge) rebuilds
--     the byte
--   * exactly one shift per falling edge -- a stretched, longer low phase
--     must not shift again or corrupt the byte
--   * busy is high from the load until the byte's last falling edge
--   * byte_done pulses exactly once, on the 9th fall (ACK cell start) --
--     not one cell early -- and busy drops with it
--   * falling edges while idle (the ACK cell, further idle cells) shift
--     nothing and pulse nothing
--   * a second byte can be streamed right after byte_done

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity i2c_tx_tb is
end entity i2c_tx_tb;

architecture sim of i2c_tx_tb is

    constant C_CLK_PERIOD : time    := 20 ns;
    constant C_HALF       : natural := 10;   -- clks per SCL phase

    signal clk              : std_logic := '0';
    signal rst_n            : std_logic := '0';
    signal scl              : std_logic := '1';
    signal send             : std_logic := '0';
    signal data_to_transmit : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_bit           : std_logic;
    signal byte_done        : std_logic;
    signal busy             : std_logic;

    -- Read-only watcher: counts byte_done pulses (never drives anything).
    signal byte_done_seen : natural := 0;

    -- Snapshots taken by the stim process for the checks after each byte
    signal busy_load      : std_logic;  -- busy right after the load
    signal busy_before_9  : std_logic;  -- busy at the end of the last data cell

    file results : text open write_mode is "results.txt";

begin

    clk_proc : process
    begin
        clk <= '0'; wait for C_CLK_PERIOD / 2;
        clk <= '1'; wait for C_CLK_PERIOD / 2;
    end process;

    dut : entity work.I2C_TX
        port map (
            clk              => clk,
            rst_n            => rst_n,
            scl              => scl,
            send             => send,
            data_to_transmit => data_to_transmit,
            tx_bit           => tx_bit,
            byte_done        => byte_done,
            busy             => busy
        );

    watcher : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                byte_done_seen <= 0;
            elsif byte_done = '1' then
                byte_done_seen <= byte_done_seen + 1;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Stimulus. A single process drives every input, so the SCL waveform can
    -- never race with the edge detection inside I2C_TX.
    ---------------------------------------------------------------------------
    stim : process
        variable L   : line;
        variable ok  : boolean := true;
        variable got : std_logic_vector(7 downto 0);

        procedure clk_ticks (constant n : natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        -- One full SCL period while the serialiser is idle (an ACK cell or
        -- bus filler). I2C_TX must ignore these falling edges completely.
        procedure idle_cell is
        begin
            scl <= '0';
            clk_ticks(C_HALF);
            scl <= '1';
            clk_ticks(C_HALF);
        end procedure;

        -- Serialise one byte the way the master FSM drives I2C_TX: pulse
        -- `send`, then one SCL period per bit cell. The serial bit is
        -- sampled at the end of every low phase -- i.e. what a slave would
        -- latch on the following rising edge. stretch_cell (1..8) lengthens
        -- that bit cell's low phase by stretch_len clocks: a clock stretch
        -- must delay the pacing without shifting twice or corrupting the
        -- byte. busy_load / busy_before_9 snapshot the busy timing.
        procedure send_byte (
            constant b            : in  std_logic_vector(7 downto 0);
            constant stretch_cell : in  natural range 0 to 8 := 0;
            constant stretch_len  : in  natural := 0;
            variable captured     : out std_logic_vector(7 downto 0)) is
        begin
            data_to_transmit <= b;
            send <= '1';
            clk_ticks(1);
            send <= '0';
            clk_ticks(1);
            busy_load   <= busy;         -- must be high one clk after the load
            captured(7) := tx_bit;       -- MSB must already be out
            for i in 6 downto 0 loop     -- bit cells 2 .. 8
                scl <= '0';              -- falling edge: one shift expected
                if 8 - i = stretch_cell then
                    clk_ticks(C_HALF + stretch_len);
                else
                    clk_ticks(C_HALF);
                end if;
                captured(i) := tx_bit;   -- what the slave would sample
                scl <= '1';              -- rising edge: slave latches the bit
                clk_ticks(C_HALF);
            end loop;
            busy_before_9 <= busy;       -- still busy: byte_done belongs to the NEXT fall
            scl <= '0';                  -- 9th fall: byte_done pulse, no shift
            clk_ticks(C_HALF);
            scl <= '1';
            clk_ticks(C_HALF);
        end procedure;
        -- Per-byte checks. lsb is the byte's bit 0: the serialiser must keep
        -- it on the output (no further shift) through the ACK cell.
        procedure check_byte (
            constant b       : in std_logic_vector(7 downto 0);
            constant tag     : in string;
            constant done_no : in natural;
            constant lsb     : in std_logic) is
        begin
            if got /= b then
                ok := false;
                write(L, string'("FAIL: " & tag & " serialised as "));
                write(L, to_bitvector(got));
                write(L, string'(", expected "));
                write(L, to_bitvector(b));
                writeline(results, L);
            end if;
            if byte_done_seen /= done_no then
                ok := false;
                write(L, string'("FAIL: " & tag & " byte_done count = "));
                write(L, byte_done_seen);
                write(L, string'(", expected "));
                write(L, done_no);
                writeline(results, L);
            end if;
            if busy_load /= '1' then
                ok := false;
                write(L, string'("FAIL: " & tag & " busy not high right after the load"));
                writeline(results, L);
            end if;
            if busy_before_9 /= '1' then
                ok := false;
                write(L, string'("FAIL: " & tag & " busy dropped before the 9th fall (early byte_done)"));
                writeline(results, L);
            end if;
            if busy /= '0' then
                ok := false;
                write(L, string'("FAIL: " & tag & " busy still high after byte_done"));
                writeline(results, L);
            end if;
            if tx_bit /= lsb then
                ok := false;
                write(L, string'("FAIL: " & tag & " serial output changed during/after the ACK cell"));
                writeline(results, L);
            end if;
        end procedure;
    begin
        -- Reset
        rst_n <= '0';
        scl   <= '1';
        send  <= '0';
        clk_ticks(5);
        rst_n <= '1';
        clk_ticks(5);

        -- Byte 1: 0xA5, plain run (MSB first: 1,0,1,0,0,1,0,1)
        send_byte(x"A5", 0, 0, got);
        check_byte(x"A5", "byte 1 (A5)", 1, '1');

        -- Falling edges while idle (ACK cell + one filler cell) must not
        -- shift anything nor pulse byte_done again.
        idle_cell;
        idle_cell;
        if byte_done_seen /= 1 or busy /= '0' or tx_bit /= '1' then
            ok := false;
            write(L, string'("FAIL: idle cells disturbed the serialiser after byte 1"));
            writeline(results, L);
        end if;

        -- Byte 2: 0x3C with a stretched low phase in bit cell 5 (bit 3).
        -- MSB = 0: the output must go low right after the load, which
        -- catches a stale '1' left over from the previous byte.
        send_byte(x"3C", 5, 15, got);
        check_byte(x"3C", "byte 2 (3C, stretched cell 5)", 2, '0');

        -- Byte 3: 0x81 streamed back to back, right after the previous
        -- byte_done: the load must restart the bit counter cleanly.
        send_byte(x"81", 0, 0, got);
        check_byte(x"81", "byte 3 (81, back to back)", 3, '1');

        -- Summary
        if ok then
            write(L, string'("RESULT: PASS -- TX rebuilt A5, 3C (stretched) and 81, MSB first"));
        else
            write(L, string'("RESULT: FAIL -- see the FAIL lines above"));
        end if;
        writeline(results, L);
        if ok then
            report "RESULT: PASS -- TX rebuilt A5, 3C (stretched) and 81, MSB first" severity note;
        else
            report "RESULT: FAIL -- see results.txt" severity error;
        end if;
        wait;
    end process stim;

end architecture sim;
