# Reel 9: "the attic crew" — the whole reel is a phone at 3:12 AM. Writes timeline.json for comp8.mjs and audio.py.
import json
S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
LOCK, CHAT, ZOOM0, ZOOM1, RING, CALL, SCARE, AFTER, END, DUR = 0.0, 1.7, 18.9, 20.8, 26.0, 27.2, 30.7, 31.7, 34.5, 38.5
# (t, who, kind, text)   who: maya / jake / me / sys     kind: text / video / photo
MSGS = [
    (0.3, "maya", "text", "guys"),
    (0.9, "maya", "text", "someone is in my attic"),
    (3.6, "jake", "text", "lol what"),
    (4.5, "maya", "text", "i keep hearing footsteps above my room"),
    (5.8, "me", "text", "it's an old house. it's the wind"),
    (6.9, "maya", "video", ""),
    (10.6, "maya", "text", "the wind walks?? 💀"),
    (11.6, "jake", "text", "maya that's not funny"),
    (12.6, "maya", "text", "my parents are out of town"),
    (13.6, "me", "text", "lock your door rn"),
    (14.8, "maya", "photo", ""),
    (15.9, "maya", "text", "the attic hatch is open"),
    (17.0, "maya", "text", "it was closed when i went to bed"),
    (18.1, "jake", "text", "wait. zoom into the photo"),
    (21.0, "jake", "text", "something is IN the hatch"),
    (22.0, "me", "text", "MAYA GET OUT"),
    (24.5, "maya", "text", "i can't move"),
    (25.3, "maya", "text", "i'm calling you"),
    (AFTER + 0.15, "sys", "text", "video call ended · 0:03"),
    (AFTER + 0.6, "me", "text", "maya??"),
    (AFTER + 1.1, "me", "text", "MAYA ANSWER"),
    (AFTER + 1.6, "sys", "text", "maya left the chat"),
]
# typing dots shown before these (start, end, who)
TYPING = [(2.0, 3.6, "jake"), (4.0, 4.5, "maya"), (10.1, 10.6, "maya"), (11.1, 11.6, "jake"), (12.1, 12.6, "maya"),
          (15.4, 15.9, "maya"), (16.4, 17.0, "maya"), (17.6, 18.1, "jake"), (20.85, 21.0, "jake"), (22.6, 24.5, "maya"), (24.9, 25.3, "maya")]
CCTV = [f"{S}/reel/raw/{450 + i:04d}.png" for i in range(102)]          # the baby monitor clip (3.4 s)
CALLF = [f"{S}/reel9/raw/{i:04d}.png" for i in range(105)]              # the video call (3.5 s)
SCAREF = [f"{S}/reel/raw/{592 + i:04d}.png" for i in range(30)]         # the jumpscare
json.dump({"fps": FPS, "phases": {"lock": LOCK, "chat": CHAT, "zoom0": ZOOM0, "zoom1": ZOOM1, "ring": RING, "call": CALL,
                                  "scare": SCARE, "after": AFTER, "end": END, "dur": DUR},
           "msgs": [{"t": t, "who": w, "kind": k, "text": x} for t, w, k, x in MSGS],
           "typing": [{"t0": a, "t1": b, "who": w} for a, b, w in TYPING],
           "cctv": CCTV, "call": CALLF, "scare": SCAREF,
           "photo": f"{S}/reel9/raw/0105.png", "wall": f"{S}/reel/raw/0130.png"}, open("timeline.json", "w"), ensure_ascii=False)
print("frames", int(DUR * FPS))
