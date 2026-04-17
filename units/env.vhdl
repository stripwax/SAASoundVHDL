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

-- counter initialised to 15
-- counter counts down always
-- counter halts after counting-down-to-zero, or repeats
-- output could be:
--    (a) output of the counter;
--    (b) output of constant 0;
--    the inverse of either (a) or (b)
--    Represent this with two flags:
--        counter_output (if true, counter is output; if false, zero is output)
--        invert_output (if true, output is inverted)
-- after 16 steps:
--    invert_output could flip (i.e. for triangles)
--    Represent this with invert_flip flag
-- the "halt or repeat after counting down to zero" takes into account an inverse-flip flag i.e. if inverse_flip is true then only act on halt/repeat if inverse is false (i.e. we finished counting DOWN)
--
-- Note that 'haltedness' is synonymous with 'env output remains zero until envelope is reinitialized'

-- so:
-- counter_output = 1(ctr) or 0(0)
-- invert_output = 0(output = counter_output) or 1(output = !counter_output)
-- invert_flip = 0(single-cycle) or 1(double-cycle i.e. triangle)
-- 'end_cycle' = ctr==0 AND (invert_flip==FALSE or INVERT=TRUE)
-- wav_repeat = 0(halt after end_cycle) or 1(repeat after end_cycle)

-- counter counts down by 1 or 2 .  if counter is counting down by 2 then we take lsb to be zero for the 'ctr==0' checks

-- what happens when counter==1 and then you flip the 4-bit/3-bit mode to 3 bit?  does "ctr==0" now become true? and if so
-- what happens if you toggle 4-bit/3-bit at exactly this point?  does "ctr==0" somehow flip between true and false? or does
-- counter always reset to 15 as soon as ctr==0 regardless of 4-bit/3-bit mode?
-- how to test this edge case?

-- also: when inverting right hand side, what happens in 3-bit mode?  (is 0 flipped to 14 or 15? presumably 14 right?)


-- EN3, EN2, EN1:     [EN0 => right inverse]
-- 000 = constant zero, halt    =>  counter_output = 0, invert_output = 0, wav_repeat = 0, invert_flip = 0
-- 001 = constant high, repeat  =>  counter_output = 0, invert_output = 1, wav_repeat = 1, invert_flip = 0
-- 010 = saw down, halt         =>  counter_output = 1, invert_output = 0, wav_repeat = 0, invert_flip = 0
-- 011 = saw down, repeat       =>  counter_output = 1, invert_output = 0, wav_repeat = 1, invert_flip = 0
-- 100 = triangle, halt         =>  counter_output = 1, invert_output = 1, wav_repeat = 0, invert_flip = 1
-- 101 = triangle, repeat       =>  counter_output = 1, invert_output = 1, wav_repeat = 1, invert_flip = 1
-- 110 = saw up, halt           =>  counter_output = 1, invert_output = 1, wav_repeat = 0, invert_flip = 0
-- 111 = saw up, repeat         =>  counter_output = 1, invert_output = 1, wav_repeat = 1, invert_flip = 0

-- actually you can just do invert flip and associated logic using a 5-bit counter instead, the MSB is the flag to say when to invert.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity env is
    -- envelope generator (see data sheet)
    port(
        clk : in std_logic;
        env_write : in std_logic;
        env_lr : in std_logic;
        env_wave : std_logic_vector(2 downto 0);
        env_res : std_logic;
        env_clk_source : std_logic;
        env_en : std_logic;
        osc_pulse: in std_logic;
        a0_pulse : in std_logic;

        output_left, output_right : out unsigned(3 downto 0)
    );
end env;

architecture behaviour of env is

    signal counter: unsigned(4 downto 0);
    signal env_lr_buffered, env_clk_source_buffered : std_logic;
    signal env_wave_buffered : std_logic_vector(2 downto 0);
    signal counter_output, halted, inverted, wav_repeat : std_logic;

    signal debug_env_wave_val : std_logic_vector(2 downto 0);
    signal debug_env_lr_val, debug_env_clk_source_val : std_logic;

begin
    process(clk)
        variable trigger : std_logic;
        variable effective_counter : unsigned(4 downto 0);
        variable next_counter : unsigned(4 downto 0);
        variable intermediate_out : unsigned(3 downto 0);
        variable calc_output_left : unsigned(3 downto 0);
        variable env_wave_val : std_logic_vector(2 downto 0);
        variable env_lr_val : std_logic;
        variable env_clk_source_val : std_logic;
        variable halted_val : std_logic;
        variable invert_flip : std_logic;
        variable ctr_zero : std_logic;
    begin

        if rising_edge(clk) then

            -- use variables to represent the output of the buffered values OR the input (if env_write is strobed)
            -- which we can use to then load into the buffer for the next clock and/or program the env gen this clock
            env_wave_val := env_wave_buffered;
            env_lr_val := env_lr_buffered;
            env_clk_source_val := env_clk_source_buffered;
            halted_val := halted;
            if env_write then
                env_wave_buffered <= env_wave;
                env_wave_val := env_wave;

                env_lr_buffered <= env_lr;
                env_lr_val := env_lr;

                env_clk_source_buffered <= env_clk_source;
                env_clk_source_val := env_clk_source;

                halted_val := not env_en;
            end if;

            debug_env_clk_source_val <= env_clk_source_val;
            debug_env_lr_val <= env_lr_val;
            debug_env_wave_val <= env_wave_val;

            trigger := (osc_pulse AND not env_clk_source_val) OR (a0_pulse AND env_clk_source_val);
            effective_counter := (counter(4 downto 1)) & (counter(0) and not env_res);
            ctr_zero := '1' when effective_counter="00000" else '0';
            if (not halted and not env_write) and ctr_zero and not wav_repeat then
                -- waveform was running, has reached end, so is now done, and state machine now halts.  a subequent env_write will restart (assuming env_en is set)
                halted_val := '1';
            elsif ((halted and env_write) or (ctr_zero  and wav_repeat)) then
                -- process new env instruction here (this corresponds to position(3) or position(4))
                -- load new wav defn from env_wav:
                counter_output <= '0' when env_wave_val(2 downto 1)="00" else '1';
                inverted <= '1' when env_wave_val(2 downto 0)="001" or env_wave_val(2)='1' else '0';
                wav_repeat <= env_wave_val(0);
                invert_flip := '1' when env_wave_val(2 downto 1)="10" else '0';
                next_counter := invert_flip & "1111";  -- interesting here.. what actually happens if we go through one complete wave using manual (a0) trigger, starting in 4-bit mode but changing to 3-bit mode half way, and then rerun a second time here and THEN change back to 4-bit mode half way through the second cycle?  We should be able to see if we actually preserved the LSB when counter was reset, or if LSB was reset to 0 because we reset the counter when still in 3-bit mode!!
            elsif (halted_val='0' and trigger='1') then
                if env_res='0' then
                    -- 4 bit mode
                    next_counter := counter-1;
                else
                    next_counter := counter-2;  -- based on my understanding that LSB is still actually preserved when the resolution is changed from 4 to 3 bits (easily confirmed by changing resolution back to 4 bits, in the SAME env wave cycle, there's a SAA test case for that in the .dsk)
                end if;
                
            end if;

            if counter_output and not(halted_val) then
                intermediate_out := effective_counter(3 downto 0);
            else
                intermediate_out := "0000";
            end if;

            calc_output_left := intermediate_out xor (("111" & not env_res) and (inverted & inverted & inverted & inverted));
            output_left <= calc_output_left;
            output_right <= calc_output_left xor (("111" & not env_res) and (env_lr_val & env_lr_val & env_lr_val & env_lr_val));
            
            counter <= next_counter;
            halted <= halted_val;

        end if;

    end process;

end behaviour;

