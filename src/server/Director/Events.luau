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
			D.lightning(1.2)
			ctx.Remotes.Figure:FireClient(data.Player, CFrame.lookAt(w.Stand, w.Face), 1.4)
			task.delay(0.3, function()
				ctx.PlayerState.addNerve(data.Player, -12)
				ctx.Remotes.Shake:FireClient(data.Player, 0.35, 0.8)
				D.think(data.Player, ctx.Story.Thoughts.Events.FigureWindow)
			end)
			D.logTruth("FigureWindow")
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
					-- his silhouette right up against the glass, for a split second
					ctx.Remotes.Figure:FireClient(data.Player, CFrame.lookAt(w.Stand:Lerp(w.Face, 0.85), w.Face), 0.45)
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
}

return Events
