--  A testbench has no ports.
use work.noise_bitstream;

entity tb_noise_bitstream is
end tb_noise_bitstream;

architecture behav of tb_noise_bitstream is
  --  Declaration of the component that will be instantiated.
  component noise_bitstream
  port (
    clk: in bit;
    trigger_313, trigger_156, trigger_76, trigger_osc : in bit;
    enabled: in bit_vector(1 downto 0);
    bitstream: out bit
    );
  end component;

  --  Specifies which entity is bound with the component.
  for noise_bitstream_0: noise_bitstream use entity work.noise_bitstream;
  signal clk, trigger_313, trigger_156, trigger_76, trigger_osc, bitstream : bit;
  signal enabled : bit_vector(1 downto 0);
begin
  --  Component instantiation.
  noise_bitstream_0: noise_bitstream port map (clk => clk, trigger_313 => trigger_313, trigger_156 => trigger_156, trigger_76 => trigger_76, trigger_osc => trigger_osc, enabled => enabled, bitstream => bitstream);

  --  This process does the real job.
  process

    constant expected_1 : bit_vector := "1000000000010000001000100000000001001000";
    constant expected_2 : bit_vector := "1000100100000011000000100010000010000100";
    constant expected_3 : bit_vector := "1001100010110010001100000110101010000001";
    constant expected_4 : bit_vector := "0100101010001001000000111000001000110000";
    constant expected_5 : bit_vector := "1010011010011000111110101011100101101001";
    variable prev : bit;

 begin
    -- check initial values for first few
    -- with trigger fully enabled just to step each clock
    trigger_313 <= '1';
    enabled <= "00";
    for i in expected_1'range loop
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      assert bitstream = expected_1(i);
    end loop;

    prev := bitstream;

    -- check values only step when the correct trigger matches the enabled flag
    for i in expected_2'range loop
      clk <= '0';
      assert bitstream = prev;
      trigger_313 <= '0';
      enabled <= "00";
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

    for i in expected_3'range loop
      clk <= '0';
      assert bitstream = prev;
      trigger_156 <= '0';
      enabled <= "01";
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

    for i in expected_4'range loop
      clk <= '0';
      assert bitstream = prev;
      trigger_76 <= '0';
      enabled <= "10";
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

    for i in expected_5'range loop
      clk <= '0';
      assert bitstream = prev;
      trigger_osc <= '0';
      enabled <= "11";
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