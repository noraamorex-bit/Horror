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
	local lastObjectives
	ctx.Remotes = setmetatable({}, { __index = function(_, k) return { FireClient = function() end, FireAllClients = function(_, payload) if k == "Objectives" then lastObjectives = payload end end, OnServerEvent = H.signal() } end })
	for _, name in { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "Hiding=HidingService", "Escape=EscapeService", "Capture=CaptureService", "PlayerState=PlayerStateService", "Phone=PhoneService" } do
		local key, file = name:match("(%w+)=(%w+)")
		ctx[key] = H.load("Server/Services/" .. file)
	end
	ctx.Objectives = H.load("Server/Services/ObjectiveService")
	ctx.Director = { getAct = function() return "Evening" end, logTruth = function() end, onDiscovery = function() end }
	ctx.World = H.load("Server/World/World")
	ctx.Director.think = function() end
	ctx.Director.onItem = function() end
	ctx.Director.onHide = function() end
	for _, k in { "Audio", "Noise", "Interaction", "Inventory", "Power", "Doors", "Hiding", "Escape", "Capture", "PlayerState", "Phone", "World", "Objectives" } do
		ctx[k].init(ctx)
	end
	local refs = ctx.World.build()
	local Depth = H.load("Server/World/Depth")
	local root = H.unwrap(ctx.World.folder())
	local t0 = os.clock()
	local n, found = Depth.find(root)
	print("ZFIGHT pairs before:", n, string.format("(%.2fs)", os.clock() - t0))
	local byName = {}
	for _, f in found do
		local k = f[1].Name .. " vs " .. f[2].Name .. " " .. f[3]
		byName[k] = (byName[k] or 0) + 1
	end
	local list = {}
	for k, v in byName do table.insert(list, { k, v }) end
	table.sort(list, function(a, b) return a[2] > b[2] end)
	for i = 1, math.min(40, #list) do print("  ", list[i][2], list[i][1]) end
	t0 = os.clock()
	print("resolved", Depth.resolve(root), string.format("(%.2fs)", os.clock() - t0))
	local n2, found2 = Depth.find(root)
	print("ZFIGHT pairs after:", n2)
	local bn = {}
	for _, f in found2 do
		local k = f[1].Name .. " vs " .. f[2].Name .. " " .. f[3]
		bn[k] = (bn[k] or 0) + 1
	end
	local l2 = {}
	for k, v in bn do table.insert(l2, { k, v }) end
	table.sort(l2, function(a, b) return a[2] > b[2] end)
	for i = 1, math.min(25, #l2) do print("  left", l2[i][2], l2[i][1]) end
end)
if not ok then print("ERR", err) end
