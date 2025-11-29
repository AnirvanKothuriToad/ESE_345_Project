-------------------------------------------------------------------------------
--
-- Title       : CPU Test Bench
-- Design      : ProjectPartII
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
-- Description : Testbench for Structural CPU Unit
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--    and may be overwritten
--{entity {CPU_tb} architecture {behavioral}} 
library IEEE;
use IEEE.std_logic_1164.all;

-- 1. DEFINE THE PACKAGE RIGHT HERE
package CPU_Defs is
    type REG_FILE_ARRAY_TYPE is array (0 to 31) of std_logic_vector(127 downto 0);
end package CPU_Defs;

use work.CPU_Defs.all;	--PUT THESE IN CPU.vhd

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;             -- For file reading
use IEEE.std_logic_textio.all;  -- For file reading	
use work.CPU_Defs.all;
use work.all;
	
entity CPU_tb is
end CPU_tb;

architecture behavioral of CPU_tb is

--1) Define signals from CPU.vhd here 


	signal clk	: std_logic := '0';
	signal reset : std_logic := '0';
	
	--Loading signals
	signal write_enable	: std_logic := '0';
	signal load_addr : std_logic_vector(5 downto 0) := (others => '0');	 --Instruction buffer can store upto 64 instructions
	signal load_data : std_logic_vector(24 downto 0) := (others => '0'); --25 bit machine code
	
	signal cpu_reg_file : REG_FILE_ARRAY_TYPE;
	
	--MIGHT HAVE TO MODIFY THIS
	--Signals for creating Results.txt 
    -- Connects output from CPU to TB
	
    signal res_PC          : std_logic_vector(5 downto 0);    -- Current Program Counter
    signal res_Instruction : std_logic_vector(24 downto 0);   -- Current Instruction being Fetched
    signal res_ALU_Result  : std_logic_vector(127 downto 0);  -- Result from EXE stage
    
    -- Forwarding Control Signals (Traffic Cops for the ALU inputs)
    signal res_Forward_A   : std_logic_vector(1 downto 0);    -- MUX control for rs1
    signal res_Forward_B   : std_logic_vector(1 downto 0);    -- MUX control for rs2
    signal res_Forward_C   : std_logic_vector(1 downto 0);    -- MUX control for rs3
    
    -- Write Back Stage Info
    signal res_WB_Data     : std_logic_vector(127 downto 0);  -- What is actually being written to RegFile
    signal res_RegWrite    : std_logic;
	
	constant PER : time := 10ns;
begin
	
	UUT: entity CPU
		port map (
			clk => clk,
			reset => reset,	
			write_enable => write_enable,
			load_addr => load_addr,
			load_data => load_data,
			cpu_reg_file => cpu_reg_file,
			
			res_PC          => res_PC,
            res_Instruction => res_Instruction,
            res_ALU_Result  => res_ALU_Result,
            res_Forward_A   => res_Forward_A,
            res_Forward_B   => res_Forward_B,
            res_Forward_C   => res_Forward_C,
            res_WB_Data     => res_WB_Data,
            res_RegWrite    => res_RegWrite
			);
			
	-----------------------------------------------		
	-- CLOCK GENERATION
	-----------------------------------------------
	clock_gen: process
	begin
		clk <= '0';
		wait for PER/2;
		clk <= '1';
		wait for PER/2;
	end process;
	
	-----------------------------------------------
	--MAIN PROCESS: FILE READING AND EXTRACTION
	-----------------------------------------------
	sim: process
	
	file progFile : text; --Files created to store extracted data
	file exp_file : text;
	
	--variables for reading file
	variable instr_line : line; --Stores string version of the instruction code
	variable instr : std_logic_vector(24 downto 0); --binary format of instruction code
	
	variable exp_reg : std_logic_vector(127 downto 0); --Holds the 128 bit register value from expected.txt
	
	variable i : integer := 0; --Counter variable to store number of instructions read
	
	begin
		
		report "1: Loading Instruction Buffer......";
		
		--Putting CPU in reset state when loading Instruction buffer
		reset <= '1';
		write_enable <= '1';
		load_addr <= (others => '0');
		
		file_open(progFile, "machine.txt", read_mode); --Opening machine.txt file made by assembler in read mode
		i := 0; --Setting Counter to 0
		
		--Looping through file and loading to memory
		while not endfile(progFile) loop
			readline(progFile, instr_line);	  --Reading line and storing to instr_line
			read(instr_line, instr);		  --Storing instr_line into instruction vector
			
			--Driving CPU Inputs
			load_addr <= std_logic_vector(to_unsigned(i,6)); --Converting i to a 6 bit vector to obtain address
			load_data <= instr;
			
			wait for PER; --Allowing inputs to update 
			i := i+1; --moving to next address
		end loop;
		
		write_enable <= '0'; --Done writing to instruction buffer 
		
		
		---PROGRAM EXECUTION
		report "Running CPU";
		
		wait for PER*2;	 --Holding reset for 2 more cycles
		reset <= '0'; --CPU can start fetching since reset is disabled
		
		wait for 2000 ns; --Waiting for a long time to compute results 
			
	    --VERIFYING results with expected.txt
		report "Checking Expected Results File";
		
		file_open(exp_file, "expected.txt", read_mode);
		
		--Looping through register file 0-31
		for j in 0 to 31 loop
			if not endfile(exp_file) then
				readLine(exp_file, instr_line);
				hread(instr_line, exp_reg); --Reads hexadecimal values from expected file and stores intno expected register vector
				
				--Comparision between Computed and Expected register values
				if exp_reg /= cpu_reg_file(j) then
					report "Error: Register Mismatch " & integer'image(j) & ". Expected: " & to_hstring(exp_reg) --Reporting error along with expected value
					& " Computed: " & to_hstring(cpu_reg_file(j)) severity error;
				end if;
			end if;
		end loop;
		
		file_close(exp_file); 
	 end process;
	 
	 -----------------------------------------------
	 --RESULT Creating process(results.txt)
	 -----------------------------------------------
	 res: process(clk)
	 	file results_file : text;
	 	variable open_status : file_open_status;
        variable line_out : line;
        variable cycle_count : integer := 0;
        variable file_is_open : boolean := false; --Prevents overwriting result data
		
	begin
		--Opening the file and writing header
		if not file_is_open then
			file_open(open_status, results_file, "results.txt", write_mode); --Opening a new file in write mode
			file_is_open := true;
																																										 --Write Enable
			--Header
		    write(line_out, string'("Cycle |   PC   |        Instruction       | FwdA | FwdB | FwdC |            ALU Result            |          WriteBack Data          | WE"));
            writeline(results_file, line_out);
            write(line_out, string'("-------------------------------------------------------------------------------------------------------------------------------------------------"));
            writeline(results_file, line_out);
        end if;
		
		if falling_edge(clk) then --Updating results file when signals are stable
			if reset = '0'then --Making sure to update only when reset is disabled
				
				--C1: Cycle Count
				write(line_out, cycle_count, right, 5);
				write(line_out, string'(" | "));
				
				--C2: PC in Hexa
				hwrite(line_out, res_PC, right, 6);
				write(line_out, string'(" | "));
				
				--C3: Instruction bits in Binary
				write(line_out, res_Instruction);
				write(line_out, string'(" | "));
				
				--C4: Forwarding Unit for rs1
				write(line_out, res_Forward_A);
				write(line_out, string'(" | "));
				write(line_out, res_Forward_B);
				write(line_out, string'(" | "));
				write(line_out, res_Forward_C);
				write(line_out, string'(" | "));
				
				--C5: ALU Result in Hexa
				write(line_out, res_ALU_Result);
				write(line_out, string'(" | "));
				
				--C6: Write Back Data in Hexa
				write(line_out, res_WB_data);
				write(line_out, string'(" | "));
				
				--C7: Write Enable
				if write_enable = '1' then
					write(line_out, string'(" 1 "));
				else
					write(line_out, string'(" 1 "));
				end if;
				
				--Save the Line to the results file
				
				writeLine(results_file, line_out); 
				cycle_count := cycle_count + 1;
			end if;
		end if;
	
		report "===================================";
        report "   SIMULATION COMPLETE ";
        report "===================================";
        
        std.env.finish; -- Stop simulation
        
    end process;

end behavioral;

				
				
				
	
	



