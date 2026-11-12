"""Generates simple, original starter sound effects into assets/sounds/.

Run from the project folder:  python3 tools/make_sounds.py
Only uses the Python standard library. Replace any .wav later with your own
file of the same name.
"""
import math
import os
import random
import struct
import wave

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")


def tone(freq_start, freq_end, dur, wave_type="sine", volume=0.5, decay=6.0, attack=0.005):
    samples = []
    n = int(RATE * dur)
    phase = 0.0
    for i in range(n):
        t = i / RATE
        k = i / n
        freq = freq_start + (freq_end - freq_start) * k
        phase += 2 * math.pi * freq / RATE
        if wave_type == "sine":
            v = math.sin(phase) + 0.3 * math.sin(phase * 2)
        elif wave_type == "triangle":
            v = 2 / math.pi * math.asin(math.sin(phase))
        elif wave_type == "square":
            v = 0.6 if math.sin(phase) >= 0 else -0.6
        else:  # noise
            v = random.uniform(-1, 1)
        env = min(1.0, t / attack) * math.exp(-decay * k)
        samples.append(v * env * volume)
    return samples


def silence(dur):
    return [0.0] * int(RATE * dur)


def mix(*tracks):
    length = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(length)]


def notes(freqs, step, dur, **kw):
    out = []
    for i, f in enumerate(freqs):
        out = mix(out or [0.0], silence(step * i) + tone(f, f, dur, **kw))
    return out


def save(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = min(1.0, 0.9 / peak)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(s * gain * 32767)) for s in samples))
    print("wrote", path)


random.seed(7)
C5, E5, G5, C6, E6, G6 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0

save("pick", tone(600, 900, 0.07, volume=0.35, decay=5))
save("place", mix(tone(220, 120, 0.12, volume=0.6, decay=5),
                  tone(0, 0, 0.03, "noise", volume=0.15, decay=8)))
save("invalid", tone(320, 200, 0.14, "triangle", volume=0.4, decay=4))
save("clear", notes([C6, E6, G6], 0.05, 0.3, volume=0.35, decay=5))
save("new_best", notes([C5, E5, G5, C6], 0.09, 0.45, wave_type="triangle", volume=0.4, decay=4))
save("game_over", notes([G5 / 2, E5 / 2, C5 / 2], 0.18, 0.5, wave_type="triangle", volume=0.45, decay=3))
save("click", tone(1200, 900, 0.035, volume=0.3, decay=6))
