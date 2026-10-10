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
	print("head", ctx.Intruder.getHead() ~= nil)
	local co = coroutine.create(function() ctx.Capture.capture(p) end)
	H.ours[co] = true
	local okc, e = coroutine.resume(co)
	print("capture ok", okc, e, "captured", p:GetAttribute("Captured"))
	print("remotes fired", table.concat(fired, ","))
	ctx.Director.checkAllCaptured()
	print("all captured -> ending right away? (expect false)", ctx.Ending.isOver())
	ctx.Capture.release(p, nil)
	print("released", p:GetAttribute("Captured"))
	local payload
	ctx.Remotes.Ending.FireClient = function(_, _, pl) payload = pl end
	ctx.Stats = H.load("Server/Services/StatsService")
	ctx.Stats.init(ctx)
	ctx.Stats.start()
	for i = 1, 7 do
		ctx.Director.onDocument(p, ctx.Story.Evidence[i])
	end
	ctx.Director.onDocument(p, ctx.Story.Evidence[1]) -- repeats don't count twice
	print("evidence", ctx.Director.evidenceCount())
	ctx.Ending.trigger("Sirens")
	print("ending", payload and payload.Title, payload and payload.Headline, payload and payload.Short, payload and #payload.FirstFor)
end)
print(ok and "CAPTURE OK" or ("CAPTURE FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
