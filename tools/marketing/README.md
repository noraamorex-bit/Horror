Store art pipeline (the images in `marketing/`):

1. `lune run dump_world.luau` (harness) exports the built map to `world.json`.
2. `node render_night.mjs world.json views_final.json out` renders night scenes (W/H env for size),
   using the house's own lamps, glowing windows and a silhouette of Curtis.
3. `node compose.mjs spec.json` adds the title type (Oswald/Inter), glow, vignette, grain and rain.

Needs Node with `playwright` and `three` installed next to the scripts.
