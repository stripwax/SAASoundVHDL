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


-- EN3, EN2, EN1:     [EN0 => right inverse]
-- 000 = constant zero, halt    =>  counter_output = 0, invert_output = 0, halt_or_repeat = 0, invert_flip = 0
-- 001 = constant high, repeat  =>  counter_output = 0, invert_output = 1, halt_or_repeat = 1, invert_flip = 0
-- 010 = saw down, halt         =>  counter_output = 1, invert_output = 0, halt_or_repeat = 0, invert_flip = 0
-- 011 = saw down, repeat       =>  counter_output = 1, invert_output = 0, halt_or_repeat = 1, invert_flip = 0
-- 100 = triangle, halt         =>  counter_output = 1, invert_output = 1, halt_or_repeat = 0, invert_flip = 1
-- 101 = triangle, repeat       =>  counter_output = 1, invert_output = 1, halt_or_repeat = 1, invert_flip = 1
-- 110 = saw up, halt           =>  counter_output = 1, invert_output = 1, halt_or_repeat = 0, invert_flip = 0
-- 111 = saw up, repeat         =>  counter_output = 1, invert_output = 1, halt_or_repeat = 1, invert_flip = 0

port(
    clk : in std_logic;
    en_write : in std_logic;
    a0_write : in std_logic;
    en7, en5, en4, en3, en2, en1, en0 : in std_logic;
    osc_trigger: in std_logic;
    output_left, output_right : out unsigned(3 downto 0)
)

signal counter: std_logic_vector(3 downto 0) := "1111";
signal new_env_waiting : std_logic;
signal en5_buffered, en4_buffered, en3_buffered, en2_buffered, en1_buffered : std_logic;
signal counter_output, invert_output, halt_or_reset, invert_flip : std_logic;

if rising_edge(clk) then

    if not en7 then
        counter <= "1111";
    else

        if mode_4bit then
            effective_counter := counter;
        else
            effective_counter := (counter(3 downto 1) & '0');
        end if;
        if effective_counter=0 then
            -- process new env instruction here (this corresponds to position(3) or position(4))
            if new_env_waiting then
            else
                if halt_or_repeat='0' and (invert_flip='0' or invert_output='0') then
                    halted <= '1';
                    env_output <= 0;
                else
                    counter <= "1111";
                    if invert_flip then
                        invert <= 0;
                    end if;
                end if;
            end if;
        else
            if mode_4bit then
                counter <= counter-1;
            else
                counter <= counter-2;
            end if;
        end if; 

        if counter_output then
            intermediate_out := counter;
        else
            intermediate_out := "0000";
        end if;
        if invert then
            calc_output_left := counter xor "1111";
        else
            calc_output_left := counter;
        end if;

        output_left <= calc_output_left;
        if right_invert then
            output_right <= calc_output_left xor "1111";
        else
            output_right <= calc_output_left;
        end if;