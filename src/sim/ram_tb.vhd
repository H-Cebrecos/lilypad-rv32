
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_components.all; 

entity ram_tb is
end entity;

architecture tb of ram_tb is
    constant NB_COL     : integer := 4;
    constant COL_WIDTH  : integer := 8;
    constant ADDR_WIDTH : integer := 12;

    signal clk        : std_logic := '0';
    signal wea        : std_logic_vector(NB_COL-1 downto 0);
    signal addra      : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal dia        : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);
    signal doa        : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);

    signal enb        : std_logic;
    signal web        : std_logic_vector(NB_COL-1 downto 0);
    signal addrb      : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal dib        : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);
    signal dob        : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);
-- Registered inputs
    signal wea_r, web_r         : std_logic_vector(NB_COL-1 downto 0);
    signal addra_r, addrb_r     : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal dia_r, dib_r         : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);
    signal enb_r                : std_logic;
    -- Expected output buffer for checking latency
    type mem_queue_t is array (natural range <>) of std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);
    signal expected_doa_queue : mem_queue_t(0 to 2) := (others => (others => '0'));
    signal expected_dob_queue : mem_queue_t(0 to 2) := (others => (others => '0'));

    

begin

    -- Clock generation
    clk_proc: process
    begin
        while now < 1 ms loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
        wait;
    end process;
 -- Register inputs synchronously
    reg_inputs : process(clk)
    begin
        if rising_edge(clk) then
            wea_r    <= wea;
            addra_r  <= addra;
            dia_r    <= dia;
            web_r    <= web;
            addrb_r  <= addrb;
            dib_r    <= dib;
            enb_r    <= enb;
        end if;
    end process;

    -- Instantiate RAM 
    uut : system_ram
        port map (
            clka  => clk,
            wea   => wea_r,
            addra => addra_r,
            dia   => dia_r,
            doa   => doa,
            enb   => enb_r,
            web   => web_r,
            addrb => addrb_r,
            dib   => dib_r,
            dob   => dob
        );

   
    -- Stimulus process
    stim: process
        variable expected : std_logic_vector(NB_COL * COL_WIDTH - 1 downto 0);
    begin
        -- Initialize
        wea  <= (others => '0');
        web  <= (others => '0');
        dia  <= (others => '0');
        dib  <= (others => '0');
        addra <= (others => '0');
        addrb <= (others => '0');
        enb  <= '0';
        wait for 25 ns;

        -- Write to port A
        dia  <= x"AABBCCDD";  -- 32-bit data
        addra <= std_logic_vector(to_unsigned(1, ADDR_WIDTH));
        wea <= (others => '1');
        wait for 10 ns;
        wea <= (others => '0');

        -- Write to port B
        dib  <= x"01234567";
        addrb <= std_logic_vector(to_unsigned(2, ADDR_WIDTH));
        web <= (others => '1');
        enb <= '1';
        wait for 10 ns;
        web <= (others => '0');
        enb <= '0';
        addrb <= std_logic_vector(to_unsigned(3, ADDR_WIDTH));
        -- Read from port A
        addra <= std_logic_vector(to_unsigned(1, ADDR_WIDTH));
        wea <= (others => '0');
        dia <= (others => '0');
        wait for 10 ns;

        -- Track expected result with 2-cycle latency
        expected_doa_queue(0) <= expected_doa_queue(1);
        expected_doa_queue(1) <= expected_doa_queue(2);
        expected_doa_queue(2) <= x"AABBCCDD";

        wait for 10 ns;
        expected := expected_doa_queue(0);
        assert doa = expected
            report "FAIL: Port A read mismatch" severity error;

        -- Read from port B
        addrb <= std_logic_vector(to_unsigned(2, ADDR_WIDTH));
        enb <= '1';
        wait for 10 ns;
        enb <= '0';

        -- Track expected result with 2-cycle latency
        expected_dob_queue(0) <= expected_dob_queue(1);
        expected_dob_queue(1) <= expected_dob_queue(2);
        expected_dob_queue(2) <= x"01234567";

        wait for 10 ns;
        expected := expected_dob_queue(0);
        assert dob = expected
            report "FAIL: Port B read mismatch" severity error;

        report "Test passed!" severity note;
        wait;
    end process;

end architecture;
