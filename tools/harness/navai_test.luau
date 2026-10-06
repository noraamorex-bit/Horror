-- navai_test: the intruder in the real house (navsim: real walls, furniture, doors, stairs, and
-- a body that collides with them). Run with arg:
--   "sweep"  : walk between random pairs of rooms / hiding spots; every trip must arrive in
--              reasonable time without being wedged or teleported
--   "brain"  : the Figure brain hunting players for a few minutes (noises, hiding, patrols);
--              reports stuck time, slips, climbs, and how much of the time he spends moving
-- The house survey is cached in the scratchpad (navgrid_cache.json): delete it after changing
-- the house.
local H = require("./env")
local Sim = require("./navsim")
local process = require("@lune/process")
local MODE = process.args[1] or "sweep"
local SEED = tonumber(process.args[2] or "7")
math.randomseed(SEED)
local CACHE = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad/navgrid_cache.json"
local Enum = H.roblox.Enum
local R = H.roblox
local V = R.Vector3.new
local T = 1000
H.clock = function() return T end
H.schedule = true

local ctx: any = {}
ctx.Config = H.load("RS/Shared/Config")
ctx.Rooms = H.load("RS/Shared/Rooms")
ctx.Sounds = H.load("RS/Shared/Sounds")
ctx.Story = H.load("RS/Shared/Story")
ctx.Util = H.load("RS/Shared/Util")
ctx.Builder = H.load("Server/World/Builder")
ctx.Layout = H.load("Server/World/Layout")
local fired = {}
ctx.Remotes = setmetatable({}, { __index = function(t, k)
	local r = { FireClient = function(_, p, a) table.insert(fired, { k, p, a }) end, FireAllClients = function() end, OnServerEvent = H.signal() }
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
Sim.install(H)
local NavGrid = H.load("Server/Intruder/NavGrid")
local t0 = os.clock()
local built = Sim.navGrid(NavGrid, CACHE)
print(built and ("surveyed the house in " .. math.floor(os.clock() - t0) .. "s") or "survey loaded from cache")
-- TweenService: tweens finish at once (doors swing open/shut instantly)
H.services.TweenService.Create = function(_, obj, _, goal)
	return {
		Play = function()
			for k, v in goal do
				obj[k] = v
				local sig = rawget(obj, "__signals")
				if k == "Value" and sig and sig.Changed then sig.Changed:Fire(v) end
			end
		end,
		Cancel = function() end,
		Completed = H.signal(),
	}
end
for _, k in names do if ctx[k].start then ctx[k].start() end end

local function mkPlayer(name, id, at)
	local p = H.wrap(R.Instance.new("Player"))
	p.Name = name
	rawset(p, "UserId", id)
	local char = H.Instance.new("Model")
	char.Name = name
	local root = H.Instance.new("Part", char)
	root.Name = "HumanoidRootPart"
	root.Size = V(2, 2, 1)
	root.CanCollide = false
	local head = H.Instance.new("Part", char)
	head.Name = "Head"
	head.Size = V(1, 1, 1)
	head.CanCollide = false
	local hum = H.Instance.new("Humanoid", char)
	hum.Health = 100
	char.Parent = H.workspaceRoot
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	p:SetAttribute("InGame", true)
	local function place(pos)
		root.CFrame = R.CFrame.new(pos)
		head.CFrame = R.CFrame.new(pos + V(0, 2.5, 0))
	end
	place(at)
	Sim.track(char)
	return p, place
end

local DT = 1 / 30
local function tick(sec)
	for _ = 1, math.max(1, math.floor(sec / DT + 0.5)) do
		Sim.step(DT)
		H.services.RunService.Heartbeat:Fire(DT)
		T += DT
		H.runDue()
	end
end

local I = ctx.Intruder
local S = I._state()
local okRun, err = pcall(function()
	if MODE == "sweep" then
		local a = mkPlayer("Far", 1, V(200, 4, 200))
		H.services.Players.GetPlayers = function() return { a } end
		ctx.Director.adminStart("Normal")
		ctx.Director.startAct("Guest")
		tick(3)
		I.setMode("Hunt")
		tick(1)
		assert(S.Model and S.InHouse, "he's in the house")
		local walker = Sim.addWalker(S.Model, { RootY = 4.9 })
		I.adminFreeze(true) -- (brain off: just his feet)
		S.AdminFrozen = nil
		S.State = "Stopped"
		-- (the physics is real: walking straight at the living/kitchen wall gets him nowhere)
		S.Model:PivotTo(R.CFrame.new(V(-35, 5.95, -5)))
		tick(0.5)
		S.Humanoid:MoveTo(V(-35, 1, 10))
		tick(3)
		assert(S.Root.Position.Z < 2, "walked through the wall to z " .. S.Root.Position.Z)
		assert(walker.Blocked > 1, "blocked by the wall")
		print(("wall stops him (z %.2f, y %.2f)"):format(S.Root.Position.Z, S.Root.Position.Y))
		walker.Blocked = 0
		walker.Climbs = 0
		local goals = {}
		for _, n in ctx.Layout.Nodes do table.insert(goals, { n.Room, n.Pos }) end
		for _, sp in ctx.Hiding.spotsNear(V(0, 0, 0), 1000) do table.insert(goals, { "exit:" .. sp.Name, sp.Exit.Position }) end
		local trips, fails, slow, totalT, wedged = 0, 0, 0, 0, 0
		local slips0 = 0
		local cur = goals[1][2]
		S.Model:PivotTo(R.CFrame.new(NavGrid.nearest(cur, 4) + V(0, 4.95, 0)))
		local trace = {}
		for k = 1, tonumber(process.args[3] or "60") do
			local g = goals[math.random(1, #goals)]
			local from = S.Root.Position
			local path = NavGrid.findPath(from, g[2], 6)
			local len = 0
			if path then for i = 2, #path do len += (path[i] - path[i - 1]).Magnitude end end
			local speed = 16
			S.Nav:goTo(g[2], { Speed = speed, Tolerance = 2 })
			local t = 0
			local blocked0 = walker.Blocked
			local lastP, lastMoveT = S.Root.Position, 0
			local maxIdle = 0
			while not S.Nav.Arrived and t < 60 do
				tick(0.1)
				t += 0.1
				local p = S.Root.Position
				if (p - lastP).Magnitude > 0.5 or T < (S.Nav.WaitUntil or 0) then lastP = p; lastMoveT = t end
				maxIdle = math.max(maxIdle, t - lastMoveT)
			end
			trips += 1
			totalT += t
			local expect = len / speed + 1.5 + 2 -- (doors: up to ~2 s)
			local status = "ok"
			if not S.Nav.Arrived or S.Nav.Failed then
				fails += 1
				status = "FAIL"
			elseif t > expect * 1.5 + 3 then
				slow += 1
				status = "SLOW"
			end
			if maxIdle > 2.5 then wedged += 1; status = status .. "+IDLE" .. string.format("%.1f", maxIdle) end
			if status ~= "ok" then
				print(("%s %s -> %s (%s) len %.0f t %.1f expect %.1f blocked %.1fs stuck %d"):format(status, tostring(from), g[1], tostring(g[2]), len, t, expect, walker.Blocked - blocked0, S.Nav.Stuck))
				if walker.Blocked > blocked0 then print("   last block: " .. tostring(walker.LastBlock)) end
			end
		end
		print(("trips %d, failed %d, slow %d, idle>2.5s %d, climbs %d, total blocked %.1fs, avg trip %.1fs"):format(trips, fails, slow, wedged, walker.Climbs, walker.Blocked, totalT / trips))
		assert(fails == 0 and wedged == 0, "navigation problems")
	else
		-- the brain, hunting: three players moving about, making noise, hiding
		local players, placers = {}, {}
		local spawnAt = { V(-24, 4, -10), V(26, 4, 17), V(-24, 18, 21) }
		for i = 1, 3 do
			local p, place = mkPlayer("P" .. i, i, spawnAt[i])
			players[i], placers[i] = p, place
		end
		H.services.Players.GetPlayers = function() return players end
		ctx.Director.adminStart("Normal")
		ctx.Director.startAct("Guest")
		tick(3)
		I.setMode("Hunt")
		tick(1)
		assert(S.Model and S.InHouse, "he's in the house")
		local walker = Sim.addWalker(S.Model, { RootY = 4.9 })
		local spots = ctx.Hiding.spotsNear(V(0, 0, 0), 1000)
		local stats = { moving = 0, should = 0, idleShould = 0, states = {}, caught = 0, slips = 0 }
		local lastPos = S.Root.Position
		local idleRun, worstIdle, worstAt = 0, 0, ""
		local DUR = tonumber(process.args[3] or "240")
		local t = 0
		local nextEvent = 0
		local trace = {}
		while t < DUR do
			-- what the players do: wander to a random node, now and then make noise, or hide
			if t >= nextEvent then
				nextEvent = t + 4 + math.random() * 8
				local i = math.random(1, 3)
				local p = players[i]
				if p:GetAttribute("Captured") then
					ctx.Capture.release(p, nil)
				end
				local roll = math.random()
				if p:GetAttribute("Hiding") then
					ctx.Hiding.exit(p)
				elseif roll < 0.5 then
					local n = ctx.Layout.Nodes[math.random(1, #ctx.Layout.Nodes)]
					local at = NavGrid.nearest(n.Pos, 4)
					if at then
						placers[i](at + V(0, 3, 0))
						ctx.Noise.emit(at + V(0, 1, 0), math.random() < 0.5 and 16 or 30, math.random() < 0.7 and "Footsteps" or "Item", p)
					end
				elseif roll < 0.8 then
					local sp = spots[math.random(1, #spots)]
					if not ctx.Hiding.occupant(sp) then
						placers[i](sp.Exit.Position)
						ctx.Hiding.enter(p, sp)
					end
				else
					ctx.Noise.emit(spawnAt[math.random(1, 3)], 60, "Glass", nil)
				end
			end
			tick(0.1)
			t += 0.1
			local st = S.State
			stats.states[st] = (stats.states[st] or 0) + 0.1
			local p = S.Root.Position
			local v = (p - lastPos).Magnitude / 0.1
			lastPos = p
			local wantsToMove = S.Nav.Goal ~= nil and not S.Nav.Arrived and os.clock() >= 0 and (T >= (S.Nav.WaitUntil or 0))
			if wantsToMove then
				stats.should += 0.1
				if v < 0.5 then
					stats.idleShould += 0.1
					idleRun += 0.1
					if idleRun > worstIdle then worstIdle = idleRun; worstAt = st .. " at " .. tostring(p) end
				else
					idleRun = 0
				end
			else
				idleRun = 0
			end
			if v > 0.5 then stats.moving += 0.1 end
			if v > 40 then stats.slips += 1 end
			if math.floor(t * 10 + 0.5) % 20 == 0 then
				table.insert(trace, ("%.0f %s %s"):format(t, st, tostring(V(math.floor(p.X), math.floor(p.Y), math.floor(p.Z)))))
			end
		end
		for _, p in players do if p:GetAttribute("Captured") then stats.caught += 1 end end
		print(("%ds hunt: moving %.0f%%, wanted to move %.0fs of which stalled %.1fs, worst stall %.1fs (%s), slips %d, climbs %d"):format(
			DUR, stats.moving / DUR * 100, stats.should, stats.idleShould, worstIdle, worstAt, stats.slips, walker.Climbs))
		local list = {}
		for k, v in stats.states do table.insert(list, k .. "=" .. math.floor(v)) end
		print("time in states: " .. table.concat(list, " "))
		if process.args[4] == "trace" then print(table.concat(trace, "\n")) end
		assert(worstIdle < 3, "stalled")
	end
end)
for _, e in H.errors do print("ERR", e) end
print(okRun and ("NAVAI " .. MODE .. " OK") or ("NAVAI " .. MODE .. " FAIL: " .. tostring(err)))
