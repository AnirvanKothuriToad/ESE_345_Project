-------------------------------------------------------------------------------
-- Title       : CPU (FINAL DEBUGGED STRUCTURAL CODE)
-- Design      : CPU_Multimedia
-- Description : Complete Model with InstructionMemory Fixes and Pipeline Wiring
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

package CPU_Defs is
    type REG_FILE_ARRAY_TYPE is array (0 to 31) of std_logic_vector(127 downto 0);
end package CPU_Defs;

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;
use work.CPU_Defs.all;

-------------------------------
-- PC Register
-------------------------------
entity PC is
    port(   
        reset : in STD_LOGIC;                               
        clk : in STD_LOGIC;                                 
        data_out : out STD_LOGIC_VECTOR(5 downto 0)         
    );
end PC;

architecture behavioral of PC is  
begin
    process (reset, clk) is 
    begin
        if (reset = '1') then   
            data_out <= (others => '0');
        elsif rising_edge(clk) then     
            data_out <= STD_LOGIC_VECTOR(UNSIGNED(data_out) + 1);   
        end if; 
    end process;
end behavioral;

----------------------------------------------------------------------
-- INSTRUCTION BUFFER (With Robust Initialization)
----------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity InstrBuffer is
    port(   
        reset : in STD_LOGIC;                           
        clk : in STD_LOGIC;                             
        write_enable : in STD_LOGIC;                    
        PC_in  : in STD_LOGIC_VECTOR(5 downto 0);           
        data_in : in STD_LOGIC_VECTOR(24 downto 0);         
        data_out : out STD_LOGIC_VECTOR(24 downto 0)        
    );
end InstrBuffer;

architecture behavioral of InstrBuffer is  
    type MEM_TYPE is array(0 to 63) of STD_LOGIC_VECTOR(24 downto 0); 
    
    -- FUNCTION: Force-Initialize Memory to 0 (Guaranteed way to fix 'U's)
    impure function InitMem return MEM_TYPE is
        variable temp_mem : MEM_TYPE;
    begin
        for i in 0 to 63 loop
            temp_mem(i) := (others => '0');
        end loop;
        return temp_mem;
    end function;

    signal MEM_ARRAY : MEM_TYPE := InitMem; 
begin
    -- 1. SAFE ASYNCHRONOUS READ
    process(PC_in, MEM_ARRAY)
    begin
        if (is_x(PC_in)) then
            data_out <= (others => '0'); 
        else
            data_out <= MEM_ARRAY(TO_INTEGER(UNSIGNED(PC_in)));
        end if;
    end process;

    -- 2. SYNCHRONOUS WRITE 
    process (clk) is 
    begin
        if rising_edge(clk) then  
            if (write_enable = '1') then 
                -- We use PC_in for the write address logic
                MEM_ARRAY(TO_INTEGER(UNSIGNED(PC_in))) <= data_in;
            end if;
        end if; 
    end process;
end behavioral;

--------------------------------
-- Structural Unit for Stage 1 (Fetch)
--------------------------------
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity stage_1 is
    port(
        clk       : in  std_logic;
        reset     : in  std_logic;
        load_en   : in  std_logic; 
        load_addr : in  std_logic_vector(5 downto 0);
        load_data : in  std_logic_vector(24 downto 0);
        instr_out : out std_logic_vector(24 downto 0);
        pc_out    : out std_logic_vector(5 downto 0)
    );
end stage_1;

architecture structural of stage_1 is
    signal current_pc : std_logic_vector(5 downto 0); 
    signal buffer_addr_in : std_logic_vector(5 downto 0); 
    
    -- ADDED: Temporary signal to resolve memory output stably
    signal s1_instr_data_read : STD_LOGIC_VECTOR(24 downto 0);
begin
    pc_out <= current_pc; 
    buffer_addr_in <= load_addr when load_en = '1' else current_pc; 
    
    u0: entity PC
        port map(reset => reset, clk => clk, data_out => current_pc);
    
    -- FIXED BINDING: Use work.InstrBuffer and map to internal signal
    u1: entity work.InstrBuffer 
        port map(
            reset => reset,
            clk => clk,
            write_enable => load_en,
            PC_in => buffer_addr_in,
            data_in => load_data,
            data_out => s1_instr_data_read -- Map to internal signal
        );
    
    -- STRUCTURAL FIX: Assign the internal signal to the external port
    instr_out <= s1_instr_data_read;

end structural;

------------------------------------
-- IF/ID Pipeline Register
------------------------------------
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity IFID is
    port(   
        reset : in STD_LOGIC;                               
        clk : in STD_LOGIC;                                 
        data_in : in STD_LOGIC_VECTOR(24 downto 0);     
        data_out : out STD_LOGIC_VECTOR(24 downto 0)                                                        
    );
end IFID;

architecture behavioral of IFID is  
begin
    process (reset, clk) is 
    begin
        if (reset = '1') then   
            data_out <= (others => '0');
        elsif rising_edge(clk) then     
            data_out <= data_in;
        end if; 
    end process;
end behavioral;

------------------------------------
-- Control Unit
------------------------------------
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity control is
    port(   
        instr : in STD_LOGIC_VECTOR(24 downto 0);   
        write_enable : out STD_LOGIC;               
        ALU_op : out STD_LOGIC_VECTOR(4 downto 0);  
        ALU_source : out STD_LOGIC;                 
        is_load : out STD_LOGIC                     
    );
end control;

architecture behavioral of control is  
begin
    process(instr) is   
    begin       
        if instr(24) = '0' then -- Load Immediate
            ALU_op <= (others => '0'); 
            write_enable <= '1';    
            is_load <= '1';         
            ALU_source <= '0';
        elsif instr(23) = '0' then  -- R4 Instruction
            write_enable <= '1';    
            is_load <= '0';         
            ALU_source <= '0';      
            case instr(22 downto 20) is
                when "000" => ALU_op <= "00001";
                when "001" => ALU_op <= "00010";
                when "010" => ALU_op <= "00011"; 
                when "011" => ALU_op <= "00100"; 
                when "100" => ALU_op <= "00101";
                when "101" => ALU_op <= "00110"; 
                when "110" => ALU_op <= "00111"; 
                when "111" => ALU_op <= "01000";
                when others => ALU_op <= "XXXXX";
            end case;
        else    -- R3 Instruction
            write_enable <= '1';    
            is_load <= '0';         
            ALU_source <= '0';      
            case instr(18 downto 15) is 
                when "0000" => ALU_op <= "01001"; write_enable <= '0'; -- NOP
                when "0001" => ALU_op <= "01010"; ALU_source <= '1'; -- SHRHI
                when "0010" => ALU_op <= "01011"; -- AU
                when "0011" => ALU_op <= "01100"; -- CNT1H
                when "0100" => ALU_op <= "01101"; -- AHS
                when "0101" => ALU_op <= "01110"; -- OR
                when "0110" => ALU_op <= "01111"; -- BCW
                when "0111" => ALU_op <= "10000"; -- MAXWS
                when "1000" => ALU_op <= "10001"; -- MINWS
                when "1001" => ALU_op <= "10010"; -- MLHU
                when "1010" => ALU_op <= "10011"; ALU_source <= '1'; -- MLHCU
                when "1011" => ALU_op <= "10100"; -- AND
                when "1100" => ALU_op <= "10101"; -- CLZW
                when "1101" => ALU_op <= "10110"; -- ROTW
                when "1110" => ALU_op <= "10111"; -- SFWU
                when "1111" => ALU_op <= "11000"; -- SFHS
                when others => ALU_op <= "XXXXX";
            end case;       
        end if;
    end process;
end behavioral;

------------------------------------
-- Register File
------------------------------------ 
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;
use work.CPU_Defs.all;

entity RegFile is
    port(   
        reset : in STD_LOGIC;                           
        clk : in STD_LOGIC;                             
        write_enable : in STD_LOGIC;                    
        address_out_A : in STD_LOGIC_VECTOR(4 downto 0);   
        address_out_B : in STD_LOGIC_VECTOR(4 downto 0);   
        address_out_C : in STD_LOGIC_VECTOR(4 downto 0);   
        data_out_A : out STD_LOGIC_VECTOR(127 downto 0);   
        data_out_B : out STD_LOGIC_VECTOR(127 downto 0);   
        data_out_C : out STD_LOGIC_VECTOR(127 downto 0);   
        address_in : in STD_LOGIC_VECTOR(4 downto 0);      
        data_in : in STD_LOGIC_VECTOR(127 downto 0);
        reg_file_full : out REG_FILE_ARRAY_TYPE
    );
end RegFile;

architecture behavioral of RegFile is  
    signal REG_FILE : REG_FILE_ARRAY_TYPE := (others => (others => '0')); 
begin
    reg_file_full <= REG_FILE;
    process (reset, clk) is 
    begin
        if (reset = '1') then   
            REG_FILE <= (others => (others => '0'));
            data_out_A <= (others => '0');
            data_out_B <= (others => '0');
            data_out_C <= (others => '0'); 
        elsif rising_edge(clk) then     
            data_out_A <= REG_FILE(TO_INTEGER(UNSIGNED(address_out_A)));
            data_out_B <= REG_FILE(TO_INTEGER(UNSIGNED(address_out_B)));
            data_out_C <= REG_FILE(TO_INTEGER(UNSIGNED(address_out_C))); 
            if (write_enable = '1') then 
                REG_FILE(TO_INTEGER(UNSIGNED(address_in))) <= data_in;
                if (address_in = address_out_A) then data_out_A <= data_in; end if;
                if (address_in = address_out_B) then data_out_B <= data_in; end if;                                                 
                if (address_in = address_out_C) then data_out_C <= data_in; end if;
            end if;
        end if;             
    end process;
end behavioral; 

--------------------------------
-- Stage 2 (Decode)
--------------------------------
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;
use work.CPU_Defs.all;

entity stage_2 is 
    port(
        clk: in std_logic;
        reset: in std_logic;
        instr_in : in std_logic_vector(24 downto 0);
        wb_reg_write: in std_logic;
        wb_dest_addr: in std_logic_vector(4 downto 0);
        wb_write_data: in std_logic_vector(127 downto 0);
        
        ctrl_write_en : out std_logic;
        ctrl_alu_op   : out std_logic_vector(4 downto 0);
        ctrl_alu_src  : out std_logic;
        ctrl_is_load  : out std_logic;
        rs1_data      : out std_logic_vector(127 downto 0);
        rs2_data      : out std_logic_vector(127 downto 0);
        rs3_data      : out std_logic_vector(127 downto 0);
        rs1_addr_out  : out std_logic_vector(4 downto 0);
        rs2_addr_out  : out std_logic_vector(4 downto 0);
        rs3_addr_out  : out std_logic_vector(4 downto 0);
        rd_addr_out   : out std_logic_vector(4 downto 0);
        imm_out       : out std_logic_vector(15 downto 0);
        ld_idx_out    : out std_logic_vector(2 downto 0);
        reg_file_out  : out REG_FILE_ARRAY_TYPE
    );
end stage_2;

architecture structural of stage_2 is
    signal addr_a : std_logic_vector(4 downto 0);  
    signal addr_b : std_logic_vector(4 downto 0);  
    signal addr_c : std_logic_vector(4 downto 0);  
    signal sig_is_load : std_logic;  
begin
    u0: entity control
        port map(
            instr => instr_in,
            write_enable => ctrl_write_en,
            ALU_op => ctrl_alu_op,
            ALU_source => ctrl_alu_src,
            is_load => sig_is_load
        );
    ctrl_is_load <= sig_is_load; 
    addr_a <= instr_in(9 downto 5);
    addr_c <= instr_in(19 downto 15);
    addr_b <= instr_in(4 downto 0) when sig_is_load = '1' else instr_in(14 downto 10);
        
    u1: entity work.RegFile
        port map(
            clk => clk, reset => reset, write_enable => wb_reg_write,
            address_in => wb_dest_addr, data_in => wb_write_data,
            address_out_A => addr_a, address_out_B => addr_b, address_out_C => addr_c,
            data_out_A => rs1_data, data_out_B => rs2_data, data_out_C => rs3_data, 
            reg_file_full => reg_file_out
        ); 
    rs1_addr_out <= addr_a;
    rs2_addr_out <= addr_b;
    rs3_addr_out <= addr_c;
    rd_addr_out  <= instr_in(4 downto 0); 
    imm_out      <= instr_in(20 downto 5);
    ld_idx_out   <= instr_in(23 downto 21);
end structural; 

------------------------------------
-- ID/EX Pipeline Register
------------------------------------
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity IDEX is
    port(   
        reset : in STD_LOGIC;                               
        clk : in STD_LOGIC;                                 
        write_enable_in : in STD_LOGIC;                     
        write_enable_out : out STD_LOGIC;                   
        ALU_op_in : in STD_LOGIC_VECTOR(4 downto 0);        
        ALU_op_out : out STD_LOGIC_VECTOR(4 downto 0);      
        ALU_source_in : in STD_LOGIC;                       
        ALU_source_out : out STD_LOGIC;                     
        is_load_in : in STD_LOGIC;                          
        is_load_out : out STD_LOGIC;                        
        rs1_in : in STD_LOGIC_VECTOR(4 downto 0);           
        rs1_out : out STD_LOGIC_VECTOR(4 downto 0);         
        rs2_in : in STD_LOGIC_VECTOR(4 downto 0);           
        rs2_out : out STD_LOGIC_VECTOR(4 downto 0);         
        rs3_in : in STD_LOGIC_VECTOR(4 downto 0);           
        rs3_out : out STD_LOGIC_VECTOR(4 downto 0);         
        rs1_d_in : in STD_LOGIC_VECTOR(127 downto 0);       
        rs1_d_out : out STD_LOGIC_VECTOR(127 downto 0);     
        rs2_d_in : in STD_LOGIC_VECTOR(127 downto 0);       
        rs2_d_out : out STD_LOGIC_VECTOR(127 downto 0);     
        rs3_d_in : in STD_LOGIC_VECTOR(127 downto 0);       
        rs3_d_out : out STD_LOGIC_VECTOR(127 downto 0);     
        rd_in : in STD_LOGIC_VECTOR(4 downto 0);            
        rd_out : out STD_LOGIC_VECTOR(4 downto 0);          
        imm_in : in STD_LOGIC_VECTOR(15 downto 0);          
        imm_out : out STD_LOGIC_VECTOR(15 downto 0);        
        ind_in : in STD_LOGIC_VECTOR(2 downto 0);           
        ind_out : out STD_LOGIC_VECTOR(2 downto 0)          
    );
end IDEX;

architecture behavioral of IDEX is  
begin
    process (reset, clk) is 
    begin
        if (reset = '1') then   
            write_enable_out <= '0';    
            ALU_op_out <= (others => '0'); 
            ALU_source_out <= '0'; 
            is_load_out <= '0'; 
            rs1_out <= (others => '0'); rs2_out <= (others => '0'); rs3_out <= (others => '0');
            rs1_d_out <= (others => '0'); rs2_d_out <= (others => '0'); rs3_d_out <= (others => '0'); 
            rd_out <= (others => '0');
            imm_out <= (others => '0'); ind_out <= (others => '0');
        elsif rising_edge(clk) then     
            write_enable_out <= write_enable_in;
            ALU_op_out <= ALU_op_in;
            ALU_source_out <= ALU_source_in;
            is_load_out <= is_load_in;
            rs1_out <= rs1_in; rs2_out <= rs2_in; rs3_out <= rs3_in;        
            rs1_d_out <= rs1_d_in; rs2_d_out <= rs2_d_in; rs3_d_out <= rs3_d_in; 
            rd_out <= rd_in;
            imm_out <= imm_in; ind_out <= ind_in;
        end if; 
    end process;
end behavioral;

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
use work.all;

entity ALU is
    port(
        instr : in STD_LOGIC_VECTOR(4 downto 0);
        rs3   : in STD_LOGIC_VECTOR(127 downto 0);
        rs2   : in STD_LOGIC_VECTOR(127 downto 0);
        rs1   : in STD_LOGIC_VECTOR(127 downto 0);

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

    process(instr, rs3, rs2, rs1) is 
	
	--Variables for Load immediate
	  variable imm:  STD_LOGIC_VECTOR(15 downto 0); --Represents the immediate value
	  variable ld_in: UNSIGNED(2 downto 0);	 --Index value 
	
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
		rd <= (others => '0'); --clearing rd to prevent XXX
        case instr is  
			----------------------------------
            when "00000" =>  -- Load Immediate
			----------------------------------	
				imm := rs1(15 downto 0); --Extracting 16 LSBs from RS1 to obtain the immediate value
				ld_in := UNSIGNED(rs1(18 downto 16)); --Using Bits 18, 17, 16 for the index value
				
				-- Assuming rd will be passed as input rs2
                case STD_LOGIC_VECTOR(ld_in) is
                    when "000" => rd <= rs2(127 downto 16) & imm;
                    when "001" => rd <= rs2(127 downto 32) & imm & rs2(15 downto 0);
                    when "010" => rd <= rs2(127 downto 48) & imm & rs2(31 downto 0);
                    when "011" => rd <= rs2(127 downto 64) & imm & rs2(47 downto 0);
                    when "100" => rd <= rs2(127 downto 80) & imm & rs2(63 downto 0);
                    when "101" => rd <= rs2(127 downto 96) & imm & rs2(79 downto 0);
                    when "110" => rd <= rs2(127 downto 112) & imm & rs2(95 downto 0);
                    when "111" => rd <= imm & rs2(111 downto 0);
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
			
				rd <= (others => '0');	-- Do nothing basically
			
			-------------------------
            when "01010" =>  -- SHRHI
			-------------------------
			
				-- rs1 is the target register, rs2 4 LSBs are shift amount
				
				-- Using shift_right() from numeric.std, takes a unsigned array to shift and an integer for shift amount
				-- Using to_integer() from numeric.std to convert last 4 bits to an integer for use in shift_right() 
				-- Converting target half-words of rs1 to type UNSIGNED to indicate to shift_right() to zero-fill instead of sign extend
				-- Finally, convert back to type STD_LOGIC_VECTOR to write to rd
				rd(15 downto 0) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(15 downto 0)), to_integer(UNSIGNED(rs2(3 downto 0))))); 
				rd(31 downto 16) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(31 downto 16)), to_integer(UNSIGNED(rs2(3 downto 0)))));
				rd(47 downto 32) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(47 downto 32)), to_integer(UNSIGNED(rs2(3 downto 0)))));
				rd(63 downto 48) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(63 downto 48)), to_integer(UNSIGNED(rs2(3 downto 0))))); 
				
				rd(79 downto 64) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(79 downto 64)), to_integer(UNSIGNED(rs2(3 downto 0)))));
				rd(95 downto 80) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(95 downto 80)), to_integer(UNSIGNED(rs2(3 downto 0)))));
				rd(111 downto 96) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(111 downto 96)), to_integer(UNSIGNED(rs2(3 downto 0)))));
				rd(127 downto 112) <= STD_LOGIC_VECTOR(shift_right(UNSIGNED(rs1(127 downto 112)), to_integer(UNSIGNED(rs2(3 downto 0)))));
			
			----------------------
            when "01011" =>  -- AU
			----------------------
			
				-- Converting values from type STD_LOGIC_VECTOR to UNSIGNED
				-- Adding them
				-- Converting result back to type STD_LOGIC_VECTOR
				-- Write value to rd, regardless of overflow/underflow
				rd(31 downto 0) <= STD_LOGIC_VECTOR(UNSIGNED(rs1(31 downto 0)) + UNSIGNED(rs2(31 downto 0)));	  
				rd(63 downto 32) <= STD_LOGIC_VECTOR(UNSIGNED(rs1(63 downto 32)) + UNSIGNED(rs2(63 downto 32)));
				rd(95 downto 64) <= STD_LOGIC_VECTOR(UNSIGNED(rs1(95 downto 64)) + UNSIGNED(rs2(95 downto 64)));
				rd(127 downto 96) <= STD_LOGIC_VECTOR(UNSIGNED(rs1(127 downto 96)) + UNSIGNED(rs2(127 downto 96)));
			
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
			
				for i in 0 to 3 loop
					
					rd(31 + (32*i) downto (32 * i)) <= 	 rs1(127 downto 96); --Copying left most word from rs1 into each word of rd
				
				end loop;
				
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

-------------------
-- Execute Stage
-------------------
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity execute is
    port(   
        write_enable_in : in STD_LOGIC;             
        write_enable_out : out STD_LOGIC;
        ALU_op : in STD_LOGIC_VECTOR(4 downto 0);   
        ALU_source : in STD_LOGIC;                  
        is_load : in STD_LOGIC;                     
        forward_1 : in STD_LOGIC;
		forward_2 : in STD_LOGIC;   
		forward_3 : in STD_LOGIC;   
        rs1 : in STD_LOGIC_VECTOR(4 downto 0);
        rs2 : in STD_LOGIC_VECTOR(4 downto 0);
        rs3 : in STD_LOGIC_VECTOR(4 downto 0);  
        rs1_d : in STD_LOGIC_VECTOR(127 downto 0);  
        rs2_d : in STD_LOGIC_VECTOR(127 downto 0);
        rs3_d : in STD_LOGIC_VECTOR(127 downto 0);  
        rs1_df : in STD_LOGIC_VECTOR(127 downto 0); 
        rs2_df : in STD_LOGIC_VECTOR(127 downto 0);
        rs3_df : in STD_LOGIC_VECTOR(127 downto 0);
        rd_in : in STD_LOGIC_VECTOR(4 downto 0);    
        rd_out : out STD_LOGIC_VECTOR(4 downto 0);  
        rd_d : out STD_LOGIC_VECTOR(127 downto 0);
        imm : in STD_LOGIC_VECTOR(15 downto 0);
        ind : in STD_LOGIC_VECTOR(2 downto 0)
    );
end execute;

architecture structural of execute is  
    signal rs1_mux : STD_LOGIC_VECTOR(127 downto 0); 
    signal rs2_mux : STD_LOGIC_VECTOR(127 downto 0);
	signal rs2_mux : STD_LOGIC_VECTOR(127 downto 0);

begin 
    
    process (all) is
    begin

        -- This eliminates any possibility of an 'X' or 'U' floating into the ALU.
        rs1_mux <= (others => '0'); 
        rs2_mux <= (others => '0');
		rs3_mux <= (others => '0');
        
        -- MUX LOGIC (Handles Operand Selection and Padding)
        if is_load = '1' then 
            -- Load Immediate (LI) processing: rs1_mux carries the new register value.
            
            -- This preserves all 128 bits that are NOT being overwritten by 'imm' or 'ind'.
            rs1_mux <= rs1_d; 

            -- Overwrite the specific fields: immediate (15:0) and index (18:16).
            rs1_mux(15 downto 0) <= imm;
            rs1_mux(18 downto 16) <= ind;
            
            if forward_2 = '1' then 
                rs2_mux <= rs2_df;	
            else 
                rs2_mux <= rs2_d; 
            end if;

			if forward_3 = '1' then 
                rs3_mux <= rs3_df;	
            else 
                rs3_mux <= rs3_d; 
            end if;
        
        elsif ALU_source = '1' then 
            -- Immediate/Shift Instructions (SHRHI, MLHCU)
            
            -- rs1_mux handles forwarding for the main register source
            if forward_1 = '1' then 
                rs1_mux <= rs1_df; 
            else 
                rs1_mux <= rs1_d; 
            end if;
            
            -- CRITICAL FIX 2: Zero-extend the 5-bit immediate input (rs2).
            -- rs2_mux is cleared to '0' at the start of the process, so we only need to drive the low bits.
            rs2_mux(4 downto 0) <= rs2(4 downto 0);

			if forward_3 = '1' then
				rs3_mux <= rs3_df;
			else
				rs3_mux <= rs3_d;
			end if;
        
        else 
            -- Standard R-Type (rs1, rs2, rs3 are all registers)
            rs1_mux <= rs1_df when forward_1 = '1' else rs1_d; 
            rs2_mux <= rs2_df when forward_2 = '1' else rs2_d;
			rs3_mus <= rs3_df when forward_3 = '1' else rs3_d;
        
        end if;
        
    end process;
    
    -- ALU instantiation (ALU process is fixed to output clean 0s)
    ALU : entity work.ALU(behavioral) port map (
        instr => ALU_op, rs1 => rs1_mux, rs2 => rs2_mux, rs3 => rs3_d, rd => rd_d
    );  
    
    -- Pipeline outputs
    rd_out <= rd_in; 
    write_enable_out <= write_enable_in;
end structural;

------------------
-- Forward Unit
------------------
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity forwarding is
    port(     
        rs1 : in STD_LOGIC_VECTOR(4 downto 0);              
        rs2 : in STD_LOGIC_VECTOR(4 downto 0);              
        rs3 : in STD_LOGIC_VECTOR(4 downto 0);              
        rd : in STD_LOGIC_VECTOR(4 downto 0);               
        rs1_d : out STD_LOGIC_VECTOR(127 downto 0);         
        rs2_d : out STD_LOGIC_VECTOR(127 downto 0);         
        rs3_d : out STD_LOGIC_VECTOR(127 downto 0);         
        rd_d : in STD_LOGIC_VECTOR(127 downto 0);           
        forward_1 : out STD_LOGIC; 
		forward_2 : out STD_LOGIC;
		forward_3 : out STD_LOGIC
    );
end forwarding;

architecture behavioral of forwarding is  
begin
    process(rs1, rs2, rs3, rd, rd_d) is 
    begin 

        if rd = rs1 then    
            forward_1 <= '1';
			forward_2 <= '0';
			forward_3 <= '0';
			rs1_d <= rd_d; 
			rs2_d <= (others => '-'); 
			rs3_d <= (others => '-');

        elsif rd = rs2 then
            forward_1 <= '0';
			forward_2 <= '1';
			forward_3 <= '0';
			rs1_d <= (others => '-'); 
			rs2_d <= rd_d; 
			rs3_d <= (others => '-');

        elsif rd = rs3 then 
            forward <= '1'; rs1_d <= (others => '-'); rs2_d <= (others => '-'); rs3_d <= rd_d;
        else 
            forward <= '0'; rs1_d <= (others => '-'); rs2_d <= (others => '-'); rs3_d <= (others => '-');
        end if;
    end process;
end behavioral;

------------------
-- Writeback Stage
------------------
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity writeback is
    port(   
        write_enable : in STD_LOGIC;                
        rs1 : in STD_LOGIC_VECTOR(4 downto 0);      
        rs2 : in STD_LOGIC_VECTOR(4 downto 0);
        rs3 : in STD_LOGIC_VECTOR(4 downto 0);      
        rs1_d : out STD_LOGIC_VECTOR(127 downto 0); 
        rs2_d : out STD_LOGIC_VECTOR(127 downto 0);
        rs3_d : out STD_LOGIC_VECTOR(127 downto 0);
        rd : in STD_LOGIC_VECTOR(4 downto 0);       
        rd_d : in STD_LOGIC_VECTOR(127 downto 0);   
        forward : out STD_LOGIC
    );
end writeback;

architecture structural of writeback is  
begin 
    fw : entity work.forwarding(behavioral) port map (
        rs1 => rs1, rs2 => rs2, rs3 => rs3,
        rs1_d => rs1_d, rs2_d => rs2_d, rs3_d => rs3_d,
        rd => rd, rd_d => rd_d, forward => forward
    );      
end structural;
    
---------------------------------------------
-- EX/WB Pipeline Reg
---------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity EXWB is
    port(   
        reset : in STD_LOGIC;                               
        clk : in STD_LOGIC;                             
        
        write_enable_in : in STD_LOGIC;
        write_enable_out : out STD_LOGIC;

        rd_in : in STD_LOGIC_VECTOR(4 downto 0);                
        rd_out : out STD_LOGIC_VECTOR(4 downto 0);              
        rd_d_in : in STD_LOGIC_VECTOR(127 downto 0);        
        rd_d_out : out STD_LOGIC_VECTOR(127 downto 0)       
    );
end EXWB;

architecture behavioral of EXWB is  
begin
    process (reset, clk) is 
    begin
        if (reset = '1') then   
            rd_out <= (others => '0');  
            rd_d_out <= (others => '0'); 
            write_enable_out <= '0';
        elsif rising_edge(clk) then     
            rd_out <= rd_in; 
            rd_d_out <= rd_d_in;
            write_enable_out <= write_enable_in;
        end if; 
    end process;
end behavioral;

----------------------------------------------------
-- Final CPU STRUCTURAL UNIT
----------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.CPU_Defs.all;
use work.all;

entity CPU is
    port (
        clk : in std_logic;
        reset : in std_logic;
        load_en : in std_logic;
        load_addr : in std_logic_vector(5 downto 0);
        load_data : in std_logic_vector(24 downto 0);
        reg_file_contents: out REG_FILE_ARRAY_TYPE;
        res_PC : out std_logic_vector(5 downto 0);
        res_Instruction : out std_logic_vector(24 downto 0);
        res_ALU_Result  : out std_logic_vector(127 downto 0);
        res_Forward     : out std_logic;
        res_WB_Data     : out std_logic_vector(127 downto 0);
        res_RegWrite    : out std_logic
    );
end CPU;

architecture structural of CPU is
    -- Signal Declarations
    signal s1_pc_out : std_logic_vector(5 downto 0);
    signal s1_instr_out : std_logic_vector(24 downto 0);
    signal IF_data_in : std_logic_vector(24 downto 0);
    
    signal s2_write_en, s2_alu_src, s2_is_load : std_logic;
    signal s2_alu_op : std_logic_vector(4 downto 0);
    signal s2_rs1_data, s2_rs2_data, s2_rs3_data : std_logic_vector(127 downto 0);
    signal s2_rs1_addr, s2_rs2_addr, s2_rs3_addr, s2_rd_addr : std_logic_vector(4 downto 0);
    signal s2_imm : std_logic_vector(15 downto 0);
    signal s2_ld_idx : std_logic_vector(2 downto 0);
    signal res_s2_reg_file : REG_FILE_ARRAY_TYPE;

    signal ie_write_en, ie_alu_src, ie_is_load : std_logic;
    signal ie_alu_op : std_logic_vector(4 downto 0);
    signal ie_rs1_data, ie_rs2_data, ie_rs3_data : std_logic_vector(127 downto 0);
    signal ie_rs1_addr, ie_rs2_addr, ie_rs3_addr, ie_rd_addr : std_logic_vector(4 downto 0);
    signal ie_imm : std_logic_vector(15 downto 0);
    signal ie_ld_idx : std_logic_vector(2 downto 0);

    signal s3_rd_addr : STD_LOGIC_VECTOR(4 downto 0); 
    signal s3_alu_result : STD_LOGIC_VECTOR(127 downto 0); 
    signal s3_write_en : std_logic;

    signal EX_rd_in, EX_rd_out : std_logic_vector(4 downto 0);
    signal EX_rd_d_in, EX_rd_d_out : std_logic_vector(127 downto 0);
    signal EX_we_in, EX_we_out : std_logic; 

    signal forward_rs1_d, forward_rs2_d, forward_rs3_d : STD_LOGIC_VECTOR(127 downto 0);
    signal forward_ctrl_sig : STD_LOGIC;

begin
    ------------
    -- STAGE 1 (Fetch)
    ------------
    S1: entity stage_1
        port map (
            clk => clk, reset => reset, load_en => load_en, load_addr => load_addr, 
            load_data => load_data, instr_out => s1_instr_out, pc_out => s1_pc_out
        );
        
    RegIFID: entity IFID
        port map (clk => clk, reset => reset, data_in => s1_instr_out, data_out => IF_data_in); 
        
    ------------
    -- STAGE 2 (Decode)
    ------------
    S2: entity stage_2
        port map (
            clk => clk, reset => reset, instr_in => IF_data_in,
            wb_reg_write  => EX_we_out,  -- CONNECTED FROM EXWB
            wb_dest_addr  => EX_rd_out,  -- CONNECTED FROM EXWB
            wb_write_data => EX_rd_d_out, -- CONNECTED FROM EXWB
            ctrl_write_en => s2_write_en, ctrl_alu_op => s2_alu_op, ctrl_alu_src => s2_alu_src, ctrl_is_load => s2_is_load,
            rs1_data => s2_rs1_data, rs2_data => s2_rs2_data, rs3_data => s2_rs3_data,
            rs1_addr_out => s2_rs1_addr, rs2_addr_out => s2_rs2_addr, rs3_addr_out => s2_rs3_addr, 
            rd_addr_out => s2_rd_addr, imm_out => s2_imm, ld_idx_out => s2_ld_idx,
            reg_file_out => res_s2_reg_file
        );
        
    RegIDEX: entity IDEX
        port map (
            clk => clk, reset => reset,
            write_enable_in => s2_write_en, write_enable_out => ie_write_en,
            ALU_op_in => s2_alu_op, ALU_op_out => ie_alu_op,
            ALU_source_in => s2_alu_src, ALU_source_out => ie_alu_src,
            is_load_in => s2_is_load, is_load_out => ie_is_load,
            rs1_in => s2_rs1_addr, rs1_out => ie_rs1_addr,
            rs2_in => s2_rs2_addr, rs2_out => ie_rs2_addr,
            rs3_in => s2_rs3_addr, rs3_out => ie_rs3_addr,
            rd_in => s2_rd_addr, rd_out => ie_rd_addr,
            rs1_d_in => s2_rs1_data, rs1_d_out => ie_rs1_data,
            rs2_d_in => s2_rs2_data, rs2_d_out => ie_rs2_data,
            rs3_d_in => s2_rs3_data, rs3_d_out => ie_rs3_data,
            imm_in => s2_imm, imm_out => ie_imm,
            ind_in => s2_ld_idx, ind_out => ie_ld_idx
        );
        
    ------------
    -- STAGE 3 (Execute)
    ------------
    Stage_ALU: entity execute
        port map (
            write_enable_in => ie_write_en, write_enable_out => s3_write_en,
            ALU_op => ie_alu_op, ALU_source => ie_alu_src, is_load => ie_is_load,
            forward => forward_ctrl_sig,
            rs1 => ie_rs1_addr, rs2 => ie_rs2_addr, rs3 => ie_rs3_addr,
            rs1_d => ie_rs1_data, rs2_d => ie_rs2_data, rs3_d => ie_rs3_data,
            rs1_df => forward_rs1_d, rs2_df => forward_rs2_d, rs3_df => forward_rs3_d,
            rd_in => ie_rd_addr, rd_out => s3_rd_addr, rd_d => s3_alu_result,
            imm => ie_imm, ind => ie_ld_idx
        );
        
    -- Connect EX/WB inputs
    EX_rd_in <= s3_rd_addr;
    EX_rd_d_in <= s3_alu_result;
    EX_we_in <= s3_write_en;

    RegEXWB: entity EXWB
        port map (
            reset => reset, clk => clk,
            rd_in => EX_rd_in, rd_out => EX_rd_out,
            rd_d_in => EX_rd_d_in, rd_d_out => EX_rd_d_out,
            write_enable_in => EX_we_in, write_enable_out => EX_we_out
        ); 
        
    ------------
    -- STAGE 4 (Writeback / Forwarding)
    ------------
    Stage_WB: entity writeback
        port map ( 
            write_enable => EX_we_out, -- CONNECTED to Pipeline Register
            rs1 => ie_rs1_addr, rs2 => ie_rs2_addr, rs3 => ie_rs3_addr, 
            rs1_d => forward_rs1_d, rs2_d => forward_rs2_d, rs3_d => forward_rs3_d,
            rd => EX_rd_out, rd_d => EX_rd_d_out,
            forward => forward_ctrl_sig
        );
        
    -- Outputs
    res_PC <= s1_pc_out;
    res_Instruction <= IF_data_in;
    res_ALU_Result  <= s3_alu_result;
    res_WB_Data     <= EX_rd_d_out; 
    res_RegWrite    <= EX_we_out; 
    res_Forward     <= forward_ctrl_sig; 
    reg_file_contents <= res_s2_reg_file;
        
end structural;
