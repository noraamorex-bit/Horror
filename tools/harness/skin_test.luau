-- skin_test (v112): the skinned creature. The asset (assets/Creature.rbxm) has its mesh, its
-- textures and its 68 bones; SkinPose finds every joint and finger on it; every gait (and the
-- duck, the look, the scream, and a blend between any two gaits) gives a finite transform for
-- every bone; walking, his feet stay on the floor (neither floating nor sunk through it); on all
-- fours his head comes right down and his hands reach the floor; the scream opens the maw. The
-- game's scale matches the server's.
local H = require("./env")
local R = H.roblox
local fs = require("@lune/fs")

local ok, err = pcall(function()
	local Skin = H.load("RS/Shared/SkinPose")
	local Rig = H.load("Server/Intruder/Rig")
	assert(Skin.Scale == Rig.SkinScale, "the client's scale is the server's")
	local model = R.deserializeModel(fs.readFile("../../assets/Creature.rbxm"))[1]
	local body = model:FindFirstChild("Body")
	assert(body and body.ClassName == "MeshPart", "the body is a MeshPart")
	local sa = body:FindFirstChildOfClass("SurfaceAppearance")
	assert(sa, "it has its surface")
	-- (v114: the raw, bloody colour map is gone; the sculpted detail of the normal map stays)
	assert(tostring(sa.ColorMapContent) == "Content(None)", "no colour map: " .. tostring(sa.ColorMapContent))
	assert(tostring(sa.NormalMapContent):find("17737124050"), "the normal map kept")
	-- (v114) the porcelain mask and hair go on the new head: everything on the old Head but its neck and
	-- the light's anchor, grown to fit the bigger skull
	local Builder = H.load("Server/World/Builder")
	local m = H.unwrap(Rig.build(Builder))
	local head = m:FindFirstChild("Head")
	local s0 = head.Size.X
	local keep = Rig.maskLayout(m)
	local n, names = 0, {}
	for p in keep do
		n += 1
		names[p.Name] = true
	end
	assert(names.Mask and names.Hair and names.Head and names.Maw, "the mask, the hair and the jaw kept")
	assert(not names.NeckBone and not names.Knuckle and not names.FaceGlow, "not the old neck or the light's anchor")
	assert(math.abs(head.Size.X - s0 * Rig.MaskScale) < 1e-4, "grown to fit")
	print("mask: " .. n .. " parts kept")
	local bones = {}
	for _, d in body:GetDescendants() do
		if d.ClassName == "Bone" then bones[d.Name] = d end
	end
	local n = 0
	for _ in bones do n += 1 end
	assert(n == 68, "68 bones: " .. n)
	local rig = Skin.rig(body)
	local fingers = 0
	for _, list in rig.Fingers do fingers += #list end
	assert(fingers >= 28, "the fingers: " .. fingers)

	-- every bone's world frame (in the mesh's own units) for a pose
	local function world(pose)
		local tr = {}
		-- (by name: lune hands out a new userdata for the same instance on every lookup)
		for b, cf in Skin.transforms(rig, pose) do tr[b.Name] = cf end
		local out = {}
		local function walk(b, parentCf)
			local cf = parentCf * b.CFrame * (tr[b.Name] or R.CFrame.identity)
			out[b.Name] = cf
			for _, c in b:GetChildren() do
				if c.ClassName == "Bone" then walk(c, cf) end
			end
		end
		for _, c in body:GetChildren() do
			if c.ClassName == "Bone" then walk(c, R.CFrame.identity) end
		end
		return out, tr
	end
	local function finite(cf)
		for _, v in { cf:GetComponents() } do
			if v ~= v or v == math.huge or v == -math.huge then return false end
		end
		return true
	end
	local rest = world({})
	local standHead = rest["spine_006_0"].Position.Y
	local gaits = { "Idle", "Stare", "Walk", "Search", "Chase", "Reach", "Stunned", "Peek", "Leap", "Sit" }
	local samples = {}
	for _, g in gaits do
		samples[g] = {}
		for i = 0, 11 do
			local opts = { Look = { 0.6, -0.2 }, Duck = (i % 3) * 0.5, Scream = (i % 4 == 3) and 1 or 0 }
			local P = Skin.sample(g, i * math.pi / 6, i * 0.37, 3, opts)
			table.insert(samples[g], P)
			local _, tr = world(Skin.toPose(P, 1))
			local count = 0
			for _, cf in tr do
				assert(finite(cf), g .. ": a finite transform")
				count += 1
			end
			assert(count >= 50, g .. ": drives the skeleton (" .. count .. " bones)")
		end
	end
	for _, a in gaits do
		for _, b in gaits do
			local P = Skin.blend(samples[a][2], samples[b][5], 0.4)
			for _, cf in Skin.transforms(rig, Skin.toPose(P, 1)) do
				assert(finite(cf), a .. " -> " .. b .. ": blends")
			end
		end
	end
	-- walking: the lower foot on the floor all the way through the stride
	local floor = rest["foot_L_58"].Position.Y
	local lo, hi = math.huge, -math.huge
	for i = 0, 23 do
		local w = world(Skin.get("Walk", i * math.pi / 12, i * 0.1, 1))
		local y = math.min(w["foot_L_58"].Position.Y, w["foot_R_63"].Position.Y)
		lo, hi = math.min(lo, y), math.max(hi, y)
	end
	print(string.format("walk: lower ankle %.2f..%.2f (standing %.2f)", lo, hi, floor))
	assert(lo > floor - 0.45 and hi < floor + 0.45, "walking, his feet stay on the floor")
	-- on all fours: the head down low, the hands near the floor
	local headY, handY = -math.huge, math.huge
	for i = 0, 11 do
		local w = world(Skin.get("Chase", i * math.pi / 6, i * 0.1, 1))
		headY = math.max(headY, w["spine_006_0"].Position.Y)
		handY = math.min(handY, w["hand_L_22"].Position.Y, w["hand_R_45"].Position.Y)
	end
	print(string.format("chase: head at most %.2f (standing %.2f), hands down to %.2f", headY, standHead, handY))
	assert(headY < standHead - 2.5, "on all fours his head comes right down")
	assert(handY < floor + 1.0, "his hands reach the floor")
	-- the scream: the two sides of the maw pulled apart
	local shut = world(Skin.get("Idle", 0, 0, 1))
	local open = world(Skin.get("Idle", 0, 0, 1, { Scream = 1 }))
	local gap0 = (shut["breast_L_49"].Position - shut["breast_R_50"].Position).Magnitude
	local w0 = shut["breast_L_49"].LookVector:Dot(shut["breast_R_50"].LookVector)
	local w1 = open["breast_L_49"].LookVector:Dot(open["breast_R_50"].LookVector)
	print(string.format("scream: breast bones %.2f apart, facing %.2f -> %.2f", gap0, w0, w1))
	assert(w1 < w0 - 0.3, "the scream opens the maw")
end)
if ok then
	print("skin_test: all checks passed")
else
	print("skin_test: FAILED " .. tostring(err))
end
