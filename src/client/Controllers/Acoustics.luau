--[[
	Acoustics — how the house sounds around you (the way DOORS sounds: you can tell where a noise
	is, and whether there's a wall between you and it).

	• Room reverb: SoundService.AmbientReverb follows the room you're in (tiled bathrooms ring,
	  the basement and garage are stone, the bedrooms and living room are soft).
	• Through walls: a sound in the world with something solid between you and it (a wall, a
	  floor, a closed door) loses its highs and some of its body, so his footsteps behind a wall
	  sound behind a wall, and the moment he steps into view they're suddenly clear.
	• Hiding: shut in a closet or behind a curtain, everything outside is muffled the same way.

	Only sounds placed in the world (on a part or an attachment) are touched; your own footsteps,
	the UI, the heartbeat and the music are not. Values ease in and out so nothing jumps.
]]

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Acoustics = {}
local ctx
local player = Players.LocalPlayer

local RANGE = 140 -- (farther than this a sound is too quiet to matter)
local TICK = 0.2
-- what the wall takes away (dB)
local WALL = { High = -16, Mid = -6, Low = 0 }
local HIDDEN = { High = -11, Mid = -4, Low = 0 }

-- room -> reverb
local REVERB: { [string]: Enum.ReverbType } = {
	Boiler = Enum.ReverbType.StoneRoom,
	Basement = Enum.ReverbType.StoneRoom,
	Garage = Enum.ReverbType.StoneRoom,
	Bathroom = Enum.ReverbType.Bathroom,
	MasterBath = Enum.ReverbType.Bathroom,
	HallBath = Enum.ReverbType.Bathroom,
	Hallway = Enum.ReverbType.Hallway,
	MudHall = Enum.ReverbType.Hallway,
	UpperHall = Enum.ReverbType.CarpettedHallway,
	Living = Enum.ReverbType.LivingRoom,
	Den = Enum.ReverbType.LivingRoom,
	Attic = Enum.ReverbType.Room,
}

function Acoustics.reverbFor(roomName: string?, pos: Vector3): Enum.ReverbType
	if roomName then
		return REVERB[roomName] or Enum.ReverbType.Room
	end
	-- under the house (the secret ending's tunnels) or out in the rain
	if pos.Y < -4 then
		return Enum.ReverbType.StoneCorridor
	end
	return Enum.ReverbType.NoReverb
end

local sounds: { [Sound]: boolean } = {}

local function worldPosition(s: Sound): Vector3?
	local p = s.Parent
	if p and p:IsA("BasePart") then
		return p.Position
	elseif p and p:IsA("Attachment") then
		return p.WorldPosition
	end
	return nil
end

-- what a sound belongs to, so its own body never blocks it: the nearest model around it (him, a
-- TV, a friend's character), else just its part. (Never a folder: the whole house is in folders.)
local function ownerOf(s: Sound): Instance?
	local node: Instance? = s.Parent
	while node and node ~= workspace do
		if node:IsA("Model") then
			return node
		end
		node = node.Parent
	end
	local p = s.Parent
	return if p and p:IsA("Attachment") then p.Parent else p
end

local function eqOf(s: Sound): EqualizerSoundEffect
	local eq = s:FindFirstChild("Occlusion")
	if not eq then
		local e = Instance.new("EqualizerSoundEffect")
		e.Name = "Occlusion"
		e.HighGain, e.MidGain, e.LowGain = 0, 0, 0
		e.Priority = 1
		e.Parent = s
		eq = e
	end
	return eq :: EqualizerSoundEffect
end

local function ease(eq: EqualizerSoundEffect, target)
	local k = 0.45
	eq.HighGain += (target.High - eq.HighGain) * k
	eq.MidGain += (target.Mid - eq.MidGain) * k
	eq.LowGain += (target.Low - eq.LowGain) * k
	if math.abs(eq.HighGain) < 0.3 and math.abs(eq.MidGain) < 0.3 and target.High == 0 then
		eq.HighGain, eq.MidGain, eq.LowGain = 0, 0, 0
	end
end

local OPEN = { High = 0, Mid = 0, Low = 0 }

-- is there something solid between the listener and the sound?
function Acoustics.blocked(from: Vector3, to: Vector3, ignore: { Instance }): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true
	local dir = to - from
	local hit = workspace:Raycast(from, dir, params)
	-- (glass and see-through bits don't stop sound much; a hit right at the sound is the sound's own spot)
	return hit ~= nil and hit.Instance.Transparency < 0.6 and (hit.Position - to).Magnitude > 1.5
end

local function update()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local ear = cam.CFrame.Position
	local char = player.Character
	-- the room you're in
	local here = char and char:FindFirstChild("HumanoidRootPart")
	local at = here and (here :: BasePart).Position or ear
	local room = ctx.Rooms.find(at)
	local reverb = Acoustics.reverbFor(room and room.Name or nil, at)
	if SoundService.AmbientReverb ~= reverb then
		SoundService.AmbientReverb = reverb
	end
	local hiding = player:GetAttribute("Hiding") ~= nil
	for s in sounds do
		if not s.Parent then
			sounds[s] = nil
			continue
		end
		local eq = s:FindFirstChild("Occlusion") :: EqualizerSoundEffect?
		if not s.IsPlaying then
			if eq then
				eq.HighGain, eq.MidGain, eq.LowGain = 0, 0, 0
			end
			continue
		end
		local pos = worldPosition(s)
		if not pos or (char and s:IsDescendantOf(char)) then
			continue
		end
		local d = (pos - ear).Magnitude
		if d > RANGE then
			continue
		end
		local target = OPEN
		if hiding and d > 4 then
			target = HIDDEN
		end
		local ignore: { Instance } = { cam }
		if char then
			table.insert(ignore, char)
		end
		local owner = ownerOf(s)
		if owner then
			table.insert(ignore, owner)
		end
		if d > 3 and Acoustics.blocked(ear, pos, ignore) then
			target = WALL
		end
		if target ~= OPEN or eq then
			ease(eqOf(s), target)
		end
	end
end

local function track(d: Instance)
	if d:IsA("Sound") then
		local p = d.Parent
		if p and (p:IsA("BasePart") or p:IsA("Attachment")) then
			sounds[d] = true
		end
	end
end

function Acoustics.init(c)
	ctx = c
	ctx.Acoustics = Acoustics
end

function Acoustics.start()
	for _, d in workspace:GetDescendants() do
		track(d)
	end
	workspace.DescendantAdded:Connect(track)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < TICK then
			return
		end
		acc = 0
		update()
	end)
end

Acoustics._update = update -- (tests)
Acoustics._track = track
Acoustics._sounds = function()
	return sounds
end

return Acoustics
