--[[
	Events — the Director's library of "small things". Every one has a real cause,
	logged to the truth timeline when it fires.

	Event fields:
		Id, Acts = { [act] = true }, Weight, Tension, Once, Cooldown (s)
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
		end,
	},
	---------------------------------------------------------------------------
	{
		Id = "DoorAjar",
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
				D.thinkNear(V(-30, 4, -10), 60, ctx.Story.Thoughts.Events.TVAlert)
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
			if nearGarage or not ctx.Intruder.isInHouse() then
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
}

return Events
