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
    --  Declaration of the component(s) that will be instantiated.
    component osc
    port (
        clk: in std_logic;
        octave_clks: in std_logic_vector(7 downto 0);
        sync: in std_logic;
        data: in std_logic_vector(7 downto 0);
        freq_wr: in std_logic;
        octave_wr: in std_logic;
        output: out std_logic;
        trigger: out std_logic
    );
    end component;
    component clocks
    port (
        clk: in std_logic;
        step_ctr: out unsigned(5 downto 0);
        octave_clks: out std_logic_vector(7 downto 0);
        noise_clks: out std_logic_vector(2 downto 0)
    );
    end component;

    --  Specifies which entity is bound with the component.
    for osc_0: osc use entity work.osc;
    for clocks_0: clocks use entity work.clocks;

    signal clk: std_logic;
    signal octave_clks: std_logic_vector(7 downto 0);
    signal sync: std_logic;
    signal data: std_logic_vector(7 downto 0);
    signal freq_wr: std_logic;
    signal octave_wr: std_logic;
    signal output: std_logic;
    signal trigger: std_logic;

    signal noise_clks_unused: std_logic_vector(2 downto 0);
    signal step_ctr_unused: unsigned(5 downto 0);

    procedure wait_n_clks(constant n: integer;
                          signal m_clk: out std_logic
                         ) is
    begin
        for x in 1 to n loop
            m_clk <= '1';
            wait for 125 ns;
            m_clk <= '0';
            wait for 125 ns;
        end loop;
    end;

    procedure write_frequency_register(constant freq: in std_logic_vector(7 downto 0);
                                       signal m_data: out std_logic_vector(7 downto 0);
                                       signal m_freq_wr: out std_logic;
                                       signal m_clk: out std_logic 
                                      ) is
    begin
        m_data <= freq;
        m_freq_wr <= '1';
        wait_n_clks(1, m_clk);
        m_freq_wr <= '0';
        m_data <= "XXXXXXXX";
    end;

    procedure write_octave_register(constant oct: in std_logic_vector(2 downto 0);
                                    signal m_data: out std_logic_vector(7 downto 0);
                                    signal m_octave_wr: out std_logic;
                                    signal m_clk: out std_logic 
                                   ) is
    begin
        m_data <= "XXXXX" & oct;
        m_octave_wr <= '1';
        wait_n_clks(1, m_clk);
        m_octave_wr <= '0';
        m_data <= "XXXXXXXX";
    end;

    procedure wait_for_octave_counter(constant n: integer;
                                      signal m_octave_clks: in std_logic_vector(7 downto 0);
                                      signal m_clk: out std_logic
                                     ) is
        variable max_clks:integer := 512;
    begin
        -- wait for the octave clocks to catch up (we expect 256 clocks between output transitions BUT we should start counting at the well-defined place after the octave clock transitions
        -- and the octave clock just keeps running regardless of sync so for a good test we wait until the octave clocks are where we want them to be)
        for x in 0 to max_clks loop
            if m_octave_clks(n) = '1' then
                report "(info) skipped " & INTEGER'IMAGE(x) & " clocks for octave timing";
                exit;
            end if;
            wait_n_clks(1, m_clk);
        end loop;
        assert m_octave_clks(n) = '1' report "(FAIL) octave clocks not pulsed after " & INTEGER'IMAGE(max_clks) & " clocks";
    end;

    procedure check_osc_output(constant count: integer;
                               constant cycles: integer;
                               constant expected: std_logic;
                               signal m_clk: out std_logic;
                               signal m_output: in std_logic
                              ) is
    begin
        for i in 1 to count loop
            for c in 1 to cycles loop
                m_clk <= '1';
                wait for 125 ns;
                assert m_output = expected report "oh" & INTEGER'IMAGE(i) & " " & INTEGER'IMAGE(c);
                m_clk <= '0';
                wait for 125 ns;
                assert m_output = expected;
            end loop;
        end loop;
    end;

    procedure run_osc_output_checks(constant n: integer;
                                    constant freq: integer;
                                    constant cycles: integer;
                                    constant expected: std_logic;
                                    signal m_clk: out std_logic;
                                    signal m_output: in std_logic
                                   ) is
    begin
        for j in 1 to n loop
            check_osc_output(freq, cycles, expected, m_clk, m_output);  -- question, should this be 0 or 1??
            check_osc_output(freq, cycles, not expected, m_clk, m_output);  -- question, should this be 0 or 1??
        end loop;
    end;

begin
  --  Component instantiation.
  osc_0: osc port map (clk => clk, octave_clks => octave_clks, sync => sync, data => data, freq_wr => freq_wr, octave_wr => octave_wr, output => output, trigger => trigger);
  clocks_0: clocks port map (clk => clk, octave_clks => octave_clks, noise_clks => noise_clks_unused, step_ctr => step_ctr_unused);

  --  This process does the real job.
  process
      variable cycles:integer;
  begin

    -- init, and assert output is always 1 while sync is set
    -- essentially this asserts that output (when sync set) does not depend on octave clocks
    clk <= '0';
    wait for 1 ns;

    data <= "11111111";
    sync <= '1';
    freq_wr <= '0';
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
        assert output = '0'; 
        clk <= '0';
        wait for 1 ns;
        assert output = '0'; 
    end loop;

    data <= "10101010";
    freq_wr <= '1';
    clk <= '1';
    wait for 1 ns;
    clk <= '0';
    wait for 1 ns;
    clk <= '1';
    wait for 1 ns;
    clk <= '0';
    wait for 1 ns;
    freq_wr <= '0';
    octave_wr <= '1';
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
        assert output = '0'; 
        clk <= '0';
        wait for 1 ns;
        assert output = '0'; 
    end loop;

    octave_wr <= '0';
    for i in 1 to 12345 loop
        clk <= '1';
        wait for 1 ns;
        assert output = '0'; 
        clk <= '0';
        wait for 1 ns;
        assert output = '0'; 
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
    sync <= '1';
    write_frequency_register("11111111", data, freq_wr, clk);
    write_octave_register("111", data, octave_wr, clk);
    wait_for_octave_counter(0, octave_clks, clk);
    sync <= '0';
    cycles := 2;  -- we are expecting 2 clocks at 8MHz to drive the octave counter
    run_osc_output_checks(5, 256, cycles, '1', clk, output);

    -- highest octave, lowest frequency
    sync <= '1';
    write_frequency_register("00000000", data, freq_wr, clk);
    write_octave_register("111", data, octave_wr, clk);
    wait_for_octave_counter(0, octave_clks, clk);
    sync <= '0';
    cycles := 2;  -- we are expecting 2 clocks at 8MHz to drive the octave counter
    run_osc_output_checks(5, 511, cycles, '1', clk, output);

    -- second highest octave, highest frequency
    sync <= '1';
    write_frequency_register("11111111", data, freq_wr, clk);
    write_octave_register("110", data, octave_wr, clk);
    wait_for_octave_counter(1, octave_clks, clk);
    sync <= '0';
    cycles := 4; -- we expect 4 cycles at 8 MHz to drive the octave counter
    run_osc_output_checks(5, 256, cycles, '1', clk, output);

    -- lowest octave, highest frequency
    sync <= '1';
    write_frequency_register("11111111", data, freq_wr, clk);
    write_octave_register("000", data, octave_wr, clk);
    wait_for_octave_counter(7, octave_clks, clk);
    sync <= '0';
    cycles := 256; -- we expect 256 cycles at 8 MHz to drive the octave counter
    run_osc_output_checks(5, 256, cycles, '1', clk, output);

    -- lowest octave, lowest frequency
    sync <= '1';
    write_frequency_register("00000000", data, freq_wr, clk);
    write_octave_register("000", data, octave_wr, clk);
    wait_for_octave_counter(7, octave_clks, clk);
    sync <= '0';
    cycles := 256; -- we expect 256 cycles at 8 MHz to drive the octave counter
    run_osc_output_checks(5, 511, cycles, '1', clk, output);

    -- test changing frequency ; should take effect only on the next half wave
    -- continue where we left off (above) but change frequency after a few cycles (123)
    check_osc_output(123, cycles, '1', clk, output);
    write_frequency_register("11111111", data, freq_wr, clk); -- this uses ONE clock cycle @ 8MHz
    check_osc_output(1, cycles-1, '1', clk, output);   -- rest of THIS octave clock CYCLE unchanged 
    check_osc_output(387, cycles, '1', clk, output);   -- rest of THIS half-wave unchanged  (123+1+387 = 511)
    -- octave register was not written so NEXT half-wave also unchanged (freq therefore deferred to the FOLLOWING half-wave)
    check_osc_output(511, cycles, '0', clk, output);
    -- after that previous half-wave finished, freq reloaded and now takes effect:
    check_osc_output(256, cycles, '1', clk, output);

    -- test changing it back, but that might even be a redundant test
    check_osc_output(123, cycles, '0', clk, output);
    -- change freq to 170 ;  so half-wave expected to be (511-170) = 341
    write_frequency_register("10101010", data, freq_wr, clk); -- this uses ONE clock cycle @ 8MHz
    check_osc_output(1, cycles-1, '0', clk, output);   -- rest of THIS octave clock CYCLE unchanged 
    check_osc_output(132, cycles, '0', clk, output);   -- rest of THIS half-wave unchanged  (256-1-123 = 132)
    -- octave register was not written so NEXT half-wave also unchanged (freq therefore deferred to the FOLLOWING half-wave)
    check_osc_output(256, cycles, '1', clk, output);
    -- after that previous half-wave finished, freq reloaded and now takes effect:
    run_osc_output_checks(5, 341, cycles, '0', clk, output);

    -- now test the "freq and octave latch" behaviour i.e. glitch-free frequency change
    -- When you set octave, it snaps the frequency reg too, and sets them both on the next half-wave
    -- So to achieve this 'glitch-free frequency change' you write frequency THEN octave.
    -- We want to check the cases where they are set sequentially in this correct order
    -- We'll test first with the minimum write cycle for freq then octave
    check_osc_output(123, cycles, '0', clk, output);
    write_frequency_register("11110000", data, freq_wr, clk); -- 240 , so NEXT half-wave expected to be (511-240) = 271
    write_octave_register("100", data, octave_wr, clk); -- 
    check_osc_output(1, cycles-2, '0', clk, output);   -- rest of THIS octave clock CYCLE unchanged . write freq takes one clock cycle and write octave takes another cycle hence subtract 2 from the remaining octave-clock cycles
    check_osc_output(217, cycles, '0', clk, output); -- 341 minus 123 minus 1
    -- new octave (and frequency) kicks in here.  cycles set accordingly: octave 100=4 => 16 cycles @ 8mhz for octave counter
    cycles := 16;
    run_osc_output_checks(5, 271, cycles, '1', clk, output);

    -- we'll also test the same idea but with a few more clock cycles separating the freq write from the octave write
    -- but where freq write and octave write still take place within the same oscillator half-wave
    check_osc_output(123, cycles, '1', clk, output);
    write_frequency_register("11111110", data, freq_wr, clk); -- 254 , so NEXT half-wave expected to be (511-254) = 257
    check_osc_output(45, cycles, '1', clk, output);   -- wait some number of periods between setting freq and setting oct
    write_octave_register("010", data, octave_wr, clk); -- write octave
    check_osc_output(1, cycles-2, '1', clk, output);   -- account for the partial octave clock cycle (write freq takes one clock cycle and write octave takes another cycle hence subtract 2 from the remaining octave-clock cycles)
    check_osc_output(102, cycles, '1', clk, output); -- wait the remainder of the octave clock cycle: 102 = 271 - 123 - 45 - 1
    -- new octave (and frequency) kicks in here.  cycles set accordingly: octave 010=2 => 64 cycles @ 8mhz for octave counter
    -- WARNING!  We don't know what phase the 64-octave clock counter is at so actually this first half-wave could be shorter (by some multiple of 16 cycle @ 8MHZ , where 16 was the previous octave clock period)
    -- The octave clocks do NOT resynchronise when octaves are changed
    -- Going up in octaves (-> higher pitch) you won't observe this because the phases coincide harmonically as the periods halve in size, but the same is not true as the periods double in size
    -- Does this mean 'glitch free' is actually not really glitch-free when you do a downwards sweep???  But you wouldn't really notice it, the next half wave would be slightly shorter by less than 1 count
    cycles := 64;
    wait_for_octave_counter(5, octave_clks, clk); -- this will skip the (remainder of the) first octave clock cycle and align on 64-cycles @8mhz
    check_osc_output(256, cycles, '0', clk, output); -- wait the remainder of the half wave
    run_osc_output_checks(5, 257, cycles, '1', clk, output); -- the next half waves will all be the full length

    -- Now, a test case for the 'glitch' case i.e. setting octave before frequency.
    -- The octave write snapshots the frequency, so you would get one half-cycle
    -- at the new octave but old frequency, then the next half cycle has the new frequency
    check_osc_output(123, cycles, '1', clk, output);
    write_octave_register("001", data, octave_wr, clk); -- write octave
    check_osc_output(45, cycles, '1', clk, output);   -- wait some number of periods between setting freq and setting oct
    write_frequency_register("10011001", data, freq_wr, clk); -- 153 , so NEXT half-wave expected to be (511-153) = 358
    check_osc_output(1, cycles-2, '1', clk, output);   -- account for the partial octave clock cycle (write freq takes one clock cycle and write octave takes another cycle hence subtract 2 from the remaining octave-clock cycles)
    check_osc_output(88, cycles, '1', clk, output); -- wait the remainder of the octave clock cycle: 88 = 257 - 123 - 45
    -- octave kicks in (so, cycles now changes, but not frequency)
    cycles := 128;
    wait_for_octave_counter(6, octave_clks, clk); -- this will skip the (remainder of the) first octave clock cycle and align on 128-cycles @8mhz
    check_osc_output(256, cycles, '0', clk, output); -- wait the remainder of the half wave (256 = 257 minus (the remainder of) one octave clock cycle we just waited)
    -- frequency now kicks in after that half wave finished:
    run_osc_output_checks(5, 358, cycles, '1', clk, output); -- 358 = the new frequency

    -- also test where the freq write comes first and the octave write comes second, but the octave write happens in the next halfwave after the freq write
    -- Should still get the same 'glitch free' beheviour, just one half-wave later
    check_osc_output(123, cycles, '1', clk, output);
    write_frequency_register("11001100", data, freq_wr, clk); -- 192, so period will be 307.  this uses ONE clock cycle @ 8MHz
    check_osc_output(1, cycles-1, '1', clk, output);   -- rest of THIS octave clock CYCLE unchanged 
    check_osc_output(234, cycles, '1', clk, output);   -- rest of THIS half-wave unchanged  (234+1+123 = 358)
    -- octave register was not written yet so NEXT half-wave also unchanged (freq therefore deferred to the FOLLOWING half-wave)
    -- we will set octave somewhere in the middle of this half-wave:
    check_osc_output(123, cycles, '0', clk, output);
    write_octave_register("101", data, octave_wr, clk); -- this uses ONE clock cycle @ 8MHz
    check_osc_output(1, cycles-1, '0', clk, output);   -- rest of THIS octave clock CYCLE unchanged 
    check_osc_output(234, cycles, '0', clk, output);   -- rest of THIS half-wave unchanged  (234+1+123 = 358)
    -- freq and osc now kick in together: after that previous half-wave finished, freq reloaded and now takes effect:
    cycles := 8;
    run_osc_output_checks(3, 307, cycles, '1', clk, output); -- 358 = the new frequency


    --  Wait forever; this will finish the simulation.
    wait;
  end process;

end behaviour;