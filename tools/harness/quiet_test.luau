-- quiet_test (v144, the owner: "Way too many scares there is like one every single room. Also they aren't even scary. Check
-- doors that is your only reference. Make it 1-2 scares the whole run before blackout."): a whole act I and act II run
-- through the Director with a player walking the house (into the open-window room too): before the blackout at most two
-- scares reach them, the act I room scare (FirstAt) and act II's HallStare; everything else the scheduler picks is the
-- house's own sound (Config.Director.Ambient) or the story (the footsteps upstairs, the TV's alert).
local H = require("./env")
local task = H.task
local T = 1000
H.clock = function() return T end
H.schedule = true
local function setup()
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Config.Thoughts.ReactGap = 0 -- (v139: the reaction gate is haunt_test's; random scares here mustn't swallow the line checked)
	ctx.Rooms = H.load("RS/Shared/Rooms")
	ctx.Sounds = H.load("RS/Shared/Sounds")
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Util = H.load("RS/Shared/Util")
	ctx.Builder = H.load("Server/World/Builder")
	ctx.Layout = H.load("Server/World/Layout")
	local fired = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { FireClient = function(_, p, a, b, c) table.insert(fired, { k, p, a, b, c }) end, FireAllClients = function(_, a) table.insert(fired, { k, "all", a }) end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService", "Revive=ReviveService", "Admin=AdminService", "Cutscene=CutsceneService", "Heartbeat=HeartbeatService" }
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
local function mkPlayer(name, id)
	local p = H.wrap(H.roblox.Instance.new("Player"))
	p.Name = name
	rawset(p, "UserId", id)
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
	return p
end
local ok, err = pcall(function()
	H.services.RunService.IsStudio = function() return false end
	local ctx, fired = setup()
	local R = H.roblox
	local V = R.Vector3.new
	local a = mkPlayer("Ava", 1)
	H.services.Players.GetPlayers = function() return { a } end
	local function tick(sec) for _ = 1, math.floor(sec * 10 + 0.5) do H.services.RunService.Heartbeat:Fire(0.1); T += 0.1; H.runDue() end end
	local function put(p, pos, look)
		local root = ctx.Util.getRoot(p)
		root.CFrame = look and (R.CFrame.new(pos) * R.CFrame.Angles(0, math.atan2(-(look.X - pos.X), -(look.Z - pos.Z)), 0)) or R.CFrame.new(pos)
		p.Character:FindFirstChild("Head").CFrame = root.CFrame * R.CFrame.new(0, 1.5, 0)
	end
	-- every event that runs, and in which act
	local Events = H.load("Server/Director/Events")
	local ran = {}
	for _, e in Events.List do
		local run = e.Run
		e.Run = function(...)
			table.insert(ran, { e.Id, ctx.Director.getAct() })
			return run(...)
		end
	end
	ctx.Director.adminStart("Normal")
	assert(ctx.Director.getAct() == "Evening", "the first act")
	-- walking the house through act I: the kitchen, the open-window guest room, the halls, the living room
	local route = {
		{ V(-24, 4, 22), V(-24, 4, 8) }, { V(2, 4, -20), V(2, 4, 20) }, { V(15, 18, -15), V(26, 18, -27) }, { V(26, 18, -20), V(26, 18, -28) },
		{ V(2, 18, -26), V(2, 18, 20) }, { V(-24, 4, -8), V(-24, 4, -20) }, { V(-11, 18, 24), V(-30, 18, 24) },
	}
	for i = 1, 16 do
		local r = route[(i - 1) % #route + 1]
		put(a, r[1], r[2])
		tick(15)
	end
	ctx.Director.startAct("SmallThings")
	-- act II: down the upstairs hall looking along it (HallStare's ground), and the rest of the house
	for i = 1, 24 do
		if i % 3 == 0 then
			put(a, V(2, 18, -26), V(2, 18, 20))
		else
			local r = route[(i - 1) % #route + 1]
			put(a, r[1], r[2])
		end
		tick(15)
	end
	local ambient = ctx.Config.Director.Ambient
	local story = { FootstepsUpstairs = true, TVAlert = true }
	local scares, list = 0, {}
	local actI = 0
	for _, r in ran do
		if (r[2] == "Evening" or r[2] == "SmallThings") and not ambient[r[1]] and not story[r[1]] then
			scares += 1
			table.insert(list, r[1] .. "@" .. r[2])
			if r[2] == "Evening" then actI += 1 end
		end
	end
	print("before the blackout:", table.concat(list, ", "))
	assert(#ran > 0, "the events were watched")
	assert(actI == 1 and list[1] == "Apparition@Evening", "act I: the one room scare, got " .. table.concat(list, ", "))
	assert(scares <= 2, "at most two scares before the blackout, got " .. scares .. ": " .. table.concat(list, ", "))
	for _, x in list do
		assert(x == "Apparition@Evening" or x == "HallStare@SmallThings", "only the two scripted ones: " .. x)
	end
end)
print(ok and "QUIET OK" or ("QUIET FAIL: " .. tostring(err)))
