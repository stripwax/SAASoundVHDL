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
    clk: in std_logic;
    octave_clks: in std_logic_vector(7 downto 0);
    sync: in std_logic;
    frequency: in unsigned(7 downto 0);
    octave: in unsigned(2 downto 0);
    octave_wr: in std_logic;
    output: out std_logic;
    trigger: out std_logic
    );
end osc;

architecture behaviour of osc is
    -- we have an 8-bit counter that operates in two phases
    -- a base phase counts 256 pulses of a (divided) clock i.e. from 0 up to 0 (overflow)
    -- a secondary phase counts up from @frequency to 0 (overflow)
    -- ctr_phase = '0' means base phase, ctr_phase = '1' means secondary (frequency register) phase
    -- the counter mode toggles between those two phases.
    signal counter: unsigned(7 downto 0) := (others=>'0');
    signal ctr_phase: std_logic := '0';
    signal latched_octave: unsigned(2 downto 0);
    signal latched_freq: unsigned(7 downto 0);
    signal octave_clk: std_logic;
    signal octave_clk_pulse: std_logic;
begin
    process(clk)
    begin

        if rising_edge(clk) then
            -- octave sets the clock divider.  octave needs to be latched (and the latched octave set the clock divider)
            -- because it is not possible to change octave mid-period ;  change is always deferred until the end of half-cycle
            -- We actually only want to 'tick' when octave counter changes from low to high so we turn the clk_div into a pulse
            octave_clk <= octave_clks(to_integer(latched_octave));
            octave_clk_pulse <= (octave_clks(to_integer(latched_octave)) and not octave_clk);

            trigger <= '0'; -- assume not triggered, but clauses below will pulse this as required

            if sync then
                counter <= "00000000";
                ctr_phase <= '0';
                latched_freq <= frequency;
                latched_octave <= octave;
                octave_clk <= '0';
                octave_clk_pulse <= '0';
                trigger <= '1';  -- unsure about this.  Is that what we need to correctly reproduce the "8mhz noise when sync'd" bug?  does that bug manifest for env generators too?
                output <= '1';  -- test case: check FRED space demo
            else

                if octave_clk_pulse then
                    if octave_wr='1' then
                        -- writing to octave register triggers a copy (latch) of the frequency register
                        -- which enables the next period to set the octave and frequency at the same time (no glitch)
                        -- setting frequency after that will be ignored until the next half cycle
                        latched_freq <= frequency;
                        latched_octave <= octave;
                    end if;

                    if counter = "11111111" then
                        if ctr_phase = '0' then
                            -- secondary  phase, counting up from frequency register
                            counter <= latched_freq;
                            ctr_phase <= '1';
                        else
                            -- reset to primary phase
                            counter <= "00000000";
                            ctr_phase <= '0';
                            trigger <= '1';  -- generate pulse on overflow, as required for env generator and noise generator

                            output <= not output;  -- toggle output bit
                            latched_freq <= frequency;
                            -- latched_octave <= octave; -- probably unnecessary since octave only changes when it has been written to, which has already been checked in a previous claus
                        end if;
                    else
                        counter <= counter + 1;
                    end if;
                end if;
            end if;
        end if;

    end process;

end behaviour;