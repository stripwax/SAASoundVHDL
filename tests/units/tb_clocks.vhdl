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
use work.clocks;

entity tb_clocks is
end tb_clocks;

architecture behaviour of tb_clocks is
  --  Declaration of the component that will be instantiated.
  component clocks
  port (
        clk: in std_logic;
        pulse_div: out std_logic_vector(2 downto 0);
        step_ctr: out unsigned(5 downto 0)
    );
  end component;

  --  Specifies which entity is bound with the component.
  for clocks_0: clocks use entity work.clocks;
    signal clk: std_logic;
    signal pulse_div: std_logic_vector(2 downto 0);
    signal step_ctr: unsigned(5 downto 0);
begin
  --  Component instantiation.
  clocks_0: clocks port map (clk => clk, pulse_div => pulse_div, step_ctr => step_ctr);

  --  This process does the real job.
  process
    variable ctr : unsigned(9 downto 0);
    variable next_ctr : unsigned(9 downto 0);
  begin

    clk <= '0';
    wait for 1 ns;

    clk <= '1';
    wait for 1 ns;
    assert step_ctr = "000000";
    assert pulse_div = "111";
    clk <= '0';
    wait for 1 ns;

    clk <= '1';
    wait for 1 ns;
    assert step_ctr = "000001";
    assert pulse_div = "000";
    clk <= '0';
    wait for 1 ns;

    clk <= '1';
    wait for 1 ns;
    assert step_ctr = "000010";
    assert pulse_div = "000";
    clk <= '0';
    wait for 1 ns;

    clk <= '1';
    wait for 1 ns;
    assert step_ctr = "000011";
    assert pulse_div = "000";
    clk <= '0';
    wait for 1 ns;

    clk <= '1';
    wait for 1 ns;
    assert step_ctr = "000100";
    assert pulse_div = "000";
    clk <= '0';
    wait for 1 ns;

    ctr := "0000000000" + step_ctr;

    for i in 1 to 262144 loop
        clk <= '1';
        wait for 1 ns;
        next_ctr := ctr+1;
        assert unsigned(step_ctr) = next_ctr(5 downto 0);
        ctr := next_ctr;
        clk <= '0';
        wait for 1 ns;
    end loop;

    --  Wait forever; this will finish the simulation.
    wait;
  end process;

end behaviour;