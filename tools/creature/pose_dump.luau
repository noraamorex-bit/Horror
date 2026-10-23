--[[
	pose_dump.luau <frames.json> <out.json> — runs the game's own src/shared/SkinPose.luau (the v112
	creature's animation) on assets/Creature.rbxm and writes every bone's rest frame and, per frame,
	its Transform, for skinview.mjs to deform the mesh with. What renders here is what the client does.
	frames.json: [{ "gait": "Walk", "phase": 1.2, "t": 0.5, "seed": 3, "opts": {...} }, ...]
	Run from the repo root: lune run tools/creature/pose_dump.luau in.json out.json
]]
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local process = require("@lune/process")

local env = { CFrame = roblox.CFrame, Vector3 = roblox.Vector3, math = math, table = table, string = string, pairs = pairs,
	ipairs = ipairs, type = type, typeof = typeof, pcall = pcall, error = error, setmetatable = setmetatable, tostring = tostring,
	tonumber = tonumber, print = print, assert = assert, select = select, next = next }
local SkinPose = luau.load(fs.readFile("src/shared/SkinPose.luau"), { debugName = "SkinPose", environment = env })()

local model = roblox.deserializeModel(fs.readFile("assets/Creature.rbxm"))[1]
local body = model:FindFirstChild("Body")
local rig = SkinPose.rig(body)

local function cf12(c)
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = c:GetComponents()
	return { x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 }
end
local bones = {}
for _, d in body:GetDescendants() do
	if d:IsA("Bone") then
		table.insert(bones, { name = d.Name, parent = d.Parent:IsA("Bone") and d.Parent.Name or nil, rest = cf12(d.CFrame) })
	end
end
local frames = serde.decode("json", fs.readFile(process.args[1]))
local out = {}
for i, f in frames do
	local pose = SkinPose.get(f.gait, f.phase or 0, f.t or 0, f.seed or 1, f.opts)
	local tr = SkinPose.transforms(rig, pose)
	local o = {}
	for bone, c in tr do
		o[bone.Name] = cf12(c)
	end
	out[i] = { transforms = o, root = pose.Root and { pose.Root.X, pose.Root.Y, pose.Root.Z } or nil }
end
fs.writeFile(process.args[2], serde.encode("json", { bones = bones, size = { body.Size.X, body.Size.Y, body.Size.Z }, frames = out }))
print("pose_dump:", #frames, "frames,", #bones, "bones")
