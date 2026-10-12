--[[
	MatchService — no lonely nights when someone else's has just started.

	The logs: a night alone was abandoned 12 times out of 13, a night of three or four almost never,
	and with few people online a group circle often started with one player after waiting 45 s
	(and 28% of the players who queued left during that wait).

	• Game server (a group circle's reserved server): while its night is in the cozy first part
	  (Config.Lobby.JoinOpenFor seconds) and it has fewer players than the circle was for, it lists
	  itself in a MemoryStore sorted map (key = its access code, which arrived with the players'
	  teleport data). PLAY SOLO nights (circle of 1) and full circles are never listed.
	• Lobby: a group circle that's waiting for players looks for such a night every few seconds and,
	  if there's room, sends its players there instead (the game server already lets late arrivals
	  into the first act: "You made it just in time").
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
	local open = D.getAct() == "Evening" and D.elapsedSeconds() < (L.JoinOpenFor or 150) and not (D.isSkipping and D.isSkipping())
		and n >= 1 and n < math.min(cap, ctx.Config.MaxPlayers)
	return open, n
end

local function publish()
	local m = getMap()
	if not m or not code then
		return
	end
	local open, n = Match.isOpen()
	if open then
		-- (places a lobby just claimed stay taken until those players arrive)
		listed = pcall(function()
			m:UpdateAsync(code, function(old)
				local nn = n
				local claimed = type(old) == "table" and tonumber(old.claimed) or nil
				if claimed and os.time() - claimed < 25 then
					nn = math.max(n, tonumber(old.n) or n)
				end
				return { n = nn, cap = cap, at = os.time(), claimed = claimed }
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
		while true do
			task.wait(8)
			publish()
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

Match._publish = publish -- (tests)
Match._set = function(c: string?, size: number?) -- (tests)
	code, cap, listed = c, size, false
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
