"""Summit sound pack — procedurally generated, zero license obligation.

Adapted from Bloom's generate_princess_sounds.py (harp + music-box, C5 pentatonic)
to a masculine rustic voice: Karplus-Strong plucks tuned like a parlor guitar and
an additive "marimba" wood-bar preset, dropped an octave-plus into C3, through a
longer valley-style convolution reverb. The original 13 event names plus 9
one-off voices for the Blocky / Galaxy / Quest packs (22 files total).

Usage: python scripts/generate_summit_sounds.py [outdir] [name ...]
Default outdir: App/Resources/Sounds (overwrites the Bloom-era files).
Extra args filter to just those job names (e.g. "thud zap horn").
Requires: numpy, lameenc (pip install lameenc).
"""
import numpy as np
import os
import sys

import lameenc

SR = 44100
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join("App", "Resources", "Sounds")
STEP = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


def freq(name):
    p = STEP[name[0]]
    octave = int(name[1:])
    midi = 12 * (octave + 1) + p
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def pluck(f0, dur, decay=0.9975):
    """Karplus-Strong string, slightly slower damping than Bloom's harp so the
    low register rings like a parlor guitar."""
    n = max(2, int(round(SR / f0)))
    buf = list(np.random.uniform(-1.0, 1.0, n))
    out = np.empty(int(dur * SR))
    idx = 0
    for i in range(out.size):
        cur = buf[idx]
        nxt = buf[(idx + 1) % n]
        buf[idx] = decay * 0.5 * (cur + nxt)
        out[i] = cur
        idx = (idx + 1) % n
    t = np.arange(out.size) / SR
    out *= np.exp(-t / (dur * 0.6))
    a = int(0.004 * SR)
    out[:a] *= np.linspace(0, 1, a)
    return out


def bell(f0, dur, partials, amps, decays, attack):
    t = np.arange(int(dur * SR)) / SR
    sig = np.zeros_like(t)
    for r, a, d in zip(partials, amps, decays):
        sig += a * np.sin(2 * np.pi * f0 * r * t) * np.exp(-t / d)
    ar = max(1, int(attack * SR))
    sig[:ar] *= np.linspace(0, 1, ar)
    return sig


# Wood-bar partials (marimba-like): strong fundamental, sparse inharmonic
# overtones, fast decay = a warm knock rather than a sparkle.
MARIMBA = ([1.0, 3.9, 9.2], [1.0, 0.25, 0.08], [0.30, 0.14, 0.08], 0.002)
# Deeper log-drum knock for accents.
LOGDRUM = ([1.0, 2.7, 5.1], [1.0, 0.35, 0.10], [0.22, 0.10, 0.06], 0.003)


def voice(kind, note, dur, amp):
    f0 = freq(note)
    if kind == 'pluck':
        return pluck(f0, dur) * amp
    preset = MARIMBA if kind == 'marimba' else LOGDRUM
    return bell(f0, dur, *preset) * amp


def fftconv(a, b):
    n = a.size + b.size - 1
    N = 1 << int(np.ceil(np.log2(n)))
    y = np.fft.irfft(np.fft.rfft(a, N) * np.fft.rfft(b, N), N)
    return y[:n]


def reverb(sig, wet, decay):
    L = int(decay * SR)
    ir = np.random.randn(L) * np.exp(-np.arange(L) / (decay * SR / 5.0))
    w = fftconv(sig, ir)
    w /= (np.max(np.abs(w)) + 1e-9)
    out = np.zeros(max(sig.size, w.size))
    out[:sig.size] += (1.0 - wet) * sig
    out[:w.size] += wet * w
    return out


def finish(sig):
    # Trim leading silence/near-silence so playback starts on the transient
    # instead of a soft ramp-in (perceived latency). Keep a ~0.5ms pre-roll
    # so the cut itself isn't an audible click.
    peak = np.max(np.abs(sig))
    if peak > 1e-9:
        onset = np.where(np.abs(sig) > 0.005 * peak)[0]
        if onset.size:
            sig = sig[max(0, onset[0] - 22):]
    sig = np.tanh(sig * 1.1)
    sig /= (np.max(np.abs(sig)) + 1e-9)
    sig *= 0.89
    thr = 0.0015
    nz = np.where(np.abs(sig) > thr)[0]
    if nz.size:
        end = min(sig.size, nz[-1] + int(0.06 * SR))
        sig = sig[:end]
    out = int(0.012 * SR)
    if sig.size > out:
        sig[-out:] *= np.linspace(1, 0, out)
    return sig


def render(events, wet, decay, span):
    buf = np.zeros(int(span * SR))
    for start, kind, note, amp, dur in events:
        v = voice(kind, note, dur, amp)
        s = int(start * SR)
        e = min(buf.size, s + v.size)
        buf[s:e] += v[:e - s]
    return finish(reverb(buf, wet, decay))


def write_mp3(path, sig):
    data = (np.clip(sig, -1, 1) * 32767).astype(np.int16)
    enc = lameenc.Encoder()
    enc.set_bit_rate(128)
    enc.set_in_sample_rate(SR)
    enc.set_channels(1)
    enc.set_quality(2)
    mp3 = enc.encode(data.tobytes()) + enc.flush()
    with open(path, 'wb') as f:
        f.write(mp3)


# Low pentatonic (C3 D3 E3 G3 A3) — same harmonized-any-order idea as Bloom,
# an octave-plus down so the taps knock instead of twinkle.
PENTA = ['C3', 'D3', 'E3', 'G3', 'A3']

JOBS = {}
for i, nm in enumerate(PENTA, 1):
    JOBS['tap%d' % i] = ([(0.0, 'marimba', nm, 0.9, 0.4)], 0.14, 0.8, 1.1)

JOBS['operator'] = ([(0.0, 'logdrum', 'C3', 0.6, 0.45), (0.0, 'marimba', 'G3', 0.4, 0.45)], 0.15, 0.8, 1.1)
JOBS['equals'] = ([(0.0, 'pluck', 'C3', 0.85, 1.0), (0.09, 'pluck', 'E3', 0.85, 1.0), (0.18, 'pluck', 'G3', 0.85, 1.1)], 0.24, 1.3, 2.4)
JOBS['clear'] = ([(0.0, 'pluck', 'E3', 0.75, 0.9), (0.1, 'pluck', 'C3', 0.75, 0.95)], 0.2, 1.1, 2.0)
JOBS['success'] = ([(0.0, 'pluck', 'C3', 0.8, 1.1), (0.08, 'pluck', 'E3', 0.8, 1.1), (0.16, 'pluck', 'G3', 0.8, 1.1), (0.3, 'marimba', 'C4', 0.6, 0.7), (0.4, 'marimba', 'G4', 0.4, 0.6)], 0.28, 1.6, 3.0)
JOBS['error'] = ([(0.0, 'pluck', 'A2', 0.6, 1.0), (0.14, 'pluck', 'F2', 0.6, 1.05)], 0.2, 1.2, 2.2)
JOBS['modeswitch'] = ([(0.0, 'marimba', 'G3', 0.6, 0.4), (0.07, 'marimba', 'C4', 0.6, 0.45)], 0.2, 1.0, 1.6)
JOBS['easteregg'] = ([(0.0, 'pluck', 'G3', 0.45, 1.1), (0.0, 'marimba', 'C4', 0.55, 0.6), (0.07, 'marimba', 'E4', 0.55, 0.6), (0.14, 'marimba', 'G4', 0.55, 0.6), (0.21, 'marimba', 'C5', 0.5, 0.6)], 0.3, 1.5, 2.7)
JOBS['startup'] = ([(0.0, 'pluck', 'C2', 0.5, 2.0), (0.0, 'pluck', 'C3', 0.7, 1.3), (0.22, 'pluck', 'E3', 0.7, 1.3), (0.44, 'pluck', 'G3', 0.7, 1.3), (0.66, 'pluck', 'A3', 0.7, 1.3), (0.88, 'pluck', 'C4', 0.75, 1.5)], 0.3, 1.9, 3.6)


# --- 9 one-off voices (Blocky / Galaxy / Quest packs) -----------------------
# Builders return the DRY signal; main() runs them through the same
# finish(reverb(...)) chain as render(). Each gets its own fixed seed so a
# filtered regeneration is byte-identical to a full run.

def mix(parts):
    """Sum (start_sec, signal) parts into one buffer."""
    buf = np.zeros(max(int(s * SR) + v.size for s, v in parts))
    for s, v in parts:
        i = int(s * SR)
        buf[i:i + v.size] += v
    return buf


def knock(f_hi, f_lo, drop, tau, total, noise_amp, noise_dur):
    """Sine knock: exponential pitch drop f_hi->f_lo over `drop` seconds (then
    held), exponential amp decay (tau), plus a short lowpassed white-noise
    attack transient layered on top."""
    t = np.arange(int(total * SR)) / SR
    f = f_hi * (f_lo / f_hi) ** np.minimum(t / drop, 1.0)
    sig = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / tau)
    n = int(noise_dur * SR)
    noise = np.convolve(np.random.uniform(-1, 1, n), np.ones(16) / 16.0, mode='same')
    sig[:n] += noise * np.linspace(1, 0, n) * noise_amp
    return sig


def chirp(f_hi, f_lo, dur, tau, harm):
    """Descending exponential frequency chirp; harm = per-harmonic amplitudes
    [h1, h2, ...] (odd-only ~ square-ish, 1/n ladder ~ saw-like)."""
    t = np.arange(int(dur * SR)) / SR
    f = f_hi * (f_lo / f_hi) ** (t / dur)
    phase = 2 * np.pi * np.cumsum(f) / SR
    sig = np.zeros_like(t)
    for i, a in enumerate(harm, 1):
        if a:
            sig += a * np.sin(i * phase)
    return sig * np.exp(-t / tau)


def warp_rise():
    """Rising 180->720 Hz sweep, soft 5th-harmonic shimmer, swell envelope
    (slow attack, soft release). Reads as "engage"."""
    dur = 0.38
    t = np.arange(int(dur * SR)) / SR
    f = 180.0 * (720.0 / 180.0) ** (t / dur)
    phase = 2 * np.pi * np.cumsum(f) / SR
    sig = np.sin(phase) + 0.15 * np.sin(5 * phase)
    return sig * np.clip(t / 0.15, 0, 1) * np.clip((dur - t) / 0.12, 0, 1)


def horn_swell():
    """Noble C3+G3 swell: three decreasing harmonics per note, each note
    doubled with a slight detune for slow beating; ~120ms attack, ~200ms
    sustain, ~260ms release."""
    dur = 0.58
    t = np.arange(int(dur * SR)) / SR
    sig = np.zeros_like(t)
    for f0 in (freq('C3'), freq('G3')):
        for det in (1.0, 1.004):
            for h, a in ((1, 1.0), (2, 0.5), (3, 0.25)):
                sig += a * 0.5 * np.sin(2 * np.pi * f0 * det * h * t)
    return sig * np.clip(t / 0.12, 0, 1) * np.clip((dur - t) / 0.26, 0, 1)


NEW = {
    'thud': (lambda: knock(170, 85, 0.10, 0.035, 0.14, 0.5, 0.015), 0.05, 0.35),
    'thok': (lambda: knock(260, 140, 0.08, 0.028, 0.11, 0.5, 0.012), 0.05, 0.3),
    'ding': (lambda: mix([(0.0, bell(freq('E5'), 0.5, *MARIMBA) * 0.8),
                          (0.08, bell(freq('B5'), 0.5, *MARIMBA) * 0.8)]), 0.18, 0.9),
    'zap': (lambda: chirp(1600, 220, 0.12, 0.045, [1.0, 0, 0.2, 0, 0.1]), 0.06, 0.3),
    'pew': (lambda: chirp(900, 140, 0.16, 0.06, [1.0, 0.5, 0.33, 0.25]), 0.08, 0.35),
    'warp': (warp_rise, 0.15, 0.8),
    'harp': (lambda: pluck(freq('E4'), 0.8, decay=0.996) * 0.9, 0.15, 0.9),
    'drum': (lambda: knock(130, 55, 0.22, 0.09, 0.5, 0.4, 0.008), 0.12, 0.5),
    'horn': (horn_swell, 0.22, 1.2),
}


def main():
    np.random.seed(7)
    os.makedirs(OUT, exist_ok=True)
    only = set(sys.argv[2:])  # optional job-name filter: regenerate just these
    wrote = 0
    for name, (events, wet, decay, span) in JOBS.items():
        if only and name not in only:
            continue
        sig = render(events, wet, decay, span)
        path = os.path.join(OUT, name + '.mp3')
        write_mp3(path, sig)
        print(name + '.mp3', os.path.getsize(path))
        wrote += 1
    for i, (name, (build, wet, decay)) in enumerate(NEW.items()):
        if only and name not in only:
            continue
        np.random.seed(100 + i)  # per-job seed: stable bytes regardless of filter
        sig = finish(reverb(build(), wet, decay))
        path = os.path.join(OUT, name + '.mp3')
        write_mp3(path, sig)
        print(name + '.mp3', os.path.getsize(path))
        wrote += 1
    print('wrote %d files to %s' % (wrote, OUT))


if __name__ == '__main__':
    main()
