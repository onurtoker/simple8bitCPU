`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// http://www.epyme.uva.es/Docs/Public/Conferences/FPGAworld2006a.pdf
//////////////////////////////////////////////////////////////////////////////////

module RISCuva0 ( clk, reset,
 				  progAddress, progData, progReset,
 				  dataIn, dataOut,
				  portAddress, portRead, portWrite,
 				  intReq, intAck );

	// Inputs and outputs:
	input 	clk, reset; 		// Clock and Reset
	
	output [9:0] progAddress; 	// Up to 1K instructions (10 bits)
	input [13:0] progData; 		// Current instruction code
	output progReset; 			// Reset of Program Memory
	
	input [7:0] dataIn; 		// Data input (from an I/O port)
	output [7:0] dataOut; 		// Data output (through a port)
	
	output [7:0] portAddress; 	// Addressed I/O Port (0..255)
	output portRead; 			// Read signal
	output portWrite; 			// Write signal
	input intReq; 				// Interrupt request
	output intAck; 				// Interrupt Acknowledge
	
	// Instruction decoding from the instruction code:
	logic [13:0] opCode; 	
	logic [1:0] opA; 
	logic [1:0] opB;
	logic [1:0] opC;
	logic [3:0] rM;
	logic [3:0] rN;
	logic [9:0] immAddr;
	logic [7:0] immData;
	logic [4:0] immPort;
    logic MISC,JP,LOAD,ALU,CALL,GOTO,RETS,MOVOUT,RETN,RETI;
	logic DI,EI,FLAG_Z,FLAG_NZ,FLAG_C,FLAG_NC,LOGIX,ARITH;
	logic SHIFT,MOVIN,MOV,XNOR,OR,AND,ADD,ADC,SUB,SBC,ASR;
	logic RRC,ROR,ROL,IND,SEQ,DIR; 

	assign opCode = progData; 	// Instruction code
	assign opA = opCode[13:12]; // 1st operation code
	assign opB = opCode[11:10]; // 2nd operation code
	assign opC = opCode[ 9: 8]; // 3rd operation code
	assign rM = opCode[ 7: 4]; 	// Source register
	assign rN = opCode[ 3: 0]; 	// Destination register
	assign immAddr = opCode[ 9:0]; // Address for jumps
	assign immData = opCode[11:4]; // Immediate data
	assign immPort = opCode[ 8:4]; // For direct access
	
	
assign MISC = (opA == 2'b00);
	assign JP = (opA == 2'b01);
	assign LOAD = (opA == 2'b10);
	assign ALU = (opA == 2'b11);
		
	assign CALL = (opB == 2'b00);
	assign GOTO = (opB == 2'b01);
	assign RETS = (opB == 2'b10);
	assign MOVOUT = (opB == 2'b11);
	
	assign RETN = (opC == 2'b00);
	assign RETI = (opC == 2'b01);
	assign DI = (opC == 2'b10);
	assign EI = (opC == 2'b11);
	
	assign FLAG_Z = (opB == 2'b00);
	assign FLAG_NZ = (opB == 2'b01);
	assign FLAG_C = (opB == 2'b10);
	assign FLAG_NC = (opB == 2'b11);
	
	assign LOGIX = (opB == 2'b00);
	assign ARITH = (opB == 2'b01);
	assign SHIFT = (opB == 2'b10);
	assign MOVIN = (opB == 2'b11);
	
	assign MOV = (opC == 2'b00);
	assign XNOR = (opC == 2'b01);
	assign OR = (opC == 2'b10);
	assign AND = (opC == 2'b11);
	
	assign ADD = (opC == 2'b00);
	assign ADC = (opC == 2'b01);
	assign SUB = (opC == 2'b10);
	assign SBC = (opC == 2'b11);
	
	assign ASR = (opC == 2'b00);
	assign RRC = (opC == 2'b01);
	assign ROR = (opC == 2'b10);
	assign ROL = (opC == 2'b11);
	
	assign IND = (opC == 2'b00);
	assign SEQ = (opC == 2'b01);
	assign DIR = (opC >= 2'b10); 
	
	// General Resources:
	reg zeroFlag, carryFlag; 				// DFFs used by flags
	logic [7:0] dataBus; 					// Data bus for all operations
	logic [2+9:0] stackValue; 				// Internal stack output
	
	// Register file (r0-r15) and operand buses: 
	reg [7:0] registerFile[0:15]; 			// 16x8 dual-port memory
	always@(posedge clk)
	begin
	    if (reset)
	    begin
	       registerFile[0] <= 0;
	       registerFile[1] <= 1;
	    end   
		else if (LOAD | ALU)
			registerFile[rN] <= dataBus; 	// Synchronous write
	end
	logic [7:0] busN;
	assign busN = registerFile[rN]; 	// Async. read of rN
	logic [7:0] busM;
	assign busM = registerFile[rM]; 	// Async. read of rM
	
	// Port signals for direct, indirect and sequential accesses: 
	reg [7:0] nextPort;
	always@(posedge clk)
	begin
		if (portRead | portWrite)
			nextPort <= portAddress + 1; 	// For sequential use
	end
	assign dataOut = busN; 					// Output from rN
	assign portRead = ALU & MOVIN; 			// Read signal
	assign portWrite = MISC & MOVOUT; 		// Write signal
	assign portAddress = IND ? busM : 		// Indirect
						 SEQ ? nextPort :	// Sequent.
							   {3'b111,immPort}; // Direct
	
	// Logic ALU: AND, OR, XNOR and MOV.
	logic logicCarry;
	assign logicCarry = AND ? 1'b1 : OR ? 1'b0 : carryFlag;
	logic [7:0] logicALU;
	assign logicALU = AND ? busN & busM :
						  OR ?  busN | busM :
						  XNOR ? busN ~^ busM :
									 	 busM ; 

	// Arithmetic ALU: ADD, ADC, SUB and SBC.
	logic [7:0] arithALU, altM;
	logic arithCarry, x, y, z;
	assign x = ADD ? 1'b0 : ADC ? carryFlag :
			   SUB ? 1'b1 : ~carryFlag;
	assign altM = (SUB | SBC) ? ~busM : busM;
	assign {z, arithALU, y} = {busN, 1'b1} + {altM, x};
	assign arithCarry = (SUB | SBC) ? ~z : z; 
	
	// Shifter: ASR, RRC, ROR and ROL. 
	logic [7:0] shiftALU;
	logic shiftCarry;
	assign {shiftALU, shiftCarry} =
						ASR ? {busN[7], busN} :
						RRC ? {carryFlag, busN} :
						ROR ? {busN[0], busN} :
							  {busN[6:0], busN[7], busN[7]};
	
	// This data bus collects results from all sources:
	always_comb
	begin
        dataBus = 8'b0;
        dataBus = ((LOAD | MISC) == 1)          ? immData   : dataBus;
        dataBus = (((ALU | JP) & LOGIX) == 1)   ? logicALU  : dataBus;
        dataBus = (((ALU | JP) & ARITH) == 1)   ? arithALU  : dataBus;
        dataBus = (((ALU | JP) & SHIFT) == 1)   ? shiftALU  : dataBus;
        dataBus = (((ALU | JP) & MOVIN) == 1)   ? dataIn    : dataBus;         
	end
	// Interrupt Controller:
	logic userEI, callingIRQ, intAck;
	logic mayIRQ;
	assign mayIRQ = ! (MISC & RETS
				  | MISC & MOVOUT
				  | ALU & MOVIN);
	logic validIRQ;
	assign validIRQ = intReq & ~intAck & userEI & mayIRQ;
	logic [9:0] destIRQ;
	assign destIRQ = callingIRQ ? 10'h001 : 10'h000;
	always@(posedge clk)
	begin
		if (reset) 					 userEI <= 0;
		else if (MISC & RETS & DI)   userEI <= 0;
		else if (MISC & RETS & EI)   userEI <= 1;
		
		if (reset) 					 intAck <= 0;
		else if (validIRQ) 			 intAck <= 1;
		else if (MISC & RETS & RETI) intAck <= 0;
		
		if (reset) 					 callingIRQ <= 0;
		else 						 callingIRQ <= validIRQ;
	end

	// Flag DFFs:
	always@(posedge clk)
	begin
		if (MISC & RETS & RETI) 	// Flags recovery 
			{carryFlag,zeroFlag} <= stackValue[11:10];
		else begin
			if (LOAD | ALU) // 'Z' changes with registers
				zeroFlag <= (dataBus == 8'h00);
			if (ALU & ~MOVIN) // but 'C' only with ALU ops
				carryFlag <= LOGIX ? logicCarry :
							 SHIFT ? shiftCarry :
									 arithCarry ;
		end
	end

	// 'validFlag' evaluates one of four conditions for jumps.
	logic validFlag;
	assign validFlag = FLAG_Z ?   zeroFlag :
				 	 FLAG_NZ ? ~zeroFlag :
					 FLAG_C ?  carryFlag :
							  ~carryFlag ; 
	
	// Program Counter (PC): the address of current instruction.
	logic [9:0] PC;
	logic [9:0] nextPC, incrPC;
	logic onRet;
	assign onRet = MISC & RETS & (RETN | RETI);
	logic onJump;
	assign onJump = MISC & (GOTO | CALL) | JP & validFlag;
	assign incrPC = PC + (callingIRQ ? 0 : 1);
	
	always_comb
	begin
	   nextPC = 10'b0;
	   nextPC = (!(onRet == 1) | !(onJump == 1))      ? incrPC : nextPC;
	   nextPC = (onRet == 1)                          ? stackValue[9:0]    : nextPC;
       nextPC = (onJump == 1)                         ? immAddr | destIRQ : nextPC;
	end
	
	always@(posedge clk)
	begin
        if (reset)
            PC <= 0;
        else
            PC <= nextPC;
    end

	// When using Xilinx BlockRAM as program memory:
	assign progAddress = nextPC;
	assign progReset = (reset == 1) ? 1 : validIRQ; 

	// Internal stack for returning addresses (16 levels):
	logic [3:0] SP; // Stack Pointer register
	always@(posedge clk)
	begin
		if (reset) 							SP <= 0;
		else if (MISC & CALL) 				SP <= SP + 1;
		else if (MISC & RETS & (RETN|RETI)) SP <= SP - 1;
	end
	logic [3:0] mySP;
	assign mySP = (CALL | GOTO) ? SP : SP - 1;

	logic [2+9:0] stackMem[0:15]; 		// Stack 16x12 memory
	always@(posedge clk)
	begin
		if (MISC & CALL) // Keep returning address and flags
			stackMem [mySP] <= {carryFlag, zeroFlag, incrPC};
	end

	assign stackValue = stackMem[mySP]; 
endmodule 	/// RISCuva1 (all in one file!)