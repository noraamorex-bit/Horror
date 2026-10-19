--[[
	CreaturePose — how Curtis moves, as joint rotations (Motor6D.Transform) for his R15 rig
	(server/Intruder/Rig). The client applies them (client/Controllers/Creature, which also
	plays them back like stop-motion: held for a few frames, then the next); the preview harness
	uses the same function to render stills.

		CreaturePose.get(gait, phase, t, seed) -> { [jointName]: CFrame }

	gait: "Chase" | "Walk" | "Idle" | "Stare" | "Reach" | "Stunned" | "Search" | "Peek"
	phase: stride phase in radians (advance by speed); t: seconds (twitches, sway)

	v99: he's nearly ten feet of jointed limbs now. He walks hunched with his head hanging forward
	and cocked, arms swinging loose to his knees; he runs on all fours, his long arms reaching out
	and slapping down in front of him like front legs, head craned up to keep looking at you;
	standing still, his head lolls sideways further than a neck should go, and now and then it turns
	right round to look behind him.

	Rig axes: X right, Y up, -Z forward. A limb hanging down swings forward with +X;
	the torso leans forward with -X; a knee bends with -X, an elbow with +X.
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

-- now and then, standing still, the head turns all the way round to look behind him and holds
-- there, then snaps back: returns the extra yaw
local function owl(t: number, seed: number): number
	local every = 9
	local slot = math.floor(t / every)
	if hash(slot + seed * 3.7) < 0.5 then
		return 0
	end
	local lt = t - slot * every - 2
	if lt < 0 or lt > 2.6 then
		return 0
	end
	local dir = hash(slot + 1.3) < 0.5 and -1 or 1
	-- (0.5 s round, 1.6 s held, a snap back)
	local k = lt < 0.5 and lt / 0.5 or (lt < 2.1 and 1 or 1 - (lt - 2.1) / 0.5)
	return dir * 2.5 * k
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
		-- on all fours: the trunk pitched forward, the long arms thrown out in front and slapped
		-- down like front legs, the back legs bent and driving, the head craned right up at you
		local lean = -1.0
		local bob = abs(sin(phase)) * 0.3
		P.Root = CFrame.new(0, -0.85 + bob, 0) * A(lean + 0.07 * sin(phase * 2), 0.1 * sp, 0.05 * cp)
		P.Waist = A(-0.22 + 0.08 * sin(phase * 2), 0.18 * sp, 0)
		local ty, tr = twitch(t, s, 1.0, 0.45)
		P.Neck = A(1.25 + jitter(t, 0.05), ty - 0.15 * sp, 0.3 + tr + jitter(t + 3, 0.06))
		-- the arms: opposite to the legs, reaching forward and down past the head
		local armL, armR = legR, legL
		P.LeftShoulder = A(1.95 + 0.62 * sin(armL), 0, -0.12)
		P.RightShoulder = A(1.95 + 0.62 * sin(armR), 0, 0.12)
		P.LeftElbow = A(0.12 + 0.5 * max(0, -cos(armL)), 0, 0)
		P.RightElbow = A(0.12 + 0.5 * max(0, -cos(armR)), 0, 0)
		P.LeftWrist = A(-0.5 + 0.4 * sin(armL), 0, 0)
		P.RightWrist = A(-0.5 + 0.4 * sin(armR), 0, 0)
		-- the legs: the trunk's pitch taken out at the hip, then a deep crouching stride
		local hipBase = -lean - 0.22 + 0.45
		P.LeftHip = A(hipBase + 0.75 * sin(legL), 0, -0.1)
		P.RightHip = A(hipBase + 0.75 * sin(legR), 0, 0.1)
		P.LeftKnee = A(-(0.75 + 0.85 * max(0, cos(legL))), 0, 0)
		P.RightKnee = A(-(0.75 + 0.85 * max(0, cos(legR))), 0, 0)
		P.LeftAnkle = A(0.35 + 0.3 * sin(legL - 0.6), 0, 0)
		P.RightAnkle = A(0.35 + 0.3 * sin(legR - 0.6), 0, 0)
	elseif gait == "Walk" or gait == "Search" then
		-- slow, too-long strides, hunched, the head hanging forward and cocked hard to one side;
		-- the arms swing loose, fingers at his knees
		local search = gait == "Search"
		local lean = search and -0.42 or -0.3
		P.Root = CFrame.new(0, -0.18 + abs(sp) * 0.1, 0) * A(lean, 0.08 * sp, 0.05 * sp)
		P.Waist = A(-0.24, 0.12 * sp, 0.05 * cp)
		local ty, tr = twitch(t, s, 1.8, 0.8)
		local scan = search and 0.7 * sin(t * 1.25) or 0.1 * sin(t * 0.7)
		P.Neck = A(0.42 + jitter(t, 0.03), scan + ty, 0.62 + tr + jitter(t + 1, 0.03))
		-- (the arms hang from a body leaning forward: swung forward that much to hang straight)
		local hang = -(lean - 0.24) * 0.8
		P.LeftShoulder = A(hang - 0.3 * sin(phase), 0, -0.07)
		P.RightShoulder = A(hang + 0.3 * sin(phase), 0, 0.07)
		P.LeftElbow = A(0.22 + 0.1 * sin(phase), 0, 0)
		P.RightElbow = A(0.22 - 0.1 * sin(phase), 0, 0)
		if search then
			-- one hand up and out, the fingers feeling the air in front of him
			P.RightShoulder = A(hang + 0.75 + 0.1 * sin(t * 1.7), 0, 0.2)
			P.RightElbow = A(0.45 + 0.1 * sin(t * 2.3), 0, 0)
		end
		P.LeftWrist = A(0.2 + 0.12 * sin(t * 2.1), 0, 0)
		P.RightWrist = A(0.2, 0, 0)
		local hipBase = -lean + 0.18
		P.LeftHip = A(hipBase + 0.5 * sin(legL), 0, 0)
		P.RightHip = A(hipBase + 0.5 * sin(legR), 0, 0)
		P.LeftKnee = A(-(0.3 + 0.7 * max(0, cos(legL))), 0, 0)
		P.RightKnee = A(-(0.3 + 0.7 * max(0, cos(legR))), 0, 0)
		P.LeftAnkle = A(0.12 + 0.15 * sin(legL - 0.5), 0, 0)
		P.RightAnkle = A(0.12 + 0.15 * sin(legR - 0.5), 0, 0)
	elseif gait == "Reach" then
		-- folded down over you, both arms out in front, the long fingers first: opening a
		-- closet, grabbing you
		P.Root = CFrame.new(0, -0.45, 0) * A(-0.45, 0, 0)
		P.Waist = A(-0.3, 0, 0)
		local ty, tr = twitch(t, s, 0.8, 0.4)
		P.Neck = A(0.5 + jitter(t, 0.04), ty, 0.75 + tr)
		P.LeftShoulder = A(1.75 + 0.1 * sin(t * 3), 0.1, -0.12)
		P.RightShoulder = A(1.6 + 0.1 * sin(t * 3 + 1), -0.1, 0.12)
		P.LeftElbow = A(0.3, 0, 0)
		P.RightElbow = A(0.42, 0, 0)
		P.LeftWrist = A(-0.25 + 0.15 * sin(t * 5), 0, 0)
		P.RightWrist = A(-0.3, 0, 0)
		P.LeftHip = A(0.95, 0, -0.06)
		P.RightHip = A(1.05, 0, 0.06)
		P.LeftKnee = A(-0.9, 0, 0)
		P.RightKnee = A(-1.0, 0, 0)
		P.LeftAnkle = A(0.25, 0, 0)
		P.RightAnkle = A(0.3, 0, 0)
	elseif gait == "Stunned" then
		-- doubled over, the hands clawing at the mask, shaking
		local shake = jitter(t * 1.6, 0.12)
		P.Root = CFrame.new(0, -0.7, 0) * A(-0.55 + shake, 0, shake)
		P.Waist = A(-0.35, shake, 0)
		P.Neck = A(-0.45 + shake, jitter(t + 2, 0.25), jitter(t + 4, 0.25))
		P.LeftShoulder = A(0.75, 0.2, -0.3)
		P.RightShoulder = A(0.75, -0.2, 0.3)
		P.LeftElbow = A(2.2 + shake, 0, 0)
		P.RightElbow = A(2.2 - shake, 0, 0)
		P.LeftWrist = A(0.4, 0, 0)
		P.RightWrist = A(0.4, 0, 0)
		P.LeftHip = A(1.15, 0, -0.12)
		P.RightHip = A(0.85, 0, 0.12)
		P.LeftKnee = A(-1.2, 0, 0)
		P.RightKnee = A(-0.9, 0, 0)
		P.LeftAnkle = A(0.3, 0, 0)
		P.RightAnkle = A(0.2, 0, 0)
	elseif gait == "Peek" then
		-- leaning out from behind a door frame (the frame on his right): the body tipped
		-- sideways, the head laid over flat, one hand up curled round the edge
		P.Root = CFrame.new(0.2, -0.3, 0) * A(-0.12, 0.25, -0.38)
		P.Waist = A(-0.1, 0.1, -0.22)
		local ty, tr = twitch(t, s, 1.5, 0.35)
		P.Neck = A(0.25 + jitter(t, 0.02), 0.2 + ty, -1.25 + tr * 0.5 + jitter(t + 2, 0.02))
		P.RightShoulder = A(1.15, 0, 1.0)
		P.RightElbow = A(1.3 + 0.05 * sin(t * 4), 0, 0)
		P.RightWrist = A(0.5, 0, 0)
		P.LeftShoulder = A(0.15, 0, -0.2)
		P.LeftElbow = A(0.3, 0, 0)
		P.LeftWrist = A(0.15 + 0.2 * max(0, sin(t * 1.3)) ^ 4, 0, 0)
		P.LeftHip = A(0.2, 0, 0.42)
		P.RightHip = A(0.15, 0, 0.3)
		P.LeftKnee = A(-0.25, 0, 0)
		P.RightKnee = A(-0.2, 0, 0)
	elseif gait == "Stare" then
		-- dead still at full height, the head laid over on one side, looking straight at you.
		-- Every so often it jerks.
		local breathe = sin(t * 1.1)
		P.Root = CFrame.new(0, -0.1, 0) * A(-0.06, 0, 0)
		P.Waist = A(-0.08 + breathe * 0.012, 0, 0)
		local ty, tr = twitch(t, s, 2.4, 0.45)
		P.Neck = A(0.12 + jitter(t, 0.012), ty * 0.6, 1.05 + tr + jitter(t + 2, 0.012))
		P.LeftShoulder = A(0.02, 0, -0.04)
		P.RightShoulder = A(0.02, 0, 0.04)
		P.LeftElbow = A(0.06, 0, 0)
		P.RightElbow = A(0.06, 0, 0)
		-- the fingers of one hand flex, slowly, then quick
		P.LeftWrist = A(0.1 + 0.35 * max(0, sin(t * 0.9)) ^ 6, 0, 0)
		P.RightWrist = A(0.1, 0, 0)
		P.LeftHip = A(0.06, 0, -0.05)
		P.RightHip = A(0.06, 0, 0.05)
		P.LeftKnee = A(-0.04, 0, 0)
		P.RightKnee = A(-0.04, 0, 0)
	else -- Idle: standing too still, breathing, the head slowly turning, snapping, and turning round
		local breathe = sin(t * 1.4)
		P.Root = CFrame.new(0, -0.15 + breathe * 0.03, 0) * A(-0.18 + breathe * 0.015, 0, 0)
		P.Waist = A(-0.16 + breathe * 0.02, 0, 0)
		local ty, tr = twitch(t, s, 1.6, 0.9)
		local back = owl(t, s)
		P.Neck = A(0.3, 0.55 * sin(t * 0.45) * (back == 0 and 1 or 0) + ty + back, 0.5 + tr + jitter(t, 0.02))
		P.LeftShoulder = A(0.27 + breathe * 0.02, 0, -0.05)
		P.RightShoulder = A(0.27 + breathe * 0.02, 0, 0.05)
		P.LeftElbow = A(0.15, 0, 0)
		P.RightElbow = A(0.15, 0, 0)
		-- the fingers of one hand flex
		P.LeftWrist = A(0.1 + 0.18 * sin(t * 2.3), 0, 0)
		P.RightWrist = A(0.1, 0, 0)
		P.LeftHip = A(0.22, 0, -0.05)
		P.RightHip = A(0.22, 0, 0.05)
		P.LeftKnee = A(-0.12, 0, 0)
		P.RightKnee = A(-0.12, 0, 0)
	end
	return P
end

-- strides per stud of travel, per gait (radians of phase per stud)
function CreaturePose.phaseRate(gait: string): number
	if gait == "Chase" then
		return 2 * math.pi / 8.5
	end
	return 2 * math.pi / 6.2
end

return CreaturePose
