# SAASoundVHDL
SAA1099 : VHDL (and similar) hardware definitions and collected notes and test cases

This is an attempt to bring together knowledge from software emulation and other FPGA cores, to produce a validated core definition that passes test cases.
The starting point for this project is my own C/C++ emulation : https://github.com/stripwax/SAASound  which has been in popular usage since 1998 within the SimCoupé emulator, and was built entirely from my own reverse-engineering experiments, beginning in 1997.
More recently (although at this point nearly 10 years ago), with some interesting experiments and discussions in VOGONS website forum, some new ideas pointed to behaviours
previously not analysed that could then be implemented correctly.  Over time this has included valuable insights (i.e. bug reports!) from far and wide.
My desire (with this project) is to convert this into an equivalent gate-level implementation.

# Aims
* VHDL for SAA1099 core (FPGA platform not decided yet)
* Test cases
* Validation that core passes tests
* Latest 'bugfixes'
* Collected knowledgebase
* (Future goal?) hardware replacement for physical SAA-1099 chip no longer in production
* (Future goal?) New advanced modes that can be enabled on-chip but backwards compatible with existing software


# Notes around flaws/observations in other projects:

* ZXUNO core SAA1099 is 9 years old at time of writing : https://github.com/zxdos/zxuno/blob/master/cores/SamCoupe/saa1099.v
* MIST core SAA1099 9 years old at time of writing : https://github.com/sorgelig/SAMCoupe_MIST/blob/master/saa1099.sv  (even though based in-part on my SAASound, it does not include latest fixes)
* Both don't appear to be validated (test cases), and/or the test case validation is not documented  [please correct me if I'm wrong on this point!]
* Both don't implement the DTACK output. Not relevant afaik for SAM Coupé emulation but maybe important for other devices, at least according to SAA datasheets.  Relevant for the aim for physical device replacement, certainly.
* My SAASound has had numerous features and fixes applied in the intervening periods i.e. newer than ZXUNO and MIST cores - in particular to envelope generator logic, sync logic, edge-cases around manual clocking, and accurate amplitude and noise mixing logic. The likelihood at this point is that both the above cores would have emulation defects that have since been resolved already in SAASound (SimCoupé) .  SAASound is there currently the most up-to-date, tested, and comprehensive, SAA-1099 emulation library available.  However it is software-only , hence this project

# Other software emulators:
* Software emulation for CMS in DOSBox is missing a lot of standard features that even older versions of SAASound implemented out-of-the-box . However DOSBox's implementation tries to model the 8MHz bitstream output, which is more like a hardware simulator than an audio emulator (so - in theory - could match a real SAA1099 bit-for-bit ; but in practice it does not)
* MAME (at least last time I looked) had very poor incomplete emulations of SAA1099 e.g. did not even implement correctly the "envelope appear at output" ('DAC mode')
* This thread : https://www.worldofsam.org/forum/2018-08-09/1082 includes a number of discussions of experimental discrepancies detected in different emulation as compared to real hardware (notably based around SimCoupé i.e. my SAASound library but also references to MIST/MISTer)
* SAAEmu http://www.keprt.cz/sam/saa/ - based on an old version of my SAA1099 so does not include most of the logic fixes added over the years
  
