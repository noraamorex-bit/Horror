--[[
	Intruder — Curtis Vane. A state machine with perception (see GDD §4).

	Modes (set by the Director): Offstage (acts I-II), Lurk (act III), Hunt (act IV).
	States: Offstage, Lurk, Patrol, Investigate, Stalk, Chase, Search, CheckSpot,
	        Retreat, Stunned, Frantic, Trapped, Gone, Stopped.

	The one rule that makes "together is safe" work: he will not grab a player in front of
	Config.Intruder.GroupWitnesses (or more) alert, lit witnesses.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Perception = require(script.Parent.Perception)
local Navigator = require(script.Parent.Navigator)

local Intruder = {}
local ctx

local V = Vector3.new
local OFFSTAGE = CFrame.new(220, -40, 220)
local ANIMS = {
	Idle = "rbxassetid://507766388",
	Walk = "rbxassetid://507777826",
	Run = "rbxassetid://507767714",
}

local S: any = {}
local STATES: { [string]: (number, { Player }) -> () } = {}

local function fresh()
	return {
		Mode = "Offstage",
		State = "Offstage",
		Data = {},
		StateStart = os.clock(),
		Model = nil,
		Humanoid = nil,
		Root = nil,
		Head = nil,
		Nav = nil,
		InHouse = false,
		Entering = false,
		Memory = {},
		SawHide = {},
		Noises = {},
		Visible = {},
		LastCaptiveCheck = os.clock(),
		ChaseCooldownUntil = 0,
		Tracks = {},
		CurrentTrack = nil,
		StepClock = 0,
		CaptionClock = 0,
	}
end

function Intruder.init(c)
	ctx = c
	Perception.init(c)
	S = fresh()
end

---------------------------------------------------------------------------
-- The rig
---------------------------------------------------------------------------
local function blockRig(): Model
	local B = ctx.Builder
	local model = Instance.new("Model")
	local jacket, jeans, skin = Color3.fromRGB(62, 60, 50), Color3.fromRGB(45, 50, 60), Color3.fromRGB(196, 160, 130)
	local root = B.part(model, { Name = "HumanoidRootPart", Size = V(2, 2, 1), Transparency = 1, Anchored = false, CanCollide = false })
	local torso = B.part(model, { Name = "Torso", Size = V(2, 2, 1), Color = jacket, Anchored = false })
	local head = B.part(model, { Name = "Head", Size = V(1.2, 1.2, 1.2), Color = skin, Anchored = false })
	local parts = {
		{ torso, CFrame.new() },
		{ head, CFrame.new(0, 1.6, 0) },
		{ B.part(model, { Name = "Left Arm", Size = V(1, 2, 1), Color = jacket, Anchored = false }), CFrame.new(-1.5, 0, 0) },
		{ B.part(model, { Name = "Right Arm", Size = V(1, 2, 1), Color = jacket, Anchored = false }), CFrame.new(1.5, 0, 0) },
		{ B.part(model, { Name = "Left Leg", Size = V(1, 2, 1), Color = jeans, Anchored = false }), CFrame.new(-0.5, -2, 0) },
		{ B.part(model, { Name = "Right Leg", Size = V(1, 2, 1), Color = jeans, Anchored = false }), CFrame.new(0.5, -2, 0) },
	}
	for _, entry in parts do
		entry[1].CFrame = root.CFrame * entry[2]
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = entry[1]
		w.Parent = entry[1]
	end
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R6
	hum.HipHeight = 0
	hum.Parent = model
	model.PrimaryPart = root
	return model
end

-- Curtis as a Roblox avatar: a stitched burlap sack over his head (UGC "Stitched Burlap Horror
-- Mask" by BloodWarrior08; a dark knit beanie if it can't load), the blank "Stare" head underneath, a black jacket and black jeans (Roblox classic clothing), big and tall. Every catalog
-- piece is optional: if the head can't load he keeps the classic head, and if the avatar can't
-- be built at all the block rig stands in.
local CURTIS = {
	Head = 13692947484, -- Roblox: Stare - Head
	Shirt = 382538295, -- Roblox: Guitar Tee with Black Jacket
	Pants = 382537569, -- Roblox: Black Jeans
	Mask = 127512374310237, -- UGC (BloodWarrior08): Stitched Burlap Horror Mask
}
local function curtisDescription(withHead: boolean)
	local desc = Instance.new("HumanoidDescription")
	local skin = Color3.fromRGB(196, 160, 130)
	if withHead then
		desc.Head = CURTIS.Head
	end
	desc.HatAccessory = tostring(CURTIS.Mask)
	desc.Shirt = CURTIS.Shirt
	desc.Pants = CURTIS.Pants
	desc.HeadColor = skin
	desc.LeftArmColor = skin
	desc.RightArmColor = skin
	desc.TorsoColor = Color3.fromRGB(40, 40, 44)
	desc.LeftLegColor = Color3.fromRGB(34, 34, 38)
	desc.RightLegColor = Color3.fromRGB(34, 34, 38)
	desc.HeightScale = 1.12
	desc.WidthScale = 1.08
	desc.DepthScale = 1.02
	desc.BodyTypeScale = 0
	desc.ProportionScale = 0
	return desc
end

local function buildRig(): Model
	local ok, result = pcall(function()
		return Players:CreateHumanoidModelFromDescription(curtisDescription(true), Enum.HumanoidRigType.R15)
	end)
	if not ok then
		ok, result = pcall(function()
			return Players:CreateHumanoidModelFromDescription(curtisDescription(false), Enum.HumanoidRigType.R15)
		end)
	end
	local model = (ok and result) or blockRig()
	model.Name = "Curtis"
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.NameDisplayDistance = 0
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.BreakJointsOnDeath = false
	hum.MaxHealth = 1e9
	hum.Health = 1e9
	hum.WalkSpeed = ctx.Config.Intruder.WalkSpeed
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	local head = model:FindFirstChild("Head") :: BasePart
	if head and not model:FindFirstChildOfClass("Accessory") then
		-- no mask loaded: a dark knit beanie pulled low: a rounded crown and a folded cuff
		local hs = head.Size
		local function knit(name: string, size: Vector3, offset: CFrame, mesh: Enum.MeshType?)
			local p = ctx.Builder.part(model, {
				Name = name,
				Size = size,
				CFrame = head.CFrame * offset,
				Color = Color3.fromRGB(32, 32, 36),
				Material = Enum.Material.Fabric,
				Anchored = false,
				CanCollide = false,
				CanQuery = false,
				Massless = true,
			})
			if mesh then
				local m = Instance.new("SpecialMesh")
				m.MeshType = mesh
				m.Parent = p
			end
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = head
			weld.Part1 = p
			weld.Parent = p
			return p
		end
		knit("Cap", Vector3.new(hs.X * 1.1, hs.Y * 0.7, hs.Z * 1.1), CFrame.new(0, hs.Y * 0.38, 0), Enum.MeshType.Sphere)
		local cuff = knit("CapCuff", Vector3.new(hs.Y * 0.2, hs.X * 1.14, hs.Z * 1.14), CFrame.new(0, hs.Y * 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2), nil)
		cuff.Shape = Enum.PartType.Cylinder
	end
	return model
end

local function loadAnims()
	local hum = S.Humanoid :: Humanoid
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = hum
	if hum.RigType ~= Enum.HumanoidRigType.R15 then
		return
	end
	for name, id in ANIMS do
		local ok, track = pcall(function()
			local a = Instance.new("Animation")
			a.AnimationId = id
			return (animator :: Animator):LoadAnimation(a)
		end)
		if ok and track then
			track.Looped = true
			S.Tracks[name] = track
		end
	end
end

local function playTrack(name: string, speed: number?)
	local track = S.Tracks[name]
	if not track then
		return
	end
	if S.CurrentTrack ~= track then
		if S.CurrentTrack then
			S.CurrentTrack:Stop(0.25)
		end
		track:Play(0.25)
		S.CurrentTrack = track
	end
	if speed then
		track:AdjustSpeed(speed)
	end
end

local function ensureModel()
	if S.Model and S.Model.Parent then
		return
	end
	local model = buildRig()
	model:PivotTo(OFFSTAGE)
	model.Parent = ctx.World.folder()
	S.Model = model
	S.Humanoid = model:FindFirstChildOfClass("Humanoid")
	S.Root = model:FindFirstChild("HumanoidRootPart")
	S.Head = model:FindFirstChild("Head")
	S.Root.Anchored = true
	S.Nav = Navigator.new(ctx, S.Humanoid, S.Root)
	S.Tracks = {}
	S.CurrentTrack = nil
	loadAnims()
end

local function setState(name: string, data: any?)
	S.State = name
	S.Data = data or {}
	S.StateStart = os.clock()
	workspace:SetAttribute("IntruderState", name)
	if ctx.Config.Debug then
		print("[Intruder] -> " .. name)
	end
end

local function park()
	if S.Model then
		S.Nav:stop()
		S.Root.Anchored = true
		S.Model:PivotTo(OFFSTAGE)
	end
	S.InHouse = false
end

local function placeAt(pos: Vector3, look: Vector3?)
	ensureModel()
	S.Root.Anchored = false
	S.Model:PivotTo(CFrame.lookAt(pos, look or (pos + V(0, 0, -1))))
	pcall(function()
		S.Root:SetNetworkOwner(nil)
	end)
	S.InHouse = true
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function now()
	return os.clock()
end

local function pos(): Vector3
	return S.Root.Position
end

local function rootOf(p: Player): BasePart?
	return ctx.Util.getRoot(p)
end

local function valid(p: Player?): boolean
	return p ~= nil and p.Parent ~= nil and p:GetAttribute("InGame") == true and not p:GetAttribute("Captured")
		and not p:GetAttribute("Escaped") and ctx.Util.isAlive(p)
end

local function faceToward(target: Vector3)
	local p = pos()
	local flat = V(target.X, p.Y, target.Z)
	if (flat - p).Magnitude > 0.1 then
		S.Root.CFrame = CFrame.lookAt(p, flat)
	end
end

local function observers(): { Player }
	local list = {}
	for _, p in ctx.Util.sessionPlayers() do
		if not p:GetAttribute("Escaped") and Perception.playerSees(p, S.Head.Position, S.Model) then
			table.insert(list, p)
		end
	end
	return list
end

-- Attic targets can't be walked to; aim for the landing under the hatch instead.
local function reachable(p: Vector3): Vector3
	if ctx.Rooms.floorOf(p) == "Attic" then
		local h = ctx.Layout.AtticHatch
		return V((h.x0 + h.x1) / 2 - 3, 18, (h.z0 + h.z1) / 2)
	end
	return p
end

local function nodes(filter: ((any) -> boolean)?)
	local out = {}
	for _, n in ctx.Layout.Nodes do
		if not filter or filter(n) then
			table.insert(out, n)
		end
	end
	return out
end

local function minPlayerDistance(p: Vector3): number
	local best = math.huge
	for _, pl in ctx.Util.activePlayers() do
		local r = rootOf(pl)
		if r then
			best = math.min(best, (r.Position - p).Magnitude)
		end
	end
	return best
end

-- the shadow node that is farthest from everyone (at least minDist away if possible)
local function farNode(): Vector3
	local best, bestD = nil, -1
	for _, n in nodes(function(n)
		return n.Shadow
	end) do
		local d = minPlayerDistance(n.Pos)
		if d > bestD then
			best, bestD = n, d
		end
	end
	return best and best.Pos or ctx.Layout.Attic.GarageHatchBelow
end

local function friendsNear(target: Player, radius: number, needLit: boolean): number
	local tr = rootOf(target)
	if not tr then
		return 0
	end
	local count = 0
	for _, p in ctx.Util.activePlayers() do
		if p ~= target and not p:GetAttribute("Hiding") then
			local r = rootOf(p)
			if r and (r.Position - tr.Position).Magnitude <= radius and (not needLit or ctx.PlayerState.isLit(p)) then
				count += 1
			end
		end
	end
	return count
end

-- alert, lit witnesses who can see him right now
local function witnesses(target: Player): number
	local count = 0
	for _, p in ctx.Util.activePlayers() do
		if p ~= target and not p:GetAttribute("Hiding") then
			local r = rootOf(p)
			if r and (r.Position - pos()).Magnitude <= 45 and ctx.PlayerState.isLit(p) and Perception.playerSees(p, S.Head.Position, S.Model) then
				count += 1
			end
		end
	end
	return count
end

local function pickTarget(visible: { Player }): Player?
	local best, bestScore = nil, -math.huge
	for _, p in visible do
		local r = rootOf(p)
		if r then
			local score = -(r.Position - pos()).Magnitude
			if ctx.PlayerState.friendsNear(p) == 0 then
				score += 40
			end
			score += (100 - (p:GetAttribute("Nerve") or 100)) * 0.2
			if score > bestScore then
				best, bestScore = p, score
			end
		end
	end
	return best
end

local function follow(target: Vector3, speed: number)
	local d = S.Data
	local p = pos()
	local sameFloor = math.abs(target.Y - p.Y) < 5
	if sameFloor and (target - p).Magnitude < 30 and Perception.clear(S.Head.Position, target + V(0, 1, 0), { S.Model }, nil) then
		S.Nav:moveDirect(target, speed)
		d.PathGoal = nil
		return
	end
	if not d.PathGoal or now() - (d.LastPath or 0) > 1.5 or (d.PathGoal - target).Magnitude > 8 then
		d.PathGoal = target
		d.LastPath = now()
		S.Nav:goTo(reachable(target), { Speed = speed, Tolerance = 2, Hurry = speed > 12 })
	else
		S.Humanoid.WalkSpeed = speed
	end
end

local function retreat(from: Vector3?, duration: number?, goal: Vector3?)
	setState("Retreat", { Goal = goal or farNode(), Duration = duration or 20, From = from })
	S.Nav:goTo(S.Data.Goal, { Speed = 12, Tolerance = 3, Hurry = true })
end

local function tryGrab(target: Player): boolean
	local r = rootOf(target)
	if not r or (r.Position - pos()).Magnitude > ctx.Config.Intruder.GrabRange then
		return false
	end
	if witnesses(target) >= ctx.Config.Intruder.GroupWitnesses then
		ctx.Audio.caption("He stops dead. Too many of you are watching.", pos(), 40)
		retreat(r.Position, 25)
		return true
	end
	if ctx.Capture.capture(target) then
		S.Memory[target] = nil
		local boiler = ctx.Rooms.ByName.Boiler
		retreat(nil, ctx.Config.Intruder.RetreatAfterCapture, boiler and V(boiler.Center.X, -10, boiler.Center.Z) or nil)
		return true
	end
	return false
end

local function engage(visible: { Player }): boolean
	if #visible == 0 then
		return false
	end
	local target = pickTarget(visible)
	if not target then
		return false
	end
	local tr = rootOf(target) :: BasePart
	-- a lit group: back off
	if ctx.PlayerState.isLit(target) and friendsNear(target, 25, true) >= ctx.Config.Intruder.GroupWitnesses then
		retreat(tr.Position, 20)
		return true
	end
	if Perception.playerSees(target, S.Head.Position, S.Model) and now() >= S.ChaseCooldownUntil then
		setState("Chase", { Target = target, LastSeen = now() })
		ctx.Director.addTension(20)
		ctx.Remotes.Shake:FireClient(target, 0.4, 0.6)
		ctx.Audio.caption("[Heavy footsteps - coming fast]", pos(), 60)
	else
		setState("Stalk", { Target = target, LastSeen = now() })
	end
	return true
end

local function spotNear(p: Vector3, radius: number)
	local spots = ctx.Hiding.spotsNear(p, radius)
	-- spots he saw someone use come first
	for _, s in spots do
		if S.SawHide[s] then
			return s
		end
	end
	return ctx.Util.choice(spots)
end

local function checkSpot(spot, returnState: string, returnData: any?)
	setState("CheckSpot", { Spot = spot, Return = returnState, ReturnData = returnData, Phase = "Approach" })
	S.Nav:goTo(spot.Exit.Position, { Speed = ctx.Config.Intruder.WalkSpeed + 1, Tolerance = 2.5 })
end

local function pickPatrolGoal(): Vector3
	local entries = {}
	local p = pos()
	for _, n in ctx.Layout.Nodes do
		if (n.Pos - p).Magnitude < 12 then
			continue
		end
		local w = 1
		if n.Shadow then
			w += 0.5
		end
		for _, ev in S.Noises do
			if now() - ev.Time < 60 and (ev.Position - n.Pos).Magnitude < 25 then
				w += 3
			end
		end
		for _, m in S.Memory do
			if now() - m.Time < 90 and (m.Pos - n.Pos).Magnitude < 25 then
				w += 3
			end
		end
		table.insert(entries, { n.Pos, w })
	end
	return ctx.Util.weighted(entries) or p
end

local function startPatrol()
	setState("Patrol", {})
	local boiler = ctx.Rooms.ByName.Boiler
	if ctx.Capture.captiveCount() > 0 and now() - S.LastCaptiveCheck > ctx.Config.Intruder.CaptiveCheckInterval and boiler then
		S.LastCaptiveCheck = now()
		S.Nav:goTo(V(boiler.Center.X + 4, -10, boiler.Center.Z), { Speed = ctx.Config.Intruder.WalkSpeed })
		return
	end
	S.Nav:goTo(pickPatrolGoal(), { Speed = ctx.Config.Intruder.WalkSpeed })
end

local function resume()
	if S.Mode == "Lurk" then
		setState("Lurk", { Phase = "Pick" })
	else
		startPatrol()
	end
end

---------------------------------------------------------------------------
-- States
---------------------------------------------------------------------------
STATES.Lurk = function(_, _visible)
	local d = S.Data
	local I = ctx.Config.Intruder
	local obs = observers()
	if #obs > 0 and d.Phase ~= "Flee" then
		if d.Phase ~= "Freeze" then
			d.Phase = "Freeze"
			d.Until = now() + 1 + math.random() * 1.2
			S.Nav:stop()
			local r = rootOf(obs[1])
			if r then
				faceToward(r.Position)
			end
		end
		if now() >= d.Until then
			d.Phase = "Flee"
			S.Nav:goTo(farNode(), { Speed = 11, Tolerance = 3, Hurry = true })
		end
		return
	end
	if d.Phase == "Freeze" or minPlayerDistance(pos()) < 6 then
		d.Phase = "Flee"
		S.Nav:goTo(farNode(), { Speed = 11, Tolerance = 3, Hurry = true })
		return
	end
	if d.Phase == "Flee" then
		if S.Nav.Arrived or now() - S.StateStart > 25 then
			d.Phase = "Wait"
			d.Until = now() + 4 + math.random() * 5
		end
		return
	end
	if d.Phase == "Move" then
		if S.Nav.Arrived then
			if d.Peek then
				d.Phase = "Peek"
				d.Until = now() + 7
			else
				d.Phase = "Wait"
				d.Until = now() + 3 + math.random() * 5
			end
		end
		return
	end
	if d.Phase == "Peek" then
		faceToward(d.Peek.Look)
		if now() >= d.Until then
			d.Phase = "Pick"
		end
		return
	end
	if d.Phase == "Wait" then
		if now() >= d.Until then
			d.Phase = "Pick"
		end
		return
	end
	-- Pick somewhere to go
	S.StateStart = now()
	if math.random() < 0.45 then
		local options = {}
		for _, spot in ctx.Layout.PeekSpots do
			local watched = false
			for _, pl in ctx.Util.activePlayers() do
				local r = rootOf(pl)
				if r and math.abs(r.Position.Y - spot.Look.Y) < 6 and (r.Position - spot.Look).Magnitude < 40 then
					watched = true
				end
			end
			if watched and minPlayerDistance(spot.Pos) > 16 then
				table.insert(options, spot)
			end
		end
		local peek = ctx.Util.choice(options)
		if peek then
			d.Peek = peek
			d.Phase = "Move"
			S.Nav:goTo(peek.Pos, { Speed = I.SneakSpeed, Tolerance = 2 })
			return
		end
	end
	d.Peek = nil
	local candidates = nodes(function(n)
		return n.Shadow and n.Room ~= "Attic" and minPlayerDistance(n.Pos) > 24
	end)
	local node = ctx.Util.choice(candidates)
	d.Phase = "Move"
	S.Nav:goTo(node and node.Pos or farNode(), { Speed = I.SneakSpeed })
end

STATES.Patrol = function(_, visible)
	if engage(visible) then
		return
	end
	local d = S.Data
	if S.Nav.Arrived or S.Nav:isStuck() then
		if not d.Linger then
			d.Linger = now() + 2 + math.random() * 3
			if math.random() < 0.4 then
				local spot = spotNear(pos(), 18)
				if spot then
					checkSpot(spot, "Patrol")
					return
				end
			end
		elseif now() >= d.Linger then
			startPatrol()
		end
	end
end

STATES.Investigate = function(_, visible)
	if engage(visible) then
		return
	end
	local d = S.Data
	if d.Retarget then
		d.Retarget = false
		S.Nav:goTo(reachable(d.Pos), { Speed = d.Radius and d.Radius >= 40 and 12 or ctx.Config.Intruder.WalkSpeed + 1, Tolerance = 3 })
	end
	if now() - S.StateStart > 35 then
		startPatrol()
		return
	end
	if S.Nav.Arrived or S.Nav:isStuck() then
		if not d.LookUntil then
			d.LookUntil = now() + 3
			d.LookDir = math.random() * math.pi * 2
		elseif now() < d.LookUntil then
			d.LookDir += 0.35
			faceToward(pos() + V(math.cos(d.LookDir), 0, math.sin(d.LookDir)) * 5)
		else
			local spot = math.random() < 0.55 and spotNear(pos(), 14)
			if spot then
				checkSpot(spot, "Patrol")
			else
				startPatrol()
			end
		end
	end
end

STATES.Stalk = function(_, visible)
	local d = S.Data
	local t = d.Target
	if not valid(t) then
		startPatrol()
		return
	end
	local r = rootOf(t) :: BasePart
	if table.find(visible, t) then
		d.LastSeen = now()
		d.LastPos = r.Position
		follow(r.Position, ctx.Config.Intruder.SneakSpeed + 1.5)
		if tryGrab(t) then
			return
		end
		if Perception.playerSees(t, S.Head.Position, S.Model) and now() >= S.ChaseCooldownUntil then
			engage({ t })
		end
	elseif now() - d.LastSeen > 3 then
		setState("Search", { Pos = d.LastPos or r.Position })
	end
end

STATES.Chase = function(_, visible)
	local d = S.Data
	local t = d.Target
	local I = ctx.Config.Intruder
	if not valid(t) then
		startPatrol()
		return
	end
	local r = rootOf(t) :: BasePart
	if now() - S.StateStart > I.ChaseMaxTime then
		S.ChaseCooldownUntil = now() + 20
		setState("Search", { Pos = r.Position })
		return
	end
	if table.find(visible, t) then
		d.LastSeen = now()
		d.LastPos = r.Position
	elseif now() - d.LastSeen > I.ChaseLoseSightTime then
		S.ChaseCooldownUntil = now() + 12
		setState("Search", { Pos = d.LastPos or r.Position })
		return
	end
	-- he's heard them running: head for where they are even between glimpses
	follow(r.Position, I.ChaseSpeed)
	tryGrab(t)
end

STATES.Search = function(_, visible)
	if engage(visible) then
		return
	end
	local d = S.Data
	if not d.Started then
		d.Started = true
		d.Checked = 0
		S.Nav:goTo(reachable(d.Pos), { Speed = ctx.Config.Intruder.WalkSpeed + 2, Tolerance = 3 })
	end
	if now() - S.StateStart > 30 then
		startPatrol()
		return
	end
	if S.Nav.Arrived or S.Nav:isStuck() then
		if d.Checked < 2 then
			local spot = spotNear(d.Pos, 22)
			if spot then
				d.Checked += 1
				checkSpot(spot, "Search", d)
				return
			end
		end
		startPatrol()
	end
end

STATES.CheckSpot = function(_, visible)
	local d = S.Data
	local spot = d.Spot
	if d.Phase == "Approach" then
		if #visible > 0 and not S.SawHide[spot] then
			if engage(visible) then
				return
			end
		end
		if S.Nav.Arrived or now() - S.StateStart > 12 then
			d.Phase = "Open"
			d.Until = now() + 1.3
			S.Nav:stop()
			faceToward(spot.Position)
			ctx.Audio.playAt("DoorOpen", spot.Position, { CaptionText = "[Something being searched, close by]", CaptionRange = 30 })
		end
		return
	end
	if now() < d.Until then
		return
	end
	local occupant = ctx.Hiding.occupant(spot)
	local I = ctx.Config.Intruder
	local found = false
	if occupant then
		local chance
		if S.SawHide[spot] then
			chance = I.SeeHideCheckChance
		else
			chance = I.RandomHideCheckChance
			if (occupant:GetAttribute("Nerve") or 100) < ctx.Config.Nerve.Heavy then
				chance += I.LowNerveHideBonus
			end
			if occupant:GetAttribute("HoldingBreath") then
				chance *= 0.4
			end
		end
		found = math.random() < chance
	end
	S.SawHide[spot] = nil
	if found and occupant then
		if witnesses(occupant) >= I.GroupWitnesses then
			ctx.Hiding.exit(occupant)
			retreat(spot.Position, 25)
			return
		end
		ctx.Hiding.exit(occupant, true)
		ctx.Capture.capture(occupant)
		local boiler = ctx.Rooms.ByName.Boiler
		retreat(nil, I.RetreatAfterCapture, boiler and V(boiler.Center.X, -10, boiler.Center.Z) or nil)
		return
	end
	if occupant then
		-- so close. they hear him breathing on the other side
		ctx.Audio.playAt("ManWhisper", spot.Position, { Only = { occupant }, Caption = true })
		ctx.PlayerState.addNerve(occupant, -10)
	end
	if d.Return == "Search" and d.ReturnData then
		S.State = "Search"
		S.Data = d.ReturnData
		S.Nav.Arrived = true
	else
		startPatrol()
	end
end

STATES.Retreat = function()
	local d = S.Data
	local t = now() - S.StateStart
	if t >= d.Duration and (S.Nav.Arrived or S.Nav:isStuck() or t > d.Duration + 20) then
		resume()
	end
end

STATES.Stunned = function()
	local d = S.Data
	if now() - S.StateStart >= ctx.Config.Intruder.StunTime then
		S.Humanoid.WalkSpeed = ctx.Config.Intruder.WalkSpeed
		retreat(d.From, ctx.Config.Intruder.RetreatAfterStun)
	end
end

STATES.Frantic = function(_, visible)
	local d = S.Data
	local I = ctx.Config.Intruder
	if d.Phase == "Hunt" then
		if now() - S.StateStart > I.FranticTime then
			d.Phase = "Flee"
			ctx.Director.logTruthRaw("Curtis gave up and ran for his van.")
			S.Nav:goTo(V(71, 1, -3), { Speed = 15, Tolerance = 3, Hurry = true })
			d.FleeStage = 1
			d.FleeStart = now()
			return
		end
		local target = (#visible > 0 and pickTarget(visible)) or (valid(d.Caller) and d.Caller) or nil
		if target then
			local r = rootOf(target)
			if r then
				follow(r.Position, I.ChaseSpeed - 1)
				if table.find(visible, target) then
					tryGrab(target)
				end
			end
		elseif S.Nav.Arrived then
			S.Nav:goTo(pickPatrolGoal(), { Speed = 12 })
		end
		return
	end
	-- Flee: out the garage side door, to the van, gone
	if d.FleeStage == 1 and (S.Nav.Arrived or S.Nav:isStuck()) then
		d.FleeStage = 2
		S.Nav:goTo(ctx.Layout.Outside.Van + V(12, 3, 0), { Speed = 15, Tolerance = 5 })
	elseif d.FleeStage == 2 and (S.Nav.Arrived or now() - d.FleeStart > 40) then
		if not Perception.anyoneSees(S.Head.Position, S.Model) or now() - d.FleeStart > 50 then
			setState("Gone")
			park()
		end
	end
end

STATES.Trapped = function()
	local d = S.Data
	local I = ctx.Config.Intruder
	local door = ctx.Doors.get("Basement")
	if not door then
		startPatrol()
		return
	end
	if not door.Locked or door.IsOpen then
		S.Nav.DoorFilter = nil
		setState("Patrol", {})
		startPatrol()
		return
	end
	local t = now() - S.StateStart
	if t > I.TrappedEscapeTime then
		S.Nav.DoorFilter = nil
		ctx.Doors.setLocked(door, false)
		ctx.Doors.open(door, "Intruder", true)
		ctx.Audio.playAt("DoorForce", door.Position, { CaptionText = "[The basement door bursts open]", CaptionRange = 120 })
		ctx.Director.logTruthRaw("Curtis forced the basement door open.")
		ctx.Remotes.Notify:FireAllClients("The basement door just gave way.", "danger")
		startPatrol()
		return
	end
	if t > I.TrappedEscapeTime - 25 then
		if now() >= (d.NextBang or 0) then
			d.NextBang = now() + 3 + math.random() * 2
			S.Nav:goTo(V(9, -10, 1), { Speed = 10 })
			ctx.Audio.playAt("DoorForce", door.Position, { CaptionText = "[Someone slamming into the basement door]", CaptionRange = 90 })
			ctx.Noise.emit(door.Position, 50, "Force")
		end
	elseif S.Nav.Arrived and now() >= (d.NextMove or 0) then
		d.NextMove = now() + 5 + math.random() * 5
		local list = nodes(function(n)
			return n.Room == "Basement" or n.Room == "Boiler"
		end)
		local n = ctx.Util.choice(list)
		if n then
			S.Nav:goTo(n.Pos, { Speed = ctx.Config.Intruder.WalkSpeed })
		end
	end
end

---------------------------------------------------------------------------
-- Think loop
---------------------------------------------------------------------------
local function animate(dt: number)
	local v = S.Root.AssemblyLinearVelocity
	local speed = V(v.X, 0, v.Z).Magnitude
	if speed > 12 then
		playTrack("Run", speed / 16)
	elseif speed > 0.6 then
		playTrack("Walk", math.max(speed / 9, 0.5))
	else
		playTrack("Idle", 1)
	end
	-- his footsteps: loud when running, soft when walking, silent when sneaking
	S.StepClock += dt
	local interval = speed > 12 and 0.35 or 0.65
	if speed > ctx.Config.Intruder.SneakSpeed + 0.5 and S.StepClock >= interval then
		S.StepClock = 0
		local running = speed > 12
		S.CaptionClock -= interval
		local caption = S.CaptionClock <= 0
		if caption then
			S.CaptionClock = running and 2 or 5
		end
		ctx.Audio.playAt("Footstep", pos() - V(0, 2.5, 0), {
			Volume = running and 1 or 0.45,
			Pitch = 0.8,
			Range = running and 80 or 40,
			Caption = caption,
			CaptionText = running and "[Heavy footsteps, running]" or "[Heavy footsteps]",
			CaptionRange = running and 60 or 28,
		})
	end
end

local function think(dt: number)
	if not S.Model or not S.InHouse then
		return
	end
	local state = S.State
	if state == "Offstage" or state == "Gone" or state == "Stopped" then
		return
	end
	S.Nav:update()
	animate(dt)
	local visible = {}
	local head = S.Head.CFrame
	for _, p in ctx.Util.activePlayers() do
		if Perception.intruderSees(head, p, S.Model) then
			table.insert(visible, p)
			local r = rootOf(p)
			if r then
				S.Memory[p] = { Pos = r.Position, Time = now() }
			end
		end
	end
	S.Visible = visible
	local handler = STATES[state]
	if handler then
		handler(dt, visible)
	end
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
local function enterHouse(onReady: (() -> ())?)
	-- the latest caller wins (the Director may switch Lurk -> Hunt while he's still coming down)
	S.OnEntered = onReady
	if S.InHouse then
		S.OnEntered = nil
		if onReady then
			onReady()
		end
		return
	end
	if S.Entering then
		return
	end
	S.Entering = true
	task.spawn(function()
		local spot = ctx.Layout.Attic.GarageHatchBelow
		local t0 = now()
		ensureModel()
		-- wait until nobody is around to see him come down
		while now() - t0 < 25 do
			if minPlayerDistance(spot) > 20 and not Perception.anyoneSees(spot + V(0, 4, 0), S.Model) then
				break
			end
			task.wait(1)
		end
		if S.Mode == "Offstage" or S.State == "Stopped" then
			S.Entering = false
			return
		end
		placeAt(spot, spot + V(0, 0, -8))
		ctx.Audio.playAt("HatchCreak", spot + V(0, 8, -3), { CaptionText = "[Something creaks in the garage ceiling]", CaptionRange = 45 })
		S.Entering = false
		local cb = S.OnEntered
		S.OnEntered = nil
		if cb then
			cb()
		end
	end)
end

function Intruder.setMode(mode: string, cause: Player?)
	S.Mode = mode
	if mode == "Offstage" then
		ensureModel()
		park()
		setState("Offstage")
	elseif mode == "Lurk" then
		enterHouse(function()
			if S.Mode == "Lurk" then
				setState("Lurk", { Phase = "Pick" })
			end
		end)
	elseif mode == "Hunt" then
		enterHouse(function()
			if S.Mode ~= "Hunt" or S.State == "Trapped" or S.State == "Frantic" then
				return
			end
			local r = cause and rootOf(cause)
			if r then
				setState("Investigate", { Pos = r.Position, Radius = 60, Retarget = true })
			else
				startPatrol()
			end
		end)
	end
end

function Intruder.getState(): string
	return S.State
end

function Intruder.isInHouse(): boolean
	return S.InHouse and S.Root ~= nil and ctx.Rooms.isInside(S.Root.Position)
end

function Intruder.isInBasement(): boolean
	return S.InHouse and S.Root ~= nil and ctx.Rooms.floorOf(S.Root.Position) == "Basement"
end

function Intruder.position(): Vector3?
	return S.InHouse and S.Root and S.Root.Position or nil
end

function Intruder.trap(): boolean
	if not Intruder.isInBasement() or S.State == "Trapped" or S.State == "Gone" then
		return false
	end
	setState("Trapped", {})
	S.Nav:stop()
	S.Nav.DoorFilter = function(door)
		return door.Id ~= "Basement"
	end
	ctx.Audio.playAt("DoorRattle", V(9, 4, 22), { CaptionText = "[The basement door handle rattles, hard]", CaptionRange = 60 })
	return true
end

function Intruder.stop()
	S.Mode = "Stopped"
	setState("Stopped")
	if S.Model and S.Nav then
		S.Nav:stop()
		S.Root.Anchored = true
	end
end

function Intruder.reset()
	S = fresh()
	workspace:SetAttribute("IntruderState", nil)
end

function Intruder.onHelpCalled(caller: Player?)
	if not S.InHouse or S.State == "Trapped" or S.State == "Gone" or S.State == "Stopped" then
		return
	end
	setState("Frantic", { Phase = "Hunt", Caller = caller })
	S.Mode = "Hunt"
	ctx.Audio.caption("[A man shouting somewhere in the house]", pos(), 90)
end

function Intruder.onExitAttempt(position: Vector3, player: Player)
	if S.Mode ~= "Hunt" or not S.InHouse then
		return
	end
	if S.State == "Patrol" or S.State == "Investigate" or S.State == "Search" then
		setState("Investigate", { Pos = position, Radius = 60, Retarget = true })
	end
end

function Intruder.onPlayerHid(player: Player, spot)
	if not S.InHouse then
		return
	end
	if table.find(S.Visible, player) then
		S.SawHide[spot] = true
		if (S.State == "Stalk" or S.State == "Chase") and S.Data.Target == player then
			checkSpot(spot, "Patrol")
		end
	end
end

function Intruder.isVisibleTo(player: Player): boolean
	if not S.InHouse or not S.Head then
		return false
	end
	return Perception.playerSees(player, S.Head.Position, S.Model)
end

function Intruder.onPepperSpray(player: Player)
	if not ctx.Inventory.take(player, "PepperSpray") then
		return
	end
	local r = rootOf(player)
	if not r then
		return
	end
	ctx.Audio.playAt("Spray", r.Position + r.CFrame.LookVector * 2)
	ctx.Noise.emit(r.Position, 20, "Spray", player)
	local left = ctx.Inventory.count(player, "PepperSpray")
	ctx.Audio.caption(left > 0 and ("Pepper spray: " .. left .. " left") or "The can sputters. Empty.", nil, nil, { player })
	if not S.InHouse or not S.Head then
		return
	end
	local P = ctx.Config.PepperSpray
	local to = S.Head.Position - r.Position
	if to.Magnitude > P.Range then
		return
	end
	local flat = V(to.X, 0, to.Z)
	if flat.Magnitude > 0.1 and r.CFrame.LookVector:Dot(flat.Unit) < math.cos(math.rad(P.ConeDegrees)) then
		return
	end
	if not Perception.clear(r.Position + V(0, 1.5, 0), S.Head.Position, { player.Character :: Instance }, S.Model) then
		return
	end
	if S.State == "Stunned" or S.State == "Trapped" or S.State == "Gone" then
		return
	end
	S.Nav:stop()
	S.Humanoid.WalkSpeed = 0
	setState("Stunned", { From = r.Position })
	ctx.Audio.playAt("Cough", S.Head.Position)
	ctx.Noise.emit(S.Head.Position, ctx.Config.Noise.Cough, "Intruder")
	ctx.Director.logTruthRaw((player:GetAttribute("RoleName") or player.Name) .. " pepper-sprayed Curtis.")
	ctx.Remotes.Notify:FireClient(player, "Direct hit. RUN.", "objective")
end

function Intruder.start()
	ctx.Noise.listen(function(ev)
		if not S.InHouse or not S.Root or S.Mode ~= "Hunt" then
			return
		end
		if ev.Kind == "Intruder" or (ev.Position - pos()).Magnitude < 8 then
			return
		end
		if not ctx.Noise.heardAt(ev, pos()) then
			return
		end
		table.insert(S.Noises, ev)
		if #S.Noises > 20 then
			table.remove(S.Noises, 1)
		end
		if S.State == "Patrol" or S.State == "Search" then
			setState("Investigate", { Pos = ev.Position, Radius = ev.Radius, Retarget = true })
		elseif S.State == "Investigate" then
			local d = S.Data
			if (ev.Radius >= (d.Radius or 0) or now() - S.StateStart > 3) and (ev.Position - d.Pos).Magnitude > 6 then
				d.Pos = ev.Position
				d.Radius = ev.Radius
				d.LookUntil = nil
				if now() - (d.LastRetarget or 0) > 1.5 then
					d.LastRetarget = now()
					d.Retarget = true
				end
			end
		end
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < ctx.Config.Intruder.ThinkRate then
			return
		end
		local step = acc
		acc = 0
		local ok, err = pcall(think, step)
		if not ok then
			warn("[Intruder] " .. tostring(err))
		end
	end)
end

return Intruder
