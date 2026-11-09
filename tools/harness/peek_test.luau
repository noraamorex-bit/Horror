-- peek_test (v147, the owner: "Make a way to peek out of hiding spots"): in the real house (navsim):
-- 1) every hiding spot's lean-out point is reachable from its view without going through a wall, and
--    from there you can see out (towards the way out)
-- 2) peeking: "Peeking" + HidePeek, a wardrobe's doors open a crack and shut again, the eye moves
-- 3) he catches you at it: facing you, close, PeekSeenTime seconds -> he comes for the spot as if
--    he'd watched you get in ("PeekWatched" meanwhile); not peeking, or behind him: nothing
-- 4) he stops to listen at your door (the heartbeat): you duck back in, and can't lean out again
local H = require("./env")
local Sim = require("./navsim")
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
ctx.ActPose = H.load("RS/Shared/ActPose")
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
for _, k in names do if ctx[k].start then ctx[k].start() end end
ctx.Ending.trigger = function() end

local function mkPlayer(name, id)
	local p = H.wrap(R.Instance.new("Player"))
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
local function tick(sec) for _ = 1, math.max(1, math.floor(sec * 10 + 0.5)) do H.services.RunService.Heartbeat:Fire(0.1); T += 0.1; H.runDue() end end

local ok, err = pcall(function()
	H.services.RunService.IsStudio = function() return false end
	local a = mkPlayer("A", 1)
	H.services.Players.GetPlayers = function() return { a } end
	local Hd = ctx.Config.Hiding

	-- 1) geometry
	local spots = ctx.Hiding.all()
	assert(#spots >= 10, "hiding spots: " .. #spots)
	local params: any = { RespectCanCollide = true }
	for _, s in spots do
		assert(s.Peek, s.Name .. ": a peek view")
		local from, to = s.View.Position, s.Peek.Position
		local out = (to - from).Magnitude
		assert(out <= Hd.PeekOut + 0.01, s.Name .. (": leans %.2f studs"):format(out))
		local holder = s.Part.Parent
		params.FilterDescendantsInstances = { holder }
		if out > 0.05 then
			local hit = Sim.raycast(from, to - from, params)
			assert(not hit, s.Name .. ": leaning out goes through " .. (hit and hit.Instance:GetFullName() or "?"))
		end
		-- from the peek point the way out is in sight (low exits: aim at chest height)
		local ex = s.Exit.Position
		local hit2 = Sim.raycast(to, ex - to, params)
		assert(not hit2, s.Name .. ": from the peek point the way out is blocked by " .. (hit2 and hit2.Instance:GetFullName() or "?"))
		print(("%-34s out %.2f"):format(s.Name, out))
	end

	-- 2) peeking from a wardrobe
	local closet
	for _, s in spots do if s.Name == "Coat closet" then closet = s end end
	assert(closet, "the coat closet")
	ctx.Hiding.enter(a, closet)
	assert(a:GetAttribute("Hiding") == "Coat closet", "hidden")
	assert(typeof(a:GetAttribute("HidePeek")) == "CFrame", "HidePeek published")
	local leaf
	for _, d in closet.Part.Parent:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Leaf") then leaf = d break end
	end
	assert(leaf, "a leaf")
	tick(2) -- (getting in swings the doors: let them shut)
	local closed = leaf:GetAttribute("Closed")
	assert((leaf.CFrame.Position - closed.Position).Magnitude < 0.01, "doors shut after getting in")
	ctx.Hiding.peek(a, true)
	assert(a:GetAttribute("Peeking") == true, "peeking")
	tick(1)
	local ajar = (leaf.CFrame.Position - closed.Position).Magnitude
	assert(ajar > 0.05, ("the doors ease open a crack (%.2f)"):format(ajar))
	ctx.Hiding.peek(a, false)
	assert(not a:GetAttribute("Peeking"), "back in")
	tick(1)
	assert((leaf.CFrame.Position - closed.Position).Magnitude < 0.01, "the doors shut again")
	-- rate limit: a burst of toggles doesn't flap the doors
	ctx.Hiding.peek(a, true)
	ctx.Hiding.peek(a, false)
	ctx.Hiding.peek(a, true)
	assert(not a:GetAttribute("Peeking"), "toggles within 0.25 s are ignored")
	tick(0.5)

	-- 3) he catches you
	ctx.Director.adminStart("Normal")
	ctx.Director.startAct("Guest")
	tick(3)
	local I = ctx.Intruder
	local S = I._state()
	assert(S.InHouse, "he's in the house")
	I.setMode("Hunt")
	S.NextSense = 1e12
	S.NextPursue = 1e12
	local peekAt = closet.Peek.Position
	local outDir = ((closet.Exit.Position - closet.View.Position) * V(1, 0, 1)).Unit
	local eye = peekAt + outDir * 8
	local facing = R.CFrame.lookAt(eye, peekAt)
	local away = R.CFrame.lookAt(eye, eye + outDir)
	local function patrol()
		S.State = "Patrol"; S.Data = { Route = {}, Index = 0, Moving = true, PauseUntil = 1e12 }; S.SawHide = {}
	end
	-- not peeking: nothing
	patrol()
	I._watchPeekers(0.3, facing); I._watchPeekers(0.5, facing)
	assert(S.State == "Patrol" and not a:GetAttribute("PeekWatched"), "hidden and not peeking: he sees nothing")
	ctx.Hiding.peek(a, true)
	assert(a:GetAttribute("Peeking"), "peeking again")
	-- peeking behind his back: nothing
	I._watchPeekers(0.3, away); I._watchPeekers(0.5, away)
	assert(S.State == "Patrol" and not a:GetAttribute("PeekWatched"), "behind him: not seen")
	-- too far: nothing
	local farEye = peekAt + outDir * (Hd.PeekSeenRange + 3)
	if not Sim.raycast(farEye, peekAt - farEye, params) then
		I._watchPeekers(0.5, R.CFrame.lookAt(farEye, peekAt)); I._watchPeekers(0.5, R.CFrame.lookAt(farEye, peekAt))
		assert(S.State == "Patrol", "out of range: not seen")
	end
	-- facing, close: a moment's warning, then seen
	I._watchPeekers(Hd.PeekSeenTime * 0.5, facing)
	assert(a:GetAttribute("PeekWatched") == true and S.State == "Patrol", "his eyes on you: the warning first")
	-- ducking back in clears it
	ctx.Hiding.peek(a, false)
	I._watchPeekers(0.1, facing)
	assert(not a:GetAttribute("PeekWatched") and S.State == "Patrol", "ducked back in time: safe")
	tick(0.3)
	ctx.Hiding.peek(a, true)
	I._watchPeekers(Hd.PeekSeenTime * 0.6, facing)
	I._watchPeekers(Hd.PeekSeenTime * 0.6, facing)
	assert(S.State == "CheckSpot" and S.Data.Spot == closet, "seen peeking: he comes for the spot, got " .. tostring(S.State))
	assert(S.SawHide[closet], "...as if he'd watched you get in")
	assert(not a:GetAttribute("PeekWatched"), "the warning's over")

	-- 3b) (v148) the stare: a loud run at someone who can see him starts with him stopped dead, staring; then he charges
	do
		ctx.Hiding.exit(a)
		tick(0.3)
		local stand = closet.Exit.Position
		local himAt = stand + outDir * 16
		S.Model:PivotTo(R.CFrame.lookAt(himAt + V(0, 4.95 - 3, 0), stand))
		local root = ctx.Util.getRoot(a)
		root.CFrame = R.CFrame.lookAt(stand, himAt * V(1, 0, 1) + V(0, stand.Y, 0))
		local headP = a.Character:FindFirstChild("Head")
		headP.CFrame = root.CFrame + V(0, 1.6, 0)
		if not Sim.raycast(headP.Position, S.Head.Position - headP.Position, { FilterDescendantsInstances = { S.Model, a.Character } }) then
			patrol()
			S.HoldUntil = 0 -- (an earlier section left him held still for a moment)
			S.NextSense = 0
			S.SensedAt = {}
			S.SenseCut = true
			I._senseTick()
			assert(S.State == "Glare" and S.Data.Target == a, "seen: he stops and stares first, got " .. tostring(S.State))
			local glare = I._tune().GlareFor
			assert(glare and glare > 0.5, "a stare of " .. tostring(glare) .. " s")
			for _ = 1, math.ceil((glare + 0.4) * 10) do tick(0.1); if S.State ~= "Glare" then break end end
			assert(S.State == "Charge" or S.State == "Chase", "then he comes, got " .. tostring(S.State))
			-- hidden or behind him: no stare, straight into the run
			patrol()
			root.CFrame = R.CFrame.lookAt(stand, stand - outDir * 10)
			headP.CFrame = root.CFrame + V(0, 1.6, 0)
			S.NextSense = 0
			S.SensedAt = {}
			I._senseTick()
			assert(S.State ~= "Glare", "not seen: no stare, got " .. tostring(S.State))
		else
			print("(stare check skipped: no clear line from this spot)")
		end
		ctx.Hiding.enter(a, closet)
		tick(0.3)
	end

	-- 4) the heartbeat pulls you back in
	patrol()
	tick(0.3)
	ctx.Hiding.peek(a, true)
	assert(a:GetAttribute("Peeking"), "peeking before he listens")
	ctx.Heartbeat.begin(a, 6, function() end)
	assert(not a:GetAttribute("Peeking"), "he stops at the door: you duck back in")
	tick(0.4)
	ctx.Hiding.peek(a, true)
	assert(not a:GetAttribute("Peeking"), "no leaning out while he's listening")
	ctx.Heartbeat.stop(a)
	-- leaving clears it all
	tick(0.4)
	ctx.Hiding.peek(a, true)
	ctx.Hiding.exit(a)
	assert(not a:GetAttribute("Peeking") and not a:GetAttribute("HidePeek"), "getting out clears the peek")
	tick(1)
	-- 5) (v147 animations) what you're doing goes on your player for every client to pose
	ctx.Interaction.act(a, "Brush", true)
	assert(a:GetAttribute("Act") == "Brush" and a:GetAttribute("ActHold"), "brushing (held)")
	tick(3)
	assert(a:GetAttribute("Act") == "Brush", "a hold lasts while it's held")
	ctx.Interaction.release(a, "Brush")
	assert(not a:GetAttribute("ActHold"), "let go")
	tick(ctx.ActPose.Kinds.Brush.Time + 0.5)
	assert(a:GetAttribute("Act") == nil, "winds down after its time")
	ctx.Interaction.act(a, "Take")
	assert(a:GetAttribute("Act") == "Take", "a one-shot")
	tick(ctx.ActPose.Kinds.Take.Time + 0.5)
	assert(a:GetAttribute("Act") == nil, "a one-shot clears itself")
	ctx.Interaction.act(a, "Take")
	tick(0.3)
	ctx.Interaction.act(a, "Knock")
	tick(ctx.ActPose.Kinds.Take.Time)
	assert(a:GetAttribute("Act") == "Knock", "a newer action isn't cleared by the older one's timer")
	ctx.Hiding.enter(a, closet)
	ctx.Interaction.act(a, "Take")
	assert(a:GetAttribute("Act") ~= "Take", "nothing while hidden")
	ctx.Hiding.exit(a)
	assert(ctx.ActPose.kindFor("Brush your teeth") == "Brush", "the sink's prompt")
end)
if not ok then
	print("FAIL", err)
else
	print("OK peek_test")
end
