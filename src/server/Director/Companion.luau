--[[
	Companion (v105) — a friend for a night alone.

	The logs: nights alone are abandoned (v104: 13 of 15), and brand-new solo players often left in
	the first seconds of the night; with two the same night is abandoned 21% of the time, with three
	6%. So when a night starts with one player, one friend made it before Creek Road flooded (the
	others turned back): an NPC friend, one of the four (whichever role the player isn't).

	• Before the blackout: they follow you round the house (a step behind, catching up at a run,
	  slipping round a door out of sight if they get stuck), talk in the dialogue box now and then
	  (Story.Companion: arriving, chatter, reactions to the scares), and you can talk to them (a
	  "Talk" prompt). They never do the chores for you.
	• The blackout: they go to flip the breaker in the garage... a scream, and they're gone. Taken.
	• The hunt: they're zip-tied in the boiler room (an optional objective, "Free <name>"). Cut
	  them loose (a hold, and it's loud) and they run next door to Mrs. Okafor's: 35 s later she
	  calls the police (Escape "Companion"). A second way out for someone alone, and a reason to go
	  down there.
	Never on a night that started with two or more. Someone joining later doesn't send them home.
]]

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local Companion = {}
local ctx

local V = Vector3.new
-- (the default R15 animations: idle, walk, run)
local ANIMS = { Idle = "rbxassetid://507766666", Walk = "rbxassetid://507777826", Run = "rbxassetid://507767714" }
local SKIN = Color3.fromRGB(234, 190, 152)
local HOODIE = Color3.fromRGB(47, 125, 224)
local JEANS = Color3.fromRGB(42, 42, 51)
local HAIR = 9243976603 -- Roblox: Short Fringe - Brown
local HEIGHT = 6.1 -- (players are scaled to this: PlayerStateService)
local FOLLOW = 5 -- studs behind you
local GARAGE = V(43.5, 1, -12.7) -- by the breaker panel in the garage
local TIED = CFrame.lookAt(V(-34.5, -13, 28.4), V(-34.5, -13, 18)) -- (boiler room floor, by the far pipes)
local NAMES = { "Riley", "Morgan", "Casey", "Jamie" }

local C: any = nil -- the companion tonight

local function now()
	return os.clock()
end

local function describe(): HumanoidDescription
	local d = Instance.new("HumanoidDescription")
	d.HairAccessory = tostring(HAIR)
	d.HeadColor = SKIN
	d.LeftArmColor = HOODIE
	d.RightArmColor = HOODIE
	d.TorsoColor = HOODIE
	d.LeftLegColor = JEANS
	d.RightLegColor = JEANS
	d.BodyTypeScale = 0
	d.ProportionScale = 0
	return d
end

-- a plain blocky stand-in when the avatar can't be built (it never should; tests use it)
local function standIn(): Model
	local m = Instance.new("Model")
	local function part(name: string, size: Vector3, offset: Vector3, color: Color3)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.CFrame = CFrame.new(offset)
		p.Parent = m
		return p
	end
	local root = part("HumanoidRootPart", V(2, 2, 1), V(0, 3, 0), HOODIE)
	root.Transparency = 1
	part("UpperTorso", V(2, 1.6, 1), V(0, 3.2, 0), HOODIE)
	part("Head", V(1.2, 1.2, 1.2), V(0, 4.6, 0), SKIN)
	local hum = Instance.new("Humanoid")
	hum.HipHeight = 2
	hum.Parent = m
	m.PrimaryPart = root
	return m
end

local function feetOffset(): number
	return C.Hum.HipHeight + C.Root.Size.Y / 2
end

local function placeAt(cf: CFrame)
	C.Model:PivotTo(cf * CFrame.new(0, feetOffset(), 0))
end

local function play(name: string, speed: number?)
	local track = C.Tracks and C.Tracks[name]
	if not track then
		return
	end
	if C.Playing ~= track then
		if C.Playing then
			C.Playing:Stop(0.2)
		end
		track:Play(0.2)
		C.Playing = track
	end
	if speed then
		track:AdjustSpeed(speed)
	end
end

local function build(at: CFrame, name: string): any
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(describe(), Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		model = standIn()
	end
	model.Name = "Companion"
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local head = model:FindFirstChild("Head") :: BasePart
	-- (the same height as the players)
	pcall(function()
		local h = head.Position.Y + head.Size.Y / 2 - (root.Position.Y - root.Size.Y / 2 - hum.HipHeight)
		if h > 1 then
			model:ScaleTo(model:GetScale() * math.clamp(HEIGHT / h, 0.8, 1.4))
		end
	end)
	hum.DisplayName = name
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.NameDisplayDistance = 30
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.WalkSpeed = 10
	pcall(function()
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	end)
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	-- (through the door leaves, like him: a friend wedged behind a door is worse than one who isn't)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			pcall(function()
				d.CollisionGroup = "Intruder"
			end)
			if d ~= root then
				d.CanCollide = false
			end
		end
	end
	local c: any = { Model = model, Hum = hum, Root = root, Head = head, Name = name, Tracks = {} }
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	for k, id in ANIMS do
		pcall(function()
			local a = Instance.new("Animation")
			a.AnimationId = id
			c.Tracks[k] = (animator :: Animator):LoadAnimation(a)
			c.Tracks[k].Looped = true
		end)
	end
	C = c
	placeAt(at)
	model.Parent = workspace
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	return c
end

local function line(text: string, audience: { Player }?)
	if not C or not ctx.Dialogue then
		return false
	end
	return ctx.Dialogue.say({ { Speaker = { Name = C.Name }, Text = text } }, audience or ctx.Util.sessionPlayers())
end

-- say it if nothing else is being said; otherwise skip it (one message at a time)
local function sayLater(text: string, delay: number?)
	local me = C
	task.delay(delay or 0, function()
		if C == me and me.Mode == "Follow" and not (ctx.Dialogue and ctx.Dialogue.isActive()) then
			line(text)
		end
	end)
end

local function friendOf(): Player?
	local p = C and C.Player
	if p and p.Parent and p:GetAttribute("InGame") then
		return p
	end
	for _, q in ctx.Util.sessionPlayers() do
		return q
	end
	return nil
end

-- can the player see this point? (so they never watch their friend pop from one place to another)
local function seenBy(p: Player, at: Vector3): boolean
	local head = p.Character and p.Character:FindFirstChild("Head") :: BasePart?
	if not head then
		return false
	end
	local to = at - head.Position
	if to.Magnitude > 80 or head.CFrame.LookVector:Dot(to.Unit) < 0.2 then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { p.Character :: Instance, C.Model }
	return workspace:Raycast(head.Position, to, params) == nil
end

-- the spot a step behind them (and a little to the side)
local function behind(r: BasePart): Vector3
	local look = r.CFrame.LookVector
	local flat = V(look.X, 0, look.Z)
	flat = flat.Magnitude > 0.1 and flat.Unit or V(0, 0, -1)
	local side = V(-flat.Z, 0, flat.X)
	return r.Position - flat * FOLLOW + side * 1.5
end

local function straightClear(from: Vector3, to: Vector3): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { C.Model }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	return math.abs(from.Y - to.Y) < 3 and workspace:Raycast(from, to - from, params) == nil
end

-- one step of walking somewhere: straight when the way is clear, else along a computed path
local function walkTowards(goal: Vector3, speed: number)
	local root = C.Root
	C.Hum.WalkSpeed = speed
	if straightClear(root.Position, goal) then
		C.Path = nil
		C.Hum:MoveTo(goal)
		return
	end
	if not C.Path or now() - (C.PathAt or 0) > 1.2 or (C.PathGoal - goal).Magnitude > 6 then
		C.PathAt = now()
		C.PathGoal = goal
		local path = PathfindingService:CreatePath({ AgentRadius = 1.4, AgentHeight = 5.5, AgentCanJump = false })
		local ok = pcall(function()
			path:ComputeAsync(root.Position, goal)
		end)
		if ok and path.Status == Enum.PathStatus.Success then
			C.Path = path:GetWaypoints()
			C.PathIndex = 2
		else
			C.Path = nil
		end
	end
	local wps = C.Path
	if wps and wps[C.PathIndex] then
		local wp = wps[C.PathIndex].Position
		if (V(wp.X, 0, wp.Z) - V(root.Position.X, 0, root.Position.Z)).Magnitude < 2 then
			C.PathIndex += 1
			wp = wps[C.PathIndex] and wps[C.PathIndex].Position or goal
		end
		C.Hum:MoveTo(wp)
	else
		C.Hum:MoveTo(goal)
	end
end

-- following: a step behind, a run to catch up, and out of sight round a corner if they lose you
local function follow(dt: number)
	local p = friendOf()
	local r = p and ctx.Util.getRoot(p)
	if not p or not r or p:GetAttribute("Hiding") then
		C.Hum:MoveTo(C.Root.Position)
		play("Idle")
		return
	end
	local root = C.Root
	local gap = (r.Position - root.Position).Magnitude
	local moved = (root.Position - (C.LastPos or root.Position)).Magnitude
	C.LastPos = root.Position
	if gap > FOLLOW + 2.5 then
		C.Stuck = (moved < 0.15 * dt * 30) and (C.Stuck or 0) + dt or 0
		-- lost (on another floor, behind a door, wedged): catch up out of their sight
		if gap > 60 or (C.Stuck or 0) > 3 then
			local spot = behind(r)
			if not seenBy(p, spot + V(0, 2, 0)) then
				placeAt(CFrame.lookAt(spot - V(0, 3, 0), V(r.Position.X, spot.Y - 3, r.Position.Z)))
				C.Stuck = 0
				C.Path = nil
				return
			end
		end
		local speed = gap > 16 and 17 or 10
		walkTowards(behind(r), speed)
		play(speed > 12 and "Run" or "Walk")
	else
		C.Stuck = 0
		C.Hum:MoveTo(root.Position)
		play("Idle")
		-- (face them, or where they're looking)
		local flat = V(r.Position.X - root.Position.X, 0, r.Position.Z - root.Position.Z)
		if flat.Magnitude > 0.5 then
			root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, root.Position + flat.Unit), math.min(1, dt * 4))
		end
	end
end

local function tie()
	C.Mode = "Tied"
	C.Hum:MoveTo(C.Root.Position)
	if C.Playing then
		C.Playing:Stop(0.1)
		C.Playing = nil
	end
	placeAt(TIED)
	C.Root.Anchored = true
	-- arms behind the back, head down
	for _, name in { "RightShoulder", "LeftShoulder" } do
		local j = C.Model:FindFirstChild(name, true)
		if j and j:IsA("Motor6D") then
			j.C0 = j.C0 * CFrame.Angles(math.rad(30), 0, name == "RightShoulder" and math.rad(-25) or math.rad(25))
		end
	end
	local neck = C.Model:FindFirstChild("Neck", true)
	if neck and neck:IsA("Motor6D") then
		neck.C0 = neck.C0 * CFrame.Angles(math.rad(-25), 0, 0)
	end
	local torso = C.Model:FindFirstChild("UpperTorso") or C.Root
	C.Prompt = ctx.Interaction.prompt(torso, { Name = "FreeCompanion", Action = "Cut loose", Object = C.Name, Hold = 3, Distance = 7 }, function(player)
		Companion.free(player)
	end)
end

-- the blackout: they go to flip the breaker... and he takes them
function Companion.blackout()
	if not C or C.Mode ~= "Follow" then
		return
	end
	C.Mode = "Breaker"
	local me = C
	if me.TalkPrompt then
		me.TalkPrompt:Destroy()
		me.TalkPrompt = nil
	end
	task.spawn(function()
		local S = ctx.Story.Companion
		-- (they talk over whatever's on screen: this is the moment)
		if ctx.Dialogue and not ctx.Dialogue.isActive() then
			task.spawn(line, S.Breaker)
		end
		local t0 = now()
		local outOfSight = nil
		while C == me and me.Mode == "Breaker" do
			local p = friendOf()
			walkTowards(GARAGE + V(0, 3, 0), 10)
			play("Walk")
			local seen = p ~= nil and seenBy(p, me.Root.Position + V(0, 2, 0))
			if seen then
				outOfSight = nil
			else
				outOfSight = outOfSight or now()
			end
			local there = (V(me.Root.Position.X, 0, me.Root.Position.Z) - V(GARAGE.X, 0, GARAGE.Z)).Magnitude < 5
			-- (round a corner and out of sight for a moment, or at the panel, or it's taking too long)
			if (outOfSight and now() - outOfSight > 2.5 and now() - t0 > 5) or there or now() - t0 > 20 then
				break
			end
			task.wait(0.2)
		end
		if C ~= me then
			return
		end
		-- the scream
		local at = me.Root.Position
		ctx.Audio.playAt("MuffledScream", at, { Volume = 1, Pitch = 1.15, CaptionText = "[" .. string.upper(me.Name) .. " SCREAMS]", CaptionRange = 400 })
		ctx.Audio.playAt("BodyFall", at, { Caption = false })
		ctx.Audio.playAt("DoorSlam", at, { Caption = false })
		for _, p in ctx.Util.sessionPlayers() do
			ctx.Remotes.Shake:FireClient(p, 0.7, 0.6)
		end
		tie()
		if ctx.Journey then
			for _, p in ctx.Util.sessionPlayers() do
				ctx.Journey.event(p, "Mate", "Taken")
			end
		end
		task.wait(2.5)
		if C == me and ctx.Director then
			ctx.Director.think(nil, string.format(ctx.Story.Companion.Taken, me.Name) .. "|danger")
		end
		task.wait(5)
		if C == me and me.Mode == "Tied" and ctx.Objectives then
			ctx.Objectives.add("FreeCompanion", true)
			if ctx.Director then
				ctx.Director.think(nil, string.format(ctx.Story.Companion.Below, me.Name))
			end
		end
	end)
end

-- cut loose: they run next door, and Mrs. Okafor calls the police
function Companion.free(by: Player?)
	if not C or C.Mode ~= "Tied" then
		return
	end
	local me = C
	me.Mode = "Fleeing"
	if me.Prompt then
		me.Prompt:Destroy()
		me.Prompt = nil
	end
	me.Root.Anchored = false
	ctx.Audio.playAt("ScissorsSnip", me.Root.Position, { Caption = false })
	if ctx.Noise then
		ctx.Noise.emit(me.Root.Position, ctx.Config.Intruder.RescueNoise or 45, "Rescue", by)
	end
	if ctx.Objectives then
		ctx.Objectives.complete("FreeCompanion")
	end
	if ctx.Journey and by then
		ctx.Journey.event(by, "Mate", "Freed")
	end
	task.spawn(function()
		line(ctx.Story.Companion.Freed, by and { by } or nil)
		-- off up the basement stairs and out of sight, then gone
		local t0 = now()
		while C == me and now() - t0 < 6 do
			walkTowards(V(3, -10, 5), 17)
			play("Run")
			task.wait(0.2)
		end
		if C == me then
			me.Model.Parent = nil
			me.Mode = "Gone"
		end
		task.wait(35)
		if C == me and ctx.Escape and not ctx.Escape.helpCalled() then
			ctx.Escape.callForHelp("Companion", by)
			if ctx.Director then
				ctx.Director.think(nil, string.format(ctx.Story.Companion.Help, me.Name))
			end
		end
	end)
end

-- a night started with one player: a friend made it
function Companion.begin(player: Player)
	Companion.stop()
	local root = ctx.Util.getRoot(player)
	if not root then
		return
	end
	local mine = string.split(tostring(player:GetAttribute("RoleName") or ""), " ")[1]
	local name = NAMES[1]
	for _, n in NAMES do
		if n ~= mine then
			name = n
			break
		end
	end
	local spot = behind(root)
	build(CFrame.lookAt(spot - V(0, 3, 0), V(root.Position.X, spot.Y - 3, root.Position.Z)), name)
	C.Player = player
	C.Mode = "Follow"
	C.Said = {}
	C.Started = now()
	-- (talk to them)
	local torso = C.Model:FindFirstChild("UpperTorso") or C.Root
	C.TalkPrompt = ctx.Interaction.prompt(torso, { Name = "TalkCompanion", Action = "Talk", Object = name, Distance = 8 }, function(p)
		Companion.talk(p)
	end)
	sayLater(ctx.Story.Companion.Arrive, 7)
	local me = C
	task.spawn(function()
		local last = now()
		while C == me and me.Model.Parent do
			local t = now()
			local dt = t - last
			last = t
			if me.Mode == "Follow" then
				local ok, err = pcall(follow, dt)
				if not ok then
					warn("[Companion] " .. tostring(err))
				end
			end
			task.wait(0.15)
		end
	end)
end

-- a "Talk" with them: a line for where the night is
function Companion.talk(p: Player)
	if not C or C.Mode ~= "Follow" or (ctx.Dialogue and ctx.Dialogue.isActive()) then
		return
	end
	local act = workspace:GetAttribute("Act") or "Evening"
	local pool = ctx.Story.Companion.Talk[act] or ctx.Story.Companion.Talk.Evening
	C.TalkN = (C.TalkN or 0) + 1
	task.spawn(line, pool[(C.TalkN - 1) % #pool + 1], { p })
end

-- every so often in the build-up: something to say (Director, while it's quiet)
function Companion.chatter(act: string, actTime: number)
	if not C or C.Mode ~= "Follow" then
		return
	end
	for i, l in ctx.Story.Companion.Chatter[act] or {} do
		local key = act .. i
		if not C.Said[key] and actTime >= l.At then
			C.Said[key] = true
			if not (ctx.Dialogue and ctx.Dialogue.isActive()) then
				task.spawn(line, l.Text)
			end
			return
		end
	end
end

-- a scare: they react out loud (once per kind of scare)
function Companion.react(id: string)
	local text = C and C.Mode == "Follow" and ctx.Story.Companion.React[id]
	if not text or C.Said["React" .. id] then
		return
	end
	C.Said["React" .. id] = true
	sayLater(text, 1.2)
end

function Companion.active(): boolean
	return C ~= nil and C.Model.Parent ~= nil
end

function Companion.mode(): string?
	return C and C.Mode or nil
end

function Companion.name(): string?
	return C and C.Name or nil
end

function Companion.model(): Model?
	return C and C.Model or nil
end

function Companion.stop()
	if C then
		pcall(function()
			C.Model:Destroy()
		end)
	end
	C = nil
end

function Companion.init(c)
	ctx = c
	ctx.Companion = Companion
end

return Companion
