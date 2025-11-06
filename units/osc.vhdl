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
    -- a primary phase counts up from @frequency to 0 (overflow)
    -- a secondary phase counts 256 pulses of a (divided) clock i.e. from 0 up to 0 (overflow)
    -- ctr_phase = '0' means primary phase, ctr_phase = '1' means secondary
    -- the counter mode toggles between those two phases.
    signal counter: unsigned(7 downto 0) := (others=>'0');
    signal ctr_phase: std_logic := '0';
    signal octave_clks: unsigned(7 downto 0);
    signal latched_octave: unsigned(2 downto 0);
    signal latched_freq: unsigned(7 downto 0);
    signal octave_clk_pulse_diag: std_logic;
begin
    process(clk)
        variable next_octave_clks: unsigned(7 downto 0);
        variable octave_clk_pulse: std_logic;
    begin

        if rising_edge(clk) then

            -- octave sets the clock divider.  octave needs to be latched (and the latched octave set the clock divider)
            -- because it is not possible to change octave mid-period ;  change is always deferred until the end of half-cycle
            -- writing to octave register triggers a copy (latch) of the frequency register
            -- which enables the next period to set the octave and frequency at the same time (no glitch)
            -- setting frequency after that will be ignored until the next half cycle
            if octave_wr='1' then
                latched_freq <= frequency;
            end if;

            trigger <= '0'; -- assume not triggered, but clauses below will pulse this as required

            if sync then
                counter <= "11111111";
                octave_clks <= "11111111";
                ctr_phase <= '1';
                latched_freq <= frequency;
                latched_octave <= octave;
                trigger <= '1';  -- this is what reproduces the "8mhz noise when sync'd" bug (feature?)
                output <= '1';  -- test case: check FRED space demo
            else

                next_octave_clks := octave_clks + 1;
                octave_clks <= next_octave_clks;

                octave_clk_pulse := (not next_octave_clks(7-to_integer(latched_octave))) and octave_clks(7-to_integer(latched_octave));
                octave_clk_pulse_diag <= octave_clk_pulse;

                if octave_clk_pulse then
                    if counter = "11111111" then
                        if ctr_phase = '0' then
                            -- primary phase complete, do secondary phase
                            counter <= "00000000";
                            ctr_phase <= '1';
                        else
                            -- done secondary phase, switch back to primary phase, counting up from frequency register
                            -- this marks the end of a (half) wave.
                            -- reload frequency/octave registers now for next half wave because they may have changed
                            counter <= latched_freq;
                            ctr_phase <= '0';
                            trigger <= '1';  -- generate pulse on overflow, as required for env generator and noise generator

                            output <= not output;  -- toggle output bit
                            latched_freq <= frequency;
                            latched_octave <= octave;
                            octave_clks <= "00000000";  -- always reset octave clks here, because we (may have) changed octave
                        end if;
                    else
                        counter <= counter + 1;
                    end if;
                end if;
            end if;
        end if;

    end process;

end behaviour;