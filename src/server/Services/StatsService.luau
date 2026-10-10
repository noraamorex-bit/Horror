--[[
	StatsService — what each player has done across nights, saved in a DataStore:
	nights played, nights escaped (walked out alive), and which endings they have seen.

	Loaded when a player joins (both the lobby and a game server) and mirrored into player
	attributes the UI reads: StatNights, StatEscapes, StatEndings, StatEndingTotal.
	Everything is best-effort: without DataStore access (Studio without API access) the numbers
	simply start at zero and nothing is saved.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Stats = {}
local ctx
local store = nil
local board = nil -- OrderedDataStore: nights survived, for the lobby leaderboard
local fastBoard = nil -- OrderedDataStore: fastest win in seconds (lowest first), for the second sign
local cache = {} -- userId -> { Nights, Escapes, Endings = { [kind] = true } }

local function fresh()
	return { Nights = 0, Escapes = 0, Endings = {}, Referrals = 0, Referred = false, Beam = "Classic", Best = 0, ReviveCredits = 0, Tips = 0, Settings = { Music = 1, Sfx = 1, Shake = true } }
end

--[[
	Invite rewards: bring friends, get flashlight colours. A friend counts once, the first time
	they ever play: they joined from your invite (LaunchData "ref:<userId>") or turned up in the
	same server as you (a Roblox friend) on their first visit. They get the first colour too.
]]
Stats.Beams = {
	{ Id = "Classic", Name = "Classic", Need = 0, Color = Color3.fromRGB(255, 244, 222) },
	{ Id = "Ember", Name = "Ember", Need = 1, Color = Color3.fromRGB(255, 140, 50) },
	{ Id = "Moonlight", Name = "Moonlight", Need = 3, Color = Color3.fromRGB(130, 175, 255) },
	{ Id = "Blood", Name = "Blood moon", Need = 5, Color = Color3.fromRGB(255, 45, 40) },
	-- game passes (ShopService): Supporter's gold, and Ghost with the colours pass
	{ Id = "Gold", Name = "Gold", Pass = "Supporter", Color = Color3.fromRGB(255, 196, 60) },
	{ Id = "Ghost", Name = "Ghost", Pass = "Colours", Color = Color3.fromRGB(120, 255, 185) },
}
-- and the colours that come out of crates (EconomyService: you own them)
do
	local Cat = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Economy"))
	for _, c in Cat.Cosmetics do
		if c.Kind == "Beam" then
			table.insert(Stats.Beams, { Id = c.Id, Name = c.Name, Crate = true, Rainbow = c.Rainbow, Color = c.Color })
		end
	end
end

local function beamUnlocked(d, id: string, player: Player?): boolean
	local colours = player ~= nil and player:GetAttribute("Pass_Colours") == true
	for _, b in Stats.Beams do
		if b.Id == id then
			if b.Crate then
				return player ~= nil and ctx.Economy ~= nil and ctx.Economy.owns(player, id)
			end
			if b.Pass then
				-- (each pass colour is its own: Gold is the supporters')
				return player ~= nil and player:GetAttribute("Pass_" .. b.Pass) == true
			end
			return colours or d.Referrals >= b.Need or (b.Need == 1 and d.Referred)
		end
	end
	return false
end

local function endingTotal(): number
	local n = 0
	for _ in ctx.Story.Endings do
		n += 1
	end
	return n
end

local function mirror(player: Player)
	local d = cache[player.UserId]
	if not d then
		return
	end
	local found = 0
	for _ in d.Endings do
		found += 1
	end
	player:SetAttribute("StatNights", d.Nights)
	player:SetAttribute("StatEscapes", d.Escapes)
	player:SetAttribute("StatEndings", found)
	player:SetAttribute("StatEndingTotal", endingTotal())
	local list = {}
	for k in d.Endings do
		table.insert(list, k)
	end
	table.sort(list)
	player:SetAttribute("StatEndingList", table.concat(list, ","))
	player:SetAttribute("StatReferrals", d.Referrals)
	player:SetAttribute("StatReferred", d.Referred)
	-- (the saved pick is kept even while it's locked: passes are checked a moment after joining,
	-- and a pass colour must not be wiped just because that check hasn't finished yet)
	local beam = beamUnlocked(d, d.Beam, player) and d.Beam or "Classic"
	player:SetAttribute("StatBeam", beam)
	player:SetAttribute("StatBest", d.Best > 0 and d.Best or nil)
	player:SetAttribute("StatTips", d.Tips)
	player:SetAttribute("ReviveCredits", d.ReviveCredits > 0 and d.ReviveCredits or nil)
	player:SetAttribute("SetMusic", d.Settings.Music)
	player:SetAttribute("SetSfx", d.Settings.Sfx)
	player:SetAttribute("SetShake", d.Settings.Shake)
	for _, b in Stats.Beams do
		if b.Id == beam then
			player:SetAttribute("StatBeamColor", b.Color)
			player:SetAttribute("StatBeamRainbow", b.Rainbow or nil)
		end
	end
end

local checkReferral: (Player) -> () -- below: needs save()

local function load(player: Player)
	cache[player.UserId] = fresh()
	if store then
		local ok, data = pcall(function()
			return store:GetAsync("u" .. player.UserId)
		end)
		if ok and type(data) == "table" then
			local d = fresh()
			d.Nights = tonumber(data.Nights) or 0
			d.Escapes = tonumber(data.Escapes) or 0
			d.Referrals = tonumber(data.Referrals) or 0
			d.Referred = data.Referred == true
			d.Beam = type(data.Beam) == "string" and data.Beam or "Classic"
			d.Best = math.max(0, math.floor(tonumber(data.Best) or 0))
			d.ReviveCredits = math.max(0, math.floor(tonumber(data.ReviveCredits) or 0))
			d.Tips = math.max(0, math.floor(tonumber(data.Tips) or 0))
			local set = type(data.Settings) == "table" and data.Settings or {}
			d.Settings = {
				Music = math.clamp(tonumber(set.Music) or 1, 0, 1),
				Sfx = math.clamp(tonumber(set.Sfx) or 1, 0, 1),
				Shake = set.Shake ~= false,
			}
			for k, v in (type(data.Endings) == "table" and data.Endings or {}) do
				if v then
					d.Endings[k] = true
				end
			end
			cache[player.UserId] = d
		end
	end
	mirror(player)
	task.spawn(checkReferral, player)
end

local function save(userId: number)
	local d = cache[userId]
	if not store or not d then
		return
	end
	task.spawn(function()
		pcall(function()
			store:UpdateAsync("u" .. userId, function(old)
				-- merge with whatever is saved (another server may have written meanwhile)
				old = type(old) == "table" and old or {}
				local endings = type(old.Endings) == "table" and old.Endings or {}
				for k in d.Endings do
					endings[k] = true
				end
				-- (invites and the chosen beam ride along: a save must never wipe them)
				return {
					Nights = math.max(tonumber(old.Nights) or 0, d.Nights),
					Escapes = math.max(tonumber(old.Escapes) or 0, d.Escapes),
					Endings = endings,
					Referrals = math.max(tonumber(old.Referrals) or 0, d.Referrals),
					Referred = old.Referred == true or d.Referred,
					Beam = d.Beam,
					Best = (function()
						local a, b = tonumber(old.Best) or 0, d.Best
						if a > 0 and b > 0 then
							return math.min(a, b)
						end
						return math.max(a, b)
					end)(),
					Settings = d.Settings,
					ReviveCredits = d.ReviveCredits,
					Tips = math.max(tonumber(old.Tips) or 0, d.Tips),
				}
			end)
		end)
	end)
end

-- credit whoever brought this brand-new player
local function creditReferrer(referrerId: number, newcomer: Player)
	local online = Players:GetPlayerByUserId(referrerId)
	if online and cache[referrerId] then
		local d = cache[referrerId]
		local before = d.Referrals
		d.Referrals += 1
		mirror(online)
		save(referrerId)
		for _, b in Stats.Beams do
			if b.Need and before < b.Need and d.Referrals >= b.Need then
				ctx.Remotes.Notify:FireClient(online, newcomer.DisplayName .. " joined you. Flashlight colour unlocked: " .. b.Name, "done")
				return
			end
		end
		ctx.Remotes.Notify:FireClient(online, newcomer.DisplayName .. " joined you. Friends brought: " .. d.Referrals, "info")
	elseif store then
		task.spawn(pcall, function()
			store:UpdateAsync("u" .. referrerId, function(old)
				old = type(old) == "table" and old or {}
				old.Referrals = (tonumber(old.Referrals) or 0) + 1
				return old
			end)
		end)
	end
end

checkReferral = function(player: Player)
	-- only on arrival in the lobby (where invites and friends land), so moving on to a game
	-- server can never count the same friend twice
	local t0 = os.clock()
	while workspace:GetAttribute("Mode") == nil and os.clock() - t0 < 5 do
		task.wait(0.2)
	end
	if workspace:GetAttribute("Mode") ~= "Lobby" then
		return
	end
	local d = cache[player.UserId]
	if not d or d.Referred or d.Nights > 0 then
		return
	end
	local referrer: number? = nil
	local okJoin, join = pcall(function()
		return player:GetJoinData()
	end)
	local launch = okJoin and type(join) == "table" and join.LaunchData
	if type(launch) == "string" then
		local id = tonumber(string.match(launch, "^ref:(%d+)$"))
		if id and id ~= player.UserId then
			referrer = id
		end
	end
	if not referrer then
		for _, other in Players:GetPlayers() do
			if other ~= player then
				local okF, isFriend = pcall(function()
					return player:IsFriendsWithAsync(other.UserId)
				end)
				if okF and isFriend then
					referrer = other.UserId
					break
				end
			end
		end
	end
	if not referrer then
		return
	end
	d.Referred = true
	mirror(player)
	save(player.UserId)
	ctx.Remotes.Notify:FireClient(player, "A friend brought you here. Flashlight colour unlocked: Ember", "done")
	creditReferrer(referrer, player)
end

-- pick a flashlight colour you've unlocked
function Stats.setBeam(player: Player, id: string)
	local d = cache[player.UserId]
	if not d or type(id) ~= "string" or not beamUnlocked(d, id, player) then
		return
	end
	d.Beam = id
	mirror(player)
	save(player.UserId)
end

-- the settings panel: music and sound volume (0-1), camera shake. Saved a few seconds after the
-- last change, so dragging through the options doesn't spam the DataStore.
local settingsSave: { [number]: boolean } = {}
function Stats.setSettings(player: Player, music: any, sfx: any, shake: any)
	local d = cache[player.UserId]
	if not d or type(music) ~= "number" or type(sfx) ~= "number" or type(shake) ~= "boolean" then
		return
	end
	if music ~= music or sfx ~= sfx then -- NaN
		return
	end
	d.Settings = { Music = math.clamp(music, 0, 1), Sfx = math.clamp(sfx, 0, 1), Shake = shake }
	mirror(player)
	local userId = player.UserId
	if not settingsSave[userId] then
		settingsSave[userId] = true
		task.delay(4, function()
			settingsSave[userId] = nil
			save(userId)
		end)
	end
end

-- passes changed (ShopService): re-check what's unlocked and update the attributes
function Stats.refresh(player: Player)
	mirror(player)
end

function Stats.beamColor(player: Player): Color3
	local id = player:GetAttribute("StatBeam")
	for _, b in Stats.Beams do
		if b.Id == id then
			return b.Color
		end
	end
	return Stats.Beams[1].Color
end

-- A win (escaped, or still standing at a good ending) took this many seconds. Keeps the
-- player's best and puts it on the fastest-wins board. Returns true for a new personal best.
-- the owner (Config.Admins, and the experience's creator) never appears on the public boards
local function offBoards(userId: number): boolean
	if ctx and ctx.Config and table.find(ctx.Config.Admins or {}, userId) then
		return true
	end
	return game.CreatorType == Enum.CreatorType.User and game.CreatorId ~= 0 and userId == game.CreatorId
end
Stats.offBoards = offBoards

function Stats.recordWin(player: Player, seconds: number): boolean
	local d = cache[player.UserId]
	seconds = math.floor(seconds)
	if not d or seconds <= 0 or (ctx.Config and ctx.Config.Debug) then
		return false
	end
	if d.Best > 0 and seconds >= d.Best then
		return false
	end
	d.Best = seconds
	mirror(player)
	save(player.UserId)
	if fastBoard and not offBoards(player.UserId) then
		local userId = player.UserId
		task.spawn(function()
			pcall(function()
				fastBoard:UpdateAsync("u" .. userId, function(old)
					old = tonumber(old)
					if old and old > 0 and old <= seconds then
						return nil -- (keep the faster time already there)
					end
					return seconds
				end)
			end)
		end)
	end
	return true
end

-- the "how he hunts" tips: shown again whenever they change (Story.SurvivalTipsVersion)
function Stats.markTips(player: Player, version: number)
	local d = cache[player.UserId]
	if not d or d.Tips >= version then
		return
	end
	d.Tips = version
	mirror(player)
	save(player.UserId)
end

-- Revives bought when they couldn't be used (the night was already over, or you were in the
-- lobby): kept, and offered the next time you die.
function Stats.addReviveCredit(player: Player): boolean
	local d = cache[player.UserId]
	if not d then
		return false
	end
	d.ReviveCredits += 1
	mirror(player)
	save(player.UserId)
	return true
end

function Stats.spendReviveCredit(player: Player): boolean
	local d = cache[player.UserId]
	if not d or d.ReviveCredits <= 0 then
		return false
	end
	d.ReviveCredits -= 1
	mirror(player)
	save(player.UserId)
	return true
end

-- A night ended for these players. Returns { [userId] = true } for everyone who saw this ending
-- for the first time.
function Stats.recordNight(players: { Player }, kind: string)
	local firsts = {}
	for _, p in players do
		local d = cache[p.UserId]
		if d then
			d.Nights += 1
			if p:GetAttribute("Escaped") or (not p:GetAttribute("Captured") and not (ctx.Story.Endings[kind] and ctx.Story.Endings[kind].Bad)) then
				d.Escapes += 1
			end
			if not d.Endings[kind] then
				d.Endings[kind] = true
				firsts[p.UserId] = true
			end
			mirror(p)
			save(p.UserId)
			if board and not offBoards(p.UserId) then
				local userId, value = p.UserId, d.Escapes
				task.spawn(function()
					pcall(function()
						board:SetAsync("u" .. userId, value)
					end)
				end)
			end
		end
	end
	return firsts
end

function Stats.init(c)
	ctx = c
	ctx.Stats = Stats
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore("PlayerStats_v1")
	end)
	store = ok and ds or nil
	local ok2, ods = pcall(function()
		return DataStoreService:GetOrderedDataStore("NightsSurvived_v1")
	end)
	board = ok2 and ods or nil
	local ok3, fds = pcall(function()
		return DataStoreService:GetOrderedDataStore("FastestWin_v1")
	end)
	fastBoard = ok3 and fds or nil
	-- (take the owner off the boards if an earlier version put them there)
	task.spawn(function()
		local ids = table.clone(ctx.Config and ctx.Config.Admins or {})
		if game.CreatorType == Enum.CreatorType.User and game.CreatorId ~= 0 then
			table.insert(ids, game.CreatorId)
		end
		for _, id in ids do
			for _, b in { board, fastBoard } do
				if b then
					pcall(function()
						b:RemoveAsync("u" .. id)
					end)
				end
			end
		end
	end)
end

-- the top survivors (or, with "Fastest", the fastest wins), for the lobby signs: { { Name, Value } }
local names: { [number]: string } = {}
function Stats.top(n: number, which: string?)
	local out = {}
	local fastest = which == "Fastest"
	local store_ = if fastest then fastBoard else board
	if not store_ then
		return out
	end
	local ok, pages = pcall(function()
		return store_:GetSortedAsync(fastest, n + 4, if fastest then 1 else nil)
	end)
	if not ok or not pages then
		return out
	end
	for _, entry in pages:GetCurrentPage() do
		local userId = tonumber(string.sub(entry.key, 2))
		if #out >= n or (userId and offBoards(userId)) then
			continue
		end
		local name = userId and names[userId] or "?"
		if userId and not names[userId] then
			local okName, n2 = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if okName and n2 then
				name = n2
				names[userId] = n2
			end
		end
		table.insert(out, { Name = name, Value = entry.value })
	end
	return out
end

function Stats.start()
	if ctx.Remotes then
		ctx.Remotes.SetBeam.OnServerEvent:Connect(function(player, id)
			Stats.setBeam(player, id)
		end)
		ctx.Remotes.SaveSettings.OnServerEvent:Connect(function(player, music, sfx, shake)
			Stats.setSettings(player, music, sfx, shake)
		end)
	end
	for _, p in Players:GetPlayers() do
		task.spawn(load, p)
	end
	Players.PlayerAdded:Connect(load)
	-- the rainbow beam cycles through the colours
	task.spawn(function()
		local Cat = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Economy"))
		while true do
			task.wait(0.25)
			for _, p in Players:GetPlayers() do
				if p:GetAttribute("StatBeamRainbow") then
					p:SetAttribute("StatBeamColor", Cat.rainbow(os.clock()))
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		if settingsSave[p.UserId] then
			settingsSave[p.UserId] = nil
			save(p.UserId) -- (a settings change still waiting to be saved)
		end
		cache[p.UserId] = nil
	end)
end

return Stats
