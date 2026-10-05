local H = require("./env")
local ok, err = pcall(function()
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
		local r = { FireClient = function(_, _, a) table.insert(fired, k) end, FireAllClients = function() end, OnServerEvent = H.signal() }
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
	local roblox = H.roblox
	local p = H.wrap(roblox.Instance.new("Player"))
	p.Name = "Tester"
	local char = H.Instance.new("Model")
	local rootPart = H.Instance.new("Part", char)
	rootPart.Name = "HumanoidRootPart"
	local hum = H.Instance.new("Humanoid", char)
	hum.Health = 100
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	H.services.Players.GetPlayers = function() return { p } end
	p:SetAttribute("InGame", true)
	ctx.Director.startAct("Guest")
	local t = 1000
	H.clock = function() return t end
	local payload
	ctx.Remotes.Ending.FireClient = function(_, _, pl) payload = pl end
	ctx.Escape.callForHelp("Landline", p)
	print("help called", ctx.Escape.helpCalled())
	local function run(f) local co = coroutine.create(f) H.ours[co] = true local okc, e = coroutine.resume(co) if not okc then print("ERR", e) end end
	run(function() ctx.Capture.capture(p) end)
	ctx.Director.checkAllCaptured()
	print("captured once, over? (expect false)", ctx.Ending.isOver())
	t += 20
	ctx.Director._lastChanceTick()
	print("20s later still struggling (expect false)", ctx.Ending.isOver())
	run(function() ctx.Capture.kill(p) end)
	ctx.Director.checkAllCaptured()
	t += 5
	ctx.Director._lastChanceTick()
	print("dead -> ending", ctx.Ending.isOver(), payload and payload.Title, payload and payload.Headline)
	assert(payload and payload.Kind == "GotAway", "expected GotAway")
end)
print(ok and "GOTAWAY OK" or ("GOTAWAY FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
