-- fit_weapon (v166): a Creator Store weapon (inspect.luau's JSON) placed in the tool's frame exactly as ToolService does
-- (shared/WeaponFit + Config.Weapons.List[k].Model), written back as the same JSON, with a red box where the hand is and a
-- 0.6-stud wide grey slab as the forearm (+Z behind the hand), for tools/assets/preview.mjs.
--   lune run fit_weapon.luau <Weapon key> <cache dir> <out.json>
local H = require("./env")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local key, cache, out = process.args[1], process.args[2], process.args[3]
local Config = H.load("RS/Shared/Config")
local Fit = H.load("RS/Shared/WeaponFit")
local w = Config.Weapons.List[key]
assert(w and w.Model, "no Model for " .. tostring(key))
local m = serde.decode("json", fs.readFile(cache .. "/" .. w.Model.Id .. ".json"))

local boxes = {}
for _, p in m.Parts do
	if (p.Transparency or 0) < 0.99 then
		table.insert(boxes, { CFrame = roblox.CFrame.new(table.unpack(p.CFrame)), Size = roblox.Vector3.new(table.unpack(p.Size)) })
	end
end
local map, k = Fit.solve(boxes, w.Model)
local parts = {}
for _, p in m.Parts do
	local cf = map(roblox.CFrame.new(table.unpack(p.CFrame)))
	local q = table.clone(p)
	q.CFrame = { cf:GetComponents() }
	q.Size = { p.Size[1] * k, p.Size[2] * k, p.Size[3] * k }
	if q.Special then
		q.Special = table.clone(q.Special)
		local s, o = q.Special.Scale or { 1, 1, 1 }, q.Special.Offset or { 0, 0, 0 }
		q.Special.Scale = { s[1] * k, s[2] * k, s[3] * k }
		q.Special.Offset = { o[1] * k, o[2] * k, o[3] * k }
	end
	table.insert(parts, q)
end
local function block(name, size, pos, color)
	table.insert(parts, { Class = "Part", Name = name, Size = size, CFrame = { pos[1], pos[2], pos[3], 1, 0, 0, 0, 1, 0, 0, 0, 1 }, Color = color, Material = "Enum.Material.SmoothPlastic", Transparency = 0, Shape = "Enum.PartType.Block" })
end
block("Hand", { 0.45, 0.45, 0.45 }, { 0, 0, 0 }, { 230, 40, 40 })
block("Arm", { 0.5, 0.5, 2.2 }, { 0, 0, 1.3 }, { 120, 120, 120 })
local mn, mx = Fit.bounds((function()
	local b = {}
	for _, p in parts do
		table.insert(b, { CFrame = roblox.CFrame.new(table.unpack(p.CFrame)), Size = roblox.Vector3.new(table.unpack(p.Size)) })
	end
	return b
end)())
m.Parts = parts
m.Min = { mn.X, mn.Y, mn.Z }
m.Max = { mx.X, mx.Y, mx.Z }
m.Size = { mx.X - mn.X, mx.Y - mn.Y, mx.Z - mn.Z }
fs.writeFile(out, serde.encode("json", m))
print(string.format("%s: scale %.2f, box %.1f x %.1f x %.1f", key, k, mx.X - mn.X, mx.Y - mn.Y, mx.Z - mn.Z))
