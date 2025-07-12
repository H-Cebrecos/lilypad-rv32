----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/09/2025 06:14:56 PM
-- Design Name: 
-- Module Name: mem_integration - Behavioral
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
use work.types.all;
use work.pkg_components.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mem_integration is
--  Port ( );
end mem_integration;

architecture Behavioral of mem_integration is
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
    
    constant NB_COL     : integer := 4;
    constant COL_WIDTH  : integer := 8;
    constant ADDR_WIDTH : integer := 12;

    signal wea        : std_logic_vector(NB_COL-1 downto 0);
    signal addra      : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal dia        : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);
    signal doa        : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);

    signal enb        : std_logic;
    signal web        : std_logic_vector(NB_COL-1 downto 0);
    signal addrb      : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal dib        : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);
    signal dob        : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);
-- Registered inputs
    signal wea_r, web_r         : std_logic_vector(NB_COL-1 downto 0);
    signal addra_r, addrb_r     : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal dia_r, dib_r         : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);
    signal enb_r                : std_logic;
begin

UUT1: mem_unit port map (
    clk           => clk,
    rst           => rst,
    
    mem_operation => mem_op,
    data_size     => mem_sz,
    
    rs2_data      => reg_data,
    mem_addr      => addrb_R(1 downto 0),
    mem_data      => mem_data,
    
    mem_rslt      => mem_rslt,
    
    write_data    => out_data,
    mem_wen       => mem_wren,
    req           => req,
    
    stall         => stall,
    address_misaligned_exception => err

);
-- Register inputs synchronously
    reg_inputs : process(clk)
    begin
        if rising_edge(clk) then
            --wea_r    <= wea;
            addra_r  <= addra;
            dia_r    <= dia;
            --web_r    <= web;
            addrb_r  <= addrb;
            dib_r    <= dib;
            enb_r    <= enb;
        end if;
    end process;

    -- Instantiate RAM 
    uut2 : system_ram
        port map (
            clka  => clk,
            wea   => (others => '0'),
            addra => addra_r,
            dia   => (others => '0'),
            doa   => doa,
            web   => mem_wren,
            addrb => "00" & addrb_r(ADDR_WIDTH-1 downto 2),
            dib   => out_data,
            dob   => mem_data
        );

    P_clk_gen: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;
    
    P_stim: process
    begin
        rst <= '1';
        addrb <= std_logic_vector(to_unsigned(0, ADDR_WIDTH));
        addra <= std_logic_vector(to_unsigned(0, ADDR_WIDTH));
        mem_op <= MEM_NONE;
        reg_data <= x"AABBCCDD";
        wait for 3.5 * CLK_PERIOD;
        rst <= '0';
        mem_op <= MEM_W;
        mem_sz <= SIZE_W;
        wait for CLK_PERIOD;
        addrb <= std_logic_vector(to_unsigned(1, ADDR_WIDTH));
        mem_op <= MEM_NONE;
        wait for 4 * CLK_PERIOD;
        mem_op <= MEM_R;
        mem_sz <= SIZE_W;
        addrb <= std_logic_vector(to_unsigned(0, ADDR_WIDTH));
        wait for 3 * CLK_PERIOD;
        addrb <= std_logic_vector(to_unsigned(1, ADDR_WIDTH));
        wait for 3 * CLK_PERIOD;
        addrb <= std_logic_vector(to_unsigned(2, ADDR_WIDTH));
        wait for 3 * CLK_PERIOD;
        addrb <= std_logic_vector(to_unsigned(3, ADDR_WIDTH));
        wait for 3 * CLK_PERIOD;
        wait;
    end process;
end Behavioral;
