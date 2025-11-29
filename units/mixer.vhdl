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
  -- In order to do this, we treat the output of noise as 0 when "noise_enabled" is false; and
  -- similarly we treat the output of oscillator as 0 when "freq_enable" is false
  -- The amplitude (pdm) chopping step takes place after mixing
  -- (and for channels that also have envelope generators (2 and 5), the envelope (pdm) chopping takes place
  --  after that, after mixing and after amplitude (pdm) chopping.  Because of a required behaviour of the envelope
  --  output, the mixer actually outputs 1 in the case where both "noise_enabled" and "freq_enabled" are false.
  --  This 'feature' could be implemented either by the mixer or by the amp (pdm) that follows it; I don't really care.
  --  But without this, the "amp behaves like a primitive DAC when env is enabled" behaviour would not function correctly.)
  port (
    noise_enable, freq_enable, env_enable : in std_logic;
    noise_bitstream, freq_bitstream : in std_logic;
    mixed: out std_logic
    );
end mixer;

architecture behaviour of mixer is
  signal noise_resolved_bitstream, freq_resolved_bitstream: std_logic;
begin
    --
    -- NOISE | FREQ | NE | FE | OUTPUT
    --   X   |  X   | 0  | 0  | 0   -- (or 1 if ENV is enabled, to be multiplied by ENV output)
    --   0   |  X   | 1  | 0  | 0
    --   1   |  X   | 1  | 0  | 1
    --   X   |  0   | 0  | 1  | 0
    --   X   |  1   | 0  | 1  | 1
    --   0   |  0   | 1  | 1  | 0
    --   1   |  0   | 1  | 1  | 0
    --   0   |  1   | 1  | 1  | 0
    --   1   |  1   | 1  | 1  | 1

    -- Confirmed that polarity of the NOISE output is unaffected by FE=0 or FE=1
    -- (NOISE output is always the inverse of the lfsr lsb, regardless of whether freq is enabled or not for that channel)
    -- TODO simplify mixer by inverting the output of the noise_bitstream instead?
    noise_resolved_bitstream <= (not noise_bitstream and noise_enable);
    freq_resolved_bitstream <= (freq_bitstream and freq_enable);
    mixed <= (noise_resolved_bitstream and freq_resolved_bitstream)
          or (noise_resolved_bitstream and not freq_enable)
          or (freq_resolved_bitstream and not noise_enable)
          or (env_enable and not freq_enable and not noise_enable);
end behaviour;