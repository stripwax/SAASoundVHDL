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

--  A testbench has no ports.
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.osc;

entity tb_osc is
end tb_osc;

architecture behaviour of tb_osc is
  --  Declaration of the component that will be instantiated.
  component osc
  port (
        clk: in std_logic;
        sync: in std_logic;
        frequency: in unsigned(7 downto 0);
        octave: in unsigned(2 downto 0);
        octave_wr: in std_logic;
        output: out std_logic;
        trigger: out std_logic
    );
  end component;

  --  Specifies which entity is bound with the component.
  for osc_0: osc use entity work.osc;
    signal clk: std_logic;
    signal sync: std_logic;
    signal frequency: unsigned(7 downto 0);
    signal octave: unsigned(2 downto 0);
    signal octave_wr: std_logic;
    signal output: std_logic;
    signal trigger: std_logic;
begin
  --  Component instantiation.
  osc_0: osc port map (clk => clk, sync => sync, frequency => frequency, octave => octave, octave_wr => octave_wr, output => output, trigger => trigger);

  --  This process does the real job.
  process
      variable cycles:integer;
  begin

    -- init, and assert output is always 1 while sync is set
    -- essentially this asserts that output (when sync set) does not depend on octave clocks
    clk <= '0';
    wait for 1 ns;

    frequency <= "11111111";
    octave <= "111";
    sync <= '1';
    octave_wr <= '0';

    clk <= '1';
    wait for 1 ns;
    clk <= '0';
    wait for 1 ns;
    clk <= '1';
    wait for 1 ns;
    clk <= '0';
    wait for 1 ns;

    for i in 1 to 123456 loop
        clk <= '1';
        wait for 1 ns;
        assert output = '1'; 
        clk <= '0';
        wait for 1 ns;
        assert output = '1'; 
    end loop;

    frequency <= "10101010";
    octave <= "010";
    octave_wr <= '1';
    for i in 1 to 123456 loop
        clk <= '1';
        wait for 1 ns;
        assert output = '1'; 
        clk <= '0';
        wait for 1 ns;
        assert output = '1'; 
    end loop;

    octave_wr <= '0';
    for i in 1 to 123456 loop
        clk <= '1';
        wait for 1 ns;
        assert output = '1'; 
        clk <= '0';
        wait for 1 ns;
        assert output = '1'; 
    end loop;

    -- At highest octave (but lowest freq register), osc output should be a square wave with period = 3.90625 kHz
    -- which corresponds to 2048 clock cycles @ 8MHz ; or in other words 1024 clock cycles @ 8 MHz per each HALF wave
    -- This is achived by counting 512 clock cycles @ 4 MHz
    --
    -- For highest octave and highest freq, this should correspond to 257 clock cycles @ 4 MHz per each HALF wave

    -- For lowest octave and lowest freq, osc output should be a square wave with period = 31 Hz
    -- which corresponds to 262144 clock cycles @ 8Mhz ; or in other words 131072 clock cycles @ 8 MHz per each HALF wave
    -- This is achived by counting 512 clock cycles @ (4 MHz divided by 128) = 15.625 kHz
    -- or in other words, 65536 clock cycles @ 4 MHz .
    --
    -- For lowest octave and highest freq, this should correspond to 257 clock cycles @ (4 MHz divided by 128)
    -- or in other words, 32896 clock cycles @ 4 MHz .
    --
    -- Start with "highest octave and highest freq" test case:
    --
    frequency <= "11111111";
    octave <= "111";
    cycles := 2;  -- we are expecting 2 clocks at 8MHz to drive the octave counter
    octave_wr <= '1';
    sync <= '1';
    clk <= '1';
    wait for 125 ns;
    clk <= '0';
    wait for 125 ns;

    octave_wr <= '0';
    clk <= '1';
    wait for 125 ns;
    clk <= '0';
    wait for 125 ns;

    sync <= '0';

    for j in 1 to 10 loop
        for i in 1 to 257 loop
            for c in 1 to cycles loop
                clk <= '1';
                wait for 125 ns;
                assert output = '0' report "oh" & INTEGER'IMAGE(i); -- question, should this be 0 or 1??
                clk <= '0';
                wait for 125 ns;
                assert output = '0'; -- question, should this be 0 or 1??
            end loop;
        end loop;
        for i in 1 to 257 loop
            for c in 1 to cycles loop
                clk <= '1';
                wait for 125 ns;
                assert output = '1' report "oh" & INTEGER'IMAGE(i); -- question, should this be 1 or 0??
                clk <= '0';
                wait for 125 ns;
                assert output = '1'; -- question, should this be 1 or 0??
            end loop;
        end loop;
    end loop;

    -- highest octave, lowest frequency
    frequency <= "00000000";
    octave <= "111";
    cycles := 2;  -- still 2
    octave_wr <= '1';
    sync <= '1';
    clk <= '1';
    wait for 125 ns;
    clk <= '0';
    wait for 125 ns;

    sync <= '0';
    octave_wr <= '0';

    for j in 1 to 10 loop
        for i in 1 to 512 loop
            for c in 1 to cycles loop
                clk <= '1';
                wait for 125 ns;
                assert output = '0' report "oh" & INTEGER'IMAGE(i); -- question, should this be 0 or 1??
                clk <= '0';
                wait for 125 ns;
                assert output = '0'; -- question, should this be 0 or 1??
            end loop;
        end loop;
        for i in 1 to 512 loop
            for c in 1 to cycles loop
                clk <= '1';
                wait for 125 ns;
                assert output = '1'; -- question, should this be 1 or 0??
                clk <= '0';
                wait for 125 ns;
                assert output = '1'; -- question, should this be 1 or 0??
            end loop;
        end loop;
    end loop;

    -- second highest octave, highest frequency
    frequency <= "11111111";
    octave <= "110";
    cycles := 4; -- we expect 4 cycles at 8 MHz to drive the octave counter
    octave_wr <= '1';
    sync <= '1';
    clk <= '1';
    wait for 125 ns;
    clk <= '0';
    wait for 125 ns;

    sync <= '0';
    octave_wr <= '0';

    for j in 1 to 10 loop
        for i in 1 to 257 loop
            for c in 1 to cycles loop
                clk <= '1';
                wait for 125 ns;
                assert output = '0' report "oh" & INTEGER'IMAGE(i) & " " & INTEGER'IMAGE(c) & " " & INTEGER'IMAGE(j); -- question, should this be 0 or 1??
                clk <= '0';
                wait for 125 ns;
                assert output = '0'; -- question, should this be 0 or 1??
            end loop;
        end loop;
        for i in 1 to 257 loop
            for c in 1 to cycles loop
                clk <= '1';
                wait for 125 ns;
                assert output = '1' report "oh" & INTEGER'IMAGE(i); -- question, should this be 1 or 0??
                clk <= '0';
                wait for 125 ns;
                assert output = '1'; -- question, should this be 1 or 0??
            end loop;
        end loop;
    end loop;

    ---- lowest octave, highest frequency
    frequency <= "11111111";
    octave <= "000";
    cycles := 256; -- we expect 4 cycles at 8 MHz to drive the octave counter
    octave_wr <= '1';
    sync <= '1';
    clk <= '1';
    wait for 125 ns;
    clk <= '0';
    wait for 125 ns;

    sync <= '0';
    octave_wr <= '0';

    for j in 1 to 10 loop
        for i in 1 to 257 loop
            for c in 1 to cycles loop
                clk <= '1';
                wait for 125 ns;
                assert output = '0' report "oh" & INTEGER'IMAGE(i) & " " & INTEGER'IMAGE(c) & " " & INTEGER'IMAGE(j); -- question, should this be 0 or 1??
                clk <= '0';
                wait for 125 ns;
                assert output = '0'; -- question, should this be 0 or 1??
            end loop;
        end loop;
        for i in 1 to 257 loop
            for c in 1 to cycles loop
                clk <= '1';
                wait for 125 ns;
                assert output = '1' report "oh" & INTEGER'IMAGE(i); -- question, should this be 1 or 0??
                clk <= '0';
                wait for 125 ns;
                assert output = '1'; -- question, should this be 1 or 0??
            end loop;
        end loop;
    end loop;

    -- lowest octave, lowest frequency
    frequency <= "00000000";
    octave <= "000";
    octave_wr <= '1';
    sync <= '1';
    clk <= '1';
    wait for 125 ns;
    clk <= '0';
    wait for 125 ns;

    sync <= '0';
    octave_wr <= '0';

    for j in 1 to 10 loop
        for i in 1 to 512 loop
            for c in 1 to cycles loop
                clk <= '1';
                wait for 125 ns;
                assert output = '0' report "oh" & INTEGER'IMAGE(i); -- question, should this be 0 or 1??
                clk <= '0';
                wait for 125 ns;
                assert output = '0'; -- question, should this be 0 or 1??
            end loop;
        end loop;
        for i in 1 to 512 loop
            for c in 1 to cycles loop
                clk <= '1';
                wait for 125 ns;
                assert output = '1' report "oh" & INTEGER'IMAGE(i); -- question, should this be 1 or 0??
                clk <= '0';
                wait for 125 ns;
                assert output = '1'; -- question, should this be 1 or 0??
            end loop;
        end loop;
    end loop;

    wait;

    -- test changing frequency ; should take effect only on the next half wave
    -- continue where we left off (above) but change frequency after a few cycles (123)
    for i in 1 to 123 loop
        clk <= '1';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 0 or 1??
        clk <= '0';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 0 or 1??
        clk <= '1';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 0 or 1??
        clk <= '0';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 0 or 1??
    end loop;
    frequency <= "11111111";
    for i in 1 to 389 loop  -- rest of THIS half-wave unchanged
        clk <= '1';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 0 or 1??
        clk <= '0';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 0 or 1??
        clk <= '1';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 0 or 1??
        clk <= '0';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 0 or 1??
    end loop;
    for i in 1 to 512 loop -- octave register was not written so NEXT half-wave also unchanged (freq therefore deferred to the FOLLOWING half-wave)
        clk <= '1';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '1';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
    end loop;
    for i in 1 to 257 loop  -- after that previous half-wave finished, freq reloaded and now takes effect:
        clk <= '1';
        wait for 125 ns;
        assert output = '0' report "oh" & INTEGER'IMAGE(i); -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 1 or 0??
        clk <= '1';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 1 or 0??
    end loop;

    -- test changing it back, but that might even be a redundant test
    for i in 1 to 123 loop
        clk <= '1';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '1';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
    end loop;
    frequency <= "10101010";  -- 170 ;  so half-wave expected to be (512-170) = 342
    for i in 1 to 134 loop  -- 257 minus 123
        clk <= '1';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '1';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
    end loop;
    for i in 1 to 257 loop  -- still old freq since octave not written
        clk <= '1';
        wait for 125 ns;
        assert output = '0' report "oh" & INTEGER'IMAGE(i); -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 1 or 0??
        clk <= '1';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 1 or 0??
    end loop;    
    for j in 1 to 5 loop
        for i in 1 to 342 loop
            clk <= '1';
            wait for 125 ns;
            assert output = '1'; -- question, should this be 1 or 0??
            clk <= '0';
            wait for 125 ns;
            assert output = '1'; -- question, should this be 1 or 0??
            clk <= '1';
            wait for 125 ns;
            assert output = '1'; -- question, should this be 1 or 0??
            clk <= '0';
            wait for 125 ns;
            assert output = '1'; -- question, should this be 1 or 0??
        end loop;
        for i in 1 to 342 loop
            clk <= '1';
            wait for 125 ns;
            assert output = '0'; -- question, should this be 1 or 0??
            clk <= '0';
            wait for 125 ns;
            assert output = '0'; -- question, should this be 1 or 0??
            clk <= '1';
            wait for 125 ns;
            assert output = '0'; -- question, should this be 1 or 0??
            clk <= '0';
            wait for 125 ns;
            assert output = '0'; -- question, should this be 1 or 0??
        end loop;
    end loop;

    -- now test the "freq and octave latch" behaviour i.e. glitch-free frequency change
    -- When you set octave, it snaps the frequency reg too, and sets them both on the next half-wave
    for i in 1 to 123 loop
        clk <= '1';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '1';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
    end loop;
    frequency <= "11110000";  -- 240 , so half-wave expected to be (512-240) = 272
    octave <= "100";
    octave_wr <= '1';
    for i in 1 to 219 loop -- 342 minus 123
        clk <= '1';
        wait for 125 ns;
        assert output = '1' report "oh" & INTEGER'IMAGE(i); -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        octave_wr <= '0';
        clk <= '1';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
    end loop;
    for i in 1 to 272 loop
        clk <= '1';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 1 or 0??
        clk <= '1';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '0'; -- question, should this be 1 or 0??
    end loop;
    for i in 1 to 272 loop
        clk <= '1';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '1';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
        clk <= '0';
        wait for 125 ns;
        assert output = '1'; -- question, should this be 1 or 0??
    end loop;

    --  Wait forever; this will finish the simulation.
    wait;
  end process;

end behaviour;