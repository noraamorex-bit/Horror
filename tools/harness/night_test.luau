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
	print("started")
	local R = H.roblox
	local T = 10000
	H.clock = function() return T end
	H.schedule = true
	rawset(H.services.PathfindingService, "CreatePath", function()
		local path = { Status = H.roblox.Enum.PathStatus.Success }
		function path:ComputeAsync(a, b) self.A, self.B = a, b end
		function path:GetWaypoints() return { { Position = self.A }, { Position = self.B } } end
		return path
	end)
	local Perc = H.load("Server/Intruder/Perception")
	Perc.clear = function(a, b) return ctx.Rooms.find(a) == ctx.Rooms.find(b) end
	local msgs = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { OnServerEvent = H.signal() }
		r.FireClient = function(_, _, a) if k == "Notify" or k == "Thought" then table.insert(msgs, { T = T, K = k, A = type(a) == "string" and a or (type(a) == "table" and "(phone)" or tostring(a)) }) end end
		r.FireAllClients = function(_, a) if k == "Notify" or k == "Thought" then table.insert(msgs, { T = T, K = k, A = tostring(a) }) end end
		rawset(t, k, r)
		return r
	end })
	local p = H.wrap(R.Instance.new("Player"))
	p.Name = "Bot"
	local char = H.Instance.new("Model")
	local root = H.Instance.new("Part", char); root.Name = "HumanoidRootPart"
	local head = H.Instance.new("Part", char); head.Name = "Head"
	local hum = H.Instance.new("Humanoid", char); hum.Health = 100
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	H.services.Players.GetPlayers = function() return { p } end
	p:SetAttribute("InGame", true)
	root.CFrame = R.CFrame.new(-20, 4, -10)
	head.CFrame = root.CFrame + R.Vector3.new(0, 1.5, 0)
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	local hb = H.services.RunService.Heartbeat
	local nodes = {}
	for _, n in ctx.Layout.Nodes do if n.Pos.Y > 1 and n.Pos.Y < 8 then table.insert(nodes, n.Pos) end end
	local goal = nodes[1]
	local I = ctx.Intruder
	local stats = { caught = 0, hides = 0, states = {} }
	local function step()
		T += 0.1
		local st = I._state()
		if st.Root and st.Nav and st.Nav.Goal and not st.Root.Anchored then
			local ip = st.Root.Position
			local dv = st.Nav.Goal - ip
			local stepLen = (st.Humanoid.WalkSpeed or 10) * 0.1
			if dv.Magnitude > 0.1 then
				local np = dv.Magnitude <= stepLen and st.Nav.Goal or ip + dv.Unit * stepLen
				st.Root.CFrame = R.CFrame.lookAt(np, np + R.Vector3.new(dv.X, 0, dv.Z + 1e-4))
			end
		end
		-- the bot: wanders, hides when he's close and hunting
		local pos = root.CFrame.Position
		local ipos = I.position()
		local d = ipos and (ipos - pos).Magnitude or 999
		local s = I.getState()
		stats.states[s] = (stats.states[s] or 0) + 1
		if p:GetAttribute("Captured") then
			if not p:GetAttribute("Dead") and not stats.wasCaptured then
				stats.wasCaptured = true
				stats.caught += 1
				T += 1
				ctx.Capture.release(p)
				root.CFrame = R.CFrame.new(nodes[math.random(#nodes)])
			end
		elseif p:GetAttribute("Hiding") then
			p:SetAttribute("HoldingBreath", (d < 10) or nil)
			if (s == "Withdraw" and d > 30) or d > 50 then
				local spot = ctx.Hiding.spotOf(p)
				ctx.Hiding.exit(p)
				if spot then root.CFrame = spot.Exit end
			end
		else
			stats.wasCaptured = nil
			if (s == "Prowl" or s == "Chase" or s == "Search" or s == "Ambush") and d < 40 then
				local best, bd = nil, 1e9
				for _, sp in ctx.Hiding.spotsNear(pos, 30) do
					if math.abs(sp.Position.Y - pos.Y) < 6 then
						local dd = (sp.Exit.Position - pos).Magnitude
						if dd < bd then best, bd = sp, dd end
					end
				end
				if best then
					goal = best.Exit.Position
					if bd < 3 then ctx.Hiding.enter(p, best); stats.hides += 1 end
				end
			elseif (pos - goal).Magnitude < 2 then
				goal = nodes[math.random(#nodes)]
			end
			if not p:GetAttribute("Hiding") then
				local dv = (goal - pos) * R.Vector3.new(1, 0, 1)
				if dv.Magnitude > 0.05 then
					local np = pos + dv.Unit * math.min(1.2, dv.Magnitude)
					root.CFrame = R.CFrame.lookAt(np, np + dv)
				end
			end
		end
		head.CFrame = root.CFrame + R.Vector3.new(0, 1.5, 0)
		hb:Fire(0.1)
		H.runDue()
	end
	local function run(seconds) for _ = 1, seconds * 10 do step() end end
	local function report(label)
		local parts = {}
		for k, v in stats.states do table.insert(parts, k .. "=" .. math.floor(v / 10)) end
		table.sort(parts)
		print(label, "act", ctx.Director.getAct(), "caught", stats.caught, "hides", stats.hides, "errors", #H.errors, "| " .. table.concat(parts, " "))
	end
	ctx.Director.startAct("Evening")
	run(60) report("evening")
	ctx.Director.startAct("SmallThings")
	run(60)
	-- lock up -> Mom's texts -> news objective
	for _, id in { "BackDoor", "GarageSide" } do
		local door = ctx.Doors.get(id)
		ctx.Doors.setLocked(door, true)
		ctx.Director.onDoorLockChanged(door, p)
	end
	run(40) report("smallthings")
	print("  news objective:", ctx.Objectives.has("News"))
	ctx.Director.startAct("SomeoneElse")
	run(180) report("someoneelse")
	print("  intruder mode/state:", I._state().Mode, I.getState())
	ctx.Director.startAct("Guest")
	run(180) report("guest")
	ctx.Escape.callForHelp("Cell", p)
	run(200) report("after help")
	print("  ending over:", ctx.Ending.isOver())
	-- bursts: 3+ messages within 3 seconds
	local bursts = 0
	for i = 1, #msgs do
		local j = i
		while msgs[j + 1] and msgs[j + 1].T - msgs[i].T <= 3 do j += 1 end
		if j - i + 1 >= 3 then
			bursts += 1
			if bursts <= 8 then
				print(string.format("  BURST at %.1f:", msgs[i].T - 10000))
				for k = i, j do print("     ", msgs[k].K, msgs[k].A:sub(1, 90)) end
			end
		end
	end
	print("  messages", #msgs, "bursts", bursts)
end)
print(ok and "NIGHT OK" or ("NIGHT FAIL: " .. tostring(err)))
local seen = {}
for _, e in H.errors do
	local k = tostring(e):sub(1, 160)
	if not seen[k] and not k:find("TextChannels") then seen[k] = true print("ERR", tostring(e):sub(1, 900)) end
end
