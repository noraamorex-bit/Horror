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

-- The house is built big (13-stud ceilings, counters and cupboards at real proportions), so a
-- default-sized avatar feels like a child in it. Every character is scaled up to a grown-up's
-- height; already-tall avatars are left as they are.
local TARGET_HEIGHT = 6.1

local function normalizeHeight(player: Player, char: Model, hum: Humanoid, head: BasePart)
	if not player:HasAppearanceLoaded() then
		local t0 = os.clock()
		while not player:HasAppearanceLoaded() and os.clock() - t0 < 6 and char.Parent do
			task.wait(0.2)
		end
	end
	local root = hum.RootPart
	if not root or not char.Parent then
		return
	end
	local feet = root.Position.Y - root.Size.Y / 2 - hum.HipHeight
	local height = head.Position.Y + head.Size.Y / 2 - feet
	if height <= 0.5 then
		return
	end
	local factor = math.clamp(TARGET_HEIGHT / height, 1, 1.4)
	if factor > 1.02 then
		pcall(function()
			-- scaling happens about the root, so the feet would sink into the floor: lift the
			-- character by the same amount first
			local rootToFeet = root.Position.Y - feet
			char:PivotTo(char:GetPivot() + Vector3.new(0, rootToFeet * (factor - 1) + 0.05, 0))
			char:ScaleTo(char:GetScale() * factor)
		end)
	end
end

local function setupCharacter(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	local head = char:WaitForChild("Head") :: BasePart
	task.spawn(pcall, normalizeHeight, player, char, hum, head)
	hum.BreakJointsOnDeath = false
	hum.WalkSpeed = ctx.Config.Movement.Walk
	hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)

	local light = Instance.new("SpotLight")
	light.Name = "Flashlight"
	light.Range = ctx.Config.Flashlight.Range
	light.Angle = ctx.Config.Flashlight.Angle
	light.Brightness = ctx.Config.Flashlight.Brightness
	-- the colour you've unlocked by bringing friends (StatsService)
	local function tint()
		local c = player:GetAttribute("StatBeamColor")
		light.Color = typeof(c) == "Color3" and c or Color3.fromRGB(255, 244, 222)
	end
	tint()
	player:GetAttributeChangedSignal("StatBeamColor"):Connect(tint)
	-- no shadows: the head (and hats/hair) would block its own beam. The owner also gets a
	-- sharper local light that follows their camera (client Movement controller).
	light.Shadows = false
	light.Face = Enum.NormalId.Front
	light.Enabled = player:GetAttribute("FlashlightOn") == true
	-- the owning client tilts this attachment with the camera pitch
	local mount = Instance.new("Attachment")
	mount.Name = "FlashlightMount"
	mount.Position = Vector3.new(0.4, -0.2, -0.6)
	mount.Parent = head
	light.Parent = mount

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
	for _, attr in { "Role", "RoleName", "Crouching", "Sprinting", "FlashlightOn", "Hiding", "Captured", "Escaped", "HoldingBreath", "Fate", "HideView", "Calling", "CallProgress", "SeesIntruder", "Breath", "StruggleProgress", "Dead", "WinTime", "NewBest" } do
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
	local chosen: { [Player]: any } = {}
	local taken: { [string]: boolean } = {}
	-- (a late arrival: the roles the others already have are taken)
	for _, other in ctx.Util.sessionPlayers() do
		local held = other:GetAttribute("Role")
		if held and not table.find(players, other) then
			taken[held] = true
		end
	end
	-- the "pick your role" pass: whoever picked one (on the vote screen) gets it, if it's free
	for _, p in shuffled do
		local want = p:GetAttribute("Pass_ChooseRole") and p:GetAttribute("WantRole")
		if want then
			for _, role in roles do
				if role.Id == want and not taken[role.Id] then
					chosen[p] = role
					taken[role.Id] = true
					break
				end
			end
		end
	end
	-- everyone else, in turn, from what's left
	local i = 0
	for _, p in shuffled do
		if not chosen[p] then
			local role
			for _ = 1, #roles do
				i += 1
				local r = roles[((i - 1) % #roles) + 1]
				if not taken[r.Id] then
					role = r
					break
				end
			end
			role = role or roles[((i - 1) % #roles) + 1]
			chosen[p] = role
			taken[role.Id] = true
		end
	end
	for _, p in shuffled do
		local role = chosen[p]
		p:SetAttribute("Role", role.Id)
		p:SetAttribute("RoleName", role.Name)
		for item, n in role.Items do
			ctx.Inventory.give(p, item, n)
		end
		-- the pepper spray pass: a can of your own, one spray
		if p:GetAttribute("Pass_PepperSpray") then
			ctx.Inventory.give(p, "PepperSpray", 1)
		end
		-- the head start pass: a flashlight in your pocket from the first minute
		if p:GetAttribute("Pass_HeadStart") then
			ctx.Inventory.give(p, "Flashlight", 1)
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
	local light = head and head:FindFirstChild("Flashlight", true)
	if light then
		(light :: SpotLight).Enabled = on
	end
end

-- Freeze / unfreeze movement (hiding, captured, cutscenes)
-- Place a character at a spot authored for a default-height body (root 3 studs above the
-- floor): taller (scaled-up) characters are raised so their feet land on the floor, not in it.
function PlayerState.placeStanding(player: Player, cf: CFrame)
	local char = player.Character
	if not char then
		return
	end
	local hum = ctx.Util.getHumanoid(player)
	local root = ctx.Util.getRoot(player)
	local rootHeight = (root and hum) and (root.Size.Y / 2 + hum.HipHeight) or 3
	char:PivotTo(cf + Vector3.new(0, math.max(0, rootHeight - 3), 0))
end

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
			-- (the marathon pass: much slower)
			if player:GetAttribute("Pass_Marathon") then
				drain *= 0.6
			end
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
			-- (the long-life battery pass: twice as long)
			local life = ctx.Config.Flashlight.BatterySeconds * (player:GetAttribute("Pass_Battery") and 2 or 1)
			-- (hard nights: the batteries are older)
			if workspace:GetAttribute("Difficulty") == "Hard" then
				life *= ctx.Config.Difficulty.Hard.BatteryMultiplier
			end
			local b = (player:GetAttribute("Battery") or 0) - dt * (100 / life)
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
		-- him being close, even unseen (outside your hiding spot, behind the wall): your heart
		-- starts pounding
		local ip = ctx.Intruder and ctx.Intruder.position()
		local myRoot = ctx.Util.getRoot(player)
		if ip and myRoot and math.abs(ip.Y - myRoot.Position.Y) < 8 then
			local d = (ip - myRoot.Position).Magnitude
			if d < N.NearIntruderRadius then
				delta -= N.NearIntruderDrain * (1 - d / N.NearIntruderRadius) * 2
			end
		end

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

	-- wedged somewhere: back to the nearest open spot on your floor (not while hidden or tied up)
	local lastUnstuck = {}
	ctx.Remotes.Unstuck.OnServerEvent:Connect(function(player)
		if not player:GetAttribute("InGame") or player:GetAttribute("Hiding") or player:GetAttribute("Captured") or player:GetAttribute("Escaped") then
			return
		end
		if os.clock() - (lastUnstuck[player] or 0) < 15 then
			ctx.Remotes.Notify:FireClient(player, "Give it a moment and try again.", "info")
			return
		end
		local root = ctx.Util.getRoot(player)
		if not root then
			return
		end
		lastUnstuck[player] = os.clock()
		local best, bestD = nil, math.huge
		for _, n in ctx.Layout.Nodes do
			local d = (n.Pos - root.Position).Magnitude + math.abs(n.Pos.Y - root.Position.Y) * 2
			if d > 2 and d < bestD then
				best, bestD = n, d
			end
		end
		if best then
			ctx.Util.unseat(player)
			PlayerState.placeStanding(player, CFrame.new(best.Pos + Vector3.new(0, 0.5, 0)))
		end
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
			ctx.Director.think(player, "I don't have a flashlight. There's one on the mudroom shelf, and one in the den drawer.")
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
