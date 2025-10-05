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

-- this is always running
-- this forms the backbone of the pulse density modulation that implements all the volume controls (amplitude x envelope) for all channels
-- question: do all channels' amplitude modules, and envelope modules, use a common synchronised step counter (i.e. step counter is shared and global)?  we assume yes.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity step_counter is
    port (
        clk: in bit;
        step_ctr: out unsigned(5 downto 0) := (others=>'0')
    );
end step_counter;

architecture behaviour of step_counter is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            step_ctr <= step_ctr + 1;
        end if;

    end process;

end behaviour;