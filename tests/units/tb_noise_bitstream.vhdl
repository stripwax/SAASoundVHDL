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

use work.noise_bitstream;

entity tb_noise_bitstream is
end tb_noise_bitstream;

architecture behav of tb_noise_bitstream is
  signal clk, trigger_313, trigger_156, trigger_76, trigger_osc, bitstream : std_logic;
  signal data : std_logic_vector(7 downto 0);
  signal reg : std_logic_vector(4 downto 0);
  signal wr : std_logic;
begin
  --  Component instantiation.
    --  Component instantiation.
    noise_bitstream_0: entity work.noise_bitstream
    generic map (MAPPED_SEL_REGISTER => 21, SEL_IN_UPPER => false)
    port map (
        clk => clk,
        data => data,
        reg => reg,
        wr => wr,
        trigger_313 => trigger_313,
        trigger_156 => trigger_156,
        trigger_76 => trigger_76,
        trigger_osc => trigger_osc,
        bitstream => bitstream
    );

  --  This process does the real job.
  process

    constant expected_1 : std_logic_vector := "1000000000010000001000100000000001001000";
    constant expected_2 : std_logic_vector := "1000100100000011000000100010000010000100";
    constant expected_3 : std_logic_vector := "1001100010110010001100000110101010000001";
    constant expected_4 : std_logic_vector := "0100101010001001000000111000001000110000";
    constant expected_5 : std_logic_vector := "1010011010011000111110101011100101101001";
    variable prev : std_logic;

 begin
    -- check initial values for first few
    -- with trigger fully enabled just to step each clock
    trigger_313 <= '1';
    data <= "XXXXXX00";
    reg <= "10101";
    wr <= '1';
    for i in expected_1'range loop
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = expected_1(i);
      wr <= '0';
      data <= "XXXXXXXX";
    end loop;

    prev := bitstream;

    -- check values only step when the correct trigger matches the enabled flag
    clk <= '0';
    assert bitstream = prev;
    trigger_313 <= '0';
    data <= "XXXXXX00";
    wr <= '1';
    wait for 1 ns;
    assert bitstream = prev;
    clk <= '1';
    wait for 1 ns;
    wr <= '0';
    data <= "XXXXXXXX";
    assert bitstream = prev;
    for i in expected_2'range loop
      clk <= '0';
      assert bitstream = prev;
      trigger_313 <= '0';
      wait for 1 ns;
      assert bitstream = prev;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_156 <= '1';
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_76 <= '1';
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_osc <= '1';
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_313 <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      clk <= '0';
      wait for 1 ns;
      assert bitstream = prev;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = expected_2(i);
      prev := bitstream;
    end loop;

    clk <= '0';
    assert bitstream = prev;
    trigger_156 <= '0';
    data <= "XXXXXX01";
    wr <= '1';
    wait for 1 ns;
    assert bitstream = prev;
    clk <= '1';
    wait for 1 ns;
    wr <= '0';
    data <= "XXXXXXXX";
    assert bitstream = prev;
    for i in expected_3'range loop
      clk <= '0';
      assert bitstream = prev;
      trigger_156 <= '0';
      wait for 1 ns;
      assert bitstream = prev;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_313 <= '1';
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_76 <= '1';
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_osc <= '1';
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_156 <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      clk <= '0';
      wait for 1 ns;
      assert bitstream = prev;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = expected_3(i);
      prev := bitstream;
    end loop;

    clk <= '0';
    assert bitstream = prev;
    trigger_76 <= '0';
    data <= "XXXXXX10";
    wr <= '1';
    wait for 1 ns;
    assert bitstream = prev;
    clk <= '1';
    wait for 1 ns;
    wr <= '0';
    data <= "XXXXXXXX";
    assert bitstream = prev;
    for i in expected_4'range loop
      clk <= '0';
      assert bitstream = prev;
      trigger_76 <= '0';
      wait for 1 ns;
      assert bitstream = prev;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_313 <= '1';
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_156 <= '1';
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_osc <= '1';
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_76 <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      clk <= '0';
      wait for 1 ns;
      assert bitstream = prev;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = expected_4(i);
      prev := bitstream;
    end loop;

    clk <= '0';
    assert bitstream = prev;
    trigger_osc <= '0';
    data <= "XXXXXX11";
    wr <= '1';
    wait for 1 ns;
    assert bitstream = prev;
    clk <= '1';
    wait for 1 ns;
    wr <= '0';
    data <= "XXXXXXXX";
    assert bitstream = prev;
    for i in expected_5'range loop
      clk <= '0';
      assert bitstream = prev;
      trigger_osc <= '0';
      wait for 1 ns;
      assert bitstream = prev;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_313 <= '1';
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_156 <= '1';
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_76 <= '1';
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      trigger_osc <= '1';
      wait for 1 ns;
      assert bitstream = prev;
      clk <= '0';
      wait for 1 ns;
      assert bitstream = prev;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = expected_5(i);
      prev := bitstream;
    end loop;

    --  Wait forever; this will finish the simulation.
    wait;
  end process;

end behav;