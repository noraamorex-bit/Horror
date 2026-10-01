# Reel 2: "POV: you hid under the bed"

`../../home_alone_reel_2.mp4` is 1080x1920, 30 fps, 26 s. One locked-off camera sits in the game's own under-the-bed hiding view in the master bedroom. He comes in, checks the wardrobe off-screen ("1 / 2"), stands at the bed ("2 / 2"), leaves, and then drops into the gap upside down.

Same pipeline as reel 1, with these differences:
- `film2.mjs` adds a door that swings open (`door` per frame, hinge set per shot).
- `creature_frames2.luau` adds `pitch` to the rig's root, used for hanging upside down.
- `comp2.mjs` adds the game's "Holding breath" meter, the hiding-spot counter, dust in the gap and the end card.
- `audio.py` is fully synthesized. His footsteps are timed from his real stride phase.
