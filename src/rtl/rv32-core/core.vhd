----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/12/2025 11:11:20 AM
-- Design Name: 
-- Module Name: memory - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_components.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.pkg_types.all;

entity core is
    Port (
        -- Inputs.
        clk         : in STD_LOGIC;                             -- clock signal. 
        reset       : in STD_LOGIC;                             -- synchronous reset, sets PC pointing to RESET_VECTOR.
        instruction : in STD_LOGIC_VECTOR (31 downto 0);        -- instruction data.
        mem_data    : in STD_LOGIC_VECTOR (31 downto 0);        -- raw data read from system memory (always word aligned).
        -- Outputs.
        inst_addr   : out STD_LOGIC_VECTOR (31 downto 0);       -- address of the next instruction to be fetched.
        mem_addr    : out STD_LOGIC_VECTOR (31 downto 0);       -- address in system memory for the memory operations.
        mem_wen     : out STD_LOGIC_VECTOR (3 downto 0);        -- write enable signal for memory.  
        write_data  : out STD_LOGIC_VECTOR (31 downto 0);       -- data for write operation.

        req         : out STD_LOGIC                             -- memory request signal.           
    );
end core;

architecture Behavioral of core is
    component decoder
        Port (
            -- Input.
            instruction : in STD_LOGIC_VECTOR (31 downto 0);

            -- Outputs to register file.
            rs1 : out STD_LOGIC_VECTOR (4 downto 0);        -- first source register.
            rs2 : out STD_LOGIC_VECTOR (4 downto 0);        -- second source register.
            rd  : out STD_LOGIC_VECTOR (4 downto 0);        -- destination register.
            reg_write_src : out WRITE_SRC_T;                -- selector for the source of write data.

            -- Outputs to ALU.
            ext_imm : out  STD_LOGIC_VECTOR (31 downto 0);  -- extended immediate.
            alu_op_sel      : out ALU_OP_T;                 -- selects the operation for the ALU.
            alu_src1_sel    : out ALU_SRC1_T;               -- selects the source for the first operand.
            alu_src2_sel    : out ALU_SRC2_T;               -- selects the source for the second operand.
            cmp_mode        : out CMP_T;                    -- selects the type of comparison.
            shft_type       : out SHFT_TYPE_T;              -- selects between logic and arithmetic shifts.
            shft_dir        : out SHFT_DIR_T;               -- selects between left and right shifts.

            -- Outputs to PC.
            is_branch   : out STD_LOGIC;                    -- indicates if the current instruction is a conditional branch, in which case cmp_rslt overrides next_pc_src.
            next_pc_src : out PC_SRC_T;                     -- selects whether the next address comes from incrementing the PC or from the ALU.

            -- Outputs to memory unit.
            mem_operation : out MEM_OP_T;                   -- selects the operation to perform.
            data_size     : out MEM_SIZE_T;                 -- selects the size of the data (Byte, half word or word) and signedness.

            -- Exeptions.
            illegal_instruction_exception : out STD_LOGIC
        );
    end component;
    component register_file
        Port (
            -- Clock input.
            clk : in STD_LOGIC;                             -- clock signal. 
            pause : in STD_LOGIC;

            -- Register selection.
            rs1 : in STD_LOGIC_VECTOR (4 downto 0);         -- source register 1.
            rs2 : in STD_LOGIC_VECTOR (4 downto 0);         -- soruce register 2.
            rd  : in STD_LOGIC_VECTOR (4 downto 0);         -- destination register.

            -- Write selection and data.
            write_src : in WRITE_SRC_T;                     -- source of the write data.
            alu_rslt  : in STD_LOGIC_VECTOR (31 downto 0);  -- result of ALU computation.
            immediate : in STD_LOGIC_VECTOR (31 downto 0);  -- extendend immendiate.
            mem_rslt  : in STD_LOGIC_VECTOR (31 downto 0);  -- value read from memory.
            next_inst : in STD_LOGIC_VECTOR (31 downto 0);  -- address of the next instruction in memory.

            -- Outputs.
            rs1_data  : out STD_LOGIC_VECTOR (31 downto 0); -- contents of register indexed by rs1.
            rs2_Data  : out STD_LOGIC_VECTOR (31 downto 0)  -- contents of register indexed by rs1.
        );
    end component;
    component ALU
        Port (
            -- Operation selection.
            op_sel  : in ALU_OP_T;                        -- selects the operation for the ALU.

            -- Operand selection.
            src1_sel : in ALU_SRC1_T;                      -- selects the source for the first operand.
            reg1, pc : in STD_LOGIC_VECTOR(31 downto 0);   -- sources for the first operand

            src2_sel : in ALU_SRC2_T;                      -- selects the source for the second operand.
            reg2, imm: in STD_LOGIC_VECTOR(31 downto 0);   -- sources for the second operand

            -- Comparator configuration.
            cmp_mode : in CMP_T;                           -- selects the type of comparison.

            -- Shift configuration.
            shft_type: in SHFT_TYPE_T;                     -- selects between logic and arithmetic shifts.
            shft_dir : in SHFT_DIR_T;                      -- selects between left and right shifts.

            -- Outputs.
            alu_rslt : out STD_LOGIC_VECTOR(31 downto 0);  -- result of computation.
            cmp_rslt : out STD_LOGIC                       -- result of comparison, used when branching.
        );
    end component;


    -- Signals.
    signal next_pc_src : PC_SRC_T;
    signal alu_rslt : STD_LOGIC_VECTOR (31 downto 0);
    signal cmp_rslt : STD_LOGIC;
    signal is_branch : STD_LOGIC;
    signal current_pc : STD_LOGIC_VECTOR (31 downto 0);
    signal current_pc_2 : STD_LOGIC_VECTOR (31 downto 0);
    signal next_inst_addr : STD_LOGIC_VECTOR (31 downto 0);
    signal instruction_address_misaligned_exception : STD_LOGIC;
    signal current_inst : STD_LOGIC_VECTOR (31 downto 0);
    signal rs1 : STD_LOGIC_VECTOR (4 downto 0);
    signal rs2 : STD_LOGIC_VECTOR (4 downto 0);
    signal rd  : STD_LOGIC_VECTOR (4 downto 0);
    signal reg_write_src : WRITE_SRC_T;
    signal ext_imm : STD_LOGIC_VECTOR (31 downto 0);
    signal alu_op_sel : ALU_OP_T;
    signal alu_src1_sel : ALU_SRC1_T;
    signal alu_src2_sel : ALU_SRC2_T;
    signal cmp_mode : CMP_T;
    signal shft_dir : SHFT_DIR_T;
    signal shft_type : SHFT_TYPE_T;
    signal mem_operation : MEM_OP_T;
    signal data_size : MEM_SIZE_T;
    signal illegal_instruction_exception : STD_LOGIC;
    signal mem_rslt : STD_LOGIC_VECTOR (31 downto 0);
    signal rs1_data : STD_LOGIC_VECTOR (31 downto 0);
    signal rs2_data : STD_LOGIC_VECTOR (31 downto 0);
    signal address_misaligned_exception : STD_LOGIC;
    --signal rg : std_logic;
    signal pause, flush, valid, is_load : std_logic;
    signal  data_out, fetch_addr : STD_LOGIC_VECTOR (31 downto 0);
    
    signal stall :std_logic;
begin

    inst_addr <= fetch_addr;
    pip_dec : pipeline_decoupler
        generic map (
            LATENCY    => 2,
            COMMAND_WIDTH => 32,
            DATA_WIDTH => 32
        )
        port map (
            clk      => clk,
            rst      => reset,
            flush    => flush,
            pause   => pause,
            cmd_in  => fetch_addr,
            data_in => instruction,

            valid    => valid,
            cmd_out => current_pc,
            data_out => data_out
        );

    PC: fetch_unit port map(
            -- Inputs.
            clk         => clk,
            rst       => reset,
            valid       => valid,
            stall       => stall,
            next_pc_src => next_pc_src,
            alu_addr    => alu_rslt(31 downto 1),
            cmp_rslt    => cmp_rslt,
            is_branch   => is_branch,
            

            inst_data   => data_out,
            inst_addr   => current_pc,
            -- Outputs.
            next_inst_addr  => next_inst_addr,
            fetch_addr         => fetch_addr,
            instruction_address_misaligned_exception => instruction_address_misaligned_exception,
            current_inst => current_inst,
            current_addr => current_pc_2,
            pause => pause,
            flush => flush
        );

    DEC: decoder port map(
            -- Inputs.
            instruction => current_inst,
            -- Outputs to register file.
            rs1 => rs1,
            rs2 => rs2,
            rd  => rd,
            reg_write_src => reg_write_src,
            -- Outputs to ALU.
            ext_imm      => ext_imm,
            alu_op_sel   => alu_op_sel,
            alu_src1_sel => alu_src1_sel,
            alu_src2_sel => alu_src2_sel,
            cmp_mode     => cmp_mode,
            shft_type    => shft_type,
            shft_dir     => shft_dir,
            -- Outputs to PC.
            is_branch   => is_branch,
            next_pc_src => next_pc_src,
            -- Outputs to memory unit.
            mem_operation => mem_operation,
            data_size     => data_size,
            -- Exeptions.
            illegal_instruction_exception => illegal_instruction_exception
        );
    REG: register_file port map(
            -- Inputs.
            clk => clk,
            pause => pause,
            rs1 => rs1,
            rs2 => rs2,
            rd  => rd,
            write_src => reg_write_src,
            alu_rslt  => alu_rslt,
            immediate => ext_imm,
            mem_rslt  => mem_rslt,
            next_inst => next_inst_addr,
            -- Outputs.
            rs1_data => rs1_data,
            rs2_Data => rs2_data
        );
    ALU1: ALU port map(
            -- Inputs.
            op_sel    => alu_op_sel,
            src1_sel  => alu_src1_sel,
            reg1      => rs1_data,
            pc        => current_pc_2,
            src2_sel  => alu_src2_sel,
            reg2      => rs2_data,
            imm       => ext_imm,
            cmp_mode  => cmp_mode,
            shft_type => shft_type,
            shft_dir  => shft_dir,
            -- Outputs.
            alu_rslt=> alu_rslt,
            cmp_rslt=> cmp_rslt
        );
    MEM_U: mem_unit port map(
            -- Inputs.          
            clk           => clk,
            rst           => reset,
            mem_operation => mem_operation,
            data_size     => data_size,
            rs2_data      => rs2_data,
            mem_addr      => alu_rslt(1 downto 0),
            mem_data      => mem_data,
            -- trigger_pause => '0',
            -- Outputs to register file.                                                                  
            mem_rslt      => mem_rslt,
            -- Outputs to memory                                                                          
            write_data    => write_data,
            mem_wen       => mem_wen,
            req           => req,

            --pause         => open,
            stall         => stall,
            -- Exeptions.  
            address_misaligned_exception => address_misaligned_exception
        );

    mem_addr <= alu_rslt;
end Behavioral;
