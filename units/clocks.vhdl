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
    step_ctr: out unsigned(5 downto 0);
    octave_clks: out std_logic_vector(7 downto 0);
    noise_clks: out std_logic_vector(2 downto 0)
    );
end clocks;

architecture behaviour of clocks is
    signal clk_div: unsigned(9 downto 0) := (others => '1');
begin
    process(clk)
        variable next_clk_div: unsigned(9 downto 0);
        variable pulse_divs: std_logic_vector(9 downto 0);
    begin
    if rising_edge(clk) then
        -- interpretation of experimentals observations:
        --   all clocks still tick when SYNC bit is set.
        --   all clocks are shared across all the oscs and noise generators
        --   the consumers of the clocks just need the pulses (edge), rather than square waves
        -- These simplifications all make sense in terms of reducing silicon on the real device
        next_clk_div := clk_div + 1;
        pulse_divs := (std_logic_vector(clk_div(9 downto 0)) AND NOT std_logic_vector(next_clk_div(9 downto 0)));
        noise_clks <= pulse_divs(9 downto 7);
        octave_clks <= pulse_divs(7 downto 0);
        step_ctr <= next_clk_div(5 downto 0);
        clk_div <= next_clk_div;
    end if;
    end process;

end behaviour;