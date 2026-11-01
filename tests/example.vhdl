library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AsyncRegisterInterface is
    Port (
        -- Host Bus Interface (Asynchronous)
        WR             : in  std_logic;           -- Active-low Write Strobe
        CS             : in  std_logic;           -- Active-low Chip Select
        address        : in  std_logic_vector(1 downto 0);
        data           : in  std_logic_vector(7 downto 0);
        
        -- System Clock Domain (8 MHz)
        clk_8mhz       : in  std_logic;
        
        -- Internal Synchronous Registers
        reg_0          : out std_logic_vector(7 downto 0);
        reg_1          : out std_logic_vector(7 downto 0);
        reg_2          : out std_logic_vector(7 downto 0);
        reg_3          : out std_logic_vector(7 downto 0)
    );
end AsyncRegisterInterface;

architecture Behavioral of AsyncRegisterInterface is

    -- Asynchronous Domain Signals
    signal shadow_addr   : std_logic_vector(1 downto 0) := (others => '0');
    signal shadow_data   : std_logic_vector(7 downto 0) := (others => '0');
    signal write_pending : std_logic := '0';

    -- Synchronous Domain Signals (8 MHz)
    signal sync_pending_0 : std_logic := '0';
    signal sync_pending_1 : std_logic := '0';
    signal clear_pending  : std_logic := '0';
    
    -- Internal storage registers matching outputs
    signal r0, r1, r2, r3 : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- Assign internal registers to top-level outputs
    reg_0 <= r0;
    reg_1 <= r1;
    reg_2 <= r2;
    reg_3 <= r3;

    ---------------------------------------------------------------------------
    -- 1. ASYNCHRONOUS DOMAIN (Clocked by the Host Bus WR Rising Edge)
    ---------------------------------------------------------------------------
    -- This process handles latching the data exactly when WR goes high (deasserts).
    -- It uses clear_pending as an asynchronous reset to clear the flag.
    ---------------------------------------------------------------------------
    P_ASYNC_CAPTURE: process(WR, clear_pending)
    begin
        if clear_pending = '1' then
            write_pending <= '0';
        elsif rising_edge(WR) then
            if CS = '0' then
                shadow_addr   <= address;       -- Captured safely (stable since before WR fell)
                shadow_data   <= data;          -- Captured safely (stable for 100ns before WR rose)
                write_pending <= '1';          -- Set the flag to alert the 8 MHz domain
            end if;
        end if;
    end process P_ASYNC_CAPTURE;


    ---------------------------------------------------------------------------
    -- 2. SYNCHRONOUS DOMAIN (8 MHz System Clock)
    ---------------------------------------------------------------------------
    -- This process synchronizes the handshake flag and safely distributes
    -- the static shadow data to the correct system register.
    ---------------------------------------------------------------------------
    P_SYNC_PROCESSING: process(clk_8mhz)
    begin
        if rising_edge(clk_8mhz) then
            -- 2-stage synchroniser pipeline to completely eliminate metastability
            sync_pending_0 <= write_pending;
            sync_pending_1 <= sync_pending_0;
            
            -- Default clear pulse to low
            clear_pending <= '0';

            -- Process the data once the synchronised flag is detected
            if (sync_pending_1 = '1') and (clear_pending = '0') then
                -- Route the static shadow data based on the static shadow address
                case shadow_addr is
                    when "00" => r0 <= shadow_data;
                    when "01" => r1 <= shadow_data;
                    when "10" => r2 <= shadow_data;
                    when "11" => r3 <= shadow_data;
                    when others => null; -- Fallback protection
                end case;
                
                -- Assert clear to drop the asynchronous 'write_pending' flag
                clear_pending <= '1';
            end if;
        end if;
    end process P_SYNC_PROCESSING;

end Behavioral;
