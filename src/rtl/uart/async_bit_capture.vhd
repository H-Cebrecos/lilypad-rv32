library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library xpm;
use xpm.vcomponents.all;

use work.pkg_uart.all;

entity async_bit_capture is
        port ( 
                clk: in std_logic;
                rst: in std_logic;
                clk_div : in std_logic_vector(RX_CNTR_SIZE-1 downto 0);
                rx : in std_logic; -- different clock domain.

                valid_pulse : out std_logic;
                sampled_bit : out std_logic 
        );
end async_bit_capture;

architecture RTL of async_bit_capture is
-- CDC singals --
    constant CDC_STAGES : natural := 4;
    signal cdc_rx: std_logic;
    --signal sync_stage   : std_logic_vector(CDC_STAGES downto 1);
    --attribute ASYNC_REG : string;
    --attribute ASYNC_REG of sync_stage : signal is "TRUE";

-- Sample pulse generation signals --
    signal sample_pulse     : std_logic;
    signal division_cntr    : unsigned(RX_CNTR_SIZE-1 downto 0);

-- Edge detector signals --
    constant EDGE_STAGES    : natural := 4;
    signal sampling_shft_reg: std_logic_vector(EDGE_STAGES-1 downto 0);
    signal edge             : std_logic;

-- Sample window signals --
    constant OVER_SAMPL_FACTOR : natural := 16;
    signal window_cntr      : natural range 0 to OVER_SAMPL_FACTOR-1;
    signal valid : std_logic;

begin
--=========== CDC ==========--
    -- Manual implementation of a simple flip-flop synchronizer. AMD recommends using the XMP.
    --P_cdc_sync: process (clk)
    --begin
    --    -- no reset on the synchronizer.
    --    if rising_edge(clk) then
    --        sync_stage(1) <= rx;
    --        for i in 2 to CDC_STAGES loop
    --            sync_stage(i) <= sync_stage(i-1);
    --        end loop;
    --    end if;
    --end process;
    --cdc_rx <= sync_stage(CDC_STAGES);
    
    xpm_cdc_single_inst : xpm_cdc_single
    generic map (
        DEST_SYNC_FF => CDC_STAGES,   -- DECIMAL; range: 2-10
        INIT_SYNC_FF => 0,   -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
        SIM_ASSERT_CHK => 0, -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
        SRC_INPUT_REG => 0   -- DECIMAL; 0=do not register input, 1=register input
    )
    port map (
       dest_out => cdc_rx,  -- 1-bit output: src_in synchronized to the destination clock domain. This output is registered.
       dest_clk => clk,     -- 1-bit input: Clock signal for the destination clock domain.
       src_clk => '0',      -- 1-bit input: optional; required when SRC_INPUT_REG = 1
       src_in => rx         -- 1-bit input: Input signal to be synchronized to dest_clk domain.
    );
--=========== END CDC ==========--

--=========== SAMPLE PULSE GENERATOR ==========--
    P_pulse_gen: process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                division_cntr <= (others => '0');
                sample_pulse <= '0';
            elsif division_cntr = unsigned(clk_div) then
                sample_pulse <= '1';
                division_cntr <= (others => '0');
            else
                sample_pulse <= '0';
                division_cntr <= division_cntr + 1;
            end if;
        end if;
    end process;
--=========== END SAMPLE PULSE GENERATOR ==========--

--=========== EDGE DETECTOR ==========--
    P_edge_detector_and_vote_shft_reg: process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sampling_shft_reg <= (others => '1');

            -- sample_pulse used as clock enable signal. 
            elsif sample_pulse = '1' then
                sampling_shft_reg(0) <= cdc_rx;
                for i in 1 to EDGE_STAGES-1 loop
                    sampling_shft_reg(i) <= sampling_shft_reg(i-1);
                end loop;
            end if;
        end if;
    end process;
    --  cdc_rx: ...¯¯¯¯¯¯¯¯¯¯\______/¯...
    --                     12 34
    --  An edge is detected when 1=2 /= 3=4 to avoid detecting glitches.
    edge <= '1' when (sampling_shft_reg = "1100") or (sampling_shft_reg = "0011") else '0';
--=========== END EDGE DETECTOR ==========--

--=========== SAMPLE WINDOW ==========--
    P_window_cntr: process (clk)
    begin
        if rising_edge(clk) then
            if edge = '1' or rst = '1' then
                window_cntr <= 0;
            elsif sample_pulse = '1' then
                if window_cntr = OVER_SAMPL_FACTOR - 1 then
                    window_cntr <= 0;
                else
                    window_cntr <= window_cntr + 1;
                end if;
            end if;
        end if;
    end process;

    -- window counter counts the 16 sample pulses in a bit (0 to 15), 
    -- we want to sample in the middle, 
    --anded with sample_pulse to make valid last for 1 clk cycle.
    valid <= '1' when window_cntr = (OVERSAMPLE/2)-1 AND sample_pulse = '1' else '0';
    valid_pulse <= valid;
    
    P_sample: process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sampled_bit <= '1';
    
            -- valid used as clock enable.
            elsif valid = '1' then
                sampled_bit <= sampling_shft_reg(EDGE_STAGES-1);
            end if;
        end if;
    end process;
--=========== END SAMPLE WINDOW ==========--
end RTL;
