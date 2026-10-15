-- admin_test: the owner panel. Non-admins are ignored; admin commands do what they say.
-- (was: revive_test header) Solo: the night waits Config.Shop.Revive.Window seconds,
-- a revive puts you back on your feet away from him; no revive and the night ends.
-- Co-op: the dead player's card offers REVIVE while the others play on.
-- Run with arg "solo", "nobuy", "coop" or "credit".
local H = require("./env")
local Enum = H.roblox.Enum
local T = 1000
H.clock = function() return T end
H.schedule = true
function H.flush(sec) for _ = 1, math.ceil(sec / 0.1) do T += 0.1; H.runDue() end end
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
		local r = { FireClient = function(_, p, a) table.insert(fired, { k, p, a }) end, FireAllClients = function() end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService", "Revive=ReviveService", "Admin=AdminService" }
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
	local roblox = H.roblox
	local p = H.wrap(roblox.Instance.new("Player"))
	p.Name = name
	rawset(p, "UserId", id)
	local char = H.Instance.new("Model")
	local rootPart = H.Instance.new("Part", char)
	rootPart.Name = "HumanoidRootPart"
	local hum = H.Instance.new("Humanoid", char)
	hum.Health = 100
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	p:SetAttribute("InGame", true)
	return p
end
local function kinds(fired, kind)
	local out = {}
	for _, f in fired do if f[1] == kind then table.insert(out, f) end end
	return out
end
local function receipt(ctx, p, n)
	local MS = H.services.MarketplaceService
	return ctx.Revive.onReceipt({ PlayerId = p.UserId, ProductId = ctx.Config.Shop.Revive.Id, PurchaseId = "buy" .. n })
end
local ok, err = pcall(function()
	H.services.RunService.IsStudio = function() return false end
	local ctx, fired = setup()
	local owner, rando = mkPlayer("Owner", 915496194), mkPlayer("Rando", 12345)
	H.services.Players.GetPlayers = function() return { owner, rando } end
	assert(ctx.Admin.isAdmin(owner) and not ctx.Admin.isAdmin(rando), "only the owner is an admin")
	local function cmd(p, c, a) ctx.Remotes.Admin.OnServerEvent:Fire(p, c, a) end
	local function lastReply(p) local r = nil; for _, f in fired do if f[1] == "AdminReply" and f[2] == p then r = f[3] end end; return r end
	-- a stranger tries everything: nothing happens, no reply
	cmd(rando, "start", "Hard")
	assert(H.unwrap(H.workspaceRoot):GetAttribute("Act") ~= "Evening", "stranger can't start a night")
	cmd(rando, "ending", "Sirens")
	assert(not ctx.Ending.isOver(), "stranger can't end the night")
	assert(lastReply(rando) == nil, "strangers get no reply at all")
	-- the owner
	cmd(owner, "start", "Hard")
	local ws = H.unwrap(H.workspaceRoot)
	assert(ws:GetAttribute("Act") == "Evening" and ws:GetAttribute("Difficulty") == "Hard", "start: Hard")
	cmd(owner, "act", "SomeoneElse"); assert(ws:GetAttribute("Act") == "SomeoneElse", "jump to act")
	cmd(owner, "nextact"); assert(ws:GetAttribute("Act") == "Guest", "next act")
	cmd(owner, "me", "items"); assert(owner:GetAttribute("Item_Scissors") == 1 and owner:GetAttribute("Item_Flashlight") == 1, "items")
	-- can't be caught: every capture (and the second-capture death) does nothing; strangers can't switch it on
	cmd(rando, "me", "god"); assert(not rando:GetAttribute("AdminGod"), "stranger can't be made uncatchable")
	cmd(owner, "me", "god"); assert(owner:GetAttribute("AdminGod") == true, "god on")
	assert(ctx.Capture.capture(owner) == false and not owner:GetAttribute("Captured"), "can't be captured")
	assert(ctx.Capture.kill(owner) == false and not owner:GetAttribute("Dead"), "can't be killed")
	cmd(owner, "me", "god"); assert(not owner:GetAttribute("AdminGod"), "god off")
	print("can't be caught ok")
	cmd(owner, "me", "ghost"); assert(owner:GetAttribute("AdminGhost") == true, "ghost on")
	cmd(owner, "ai", "freeze"); assert(ctx.Intruder.adminIsFrozen(), "freeze")
	cmd(owner, "ai", "freeze"); assert(not ctx.Intruder.adminIsFrozen(), "unfreeze")
	cmd(owner, "tp", "Kitchen"); print("tp:", lastReply(owner))
	cmd(owner, "events"); print(lastReply(owner))
	cmd(owner, "event", "Flicker"); print("event:", lastReply(owner))
	cmd(owner, "help", "Phone"); assert(ctx.Escape.helpCalled(), "help called")
	cmd(owner, "police"); print("police:", lastReply(owner))
	cmd(owner, "bogus"); assert(lastReply(owner) == "Unknown command.")
	-- the yanked door: opening it right after gives a loud hit, once
	H.schedule = true
	local door = ctx.Doors.get("FrontDoor")
	door.YankedAt = H.clock()
	ctx.Director.onDoorOpened(door, owner)
	ctx.Director.onDoorOpened(door, owner)
	H.flush(1)
	local hits = 0
	for _, f in fired do if f[1] == "PlaySound" and f[2] == owner and f[3] == "HorrorHit" then hits += 1 end end
	assert(hits == 1, "yanked door: one loud hit, got " .. hits)
	print("door yank scare ok")
	-- coins: only for the owner
	local bank = {}
	ctx.Economy = {
		coins = function(p) return bank[p] or 0 end,
		addCoins = function(p, n) if (bank[p] or 0) + n < 0 then return false end bank[p] = (bank[p] or 0) + n return true end,
	}
	cmd(rando, "coins", "5000"); assert((bank[rando] or 0) == 0, "a stranger gets no coins")
	cmd(owner, "coins", "5000"); assert(bank[owner] == 5000, "owner +5000")
	cmd(owner, "coins", "-99999"); assert(bank[owner] == 0, "taking back never goes below 0")
	cmd(owner, "coins"); assert(bank[owner] == 1000, "default +1000: " .. tostring(lastReply(owner)))
	print("coins:", lastReply(owner))
	-- the SHOP tab: passes on/off (this server), the paid gear, saved credits; never for strangers
	cmd(rando, "pass", "Rocket"); assert(not rando:GetAttribute("Pass_Rocket"), "a stranger can't switch passes on")
	cmd(rando, "give", "Rocket"); assert(not rando:GetAttribute("Item_Rocket"), "nor get rockets")
	owner:SetAttribute("Item_Rocket", nil)
	ctx.Inventory.take(owner, "Rocket", 99)
	cmd(owner, "pass", "Rocket")
	assert(owner:GetAttribute("Pass_Rocket") == true and ctx.Inventory.count(owner, "Rocket") == ctx.Config.Rocket.Charges, "rocket pass on: its rockets now")
	cmd(owner, "pass", "Rocket"); assert(not owner:GetAttribute("Pass_Rocket"), "and off again")
	cmd(owner, "pass", "VIP"); assert(owner:GetAttribute("Pass_ChooseRole") and owner:GetAttribute("Pass_Battery"), "VIP switches its perks on")
	cmd(owner, "pass", "Nope"); assert(lastReply(owner) == "Unknown pass.")
	for _, item in { "Taser", "EnergyDrink", "Firecracker", "PepperSpray" } do
		local before = ctx.Inventory.count(owner, item)
		cmd(owner, "give", item)
		assert(ctx.Inventory.count(owner, item) > before, "give " .. item)
	end
	cmd(owner, "becomehim"); print("become him (alone):", lastReply(owner))
	assert(not owner:GetAttribute("Monster"), "not without a friend in the night")
	print("shop tab ok")
	-- roles: each starts with its own item, and is told so
	ctx.Economy.applyLoadout = function() return {} end
	owner:SetAttribute("Role", nil); rando:SetAttribute("Role", nil) -- (so every role is free)
	local Roles = ctx.Story.Roles
	for _, role in Roles do
		local p = mkPlayer("Role" .. role.Id, 5000 + #role.Id)
		p:SetAttribute("Pass_ChooseRole", true)
		p:SetAttribute("WantRole", role.Id)
		ctx.PlayerState.assignRoles({ p })
		assert(p:GetAttribute("Role") == role.Id, "picked " .. role.Id)
		for item, n in role.Items do
			assert(ctx.Inventory.count(p, item) >= n, role.Id .. " starts with " .. item)
		end
		assert(role.Gear and role.Start, role.Id .. " says what it starts with")
	end
	local said = false
	H.flush(4)
	for _, f in fired do if f[1] == "Notify" and type(f[3]) == "string" and f[3]:find("You start with") then said = true end end
	assert(said, "the night tells you who you are and what you start with")
	print("role items ok")
	-- Morgan's energy drink: sprint without tiring for a while
	local runner = mkPlayer("Runner", 7001)
	ctx.Inventory.give(runner, "EnergyDrink", 2)
	runner:SetAttribute("Stamina", 10)
	assert(ctx.PlayerState.drink(runner), "drank one")
	assert(runner:GetAttribute("Rush") == true and runner:GetAttribute("Stamina") == ctx.Config.Movement.StaminaMax, "rush: stamina full")
	assert(ctx.Inventory.count(runner, "EnergyDrink") == 1, "one used")
	-- Casey's firecracker: thrown, then the bang is a big noise where it landed
	local thrower = mkPlayer("Thrower", 7002)
	local head = H.Instance.new("Part", thrower.Character)
	head.Name = "Head"
	head.CFrame = H.roblox.CFrame.new(-20, 6, 0)
	ctx.Inventory.give(thrower, "Firecracker", 2)
	local bangs = {}
	ctx.Noise.listen(function(ev) if ev.Kind == "Firecracker" then table.insert(bangs, ev) end end)
	local land = ctx.PlayerState.throwFirecracker(thrower, H.roblox.Vector3.new(1, 0, 0))
	assert(land and ctx.Inventory.count(thrower, "Firecracker") == 1, "thrown")
	assert(#bangs == 0, "not yet: the fuse")
	H.flush(ctx.Config.Firecracker.Fuse + 0.2)
	assert(#bangs == 1 and bangs[1].Radius == ctx.Config.Firecracker.Noise and (bangs[1].Position - land).Magnitude < 0.1, "bang, where it landed")
	print("drink + firecracker ok")
	cmd(owner, "ending", "Sirens"); assert(ctx.Ending.isOver(), "ending")
	print("admin ok")
end)
print(ok and "ADMIN OK" or ("ADMIN FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
