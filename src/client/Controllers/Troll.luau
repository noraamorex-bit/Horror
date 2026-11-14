--[[
	Troll — what the admin panel's trolls do on your own screen (v149, the owner: "Make admin panel
	have 'troll' abilities"). AdminService COMMANDS.troll checks who may do it and fires
	Remotes.Troll(kind, fromName) at the player it's aimed at:
		scare    his face lunging at you (client Prank's scare)
		fling    thrown across the room, tumbling
		launch   shot up in the air
		spin     spun round on the spot
		freeze   an icy screen while the server holds them still for 4 s
		trip     falls flat on their face
		blind    the screen goes black, a heartbeat, a whisper
		whisper  his breath and voice right at your ear: "I can see you."
		steps    his footsteps coming up behind you, then breathing at your neck
		shake    the screen shakes, a low hit
		creak    (with the lights flickering) the house groans
	Each is short and gives your controls back; a small line at the top says who did it, so it never
	reads as a bug. (Tiny / giant, bring / go to, sic him, him behind you and the room scare are the
	server's.)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Troll = {}
local ctx
local player = Players.LocalPlayer
local busy: { [string]: boolean } = {}

local function body(): (Model?, Humanoid?, BasePart?)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not char or not hum or not root then
		return nil, nil, nil
	end
	return char, hum, root
end

local function sound(name: string): Sound?
	local s = ctx.Effects and ctx.Effects.localSound and ctx.Effects.localSound(name)
	if s then
		s:Play()
		Debris:AddItem(s, 10)
	end
	return s
end

-- a sound from a spot in the world (behind you)
local function soundAt(name: string, at: Vector3)
	if ctx.Effects and ctx.Effects.playSound then
		ctx.Effects.playSound(name, at, { Caption = false })
	end
end

local function overlay(): ScreenGui
	return ctx.UI.new("ScreenGui", {
		Name = "Troll",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 61,
		Parent = player:WaitForChild("PlayerGui"),
	})
end

-- who did it: small, top centre, gone in a few seconds
local function banner(text: string)
	local gui = overlay()
	local l = ctx.UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 64),
		Size = UDim2.fromOffset(280, 26),
		Text = text,
		TextSize = 14,
		Font = ctx.UI.Font.Bold,
		TextColor3 = Color3.fromRGB(255, 200, 120),
		BackgroundColor3 = Color3.fromRGB(12, 12, 15),
		BackgroundTransparency = 0.25,
		Parent = gui,
	})
	ctx.UI.corner(l, 8)
	task.delay(3.2, function()
		ctx.UI.tween(l, 0.4, { TextTransparency = 1, BackgroundTransparency = 1 })
		task.delay(0.5, function()
			gui:Destroy()
		end)
	end)
end

-- knocked over for a moment, then back on your feet
local function tumble(hum: Humanoid, seconds: number)
	hum.PlatformStand = true
	task.delay(seconds, function()
		if hum.Parent then
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

local KINDS = {}

KINDS.scare = function(from)
	if ctx.Prank and ctx.Prank.scare then
		ctx.Prank.scare(from, "😈 " .. from .. " jumpscared you!")
		return true -- (the scare has its own line)
	end
	return false
end

KINDS.fling = function(from)
	local _, hum, root = body()
	if not hum or not root then
		return false
	end
	local a = math.random() * math.pi * 2
	tumble(hum, 1.8)
	root.AssemblyLinearVelocity = Vector3.new(math.cos(a) * 75, 55, math.sin(a) * 75)
	root.AssemblyAngularVelocity = Vector3.new(math.random(-12, 12), math.random(-12, 12), math.random(-12, 12))
	sound("HorrorHitLow")
	return false
end

-- (v161) the Slap Glove (a rolled Legendary): sent flying the way the slap went, with a crack
KINDS.slap = function(from, dir)
	local _, hum, root = body()
	if not hum or not root then
		return false
	end
	local d = typeof(dir) == "Vector3" and Vector3.new(dir.X, 0, dir.Z) or Vector3.zero
	if d.Magnitude < 0.01 then
		local a = math.random() * math.pi * 2
		d = Vector3.new(math.cos(a), 0, math.sin(a))
	end
	d = d.Unit
	tumble(hum, 1.6)
	root.AssemblyLinearVelocity = d * 85 + Vector3.new(0, 38, 0)
	root.AssemblyAngularVelocity = Vector3.new(math.random(-14, 14), math.random(-6, 6), math.random(-14, 14))
	sound("Slap")
	if ctx.Effects and ctx.Effects.shake then
		pcall(ctx.Effects.shake, 0.5, 0.3)
	end
	banner("🖐️ slapped by " .. from)
	return true
end

KINDS.launch = function(from)
	local _, hum, root = body()
	if not hum or not root then
		return false
	end
	hum:ChangeState(Enum.HumanoidStateType.Jumping)
	root.AssemblyLinearVelocity = Vector3.new(0, 95, 0)
	return false
end

KINDS.trip = function(from)
	local _, hum, root = body()
	if not hum or not root then
		return false
	end
	tumble(hum, 1.6)
	root.AssemblyLinearVelocity = root.CFrame.LookVector * 14 + Vector3.new(0, 6, 0)
	root.AssemblyAngularVelocity = root.CFrame.RightVector * -9
	return false
end

KINDS.spin = function(from)
	local _, hum, root = body()
	if not hum or not root or busy.spin then
		return false
	end
	busy.spin = true
	local auto = hum.AutoRotate
	hum.AutoRotate = false
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local k = os.clock() - t0
		if k > 3 or not root.Parent or player:GetAttribute("Hiding") or player:GetAttribute("Captured") then
			conn:Disconnect()
			if hum.Parent then
				hum.AutoRotate = auto
			end
			busy.spin = false
			return
		end
		-- (fast, then winding down)
		root.CFrame *= CFrame.Angles(0, dt * 22 * (1 - k / 3.6), 0)
	end)
	return false
end

KINDS.freeze = function(from)
	local _, hum, root = body()
	if not hum or not root or busy.freeze then
		return false
	end
	busy.freeze = true
	local gui = overlay()
	local ice = ctx.UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(160, 215, 255), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = gui })
	-- (the server holds the body still; this is the ice)
	ctx.UI.tween(ice, 0.25, { BackgroundTransparency = 0.72 })
	task.delay(4, function()
		ctx.UI.tween(ice, 0.5, { BackgroundTransparency = 1 })
		task.delay(0.6, function()
			gui:Destroy()
		end)
		busy.freeze = false
	end)
	return false
end

KINDS.blind = function(from)
	if busy.blind then
		return false
	end
	busy.blind = true
	local gui = overlay()
	local black = ctx.UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = gui })
	ctx.UI.tween(black, 0.15, { BackgroundTransparency = 0 })
	local beat = sound("Heartbeat")
	task.delay(1.8, function()
		sound("CreatureWhisper")
	end)
	task.delay(4, function()
		if beat then
			beat:Stop()
		end
		ctx.UI.tween(black, 0.6, { BackgroundTransparency = 1 })
		task.delay(0.7, function()
			gui:Destroy()
		end)
		busy.blind = false
	end)
	return false
end

KINDS.whisper = function(from)
	sound("ManWhisper")
	if ctx.Voices and ctx.Voices.say then
		ctx.Voices.say("I can see you.", "Him", { Channel = "Him", Volume = 0.8 })
	end
	if ctx.Effects then
		ctx.Effects.shake(0.25, 0.6)
	end
	return false
end

KINDS.steps = function(from)
	local _, _, root = body()
	if not root or busy.steps then
		return false
	end
	busy.steps = true
	task.spawn(function()
		-- five heavy steps coming up behind you, then his breath at your neck
		for i = 1, 5 do
			if not root.Parent then
				break
			end
			local back = root.CFrame.LookVector * Vector3.new(1, 0, 1)
			local dist = 14 - i * 2.4
			soundAt(i % 2 == 0 and "FootstepDirt1" or "FootstepDirt2", root.Position - back.Unit * dist)
			task.wait(0.55 - i * 0.04)
		end
		task.wait(0.3)
		sound("Breath2")
		busy.steps = false
	end)
	return false
end

KINDS.shake = function(from)
	if ctx.Effects then
		ctx.Effects.shake(1.4, 2.2)
	end
	sound("HorrorHitLow")
	return false
end

KINDS.creak = function(from)
	sound(math.random() < 0.5 and "HouseCreak1" or "HouseCreak2")
	return false
end

function Troll.init(c)
	ctx = c
	ctx.Troll = Troll
end

function Troll.start()
	ctx.Remotes.Troll.OnClientEvent:Connect(function(kind: string, from: string, extra: any)
		local fn = type(kind) == "string" and KINDS[kind]
		if not fn then
			return
		end
		-- (never over the real ending)
		if workspace:GetAttribute("EndingActive") then
			return
		end
		local name = type(from) == "string" and from or "Someone"
		local ok, own = pcall(fn, name, extra)
		if ok and not own and kind ~= "creak" then
			banner("😈 trolled by " .. name)
		end
	end)
end

Troll._kinds = KINDS -- (tests)

return Troll
