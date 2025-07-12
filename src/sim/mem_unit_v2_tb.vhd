
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;
use work.pkg_components.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mem_unit_v2_tb is
--  Port ( );
end mem_unit_v2_tb;

architecture Behavioral of mem_unit_v2_tb is

    constant CLK_PERIOD : time := 10 ns;
    
    signal clk   : std_logic;
    signal rst   : std_logic;
    signal req   : std_logic;
    signal stall : std_logic;
    signal err   : std_logic;
    
    signal mem_op : mem_op_t;
    signal mem_sz : mem_size_t;
    
    signal reg_data : std_logic_vector (31 downto 0);
    signal mem_addr : std_logic_vector ( 1 downto 0);
    signal mem_data : std_logic_vector (31 downto 0);
    signal mem_rslt : std_logic_vector (31 downto 0);
    signal out_data : std_logic_vector (31 downto 0);
    
    signal mem_wren : std_logic_vector (3 downto 0);
    
    
begin
UUT: mem_unit port map (
    clk           => clk,
    rst           => rst,
    
    mem_operation => mem_op,
    data_size     => mem_sz,
    
    rs2_data      => reg_data,
    mem_addr      => mem_addr,
    mem_data      => mem_data,
    
    mem_rslt      => mem_rslt,
    
    write_data    => out_data,
    mem_wen       => mem_wren,
    req           => req,
    
    stall         => stall,
    address_misaligned_exception => err

);

    P_clk_gen: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;
    
    P_stimulus: process
    begin
        mem_op <= MEM_NONE;
        mem_sz <= SIZE_B;
        reg_data <= (others => '0');
        mem_data <= (others => '0');
        mem_addr <= (others => '0');
        rst <= '1';
        wait for 3 * CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD / 2;
        
        -- test stall --
        mem_op <= MEM_R;
        wait for 4 * CLK_PERIOD;
        
        mem_op <= MEM_W;
        wait for CLK_PERIOD;
        
        mem_sz <= SIZE_W;
        wait for CLK_PERIOD;
        mem_op <= MEM_NONE;
        wait;
    end process;
end Behavioral;
