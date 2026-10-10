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
	local roblox = H.roblox
	local p = H.wrap(roblox.Instance.new("Player"))
	p.Name = "Tester"
	local char = H.Instance.new("Model")
	local rootPart = H.Instance.new("Part", char)
	rootPart.Name = "HumanoidRootPart"
	rawset(p, "Character", char)
	H.services.Players.GetPlayers = function() return { p } end
	p:SetAttribute("InGame", true)
	p:SetAttribute("Role", "Host")
	ctx.Director.startAct("Evening")
	local world = H.unwrap(ctx.World.folder())
	local function press(partName, action)
		for _, d in world:GetDescendants() do
			if d:IsA("ProximityPrompt") and d.Parent and (d.Parent.Name == partName or (d.Parent.Parent and d.Parent.Parent.Name == partName)) and (not action or d.ActionText == action) then
				local prox = H.wrap(d)
				local sigs = rawget(prox, "__signals")
				local sig = sigs and sigs.Triggered
				if sig then
					sig:Fire(p)
					return true
				end
			end
		end
		print("  !! no prompt", partName, action)
		return false
	end
	local function status(label)
		local lines = {}
		for _, id in { "OrderPizza", "Popcorn", "Movie", "Fire", "Windows" } do
			table.insert(lines, id .. "=" .. (ctx.Objectives.isDone(id) and "done" or (ctx.Objectives.currentText(id) or "?")))
		end
		print(label, table.concat(lines, " | "))
	end
	ctx.Director.startAct("SomeoneElse")
	ctx.Power.setMain(false, "Intruder")
	ctx.Escape.cutLine()
	local function st(l) print(l, "Phone=" .. tostring(ctx.Objectives.currentText("Phone") or (ctx.Objectives.isDone("Phone") and "done")), "Power=" .. tostring(ctx.Objectives.currentText("Power") or (ctx.Objectives.isDone("Power") and "done"))) end
	st("start")
	press("Landline")
	st("after landline")
	press("BoxDoor", "Inspect")
	st("after box")
	press("JunkDrawer")
	st("after tape")
	press("BoxDoor", "Splice the wires")
	st("after splice")
	press("Flashlight")
	press("BreakerPanel", "Inspect")
	st("after panel")
	press("MainLever")
	st("after flip")
	press("Landline")
	st("after call")
end)
print(ok and "ACT1 OK" or ("ACT1 FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
