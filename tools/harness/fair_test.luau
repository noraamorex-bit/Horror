-- fair_test (v136, a player's downvote: "how is it scary but fair when the ghost can literally find you when you're standing
-- completely still and it's says it hears me also the protag won't shut the hell up every 1 minutes spilling some worthless
-- info"): 1) someone who keeps still (Intruder.StillAfter s) isn't run at exactly: his run goes StillMiss studs off and
-- doesn't follow them while they stay still; 2) moving, he's right on them; 3) his run lines come at most every
-- Thoughts.RunLineGap s; 4) the task reminders back off (five minutes of hunting: a handful at most).
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
		if line then
			local list = players == nil and { a, b } or (type(players) == "table" and players or { players })
			for _, p in list do table.insert(thoughts, { p, line, T }) end
		end
		return think(players, line, ...)
	end
	local function count(p, pred)
		local n = 0
		for _, t in thoughts do if t[1] == p and pred(t[2]) then n += 1 end end
		return n
	end
	ctx.Director.startAct("Guest")
	tick(3)
	local I = ctx.Intruder
	local S = I._state()
	assert(S.InHouse, "in the house")
	local tune = I._tune()
	local Hunt = ctx.Story.Hunt
	S.NextSense = 1e12
	S.NextPursue = 1e12
	local function patrolling(at)
		S.State = "Patrol"; S.Data = { Route = {}, Index = 0, Moving = true, PauseUntil = 1e12 }; S.Heard = nil
		if at then S.Root.CFrame = R.CFrame.new(at) end
	end
	ctx.Util.getRoot(b).CFrame = R.CFrame.new(R.Vector3.new(0, 300, 400))
	b:SetAttribute("InGame", nil)
	S.Spared, S.LeftAlone = {}, {}
	-- a in the open on the ground floor, him far off across the house
	local aRoot = ctx.Util.getRoot(a)
	local spotA = R.Vector3.new(2, 4, -18)          -- (the front hall)
	aRoot.CFrame = R.CFrame.new(spotA)
	patrolling(R.Vector3.new(40, 4, 20))

	-- 1) keeping still: his quiet run goes to a guess StillMiss off, not to her feet
	tick(math.max(0, (S.HoldUntil or 0) - T) + 0.3) -- (his entrance holds him a few seconds)
	tick(tune.StillAfter + 0.5)
	assert(I._keepingStill(a), "she's kept still " .. tune.StillAfter .. " s")
	S.NextPursue = T - 1
	tick(0.1)
	assert(S.State == "Charge" and S.Data.Homing == a, "he runs after her, got " .. S.State)
	local miss = (S.Data.Pos - aRoot.Position)
	local flat = R.Vector3.new(miss.X, 0, miss.Z).Magnitude
	assert(math.abs(flat - tune.StillMiss) < 0.5, ("a guess %d studs off, got %.1f"):format(tune.StillMiss, flat))
	-- ...and while she stays still he doesn't follow her
	local guess = S.Data.Pos
	tick(1.0)
	if S.State == "Charge" then
		assert((S.Data.Pos - guess).Magnitude < 0.01, "no re-aim at someone keeping still")
	end
	print(("still: his run went %.1f studs off"):format(flat))

	-- 2) moving: he's on her exactly
	patrolling(R.Vector3.new(40, 4, 20))
	aRoot.CFrame = R.CFrame.new(spotA + R.Vector3.new(4, 0, 0))
	S.NextPursue = T - 1
	tick(0.1)
	assert(not I._keepingStill(a), "she moved")
	assert(S.State == "Charge" and (S.Data.Pos - aRoot.Position).Magnitude < 1, "moving: he runs at exactly where she is")
	print("moving: his run goes right at her")

	-- 3) the run lines: "He's after me" at most every RunLineGap s, however often he runs
	local gap = ctx.Config.Thoughts.RunLineGap
	local n0 = count(a, function(l) return l == Hunt.Pursued end)
	for _ = 1, 6 do
		patrolling(R.Vector3.new(40, 4, 20))
		aRoot.CFrame = R.CFrame.new(spotA + R.Vector3.new(math.random() * 6, 0, 0))
		S.PursueTold = {}
		S.NextPursue = T - 1
		tick(8)
	end
	local n1 = count(a, function(l) return l == Hunt.Pursued end)
	assert(n1 - n0 <= 1, ("one run line in ~48 s (gap %d), got %d"):format(gap, n1 - n0))
	print(("run lines: %d in 48 s of runs"):format(n1 - n0))

	-- 4) the task reminders back off: in five minutes of hunting with nothing done, a handful at most
	S.NextPursue, S.NextSense = 1e12, 1e12
	ctx.Intruder.isHunting = function() return true end
	local startT = T
	local before = #thoughts
	for _ = 1, 300 do
		patrolling(R.Vector3.new(40, 4, 20))
		tick(1)
	end
	local hints = 0
	for i = before + 1, #thoughts do
		local t = thoughts[i]
		if t[1] == a and (string.find(t[2], "What next", 1, true)) then hints += 1 end
	end
	assert(hints <= 3, "at most 3 \"What next\" reminders in 5 min, got " .. hints)
	print(("reminders: %d in %d s"):format(hints, math.floor(T - startT)))
end)
print(ok and "FAIR OK" or ("FAIR FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
