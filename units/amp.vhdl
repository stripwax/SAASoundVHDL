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


entity amp is
    -- amplifier logic is what "chops" the square waves using mask bits at 8mhz
    -- well documented in docs section.
    -- question: does every channel use the same masking patterns?  in other words, are the channels masking patterns synchronised
    --           to the same step counter, or could they be offset/flipped for different channels?
    --           test case: try enabling multiple channels with synchronised osc and changing osc levels
    --           test case: try setting 'DAC' mode (env enabled, osc mixer disabled) and changing osc levels AND env leves
    port(
        step_ctr: in unsigned(5 downto 0);
        amplitude_level: in unsigned(3 downto 0);
        envelope_level: in unsigned(3 downto 0);
        envelope_enabled: in std_logic;
        frequency_enabled: in std_logic;
        chop_mask: out std_logic
    );
end entity;

architecture behaviour of amp is
        signal A: unsigned(3 downto 0);
        signal E: unsigned(3 downto 0);
        signal C: unsigned(5 downto 0);
        signal amp_step_0_3, amp_step_4_7, amp_step_8_15, amp_step_16_31_48_63, amp_step_32_47: std_logic;
        signal env_step_0, env_step_1_9, env_step_2_5_10_13, env_step_6_7_14_15, env_step_8: std_logic;
        signal amp_bitstream: std_logic;
        signal env_bitstream: std_logic;
begin

        C <= step_ctr;

        A(3) <= amplitude_level(3);
        A(2) <= amplitude_level(2);
        A(1) <= amplitude_level(1);
        A(0) <= amplitude_level(0) and not envelope_enabled; -- I still cannot understand the logic behind this behaviour

        E(3) <= envelope_level(3);
        E(2) <= envelope_level(2);
        E(1) <= envelope_level(1);
        E(0) <= envelope_level(0);

        amp_step_0_3 <= '0';
        amp_step_4_7 <= A(0) AND C(2) AND NOT (C(3) OR C(4) OR C(5));
        amp_step_8_15 <= A(1) AND C(3) AND NOT (C(4) OR C(5));
        amp_step_16_31_48_63 <= A(3) AND C(4);
        amp_step_32_47 <= A(2) AND C(5) AND NOT C(4);
        amp_bitstream <= (amp_step_0_3 OR amp_step_4_7 OR amp_step_8_15 OR amp_step_16_31_48_63 OR amp_step_32_47) OR NOT (frequency_enabled);

        env_step_0 <= '0';
        env_step_1_9 <= E(1) AND C(0) AND NOT (C(1) OR C(2));
        env_step_2_5_10_13 <= E(3) AND (C(1) XOR C(2));
        env_step_6_7_14_15 <= E(2) AND C(2) AND C(1);
        env_step_8 <= E(0) AND C(3) AND NOT (C(0) OR C(1) OR C(2));
        env_bitstream <= (env_step_0 OR env_step_1_9 OR env_step_2_5_10_13 OR env_step_6_7_14_15 OR env_step_8) OR NOT (envelope_enabled);

        chop_mask <= amp_bitstream AND env_bitstream;

end behaviour;