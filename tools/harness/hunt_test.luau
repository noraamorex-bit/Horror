local H = require("./env")
local ok, err = pcall(function()
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Config.Intruder.Brain = "Classic" -- (this test covers the classic brain; figure_test covers the Figure one)
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
			if st.Root and st.Nav and st.Nav.Goal and not st.Root.Anchored then
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
	local a, aRoot, aHead = mkPlayer("Alex", R.Vector3.new(-22, 4, -18))
	local b, bRoot, bHead = mkPlayer("Bo", R.Vector3.new(-30, 22, 20))
	H.services.Players.GetPlayers = function() return { a, b } end
	print("hiding spots", #ctx.Hiding.all())
	local I = ctx.Intruder
	ctx.Config.Intruder.AmbushChance = 1
	ctx.Director.startAct("SomeoneElse")
	I.setMode("Hunt")
	print("placed at", I.position(), "alex", aRoot.Position, ctx.Util.getRoot(a) and ctx.Util.getRoot(a).Position)
	tick(0.3)
	print("captured?", a:GetAttribute("Captured"), b:GetAttribute("Captured"))
	print("1 state", I.getState(), "inHouse", I.isInHouse())
	assert(I.getState() == "Prowl", "starts prowling")
	tick(1)
	-- he should be heading for the nearest felt player
	local ip = I.position()
	print("2 intruder at", ip, "dist to Alex", (ip - aRoot.Position).Magnitude, "to Bo", (ip - bRoot.Position).Magnitude)
	-- Alex hides in the nearest spot, out of his sight
	local spots = ctx.Hiding.spotsNear(aRoot.Position, 40)
	local spot = spots[1]
	print("Alex hides in", spot and spot.Name)
	-- make sure he isn't 'seeing' it: move him far away first
	ctx.Intruder.position()
	ctx.Hiding.enter(a, spot)
	-- Bo hides too, so nobody is left to feel
	local bspot = ctx.Hiding.spotsNear(bRoot.Position, 60)[1]
	ctx.Hiding.enter(b, bspot)
	tick(0.5)
	print("3 after both hid:", I.getState())
	-- let the search run its course
	local seen = {}
	for _ = 1, 400 do
		tick(0.1)
		local st = I.getState()
		if seen[#seen] ~= st then table.insert(seen, st) end
		if a:GetAttribute("Captured") or b:GetAttribute("Captured") then break end
	end
	print("4 states:", table.concat(seen, " > "))
	print("   captured: Alex", a:GetAttribute("Captured"), "Bo", b:GetAttribute("Captured"))
	-- out of hiding: grace, then he feels them again
	if not a:GetAttribute("Captured") then ctx.Hiding.exit(a) end
	if not b:GetAttribute("Captured") then ctx.Hiding.exit(b) end
	local t0 = T
	local back
	for _ = 1, 700 do
		tick(0.1)
		if I.getState() == "Prowl" or I.getState() == "Chase" then back = T - t0 break end
	end
	print("5 hunting again after", back, "s, state", I.getState())
	-- a help call in Withdraw: frenzy, hunts immediately
	I.onHelpCalled(a)
	print("6 after help call", I.getState())
	-- seen up close: chase, grab
	local ipos = I.position()
	aRoot.CFrame = R.CFrame.lookAt(ipos + R.Vector3.new(0, -0.9, -4), ipos)
	aHead.CFrame = aRoot.CFrame + R.Vector3.new(0, 1.5, 0)
	for _ = 1, 30 do
		tick(0.1)
		if a:GetAttribute("Captured") then break end
	end
	print("8 grabbed when close:", a:GetAttribute("Captured"), I.getState())
	-- seen getting into a hiding spot: he opens that one
	ctx.Capture.release(a)
	aRoot.CFrame = R.CFrame.new(60, 4, 60)
	aHead.CFrame = R.CFrame.new(60, 5.5, 60)
	ctx.Hiding.enter(a, ctx.Hiding.spotsNear(R.Vector3.new(0, 0, 0), 200)[5])
	for _ = 1, 400 do tick(0.1) if I.getState() ~= "Retreat" then break end end
	print("9 after retreat", I.getState())
	local near = ctx.Hiding.spotsNear(I.position(), 60)
	local close = near[1]
	bRoot.CFrame = R.CFrame.lookAt(I.position() + R.Vector3.new(0, -0.9, -12), I.position())
	bHead.CFrame = bRoot.CFrame + R.Vector3.new(0, 1.5, 0)
	tick(0.3)
	print("   Bo visible? state", I.getState())
	-- (no physics here: put him at the spot, as if he'd walked over)
	local hrp = H.unwrap(ctx.World.folder()):FindFirstChild("Curtis", true):FindFirstChild("HumanoidRootPart")
	hrp.CFrame = R.CFrame.new(close.Exit.Position + R.Vector3.new(0, 2, 0))
	ctx.Hiding.enter(b, close)
	tick(0.2)
	print("10 Bo hid in view; state", I.getState(), "Alex captured", a:GetAttribute("Captured"), "dead", a:GetAttribute("Dead"))
	for _ = 1, 300 do tick(0.1) if b:GetAttribute("Captured") then break end end
	print("   Bo captured:", b:GetAttribute("Captured"))
	-- client gait attribute
	local model = H.unwrap(ctx.World.folder()):FindFirstChild("Curtis", true)
	print("7 gait attr", model and model:GetAttribute("Gait"), "creature", model and model:GetAttribute("Creature"))
end)
print(ok and "HUNT OK" or ("HUNT FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
