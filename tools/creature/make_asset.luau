--[[
	make_asset.luau <source.rbxm> <out.rbxm> — the creature's body for the game (v112): the Creator Store
	skin-walker (asset 17737124382, a single skinned MeshPart with a Rigify skeleton and PBR maps),
	stripped down to what renders: the MeshPart ("Body"), its SurfaceAppearance and its Bones. Every
	script, value object, AnimationController and stored pose is dropped. Run from the repo root:
	  lune run tools/creature/make_asset.luau <cache>/17737124382.bin assets/Creature.rbxm
]]
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local src, out = process.args[1], process.args[2]
local roots = roblox.deserializeModel(fs.readFile(src))
local body
for _, r in roots do
	for _, d in r:GetDescendants() do
		if d:IsA("MeshPart") and d:FindFirstChildOfClass("Bone") then
			body = d
		end
	end
end
assert(body, "no skinned MeshPart")
local keep = { Bone = true, SurfaceAppearance = true }
local function prune(inst)
	for _, c in inst:GetChildren() do
		if not keep[c.ClassName] then
			c:Destroy()
		else
			prune(c)
		end
	end
end
prune(body)
body.Name = "Body"
body.Anchored = false
body.CanCollide = false
body.CanQuery = false
body.CanTouch = false
body.Massless = true
body.CastShadow = true
local model = roblox.Instance.new("Model")
model.Name = "Creature"
body.Parent = model
-- (rojo 7.4.4 predates the Content-typed properties: write the classic ContentId ones too, which every
-- engine version reads)
local function id(v)
	return v and string.match(tostring(v), "rbxassetid://%d+")
end
local function try(inst, prop, value)
	local ok, err = pcall(function()
		inst[prop] = value
	end)
	if not ok then
		print("  can't set", prop, err)
	end
end
try(body, "MeshId", id(body.MeshContent))
local sa0 = body:FindFirstChildOfClass("SurfaceAppearance")
if sa0 then
	for _, k in { "ColorMap", "NormalMap", "RoughnessMap", "MetalnessMap" } do
		local ok, v = pcall(function()
			return sa0[k .. "Content"]
		end)
		if ok and v then
			try(sa0, k, id(v))
		end
	end
end
local n = 0
for _, d in model:GetDescendants() do
	if d:IsA("Bone") then n += 1 end
end
local sa = body:FindFirstChildOfClass("SurfaceAppearance")
print("body", body.Size, "bones", n)
fs.writeFile(out, roblox.serializeModel({ model }))
print("wrote", out)
