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

	local MODE = os.getenv and nil
	-- walls: you can only see within the same room (or the open hall/stairs)
	local Perc = H.load("Server/Intruder/Perception")
	Perc.clear = function(a, b)
		local ra, rb = ctx.Rooms.find(a), ctx.Rooms.find(b)
		return ra == rb
	end
	local how = {}
	local function run(strategy, seed, minutes)
		math.randomseed(seed)
		local p, root, head = mkPlayer("Bot", R.Vector3.new(-20, 4, -10))
		H.services.Players.GetPlayers = function() return { p } end
		local I = ctx.Intruder
		I.reset()
		I.init(ctx)
		I.setMode("Hunt")
		local nodes = {}
		for _, n in ctx.Layout.Nodes do
			if n.Pos.Y > 1 and n.Pos.Y < 8 then table.insert(nodes, n.Pos) end
		end
		local goal = nodes[math.random(#nodes)]
		local stamina = 7
		local hiddenAt, hideSpot = nil, nil
		local caught, hides, chases = 0, 0, 0
		local lastState = nil
		local t0 = T
		while T - t0 < minutes * 60 do
			-- the bot
			local st = I._state()
			local ip = I.position()
			local pos = root.CFrame.Position
			local d = ip and (ip - pos).Magnitude or 999
			local state = I.getState()
			if state == "Chase" and lastState ~= "Chase" then chases += 1 end
			lastState = state
			if p:GetAttribute("Captured") then
				caught += 1
				local k = strategy .. ":" .. tostring(st.State) .. (hideSpot and hiddenAt and ":hidden" or "")
				how[k] = (how[k] or 0) + 1
				ctx.Capture.release(p)
				p:SetAttribute("Captured", nil)
				p:SetAttribute("Dead", nil)
				root.CFrame = R.CFrame.new(nodes[math.random(#nodes)])
				head.CFrame = root.CFrame + R.Vector3.new(0, 1.5, 0)
			elseif p:GetAttribute("Hiding") then
				if not hiddenAt then hiddenAt = T end
				-- a sensible player holds their breath when he's right outside
				p:SetAttribute("HoldingBreath", (d < 10) or nil)
				-- come out once he has been away/quiet for a while
				if (state == "Withdraw" and d > 30) or (d > 45 and T - hiddenAt > 20) then
					hiddenAt = nil
					ctx.Hiding.exit(p)
					root.CFrame = hideSpot.Exit
					head.CFrame = root.CFrame + R.Vector3.new(0, 1.5, 0)
				end
			else
				local danger = (state == "Prowl" or state == "Chase" or state == "Search" or state == "Ambush") and d < 40
				if strategy == "hide" and danger then
					-- run to the nearest spot and get in
					local spots = ctx.Hiding.spotsNear(pos, 30)
					local best, bd = nil, 1e9
					for _, sp in spots do
						if not ctx.Hiding.occupant(sp) and math.abs(sp.Position.Y - pos.Y) < 6 then
							local dd = (sp.Exit.Position - pos).Magnitude
							if dd < bd then best, bd = sp, dd end
						end
					end
					if best then
						goal = best.Exit.Position
						if bd < 3 then
							ctx.Hiding.enter(p, best)
							hideSpot = best
							hiddenAt = T
							hides += 1
						end
					end
				elseif (pos - goal).Magnitude < 2 then
					goal = nodes[math.random(#nodes)]
				end
				if not p:GetAttribute("Hiding") then
					local sprint = (danger or state == "Chase") and stamina > 0
					stamina = sprint and stamina - 0.1 or math.min(7, stamina + 0.1 * 9 / 14)
					local speed = sprint and 17 or 10
					-- flee directly away from him if he's chasing and we're not hiding
					local tgt = goal
					if state == "Chase" and strategy ~= "hide" and ip then
						tgt = pos + (pos - ip).Unit * 10
					end
					local dv = (tgt - pos) * R.Vector3.new(1, 0, 1)
					if dv.Magnitude > 0.05 then
						local np = pos + dv.Unit * math.min(speed * 0.1, dv.Magnitude)
						root.CFrame = R.CFrame.lookAt(np, np + dv)
						head.CFrame = root.CFrame + R.Vector3.new(0, 1.5, 0)
					end
				end
			end
			tick(0.1)
		end
		return caught, hides, chases
	end
	for _, strat in { "never", "hide" } do
		local tc, th, tch = 0, 0, 0
		for seed = 1, 3 do
			local c, h, ch = run(strat, seed, 5)
			tc += c; th += h; tch += ch
		end
		print(string.format("SIM %-6s 3x5min: caught %d, hid %d times, chases %d", strat, tc, th, tch))
	end
	for k, v in how do print("  caught while", k, v) end
end)
print(ok and "SIM OK" or ("SIM FAIL: " .. tostring(err)))
for _, e in H.errors do if not tostring(e):find("TextChannels") then print(e) end end
