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
	local function mk(name)
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
	local a, b = mk("Picker"), mk("Other")
	H.services.Players.GetPlayers = function() return { a, b } end
	-- pick your role: the pass holder wanted the Runner and gets it, every time
	a:SetAttribute("Pass_ChooseRole", true)
	a:SetAttribute("WantRole", "Runner")
	b:SetAttribute("WantRole", "Runner") -- (no pass: ignored)
	for _ = 1, 10 do
		for _, p in { a, b } do ctx.PlayerState.resetPlayer(p) end
		ctx.PlayerState.assignRoles({ a, b })
		assert(a:GetAttribute("Role") == "Runner", "the pass holder gets their pick")
		assert(b:GetAttribute("Role") ~= "Runner", "nobody else gets the same role")
	end
	print("roles:", a:GetAttribute("Role"), b:GetAttribute("Role"))
	-- head start: a flashlight from the first minute
	b:SetAttribute("Pass_HeadStart", true)
	ctx.PlayerState.resetPlayer(b)
	ctx.PlayerState.assignRoles({ a, b })
	print("head start flashlight:", b:GetAttribute("Item_Flashlight"), "without:", a:GetAttribute("Item_Flashlight"))
	assert(b:GetAttribute("Item_Flashlight") == 1 and a:GetAttribute("Item_Flashlight") == nil)
end)
print(ok and "PASS OK" or ("PASS FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
