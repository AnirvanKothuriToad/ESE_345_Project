-------------------------------------------------------------------------------
--
-- Title       : EXWBReg
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

entity EXWB is
	port(	
		reset : in STD_LOGIC;							  	-- Asynchronous reset
		clk : in STD_LOGIC;							   		-- Clock signal	
		
		-- Destination register number
		rd_in : in STD_LOGIC_VECTOR(4 downto 0);		  		-- rd input
		rd_out : out STD_LOGIC_VECTOR(4 downto 0);				-- rd output  
		
		-- Destination register data
		rd_d_in : in STD_LOGIC_VECTOR(127 downto 0);	   		-- rd_d input
		rd_d_out : out STD_LOGIC_VECTOR(127 downto 0)	   		-- rd_d output
	);
end EXWB;

--}} End of automatically maintained section

architecture behavioral of EXWB is  

begin

	process (reset, clk) is	-- Only operating on rising clock edges unless reset is asserted
	
	begin
		if (reset = '1') then	-- Asynchronous reset, does not rely on clk
			
			-- Clear register
			
			rd_out <= (others => '0'); 	 
			rd_d_out <= (others => '0'); 
			
			
		else  -- reset not asserted, function normally
			
			if rising_edge(clk) then 	-- Update on every positive edge of clk 
				
				rd_out <= rd_in; 
				rd_d_out <= rd_d_in;
				
				
			end if;
			
		end if;	
					
	end process;

end behavioral;
