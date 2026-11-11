-- skin_test (v112; v156: the gaunt man, 14 skinned pieces on a 55-bone biped): the skinned creature. The asset
-- (assets/Creature.rbxm) has its pieces, their colour map and its bones; SkinPose finds every joint and finger on it; every gait (and the
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
	assert(body and body.ClassName == "MeshPart", "the body is a MeshPart (the bones' holder)")
	-- (v156, the owner: "Not so gory and regular humanoid looking but also really scary": a gaunt, starved man, 14 skinned pieces)
	local pieces = 0
	for _, p in model:GetChildren() do
		if p.ClassName == "MeshPart" and p:GetAttribute("SkinPiece") then
			pieces += 1
			local sa = p:FindFirstChildOfClass("SurfaceAppearance")
			assert(sa and tostring(sa.ColorMapContent):find("9324645994"), p.Name .. ": his colour map")
			assert(sa.Color.R > 0.85, p.Name .. ": pale, barely tinted: " .. tostring(sa.Color))
			local weld = p:FindFirstChildOfClass("WeldConstraint")
			assert(weld and weld.Part0 == body, p.Name .. ": welded to the body")
		end
	end
	assert(pieces == 14, "14 pieces: " .. pieces)
	assert(not Rig.Masked, "no mask, his own face")
	local bones = {}
	for _, d in body:GetDescendants() do
		if d.ClassName == "Bone" then bones[d.Name] = d end
	end
	local n = 0
	for _ in bones do n += 1 end
	assert(n == 55, "55 bones: " .. n)
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
	local J = Skin.Joints
	local U = Skin.Units -- (the gaits' measures were in the old mesh's units)
	local standHead = rest[J.Head].Position.Y
	-- (v156) at rest the biped's A-pose is turned into the old body's: arms hanging ~25 degrees out, not ~50
	for _, sd in { "L", "R" } do
		local a, f = rest[J[sd .. "Arm"]].Position, rest[J[sd .. "Fore"]].Position
		local d = (f - a).Unit
		local off = math.deg(math.acos(math.clamp(-d.Y, -1, 1)))
		print(string.format("rest: %s upper arm %.0f degrees from hanging straight down", sd, off))
		assert(off > 15 and off < 38, sd .. " arm in the old rest pose")
	end
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
			assert(count >= 40, g .. ": drives the skeleton (" .. count .. " bones)")
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
	-- (the floor: where the mesh's ankles and toes stand in its own rest pose, which the feet are planted to)
	local floor = rig.Plant.Foot
	local toeFloor = rig.Plant.Toe
	local lo, hi = math.huge, -math.huge
	local tlo, thi = math.huge, -math.huge
	for i = 0, 23 do
		local w = world(Skin.get("Walk", i * math.pi / 12, i * 0.1, 1))
		local y = math.min(w[J.LFoot].Position.Y, w[J.RFoot].Position.Y)
		lo, hi = math.min(lo, y), math.max(hi, y)
		local ty = math.min(w[J.LToe].Position.Y, w[J.RToe].Position.Y)
		tlo, thi = math.min(tlo, ty), math.max(thi, ty)
	end
	print(string.format("walk: lower toe %.2f..%.2f (standing %.2f)", tlo, thi, toeFloor))
	print(string.format("walk: lower ankle %.2f..%.2f (standing %.2f)", lo, hi, floor))
	assert(tlo > toeFloor - 0.45 * U and lo > floor - 0.45 * U and hi < floor + 0.6 * U, "walking, his feet stay on the floor")
	-- on all fours: the head down low, the hands near the floor
	local headY, handY = -math.huge, math.huge
	for i = 0, 11 do
		local w = world(Skin.get("Chase", i * math.pi / 6, i * 0.1, 1))
		headY = math.max(headY, w[J.Head].Position.Y)
		handY = math.min(handY, w[J.LHand].Position.Y, w[J.RHand].Position.Y)
	end
	print(string.format("chase: head at most %.2f (standing %.2f), hands down to %.2f", headY, standHead, handY))
	assert(headY < standHead - 2.5 * U, "on all fours his head comes right down")
	assert(handY < floor + 1.6 * U, "his hands reach the floor")
	-- the scream: his jaw drops open (v156: no maw any more)
	local shut = world(Skin.get("Idle", 0, 0, 1))
	local open = world(Skin.get("Idle", 0, 0, 1, { Scream = 1 }))
	local function jawDrop(w) return w[J.Head]:PointToObjectSpace((w[J.Jaw] * R.CFrame.new(-6, 0, 0)).Position) end
	local d0, d1 = jawDrop(shut), jawDrop(open)
	print(string.format("scream: the jaw tip moves %.2f units", (d1 - d0).Magnitude))
	assert((d1 - d0).Magnitude > 1.5, "the scream opens his jaw")
end)
if ok then
	print("skin_test: all checks passed")
else
	print("skin_test: FAILED " .. tostring(err))
end
