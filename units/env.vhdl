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
-- halt_or_repeat = 0(halt after end_cycle) or 1(repeat after end_cycle)

-- counter counts down by 1 or 2 .  if counter is counting down by 2 then we take lsb to be zero for the 'ctr==0' checks

-- what happens when counter==1 and then you flip the 4-bit/3-bit mode to 3 bit?  does "ctr==0" now become true? and if so
-- what happens if you toggle 4-bit/3-bit at exactly this point?  does "ctr==0" somehow flip between true and false? or does
-- counter always reset to 15 as soon as ctr==0 regardless of 4-bit/3-bit mode?
-- how to test this edge case?

-- also: when inverting right hand side, what happens in 3-bit mode?  (is 0 flipped to 14 or 15? presumably 14 right?)


-- EN3, EN2, EN1:     [EN0 => right inverse]
-- 000 = constant zero, halt    =>  counter_output = 0, invert_output = 0, halt_or_repeat = 0, invert_flip = 0
-- 001 = constant high, repeat  =>  counter_output = 0, invert_output = 1, halt_or_repeat = 1, invert_flip = 0
-- 010 = saw down, halt         =>  counter_output = 1, invert_output = 0, halt_or_repeat = 0, invert_flip = 0
-- 011 = saw down, repeat       =>  counter_output = 1, invert_output = 0, halt_or_repeat = 1, invert_flip = 0
-- 100 = triangle, halt         =>  counter_output = 1, invert_output = 1, halt_or_repeat = 0, invert_flip = 1
-- 101 = triangle, repeat       =>  counter_output = 1, invert_output = 1, halt_or_repeat = 1, invert_flip = 1
-- 110 = saw up, halt           =>  counter_output = 1, invert_output = 1, halt_or_repeat = 0, invert_flip = 0
-- 111 = saw up, repeat         =>  counter_output = 1, invert_output = 1, halt_or_repeat = 1, invert_flip = 0

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

    signal counter: unsigned(3 downto 0);
    signal new_env_waiting : std_logic;
    signal env_lr_buffered, env_clk_source_buffered : std_logic;
    signal env_wave_buffer : std_logic_vector(2 downto 0);
    signal counter_output, halted, inverted, halt_or_repeat, invert_flip : std_logic;

begin
    process(clk)
        variable trigger : std_logic;
        variable effective_counter : unsigned(3 downto 0);
        variable next_counter : unsigned(3 downto 0);
        variable intermediate_out : unsigned(3 downto 0);
        variable calc_output_left : unsigned(3 downto 0);
    begin

        trigger := (osc_pulse AND not env_clk_source) OR (a0_pulse AND env_clk_source);

        if rising_edge(clk) then

            if not env_en then
                next_counter := "1111";
                halted <= '1';
            else
                -- if env_res='1' then
                --     -- 4 bit mode
                --     effective_counter := counter;
                -- else
                --     -- 3 bit mode , and lsb is fixed to be zero
                --     effective_counter := (counter(3 downto 1) & '0');
                -- end if;
                effective_counter(3 downto 1) := counter(3 downto 1);
                effective_counter(0) := counter(0) and env_res;


                if (halted='1' or effective_counter="0000") and new_env_waiting='1' then
                    -- process new env instruction here (this corresponds to position(3) or position(4))
                    halted <= '0';
                    next_counter := "1111";
                    -- load new wav defn from env_wav
                    -- for example:
                    counter_output <= '1';
                    inverted <= '1';
                    halt_or_repeat <= '1';
                    invert_flip <= '1';
                end if;

                if (halted='0' and trigger='1') then
                    if counter = "0000" then
                        if halt_or_repeat='0' and (invert_flip='0' or inverted='0') then
                            halted <= '1';
                        else
                            inverted <= inverted xor invert_flip;
                        end if;
                        next_counter := "1111";
                    else
                        if env_res='1' then
                            -- 4 bit mode
                            next_counter := counter-1;
                        else
                            next_counter := counter-2;
                        end if;
                    end if;
                   
                end if;

                counter <= next_counter;

                if counter_output and not(halted) then
                    intermediate_out := effective_counter;
                else
                    intermediate_out := "0000";
                end if;

                calc_output_left := intermediate_out xor (("111" & env_res) and (inverted & inverted & inverted & inverted));
                output_left <= calc_output_left;
                output_right <= calc_output_left xor (("111" & env_res) and (env_lr & env_lr & env_lr & env_lr));
            
            end if;
            
        end if;

    end process;

end behaviour;

