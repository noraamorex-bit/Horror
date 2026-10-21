-- creature_test (v99): the new Curtis. The rig stands on y = 0 with his root where the navigator
-- expects it, nearly ten feet tall, every R15 joint there; an invisible eye point at the old head
-- height for the server's sight lines; nothing collides but the root. Every gait (and Peek) poses
-- every joint; standing idle, his head now and then turns right round. At the blackout his
-- footprints lie on the upstairs hall floor, clear of the stairwell. The new scares (YardFigure,
-- HallStare) are in the Director's list with their lines, and show a posed figure; the new sounds exist.
local H = require("./env")
local R = H.roblox
local V = R.Vector3.new

local ok, err = pcall(function()
	local Builder = H.load("Server/World/Builder")
	local Rig = H.load("Server/Intruder/Rig")
	local Pose = H.load("RS/Shared/CreaturePose")
	local model = H.unwrap(Rig.build(Builder))
	local root = model:FindFirstChild("HumanoidRootPart")
	assert(root and math.abs(root.CFrame.Position.Y - Rig.RootY) < 1e-3, "root at RootY")
	local head = model:FindFirstChild("Head")
	local top = head.CFrame.Position.Y + head.Size.Y / 2
	assert(top > 9.3 and top < 10.4, "nearly ten feet tall: " .. top)
	local lowest = math.huge
	local parts, colliders = 0, 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
			if d.CanCollide then colliders += 1 end
			lowest = math.min(lowest, d.CFrame.Position.Y - 0.2)
		end
	end
	assert(colliders == 1, "only the root collides")
	assert(lowest > -0.25 and lowest < 0.3, "standing on the floor: " .. lowest)
	print("rig ok: " .. parts .. " parts, top " .. string.format("%.2f", top))
	local motors = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") then motors[d.Name] = true end
	end
	for _, n in { "Root", "Waist", "Neck", "LeftShoulder", "RightShoulder", "LeftElbow", "RightElbow", "LeftWrist", "RightWrist",
		"LeftHip", "RightHip", "LeftKnee", "RightKnee", "LeftAnkle", "RightAnkle" } do
		assert(motors[n], "joint " .. n)
	end
	local eyes = model:FindFirstChild("Eyes", true)
	assert(eyes and eyes.Transparency == 1 and math.abs(eyes.CFrame.Position.Y - 7.82) < 0.01, "the eye point at the old head height")
	-- the face: a mask, sockets, a grin with teeth, hair
	local count = {}
	for _, d in model:GetDescendants() do count[d.Name] = (count[d.Name] or 0) + 1 end
	assert(count.Mask == 1 and count.EyeHole == 2 and (count.Tooth or 0) + (count.LowerTooth or 0) >= 15 and (count.Hair or 0) >= 20 and count.Glint == 2 and count.Maw == 1, "the face")
	print("face ok")
	-- (v100) jointed fingers; the mouth opens: the black stretches down from a still top edge and
	-- the lower teeth drop to its new bottom
	for _, side in { "Left", "Right" } do
		for i = 1, 4 do
			assert(motors[side .. "Finger" .. i], "finger joint " .. side .. i)
		end
	end
	local jaws = Pose.jawMeshes(model)
	local maw, lowTeeth = nil, 0
	for _, j in jaws do
		if j.Name == "Maw" then maw = j else lowTeeth += 1 end
	end
	assert(maw and lowTeeth == 9, "the mouth's moving parts: " .. #jaws)
	Pose.setJaw(jaws, 1)
	local mawPart = maw.Mesh.Parent
	local h = 0.17 * maw.Mesh.Scale.Y
	local topEdge = maw.Mesh.Offset.Y + h / 2
	assert(math.abs(topEdge - 0.085) < 1e-3 and h > 0.35, "the mouth opens downwards from its top edge")
	for _, j in jaws do
		if j.Name == "LowerTooth" then
			assert(j.Mesh.Offset.Y < -0.18, "the lower teeth drop with it")
		end
	end
	Pose.setJaw(jaws, 0)
	assert(maw.Mesh.Scale.Y == 1 and maw.Mesh.Offset.Magnitude < 1e-6, "shut again")
	assert(mawPart.Name == "Maw", "the mouth part")
	for _, g in { "Chase", "Walk", "Reach", "Stunned", "Stare", "Idle" } do
		local lo, hi = 1, 0
		for i = 0, 200 do
			local j = Pose.jaw(g, i * 0.05, 1)
			lo, hi = math.min(lo, j), math.max(hi, j)
		end
		assert(lo >= -0.05 and hi <= 1.2, g .. " jaw in range")
		if g == "Chase" or g == "Stunned" then assert(lo > 0.4, g .. ": mouth wide open") end
	end
	print("jaw + fingers ok")

	-- every gait poses the joints; no NaN anywhere
	for _, g in { "Chase", "Walk", "Search", "Reach", "Stunned", "Stare", "Idle", "Peek" } do
		for _, t in { 0, 0.7, 3.3, 11.1 } do
			local P = Pose.get(g, t * 2, t, 1)
			assert(P.Root and P.Neck and P.LeftShoulder and P.RightHip and P.LeftFinger1 and P.RightFinger4, g .. " poses the body")
			for name, cf in P do
				local x, y, z = cf:ToEulerAnglesXYZ()
				assert(x == x and y == y and z == z and cf.Position.Y == cf.Position.Y, g .. " " .. name .. " is a number")
			end
		end
	end
	local turned = false
	for i = 0, 400 do
		local P = Pose.get("Idle", 0, i * 0.1, 3)
		local _, yaw = P.Neck:ToEulerAnglesYXZ()
		if math.abs(yaw) > 2.0 then turned = true break end
	end
	assert(turned, "idle: the head turns right round now and then")
	print("poses ok")

	-- the footprints
	local Signs = H.load("Server/World/Signs")
	local folder = H.unwrap(Signs.footprints(H.Instance.new("Folder")))
	local n = 0
	for _, p in folder:GetChildren() do
		n += 1
		local pos = p.CFrame.Position
		assert(math.abs(pos.Y - 15.011) < 0.01, "on the hall floor")
		assert(pos.X > -1.5 and pos.X < 11 and pos.Z > -9 and pos.Z < 12, "in the hall, clear of the stairwell: " .. tostring(pos))
		assert(not p.CanCollide and not p.CanQuery, "nothing to trip on")
	end
	assert(n >= 30, "a trail of prints: " .. n)
	print("footprints ok: " .. n .. " pieces")

	-- the new scares
	local Story = H.load("RS/Shared/Story")
	local Events = H.load("Server/Director/Events")
	local found = {}
	for _, e in Events.List do found[e.Id] = e end
	for _, id in { "YardFigure", "HallStare" } do
		assert(found[id] and found[id].Once, id .. " is scheduled, once")
		assert(Story.Thoughts.Events[id] and Story.Truths[id], id .. " has its thought and its truth")
	end
	assert(found.YardFigure.Acts.Evening, "the yard figure comes in the first act")
	local fired = {}
	local ctx: any = {
		Remotes = setmetatable({}, { __index = function(t, k)
			local r = { FireClient = function(_, ...) table.insert(fired, { k, ... }) end }
			rawset(t, k, r)
			return r
		end }),
		PlayerState = { addNerve = function() end },
		Story = Story,
	}
	local D = { lightning = function() end, think = function() end, logTruth = function() end }
	local who = H.wrap(R.Instance.new("Player"))
	found.YardFigure.Run(ctx, D, { Player = who, Watch = { Stand = V(-50, 4, -22), Face = V(-40, 4, -22) } })
	local fig = nil
	for _, f in fired do if f[1] == "Figure" then fig = f end end
	assert(fig and fig[5] == "Stare" and fig[3].Position.X < -60, "the yard figure stands well out in the yard, staring")
	fired = {}
	found.HallStare.Run(ctx, D, { Player = who, Feet = V(2, 15, -25), From = V(2, 16, 10) })
	local sound = false
	fig = nil
	for _, f in fired do
		if f[1] == "Figure" then fig = f end
		if f[1] == "PlaySound" and f[3] == "CreatureWhisper" then sound = true end
	end
	assert(fig and fig[5] == "Stare" and math.abs(fig[3].Position.Y - 17.6) < 0.01 and sound, "the hall figure, at the far end, and a whisper")
	print("scares ok")

	-- v106: the mimic: a friend's voice (or Mom's) calling you from the other floor
	assert(found.Mimic and found.Mimic.Once and Story.Truths.Mimic, "the mimic is scheduled, once, with its truth")
	local me = H.wrap(R.Instance.new("Player"))
	me:SetAttribute("RoleName", "Jamie Whitaker")
	local pal = H.wrap(R.Instance.new("Player"))
	pal:SetAttribute("Role", "Tinkerer")
	pal:SetAttribute("RoleName", "Riley Chen")
	fired = {}
	found.Mimic.Run(ctx, D, { Player = me, From = V(4, 16, 0), Up = true, Friend = pal })
	local call = nil
	for _, f in fired do if f[1] == "HisVoice" then call = f end end
	assert(call and call[2] == me and string.find(call[3], "Jamie") and call[4].Voice == "Tinkerer", "in Riley's voice, calling Jamie: " .. tostring(call and call[3]))
	assert(call[4].From.Y > 16 and string.sub(call[4].Caption, 1, 15) == "[From upstairs]", "from upstairs")
	assert(Story.Voices.Profiles[call[4].Voice], "a voice that exists")
	fired = {}
	found.Mimic.Run(ctx, D, { Player = me, From = V(4, 2, 0), Up = false })
	call = nil
	for _, f in fired do if f[1] == "HisVoice" then call = f end end
	assert(call and call[4].Voice == "Mom" and Story.Voices.Profiles.Mom and string.find(call[4].Caption, "downstairs"), "alone: Mom, from downstairs")
	print("mimic ok:", call[3])

	-- v106: the bathroom mirror steams up, words in the steam, on the side you're standing
	local glass = H.Instance.new("Part")
	glass.CFrame = R.CFrame.new(0, 5, 0)
	local gui = Signs.mirror(glass, V(0, 5, -4), "I WATCH YOU SLEEP")
	assert(gui and H.unwrap(glass):FindFirstChild("MirrorWriting"), "the writing")
	local label = H.unwrap(gui):FindFirstChildWhichIsA("TextLabel", true)
	assert(label and label.Text == "I WATCH YOU SLEEP", "what it says")
	assert(Signs.mirror(glass, V(0, 5, -4), "AGAIN") == nil, "once at a time")
	assert(#Story.Mirror >= 1 and #Story.HisLines.Murmur >= 6, "lines to say")
	print("mirror ok")

	-- the new sounds
	local Sounds = H.load("RS/Shared/Sounds")
	for _, s in { "Screech", "BoneCrack1", "BoneCrack2", "ClawStep", "CreatureWhisper", "GlassTap", "HouseCreak1", "HouseCreak2" } do
		local def = Sounds.Library[s]
		assert(def and string.find(def.Id, "rbxassetid://%d+"), "sound " .. s)
	end
	print("sounds ok")
end)
print(ok and "CREATURE OK" or ("CREATURE FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
