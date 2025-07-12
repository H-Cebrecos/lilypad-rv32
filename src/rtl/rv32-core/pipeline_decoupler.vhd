-- NOTE: pausing right after a flush does not make much sense for this application and is broken and does not work :)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pipeline_decoupler is
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
end pipeline_decoupler;

architecture Behavioral of pipeline_decoupler is

    type cmd_fifo_type is array (0 to LATENCY-2) of std_logic_vector(COMMAND_WIDTH-1 downto 0);
    type dat_fifo_type is array (0 to LATENCY-2) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal cmd_fifo : cmd_fifo_type;
    signal dat_fifo : dat_fifo_type;
    signal cmd_head, cmd_tail, dat_head, dat_tail : integer range 0 to LATENCY-1;

    --signal cmd_out_buff : STD_LOGIC_VECTOR (COMMAND_WIDTH-1 downto 0);
    signal data_sel : STD_LOGIC;
    signal data_buff : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal internal_data_out : std_logic_vector(DATA_WIDTH-1 downto 0);
    --initial conditions
    signal num_stored : integer range 0 to LATENCY-1;
    signal pending_stores : integer range 0 to LATENCY-1;
    signal cycles_until_full : integer range 0 to LATENCY-1;
    signal stored    : integer range 0 to LATENCY-1;
    signal paused : std_logic;

begin
    data_out <= internal_data_out;
    internal_data_out <= data_in when data_sel = '1' else data_buff;

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' or flush = '1' then -- the incomming message is ignored during a flush due to the delay when filling the fetch register in the PC.

                cmd_head <= 0;
                cmd_tail <= 0;
                cmd_fifo <= (others => (others => '0'));

                cycles_until_full <= LATENCY-1;
                stored <= 0;
                paused <= '0';

                data_buff <= (others => '0');

                -- out: invalid.
                valid <= '0';
                data_sel <= '1'; -- output doesn't matter.
            else
                
                data_buff <= internal_data_out; -- register current output.
                
                if cycles_until_full > 0 then
                    cycles_until_full <= cycles_until_full - 1;
                    cmd_fifo(cmd_tail) <= cmd_in;
                    cmd_tail <= (cmd_tail + 1) mod (LATENCY-1);
                    -- out: invalid.
                    data_sel <= '1'; -- output doesn't matter.
                    valid <= '0';
                else
                    valid <= '1';
                    cycles_until_full <= 0;

                    if pause = '1' then -- the PC can only pause if its executing an instrution so the output was valid and thus the fifo full.
                        num_stored <= LATENCY-1;
                        if paused <= '0' then
                            pending_stores <= LATENCY-1;
                            paused <= '1';
                        end if;

                        if pending_stores > 0 then
                            -- store

                            dat_fifo(dat_tail) <= data_in;
                            dat_tail <= (dat_tail + 1) MOD (LATENCY-1);
                            pending_stores <= pending_stores - 1;
                        end if;

                        -- out: maintain previous.             
                        --output <= data_buff;
                        data_sel <= '0';
                    else
                        cmd_fifo(cmd_tail) <= cmd_in;
                        cmd_tail <= (cmd_tail + 1) mod (LATENCY-1);
                        paused <= '0';
                        cmd_out <= cmd_fifo(cmd_head);
                        cmd_head <= (cmd_head + 1) mod (LATENCY-1);
                        if pending_stores > 0 then
                            -- store
                            dat_fifo(dat_tail) <= data_in;
                            dat_tail <= (dat_tail + 1) MOD (LATENCY-1);
                            pending_stores <= pending_stores - 1;
                        end if;

                        if num_stored > 0 then
                            num_stored <= num_stored - 1;
                            data_buff <= dat_fifo(dat_head);
                            dat_head <= (dat_head + 1) MOD (LATENCY-1);
                            data_sel <= '0';
                        else
                            
                            data_sel <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;



