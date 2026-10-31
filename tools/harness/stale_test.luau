-- stale_test (v125, a player: "you can literally just hide and wait 2 mins and you've won"):
-- 1) a hiding spot goes stale: camp one spot Config.Intruder.HideStale seconds and a thought warns you
--    first, then he comes and listens at it (the heartbeat); get through that and stay put, and
--    HideStaleAgain seconds after he walked off he's back and rips it open. Moving spots resets it.
-- 2) the police arriving is a last run, not the end: the front door opens, he goes for whoever is
--    still inside (hidden or not), out on the porch is out, and after Config.Help.FinalRun the police
--    come in (the night ends "Sirens").
local H = require("./env")
local T = 1000
H.clock = function() return T end
H.schedule = true
function H.flush(sec) for _ = 1, math.ceil(sec / 0.1) do T += 0.1; H.runDue() end end
local function setup()
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Rooms = H.load("RS/Shared/Rooms")
	ctx.Sounds = H.load("RS/Shared/Sounds")
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Util = H.load("RS/Shared/Util")
	ctx.Builder = H.load("Server/World/Builder")
	ctx.Layout = H.load("Server/World/Layout")
	local fired = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { FireClient = function(_, p, a) table.insert(fired, { k, p, a }) end, FireAllClients = function(_, a) table.insert(fired, { k, "all", a }) end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService", "Revive=ReviveService", "Admin=AdminService", "Cutscene=CutsceneService", "Heartbeat=HeartbeatService" }
	local names = {}
	for _, name in ORDER do
		local key, file = name:match("(%w+)=(%w+)")
		ctx[key] = H.load("Server/Services/" .. file)
		table.insert(names, key)
	end
	ctx.World = H.load("Server/World/World")
	ctx.Director = H.load("Server/Director/Director")
	ctx.Intruder = H.load("Server/Intruder/Intruder")
	for _, k in { "World", "Director", "Intruder" } do table.insert(names, k) end
	for _, k in names do if ctx[k].init then ctx[k].init(ctx) end end
	ctx.World.build()
	ctx.restart = function() end
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	return ctx, fired
end
local function mkPlayer(name, id)
	local p = H.wrap(H.roblox.Instance.new("Player"))
	p.Name = name
	rawset(p, "UserId", id)
	local char = H.Instance.new("Model")
	local rootPart = H.Instance.new("Part", char)
	rootPart.Name = "HumanoidRootPart"
	local hum = H.Instance.new("Humanoid", char)
	hum.Health = 100
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	p:SetAttribute("InGame", true)
	return p
end
local ok, err = pcall(function()
	H.services.RunService.IsStudio = function() return false end
	local ctx, fired = setup()
	local R = H.roblox
	local a, b = mkPlayer("A", 1), mkPlayer("B", 2)
	H.services.Players.GetPlayers = function() return { a, b } end
	local function tick(sec) for _ = 1, math.floor(sec * 10 + 0.5) do H.services.RunService.Heartbeat:Fire(0.1); T += 0.1; H.runDue() end end
	local thoughts = {}
	local think = ctx.Director.think
	ctx.Director.think = function(players, line, ...)
		table.insert(thoughts, { players, line })
		return think(players, line, ...)
	end
	local function thought(p, line)
		for _, t in thoughts do
			local list = t[1]
			local hit = list == p or (type(list) == "table" and table.find(list, p))
			if hit and t[2] == line then return true end
		end
		return false
	end
	ctx.Director.adminStart("Normal")
	ctx.Director.startAct("Guest")
	tick(3)
	local I = ctx.Intruder
	local S = I._state()
	assert(S.InHouse, "in the house")
	local tune = I._tune()
	local Hunt = ctx.Story.Hunt
	S.NextSense = 1e12 -- (v126's sense sprint off for the stale checks: section 4 tests it)
	S.NextPursue = 1e12 -- (v127's constant pursuit too: section 5)
	local function patrolling(at)
		S.State = "Patrol"; S.Data = { Route = {}, Index = 0, Moving = true, PauseUntil = 1e12 }; S.Heard = nil
		if at then S.Root.CFrame = R.CFrame.new(at) end
	end
	-- two hiding spots on the ground floor, far apart
	local spots = {}
	for _, s in ctx.Hiding.all() do
		if s.Exit and math.abs(s.Position.Y - 1) < 6 then table.insert(spots, s) end
	end
	assert(#spots >= 3, "hiding spots on the ground floor")
	local spot, spot2, spot3 = spots[1], nil, nil
	for _, s in spots do
		if not spot2 and (s.Position - spot.Position).Magnitude > 25 then spot2 = s
		elseif spot2 and not spot3 and (s.Position - spot.Position).Magnitude > 25 and (s.Position - spot2.Position).Magnitude > 25 then spot3 = s end
	end
	assert(spot2 and spot3, "three spots apart")
	-- b well out of the way, standing still (so he has nobody to chase)
	ctx.Util.getRoot(b).CFrame = R.CFrame.new(R.Vector3.new(0, 300, 400))
	b:SetAttribute("InGame", nil)

	-- 1) camping one spot: the warning, then he comes to listen
	local far = spot.Position + R.Vector3.new(0, 0, 0)
	patrolling(spot2.Exit.Position + R.Vector3.new(60, 0, 0))
	ctx.Hiding.enter(a, spot)
	assert(S.State == "Patrol", "hid far from him: nothing yet, got " .. S.State)
	-- (the clock starts on his first look once he's hunting)
	for _ = 1, 100 do
		if S.HideStale[a] then break end
		tick(0.1)
	end
	assert(S.HideStale[a], "he's timing the spot")
	local since = S.HideStale[a].Since
	tick(since + tune.HideStale - tune.HideStaleWarn - 1 - T)
	assert(not thought(a, Hunt.Stale), "no warning before " .. (tune.HideStale - tune.HideStaleWarn) .. " s")
	tick(2)
	assert(thought(a, Hunt.Stale), "the stale warning comes " .. tune.HideStaleWarn .. " s before")
	assert(S.State ~= "Inspect", "...and he isn't there yet")
	-- (keep him patrolling far away meanwhile: no chance encounter)
	patrolling(spot2.Exit.Position + R.Vector3.new(60, 0, 0))
	-- (no physics here: put him in the next room so his walk there "arrives")
	tick(since + tune.HideStale - 0.3 - T)
	assert(S.State == "Patrol", "not yet")
	patrolling(spot.Exit.Position + R.Vector3.new(0, 0, 3))
	a:SetAttribute("HoldingBreath", true) -- (so it's the stale visit, not him hearing her breathe as he passes)
	tick(0.6)
	a:SetAttribute("HoldingBreath", nil)
	assert(S.HideStale[a].Stage == 1, "the stale visit")
	assert(S.State == "Inspect" and S.Data.Spot == spot, "camped " .. tune.HideStale .. " s: he comes to listen, got " .. S.State)
	print("stale warning + inspect ok")
	-- he listened and walked off (say she passed the heartbeat): the second warning, then he's back to rip it open
	patrolling(spot2.Exit.Position + R.Vector3.new(60, 0, 0))
	tick(0.2)
	assert(thought(a, Hunt.StaleAfter), "after he walks off: 'he's coming back. MOVE.'")
	tick(tune.HideStaleAgain - 2)
	assert(S.State == "Patrol", "not before HideStaleAgain")
	patrolling(spot.Exit.Position + R.Vector3.new(0, 0, 3))
	a:SetAttribute("HoldingBreath", true)
	tick(2.5)
	a:SetAttribute("HoldingBreath", nil)
	assert(S.State == "CheckSpot" and S.Data.Spot == spot, "stayed put: he comes to open it, got " .. S.State)
	S.Root.CFrame = R.CFrame.new(spot.Exit.Position)
	for _ = 1, 60 do
		tick(0.1)
		if a:GetAttribute("Captured") then break end
	end
	assert(a:GetAttribute("Captured"), "camped through both warnings: caught")
	assert(a:GetAttribute("CaughtHow") == "Hiding", "caught in hiding")
	print("stale second visit rips it open ok")

	-- 2) moving spots resets the clock
	ctx.Capture.release(a)
	a:SetAttribute("Captured", nil)
	tick(1)
	patrolling(spot.Exit.Position + R.Vector3.new(60, 0, 0))
	ctx.Hiding.enter(a, spot2)
	tick(tune.HideStale - 10)
	ctx.Hiding.exit(a)
	ctx.Hiding.enter(a, spot3)
	patrolling(spot.Exit.Position + R.Vector3.new(60, 0, 0))
	tick(12)
	assert(S.State == "Patrol", "a new spot: the clock starts again, got " .. S.State)
	ctx.Hiding.exit(a)
	print("moving resets ok")

	-- 4) (v126) he knows where you are: every SenseEvery s he sprints at someone's current position. Out in
	--    the open: a charge at SenseSpeed that keeps re-aiming at them. Hiding: straight to their spot to listen
	do
		b:SetAttribute("InGame", true)
		local aRoot, bRoot = ctx.Util.getRoot(a), ctx.Util.getRoot(b)
		aRoot.CFrame = R.CFrame.new(spot.Exit.Position + R.Vector3.new(0, 3, 0))
		bRoot.CFrame = R.CFrame.new(R.Vector3.new(0, 300, 400))
		b:SetAttribute("InGame", nil)
		patrolling(spot2.Exit.Position + R.Vector3.new(40, 0, 0))
		S.SensedAt = {}
		S.Spared, S.LeftAlone = {}, {} -- (she was freed in section 1: her FreedGrace would hide her from him)
		S.NextSense = T - 1
		tick(0.2)
		assert(S.State == "Charge" and S.Data.Homing == a and S.Data.Speed == tune.SenseSpeed, "he sprints at her, got " .. S.State)
		assert(thought(a, Hunt.Sensed), "she's told he's coming")
		-- (the first run of the night plays the HeKnows cutscene: his face, the scream; he's held for it)
		local cut = false
		for _, f in fired do if f[1] == "Cutscene" and type(f[3]) == "table" and f[3].Name == "HeKnows" then cut = true end end
		assert(cut, "the first run of the night: the HeKnows cutscene")
		tick(4.5)
		assert(S.State == "Charge" and S.Data.Homing == a, "after the cutscene he goes, got " .. S.State)
		-- she moves: he re-aims at where she is now
		aRoot.CFrame = R.CFrame.new(spot3.Exit.Position + R.Vector3.new(0, 3, 0))
		tick(0.7)
		assert(S.State == "Charge" and (S.Data.Pos - aRoot.Position).Magnitude < 1, "re-aimed at her new position")
		-- next time she's hiding: he runs to her spot and listens
		ctx.Hiding.enter(a, spot3)
		-- (no physics here: he's put a few steps from her spot so his run there "arrives")
		patrolling(spot3.Exit.Position + R.Vector3.new(0, 0, 3))
		a:SetAttribute("HoldingBreath", true)
		S.SensedAt = {}
		S.NextSense = T - 1
		tick(0.2)
		a:SetAttribute("HoldingBreath", nil)
		assert(S.State == "Inspect" and S.Data.Spot == spot3, "hiding: straight to her spot, got " .. S.State)
		assert(thought(a, Hunt.SensedHiding), "and she's told")
		assert(S.NextSense > T + tune.SenseEvery[1] - 1, "the next one in SenseEvery s")
		ctx.Hiding.exit(a)
		S.NextSense = 1e12
		patrolling(spot.Exit.Position + R.Vector3.new(60, 0, 0))
		print("sense sprint ok")
	end

	-- 5) (v127) always after someone: with nothing else to do, PursueGap s later he's running after one of you
	do
		local aRoot = ctx.Util.getRoot(a)
		aRoot.CFrame = R.CFrame.new(spot.Exit.Position + R.Vector3.new(0, 3, 0))
		S.Spared, S.LeftAlone = {}, {}
		patrolling(spot2.Exit.Position + R.Vector3.new(40, 0, 0))
		S.PursueTarget = nil
		S.NextPursue = T - 1
		local said = 0
		for _, f in fired do if f[1] == "HisVoice" then said += 1 end end
		tick(0.2)
		assert(S.State == "Charge" and S.Data.Homing == a and S.Data.Speed == tune.PursueSpeed, "patrolling with nothing to do: after her, got " .. S.State)
		assert(tune.PursueSpeed < tune.SenseSpeed and tune.PursueSpeed > ctx.Config.Movement.Walk, "quiet runs: under the sense sprint, over your walk")
		assert(thought(a, Hunt.Pursued), "she's told, quietly")
		-- done with that run: back on her within PursueGap, not patrolling
		patrolling(spot2.Exit.Position + R.Vector3.new(40, 0, 0))
		tick(tune.PursueGap + 0.3)
		assert(S.State == "Charge" and S.Data.Homing == a, "and again within PursueGap s, got " .. S.State)
		-- after PursueFor s on her, he switches to whoever he went for longest ago (b, put in play)
		b:SetAttribute("InGame", true)
		ctx.Util.getRoot(b).CFrame = R.CFrame.new(spot3.Exit.Position + R.Vector3.new(0, 3, 0))
		S.PursueUntil = T - 1
		patrolling(spot2.Exit.Position + R.Vector3.new(40, 0, 0))
		S.NextPursue = T - 1
		tick(0.2)
		assert(S.State == "Charge" and S.Data.Homing == b, "then the other one, got " .. tostring(S.Data.Homing))
		b:SetAttribute("InGame", nil)
		S.NextPursue = 1e12
		S.PursueTarget = nil
		patrolling(spot.Exit.Position + R.Vector3.new(60, 0, 0))
		print("constant pursuit ok")
	end

	-- 6) (v128) who his runs pick: anyone not caught yet before anyone on their last life (Normal), and
	--    someone just freed is left alone FreedLeaveAlone s past their grace
	do
		b:SetAttribute("InGame", true)
		local aRoot, bRoot = ctx.Util.getRoot(a), ctx.Util.getRoot(b)
		aRoot.CFrame = R.CFrame.new(S.Root.Position + R.Vector3.new(4, 0, 0))
		bRoot.CFrame = R.CFrame.new(S.Root.Position + R.Vector3.new(60, 0, 0))
		S.Spared, S.LeftAlone, S.SensedAt = {}, {}, {}
		a:SetAttribute("NightCaught", 1)
		b:SetAttribute("NightCaught", 0)
		assert(I._runTarget() == b, "last life last: the one not caught yet, though she's further")
		a:SetAttribute("NightCaught", 0)
		assert(I._runTarget() == a, "both uncaught: the closest")
		I.spare(a, 5, true)
		assert(I._runTarget() == b, "spared: not her")
		-- (both well away from him while the clock runs: no physics, he'd only have to turn round to grab her)
		aRoot.CFrame = R.CFrame.new(S.Root.Position + R.Vector3.new(0, 300, 400))
		bRoot.CFrame = R.CFrame.new(S.Root.Position + R.Vector3.new(0, 300, -400))
		S.NextSense, S.NextPursue = 1e12, 1e12
		tick(6)
		assert(I._runTarget() == b, "grace over, still left alone")
		b:SetAttribute("InGame", nil)
		assert(I._runTarget() == nil, "nobody else: he still leaves her be")
		tick(tune.FreedLeaveAlone)
		assert(I._runTarget() == a, "then she's fair game again")
		I.spare(a, 5) -- (not a release: a caller's head start)
		tick(6)
		assert(I._runTarget() == a, "a plain head start isn't left alone")
		a:SetAttribute("NightCaught", nil)
		b:SetAttribute("NightCaught", nil)
		S.Spared, S.LeftAlone, S.SensedAt = {}, {}, {}
		print("run targets ok")
	end

	-- 7) (v129) he chases someone on their first night a little slower (Normal); veterans as before
	do
		b:SetAttribute("InGame", true)
		a:SetAttribute("StatNights", 0)
		b:SetAttribute("StatNights", 3)
		local rookie, vet = I._chaseSpeed(a), I._chaseSpeed(b)
		assert(math.abs(vet - rookie - tune.RookieChaseSlowdown) < 1e-6 and tune.RookieChaseSlowdown > 0, "a first-nighter: slower")
		assert(rookie > ctx.Config.Movement.Walk, "still faster than your walk")
		assert(I._chaseSpeed(a, true) > rookie, "the lunge is still faster")
		assert(ctx.Config.Difficulty.Hard.Intruder.RookieChaseSlowdown == 0, "not on Hard")
		a:SetAttribute("StatNights", nil)
		b:SetAttribute("StatNights", nil)
		b:SetAttribute("InGame", nil)
		print("rookie chase ok")
	end

	-- 3) the police: the last run for the front door
	b:SetAttribute("InGame", true)
	ctx.Util.getRoot(b).CFrame = R.CFrame.new(spot3.Exit.Position + R.Vector3.new(0, 3, 0))
	patrolling(spot.Exit.Position)
	ctx.Escape.callForHelp("Cell", a)
	ctx.Escape.finalRun()
	assert(ctx.Escape.isFinalRun(), "final run on")
	do
		local cut = false
		for _, f in fired do if f[1] == "Cutscene" and type(f[3]) == "table" and f[3].Name == "PoliceHere" then cut = true end end
		assert(cut, "the PoliceHere cutscene")
	end
	local door = ctx.Doors.get("FrontDoor")
	assert(door.IsOpen and not door.Locked, "the front door is open")
	assert(type(H.workspaceRoot:GetAttribute("FinalRunEnd")) == "number", "GET OUT timer on the HUD")
	assert(I.isFinalRun(), "he knows it's over")
	local any = false
	for _, f in fired do if f[1] == "Notify" and f[3] == Hunt.FinalNotice then any = true end end
	assert(any, "everyone told: GET OUT THE FRONT DOOR")
	-- b hides; a stays in the open far away: he goes for whoever's nearest, hidden or not
	ctx.Hiding.enter(b, spot3)
	S.Root.CFrame = R.CFrame.new(spot3.Exit.Position + R.Vector3.new(0, 0, 3))
	b:SetAttribute("HoldingBreath", true) -- (no physics: he's put beside it; not him hearing her breathe)
	ctx.Util.getRoot(a).CFrame = R.CFrame.new(spot.Exit.Position + R.Vector3.new(0, 3, 0))
	S.State = "Patrol"; S.Data = { Route = {}, Index = 0, Moving = true, PauseUntil = 1e12 }
	local went = false
	-- (v126: the PoliceHere cutscene holds him a few seconds first)
	for _ = 1, math.floor((ctx.Config.Help.FinalRunGrace + 10) * 10) do
		tick(0.1)
		if S.State == "CheckSpot" and S.Data.Spot == spot3 then went = true end
	end
	assert(went, "hiding during the last run: he goes straight to your spot")
	assert(b:GetAttribute("Captured"), "...and has her")
	b:SetAttribute("HoldingBreath", nil)
	-- a reaches the porch: out
	ctx.Util.getRoot(a).CFrame = R.CFrame.new(door.Position + R.Vector3.new(0, 0, -6))
	tick(0.5)
	assert(a:GetAttribute("Escaped") == "FrontDoor", "out the front door = out")
	-- (b is zip-tied, a is out: nobody left inside, so the police come in now and find her)
	tick(0.5)
	assert(ctx.Ending.isOver(), "nobody left inside: the police come in")
	local kind = H.workspaceRoot:GetAttribute("EndingActive")
	assert(kind == "Sirens" or kind == "CaseClosed", "Sirens ending, got " .. tostring(kind))
	print("final run ok")
end)
if not ok then
	print("FAIL: " .. tostring(err))
	return
end
print("stale_test OK")
