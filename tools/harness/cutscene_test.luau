-- cutscene_test: lights out (Act III), tied up (first capture), he comes down (first hunt).
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
	local a = mkPlayer("A", 1)
	H.services.Players.GetPlayers = function() return { a } end
	local ws = H.unwrap(H.workspaceRoot)
	ctx.Director.adminStart("Normal")
	ctx.Director.startAct("SomeoneElse")
	H.flush(8.5)
	assert(#kinds(fired, "Cutscene") == 1 and kinds(fired, "Cutscene")[1][3].Name == "LightsOut", "lights-out cutscene")
	assert(ctx.Power.isOn(), "power still on as it starts")
	assert(ctx.Cutscene.isPlaying(), "playing")
	local root = ctx.Util.getRoot(a)
	assert(root.Anchored, "player held still")
	H.flush(2.6)
	assert(not ctx.Power.isOn(), "the power dies during the shot")
	H.flush(4)
	assert(not root.Anchored and not ctx.Cutscene.isPlaying(), "released after")
	print("lights out ok")
	-- first capture: the tied-up shot, just for them
	local co = coroutine.create(function() ctx.Capture.capture(a) end); H.ours[co] = true; coroutine.resume(co)
	H.flush(3)
	local cs = kinds(fired, "Cutscene")
	assert(#cs == 2 and cs[2][3].Name == "TiedUp" and cs[2][2] == a and cs[2][3].Subtitle:find("zip"), "tied-up cutscene")
	print("tied up ok")
	-- the first hunt: him under the garage hatch
	local b = mkPlayer("B", 2)
	H.services.Players.GetPlayers = function() return { a, b } end
	ctx.Intruder.setMode("Hunt")
	H.flush(3)
	local cs2 = kinds(fired, "Cutscene")
	local last = cs2[#cs2][3]
	print("after hunt:", last.Name, "state", ctx.Intruder.getState())
	assert(last.Name == "HeComesDown", "he-comes-down cutscene")
	print("he comes down ok")
end)
print(ok and "CUTSCENE OK" or ("CUTSCENE FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
