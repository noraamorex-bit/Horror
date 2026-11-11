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

	(v156, the owner: "I already said i don't like this model for monster why did you bring it back. Not so gory and regular humanoid
	looking but also really scary") the body is a gaunt, starved man now (assets/Creature.rbxm from tools/creature/make_curtis.luau: a
	biped skeleton, 14 skinned pieces). The gaits were written for the old body, so: the joints map onto the biped's bones (its one
	neck bone takes both of the old neck joints), each limb gets a rest correction (K) that turns the biped's A-pose into the old
	body's rest pose before a gait's rotation is applied, and the gaits' body offsets (in the old mesh's units) grow by Units.
]]

local SkinPose = {}

SkinPose.Scale = 0.05485 -- (the body's scale in the game: Rig.SkinScale; v156: the new mesh is 179.4 units tall, ~9.8 studs)
-- (v156) the gaits' body offsets were written in the old mesh's units (13.66 tall): the new mesh's units per old unit
SkinPose.Units = 179.4 / 13.66

local A = CFrame.fromEulerAnglesYXZ
local sin, cos, abs, max, min, floor = math.sin, math.cos, math.abs, math.max, math.min, math.floor
local PI = math.pi

-- the skeleton's bones (names as the asset has them; v156: the biped's)
local JOINTS = {
	Hips = "Base HumanPelvis",
	Spine = "Base HumanSpine1",
	Spine2 = "Base HumanSpine2",
	Chest = "Base HumanRibcage",
	Neck = "Base HumanNeck",
	Head = "Base HumanHead",
	Jaw = "Base HumanHeadJaw",
	LClav = "Base HumanLArmCollarbone",
	RClav = "Base HumanRArmCollarbone",
	LArm = "Base HumanLArmUpperarm",
	RArm = "Base HumanRArmUpperarm",
	LFore = "Base HumanLArmForearm",
	RFore = "Base HumanRArmForearm",
	LHand = "Base HumanLArmPalm",
	RHand = "Base HumanRArmPalm",
	LThigh = "Base HumanLLegThigh",
	RThigh = "Base HumanRThigh",
	LShin = "Base HumanLLegCalf",
	RShin = "Base HumanRCalf",
	LFoot = "Base HumanLLegFoot",
	RFoot = "Base HumanRFoot",
	LToe = "Base HumanLLegDigit11",
	RToe = "Base HumanRDigit11",
}
-- (v156) joints the old body had and this one doesn't: their rotation goes onto the joint above (Neck2 sat on Neck)
local MERGE = { Neck2 = "Neck" }
-- (v156) the old body's rest pose: each limb's direction to the next joint, in the creature's axes (X right, Y up, -Z forward).
-- The biped stands in an A-pose (arms ~50 degrees out, the old body's hung ~25): K turns it into this before a gait applies
local REST_DIR = {
	LClav = Vector3.new(-0.88, -0.16, 0.44),
	LArm = Vector3.new(-0.43, -0.88, 0.19),
	LFore = Vector3.new(-0.33, -0.90, -0.28),
	LThigh = Vector3.new(-0.00, -0.99, 0.11),
	LShin = Vector3.new(-0.09, -0.99, 0.05),
	-- (no foot: the two skeletons put the toe bone in different places; the biped's feet stay flat as they stand)
}
local CHILD = { Clav = "Arm", Arm = "Fore", Fore = "Hand", Thigh = "Shin", Shin = "Foot", Foot = "Toe" }
local PARENT = { Clav = "Chest", Arm = "Clav", Fore = "Arm", Hand = "Fore", Thigh = "Hips", Shin = "Thigh", Foot = "Shin", Toe = "Foot" }
SkinPose.MinJoints = 20
SkinPose.CurlSign = -1
SkinPose.JawSign = -1 -- (the client waits for a whole skeleton: v133)
SkinPose.Joints = JOINTS


export type Rig = {
	Joints: { [string]: { Bone: Instance, Rot: CFrame, Inv: CFrame, Local: CFrame, K: CFrame?, KpInv: CFrame? } },
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
	-- (v156) the rest corrections, shoulder to fingertip and hip to toe: K at each joint turns its rest direction (after the joints
	-- above have been corrected) into the old body's
	local function align(a: Vector3, b: Vector3): CFrame
		local axis = a:Cross(b)
		local d = math.clamp(a:Dot(b), -1, 1)
		if axis.Magnitude < 1e-5 then
			return CFrame.identity
		end
		return CFrame.fromAxisAngle(axis.Unit, math.acos(d))
	end
	for _, side in { "L", "R" } do
		local K: { [string]: CFrame } = {}
		for _, part in { "Clav", "Arm", "Fore", "Hand", "Thigh", "Shin", "Foot", "Toe" } do
			local j = rig.Joints[side .. part]
			local pName = PARENT[part]
			local Kp = (pName == "Chest" or pName == "Hips") and CFrame.identity or (K[pName] or CFrame.identity)
			local Kj = Kp
			local want = REST_DIR["L" .. part]
			local child = CHILD[part] and rig.Joints[side .. CHILD[part]]
			if j and want and child then
				local here = rest(j.Bone).Position
				local dNew = (rest(child.Bone).Position - here).Unit
				if side == "R" then
					want = Vector3.new(-want.X, want.Y, want.Z)
				end
				Kj = align(Kp:VectorToWorldSpace(dNew), want.Unit) * Kp
			end
			K[part] = Kj
			if j then
				j.K = Kj
				j.KpInv = Kp:Inverse()
			end
		end
	end
	-- fingers (v156: the biped's Digit<finger><knuckle>, finger 1 the thumb)
	for name, b in byName do
		local side, f, k = string.match(name, "Human([LR])ArmDigit(%d)(%d)$")
		if side and f and k then
			table.insert(rig.Fingers[side], { Bone = b, K = tonumber(k), Thumb = f == "1" })
		end
	end
	return rig :: any
end

-- (v147, the owner: "Make the monsters model much creepier") longer than a man: the upper arms, the
-- forearms, the fingers and the neck drawn out (each bone's offset from its parent grown, so the skinned
-- mesh stretches between the joints). Once per body (the server, before it replicates; the reel tools).
-- (v156, the owner: "regular humanoid looking": a man, a little too long in the arm and the neck, no more; one neck bone: Head's offset is the neck)
SkinPose.Stretch = { LFore = 1.08, RFore = 1.08, LHand = 1.12, RHand = 1.12, Head = 1.18 }
SkinPose.FingerStretch = 1.3
SkinPose.ThumbStretch = 1.15
function SkinPose.stretch(body: Instance)
	if body:GetAttribute("Stretched") then
		return
	end
	body:SetAttribute("Stretched", true)
	local byName = {}
	for _, d in body:GetDescendants() do
		if d:IsA("Bone") then
			byName[d.Name] = d
		end
	end
	local function grow(b: any, k: number)
		local c = b.CFrame
		b.CFrame = (c - c.Position) + c.Position * k
	end
	for joint, k in SkinPose.Stretch do
		local b = byName[JOINTS[joint]]
		if b then
			grow(b, k)
		end
	end
	for name, b in byName do
		local side, f, k = string.match(name, "Human([LR])ArmDigit(%d)(%d)$")
		-- (from the second knuckle on: the palm keeps its size, the fingers grow)
		if side and k and tonumber(k) >= 2 then
			grow(b, f == "1" and SkinPose.ThumbStretch or SkinPose.FingerStretch)
		end
	end
end

-- pose -> { [Bone]: Transform }
function SkinPose.transforms(rig: Rig, pose: { [string]: any }): { [Instance]: CFrame }
	local out = {}
	-- (v156) joints this body doesn't have: onto the joint above
	for from, to in MERGE do
		if pose[from] and not rig.Joints[from] then
			pose[to] = (pose[to] or CFrame.identity) * pose[from]
			pose[from] = nil
		end
	end
	for joint, j in rig.Joints do
		local r = pose[joint]
		-- (v156) the rest corrections: K_parent^-1 * gait * K_joint
		if j.K then
			r = j.KpInv * (r or CFrame.identity) * j.K
		end
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
	if plant > 0 and rig.Plant and rig.Joints.Hips and out[rig.Joints.Hips.Bone] then
		local pl = rig.Plant
		local hips = rig.Joints.Hips
		local base = pl.Base * hips.Local
		local hw = base * out[hips.Bone]
		local err = math.huge
		for _, sd in { "L", "R" } do
			local th, sh, ft, to = rig.Joints[sd .. "Thigh"], rig.Joints[sd .. "Shin"], rig.Joints[sd .. "Foot"], rig.Joints[sd .. "Toe"]
			-- (v152: a body whose leg bones haven't all arrived: one device logged this 16,104 times. Skip that leg)
			if not (th and sh and ft and out[th.Bone] and out[sh.Bone]) then
				continue
			end
			local a = hw * th.Local * out[th.Bone] * sh.Local * out[sh.Bone] * ft.Local
			err = min(err, a.Position.Y - pl.Foot)
			if to then
				err = min(err, (a * out[ft.Bone] * to.Local).Position.Y - pl.Toe)
			end
		end
		if err < math.huge then
			out[hips.Bone] = base:Inverse() * CFrame.new(0, -err * plant, 0) * hw
		end
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
			-- (v156: the biped's knuckles bend about their own Z)
			out[f.Bone] = CFrame.Angles(0, 0, SkinPose.CurlSign * amt * (f.K == 1 and 0.7 or 1.0))
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
		-- (v143, the owner: "better run animation... creepier") a low splayed scuttle, not a gallop: the torso flat and
		-- close to the floor with the hips high behind it, the long arms thrown out wide and planted far ahead like a
		-- spider's front legs, elbows and knees jutting up and out, the hind legs splayed and bounding a beat apart, the
		-- head cocked over and locked on you, snapping round now and then; one arm reaches a little further than the other
		local flex = sin(phase)
		local wave = sin(phase + 0.9)
		set(P, "Hips", -0.42 + 0.06 * wave)
		set(P, "Spine", -1.0 + 0.22 * flex, 0.1 * sin(phase * 0.5), 0.08 * wave)
		set(P, "Spine2", -0.55 + 0.16 * wave, 0, -0.06 * flex)
		set(P, "Chest", -0.32 + 0.08 * flex, 0.06 * cos(phase), 0)
		set(P, "Neck", 1.08 - 0.1 * flex)
		set(P, "Neck2", 0.52)
		local jerk, js = snap(t, sd + 11, 1.7)
		set(P, "Head", 0.42 + 0.08 * cos(phase * 2), 0.06 * drift(t * 2, sd) + 0.5 * jerk * js, 0.42 + 0.1 * drift(t, sd + 3))
		local function hind(side: string, ph: number, out: number)
			local ss, cc = sin(ph), cos(ph)
			set(P, side .. "Thigh", 1.25 + 0.62 * ss, 0, out * (0.32 + 0.1 * cc))
			set(P, side .. "Shin", -1.7 - 0.45 * sin(ph + 0.9))
			set(P, side .. "Foot", 0.5 - 0.35 * cc)
			set(P, side .. "Toe", 0.35 * max(0, -cc))
		end
		hind("L", phase, -1)
		hind("R", phase - 0.55, 1)
		local function front(side: string, ph: number, roll: number, reach: number)
			local ss, cc = sin(ph), cos(ph)
			set(P, side .. "Clav", 0.32 + 0.18 * ss, 0, 0.12 * roll)
			set(P, side .. "Arm", 1.35 + reach * ss, 0, roll)
			-- (the elbow juts up and out as the hand swings forward; locked straight while it's planted)
			set(P, side .. "Fore", 0.1 + 1.0 * max(0, cc), 0, 0.25 * roll * max(0, cc))
			set(P, side .. "Hand", -0.7 + 0.55 * max(0, cc))
		end
		front("L", phase + PI + 0.3, 0.78, 0.86)
		front("R", phase + PI + 0.78, -0.72, 1.02)
		P.Root = { 0.12 * sin(phase * 0.5), -2.45 + 0.42 * sin(phase + 1.2), 2.1 }
		P.CurlL, P.CurlR = -0.05, 0.02
		P.Mouth = 0.25 + 0.15 * sin(phase)
		P.Twitch = 0.65
	elseif gait == "Walk" or gait == "Search" then
		local search = gait == "Search"
		stance(P, 1)
		-- (v149, the owner: "animations... actually scary") a lurching, dragging walk: the left leg strides, the right
		-- swings short and late with its toe scraping (a hitch in every step), the body dropping onto it; the long arms
		-- hang and swing a beat behind like dead weight; one shoulder rides higher; the head stays cocked over
		local function leg(side: string, ph: number, stride: number, drag: number)
			local ss, cc = sin(ph), cos(ph)
			local thigh = stride * ss
			local knee = -0.85 * (1 - drag * 0.6) * max(0, cc) ^ 1.3 - 0.08
			set(P, side .. "Thigh", thigh)
			set(P, side .. "Shin", knee)
			set(P, side .. "Foot", -(thigh + knee) * 0.8 + 0.18 * max(0, -ss) + 0.35 * drag * max(0, cc))
			set(P, side .. "Toe", 0.25 * max(0, -ss) + 0.3 * drag)
		end
		local hitch = phase + PI + 0.45 * sin(phase) -- (the right leg comes through late, then catches up)
		leg("L", phase, 0.5, 0)
		leg("R", hitch, 0.28, 1)
		-- the pelvis rolls and turns with each step, the shoulders against it; he drops hard onto the short leg
		set(P, "Hips", 0, 0.12 * s, 0.07 * c + 0.06)
		set(P, "Chest", 0, -0.14 * s, -0.06 * c - 0.05)
		P.Root[2] += -0.12 * abs(s) - 0.12 * max(0, -s)
		P.Root[1] += 0.18 * c
		set(P, "LClav", 0.1, 0, 0.08)
		local swing = sin(phase - 0.7) -- (a beat behind the stride)
		set(P, "LArm", -0.14 * swing, 0, 0.05 * abs(swing))
		set(P, "RArm", 0.18 * swing, 0, -0.04 * abs(swing))
		set(P, "LFore", 0.12 * max(0, -swing) + 0.06)
		set(P, "RFore", 0.16 * max(0, swing) + 0.06)
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
			-- cocked well over to one side, bobbing with the lurch
			set(P, "Head", 0.06 * c + 0.05 * max(0, -s), 0.15 * drift(t, sd), 0.34 + 0.12 * drift(t * 0.6, sd + 5))
			set(P, "Neck2", 0, 0, 0.1)
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
	elseif gait == "Sit" then
		-- (v115, for the reels: sitting at the head of the family's table) on a chair, knees up,
		-- forearms on the table, the head laid over, watching; seat height ~2.2 studs
		stance(P, 0.35)
		set(P, "LThigh", 1.45, 0.05, 0.06)
		set(P, "RThigh", 1.45, -0.05, -0.06)
		set(P, "LShin", -1.5)
		set(P, "RShin", -1.5)
		set(P, "LFoot", 0.1)
		set(P, "RFoot", 0.1)
		set(P, "Spine", -0.08)
		set(P, "LArm", 0.7, 0, 0.1)
		set(P, "RArm", 0.7, 0, -0.1)
		set(P, "LFore", 0.95)
		set(P, "RFore", 0.95)
		set(P, "LHand", -0.2)
		set(P, "RHand", -0.2)
		local tilt = 0.35 + 0.1 * drift(t * 0.4, sd)
		set(P, "Head", -0.05, 0.1 * drift(t * 0.5, sd + 1), tilt)
		life(P, t, sd, 0.6)
		P.Root = { 0, -3.15, 0.1 }
		P.Plant = 0
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
		-- (v147) and every few seconds the head jerks over, hard, like something pulled it
		local jerk, js = snap(t, sd + 21, 2.6)
		set(P, "Neck2", 0, 0.15 * jerk * js, 0)
		set(P, "Head", 0.08 * jerk, 0.22 * jerk * js, 0.55 * jerk * js)
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
		-- (v156: his jaw drops open as he screams; a little slack when he's agitated)
	local open = math.max(P.Scream or 0, (P.Twitch or 0) * 0.15)
	if open > 0 then
		pose.Jaw = A(SkinPose.JawSign * 0.6 * open, 0, 0)
	end
	local r = P.Root
	if r then
		local k = SkinPose.Units * (scale or 1)
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
