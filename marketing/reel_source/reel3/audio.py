# Original, fully synthesized soundtrack for the reel (no samples): python3 audio.py -> reel_audio.wav
import numpy as np, wave, math

SR = 48000
DUR = 30.0
N = int(SR * DUR)
rng = np.random.default_rng(11)
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

# ---------------------------------------------------------------- beds
t_all = np.arange(N) / SR
drone = (np.sin(2 * np.pi * 55 * t_all) + 0.8 * np.sin(2 * np.pi * 55.4 * t_all + 1) + 0.45 * np.sin(2 * np.pi * 82.6 * t_all)
         + 0.25 * np.sin(2 * np.pi * 110.3 * t_all)) * (0.75 + 0.25 * np.sin(2 * np.pi * 0.23 * t_all))
drone += 0.6 * filt(rng.standard_normal(N), hi=140)
whine = 0.04 * np.sin(2 * np.pi * 1864 * t_all + 3 * np.sin(2 * np.pi * 0.4 * t_all)) * (0.5 + 0.5 * np.sin(2 * np.pi * 5.3 * t_all))
drone_g = gain_env([(0, 0), (0.4, 0.6), (3.4, 0.7), (3.45, 0.45), (8.6, 0.6), (11, 0.8), (17.0, 0.95), (17.3, 0.2), (19.3, 0.3), (19.4, 1.0), (20.95, 1.1), (21.0, 0), (22.5, 0), (22.55, 0.8), (30, 0.5)])
whine_g = gain_env([(0, 0), (11, 0), (13, 0.6), (17, 0.9), (17.3, 0), (19.4, 0.8), (21, 0), (30, 0)])
L += 0.15 * drone * drone_g + whine * whine_g; R += 0.15 * drone * drone_g * 0.97 + whine * whine_g * 0.9
rain = filt(rng.standard_normal(N), lo=200, hi=900) * 0.4 + filt(rng.standard_normal(N), lo=900, hi=4000) * 0.15
rain_in = filt(rain, hi=650)
roof = filt(rng.standard_normal(N), lo=400, hi=3000) * 0.5   # rain right on the roof, in the attic
rain_g = gain_env([(0, 0), (0.3, 0.9), (11, 0.6), (21, 0.6), (21.05, 0), (22.5, 0), (23, 0.5), (30, 0.4)])
roof_g = gain_env([(0, 0), (10.0, 0), (11.2, 0.55), (17.0, 0.55), (17.3, 0.2), (21.0, 0.2), (21.05, 0), (30, 0)])
L += 0.35 * rain_in * rain_g + 0.06 * roof * roof_g; R += 0.35 * np.roll(rain_in, 1201) * rain_g + 0.06 * np.roll(roof, 777) * roof_g

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
# ------------------------------------------------------------- timeline
# 1 — the hatch: something moving up there, then it knocks
put(creak(), 0.7, 0.6, 0.1); put(creak(), 1.5, 0.7, -0.1)
put(knock(1.2), 2.3, 1.0); put(knock(0.7), 2.45, 0.6); put(knock(0.4), 2.58, 0.4)
put(sting(2.2, 196), 2.3, 0.3)
put(his_breath(1.2), 2.8, 0.35)
# 2a — the kitchen: fridge hum, a clock
put(hum(1.6), 3.4, 0.8)
for k in range(4):
    put(tick() * 0.25, 3.5 + k * 0.4, 0.5, -0.5)
# 2b — footsteps over the bed
for k, tt0 in enumerate([5.1, 5.65, 6.2]):
    put(filt(footstep(1.3), hi=380), tt0, 1.0, 0.2 - k * 0.2)
    put(creak() * 0.5, tt0 + 0.08, 0.4, 0.2 - k * 0.2)
# 2c — the open hatch: air moving, breathing up there
put(whoosh(1.8), 6.8, 0.8)
put(his_breath(1.4), 7.3, 0.5)
# 3 — up the ladder
for k in range(4):
    put(creak(), 8.7 + k * 0.5, 0.8, 0.1 * (-1) ** k)
bt, inh = 8.7, True
while bt < 11.0:
    put(breath(inh, 0.5), bt, 0.55); bt += 0.55; inh = not inh
# 4 — the nest: a music box somewhere, the photos, the tally marks
for i, fq in enumerate([523.3, 493.9, 440, 415.3, 440, 392]):
    put(music_box(fq, 2.0), 11.4 + i * 0.6, 0.45, 0.3 * math.sin(i))
put(sting(2.6, 155), 13.6, 0.35)
put(scratch(0.6), 15.4, 0.7); put(scratch(0.5), 15.95, 0.6)
# 5 — a creak behind you. silence. the heartbeat. turn around.
put(creak(), 17.6, 1.0, -0.5)
t = 17.9; bpm = 70
while t < 20.4:
    put(heartbeat(), t, 0.4 + 0.35 * (t - 17.9) / 2.5)
    bpm = 70 + (t - 17.9) * 28
    t += 60 / bpm
put(riser(1.2), 18.3, 0.3)
put(his_breath(1.6), 19.3, 1.0)
put(sting(1.6, 207), 19.4, 0.5); put(boom(1.4, 90, 34), 19.4, 0.5)
put(crack(), 19.9, 0.9)
# 6 — he comes at you
for k in range(3):
    put(footstep(1.6), 20.42 + k * 0.17, 1.0)
put(boom(1.8, 150, 34), 20.62, 1.0); put(scream(1.0), 20.6, 1.0); put(sting(1.2, 311), 20.62, 0.55)
# end card
put(boom(3.0, 90, 28), 22.5, 0.9); put(sting(3.2, 138), 22.5, 0.3)
for i, fq in enumerate([440, 523.3, 493.9, 415.3]):
    put(music_box(fq, 2.5), 23.6 + i * 0.55, 0.8, 0.2 * math.sin(i))
put(creak(), 27.2, 0.5); put(his_breath(1.6), 27.6, 0.5)

duck = gain_env([(0, 1), (17.25, 1), (17.35, 0.5), (19.3, 0.6), (19.4, 1), (20.93, 1), (20.95, 0.0), (22.48, 0.0), (22.5, 1), (30, 1)])
L *= duck; R *= duck

def reverb(x, rt=1.6, mix=0.24):
    ir_n = int(SR * rt)
    ir = rng.standard_normal(ir_n) * np.exp(-np.arange(ir_n) / (SR * rt / 6.9))
    ir = filt(ir, hi=5000); ir /= np.sqrt(np.sum(ir ** 2))
    n = 1 << int(math.ceil(math.log2(len(x) + ir_n)))
    y = np.fft.irfft(np.fft.rfft(x, n) * np.fft.rfft(ir, n), n)[: len(x)]
    return x * (1 - mix) + y * mix
L = reverb(L); R = reverb(R)
L = np.tanh(L * 1.05) / np.tanh(1.05); R = np.tanh(R * 1.05) / np.tanh(1.05)
peak = max(np.max(np.abs(L)), np.max(np.abs(R)))
L *= 0.89 / peak; R *= 0.89 / peak
fade = gain_env([(0, 1), (29.4, 1), (30, 0)])
L *= fade; R *= fade
data = (np.stack([L, R], 1) * 32767).astype(np.int16)
with wave.open("reel_audio.wav", "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
print("wrote reel_audio.wav", DUR, "s")
