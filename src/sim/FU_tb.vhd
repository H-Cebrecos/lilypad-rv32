----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/30/2025 01:37:04 PM
-- Design Name: 
-- Module Name: FU_tb - Testbench
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
use work.types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FU_tb is
    --  Port ( );
end FU_tb;

architecture Testbench of FU_tb is
    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic;
    signal rst : std_logic;
    signal val : std_logic;

    signal stall : std_logic;
    signal stall_r : std_logic;
    signal pause : std_logic;
    signal flush : std_logic;
    
    signal cmp : std_logic;
    signal brnch : std_logic;
    
    signal pc_src : PC_SRC_T;
    
    signal inst : std_logic_vector (31 downto 0);
    signal del1 : std_logic_vector (31 downto 0);
    signal del2 : std_logic_vector (31 downto 0);
    signal fetch : std_logic_vector (31 downto 0);
    signal nxt : std_logic_vector (31 downto 0);
    signal pc : std_logic_vector (31 downto 0);
    signal i_reg : std_logic_vector (31 downto 0);
    signal mem_inst : std_logic_vector (31 downto 0);
    signal mem_addr : std_logic_vector (31 downto 0);
begin
    UUT: fetch_unit port map (
            clk => clk,
            rst => rst,
            valid => val,
            stall => stall_r,
            next_pc_src => pc_src,
            alu_addr => (others => '0'),
            cmp_rslt => cmp,
            is_branch => brnch,
            
            inst_data => inst,
            inst_addr => mem_addr,
            
            fetch_addr => fetch,

            next_inst_addr => nxt,
            current_inst   => i_reg,
            current_addr   => pc,

            flush => flush,
            pause => pause,

            instruction_address_misaligned_exception => open
        );
        
        pip_dec : pipeline_decoupler
        generic map (
            LATENCY    => 2,
            COMMAND_WIDTH => 32,
            DATA_WIDTH => 32
        )
        port map (
            clk      => clk,
            rst      => rst,
            flush    => flush,
            pause   => pause,
            cmd_in  => fetch,
            data_in => mem_inst,

            valid    => val,
            cmd_out => mem_addr,
            data_out => inst
        );

    P_clk_gen: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;
    
    
    P_latency_sim: process(clk)
    begin
        if rising_edge(clk) then
            stall_r <= stall; 
            del1 <= fetch;
            --del2 <= del1;
            mem_inst <= del1;
        end if;
    end process;
    
    P_stimulus: process
    begin
        stall <= '0';
        brnch <= '0';
        cmp <= '0';
        pc_src <= PC_SRC_ADD_RSLT;
        
        rst <= '1';
        wait for 3 * CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD / 2;

        -- jump
        wait for 5 * CLK_PERIOD;
        pc_src <= PC_SRC_ALU_RSLT;
        wait for CLK_PERIOD;
        pc_src <= PC_SRC_ADD_RSLT;
        
        -- load
        wait for 7 * CLK_PERIOD;
        stall <= '1';
        wait for CLK_PERIOD;
        stall <= '0';
        wait;
    end process;
end Testbench;
