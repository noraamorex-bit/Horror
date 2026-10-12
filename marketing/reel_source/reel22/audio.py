# Reel 22 — "AMAZING NEW ROBLOX HORROR GAME TO PLAY WITH YOUR FRIENDS": an original upbeat track, all
# synthesized here (no samples). 128 BPM, A minor (Am - F - C - G), 14 bars = 26.25 s:
# bars 1-2 intro (filtered chords + riser), the drop on bar 3 (four-on-the-floor kick, claps, offbeat
# hats, pumping bass and supersaw stabs, a pluck hook), bars 13-14 the end card. Writes reel_audio.wav.
import numpy as np, wave, math

SR = 48000
BPM = 128
BEAT = 60 / BPM
BAR = BEAT * 4
BARS = 14
DUR = BARS * BAR
N = int(SR * DUR)
rng = np.random.default_rng(7)
# two buses: drums, and everything melodic (which ducks under the kick)
BUS = {"d": [np.zeros(N), np.zeros(N)], "m": [np.zeros(N), np.zeros(N)]}

def tt(d): return np.arange(int(SR * d)) / SR
def noise(d): return rng.standard_normal(int(SR * d))
def midi(n): return 440.0 * 2 ** ((n - 69) / 12)

def filt(x, lo=None, hi=None, order=2):
    n = len(x)
    if n == 0: return x
    X = np.fft.rfft(x); f = np.fft.rfftfreq(n, 1 / SR); g = np.ones_like(f)
    if hi: g *= 1 / np.sqrt(1 + (f / hi) ** (2 * order))
    if lo: g *= 1 / np.sqrt(1 + (lo / np.maximum(f, 1e-3)) ** (2 * order))
    return np.fft.irfft(X * g, n)

def put(sig, t, gain=1.0, pan=0.0, bus="m"):
    i = int(t * SR)
    if i >= N: return
    s = sig[: N - i] * gain
    l = math.cos((pan + 1) * math.pi / 4); r = math.sin((pan + 1) * math.pi / 4)
    B = BUS[bus]
    B[0][i:i + len(s)] += s * l * 1.414; B[1][i:i + len(s)] += s * r * 1.414

def saw(f, d, phase=0.0):
    t = tt(d); x = (f * t + phase) % 1.0
    return 2 * x - 1

DROP = 2 * BAR                       # the drop: bar 3
END = 12 * BAR                       # the end card: bar 13

# ---------------------------------------------------------------- drums
def kick():
    t = tt(0.42)
    f = 46 + 120 * np.exp(-t * 32)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 7.5)
    s += 0.25 * filt(noise(0.42), lo=3000) * np.exp(-t * 180)
    return np.tanh(2.2 * s)

def clap():
    d = 0.32; t = tt(d); n = filt(noise(d), lo=900, hi=7000)
    e = np.zeros_like(t)
    for k, off in enumerate((0, 0.011, 0.022)):
        e += np.where(t >= off, np.exp(-(t - off) * (90 if k < 2 else 16)), 0)
    return n * e * 0.9

def hat(open_=False):
    d = 0.22 if open_ else 0.06; t = tt(d)
    return filt(noise(d), lo=7000) * np.exp(-t * (14 if open_ else 70)) * 0.5

# ---------------------------------------------------------------- tones
PROG = [(57, [57, 60, 64]), (53, [53, 57, 60]), (48, [48, 52, 55]), (55, [55, 59, 62])]   # Am F C G (root, triad)

def supersaw(notes, d, cutoff):
    out = np.zeros(int(SR * d))
    for n in notes:
        for det in (-0.12, -0.05, 0, 0.05, 0.12):
            out += saw(midi(n + 12) * 2 ** (det / 12), d, phase=rng.random())
    out = filt(out / (len(notes) * 5), hi=cutoff)
    t = tt(d)
    return out * np.minimum(1, t / 0.005) * np.exp(-t * 6)

def bass(n, d):
    t = tt(d); f = midi(n - 12)
    s = 0.7 * np.sin(2 * np.pi * f * t) + 0.35 * filt(saw(f, d), hi=900)
    return np.tanh(1.6 * s) * np.minimum(1, t / 0.004) * np.exp(-t * 5)

def pluck(n, d=0.35):
    t = tt(d); f = midi(n)
    s = saw(f, d) * 0.6 + np.sign(np.sin(2 * np.pi * f * 2 * t)) * 0.15
    s = filt(s, hi=4200)
    return s * np.exp(-t * 11) * np.minimum(1, t / 0.002)

def riser(d):
    t = tt(d); k = t / d
    s = filt(noise(d), lo=800, hi=9000) * k ** 2 * 0.35
    s += 0.2 * np.sin(2 * np.pi * np.cumsum(200 + 1400 * k ** 2) / SR) * k ** 2
    return s

def impact():
    t = tt(1.6)
    s = np.sin(2 * np.pi * np.cumsum(30 + 90 * np.exp(-t * 9)) / SR) * np.exp(-t * 2.2)
    s += 0.5 * filt(noise(1.6), hi=2500) * np.exp(-t * 4)
    return np.tanh(1.8 * s)

# the hook melody (A minor pentatonic-ish), one note per 8th, over two bars
HOOK = [69, 72, 76, 74, 72, 69, 72, 74,   76, 79, 76, 74, 72, 74, 72, 67]

# ---------------------------------------------------------------- arrangement
duck = np.ones(N)                    # sidechain: everything melodic ducks under the kick
for bar in range(BARS):
    t0 = bar * BAR
    root, triad = PROG[bar % 4]
    main = DROP <= t0 < END + 2 * BAR
    for b in range(4):
        tb = t0 + b * BEAT
        if main:
            put(kick(), tb, 1.0, bus="d")
            i = int(tb * SR); n = int(0.18 * SR)
            if i < N:
                seg = min(n, N - i)
                duck[i:i + seg] = np.minimum(duck[i:i + seg], 0.2 + 0.8 * np.linspace(0, 1, seg) ** 0.7)
            if b in (1, 3):
                put(clap(), tb, 0.6, bus="d")
            put(hat(), tb + BEAT / 2, 0.45, pan=0.2, bus="d")
            put(hat(), tb + BEAT / 4, 0.16, pan=-0.2, bus="d")
            put(hat(), tb + 3 * BEAT / 4, 0.16, pan=-0.2, bus="d")
            if b == 3:
                put(hat(True), tb + BEAT / 2, 0.3, pan=0.3, bus="d")
        # bass and chord stabs on the offbeats
        if main:
            put(bass(root, BEAT / 2), tb + BEAT / 2, 0.55)
        cutoff = 1200 + 3800 * min(1, t0 / DROP) if not main else 6500
        put(supersaw(triad, BEAT / 2, cutoff), tb + BEAT / 2, 0.3 if main else 0.3, pan=-0.15)
        put(supersaw(triad, BEAT / 2, cutoff), tb + BEAT / 2 + 0.012, 0.3 if main else 0.3, pan=0.15)
    # the hook, from the drop on (every other 2 bars it answers an octave up)
    if main and t0 < END:
        k = (bar - 2) % 2
        up = 12 if ((bar - 2) // 4) % 2 == 1 else 0
        for j in range(8):
            put(pluck(HOOK[k * 8 + j] + up), t0 + j * BEAT / 2, 0.32, pan=0.25 if j % 2 else -0.25)

# intro: a riser into the drop, an impact on it; a last hit on the end card
put(riser(DROP - 0.1), 0.05, 1.0)
put(impact(), DROP, 0.9, bus="d")
put(impact(), END, 0.6, bus="d")
L = BUS["d"][0] + BUS["m"][0] * duck
R = BUS["d"][1] + BUS["m"][1] * duck
L = np.tanh(L * 1.1) / np.tanh(1.1); R = np.tanh(R * 1.1) / np.tanh(1.1)
peak = max(np.max(np.abs(L)), np.max(np.abs(R)))
L *= 0.92 / peak; R *= 0.92 / peak
fade = np.interp(np.arange(N) / SR, [0, DUR - 0.6, DUR], [1, 1, 0])
L *= fade; R *= fade
data = (np.stack([L, R], 1) * 32767).astype(np.int16)
with wave.open("reel_audio.wav", "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
print("wrote reel_audio.wav", round(DUR, 2), "s; drop at", round(DROP, 3), "end card at", round(END, 3))
