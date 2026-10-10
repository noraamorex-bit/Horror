-- journey_test: our own night / lobby logs (JourneyService). A stand-in DataStore records every
-- write: a night with its acts, objectives, each player's moments, where a quitter was when they
-- left (captured, his distance...), device and frame rate from the client; and lobby visits.
local H = require("./env")
local R = H.roblox
local ok, err = pcall(function()
	local writes = {}
	local function store(name)
		return { SetAsync = function(_, key, value) table.insert(writes, { Store = name, Key = key, Value = value }) end }
	end
	H.services.DataStoreService = { GetDataStore = function(_, name) return store(name) end }
	H.services.RunService.IsStudio = function() return false end
	local players = {}
	H.services.Players.GetPlayers = function() return players end
	local function mk(id, nights)
		local p = H.wrap(R.Instance.new("Player"))
		rawset(p, "UserId", id)
		rawset(p, "Parent", H.workspaceRoot)
		p:SetAttribute("StatNights", nights)
		table.insert(players, p)
		return p
	end
	local function remotes()
		return setmetatable({}, { __index = function(t, k)
			local r = { OnServerEvent = H.signal(), FireClient = function() end, FireAllClients = function() end }
			rawset(t, k, r)
			return r
		end })
	end

	-- a game server ---------------------------------------------------------
	local mode = "Game"
	local ctx: any = { Remotes = remotes(), Mode = { get = function() return mode end }, Util = { getRoot = function() return nil end } }
	ctx.Intruder = { getState = function() return "Chase" end, position = function() return R.Vector3.new(0, 0, 0) end }
	local J = H.load("Server/Services/JourneyService")
	J.init(ctx)
	J.start()
	local a, b = mk(11, 0), mk(12, 3)
	H.services.Players.PlayerAdded:Fire(a)
	H.services.Players.PlayerAdded:Fire(b)
	ctx.Remotes.ClientInfo.OnServerEvent:Fire(a, { Dev = "Phone", Mem = 812.4, Fps = 41.2, Q = 3 })
	ctx.Remotes.ClientInfo.OnServerEvent:Fire(a, { Dev = "Hacker", Mem = 900, Fps = 2 }) -- (rate limited: ignored)
	J.event(a, "Cap") -- (before the night: not logged)
	J.nightStart({ a, b })
	J.act("Evening"); J.act("SomeoneElse")
	J.team("Phone:Box")
	J.count(a, "Hides"); J.count(a, "Hides"); J.count(b, "Seen")
	J.event(a, "Cap", "Kitchen")
	a:SetAttribute("Captured", true)
	-- a leaves while tied up
	table.remove(players, 1)
	H.services.Players.PlayerRemoving:Fire(a)
	J.ending("Sirens")
	J.event(b, "Again")
	J.flush("restart")
	assert(#writes == 1 and writes[1].Store == "NightLog_v1", "one night written")
	local n = writes[1].Value
	assert(#n.Acts == 2 and n.Acts[2][2] == "SomeoneElse", "acts")
	assert(n.Obj[1][2] == "Phone:Box", "objective steps")
	assert(n.End[2] == "Sirens" and n.Size == 2, "ending and size")
	local ea, eb = n.P["11"], n.P["12"]
	assert(ea and eb, "both players")
	assert(ea.New == true and eb.New == false and eb.Nights == 3, "first-nighter flagged")
	assert(ea.Hides == 2 and eb.Seen == 1, "counts")
	assert(#ea.Ev == 1 and ea.Ev[1][2] == "Cap" and ea.Ev[1][3] == "Kitchen", "the capture (not the one before the night)")
	assert(ea.Out and ea.Out.cap == true and ea.Out.act == nil or ea.Out.cap == true, "left while captured")
	assert(ea.Out.him == "Chase", "his state when they left")
	assert(ea.Perf and ea.Perf.Dev == "Phone" and ea.Perf.MemMax == 812 and ea.Perf.FpsMin == 41.2 and ea.Perf.Q == 3, "device and frame rate")
	assert(eb.Out == nil and eb.Stay == true and eb.Ev[1][2] == "Again", "still here, asked for another night")
	-- the next night in the same server is a new record
	J.nightStart({ b })
	J.flush("close")
	assert(#writes == 2 and writes[2].Key ~= writes[1].Key and writes[2].Value.P["12"], "second night, new key")
	-- nobody started a night: still logged (NoStart)
	local c = mk(13, 0)
	H.services.Players.PlayerAdded:Fire(c)
	J.flush("close")
	assert(#writes == 3 and writes[3].Value.NoStart == true, "left before any night started")

	-- a lobby server --------------------------------------------------------
	mode = "Lobby"
	players = {}
	local ctx2: any = { Remotes = remotes(), Mode = { get = function() return mode end } }
	-- (the same module, set up as a lobby server)
	J.init(ctx2)
	local L = J
	L.start()
	local d = mk(21, 0)
	d:SetAttribute("FirstVisit", true)
	L.lobbyJoin(d)
	L.lobbyQueued(d, 1)
	L.lobbyQueued(d, 4) -- (only the first queue counts)
	L.lobbyTeleport(d)
	H.services.Players.PlayerRemoving:Fire(d)
	L._flushLobby()
	local last = writes[#writes]
	assert(last.Store == "LobbyLog_v1" and #last.Value == 1, "a lobby visit written")
	local v = last.Value[1]
	assert(v.U == 21 and v.New == true and v.Queued == 0 and v.Q == 1 and v.Tp == 0, "queued and teleported")
	print(("journey ok: %d writes"):format(#writes))
end)
print(ok and "JOURNEY OK" or ("JOURNEY FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
