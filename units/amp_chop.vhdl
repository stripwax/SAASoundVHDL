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


entity amp_chop is
    -- amplifier logic is what "chops" the square waves using mask bits at 8mhz
    -- well documented in docs section.
    -- question: does every channel use the same masking patterns?  in other words, are the channels masking patterns synchronised
    --           to the same step counter, or could they be offset/flipped for different channels?
    --           test case: try enabling multiple channels with synchronised osc and changing osc levels
    --           test case: try setting 'DAC' mode (env enabled, osc mixer disabled) and changing osc levels AND env leves
    port(
        step_ctr: in unsigned(5 downto 0);
        input: in std_logic;
        envelope_enabled: in std_logic;
        amplitude_l: in unsigned(3 downto 0);
        amplitude_r: in unsigned(3 downto 0);
        output_l: out std_logic;
        output_r: out std_logic
    );
end entity;

architecture behaviour of amp_chop is
        signal A_l, A_r: unsigned(3 downto 0);
        signal C: unsigned(5 downto 0);
        signal amp_step_0_3_l, amp_step_4_7_l, amp_step_8_15_l, amp_step_16_31_48_63_l, amp_step_32_47_l: std_logic;
        signal amp_step_0_3_r, amp_step_4_7_r, amp_step_8_15_r, amp_step_16_31_48_63_r, amp_step_32_47_r: std_logic;
        signal chop_mask_l, chop_mask_r: std_logic;
begin

        C <= step_ctr;

        A_l(3) <= amplitude_l(3);
        A_l(2) <= amplitude_l(2);
        A_l(1) <= amplitude_l(1);
        A_l(0) <= amplitude_l(0) and not envelope_enabled; -- I still cannot understand the logic behind this behaviour

        amp_step_0_3_l <= '0';
        amp_step_4_7_l <= A_l(0) AND C(2) AND NOT (C(3) OR C(4) OR C(5));
        amp_step_8_15_l <= A_l(1) AND C(3) AND NOT (C(4) OR C(5));
        amp_step_16_31_48_63_l <= A_l(3) AND C(4);
        amp_step_32_47_l <= A_l(2) AND C(5) AND NOT C(4);

        chop_mask_l <= (amp_step_0_3_l OR amp_step_4_7_l OR amp_step_8_15_l OR amp_step_16_31_48_63_l OR amp_step_32_47_l);

        A_r(3) <= amplitude_r(3);
        A_r(2) <= amplitude_r(2);
        A_r(1) <= amplitude_r(1);
        A_r(0) <= amplitude_r(0) and not envelope_enabled; -- I still cannot understand the logic behind this behaviour

        amp_step_0_3_r <= '0';
        amp_step_4_7_r <= A_r(0) AND C(2) AND NOT (C(3) OR C(4) OR C(5));
        amp_step_8_15_r <= A_r(1) AND C(3) AND NOT (C(4) OR C(5));
        amp_step_16_31_48_63_r <= A_r(3) AND C(4);
        amp_step_32_47_r <= A_r(2) AND C(5) AND NOT C(4);

        chop_mask_r <= (amp_step_0_3_r OR amp_step_4_7_r OR amp_step_8_15_r OR amp_step_16_31_48_63_r OR amp_step_32_47_r);
        output_l <= input and chop_mask_l;
        output_r <= input and chop_mask_r;

end behaviour;