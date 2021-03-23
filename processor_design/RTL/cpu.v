//Module: CPU
//Function: CPU is the top design of the processor
//Inputs:
//	clk: main clock
//	arst_n: reset 
// 	enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// 	ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// 	ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory
//Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory


module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[31:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[31:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [31:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[31:0]  rdata_ext_2

   );

wire              zero_flag;
wire [      31:0] branch_pc,updated_pc,current_pc,jump_pc,
                  instruction;
wire [       1:0] alu_op;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire [       4:0] regfile_waddr;
wire [      31:0] regfile_wdata, dram_data,alu_out,
                  regfile_data_1,regfile_data_2,
                  alu_operand_2;
wire [      63:0] signal_IF_out,signal_ID_in;           // updated_pc, instruction

wire [     169:0] signal_ID_out, signal_EX_in;          // reg_write[169], mem_2_reg[168]
                                                        // jump [167], branch[166], mem_read[165], mem_write[164]
                                                        // reg_dst[163], alu_op[162:161], alu_src[160]
                                                        // updated_pc[159:128]
                                                        // regfile_data_1[127:96], regfile_data_2 [95:64]
                                                        // immediate_extended[63:32], instruction[31:0]
                  

wire signed [31:0] immediate_extended;



// IF Stage
pc #(
   .DATA_W(32)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc ),
   .jump_pc   (jump_pc   ),
   .zero_flag (zero_flag ),
   .branch    (branch    ),
   .jump      (jump      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(signal_IF_out[63:32])        // updated_pc
);


sram #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (signal_IF_out[31:0]   ),      //instruction
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

// ID STAGE

reg_arstn_en #(
      .DATA_W(64)
) signal_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (signal_IF_out  ),
      .en    (enable    ),
      .dout  (signal_ID_in)
   );

control_unit control_unit(
   .opcode   (signal_ID_in[31:26]),
   .reg_dst  (signal_ID_out[141]           ),           //reg_dst
   .branch   (signal_ID_out[144]            ),          //branch
   .mem_read (signal_ID_out[143]          ),            //mem_read
   .mem_2_reg(signal_ID_out[146]         ),             //mem_2_reg
   .alu_op   (signal_ID_out[140:139]            ),      //alu_op
   .mem_write(signal_ID_out[142]         ),             //mem_write
   .alu_src  (signal_ID_out[138]),                      //alu_src
   .reg_write(signal_ID_out[147]         ),             //reg_write
   .jump     (signal_ID_out[145]              )         //jump
);


register_file #(
   .DATA_W(32)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(reg_write         ),
   .raddr_1  (signal_ID_in[25:21]),
   .raddr_2  (signal_ID_in[20:16]),
   .waddr    (regfile_waddr     ),
   .wdata    (regfile_wdata     ),
   .rdata_1  (signal_ID_out[105:74]    ),     //regfile_data_1
   .rdata_2  (signal_ID_out[73:42]    )       //regfile_data_2
);

assign immediate_extended = $signed(signal_ID_in[15:0]);

assign signal_ID_out[4:0] = signal_ID_in[15:11];
assign signal_ID_out[9:5] = signal_ID_in[20:16];
assign signal_ID_out[41:10] = immediate_extended;

assign signal_ID_out[137:106] = signal_ID_in[63:32];    //updated_pc


// EX STAGE

reg_arstn_en #(
      .DATA_W(16)
) signal_pipe_ID_EX(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (signal_ID_out  ),
      .en    (enable    ),
      .dout  (signal_EX_in)
   );
   
mux_2 #(
   .DATA_W(5)
) regfile_dest_mux (
   .input_a (signal_EX_in[4:0]),
   .input_b (signal_EX_in[9:5]),
   .select_a(signal_EX_in[141]          ),
   .mux_out (regfile_waddr     )
);

alu_control alu_ctrl(
   .function_field (signal_EX_in[15:10]),               //instruction[5:0]
   .alu_op         (signal_EX_in[140:139]          ),   //alu_op
   .alu_control    (alu_control     )
);

mux_2 #(
   .DATA_W(32)
) alu_operand_mux (
   .input_a (signal_EX_in[41:10]),          // immediate_extended
   .input_b (signal_EX_in[73:42]    ),      //regfile_data_2
   .select_a(signal_EX_in[138]           ), //alu_src
   .mux_out (alu_operand_2     )
);


alu#(
   .DATA_W(32)
) alu(
   .alu_in_0 (signal_EX_in[105:74),     //regfile_data_1
   .alu_in_1 (alu_operand_2 ),
   .alu_ctrl (alu_control   ),
   .alu_out  (alu_out       ),
   .shft_amnt(signal_EX_in[20:16]),     // instruction[10:6]
   .zero_flag(zero_flag     ),
   .overflow (              )
);

// STAGE MEM

reg_arstn_en #(
      .DATA_W(16)
) signal_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (signal_IF  ),
      .en    (enable    ),
      .dout  (signal_ID)
   );

sram #(
   .ADDR_W(10),
   .DATA_W(32)
) data_memory(
   .clk      (clk           ),
   .addr     (alu_out       ),
   .wen      (mem_write     ),
   .ren      (mem_read      ),
   .wdata    (regfile_data_2),
   .rdata    (dram_data     ),   
   .addr_ext (addr_ext_2    ),
   .wen_ext  (wen_ext_2     ),
   .ren_ext  (ren_ext_2     ),
   .wdata_ext(wdata_ext_2   ),
   .rdata_ext(rdata_ext_2   )
);

branch_unit#(
   .DATA_W(32)
)branch_unit(
   .updated_pc   (updated_pc        ),
   .instruction  (instruction       ),
   .branch_offset(immediate_extended),
   .branch_pc    (branch_pc         ),
   .jump_pc      (jump_pc         )
);

// WB STAGE

reg_arstn_en #(
      .DATA_W(16)
) signal_pipe_MEM_WB(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (signal_IF  ),
      .en    (enable    ),
      .dout  (signal_ID)
   );

mux_2 #(
   .DATA_W(32)
) regfile_data_mux (
   .input_a  (dram_data    ),
   .input_b  (alu_out      ),
   .select_a (mem_2_reg     ),
   .mux_out  (regfile_wdata)
);




endmodule


