-- ai2_test: he investigates noises, hears breathing next to a hiding spot, and goes for the
-- one who is alone.
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
	local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService", "Revive=ReviveService", "Admin=AdminService", "Cutscene=CutsceneService" }
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
	local a, b = mkPlayer("A", 1), mkPlayer("B", 2)
	H.services.Players.GetPlayers = function() return { a, b } end
	ctx.Director.adminStart("Normal")
	ctx.Director.startAct("Guest")
	H.flush(3)
	local S = ctx.Intruder._state()
	assert(S.InHouse, "in the house")
	local R = H.roblox
	-- 1) a door, heard while patrolling with nobody to feel: he goes to look
	a:SetAttribute("Hiding", "x"); b:SetAttribute("Hiding", "x")
	S.State = "Patrol"; S.Data = { Route = {}, Index = 0 }
	ctx.Noise.emit(S.Root.Position + R.Vector3.new(10, 0, 0), 30, "Door", nil)
	assert(S.State == "Investigate", "investigates a door: " .. S.State)
	print("investigate ok")
	-- footsteps don't end his rest
	S.State = "Withdraw"; S.Data = { Until = H.clock() + 20 }
	ctx.Noise.emit(S.Root.Position + R.Vector3.new(12, 0, 0), 16, "Footsteps", a)
	assert(S.State == "Withdraw", "footsteps don't break his rest")
	ctx.Noise.emit(S.Root.Position + R.Vector3.new(12, 0, 0), 22, "Microwave", a)
	assert(S.State == "Investigate", "the microwave next to him does")
	print("rest window ok")
	a:SetAttribute("Hiding", nil); b:SetAttribute("Hiding", nil)
	-- 2) breathing: a hidden, scared player right next to him, not holding their breath
	local spot = nil
	for _, s in ctx.Hiding.spotsNear(S.Root.Position, 400) do spot = s break end
	assert(spot, "a hiding spot")
	ctx.Hiding.enter(a, spot)
	a:SetAttribute("Nerve", 5)
	S.Root.CFrame = R.CFrame.new(spot.Position + R.Vector3.new(3, 0, 0))
	S.State = "Patrol"; S.Data = { Route = {}, Index = 0, Moving = true, PauseUntil = 1e12 }
	local heard = false
	for _ = 1, 400 do
		H.services.RunService.Heartbeat:Fire(0.1)
		T += 0.1; H.runDue()
		if S.State == "CheckSpot" and S.Data.Spot == spot then heard = true break end
		if S.State ~= "Patrol" then S.State = "Patrol"; S.Data = { Route = {}, Index = 0, Moving = true, PauseUntil = 1e12 }; S.Root.CFrame = R.CFrame.new(spot.Position + R.Vector3.new(3, 0, 0)) end
	end
	assert(heard, "he heard them breathing")
	print("breathing ok")
	-- holding your breath (for a few seconds, while he's right there): he hears nothing
	ctx.Hiding.exit(a, true)
	S.SpotCooldown = {}
	S.HeardHide = {}
	ctx.Hiding.enter(a, spot)
	-- (he's off somewhere else while they get their breath back)
	S.State = "Stopped"
	for _ = 1, 130 do T += 0.1; H.runDue() end
	ctx.Remotes.HoldBreath.OnServerEvent:Fire(a, true)
	assert(a:GetAttribute("HoldingBreath") == true, "holding")
	S.State = "Patrol"; S.Data = { Route = {}, Index = 0, Moving = true, PauseUntil = 1e12 }
	local heard2 = false
	for _ = 1, 50 do
		S.Root.CFrame = R.CFrame.new(spot.Position + R.Vector3.new(3, 0, 0))
		H.services.RunService.Heartbeat:Fire(0.1)
		T += 0.1; H.runDue()
		if S.State == "CheckSpot" and S.Data.Spot == spot then heard2 = true break end
		if S.State ~= "Patrol" then S.State = "Patrol"; S.Data = { Route = {}, Index = 0, Moving = true, PauseUntil = 1e12 } end
	end
	assert(not heard2, "holding your breath keeps you quiet")
	print("holding breath ok")
end)
print(ok and "AI2 OK" or ("AI2 FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
