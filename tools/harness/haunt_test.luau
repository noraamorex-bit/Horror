-- haunt_test (v131, the owner: "Make the map (house) much better... Add way more scares. Actually scary and
-- creepy stuff."): the attic and the rest of World/Haunt are built, the drawings are drawn, and each of the new
-- scares (Director/Events) fires where it should and does what it says: footsteps that follow you, Lily's ball
-- down the stairs, her bears turned to the door, a hand from under the bed, red writing on a wall (with your
-- name in it), the kitchen chairs facing the door (put back before he hunts), knocking inside a closet, the
-- house phone that stops when you get close, and the attic rocking chair.
local H = require("./env")
local task = H.task
local T = 1000
H.clock = function() return T end
H.schedule = true
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
		local r = { FireClient = function(_, p, a, b) table.insert(fired, { k, p, a, b }) end, FireAllClients = function(_, a) table.insert(fired, { k, "all", a }) end, OnServerEvent = H.signal() }
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
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	return ctx, fired
end
local function mkPlayer(name, id)
	local p = H.wrap(H.roblox.Instance.new("Player"))
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
local ok, err = pcall(function()
	H.services.RunService.IsStudio = function() return false end
	local ctx, fired = setup()
	H.realModels = true -- (pivots move the parts: the bears and chairs really turn)
	local R = H.roblox
	local V = R.Vector3.new
	local a, b = mkPlayer("Ava", 1), mkPlayer("Ben", 2)
	H.services.Players.GetPlayers = function() return { a, b } end
	local function tick(sec) for _ = 1, math.floor(sec * 10 + 0.5) do H.services.RunService.Heartbeat:Fire(0.1); T += 0.1; H.runDue() end end
	local thoughts = {}
	local think = ctx.Director.think
	ctx.Director.think = function(players, line, ...)
		table.insert(thoughts, { players, line })
		return think(players, line, ...)
	end
	local function thought(p, line)
		for _, t in thoughts do
			local list = t[1]
			local hit = list == p or list == nil or (type(list) == "table" and table.find(list, p))
			if hit and t[2] == line then return true end
		end
		return false
	end
	local played = {}
	local playAt = ctx.Audio.playAt
	ctx.Audio.playAt = function(name, ...)
		played[name] = true
		return playAt(name, ...)
	end
	local function sound(name) return played[name] == true end
	local vel = {}
	H.velocityOf = function(part) return vel[H.unwrap(part)] end
	local function put(p, pos, look)
		local root = ctx.Util.getRoot(p)
		-- (a yaw, not CFrame.lookAt: lune's lookAt flips a view toward +Z)
		root.CFrame = look and (R.CFrame.new(pos) * R.CFrame.Angles(0, math.atan2(-(look.X - pos.X), -(look.Z - pos.Z)), 0)) or R.CFrame.new(pos)
		local head = p.Character:FindFirstChild("Head")
		head.CFrame = root.CFrame * R.CFrame.new(0, 1.5, 0)
	end
	local function away(p) put(p, V(0, 300, 400)) end
	ctx.Director.adminStart("Normal")
	ctx.Director.startAct("SmallThings")
	tick(1)
	local Events = H.load("Server/Director/Events")
	local E = {}
	for _, e in Events.List do E[e.Id] = e end
	local Story = ctx.Story
	local D = ctx.Director
	local root = H.unwrap(ctx.World.folder())
	local IDS = { "Follower", "StairBall", "ToysTurn", "UnderBed", "Scrawl", "KitchenChairs", "ClosetKnock", "HousePhone", "Rocker" }
	for _, id in IDS do
		assert(E[id], id .. " is in Events.List")
		assert(Story.Thoughts.Events[id], id .. " has a thought")
		assert(Story.Truths[id], id .. " has its truth")
	end
	assert(Story.Thoughts.Events.HousePhoneStop, "the phone's stop has its thought")
	print("events registered ok")

	-- 1) the static layer
	local junk = root:FindFirstChild("AtticJunk")
	assert(junk, "the attic is furnished")
	for _, n in { "Rocker", "DressForm" } do
		assert(junk:FindFirstChild(n), "attic: " .. n)
	end
	local nParts = 0
	for _, d in junk:GetDescendants() do if d:IsA("BasePart") then nParts += 1 end end
	assert(nParts > 60, "the attic is properly full: " .. nParts)
	local drawing = root:FindFirstChild("Kitchen"):FindFirstChild("Drawing", true)
	local crayon = drawing and drawing:FindFirstChild("Crayon")
	assert(crayon and #crayon:GetChildren() > 20, "the fridge drawing is drawn")
	local friend = root:FindFirstChild("Lily"):FindFirstChild("FriendDrawing", true)
	assert(friend and friend:FindFirstChild("Crayon"), "Lily's drawing")
	print("static layer ok")

	-- 2) a hand from under the bed: alone, a few studs from the bed, looking at it
	do
		local spot
		for _, s in ctx.Hiding.all() do if s.Name == "Under Jamie's bed" then spot = s end end
		assert(spot, "Jamie's bed is a hiding spot")
		local out = (spot.Exit.Position - spot.Inside.Position) * V(1, 0, 1)
		local stand = spot.Exit.Position + out.Unit * 5
		put(a, V(stand.X, 18, stand.Z), spot.Exit.Position)
		away(b)
		local data = E.UnderBed.Cond(ctx, D)
		assert(data and data.Player == a, "UnderBed: alone and looking at the bed")
		local seenHand = false
		task.spawn(E.UnderBed.Run, ctx, D, data)
		for _ = 1, 30 do
			tick(0.1)
			if root:FindFirstChild("Hand") then seenHand = true end
		end
		assert(seenHand, "the hand came out")
		assert(not root:FindFirstChild("Hand"), "and went back")
		assert(thought(a, Story.Thoughts.Events.UnderBed), "she thinks it")
		-- not with someone hiding under it
		ctx.Hiding.enter(b, spot)
		assert(E.UnderBed.Cond(ctx, D) == nil or E.UnderBed.Cond(ctx, D).Edge ~= data.Edge, "not the bed someone's under")
		ctx.Hiding.exit(b)
		print("under the bed ok")
	end

	-- 3) writing on the walls, in rooms nobody's in, with a name in it; found later
	do
		away(a); away(b)
		local names = {}
		for k = 1, 4 do
			local i = E.Scrawl.Cond(ctx, D)
			assert(i, "Scrawl: somewhere to write (" .. k .. ")")
			E.Scrawl.Run(ctx, D, i)
		end
		assert(E.Scrawl.Cond(ctx, D) == nil, "four a night at most")
		local parts = {}
		for _, d in root:GetDescendants() do
			if d.Name == "Scrawl" then
				table.insert(parts, d)
				local label = d:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel")
				assert(label and label.Text ~= "" and not label.Text:find("{NAME}"), "the words are written out")
				names[label.Text] = true
			end
		end
		assert(#parts == 4, "four on the walls: " .. #parts)
		local n = 0
		for _ in names do n += 1 end
		assert(n == 4, "all different")
		-- walk up to one: you see it
		local s = Events.Scrawls[1]
		local found = parts[1]
		for _, p in parts do
			for _, sp in Events.Scrawls do
				if (p.CFrame.Position - sp.At).Magnitude < 0.1 then s = sp; found = p end
			end
		end
		put(a, s.At + s.Into * 10 - V(0, 2, 0), s.At)
		tick(1.5)
		assert(thought(a, Story.Thoughts.Events.Scrawl), "she finds it")
		print("scrawl ok")
	end

	-- 4) Lily's bears turn to face her door, the rocking horse rocks; whoever walks in first
	do
		local door = ctx.Doors.get("Lily")
		-- (by her door, looking the other way)
		put(a, door.Position + V(-6, 0, 3), door.Position + V(-20, 0, 3))
		away(b)
		local data = E.ToysTurn.Cond(ctx, D)
		assert(data, "ToysTurn: someone near Lily's door, nobody in her room")
		task.spawn(E.ToysTurn.Run, ctx, D, data)
		tick(0.5)
		local bears = 0
		for _, d in root:FindFirstChild("Lily"):GetDescendants() do
			if d:IsA("Model") and d.Name == "Teddy" then
				local cf = H.wrap(d):GetBoundingBox()
				local to = (door.Position - cf.Position) * V(1, 0, 1)
				local look = cf.LookVector * V(1, 0, 1)
				assert(look.Unit:Dot(to.Unit) > 0.9, "a bear faces the door")
				bears += 1
			end
		end
		assert(bears >= 3, "her bears: " .. bears)
		put(a, V(24, 18, 20))
		tick(1)
		assert(thought(a, Story.Thoughts.Events.ToysTurn), "she walks in on them")
		tick(15)
		print("toys turn ok")
	end

	-- 5) the kitchen chairs face the doorway, and go back before he hunts
	do
		put(a, V(2, 4, 20))
		away(b)
		local chairs = E.KitchenChairs.Cond(ctx, D)
		assert(chairs and #chairs >= 4, "KitchenChairs: the dining chairs")
		local before = {}
		for _, m in chairs do before[m] = m:GetPivot() end
		task.spawn(E.KitchenChairs.Run, ctx, D, chairs)
		tick(0.5)
		for _, m in chairs do
			local cf = m:GetBoundingBox()
			local to = (V(-8, 0, 26) - cf.Position) * V(1, 0, 1)
			assert((cf.LookVector * V(1, 0, 1)).Unit:Dot(to.Unit) > 0.9, "a chair faces the doorway")
		end
		put(a, V(-24, 4, 12))
		tick(1)
		assert(thought(a, Story.Thoughts.Events.KitchenChairs), "she sees them")
		local hunting = false
		local real = ctx.Intruder.isHunting
		ctx.Intruder.isHunting = function() return hunting end
		hunting = true
		tick(1)
		for _, m in chairs do
			assert((m:GetPivot().Position - before[m].Position).Magnitude < 0.01, "back in place for the hunt")
		end
		ctx.Intruder.isHunting = real
		print("kitchen chairs ok")
	end

	-- 6) knocking inside a closet, alone beside it
	do
		local spot
		for _, s in ctx.Hiding.all() do if s.Name == "Coat closet" then spot = s end end
		assert(spot, "the coat closet")
		put(a, spot.Inside.Position + V(-6, 0, 0))
		away(b)
		local data = E.ClosetKnock.Cond(ctx, D)
		assert(data, "ClosetKnock")
		task.spawn(E.ClosetKnock.Run, ctx, D, data)
		tick(6.5)
		assert(thought(data.Player, Story.Thoughts.Events.ClosetKnock), "a knock from inside")
		print("closet knock ok")
	end

	-- 7) the house phone: rings, and stops the moment you get close
	do
		local phone = root:FindFirstChild("Kitchen"):FindFirstChild("Landline", true)
		local pos = phone:IsA("Model") and H.wrap(phone):GetPivot().Position or phone.CFrame.Position
		put(a, pos + V(25, 0, 0))
		away(b)
		local data = E.HousePhone.Cond(ctx, D)
		assert(data, "HousePhone: someone in earshot, nobody close")
		task.spawn(E.HousePhone.Run, ctx, D, data)
		tick(2)
		assert(sound("PhoneRing"), "it rings")
		put(a, pos + V(4, 0, 0))
		tick(1)
		assert(thought(a, Story.Thoughts.Events.HousePhoneStop), "it stops when she gets close")
		print("house phone ok")
	end

	-- 8) Lily's ball down the stairs to someone at the bottom
	do
		local st = ctx.Layout.Stairs.Main
		put(a, V(-5, 4, st.zStart - 8), V(-5, 4, st.zEnd))
		away(b)
		local data = E.StairBall.Cond(ctx, D)
		assert(data, "StairBall: at the bottom of the stairs, looking up them")
		task.spawn(E.StairBall.Run, ctx, D, data)
		tick(1.2)
		assert(root:FindFirstChild("LilyBall"), "a ball")
		tick(5)
		assert(thought(a, Story.Thoughts.Events.StairBall), "Lily's ball")
		print("stair ball ok")
	end

	-- 9) footsteps behind you that stop when you stop
	do
		put(a, V(2, 4, -20), V(2, 4, 0))
		away(b)
		local aRoot = H.unwrap(ctx.Util.getRoot(a))
		vel[aRoot] = V(0, 0, 8)
		assert(E.Follower.Cond(ctx, D) == a, "Follower: walking alone")
		local steps0 = 0
		for _, f in fired do if f[1] == "PlaySound" and f[3] == "Footstep" then steps0 += 1 end end
		task.spawn(E.Follower.Run, ctx, D, a)
		tick(3)
		vel[aRoot] = V(0, 0, 0)
		tick(4)
		local steps = 0
		for _, f in fired do if f[1] == "PlaySound" and f[3] == "Footstep" then steps += 1 end end
		assert(steps - steps0 >= 5, "steps behind her: " .. (steps - steps0))
		assert(thought(a, Story.Thoughts.Events.Follower), "and then she stops")
		print("follower ok")
	end

	-- 10) the attic rocking chair rocks when you climb up
	do
		put(a, V(4, 31, 11))
		local data = E.Rocker.Cond(ctx, D)
		assert(data, "Rocker: someone in the attic")
		local chair = data.Chair
		local base = chair:GetPivot()
		task.spawn(E.Rocker.Run, ctx, D, data)
		tick(0.6)
		local moved = (chair:GetPivot().LookVector - base.LookVector).Magnitude > 0.01
		assert(moved, "it's rocking")
		tick(17)
		assert((chair:GetPivot().Position - base.Position).Magnitude < 0.01, "and comes to rest where it was")
		assert(thought(a, Story.Thoughts.Events.Rocker), "she sees it")
		print("rocker ok")
	end
end)
if not ok then
	print("FAIL: " .. tostring(err))
	return
end
print("haunt_test OK")
