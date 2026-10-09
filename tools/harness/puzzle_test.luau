-- puzzle_test: the electrics puzzles. Puzzle.check accepts only right answers (wires join their
-- colour; breaker taps replayed, MAIN last with everything on); the splice prompt opens the Wires
-- puzzle and only a right answer repairs the line; the MAIN opens the Breakers puzzle and only
-- solving it brings the power back; walking off closes it.
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
	local fired = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { FireClient = function(_, p, a) table.insert(fired, { k, p, a }) end, FireAllClients = function() end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService", "Puzzle=PuzzleService" }
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
	local P = ctx.Puzzle

	-- pure checks
	for _ = 1, 50 do
		local n = math.random(3, 4)
		local w = P.wires(n)
		assert(#w.Left == n and #w.Right == n, "wire count")
		local same = true
		for i = 1, n do same = same and w.Left[i] == w.Right[i] end
		assert(not same, "right side is shuffled")
		local ans = {}
		for i = 1, n do ans[i] = table.find(w.Right, w.Left[i]) end
		assert(P.check("Wires", w, ans), "right wiring passes")
		local bad = table.clone(ans)
		bad[1], bad[2] = bad[2], bad[1]
		assert(not P.check("Wires", w, bad), "crossed wires fail")
		assert(not P.check("Wires", w, { ans[1], ans[1], ans[3], ans[4] }), "one end twice fails")
		assert(not P.check("Wires", w, "x"), "junk fails")
	end
	for _ = 1, 50 do
		local b = P.breakers()
		assert(#b.Tripped == 3, "three tripped")
		local taps = table.clone(b.Tripped)
		table.insert(taps, 0)
		assert(P.check("Breakers", b, taps), "reset tripped then MAIN passes")
		assert(not P.check("Breakers", b, { 0 }), "MAIN alone fails")
		assert(not P.check("Breakers", b, { b.Tripped[1], 0 }), "MAIN with some still off fails")
		local good = 1
		while table.find(b.Tripped, good) do good += 1 end
		local wobble = { good, good }
		for _, t in b.Tripped do table.insert(wobble, t) end
		table.insert(wobble, 0)
		assert(P.check("Breakers", b, wobble), "a good one flipped off and back still passes")
		local extra = table.clone(taps)
		table.insert(extra, 1)
		assert(not P.check("Breakers", b, extra), "taps after the MAIN fail")
		assert(not P.check("Breakers", b, { 1.5, 0 }), "junk taps fail")
		assert(not P.check("Breakers", b, { 99, 0 }), "out of range fails")
	end
	print("checks ok")

	-- in the house
	local roblox = H.roblox
	local p = H.wrap(roblox.Instance.new("Player"))
	p.Name = "Tester"
	local char = H.Instance.new("Model")
	local rootPart = H.Instance.new("Part", char)
	rootPart.Name = "HumanoidRootPart"
	local hum = H.Instance.new("Humanoid", char)
	hum.Health = 100
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	H.services.Players.GetPlayers = function() return { p } end
	p:SetAttribute("InGame", true)
	p:SetAttribute("Role", "Host")
	ctx.Director.startAct("Evening")
	ctx.Director.startAct("SomeoneElse")
	ctx.Power.setMain(false, "Intruder")
	ctx.Escape.cutLine()
	local world = H.unwrap(ctx.World.folder())
	local function find(partName)
		for _, d in world:GetDescendants() do
			if d:IsA("BasePart") and d.Name == partName then return d end
		end
	end
	local function press(partName, action)
		for _, d in world:GetDescendants() do
			if d:IsA("ProximityPrompt") and d.Parent and (d.Parent.Name == partName or (d.Parent.Parent and d.Parent.Parent.Name == partName)) and (not action or d.ActionText == action) then
				local sig = rawget(H.wrap(d), "__signals")
				sig = sig and sig.Triggered
				if sig then sig:Fire(p); return true end
			end
		end
		error("no prompt " .. partName .. " " .. tostring(action))
	end
	local function lastPuzzle()
		local r
		for _, f in fired do if f[1] == "Puzzle" and f[2] == p then r = f[3] end end
		return r
	end
	local function input(...) ctx.Remotes.PuzzleInput.OnServerEvent:Fire(p, ...) end
	local box = find("BoxDoor")
	rootPart.CFrame = roblox.CFrame.new(box.CFrame.Position + roblox.Vector3.new(0, 0, 2))
	ctx.Inventory.give(p, "ElectricalTape")
	rootPart.CFrame = roblox.CFrame.new(box.CFrame.Position + roblox.Vector3.new(0, 0, 2))
	assert(ctx.Inventory.has(p, "ElectricalTape"), "has tape")
	press("BoxDoor", "Splice the wires")
	local pz = lastPuzzle()
	assert(pz and pz.Kind == "Wires" and #pz.Data.Left == 4, "splice opens a 4-wire puzzle")
	assert(not ctx.Escape.isLineWorking(), "not repaired yet")
	-- wrong answer: a spark, still open, still cut
	local ans = {}
	for i = 1, 4 do ans[i] = table.find(pz.Data.Right, pz.Data.Left[i]) end
	local bad = table.clone(ans); bad[1], bad[2] = bad[2], bad[1]
	input(pz.Id, "Submit", bad)
	assert(P.isOpen(p) and not ctx.Escape.isLineWorking(), "wrong wiring doesn't repair")
	input(pz.Id + 1, "Submit", ans)
	assert(not ctx.Escape.isLineWorking(), "stale id ignored")
	input(pz.Id, "Submit", ans)
	H.runDue()
	assert(ctx.Escape.isLineWorking(), "right wiring repairs the line")
	assert(not P.isOpen(p) and lastPuzzle().Result == "Solved", "closed as solved")
	print("wires ok")

	-- breakers
	local lever = find("MainLever")
	rootPart.CFrame = roblox.CFrame.new(lever.CFrame.Position + roblox.Vector3.new(0, 0, 2))
	assert(not ctx.Power.isOn(), "power off")
	press("MainLever")
	local bz = lastPuzzle()
	assert(bz and bz.Kind == "Breakers", "MAIN opens the breaker puzzle")
	assert(not ctx.Power.isOn(), "still off until solved")
	input(bz.Id, "Submit", { 0 })
	assert(not ctx.Power.isOn(), "MAIN alone does nothing")
	-- walk away: it closes
	rootPart.CFrame = roblox.CFrame.new(lever.CFrame.Position + roblox.Vector3.new(0, 0, 30))
	input(bz.Id, "Click")
	assert(not P.isOpen(p), "walking off closes it")
	rootPart.CFrame = roblox.CFrame.new(lever.CFrame.Position + roblox.Vector3.new(0, 0, 2))
	press("MainLever")
	bz = lastPuzzle()
	local taps = table.clone(bz.Data.Tripped); table.insert(taps, 0)
	input(bz.Id, "Submit", taps)
	H.runDue()
	assert(ctx.Power.isOn(), "solved: the power is back")
	-- flipping it off is instant
	press("MainLever")
	assert(not ctx.Power.isOn(), "off is instant")
	print("breakers ok")
end)
print(ok and "PUZZLE OK" or ("PUZZLE FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
