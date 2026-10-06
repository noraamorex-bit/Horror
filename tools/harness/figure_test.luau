-- figure_test: the DOORS-Figure brain. He hears; quiet noises bring him to look, loud ones make
-- him charge (louder wins); captives' breathing doesn't lure him; hide near him and he stops to
-- listen: fail the heartbeat minigame and he rips the door open, pass it and he walks away;
-- step out while he's listening and he has you.
-- (header shared with revive_test) Solo: the night waits Config.Shop.Revive.Window seconds,
-- a revive puts you back on your feet away from him; no revive and the night ends.
-- Co-op: the dead player's card offers REVIVE while the others play on.
-- Run with arg "solo", "nobuy", "coop" or "credit".
local H = require("./env")
local Enum = H.roblox.Enum
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
		local r = { FireClient = function(_, p, a) table.insert(fired, { k, p, a }) end, FireAllClients = function() end, OnServerEvent = H.signal() }
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
	local roblox = H.roblox
	local p = H.wrap(roblox.Instance.new("Player"))
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
local function kinds(fired, kind)
	local out = {}
	for _, f in fired do if f[1] == kind then table.insert(out, f) end end
	return out
end
local function receipt(ctx, p, n)
	local MS = H.services.MarketplaceService
	return ctx.Revive.onReceipt({ PlayerId = p.UserId, ProductId = ctx.Config.Shop.Revive.Id, PurchaseId = "buy" .. n })
end
local ok, err = pcall(function()
	H.services.RunService.IsStudio = function() return false end
	local ctx, fired = setup()
	assert(ctx.Config.Intruder.Brain == "Figure", "Figure brain is the default")
	local R = H.roblox
	local a, b = mkPlayer("A", 1), mkPlayer("B", 2)
	H.services.Players.GetPlayers = function() return { a, b } end
	local function tick(sec) for _ = 1, math.floor(sec * 10) do H.services.RunService.Heartbeat:Fire(0.1); T += 0.1; H.runDue() end end
	local ctxI = ctx.Intruder
	ctx.Director.adminStart("Normal")
	ctx.Director.startAct("Guest")
	tick(3)
	local S = ctxI._state()
	assert(S.InHouse, "in the house")
	local function patrolling()
		S.State = "Patrol"; S.Data = { Route = {}, Index = 0, Moving = true, PauseUntil = 1e12 }; S.Heard = nil
	end
	local here = S.Root.Position
	-- far away and quiet, the two of them
	local aRoot, bRoot = ctx.Util.getRoot(a), ctx.Util.getRoot(b)
	aRoot.CFrame = R.CFrame.new(here + R.Vector3.new(80, 0, 0)); bRoot.CFrame = R.CFrame.new(here + R.Vector3.new(-80, 0, 0))
	-- 1) a quiet noise: he comes to look
	patrolling()
	ctx.Noise.emit(here + R.Vector3.new(10, 0, 0), 14, "Door", nil)
	assert(S.State == "Investigate", "door -> investigate, got " .. S.State)
	-- 2) footsteps near him: he charges, and re-aims at the next step
	patrolling()
	ctx.Noise.emit(here + R.Vector3.new(12, 0, 0), 16, "Footsteps", a)
	assert(S.State == "Charge" and S.Data.Source == a, "footsteps -> charge, got " .. S.State)
	ctx.Noise.emit(here + R.Vector3.new(12, 0, 3), 16, "Footsteps", a)
	assert((S.Data.Pos - (here + R.Vector3.new(12, 0, 3))).Magnitude < 0.01, "re-aims at the newest footstep")
	print("investigate + charge ok")
	-- 3) louder wins: a faint door far off doesn't pull him away; glass breaking does
	ctx.Noise.emit(here + R.Vector3.new(0, 0, 13), 14, "Door", nil)
	assert(S.State == "Charge" and S.Data.Source == a, "quieter noise ignored")
	ctx.Noise.emit(here + R.Vector3.new(-30, 0, 0), 140, "Glass", b)
	assert(S.State == "Charge" and (S.Data.Pos - (here + R.Vector3.new(-30, 0, 0))).Magnitude < 0.01, "louder noise wins")
	print("loudness priority ok")
	-- 4) a captive's breathing doesn't lure him
	patrolling()
	b:SetAttribute("Captured", true)
	ctx.Noise.emit(here + R.Vector3.new(10, 0, 0), 13, "Breathing", b)
	assert(S.State == "Patrol", "captive breathing ignored")
	b:SetAttribute("Captured", nil)
	print("captive ignored ok")
	-- 5) hiding near him: he stops to listen; nobody answers the heartbeat -> he rips it open
	local spot = nil
	for _, s in ctx.Hiding.spotsNear(here, 400) do
		if math.abs(s.Position.Y - here.Y) < 6 then spot = s break end
	end
	assert(spot, "a spot on his floor")
	patrolling()
	S.Root.CFrame = R.CFrame.new(spot.Exit.Position + R.Vector3.new(0, 0, 3))
	ctx.Hiding.enter(a, spot)
	assert(S.State == "Inspect", "someone hid near him -> inspect, got " .. S.State)
	S.Root.CFrame = R.CFrame.new(spot.Exit.Position)
	local sessions = 0
	for _ = 1, 300 do
		tick(0.1)
		for _, f in fired do if f[1] == "Heartbeat" and f[2] == a and f[3].Beats and not f.seen then f.seen = true; sessions += 1 end end
		if a:GetAttribute("Captured") then break end
	end
	assert(sessions == 1, "heartbeat minigame started")
	assert(a:GetAttribute("Captured"), "failed heartbeat -> caught")
	print("heartbeat fail ok")
	-- 6) pass the heartbeat: he walks away
	ctx.Capture.release(a, nil)
	S.SpotCooldown = {}
	patrolling()
	S.Root.CFrame = R.CFrame.new(spot.Exit.Position + R.Vector3.new(0, 0, 3))
	ctx.Hiding.enter(b, spot)
	assert(S.State == "Inspect", "inspect again")
	S.Root.CFrame = R.CFrame.new(spot.Exit.Position)
	local payload = nil
	local passed = false
	for _ = 1, 400 do
		tick(0.1)
		for _, f in fired do
			if f[1] == "Heartbeat" and f[2] == b then
				if f[3].Beats then payload = f[3] end
				if f[3].Result == "Pass" then passed = true end
			end
		end
		if payload then
			local s0 = payload.__t0 or T
			payload.__t0 = s0
			for i, beat in payload.Beats do
				if not payload["done" .. i] and T - s0 >= beat.T then
					payload["done" .. i] = true
					ctx.Remotes.HeartbeatInput.OnServerEvent:Fire(b, payload.Id, i, true)
				end
			end
		end
		if S.State ~= "Inspect" and payload then break end
	end
	assert(payload and #payload.Beats >= 3, "beats dealt")
	assert(not b:GetAttribute("Captured"), "steady heartbeat -> safe")
	assert(S.State == "Patrol", "he walks away, got " .. S.State)
	print("heartbeat pass ok (beats " .. #payload.Beats .. ")")
	-- 7) step out while he's listening: he has you
	ctx.Hiding.exit(b)
	S.SpotCooldown = {}
	patrolling()
	S.Root.CFrame = R.CFrame.new(spot.Exit.Position + R.Vector3.new(0, 0, 3))
	ctx.Hiding.enter(b, spot)
	S.Root.CFrame = R.CFrame.new(spot.Exit.Position)
	for _ = 1, 140 do
		tick(0.1)
		if S.State == "Inspect" and S.Data.Phase == "Listen" then break end
	end
	assert(S.Data.Phase == "Listen", "listening")
	ctx.Hiding.exit(b)
	ctx.Util.getRoot(b).CFrame = R.CFrame.new(spot.Exit.Position + R.Vector3.new(1, 0, 0))
	tick(0.5)
	assert(b:GetAttribute("Captured"), "came out in front of him -> caught")
	print("step out ok")
end)
print(ok and "FIGURE OK" or ("FIGURE FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
