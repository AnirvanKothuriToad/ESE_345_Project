#include <iostream>
using namespace std;
#include <fstream>
#include <string>
#include <vector>
#include <algorithm> // For reverse


string toBinary(int value, int bits) {
	string result = "";

	for (int i = 0; i < bits; i++) {
		
		if ((value >> i) & 1) {
			result += "1"; //Concactenating 1 if the bit at pos i is 1
		}
		else {
			result += "0";
		}
	}

	//Reverses string to LSB is placed on right
	reverse(result.begin(), result.end());
	return result;
}

string parseReg(string regName) {
	string num = regName.substr(1); //removing the char r from register name to obtain number.

	int toNum = stoi(num); //converts the string number to an int type

	return toBinary(toNum, 5);   //Converting register number to binary. # bits = 5 because there are 32 registers
}

int main() {
	ifstream inFile("assembly.txt");
	ofstream outFile("machine.txt");

	if (!inFile.is_open()) {
		// If NOT open, print an error and stop the program
		cerr << "Error: Could not open 'prog.asm'. Check if the file exists!" << endl;
		exit(1); 
	}
	cout << "Input File opened successfully!" << endl;

	string op; //Stores what operator is being performed. ex: add, nop, li, au.....

	while (inFile >> op) {
		string machine_line;
		string rs3_str, rs2_str, rs1_str, rd_str; //Strings to store source and destination registers
		
		//-----------------
		//Load Immediate
		//-----------------

		if (op == "li") {
			int index, imm; //variables to store load index and immediate value

			inFile >> rd_str >> imm >> index; //reading values from input file

			//building machine_line based on instruction
			machine_line += "0";
			machine_line += toBinary(index, 3); //converting index to 3 bit binary and concactenating 
			machine_line += toBinary(imm, 16);  //16 bit immediate value
			machine_line += parseReg(rd_str);   //Destination register
		}

		//-----------------
		//R4 Instruction Format
		//-----------------

		else if (op == "simals" || op == "simahs" || op == "simsls" || op == "simshs" ||
			op == "slimals" || op == "slimahs" || op == "slimsls" || op == "slimshs") {
			string instr; //variable to store instruction bits for R4 Operations

			if (op == "simals") {    //Signed Integer Multiply-Add Low with Saturation
				instr = "000";
			}

			else if (op == "simahs") {    //Signed Integer Multiply-Add High with Saturation
				instr = "001";
			}

			else if (op == "simsls") {    //Signed Integer Multiply-Subtract Low with Saturation
				instr = "010";
			}

			else if (op == "simshs") {    //Signed Integer Multiply-Subtract High with Saturation
				instr = "011";
			}

			else if (op == "slimals") {    //Signed Long Integer Multiply - Add Low with Saturation
				instr = "100";
			}

			else if (op == "slimahs") {    //Signed Long Integer Multiply - Add High with Saturation
				instr = "101";
			}

			else if (op == "slimsls") {    //Signed Long Integer Multiply - Subtract Low with Saturation
				instr = "110";
			}

			else if (op == "slimshs") {    //Signed Long Integer Multiply - Subtract High with Saturation 
				instr = "111";
			}

			inFile >> rd_str >> rs1_str >> rs2_str >> rs3_str; //Reading all register values for R4 Format

			//building machine_line
			machine_line += "01";
			machine_line += instr;
			machine_line += parseReg(rs3_str);
			machine_line += parseReg(rs2_str);
			machine_line += parseReg(rs1_str);
			machine_line += parseReg(rd_str);

		}

		//-----------------
		//R3 Instruction Format
		//-----------------

		else { //assuming any other instruction is an R3 Instruction

			string opcode = ""; //variable to store 8 bit opcode variable
			if (op == "nop") {
				machine_line = "1100000000000000000000000";
				outFile << machine_line << endl;
				continue;
			}
			else if (op == "shri") {
				opcode = "00000001";
			}

			else if (op == "au") {
				opcode = "00000010";
			}

			else if (op == "cnt1h") {
				opcode = "00000011";
			}

			else if (op == "ahs") {
				opcode = "00000100";
			}

			else if (op == "or") {
				opcode = "00000101";
			}

			else if (op == "bcw") {
				opcode = "00000110";
			}

			else if (op == "maxws") {
				opcode = "00000111";
			}

			else if (op == "minws") {
				opcode = "00001000";
			}

			else if (op == "mlhu") {
				opcode = "00001001";
			}

			else if (op == "mlhcu") {
				opcode = "00001010";
			}

			else if (op == "and") {
				opcode = "00001011";
			}

			else if (op == "clzw") {
				opcode = "00001100";
			}

			else if (op == "rotw") {
				opcode = "00001101";
			}

			else if (op == "sfwu") {
				opcode = "00001110";
			}

			else if (op == "sfhs") {
				opcode = "00001111";
			}

			inFile >> rd_str >> rs1_str >> rs2_str; //Reading all register values for R3 Format

			//Building machine_line
			machine_line += "11";
			machine_line += opcode;
			machine_line += parseReg(rs2_str);
			machine_line += parseReg(rs1_str);
			machine_line += parseReg(rd_str);
		}

		//Writing Machine Code Line to Output File
		outFile << machine_line << endl;
	}

	inFile.close();
	outFile.close();
	cout << "Assembly Complete!" << endl;
	return 0;
}


