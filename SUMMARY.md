# SAASoundVHDL

## Overview

Gate-level VHDL implementation of the **Philips SAA1099** 6-channel sound synthesizer chip, based on years of reverse-engineering and software emulation experience from the [SAASound](https://github.com/stripwax/SAASound) C/C++ library (used in the SimCoupé emulator since 1998).

## Purpose

- Provide a validated, up-to-date SAA1099 core in VHDL for FPGA platforms
- Serve as a hardware replacement for the SAA-1099 chip, which is no longer in production
- Capture and validate the latest bugfixes and behavioral corrections discovered through community contributions (notably via VOGONS forum discussions)

## Architecture

The project implements the SAA1099 at the gate/RTL level, decomposed into the following units:

| Unit | Description |
|------|-------------|
| `saa1099_chip.vhdl` | Top-level chip: 6-channel sound synthesis with left/right digital bitstream outputs |
| `osc.vhdl` | Oscillator (6 instances) with frequency, octave, and sync control |
| `noise_bitstream.vhdl` | Noise generator (2 instances) using 18-bit Galois LFSR (polynomial x^18 + x^11 + 1) |
| `mixer.vhdl` | Bitwise AND mixer combining oscillator, noise, and envelope signals |
| `amp.vhdl` / `amp_chop.vhdl` | Amplitude modulation with 4-bit PDM (pulse density modulation) |
| `env.vhdl` / `env_chop.vhdl` | Envelope generator (2 instances) with configurable waveform, resolution, and clock source |
| `clocks.vhdl` | Clock division network generating noise and octave clock triggers |

Each of the 6 channels combines an oscillator and noise source through a mixer, then through amplitude modulation, to produce left/right bitstream outputs. Channels 2 and 5 support envelope generator modulation.

## Key Technical Details

- **6 independent sound channels** with programmable frequency, amplitude, and octave
- **2 noise generators** (18-bit Galois LFSR) shared across channels
- **2 envelope generators** assignable to channels 2 and 5
- **Pulse density modulation (PDM)** for amplitude and envelope output (64-step sequences per period)
- **Digital bitstream outputs** (`outl[5:0]`, `outr[5:0]`) synchronised with clock
- **DTACK output** support (absent in other FPGA cores)
- **8 MHz clock** input

## Documentation

| File | Content |
|------|---------|
| `docs/architecture.md` | Mermaid block diagram of the full chip architecture |
| `docs/oscillators.md` | Notes on oscillator sync and level timing behaviour |
| `docs/pulse_density_modulation.md` | Detailed PDM sequence tables and combinatorial logic derivation |
| `docs/lsfr.md` | LFSR polynomial and hardware-synthesisable pseudocode |
| `tests/docs/references.md` | External references and prior art |

## Testing

Unit test benches in `tests/units/`:

- `tb_osc.vhdl` — Oscillator tests
- `tb_amp.vhdl` — Amplitude modulation tests
- `tb_clocks.vhdl` — Clock division tests
- `tb_noise_bitstream.vhdl` — Noise generator tests

Top-level testbench: `tests/tb_saa1099_sim.vhdl`

Debug waveforms and analysis captured in `tests/debugsaa*.txt` files.

## License

GNU General Public License v3+ (GPL-3.0-or-later). See `LICENSE` for full text.

## Acknowledgements

Contributions from Simon Owen, Stefan Drissen, Anton Javorček, Balor Price, Miguel Angel Rodríguez Jódar, Theo Niessink, and the VOGONS community.

## Future Goals

- Target hardware deployment on a specific FPGA platform
- Add advanced on-chip modes that remain backwards compatible with existing SAA1099 software
