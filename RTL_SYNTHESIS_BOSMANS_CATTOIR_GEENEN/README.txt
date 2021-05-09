As mentioned in the Discord channel #FAQ, the following list of programs work:
Pipelined Processor (with data-hazard resolution): simpleprogram, mult2, mult3

Note that however 'simpleprogram' will run into an error for the pipelined processor, unless some NOPS are added between the two final lines of code.
Otherwise, the stop instruction is executed too early and the pipeline is stopped.
This is confirmed to be a known "issue" by TA Linyan Mei, and she approved to solve it by including 4 times "fffffff" before the stop instruction.
The file 'simpleprogram_imem_content.txt' should thus look like the version at the bottom of this file.

Also note that two extra units were made to make the Pipelined Processor with data-hazard resolution implementation work.
To make sure the simulation takes these units into account as well, two extra lines of code were added in the file 'processor_design\SIM\files_verilog.f':
../RTL/mux_3.v
../RTL/fw_unit.v




20100007 // addi $s0, $0, 7
ffffffff
ffffffff
ffffffff
ffffffff
22110002 // addi $s1, $s0, 2
ffffffff
ffffffff
ffffffff
ffffffff
ac110000 // sw $s1, 0($0)
ffffffff
ffffffff
ffffffff
ffffffff
8c120000 // lw $s2, 0($0)
ffffffff
ffffffff
ffffffff
ffffffff
02129820 // add $s3, $s0, $s2
ffffffff
ffffffff
ffffffff
ffffffff
12320009 // beq $s1,$s2, FINAL
ffffffff
ffffffff
ffffffff
ffffffff
0211a020 // add $s4, $s0, $s1
ffffffff
ffffffff
ffffffff
ffffffff
0253a020 // FINAL: add $s4, $s2,$s3
ffffffff
ffffffff
ffffffff
ffffffff
f8000000 // STOP instruction
