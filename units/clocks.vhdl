--    SAASoundVHDL - hardware description of Philips SAA1099 device in VHDL and other languages
--    Copyright (C) 2025  David Hooper (github.com/stripwax)
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <https://www.gnu.org/licenses/>.

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