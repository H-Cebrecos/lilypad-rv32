library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.pkg_types.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.NUMERIC_STD_UNSIGNED.ALL; -- Using VHDL 2008 features.

entity register_file is
    Port (
        -- Clock input.
        clk : in STD_LOGIC;                             -- clock signal. 
        pause : in STD_LOGIC;

        -- Register selection.
        rs1 : in STD_LOGIC_VECTOR (4 downto 0);         -- source register 1.
        rs2 : in STD_LOGIC_VECTOR (4 downto 0);         -- soruce register 2.
        rd  : in STD_LOGIC_VECTOR (4 downto 0);         -- destination register.

        -- Write selection and data.
        write_src : in WRITE_SRC_T;                     -- source of the write data.
        alu_rslt  : in STD_LOGIC_VECTOR (31 downto 0);  -- result of ALU computation.
        immediate : in STD_LOGIC_VECTOR (31 downto 0);  -- extendend immendiate.
        mem_rslt  : in STD_LOGIC_VECTOR (31 downto 0);  -- value read from memory.
        next_inst : in STD_LOGIC_VECTOR (31 downto 0);  -- address of the next instruction in memory.

        -- Outputs.
        rs1_data  : out STD_LOGIC_VECTOR (31 downto 0); -- contents of register indexed by rs1.
        rs2_Data  : out STD_LOGIC_VECTOR (31 downto 0)  -- contents of register indexed by rs1.
    );
end register_file;

architecture Behavioral of register_file is
    -- 32 general pourpouse registers.   
    type REG_FILE_T is array (31 downto 0) of STD_LOGIC_VECTOR (31 downto 0);
    signal regs : REG_FILE_T := (others => (others => '0'));

    -- Internal signals.
    signal write_data : STD_LOGIC_VECTOR (31 downto 0);
    signal we         : STD_LOGIC;
begin
    -- Asynchronous read port.
    rs1_data <= regs(to_integer(rs1));
    rs2_data <= regs(to_integer(rs2));

    -- Combinatorial source and write enable selection.
    src_we: process(all)
    begin
        we <= not pause; --don't write while paused.
        case write_src is
            when SRC_ALU     => write_data <= alu_rslt;
            when SRC_PC_ADD4 => write_data <= next_inst;
            when SRC_IMM     => write_data <= immediate;
            when SRC_MEM     => write_data <= mem_rslt;
            when others      => write_Data <= (others => '-'); we <= '0';
        end case;
    end process;

    -- Synchronous write port.
    write: process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                regs(to_integer(rd)) <= write_data;
            end if;
            -- Register 0 is always set to 0 when read or written.
            regs(0) <= (others => '0');
        end if;
    end process;
end Behavioral;
