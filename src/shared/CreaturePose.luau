--[[
	CreaturePose — how Curtis moves, as joint rotations (Motor6D.Transform) for his R15 rig
	(server/Intruder/Rig). The client applies them every frame (client/Controllers/Creature);
	the preview harness uses the same function to render stills.

		CreaturePose.get(gait, phase, t, seed) -> { [jointName]: CFrame }

	gait: "Chase" | "Walk" | "Idle" | "Stare" | "Reach" | "Stunned" | "Search"
	phase: stride phase in radians (advance by speed); t: seconds (twitches, sway)

	Rig axes: X right, Y up, -Z forward. A limb hanging down swings forward with +X;
	the torso leans forward with -X.
]]

local CreaturePose = {}

local A = CFrame.Angles
local sin, cos, max, abs = math.sin, math.cos, math.max, math.abs

-- deterministic noise: the same t always gives the same twitch, so no state is needed
local function hash(n: number): number
	local x = math.sin(n * 127.1 + 311.7) * 43758.5453
	return x - math.floor(x)
end

-- a sudden snap of the head every couple of seconds: returns yaw, roll offsets
local function twitch(t: number, seed: number, every: number, strength: number): (number, number)
	local slot = math.floor(t / every)
	local h = hash(slot + seed * 17.3)
	if h < 0.45 then
		return 0, 0
	end
	local start = hash(slot + 3.1 + seed) * every * 0.7
	local local_t = t - slot * every - start
	local dur = 0.12 + hash(slot + 9.7) * 0.25
	if local_t < 0 or local_t > dur then
		return 0, 0
	end
	-- snap there and hold, no easing: it should look wrong
	local yaw = (hash(slot + 5.5) - 0.5) * 2 * strength
	local roll = (hash(slot + 7.9) - 0.5) * 2 * strength * 0.8
	return yaw, roll
end

-- constant tiny tremor
local function jitter(t: number, amount: number): number
	return (sin(t * 37.1) * 0.6 + sin(t * 53.7) * 0.4) * amount
end

function CreaturePose.get(gait: string, phase: number, t: number, seed: number?): { [string]: CFrame }
	local s = seed or 0
	local P = {}
	local sp, cp = sin(phase), cos(phase)
	local legL, legR = phase, phase + math.pi

	if gait == "Chase" then
		-- bent almost double, head craned up to keep looking at you, arms flailing
		local lean = -0.55
		local bob = abs(sin(phase)) * 0.22
		P.Root = CFrame.new(0, -0.35 + bob, 0) * A(lean + 0.05 * sin(phase * 2), 0.12 * sp, 0)
		P.Waist = A(-0.25 + 0.06 * sin(phase * 2), 0.22 * sp, 0)
		local ty, tr = twitch(t, s, 1.1, 0.5)
		P.Neck = A(0.85 + jitter(t, 0.05), ty - 0.22 * sp, 0.18 + tr + jitter(t + 3, 0.06))
		P.LeftShoulder = A(-0.45 - 1.15 * sin(phase), 0, -0.35 - 0.15 * abs(sp))
		P.RightShoulder = A(-0.45 + 1.15 * sin(phase), 0, 0.35 + 0.15 * abs(sp))
		P.LeftElbow = A(0.55 + 0.45 * max(0, -sin(phase)), 0, 0)
		P.RightElbow = A(0.55 + 0.45 * max(0, sin(phase)), 0, 0)
		P.LeftWrist = A(0.2 + 0.3 * sin(phase + 1), 0, 0)
		P.RightWrist = A(0.2 - 0.3 * sin(phase + 1), 0, 0)
		-- legs: the root lean is taken out at the hip so they still reach the floor
		local hipBase = -lean - 0.25
		P.LeftHip = A(hipBase + 0.95 * sin(legL), 0, -0.04)
		P.RightHip = A(hipBase + 0.95 * sin(legR), 0, 0.04)
		P.LeftKnee = A(-(0.35 + 1.25 * max(0, cos(legL))), 0, 0)
		P.RightKnee = A(-(0.35 + 1.25 * max(0, cos(legR))), 0, 0)
		P.LeftAnkle = A(0.25 * sin(legL - 0.6), 0, 0)
		P.RightAnkle = A(0.25 * sin(legR - 0.6), 0, 0)
	elseif gait == "Walk" or gait == "Search" then
		-- slow, long strides, the head cocked hard to one side; arms dead weight
		local lean = gait == "Search" and -0.32 or -0.2
		P.Root = CFrame.new(0, -0.12 + abs(sp) * 0.08, 0) * A(lean, 0.06 * sp, 0.03 * sp)
		P.Waist = A(-0.14, 0.1 * sp, 0.04 * cp)
		local ty, tr = twitch(t, s, 1.9, 0.75)
		local scan = gait == "Search" and 0.55 * sin(t * 1.3) or 0.12 * sin(t * 0.7)
		P.Neck = A(0.22 + jitter(t, 0.03), scan + ty, 0.42 + tr + jitter(t + 1, 0.03))
		P.LeftShoulder = A(0.1 - 0.28 * sin(phase), 0, -0.06)
		P.RightShoulder = A(0.1 + 0.28 * sin(phase), 0, 0.06)
		P.LeftElbow = A(0.18 + 0.08 * sin(phase), 0, 0)
		P.RightElbow = A(0.18 - 0.08 * sin(phase), 0, 0)
		P.LeftWrist = A(0.15, 0, 0)
		P.RightWrist = A(0.15, 0, 0)
		local hipBase = -lean - 0.05
		P.LeftHip = A(hipBase + 0.55 * sin(legL), 0, 0)
		P.RightHip = A(hipBase + 0.55 * sin(legR), 0, 0)
		P.LeftKnee = A(-(0.12 + 0.75 * max(0, cos(legL))), 0, 0)
		P.RightKnee = A(-(0.12 + 0.75 * max(0, cos(legR))), 0, 0)
		P.LeftAnkle = A(0.15 * sin(legL - 0.5), 0, 0)
		P.RightAnkle = A(0.15 * sin(legR - 0.5), 0, 0)
	elseif gait == "Reach" then
		-- both arms out in front, long fingers first: opening a closet, grabbing you
		P.Root = CFrame.new(0, -0.2, 0) * A(-0.28, 0, 0)
		P.Waist = A(-0.2, 0, 0)
		local ty, tr = twitch(t, s, 0.9, 0.35)
		P.Neck = A(0.15 + jitter(t, 0.04), ty, 0.3 + tr)
		P.LeftShoulder = A(1.45 + 0.08 * sin(t * 3), 0.1, -0.1)
		P.RightShoulder = A(1.35 + 0.08 * sin(t * 3 + 1), -0.1, 0.1)
		P.LeftElbow = A(0.25, 0, 0)
		P.RightElbow = A(0.35, 0, 0)
		P.LeftWrist = A(-0.3, 0, 0)
		P.RightWrist = A(-0.3, 0, 0)
		P.LeftHip = A(0.33, 0, 0)
		P.RightHip = A(0.48, 0, 0)
		P.LeftKnee = A(-0.25, 0, 0)
		P.RightKnee = A(-0.35, 0, 0)
	elseif gait == "Stunned" then
		-- hands clawing at the mask, doubled over, shaking
		local shake = jitter(t * 1.6, 0.12)
		P.Root = CFrame.new(0, -0.5, 0) * A(-0.5 + shake, 0, shake)
		P.Waist = A(-0.35, shake, 0)
		P.Neck = A(-0.3 + shake, jitter(t + 2, 0.2), jitter(t + 4, 0.2))
		P.LeftShoulder = A(2.2, 0, -0.2)
		P.RightShoulder = A(2.2, 0, 0.2)
		P.LeftElbow = A(1.7 + shake, 0, 0)
		P.RightElbow = A(1.7 - shake, 0, 0)
		P.LeftHip = A(0.9, 0, -0.1)
		P.RightHip = A(0.6, 0, 0.1)
		P.LeftKnee = A(-0.9, 0, 0)
		P.RightKnee = A(-0.6, 0, 0)
	elseif gait == "Stare" then
		-- dead still, the head cocked, looking straight at you. Every so often it jerks.
		local breathe = sin(t * 1.1)
		P.Root = CFrame.new(0, -0.18, 0) * A(-0.12, 0, 0)
		P.Waist = A(-0.1 + breathe * 0.012, 0, 0)
		local ty, tr = twitch(t, s, 2.4, 0.5)
		P.Neck = A(0.18 + jitter(t, 0.015), ty * 0.6, 0.55 + tr + jitter(t + 2, 0.015))
		P.LeftShoulder = A(0.02, 0, -0.03)
		P.RightShoulder = A(0.02, 0, 0.03)
		P.LeftElbow = A(0.08, 0, 0)
		P.RightElbow = A(0.08, 0, 0)
		P.LeftWrist = A(0.1 + 0.25 * max(0, sin(t * 0.9)) ^ 6, 0, 0)
		P.RightWrist = A(0.1, 0, 0)
		P.LeftHip = A(0.12, 0, -0.05)
		P.RightHip = A(0.12, 0, 0.05)
		P.LeftKnee = A(-0.06, 0, 0)
		P.RightKnee = A(-0.06, 0, 0)
	else -- Idle: standing too still, breathing, the head slowly turning, then snapping
		local breathe = sin(t * 1.4)
		P.Root = CFrame.new(0, -0.15 + breathe * 0.03, 0) * A(-0.16 + breathe * 0.015, 0, 0)
		P.Waist = A(-0.12 + breathe * 0.02, 0, 0)
		local ty, tr = twitch(t, s, 1.6, 0.9)
		P.Neck = A(0.12, 0.65 * sin(t * 0.45) + ty, 0.38 + tr + jitter(t, 0.02))
		P.LeftShoulder = A(0.05 + breathe * 0.02, 0, -0.04)
		P.RightShoulder = A(0.05 + breathe * 0.02, 0, 0.04)
		P.LeftElbow = A(0.12, 0, 0)
		P.RightElbow = A(0.12, 0, 0)
		-- the fingers of one hand flex
		P.LeftWrist = A(0.1 + 0.15 * sin(t * 2.3), 0, 0)
		P.RightWrist = A(0.1, 0, 0)
		P.LeftHip = A(0.17, 0, -0.05)
		P.RightHip = A(0.17, 0, 0.05)
		P.LeftKnee = A(-0.1, 0, 0)
		P.RightKnee = A(-0.1, 0, 0)
	end
	return P
end

-- strides per stud of travel, per gait (radians of phase per stud)
function CreaturePose.phaseRate(gait: string): number
	if gait == "Chase" then
		return 2 * math.pi / 7.5
	end
	return 2 * math.pi / 5.2
end

return CreaturePose
