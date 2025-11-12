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
-- Description : EX/WB pipeline register for multimedia processor
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
		c : in STD_LOGIC_VECTOR(1 downto 0);		-- Bits 24 and 23 of instruction 
	   
		write_enable : out STD_LOGIC				-- Write enable (always on unless nop)
		ALU_source : out STD_LOGIC					-- Choose between register or immediate based on instruction	
		is_load	: out STD_LOGIC						-- Switch MUX inputs if load instruction (rs1 <= load_index, rs2 <= )
		
	
	);
end control;

--}} End of automatically maintained section

architecture behavioral of control is  

begin

	process(c) is	-- Only operating on rising clock edges unless reset is asserted
	
	begin
		
		write_enable = '1';		-- Will be overwritten to 0 if nop (c = "00" and opcode = "xxxx0000")		  
		
		if c(1) = '0' then	   -- Load Immediate instruction  
		-- Need to write rd to rs1, tell ALU to read instr(23 downto 21) as load index,
		-- instr(20 downto 5) as imm, 
		
			
					
	end process;

end behavioral;
