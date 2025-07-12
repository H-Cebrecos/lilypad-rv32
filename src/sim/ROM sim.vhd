----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/31/2025 11:09:31 AM
-- Design Name: 
-- Module Name: ROM sim - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use work.pkg_components.all;

entity ROM_sim is
    --  Port ( );
end ROM_sim;

architecture Behavioral of ROM_sim is
    -- Constants
    constant CLK_PERIOD : time := 10 ns;

    -- DUT Signals
    signal clk, valid , flush, pause : std_logic := '0';
    signal addr     : std_logic_vector(9 downto 0) := (others => '0'); -- 10-bit address
    signal rom_inst : std_logic_vector(31 downto 0);
    signal inst_reg : std_logic_vector(31 downto 0):= (others => '0');
    signal rom_ce   : std_logic;

begin
  ROM_4K : boot_ROM
  PORT MAP (
    clka => clk,
    --regcea => rom_ce,
    addra => addr,
    douta => rom_inst,
    clkb => clk,
    addrb => (others => '0'),
    doutb => open
  );  

    -- Clock Generation
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;
    
    p_inst_reg: process (clk)
    begin
        if rising_edge(clk) then
            inst_reg <= rom_inst;
        end if;
    end process;
    
    process (inst_reg)
    begin
        if inst_reg = x"00100317" then
            rom_ce <= '0';
        else
            rom_ce <= '1';
        end if;
    end process;
    -- Stimulus Process
    stim_process: process
    begin
        --rom_ce <= '1';
        wait for CLK_PERIOD / 2;
        
        addr <= std_logic_vector(to_unsigned(0, 10));
        wait for CLK_PERIOD;
        addr <= std_logic_vector(to_unsigned(1, 10));
        wait for CLK_PERIOD;
        addr <= std_logic_vector(to_unsigned(2, 10));
        wait;  -- Stop simulation
    end process;

end Behavioral;
