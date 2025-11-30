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

--------------------------------
-- ALU (Simplified for structure - PASTE YOUR FULL ALU CODE HERE!)
--------------------------------
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

architecture behavioral of ALU is                                            
    -- Keep your existing signals/variables logic here...
    constant SIGNED_16_MAX : SIGNED(15 downto 0) := (15 => '0', others => '1');
    -- ... (constants)
begin
    process(instr, rs3, rs2, rs1) 
        -- Declare variables
        variable imm:  STD_LOGIC_VECTOR(15 downto 0);
        variable ld_in: UNSIGNED(2 downto 0);  
        -- ... (other variables) ...
    begin
        -- !! IMPORTANT: You MUST paste your full ALU case statement back here!
        rd <= (others => '0'); -- Default placeholder
        -- ... [Your ALU Case Statement] ...
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
        forward : in STD_LOGIC;                     
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
begin 
    process (all) is
    begin
        if is_load = '1' then 
            rs1_mux(15 downto 0) <= imm;
            rs1_mux(18 downto 16) <= ind;
            rs1_mux(127 downto 19) <= (others => '-'); 
            if forward = '1' then rs2_mux <= rs2_df; else rs2_mux <= rs2_d; end if;
        elsif ALU_source = '1' then 
            if forward = '1' then rs1_mux <= rs1_df; else rs1_mux <= rs1_d; end if;
            rs2_mux(4 downto 0) <= rs2; rs2_mux(127 downto 5) <= (others => '0'); 
        else 
            rs1_mux <= rs1_d; rs2_mux <= rs2_d;
        end if;
    end process;
        
    ALU : entity work.ALU(behavioral) port map (
        instr => ALU_op, rs1 => rs1_mux, rs2 => rs2_mux, rs3 => rs3_d, rd => rd_d
    );  
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
        forward : out STD_LOGIC                             
    );
end forwarding;

architecture behavioral of forwarding is  
begin
    process(rs1, rs2, rs3, rd, rd_d) is 
    begin       
        if rd = rs1 then    
            forward <= '1'; rs1_d <= rd_d; rs2_d <= (others => '-'); rs3_d <= (others => '-');
        elsif rd = rs2 then
            forward <= '1'; rs1_d <= (others => '-'); rs2_d <= rd_d; rs3_d <= (others => '-');
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