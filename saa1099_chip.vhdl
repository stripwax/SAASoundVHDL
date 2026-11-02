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
    signal data_latch : std_logic_vector(7 downto 0);
    signal a0_latch : std_logic;
    signal wr_pending : std_logic;
    signal clear_pending : std_logic := '0';
    signal wr_pending_sync : std_logic_vector(1 downto 0);
    signal reg : std_logic_vector(4 downto 0);

    signal write_active : std_logic;

    signal amp0 : std_logic_vector(7 downto 0);
    signal amp1 : std_logic_vector(7 downto 0);
    signal amp2 : std_logic_vector(7 downto 0);
    signal amp3 : std_logic_vector(7 downto 0);
    signal amp4 : std_logic_vector(7 downto 0);
    signal amp5 : std_logic_vector(7 downto 0);
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
    signal env0_res : std_logic := '0'; -- SIMULATION ONLY, REMOVE LATER
    signal env0_clk_source : std_logic;
    signal env0_en : std_logic := '0'; -- SIMULATION ONLY, REMOVE LATER
    signal env1_lr : std_logic;
    signal env1_wave : std_logic_vector(2 downto 0);
    signal env1_res : std_logic := '0'; -- SIMULATION ONLY, REMOVE LATER
    signal env1_clk_source : std_logic;
    signal env1_en : std_logic := '0'; -- SIMULATION ONLY, REMOVE LATER
    signal reg_28_load_en : std_logic; -- this unit only implements register 28, the rest are forwarded to the other units
    signal enable, sync_rst : std_logic;
    signal reg_enable : std_logic := '0';
    signal reg_sync_rst : std_logic;

    signal a0_wr, d_wr: std_logic;

    signal osc0_output: std_logic;
    signal osc0_trigger: std_logic;
    signal osc1_output: std_logic;
    signal osc1_trigger: std_logic;
    signal osc2_output: std_logic;
    signal osc2_trigger: std_logic;  -- unused
    signal osc3_output: std_logic;
    signal osc3_trigger: std_logic;
    signal osc4_output: std_logic;
    signal osc4_trigger: std_logic;
    signal osc5_output: std_logic;
    signal osc5_trigger: std_logic;  -- unused

    signal freq0_wr, freq1_wr, freq2_wr, freq3_wr, freq4_wr, freq5_wr: std_logic;
    signal freq0_wr_prev, freq1_wr_prev, freq2_wr_prev, freq3_wr_prev, freq4_wr_prev, freq5_wr_prev: std_logic;
    signal freq0_wr_pulse, freq1_wr_pulse, freq2_wr_pulse, freq3_wr_pulse, freq4_wr_pulse, freq5_wr_pulse: std_logic;
    signal oct01_wr, oct23_wr, oct45_wr: std_logic;
    signal oct01_wr_prev, oct23_wr_prev, oct45_wr_prev: std_logic;
    signal oct01_wr_pulse, oct23_wr_pulse, oct45_wr_pulse: std_logic;
    signal env0_wr, env1_wr : std_logic;
    signal env0_wr_prev, env1_wr_prev : std_logic;
    signal env0_wr_pulse, env1_wr_pulse : std_logic;
    signal amp0_wr, amp1_wr, amp2_wr, amp3_wr, amp4_wr, amp5_wr : std_logic;
    signal noise_sel_wr : std_logic;

    signal noise0_output, noise1_output : std_logic;
    signal noise_clks : std_logic_vector(2 downto 0);
    signal octave_clks : std_logic_vector(7 downto 0);
    signal amp0l_out, amp0r_out, amp1l_out, amp1r_out, amp2l_out, amp2r_out, amp3l_out, amp3r_out, amp4l_out, amp4r_out, amp5l_out, amp5r_out : std_logic;
    signal env0l_level_out, env0r_level_out, env1l_level_out, env1r_level_out : unsigned(3 downto 0);
    signal env0l_chop_out, env0r_chop_out, env1l_chop_out, env1r_chop_out : std_logic;
    signal mixer0_out, mixer1_out, mixer2_out, mixer3_out, mixer4_out, mixer5_out : std_logic;
    signal step_ctr : unsigned(5 downto 0);

    -- edge detection:
    signal wr_edge : std_logic;

    -- debugging:
    signal outl_sum : unsigned(2 downto 0);
    signal outr_sum : unsigned(2 downto 0);

begin

    CLOCKS: entity work.clocks
        port map (
            clk => clk,
            noise_clks => noise_clks,
            octave_clks => octave_clks,
            step_ctr => step_ctr
        );

    OSC0: entity work.osc
        generic map (MAPPED_FREQ_REGISTER => 8, MAPPED_OCT_REGISTER => 16, OCT_IN_UPPER => false)
        port map (
            clk => clk,
            data => d,
            reg => reg,
            wr => d_wr,
            octave_clks => octave_clks,
            sync => sync_rst,
            output => osc0_output,
            trigger => osc0_trigger
        );

    OSC1: entity work.osc
        generic map (MAPPED_FREQ_REGISTER => 9, MAPPED_OCT_REGISTER => 16, OCT_IN_UPPER => true)
        port map (
            clk => clk,
            data => d,
            reg => reg,
            wr => d_wr,
            octave_clks => octave_clks,
            sync => sync_rst,
            output => osc1_output,
            trigger => osc1_trigger
        );

    OSC2: entity work.osc
        generic map (MAPPED_FREQ_REGISTER => 10, MAPPED_OCT_REGISTER => 17, OCT_IN_UPPER => false)
        port map (
            clk => clk,
            data => d,
            reg => reg,
            wr => d_wr,
            octave_clks => octave_clks,
            sync => sync_rst,
            output => osc2_output,
            trigger => osc2_trigger
        );

    OSC3: entity work.osc
        generic map (MAPPED_FREQ_REGISTER => 11, MAPPED_OCT_REGISTER => 17, OCT_IN_UPPER => true)
        port map (
            clk => clk,
            data => d,
            reg => reg,
            wr => d_wr,
            octave_clks => octave_clks,
            sync => sync_rst,
            output => osc3_output,
            trigger => osc3_trigger
        );

    OSC4: entity work.osc
        generic map (MAPPED_FREQ_REGISTER => 12, MAPPED_OCT_REGISTER => 18, OCT_IN_UPPER => false)
        port map (
            clk => clk,
            data => d,
            reg => reg,
            wr => d_wr,
            octave_clks => octave_clks,
            sync => sync_rst,
            output => osc4_output,
            trigger => osc4_trigger
        );

    OSC5: entity work.osc
        generic map (MAPPED_FREQ_REGISTER => 13, MAPPED_OCT_REGISTER => 18, OCT_IN_UPPER => true)
        port map (
            clk => clk,
            data => d,
            reg => reg,
            wr => d_wr,
            octave_clks => octave_clks,
            sync => sync_rst,
            output => osc5_output,
            trigger => osc5_trigger
        );

    NOISE0: entity work.noise_bitstream
        generic map (MAPPED_SEL_REGISTER => 20, SEL_IN_UPPER => false)
        port map (
            clk => clk,
            data => d,
            reg => reg,
            wr => d_wr,
            trigger_313 => noise_clks(0),
            trigger_156 => noise_clks(1),
            trigger_76 => noise_clks(2),
            trigger_osc => osc0_trigger,
            bitstream => noise0_output
        );

    NOISE1: entity work.noise_bitstream
        generic map (MAPPED_SEL_REGISTER => 20, SEL_IN_UPPER => true)
        port map (
            clk => clk,
            data => d,
            reg => reg,
            wr => d_wr,
            trigger_313 => noise_clks(0),
            trigger_156 => noise_clks(1),
            trigger_76 => noise_clks(2),
            trigger_osc => osc3_trigger,
            bitstream => noise1_output
        );

    -- mixer is purely combinatoric
    MIXER0 : entity work.mixer
        port map (
            noise_enable => noise0_en,
            freq_enable => freq0_en,
            env_enable => '0',
            noise_bitstream => noise0_output,
            freq_bitstream => osc0_output,
            mixed => mixer0_out
        );

    MIXER1 : entity work.mixer
        port map (
            noise_enable => noise1_en,
            freq_enable => freq1_en,
            env_enable => '0',
            noise_bitstream => noise0_output,
            freq_bitstream => osc1_output,
            mixed => mixer1_out
        );

    MIXER2 : entity work.mixer
        port map (
            noise_enable => noise2_en,
            freq_enable => freq2_en,
            env_enable => env0_en,
            noise_bitstream => noise0_output,
            freq_bitstream => osc2_output,
            mixed => mixer2_out
        );

    MIXER3 : entity work.mixer
        port map (
            noise_enable => noise3_en,
            freq_enable => freq3_en,
            env_enable => '0',
            noise_bitstream => noise1_output,
            freq_bitstream => osc3_output,
            mixed => mixer3_out
        );

    MIXER4 : entity work.mixer
        port map (
            noise_enable => noise4_en,
            freq_enable => freq4_en,
            env_enable => '0',
            noise_bitstream => noise1_output,
            freq_bitstream => osc4_output,
            mixed => mixer4_out
        );

    MIXER5 : entity work.mixer
        port map (
            noise_enable => noise5_en,
            freq_enable => freq5_en,
            env_enable => env1_en,
            noise_bitstream => noise1_output,
            freq_bitstream => osc5_output,
            mixed => mixer5_out
        );

    AMP_0: entity work.amp_chop
        port map (
            data => d,
            reg => reg,
            wr => d_wr,
            step_ctr => step_ctr,
            input => mixer0_out,
            envelope_enabled => '0',
            output_l => amp0l_out,
            output_r => amp0r_out
        );
    AMP_1: entity work.amp_chop
        port map (
            data => d,
            reg => reg,
            wr => d_wr,
            step_ctr => step_ctr,
            input => mixer1_out,
            envelope_enabled => '0',
            output_l => amp1l_out,
            output_r => amp1r_out
        );
    AMP_2: entity work.amp_chop
        port map (
            data => d,
            reg => reg,
            wr => d_wr,
            step_ctr => step_ctr,
            input => mixer2_out,
            envelope_enabled => env0_en,
            output_l => amp2l_out,
            output_r => amp2r_out
        );
    AMP_3: entity work.amp_chop
        port map (
            data => d,
            reg => reg,
            wr => d_wr,
            step_ctr => step_ctr,
            input => mixer3_out,
            envelope_enabled => '0',
            output_l => amp3l_out,
            output_r => amp3r_out
        );
    AMP_4: entity work.amp_chop
        port map (
            data => d,
            reg => reg,
            wr => d_wr,
            step_ctr => step_ctr,
            input => mixer4_out,
            envelope_enabled => '0',
            output_l => amp4l_out,
            output_r => amp4r_out
        );
    AMP_5: entity work.amp_chop
        port map (
            clk => clk,
            data => d,
            reg => reg,
            wr => d_wr,
            step_ctr => step_ctr,
            input => mixer5_out,
            envelope_enabled => env1_en,
            output_l => amp5l_out,
            output_r => amp5r_out
        );

    ENV0 : entity work.env
        port map (
            clk => clk,
            data => d,
            reg => reg,
            wr => d_wr,
            osc_pulse => osc1_trigger,
            a0_pulse => a0_wr,
            output_left => env0l_level_out,
            output_right => env0r_level_out,
            env_en => env0_en -- output from unit
        );

    -- env chop is purely combinatoric
    ENV_CHOP0 : entity work.env_chop
        port map (
            step_ctr => step_ctr,
            envelope_enabled => env0_en,
            input_l => amp2l_out,
            input_r => amp2r_out,
            env_l => env0l_level_out,
            env_r => env0r_level_out,
            output_l => env0l_chop_out,
            output_r => env0r_chop_out
        );

    ENV1 : entity work.env
        port map (
            clk => clk,
            data => d,
            reg => reg,
            wr => d_wr,
            osc_pulse => osc4_trigger,
            a0_pulse => a0_wr,
            output_left => env1l_level_out,
            output_right => env1r_level_out,
            env_en => env0_en -- output from unit
        );

    -- env chop is purely combinatoric
    ENV_CHOP1 : entity work.env_chop
        port map (
            step_ctr => step_ctr,
            envelope_enabled => env1_en,
            input_l => amp5l_out,
            input_r => amp5r_out,
            env_l => env1l_level_out,
            env_r => env1r_level_out,
            output_l => env1l_chop_out,
            output_r => env1r_chop_out
        );

    outl(0) <= amp0l_out and enable;
    outl(1) <= amp1l_out and enable;
    outl(2) <= env0l_chop_out and enable;
    outl(3) <= amp3l_out and enable;
    outl(4) <= amp4l_out and enable;
    outl(5) <= env1l_chop_out and enable;
    outr(0) <= amp0r_out and enable;
    outr(1) <= amp1r_out and enable;
    outr(2) <= env0r_chop_out and enable;
    outr(3) <= amp3r_out and enable;
    outr(4) <= amp4r_out and enable;
    outr(5) <= env1r_chop_out and enable;

    outl_sum <= unsigned("00" & outl(0 downto 0)) + unsigned("00" & outl(1 downto 1)) + unsigned("00" & outl(2 downto 2)) + unsigned("00" & outl(3 downto 3)) + unsigned("00" & outl(4 downto 4)) + unsigned("00" & outl(5 downto 5));
    outr_sum <= unsigned("00" & outr(0 downto 0)) + unsigned("00" & outr(1 downto 1)) + unsigned("00" & outr(2 downto 2)) + unsigned("00" & outr(3 downto 3)) + unsigned("00" & outr(4 downto 4)) + unsigned("00" & outr(5 downto 5));

    -- detect rising edge on wr (with cs still asserted) and/or cs (with wr still asserted)
    wr_edge <= (wr_n or cs_n);

    -- handle async bus writes and latch the incoming data and address line.
    -- we pipeline the "write" event via wr_pending/clear_pending and a two-stage buffer (wr_pending_sync)
    -- the buffer is shifted in the sequential logic to sample the write event and eliminate metastability
    async_bus_write : process(wr_edge, clear_pending)
    begin
        if clear_pending = '1' then
            wr_pending <= '0';
        elsif rising_edge(wr_edge) then
            data_latch <= d;
            a0_latch <= a0;
            wr_pending <= '1';
        end if;
    end process async_bus_write;

    -- write_active is a signal we set high during the clock cycle that the sequential state 
    -- machine decides to process the write. This is so that connected units can act on the same written data
    -- in the same clock cycle, rather than one cycle later.
    write_active <= '1' when (wr_pending_sync(1) = '1' and clear_pending = '0') else '0';

    reg_28_load_en <= '1' when (reg(4 downto 0) = "11100") else '0';

    sync_register_load : process(clk)
    begin
        if rising_edge(clk) then
            wr_pending_sync <= wr_pending_sync(0) & wr_pending;
            clear_pending   <= '0';

            if write_active then

                clear_pending <= '1';

                if a0_latch='1' then
                    -- a0 is high (i.e. register write)
                    reg <= data_latch(4 downto 0); -- higher bits unused; register file repeats according to datasheet
                else
                    -- write data value to register.  This unit only implements register 28, the rest are delegated to the other units
                    if reg_28_load_en='1' then
                        reg_enable <= d(0);
                        reg_sync_rst <= d(1);
                    end if;
                end if;
            end if;
        end if;
    end process sync_register_load;

    -- The clock in which this occurs is what drives the a0_pulse, and the various 'load_en' signals for the registers embedded in the units.
    -- Only this topmost unit has visibility of a0 so we compute the a0_wr pulse here
    -- Similarly we compute a d_wr pulse (data write) here too, for the 'load_en' signals.
    a0_wr <= '1' when (write_active = '1' and a0_latch = '1') else '0';
    d_wr <= '1' when (write_active = '1' and a0_latch = '0') else '0';

    -- Combinatorial forwarding/bypass.  This unit only implements enable and sync_rst registers.
    enable <= data_latch(0) when (write_active = '1' and reg_28_load_en='1') else reg_enable;
    sync_rst <= data_latch(1) when (write_active = '1' and reg_28_load_en='1') else reg_sync_rst;

end behaviour;
