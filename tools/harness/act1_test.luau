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
	local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService" }
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
	-- (v111) the first task has to be in reach where you land: from every spawn, the menu's and the
	-- note's prompts show without a step (v110 put the spawns 5 studs from the fridge, but the menu sits
	-- 9.4 up and its prompt reached 6: you stood facing a fridge with nothing to press)
	local L = ctx.Layout
	for _, name in { "PizzaMenu", "FridgeNote" } do
		local pr
		for _, d in world:GetDescendants() do
			if d:IsA("ProximityPrompt") and d.Parent and d.Parent.Name == name then
				pr = d
			end
		end
		assert(pr, "no prompt on " .. name)
		for i, sp in L.LobbySpawns do
			local pp = pr.Parent.CFrame.Position
			local dist = math.sqrt((pp.X - sp.X) ^ 2 + (pp.Y - sp.Y) ^ 2 + (pp.Z - sp.Z) ^ 2)
			print(string.format("  %s from spawn %d: %.1f studs (reach %.1f)", name, i, dist, pr.MaxActivationDistance))
			assert(dist <= pr.MaxActivationDistance - 0.5, name .. " out of reach from spawn " .. i)
		end
	end
	status("start")
	press("Landline")
	press("PizzaMenu")
	press("Landline", "Order pizza")
	press("Microwave")
	press("Cupboard")
	press("Microwave", "Make popcorn")
	press("Microwave", "Take the popcorn")
	press("TableSpot")
	press("Screen", "Turn on")
	press("CouchSearch")
	press("Screen", "Turn on")
	press("FireSpot")
	press("PileSpot")
	press("FireSpot", "Put in firewood")
	press("MatchDrawer")
	press("FireSpot", "Light the fire")
	status("after tasks")
	for _, w in ctx.World.refs().OpenWindows do
		local prompts = w.Glass:GetDescendants()
	end
	-- (v99) closing an open window upstairs, you are looking out of it: the Director's chance for
	-- the yard figure, straight out of the house through that window
	local glances = {}
	local realGlance = ctx.Director.windowGlance
	ctx.Director.windowGlance = function(pl, gp, out)
		table.insert(glances, { gp, out })
		return realGlance(pl, gp, out)
	end
	press("Glass", "Close window")
	press("Glass", "Close window")
	ctx.Director.windowGlance = realGlance
	assert(#glances >= 1, "a glance out of the window, got " .. #glances)
	for _, g in glances do
		local gp, out = g[1], g[2]
		assert(math.abs(out.Magnitude - 1) < 1e-6 and out.Y == 0, "a flat outward direction")
		assert((gp + out * 5).Magnitude > gp.Magnitude, "pointing out of the house")
	end
	status("after windows")
	print("all required done:", ctx.Objectives.allRequiredDone())
end)
print(ok and "ACT1 OK" or ("ACT1 FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
