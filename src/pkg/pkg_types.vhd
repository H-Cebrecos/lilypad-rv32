
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package pkg_types is

    constant NOP : std_logic_vector(31 downto 0) := X"00000013";
    -- Define enumeration for opcodes
    type OPCODE_T is (
        OP,
        OP_IMM,
        LOAD,
        STORE,
        BRANCH,
        MISC_MEM,
        SYSTEM,
        LUI,
        AUIPC,
        JAL,
        JALR,
        ILLEGAL
    );

    -- Values of opcodes
    constant OP_VAL       : std_logic_vector(4 downto 0) := "01100";
    constant OP_IMM_VAL   : std_logic_vector(4 downto 0) := "00100";
    constant LOAD_VAL     : std_logic_vector(4 downto 0) := "00000";
    constant STORE_VAL    : std_logic_vector(4 downto 0) := "01000";
    constant BRANCH_VAL   : std_logic_vector(4 downto 0) := "11000";
    constant MISC_MEM_VAL : std_logic_vector(4 downto 0) := "00011";
    constant SYSTEM_VAL   : std_logic_vector(4 downto 0) := "11100";
    constant LUI_VAL      : std_logic_vector(4 downto 0) := "01101";
    constant AUIPC_VAL    : std_logic_vector(4 downto 0) := "00101";
    constant JAL_VAL      : std_logic_vector(4 downto 0) := "11011";
    constant JALR_VAL     : std_logic_vector(4 downto 0) := "11001";

    -- function to convert between the two
    function binary_to_opcode(bin : std_logic_vector(4 downto 0)) return opcode_t;


    -- ALU operation types
    type ALU_OP_T is (
        ALU_ADD,
        ALU_SUB,
        ALU_AND,
        ALU_OR,

        ALU_XOR,
        ALU_SHFT,
        ALU_CMP,
        ALU_BRANCH
    );
    -- Shift direction
    type SHFT_DIR_T is (SHFT_LEFT, SHFT_RIGHT);

    -- Shift type
    type SHFT_TYPE_T is (SHFT_LOGIC, SHFT_ARITH);

    -- ALU source types
    type ALU_SRC1_T is (ALU_REG1, ALU_PC);
    type ALU_SRC2_T is (ALU_REG2, ALU_IMM);

    -- Write source types
    type WRITE_SRC_T is (
        SRC_ALU,
        SRC_PC_ADD4,
        SRC_IMM,
        SRC_MEM,

        SRC_NONE
    );

    -- PC source types
    type PC_SRC_T is (
        PC_SRC_ALU_RSLT,
        PC_SRC_ADD_RSLT
    );

    -- Memory operation types
    type MEM_OP_T is (
        MEM_R,
        MEM_W,
        MEM_NONE
    );

    -- Memory size types
    type MEM_SIZE_T is (
        SIZE_B,
        SIZE_H,
        SIZE_W,
        SIZE_BU,

        SIZE_HU
    );

    -- Comparison operation types
    type CMP_T is (
        CMP_EQ,
        CMP_NE,
        CMP_LT,
        CMP_LTU,

        CMP_GE,
        CMP_GEU,
        CMP_NONE
    );

end package ;

package body pkg_types is
    function binary_to_opcode(bin : std_logic_vector(4 downto 0)) return opcode_t is
    begin
        case bin is
            when "01100" => return OP;
            when "00100" => return OP_IMM;
            when "00000" => return LOAD;
            when "01000" => return STORE;
            when "11000" => return BRANCH;
            when "00011" => return MISC_MEM;
            when "11100" => return SYSTEM;
            when "01101" => return LUI;
            when "00101" => return AUIPC;
            when "11011" => return JAL;
            when "11001" => return JALR;
            when others  => return ILLEGAL; 
        end case;
    end binary_to_opcode;

end;