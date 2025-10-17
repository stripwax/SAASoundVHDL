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
USE STD.TEXTIO.all;
use std.env.finish;
use work.saa1099_digital_output;

entity tb_saa1099_sim is
end tb_saa1099_sim;


architecture behav of tb_saa1099_sim is
  --  Declaration of the component that will be instantiated.
  component saa1099_digital_output
  port (
        wr_n, cs_n, clk, a0 : in std_logic;
        dtack_n : out std_logic;
        d : in std_logic_vector(7 downto 0);
        outl : out std_logic_vector(5 downto 0);
        outr : out std_logic_vector(5 downto 0)
    );
  end component;

  --  Specifies which entity is bound with the component.
  for saa_0: saa1099_digital_output use entity work.saa1099_digital_output;
    signal wr_n, cs_n, clk, a0 : std_logic;
    signal dtack_n : std_logic;
    signal d : std_logic_vector(7 downto 0);
    signal outl : std_logic_vector(5 downto 0);
    signal outr : std_logic_vector(5 downto 0);

    function decodeDigit(c : character) return integer is
    variable retVal : integer;
    variable l : line;
begin
    retVal := character'pos(c) - character'pos('0');
    if retVal < 0 or retVal > 9 then
        return -1;
    else
        return retVal;
    end if;
end function decodeDigit;

procedure read(l : inout line; val : inout unsigned; ok : out boolean) is
    variable c : character;
    variable done : boolean := false;
    variable c_ok : boolean := true;
    variable retVal : unsigned(val'length - 1 downto 0) := (others => '0');
    variable something : boolean := false;
begin
    while not done loop
        read(l, c, c_ok);
        if not c_ok then
            done := true;
        else
            if (decodeDigit(c) < 0) then
                done := true;
            else
                something := true;
                retVal := resize(retVal * to_unsigned(10, 4), val'length);
                retVal := retVal + to_unsigned(decodeDigit(c), 4);
            end if;
        end if;
    end loop;
    val := retVal;
    if something then
        ok := true;
    else
        ok := c_ok;
    end if;
end procedure read;

begin
  --  Component instantiation.
  saa_0: saa1099_digital_output port map (
    wr_n => wr_n,
    cs_n => cs_n,
    clk => clk,
    a0 => a0,
    dtack_n => dtack_n,
    d => d,
    outl => outl,
    outr => outr
  );

    PROC_SEQUENCER : process
    file text_file : text open read_mode is "tests/debugsaa.txt";
    variable text_line : line;
    variable ok : boolean;
    variable char : character;
    --variable wait_time : time;
    variable reg : unsigned(7 downto 0);
    variable data_byte : unsigned(7 downto 0);
    variable sample_pos : unsigned(31 downto 0);
    variable the_word_ns : string(2 downto 1);
    variable selector : bit_vector(1 downto 0);
    variable data : bit_vector(7 downto 0);
    variable sample_ns : unsigned(127 downto 0) := (others => '0');
    variable current_ns : unsigned(127 downto 0) := (others => '0');
    variable ns_per_sample : unsigned(15 downto 0) := to_unsigned(22675, 16);
    begin

        while not endfile(text_file) loop
        
            readline(text_file, text_line);
            
            -- Skip empty lines and single-line comments
            if text_line.all'length = 0 or text_line.all(1) = '#' then
                next;
            end if;

            --read(text_line, wait_time, ok);
            read(text_line, sample_pos, ok);
            assert ok
            report "Read 'sample_pos' failed for line: " & text_line.all
            severity failure;

            sample_ns := resize(sample_pos * ns_per_sample, sample_ns'length);

            if sample_ns > current_ns then
                while sample_ns > current_ns loop
                    clk <= '1';
                    wait for 125 ns;
                    clk <= '0';
                    wait for 125 ns;
                    current_ns := current_ns + to_unsigned(250, 8);
                end loop;
            end if;

            read(text_line, reg, ok);
            assert ok
            report "Read 'reg' failed for line: " & text_line.all
            severity failure;

            read(text_line, data_byte, ok);
            if not ok then
                -- just a reg write
                write(OUTPUT, "REG " & to_hstring(reg) & LF);
                a0 <= '1';
                wr_n <= '0';
                cs_n <= '0';
                d <= std_logic_vector(reg);
                clk <= '1';
                wait for 125 ns;
                clk <= '0';
                wait for 125 ns;
                wr_n <= '1';
                cs_n <= '1';
                current_ns := current_ns + to_unsigned(250, 8);
            else
                write(OUTPUT, "DATA: (REG" & to_hstring(reg) & ") = " & to_hstring(data_byte) & LF);
                a0 <= '0';
                wr_n <= '0';
                cs_n <= '0';
                d <= std_logic_vector(data_byte);
                clk <= '1';
                wait for 125 ns;
                clk <= '0';
                wait for 125 ns;
                wr_n <= '1';
                cs_n <= '1';
                current_ns := current_ns + to_unsigned(250, 8);
            end if;

        end loop;
        
        finish;
    
    end process;

end behav;