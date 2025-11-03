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


entity env_chop is
    -- similar to amplifier chop, this is the chop stage of the env controller
    port(
        step_ctr: in unsigned(5 downto 0);
        input_l: in std_logic;
        input_r: in std_logic;
        envelope_enabled: in std_logic;
        env_l: in unsigned(3 downto 0);
        env_r: in unsigned(3 downto 0);
        output_l: out std_logic;
        output_r: out std_logic
    );
end entity;

architecture behaviour of env_chop is
        signal E_l, E_r: unsigned(3 downto 0);
        signal C: unsigned(5 downto 0);
        signal env_step_0_l, env_step_1_9_l, env_step_2_5_10_13_l, env_step_6_7_14_15_l, env_step_8_l: std_logic;
        signal env_step_0_r, env_step_1_9_r, env_step_2_5_10_13_r, env_step_6_7_14_15_r, env_step_8_r: std_logic;
        signal chop_mask_l, chop_mask_r: std_logic;
begin

        C <= step_ctr;

        E_l(3) <= env_l(3);
        E_l(2) <= env_l(2);
        E_l(1) <= env_l(1);
        E_l(0) <= env_l(0);

        env_step_0_l <= '0';
        env_step_1_9_l <= E_l(1) AND C(0) AND NOT (C(1) OR C(2));
        env_step_2_5_10_13_l <= E_l(3) AND (C(1) XOR C(2));
        env_step_6_7_14_15_l <= E_l(2) AND C(2) AND C(1);
        env_step_8_l <= E_l(0) AND C(3) AND NOT (C(0) OR C(1) OR C(2));

        chop_mask_l <= not (env_step_0_l OR env_step_1_9_l OR env_step_2_5_10_13_l OR env_step_6_7_14_15_l OR env_step_8_l) OR NOT (envelope_enabled);
        output_l <= input_l and chop_mask_l;

        E_r(3) <= env_r(3);
        E_r(2) <= env_r(2);
        E_r(1) <= env_r(1);
        E_r(0) <= env_r(0);

        env_step_0_r <= '0';
        env_step_1_9_r <= E_r(1) AND C(0) AND NOT (C(1) OR C(2));
        env_step_2_5_10_13_r <= E_r(3) AND (C(1) XOR C(2));
        env_step_6_7_14_15_r <= E_r(2) AND C(2) AND C(1);
        env_step_8_r <= E_r(0) AND C(3) AND NOT (C(0) OR C(1) OR C(2));

        chop_mask_r <= not (env_step_0_r OR env_step_1_9_r OR env_step_2_5_10_13_r OR env_step_6_7_14_15_r OR env_step_8_r) OR NOT (envelope_enabled);
        output_r <= input_r and chop_mask_r;


end behaviour;