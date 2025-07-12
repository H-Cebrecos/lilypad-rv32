library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_uart.all;


entity uart_tx is
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
end uart_tx;

architecture RTL of uart_tx is
    constant PARITY_BIT : natural := 0;-- when G_PARITY = NONE else 1;
    constant STOP_BITS : std_logic_vector (G_STOP_BITS-1 downto 0) := (others => '1');
    constant FRAME_SIZE : natural := (1 + G_DATA_BITS + PARITY_BIT + G_STOP_BITS);
-- Transmit pulse signals --
    signal transmit_pulse   : std_logic;
    signal division_cntr    : unsigned(TX_CNTR_SIZE-1 downto 0);
    signal clk_div_reg      : std_logic_vector (TX_CNTR_SIZE-1 downto 0);

-- Data shift register signals --
    signal data_reg         : std_logic_vector(FRAME_SIZE-1 downto 0);
    signal data_shft_reg    : std_logic_vector(FRAME_SIZE-1 downto 0);
    signal init : std_logic;
    signal stop : std_logic;
    signal parity : std_logic;
            
-- State machine signals --
    type fsm_state_type is (
        ST_IDLE,
        ST_START,
        ST_DATA,
        ST_PARITY,
        ST_STOP,
        ST_CRAZY
    );
    signal busy_internal : std_logic;
    signal last_bit : std_logic;
    signal rst_busy : std_logic;
    signal last_prev : std_logic;
    signal sm_current_state : fsm_state_type;
    signal sm_next_state    : fsm_state_type;
    signal bit_cntr : integer range 0 to FRAME_SIZE;
begin
--=========== TRANSMIT PULSE GENERATOR ==========--
    P_reg_clk_div: process (clk) -- don't change baudrate in the middle of a frame.
    begin
        if rising_edge(clk) then
            if rst = '1' or busy_internal = '0' then
                clk_div_reg <= clk_div;
            end if;
        end if;
    end process;

    P_pulse_gen: process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                division_cntr <= (others => '0');
                transmit_pulse <= '0';
            elsif division_cntr = unsigned(clk_div_reg) then
                transmit_pulse <= '1';
                division_cntr <= (others => '0');
            else
                transmit_pulse <= '0';
                division_cntr <= division_cntr + 1;
            end if;
        end if;
    end process;
--=========== END TRANSMIT PULSE GENERATOR ==========--

--=========== INPUT REGISTERS ==========--
    P_reg_data : process (clk)
    begin
        if rising_edge(clk) then
            if rst  = '1' then
                data_reg <= (others => '1');
            elsif busy_internal = '0' and valid = '1' then
                if G_PARITY = NONE then
                    data_reg <= STOP_BITS & data & '0';
                else
                    data_reg <= STOP_BITS & parity & data & '0';
                end if;
            end if;
        end if;
    end process;

    P_busy: process (clk)
    begin
        if rising_edge(clk) then
            if rst  = '1' or rst_busy = '1' then
                busy_internal <= '0';
            elsif valid = '1' then
                busy_internal <= '1';
            end if;
         end if;
    end process;
    busy <= busy_internal;
    P_init_transmission : process (clk)
    begin
        if rising_edge(clk) then
            if rst  = '1' or stop = '1' then
                init <= '0';
            elsif valid = '1' then --todo: make it so that it works with valid always asserted.
                init <= '1';
            end if;
        end if;
    end process;
--=========== END INPUT REGISTERS ==========--
 
--=========== DATA SHIFT REGISTER ==========--   
    P_parity_bit : process (data) is
    begin
        case G_PARITY is
            when MARK => 
                parity <= '1';
            when SPACE =>  
                parity <= '0';
            when EVEN =>
                parity <= xor_reduce(data);
            when ODD => 
                parity <= not xor_reduce(data);
            when others => parity <= '0'; --default value to not produce a latch, unreachable in practice.
        end case;
    end process;
    P_data_shift : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                data_shft_reg <= (others => '1');
                stop <= '0';
            elsif transmit_pulse = '1' then
                if init = '1' then
                    stop <= '1';
                    data_shft_reg <= data_reg;
                else
                    stop <= '0';
                    for i in 1 to FRAME_SIZE-1 loop
                        data_shft_reg(i-1) <= data_shft_reg(i);
                    end loop;
                end if;
            end if;
        end if;        
    end process; 
    tx <= data_shft_reg(0);
--=========== END DATA SHIFT REGISTER ==========--
 
--=========== CONTROL SIGNALS ==========--
    P_bit_cntr: process (clk, rst) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                bit_cntr <= 0;
                --rst_busy <= '0';
            elsif transmit_pulse = '1' then
                if  init = '1' or bit_cntr = FRAME_SIZE then
                    bit_cntr <= 0;
                    --rst_busy <= '1';
                else
                    bit_cntr <= bit_cntr + 1;
                    --rst_busy <= '0';
                end if;
            end if;
        end if;
    end process;
    
    last_bit <= '1' when bit_cntr = FRAME_SIZE - 1 else '0';
    rst_busy <= '1' when (last_bit = '1' and last_prev = '0') else '0';
    P_sync_pulse : process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                last_prev <= '0';
            else
                last_prev <= last_bit;
            end if;
        end if;
    end process;
--=========== END CONTROL SIGNALS ==========--
end RTL;
