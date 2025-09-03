library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity mixer is
  -- a 1-bit mixer for saa1099
  -- takes as input the outputs of noise generator, frequency generator, amplitude (pdm) generator
  -- and the corresponding select/enable bits,
  -- and generates the corresponding output (1-bit) bitstream
  -- by simply ANDing the signals together
  -- In order to do this, we treat the output of noise as 1 when "noise_enabled" is false; and
  -- similarly we treat the output of oscillator as 1 when "freq_enable" is false
  -- The amplitude (pdm) generator already handles the complexity around freq_enable/env_enable combinations.
  port (
    noise_enable, freq_enable : in bit;
    noise_bitstream, freq_bitstream, amp_bitstream: in bit;
    mixed: out bit
    );
end mixer;

architecture behaviour of mixer is
signal noise_resolved_bitstream, freq_resolved_bitstream, env_resolved_bitstream: bit;
begin
    noise_resolved_bitstream <= (noise_bitstream or not noise_enable);
    freq_resolved_bitstream <= (freq_bitstream or not freq_enable);
    mixed <= noise_resolved_bitstream and freq_resolved_bitstream and amp_bitstream;
end behaviour;