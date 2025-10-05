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
  -- Oscillators require 8 octaves, corresponding to dividing by 2, 4, 8, 16, 32, 64, 128, 256
  -- Noise generators require clocks at 31.3khz, 15.6khz and 7.6khz
  -- (respectively, divide by 256, 512, 1024)
  -- Is this what the datasheet means by /8 octave clocks and /3 internal clocks?
  port (
    clk: in std_logic;
    clk_div: out std_logic_vector(9 downto 0) := (others => '0')
    );
end clocks;

architecture behaviour of clocks is
begin
    process(clk)
    begin
    if rising_edge(clk) then
        -- question: which clocks (if any) still tick when SYNC bit is set? I may need to connect to SYNC bit here.
        -- question: are all these clocks shared across all the oscs and noise generators, or do they have their own counters?
        --           (I assume all shared to reduce silicon, but should be a test case with chip to confirm)
        clk_div <= std_logic_vector(unsigned(clk_div) + 1);
    end if;
    end process;

end behaviour;