library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_types.all;

entity decoder is
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
end decoder;

architecture Behavioral of decoder is
    signal opcode : OPCODE_T;
    signal funct3 : STD_LOGIC_VECTOR (2 downto 0);
    signal funct7 : STD_LOGIC_VECTOR (6 downto 0);
    signal f7_bit : STD_LOGIC;                      -- Determinant bit for choosing instructions.
    -- NOTE: this field is 7 bits long, but in the base extension the only possible values for this field are 0000000 and 0100000
    --       the rest of the encodign space is not formed by illegal instruction but used for HINT instructions when rd=x0 instead.
    --       All hints are silently ignored in this implementation.

begin
    -- Register decoding.
    rs1 <= instruction(19 downto 15);
    rs2 <= instruction(24 downto 20);
    rd  <= instruction(11 downto  7);

    -- Function fields.
    funct3 <= instruction(14 downto 12);
    funct7 <= instruction(31 downto 25);
    f7_bit <= instruction(30);
    -- Opcode.
    opcode <= binary_to_opcode(instruction(6 downto 2)); -- auxiliary function to convert binary repensetation into an enum, internaly is just a case statement.

    process(all)
    begin
        -- Opcode must be of the form -----11 to be valid.
        illegal_instruction_exception <= '1' when instruction(1 downto 0) /= "11" else '0';

        -- Default values. Most of this are arbitrary values as instructions that do not set this values will ignore the result.
        next_pc_src   <= PC_SRC_ADD_RSLT; -- next instruction in memory. 
        cmp_mode      <= CMP_NONE;
        alu_op_sel    <= ALU_ADD;
        alu_src1_sel  <= ALU_REG1;
        alu_src2_sel  <= ALU_IMM;
        shft_dir      <= SHFT_LEFT;
        shft_type     <= SHFT_LOGIC;
        reg_write_src <= SRC_NONE; -- Don't write in rd.
        is_branch     <= '0';      -- Not a branch instrution.
        mem_operation <= MEM_NONE; -- Don't request a memory operation.
        data_size     <= SIZE_B;   -- Don't generate address misaligned exceptions if it's not a memory operation.
        

        -- Immediate extension, defined at page 25 of The RISC-V Instruction Set Manual Volume I Unprivileged Architecture Version 20240411.
        imm: case opcode is
            /*I-type*/ when OP_IMM | LOAD |JALR | SYSTEM => ext_imm <= (31 downto 11 => instruction(31)) & instruction(30 downto 20);
            /*S-type*/ when STORE                        => ext_imm <= (31 downto 11 => instruction(31)) & instruction(30 downto 25) & instruction(11 downto 7);
            /*B-type*/ when BRANCH                       => ext_imm <= (31 downto 12 => instruction(31)) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8) & '0';
            /*U-type*/ when LUI | AUIPC                  => ext_imm <= instruction(31 downto 12) & "000000000000";
            /*J-type*/  when JAL                         => ext_imm <= (31 downto 20 => instruction(31)) & instruction(19 downto 12) & instruction(20) & instruction(30 downto 21) & '0';
            /*OP, MISC_MEM*/ when others                 => ext_imm <= (others => '0');
        end case;

        -- Opcode decoding.
        decode: case opcode is
            when LUI =>
                -- LUI stores the extended immediate in rd.
                reg_write_src <= SRC_IMM;
            when AUIPC =>
                -- AUIPC adds the immediate to the program counter in the ALU and stores the result in rd.
                alu_src1_sel  <= ALU_PC; -- addition and imm are selected by default.
                reg_write_src <= SRC_ALU;
            when JAL =>
                -- JAL sets the next PC to the current PC plus the immendiate, and stores the address of the instruction after the current JAL into rd.
                alu_src1_sel  <= ALU_PC; -- addition and imm are selected by default.
                next_pc_src   <= PC_SRC_ALU_RSLT;
                reg_write_src <= SRC_PC_ADD4;
            when JALR =>
                -- Same as JAL but the target address is rs1 + imm instead.
                next_pc_src   <= PC_SRC_ALU_RSLT; -- addition, rs1 and imm are selected by default.
                reg_write_src <= SRC_PC_ADD4;
                -- funct3 field must be all zeroes.
                illegal_instruction_exception <= '1' when funct3 /= "000";
            when OP_IMM =>
                -- Exception if not a HINT instruction, else default value.
                illegal_instruction_exception <= '0' when funct7 = "0-00000" OR rd = "00000";

                -- All OP_IMM instructions use rs1 (default) and immediates (default) and store the ALU result in rd.
                reg_write_src <= SRC_ALU;
                case funct3 is
                    /*ADDI */ when "000" => null; -- defautl behaviour. Add rs1 to immediate and store in rd.
                    /*SLTI */ when "010" => alu_op_sel <= ALU_CMP; cmp_mode <= CMP_LT;  --compare rs1 with immediate in signed mode, place 1 in rd if rs1 > imm.
                    /*SLTIU*/ when "011" => alu_op_sel <= ALU_CMP; cmp_mode <= CMP_LTU; --compare rs1 with immediate in unsigned mode, place 1 in rd if rs1 > imm.
                    /*XORI */ when "100" => alu_op_sel <= ALU_XOR;
                    /*ORI  */ when "110" => alu_op_sel <= ALU_OR;
                    /*ANDI */ when "111" => alu_op_sel <= ALU_AND;
                    /*Shfts*/ when "001" | "101" =>
                        -- Shifts by the lower 5 bits of immediate.
                        alu_op_sel <= ALU_SHFT;
                        shft_dir   <= SHFT_LEFT  when funct3(2) = '0' else SHFT_RIGHT;
                        shft_type  <= SHFT_LOGIC when f7_bit = '0' else SHFT_ARITH;
                    when others => illegal_instruction_exception <= '1';
                end case;
            when OP =>
                -- Exception if not a HINT instruction, else default value.
                illegal_instruction_exception <= '0' when funct7 = "0-00000" OR rd = "00000";

                -- All OP instructions use rs1 (default) and rs2 and store the ALU result in rd.
                alu_src2_sel <= ALU_REG2;
                reg_write_src <= SRC_ALU;
                case funct3 is
                    /*ADDR*/ when "000" => alu_op_sel <= ALU_ADD when f7_bit = '0' else ALU_SUB; -- bit 5 of funct7 field determines if its an addition or subtraction.
                    /*SLT */ when "010" => alu_op_sel <= ALU_CMP; cmp_mode <= CMP_LT;
                    /*SLTU*/ when "011" => alu_op_sel <= ALU_CMP; cmp_mode <= CMP_LTU;
                    /*XOR */ when "100" => alu_op_sel <= ALU_XOR;
                    /*OR  */ when "110" => alu_op_sel <= ALU_OR;
                    /*AND */ when "111" => alu_op_sel <= ALU_AND;
                    /*Shft*/ when "001" | "101" =>
                        -- Shifts by the lower 5 bits of rs2.
                        alu_op_sel <= ALU_SHFT;
                        shft_dir   <= SHFT_LEFT  when funct3(2) = '0' else SHFT_RIGHT;
                        shft_type  <= SHFT_LOGIC when f7_bit = '0' else SHFT_ARITH;
                    when others => illegal_instruction_exception <= '1';
                end case;
            when BRANCH =>
                is_branch <= '1'; -- No need to set next_pc_src to PC_SRC_ALU_RLST, as it's overriden by this signal.

                -- All branch instructions compute the target address and perform a comparison in the ALU in parallel.
                -- branch operations ignore the selected operands and always output PC + imm and compare rs1 with rs2.
                alu_op_sel <= ALU_BRANCH;
                case funct3 is
                    /*BEQ */ when "000" => cmp_mode <= CMP_EQ;
                    /*BNE */ when "001" => cmp_mode <= CMP_NE;
                    /*BLT */ when "100" => cmp_mode <= CMP_LT;
                    /*BGE */ when "101" => cmp_mode <= CMP_GE;
                    /*BLTU*/ when "110" => cmp_mode <= CMP_LTU;
                    /*BGEU*/ when "111" => cmp_mode <= CMP_GEU;
                    when others => illegal_instruction_exception <= '1';
                end case;
            when LOAD =>
                -- Compute the memory address as rs1 + imm (default behaviour).
                mem_operation <= MEM_R;
                reg_write_src <= SRC_MEM;
                case funct3 is
                    /*LB */ when "000" => data_size <= SIZE_B;
                    /*LH */ when "001" => data_size <= SIZE_H;
                    /*LW */ when "010" => data_size <= SIZE_W;
                    /*LBU*/ when "100" => data_size <= SIZE_BU;
                    /*LHU*/ when "101" => data_size <= SIZE_HU;
                    when others => illegal_instruction_exception <= '1';
                end case;
            when STORE =>
                -- Compute the memory address as rs1 + imm (default behaviour).
                mem_operation <= MEM_W;
                case funct3 is
                    /*LB */ when "000" => data_size <= SIZE_B;
                    /*LH */ when "001" => data_size <= SIZE_H;
                    /*LW */ when "010" => data_size <= SIZE_W;
                    when others => illegal_instruction_exception <= '1';
                end case;
            when MISC_MEM => null;
            when SYSTEM => null;
            when ILLEGAL => illegal_instruction_exception <= '1';
        end case;
    end process;
end Behavioral;
