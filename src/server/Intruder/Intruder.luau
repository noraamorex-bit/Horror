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
	hum.WalkSpeed = ctx.Config.Intruder.WalkSpeed
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
	if ctx.Capture.capture(target) then
		S.Memory[target] = nil
		S.HuntTarget = nil
		local boiler = ctx.Rooms.ByName.Boiler
		retreat(nil, ctx.Config.Intruder.RetreatAfterCapture, boiler and V(boiler.Center.X, -10, boiler.Center.Z) or nil)
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
			if S.WasHidden[p] then
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
	local r = rootOf(p)
	if r and table.find(S.Visible, p) then
		return r.Position
	end
	local I = ctx.Config.Intruder
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
	S.Nav:goTo(spot.Exit.Position, { Speed = ctx.Config.Intruder.ProwlSpeed, Tolerance = 2.5, Hurry = true })
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
			elseif target and ctx.Hiding.occupant(s) == target then
				w = ctx.Config.Intruder.TrueSpotWeight
			end
			table.insert(entries, { s, w })
		end
	end
	return ctx.Util.weighted(entries)
end

-- a new hunt: a door slams somewhere, and he starts running
local function startHunt()
	setState("Prowl", {})
	S.HuntTarget = nil
	S.Waves += 1
	ctx.Audio.playAt("DoorSlam", pos(), { CaptionText = "[A door SLAMS somewhere in the house]", CaptionRange = 200 })
	local H = ctx.Story.Hunt
	if S.Waves == 1 then
		for _, line in H.First do
			ctx.Director.think(nil, line)
		end
		ctx.Remotes.Notify:FireAllClients(H.FirstNotice, "danger")
	elseif math.random() < 0.5 then
		ctx.Director.think(nil, ctx.Util.choice(H.Wave))
	end
end

-- he lets the house go quiet: walks off somewhere dark and waits, listening
local function withdraw()
	local I = ctx.Config.Intruder
	local dur = I.WithdrawMin + math.random() * (I.WithdrawMax - I.WithdrawMin)
	if S.Frenzy then
		dur *= 0.5
	end
	-- alone, you get a little longer to get things done
	if #ctx.Util.sessionPlayers() <= 1 then
		dur *= 1.3
	end
	local goal = farNode()
	local boiler = ctx.Rooms.ByName.Boiler
	if ctx.Capture.captiveCount() > 0 and now() - S.LastCaptiveCheck > I.CaptiveCheckInterval and boiler then
		S.LastCaptiveCheck = now()
		goal = V(boiler.Center.X + 4, -10, boiler.Center.Z)
	end
	setState("Withdraw", { Until = now() + dur })
	S.HuntTarget = nil
	S.Nav:goTo(goal, { Speed = I.WalkSpeed })
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
	local I = ctx.Config.Intruder
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
	local I = ctx.Config.Intruder
	-- the one he was after just vanished into a hiding spot: search where he last felt them
	local was = S.HuntTarget
	if was and valid(was) and was:GetAttribute("Hiding") and S.LastFelt[was] then
		setState("Search", { Pos = S.LastFelt[was], Target = was, Checked = {} })
		S.HuntTarget = nil
		return
	end
	local target, at = huntTarget()
	if not target or not at then
		-- nobody to feel (all hidden, or just out of hiding): he gives up for now
		if now() - S.StateStart > 2 then
			withdraw()
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
	local I = ctx.Config.Intruder
	if not valid(t) then
		startHunt()
		return
	end
	if t:GetAttribute("Hiding") then
		-- hid out of his sight (in sight, onPlayerHid already sent him to that spot)
		setState("Search", { Pos = d.LastPos or pos(), Target = t, Checked = {} })
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
		-- lost sight: back on the trail
		S.HuntTarget = t
		setState("Prowl", {})
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
	local I = ctx.Config.Intruder
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
		withdraw()
	end
end

--[[
	Withdraw: the house goes quiet. He walks off somewhere dark and waits. This is the time to
	move. Run into him (or into his sight up close) and it's over early.
]]
STATES.Withdraw = function(_, visible)
	local d = S.Data
	local I = ctx.Config.Intruder
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
		-- nobody out to hunt: keep waiting, quietly
		if huntTarget() then
			startHunt()
		else
			d.Until = now() + 4 + math.random() * 4
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
	if now() < d.Until then
		return
	end
	local occupant = ctx.Hiding.occupant(spot)
	local I = ctx.Config.Intruder
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
	if found and occupant then
		ctx.Audio.playAt("DoorYank", spot.Position, { CaptionText = "[The door is ripped open]", CaptionRange = 50 })
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
		startHunt()
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

STATES.Trapped = function()
	local d = S.Data
	local I = ctx.Config.Intruder
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
			S.Nav:goTo(n.Pos, { Speed = ctx.Config.Intruder.WalkSpeed })
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
	elseif st == "Lurk" or st == "Withdraw" then
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
	if speed > ctx.Config.Intruder.SneakSpeed + 0.5 and S.StepClock >= interval then
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
	S.Nav:update()
	animate(dt)
	if S.Mode == "Hunt" then
		recordTrails()
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
			if S.State == "Prowl" or S.State == "Chase" or S.State == "Search" or S.State == "CheckSpot" or S.State == "Withdraw" or S.State == "Retreat" or S.State == "Stunned" then
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
			table.insert(tr, { T = now() - ctx.Config.Intruder.SenseDelay, Pos = position })
		end
	end
end

-- he saw you get in (or heard it right next to him): he's coming to that exact spot
function Intruder.onPlayerHid(player: Player, spot)
	if not S.InHouse or not S.Root then
		return
	end
	local heard = (spot.Position - pos()).Magnitude < 9
	if table.find(S.Visible, player) or heard then
		S.SawHide[spot] = true
		if S.Mode == "Hunt" and (S.State == "Prowl" or S.State == "Chase" or S.State == "Search" or S.State == "Withdraw") then
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
		-- something loud while he's lying low: the break is over
		if S.State == "Withdraw" and (ev.Radius or 0) >= 30 and S.Data.Until - now() > 4 then
			startHunt()
		end
		-- whoever made it is felt right away
		local who = ev.Source
		if who and valid(who) and S.Trails[who] and (S.State == "Prowl" or S.State == "Withdraw") then
			S.UnhidAt[who] = nil
			table.insert(S.Trails[who], { T = now() - ctx.Config.Intruder.SenseDelay, Pos = ev.Position })
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
