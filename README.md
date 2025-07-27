# SAASoundVHDL
SAA1099 : VHDL (and similar) hardware definitions and collected notes and test cases

This is an attempt to bring together knowledge from software emulation and other FPGA cores, to produce a validated core definition that passes test cases.
The starting point for this project is my own C/C++ emulation : https://github.com/stripwax/SAASound
and desire to convert into an equivalent gate-level implementation.  In turn, my emulation was built entirely from my own reverse-engineering experiments, beginning in 1997.
More recently (although at this point nearly 10 years ago), with some interesting experiments and discussions in VOGONS website forum, some new ideas pointed to behaviours
previously not analysed that could then be implemented correctly.  Over time this has included valuable insights (i.e. bug reports!) from far and wide.

# Aims
* VHDL for SAA1099 core (FPGA platform not decided yet)
* Test cases
* Validation that core passes tests
* Latest 'bugfixes'
* Collected knowledgebase


# Notes around flaws/observations in other projects:

* ZXUNO core SAA1099 is 9 years old at time of writing : https://github.com/zxdos/zxuno/blob/master/cores/SamCoupe/saa1099.v
* MIST core SAA1099 9 years old at time of writing : https://github.com/sorgelig/SAMCoupe_MIST/blob/master/saa1099.sv  (even though based in-part on my SAASound, it does not include latest fixes)
* SAASound library has had features and fixes applied in the intervening periods so likelihood is that both the above cores would have emulation defects that have since been resolved already in SAASound (SimCoupé)
* Both don't appear to be validated (test cases), or test case validation is not documented
* Both don't implement the DTACK output. Not relevant afaik for SAM Coupé emulation but maybe important for other devices, at least according to SAA datasheets.
