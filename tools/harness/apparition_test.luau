-- apparition_test (v132, the owner: "When a person enters the upstairs room to close the window make the light flicker
-- and let him show for a sec and then disappear suddenly with a loud sound effect too. These are the types of scares I
-- want you to add through the game."): walking into the guest room in the first act, with its window open, brings the
-- room scare (Remotes.Apparition: the client flickers the lights, shows him, snaps them off with a hit) with him
-- standing just inside the window; once a room a night; other rooms by chance later on, him in front of you.
--
-- (setup as haunt_test:) haunt_test (v131, the owner: "Make the map (house) much better... Add way more scares. Actually scary and
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
	local function put(p, pos, look)
		local root = ctx.Util.getRoot(p)
		-- (a yaw, not CFrame.lookAt: lune's lookAt flips a view toward +Z)
		root.CFrame = look and (R.CFrame.new(pos) * R.CFrame.Angles(0, math.atan2(-(look.X - pos.X), -(look.Z - pos.Z)), 0)) or R.CFrame.new(pos)
		p.Character:FindFirstChild("Head").CFrame = root.CFrame * R.CFrame.new(0, 1.5, 0)
	end
	local function away(p) put(p, V(0, 300, 400)) end
	local function apparitions(p)
		local out = {}
		for _, f in fired do
			if f[1] == "Apparition" and f[2] == p then table.insert(out, f) end
		end
		return out
	end
	local Story = ctx.Story
	ctx.Director.adminStart("Normal")
	assert(ctx.Director.getAct() == "Evening", "the first act")
	away(b)
	-- in the upstairs hall by the guest room door, a while into the night
	put(a, V(6, 18, -14), V(20, 18, -14))
	tick(30)
	assert(#apparitions(a) == 0, "nothing in the hall")
	-- 1) into the guest room to close its window: the lights go, and he's standing by the window
	put(a, V(15, 18, -15), V(26, 18, -27))
	tick(0.6)
	local got = apparitions(a)
	assert(#got == 1, "the room scare, walking in: " .. #got)
	local cf = got[1][3]
	assert(typeof(cf) == "CFrame", "where he stands")
	assert(got[1][4] == "Guest", "the guest room's lights")
	assert(math.abs(cf.Position.X - 26) < 0.5 and math.abs(cf.Position.Z + 27.4) < 0.5, "just inside the open window: " .. tostring(cf.Position))
	local toMe = (V(15, 0, -15) - cf.Position) * V(1, 0, 1)
	assert((cf.LookVector * V(1, 0, 1)).Unit:Dot(toMe.Unit) > 0.95, "facing whoever walked in")
	tick(2.5)
	assert(thought(a, Story.Thoughts.Events.ApparitionWindow), "the thought")
	-- once a room a night: out and back in, nothing
	put(a, V(6, 18, -14), V(20, 18, -14))
	tick(70)
	put(a, V(15, 18, -15), V(26, 18, -27))
	tick(1)
	assert(#apparitions(a) == 1, "the guest room's had its scare")
	print("window room ok")

	-- 2) later, another room, by chance (forced here): him in front of you, in the room
	ctx.Config.Director.Apparition.Chance = 1
	ctx.Director.startAct("SmallThings")
	put(a, V(-4, 18, 24), V(-30, 18, 24))
	tick(70)
	put(a, V(-11, 18, 24), V(-30, 18, 24))
	tick(0.6)
	got = apparitions(a)
	assert(#got == 2, "Jamie's room: " .. #got)
	local p2 = got[2][3].Position
	local r = ctx.Rooms.find(p2)
	assert(r and r.Name == "Jamie", "he stands in the room")
	local d = (p2 - V(-11, p2.Y, 24)).Magnitude
	assert(d >= 5 and d <= 13.5, "a few strides in front of you: " .. d)
	assert(p2.X < -11, "ahead, not behind")
	tick(2.5)
	assert(thought(a, Story.Thoughts.Events.Apparition), "the thought")
	-- not again so soon (Apparition.Cooldown), even in a room that hasn't had one
	put(a, V(-4, 18, -10), V(-30, 18, -10))
	tick(0.5)
	put(a, V(-11, 18, -10), V(-30, 18, -10))
	tick(0.6)
	assert(#apparitions(a) == 2, "the cooldown between room scares")
	print("other rooms ok")
end)
if not ok then
	print("FAIL: " .. tostring(err))
	return
end
print("apparition_test OK")
