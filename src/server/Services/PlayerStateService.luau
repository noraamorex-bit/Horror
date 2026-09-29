--[[
	PlayerStateService — authoritative per-player simulation.

	• movement intents (sprint / crouch) -> WalkSpeed, stamina
	• footstep noise from real velocity
	• nerve (composure) model
	• flashlight (server SpotLight on the head so others see it) + battery
	• cell signal
	• roles and starting items

	Replicated attributes on Player:
		InGame, Role, RoleName, Nerve, Stamina, Crouching, Sprinting, FlashlightOn, Battery,
		Signal, Hiding, Captured, Escaped, HoldingBreath
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerState = {}
local ctx

local intents = {} -- player -> {Sprint, Crouch}
local stepClock = {} -- player -> seconds since last footstep noise
local seenIntruder = {} -- player -> bool (was visible last tick)
local spawnResolver = nil

function PlayerState.init(c)
	ctx = c
end

function PlayerState.setSpawnResolver(fn)
	spawnResolver = fn
end

local function setupCharacter(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	local head = char:WaitForChild("Head") :: BasePart
	hum.BreakJointsOnDeath = false
	hum.WalkSpeed = ctx.Config.Movement.Walk
	hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)

	local light = Instance.new("SpotLight")
	light.Name = "Flashlight"
	light.Range = ctx.Config.Flashlight.Range
	light.Angle = ctx.Config.Flashlight.Angle
	light.Brightness = ctx.Config.Flashlight.Brightness
	light.Color = Color3.fromRGB(255, 244, 222)
	light.Shadows = true
	light.Face = Enum.NormalId.Front
	light.Enabled = player:GetAttribute("FlashlightOn") == true
	light.Parent = head

	if spawnResolver then
		local cf = spawnResolver(player)
		if cf then
			task.defer(function()
				char:PivotTo(cf)
			end)
		end
	end
end

local function onPlayerAdded(player: Player)
	player:SetAttribute("Nerve", ctx.Config.Nerve.Max)
	player:SetAttribute("Stamina", ctx.Config.Movement.StaminaMax)
	player:SetAttribute("Battery", 100)
	player:SetAttribute("Signal", 0)
	intents[player] = { Sprint = false, Crouch = false }
	stepClock[player] = 0
	player.CharacterAdded:Connect(function(char)
		setupCharacter(player, char)
	end)
	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end
end

function PlayerState.resetPlayer(player: Player)
	for _, attr in { "Role", "RoleName", "Crouching", "Sprinting", "FlashlightOn", "Hiding", "Captured", "Escaped", "HoldingBreath", "Fate" } do
		player:SetAttribute(attr, nil)
	end
	player:SetAttribute("Nerve", ctx.Config.Nerve.Max)
	player:SetAttribute("Stamina", ctx.Config.Movement.StaminaMax)
	player:SetAttribute("Battery", 100)
	intents[player] = { Sprint = false, Crouch = false }
	ctx.Inventory.clear(player)
end

function PlayerState.assignRoles(players: { Player })
	local roles = ctx.Story.Roles
	local shuffled = table.clone(players)
	ctx.Util.shuffle(shuffled)
	for i, p in shuffled do
		local role = roles[((i - 1) % #roles) + 1]
		p:SetAttribute("Role", role.Id)
		p:SetAttribute("RoleName", role.Name)
		for item, n in role.Items do
			ctx.Inventory.give(p, item, n)
		end
	end
end

function PlayerState.addNerve(player: Player, delta: number)
	local n = player:GetAttribute("Nerve") or 100
	player:SetAttribute("Nerve", math.clamp(n + delta, 0, ctx.Config.Nerve.Max))
end

function PlayerState.scareNear(position: Vector3, radius: number, amount: number)
	for _, p in ctx.Util.activePlayers() do
		local root = ctx.Util.getRoot(p)
		if root and (root.Position - position).Magnitude <= radius then
			PlayerState.addNerve(p, -amount)
		end
	end
end

function PlayerState.isLit(player: Player): boolean
	if player:GetAttribute("FlashlightOn") then
		return true
	end
	local root = ctx.Util.getRoot(player)
	return root ~= nil and ctx.Power.isLit(root.Position)
end

function PlayerState.setFlashlight(player: Player, on: boolean)
	player:SetAttribute("FlashlightOn", on or nil)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local light = head and head:FindFirstChild("Flashlight")
	if light then
		(light :: SpotLight).Enabled = on
	end
end

-- Freeze / unfreeze movement (hiding, captured, cutscenes)
function PlayerState.setFrozen(player: Player, frozen: boolean)
	local hum = ctx.Util.getHumanoid(player)
	local root = ctx.Util.getRoot(player)
	if hum then
		hum.WalkSpeed = frozen and 0 or ctx.Config.Movement.Walk
		hum.JumpPower = frozen and 0 or 32
	end
	if root then
		root.Anchored = frozen
	end
end

-- neighbours within FriendRadius (active players only)
function PlayerState.friendsNear(player: Player, radius: number?): number
	local root = ctx.Util.getRoot(player)
	if not root then
		return 0
	end
	local r = radius or ctx.Config.Nerve.FriendRadius
	local count = 0
	for _, other in ctx.Util.activePlayers() do
		if other ~= player then
			local oroot = ctx.Util.getRoot(other)
			if oroot and (oroot.Position - root.Position).Magnitude <= r then
				count += 1
			end
		end
	end
	return count
end

local function computeSignal(pos: Vector3): number
	-- The Route 9 tower is down. One flickering bar at the upstairs bathroom window,
	-- two bars far out at the end of the driveway.
	local room = ctx.Rooms.find(pos)
	if room and room.Name == "HallBath" and pos.X > 33 then
		return 1
	end
	if not room and pos.Z < -62 then
		return 2
	end
	return 0
end

local accumulator = 0
local slowAccumulator = 0

local function tick(dt: number)
	local M = ctx.Config.Movement
	for _, player in ctx.Util.sessionPlayers() do
		local hum = ctx.Util.getHumanoid(player)
		local root = ctx.Util.getRoot(player)
		if not hum or not root then
			continue
		end
		if player:GetAttribute("Captured") or player:GetAttribute("Hiding") or player:GetAttribute("Escaped") or root.Anchored then
			continue
		end
		local intent = intents[player] or {}
		local stamina = player:GetAttribute("Stamina") or M.StaminaMax
		local moving = root.AssemblyLinearVelocity.Magnitude > 1.5 and hum.MoveDirection.Magnitude > 0.1
		local crouch = intent.Crouch == true
		local sprint = intent.Sprint == true and not crouch and moving and stamina > 1
		local role = player:GetAttribute("Role")
		local nerve = player:GetAttribute("Nerve") or 100

		if sprint then
			local drain = M.StaminaDrain * (role == "Runner" and M.RunnerDrainMultiplier or 1)
			if nerve < ctx.Config.Nerve.Panic then
				drain *= 1.4
			end
			stamina = math.max(0, stamina - drain * dt)
		else
			stamina = math.min(M.StaminaMax, stamina + M.StaminaRegen * dt * (moving and 0.6 or 1))
		end
		player:SetAttribute("Stamina", stamina)
		player:SetAttribute("Crouching", crouch or nil)
		player:SetAttribute("Sprinting", sprint or nil)

		hum.WalkSpeed = crouch and M.Crouch or (sprint and M.Sprint or M.Walk)

		-- footstep noise
		stepClock[player] = (stepClock[player] or 0) + dt
		if moving and stepClock[player] >= 0.4 then
			stepClock[player] = 0
			local radius = crouch and ctx.Config.Noise.Crouch
				or (sprint and (role == "Runner" and ctx.Config.Noise.RunnerSprint or ctx.Config.Noise.Sprint) or ctx.Config.Noise.Walk)
			ctx.Noise.emit(root.Position, radius, "Footsteps", player)
		end
	end
end

local function slowTick(dt: number)
	local N = ctx.Config.Nerve
	local act = ctx.Director and ctx.Director.getAct() or "Lobby"
	local tense = act ~= "Lobby" and act ~= "Evening"
	for _, player in ctx.Util.sessionPlayers() do
		local root = ctx.Util.getRoot(player)
		if not root then
			continue
		end

		-- flashlight battery
		if player:GetAttribute("FlashlightOn") then
			local b = (player:GetAttribute("Battery") or 0) - dt * (100 / ctx.Config.Flashlight.BatterySeconds)
			player:SetAttribute("Battery", math.max(0, b))
			if b <= 0 then
				PlayerState.setFlashlight(player, false)
				ctx.Audio.caption("The flashlight dies.", nil, nil, { player })
			end
		end

		player:SetAttribute("Signal", computeSignal(root.Position))

		if player:GetAttribute("Escaped") then
			continue
		end

		-- nerve
		local delta = 0
		local friends = PlayerState.friendsNear(player)
		local lit = PlayerState.isLit(player)
		if tense then
			if friends == 0 then
				delta -= lit and N.AloneDrain or N.AloneDarkDrain
			end
		end
		if friends > 0 then
			delta += N.NearFriendsRegen
		end
		if lit then
			delta += N.LitRegen
		end
		if player:GetAttribute("Captured") then
			delta -= 0.3
		end

		-- seeing the intruder
		local sees = ctx.Intruder and ctx.Intruder.isVisibleTo(player) or false
		if sees then
			if not seenIntruder[player] then
				PlayerState.addNerve(player, -N.SeeIntruder)
				ctx.Remotes.Shake:FireClient(player, 0.25, 0.6)
				if ctx.Director then
					ctx.Director.onSighting(player)
				end
			end
			delta -= N.SeeIntruderDrain
		end
		seenIntruder[player] = sees
		player:SetAttribute("SeesIntruder", sees or nil)

		PlayerState.addNerve(player, delta * dt)

		-- panicked breathing is audible
		local nerve = player:GetAttribute("Nerve") or 100
		if nerve < N.Heavy and not player:GetAttribute("HoldingBreath") then
			ctx.Noise.emit(root.Position, N.Heavy - nerve > 20 and ctx.Config.Noise.Breathing * 1.5 or ctx.Config.Noise.Breathing, "Breathing", player)
		end
	end
end

function PlayerState.start()
	for _, p in Players:GetPlayers() do
		onPlayerAdded(p)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(p)
		intents[p] = nil
		stepClock[p] = nil
		seenIntruder[p] = nil
	end)

	ctx.Remotes.Movement.OnServerEvent:Connect(function(player, intent)
		if typeof(intent) ~= "table" then
			return
		end
		intents[player] = { Sprint = intent.Sprint == true, Crouch = intent.Crouch == true }
	end)

	ctx.Remotes.Flashlight.OnServerEvent:Connect(function(player)
		if not player:GetAttribute("InGame") or player:GetAttribute("Captured") then
			return
		end
		if not ctx.Inventory.has(player, "Flashlight") then
			ctx.Audio.caption("You don't have a flashlight.", nil, nil, { player })
			return
		end
		if (player:GetAttribute("Battery") or 0) <= 0 then
			ctx.Audio.caption("Click. Click. The batteries are dead.", nil, nil, { player })
			return
		end
		PlayerState.setFlashlight(player, not player:GetAttribute("FlashlightOn"))
	end)

	ctx.Remotes.UseItem.OnServerEvent:Connect(function(player, item)
		if typeof(item) ~= "string" or not player:GetAttribute("InGame") then
			return
		end
		if player:GetAttribute("Captured") or player:GetAttribute("Hiding") then
			return
		end
		if item == "PepperSpray" and ctx.Inventory.has(player, "PepperSpray") then
			ctx.Intruder.onPepperSpray(player)
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		slowAccumulator += dt
		if accumulator >= 0.1 then
			tick(accumulator)
			accumulator = 0
		end
		if slowAccumulator >= 0.5 then
			slowTick(slowAccumulator)
			slowAccumulator = 0
		end
	end)
end

return PlayerState
