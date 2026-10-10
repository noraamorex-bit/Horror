-- economy_test: coins (EconomyService). A fake DataStore that another "server" can write to as
-- well, to check that coins and gear are added onto what's saved (never overwritten), that a
-- Robux pack receipt pays once, that crates, gear, the daily reward, quests and the night's pay
-- all do what they say.
local H = require("./env")
local R = H.roblox
local T = 5000
H.clock = function() return T end

local function copy(v)
	if type(v) ~= "table" then return v end
	local t = {}
	for k, x in v do t[k] = copy(x) end
	return t
end
local saved = {}
local fakeStore = {
	GetAsync = function(_, key) return copy(saved[key]) end,
	UpdateAsync = function(_, key, fn)
		local new = fn(copy(saved[key]))
		if new ~= nil then saved[key] = copy(new) end
		return copy(saved[key])
	end,
}
H.services.DataStoreService = { GetDataStore = function() return fakeStore end, GetOrderedDataStore = function() return nil end }

local ok, err = pcall(function()
	local fired = {}
	local ctx: any = {}
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { FireClient = function(_, p, a) table.insert(fired, { k, p, a }) end, FireAllClients = function() end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	local credits = 0
	local beam = nil
	ctx.Stats = { addReviveCredit = function() credits += 1 return true end, refresh = function() end, setBeam = function(_, id) beam = id end }
	local given = {}
	ctx.Inventory = { give = function(_, item, n) given[item] = (given[item] or 0) + (n or 1) end }
	local E = H.load("Server/Services/EconomyService")
	E.init(ctx)
	local Cat = E.Catalog
	local p = H.wrap(R.Instance.new("Player"))
	rawset(p, "UserId", 77)
	H.services.Players.GetPlayers = function() return { p } end
	H.services.Players.GetPlayerByUserId = function(_, id) return id == 77 and p or nil end
	E._load(p)
	-- a new player: the welcome coins
	assert(p:GetAttribute("Coins") == Cat.StartCoins, "welcome coins, got " .. tostring(p:GetAttribute("Coins")))
	E._save(77)
	assert(saved.u77 and saved.u77.Coins == Cat.StartCoins and saved.u77.Welcomed == true, "saved")
	-- a second load doesn't pay the welcome again
	E._load(p)
	assert(p:GetAttribute("Coins") == Cat.StartCoins, "no second welcome")
	print("welcome ok")

	-- buy gear
	assert(E.buy(p, "Walkie") == true, "buy a walkie")
	assert(E.coins(p) == Cat.StartCoins - 40 and E.itemCount(p, "Walkie") == 1, "paid and carried")
	assert(E.buy(p, "Revive") == false, "can't afford a revive")
	assert(E.buy(p, "Nope") == false, "unknown item")
	print("buy ok")

	-- another server adds 500 coins meanwhile; our pending change lands on top of it
	saved.u77.Coins += 500
	E.addCoins(p, 10, true)
	E._save(77)
	assert(saved.u77.Coins == Cat.StartCoins - 40 + 500 + 10, "added onto what's saved: " .. saved.u77.Coins)
	assert(E.coins(p) == saved.u77.Coins, "the view resyncs to the saved total")
	assert(saved.u77.Items.Walkie == 1, "gear saved")
	print("merge ok")

	-- a Robux pack: paid once per receipt
	local pack = Cat.Packs[1]
	local before = E.coins(p)
	local d1 = E.onReceipt({ ProductId = pack.Id, PlayerId = 77, PurchaseId = "rcpt-1" })
	local d2 = E.onReceipt({ ProductId = pack.Id, PlayerId = 77, PurchaseId = "rcpt-1" })
	assert(d1 == R.Enum.ProductPurchaseDecision.PurchaseGranted and d2 == R.Enum.ProductPurchaseDecision.PurchaseGranted, "granted")
	assert(E.coins(p) == before + pack.Coins and saved.u77.Coins == before + pack.Coins, "paid once: " .. E.coins(p))
	assert(E.onReceipt({ ProductId = 123, PlayerId = 77, PurchaseId = "x" }) == R.Enum.ProductPurchaseDecision.NotProcessedYet, "not ours")
	print("receipts ok")

	-- crates: something new, then (eventually) a duplicate that pays back
	E.addCoins(p, 20000)
	local res = E.openCrate(p, "Basic")
	assert(res and res.Id and Cat.cosmetic(res.Id) and E.owns(p, res.Id), "a cosmetic")
	local dup = nil
	for _ = 1, 400 do
		local r = E.openCrate(p, "Basic")
		if r.Dup then dup = r break end
	end
	assert(dup and dup.Refund == Cat.Rarity[dup.Rarity].Refund, "a duplicate refunds")
	local mid = E.openCrate(p, "Midnight")
	assert(mid.Rarity ~= "Common", "midnight crates are rare or better")
	-- the odds roughly hold
	local counts = { Common = 0, Rare = 0, Epic = 0, Legendary = 0 }
	local rng = H.Random.new(3)
	for _ = 1, 5000 do
		local c = E._roll(Cat.crate("Basic"), rng)
		counts[c.Rarity] += 1
	end
	assert(counts.Common > 2700 and counts.Legendary > 30 and counts.Legendary < 220, "odds: " .. counts.Common .. "/" .. counts.Rare .. "/" .. counts.Epic .. "/" .. counts.Legendary)
	print(("crates ok (5000 rolls: %d common, %d rare, %d epic, %d legendary)"):format(counts.Common, counts.Rare, counts.Epic, counts.Legendary))

	-- equip a title you own; not one you don't
	local title
	for _, c in Cat.Cosmetics do if c.Kind == "Title" and E.owns(p, c.Id) then title = c break end end
	if title then
		assert(E.equip(p, title.Id) and p:GetAttribute("TitleText") == title.Name, "title equipped")
	end
	assert(E.equip(p, "Title_Family") == false, "can't wear what you don't own")
	assert(E.grantCosmetic(p, "Title_Family") and E.equip(p, "Title_Family") and p:GetAttribute("TitleText") == "Not Your Family", "the secret title")
	assert(E.unequip(p, "Title") and p:GetAttribute("TitleText") == nil, "unequip")
	print("equip ok")

	-- the daily reward: once a day; the streak goes on tomorrow, resets after a gap
	local c0 = E.coins(p)
	assert(E.claimDaily(p) == Cat.Daily[1] and E.coins(p) == c0 + Cat.Daily[1], "day 1")
	assert(E.claimDaily(p) == nil, "not twice")
	local d = E._docs[77]
	d.Daily.Day -= 1 -- (pretend it was claimed yesterday)
	assert(E.claimDaily(p) == Cat.Daily[2], "day 2")
	d.Daily.Day -= 3
	assert(E.claimDaily(p) == Cat.Daily[1], "missed days: back to day 1")
	print("daily ok")

	-- quests: today's three count up and pay once
	local q = Cat.questsFor(Cat.day())
	assert(#q == Cat.QuestsPerDay, "three quests")
	local first = q[1]
	local c1 = E.coins(p)
	E.track(p, first.Stat, first.Goal)
	assert(E._docs[77].Quests.Done[first.Id], "quest done")
	local paid = E.coins(p) - c1
	assert(paid >= first.Coins, "quest paid " .. paid)
	E.track(p, first.Stat, first.Goal)
	assert(E.coins(p) - c1 == paid, "paid once")
	print("quests ok")

	-- the night: gear goes in (one of each), coins come out (once; the new-ending bonus after)
	E.buy(p, "Lucky")
	E.buy(p, "Flashlight")
	local list = E.applyLoadout(p)
	assert(given.Walkie == 1 and given.Flashlight == 1 and p:GetAttribute("Boost_Lucky") == true, "loadout given")
	assert(E.itemCount(p, "Walkie") == 0 and E.itemCount(p, "Lucky") == 0, "and used up")
	E.resetNight()
	local cBefore = E.coins(p)
	local r1 = E.nightRewards(p, { Seconds = 600, Survived = true })
	assert(r1.Total > 0 and E.coins(p) == cBefore + r1.Total, "night paid " .. r1.Total)
	local r2 = E.nightRewards(p, { Seconds = 600, Survived = true })
	assert(r2.Total == 0, "not twice")
	local r3 = E.nightRewards(p, { NewEnding = true })
	assert(r3.Total >= Cat.Night.NewEnding, "new ending bonus after")
	print(("night ok: +%d (%d lines, lucky), then +%d for a new ending"):format(r1.Total, #r1.Lines, r3.Total))
	E._save(77)
	assert(saved.u77.Coins == E.coins(p), "all saved")
end)
print(ok and "ECONOMY OK" or ("ECONOMY FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
