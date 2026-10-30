--[[
	MatchService — no lonely nights when someone else's has just started.

	The logs: a night alone was abandoned 12 times out of 13 (v78: 14 of 15), a night of three or four
	almost never, and with few people online a group circle often goes with one player.

	• Game server (a group circle's reserved server): a night that started short (fewer players than
	  its circle was for) lists itself in a MemoryStore sorted map (key = its access code, which arrived
	  with the players' teleport data) while late arrivals can still join (Director.lateJoinOpen: the
	  first two acts, until bedtime; Config.Lobby.JoinOpenFor at most) and it has room, up to
	  MaxPlayers. PLAY SOLO nights (circle of 1) and nights that started full are never listed.
	• Lobby: every group circle, full or not, looks for such a night when its countdown runs out and,
	  if there's room for all of them, sends its players there instead ("You made it just in time").
	  A short group sent to a fresh house is listed by the lobby at once (Match.listNew), and the
	  game server keeps it listed while its players arrive and vote, then through acts I-II.
	• (v124) Friends find each other. The v121-122 logs: 33 of 36 first-nighters who left a night within
	  30 s went straight back to the lobby (30 played a night after), most of them sent by a "2 players"
	  circle's countdown before their friend got there. So every house that can still take an invited
	  friend (InviteOpen) lists who is in it ("f:<code>"); a lobby offers its players a friend's house
	  (JOIN ▶, LobbyServer) and leaves word for that house ("c:<code>": the HUD says "Sam is in the
	  lobby: they can join you", so the one who's in there waits instead of leaving).
]]

local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")

local Match = {}
local ctx
local MAP_NAME = "OpenNights_v1"
local TTL = 30 -- seconds an entry lives unless refreshed
local map = nil
local code: string? = nil -- (game server) this server's access code
local cap: number? = nil -- (game server) the size of the circle it came from
local party: number? = nil -- (game server) how many came over together to start the night
local listed = false
-- (v113) every lobby server's head count, so a lone night can say how many might join it
local PULSE_NAME = "LobbyPulse_v1"
local pulseMap = nil
local lobbyNowAt = 0
-- (v124) who is in each house a friend can still join, and which friends in a lobby have seen it
local FRIENDS_NAME = "FriendNights_v1"
local friendMap = nil
local friendListed = false

local function getFriendMap()
	if not friendMap then
		local ok, m = pcall(function()
			return MemoryStoreService:GetSortedMap(FRIENDS_NAME)
		end)
		if ok then
			friendMap = m
		end
	end
	return friendMap
end

local function getPulse()
	if not pulseMap then
		local ok, m = pcall(function()
			return MemoryStoreService:GetSortedMap(PULSE_NAME)
		end)
		if ok then
			pulseMap = m
		end
	end
	return pulseMap
end

-- how many players are in lobbies right now (every lobby server's last pulse), or nil
local function lobbyNow(): number?
	local m = getPulse()
	if not m then
		return nil
	end
	local ok, items = pcall(function()
		return m:GetRangeAsync(Enum.SortDirection.Ascending, 100)
	end)
	if not ok or type(items) ~= "table" then
		return nil
	end
	local total = 0
	for _, item in items do
		local v = item.value
		if type(v) == "table" and tonumber(v.n) and os.time() - (tonumber(v.at) or 0) < 25 then
			total += v.n
		end
	end
	return total
end
Match._lobbyNow = lobbyNow -- (tests)

local function getMap()
	if not map then
		local ok, m = pcall(function()
			return MemoryStoreService:GetSortedMap(MAP_NAME)
		end)
		if ok then
			map = m
		end
	end
	return map
end

function Match.init(c)
	ctx = c
	ctx.Match = Match
end

---------------------------------------------------------------------------
-- Game server
---------------------------------------------------------------------------
local function readJoin(p: Player)
	local ok, data = pcall(function()
		return p:GetJoinData()
	end)
	local td = ok and data and data.TeleportData
	if type(td) == "table" then
		if type(td.Code) == "string" and not code then
			code = td.Code
			-- (the night's own invite link: a friend invited from here comes straight to this house)
			workspace:SetAttribute("NightCode", code)
		end
		if tonumber(td.Cap) and not cap then
			cap = tonumber(td.Cap)
		end
		if tonumber(td.PartySize) and not party then
			party = tonumber(td.PartySize)
		end
		-- (v122) who was left in the lobby when this short group was sent: the lone player is told they
		-- can follow (v116-121 logs: 30 of 35 new players who left a lone night within 30 s had others in
		-- the lobby when they were sent, and went back to them; alone in the lobby, players stayed)
		if tonumber(td.Behind) and tonumber(td.Behind) > 0 and not workspace:GetAttribute("LobbyBehind") then
			workspace:SetAttribute("LobbyBehind", math.floor(tonumber(td.Behind) :: number))
			if type(td.BehindNames) == "string" and #td.BehindNames > 0 then
				workspace:SetAttribute("LobbyBehindNames", string.sub(td.BehindNames, 1, 60))
			end
		end
	end
end

-- is this night taking more players right now? (and how many it has)
function Match.isOpen(): (boolean, number)
	local n = #ctx.Util.sessionPlayers()
	local L = ctx.Config.Lobby
	local D = ctx.Director
	if not (code and cap and cap > 1 and D) then
		return false, n
	end
	-- (a night that started full is a group that wanted to be together: never offered)
	local startedShort = party == nil or party < cap
	-- (and before it starts, while its players arrive and vote, anyone who comes is there from the
	-- very beginning: v88-90 logs, 43 of 70 lone nights had another night start within a minute,
	-- mostly in that gap before a fresh night first listed itself)
	local waiting = D.getAct() == "Lobby"
	if waiting then
		n = #Players:GetPlayers()
	end
	local early = waiting or (if D.lateJoinOpen then D.lateJoinOpen() else D.getAct() == "Evening")
	local open = startedShort and early and D.elapsedSeconds() < (L.JoinOpenFor or 420) and not (D.isSkipping and D.isSkipping())
		and not workspace:GetAttribute("AdminUsed") -- (a stranger never lands in an admin panel night)
		and n >= 1 and n < ctx.Config.MaxPlayers
	return open, n
end

local function publish()
	-- (an invited friend can come in, even to a PLAY SOLO night, while late arrivals still join it)
	local D = ctx.Director
	local inviteOpen = code ~= nil and D ~= nil and (D.getAct() == "Lobby" or (D.lateJoinOpen ~= nil and D.lateJoinOpen()))
		and #Players:GetPlayers() < ctx.Config.MaxPlayers
	workspace:SetAttribute("InviteOpen", inviteOpen or nil)
	-- (v124) friends: who's in here, for a friend's lobby; and whether one of them has seen it
	local fm = getFriendMap()
	if fm and code then
		local ids, names = {}, {}
		for _, p in Players:GetPlayers() do
			local uid = (p :: any).UserId
			if tonumber(uid) then
				table.insert(ids, uid)
				table.insert(names, tostring((p :: any).DisplayName or (p :: any).Name))
			end
		end
		if inviteOpen and #ids > 0 then
			friendListed = pcall(function()
				fm:SetAsync("f:" .. code, { u = ids, nm = names, n = #ids, at = os.time() }, TTL)
			end) or friendListed
			local ok, v = pcall(function()
				return fm:GetAsync("c:" .. code)
			end)
			local fresh = ok and type(v) == "table" and type(v.name) == "string" and os.time() - (tonumber(v.at) or 0) < 40
			local who = fresh and string.sub(v.name, 1, 20) or nil
			local coming = fresh and v.coming == true or nil
			if who ~= workspace:GetAttribute("FriendInLobby") and who and ctx.Remotes then
				for _, p in Players:GetPlayers() do
					ctx.Remotes.Notify:FireClient(p, who .. " is in the lobby and can join you right here. Wait for them.", "info")
				end
			end
			workspace:SetAttribute("FriendInLobby", who)
			workspace:SetAttribute("FriendComing", coming)
		else
			workspace:SetAttribute("FriendInLobby", nil)
			workspace:SetAttribute("FriendComing", nil)
			if friendListed then
				friendListed = false
				pcall(function()
					fm:RemoveAsync("f:" .. code)
				end)
			end
		end
	end
	local m = getMap()
	if not m or not code then
		return
	end
	local open, n = Match.isOpen()
	-- (on screen: "others can still join your night". v87 logs: alone in a group circle's night,
	-- 23 of 52 left within 45 s, while another group teleported within a minute half the time)
	workspace:SetAttribute("OpenNight", open and string.format("%d/%d", n, ctx.Config.MaxPlayers) or nil)
	-- (v113: alone and open, the HUD says how many are in the lobby right now, every ~16 s)
	if open and n == 1 and os.clock() - lobbyNowAt > 15 then
		lobbyNowAt = os.clock()
		workspace:SetAttribute("LobbyNow", lobbyNow())
	elseif not open or n > 1 then
		workspace:SetAttribute("LobbyNow", nil)
	end
	if open then
		-- (places a lobby just claimed stay taken until those players arrive)
		local onWay = 0
		listed = pcall(function()
			m:UpdateAsync(code, function(old)
				local nn = n
				local claimed = type(old) == "table" and tonumber(old.claimed) or nil
				if claimed and os.time() - claimed < 25 then
					nn = math.max(n, tonumber(old.n) or n)
				end
				onWay = nn - n
				return { n = nn, cap = ctx.Config.MaxPlayers, at = os.time(), claimed = claimed }
			end, TTL)
		end) or listed
		-- (v122: a lobby has sent someone here: the HUD says they're on their way)
		workspace:SetAttribute("OnTheirWay", onWay > 0 and onWay or nil)
	elseif listed then
		listed = false
		workspace:SetAttribute("OnTheirWay", nil)
		pcall(function()
			m:RemoveAsync(code)
		end)
	end
end

function Match.startGame()
	for _, p in Players:GetPlayers() do
		readJoin(p)
	end
	Players.PlayerAdded:Connect(readJoin)
	task.spawn(function()
		task.wait(2)
		while true do
			publish()
			task.wait(8)
		end
	end)
	game:BindToClose(function()
		if listed and map and code then
			pcall(function()
				map:RemoveAsync(code)
			end)
		end
		if friendListed and friendMap and code then
			pcall(function()
				friendMap:RemoveAsync("f:" .. code)
			end)
		end
	end)
end

-- (lobby) a group circle just sent fewer players than it holds to a fresh house: list it straight
-- away, so the next lone circle (here or in another lobby) joins them instead of starting alone.
-- The game server keeps the entry fresh once its players are in.
function Match.listNew(accessCode: string, count: number)
	local m = getMap()
	if not m or count >= ctx.Config.MaxPlayers then
		return
	end
	pcall(function()
		m:SetAsync(accessCode, { n = count, cap = ctx.Config.MaxPlayers, at = os.time(), claimed = os.time() }, TTL)
	end)
end

Match._publish = publish -- (tests)
Match._readJoin = readJoin -- (tests)
Match._set = function(c: string?, size: number?, started: number?) -- (tests)
	code, cap, party, listed = c, size, started, false
end

---------------------------------------------------------------------------
-- Lobby
---------------------------------------------------------------------------
-- (v113) this lobby's head count, every few seconds, for the lone nights' "N in the lobby"
function Match.startLobby()
	task.spawn(function()
		while true do
			local m = getPulse()
			if m then
				pcall(function()
					m:SetAsync(game.JobId ~= "" and game.JobId or "studio", { n = #Players:GetPlayers(), at = os.time() }, 25)
				end)
			end
			task.wait(8)
		end
	end)
end

-- a night with room for `count` more; claims the places (so two lobbies don't fill the same one
-- twice) and returns its access code, or nil
function Match.find(count: number): string?
	local m = getMap()
	if not m then
		return nil
	end
	local ok, items = pcall(function()
		return m:GetRangeAsync(Enum.SortDirection.Ascending, 50)
	end)
	if not ok or type(items) ~= "table" then
		return nil
	end
	-- the fullest night that still has room first (a group of three beats a pair)
	local best = {}
	for _, item in items do
		local v = item.value
		if type(v) == "table" and tonumber(v.n) and tonumber(v.cap) and v.n + count <= v.cap
			and os.time() - (tonumber(v.at) or 0) < TTL then
			table.insert(best, item)
		end
	end
	table.sort(best, function(a, b)
		return a.value.n > b.value.n
	end)
	for _, item in best do
		local claimed = false
		pcall(function()
			m:UpdateAsync(item.key, function(old)
				if type(old) == "table" and old.n + count <= old.cap then
					old.n += count
					old.claimed = os.time()
					claimed = true
					return old
				end
				claimed = false
				return nil
			end, TTL)
		end)
		if claimed then
			return item.key
		end
	end
	return nil
end

-- (v124, lobby) a house this player's Roblox friend is in, that can still take them: its code and
-- the friend's name, or nil. One read of the list every few seconds serves the whole lobby; each
-- friendship is asked once.
local friendCache: { [Player]: { [number]: boolean } } = {}
local rangeAt, rangeItems = -math.huge, {}
local function isFriend(p: Player, uid: number): boolean
	local c = friendCache[p]
	if not c then
		c = {}
		friendCache[p] = c
	end
	if c[uid] == nil then
		local ok, yes = pcall(function()
			return p:IsFriendsWith(uid)
		end)
		c[uid] = ok and yes == true
	end
	return c[uid]
end

function Match.friendHouse(p: Player): (string?, string?)
	local fm = getFriendMap()
	if not fm then
		return nil, nil
	end
	if os.clock() - rangeAt > 4 then
		rangeAt = os.clock()
		local ok, items = pcall(function()
			return fm:GetRangeAsync(Enum.SortDirection.Ascending, 100)
		end)
		rangeItems = (ok and type(items) == "table") and items or {}
	end
	for _, item in rangeItems do
		local v, key = item.value, item.key
		if type(key) == "string" and string.sub(key, 1, 2) == "f:" and type(v) == "table" and type(v.u) == "table"
			and os.time() - (tonumber(v.at) or 0) < TTL and (tonumber(v.n) or 0) < ctx.Config.MaxPlayers then
			for i, uid in v.u do
				if tonumber(uid) and uid ~= p.UserId and isFriend(p, uid) then
					local nm = type(v.nm) == "table" and type(v.nm[i]) == "string" and v.nm[i] or "Your friend"
					return string.sub(key, 3), nm
				end
			end
		end
	end
	return nil, nil
end

-- (v124, lobby) tell a house that a friend of someone in it is here (and whether they're on their way)
function Match.friendSeen(accessCode: string, name: string, coming: boolean?)
	local fm = getFriendMap()
	if not fm then
		return
	end
	pcall(function()
		fm:SetAsync("c:" .. accessCode, { name = name, at = os.time(), coming = coming or nil }, 40)
	end)
end

function Match.forget(p: Player)
	friendCache[p] = nil
end
Match._resetFriends = function() -- (tests)
	rangeAt, rangeItems, friendCache = -math.huge, {}, {}
end

-- (lobby) places claimed by a lookup that came back too late go back (LobbyServer.findWithin)
function Match.release(accessCode: string, count: number)
	local m = getMap()
	if not m then
		return
	end
	pcall(function()
		m:UpdateAsync(accessCode, function(old)
			if type(old) == "table" and tonumber(old.n) then
				old.n = math.max(0, old.n - count)
				return old
			end
			return nil
		end, TTL)
	end)
end

return Match
