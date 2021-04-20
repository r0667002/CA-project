module fw_unit(
      input  wire [4:0] ex_mem_rd,
      input  wire [4:0] mem_wb_rd,
      input  wire [4:0] rs1_addr,
      input  wire [4:0] rs2_addr,
      input  wire       ex_mem_regwrite,
      input  wire       mem_wb_regwrite,
      output reg  [1:0] mux_A_crtl,
      output reg  [1:0] mux_B_crtl
   );  


   //The behavior of the control unit can be found in Chapter 4, Figure 4.18

   always@(*)begin
    
    // ex_mem stage FW
        
        // mux A
        
        if(ex_mem_regwrite == 1 && ex_mem_rd == rs1_addr)
        begin
            mux_A_crtl = 2'd1;
        end
        else if(mem_wb_regwrite == 1 && ex_mem_rd == rs1_addr)
        begin
            mux_A_crtl = 2'd2;
        end
        else begin
            mux_A_crtl = 2'd0;
        end
        
        // mux B
        
        if(ex_mem_regwrite == 1 && ex_mem_rd == rs2_addr)
        begin
            mux_B_crtl = 2'd1;
        end
        else if(mem_wb_regwrite == 1 && ex_mem_rd == rs2_addr)
        begin
            mux_B_crtl = 2'd2;
        end
        else begin
            mux_B_crtl = 2'd0;
        end
    
   
   end

endmodule



