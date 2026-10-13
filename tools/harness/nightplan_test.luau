-- nightplan_test: what the first act asks of you tonight (Director/NightPlan).
-- A first night always gets pizza + popcorn + the upstairs windows; repeat nights get pizza and
-- two from Popcorn / Windows / Fire / Movie, never the same two as the server's last night.
-- The fire and movie chores play through with the real prompts: firewood from the garage into a
-- cold fireplace, the remote from the couch and channel 4. A fire left unlit is lit at act II
-- (the living room keeps its light for the blackout).
local H = require("./env")
local ok, err = pcall(function()
	-- the draw on its own
	local NP = H.load("Server/Director/NightPlan")
	local first = NP.choose(true, { "Fire", "Movie" })
	assert(NP.key(first) == "Popcorn+Windows", "a first night: the tuned chores, got " .. NP.key(first))
	local seen = {}
	local last = { "Popcorn", "Windows" }
	for i = 1, 400 do
		local c = NP.choose(false, last)
		assert(#c == 2 and c[1] ~= c[2], "two different chores")
		assert(NP.key(c) ~= NP.key(last), "never the same two as last night")
		seen[NP.key(c)] = true
		last = c
	end
	local n = 0
	for _ in seen do n += 1 end
	assert(n == 6, "every pair turns up, got " .. n)
	local ev = NP.evening({ "Fire", "Movie" })
	assert(ev[1] == "OrderPizza" and #ev == 3, "pizza always comes first")
	print("draw ok")

	-- the whole house
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Rooms = H.load("RS/Shared/Rooms")
	ctx.Sounds = H.load("RS/Shared/Sounds")
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Util = H.load("RS/Shared/Util")
	ctx.Builder = H.load("Server/World/Builder")
	ctx.Layout = H.load("Server/World/Layout")
	local plans = {}
	ctx.Journey = { plan = function(t) table.insert(plans, t) end, act = function() end, team = function() end, event = function() end }
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
	ctx.restart = function() end
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	local R = H.roblox
	local p = H.wrap(R.Instance.new("Player"))
	p.Name = "Veteran"
	local char = H.Instance.new("Model")
	local rootPart = H.Instance.new("Part", char)
	rootPart.Name = "HumanoidRootPart"
	rawset(p, "Character", char)
	H.services.Players.GetPlayers = function() return { p } end
	p:SetAttribute("InGame", true)
	p:SetAttribute("Role", "Host")

	-- a first-timer: the tuned set
	p:SetAttribute("StatNights", 0)
	ctx.Director.startAct("Evening")
	assert(NP.key(ctx.Director.chores()) == "Popcorn+Windows", "first night")
	assert(ctx.Objectives.has("OrderPizza") and ctx.Objectives.has("Popcorn") and ctx.Objectives.has("Windows"), "on the list")
	assert(ctx.World.refs().Fire.Lit, "the fire's going on a first night")
	-- veterans: keep drawing until a night with the fire and the movie
	p:SetAttribute("StatNights", 4)
	local prev = ctx.Director.chores()
	for _ = 1, 60 do
		ctx.Director.startAct("Evening")
		local c = ctx.Director.chores()
		assert(NP.key(c) ~= NP.key(prev), "a different set from the last night")
		prev = c
		if NP.key(c) == "Fire+Movie" then break end
	end
	assert(NP.key(ctx.Director.chores()) == "Fire+Movie", "drew the fire and the movie")
	assert(plans[#plans] == "Fire+Movie", "the plan is logged")
	assert(not ctx.Objectives.has("Popcorn") and not ctx.Objectives.has("Windows") and ctx.Objectives.has("Fire") and ctx.Objectives.has("Movie"), "tonight's list")
	local fire = ctx.World.refs().Fire
	assert(not fire.Lit and not fire.Logs, "a cold fireplace")
	print("plans ok:", table.concat(plans, ", "))

	local world = H.unwrap(ctx.World.folder())
	local function press(partName, action)
		for _, d in world:GetDescendants() do
			if d:IsA("ProximityPrompt") and d.Parent and d.Parent.Name == partName and (not action or d.ActionText == action) and d.Enabled then
				local sig = rawget(H.wrap(d), "__signals")
				if sig and sig.Triggered then sig.Triggered:Fire(p); return true end
			end
		end
		error("no enabled prompt " .. partName .. " " .. tostring(action))
	end
	-- the fire: firewood from the garage, into the fireplace
	press("FireSpot", "Light the fire") -- (no wood yet: nothing happens)
	assert(not fire.Lit, "can't light it without wood")
	press("PileSpot", "Take firewood")
	assert(ctx.Objectives.isStepDone("Fire", "Wood"), "got the wood")
	press("FireSpot", "Light the fire")
	assert(fire.Lit and ctx.Objectives.isDone("Fire"), "the fire's going")
	-- the movie: the remote in the couch, channel 4
	press("CouchSearch")
	assert(ctx.Objectives.isStepDone("Movie", "Remote"), "found the remote")
	for _ = 1, #ctx.Story.TV + 1 do
		if ctx.Objectives.isDone("Movie") then break end
		press("Screen")
	end
	assert(ctx.Objectives.isDone("Movie"), "the movie's on")
	print("fire + movie chores ok")

	-- a cold fireplace nobody got to: lit when act II starts
	for _ = 1, 60 do
		ctx.Director.startAct("Evening")
		if table.find(ctx.Director.chores(), "Fire") then break end
	end
	assert(table.find(ctx.Director.chores(), "Fire") and not fire.Lit, "the fire's out again")
	ctx.Director.startAct("SmallThings")
	assert(fire.Lit, "lit for act II")
	ctx.Director.startAct("Evening")
	if not table.find(ctx.Director.chores(), "Fire") then
		assert(fire.Lit, "lit on a night without the fire chore")
	end
	print("fire safety ok")
end)
print(ok and "NIGHTPLAN OK" or ("NIGHTPLAN FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
