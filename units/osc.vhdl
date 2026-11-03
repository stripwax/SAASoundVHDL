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
    generic (
        MAPPED_FREQ_REGISTER: integer;
        MAPPED_OCT_REGISTER: integer;
        OCT_IN_UPPER : boolean := false
    );
    port (
        clk: in std_logic;
        data: in std_logic_vector(7 downto 0);
        reg : in std_logic_vector(4 downto 0);
        wr : in std_logic;
        octave_clks: in std_logic_vector(7 downto 0);
        sync: in std_logic;
        output: out std_logic := '0';
        trigger: out std_logic
    );
end osc;

architecture behaviour of osc is

    signal freq_load_en, oct_load_en: std_logic;
    signal reg_octave: unsigned(2 downto 0) := (others=>'0'); -- REMOVE INIT?
    signal reg_frequency: unsigned(7 downto 0) := (others=>'0'); -- REMOVE INIT?;

    signal octave: unsigned(2 downto 0);
    signal frequency: unsigned(7 downto 0);

    -- we have a 9-bit counter , initialised with the value of the frequency register
    -- and counting up until all bits are set
    signal counter: unsigned(8 downto 0) := (others=>'0');
    signal latched_octave: unsigned(2 downto 0) := (others=>'0'); -- REMOVE INIT?;
    signal latched_freq: unsigned(7 downto 0) := (others=>'0'); -- REMOVE INIT?;
begin

    -- handle register writes
    freq_load_en <= '1' when (wr = '1' and to_integer(unsigned(reg)) = MAPPED_FREQ_REGISTER) else '0';
    oct_load_en <= '1' when (wr = '1' and to_integer(unsigned(reg)) = MAPPED_OCT_REGISTER) else '0';

    -- Combinatorial forwarding/bypass
    octave <= unsigned(data(6 downto 4)) when (oct_load_en ='1' and OCT_IN_UPPER=true) else
              unsigned(data(2 downto 0)) when (oct_load_en ='1' and OCT_IN_UPPER=false) else
              reg_octave;
    frequency <= unsigned(data) when freq_load_en = '1' else reg_frequency;

    sync_register_load : process(clk)
    begin   
        if rising_edge(clk) then
            if freq_load_en = '1' then
                reg_frequency <= unsigned(data);
            end if;
            if oct_load_en = '1' then
                reg_octave <= unsigned(data(6 downto 4)) when (oct_load_en ='1' and OCT_IN_UPPER=true) else
                              unsigned(data(2 downto 0)) when (oct_load_en ='1' and OCT_IN_UPPER=false);
            end if;
        end if;
    end process;

    seq: process(clk)
        variable octave_clk_pulse: std_logic;
        variable load: std_logic;
        variable overflow: std_logic;
        variable next_counter: unsigned(8 downto 0);
    begin

        if rising_edge(clk) then

            -- octave sets the clock divider.  octave needs to be latched (and the latched octave set the clock divider)
            -- because it is not possible to change octave mid-period ;  change is always deferred until the end of half-cycle
            -- writing to octave register triggers a copy (latch) of the frequency register
            -- which enables the next period to set the octave and frequency at the same time (no glitch)
            -- setting frequency after that will be ignored until the next half cycle
            if oct_load_en='1' or sync='1' then
                latched_freq <= frequency;
            end if;

            trigger <= '0'; -- assume not triggered, but clauses below will pulse this as required

            octave_clk_pulse := octave_clks(7-to_integer(latched_octave));

            load := '0';
            overflow := '0';
            next_counter := counter + 1;
            if (octave_clk_pulse='1') and (next_counter="000000000") then
                -- since this doesn't depend on sync='0', this is what reproduces the "8mhz noise when sync'd" bug (feature?)
                overflow := '1';
            end if;
            trigger <= overflow; -- this is the output that is wired up to noise gen and env gen.  QUESTION does env gen also have an equivalent  "8mhz when sync'd" bug?  ANSWER yes, and what an excellent discovery!

            if sync='1' then
                counter <= "111111111"; -- rearmed so that next tick after sync has been cleared will trigger the overflow condition and flip output and reload the counter
                --counter <= "0" & latched_freq;
                load := '1';
                output <= '0';  -- I'm fairly certain this is true, but need to check test case: FRED space demo.  QUESTION: does output immediately flip to 1 when sync disabled?
            elsif overflow='1' then
                -- this marks the end of a (half) wave.  (or sync/reset flag is set)
                --counter <= "0" & latched_freq;
                counter <= "0" & latched_freq + 1;
                output <= not output;
                -- reload frequency/octave registers now for next half wave because they may have changed
                load := '1';
            elsif octave_clk_pulse='1' then
                counter <= next_counter;
            end if;

            if load='1' then
                latched_freq <= frequency;
                latched_octave <= octave;
            end if;

        end if;

    end process;

end behaviour;