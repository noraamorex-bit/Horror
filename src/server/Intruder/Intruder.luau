--[[
	Intruder — Curtis Vane. A state machine with perception (see GDD §4).

	Modes (set by the Director): Offstage (acts I-II), Lurk (glimpses, before the hunt),
	Hunt (from the blackout on).

	The hunt: he always knows roughly where everyone who isn't hiding is (where they were a
	few seconds ago) and comes for the nearest at a run. Once he sees you he's faster than you.
	The only way out is to break his line of sight and hide somewhere he didn't see you go;
	then he searches nearby hiding spots, gives up, and backs off for a while before the next
	hunt. States: Prowl, Chase, Search, CheckSpot, Withdraw, Retreat, Stunned, Trapped, plus
	Lurk/Offstage/Gone/Stopped.
]]

local RunService = game:GetService("RunService")

local Perception = require(script.Parent.Perception)
local Navigator = require(script.Parent.Navigator)
local NavGrid = require(script.Parent.NavGrid)
local Rig = require(script.Parent.Rig)

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
local tune: () -> any
local charge: (Vector3, Player?) -> ()
local inspect: (any) -> ()
local grabAnyone: () -> boolean
local patrolRoute: () -> { Vector3 }
local unstick: (string) -> ()
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
		HeardHide = {}, -- spot -> time he heard someone in it (a door, a gasp, breathing)
		SpotCooldown = {}, -- spot -> don't go back to it before this time
		NearWarned = {}, -- player -> time we last told them he's right outside
		Noises = {},
		Visible = {},
		LastCaptiveCheck = os.clock(),
		ChaseCooldownUntil = 0,
		-- the hunt
		Trails = {},
		WasHidden = {},
		UnhidAt = {},
		Ignore = {},
		StungAt = {},
		LastFelt = {},
		HuntTarget = nil,
		Waves = 0,
		Frenzy = false,
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

-- the DOORS-Figure brain (hunts by sound) or the classic one (always feels where you are)
local function figure(): boolean
	return ctx.Config.Intruder.Brain == "Figure"
end

-- Config.Intruder, with the night's difficulty laid over it (Config.Difficulty.<name>.Intruder)
local tuned, tunedFor = nil, nil
tune = function(): any
	local d = workspace:GetAttribute("Difficulty") or "Normal"
	if tunedFor ~= d or not tuned then
		tunedFor = d
		tuned = table.clone(ctx.Config.Intruder)
		local diff = ctx.Config.Difficulty and ctx.Config.Difficulty[d]
		for k, v in (diff and diff.Intruder) or {} do
			tuned[k] = v
		end
	end
	return tuned
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

local function buildRig(): Model
	local ok, result = pcall(Rig.build, ctx.Builder)
	local model = (ok and result) or blockRig()
	if not ok then
		warn("[Intruder] rig failed, using the block rig: " .. tostring(result))
	end
	model.Name = "Curtis"
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.NameDisplayDistance = 0
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.BreakJointsOnDeath = false
	hum.MaxHealth = 1e9
	hum.Health = 1e9
	hum.WalkSpeed = tune().WalkSpeed
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	return model
end

local function loadAnims()
	local hum = S.Humanoid :: Humanoid
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = hum
	if hum.RigType ~= Enum.HumanoidRigType.R15 or (S.Model and S.Model:GetAttribute("Creature")) then
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
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CollisionGroup = "Intruder"
		end
	end
	S.Nav = Navigator.new(ctx, S.Humanoid, S.Root)
	S.Tracks = {}
	S.CurrentTrack = nil
	loadAnims()
	-- heavy, slow breathing that carries a few steps: the sound of him right outside the closet
	if S.Head then
		ctx.Audio.loopOn("IntruderBreath", S.Head, { Caption = false })
	end
end

local function setState(name: string, data: any?)
	-- (walking away from a hiding spot he was listening at: the heartbeat minigame is over)
	if S.State == "Inspect" and S.Data and S.Data.Occupant and ctx.Heartbeat then
		ctx.Heartbeat.stop(S.Data.Occupant)
	end
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
	-- stand him on the floor under `pos` (markers are a few studs up; his root is higher than
	-- a player's)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { S.Model }
	local hit = workspace:Raycast(pos + V(0, 1, 0), V(0, -10, 0), params)
	local rootY = (S.Humanoid and S.Humanoid.HipHeight or Rig.HipHeight) + S.Root.Size.Y / 2
	if hit then
		pos = V(pos.X, hit.Position.Y + rootY + 0.05, pos.Z)
	end
	local lookAt = look and V(look.X, pos.Y, look.Z) or (pos + V(0, 0, -1))
	if (lookAt - pos).Magnitude < 0.01 then
		lookAt = pos + V(0, 0, -1)
	end
	S.Model:PivotTo(CFrame.lookAt(pos, lookAt))
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
		and not p:GetAttribute("Escaped") and not p:GetAttribute("AdminGhost") and ctx.Util.isAlive(p)
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
	target = reachable(target)
	-- a straight run he can actually walk (no wall, no furniture, no ledge in the way): straight there
	local direct
	if NavGrid.ready() then
		direct = (target - p).Magnitude < 40 and NavGrid.straight(p, target)
	else
		direct = math.abs(target.Y - p.Y) < 5 and (target - p).Magnitude < 30
			and Perception.clear(S.Head.Position, target + V(0, 1, 0), { S.Model }, nil)
	end
	if direct then
		S.Nav:moveDirect(target, speed)
		d.PathGoal = nil
		return
	end
	if not d.PathGoal or S.Nav.Arrived or now() - (d.LastPath or 0) > 1 or (d.PathGoal - target).Magnitude > 4 then
		d.PathGoal = target
		d.LastPath = now()
		S.Nav:goTo(target, { Speed = speed, Tolerance = 2, Hurry = speed > 12 })
	else
		S.Humanoid.WalkSpeed = speed
	end
end

local function retreat(from: Vector3?, duration: number?, goal: Vector3?)
	setState("Retreat", { Goal = goal or farNode(), Duration = duration or 20, From = from })
	S.Nav:goTo(S.Data.Goal, { Speed = 12, Tolerance = 3, Hurry = true })
end

-- the boiler room, where captives are held
local function boilerPos(): Vector3?
	local boiler = ctx.Rooms.ByName.Boiler
	return boiler and V(boiler.Center.X, -10, boiler.Center.Z) or nil
end

-- Someone's just been zip-tied (Capture teleports them to the boiler room). He doesn't hang around
-- down there: he heads off somewhere dark on another floor, far from the boiler room, and for
-- CaptiveGrace seconds he ignores the basement altogether (their struggling included), so they and
-- their friends get a real chance to cut them free.
local function afterCapture(who: Player?)
	local I = tune()
	S.CaptiveGraceUntil = now() + (I.CaptiveGrace or 0)
	S.LastCaptiveCheck = now()
	local boiler = boilerPos()
	local best, bestScore = nil, -math.huge
	for _, n in ctx.Layout.Nodes do
		if n.Room ~= "Basement" and n.Room ~= "Boiler" then
			local score = (boiler and (n.Pos - boiler).Magnitude or 0) + (n.Shadow and 15 or 0) + math.random() * 20
			if score > bestScore then
				best, bestScore = n, score
			end
		end
	end
	retreat(nil, I.RetreatAfterCapture, best and best.Pos or nil)
	-- (tell them: this is the moment)
	if who then
		task.delay(6, function()
			if who.Parent and who:GetAttribute("Captured") and now() < (S.CaptiveGraceUntil or 0) then
				ctx.Director.think(who, "His footsteps are going back up the stairs. Struggle. NOW.")
			end
		end)
	end
end

local function inCaptiveGrace(): boolean
	return now() < (S.CaptiveGraceUntil or 0)
end

-- the owner's "can't be caught" switch (admin panel): he still comes for them and grabs, and nothing happens
local function grabFails(target: Player): boolean
	if not target:GetAttribute("AdminGod") then
		return false
	end
	S.GodGrab = S.GodGrab or {}
	if now() - (S.GodGrab[target] or -1e9) > 2.5 then
		S.GodGrab[target] = now()
		ctx.Remotes.Shake:FireClient(target, 0.6, 0.4)
		if S.Head then
			ctx.Audio.playAt("Growl", S.Head.Position, { Caption = false })
		end
		ctx.Audio.caption("[He grabs you. Nothing happens. (Admin: can't be caught)]", nil, nil, { target })
	end
	return true
end

local function tryGrab(target: Player): boolean
	local r = rootOf(target)
	if not r or (r.Position - pos()).Magnitude > tune().GrabRange then
		return false
	end
	if grabFails(target) then
		return false
	end
	if ctx.Capture.capture(target) then
		S.Memory[target] = nil
		S.HuntTarget = nil
		afterCapture(target)
		return true
	end
	return false
end

---------------------------------------------------------------------------
-- The hunt: what he knows
---------------------------------------------------------------------------
--[[
	He always knows roughly where you are: every half second he "hears" where each player who
	isn't hiding is, and acts on where you were SenseDelay seconds ago (a bloodhound on your
	trail, not a camera on you). Hide and the trail goes cold. Come out and he doesn't feel you
	again for HideGrace seconds, so you can slip away. If he can see you, he knows exactly.
]]
local function recordTrails()
	if now() - (S.TrailClock or 0) < 0.5 then
		return
	end
	S.TrailClock = now()
	for _, p in ctx.Util.activePlayers() do
		local r = rootOf(p)
		if p:GetAttribute("Hiding") or not r then
			S.Trails[p] = {}
			S.WasHidden[p] = true
		else
			-- just out of hiding, just cut free, or the hunt just began: a few seconds' grace
			if S.WasHidden[p] or S.Trails[p] == nil then
				S.WasHidden[p] = nil
				S.UnhidAt[p] = now()
			end
			local tr = S.Trails[p] or {}
			S.Trails[p] = tr
			table.insert(tr, { T = now(), Pos = r.Position })
			if #tr > 24 then
				table.remove(tr, 1)
			end
		end
	end
	for p in S.Trails do
		if not valid(p) then
			S.Trails[p] = nil
		end
	end
end

-- where he thinks this player is right now (nil: he has no idea)
local function sensed(p: Player): Vector3?
	if not valid(p) or p:GetAttribute("Hiding") then
		return nil
	end
	-- (the Figure brain has no sixth sense: only what he hears, and what he sees close up)
	if figure() then
		return nil
	end
	local r = rootOf(p)
	if r and table.find(S.Visible, p) then
		return r.Position
	end
	local I = tune()
	if now() - (S.UnhidAt[p] or -1e9) < I.HideGrace or now() < (S.Ignore[p] or 0) then
		return nil
	end
	local tr = S.Trails[p]
	if not tr or #tr == 0 then
		return nil
	end
	local want = now() - I.SenseDelay
	local best = tr[1]
	for _, e in tr do
		if e.T <= want then
			best = e
		end
	end
	return best.Pos
end

-- the nearest player he can feel (sticks with the current one unless another is much closer)
local function huntTarget(): (Player?, Vector3?)
	local best, bestPos, bestD = nil, nil, math.huge
	local here = pos()
	for _, p in ctx.Util.activePlayers() do
		local at = sensed(p)
		if at then
			local d = (at - here).Magnitude + math.abs(at.Y - here.Y) * 2.5
			if p == S.HuntTarget then
				d *= 0.7
			end
			-- he goes for the one on their own, and the one waving a light around
			local mine = rootOf(p)
			local alone = mine ~= nil
			if mine then
				for _, q in ctx.Util.activePlayers() do
					local qr = q ~= p and rootOf(q)
					if qr and (qr.Position - mine.Position).Magnitude < 20 then
						alone = false
						break
					end
				end
			end
			if alone and #ctx.Util.activePlayers() > 1 then
				d *= 0.8
			end
			if p:GetAttribute("FlashlightOn") then
				d *= 0.85
			end
			if d < bestD then
				best, bestPos, bestD = p, at, d
			end
		end
	end
	return best, bestPos
end

local function startChase(target: Player)
	setState("Chase", { Target = target, LastSeen = now() })
	S.HuntTarget = target
	ctx.Director.addTension(20)
	-- the moment he sees you: a sting only you hear, the screen jolts
	if now() - (S.StungAt[target] or -1e9) > 18 then
		S.StungAt[target] = now()
		ctx.Audio.playFor(target, "Stinger")
		ctx.Audio.playFor(target, "GaspDeep")
		ctx.Remotes.Shake:FireClient(target, 0.6, 0.6)
		if ctx.Director.thinkOnce then
			ctx.Director.thinkOnce(target, "HuntSeen", ctx.Story.Hunt.Seen)
		end
	end
	ctx.Audio.caption("[Heavy footsteps - running at you]", pos(), 60)
end

local function engage(visible: { Player }): boolean
	if #visible == 0 or now() < S.ChaseCooldownUntil then
		return false
	end
	local target = pickTarget(visible)
	if not target then
		return false
	end
	startChase(target)
	return true
end

local function checkSpot(spot, returnState: string, returnData: any?)
	setState("CheckSpot", { Spot = spot, Return = returnState, ReturnData = returnData, Phase = "Approach" })
	S.Nav:goTo(spot.Exit.Position, { Speed = tune().ProwlSpeed, Tolerance = 2.5, Hurry = true })
end

-- the next hiding spot to tear open around `at`: one he saw someone use first, then (a little
-- more often) the one they're really in, then any
local function searchSpot(at: Vector3, target: Player?, checked: { [any]: boolean })
	local entries = {}
	for _, s in ctx.Hiding.spotsNear(at, 18) do
		if not checked[s] then
			local w = 1
			if S.SawHide[s] then
				w = 20
			elseif S.HeardHide[s] and now() - S.HeardHide[s] < 40 then
				w = 8
			elseif target and ctx.Hiding.occupant(s) == target then
				w = tune().TrueSpotWeight
			end
			table.insert(entries, { s, w })
		end
	end
	return ctx.Util.weighted(entries)
end

-- a new hunt: a door slams somewhere, and he starts running
local function startHunt()
	if figure() then
		setState("Patrol", { Route = patrolRoute(), Index = 0 })
	else
		setState("Prowl", {})
	end
	S.HuntTarget = nil
	if S.LastHuntAt and now() - S.LastHuntAt < 30 then
		-- (he never really stopped: no door slam, no new wave)
		return
	end
	S.LastHuntAt = now()
	S.Waves += 1
	local justEntered = S.JustEntered
	S.JustEntered = nil
	ctx.Audio.playAt("DoorSlam", pos(), { CaptionText = "[A door SLAMS somewhere in the house]", CaptionRange = 200 })
	local H = ctx.Story.Hunt
	if S.Waves == 1 then
		-- the first time: the cutscene of him under the garage hatch, just down from the attic
		if ctx.Cutscene and S.InHouse and justEntered and now() - (S.EnteredAt or -1e9) < 5 then
			ctx.Cutscene.heComesDown(justEntered)
		end
		-- (one clear warning, not a thought and a note saying the same thing at once)
		ctx.Remotes.Notify:FireAllClients(H.FirstNotice, "danger")
		-- Figure brain: the first time, he heard the whole house. He goes for the nearest of you
		if figure() then
			local best, bestD = nil, math.huge
			for _, p in ctx.Util.activePlayers() do
				local r = valid(p) and not p:GetAttribute("Hiding") and rootOf(p)
				if r and (r.Position - pos()).Magnitude < bestD then
					best, bestD = p, (r.Position - pos()).Magnitude
				end
			end
			local r = best and rootOf(best)
			if best and r then
				charge(r.Position, best)
			end
		end
	elseif math.random() < 0.5 then
		ctx.Director.think(nil, ctx.Util.choice(H.Wave))
	end
end

-- which floors have players on them (hidden ones too, by where he last felt them)
local function playerFloors(): { [string]: boolean }
	local floors = {}
	for _, p in ctx.Util.activePlayers() do
		local r = rootOf(p)
		if r then
			floors[ctx.Rooms.floorOf(r.Position)] = true
		end
	end
	for p, at in S.LastFelt do
		if valid(p) then
			floors[ctx.Rooms.floorOf(at)] = true
		end
	end
	return floors
end

-- somewhere dark to wait: near the players' floor but not on top of them, and not the basement
-- (the old "farthest dark corner" was always the basement, and he'd sit down there all night)
local function restNode(): Vector3
	local floors = playerFloors()
	local best, bestScore = nil, -math.huge
	for _, n in ctx.Layout.Nodes do
		if n.Shadow then
			local d = minPlayerDistance(n.Pos)
			local score = -math.abs(math.min(d, 200) - 40) + math.random() * 8
			if floors[ctx.Rooms.floorOf(n.Pos)] then
				score += 25
			end
			if n.Room == "Basement" or n.Room == "Boiler" then
				score -= 30
			end
			if d < 18 then
				score -= 100
			end
			if score > bestScore then
				best, bestScore = n, score
			end
		end
	end
	return best and best.Pos or farNode()
end

-- a few rooms to sweep: where players were last felt, where the last noises came from, and
-- the rest of their floor (past the boiler room now and then if someone's tied up down there)
patrolRoute = function(): { Vector3 }
	local I = tune()
	local clues = {}
	for p, at in S.LastFelt do
		if valid(p) then
			table.insert(clues, at)
		end
	end
	for i = #S.Noises, math.max(1, #S.Noises - 4), -1 do
		local ev = S.Noises[i]
		if ev and now() - ev.Time < 60 then
			table.insert(clues, ev.Position)
		end
	end
	local floors = playerFloors()
	local grace = inCaptiveGrace()
	local checkCaptives = not grace and ctx.Capture.captiveCount() > 0 and now() - S.LastCaptiveCheck > I.PatrolCaptiveCheck
	local candidates = {}
	for _, n in ctx.Layout.Nodes do
		local w = floors[ctx.Rooms.floorOf(n.Pos)] and 3 or 0.4
		local below = n.Room == "Boiler" or n.Room == "Basement"
		if n.Room == "Boiler" then
			w = checkCaptives and 8 or 0.1
		elseif n.Room == "Basement" then
			w = floors.Basement and 3 or 0.15
		end
		for _, c in clues do
			if (c - n.Pos).Magnitude < 25 and not (grace and below) then
				w += 4
			end
		end
		if grace and below then
			w = 0 -- (he's just left someone down there: he leaves them be for a while)
		end
		if (n.Pos - pos()).Magnitude < 8 then
			w *= 0.2
		end
		table.insert(candidates, { n, w })
	end
	local route = {}
	for _ = 1, 4 do
		local n = ctx.Util.weighted(candidates)
		if not n then
			break
		end
		table.insert(route, n.Pos)
		for i, e in candidates do
			if e[1] == n then
				table.remove(candidates, i)
				break
			end
		end
	end
	return route
end

local function patrol()
	setState("Patrol", { Route = patrolRoute(), Index = 0 })
	S.HuntTarget = nil
end

-- he moves through the walls and the crawlspaces: gone from somewhere nobody's looking, out of
-- a dark corner on the players' floor that nobody's looking at either
local function relocate(): boolean
	if Perception.anyoneSees(pos() + V(0, 3, 0), S.Model) then
		return false
	end
	local floors = playerFloors()
	local best, bestScore = nil, -math.huge
	for _, n in ctx.Layout.Nodes do
		local d = minPlayerDistance(n.Pos)
		if n.Shadow and d > 22 and floors[ctx.Rooms.floorOf(n.Pos)] and not Perception.anyoneSees(n.Pos + V(0, 3, 0), S.Model) then
			local score = -math.abs(math.min(d, 200) - 35) + math.random() * 5
			if score > bestScore then
				best, bestScore = n, score
			end
		end
	end
	if not best then
		return false
	end
	S.Nav:stop()
	placeAt(best.Pos, best.Pos + V(0, 0, -1))
	S.Progress = { Pos = pos(), T = now() }
	if ctx.Director.logTruthRaw and not S.LoggedWalls then
		S.LoggedWalls = true
		ctx.Director.logTruthRaw("He knew the crawlspaces and the gaps behind the walls. That's how he always seemed to be everywhere at once.")
	end
	return true
end

-- he lets the house go quiet: walks off somewhere dark and waits, listening
local function withdraw()
	local I = tune()
	local dur = I.WithdrawMin + math.random() * (I.WithdrawMax - I.WithdrawMin)
	if S.Frenzy then
		dur *= 0.5
	end
	-- alone, you get a little longer to get things done
	if #ctx.Util.sessionPlayers() <= 1 then
		dur *= 1.3
	end
	local goal = restNode()
	local boiler = ctx.Rooms.ByName.Boiler
	if not inCaptiveGrace() and ctx.Capture.captiveCount() > 0 and now() - S.LastCaptiveCheck > I.CaptiveCheckInterval and boiler then
		S.LastCaptiveCheck = now()
		goal = V(boiler.Center.X + 4, -10, boiler.Center.Z)
	end
	setState("Withdraw", { Until = now() + dur })
	S.HuntTarget = nil
	S.Nav:goTo(goal, { Speed = I.WalkSpeed })
end

-- he doesn't really leave: creeps (silently) to somewhere close but out of the way, and waits
-- for whoever's hiding to think it's over
local function ambush(at: Vector3, target: Player?, checked: { [any]: boolean }?)
	local I = tune()
	local best, bestScore = nil, -math.huge
	for _, n in ctx.Layout.Nodes do
		local d = (n.Pos - at).Magnitude
		if d > 8 and d < 20 and math.abs(n.Pos.Y - at.Y) < 6 then
			-- in sight of the spot he searched is better (he wants to see you come out)
			local score = -math.abs(d - 13) + (Perception.clear(n.Pos + V(0, 3, 0), at + V(0, 2, 0), { S.Model }, nil) and 6 or 0)
			if score > bestScore then
				best, bestScore = n, score
			end
		end
	end
	if not best then
		withdraw()
		return
	end
	setState("Ambush", { Pos = at, Target = target, Checked = checked or {}, Until = now() + I.AmbushTime + math.random() * 5 })
	S.Nav:goTo(best.Pos, { Speed = I.SneakSpeed, Tolerance = 2.5 })
end

local function resume()
	if S.Mode == "Lurk" then
		setState("Lurk", { Phase = "Pick" })
	else
		startHunt()
	end
end

---------------------------------------------------------------------------
-- States
---------------------------------------------------------------------------
--[[
	Lurk (before the hunt): he is hiding, not wandering. Most of the time he's out of sight in
	the walls and the attic (parked, not in the house). Now and then he makes an appearance: he
	stands somewhere you can see from where you are, but aren't looking at yet. Turn around and
	he's there, at the end of the hall, staring. Once he's been seen (or after a while) he walks
	out of sight and is gone again. Walk right up to him and he shoves you down and runs.
]]
local function lurkSpot(): (Vector3?, Player?)
	local players = ctx.Util.activePlayers()
	if #players == 0 then
		return nil, nil
	end
	-- the loneliest player is the one he shows himself to
	table.sort(players, function(a, b)
		return ctx.PlayerState.friendsNear(a) < ctx.PlayerState.friendsNear(b)
	end)
	local candidates = {}
	for _, p in players do
		local eye, look = Perception.eyeOf(p)
		local r = rootOf(p)
		if not eye or not look or not r then
			continue
		end
		local spots = {}
		for _, n in ctx.Layout.Nodes do
			table.insert(spots, n.Pos)
		end
		for _, sp in ctx.Layout.PeekSpots do
			table.insert(spots, sp.Pos)
		end
		for _, pos in spots do
			local d = (pos - r.Position).Magnitude
			local to = pos + V(0, 2.5, 0) - eye
			if math.abs(pos.Y - r.Position.Y) < 6 and d > 14 and d < 38 and ctx.Rooms.floorOf(pos) ~= "Attic" then
				-- in plain view from where they stand, but not where they're looking right now
				if look:Dot(to.Unit) < 0.2 and Perception.clear(eye, pos + V(0, 2.5, 0), { p.Character :: Instance }, S.Model)
					and not Perception.anyoneSees(pos + V(0, 2.5, 0), S.Model) then
					table.insert(candidates, { pos, p })
				end
			end
		end
		if #candidates > 0 then
			break
		end
	end
	local pick = ctx.Util.choice(candidates)
	if pick then
		return pick[1], pick[2]
	end
	return nil, nil
end

-- bolting after being seen: fast, to the far side of the house, and clumsy about it
local function bolt(d)
	d.Phase = "Leave"
	d.Bolting = true
	d.FleeStart = now()
	d.UnseenSince = nil
	S.Nav:goTo(farNode(), { Speed = 15, Tolerance = 3, Hurry = true })
	-- in his hurry he knocks a chair over (once a night; the one loud thing he does by accident)
	if not S.KnockedChair and math.random() < 0.6 then
		S.KnockedChair = true
		task.delay(0.6, function()
			if S.Root and S.InHouse then
				ctx.Audio.playAt("ChairDrop", pos(), { Volume = 1 })
				ctx.Director.logTruth("ChairDrop")
			end
		end)
	end
end

-- someone walked right up to him: he shoves past them and runs
local function shove(p: Player)
	local r = rootOf(p)
	if not r then
		return
	end
	faceToward(r.Position)
	ctx.Audio.playAt("Stinger", r.Position, { Volume = 1, Caption = false })
	ctx.Audio.caption("[A man shoves past you in the dark]", r.Position, 30)
	ctx.Remotes.Shake:FireClient(p, 0.9, 0.9)
	ctx.PlayerState.addNerve(p, -25)
	-- knocked flat for a moment: the player's own client owns their physics, so it does the fall
	local away = V(r.Position.X - pos().X, 0, r.Position.Z - pos().Z)
	ctx.Remotes.Knockdown:FireClient(p, away.Magnitude > 0.1 and away.Unit or V(0, 0, 1))
	if not S.LoggedShove then
		S.LoggedShove = true
		ctx.Director.logTruthRaw(tostring(p:GetAttribute("RoleName") or p.Name) .. " walked right into Curtis in the dark. He shoved them down and ran.")
	end
	ctx.Director.onSighting(p)
end

local function hideAway(d)
	park()
	d.Phase = "Hidden"
	d.Bolting = false
	d.Until = now() + 25 + math.random() * 30
end

STATES.Lurk = function(dt, visible)
	local d = S.Data
	local I = tune()
	if d.Phase == nil or d.Phase == "Pick" then
		hideAway(d)
	end
	if d.Phase == "Hidden" then
		-- in the walls: rooms go dark behind you now and then (he moves easier in the dark)
		d.LightClock = (d.LightClock or 20) - dt
		if d.LightClock <= 0 and ctx.Power.isOn() then
			d.LightClock = 30
			local occupied = {}
			for _, p in ctx.Util.activePlayers() do
				local r = rootOf(p)
				local room = r and ctx.Rooms.find(r.Position)
				if room then
					occupied[room.Name] = true
				end
			end
			for _, room in ctx.Rooms.List do
				if not occupied[room.Name] and ctx.Power.isRoomSwitchOn(room.Name) and math.random() < 0.2 then
					ctx.Power.setSwitch(room.Name, false)
					if not S.LoggedLights then
						S.LoggedLights = true
						ctx.Director.logTruthRaw("The lights that kept going off in empty rooms were Curtis. He moves easier in the dark.")
					end
					break
				end
			end
		end
		if now() < d.Until then
			return
		end
		local spot, who = lurkSpot()
		if not spot or not who then
			d.Until = now() + 6
			return
		end
		local r = rootOf(who)
		placeAt(spot, r and V(r.Position.X, spot.Y, r.Position.Z) or nil)
		S.Nav:stop()
		d.Phase = "Watch"
		d.Target = who
		d.Until = now() + 12
		d.SeenAt = nil
		return
	end
	if not S.InHouse then
		return
	end
	local obs = observers()
	-- too close: whether they've seen him or he's seen them, he can't stay hidden
	if not d.Bolting then
		for _, pl in ctx.Util.activePlayers() do
			local r = rootOf(pl)
			if r and math.abs(r.Position.Y - pos().Y) < 6 and (r.Position - pos()).Magnitude < 8
				and (table.find(obs, pl) or table.find(visible, pl)) then
				shove(pl)
				bolt(d)
				return
			end
		end
	end
	if d.Phase == "Watch" then
		local t = d.Target
		local r = t and valid(t) and rootOf(t)
		if r then
			faceToward(r.Position)
		end
		if #obs > 0 and not d.SeenAt then
			d.SeenAt = now()
			if t and table.find(obs, t) then
				ctx.Director.onSighting(t)
			end
		end
		-- seen: a long second of staring back; not seen: he gives up after a while
		if (d.SeenAt and now() - d.SeenAt > 1.2 + math.random() * 0.6) or now() > d.Until then
			d.Phase = "Leave"
			d.UnseenSince = nil
			d.FleeStart = now()
			S.Nav:goTo(farNode(), { Speed = I.WalkSpeed, Tolerance = 3 })
		end
		return
	end
	if d.Phase == "Leave" then
		-- the moment nobody can see him, he's gone
		if #obs == 0 then
			d.UnseenSince = d.UnseenSince or now()
			if now() - d.UnseenSince > 1.2 then
				hideAway(d)
			end
		else
			d.UnseenSince = nil
		end
		if S.Nav.Arrived or S.Nav:isStuck() or now() - (d.FleeStart or 0) > 25 then
			S.Nav:goTo(farNode(), { Speed = d.Bolting and 15 or I.WalkSpeed, Tolerance = 3, Hurry = d.Bolting })
		end
	end
end

--[[
	Prowl: running to wherever he feels the nearest player is. Heavy, fast footsteps through the
	house; you hear him long before you see him. Seeing anyone turns it into a chase.
]]
STATES.Prowl = function(_, visible)
	if engage(visible) then
		return
	end
	local d = S.Data
	local I = tune()
	-- the one he was after just vanished into a hiding spot: search where he last felt them
	local was = S.HuntTarget
	if was and valid(was) and was:GetAttribute("Hiding") and S.LastFelt[was] then
		setState("Search", { Pos = S.LastFelt[was], Target = was, Checked = {} })
		S.HuntTarget = nil
		return
	end
	local target, at = huntTarget()
	if not target or not at then
		-- nobody to feel (all hidden, or just out of hiding): he starts going room to room
		if now() - S.StateStart > 2 then
			patrol()
		end
		return
	end
	S.HuntTarget = target
	S.LastFelt[target] = at
	follow(reachable(at), (at - pos()).Magnitude > 40 and I.ProwlSpeed or I.ProwlSpeed - 1.5)
	-- ran right into them in the dark
	if tryGrab(target) then
		return
	end
	-- they're somewhere he can't follow (up in the attic): he waits under it a while, then
	-- leaves them be
	local tr = rootOf(target)
	if S.Nav.Arrived and tr and (tr.Position - pos()).Magnitude > 10 then
		d.WaitSince = d.WaitSince or now()
		if now() - d.WaitSince > 8 then
			S.Ignore[target] = now() + 15
			d.WaitSince = nil
			S.HuntTarget = nil
			patrol()
			return
		end
	else
		d.WaitSince = nil
	end
	-- somewhere he can't get to (the attic, a roof): leave them be for a while
	if S.Nav:isStuck() then
		d.StuckSince = d.StuckSince or now()
		if now() - d.StuckSince > 6 then
			S.Ignore[target] = now() + 20
			d.StuckSince = nil
			S.HuntTarget = nil
		end
	else
		d.StuckSince = nil
	end
	-- he got to where they were and they're not there (and not hidden): keep following the trail
end

--[[
	Chase: he can see you. He's faster than you and doesn't tire; up close he lunges. Get out of
	his sight and he's back to following your trail, a few seconds behind.
]]
STATES.Chase = function(_, visible)
	local d = S.Data
	local t = d.Target
	local I = tune()
	if not valid(t) then
		startHunt()
		return
	end
	if t:GetAttribute("Hiding") then
		-- hid out of his sight (in sight, onPlayerHid already sent him to that spot)
		if figure() then
			charge(d.LastPos or pos(), t)
		else
			setState("Search", { Pos = d.LastPos or pos(), Target = t, Checked = {} })
		end
		return
	end
	local r = rootOf(t) :: BasePart
	local seen = table.find(visible, t) ~= nil
	if seen then
		d.LastSeen = now()
		d.LastPos = r.Position
		local v = r.AssemblyLinearVelocity
		d.LastVel = V(v.X, 0, v.Z)
	elseif now() - d.LastSeen > I.ChaseLoseSightTime then
		-- lost sight: back on the trail (Figure brain: he runs to where you were and listens)
		S.HuntTarget = t
		if figure() then
			charge(d.LastPos or r.Position, t)
		else
			setState("Prowl", {})
		end
		return
	end
	-- out of sight for a moment: he runs to where they were heading
	local goal = r.Position
	if not seen and d.LastPos then
		local ahead = (d.LastVel or V()) * math.min(now() - d.LastSeen + 0.6, 1.8)
		if ahead.Magnitude > 10 then
			ahead = ahead.Unit * 10
		end
		goal = d.LastPos + ahead
	end
	local solo = #ctx.Util.sessionPlayers() <= 1
	local speed = I.ChaseSpeed - (solo and I.SoloChaseSlowdown or 0)
	if seen and (r.Position - pos()).Magnitude < 10 then
		speed = I.LungeSpeed
	end
	follow(goal, speed)
	tryGrab(t)
end

--[[
	Search: someone hid. He goes to where he last felt them, stands still and listens, then
	tears open hiding spots nearby - one he saw you use first. Two at most, then he leaves.
]]
STATES.Search = function(_, visible)
	if engage(visible) then
		return
	end
	local d = S.Data
	local I = tune()
	d.Checked = d.Checked or {}
	if not d.Started then
		d.Started = true
		d.Checks = d.Checks or 0
		S.Nav:goTo(reachable(d.Pos), { Speed = I.ProwlSpeed - 2, Tolerance = 3 })
	end
	if now() - S.StateStart > 30 then
		withdraw()
		return
	end
	-- someone else is out in the open meanwhile: he can feel them, but finishes here first
	if S.Nav.Arrived or S.Nav:isStuck() then
		if not d.ListenUntil then
			d.ListenUntil = now() + 2 + math.random() * 1.5
			S.Nav:stop()
			ctx.Audio.playAt("ManWhisper", S.Head.Position, { CaptionText = "[Slow, heavy breathing. Listening.]", CaptionRange = 22 })
			return
		end
		if now() < d.ListenUntil then
			return
		end
		if d.Checks < I.SearchChecks then
			local spot = searchSpot(d.Pos, d.Target, d.Checked)
			if spot then
				d.Checks += 1
				d.Checked[spot] = true
				d.ListenUntil = nil
				checkSpot(spot, "Search", d)
				return
			end
		end
		if not d.Ambushed and math.random() < I.AmbushChance then
			ambush(d.Pos, d.Target, d.Checked)
		else
			withdraw()
		end
	end
end

--[[
	Ambush: he walked off without a sound and is standing just round the corner, watching.
	Come out too soon and he's right there. Then one more look, and he really leaves.
]]
STATES.Ambush = function(_, visible)
	if engage(visible) then
		return
	end
	local d = S.Data
	local I = tune()
	if S.Nav.Arrived and not d.Waiting then
		d.Waiting = true
		S.Nav:stop()
		faceToward(d.Pos)
	end
	if now() >= d.Until then
		-- one more look, at a spot he hasn't opened yet
		setState("Search", { Pos = d.Pos, Target = d.Target, Checked = d.Checked, Checks = I.SearchChecks - 1, Ambushed = true })
	end
end

--[[
	Withdraw: the house goes quiet. He walks off somewhere dark and waits. This is the time to
	move. Run into him (or into his sight up close) and it's over early.
]]
STATES.Withdraw = function(_, visible)
	local d = S.Data
	local I = tune()
	for _, p in visible do
		local r = rootOf(p)
		if r and (r.Position - pos()).Magnitude < I.WithdrawNotice then
			startChase(p)
			return
		end
	end
	if S.Nav.Arrived and not d.Idle then
		d.Idle = true
		S.Nav:stop()
	end
	if now() >= d.Until then
		-- nobody out in the open: he goes looking, room by room
		if huntTarget() then
			startHunt()
		else
			patrol()
		end
	end
end

--[[
	Patrol: nobody he can feel (everyone hiding, or the house just went quiet). He walks the
	rooms where you were last, stops and listens, and now and then tears open a hiding spot.
	Anyone out in the open and he's back on the hunt.
]]
STATES.Patrol = function(_, visible)
	if engage(visible) then
		return
	end
	local d = S.Data
	local I = tune()
	if figure() then
		-- (he walks into anyone standing in his way)
		if grabAnyone() then
			return
		end
	elseif huntTarget() then
		startHunt()
		return
	end
	if not d.Moving then
		d.Index += 1
		local goal = d.Route and d.Route[d.Index]
		if not goal then
			patrol()
			return
		end
		d.Moving = true
		d.PauseUntil = nil
		d.LegStart = now()
		S.Nav:goTo(goal, { Speed = I.PatrolSpeed, Tolerance = 3 })
		return
	end
	if S.Nav.Arrived or S.Nav:isStuck() or now() - (d.LegStart or S.StateStart) > 40 then
		if not d.PauseUntil then
			S.Nav:stop()
			d.PauseUntil = now() + I.PatrolPause[1] + math.random() * (I.PatrolPause[2] - I.PatrolPause[1])
			local room = ctx.Rooms.find(pos())
			if room and room.Name == "Boiler" then
				S.LastCaptiveCheck = now()
			end
			if math.random() < I.PatrolCheckChance * (figure() and 0.6 or 1) then
				local spots = ctx.Hiding.spotsNear(pos(), 14)
				if #spots > 0 then
					d.Moving = false
					d.PauseUntil = nil
					local pick = spots[math.random(1, #spots)]
					if figure() then
						-- stops at one and listens (for nothing, most of the time)
						inspect(pick)
					else
						checkSpot(pick, "Patrol", d)
					end
				end
			end
			return
		end
		if now() >= d.PauseUntil then
			d.Moving = false
			d.PauseUntil = nil
		end
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
			-- couldn't get there: don't pretend to search a cupboard from across the room
			if (pos() - spot.Exit.Position).Magnitude > 7 then
				S.SawHide[spot] = nil
				resume()
				return
			end
			d.Phase = "Open"
			d.Until = now() + 1.3
			S.Nav:stop()
			faceToward(spot.Position)
			ctx.Audio.playAt("DoorOpen", spot.Position, { CaptionText = "[Something being searched, close by]", CaptionRange = 30 })
		end
		return
	end
	-- someone out in the open right behind him while he's at the door: forget the cupboard
	for _, p in visible do
		local r = rootOf(p)
		if r and (r.Position - pos()).Magnitude < 10 and engage({ p }) then
			S.SawHide[spot] = nil
			return
		end
	end
	if now() < d.Until then
		return
	end
	local occupant = ctx.Hiding.occupant(spot)
	local I = tune()
	local found = false
	if occupant then
		-- he saw you get in: he opens it and you're his. Otherwise he usually still finds you
		-- once he opens the right door, unless you hold your breath and keep still
		local chance = S.SawHide[spot] and I.SeeHideCheckChance or I.OpenFindChance
		if occupant:GetAttribute("HoldingBreath") and not S.SawHide[spot] then
			chance *= 1 - I.BreathHoldSave
		end
		found = math.random() < chance
	end
	S.SawHide[spot] = nil
	if found and occupant and grabFails(occupant) then
		patrol()
		return
	end
	if found and occupant then
		ctx.Audio.playAt("DoorYank", spot.Position, { CaptionText = "[The door is ripped open]", CaptionRange = 50 })
		ctx.Hiding.exit(occupant, true)
		if ctx.Capture.capture(occupant) then
			afterCapture(occupant)
		else
			patrol()
		end
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
	elseif d.Return == "Patrol" and d.ReturnData then
		setState("Patrol", d.ReturnData)
	else
		startHunt()
	end
end

--[[
	The DOORS-Figure brain (Config.Intruder.Brain = "Figure"): he hunts by SOUND.
		Patrol       room to room along a route, stopping to listen
		Investigate  a quiet noise (a door, a lock, the microwave): a growl, he walks over, then
		             paces round where it came from, and goes back to his patrol
		Charge       a loud one (anyone walking near him, running, glass, a slam): a roar and a
		             run straight at it, re-aimed at every new footstep he hears; then he thrashes
		             about where it was. Anyone he runs into, he grabs
		Inspect      someone hid near him (or he walks right past them breathing): he stops at that
		             hiding spot, sways, listens. The one inside plays the heartbeat minigame
		             (HeartbeatService). Fail it, or come out while he's there, and he has you.
	Louder (for him: the noise's reach minus its distance) beats quieter; he ignores everything
	while he's listening at a hiding spot.
]]

-- anyone in the open he walks right into
grabAnyone = function(): boolean
	local here = pos()
	local I = tune()
	for _, p in ctx.Util.activePlayers() do
		if valid(p) and not p:GetAttribute("Hiding") then
			local r = rootOf(p)
			if r and (r.Position - here).Magnitude <= I.GrabRange and math.abs(r.Position.Y - here.Y) < 5 then
				if tryGrab(p) then
					return true
				end
			end
		end
	end
	return false
end

-- pacing about where the noise came from: short dashes to points around it, turning, listening
local function erratic(d, center: Vector3, speed: number)
	if now() < (d.NextPoint or 0) and not S.Nav.Arrived then
		return
	end
	-- (somewhere around it he can walk to: never a point inside a wall or a wardrobe)
	local goal = NavGrid.randomNear(reachable(center), 2.5, 8)
	if not goal then
		local a = math.random() * math.pi * 2
		local r = 2 + math.random() * 6
		goal = reachable(center + V(math.cos(a) * r, 0, math.sin(a) * r))
	end
	S.Nav:goTo(goal :: Vector3, { Speed = speed, Tolerance = 1.5 })
	d.NextPoint = now() + 1 + math.random() * 1.2
end

local function growl()
	if now() - (S.LastGrowl or -1e9) > 4 and S.Head then
		S.LastGrowl = now()
		ctx.Audio.playAt("Growl", S.Head.Position, { Caption = true })
	end
end

charge = function(at: Vector3, who: Player?)
	if S.State == "Charge" then
		-- another footstep: re-aim, and if he'd started thrashing about, he runs again
		S.Data.Pos = at
		S.Data.Source = who or S.Data.Source
		S.Data.Searching = false
		return
	end
	setState("Charge", { Pos = at, Source = who })
	S.HuntTarget = who
	if who then
		S.LastFelt[who] = at
	end
	if now() - (S.LastRoar or -1e9) > 6 and S.Head then
		S.LastRoar = now()
		ctx.Audio.playAt("Roar", S.Head.Position, { Caption = true })
		if who and valid(who) then
			ctx.Remotes.Shake:FireClient(who, 0.5, 0.5)
			ctx.PlayerState.addNerve(who, -8)
		end
	end
	ctx.Director.addTension(12)
end

STATES.Charge = function(_, visible)
	local d = S.Data
	local I = tune()
	if engage(visible) then
		return
	end
	if grabAnyone() then
		return
	end
	local speed = I.ChargeSpeed + (S.Frenzy and 1 or 0)
	if not d.Searching then
		follow(d.Pos, speed)
		local off = d.Pos - pos()
		local arrived = V(off.X, 0, off.Z).Magnitude < 3.5 and math.abs(off.Y) < 6
		if arrived or (S.Nav.Arrived and off.Magnitude < 9) or S.Nav:isStuck() or now() - S.StateStart > 25 then
			-- whoever made it is hiding right here: he heard them get in
			local src = d.Source
			local spot = src and ctx.Hiding.spotOf(src)
			if spot and (spot.Position - pos()).Magnitude < 12 then
				inspect(spot)
				return
			end
			d.Searching = true
			d.SearchUntil = now() + I.ChargeSearchTime
			d.NextPoint = 0
			growl()
		end
		return
	end
	if now() >= d.SearchUntil then
		patrol()
		return
	end
	erratic(d, d.Pos, speed * 0.7)
end

STATES.Investigate = function(_, visible)
	if engage(visible) then
		return
	end
	local d = S.Data
	local I = tune()
	if figure() then
		if grabAnyone() then
			return
		end
		if not d.Started then
			d.Started = true
			S.Nav:goTo(reachable(d.Pos), { Speed = I.InvestigateSpeed, Tolerance = 3 })
		end
		if not d.Searching then
			if S.Nav.Arrived or S.Nav:isStuck() or now() - S.StateStart > 18 then
				d.Searching = true
				d.SearchUntil = now() + I.InvestigateSearchTime
				d.NextPoint = now() + 1.2 -- (a moment's stillness first: listening)
				S.Nav:stop()
			end
			return
		end
		if now() >= d.SearchUntil then
			patrol()
			return
		end
		erratic(d, d.Pos, I.PatrolSpeed)
		return
	end
	-- (classic brain)
	if huntTarget() then
		startHunt()
		return
	end
	if not d.Started then
		d.Started = true
		S.Nav:goTo(reachable(d.Pos), { Speed = I.ProwlSpeed - 2, Tolerance = 3 })
	end
	if now() - S.StateStart > 22 then
		patrol()
		return
	end
	if S.Nav.Arrived or S.Nav:isStuck() then
		if not d.LookUntil then
			d.LookUntil = now() + 1.6 + math.random() * 1.4
			d.LookFrom = now()
			S.Nav:stop()
			return
		end
		if now() < d.LookUntil then
			local k = (now() - d.LookFrom) / (d.LookUntil - d.LookFrom)
			local yaw = math.sin(k * math.pi * 2) * 1.2
			faceToward(pos() + (CFrame.Angles(0, yaw, 0) * (d.Pos - pos() + V(0.01, 0, 0.01))).Unit * 5)
			return
		end
		if not d.Checked then
			d.Checked = true
			local spot = searchSpot(d.Pos, d.Source, {})
			if spot and math.random() < 0.6 and now() >= (S.SpotCooldown[spot] or 0) then
				S.SpotCooldown[spot] = now() + 20
				checkSpot(spot, "Patrol", { Route = patrolRoute(), Index = 0 })
				return
			end
		end
		patrol()
	end
end

local function investigate(at: Vector3, source: Player?)
	if S.State == "Investigate" and S.Data.Pos and (S.Data.Pos - at).Magnitude < 8 then
		return -- (already on his way there)
	end
	setState("Investigate", { Pos = at, Source = source })
	S.HuntTarget = nil
	if figure() then
		growl()
	end
end

-- stop at a hiding spot and listen (the heartbeat minigame for whoever's inside)
inspect = function(spot)
	if not spot or S.State == "Inspect" or now() < (S.SpotCooldown[spot] or 0) then
		return
	end
	S.SpotCooldown[spot] = now() + 30
	setState("Inspect", { Spot = spot, Phase = "Approach" })
	S.HuntTarget = nil
	S.Nav:goTo(spot.Exit.Position, { Speed = tune().InvestigateSpeed, Tolerance = 2.5 })
end

local function ripOut(who: Player, spot)
	if grabFails(who) then
		patrol() -- (the owner can't be caught: they stay hidden, he gives up on the spot)
		return
	end
	ctx.Audio.playAt("DoorYank", spot.Position, { CaptionText = "[The door is ripped open]", CaptionRange = 50 })
	ctx.Hiding.exit(who, true)
	if ctx.Capture.capture(who) then
		S.Memory[who] = nil
		afterCapture(who)
	else
		patrol()
	end
end

STATES.Inspect = function(_, visible)
	local d = S.Data
	local spot = d.Spot
	local I = tune()
	if d.Phase == "Approach" then
		-- (someone right in front of him on the way: that comes first)
		for _, p in visible do
			local r = rootOf(p)
			if r and (r.Position - pos()).Magnitude < 9 and engage({ p }) then
				return
			end
		end
		if grabAnyone() then
			return
		end
		if S.Nav.Arrived or S.Nav:isStuck() or now() - S.StateStart > 12 then
			if (pos() - spot.Exit.Position).Magnitude > 7 then
				patrol() -- (couldn't get there)
				return
			end
			S.Nav:stop()
			faceToward(spot.Position)
			local dur = I.InspectTime[1] + math.random() * (I.InspectTime[2] - I.InspectTime[1])
			d.Phase = "Listen"
			d.Until = now() + dur
			ctx.Audio.playAt("ManWhisper", spot.Position, { CaptionText = "[Something right outside. Listening.]", CaptionRange = 18 })
			local who = ctx.Hiding.occupant(spot)
			d.Occupant = who
			if who and ctx.Heartbeat then
				ctx.Heartbeat.begin(who, dur, function()
					if S.State == "Inspect" and S.Data == d then
						d.Heard = true
					end
				end)
			end
		end
		return
	end
	-- listening at the door (he ignores everything else meanwhile)
	local who = d.Occupant
	if who then
		if ctx.Hiding.spotOf(who) ~= spot then
			-- they came out while he's standing right here
			d.Occupant = nil
			ctx.Heartbeat.stop(who)
			local r = rootOf(who)
			if valid(who) and r and (r.Position - pos()).Magnitude < 12 and tryGrab(who) then
				return
			end
			patrol()
			return
		end
		if d.Heard then
			d.Occupant = nil
			ripOut(who, spot)
			return
		end
	end
	if now() >= d.Until then
		-- nothing. He turns away and goes somewhere else
		S.SpotCooldown[spot] = now() + 40
		patrol()
	end
end

-- what he does about a noise he heard, depending on what he's doing
local function onNoise(ev)
	if ev.Kind == "Intruder" or ev.Kind == "Car" then
		return
	end
	local st = S.State
	local who = ev.Source
	if figure() then
		-- busy: listening at a hiding spot, carrying someone off, stunned, trapped, or he can see you
		if st == "Inspect" or st == "Retreat" or st == "Stunned" or st == "Trapped" or st == "Gone" or st == "Stopped" or st == "Chase" or st == "CheckSpot" then
			return
		end
		-- someone tied up in the boiler room: their breathing doesn't carry; struggling does, but it
		-- only brings him down to look now and then (he isn't going to sit down there)
		if who and who:GetAttribute("Captured") then
			if ev.Kind ~= "Struggle" or inCaptiveGrace() or now() - (S.LastCaptiveNoise or -1e9) < 60 then
				return
			end
			S.LastCaptiveNoise = now()
			if st ~= "Charge" then
				investigate(ev.Position, nil)
			end
			return
		end
		-- just after a capture, nothing from the basement brings him back down (the rescue window)
		if inCaptiveGrace() and ctx.Rooms.floorOf(ev.Position) == "Basement" then
			return
		end
		-- a hiding spot giving itself away (its door, a gasp, breathing): he goes and listens there
		local spot = who and ctx.Hiding.spotOf(who)
		if spot and (ev.Kind == "Hide" or ev.Kind == "Gasp" or ev.Kind == "Breathing") then
			S.HeardHide[spot] = now()
			inspect(spot)
			return
		end
		-- how loud it is where he stands; something quieter than what he's after doesn't distract him
		local reach = ev.Radius or 0
		if ctx.Rooms.floorOf(ev.Position) ~= ctx.Rooms.floorOf(pos()) then
			reach *= ctx.Config.Noise.FloorDropMultiplier
		end
		local loud = reach - (ev.Position - pos()).Magnitude
		local cur = S.Heard
		if cur and now() - cur.T < 3 and loud < cur.Loud - 3 and not (who ~= nil and who == cur.Source) then
			return
		end
		S.Heard = { Loud = loud, T = now(), Source = who }
		-- footsteps (walking or running near him) and anything big: he charges. Smaller: he looks
		local aggressive = ev.Kind == "Footsteps" or (ev.Radius or 0) >= 30 or ev.Kind == "Struggle" or ev.Kind == "Rescue" or ev.Kind == "Voice"
		if aggressive then
			charge(ev.Position, who)
		elseif st ~= "Charge" then
			investigate(ev.Position, who)
		end
		return
	end
	-- (classic brain)
	local spot = who and ctx.Hiding.spotOf(who)
	if spot and (ev.Kind == "Hide" or ev.Kind == "Gasp" or ev.Kind == "Breathing") then
		S.HeardHide[spot] = now()
		if (st == "Patrol" or st == "Investigate" or st == "Prowl" or st == "Search")
			and (spot.Position - pos()).Magnitude < 22 and now() >= (S.SpotCooldown[spot] or 0) then
			S.SpotCooldown[spot] = now() + 20
			if st == "Search" then
				checkSpot(spot, "Search", S.Data)
			else
				checkSpot(spot, "Patrol", { Route = patrolRoute(), Index = 0 })
			end
		end
		return
	end
	if st == "Patrol" then
		investigate(ev.Position, who)
	elseif st == "Search" and (ev.Radius or 0) >= 20 and S.Data.Pos and (ev.Position - S.Data.Pos).Magnitude > 14 then
		investigate(ev.Position, who)
	elseif st == "Withdraw" and ev.Kind ~= "Footsteps" and ev.Kind ~= "Breathing" and (ev.Radius or 0) >= 14
		and (ev.Position - pos()).Magnitude < 22 and (S.Data.Until or 0) - now() > 3 then
		investigate(ev.Position, who)
	end
end

--[[
	Walking right past someone's hiding spot: unless they're holding their breath, he may hear
	them (the more scared they are, the likelier). They're warned the moment he's close.
	Figure brain: he stops there and listens (heartbeat minigame). Classic: he opens it.
]]
local function listenForBreath(dt: number): boolean
	local here = pos()
	S.PassChecked = S.PassChecked or {}
	for _, p in ctx.Util.sessionPlayers() do
		local spot = p:GetAttribute("Hiding") and ctx.Hiding.spotOf(p)
		if spot and not p:GetAttribute("AdminGhost") then
			local off = spot.Position - here
			local dist = V(off.X, 0, off.Z).Magnitude
			local sameFloor = math.abs(off.Y) < 6
			if dist < 11 and sameFloor then
				if now() - (S.NearWarned[p] or -1e9) > 25 then
					S.NearWarned[p] = now()
					ctx.Director.think(p, "He's right outside. Hold your breath.|breath")
					ctx.PlayerState.addNerve(p, -6)
				end
			end
			if dist > 10 then
				S.PassChecked[spot] = nil
			end
			if dist < 6 and sameFloor and not p:GetAttribute("HoldingBreath") and now() >= (S.SpotCooldown[spot] or 0) then
				local nerve = math.clamp((tonumber(p:GetAttribute("Nerve")) or 100) / 100, 0, 1)
				if figure() then
					-- once per pass: does he hear them?
					if not S.PassChecked[spot] then
						S.PassChecked[spot] = true
						if math.random() < tune().InspectNearChance * (0.6 + 0.8 * (1 - nerve)) then
							S.HeardHide[spot] = now()
							inspect(spot)
							return true
						end
					end
				elseif math.random() < (0.1 + 0.35 * (1 - nerve)) * dt then
					S.SpotCooldown[spot] = now() + 25
					S.HeardHide[spot] = now()
					if S.State == "Search" then
						checkSpot(spot, "Search", S.Data)
					else
						checkSpot(spot, "Patrol", { Route = patrolRoute(), Index = 0 })
					end
					return true
				end
			end
		end
	end
	return false
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
	if now() - S.StateStart >= tune().StunTime then
		S.Humanoid.WalkSpeed = tune().WalkSpeed
		retreat(d.From, tune().RetreatAfterStun)
	end
end

STATES.Trapped = function()
	local d = S.Data
	local I = tune()
	local door = ctx.Doors.get("Basement")
	if not door then
		startHunt()
		return
	end
	if not door.Locked or door.IsOpen then
		S.Nav.DoorFilter = nil
		startHunt()
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
		startHunt()
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
			S.Nav:goTo(n.Pos, { Speed = tune().WalkSpeed })
		end
	end
end

---------------------------------------------------------------------------
-- Think loop
---------------------------------------------------------------------------
-- which gait the clients should animate (client/Controllers/Creature)
local function gaitFor(speed: number): string
	local st = S.State
	if st == "Stunned" then
		return "Stunned"
	elseif st == "CheckSpot" and S.Data.Phase == "Open" then
		return "Reach"
	elseif speed > 12 then
		return "Chase"
	elseif st == "Search" or st == "CheckSpot" then
		return "Search"
	elseif st == "Chase" and speed < 2 then
		return "Reach"
	elseif speed > 0.6 then
		return "Walk"
	elseif st == "Patrol" or st == "Investigate" or st == "Inspect" or st == "Charge" then
		-- stopped mid-sweep, or at your hiding spot: head turning, swaying, listening
		return "Search"
	elseif st == "Lurk" or st == "Withdraw" or st == "Ambush" then
		return "Stare"
	end
	return "Idle"
end

local function animate(dt: number)
	local v = S.Root.AssemblyLinearVelocity
	local speed = V(v.X, 0, v.Z).Magnitude
	if S.Tracks.Run then
		if speed > 12 then
			playTrack("Run", speed / 16)
		elseif speed > 0.6 then
			playTrack("Walk", math.max(speed / 9, 0.5))
		else
			playTrack("Idle", 1)
		end
	end
	local gait = gaitFor(speed)
	if S.Model:GetAttribute("Gait") ~= gait then
		S.Model:SetAttribute("Gait", gait)
	end
	-- his footsteps, in time with his stride: thunder when he runs, slow and heavy otherwise
	S.StepClock += dt
	local running = speed > 12
	local interval = running and math.max(3.75 / speed, 0.18) or math.max(2.6 / math.max(speed, 1), 0.3)
	if speed > tune().SneakSpeed + 0.5 and S.StepClock >= interval then
		S.StepClock = 0
		S.CaptionClock -= interval
		local caption = S.CaptionClock <= 0
		if caption then
			S.CaptionClock = running and 2 or 5
		end
		ctx.Audio.playAt("Footstep", pos() - V(0, 2.5, 0), {
			Volume = running and 1 or 0.5,
			Pitch = running and 0.72 or 0.8,
			Range = running and 95 or 40,
			Caption = caption,
			CaptionText = running and "[Heavy footsteps, running]" or "[Heavy footsteps]",
			CaptionRange = running and 70 or 28,
		})
	end
end

-- no real progress for a while (wedged, or a path that won't resolve), or idling in the
-- basement with nobody down there: he slips through the walls to the players' floor
unstick = function(state: string)
	local I = tune()
	local moving = state == "Prowl" or state == "Patrol" or state == "Search" or state == "Retreat" or state == "Investigate" or state == "Charge"
	local pr = S.Progress
	if not pr or (pos() - pr.Pos).Magnitude > 6 then
		S.Progress = { Pos = pos(), T = now() }
	elseif moving and now() - pr.T > I.StuckRelocate then
		S.Progress = { Pos = pos(), T = now() }
		if relocate() and state ~= "Prowl" and state ~= "Retreat" then
			patrol()
		end
		return
	end
	local room = ctx.Rooms.find(pos())
	local below = room ~= nil and room.Floor == "Basement"
	if below and state ~= "Trapped" and state ~= "Retreat" and state ~= "Chase" and state ~= "CheckSpot" and state ~= "Stunned" then
		local floors = playerFloors()
		if floors.Basement then
			S.BasementSince = nil
		else
			S.BasementSince = S.BasementSince or now()
			if now() - S.BasementSince > I.BasementIdle then
				S.BasementSince = nil
				if relocate() then
					patrol()
				end
			end
		end
	else
		S.BasementSince = nil
	end
end

local function think(dt: number)
	if S.State == "Lurk" and S.Model and not S.InHouse then
		STATES.Lurk(dt, {})
		return
	end
	if not S.Model or not S.InHouse then
		return
	end
	local state = S.State
	if state == "Offstage" or state == "Gone" or state == "Stopped" then
		return
	end
	animate(dt)
	if S.Mode == "Hunt" then
		recordTrails()
		unstick(state)
		state = S.State
	end
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
	-- he prefers the dark: passing through a lit, empty room nobody can see, he sometimes
	-- reaches for the switch (rooms go dark one by one while you're elsewhere)
	if (state == "Lurk" or state == "Withdraw" or state == "Prowl") and #visible == 0 and ctx.Power.isOn() then
		S.LightsClock = (S.LightsClock or 0) - dt
		if S.LightsClock <= 0 then
			S.LightsClock = 4
			local room = ctx.Rooms.find(pos())
			if room and ctx.Power.isRoomSwitchOn(room.Name) and math.random() < 0.35 then
				local occupied = false
				for _, p in ctx.Util.activePlayers() do
					local r = rootOf(p)
					if r and ctx.Rooms.find(r.Position) == room then
						occupied = true
					end
				end
				if not occupied and not Perception.anyoneSees(pos(), S.Model) then
					ctx.Power.setSwitch(room.Name, false)
					S.LightsClock = 45
					if ctx.Director.logTruthRaw and not S.LoggedLights then
						S.LoggedLights = true
						ctx.Director.logTruthRaw("The lights that kept going off in empty rooms were Curtis. He moves easier in the dark.")
					end
				end
			end
		end
	end
	-- passing right by someone's hiding spot: does he hear them breathing?
	if S.Mode == "Hunt" and (state == "Patrol" or state == "Search" or state == "Investigate" or state == "Prowl" or state == "Charge") then
		if listenForBreath(dt) then
			return
		end
	end
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
		S.JustEntered = spot -- (the first hunt shows him here: Cutscene.heComesDown)
		S.EnteredAt = now()
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
		-- hidden in the walls to begin with; he shows himself when he chooses
		ensureModel()
		park()
		setState("Lurk", { Phase = "Hidden", Until = now() + 18 + math.random() * 12 })
	elseif mode == "Hunt" then
		enterHouse(function()
			if S.Mode ~= "Hunt" or S.State == "Trapped" or S.State == "Gone" then
				return
			end
			-- already hunting: carry on
			if S.State == "Prowl" or S.State == "Chase" or S.State == "Search" or S.State == "CheckSpot" or S.State == "Withdraw" or S.State == "Ambush" or S.State == "Retreat" or S.State == "Stunned"
				or S.State == "Patrol" or S.State == "Investigate" or S.State == "Charge" or S.State == "Inspect" then
				return
			end
			startHunt()
			if cause and valid(cause) then
				S.HuntTarget = cause
			end
		end)
	end
end

-- (tests, and the Director if it ever wants a scare on cue) make his next appearance now
function Intruder.appearNow()
	if S.State == "Lurk" and S.Data.Phase == "Hidden" then
		S.Data.Until = 0
	end
end

-- something gave him away (a door he was holding shut): he runs for it
function Intruder.spook()
	if S.State == "Lurk" and S.InHouse and not S.Data.Bolting then
		bolt(S.Data)
	end
end

-- his head, for the capture jumpscare
function Intruder.getHead(): BasePart?
	return S.Head
end

-- (tests) his internal state, to simulate walking where there's no physics
-- a revived player: he can't feel them for a few seconds, and forgets where they were
function Intruder.grace(player: Player, seconds: number)
	if not S.Ignore or not S.Trails then
		return
	end
	S.Ignore[player] = now() + seconds
	S.Trails[player] = {}
	if S.HuntTarget == player then
		S.HuntTarget = nil
	end
end

-- a cutscene is playing: he stays exactly where he is for a while
function Intruder.hold(seconds: number)
	S.HoldUntil = math.max(S.HoldUntil or 0, now() + seconds)
	if S.Nav then
		S.Nav:stop()
	end
end

-- owner admin panel (AdminService) ------------------------------------------
function Intruder.adminFreeze(on: boolean)
	S.AdminFrozen = on or nil
	if on and S.Nav then
		S.Nav:stop()
	end
end

function Intruder.adminIsFrozen(): boolean
	return S.AdminFrozen == true
end

-- put him a few steps behind this player (in the house, hunting)
function Intruder.adminBring(player: Player): boolean
	local root = ctx.Util.getRoot(player)
	if not root or not S.Root then
		return false
	end
	if not S.InHouse then
		Intruder.setMode("Hunt")
		return true
	end
	local behind = root.CFrame * CFrame.new(0, 0, 12)
	if S.Nav then
		S.Nav:stop()
	end
	placeAt(behind.Position, root.Position)
	S.Progress = { Pos = pos(), T = now() }
	return true
end

function Intruder.adminHunt(player: Player?)
	Intruder.setMode("Hunt", player)
	if figure() and player and valid(player) and S.InHouse then
		local r = rootOf(player)
		if r then
			charge(r.Position, player)
		end
		return
	end
	if player and valid(player) then
		S.HuntTarget = player
		S.UnhidAt[player] = nil
		S.Ignore[player] = nil
	end
end

function Intruder._tune()
	return tune()
end

function Intruder._state()
	return S
end

-- out in the house, hunting (as opposed to hiding in the walls)
function Intruder.isHunting(): boolean
	return S.Mode == "Hunt" and S.InHouse == true
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

-- build him (offstage) ahead of time, so clients can show a copy of him (the opening shot)
function Intruder.prepare()
	ensureModel()
end

function Intruder.reset()
	S = fresh()
	workspace:SetAttribute("IntruderState", nil)
end

-- help is coming: he knows he's out of time. Shorter breaks between hunts, and he comes
-- straight for whoever made the call.
function Intruder.onHelpCalled(caller: Player?)
	if S.Mode == "Offstage" or S.Mode == "Stopped" or S.State == "Trapped" or S.State == "Gone" then
		return
	end
	S.Frenzy = true
	if S.Mode ~= "Hunt" or not S.InHouse then
		-- still hiding in the walls: not any more
		Intruder.setMode("Hunt", caller)
		return
	end
	ctx.Audio.caption("[A man screaming somewhere in the house]", pos(), 120)
	if figure() then
		-- the phone call / the knocking / the engine: he heard exactly where
		local r = caller and valid(caller) and rootOf(caller)
		if r and S.State ~= "Inspect" and S.State ~= "Retreat" and S.State ~= "Stunned" and S.State ~= "Trapped" then
			charge(r.Position, caller)
		end
		return
	end
	if S.State == "Withdraw" or S.State == "Lurk" or S.State == "Retreat" then
		startHunt()
	end
	if caller and valid(caller) then
		S.HuntTarget = caller
		S.UnhidAt[caller] = nil
	end
end

-- someone is trying the doors and windows: he hears it
function Intruder.onExitAttempt(position: Vector3, player: Player)
	if S.Mode ~= "Hunt" or not S.InHouse then
		return
	end
	-- (rattling the doors and windows is loud: Figure brain, he charges at it)
	if figure() then
		local st = S.State
		if st ~= "Inspect" and st ~= "Retreat" and st ~= "Stunned" and st ~= "Trapped" and st ~= "Chase" and st ~= "CheckSpot" then
			charge(position, player)
		end
		return
	end
	if S.State == "Withdraw" then
		startHunt()
	end
	if (S.State == "Prowl" or S.State == "Withdraw") and valid(player) and not player:GetAttribute("Hiding") then
		S.HuntTarget = player
		S.UnhidAt[player] = nil
		S.Ignore[player] = nil
		-- the noise gives the place away right now, not a few seconds late
		local tr = S.Trails[player]
		if tr then
			table.insert(tr, { T = now() - tune().SenseDelay, Pos = position })
		end
	end
end

-- someone's cutting a friend free in the boiler room: zip ties, whispering, a struggle. He hears it.
function Intruder.onRescueAttempt(position: Vector3, rescuer: Player)
	if S.Mode ~= "Hunt" or not S.InHouse or not S.Root then
		return
	end
	local st = S.State
	if st == "Chase" or st == "CheckSpot" or st == "Stunned" or st == "Trapped" or st == "Gone" or st == "Stopped" then
		return
	end
	if inCaptiveGrace() and ctx.Rooms.floorOf(position) == "Basement" then
		return -- (he's only just left them down there)
	end
	local reach = tune().RescueNoise
	if ctx.Rooms.floorOf(position) ~= ctx.Rooms.floorOf(pos()) then
		reach *= ctx.Config.Noise.FloorDropMultiplier
	end
	if (position - pos()).Magnitude > reach then
		return
	end
	if figure() then
		if st ~= "Inspect" and st ~= "Retreat" then
			charge(position, rescuer)
		end
		return
	end
	setState("Search", { Pos = position, Target = rescuer, Checked = {} })
	ctx.Audio.caption("[Heavy footsteps, coming this way]", position, 40)
end

-- he saw you get in (or heard it right next to him): he's coming to that exact spot
function Intruder.onPlayerHid(player: Player, spot)
	if not S.InHouse or not S.Root then
		return
	end
	if figure() then
		if S.Mode ~= "Hunt" then
			return
		end
		local st = S.State
		local busy = st == "Retreat" or st == "Stunned" or st == "Trapped" or st == "Gone" or st == "Stopped" or st == "Inspect" or st == "CheckSpot"
		if busy then
			return
		end
		-- he saw you get in: it's over. Close by (he heard the door): he comes and listens
		if table.find(S.Visible, player) then
			S.SawHide[spot] = true
			checkSpot(spot, "Patrol", { Route = patrolRoute(), Index = 0 })
		else
			local off = spot.Position - pos()
			if V(off.X, 0, off.Z).Magnitude < 14 and math.abs(off.Y) < 6 then
				S.HeardHide[spot] = now()
				inspect(spot)
			end
		end
		return
	end
	local heard = (spot.Position - pos()).Magnitude < 9
	if table.find(S.Visible, player) or heard then
		S.SawHide[spot] = true
		if S.Mode == "Hunt" and (S.State == "Prowl" or S.State == "Chase" or S.State == "Search" or S.State == "Withdraw" or S.State == "Ambush") then
			checkSpot(spot, "Search", { Pos = spot.Position, Target = player, Started = true, Checks = 1, Checked = { [spot] = true } })
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

-- survey the house for his routes (NavGrid), a little each frame, once the house is built
local function surveyHouse()
	task.spawn(function()
		task.wait(2)
		if NavGrid.ready() then
			return
		end
		local skip = {}
		for _, d in workspace:GetDescendants() do
			if d:IsA("Humanoid") and d.Parent then
				table.insert(skip, d.Parent)
			end
		end
		local t0 = os.clock()
		local ok, err = pcall(NavGrid.build, skip, 0.004)
		if not ok then
			warn("[Intruder] house survey failed, using PathfindingService: " .. tostring(err))
		elseif ctx.Config.Debug then
			print(("[Intruder] house surveyed in %.1fs"):format(os.clock() - t0), NavGrid.stats())
		end
	end)
end

function Intruder.start()
	surveyHouse()
	ctx.Noise.listen(function(ev)
		if not S.InHouse or not S.Root or S.Mode ~= "Hunt" then
			return
		end
		if ev.Kind == "Intruder" then
			return
		end
		-- (right next to him: only a player's own noises count; the rest is him)
		if (ev.Position - pos()).Magnitude < 8 and not (figure() and ev.Source) then
			return
		end
		if not ctx.Noise.heardAt(ev, pos()) then
			return
		end
		table.insert(S.Noises, ev)
		if #S.Noises > 20 then
			table.remove(S.Noises, 1)
		end
		-- something loud while he's lying low: the break is over
		if S.State == "Withdraw" and (ev.Radius or 0) >= 30 and S.Data.Until - now() > 4 then
			startHunt()
		end
		-- whoever made it is felt right away
		local who = ev.Source
		if who and valid(who) and S.Trails[who] and (S.State == "Prowl" or S.State == "Withdraw") then
			S.UnhidAt[who] = nil
			table.insert(S.Trails[who], { T = now() - tune().SenseDelay, Pos = ev.Position })
		end
		-- and what he does about it
		onNoise(ev)
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		-- (his feet every frame: he turns corners the moment he reaches them)
		if S.Nav and S.InHouse and not S.AdminFrozen and now() >= (S.HoldUntil or 0) and S.State ~= "Offstage" then
			local ok, err = pcall(S.Nav.update, S.Nav)
			if not ok then
				warn("[Intruder] nav: " .. tostring(err))
			end
		end
		acc += dt
		if acc < tune().ThinkRate then
			return
		end
		local step = acc
		acc = 0
		if S.AdminFrozen or now() < (S.HoldUntil or 0) then
			return -- (frozen by the owner's admin panel, or held still for a cutscene)
		end
		local ok, err = pcall(think, step)
		if not ok then
			warn("[Intruder] " .. tostring(err))
		end
	end)
end

return Intruder
