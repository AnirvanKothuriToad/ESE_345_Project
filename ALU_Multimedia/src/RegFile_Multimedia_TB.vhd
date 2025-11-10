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

entity ALU_Multimedia_TB is
end ALU_Multimedia_TB;

architecture TB_Architecture of ALU_Multimedia_TB is

	--Stimulus Signals
	signal reset :  STD_LOGIC;							   -- Asynchronous reset
	signal clk   :  STD_LOGIC;								   -- Clock signal
	signal write_enable :  STD_LOGIC;					   -- If enabled, write to register pointed to by address_in
		
		
	signal address_out_A :  STD_LOGIC_VECTOR(5 downto 0);   -- Register to read from (A)
	signal address_out_B :  STD_LOGIC_VECTOR(5 downto 0);   -- Register to read from (B)
	signal address_out_C :  STD_LOGIC_VECTOR(5 downto 0);   -- Register to read from (C)  
	
	signal address_in :  STD_LOGIC_VECTOR(5 downto 0); 	   -- Register to write to
	signal data_in :  STD_LOGIC_VECTOR(127 downto 0)		   -- Value to write to register
	
	--Observed Signal
	signal data_out_A :  STD_LOGIC_VECTOR(127 downto 0);   -- Value read from register (A)
	signal data_out_B :  STD_LOGIC_VECTOR(127 downto 0);   -- Value read from register (B)
	signal data_out_C :  STD_LOGIC_VECTOR(127 downto 0);   -- Value read from register (C)
		
	constant PER : time := 10ns;	  --Setting a constant period value
	 
	signal END_SIM : boolean := false;
	
begin
	-- Unit Under Test port map
	UUT : entity ALU
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
		clock <= '0'; --setting clock to 0 initially
		wait for PER/2;
		loop --Infinite Loop
			clk <= not clock;
			wait for PER/2;
			exit when END_SIM = true;
		end loop;
		std.env.finish;
		
		-- Reset Signal
	 reset <= '1', '0' after 2.5 * PER;	  --Testing asynch reset 
	
	-- Simulation control process
	sim_cntrl: process
	begin




	std.env.finish; --Testbench Complete
	end process;
	
end TB_Architecture;