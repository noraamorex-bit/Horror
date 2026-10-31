--[[
	Events — the Director's library of "small things". Every one has a real cause,
	logged to the truth timeline when it fires.

	Event fields:
		Id, Acts = { [act] = true }, Weight, Tension, Once, Cooldown (s)
		Where(ctx, data) -> Vector3    for things Curtis does in person: once he's really in the
		                               house the event only happens right where he is, unseen
		Cond(ctx, D) -> data | nil     only fires when this returns something
		Run(ctx, D, data)              may yield
		Force(ctx, D) -> data | nil    relaxed condition for guaranteed beats past their deadline
]]

local Haunt = require(script.Parent.Parent.World.Haunt)

local Events = {}

local V = Vector3.new

local function anyone(ctx, fn): boolean
	for _, p in ctx.Util.activePlayers() do
		local root = ctx.Util.getRoot(p)
		if root and fn(p, root) then
			return true
		end
	end
	return false
end

local function everyone(ctx, fn): boolean
	return not anyone(ctx, function(p, root)
		return not fn(p, root)
	end)
end

local function floorOf(ctx, root: BasePart): string
	return ctx.Rooms.floorOf(root.Position)
end


-- the loud musical sting that lands with a scare: rare, so it never stops being sudden
local nextSting = 0
local function sting(ctx, players: { Player })
	if os.clock() < nextSting or #players == 0 then
		return
	end
	nextSting = os.clock() + 150
	for _, p in players do
		ctx.Remotes.PlaySound:FireClient(p, "Stinger", nil, { Volume = 0.9 })
	end
end
Events.sting = sting

-- a loud sudden noise: shake and rattle everyone close enough to hear it clearly
local function jolt(ctx, pos: Vector3, radius: number, nerve: number, shake: number)
	local hit = {}
	for _, p in ctx.Util.activePlayers() do
		local root = ctx.Util.getRoot(p)
		if root then
			local d = (root.Position - pos).Magnitude
			if d <= radius then
				local k = 1 - d / radius * 0.6
				ctx.PlayerState.addNerve(p, -nerve * k)
				ctx.Remotes.Shake:FireClient(p, shake * k, 0.55)
				table.insert(hit, p)
			end
		end
	end
	sting(ctx, hit)
	return hit
end

local function roomOf(ctx, p: Player)
	local root = ctx.Util.getRoot(p)
	return root and ctx.Rooms.find(root.Position), root
end

-- (v131) someone on their own: nobody else within `r` studs, not hiding
local function alone(ctx, p: Player, root: BasePart, r: number): boolean
	if p:GetAttribute("Hiding") then
		return false
	end
	for _, o in ctx.Util.activePlayers() do
		local q = ctx.Util.getRoot(o)
		if o ~= p and q and (q.Position - root.Position).Magnitude < r then
			return false
		end
	end
	return true
end

-- (v131) is p looking at pos (within the cone cos >= dot), with nothing in between?
local function looksAt(ctx, D, p: Player, pos: Vector3, dot: number): boolean
	local root = ctx.Util.getRoot(p)
	if not root then
		return false
	end
	local to = pos - root.Position
	local flat = V(to.X, 0, to.Z)
	if flat.Magnitude < 0.5 then
		return true
	end
	local look = root.CFrame.LookVector
	if V(look.X, 0, look.Z).Unit:Dot(flat.Unit) < dot then
		return false
	end
	return D.Perception == nil or D.Perception.playerSees(p, pos)
end

-- (v131) can anyone see this point right now?
local function D_sees(ctx, pos: Vector3): boolean
	local P = ctx.Director and ctx.Director.Perception
	return P ~= nil and P.anyoneSees(pos)
end

-- (v131) a CFrame at pos facing a horizontal direction (a yaw: lune's lookAt mishandles +Z, and these
-- are all level)
local function facing(pos: Vector3, dir: Vector3): CFrame
	return CFrame.new(pos) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), 0)
end

-- (v131) models in a room folder by PropKey (or name)
local function modelsIn(ctx, roomName: string, match: (Model) -> boolean): { Model }
	local out = {}
	local folder = ctx.World.folder() and ctx.World.folder():FindFirstChild(roomName)
	if not folder then
		return out
	end
	for _, d in folder:GetDescendants() do
		if d:IsA("Model") and match(d) and not d:FindFirstAncestor("Prop") then
			table.insert(out, d)
		end
	end
	return out
end

-- (v131) turn a model in place round its middle by `rot`
local function turnInPlace(m: Model, target: CFrame)
	local cf = m:GetBoundingBox()
	local now = m:GetPivot()
	m:PivotTo(target * cf:ToObjectSpace(now))
end

-- (v131) red writing on the walls: where it can go (on the face of a wall, -Z into the room), and what it
-- says ({NAME}: one of you). Placed where nobody is and nobody can see; found later.
local SCRAWLS = {
	{ Room = "UpperHall", At = V(-7.66, 21.5, 5), Into = V(1, 0, 0), W = 8, H = 2.6 }, -- over the stairwell
	{ Room = "Jamie", At = V(-35, 23.2, 12.34), Into = V(0, 0, 1), W = 6, H = 2 }, -- over Jamie's bed
	{ Room = "Master", At = V(-12.5, 22, -0.34), Into = V(0, 0, -1), W = 6, H = 2.2 },
	{ Room = "Basement", At = V(-6, -7, 29.46), Into = V(0, 0, -1), W = 8, H = 2.4 },
	{ Room = "Den", At = V(20, 11.6, 4.34), Into = V(0, 0, 1), W = 6, H = 1.8 }, -- over the TV
	{ Room = "Garage", At = V(40.54, 10, -26), Into = V(1, 0, 0), W = 6, H = 2 },
}
Events.Scrawls = SCRAWLS
local SCRAWL_TEXT = { "I'M IN THE WALLS", "WE'RE A FAMILY NOW", "{NAME} IS MINE", "DON'T LOOK UP", "NOBODY LEAVES", "I LIKE IT WHEN YOU SLEEP", "{NAME}, COME UPSTAIRS" }
local scrawled: { [any]: { [number]: boolean } } = {}
local scrawlLines: { [any]: { [string]: boolean } } = {}

Events.List = {
	---------------------------------------------------------------------------
	{
		Id = "FootstepsUpstairs",
		Acts = { SmallThings = true },
		Weight = 3,
		Tension = 14,
		Once = true,
		Cond = function(ctx)
			local someone = #ctx.Util.activePlayers() > 0
			local nobodyUp = everyone(ctx, function(_, root)
				local f = floorOf(ctx, root)
				return f == "Ground" or f == "Basement"
			end)
			return (someone and nobodyUp) and true or nil
		end,
		Force = function()
			return true
		end,
		Run = function(ctx, D)
			local path = ctx.Layout.FootstepPath
			for i, pos in path do
				ctx.Audio.playAt(i == 1 and "FootstepsAbove" or "Footstep", pos, { Caption = i == 1, Pitch = 0.85, Range = 90 })
				task.wait(0.62)
			end
			local hatch = ctx.World.refs().AtticHatch
			if hatch then
				hatch.swing(6)
			end
			ctx.Audio.playAt("HatchCreak", path[#path] + V(0, 12, 0))
			D.logTruth("FootstepsUpstairs")
			D.think(nil, ctx.Story.Thoughts.Events.FootstepsUpstairs)
			if ctx.Director.getAct() == "SmallThings" then
				ctx.Objectives.add("Investigate")
			end
		end,
	},
	---------------------------------------------------------------------------
	{
		Id = "DoorAjar",
		Where = function(_, door)
			return door.Position
		end,
		Acts = { SmallThings = true, SomeoneElse = true },
		Weight = 3,
		Tension = 8,
		Cooldown = 90,
		Cond = function(ctx, D)
			local candidates = {}
			for _, door in ctx.Doors.all() do
				if door.IsOpen or door.Locked or door.Exterior or door.Id == "Office" or door.Id == "Basement" then
					continue
				end
				local near, far = false, false
				for _, p in ctx.Util.activePlayers() do
					local root = ctx.Util.getRoot(p)
					if root then
						local d = (root.Position - door.Position).Magnitude
						if d < 14 then
							near = true
						elseif d < 50 then
							far = true
						end
					end
				end
				if far and not near and not D.Perception.anyoneSees(door.Position) then
					table.insert(candidates, door)
				end
			end
			return ctx.Util.choice(candidates)
		end,
		Run = function(ctx, D, door)
			ctx.Doors.setAjar(door, 35)
			D.thinkNear(door.Position, 50, ctx.Story.Thoughts.Events.DoorAjar)
			ctx.Audio.playAt("DoorOpen", door.Position, { Volume = 0.35, CaptionText = "[A door creaks open, somewhere close]", CaptionRange = 45 })
			D.logTruth("DoorAjar")
		end,
	},
	---------------------------------------------------------------------------
	{
		Id = "CordSwing",
		Acts = { SmallThings = true },
		Weight = 2,
		Tension = 10,
		Once = true,
		Cond = function(ctx)
			local h = ctx.Layout.AtticHatch
			local c = V((h.x0 + h.x1) / 2, 18, (h.z0 + h.z1) / 2)
			local found = anyone(ctx, function(_, root)
				local d = (root.Position - c).Magnitude
				return floorOf(ctx, root) == "Upstairs" and d > 10 and d < 38
			end)
			return found and true or nil
		end,
		Run = function(ctx, D)
			local hatch = ctx.World.refs().AtticHatch
			if hatch and not hatch.Open then
				hatch.swing(9)
				D.thinkNear(hatch.Handle.Position, 40, ctx.Story.Thoughts.Events.CordSwing)
				ctx.Audio.playAt("HatchCreak", hatch.Handle.Position + V(0, 3, 0))
				D.logTruth("CordSwing")
			end
		end,
	},
	---------------------------------------------------------------------------
	{
		Id = "FoodMissing",
		Where = function(_, k)
			return k.FridgePos
		end,
		Acts = { SmallThings = true },
		Weight = 2,
		Tension = 4,
		Once = true,
		Cond = function(ctx, D)
			local k = ctx.World.refs().Kitchen
			if not k or k.LasagnaGone then
				return nil
			end
			local inKitchen = anyone(ctx, function(_, root)
				local r = ctx.Rooms.find(root.Position)
				return r ~= nil and r.Name == "Kitchen"
			end)
			if inKitchen or D.Perception.anyoneSees(k.FridgePos) then
				return nil
			end
			return k
		end,
		Run = function(ctx, D, k)
			k.takeLasagna()
			D.logTruth("FoodMissing")
		end,
	},
	---------------------------------------------------------------------------
	{
		Id = "SilentCall",
		Acts = { SmallThings = true },
		Weight = 2,
		Tension = 10,
		Once = true,
		Cond = function(ctx)
			if not ctx.Escape.isLineWorking() then
				return nil
			end
			local phone = V(-9, 5, 6)
			local near = anyone(ctx, function(_, root)
				return (root.Position - phone).Magnitude < 45
			end)
			return near and true or nil
		end,
		Run = function(ctx, D)
			ctx.Escape.ringLandline("Silent", function()
				ctx.PlayerState.scareNear(V(-9, 5, 6), 20, ctx.Config.Nerve.ScareEvent)
				task.delay(8, function()
					D.thinkNear(V(-9, 5, 6), 30, ctx.Story.Thoughts.Events.SilentCall)
				end)
			end)
			D.logTruth("SilentCall")
		end,
	},
	---------------------------------------------------------------------------
	{
		Id = "DogBark",
		DuringHunt = true, -- ambience, not him
		Acts = { Evening = true, SmallThings = true, SomeoneElse = true, Guest = true },
		Weight = 2,
		Tension = 4,
		Cooldown = 150,
		Cond = function()
			return true
		end,
		Run = function(ctx, D)
			ctx.Audio.playAt("DogBark", V(100, 3, -10), { Range = 220, CaptionRange = 200 })
			D.logTruth("DogBark")
		end,
	},
	---------------------------------------------------------------------------
	{
		Id = "TVAlert",
		Acts = { SmallThings = true },
		Weight = 2,
		Tension = 8,
		Once = true,
		Cond = function(ctx)
			if not ctx.Power.isOn() then
				return nil
			end
			local inLiving = anyone(ctx, function(_, root)
				local r = ctx.Rooms.find(root.Position)
				return r ~= nil and (r.Name == "Living" or r.Name == "Kitchen")
			end)
			return inLiving and true or nil
		end,
		Run = function(ctx, D)
			local tv = ctx.World.refs().TV
			if tv and tv.emergencyAlert(18) then
				D.logTruth("TVAlert")
				D.thinkNear(V(-24, 4, -24), 60, ctx.Story.Thoughts.Events.TVAlert)
			end
		end,
	},
	---------------------------------------------------------------------------
	{
		Id = "Flicker",
		Acts = { Evening = true, SmallThings = true },
		Weight = 2,
		Tension = 6,
		Cooldown = 110,
		Cond = function(ctx)
			return ctx.Power.isOn() and true or nil
		end,
		Run = function(ctx, D)
			D.lightning(1)
			ctx.Power.flicker(2.4)
			D.logTruth("Flicker")
		end,
	},
	---------------------------------------------------------------------------
	{
		Id = "FigureWindow",
		Acts = { SmallThings = true },
		Weight = 3,
		Tension = 20,
		Once = true,
		Cond = function(ctx)
			for _, p in ctx.Util.activePlayers() do
				local root = ctx.Util.getRoot(p)
				if not root or ctx.PlayerState.friendsNear(p) > 0 then
					continue
				end
				local room = ctx.Rooms.find(root.Position)
				if not room or room.Floor ~= "Ground" then
					continue
				end
				for _, w in ctx.Layout.WindowWatch do
					if w.Room == room.Name then
						local toWin = w.Face - root.Position
						local flat = V(toWin.X, 0, toWin.Z)
						if flat.Magnitude < 26 and root.CFrame.LookVector:Dot(flat.Unit) > 0.45 then
							return { Player = p, Watch = w }
						end
					end
				end
			end
			return nil
		end,
		Force = function(ctx)
			-- any lone player on the ground floor: use the window nearest to them in their room
			for _, p in ctx.Util.activePlayers() do
				local root = ctx.Util.getRoot(p)
				local room = root and ctx.Rooms.find(root.Position)
				if room and room.Floor == "Ground" then
					for _, w in ctx.Layout.WindowWatch do
						if w.Room == room.Name then
							return { Player = p, Watch = w }
						end
					end
				end
			end
			return nil
		end,
		Run = function(ctx, D, data)
			local w = data.Watch
			-- (v99) a tap, tap on the glass first, so you're looking right at it when the lightning comes
			ctx.Remotes.PlaySound:FireClient(data.Player, "GlassTap", w.Face, { Volume = 0.9 })
			task.wait(0.9)
			D.lightning(1.2)
			ctx.Remotes.Figure:FireClient(data.Player, CFrame.lookAt(w.Stand, w.Face), 1.4, "Stare")
			task.delay(0.3, function()
				ctx.PlayerState.addNerve(data.Player, -12)
				ctx.Remotes.Shake:FireClient(data.Player, 0.35, 0.8)
				D.think(data.Player, ctx.Story.Thoughts.Events.FigureWindow)
			end)
			D.logTruth("FigureWindow")
		end,
	},
	---------------------------------------------------------------------------
	-- v99: in the first act, looking out of a ground-floor window: lightning, and for a second
	-- something impossibly tall is standing out in the yard, its head on one side, watching
	-- the house. Then it's dark again.
	{
		Id = "YardFigure",
		Acts = { Evening = true },
		Weight = 4,
		Tension = 14,
		Once = true,
		Cond = function(ctx)
			for _, p in ctx.Util.activePlayers() do
				local room, root = roomOf(ctx, p)
				if not room or room.Floor ~= "Ground" or p:GetAttribute("Hiding") then
					continue
				end
				for _, w in ctx.Layout.WindowWatch do
					if w.Room == room.Name then
						local toWin = w.Face - root.Position
						local flat = V(toWin.X, 0, toWin.Z)
						if flat.Magnitude < 24 and flat.Magnitude > 2 and root.CFrame.LookVector:Dot(flat.Unit) > 0.7 then
							return { Player = p, Watch = w }
						end
					end
				end
			end
			return nil
		end,
		Run = function(ctx, D, data)
			local w = data.Watch
			local out = w.Stand - w.Face
			out = V(out.X, 0, out.Z).Unit
			local at = w.Stand + out * 14
			D.lightning(0.8)
			ctx.Remotes.Figure:FireClient(data.Player, CFrame.lookAt(at, V(w.Face.X, at.Y, w.Face.Z)), 0.9, "Stare")
			task.delay(0.35, function()
				ctx.PlayerState.addNerve(data.Player, -8)
				D.think(data.Player, ctx.Story.Thoughts.Events.YardFigure)
			end)
			D.logTruth("YardFigure")
		end,
	},
	---------------------------------------------------------------------------
	-- v99: before he's in for good: at the far end of the hall you're looking down, in the dark,
	-- something standing dead still with its head laid over on one side. A whisper. Then the
	-- lights stutter and it's gone, and something in the dark cracks like a knuckle.
	{
		Id = "HallStare",
		Acts = { SmallThings = true, SomeoneElse = true },
		Weight = 3,
		Tension = 22,
		Once = true,
		Cond = function(ctx)
			if ctx.Intruder.isInHouse() then
				return nil
			end
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			local chars = {}
			for _, p in ctx.Util.activePlayers() do
				if p.Character then
					table.insert(chars, p.Character)
				end
			end
			params.FilterDescendantsInstances = chars
			for _, p in ctx.Util.activePlayers() do
				local head = p.Character and p.Character:FindFirstChild("Head") :: BasePart?
				local root = ctx.Util.getRoot(p)
				if not head or not root or p:GetAttribute("Hiding") then
					continue
				end
				local look = root.CFrame.LookVector
				for _, n in ctx.Layout.Nodes do
					local to = n.Pos - root.Position
					local flat = V(to.X, 0, to.Z)
					if math.abs(to.Y) < 4 and flat.Magnitude > 16 and flat.Magnitude < 40 and look:Dot(flat.Unit) > 0.93 then
						-- nobody else near it, and a clear view of his whole height from where you stand
						local alone = true
						for _, o in ctx.Util.activePlayers() do
							local r = ctx.Util.getRoot(o)
							if r and (r.Position - n.Pos).Magnitude < 14 then
								alone = false
							end
						end
						local feet = n.Pos - V(0, 3, 0)
						local clear = alone
							and workspace:Raycast(head.Position, feet + V(0, 8.5, 0) - head.Position, params) == nil
							and workspace:Raycast(head.Position, feet + V(0, 4, 0) - head.Position, params) == nil
						if clear then
							return { Player = p, Feet = feet, From = root.Position }
						end
					end
				end
			end
			return nil
		end,
		Run = function(ctx, D, data)
			local feet = data.Feet
			ctx.Remotes.Figure:FireClient(data.Player, CFrame.lookAt(feet + V(0, 2.6, 0), V(data.From.X, feet.Y + 2.6, data.From.Z)), 1.7, "Stare")
			ctx.Remotes.PlaySound:FireClient(data.Player, "CreatureWhisper", feet + V(0, 8, 0), { Volume = 0.8 })
			task.delay(0.5, function()
				ctx.PlayerState.addNerve(data.Player, -12)
				ctx.Remotes.Shake:FireClient(data.Player, 0.25, 0.6)
				D.think(data.Player, ctx.Story.Thoughts.Events.HallStare)
			end)
			task.delay(1.75, function()
				ctx.Remotes.PlaySound:FireClient(data.Player, "BoneCrack1", feet + V(0, 6, 0), { Volume = 0.9 })
			end)
			D.logTruth("HallStare")
		end,
	},
	---------------------------------------------------------------------------
	-- v106 (the owner: "make it scarier, like actually creepy"): the mimic. From upstairs (or the
	-- basement), in the voice of the friend standing right next to you, someone calls you by name
	-- to come up. Alone, it's Mom's voice, and Mom is two states away. (Client Voices plays it
	-- from that spot, with a far-off echo; Story.Mimic.)
	{
		Id = "Mimic",
		Acts = { SmallThings = true, SomeoneElse = true },
		Weight = 3,
		Tension = 18,
		Once = true,
		Cond = function(ctx)
			if ctx.Intruder.isInHouse() then
				return nil
			end
			local players = ctx.Util.activePlayers()
			for _, p in players do
				local root = ctx.Util.getRoot(p)
				if not root or p:GetAttribute("Hiding") then
					continue
				end
				local floor = floorOf(ctx, root)
				local want = floor == "Upstairs" and "Ground" or "Upstairs"
				-- a spot on the other floor, not too far, with nobody there
				local best, bestD = nil, math.huge
				for _, n in ctx.Layout.Nodes do
					if ctx.Rooms.floorOf(n.Pos) == want then
						local d = (n.Pos - root.Position).Magnitude
						local empty = true
						for _, o in players do
							local r = ctx.Util.getRoot(o)
							if r and (r.Position - n.Pos).Magnitude < 18 then
								empty = false
							end
						end
						if empty and d > 16 and d < 34 and d < bestD then
							best, bestD = n.Pos, d
						end
					end
				end
				if best then
					-- whose voice: a friend right here with you (or Mom)
					local friend = nil
					for _, o in players do
						local r = o ~= p and ctx.Util.getRoot(o)
						if r and (r.Position - root.Position).Magnitude < 22 and o:GetAttribute("Role") then
							friend = o
						end
					end
					return { Player = p, From = best, Up = want == "Upstairs", Friend = friend }
				end
			end
			return nil
		end,
		Run = function(ctx, D, data)
			local M = ctx.Story.Mimic
			local p = data.Player
			local function first(pl: Player): string
				local n = pl:GetAttribute("RoleName")
				return type(n) == "string" and string.split(n, " ")[1] or pl.DisplayName
			end
			local text, voice
			local way = data.Up and "Up" or "Down"
			if data.Friend then
				local lines = M.Friend[way]
				text = string.format(lines[math.random(1, #lines)], first(p))
				voice = data.Friend:GetAttribute("Role")
			else
				local lines = M.Mom[way]
				text = lines[math.random(1, #lines)]
				voice = "Mom"
			end
			ctx.Remotes.HisVoice:FireClient(p, text, {
				Voice = voice,
				From = data.From + V(0, 3, 0),
				Range = 60,
				Caption = (data.Up and "[From upstairs] " or "[From downstairs] ") .. "\"" .. text .. "\"",
			})
			task.delay(4.5, function()
				ctx.PlayerState.addNerve(p, -10)
				if data.Friend then
					local f = first(data.Friend)
					D.think(p, string.format(M.ThoughtFriend, f, data.Up and "upstairs" or "downstairs", f))
				else
					D.think(p, M.ThoughtMom)
				end
			end)
			D.logTruth("Mimic")
		end,
	},
	---------------------------------------------------------------------------
	{
		Id = "Floorboard",
		DuringHunt = true, -- ambience, not him
		Acts = { Evening = true, SmallThings = true, SomeoneElse = true },
		Weight = 2,
		Tension = 6,
		Cooldown = 140,
		Cond = function(ctx)
			for _, p in ctx.Util.activePlayers() do
				local root = ctx.Util.getRoot(p)
				if root and floorOf(ctx, root) == "Upstairs" then
					return p
				end
			end
			return nil
		end,
		Run = function(ctx, D, player)
			local root = ctx.Util.getRoot(player)
			if root then
				ctx.Audio.playAt("Floorboard", root.Position + V(0, 13, 0), { Only = { player } })
				D.logTruth("Floorboard")
			end
		end,
	},
	---------------------------------------------------------------------------
	{
		Id = "BreakerAgain",
		DuringHunt = true, -- only when he's really standing at the panel
		Where = function()
			return V(41, 8, -12.7)
		end,
		Acts = { Guest = true },
		Weight = 2,
		Tension = 10,
		Cooldown = 200,
		Cond = function(ctx, D)
			if not ctx.Power.isOn() then
				return nil
			end
			local nearGarage = anyone(ctx, function(_, root)
				local r = ctx.Rooms.find(root.Position)
				return r ~= nil and (r.Name == "Garage" or r.Name == "Mudroom")
			end)
			local ip = ctx.Intruder.position()
			if nearGarage or not ctx.Intruder.isInHouse() or not ip or (ip - V(41, 8, -12.7)).Magnitude > 22 then
				return nil
			end
			return true
		end,
		Run = function(ctx, D)
			ctx.Power.setMain(false, "Intruder")
			ctx.Audio.playAt("Breaker", V(41, 8, -12.7))
			ctx.Audio.playAt("PowerDown", V(0, 8, 0), { Caption = true })
			D.logTruthRaw("The power went out again. Curtis flipped the main breaker a second time.")
		end,
	},
	---------------------------------------------------------------------------
	-- JUMP SCARES: loud, sudden noises with a real cause
	---------------------------------------------------------------------------
	{
		-- the storm: lightning strikes right by the house, the flash and the crack together
		Id = "Thunderclap",
		DuringHunt = true, -- ambience, not him
		Acts = { Evening = true, SmallThings = true, SomeoneElse = true, Guest = true },
		Weight = 2,
		Tension = 8,
		Cooldown = 260,
		Cond = function(ctx)
			local list = {}
			for _, p in ctx.Util.activePlayers() do
				local room = roomOf(ctx, p)
				if room and room.Floor ~= "Basement" and not p:GetAttribute("Hiding") then
					table.insert(list, p)
				end
			end
			return #list > 0 and list or nil
		end,
		Run = function(ctx, D, list)
			local root = ctx.Util.getRoot(list[1])
			if not root then
				return
			end
			ctx.Remotes.Lightning:FireAllClients(1.8, 0.05)
			ctx.Audio.playAt("BigHit", root.Position + V(0, 40, 0), { Volume = 1 })
			ctx.Audio.playAt("Thunder", root.Position + V(0, 40, 0), { Volume = 1, Caption = false })
			ctx.Power.flicker(1.2)
			jolt(ctx, root.Position, 200, 6, 0.6)
			D.logTruth("Thunderclap")
		end,
	},
	{
		Id = "WindSlam",
		Acts = { Evening = true },
		Weight = 4,
		Tension = 10,
		Once = true,
		Cond = function(ctx)
			if ctx.Objectives.isDone("Windows") then
				return nil
			end
			local ok = anyone(ctx, function(_, root)
				return floorOf(ctx, root) == "Ground"
			end)
			return ok and (ctx.Doors.get("Lily") or ctx.Doors.get("Guest")) or nil
		end,
		Run = function(ctx, D, door)
			if door.IsOpen then
				ctx.Doors.close(door)
			end
			ctx.Audio.playAt("DoorSlam", door.Position, { Volume = 1, Range = 160 })
			D.lightning(0.8)
			local hit = jolt(ctx, door.Position, 70, 8, 0.4)
			D.think(#hit > 0 and hit or nil, ctx.Story.Thoughts.Events.WindSlam)
			D.logTruth("WindSlam")
		end,
	},
	{
		Id = "PlateCrash",
		Where = function(_, pos)
			return pos
		end,
		Acts = { SmallThings = true, SomeoneElse = true },
		Weight = 4,
		Tension = 14,
		Once = true,
		Cond = function(ctx)
			local inKitchen, nearby = false, false
			for _, p in ctx.Util.activePlayers() do
				local room, root = roomOf(ctx, p)
				if room and room.Name == "Kitchen" then
					inKitchen = true
				elseif root and root.Position.Y < 12 and (root.Position - V(-16, 4, 17)).Magnitude < 55 then
					nearby = true
				end
			end
			return (nearby and not inKitchen) and V(-16.5, 1, 22.6) or nil
		end,
		Run = function(ctx, D, pos)
			ctx.Audio.playAt("PlateCrash", pos + V(0, 2, 0), { Volume = 1 })
			-- the pieces stay on the floor
			local folder = Instance.new("Model")
			folder.Name = "BrokenPlate" -- Props swaps in a proper broken-plate model
			local rng = Random.new()
			for i = 1, 9 do
				local shard = ctx.Builder.block(folder, "PlateShard", pos + V(rng:NextNumber(-0.8, 0.8), 0.05, rng:NextNumber(-0.6, 0.6)), V(rng:NextNumber(0.25, 0.7), 0.06, rng:NextNumber(0.2, 0.5)), i <= 2 and Color3.fromRGB(70, 110, 150) or Color3.fromRGB(245, 243, 236), Enum.Material.SmoothPlastic, rng:NextNumber(0, 360), { CanCollide = false, CanQuery = false })
				shard.Name = "PlateShard"
			end
			folder.Parent = ctx.World.folder():FindFirstChild("Kitchen") or ctx.World.folder()
			local hit = jolt(ctx, pos, 60, 12, 0.5)
			D.think(#hit > 0 and hit or nil, ctx.Story.Thoughts.Events.PlateCrash)
			D.logTruth("PlateCrash")
		end,
	},
	{
		Id = "CeilingThud",
		Where = function(_, data)
			return data.Pos
		end,
		Acts = { SmallThings = true, SomeoneElse = true, Guest = true },
		Weight = 3,
		Tension = 12,
		Cooldown = 150,
		Cond = function(ctx)
			local choices = {}
			for _, p in ctx.Util.activePlayers() do
				local room, root = roomOf(ctx, p)
				if room and room.Floor == "Upstairs" and not p:GetAttribute("Hiding") then
					table.insert(choices, { Player = p, Pos = V(root.Position.X, 28.8, root.Position.Z) })
				end
			end
			-- only when he could really be up there (offstage, or in the attic itself)
			local ip = ctx.Intruder.position()
			if ip and ctx.Rooms.floorOf(ip) ~= "Attic" then
				return nil
			end
			return ctx.Util.choice(choices)
		end,
		Run = function(ctx, D, data)
			ctx.Audio.playAt("CeilingThud", data.Pos, { Volume = 1 })
			-- dust shaken loose from the ceiling
			local dust = ctx.Builder.block(ctx.World.folder(), "CeilingDust", data.Pos - V(0, 1, 0), V(5, 0.2, 5), Color3.new(), nil, 0, { Transparency = 1, CanCollide = false, CanQuery = false })
			local e = Instance.new("ParticleEmitter")
			e.Texture = "rbxasset://textures/particles/smoke_main.dds"
			e.Color = ColorSequence.new(Color3.fromRGB(190, 180, 165))
			e.Transparency = NumberSequence.new(0.55, 1)
			e.Size = NumberSequence.new(0.4, 1.2)
			e.Lifetime = NumberRange.new(1.5, 2.5)
			e.Speed = NumberRange.new(1, 3)
			e.EmissionDirection = Enum.NormalId.Bottom
			e.Acceleration = V(0, -4, 0)
			-- a short burst (a server-side :Emit() wouldn't reach the clients)
			e.Rate = 90
			e.Parent = dust
			task.delay(0.45, function()
				e.Enabled = false
			end)
			game:GetService("Debris"):AddItem(dust, 4)
			local hit = jolt(ctx, data.Pos - V(0, 12, 0), 26, 10, 0.55)
			D.think(#hit > 0 and hit or data.Player, ctx.Story.Thoughts.Events.CeilingThud)
			D.logTruth("CeilingThud")
		end,
	},
	{
		Id = "WindowBang",
		Acts = { SmallThings = true, SomeoneElse = true },
		Weight = 3,
		Tension = 18,
		Once = true,
		Cond = function(ctx)
			if ctx.Intruder.isInHouse() then
				return nil
			end
			for _, p in ctx.Util.activePlayers() do
				local room, root = roomOf(ctx, p)
				if not room or room.Floor ~= "Ground" or p:GetAttribute("Hiding") then
					continue
				end
				for _, w in ctx.Layout.WindowWatch do
					if w.Room == room.Name and (root.Position - w.Face).Magnitude < 20 then
						return { Player = p, Watch = w }
					end
				end
			end
			return nil
		end,
		Run = function(ctx, D, data)
			local w = data.Watch
			for i = 1, 3 do
				ctx.Audio.playAt("WindowBang", w.Face, { Volume = 1, Caption = i == 1 })
				if i == 1 then
					jolt(ctx, w.Face, 30, 16, 0.6)
					-- him at the glass, both long hands slammed flat against it, for a split second
					ctx.Remotes.Figure:FireClient(data.Player, CFrame.lookAt(w.Stand:Lerp(w.Face, 0.4), w.Face), 0.45, "Reach")
				end
				task.wait(0.28)
			end
			D.think(data.Player, ctx.Story.Thoughts.Events.WindowBang)
			D.logTruth("WindowBang")
		end,
	},
	{
		Id = "DoorRattle",
		Acts = { SmallThings = true, SomeoneElse = true },
		Weight = 2,
		Tension = 14,
		Once = true,
		Cond = function(ctx)
			if ctx.Intruder.isInHouse() then
				return nil
			end
			for _, id in { "FrontDoor", "BackDoor", "GarageSide" } do
				local door = ctx.Doors.get(id)
				if door and not door.IsOpen then
					local near = anyone(ctx, function(_, root)
						local d = (root.Position - door.Position).Magnitude
						return d > 6 and d < 30
					end)
					if near then
						return door
					end
				end
			end
			return nil
		end,
		Run = function(ctx, D, door)
			-- (Director.onDoorOpened: whoever dares to open it in the next while gets a jolt)
			door.YankedAt = os.clock()
			for i = 1, 4 do
				ctx.Audio.playAt("DoorYank", door.Position, { Volume = 1, Caption = i == 1 })
				if i == 1 then
					local hit = jolt(ctx, door.Position, 40, 12, 0.45)
					D.think(#hit > 0 and hit or nil, ctx.Story.Thoughts.Events.DoorRattle)
				end
				task.wait(0.5 + math.random() * 0.4)
			end
			D.logTruth("DoorRattle")
		end,
	},
	{
		Id = "ChairDrop",
		Acts = {}, -- not scheduled: Intruder.lua knocks a chair over when he bolts after being seen
		Weight = 2,
		Tension = 10,
		Cooldown = 200,
		Cond = function(ctx)
			-- an empty ground-floor room next to someone
			local occupied = {}
			local anyRoot
			for _, p in ctx.Util.activePlayers() do
				local room, root = roomOf(ctx, p)
				if room then
					occupied[room.Name] = true
					anyRoot = anyRoot or root
				end
			end
			if not anyRoot then
				return nil
			end
			local best, bestD = nil, math.huge
			for _, name in { "Kitchen", "Living", "Den", "Office", "Mudroom" } do
				local r = ctx.Rooms.ByName[name]
				if r and not occupied[name] then
					local d = (r.Center - anyRoot.Position).Magnitude
					if d > 14 and d < bestD then
						best, bestD = r, d
					end
				end
			end
			return best and bestD < 50 and best or nil
		end,
		Run = function(ctx, D, room)
			local pos = room.Center + V(0, 2, 0)
			ctx.Audio.playAt("ChairDrop", pos, { Volume = 1 })
			local hit = jolt(ctx, pos, 45, 8, 0.35)
			D.think(#hit > 0 and hit or nil, ctx.Story.Thoughts.Events.ChairDrop)
			D.logTruth("ChairDrop")
		end,
	},
	{
		-- Lily's music box starts playing upstairs while nobody is in her room
		Id = "MusicBox",
		Where = function(_, box)
			return box.Position
		end,
		Acts = { SmallThings = true, SomeoneElse = true },
		Weight = 3,
		Tension = 10,
		Once = true,
		Cond = function(ctx)
			local box = ctx.World.folder():FindFirstChild("MusicBox", true)
			if not box then
				return nil
			end
			local inLily, near = false, false
			for _, p in ctx.Util.activePlayers() do
				local room, root = roomOf(ctx, p)
				if room and room.Name == "Lily" then
					inLily = true
				elseif root and (root.Position - box.Position).Magnitude < 60 then
					near = true
				end
			end
			return (near and not inLily) and box or nil
		end,
		Run = function(ctx, D, box)
			ctx.Audio.playAt("MusicBox", box.Position + V(0, 0.5, 0), { Volume = 0.9 })
			D.thinkNear(box.Position, 60, ctx.Story.Thoughts.Events.MusicBox)
			D.logTruth("MusicBox")
		end,
	},
	{
		-- with everyone downstairs, the light in Lily's room comes on
		Id = "LightUpstairs",
		Where = function(ctx)
			local r = ctx.Rooms.ByName.Lily
			return r and r.Center or Vector3.zero
		end,
		Acts = { SmallThings = true },
		Weight = 2,
		Tension = 8,
		Once = true,
		Cond = function(ctx)
			if not ctx.Power.isOn() or ctx.Power.isRoomSwitchOn("Lily") then
				return nil
			end
			return everyone(ctx, function(_, root)
				return floorOf(ctx, root) == "Ground"
			end) and true or nil
		end,
		Run = function(ctx, D)
			ctx.Power.setSwitch("Lily", true)
			D.think(nil, ctx.Story.Thoughts.Events.LightUpstairs)
			D.logTruth("LightUpstairs")
		end,
	},
	{
		-- the unlocked back door is found swinging open, rain blowing in, wet prints on the tile
		Id = "BackDoorOpen",
		Where = function(_, door)
			return door.Position
		end,
		Acts = { SmallThings = true, SomeoneElse = true },
		Weight = 3,
		Tension = 12,
		Once = true,
		Cond = function(ctx)
			local door = ctx.Doors.get("BackDoor")
			if not door or door.Locked or door.IsOpen then
				return nil
			end
			local inKitchen, near = false, false
			for _, p in ctx.Util.activePlayers() do
				local room, root = roomOf(ctx, p)
				if room and room.Name == "Kitchen" then
					inKitchen = true
				elseif root and root.Position.Y < 12 and (root.Position - door.Position).Magnitude < 60 then
					near = true
				end
			end
			return (near and not inKitchen) and door or nil
		end,
		Run = function(ctx, D, door)
			ctx.Doors.open(door, "Intruder")
			ctx.Audio.playAt("DoorSlam", door.Position, { Volume = 0.6, Range = 90 })
			-- wet boot prints from the door into the kitchen, fading toward the hall
			local folder = ctx.World.folder():FindFirstChild("Kitchen") or ctx.World.folder()
			local start = V(door.Position.X, 1.03, door.Position.Z - 2)
			for i = 0, 6 do
				local p = start + V((i % 2 == 0) and 0.45 or -0.45, 0, -i * 2.2)
				local fp = ctx.Builder.block(folder, "WetPrint", p, V(0.55, 0.03, 1.2), Color3.fromRGB(60, 58, 54), Enum.Material.Glass, 0, { CanCollide = false, CanQuery = false })
				fp.Transparency = 0.35 + i * 0.07
				fp.Reflectance = 0.25
			end
			D.thinkNear(door.Position, 60, ctx.Story.Thoughts.Events.BackDoorOpen)
			D.logTruth("BackDoorOpen")
		end,
	},
	---------------------------------------------------------------------------
	-- v131 (the owner: "Add way more scares. Actually scary and creepy stuff.")
	---------------------------------------------------------------------------
	{
		-- someone walking on their own hears footsteps behind them, step for step; they stop when you
		-- stop. Then one more step, and a breath, right behind you.
		Id = "Follower",
		Acts = { Evening = true, SmallThings = true },
		Weight = 3,
		Tension = 12,
		Cooldown = 200,
		Cond = function(ctx)
			for _, p in ctx.Util.activePlayers() do
				local root = ctx.Util.getRoot(p)
				if root and alone(ctx, p, root, 30) and floorOf(ctx, root) ~= "Attic" then
					local v = root.AssemblyLinearVelocity
					if V(v.X, 0, v.Z).Magnitude > 4 then
						return p
					end
				end
			end
			return nil
		end,
		Run = function(ctx, D, p: Player)
			local t0, still, steps = os.clock(), 0, 0
			while os.clock() - t0 < 10 and p.Parent do
				local root = ctx.Util.getRoot(p)
				if not root then
					break
				end
				local v = root.AssemblyLinearVelocity
				local flat = V(v.X, 0, v.Z)
				if flat.Magnitude > 3 then
					still = 0
					ctx.Remotes.PlaySound:FireClient(p, "Footstep", root.Position - flat.Unit * 6 - V(0, 2.5, 0), { Volume = 0.55, Pitch = 0.9 })
					steps += 1
					task.wait(0.5)
				else
					still += 0.25
					if still >= 1 and steps >= 4 then
						break
					end
					task.wait(0.25)
				end
			end
			local root = ctx.Util.getRoot(p)
			if steps >= 4 and root and p.Parent then
				local back = root.Position - root.CFrame.LookVector * 3.5
				task.wait(0.6)
				ctx.Remotes.PlaySound:FireClient(p, "Footstep", back - V(0, 2.5, 0), { Volume = 0.75, Pitch = 0.85 })
				task.wait(0.5)
				ctx.Remotes.PlaySound:FireClient(p, "IntruderBreath", back + V(0, 1.5, 0), { Volume = 0.6 })
				ctx.PlayerState.addNerve(p, -8)
				D.think(p, ctx.Story.Thoughts.Events.Follower)
				D.logTruth("Follower")
			end
		end,
	},
	{
		-- standing at the bottom of the stairs: a red ball comes bouncing down them, from nobody
		Id = "StairBall",
		Acts = { SmallThings = true },
		Weight = 2,
		Tension = 10,
		Once = true,
		Cond = function(ctx)
			local L = ctx.Layout
			local st = L.Stairs.Main
			local bottom = V((st.x0 + st.x1) / 2, st.yStart, st.zStart)
			local top = V((st.x0 + st.x1) / 2, st.yEnd, st.zEnd)
			local nobodyUp = everyone(ctx, function(_, root)
				return (root.Position - top).Magnitude > 16
			end)
			if not nobodyUp then
				return nil
			end
			for _, p in ctx.Util.activePlayers() do
				local root = ctx.Util.getRoot(p)
				if root and not p:GetAttribute("Hiding") and math.abs(root.Position.Y - bottom.Y - 3) < 3 then
					local d = (root.Position - bottom).Magnitude
					local to = (top - root.Position) * V(1, 0, 1)
					if d > 3 and d < 18 and to.Magnitude > 0.5 and root.CFrame.LookVector:Dot(to.Unit) > 0.35 then
						return { Player = p, Top = top }
					end
				end
			end
			return nil
		end,
		Run = function(ctx, D, data)
			local top = data.Top
			ctx.Audio.playAt("StairCreak", top + V(0, 3, 0), { Volume = 0.5 })
			task.wait(0.8)
			local ball = Instance.new("Part")
			ball.Name = "LilyBall"
			ball.Shape = Enum.PartType.Ball
			ball.Size = V(0.85, 0.85, 0.85)
			ball.Color = Color3.fromRGB(210, 40, 40)
			ball.Material = Enum.Material.SmoothPlastic
			ball.CustomPhysicalProperties = PhysicalProperties.new(0.4, 0.4, 0.7, 1, 1)
			ball.CFrame = CFrame.new(top + V(0, 1.2, -0.6))
			ball.CanQuery = false
			ball.Parent = ctx.World.folder()
			ball.AssemblyLinearVelocity = V(0, 2, -9)
			-- a bounce on every tread on the way down
			for _ = 1, 14 do
				if not ball.Parent then
					break
				end
				ctx.Audio.playAt("ToolDrop", ball.Position, { Volume = 0.25, Pitch = 1.7, Range = 50, Caption = false })
				task.wait(0.28)
			end
			D.think(data.Player, ctx.Story.Thoughts.Events.StairBall)
			ctx.PlayerState.addNerve(data.Player, -6)
			D.logTruth("StairBall")
			task.delay(30, function()
				ball:Destroy()
			end)
		end,
	},
	{
		-- with nobody in Lily's room, every bear in it turns to face the door, and her rocking horse rocks.
		-- Whoever walks in first finds them all looking at them.
		Id = "ToysTurn",
		Acts = { SmallThings = true, SomeoneElse = true },
		Weight = 3,
		Tension = 10,
		Once = true,
		Cond = function(ctx)
			local door = ctx.Doors.get("Lily")
			if not door then
				return nil
			end
			local inLily, near = false, false
			for _, p in ctx.Util.activePlayers() do
				local room, root = roomOf(ctx, p)
				if room and room.Name == "Lily" then
					inLily = true
				elseif root and (root.Position - door.Position).Magnitude < 24 then
					near = true
				end
			end
			-- (nobody watching her tea party when it happens)
			if inLily or not near or D_sees(ctx, V(24, ctx.Layout.Y.Upstairs + 1.5, 15.2)) then
				return nil
			end
			return door
		end,
		Run = function(ctx, D, door)
			local target = V(door.Position.X, 0, door.Position.Z)
			for _, m in modelsIn(ctx, "Lily", function(m)
				local k = m:GetAttribute("PropKey")
				return m.Name == "Teddy" or (type(k) == "string" and k:sub(1, 5) == "Teddy")
			end) do
				local c = m:GetBoundingBox()
				turnInPlace(m, facing(c.Position, target - c.Position))
			end
			-- the rocking horse: rocking, slower and slower
			local horse = modelsIn(ctx, "Lily", function(m)
				return m:GetAttribute("PropKey") == "RockingHorse"
			end)[1]
			if horse then
				task.spawn(function()
					local base = horse:GetPivot()
					local t0 = os.clock()
					local nextCreak = 0
					while os.clock() - t0 < 14 and horse.Parent do
						local t = os.clock() - t0
						local a = 0.16 * math.exp(-t / 7) * math.sin(t * 4.2)
						horse:PivotTo(base * CFrame.Angles(0, 0, a))
						if t >= nextCreak then
							nextCreak = t + 0.75
							ctx.Audio.playAt("Floorboard", base.Position, { Volume = 0.25, Pitch = 1.4, Range = 30, Caption = false })
						end
						task.wait(0.05)
					end
					horse:PivotTo(base)
				end)
			end
			-- whoever comes in first
			task.spawn(function()
				local t0 = os.clock()
				while os.clock() - t0 < 60 do
					for _, p in ctx.Util.activePlayers() do
						local room = roomOf(ctx, p)
						if room and room.Name == "Lily" then
							ctx.PlayerState.addNerve(p, -8)
							D.think(p, ctx.Story.Thoughts.Events.ToysTurn)
							return
						end
					end
					task.wait(0.4)
				end
			end)
			D.logTruth("ToysTurn")
		end,
	},
	{
		-- someone alone, looking at a bed: a long charcoal hand slides out from under it, fingers
		-- spread on the floor... and snaps back
		Id = "UnderBed",
		Acts = { SmallThings = true, SomeoneElse = true },
		Weight = 3,
		Tension = 16,
		Cooldown = 150,
		Cond = function(ctx, D)
			for _, spot in ctx.Hiding.all() do
				if type(spot.Name) == "string" and spot.Name:find("bed") and not ctx.Hiding.occupant(spot) then
					local exitP = spot.Exit.Position
					local out = (spot.Exit.Position - spot.Inside.Position) * V(1, 0, 1)
					if out.Magnitude > 0.5 then
						for _, p in ctx.Util.activePlayers() do
							local root = ctx.Util.getRoot(p)
							if root and alone(ctx, p, root, 20) then
								local d = (root.Position - exitP).Magnitude
								local floorY = exitP.Y > 10 and ctx.Layout.Y.Upstairs or ctx.Layout.Y.Ground
								local edge = V(exitP.X, floorY, exitP.Z) - out.Unit * 1.6
								if d > 4 and d < 12 and looksAt(ctx, D, p, edge + V(0, 0.4, 0), 0.75) then
									return { Player = p, Edge = edge, Out = out.Unit }
								end
							end
						end
					end
				end
			end
			return nil
		end,
		Run = function(ctx, D, data)
			local out: Vector3 = data.Out
			local edge: Vector3 = data.Edge
			local folder = ctx.World.folder()
			local function at(k: number): CFrame
				return facing(edge + out * k, out)
			end
			local hand = Haunt.hand(folder, at(-2.6))
			ctx.Audio.playAt("ClawStep", edge, { Volume = 0.6, Range = 30 })
			-- out, the fingers dragging on the floor
			for i = 1, 10 do
				hand:PivotTo(at(-2.6 + 3.6 * (i / 10) ^ 0.7))
				task.wait(0.045)
			end
			ctx.PlayerState.addNerve(data.Player, -14)
			ctx.Remotes.Shake:FireClient(data.Player, 0.25, 0.4)
			sting(ctx, { data.Player })
			task.wait(1.0)
			ctx.Audio.playAt("ClawStep", edge, { Volume = 0.8, Range = 30 })
			-- and gone, fast
			for i = 1, 3 do
				hand:PivotTo(at(1.0 - 3.8 * i / 3))
				task.wait(0.03)
			end
			hand:Destroy()
			D.think(data.Player, ctx.Story.Thoughts.Events.UnderBed)
			D.logTruth("UnderBed")
		end,
	},
	{
		-- red writing on a wall, in a room nobody's in: found later. Sometimes it has your name in it.
		Id = "Scrawl",
		Acts = { SmallThings = true, SomeoneElse = true },
		DuringHunt = true,
		Weight = 3,
		Tension = 10,
		Cooldown = 100,
		Cond = function(ctx, D)
			local folder = ctx.World.folder()
			if not folder then
				return nil
			end
			scrawled[folder] = scrawled[folder] or {}
			local used = scrawled[folder]
			local n = 0
			for _ in used do
				n += 1
			end
			if n >= 4 then
				return nil
			end
			local order = {}
			for i in SCRAWLS do
				table.insert(order, i)
			end
			for i = #order, 2, -1 do
				local j = math.random(1, i)
				order[i], order[j] = order[j], order[i]
			end
			for _, i in order do
				local s = SCRAWLS[i]
				if not used[i] then
					local busy = false
					for _, p in ctx.Util.activePlayers() do
						local room, root = roomOf(ctx, p)
						if (room and room.Name == s.Room) or (root and (root.Position - s.At).Magnitude < 22) then
							busy = true
						end
					end
					if not busy and not D_sees(ctx, s.At) then
						return i
					end
				end
			end
			return nil
		end,
		Run = function(ctx, D, i: number)
			local folder = ctx.World.folder()
			local s = SCRAWLS[i]
			scrawled[folder] = scrawled[folder] or {}
			scrawled[folder][i] = true
			scrawlLines[folder] = scrawlLines[folder] or {}
			local lines = {}
			for _, l in SCRAWL_TEXT do
				if not scrawlLines[folder][l] then
					table.insert(lines, l)
				end
			end
			local line = #lines > 0 and lines[math.random(1, #lines)] or SCRAWL_TEXT[1]
			scrawlLines[folder][line] = true
			if line:find("{NAME}") then
				local ps = ctx.Util.activePlayers()
				local who = #ps > 0 and ps[math.random(1, #ps)] or nil
				line = (line:gsub("{NAME}", who and string.upper(who.DisplayName) or "YOU"))
			end
			local part = Haunt.scrawl(folder:FindFirstChild(s.Room) or folder, facing(s.At, s.Into), s.W, s.H, line)
			D.logTruth("Scrawl")
			-- the first to see it
			task.spawn(function()
				local t0 = os.clock()
				while part.Parent and os.clock() - t0 < 600 do
					for _, p in ctx.Util.activePlayers() do
						local room, root = roomOf(ctx, p)
						-- (in the room, facing that wall: furniture under the words doesn't hide them)
						local facing = root ~= nil and room ~= nil and room.Name == s.Room and root.CFrame.LookVector:Dot(-s.Into) > 0.6
						if root and (root.Position - s.At).Magnitude < 22 and (facing or looksAt(ctx, D, p, s.At, 0.8)) then
							ctx.Remotes.PlaySound:FireClient(p, "HorrorHitLow", nil, { Volume = 0.7 })
							ctx.PlayerState.addNerve(p, -10)
							D.think(p, ctx.Story.Thoughts.Events.Scrawl)
							return
						end
					end
					task.wait(0.5)
				end
			end)
		end,
	},
	{
		-- with the kitchen empty, every chair at the table is pulled out and turned to face the doorway.
		-- They're put back before he comes (the hiding spot under the table stays clear).
		Id = "KitchenChairs",
		Acts = { SmallThings = true },
		Weight = 2,
		Tension = 10,
		Once = true,
		Cond = function(ctx)
			local r = ctx.Rooms.ByName.Kitchen
			local inKitchen, near = false, false
			for _, p in ctx.Util.activePlayers() do
				local room, root = roomOf(ctx, p)
				if room and room.Name == "Kitchen" then
					inKitchen = true
				elseif root and root.Position.Y < 12 and (root.Position - r.Center).Magnitude < 45 then
					near = true
				end
			end
			if inKitchen or not near or D_sees(ctx, V(-15, 3.5, 17.5)) then
				return nil
			end
			local chairs = modelsIn(ctx, "Kitchen", function(m)
				return m:GetAttribute("PropKey") == "DiningChair"
			end)
			return #chairs > 0 and chairs or nil
		end,
		Run = function(ctx, D, chairs: { Model })
			local door = V(-8, 0, 26) -- (the kitchen's doorway from the front hall)
			local table0 = V(-15, 0, 17.5)
			local before = {}
			for _, m in chairs do
				before[m] = m:GetPivot()
				local c = m:GetBoundingBox()
				local away = (c.Position - table0) * V(1, 0, 1)
				local pos = c.Position + (away.Magnitude > 0.1 and V(away.Unit.X, 0, 0) * 1.0 or Vector3.zero)
				turnInPlace(m, facing(pos, door - c.Position))
			end
			ctx.Audio.playAt("ChairDrop", table0 + V(0, 3, 0), { Volume = 0.25, Range = 40, Caption = false })
			D.logTruth("KitchenChairs")
			task.spawn(function()
				local seen = false
				local t0 = os.clock()
				while os.clock() - t0 < 900 do
					if not seen then
						for _, p in ctx.Util.activePlayers() do
							local room = roomOf(ctx, p)
							if room and room.Name == "Kitchen" then
								seen = true
								ctx.PlayerState.addNerve(p, -8)
								D.think(p, ctx.Story.Thoughts.Events.KitchenChairs)
								break
							end
						end
					end
					-- back as they were once he's hunting, so nobody trips on them under the table
					if ctx.Intruder.isHunting() then
						break
					end
					task.wait(0.5)
				end
				for m, cf in before do
					if m.Parent then
						m:PivotTo(cf)
					end
				end
			end)
		end,
	},
	{
		-- alone by a closed closet: three slow knocks from inside it. Then scratching.
		Id = "ClosetKnock",
		Acts = { Evening = true, SmallThings = true, SomeoneElse = true },
		DuringHunt = true, -- (during the hunt too: you'll never know if it's him)
		Weight = 2,
		Tension = 10,
		Cooldown = 180,
		Cond = function(ctx)
			for _, spot in ctx.Hiding.all() do
				local name = type(spot.Name) == "string" and spot.Name:lower() or ""
				if (name:find("closet") or name:find("wardrobe") or name:find("cupboard") or name:find("cabinet")) and not ctx.Hiding.occupant(spot) then
					local inside = spot.Inside.Position
					for _, p in ctx.Util.activePlayers() do
						local root = ctx.Util.getRoot(p)
						if root and alone(ctx, p, root, 25) then
							local d = (root.Position - inside).Magnitude
							if d > 3.5 and d < 10 then
								return { Player = p, At = inside }
							end
						end
					end
				end
			end
			return nil
		end,
		Run = function(ctx, D, data)
			for _ = 1, 3 do
				ctx.Audio.playAt("Knock", data.At, { Volume = 0.45, Pitch = 0.8, Range = 25, Caption = false })
				task.wait(0.9)
			end
			task.wait(1.4)
			ctx.Audio.playAt("ClawStep", data.At, { Volume = 0.5, Range = 20, Caption = false })
			task.wait(0.5)
			ctx.Audio.playAt("ClawStep", data.At, { Volume = 0.5, Pitch = 0.8, Range = 20, Caption = false })
			ctx.PlayerState.addNerve(data.Player, -8)
			D.think(data.Player, ctx.Story.Thoughts.Events.ClosetKnock)
			D.logTruth("ClosetKnock")
		end,
	},
	{
		-- the house phone in the kitchen rings. It stops the moment anyone gets close to it.
		Id = "HousePhone",
		Acts = { Evening = true, SmallThings = true },
		Weight = 2,
		Tension = 8,
		Once = true,
		Cond = function(ctx)
			local folder = ctx.World.folder()
			local kitchen = folder and folder:FindFirstChild("Kitchen")
			local phone = kitchen and kitchen:FindFirstChild("Landline", true)
			if not phone then
				return nil
			end
			local pos = phone:IsA("Model") and phone:GetPivot().Position or (phone :: BasePart).Position
			local near, close = false, false
			for _, p in ctx.Util.activePlayers() do
				local root = ctx.Util.getRoot(p)
				if root then
					local d = (root.Position - pos).Magnitude
					if d < 14 then
						close = true
					elseif d < 60 then
						near = true
					end
				end
			end
			return (near and not close) and pos or nil
		end,
		Run = function(ctx, D, pos: Vector3)
			-- (the ring loops: it goes on for 15 s, or until someone gets close)
			local ring = ctx.Audio.playAt("PhoneRing", pos, { Volume = 0.7, Duration = 15 })
			local stopped = false
			local t0 = os.clock()
			while os.clock() - t0 < 15 and not stopped do
				for _, p in ctx.Util.activePlayers() do
					local root = ctx.Util.getRoot(p)
					if root and (root.Position - pos).Magnitude < 7 then
						stopped = true
						if ring then
							ring:Stop()
						end
						D.think(p, ctx.Story.Thoughts.Events.HousePhoneStop)
						break
					end
				end
				task.wait(0.2)
			end
			if not stopped then
				D.thinkNear(pos, 60, ctx.Story.Thoughts.Events.HousePhone)
			end
			D.logTruth("HousePhone")
		end,
	},
	{
		-- climbing into the attic: the rocking chair by his nest is rocking. Nobody's in it.
		Id = "Rocker",
		Acts = { SmallThings = true, SomeoneElse = true, Guest = true },
		DuringHunt = true,
		Weight = 5,
		Tension = 6,
		Once = true,
		Cond = function(ctx)
			local folder = ctx.World.folder()
			local junk = folder and folder:FindFirstChild("AtticJunk")
			local rocker = junk and junk:FindFirstChild("Rocker")
			if not rocker or not rocker:IsA("Model") then
				return nil
			end
			for _, p in ctx.Util.activePlayers() do
				local root = ctx.Util.getRoot(p)
				if root and root.Position.Y > 29 then
					return { Player = p, Chair = rocker }
				end
			end
			return nil
		end,
		Run = function(ctx, D, data)
			local chair: Model = data.Chair
			local base = chair:GetPivot()
			ctx.PlayerState.addNerve(data.Player, -6)
			D.think(data.Player, ctx.Story.Thoughts.Events.Rocker)
			D.logTruth("Rocker")
			local t0, nextCreak = os.clock(), 0
			while os.clock() - t0 < 16 and chair.Parent do
				local t = os.clock() - t0
				chair:PivotTo(base * CFrame.Angles(0.14 * math.exp(-t / 8) * math.sin(t * 3.2), 0, 0))
				if t >= nextCreak then
					nextCreak = t + math.pi / 3.2
					ctx.Audio.playAt("Floorboard", base.Position, { Volume = 0.3, Pitch = 1.25, Range = 40, Caption = false })
				end
				task.wait(0.05)
			end
			chair:PivotTo(base)
		end,
	},
	{
		-- (v132) the room scare: not scheduled; Director.roomEntered fires it as you walk into a room.
		-- Everyone in that room sees it (client Effects.apparition: the lights stutter and die, he's there,
		-- the lights come up on him, then snap off with a loud hit, and when they're back he's gone).
		Id = "Apparition",
		Acts = {},
		Tension = 14,
		Cond = function()
			return nil
		end,
		Run = function(ctx, D, data)
			local who = {}
			for _, p in ctx.Util.activePlayers() do
				local room = roomOf(ctx, p)
				if p == data.Player or (room and room.Name == data.Room) then
					table.insert(who, p)
					ctx.Remotes.Apparition:FireClient(p, data.Spot, data.Room)
				end
			end
			task.wait(1.9)
			for _, p in who do
				ctx.PlayerState.addNerve(p, -14)
			end
			D.think(who, data.Window and ctx.Story.Thoughts.Events.ApparitionWindow or ctx.Story.Thoughts.Events.Apparition)
			D.logTruth("Apparition")
		end,
	},
}

return Events
