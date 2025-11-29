-------------------------------------------------------------------------------
--
-- Title       : IDEXReg
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
-- Description : ID/EX pipeline register for multimedia processor
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--    and may be overwritten
--{entity {InstrBuffer} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity IDEX is
	port(	
		reset : in STD_LOGIC;							  	-- Asynchronous reset
		clk : in STD_LOGIC;							   		-- Clock signal	
		
		-- Read register numbers (rs1, rs2, rs3)
		rs1_in : in STD_LOGIC_VECTOR(4 downto 0);	   		-- rs1 input
		rs1_out : out STD_LOGIC_VECTOR(4 downto 0);	   		-- rs1 output 
		
		rs2_in : in STD_LOGIC_VECTOR(4 downto 0);	   		-- rs2 input
		rs2_out : out STD_LOGIC_VECTOR(4 downto 0);	   		-- rs2 output 
		
		rs3_in : in STD_LOGIC_VECTOR(4 downto 0);	   		-- rs3 input
		rs3_out : out STD_LOGIC_VECTOR(4 downto 0);	   		-- rs3 output 
		
		-- Read register data (rs1_d, rs2_d, rs3_d)
		rs1_d_in : in STD_LOGIC_VECTOR(127 downto 0);	   	-- rs1_d input
		rs1_d_out : out STD_LOGIC_VECTOR(127 downto 0);	   	-- rs1_d output
		
		rs2_d_in : in STD_LOGIC_VECTOR(127 downto 0);	   	-- rs2_d input
		rs2_d_out : out STD_LOGIC_VECTOR(127 downto 0);	   	-- rs2_d output
		
		rs3_d_in : in STD_LOGIC_VECTOR(127 downto 0);	   	-- rs3_d input
		rs3_d_out : out STD_LOGIC_VECTOR(127 downto 0);	   	-- rs3_d output
		
		
		-- Write register number (rd)
		rd_in : in STD_LOGIC_VECTOR(4 downto 0);	   		-- rd input
		rd_out : out STD_LOGIC_VECTOR(4 downto 0);	   		-- rd output
		
		
		-- Load immediate (imm, ind)
		imm_in : in STD_LOGIC_VECTOR(15 downto 0);			-- imm input	 
		imm_out : out STD_LOGIC_VECTOR(15 downto 0);		-- imm output 
		
		ind_in : in STD_LOGIC_VECTOR(2 downto 0);			-- ind input
		ind_out : out STD_LOGIC_VECTOR(2 downto 0);			-- ind output
		
		
		-- R4 Format (long/int, subtract/add, high/low)
		LI_SA_HL_in : in STD_LOGIC_VECTOR(2 downto 0);		-- LI/SA/HL input
		LI_SA_HL_out : out STD_LOGIC_VECTOR(2 downto 0);	-- LI/SA/HL output	
		
		-- R3 Format (opcode)
		opcode_in : in STD_LOGIC_VECTOR(7 downto 0);		-- opcode input
		opcode_out : out STD_LOGIC_VECTOR(7 downto 0)		-- opcode output
		
	);
end IDEX;

--}} End of automatically maintained section

architecture behavioral of IDEX is  

begin

	process (reset, clk) is	-- Only operating on rising clock edges unless reset is asserted
	
	begin
		if (reset = '1') then	-- Asynchronous reset, does not rely on clk
			
			-- Clear register
			 
			rs1_out <= (others => '0');
			rs2_out <= (others => '0');
			rs3_out <= (others => '0');
			
			rs1_d_out <= (others => '0');
			rs2_d_out <= (others => '0');
			rs3_d_out <= (others => '0');
			
			rd_out <= (others => '0');
			
			imm_out	<= (others => '0');
			ind_out <= (others => '0');
			
			LI_SA_HL_out <= (others => '0');   
			
			opcode_out <= (others => '0');
			
			
		else  -- reset not asserted, function normally
			
			if rising_edge(clk) then 	-- Update on every positive edge of clk 
				
				-- Shift register with various inputs/outputs
				
				rs1_out <= rs1_in;
				rs2_out <= rs2_in;
				rs3_out <= rs3_in; 		 
				
				rs1_d_out <= rs1_d_in;
				rs2_d_out <= rs2_d_in;
				rs3_d_out <= rs3_d_in; 
				
				rd_out <= rd_in;
				
				imm_out <= imm_in;
				ind_out <= ind_in;
				
				LI_SA_HL_out <= LI_SA_HL_in;
				
				opcode_out <= opcode_in;
				
				
			end if;
			
		end if;	
					
	end process;

end behavioral;
