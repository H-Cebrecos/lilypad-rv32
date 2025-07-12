library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.ALU_TLM.ALL;
use work.types.all;

entity ALU_tb is
end ALU_tb;

architecture Test of ALU_tb is
    -- ALU signals
    signal op_sel    : ALU_OP_T;
    signal src1_sel  : ALU_SRC1_T;
    signal reg1      : std_logic_vector(31 downto 0);
    signal src2_sel  : ALU_SRC2_T;
    signal reg2      : std_logic_vector(31 downto 0);
    signal pc        : std_logic_vector(31 downto 0):= ( others =>'0');
    signal imm       : std_logic_vector(31 downto 0);
    signal cmp_mode  : CMP_T;
    signal shft_type : SHFT_TYPE_T;
    signal shft_dir  : SHFT_DIR_T;
    signal alu_rslt  : std_logic_vector(31 downto 0);
    signal error_flag: boolean := false;

    -- Instantiate ALU (DUT)
    component ALU
        Port (
            op_sel    : in  ALU_OP_T;
            src1_sel  : in  ALU_SRC1_T;
            reg1      : in  std_logic_vector(31 downto 0);
            src2_sel  : in  ALU_SRC2_T;
            reg2      : in  std_logic_vector(31 downto 0);
            pc        : in  std_logic_vector(31 downto 0);
            imm       : in  std_logic_vector(31 downto 0);
            cmp_mode  : in  CMP_T;
            shft_type : in  SHFT_TYPE_T;
            shft_dir  : in  SHFT_DIR_T;
            alu_rslt  : out std_logic_vector(31 downto 0)
        );
    end component;

begin
    -- Connect ALU (DUT)
    ALU_INST: ALU
        port map (
            op_sel    => op_sel,
            src1_sel  => src1_sel,
            reg1      => reg1,
            src2_sel  => src2_sel,
            reg2      => reg2,
            pc        => pc,
            imm       => imm,
            cmp_mode  => cmp_mode,
            shft_type => shft_type,
            shft_dir  => shft_dir,
            alu_rslt  => alu_rslt
        );

    -- Test Process
    process
    type ALU_Transaction_Array is array (natural range <>) of ALU_Transaction;
    constant transactions : ALU_Transaction_Array := (
        -- ADD Tests
        --  op      src1         r1        src2        r2        expected         pc          imm     cmp_mode shft_type   shft_dir 
        (ALU_ADD, ALU_REG1, x"0000000A", ALU_REG2, x"00000014", x"0000001E", x"00000000", x"00000000", CMP_EQ, SHFT_LOGIC, SHFT_LEFT),  --1 addition
        (ALU_ADD, ALU_REG1, x"0000000A", ALU_IMM,  x"00000000", x"0000001E", x"00000000", x"00000014", CMP_EQ, SHFT_LOGIC, SHFT_LEFT),  --2 addition
        (ALU_ADD, ALU_REG1, x"FFFFFFFE", ALU_REG2, x"00000002", x"00000000", x"00000000", x"00000000", CMP_EQ, SHFT_LOGIC, SHFT_LEFT),  --3 overflow

        -- SUB Tests
        --  op      src1         r1        src2        r2        expected         pc          imm     cmp_mode shft_type   shft_dir 
        (ALU_SUB, ALU_REG1, x"00000014", ALU_REG2, x"0000000A", x"0000000A", x"00000000", x"00000000", CMP_EQ, SHFT_LOGIC, SHFT_LEFT),  --4 subtraction
        (ALU_SUB, ALU_REG1, x"00000000", ALU_REG2, x"00000010", x"FFFFFFF0", x"00000000", x"00000000", CMP_EQ, SHFT_LOGIC, SHFT_LEFT),  --5 underflow

        -- LOGIC Tests
        --  op      src1         r1        src2        r2        expected         pc          imm     cmp_mode shft_type   shft_dir 
        (ALU_AND, ALU_REG1, x"FFFFFFFF", ALU_REG2, x"00000000", x"00000000", x"00000000", x"00000000", CMP_EQ, SHFT_LOGIC, SHFT_LEFT),  --6  AND
        (ALU_OR,  ALU_REG1, x"FFFFFFFF", ALU_REG2, x"00000000", x"FFFFFFFF", x"00000000", x"00000000", CMP_EQ, SHFT_LOGIC, SHFT_LEFT),  --7  OR
        (ALU_XOR, ALU_REG1, x"FFFFFFFF", ALU_REG2, x"0000000A", x"FFFFFFF5", x"00000000", x"00000000", CMP_EQ, SHFT_LOGIC, SHFT_LEFT),  --8  XOR

        -- SHIFT Tests
        --  op      src1         r1        src2        r2        expected         pc          imm     cmp_mode shft_type   shft_dir 
        (ALU_SHFT, ALU_REG1, x"50055005", ALU_REG2, x"00000001", x"A00AA00A", x"00000000", x"00000000", CMP_EQ, SHFT_LOGIC, SHFT_LEFT), --9  SLL
        (ALU_SHFT, ALU_REG1, x"A000000A", ALU_REG2, x"00000001", x"50000005", x"00000000", x"00000000", CMP_EQ, SHFT_LOGIC, SHFT_RIGHT),--10 SRL
        (ALU_SHFT, ALU_REG1, x"A000000A", ALU_REG2, x"00000001", x"D0000005", x"00000000", x"00000000", CMP_EQ, SHFT_ARITH, SHFT_RIGHT),--11 SRA

        -- Comparison Tests
        --  op      src1         r1        src2        r2        expected         pc          imm     cmp_mode shft_type   shft_dir 
        (ALU_CMP, ALU_REG1, x"FFFFFFFF", ALU_REG2, x"00000000", x"00000000", x"00000000", x"00000000", CMP_EQ, SHFT_LOGIC, SHFT_LEFT),  --12 EQ  false
        (ALU_CMP, ALU_REG1, x"00000000", ALU_REG2, x"00000000", x"00000001", x"00000000", x"00000000", CMP_EQ, SHFT_LOGIC, SHFT_LEFT),  --13 EQ  true
        (ALU_CMP, ALU_REG1, x"FFFFFFFF", ALU_REG2, x"00000000", x"00000001", x"00000000", x"00000000", CMP_NE, SHFT_LOGIC, SHFT_LEFT),  --14 NEQ true
        (ALU_CMP, ALU_REG1, x"00000000", ALU_REG2, x"00000000", x"00000000", x"00000000", x"00000000", CMP_NE, SHFT_LOGIC, SHFT_LEFT),  --15 NEQ false
        (ALU_CMP, ALU_REG1, x"00000005", ALU_REG2, x"0000000A", x"00000001", x"00000000", x"00000000", CMP_LT, SHFT_LOGIC, SHFT_LEFT),  --16 LT  true
        (ALU_CMP, ALU_REG1, x"FFFFFFFF", ALU_REG2, x"FFFFFFFE", x"00000000", x"00000000", x"00000000", CMP_LT, SHFT_LOGIC, SHFT_LEFT),  --17 LT  false
        (ALU_CMP, ALU_REG1, x"00000002", ALU_REG2, x"00010000", x"00000001", x"00000000", x"00000000", CMP_LTU, SHFT_LOGIC, SHFT_LEFT), --18 LTU true
        (ALU_CMP, ALU_REG1, x"0000000A", ALU_REG2, x"00000005", x"00000000", x"00000000", x"00000000", CMP_LTU, SHFT_LOGIC, SHFT_LEFT), --19 LTU false
        (ALU_CMP, ALU_REG1, x"0000000A", ALU_REG2, x"00000005", x"00000001", x"00000000", x"00000000", CMP_GE, SHFT_LOGIC, SHFT_LEFT),  --20 GE  true
        (ALU_CMP, ALU_REG1, x"00000005", ALU_REG2, x"0000000A", x"00000000", x"00000000", x"00000000", CMP_GE, SHFT_LOGIC, SHFT_LEFT),  --21 GE  false
        (ALU_CMP, ALU_REG1, x"FFFFFFFF", ALU_REG2, x"FFFFFFFE", x"00000001", x"00000000", x"00000000", CMP_GEU, SHFT_LOGIC, SHFT_LEFT), --22 GEU true
        (ALU_CMP, ALU_REG1, x"00000005", ALU_REG2, x"0000000A", x"00000000", x"00000000", x"00000000", CMP_GEU, SHFT_LOGIC, SHFT_LEFT)  --23 GEU false
    );
begin
    -- Loop through all transactions
    for i in transactions'range loop
        execute_transaction(i+1, transactions(i), op_sel, src1_sel, reg1, src2_sel, reg2,
                            pc, imm, cmp_mode, shft_type, shft_dir, alu_rslt, error_flag);
    end loop;

    -- Final result check
    if error_flag then
        report "TEST FAILED!" severity error;
    else
        report "ALL TESTS PASSED" severity note;
    end if;

    wait;
end process;
end Test;
