-------------------------------------------------------------------------------
--
-- Title       : ALU_TB
-- Design      : ProjectPartI
-- Author      : Anirvan Kothuri and Mahir Patel
-- Company     : Stony Brook University
--
-------------------------------------------------------------------------------
--
-- File        : C:
-- Generated   : Mon Oct 27 15:40:31 2025
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
	signal instr  :    STD_LOGIC_VECTOR(4 downto 0);
	signal rs3    :    STD_LOGIC_VECTOR(127 downto 0);
	signal rs2    :    STD_LOGIC_VECTOR(127 downto 0);
	signal rs1    :    STD_LOGIC_VECTOR(127 downto 0);
	signal ld_in  :    STD_LOGIC_VECTOR(2 downto 0);
	signal imm    :    STD_LOGIC_VECTOR(15 downto 0);
	
	--Observed Signal
	signal rd     :    STD_LOGIC_VECTOR(127 downto 0);
	
	constant clk_period : time := 125 ns;
	signal END_SIM : boolean := false;
	
begin
	-- Unit Under Test port map
	UUT : entity ALU
		port map (
			instr => instr,
			rs3 => rs3,
			rs2 => rs2,
			rs1 => rs1,
			ld_in => ld_in,
			rd => rd,
			imm => imm
		);
		

	-- Simulation control process
	sim_cntrl: process
	begin
		   -----------------------------------------
		   --Testing Load Immediate Function--------
		   -----------------------------------------
		   rs1 <= (others => '0'); --Clearing rs1 initially
		   instr <= "00000"; --setting instruction to Load Immediate   
		   ld_in <= "000"; --Testing for load index =0
		   imm <= "1100000000000011"; --Setting a value for immediate to test
		   wait for 4ns;
		   
		   for i in 0 to 6 loop --testing for remaining 7 indices through a for loop
			   
			   ld_in <= STD_LOGIC_VECTOR(UNSIGNED(ld_in) + 1); --incrementing index
			   
			   wait for 4ns;
			   
		   end loop;
		
		    --Testing first 4 16 bit R4 Functions 
		   	ld_in <= "000"; --Not testing load index
			        --Normal Addition	  --Overflow Add	 --Underflow Add		 --Subtract		    --Overflow Sub			--Underflow Sub
			rs2 <= "0000000000000001" & "0000000000000010" & "0000000000000011" & "0000000000000100" & "0000000000000101" & "0000000000000110" & "0111111111111111" & "1000000000000000";
			rs1 <= "0000000011000000" & "0111111111111111" & "1000000000000000" & "0000000000000001" & "1000000000000000" & "0111111111111111" & "0000000000000001" & "0000000000000001"; 
			rs3 <= "0000000000000001" & "0000000000000001" & "0000000000000001" & "0000000000000001" & "0000000000000001" & "0000000000000001" & "0000000000000001" & "0000000000000001";
			instr <= "00001"; --Testing  Signed Integer Multiply-Add Low with Saturation   
			wait for 4ns;
			
		for i in 0 to 3 loop
	
			instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --first 4 16 bit R4 Functions
			wait for 4ns;
			
		end loop;
		
		std.env.finish;		-- done
	end process;
	
end TB_Architecture;