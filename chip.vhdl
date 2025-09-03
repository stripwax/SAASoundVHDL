library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity saa1099_digital_output is
  -- essentially saa1099 i/o but with additional digital (rather than analog) outputs
  -- outputs are bitstreams synchronised with clk
  -- you can convert these digital outputs to analog via a combination of filters and mixers
  port (
    wr_, cs_, clk, a0 : in std_logic_bit,
    dtack_ : out std_logic_bit,
    d : in std_logic_vector(7 down to 0),
    outl : out bit_vector(5 down to 0),
    outr : out bit_vector(5 down to 0)
    );
end saa1099_digital_output;

architecture behaviour of saa1099_digital_output is
begin
    process (inputs, selector)
    begin
        val <= inputs(to_integer(selector));
    end process;
end behaviour;