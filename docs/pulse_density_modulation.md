Taken from my own analysis in vogons thread:
https://www.vogons.org/viewtopic.php?t=51695&start=60

But with some more recent thoughts and ideas captured below:


AMPLITUDE PDM SEQUENCES
==

This is the original table from my 2018 analysis:

|level|bitstream|ratio|
|-----|---------|-----|
|0    |0000000000000000000000000000000000000000000000000000000000000000|0/64|
|1    |0000000011110000000000000000000000000000000000000000000000000000|4/64|
|2    |0000000000001111111100000000000000000000000000000000000000000000|8/64|
|3    |0000000011111111111100000000000000000000000000000000000000000000|12/64|
|4    |0000000000000000000000000000000000001111111111111111000000000000|16/64|
|5    |0000000011110000000000000000000000001111111111111111000000000000|20/64|
|6    |0000000000001111111100000000000000001111111111111111000000000000|24/64|
|7    |0000000011111111111100000000000000001111111111111111000000000000|28/64|
|8    |1111000000000000000011111111111111110000000000000000111111111111|32/64|
|9    |1111000011110000000011111111111111110000000000000000111111111111|36/64|
|10   |1111000000001111111111111111111111110000000000000000111111111111|40/64|
|11   |1111000011111111111111111111111111110000000000000000111111111111|44/64|
|12   |1111000000000000000011111111111111111111111111111111111111111111|48/64|
|13   |1111000011110000000011111111111111111111111111111111111111111111|52/64|
|14   |1111000000001111111111111111111111111111111111111111111111111111|56/64|
|15   |1111000011111111111111111111111111111111111111111111111111111111|60/64|

My current thinking is that step 0 in the sequence is the fourth column from the above table: meaning that all levels begin with four periods at zero


ENVELOPE PDM SEQUENCES
==

This is the original table from my 2018 analysis:

|level|bitstream|ratio|
|-----|---------|-----|
|0    |0000000000000000000000000000000000000000000000000000000000000000|0/64|
|1    |0000000000001000000000000000100000000000000010000000000000001000|4/64|
|2    |0000010000000100000001000000010000000100000001000000010000000100|8/64|
|3    |0000010000001100000001000000110000000100000011000000010000001100|12/64|
|4    |0011000000110000001100000011000000110000001100000011000000110000|16/64|
|5    |0011000000111000001100000011100000110000001110000011000000111000|20/64|
|6    |0011010000110100001101000011010000110100001101000011010000110100|24/64|
|7    |0011010000111100001101000011110000110100001111000011010000111100|28/64|
|8    |1100001111000011110000111100001111000011110000111100001111000011|32/64|
|9    |1100001111001011110000111100101111000011110010111100001111001011|36/64|
|10   |1100011111000111110001111100011111000111110001111100011111000111|40/64|
|11   |1100011111001111110001111100111111000111110011111100011111001111|44/64|
|12   |1111001111110011111100111111001111110011111100111111001111110011|48/64|
|13   |1111001111111011111100111111101111110011111110111111001111111011|52/64|
|14   |1111011111110111111101111111011111110111111101111111011111110111|56/64|
|15   |1111011111111111111101111111111111110111111111111111011111111111|60/64|

Similarly, I now believe that step 0 in the sequence is the fourth column from the above table too: meaning that all levels begin with one period at zero

MIXER
==

Mixed output is simply the logic AND of the two
Note that, if the frequency oscillator is disabled, then the 'output' of the frequency oscillator is taken to be all 1s i.e. 64/64
This interacts in the expected way with the envelope generator and mixer, which is how the output of the envelope on its own (e.g. triangle wave) can
be made audible, as used in various DAC examples.
Note also that, when the env control is enabled for a channel, the LSB of the AMPLITUDE register for that channel is ignored, hence why standard DAC examples have only 3-bit resolution at the output rather than 4-bit.

If the envelope generator is operating in "3-bit mode" instead of "4-bit mode" then the LSB of the envelope output (0-15) is taken to be zero, but the same PDM sequences apply

COMBINATORIAL LOGIC EXPLANATION
==

Starting with the AMPLITUDE table, as it's a bit easier:

Represent each AMPLITUDE as a 4-bit value using bits A<sub>3</sub> A<sub>2</sub> A<sub>1</sub> A<sub>0</sub> .

Consider a 6-bit counter, representing time and numbering each step Step<sub>0</sub> thru Step<sub>63</sub> .  Label these bits C<sub>5</sub> C<sub>4</sub> C<sub>3</sub> C<sub>2</sub> C<sub>1</sub> C<sub>0</sub>.

Group the PDM bitstream into chunks of four bits (taking note of my above comment about where step 0 is in this table). The 'grouping into blocks of 4' is essentially just a 4-bit counter (although with some small additional complexity described later).  But in practical terms, consider instead a 6-bit counter, and extract just the topmost four bits (C<sub>5</sub>-C<sub>2</sub>), and use these for looking up the value from the table.


The following table then defines the values for each step:

|step|value|
|----|-----|
|0-3  | =0  |
|4-7  | =A<sub>0</sub> |
|8-11 | =A<sub>1</sub> |
|12-15| =A<sub>1</sub> |
|16-19| =A<sub>3</sub> |
|20-23| =A<sub>3</sub> |
|24-27| =A<sub>3</sub> |
|38-31| =A<sub>3</sub> |
|32-35| =A<sub>2</sub> |
|36-39| =A<sub>2</sub> |
|40-43| =A<sub>2</sub> |
|44-47| =A<sub>2</sub> |
|48-51| =A<sub>3</sub> |
|52-55| =A<sub>3</sub> |
|56-59| =A<sub>3</sub> |
|60-63| =A<sub>3</sub> |


Similarly, for the ENVELOPE table - treating it as its own standalone thing for now:

Represent each of the possible outputs of the EVENLOPE as a 4-bit value using bits E<sub>3</sub> E<sub>2</sub> E<sub>1</sub> E<sub>0</sub> .

For this one, there's no need to do any grouping into blocks of four clocks.  Instead, we observe that each pattern repeats four times across the 64-clock period.  So again consider a 6-bit counter but extract just the lower 4 bits, and use these for looking up the value from the table.  In this sense, Step<sub>0</sub> and Step<sub>16</sub> and Step<sub>32</sub> and Step<sub>40</sub> point to the same row of the table.

|step|value|
|----|-----|
|0 (, 16, 32, 40) | =0  |
|1 (, 17, 33, 41) | =E<sub>1</sub> |
|2 (, .. etc)     | =E<sub>3</sub> |
|3  | =E<sub>3</sub> |
|4  | =E<sub>3</sub> |
|5  | =E<sub>3</sub> |
|6  | =E<sub>2</sub> |
|7  | =E<sub>2</sub> |
|8  | =E<sub>0</sub> |
|9  | =E<sub>1</sub> |
|10 | =E<sub>3</sub> |
|11 | =E<sub>3</sub> |
|12 | =E<sub>3</sub> |
|13 | =E<sub>3</sub> |
|14 | =E<sub>2</sub> |
|15 | =E<sub>2</sub> |

To combine these you need to then consider a few differnt cases:
* if ENV is enabled, use zero instead of LSB of AMPLITUDE (i.e. use C<sub>0</sub> = 0 in this case)
* if FREQ output is disabled, use '1' for all values of Step for AMPLITUDE PDM
* If ENV is operating in 3-bit mode, use zero instead of LSB of ENVELOPER (i.e. use E<sub>0</sub> = 0 in this case)

Then it's just a case of computing the logical AND according to the above cases.

If you do all this, you can simplify everything to quite a small number of logic gates and a single counter for Step .

For example, for AMPLITUDE:

Step 4-7 matches the rule: A<sub>0</sub> AND C<sub>2</sub> AND NOT (C<sub>5</sub> OR C<sub>4</sub> OR C<sub>3</sub>)

For ENVELOPE:

Step 15 matches the rule: E<sub>2</sub> AND C<sub>2</sub> AND C<sub>1</sub>

For additional optimizations, you could then repeat this exercise for all possible shifts (i.e. instead of saying "Step 0 begins at the 4th timestep in the AMPLITUDE PDM tables" you could say "Step 0 begins at the 0th timestep" or "Step begins at the 62nd timestep").  So long as you use the same shift for both AMPLITUDE PDM and ENVELOPE PDM, the end results are completely equivalent (and it's virtually impossible to replicate how many ticks at 8mhz have passed since power-on-initialization while analysing the behaviour of these steps).  But different shifts might actually result in simpler logic (fewer gates)

Given the ordering of the sequences for ENVELOPE PDM, it also looks like a grey-code counter might be more appropriate than a regular counter;  but only if the advantage in logic offsets the cost of having two separate counters rather than just one global step counter.
