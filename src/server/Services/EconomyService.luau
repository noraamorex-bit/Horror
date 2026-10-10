--[[
	EconomyService — coins, one-use gear, crates and cosmetics, the daily reward and daily quests
	(catalog: Shared/Economy). Runs in the lobby and in the house.

	Saved in its own DataStore ("Economy_v1", key "u<userId>"). Coins and gear counts are kept as
	pending deltas and added onto whatever is saved (UpdateAsync), so the lobby and a game server
	can never overwrite each other's coins while a player moves between them. Owned cosmetics are
	a union; the daily streak and quest progress keep the newest/furthest copy.

	Mirrored for the UI as player attributes: "Coins" (number) and "Eco" (JSON: gear, owned,
	equipped, daily, quests). Equipped cosmetics also become attributes the world reads:
	"TitleText"/"TitleColor" (lobby title tag), "TrailId" (lobby trail) and, for crate flashlight
	colours, StatsService's StatBeamColor.

	Robux coin packs (Economy.Packs) are granted in ShopService's ProcessReceipt through
	Economy.onReceipt: the purchase id is stored in the same saved document as the coins, so a
	repeated receipt is never paid twice.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Economy = {}
local ctx
local Cat -- Shared/Economy
local store = nil
local docs: { [number]: any } = {} -- userId -> merged view
local pending: { [number]: any } = {} -- userId -> { Coins, Items = {}, Earned, Crates }
local loaded: { [number]: boolean } = {}
local saveQueued: { [number]: boolean } = {}
local lastAction: { [Player]: number } = {}
local granted: { [Player]: boolean } = {} -- this night's coins already paid
Economy.MaxStack = 5

local function fresh()
	return {
		Coins = 0,
		Items = {},
		Owned = {},
		Equip = {},
		Daily = { Day = 0, Streak = 0 },
		Quests = { Day = 0, P = {}, Done = {} },
		Receipts = {},
		Earned = 0,
		Crates = 0,
		Welcomed = false,
	}
end

local function freshPending()
	return { Coins = 0, Items = {}, Earned = 0, Crates = 0 }
end

-- a saved document, cleaned up (anything odd in it is dropped)
local function clean(data): any
	local d = fresh()
	if type(data) ~= "table" then
		return d
	end
	d.Coins = math.max(0, math.floor(tonumber(data.Coins) or 0))
	for k, v in (type(data.Items) == "table" and data.Items or {}) do
		local n = math.floor(tonumber(v) or 0)
		if type(k) == "string" and n > 0 then
			d.Items[k] = n
		end
	end
	for k, v in (type(data.Owned) == "table" and data.Owned or {}) do
		if type(k) == "string" and v then
			d.Owned[k] = true
		end
	end
	for k, v in (type(data.Equip) == "table" and data.Equip or {}) do
		if type(k) == "string" and type(v) == "string" then
			d.Equip[k] = v
		end
	end
	if type(data.Daily) == "table" then
		d.Daily = { Day = math.floor(tonumber(data.Daily.Day) or 0), Streak = math.floor(tonumber(data.Daily.Streak) or 0) }
	end
	if type(data.Quests) == "table" then
		local q = { Day = math.floor(tonumber(data.Quests.Day) or 0), P = {}, Done = {} }
		for k, v in (type(data.Quests.P) == "table" and data.Quests.P or {}) do
			if type(k) == "string" then
				q.P[k] = math.max(0, math.floor(tonumber(v) or 0))
			end
		end
		for k, v in (type(data.Quests.Done) == "table" and data.Quests.Done or {}) do
			if type(k) == "string" and v then
				q.Done[k] = true
			end
		end
		d.Quests = q
	end
	if type(data.Receipts) == "table" then
		for _, r in data.Receipts do
			if type(r) == "string" then
				table.insert(d.Receipts, r)
			end
		end
	end
	d.Earned = math.max(0, math.floor(tonumber(data.Earned) or 0))
	d.Crates = math.max(0, math.floor(tonumber(data.Crates) or 0))
	d.Welcomed = data.Welcomed == true
	return d
end

---------------------------------------------------------------------------
-- What the UI sees
---------------------------------------------------------------------------
local function questView(d)
	local today = Cat.day()
	local out = {}
	for _, q in Cat.questsFor(today) do
		local p = d.Quests.Day == today and (d.Quests.P[q.Id] or 0) or 0
		local done = d.Quests.Day == today and d.Quests.Done[q.Id] == true
		table.insert(out, { Id = q.Id, Text = q.Text, Goal = q.Goal, Progress = math.min(p, q.Goal), Done = done, Coins = q.Coins })
	end
	return out
end

local function dailyView(d)
	local today = Cat.day()
	local canClaim = d.Daily.Day ~= today
	local nextStreak = 1
	if d.Daily.Day == today - 1 then
		nextStreak = (d.Daily.Streak % #Cat.Daily) + 1
	elseif d.Daily.Day == today then
		nextStreak = d.Daily.Streak
	end
	return { CanClaim = canClaim, Streak = d.Daily.Day >= today - 1 and d.Daily.Streak or 0, Next = nextStreak, SecondsLeft = (today + 1) * 86400 - os.time() }
end

local function mirror(player: Player)
	local d = docs[player.UserId]
	if not d then
		return
	end
	player:SetAttribute("Coins", d.Coins)
	local owned = {}
	for k in d.Owned do
		table.insert(owned, k)
	end
	table.sort(owned)
	local ok, json = pcall(HttpService.JSONEncode, HttpService, {
		Items = d.Items,
		Owned = owned,
		Equip = d.Equip,
		Daily = dailyView(d),
		Quests = questView(d),
		Crates = d.Crates,
	})
	if ok then
		player:SetAttribute("Eco", json)
	end
	-- what the world shows: your title and trail (lobby), and the crate flashlight colours
	local title = d.Equip.Title and Cat.cosmetic(d.Equip.Title)
	player:SetAttribute("TitleText", title and title.Name or nil)
	player:SetAttribute("TitleColor", title and title.Color or nil)
	player:SetAttribute("TrailId", d.Equip.Trail)
end

---------------------------------------------------------------------------
-- Saving
---------------------------------------------------------------------------
local function merge(old, d, pend)
	old = clean(old)
	local new = fresh()
	new.Coins = math.max(0, old.Coins + pend.Coins)
	for k, v in old.Items do
		new.Items[k] = v
	end
	for k, v in pend.Items do
		local n = math.max(0, (new.Items[k] or 0) + v)
		new.Items[k] = n > 0 and n or nil
	end
	for k in old.Owned do
		new.Owned[k] = true
	end
	for k in d.Owned do
		new.Owned[k] = true
	end
	new.Equip = d.EquipDirty and table.clone(d.Equip) or old.Equip
	-- the daily streak: whichever copy claimed most recently
	if d.Daily.Day > old.Daily.Day or (d.Daily.Day == old.Daily.Day and d.Daily.Streak >= old.Daily.Streak) then
		new.Daily = table.clone(d.Daily)
	else
		new.Daily = old.Daily
	end
	-- quests: today's copy, the further progress of each
	if d.Quests.Day > old.Quests.Day then
		new.Quests = { Day = d.Quests.Day, P = table.clone(d.Quests.P), Done = table.clone(d.Quests.Done) }
	elseif d.Quests.Day == old.Quests.Day then
		local q = { Day = d.Quests.Day, P = table.clone(old.Quests.P), Done = table.clone(old.Quests.Done) }
		for k, v in d.Quests.P do
			q.P[k] = math.max(q.P[k] or 0, v)
		end
		for k in d.Quests.Done do
			q.Done[k] = true
		end
		new.Quests = q
	else
		new.Quests = old.Quests
	end
	new.Receipts = old.Receipts
	new.Earned = old.Earned + pend.Earned
	new.Crates = old.Crates + pend.Crates
	new.Welcomed = old.Welcomed or d.Welcomed
	return new
end

local function save(userId: number)
	local d, pend = docs[userId], pending[userId]
	if not d or not pend or not loaded[userId] then
		return
	end
	if not store then
		return -- (no DataStore: Studio without API access; everything stays in memory)
	end
	local snap = { Coins = pend.Coins, Items = table.clone(pend.Items), Earned = pend.Earned, Crates = pend.Crates }
	local result
	local ok, err = pcall(function()
		result = store:UpdateAsync("u" .. userId, function(old)
			return merge(old, d, snap)
		end)
	end)
	if not ok then
		warn("[Economy] save failed: " .. tostring(err))
		return
	end
	d.EquipDirty = nil
	-- what was saved is no longer pending; the view becomes the saved copy plus what's still pending
	pend.Coins -= snap.Coins
	pend.Earned -= snap.Earned
	pend.Crates -= snap.Crates
	for k, v in snap.Items do
		pend.Items[k] = (pend.Items[k] or 0) - v
		if pend.Items[k] == 0 then
			pend.Items[k] = nil
		end
	end
	if type(result) == "table" then
		local r = clean(result)
		d.Coins = math.max(0, r.Coins + pend.Coins)
		d.Items = {}
		for k, v in r.Items do
			d.Items[k] = v
		end
		for k, v in pend.Items do
			local n = math.max(0, (d.Items[k] or 0) + v)
			d.Items[k] = n > 0 and n or nil
		end
		for k in r.Owned do
			d.Owned[k] = true
		end
		d.Receipts = r.Receipts
		local p = Players:GetPlayerByUserId(userId)
		if p then
			mirror(p)
		end
	end
end

-- saved a moment after the last change (a burst of changes is one write)
local function queueSave(userId: number)
	if saveQueued[userId] then
		return
	end
	saveQueued[userId] = true
	task.delay(3, function()
		saveQueued[userId] = nil
		save(userId)
	end)
end

---------------------------------------------------------------------------
-- Coins and gear
---------------------------------------------------------------------------
function Economy.coins(player: Player): number
	local d = docs[player.UserId]
	return d and d.Coins or 0
end

-- add (or, negative, take) coins. Taking more than you have fails.
function Economy.addCoins(player: Player, n: number, earned: boolean?): boolean
	local d, pend = docs[player.UserId], pending[player.UserId]
	n = math.floor(n)
	if not d or not pend or n == 0 then
		return n == 0
	end
	if n < 0 and d.Coins + n < 0 then
		return false
	end
	d.Coins += n
	pend.Coins += n
	if earned and n > 0 then
		pend.Earned += n
		d.Earned += n
	end
	mirror(player)
	queueSave(player.UserId)
	if earned and n > 0 then
		Economy.track(player, "Earned", n)
	end
	return true
end

function Economy.itemCount(player: Player, id: string): number
	local d = docs[player.UserId]
	return d and d.Items[id] or 0
end

local function addItem(player: Player, id: string, n: number)
	local d, pend = docs[player.UserId], pending[player.UserId]
	if not d or not pend then
		return
	end
	local c = math.max(0, (d.Items[id] or 0) + n)
	d.Items[id] = c > 0 and c or nil
	pend.Items[id] = (pend.Items[id] or 0) + n
	mirror(player)
	queueSave(player.UserId)
end

function Economy.owns(player: Player, cosmeticId: string): boolean
	local d = docs[player.UserId]
	return d ~= nil and d.Owned[cosmeticId] == true
end

local function result(player: Player, payload)
	ctx.Remotes.EconomyResult:FireClient(player, payload)
end

function Economy.buy(player: Player, itemId: string): boolean
	local item = type(itemId) == "string" and Cat.item(itemId)
	local d = docs[player.UserId]
	if not item or not d or not loaded[player.UserId] then
		return false
	end
	if (d.Items[item.Id] or 0) >= Economy.MaxStack then
		result(player, { Kind = "Error", Text = "You're carrying as many as you can (" .. Economy.MaxStack .. ")." })
		return false
	end
	if not Economy.addCoins(player, -item.Price) then
		result(player, { Kind = "Error", Text = "Not enough coins." })
		return false
	end
	addItem(player, item.Id, 1)
	result(player, { Kind = "Buy", Id = item.Id, Name = item.Name })
	return true
end

-- a crate: a random cosmetic of a random rarity (by the crate's odds). A duplicate pays back.
local function roll(crate, rng: Random): any
	local total = 0
	for _, w in crate.Odds do
		total += w
	end
	local r = rng:NextNumber(0, total)
	local rarity = "Common"
	for _, name in { "Legendary", "Epic", "Rare", "Common" } do
		local w = crate.Odds[name] or 0
		if r < w then
			rarity = name
			break
		end
		r -= w
	end
	local pool = {}
	for _, c in Cat.Cosmetics do
		if c.Rarity == rarity then
			table.insert(pool, c)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end
Economy._roll = roll

local rng = Random.new()
function Economy.openCrate(player: Player, crateId: string, free: boolean?): any
	local crate = type(crateId) == "string" and Cat.crate(crateId)
	local d, pend = docs[player.UserId], pending[player.UserId]
	if not crate or not d or not pend or not loaded[player.UserId] then
		return nil
	end
	if not free and not Economy.addCoins(player, -crate.Price) then
		result(player, { Kind = "Error", Text = "Not enough coins." })
		return nil
	end
	local got = roll(crate, rng)
	local dup = d.Owned[got.Id] == true
	local refund = 0
	if dup then
		refund = Cat.Rarity[got.Rarity].Refund
		Economy.addCoins(player, refund)
	else
		d.Owned[got.Id] = true
	end
	d.Crates += 1
	pend.Crates += 1
	mirror(player)
	queueSave(player.UserId)
	local out = { Kind = "Crate", Crate = crate.Id, Id = got.Id, Name = got.Name, Rarity = got.Rarity, CosmeticKind = got.Kind, Dup = dup, Refund = refund }
	result(player, out)
	return out
end

-- give a cosmetic outright (the secret ending's title)
function Economy.grantCosmetic(player: Player, id: string): boolean
	local d = docs[player.UserId]
	if not d or not Cat.cosmetic(id) or d.Owned[id] then
		return false
	end
	d.Owned[id] = true
	mirror(player)
	queueSave(player.UserId)
	return true
end

function Economy.equip(player: Player, id: string): boolean
	local d = docs[player.UserId]
	local c = type(id) == "string" and Cat.cosmetic(id)
	if not d or not c or not d.Owned[id] then
		return false
	end
	if c.Kind == "Beam" then
		if ctx.Stats then
			ctx.Stats.setBeam(player, id)
		end
		return true
	end
	d.Equip[c.Kind] = id
	d.EquipDirty = true
	mirror(player)
	queueSave(player.UserId)
	return true
end

function Economy.unequip(player: Player, kind: string): boolean
	local d = docs[player.UserId]
	if not d or (kind ~= "Title" and kind ~= "Trail") then
		return false
	end
	d.Equip[kind] = nil
	d.EquipDirty = true
	mirror(player)
	queueSave(player.UserId)
	return true
end

---------------------------------------------------------------------------
-- The daily reward and daily quests
---------------------------------------------------------------------------
function Economy.claimDaily(player: Player): number?
	local d = docs[player.UserId]
	if not d or not loaded[player.UserId] then
		return nil
	end
	local view = dailyView(d)
	if not view.CanClaim then
		return nil
	end
	local streak = view.Next
	d.Daily = { Day = Cat.day(), Streak = streak }
	local coins = Cat.Daily[streak] or Cat.Daily[1]
	Economy.addCoins(player, coins, true)
	result(player, { Kind = "Daily", Streak = streak, Coins = coins })
	if streak == Cat.DailyCrateDay then
		task.delay(1.5, function()
			if player.Parent then
				Economy.openCrate(player, "Basic", true)
			end
		end)
	end
	mirror(player)
	queueSave(player.UserId)
	return coins
end

-- something a quest counts happened (stat names: Economy.Quests[].Stat)
function Economy.track(player: Player, stat: string, n: number?)
	local d = docs[player.UserId]
	if not d then
		return
	end
	n = n or 1
	local today = Cat.day()
	if d.Quests.Day ~= today then
		d.Quests = { Day = today, P = {}, Done = {} }
	end
	local changed = false
	for _, q in Cat.questsFor(today) do
		if q.Stat == stat and not d.Quests.Done[q.Id] then
			d.Quests.P[q.Id] = (d.Quests.P[q.Id] or 0) + n
			changed = true
			if d.Quests.P[q.Id] >= q.Goal then
				d.Quests.Done[q.Id] = true
				-- (paid right away; "Earned" quests don't count their own reward)
				Economy.addCoins(player, q.Coins, q.Stat ~= "Earned")
				result(player, { Kind = "Quest", Id = q.Id, Text = q.Text, Coins = q.Coins })
				ctx.Remotes.Notify:FireClient(player, "Quest complete: " .. q.Text .. "  +" .. q.Coins .. " coins", "done")
			end
		end
	end
	if changed then
		mirror(player)
		queueSave(player.UserId)
	end
end

---------------------------------------------------------------------------
-- The night: gear in, coins out
---------------------------------------------------------------------------
-- the night is starting: the gear you bought goes into your pockets (one of each), once
function Economy.applyLoadout(player: Player): { string }
	local d = docs[player.UserId]
	local given = {}
	if not d then
		return given
	end
	for _, item in Cat.Items do
		if (d.Items[item.Id] or 0) > 0 then
			addItem(player, item.Id, -1)
			if item.Id == "Lucky" then
				player:SetAttribute("Boost_Lucky", true)
			elseif item.Id == "Energy" then
				player:SetAttribute("Boost_Energy", true)
			elseif ctx.Inventory then
				ctx.Inventory.give(player, item.Id, 1)
			end
			table.insert(given, item.Name)
		end
	end
	if #given > 0 then
		ctx.Remotes.Notify:FireClient(player, "From the lobby: " .. table.concat(given, ", "), "info")
	end
	return given
end

--[[
	A player's night is over (escaped, died, or the ending). Works out their coins, pays them and
	returns { Total, Lines = { {Text, Amount} }, Balance } for their result card. Paid once a night;
	`newEnding` adds the bonus for an ending they hadn't seen (it can come after the rest).
]]
function Economy.nightRewards(player: Player, info): any
	local N = Cat.Night
	info = info or {}
	local lines = {}
	local function add(text: string, n: number)
		if n > 0 then
			table.insert(lines, { Text = text, Amount = math.floor(n) })
		end
	end
	if granted[player] then
		-- (already paid: only the new-ending bonus can still come)
		if info.NewEnding then
			add("New ending found", N.NewEnding)
		end
	else
		granted[player] = true
		local seconds = math.max(0, info.Seconds or 0)
		if seconds >= N.MinSeconds then
			add("Played a night", N.Played)
		end
		add("Lasted " .. math.floor(seconds / 60) .. " min", math.min(N.MinuteCap, math.floor(seconds / 60)) * N.PerMinute)
		if info.Survived then
			add("Survived", N.Survived)
		end
		local rescues = tonumber(player:GetAttribute("NightRescues")) or 0
		add("Friends cut free ×" .. rescues, rescues * N.Rescue)
		if info.NewEnding then
			add("New ending found", N.NewEnding)
		end
		if info.Secret then
			add("The secret ending", N.Secret)
		end
	end
	local total = 0
	for _, l in lines do
		total += l.Amount
	end
	local mult = 1
	if workspace:GetAttribute("Difficulty") == "Hard" then
		mult *= N.HardMultiplier
	end
	if player:GetAttribute("Boost_Lucky") then
		mult *= N.LuckyMultiplier
	end
	if mult > 1 and total > 0 then
		local bonus = math.floor(total * mult) - total
		table.insert(lines, { Text = (player:GetAttribute("Boost_Lucky") and "Lucky charm" or "Hard mode") .. " bonus", Amount = bonus })
		total += bonus
	end
	if total > 0 then
		Economy.addCoins(player, total, true)
	end
	return { Total = total, Lines = lines, Balance = Economy.coins(player) }
end

-- the night's quest counters, for everyone who played it (EndingService)
function Economy.nightEnded(players: { Player }, kind: string, firsts: { [number]: boolean })
	local story = ctx.Story and ctx.Story.Endings[kind]
	local bad = story and story.Bad == true
	for _, p in players do
		Economy.track(p, "Nights", 1)
		if workspace:GetAttribute("Difficulty") == "Hard" then
			Economy.track(p, "HardNights", 1)
		end
		if #players >= 2 then
			Economy.track(p, "GroupNights", 1)
		end
		if p:GetAttribute("Escaped") or (not bad and not p:GetAttribute("Dead") and not p:GetAttribute("Captured")) then
			Economy.track(p, "Survived", 1)
		end
		if firsts[p.UserId] then
			Economy.track(p, "NewEndings", 1)
		end
	end
end

function Economy.resetNight()
	granted = {}
end

---------------------------------------------------------------------------
-- Robux coin packs (ShopService routes the receipts here)
---------------------------------------------------------------------------
function Economy.isPack(productId: number): boolean
	return Cat.pack(productId) ~= nil
end

function Economy.onReceipt(info): Enum.ProductPurchaseDecision
	local pack = Cat.pack(info.ProductId)
	if not pack then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local userId = info.PlayerId
	local key = tostring(info.PurchaseId)
	local already = false
	if store then
		local ok = pcall(function()
			store:UpdateAsync("u" .. userId, function(old)
				local d = clean(old)
				if table.find(d.Receipts, key) then
					already = true
					return nil
				end
				d.Coins += pack.Coins
				table.insert(d.Receipts, key)
				while #d.Receipts > 40 do
					table.remove(d.Receipts, 1)
				end
				return d
			end)
		end)
		if not ok then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
	local player = Players:GetPlayerByUserId(userId)
	if not already then
		local d = docs[userId]
		if d then
			d.Coins += pack.Coins
			if not store then
				pending[userId].Coins += pack.Coins
			end
			table.insert(d.Receipts, key)
			if player then
				mirror(player)
			end
		end
		if player then
			result(player, { Kind = "Pack", Coins = pack.Coins })
			ctx.Remotes.Notify:FireClient(player, "+" .. pack.Coins .. " coins. Thank you!", "done")
		end
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

---------------------------------------------------------------------------
-- The lobby: titles over heads, trails behind feet
---------------------------------------------------------------------------
local function dressLobby(player: Player)
	if workspace:GetAttribute("Mode") ~= "Lobby" then
		return
	end
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not head or not root then
		return
	end
	-- the title
	local tag = head:FindFirstChild("TitleTag")
	local text = player:GetAttribute("TitleText")
	if text then
		if not tag then
			tag = Instance.new("BillboardGui")
			tag.Name = "TitleTag"
			tag.Size = UDim2.fromOffset(200, 22)
			tag.StudsOffset = Vector3.new(0, head:FindFirstChild("SupporterTag") and 3.3 or 2.4, 0)
			tag.MaxDistance = 70
			tag.LightInfluence = 0
			local l = Instance.new("TextLabel")
			l.Name = "Text"
			l.Size = UDim2.fromScale(1, 1)
			l.BackgroundTransparency = 1
			l.Font = Enum.Font.GothamBold
			l.TextScaled = true
			l.TextStrokeTransparency = 0.35
			l.Parent = tag
			tag.Parent = head
		end
		local l = tag:FindFirstChild("Text") :: TextLabel
		l.Text = "« " .. text .. " »"
		local c = player:GetAttribute("TitleColor")
		l.TextColor3 = typeof(c) == "Color3" and c or Color3.new(1, 1, 1)
	elseif tag then
		tag:Destroy()
	end
	-- the trail
	local trailId = player:GetAttribute("TrailId")
	local trail = root:FindFirstChild("CosmeticTrail")
	if trail then
		trail:Destroy()
		for _, n in { "TrailA", "TrailB" } do
			local a = root:FindFirstChild(n)
			if a then
				a:Destroy()
			end
		end
	end
	local def = trailId and Cat.cosmetic(trailId)
	if def then
		local a0 = Instance.new("Attachment")
		a0.Name = "TrailA"
		a0.Position = Vector3.new(0, 0.6, 0)
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Name = "TrailB"
		a1.Position = Vector3.new(0, -1.6, 0)
		a1.Parent = root
		local t = Instance.new("Trail")
		t.Name = "CosmeticTrail"
		t.Attachment0 = a0
		t.Attachment1 = a1
		t.Lifetime = 0.7
		t.LightEmission = 0.8
		t.FaceCamera = true
		t.Transparency = NumberSequence.new(0.2, 1)
		t.Color = ColorSequence.new(def.Color)
		if def.Rainbow then
			t.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
				ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 60)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 120)),
				ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 80, 255)),
			})
		end
		t.Parent = root
	end
end

---------------------------------------------------------------------------
local function load(player: Player)
	local userId = player.UserId
	docs[userId] = fresh()
	pending[userId] = freshPending()
	local fresh_ = false
	if store then
		local ok, data
		for attempt = 1, 3 do
			ok, data = pcall(function()
				return store:GetAsync("u" .. userId)
			end)
			if ok then
				break
			end
			task.wait(attempt)
		end
		if not ok then
			warn("[Economy] couldn't load " .. userId .. "; coins won't be saved this visit")
			mirror(player)
			return
		end
		docs[userId] = clean(data)
		fresh_ = data == nil
	else
		fresh_ = true
	end
	loaded[userId] = true
	local d = docs[userId]
	if fresh_ or not d.Welcomed then
		-- a welcome present for a brand-new player
		d.Welcomed = true
		Economy.addCoins(player, Cat.StartCoins)
	end
	mirror(player)
	-- (a crate flashlight colour can only be shown once we know it's yours)
	if ctx.Stats and ctx.Stats.refresh then
		ctx.Stats.refresh(player)
	end
end

function Economy.init(c)
	ctx = c
	ctx.Economy = Economy
	Cat = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Economy"))
	Economy.Catalog = Cat
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore("Economy_v1")
	end)
	store = ok and ds or nil
end

function Economy.start()
	ctx.Remotes.Economy.OnServerEvent:Connect(function(player, action, arg)
		local now = os.clock()
		if lastAction[player] and now - lastAction[player] < 0.35 then
			return
		end
		lastAction[player] = now
		if action == "Buy" then
			Economy.buy(player, arg)
		elseif action == "Crate" then
			Economy.openCrate(player, arg)
		elseif action == "Equip" then
			Economy.equip(player, arg)
		elseif action == "Unequip" then
			Economy.unequip(player, arg)
		elseif action == "Daily" then
			Economy.claimDaily(player)
		end
	end)
	local function added(player: Player)
		task.spawn(load, player)
		if workspace:GetAttribute("Mode") == "Lobby" then
			player.CharacterAdded:Connect(function()
				task.wait(0.6)
				dressLobby(player)
			end)
			for _, a in { "TitleText", "TitleColor", "TrailId" } do
				player:GetAttributeChangedSignal(a):Connect(function()
					dressLobby(player)
				end)
			end
		end
	end
	for _, p in Players:GetPlayers() do
		added(p)
	end
	Players.PlayerAdded:Connect(added)
	Players.PlayerRemoving:Connect(function(p)
		local userId = p.UserId
		lastAction[p] = nil
		granted[p] = nil
		task.spawn(function()
			save(userId)
			docs[userId] = nil
			pending[userId] = nil
			loaded[userId] = nil
		end)
	end)
	game:BindToClose(function()
		if RunService:IsStudio() and not store then
			return
		end
		for _, p in Players:GetPlayers() do
			task.spawn(save, p.UserId)
		end
		task.wait(3)
	end)
	-- the day rolls over: the daily reward and the quests change for everyone online
	task.spawn(function()
		local day = Cat.day()
		while true do
			task.wait(30)
			if Cat.day() ~= day then
				day = Cat.day()
				for _, p in Players:GetPlayers() do
					mirror(p)
				end
			end
		end
	end)
end

Economy._docs = docs -- (tests)
Economy._pending = pending
Economy._save = save
Economy._merge = merge
Economy._clean = clean
Economy._load = load

return Economy
