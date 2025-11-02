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

entity mixer is
  -- a 1-bit mixer for saa1099
  -- takes as input the outputs of noise generator, frequency generator
  -- and the corresponding select/enable bits,
  -- and generates the corresponding output (1-bit) bitstream
  -- by simply ANDing the signals together
  -- In order to do this, we treat the output of noise as 1 when "noise_enabled" is false; and
  -- similarly we treat the output of oscillator as 1 when "freq_enable" is false
  -- The amplitude (pdm) generator step takes place after mixing
  port (
    noise_enable, freq_enable : in std_logic;
    noise_bitstream, freq_bitstream : in std_logic;
    mixed: out std_logic
    );
end mixer;

architecture behaviour of mixer is
signal noise_resolved_bitstream, freq_resolved_bitstream: std_logic;
begin
    noise_resolved_bitstream <= (noise_bitstream or not noise_enable);
    freq_resolved_bitstream <= (freq_bitstream or not freq_enable);
    mixed <= noise_resolved_bitstream and freq_resolved_bitstream;
end behaviour;