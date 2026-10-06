--[[
	CutsceneService — short cinematic moments in the middle of the night (like the endings'):
	letterbox bars, slow camera moves, a line of subtitle. The client (Cutscene) flies the camera.

	Cutscene.play({
		Name = "LightsOut",
		Shots = { { From = CFrame, To = CFrame, Time = 3, Track = "Intruder"? }, ... },
		Subtitle = "..."?,
		Players = { Player }?,  -- default: everyone in the night who isn't out of it
		Freeze = true?,         -- hold the players still while it plays (default true)
		HoldIntruder = true?,   -- and him (default true)
	})

	While a shared cutscene plays nobody can be caught: he's held where he stands.
]]

local Cutscene = {}
local ctx
local busyUntil = 0

function Cutscene.init(c)
	ctx = c
	ctx.Cutscene = Cutscene
end

function Cutscene.reset()
	busyUntil = 0
end

function Cutscene.isPlaying(): boolean
	return os.clock() < busyUntil
end

local function duration(shots): number
	local d = 0
	for _, s in shots do
		d += s.Time or 3
	end
	return d
end

function Cutscene.play(spec): number
	if ctx.Ending.isOver() then
		return 0
	end
	local shots = spec.Shots or {}
	if #shots == 0 then
		return 0
	end
	-- the client fades in (0.7) and the bars close (0.6) around the shots
	local total = duration(shots) + 1.5
	local players = spec.Players
	if not players then
		players = {}
		for _, p in ctx.Util.sessionPlayers() do
			if not p:GetAttribute("Escaped") and not p:GetAttribute("Dead") then
				table.insert(players, p)
			end
		end
	end
	if #players == 0 then
		return 0
	end
	local shared = spec.Players == nil
	if shared then
		busyUntil = math.max(busyUntil, os.clock() + total)
	end
	if spec.HoldIntruder ~= false and shared and ctx.Intruder and ctx.Intruder.hold then
		ctx.Intruder.hold(total)
	end
	local frozen = {}
	if spec.Freeze ~= false then
		for _, p in players do
			-- (tied up or hiding: they're held already)
			if not p:GetAttribute("Captured") and not p:GetAttribute("Hiding") then
				ctx.PlayerState.setFrozen(p, true)
				table.insert(frozen, p)
			end
		end
	end
	for _, p in players do
		ctx.Remotes.Cutscene:FireClient(p, { Name = spec.Name, Shots = shots, Subtitle = spec.Subtitle })
	end
	task.delay(total, function()
		for _, p in frozen do
			if p.Parent and not p:GetAttribute("Captured") and not p:GetAttribute("Hiding") and not p:GetAttribute("Escaped") then
				ctx.PlayerState.setFrozen(p, false)
			end
		end
	end)
	return total
end

---------------------------------------------------------------------------
-- The night's cutscenes (camera moves built from the map)
---------------------------------------------------------------------------
local V = Vector3.new
local function look(from: Vector3, at: Vector3): CFrame
	return CFrame.lookAt(from, at)
end

-- Act III: the lights go out. From across the street, the whole house goes dark at once.
-- `cut` is called at the moment the power should die (Director does the actual work).
function Cutscene.lightsOut(cut: () -> ())
	local house = V(2, 14, -30)
	local t = Cutscene.play({
		Name = "LightsOut",
		Shots = {
			{ From = look(V(-34, 8, -96), house), To = look(V(-24, 8.5, -88), house), Time = 4.2 },
		},
	})
	-- (fade in 0.7 s, then ~1.6 s on the lit house before it goes)
	task.delay(t > 0 and 2.3 or 0, cut)
end

-- The first hunt: in the garage, under the hatch, he's standing there.
function Cutscene.heComesDown(at: Vector3)
	local face = at + V(0, 5.2, 0)
	Cutscene.play({
		Name = "HeComesDown",
		Shots = {
			{ From = look(at + V(-6, 3, -17), face), To = look(at + V(-4.5, 2.6, -13), face), Time = 2.6 },
			{ From = look(at + V(3, 3.4, -7), face), To = look(at + V(1.4, 3.2, -4.2), face), Time = 2.2 },
		},
		Subtitle = "",
	})
end

-- Tied up for the first time: you, zip-tied to the pipes in the boiler room. Just for you.
function Cutscene.tiedUp(player: Player, slot, line: string?)
	if not slot then
		return
	end
	local pos, faceTo = slot.Pos, slot.Face
	local out = (faceTo - pos)
	out = V(out.X, 0, out.Z).Unit
	local head = pos + V(0, 1.2, 0)
	Cutscene.play({
		Name = "TiedUp",
		Players = { player },
		Freeze = false,
		HoldIntruder = false,
		Shots = {
			{ From = look(head + out * 9 + V(2.5, 3.5, 0), head), To = look(head + out * 6.5 + V(1.5, 2.2, 0), head), Time = 3.4 },
		},
		Subtitle = line or "Zip-tied to the pipes. Struggle free, or wait for your friends.",
	})
end

return Cutscene
