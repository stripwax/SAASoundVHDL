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
        clk_div: out std_logic_vector(9 downto 0)
    );
  end component;

  --  Specifies which entity is bound with the component.
  for clocks_0: clocks use entity work.clocks;
    signal clk: std_logic;
    signal clk_div: std_logic_vector(9 downto 0);
begin
  --  Component instantiation.
  clocks_0: clocks port map (clk => clk, clk_div => clk_div);

  --  This process does the real job.
  process
    variable prev : unsigned(9 downto 0);
  begin

    assert clk_div = "0000000000";

    clk <= '0';
    wait for 1 ns;
    clk <= '1';
    wait for 1 ns;

    assert clk_div = "0000000001";

    clk <= '0';
    wait for 1 ns;
    clk <= '1';
    wait for 1 ns;

    assert clk_div = "0000000010";

    clk <= '0';
    wait for 1 ns;
    clk <= '1';
    wait for 1 ns;

    assert clk_div = "0000000011";

    prev := unsigned(clk_div);

    for i in 1 to 262144 loop
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        assert unsigned(clk_div) = prev+1;
        prev := unsigned(clk_div);
    end loop;

    --  Wait forever; this will finish the simulation.
    wait;
  end process;

end behaviour;