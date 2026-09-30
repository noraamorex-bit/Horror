Store art pipeline (the images in `marketing/`):

1. `lune run dump_world.luau` (harness) exports the built map to `world.json`.
2. `node render_night.mjs world.json views_final.json out` renders night scenes (W/H env for size),
   using the house's own lamps, glowing windows and a silhouette of Curtis.
3. `node compose.mjs spec.json` adds the title type (Oswald/Inter), glow, vignette, grain and rain.

Needs Node with `playwright` and `three` installed next to the scripts.

Teaser videos (`marketing/teaser_*.mp4`):

4. `M=<dir> python3 gen_frames.py` writes per-frame camera views (24 fps) for both teasers.
5. `W=720 H=1280 node render_night.mjs world.json views_hall.json hall` renders the frames.
6. `node captions.mjs captions.json` renders transparent caption cards.
7. `assemble.sh` upscales, adds grain and a vignette, overlays the captions, adds the synthesized
   soundtrack (ffmpeg `aevalsrc`, commands in the git history) and encodes H.264/AAC.
