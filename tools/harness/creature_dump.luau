local H = require("./env")
local ok, err = pcall(function()
	local R = H.roblox
	local Builder = H.load("Server/World/Builder")
	local Rig = H.load("Server/Intruder/Rig")
	local Pose = H.load("RS/Shared/CreaturePose")
	local folder = H.Instance.new("Folder")
	local poses = { { "Stare", 0, 0.01 }, { "Walk", 1.2, 0.5 }, { "Chase", 1.0, 0.2 }, { "Chase", 2.6, 0.9 }, { "Reach", 0, 0.4 }, { "Stunned", 0, 0.1 }, { "Search", 0.4, 2.2 } }
	for i, ps in poses do
		local model = Rig.build(Builder)
		local raw = H.unwrap(model)
		local x = (i - 1) * 7
		-- rest CFrames
		local rest, byK = {}, {}
		local kc = 0
		local function K(p) return p:GetAttribute("K") end
		for _, d in raw:GetDescendants() do
			if d:IsA("BasePart") then kc += 1; d:SetAttribute("K", kc); rest[kc] = d.CFrame; byK[kc] = d end
		end
		local P = Pose.get(ps[1], ps[2], ps[3], 1)
		local posed = {}
		local hrp = raw:FindFirstChild("HumanoidRootPart")
		posed[K(hrp)] = R.CFrame.new(x, 0, 0) * rest[K(hrp)]
		-- solve joints breadth-first
		local motors = {}
		for _, d in raw:GetDescendants() do if d:IsA("Motor6D") then table.insert(motors, d) end end
		local changed = true
		while changed do
			changed = false
			for _, m in motors do
				if posed[K(m.Part0)] and not posed[K(m.Part1)] then
					local T = P[m.Name] or R.CFrame.new()
					posed[K(m.Part1)] = posed[K(m.Part0)] * m.C0 * T * m.C1:Inverse()
					changed = true
				end
			end
		end
		-- welded decorations follow their body part
		for _, d in raw:GetDescendants() do
			if d:IsA("WeldConstraint") and posed[K(d.Part0)] and not posed[K(d.Part1)] then
				posed[K(d.Part1)] = posed[K(d.Part0)] * rest[K(d.Part0)]:Inverse() * rest[K(d.Part1)]
			end
		end
		for k, cf in posed do byK[k].CFrame = cf end
		raw.Parent = H.unwrap(folder)
	end
	-- a player for scale (6.2 tall) and a floor
	local ref = R.Instance.new("Part"); ref.Size = R.Vector3.new(2, 6.2, 1); ref.CFrame = R.CFrame.new(-5, 3.1, 0); ref.Color = R.Color3.fromRGB(90, 110, 140); ref.Parent = H.unwrap(folder)
	local floor = R.Instance.new("Part"); floor.Size = R.Vector3.new(80, 0.2, 30); floor.CFrame = R.CFrame.new(20, -0.1, 0); floor.Color = R.Color3.fromRGB(60, 45, 35); floor.Parent = H.unwrap(folder)
	require("./dump")(H.unwrap(folder), "../render/creature.json")
end)
print(ok and "CREATURE OK" or ("CREATURE FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
