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
			imm => imm
		);
		
	-- System Clock Process
	clock_gen : process
	begin
		wait for clk_period/2;
		loop	-- inifinite loop
			wait for clk_period/2;
			exit when END_SIM = true;
		end loop;
		std.env.finish;
	end process;
	
	-- Simulation control process
	sim_cntrl: process
	begin
		--MAIN CODE FOR TESTING EACH FUNCTION GOES HERE 
		std.env.finish;		-- done
	end process;
	
end TB_Architecture;