-- True-Dual-Port BRAM with Byte-wide Write Enable
-- Write First mode
--
-- bytewrite_tdp_ram_wf.vhd
-- WRITE_FIRST ByteWide WriteEnable Block RAM Template
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity system_ram is
 generic(
        SIZE : integer := 4096;
        ADDR_WIDTH : integer := 12;
        COL_WIDTH : integer := 8;
        NB_COL : integer := 4
 );
 port(
        clka : in std_logic;
        --ena : in std_logic;
        wea : in std_logic_vector(NB_COL - 1 downto 0);
        addra : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        dia : in std_logic_vector(NB_COL * COL_WIDTH - 1 downto 0);
        doa : out std_logic_vector(NB_COL * COL_WIDTH - 1 downto 0);
        --clkb : in std_logic;
        --enb : in std_logic;
        web : in std_logic_vector(NB_COL - 1 downto 0);
        addrb : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        dib : in std_logic_vector(NB_COL * COL_WIDTH - 1 downto 0);
        dob : out std_logic_vector(NB_COL * COL_WIDTH - 1 downto 0)
 );
end system_ram;
architecture byte_wr_ram_wf of system_ram is
        type ram_type is array (0 to SIZE - 1) of std_logic_vector(NB_COL * COL_WIDTH - 1 downto 0);
        shared variable RAM : ram_type := (others => (others => '0'));
        signal doa_r : std_logic_vector(NB_COL * COL_WIDTH - 1 downto 0) := (others => '0');
        signal dob_r : std_logic_vector(NB_COL * COL_WIDTH - 1 downto 0) := (others => '0');
begin
 ------- Port A -------
        process(clka)
        begin
                if rising_edge(clka) then
                        --if ena = '1' then
                                for i in 0 to NB_COL - 1 loop
                                        if wea(i) = '1' then
                                                RAM(conv_integer(addra))((i + 1) * COL_WIDTH - 1 downto i * COL_WIDTH) := dia((i + 1) * COL_WIDTH - 1 downto i * COL_WIDTH);
                                        end if;
                                end loop;
                                doa_r <= RAM(conv_integer(addra));
                                doa   <= doa_r;
                        --end if;
                end if;
        end process;
 ------- Port B -------
        process(clka)
        begin
                if rising_edge(clka) then
                        --if enb = '1' then
                                for i in 0 to NB_COL - 1 loop
                                        if web(i) = '1' then
                                                RAM(conv_integer(addrb))((i + 1) * COL_WIDTH - 1 downto i * COL_WIDTH) := dib((i + 1) * COL_WIDTH - 1 downto i * COL_WIDTH);
                                        end if;
                                end loop;
                                dob_r <= RAM(conv_integer(addrb));   
                                dob   <= dob_r;        
                        --end if;
                        
                end if;
        end process;
end byte_wr_ram_wf;