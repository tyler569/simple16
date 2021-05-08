
// 
// Simple
//
// A CPU
//
// word / byte / address: 16 bit
//
// 16 registers; r0 aleays read 0
// 2op addressing
//
// instruction formats:
// 0000 0000 oppp drrr      // 1op - 0 is invalid
// 0000 oppp drrr srrr      // 2op - 0 is invalid
// 0001 cccc rrrr 0000      // cjmp to r   if c
// 0001 cccc rrrr 0001      // cjmp to [r] if c
// 0001 cccc 0000 0010  N   // cjmp abs N  if c
// 0010 oppp drrr ivvv      // 2op immidiate
// 0011 cccc ivvvvvvv       // cjmp relative +-127 if c
// 0100 drrr arrr orrr      // load [a + o] to d
// 0101 drrr arrr orrr      // store d to [a + o]
// 0110
// 0111
// 1000 drrr ivvvvvvv       // load immidiate v to d
// 1001 rrrr 00000000   N   // load immidiate N in next word to r
// 1010                     // free
// 1011 drrr srrr dp sp     // move s to d from pages (see below)
// 1100
// 1101
// 1110
// 1111
//
// register pages:
//    0   1   2   3   4   5   6   7   [...]
// 0: r0  r1  r2  r3  r4  r5  r6  r7  ...
// 1: ip  fl  [reserved...]
// 2: reserved
// 3: reserved
// every instruction except mov (1001) always uses page 0
//
// 2ops:
// 0000 - invalid / trap
// 0001 - add
// 0010 - sub
// 0011 - or
// 0100 - nor
// 0101 - and
// 0110 - nand
// 0111 - xor
// 1000 - xnor
// 1001 - adc
// 1010 - sbb
// 1011 - cmp (sub, but no commit)
// <rest> - reserved
//
// 1ops:
// 0000 - not
// 0001 - inv (2s comp invert)
// 0010 - push (r15 as sp)
// 0011 - pop  (r15 as sp)
// 0100 - inc
// 0101 - dec
//   thoughts:
//   int, syscall, msr?
//

module SimpleALU(a, b, op, flags, out, flags_out);
    input[15:0] a, b;
    input[3:0] op;
    input[15:0] flags;

    reg[16:0] acc = 0;

    output[15:0] out;
    output[15:0] flags_out;

    wire of, cf, zf, sf;
    reg ef = 0;

    assign zf = acc[15:0] == 0;
    assign cf = acc[16];
    assign sf = acc[15];
    assign of = acc[16:15] == 2'b01;

    assign out = op == 4'b1011 ? a : acc[15:0];
    assign flags_out = {ef, 11'd0, sf, of, cf, zf};

    always @(*) begin
        case (op)
        4'b0001: acc = a + b;            // add
        4'b0010: acc = a - b;            // sub
        4'b0011: acc = a | b;            // or
        4'b0100: acc = ~(a | b);         // nor
        4'b0101: acc = a & b;            // and
        4'b0110: acc = ~(a & b);         // nand
        4'b0111: acc = a ^ b;            // xor
        4'b1000: acc = ~(a ^ b);         // xnor
        4'b1001: acc = a + b + flags[1]; // adc
        4'b1010: acc = a - b - flags[1]; // sbb
        4'b1011: acc = a - b;            // cmp
        default: ef = 1;
        endcase
    end
endmodule

// `define RAM_DEBUG

module SimpleRAM(clock, address, data, we, oe);
    parameter SIZE = 2048;

    input clock;
    input[15:0] address;
    input we;
    input oe;

    inout[15:0] data;

    reg[7:0] memory [0:SIZE-1];
    reg[15:0] read;

    // tristate control
    assign data = (address < 16'h0fff && oe && !we) ? read : 16'bz;

    always @ (posedge clock) begin
        if (address < 16'h0FFF && we) begin
            `ifdef RAM_DEBUG
                $display("time: %t, RAM: writing %b to %d",
                    $time, data, address);
            `endif
            memory[address] <= data[15:8];
            memory[address+1] <= data[7:0];
        end
    end

    always @ (posedge clock) begin
        if (address < 16'h1000 && !we && oe) begin
            read[15:8] <= memory[address];
            read[7:0] <= memory[address+1];
            `ifdef RAM_DEBUG
                $display("time: %t, RAM: reading %d: got %b",
                    $time, address, read);
            `endif
        end
    end

    integer k;
    initial begin
        $display("initializing RAM");
        for (k = 0; k < SIZE; k = k + 1)
            memory[k] = 16'h0000;

        $readmemh("test.mem", memory);
    end
endmodule

// `define INSTR_DEBUG

module SimpleCPU(clock, int, reset, address_bus, ram_write, data_bus);
    input clock;
    input int;
    input reset;

    output reg[15:0] address_bus = 0;
    inout[15:0] data_bus;
    output reg ram_write = 0;

    reg[15:0] alu_a;
    reg[15:0] alu_b;
    reg[3:0] alu_op;
    reg[15:0] alu_flags;
    wire[15:0] alu_flags_out;
    wire[15:0] alu_out;

    reg[15:0] pc;
    reg[15:0] int_vec;

    reg[15:0] instruction;
    reg[2:0] instruction_stage = 0;
    reg next_instr = 1;

    reg[15:0] registers [15:0];
    reg[15:0] flags = 0;

    reg[15:0] data_out_buffer;

    assign data_bus = ram_write ? data_out_buffer : 16'bz;

    SimpleALU alu(alu_a, alu_b, alu_op, alu_flags, alu_out, alu_flags_out);

    always @ (posedge reset) begin
        registers[0] <= 0;
        registers[1] <= 0;
        registers[2] <= 0;
        registers[3] <= 0;
        registers[4] <= 0;
        registers[5] <= 0;
        registers[6] <= 0;
        registers[7] <= 0;
        registers[8] <= 0;
        registers[9] <= 0;
        registers[10] <= 0;
        registers[11] <= 0;
        registers[12] <= 0;
        registers[13] <= 0;
        registers[14] <= 0;
        registers[15] <= 0;

        pc <= 0;
        address_bus <= 0;
        int_vec <= 0;
        next_instr <= 1;
    end

    reg do_jump = 0;
    reg[15:0] jump_to = 0;

    `define ZF flags[0]
    `define CF flags[1]
    `define OF flags[2]
    `define SF flags[3]

    always @ (posedge clock) begin
        if (next_instr) begin
            instruction = data_bus;
        end
        
        casez ({instruction_stage, instruction})
        19'b0000000000000000000: begin
            $display("0 stop");
            $finish;
        end

        19'b00000000000????????: begin
            `ifdef INSTR_DEBUG
                $display("1op: unimplemented");
            `endif
        end

        19'b0000000????????????: begin
            `ifdef INSTR_DEBUG
                $display("2op: %b, rd: %b, rs: %b",
                    instruction[11:8], instruction[7:4], instruction[3:0]);
            `endif
            alu_op <= instruction[11:8];
            alu_a <= registers[instruction[7:4]];
            alu_b <= registers[instruction[3:0]];
            instruction_stage <= 1;
            next_instr = 0;
        end
        19'b0010000????????????: begin
            registers[instruction[7:4]] <= alu_out;
            flags <= alu_flags_out;
            next_instr = 1;
        end

        19'b00000010000????????: begin
            `ifdef INSTR_DEBUG
                $display("cjmp: %b, to: (r%0d)",
                    instruction[7:4], instruction[3:0]);
            `endif
            jump_to = registers[instruction[3:0]];

            // $display("IN JUMP: zf: %b, cf: %b, of: %b, sf: %b",
            //     flags[0], flags[1], flags[2], flags[3]);

            case (instruction[7:4])
            // ja / jnbe
            4'b0001: if (~`ZF && ~`CF) do_jump = 1;
            // jae / jnb / jnc
            4'b0010: if (~`CF) do_jump = 1;
            // jb / jnae / jc
            4'b0011: if (`CF) do_jump = 1;
            // jbe / jna
            4'b0100: if (`CF || `ZF) do_jump = 1;
            // jg / jnle
            4'b0101: if (~`ZF && `SF == `OF) do_jump = 1;
            // jge / jnl
            4'b0110: if (`SF == `OF) do_jump = 1;
            // jl / jnge
            4'b0111: if (`SF != `OF) do_jump = 1;
            // jle / jng
            4'b1000: if (~`ZF || `SF != `OF) do_jump = 1;
            // jeq
            4'b1001: if (`ZF) do_jump = 1;
            // jne
            4'b1010: if (~`ZF) do_jump = 1;
            // jo
            4'b1011: if (`OF) do_jump = 1;
            // jno
            4'b1100: if (~`OF) do_jump = 1;
            // jmp
            4'b1101: do_jump = 1;
            // unassigned
            4'b1110: do_jump = 0;
            4'b1111: do_jump = 0;
            endcase
        end

        19'b0000001????????????: begin
            `ifdef INSTR_DEBUG
                $display("cjmp: %b, to: pc + %0d",
                    instruction[11:8], $signed({{8{instruction[7]}}, instruction[7:0]}));
            `endif
            jump_to = pc + {{8{instruction[7]}}, instruction[7:0]};

            // $display("IN JUMP: zf: %b, cf: %b, of: %b, sf: %b",
            //     flags[0], flags[1], flags[2], flags[3]);

            case (instruction[11:8])
            // ja / jnbe
            4'b0001: if (~`ZF && ~`CF) do_jump = 1;
            // jae / jnb / jnc
            4'b0010: if (~`CF) do_jump = 1;
            // jb / jnae / jc
            4'b0011: if (`CF) do_jump = 1;
            // jbe / jna
            4'b0100: if (`CF || `ZF) do_jump = 1;
            // jg / jnle
            4'b0101: if (~`ZF && `SF == `OF) do_jump = 1;
            // jge / jnl
            4'b0110: if (`SF == `OF) do_jump = 1;
            // jl / jnge
            4'b0111: if (`SF != `OF) do_jump = 1;
            // jle / jng
            4'b1000: if (~`ZF || `SF != `OF) do_jump = 1;
            // jeq
            4'b1001: if (`ZF) do_jump = 1;
            // jne
            4'b1010: if (~`ZF) do_jump = 1;
            // jo
            4'b1011: if (`OF) do_jump = 1;
            // jno
            4'b1100: if (~`OF) do_jump = 1;
            // jmp
            4'b1101: do_jump = 1;
            // unassigned
            4'b1110: do_jump = 0;
            4'b1111: do_jump = 0;
            endcase
        end

        19'b0000010????????????: begin
            `ifdef INSTR_DEBUG
                $display("2opi: %b, rd: %b, imm: %b",
                    instruction[11:8], instruction[7:4], instruction[3:0]);
                $display("UNFINISHED NEED TO CHANGE TO IMM = 2^IMM");
            `endif
            alu_op <= instruction[11:8];
            alu_a <= registers[instruction[7:4]];
            alu_b <= instruction[3:0];
            instruction_stage <= 1;
            next_instr = 0;
        end
        19'b0010010????????????: begin
            registers[instruction[7:4]] <= alu_out;
            flags <= alu_flags_out;
            next_instr = 1;
        end

        19'b0000011????????????: begin
            $display("unused space");
        end

        19'b0000100????????0000: begin
            `ifdef INSTR_DEBUG
                $display("ld r%0d, [r%0d]", instruction[11:8], instruction[7:4]);
            `endif
            address_bus <= registers[instruction[7:4]];
            instruction_stage <= 1;
            next_instr = 0;
        end
        19'b0010100????????0000: begin
            registers[instruction[11:8]] <= data_bus;
            next_instr = 1;
        end

        19'b0000101????????0000: begin
            `ifdef INSTR_DEBUG
                $display("st [r%0d], r%0d", instruction[7:4], instruction[11:8]);
            `endif
            address_bus <= registers[instruction[7:4]];
            data_out_buffer <= registers[instruction[11:8]];
            ram_write <= 1;
            instruction_stage <= 1;
            next_instr = 0;
        end
        19'b0010101????????0000: begin
            ram_write <= 0;
            next_instr = 1;
        end

        19'b0000110????????????: begin
            `ifdef INSTR_DEBUG
                $display("ldo r%0d, [r%0d + r%0d]",
                    instruction[11:8], instruction[7:4], instruction[3:0]);
            `endif
            address_bus <= 
                registers[instruction[7:4]] + registers[instruction[3:0]];
            instruction_stage <= 1;
            next_instr = 0;
        end
        19'b0010110????????????: begin
            registers[instruction[11:8]] <= data_bus;
            next_instr = 1;
        end

        19'b0000111????????????: begin
            `ifdef INSTR_DEBUG
                $display("sto [r%0d + r%0d], r%0d",
                    instruction[7:4], instruction[3:0], instruction[11:8]);
            `endif
            address_bus <= 
                registers[instruction[7:4]] + registers[instruction[3:0]];
            data_out_buffer <= registers[instruction[11:8]];
            ram_write <= 1;
            instruction_stage <= 1;
            next_instr = 0;
        end
        19'b0010111????????????: begin
            ram_write <= 0;
            next_instr = 1;
        end

        19'b0001000????????????: begin
            `ifdef INSTR_DEBUG
                $display("ldi r%0d, %b",
                    instruction[11:8], {{8{instruction[7]}}, instruction[7:0]});
            `endif
            registers[instruction[11:8]] = 
                {{8{instruction[7]}}, instruction[7:0]}; // sign extend
        end

        19'b0001001????00000000: begin
            `ifdef INSTR_DEBUG
                $display("ldil r%0d, <N>", instruction[11:8]);
            `endif
            address_bus <= pc + 2;
            instruction_stage <= 1;
            next_instr = 0;
        end
        19'b0011001????00000000: begin
            registers[instruction[11:8]] = data_bus;
            pc = pc + 2;
            next_instr = 1;
        end

        19'b0001010????????0000: begin
            $display("unused space");
        end

        19'b0001011????????????: begin
            `ifdef INSTR_DEBUG
                $display("mov %0d:r%0d, %0d:r%0d",
                    instruction[3:2], instruction[11:8],
                    instruction[1:0], instruction[7:4]);
            `endif
            if (instruction[3:0] != 0)
                $display("alternate register pages are todo");
            registers[instruction[11:8]] = registers[instruction[7:4]];
        end

        // 19'b000111100000000????:
        //     $display("r%0d: %b",
        //         instruction[3:0], registers[instruction[3:0]]);
        // 19'b000111100000001????:
        //     $display("r%0d: %x",
        //         instruction[3:0], registers[instruction[3:0]]);
        // 19'b000111100000010????:
        //     $display("r%0d: %0d",
        //         instruction[3:0], registers[instruction[3:0]]);

        default: begin
            $display("error, unsupported op/stage %b",
                {instruction_stage, instruction});
            next_instr = 1;
        end
        endcase

        if (next_instr) begin
            instruction_stage <= 0;
            if (do_jump) begin
                pc <= jump_to;
                address_bus <= jump_to;
                do_jump <= 0;
            end else begin
                pc <= pc + 2;
                address_bus <= pc + 2;
            end
        end
    end

    // check flags[3] and jmp to interrupt if set

    initial begin
        // $monitor("a: %b, b: %b, | out: %b, flags: %b", 
        //     alu_a, alu_b, alu_out, alu_flags_out);
    end
endmodule

module SimpleDebug(clock, address_bus, ram_write, data_bus);
    input clock;
    input[15:0] address_bus;
    input ram_write;
    input[15:0] data_bus;

    always @ (posedge clock) begin
        if (ram_write) begin
            case (address_bus)
            16'hFF01:
                $display("out: %0d", data_bus);
            16'hFF02:
                $display("out: %h", data_bus);
            16'hFF03:
                $display("out: %b", data_bus);
            endcase
        end
    end
endmodule

module main;
    wire[15:0] address_bus;
    wire[15:0] data_bus;
    wire ram_write;

    reg clock_enable = 0;
    reg main_clk = 0;

    always #5 main_clk = ~main_clk;

    wire ram_clock, cpu_clock;

    and (ram_clock, clock_enable, main_clk);
    and #(2, 2) (cpu_clock, clock_enable, main_clk);

    pullup pd_addr[15:0] (address_bus); 
    pullup pd_data[15:0] (data_bus);

    SimpleRAM ram0(ram_clock, address_bus, data_bus, ram_write, ~ram_write);

    reg hw_int = 0;
    reg hw_reset = 0;

    SimpleCPU cpu0(cpu_clock, hw_int, hw_reset, address_bus, ram_write, data_bus);

    SimpleDebug sd0(ram_clock, address_bus, ram_write, data_bus);

    initial begin
        hw_reset <= 1;
        #2 hw_reset <= 0;
        #13 clock_enable <= 1;

        // $monitor("time: %t, clk: %b, addr: %b, data: %b",
        //     $time, cpu_clock, address_bus, data_bus);
    end
endmodule

