--[[
	ActPose (v147, the owner: "make animations for everything like brushing and peeking out and all
	things"): what a player's body does while they use something. Pure maths, shared by the server
	(which action a prompt is: ActPose.kindFor) and the client (Actions: poses every character's
	R15 joints over its walk/idle animation, every frame).

	A pose is a set of targets in the UpperTorso's space (-Z forward, +X the character's right):
	where each wrist goes, a waist lean, a head tilt. ActPose.solve turns them into Motor6D
	Transforms with a two-bone arm IK that reads the real rig's C0/C1, so it fits any R15 avatar's
	size. `fp` = the local player's own first-person view: hands held further out and lower, so
	they're on screen (the camera sits in the head).

		ActPose.kindFor(actionText) -> kind?
		ActPose.Kinds[kind] = { Hold = bool, Time = seconds (one-shot), Prop = "Toothbrush"|"Phone"|"Paper"|nil }
		ActPose.targets(kind, t, fp) -> { R = Vector3?, L = Vector3?, Waist = number?, Neck = number?, RWrist = CFrame?, ... }
		ActPose.solve(rig, targets) -> { [jointName]: CFrame }
]]

local ActPose = {}

-- prompt action text (lowercase, first match wins) -> kind
ActPose.Keywords = {
	{ "brush", "Brush" },
	{ "call 911", "Call" },
	{ "order", "Phone" },
	{ "search", "Search" },
	{ "splice", "Work" },
	{ "cut", "Work" },
	{ "light the fire", "Work" },
	{ "make popcorn", "Take" },
	{ "enter code", "Code" },
	{ "knock", "Knock" },
	{ "pull", "Pull" },
	{ "push", "Push" },
	{ "smash", "Push" },
	{ "bar the door", "Push" },
	{ "answer", "Push" },
	{ "open", "Push" },
	{ "close", "Push" },
	{ "unlock", "Press" },
	{ "lock", "Press" },
	{ "flip", "Press" },
	{ "press", "Press" },
	{ "switch", "Press" },
	{ "turn on", "Press" },
	{ "turn off", "Press" },
	{ "read", "Read" },
	{ "inspect", "Read" },
	{ "look", "Read" },
	{ "take", "Take" },
	{ "pick up", "Take" },
	{ "put down", "Take" },
	{ "drive", "Take" },
}

-- Hold: lasts while the prompt is held (then Time more seconds); otherwise a one-shot of Time s
ActPose.Kinds = {
	Brush = { Hold = true, Time = 2.2, Prop = "Toothbrush" },
	Search = { Hold = true, Time = 0.5 },
	Work = { Hold = true, Time = 0.4 },
	Code = { Hold = true, Time = 0.6 },
	Read = { Time = 2.4, Prop = "Paper" },
	Take = { Time = 0.75 },
	Push = { Time = 0.6 },
	Pull = { Hold = true, Time = 0.6 },
	Press = { Time = 0.55 },
	Knock = { Time = 1.2 },
	Phone = { Time = 2.5, Prop = "Phone" },
	Call = { Hold = true, Time = 0.3, Prop = "Phone" }, -- (also while "Calling")
	PhoneOut = { Hold = true, Time = 0.3, Prop = "Phone" }, -- (the phone in your hand: "PhoneOut")
	Drink = { Time = 1.6 },
	Tied = { Hold = true, Time = 0.3 }, -- (zip-tied: arms behind your back; struggling shakes you)
}

function ActPose.kindFor(text: string?): string?
	local t = string.lower(tostring(text or ""))
	if t == "" or t == "hide" or t == "sit" then
		return nil
	end
	for _, e in ActPose.Keywords do
		if string.find(t, e[1], 1, true) then
			return e[2]
		end
	end
	return nil
end

local V = Vector3.new
local sin, cos, pi = math.sin, math.cos, math.pi

-- an envelope for one-shots: 0 -> 1 -> 0 over [0, 1] with a held middle
local function bump(x: number, a: number?, b: number?): number
	a = a or 0.3
	b = b or 0.7
	if x <= 0 or x >= 1 then
		return 0
	elseif x < a then
		local k = x / a
		return k * k * (3 - 2 * k)
	elseif x > b then
		local k = (1 - x) / (1 - b)
		return k * k * (3 - 2 * k)
	end
	return 1
end
ActPose._bump = bump

--[[
	Targets, in units of a standard R15 (scaled by the rig at solve time), relative to the UpperTorso
	centre. The head's centre is about (0, 1.3, 0); the right shoulder joint (1, 0.56, 0); arms reach
	~1.5 to the wrist. t = seconds since the action began; x = t / Time for one-shots.
]]
function ActPose.targets(kind: string, t: number, fp: boolean?): any
	local def = ActPose.Kinds[kind]
	if not def then
		return nil
	end
	local x = def.Hold and 0.5 or math.clamp(t / def.Time, 0, 1)
	local out: any = {}
	-- (the first-person versions bring the hands out in front of the eye, into view)
	local F = fp and 1 or 0
	if kind == "Brush" then
		-- toothbrush at the mouth, scrubbing side to side; the other hand on the basin
		local scrub = sin(t * 15) * 0.09
		out.R = V(0.22 + scrub + F * 0.1, 1.05 - F * 0.3, -0.62 - F * 0.5)
		out.RWrist = CFrame.Angles(0, 0, 0.6 + sin(t * 15) * 0.25) * CFrame.Angles(-0.9, 0, 0)
		out.L = V(-0.75, -0.15, -1.05)
		out.Waist = -0.12
		out.Neck = -0.08 + sin(t * 15) * 0.02
		out.NeckYaw = sin(t * 7.5) * 0.04
	elseif kind == "Search" then
		-- bent over, both hands rummaging, turns about
		local r = sin(t * 7)
		out.R = V(0.35 + r * 0.12, -0.35 + F * 0.95 + math.abs(r) * 0.12, -1.1 - F * 0.2)
		out.L = V(-0.35 + r * 0.12, -0.35 + F * 0.95 + math.abs(cos(t * 7)) * 0.12, -1.05 - F * 0.2)
		out.RWrist = CFrame.Angles(-0.5 + r * 0.3, 0, 0)
		out.LWrist = CFrame.Angles(-0.5 - r * 0.3, 0, 0)
		out.Waist = -0.42
		out.Neck = -0.35
		out.NeckYaw = sin(t * 1.7) * 0.18
	elseif kind == "Work" then
		-- both hands working at something in front of you, small and fiddly
		local j = sin(t * 11) * 0.05
		out.R = V(0.22 + j, 0.05 + F * 0.65, -1.05 - F * 0.2)
		out.L = V(-0.22 - j, 0.08 + F * 0.65, -1.0 - F * 0.2)
		out.RWrist = CFrame.Angles(-0.4, sin(t * 11) * 0.3, 0)
		out.LWrist = CFrame.Angles(-0.4, -sin(t * 11) * 0.3, 0)
		out.Waist = -0.22
		out.Neck = -0.4
	elseif kind == "Code" then
		-- tapping a keypad: one finger poking, the other hand flat beside it
		local tap = math.max(0, sin(t * 9)) * 0.14
		out.R = V(0.15, 0.5 + F * 0.3, -1.15 - F * 0.15 + tap)
		out.RWrist = CFrame.Angles(-0.2, 0, 0)
		out.L = V(-0.6, -0.4, -0.75)
		out.Neck = -0.05
	elseif kind == "Read" then
		-- a page held up in both hands, head bowed over it
		local k = bump(x, 0.15, 0.85)
		out.R = V(0.3, 0.25 + k * 0.25 + F * 0.15, -0.95 - F * 0.25)
		out.L = V(-0.3, 0.25 + k * 0.25 + F * 0.15, -0.95 - F * 0.25)
		out.RWrist = CFrame.Angles(-0.3, 0, -0.35)
		out.LWrist = CFrame.Angles(-0.3, 0, 0.35)
		out.Neck = -0.3 * k
		out.Weight = k
	elseif kind == "Take" then
		-- reach out and down, close the hand, bring it back to the chest
		local reach = bump(x, 0.35, 0.55)
		local back = math.clamp((x - 0.55) / 0.45, 0, 1)
		local home = V(0.5, -0.1, -0.7)
		local far = V(0.4, -0.55 + F * 1.05, -1.55 + F * 0.1)
		if fp then
			home = V(0.45, 0.45, -1.0)
		end
		out.R = home:Lerp(far, reach)
		out.RWrist = CFrame.Angles(-0.6 * reach, 0, 0)
		out.Waist = -0.35 * reach
		out.Neck = -0.3 * reach
		out.Weight = math.max(reach, bump(x, 0.1, 0.8) * (1 - back))
	elseif kind == "Push" then
		-- a palm out to the door, a shove
		local k = bump(x, 0.3, 0.6)
		out.R = V(0.55, 0.55 + F * 0.05, -0.6 - k * 0.95)
		out.RWrist = CFrame.Angles(1.1 * k, 0, 0)
		out.Waist = -0.12 * k
		out.Weight = bump(x, 0.2, 0.75)
	elseif kind == "Pull" then
		-- both hands on it, leaning back and heaving
		local heave = 0.5 + 0.5 * sin(t * 4)
		out.R = V(0.35, 0.45 + F * 0.35, -1.35 + heave * 0.3)
		out.L = V(-0.35, 0.45 + F * 0.35, -1.35 + heave * 0.3)
		out.Waist = 0.12 + heave * 0.12
		out.Neck = 0.1
	elseif kind == "Press" then
		-- a quick poke (a switch, a lock, a breaker)
		local k = bump(x, 0.35, 0.55)
		out.R = V(0.35, 0.55, -0.7 - k * 0.65 - F * 0.1)
		out.RWrist = CFrame.Angles(-0.15, 0, 0)
		out.Weight = bump(x, 0.2, 0.7)
	elseif kind == "Knock" then
		-- three raps on the door
		local k = bump(x, 0.15, 0.85)
		local rap = math.max(0, sin(t * 16)) * 0.22
		out.R = V(0.5, 0.95, -1.05 + rap)
		out.RWrist = CFrame.Angles(0.5, 0, 0)
		out.Neck = 0.05
		out.Weight = k
	elseif kind == "Phone" or kind == "PhoneOut" then
		-- the phone held low in front, thumb going, head down at the screen
		local k = kind == "Phone" and bump(x, 0.12, 0.85) or 1
		out.R = V(0.2, 0.2 + F * 0.55, -0.85 - F * 0.3)
		out.RWrist = CFrame.Angles(-0.25, 0, -0.5 + sin(t * 6) * 0.05)
		out.L = V(-0.15, 0.1 + F * 0.55, -0.8 - F * 0.3)
		out.Neck = -0.38 * k
		out.Weight = k
	elseif kind == "Call" then
		-- the phone to your ear (first person: just off to the side, as if it were)
		out.R = fp and V(0.55, 1.0, -0.75) or V(0.55, 1.25, -0.1)
		out.RWrist = CFrame.Angles(0, -1.2, 0)
		out.Neck = 0.02
		out.NeckYaw = sin(t * 0.8) * 0.1
		out.Elbow = V(1, -0.2, -0.3) -- (the elbow out to the side, forward a little)
	elseif kind == "Drink" then
		-- the can to the mouth, head back
		local k = bump(x, 0.25, 0.75)
		out.R = V(0.25, 0.4 + k * 0.6, -0.9 + k * 0.25 - F * 0.4 * k)
		out.RWrist = CFrame.Angles(0.9 * k, 0, 0)
		out.Neck = 0.35 * k
		out.Weight = bump(x, 0.15, 0.85)
	elseif kind == "Tied" then
		-- wrists behind the back; `t` keeps time with the struggle (the client feeds it)
		local w = sin(t * 18) * 0.06
		out.R = V(0.3 + w, -0.45, 0.6)
		out.L = V(-0.3 + w, -0.45, 0.6)
		out.RWrist = CFrame.Angles(0.8, 0, 0)
		out.LWrist = CFrame.Angles(0.8, 0, 0)
		out.Waist = 0.08 + w * 0.6
		out.Neck = -0.25
		out.NeckYaw = sin(t * 2.3) * 0.25
		out.Elbow = V(1, -0.4, 0.6)
	end
	-- (first person: the camera doesn't lean with the body, so a deep bow would drop the hands out of view)
	if fp and out.Waist then
		out.Waist *= 0.3
	end
	return out
end

--[[
	rig = { Scale, Waist, Neck, RS, RE, RW, LS, LE, LW } where each joint is { C0 = CFrame, C1 = CFrame }
	(the Motor6Ds' own offsets: RightShoulder, RightElbow, RightWrist...). Returns joint name -> Transform.
]]
local function frame(dir: Vector3, side: Vector3): CFrame
	-- a rotation whose -Y is `dir` and whose X is `side` (made perpendicular)
	local y = -dir
	local x = side - y * side:Dot(y)
	if x.Magnitude < 1e-4 then
		x = V(1, 0, 0) - y * y.X
	end
	x = x.Unit
	local z = x:Cross(y)
	return CFrame.fromMatrix(Vector3.zero, x, y, z)
end

local function armOnce(S, E, W, s: Vector3, a: Vector3, b: Vector3, target: Vector3, hint: Vector3): (CFrame, CFrame)
	local L1, L2 = a.Magnitude, b.Magnitude
	local toT = target - s
	local d = math.clamp(toT.Magnitude, math.abs(L1 - L2) + 0.02, L1 + L2 - 0.005)
	local w = toT.Magnitude > 1e-4 and toT.Unit or V(0, -1, 0)
	-- the elbow: on the hint's side of the shoulder->wrist line
	local h = hint - w * hint:Dot(w)
	if h.Magnitude < 1e-3 then
		h = V(0, -1, 0) - w * w.Y
		if h.Magnitude < 1e-3 then
			h = V(0, 0, 1)
		end
	end
	h = h.Unit
	local ca = math.clamp((L1 * L1 + d * d - L2 * L2) / (2 * L1 * d), -1, 1)
	local sa = math.sqrt(1 - ca * ca)
	local u = w * ca + h * sa -- shoulder -> elbow
	local elbow = s + u * L1
	local v = (s + w * d - elbow).Unit -- elbow -> wrist
	-- the hinge: turning about it by a positive angle swings the forearm from straight (u) to v
	local f = v - u * v:Dot(u)
	if f.Magnitude < 1e-4 then
		f = h:Cross(u)
	end
	f = f.Unit
	local n = u:Cross(f)
	-- the upper arm's rest frame (its shoulder->elbow vector `a`, its hinge X) onto (u, n)
	local R1 = frame(u, n) * frame(a.Unit, V(1, 0, 0)):Inverse()
	local T1 = S.C0.Rotation:Inverse() * R1 * S.C1.Rotation
	-- the forearm's direction in the upper arm's own frame, as a bend about X
	local dl = (R1 * E.C0.Rotation):Inverse() * v
	local bl = b.Unit
	local theta = math.atan2(-dl.Z, -dl.Y) - math.atan2(-bl.Z, -bl.Y)
	local T2 = CFrame.Angles(theta, 0, 0)
	return T1, T2
end

local function arm(rig, side: string, target: Vector3, hint: Vector3): (CFrame?, CFrame?)
	local S = rig[side .. "S"]
	local E = rig[side .. "E"]
	local W = rig[side .. "W"]
	if not (S and E and W) then
		return nil, nil
	end
	local s = S.C0.Position
	local a = E.C0.Position - S.C1.Position -- shoulder joint -> elbow joint, in the upper arm
	local b = W.C0.Position - E.C1.Position -- elbow joint -> wrist joint, in the lower arm
	if a.Magnitude < 1e-3 or b.Magnitude < 1e-3 then
		return nil, nil
	end
	-- (an R15 shoulder joint sits at the arm's inner top edge, so `a` slants and the hinge isn't
	-- square to it: solve, see where the wrist really lands, aim off by the miss, twice more)
	local aim = target
	local T1, T2 = armOnce(S, E, W, s, a, b, aim, hint)
	for _ = 1, 3 do
		local upper = S.C0 * T1 * S.C1:Inverse()
		local wrist = (upper * E.C0 * T2 * E.C1:Inverse() * W.C0).Position
		local miss = target - wrist
		if miss.Magnitude < 0.01 then
			break
		end
		aim += miss
		T1, T2 = armOnce(S, E, W, s, a, b, aim, hint)
	end
	return T1, T2
end
ActPose._arm = arm

function ActPose.solve(rig, tg): { [string]: CFrame }
	local out = {}
	local sc = rig.Scale or 1
	if tg.Waist and rig.Waist then
		out.Waist = CFrame.Angles(tg.Waist, 0, 0)
	end
	if (tg.Neck or tg.NeckYaw) and rig.Neck then
		out.Neck = CFrame.Angles(0, tg.NeckYaw or 0, 0) * CFrame.Angles(tg.Neck or 0, 0, 0)
	end
	for _, side in { "R", "L" } do
		local tgt = tg[side]
		if tgt then
			local sign = side == "R" and 1 or -1
			local hint = tg.Elbow and V(tg.Elbow.X * sign, tg.Elbow.Y, tg.Elbow.Z) or V(sign, -1, 0.35)
			local T1, T2 = arm(rig, side, tgt * sc, hint)
			if T1 and T2 then
				out[side == "R" and "RightShoulder" or "LeftShoulder"] = T1
				out[side == "R" and "RightElbow" or "LeftElbow"] = T2
				local wr = tg[side .. "Wrist"]
				if wr then
					out[side == "R" and "RightWrist" or "LeftWrist"] = wr
				end
			end
		end
	end
	return out
end

-- a standard R15's joint offsets (tests and previews; the client reads the real ones)
ActPose.StandardRig = {
	Scale = 1,
	Waist = { C0 = CFrame.new(0, 0.2, 0), C1 = CFrame.new(0, -0.8, 0) },
	Neck = { C0 = CFrame.new(0, 0.8, 0), C1 = CFrame.new(0, -0.5, 0) },
	RS = { C0 = CFrame.new(1, 0.563, 0), C1 = CFrame.new(-0.5, 0.392, 0) },
	RE = { C0 = CFrame.new(0, -0.334, 0), C1 = CFrame.new(0, 0.26, 0) },
	RW = { C0 = CFrame.new(0, -0.501, 0), C1 = CFrame.new(0, 0.125, 0) },
	LS = { C0 = CFrame.new(-1, 0.563, 0), C1 = CFrame.new(0.5, 0.392, 0) },
	LE = { C0 = CFrame.new(0, -0.334, 0), C1 = CFrame.new(0, 0.26, 0) },
	LW = { C0 = CFrame.new(0, -0.501, 0), C1 = CFrame.new(0, 0.125, 0) },
}

-- where a joint's child part ends up (UpperTorso space) for a set of transforms: FK, for tests
function ActPose.wristOf(rig, side: string, tr): Vector3
	local S, E, W = rig[side .. "S"], rig[side .. "E"], rig[side .. "W"]
	local sh = (side == "R") and "RightShoulder" or "LeftShoulder"
	local el = (side == "R") and "RightElbow" or "LeftElbow"
	local upper = S.C0 * (tr[sh] or CFrame.identity) * S.C1:Inverse()
	local lower = upper * E.C0 * (tr[el] or CFrame.identity) * E.C1:Inverse()
	return (lower * W.C0).Position
end

return ActPose
