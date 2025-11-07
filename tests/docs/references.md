# Collection of tests cases for validation

## Manual testing

* My test cases documentation: https://github.com/stripwax/SAASound/wiki/Test-cases
* For downloadable .DSK file for use with SimCoupe emulator see: https://github.com/stripwax/SAASound/tree/8eae13dea9d34919f0ec4ecc18765ad0b72444cf/tests

## General notes

* When outputs are disabled (i.e. 28=0), or sync (28=2 or 28=3), volumes are zero, or channels are muted, chip output levels are pulled high.  This is because the chip outputs are current sinks with pullups.
* You can think of this as 'inverted' logic, and it's ok to reason about the oscillator outputs etc as the inverse of this:  when a channel is disabled, or muted, or volume is zero, think of the output as 0.  It's just the on-chip amplifier outputs that inverts this.
* As a result, oscilloscope traces tend to be 'upside down' from a logic perspective but that's ok.
* I will tend to describe the logic in terms of "muted means 0", i.e. the INVERSE of the oscilloscope outputs.  I'll refer to this as 'logical' 0.  Or if otherwise I will be explicit.  For example, explicitly, the very last output clause in saa1099_chip.vhdl inverts the logical output (so that saa1099_chip.vhdl output is "same as oscilloscope output")

* The PDM chopping logic for amplitude control AND envelope controls works both in the same direction (0-volume amp towards logical 0 and 0-volume env towards logical 0)

## Noise generators

* When chip is enabled AND sync (reset=1), the noise generators are still running, and indeed are triggered at their maximum (15.6kHz) freq. , equivalent to N01:N00 being set to 00 .  The noise generators themselves are never reset/disabled by the sync/reset bit.  The implication is also that they are constantly running.
* Even if running at the same noise trigger frequency, the two noise generators change can state independently.  For example, just because one noise generator is running at 15.6kHz (N01:N00 == 0) and the other at half that (N01:N00 == 01), does no mean that they change state at clean edge boundaries.  They are out of sync in terms of cycles.  They will change state (independently) according to their own statemachine transitioning according to master clock.
* There does not appear to be any way to synchronise the two noise generators to each other. (A fun experiment would be to TRY - e.g. 'speed up' one of the noise generators and then slow it down again to see if you can catch it up with the other one)
* For both noise generator 0 and 1 , the polynomial is 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1 .  Fun fact!  You can confirm this for yourself by capturing the bitstream of the noise generator (0 or 1) on an oscilloscope and reading out the pulses and invoking the Berlekamp-Massey algorithm to derive the polynomial from the outputs!  You need to remember about the polarity: a 'low' pulse is a logical 1 and a 'high' pulse is a logical 0. HOWEVER in the case of SAA1099, the output of the noise generators is in fact flipped!  In other words: where the LSFR generates a "0", the output of the noise generator (or at least the logical value seen at the mixer output) is a "1", and vice versa. (From the perspective of the logical output; the actual amplifier output inverts this again so, interestingly, the perceived output on the oscilloscope matches the actual LSFR output).  (There's maybe no good reason why the output of the LFSR is itself flipped here by SAA1099, unless it is a trick to simplify power-on-reset of the initial state of the noise generators, or something like that, or simply an optimisation in gate count)

```python
from lfsr_tools import BerlekampMassey
# the below sequence was read out from an oscilloscope view, taking a 'low' as binary 1 and a 'high' as binary 0
# This was before I realised that the LFSR output is being inverted in the SAA1099 mixer logic.
# Hence the "1-" below
sequence = [1-int(x) for x in list("010101100111100101100101010011010000111100001101010111011001011100011")]
bkm = BerlekampMassey(sequence)
bkm.estimate_polynomial()

>>>  array([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1])
```
* I'm assuming that the mixer (freq + noise) is just binary AND (rather than OR), since there is a half-cycle of logical 0 followed by a half-cycle of noise.
* Therefore we could say that the mixer function is (freq AND noise) but where NOISE is the inverse of the LSFR output... or we could say that the mixer is "FREQ OR NOISE" and then this is inverted.  It's not yet possible to know if the oscillator's squarewave output is 0101 or 1010 ; arguably it doesn't matter.
* However, one thing that DOES matter is whether the oscillator's output immediately after being enabled (e.g. sync/reset going from 1 to 0) starts with a half-cycle of logical 1 , or logical 0.  I have to assume it starts with a half-cycle of logical 1 but I need to also find a good way to determine this empirically (tricky timing to actually observe it directly)

### Features/easter eggs
* If you set the noise generator to be "oscillator triggered" (N01:N00=11), (and enable the noise output in the mixer and set the volume, etc), and ALSO set the global sync/reset flag, then the noise output is a bitstream at a frequency dictated by ONLY the octave register (modulated by the amplitude etc).  Usually of course the noise generators output noise in audio frequency ranges based on the output of the oscillator, but with the global sync/reset flag set then the oscillators do not oscillate :-)  but with the sync/reset bit set, the noise generator appears to be triggered every cycle of "clock tick divided by octave divisor".  It appears that OCT=7 means 'divide by 2', OCT=6 means "divide by 4", OCT=5 means "divide by 8", etc. In other words: if octave register is set to OCT=7, then the noise output is clocked at 4MHz; if octave register is set to OCT=6 then the output is at 2MHz, OCT=5 => 1MHz, and so on.  OCT=0 => 31.25 kHz.  Confirmed experimentally on-chip.  Actually I need to be more careful with my terminology: when I say that the noise output is "clocked at 4MHz", I mean that (with an 8MHz clock 125ns high-pulse width and 125ns low-pulse width, and OCT=7) the noise generator changes *state* at half the frequency of the clock i.e. every *250ns* and therefore the output pulses are minimum 250ns width (or some multiple, because it's noise) (and if the noise output happens to be oscillatory then the output *waveform* appears to be a square-wave with *half*-cycle *250ns*). See testcase `debuggsaa_noise_8mhz.txt` .  Note also that this configuration with OCT=0 => 31.25kHz noise output, has identical output to the standard configuration of N01:N00=00 and sync/reset bit cleared.

## Automated testing


