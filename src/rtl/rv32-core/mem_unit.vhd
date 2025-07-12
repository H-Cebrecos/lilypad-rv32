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

entity mem_unit is
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
end mem_unit;

architecture Behavioral of mem_unit is
    signal req_internal : STD_LOGIC;
    signal is_read          : std_logic;
    signal stall_prev       : std_logic;
    signal stall_internal   : std_logic;
    signal stall_delay      : std_logic;
begin
    process(all)
        variable shifted_data_r : STD_LOGIC_VECTOR (31 downto 0);
        variable shifted_data_w : STD_LOGIC_VECTOR (31 downto 0);
    begin

        -- Memory is always read or written one word a time, aligned to a word boundary (2 lsb are effectively '0').
        -- data must be shifted based on the two least significant bits of the address.
        -- The operation must also be checked for correct alignment.
        -- below a diagram with the valid operations based on the address alignment is shown for clarity.
        -- [BHW] [  B] [ BH] [  B] [BHW]...
        -- ...00 ...01 ...10 ...11 ...00

        -- Align the data and check of misaligned addresses.
        case mem_addr is
            when "00" =>
                shifted_data_r := mem_data;
                shifted_data_w := rs2_data;
                address_misaligned_exception <= '0'; -- no need to shift data, all operations valid.
            when "01" =>
                -- Shift 1 byte.
                shifted_data_r := mem_data srl 8;
                shifted_data_w := mem_data sll 8;
                -- The only valid operations are byte sized ones.
                address_misaligned_exception <= '0' when data_size = SIZE_B OR data_size = SIZE_BU else '1';
            when "10" =>
                -- Shift 2 bytes.
                shifted_data_r := mem_data srl 16;
                shifted_data_w := mem_data sll 16;
                -- The only NOT valid operation is a word size.
                address_misaligned_exception <= '1' when data_size = SIZE_W else '0';
            when "11" =>
                -- Shift 3 bytes.
                shifted_data_r := mem_data srl 24;
                shifted_data_w := mem_data sll 24;
                -- The only valid operations are byte sized ones.
                address_misaligned_exception <= '0' when data_size = SIZE_B OR data_size = SIZE_BU else '1';
            when others => null; --unreachable.
        end case;
        -- NOTE: shifted_data could also be computed with: data_to_shft srl to_integer(signed(mem_addr(1 downto 0))* 8);
        --       but RTL synthesis generated a variable shifter instead of three fixed shifters and a mux.

        -- Default values
        mem_wen <= "0000";
        write_data <= shifted_data_w;
        mem_rslt <= (others => '0');
        is_read <= '0';
        case mem_operation is
            when MEM_R =>
                -- Send request.
                req_internal <= '1';
                is_read <= '1';
                
                -- Perform sign extension based on size of read.
                case data_size is
                    when SIZE_B  => mem_rslt <= (31 downto  7 => shifted_data_r(7)) & shifted_data_r( 6 downto 0);
                    when SIZE_BU => mem_rslt <= (31 downto  8 => '0')               & shifted_data_r( 7 downto 0);
                    when SIZE_H  => mem_rslt <= (31 downto 15 => shifted_data_r(15))& shifted_data_r(14 downto 0);
                    when SIZE_HU => mem_rslt <= (31 downto 16 => '0')               & shifted_data_r(15 downto 0);
                    when SIZE_W  => mem_rslt <= shifted_data_r;
                    when others  =>
                        -- Don't request when size is undefined.
                        req_internal <= '0';
                end case;

            when MEM_W =>
                -- Send request.
                req_internal <= '1';

                -- Per byte write enable.
                case data_size is
                    when SIZE_B =>
                        case mem_addr is
                            when "00" => mem_wen <= "0001";
                            when "01" => mem_wen <= "0010";
                            when "10" => mem_wen <= "0100";
                            when "11" => mem_wen <= "1000";
                            when others => null; --unreachable.
                        end case;
                    when SIZE_H =>
                        case mem_addr is
                            when "00" => mem_wen <= "0011"; -- lower half-word.
                            when "10" => mem_wen <= "1100"; -- upper half-word.
                            when others => req_internal <= '0'; -- incorrect alignment. Don't request.
                        end case;
                    when SIZE_W =>
                        mem_wen <= "1111" when mem_addr = "00";
                    when others =>
                        -- Don't request when size is undefined.
                        req_internal <= '0';

                end case;
            when others => req_internal <= '0';
        end case;
    end process;
        -- Don't request when an exception happens.
        req <= req_internal AND NOT address_misaligned_exception;
        
        -- output two cycle pulse each time data is read
    stall_internal <= '1' when (is_read = '1' and stall_prev = '0') else '0';
    P_sync_pulse : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                stall_prev <= '0';
                stall_delay <= '0';
            else
                stall_prev <= (stall_internal or stall_delay); -- if there are consecutive reads the value should reset and issue multiple stalls.
                stall_delay <= stall_internal;
            end if;
        end if;
    end process;
    stall <= stall_internal or stall_delay;
    
end Behavioral;
