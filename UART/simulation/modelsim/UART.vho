-- Copyright (C) 2020  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and any partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details, at
-- https://fpgasoftware.intel.com/eula.

-- VENDOR "Altera"
-- PROGRAM "Quartus Prime"
-- VERSION "Version 20.1.0 Build 711 06/05/2020 SJ Lite Edition"

-- DATE "09/07/2026 11:39:51"

-- 
-- Device: Altera EP4CE6E22C8 Package TQFP144
-- 

-- 
-- This VHDL file should be used for ModelSim-Altera (VHDL) only
-- 

LIBRARY CYCLONEIVE;
LIBRARY IEEE;
USE CYCLONEIVE.CYCLONEIVE_COMPONENTS.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY 	hard_block IS
    PORT (
	devoe : IN std_logic;
	devclrn : IN std_logic;
	devpor : IN std_logic
	);
END hard_block;

-- Design Ports Information
-- ~ALTERA_ASDO_DATA1~	=>  Location: PIN_6,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- ~ALTERA_FLASH_nCE_nCSO~	=>  Location: PIN_8,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- ~ALTERA_DCLK~	=>  Location: PIN_12,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- ~ALTERA_DATA0~	=>  Location: PIN_13,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- ~ALTERA_nCEO~	=>  Location: PIN_101,	 I/O Standard: 2.5 V,	 Current Strength: 8mA


ARCHITECTURE structure OF hard_block IS
SIGNAL gnd : std_logic := '0';
SIGNAL vcc : std_logic := '1';
SIGNAL unknown : std_logic := 'X';
SIGNAL ww_devoe : std_logic;
SIGNAL ww_devclrn : std_logic;
SIGNAL ww_devpor : std_logic;
SIGNAL \~ALTERA_ASDO_DATA1~~padout\ : std_logic;
SIGNAL \~ALTERA_FLASH_nCE_nCSO~~padout\ : std_logic;
SIGNAL \~ALTERA_DATA0~~padout\ : std_logic;
SIGNAL \~ALTERA_ASDO_DATA1~~ibuf_o\ : std_logic;
SIGNAL \~ALTERA_FLASH_nCE_nCSO~~ibuf_o\ : std_logic;
SIGNAL \~ALTERA_DATA0~~ibuf_o\ : std_logic;

BEGIN

ww_devoe <= devoe;
ww_devclrn <= devclrn;
ww_devpor <= devpor;
END structure;


LIBRARY ALTERA;
LIBRARY CYCLONEIVE;
LIBRARY IEEE;
USE ALTERA.ALTERA_PRIMITIVES_COMPONENTS.ALL;
USE CYCLONEIVE.CYCLONEIVE_COMPONENTS.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY 	UART IS
    PORT (
	clk : IN std_logic;
	rst_n : IN std_logic;
	w : IN std_logic;
	r : IN std_logic;
	data_tx_buff : IN std_logic_vector(7 DOWNTO 0);
	data_line_rx : IN std_logic;
	tx_busy : BUFFER std_logic;
	rx_busy : BUFFER std_logic;
	rx_valid : BUFFER std_logic;
	data_rx_buff : BUFFER std_logic_vector(7 DOWNTO 0);
	data_line_tx : BUFFER std_logic
	);
END UART;

-- Design Ports Information
-- tx_busy	=>  Location: PIN_87,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- rx_busy	=>  Location: PIN_59,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- rx_valid	=>  Location: PIN_53,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_rx_buff[0]	=>  Location: PIN_60,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_rx_buff[1]	=>  Location: PIN_55,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_rx_buff[2]	=>  Location: PIN_52,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_rx_buff[3]	=>  Location: PIN_64,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_rx_buff[4]	=>  Location: PIN_65,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_rx_buff[5]	=>  Location: PIN_74,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_rx_buff[6]	=>  Location: PIN_69,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_rx_buff[7]	=>  Location: PIN_67,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_line_tx	=>  Location: PIN_80,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- rst_n	=>  Location: PIN_77,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- clk	=>  Location: PIN_23,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- w	=>  Location: PIN_86,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- r	=>  Location: PIN_54,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_tx_buff[0]	=>  Location: PIN_66,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_line_rx	=>  Location: PIN_71,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_tx_buff[1]	=>  Location: PIN_58,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_tx_buff[2]	=>  Location: PIN_68,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_tx_buff[3]	=>  Location: PIN_85,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_tx_buff[4]	=>  Location: PIN_76,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_tx_buff[5]	=>  Location: PIN_84,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_tx_buff[6]	=>  Location: PIN_72,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- data_tx_buff[7]	=>  Location: PIN_83,	 I/O Standard: 2.5 V,	 Current Strength: Default


ARCHITECTURE structure OF UART IS
SIGNAL gnd : std_logic := '0';
SIGNAL vcc : std_logic := '1';
SIGNAL unknown : std_logic := 'X';
SIGNAL devoe : std_logic := '1';
SIGNAL devclrn : std_logic := '1';
SIGNAL devpor : std_logic := '1';
SIGNAL ww_devoe : std_logic;
SIGNAL ww_devclrn : std_logic;
SIGNAL ww_devpor : std_logic;
SIGNAL ww_clk : std_logic;
SIGNAL ww_rst_n : std_logic;
SIGNAL ww_w : std_logic;
SIGNAL ww_r : std_logic;
SIGNAL ww_data_tx_buff : std_logic_vector(7 DOWNTO 0);
SIGNAL ww_data_line_rx : std_logic;
SIGNAL ww_tx_busy : std_logic;
SIGNAL ww_rx_busy : std_logic;
SIGNAL ww_rx_valid : std_logic;
SIGNAL ww_data_rx_buff : std_logic_vector(7 DOWNTO 0);
SIGNAL ww_data_line_tx : std_logic;
SIGNAL \clk~inputclkctrl_INCLK_bus\ : std_logic_vector(3 DOWNTO 0);
SIGNAL \tx_busy~output_o\ : std_logic;
SIGNAL \rx_busy~output_o\ : std_logic;
SIGNAL \rx_valid~output_o\ : std_logic;
SIGNAL \data_rx_buff[0]~output_o\ : std_logic;
SIGNAL \data_rx_buff[1]~output_o\ : std_logic;
SIGNAL \data_rx_buff[2]~output_o\ : std_logic;
SIGNAL \data_rx_buff[3]~output_o\ : std_logic;
SIGNAL \data_rx_buff[4]~output_o\ : std_logic;
SIGNAL \data_rx_buff[5]~output_o\ : std_logic;
SIGNAL \data_rx_buff[6]~output_o\ : std_logic;
SIGNAL \data_rx_buff[7]~output_o\ : std_logic;
SIGNAL \data_line_tx~output_o\ : std_logic;
SIGNAL \clk~input_o\ : std_logic;
SIGNAL \clk~inputclkctrl_outclk\ : std_logic;
SIGNAL \rst_n~input_o\ : std_logic;
SIGNAL \u_tx|u_brg|counter[0]~33_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[0]~34\ : std_logic;
SIGNAL \u_tx|u_brg|counter[1]~35_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[1]~36\ : std_logic;
SIGNAL \u_tx|u_brg|counter[2]~37_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[2]~38\ : std_logic;
SIGNAL \u_tx|u_brg|counter[3]~39_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[3]~40\ : std_logic;
SIGNAL \u_tx|u_brg|counter[4]~41_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[4]~42\ : std_logic;
SIGNAL \u_tx|u_brg|counter[5]~43_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[5]~44\ : std_logic;
SIGNAL \u_tx|u_brg|counter[6]~45_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[6]~46\ : std_logic;
SIGNAL \u_tx|u_brg|counter[7]~47_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[7]~48\ : std_logic;
SIGNAL \u_tx|u_brg|counter[8]~49_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[8]~50\ : std_logic;
SIGNAL \u_tx|u_brg|counter[9]~51_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[9]~52\ : std_logic;
SIGNAL \u_tx|u_brg|counter[10]~53_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[10]~54\ : std_logic;
SIGNAL \u_tx|u_brg|counter[11]~55_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[11]~56\ : std_logic;
SIGNAL \u_tx|u_brg|counter[12]~57_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[12]~58\ : std_logic;
SIGNAL \u_tx|u_brg|counter[13]~59_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[13]~60\ : std_logic;
SIGNAL \u_tx|u_brg|counter[14]~61_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[14]~62\ : std_logic;
SIGNAL \u_tx|u_brg|counter[15]~63_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[15]~64\ : std_logic;
SIGNAL \u_tx|u_brg|counter[16]~65_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[16]~66\ : std_logic;
SIGNAL \u_tx|u_brg|counter[17]~67_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[17]~68\ : std_logic;
SIGNAL \u_tx|u_brg|counter[18]~69_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[18]~70\ : std_logic;
SIGNAL \u_tx|u_brg|counter[19]~71_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[19]~72\ : std_logic;
SIGNAL \u_tx|u_brg|counter[20]~73_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[20]~74\ : std_logic;
SIGNAL \u_tx|u_brg|counter[21]~75_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[21]~76\ : std_logic;
SIGNAL \u_tx|u_brg|counter[22]~77_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[22]~78\ : std_logic;
SIGNAL \u_tx|u_brg|counter[23]~79_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[23]~80\ : std_logic;
SIGNAL \u_tx|u_brg|counter[24]~81_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[24]~82\ : std_logic;
SIGNAL \u_tx|u_brg|counter[25]~83_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[25]~84\ : std_logic;
SIGNAL \u_tx|u_brg|counter[26]~85_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[26]~86\ : std_logic;
SIGNAL \u_tx|u_brg|counter[27]~87_combout\ : std_logic;
SIGNAL \u_tx|u_brg|Equal0~8_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[27]~88\ : std_logic;
SIGNAL \u_tx|u_brg|counter[28]~89_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[28]~90\ : std_logic;
SIGNAL \u_tx|u_brg|counter[29]~91_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[29]~92\ : std_logic;
SIGNAL \u_tx|u_brg|counter[30]~93_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[30]~94\ : std_logic;
SIGNAL \u_tx|u_brg|counter[31]~95_combout\ : std_logic;
SIGNAL \u_tx|u_brg|Equal0~9_combout\ : std_logic;
SIGNAL \u_tx|u_brg|Equal0~0_combout\ : std_logic;
SIGNAL \u_tx|u_brg|Equal0~1_combout\ : std_logic;
SIGNAL \u_tx|u_brg|Equal0~3_combout\ : std_logic;
SIGNAL \u_tx|u_brg|Equal0~2_combout\ : std_logic;
SIGNAL \u_tx|u_brg|Equal0~4_combout\ : std_logic;
SIGNAL \u_tx|u_brg|Equal0~5_combout\ : std_logic;
SIGNAL \u_tx|u_brg|Equal0~6_combout\ : std_logic;
SIGNAL \u_tx|u_brg|Equal0~7_combout\ : std_logic;
SIGNAL \u_tx|u_brg|Equal0~10_combout\ : std_logic;
SIGNAL \u_tx|u_brg|counter[31]~32_combout\ : std_logic;
SIGNAL \w~input_o\ : std_logic;
SIGNAL \u_tx|state~19_combout\ : std_logic;
SIGNAL \u_tx|state~22_combout\ : std_logic;
SIGNAL \u_tx|state~23_combout\ : std_logic;
SIGNAL \u_tx|state.START_BIT~q\ : std_logic;
SIGNAL \u_tx|state~20_combout\ : std_logic;
SIGNAL \u_tx|state~13_combout\ : std_logic;
SIGNAL \u_tx|u_brg|baud_tick~0_combout\ : std_logic;
SIGNAL \u_tx|state~15_combout\ : std_logic;
SIGNAL \u_tx|state~21_combout\ : std_logic;
SIGNAL \u_tx|state.DATA_BITS~q\ : std_logic;
SIGNAL \u_tx|count~7_combout\ : std_logic;
SIGNAL \u_tx|count[1]~5_combout\ : std_logic;
SIGNAL \u_tx|count[1]~6_combout\ : std_logic;
SIGNAL \u_tx|count~8_combout\ : std_logic;
SIGNAL \u_tx|count~4_combout\ : std_logic;
SIGNAL \u_tx|Equal0~0_combout\ : std_logic;
SIGNAL \u_tx|state~14_combout\ : std_logic;
SIGNAL \u_tx|state~17_combout\ : std_logic;
SIGNAL \u_tx|state~16_combout\ : std_logic;
SIGNAL \u_tx|state~18_combout\ : std_logic;
SIGNAL \u_tx|state.STOP_BIT~q\ : std_logic;
SIGNAL \u_tx|state~12_combout\ : std_logic;
SIGNAL \u_tx|state~24_combout\ : std_logic;
SIGNAL \u_tx|state.IDLE~q\ : std_logic;
SIGNAL \u_tx|tx_busy_r~0_combout\ : std_logic;
SIGNAL \u_tx|tx_busy_r~feeder_combout\ : std_logic;
SIGNAL \u_tx|tx_busy_r~q\ : std_logic;
SIGNAL \data_line_rx~input_o\ : std_logic;
SIGNAL \u_rx|data_in_meta~0_combout\ : std_logic;
SIGNAL \u_rx|data_in_meta~q\ : std_logic;
SIGNAL \u_rx|data_in_sync~0_combout\ : std_logic;
SIGNAL \u_rx|data_in_sync~q\ : std_logic;
SIGNAL \r~input_o\ : std_logic;
SIGNAL \u_rx|state~20_combout\ : std_logic;
SIGNAL \u_rx|baud_enable~2_combout\ : std_logic;
SIGNAL \u_rx|u_brg|counter~1_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~0_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~11\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~12_combout\ : std_logic;
SIGNAL \u_rx|u_brg|counter~2_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~13\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~14_combout\ : std_logic;
SIGNAL \u_rx|u_brg|counter~3_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~15\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~16_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~87_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~17\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~18_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~86_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~19\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~20_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~85_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~21\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~22_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~84_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~23\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~24_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~83_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~25\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~26_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~82_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~27\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~28_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~81_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~29\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~30_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~80_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~31\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~32_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~79_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~33\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~34_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~78_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~35\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~36_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~77_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~37\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~38_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~76_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~39\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~40_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~75_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~41\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~42_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~74_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~43\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~44_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~73_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~45\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~46_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~72_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Equal0~2_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Equal0~3_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~47\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~48_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~71_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~49\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~50_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~70_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~51\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~52_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~69_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~53\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~54_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~68_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~55\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~56_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~67_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~57\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~58_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~66_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~59\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~60_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~65_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~61\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~62_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~64_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Equal0~0_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Equal0~1_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Equal0~4_combout\ : std_logic;
SIGNAL \u_rx|u_brg|counter[10]~0_combout\ : std_logic;
SIGNAL \u_rx|u_brg|counter~6_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~1\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~2_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~90_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~3\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~4_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~89_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~5\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~6_combout\ : std_logic;
SIGNAL \u_rx|u_brg|counter~5_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~7\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~8_combout\ : std_logic;
SIGNAL \u_rx|u_brg|counter~4_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~9\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~10_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Add0~88_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Equal0~7_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Equal0~8_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Equal0~5_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Equal0~6_combout\ : std_logic;
SIGNAL \u_rx|u_brg|Equal0~9_combout\ : std_logic;
SIGNAL \u_rx|state~9_combout\ : std_logic;
SIGNAL \u_rx|state~27_combout\ : std_logic;
SIGNAL \u_rx|state~21_combout\ : std_logic;
SIGNAL \u_rx|state~25_combout\ : std_logic;
SIGNAL \u_rx|state.WAIT_START_BIT~q\ : std_logic;
SIGNAL \u_rx|state~19_combout\ : std_logic;
SIGNAL \u_rx|state~26_combout\ : std_logic;
SIGNAL \u_rx|state.START_BIT~q\ : std_logic;
SIGNAL \u_rx|state~23_combout\ : std_logic;
SIGNAL \u_rx|state~11_combout\ : std_logic;
SIGNAL \u_rx|state~12_combout\ : std_logic;
SIGNAL \u_rx|state~15_combout\ : std_logic;
SIGNAL \u_rx|state~16_combout\ : std_logic;
SIGNAL \u_rx|state~17_combout\ : std_logic;
SIGNAL \u_rx|state~24_combout\ : std_logic;
SIGNAL \u_rx|state.DATA_BITS~q\ : std_logic;
SIGNAL \u_rx|count~3_combout\ : std_logic;
SIGNAL \u_rx|count[1]~2_combout\ : std_logic;
SIGNAL \u_rx|count~4_combout\ : std_logic;
SIGNAL \u_rx|count~1_combout\ : std_logic;
SIGNAL \u_rx|state~13_combout\ : std_logic;
SIGNAL \u_rx|state~14_combout\ : std_logic;
SIGNAL \u_rx|state~22_combout\ : std_logic;
SIGNAL \u_rx|state.STOP_BIT~q\ : std_logic;
SIGNAL \u_rx|state~10_combout\ : std_logic;
SIGNAL \u_rx|state~18_combout\ : std_logic;
SIGNAL \u_rx|state.IDLE~q\ : std_logic;
SIGNAL \u_rx|rx_busy_r~0_combout\ : std_logic;
SIGNAL \u_rx|rx_busy_r~q\ : std_logic;
SIGNAL \u_rx|process_1~1_combout\ : std_logic;
SIGNAL \u_rx|rx_valid_r~q\ : std_logic;
SIGNAL \u_rx|u_s2p|q~8_combout\ : std_logic;
SIGNAL \u_rx|u_s2p|q[0]~1_combout\ : std_logic;
SIGNAL \u_rx|u_s2p|q~7_combout\ : std_logic;
SIGNAL \u_rx|u_s2p|q~6_combout\ : std_logic;
SIGNAL \u_rx|u_s2p|q~5_combout\ : std_logic;
SIGNAL \u_rx|u_s2p|q~4_combout\ : std_logic;
SIGNAL \u_rx|u_s2p|q~3_combout\ : std_logic;
SIGNAL \u_rx|u_s2p|q~2_combout\ : std_logic;
SIGNAL \u_rx|u_s2p|q~0_combout\ : std_logic;
SIGNAL \data_tx_buff[0]~input_o\ : std_logic;
SIGNAL \data_tx_buff[1]~input_o\ : std_logic;
SIGNAL \data_tx_buff[3]~input_o\ : std_logic;
SIGNAL \data_tx_buff[7]~input_o\ : std_logic;
SIGNAL \u_tx|u_p2s|data_in_load~10_combout\ : std_logic;
SIGNAL \u_tx|u_p2s|data_in_load~11_combout\ : std_logic;
SIGNAL \data_tx_buff[6]~input_o\ : std_logic;
SIGNAL \u_tx|u_p2s|data_in_load~9_combout\ : std_logic;
SIGNAL \u_tx|u_p2s|data_in_load[0]~3_combout\ : std_logic;
SIGNAL \data_tx_buff[5]~input_o\ : std_logic;
SIGNAL \u_tx|u_p2s|data_in_load~8_combout\ : std_logic;
SIGNAL \data_tx_buff[4]~input_o\ : std_logic;
SIGNAL \u_tx|u_p2s|data_in_load~7_combout\ : std_logic;
SIGNAL \u_tx|u_p2s|data_in_load~6_combout\ : std_logic;
SIGNAL \data_tx_buff[2]~input_o\ : std_logic;
SIGNAL \u_tx|u_p2s|data_in_load~5_combout\ : std_logic;
SIGNAL \u_tx|u_p2s|data_in_load~4_combout\ : std_logic;
SIGNAL \u_tx|u_p2s|data_in_load~2_combout\ : std_logic;
SIGNAL \u_tx|data_out_r~0_combout\ : std_logic;
SIGNAL \u_tx|data_out_r~q\ : std_logic;
SIGNAL \u_rx|count\ : std_logic_vector(2 DOWNTO 0);
SIGNAL \u_tx|u_p2s|data_in_load\ : std_logic_vector(7 DOWNTO 0);
SIGNAL \u_tx|u_brg|counter\ : std_logic_vector(31 DOWNTO 0);
SIGNAL \u_tx|count\ : std_logic_vector(2 DOWNTO 0);
SIGNAL \u_rx|u_s2p|q\ : std_logic_vector(7 DOWNTO 0);
SIGNAL \u_rx|u_brg|counter\ : std_logic_vector(31 DOWNTO 0);
SIGNAL \ALT_INV_rst_n~input_o\ : std_logic;
SIGNAL \u_tx|ALT_INV_data_out_r~q\ : std_logic;

COMPONENT hard_block
    PORT (
	devoe : IN std_logic;
	devclrn : IN std_logic;
	devpor : IN std_logic);
END COMPONENT;

BEGIN

ww_clk <= clk;
ww_rst_n <= rst_n;
ww_w <= w;
ww_r <= r;
ww_data_tx_buff <= data_tx_buff;
ww_data_line_rx <= data_line_rx;
tx_busy <= ww_tx_busy;
rx_busy <= ww_rx_busy;
rx_valid <= ww_rx_valid;
data_rx_buff <= ww_data_rx_buff;
data_line_tx <= ww_data_line_tx;
ww_devoe <= devoe;
ww_devclrn <= devclrn;
ww_devpor <= devpor;

\clk~inputclkctrl_INCLK_bus\ <= (vcc & vcc & vcc & \clk~input_o\);
\ALT_INV_rst_n~input_o\ <= NOT \rst_n~input_o\;
\u_tx|ALT_INV_data_out_r~q\ <= NOT \u_tx|data_out_r~q\;
auto_generated_inst : hard_block
PORT MAP (
	devoe => ww_devoe,
	devclrn => ww_devclrn,
	devpor => ww_devpor);

-- Location: IOOBUF_X34_Y10_N9
\tx_busy~output\ : cycloneive_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false")
-- pragma translate_on
PORT MAP (
	i => \u_tx|tx_busy_r~q\,
	devoe => ww_devoe,
	o => \tx_busy~output_o\);

-- Location: IOOBUF_X23_Y0_N16
\rx_busy~output\ : cycloneive_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false")
-- pragma translate_on
PORT MAP (
	i => \u_rx|rx_busy_r~q\,
	devoe => ww_devoe,
	o => \rx_busy~output_o\);

-- Location: IOOBUF_X16_Y0_N2
\rx_valid~output\ : cycloneive_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false")
-- pragma translate_on
PORT MAP (
	i => \u_rx|rx_valid_r~q\,
	devoe => ww_devoe,
	o => \rx_valid~output_o\);

-- Location: IOOBUF_X23_Y0_N9
\data_rx_buff[0]~output\ : cycloneive_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false")
-- pragma translate_on
PORT MAP (
	i => \u_rx|u_s2p|q\(0),
	devoe => ww_devoe,
	o => \data_rx_buff[0]~output_o\);

-- Location: IOOBUF_X18_Y0_N16
\data_rx_buff[1]~output\ : cycloneive_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false")
-- pragma translate_on
PORT MAP (
	i => \u_rx|u_s2p|q\(1),
	devoe => ww_devoe,
	o => \data_rx_buff[1]~output_o\);

-- Location: IOOBUF_X16_Y0_N9
\data_rx_buff[2]~output\ : cycloneive_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false")
-- pragma translate_on
PORT MAP (
	i => \u_rx|u_s2p|q\(2),
	devoe => ww_devoe,
	o => \data_rx_buff[2]~output_o\);

-- Location: IOOBUF_X25_Y0_N2
\data_rx_buff[3]~output\ : cycloneive_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false")
-- pragma translate_on
PORT MAP (
	i => \u_rx|u_s2p|q\(3),
	devoe => ww_devoe,
	o => \data_rx_buff[3]~output_o\);

-- Location: IOOBUF_X28_Y0_N23
\data_rx_buff[4]~output\ : cycloneive_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false")
-- pragma translate_on
PORT MAP (
	i => \u_rx|u_s2p|q\(4),
	devoe => ww_devoe,
	o => \data_rx_buff[4]~output_o\);

-- Location: IOOBUF_X34_Y2_N16
\data_rx_buff[5]~output\ : cycloneive_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false")
-- pragma translate_on
PORT MAP (
	i => \u_rx|u_s2p|q\(5),
	devoe => ww_devoe,
	o => \data_rx_buff[5]~output_o\);

-- Location: IOOBUF_X30_Y0_N2
\data_rx_buff[6]~output\ : cycloneive_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false")
-- pragma translate_on
PORT MAP (
	i => \u_rx|u_s2p|q\(6),
	devoe => ww_devoe,
	o => \data_rx_buff[6]~output_o\);

-- Location: IOOBUF_X30_Y0_N23
\data_rx_buff[7]~output\ : cycloneive_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false")
-- pragma translate_on
PORT MAP (
	i => \u_rx|u_s2p|q\(7),
	devoe => ww_devoe,
	o => \data_rx_buff[7]~output_o\);

-- Location: IOOBUF_X34_Y7_N9
\data_line_tx~output\ : cycloneive_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false")
-- pragma translate_on
PORT MAP (
	i => \u_tx|ALT_INV_data_out_r~q\,
	devoe => ww_devoe,
	o => \data_line_tx~output_o\);

-- Location: IOIBUF_X0_Y11_N8
\clk~input\ : cycloneive_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_clk,
	o => \clk~input_o\);

-- Location: CLKCTRL_G2
\clk~inputclkctrl\ : cycloneive_clkctrl
-- pragma translate_off
GENERIC MAP (
	clock_type => "global clock",
	ena_register_mode => "none")
-- pragma translate_on
PORT MAP (
	inclk => \clk~inputclkctrl_INCLK_bus\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	outclk => \clk~inputclkctrl_outclk\);

-- Location: IOIBUF_X34_Y4_N15
\rst_n~input\ : cycloneive_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_rst_n,
	o => \rst_n~input_o\);

-- Location: LCCOMB_X24_Y9_N0
\u_tx|u_brg|counter[0]~33\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[0]~33_combout\ = \u_tx|u_brg|counter\(0) $ (VCC)
-- \u_tx|u_brg|counter[0]~34\ = CARRY(\u_tx|u_brg|counter\(0))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011001111001100",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(0),
	datad => VCC,
	combout => \u_tx|u_brg|counter[0]~33_combout\,
	cout => \u_tx|u_brg|counter[0]~34\);

-- Location: FF_X24_Y9_N1
\u_tx|u_brg|counter[0]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[0]~33_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(0));

-- Location: LCCOMB_X24_Y9_N2
\u_tx|u_brg|counter[1]~35\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[1]~35_combout\ = (\u_tx|u_brg|counter\(1) & (!\u_tx|u_brg|counter[0]~34\)) # (!\u_tx|u_brg|counter\(1) & ((\u_tx|u_brg|counter[0]~34\) # (GND)))
-- \u_tx|u_brg|counter[1]~36\ = CARRY((!\u_tx|u_brg|counter[0]~34\) # (!\u_tx|u_brg|counter\(1)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(1),
	datad => VCC,
	cin => \u_tx|u_brg|counter[0]~34\,
	combout => \u_tx|u_brg|counter[1]~35_combout\,
	cout => \u_tx|u_brg|counter[1]~36\);

-- Location: FF_X24_Y9_N3
\u_tx|u_brg|counter[1]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[1]~35_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(1));

-- Location: LCCOMB_X24_Y9_N4
\u_tx|u_brg|counter[2]~37\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[2]~37_combout\ = (\u_tx|u_brg|counter\(2) & (\u_tx|u_brg|counter[1]~36\ $ (GND))) # (!\u_tx|u_brg|counter\(2) & (!\u_tx|u_brg|counter[1]~36\ & VCC))
-- \u_tx|u_brg|counter[2]~38\ = CARRY((\u_tx|u_brg|counter\(2) & !\u_tx|u_brg|counter[1]~36\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(2),
	datad => VCC,
	cin => \u_tx|u_brg|counter[1]~36\,
	combout => \u_tx|u_brg|counter[2]~37_combout\,
	cout => \u_tx|u_brg|counter[2]~38\);

-- Location: FF_X24_Y9_N5
\u_tx|u_brg|counter[2]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[2]~37_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(2));

-- Location: LCCOMB_X24_Y9_N6
\u_tx|u_brg|counter[3]~39\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[3]~39_combout\ = (\u_tx|u_brg|counter\(3) & (!\u_tx|u_brg|counter[2]~38\)) # (!\u_tx|u_brg|counter\(3) & ((\u_tx|u_brg|counter[2]~38\) # (GND)))
-- \u_tx|u_brg|counter[3]~40\ = CARRY((!\u_tx|u_brg|counter[2]~38\) # (!\u_tx|u_brg|counter\(3)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(3),
	datad => VCC,
	cin => \u_tx|u_brg|counter[2]~38\,
	combout => \u_tx|u_brg|counter[3]~39_combout\,
	cout => \u_tx|u_brg|counter[3]~40\);

-- Location: FF_X24_Y9_N7
\u_tx|u_brg|counter[3]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[3]~39_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(3));

-- Location: LCCOMB_X24_Y9_N8
\u_tx|u_brg|counter[4]~41\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[4]~41_combout\ = (\u_tx|u_brg|counter\(4) & (\u_tx|u_brg|counter[3]~40\ $ (GND))) # (!\u_tx|u_brg|counter\(4) & (!\u_tx|u_brg|counter[3]~40\ & VCC))
-- \u_tx|u_brg|counter[4]~42\ = CARRY((\u_tx|u_brg|counter\(4) & !\u_tx|u_brg|counter[3]~40\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(4),
	datad => VCC,
	cin => \u_tx|u_brg|counter[3]~40\,
	combout => \u_tx|u_brg|counter[4]~41_combout\,
	cout => \u_tx|u_brg|counter[4]~42\);

-- Location: FF_X24_Y9_N9
\u_tx|u_brg|counter[4]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[4]~41_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(4));

-- Location: LCCOMB_X24_Y9_N10
\u_tx|u_brg|counter[5]~43\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[5]~43_combout\ = (\u_tx|u_brg|counter\(5) & (!\u_tx|u_brg|counter[4]~42\)) # (!\u_tx|u_brg|counter\(5) & ((\u_tx|u_brg|counter[4]~42\) # (GND)))
-- \u_tx|u_brg|counter[5]~44\ = CARRY((!\u_tx|u_brg|counter[4]~42\) # (!\u_tx|u_brg|counter\(5)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(5),
	datad => VCC,
	cin => \u_tx|u_brg|counter[4]~42\,
	combout => \u_tx|u_brg|counter[5]~43_combout\,
	cout => \u_tx|u_brg|counter[5]~44\);

-- Location: FF_X24_Y9_N11
\u_tx|u_brg|counter[5]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[5]~43_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(5));

-- Location: LCCOMB_X24_Y9_N12
\u_tx|u_brg|counter[6]~45\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[6]~45_combout\ = (\u_tx|u_brg|counter\(6) & (\u_tx|u_brg|counter[5]~44\ $ (GND))) # (!\u_tx|u_brg|counter\(6) & (!\u_tx|u_brg|counter[5]~44\ & VCC))
-- \u_tx|u_brg|counter[6]~46\ = CARRY((\u_tx|u_brg|counter\(6) & !\u_tx|u_brg|counter[5]~44\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010010100001010",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(6),
	datad => VCC,
	cin => \u_tx|u_brg|counter[5]~44\,
	combout => \u_tx|u_brg|counter[6]~45_combout\,
	cout => \u_tx|u_brg|counter[6]~46\);

-- Location: FF_X24_Y9_N13
\u_tx|u_brg|counter[6]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[6]~45_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(6));

-- Location: LCCOMB_X24_Y9_N14
\u_tx|u_brg|counter[7]~47\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[7]~47_combout\ = (\u_tx|u_brg|counter\(7) & (!\u_tx|u_brg|counter[6]~46\)) # (!\u_tx|u_brg|counter\(7) & ((\u_tx|u_brg|counter[6]~46\) # (GND)))
-- \u_tx|u_brg|counter[7]~48\ = CARRY((!\u_tx|u_brg|counter[6]~46\) # (!\u_tx|u_brg|counter\(7)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(7),
	datad => VCC,
	cin => \u_tx|u_brg|counter[6]~46\,
	combout => \u_tx|u_brg|counter[7]~47_combout\,
	cout => \u_tx|u_brg|counter[7]~48\);

-- Location: FF_X24_Y9_N15
\u_tx|u_brg|counter[7]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[7]~47_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(7));

-- Location: LCCOMB_X24_Y9_N16
\u_tx|u_brg|counter[8]~49\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[8]~49_combout\ = (\u_tx|u_brg|counter\(8) & (\u_tx|u_brg|counter[7]~48\ $ (GND))) # (!\u_tx|u_brg|counter\(8) & (!\u_tx|u_brg|counter[7]~48\ & VCC))
-- \u_tx|u_brg|counter[8]~50\ = CARRY((\u_tx|u_brg|counter\(8) & !\u_tx|u_brg|counter[7]~48\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(8),
	datad => VCC,
	cin => \u_tx|u_brg|counter[7]~48\,
	combout => \u_tx|u_brg|counter[8]~49_combout\,
	cout => \u_tx|u_brg|counter[8]~50\);

-- Location: FF_X24_Y9_N17
\u_tx|u_brg|counter[8]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[8]~49_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(8));

-- Location: LCCOMB_X24_Y9_N18
\u_tx|u_brg|counter[9]~51\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[9]~51_combout\ = (\u_tx|u_brg|counter\(9) & (!\u_tx|u_brg|counter[8]~50\)) # (!\u_tx|u_brg|counter\(9) & ((\u_tx|u_brg|counter[8]~50\) # (GND)))
-- \u_tx|u_brg|counter[9]~52\ = CARRY((!\u_tx|u_brg|counter[8]~50\) # (!\u_tx|u_brg|counter\(9)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(9),
	datad => VCC,
	cin => \u_tx|u_brg|counter[8]~50\,
	combout => \u_tx|u_brg|counter[9]~51_combout\,
	cout => \u_tx|u_brg|counter[9]~52\);

-- Location: FF_X24_Y9_N19
\u_tx|u_brg|counter[9]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[9]~51_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(9));

-- Location: LCCOMB_X24_Y9_N20
\u_tx|u_brg|counter[10]~53\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[10]~53_combout\ = (\u_tx|u_brg|counter\(10) & (\u_tx|u_brg|counter[9]~52\ $ (GND))) # (!\u_tx|u_brg|counter\(10) & (!\u_tx|u_brg|counter[9]~52\ & VCC))
-- \u_tx|u_brg|counter[10]~54\ = CARRY((\u_tx|u_brg|counter\(10) & !\u_tx|u_brg|counter[9]~52\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(10),
	datad => VCC,
	cin => \u_tx|u_brg|counter[9]~52\,
	combout => \u_tx|u_brg|counter[10]~53_combout\,
	cout => \u_tx|u_brg|counter[10]~54\);

-- Location: FF_X24_Y9_N21
\u_tx|u_brg|counter[10]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[10]~53_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(10));

-- Location: LCCOMB_X24_Y9_N22
\u_tx|u_brg|counter[11]~55\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[11]~55_combout\ = (\u_tx|u_brg|counter\(11) & (!\u_tx|u_brg|counter[10]~54\)) # (!\u_tx|u_brg|counter\(11) & ((\u_tx|u_brg|counter[10]~54\) # (GND)))
-- \u_tx|u_brg|counter[11]~56\ = CARRY((!\u_tx|u_brg|counter[10]~54\) # (!\u_tx|u_brg|counter\(11)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(11),
	datad => VCC,
	cin => \u_tx|u_brg|counter[10]~54\,
	combout => \u_tx|u_brg|counter[11]~55_combout\,
	cout => \u_tx|u_brg|counter[11]~56\);

-- Location: FF_X24_Y9_N23
\u_tx|u_brg|counter[11]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[11]~55_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(11));

-- Location: LCCOMB_X24_Y9_N24
\u_tx|u_brg|counter[12]~57\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[12]~57_combout\ = (\u_tx|u_brg|counter\(12) & (\u_tx|u_brg|counter[11]~56\ $ (GND))) # (!\u_tx|u_brg|counter\(12) & (!\u_tx|u_brg|counter[11]~56\ & VCC))
-- \u_tx|u_brg|counter[12]~58\ = CARRY((\u_tx|u_brg|counter\(12) & !\u_tx|u_brg|counter[11]~56\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(12),
	datad => VCC,
	cin => \u_tx|u_brg|counter[11]~56\,
	combout => \u_tx|u_brg|counter[12]~57_combout\,
	cout => \u_tx|u_brg|counter[12]~58\);

-- Location: FF_X24_Y9_N25
\u_tx|u_brg|counter[12]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[12]~57_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(12));

-- Location: LCCOMB_X24_Y9_N26
\u_tx|u_brg|counter[13]~59\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[13]~59_combout\ = (\u_tx|u_brg|counter\(13) & (!\u_tx|u_brg|counter[12]~58\)) # (!\u_tx|u_brg|counter\(13) & ((\u_tx|u_brg|counter[12]~58\) # (GND)))
-- \u_tx|u_brg|counter[13]~60\ = CARRY((!\u_tx|u_brg|counter[12]~58\) # (!\u_tx|u_brg|counter\(13)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(13),
	datad => VCC,
	cin => \u_tx|u_brg|counter[12]~58\,
	combout => \u_tx|u_brg|counter[13]~59_combout\,
	cout => \u_tx|u_brg|counter[13]~60\);

-- Location: FF_X24_Y9_N27
\u_tx|u_brg|counter[13]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[13]~59_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(13));

-- Location: LCCOMB_X24_Y9_N28
\u_tx|u_brg|counter[14]~61\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[14]~61_combout\ = (\u_tx|u_brg|counter\(14) & (\u_tx|u_brg|counter[13]~60\ $ (GND))) # (!\u_tx|u_brg|counter\(14) & (!\u_tx|u_brg|counter[13]~60\ & VCC))
-- \u_tx|u_brg|counter[14]~62\ = CARRY((\u_tx|u_brg|counter\(14) & !\u_tx|u_brg|counter[13]~60\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(14),
	datad => VCC,
	cin => \u_tx|u_brg|counter[13]~60\,
	combout => \u_tx|u_brg|counter[14]~61_combout\,
	cout => \u_tx|u_brg|counter[14]~62\);

-- Location: FF_X24_Y9_N29
\u_tx|u_brg|counter[14]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[14]~61_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(14));

-- Location: LCCOMB_X24_Y9_N30
\u_tx|u_brg|counter[15]~63\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[15]~63_combout\ = (\u_tx|u_brg|counter\(15) & (!\u_tx|u_brg|counter[14]~62\)) # (!\u_tx|u_brg|counter\(15) & ((\u_tx|u_brg|counter[14]~62\) # (GND)))
-- \u_tx|u_brg|counter[15]~64\ = CARRY((!\u_tx|u_brg|counter[14]~62\) # (!\u_tx|u_brg|counter\(15)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(15),
	datad => VCC,
	cin => \u_tx|u_brg|counter[14]~62\,
	combout => \u_tx|u_brg|counter[15]~63_combout\,
	cout => \u_tx|u_brg|counter[15]~64\);

-- Location: FF_X24_Y9_N31
\u_tx|u_brg|counter[15]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[15]~63_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(15));

-- Location: LCCOMB_X24_Y8_N0
\u_tx|u_brg|counter[16]~65\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[16]~65_combout\ = (\u_tx|u_brg|counter\(16) & (\u_tx|u_brg|counter[15]~64\ $ (GND))) # (!\u_tx|u_brg|counter\(16) & (!\u_tx|u_brg|counter[15]~64\ & VCC))
-- \u_tx|u_brg|counter[16]~66\ = CARRY((\u_tx|u_brg|counter\(16) & !\u_tx|u_brg|counter[15]~64\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(16),
	datad => VCC,
	cin => \u_tx|u_brg|counter[15]~64\,
	combout => \u_tx|u_brg|counter[16]~65_combout\,
	cout => \u_tx|u_brg|counter[16]~66\);

-- Location: FF_X24_Y8_N1
\u_tx|u_brg|counter[16]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[16]~65_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(16));

-- Location: LCCOMB_X24_Y8_N2
\u_tx|u_brg|counter[17]~67\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[17]~67_combout\ = (\u_tx|u_brg|counter\(17) & (!\u_tx|u_brg|counter[16]~66\)) # (!\u_tx|u_brg|counter\(17) & ((\u_tx|u_brg|counter[16]~66\) # (GND)))
-- \u_tx|u_brg|counter[17]~68\ = CARRY((!\u_tx|u_brg|counter[16]~66\) # (!\u_tx|u_brg|counter\(17)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(17),
	datad => VCC,
	cin => \u_tx|u_brg|counter[16]~66\,
	combout => \u_tx|u_brg|counter[17]~67_combout\,
	cout => \u_tx|u_brg|counter[17]~68\);

-- Location: FF_X24_Y8_N3
\u_tx|u_brg|counter[17]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[17]~67_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(17));

-- Location: LCCOMB_X24_Y8_N4
\u_tx|u_brg|counter[18]~69\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[18]~69_combout\ = (\u_tx|u_brg|counter\(18) & (\u_tx|u_brg|counter[17]~68\ $ (GND))) # (!\u_tx|u_brg|counter\(18) & (!\u_tx|u_brg|counter[17]~68\ & VCC))
-- \u_tx|u_brg|counter[18]~70\ = CARRY((\u_tx|u_brg|counter\(18) & !\u_tx|u_brg|counter[17]~68\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(18),
	datad => VCC,
	cin => \u_tx|u_brg|counter[17]~68\,
	combout => \u_tx|u_brg|counter[18]~69_combout\,
	cout => \u_tx|u_brg|counter[18]~70\);

-- Location: FF_X24_Y8_N5
\u_tx|u_brg|counter[18]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[18]~69_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(18));

-- Location: LCCOMB_X24_Y8_N6
\u_tx|u_brg|counter[19]~71\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[19]~71_combout\ = (\u_tx|u_brg|counter\(19) & (!\u_tx|u_brg|counter[18]~70\)) # (!\u_tx|u_brg|counter\(19) & ((\u_tx|u_brg|counter[18]~70\) # (GND)))
-- \u_tx|u_brg|counter[19]~72\ = CARRY((!\u_tx|u_brg|counter[18]~70\) # (!\u_tx|u_brg|counter\(19)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(19),
	datad => VCC,
	cin => \u_tx|u_brg|counter[18]~70\,
	combout => \u_tx|u_brg|counter[19]~71_combout\,
	cout => \u_tx|u_brg|counter[19]~72\);

-- Location: FF_X25_Y9_N13
\u_tx|u_brg|counter[19]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	asdata => \u_tx|u_brg|counter[19]~71_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	sload => VCC,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(19));

-- Location: LCCOMB_X24_Y8_N8
\u_tx|u_brg|counter[20]~73\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[20]~73_combout\ = (\u_tx|u_brg|counter\(20) & (\u_tx|u_brg|counter[19]~72\ $ (GND))) # (!\u_tx|u_brg|counter\(20) & (!\u_tx|u_brg|counter[19]~72\ & VCC))
-- \u_tx|u_brg|counter[20]~74\ = CARRY((\u_tx|u_brg|counter\(20) & !\u_tx|u_brg|counter[19]~72\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(20),
	datad => VCC,
	cin => \u_tx|u_brg|counter[19]~72\,
	combout => \u_tx|u_brg|counter[20]~73_combout\,
	cout => \u_tx|u_brg|counter[20]~74\);

-- Location: FF_X24_Y8_N9
\u_tx|u_brg|counter[20]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[20]~73_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(20));

-- Location: LCCOMB_X24_Y8_N10
\u_tx|u_brg|counter[21]~75\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[21]~75_combout\ = (\u_tx|u_brg|counter\(21) & (!\u_tx|u_brg|counter[20]~74\)) # (!\u_tx|u_brg|counter\(21) & ((\u_tx|u_brg|counter[20]~74\) # (GND)))
-- \u_tx|u_brg|counter[21]~76\ = CARRY((!\u_tx|u_brg|counter[20]~74\) # (!\u_tx|u_brg|counter\(21)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(21),
	datad => VCC,
	cin => \u_tx|u_brg|counter[20]~74\,
	combout => \u_tx|u_brg|counter[21]~75_combout\,
	cout => \u_tx|u_brg|counter[21]~76\);

-- Location: FF_X24_Y8_N11
\u_tx|u_brg|counter[21]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[21]~75_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(21));

-- Location: LCCOMB_X24_Y8_N12
\u_tx|u_brg|counter[22]~77\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[22]~77_combout\ = (\u_tx|u_brg|counter\(22) & (\u_tx|u_brg|counter[21]~76\ $ (GND))) # (!\u_tx|u_brg|counter\(22) & (!\u_tx|u_brg|counter[21]~76\ & VCC))
-- \u_tx|u_brg|counter[22]~78\ = CARRY((\u_tx|u_brg|counter\(22) & !\u_tx|u_brg|counter[21]~76\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010010100001010",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(22),
	datad => VCC,
	cin => \u_tx|u_brg|counter[21]~76\,
	combout => \u_tx|u_brg|counter[22]~77_combout\,
	cout => \u_tx|u_brg|counter[22]~78\);

-- Location: FF_X24_Y8_N13
\u_tx|u_brg|counter[22]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[22]~77_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(22));

-- Location: LCCOMB_X24_Y8_N14
\u_tx|u_brg|counter[23]~79\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[23]~79_combout\ = (\u_tx|u_brg|counter\(23) & (!\u_tx|u_brg|counter[22]~78\)) # (!\u_tx|u_brg|counter\(23) & ((\u_tx|u_brg|counter[22]~78\) # (GND)))
-- \u_tx|u_brg|counter[23]~80\ = CARRY((!\u_tx|u_brg|counter[22]~78\) # (!\u_tx|u_brg|counter\(23)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(23),
	datad => VCC,
	cin => \u_tx|u_brg|counter[22]~78\,
	combout => \u_tx|u_brg|counter[23]~79_combout\,
	cout => \u_tx|u_brg|counter[23]~80\);

-- Location: FF_X24_Y8_N15
\u_tx|u_brg|counter[23]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[23]~79_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(23));

-- Location: LCCOMB_X24_Y8_N16
\u_tx|u_brg|counter[24]~81\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[24]~81_combout\ = (\u_tx|u_brg|counter\(24) & (\u_tx|u_brg|counter[23]~80\ $ (GND))) # (!\u_tx|u_brg|counter\(24) & (!\u_tx|u_brg|counter[23]~80\ & VCC))
-- \u_tx|u_brg|counter[24]~82\ = CARRY((\u_tx|u_brg|counter\(24) & !\u_tx|u_brg|counter[23]~80\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(24),
	datad => VCC,
	cin => \u_tx|u_brg|counter[23]~80\,
	combout => \u_tx|u_brg|counter[24]~81_combout\,
	cout => \u_tx|u_brg|counter[24]~82\);

-- Location: FF_X24_Y8_N17
\u_tx|u_brg|counter[24]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[24]~81_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(24));

-- Location: LCCOMB_X24_Y8_N18
\u_tx|u_brg|counter[25]~83\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[25]~83_combout\ = (\u_tx|u_brg|counter\(25) & (!\u_tx|u_brg|counter[24]~82\)) # (!\u_tx|u_brg|counter\(25) & ((\u_tx|u_brg|counter[24]~82\) # (GND)))
-- \u_tx|u_brg|counter[25]~84\ = CARRY((!\u_tx|u_brg|counter[24]~82\) # (!\u_tx|u_brg|counter\(25)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(25),
	datad => VCC,
	cin => \u_tx|u_brg|counter[24]~82\,
	combout => \u_tx|u_brg|counter[25]~83_combout\,
	cout => \u_tx|u_brg|counter[25]~84\);

-- Location: FF_X24_Y8_N19
\u_tx|u_brg|counter[25]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[25]~83_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(25));

-- Location: LCCOMB_X24_Y8_N20
\u_tx|u_brg|counter[26]~85\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[26]~85_combout\ = (\u_tx|u_brg|counter\(26) & (\u_tx|u_brg|counter[25]~84\ $ (GND))) # (!\u_tx|u_brg|counter\(26) & (!\u_tx|u_brg|counter[25]~84\ & VCC))
-- \u_tx|u_brg|counter[26]~86\ = CARRY((\u_tx|u_brg|counter\(26) & !\u_tx|u_brg|counter[25]~84\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(26),
	datad => VCC,
	cin => \u_tx|u_brg|counter[25]~84\,
	combout => \u_tx|u_brg|counter[26]~85_combout\,
	cout => \u_tx|u_brg|counter[26]~86\);

-- Location: FF_X24_Y8_N21
\u_tx|u_brg|counter[26]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[26]~85_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(26));

-- Location: LCCOMB_X24_Y8_N22
\u_tx|u_brg|counter[27]~87\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[27]~87_combout\ = (\u_tx|u_brg|counter\(27) & (!\u_tx|u_brg|counter[26]~86\)) # (!\u_tx|u_brg|counter\(27) & ((\u_tx|u_brg|counter[26]~86\) # (GND)))
-- \u_tx|u_brg|counter[27]~88\ = CARRY((!\u_tx|u_brg|counter[26]~86\) # (!\u_tx|u_brg|counter\(27)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(27),
	datad => VCC,
	cin => \u_tx|u_brg|counter[26]~86\,
	combout => \u_tx|u_brg|counter[27]~87_combout\,
	cout => \u_tx|u_brg|counter[27]~88\);

-- Location: FF_X24_Y8_N23
\u_tx|u_brg|counter[27]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[27]~87_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(27));

-- Location: LCCOMB_X25_Y9_N26
\u_tx|u_brg|Equal0~8\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|Equal0~8_combout\ = (\u_tx|u_brg|counter\(24)) # ((\u_tx|u_brg|counter\(25)) # ((\u_tx|u_brg|counter\(26)) # (\u_tx|u_brg|counter\(27))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(24),
	datab => \u_tx|u_brg|counter\(25),
	datac => \u_tx|u_brg|counter\(26),
	datad => \u_tx|u_brg|counter\(27),
	combout => \u_tx|u_brg|Equal0~8_combout\);

-- Location: LCCOMB_X24_Y8_N24
\u_tx|u_brg|counter[28]~89\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[28]~89_combout\ = (\u_tx|u_brg|counter\(28) & (\u_tx|u_brg|counter[27]~88\ $ (GND))) # (!\u_tx|u_brg|counter\(28) & (!\u_tx|u_brg|counter[27]~88\ & VCC))
-- \u_tx|u_brg|counter[28]~90\ = CARRY((\u_tx|u_brg|counter\(28) & !\u_tx|u_brg|counter[27]~88\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(28),
	datad => VCC,
	cin => \u_tx|u_brg|counter[27]~88\,
	combout => \u_tx|u_brg|counter[28]~89_combout\,
	cout => \u_tx|u_brg|counter[28]~90\);

-- Location: FF_X24_Y8_N25
\u_tx|u_brg|counter[28]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[28]~89_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(28));

-- Location: LCCOMB_X24_Y8_N26
\u_tx|u_brg|counter[29]~91\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[29]~91_combout\ = (\u_tx|u_brg|counter\(29) & (!\u_tx|u_brg|counter[28]~90\)) # (!\u_tx|u_brg|counter\(29) & ((\u_tx|u_brg|counter[28]~90\) # (GND)))
-- \u_tx|u_brg|counter[29]~92\ = CARRY((!\u_tx|u_brg|counter[28]~90\) # (!\u_tx|u_brg|counter\(29)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(29),
	datad => VCC,
	cin => \u_tx|u_brg|counter[28]~90\,
	combout => \u_tx|u_brg|counter[29]~91_combout\,
	cout => \u_tx|u_brg|counter[29]~92\);

-- Location: FF_X24_Y8_N27
\u_tx|u_brg|counter[29]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[29]~91_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(29));

-- Location: LCCOMB_X24_Y8_N28
\u_tx|u_brg|counter[30]~93\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[30]~93_combout\ = (\u_tx|u_brg|counter\(30) & (\u_tx|u_brg|counter[29]~92\ $ (GND))) # (!\u_tx|u_brg|counter\(30) & (!\u_tx|u_brg|counter[29]~92\ & VCC))
-- \u_tx|u_brg|counter[30]~94\ = CARRY((\u_tx|u_brg|counter\(30) & !\u_tx|u_brg|counter[29]~92\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(30),
	datad => VCC,
	cin => \u_tx|u_brg|counter[29]~92\,
	combout => \u_tx|u_brg|counter[30]~93_combout\,
	cout => \u_tx|u_brg|counter[30]~94\);

-- Location: FF_X24_Y8_N29
\u_tx|u_brg|counter[30]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[30]~93_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(30));

-- Location: LCCOMB_X24_Y8_N30
\u_tx|u_brg|counter[31]~95\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[31]~95_combout\ = \u_tx|u_brg|counter\(31) $ (\u_tx|u_brg|counter[30]~94\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011010",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(31),
	cin => \u_tx|u_brg|counter[30]~94\,
	combout => \u_tx|u_brg|counter[31]~95_combout\);

-- Location: FF_X24_Y8_N31
\u_tx|u_brg|counter[31]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_brg|counter[31]~95_combout\,
	sclr => \u_tx|u_brg|counter[31]~32_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_brg|counter\(31));

-- Location: LCCOMB_X25_Y9_N24
\u_tx|u_brg|Equal0~9\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|Equal0~9_combout\ = (\u_tx|u_brg|counter\(28)) # ((\u_tx|u_brg|counter\(31)) # ((\u_tx|u_brg|counter\(29)) # (\u_tx|u_brg|counter\(30))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(28),
	datab => \u_tx|u_brg|counter\(31),
	datac => \u_tx|u_brg|counter\(29),
	datad => \u_tx|u_brg|counter\(30),
	combout => \u_tx|u_brg|Equal0~9_combout\);

-- Location: LCCOMB_X25_Y9_N22
\u_tx|u_brg|Equal0~0\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|Equal0~0_combout\ = ((\u_tx|u_brg|counter\(2)) # ((\u_tx|u_brg|counter\(1)) # (\u_tx|u_brg|counter\(3)))) # (!\u_tx|u_brg|counter\(0))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111101",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(0),
	datab => \u_tx|u_brg|counter\(2),
	datac => \u_tx|u_brg|counter\(1),
	datad => \u_tx|u_brg|counter\(3),
	combout => \u_tx|u_brg|Equal0~0_combout\);

-- Location: LCCOMB_X25_Y9_N28
\u_tx|u_brg|Equal0~1\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|Equal0~1_combout\ = ((\u_tx|u_brg|counter\(6)) # ((!\u_tx|u_brg|counter\(5)) # (!\u_tx|u_brg|counter\(4)))) # (!\u_tx|u_brg|counter\(7))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1101111111111111",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(7),
	datab => \u_tx|u_brg|counter\(6),
	datac => \u_tx|u_brg|counter\(4),
	datad => \u_tx|u_brg|counter\(5),
	combout => \u_tx|u_brg|Equal0~1_combout\);

-- Location: LCCOMB_X25_Y9_N8
\u_tx|u_brg|Equal0~3\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|Equal0~3_combout\ = (\u_tx|u_brg|counter\(12)) # ((\u_tx|u_brg|counter\(14)) # ((\u_tx|u_brg|counter\(13)) # (\u_tx|u_brg|counter\(15))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(12),
	datab => \u_tx|u_brg|counter\(14),
	datac => \u_tx|u_brg|counter\(13),
	datad => \u_tx|u_brg|counter\(15),
	combout => \u_tx|u_brg|Equal0~3_combout\);

-- Location: LCCOMB_X25_Y9_N6
\u_tx|u_brg|Equal0~2\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|Equal0~2_combout\ = ((\u_tx|u_brg|counter\(10)) # ((\u_tx|u_brg|counter\(9)) # (\u_tx|u_brg|counter\(11)))) # (!\u_tx|u_brg|counter\(8))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111101",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(8),
	datab => \u_tx|u_brg|counter\(10),
	datac => \u_tx|u_brg|counter\(9),
	datad => \u_tx|u_brg|counter\(11),
	combout => \u_tx|u_brg|Equal0~2_combout\);

-- Location: LCCOMB_X25_Y9_N14
\u_tx|u_brg|Equal0~4\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|Equal0~4_combout\ = (\u_tx|u_brg|Equal0~0_combout\) # ((\u_tx|u_brg|Equal0~1_combout\) # ((\u_tx|u_brg|Equal0~3_combout\) # (\u_tx|u_brg|Equal0~2_combout\)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|Equal0~0_combout\,
	datab => \u_tx|u_brg|Equal0~1_combout\,
	datac => \u_tx|u_brg|Equal0~3_combout\,
	datad => \u_tx|u_brg|Equal0~2_combout\,
	combout => \u_tx|u_brg|Equal0~4_combout\);

-- Location: LCCOMB_X25_Y9_N4
\u_tx|u_brg|Equal0~5\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|Equal0~5_combout\ = (\u_tx|u_brg|counter\(16)) # (\u_tx|u_brg|counter\(17))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111001100",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|u_brg|counter\(16),
	datad => \u_tx|u_brg|counter\(17),
	combout => \u_tx|u_brg|Equal0~5_combout\);

-- Location: LCCOMB_X25_Y9_N18
\u_tx|u_brg|Equal0~6\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|Equal0~6_combout\ = (\u_tx|u_brg|counter\(23)) # ((\u_tx|u_brg|counter\(22)) # ((\u_tx|u_brg|counter\(21)) # (\u_tx|u_brg|counter\(20))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(23),
	datab => \u_tx|u_brg|counter\(22),
	datac => \u_tx|u_brg|counter\(21),
	datad => \u_tx|u_brg|counter\(20),
	combout => \u_tx|u_brg|Equal0~6_combout\);

-- Location: LCCOMB_X25_Y9_N20
\u_tx|u_brg|Equal0~7\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|Equal0~7_combout\ = (\u_tx|u_brg|counter\(19)) # ((\u_tx|u_brg|counter\(18)) # ((\u_tx|u_brg|Equal0~5_combout\) # (\u_tx|u_brg|Equal0~6_combout\)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter\(19),
	datab => \u_tx|u_brg|counter\(18),
	datac => \u_tx|u_brg|Equal0~5_combout\,
	datad => \u_tx|u_brg|Equal0~6_combout\,
	combout => \u_tx|u_brg|Equal0~7_combout\);

-- Location: LCCOMB_X25_Y9_N10
\u_tx|u_brg|Equal0~10\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|Equal0~10_combout\ = (\u_tx|u_brg|Equal0~8_combout\) # ((\u_tx|u_brg|Equal0~9_combout\) # ((\u_tx|u_brg|Equal0~4_combout\) # (\u_tx|u_brg|Equal0~7_combout\)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|Equal0~8_combout\,
	datab => \u_tx|u_brg|Equal0~9_combout\,
	datac => \u_tx|u_brg|Equal0~4_combout\,
	datad => \u_tx|u_brg|Equal0~7_combout\,
	combout => \u_tx|u_brg|Equal0~10_combout\);

-- Location: LCCOMB_X25_Y9_N30
\u_tx|u_brg|counter[31]~32\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|counter[31]~32_combout\ = ((!\u_tx|u_brg|Equal0~10_combout\) # (!\rst_n~input_o\)) # (!\u_tx|state.IDLE~q\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011111111111111",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|state.IDLE~q\,
	datac => \rst_n~input_o\,
	datad => \u_tx|u_brg|Equal0~10_combout\,
	combout => \u_tx|u_brg|counter[31]~32_combout\);

-- Location: IOIBUF_X34_Y9_N1
\w~input\ : cycloneive_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_w,
	o => \w~input_o\);

-- Location: LCCOMB_X26_Y9_N4
\u_tx|state~19\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|state~19_combout\ = (\u_tx|state.DATA_BITS~q\ & \rst_n~input_o\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100110000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|state.DATA_BITS~q\,
	datad => \rst_n~input_o\,
	combout => \u_tx|state~19_combout\);

-- Location: LCCOMB_X28_Y9_N16
\u_tx|state~22\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|state~22_combout\ = (\rst_n~input_o\ & (!\u_tx|state.IDLE~q\ & \w~input_o\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000110000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \rst_n~input_o\,
	datac => \u_tx|state.IDLE~q\,
	datad => \w~input_o\,
	combout => \u_tx|state~22_combout\);

-- Location: LCCOMB_X25_Y9_N16
\u_tx|state~23\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|state~23_combout\ = (\u_tx|state~22_combout\) # ((\u_tx|state.START_BIT~q\ & ((\u_tx|state~17_combout\) # (!\u_tx|u_brg|counter[31]~32_combout\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111110011011100",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter[31]~32_combout\,
	datab => \u_tx|state~22_combout\,
	datac => \u_tx|state.START_BIT~q\,
	datad => \u_tx|state~17_combout\,
	combout => \u_tx|state~23_combout\);

-- Location: FF_X25_Y9_N17
\u_tx|state.START_BIT\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|state~23_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|state.START_BIT~q\);

-- Location: LCCOMB_X26_Y9_N14
\u_tx|state~20\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|state~20_combout\ = (\u_tx|state.IDLE~q\ & (\u_tx|state.START_BIT~q\ & \rst_n~input_o\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|state.IDLE~q\,
	datac => \u_tx|state.START_BIT~q\,
	datad => \rst_n~input_o\,
	combout => \u_tx|state~20_combout\);

-- Location: LCCOMB_X26_Y9_N6
\u_tx|state~13\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|state~13_combout\ = (\w~input_o\ & !\u_tx|state.IDLE~q\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000000011110000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \w~input_o\,
	datad => \u_tx|state.IDLE~q\,
	combout => \u_tx|state~13_combout\);

-- Location: LCCOMB_X26_Y9_N16
\u_tx|u_brg|baud_tick~0\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_brg|baud_tick~0_combout\ = (\u_tx|state.IDLE~q\ & !\u_tx|u_brg|Equal0~10_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000000011001100",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|state.IDLE~q\,
	datad => \u_tx|u_brg|Equal0~10_combout\,
	combout => \u_tx|u_brg|baud_tick~0_combout\);

-- Location: LCCOMB_X26_Y9_N24
\u_tx|state~15\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|state~15_combout\ = (\u_tx|state~13_combout\ & (((!\u_tx|state~14_combout\ & \u_tx|u_brg|baud_tick~0_combout\)) # (!\u_tx|state.DATA_BITS~q\))) # (!\u_tx|state~13_combout\ & (((!\u_tx|state~14_combout\ & \u_tx|u_brg|baud_tick~0_combout\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0010111100100010",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|state~13_combout\,
	datab => \u_tx|state.DATA_BITS~q\,
	datac => \u_tx|state~14_combout\,
	datad => \u_tx|u_brg|baud_tick~0_combout\,
	combout => \u_tx|state~15_combout\);

-- Location: LCCOMB_X26_Y9_N30
\u_tx|state~21\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|state~21_combout\ = (\u_tx|state~15_combout\ & (!\u_tx|u_brg|Equal0~10_combout\ & ((\u_tx|state~20_combout\)))) # (!\u_tx|state~15_combout\ & (((\u_tx|state~19_combout\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101000011001100",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|Equal0~10_combout\,
	datab => \u_tx|state~19_combout\,
	datac => \u_tx|state~20_combout\,
	datad => \u_tx|state~15_combout\,
	combout => \u_tx|state~21_combout\);

-- Location: FF_X26_Y9_N31
\u_tx|state.DATA_BITS\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|state~21_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|state.DATA_BITS~q\);

-- Location: LCCOMB_X26_Y9_N22
\u_tx|count~7\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|count~7_combout\ = (\u_tx|state.DATA_BITS~q\ & (!\u_tx|count\(0) & \rst_n~input_o\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000110000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_tx|state.DATA_BITS~q\,
	datac => \u_tx|count\(0),
	datad => \rst_n~input_o\,
	combout => \u_tx|count~7_combout\);

-- Location: LCCOMB_X26_Y9_N8
\u_tx|count[1]~5\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|count[1]~5_combout\ = (\u_tx|state.START_BIT~q\) # (\u_tx|state.DATA_BITS~q\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111110000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_tx|state.START_BIT~q\,
	datad => \u_tx|state.DATA_BITS~q\,
	combout => \u_tx|count[1]~5_combout\);

-- Location: LCCOMB_X26_Y9_N2
\u_tx|count[1]~6\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|count[1]~6_combout\ = ((!\u_tx|state.STOP_BIT~q\ & ((\u_tx|u_brg|baud_tick~0_combout\) # (!\u_tx|count[1]~5_combout\)))) # (!\rst_n~input_o\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0111011101010111",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \rst_n~input_o\,
	datab => \u_tx|state.STOP_BIT~q\,
	datac => \u_tx|count[1]~5_combout\,
	datad => \u_tx|u_brg|baud_tick~0_combout\,
	combout => \u_tx|count[1]~6_combout\);

-- Location: FF_X26_Y9_N23
\u_tx|count[0]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|count~7_combout\,
	ena => \u_tx|count[1]~6_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|count\(0));

-- Location: LCCOMB_X26_Y9_N12
\u_tx|count~8\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|count~8_combout\ = (\u_tx|state.DATA_BITS~q\ & (\rst_n~input_o\ & (\u_tx|count\(0) $ (\u_tx|count\(1)))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0100100000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|count\(0),
	datab => \u_tx|state.DATA_BITS~q\,
	datac => \u_tx|count\(1),
	datad => \rst_n~input_o\,
	combout => \u_tx|count~8_combout\);

-- Location: FF_X26_Y9_N13
\u_tx|count[1]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|count~8_combout\,
	ena => \u_tx|count[1]~6_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|count\(1));

-- Location: LCCOMB_X26_Y9_N10
\u_tx|count~4\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|count~4_combout\ = (\u_tx|state~19_combout\ & (\u_tx|count\(2) $ (((\u_tx|count\(0) & \u_tx|count\(1))))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0100100011000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|count\(0),
	datab => \u_tx|state~19_combout\,
	datac => \u_tx|count\(2),
	datad => \u_tx|count\(1),
	combout => \u_tx|count~4_combout\);

-- Location: FF_X26_Y9_N11
\u_tx|count[2]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|count~4_combout\,
	ena => \u_tx|count[1]~6_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|count\(2));

-- Location: LCCOMB_X26_Y9_N0
\u_tx|Equal0~0\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|Equal0~0_combout\ = ((!\u_tx|count\(2)) # (!\u_tx|count\(0))) # (!\u_tx|count\(1))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101111111111111",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|count\(1),
	datac => \u_tx|count\(0),
	datad => \u_tx|count\(2),
	combout => \u_tx|Equal0~0_combout\);

-- Location: LCCOMB_X26_Y9_N26
\u_tx|state~14\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|state~14_combout\ = (!\u_tx|state.START_BIT~q\ & (!\u_tx|state.STOP_BIT~q\ & ((\u_tx|Equal0~0_combout\) # (!\u_tx|state.DATA_BITS~q\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000000000001101",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|state.DATA_BITS~q\,
	datab => \u_tx|Equal0~0_combout\,
	datac => \u_tx|state.START_BIT~q\,
	datad => \u_tx|state.STOP_BIT~q\,
	combout => \u_tx|state~14_combout\);

-- Location: LCCOMB_X26_Y9_N18
\u_tx|state~17\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|state~17_combout\ = (\rst_n~input_o\ & ((\u_tx|state.IDLE~q\ & ((\u_tx|state~14_combout\))) # (!\u_tx|state.IDLE~q\ & (!\w~input_o\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1101000100000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \w~input_o\,
	datab => \u_tx|state.IDLE~q\,
	datac => \u_tx|state~14_combout\,
	datad => \rst_n~input_o\,
	combout => \u_tx|state~17_combout\);

-- Location: LCCOMB_X28_Y9_N20
\u_tx|state~16\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|state~16_combout\ = (\u_tx|state.DATA_BITS~q\ & (\u_tx|tx_busy_r~0_combout\ & (!\u_tx|Equal0~0_combout\ & !\u_tx|u_brg|Equal0~10_combout\)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000000000001000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|state.DATA_BITS~q\,
	datab => \u_tx|tx_busy_r~0_combout\,
	datac => \u_tx|Equal0~0_combout\,
	datad => \u_tx|u_brg|Equal0~10_combout\,
	combout => \u_tx|state~16_combout\);

-- Location: LCCOMB_X28_Y9_N6
\u_tx|state~18\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|state~18_combout\ = (\u_tx|u_brg|counter[31]~32_combout\ & ((\u_tx|state~17_combout\ & (\u_tx|state.STOP_BIT~q\)) # (!\u_tx|state~17_combout\ & ((\u_tx|state~16_combout\))))) # (!\u_tx|u_brg|counter[31]~32_combout\ & (((\u_tx|state.STOP_BIT~q\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111001011010000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_brg|counter[31]~32_combout\,
	datab => \u_tx|state~17_combout\,
	datac => \u_tx|state.STOP_BIT~q\,
	datad => \u_tx|state~16_combout\,
	combout => \u_tx|state~18_combout\);

-- Location: FF_X28_Y9_N7
\u_tx|state.STOP_BIT\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|state~18_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|state.STOP_BIT~q\);

-- Location: LCCOMB_X26_Y9_N20
\u_tx|state~12\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|state~12_combout\ = ((\u_tx|state.IDLE~q\ & (\u_tx|state.STOP_BIT~q\ & !\u_tx|u_brg|Equal0~10_combout\))) # (!\rst_n~input_o\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101010111010101",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \rst_n~input_o\,
	datab => \u_tx|state.IDLE~q\,
	datac => \u_tx|state.STOP_BIT~q\,
	datad => \u_tx|u_brg|Equal0~10_combout\,
	combout => \u_tx|state~12_combout\);

-- Location: LCCOMB_X26_Y9_N28
\u_tx|state~24\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|state~24_combout\ = (\u_tx|state~15_combout\ & (((!\u_tx|state~12_combout\)))) # (!\u_tx|state~15_combout\ & (\rst_n~input_o\ & ((\u_tx|state.IDLE~q\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011001110100000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \rst_n~input_o\,
	datab => \u_tx|state~12_combout\,
	datac => \u_tx|state.IDLE~q\,
	datad => \u_tx|state~15_combout\,
	combout => \u_tx|state~24_combout\);

-- Location: FF_X26_Y9_N29
\u_tx|state.IDLE\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|state~24_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|state.IDLE~q\);

-- Location: LCCOMB_X28_Y9_N28
\u_tx|tx_busy_r~0\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|tx_busy_r~0_combout\ = (\u_tx|state.IDLE~q\ & \rst_n~input_o\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010000010100000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|state.IDLE~q\,
	datac => \rst_n~input_o\,
	combout => \u_tx|tx_busy_r~0_combout\);

-- Location: LCCOMB_X28_Y9_N0
\u_tx|tx_busy_r~feeder\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|tx_busy_r~feeder_combout\ = \u_tx|tx_busy_r~0_combout\

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111100000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datad => \u_tx|tx_busy_r~0_combout\,
	combout => \u_tx|tx_busy_r~feeder_combout\);

-- Location: FF_X28_Y9_N1
\u_tx|tx_busy_r\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|tx_busy_r~feeder_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|tx_busy_r~q\);

-- Location: IOIBUF_X32_Y0_N15
\data_line_rx~input\ : cycloneive_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_data_line_rx,
	o => \data_line_rx~input_o\);

-- Location: LCCOMB_X25_Y2_N30
\u_rx|data_in_meta~0\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|data_in_meta~0_combout\ = (\rst_n~input_o\ & !\data_line_rx~input_o\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000000011110000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \rst_n~input_o\,
	datad => \data_line_rx~input_o\,
	combout => \u_rx|data_in_meta~0_combout\);

-- Location: FF_X24_Y2_N31
\u_rx|data_in_meta\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	asdata => \u_rx|data_in_meta~0_combout\,
	sload => VCC,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|data_in_meta~q\);

-- Location: LCCOMB_X23_Y2_N2
\u_rx|data_in_sync~0\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|data_in_sync~0_combout\ = (\rst_n~input_o\ & \u_rx|data_in_meta~q\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100000011000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \rst_n~input_o\,
	datac => \u_rx|data_in_meta~q\,
	combout => \u_rx|data_in_sync~0_combout\);

-- Location: FF_X23_Y2_N3
\u_rx|data_in_sync\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|data_in_sync~0_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|data_in_sync~q\);

-- Location: IOIBUF_X18_Y0_N22
\r~input\ : cycloneive_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_r,
	o => \r~input_o\);

-- Location: LCCOMB_X23_Y2_N8
\u_rx|state~20\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~20_combout\ = (\r~input_o\ & !\u_rx|state.IDLE~q\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000000011110000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \r~input_o\,
	datad => \u_rx|state.IDLE~q\,
	combout => \u_rx|state~20_combout\);

-- Location: LCCOMB_X23_Y2_N24
\u_rx|baud_enable~2\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|baud_enable~2_combout\ = (\u_rx|state.WAIT_START_BIT~q\ & ((\u_rx|data_in_sync~q\))) # (!\u_rx|state.WAIT_START_BIT~q\ & (\u_rx|state.IDLE~q\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100110010101010",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|state.IDLE~q\,
	datab => \u_rx|data_in_sync~q\,
	datad => \u_rx|state.WAIT_START_BIT~q\,
	combout => \u_rx|baud_enable~2_combout\);

-- Location: LCCOMB_X23_Y2_N26
\u_rx|u_brg|counter~1\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|counter~1_combout\ = (\rst_n~input_o\ & ((\u_rx|state.WAIT_START_BIT~q\ & ((!\u_rx|data_in_sync~q\))) # (!\u_rx|state.WAIT_START_BIT~q\ & (!\u_rx|state.IDLE~q\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011000001010000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|state.IDLE~q\,
	datab => \u_rx|data_in_sync~q\,
	datac => \rst_n~input_o\,
	datad => \u_rx|state.WAIT_START_BIT~q\,
	combout => \u_rx|u_brg|counter~1_combout\);

-- Location: LCCOMB_X24_Y5_N0
\u_rx|u_brg|Add0~0\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~0_combout\ = \u_rx|u_brg|counter\(0) $ (VCC)
-- \u_rx|u_brg|Add0~1\ = CARRY(\u_rx|u_brg|counter\(0))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011001111001100",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(0),
	datad => VCC,
	combout => \u_rx|u_brg|Add0~0_combout\,
	cout => \u_rx|u_brg|Add0~1\);

-- Location: LCCOMB_X24_Y5_N10
\u_rx|u_brg|Add0~10\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~10_combout\ = (\u_rx|u_brg|counter\(5) & (!\u_rx|u_brg|Add0~9\)) # (!\u_rx|u_brg|counter\(5) & ((\u_rx|u_brg|Add0~9\) # (GND)))
-- \u_rx|u_brg|Add0~11\ = CARRY((!\u_rx|u_brg|Add0~9\) # (!\u_rx|u_brg|counter\(5)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(5),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~9\,
	combout => \u_rx|u_brg|Add0~10_combout\,
	cout => \u_rx|u_brg|Add0~11\);

-- Location: LCCOMB_X24_Y5_N12
\u_rx|u_brg|Add0~12\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~12_combout\ = (\u_rx|u_brg|counter\(6) & (\u_rx|u_brg|Add0~11\ $ (GND))) # (!\u_rx|u_brg|counter\(6) & (!\u_rx|u_brg|Add0~11\ & VCC))
-- \u_rx|u_brg|Add0~13\ = CARRY((\u_rx|u_brg|counter\(6) & !\u_rx|u_brg|Add0~11\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010010100001010",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(6),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~11\,
	combout => \u_rx|u_brg|Add0~12_combout\,
	cout => \u_rx|u_brg|Add0~13\);

-- Location: LCCOMB_X23_Y5_N2
\u_rx|u_brg|counter~2\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|counter~2_combout\ = (\u_rx|u_brg|counter~1_combout\) # ((\u_rx|u_brg|Add0~12_combout\ & \u_rx|u_brg|counter[10]~0_combout\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111101010101010",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter~1_combout\,
	datac => \u_rx|u_brg|Add0~12_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|counter~2_combout\);

-- Location: FF_X23_Y5_N3
\u_rx|u_brg|counter[6]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|counter~2_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(6));

-- Location: LCCOMB_X24_Y5_N14
\u_rx|u_brg|Add0~14\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~14_combout\ = (\u_rx|u_brg|counter\(7) & (!\u_rx|u_brg|Add0~13\)) # (!\u_rx|u_brg|counter\(7) & ((\u_rx|u_brg|Add0~13\) # (GND)))
-- \u_rx|u_brg|Add0~15\ = CARRY((!\u_rx|u_brg|Add0~13\) # (!\u_rx|u_brg|counter\(7)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(7),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~13\,
	combout => \u_rx|u_brg|Add0~14_combout\,
	cout => \u_rx|u_brg|Add0~15\);

-- Location: LCCOMB_X23_Y5_N4
\u_rx|u_brg|counter~3\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|counter~3_combout\ = (\u_rx|u_brg|counter~1_combout\) # ((\u_rx|u_brg|Add0~14_combout\ & \u_rx|u_brg|counter[10]~0_combout\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111101010101010",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter~1_combout\,
	datac => \u_rx|u_brg|Add0~14_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|counter~3_combout\);

-- Location: FF_X23_Y5_N5
\u_rx|u_brg|counter[7]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|counter~3_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(7));

-- Location: LCCOMB_X24_Y5_N16
\u_rx|u_brg|Add0~16\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~16_combout\ = (\u_rx|u_brg|counter\(8) & (\u_rx|u_brg|Add0~15\ $ (GND))) # (!\u_rx|u_brg|counter\(8) & (!\u_rx|u_brg|Add0~15\ & VCC))
-- \u_rx|u_brg|Add0~17\ = CARRY((\u_rx|u_brg|counter\(8) & !\u_rx|u_brg|Add0~15\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(8),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~15\,
	combout => \u_rx|u_brg|Add0~16_combout\,
	cout => \u_rx|u_brg|Add0~17\);

-- Location: LCCOMB_X23_Y5_N30
\u_rx|u_brg|Add0~87\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~87_combout\ = (\u_rx|u_brg|Add0~16_combout\ & \u_rx|u_brg|counter[10]~0_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100110000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|Add0~16_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|Add0~87_combout\);

-- Location: FF_X23_Y5_N31
\u_rx|u_brg|counter[8]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~87_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(8));

-- Location: LCCOMB_X24_Y5_N18
\u_rx|u_brg|Add0~18\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~18_combout\ = (\u_rx|u_brg|counter\(9) & (!\u_rx|u_brg|Add0~17\)) # (!\u_rx|u_brg|counter\(9) & ((\u_rx|u_brg|Add0~17\) # (GND)))
-- \u_rx|u_brg|Add0~19\ = CARRY((!\u_rx|u_brg|Add0~17\) # (!\u_rx|u_brg|counter\(9)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(9),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~17\,
	combout => \u_rx|u_brg|Add0~18_combout\,
	cout => \u_rx|u_brg|Add0~19\);

-- Location: LCCOMB_X23_Y5_N20
\u_rx|u_brg|Add0~86\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~86_combout\ = (\u_rx|u_brg|Add0~18_combout\ & \u_rx|u_brg|counter[10]~0_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100110000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|Add0~18_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|Add0~86_combout\);

-- Location: FF_X23_Y5_N21
\u_rx|u_brg|counter[9]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~86_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(9));

-- Location: LCCOMB_X24_Y5_N20
\u_rx|u_brg|Add0~20\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~20_combout\ = (\u_rx|u_brg|counter\(10) & (\u_rx|u_brg|Add0~19\ $ (GND))) # (!\u_rx|u_brg|counter\(10) & (!\u_rx|u_brg|Add0~19\ & VCC))
-- \u_rx|u_brg|Add0~21\ = CARRY((\u_rx|u_brg|counter\(10) & !\u_rx|u_brg|Add0~19\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010010100001010",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(10),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~19\,
	combout => \u_rx|u_brg|Add0~20_combout\,
	cout => \u_rx|u_brg|Add0~21\);

-- Location: LCCOMB_X23_Y5_N26
\u_rx|u_brg|Add0~85\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~85_combout\ = (\u_rx|u_brg|Add0~20_combout\ & \u_rx|u_brg|counter[10]~0_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|u_brg|Add0~20_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|Add0~85_combout\);

-- Location: FF_X23_Y5_N27
\u_rx|u_brg|counter[10]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~85_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(10));

-- Location: LCCOMB_X24_Y5_N22
\u_rx|u_brg|Add0~22\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~22_combout\ = (\u_rx|u_brg|counter\(11) & (!\u_rx|u_brg|Add0~21\)) # (!\u_rx|u_brg|counter\(11) & ((\u_rx|u_brg|Add0~21\) # (GND)))
-- \u_rx|u_brg|Add0~23\ = CARRY((!\u_rx|u_brg|Add0~21\) # (!\u_rx|u_brg|counter\(11)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(11),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~21\,
	combout => \u_rx|u_brg|Add0~22_combout\,
	cout => \u_rx|u_brg|Add0~23\);

-- Location: LCCOMB_X23_Y5_N16
\u_rx|u_brg|Add0~84\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~84_combout\ = (\u_rx|u_brg|Add0~22_combout\ & \u_rx|u_brg|counter[10]~0_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|u_brg|Add0~22_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|Add0~84_combout\);

-- Location: FF_X23_Y5_N17
\u_rx|u_brg|counter[11]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~84_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(11));

-- Location: LCCOMB_X24_Y5_N24
\u_rx|u_brg|Add0~24\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~24_combout\ = (\u_rx|u_brg|counter\(12) & (\u_rx|u_brg|Add0~23\ $ (GND))) # (!\u_rx|u_brg|counter\(12) & (!\u_rx|u_brg|Add0~23\ & VCC))
-- \u_rx|u_brg|Add0~25\ = CARRY((\u_rx|u_brg|counter\(12) & !\u_rx|u_brg|Add0~23\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(12),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~23\,
	combout => \u_rx|u_brg|Add0~24_combout\,
	cout => \u_rx|u_brg|Add0~25\);

-- Location: LCCOMB_X25_Y5_N22
\u_rx|u_brg|Add0~83\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~83_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~24_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~24_combout\,
	combout => \u_rx|u_brg|Add0~83_combout\);

-- Location: FF_X25_Y5_N23
\u_rx|u_brg|counter[12]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~83_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(12));

-- Location: LCCOMB_X24_Y5_N26
\u_rx|u_brg|Add0~26\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~26_combout\ = (\u_rx|u_brg|counter\(13) & (!\u_rx|u_brg|Add0~25\)) # (!\u_rx|u_brg|counter\(13) & ((\u_rx|u_brg|Add0~25\) # (GND)))
-- \u_rx|u_brg|Add0~27\ = CARRY((!\u_rx|u_brg|Add0~25\) # (!\u_rx|u_brg|counter\(13)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(13),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~25\,
	combout => \u_rx|u_brg|Add0~26_combout\,
	cout => \u_rx|u_brg|Add0~27\);

-- Location: LCCOMB_X25_Y5_N12
\u_rx|u_brg|Add0~82\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~82_combout\ = (\u_rx|u_brg|Add0~26_combout\ & \u_rx|u_brg|counter[10]~0_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010000010100000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|Add0~26_combout\,
	datac => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|Add0~82_combout\);

-- Location: FF_X25_Y5_N13
\u_rx|u_brg|counter[13]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~82_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(13));

-- Location: LCCOMB_X24_Y5_N28
\u_rx|u_brg|Add0~28\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~28_combout\ = (\u_rx|u_brg|counter\(14) & (\u_rx|u_brg|Add0~27\ $ (GND))) # (!\u_rx|u_brg|counter\(14) & (!\u_rx|u_brg|Add0~27\ & VCC))
-- \u_rx|u_brg|Add0~29\ = CARRY((\u_rx|u_brg|counter\(14) & !\u_rx|u_brg|Add0~27\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(14),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~27\,
	combout => \u_rx|u_brg|Add0~28_combout\,
	cout => \u_rx|u_brg|Add0~29\);

-- Location: LCCOMB_X25_Y5_N18
\u_rx|u_brg|Add0~81\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~81_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~28_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~28_combout\,
	combout => \u_rx|u_brg|Add0~81_combout\);

-- Location: FF_X25_Y5_N19
\u_rx|u_brg|counter[14]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~81_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(14));

-- Location: LCCOMB_X24_Y5_N30
\u_rx|u_brg|Add0~30\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~30_combout\ = (\u_rx|u_brg|counter\(15) & (!\u_rx|u_brg|Add0~29\)) # (!\u_rx|u_brg|counter\(15) & ((\u_rx|u_brg|Add0~29\) # (GND)))
-- \u_rx|u_brg|Add0~31\ = CARRY((!\u_rx|u_brg|Add0~29\) # (!\u_rx|u_brg|counter\(15)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(15),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~29\,
	combout => \u_rx|u_brg|Add0~30_combout\,
	cout => \u_rx|u_brg|Add0~31\);

-- Location: LCCOMB_X25_Y5_N8
\u_rx|u_brg|Add0~80\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~80_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~30_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~30_combout\,
	combout => \u_rx|u_brg|Add0~80_combout\);

-- Location: FF_X25_Y5_N9
\u_rx|u_brg|counter[15]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~80_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(15));

-- Location: LCCOMB_X24_Y4_N0
\u_rx|u_brg|Add0~32\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~32_combout\ = (\u_rx|u_brg|counter\(16) & (\u_rx|u_brg|Add0~31\ $ (GND))) # (!\u_rx|u_brg|counter\(16) & (!\u_rx|u_brg|Add0~31\ & VCC))
-- \u_rx|u_brg|Add0~33\ = CARRY((\u_rx|u_brg|counter\(16) & !\u_rx|u_brg|Add0~31\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010010100001010",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(16),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~31\,
	combout => \u_rx|u_brg|Add0~32_combout\,
	cout => \u_rx|u_brg|Add0~33\);

-- Location: LCCOMB_X25_Y4_N2
\u_rx|u_brg|Add0~79\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~79_combout\ = (\u_rx|u_brg|Add0~32_combout\ & \u_rx|u_brg|counter[10]~0_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010101000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|Add0~32_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|Add0~79_combout\);

-- Location: FF_X25_Y4_N3
\u_rx|u_brg|counter[16]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~79_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(16));

-- Location: LCCOMB_X24_Y4_N2
\u_rx|u_brg|Add0~34\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~34_combout\ = (\u_rx|u_brg|counter\(17) & (!\u_rx|u_brg|Add0~33\)) # (!\u_rx|u_brg|counter\(17) & ((\u_rx|u_brg|Add0~33\) # (GND)))
-- \u_rx|u_brg|Add0~35\ = CARRY((!\u_rx|u_brg|Add0~33\) # (!\u_rx|u_brg|counter\(17)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(17),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~33\,
	combout => \u_rx|u_brg|Add0~34_combout\,
	cout => \u_rx|u_brg|Add0~35\);

-- Location: LCCOMB_X25_Y4_N0
\u_rx|u_brg|Add0~78\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~78_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~34_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~34_combout\,
	combout => \u_rx|u_brg|Add0~78_combout\);

-- Location: FF_X25_Y4_N1
\u_rx|u_brg|counter[17]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~78_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(17));

-- Location: LCCOMB_X24_Y4_N4
\u_rx|u_brg|Add0~36\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~36_combout\ = (\u_rx|u_brg|counter\(18) & (\u_rx|u_brg|Add0~35\ $ (GND))) # (!\u_rx|u_brg|counter\(18) & (!\u_rx|u_brg|Add0~35\ & VCC))
-- \u_rx|u_brg|Add0~37\ = CARRY((\u_rx|u_brg|counter\(18) & !\u_rx|u_brg|Add0~35\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010010100001010",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(18),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~35\,
	combout => \u_rx|u_brg|Add0~36_combout\,
	cout => \u_rx|u_brg|Add0~37\);

-- Location: LCCOMB_X25_Y4_N30
\u_rx|u_brg|Add0~77\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~77_combout\ = (\u_rx|u_brg|Add0~36_combout\ & \u_rx|u_brg|counter[10]~0_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|u_brg|Add0~36_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|Add0~77_combout\);

-- Location: FF_X25_Y4_N31
\u_rx|u_brg|counter[18]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~77_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(18));

-- Location: LCCOMB_X24_Y4_N6
\u_rx|u_brg|Add0~38\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~38_combout\ = (\u_rx|u_brg|counter\(19) & (!\u_rx|u_brg|Add0~37\)) # (!\u_rx|u_brg|counter\(19) & ((\u_rx|u_brg|Add0~37\) # (GND)))
-- \u_rx|u_brg|Add0~39\ = CARRY((!\u_rx|u_brg|Add0~37\) # (!\u_rx|u_brg|counter\(19)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(19),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~37\,
	combout => \u_rx|u_brg|Add0~38_combout\,
	cout => \u_rx|u_brg|Add0~39\);

-- Location: LCCOMB_X25_Y4_N4
\u_rx|u_brg|Add0~76\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~76_combout\ = (\u_rx|u_brg|Add0~38_combout\ & \u_rx|u_brg|counter[10]~0_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|u_brg|Add0~38_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|Add0~76_combout\);

-- Location: FF_X25_Y4_N5
\u_rx|u_brg|counter[19]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~76_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(19));

-- Location: LCCOMB_X24_Y4_N8
\u_rx|u_brg|Add0~40\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~40_combout\ = (\u_rx|u_brg|counter\(20) & (\u_rx|u_brg|Add0~39\ $ (GND))) # (!\u_rx|u_brg|counter\(20) & (!\u_rx|u_brg|Add0~39\ & VCC))
-- \u_rx|u_brg|Add0~41\ = CARRY((\u_rx|u_brg|counter\(20) & !\u_rx|u_brg|Add0~39\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(20),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~39\,
	combout => \u_rx|u_brg|Add0~40_combout\,
	cout => \u_rx|u_brg|Add0~41\);

-- Location: LCCOMB_X25_Y4_N12
\u_rx|u_brg|Add0~75\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~75_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~40_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010101000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~40_combout\,
	combout => \u_rx|u_brg|Add0~75_combout\);

-- Location: FF_X25_Y4_N13
\u_rx|u_brg|counter[20]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~75_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(20));

-- Location: LCCOMB_X24_Y4_N10
\u_rx|u_brg|Add0~42\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~42_combout\ = (\u_rx|u_brg|counter\(21) & (!\u_rx|u_brg|Add0~41\)) # (!\u_rx|u_brg|counter\(21) & ((\u_rx|u_brg|Add0~41\) # (GND)))
-- \u_rx|u_brg|Add0~43\ = CARRY((!\u_rx|u_brg|Add0~41\) # (!\u_rx|u_brg|counter\(21)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(21),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~41\,
	combout => \u_rx|u_brg|Add0~42_combout\,
	cout => \u_rx|u_brg|Add0~43\);

-- Location: LCCOMB_X25_Y4_N26
\u_rx|u_brg|Add0~74\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~74_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~42_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010101000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~42_combout\,
	combout => \u_rx|u_brg|Add0~74_combout\);

-- Location: FF_X25_Y4_N27
\u_rx|u_brg|counter[21]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~74_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(21));

-- Location: LCCOMB_X24_Y4_N12
\u_rx|u_brg|Add0~44\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~44_combout\ = (\u_rx|u_brg|counter\(22) & (\u_rx|u_brg|Add0~43\ $ (GND))) # (!\u_rx|u_brg|counter\(22) & (!\u_rx|u_brg|Add0~43\ & VCC))
-- \u_rx|u_brg|Add0~45\ = CARRY((\u_rx|u_brg|counter\(22) & !\u_rx|u_brg|Add0~43\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010010100001010",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(22),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~43\,
	combout => \u_rx|u_brg|Add0~44_combout\,
	cout => \u_rx|u_brg|Add0~45\);

-- Location: LCCOMB_X25_Y4_N20
\u_rx|u_brg|Add0~73\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~73_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~44_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010101000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~44_combout\,
	combout => \u_rx|u_brg|Add0~73_combout\);

-- Location: FF_X25_Y4_N21
\u_rx|u_brg|counter[22]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~73_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(22));

-- Location: LCCOMB_X24_Y4_N14
\u_rx|u_brg|Add0~46\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~46_combout\ = (\u_rx|u_brg|counter\(23) & (!\u_rx|u_brg|Add0~45\)) # (!\u_rx|u_brg|counter\(23) & ((\u_rx|u_brg|Add0~45\) # (GND)))
-- \u_rx|u_brg|Add0~47\ = CARRY((!\u_rx|u_brg|Add0~45\) # (!\u_rx|u_brg|counter\(23)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(23),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~45\,
	combout => \u_rx|u_brg|Add0~46_combout\,
	cout => \u_rx|u_brg|Add0~47\);

-- Location: LCCOMB_X25_Y4_N22
\u_rx|u_brg|Add0~72\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~72_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~46_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010101000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~46_combout\,
	combout => \u_rx|u_brg|Add0~72_combout\);

-- Location: FF_X25_Y4_N23
\u_rx|u_brg|counter[23]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~72_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(23));

-- Location: LCCOMB_X25_Y4_N10
\u_rx|u_brg|Equal0~2\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Equal0~2_combout\ = (\u_rx|u_brg|counter\(23)) # ((\u_rx|u_brg|counter\(22)) # ((\u_rx|u_brg|counter\(21)) # (\u_rx|u_brg|counter\(20))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(23),
	datab => \u_rx|u_brg|counter\(22),
	datac => \u_rx|u_brg|counter\(21),
	datad => \u_rx|u_brg|counter\(20),
	combout => \u_rx|u_brg|Equal0~2_combout\);

-- Location: LCCOMB_X25_Y4_N28
\u_rx|u_brg|Equal0~3\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Equal0~3_combout\ = (\u_rx|u_brg|counter\(18)) # ((\u_rx|u_brg|counter\(17)) # ((\u_rx|u_brg|counter\(19)) # (\u_rx|u_brg|counter\(16))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(18),
	datab => \u_rx|u_brg|counter\(17),
	datac => \u_rx|u_brg|counter\(19),
	datad => \u_rx|u_brg|counter\(16),
	combout => \u_rx|u_brg|Equal0~3_combout\);

-- Location: LCCOMB_X24_Y4_N16
\u_rx|u_brg|Add0~48\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~48_combout\ = (\u_rx|u_brg|counter\(24) & (\u_rx|u_brg|Add0~47\ $ (GND))) # (!\u_rx|u_brg|counter\(24) & (!\u_rx|u_brg|Add0~47\ & VCC))
-- \u_rx|u_brg|Add0~49\ = CARRY((\u_rx|u_brg|counter\(24) & !\u_rx|u_brg|Add0~47\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(24),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~47\,
	combout => \u_rx|u_brg|Add0~48_combout\,
	cout => \u_rx|u_brg|Add0~49\);

-- Location: LCCOMB_X25_Y4_N18
\u_rx|u_brg|Add0~71\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~71_combout\ = (\u_rx|u_brg|Add0~48_combout\ & \u_rx|u_brg|counter[10]~0_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|u_brg|Add0~48_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|Add0~71_combout\);

-- Location: FF_X25_Y4_N19
\u_rx|u_brg|counter[24]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~71_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(24));

-- Location: LCCOMB_X24_Y4_N18
\u_rx|u_brg|Add0~50\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~50_combout\ = (\u_rx|u_brg|counter\(25) & (!\u_rx|u_brg|Add0~49\)) # (!\u_rx|u_brg|counter\(25) & ((\u_rx|u_brg|Add0~49\) # (GND)))
-- \u_rx|u_brg|Add0~51\ = CARRY((!\u_rx|u_brg|Add0~49\) # (!\u_rx|u_brg|counter\(25)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(25),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~49\,
	combout => \u_rx|u_brg|Add0~50_combout\,
	cout => \u_rx|u_brg|Add0~51\);

-- Location: LCCOMB_X25_Y4_N16
\u_rx|u_brg|Add0~70\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~70_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~50_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010101000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~50_combout\,
	combout => \u_rx|u_brg|Add0~70_combout\);

-- Location: FF_X25_Y4_N17
\u_rx|u_brg|counter[25]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~70_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(25));

-- Location: LCCOMB_X24_Y4_N20
\u_rx|u_brg|Add0~52\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~52_combout\ = (\u_rx|u_brg|counter\(26) & (\u_rx|u_brg|Add0~51\ $ (GND))) # (!\u_rx|u_brg|counter\(26) & (!\u_rx|u_brg|Add0~51\ & VCC))
-- \u_rx|u_brg|Add0~53\ = CARRY((\u_rx|u_brg|counter\(26) & !\u_rx|u_brg|Add0~51\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010010100001010",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(26),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~51\,
	combout => \u_rx|u_brg|Add0~52_combout\,
	cout => \u_rx|u_brg|Add0~53\);

-- Location: LCCOMB_X25_Y4_N6
\u_rx|u_brg|Add0~69\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~69_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~52_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010101000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~52_combout\,
	combout => \u_rx|u_brg|Add0~69_combout\);

-- Location: FF_X25_Y4_N7
\u_rx|u_brg|counter[26]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~69_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(26));

-- Location: LCCOMB_X24_Y4_N22
\u_rx|u_brg|Add0~54\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~54_combout\ = (\u_rx|u_brg|counter\(27) & (!\u_rx|u_brg|Add0~53\)) # (!\u_rx|u_brg|counter\(27) & ((\u_rx|u_brg|Add0~53\) # (GND)))
-- \u_rx|u_brg|Add0~55\ = CARRY((!\u_rx|u_brg|Add0~53\) # (!\u_rx|u_brg|counter\(27)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(27),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~53\,
	combout => \u_rx|u_brg|Add0~54_combout\,
	cout => \u_rx|u_brg|Add0~55\);

-- Location: LCCOMB_X25_Y4_N8
\u_rx|u_brg|Add0~68\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~68_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~54_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010101000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~54_combout\,
	combout => \u_rx|u_brg|Add0~68_combout\);

-- Location: FF_X25_Y4_N9
\u_rx|u_brg|counter[27]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~68_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(27));

-- Location: LCCOMB_X24_Y4_N24
\u_rx|u_brg|Add0~56\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~56_combout\ = (\u_rx|u_brg|counter\(28) & (\u_rx|u_brg|Add0~55\ $ (GND))) # (!\u_rx|u_brg|counter\(28) & (!\u_rx|u_brg|Add0~55\ & VCC))
-- \u_rx|u_brg|Add0~57\ = CARRY((\u_rx|u_brg|counter\(28) & !\u_rx|u_brg|Add0~55\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010010100001010",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(28),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~55\,
	combout => \u_rx|u_brg|Add0~56_combout\,
	cout => \u_rx|u_brg|Add0~57\);

-- Location: LCCOMB_X23_Y4_N26
\u_rx|u_brg|Add0~67\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~67_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~56_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~56_combout\,
	combout => \u_rx|u_brg|Add0~67_combout\);

-- Location: FF_X23_Y4_N27
\u_rx|u_brg|counter[28]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~67_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(28));

-- Location: LCCOMB_X24_Y4_N26
\u_rx|u_brg|Add0~58\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~58_combout\ = (\u_rx|u_brg|counter\(29) & (!\u_rx|u_brg|Add0~57\)) # (!\u_rx|u_brg|counter\(29) & ((\u_rx|u_brg|Add0~57\) # (GND)))
-- \u_rx|u_brg|Add0~59\ = CARRY((!\u_rx|u_brg|Add0~57\) # (!\u_rx|u_brg|counter\(29)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011110000111111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(29),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~57\,
	combout => \u_rx|u_brg|Add0~58_combout\,
	cout => \u_rx|u_brg|Add0~59\);

-- Location: LCCOMB_X23_Y4_N20
\u_rx|u_brg|Add0~66\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~66_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~58_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~58_combout\,
	combout => \u_rx|u_brg|Add0~66_combout\);

-- Location: FF_X23_Y4_N21
\u_rx|u_brg|counter[29]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~66_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(29));

-- Location: LCCOMB_X24_Y4_N28
\u_rx|u_brg|Add0~60\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~60_combout\ = (\u_rx|u_brg|counter\(30) & (\u_rx|u_brg|Add0~59\ $ (GND))) # (!\u_rx|u_brg|counter\(30) & (!\u_rx|u_brg|Add0~59\ & VCC))
-- \u_rx|u_brg|Add0~61\ = CARRY((\u_rx|u_brg|counter\(30) & !\u_rx|u_brg|Add0~59\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100001100001100",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter\(30),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~59\,
	combout => \u_rx|u_brg|Add0~60_combout\,
	cout => \u_rx|u_brg|Add0~61\);

-- Location: LCCOMB_X23_Y4_N30
\u_rx|u_brg|Add0~65\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~65_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~60_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|u_brg|counter[10]~0_combout\,
	datad => \u_rx|u_brg|Add0~60_combout\,
	combout => \u_rx|u_brg|Add0~65_combout\);

-- Location: FF_X23_Y4_N31
\u_rx|u_brg|counter[30]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~65_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(30));

-- Location: LCCOMB_X24_Y4_N30
\u_rx|u_brg|Add0~62\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~62_combout\ = \u_rx|u_brg|Add0~61\ $ (\u_rx|u_brg|counter\(31))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000111111110000",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	datad => \u_rx|u_brg|counter\(31),
	cin => \u_rx|u_brg|Add0~61\,
	combout => \u_rx|u_brg|Add0~62_combout\);

-- Location: LCCOMB_X23_Y4_N24
\u_rx|u_brg|Add0~64\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~64_combout\ = (\u_rx|u_brg|counter[10]~0_combout\ & \u_rx|u_brg|Add0~62_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100000011000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|u_brg|counter[10]~0_combout\,
	datac => \u_rx|u_brg|Add0~62_combout\,
	combout => \u_rx|u_brg|Add0~64_combout\);

-- Location: FF_X23_Y4_N25
\u_rx|u_brg|counter[31]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~64_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(31));

-- Location: LCCOMB_X23_Y4_N28
\u_rx|u_brg|Equal0~0\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Equal0~0_combout\ = (\u_rx|u_brg|counter\(30)) # ((\u_rx|u_brg|counter\(29)) # ((\u_rx|u_brg|counter\(28)) # (\u_rx|u_brg|counter\(31))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(30),
	datab => \u_rx|u_brg|counter\(29),
	datac => \u_rx|u_brg|counter\(28),
	datad => \u_rx|u_brg|counter\(31),
	combout => \u_rx|u_brg|Equal0~0_combout\);

-- Location: LCCOMB_X25_Y4_N24
\u_rx|u_brg|Equal0~1\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Equal0~1_combout\ = (\u_rx|u_brg|counter\(26)) # ((\u_rx|u_brg|counter\(24)) # ((\u_rx|u_brg|counter\(27)) # (\u_rx|u_brg|counter\(25))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(26),
	datab => \u_rx|u_brg|counter\(24),
	datac => \u_rx|u_brg|counter\(27),
	datad => \u_rx|u_brg|counter\(25),
	combout => \u_rx|u_brg|Equal0~1_combout\);

-- Location: LCCOMB_X25_Y4_N14
\u_rx|u_brg|Equal0~4\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Equal0~4_combout\ = (\u_rx|u_brg|Equal0~2_combout\) # ((\u_rx|u_brg|Equal0~3_combout\) # ((\u_rx|u_brg|Equal0~0_combout\) # (\u_rx|u_brg|Equal0~1_combout\)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|Equal0~2_combout\,
	datab => \u_rx|u_brg|Equal0~3_combout\,
	datac => \u_rx|u_brg|Equal0~0_combout\,
	datad => \u_rx|u_brg|Equal0~1_combout\,
	combout => \u_rx|u_brg|Equal0~4_combout\);

-- Location: LCCOMB_X24_Y2_N22
\u_rx|u_brg|counter[10]~0\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|counter[10]~0_combout\ = (\rst_n~input_o\ & (\u_rx|baud_enable~2_combout\ & ((\u_rx|u_brg|Equal0~9_combout\) # (\u_rx|u_brg|Equal0~4_combout\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1000100010000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \rst_n~input_o\,
	datab => \u_rx|baud_enable~2_combout\,
	datac => \u_rx|u_brg|Equal0~9_combout\,
	datad => \u_rx|u_brg|Equal0~4_combout\,
	combout => \u_rx|u_brg|counter[10]~0_combout\);

-- Location: LCCOMB_X23_Y5_N6
\u_rx|u_brg|counter~6\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|counter~6_combout\ = (\u_rx|u_brg|counter~1_combout\) # ((\u_rx|u_brg|Add0~0_combout\ & \u_rx|u_brg|counter[10]~0_combout\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111101010101010",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter~1_combout\,
	datac => \u_rx|u_brg|Add0~0_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|counter~6_combout\);

-- Location: FF_X23_Y5_N7
\u_rx|u_brg|counter[0]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|counter~6_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(0));

-- Location: LCCOMB_X24_Y5_N2
\u_rx|u_brg|Add0~2\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~2_combout\ = (\u_rx|u_brg|counter\(1) & (!\u_rx|u_brg|Add0~1\)) # (!\u_rx|u_brg|counter\(1) & ((\u_rx|u_brg|Add0~1\) # (GND)))
-- \u_rx|u_brg|Add0~3\ = CARRY((!\u_rx|u_brg|Add0~1\) # (!\u_rx|u_brg|counter\(1)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(1),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~1\,
	combout => \u_rx|u_brg|Add0~2_combout\,
	cout => \u_rx|u_brg|Add0~3\);

-- Location: LCCOMB_X23_Y5_N0
\u_rx|u_brg|Add0~90\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~90_combout\ = (\u_rx|u_brg|Add0~2_combout\ & \u_rx|u_brg|counter[10]~0_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010101000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|Add0~2_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|Add0~90_combout\);

-- Location: FF_X23_Y5_N1
\u_rx|u_brg|counter[1]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~90_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(1));

-- Location: LCCOMB_X24_Y5_N4
\u_rx|u_brg|Add0~4\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~4_combout\ = (\u_rx|u_brg|counter\(2) & (\u_rx|u_brg|Add0~3\ $ (GND))) # (!\u_rx|u_brg|counter\(2) & (!\u_rx|u_brg|Add0~3\ & VCC))
-- \u_rx|u_brg|Add0~5\ = CARRY((\u_rx|u_brg|counter\(2) & !\u_rx|u_brg|Add0~3\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010010100001010",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(2),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~3\,
	combout => \u_rx|u_brg|Add0~4_combout\,
	cout => \u_rx|u_brg|Add0~5\);

-- Location: LCCOMB_X23_Y5_N14
\u_rx|u_brg|Add0~89\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~89_combout\ = (\u_rx|u_brg|Add0~4_combout\ & \u_rx|u_brg|counter[10]~0_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010101000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|Add0~4_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|Add0~89_combout\);

-- Location: FF_X23_Y5_N15
\u_rx|u_brg|counter[2]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~89_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(2));

-- Location: LCCOMB_X24_Y5_N6
\u_rx|u_brg|Add0~6\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~6_combout\ = (\u_rx|u_brg|counter\(3) & (!\u_rx|u_brg|Add0~5\)) # (!\u_rx|u_brg|counter\(3) & ((\u_rx|u_brg|Add0~5\) # (GND)))
-- \u_rx|u_brg|Add0~7\ = CARRY((!\u_rx|u_brg|Add0~5\) # (!\u_rx|u_brg|counter\(3)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0101101001011111",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(3),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~5\,
	combout => \u_rx|u_brg|Add0~6_combout\,
	cout => \u_rx|u_brg|Add0~7\);

-- Location: LCCOMB_X23_Y5_N12
\u_rx|u_brg|counter~5\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|counter~5_combout\ = (\u_rx|u_brg|counter~1_combout\) # ((\u_rx|u_brg|Add0~6_combout\ & \u_rx|u_brg|counter[10]~0_combout\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111101011110000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|Add0~6_combout\,
	datac => \u_rx|u_brg|counter~1_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|counter~5_combout\);

-- Location: FF_X23_Y5_N13
\u_rx|u_brg|counter[3]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|counter~5_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(3));

-- Location: LCCOMB_X24_Y5_N8
\u_rx|u_brg|Add0~8\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~8_combout\ = (\u_rx|u_brg|counter\(4) & (\u_rx|u_brg|Add0~7\ $ (GND))) # (!\u_rx|u_brg|counter\(4) & (!\u_rx|u_brg|Add0~7\ & VCC))
-- \u_rx|u_brg|Add0~9\ = CARRY((\u_rx|u_brg|counter\(4) & !\u_rx|u_brg|Add0~7\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010010100001010",
	sum_lutc_input => "cin")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(4),
	datad => VCC,
	cin => \u_rx|u_brg|Add0~7\,
	combout => \u_rx|u_brg|Add0~8_combout\,
	cout => \u_rx|u_brg|Add0~9\);

-- Location: LCCOMB_X23_Y5_N8
\u_rx|u_brg|counter~4\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|counter~4_combout\ = (\u_rx|u_brg|counter~1_combout\) # ((\u_rx|u_brg|Add0~8_combout\ & \u_rx|u_brg|counter[10]~0_combout\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111101010101010",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter~1_combout\,
	datac => \u_rx|u_brg|Add0~8_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|counter~4_combout\);

-- Location: FF_X23_Y5_N9
\u_rx|u_brg|counter[4]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|counter~4_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(4));

-- Location: LCCOMB_X23_Y5_N10
\u_rx|u_brg|Add0~88\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Add0~88_combout\ = (\u_rx|u_brg|Add0~10_combout\ & \u_rx|u_brg|counter[10]~0_combout\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|u_brg|Add0~10_combout\,
	datad => \u_rx|u_brg|counter[10]~0_combout\,
	combout => \u_rx|u_brg|Add0~88_combout\);

-- Location: FF_X23_Y5_N11
\u_rx|u_brg|counter[5]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_brg|Add0~88_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_brg|counter\(5));

-- Location: LCCOMB_X23_Y5_N22
\u_rx|u_brg|Equal0~7\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Equal0~7_combout\ = (((\u_rx|u_brg|counter\(6)) # (!\u_rx|u_brg|counter\(7))) # (!\u_rx|u_brg|counter\(4))) # (!\u_rx|u_brg|counter\(5))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111101111111",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(5),
	datab => \u_rx|u_brg|counter\(4),
	datac => \u_rx|u_brg|counter\(7),
	datad => \u_rx|u_brg|counter\(6),
	combout => \u_rx|u_brg|Equal0~7_combout\);

-- Location: LCCOMB_X23_Y5_N24
\u_rx|u_brg|Equal0~8\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Equal0~8_combout\ = ((\u_rx|u_brg|counter\(1)) # ((\u_rx|u_brg|counter\(2)) # (\u_rx|u_brg|counter\(3)))) # (!\u_rx|u_brg|counter\(0))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111101",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(0),
	datab => \u_rx|u_brg|counter\(1),
	datac => \u_rx|u_brg|counter\(2),
	datad => \u_rx|u_brg|counter\(3),
	combout => \u_rx|u_brg|Equal0~8_combout\);

-- Location: LCCOMB_X25_Y5_N28
\u_rx|u_brg|Equal0~5\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Equal0~5_combout\ = (\u_rx|u_brg|counter\(13)) # ((\u_rx|u_brg|counter\(15)) # ((\u_rx|u_brg|counter\(12)) # (\u_rx|u_brg|counter\(14))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(13),
	datab => \u_rx|u_brg|counter\(15),
	datac => \u_rx|u_brg|counter\(12),
	datad => \u_rx|u_brg|counter\(14),
	combout => \u_rx|u_brg|Equal0~5_combout\);

-- Location: LCCOMB_X23_Y5_N28
\u_rx|u_brg|Equal0~6\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Equal0~6_combout\ = ((\u_rx|u_brg|counter\(9)) # ((\u_rx|u_brg|counter\(10)) # (\u_rx|u_brg|counter\(11)))) # (!\u_rx|u_brg|counter\(8))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111101",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|counter\(8),
	datab => \u_rx|u_brg|counter\(9),
	datac => \u_rx|u_brg|counter\(10),
	datad => \u_rx|u_brg|counter\(11),
	combout => \u_rx|u_brg|Equal0~6_combout\);

-- Location: LCCOMB_X23_Y5_N18
\u_rx|u_brg|Equal0~9\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_brg|Equal0~9_combout\ = (\u_rx|u_brg|Equal0~7_combout\) # ((\u_rx|u_brg|Equal0~8_combout\) # ((\u_rx|u_brg|Equal0~5_combout\) # (\u_rx|u_brg|Equal0~6_combout\)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111111111110",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|Equal0~7_combout\,
	datab => \u_rx|u_brg|Equal0~8_combout\,
	datac => \u_rx|u_brg|Equal0~5_combout\,
	datad => \u_rx|u_brg|Equal0~6_combout\,
	combout => \u_rx|u_brg|Equal0~9_combout\);

-- Location: LCCOMB_X24_Y2_N12
\u_rx|state~9\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~9_combout\ = (\u_rx|baud_enable~2_combout\ & (!\u_rx|u_brg|Equal0~9_combout\ & !\u_rx|u_brg|Equal0~4_combout\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000000000001100",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|baud_enable~2_combout\,
	datac => \u_rx|u_brg|Equal0~9_combout\,
	datad => \u_rx|u_brg|Equal0~4_combout\,
	combout => \u_rx|state~9_combout\);

-- Location: LCCOMB_X24_Y2_N14
\u_rx|state~27\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~27_combout\ = (\rst_n~input_o\ & (((!\u_rx|state.START_BIT~q\ & !\u_rx|state.STOP_BIT~q\)) # (!\u_rx|state~9_combout\)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000001010101010",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \rst_n~input_o\,
	datab => \u_rx|state.START_BIT~q\,
	datac => \u_rx|state.STOP_BIT~q\,
	datad => \u_rx|state~9_combout\,
	combout => \u_rx|state~27_combout\);

-- Location: LCCOMB_X24_Y2_N16
\u_rx|state~21\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~21_combout\ = (!\u_rx|state~20_combout\ & (!\u_rx|state~19_combout\ & (\u_rx|state~27_combout\ & !\u_rx|state~14_combout\)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000000000010000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|state~20_combout\,
	datab => \u_rx|state~19_combout\,
	datac => \u_rx|state~27_combout\,
	datad => \u_rx|state~14_combout\,
	combout => \u_rx|state~21_combout\);

-- Location: LCCOMB_X24_Y2_N26
\u_rx|state~25\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~25_combout\ = (\u_rx|state~20_combout\ & ((\rst_n~input_o\) # ((\u_rx|state.WAIT_START_BIT~q\ & \u_rx|state~21_combout\)))) # (!\u_rx|state~20_combout\ & (((\u_rx|state.WAIT_START_BIT~q\ & \u_rx|state~21_combout\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111100010001000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|state~20_combout\,
	datab => \rst_n~input_o\,
	datac => \u_rx|state.WAIT_START_BIT~q\,
	datad => \u_rx|state~21_combout\,
	combout => \u_rx|state~25_combout\);

-- Location: FF_X24_Y2_N27
\u_rx|state.WAIT_START_BIT\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|state~25_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|state.WAIT_START_BIT~q\);

-- Location: LCCOMB_X23_Y2_N22
\u_rx|state~19\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~19_combout\ = (\u_rx|data_in_sync~q\ & \u_rx|state.WAIT_START_BIT~q\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100110000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|data_in_sync~q\,
	datad => \u_rx|state.WAIT_START_BIT~q\,
	combout => \u_rx|state~19_combout\);

-- Location: LCCOMB_X24_Y2_N0
\u_rx|state~26\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~26_combout\ = (\rst_n~input_o\ & ((\u_rx|state~19_combout\) # ((\u_rx|state.START_BIT~q\ & \u_rx|state~21_combout\)))) # (!\rst_n~input_o\ & (((\u_rx|state.START_BIT~q\ & \u_rx|state~21_combout\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111100010001000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \rst_n~input_o\,
	datab => \u_rx|state~19_combout\,
	datac => \u_rx|state.START_BIT~q\,
	datad => \u_rx|state~21_combout\,
	combout => \u_rx|state~26_combout\);

-- Location: FF_X24_Y2_N1
\u_rx|state.START_BIT\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|state~26_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|state.START_BIT~q\);

-- Location: LCCOMB_X24_Y2_N28
\u_rx|state~23\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~23_combout\ = (\u_rx|state.START_BIT~q\ & (\u_rx|baud_enable~2_combout\ & (!\u_rx|u_brg|Equal0~9_combout\ & !\u_rx|u_brg|Equal0~4_combout\)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000000000001000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|state.START_BIT~q\,
	datab => \u_rx|baud_enable~2_combout\,
	datac => \u_rx|u_brg|Equal0~9_combout\,
	datad => \u_rx|u_brg|Equal0~4_combout\,
	combout => \u_rx|state~23_combout\);

-- Location: LCCOMB_X24_Y2_N30
\u_rx|state~11\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~11_combout\ = (!\u_rx|state.START_BIT~q\ & !\u_rx|state.STOP_BIT~q\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000000000110011",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|state.START_BIT~q\,
	datad => \u_rx|state.STOP_BIT~q\,
	combout => \u_rx|state~11_combout\);

-- Location: LCCOMB_X23_Y2_N6
\u_rx|state~12\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~12_combout\ = (\u_rx|state.IDLE~q\ & (((\u_rx|data_in_sync~q\ & !\u_rx|state.DATA_BITS~q\)))) # (!\u_rx|state.IDLE~q\ & (\r~input_o\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000110010101010",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \r~input_o\,
	datab => \u_rx|data_in_sync~q\,
	datac => \u_rx|state.DATA_BITS~q\,
	datad => \u_rx|state.IDLE~q\,
	combout => \u_rx|state~12_combout\);

-- Location: LCCOMB_X24_Y2_N2
\u_rx|state~15\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~15_combout\ = (\u_rx|state~11_combout\ & ((\u_rx|state~12_combout\) # ((\u_rx|state.IDLE~q\ & \u_rx|state~14_combout\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010100010100000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|state~11_combout\,
	datab => \u_rx|state.IDLE~q\,
	datac => \u_rx|state~12_combout\,
	datad => \u_rx|state~14_combout\,
	combout => \u_rx|state~15_combout\);

-- Location: LCCOMB_X24_Y2_N24
\u_rx|state~16\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~16_combout\ = ((\u_rx|state~15_combout\) # ((\u_rx|state~9_combout\ & !\u_rx|state~11_combout\))) # (!\rst_n~input_o\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111100111011",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|state~9_combout\,
	datab => \rst_n~input_o\,
	datac => \u_rx|state~11_combout\,
	datad => \u_rx|state~15_combout\,
	combout => \u_rx|state~16_combout\);

-- Location: LCCOMB_X24_Y2_N10
\u_rx|state~17\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~17_combout\ = (\rst_n~input_o\ & ((\u_rx|state~15_combout\) # ((\u_rx|state~9_combout\ & !\u_rx|state~11_combout\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100110000001000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|state~9_combout\,
	datab => \rst_n~input_o\,
	datac => \u_rx|state~11_combout\,
	datad => \u_rx|state~15_combout\,
	combout => \u_rx|state~17_combout\);

-- Location: LCCOMB_X24_Y2_N8
\u_rx|state~24\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~24_combout\ = (\u_rx|state~23_combout\ & ((\u_rx|state~17_combout\) # ((!\u_rx|state~16_combout\ & \u_rx|state.DATA_BITS~q\)))) # (!\u_rx|state~23_combout\ & (!\u_rx|state~16_combout\ & (\u_rx|state.DATA_BITS~q\)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1011101000110000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|state~23_combout\,
	datab => \u_rx|state~16_combout\,
	datac => \u_rx|state.DATA_BITS~q\,
	datad => \u_rx|state~17_combout\,
	combout => \u_rx|state~24_combout\);

-- Location: FF_X24_Y2_N9
\u_rx|state.DATA_BITS\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|state~24_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|state.DATA_BITS~q\);

-- Location: LCCOMB_X23_Y2_N10
\u_rx|count~3\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|count~3_combout\ = (\rst_n~input_o\ & !\u_rx|count\(0))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000110000001100",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \rst_n~input_o\,
	datac => \u_rx|count\(0),
	combout => \u_rx|count~3_combout\);

-- Location: LCCOMB_X23_Y2_N4
\u_rx|count[1]~2\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|count[1]~2_combout\ = ((!\u_rx|u_brg|Equal0~9_combout\ & (\u_rx|state.DATA_BITS~q\ & !\u_rx|u_brg|Equal0~4_combout\))) # (!\rst_n~input_o\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0011001101110011",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|u_brg|Equal0~9_combout\,
	datab => \rst_n~input_o\,
	datac => \u_rx|state.DATA_BITS~q\,
	datad => \u_rx|u_brg|Equal0~4_combout\,
	combout => \u_rx|count[1]~2_combout\);

-- Location: FF_X23_Y2_N11
\u_rx|count[0]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|count~3_combout\,
	ena => \u_rx|count[1]~2_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|count\(0));

-- Location: LCCOMB_X23_Y2_N30
\u_rx|count~4\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|count~4_combout\ = \u_rx|count\(1) $ (\u_rx|count\(0))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000111111110000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \u_rx|count\(1),
	datad => \u_rx|count\(0),
	combout => \u_rx|count~4_combout\);

-- Location: FF_X23_Y2_N31
\u_rx|count[1]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|count~4_combout\,
	sclr => \ALT_INV_rst_n~input_o\,
	ena => \u_rx|count[1]~2_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|count\(1));

-- Location: LCCOMB_X23_Y2_N20
\u_rx|count~1\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|count~1_combout\ = (\rst_n~input_o\ & (\u_rx|count\(2) $ (((\u_rx|count\(1) & \u_rx|count\(0))))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0100100011000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|count\(1),
	datab => \rst_n~input_o\,
	datac => \u_rx|count\(2),
	datad => \u_rx|count\(0),
	combout => \u_rx|count~1_combout\);

-- Location: FF_X23_Y2_N21
\u_rx|count[2]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|count~1_combout\,
	ena => \u_rx|count[1]~2_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|count\(2));

-- Location: LCCOMB_X23_Y2_N16
\u_rx|state~13\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~13_combout\ = (\u_rx|count\(0) & (\u_rx|count\(1) & \u_rx|count\(2)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|count\(0),
	datac => \u_rx|count\(1),
	datad => \u_rx|count\(2),
	combout => \u_rx|state~13_combout\);

-- Location: LCCOMB_X24_Y2_N20
\u_rx|state~14\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~14_combout\ = (\u_rx|state.DATA_BITS~q\ & (\u_rx|state~13_combout\ & \u_rx|state~9_combout\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|state.DATA_BITS~q\,
	datac => \u_rx|state~13_combout\,
	datad => \u_rx|state~9_combout\,
	combout => \u_rx|state~14_combout\);

-- Location: LCCOMB_X24_Y2_N18
\u_rx|state~22\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~22_combout\ = (\rst_n~input_o\ & ((\u_rx|state~14_combout\) # ((\u_rx|state.STOP_BIT~q\ & \u_rx|state~21_combout\)))) # (!\rst_n~input_o\ & (((\u_rx|state.STOP_BIT~q\ & \u_rx|state~21_combout\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111100010001000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \rst_n~input_o\,
	datab => \u_rx|state~14_combout\,
	datac => \u_rx|state.STOP_BIT~q\,
	datad => \u_rx|state~21_combout\,
	combout => \u_rx|state~22_combout\);

-- Location: FF_X24_Y2_N19
\u_rx|state.STOP_BIT\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|state~22_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|state.STOP_BIT~q\);

-- Location: LCCOMB_X24_Y2_N6
\u_rx|state~10\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~10_combout\ = (\u_rx|state.STOP_BIT~q\ & (\u_rx|baud_enable~2_combout\ & (!\u_rx|u_brg|Equal0~9_combout\ & !\u_rx|u_brg|Equal0~4_combout\)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000000000001000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|state.STOP_BIT~q\,
	datab => \u_rx|baud_enable~2_combout\,
	datac => \u_rx|u_brg|Equal0~9_combout\,
	datad => \u_rx|u_brg|Equal0~4_combout\,
	combout => \u_rx|state~10_combout\);

-- Location: LCCOMB_X24_Y2_N4
\u_rx|state~18\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|state~18_combout\ = (\u_rx|state~10_combout\ & (!\u_rx|state~16_combout\ & (\u_rx|state.IDLE~q\))) # (!\u_rx|state~10_combout\ & ((\u_rx|state~17_combout\) # ((!\u_rx|state~16_combout\ & \u_rx|state.IDLE~q\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0111010100110000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|state~10_combout\,
	datab => \u_rx|state~16_combout\,
	datac => \u_rx|state.IDLE~q\,
	datad => \u_rx|state~17_combout\,
	combout => \u_rx|state~18_combout\);

-- Location: FF_X24_Y2_N5
\u_rx|state.IDLE\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|state~18_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|state.IDLE~q\);

-- Location: LCCOMB_X23_Y2_N28
\u_rx|rx_busy_r~0\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|rx_busy_r~0_combout\ = (\u_rx|state.IDLE~q\ & \rst_n~input_o\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010000010100000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|state.IDLE~q\,
	datac => \rst_n~input_o\,
	combout => \u_rx|rx_busy_r~0_combout\);

-- Location: FF_X23_Y2_N29
\u_rx|rx_busy_r\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|rx_busy_r~0_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|rx_busy_r~q\);

-- Location: LCCOMB_X23_Y2_N12
\u_rx|process_1~1\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|process_1~1_combout\ = (\u_rx|state.STOP_BIT~q\ & (!\u_rx|u_brg|Equal0~9_combout\ & !\u_rx|u_brg|Equal0~4_combout\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000000000001100",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datab => \u_rx|state.STOP_BIT~q\,
	datac => \u_rx|u_brg|Equal0~9_combout\,
	datad => \u_rx|u_brg|Equal0~4_combout\,
	combout => \u_rx|process_1~1_combout\);

-- Location: FF_X23_Y2_N13
\u_rx|rx_valid_r\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|process_1~1_combout\,
	sclr => \ALT_INV_rst_n~input_o\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|rx_valid_r~q\);

-- Location: LCCOMB_X25_Y2_N10
\u_rx|u_s2p|q~8\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_s2p|q~8_combout\ = (\rst_n~input_o\ & !\u_rx|data_in_sync~q\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0000000011110000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \rst_n~input_o\,
	datad => \u_rx|data_in_sync~q\,
	combout => \u_rx|u_s2p|q~8_combout\);

-- Location: LCCOMB_X25_Y2_N8
\u_rx|u_s2p|q[0]~1\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_s2p|q[0]~1_combout\ = ((\u_rx|state.DATA_BITS~q\ & \u_rx|state~9_combout\)) # (!\rst_n~input_o\)

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010111100001111",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_rx|state.DATA_BITS~q\,
	datac => \rst_n~input_o\,
	datad => \u_rx|state~9_combout\,
	combout => \u_rx|u_s2p|q[0]~1_combout\);

-- Location: FF_X25_Y2_N11
\u_rx|u_s2p|q[7]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_s2p|q~8_combout\,
	ena => \u_rx|u_s2p|q[0]~1_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_s2p|q\(7));

-- Location: LCCOMB_X25_Y2_N16
\u_rx|u_s2p|q~7\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_s2p|q~7_combout\ = (\rst_n~input_o\ & \u_rx|u_s2p|q\(7))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \rst_n~input_o\,
	datad => \u_rx|u_s2p|q\(7),
	combout => \u_rx|u_s2p|q~7_combout\);

-- Location: FF_X25_Y2_N17
\u_rx|u_s2p|q[6]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_s2p|q~7_combout\,
	ena => \u_rx|u_s2p|q[0]~1_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_s2p|q\(6));

-- Location: LCCOMB_X25_Y2_N6
\u_rx|u_s2p|q~6\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_s2p|q~6_combout\ = (\rst_n~input_o\ & \u_rx|u_s2p|q\(6))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \rst_n~input_o\,
	datad => \u_rx|u_s2p|q\(6),
	combout => \u_rx|u_s2p|q~6_combout\);

-- Location: FF_X25_Y2_N7
\u_rx|u_s2p|q[5]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_s2p|q~6_combout\,
	ena => \u_rx|u_s2p|q[0]~1_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_s2p|q\(5));

-- Location: LCCOMB_X25_Y2_N28
\u_rx|u_s2p|q~5\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_s2p|q~5_combout\ = (\rst_n~input_o\ & \u_rx|u_s2p|q\(5))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \rst_n~input_o\,
	datad => \u_rx|u_s2p|q\(5),
	combout => \u_rx|u_s2p|q~5_combout\);

-- Location: FF_X25_Y2_N29
\u_rx|u_s2p|q[4]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_s2p|q~5_combout\,
	ena => \u_rx|u_s2p|q[0]~1_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_s2p|q\(4));

-- Location: LCCOMB_X25_Y2_N18
\u_rx|u_s2p|q~4\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_s2p|q~4_combout\ = (\rst_n~input_o\ & \u_rx|u_s2p|q\(4))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \rst_n~input_o\,
	datad => \u_rx|u_s2p|q\(4),
	combout => \u_rx|u_s2p|q~4_combout\);

-- Location: FF_X25_Y2_N19
\u_rx|u_s2p|q[3]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_s2p|q~4_combout\,
	ena => \u_rx|u_s2p|q[0]~1_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_s2p|q\(3));

-- Location: LCCOMB_X25_Y2_N0
\u_rx|u_s2p|q~3\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_s2p|q~3_combout\ = (\rst_n~input_o\ & \u_rx|u_s2p|q\(3))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \rst_n~input_o\,
	datad => \u_rx|u_s2p|q\(3),
	combout => \u_rx|u_s2p|q~3_combout\);

-- Location: FF_X25_Y2_N1
\u_rx|u_s2p|q[2]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_s2p|q~3_combout\,
	ena => \u_rx|u_s2p|q[0]~1_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_s2p|q\(2));

-- Location: LCCOMB_X25_Y2_N2
\u_rx|u_s2p|q~2\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_s2p|q~2_combout\ = (\rst_n~input_o\ & \u_rx|u_s2p|q\(2))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \rst_n~input_o\,
	datad => \u_rx|u_s2p|q\(2),
	combout => \u_rx|u_s2p|q~2_combout\);

-- Location: FF_X25_Y2_N3
\u_rx|u_s2p|q[1]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_s2p|q~2_combout\,
	ena => \u_rx|u_s2p|q[0]~1_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_s2p|q\(1));

-- Location: LCCOMB_X25_Y2_N12
\u_rx|u_s2p|q~0\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_rx|u_s2p|q~0_combout\ = (\rst_n~input_o\ & \u_rx|u_s2p|q\(1))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111000000000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	datac => \rst_n~input_o\,
	datad => \u_rx|u_s2p|q\(1),
	combout => \u_rx|u_s2p|q~0_combout\);

-- Location: FF_X25_Y2_N13
\u_rx|u_s2p|q[0]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_rx|u_s2p|q~0_combout\,
	ena => \u_rx|u_s2p|q[0]~1_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_rx|u_s2p|q\(0));

-- Location: IOIBUF_X28_Y0_N1
\data_tx_buff[0]~input\ : cycloneive_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_data_tx_buff(0),
	o => \data_tx_buff[0]~input_o\);

-- Location: IOIBUF_X21_Y0_N8
\data_tx_buff[1]~input\ : cycloneive_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_data_tx_buff(1),
	o => \data_tx_buff[1]~input_o\);

-- Location: IOIBUF_X34_Y9_N8
\data_tx_buff[3]~input\ : cycloneive_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_data_tx_buff(3),
	o => \data_tx_buff[3]~input_o\);

-- Location: IOIBUF_X34_Y9_N22
\data_tx_buff[7]~input\ : cycloneive_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_data_tx_buff(7),
	o => \data_tx_buff[7]~input_o\);

-- Location: LCCOMB_X28_Y9_N2
\u_tx|u_p2s|data_in_load~10\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_p2s|data_in_load~10_combout\ = (!\u_tx|state~13_combout\ & (\u_tx|u_p2s|data_in_load\(7) & ((\u_tx|u_brg|Equal0~10_combout\) # (!\u_tx|state.DATA_BITS~q\))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0100010000000100",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|state~13_combout\,
	datab => \u_tx|u_p2s|data_in_load\(7),
	datac => \u_tx|state.DATA_BITS~q\,
	datad => \u_tx|u_brg|Equal0~10_combout\,
	combout => \u_tx|u_p2s|data_in_load~10_combout\);

-- Location: LCCOMB_X28_Y9_N30
\u_tx|u_p2s|data_in_load~11\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_p2s|data_in_load~11_combout\ = (\u_tx|u_p2s|data_in_load~10_combout\) # ((\data_tx_buff[7]~input_o\ & (\w~input_o\ & !\u_tx|state.IDLE~q\)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1111111100001000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \data_tx_buff[7]~input_o\,
	datab => \w~input_o\,
	datac => \u_tx|state.IDLE~q\,
	datad => \u_tx|u_p2s|data_in_load~10_combout\,
	combout => \u_tx|u_p2s|data_in_load~11_combout\);

-- Location: FF_X28_Y9_N31
\u_tx|u_p2s|data_in_load[7]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_p2s|data_in_load~11_combout\,
	sclr => \ALT_INV_rst_n~input_o\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_p2s|data_in_load\(7));

-- Location: IOIBUF_X32_Y0_N8
\data_tx_buff[6]~input\ : cycloneive_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_data_tx_buff(6),
	o => \data_tx_buff[6]~input_o\);

-- Location: LCCOMB_X28_Y9_N12
\u_tx|u_p2s|data_in_load~9\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_p2s|data_in_load~9_combout\ = (\u_tx|state.IDLE~q\ & (\u_tx|u_p2s|data_in_load\(7))) # (!\u_tx|state.IDLE~q\ & ((\w~input_o\ & ((\data_tx_buff[6]~input_o\))) # (!\w~input_o\ & (\u_tx|u_p2s|data_in_load\(7)))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010110010101010",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_p2s|data_in_load\(7),
	datab => \data_tx_buff[6]~input_o\,
	datac => \u_tx|state.IDLE~q\,
	datad => \w~input_o\,
	combout => \u_tx|u_p2s|data_in_load~9_combout\);

-- Location: LCCOMB_X28_Y9_N18
\u_tx|u_p2s|data_in_load[0]~3\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_p2s|data_in_load[0]~3_combout\ = (\u_tx|state~13_combout\) # (((\u_tx|state.DATA_BITS~q\ & !\u_tx|u_brg|Equal0~10_combout\)) # (!\rst_n~input_o\))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1011101111111011",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|state~13_combout\,
	datab => \rst_n~input_o\,
	datac => \u_tx|state.DATA_BITS~q\,
	datad => \u_tx|u_brg|Equal0~10_combout\,
	combout => \u_tx|u_p2s|data_in_load[0]~3_combout\);

-- Location: FF_X28_Y9_N13
\u_tx|u_p2s|data_in_load[6]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_p2s|data_in_load~9_combout\,
	sclr => \ALT_INV_rst_n~input_o\,
	ena => \u_tx|u_p2s|data_in_load[0]~3_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_p2s|data_in_load\(6));

-- Location: IOIBUF_X34_Y9_N15
\data_tx_buff[5]~input\ : cycloneive_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_data_tx_buff(5),
	o => \data_tx_buff[5]~input_o\);

-- Location: LCCOMB_X28_Y9_N14
\u_tx|u_p2s|data_in_load~8\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_p2s|data_in_load~8_combout\ = (\w~input_o\ & ((\u_tx|state.IDLE~q\ & (\u_tx|u_p2s|data_in_load\(6))) # (!\u_tx|state.IDLE~q\ & ((\data_tx_buff[5]~input_o\))))) # (!\w~input_o\ & (\u_tx|u_p2s|data_in_load\(6)))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010111010100010",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_p2s|data_in_load\(6),
	datab => \w~input_o\,
	datac => \u_tx|state.IDLE~q\,
	datad => \data_tx_buff[5]~input_o\,
	combout => \u_tx|u_p2s|data_in_load~8_combout\);

-- Location: FF_X28_Y9_N15
\u_tx|u_p2s|data_in_load[5]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_p2s|data_in_load~8_combout\,
	sclr => \ALT_INV_rst_n~input_o\,
	ena => \u_tx|u_p2s|data_in_load[0]~3_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_p2s|data_in_load\(5));

-- Location: IOIBUF_X34_Y4_N22
\data_tx_buff[4]~input\ : cycloneive_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_data_tx_buff(4),
	o => \data_tx_buff[4]~input_o\);

-- Location: LCCOMB_X28_Y9_N24
\u_tx|u_p2s|data_in_load~7\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_p2s|data_in_load~7_combout\ = (\u_tx|state.IDLE~q\ & (\u_tx|u_p2s|data_in_load\(5))) # (!\u_tx|state.IDLE~q\ & ((\w~input_o\ & ((\data_tx_buff[4]~input_o\))) # (!\w~input_o\ & (\u_tx|u_p2s|data_in_load\(5)))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1101100011001100",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|state.IDLE~q\,
	datab => \u_tx|u_p2s|data_in_load\(5),
	datac => \data_tx_buff[4]~input_o\,
	datad => \w~input_o\,
	combout => \u_tx|u_p2s|data_in_load~7_combout\);

-- Location: FF_X28_Y9_N25
\u_tx|u_p2s|data_in_load[4]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_p2s|data_in_load~7_combout\,
	sclr => \ALT_INV_rst_n~input_o\,
	ena => \u_tx|u_p2s|data_in_load[0]~3_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_p2s|data_in_load\(4));

-- Location: LCCOMB_X28_Y9_N22
\u_tx|u_p2s|data_in_load~6\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_p2s|data_in_load~6_combout\ = (\u_tx|state.IDLE~q\ & (((\u_tx|u_p2s|data_in_load\(4))))) # (!\u_tx|state.IDLE~q\ & ((\w~input_o\ & (\data_tx_buff[3]~input_o\)) # (!\w~input_o\ & ((\u_tx|u_p2s|data_in_load\(4))))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100101011001100",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \data_tx_buff[3]~input_o\,
	datab => \u_tx|u_p2s|data_in_load\(4),
	datac => \u_tx|state.IDLE~q\,
	datad => \w~input_o\,
	combout => \u_tx|u_p2s|data_in_load~6_combout\);

-- Location: FF_X28_Y9_N23
\u_tx|u_p2s|data_in_load[3]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_p2s|data_in_load~6_combout\,
	sclr => \ALT_INV_rst_n~input_o\,
	ena => \u_tx|u_p2s|data_in_load[0]~3_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_p2s|data_in_load\(3));

-- Location: IOIBUF_X30_Y0_N8
\data_tx_buff[2]~input\ : cycloneive_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_data_tx_buff(2),
	o => \data_tx_buff[2]~input_o\);

-- Location: LCCOMB_X28_Y9_N4
\u_tx|u_p2s|data_in_load~5\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_p2s|data_in_load~5_combout\ = (\u_tx|state.IDLE~q\ & (\u_tx|u_p2s|data_in_load\(3))) # (!\u_tx|state.IDLE~q\ & ((\w~input_o\ & ((\data_tx_buff[2]~input_o\))) # (!\w~input_o\ & (\u_tx|u_p2s|data_in_load\(3)))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1010110010101010",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|u_p2s|data_in_load\(3),
	datab => \data_tx_buff[2]~input_o\,
	datac => \u_tx|state.IDLE~q\,
	datad => \w~input_o\,
	combout => \u_tx|u_p2s|data_in_load~5_combout\);

-- Location: FF_X28_Y9_N5
\u_tx|u_p2s|data_in_load[2]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_p2s|data_in_load~5_combout\,
	sclr => \ALT_INV_rst_n~input_o\,
	ena => \u_tx|u_p2s|data_in_load[0]~3_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_p2s|data_in_load\(2));

-- Location: LCCOMB_X28_Y9_N26
\u_tx|u_p2s|data_in_load~4\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_p2s|data_in_load~4_combout\ = (\u_tx|state.IDLE~q\ & (((\u_tx|u_p2s|data_in_load\(2))))) # (!\u_tx|state.IDLE~q\ & ((\w~input_o\ & (\data_tx_buff[1]~input_o\)) # (!\w~input_o\ & ((\u_tx|u_p2s|data_in_load\(2))))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1100101011001100",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \data_tx_buff[1]~input_o\,
	datab => \u_tx|u_p2s|data_in_load\(2),
	datac => \u_tx|state.IDLE~q\,
	datad => \w~input_o\,
	combout => \u_tx|u_p2s|data_in_load~4_combout\);

-- Location: FF_X28_Y9_N27
\u_tx|u_p2s|data_in_load[1]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_p2s|data_in_load~4_combout\,
	sclr => \ALT_INV_rst_n~input_o\,
	ena => \u_tx|u_p2s|data_in_load[0]~3_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_p2s|data_in_load\(1));

-- Location: LCCOMB_X28_Y9_N8
\u_tx|u_p2s|data_in_load~2\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|u_p2s|data_in_load~2_combout\ = (\u_tx|state.IDLE~q\ & (((\u_tx|u_p2s|data_in_load\(1))))) # (!\u_tx|state.IDLE~q\ & ((\w~input_o\ & (\data_tx_buff[0]~input_o\)) # (!\w~input_o\ & ((\u_tx|u_p2s|data_in_load\(1))))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "1110010011110000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|state.IDLE~q\,
	datab => \data_tx_buff[0]~input_o\,
	datac => \u_tx|u_p2s|data_in_load\(1),
	datad => \w~input_o\,
	combout => \u_tx|u_p2s|data_in_load~2_combout\);

-- Location: FF_X28_Y9_N9
\u_tx|u_p2s|data_in_load[0]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|u_p2s|data_in_load~2_combout\,
	sclr => \ALT_INV_rst_n~input_o\,
	ena => \u_tx|u_p2s|data_in_load[0]~3_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|u_p2s|data_in_load\(0));

-- Location: LCCOMB_X28_Y9_N10
\u_tx|data_out_r~0\ : cycloneive_lcell_comb
-- Equation(s):
-- \u_tx|data_out_r~0_combout\ = (!\u_tx|state.STOP_BIT~q\ & (\u_tx|tx_busy_r~0_combout\ & ((!\u_tx|state.DATA_BITS~q\) # (!\u_tx|u_p2s|data_in_load\(0)))))

-- pragma translate_off
GENERIC MAP (
	lut_mask => "0001010100000000",
	sum_lutc_input => "datac")
-- pragma translate_on
PORT MAP (
	dataa => \u_tx|state.STOP_BIT~q\,
	datab => \u_tx|u_p2s|data_in_load\(0),
	datac => \u_tx|state.DATA_BITS~q\,
	datad => \u_tx|tx_busy_r~0_combout\,
	combout => \u_tx|data_out_r~0_combout\);

-- Location: FF_X28_Y9_N11
\u_tx|data_out_r\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \clk~inputclkctrl_outclk\,
	d => \u_tx|data_out_r~0_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_tx|data_out_r~q\);

ww_tx_busy <= \tx_busy~output_o\;

ww_rx_busy <= \rx_busy~output_o\;

ww_rx_valid <= \rx_valid~output_o\;

ww_data_rx_buff(0) <= \data_rx_buff[0]~output_o\;

ww_data_rx_buff(1) <= \data_rx_buff[1]~output_o\;

ww_data_rx_buff(2) <= \data_rx_buff[2]~output_o\;

ww_data_rx_buff(3) <= \data_rx_buff[3]~output_o\;

ww_data_rx_buff(4) <= \data_rx_buff[4]~output_o\;

ww_data_rx_buff(5) <= \data_rx_buff[5]~output_o\;

ww_data_rx_buff(6) <= \data_rx_buff[6]~output_o\;

ww_data_rx_buff(7) <= \data_rx_buff[7]~output_o\;

ww_data_line_tx <= \data_line_tx~output_o\;
END structure;


