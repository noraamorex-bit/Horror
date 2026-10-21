-- companion_test: v105, a night alone isn't alone. A night that starts with one player gets a
-- friend (an NPC): they arrive behind you and talk, react to a scare, go to flip the breaker at the
-- blackout and are taken (tied in the boiler room, an optional objective), and cut loose they run
-- next door: Mrs. Okafor calls the police. Never on a night that starts with two.
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
	local said = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { FireClient = function(_, _, payload) if k == "Dialogue" and payload then table.insert(said, payload) end end, FireAllClients = function() end, OnServerEvent = H.signal() }
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
	ctx.restart = function() end
	require("./navsim").install(H) -- (real raycasts, and Model:PivotTo moves models)
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	local R = H.roblox
	local T = 5000
	H.clock = function() return T end
	H.schedule = true
	local function tick(sec)
		for _ = 1, math.max(1, math.floor(sec / 0.1 + 0.5)) do
			T += 0.1
			H.services.RunService.Heartbeat:Fire(0.1)
			H.runDue()
		end
	end
	rawset(H.services.PathfindingService, "CreatePath", function()
		local path = { Status = R.Enum.PathStatus.Success }
		function path:ComputeAsync(a, b) self.A, self.B = a, b end
		function path:GetWaypoints() return { { Position = self.A }, { Position = self.B } } end
		return path
	end)
	local function mkPlayer(name, at)
		local p = H.wrap(R.Instance.new("Player"))
		p.Name = name
		local char = H.Instance.new("Model")
		local rootPart = H.Instance.new("Part", char)
		rootPart.Name = "HumanoidRootPart"
		local head = H.Instance.new("Part", char)
		head.Name = "Head"
		local hum = H.Instance.new("Humanoid", char)
		hum.Health = 100
		rawset(p, "Character", char)
		rawset(p, "Parent", H.workspaceRoot)
		p:SetAttribute("InGame", true)
		p:SetAttribute("RoleName", "Jamie Whitaker")
		rootPart.CFrame = R.CFrame.new(at)
		head.CFrame = R.CFrame.new(at + R.Vector3.new(0, 1.5, 0))
		return p, rootPart
	end
	local a = mkPlayer("Alex", R.Vector3.new(-22, 4, -10))
	H.services.Players.GetPlayers = function() return { a } end
	local Comp = ctx.Companion
	assert(Comp, "the companion is set up")
	ctx.Director.startAct("Evening")
	tick(10)
	assert(Comp.active(), "a night alone: a friend made it")
	assert(Comp.name() ~= "Jamie", "not the player's own role")
	print("companion:", Comp.name(), Comp.mode())
	-- they say hello, and can be talked to
	local heard = false
	for _, l in said do if l.Speaker == Comp.name() then heard = true end end
	print("said:", #said, said[1] and (said[1].Speaker .. ": " .. said[1].Text))
	assert(heard, "they say something when they arrive")
	tick(6)
	local n0 = #said
	Comp.talk(a)
	tick(6)
	assert(#said > n0, "Talk: they answer")
	-- a scare: one line, once
	n0 = #said
	Comp.react("PlateCrash")
	tick(5)
	Comp.react("PlateCrash")
	tick(5)
	local reacts = 0
	for i = n0 + 1, #said do if string.find(said[i].Text, "kitchen", 1, true) then reacts += 1 end end
	assert(reacts == 1, "they react to the plate, once: " .. reacts)
	-- the blackout: off to the breaker, a scream, tied in the boiler room
	Comp.blackout()
	for _ = 1, 400 do
		tick(0.1)
		if Comp.mode() == "Tied" then break end
	end
	tick(10)
	print("after the blackout:", Comp.mode(), Comp.model() and Comp.model():FindFirstChild("HumanoidRootPart").Position)
	assert(Comp.mode() == "Tied", "taken and tied")
	local at = Comp.model():FindFirstChild("HumanoidRootPart").Position
	local room = ctx.Rooms.find(at)
	assert(room and room.Name == "Boiler", "in the boiler room: " .. tostring(room and room.Name))
	assert(ctx.Objectives.has("FreeCompanion"), "an objective to free them")
	-- cut loose: they run, and Mrs. Okafor calls the police
	assert(not ctx.Escape.helpCalled(), "no help yet")
	Comp.free(a)
	for _ = 1, 600 do
		tick(0.1)
		if ctx.Escape.helpCalled() then break end
	end
	assert(ctx.Escape.helpCalled() and ctx.Escape.helpMethod() == "Companion", "help is called: " .. tostring(ctx.Escape.helpMethod()))
	print("freed: help called by", ctx.Escape.helpMethod())
	-- a night that starts with two: no companion
	ctx.Director.enterLobby()
	assert(not Comp.active(), "gone with the night")
	local b = mkPlayer("Bo", R.Vector3.new(-26, 4, -10))
	H.services.Players.GetPlayers = function() return { a, b } end
	ctx.Director.startAct("Evening")
	tick(3)
	assert(not Comp.active(), "two players: no companion")
end)
print(ok and "COMPANION OK" or ("COMPANION FAIL: " .. tostring(err)))
