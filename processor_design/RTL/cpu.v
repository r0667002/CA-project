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
wire [      63:0] signal_IF_out,signal_ID_in;           // updated_pc[63:32], instruction[31:0]

wire [     169:0] signal_ID_out, signal_EX_in;          // reg_write[169], mem_2_reg[168]
                                                        // jump [167], branch[166], mem_read[165], mem_write[164]
                                                        // reg_dst[163], alu_op[162:161], alu_src[160]
                                                        // updated_pc[159:128]
                                                        // regfile_data_1[127:96], regfile_data_2 [95:64]
                                                        // immediate_extended[63:32], instruction[31:0]
                                                        
wire [     171:0] signal_EX_out, signal_MEM_in;          // reg_write[171], mem_2_reg[170]
                                                         // jump [169], branch[168], mem_read[167], mem_write[166]
                                                         // updated_pc[165:134]
                                                         // zero_flag[133], alu_out[132:101]
                                                         // regfile_data_2[100:69]
                                                         // regfile_waddr[68:64]
                                                         // immediate_extended[63:32], instruction[31:0]

wire [      97:0] signal_MEM_out, signal_WB_in;          // reg_write[70], mem_2_reg[69]
                                                         // dram_data[68:37]
                                                         // alu_out[36:5]
                                                         // regfile_waddr[4:0]
                  

wire signed [31:0] immediate_extended;


// IF Stage
pc #(
   .DATA_W(32)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc ),
   .jump_pc   (jump_pc   ),
   .zero_flag (signal_MEM_in[133] ),                // zero_flag
   .branch    (signal_MEM_in[168]    ),             // branch
   .jump      (signal_MEM_in[169]      ),           // jump
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc)                // updated_pc
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
   .rdata    (instruction   ),      //instruction
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

assign signal_IF_out[31:0] = instruction;
assign signal_IF_out[63:32] = updated_pc;

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
   .reg_dst  (signal_ID_out[163]           ),           //reg_dst
   .branch   (signal_ID_out[166]            ),          //branch
   .mem_read (signal_ID_out[165]          ),            //mem_read
   .mem_2_reg(signal_ID_out[168]         ),             //mem_2_reg
   .alu_op   (signal_ID_out[162:161]            ),      //alu_op
   .mem_write(signal_ID_out[164]         ),             //mem_write
   .alu_src  (signal_ID_out[160]),                      //alu_src
   .reg_write(signal_ID_out[169]         ),             //reg_write
   .jump     (signal_ID_out[167]              )         //jump
);


register_file #(
   .DATA_W(32)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(signal_WB_in[70]         ),               // reg_write
   .raddr_1  (signal_ID_in[25:21]),
   .raddr_2  (signal_ID_in[20:16]),
   .waddr    (signal_WB_in[4:0]     ),                 // regfile_waddr
   .wdata    (regfile_wdata     ),
   .rdata_1  (signal_ID_out[127:96]    ),               //regfile_data_1
   .rdata_2  (signal_ID_out[95:64]    )                 //regfile_data_2
);

assign immediate_extended = $signed(signal_ID_in[15:0]);


assign signal_ID_out[31:0] = signal_ID_in[31:0];        //instruction
assign signal_ID_out[63:32] = immediate_extended;       //immediate_extended
assign signal_ID_out[159:128] = signal_ID_in[63:32];    //updated_pc


// EX STAGE

reg_arstn_en #(
      .DATA_W(170)
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
   .input_a (signal_EX_in[15:11]),                  //instruction[15:11]
   .input_b (signal_EX_in[20:16]),                  //instruction[20:16]
   .select_a(signal_EX_in[163]),                    //reg_dst
   .mux_out (signal_EX_out[68:64]     )             //regfile_waddr
);

alu_control alu_ctrl(
   .function_field (signal_EX_in[5:0]),                 //instruction[5:0]
   .alu_op         (signal_EX_in[162:161]          ),   //alu_op
   .alu_control    (alu_control     )
);

mux_2 #(
   .DATA_W(32)
) alu_operand_mux (
   .input_a (signal_EX_in[63:32]),          // immediate_extended
   .input_b (signal_EX_in[95:64]    ),      //regfile_data_2
   .select_a(signal_EX_in[160]           ), //alu_src
   .mux_out (alu_operand_2     )
);


alu#(
   .DATA_W(32)
) alu(
   .alu_in_0 (signal_EX_in[127:96]),         //regfile_data_1
   .alu_in_1 (alu_operand_2 ),
   .alu_ctrl (alu_control   ),
   .alu_out  (signal_EX_out[132:101]),      // alu_out
   .shft_amnt(signal_EX_in[10:6]),          // instruction[10:6]
   .zero_flag(signal_EX_out[133]  ),        // zero_flag
   .overflow (              )
);


assign signal_EX_out[63:0] = signal_EX_in[63:0];        // instruction + immediate_extended
assign signal_EX_out[100:69] = signal_EX_in[95:64];     // regfile_data_2
assign signal_EX_out[165:134] = signal_EX_in[159:128];  // updated_pc
assign signal_EX_out[171:166] = signal_EX_in[169:164];  // WB + M control signals


// STAGE MEM

reg_arstn_en #(
      .DATA_W(172)
) signal_pipe_EX_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (signal_EX_out  ),
      .en    (enable    ),
      .dout  (signal_MEM_in)
   );

sram #(
   .ADDR_W(10),
   .DATA_W(32)
) data_memory(
   .clk      (clk           ),
   .addr     (signal_MEM_in[132:101]),      // alu_out
   .wen      (signal_MEM_in[166]    ),      // mem_write
   .ren      (signal_MEM_in[167]    ),      // mem_read
   .wdata    (signal_MEM_in[100:69] ),      // regfile_data_2
   .rdata    (signal_MEM_out[68:37] ),      // dram_data
   .addr_ext (addr_ext_2            ),
   .wen_ext  (wen_ext_2             ),
   .ren_ext  (ren_ext_2             ),
   .wdata_ext(wdata_ext_2           ),
   .rdata_ext(rdata_ext_2           )
);

branch_unit#(
   .DATA_W(32)
)branch_unit(
   .updated_pc   (signal_MEM_in[165:134]),    // updated_pc
   .instruction  (signal_MEM_in[31:0]   ),    // instruction
   .branch_offset(signal_MEM_in[63:32]  ),    // immediate_extended
   .branch_pc    (branch_pc             ),
   .jump_pc      (jump_pc               )
);

assign signal_MEM_out[4:0] = signal_MEM_in[68:64]; // regfile_waddr
assign signal_MEM_out[36:5] = signal_MEM_in[132:101]; // alu_out
assign signal_MEM_out[70:69] = signal_MEM_in[171:170]; // reg_write, mem_2_reg


// WB STAGE

reg_arstn_en #(
      .DATA_W(98)
) signal_pipe_MEM_WB(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (signal_MEM_out ),
      .en    (enable    ),
      .dout  (signal_WB_in)
   );

mux_2 #(
   .DATA_W(32)
) regfile_data_mux (
   .input_a  (signal_WB_in[68:37]),          // dram_data
   .input_b  (signal_WB_in[36:5] ),          // alu_out
   .select_a (signal_WB_in[69]   ),          // mem_2_reg
   .mux_out  (regfile_wdata      )
   );




endmodule

