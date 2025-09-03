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
    count_zero: out bit
    );
end osc;

architecture behaviour of osc is
    signal counter: unsigned(7 downto 0) := (others=>'0');
    signal div_counter: unsigned(2 downto 0) := (others=>'0');
    signal latched_freq: unsigned(7 downto 0);
    signal latched_octave: unsigned(2 downto 0);
    signal latched: bit := '0';
begin
    process(clk)
    variable counter_is_zero: bit;
    begin

    if rising_edge(clk) then

        counter_is_zero := '0';

        if sync then
            counter <= (others=>'0');
            div_counter <= (others=>'0');
            latched_octave <= octave;
            latched_freq <= frequency;
            latched <= '1';
            counter_is_zero := '1';
        else
            if div_counter/=0 then
                div_counter <= div_counter-1;
            else
                div_counter <= latched_octave;

                if counter="0" then
                    counter_is_zero := '1';
                end if;

                if octave_wr then
                    latched_freq <= frequency;
                    latched_octave <= octave;
                    latched <= '1'; -- note, since signal, won't be updated until end of process
                end if;
                
                if counter_is_zero = '1' then
                    output <= not output;
                    if latched = '1' or octave_wr ='1' then
                        counter <= latched_freq;
                        latched <= '0';
                    else
                        counter <= frequency;
                    end if;
                else
                    counter <= counter - 1;
                end if;
            end if;
        end if;

        count_zero <= counter_is_zero;

    end if;

    end process;

end behaviour;