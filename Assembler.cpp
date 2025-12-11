#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm> // For reverse
#include <cstdlib>

using namespace std;

string toBinary(int value, int bits) {
    string result = "";

    for (int i = 0; i < bits; i++) {
        if ((value >> i) & 1) {
            result += "1"; // Concatenating 1 if the bit at pos i is 1
        }
        else {
            result += "0";
        }
    }

    // Reverses string so LSB is placed on right
    reverse(result.begin(), result.end());
    return result;
}

string parseReg(string regName) {
    
    if (regName.length() < 2 || regName[0] != 'r') {
        
        return "00000";
    }

    string num = regName.substr(1); // removing the char 'r'
    int toNum = stoi(num);          // converts the string number to an int
    return toBinary(toNum, 5);      // 5 bits for 32 registers
}

int main() {
    ifstream inFile("assembly.txt");
    ofstream outFile("machine.txt");

    if (!inFile.is_open()) {
        cerr << "Error: Could not open 'assembly.txt'. Check if the file exists!" << endl;
        exit(1);
    }
    cout << "Input File opened successfully!" << endl;

    string op;

    while (inFile >> op) {
        string machine_line = "";
        string rs3_str, rs2_str, rs1_str, rd_str;

        //-----------------
        // Load Immediate
        //-----------------
        if (op == "li") {
            int index, imm;
            inFile >> rd_str >> imm >> index;

            machine_line += "0";
            machine_line += toBinary(index, 3);
            machine_line += toBinary(imm, 16);
            machine_line += parseReg(rd_str);
        }

        //-----------------
        // R4 Instruction Format
        //-----------------
        else if (op == "simals" || op == "simahs" || op == "simsls" || op == "simshs" ||
            op == "slimals" || op == "slimahs" || op == "slimsls" || op == "slimshs") {

            string instr;

            if (op == "simals")       instr = "000";
            else if (op == "simahs")  instr = "001";
            else if (op == "simsls")  instr = "010";
            else if (op == "simshs")  instr = "011";
            else if (op == "slimals") instr = "100";
            else if (op == "slimahs") instr = "101";
            else if (op == "slimsls") instr = "110";
            else if (op == "slimshs") instr = "111";

            inFile >> rd_str >> rs1_str >> rs2_str >> rs3_str;

            machine_line += "10";
            machine_line += instr;
            machine_line += parseReg(rs3_str);
            machine_line += parseReg(rs2_str);
            machine_line += parseReg(rs1_str);
            machine_line += parseReg(rd_str);
        }

        //-----------------
        // R3 Instruction Format
        //-----------------
        else {
            string opcode = "";
            // Check if 'op' is a recognized R3 instruction
            if (op == "nop" || op == "shrhi" || op == "au" || op == "cnt1h" ||
                op == "ahs" || op == "or" || op == "bcw" || op == "maxws" ||
                op == "minws" || op == "mlhu" || op == "mlhcu" || op == "and" ||
                op == "clzw" || op == "rotw" || op == "sfwu" || op == "sfhs")
            {
                if (op == "nop") {
                    machine_line = "1100000000000000000000000";
                    outFile << machine_line << endl;
                    continue; // Skip the write at the bottom
                }
                else if (op == "shrhi") opcode = "00000001";
                else if (op == "au")    opcode = "00000010";
                else if (op == "cnt1h") opcode = "00000011";
                else if (op == "ahs")   opcode = "00000100";
                else if (op == "or")    opcode = "00000101";
                else if (op == "bcw")   opcode = "00000110";
                else if (op == "maxws") opcode = "00000111";
                else if (op == "minws") opcode = "00001000";
                else if (op == "mlhu")  opcode = "00001001";
                else if (op == "mlhcu") opcode = "00001010";
                else if (op == "and")   opcode = "00001011";
                else if (op == "clzw")  opcode = "00001100";
                else if (op == "rotw")  opcode = "00001101";
                else if (op == "sfwu")  opcode = "00001110";
                else if (op == "sfhs")  opcode = "00001111";
            }
            else {
                // Catch any remaining token that isn't a known mnemonic
                cerr << "Error: Unknown instruction mnemonic or token '" << op << "' found." << endl;
                exit(1);
            }

            
            // If you have others (like 'bcw' or 'rotw') add them here
            if (op == "clzw" || op == "cnt1h") {
                inFile >> rd_str >> rs1_str;
                rs2_str = "r0"; // Dummy value for the missing 3rd register
            }
            else {
                // Standard 3-operand read
                inFile >> rd_str >> rs1_str >> rs2_str;
            }

            machine_line += "11";
            machine_line += opcode;

            if (op == "shrhi" || op == "mlhcu") {
                // It is a number, convert directly
                int imm_val = stoi(rs2_str);
                machine_line += toBinary(imm_val, 5);
            }
            else {
                // It is a register
                machine_line += parseReg(rs2_str);
            }

            machine_line += parseReg(rs1_str);
            machine_line += parseReg(rd_str);
        }

        
        outFile << machine_line << endl;
    }

    inFile.close();
    outFile.close();
    cout << "Assembly Complete!" << endl;
    return 0;
}
