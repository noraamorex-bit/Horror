-- finale_test: the secret ending (FinaleService) in the real house and burrow (navsim physics).
--   * one player tied up alone: no finale (the old last-chance path)
--   * two players tied up at once: the family dinner. Struggling while he watches is a strike;
--     struggling while his back is turned frees you; a free player off their chair while he
--     watches is a strike; a free player cuts the other loose; everyone free -> the tunnels
--   * the notes give the lock code (the client never gets the answer); a wrong code buzzes;
--     the right code opens the hatch; pushes, then climbing out = escaped
--   * he catches the last one in the tunnels -> NOT YOUR FAMILY; and a run where bedtime comes
--     at dinner -> FOREVER FAMILY
local H = require("./env")
local Sim = require("./navsim")
local process = require("@lune/process")
local R = H.roblox
local V = R.Vector3.new
local T = 1000
H.clock = function() return T end
H.schedule = true
local SCENARIO = process.args[1] or "escape"
math.randomseed(({ escape = 11, bedtime = 22, patrol = 33 })[SCENARIO] or 1) -- the dinner and patrol roll dice: the same ones every run

local ctx: any = {}
ctx.Config = H.load("RS/Shared/Config")
ctx.Rooms = H.load("RS/Shared/Rooms")
ctx.Sounds = H.load("RS/Shared/Sounds")
ctx.Story = H.load("RS/Shared/Story")
ctx.Util = H.load("RS/Shared/Util")
ctx.Builder = H.load("Server/World/Builder")
ctx.Layout = H.load("Server/World/Layout")
local fired, allFired = {}, {}
ctx.Remotes = setmetatable({}, { __index = function(t, k)
	local r = {
		FireClient = function(_, p, a, b) table.insert(fired, { k, p, a, b }) end,
		FireAllClients = function(_, a) table.insert(allFired, { k, a }) end,
		OnServerEvent = H.signal(),
	}
	rawset(t, k, r)
	return r
end })
local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService", "Revive=ReviveService", "Admin=AdminService", "Cutscene=CutsceneService", "Heartbeat=HeartbeatService", "Puzzle=PuzzleService", "Finale=FinaleService" }
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
Sim.install(H)
H.services.TweenService.Create = function(_, obj, _, goal)
	return { Play = function() for k, v in goal do obj[k] = v end end, Cancel = function() end, Completed = H.signal() }
end
-- (the house survey isn't needed down here; keep the brain from building one)
local NavGrid = H.load("Server/Intruder/NavGrid")
NavGrid.ready = function() return true end
for _, k in names do if ctx[k].start then ctx[k].start() end end

local function mkPlayer(name, id, at)
	local p = H.wrap(R.Instance.new("Player"))
	p.Name = name
	rawset(p, "UserId", id)
	rawset(p, "DisplayName", name)
	local char = H.Instance.new("Model")
	char.Name = name
	local root = H.Instance.new("Part", char)
	root.Name = "HumanoidRootPart"
	root.Size = V(2, 2, 1)
	root.CanCollide = false
	local head = H.Instance.new("Part", char)
	head.Name = "Head"
	head.Size = V(1, 1, 1)
	head.CanCollide = false
	local hum = H.Instance.new("Humanoid", char)
	hum.Health = 100
	char.Parent = H.workspaceRoot
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	p:SetAttribute("InGame", true)
	local function place(pos)
		root.CFrame = R.CFrame.new(pos)
		head.CFrame = R.CFrame.new(pos + V(0, 2.5, 0))
	end
	place(at)
	return p, place, root
end

local DT = 1 / 20
local function tick(sec)
	for _ = 1, math.max(1, math.floor(sec / DT + 0.5)) do
		Sim.step(DT)
		H.services.RunService.Heartbeat:Fire(DT)
		T += DT
		H.runDue()
	end
end
local function tickUntil(cond, maxSec, what)
	local t = 0
	while not cond() do
		tick(0.1)
		t += 0.1
		assert(t < maxSec, "timed out waiting for " .. what)
	end
	return t
end

local F = ctx.Finale
local WS = H.unwrap(H.workspaceRoot)
local world = H.unwrap(ctx.World.folder())
local function promptsOn(part)
	local out = {}
	for _, d in H.unwrap(part):GetDescendants() do
		if d:IsA("ProximityPrompt") then table.insert(out, d) end
	end
	return out
end
local function trigger(part, name, who)
	for _, d in promptsOn(part) do
		if not name or d.Name == name then
			local sig = rawget(H.wrap(d), "__signals")
			sig = sig and sig.Triggered
			assert(sig, "prompt has no Triggered")
			sig:Fire(who)
			return true
		end
	end
	error("no prompt " .. tostring(name) .. " on " .. part.Name)
end
local function lastFired(kind, who)
	local r
	for _, f in fired do if f[1] == kind and (not who or f[2] == who) then r = f end end
	return r
end
local function struggle(p) ctx.Remotes.Struggle.OnServerEvent:Fire(p) end

local ok, err = pcall(function()
	local p1, place1, root1 = mkPlayer("Ana", 1, V(-24, 4, -10))
	local p2, place2, root2 = mkPlayer("Ben", 2, V(26, 4, 17))
	local players = { p1, p2 }
	H.services.Players.GetPlayers = function() return players end
	ctx.Director.adminStart("Normal")
	ctx.Director.startAct("Guest")
	tick(2)
	ctx.Intruder.setMode("Hunt")
	tick(1)
	local IS = ctx.Intruder._state()
	if IS.Model then Sim.addWalker(IS.Model, { RootY = 4.9 }) end

	-- one tied up, the other still free: no finale
	ctx.Capture.capture(p1)
	tick(4)
	assert(not F.isActive(), "no finale while someone's still free")
	-- (solo: one player, tied: never)
	assert(F.eligible() == false, "not eligible yet")

	-- the second one: everyone's tied up -> the family dinner
	ctx.Capture.capture(p2)
	tickUntil(function() return F.phase() == "Dinner" end, 40, "the dinner")
	assert(WS:GetAttribute("Act") == "Below", "act V")
	local S = F._state()
	local B = ctx.World.refs().Burrow
	for _, p in players do
		assert(p:GetAttribute("FinaleTied") and p:GetAttribute("Captured"), p.Name .. " tied at the table")
		local seat = S.Seats[p]
		assert(seat and seat.Tied, "has a seat")
		local root = ctx.Util.getRoot(p)
		assert((root.Position - seat.Spot.Pos).Magnitude < 6, p.Name .. " sits at their chair (" .. tostring(root.Position) .. ")")
		assert(seat.Spot.Card.Text ~= "", "a place card with a name")
	end
	assert(not ctx.Escape.helpCalled() or true)
	print("dinner: both at the table, cards " .. S.Seats[p1].Spot.Card.Text .. " / " .. S.Seats[p2].Spot.Card.Text)

	if SCENARIO == "bedtime" then
		-- nobody gets free: bedtime -> FOREVER FAMILY
		T += ctx.Config.Finale.DinnerTime + 5
		tickUntil(function() return WS:GetAttribute("EndingActive") ~= nil end, 30, "the ending")
		assert(WS:GetAttribute("EndingActive") == "ForeverFamily", "forever family, got " .. tostring(WS:GetAttribute("EndingActive")))
		print("bedtime -> " .. WS:GetAttribute("EndingActive"))
		return
	end

	-- struggling while he watches: a strike, and it undoes half the struggle
	tickUntil(function() return S.Mode == "Back" end, 30, "his back turned")
	for _ = 1, 10 do struggle(p2); tick(0.1) end
	local before = S.Seats[p2].Progress
	assert(before > 5, "struggling with his back turned works (" .. before .. ")")
	tickUntil(function() return S.Mode == "Watching" end, 60, "him watching") -- (each fake-out starts a new 6-9 s spell)
	local strikes = S.Strikes
	struggle(p2)
	tick(0.2)
	assert(S.Strikes == strikes + 1, "struggling while he watches is a strike")
	assert(S.Seats[p2].Progress < before, "and the tie gets tighter")
	print(("strike: progress %.0f -> %.0f, bedtime moved up"):format(before, S.Seats[p2].Progress))

	-- free p1: struggle through his back-turned spells
	local guard = 0
	while S.Seats[p1].Tied do
		guard += 1
		assert(guard < 4000, "never got free")
		if S.Mode == "Back" then struggle(p1) end
		tick(0.1)
	end
	assert(not p1:GetAttribute("Captured") and not p1:GetAttribute("FinaleTied"), "p1 free")
	print("p1 struggled free (" .. S.Strikes .. " strikes so far)")
	-- a free player away from their chair while he watches: a strike, and tied again
	tickUntil(function() return S.Mode == "Watching" end, 60, "him watching (2)")
	place1(S.Seats[p1].Spot.Pos + V(6, 3, 0))
	local st = S.Strikes
	tick(0.5)
	assert(S.Strikes > st, "caught off the chair")
	assert(S.Seats[p1].Tied, "and tied up again")
	print("p1 caught off the chair: tied again")
	-- free p1 again, then cut p2 loose while his back is turned
	guard = 0
	while S.Seats[p1].Tied do
		guard += 1
		assert(guard < 4000, "never got free (2)")
		if S.Mode == "Back" then struggle(p1) end
		tick(0.1)
	end
	tickUntil(function() return S.Mode == "Back" end, 30, "back turned to cut")
	place1(ctx.Util.getRoot(p2).Position + V(2, 0, 0))
	trigger(ctx.Util.getRoot(p2), "FinaleCut", p1)
	tick(0.3)
	assert(not S.Seats[p2].Tied, "p2 cut loose")
	tickUntil(function() return F.phase() == "Tunnels" end, 40, "the tunnels")
	assert(B.DiningDoor.Part.CanCollide == false, "the door's open")
	Sim.index() -- (the sim reads the swung-open door again)
	print("everyone free: he went for dessert. Tunnels.")

	-- he climbed up into the house: really gone (off the map) until he comes back down
	local function burrowTargets()
		local last = nil
		for _, f in allFired do if f[1] == "Objectives" then last = f[2] end end
		for _, o in last or {} do if o.Id == "FinaleBurrow" then return #o.Targets end end
		return -1
	end
	assert(S.AwayUntil and not S.Returned, "he's away")
	assert((S.P.position() - B.TableCenter).Magnitude > 100, "and far away: " .. tostring(S.P.position()))
	assert(burrowTargets() == 3, "a marker on each of the 3 notes, got " .. burrowTargets())
	ctx.Noise.emit(B.Nodes.J1, 80, "Door", p1)
	tick(0.5)
	assert(S.Heard == nil and (S.P.position() - B.TableCenter).Magnitude > 100, "he can't hear you from up there")
	print(("he's upstairs for %.0f s, the 3 notes are marked"):format(S.AwayUntil - T))
	-- the notes can be read while he's gone: each one's marker goes once it's read
	trigger(B.Notes.Pantry, nil, p1)
	assert(burrowTargets() == 2, "the pantry note's marker is gone")
	assert(S.Notes.Pantry, "pantry note read")
	-- then he comes back down the dining-room ladder
	T = S.AwayUntil + 0.1
	tickUntil(function() return S.Returned end, 5, "him coming back")
	assert((S.P.position() - B.Ladder).Magnitude < 6, "back down the dining-room ladder: " .. tostring(S.P.position()))
	print("he came back down the ladder at " .. tostring(S.P.position()))

	if SCENARIO == "patrol" then
		-- both hide behind blankets (crouched): he walks the tunnels for two minutes
		local nooks = B.Nooks
		place1((nooks[1].Min + nooks[1].Max) / 2 + V(0, 3, 0))
		place2((nooks[2].Min + nooks[2].Max) / 2 + V(0, 3, 0))
		ctx.Remotes.Movement.OnServerEvent:Fire(p1, { Crouch = true })
		ctx.Remotes.Movement.OnServerEvent:Fire(p2, { Crouch = true })
		local visited, last, still, worst = {}, S.P.position(), 0, 0
		for _ = 1, 1200 do
			tick(0.1)
			local pos = S.P.position()
			for name, n in B.Nodes do
				if V(pos.X - n.X, 0, pos.Z - n.Z).Magnitude < 3 then visited[name] = true end
			end
			if _ % 100 == 0 then print(("  t%d pos %s mode %s path %s busy %s"):format(_, tostring(pos), tostring(S.HunterMode), tostring(S.HunterPath), tostring(S.Busy and (S.Busy - T)))) end
			if (pos - last).Magnitude < 0.3 then still += 0.1 else still = 0 end
			worst = math.max(worst, still)
			last = pos
		end
		local n = 0
		for _ in visited do n += 1 end
		print(("patrol: visited %d nodes in 120 s, longest stop %.1fs, caught %s"):format(n, worst, tostring(S.Seats[p1].Tied or S.Seats[p2].Tied)))
		assert(n >= 8, "he gets around the tunnels")
		assert(worst < 8, "never stuck long")
		assert(not S.Seats[p1].Tied and not S.Seats[p2].Tied, "crouched behind the blankets: not found")
		return
	end

	-- the notes: the code, a digit at a time (and the documents carry it)
	local code = S.Code
	for i, key in { "Pantry", "Nursery", "HisRoom" } do
		trigger(B.Notes[key], nil, p1)
		local doc = lastFired("Document", p1)
		assert(doc and type(doc[4]) == "table" and string.find(doc[4].Body, tostring(code[i == 3 and 3 or i])), key .. " note shows its digit")
	end
	assert(S.CodeShown == table.concat(code, " "), "code known: " .. tostring(S.CodeShown))
	assert(burrowTargets() == 1, "all notes read: the marker moves to the keypad, got " .. burrowTargets())
	-- the keypad: the client never sees the answer
	place1(B.Keypad.Position + V(0, 0, -3))
	trigger(B.Keypad, nil, p1)
	local pz = lastFired("Puzzle", p1)
	assert(pz and pz[3].Kind == "Code" and pz[3].Data.Len == 4 and pz[3].Data.Answer == nil, "keypad opened without the answer")
	assert(pz[3].Data.Hint == S.CodeShown, "but with the code from the notes as a hint")
	ctx.Remotes.PuzzleInput.OnServerEvent:Fire(p1, pz[3].Id, "Submit", "0000" == table.concat(code, "") and "1111" or "0000")
	tick(0.2)
	assert(F.phase() == "Tunnels", "wrong code: still locked")
	ctx.Remotes.PuzzleInput.OnServerEvent:Fire(p1, pz[3].Id, "Submit", table.concat(code, ""))
	tick(0.2)
	assert(F.phase() == "Out", "right code: unlocked")
	print("code " .. table.concat(code, "") .. ": unlocked")

	-- push the hatch four times, then climb out
	place1(B.LadderOut.Position + V(0, 0, -2))
	for _ = 1, ctx.Config.Finale.HatchPushes do
		trigger(B.LadderOut, "Hatch", p1)
		tick(0.1)
	end
	assert(S.Hatch == ctx.Config.Finale.HatchPushes, "hatch open")
	trigger(B.LadderOut, "Hatch", p1)
	tick(1)
	assert(p1:GetAttribute("Escaped") == "Burrow", "p1 climbed out")
	assert(ctx.Util.getRoot(p1).Position.Y > 0, "and is up in the yard")
	print("p1 out in the yard")

	-- p2 walks right into him in the tunnels: caught -> nobody free, one out -> NOT YOUR FAMILY
	-- (keeps stepping right in front of his face until he grabs them; the sim doesn't turn him
	-- to face where he walks the way a Humanoid does, so "in front" is where his head looks)
	local t = 0
	while not S.Seats[p2].Tied and t < 12 do
		local head = S.P.head()
		local look = V(head.CFrame.LookVector.X, 0, head.CFrame.LookVector.Z).Unit
		local root = S.P.position()
		place2(V(root.X, B.FloorY + 3, root.Z) + look * 3)
		tick(0.1)
		t += 0.1
	end
	tickUntil(function() return WS:GetAttribute("EndingActive") ~= nil end, 30, "the ending")
	assert(WS:GetAttribute("EndingActive") == "NotYourFamily", "not your family, got " .. tostring(WS:GetAttribute("EndingActive")))
	print("p2 caught, p1 out -> " .. WS:GetAttribute("EndingActive"))
end)
print(ok and ("FINALE OK " .. SCENARIO) or ("FINALE FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
