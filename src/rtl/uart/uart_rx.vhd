library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.pkg_uart.all;

entity uart_rx is
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
end uart_rx;


architecture RTL of uart_rx is
    -- Bit capture signals --
    signal sampled_bit : std_logic;
    signal valid_pulse : std_logic;

    -- Data register signals --
    signal data_shft_reg : std_logic_vector (G_DATA_BITS-1 downto 0);
    signal data_region : std_logic;

    -- State machine signals --
    type fsm_state_type is (
        ST_IDLE,
        ST_DATA,
        ST_PARITY,
        ST_STOP1,
        ST_STOP2,
        ST_CRAZY
    );
    signal sm_current_state : fsm_state_type;
    signal sm_next_state    : fsm_state_type;
    signal bit_cntr : integer range 0 to G_DATA_BITS-1;
    signal rst_bit_cntr : std_logic;
    signal data_parity : std_logic;
    signal error     : std_logic;

    -- Ouput pulse signals --
    signal data_valid   : std_logic;
    signal data_prev    : std_logic;
    signal frame_error  : std_logic;
    signal frame_prev   : std_logic;
    signal parity_error : std_logic;
    signal parity_prev  : std_logic;

begin


--=========== BIT CAPTURE ==========--
    bit_capture : async_bit_capture
        port map (
            clk => clk,
            rst => rst,
            clk_div => clk_div,
            rx => rx,
            valid_pulse => valid_pulse,
            sampled_bit => sampled_bit
        );
--=========== END BIT CAPTURE ==========--

--=========== DATA REGISTER ==========--
    P_register_data: process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                data_shft_reg <= (others => '0');
            -- valid_pulse and data_region used as clock enable.
            elsif  valid_pulse = '1' and data_region = '1' then
                -- register data bit. (UART transmits in LSB first)
                data_shft_reg(G_DATA_BITS-1) <= sampled_bit;
                for i in G_DATA_BITS-2 downto 0 loop
                    data_shft_reg(i) <= data_shft_reg(i+1);
                end loop;
            end if;
        end if;
    end process;

    data <= data_shft_reg;
--=========== END DATA REGISTER ==========--

--=========== STATE MACHINE ==========--
    P_fsm_synchronous: process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sm_current_state <= ST_IDLE;
            -- valid_pulse used as clock enable
            elsif valid_pulse = '1' then
                sm_current_state <= sm_next_state;
            end if;
        end if;
    end process;

    data_parity <= xor_reduce(data_shft_reg);

    P_fsm_comb: process(sm_current_state, sampled_bit, bit_cntr, data_parity, error) is
    begin
        -- default values.
        parity_error <= '0';
        frame_error  <= '0';
        data_valid   <= '0';
        data_region  <= '0';
        rst_bit_cntr <= '0';

        case sm_current_state is
            when ST_IDLE =>
                rst_bit_cntr <= '1';
                if sampled_bit = '0' then
                    sm_next_state <= ST_DATA;
                else
                    sm_next_state <= ST_IDLE;
                end if;
            when ST_DATA =>
                data_region <= '1';
                if bit_cntr = G_DATA_BITS-1 then
                    if G_PARITY = NONE then
                        sm_next_state <= ST_STOP1;
                        --rst_bit_cntr <= '1';
                    else
                        sm_next_state <= ST_PARITY;
                    end if;
                else
                    sm_next_state <= ST_DATA;
                end if;
            when ST_PARITY =>
                rst_bit_cntr <= '1';
                sm_next_state <= ST_STOP1;
                case G_PARITY is
                    when MARK => 
                        if sampled_bit = '0' then
                            parity_error <= '1';
                        end if;
                    when SPACE =>  
                        if sampled_bit = '1' then
                            parity_error <= '1';
                        end if;
                    when EVEN =>
                        if sampled_bit /= data_parity then
                             parity_error <= '1';
                        end if;
                    when ODD => 
                        if sampled_bit = data_parity then
                             parity_error <= '1';
                        end if;
                    when others => null;
                end case;
            when ST_STOP1 =>
                if G_STOP_BITS = 2 then
                    sm_next_state <= ST_STOP2;
                    if sampled_bit = '0' then
                        frame_error  <= '1';
                    end if;
                else 
                    sm_next_state <= ST_IDLE;
                    if sampled_bit = '1' then
                        if error = '0' then
                            data_valid <= '1';
                        end if;
                    else
                        frame_error  <= '1';
                    end if;
                end if;
           when ST_STOP2 =>
                    sm_next_state <= ST_IDLE;
                    if sampled_bit = '1' then
                        if error = '0' then
                            data_valid <= '1';
                        end if;
                    else
                        frame_error  <= '1';
                    end if;
            when others => sm_next_state <= ST_IDLE; -- output defaults.
        end case;
    end process;
    
    P_error: process (clk, rst) is -- SR flip-flop to keep track of errors in the frame. 
    begin
        if rising_edge(clk) then
            if rst = '1' or sm_current_state = ST_IDLE then
                error <= '0';
            elsif frame_error = '1' then
                    error <= '1';
            end if;
        end if;
    end process;

    P_bit_cntr: process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' or rst_bit_cntr = '1' then
                bit_cntr <= 0;
            elsif valid_pulse = '1' then
                if  bit_cntr = G_DATA_BITS-1 then
                    bit_cntr <= 0;
                else
                    bit_cntr <= bit_cntr + 1;
                end if;
            end if;
        end if;
    end process;
--=========== END STATE MACHINE ==========--
    
--=========== OUTPUT PULSE ==========--
    -- output signals should be asserted for only one clk cycle but the logic that 
    -- asserts them is clocked slower because of the clock enable.
    valid       <= '1' when (data_valid = '1' and data_prev = '0') else '0';
    frame_err   <= '1' when (frame_error = '1' and frame_prev = '0')  else '0';   
    parity_err  <= '1' when (parity_error = '1' and parity_prev = '0') else '0';
    P_sync_pulse : process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                data_prev <= '0';
                parity_prev <= '0';
                frame_prev  <= '0';
            else
                data_prev <= data_valid;
                parity_prev <= parity_error;
                frame_prev <= frame_error;
            end if;
        end if;
    end process;
--=========== END OUTPUT PULSE ==========--
end RTL;
