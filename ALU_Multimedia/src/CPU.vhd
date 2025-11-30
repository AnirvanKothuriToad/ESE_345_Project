-------------------------------------------------------------------------------
--
-- Title       : CPU
-- Design      : CPU_Multimedia
-- Author      : Anirvan Kothuri and Mahir Patel
-- Company     : Stony Brook University
--
-------------------------------------------------------------------------------
--
-- File        : C:/Users/anirv/Downloads/Fall 2025/ESE 345/Project1/ProjectPart1/ALU_Multimedia/src/Multimedia_CPU.vhd
-- Generated   : Sat Nov 29 13:46:11 2025
-- From        : Interface description file
-- By          : ItfToHdl ver. 1.0
--
-------------------------------------------------------------------------------
--
-- Description :  A Structural Architecture that connects all entities: ALU, Register File, forwarding, and Pipeline
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--    and may be overwritten
--{entity {CPU} architecture {CPU}}

 
	-------------------------------
	--PC Register------------------
	-------------------------------

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


entity PC is
	port(	
		reset : in STD_LOGIC;							  	-- Asynchronous reset
		clk : in STD_LOGIC;							   		-- Clock signal	 
		data_out : out STD_LOGIC_VECTOR(5 downto 0)	   		-- PC output
													
	);
end PC;

--}} End of automatically maintained section

architecture behavioral of PC is  

begin

	process (reset, clk) is	-- Only operating on rising clock edges unless reset is asserted
	
	begin
		if (reset = '1') then	-- Asynchronous reset, does not rely on clk
			
			-- Clear PC
			
			data_out <= (others => '0');
			
			
		else  -- reset not asserted, function normally
			
			if rising_edge(clk) then 	-- Update on every positive edge of clk 
				
				-- Increment PC value on every clock edge
				data_out <= STD_LOGIC_VECTOR(UNSIGNED(data_out) + 1);	-- PC <= PC + 1
				
				
			end if;
			
		end if;	
					
	end process;

end behavioral;

	-------------------------------
	--INSTRUCTION BUFFER-----------
	-------------------------------

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

--------------------------------
--Structural Unit for Stage 1---
--------------------------------
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity stage_1 is
	port(
	    clk          : in  std_logic;
        reset        : in  std_logic;
        
        -- Ports for Testbench to create results file
        load_en   : in  std_logic; 
        load_addr : in  std_logic_vector(5 downto 0);
        load_data : in  std_logic_vector(24 downto 0);
        
        -- Outputs
        instr_out    : out std_logic_vector(24 downto 0);
        pc_out       : out std_logic_vector(5 downto 0)
	);
end stage_1;


architecture structural of stage_1 is

	signal current_pc : std_logic_vector(5 downto 0); --Internal PC Signal
	
	signal buffer_addr_in : std_logic_vector(5 downto 0); 
	
begin
	
	pc_out <= current_pc; --Connecting local signal to port
	
	buffer_addr_in <= load_addr when load_en = '1' else current_pc;	--When load_en is asserted, address from testbench will be used
	
	u0: entity PC
		port map(
		reset => reset,
		clk => clk,
		data_out => current_pc --connecting PC value to local signal
		);
	
	u1: entity InstrBuffer
		port map(
		reset => reset,
		clk => clk,
		write_enable => load_en,
		PC_in => buffer_addr_in,
		data_in => load_data,
		data_out => instr_out
		);
end structural;
		
--------End of Stage_1 Structural---------	

	------------------------------------
	--IF/ID Pipeline Register-----------
	------------------------------------
	
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

--------------------------
--STAGE 2------------------
---------------------------


	------------------------------------
	--Control Unit-----------
	------------------------------------
	
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity control is
	port(	
		instr : in STD_LOGIC_VECTOR(24 downto 0);	-- Binary instruction 
	   
		write_enable : out STD_LOGIC;				-- Write enable (always on unless nop)	
		
		ALU_op : out STD_LOGIC_VECTOR(4 downto 0);	-- ALU operation 						
		ALU_source : out STD_LOGIC;					-- Choose between register or immediate based on instruction
		
		is_load	: out STD_LOGIC						-- Switch MUX inputs if load instruction 
													-- (rs1(18 downto 16) <= load_index, rs1(15 downto 0) <= load_imm, rs2 <= rd)
		
	
	);
end control;

--}} End of automatically maintained section

architecture behavioral of control is  

begin

	process(instr) is	-- Only operating on rising clock edges unless reset is asserted
	
	begin		  
		
		-----------------------------------------------------
		if instr(24) = '0' then	-- Load Immediate instruction 
		-----------------------------------------------------
		
			ALU_op <= (others => '0'); -- ALU operation for load immediate
			write_enable <= '1';	-- Will be writing to rd
			is_load <= '1'; 		-- Need to tell MUXs to switch
		    ALU_source <= '0';
		---------------------------------------------	
		elsif instr(23) = '0' then	-- R4 Instruction
		---------------------------------------------
			
			write_enable <= '1';	-- Always on for any R4 instruction
			is_load <= '0';			-- Not load immediate instruction 
			ALU_source <= '0';		-- Only used for SHRHI and MLCHS R3 instructions
			
			case instr(22 downto 20) is
				
				when "000" =>	-- Signed Integer Multiply-Add Low with Saturation
					ALU_op <= "00001";
				
				when "001" =>	-- Signed Integer Multiply-Add High with Saturation
					ALU_op <= "00010";
				
				when "010" =>	-- Signed Integer Multiply-Subtract Low with Saturation
					ALU_op <= "00011"; 
				
				when "011" =>	-- Signed Integer Multiply-Subtract High with Saturation
					ALU_op <= "00100"; 
				
				when "100" =>	-- Signed Long Integer Multiply-Add Low with Saturation
					ALU_op <= "00101";
				
				when "101" =>	-- Signed Long Integer Multiply-Add High with Saturation
					ALU_op <= "00110"; 
				
				when "110" =>	-- Signed Long Integer Multiply-Subtract Low with Saturation
					ALU_op <= "00111"; 
				
				when "111" =>	-- Signed Long Integer Multiply-Subtract High with Saturation
					ALU_op <= "01000";
				
				when others => 	-- Invalid
					ALU_op <= "XXXXX";
				
			end case;
		
		-------------------------
		else	-- R3 Instruction
		-------------------------
		
			write_enable <= '1';	-- All instructions except NOP write back to reg file 
			is_load <= '0';			-- Not load immediate instruction
			ALU_source <= '0';		-- Only asserted on SHRHI and MLHCU
			
			case instr(18 downto 15) is	-- Useful opcode, rest is don't cares
				
				when "0000" =>	-- NOP	
					ALU_op <= "01001";
				
					write_enable <= '0';	-- Don't do anything
					
				
				when "0001" =>	-- SHRHI	
					ALU_op <= "01010"; 
					ALU_source <= '1';	-- Using 4 LSBs of 5-bit immediate value of rs2 from instruction
				
				
				when "0010" =>	-- AU	
					ALU_op <= "01011";
				
				
				when "0011" =>	-- CNT1H	
					ALU_op <= "01100";
				
				
				when "0100" =>	-- AHS	
					ALU_op <= "01101";
				
				
				when "0101" =>	-- OR	
					ALU_op <= "01110";
				
				
				when "0110" =>	-- BCW	
					ALU_op <= "01111";
				
				
				when "0111" =>	-- MAXWS	
					ALU_op <= "10000";
				
				
				when "1000" =>	-- MINWS	
					ALU_op <= "10001";
				
				
				when "1001" =>	-- MLHU	
					ALU_op <= "10010";
				
				
				when "1010" =>	-- MLHCU	
					ALU_op <= "10011";
					ALU_source <= '1'; -- Using 5-bit immediate value of rs2 from instruction
				
				
				when "1011" =>	-- AND	
					ALU_op <= "10100";
				
				
				when "1100" =>	-- CLZW	
					ALU_op <= "10101";
				
				
				when "1101" =>	-- ROTW	
					ALU_op <= "10110";
				
				
				when "1110" =>	-- SFWU	
					ALU_op <= "10111";
				
				
				when "1111" =>	-- SFHS	
					ALU_op <= "11000"; 
				
				when others => 	-- Invalid
					ALU_op <= "XXXXX";
				
			end case;		
				
		end if;
		
	end process;

end behavioral;


	------------------------------------
	--Register File-----------
	------------------------------------ 
	
library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity RegFile is
	port(	
		reset : in STD_LOGIC;							   -- Asynchronous reset
		clk : in STD_LOGIC;								   -- Clock signal
		write_enable : in STD_LOGIC;					   -- If enabled, write to register pointed to by address_in
		
		
		address_out_A : in STD_LOGIC_VECTOR(4 downto 0);   -- Register to read from (A)
		address_out_B : in STD_LOGIC_VECTOR(4 downto 0);   -- Register to read from (B)
		address_out_C : in STD_LOGIC_VECTOR(4 downto 0);   -- Register to read from (C)	
		data_out_A : out STD_LOGIC_VECTOR(127 downto 0);   -- Value read from register (A)
		data_out_B : out STD_LOGIC_VECTOR(127 downto 0);   -- Value read from register (B)
		data_out_C : out STD_LOGIC_VECTOR(127 downto 0);   -- Value read from register (C)
		
		
		address_in : in STD_LOGIC_VECTOR(4 downto 0); 	   -- Register to write to
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

--------------------------------
--Structural Unit for Stage 2---
--------------------------------

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity stage_2 is 
	port(
	
	clk: in std_logic;
	reset: in std_logic;
	
	--Input from IF/ID Register(Instruction)
	instr_in : std_logic_vector(24 downto 0);
	
	--Inputs from Write Back Stage
	wb_reg_write: in std_logic;
	wb_dest_addr: in std_logic_vector(4 downto 0);
	wb_write_data: in std_logic_vector(127 downto 0);
	
	--Outputs to ID?EX Register
	--Control Signals
	ctrl_write_en : out std_logic;
	ctrl_alu_op	  : out std_logic_vector(4 downto 0);
	ctrl_alu_src	  : out std_logic;
	ctrl_is_load  : out std_logic;
	
	rs1_data      : out std_logic_vector(127 downto 0);
    rs2_data      : out std_logic_vector(127 downto 0);
    rs3_data      : out std_logic_vector(127 downto 0);
        
    -- Forwarded Addresses & Immediates
    rs1_addr_out  : out std_logic_vector(4 downto 0);
    rs2_addr_out  : out std_logic_vector(4 downto 0);
    rs3_addr_out  : out std_logic_vector(4 downto 0);
    rd_addr_out   : out std_logic_vector(4 downto 0);
    imm_out       : out std_logic_vector(15 downto 0);
    ld_idx_out    : out std_logic_vector(2 downto 0)
	);
end stage_2;

architecture structural of stage_2 is

	--Internal signals for register addresses
	signal addr_a : std_logic_vector(4 downto 0);  --For rs1
	signal addr_b : std_logic_vector(4 downto 0);  --For rs2
	signal addr_c : std_logic_vector(4 downto 0);  --For rs3
	
	signal sig_is_load : std_logic;	 --MUX input if instruction is load or not

begin
	
	u0: entity control
		port map(
			instr => instr_in,
			write_enable => ctrl_write_en,
			ALU_op => ctrl_alu_op,
			ALU_source => ctrl_alu_src,
			is_load => sig_is_load
		);
		
	ctrl_is_load <= sig_is_load; --Passing the signal to ID/EX register
	
	--RS1 bits 9-5
	addr_a <= instr_in(9 downto 5);
	
	--RS3 is always bits 19-15 for R4
	addr_c <= instr_in(19 downto 15);
	
	--RS2 MUX needed
	-- If LI (sig_is_load ='1') then destination register has to be read
	addr_b <= instr_in(4 downto 0) when sig_is_load = '1' else instr_in(14 downto 10);
		
		
	--Accessing Register File entity
	u1: entity regFile
		port map(
			clk => clk,
			reset => reset,
			
			--Write Back input connection
			write_enable => wb_reg_write,
			address_in => wb_dest_addr,
			data_in => wb_write_data,
			
			--Read Ports
			address_out_A => addr_a,
			address_out_B => addr_b,
			address_out_C => addr_c,
			
			--Read Data outputs(Going to ID/EX)
			data_out_A => rs1_data,
			data_out_B => rs2_data,
			data_out_C => rs3_data
		); 
	
	--Send data to ID/EX (Needed in Forwarding)
	rs1_addr_out <= addr_a;
    rs2_addr_out <= addr_b;
    rs3_addr_out <= addr_c;
    rd_addr_out  <= instr_in(4 downto 0); -- location of rd
    
    -- Send Immediate values to ID/EX (for 'li' in ALU)
    imm_out      <= instr_in(20 downto 5);
    ld_idx_out   <= instr_in(23 downto 21);
	
end structural; 


--------End of Stage_2 Structural---------

	------------------------------------
	--ID/EX Pipeline Register-----------
	------------------------------------

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity IDEX is
	port(	
		reset : in STD_LOGIC;							  	-- Asynchronous reset
		clk : in STD_LOGIC;							   		-- Clock signal	
		
		-- Outputs of decoder
		write_enable_in : in STD_LOGIC;						-- write enable in
		write_enable_out : out STD_LOGIC;					-- write enable out
		
		ALU_op_in : in STD_LOGIC_VECTOR(4 downto 0);		-- ALU operation in
		ALU_op_out : out STD_LOGIC_VECTOR(4 downto 0);		-- ALU operation out
		
		ALU_source_in : in STD_LOGIC;						-- ALU source in
		ALU_source_out : out STD_LOGIC;						-- ALU source out
		
		is_load_in : in STD_LOGIC;							-- is_load input
		is_load_out : out STD_LOGIC;						-- is_load output
		
		
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
		ind_out : out STD_LOGIC_VECTOR(2 downto 0)			-- ind output
		
		
	);
end IDEX;

--}} End of automatically maintained section

architecture behavioral of IDEX is  

begin

	process (reset, clk) is	-- Only operating on rising clock edges unless reset is asserted
	
	begin
		if (reset = '1') then	-- Asynchronous reset, does not rely on clk
			
			-- Clear register
			write_enable_out <= '0';   
			ALU_op_out <= (others => '0'); 
			ALU_source_out <= '0'; 
			is_load_out <= '0'; 
			
			rs1_out <= (others => '0');
			rs2_out <= (others => '0');
			rs3_out <= (others => '0');
			
			rs1_d_out <= (others => '0');
			rs2_d_out <= (others => '0');
			rs3_d_out <= (others => '0');
			
			rd_out <= (others => '0');
			
			imm_out	<= (others => '0');
			ind_out <= (others => '0');
			
			
		else  -- reset not asserted, function normally
			
			if rising_edge(clk) then 	-- Update on every positive edge of clk 
				
				write_enable_out <= write_enable_in;
				ALU_op_out <= ALU_op_in;
				ALU_source_out <= ALU_source_in;
				is_load_out <= is_load_in;
				
				rs1_out <= rs1_in;
				rs2_out <= rs2_in;
				rs3_out <= rs3_in; 		 
				
				rs1_d_out <= rs1_d_in;
				rs2_d_out <= rs2_d_in;
				rs3_d_out <= rs3_d_in; 
				
				rd_out <= rd_in;
				
				imm_out <= imm_in;
				ind_out <= ind_in;
				
			end if;
			
		end if;	
					
	end process;

end behavioral;





	
--------------------------
--STAGE 3------------------
---------------------------
	
	-----------------
	--ALU------------
	-----------------
	
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
        case instr is  
			----------------------------------
            when "00000" =>  -- Load Immediate
			----------------------------------	
				imm := rs1(15 downto 0); --Extracting 16 LSBs from RS1 to obtain the immediate value
				ld_in := UNSIGNED(rs1(18 downto 16)); --Using Bits 18, 17, 16 for the index value
				
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
			
				rd <= (others => '-');	-- Do nothing basically
			
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
-- Execute Stage --
-------------------

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity execute is
	port(	
	
	-- Control signals
	write_enable_in : in STD_LOGIC;				-- write enable (pass to EXWB register)
	write_enable_out : out STD_LOGIC;
	
	ALU_op : in STD_LOGIC_VECTOR(4 downto 0);	-- ALU operation (pass to ALU)
	ALU_source : in STD_LOGIC;					-- ALU source (use in if statement to pass correct value into ALU)
	is_load : in STD_LOGIC;						-- is_load (use in if statement to pass correct value into ALU)	 
		
	forward : in STD_LOGIC;						-- forward control signal (comes from forwarding unit in WB stage)
	
	-- Read register numbers
	rs1 : in STD_LOGIC_VECTOR(4 downto 0);
	rs2 : in STD_LOGIC_VECTOR(4 downto 0);
	rs3 : in STD_LOGIC_VECTOR(4 downto 0);	 
	
	-- Read register data (not forwarded)
	rs1_d : in STD_LOGIC_VECTOR(127 downto 0);	
	rs2_d : in STD_LOGIC_VECTOR(127 downto 0);
	rs3_d : in STD_LOGIC_VECTOR(127 downto 0);	
	
	-- Read register data (forwarded)
	rs1_df : in STD_LOGIC_VECTOR(127 downto 0);	
	rs2_df : in STD_LOGIC_VECTOR(127 downto 0);
	rs3_df : in STD_LOGIC_VECTOR(127 downto 0);
	
	-- Write register number
	rd_in : in STD_LOGIC_VECTOR(4 downto 0);   	
	rd_out : out STD_LOGIC_VECTOR(4 downto 0);	
	
	-- Write register data
	rd_d : out STD_LOGIC_VECTOR(127 downto 0);
	
	-- Load instruction values
	imm : in STD_LOGIC_VECTOR(15 downto 0);
	ind : in STD_LOGIC_VECTOR(2 downto 0)
		
		
	);
end execute;

--}} End of automatically maintained section

architecture structural of execute is  

signal rs1_mux : STD_LOGIC_VECTOR(127 downto 0); 
signal rs2_mux : STD_LOGIC_VECTOR(127 downto 0);
-- rs3 never goes through a MUX

begin 
	
	process (all) is
	
	begin
	
		if is_load = '1' then 
			rs1_mux(15 downto 0) <= imm;
			rs1_mux(18 downto 16) <= ind;
			rs1_mux(127 downto 19) <= (others => '-');	-- Set rest as don't cares
			
			if forward = '1' then 
				rs2_mux <= rs2_df;	-- rs2_d should be same as rd
				
			else 
				rs2_mux <= rs2_d; 
				
			end if;
		
		elsif ALU_source = '1' then	
			
			if forward = '1' then
				rs1_mux <= rs1_df;
			
			else
				rs1_mux <= rs1_d;
			
			end if;
			
			rs2_mux(4 downto 0) <= rs2;	-- rs2 has the same value as the immediate field from original instruction 
			
		else 
			rs1_mux <= rs1_d;
			rs2_mux <= rs2_d;
		
		end if;
		
	end process;
		
	ALU : entity ALU(behavioral) port map (
		instr => ALU_op,
		rs1 => rs1_mux,
		rs2 => rs2_mux,
		rs3 => rs3_d,
		rd => rd_d
	);	
	
	rd_out <= rd_in;	-- Passes through this stage to write-back stage 
	write_enable_out <= write_enable_in;
	
end structural;


--------------
--Stage 4 Write Back
--------------

------------------
-- Forward Unit --
------------------
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


library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use work.all;

entity writeback is
	port(	
	
		
	-- Control signals
	write_enable : in STD_LOGIC;				-- write enable
	
	-- Read registers passed from ID stage
	rs1 : in STD_LOGIC_VECTOR(4 downto 0); 		-- rs number
	rs2 : in STD_LOGIC_VECTOR(4 downto 0);
	rs3 : in STD_LOGIC_VECTOR(4 downto 0);		 
	
	rs1_d : out STD_LOGIC_VECTOR(127 downto 0);	-- rs data
	rs2_d : out STD_LOGIC_VECTOR(127 downto 0);
	rs3_d : out STD_LOGIC_VECTOR(127 downto 0);
	
	-- Write registers from EX stage
	rd : in STD_LOGIC_VECTOR(4 downto 0);  		-- rd number
	rd_d : in STD_LOGIC_VECTOR(127 downto 0)	-- rd data	
		
	);
end writeback;

--}} End of automatically maintained section

architecture structural of writeback is  


signal forward : STD_LOGIC;

begin 
	
	fw : entity forwarding(behavioral) port map (
		rs1 => rs1,
		rs2 => rs2,
		rs3 => rs3,
		
		rs1_d => rs1_d,
		rs2_d => rs2_d,
		rs3_d => rs3_d,
		
		rd => rd,
		
		rd_d => rd_d, 
		
		forward => forward
		
	);	  
	
end structural;
	
	
	--------------------
	--EX/WB Pipeline Reg
	--------------------
	
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

---------------------------
--Final CPU STRUCTURAL UNIT----------
---------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.CPU_Defs.all;
use work.all;

entity CPU is
	port (
		clk : in std_logic;
	 	reset : in std_logic;
		 
		 --Testbench Ports in order to load instruction buffer
		 load_en : in std_logic;
		 load_addr : in std_logic_vector(5 downto 0);
		 load_data : in std_logic_vector(24 downto 0);
		 
		 --Creating a connection between Register File and testbench
		 reg_file_contents: out REG_FILE_ARRAY_TYPE;
		 
		 --Ports for Testbench to create Result file
			res_PC : out std_logic_vector(5 downto 0);
			res_Instruction : out std_logic_vector(24 downto 0);
			res_ALU_Result  : out std_logic_vector(127 downto 0);
        	res_Forward   	: out std_logic;
        	res_WB_Data     : out std_logic_vector(127 downto 0);
        	res_RegWrite    : out std_logic
		);
end CPU;

--}} End of automatically maintained section

architecture structural of CPU is
	------------------------------
	--Local Signals for Stage 1-Fetch
	------------------------------	
	signal s1_pc_out       : std_logic_vector(5 downto 0);
    signal s1_instr_out    : std_logic_vector(24 downto 0);
	
		
	------------------------------	
	--Local Signals for IF/ID
	------------------------------
	
		signal IF_data_in : std_logic_vector(24 downto 0);
		signal IF_data_out : std_logic_vector(24 downto 0);
		
	------------------------------	
	--Local Signals for Stage 2-Decode
	------------------------------
	
		-- Control Signals
    signal s2_write_en     : std_logic;
    signal s2_alu_op       : std_logic_vector(4 downto 0);
    signal s2_alu_src      : std_logic;
    signal s2_is_load      : std_logic;
    
    -- Data Signals
    signal s2_rs1_data     : std_logic_vector(127 downto 0);
    signal s2_rs2_data     : std_logic_vector(127 downto 0);
    signal s2_rs3_data     : std_logic_vector(127 downto 0);
    
    -- Addresses & Immediates
    signal s2_rs1_addr     : std_logic_vector(4 downto 0);
    signal s2_rs2_addr     : std_logic_vector(4 downto 0);
    signal s2_rs3_addr     : std_logic_vector(4 downto 0);
    signal s2_rd_addr      : std_logic_vector(4 downto 0);
    signal s2_imm          : std_logic_vector(15 downto 0);
    signal s2_ld_idx       : std_logic_vector(2 downto 0);
		
	------------------------------	
	--Local Signals for ID/EX
	------------------------------
	
	signal ie_write_en     : std_logic;
    signal ie_alu_op       : std_logic_vector(4 downto 0);
    signal ie_alu_src      : std_logic;
    signal ie_is_load      : std_logic;
    
    signal ie_rs1_data     : std_logic_vector(127 downto 0);
    signal ie_rs2_data     : std_logic_vector(127 downto 0);
    signal ie_rs3_data     : std_logic_vector(127 downto 0);
    
    signal ie_rs1_addr     : std_logic_vector(4 downto 0);
    signal ie_rs2_addr     : std_logic_vector(4 downto 0);
    signal ie_rs3_addr     : std_logic_vector(4 downto 0);
    signal ie_rd_addr      : std_logic_vector(4 downto 0);
    
    signal ie_imm          : std_logic_vector(15 downto 0);
    signal ie_ld_idx       : std_logic_vector(2 downto 0);
		 
	------------------------------
	--Local Signals for Stage 3-Execute
	------------------------------
		
	    signal s3_rd_addr :  STD_LOGIC_VECTOR(4 downto 0); --Register destination
        signal s3_alu_result   :  STD_LOGIC_VECTOR(127 downto 0); --Register value
		signal s3_write_en : std_logic;
        
		
	------------------------------	
	--Local Signals for EX/WB
	------------------------------
		
		-- Destination register number
		signal ew_write_en: std_logic;
		signal ew_rd_addr: std_logic_vector(4 downto 0);
		signal ew_alu_result: std_logic_vector(127 downto 0); --rd
		
	------------------------------	
	--Local Signals for Forwarding Unit
	------------------------------	
	
		-- Register numbers that are being read by current instruction
		signal forward_rs1 :  STD_LOGIC_VECTOR(4 downto 0);	   			-- rs1 input
		signal forward_rs2 :  STD_LOGIC_VECTOR(4 downto 0);	   			-- rs2 input
		signal forward_rs3 :  STD_LOGIC_VECTOR(4 downto 0);	   			-- rs3 input
		
		-- Register that is being written to in last instruction
		signal forward_rd :  STD_LOGIC_VECTOR(4 downto 0);	   			-- rd input
		
		-- Register values to forward to
		signal forward_rs1_d :  STD_LOGIC_VECTOR(127 downto 0);	   		-- rs1_d output
		signal forward_rs2_d :  STD_LOGIC_VECTOR(127 downto 0);	   		-- rs2_d output
		signal forward_rs3_d :  STD_LOGIC_VECTOR(127 downto 0);	   		-- rs3_d output	
		
		-- Register value to forward
		signal forward_rd_d :  STD_LOGIC_VECTOR(127 downto 0);			-- rd_d input 
		
		signal forward :  STD_LOGIC;								-- Forwarding MUX control signal
begin
   
	------------
	--STAGE 1---
	------------
	S1: entity stage_1
		port map (
			clk => clk,
			reset => reset,
			
			--connecting local signals to inputs for testbench
			load_en => load_en,
			load_addr => load_addr,
			load_data => load_data,
			
			--Outputs
			intsr_out => s1_instr_out, --Goes to IF/ID
			pc_out => s1_pc_out --Necessary for generating results file
		);
		
	----------------
	--PIPELINE IF/ID
	----------------
	RegIFID: entity IFID
		port map (
			clk => clk,
			reset => reset,
			data_in => s1_instr_out, --Connecting to Stage 1
			data_out => IF_data_in   --Will be used to connect to stage 2
		); 
		
	------------
	--STAGE 2---
	------------
	S2: entity stage_2
		port map (
			clk => clk,
			reset => reset,
			
			--Input from IF/ID
			instr_in => IF_data_in,
			
			--Inputs from Writeback CHANGE	based on Stage 3/4
			wb_reg_write  => wb_reg_write,
            wb_dest_addr  => wb_dest_addr,
            wb_write_data => wb_write_data,
			
			-- Control Outputs
            ctrl_write_en => s2_write_en,
            ctrl_alu_op   => s2_alu_op,
            ctrl_alu_src  => s2_alu_src,
            ctrl_is_load  => s2_is_load,
			
			-- Data Outputs
            rs1_data      => s2_rs1_data,
            rs2_data      => s2_rs2_data,
            rs3_data      => s2_rs3_data,
            
            -- Address/Immediate Outputs
            rs1_addr_out  => s2_rs1_addr,
            rs2_addr_out  => s2_rs2_addr,
            rs3_addr_out  => s2_rs3_addr,
            rd_addr_out   => s2_rd_addr,
            imm_out       => s2_imm,
            ld_idx_out    => s2_ld_idx
		);
		
	----------------
	--PIPELINE ID/EX
	----------------
	
	RegIDEX: entity IDEX
		port map (
			clk              => clk,
            reset            => reset,
            
            write_enable_in  => s2_write_en,  write_enable_out => ie_write_en,
            ALU_op_in        => s2_alu_op,    ALU_op_out       => ie_alu_op,
            ALU_source_in    => s2_alu_src,   ALU_source_out   => ie_alu_src,
            is_load_in       => s2_is_load,   is_load_out      => ie_is_load,
            
            rs1_in           => s2_rs1_addr,  rs1_out          => ie_rs1_addr,
            rs2_in           => s2_rs2_addr,  rs2_out          => ie_rs2_addr,
            rs3_in           => s2_rs3_addr,  rs3_out          => ie_rs3_addr,
            rd_in            => s2_rd_addr,   rd_out           => ie_rd_addr,
            
            rs1_d_in         => s2_rs1_data,  rs1_d_out        => ie_rs1_data,
            rs2_d_in         => s2_rs2_data,  rs2_d_out        => ie_rs2_data,
            rs3_d_in         => s2_rs3_data,  rs3_d_out        => ie_rs3_data,
            
            imm_in           => s2_imm,       imm_out          => ie_imm,
            ind_in           => s2_ld_idx,    ind_out          => ie_ld_idx,
		);
		
		
	Stage_ALU: entity stage_3
		port map (
			--Control Inputs
			write_enable_in => ie_write_en,
			write_enable_out => s3_write_en,
			ALU_op => ie_alu_op,
			ALU_source => ie_alu_src,
			is_load => ie_is_load,
			
			--Forwarding input control
			forward => fwd_ctrl_sig,
			
			--Register address inputs
			rs1 => ie_rs1_addr,
			rs2 => ie_rs2_addr,
			rs3 => ie_rs3_addr,
			
			--Data inputs with No Forwarding
			rs1_d => ie_rs1_data,
			rs2_d => ie_rs2_data,
			rs3_d => ie_rs3_data,
			
			--Forwarded Data Inputs from Stage 4
			rs1_df => fwd_rs1_data,
			rs2_df => fwd_rs2_data,
			rs3_df => fwd_rs3_data,
			
			--Destination
			rd_in => ie_rd_addr,
			rd_out => s3_rd_addr,
			rd_d => s3_alu_result,
			
			--Immediates
			imm => ie_imm,
			ind => ie_ld_idx
		);
		
	RegEXWB: entity EXWB
		port map (
		
		
		
		
		
		); 
		
		--Outputs for results file creation
		res_PC <= s1_pc_out;
		res_Instruction <= 	 IF_data_in;
		res_ALU_Result  <= 
	    res_WB_Data     <= 
	    res_RegWrite    <= 
	    res_Forward
		
		
end structural;
