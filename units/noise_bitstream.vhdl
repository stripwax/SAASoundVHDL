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
--
--	https://www.vogons.org/viewtopic.php?f=9&t=51695
--	SAA1099P noise generator as documented by Jepael
--	18-bit Galois LFSR
--	Feedback polynomial = x^18 + x^11 + x^1
--	Period = 2^18-1 = 262143 bits
--	Verified to match recorded noise from my SAA1099P
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity noise_bitstream is
  -- a bitstream output of noise generator
  -- takes as input the various frequency sources and triggers
  -- and generates the corresponding output (1-bit) bitstream
  port (
    clk: in bit;
    trigger_313, trigger_156, trigger_76, trigger_osc : in bit;
    enabled: in bit_vector(1 downto 0);
    bitstream: out bit
    );
end noise_bitstream;

architecture behaviour of noise_bitstream is
signal lsfr: bit_vector(17 downto 0) := "000000000000000001";  -- need power-on initialisation
begin
    process(clk)

    variable triggered: bit;
    variable lsb : bit;
    variable mask: bit_vector(17 downto 0);

    begin
    if rising_edge(clk) then
        case enabled is
            when "00" => triggered := trigger_313;
            when "01" => triggered := trigger_156;
            when "10" => triggered := trigger_76;
            when "11" => triggered := trigger_osc;
        end case;
        if triggered then
            lsb := lsfr(0);
            mask := lsb & "000000" & lsb & "0000000000";
            lsfr <= ('0' & lsfr(17 downto 1)) xor mask;
            bitstream <= lsb;
        end if;
    end if;
    end process;

end behaviour;