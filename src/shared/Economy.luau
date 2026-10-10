--[[
	Economy — the catalog for coins, shared by the server (EconomyService) and the lobby UI.

	Coins are earned at the end of every night (EconomyService.nightRewards), from the daily
	reward streak and from daily quests, and can be bought with Robux (Packs). They buy:
	  • Items: one-use gear you carry into your next night (Store tab "Items").
	  • Crates: a random cosmetic (flashlight colours, titles, lobby trails). A duplicate pays
	    back some coins instead.
	Nothing coins buy is needed to finish the game: they're shortcuts and looks.
]]

local Economy = {}

Economy.StartCoins = 100 -- a welcome present: enough for a first item straight away

-- one-use gear for the next night (given at the start of the night, then gone)
Economy.Items = {
	{ Id = "Flashlight", Name = "Pocket flashlight", Price = 60, Glyph = "🔦", Desc = "Start your next night with a flashlight." },
	{ Id = "PepperSpray", Name = "Pepper spray", Price = 90, Glyph = "🧴", Desc = "One can. Spray him and he staggers back, blind." },
	{ Id = "Multitool", Name = "Multitool", Price = 70, Glyph = "🔧", Desc = "Cut friends free in half the time." },
	{ Id = "Walkie", Name = "Walkie-talkie", Price = 40, Glyph = "📻", Desc = "Talk to your friends from anywhere in the house." },
	{ Id = "Energy", Name = "Energy drink", Price = 50, Glyph = "🥤", Desc = "Sprint for much longer, all night." },
	{ Id = "Lucky", Name = "Lucky charm", Price = 80, Glyph = "🍀", Desc = "Earn 50% more coins from your next night." },
	{ Id = "Revive", Name = "Revive token", Price = 250, Glyph = "💖", Desc = "Come back once after you're caught for good. Kept until you use it." },
}

Economy.Rarity = {
	Common = { Order = 1, Color = Color3.fromRGB(200, 200, 200), Refund = 20 },
	Rare = { Order = 2, Color = Color3.fromRGB(90, 160, 255), Refund = 50 },
	Epic = { Order = 3, Color = Color3.fromRGB(190, 100, 255), Refund = 120 },
	Legendary = { Order = 4, Color = Color3.fromRGB(255, 196, 60), Refund = 300 },
}

--[[
	Cosmetics. Kind "Beam": a flashlight colour (everyone sees it, in the house too).
	"Title": a line over your name in the lobby. "Trail": a glowing trail behind you in the lobby.
	Rainbow beams/trails cycle through the colours.
]]
Economy.Cosmetics = {
	-- flashlight colours
	{ Id = "Beam_Candle", Kind = "Beam", Name = "Candlelight", Rarity = "Common", Color = Color3.fromRGB(255, 196, 120) },
	{ Id = "Beam_Ice", Kind = "Beam", Name = "Ice", Rarity = "Common", Color = Color3.fromRGB(190, 236, 255) },
	{ Id = "Beam_Sakura", Kind = "Beam", Name = "Sakura", Rarity = "Rare", Color = Color3.fromRGB(255, 170, 210) },
	{ Id = "Beam_Toxic", Kind = "Beam", Name = "Toxic", Rarity = "Rare", Color = Color3.fromRGB(160, 255, 70) },
	{ Id = "Beam_Violet", Kind = "Beam", Name = "Violet", Rarity = "Epic", Color = Color3.fromRGB(170, 110, 255) },
	{ Id = "Beam_Sunset", Kind = "Beam", Name = "Sunset", Rarity = "Epic", Color = Color3.fromRGB(255, 110, 90) },
	{ Id = "Beam_Rainbow", Kind = "Beam", Name = "Rainbow", Rarity = "Legendary", Color = Color3.fromRGB(255, 80, 200), Rainbow = true },
	-- titles
	{ Id = "Title_Scaredy", Kind = "Title", Name = "Scaredy Cat", Rarity = "Common", Color = Color3.fromRGB(230, 230, 230) },
	{ Id = "Title_Pizza", Kind = "Title", Name = "Pizza Lover", Rarity = "Common", Color = Color3.fromRGB(255, 170, 90) },
	{ Id = "Title_NightOwl", Kind = "Title", Name = "Night Owl", Rarity = "Common", Color = Color3.fromRGB(180, 190, 255) },
	{ Id = "Title_Quiet", Kind = "Title", Name = "The Quiet One", Rarity = "Rare", Color = Color3.fromRGB(150, 230, 210) },
	{ Id = "Title_Survivor", Kind = "Title", Name = "Survivor", Rarity = "Rare", Color = Color3.fromRGB(120, 230, 150) },
	{ Id = "Title_Attic", Kind = "Title", Name = "Attic Explorer", Rarity = "Epic", Color = Color3.fromRGB(200, 120, 255) },
	{ Id = "Title_Phrogger", Kind = "Title", Name = "Phrogger", Rarity = "Epic", Color = Color3.fromRGB(110, 255, 120) },
	{ Id = "Title_Legend", Kind = "Title", Name = "Legend of Alder Lane", Rarity = "Legendary", Color = Color3.fromRGB(255, 205, 80) },
	-- lobby trails
	{ Id = "Trail_Dust", Kind = "Trail", Name = "Dust", Rarity = "Common", Color = Color3.fromRGB(210, 200, 180) },
	{ Id = "Trail_Moon", Kind = "Trail", Name = "Moonbeam", Rarity = "Rare", Color = Color3.fromRGB(140, 180, 255) },
	{ Id = "Trail_Ember", Kind = "Trail", Name = "Embers", Rarity = "Rare", Color = Color3.fromRGB(255, 120, 40) },
	{ Id = "Trail_Blood", Kind = "Trail", Name = "Blood Moon", Rarity = "Epic", Color = Color3.fromRGB(220, 30, 40) },
	{ Id = "Trail_Rainbow", Kind = "Trail", Name = "Rainbow", Rarity = "Legendary", Color = Color3.fromRGB(255, 80, 200), Rainbow = true },
}

-- the secret ending's own reward (not in any crate)
Economy.Special = {
	{ Id = "Title_Family", Kind = "Title", Name = "Not Your Family", Rarity = "Legendary", Color = Color3.fromRGB(255, 70, 70) },
}

Economy.Crates = {
	{ Id = "Basic", Name = "Attic Crate", Price = 150, Glyph = "📦", Odds = { Common = 62, Rare = 27, Epic = 9, Legendary = 2 }, Desc = "A random colour, title or trail." },
	{ Id = "Midnight", Name = "Midnight Crate", Price = 450, Glyph = "🎁", Odds = { Common = 0, Rare = 55, Epic = 33, Legendary = 12 }, Desc = "Rare or better, every time." },
}

-- Robux coin packs (developer products; Id 0 = not set up yet)
Economy.Packs = {
	{ Id = 3717625128, Coins = 250, Robux = 25 },
	{ Id = 3717625136, Coins = 650, Robux = 49, Tag = "+30%" },
	{ Id = 3717625143, Coins = 1500, Robux = 99, Tag = "+50%" },
	{ Id = 3717625149, Coins = 4000, Robux = 199, Tag = "BEST" },
}

-- the daily reward: come back on consecutive days (missing a day starts over at day 1)
Economy.Daily = { 25, 40, 60, 80, 100, 130, 200 }
Economy.DailyCrateDay = 7 -- day 7 also gives a free Attic Crate

--[[
	Daily quests: three a day from this pool (the same three for everyone on a given day).
	Stat = what counts (EconomyService.track), Goal = how many. Coins are paid when it's done.
]]
Economy.Quests = {
	{ Id = "Play2", Text = "Play 2 nights", Stat = "Nights", Goal = 2, Coins = 60 },
	{ Id = "Play3", Text = "Play 3 nights", Stat = "Nights", Goal = 3, Coins = 100 },
	{ Id = "Survive", Text = "Survive a night", Stat = "Survived", Goal = 1, Coins = 80 },
	{ Id = "Rescue", Text = "Cut a friend free", Stat = "Rescues", Goal = 1, Coins = 70 },
	{ Id = "Hide", Text = "Hide from him 5 times", Stat = "Hides", Goal = 5, Coins = 50 },
	{ Id = "Heartbeat", Text = "Keep your heartbeat steady while he listens, twice", Stat = "Heartbeats", Goal = 2, Coins = 70 },
	{ Id = "Puzzle", Text = "Splice the phone line or reset the breakers", Stat = "Puzzles", Goal = 1, Coins = 60 },
	{ Id = "Clues", Text = "Read 5 clues about him", Stat = "Clues", Goal = 5, Coins = 50 },
	{ Id = "Hard", Text = "Play a night on Hard", Stat = "HardNights", Goal = 1, Coins = 80 },
	{ Id = "Friends", Text = "Play a night with 2 or more players", Stat = "GroupNights", Goal = 1, Coins = 70 },
	{ Id = "NewEnding", Text = "Find an ending you haven't seen", Stat = "NewEndings", Goal = 1, Coins = 120 },
	{ Id = "Coins", Text = "Earn 200 coins", Stat = "Earned", Goal = 200, Coins = 60 },
}
Economy.QuestsPerDay = 3

-- what a night pays (EconomyService.nightRewards)
Economy.Night = {
	Played = 20, -- for playing (at least a few minutes)
	PerMinute = 1, -- for every minute you lasted (up to MinuteCap)
	MinuteCap = 25,
	Survived = 40, -- escaped, or still standing at a good ending
	Rescue = 15, -- each friend you cut free
	NewEnding = 50, -- an ending you hadn't seen before
	Secret = 150, -- the secret ending (everyone tied up at once... and out)
	HardMultiplier = 1.5,
	LuckyMultiplier = 1.5,
	MinSeconds = 120, -- shorter than this (left early): only the minutes
}

local byId: { [string]: any } = {}
for _, list in { Economy.Items, Economy.Cosmetics, Economy.Special, Economy.Crates, Economy.Quests } do
	for _, e in list do
		byId[e.Id] = e
	end
end

function Economy.get(id: string): any
	return byId[id]
end

function Economy.item(id: string): any
	for _, e in Economy.Items do
		if e.Id == id then
			return e
		end
	end
	return nil
end

function Economy.cosmetic(id: string): any
	for _, list in { Economy.Cosmetics, Economy.Special } do
		for _, e in list do
			if e.Id == id then
				return e
			end
		end
	end
	return nil
end

function Economy.crate(id: string): any
	for _, e in Economy.Crates do
		if e.Id == id then
			return e
		end
	end
	return nil
end

function Economy.pack(productId: number): any
	for _, e in Economy.Packs do
		if e.Id == productId and productId ~= 0 then
			return e
		end
	end
	return nil
end

-- the UTC day number (the daily reward and the quests roll over at midnight UTC)
function Economy.day(t: number?): number
	return math.floor((t or os.time()) / 86400)
end

-- today's quests: the same three for everyone, picked from the pool by the day number
function Economy.questsFor(day: number): { any }
	local pool = table.clone(Economy.Quests)
	local rng = Random.new(day * 7919 + 17)
	local out = {}
	while #out < Economy.QuestsPerDay and #pool > 0 do
		local i = rng:NextInteger(1, #pool)
		local q = table.remove(pool, i)
		-- (never two quests that count the same thing)
		local dup = false
		for _, o in out do
			if o.Stat == q.Stat then
				dup = true
			end
		end
		if not dup then
			table.insert(out, q)
		end
	end
	return out
end

-- rainbow colours cycle with time
function Economy.rainbow(t: number): Color3
	return Color3.fromHSV((t * 0.12) % 1, 0.75, 1)
end

return Economy
