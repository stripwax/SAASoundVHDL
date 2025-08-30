https://www.vogons.org/viewtopic.php?t=51695

Details taken from above thread, but with corrections applied, below:

    18-bit Galois LFSR
    Feedback polynomial = x^18 + x^11 + 1
    Period = 2^18-1 = 262143 bits

Pseudocode from that thread

    static uint32_t lfsr=1; // seed unknown, must be non-zero

    if (lfsr&1)
    {
        lfsr=(lfsr>>1)^0x20400;
        return 1;
    }
    else
    {
        lfsr=(lfsr>>1);
        return 0;
    }

Hardware-synthesisable pseudocode (@stripwax)

    static uint32_t lfsr=1; // seed unknown, must be non-zero
    uint32_t mask = ((lsfr&1)<<17) | ((lsfr&1)<<10);
    lfsr=(lfsr>>1)^mask;
    /* or equivalent, since lsb ^ 0 is same as lsb:
    uint32_t mask = ((lsfr&1)<<10);
    lfsr=((lsfr&1)<<17) | ((lfsr>>1)^mask);
    */
    return lsb;
