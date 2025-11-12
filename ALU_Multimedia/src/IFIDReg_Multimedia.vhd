-------------------------------------------------------------------------------
--
-- Title       : IFIDReg
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
-- Description : IF/ID pipeline register for multimedia processor
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--    and may be overwritten
--{entity {InstrBuffer} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity IFID is
	port(	
		reset : in STD_LOGIC;							  	-- Asynchronous reset
		clk : in STD_LOGIC;							   		-- Clock signal	 
		data_in : out STD_LOGIC_VECTOR(24 downto 0);	   	-- Input
		data_out : out STD_LOGIC_VECTOR(24 downto 0)		-- Output													
	);
end IFID;

--}} End of automatically maintained section

architecture behavioral of IFID is  

begin

	process (reset, clk) is	-- Only operating on rising clock edges unless reset is asserted
	
	begin
		if (reset = '1') then	-- Asynchronous reset, does not rely on clk
			
			-- Clear register
			
			data_out <= (others => '0');
			
			
		else  -- reset not asserted, function normally
			
			if rising_edge(clk) then 	-- Update on every positive edge of clk 
				
				-- 25-bit shift register
				data_out <= data_in;
				
				
			end if;
			
		end if;	
					
	end process;

end behavioral;
