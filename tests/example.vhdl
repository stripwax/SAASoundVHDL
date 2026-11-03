library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity device_interface_mimic is
    port (
        -- External Bus Interface Pins
        ext_wr           : in  std_logic;                    -- Write strobe from host
        ext_address      : in  std_logic;                    -- Target register selector
        ext_data_pins    : in  std_logic_vector(7 downto 0);-- Asynchronous data bus
        
        -- Internal Clock Domain (8MHz Device Clock)
        sys_clk_8mhz     : in  std_logic;
        sys_reset        : in  std_logic;
        
        -- Internal Destination Registers
        r0, r1           : out std_logic_vector(7 downto 0)
    );
end entity device_interface_mimic;

architecture rtl of device_interface_mimic is
    -- Asynchronous Domain Signals
    signal data_latch      : std_logic_vector(7 downto 0);
    signal wr_pending      : std_logic := '0';
    
    -- Synchronous Domain Handshake & Storage Signals
    signal wr_pending_sync : std_logic_vector(2 downto 1) := "00";
    signal clear_pending   : std_logic := '0';
    
    signal r0_reg, r1_reg  : std_logic_vector(7 downto 0) := (others => '0');
begin

    ---------------------------------------------------------------------------
    -- 1. Asynchronous Capture Domain (Triggered by External Host WR Pin)
    ---------------------------------------------------------------------------
    -- This process handles the 0ns hold time constraint by instantly freezing
    -- the data bus on the rising edge of ext_wr.
    ---------------------------------------------------------------------------
    p_async_capture : process(ext_wr, clear_pending)
    begin
        if clear_pending = '1' then
            wr_pending <= '0';
        elsif rising_edge(ext_wr) then
            data_latch <= ext_data_pins; -- Snapshot data before it disappears
            wr_pending <= '1';           -- Raise the flag to the 8MHz clock
        end if;
    end process p_async_capture;


    ---------------------------------------------------------------------------
    -- 2. Synchronous Processing Domain (Triggered by 8MHz Internal Clock)
    ---------------------------------------------------------------------------
    -- This process safely synchronises the flag, routes the snapshot data to
    -- r0..r3, and sends back the clear handshake.
    ---------------------------------------------------------------------------
    p_sync_processing : process(sys_clk_8mhz, sys_reset)
    begin
        if sys_reset = '1' then
            wr_pending_sync <= "00";
            clear_pending   <= '0';
            r0_reg          <= (others => '0');
            r1_reg          <= (others => '0');
        elsif rising_edge(sys_clk_8mhz) then
            -- 2-Stage Shift Register to prevent metastability crossing clock domains
            wr_pending_sync <= wr_pending_sync(1) & wr_pending;
            
            -- Default assignment to ensure clear_pending pulses for exactly one cycle
            clear_pending <= '0';

            -- Check if the stable flag has successfully passed the synchronizer
            if wr_pending_sync(2) = '1' and clear_pending = '0' then
                
                -- Address decoding logic to commit data to target register
                case ext_address is
                    when '0' => r0_reg <= data_latch;
                    when '1' => r1_reg <= data_latch;
                    when others => null;
                end case;
                
                -- Send the acknowledgement pulse back to reset the async domain
                clear_pending <= '1';
            end if;
        end if;
    end process p_sync_processing;

    -- Drive output ports
    r0 <= r0_reg;
    r1 <= r1_reg;

end architecture rtl;
