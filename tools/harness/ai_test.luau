local H = require("./env")
FREEZE = false
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
	local R = H.roblox
	-- a controllable clock: waits advance it, so spawned loops run straight through
	local T = 5000
	local R = H.roblox
	H.clock = function() return T end
	H.task.wait = function(s) T += (s or 0.03); return s or 0.03 end
	local hb = H.services.RunService.Heartbeat
	-- straight-line paths (there's no navmesh in here)
	rawset(H.services.PathfindingService, "CreatePath", function()
		local path = { Status = H.roblox.Enum.PathStatus.Success }
		function path:ComputeAsync(a, b) self.A, self.B = a, b end
		function path:GetWaypoints() return { { Position = self.A }, { Position = self.B } } end
		return path
	end)
	local function tick(seconds)
		for _ = 1, math.floor(seconds / 0.1) do
			T += 0.1
			-- walk him toward his navigation goal (no physics in here)
			local st = ctx.Intruder._state()
			if st.Root and st.Nav and st.Nav.Goal and not st.Root.Anchored and not FREEZE then
				local p = st.Root.Position
				local g = st.Nav.Goal
				local step = (st.Humanoid.WalkSpeed or 10) * 0.1
				local dv = g - p
				if dv.Magnitude > 0.1 then
					local np = dv.Magnitude <= step and g or p + dv.Unit * step
					st.Root.CFrame = R.CFrame.lookAt(np, np + R.Vector3.new(dv.X, 0, dv.Z + 1e-4))
				end
			end
			hb:Fire(0.1)
		end
	end
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
		rootPart.CFrame = R.CFrame.new(at)
		head.CFrame = R.CFrame.new(at + R.Vector3.new(0, 1.5, 0))
		return p, rootPart, head
	end
	-- ai_test: one friend zip-tied in the boiler room, the other hiding upstairs. He must not sit in
	-- the basement: he comes back up, patrols, and opens hiding spots on the survivor's floor.
	local a, aRoot = mkPlayer("Alex", R.Vector3.new(-30, -9, 20))
	local b, bRoot = mkPlayer("Bo", R.Vector3.new(-11, 18, 24))
	H.services.Players.GetPlayers = function() return { a, b } end
	local I = ctx.Intruder
	ctx.Director.startAct("Guest")
	I.setMode("Hunt")
	tick(0.5)
	-- Alex is taken (he carries them to the boiler room); Bo hides in Jamie's room upstairs
	local co = coroutine.create(function() ctx.Capture.capture(a) end)
	H.ours[co] = true
	coroutine.resume(co)
	local bspot = ctx.Hiding.spotsNear(bRoot.Position, 30)[1]
	print("Bo hides in", bspot and bspot.Name)
	ctx.Hiding.enter(b, bspot)
	local floors, states, checks, upAt = {}, {}, 0, nil
	local last
	for _ = 1, 3000 do -- 300 s
		tick(0.1)
		local st = I.getState()
		if st ~= last then
			table.insert(states, st)
			if st == "CheckSpot" or st == "Inspect" then checks += 1 end
			last = st
		end
		local fl = ctx.Rooms.floorOf(I.position())
		floors[fl] = (floors[fl] or 0) + 0.1
		if fl ~= "Basement" and fl ~= "Outside" and not upAt then upAt = T end
		if b:GetAttribute("Captured") then break end
	end
	print("states:", table.concat(states, " > "):sub(1, 400))
	local fs = {}
	for k, v in floors do table.insert(fs, k .. "=" .. math.floor(v) .. "s") end
	print("time by floor:", table.concat(fs, " "), "spot checks:", checks, "Bo caught:", b:GetAttribute("Captured"))
	assert((floors.Basement or 0) < 120, "spent too long in the basement")
	assert(checks >= 1 or b:GetAttribute("Captured"), "never searched for the survivor")
	assert(table.find(states, "Patrol"), "never patrolled")
	-- stuck: he can't move at all, in the basement, while Bo is out in the open upstairs. He
	-- must get himself out through the walls rather than stand there.
	if b:GetAttribute("Captured") then ctx.Capture.release(b) end
	if b:GetAttribute("Hiding") then ctx.Hiding.exit(b) end
	bRoot.CFrame = R.CFrame.new(-11, 18, 24)
	local st = I._state()
	st.Root.CFrame = R.CFrame.new(-4, -8, -22)
	-- (the harness's Model:PivotTo doesn't move parts; in the engine it moves the whole rig)
	rawset(st.Model, "PivotTo", function(_, cf) st.Root.CFrame = cf end)
	print("placed on", ctx.Rooms.floorOf(I.position()))
	FREEZE = true
	-- (no walls in here: a whole floor between them still counts as out of sight)
	local P = H.load("Server/Intruder/Perception")
	local realSees, realPlayerSees = P.anyoneSees, P.playerSees
	P.anyoneSees = function() return false end
	P.playerSees = function() return false end
	local outAfter
	local t0 = T
	for _ = 1, 600 do
		tick(0.1)
		if ctx.Rooms.floorOf(I.position()) ~= "Basement" then outAfter = T - t0 break end
	end
	FREEZE = false
	P.anyoneSees, P.playerSees = realSees, realPlayerSees
	print("stuck in the basement -> out after", outAfter, "s, now on", ctx.Rooms.floorOf(I.position()), "state", I.getState())
	assert(outAfter and outAfter < 45, "never got himself out of the basement")
end)
print(ok and "AI OK" or ("AI FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
