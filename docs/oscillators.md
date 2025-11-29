Notes on "does level jump to 1 immediately after sync(reset) is de-asserted"

Multiple runs of experiment : 28,2 asserted for 16+40000 clocks ; 28,1 asserted then for 16+10 clocks
*  (of 16 clocks on write) 9 before level change and 7 after;  then my 10 clocks after
* 9 before level change and 7 after (but look the level changed during a big pause between the 9 and the 7); then my 10 clocks after
* again 9 before and 7 after

changed 28,2 timing to be 16+39999 clocks instead:
* 10 (and a half?) before, 5 (and a half?) after
* 10 before, 6 after
* 10 before, 6 after

tried 40000 again, seemed a bit variable, sometimes more clearly 9 before, sometimes more clearly 10 before
39998, looked like 9 before

Did it all again with octave 6 instead of octave 7, and 16+10000 clocks
really interesting/weird:
shows again around 9 or 10 before the level change
but then after 10 ticks the level went back to zero
and it seemed reproducible
Doing 20 clocks after instead of 10 clocks after revealed what I hoped to see:  the "level went back to zero" seemed to just be the volume PDM, since it lasted
for 4 clocks which is what we expect for volume=15
