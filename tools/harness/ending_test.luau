-- ending_test: out early. Solo escape ends the night at once (Taillights); in co-op the escaper
-- gets a Result card and the night goes on; dying leaves a Result card too.
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
		local r = { FireClient = function(_, p, a) table.insert(fired, { k, p, a }) end, FireAllClients = function() end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService" }
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
local function mkPlayer(name)
	local roblox = H.roblox
	local p = H.wrap(roblox.Instance.new("Player"))
	p.Name = name
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
	for _, f in fired do
		if f[1] == kind then table.insert(out, f) end
	end
	return out
end
local MODE = require("@lune/process").args[1] or "solo"
local ok, err = pcall(function()
	-- solo: the car gets you out, and the night ends right there
	if MODE == "solo" then
		local ctx, fired = setup()
		local a = mkPlayer("Solo")
		H.services.Players.GetPlayers = function() return { a } end
		ctx.Director.startAct("Guest")
		ctx.Escape.markEscaped(a, "Car")
		H.flush(3)
		local e = kinds(fired, "Ending")
		print("solo: over", ctx.Ending.isOver(), "kind", e[1] and e[1][3].Kind, "headline", e[1] and e[1][3].Headline, "results", #kinds(fired, "Result"))
		assert(ctx.Ending.isOver() and e[1] and e[1][3].Kind == "Taillights" and e[1][3].Headline == "YOU ESCAPED", "solo car escape should end the night as Taillights")
		assert(#kinds(fired, "Result") == 0, "no separate result card when the night is over")
		assert(e[1][3].Shots and #e[1][3].Shots > 0, "the ending has a cutscene")
		assert(e[1][3].WinTime ~= nil, "a solo car escape is a timed win")
	end
	-- co-op: one escapes, one is still inside
	if MODE == "coop" then
		local ctx, fired = setup()
		local a, b = mkPlayer("Out"), mkPlayer("In")
		H.services.Players.GetPlayers = function() return { a, b } end
		ctx.Director.startAct("Guest")
		ctx.Escape.markEscaped(a, "Neighbor")
		H.flush(3)
		local r = kinds(fired, "Result")
		print("co-op: over", ctx.Ending.isOver(), "result to", r[1] and r[1][2].Name, r[1] and r[1][3].Title, r[1] and r[1][3].CanSpectate)
		assert(not ctx.Ending.isOver(), "the night goes on for the friend inside")
		assert(r[1] and r[1][2] == a and r[1][3].Title == "YOU ESCAPED" and r[1][3].CanSpectate, "the escaper gets a result card")
		-- then the friend dies: nobody left inside, the night ends (a lost ending, since nobody was free)
		local co = coroutine.create(function() ctx.Capture.capture(b) end)
		H.ours[co] = true
		coroutine.resume(co)
		local co2 = coroutine.create(function() ctx.Capture.kill(b) end)
		H.ours[co2] = true
		coroutine.resume(co2)
		H.flush(5)
		local e = kinds(fired, "Ending")
		local heads = {}
		for _, f in e do heads[f[2].Name] = f[3].Headline end
		print("co-op end:", ctx.Ending.isOver(), e[1] and e[1][3].Kind, "Out:", heads.Out, "In:", heads.In)
		assert(ctx.Ending.isOver() and e[1] and e[1][3].Kind == "NextDoor", "someone got out next door")
		assert(heads.Out == "YOU ESCAPED" and heads.In == "YOU DIED", "each player gets their own headline")
	end
end)
print(ok and "ENDING OK" or ("ENDING FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
