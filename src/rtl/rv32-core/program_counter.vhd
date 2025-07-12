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

use work.pkg_types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.NUMERIC_STD_UNSIGNED.ALL; -- Using VHDL 2008 features.


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fetch_unit is
    generic (
        RESET_VECTOR : STD_LOGIC_VECTOR (31 downto 0) := (others => '0')
    );
    Port (
        -- Sequential logic inputs.
        clk         : in STD_LOGIC;                             -- clock signal. 
        rst         : in STD_LOGIC;                             -- reset, sets PC pointing to RESET_VECTOR. !! Should not be desasserted in a clk rising edge.
        valid       : in STD_LOGIC;                             -- indicates if the data is valid.

        stall       : in std_logic;

        -- Next address computation selection and data.
        next_pc_src : in PC_SRC_T;                              -- selects whether the next address comes from incrementing the PC or from the ALU.
        alu_addr    : in STD_LOGIC_VECTOR (31 downto 1);        -- result from computing a branch target address in the ALU.
        cmp_rslt    : in STD_LOGIC;                             -- result of the logic comparison, determines whether to branch or not.
        is_branch   : in STD_LOGIC;                             -- indicates if the current instruction is a conditional branch, in which case cmp_rslt overrides next_pc_src.

        -- Instruction read from decoupler (or memory).
        inst_data   : in STD_LOGIC_VECTOR (31 downto 0);        -- instruction data read from memory, not the same as the requested instruction due to lantency.
        inst_addr   : in STD_LOGIC_VECTOR (31 downto 0);        -- address of the currently executing instruction. Corresponds to the traditionally called program counter.

        -- Outputs
        fetch_addr      : out STD_LOGIC_VECTOR (31 downto 0);   -- address of the next instruction to be fetched.

        -- Downstream outputs --
        next_inst_addr  : out STD_LOGIC_VECTOR (31 downto 0);   -- address of the subsecuent instruction in memory.
        current_inst    : out STD_LOGIC_VECTOR (31 downto 0);   -- instruction data of the current PC.
        current_addr    : out STD_LOGIC_VECTOR (31 downto 0);

        -- Decoupler control
        flush : out std_logic;
        pause : out std_logic;

        instruction_address_misaligned_exception : out STD_LOGIC
    );
end fetch_unit;

architecture Behavioral of fetch_unit is
    -- After a reset the fetch unit starts fetching addresses in order each cycle, if the currently executing instruction indicates that a branch is taken
    -- the module flushes the incomming data buffers and branches to the correct address. if an instruction must pause execution the fetch unit stops fetching
    -- for the appropiate number of cycles and asserts the pause signal.

    -- Fetch pointer resgister. Address of the instruction just fetched.
    -- If memory has no latency then the currently executing instrucction is the one at the fetched address, the fetch pointer corresponds to the program counter.
    signal fetch_ptr_reg : STD_LOGIC_VECTOR (31 downto 0);

    -- Intermediate values

    signal branch_addr  : STD_LOGIC_VECTOR (31 downto 0);
    --signal next_addr    : STD_LOGIC_VECTOR (31 downto 0);
    --signal j_flush      : STD_LOGIC;  -- indicates if we must flush due to a taken branch.
    --signal reset_guard  : STD_LOGIC;  -- synchronous signal to avoid outputing data before the first cycle after a reset.
    --signal paused       : STD_LOGIC;


    signal inst_reg : std_logic_vector (31 downto 0); -- downstream signals are registered to prevent comb. loops and reduce critcal path length.
    signal addr_reg : std_logic_vector (31 downto 0);
    signal next_reg : std_logic_vector (31 downto 0);

    signal jump : std_logic;


    

begin

    P_register_outputs: process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                inst_reg <= NOP;
                addr_reg <= RESET_VECTOR;
                next_reg <= RESET_VECTOR + 4;
            elsif stall = '0' then -- if the core is stalled the PC maintains its outputs untill the stall is resolved.
                if valid = '1' and jump = '0' then
                    inst_reg <= inst_data;
                    addr_reg <= inst_addr;
                    next_reg <= inst_addr + 4;
                else
                    inst_reg <= NOP;
                end if;
            end if;
        end if;
    end process;
    current_inst   <= inst_reg;
    current_addr   <= addr_reg;
    next_inst_addr <= next_reg;

    jump <= '1' when (is_branch = '1' and cmp_rslt = '1') or next_pc_src = PC_SRC_ALU_RSLT else '0';
    flush <= jump;
    pause <= stall;
    -- Align branch address acording to the spec (see: section 2.5.1, page 28 of the The RISC-V Instruction Set Manual Volume I Unprivileged Architecture Version 20240411 
    -- "the target address is obtained by adding the sign-extended 12-bit I-immediate to the register rs1, then setting the least-significant bit of the result to zero." )
    branch_addr <= alu_addr & '0';

    P_fetch_pointer: process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fetch_ptr_reg <= RESET_VECTOR;
            else
                if jump = '1'  then --maybe other conditions too.
                    fetch_ptr_reg <= branch_addr;
                --flush.
                else
                    if stall = '0' then
                        fetch_ptr_reg <= fetch_ptr_reg + 4;
                    end if;
                end if;
            end if;
        end if;
    end process;
    fetch_addr <= fetch_ptr_reg;

    -- Raise an execption if the next instruction is not aligned to a 4 Byte boundary, as this core doesn't implement the compressed extension.
    instruction_address_misaligned_exception <= '1' when addr_reg(1 downto 0) /= "00" else '0'; -- TODO: check the standar to see if it is raised at execution or at fetch.

end Behavioral;
