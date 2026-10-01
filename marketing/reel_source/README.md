# How the reel was made

`home_alone_reel.mp4` is 1080x1920, 30 fps, 27 s, rendered from the real game map and creature rig. Everything in it is original: rendered from the game, with synthesized sound.

1. `timeline.py` lays out 8 shots (camera, lights, flashlight, lightning, where he is and how he moves) and writes the per-frame spec.
2. `creature_frames.luau` (lune, from `tools/harness`) poses the real rig (`server/Intruder/Rig`) with the game's own animation code (`shared/CreaturePose`) for every frame.
3. `film.mjs` renders each frame in three.js (Playwright/Chromium) from a dump of the built world.
4. `comp.mjs` adds the titles, the phone notifications, the closet-door slit, flashes, colour split, rain, grain and the end card.
5. `audio.py` synthesizes the soundtrack with numpy (drone, rain, thunder, music box, phone buzz, power-down, footsteps synced to his stride, heartbeat, scream). No samples are used.
6. ffmpeg: `-c:v libx264 -crf 17 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart`.
