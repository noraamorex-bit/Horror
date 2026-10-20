--[[
	Dread — what the dark house sounds like (v104; a player: '"horror game" but almost no audio
	for it'). Not music (the owner: no chase or tension music): the house itself.

	• Once the power's gone, an eerie room tone under everything indoors (DarkBed), a little louder
	  while he's hunting.
	• Him getting close: a low rumble swelling under it (Presence), with your heartbeat (Effects
	  reads Dread.proximity()). Through a floor it's half as strong; you feel him before you see him.
	• While he hunts, now and then, a noise off somewhere in the house: a creak, a thud upstairs, wood
	  splintering, his joints, a whisper, and rarely a shriek far away. Never right on top of you
	  (that's what the scares are for) and never while he's chasing you.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Dread = {}
local ctx
local player = Players.LocalPlayer

-- his states while the hunt is on (workspace IntruderState)
local HUNTING = {
	Prowl = true, Chase = true, Search = true, CheckSpot = true, Withdraw = true, Ambush = true, Patrol = true,
	Investigate = true, Charge = true, Inspect = true, Retreat = true, Stunned = true,
}
local NEAR = 55 -- (studs: the rumble starts here)

-- noises off: name, how loud (library volume x), how often (weight)
local OFF = {
	{ "HouseCreak1", 1, 4 },
	{ "HouseCreak2", 1, 3 },
	{ "Floorboard", 1, 3 },
	{ "StairCreak", 1, 2 },
	{ "CeilingThud", 0.45, 1.5 },
	{ "WoodSplinter", 1, 1.5 },
	{ "BoneCrack2", 1, 1 },
	{ "DoorRattle", 0.8, 1 },
	{ "CreatureWhisper", 0.8, 0.8 },
	{ "DistantShriek", 0.7, 0.35 },
}

local prox = 0
local bed: Sound?
local presence: Sound?
local nextOff = 0

function Dread.hunting(): boolean
	return HUNTING[workspace:GetAttribute("IntruderState") or ""] == true
end

-- 0 (he's nowhere near) .. 1 (right beside you)
function Dread.proximity(): number
	return prox
end

-- pick a noise off by weight (r: 0..1)
function Dread.pick(r: number): (string, number)
	local total = 0
	for _, o in OFF do
		total += o[3]
	end
	local x = r * total
	for _, o in OFF do
		x -= o[3]
		if x <= 0 then
			return o[1], o[2]
		end
	end
	return OFF[#OFF][1], OFF[#OFF][2]
end

-- where a noise off goes: 18-34 studs from you, maybe a floor up or down
function Dread.spot(from: Vector3, r1: number, r2: number, r3: number): Vector3
	local a = r1 * math.pi * 2
	local d = 18 + r2 * 16
	local dy = r3 < 0.3 and 12 or (r3 > 0.85 and -10 or 0)
	return from + Vector3.new(math.cos(a) * d, dy, math.sin(a) * d)
end

local function curtisRoot(): BasePart?
	local m = workspace:FindFirstChild("Curtis", true)
	return m and m:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function Dread.init(c)
	ctx = c
	ctx.Dread = Dread
end

function Dread.start()
	bed = ctx.Effects.localSound("DarkBed")
	presence = ctx.Effects.localSound("Presence")
	for _, s in { bed, presence } do
		if s then
			s.Looped = true
			s.Volume = 0
			s:Play()
		end
	end
	nextOff = os.clock() + 25
	local bedVol, presVol = 0, 0
	local findClock, root = 0, nil :: BasePart?
	RunService.Heartbeat:Connect(function(dt)
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local ear = cam.CFrame.Position
		local inGame = player:GetAttribute("InGame") == true and not player:GetAttribute("Escaped")
			and not workspace:GetAttribute("EndingActive")
		local inside = inGame and ctx.Rooms.isInside(ear)
		local dark = workspace:GetAttribute("Power") == false
		local hunting = Dread.hunting()

		-- how close he is (he's only "there" while hunting and in the house)
		findClock -= dt
		if (not root or not root.Parent) and findClock <= 0 then
			findClock = 1
			root = curtisRoot()
		end
		local want = 0
		if inGame and hunting and root and root.Parent then
			local d = (root.Position - ear).Magnitude
			want = math.clamp(1 - d / NEAR, 0, 1) ^ 1.4
			if math.abs(root.Position.Y - ear.Y) > 9 then
				want *= 0.5
			end
		end
		prox += (want - prox) * math.min(1, dt * 2.5)

		-- the bed: the dark house, indoors
		local bedWant = (inside and dark) and (hunting and 0.55 or 0.4) or 0
		bedVol += math.clamp(bedWant - bedVol, -dt * 0.25, dt * 0.15)
		if bed then
			bed.Volume = ctx.Sounds.volume("DarkBed", bedVol)
		end
		-- the rumble: him, close
		presVol += (prox - presVol) * math.min(1, dt * 3)
		if presence then
			presence.Volume = ctx.Sounds.volume("Presence", presVol)
		end

		-- noises off, while he hunts and isn't on you
		local st = workspace:GetAttribute("IntruderState")
		if inside and hunting and st ~= "Chase" and st ~= "Charge" and prox < 0.35 and not player:GetAttribute("Captured") then
			if os.clock() >= nextOff then
				nextOff = os.clock() + 14 + math.random() * 16
				local name, k = Dread.pick(math.random())
				ctx.Effects.playSound(name, Dread.spot(ear, math.random(), math.random(), math.random()), {
					Caption = name == "DistantShriek" or name == "WoodSplinter",
					Volume = (ctx.Sounds.get(name).Volume or 0.6) * k,
				})
			end
		else
			nextOff = math.max(nextOff, os.clock() + 8)
		end
	end)
end

return Dread
