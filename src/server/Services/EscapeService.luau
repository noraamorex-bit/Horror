--[[
	EscapeService — every way out of the night, plus the police response.

	Routes: landline (after splicing the cut line), cell call (PhoneService), the neighbor,
	the car (keys + garage door), breaking a window. Help called -> police timer -> ending.
]]

local TweenService = game:GetService("TweenService")

local Escape = {}
local ctx

local state = {}

local function freshState()
	return {
		HelpCalled = false,
		HelpMethod = nil,
		HelpCaller = nil,
		PoliceETA = nil,
		LineCut = false,
		LineRepaired = false,
		Landline = nil, -- {Part, Prompt, Ringing, RingSound, Call}
		GarageOpen = false,
		GarageDoor = nil,
		Car = nil,
		Nest = nil,
		KeyHook = nil,
		Knocking = false,
		PoliceArrived = false,
	}
end

function Escape.init(c)
	ctx = c
	state = freshState()
end

function Escape.reset()
	state = freshState()
	workspace:SetAttribute("PoliceETA", nil)
	workspace:SetAttribute("HelpMethod", nil)
end

function Escape.helpCalled(): boolean
	return state.HelpCalled
end

function Escape.helpMethod(): string?
	return state.HelpMethod
end

function Escape.helpCaller(): Player?
	return state.HelpCaller
end

local function say(lines, position: Vector3?, range: number?, only, gap: number?)
	for _, line in lines do
		ctx.Audio.caption(line, position, range or 25, only)
		task.wait(gap or 2.6)
	end
end

---------------------------------------------------------------------------
-- Help / police
---------------------------------------------------------------------------
function Escape.callForHelp(method: string, player: Player?)
	if state.HelpCalled then
		return
	end
	state.HelpCalled = true
	state.HelpMethod = method
	state.HelpCaller = player
	local H = ctx.Config.Help
	local eta = (method == "Car" and H.CarResponse) or (method == "Neighbor" and H.NeighborResponse) or H.PhoneResponse
	state.PoliceETA = os.clock() + eta
	workspace:SetAttribute("PoliceETA", workspace:GetServerTimeNow() + eta)
	workspace:SetAttribute("HelpMethod", method)

	ctx.Objectives.complete("Call911")
	ctx.Objectives.complete("Phone")
	ctx.Objectives.complete("Neighbor")
	ctx.Objectives.complete("Car")
	ctx.Objectives.add("Survive")
	ctx.Remotes.Notify:FireAllClients("Help is coming. Police ETA " .. ctx.Util.formatSeconds(eta) .. ". Survive.", "objective")
	ctx.Director.logTruthRaw("Help was called (" .. method .. ").")
	if ctx.Intruder then
		ctx.Intruder.onHelpCalled(player)
	end

	task.delay(eta, function()
		Escape.policeArrive()
	end)
end

function Escape.policeArrive()
	if state.PoliceArrived or ctx.Ending.isOver() then
		return
	end
	state.PoliceArrived = true
	local world = ctx.World.folder()
	local model = Instance.new("Model")
	model.Name = "PoliceCar"
	model.Parent = world
	local start = Vector3.new(-220, 2.5, -76)
	local body = ctx.Builder.block(model, "Body", start, Vector3.new(16, 3.5, 7.5), Color3.fromRGB(25, 25, 30), Enum.Material.SmoothPlastic)
	ctx.Builder.block(model, "Doors", start + Vector3.new(0, 0.2, 0), Vector3.new(7, 2.4, 7.6), Color3.fromRGB(230, 230, 230), Enum.Material.SmoothPlastic)
	ctx.Builder.block(model, "Cabin", start + Vector3.new(-1, 3, 0), Vector3.new(8, 2.8, 7), Color3.fromRGB(20, 20, 24), Enum.Material.Glass)
	local bar = ctx.Builder.block(model, "LightBar", start + Vector3.new(-1, 4.6, 0), Vector3.new(1.2, 0.5, 5), Color3.fromRGB(40, 40, 40), Enum.Material.SmoothPlastic)
	model.PrimaryPart = body
	local red = Instance.new("PointLight")
	red.Color = Color3.fromRGB(255, 30, 30)
	red.Range = 45
	red.Brightness = 6
	red.Parent = bar
	local blue = Instance.new("SpotLight")
	blue.Color = Color3.fromRGB(40, 80, 255)
	blue.Range = 55
	blue.Brightness = 8
	blue.Angle = 120
	blue.Face = Enum.NormalId.Back
	blue.Parent = body
	local siren = ctx.Audio.loopOn("Siren", body)
	task.spawn(function()
		local on = true
		while model.Parent do
			on = not on
			red.Enabled = on
			blue.Enabled = not on
			task.wait(0.35)
		end
	end)
	ctx.Remotes.Notify:FireAllClients("Red and blue light, through the rain.", "objective")
	local target = ctx.Layout.Outside.PoliceStop + Vector3.new(0, 2.5, 0)
	local value = Instance.new("CFrameValue")
	value.Value = CFrame.new(start)
	value.Changed:Connect(function(cf)
		model:PivotTo(cf)
	end)
	local tw = TweenService:Create(value, TweenInfo.new(7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = CFrame.new(target) })
	tw:Play()
	if siren then
		siren.RollOffMaxDistance = 600
	end
	task.wait(8)

	local kind
	if ctx.Intruder and ctx.Intruder.getState() == "Trapped" then
		kind = "LockedIn"
	elseif state.HelpMethod == "Car" then
		kind = "Taillights"
	elseif state.HelpMethod == "Neighbor" then
		kind = "NextDoor"
	elseif state.HelpMethod == "Dawn" then
		kind = "Dawn"
	else
		kind = "Sirens"
	end
	ctx.Ending.trigger(kind)
end

-- The hard-cap ending
function Escape.dawn()
	if state.HelpCalled then
		return
	end
	state.HelpCalled = true
	state.HelpMethod = "Dawn"
	ctx.Remotes.Lightning:FireAllClients(0, 0) -- no-op flash to sync
	task.spawn(Escape.policeArrive)
end

---------------------------------------------------------------------------
-- Escaping players are moved to a safe spot and spectate
---------------------------------------------------------------------------
function Escape.markEscaped(player: Player, where: string)
	if player:GetAttribute("Escaped") then
		return
	end
	if ctx.Hiding.spotOf(player) then
		ctx.Hiding.exit(player, true)
	end
	player:SetAttribute("Escaped", where)
	ctx.PlayerState.setFlashlight(player, false)
	ctx.Remotes.Fade:FireClient(player, true, 0.8)
	task.delay(1, function()
		local char = player.Character
		if char then
			ctx.PlayerState.setFrozen(player, false)
			char:PivotTo(CFrame.new(ctx.Layout.Outside.NeighborSafe + Vector3.new(math.random(-3, 3), 0, math.random(-2, 2))))
		end
		ctx.Remotes.Fade:FireClient(player, false, 1.5)
		ctx.Audio.caption("You're out. You're safe. The others aren't.", nil, nil, { player })
	end)
	if ctx.Director then
		ctx.Director.checkAllCaptured()
	end
end

---------------------------------------------------------------------------
-- Landline + junction box
---------------------------------------------------------------------------
function Escape.setupLandline(part: BasePart)
	local line = { Part = part, Ringing = nil }
	state.Landline = line
	line.Prompt = ctx.Interaction.prompt(part, {
		Action = "Pick up",
		Object = "Kitchen phone",
		Distance = 6,
	}, function(player)
		Escape.useLandline(player)
	end)
	Escape.refreshLandline()
end

function Escape.refreshLandline()
	local line = state.Landline
	if not line then
		return
	end
	local act = ctx.Director and ctx.Director.getAct() or "Lobby"
	if line.Ringing then
		line.Prompt.ActionText = "Answer"
		line.Prompt.HoldDuration = 0
	elseif act == "Evening" and not ctx.Objectives.isDone("OrderPizza") then
		line.Prompt.ActionText = "Order pizza"
		line.Prompt.HoldDuration = 0.5
	elseif (act == "SomeoneElse" or act == "Guest") and state.LineRepaired and not state.HelpCalled then
		line.Prompt.ActionText = "Call 911"
		line.Prompt.HoldDuration = ctx.Config.Help.LandlineCallDuration
	else
		line.Prompt.ActionText = "Pick up"
		line.Prompt.HoldDuration = 0
	end
end

function Escape.ringLandline(callId: string, onAnswered)
	local line = state.Landline
	if not line or line.Ringing then
		return
	end
	line.Ringing = callId
	line.OnAnswered = onAnswered
	line.RingSound = ctx.Audio.loopOn("PhoneRing", line.Part)
	ctx.Noise.emit(line.Part.Position, 60, "Phone")
	Escape.refreshLandline()
	-- stop ringing after a while
	task.delay(25, function()
		if line.Ringing == callId then
			line.Ringing = nil
			if line.RingSound then
				line.RingSound:Destroy()
			end
			Escape.refreshLandline()
		end
	end)
end

function Escape.useLandline(player: Player)
	local line = state.Landline
	local pos = line.Part.Position
	if line.Ringing then
		local callId = line.Ringing
		line.Ringing = nil
		if line.RingSound then
			line.RingSound:Destroy()
		end
		Escape.refreshLandline()
		if line.OnAnswered then
			task.spawn(line.OnAnswered, player)
		end
		say(ctx.Story.Calls[callId] or {}, pos, 20)
		return
	end
	local act = ctx.Director.getAct()
	if act == "Evening" and not ctx.Objectives.isDone("OrderPizza") then
		if not ctx.Objectives.isStepDone("OrderPizza", "Menu") then
			ctx.Director.think(player, "I don't know Tony's number by heart. Mom keeps the menu on the fridge.")
			return
		end
		ctx.Audio.playAt("DialTone", pos, { Caption = false })
		ctx.Objectives.complete("OrderPizza")
		Escape.refreshLandline()
		say(ctx.Story.Calls.OrderPizza, pos, 20)
		return
	end
	if state.LineCut and not state.LineRepaired then
		say(ctx.Story.Calls.Dead, pos, 12, { player })
		if act ~= "Evening" and act ~= "SmallThings" then
			ctx.Director.logTruth("LineCut")
		end
		return
	end
	if (act == "SomeoneElse" or act == "Guest") and not state.HelpCalled then
		ctx.Noise.emit(pos, ctx.Config.Noise.PhoneCall, "Voice", player)
		task.spawn(say, ctx.Story.Calls.Dispatch, pos, 20, nil, 2.2)
		Escape.callForHelp("Landline", player)
		Escape.refreshLandline()
		return
	end
	ctx.Audio.playAt("DialTone", pos, { Caption = false })
	ctx.Audio.caption("(Dial tone. Nobody to call.)", nil, nil, { player })
end

function Escape.cutLine()
	state.LineCut = true
	state.LineRepaired = false
	Escape.refreshLandline()
	local box = state.Junction
	if box then
		box.Door.CFrame = box.OpenCF
		box.Wire.Transparency = 1
		box.CutWire.Transparency = 0
	end
end

function Escape.isLineWorking(): boolean
	return not state.LineCut or state.LineRepaired
end

function Escape.setupJunctionBox(model: Model, door: BasePart, openCF: CFrame, wire: BasePart, cutWire: BasePart)
	state.Junction = { Model = model, Door = door, OpenCF = openCF, Wire = wire, CutWire = cutWire }
	ctx.Interaction.document(door, "JunctionBox", { Action = "Inspect", Object = "Phone junction box" }, function(player, first)
		if state.LineCut then
			ctx.Director.logTruth("LineCut")
			ctx.Objectives.step("Phone", "Box")
		end
	end)
	local prompt
	prompt = ctx.Interaction.prompt(door, {
		Name = "Splice",
		Action = "Splice the wires",
		Object = "Needs electrical tape",
		Key = Enum.KeyCode.R,
		Hold = ctx.Config.Help.JunctionRepair,
		Distance = 6,
	}, function(player)
		if not state.LineCut or state.LineRepaired then
			ctx.Audio.caption("The line looks fine.", nil, nil, { player })
			return
		end
		if not ctx.Inventory.has(player, "ElectricalTape") then
			ctx.Audio.caption("You need something to join the wires. Electrical tape?", nil, nil, { player })
			return
		end
		state.LineRepaired = true
		wire.Transparency = 0
		cutWire.Transparency = 1
		Escape.refreshLandline()
		ctx.Objectives.step("Phone", "Splice")
		ctx.Audio.caption("You twist the copper together and wrap it tight. The landline should work now.", nil, nil, { player })
		ctx.Remotes.Notify:FireAllClients("The phone line is spliced. Use the kitchen phone!", "objective")
	end)
	prompt.PromptButtonHoldBegan:Connect(function(player)
		prompt.HoldDuration = player:GetAttribute("Role") == "Tinkerer" and ctx.Config.Help.JunctionRepair / 2 or ctx.Config.Help.JunctionRepair
	end)
end

---------------------------------------------------------------------------
-- Breaker panel
---------------------------------------------------------------------------
function Escape.setupBreaker(panel: BasePart, lever: BasePart, onCF: CFrame, offCF: CFrame)
	state.Breaker = { Lever = lever, OnCF = onCF, OffCF = offCF }
	ctx.Interaction.document(panel, "Breaker", { Action = "Inspect", Object = "Breaker panel", Offset = Vector3.new(0, -1, 0) }, function(player, first)
		if not ctx.Power.isOn() then
			ctx.Director.logTruth("PowerOut")
		end
	end)
	ctx.Interaction.prompt(lever, {
		Name = "Main",
		Action = "Flip MAIN breaker",
		Object = "Breaker panel",
		Key = Enum.KeyCode.R,
		Hold = 0.8,
		Distance = 6,
	}, function(player)
		local on = not ctx.Power.isOn()
		ctx.Power.setMain(on, "Player")
		ctx.Audio.playAt("Breaker", lever.Position)
		ctx.Noise.emit(lever.Position, 30, "Breaker", player)
		if on then
			ctx.Objectives.complete("Power")
			ctx.Audio.playAt("PowerUp", lever.Position)
		end
	end)
	ctx.Power.onChanged(function(on)
		lever.CFrame = on and onCF or offCF
	end, lever)
end

---------------------------------------------------------------------------
-- Garage door
---------------------------------------------------------------------------
function Escape.setupGarageDoor(door: BasePart, button: BasePart, cord: BasePart)
	local closedCF = door.CFrame
	local openCF = closedCF * CFrame.new(0, 9.2, 0)
	state.GarageDoor = { Part = door, Closed = closedCF, Open = openCF }
	-- the door and its panel seams move together
	local pieces = { door }
	for _, d in door:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(pieces, d)
		end
	end
	local closedOf = {}
	for _, p in pieces do
		closedOf[p] = p.CFrame
	end
	local function setOpen(open: boolean, time: number)
		state.GarageOpen = open
		if open then
			ctx.Objectives.step("Car", "Garage")
		end
		for _, p in pieces do
			local target = open and (closedOf[p] + Vector3.new(0, 9.2, 0)) or closedOf[p]
			TweenService:Create(p, TweenInfo.new(time, Enum.EasingStyle.Linear), { CFrame = target }):Play()
		end
	end
	ctx.Interaction.prompt(button, {
		Action = "Press",
		Object = "Garage door opener",
		Distance = 6,
	}, function(player)
		if not ctx.Power.isOn() then
			ctx.Audio.caption("Nothing. The opener has no power. (There's a manual release cord on the rail.)", nil, nil, { player })
			return
		end
		setOpen(not state.GarageOpen, 6)
		ctx.Audio.playAt("GarageMotor", door.Position)
		ctx.Noise.emit(door.Position, ctx.Config.Noise.GarageMotor, "Garage", player)
	end)
	ctx.Interaction.prompt(cord, {
		Action = "Pull release & heave",
		Object = "Manual release cord",
		Hold = 4,
		Distance = 9,
	}, function(player)
		if state.GarageOpen then
			return
		end
		setOpen(true, 2.5)
		ctx.Audio.playAt("GarageManual", door.Position)
		ctx.Noise.emit(door.Position, ctx.Config.Noise.GarageRelease, "Garage", player)
	end)
end

function Escape.isGarageOpen(): boolean
	return state.GarageOpen
end

---------------------------------------------------------------------------
-- Car keys: the hook, the nest, the spare
---------------------------------------------------------------------------
function Escape.setupKeyHook(keysPart: BasePart, hookBoard: BasePart)
	state.KeyHook = keysPart
	ctx.Interaction.pickup(keysPart, "CarKeys", { Object = "Car keys (Honda)" })
	-- the board only reads as "empty" once the Honda keys are gone
	state.HookDoc = ctx.Interaction.document(hookBoard, "EmptyHook", { Action = "Look", Object = "Key hooks", Distance = 5 }, function()
		ctx.Director.logTruth("KeysTaken")
	end)
	state.HookDoc.Enabled = false
end

function Escape.setNest(nestFolder: Instance, keysPos: Vector3)
	state.Nest = { Folder = nestFolder, KeysPos = keysPos }
end

-- Curtis takes the car keys (Act III). If a player already holds them, he can't.
function Escape.stealKeys(): boolean
	if state.KeyHook and state.KeyHook.Parent then
		state.KeyHook:Destroy()
		state.KeyHook = nil
		if state.HookDoc then
			state.HookDoc.Enabled = true
		end
		Escape.returnCarKeysToNest()
		return true
	end
	return false
end

function Escape.returnCarKeysToNest()
	if not state.Nest then
		return
	end
	local p = ctx.Builder.block(state.Nest.Folder, "NestCarKeys", state.Nest.KeysPos, Vector3.new(0.8, 0.2, 0.5), Color3.fromRGB(190, 190, 195), Enum.Material.Metal)
	ctx.Interaction.pickup(p, "CarKeys", { Object = "Car keys (Honda)" })
end

---------------------------------------------------------------------------
-- The car
---------------------------------------------------------------------------
function Escape.setupCar(carModel: Model, driverDoor: BasePart, seats: { Seat })
	state.Car = { Model = carModel, Seats = seats }
	ctx.Interaction.prompt(driverDoor, {
		Action = "Drive",
		Object = "Mom's Honda",
		Hold = 1.5,
		Distance = 7,
	}, function(player)
		if not ctx.Inventory.has(player, "CarKeys") then
			ctx.Audio.caption("Locked, and the keys aren't in it. Mom's keys hang on the hook by the back door.", nil, nil, { player })
			return
		end
		local act = ctx.Director.getAct()
		if act ~= "SomeoneElse" and act ~= "Guest" then
			ctx.Audio.caption("You have your learner's permit and a flood warning. Not tonight. Not unless you have to.", nil, nil, { player })
			return
		end
		if not state.GarageOpen then
			ctx.Audio.caption("The garage door is shut. Open it first - the opener needs power, or pull the release cord.", nil, nil, { player })
			return
		end
		Escape.driveAway(player)
	end)
end

function Escape.driveAway(driver: Player)
	local car = state.Car
	if not car or car.Gone then
		return
	end
	car.Gone = true
	ctx.Audio.playAt("CarEngine", car.Model:GetPivot().Position)
	ctx.Noise.emit(car.Model:GetPivot().Position, 120, "Car", driver)

	-- everyone in a seat, plus the driver, plus anyone standing right by the car
	local riders = { driver }
	for _, seat in car.Seats do
		local occ = seat.Occupant
		if occ then
			local p = game:GetService("Players"):GetPlayerFromCharacter(occ.Parent)
			if p and not table.find(riders, p) then
				table.insert(riders, p)
			end
		end
	end
	local carPos = car.Model:GetPivot().Position
	for _, p in ctx.Util.activePlayers() do
		local root = ctx.Util.getRoot(p)
		if root and (root.Position - carPos).Magnitude < 9 and not table.find(riders, p) then
			table.insert(riders, p)
		end
	end
	for _, p in riders do
		local hum = ctx.Util.getHumanoid(p)
		if hum then
			hum.Sit = false
		end
		Escape.markEscaped(p, "Car")
	end

	-- drive out: back down the driveway, then away down the street
	task.wait(1.2)
	local value = Instance.new("CFrameValue")
	local startCF = car.Model:GetPivot()
	value.Value = startCF
	value.Changed:Connect(function(cf)
		car.Model:PivotTo(cf)
	end)
	local mid = startCF * CFrame.new(0, 0, 50)
	local tw = TweenService:Create(value, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = mid })
	tw:Play()
	tw.Completed:Wait()
	local far = CFrame.new(mid.Position + Vector3.new(260, 0, 0)) * CFrame.Angles(0, math.rad(90), 0)
	TweenService:Create(value, TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = far }):Play()

	Escape.callForHelp("Car", driver)
end

---------------------------------------------------------------------------
-- Mrs. Okafor's door
---------------------------------------------------------------------------
function Escape.setupNeighbor(doorPart: BasePart)
	ctx.Interaction.prompt(doorPart, {
		Action = "Knock",
		Object = "Mrs. Okafor's door",
		Hold = 1,
		Distance = 8,
	}, function(player)
		local act = ctx.Director.getAct()
		if act ~= "SomeoneElse" and act ~= "Guest" then
			ctx.Audio.caption("It's late and she's eighty-one. You'd need a real reason to wake her up.", nil, nil, { player })
			return
		end
		if state.Knocking then
			return
		end
		state.Knocking = true
		local pos = doorPart.Position
		ctx.Audio.playAt("Knock", pos)
		ctx.Noise.emit(pos, ctx.Config.Noise.Knock, "Knock", player)
		ctx.Audio.playAt("DogBark", pos + Vector3.new(0, 0, 10))
		if ctx.Intruder then
			ctx.Intruder.onExitAttempt(pos, player)
		end
		local wait = ctx.Config.Help.NeighborWait
		local lines = {
			{ 0.25, "Biscuit goes wild inside. No lights yet." },
			{ 0.55, "A light comes on upstairs." },
			{ 0.85, "Slippers on the stairs. The chain rattles." },
		}
		local t0 = os.clock()
		local nextLine = 1
		local ok = true
		while os.clock() - t0 < wait do
			task.wait(0.25)
			local root = ctx.Util.getRoot(player)
			if not root or player:GetAttribute("Captured") or (root.Position - ctx.Layout.Outside.NeighborPorch).Magnitude > 16 then
				ok = false
				break
			end
			local frac = (os.clock() - t0) / wait
			if lines[nextLine] and frac >= lines[nextLine][1] then
				ctx.Audio.caption(lines[nextLine][2], pos, 30)
				nextLine += 1
			end
		end
		state.Knocking = false
		if not ok then
			ctx.Audio.caption("The porch light clicks off again. She never saw you.", nil, nil, { player })
			return
		end
		ctx.Audio.caption("The door opens. Mrs. Okafor pulls you inside.", pos, 30)
		Escape.markEscaped(player, "Neighbor")
		Escape.callForHelp("Neighbor", player)
	end)
end

---------------------------------------------------------------------------
-- Breakable windows (fire poker)
---------------------------------------------------------------------------
function Escape.setupBreakableWindow(glass: BasePart, op)
	local broken = false
	local inward = op.Axis == "X" and Vector3.new(0, 0, 1) or Vector3.new(1, 0, 0)
	local prompt
	prompt = ctx.Interaction.prompt(glass, {
		Name = "Break",
		Action = "Smash window",
		Object = "Needs something heavy",
		Key = Enum.KeyCode.R,
		Hold = 1.5,
		Distance = 6,
	}, function(player)
		if broken then
			-- climb through to the other side
			local root = ctx.Util.getRoot(player)
			if not root then
				return
			end
			local side = (root.Position - glass.Position):Dot(inward) > 0 and -1 or 1
			local target = glass.Position + inward * side * 3.5
			player.Character:PivotTo(CFrame.new(Vector3.new(target.X, op.Center.Y - op.bottom + 3, target.Z)))
			ctx.Noise.emit(glass.Position, 20, "Glass", player)
			return
		end
		if not ctx.Inventory.has(player, "Poker") then
			ctx.Audio.caption("You'd need something heavy. The fire poker?", nil, nil, { player })
			return
		end
		broken = true
		glass.Transparency = 1
		glass.CanCollide = false
		prompt.ActionText = "Climb through"
		prompt.ObjectText = "Broken window"
		prompt.HoldDuration = 1.2
		ctx.Audio.playAt("GlassBreak", glass.Position)
		ctx.Noise.emit(glass.Position, ctx.Config.Noise.GlassBreak, "Glass", player)
		ctx.PlayerState.scareNear(glass.Position, 60, 4)
	end)
end

return Escape
