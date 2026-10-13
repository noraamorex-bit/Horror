# Asset tools: Creator Store models, checked before they go in the game

The API key has `legacy-asset:manage` (asset downloads), added by the owner on 13 Oct. Everything
here runs from the repo root; `npm install` in `tools/assets` first (draco3d, three, playwright).
Scratch output goes wherever you point it (not in the repo).

1. **Find**: `python3 tools/assets/search.py <out> "dining chair" 18` → `<out>/dining_chair.png`, a
   contact sheet of Creator Store thumbnails with their asset ids (and a .json with names/creators).
2. **Look**: `python3 tools/assets/fetch.py <cache> <id>`, then
   `lune run tools/assets/inspect.luau <cache>/<id>.bin <cache>/<id>.json` (parts, sizes, meshes,
   textures, anything that would need stripping: a model full of Scripts / ScreenGuis /
   RemoteFunctions is a red flag, skip it), then
   `node tools/assets/preview.mjs <cache>/<id>.json <cache> <cache>/<id>.png` → four views (its -Z
   front, +X side, back, top) on a 1-stud grid with a 5.5-stud person and an arrow along -Z.
   Find which way its front faces: our furniture faces -Z, so a model facing +Z needs `Yaw = 180`,
   facing -X `Yaw = -90`, facing +X `Yaw = 90`.
   (Unions render as plain boxes here: they can't be checked, so prefer mesh models. A mesh the
   key can't download, "not authorized", is private and won't load in our game either.)
3. **Place**: add it to `Props.Models` in `src/server/World/Props.luau` (`{ Id, Yaw, Fit, Back }`,
   see the comment there). Our placeholders are matched by their `PropKey` attribute (or model
   name); Kit furniture records its frame as its WorldPivot.
4. **Check in the house**: `cd tools/harness && lune run stage_dump.luau <out>/stage.json`, then
   `node tools/assets/stage.mjs <out>/stage.json <cache> views.json <outDir>` renders the house with
   the props placed exactly as World/Props fit() does (views.json: `[{name, pos, look, fov, radius}]`).
5. `tools/harness/props_test.luau` tests the fitting itself (turn, scale, floor, back to the wall).

Don't swap things players use or hide in (beds, wardrobes, desks you hide under, the fridge, oven,
sink, TV) or that other things sit on at fixed heights (coffee/dining tables, nightstands,
dressers): a different shape there breaks hiding views or leaves cups floating.
