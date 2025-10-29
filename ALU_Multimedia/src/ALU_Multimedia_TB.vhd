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
		   
		   ------TESTING R4 FUNCTIONS------------------------------------
		   
		   		--------------------------------------------------------------
		   		--Testing Signed Integer Multiply add/sub and Low/High (16 bit variant)
		   		--------------------------------------------------------------
		   
		   	ld_in <= "000"; --Not testing load index
			        --Normal Addition	  --Overflow Add	 --Underflow Add		 --Subtract		    --Overflow Sub		--Underflow Sub
			rs2 <= "0000000000000001" & "0000000000000010" & "0000000000000011" & "0000000000000100" & "0000000000000101" & "0000000000000110" & "0111111111111111" & "1000000000000000";
			rs1 <= "0000000011000000" & "0111111111111111" & "1000000000000000" & "0000000000000001" & "1000000000000000" & "0111111111111111" & "0000000000000001" & "0000000000000001"; 
			rs3 <= "0000000000000001" & "0000000000000001" & "0000000000000001" & "0000000000000001" & "0000000000000001" & "0000000000000001" & "0000000000000001" & "0000000000000001";
			instr <= "00001"; --Testing  Signed Integer Multiply-Add Low with Saturation   
			wait for 4ns;
			
			for i in 0 to 2 loop
	
				instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --first 4 16 bit R4 Functions
				wait for 4ns;
			
			end loop;
			
					-----------------------------------------------------------
					--Testing Signed Long Integer Multiply Add and LOW and HIGH (32 bit variant)
					-----------------------------------------------------------
			
					 --Normal Addition					  --Overflow Addition				   --Underflow Addition
			rs2 <= "00000000000000010000000000000001" & "01111111111111110111111111111111" & "00000000000000000000000000000001" & "00000000000000000000000000000000";
			rs1 <= "00000000000000000000000000000001" & "01111111111111110111111111111111" & "10000000000000000000000000000000" & "00000000000000000000000000000000";
			rs3 <= "00000000000000000000000000000001" & "00000000000000000000000000000001" & "00000000000000000000000000000001" & "00000000000000000000000000000001";
			
			instr <= "00101"; --Setting instruction to SIGN LONG MULTIPLY ADD LOW
			wait for 4ns; --Allowing new inputs to update and compute rd
			
			instr <= "00110"; --Setting instruction to SIGN LONG MULTIPLY ADD HIGH
			wait for 4ns; --Computing rd
			
					-----------------------------------------------------------
					--Testing Signed Long Integer Multiply Subtract and LOW and HIGH (32 bit variant)
					-----------------------------------------------------------
			
					--Normal Subtraction					--Overflow Subtraction				  --Underflow Subtraction
			rs2 <= "00000000000000010000000000000000" & "01111111111111110111111111111111" & "00000000000000000000000000000001" & "00000000000000000000000000000000";
			rs1 <= "00000000000000000000000000000001" & "10000000000000000000000000000000" & "10000000000000000000000000000000" & "00000000000000000000000000000000";
			rs3 <= "00000000000000000000000000000001" & "00000000000000000000000000000001" & "00000000000000000000000000000001" & "00000000000000000000000000000000";
			
			instr <= "00111"; --Setting instruction to SIGN LONG MULTIPLY SUB LOW 
			wait for 4ns; --Allowing new inputs to update and compute rd
			
			instr <= "01000"; --Setting instruction to SIGN LONG MULTIPLY SUB HIGH
			wait for 4ns; --Computing rd
			
		   -------END OF R4 FUNCTION TESTING--------------------------
		   
		   
		   -----------------------------------------------------------
		   --------TESTING R3 FUNCTIONS-------------------------------
		   ----------------------------------------------------------- 
		   
		   	-------------------------
		   		--NOP
		   	-------------------------
			   
		   	instr <= "01001"; --Setting to NOP function
		   	wait for 4ns;    --Output should not change for no op 
			   
			 -------------------------
            	  -- SHRHI
			-------------------------
		   
		   	instr <= "01010"; --Setting to SHRHI Function
		   	rs1   <= "11110000000000000000000000000000" & "00000000000000000000000000000000" & "00000000000000000000000000000000" & "00000000000000000000000000001111"; --Setting LSBS to 1 to show how shifted bits are discarded correctly
		   	rs2   <= STD_LOGIC_VECTOR(to_unsigned(4, 128)); --Setting vector to 4, so the shift amount is 4 as LSB value is also 4
		   	wait for 4ns;
		   
		  	-------------------------
            	  -- AU
			-------------------------  
		  
		  	instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to AU
		  		 	--Testing overflow					   --Normal Addition
		  	rs1   <= "11111111111111111111111111111111" & "00000000000000000000000110000000" & "00000000000000000000000000000000" & "00000000000000000000000000001111";
		  	rs2   <= "11111111111111111111111111111111" & "00000000000000000000000000000000" & "00000000000000000000000000000000" & "00000000000000000000000000000000";
		  	wait for 4ns; --Updating input
		   
		 	-------------------------
            	  -- CNT1H
			------------------------- 
			
		  	instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to CNT1H
		  		  	--Testing all 0s		   All 1s
		  	rs1   <= "0000000000000000" & "1111111111111111" & "0000000000000011" & "0000000000000100" & "0000000000000101" & "0000000000000110" & "0111111111111111" & "1000000000000000";
		  	wait for 4ns;
		  
		    -------------------------
            	  -- AHS
			------------------------- 
			
			instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to AHS
		  		 --Testing overflow					   --Normal Addition			            --Testing Underflow
		  	rs1   <= "01111111111111111111111111111111" & "00000000000000000000000110000000" & "11100000000000000000000000000000" & "00000000000000000000000000001111";
		  	rs2   <= "01111111111111111111111111111100" & "00000000000000000000000000000000" & "10000000000000000000000000000000" & "00000000000000000000000000000000";
		  	wait for 4ns; --Updating input
		  
		  	-------------------------
            	  -- OR
			------------------------- 
			
			instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to OR
			
			rs1 <= "11111111111111111111111111111111" & "00000000000000000000000000000000" & "00000000000000000000000000001111" & "00000000000000000000000000000000";
			rs2 <= "00000000000000000000000000000000" & "00000000000000000000000000001111" & "00000000000000000000000000000000" & "00000000000000000000000000000000";
			wait for 4ns;
			
			-------------------------
            	  -- BCW
			-------------------------
			
			instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to BCW
			
			rs1 <= "11111111111111111111111111111111" & "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"; --Setting broadcasting word as all 1s
			wait for 4ns;
			
			-------------------------
            	  -- MAXWS
			-------------------------
			
			instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to MAXWS
					--Testing when R1 word is greater	 --Testing when R1 word is smaller	   --Equal
			rs1 <= "01111111111111111111111111111111" &	"10000000000000000000000000000000" &  "00000000000000000000000000000000" & "00000000000000000000000000000000";
			rs2 <= "00000000000000000000000000001111" &	"00000000000000000000000000001111" &  "00000000000000000000000000000000" & "00000000000000000000000000000000";
			wait for 4ns;
			
			-------------------------
            	  -- MINWS
			-------------------------
			
			instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to MINWS
				   --Testing when R2 word is smaller	     --Testing when R1 word is smaller	   --Equal
			rs1 <= "01111111111111111111111111111111" &	"10000000000000000000000000000000" &  "00000000000000000000000000000000" & "00000000000000000000000000000000";
			rs2 <= "11111111111111111111111111111111" &	"00000000000000000000000000001111" &  "00000000000000000000000000000000" & "00000000000000000000000000000000";
			wait for 4ns;	
			
			-------------------------
            	  -- MLHU
			-------------------------
			
			instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to MLHU						   
					  --3x0			--65535x65535		     3x3					 4x1				 4x4				     0x0			      
			rs1 <= "0000000000000000" & "1111111111111111" & "0000000000000011" & "0000000000000100" & "0000000000000101" & "0000000000000000" & "0000000000000000" & "0000000000000000";
			rs2 <= "0000000000000011" & "1111111111111111" & "0000000000000011" & "0000000000000001" & "0000000000000101" & "0000000000000000" & "0111111111111111" & "1000000000000000";
			
			wait for 4ns;
			
			-------------------------
            	  -- MLHCU
			-------------------------
			
			instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to MLHCU
			
			rs2 <= STD_LOGIC_VECTOR(to_unsigned(4,128)); --Setting the 5 bit constant to 4 in decimal. so RS1's low half words are multiplied 4
			rs1 <= "0000000000000000" & "1111111111111111" & "0000000000000011" & "0000000000000100" & "0000000000000101" & "0000000000000000" & "0000000000000000" & "0000000000000000";
			wait for 4ns;
			
			-------------------------
            	  -- AND
			-------------------------
			
			instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to ADD
			
			rs1 <= "01111111111111111111111111111111" &	"10000000000000000000000000001010" &  "11000000000000000000000000000000" & "00000000000000000000000000000000";
			rs2 <= "11111111111111111111111111111111" &	"00000000000000000000000000001111" &  "11000000000000000000000000000000" & "00000000000000000000000000000000";
			wait for 4ns;
			
			-------------------------
            	  -- CLZW
			-------------------------
			
			instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to CLZW
					--Only 1 0							 --0 leading 0s					         --30 Leading 0s				   -- All 0s
			rs1 <= "01111111111111111111111111111111" &	"10000000000000000000000000001010" &  "00000000000000000000000000000011" & "00000000000000000000000000000000";
			wait for 4ns;
			
			-------------------------
            	  -- ROTW
			-------------------------
			
			instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to ROTW
			
			rs2 <= STD_LOGIC_VECTOR(to_unsigned(4,128)); --Setting the 5 bit constant to 4. The words in rs1 will be rotated 4 times. 
				    --Testing wrapping
			rs1 <= "00000000000000000000000000001111" & "11000000000000000000000000000011" & "00000000000111000000000000000000" & "00000000000000000000000000000000";
			wait for 4ns;
			
			-------------------------
            	  -- SFWU
			-------------------------
			
			instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to SFWU	
			         --Underflow W/O saturation					 --Normal
			rs2 <= "01111111111111111111111111111111" &	"11111111111111111111111111111111" &  "01111111111111111111111111111111" & "00000000000000000000000000000000";
			rs1 <= "11111111111111111111111111111111" &	"11111111111111111111111111111110" &  "10000000000000000000000000000000" & "00000000000000000000000000000000";
			
			wait for 4ns;
			
			-------------------------
            	  -- SFHS
			-------------------------  
			
			instr <= STD_LOGIC_VECTOR(UNSIGNED(instr) + 1); --setting instr to SFWH	
			
					--Underflow  W Saturation							 --Normal				 --Overflow
			rs2 <= "10000000000000000000000000000000" &	"11111111111111111111111111111111" &  "01111111111111111111111111111111" & "00000000000000000000000000000000";
			rs1 <= "00000000000000000000000000000001" &	"11111111111111111111111111111110" &  "10000000000000000000000000000000" & "00000000000000000000000000000000"; 
			wait for 4ns;
			
	
		---------------------------------------
		---END OF R3 FUNCTION TESTING----------
		---------------------------------------
			
			
	std.env.finish; --Testbench Complete
	end process;
	
end TB_Architecture;