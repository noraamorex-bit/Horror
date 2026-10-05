# Reel 9 soundtrack (the phone at 3 AM), fully synthesized: python3 audio.py -> reel_audio.wav
import numpy as np, wave, math

SR = 48000
DUR = 38.5
N = int(SR * DUR)
rng = np.random.default_rng(61)
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
tl = json.load(open("timeline.json"))
P = tl["phases"]
t_all = np.arange(N) / SR

def blip(f0, f1, d=0.12, g=0.35):
    t = tt(d); f = np.linspace(f0, f1, len(t))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / (d / 3)) * g
def pop_in():
    a = blip(1250, 1650, 0.11, 0.32); b = blip(1900, 2100, 0.07, 0.12); a[:len(b)] += b; return a
def sent():
    a = filt(noise(0.22), lo=900, hi=5000) * np.sin(np.pi * tt(0.22) / 0.22) ** 2 * 0.35; b = blip(700, 1300, 0.12, 0.2); a[:len(b)] += b; return a
def notif():    return np.concatenate([blip(1318, 1318, 0.14, 0.35), np.zeros(int(SR * 0.04)), blip(1760, 1760, 0.22, 0.35)])
def keytap():   t = tt(0.025); return filt(noise(0.025), lo=2500, hi=9000) * np.exp(-t / 0.006) * 0.25
def shutter():  t = tt(0.16); s = filt(noise(0.16), lo=1500, hi=8000) * (np.exp(-t / 0.01) + 0.6 * np.exp(-np.maximum(0, t - 0.07) / 0.012) * (t > 0.07)); return s * 0.6
def static(d):  return filt(noise(d), lo=1200, hi=6000) * 0.06
def ringtone(d):
    out = np.zeros(int(SR * d)); notes = [784, 988, 1175, 988, 784, 1175]
    for i in range(int(d / 0.16)):
        s = bell(notes[i % len(notes)], 0.5) * 1.6; a = int(i * 0.16 * SR); n = min(len(s), len(out) - a)
        if n > 0: out[a:a + n] += s[:n]
    return out

# ---- the room at 3 AM: a low drone the whole way, swelling toward the call
drone = (np.sin(2 * np.pi * 46 * t_all) + 0.6 * np.sin(2 * np.pi * 46.4 * t_all + 1) + 0.3 * np.sin(2 * np.pi * 69 * t_all)) * 0.12
dg = gain_env([(0, 0.5), (P["chat"], 0.8), (P["ring"] - 0.1, 1.3), (P["ring"], 0.3), (P["call"], 0.8), (P["scare"] - 0.3, 1.5), (P["scare"] - 0.25, 0), (P["after"], 0), (P["after"] + 0.3, 0.6), (P["end"], 0.4), (DUR, 0)])
L += drone * dg; R += drone * dg
# ---- lock screen
put(notif(), 0.25, 0.9); put(notif(), 0.85, 0.9)
put(whoosh(0.5), 1.3, 0.4)
# ---- messages
for m in tl["msgs"]:
    t = m["t"]
    if t < P["chat"]: continue
    if m["who"] == "me":
        n = len(m["text"])
        for j in range(n):
            put(keytap(), t - 0.9 + 0.75 * j / max(1, n), 0.5, 0.2)
        put(sent(), t, 0.9)
    elif m["who"] == "sys":
        put(blip(520, 380, 0.3, 0.3), t, 0.8)
    else:
        put(pop_in(), t, 0.9, -0.15)
    if m["kind"] == "video":
        put(static(3.4), t, 1.0)
        for k in range(5): put(footstep(1.0), t + 0.4 + k * 0.6, 0.7, 0.3)
        put(his_breath(1.4), t + 1.8, 0.4)
    if m["kind"] == "photo":
        put(shutter(), t - 0.25, 0.9)
# ---- the zoom: a riser and a sting when he's there
put(riser(1.8), P["zoom0"] + 0.1, 0.6)
put(sting(1.8, 155), P["zoom1"] - 0.5, 0.55); put(boom(1.2, 110, 36), P["zoom1"] - 0.5, 0.6)
# ---- heartbeat while she's typing and can't move
t = 21.0
while t < P["ring"]:
    put(heartbeat(), t, 0.5 + 0.4 * (t - 21) / 5); t += 0.8 - 0.25 * (t - 21) / 5
put(creak(), 23.4, 0.5, -0.4)
# ---- the call
put(ringtone(P["call"] - P["ring"]), P["ring"], 0.8)
put(blip(900, 1400, 0.15, 0.4), P["call"] - 0.05, 0.8)
put(breath(True, 0.8), P["call"] + 0.3, 0.6); put(breath(False, 0.9), P["call"] + 1.2, 0.6)
put(creak(), P["call"] + 1.0, 0.7, -0.3)
put(his_breath(1.6), P["call"] + 1.6, 0.9)
put(static(0.9) * 4, P["scare"] - 0.9, 0.7)
for k in range(6): put(hum_glitch(0.15), P["scare"] - 0.8 + k * 0.13, 0.5)
# ---- him
s = P["scare"]
put(boom(1.8, 150, 34), s, 1.0); put(scream(1.0), s, 1.0); put(sting(1.2, 311), s, 0.5)
# ---- after: the call drops
put(blip(480, 480, 0.18, 0.35), P["after"] + 0.1, 0.8); put(blip(380, 380, 0.25, 0.35), P["after"] + 0.32, 0.8)
# ---- end card: the beat
BPM = 140; B = 60 / BPM; T0 = P["end"] + 0.1
MEL = [311.1, 0, 370.0, 0, 349.2, 311.1, 0, 277.2, 311.1, 0, 370.0, 0, 415.3, 370.0, 349.2, 0]
b = 0
while T0 + b * 4 * B < DUR - 0.3:
    t0 = T0 + b * 4 * B
    put(kick808(), t0, 0.8); put(kick808(0.6), t0 + 2.5 * B, 0.55); put(clap(), t0 + 2 * B, 0.7)
    for k in range(8): put(hat(open_=(k == 7)), t0 + k * B / 2, 0.5)
    for k, fq in enumerate(MEL):
        if fq: put(bell(fq), t0 + k * B / 4, 0.5, 0.25 * math.sin(k))
    b += 1
for d in (0.1, 0.3, 0.9, 1.5):
    put(whoosh_pop(), P["end"] + d, 0.7)

L = np.tanh(L * 1.1) / np.tanh(1.1); R = np.tanh(R * 1.1) / np.tanh(1.1)
peak = max(np.max(np.abs(L)), np.max(np.abs(R)))
L *= 0.9 / peak; R *= 0.9 / peak
fade = gain_env([(0, 1), (DUR - 0.5, 1), (DUR, 0)])
L *= fade; R *= fade
data = (np.stack([L, R], 1) * 32767).astype(np.int16)
with wave.open("reel_audio.wav", "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
print("wrote reel_audio.wav")
