-------------------------------------------------------------------------------
--
-- Title       : RegFile
-- Design      : ProjectPartI
-- Author      : Anirvan Kothuri and Mahir Patel
-- Company     : Stony Brook University
--
-------------------------------------------------------------------------------
--
-- File        : C:/Users/mpa32/Desktop/ESE 345/Project Part I/ProjectPartI/ProjectPartI/src/RegFile_Multimedia.vhd
-- Generated   : Tue Nov  4 18:46:26 2025
-- From        : Interface description file
-- By          : ItfToHdl ver. 1.0
--
-------------------------------------------------------------------------------
--
-- Description : Register file with 32 128-bit regsiters for use in multimedia
--				 pipelined CPU
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--    and may be overwritten
--{entity {RegFile} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity RegFile is
	port(	
		reset : in STD_LOGIC;							   -- Asynchronous reset
		clk : in STD_LOGIC;								   -- Clock signal
		write_enable : in STD_LOGIC;					   -- If enabled, write to register pointed to by address_in
		
		
		address_out_A : in STD_LOGIC_VECTOR(5 downto 0);   -- Register to read from (A)
		address_out_B : in STD_LOGIC_VECTOR(5 downto 0);   -- Register to read from (B)
		address_out_C : in STD_LOGIC_VECTOR(5 downto 0);   -- Register to read from (C)	
		data_out_A : out STD_LOGIC_VECTOR(127 downto 0);   -- Value read from register (A)
		data_out_B : out STD_LOGIC_VECTOR(127 downto 0);   -- Value read from register (B)
		data_out_C : out STD_LOGIC_VECTOR(127 downto 0);   -- Value read from register (C)
		
		
		address_in : in STD_LOGIC_VECTOR(5 downto 0); 	   -- Register to write to
		data_in : in STD_LOGIC_VECTOR(127 downto 0)		   -- Value to write to register
		
	);
end RegFile;

--}} End of automatically maintained section

architecture behavioral of RegFile is  

type REG_FILE_TYPE is array(0 to 31) of STD_LOGIC_VECTOR(127 downto 0);	-- Create type of 32 128-bit registers 

signal REG_FILE : REG_FILE_TYPE := (others => (others => '0'));	-- Create actual signal using type and clear all registers

begin

	process (reset, clk) is	-- Only operating on rising clock edges unless reset is asserted
	
	begin
		if (reset = '1') then	-- Asynchronous reset, does not rely on clk
			
			-- Clear register file and set all outputs to 0
			
			REG_FILE <= (others => (others => '0'));
			data_out_A <= (others => '0');
			data_out_B <= (others => '0');
			data_out_C <= (others => '0'); 
			
			
		else  -- reset not asserted, function normally
			
			if rising_edge(clk) then 	-- Update on every positive edge of clk 
				
				-- Read value from each of the three pointed-to registers
				
				data_out_A <= REG_FILE(TO_INTEGER(UNSIGNED(address_out_A)));
				data_out_B <= REG_FILE(TO_INTEGER(UNSIGNED(address_out_B)));
				data_out_C <= REG_FILE(TO_INTEGER(UNSIGNED(address_out_C))); 
			
				if (write_enable = '1')	then -- Write is enabled, write to pointed-to register
					
					REG_FILE(TO_INTEGER(UNSIGNED(address_in))) <= data_in;
					
					-- Need to implement bypass if register that is being written to is also being read from in same clk edge 
						
					if (address_in = address_out_A) then data_out_A <= data_in; 	-- Directly write input to output 
					end if;
					
					if (address_in = address_out_B) then data_out_B <= data_in;
					end if;													
					
					if (address_in = address_out_C) then data_out_C <= data_in;
					end if;
					
				end if;
				
			end if;
			
		end if;
					
	end process;

end behavioral;
