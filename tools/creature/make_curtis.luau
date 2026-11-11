--[[
	make_curtis.luau <source.rbxm> <out.rbxm> — (v156, the owner: "I already said i don't like this model for monster why did you
	bring it back. Not so gory and regular humanoid looking but also really scary") his new body: a gaunt, starved man (Creator Store
	9324817907: 14 skinned mesh pieces on a biped skeleton with a jaw and eyelids), rebuilt into the shape the game expects:
	Model "Creature" > MeshPart "Body" (invisible, the size of the whole figure) holding the bones, and the 14 pieces welded to it.
	Each piece gets a SurfaceAppearance with the source's colour map and Rig.SkinTint (pale, cold). Run from the repo root:
		python3 tools/assets/fetch.py <cache> 9324817907
		lune run tools/creature/make_curtis.luau <cache>/9324817907.bin assets/Creature.rbxm
]]
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local CFrame, Vector3, Instance = roblox.CFrame, roblox.Vector3, roblox.Instance

local TINT = roblox.Color3.fromRGB(232, 228, 226) -- (keep in step with Rig.SkinTint)
local src = roblox.deserializeModel(fs.readFile(process.args[1]))[1]
local rootPart = src:FindFirstChild("RootPart")
assert(rootPart, "no RootPart: not the expected source")

local pieces = {}
for _, c in src:GetChildren() do
	if c:IsA("MeshPart") then
		table.insert(pieces, c)
	end
end
assert(#pieces == 14, "expected 14 mesh pieces, got " .. #pieces)

-- the figure's box (in the root part's frame, axis-aligned)
local mn, mx = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
for _, p in pieces do
	local rel = rootPart.CFrame:ToObjectSpace(p.CFrame)
	local h = p.Size / 2
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local q = rel * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)
				mn = Vector3.new(math.min(mn.X, q.X), math.min(mn.Y, q.Y), math.min(mn.Z, q.Z))
				mx = Vector3.new(math.max(mx.X, q.X), math.max(mx.Y, q.Y), math.max(mx.Z, q.Z))
			end
		end
	end
end
local centre = (mn + mx) / 2
local model = Instance.new("Model")
model.Name = "Creature"
local body = Instance.new("MeshPart")
body.Name = "Body"
body.Size = mx - mn
body.CFrame = rootPart.CFrame * CFrame.new(centre)
body.Transparency = 1
body.Anchored = false
body.CanCollide = false
body.CanQuery = false
body.CanTouch = false
body.Massless = true
body.CastShadow = false
body.Parent = model
-- the skeleton moves onto the body (same place in the world)
local toBody = body.CFrame:Inverse() * rootPart.CFrame
for _, b in rootPart:GetChildren() do
	if b:IsA("Bone") then
		b.CFrame = toBody * b.CFrame
		b.Parent = body
	end
end
local function idOf(uri)
	return string.match(tostring(uri), "id=(%d+)") or string.match(tostring(uri), "rbxassetid://(%d+)")
end
for _, p in pieces do
	for _, m in p:GetChildren() do
		m:Destroy() -- (the Motor6Ds to the old root)
	end
	local mesh = idOf(p.MeshContent.Uri)
	local tex = idOf(p.TextureContent.Uri)
	assert(mesh and tex, "piece without a mesh or texture: " .. p.Name)
	p.MeshContent = roblox.Content.fromUri("rbxassetid://" .. mesh)
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = true
	p:SetAttribute("SkinPiece", true)
	local sa = Instance.new("SurfaceAppearance")
	sa.ColorMapContent = roblox.Content.fromUri("rbxassetid://" .. tex)
	sa.Color = TINT
	sa.Parent = p
	local w = Instance.new("WeldConstraint")
	w.Part0 = body
	w.Part1 = p
	w.Parent = p
	p.Parent = model
end
model.PrimaryPart = body
fs.writeFile(process.args[2], roblox.serializeModel({ model }))
local nb = 0
for _, d in body:GetDescendants() do
	if d:IsA("Bone") then
		nb += 1
	end
end
print(string.format("make_curtis: %d pieces, %d bones, body %.1f x %.1f x %.1f", #pieces, nb, body.Size.X, body.Size.Y, body.Size.Z))
