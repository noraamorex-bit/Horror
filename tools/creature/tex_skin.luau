--[[
	tex_skin.luau <in.rbxm> <out.rbxm> — (v149, the owner: "the monster model... is too plain the face looks dumb. Make it proper and
	actually scary and texture") the creature's body with its own painted skin again: the colour map (pale grey hide, dark veins, the
	raw red round the maw), the normal and roughness maps; tinted darker and colder through the SurfaceAppearance's Color (Rig.SkinTint),
	so it's grimy rather than bright, and no metalness map (the source reuses its roughness map there: it made him shine like metal).
	Replaces v114's plain_skin.luau. Run from the repo root after make_asset.luau:
		lune run tools/creature/make_asset.luau <cache>/17737124382.bin assets/Creature.rbxm
		lune run tools/creature/tex_skin.luau assets/Creature.rbxm assets/Creature.rbxm
]]
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local TINT = roblox.Color3.fromRGB(212, 202, 200) -- (keep in step with Rig.SkinTint)
local model = roblox.deserializeModel(fs.readFile(process.args[1]))[1]
local body = model:FindFirstChild("Body")
local sa = body:FindFirstChildOfClass("SurfaceAppearance")
assert(tostring(sa.ColorMapContent) ~= "Content(None)", "no colour map: run make_asset.luau on the Creator Store source first")
sa.MetalnessMapContent = roblox.Content.none
pcall(function()
	(sa :: any).MetalnessMap = ""
end)
sa.Color = TINT
fs.writeFile(process.args[2], roblox.serializeModel({ model }))
print("tex_skin:", tostring(sa.ColorMapContent), "tint", tostring(sa.Color))
