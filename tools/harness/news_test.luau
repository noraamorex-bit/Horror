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
	local log = {}
	local texts = {}
	ctx.Remotes = ctx.Remotes
	local orig = getmetatable(ctx.Remotes).__index
	setmetatable(ctx.Remotes, { __index = function(_, k)
		local r = orig(nil, k)
		r.FireClient = function(_, p, a, b)
			if k == "Texts" then texts = a end
			if k == "Notify" then table.insert(log, "notify: " .. tostring(a)) end
		end
		r.FireAllClients = function(_, a) if k == "Notify" then table.insert(log, "notifyAll: " .. tostring(a)) end end
		return r
	end })
	local p = H.wrap(H.roblox.Instance.new("Player"))
	p.Name = "Tester"
	local char = H.Instance.new("Model")
	local rootPart = H.Instance.new("Part", char)
	rootPart.Name = "HumanoidRootPart"
	H.Instance.new("Humanoid", char)
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	H.services.Players.GetPlayers = function() return { p } end
	p:SetAttribute("InGame", true)
	ctx.Director.startAct("SmallThings")
	H.task.wait = function() return 0 end
	print("act", ctx.Director.getAct(), #ctx.Util.sessionPlayers())
	ctx.Director.startMomNews()
	for _, m in texts.Messages do print("msg", m.Thread, m.From, m.Mine, m.Body) end
	assert(texts.Reply and texts.Reply.Thread == "Mom", "reply pending")
	print("reply options", table.concat(texts.Reply.Options, " | "))
	assert(ctx.Objectives.has("News"), "News objective")
	ctx.Phone.answer(p, 2)
	for _, m in texts.Messages do print("msg2", m.Thread, m.From, m.Mine, m.Body) end
	assert(texts.Reply == nil)
	ctx.Director.onNewsWatched({ p })
	for _, l in log do print(l) end
	print("NEWS OK")
end)
if not ok then print("FAIL", err) end
for _, e in H.errors do print("ERR", e) end
