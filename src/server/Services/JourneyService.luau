--[[
	JourneyService — our own detailed log of every night and every lobby visit, saved in DataStores
	the owner's read-only Open Cloud key can read (tools/pull_stats.py). Creator Hub's charts are
	slow and coarse; this says exactly where each player was, and what had happened to them, when
	they left. Everything is best-effort: a failed write never touches the game.

	NightLog_v1  key "<yyyymmdd>-<server>-<n>": one night in a game server
		{ V, Ver (place version), Day, Start (unix), Diff, Size, Acts = { {t, name} }, Obj = { {t, "Task:Step"} },
		  End = { t, kind } | nil,
		  P = { ["<userId>"] = { New, Nights, Dev, Role, Arr (s before the night started), Ev = { {t, code, x} },
		        Hides, Seen, Out = { t, act, why, cap, dead, esc, hid, him, dist, nerve } | nil, Perf } } }
		t = seconds since the night started (negative: before it started).
	LobbyLog_v1  key "<yyyymmdd>-<server>-<n>": lobby visits that ended since the last write
		{ { U, New, Nights, Ref, Dev, Join (unix), Secs, Queued (s to first queue), Q (circle), Tp, Perf } }

	Devices and performance come from the client (Remotes.ClientInfo, client Diagnostics) every
	15 s: Phone / Tablet / PC / Console, memory (MB), frame rate, graphics quality.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Journey = {}
local ctx
local nightStore: any = nil
local lobbyStore: any = nil
local isLobby = false

local night: any = nil -- the night being logged (game servers)
local nightN = 0
local perf: { [Player]: any } = {}
local lobby: { [Player]: any } = {}
local lobbyDone: { any } = {}
local lobbyN = 0

local MAX_EVENTS = 60

local function serverId(): string
	local id = game.JobId
	return (id ~= nil and id ~= "") and string.sub(id, 1, 8) or "local"
end

local function day(): string
	return os.date("!%Y%m%d") :: string
end

local function round(x: number?): number?
	return x and math.floor(x * 10 + 0.5) / 10 or nil
end

local function write(store: any, key: string, value: any)
	if not store then
		return
	end
	task.spawn(function()
		for attempt = 1, 3 do
			local ok = pcall(function()
				store:SetAsync(key, value)
			end)
			if ok then
				return
			end
			task.wait(2 * attempt)
		end
	end)
end

local function perfOf(p: Player): any
	local s = perf[p]
	if not s then
		return nil
	end
	return {
		Dev = s.Dev,
		Q = s.Q,
		MemMax = s.MemMax and math.floor(s.MemMax) or nil,
		FpsMin = round(s.FpsMin),
		FpsAvg = s.N > 0 and round(s.FpsSum / s.N) or nil,
		Last = s.Last and { Mem = math.floor(s.Last.Mem or 0), Fps = round(s.Last.Fps), Ago = math.floor(os.clock() - s.Last.At) } or nil,
	}
end

local function isNew(p: Player): boolean
	return (tonumber(p:GetAttribute("StatNights")) or 0) == 0
end

---------------------------------------------------------------------------
-- Nights (game servers)
---------------------------------------------------------------------------
local function since(): number
	if not night then
		return 0
	end
	return math.floor((os.clock() - (night.Clock or os.clock())) * 10 + 0.5) / 10
end

local function ensureNight()
	if night then
		return night
	end
	nightN += 1
	night = {
		Key = string.format("%s-%s-%d", day(), serverId(), nightN),
		Clock = os.clock(), -- (moved to the real start when the night starts)
		Started = false,
		Data = { V = 1, Ver = game.PlaceVersion, Day = day(), Start = os.time(), Acts = {}, Obj = {}, P = {} },
	}
	return night
end

local function entry(p: Player): any
	local n = ensureNight()
	local k = tostring(p.UserId)
	local e = n.Data.P[k]
	if not e then
		e = { New = isNew(p), Nights = tonumber(p:GetAttribute("StatNights")) or 0, Ev = {}, Hides = 0, Seen = 0 }
		n.Data.P[k] = e
		e.ArrClock = os.clock()
	end
	return e
end

-- a player's moment ("Cap", "Free", "Dead", "Esc", "Help", "Revive", "Result", "Again", "Lobby"...)
function Journey.event(p: Player, code: string, x: any?)
	if isLobby or not p or not night or not night.Started then
		return
	end
	local e = entry(p)
	if #e.Ev < MAX_EVENTS then
		table.insert(e.Ev, x ~= nil and { since(), code, x } or { since(), code })
	end
end

-- counted, not listed
function Journey.count(p: Player, what: string)
	if isLobby or not p or not night or not night.Started then
		return
	end
	local e = entry(p)
	e[what] = (e[what] or 0) + 1
end

-- the group's progress: an objective step or task done
function Journey.team(code: string)
	if isLobby or not night then
		return
	end
	local list = night.Data.Obj
	if #list < 80 then
		table.insert(list, { since(), code })
	end
end

function Journey.nightStart(players: { Player })
	if isLobby then
		return
	end
	if night and night.Started then
		Journey.flush("next")
	end
	local n = ensureNight()
	n.Started = true
	n.Clock = os.clock()
	n.Data.Start = os.time()
	n.Data.Diff = workspace:GetAttribute("Difficulty")
	n.Data.Size = #players
	for _, p in players do
		local e = entry(p)
		e.Role = p:GetAttribute("Role")
		e.New = isNew(p)
		e.Nights = tonumber(p:GetAttribute("StatNights")) or 0
		e.Arr = e.ArrClock and math.floor(e.ArrClock - n.Clock) or 0
		e.In = true
	end
end

function Journey.act(name: string)
	if isLobby or not night or not night.Started then
		return
	end
	table.insert(night.Data.Acts, { since(), name })
end

function Journey.ending(kind: string)
	if isLobby or not night or not night.Started then
		return
	end
	night.Data.End = { since(), kind }
end

-- someone left the server: where were they, and what was going on?
local function playerOut(p: Player, why: string)
	if not night then
		return
	end
	local e = night.Data.P[tostring(p.UserId)]
	if not e or e.Out then
		return
	end
	local out: any = { t = since(), why = why, act = workspace:GetAttribute("Act") }
	if night.Data.End then
		out.after = true -- (the night was already over: leaving from the result card)
	end
	out.cap = p:GetAttribute("Captured") == true or nil
	out.dead = p:GetAttribute("Dead") == true or nil
	out.esc = p:GetAttribute("Escaped")
	out.hid = p:GetAttribute("Hiding") ~= nil and p:GetAttribute("Hiding") ~= false or nil
	local nerve = tonumber(p:GetAttribute("Nerve"))
	out.nerve = nerve and math.floor(nerve) or nil
	local I = ctx.Intruder
	if I and I.getState then
		local okS, st = pcall(I.getState)
		out.him = okS and st or nil
		local okP, ip = pcall(I.position)
		local root = ctx.Util and ctx.Util.getRoot(p)
		if okP and ip and root then
			out.dist = math.floor((ip - root.Position).Magnitude)
		end
	end
	e.Out = out
	e.Perf = perfOf(p)
end

-- write the night (once). Called when the house restarts, the next night starts, or the server closes.
function Journey.flush(why: string?)
	if isLobby or not night then
		return
	end
	local n = night
	night = nil
	if not n.Started then
		-- nobody ever got a night started here (they left while arriving or voting): still worth knowing
		local any = false
		for _ in n.Data.P do
			any = true
		end
		if not any then
			return
		end
		n.Data.NoStart = true
	end
	for _, p in Players:GetPlayers() do
		local e = n.Data.P[tostring(p.UserId)]
		if e then
			e.Perf = e.Perf or perfOf(p)
			e.Stay = true -- (still here when the night was written)
		end
	end
	for _, e in n.Data.P do
		e.ArrClock = nil
	end
	n.Data.Why = why
	n.Data.Len = math.floor(os.clock() - n.Clock)
	write(nightStore, n.Key, n.Data)
end

---------------------------------------------------------------------------
-- The lobby
---------------------------------------------------------------------------
function Journey.lobbyJoin(p: Player)
	if not isLobby then
		return
	end
	lobby[p] = { Clock = os.clock(), Join = os.time() }
end

function Journey.lobbyQueued(p: Player, size: number)
	local s = lobby[p]
	if s and not s.Queued then
		s.Queued = math.floor(os.clock() - s.Clock)
		s.Q = size
	end
end

function Journey.lobbyTeleport(p: Player, joined: boolean?)
	local s = lobby[p]
	if s then
		s.Tp = math.floor(os.clock() - s.Clock)
		s.Late = joined or nil -- (into a night already under way: MatchService)
	end
end

local function lobbyLeave(p: Player)
	local s = lobby[p]
	lobby[p] = nil
	if not s then
		return
	end
	table.insert(lobbyDone, {
		U = p.UserId,
		Ver = game.PlaceVersion,
		New = p:GetAttribute("FirstVisit") == true or nil,
		Nights = tonumber(p:GetAttribute("StatNights")) or 0,
		Lv = tonumber(p:GetAttribute("Level")),
		Ref = p:GetAttribute("StatReferred") == true or nil,
		Join = s.Join,
		Late = s.Late,
		Secs = math.floor(os.clock() - s.Clock),
		Queued = s.Queued,
		Q = s.Q,
		Tp = s.Tp,
		Perf = perfOf(p),
	})
end

local function flushLobby()
	if #lobbyDone == 0 then
		return
	end
	lobbyN += 1
	local batch = lobbyDone
	lobbyDone = {}
	write(lobbyStore, string.format("%s-%s-%d", day(), serverId(), lobbyN), batch)
end
Journey._flushLobby = flushLobby -- (tests)

---------------------------------------------------------------------------
function Journey.init(c)
	ctx = c
	ctx.Journey = Journey
	isLobby = ctx.Mode and ctx.Mode.get and ctx.Mode.get() == "Lobby" or false
	if RunService:IsStudio() then
		return
	end
	local ok, a = pcall(function()
		return DataStoreService:GetDataStore("NightLog_v1")
	end)
	nightStore = ok and a or nil
	local ok2, b = pcall(function()
		return DataStoreService:GetDataStore("LobbyLog_v1")
	end)
	lobbyStore = ok2 and b or nil
end

function Journey.start()
	ctx.Remotes.ClientInfo.OnServerEvent:Connect(function(p, info)
		if type(info) ~= "table" then
			return
		end
		local s = perf[p]
		if not s then
			s = { N = 0, FpsSum = 0 }
			perf[p] = s
		end
		if s.LastAt and os.clock() - s.LastAt < 5 then
			return -- (rate limit)
		end
		s.LastAt = os.clock()
		local dev = info.Dev
		if dev == "Phone" or dev == "Tablet" or dev == "PC" or dev == "Console" then
			s.Dev = dev
		end
		local mem, fps, q = tonumber(info.Mem), tonumber(info.Fps), tonumber(info.Q)
		if mem and mem == mem and mem > 0 and mem < 100000 then
			s.MemMax = math.max(s.MemMax or 0, mem)
		end
		if fps and fps == fps and fps >= 0 and fps < 1000 then
			s.FpsMin = math.min(s.FpsMin or math.huge, fps)
			s.FpsSum += fps
			s.N += 1
		end
		if q and q == q then
			s.Q = math.floor(q)
		end
		s.Last = { Mem = mem, Fps = fps, At = os.clock() }
	end)
	if isLobby then
		for _, p in Players:GetPlayers() do
			Journey.lobbyJoin(p)
		end
		Players.PlayerAdded:Connect(Journey.lobbyJoin)
		Players.PlayerRemoving:Connect(function(p)
			lobbyLeave(p)
			perf[p] = nil
		end)
		task.spawn(function()
			while true do
				task.wait(120)
				flushLobby()
			end
		end)
		pcall(function()
			game:BindToClose(function()
				for _, p in Players:GetPlayers() do
					lobbyLeave(p)
				end
				flushLobby()
				task.wait(2)
			end)
		end)
	else
		local function arrived(p: Player)
			-- (in the log from the moment they arrive: some leave before a night ever starts)
			entry(p)
		end
		for _, p in Players:GetPlayers() do
			arrived(p)
		end
		Players.PlayerAdded:Connect(arrived)
		Players.PlayerRemoving:Connect(function(p)
			playerOut(p, "left")
			perf[p] = nil
		end)
		pcall(function()
			game:BindToClose(function()
				for _, p in Players:GetPlayers() do
					playerOut(p, "shutdown")
				end
				Journey.flush("close")
				task.wait(2)
			end)
		end)
	end
end

return Journey
