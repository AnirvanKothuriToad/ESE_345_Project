-------------------------------------------------------------------------------
--
-- Title       : RegFile_TB
-- Design      : ProjectPartI
-- Author      : Anirvan Kothuri and Mahir Patel
-- Company     : Stony Brook University
--
-------------------------------------------------------------------------------
--
-- File        : C:
-- Generated   : Tue Nov  4 18:46:26 2025
-- From        : Interface description file
-- By          : ItfToHdl ver. 1.0
--
-------------------------------------------------------------------------------
--
-- Description :ALU Test bench designed to test random cases and edge cases for each function
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {ALU_TB} architecture {Behavioral}} 

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.all;

entity RegFile_Multimedia_TB is
end RegFile_Multimedia_TB;

architecture TB_Architecture of RegFile_Multimedia_TB is

	--Stimulus Signals
	signal reset :  STD_LOGIC;							   -- Asynchronous reset
	signal clk   :  STD_LOGIC;								   -- Clock signal
	signal write_enable :  STD_LOGIC;					   -- If enabled, write to register pointed to by address_in
		
		
	signal address_out_A :  STD_LOGIC_VECTOR(4 downto 0);   -- Register to read from (A)
	signal address_out_B :  STD_LOGIC_VECTOR(4 downto 0);   -- Register to read from (B)
	signal address_out_C :  STD_LOGIC_VECTOR(4 downto 0);   -- Register to read from (C)  
	
	signal address_in :  STD_LOGIC_VECTOR(4 downto 0); 	   -- Register to write to
	signal data_in :  STD_LOGIC_VECTOR(127 downto 0);		   -- Value to write to register
	
	--Observed Signal
	signal data_out_A :  STD_LOGIC_VECTOR(127 downto 0);   -- Value read from register (A)
	signal data_out_B :  STD_LOGIC_VECTOR(127 downto 0);   -- Value read from register (B)
	signal data_out_C :  STD_LOGIC_VECTOR(127 downto 0);   -- Value read from register (C)
		
	constant PER : time := 10ns;	  --Setting a constant period value
	 
	signal END_SIM : boolean := false;
	
begin
	-- Unit Under Test port map
	UUT : entity RegFile
		port map (
			reset => reset,
			clk => clk,
			write_enable => write_enable,
			
			address_out_A => address_out_A,
			address_out_B => address_out_B,
			address_out_C => address_out_C,
			
			address_in => address_in,
			data_in    => data_in,
			
			data_out_A => data_out_A,
			data_out_B => data_out_B,
			data_out_C => data_out_C
		);
		
	clock: process
	begin
		clk <= '0'; --setting clock to 0 initially
		wait for PER/2;
		loop --Infinite Loop
			clk <= not clk;
			wait for PER/2;
			exit when END_SIM = true;
		end loop;
		std.env.finish;
	end process;

	
	-- Simulation control process
	sim_cntrl: process
	begin
	--Starting by resetting outputs
	
	-- Reset Signal
	reset <= '1', '0' after 2 * PER;	  --Testing asynch reset for 2 cycles
	wait for PER;
	
	wait until falling_edge(clk); --Changing Inputs on falling edge, so they are ready before next positive clock edge 
	write_enable <= '0'; --setting write_enable to 0 
	address_in <= "00001"; --Writing to register 1
	data_in <= x"FEED0000000000000000000000000000"; --Setting data in as FEED in hexadecimal   
	wait for PER; --allowing inputs to update  
	
	wait until falling_edge(clk);
	--Output should remain 0 as write_en is 0
	address_out_A <= "00001"; --Reading register 1 to see if output updated
	wait for PER;	
		
	wait until falling_edge(clk);
	--Output Should update as write_en =1
	write_enable <= '1'; --toggling to 1 to modify register value
	wait for PER;
	
	wait until falling_edge(clk);
	--Output should update to FEED as write_en is 1
	address_out_A <= "00001"; --Reading register 1 to see if output updated
	wait for PER;
	
	wait until falling_edge(clk);
	--Testing Bypass Case
	write_enable <= '1';
	address_in <= "00001"; --Selecting register 1 to modify
	data_in <= x"FFFF0000000000000000000000000000"; --loading FFFF as MSBs in Hexa
	address_out_A <= "00001"; --reading from register 1
	wait for PER*2;
	
	
	



	std.env.finish; --Testbench Complete
	end process;
	
end TB_Architecture;