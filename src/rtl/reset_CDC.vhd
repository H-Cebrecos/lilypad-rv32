library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity reset_CDC is
    Port ( sys_clk   : in STD_LOGIC;
           async_rst : in STD_LOGIC;
           sync_rst  : out STD_LOGIC);
end reset_CDC;

architecture Behavioral of reset_CDC is
    --signal btn_meta  : std_logic := '0'; -- First stage to resolve metastability
    signal btn_reg   : std_logic := '0'; -- Second stage, stable output

    -- Mark the registers as part of an asynchronous synchronizer chain
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of btn_reg, sync_rst : signal is "TRUE";
begin
process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            btn_reg  <= async_rst;
            sync_rst <= btn_reg;
        end if;
    end process;

end Behavioral;
