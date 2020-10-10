`timescale 1ns / 1ps

module mySystem(

    );

logic progReset0;
logic [13:0] progData0;
logic [9:0] progAddress0;

RISCuva0 U0(
    .clk(clk), .reset(reset),
    .progAddress(progAddress0), 
    .progData(progData0), 
    .progReset(progReset0),
    //.dataIn(dataIn), .dataOut(dataOut),
    //.portAddress(portAddress), 
    //.portRead(portRead), .portWrite(portWrite),
    .intReq(1'b0), .intAck());

programMemory U0m(
    .addr(progAddress0),
    .d_out(progData0),
    .reset(progReset0));    

logic clk;
always
begin
   clk = 0; #(5);
   clk = 1; #(5);
end

logic reset;
initial
begin
  reset = 1; 
  #(11); reset = 0;
  $display("Reset applied") ;
  
  #(100);  
  $stop;
end

endmodule

//logic progReset, portRead, portWrite;
//logic [13:0] progData;
//logic [9:0] progAddress;
//logic [7:0] dataIn, dataOut, portAddress;

//logic progReset1;
//logic [13:0] progData1;
//logic [9:0] progAddress1;
//
//RISCuva1 U1(
//    .clk(clk), .reset(reset),
//    .progAddress(progAddress1), 
//    .progData(progData1), 
//    .progReset(progReset1),
//    //.dataIn(dataIn), .dataOut(dataOut),
//    //.portAddress(portAddress), 
//    //.portRead(portRead), .portWrite(portWrite),
//    .intReq(1'b0), .intAck());
//
//programMemory U1m(
//    .addr(progAddress1),
//    .d_out(progData1),
//    .reset(progReset1));    
