----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/17/2025 02:26:24 PM
-- Design Name: 
-- Module Name: top_tb - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_tb is
    --  Port ( );
end top_tb;

architecture Behavioral of top_tb is

    constant ROM_ADDR : std_logic_vector(31 downto 0) := x"00000000";
    constant RAM_ADDR : std_logic_vector(31 downto 0) := x"00010000";
    signal ram_data_addr  : std_logic;
    signal rom_data_addr  : std_logic;
    signal ram_inst_addr  : std_logic;
    signal rom_inst_addr  : std_logic;
     signal clk, reset, req : STD_LOGIC;
     signal ram_data_en , locked, rom_data_en: STD_LOGIC;
     --signal addra, addrb, douta, inst_mux, mem_data, write_data : STD_LOGIC_VECTOR(31 downto 0);
     signal sim_done   : boolean := false;
         signal ram_data  : std_logic_vector (31 downto 0);
             signal mem_wen, wen_mux : STD_LOGIC_VECTOR(3 downto 0);
    signal rom_data  : std_logic_vector (31 downto 0);
     signal addra, inst_mux, ram_inst, rom_inst, mem_addr, mem_data, write_data : STD_LOGIC_VECTOR(31 downto 0);
begin
    rom_inst_addr  <= '1' when addra(31 downto 11) = ROM_ADDR(31 downto 11) else '0';
    rom_data_addr  <= '1' when mem_addr(31 downto 11) = ROM_ADDR(31 downto 11) else '0';
    ram_inst_addr <= '1' when    addra(31 downto 14) = RAM_ADDR(31 downto 14) else '0';
    ram_data_addr <= '1' when mem_addr(31 downto 14) = RAM_ADDR(31 downto 14) else '0';
    CPU1: core port map(
            clk => clk,
            reset => reset,
            inst_addr => addra,
            instruction => inst_mux,
            
            mem_addr => mem_addr,
            mem_data => mem_data,
            write_data => write_data,               
            mem_wen => mem_wen,
            debug => open,
            cpc => open,
            req => req
        );
    BOOT : boot_ROM
        PORT MAP (
            clka => clk,
           
            addra => addra(10 downto 2),
            douta => rom_inst,
            clkb => clk,

            addrb => mem_addr(10 downto 2),
            doutb => rom_data
        );
        ram_data_en <= req and ram_data_addr;
    RAM_16K: system_RAM
    PORT MAP (
      clka => clk,
      wea => "0000",
      addra => addra(13 downto 2),
      dia => x"00000000",
      doa => ram_inst,
      web => wen_mux,
      addrb => mem_addr(13 downto 2),
      dib => write_data,
      dob => ram_data
    );
    
        P_wen_mux : process (ram_data_addr, mem_wen)
    begin
        if ram_data_addr = '1' then
            wen_mux <= mem_wen;
        else
            wen_mux <= (others => '0');
        end if;
    end process;
    P_data_bus_mux : process (ram_data_addr, rom_data_addr, ram_data, rom_data)
    begin
        if rom_data_addr = '1' then
            mem_data <= rom_data;
        elsif ram_data_addr = '1' then
            mem_data <= ram_data;
        else
            mem_data <= (others => '0');
        end if;
    end process;
    
    P_inst_bus_mux : process (ram_inst_addr, rom_inst_addr, ram_inst, rom_inst)
    begin
        if rom_inst_addr = '1' then
            inst_mux <= rom_inst;
        elsif ram_inst_addr = '1' then
            inst_mux <= ram_inst;
        else
            inst_mux <= (others => '0');
        end if;
    end process;
    -- Clock generation.
    clk_process : process
    begin
        while not sim_done loop
            clk <= '0';
            wait for 5 ns; -- 50 MHz clock
            clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process;

    -- Reset assertion.
    reset_process : process
    begin
        reset <= '1';
        wait for 30 ns;
        reset <= '0';
        wait;
    end process;
    -- Testbench process.
    tb_process : process
    begin
        -- Allow some time for the simulation to run.
        wait for 20000000 ns;
        sim_done <= true; -- End simulation after ~10 clock cycles.
        wait;
    end process;
end Behavioral;
