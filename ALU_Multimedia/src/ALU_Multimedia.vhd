-------------------------------------------------------------------------------
--
-- Title       : ALU
-- Design      : ProjectPartI
-- Author      : anirvan.kothuri@stonybrook.edu
-- Company     : Stony Brook University
--
-------------------------------------------------------------------------------
--
-- File        : C:
-- Generated   : Sun Oct 12 15:37:45 2025
-- From        : Interface description file
-- By          : ItfToHdl ver. 1.0
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--    and may be overwritten
--{entity {ALU} architecture {structural}}

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ALU is
	port(
		instr : in STD_LOGIC_VECTOR(5 downto 0);
		rs3 : out STD_LOGIC_VECTOR(127 downto 0)
		rs2 : out STD_LOGIC_VECTOR(127 downto 0)
		rs1 : out STD_LOGIC_VECTOR(127 downto 0)
		rd : out STD_LOGIC_VECTOR(127 downto 0);
	);
end ALU;

--}} End of automatically maintained section

architecture behavioral of ALU is  
	constant SIGNED_64_MAX: SIGNED(63 downto 0) := (63 => '0', others => '1'); --Setting MSB as 0 and everything else as 1
	constant SIGNED_64_MIN: SIGNED(63 downto 0) := (63 => '1', others => '0'); --Setting MSB as 1 and everything else as 0 to obtain the smallest signed number
begin

	process(instr, rs3, rs2, rs1)
		variable product_low : SIGNED(63 downto 0); --variable to store product of low 32 bits 
		variable product_high : SIGNED(63 downto 0); --variable to store product of high 32 bits
		
		--Variables to store 64 bit sum values
		variable sum_low : SIGNED(63 downto 0);  
		variable sum_high : SIGNED(63 downto 0);
		
		--Variables to store 65 bit sum values to perform clipping
		variable sum_low_65 : SIGNED(64 downto 0); 
		variable sum_high_65 : SIGNED(64 downto 0);
	begin
    	case instr
        	when "00000" =>    -- Load Immediate 
				case ld_in
			        when "000" => rd <= rd(127 downto 16) + imm;
			        when "001" => rd <= rd(127 downto 32) + imm + rd(15 downto 0);
			        when "010" => rd <= rd(127 downto 48) + imm + rd(31 downto 0);
			        when "011" => rd <= rd(127 downto 64) + imm + rd(47 downto 0);
			        when "100" => rd <= rd(127 downto 80) + imm + rd(63 downto 0);
			        when "101" => rd <= rd(127 downto 96) + imm + rd(79 downto 0);
			        when "110" => rd <= rd(127 downto 112) + imm + rd(95 downto 0);
			        when "111" => rd <= imm + rd(111 downto 0);

	        -- Multiply-Add and Multiply-Subtract R4-Instruction Format
	        when "00001" => -- Signed Integer Multiply-Add Low with Saturation 
	        when "00010" =>    -- Signed Integer Multiply-Add High with Saturation
	        when "00011" =>    -- Signed Integer Multiply-Subtract Low with Saturation
	        when "00100" =>    -- Signed Integer Multiply-Subtract High with Saturation			 
	        when "00101" =>    -- Signed Long Integer Multiply-Add Low with Saturation
			
				  product_low := SIGNED(rs2(31 downto 0)) * SIGNED(rs3(31 downto 0)); --computing and storing lower product(Lower 32 Bits)
				  product_high := SIGNED(rs2(95 downto 64)) * SIGNED(rs3(95 downto 64)); --computing and storing the high product	
				  
				  --performing addition with the two product values
				  sum_low_65 := resize(SIGNED(rs1(63 downto 0)),65) + resize(product_low,65);  --performing signed extension by resizing to 65 bits to perform clipping
				  sum_high_65 := resize(SIGNED(rs1(127 downto 64)),65) + resize(product_high,65); 
				  
				  --checking sum_low and clipping
				  if(sum_low_65 > resize(SIGNED_64_MAX,65)) then
					  --Overflow has occured
					  sum_low := SIGNED_64_MAX; --Clipping by setting sum to the maximum value
				  elsif(sum_low_65 < resize(SIGNED_64_MIN,65)) then
					  --Underflow has occured
					  sum_low := SIGNED_64_MIN; --Clipping for underflow
				  else
					  sum_low := resize(sum_low_65, 64); --No clipping is required, so sum is resized to 64 bits
				  end if;  
					  --checking sum_high 
				  if(sum_high_65 > resize(SIGNED_64_MAX,65)) then
					  --Overflow has occured
					  sum_high := SIGNED_64_MAX; --Clipping for overflow
				  elsif(sum_high_65 < resize(SIGNED_64_MIN,65)) then
					  --Underflow has occured
					  sum_high := SIGNED_64_MIN; --Clipping for underflow
				  else
					  sum_high := resize(sum_high_65, 64); --No clipping is required, so sum is resized to 64 bits
				  end if;  
				--Transferring sum_high and sum_low into register rd
				rd(127 downto 64) <= STD_LOGIC_VECTOR(sum_high);	--Assigning sum_high to top half of rd
				rd(63 downto 0) := STD_LOGIC_VECTOR(sum_low);		--Assigning sum_low to top bottom half of rd
				
	        when "00110" =>    -- Signed Long Integer Multiply-Add High with Saturation
			
				  product_low := SIGNED(rs2(63 downto 32)) * SIGNED(rs3(63 downto 32)); --computing and storing lower product( Higher 32 Bits)
				  product_high := SIGNED(rs2(127 downto 96)) * SIGNED(rs3(127 downto 96)); --computing and storing the high product	
				  
				  --performing addition with the two product values
				  sum_low_65 := resize(SIGNED(rs1(63 downto 0)),65) + resize(product_low,65);  --performing signed extension by resizing to 65 bits to perform clipping
				  sum_high_65 := resize(SIGNED(rs1(127 downto 64)),65) + resize(product_high,65); 
				  
				  --checking sum_low and clipping
				  if(sum_low_65 > resize(SIGNED_64_MAX,65)) then
					  --Overflow has occured
					  sum_low := SIGNED_64_MAX; --Clipping by setting sum to the maximum value
				  elsif(sum_low_65 < resize(SIGNED_64_MIN,65)) then
					  --Underflow has occured
					  sum_low := SIGNED_64_MIN; --Clipping for underflow
				  else
					  sum_low := resize(sum_low_65, 64); --No clipping is required, so sum is resized to 64 bits
				  end if;  
					  --checking sum_high 
				  if(sum_high_65 > resize(SIGNED_64_MAX,65)) then
					  --Overflow has occured
					  sum_high := SIGNED_64_MAX; --Clipping for overflow
				  elsif(sum_high_65 < resize(SIGNED_64_MIN,65)) then
					  --Underflow has occured
					  sum_high := SIGNED_64_MIN; --Clipping for underflow
				  else
					  sum_high := resize(sum_high_65, 64); --No clipping is required, so sum is resized to 64 bits
				  end if;  
				--Transferring sum_high and sum_low into register rd
				rd(127 downto 64) <= STD_LOGIC_VECTOR(sum_high);	--Assigning sum_high to top half of rd
				rd(63 downto 0) := STD_LOGIC_VECTOR(sum_low);		--Assigning sum_low to top bottom half of rd 
				
	        when "00111" =>    -- Signed Long Integer Multiply-Subtract Low with Saturation
	        when "01000" =>    -- Signed Long Integer Multiply-Subtract High with Saturation
	
	        -- R3-Instruction Format
	        when "01001" =>    -- NOP
	        when "01010" =>    -- SHRHI
	        when "01011" =>    -- AU
	        when "01100" =>    -- CNT1H
	        when "01101" =>    -- AHS
	        when "01110" =>    -- OR
	        when "01111" =>    -- BCW
	        when "10000" =>    -- MAXWS
	        when "10001" =>    -- MINWS
	        when "10010" =>    -- MLHU
	        when "10011" =>    -- MLHCU
	        when "10100" =>    -- AND
	        when "10101" => -- CLZW
	        when "10110" =>    -- ROTW
	        when "10111" =>    -- SFWU
	        when "11000" =>    -- SFHS
		
			-- Invalid
			when others => 

end structural;	
