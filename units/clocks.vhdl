library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity clocks is
  -- various clock frequencies
  -- given 8mhz system clock, outputs clocks at 31.3khz, 15.6khz and 7.6khz
  -- (respectively, divide by 256, 512, 1024)
  -- as required by noise generators
  port (
    clk: in bit;
    clk_313, clk_156, clk_76: out std_logic
    );
end clocks;

architecture behaviour of clocks is
    signal counter: unsigned(10 downto 0) := (others => '0');
begin
    process(clk)
    begin
    if rising_edge(clk) then
        -- question: which clocks (if any) still tick when SYNC bit is set? I may need to connect to SYNC bit here.
        counter <= counter + 1;
        clk_313 <= counter(8);
        clk_156 <= counter(9);
        clk_76 <= counter(10);
    end if;
    end process;

end behaviour;