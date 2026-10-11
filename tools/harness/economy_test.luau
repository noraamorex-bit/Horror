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
	assert(E.buy(p, "Revive") == false, "revives are Robux only (no coin revive)")
	assert(E.buy(p, "PepperSpray") == false, "can't afford it (60 left)")
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
	-- titles aren't in crates any more: each one is earned in the game
	for _ = 1, 2000 do
		local c = E._roll(Cat.crate(math.random() < 0.5 and "Basic" or "Midnight"), rng)
		assert(c and c.Kind ~= "Title", "a crate gave a title")
	end
	for _, c in Cat.Cosmetics do assert(c.Kind ~= "Title", "no titles in the crate pool") end
	for _, c in Cat.Special do
		assert(c.Kind ~= "Title" or c.How or c.Level, c.Id .. " says how to earn it")
	end
	local seenNames = {}
	for _, c in Cat.Special do
		assert(not seenNames[c.Name], "two titles called " .. c.Name)
		seenNames[c.Name] = true
	end
	local notes = 0
	for _, f in fired do if f[1] == "Notify" then notes += 1 end end
	assert(E.achieve(p, "Title_Attic") == true and E.owns(p, "Title_Attic"), "attic explorer earned")
	assert(E.achieve(p, "Title_Attic") == false, "only once")
	local notes2 = 0
	for _, f in fired do if f[1] == "Notify" and tostring(f[3]):find("Attic Explorer") then notes2 += 1 end end
	assert(notes2 == 1, "one note about it")
	-- someone who got a title out of a crate before keeps it, and can still wear it
	local old = H.wrap(R.Instance.new("Player"))
	rawset(old, "UserId", 66)
	saved.u66 = { Coins = 10, Welcomed = true, Owned = { Title_Phrogger = true, Title_Legend = true } }
	E._load(old)
	assert(E.owns(old, "Title_Phrogger") and E.owns(old, "Title_Legend"), "old crate titles kept")
	assert(E.equip(old, "Title_Legend") and old:GetAttribute("TitleText") == "Legend of Alder Lane", "and still worn")
	print("titles ok")

	-- equip a title you own; not one you don't
	local title
	for _, c in Cat.Special do if c.Kind == "Title" and E.owns(p, c.Id) then title = c break end end
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
	-- (today's quests already done: on some days one is "earn coins", and the night's pay would finish it)
	local function questsDone(doc)
		local done = {}
		for _, qq in Cat.questsFor(Cat.day()) do done[qq.Id] = true end
		doc.Quests = { Day = Cat.day(), P = {}, Done = done }
	end
	questsDone(E._docs[77])
	E.resetNight()
	local cBefore = E.coins(p)
	local r1 = E.nightRewards(p, { Seconds = 600, Survived = true })
	assert(r1.Total > 0 and E.coins(p) == cBefore + r1.Total, "night paid " .. r1.Total)
	local r2 = E.nightRewards(p, { Seconds = 600, Survived = true })
	assert(r2.Total == 0, "not twice")
	local r3 = E.nightRewards(p, { NewEnding = true })
	assert(r3.Total >= Cat.Night.NewEnding, "new ending bonus after")
	print(("night ok: +%d (%d lines, lucky), then +%d for a new ending"):format(r1.Total, #r1.Lines, r3.Total))
	-- the night streak: another night started soon after pays more; it's saved and merged
	assert(r1.Chain == 1 and r1.NextBonus == 25 and r1.ChainMinutes == 15, "first night in a row (next +25%)")
	local function streakLine(r)
		for _, l in r.Lines do if tostring(l.Text):find("Night streak") then return l end end
		return nil
	end
	assert(not streakLine(r1), "no streak bonus on the first")
	assert(p:GetAttribute("ChainNext") == 25 and p:GetAttribute("ChainUntil") ~= nil, "the lobby can show it")
	E.resetNight()
	local r4 = E.nightRewards(p, { Seconds = 600, Survived = true })
	local sl = streakLine(r4)
	assert(r4.Chain == 2 and sl and sl.Amount > 0 and r4.NextBonus == 50, "second night in a row: +25% (next +50%)")
	E.resetNight()
	local r5 = E.nightRewards(p, { Seconds = 600, Survived = true })
	assert(r5.Chain == 3 and r5.NextBonus == 50, "third: +50%, and it stays there")
	-- a short visit doesn't count (or break it)
	E.resetNight()
	local r6 = E.nightRewards(p, { Seconds = 30 })
	assert(r6.Chain == 3 and not streakLine(r6), "under the minimum: no streak change")
	-- a long break: it starts over
	local d77c = E._docs[77]
	d77c.Chain.At -= 3 * 3600
	E.resetNight()
	local r7 = E.nightRewards(p, { Seconds = 600, Survived = true })
	assert(r7.Chain == 1 and not streakLine(r7), "after a break the streak starts over")
	E._save(77)
	assert(saved.u77.Chain and saved.u77.Chain.N == 1 and saved.u77.Chain.At > 0, "the streak is saved")
	-- another server ended a night more recently: its streak wins the merge
	saved.u77.Chain = { At = os.time() + 5, N = 4 }
	E._save(77)
	assert(saved.u77.Chain.N == 4 and E._docs[77].Chain.N == 4, "merge keeps the latest streak")
	assert(E.owns(p, "Title_NightOwl"), "three nights in a row: Night Owl")
	print("streak ok")
	-- titles a night earns: survived, unseen, a Hard night uncaught
	local t = H.wrap(R.Instance.new("Player"))
	rawset(t, "UserId", 55)
	E._load(t)
	E.resetNight()
	t:SetAttribute("NightSpotted", 2)
	E.nightRewards(t, { Seconds = 600, Survived = false })
	assert(not E.owns(t, "Title_Survivor"), "not for a night you didn't survive")
	E.resetNight()
	E.nightRewards(t, { Seconds = 600, Survived = true })
	assert(E.owns(t, "Title_Survivor") and not E.owns(t, "Title_Quiet"), "survived, but he saw you")
	E.resetNight()
	t:SetAttribute("NightSpotted", 0)
	H.unwrap(H.workspaceRoot):SetAttribute("Difficulty", "Hard")
	t:SetAttribute("NightCaught", 1)
	E.nightRewards(t, { Seconds = 600, Survived = true })
	assert(E.owns(t, "Title_Quiet") and not E.owns(t, "Title_Legend"), "unseen: the Quiet One; caught on Hard: no legend")
	E.resetNight()
	t:SetAttribute("NightCaught", 0)
	E.nightRewards(t, { Seconds = 600, Survived = true })
	assert(E.owns(t, "Title_Legend"), "a Hard night, never caught: Legend of Alder Lane")
	H.unwrap(H.workspaceRoot):SetAttribute("Difficulty", nil)
	print("night titles ok")
	-- today's daily reward comes with a night (not day 7: that crate opens in the lobby)
	local z = H.wrap(R.Instance.new("Player"))
	rawset(z, "UserId", 99)
	E._load(z)
	questsDone(E._docs[99])
	E.resetNight()
	local cz = E.coins(z)
	local rz = E.nightRewards(z, { Seconds = 600, Survived = true })
	local dl = nil
	for _, l in rz.Lines do if tostring(l.Text):find("Daily reward, day 1") then dl = l end end
	assert(dl and dl.Amount == Cat.Daily[1], "day 1 claimed with the night")
	assert(E.coins(z) == cz + rz.Total, "and paid once, in the total")
	assert(E._docs[99].Daily.Day == Cat.day() and E._docs[99].Daily.Streak == 1, "the streak has begun")
	E.resetNight()
	local rz2 = E.nightRewards(z, { Seconds = 600 })
	for _, l in rz2.Lines do assert(not tostring(l.Text):find("Daily"), "not twice in a day") end
	-- day 7 waits for the lobby
	E._docs[99].Daily = { Day = Cat.day() - 1, Streak = Cat.DailyCrateDay - 1 }
	E.resetNight()
	local rz3 = E.nightRewards(z, { Seconds = 600 })
	for _, l in rz3.Lines do assert(not tostring(l.Text):find("Daily"), "the crate day is claimed in the lobby") end
	-- a short visit doesn't claim it
	E._docs[99].Daily = { Day = Cat.day() - 1, Streak = 2 }
	E.resetNight()
	local rz4 = E.nightRewards(z, { Seconds = 30 })
	for _, l in rz4.Lines do assert(not tostring(l.Text):find("Daily"), "not for a short visit") end
	print("daily with the night ok")
	-- levels: XP is coins earned by playing. A player counted for the first time gets the titles of
	-- the levels they already have (no coins); after that each new level pays once.
	local d77 = E._docs[77]
	assert(p:GetAttribute("Level") ~= nil and p:GetAttribute("XPNext") ~= nil, "level mirrored")
	local lv = Cat.levelOf(d77.Earned)
	assert(d77.LevelPaid == lv, "counted on load: level " .. lv .. ", paid " .. tostring(d77.LevelPaid))
	-- a returning veteran (never counted, level 12 already): titles only
	local q = H.wrap(R.Instance.new("Player"))
	rawset(q, "UserId", 88)
	saved.u88 = { Coins = 5, Earned = Cat.xpFor(12) + 10, Welcomed = true }
	E._load(q)
	local d88 = E._docs[88]
	assert(d88.LevelPaid == 12 and E.coins(q) == 5, "veteran: level 12 counted, no back pay (" .. E.coins(q) .. ")")
	assert(E.owns(q, "Title_Lv5") and E.owns(q, "Title_Lv10") and not E.owns(q, "Title_Lv20"), "veteran: the level 5 and 10 titles")
	-- then a night that crosses two levels: coins for each, the crate level opens a crate
	questsDone(d88)
	local c0 = E.coins(q)
	local before = Cat.levelOf(d88.Earned)
	local need = Cat.xpFor(14) - d88.Earned + 1
	E.addCoins(q, need, true, "Gameplay", "Night")
	assert(Cat.levelOf(d88.Earned) == 14 and d88.LevelPaid == 14, "now level 14")
	local paid = E.coins(q) - c0 - need
	assert(paid == 13 * Cat.LevelCoins + 14 * Cat.LevelCoins, "paid levels 13 and 14: " .. paid)
	-- level-up coins aren't XP (no runaway)
	assert(Cat.levelOf(d88.Earned) == 14, "level-up coins don't count as XP")
	E._save(88)
	assert(saved.u88.LevelPaid == 14, "saved")
	-- another server paid up to 15 meanwhile: the higher wins
	saved.u88.LevelPaid = 15
	E._save(88)
	assert(saved.u88.LevelPaid == 15, "merge keeps the highest paid level")
	print(("levels ok: level %d -> %d, %d coins for levelling"):format(before, 14, paid))
	E._save(77)
	assert(saved.u77.Coins == E.coins(p), "all saved")
end)
print(ok and "ECONOMY OK" or ("ECONOMY FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
