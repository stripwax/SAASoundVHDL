-- this is always running
-- this forms the backbone of the pulse density modulation that implements all the volume controls (amplitude x envelope) for all channels

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity step_counter is
  port (
    clk: in bit;
    step_ctr: out unsigned(5 downto 0)
    );
end step_counter;

architecture behaviour of step_counter is
signal step_ctr_int: unsigned(5 downto 0) := (others=>'0');
begin
    process(clk)
    begin
    if rising_edge(clk) then
        step_ctr_int <= step_ctr_int + 1;
    end if;

    step_ctr <= step_ctr_int;
    end process;

end behaviour;