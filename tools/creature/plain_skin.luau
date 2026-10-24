--[[
	plain_skin.luau <in.rbxm> <out.rbxm> — (v114) the creature's body without its raw, bloody colour map: the
	SurfaceAppearance keeps only the normal map (the sculpted detail), the colour comes from the part
	(Rig.SkinColor, charcoal), and the wet roughness/metalness maps go too. The owner found the full-colour
	body "a bit too much"; with the porcelain mask back on (Rig.MaskParts) he's the old Curtis on a real body.
	Run from the repo root after make_asset.luau:
		lune run tools/creature/plain_skin.luau assets/Creature.rbxm assets/Creature.rbxm
]]
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local model = roblox.deserializeModel(fs.readFile(process.args[1]))[1]
local body = model:FindFirstChild("Body")
local sa = body:FindFirstChildOfClass("SurfaceAppearance")
sa.ColorMapContent = roblox.Content.none
sa.RoughnessMapContent = roblox.Content.none
sa.MetalnessMapContent = roblox.Content.none
body.Color = roblox.Color3.fromRGB(52, 49, 49)
fs.writeFile(process.args[2], roblox.serializeModel({ model }))
print("plain_skin:", tostring(sa.NormalMapContent), "normal map kept")
