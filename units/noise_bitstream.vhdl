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
    generic (
        MAPPED_SEL_REGISTER: integer;
        SEL_IN_UPPER : boolean := false
    );
  port (
    clk: in std_logic;
    data: in std_logic_vector(7 downto 0);
    reg : in std_logic_vector(4 downto 0);
    wr : in std_logic;
    trigger_313, trigger_156, trigger_76, trigger_osc : in std_logic;
    bitstream: out std_logic
    );
end noise_bitstream;

architecture behaviour of noise_bitstream is
    signal load_en: std_logic;
    signal reg_source_select: std_logic_vector(1 downto 0);
    signal source_select: std_logic_vector(1 downto 0);
    signal lsfr: std_logic_vector(17 downto 0) := "000000000000000001";  -- need power-on initialisation  -- question, are BOTH noise generators initialised identically?  [Confirmed: YES, but we have not yet confirmed the initialisation vector]
begin

    -- handle register writes
    load_en <= '1' when (wr = '1' and to_integer(unsigned(reg)) = MAPPED_SEL_REGISTER) else '0';

    sync_register_load : process(clk)
    begin   
        if rising_edge(clk) then
            if load_en = '1' then
                if SEL_IN_UPPER then
                    reg_source_select <= data(5 downto 4);
                else
                    reg_source_select <= data(1 downto 0);
                end if;
            end if;
        end if;
    end process;

    -- Combinatorial forwarding/bypass
    source_select <= data(5 downto 4) when (load_en = '1' and SEL_IN_UPPER=true) else
                     data(1 downto 0) when (load_en = '1' and SEL_IN_UPPER=false) else
                     reg_source_select;


    seq: process(clk)

        variable triggered: std_logic;
        variable lsb : std_logic;
        variable mask: std_logic_vector(17 downto 0);

    begin
        if rising_edge(clk) then
            case source_select is
                when "00" => triggered := trigger_313;
                when "01" => triggered := trigger_156;
                when "10" => triggered := trigger_76;
                when "11" => triggered := trigger_osc;
                when others => triggered := trigger_313;
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