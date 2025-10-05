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
use work.amp;

entity tb_amp is
end tb_amp;

architecture behav of tb_amp is
  --  Declaration of the component that will be instantiated.
  component amp
  port (
        step_counter: in unsigned(5 downto 0);
        amplitude_level: in unsigned(3 downto 0);
        envelope_level: in unsigned(3 downto 0);
        envelope_enabled: in std_logic;
        frequency_enabled: in std_logic;
        chop_mask: out std_logic
    );
  end component;

  --  Specifies which entity is bound with the component.
  for amp_0: amp use entity work.amp;
    signal step_counter: unsigned(5 downto 0);
    signal amplitude_level: unsigned(3 downto 0);
    signal envelope_level: unsigned(3 downto 0);
    signal envelope_enabled: std_logic;
    signal frequency_enabled: std_logic;
    signal chop_mask: std_logic;
    signal expected_amp, expected_env: std_logic_vector(63 downto 0);
begin
  --  Component instantiation.
  amp_0: amp port map (step_counter => step_counter, amplitude_level => amplitude_level, envelope_level => envelope_level, envelope_enabled => envelope_enabled, frequency_enabled => frequency_enabled, chop_mask => chop_mask);

  --  This process does the real job.
  process

    variable expected_bit: std_logic;

    type seq_list is array (natural range <>) of std_logic_vector(63 downto 0);
    constant amp_seqs : seq_list := (
      "0000000000000000000000000000000000000000000000000000000000000000",
      "0000111100000000000000000000000000000000000000000000000000000000",
      "0000000011111111000000000000000000000000000000000000000000000000",
      "0000111111111111000000000000000000000000000000000000000000000000",
      "0000000000000000000000000000000011111111111111110000000000000000",
      "0000111100000000000000000000000011111111111111110000000000000000",
      "0000000011111111000000000000000011111111111111110000000000000000",
      "0000111111111111000000000000000011111111111111110000000000000000",
      "0000000000000000111111111111111100000000000000001111111111111111",
      "0000111100000000111111111111111100000000000000001111111111111111",
      "0000000011111111111111111111111100000000000000001111111111111111",
      "0000111111111111111111111111111100000000000000001111111111111111",
      "0000000000000000111111111111111111111111111111111111111111111111",
      "0000111100000000111111111111111111111111111111111111111111111111",
      "0000000011111111111111111111111111111111111111111111111111111111",
      "0000111111111111111111111111111111111111111111111111111111111111"
    );
    constant env_seqs : seq_list := (
      "0000000000000000000000000000000000000000000000000000000000000000",
      "0000000010000000000000001000000000000000100000000000000010000000",
      "0100000001000000010000000100000001000000010000000100000001000000",
      "0100000011000000010000001100000001000000110000000100000011000000",
      "0000001100000011000000110000001100000011000000110000001100000011",
      "0000001110000011000000111000001100000011100000110000001110000011",
      "0100001101000011010000110100001101000011010000110100001101000011",
      "0100001111000011010000111100001101000011110000110100001111000011",
      "0011110000111100001111000011110000111100001111000011110000111100",
      "0011110010111100001111001011110000111100101111000011110010111100",
      "0111110001111100011111000111110001111100011111000111110001111100",
      "0111110011111100011111001111110001111100111111000111110011111100",
      "0011111100111111001111110011111100111111001111110011111100111111",
      "0011111110111111001111111011111100111111101111110011111110111111",
      "0111111101111111011111110111111101111111011111110111111101111111",
      "0111111111111111011111111111111101111111111111110111111111111111"
    );
  begin

    --  Check behaviour with everything disabled
    envelope_enabled <= '0';
    frequency_enabled <= '0';
    for i in amp_seqs'range loop
        for j in env_seqs'range loop
        --  Set the inputs.
            for s in 0 to 63 loop
                amplitude_level <= to_unsigned(i, 4);
                envelope_level <= to_unsigned(j, 4);
                step_counter <= to_unsigned(s, 6);

                --  Check the outputs.
                wait for 1 ns;
                assert chop_mask = '1';
            end loop;
        end loop;
    end loop;

    -- amplitude behaviour - standalone (freq enabled, env disabled)
    envelope_enabled <= '0';
    frequency_enabled <= '1';
    for i in amp_seqs'range loop
        for j in env_seqs'range loop
        --  Set the inputs.
            for s in 0 to 63 loop
                expected_amp <= amp_seqs(i);
                amplitude_level <= to_unsigned(i, 4);
                envelope_level <= to_unsigned(j, 4);
                step_counter <= to_unsigned(s, 6);

                --  Check the outputs.
                wait for 1 ns;
                -- time steps are 0 to 63 but patterns expressed left-to-right so timestep 0 is MSB (not LSB)
                -- so need (63-s) as index not (s)
                expected_bit := expected_amp(63-s);
                expected_bit; -- placate automated checks that say expected_bit is unused (I suppose they don't understand assert statements?)
                assert chop_mask = expected_bit
                    report "amp " & to_string(i) & " env " & to_string(j) & " wrong output " & to_string(s) & " - expected " & to_string(expected_bit) & " got " & to_string(chop_mask) & " - pattern should be " & to_string(expected_amp) severity error;
            end loop;
        end loop;
    end loop;

    -- envelope behaviour - standalone (freq disabled, env enabled)
    envelope_enabled <= '1';
    frequency_enabled <= '0';
    for i in amp_seqs'range loop
        for j in env_seqs'range loop
        --  Set the inputs.
            for s in 0 to 63 loop
                expected_env <= env_seqs(j);
                amplitude_level <= to_unsigned(i, 4);
                envelope_level <= to_unsigned(j, 4);
                step_counter <= to_unsigned(s, 6);

                --  Check the outputs.
                wait for 1 ns;
                -- time steps are 0 to 63 but patterns expressed left-to-right so timestep 0 is MSB (not LSB)
                -- so need (63-s) as index not (s)
                expected_bit := expected_env(63-s);
                assert chop_mask = expected_bit
                    report "amp " & to_string(i) & " env " & to_string(j) & " wrong output " & to_string(s) & " - expected " & to_string(expected_bit) & " got " & to_string(chop_mask) & " - pattern should be " & to_string(expected_env) severity error;
            end loop;
        end loop;
    end loop;

    -- envelope and amplitude behaviour - combined (freq enabled, env enabled)
    envelope_enabled <= '1';
    frequency_enabled <= '1';
    for i in amp_seqs'range loop
        for j in env_seqs'range loop
        --  Set the inputs.
            for s in 0 to 63 loop
                expected_amp <= amp_seqs(to_integer((to_unsigned(i,4)(3 downto 1)) & '0'));  -- SAA1099 treats low bit of amplitude as zero when env enabled so expected output comes only from the 'even' rows of the amp_seqs table
                expected_env <= env_seqs(j);
                amplitude_level <= to_unsigned(i, 4);
                envelope_level <= to_unsigned(j, 4);
                step_counter <= to_unsigned(s, 6);

                --  Check the outputs.
                wait for 1 ns;
                -- time steps are 0 to 63 but patterns expressed left-to-right so timestep 0 is MSB (not LSB)
                -- so need (63-s) as index not (s)
                expected_bit := expected_amp(63-s) and expected_env(63-s);
                assert chop_mask = expected_bit
                    report "amp " & to_string(i) & " env " & to_string(j) & " wrong output " & to_string(s) & " - expected " & to_string(expected_bit) & " got " & to_string(chop_mask) & " - pattern should be " & to_string(expected_env and expected_amp) severity error;
            end loop;
        end loop;
    end loop;

    --  Wait forever; this will finish the simulation.
    wait;
  end process;

end behav;