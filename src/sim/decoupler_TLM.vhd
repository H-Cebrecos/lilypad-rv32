----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/19/2025 04:31:03 PM
-- Design Name: 
-- Module Name: decoupler_TLM - Behavioral
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
use IEEE.STD_LOGIC_1164;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package decoupler_TLM is
    constant CLK_PERIOD: time := 10 ns;
    type TRANSACTION_TYPE is (PAUSE, REQUEST, FLUSH);
    type EXPECTED is record
        cmd  : std_logic_vector(31 downto 0);
        data : std_logic_vector(31 downto 0);
        valid : boolean;
    end record;
    type DECOUPLER_TRANSACTION is record
        t_type : TRANSACTION_TYPE;
        cmd    : std_logic_vector(31 downto 0);
        expect : EXPECTED;
    end record;
    procedure execute_transaction(
        test_id     : in INTEGER;
        trans : in decoupler_transaction;
        signal cmd_out: in std_logic_vector(31 downto 0);
        signal dat_out: in std_logic_vector(31 downto 0);
        signal valid  : in std_logic;
        signal pause_s : out std_logic;
        signal flush_s : out std_logic;
        signal cmd_in: out std_logic_vector(31 downto 0);
        signal errors   : out boolean
    );
end decoupler_TLM;

package body decoupler_TLM is
    procedure execute_transaction(
        test_id     : in INTEGER;
        trans : in decoupler_transaction;
        signal cmd_out: in std_logic_vector(31 downto 0);
        signal dat_out: in std_logic_vector(31 downto 0);
        signal valid  : in std_logic;
        signal pause_s : out std_logic;
        signal flush_s : out std_logic;
        signal cmd_in: out std_logic_vector(31 downto 0);
        signal errors   : out boolean
    ) is
    begin
        case trans.t_type is
            when PAUSE =>
                pause_s <= '1';
                flush_s <= '0';
            when REQUEST =>
                pause_s <= '0';
                flush_s <= '0';
            when FLUSH =>
                pause_s <= '0';
                flush_s <= '1';
        end case;
        cmd_in <= trans.cmd;
        wait for CLK_PERIOD;
        if (valid = '1') /= trans.expect.valid then -- valid and trans.expect.valid have the same value.
            report "incorrect Valid signal - Test id: " & integer'image(test_id) severity error;
            errors <= true;
        end if;
        if trans.expect.valid then
            if trans.expect.cmd /= cmd_out then
                report "incorrect command - Test id: " & integer'image(test_id) severity error;
                errors <= true;
            end if;

            if trans.expect.data /= dat_out then
                report "incorrect data Test id: " & integer'image(test_id) severity error;
                errors <= true;
            end if;
        end if;
    end procedure;

end decoupler_TLM;
