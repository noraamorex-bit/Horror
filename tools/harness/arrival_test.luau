-- arrival_test (v107): how a group's own server starts the night (Director arrivalTick).
local H = require("./env")
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
		local r = { FireClient = function(_, p, a) table.insert(fired, { k, p, a }) end, FireAllClients = function(_, a) table.insert(fired, { k, nil, a }) end, OnServerEvent = H.signal() }
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
	return p
end
local function last(fired, kind, p)
	for i = #fired, 1, -1 do
		if fired[i][1] == kind and (p == nil or fired[i][2] == p) then return fired[i][3] end
	end
	return nil
end
local ws = H.unwrap(H.workspaceRoot)
local ok, err = pcall(function()
	-- (v107) a group's own server: once everyone's here the night starts a second later; when it's
	-- everyone's first night there's no vote (nothing to choose), otherwise the vote as before
	local ctx, fired = setup()
	ctx.Reserved = true
	local D = ctx.Director
	-- a veteran among them: the vote, as before
	local v, n = mkPlayer("Vet"), mkPlayer("New2")
	v:SetAttribute("StatNights", 3); n:SetAttribute("StatNights", 0)
	v:SetAttribute("ClientReady", true); n:SetAttribute("ClientReady", true)
	H.services.Players.GetPlayers = function() return { v, n } end
	D._state().Expected = 2
	D._arrivalTick()
	assert(D._state().Vote == nil, "1 s first")
	D._arrivalTick()
	assert(D._state().Vote ~= nil and ws:GetAttribute("Act") ~= "Evening", "a veteran among them: the vote as before")
	print("veteran present: vote")
	-- everyone new: straight in
	D._state().Vote = nil
	D.enterLobby()
	local a = mkPlayer("New")
	H.services.Players.GetPlayers = function() return { a } end
	-- (saved stats still loading: it waits for them, a few seconds at most)
	D._arrivalTick(); D._arrivalTick(); D._arrivalTick()
	assert(ws:GetAttribute("Act") ~= "Evening" and D._firstNightsOnly() == nil, "waits for the stats")
	a:SetAttribute("StatNights", 0)
	-- (v110: and for their client to be up)
	D._arrivalTick(); D._arrivalTick()
	assert(ws:GetAttribute("Act") ~= "Evening", "waits for the client to load")
	a:SetAttribute("ClientReady", true)
	D._arrivalTick()
	assert(ws:GetAttribute("Act") == "Evening", "a first night starts at once: " .. tostring(ws:GetAttribute("Act")))
	assert(D._state().Vote == nil and ws:GetAttribute("Difficulty") == "Normal", "no vote, Normal")
	print("first night: no vote, started")
end)
print(ok and "ARRIVAL OK" or ("ARRIVAL FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
