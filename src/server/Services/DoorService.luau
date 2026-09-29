--[[
	DoorService — hinged doors with locks.

	Doors swing around their hinge (animated), carry a PathfindingModifier so the
	intruder can path through them, and emit noise when used.

	Lock types:
		Privacy  : thumb-turn, anyone can lock/unlock (bathrooms, bedrooms)
		Key      : needs the key item (office, basement) — HouseKeys opens everything
		Deadbolt : exterior thumb-turn, loud
]]

local TweenService = game:GetService("TweenService")

local Doors = {}
local ctx

local byId = {}
local list = {}

local OPEN_ANGLE = math.rad(100)

function Doors.init(c)
	ctx = c
end

function Doors.reset()
	byId = {}
	list = {}
end

local function doorCFrame(door, angle: number): CFrame
	return CFrame.new(door.Hinge) * CFrame.Angles(0, angle * door.Sign, 0) * CFrame.new(door.Offset)
end

local function applyAngle(door, angle: number)
	door.Angle = angle
	door.Model:PivotTo(doorCFrame(door, angle))
end

local function updatePrompts(door)
	if door.OpenPrompt then
		door.OpenPrompt.ActionText = door.IsOpen and "Close" or "Open"
	end
	if door.LockPrompt then
		door.LockPrompt.ActionText = door.Locked and "Unlock" or "Lock"
		door.LockPrompt.Enabled = not door.IsOpen
	end
end

local function tweenTo(door, target: number, time: number)
	if door.Tween then
		door.Tween:Cancel()
	end
	local value = Instance.new("NumberValue")
	value.Value = door.Angle
	local conn = value.Changed:Connect(function(v)
		applyAngle(door, v)
	end)
	local tw = TweenService:Create(value, TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Value = target })
	door.Tween = tw
	tw.Completed:Connect(function()
		conn:Disconnect()
		value:Destroy()
		if door.Tween == tw then
			door.Tween = nil
		end
	end)
	tw:Play()
end

local function hasKey(player: Player, door): boolean
	if not door.Key then
		return true
	end
	return ctx.Inventory.has(player, door.Key) or ctx.Inventory.has(player, "HouseKeys")
end

--[[
	Create a door in a wall opening (from Builder.wall). spec is the Layout opening.
]]
function Doors.create(parent: Instance, op)
	local alongX = op.Axis == "X"
	local w, h = op.w - 0.15, op.h - 0.1
	local t = 0.35
	local wallDir = alongX and Vector3.new(1, 0, 0) or Vector3.new(0, 0, 1)
	local hingeEnd = op.hinge == "max" and 1 or -1
	local hinge = op.Center + wallDir * hingeEnd * (op.w / 2 - 0.05)
	local centerClosed = op.Center + Vector3.new(0, h / 2 + 0.02, 0)
	local offset = centerClosed - hinge

	-- rotation sign so the door swings to the requested side
	local sign
	if alongX then
		if hingeEnd == -1 then
			sign = op.into == "-" and 1 or -1
		else
			sign = op.into == "+" and 1 or -1
		end
	else
		if hingeEnd == -1 then
			sign = op.into == "+" and 1 or -1
		else
			sign = op.into == "-" and 1 or -1
		end
	end

	local model = Instance.new("Model")
	model.Name = "Door_" .. op.id
	model.Parent = parent

	local exterior = op.exterior == true
	local color = exterior and Color3.fromRGB(70, 40, 35) or ctx.Builder.C.Trim
	local panel = ctx.Builder.part(model, {
		Name = "Panel",
		Size = alongX and Vector3.new(w, h, t) or Vector3.new(t, h, w),
		CFrame = CFrame.new(centerClosed),
		Color = color,
		Material = Enum.Material.Wood,
	})
	model.PrimaryPart = panel
	-- inset panels for detail
	for i = -1, 1, 2 do
		local inset = alongX and Vector3.new(w * 0.7, h * 0.35, t + 0.08) or Vector3.new(t + 0.08, h * 0.35, w * 0.7)
		ctx.Builder.part(model, {
			Name = "Inset",
			Size = inset,
			CFrame = CFrame.new(centerClosed + Vector3.new(0, i * h * 0.22, 0)),
			Color = color:Lerp(Color3.new(0, 0, 0), 0.08),
			Material = Enum.Material.Wood,
			CanCollide = false,
			CanQuery = false,
		})
	end
	-- knob on the far side from the hinge
	local knobPos = centerClosed - wallDir * hingeEnd * (w / 2 - 0.5) + Vector3.new(0, -0.8, 0)
	for side = -1, 1, 2 do
		local off = alongX and Vector3.new(0, 0, side * (t / 2 + 0.15)) or Vector3.new(side * (t / 2 + 0.15), 0, 0)
		ctx.Builder.part(model, {
			Name = "Knob",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.45, 0.45, 0.45),
			CFrame = CFrame.new(knobPos + off),
			Color = Color3.fromRGB(190, 170, 110),
			Material = Enum.Material.Metal,
			CanCollide = false,
			CanQuery = false,
		})
	end

	local modifier = Instance.new("PathfindingModifier")
	modifier.Label = "Door"
	modifier.PassThrough = true
	modifier.Parent = panel

	local door = {
		Id = op.id,
		Name = op.name or op.id,
		Model = model,
		Panel = panel,
		Hinge = hinge,
		Offset = offset,
		Sign = sign,
		Angle = 0,
		IsOpen = false,
		Locked = op.locked == true,
		LockType = op.lock,
		Key = op.key,
		Exterior = exterior,
		Position = op.Center + Vector3.new(0, 3, 0),
		Axis = op.Axis,
	}
	byId[door.Id] = door
	table.insert(list, door)

	door.OpenPrompt = ctx.Interaction.prompt(panel, {
		Name = "DoorOpen",
		Action = "Open",
		Object = door.Name,
		Distance = 7,
	}, function(player)
		if door.IsOpen then
			Doors.close(door, player)
		else
			Doors.tryOpen(door, player)
		end
	end)

	if door.LockType then
		door.LockPrompt = ctx.Interaction.prompt(panel, {
			Name = "DoorLock",
			Action = door.Locked and "Unlock" or "Lock",
			Object = door.Name,
			Key = Enum.KeyCode.R,
			Hold = door.LockType == "Deadbolt" and 0.6 or 0.3,
			Distance = 6,
		}, function(player)
			Doors.toggleLock(door, player)
		end)
	end
	updatePrompts(door)
	return door
end

function Doors.get(id: string)
	return byId[id]
end

function Doors.all()
	return list
end

function Doors.open(door, byWho: string?, fast: boolean?)
	if door.IsOpen then
		return
	end
	door.IsOpen = true
	tweenTo(door, OPEN_ANGLE, fast and 0.35 or 0.9)
	updatePrompts(door)
	if fast then
		ctx.Audio.playAt("DoorSlam", door.Position)
		ctx.Noise.emit(door.Position, ctx.Config.Noise.DoorSlam, "Door")
	else
		ctx.Audio.playAt("DoorOpen", door.Position, { Caption = byWho == "Intruder" and nil or false })
		ctx.Noise.emit(door.Position, ctx.Config.Noise.Door, "Door")
	end
end

function Doors.close(door, player: Player?)
	if not door.IsOpen then
		return
	end
	door.IsOpen = false
	tweenTo(door, 0, 0.8)
	updatePrompts(door)
	ctx.Audio.playAt("DoorClose", door.Position, { Caption = false })
	ctx.Noise.emit(door.Position, ctx.Config.Noise.Door, "Door", player)
end

function Doors.tryOpen(door, player: Player)
	if door.Locked then
		-- thumb-turn locks open from either side for players except keyed locks
		ctx.Audio.playAt("DoorRattle", door.Position, { Caption = false })
		ctx.Noise.emit(door.Position, ctx.Config.Noise.Door, "Rattle", player)
		if door.LockType == "Key" and not hasKey(player, door) then
			ctx.Audio.caption("It's locked. You need a key.", nil, nil, { player })
		else
			ctx.Audio.caption("It's locked. (Press R to unlock)", nil, nil, { player })
		end
		return
	end
	Doors.open(door, "Player")
	if ctx.Director then
		ctx.Director.onDoorOpened(door, player)
	end
end

function Doors.toggleLock(door, player: Player)
	if door.IsOpen then
		return
	end
	if door.LockType == "Key" and not hasKey(player, door) then
		ctx.Audio.caption("You need the key for this lock.", nil, nil, { player })
		return
	end
	door.Locked = not door.Locked
	updatePrompts(door)
	local loud = door.LockType == "Deadbolt"
	ctx.Audio.playAt("Deadbolt", door.Position, { Caption = false })
	ctx.Noise.emit(door.Position, loud and ctx.Config.Noise.Deadbolt or 6, "Lock", player)
	ctx.Audio.caption(door.Locked and ("Locked: " .. door.Name) or ("Unlocked: " .. door.Name), nil, nil, { player })
	if ctx.Director then
		ctx.Director.onDoorLockChanged(door, player)
	end
end

function Doors.setLocked(door, locked: boolean)
	door.Locked = locked
	updatePrompts(door)
end

-- Silent partial open (used by the Director when nobody is looking)
function Doors.setAjar(door, degrees: number)
	door.IsOpen = true
	tweenTo(door, math.rad(degrees), 2.5)
	updatePrompts(door)
end

--[[
	Intruder use: returns the seconds he must wait before walking through.
	Locked doors get forced (loud) unless it's a thumb-turn on his side.
]]
function Doors.intruderOpen(door, hurry: boolean?): number
	if door.IsOpen then
		return 0
	end
	local wait = 0.4
	if door.Locked then
		if door.LockType == "Deadbolt" or door.LockType == "Privacy" then
			-- he picks privacy locks with a coin / knows the deadbolts; a short pause
			wait = door.LockType == "Privacy" and 2.5 or 1.2
			ctx.Audio.playAt("DoorRattle", door.Position)
			ctx.Noise.emit(door.Position, ctx.Config.Noise.Door, "Rattle")
		else
			wait = ctx.Config.Intruder.ForceLockTime
			ctx.Audio.playAt("DoorForce", door.Position)
			ctx.Noise.emit(door.Position, 60, "Force")
		end
		door.Locked = false
	end
	task.delay(wait, function()
		if not door.IsOpen then
			Doors.open(door, "Intruder", hurry)
		end
	end)
	return wait + 0.3
end

function Doors.nearestClosed(pos: Vector3, radius: number)
	local best, bestD = nil, radius
	for _, door in list do
		if not door.IsOpen then
			local d = (door.Position - pos).Magnitude
			if d < bestD then
				best, bestD = door, d
			end
		end
	end
	return best
end

return Doors
