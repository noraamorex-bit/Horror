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
		end
		if tonumber(td.Cap) and not cap then
			cap = tonumber(td.Cap)
		end
		if tonumber(td.PartySize) and not party then
			party = tonumber(td.PartySize)
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
		and n >= 1 and n < ctx.Config.MaxPlayers
	return open, n
end

local function publish()
	local m = getMap()
	if not m or not code then
		return
	end
	local open, n = Match.isOpen()
	-- (on screen: "others can still join your night". v87 logs: alone in a group circle's night,
	-- 23 of 52 left within 45 s, while another group teleported within a minute half the time)
	workspace:SetAttribute("OpenNight", open and string.format("%d/%d", n, ctx.Config.MaxPlayers) or nil)
	if open then
		-- (places a lobby just claimed stay taken until those players arrive)
		listed = pcall(function()
			m:UpdateAsync(code, function(old)
				local nn = n
				local claimed = type(old) == "table" and tonumber(old.claimed) or nil
				if claimed and os.time() - claimed < 25 then
					nn = math.max(n, tonumber(old.n) or n)
				end
				return { n = nn, cap = ctx.Config.MaxPlayers, at = os.time(), claimed = claimed }
			end, TTL)
		end) or listed
	elseif listed then
		listed = false
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
Match._set = function(c: string?, size: number?, started: number?) -- (tests)
	code, cap, party, listed = c, size, started, false
end

---------------------------------------------------------------------------
-- Lobby
---------------------------------------------------------------------------
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

return Match
