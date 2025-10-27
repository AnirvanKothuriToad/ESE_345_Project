-------------------------------------------------------------------------------
--
-- Title       : ALU
-- Design      : ProjectPartI
-- Author      : Anirvan Kothuri and Mahir Patel
-- Company     : Stony Brook University
--
-------------------------------------------------------------------------------
--
-- File        : C:
-- Generated   : Sun Oct 10 15:37:45 2025
-- From        : Interface description file
-- By          : ItfToHdl ver. 1.0
--
-------------------------------------------------------------------------------
--
-- Description :
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {ALU} architecture {Behavioral}}

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ALU is
    port(
        instr : in STD_LOGIC_VECTOR(4 downto 0);
        rs3   : in STD_LOGIC_VECTOR(127 downto 0);
        rs2   : in STD_LOGIC_VECTOR(127 downto 0);
        rs1   : in STD_LOGIC_VECTOR(127 downto 0);

        ld_in : in STD_LOGIC_VECTOR(2 downto 0);
        imm   : in STD_LOGIC_VECTOR(15 downto 0);

        rd    : out STD_LOGIC_VECTOR(127 downto 0)
    );
end ALU;

--}} End of automatically maintained section

architecture behavioral of ALU is											  

	--Setting MSB as 0 and everything else as 1
	constant SIGNED_16_MAX : SIGNED(15 downto 0) := (15 => '0', others => '1');
	constant SIGNED_32_MAX : SIGNED(31 downto 0) := (31 => '0', others => '1');
	constant SIGNED_64_MAX : SIGNED(63 downto 0) := (63 => '0', others => '1');	  
	
	--Setting MSB as 1 and everything else as 0 to obtain the smallest signed number
	constant SIGNED_16_MIN : SIGNED(15 downto 0) := (15 => '1', others => '0');
	constant SIGNED_32_MIN : SIGNED(31 downto 0) := (31 => '1', others => '0');
    constant SIGNED_64_MIN : SIGNED(63 downto 0) := (63 => '1', others => '0');	 
	
begin

    process(instr, rs3, rs2, rs1, ld_in, imm) is 
	
	--Variables for Signed Multiplty Add High, Low 
		
		-- 16 bit variant:	 
		
			-- Variables of products (16-bit [half word] values to 32-bit product)
			variable product_1st_hw : SIGNED(31 downto 0); 
			variable product_2nd_hw : SIGNED(31 downto 0);
			variable product_3rd_hw : SIGNED(31 downto 0);
			variable product_4th_hw : SIGNED(31 downto 0); 	
			
			-- Store 32-bit sum
			variable sum_1st_w : SIGNED(31 downto 0);  
			variable sum_2nd_w : SIGNED(31 downto 0);
			variable sum_3rd_w : SIGNED(31 downto 0);
			variable sum_4th_w : SIGNED(31 downto 0);	 
			
			-- 33-bit variables to handle clipping
			variable sum_1st_w_33 : SIGNED(32 downto 0);
			variable sum_2nd_w_33 : SIGNED(32 downto 0);
			variable sum_3rd_w_33 : SIGNED(32 downto 0);
			variable sum_4th_w_33 : SIGNED(32 downto 0);
	
		
		-- 32 bit variant:
	        --variable to store product of low 32 bits
	        variable product_low  : SIGNED(63 downto 0);
	        --variable to store product of high 32 bits
	        variable product_high : SIGNED(63 downto 0);
	
	        --Variables to store 64 bit sum values
	        variable sum_low      : SIGNED(63 downto 0);
	        variable sum_high     : SIGNED(63 downto 0);
	
	        --Variables to store 65 bit sum values to perform clipping
	        variable sum_low_65   : SIGNED(64 downto 0);
	        variable sum_high_65  : SIGNED(64 downto 0);
			
	--Variables for Signed Muliplty subtract High, Low	
			
		-- 16-bit variant
		
			-- variables for 32-bit differences
			variable diff_1st_w : SIGNED(31 downto 0);
			variable diff_2nd_w : SIGNED(31 downto 0);
			variable diff_3rd_w : SIGNED(31 downto 0);
			variable diff_4th_w : SIGNED(31 downto 0);
			
			-- 33-bit variables to handle clipping;
			variable diff_1st_w_33 : SIGNED(32 downto 0);
			variable diff_2nd_w_33 : SIGNED(32 downto 0);
			variable diff_3rd_w_33 : SIGNED(32 downto 0);
			variable diff_4th_w_33 : SIGNED(32 downto 0);
			
			
			-- 32-bit variant: 
			
			  --Variables to store 64 bit difference values
	        variable diff_low     : SIGNED(63 downto 0);
	        variable diff_high    : SIGNED(63 downto 0); 
			
	        --Variables to store 65 bit difference values to perform clipping
	        variable diff_low_65  : SIGNED(64 downto 0);
	        variable diff_high_65 : SIGNED(64 downto 0);
			
		-- Variable for AHU
		variable sum_17 : SIGNED(16 downto 0); -- 17 bit variable to store sum for saturation rounding
			
		--Variables to hold the 4 products for MLHU and MLHCU	
		variable product : UNSIGNED(31 downto 0); --Stores the 32 bit product 
		variable five_const : UNSIGNED(4 downto 0); --5 bit constant from rs2	
		
		--Variables for CLZW
		variable count: INTEGER; --Counter variable to count 0s
		variable word: UNSIGNED(31 downto 0); --variable to store each word from rs1
		
		--Variables for SFHS
		variable diff_17 : SIGNED(16 downto 0); --17 bit variable to store difference.
		
    begin
        case instr is  
			----------------------------------
            when "00000" =>  -- Load Immediate
			----------------------------------	
			
                case ld_in is
                    when "000" => rd <= rs1(127 downto 16) & imm;
                    when "001" => rd <= rs1(127 downto 32) & imm & rs1(15 downto 0);
                    when "010" => rd <= rs1(127 downto 48) & imm & rs1(31 downto 0);
                    when "011" => rd <= rs1(127 downto 64) & imm & rs1(47 downto 0);
                    when "100" => rd <= rs1(127 downto 80) & imm & rs1(63 downto 0);
                    when "101" => rd <= rs1(127 downto 96) & imm & rs1(79 downto 0);
                    when "110" => rd <= rs1(127 downto 112) & imm & rs1(95 downto 0);
                    when "111" => rd <= imm & rs1(111 downto 0);
                    when others => rd <= (others => 'X');
                end case;

            -- Multiply-Add and Multiply-Subtract R4-Instruction Format
			
			------------------------------------------------------------------
            when "00001" => -- Signed Integer Multiply-Add Low with Saturation	
			------------------------------------------------------------------
				
				-- Multiply all corresponding low 16-bit values of 32-bit fields in rs2 and rs3
				product_1st_hw := SIGNED(rs2(15 downto 0)) * SIGNED(rs3(15 downto 0));
				product_2nd_hw := SIGNED(rs2(47 downto 32)) * SIGNED(rs3(47 downto 32));
				product_3rd_hw := SIGNED(rs2(79 downto 64)) * SIGNED(rs3(79 downto 64));
				product_4th_hw := SIGNED(rs2(111 downto 96)) * SIGNED(rs3(111 downto 96));
				
				-- Add corresponding 32-bit values with product_x_hw and rs1 (put into 33-bit value to handle clipping)
				sum_1st_w_33 := resize(SIGNED(rs1(31 downto 0)), 33) + resize(product_1st_hw, 33);	
				sum_2nd_w_33 := resize(SIGNED(rs1(63 downto 32)), 33) + resize(product_2nd_hw, 33);
				sum_3rd_w_33 := resize(SIGNED(rs1(95 downto 64)), 33) + resize(product_3rd_hw, 33);
				sum_4th_w_33 := resize(SIGNED(rs1(127 downto 96)), 33) + resize(product_4th_hw, 33);
				
				-- Determine clipping 
				-- First sum
				if (sum_1st_w_33 > resize(SIGNED_32_MAX, 33)) then
					sum_1st_w := SIGNED_32_MAX;
				elsif (sum_1st_w_33 < resize(SIGNED_32_MIN, 33)) then
					sum_1st_w := SIGNED_32_MIN;
				else
					sum_1st_w := sum_1st_w_33(31 downto 0);
				end if;	   
				
				-- Second sum
				if (sum_2nd_w_33 > resize(SIGNED_32_MAX, 33)) then
					sum_2nd_w := SIGNED_32_MAX;
				elsif (sum_2nd_w_33 < resize(SIGNED_32_MIN, 33)) then
					sum_2nd_w := SIGNED_32_MIN;
				else
					sum_2nd_w := sum_2nd_w_33(31 downto 0);
				end if;
				
				-- Third sum
				if (sum_3rd_w_33 > resize(SIGNED_32_MAX, 33)) then
					sum_3rd_w := SIGNED_32_MAX;
				elsif (sum_3rd_w_33 < resize(SIGNED_32_MIN, 33)) then
					sum_3rd_w := SIGNED_32_MIN;
				else
					sum_3rd_w := sum_3rd_w_33(31 downto 0);
				end if;
				
				-- Fourth sum
				if (sum_4th_w_33 > resize(SIGNED_32_MAX, 33)) then
					sum_4th_w := SIGNED_32_MAX;
				elsif (sum_4th_w_33 < resize(SIGNED_32_MIN, 33)) then
					sum_4th_w := SIGNED_32_MIN;
				else
					sum_4th_w := sum_4th_w_33(31 downto 0);
				end if;	   
				
				-- Write to rd
				rd(31 downto 0) <= STD_LOGIC_VECTOR(sum_1st_w);	
				rd(63 downto 32) <= STD_LOGIC_VECTOR(sum_2nd_w);
				rd(95 downto 64) <= STD_LOGIC_VECTOR(sum_3rd_w);
				rd(127 downto 96) <= STD_LOGIC_VECTOR(sum_4th_w);  
				
			-------------------------------------------------------------------
            when "00010" => -- Signed Integer Multiply-Add High with Saturation
			-------------------------------------------------------------------
			
				-- Multiply all corresponding high 16-bit values of 32-bit fields in rs2 and rs3
				product_1st_hw := SIGNED(rs2(31 downto 16)) * SIGNED(rs3(31 downto 16));
				product_2nd_hw := SIGNED(rs2(63 downto 48)) * SIGNED(rs3(63 downto 48));
				product_3rd_hw := SIGNED(rs2(95 downto 80)) * SIGNED(rs3(95 downto 80));
				product_4th_hw := SIGNED(rs2(127 downto 112)) * SIGNED(rs3(127 downto 112));
				
				-- Add corresponding 32-bit values with product_x_hw and rs1 (put into 33-bit value to handle clipping)
				sum_1st_w_33 := resize(SIGNED(rs1(31 downto 0)), 33) + resize(product_1st_hw, 33);	
				sum_2nd_w_33 := resize(SIGNED(rs1(63 downto 32)), 33) + resize(product_2nd_hw, 33);
				sum_3rd_w_33 := resize(SIGNED(rs1(95 downto 64)), 33) + resize(product_3rd_hw, 33);
				sum_4th_w_33 := resize(SIGNED(rs1(127 downto 96)), 33) + resize(product_4th_hw, 33);
				
				-- Determine clipping 
				-- First sum
				if (sum_1st_w_33 > resize(SIGNED_32_MAX, 33)) then
					sum_1st_w := SIGNED_32_MAX;
				elsif (sum_1st_w_33 < resize(SIGNED_32_MIN, 33)) then
					sum_1st_w := SIGNED_32_MIN;
				else
					sum_1st_w := sum_1st_w_33(31 downto 0);
				end if;	   
				
				-- Second sum
				if (sum_2nd_w_33 > resize(SIGNED_32_MAX, 33)) then
					sum_2nd_w := SIGNED_32_MAX;
				elsif (sum_2nd_w_33 < resize(SIGNED_32_MIN, 33)) then
					sum_2nd_w := SIGNED_32_MIN;
				else
					sum_2nd_w := sum_2nd_w_33(31 downto 0);
				end if;
				
				-- Third sum
				if (sum_3rd_w_33 > resize(SIGNED_32_MAX, 33)) then
					sum_3rd_w := SIGNED_32_MAX;
				elsif (sum_3rd_w_33 < resize(SIGNED_32_MIN, 33)) then
					sum_3rd_w := SIGNED_32_MIN;
				else
					sum_3rd_w := sum_3rd_w_33(31 downto 0);
				end if;
				
				-- Fourth sum
				if (sum_4th_w_33 > resize(SIGNED_32_MAX, 33)) then
					sum_4th_w := SIGNED_32_MAX;
				elsif (sum_4th_w_33 < resize(SIGNED_32_MIN, 33)) then
					sum_4th_w := SIGNED_32_MIN;
				else
					sum_4th_w := sum_4th_w_33(31 downto 0);
				end if;	   
				
				-- Write to rd
				rd(31 downto 0) <= STD_LOGIC_VECTOR(sum_1st_w);	
				rd(63 downto 32) <= STD_LOGIC_VECTOR(sum_2nd_w);
				rd(95 downto 64) <= STD_LOGIC_VECTOR(sum_3rd_w);
				rd(127 downto 96) <= STD_LOGIC_VECTOR(sum_4th_w);
				
			-----------------------------------------------------------------------
            when "00011" => -- Signed Integer Multiply-Subtract Low with Saturation
			-----------------------------------------------------------------------
			
				-- Multiply all corresponding high 16-bit values of 32-bit fields in rs2 and rs3
				product_1st_hw := SIGNED(rs2(15 downto 0)) * SIGNED(rs3(15 downto 0));
				product_2nd_hw := SIGNED(rs2(47 downto 32)) * SIGNED(rs3(47 downto 32));
				product_3rd_hw := SIGNED(rs2(79 downto 64)) * SIGNED(rs3(79 downto 64));
				product_4th_hw := SIGNED(rs2(111 downto 96)) * SIGNED(rs3(111 downto 96));
				
				-- Subtract corresponding 32-bit values of product_x_hw from rs1 (put into 33-bit value to handle clipping)
				diff_1st_w_33 := resize(SIGNED(rs1(31 downto 0)), 33) - resize(product_1st_hw, 33);	
				diff_2nd_w_33 := resize(SIGNED(rs1(63 downto 32)), 33) - resize(product_2nd_hw, 33);
				diff_3rd_w_33 := resize(SIGNED(rs1(95 downto 64)), 33) - resize(product_3rd_hw, 33);
				diff_4th_w_33 := resize(SIGNED(rs1(127 downto 96)), 33) - resize(product_4th_hw, 33);
				
				-- Determine clipping 
				-- First difference
				if (diff_1st_w_33 > resize(SIGNED_32_MAX, 33)) then
					diff_1st_w := SIGNED_32_MAX;
				elsif (diff_1st_w_33 < resize(SIGNED_32_MIN, 33)) then
					diff_1st_w := SIGNED_32_MIN;
				else
					diff_1st_w := diff_1st_w_33(31 downto 0);
				end if;	   
				
				-- Second difference
				if (diff_2nd_w_33 > resize(SIGNED_32_MAX, 33)) then
					diff_2nd_w := SIGNED_32_MAX;
				elsif (diff_2nd_w_33 < resize(SIGNED_32_MIN, 33)) then
					diff_2nd_w := SIGNED_32_MIN;
				else
					diff_2nd_w := diff_2nd_w_33(31 downto 0);
				end if;
				
				-- Third difference
				if (diff_3rd_w_33 > resize(SIGNED_32_MAX, 33)) then
					diff_3rd_w := SIGNED_32_MAX;
				elsif (diff_3rd_w_33 < resize(SIGNED_32_MIN, 33)) then
					diff_3rd_w := SIGNED_32_MIN;
				else
					diff_3rd_w := diff_3rd_w_33(31 downto 0);
				end if;
				
				-- Fourth difference
				if (diff_4th_w_33 > resize(SIGNED_32_MAX, 33)) then
					diff_4th_w := SIGNED_32_MAX;
				elsif (diff_4th_w_33 < resize(SIGNED_32_MIN, 33)) then
					diff_4th_w := SIGNED_32_MIN;
				else
					diff_4th_w := diff_4th_w_33(31 downto 0);
				end if;	  
				
				-- Write to rd
				rd(31 downto 0) <= STD_LOGIC_VECTOR(diff_1st_w);	
				rd(63 downto 32) <= STD_LOGIC_VECTOR(diff_2nd_w);
				rd(95 downto 64) <= STD_LOGIC_VECTOR(diff_3rd_w);
				rd(127 downto 96) <= STD_LOGIC_VECTOR(diff_4th_w);
				
			------------------------------------------------------------------------
            when "00100" => -- Signed Integer Multiply-Subtract High with Saturation
			------------------------------------------------------------------------
			
            	-- Multiply all corresponding high 16-bit values of 32-bit fields in rs2 and rs3
				product_1st_hw := SIGNED(rs2(31 downto 16)) * SIGNED(rs3(31 downto 16));
				product_2nd_hw := SIGNED(rs2(63 downto 48)) * SIGNED(rs3(63 downto 48));
				product_3rd_hw := SIGNED(rs2(95 downto 80)) * SIGNED(rs3(95 downto 80));
				product_4th_hw := SIGNED(rs2(127 downto 112)) * SIGNED(rs3(127 downto 112));
				
				-- Subtract corresponding 32-bit values of product_x_hw from rs1 (put into 33-bit value to handle clipping)
				diff_1st_w_33 := resize(SIGNED(rs1(31 downto 0)), 33) - resize(product_1st_hw, 33);	
				diff_2nd_w_33 := resize(SIGNED(rs1(63 downto 32)), 33) - resize(product_2nd_hw, 33);
				diff_3rd_w_33 := resize(SIGNED(rs1(95 downto 64)), 33) - resize(product_3rd_hw, 33);
				diff_4th_w_33 := resize(SIGNED(rs1(127 downto 96)), 33) - resize(product_4th_hw, 33);
				
				-- Determine clipping 
				-- First difference
				if (diff_1st_w_33 > resize(SIGNED_32_MAX, 33)) then
					diff_1st_w := SIGNED_32_MAX;
				elsif (diff_1st_w_33 < resize(SIGNED_32_MIN, 33)) then
					diff_1st_w := SIGNED_32_MIN;
				else
					diff_1st_w := diff_1st_w_33(31 downto 0);
				end if;	   
				
				-- Second difference
				if (diff_2nd_w_33 > resize(SIGNED_32_MAX, 33)) then
					diff_2nd_w := SIGNED_32_MAX;
				elsif (diff_2nd_w_33 < resize(SIGNED_32_MIN, 33)) then
					diff_2nd_w := SIGNED_32_MIN;
				else
					diff_2nd_w := diff_2nd_w_33(31 downto 0);
				end if;
				
				-- Third difference
				if (diff_3rd_w_33 > resize(SIGNED_32_MAX, 33)) then
					diff_3rd_w := SIGNED_32_MAX;
				elsif (diff_3rd_w_33 < resize(SIGNED_32_MIN, 33)) then
					diff_3rd_w := SIGNED_32_MIN;
				else
					diff_3rd_w := diff_3rd_w_33(31 downto 0);
				end if;
				
				-- Fourth difference
				if (diff_4th_w_33 > resize(SIGNED_32_MAX, 33)) then
					diff_4th_w := SIGNED_32_MAX;
				elsif (diff_4th_w_33 < resize(SIGNED_32_MIN, 33)) then
					diff_4th_w := SIGNED_32_MIN;
				else
					diff_4th_w := diff_4th_w_33(31 downto 0);
				end if;	  
				
				-- Write to rd
				rd(31 downto 0) <= STD_LOGIC_VECTOR(diff_1st_w);	
				rd(63 downto 32) <= STD_LOGIC_VECTOR(diff_2nd_w);
				rd(95 downto 64) <= STD_LOGIC_VECTOR(diff_3rd_w);
				rd(127 downto 96) <= STD_LOGIC_VECTOR(diff_4th_w);
				
			------------------------------------------------------------------------
            when "00101" =>  -- Signed Long Integer Multiply-Add Low with Saturation
			------------------------------------------------------------------------
			
                product_low  := SIGNED(rs2(31 downto 0)) * SIGNED(rs3(31 downto 0)); --computing and storing lower product(Lower 32 Bits)
                product_high := SIGNED(rs2(95 downto 64)) * SIGNED(rs3(95 downto 64)); --computing and storing the high product

                --performing addition with the two product values
                sum_low_65  := resize(SIGNED(rs1(63 downto 0)),65) + resize(product_low,65);  --performing signed extension by resizing to 65 bits to perform clipping
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
                rd(127 downto 64) <= STD_LOGIC_VECTOR(sum_high); --Assigning sum_high to top half of rd
                rd(63 downto 0)   <= STD_LOGIC_VECTOR(sum_low);  --Assigning sum_low to top bottom half of rd
			
			-------------------------------------------------------------------------
            when "00110" =>  -- Signed Long Integer Multiply-Add High with Saturation
			-------------------------------------------------------------------------
			
                product_low  := SIGNED(rs2(63 downto 32)) * SIGNED(rs3(63 downto 32)); --computing and storing lower product( Higher 32 Bits)
                product_high := SIGNED(rs2(127 downto 96)) * SIGNED(rs3(127 downto 96)); --computing and storing the high product

                --performing addition with the two product values
                sum_low_65  := resize(SIGNED(rs1(63 downto 0)),65) + resize(product_low,65);  --performing signed extension by resizing to 65 bits to perform clipping
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
                rd(127 downto 64) <= STD_LOGIC_VECTOR(sum_high); --Assigning sum_high to top half of rd
                rd(63 downto 0)   <= STD_LOGIC_VECTOR(sum_low);  --Assigning sum_low to top bottom half of rd
			
			-----------------------------------------------------------------------------
            when "00111" =>  -- Signed Long Integer Multiply-Subtract Low with Saturation
			-----------------------------------------------------------------------------
			
                product_low  := SIGNED(rs2(31 downto 0)) * SIGNED(rs3(31 downto 0)); --computing and storing lower product(Lower 32 Bits)
                product_high := SIGNED(rs2(95 downto 64)) * SIGNED(rs3(95 downto 64)); --computing and storing the high product

                --performing Subtraction with the two product values
                diff_low_65  := resize(SIGNED(rs1(63 downto 0)),65) - resize(product_low,65);  --performing signed extension by resizing to 65 bits to perform clipping
                diff_high_65 := resize(SIGNED(rs1(127 downto 64)),65) - resize(product_high,65);

                --checking diff_low and clipping
                if(diff_low_65 > resize(SIGNED_64_MAX,65)) then
                    --Overflow has occured
                    diff_low := SIGNED_64_MAX; --Clipping by setting sum to the maximum value
                elsif(diff_low_65 < resize(SIGNED_64_MIN,65)) then
                    --Underflow has occured
                    diff_low := SIGNED_64_MIN; --Clipping for underflow
                else
                    diff_low := resize(diff_low_65, 64); --No clipping is required, so sum is resized to 64 bits
                end if;
                
                --checking diff_high
                if(diff_high_65 > resize(SIGNED_64_MAX,65)) then
                    --Overflow has occured
                    diff_high := SIGNED_64_MAX; --Clipping for overflow
                elsif(diff_high_65 < resize(SIGNED_64_MIN,65)) then
                    --Underflow has occured
                    diff_high := SIGNED_64_MIN; --Clipping for underflow
                else
                    diff_high := resize(diff_high_65, 64); --No clipping is required, so sum is resized to 64 bits
                end if;

                --Transferring diff_high and diff_low into register rd
                rd(127 downto 64) <= STD_LOGIC_VECTOR(diff_high); --Assigning sum_high to top half of rd
                rd(63 downto 0)   <= STD_LOGIC_VECTOR(diff_low);  --Assigning sum_low to top bottom half of rd
			
			------------------------------------------------------------------------------
            when "01000" =>  -- Signed Long Integer Multiply-Subtract High with Saturation
			------------------------------------------------------------------------------
			
                product_low  := SIGNED(rs2(63 downto 32)) * SIGNED(rs3(63 downto 32)); --computing and storing lower product(Higher 32 Bits)
                product_high := SIGNED(rs2(127 downto 96)) * SIGNED(rs3(127 downto 96)); --computing and storing the high product

                --performing Subtraction with the two product values
                diff_low_65  := resize(SIGNED(rs1(63 downto 0)),65) - resize(product_low,65);  --performing signed extension by resizing to 65 bits to perform clipping
                diff_high_65 := resize(SIGNED(rs1(127 downto 64)),65) - resize(product_high,65);

                --checking diff_low and clipping
                if(diff_low_65 > resize(SIGNED_64_MAX,65)) then
                    --Overflow has occured
                    diff_low := SIGNED_64_MAX; --Clipping by setting sum to the maximum value
                elsif(diff_low_65 < resize(SIGNED_64_MIN,65)) then
                    --Underflow has occured
                    diff_low := SIGNED_64_MIN; --Clipping for underflow
                else
                    diff_low := resize(diff_low_65, 64); --No clipping is required, so sum is resized to 64 bits
                end if;
                
                --checking diff_high
                if(diff_high_65 > resize(SIGNED_64_MAX,65)) then
                    --Overflow has occured
                    diff_high := SIGNED_64_MAX; --Clipping for overflow
                elsif(diff_high_65 < resize(SIGNED_64_MIN,65)) then
                    --Underflow has occured
                    diff_high := SIGNED_64_MIN; --Clipping for underflow
                else
                    diff_high := resize(diff_high_65, 64); --No clipping is required, so sum is resized to 64 bits
                end if;

                --Transferring diff_high and diff_low into register rd
                rd(127 downto 64) <= STD_LOGIC_VECTOR(diff_high); --Assigning sum_high to top half of rd
                rd(63 downto 0)   <= STD_LOGIC_VECTOR(diff_low);  --Assigning sum_low to top bottom half of rd
				
			------------------------	
            -- R3-Instruction Format 
			------------------------
			
			-----------------------
            when "01001" =>  -- NOP
			-----------------------
			
				rd <= rd;	-- Do nothing basically
			
			-------------------------
            when "01010" =>  -- SHRHI
			-------------------------
			
				-- rs1 is the target register, rs2 4 LSBs are shift amount
				
				-- Using shift_right() from numeric.std, takes a unsigned array to shift and an integer for shift amount
				-- Using to_integer() from numeric.std to convert last 4 bits to an integer for use in shift_right() 
				-- Converting target half-words of rs1 to type UNSIGNED to indicate to shift_right() to zero-fill instead of sign extend
				-- Finally, convert back to type STD_LOGIC_VECTOR to write to rd
				rd(15 downto 0) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(15 downto 0)), to_integer(SIGNED(rs2(3 downto 0))))); 
				rd(31 downto 16) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(31 downto 16)), to_integer(SIGNED(rs2(3 downto 0)))));
				rd(47 downto 32) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(47 downto 32)), to_integer(SIGNED(rs2(3 downto 0)))));
				rd(63 downto 48) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(63 downto 48)), to_integer(SIGNED(rs2(3 downto 0))))); 
				
				rd(79 downto 64) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(79 downto 64)), to_integer(SIGNED(rs2(3 downto 0)))));
				rd(95 downto 80) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(95 downto 80)), to_integer(SIGNED(rs2(3 downto 0)))));
				rd(111 downto 96) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(111 downto 96)), to_integer(SIGNED(rs2(3 downto 0)))));
				rd(127 downto 112) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(127 downto 112)), to_integer(SIGNED(rs2(3 downto 0)))));
			
			----------------------
            when "01011" =>  -- AU
			----------------------
			
				-- Converting values from type STD_LOGIC_VECTOR to SIGNED
				-- Adding them
				-- Converting result back to type STD_LOGIC_VECTOR
				-- Write value to rd, regardless of overflow/underflow
				rd(31 downto 0) <= STD_LOGIC_VECTOR(SIGNED(rs1(31 downto 0)) + SIGNED(rs2(31 downto 0)));	  
				rd(63 downto 32) <= STD_LOGIC_VECTOR(SIGNED(rs1(63 downto 32)) + SIGNED(rs2(63 downto 32)));
				rd(95 downto 64) <= STD_LOGIC_VECTOR(SIGNED(rs1(95 downto 64)) + SIGNED(rs2(95 downto 64)));
				rd(127 downto 96) <= STD_LOGIC_VECTOR(SIGNED(rs1(127 downto 96)) + SIGNED(rs2(127 downto 96)));
			
			-------------------------
            when "01100" =>  -- CNT1H
			-------------------------
			
				-- Using variable count	
				
				-- Outer loop for all 8 half-word segments in rs1
				for i in 0 to 7	loop  
					
					count := 0;	-- Reset counter at start of every loop
						
					-- Inner loop for each half-word
					for j in (15 + (16 * i)) downto (0 + (16 * i)) loop  
						
						-- Increment counter for every '1'
						if rs1(j) = '1' then
							count := count + 1;	
							
						end if;	
					end loop;
					
					-- Convert count to 16-bit unsigned value and then to type STD_LOGIC_VECTOR
					-- Write to corresponding rd half-word
					rd((15 + (16 * i)) downto (0 + (16 * i))) <= STD_LOGIC_VECTOR(to_unsigned(count, 16));
					
				end loop;
			
			-----------------------
            when "01101" =>  -- AHS
			-----------------------
			
				for i in 0 to 7 loop
					
					sum_17 := resize(SIGNED(rs1((15 + (16 * i)) downto (0 + (16 * i)))), 17) 
							+ resize(SIGNED(rs2((15 + (16 * i)) downto (0 + (16 * i)))), 17);  
					
					-- Determine clipping
					if (sum_17 > resize(SIGNED_16_MAX, 17)) then	   
						
						rd((15 + (16 * i)) downto (0 + (16 * i))) <= STD_LOGIC_VECTOR(SIGNED_16_MAX);
						
					elsif (sum_17 < resize(SIGNED_16_MIN, 17)) then	  
						
						rd((15 + (16 * i)) downto (0 + (16 * i))) <= STD_LOGIC_VECTOR(SIGNED_16_MIN);	
						
					else												
						
						rd((15 + (16 * i)) downto (0 + (16 * i))) <= STD_LOGIC_VECTOR(sum_17(15 downto 0));
						
					end if;		
				end loop;
			
			----------------------
            when "01110" =>  -- OR
			----------------------
			
		  		rd <= rs1 OR rs2;
			
			-----------------------
            when "01111" =>  -- BCW
			-----------------------
			
			
			
			-------------------------
            when "10000" =>  -- MAXWS
			-------------------------
			
			--Working on Slice 4
				if(SIGNED(rs1(127 downto 96)) > SIGNED(rs2(127 downto 96)))then
					rd(127 downto 96) <= rs1(127 downto 96); --Copying greater 32 bits into slice 4 of rd
				else
					rd(127 downto 96) <= rs2(127 downto 96); --Copying rs2 slice because it is bigger
				end if;  
				
				--Working on Slice 3	
				if(SIGNED(rs1(95 downto 64)) > SIGNED(rs2(95 downto 64)))then
					rd(95 downto 64) <= rs1(95 downto 64); --Copying greater 32 bits into slice 3 of rd
				else
					rd(95 downto 64) <= rs2(95 downto 64); 
				end if; 
				
				--Working on Slice 2	
				if(SIGNED(rs1(63 downto 32)) > SIGNED(rs2(63 downto 32)))then
					rd(63 downto 32) <= rs1(63 downto 32); --Copying greater 32 bits into slice 2 of rd
				else
					rd(63 downto 32) <= rs2(63 downto 32); 
				end if; --Operation done for slice 2
				
				--Working on Slice 1
				if(SIGNED(rs1(31 downto 0)) > SIGNED(rs2(31 downto 0)))then
					rd(31 downto 0) <= rs1(31 downto 0); --Copying greater 32 bits into slice 1 of rd
				else
					rd(31 downto 0) <= rs2(31 downto 0); 
				end if; 
			
			-------------------------
            when "10001" =>  -- MINWS
			-------------------------
			
				--Working on Slice 4
				if(SIGNED(rs1(127 downto 96)) < SIGNED(rs2(127 downto 96)))then
					rd(127 downto 96) <= rs1(127 downto 96); --Copying smaller 32 bits into slice 4 of rd
				else
					rd(127 downto 96) <= rs2(127 downto 96); --Copying rs2 slice because it is smaller
				end if;  
				
				--Working on Slice 3	
				if(SIGNED(rs1(95 downto 64)) < SIGNED(rs2(95 downto 64)))then
					rd(95 downto 64) <= rs1(95 downto 64); --Copying smaller 32 bits into slice 3 of rd
				else
					rd(95 downto 64) <= rs2(95 downto 64); 
				end if; 
				
				--Working on Slice 2	
				if(SIGNED(rs1(63 downto 32)) < SIGNED(rs2(63 downto 32)))then
					rd(63 downto 32) <= rs1(63 downto 32); --Copying smaller 32 bits into slice 2 of rd
				else
					rd(63 downto 32) <= rs2(63 downto 32); 
				end if; --Operation done for slice 2
				
				--Working on Slice 1
				if(SIGNED(rs1(31 downto 0)) < SIGNED(rs2(31 downto 0)))then
					rd(31 downto 0) <= rs1(31 downto 0); --Copying smaller 32 bits into slice 1 of rd
				else
					rd(31 downto 0) <= rs2(31 downto 0); 
				end if; 
			
			------------------------
            when "10010" =>  -- MLHU
			------------------------
				--Starting With most significant low 16 bits -> Slice 4
			    product := UNSIGNED(rs1(111 downto 96)) * UNSIGNED(rs2(111 downto 96)); --Storing the product into the variable	
				rd(127 downto 96) <= STD_LOGIC_VECTOR(product); --copying the 32 bit product to slice 4 of rd
				
				--Next 16 bits -> Slice 3  
				product := UNSIGNED(rs1(79 downto 64)) * UNSIGNED(rs2(79 downto 64));
				rd(95 downto 64) <= STD_LOGIC_VECTOR(product);	 --Copying product to slice 3 of rd
				
				--Next 16 bits -> Slice 2
				product := UNSIGNED(rs1(47 downto 32)) * UNSIGNED(rs2(47 downto 32));
				rd(63 downto 32) <= STD_LOGIC_VECTOR(product);	 --Copying product to slice 2 of rd
				
				--Next 16 bits -> Slice 1
				product := UNSIGNED(rs1(15 downto 0)) * UNSIGNED(rs2(15 downto 0));
				rd(31 downto 0) <= STD_LOGIC_VECTOR(product);	 --Copying product to slice 1 of rd
			
			-------------------------
            when "10011" =>  -- MLHCU
			-------------------------
			
				five_const := UNSIGNED(rs2(4 downto 0)); --Extracting the 5 LSBs from rs2
			
				--Starting With most significant low 16 bits -> Slice 4
			    product := resize(UNSIGNED(rs1(111 downto 96)) * five_const,32); --Performing multiplication and resizing to 32 bits
				rd(127 downto 96) <= STD_LOGIC_VECTOR(product); --copying the 32 bit product to slice 4 of rd
				
				--Next 16 bits -> Slice 3  
				product := resize(UNSIGNED(rs1(79 downto 64)) * five_const,32);
				rd(95 downto 64) <= STD_LOGIC_VECTOR(product);	 --Copying product to slice 3 of rd
				
				--Next 16 bits -> Slice 2
				product := resize(UNSIGNED(rs1(47 downto 32)) * five_const,32);
				rd(63 downto 32) <= STD_LOGIC_VECTOR(product);	 --Copying product to slice 2 of rd
				
				--Next 16 bits -> Slice 1
				product := resize(UNSIGNED(rs1(15 downto 0)) * five_const,32);	
				rd(31 downto 0) <= STD_LOGIC_VECTOR(product);
			-----------------------
            when "10100" =>  -- AND	
			-----------------------
			
				rd <= rs1 AND rs2; --BITWISE AND
			
			------------------------
            when "10101" =>  -- CLZW
			------------------------ 
			
				--Starting with top word: word 4
				count := 0; --resetting counter before next iteration
				word := UNSIGNED(rs1(127 downto 96)); --Extracting word from rs1
				if(word = to_UNSIGNED(0,32)) then
					rd(127 downto 96) <= STD_LOGIC_VECTOR(to_UNSIGNED(32,32)); --Converting 32 from int to binary with a width of 32 and trasnferring to rd
				else
					for i in 31 downto 0 loop
						if(word(i) = '1') then
							exit;
						else
							count := count + 1;	  --Incrementing count
						end if;
					end loop;
					rd(127 downto 96) <= STD_LOGIC_VECTOR(to_UNSIGNED(count,32)); --converting count to 32 bit value and storing into slice 4 of rd
				end if;
				
				--Operating word 3
				count := 0; --resetting counter before next iteration
				word := UNSIGNED(rs1(95 downto 64)); --Extracting word from rs1
				if(word = to_UNSIGNED(0,32)) then
					rd(95 downto 64) <= STD_LOGIC_VECTOR(to_UNSIGNED(32,32)); 
				else
					for i in 31 downto 0 loop
						if(word(i) = '1') then
							exit;
						else
							count := count + 1;	  --Incrementing count
						end if;
					end loop;
					rd(95 downto 64) <= STD_LOGIC_VECTOR(to_UNSIGNED(count,32)); --Storing into slice 3 of rd
				end if;
				
				--Operating word 2
				count := 0; --resetting counter before next iteration
				word := UNSIGNED(rs1(63 downto 32)); --Extracting word from rs1
				if(word = to_UNSIGNED(0,32)) then
					rd(63 downto 32) <= STD_LOGIC_VECTOR(to_UNSIGNED(32,32)); 
				else
					for i in 31 downto 0 loop
						if(word(i) = '1') then
							exit;
						else
							count := count + 1;	 --Incrementing count
						end if;
					end loop;
					rd(63 downto 32) <= STD_LOGIC_VECTOR(to_UNSIGNED(count,32)); --Storing into slice 2 of rd
				end if;	
				
				--Operating word 1
				count := 0; --resetting counter before next iteration
				word := UNSIGNED(rs1(31 downto 0)); --Extracting word from rs1
				if(word = to_UNSIGNED(0,32)) then
					rd(31 downto 0) <= STD_LOGIC_VECTOR(to_UNSIGNED(32,32)); 
				else
					for i in 31 downto 0 loop
						if(word(i) = '1') then
							exit;
						else
							count := count + 1;	 --Incrementing count
						end if;
					end loop;
					rd(31 downto 0) <= STD_LOGIC_VECTOR(to_UNSIGNED(count,32)); --Storing into slice 1 of rd
				end if;
				
			------------------------
            when "10110" =>  -- ROTW
			------------------------
			
				 --Operating Slice 4
				 rd(127 downto 96) <=  STD_LOGIC_VECTOR(rotate_right(UNSIGNED(rs1(127 downto 96)), to_integer(UNSIGNED(rs2(100 downto 96))))); --rotating slice 4 of rs1 by 5 LSBs from rs2 word and storing into slice 4 of rd.
				 
				 --Operating Slice 3
				 rd(95 downto 64) <=  STD_LOGIC_VECTOR(rotate_right(UNSIGNED(rs1(95 downto 64)), to_integer(UNSIGNED(rs2(68 downto 64))))); --rotating slice 3 of rs1 and storing into slice 3 of rd	
				 
				 --Operating Slice 2
				 rd(63 downto 32) <=  STD_LOGIC_VECTOR(rotate_right(UNSIGNED(rs1(63 downto 32)), to_integer(UNSIGNED(rs2(36 downto 32))))); --rotating slice 2 of rs1 and storing into slice 2 of rd
				 
				 --Operating Slice 1
				 rd(31 downto 0) <=  STD_LOGIC_VECTOR(rotate_right(UNSIGNED(rs1(31 downto 0)), to_integer(UNSIGNED(rs2(4 downto 0))))); --rotating slice 1 of rs1 and storing into slice 1 of rd
				 
			------------------------
            when "10111" =>  -- SFWU
			------------------------
			
				  --Operating Slice 4
				 rd(127 downto 96) <=  STD_LOGIC_VECTOR(UNSIGNED(rs2(127 downto 96)) - UNSIGNED(rs1(127 downto 96)));  --subtracting slice 4 of rs2 by rs1 and storing into slice 4 of rd
				 
				 --Operating Slice 3
				 rd(95 downto 64) <=  STD_LOGIC_VECTOR(UNSIGNED(rs2(95 downto 64)) - UNSIGNED(rs1(95 downto 64)));	  --subtracting slice 3 of rs2 by rs1 and storing into slice 3 of rd
				 
				 --Operating Slice 2
				 rd(63 downto 32) <=  STD_LOGIC_VECTOR(UNSIGNED(rs2(63 downto 32)) - UNSIGNED(rs1(63 downto 32)));	  --subtracting slice 2 of rs2 by rs1 and storing into slice 2 of rd
				 
				 --Operating Slice 1
				 rd(31 downto 0) <=  STD_LOGIC_VECTOR(UNSIGNED(rs2(31 downto 0)) - UNSIGNED(rs1(31 downto 0)));		  --subtracting slice 1 of rs2 by rs1 and storing into slice 1 of rd
			
			
			------------------------
            when "11000" =>  -- SFHS
			------------------------
			
				for i in 0 to 7 loop   --For loop to perform 8 halfword substractions
					
					diff_17 := resize(SIGNED(rs2(15+(16 * i) downto (16 * i))), 17) - resize(SIGNED(rs1(15+(16 * i) downto (16 * i))), 17);	--performing halfword subtraction with rs2 and rs1
				
					--Saturation Logic
					if(diff_17 > resize(SIGNED_16_MAX, 17)) then
						
						rd(15+(16 * i) downto (16 * i)) <= STD_LOGIC_VECTOR(SIGNED_16_MAX); --Overflow detected: Clip to greatest 16 bit signed value
						
					elsif(diff_17 < resize(SIGNED_16_MIN, 17)) then
						
						rd(15+(16 * i) downto (16 * i)) <= STD_LOGIC_VECTOR(SIGNED_16_MIN); --Underflow detected: Clip to smallest 16 bit signed value
						
					else
						
						rd(15+(16 * i) downto (16 * i)) <=  STD_LOGIC_VECTOR(resize(diff_17, 16)); --No Clipping Required: Perform signed subtraction
						
					end if;	 
				end loop;
				
            --------------------------------------------------
            when others => rd <= (others => 'X');	-- Invalid
			--------------------------------------------------
			
        end case;
    end process;
end behavioral;
