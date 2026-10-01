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
	ctx.Remotes = setmetatable({}, { __index = function() return { FireClient = function() end, FireAllClients = function() end, OnServerEvent = H.signal() } end })
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
	ctx.restart = function() print("restart called") end
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	print("started")
	local R = H.roblox
	local truths = {}
	local rawLog = ctx.Director.logTruthRaw
	ctx.Director.logTruthRaw = function(t) table.insert(truths, t); rawLog(t) end
	local p = H.wrap(R.Instance.new("Player"))
	p.Name = "Tester"
	local char = H.Instance.new("Model")
	local rootPart = H.Instance.new("Part", char)
	rootPart.Name = "HumanoidRootPart"
	local head = H.Instance.new("Part", char)
	head.Name = "Head"
	local hum = H.Instance.new("Humanoid", char)
	hum.Health = 100
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	H.services.Players.GetPlayers = function() return { p } end
	p:SetAttribute("InGame", true)
	ctx.Director.startAct("SomeoneElse")
	ctx.Intruder.setMode("Lurk")
	local hb = H.services.RunService.Heartbeat
	for _ = 1, 5 do hb:Fire(0.1) end
	print("hidden at first:", not ctx.Intruder.isInHouse())
	-- stand the player somewhere, looking away from the front hall, then let him appear
	rootPart.CFrame = R.CFrame.lookAt(R.Vector3.new(2, 4, 0), R.Vector3.new(2, 4, -20))
	head.CFrame = rootPart.CFrame + R.Vector3.new(0, 1.5, 0)
	ctx.Intruder.appearNow()
	for _ = 1, 3 do hb:Fire(0.1) end
	print("state", ctx.Intruder.getState(), "inHouse", ctx.Intruder.isInHouse(), "pos", ctx.Intruder.position())
	local p1 = p
	local root = ctx.Util.getRoot(p1)
	local ip = ctx.Intruder.position()
	print("player", p1 and p1.Name, "root", root ~= nil)
	if root and ip then
		-- stand right in front of him, facing him
		root.CFrame = R.CFrame.lookAt(ip + R.Vector3.new(4, 0, 0), ip)
		head.CFrame = root.CFrame + R.Vector3.new(0, 1.5, 0)
		for _ = 1, 10 do hb:Fire(0.1) end
	end
	print("after close: state", ctx.Intruder.getState())
	for _, t in truths do print("  truth:", t) end
	-- spook while lurking: runs
	ctx.Intruder.spook()
	print("spooked ok")
	-- door ajar handling: push an ajar door open
	local d = ctx.Doors.get("Lily")
	ctx.Doors.setAjar(d, 30)
	local near = ctx.Doors.nearestClosed(d.Position, 3)
	print("ajar counts as blocking", near == d, "wait", ctx.Doors.intruderOpen(d, false), "target now open", d.Target and d.Target > 1.5)
end)
print(ok and "INTRUDER OK" or ("INTRUDER FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
