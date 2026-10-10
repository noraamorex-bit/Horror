# The reels' beat on its own ("someone lives in our attic"): the #2 / #7 track without the sound
# effects, about a minute long so it works under any reel. Same instruments and seed as
# reel_source/reel18/audio.py (its synth functions are reused from there).
# python3 beat.py -> someone_lives_in_our_attic_beat.wav
import math, wave, numpy as np
src = open("../reel_source/reel18/audio.py").read()
head = src[: src.index("import json")].replace("DUR = 29.5", "DUR = 64.0")
exec(head)                                                       # SR, N, L, R, tt, noise, filt, put, gain_env, boom, riser, music_box...
inst = src[src.index("def kick808"): src.index("# ---- intro")]
BPM = 146; B = 60 / BPM
exec(inst)                                                       # kick808, clap, hat, bell, whoosh_pop
MEL = [415.3, 0, 311.1, 0, 370.0, 0, 349.2, 311.1, 466.2, 0, 415.3, 0, 370.0, 349.2, 311.1, 0]
bar = 4 * B
T0 = 3.5                                                         # the drop
A, BRK, B2 = 16, 2, 16                                           # bars: beat, breakdown, beat
t_end = T0 + (A + BRK + B2) * bar
# the drone under everything; music box intro
t_all = np.arange(N) / SR
drone = (np.sin(2 * np.pi * 55 * t_all) + 0.7 * np.sin(2 * np.pi * 55.4 * t_all + 1) + 0.3 * np.sin(2 * np.pi * 82.6 * t_all)) * 0.12
dg = gain_env([(0, 0), (0.3, 1), (3.4, 1), (3.5, 0.35), (T0 + A * bar, 0.35), (T0 + A * bar + 0.1, 0.8), (T0 + (A + BRK) * bar, 0.8), (T0 + (A + BRK) * bar + 0.1, 0.35), (t_end, 0.35), (t_end + 2.5, 0)])
L += drone * dg; R += drone * dg
for i, fq in enumerate([659.3, 587.3, 523.3, 493.9, 523.3]):
    put(music_box(fq, 1.6), 0.25 + i * 0.45, 0.7, 0.2 * math.sin(i))
put(riser(1.0), T0 - 1.0, 0.5)
def drums_and_bells(t0, b, drums=True):
    if drums:
        put(kick808(), t0, 0.95)
        put(kick808(0.6), t0 + 2.5 * B, 0.7)
        put(clap(), t0 + 2 * B, 0.8)
        for k in range(8):
            put(hat(open_=(k == 7)), t0 + k * B / 2, 0.6)
        for k in (5, 13):
            for r in range(3):
                put(hat(), t0 + k * B / 4 + r * B / 12, 0.4)
    for k, fq in enumerate(MEL):
        if fq and (b % 2 == 0 or k < 8):
            put(bell(fq), t0 + k * B / 4, 0.55, 0.25 * math.sin(k))
put(boom(1.6, 110, 32), T0, 0.9)
for b in range(A):
    drums_and_bells(T0 + b * bar, b)
for b in range(BRK):                                             # the breakdown: just the bells
    drums_and_bells(T0 + (A + b) * bar, b, drums=False)
put(riser(1.4), T0 + (A + BRK) * bar - 1.4, 0.55)
put(boom(1.6, 110, 32), T0 + (A + BRK) * bar, 0.9)
for b in range(B2):
    drums_and_bells(T0 + (A + BRK + b) * bar, b)
put(boom(2.0, 90, 30), t_end, 0.7)
for i, fq in enumerate([659.3, 587.3, 523.3, 493.9]):            # the music box, once more, to close
    put(music_box(fq, 1.6), t_end + 0.3 + i * 0.45, 0.6, 0.2 * math.sin(i))
L = np.tanh(L * 1.1) / np.tanh(1.1); R = np.tanh(R * 1.1) / np.tanh(1.1)
peak = max(np.max(np.abs(L)), np.max(np.abs(R)))
L *= 0.9 / peak; R *= 0.9 / peak
fade = gain_env([(0, 1), (DUR - 1.5, 1), (DUR, 0)])
L *= fade; R *= fade
with wave.open("someone_lives_in_our_attic_beat.wav", "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes((np.stack([L, R], 1) * 32767).astype(np.int16).tobytes())
print("wrote", round(DUR, 1), "s; beat ends at", round(t_end, 1))
