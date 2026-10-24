--[[
	SkinPose — how he moves (v112): procedural animation for the skinned creature
	(ReplicatedStorage.Assets.Creature: one MeshPart with a Rigify skeleton). The client drives the
	bones every frame (client/Controllers/Creature); tools/creature/pose_dump.luau runs this same
	module offline to render previews.

		local rig = SkinPose.rig(bodyMeshPart)
		local pose = SkinPose.get(gait, phase, t, seed, opts)   -- { [joint]: CFrame (rotation), Root = CFrame? }
		for bone, transform in SkinPose.transforms(rig, pose) do bone.Transform = transform end

	Joint rotations are written in the creature's own axes, whatever way each bone happens to point:
	X to his right, Y up, -Z forward. A limb hanging down swings forward with +X; the spine leans
	forward with -X; a positive Y turn looks to his left; a positive Z roll tips to his left. Each
	rotation turns the bone (and everything below it) about its own pivot, on top of its parent's.
	Fingers curl about their own bend axes instead (opts / pose.Curl).
]]

local SkinPose = {}

SkinPose.Scale = 0.72 -- (the body's scale in the game: Rig.SkinScale)

local A = CFrame.fromEulerAnglesYXZ
local sin, cos, abs, max, min, floor = math.sin, math.cos, math.abs, math.max, math.min, math.floor
local PI = math.pi

-- the skeleton's bones (names as the asset has them)
local JOINTS = {
	Hips = "spine_66",
	Spine = "spine_001_53",
	Spine2 = "spine_002_52",
	Chest = "spine_003_51",
	Neck = "spine_004_2",
	Neck2 = "spine_005_1",
	Head = "spine_006_0",
	LClav = "shoulder_L_25",
	RClav = "shoulder_R_48",
	LArm = "upper_arm_L_24",
	RArm = "upper_arm_R_47",
	LFore = "forearm_L_23",
	RFore = "forearm_R_46",
	LHand = "hand_L_22",
	RHand = "hand_R_45",
	LThigh = "thigh_L_60",
	RThigh = "thigh_R_65",
	LShin = "shin_L_59",
	RShin = "shin_R_64",
	LFoot = "foot_L_58",
	RFoot = "foot_R_63",
	LToe = "toe_L_56",
	RToe = "toe_R_61",
	LBreast = "breast_L_49",
	RBreast = "breast_R_50",
}
SkinPose.Joints = JOINTS

-- finger segments by side: { bone, which knuckle (1 = base) }
local FINGERS = { "f_index", "f_middle", "f_ring", "f_pinky" }

export type Rig = {
	Joints: { [string]: { Bone: Instance, Rot: CFrame, Inv: CFrame, Local: CFrame } },
	Plant: { Base: CFrame, Foot: number, Toe: number }?,
	Fingers: { L: { { Bone: Instance, K: number, Thumb: boolean } }, R: { { Bone: Instance, K: number, Thumb: boolean } } },
}

local function rotOnly(c: CFrame): CFrame
	return c - c.Position
end

-- the bones of a skinned MeshPart, with each one's rest orientation relative to the part
function SkinPose.rig(body: Instance): Rig
	local byName = {}
	for _, d in body:GetDescendants() do
		if d:IsA("Bone") then
			byName[d.Name] = d
		end
	end
	local restWorld = {}
	local function rest(b: any): CFrame
		local cached = restWorld[b]
		if cached then
			return cached
		end
		local p = b.Parent
		local w = ((p and p:IsA("Bone")) and rest(p) or CFrame.identity) * b.CFrame
		restWorld[b] = w
		return w
	end
	local rig = { Joints = {}, Fingers = { L = {}, R = {} } }
	for joint, name in JOINTS do
		local b = byName[name]
		if b then
			local r = rotOnly(rest(b))
			rig.Joints[joint] = { Bone = b, Rot = r, Inv = r:Inverse(), Local = (b :: any).CFrame }
		end
	end
	-- (for keeping his feet on the floor: where the ankles and toes sit at rest)
	local hips, foot, toe = byName[JOINTS.Hips], byName[JOINTS.LFoot], byName[JOINTS.LToe]
	if hips and foot and toe and rig.Joints.LThigh and rig.Joints.RThigh and rig.Joints.LShin and rig.Joints.RShin then
		local p = hips.Parent
		rig.Plant = {
			Base = (p and p:IsA("Bone")) and rest(p) or CFrame.identity,
			Foot = rest(foot).Position.Y,
			Toe = rest(toe).Position.Y,
		}
	end
	for name, b in byName do
		local side = string.match(name, "_([LR])_%d+$")
		local finger = string.match(name, "^(f_%a+)_0(%d)") or string.match(name, "^(thumb)_0(%d)")
		local k = tonumber(string.match(name, "_0(%d)_"))
		if side and finger and k then
			table.insert(rig.Fingers[side], { Bone = b, K = k, Thumb = string.sub(name, 1, 5) == "thumb" })
		end
	end
	return rig :: any
end

-- pose -> { [Bone]: Transform }
function SkinPose.transforms(rig: Rig, pose: { [string]: any }): { [Instance]: CFrame }
	local out = {}
	for joint, j in rig.Joints do
		local r = pose[joint]
		local move = joint == "Hips" and pose.Root or nil
		if r or move then
			local t = j.Inv * (r or CFrame.identity) * j.Rot
			if move then
				t = CFrame.new(j.Inv:VectorToWorldSpace(move)) * t
			end
			out[j.Bone] = t
		else
			out[j.Bone] = CFrame.identity
		end
	end
	-- feet on the floor: the whole body lifted or lowered so the lower ankle (or toe) is where it
	-- is standing at rest, whatever the legs are doing (pose.Plant: 0..1, how much)
	local plant = pose.Plant or 0
	if plant > 0 and rig.Plant then
		local pl = rig.Plant
		local hips = rig.Joints.Hips
		local base = pl.Base * hips.Local
		local hw = base * out[hips.Bone]
		local err = math.huge
		for _, sd in { "L", "R" } do
			local th, sh, ft, to = rig.Joints[sd .. "Thigh"], rig.Joints[sd .. "Shin"], rig.Joints[sd .. "Foot"], rig.Joints[sd .. "Toe"]
			local a = hw * th.Local * out[th.Bone] * sh.Local * out[sh.Bone] * ft.Local
			err = min(err, a.Position.Y - pl.Foot)
			if to then
				err = min(err, (a * out[ft.Bone] * to.Local).Position.Y - pl.Toe)
			end
		end
		out[hips.Bone] = base:Inverse() * CFrame.new(0, -err * plant, 0) * hw
	end
	-- fingers: each knuckle bends about its own X (the curl), spreading a little with the base ones
	local curl = pose.Curl or { L = 0.35, R = 0.35 }
	local t, tw = pose.T or 0, pose.Twitch or 0
	for side, list in rig.Fingers do
		local c = curl[side] or 0.35
		for i, f in list do
			-- (each finger a little on its own, twitching when he's agitated)
			local own = tw * 0.22 * sin(t * 6.3 + i * 1.7) * sin(t * 2.1 + i * 0.9)
			local amt = (f.Thumb and c * 0.5 or c) + own
			out[f.Bone] = CFrame.Angles(amt * (f.K == 1 and 0.7 or 1.0), 0, 0)
		end
	end
	return out
end

---------------------------------------------------------------------------
-- the gaits
--
-- A gait is sampled as plain numbers first (P[joint] = { x, y, z } angles, P.Root = { x, y, z }
-- offset in mesh units, P.CurlL / P.CurlR finger curl, P.Mouth 0..1 the chest splitting open),
-- so two gaits blend by simple interpolation (SkinPose.blend), then turned into CFrames.
---------------------------------------------------------------------------

local JOINT_LIST = { "Hips", "Spine", "Spine2", "Chest", "Neck", "Neck2", "Head", "LClav", "RClav", "LArm", "RArm", "LFore",
	"RFore", "LHand", "RHand", "LThigh", "RThigh", "LShin", "RShin", "LFoot", "RFoot", "LToe", "RToe" }

local function hash(n: number): number
	local x = sin(n * 127.1 + 311.7) * 43758.5453
	return x - floor(x)
end

-- smooth organic drift in [-1, 1]
local function drift(t: number, s: number): number
	return sin(t * 0.73 + s * 3.1) * 0.5 + sin(t * 1.31 + s * 7.3) * 0.3 + sin(t * 2.17 + s * 1.9) * 0.2
end

-- a sudden snap every so often: an envelope (0..1, sharp attack, slow release) and a random sign
local function snap(t: number, seed: number, every: number): (number, number)
	local slot = floor(t / every)
	if hash(slot + seed * 17.3) < 0.35 then
		return 0, 0
	end
	local start = hash(slot + 3.1 + seed) * every * 0.6
	local dt = t - slot * every - start
	if dt < 0 or dt > 0.9 then
		return 0, 0
	end
	local env = dt < 0.07 and dt / 0.07 or math.exp(-(dt - 0.07) * 5)
	return env, (hash(slot + 9.7 + seed) < 0.5) and -1 or 1
end

-- now and then his head turns right round, holds, and comes back
local function owl(t: number, seed: number): number
	local every = 13
	local slot = floor(t / every)
	if hash(slot + seed * 5.7) < 0.55 then
		return 0
	end
	local dt = t - slot * every - hash(slot + 1.3 + seed) * 6
	if dt < 0 or dt > 3.4 then
		return 0
	end
	local k = dt < 0.5 and dt / 0.5 or (dt < 2.4 and 1 or 1 - (dt - 2.4))
	k = k * k * (3 - 2 * k)
	return k * ((hash(slot + 4.4 + seed) < 0.5) and -1 or 1)
end

local function set(P, joint: string, x: number, y: number?, z: number?)
	local v = P[joint]
	if v then
		v[1] += x
		v[2] += y or 0
		v[3] += z or 0
	else
		P[joint] = { x, y or 0, z or 0 }
	end
end

-- the stalker's stance every gait starts from: hunched, knees soft, long arms hanging in front
local function stance(P, hunch: number)
	set(P, "Hips", -0.05 * hunch)
	set(P, "Spine", -0.3 * hunch)
	set(P, "Spine2", -0.24 * hunch)
	set(P, "Chest", -0.16 * hunch)
	-- the neck comes forward and up, so the face still looks where he's going
	set(P, "Neck", 0.4 * hunch)
	set(P, "Neck2", 0.2 * hunch)
	set(P, "Head", 0.08 * hunch)
	set(P, "LClav", 0.12 * hunch, 0, 0.04)
	set(P, "RClav", 0.12 * hunch, 0, -0.04)
	-- arms hang straight down (the asset rests in an A-pose), a little in front of him
	set(P, "LArm", 0.5 * hunch + 0.12, 0, 0.32)
	set(P, "RArm", 0.5 * hunch + 0.12, 0, -0.32)
	set(P, "LFore", 0.28)
	set(P, "RFore", 0.28)
	set(P, "LHand", 0.1, 0, 0.1)
	set(P, "RHand", 0.1, 0, -0.1)
	set(P, "LThigh", 0.25 * hunch)
	set(P, "RThigh", 0.25 * hunch)
	set(P, "LShin", -0.45 * hunch)
	set(P, "RShin", -0.45 * hunch)
	set(P, "LFoot", 0.2 * hunch)
	set(P, "RFoot", 0.2 * hunch)
	P.Root = { 0, -0.15 * hunch, 0 }
	P.CurlL, P.CurlR = 0.55, 0.55
	P.Mouth = 0
end

-- the twitchy life on top of everything: breathing, fingers, sudden snaps of the head and shoulders
local function life(P, t: number, seed: number, amount: number)
	local breath = sin(t * 1.6 + seed)
	set(P, "Chest", -0.025 * breath)
	set(P, "LClav", 0, 0, 0.02 * breath)
	set(P, "RClav", 0, 0, -0.02 * breath)
	P.Mouth += (0.06 + 0.05 * breath) * amount
	local e, sgn = snap(t, seed, 2.6)
	set(P, "Head", -0.25 * e * amount, 0.35 * e * sgn * amount, 0.5 * e * sgn * amount)
	set(P, "Neck2", 0, 0.15 * e * sgn * amount, 0.1 * e * sgn * amount)
	local e2, sgn2 = snap(t + 1.7, seed + 11, 3.4)
	set(P, sgn2 > 0 and "LClav" or "RClav", 0.15 * e2 * amount, 0, 0.25 * e2 * sgn2 * amount)
	set(P, sgn2 > 0 and "LFore" or "RFore", 0.3 * e2 * amount)
	P.Twitch = amount
end

function SkinPose.sample(gait: string, phase: number, t: number, seed: number?, opts: any?): { [string]: any }
	local sd = seed or 1
	local o = opts or {}
	local P: { [string]: any } = {}
	local s, c = sin(phase), cos(phase)
	if gait == "Chase" then
		-- on all fours: the torso flat out in front of him, long arms reaching and slapping down like
		-- front legs, the hind legs bounding together, the head craned up so it never stops looking at you
		local flex = sin(phase)
		set(P, "Hips", -0.28)
		set(P, "Spine", -0.85 + 0.16 * flex)
		set(P, "Spine2", -0.5 + 0.12 * flex)
		set(P, "Chest", -0.3 + 0.05 * flex)
		set(P, "Neck", 0.95 - 0.08 * flex)
		set(P, "Neck2", 0.5)
		set(P, "Head", 0.38 + 0.1 * cos(phase * 2), 0.08 * drift(t * 2, sd), 0.12 * drift(t, sd + 3))
		local function hind(side: string, ph: number)
			local ss, cc = sin(ph), cos(ph)
			set(P, side .. "Thigh", 1.15 + 0.6 * ss)
			set(P, side .. "Shin", -1.5 - 0.45 * sin(ph + 0.9))
			set(P, side .. "Foot", 0.45 - 0.35 * cc)
			set(P, side .. "Toe", 0.3 * max(0, -cc))
		end
		hind("L", phase)
		hind("R", phase - 0.35)
		local function front(side: string, ph: number, roll: number)
			local ss, cc = sin(ph), cos(ph)
			set(P, side .. "Clav", 0.25 + 0.15 * ss, 0, 0)
			set(P, side .. "Arm", 1.42 + 0.72 * ss, 0, roll)
			-- (the elbow folds as the hand comes forward off the floor; straight while it's planted)
			set(P, side .. "Fore", 0.08 + 0.8 * max(0, cc))
			set(P, side .. "Hand", -0.6 + 0.5 * max(0, cc))
		end
		front("L", phase + PI + 0.3, 0.42)
		front("R", phase + PI + 0.62, -0.42)
		P.Root = { 0, -1.95 + 0.38 * sin(phase + 1.2), 1.9 }
		P.CurlL, P.CurlR = 0.12, 0.12
		P.Mouth = 0.25 + 0.15 * sin(phase)
		P.Twitch = 0.3
	elseif gait == "Walk" or gait == "Search" then
		local search = gait == "Search"
		stance(P, 1)
		local function leg(side: string, ph: number)
			local ss, cc = sin(ph), cos(ph)
			local thigh = 0.45 * ss
			local knee = -0.85 * max(0, cc) ^ 1.3 - 0.08
			set(P, side .. "Thigh", thigh)
			set(P, side .. "Shin", knee)
			set(P, side .. "Foot", -(thigh + knee) * 0.8 + 0.18 * max(0, -ss))
			set(P, side .. "Toe", 0.25 * max(0, -ss))
		end
		leg("L", phase)
		leg("R", phase + PI)
		-- the pelvis rolls and turns with each step, the shoulders against it; he sinks on each stride
		set(P, "Hips", 0, 0.12 * s, 0.07 * c)
		set(P, "Chest", 0, -0.14 * s, -0.04 * c)
		P.Root[2] += -0.16 * abs(s)
		P.Root[1] += 0.12 * c
		set(P, "LArm", -0.22 * s)
		set(P, "RArm", 0.22 * s)
		set(P, "LFore", 0.1 * max(0, -s))
		set(P, "RFore", 0.1 * max(0, s))
		if search then
			-- the head sweeps the room, the body following; now and then a hand comes up, feeling ahead
			local scan = sin(t * 0.55 + sd) * 0.9 + 0.2 * drift(t, sd)
			set(P, "Neck", -0.1, 0.25 * scan, 0)
			set(P, "Neck2", 0, 0.3 * scan, 0.1 * scan)
			set(P, "Head", -0.15 + 0.1 * sin(t * 0.9), 0.35 * scan, 0.25 * scan)
			set(P, "Chest", 0, 0.15 * scan)
			local reach = max(0, sin(t * 0.37 + sd * 2)) ^ 2
			set(P, "LArm", 0.9 * reach, 0, -0.15 * reach)
			set(P, "LFore", -0.2 * reach)
			P.CurlL = 0.55 - 0.45 * reach
		else
			set(P, "Head", 0.06 * c, 0.15 * drift(t, sd), 0.18 * drift(t * 0.6, sd + 5))
		end
		life(P, t, sd, 0.8)
	elseif gait == "Reach" then
		-- the grab: he lunges, both hands out, the fingers splayed and closing, the chest splitting open
		stance(P, 0.7)
		local pulse = 0.5 + 0.5 * sin(t * 5)
		set(P, "Spine", -0.2)
		set(P, "Chest", -0.1)
		set(P, "Neck", 0.15)
		set(P, "Head", 0.1, 0.1 * drift(t * 3, sd), 0.45)
		set(P, "LArm", 1.25 + 0.15 * pulse, 0, 0.05)
		set(P, "RArm", 1.2 + 0.15 * (1 - pulse), 0, -0.05)
		set(P, "LFore", -0.12)
		set(P, "RFore", -0.12)
		set(P, "LHand", -0.3)
		set(P, "RHand", -0.3)
		P.Root[2] -= 0.35
		P.CurlL, P.CurlR = 0.05 + 0.6 * pulse, 0.05 + 0.6 * (1 - pulse)
		P.Mouth = 0.55 + 0.2 * pulse
		life(P, t, sd, 0.4)
	elseif gait == "Stunned" then
		-- the taser: knees gone, arms jerking out, the head thrown back, the chest snapping open and shut
		stance(P, 0.6)
		local function jit(k: number): number
			return sin(t * 47 + k * 2.3) * 0.6 + sin(t * 71 + k * 5.1) * 0.4
		end
		set(P, "LThigh", 0.55)
		set(P, "RThigh", 0.45)
		set(P, "LShin", -1.1)
		set(P, "RShin", -0.95)
		set(P, "LFoot", 0.5)
		set(P, "RFoot", 0.45)
		P.Root[2] -= 1.2
		set(P, "Spine", -0.25 + 0.12 * jit(1))
		set(P, "Chest", 0.15 * jit(2), 0.1 * jit(3))
		set(P, "Neck", -0.2 + 0.15 * jit(4), 0, 0.2 * jit(5))
		set(P, "Head", 0.7 + 0.25 * jit(6), 0.3 * jit(7), 0.4 * jit(8))
		set(P, "LArm", 0.6 + 0.4 * jit(9), 0, -0.9 + 0.4 * jit(10))
		set(P, "RArm", 0.5 + 0.4 * jit(11), 0, 0.9 + 0.4 * jit(12))
		set(P, "LFore", 0.9 + 0.5 * jit(13))
		set(P, "RFore", 0.8 + 0.5 * jit(14))
		P.CurlL, P.CurlR = 0.9 + 0.3 * jit(15), 0.9 + 0.3 * jit(16)
		P.Mouth = 0.4 + 0.4 * jit(17)
		P.Twitch = 1
	elseif gait == "Peek" then
		-- leaning out from behind a door frame: tipped sideways, the head laid right over, one hand
		-- high up curled round the edge
		stance(P, 0.5)
		set(P, "Hips", 0, 0, 0.3)
		set(P, "Spine", 0, 0, 0.25)
		set(P, "Chest", 0, 0.1, 0.2)
		set(P, "Neck", 0.1, 0, 0.35)
		set(P, "Head", 0.1, 0.15 * drift(t, sd), 0.95 + 0.1 * drift(t * 0.7, sd + 2))
		set(P, "LArm", 2.3, 0, -0.55)
		set(P, "LFore", 0.85)
		set(P, "LHand", 0.3)
		P.CurlL = 1.1
		P.Root[1] -= 0.7
		life(P, t, sd, 0.6)
	elseif gait == "Leap" then
		-- the pounce: arms flung forward, legs trailing, the chest wide open
		set(P, "Spine", -0.35)
		set(P, "Spine2", -0.2)
		set(P, "Neck", 0.4)
		set(P, "Head", 0.3)
		set(P, "LArm", 2.0, 0, -0.35)
		set(P, "RArm", 2.0, 0, 0.35)
		set(P, "LFore", 0.15)
		set(P, "RFore", 0.15)
		set(P, "LThigh", -0.45)
		set(P, "RThigh", -0.3)
		set(P, "LShin", -0.9)
		set(P, "RShin", -1.1)
		P.Root = { 0, -0.6, 0.6 }
		P.CurlL, P.CurlR, P.Mouth = 0.15, 0.15, 0.7
		P.Twitch = 0.3
	else
		-- Stare / Idle: dead still but for the breathing and the twitches, the head laid over,
		-- listening; now and then it turns right round
		local stare = gait == "Stare"
		stance(P, stare and 0.75 or 0.9)
		local tilt = (stare and 0.42 or 0.18) + 0.12 * drift(t * 0.4, sd)
		set(P, "Neck", 0.05, 0, 0.12 * tilt)
		set(P, "Head", -0.05, 0.12 * drift(t * 0.5, sd + 1), tilt)
		set(P, "Hips", 0, 0.04 * drift(t * 0.3, sd + 2), 0.03 * drift(t * 0.3, sd + 3))
		set(P, "LArm", 0.04 * drift(t * 0.5, sd + 4))
		set(P, "RArm", 0.04 * drift(t * 0.5, sd + 5))
		local turn = owl(t, sd)
		if turn ~= 0 then
			set(P, "Neck", 0, 0.5 * turn)
			set(P, "Neck2", 0, 0.65 * turn)
			set(P, "Head", 0, 0.85 * turn, -tilt * abs(turn))
		end
		life(P, t, sd, 1)
	end
	if P.Plant == nil then
		P.Plant = gait == "Leap" and 0 or 1
	end
	-- where he's looking (the head turns to it, the neck helps)
	if o.Look then
		set(P, "Neck2", 0.3 * (o.Look[2] or 0), 0.35 * (o.Look[1] or 0))
		set(P, "Head", 0.5 * (o.Look[2] or 0), 0.5 * (o.Look[1] or 0))
	end
	-- stooping under a door frame or a low ceiling
	local duck = o.Duck or 0
	if duck > 0 then
		set(P, "Spine", -0.35 * duck)
		set(P, "Spine2", -0.2 * duck)
		set(P, "Neck", 0.35 * duck)
		set(P, "LThigh", 0.45 * duck)
		set(P, "RThigh", 0.45 * duck)
		set(P, "LShin", -0.7 * duck)
		set(P, "RShin", -0.7 * duck)
		set(P, "LFoot", 0.25 * duck)
		set(P, "RFoot", 0.25 * duck)
		P.Root[2] -= 0.75 * duck
	end
	-- the scream (jumpscare): arms flung wide, the chest torn open, shaking
	local scream = o.Scream or 0
	if scream > 0 then
		local sh = sin(t * 53) * 0.6 + sin(t * 37) * 0.4
		-- (v114: the mask on, he screams straight at you, not at the ceiling)
		set(P, "Spine", 0.05 * scream)
		set(P, "Chest", (0.12 + 0.05 * sh) * scream)
		set(P, "Neck", -0.12 * scream)
		set(P, "Head", (-0.08 + 0.08 * sh) * scream, 0, 0.1 * sh * scream)
		set(P, "LArm", 0.6 * scream, 0, (-1.3 + 0.1 * sh) * scream)
		set(P, "RArm", 0.6 * scream, 0, (1.3 - 0.1 * sh) * scream)
		set(P, "LFore", 0.5 * scream)
		set(P, "RFore", 0.5 * scream)
		P.CurlL = P.CurlL + (0.05 - P.CurlL) * scream
		P.CurlR = P.CurlR + (0.05 - P.CurlR) * scream
		P.Mouth = P.Mouth + (1.05 - P.Mouth) * scream
	end
	P.Scream = scream
	P.T = t
	return P
end

-- a and b mixed: w = 0 is a, 1 is b
function SkinPose.blend(a: { [string]: any }, b: { [string]: any }, w: number): { [string]: any }
	if w <= 0 then
		return a
	elseif w >= 1 then
		return b
	end
	local out: { [string]: any } = {}
	for _, j in JOINT_LIST do
		local va, vb = a[j], b[j]
		if va or vb then
			va = va or { 0, 0, 0 }
			vb = vb or { 0, 0, 0 }
			out[j] = { va[1] + (vb[1] - va[1]) * w, va[2] + (vb[2] - va[2]) * w, va[3] + (vb[3] - va[3]) * w }
		end
	end
	local ra, rb = a.Root or { 0, 0, 0 }, b.Root or { 0, 0, 0 }
	out.Root = { ra[1] + (rb[1] - ra[1]) * w, ra[2] + (rb[2] - ra[2]) * w, ra[3] + (rb[3] - ra[3]) * w }
	for _, k in { "CurlL", "CurlR", "Mouth", "Twitch", "Plant", "Scream" } do
		local x, y = a[k] or 0, b[k] or 0
		out[k] = x + (y - x) * w
	end
	out.T = b.T or a.T
	return out
end

-- sampled numbers -> what transforms() takes; scale: the model's scale (the Root offset is in mesh units)
function SkinPose.toPose(P: { [string]: any }, scale: number?): { [string]: any }
	local pose: { [string]: any } = {}
	for _, j in JOINT_LIST do
		local v = P[j]
		if v then
			pose[j] = A(v[1], v[2], v[3])
		end
	end
	-- (the breast bones pull the vertical maw in his chest open: v114, only when he screams; the rest
	-- of the time his mouth is the mask's, pose.Mouth)
	local maw = P.Scream or 0
	if maw > 0 then
		pose.LBreast = A(0, 0.66 * maw, 0)
		pose.RBreast = A(0, -0.66 * maw, 0)
	end
	local r = P.Root
	if r then
		local k = scale or 1
		pose.Root = Vector3.new(r[1] * k, r[2] * k, r[3] * k)
	end
	pose.Curl = { L = P.CurlL or 0.5, R = P.CurlR or 0.5 }
	pose.T = P.T
	pose.Twitch = P.Twitch
	pose.Plant = P.Plant
	pose.Mouth = P.Mouth
	return pose
end

function SkinPose.get(gait: string, phase: number, t: number, seed: number?, opts: any?): { [string]: any }
	if gait == "Test" then
		local o = opts or {}
		local p: { [string]: any } = {}
		for k, v in o do
			if type(v) == "table" and #v == 3 then
				p[k] = A(v[1], v[2], v[3]) -- (x pitch, y yaw, z roll)
			end
		end
		if o.Root then
			p.Root = Vector3.new(o.Root[1], o.Root[2], o.Root[3])
		end
		if o.Curl then
			p.Curl = { L = o.Curl, R = o.Curl }
		end
		return p
	end
	return SkinPose.toPose(SkinPose.sample(gait, phase, t, seed, opts), opts and opts.Scale)
end

-- stride phase per stud travelled (in the game's studs, at the game's scale)
function SkinPose.phaseRate(gait: string): number
	if gait == "Chase" then
		return 0.62
	end
	return 0.85
end

return SkinPose
