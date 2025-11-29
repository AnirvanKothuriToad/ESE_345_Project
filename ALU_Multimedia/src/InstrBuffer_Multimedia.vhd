						   -------------------------------------------------------------------------------
--
-- Title       : InstrBuffer
-- Design      : ProjectPartI
-- Author      : Anirvan Kothuri and Mahir Patel
-- Company     : Stony Brook University
--
-------------------------------------------------------------------------------
--
-- File        : C:/Users/mpa32/Desktop/ESE 345/Project Part I/ProjectPartI/ProjectPartI/src/RegFile_Multimedia.vhd
-- Generated   : Tue Nov  10 18:46:26 2025
-- From        : Interface description file
-- By          : ItfToHdl ver. 1.0
--
-------------------------------------------------------------------------------
--
-- Description : Instruction buffer with 64 25-bit regsiters for use in multimedia
--				 pipelined CPU
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--    and may be overwritten
--{entity {InstrBuffer} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity InstrBuffer is
	port(	
		reset : in STD_LOGIC;							  	-- Asynchronous reset
		clk : in STD_LOGIC;							   	-- Clock signal
		write_enable : in STD_LOGIC;					  	-- If enabled, write to register pointed to by address_in
		PC_in  : in STD_LOGIC_VECTOR(5 downto 0);			-- PC input address (0 to 63)
		
		data_in : in STD_LOGIC_VECTOR(24 downto 0);			-- Value to write to current line address	  
		data_out : out STD_LOGIC_VECTOR(24 downto 0)	   		-- Value read from current line address
													
	);
end InstrBuffer;

--}} End of automatically maintained section

architecture behavioral of InstrBuffer is  

type INSTR_BUFFER_TYPE is array(0 to 63) of STD_LOGIC_VECTOR(24 downto 0);	-- Create type of 64 25-bit registers 

signal INSTR_BUFFER : INSTR_BUFFER_TYPE := (others => (others => '0'));	-- Create actual signal using type and clear all registers

begin

	process (reset, clk) is	-- Only operating on rising clock edges unless reset is asserted
	
	begin
		if (reset = '1') then	-- Asynchronous reset, does not rely on clk
			
			-- Clear instruction buffer and set all outputs to 0
			
			INSTR_BUFFER <= (others => (others => '0'));
			data_out <= (others => '0');
			
			
		else  -- reset not asserted, function normally
			
			if rising_edge(clk) then 	-- Update on every positive edge of clk 
				
				-- Read value pointed to by PC (connected to address input)
				
				data_out <= INSTR_BUFFER(TO_INTEGER(UNSIGNED(PC_in)));
			
				if (write_enable = '1')	then -- Write is enabled, write to pointed-to register
					
					INSTR_BUFFER(TO_INTEGER(UNSIGNED(PC_in))) <= data_in;
					
					
				end if;
				
			end if;
			
		end if;	
					
	end process;

end behavioral;
