library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use IEEE.NUMERIC_STD_UNSIGNED.ALL;

use work.pkg_types.all;

entity ALU is
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
end ALU;

architecture Behavioral of ALU is
    -- Internal operands.
    signal op1 : STD_LOGIC_VECTOR (31 downto 0);
    signal op2 : STD_LOGIC_VECTOR (31 downto 0);
    signal cmp : STD_LOGIC;

    -- Function extracted for code reuse.
    function compare(mode: CMP_T; op1, op2: STD_LOGIC_VECTOR (31 downto 0))return STD_LOGIC is
        variable rslt : STD_LOGIC;
    begin

        return  rslt;
    end function;
begin
    -- Operands selection muxes.
    op1 <= reg1 when src1_sel = ALU_REG1 else pc;
    op2 <= reg2 when src2_sel = ALU_REG2 else imm;

    -- Compare signal.
    comparison : process(all)
        variable cmp_op1, cmp_op2 : STD_LOGIC_VECTOR(31 downto 0);
    begin
        -- Branch Instructions ignore the operand selection and always compare the registers.
        cmp_op1 := reg1 when op_sel = ALU_BRANCH else op1;
        cmp_op2 := reg2 when op_sel = ALU_BRANCH else op2;
        case cmp_mode is
            when CMP_EQ  => cmp <= '1' when cmp_op1 = cmp_op2 else '0';
            when CMP_NE  => cmp <= '1' when cmp_op1 /= cmp_op2 else '0';
            when CMP_LT  => cmp <= '1' when signed(cmp_op1) < signed(cmp_op2) else '0';
            when CMP_LTU => cmp <= '1' when unsigned(cmp_op1) < unsigned(cmp_op2) else '0';
            when CMP_GE  => cmp <= '1' when signed(cmp_op1) >= signed(cmp_op2) else '0';
            when CMP_GEU => cmp <= '1' when unsigned(cmp_op1) >= unsigned(cmp_op2) else '0';
            when others  => cmp <= '0'; -- default behaviour is no-branch. 
        end case;
        cmp_rslt <= cmp;
    end process;
    
    compute : process(all) -- Compute the ALU result.
    begin
        case op_sel is
            when ALU_ADD => alu_rslt <= op1 + op2;
            when ALU_SUB => alu_rslt <= op1 - op2;
            when ALU_AND => alu_rslt <= op1 AND op2;
            when ALU_OR  => alu_rslt <= op1 OR op2;
            when ALU_XOR => alu_rslt <= op1 XOR op2;
            when ALU_CMP =>
                alu_rslt <= (31 downto 1 => '0') & cmp;
            when ALU_BRANCH  =>
                alu_rslt <= pc + imm;                   -- branch target address computation.
            when ALU_SHFT =>
                if shft_dir = SHFT_LEFT then
                    -- shift left, same for logic and arith.
                    alu_rslt <= op1 sll to_integer(op2(4 downto 0));
                elsif shft_type = SHFT_LOGIC then
                    -- shift logic right.
                    alu_rslt <= op1 srl to_integer(op2(4 downto 0));
                else
                    -- shift arith right.
                    --alu_rslt <= op1 sra to_integer(op2(4 downto 0)); --does not work as it doesn't interpret the data as signed.
                    alu_rslt <= std_logic_vector(shift_right(signed(op1), to_integer(op2(4 downto 0) )));
                    
                    
                end if;
        end case;
    end process;
end Behavioral;
