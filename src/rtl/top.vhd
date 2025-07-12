library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_components.all; 
use ieee.numeric_std.all;

entity top is
    Port (
        -- Input clock
        clk_base: in  STD_LOGIC ;

        -- Reset signal
        async_reset    : in  STD_LOGIC;
        
        -- LED output
        led     : out STD_LOGIC_VECTOR (15 downto 0);
        
        -- UART signals
        rx      : in  std_logic; 
        tx      : out std_logic
        
    );
end top;

architecture Behavioral of top is
    
    -- Memory Map --
    constant ROM_ADDR : std_logic_vector(31 downto 0) := x"00000000";
    constant RAM_ADDR : std_logic_vector(31 downto 0) := x"00010000";
    constant LED_ADDR : std_logic_vector(31 downto 0) := x"FFFFFFF0";
    
    signal  reset   : std_logic; 
    signal rst_buff : std_logic;
    signal  sys_clk : std_logic;

    signal addra, inst_mux, ram_inst, rom_inst, mem_addr, mem_data, write_data : STD_LOGIC_VECTOR(31 downto 0);
    signal req : STD_LOGIC;
    signal mem_wen, wen_mux : STD_LOGIC_VECTOR(3 downto 0);
    signal  locked : STD_LOGIC;

   
    signal uart_data_addr : std_logic;
    signal led_data_addr  : std_logic;
    signal ram_data_addr  : std_logic;
    signal rom_data_addr  : std_logic;
    signal ram_inst_addr  : std_logic;
    signal rom_inst_addr  : std_logic;
    
    signal one_hot   : std_logic_vector (2 downto 0);
    signal inst_oh   : std_logic_vector (1 downto 0);
    
    signal uart_data : std_logic_vector (31 downto 0);
    signal ram_data  : std_logic_vector (31 downto 0);
    signal rom_data  : std_logic_vector (31 downto 0);
    
    begin

    rst_CDC: reset_CDC port map (
        sys_clk   => sys_clk,
        async_rst => async_reset,
        sync_rst  => rst_buff
    );
    reset <= rst_buff or not locked;

    Clocking : clk_wiz port map ( 
        clk_out1 => sys_clk,
        locked => locked,
        clk_in1 => clk_base
    );  

    --********* CORES *********--
    CPU1: core port map(
        clk => sys_clk,
        reset => reset,
        
        inst_addr => addra,
        instruction => inst_mux,
        
        mem_addr => mem_addr,
        mem_data => mem_data,
        write_data => write_data,               
        mem_wen => mem_wen,

        req => req
    );
    --********* MEMORY *********--
    
    RAM_16K : SYSTEM_RAM port map (
        clka => sys_clk,
        wea => "0000",
        addra => addra(13 downto 2),
        dia => x"00000000",
        doa => ram_inst,
        web => wen_mux,
        addrb => mem_addr(13 downto 2),
        dib => write_data,
        dob => ram_data
    );
    ROM_2K : boot_ROM port map (
        clka => sys_clk,
        addra => addra(10 downto 2),
        douta => rom_inst,
        clkb => sys_clk,
        addrb => mem_addr(10 downto 2),
        doutb => rom_data
    );  
  
    --********* PERIPHERALS *********--
    uart: uart_top port map (
        clk => sys_clk,
        rst => reset,
        en  => uart_data_addr,
        write => mem_wen(0),
        read  => req,
        reg_addr => mem_addr(7 downto 0),
        i_data   => write_data(7 downto 0),
        o_data   => uart_data,
        rx => rx,
        tx => tx
    );

    P_led_reg: process(sys_clk)
    begin
        if rising_edge(sys_clk)then
            if reset = '1' then
                led <= (others => '0');
            elsif led_data_addr = '1' AND req = '1' then
                led <= write_data(15 downto 0);
            end if;
        end if;
    end process;

    --********* SYSTEM BUSES *********--

    uart_data_addr <= '1' when mem_addr(31 downto 8) = x"005555" else '0'; 
    led_data_addr  <= '1' when mem_addr = LED_ADDR else '0';
      
    rom_inst_addr  <= '1' when    addra(31 downto 11) = ROM_ADDR(31 downto 11) else '0';
    rom_data_addr  <= '1' when mem_addr(31 downto 11) = ROM_ADDR(31 downto 11) else '0';
    
    ram_inst_addr <= '1' when    addra(31 downto 14) = RAM_ADDR(31 downto 14) else '0';
    ram_data_addr <= '1' when mem_addr(31 downto 14) = RAM_ADDR(31 downto 14) else '0';
    
    one_hot <= (uart_data_addr & ram_data_addr & rom_data_addr);
    P_one_hot : process(one_hot, uart_data, ram_data, rom_data)
    begin
        case one_hot is
            when "100" => mem_data <= uart_data;
            when "010" => mem_data <= ram_data;
            when "001" => mem_data <= rom_data;
            when others => mem_data <= (others => '0');
        end case;
    end process;
    
    P_wen_mux : process (ram_data_addr, mem_wen)
    begin
        if ram_data_addr = '1' then
            wen_mux <= mem_wen;
        else
            wen_mux <= (others => '0');
        end if;
    end process;
    
    inst_oh <= rom_inst_addr & ram_inst_addr;
    P_inst_bus_mux : process (inst_oh, ram_inst, rom_inst)
    begin
        case inst_oh is
            when "10" => inst_mux <= rom_inst;
            when "01" => inst_mux <= ram_inst;
            when others => inst_mux <= (others => '0'); -- illegal instruction.
        end case;
    end process;
end Behavioral;
