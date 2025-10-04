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

entity osc is
  -- square wave oscillator output with frequency & octave control inputs
  -- and count-zero trigger output
  port (
    clk: in bit;
    sync: in bit;
    frequency: in unsigned(7 downto 0);
    octave: in unsigned(2 downto 0);
    octave_wr: in bit;
    output: out bit;
    trigger: out bit
    );
end osc;

architecture behaviour of osc is
    signal counter: unsigned(7 downto 0) := (others=>'0');
    signal div_counter: unsigned(2 downto 0) := (others=>'0');  -- question: does every osc have their own div_counter or is there a shared set of 8 triggers?  test case: is it possible to run two oscs at same frequency+octave but mismatched phase.  pretty sure the answer is yes.
    signal latched_freq: unsigned(7 downto 0);
    signal latched: bit := '0';
begin
    process(clk)
    variable counter_overflow: bit;
    begin

    if rising_edge(clk) then

        if counter="11111111" then
            counter_overflow := '1';
        else
            counter_overflow := '0';
        end if;

        if sync then
            div_counter <= octave;
            counter <= frequency;
            latched_freq <= frequency;
            latched <= '1';
            counter_overflow := '1';  -- unsure about this.  Is that what we need to correctly reproduce the "8mhz noise when sync'd" bug?
            output <= '1';  -- test case: check FRED space demo
        else
            if div_counter/="111" then
                div_counter <= div_counter+1;
            else
                div_counter <= octave;

                if octave_wr='1' then
                    -- writing to octave register triggers a copy (latch) of the frequency register
                    -- which enables the next period to set the octave and frequency at the same time (no glitch)
                    -- setting frequency after that will be ignored until the next half cycle
                    latched_freq <= frequency;
                    latched <= '1'; -- note, since signal, won't be updated until end of process
                end if;
                
                if counter_overflow = '1' then
                    output <= not output;  -- toggle output bit
                    if latched = '1' or octave_wr ='1' then
                        counter <= latched_freq;
                        latched <= '0';
                    else
                        counter <= frequency;
                    end if;
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;

        trigger <= counter_overflow;  -- pulses when output toggles, used to trigger the connected noise or env device

    end if;

    end process;

end behaviour;