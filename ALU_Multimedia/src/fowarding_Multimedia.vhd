-------------------------------------------------------------------------------
--
-- Title       : Forwarding_Unit
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
-- Description : Design to forward register values when needed for pipelined processor
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--    and may be overwritten
--{entity {InstrBuffer} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity forwarding is
	port(	  
	
		-- Register numbers that are being read by current instruction
		rs1 : in STD_LOGIC_VECTOR(4 downto 0);	   			-- rs1 input
		rs2 : in STD_LOGIC_VECTOR(4 downto 0);	   			-- rs2 input
		rs3 : in STD_LOGIC_VECTOR(4 downto 0);	   			-- rs3 input
		
		-- Register that is being written to in last instruction
		rd : in STD_LOGIC_VECTOR(4 downto 0);	   			-- rd input
		
		-- Register values to forward to
		rs1_d : out STD_LOGIC_VECTOR(127 downto 0);	   		-- rs1_d output
		rs2_d : out STD_LOGIC_VECTOR(127 downto 0);	   		-- rs2_d output
		rs3_d : out STD_LOGIC_VECTOR(127 downto 0);	   		-- rs3_d output	
		
		-- Register value to forward
		rd_d : in STD_LOGIC_VECTOR(127 downto 0);			-- rd_d input 
		
		forward : out STD_LOGIC								-- Forwarding MUX control signal
		
	);
end forwarding;

--}} End of automatically maintained section

architecture behavioral of forwarding is  

begin

	process(rs1, rs2, rs3, rd, rd_d) is	-- Only operating on rising clock edges unless reset is asserted
	
	begin		  
		
		if rd = rs1 then   
			
			-- If register that is being written to matches register that is being read from, forward value
			forward <= '1';		-- Assert forward control signal	  
			rs1_d <= rd_d;		-- Directly copy value for rd_d to rs1_d 
			rs2_d <= (others => '-');	-- Other register data is don't cares 
			rs3_d <= (others => '-');
			
		elsif rd = rs2 then
			forward <= '1';
			rs1_d <= (others => '-');
			rs2_d <= rd_d;
			rs3_d <= (others => '-');
			
		elsif rd = rs3 then	
			forward <= '1';
			rs1_d <= (others => '-');
			rs2_d <= (others => '-');
			rs3_d <= rd_d;
			
		else  -- Forwarding unnecessary, turn off control signal
			forward <= '0';
			rs1_d <= (others => '-');
			rs2_d <= (others => '-');
			rs3_d <= (others => '-');
			
		end if;
		
	end process;

end behavioral;
