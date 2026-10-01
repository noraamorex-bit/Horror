# Original, fully synthesized soundtrack for the reel (no samples): python3 audio.py -> reel_audio.wav
import numpy as np, wave, math

SR = 48000
DUR = 27.0
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
# low drone: detuned A1 + fifth, slow beating, plus a thin high whine
drone = (np.sin(2 * np.pi * 55 * t_all) + 0.8 * np.sin(2 * np.pi * 55.4 * t_all + 1) + 0.45 * np.sin(2 * np.pi * 82.6 * t_all)
         + 0.25 * np.sin(2 * np.pi * 110.3 * t_all)) * (0.75 + 0.25 * np.sin(2 * np.pi * 0.23 * t_all))
drone += 0.6 * filt(rng.standard_normal(N), hi=140)
whine = 0.05 * np.sin(2 * np.pi * 1864 * t_all + 3 * np.sin(2 * np.pi * 0.4 * t_all)) * (0.5 + 0.5 * np.sin(2 * np.pi * 5.3 * t_all))
drone_g = gain_env([(0, 0), (0.25, 0.9), (2.55, 0.9), (2.62, 0.45), (5.4, 0.35), (8.7, 0.35), (8.75, 0), (9.9, 0), (10.4, 0.8),
                    (13.5, 1.0), (13.56, 0), (14.4, 0), (14.8, 0.7), (19.0, 0.9), (20.55, 1.0), (20.6, 0), (21.0, 0), (21.05, 0.9), (26.0, 0.7), (27, 0)])
whine_g = gain_env([(0, 0), (0.5, 1), (2.6, 1), (2.62, 0), (14.4, 0), (15, 0.8), (19, 1), (20.6, 0)])
L += 0.16 * drone * drone_g + whine * whine_g; R += 0.16 * drone * drone_g * 0.97 + whine * whine_g * 0.9

# rain: hiss outside, muffled indoors
rain = filt(rng.standard_normal(N), lo=900, hi=9000) * 0.5 + filt(rng.standard_normal(N), lo=200, hi=900) * 0.3
rain_in = filt(rain, hi=700)
rain_g = gain_env([(0, 0.25), (2.6, 0.25), (2.62, 1.0), (5.38, 1.0), (5.42, 0), (27, 0)])
rain_in_g = gain_env([(0, 0), (5.38, 0), (5.42, 0.9), (8.7, 0.9), (8.8, 0.6), (13.5, 0.5), (13.56, 0), (14.4, 0.3), (20.6, 0.3), (20.65, 0), (21, 0.4), (27, 0.2)])
L += 0.09 * (rain * rain_g + 3 * rain_in * rain_in_g)
R += 0.09 * (np.roll(rain, 997) * rain_g + 3 * np.roll(rain_in, 1201) * rain_in_g)

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

# ------------------------------------------------------------- timeline
# S1 hook
put(his_breath(1.8), 0.1, 0.5)
put(sting(2.6, 207), 1.3, 0.55); put(boom(2.0), 1.3, 0.9)
put(crack(), 1.62, 0.7, 0.2)
for k in range(5):
    put(click(0.04, 1500) * 0.6, 2.0 + k * 0.11 + rng.random() * 0.04, 0.5, 0.3)
put(buzz(0.6), 1.95, 0.12)
# S2 house + title
put(thunder(), 2.96, 1.0); put(boom(2.6, 110, 30), 2.98, 1.0)
put(sting(3.0, 155), 2.98, 0.35)
put(thunder(3.0) * 0.5, 3.24, 0.5, -0.4)
# S3 cozy: music box lullaby, ticking clock, Mom's texts
notes = [440, 523.3, 659.3, 587.3, 523.3, 493.9, 440, 392, 440]
for i, fq in enumerate(notes):
    put(music_box(fq), 5.45 + i * 0.36, 1.0, 0.25 * math.sin(i))
for k in range(9):
    put(tick() * 0.25, 5.5 + k * 0.4, 0.4, -0.6)
put(phone_buzz(), 5.8, 0.9, 0.3); put(phone_buzz(), 6.75, 0.9, 0.3)
# S4 blackout
put(buzz(0.25), 8.48, 0.25)
put(powerdown(), 8.7, 1.0)
put(click(0.05, 1800) * 2, 9.4, 0.8, 0.4)
# S5 the hunt
put(his_breath(2.2), 10.2, 0.45, -0.2)
put(crack(), 10.95, 0.8)
put(riser(2.4), 11.15, 0.6)
put(sting(2.0, 185), 11.2, 0.45)
# footsteps synced with his stride (one per 3.75 studs travelled)
z0, back = -24.0, None
last = 0
for f in range(int(10.0 * 30), int(13.55 * 30)):
    s = f / 30 - 10.0
    if s < 1.2: continue
    u = s - 1.2
    dist = 18 * (u - 0.25) if u > 0.5 else 18 * u * u
    stepn = int(dist / 3.75)
    if stepn > last:
        last = stepn
        near = min(1.0, dist / 34)
        put(footstep(0.8 + 0.6 * near), f / 30, 0.45 + 0.55 * near, 0.15 * math.sin(stepn * 2.1))
put(boom(1.4, 130, 40), 13.55, 0.9); put(scream(0.5), 13.4, 0.55)
put(heartbeat(), 13.95, 0.55); put(heartbeat(), 14.2, 0.45)
# S6 closet: heartbeat speeding up, your breathing until you hold it, his footsteps and breath
t = 14.4; bpm = 78
while t < 19.0:
    put(heartbeat(), t, 0.32 + 0.4 * (t - 14.4) / 4.6)
    bpm = 78 + (t - 14.4) / 4.6 * 60
    t += 60 / bpm
bt = 14.5; inh = True
while bt < 16.35:
    put(breath(inh, 0.7), bt, 0.55, 0.0); bt += 0.75; inh = not inh
for k in range(5):
    put(creak(), 14.9 + k * 0.42, 0.8, 0.5 - k * 0.2)
put(his_breath(1.6), 16.9, 0.9, -0.1); put(his_breath(1.6), 18.3, 1.0, -0.1)
put(creak(), 18.05, 0.9); put(creak(), 18.55, 0.9)
put(riser(1.8), 17.2, 0.35)
# S7 the doors
put(door_bang(), 19.0, 1.0); put(scream(1.6), 19.05, 0.7)
put(boom(1.8, 140, 35), 19.9, 1.0); put(scream(0.8), 19.9, 1.0); put(sting(1.2, 311), 19.9, 0.5)
# S8 end
put(boom(3.0, 90, 28), 21.0, 1.0); put(sting(4.0, 138), 21.0, 0.35)
put(boom(1.5, 70, 30), 23.0, 0.5)
for i, fq in enumerate([440, 523.3, 493.9, 415.3]):
    put(music_box(fq, 2.5), 24.4 + i * 0.55, 0.8, 0.2 * math.sin(i))
put(his_breath(1.8), 25.4, 0.6)

# hard silences on the cuts (everything ducks)
duck = gain_env([(0, 1), (13.9, 1), (14.1, 0.55), (14.4, 0.55), (14.8, 1), (20.58, 1), (20.6, 0.0), (20.98, 0.0), (21.0, 1), (27, 1)])
L *= duck; R *= duck

# --------------------------------------------------- simple room reverb (FFT convolution)
def reverb(x, rt=1.6, mix=0.22):
    ir_n = int(SR * rt)
    ir = rng.standard_normal(ir_n) * np.exp(-np.arange(ir_n) / (SR * rt / 6.9))
    ir = filt(ir, hi=5000); ir /= np.sqrt(np.sum(ir ** 2))
    n = 1 << int(math.ceil(math.log2(len(x) + ir_n)))
    y = np.fft.irfft(np.fft.rfft(x, n) * np.fft.rfft(ir, n), n)[: len(x)]
    return x * (1 - mix) + y * mix
L = reverb(L); R = reverb(R)

# master: gentle compression + limiter, normalise to -1 dBFS
def master(x):
    x = np.tanh(x * 1.05) / np.tanh(1.05)
    return x
L, R = master(L), master(R)
peak = max(np.max(np.abs(L)), np.max(np.abs(R)))
L *= 0.89 / peak; R *= 0.89 / peak
fade = gain_env([(0, 1), (26.4, 1), (27, 0)])
L *= fade; R *= fade
data = (np.stack([L, R], 1) * 32767).astype(np.int16)
with wave.open("reel_audio.wav", "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
print("wrote reel_audio.wav", DUR, "s")
