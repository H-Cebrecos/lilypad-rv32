library IEEE;
use IEEE.STD_LOGIC_1164;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;
use IEEE.NUMERIC_STD.ALL;

package ALU_TLM is
    type ALU_Transaction is record
        op       : ALU_OP_T;
        src1     : ALU_SRC1_T;
        s1       : std_logic_vector(31 downto 0);
        src2     : ALU_SRC2_T;
        s2       : std_logic_vector(31 downto 0);
        expected : std_logic_vector(31 downto 0);
        pc       : std_logic_vector(31 downto 0);
        imm      : std_logic_vector(31 downto 0);
        cmp_mode : CMP_T;
        shft_type: SHFT_TYPE_T;
        shft_dir : SHFT_DIR_T;
    end record;

    -- Declare the procedure
    procedure execute_transaction(
        test_id     : in INTEGER;
        trans       : in ALU_Transaction;
        signal op_sel   : out ALU_OP_T;
        signal src1_sel : out ALU_SRC1_T;
        signal reg1     : out std_logic_vector(31 downto 0);
        signal src2_sel : out ALU_SRC2_T;
        signal reg2     : out std_logic_vector(31 downto 0);
        signal pc       : out std_logic_vector(31 downto 0);
        signal imm      : out std_logic_vector(31 downto 0);
        signal cmp_mode : out CMP_T;
        signal shft_type: out SHFT_TYPE_T;
        signal shft_dir : out SHFT_DIR_T;
        signal alu_rslt : in std_logic_vector(31 downto 0);
        signal errors   : out boolean
    );
end ALU_TLM;

package body ALU_TLM is
    procedure execute_transaction(
        test_id     : in INTEGER;
        trans       : in ALU_Transaction;
        signal op_sel   : out ALU_OP_T;
        signal src1_sel : out ALU_SRC1_T;
        signal reg1     : out std_logic_vector(31 downto 0);
        signal src2_sel : out ALU_SRC2_T;
        signal reg2     : out std_logic_vector(31 downto 0);
        signal pc       : out std_logic_vector(31 downto 0);
        signal imm      : out std_logic_vector(31 downto 0);
        signal cmp_mode : out CMP_T;
        signal shft_type: out SHFT_TYPE_T;
        signal shft_dir : out SHFT_DIR_T;
        signal alu_rslt : in std_logic_vector(31 downto 0);
        signal errors   : out boolean
    ) is
    begin
        -- Apply inputs
        op_sel     <= trans.op;
        src1_sel   <= trans.src1;
        reg1       <= trans.s1;
        src2_sel   <= trans.src2;
        reg2       <= trans.s2;
        pc         <= trans.pc;
        imm        <= trans.imm;
        cmp_mode   <= trans.cmp_mode;
        shft_type  <= trans.shft_type;
        shft_dir   <= trans.shft_dir;

        -- Wait for ALU response
        wait for 10 ns;

        -- Compare expected vs actual
            assert unsigned(alu_rslt) = unsigned(trans.expected) 
            report "Test id: " & integer'image(test_id) & " Expected " & integer'image(to_integer(unsigned(trans.expected))) &  
                  " but got " & integer'image(to_integer(unsigned(alu_rslt))) severity error; 
            if  unsigned(alu_rslt) /= unsigned(trans.expected) then  
                errors <= true;
            end if;
    end procedure;
end ALU_TLM;
