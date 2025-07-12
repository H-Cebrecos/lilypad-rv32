--TODO: fifo breaks if the size is not a power of 2 because there is no check of that when indexing.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pkg_uart.clog2; --todo: move this to a better place?
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sync_fifo is
    Generic (
        G_FIFO_DEPTH : natural;
        G_OVERWRITE_WHEN_FULL: boolean;
        G_DATA_WIDTH : natural
    );
    Port ( 
        clk      : in std_logic;
        rst      : in std_logic;
        
        w_req    : in std_logic;
        data_i   : in std_logic_vector (G_DATA_WIDTH-1 downto 0);
        full     : out std_logic;
        overrun  : out std_logic;
        
        r_req    : in std_logic;
        data_o   : out std_logic_vector (G_DATA_WIDTH-1 downto 0);
        empty    : out std_logic;
        underrun : out std_logic
    );
end sync_fifo;

architecture Behavioral of sync_fifo is
    -- fifo --
    type fifo_type is array (0 to G_FIFO_DEPTH-1) of std_logic_vector(G_DATA_WIDTH-1 downto 0);
    constant C_PTR_SIZE : natural := clog2(G_FIFO_DEPTH);
    signal fifo     : fifo_type;
    
    signal w_ptr    : unsigned(C_PTR_SIZE downto 0); -- one bit oversize for ...
    signal r_ptr    : unsigned(C_PTR_SIZE downto 0);
    signal fill     : unsigned(C_PTR_SIZE downto 0);
    
    signal full_an  : std_logic; -- ancillary internal signal.
    signal empty_an : std_logic;
    
    signal w_en     : std_logic; -- internal enable signal.
    signal r_en     : std_logic; -- internal enable signal.
begin
    
    process (w_req, full_an)
    begin
        if G_OVERWRITE_WHEN_FULL then
            w_en <= w_req;
        else
            w_en <= w_req and not full_an;
        end if;
    end process;
    
    overrun <= w_req and full_an;
    
    r_en <= r_req and not empty_an;
    underrun <= r_req and empty_an;
    
    P_write: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
               fifo <= (others => (others => '0'));
               w_ptr <= (others => '0');
            elsif w_en = '1' then
                fifo(to_integer(w_ptr(C_PTR_SIZE-1 downto 0))) <= data_i;
                w_ptr <= w_ptr + 1;
            end if;
        end if;
    end process;
    
    P_read: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
               r_ptr <= (others => '0');
            elsif r_en = '1' then
                r_ptr <= r_ptr + 1;
            end if;
        end if;
    end process;
    data_o <= fifo(to_integer(r_ptr(C_PTR_SIZE-1 downto 0)));
    
    fill     <= w_ptr - r_ptr;
    empty_an <= '1' when fill = 0 else '0';
    full_an  <= '1' when fill = G_FIFO_DEPTH else '0';
    
    empty <= empty_an;
    full  <= full_an;
end Behavioral;
