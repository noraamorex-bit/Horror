-- hunt_goal_test: when the power dies, the objectives become the ways out, the quickest first
-- (Call 911 from the one bar of signal upstairs); a Call 911 prompt waits by the bathroom window
-- and only works there; holding the call brings the police (Survive). Plus the veteran pacing:
-- a group that has all played before gets one chore fewer.
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

	-- the act starts: nothing to run from yet, so no objectives
	ctx.Director.startAct("SomeoneElse")
	assert(sent and #sent == 0, "no objectives before the blackout")
	-- the breaker drops (8 s after the chapter card): the ways out
	H.flush(10)
	assert(not ctx.Power.isOn(), "the power is off")
	local call = has(sent, "Call911")
	assert(call and not call.Optional, "Call 911 is the main goal")
	for _, id in { "Neighbor", "Car", "Attic", "Power" } do
		local o = has(sent, id)
		assert(o and o.Optional, id .. " is there, optional")
	end
	assert(sent[1].Id == "Call911", "Call 911 first")
	assert(call.Current and call.Current:find("bathroom window"), "the step says where the signal is")
	assert(#call.Targets >= 1, "a marker for it")

	-- the Call 911 prompt by the bathroom window
	local world = H.unwrap(ctx.World.folder())
	local prompt = nil
	for _, d in world:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "Call911" then prompt = H.wrap(d) end
	end
	assert(prompt, "a Call 911 prompt exists")
	H.flush(0.5)
	assert(prompt.Enabled == true, "it's on once he's in the house")
	local spot = prompt.Parent.Position
	assert(ctx.Rooms.find(spot) and ctx.Rooms.find(spot).Name == "HallBath" and spot.X > 33, "it sits where the bar of signal is")
	-- not standing in the signal: it says so, no call
	root.CFrame = R.CFrame.new(0, 20, 0)
	p:SetAttribute("Signal", 0)
	rawget(prompt, "__signals").Triggered:Fire(p)
	assert(not p:GetAttribute("Calling"), "no call without signal")
	-- in the signal: the call goes through after CellCallDuration
	root.CFrame = R.CFrame.new(spot)
	p:SetAttribute("Signal", 1)
	rawget(prompt, "__signals").Triggered:Fire(p)
	assert(p:GetAttribute("Calling") == true, "calling")
	-- (PlayerState recomputes Signal from the position every tick: keep it there)
	for _ = 1, 20 do p:SetAttribute("Signal", 1); H.flush(1) end
	assert(ctx.Escape.helpCalled(), "help is on the way")
	assert(has(sent, "Survive"), "survive until they come")
	assert(not has(sent, "Neighbor") and not has(sent, "Car"), "the other ways out are gone")
	H.flush(0.5)
	assert(prompt.Enabled == false, "the prompt goes once help is called")

	-- veteran pacing: a group that has all played before
	-- (one world per test file: modules are shared; back to the house's own lobby state)
	local ctx2 = ctx
	ctx2.Director.enterLobby()
	local a = mkPlayer("Vet1")
	local b = mkPlayer("Vet2")
	a:SetAttribute("StatNights", 3); b:SetAttribute("StatNights", 1)
	H.services.Players.GetPlayers = function() return { a, b } end
	local list2 = nil
	ctx2.Remotes.Objectives.FireAllClients = function(_, l) list2 = l end
	ctx2.Director.adminStart("Normal")
	assert(H.unwrap(H.workspaceRoot):GetAttribute("VeteranNight") == true, "a veteran night")
	assert(list2 and #list2 == 2 and not has(list2, "Popcorn"), "one chore fewer")
	-- a first-timer joins the group: the full build-up
	local ctx3 = ctx
	ctx3.Director.enterLobby()
	local c = mkPlayer("New")
	H.services.Players.GetPlayers = function() return { a, c } end
	local list3 = nil
	ctx3.Remotes.Objectives.FireAllClients = function(_, l) list3 = l end
	ctx3.Director.adminStart("Normal")
	assert(H.unwrap(H.workspaceRoot):GetAttribute("VeteranNight") == nil, "not with a first-timer")
	assert(list3 and has(list3, "Popcorn"), "all three chores")
	print("hunt goal ok")
end)
print(ok and "HUNTGOAL OK" or ("HUNTGOAL FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
