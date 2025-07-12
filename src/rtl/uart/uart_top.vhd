library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_uart.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_top is
    Port (
        -- global signals --
        clk : in std_logic;
        rst : in std_logic;
        en  : in std_logic;

        write : in std_logic;
        read  : in std_logic;

        i_data  : in   std_logic_vector (7 downto 0);
        o_data  : out  std_logic_vector (31 downto 0);

        reg_addr: in   std_logic_vector (7 downto 0);

        -- UART signals --
        rx              : in std_logic;
        tx              : out std_logic
    );
end uart_top;

architecture Behavioral of uart_top is

    constant G_DATA_BITS : natural := 8;
    
    constant C_BR_DIV : natural := (50_000_000/115200);
    constant br       : std_logic_vector(TX_CNTR_SIZE -1 downto 0) := std_logic_vector(to_unsigned(C_BR_DIV, TX_CNTR_SIZE));
    signal fifo_wr    : std_logic;
    signal data_sel   : std_logic;

    -- rx fifo --
    signal rx_full    : std_logic;
    signal rx_empty   : std_logic;
    signal rx_overrun : std_logic;
    signal rx_r_req   : std_logic;
    signal rx_data_o  : std_logic_vector (G_DATA_BITS-1 downto 0);
    signal write_s    : std_logic;
    signal write_prev : std_logic;
    signal read_s     : std_logic;
    signal read_prev  : std_logic;

    -- tx fifo --
    signal tx_full    : std_logic;
    signal tx_empty   : std_logic;
    signal tx_r_req   : std_logic;
    signal tx_data_o  : std_logic_vector (G_DATA_BITS-1 downto 0);
    signal tx_w_req   : std_logic;
    signal data  : std_logic_vector (G_DATA_BITS-1 downto 0);

    -- UART signals --
    signal rx_valid   : std_logic;
    signal rx_data    : std_logic_vector (G_DATA_BITS-1 downto 0);
    signal busy       : std_logic;
begin


    data_sel <= '1' when reg_addr = x"00" else '0';

    o_data <= x"000000" & data;


    P_reg:process(clk) -- this process registers the output after a read as the core expects the result with some latency.
    begin
        if rising_edge(clk) then
            if rst = '1' then
                data <= x"00";
            elsif read_s = '1' then
                if reg_addr = x"00" then
                    data <= rx_data_o;
                else
                    data <= x"0" & tx_full & tx_empty & rx_full & rx_empty;
                end if;
            end if;
        end if;
    end process;
    
    P_wr_addr_dec : process (reg_addr)
    begin
        case reg_addr is
            when x"04" =>
                fifo_wr <= '1';
            when others =>
                fifo_wr <= '0';
        end case;
    end process;

    write_s <= '1' when (write = '1' and write_prev = '0') else '0';
    read_s  <= '1' when (read  = '1' and read_prev  = '0') else '0';
    P_sync_pulse : process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                write_prev <= '0';
                read_prev <= '0';
            else
                write_prev <= write;
                read_prev <= read;
            end if;
        end if;
    end process;
    tx_w_req <= en and fifo_wr and write_s;
    rx_r_req <= en and read_s and data_sel;
--    --========== FIFOS ===============--
    rx_fifo : sync_fifo
        generic map (
            G_FIFO_DEPTH => 512,
            G_OVERWRITE_WHEN_FULL => FALSE,
            G_DATA_WIDTH => G_DATA_BITS
        )
        port map (
            clk      => clk,
            rst      => rst,
            w_req    => rx_valid,
            data_i   => rx_data,
            full     => rx_full,
            overrun  => rx_overrun,
            r_req    => rx_r_req,
            data_o   => rx_data_o,
            empty    => rx_empty,
            underrun => open
        );
 
    tx_r_req <= not (busy or tx_empty);
    tx_fifo : sync_fifo
        generic map (
            G_FIFO_DEPTH => 16,
            G_OVERWRITE_WHEN_FULL => FALSE,
            G_DATA_WIDTH => G_DATA_BITS
        )
        port map (
            clk      => clk,
            rst      => rst,
            w_req    => tx_w_req,
            data_i   => i_data,
            full     => tx_full,
            overrun  => open,
            r_req    => tx_r_req,
            data_o   => tx_data_o,
            empty    => tx_empty,
            underrun => open
        );
    


    RX_UART : uart_rx
        port map(
            clk	=> clk,
            rst	=> rst,
            clk_div => br(TX_CNTR_SIZE-1 downto 4),
            rx	=> rx,
            data	=> rx_data,
            valid	=> rx_valid,
            frame_err	=> open,
            parity_err	=> open
        );

    TX_UART: uart_tx
        port map(
            clk	=> clk,
            rst	=> rst,
            clk_div => br,
            tx	=> tx,
            data	=> tx_data_o,
            valid	=> tx_r_req,
            busy	=> busy
        );
end Behavioral;
