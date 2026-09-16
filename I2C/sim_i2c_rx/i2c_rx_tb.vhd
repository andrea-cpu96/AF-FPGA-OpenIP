-- i2c_rx_tb.vhd
-- Testbench for the receive path of the I2C_Master hierarchy.
-- Models the slave side of a read: data is presented while SCL is low and is
-- valid on the SCL rising edge, which is the edge I2C_RX samples.
-- Checks: the byte is rebuilt MSB first, byte_done pulses once per byte, the
-- block re-arms for a second byte, and the ACK bit cell that follows a byte
-- is ignored (busy-low, so no shift).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity i2c_rx_tb is
end entity i2c_rx_tb;

architecture sim of i2c_rx_tb is

    constant C_CLK_PERIOD : time    := 20 ns;
    constant C_HALF       : natural := 10;   -- clks per SCL phase

    signal clk           : std_logic := '0';
    signal rst_n         : std_logic := '0';
    signal scl           : std_logic := '1';
    signal receive       : std_logic := '0';
    signal sda_in        : std_logic := '1';
    signal data_received : std_logic_vector(7 downto 0);
    signal byte_done     : std_logic;
    signal busy          : std_logic;

    -- Read-only watcher: counts byte_done pulses (never drives anything).
    signal byte_done_seen : natural := 0;

    file results : text open write_mode is
        "C:/Andrea/Eng/fpga_projects/AF-FPGA-OpenIP/I2C/sim_i2c_rx/results.txt";

begin

    clk_proc : process
    begin
        clk <= '0'; wait for C_CLK_PERIOD / 2;
        clk <= '1'; wait for C_CLK_PERIOD / 2;
    end process;

    dut : entity work.I2C_RX
        port map (
            clk           => clk,
            rst_n         => rst_n,
            scl           => scl,
            receive       => receive,
            sda_in        => sda_in,
            data_received => data_received,
            byte_done     => byte_done,
            busy          => busy
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
    -- Stimulus. A single process drives every input, so the SCL/SDA waveform
    -- can never race with the sampling done inside I2C_RX.
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

        -- Slave model for one byte: pulse `receive`, then present b MSB first,
        -- one bit per SCL period (low phase drives the bit, high phase is when
        -- I2C_RX samples it on the rising edge).
        procedure send_byte (constant b : std_logic_vector(7 downto 0)) is
        begin
            receive <= '1';
            clk_ticks(1);
            receive <= '0';
            for i in 7 downto 0 loop
                scl    <= '0';          -- falling edge: slave sets the data bit
                sda_in <= b(i);
                clk_ticks(C_HALF);
                scl <= '1';             -- rising edge: I2C_RX samples the bit
                clk_ticks(C_HALF);
            end loop;
        end procedure;

        -- The 9th bit cell of a byte (the ACK slot). I2C_RX must be idle here.
        procedure ack_cell (constant a : std_logic) is
        begin
            scl    <= '0';
            sda_in <= a;
            clk_ticks(C_HALF);
            scl <= '1';
            clk_ticks(C_HALF);
        end procedure;
    begin
        -- Reset
        rst_n   <= '0';
        receive <= '0';
        scl     <= '1';
        sda_in  <= '1';
        clk_ticks(5);
        rst_n <= '1';
        clk_ticks(5);

        -- Byte 1: 0xA5 = 10100101
        send_byte(x"A5");
        clk_ticks(2);
        got := data_received;
        if got /= x"A5" then
            ok := false;
            write(L, string'("FAIL: byte 1 expected A5, got "));
            write(L, to_bitvector(got));
            writeline(results, L);
        end if;
        if byte_done_seen /= 1 then
            ok := false;
            write(L, string'("FAIL: byte 1 byte_done count = "));
            write(L, byte_done_seen);
            writeline(results, L);
        end if;
        if busy /= '0' then
            ok := false;
            write(L, string'("FAIL: busy still high after byte 1"));
            writeline(results, L);
        end if;

        -- The ACK bit cell must not disturb the captured byte.
        ack_cell('0');
        clk_ticks(2);
        if data_received /= x"A5" then
            ok := false;
            write(L, string'("FAIL: ACK cell overwrote byte 1"));
            writeline(results, L);
        end if;

        -- Byte 2: 0x3C = 00111100, leading zeros exercise the MSB-first order.
        send_byte(x"3C");
        clk_ticks(2);
        got := data_received;
        if got /= x"3C" then
            ok := false;
            write(L, string'("FAIL: byte 2 expected 3C, got "));
            write(L, to_bitvector(got));
            writeline(results, L);
        end if;
        if byte_done_seen /= 2 then
            ok := false;
            write(L, string'("FAIL: byte_done count = "));
            write(L, byte_done_seen);
            writeline(results, L);
        end if;

        -- Summary
        if ok then
            write(L, string'("RESULT: PASS -- RX rebuilt A5 then 3C, MSB first"));
        else
            write(L, string'("RESULT: FAIL"));
        end if;
        writeline(results, L);
        if ok then
            report "RESULT: PASS -- RX rebuilt A5 then 3C, MSB first" severity note;
        else
            report "RESULT: FAIL -- see results.txt" severity error;
        end if;
        wait;
    end process;

end architecture sim;
