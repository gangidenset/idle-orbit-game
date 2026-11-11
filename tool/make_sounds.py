"""Synthesises the game's sound effects into assets/audio/*.wav.
Run: python3 tool/make_sounds.py   (stdlib only, so sounds are license-free)"""
import math, random, struct, wave

RATE = 22050


def write(name, samples, gain=0.5):
    peak = max(1e-9, max(abs(s) for s in samples))
    with wave.open(f'assets/audio/{name}.wav', 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(s / peak * gain * 32767)) for s in samples))


def tone(freq, dur, attack=0.005, decay=None, shape='sine', vib=0.0):
    n = int(RATE * dur); out = []
    decay = decay or dur
    for i in range(n):
        t = i / RATE
        f = freq * (1 + vib * math.sin(2 * math.pi * 6 * t))
        ph = 2 * math.pi * f * t
        v = math.sin(ph) if shape == 'sine' else (0.6 * math.sin(ph) + 0.25 * math.sin(2 * ph) + 0.15 * math.sin(3 * ph))
        env = min(1.0, t / attack) * math.exp(-t / decay * 4)
        out.append(v * env)
    return out


def mix(*tracks):
    n = max(len(t) for t, _ in tracks); out = [0.0] * n
    for tr, off in tracks:
        o = int(off * RATE)
        for i, s in enumerate(tr):
            if o + i < n: out[o + i] += s
            else: out.append(s)
    return out


# Upgrade: short soft "plip" rising
up = [s for s in tone(880, 0.09, decay=0.08)]
up = mix((up, 0), (tone(1320, 0.08, decay=0.06), 0.03))
write('upgrade', up, 0.35)

# Reward: bright two-note chime
write('reward', mix((tone(1046.5, 0.5, shape='bell', decay=0.4), 0),
                    (tone(1568.0, 0.6, shape='bell', decay=0.5), 0.09)), 0.45)

# Planet unlock: rising arpeggio fanfare (C E G C')
notes = [523.25, 659.25, 783.99, 1046.5]
write('unlock', mix(*[(tone(f, 1.0 if i == 3 else 0.35, shape='bell', decay=0.9 if i == 3 else 0.3, vib=0.004), i * 0.11)
                      for i, f in enumerate(notes)]), 0.5)

# Warp (prestige): filtered noise sweep + low tone
rnd = random.Random(1); n = int(RATE * 1.3); prev = 0.0; sweep = []
for i in range(n):
    t = i / RATE; a = 0.02 + 0.5 * (t / 1.3)  # opening low-pass
    prev += a * (rnd.uniform(-1, 1) - prev)
    sweep.append(prev * math.sin(math.pi * t / 1.3))
write('warp', mix((sweep, 0), (tone(110, 1.2, attack=0.3, decay=1.0), 0)), 0.5)
# Evolution: quick rising sweep into a bright major chord (shorter than unlock)
n = int(RATE * 0.25); sweep2 = []
for i in range(n):
    t = i / RATE; f = 400 + 1400 * (t / 0.25) ** 1.5
    sweep2.append(math.sin(2 * math.pi * f * t) * (t / 0.25) * 0.5)
chord = mix((tone(1046.5, 0.7, shape='bell', decay=0.6), 0), (tone(1318.5, 0.7, shape='bell', decay=0.6), 0.03),
            (tone(1568.0, 0.8, shape='bell', decay=0.7, vib=0.003), 0.06))
write('evolve', mix((sweep2, 0), (chord, 0.22)), 0.45)
print('ok')
