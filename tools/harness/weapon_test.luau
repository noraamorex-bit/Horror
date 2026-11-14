-- weapon_test (v161): the Weapon Roll. The odds match what the window shows, the guarantees hold, a roll bought in a live
-- night spins and lands in your items, one bought elsewhere waits for the next night, each weapon stuns / shoves / slows him,
-- cooldowns and the stun immunity keep anyone from stun-locking him, guns save their shots before the hunt, the cannon
-- charges, the glove slaps players (never the owner, never someone hiding), a Legendary comes back for its nights, a
-- duplicate pays coins, and every weapon is a hotbar tool with its emoji and tier.
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
local fired = {} -- remote name -> list of { target, args... }
ctx.Remotes = setmetatable({}, { __index = function(t, k)
	fired[k] = fired[k] or {}
	local r = {
		FireClient = function(_, p, ...) table.insert(fired[k], { p, ... }) end,
		FireAllClients = function(_, ...) table.insert(fired[k], { "all", ... }) end,
		OnServerEvent = H.signal(),
	}
	rawset(t, k, r)
	return r
end })
local coins = {}
ctx.Economy = setmetatable({ addCoins = function(p, n) coins[p] = (coins[p] or 0) + n; return true end }, { __index = function() return function() end end })
local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Tools=ToolService", "Weapons=WeaponService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService", "Stats=StatsService" }
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
	rawset(p, "DisplayName", name)
	local char = H.Instance.new("Model")
	local root = H.Instance.new("Part", char); root.Name = "HumanoidRootPart"
	local head = H.Instance.new("Part", char); head.Name = "Head"
	local hum = H.Instance.new("Humanoid", char); hum.Health = 100
	H.Instance.new("Backpack", p)
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	p:SetAttribute("InGame", true)
	root.CFrame = R.CFrame.new(at)
	head.CFrame = R.CFrame.new(at + V(0, 1.5, 0))
	table.insert(players, p)
	return p, root, head
end
H.services.Players.GetPlayers = function()
	local out = {}
	for _, q in players do if rawget(q, "Parent") then table.insert(out, q) end end
	return out
end
H.services.Players.GetPlayerByUserId = function(_, id)
	for _, q in players do if q.UserId == id then return q end end
	return nil
end

local W = ctx.Config.Weapons
-- (the harness has no geometry to cast against: a flat floor under him, no walls)
local function floorCast(o, d)
	if d.Y < -1 and math.abs(d.X) < 1e-3 and math.abs(d.Z) < 1e-3 and o.Y > 0 and o.Y + d.Y < 0 then
		return { Position = V(o.X, 0, o.Z), Normal = V(0, 1, 0), Distance = o.Y }
	end
	return nil
end
local ok, err = pcall(function()
	H.raycast = floorCast
	-- (pivots are stubs in here: moving his model moves his root)
	H.onPivotTo = function(self, cf)
		local st = ctx.Intruder._state and ctx.Intruder._state()
		if st and self == st.Model and st.Root then st.Root.CFrame = cf end
	end
	local a, ra, ha = mkPlayer("Ana", 21, V(-20, 4, -10))
	local b, rb, hb = mkPlayer("Bo", 22, V(-24, 4, -12))
	local owner, ro = mkPlayer("Owner", ctx.Config.Admins[1], V(-26, 4, -12))
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	local Wp = ctx.Weapons

	-- 1. the odds add up to 100 and the rolls follow them (guarantees off for this)
	local total = 0
	for _, k in W.Order do total += W.List[k].Odds end
	assert(math.abs(total - 100) < 1e-6, "the odds add up to 100: " .. total)
	local savedPity = W.Pity
	W.Pity = { EpicBy = 1e9, LegendaryBy = 1e9 }
	local N = 20000
	local seen = {}
	for _ = 1, N do
		local k = Wp.roll(a)
		seen[k] = (seen[k] or 0) + 1
	end
	for _, k in W.Order do
		local got = (seen[k] or 0) / N * 100
		local want = W.List[k].Odds
		assert(math.abs(got - want) < math.max(0.6, want * 0.15), k .. ": rolled " .. got .. "%, the window says " .. want .. "%")
	end
	print("odds ok", seen.Bat, seen.Gun, seen.SlapGlove, seen.PlasmaCannon)
	W.Pity = savedPity

	-- 2. the guarantees: never more than EpicBy rolls without Epic+, LegendaryBy without a Legendary
	ctx.Stats.setWeaponPity(a, 0, 0)
	local sinceE, sinceL, maxE, maxL = 0, 0, 0, 0
	for _ = 1, 3000 do
		local rank = Wp._tierRank(W.List[Wp.roll(a)].Tier)
		sinceE += 1
		sinceL += 1
		if rank >= 3 then maxE = math.max(maxE, sinceE); sinceE = 0 end
		if rank >= 4 then maxL = math.max(maxL, sinceL); sinceL = 0 end
	end
	assert(maxE <= W.Pity.EpicBy and maxL <= W.Pity.LegendaryBy, "guarantees: epic gap " .. maxE .. ", legendary gap " .. maxL)
	ctx.Stats.setWeaponPity(a, W.Pity.LegendaryBy - 1, W.Pity.LegendaryBy - 1)
	local forced = Wp.roll(a)
	assert(W.List[forced].Tier == "Legendary", "the guaranteed roll is a Legendary: " .. forced)
	local pity = ctx.Stats.weaponPity(a)
	assert(pity.E == 0 and pity.L == 0, "and both counters start over")
	assert(a:GetAttribute("RollsSinceEpic") == 0 and a:GetAttribute("RollsSinceLegendary") == 0, "mirrored for the window")
	print("guarantees ok", maxE, maxL)

	-- 3. bought in the lobby / between nights: saved, then rolled when the night starts
	local info = { PlayerId = a.UserId, ProductId = ctx.Config.Shop.WeaponRoll.Id, PurchaseId = "x1", CurrencySpent = 10 }
	local dec = Wp.receipt(info)
	assert(dec == R.Enum.ProductPurchaseDecision.PurchaseGranted, "saved for later counts as granted")
	assert(#(fired.WeaponRoll or {}) == 0, "no spin outside a night")

	ctx.Director.adminStart("Normal")
	ctx.Director.startAct("SomeoneElse")
	H.flush(1)
	Wp.nightStart(a)
	H.flush(8.5)
	assert(#fired.WeaponRoll == 1 and fired.WeaponRoll[1][1] == a, "the saved roll spins when the night starts")
	local savedKind = fired.WeaponRoll[1][2]
	H.flush(W.SpinTime + 0.5)
	assert(ctx.Inventory.has(a, savedKind), "and lands in their items: " .. savedKind)
	print("saved roll ok", savedKind)

	-- 4. bought in a live night: the spin, then the weapon
	local before = #fired.WeaponRoll
	dec = Wp.receipt({ PlayerId = b.UserId, ProductId = ctx.Config.Shop.WeaponRoll.Id, PurchaseId = "x2", CurrencySpent = 10 })
	assert(dec == R.Enum.ProductPurchaseDecision.PurchaseGranted and #fired.WeaponRoll == before + 1, "live: rolled now")
	local rolled = fired.WeaponRoll[#fired.WeaponRoll][2]
	assert(not ctx.Inventory.has(b, rolled) or W.List[rolled].Ammo, "not in hand before the spin stops")
	H.flush(W.SpinTime + 0.3)
	assert(ctx.Inventory.has(b, rolled), "in hand when it stops")
	print("live roll ok", rolled)

	-- 5. weapons are hotbar tools with their emoji and tier, and every model builds
	for _, k in W.Order do
		assert(ctx.Tools.isTool(k), k .. " is a tool")
		local tool = ctx.Tools._build(k)
		assert(tool:GetAttribute("Emoji") == W.List[k].Emoji and tool:GetAttribute("Tier") == W.List[k].Tier, k .. " carries its emoji and tier")
		assert(tool:FindFirstChild("Handle"), k .. " has a handle")
	end
	ctx.Inventory.give(a, "Bat", 1)
	local batTool = ctx.Tools.find(a, "Bat")
	assert(batTool and batTool.Name == "Bat" and batTool:GetAttribute("Count") == nil, "a melee weapon shows no count")
	print("tools ok")

	-- 6. before the hunt: guns save their shots
	for _, q in { a, b } do ctx.Inventory.clear(q) end
	ctx.Inventory.give(a, "Gun", W.List.Gun.Ammo)
	assert(Wp.use(a, "Gun", V(0, 0, -1)) == "saved" and ctx.Inventory.count(a, "Gun") == W.List.Gun.Ammo, "no shot wasted before the hunt")

	-- the hunt: put Ana right in front of him
	ctx.Intruder.setMode("Hunt")
	H.flush(3)
	local S = ctx.Intruder._state()
	assert(S.InHouse, "he's in the house")
	local function faceHim(dist)
		local p = S.Root.Position
		local at = p + V(dist, 0, 0)
		ra.CFrame = R.CFrame.lookAt(at, V(p.X, at.Y, p.Z))
		ha.CFrame = R.CFrame.new(at + V(0, 1.5, 0))
		return (V(p.X, at.Y, p.Z) - at).Unit
	end
	local function calm()
		S.WeaponImmuneUntil = 0
		if S.State == "Stunned" then H.flush(10) end
		ctx.Intruder.setMode("Hunt")
		H.flush(0.3)
	end

	-- 7. the bat: a shove, a short stun, the cooldown; then he's back at it (no retreat)
	ctx.Inventory.give(a, "Bat", 1)
	local aim = faceHim(4)
	local p0 = S.Root.Position
	local res = Wp.use(a, "Bat", aim)
	assert(res == "stun" and S.State == "Stunned" and S.Data.Weapon == W.List.Bat, "the bat stuns him: " .. tostring(res) .. " " .. S.State)
	local moved = (S.Root.Position - p0)
	print("bat shove", moved.Magnitude, moved.Magnitude > 0 and moved.Unit:Dot(aim) or 0, S.Root.Position)
	assert(moved.Magnitude > 0.5 and moved.Unit:Dot(aim) > 0.5, "and shoves him away from you")
	assert(Wp.use(a, "Bat", aim) == "cooldown", "then it's cooling down")
	assert(ctx.Tools.find(a, "Bat"):GetAttribute("ReadyAt"), "the hotbar shows the cooldown")
	H.flush(W.List.Bat.Stun + 0.3)
	assert(S.State ~= "Stunned" and S.State ~= "Retreat", "up again and straight back at it: " .. S.State)
	-- 8. right after: weapons only stagger him (nobody stun-locks him)
	ctx.Inventory.give(b, "Dagger", 1)
	local bAim
	do
		local p = S.Root.Position
		local at = p + V(-3, 0, 0)
		rb.CFrame = R.CFrame.lookAt(at, V(p.X, at.Y, p.Z))
		hb.CFrame = R.CFrame.new(at + V(0, 1.5, 0))
		bAim = (V(p.X, at.Y, p.Z) - at).Unit
	end
	assert(Wp.use(b, "Dagger", bAim) == "stagger" and S.State ~= "Stunned", "within StunImmune of a weapon stun: only a stagger")
	H.flush(W.StunImmune + 0.5)
	calm()
	print("bat + immunity ok")

	-- 9. a miss: a short wait only
	ctx.Inventory.give(a, "Axe", 1)
	faceHim(4)
	local away = V(0, 0, 1)
	do
		local p = S.Root.Position
		local at = p + V(30, 0, 0)
		ra.CFrame = R.CFrame.new(at)
		ha.CFrame = R.CFrame.new(at + V(0, 1.5, 0))
	end
	assert(Wp.use(a, "Axe", away) == "miss", "out of reach: a miss")
	assert(Wp.use(a, "Axe", away) == "cooldown", "a short wait")
	H.flush(1.3)
	assert(Wp.use(a, "Axe", away) == "miss", "then you can swing again")
	H.flush(1.3)

	-- 10. the gun: shots from across the room, ammo, a slow afterwards
	calm()
	ctx.Inventory.give(a, "Gun", 0)
	aim = faceHim(20)
	local ammo = ctx.Inventory.count(a, "Gun")
	res = Wp.use(a, "Gun", aim)
	assert(res == "stun" and ctx.Inventory.count(a, "Gun") == ammo - 1, "a shot hits from 20 studs and uses a shot: " .. tostring(res))
	assert(#fired.WeaponFx > 0, "everyone sees it")
	local normal = ctx.Intruder._tune().ChaseSpeed
	H.flush(W.List.Gun.Stun + 0.3)
	assert(ctx.Intruder._tune().ChaseSpeed < normal * 0.8, "then he's slowed")
	H.flush(W.List.Gun.Slow + W.StunImmune)
	calm()
	print("gun ok")

	-- 11. the plasma cannon: it charges, then the beam drops him for long, then he backs off
	ctx.Inventory.give(a, "PlasmaCannon", W.List.PlasmaCannon.Ammo)
	aim = faceHim(25)
	assert(Wp.use(a, "PlasmaCannon", aim) == "charging", "it winds up first")
	assert(ctx.Inventory.count(a, "PlasmaCannon") == W.List.PlasmaCannon.Ammo, "no shot spent while charging")
	faceHim(25)
	H.flush(W.List.PlasmaCannon.Charge + 0.1)
	assert(S.State == "Stunned" and S.Data.Weapon == W.List.PlasmaCannon, "the beam drops him: " .. S.State)
	assert(ctx.Inventory.count(a, "PlasmaCannon") == W.List.PlasmaCannon.Ammo - 1, "one shot used")
	H.flush(W.List.PlasmaCannon.Stun - 1)
	assert(S.State == "Stunned", "down for a long time")
	H.flush(1.5)
	assert(S.State == "Retreat", "then he backs off: " .. S.State)
	H.flush(30)
	calm()
	print("cannon ok")

	-- 12. the slap glove: him across the room; players too (never the owner, never someone hiding)
	ctx.Inventory.give(a, "SlapGlove", 1)
	aim = faceHim(3)
	p0 = S.Root.Position
	res = Wp.use(a, "SlapGlove", aim)
	assert(res == "stun", "the glove slaps him: " .. tostring(res))
	print("slap moved him", (S.Root.Position - p0).Magnitude)
	H.flush(W.List.SlapGlove.Cooldown + W.List.SlapGlove.Stun + 1)
	calm()
	-- far from him, a friend in front (a fresh one: Bo may have been caught by now)
	b, rb, hb = mkPlayer("Cy", 23, ctx.Phone.signalSpot() + V(3, 0, 0))
	do
		local p = S.Root.Position + V(0, 0, 0)
		local spot = ctx.Phone.signalSpot()
		ra.CFrame = R.CFrame.lookAt(spot, spot + V(1, 0, 0))
		ha.CFrame = R.CFrame.new(spot + V(0, 1.5, 0))
		rb.CFrame = R.CFrame.new(spot + V(3, 0, 0))
		ro.CFrame = R.CFrame.new(spot + V(2, 0, 0.5))
		local _ = p
	end
	local trolls = #(fired.Troll or {})
	S.WeaponImmuneUntil = 0
	res = Wp.use(a, "SlapGlove", V(1, 0, 0))
	if res ~= "slapped" then print("(glove: " .. tostring(res) .. ")", b:GetAttribute("Captured"), b:GetAttribute("Hiding"), b:GetAttribute("Dead"), b:GetAttribute("InGame"), rb.Position, ra.Position) end
	local last = fired.Troll and fired.Troll[#fired.Troll]
	assert(res == "slapped" and #fired.Troll == trolls + 1 and last[1] == b and last[2] == "slap", "the glove slaps the friend, not the owner")
	assert(Wp.use(a, "SlapGlove", V(1, 0, 0)) == "cooldown", "slaps are spaced out")
	H.flush(W.List.SlapGlove.PlayerCooldown + 0.2)
	b:SetAttribute("Hiding", true)
	rb.CFrame = R.CFrame.new(ctx.Phone.signalSpot() + V(30, 0, 0))
	trolls = #fired.Troll
	Wp.use(a, "SlapGlove", V(1, 0, 0))
	assert(#fired.Troll == trolls, "nobody slapped: the owner's off limits, the friend's hiding")
	b:SetAttribute("Hiding", nil)
	print("glove ok")

	-- 13. a Legendary comes back for its nights; a duplicate melee weapon pays coins
	ctx.Stats.setLegend(a, "SlapGlove", W.LegendaryNights - 1)
	for i = 1, W.LegendaryNights - 1 do
		assert(ctx.Stats.takeLegendNight(a) == "SlapGlove", "night " .. i .. ": the glove's back")
	end
	assert(ctx.Stats.takeLegendNight(a) == nil, "then it's gone")
	ctx.Inventory.give(a, "Katana", 1)
	local c0 = coins[a] or 0
	-- (grant goes through rollNow's landing: force the roll)
	local realRoll = Wp.roll
	Wp.roll = function() return "Katana" end
	Wp.rollNow(a, "test")
	H.flush(W.SpinTime + 0.2)
	Wp.roll = realRoll
	assert((coins[a] or 0) == c0 + W.DuplicateCoins and ctx.Inventory.count(a, "Katana") == 1, "a duplicate pays coins")
	print("legendary nights + duplicates ok")

	-- 14. where paid random items aren't allowed, nothing is offered
	a:SetAttribute("RollRestricted", true)
	assert(Wp.restricted(a), "restricted players are flagged")
	a:SetAttribute("RollRestricted", nil)
end)
local errs = {}
for _, e in H.errors do if not string.find(tostring(e), "TextChannels", 1, true) then table.insert(errs, tostring(e)) end end
print(ok and (#errs == 0 and "WEAPON OK" or "WEAPON FAIL: errors") or ("WEAPON FAIL: " .. tostring(err)))
for _, e in errs do print(e:sub(1, 1500)) end
