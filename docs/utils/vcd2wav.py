#!/usr/bin/env python3
"""Convert VCD signal transitions to 8-bit signed stereo WAV.

Usage:
    vcd2wav.py --vcd file.vcd --left "tb.saa_0.outl" --right "tb.saa_0.outr" \
        [--samplerate 44100] [--cutoff 20] [--lowpass 20000] [-o out.wav]

The 6-bit input signals are popcounted to get levels 0-6, then mapped to
amplitudes {0, 16, 32, 48, 64, 80, 96}. An optional lowpass filter
removes bitstream artifacts above audio bandwidth. An optional highpass
filter (--cutoff) removes DC offset. Output is 8-bit signed PCM stereo WAV.
"""

import argparse
import wave
import sys
import numpy as np
import cProfile
import pstats
import io
import time


def extract_target_ids(vcd_path, left_name, right_name):
    """First pass: extract VCD IDs for target signals from header only.

    Returns (target_ids_dict, timescale) where target_ids_dict maps
    VCD ID -> channel index (0=left, 1=right).
    """
    scope_stack = []
    var_map = {}
    in_var = False
    in_timescale = False
    in_dumpvars = False
    in_block = False  # For unknown $xxx ... $end blocks
    timescale = 1
    target_set = {left_name, right_name}
    target_ids = {}

    with open(vcd_path, 'r') as f:
        for line in f:
            line = line.rstrip('\n')

            if in_block:
                if line.startswith('$end'):
                    in_block = False
                continue

            if in_dumpvars:
                if line.startswith('$end'):
                    in_dumpvars = False
                continue

            if line.startswith('$var '):
                parts = line.split()
                vtype = parts[1]
                width = int(parts[2])
                vcd_id = parts[3]
                name = ' '.join(parts[4:-1])
                full_name = '.'.join(scope_stack) + '.' + name if scope_stack else name
                var_map[vcd_id] = (name, width, full_name)
                in_var = True
                continue

            if line.startswith('$scope '):
                parts = line.split()
                scope_stack.append(parts[2])
                continue

            if line.startswith('$upscope'):
                if scope_stack:
                    scope_stack.pop()
                continue

            if line.startswith('$dumpall'):
                continue

            if line.startswith('$end'):
                if in_var:
                    in_var = False
                continue

            if line.startswith('$timescale'):
                in_timescale = True
                continue

            if in_timescale:
                parts = line.split()
                val = int(parts[0])
                unit = parts[1]
                multipliers = {'fs': 15, 'ps': 12, 'ns': 9, 'us': 6, 'ms': 3, 's': 0}
                exp = multipliers.get(unit, 0)
                timescale = val * (10 ** exp)
                in_timescale = False
                continue

            if line.startswith('$dumpvars'):
                in_dumpvars = True
                continue

            # Handle any other $xxx ... $end blocks (e.g., $date, $version, $comment)
            if line.startswith('$') and not line.startswith('$var') and not line.startswith('$scope') and \
               not line.startswith('$upscope') and not line.startswith('$dumpall') and \
               not line.startswith('$dumpvars') and not line.startswith('$timescale') and \
               not line.startswith('$end') and not line.startswith('$dumpoff') and \
               not line.startswith('$dumpon') and not line.startswith('$scope') and \
               not line.startswith('$upscope'):
                # Unknown block directive - skip until $end
                in_block = True
                continue

            # Stop at first data (we only need header)
            if line.startswith('#') or (line and not line.startswith('$')):
                break

    # Build target_ids mapping
    for vcd_id, (name, width, full_name) in var_map.items():
        if full_name in target_set:
            channel = 0 if full_name == left_name else 1
            target_ids[vcd_id] = channel

    return target_ids, timescale


def parse_vcd_streaming(vcd_path, left_name, right_name, target_ids, timescale):
    """Parse VCD file using grep pre-filtering for speed.
    
    Yields (time, channel, value) tuples where channel is 0=left, 1=right.
    """
    import subprocess
    import re
    import sys
    
    # Get signal IDs for grep pattern
    signal_ids = list(target_ids.keys())
    
    # Build grep pattern to match lines ending with our target signal IDs
    # Also include lines starting with # (time lines)
    grep_pattern = '|'.join(re.escape(sid) + r'[\s;]*$' for sid in signal_ids)
    grep_pattern = f'^#|({grep_pattern})'
    
    # Run grep to pre-filter the VCD file
    try:
        with subprocess.Popen(
            ['grep', '-E', grep_pattern, vcd_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        ) as grep_proc:
            # Process grep output line by line
            current_time = 0
            
            # Compile regex patterns
            time_re = re.compile(rb'#(\d+)')
            # Match data lines: value (with optional b/h/d/v prefix) followed by optional space and signal ID
            data_re = re.compile(rb'([bhdv]?[01]+)\s*(\S+);?\s*$')
            
            for line_bytes in grep_proc.stdout:
                # Decode once
                line = line_bytes.decode('ascii', errors='ignore')
                
                if line.startswith('#'):
                    m = time_re.match(line_bytes)
                    if m:
                        current_time = int(m.group(1))
                    continue
                
                if not line or line[0] == '$':
                    continue
                
                # Parse data line
                m = data_re.match(line_bytes)
                if m:
                    value_data = m.group(1).decode('ascii')
                    signal_id = m.group(2).decode('ascii')
                    
                    # Skip value type prefix
                    if value_data and value_data[0] in 'bhdv':
                        value_data = value_data[1:]
                    
                    # Check if this signal ID is one we care about
                    if signal_id in target_ids:
                        count = value_data.count('1')
                        channel = target_ids[signal_id]
                        yield (current_time / timescale, channel, count)
    except Exception as e:
        print(f"grep error: {e}", file=sys.stderr)
        # Fallback to slow parsing
        yield from _parse_vcd_slow(vcd_path, target_ids, timescale)


def _parse_vcd_slow(vcd_path, target_ids, timescale):
    """Slow fallback parser for when grep fails."""
    current_time = 0
    
    with open(vcd_path, 'r') as f:
        # Skip header by finding $enddefinitions
        for line in f:
            if line.startswith('$enddefinitions'):
                break
        
        # Now parse data lines
        for line in f:
            first_char = line[0]
            
            if first_char == '#':
                current_time = int(line[1:])
                continue
            elif first_char not in ('U', '0', '1', 'b', 'h', 'd', 'v'):
                continue
            
            line = line.rstrip('\n;')
            
            last_space = line.rfind(' ')
            if last_space >= 0:
                value_data = line[:last_space]
                signal_id = line[last_space + 1:]
            else:
                signal_id = line[-1:]
                if signal_id not in target_ids:
                    continue
                value_data = line[:-1]
            
            if value_data and value_data[0] in 'bhdv':
                value_data = value_data[1:]
            
            if signal_id in target_ids:
                count = value_data.count('1')
                channel = target_ids[signal_id]
                yield (current_time / timescale, channel, count)


def lowpass_filter_chunked(transitions, initial_state, lowpass_enabled, cutoff_hz):
    """Apply lowpass filter to a chunk of transitions, carrying forward state.

    Returns numpy array of shape (N, 2) with columns [time, filtered_value].
    """
    if len(transitions) == 0 or not lowpass_enabled:
        return transitions

    times = transitions[:, 0]
    amps = transitions[:, 1].copy()

    if initial_state is not None:
        prev_time, prev_amp = initial_state
        # Prepend the previous state
        times = np.concatenate(([prev_time], times))
        amps = np.concatenate(([prev_amp], amps))

    tau = 1.0 / (2.0 * np.pi * cutoff_hz)
    dt = np.diff(times)

    # Compute decay factors
    alpha = np.exp(-dt / tau)

    # IIR filter (still a loop due to recurrence)
    filtered = np.empty_like(amps)
    filtered[0] = amps[0]

    for i in range(1, len(filtered)):
        if dt[i-1] > 0:
            filtered[i] = filtered[i-1] * alpha[i-1] + amps[i] * (1.0 - alpha[i-1])
        else:
            filtered[i] = amps[i]

    # Return as (times, filtered) pairs
    result = np.empty((len(times), 2), dtype=np.float64)
    result[:, 0] = times
    result[:, 1] = filtered
    return result


def _lowpass_filter_numba(transitions, initial_state, cutoff_hz):
    """Numba-accelerated lowpass filter."""
    import numba
    from numba import njit

    @njit
    def _filter(times, amps, initial_time, initial_amp, tau):
        n = len(times)
        filtered = np.empty(n, dtype=np.float64)
        filtered[0] = initial_amp
        for i in range(1, n):
            dt = times[i] - times[i-1]
            if dt > 0:
                alpha = np.exp(-dt / tau)
                filtered[i] = filtered[i-1] * alpha + amps[i] * (1.0 - alpha)
            else:
                filtered[i] = amps[i]
        return filtered

    times = transitions[:, 0]
    amps = transitions[:, 1].copy()

    if initial_state is not None:
        prev_time, prev_amp = initial_state
        times = np.concatenate(([prev_time], times))
        amps = np.concatenate(([prev_amp], amps))

    tau = 1.0 / (2.0 * np.pi * cutoff_hz)
    filtered = _filter(times, amps, initial_state[0] if initial_state else times[0],
                       initial_state[1] if initial_state else amps[0], tau)

    result = np.empty((len(times), 2), dtype=np.float64)
    result[:, 0] = times
    result[:, 1] = filtered
    return result


def apply_highpass_filter_vectorized(samples, sample_rate, cutoff_hz):
    """Apply first-order highpass filter using scipy.signal.lfilter if available."""
    if cutoff_hz is None or len(samples) == 0:
        return samples

    try:
        from scipy import signal
        # Highpass: y[n] = alpha*(x[n] - x[n-1]) + (1-alpha)*y[n-1]
        # This is equivalent to: b=[alpha, -alpha], a=[1, -(1-alpha)]
        alpha = (2 * np.pi * cutoff_hz) / (2 * np.pi * cutoff_hz + sample_rate)
        b = np.array([alpha, -alpha])
        a = np.array([1.0, -(1.0 - alpha)])
        return signal.lfilter(b, a, samples)
    except ImportError:
        # Fallback to Python loop
        alpha = (2 * np.pi * cutoff_hz) / (2 * np.pi * cutoff_hz + sample_rate)
        filtered = np.empty_like(samples, dtype=np.float64)
        filtered[0] = alpha * samples[0]
        prev_input = samples[0]
        prev_output = filtered[0]
        for i in range(1, len(samples)):
            y = alpha * (samples[i] - prev_input) + (1 - alpha) * prev_output
            filtered[i] = y
            prev_input = samples[i]
            prev_output = y
        return filtered


def sample_signal(transitions, start_time, end_time, sample_rate):
    """Sample filtered signal at regular intervals using numpy.

    Returns numpy array of amplitude values.
    """
    if len(transitions) == 0:
        return np.array([])

    times = transitions[:, 0]
    values = transitions[:, 1]

    mask = (times >= start_time) & (times <= end_time)
    times = times[mask]
    values = values[mask]

    if len(times) == 0:
        return np.array([])

    sample_period = 1.0 / sample_rate
    num_samples = int((end_time - start_time) / sample_period) + 1
    sample_times = start_time + np.arange(num_samples) * sample_period

    indices = np.searchsorted(times, sample_times, side='right') - 1
    indices = np.clip(indices, 0, len(times) - 1)

    amplitudes = values[indices] * 16.0

    return amplitudes


def _write_wav_chunk(wav_file, left_samples, right_samples):
    """Write a chunk of samples to the WAV file."""
    if not left_samples and not right_samples:
        return

    left_8bit = np.clip(left_samples, -128, 127).astype(np.int16) + 128
    right_8bit = np.clip(right_samples, -128, 127).astype(np.int16) + 128

    interleaved = np.empty(len(left_8bit) * 2, dtype=np.uint8)
    interleaved[0::2] = left_8bit.astype(np.uint8)
    interleaved[1::2] = right_8bit.astype(np.uint8)

    wav_file.writeframes(interleaved.tobytes())


def main():
    parser = argparse.ArgumentParser(
        description='Convert VCD signals to 8-bit signed stereo WAV.'
    )
    parser.add_argument('--vcd', required=True, help='Path to VCD file')
    parser.add_argument('--left', required=True, help='VCD signal name for left channel')
    parser.add_argument('--right', required=True, help='VCD signal name for right channel')
    parser.add_argument('--samplerate', type=int, default=44100, help='Output sample rate (default: 44100)')
    parser.add_argument('--lowpass', type=float, default=None, help='Lowpass filter cutoff in Hz (default: samplerate/2)')
    parser.add_argument('--no-lowpass', action='store_true', help='Disable lowpass filtering')
    parser.add_argument('--cutoff', type=float, default=None, help='Highpass filter cutoff in Hz for DC removal (default: disabled)')
    parser.add_argument('-o', '--output', default='output.wav', help='Output WAV file path (default: output.wav)')
    parser.add_argument('--start', type=float, default=0.0, help='Start time in seconds (default: 0)')
    parser.add_argument('--end', type=float, default=None, help='End time in seconds (default: end of VCD)')
    parser.add_argument('--chunk-transitions', type=int, default=500000, help='Number of transitions per processing chunk')
    parser.add_argument('--profile', action='store_true', help='Enable profiling')
    parser.add_argument('--numba', action='store_true', help='Use numba for lowpass filter (requires numba)')
    args = parser.parse_args()

    if args.profile:
        pr = cProfile.Profile()
        pr.enable()

    print(f"Parsing VCD: {args.vcd}")

    # Check numba availability
    numba_available = False
    if args.numba:
        try:
            import numba
            numba_available = True
            print("Using numba-accelerated lowpass filter")
        except ImportError:
            print("Warning: numba not available, using pure Python lowpass filter", file=sys.stderr)

    # Apply lowpass filter at audio bandwidth BEFORE sampling (anti-aliasing)
    if args.no_lowpass:
        lowpass_enabled = False
    elif args.lowpass is None:
        args.lowpass = args.samplerate / 2.0
        lowpass_enabled = True
    else:
        lowpass_enabled = True

    if lowpass_enabled:
        nyquist = args.samplerate / 2.0
        if args.lowpass >= nyquist:
            print(f"Warning: lowpass cutoff ({args.lowpass} Hz) >= Nyquist ({nyquist} Hz). "
                  f"Setting to {nyquist * 0.9:.0f} Hz.", file=sys.stderr)
            args.lowpass = nyquist * 0.9

    # Streaming state
    left_lowpass_state = None
    right_lowpass_state = None
    left_samples = []
    right_samples = []
    max_time = 0
    total_transitions = 0

    # Transition buffers as numpy arrays (pre-allocate)
    left_buf = np.empty((args.chunk_transitions, 2), dtype=np.float64)
    right_buf = np.empty((args.chunk_transitions, 2), dtype=np.float64)
    left_buf_len = 0
    right_buf_len = 0

    # Open WAV file for chunked writing
    wav_file = wave.open(args.output, 'w')
    wav_file.setnchannels(2)
    wav_file.setsampwidth(1)
    wav_file.setframerate(args.samplerate)

    print(f"Streaming transitions (chunk size: {args.chunk_transitions})")

    # Two-pass approach: first extract target signal IDs from header
    t0 = time.perf_counter()
    print("Pass 1: extracting target signal IDs from VCD header...")
    t_header = time.perf_counter()
    target_ids, timescale = extract_target_ids(args.vcd, args.left, args.right)
    t_header_end = time.perf_counter()
    print(f"  Found {len(target_ids)} target signals in {t_header_end - t_header:.1f}s")

    if not target_ids:
        print("Error: no target signals found in VCD file.", file=sys.stderr)
        sys.exit(1)

    # Pass 2: parse data lines, only for target signals
    # Determine actual end time
    actual_end = args.end if args.end else None
    
    t_parse = time.perf_counter()
    for t, channel, value in parse_vcd_streaming(args.vcd, args.left, args.right, target_ids, timescale):
        # Stop processing once we've passed the end time
        if actual_end is not None and t > actual_end:
            break
            
        max_time = max(max_time, t)
        total_transitions += 1

        if channel == 0:
            if left_buf_len < args.chunk_transitions:
                left_buf[left_buf_len] = (t, value)
                left_buf_len += 1
            else:
                left_buf[left_buf_len] = (t, value)
                left_buf_len += 1
        else:
            if right_buf_len < args.chunk_transitions:
                right_buf[right_buf_len] = (t, value)
                right_buf_len += 1
            else:
                right_buf[right_buf_len] = (t, value)
                right_buf_len += 1

        # Process in chunks when either buffer is full
        if left_buf_len >= args.chunk_transitions or right_buf_len >= args.chunk_transitions:
            chunk_end = max(args.start, max(
                left_buf[:left_buf_len, 0].max() if left_buf_len > 0 else 0,
                right_buf[:right_buf_len, 0].max() if right_buf_len > 0 else 0,
            ))
            chunk_start = max(args.start, min(
                left_buf[0, 0] if left_buf_len > 0 else float('inf'),
                right_buf[0, 0] if right_buf_len > 0 else float('inf'),
            ))

            # Process left channel chunk
            if left_buf_len > 0:
                left_chunk = left_buf[:left_buf_len]
                left_filtered = lowpass_filter_chunked(left_chunk, left_lowpass_state, lowpass_enabled, args.lowpass)
                left_amps = sample_signal(left_filtered, chunk_start, actual_end if actual_end else chunk_end, args.samplerate)
                if args.cutoff:
                    left_amps = apply_highpass_filter_vectorized(left_amps, args.samplerate, args.cutoff)
                left_samples.extend(left_amps)
                if left_filtered is not None and len(left_filtered) > 0:
                    left_lowpass_state = (left_filtered[-1][0], left_filtered[-1][1])
                left_buf_len = 0

            # Process right channel chunk
            if right_buf_len > 0:
                right_chunk = right_buf[:right_buf_len]
                right_filtered = lowpass_filter_chunked(right_chunk, right_lowpass_state, lowpass_enabled, args.lowpass)
                right_amps = sample_signal(right_filtered, chunk_start, actual_end if actual_end else chunk_end, args.samplerate)
                if args.cutoff:
                    right_amps = apply_highpass_filter_vectorized(right_amps, args.samplerate, args.cutoff)
                right_samples.extend(right_amps)
                if right_filtered is not None and len(right_filtered) > 0:
                    right_lowpass_state = (right_filtered[-1][0], right_filtered[-1][1])
                right_buf_len = 0

            # Write both channels together
            if left_samples or right_samples:
                _write_wav_chunk(wav_file, left_samples, right_samples)
                left_samples.clear()
                right_samples.clear()

    t_parse_end = time.perf_counter()
    print(f"VCD parsing: {t_parse_end - t0:.1f}s ({total_transitions} transitions)")

    # Process remaining transitions
    remaining_start = max(args.start, min(
        left_buf[0, 0] if left_buf_len > 0 else float('inf'),
        right_buf[0, 0] if right_buf_len > 0 else float('inf'),
    ))

    if left_buf_len > 0:
        left_chunk = left_buf[:left_buf_len]
        left_filtered = lowpass_filter_chunked(left_chunk, left_lowpass_state, lowpass_enabled, args.lowpass)
        left_amps = sample_signal(left_filtered, remaining_start, actual_end if actual_end else max_time, args.samplerate)
        if args.cutoff:
            left_amps = apply_highpass_filter_vectorized(left_amps, args.samplerate, args.cutoff)
        left_samples.extend(left_amps)

    if right_buf_len > 0:
        right_chunk = right_buf[:right_buf_len]
        right_filtered = lowpass_filter_chunked(right_chunk, right_lowpass_state, lowpass_enabled, args.lowpass)
        right_amps = sample_signal(right_filtered, remaining_start, actual_end if actual_end else max_time, args.samplerate)
        if args.cutoff:
            right_amps = apply_highpass_filter_vectorized(right_amps, args.samplerate, args.cutoff)
        right_samples.extend(right_amps)

    # Write remaining samples
    if left_samples or right_samples:
        _write_wav_chunk(wav_file, left_samples, right_samples)

    wav_file.close()

    total_samples = len(left_samples) + len(right_samples)
    t_end = time.perf_counter()
    print(f"Wrote {args.output} ({total_samples} total samples, stereo)")
    print(f"Total transitions processed: {total_transitions}")
    print(f"Total time: {t_end - t0:.1f}s")

    if args.profile:
        pr.disable()
        s = io.StringIO()
        ps = pstats.Stats(pr, stream=s).sort_stats('cumulative')
        ps.print_stats(30)
        print(s.getvalue())


if __name__ == '__main__':
    main()
