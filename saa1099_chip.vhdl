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

entity saa1099_digital_output is
  -- essentially saa1099 i/o but with additional digital (rather than analog) outputs
  -- outputs are bitstreams synchronised with clk
  -- you can convert these digital outputs to analog via a combination of filters and mixers
  port (
    wr_, cs_, clk, a0 : in std_logic_bit,
    dtack_ : out std_logic_bit,
    d : in std_logic_vector(7 downto 0),
    outl : out bit_vector(5 downto 0),
    outr : out bit_vector(5 downto 0),
    -- power_on_reset : in std_logic_bit  -- TODO: model power-on-reset behaviour explicitly?
    );
end saa1099_digital_output;

architecture behaviour of saa1099_digital_output is
    signal _reg : std_logic_vector(4 downto 0),
    signal amp0 : std_logic_vector(7 downto 0),
    signal amp1 : std_logic_vector(7 downto 0),
    signal amp2 : std_logic_vector(7 downto 0),
    signal amp3 : std_logic_vector(7 downto 0),
    signal amp4 : std_logic_vector(7 downto 0),
    signal amp5 : std_logic_vector(7 downto 0),
    signal freq0 : std_logic_vector(7 downto 0),
    signal freq1 : std_logic_vector(7 downto 0),
    signal freq2 : std_logic_vector(7 downto 0),
    signal freq3 : std_logic_vector(7 downto 0),
    signal freq4 : std_logic_vector(7 downto 0),
    signal freq5 : std_logic_vector(7 downto 0),
    signal oct0 : std_logic_vector(2 downto 0),
    signal oct1 : std_logic_vector(2 downto 0),
    signal oct2 : std_logic_vector(2 downto 0),
    signal oct3 : std_logic_vector(2 downto 0),
    signal oct4 : std_logic_vector(2 downto 0),
    signal oct5 : std_logic_vector(2 downto 0),
    signal freq0_en : std_logic_bit, -- frequency enable
    signal freq1_en : std_logic_bit,
    signal freq2_en : std_logic_bit,
    signal freq3_en : std_logic_bit,
    signal freq4_en : std_logic_bit,
    signal freq5_en : std_logic_bit,
    signal noise0_en : std_logic_bit, -- noise enable
    signal noise1_en : std_logic_bit,
    signal noise2_en : std_logic_bit,
    signal noise3_en : std_logic_bit,
    signal noise4_en : std_logic_bit,
    signal noise5_en : std_logic_bit,
    signal noise0_sel : std_logic_vector(1 downto 0),
    signal noise1_sel : std_logic_vector(1 downto 0),
    signal env0_lr : std_logic_bit,
    signal env0_wave : std_logic_vector(2 downto 0),
    signal env0_res : std_logic_bit,
    signal env0_clk_source : std_logic_bit,
    signal env0_en : std_logic_bit,
    signal env1_lr : std_logic_bit,
    signal env1_wave : std_logic_vector(2 downto 0),
    signal env1_res : std_logic_bit,
    signal env1_clk_source : std_logic_bit,
    signal env1_en : std_logic_bit,
    signal sync_rst : std_logic_bit,
    signal enable : bit = '0',  -- TODO: model power-on-reset behaviour explicitly?

    signal a0_pulse: std_logic_bit,

begin
    process (clk)
    begin
        -- we need to track if this was an 'address' write, and if so send a pulse to the envelope generators
        a0_pulse = '0';

        if rising_edge(clk) then
            if /wr_ and /cs_ then
                if /a0 and /a0_pulse then
                    -- a0 drawn low, and a0_pulse was low so set a0_pulse for one cycle
                    a0_pulse = '1';
                end if;

                if /a0 then
                    _reg <= d;
                else
                    if _reg(4 downto 3) = "00" then
                        -- amplitude register; need to consider wait states
                        --
                        if _reg(2 downto 0) = "000" then
                            amp0 <= d;
                        else if _reg(2 downto 0) = "001" then
                            amp1 <= d;
                        else if _reg(2 downto 0) = "010" then
                            amp2 <= d;
                        else if _reg(2 downto 0) = "011" then
                            amp3 <= d;
                        else if _reg(2 downto 0) = "100" then
                            amp4 <= d;
                        else if _reg(2 downto 0) = "101" then
                            amp5 <= d;
                        else
                            -- unused
                        end if;
                    else if _reg(4 downto 3) = "01" then
                        -- freq register
                        if _reg(2 downto 0) = "000" then
                            freq0 <= d;
                        else if _reg(2 downto 0) = "001" then
                            freq1 <= d;
                        else if _reg(2 downto 0) = "010" then
                            freq2 <= d;
                        else if _reg(2 downto 0) = "011" then
                            freq3 <= d;
                        else if _reg(2 downto 0) = "100" then
                            freq4 <= d;
                        else if _reg(2 downto 0) = "101" then
                            freq5 <= d;
                        else
                            -- unused
                        end if;
                    else if _reg(4 downto 0) = "10000" then
                        -- osc0 and 1 register
                        osc0(2 downto 0) <= d(2 downto 0);
                        osc1(2 downto 0) <= d(6 downto 4);
                    else if _reg(4 downto 0) = "10001" then
                        -- osc2 and 3 register
                        osc2(2 downto 0) <= d(2 downto 0);
                        osc3(2 downto 0) <= d(6 downto 4);
                    else if _reg(4 downto 0) = "10010" then
                        -- osc4 and 5 register
                        osc4(2 downto 0) <= d(2 downto 0);
                        osc5(2 downto 0) <= d(6 downto 4);
                    else if _reg(4 downto 0) = "10100" then
                        freq0_en <= d(0 downto 0);
                        freq1_en <= d(1 downto 1);
                        freq2_en <= d(2 downto 2);
                        freq3_en <= d(3 downto 3);
                        freq4_en <= d(4 downto 4);
                        freq5_en <= d(5 downto 5);
                    else if _reg(4 downto 0) = "10101" then
                        noise0_en <= d(0 downto 0);
                        noise1_en <= d(1 downto 1);
                        noise2_en <= d(2 downto 2);
                        noise3_en <= d(3 downto 3);
                        noise4_en <= d(4 downto 4);
                        noise5_en <= d(5 downto 5);
                    else if _reg(4 downto 0) = "10110" then
                        noise0_sel <= d(1 downto 0);
                        noise1_sel <= d(5 downto 4);
                    else if _reg(4 downto 0) = "11000" then
                        env0_lr <= d(0 downto 0);
                        env0_wave(2 downto 0) <= d(3 downto 1);
                        env0_res <= d(4 downto 4);
                        env0_clk_source <= d(5 downto 5);
                        env0_en <= d(7 downto 7);
                    else if _reg(4 downto 0) = "11001" then
                        env1_lr <= d(0 downto 0);
                        env1_wave(2 downto 0) <= d(3 downto 1);
                        env1_res <= d(4 downto 4);
                        env1_clk_source <= d(5 downto 5);
                        env1_en <= d(7 downto 7);
                    else if _reg(4 downto 0) = "11100" then
                        enable <= d(0 downto 0);
                        sync_rst <= d(1 downto 1);
                    else
                        -- unused
                    end if;
                end if;
            end if;
        end if;
    end process;
end behaviour;