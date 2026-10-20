-- leap_test: v104 (a player: "most loopable enemy in horror games"). In the real house (navsim):
-- chasing someone with the dining table between them, he goes over it and lands on the far side;
-- never over a wall, never when nothing's in the way, never onto another floor. And a winded
-- player can't sprint until their breath is back.
local H = require("./env")
local Sim = require("./navsim")
local CACHE = "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/navgrid_cache.json"
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
ctx.Remotes = setmetatable({}, { __index = function(t, k)
	local r = { FireClient = function() end, FireAllClients = function() end, OnServerEvent = H.signal() }
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
Sim.navGrid(NavGrid, CACHE)
for _, k in names do if ctx[k].start then ctx[k].start() end end
ctx.Ending.trigger = function() end

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
local ok, err = pcall(function()
	ctx.Director.adminStart("Normal")
	ctx.Director.startAct("Guest")
	tick(2)
	I.setMode("Hunt")
	tick(1)
	assert(S.Model and S.InHouse, "he's in the house")
	I.adminFreeze(true)
	local G = 1
	local function standAt(p)
		S.Model:PivotTo(R.CFrame.new(V(p.X, G + 4.95, p.Z)))
		S.Root.Anchored = false
	end
	-- across the dining table (x -18..-12, z 13..22), the short way, between the chairs
	standAt(V(-22, G, 17.5))
	local target = V(-9.4, G + 3, 17.5)
	local landing, top = I._leapOver(target)
	print("dining table:", landing, top)
	assert(landing and top, "goes over the dining table")
	assert(landing.X > -12.2 and landing.X <= -9.3, ("lands past the table (x %.1f)"):format(landing.X))
	assert(top > G + 1.5 and top < G + 4.8, ("the table top (%.1f)"):format(top - G))
	I._leap(landing, top)
	tick(1.2)
	print("after the leap:", S.Root.Position, "anchored", S.Root.Anchored)
	assert(S.Root.Position.X > -12.5, "he's on the far side")
	assert(not S.Root.Anchored, "and back on his feet")
	assert(math.abs(S.Root.Position.Y - (G + 4.95)) < 1.2, ("on the floor (y %.1f)"):format(S.Root.Position.Y))
	-- the kitchen island (x -28..-22, z ~13..17), from the stove side to the stools
	standAt(V(-25, G, 9.6))
	local l2, t2 = I._leapOver(V(-25, G + 3, 21.6))
	print("kitchen island:", l2, t2)
	assert(l2 and l2.Z > 17, "goes over the kitchen island")
	-- nothing in the way: no leap
	standAt(V(-22, G, 26))
	assert(I._leapOver(V(-10, G + 3, 26)) == nil, "open floor: he just runs")
	-- a wall in the way (kitchen to living room): never
	standAt(V(-30, G, 6))
	assert(I._leapOver(V(-30, G + 3, -6)) == nil, "never over a wall")
	-- another floor: never
	standAt(V(-22, G, 17.5))
	assert(I._leapOver(V(-9.4, 18, 17.5)) == nil, "never onto another floor")
	print("leaps: ok")
end)
print(ok and "LEAP OK" or ("LEAP FAIL: " .. tostring(err)))

-- surprises: the closet ambush and the one behind you
local ok3, err3 = pcall(function()
	local G = 1
	local p, place = nil, nil
	do
		local pl = H.wrap(R.Instance.new("Player"))
		pl.Name = "Sam"
		rawset(pl, "UserId", 5)
		local char = H.Instance.new("Model")
		char.Name = "Sam"
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
		rawset(pl, "Character", char)
		rawset(pl, "Parent", H.workspaceRoot)
		pl:SetAttribute("InGame", true)
		p = pl
		place = function(pos, look)
			root.CFrame = look and H.CFrame.lookAt(pos, look) or R.CFrame.new(pos)
			head.CFrame = R.CFrame.new(pos + V(0, 2.5, 0))
		end
		Sim.track(char)
	end
	H.services.Players.GetPlayers = function() return { p } end
	I.adminFreeze(false)
	S.AdminFrozen = nil
	-- the closet: someone 20-30 studs from a closet, out in the open
	local spot
	for _, sp in ctx.Hiding.all() do
		if sp.Exit and sp.Exit.Position.Y < 10 then
			spot = sp
			break
		end
	end
	assert(spot, "a ground-floor hiding spot")
	local exit = spot.Exit.Position
	-- (stand somewhere 20 studs off, on the floor)
	local stand
	for _, n in ctx.Layout.Nodes do
		local d = (n.Pos - exit).Magnitude
		if d > 18 and d < 26 and math.abs(n.Pos.Y - exit.Y) < 4 then
			stand = n.Pos
			break
		end
	end
	assert(stand, "somewhere to stand")
	place(V(stand.X, exit.Y + 2, stand.Z))
	S.State = "Patrol"
	assert(I._surprise("closet"), "he hides in a closet")
	print("closet:", S.State, spot.Name)
	assert(S.State == "Closet", "waiting in the closet")
	spot = S.Data.Spot
	exit = spot.Exit.Position
	print("he chose", spot.Name)
	tick(1)
	assert(S.State == "Closet", "still waiting while nobody's close")
	local away = V(stand.X - exit.X, 0, stand.Z - exit.Z)
	place(V(exit.X, exit.Y + 2, exit.Z) + (away.Magnitude > 0.1 and away.Unit or V(1, 0, 0)) * 5)
	tick(0.3)
	print("walked up to it:", S.State, "warned", S.Data.Warned)
	assert(S.State == "Chase", "he bursts out")
	assert((S.Root.Position - exit).Magnitude < 4, "out of that closet")
	-- behind you: alone, out in the open, facing away
	p:SetAttribute("Captured", nil)
	S.State = "Patrol"
	S.Root.Anchored = false
	local here = V(-21, G + 3, 20.5)
	place(here) -- (facing -z)
	assert(I._surprise("behind"), "he's behind them")
	print("behind:", S.State, S.Root.Position)
	assert(S.State == "Stalk", "standing there")
	assert(S.Root.Position.Z > here.Z + 3, "behind them, not in front")
	tick(1)
	assert(S.State == "Stalk", "they haven't turned yet")
	place(here, S.Root.Position + V(0.4, 0, 0)) -- (they turn round)
	tick(0.3)
	print("turned round:", S.State)
	assert(S.State == "Chase", "he screams and comes for them")
	-- and if they never turn: gone after a few seconds
	S.State = "Patrol"
	S.Root.Anchored = false
	place(here)
	assert(I._surprise("behind"), "behind them again")
	tick(8)
	print("never turned:", S.State)
	assert(S.State ~= "Stalk" and S.State ~= "Chase", "he's gone again")
end)
print(ok3 and "SURPRISE OK" or ("SURPRISE FAIL: " .. tostring(err3)))

-- winded: run dry and there's no sprint until the breath is back to 35
local ok2, err2 = pcall(function()
	local M = ctx.Config.Movement
	assert(M.WindedRecover and M.WindedRecover >= 25, "a recovery threshold")
end)
print(ok2 and "WINDED CONFIG OK" or ("WINDED FAIL: " .. tostring(err2)))
