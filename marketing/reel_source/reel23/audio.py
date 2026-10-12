# Reel 23 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS": an original dark phonk/trap beat (all
# synthesized here, no samples) for the slow first-person format: loud from the first frame like a
# trending song. 112 BPM, E Phrygian: a distorted 808 with slides, a low pitched cowbell riff, trap hats
# with rolls, a half-time clap, a dark pad and vinyl crackle. Bar 5 (8.57 s) is the jumpscare: half a
# beat of silence, then a huge hit. Bar 9 is the end card. 9 bars = 19.29 s. Writes reel_audio.wav.
import numpy as np, wave, math

SR = 48000
BPM = 112
BEAT = 60 / BPM
BAR = BEAT * 4
BARS = 9
DUR = BARS * BAR
N = int(SR * DUR)
rng = np.random.default_rng(11)
BUS = {"d": [np.zeros(N), np.zeros(N)], "m": [np.zeros(N), np.zeros(N)], "fx": [np.zeros(N), np.zeros(N)]}

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
    if i >= N or i < 0: return
    s = sig[: N - i] * gain
    l = math.cos((pan + 1) * math.pi / 4); r = math.sin((pan + 1) * math.pi / 4)
    B = BUS[bus]
    B[0][i:i + len(s)] += s * l * 1.414; B[1][i:i + len(s)] += s * r * 1.414

SCARE = 4 * BAR          # 8.57 s
END = 8 * BAR            # 17.14 s
def muted(t):            # the half beat of silence before the scare
    return SCARE - BEAT / 2 <= t < SCARE

# ---------------------------------------------------------------- drums
def kick():
    t = tt(0.3)
    f = 50 + 140 * np.exp(-t * 40)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 14)
    s += 0.3 * filt(noise(0.3), lo=2500) * np.exp(-t * 200)
    return np.tanh(2.5 * s)

def clap():
    d = 0.45; t = tt(d); n = filt(noise(d), lo=700, hi=6000)
    e = np.zeros_like(t)
    for k, off in enumerate((0, 0.009, 0.019, 0.03)):
        e += np.where(t >= off, np.exp(-(t - off) * (110 if k < 3 else 9)), 0)
    return np.tanh(1.5 * n * e) * 0.9

def hat(d=0.045):
    t = tt(d)
    return filt(noise(d), lo=7000, hi=12000) * np.exp(-t * 90) * 0.5

# ---------------------------------------------------------------- 808 (distorted, with slides)
def bass808(n, d, slide_from=None):
    t = tt(d)
    f1 = midi(n)
    f = np.full_like(t, f1)
    if slide_from is not None:
        f0 = midi(slide_from)
        f = f1 + (f0 - f1) * np.exp(-t * 18)
    ph = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(ph) + 0.15 * np.sin(2 * ph)
    env = np.minimum(1, t / 0.004) * np.exp(-t * 1.6)
    return np.tanh(3.2 * s * env) * 0.9

# ---------------------------------------------------------------- the cowbell (pitched, low, eerie)
def cowbell(n, d=0.22):
    t = tt(d); f = midi(n)
    sq = lambda fr: np.sign(np.sin(2 * np.pi * fr * t))
    s = 0.6 * sq(f) + 0.45 * sq(f * 1.483)
    s = filt(s, lo=300, hi=3000)
    return s * np.exp(-t * 16) * np.minimum(1, t / 0.0015)

def pad(notes, d):
    t = tt(d); out = np.zeros_like(t)
    for n in notes:
        for det in (-0.07, 0, 0.07):
            out += np.sin(2 * np.pi * midi(n) * 2 ** (det / 12) * t + rng.random() * 6) * 0.5
            out += 0.25 * (2 * ((midi(n) * 2 ** (det / 12) * t) % 1) - 1)
    out = filt(out / (len(notes) * 3), lo=180, hi=1600)
    return out * np.minimum(1, t / 0.6) * np.minimum(1, (d - t) / 0.4)

# an eerie choir-like lead: a sawtooth through two "ah" formants, slow vibrato (the mid-range voice)
def choir(n, d):
    t = tt(d); f = midi(n) * (1 + 0.006 * np.sin(2 * np.pi * 5.2 * t))
    ph = np.cumsum(f) / SR
    src = sum((2 * ((ph * (1 + det)) % 1) - 1) for det in (-0.004, 0, 0.004)) / 3
    out = filt(src, lo=650, hi=1000, order=2) * 1.0 + filt(src, lo=1000, hi=1350, order=2) * 0.7 + filt(src, lo=2400, hi=2900, order=2) * 0.25
    return out * np.minimum(1, t / 0.12) * np.minimum(1, np.maximum(0, d - t) / 0.25)

def crackle(d):
    x = np.zeros(int(SR * d))
    idx = rng.integers(0, len(x), int(d * 40))
    x[idx] = rng.standard_normal(len(idx)) * 0.6
    return filt(x, lo=1500, hi=6000) + 0.004 * filt(noise(d), lo=3000, hi=7000)

# ---------------------------------------------------------------- the jumpscare
def scare_hit():
    d = 1.6; t = tt(d)
    boom = np.sin(2 * np.pi * np.cumsum(28 + 160 * np.exp(-t * 7)) / SR) * np.exp(-t * 2.4)
    screech = np.zeros_like(t)
    for k, f0 in enumerate((1180, 1470, 1910, 2650)):
        fm = f0 * (1 + 0.04 * np.sin(2 * np.pi * (7 + k) * t))
        screech += np.sin(2 * np.pi * np.cumsum(fm) / SR) / (k + 1)
    screech = filt(screech + 0.6 * noise(d), lo=600, hi=7000) * np.exp(-t * 3.5)
    return np.tanh(2.2 * (boom + 0.9 * screech))

def reverse_swell(d):
    t = tt(d); k = t / d
    s = filt(noise(d), lo=400, hi=6000) * k ** 3 * 0.5
    s += 0.3 * np.sin(2 * np.pi * np.cumsum(80 + 900 * k ** 3) / SR) * k ** 3
    return s

# ---------------------------------------------------------------- arrangement
E1 = 28  # (MIDI: E1 = 28)
BASSLINE = [  # (beat offset, note, length in beats, slide from) per bar, E Phrygian
    [(0, E1, 1.5, None), (1.5, E1, 0.5, None), (2.5, E1 + 1, 1.0, E1 + 5), (3.5, E1 + 3, 0.5, None)],
    [(0, E1, 1.5, None), (1.75, E1, 0.75, None), (2.5, E1 - 2, 1.0, E1 + 7), (3.5, E1 + 1, 0.5, None)],
]
KICKS = [0, 1.75, 2.5]            # (beats; the clap is on 3, half time)
COW = [64, 65, 67, 64, 71, 72, 71, 67,  64, 65, 67, 69, 67, 65, 64, 62]   # 8ths over two bars (E4 phrygian), an octave down
for bar in range(BARS):
    t0 = bar * BAR
    end = bar == BARS - 1
    # vinyl crackle all the way through
    put(crackle(BAR), t0, 0.12, bus="fx")
    # the pad (E minor, then F major: phrygian)
    put(pad([52, 59, 64, 67] if bar % 2 == 0 else [53, 60, 65, 69], BAR), t0, 0.5, bus="m")
    if end:
        put(bass808(E1, 2.0, slide_from=E1 + 12), t0, 1.0, bus="d")
        put(reverse_swell(BAR * 0.9), t0 + BAR * 0.1, 0.5, bus="fx")
        continue
    for b in KICKS:
        if not muted(t0 + b * BEAT):
            put(kick(), t0 + b * BEAT, 0.9, bus="d")
    if not muted(t0 + 2 * BEAT):
        put(clap(), t0 + 2 * BEAT, 0.75, bus="d")
    # hats: 8ths, a triplet roll at the end of every other bar
    for j in range(8):
        th = t0 + j * BEAT / 2
        if not muted(th):
            put(hat(), th, 0.22 if j % 2 == 0 else 0.14, pan=0.2, bus="d")
    if bar % 2 == 1:
        for j in range(6):
            th = t0 + 3 * BEAT + j * BEAT / 6
            if not muted(th):
                put(hat(0.03), th, 0.13, pan=-0.2, bus="d")
    for off, n, ln, sl in BASSLINE[bar % 2]:
        tb = t0 + off * BEAT
        if not muted(tb):
            put(bass808(n, ln * BEAT, sl), tb, 0.5, bus="d")
    # the cowbell riff (an octave up after the scare)
    up = 12 if bar >= 4 else 0
    for j in range(8):
        tc = t0 + j * BEAT / 2
        if not muted(tc):
            put(cowbell(COW[(bar % 2) * 8 + j] - 12 + up), tc, 0.75, pan=0.15 if j % 2 else -0.15, bus="m")
    # the choir: a long, sad line over each bar (E - F - G - F, an octave up after the scare)
    line = [64, 65, 67, 65][bar % 4] + (12 if bar >= 4 else 0)
    put(choir(line, BAR * 0.95), t0, 0.9, pan=0.0, bus="m")

# the jumpscare: a swell into half a beat of silence, then the hit
put(reverse_swell(BAR * 0.6), SCARE - BAR * 0.6 - BEAT / 2, 0.55, bus="fx")
put(scare_hit(), SCARE, 1.0, bus="fx")

mix_l = BUS["d"][0] * 1.0 + BUS["m"][0] * 0.9 + BUS["fx"][0]
mix_r = BUS["d"][1] * 1.0 + BUS["m"][1] * 0.9 + BUS["fx"][1]
# (the silence before the scare really is silent)
gate = np.ones(N); a, b = int((SCARE - BEAT / 2) * SR), int(SCARE * SR)
gate[a:b] = 0.0
mix_l *= gate; mix_r *= gate
mix_l += np.where(gate == 0, BUS["fx"][0], 0); mix_r += np.where(gate == 0, BUS["fx"][1], 0)
pk = max(np.max(np.abs(mix_l)), np.max(np.abs(mix_r)))
mix_l /= pk; mix_r /= pk
L = np.tanh(mix_l * 1.3) / np.tanh(1.3); R = np.tanh(mix_r * 1.3) / np.tanh(1.3)
peak = max(np.max(np.abs(L)), np.max(np.abs(R)))
L *= 0.95 / peak; R *= 0.95 / peak
fade = np.interp(np.arange(N) / SR, [0, DUR - 0.5, DUR], [1, 1, 0])
L *= fade; R *= fade
data = (np.stack([L, R], 1) * 32767).astype(np.int16)
with wave.open("reel_audio.wav", "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
print("wrote reel_audio.wav", round(DUR, 2), "s; scare at", round(SCARE, 3), "end card at", round(END, 3))
