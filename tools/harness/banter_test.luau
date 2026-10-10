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
	local lines = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { FireClient = function(_, _, payload) if k == "Dialogue" then table.insert(lines, payload or false) end end, FireAllClients = function() end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	H.services.TweenService.Create = function() return { Play = function() end, Cancel = function() end, Completed = { Wait = function() end, Connect = function() end } } end
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
	local roblox = H.roblox
	local players = {}
	for i, role in { "Host", "Tinkerer", "Runner" } do
		local p = H.wrap(roblox.Instance.new("Player"))
		p.Name = "P" .. i
		rawset(p, "UserId", i)
		rawset(p, "DisplayName", "Player" .. i)
		local char = H.Instance.new("Model")
		local rootPart = H.Instance.new("Part", char)
		rootPart.Name = "HumanoidRootPart"
		rootPart.Position = roblox.Vector3.new(i * 3, 4, 0)
		local hum = H.Instance.new("Humanoid", char)
		hum.Health = 100
		rawset(p, "Character", char)
		rawset(p, "Parent", H.workspaceRoot)
		p:SetAttribute("InGame", true)
		p:SetAttribute("Role", role)
		p:SetAttribute("RoleName", ({ Host = "Jamie Whitaker", Tinkerer = "Riley Chen", Runner = "Morgan Hale" })[role])
		table.insert(players, p)
	end
	H.services.Players.GetPlayers = function() return players end
	print("active", #ctx.Util.activePlayers())
	ctx.Director.startAct("SmallThings")
	print("quiet right after act start (expect false):", ctx.Director.isQuiet())
	-- texts must wait too
	local sent = 0
	ctx.Remotes.Texts.FireClient = function() sent += 1 end
	ctx.Phone.update("SmallThings", 9999, ctx.Director.isQuiet())
	print("texts while busy (expect 0):", sent)
	-- let the thought lines 'clear'
	ctx.Config.Thoughts.Duration = -10
	ctx.Director.think(nil, "clear")
	print("quiet now (expect true):", ctx.Director.isQuiet())
	ctx.Phone.update("SmallThings", 9999, ctx.Director.isQuiet())
	ctx.Phone.update("SmallThings", 9999, ctx.Director.isQuiet())
	print("texts when quiet, two updates (expect 1 player text, spaced):", sent)
	local captured
	local realSay = ctx.Dialogue.say
	ctx.Dialogue.say = function(l, aud) captured = { l, aud } end
	ctx.Director.banterTick(10)
	print("banter before due (expect none):", captured == nil)
	ctx.Director.banterTick(200)
	print("banter cast:", captured ~= nil)
	if captured then
		local co = coroutine.create(function() print("say returned", realSay(captured[1], captured[2])) end)
		H.ours[co] = true
		for _ = 1, 200 do
			if coroutine.status(co) == "dead" then break end
			coroutine.resume(co)
		end
		print("audience", #captured[2])
	end
	for _, l in lines do
		if l then print("  ", l.Speaker, l.SpeakerId, l.Ambient, l.Text) else print("  <close>") end
	end
	captured = nil
	ctx.Director.reactBanter("PlateCrash")
	print("reaction cast:", captured ~= nil, captured and captured[1][1].Text)
	captured = nil
	ctx.Director.reactBanter("PlateCrash")
	print("reaction only once (expect true):", captured == nil)
	-- solo: no banter
	H.services.Players.GetPlayers = function() return { players[1] } end
	captured = nil
	ctx.Director.banterTick(400)
	print("solo banter (expect none):", captured == nil)
end)
print(ok and "BANTER OK" or ("BANTER FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
