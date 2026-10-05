-- vote_test: the NORMAL / HARD vote before the night. A tie stays Normal; a HARD majority makes
-- him faster, the police slower and the last chance shorter. Run with arg "tie" or "hard".
local H = require("./env")
local function setup()
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
		local r = { FireClient = function(_, p, a) table.insert(fired, { k, p, a }) end, FireAllClients = function(_, a) table.insert(fired, { k, nil, a }) end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
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
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	return ctx, fired
end
local function mkPlayer(name)
	local roblox = H.roblox
	local p = H.wrap(roblox.Instance.new("Player"))
	p.Name = name
	local char = H.Instance.new("Model")
	local rootPart = H.Instance.new("Part", char)
	rootPart.Name = "HumanoidRootPart"
	local hum = H.Instance.new("Humanoid", char)
	hum.Health = 100
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	return p
end
local function last(fired, kind, p)
	for i = #fired, 1, -1 do
		if fired[i][1] == kind and (p == nil or fired[i][2] == p) then return fired[i][3] end
	end
	return nil
end
local MODE = require("@lune/process").args[1] or "tie"
local ws = H.unwrap(H.workspaceRoot)
local ok, err = pcall(function()
	local ctx, fired = setup()
	local a, b = mkPlayer("A"), mkPlayer("B")
	H.services.Players.GetPlayers = function() return { a, b } end
	local normalChase = ctx.Intruder._tune().ChaseSpeed
	ctx.Director._beginVote()
	local v = last(fired, "Vote", a)
	assert(v and v.Ends and v.Total == 2 and v.Normal == 0 and v.Hard == 0, "vote opens for everyone")
	assert(last(fired, "Lobby").Phase == "Vote", "lobby card hides during the vote")
	-- bad input is ignored
	ctx.Remotes.CastVote.OnServerEvent:Fire(a, "Impossible")
	assert(last(fired, "Vote", a).Hard == 0 and last(fired, "Vote", a).Normal == 0, "junk vote ignored")
	ctx.Remotes.CastVote.OnServerEvent:Fire(a, "Hard")
	ctx.Remotes.CastVote.OnServerEvent:Fire(a, "Normal")
	ctx.Remotes.CastVote.OnServerEvent:Fire(a, "Hard") -- changing your mind is fine
	assert(last(fired, "Vote", a).Hard == 1 and last(fired, "Vote", a).Mine == "Hard", "vote counted once, latest choice")
	assert(ctx.Director._voteTick() == true and ws:GetAttribute("Difficulty") == nil, "still open with one vote missing")
	ctx.Remotes.CastVote.OnServerEvent:Fire(b, MODE == "hard" and "Hard" or "Normal")
	ctx.Director._voteTick()
	assert(ws:GetAttribute("Act") == "Lobby", "the result shows for a moment first")
	ctx.Remotes.CastVote.OnServerEvent:Fire(a, "Normal") -- too late to change it
	local t0 = os.clock()
	while os.clock() - t0 < 2.1 do end
	ctx.Director._voteTick()
	local res = last(fired, "Vote", b)
	print(MODE, "result", res and res.Result, "attr", ws:GetAttribute("Difficulty"), "act", ws:GetAttribute("Act"))
	local want = MODE == "hard" and "Hard" or "Normal"
	assert(res and res.Result == want and ws:GetAttribute("Difficulty") == want, "result " .. want)
	assert(ws:GetAttribute("Act") ~= "Lobby", "the night starts after the vote")
	assert(ctx.Director._voteTick() == false, "vote closed")
	-- the effects
	local chase = ctx.Intruder._tune().ChaseSpeed
	ctx.Escape.callForHelp("Phone", a)
	local eta = ws:GetAttribute("PoliceETA") - os.clock()
	print("chase", normalChase, "->", chase, "police eta", math.floor(eta + 0.5))
	if MODE == "hard" then
		assert(chase == ctx.Config.Difficulty.Hard.Intruder.ChaseSpeed and chase > normalChase, "hard: he is faster")
		assert(math.abs(eta - ctx.Config.Help.PhoneResponse * ctx.Config.Difficulty.Hard.PoliceMultiplier) < 1.5, "hard: help takes longer")
	else
		assert(chase == normalChase, "normal: base speed")
		assert(math.abs(eta - ctx.Config.Help.PhoneResponse) < 1.5, "normal: base police time")
	end
	-- back to the lobby clears it
	ctx.Director.enterLobby()
	assert(ws:GetAttribute("Difficulty") == nil, "difficulty cleared for the next night")
end)
print(ok and ("VOTE OK " .. MODE) or ("VOTE FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
