----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/19/2025 04:16:42 PM
-- Design Name: 
-- Module Name: decoupler_tb - Behavioral
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
use work.decoupler_TLM.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity decoupler_tb is
    --  Port ( );
end decoupler_tb;

architecture Behavioral of decoupler_tb is

    -- DUT Signals
    signal clk, valid , flush_s, pause_s : std_logic := '0';
    signal addr, adj_addr   : std_logic_vector(31 downto 0) := (others => '0');
    signal data, data_o, data_mem   : std_logic_vector(31 downto 0); -- 32-bit output data
    signal error_flag: boolean := false;
    component pipeline_decoupler is
        Generic (
            LATENCY         : integer;
            DATA_WIDTH      : integer;
            COMMAND_WIDTH   : integer
        );
        Port (
            clk      : in STD_LOGIC;
            flush    : in STD_LOGIC;
            pause    : in STD_LOGIC;
            cmd_in   : in STD_LOGIC_VECTOR (COMMAND_WIDTH-1 downto 0);
            data_in  : in STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);

            valid    : out STD_LOGIC;
            cmd_out : out STD_LOGIC_VECTOR (COMMAND_WIDTH-1 downto 0);
            data_out : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)
        );
    end component;

begin
    uut : pipeline_decoupler
        generic map (
            LATENCY    => 3,   -- Set the required latency cycles
            COMMAND_WIDTH => 32,
            DATA_WIDTH => 32         -- Set the width of data
        )
        port map (
            clk      => clk,          -- Connect to system clock
            flush    => flush_s,        -- Connect to flush control signal
            pause    => pause_s,        -- Pause signal added
            cmd_in   => addr,         -- Connect to data source
            data_in  => data,

            valid    => valid,        -- Connect to valid output signal
            cmd_out  => adj_addr,     -- Connect to data destination
            data_out => data_o
        );

    process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;
    process
        type Decoupler_Transaction_Array is array (natural range <>) of decoupler_Transaction;

        constant transactions : Decoupler_Transaction_Array := (
            -- type     addr in        addr out    data out     valid
            (REQUEST,   X"00000000", (X"00000000", X"00000000", false)), --0   -- a few cycles of normal operation.
            (REQUEST,   X"00000001", (X"00000000", X"00000000", false)), --1 
            (REQUEST,   X"00000002", (X"00000000", X"00000000", true)),  --2 
            (REQUEST,   X"00000003", (X"00000001", X"00000001", true)),  --3 
            (FLUSH,     X"00000000", (X"00000000", X"00000000", false)), --4   -- flush operation to check full recovery.
             
            (REQUEST,   X"00000001", (X"00000000", X"00000000", false)), --5
            (REQUEST,   X"00000002", (X"00000000", X"00000000", true)),  --6 
            (REQUEST,   X"00000003", (X"00000001", X"00000001", true)),  --7 
             
            (PAUSE,     X"00000000", (X"00000000", X"00000000", false)), --8   -- very long pause.
            (PAUSE,     X"00000000", (X"00000000", X"00000000", false)), --9 
            (PAUSE,     X"00000000", (X"00000000", X"00000000", false)), --10
            (PAUSE,     X"00000000", (X"00000000", X"00000000", false)), --11
            (PAUSE,     X"00000000", (X"00000000", X"00000000", false)), --12
            (PAUSE,     X"00000000", (X"00000000", X"00000000", false)), --13
            
            (REQUEST,   X"00000004", (X"00000002", X"00000002", true)),  --14  -- should recover where it left.
            (REQUEST,   X"00000005", (X"00000003", X"00000003", true)),  --15
            (REQUEST,   X"00000006", (X"00000004", X"00000004", true)),  --16
            
            (PAUSE,     X"00000000", (X"00000000", X"00000000", false)), --17  -- short pause.
            
            (REQUEST,   X"00000007", (X"00000005", X"00000005", true)),  --18
            (REQUEST,   X"00000008", (X"00000006", X"00000006", true)),  --19
            (REQUEST,   X"00000009", (X"00000007", X"00000007", true))   --20                                                                 
        );
    begin
        for i in transactions'range loop
            execute_transaction(i, transactions(i), adj_addr, data_o, valid, pause_s, flush_s, addr, error_flag);

        end loop;
        -- Final result check
        if error_flag then
            report "TEST FAILED!" severity error;
        else
            report "ALL TESTS PASSED" severity note;
        end if;
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
            pipeline(0) := addr;  -- New request enters the pipeline

            -- Output the third stage
            data <= pipeline(2);
        end if;
    end process;
end Behavioral;
