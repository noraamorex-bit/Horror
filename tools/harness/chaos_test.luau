-- chaos_test (v160): a three-player night in the hunt where players leave in the middle of things: one hiding while he
-- listens at their spot (the heartbeat running), one tied up, one in a call. Nothing may error, he mustn't keep chasing
-- or carrying someone who's gone, and the night must still end properly for whoever is left (out the front door).
-- Then a second night where the last player in the house leaves: the server must not be left with a stuck night.
local H = require("./env")
local T = 1000
H.clock = function() return T end
H.schedule = true
function H.flush(sec) for _ = 1, math.ceil(sec / 0.1) do T += 0.1; H.runDue(); H.services.RunService.Heartbeat:Fire(0.1) end end
local R = H.roblox
local V = R.Vector3.new

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
local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService", "Revive=ReviveService", "Cutscene=CutsceneService", "Heartbeat=HeartbeatService" }
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
local restarted = 0
ctx.restart = function() restarted += 1 end
rawset(H.services.PathfindingService, "CreatePath", function()
	local path = { Status = R.Enum.PathStatus.Success }
	function path:ComputeAsync(a, b) self.A, self.B = a, b end
	function path:GetWaypoints() return { { Position = self.A }, { Position = self.B } } end
	return path
end)

local players = {}
local function mkPlayer(name, id, at)
	local p = H.wrap(R.Instance.new("Player"))
	p.Name = name
	rawset(p, "UserId", id)
	local char = H.Instance.new("Model")
	local root = H.Instance.new("Part", char); root.Name = "HumanoidRootPart"
	local head = H.Instance.new("Part", char); head.Name = "Head"
	local hum = H.Instance.new("Humanoid", char); hum.Health = 100
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	p:SetAttribute("InGame", true)
	root.CFrame = R.CFrame.new(at)
	table.insert(players, p)
	return p, root
end
H.services.Players.GetPlayers = function()
	local out = {}
	for _, p in players do if rawget(p, "Parent") then table.insert(out, p) end end
	return out
end
local function leave(p)
	H.services.Players.PlayerRemoving:Fire(p)
	rawset(p, "Parent", nil)
	for i, q in players do if q == p then table.remove(players, i) break end end
end

local ok, err = pcall(function()
	local a, ra = mkPlayer("Hider", 11, V(-20, 4, -10))
	local b, rb = mkPlayer("Tied", 12, V(-24, 4, -12))
	local c, rc = mkPlayer("Caller", 13, ctx.Phone.signalSpot())
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	ctx.Director.adminStart("Normal")
	ctx.Director.startAct("SomeoneElse")
	H.flush(12)
	ctx.Intruder.setMode("Hunt")
	H.flush(2)
	-- a hides, and he comes to listen: the heartbeat starts for them
	local spot = ctx.Hiding.spotsNear(ra.Position, 60)[1]
	assert(spot, "a hiding spot near the hider")
	ra.CFrame = R.CFrame.new(spot.Exit.Position)
	ctx.Hiding.enter(a, spot)
	assert(ctx.Hiding.spotOf(a) == spot, "hidden")
	ctx.Heartbeat.begin(a, 8, function() end)
	assert(ctx.Heartbeat.isActive(a), "the heartbeat runs")
	-- b is caught
	ctx.Capture.capture(b)
	H.flush(3)
	assert(ctx.Capture.isCaptured(b) or b:GetAttribute("Captured"), "tied up")
	-- c starts the call
	ctx.Phone.startCall(c)
	H.flush(1)
	-- now a and b leave, mid-heartbeat and tied up
	leave(a)
	H.flush(2)
	leave(b)
	H.flush(5)
	local S = ctx.Intruder._state and ctx.Intruder._state()
	if S then
		assert(S.HuntTarget ~= a and S.HuntTarget ~= b, "he isn't still after someone who left")
		assert(not (S.Data and (S.Data.Victim == a or S.Data.Victim == b)), "he isn't carrying someone who left")
	end
	assert(not ctx.Heartbeat.isActive(a), "the heartbeat stopped for the player who left")
	assert(#ctx.Capture.captives() == 0, "nobody tied up who's gone: " .. #ctx.Capture.captives())
	-- c finishes the call (it may drop: the attic chapter), then the police and the last run
	for _ = 1, 40 do rc.CFrame = R.CFrame.new(ctx.Phone.signalSpot()); c:SetAttribute("Signal", 3); H.flush(1) end
	ctx.Escape.finalRun()
	H.flush(2)
	-- out the front door
	rc.CFrame = R.CFrame.new(2, 2, -36)
	H.flush(8)
	assert(ctx.Ending.isOver() or c:GetAttribute("Escaped"), "the night ends for the last one standing (escaped " .. tostring(c:GetAttribute("Escaped")) .. ")")
	print("leavers handled, ending ok")
	-- everyone leaves: nothing errors afterwards
	leave(c)
	H.flush(10)
	print("empty server ok")
end)
local errs = {}
for _, e in H.errors do if not string.find(tostring(e), "TextChannels", 1, true) then table.insert(errs, tostring(e)) end end
print(ok and (#errs == 0 and "CHAOS OK" or "CHAOS FAIL: errors") or ("CHAOS FAIL: " .. tostring(err)))
for _, e in errs do print(e:sub(1, 1500)) end
