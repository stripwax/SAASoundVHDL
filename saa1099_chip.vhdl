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

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity saa1099_digital_output is
  -- essentially saa1099 i/o but with additional digital (rather than analog) outputs
  -- outputs are bitstreams synchronised with clk
  -- you can convert these digital outputs to analog via a combination of filters and mixers
  port (
    wr_n, cs_n, clk, a0 : in std_logic;
    dtack_n : out std_logic;
    d : in std_logic_vector(7 downto 0);
    outl : out std_logic_vector(5 downto 0);
    outr : out std_logic_vector(5 downto 0)
    );
end saa1099_digital_output;

architecture behaviour of saa1099_digital_output is
    signal reg : std_logic_vector(4 downto 0);
    signal amp0 : std_logic_vector(7 downto 0);
    signal amp1 : std_logic_vector(7 downto 0);
    signal amp2 : std_logic_vector(7 downto 0);
    signal amp3 : std_logic_vector(7 downto 0);
    signal amp4 : std_logic_vector(7 downto 0);
    signal amp5 : std_logic_vector(7 downto 0);
    signal freq0 : std_logic_vector(7 downto 0);
    signal freq1 : std_logic_vector(7 downto 0);
    signal freq2 : std_logic_vector(7 downto 0);
    signal freq3 : std_logic_vector(7 downto 0);
    signal freq4 : std_logic_vector(7 downto 0);
    signal freq5 : std_logic_vector(7 downto 0);
    signal oct0 : std_logic_vector(2 downto 0);
    signal oct1 : std_logic_vector(2 downto 0);
    signal oct2 : std_logic_vector(2 downto 0);
    signal oct3 : std_logic_vector(2 downto 0);
    signal oct4 : std_logic_vector(2 downto 0);
    signal oct5 : std_logic_vector(2 downto 0);
    signal freq0_en : std_logic; -- frequency enable
    signal freq1_en : std_logic;
    signal freq2_en : std_logic;
    signal freq3_en : std_logic;
    signal freq4_en : std_logic;
    signal freq5_en : std_logic;
    signal noise0_en : std_logic; -- noise enable
    signal noise1_en : std_logic;
    signal noise2_en : std_logic;
    signal noise3_en : std_logic;
    signal noise4_en : std_logic;
    signal noise5_en : std_logic;
    signal noise0_sel : std_logic_vector(1 downto 0);
    signal noise1_sel : std_logic_vector(1 downto 0);
    signal env0_lr : std_logic;
    signal env0_wave : std_logic_vector(2 downto 0);
    signal env0_res : std_logic;
    signal env0_clk_source : std_logic;
    signal env0_en : std_logic;
    signal env1_lr : std_logic;
    signal env1_wave : std_logic_vector(2 downto 0);
    signal env1_res : std_logic;
    signal env1_clk_source : std_logic;
    signal env1_en : std_logic;
    signal sync_rst : std_logic;
    signal enable : std_logic := '0';

    signal a0_pulse: std_logic;
    signal osc01_wr: std_logic;
    signal osc23_wr: std_logic;
    signal osc45_wr: std_logic;

    signal osc0_output: std_logic;
    signal osc0_trigger: std_logic;
    signal osc1_output: std_logic;
    signal osc1_trigger: std_logic;
    signal osc2_output: std_logic;
    signal osc2_trigger: std_logic;
    signal osc3_output: std_logic;
    signal osc3_trigger: std_logic;
    signal osc4_output: std_logic;
    signal osc4_trigger: std_logic;
    signal osc5_output: std_logic;
    signal osc5_trigger: std_logic;

    signal oct01_wr, oct23_wr, oct45_wr: std_logic;

begin

    OSC0: entity work.osc
        port map (
            clk => clk,
            sync => sync_rst,
            frequency => unsigned(freq0),
            octave => unsigned(oct0),
            octave_wr => oct01_wr,
            output => osc0_output,
            trigger => osc0_trigger
        );

    OSC1: entity work.osc
        port map (
            clk => clk,
            sync => sync_rst,
            frequency => unsigned(freq1),
            octave => unsigned(oct1),
            octave_wr => oct01_wr,
            output => osc1_output,
            trigger => osc1_trigger
        );

    OSC2: entity work.osc
        port map (
            clk => clk,
            sync => sync_rst,
            frequency => unsigned(freq2),
            octave => unsigned(oct2),
            octave_wr => oct23_wr,
            output => osc2_output,
            trigger => osc2_trigger
        );

    OSC3: entity work.osc
        port map (
            clk => clk,
            sync => sync_rst,
            frequency => unsigned(freq3),
            octave => unsigned(oct3),
            octave_wr => oct23_wr,
            output => osc3_output,
            trigger => osc3_trigger
        );

    OSC4: entity work.osc
        port map (
            clk => clk,
            sync => sync_rst,
            frequency => unsigned(freq4),
            octave => unsigned(oct4),
            octave_wr => oct45_wr,
            output => osc4_output,
            trigger => osc4_trigger
        );

    OSC5: entity work.osc
        port map (
            clk => clk,
            sync => sync_rst,
            frequency => unsigned(freq5),
            octave => unsigned(oct5),
            octave_wr => oct45_wr,
            output => osc5_output,
            trigger => osc5_trigger
        );

    -- temp bodge:
    outl(0) <= osc0_output or (not enable);
    outl(1) <= osc1_output or (not enable);
    outl(2) <= osc2_output or (not enable);
    outl(3) <= osc3_output or (not enable);
    outl(4) <= osc4_output or (not enable);
    outl(5) <= osc5_output or (not enable);
    outr(0) <= osc0_output or (not enable);
    outr(1) <= osc1_output or (not enable);
    outr(2) <= osc2_output or (not enable);
    outr(3) <= osc3_output or (not enable);
    outr(4) <= osc4_output or (not enable);
    outr(5) <= osc5_output or (not enable);

/*
    NOISE0: entity work.noise_bitstream
        port map (

        );

    NOISE1: entity work.noise_bitstream
        port map (

        );

    ENV0 : entity work.env
        port map (
        
        );

    ENV1 : entity work.env
        port map (
        
        );

    CLOCKS : entity work.clocks
        port map (

        );

    STEP_COUNTER : entity work.step_counter
        port map (

        );

    AMP0 : entity work.amp
        port map (

        );
    
    AMP1 : entity work.amp
        port map (

        );

    AMP2 : entity work.amp
        port map (

        );

    AMP3 : entity work.amp
        port map (

        );

    AMP4 : entity work.amp
        port map (

        );

    AMP5 : entity work.amp
        port map (

        );

    MIXER0 : entity work.mixer
        port map (

        );

    MIXER1 : entity work.mixer
        port map (

        );

    MIXER2 : entity work.mixer
        port map (

        );

    MIXER3 : entity work.mixer
        port map (

        );

    MIXER4 : entity work.mixer
        port map (

        );

    MIXER5 : entity work.mixer
        port map (

        );
*/
    process (clk)
    begin
        -- we need to track if this was an 'address' write, and if so send a pulse to the envelope generators
        a0_pulse <= '0';

        -- we need to track if octave registers were written to, since this is a trigger for the oscillator
        -- to also capture the freq registers at the same time
        osc01_wr <= '0';
        osc23_wr <= '0';
        osc45_wr <= '0';

        if rising_edge(clk) then
            if wr_n='0' and cs_n='0' then

                if a0='1' then
                    -- a0 is high (i.e. register write)
                    reg <= d(4 downto 0); -- higher bits unused; register file repeats according to datasheet
                    if a0_pulse='0' then
                        -- set a0_pulse for one cycle (triggers for env if configured that way)
                        a0_pulse <= '1';
                    end if;

                else
                    if reg(4 downto 3) = "00" then
                        -- amplitude register; need to consider wait states
                        --
                        if reg(2 downto 0) = "000" then
                            amp0 <= d;
                        elsif reg(2 downto 0) = "001" then
                            amp1 <= d;
                        elsif reg(2 downto 0) = "010" then
                            amp2 <= d;
                        elsif reg(2 downto 0) = "011" then
                            amp3 <= d;
                        elsif reg(2 downto 0) = "100" then
                            amp4 <= d;
                        elsif reg(2 downto 0) = "101" then
                            amp5 <= d;
                        else
                            -- unused
                        end if;
                    elsif reg(4 downto 3) = "01" then
                        -- freq register
                        if reg(2 downto 0) = "000" then
                            freq0 <= d;
                        elsif reg(2 downto 0) = "001" then
                            freq1 <= d;
                        elsif reg(2 downto 0) = "010" then
                            freq2 <= d;
                        elsif reg(2 downto 0) = "011" then
                            freq3 <= d;
                        elsif reg(2 downto 0) = "100" then
                            freq4 <= d;
                        elsif reg(2 downto 0) = "101" then
                            freq5 <= d;
                        else
                            -- unused
                        end if;
                    elsif reg(4 downto 0) = "10000" then
                        -- oct0 and 1 register
                        oct0(2 downto 0) <= d(2 downto 0);
                        oct1(2 downto 0) <= d(6 downto 4);
                        oct01_wr <= '1';
                    elsif reg(4 downto 0) = "10001" then
                        -- oct2 and 3 register
                        oct2(2 downto 0) <= d(2 downto 0);
                        oct3(2 downto 0) <= d(6 downto 4);
                        oct23_wr <= '1';
                    elsif reg(4 downto 0) = "10010" then
                        -- oct4 and 5 register
                        oct4(2 downto 0) <= d(2 downto 0);
                        oct5(2 downto 0) <= d(6 downto 4);
                        oct45_wr <= '1';
                    elsif reg(4 downto 0) = "10100" then
                        freq0_en <= d(0);
                        freq1_en <= d(1);
                        freq2_en <= d(2);
                        freq3_en <= d(3);
                        freq4_en <= d(4);
                        freq5_en <= d(5);
                    elsif reg(4 downto 0) = "10101" then
                        noise0_en <= d(0);
                        noise1_en <= d(1);
                        noise2_en <= d(2);
                        noise3_en <= d(3);
                        noise4_en <= d(4);
                        noise5_en <= d(5);
                    elsif reg(4 downto 0) = "10110" then
                        noise0_sel <= d(1 downto 0);
                        noise1_sel <= d(5 downto 4);
                    elsif reg(4 downto 0) = "11000" then
                        env0_lr <= d(0);
                        env0_wave(2 downto 0) <= d(3 downto 1);
                        env0_res <= d(4);
                        env0_clk_source <= d(5);
                        env0_en <= d(7);
                    elsif reg(4 downto 0) = "11001" then
                        env1_lr <= d(0);
                        env1_wave(2 downto 0) <= d(3 downto 1);
                        env1_res <= d(4);
                        env1_clk_source <= d(5);
                        env1_en <= d(7);
                    elsif reg(4 downto 0) = "11100" then
                        enable <= d(0);
                        sync_rst <= d(1);
                    else
                        -- unused
                    end if;
                end if;
            end if;
        end if;
    end process;
end behaviour;
