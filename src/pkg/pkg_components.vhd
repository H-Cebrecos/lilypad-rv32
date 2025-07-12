library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_types.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package pkg_components is
    component reset_CDC is
        Port (
            sys_clk   : in STD_LOGIC;
            async_rst : in STD_LOGIC;
            sync_rst  : out STD_LOGIC
        );
    end component;
        component mem_unit
    Port (
        clk : in std_logic;
        rst : in std_logic;
        
        -- Operation selection.
        mem_operation : in MEM_OP_T;                            -- selects the operation to perform.
        data_size     : in MEM_SIZE_T;                          -- selects the size of the data (Byte, half word or word) and signedness.

        -- Memory operands.
        rs2_data      : in STD_LOGIC_VECTOR (31 downto 0);      -- register contents for write opetarion.
        mem_addr      : in STD_LOGIC_VECTOR (1 downto 0);      -- lower lsbits of address to read from or write to.
        mem_data      : in STD_LOGIC_VECTOR (31 downto 0);      -- raw data from memory.

        --trigger_pause : in STD_LOGIC;

        -- Outputs to register file.
        mem_rslt      : out STD_LOGIC_VECTOR (31 downto 0);     -- aligned data read from memory.

        -- Outputs to memory
        write_data    : out STD_LOGIC_VECTOR (31 downto 0);     -- data for write operation.
        mem_wen       : out STD_LOGIC_VECTOR (3 downto 0);      -- write enable signal for memory.
        req           : out STD_LOGIC;                          -- memory request signal.
        
        stall         : out std_logic;
        address_misaligned_exception : out STD_LOGIC
    );
    end component;
        
    component core
        Port (
            -- Inputs.
            clk         : in STD_LOGIC;                             -- clock signal. 
            reset       : in STD_LOGIC;                             -- synchronous reset, sets PC pointing to RESET_VECTOR.
            instruction : in STD_LOGIC_VECTOR (31 downto 0);        -- instruction data.
            mem_data    : in STD_LOGIC_VECTOR (31 downto 0);        -- raw data read from system memory (always word aligned).
            -- Outputs.
            inst_addr   : out STD_LOGIC_VECTOR (31 downto 0);       -- address of the next instruction to be fetched.
            mem_addr    : out STD_LOGIC_VECTOR (31 downto 0);       -- address in system memory for the memory operations.
            mem_wen     : out STD_LOGIC_VECTOR (3 downto 0);        -- write enable signal for memory.  
            write_data  : out STD_LOGIC_VECTOR (31 downto 0);       -- data for write operation.

            req         : out STD_LOGIC                             -- memory request signal.           
        );
    end component;

    component clk_wiz
        port (
            clk_out1          : out    std_logic;
            locked            : out    std_logic;
            clk_in1           : in     std_logic
        );
    end component;
    COMPONENT RAM
    PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) 
    );
END COMPONENT;

component system_ram is
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
end component;
COMPONENT boot_ROM
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) 
  );
END COMPONENT;
    component  seven_segment_display is
        Port (
            clk     : in  STD_LOGIC;-- 100Mhz 
            data    : in  STD_LOGIC_VECTOR (15 downto 0);
            an      : out STD_LOGIC_VECTOR (3 downto 0);
            seg     : out STD_LOGIC_VECTOR (0 to 6)
        );
    end component;
    component uart_top is
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
    end component;
    
    component fetch_unit
     generic (
        RESET_VECTOR : STD_LOGIC_VECTOR (31 downto 0) := (others => '0')
    );
    Port (
        -- Sequential logic inputs.
        clk         : in STD_LOGIC;                             -- clock signal. 
        rst         : in STD_LOGIC;                             -- reset, sets PC pointing to RESET_VECTOR. !! Should not be desasserted in a clk rising edge.
        valid       : in STD_LOGIC;                             -- indicates if the data is valid.
        
        stall       : in std_logic;
        
        -- Next address computation selection and data.
        next_pc_src : in PC_SRC_T;                              -- selects whether the next address comes from incrementing the PC or from the ALU.
        alu_addr    : in STD_LOGIC_VECTOR (31 downto 1);        -- result from computing a branch target address in the ALU.
        cmp_rslt    : in STD_LOGIC;                             -- result of the logic comparison, determines whether to branch or not.
        is_branch   : in STD_LOGIC;                             -- indicates if the current instruction is a conditional branch, in which case cmp_rslt overrides next_pc_src.


        -- Instruction read from decoupler (or memory).
        inst_data   : in STD_LOGIC_VECTOR (31 downto 0);        -- instruction data read from memory, not the same as the requested instruction due to lantency.
        inst_addr   : in STD_LOGIC_VECTOR (31 downto 0);        -- address of the currently executing instruction. Corresponds to the traditionally called program counter.

        -- Outputs
        fetch_addr      : out STD_LOGIC_VECTOR (31 downto 0);   -- address of the next instruction to be fetched.
        
        -- Downstream outputs --
        next_inst_addr  : out STD_LOGIC_VECTOR (31 downto 0);   -- address of the subsecuent instruction in memory.
        current_inst    : out STD_LOGIC_VECTOR (31 downto 0);   -- instruction data of the current PC.
        current_addr    : out STD_LOGIC_VECTOR (31 downto 0);
        
        -- Decoupler control
        flush : out std_logic;
        pause : out std_logic;

        instruction_address_misaligned_exception : out STD_LOGIC
    );
    end component;
    component pipeline_decoupler is
        Generic (
            LATENCY         : integer;
            DATA_WIDTH      : integer;
            COMMAND_WIDTH   : integer
        );
        Port (
            clk      : in STD_LOGIC;
            rst      : in std_logic;
            flush    : in STD_LOGIC;
            pause    : in STD_LOGIC;
            cmd_in   : in STD_LOGIC_VECTOR (COMMAND_WIDTH-1 downto 0);
            data_in  : in STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);

            valid    : out STD_LOGIC;
            cmd_out : out STD_LOGIC_VECTOR (COMMAND_WIDTH-1 downto 0);
            data_out : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)
        );
    end component;
end pkg_components;

