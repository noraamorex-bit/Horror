--[[
	skin_frames.luau <frames_in.json> <out.json> — the v112 creature for the reels' film2 renders:
	runs the game's own src/shared/SkinPose.luau on assets/Creature.rbxm and writes, per frame, every
	bone's Transform plus where he stands, so film2.mjs (a creature file with "skin") draws the real
	skinned mesh posed exactly as the client poses it.
	frames_in.json: [{ "f": 12, "pos": {"x":..,"y":..,"z":..} (feet on the floor), "yaw": 0 (0 faces -Z),
	                   "gait": "Walk", "phase": 1.2, "t": 0.5, "seed": 3,
	                   "opts": { "Look": [yaw, pitch], "Duck": 0..1.6, "Scream": 0..1, ... } }, ...]
	Out: { skin = { scale, bones = [{ name, parent, rest }] }, frames = { [f] = { root = {x, y, z, yaw},
	       tr = { [bone] = {12} }, glow = {x, y, z} } } }
	Run from the repo root: lune run tools/creature/skin_frames.luau in.json out.json [mask.json]
	(reels) A frame can also carry "head": { pos, look, roll } (the mask placed there) and "noSkin" (no body).
	(v114) With mask.json (tools/harness/mask_dump.luau) he wears the porcelain mask and the hair, kept on
	the posed head bone exactly as the client does (client Creature), and the body gets the server's plain colour:
	parts = the mask's parts (film2's part format), each frame's "parts" their frames.
]]
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local process = require("@lune/process")
local CFrame, Vector3 = roblox.CFrame, roblox.Vector3

local env = { CFrame = CFrame, Vector3 = Vector3, math = math, table = table, string = string, pairs = pairs,
	ipairs = ipairs, type = type, typeof = typeof, pcall = pcall, error = error, setmetatable = setmetatable, tostring = tostring,
	tonumber = tonumber, print = print, assert = assert, select = select, next = next }
local SkinPose = luau.load(fs.readFile("src/shared/SkinPose.luau"), { debugName = "SkinPose", environment = env })()
local CreaturePose = luau.load(fs.readFile("src/shared/CreaturePose.luau"), { debugName = "CreaturePose", environment = env })()
local SCALE = SkinPose.Scale

local model = roblox.deserializeModel(fs.readFile("assets/Creature.rbxm"))[1]
local body = model:FindFirstChild("Body")
SkinPose.stretch(body) -- (v147: as the server does)
local rig = SkinPose.rig(body)
local half = body.Size.Y / 2 -- (mesh units: the soles are at -half)

local function cf12(c)
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = c:GetComponents()
	return { x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 }
end
local HEAD = SkinPose.Joints.Head
local bones, byName = {}, {}
for _, d in body:GetDescendants() do
	if d:IsA("Bone") then
		table.insert(bones, { name = d.Name, parent = d.Parent:IsA("Bone") and d.Parent.Name or nil, rest = cf12(d.CFrame) })
		byName[d.Name] = d
	end
end
-- a bone's frame in the body's space, posed (by name: lune hands out new userdata per lookup)
local function posed(name, tr)
	local b = byName[name]
	local chain = {}
	while b and b:IsA("Bone") do
		table.insert(chain, 1, b)
		b = b.Parent
	end
	local cf = CFrame.identity
	for _, x in chain do
		cf = cf * x.CFrame * (tr[x.Name] or CFrame.identity)
	end
	return cf
end
local function restOf(name)
	return posed(name, {})
end
-- (v156) the face light: in front of his eyes, as Rig places it (1.6 studs out, 0.1 up)
local eyeMid = (restOf("Base HumanLEye").Position + restOf("Base HumanHeadREye").Position) / 2
local faceRest = restOf(HEAD):Inverse() * CFrame.new(eyeMid + Vector3.new(0, 0.1 / SCALE, -1.6 / SCALE))

local function scaled(c)
	return CFrame.new(c.Position * SCALE) * (c - c.Position)
end
local function cfOf(a)
	return CFrame.new(a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10], a[11], a[12])
end
local mask = process.args[3] and serde.decode("json", fs.readFile(process.args[3])) or nil
local bodyOffset = CFrame.new(0, half * SCALE, 0) -- (the body's centre above his feet, in studs)
local relHead
if mask then
	-- the Head part relative to the head bone, at rest (in studs, model space)
	relHead = (bodyOffset * scaled(restOf(HEAD))):Inverse() * cfOf(mask.head)
end

local frames = serde.decode("json", fs.readFile(process.args[1]))
local out = {}
for _, f in frames do
	local opts = f.opts or {}
	opts.Scale = 1 -- (posed in the mesh's own units; film2 scales the whole body)
	local pose = SkinPose.get(f.gait or "Idle", f.phase or 0, f.t or 0, f.seed or 1, opts)
	local tr, byBone = {}, {}
	for bone, c in SkinPose.transforms(rig, pose) do
		tr[bone.Name] = cf12(c)
		byBone[bone.Name] = c
	end
	local yaw = f.yaw or 0
	local feet = Vector3.new(f.pos.x, f.pos.y, f.pos.z)
	local place = CFrame.new(feet) * CFrame.Angles(0, yaw, 0)
	local face = (posed(HEAD, byBone) * faceRest).Position
	local g = place:PointToWorldSpace((face + Vector3.new(0, half, 0)) * SCALE)
	local fr = { root = { feet.X, feet.Y, feet.Z, yaw }, tr = tr, glow = { g.X, g.Y, g.Z }, noSkin = f.noSkin }
	if mask then
		local headCF = place * bodyOffset * scaled(posed(HEAD, byBone)) * relHead
		-- (reels) "head": { pos, look, roll? } puts the mask and hair exactly there, whatever the body does
		-- (with "noSkin" film2 draws only them: his face in the dark at the back of a closet)
		if f.head then
			local hp, hl = f.head.pos, f.head.look
			-- (the direction is turned for the way film2 puts these frames down: (dx, -dy, -dz) is what turns
			-- the mask's face to "look" in the render; probed from along x, along z and from below)
			local at = Vector3.new(hp[1], hp[2], hp[3])
			local d = Vector3.new(hl[1], hl[2], hl[3]) - at
			headCF = CFrame.lookAt(at, at + Vector3.new(d.X, -d.Y, -d.Z))
			headCF *= CFrame.Angles(0, 0, f.head.roll or 0)
			fr.glow = { hp[1], hp[2], hp[3] }
		end
		local open = math.clamp((pose.Mouth or 0) * 1.2, 0, 1)
		fr.parts = {}
		for i, p in mask.parts do
			local cf = headCF * cfOf(mask.rel[i])
			local off, sc = CreaturePose.jawOffset(p.n, open)
			if off then
				cf = cf * CFrame.new(off.X, off.Y, off.Z)
			end
			local c = { cf:GetComponents() }
			if sc then
				for j = 0, 2 do
					c[4 + j * 3] *= sc.X
					c[5 + j * 3] *= sc.Y
					c[6 + j * 3] *= sc.Z
				end
			end
			fr.parts[i] = c
		end
	end
	out[tostring(f.f)] = fr
end
-- (v149+) unmasked, he wears the store colour map under Rig.SkinTint (film2: skin.tint); read from Rig.luau so reels follow the game
local tint = nil
if not mask then
	local r, g, b = fs.readFile("src/server/Intruder/Rig.luau"):match("Rig%.SkinTint%s*=%s*Color3%.fromRGB%((%d+),%s*(%d+),%s*(%d+)%)")
	if r then
		tint = { tonumber(r), tonumber(g), tonumber(b) }
	end
end
-- (v156) his 14 skinned pieces: mesh, colour map, and where each sits on the body (its mesh space -> the body's)
local pieces = {}
for _, p in model:GetChildren() do
	if p:IsA("MeshPart") and p ~= body then
		local sa = p:FindFirstChildOfClass("SurfaceAppearance")
		table.insert(pieces, { name = p.Name, mesh = string.match(tostring(p.MeshContent.Uri), "%d+"),
			tex = sa and string.match(tostring(sa.ColorMapContent.Uri), "%d+") or string.match(tostring(p.TextureContent.Uri), "%d+"),
			rel = cf12(body.CFrame:ToObjectSpace(p.CFrame)) })
	end
end
fs.writeFile(process.args[2], serde.encode("json", { skin = { scale = SCALE, half = half, bones = bones, color = mask and mask.color or nil, tint = tint, pieces = pieces },
	parts = mask and mask.parts or nil, frames = out }))
print("skin_frames:", #frames, "frames")
