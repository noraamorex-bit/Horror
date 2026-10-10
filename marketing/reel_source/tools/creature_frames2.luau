-- frames_in.json: [{ f, pos = {x,y,z} (feet on floor), yaw, gait, phase, t, duck, lean }]
-- -> ../reel2/creature_frames.json: { parts = [{sh,s,col,mat,m,n}], frames = { [f] = {{12 floats}...} } }
local H = require("./env")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")
local DIR = process.args[1] or "../reel2"
local ok, err = pcall(function()
	local R = H.roblox
	local Builder = H.load("Server/World/Builder")
	local Rig = H.load("Server/Intruder/Rig")
	local Pose = H.load("RS/Shared/CreaturePose")
	local model = Rig.build(Builder)
	local raw = H.unwrap(model)
	local list, rest, idx = {}, {}, {}
	local kc = 0
	for _, d in raw:GetDescendants() do
		if d:IsA("BasePart") then
			kc += 1
			d:SetAttribute("K", kc)
			rest[kc] = d.CFrame
			table.insert(list, d)
			idx[kc] = #list
		end
	end
	local function K(p) return p:GetAttribute("K") end
	local parts = {}
	for _, d in list do
		local shape = "Block"
		if d.ClassName == "WedgePart" then shape = "Wedge" elseif d.ClassName == "Part" then shape = d.Shape.Name end
		local mesh = d:FindFirstChildOfClass("SpecialMesh")
		table.insert(parts, {
			n = d.Name, sh = shape, s = { d.Size.X, d.Size.Y, d.Size.Z },
			col = { math.floor(d.Color.R * 255), math.floor(d.Color.G * 255), math.floor(d.Color.B * 255) },
			mat = d.Material.Name, tr = d.Transparency,
			m = mesh and { t = mesh.MeshType.Name, s = { 1, 1, 1 }, o = { 0, 0, 0 } } or nil,
		})
	end
	local motors = {}
	for _, d in raw:GetDescendants() do if d:IsA("Motor6D") then table.insert(motors, d) end end
	local welds = {}
	for _, d in raw:GetDescendants() do if d:IsA("WeldConstraint") then table.insert(welds, d) end end
	local hrp = raw:FindFirstChild("HumanoidRootPart")
	local input = serde.decode("json", fs.readFile(DIR .. "/frames_in.json"))
	local frames = {}
	for _, fr in input do
		local P = Pose.get(fr.gait, fr.phase or 0, fr.t or 0, 1)
		local duck = fr.duck or 0
		if duck > 0 then
			P.Root = R.CFrame.new(0, -duck * 0.45, 0) * (P.Root or R.CFrame.new()) * R.CFrame.Angles(-duck * 0.3, 0, 0)
		end
		if fr.neck then
			P.Neck = (P.Neck or R.CFrame.new()) * R.CFrame.Angles(fr.neck[1], fr.neck[2], fr.neck[3])
		end
		local posed = {}
		posed[K(hrp)] = R.CFrame.new(fr.pos[1], fr.pos[2], fr.pos[3]) * R.CFrame.Angles(0, fr.yaw or 0, 0) * R.CFrame.Angles(fr.pitch or 0, 0, 0) * rest[K(hrp)]
		local changed = true
		while changed do
			changed = false
			for _, m in motors do
				if posed[K(m.Part0)] and not posed[K(m.Part1)] then
					posed[K(m.Part1)] = posed[K(m.Part0)] * m.C0 * (P[m.Name] or R.CFrame.new()) * m.C1:Inverse()
					changed = true
				end
			end
		end
		for _ = 1, 3 do
			for _, w in welds do
				if posed[K(w.Part0)] and not posed[K(w.Part1)] then
					posed[K(w.Part1)] = posed[K(w.Part0)] * rest[K(w.Part0)]:Inverse() * rest[K(w.Part1)]
				end
			end
		end
		local out = {}
		for i, d in list do
			local cf = posed[K(d)] or rest[K(d)]
			local c = { cf:GetComponents() }
			for j = 1, 12 do c[j] = math.floor(c[j] * 10000 + 0.5) / 10000 end
			out[i] = c
		end
		frames[tostring(fr.f)] = out
	end
	fs.writeFile(DIR .. "/creature_frames.json", serde.encode("json", { parts = parts, frames = frames }))
	print("CREATURE FRAMES", #input)
end)
if not ok then print("FAIL", err) end
