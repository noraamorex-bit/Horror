# Reel 17 (the cinematic trailer) audio: a film-trailer score, synthesized (no samples). A drone and sparse
# piano under the quiet first half, the power cut, creaks and his footsteps in time with his stride, a deep
# hit on each card, a rising montage with hits on every cut, dead silence, two heartbeats, then the title.
import numpy as np, wave, math, json
DUR_FROM_EDIT = json.load(open('edit.json'))['dur']

SR = 48000
DUR = DUR_FROM_EDIT
N = int(SR * DUR)
rng = np.random.default_rng(1717)
L = np.zeros(N); R = np.zeros(N)

def tt(d): return np.arange(int(SR * d)) / SR
def noise(d): return rng.standard_normal(int(SR * d))

def filt(x, lo=None, hi=None, order=2):
    # FFT band filter with smooth (Butterworth-like) magnitude response
    n = len(x)
    if n == 0: return x
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(n, 1 / SR)
    g = np.ones_like(f)
    if hi: g *= 1 / np.sqrt(1 + (f / hi) ** (2 * order))
    if lo: g *= 1 / np.sqrt(1 + (lo / np.maximum(f, 1e-3)) ** (2 * order))
    return np.fft.irfft(X * g, n)

def env_ad(n, a, d):
    na = max(1, int(SR * a)); e = np.ones(n)
    e[:na] = np.linspace(0, 1, na)
    e[na:] = np.exp(-np.arange(n - na) / (SR * d))
    return e

def put(sig, t, gain=1.0, pan=0.0):
    i = int(t * SR)
    if i >= N: return
    s = sig[: N - i] * gain
    l = math.cos((pan + 1) * math.pi / 4); r = math.sin((pan + 1) * math.pi / 4)
    L[i:i + len(s)] += s * l * 1.414; R[i:i + len(s)] += s * r * 1.414

def fade_curve(t0, t1, v0, v1):
    # gain curve over the whole timeline
    g = np.ones(N)
    return g

def gain_env(points):
    # piecewise-linear gain over the timeline: [(t, g), ...]
    ts = np.array([p[0] for p in points]); gs = np.array([p[1] for p in points])
    return np.interp(np.arange(N) / SR, ts, gs)

# ---------------------------------------------------------------- one-shots
def boom(d=2.2, f0=95, f1=32):
    t = tt(d)
    f = f1 + (f0 - f1) * np.exp(-t * 4)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.7)
    s += 0.6 * filt(noise(d), hi=180) * np.exp(-t / 0.25)
    s += 0.5 * filt(noise(d), lo=2000) * np.exp(-t / 0.03)
    return np.tanh(1.6 * s)

def sting(d=2.6, base=233):
    t = tt(d)
    parts = [1, 1.335, 2.004, 2.53, 4.47, 5.9]
    s = sum(np.sin(2 * np.pi * base * p * t + i) * (0.6 / (1 + i * 0.5)) * np.exp(-t / (1.4 - i * 0.15)) for i, p in enumerate(parts))
    s += 0.4 * filt(noise(d), lo=3000) * np.exp(-t / 0.15)
    return s * env_ad(len(t), 0.003, 9)

def thunder(d=4.0):
    t = tt(d)
    s = filt(noise(d), hi=380, order=3) * (np.exp(-t / 1.4) * (1 - np.exp(-t / 0.02)))
    crack = filt(noise(d), lo=800, hi=6000) * np.exp(-t / 0.08)
    rumble = filt(noise(d), hi=90) * np.exp(-t / 2.2) * 1.5
    return np.tanh(2.2 * (s * 2.5 + crack * 0.9 + rumble))

def click(d=0.03, lo=2500):
    return filt(noise(d), lo=lo) * np.exp(-tt(d) / 0.006)

def tick():
    t = tt(0.25)
    return np.sin(2 * np.pi * 1300 * t) * np.exp(-t / 0.01) + 0.6 * click(0.25) * 0.5

def crack():
    t = tt(0.18)
    return np.tanh(3 * (filt(noise(0.18), lo=600, hi=5000) * np.exp(-t / 0.02) + np.sin(2 * np.pi * 140 * t) * np.exp(-t / 0.03)))

def buzz(d):
    t = tt(d)
    saw = 2 * ((t * 120) % 1) - 1
    gate = (rng.random(len(t)) < 0.002).astype(float)
    gate = np.convolve(gate, np.ones(900), 'same').clip(0, 1)
    return filt(saw, hi=3000) * (0.4 + 0.6 * gate) + 0.5 * filt(noise(d), lo=3000) * gate

def powerdown():
    t = tt(1.2)
    f = 30 + 190 * np.exp(-t * 4)
    s = (2 * ((np.cumsum(f) / SR) % 1) - 1) * np.exp(-t / 0.5) * 0.6
    s = filt(s, hi=1800)
    s += boom(1.2, 70, 30) * 0.8
    return s

def phone_buzz():
    t = tt(0.9)
    sq = np.sign(np.sin(2 * np.pi * 165 * t))
    gate = ((t % 0.3) < 0.18).astype(float)
    return filt(sq, hi=900) * gate * np.exp(-t / 2) * 0.5

def footstep(heavy=1.0):
    d = 0.35; t = tt(d)
    s = np.sin(2 * np.pi * (48 + 30 * np.exp(-t * 30)) * t) * np.exp(-t / 0.09)
    s += 0.7 * filt(noise(d), hi=500) * np.exp(-t / 0.05)
    s += 0.25 * filt(noise(d), lo=1500, hi=5000) * np.exp(-t / 0.015)
    return np.tanh(1.8 * s * heavy)

def creak():
    d = 0.6; t = tt(d)
    f = 170 + 60 * np.sin(2 * np.pi * 2.3 * t) + 25 * rng.standard_normal(len(t)).cumsum() / 4000
    s = (2 * ((np.cumsum(f) / SR) % 1) - 1)
    s = filt(s, lo=300, hi=1600) * env_ad(len(t), 0.05, 0.3)
    return s * 0.5

def heartbeat():
    t = tt(0.5)
    lub = np.sin(2 * np.pi * 52 * t) * np.exp(-t / 0.07) * (1 - np.exp(-t / 0.004))
    dub = np.zeros_like(t); k = int(0.24 * SR)
    t2 = t[: len(t) - k]
    dub[k:] = 0.7 * np.sin(2 * np.pi * 44 * t2) * np.exp(-t2 / 0.06)
    return np.tanh(2.5 * (lub + dub))

def breath(inhale=True, d=0.9):
    t = tt(d)
    s = filt(noise(d), lo=500, hi=3500 if inhale else 2200) * np.sin(np.pi * t / d) ** 2
    return s * 0.35

def his_breath(d=1.6):
    t = tt(d)
    s = filt(noise(d), lo=120, hi=900) * np.sin(np.pi * t / d) ** 3
    return s * 0.7

def door_bang():
    t = tt(1.2)
    return np.tanh(2.5 * (boom(1.2, 120, 45) * 0.8 + filt(noise(1.2), lo=200, hi=3000) * np.exp(-t / 0.06)))

def scream(d=1.6):
    t = tt(d)
    out = np.zeros_like(t)
    for i, f0 in enumerate([392, 415, 587, 622, 880, 933]):
        glide = f0 * (1 + 0.25 * np.exp(-t * 3) - 0.18 * t / d)
        vib = 1 + 0.02 * np.sin(2 * np.pi * (6.5 + i) * t)
        ph = np.cumsum(glide * vib) / SR
        out += (2 * (ph % 1) - 1) / (1 + 0.3 * i)
    out = filt(out, lo=300, hi=4200)
    out += 0.6 * filt(noise(d), lo=1500, hi=7000)
    out *= env_ad(len(t), 0.02, 0.9)
    return np.tanh(3.0 * out) * 0.8

def music_box(freq, d=1.8):
    t = tt(d)
    s = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(2 * np.pi * freq * 2.01 * t) + 0.12 * np.sin(2 * np.pi * freq * 3.98 * t)
    return s * np.exp(-t / 0.55) * (1 - np.exp(-t / 0.002)) * 0.22

def riser(d):
    t = tt(d)
    f = 80 * (1 + 10 * (t / d) ** 2)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * 0.3 + filt(noise(d), lo=1500) * (t / d) ** 2 * 0.6
    return s * (t / d) ** 1.5


def door_creak(d=1.7):
    t = tt(d)
    f = 120 + 70 * (t / d) + 30 * np.sin(2 * np.pi * 1.7 * t) + 12 * np.sin(2 * np.pi * 7.3 * t)
    ph = np.cumsum(f) / SR
    s = (2 * (ph % 1) - 1) * (0.6 + 0.4 * (rng.random(len(t)) < 0.5))
    s = filt(s, lo=250, hi=2200) * env_ad(len(t), 0.15, 0.9) * np.sin(np.pi * np.clip(t / d, 0, 1)) ** 0.5
    return s * 0.7

def door_yank():
    t = tt(1.0)
    s = boom(1.0, 150, 45) * 0.9 + filt(noise(1.0), lo=300, hi=4000) * np.exp(-t / 0.05) * 1.2
    return np.tanh(2.4 * s)

def exhale(d=1.4):
    t = tt(d)
    return filt(noise(d), lo=300, hi=1800) * np.sin(np.pi * t / d) ** 1.5 * 0.45

def hum_glitch(d=0.6):
    t = tt(d)
    return filt(noise(d), lo=2500, hi=9000) * (rng.random(len(t)) < 0.3) * np.exp(-t / 0.3) * 0.4


def knock(heavy=1.0):
    t = tt(0.4)
    s = np.sin(2 * np.pi * (90 + 60 * np.exp(-t * 40)) * t) * np.exp(-t / 0.07) + 0.6 * filt(noise(0.4), lo=300, hi=2500) * np.exp(-t / 0.025)
    return np.tanh(2 * s * heavy)

def hum(d):
    t = tt(d)
    return (np.sin(2 * np.pi * 60 * t) + 0.5 * np.sin(2 * np.pi * 120 * t) + 0.2 * np.sin(2 * np.pi * 180 * t)) * 0.25 * np.clip(t / 0.2, 0, 1)

def scratch(d=0.5):
    t = tt(d)
    return filt(noise(d), lo=1800, hi=7000) * (0.5 + 0.5 * np.sin(2 * np.pi * 9 * t)) ** 2 * np.sin(np.pi * t / d) * 0.4

def whoosh(d=1.6):
    t = tt(d)
    return filt(noise(d), lo=150, hi=1200) * np.sin(np.pi * t / d) ** 2 * 0.5

def kick808(d=0.9, f0=52):
    t = tt(d); f = f0 * (1 + 1.6 * np.exp(-t * 40))
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.42)
    return np.tanh(2.2 * s)
def clap():
    t = tt(0.3); s = np.zeros_like(t)
    for k, dl in enumerate([0, 0.011, 0.022]):
        i = int(dl * SR); n = filt(noise(0.3), lo=900, hi=6000)
        s[i:] += n[: len(t) - i] * np.exp(-t[: len(t) - i] / (0.012 if k < 2 else 0.12))
    return s * 0.8
def hat(open_=False):
    d = 0.25 if open_ else 0.06; t = tt(d)
    return filt(noise(d), lo=7000) * np.exp(-t / (0.08 if open_ else 0.015)) * 0.35
def bell(freq, d=1.4):
    t = tt(d)
    s = np.sin(2 * np.pi * freq * t) + 0.5 * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t / 0.3) + 0.25 * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-t / 0.15)
    return s * np.exp(-t / 0.6) * 0.2
def whoosh_pop():
    t = tt(0.18); return (filt(noise(0.18), lo=1500, hi=8000) * np.exp(-t / 0.04) * 0.5 + np.sin(2 * np.pi * 680 * t) * np.exp(-t / 0.03) * 0.3)

import json
BPM = 140; B = 60 / BPM; BAR = 4 * B
t_all = np.arange(N) / SR

def saw(f, d, det=0.0):
    t = tt(d); return 2 * ((f * (1 + det) * t) % 1.0) - 1
def braam(d=2.6, f=36.71):
    t = tt(d)
    body = sum(saw(f * m, d, det) for m in (1, 2, 3) for det in (-0.004, 0.0, 0.005)) / 9
    bright = filt(body, hi=1600) * np.exp(-t / 0.35)
    low = filt(body, hi=380) * np.minimum(1, t / 0.04) * np.exp(-t / 1.1)
    s = np.tanh(2.4 * (low * 1.2 + bright * 0.8))
    bm = boom(d, 70, 30); m = min(len(s), len(bm)); return s[:m] * 0.9 + bm[:m] * 0.5
def pluck(f, d=0.28):
    t = tt(d); s = saw(f, d) * 0.6 + saw(f, d, 0.006) * 0.4
    return filt(s, hi=2600) * np.exp(-t / 0.09) * 0.35
def pad(freqs, d, hi=900):
    t = tt(d); s = sum(saw(f, d, det) for f in freqs for det in (-0.003, 0.003)) / (2 * len(freqs))
    return filt(s, hi=hi) * np.minimum(1, t / 0.8) * 0.5
def string_stab(f, d=0.22):
    t = tt(d); s = sum(saw(f, d, det) for det in (-0.005, 0, 0.005)) / 3
    return filt(s, lo=60, hi=1400) * np.exp(-t / 0.12) * 0.5
def sub(f, d=0.8):
    t = tt(d); fr = f * (1 + 1.4 * np.exp(-t * 40))
    return np.tanh(2.0 * np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t / 0.5)) * 0.9
def impact():
    a = boom(1.4, 140, 36).copy(); n = filt(noise(0.25), lo=300, hi=6000) * np.exp(-tt(0.25) / 0.05) * 0.8
    a[:len(n)] += n[:len(a)]; return a
def tinnitus(d):
    t = tt(d); return np.sin(2 * np.pi * 6200 * t) * 0.025 * np.minimum(1, t / 0.1)

D1, D2, F2, A2, D3, F3, A3, Cs4, D4, E3 = 36.71, 73.42, 87.31, 110.0, 146.83, 174.61, 220.0, 277.18, 293.66, 164.81

D1, D2, F2, A2, D3, F3, A3, Cs4, D4, E3 = 36.71, 73.42, 87.31, 110.0, 146.83, 174.61, 220.0, 277.18, 293.66, 164.81
def chime():
    return sum(bell(f, 1.2) for f in (880.0, 1108.7, 1318.5)) * 1.6
def buzzer(d=0.45):
    t = tt(d); s = saw(110, d) * 0.5 + saw(116.5, d) * 0.5
    return np.tanh(3 * filt(s, hi=2400)) * np.minimum(1, t / 0.01) * np.exp(-np.maximum(0, t - d + 0.08) / 0.03) * 0.5

E = json.load(open("edit.json"))
CUES = E["cues"]
def cue(kind, name=None, text=None, nth=0):
    hits = [c for c in CUES if c["kind"] == kind and (name is None or c.get("name") == name) and (text is None or text in c.get("text", ""))]
    return hits[nth]
D1, D2, F2, A1, A2, D3, F3, A3, Bb2, C3, E3 = 36.71, 73.42, 87.31, 55.0, 110.0, 146.83, 174.61, 220.0, 116.54, 130.81, 164.81

def piano(f, d=3.2, vel=1.0):
    t = tt(d)
    s = np.zeros_like(t)
    for h, a in ((1, 1.0), (2, 0.45), (3, 0.22), (4, 0.12), (5, 0.06)):
        fh = f * h * (1 + 0.0004 * h * h)
        s += a * np.sin(2 * np.pi * fh * t) * np.exp(-t * (0.9 + 0.7 * h))
    hammer = filt(noise(0.03), lo=1500) * np.exp(-tt(0.03) / 0.006) * 0.15
    s[:len(hammer)] += hammer
    return s * 0.28 * vel * np.minimum(1, t / 0.004)

def drone(d, f=D1):
    t = tt(d)
    s = sum(saw(f * m, d, det) for m in (1, 1.5, 2) for det in (-0.003, 0.002)) / 6
    return filt(s, hi=420) * np.minimum(1, t / 2.5) * np.minimum(1, (d - t) / 1.5) * 0.5

def rain(d):
    return filt(noise(d), lo=900, hi=7000) * 0.05

def reverb(x, secs=2.6, mix=0.32):
    n = int(SR * secs); ir = rng.standard_normal(n) * np.exp(-np.arange(n) / (SR * secs / 6))
    ir = filt(ir, hi=5000); ir /= np.sqrt(np.sum(ir ** 2))
    m = len(x) + n
    y = np.fft.irfft(np.fft.rfft(x, m) * np.fft.rfft(ir, m), m)[:len(x)]
    return x * (1 - mix) + y * mix * 1.4

def steps_along(t0, dur, dist_fn, stride=2.6, gain=0.7, heavy=1.0, pan=0.0):
    # a footstep every half stride of distance travelled (dist_fn(k) = studs walked by k in 0..1)
    last = 0.0
    n = int(dur * 30)
    for i in range(n + 1):
        k = i / n
        dd = dist_fn(k)
        if dd - last >= stride / 2:
            last = dd
            put(footstep(heavy), t0 + k * dur, gain, pan)

def ease(k): return k * k * (3 - 2 * k)

# ---- the bed: rain and wind under everything up to the montage, then silence
MONT = cue("card", text="BRING YOUR FRIENDS")["t"] + cue("card", text="BRING YOUR FRIENDS")["len"]
BLACK = cue("black")["t"]
HERO = cue("shot", "hero", nth=1)["t"]
TITLE = cue("title")["t"]
ENDC = cue("end")["t"]
put(rain(BLACK), 0, 0.9)
put(drone(BLACK + 0.2, D1), 0, 0.55)
put(drone(BLACK - 8, A1 / 2 * 1.0), 8, 0.35)

# ---- the opening: a slow piano line (D minor), sparse
melody = [(0.5, A3 * 2), (1.6, F3 * 2), (2.6, E3 * 2), (3.7, D3 * 2), (5.6, A3 * 2), (6.6, Bb2 * 4), (7.6, A3 * 2), (9.8, F3 * 2), (10.8, E3 * 2), (11.9, D3 * 2)]
for at, fq in melody:
    put(piano(fq, 3.5, 0.9), at, 0.9, 0.2 * math.sin(at))
    put(piano(fq / 2, 3.5, 0.5), at, 0.5)
LIV = cue("shot", "living")
OUT = LIV["t"] + 97 / 30
for k in range(7): put(click(0.02, 2500), OUT + k * 0.11 * (1 + 0.3 * math.sin(k)), 0.5)       # the lights stutter
put(powerdown(), OUT + 0.6, 0.9)
put(impact(), LIV["t"] + 129 / 30, 0.8)
# ---- cards from "BUT SOMEONE ELSE" on: a deep hit with a long tail
for c in CUES:
    if c["kind"] == "card" and c["t"] > LIV["t"]:
        put(boom(2.6, 70, 28), c["t"] + 0.05, 0.9)
        put(sub(D1 * 2, 1.6), c["t"] + 0.05, 0.5)
# ---- the hatch and the attic: creaks, a low breath up there
H = cue("shot", "hatch"); put(creak(), H["t"] + 0.8, 0.6); put(creak(), H["t"] + 2.0, 0.4, -0.3)
A = cue("shot", "attic"); put(his_breath(2.0), A["t"] + 1.0, 0.45)
# ---- the garage: the hatch, his legs, the landing
G = cue("shot", "garage")
put(creak(), G["t"] + 0.2, 0.7); put(door_creak(1.4), G["t"] + 0.6, 0.5)
put(boom(1.2, 110, 40), G["t"] + 65 / 30 * (105 / 105), 1.0); put(impact(), G["t"] + 65 / 30, 0.7)
put(his_breath(1.8), G["t"] + 2.6, 0.6)
# ---- the stairs: the flashlight clicks on; a sting when it finds him
ST = cue("shot", "stairs"); put(click(0.03, 3000), ST["t"] + 0.05, 1.0); put(sting(1.8, 233), ST["t"] + 1.7, 0.6)
# ---- under the bed: his footsteps, slowing, stopping; breath held
UB = cue("shot", "underbed")
dur = UB["len"]; off = 10 / 30
def ub_dist(k):
    kk = min(1.0, (off + k * dur) / (120 / 30) / 0.7)
    return 16.8 * ease(kk)
steps_along(UB["t"], dur, ub_dist, gain=0.9, heavy=1.2)
put(breath(True, 0.4), UB["t"] + 0.2, 0.35)
HA = cue("shot", "hall"); steps_along(HA["t"], HA["len"], lambda k: 11 * k, gain=0.45, heavy=0.9, pan=0.3)
BO = cue("shot", "boiler")
put(filt(noise(BO["len"]), hi=180) * 0.4, BO["t"], 0.8)                                        # the boiler's roar
steps_along(BO["t"], BO["len"], lambda k: 14 * (8 / 105 + k * 97 / 105), gain=1.0, heavy=1.3, pan=-0.2)
# ---- the montage: a riser into it, a hit on every cut and flash, footsteps running at you
put(riser(3.2), MONT - 3.2, 0.9)
for c in CUES:
    if MONT - 0.01 <= c["t"] < BLACK:
        if c["kind"] in ("shot", "flash"):
            put(impact(), c["t"], 0.9 if c["kind"] == "flash" else 0.6)
            put(filt(noise(0.12), lo=2000) * np.exp(-tt(0.12) / 0.03), c["t"], 0.6)
CH = cue("shot", "chase")
for k in range(9): put(footstep(1.4), CH["t"] + k * 0.12, 1.0)
put(scream(0.9), CH["t"] + 0.5, 0.8)
put(braam(2.0), CH["t"] + CH["len"] - 0.15, 1.0)
# ---- silence, then him
mute = gain_env([(0, 1), (BLACK - 0.02, 1), (BLACK, 0), (DUR, 0)])
L *= mute; R *= mute
put(tinnitus(HERO - BLACK + 0.6), BLACK, 0.8)
put(heartbeat(), HERO + 0.4, 0.9); put(heartbeat(), HERO + 1.5, 0.9)
put(his_breath(1.6), HERO + 1.2, 0.8)
put(braam(3.4), HERO + 2.3, 1.0)
# ---- the title: one hit, then the piano line again, softly, under the end card
put(impact(), TITLE + 0.15, 1.0); put(boom(3.0, 60, 26), TITLE + 0.15, 1.0)
for at, fq in [(0.4, A3 * 2), (1.4, F3 * 2), (2.3, E3 * 2), (3.3, D3 * 2), (4.6, A3)]:
    put(piano(fq, 3.5, 0.7), ENDC + at, 0.8)
put(drone(DUR - ENDC, D1), ENDC, 0.3)

L = reverb(L); R = reverb(R, 2.7)
pk = max(np.max(np.abs(L)), np.max(np.abs(R))); L /= pk / 1.4; R /= pk / 1.4
L = np.tanh(L); R = np.tanh(R)
peak = max(np.max(np.abs(L)), np.max(np.abs(R)))
L *= 0.9 / peak; R *= 0.9 / peak
fade = gain_env([(0, 0), (0.3, 1), (DUR - 0.8, 1), (DUR, 0)])
L *= fade; R *= fade
data = (np.stack([L, R], 1) * 32767).astype(np.int16)
with wave.open("reel_audio.wav", "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
print("wrote reel_audio.wav", round(DUR, 2), "s")
