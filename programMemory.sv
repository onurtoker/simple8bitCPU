`timescale 1ns / 1ps

module programMemory(
    input logic [9:0] addr,
    output logic [13:0] d_out,
    input logic reset
);
    
logic [13:0] data_ROM [0:1023];
logic [13:0] d_rom;

/*
// simulation only. Not OK for synthesis
initial 
    $readmemh("rom.data", data_ROM);
    
assign d_out = (reset) ? 0 : data_ROM[addr];    
*/

// ROM device as program memory
always_comb
begin
    case (addr)
    
        10'h0: d_rom    = 14'b11_0000_0000_0000; // nop                 ; reset vector
        10'h1: d_rom    = 14'b11_0000_0001_0010; // mov r2, 1
        10'h2: d_rom    = 14'b11_0000_0001_0011; // mov r3, 1
        10'h3: d_rom    = 14'b11_0100_0010_0011; // add r3, r2
        10'h4: d_rom    = 14'b00_0100_0000_0100; // halt
        
        default: d_rom  = 14'b00_0000_0000_0000; // all other addresses of the ROM
    endcase
end
    
assign d_out = (reset === 1) ? 0 : d_rom;    
    
endmodule    
