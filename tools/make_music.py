"""Generates original, seamlessly looping background music for each theme.

Run from the project folder:  python3 tools/make_music.py
Pure Python (no numpy). Writes assets/sounds/music_<theme>.wav
(mono, 22.05 kHz, 8 bars). Replace any file with your own track of the
same name (.wav / .ogg / .mp3) to use it instead.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")
TAU = 2 * math.pi


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


NOTE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def n(name):
    """'A3' -> midi number, 'F#4' -> midi number."""
    base = NOTE[name[0]]
    rest = name[1:]
    if rest.startswith("#"):
        base += 1
        rest = rest[1:]
    elif rest.startswith("b"):
        base -= 1
        rest = rest[1:]
    return 12 * (int(rest) + 1) + base


class Track:
    def __init__(self, bpm, bars):
        self.beat = 60.0 / bpm
        self.length = int(RATE * self.beat * 4 * bars)
        self.buf = [0.0] * self.length

    def at(self, beat):
        return int(beat * self.beat * RATE)

    def add(self, start_beat, samples, gain=1.0):
        """Mix samples in; tails past the end wrap to the start (seamless loop)."""
        i0 = self.at(start_beat)
        L = self.length
        buf = self.buf
        for i, s in enumerate(samples):
            buf[(i0 + i) % L] += s * gain

    def save(self, name, target_rms=0.16, max_peak=0.95):
        # Same perceived loudness for every track (RMS), without clipping.
        peak = max(1e-9, max(abs(s) for s in self.buf))
        rms = max(1e-9, math.sqrt(sum(s * s for s in self.buf) / len(self.buf)))
        g = min(target_rms / rms, max_peak / peak)
        os.makedirs(OUT, exist_ok=True)
        path = os.path.join(OUT, name + ".wav")
        with wave.open(path, "w") as f:
            f.setnchannels(1)
            f.setsampwidth(2)
            f.setframerate(RATE)
            f.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * g)) * 32767)) for s in self.buf))
        print("wrote", os.path.normpath(path), "%.1fs" % (self.length / RATE))


# --- instruments (return lists of samples) ------------------------------------

def env(i, total, attack, release):
    a = min(1.0, i / max(1, attack))
    r = min(1.0, (total - i) / max(1, release))
    return a * r


def osc(freq, dur, shape="sine", attack=0.01, release=0.05, decay=0.0, detune=0.0, harmonics=6):
    total = int(dur * RATE)
    at, rl = int(attack * RATE), int(release * RATE)
    out = []
    ph = ph2 = 0.0
    step = TAU * freq / RATE
    step2 = TAU * freq * (1 + detune) / RATE
    for i in range(total):
        ph += step
        ph2 += step2
        if shape == "sine":
            v = math.sin(ph)
        elif shape == "tri":
            v = 2 / math.pi * math.asin(math.sin(ph))
        elif shape == "saw":
            v = sum(math.sin(ph * k) / k for k in range(1, harmonics + 1)) * 0.6
            if detune:
                v += sum(math.sin(ph2 * k) / k for k in range(1, harmonics + 1)) * 0.6
                v *= 0.5
        elif shape == "square":
            v = sum(math.sin(ph * k) / k for k in range(1, harmonics * 2, 2)) * 0.8
        else:
            v = 0.0
        e = env(i, total, at, rl)
        if decay:
            e *= math.exp(-decay * i / RATE)
        out.append(v * e)
    return out


def pluck(freq, dur, bright=0.5, seed=0):
    """Karplus-Strong plucked string."""
    rnd = random.Random(seed)
    period = max(2, int(RATE / freq))
    buf = [rnd.uniform(-1, 1) for _ in range(period)]
    out = []
    total = int(dur * RATE)
    damp = 0.996 - (1 - bright) * 0.01
    for i in range(total):
        j = i % period
        s = buf[j]
        out.append(s)
        buf[j] = damp * 0.5 * (s + buf[(j + 1) % period])
    fade = int(0.03 * RATE)
    for i in range(min(fade, total)):
        out[total - 1 - i] *= i / fade
    return out


def bell(freq, dur):
    total = int(dur * RATE)
    out = []
    for i in range(total):
        t = i / RATE
        v = (math.sin(TAU * freq * t) + 0.5 * math.sin(TAU * freq * 2.76 * t) * math.exp(-6 * t)
             + 0.25 * math.sin(TAU * freq * 5.4 * t) * math.exp(-10 * t))
        out.append(v * math.exp(-3.2 * t) * min(1, i / 40))
    return out


def kick(dur=0.3):
    out, ph = [], 0.0
    for i in range(int(dur * RATE)):
        t = i / RATE
        ph += TAU * (45 + 90 * math.exp(-30 * t)) / RATE
        out.append(math.sin(ph) * math.exp(-9 * t))
    return out


def noise_hit(dur, decay, seed, tone=0.0, tone_freq=200):
    rnd = random.Random(seed)
    out, prev = [], 0.0
    for i in range(int(dur * RATE)):
        t = i / RATE
        x = rnd.uniform(-1, 1)
        hp = x - prev  # crude high-pass for hats
        prev = x
        v = hp * 0.5 + tone * math.sin(TAU * tone_freq * t)
        out.append(v * math.exp(-decay * t))
    return out


def chord_notes(root, kind):
    steps = {"min": [0, 3, 7], "maj": [0, 4, 7], "maj7": [0, 4, 7, 11], "min7": [0, 3, 7, 10], "6": [0, 4, 7, 9]}
    return [root + s for s in steps[kind]]


# --- songs -------------------------------------------------------------------------

def neon():
    t = Track(bpm=108, bars=8)
    prog = [(n("A2"), "min"), (n("F2"), "maj"), (n("C3"), "maj"), (n("G2"), "maj")] * 2
    hat = noise_hit(0.05, 60, 1)
    snare = noise_hit(0.18, 22, 2, tone=0.3, tone_freq=190)
    k = kick()
    for bar, (root, kind) in enumerate(prog):
        b0 = bar * 4
        notes = chord_notes(root, kind)
        # bass: driving 8ths
        for e in range(8):
            t.add(b0 + e * 0.5, osc(midi(root), t.beat * 0.45, "saw", 0.005, 0.03, decay=3, harmonics=5), 0.32)
        # pad
        for m in notes:
            t.add(b0, osc(midi(m + 12), t.beat * 4, "saw", 0.4, 0.4, detune=0.004, harmonics=4), 0.07)
        # arpeggio 16ths
        arp = [notes[0] + 24, notes[1] + 24, notes[2] + 24, notes[1] + 24]
        for s in range(16):
            t.add(b0 + s * 0.25, osc(midi(arp[s % 4]), t.beat * 0.22, "square", 0.003, 0.04, decay=6, harmonics=3), 0.07)
        # drums
        for beat in range(4):
            if beat in (0, 2):
                t.add(b0 + beat, k, 0.55)
            else:
                t.add(b0 + beat, snare, 0.22)
            t.add(b0 + beat + 0.5, hat, 0.12)
    t.save("music_neon")


def candy():
    t = Track(bpm=122, bars=8)
    prog = [(n("C3"), "maj"), (n("G2"), "maj"), (n("A2"), "min"), (n("F2"), "maj")] * 2
    rnd = random.Random(7)
    scale = [n("C5"), n("D5"), n("E5"), n("G5"), n("A5"), n("C6")]
    clap = noise_hit(0.12, 30, 3)
    for bar, (root, kind) in enumerate(prog):
        b0 = bar * 4
        notes = chord_notes(root, kind)
        for beat in range(4):
            t.add(b0 + beat, osc(midi(root), t.beat * 0.8, "sine", 0.005, 0.1, decay=2), 0.4)
            # offbeat ukulele-like chord
            for j, m in enumerate(notes):
                t.add(b0 + beat + 0.5 + j * 0.01, pluck(midi(m + 12), t.beat * 0.5, 0.6, seed=bar * 10 + beat + j), 0.12)
            if beat in (1, 3):
                t.add(b0 + beat, clap, 0.12)
        # bouncy bell melody
        pattern = [0, 1, 1.5, 2, 3] if bar % 2 == 0 else [0, 0.5, 1, 2.5, 3]
        for p in pattern:
            t.add(b0 + p, bell(midi(rnd.choice(scale)), t.beat * 1.2), 0.11)
    t.save("music_candy")


def gems():
    t = Track(bpm=80, bars=8)
    prog = [(n("D3"), "maj7"), (n("B2"), "min7"), (n("G2"), "maj7"), (n("A2"), "6")] * 2
    rnd = random.Random(11)
    for bar, (root, kind) in enumerate(prog):
        b0 = bar * 4
        notes = chord_notes(root, kind)
        t.add(b0, osc(midi(root - 12), t.beat * 4, "sine", 0.3, 0.6), 0.35)
        for m in notes:
            t.add(b0, osc(midi(m + 12), t.beat * 4.2, "tri", 1.2, 1.2, detune=0.003), 0.08)
        # sparse sparkling bells from the chord
        for s in range(8):
            if rnd.random() < 0.55:
                m = rnd.choice(notes) + rnd.choice([24, 36])
                t.add(b0 + s * 0.5, bell(midi(m), t.beat * 3), 0.07)
    t.save("music_gems")


def nature():
    t = Track(bpm=92, bars=8)
    prog = [(n("G2"), "maj"), (n("E2"), "min"), (n("C3"), "maj"), (n("D3"), "maj")] * 2
    rnd = random.Random(5)
    penta = [n("G4"), n("A4"), n("B4"), n("D5"), n("E5"), n("G5")]
    shaker = noise_hit(0.07, 40, 9)
    for bar, (root, kind) in enumerate(prog):
        b0 = bar * 4
        notes = chord_notes(root, kind)
        arp = [notes[0], notes[1] + 12, notes[2] + 12, notes[0] + 12, notes[2] + 12, notes[1] + 12]
        for s in range(8):
            m = arp[s % len(arp)]
            t.add(b0 + s * 0.5, pluck(midi(m + 12), t.beat * 1.2, 0.45, seed=bar * 20 + s), 0.18)
            t.add(b0 + s * 0.5 + 0.25, shaker, 0.04)
        t.add(b0, pluck(midi(root), t.beat * 3, 0.3, seed=99 + bar), 0.3)
        # gentle flute melody (sine with vibrato via slight detune) on even bars
        if bar % 2 == 0:
            pos = 0.0
            for length in (1.5, 0.5, 1.0, 1.0):
                f = midi(rnd.choice(penta))
                t.add(b0 + pos, osc(f, t.beat * length * 0.95, "sine", 0.08, 0.15, detune=0.004), 0.1)
                pos += length
    t.save("music_nature")


if __name__ == "__main__":
    neon()
    candy()
    gems()
    nature()
