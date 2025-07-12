library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


package pkg_uart is
    type parity_type is (NONE, ODD, EVEN, MARK, SPACE);

    function xor_reduce(v : std_logic_vector) return std_logic;
    function check_parity(v : std_logic_vector; parity: parity_type) return boolean;
    function clog2(x : natural) return natural;

    constant CLK_FREQ   : natural := 50_000_000;
    constant MIN_BAUD   : natural := 115200;
    constant OVERSAMPLE : natural := 16;

    constant RX_CNTR_SIZE : natural := clog2((CLK_FREQ / (MIN_BAUD * OVERSAMPLE)));
    constant TX_CNTR_SIZE : natural := clog2((CLK_FREQ / (MIN_BAUD))); -- The value is 16 times larger so rx size is 4 bits less than tx size.


    component uart_rx is
        Generic(
            G_DATA_BITS   : natural := 8;
            G_PARITY      : parity_type := NONE;
            G_STOP_BITS   : natural range 1 to 2 := 1
        );
        Port (
            clk: in std_logic;
            rst: in std_logic;
            clk_div : in std_logic_vector(RX_CNTR_SIZE-1 downto 0);
            rx : in std_logic; -- different clock domain.

            data : out std_logic_vector(G_DATA_BITS-1 downto 0);
            valid: out std_logic;
            frame_err : out std_logic;
            parity_err: out std_logic
        );
    end component;

    component async_bit_capture is

        Port (
            clk: in std_logic;
            rst: in std_logic;
            clk_div : in std_logic_vector(RX_CNTR_SIZE-1 downto 0);
            rx : in std_logic; -- different clock domain.

            valid_pulse : out std_logic;
            sampled_bit : out std_logic
        );
    end component;

    component uart_tx is
        Generic(
            G_DATA_BITS   : natural := 8;
            G_PARITY      : parity_type := NONE;
            G_STOP_BITS   : natural range 1 to 2 := 1
        );
        Port (
            clk: in std_logic;
            rst: in std_logic;
            clk_div : in std_logic_vector(TX_CNTR_SIZE-1 downto 0);
            data : in std_logic_vector(G_DATA_BITS-1 downto 0);
            valid: in std_logic;

            busy : out std_logic;
            tx : out std_logic
        );
    end component;
    
    component sync_fifo is
    generic (
        G_FIFO_DEPTH : natural;
        G_OVERWRITE_WHEN_FULL: boolean;
        G_DATA_WIDTH : natural
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;

        w_req    : in  std_logic;
        data_i   : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
        full     : out std_logic;
        overrun  : out std_logic;

        r_req    : in  std_logic;
        data_o   : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
        empty    : out std_logic;
        underrun : out std_logic
    );
end component;
end package;

package body pkg_uart is

    function xor_reduce(v : std_logic_vector) return std_logic is
        variable v_reduce : std_logic := '0';
    begin
        for i in v'range loop
            v_reduce := v_reduce xor v(i);
        end loop;
        return v_reduce;
    end function;
   
    function check_parity(v : std_logic_vector; parity: parity_type) return boolean is
        variable v_reduce : std_logic := '0';
    begin
        v_reduce := xor_reduce(v);

        case parity is
            when NONE  => return true;
            when ODD   => return v_reduce   = '1';
            when EVEN  => return v_reduce   = '0';
            when MARK  => return v(v'low) = '1';
            when SPACE => return v(v'low) = '0';
        end case;
    end function;

    function clog2(x : natural) return natural is
        variable res : natural := 0;
        variable tmp : natural := x - 1;
    begin
        while tmp > 0 loop
            res := res + 1;
            tmp := tmp / 2;
        end loop;
        return res;
    end function;
end package body;

