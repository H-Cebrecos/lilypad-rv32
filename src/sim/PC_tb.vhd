----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/24/2025 05:52:26 PM
-- Design Name: 
-- Module Name: PC_tb - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.types.all;

entity PC_tb is
    --  Port ( );
end PC_tb;

architecture Behavioral of PC_tb is
    component program_counter
        generic (
            RESET_VECTOR : STD_LOGIC_VECTOR (31 downto 0) := (others => '0')
        );
        Port (
            -- Sequential logic inputs.
            clk         : in STD_LOGIC;                             -- clock signal. 
            reset       : in STD_LOGIC;                             -- synchronous reset, sets PC pointing to RESET_VECTOR.
            valid       : in STD_LOGIC;                             -- indicates if the data is valid.

            -- Next address computation selection and data.
            next_pc_src : in PC_SRC_T;                              -- selects whether the next address comes from incrementing the PC or from the ALU.
            alu_rslt    : in STD_LOGIC_VECTOR (31 downto 1);        -- result from computing a branch target address in the ALU.
            cmp_rslt    : in STD_LOGIC;                             -- result of the logic comparison, determines whether to branch or not.
            is_branch   : in STD_LOGIC;                             -- indicates if the current instruction is a conditional branch, in which case cmp_rslt overrides next_pc_src.
            is_load     : in STD_LOGIC;                             -- indicates if the current instruction is a load operation, in which case we pause for the necesary cycles.
            -- instruction read from decoupler (or memory).
            inst_data   : in STD_LOGIC_VECTOR (31 downto 0);        -- instruction data read from memory, not the same as the requested instruction due to lantency.
            --inst_addr   : in STD_LOGIC_VECTOR (31 downto 0);        -- address of the incoming instruction data.

            -- Outputs
            --current_pc      : out STD_LOGIC_VECTOR (31 downto 0);   -- address of the current instruction beign decoded.
            next_inst_addr  : out STD_LOGIC_VECTOR (31 downto 0);   -- address of the subsecuent instruction in memory.
            fetch_addr         : out STD_LOGIC_VECTOR (31 downto 0);   -- address of the next instruction to be fetched.
            instruction_address_misaligned_exception : out STD_LOGIC;
            current_inst    : out STD_LOGIC_VECTOR (31 downto 0);   -- instruction data of the current PC.

            -- Decoupler control
            flush : out std_logic;
            pause : out std_logic
        );
    end component;
    signal clk, valid , flush, pause, reset : std_logic := '0';
    signal is_branch, is_load, cmp_rslt: std_logic;

    signal inst_data, cmd_out : std_logic_vector (31 downto 0);
    signal fetch_addr, next_inst_addr, current_inst, current_pc : std_logic_vector (31 downto 0);
    signal next_pc_src : PC_SRC_T;

    signal alu_rslt : std_logic_vector (31 downto 1) := (others => '0');
    constant CLK_PERIOD: time := 10 ns;
begin
    PC: program_counter port map(
            -- Inputs.
            clk         => clk,
            reset       => reset,
            valid       => valid,

            next_pc_src => next_pc_src,
            alu_rslt    => alu_rslt(31 downto 1),
            cmp_rslt    => cmp_rslt,
            is_branch   => is_branch,
            is_load     => is_load,

            inst_data   => inst_data,
            --inst_addr   => current_inst,
            -- Outputs.
            --current_pc      => current_pc,
            next_inst_addr  => next_inst_addr,
            fetch_addr         => fetch_addr,
            instruction_address_misaligned_exception => open,
            current_inst => current_inst,

            pause => pause,
            flush => flush
        );

    --Things to test:
    --normal operation.
    --inconditional jump
    --not taken branch
    --taken branch
    --correct pause on a load.
    --(LOAD, req_addr)
    --(NORM, req_addr)
    --(JUMP, req_addr)
    --(BRAN, req_addr)
    --(RST , req_addr)
    process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    test: process
    begin
        reset <= '1';
        is_branch <= '0';
        is_load <= '0';
        cmp_rslt <= '0';
        valid <= '1';
        next_pc_src <= PC_SRC_ADD_RSLT;
        wait for CLK_PERIOD * 3;
        reset <= '0';
        wait for CLK_PERIOD * 2 + CLK_PERIOD/2;
        -- KNOWN ERROR.
        reset <= '1';
        wait for CLK_PERIOD * 5;
        reset <= '0';
        wait for CLK_PERIOD * 5;
        is_branch <= '1';
        cmp_rslt <= '1';
        wait for CLK_PERIOD;
         is_branch <= '0';
        cmp_rslt <= '0'; 
        wait for CLK_PERIOD;
        next_pc_src <= PC_SRC_ALU_RSLT;
        wait for CLK_PERIOD;  
        next_pc_src <= PC_SRC_ADD_RSLT;
        wait for CLK_PERIOD;  
        is_load <= '1';
        valid <= '0';
        wait for CLK_PERIOD * 3; 
        is_load <= '0';
        valid <= '1';
        wait for CLK_PERIOD * 3; 
        is_load <= '1';
        valid <= '0';
        wait;
    end process;

    mock_rom : process (clk)
        type Pipeline_T is array (0 to 2) of std_logic_vector(31 downto 0);
        variable pipeline : Pipeline_T := (others => (others => '0'));
    begin
        if rising_edge(clk) then
            -- Shift pipeline
            pipeline(2) := pipeline(1);
            pipeline(1) := pipeline(0);
            pipeline(0) := fetch_addr;  -- New request enters the pipeline

            -- Output the third stage
            inst_data <= pipeline(2);
        end if;
    end process;

end Behavioral;
