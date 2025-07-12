# lilypad-rv32
An FPGA implementation of a RISC-V 32-bit processor.

This project was developed for the Basys 3 board, but it should be trivial to port it to other AMD FPGAs and not to difficult to port to other vendors.

## File structure
    lilypad-rv32
    ├── software/
    │ 
    ├── src/
    │   ├── cons/
    │   ├── pkg/
    │   ├── rtl/
    │   ├── sim/
    │   └── ip/
    │ 
    ├── vivado/
    │   └── rebuild.tcl
    │ 
    └── README.md

- The rtl, sim and cons subdirectories inside src contain the source code for synthesis, for    simulation and the constraint files respectively. The pkg directory contails the VHDL packages and the ip directory contains the ip source files.
- The vivado subdirectory contains the script to regenerate the Vivado project.

## Regenerating the Vivado project
To regenerate the Vivado project navigate to the vivado subdiretory and run the following command:

    vivado -source ./rebuild.tcl

This will generate the vivado project subdirectory inside the vivado directory.

## Modifiying the project
 The generated vivado project subdirectory should NOT be checked into the repository. Instead all new source files for the project should be created inside the src directory and then imported into the project. To generate an up to date regeneration script, run the following tcl command inside the tcl console in vivado.

    write_project_tcl -force rebuild

This will generate an up to date script inside the project subdirectory, this file should replace the now out-of-date file located in the vivado parent directory.

If you use IP from the IP catalaog remember to change the IP location in the configuration wizard to the /src/ip directory.

## Developing software

To compile C programs you use the compile.sh script an pass the files you want to compile as arguments, as if calling the compiler, this will genereate a uf2 file.

## Developing the bootloader
The same as the software but you call make_boot_rom.sh instead, the output is the contents of a COE file, you then reprogram the system ROM with that file.

## Programming the core

To program the processor connect to the UART acording to your constraints file (in this case RX: JB1 TX: JB2 on the basys PMods) the configuration is 8N1 @ 115200, then transmit the uf2 file through the UART.