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
local cache = {} -- userId -> { Nights, Escapes, Endings = { [kind] = true } }

local function fresh()
	return { Nights = 0, Escapes = 0, Endings = {}, Referrals = 0, Referred = false, Beam = "Classic" }
end

--[[
	Invite rewards: bring friends, get flashlight colours. A friend counts once, the first time
	they ever play: they joined from your invite (LaunchData "ref:<userId>") or turned up in the
	same server as you (a Roblox friend) on their first visit. They get the first colour too.
]]
Stats.Beams = {
	{ Id = "Classic", Name = "Classic", Need = 0, Color = Color3.fromRGB(255, 244, 222) },
	{ Id = "Ember", Name = "Ember", Need = 1, Color = Color3.fromRGB(255, 176, 96) },
	{ Id = "Moonlight", Name = "Moonlight", Need = 3, Color = Color3.fromRGB(190, 214, 255) },
	{ Id = "Blood", Name = "Blood moon", Need = 5, Color = Color3.fromRGB(255, 96, 80) },
}

local function beamUnlocked(d, id: string): boolean
	for _, b in Stats.Beams do
		if b.Id == id then
			return d.Referrals >= b.Need or (b.Need == 1 and d.Referred)
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
	if not beamUnlocked(d, d.Beam) then
		d.Beam = "Classic"
	end
	player:SetAttribute("StatBeam", d.Beam)
	for _, b in Stats.Beams do
		if b.Id == d.Beam then
			player:SetAttribute("StatBeamColor", b.Color)
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
				return {
					Nights = math.max(tonumber(old.Nights) or 0, d.Nights),
					Escapes = math.max(tonumber(old.Escapes) or 0, d.Escapes),
					Endings = endings,
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
			if before < b.Need and d.Referrals >= b.Need then
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
	if not d or type(id) ~= "string" or not beamUnlocked(d, id) then
		return
	end
	d.Beam = id
	mirror(player)
	save(player.UserId)
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
			if board then
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
end

-- the top survivors, for the lobby sign: { { Name, Value } }
function Stats.top(n: number)
	local out = {}
	if not board then
		return out
	end
	local ok, pages = pcall(function()
		return board:GetSortedAsync(false, n)
	end)
	if not ok or not pages then
		return out
	end
	for _, entry in pages:GetCurrentPage() do
		local userId = tonumber(string.sub(entry.key, 2))
		local name = "?"
		if userId then
			local okName, n2 = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			name = okName and n2 or name
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
	end
	for _, p in Players:GetPlayers() do
		task.spawn(load, p)
	end
	Players.PlayerAdded:Connect(load)
	Players.PlayerRemoving:Connect(function(p)
		cache[p.UserId] = nil
	end)
end

return Stats
