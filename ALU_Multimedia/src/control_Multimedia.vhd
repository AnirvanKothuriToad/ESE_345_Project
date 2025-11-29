-------------------------------------------------------------------------------
--
-- Title       : Control
-- Design      : ProjectPartI
-- Author      : Anirvan Kothuri and Mahir Patel
-- Company     : Stony Brook University
--
-------------------------------------------------------------------------------
--
-- File        : C:/Users/mpa32/Desktop/ESE 345/Project Part I/ProjectPartI/ProjectPartI/src/RegFile_Multimedia.vhd
-- Generated   : Tue Nov  11 18:46:26 2025
-- From        : Interface description file
-- By          : ItfToHdl ver. 1.0
--
-------------------------------------------------------------------------------
--
-- Description : Design to generate control signals for pipelined processor
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--    and may be overwritten
--{entity {InstrBuffer} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity control is
	port(	
		instr : in STD_LOGIC_VECTOR(24 downto 0);	-- Binary instruction 
	   
		write_enable : out STD_LOGIC;				-- Write enable (always on unless nop)	   
		ALU_op : out STD_LOGIC_VECTOR(4 downto 0);	-- ALU operation 						
		ALU_source : out STD_LOGIC;					-- Choose between register or immediate based on instruction	
		is_load	: out STD_LOGIC						-- Switch MUX inputs if load instruction 
													-- (rs1(18 downto 16) <= load_index, rs1(15 downto 0) <= load_imm, rs2 <= rd)
		
	
	);
end control;

--}} End of automatically maintained section

architecture behavioral of control is  

begin

	process(instr) is	-- Only operating on rising clock edges unless reset is asserted
	
	begin		  
		
		-----------------------------------------------------
		if instr(24) = '0' then	-- Load Immediate instruction 
		-----------------------------------------------------
		
			ALU_op <= (others => '0'); -- ALU operation for load immediate
			write_enable <= '1';	-- Will be writing to rd
			is_load <= '1'; 		-- Need to tell MUXs to switch
		
		---------------------------------------------	
		elsif instr(23) = '0' then	-- R4 Instruction
		---------------------------------------------
			
			write_enable <= '1';	-- Always on for any R4 instruction
			is_load <= '0';			-- Not load immediate instruction
			
			case instr(22 downto 20) is
				
				when "000" =>	-- Signed Integer Multiply-Add Low with Saturation
					ALU_op <= "00001";
				
				when "001" =>	-- Signed Integer Multiply-Add High with Saturation
					ALU_op <= "00010";
				
				when "010" =>	-- Signed Integer Multiply-Subtract Low with Saturation
					ALU_op <= "00011"; 
				
				when "011" =>	-- Signed Integer Multiply-Subtract High with Saturation
					ALU_op <= "00100"; 
				
				when "100" =>	-- Signed Long Integer Multiply-Add Low with Saturation
					ALU_op <= "00101";
				
				when "101" =>	-- Signed Long Integer Multiply-Add High with Saturation
					ALU_op <= "00110"; 
				
				when "110" =>	-- Signed Long Integer Multiply-Subtract Low with Saturation
					ALU_op <= "00111"; 
				
				when "111" =>	-- Signed Long Integer Multiply-Subtract High with Saturation
					ALU_op <= "01000";
				
				when others => 	-- Invalid
					ALU_op <= "XXXXX";
				
			end case;
		
		-------------------------
		else	-- R3 Instruction
		-------------------------
		
			write_enable <= '1';	-- All instructions except NOP write back to reg file 
			is_load <= '0';			-- Not load immediate instruction  
			
			case instr(18 downto 15) is	-- Useful opcode, rest is don't cares
				
				when "0000" =>	-- NOP	
					ALU_op <= "01001";
				
					write_enable <= '0';	-- Don't do anything
					
				
				when "0001" =>	-- SHRHI	
					ALU_op <= "01010";
				
				
				when "0010" =>	-- AU	
					ALU_op <= "01011";
				
				
				when "0011" =>	-- CNT1H	
					ALU_op <= "01100";
				
				
				when "0100" =>	-- AHS	
					ALU_op <= "01101";
				
				
				when "0101" =>	-- OR	
					ALU_op <= "01110";
				
				
				when "0110" =>	-- BCW	
					ALU_op <= "01111";
				
				
				when "0111" =>	-- MAXWS	
					ALU_op <= "10000";
				
				
				when "1000" =>	-- MINWS	
					ALU_op <= "10001";
				
				
				when "1001" =>	-- MLHU	
					ALU_op <= "10010";
				
				
				when "1010" =>	-- MLHCU	
					ALU_op <= "10011";
				
				
				when "1011" =>	-- AND	
					ALU_op <= "10100";
				
				
				when "1100" =>	-- CLZW	
					ALU_op <= "10101";
				
				
				when "1101" =>	-- ROTW	
					ALU_op <= "10110";
				
				
				when "1110" =>	-- SFWU	
					ALU_op <= "10111";
				
				
				when "1111" =>	-- SFHS	
					ALU_op <= "11000";
				
				when others =>
					write_enable <= '0'; --Not writing to ID/EX register file
					ALU_op <= (others => 'X');
				
			end case;		
				
		end if;
		
	end process;

end behavioral;
