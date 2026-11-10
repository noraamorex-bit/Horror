-- attic_test (v154, Director/AtticRun, the owner's pick "Into the attic"): the first 911 call from the bathroom window
-- gets through and drops; no help, zero bars everywhere, the objective becomes the attic. The booster in his nest
-- plugs back in (only then), full bars up there; the ladder creaks and he comes up through the hatch after whoever is in
-- the attic; a call from the attic brings the police. With nobody left up there, he goes back down. Two hiding spots up there.
local H = require("./env")
local T = 1000
H.clock = function() return T end
H.schedule = true
function H.flush(sec) for _ = 1, math.ceil(sec / 0.1) do T += 0.1; H.runDue() end end
local R = H.roblox
local function setup()
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
	return ctx
end
local function mkPlayer(name)
	local p = H.wrap(R.Instance.new("Player"))
	p.Name = name
	local char = H.Instance.new("Model")
	local rootPart = H.Instance.new("Part", char)
	rootPart.Name = "HumanoidRootPart"
	local hum = H.Instance.new("Humanoid", char)
	hum.Health = 100
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	p:SetAttribute("InGame", true)
	return p, rootPart
end
local function has(list, id)
	for _, o in list do if o.Id == id then return o end end
	return nil
end
local ok, err = pcall(function()
	local ctx = setup()
	local p, root = mkPlayer("Caller")
	H.services.Players.GetPlayers = function() return { p } end
	local sent = nil
	ctx.Remotes.Objectives.FireAllClients = function(_, list) sent = list end
	local thoughts = {}
	ctx.Remotes.Thought.FireClient = function(_, who, text) table.insert(thoughts, text) end
	local spot = ctx.Phone.signalSpot()
	root.CFrame = R.CFrame.new(spot)
	ctx.Director.startAct("SomeoneElse")
	H.flush(10)
	assert(not ctx.Power.isOn(), "the blackout")
	local world = H.unwrap(ctx.World.folder())
	local function prompt(name, parentName)
		for _, d in world:GetDescendants() do
			if d:IsA("ProximityPrompt") and d.Name == name and (not parentName or d.Parent.Name == parentName) then return H.wrap(d) end
		end
		return nil
	end
	-- the window: the call gets through... and drops
	local function workspace_dead() return H.workspaceRoot:GetAttribute("SignalDead") == true end
	local window = nil
	for _, d in world:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "Call911" and d.Parent.Name ~= "SignalBooster" then window = H.wrap(d) end
	end
	assert(window, "the window's Call 911")
	H.flush(0.5)
	p:SetAttribute("Signal", 1)
	rawget(window, "__signals").Triggered:Fire(p)
	for _ = 1, ctx.Config.Help.CellCallDurationNormal + 2 do
		if not workspace_dead() then p:SetAttribute("Signal", 1) end
		H.flush(1)
	end
	local ws = H.unwrap(H.workspaceRoot)
	assert(not ctx.Escape.helpCalled(), "the first call from the window brings no help")
	assert(ws:GetAttribute("SignalDead") == true, "zero bars now")
	-- (PlayerState's tick isn't driven here: ask its signal function directly)
	local function bars(at) return ctx.PlayerState._signal(at) end
	assert(bars(spot) == 0, "zero bars even at the window: " .. bars(spot))
	H.flush(3)
	local booster = has(sent, "Booster")
	assert(booster and not booster.Optional, "the attic is the goal now")
	assert(not has(sent, "Call911"), "the window's call is gone from the list")
	local said = false
	local dead = ctx.Story.Thoughts.BoosterDead:match("^(.-)|")
	for _, t in thoughts do if t == dead then said = true end end
	assert(said, "told why: the booster in the attic")
	-- up the hatch
	local hatch = prompt("Prompt", nil)
	for _, d in world:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.ObjectText == "Attic hatch" then hatch = H.wrap(d) end
	end
	rawget(hatch, "__signals").Triggered:Fire(p)
	H.flush(0.5)
	booster = has(sent, "Booster")
	assert(booster.Current and booster.Current:find("booster"), "next: the booster: " .. tostring(booster.Current))
	-- in the attic: plug it in
	local plug = prompt("PlugBooster")
	assert(plug and plug.Enabled, "the booster can be plugged in now")
	local attic = R.CFrame.new(-25, 32.5, -5)
	root.CFrame = attic
	local climbed = nil
	local realClimb = ctx.Intruder.climbInto
	ctx.Intruder.climbInto = function(at, look, target) climbed = { at, target }; return realClimb(at, look, target) end
	-- (the harness's Model:PivotTo doesn't move parts; in the engine it moves the whole rig)
	H.onPivotTo = function(model, cf)
		local r = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
		if r then r.CFrame = cf end
	end
	rawget(plug, "__signals").Triggered:Fire(p)
	assert(ws:GetAttribute("BoosterOn") == true and not ws:GetAttribute("SignalDead"), "plugged in")
	assert(bars(attic.Position) == 3, "full bars up in the attic: " .. bars(attic.Position))
	assert(bars(spot) == 1, "the window's bar is back")
	local onLadder = ctx.Story.Thoughts.OnTheLadder:match("^(.-)|")
	H.flush(ctx.Config.Attic.HeHearsAfter + 0.5)
	local warned = false
	for _, t in thoughts do if t == onLadder then warned = true end end
	assert(warned, "the ladder creaks: HIDE")
	H.flush(ctx.Config.Attic.ClimbDelay + 0.5)
	assert(climbed and climbed[2] == p and (climbed[1] - ctx.Layout.Attic.HatchTop).Magnitude < 1, "he comes up through the hatch, after me")
	assert(ctx.Rooms.floorOf(ctx.Intruder.position()) == "Attic", "he's in the attic")
	-- two places to hide up there
	local n = 0
	for _, d in world:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "Hide" and (d.ObjectText == "Under the dust sheet" or d.ObjectText == "In the old trunk") then n += 1 end
	end
	assert(n == 2, "two hiding spots in the attic, got " .. n)
	-- the call from the attic brings the police
	local fromAttic = prompt("Call911", "SignalBooster")
	assert(fromAttic and fromAttic.Enabled, "a Call 911 on the booster")
	ctx.Intruder.adminFreeze(true) -- (the call itself; he's tested elsewhere)
	rawget(fromAttic, "__signals").Triggered:Fire(p)
	assert(p:GetAttribute("Calling") == true, "calling from the attic")
	for _ = 1, ctx.Config.Help.CellCallDurationNormal + 2 do root.CFrame = attic; p:SetAttribute("Signal", 3); H.flush(1) end
	assert(ctx.Escape.helpCalled(), "help is on the way")
	H.flush(1)
	local ids = {}
	for _, o in sent do table.insert(ids, o.Id .. (o.Done and "(done)" or "")) end
	assert(has(sent, "Survive") and not (has(sent, "Booster") and not has(sent, "Booster").Done), "survive until they come: " .. table.concat(ids, ","))
	-- nobody left up there: he goes back down the ladder
	ctx.Intruder.adminFreeze(false)
	root.CFrame = R.CFrame.new(0, 18, -20)
	H.flush(ctx.Config.Attic.LeaveAfter + 2.5)
	assert(ctx.Rooms.floorOf(ctx.Intruder.position()) ~= "Attic", "back down the hatch: " .. tostring(ctx.Intruder.position()))
	print("attic ok")
end)
print(ok and "ATTIC OK" or ("ATTIC FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
