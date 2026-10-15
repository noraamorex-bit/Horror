-- match_test: no lonely nights when someone else's has just started (MatchService).
-- Game side: a group night that started short lists itself (its access code, how many, room up to
-- MaxPlayers) through the first two acts until bedtime; PLAY SOLO and nights that started full never
-- do. Lobby side: find() takes the fullest night with room and claims the places, so the next lobby
-- can't overfill it; a claim made moments ago survives the game server's next refresh.
local H = require("./env")
local ok, err = pcall(function()
	-- an in-memory MemoryStore sorted map
	local store = {}
	local fakeMap = {
		SetAsync = function(_, k, v) store[k] = v end,
		RemoveAsync = function(_, k) store[k] = nil end,
		UpdateAsync = function(_, k, fn) local v = fn(store[k]); if v ~= nil then store[k] = v end; return v end,
		GetRangeAsync = function()
			local out = {}
			for k, v in store do table.insert(out, { key = k, value = v }) end
			table.sort(out, function(a, b) return a.key < b.key end)
			return out
		end,
	}
	H.services.MemoryStoreService = { GetSortedMap = function() return fakeMap end }

	local players = {}
	local act, elapsed, skipping, bedtime = "Evening", 20, false, false
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Util = { sessionPlayers = function() return players end }
	ctx.Director = {
		getAct = function() return act end, elapsedSeconds = function() return elapsed end, isSkipping = function() return skipping end,
		lateJoinOpen = function() return act == "Evening" or (act == "SmallThings" and not bedtime and not skipping) end,
	}
	local Match = H.load("Server/Services/MatchService")
	Match.init(ctx)
	assert(ctx.Match == Match, "on ctx")
	local MAX = ctx.Config.MaxPlayers

	-- a circle of 2 that started with one player: open up to the server's limit
	players = { "A" }
	Match._set("night-A", 2, 1)
	Match._publish()
	assert(store["night-A"] and store["night-A"].n == 1 and store["night-A"].cap == MAX, "listed with 1 of " .. MAX)
	assert(H.unwrap(H.workspaceRoot):GetAttribute("OpenNight") == "1/" .. MAX, "on screen: others can join (1/" .. MAX .. ")")
	-- a circle of 4 that started with two
	Match._set("night-B", 4, 2)
	players = { "B1", "B2" }
	Match._publish()
	assert(store["night-B"] and store["night-B"].n == 2, "listed with 2")

	-- the lobby: a lone player gets the fuller night first
	local code = Match.find(1)
	assert(code == "night-B", "fullest night with room first, got " .. tostring(code))
	assert(store["night-B"].n == 3 and store["night-B"].claimed, "the place is claimed")
	-- a full pair from a circle of 2 doesn't fit B (3 + 2 > 4) but does fit the lone night A
	assert(Match.find(2) == "night-A", "a pair joins the lone player")
	assert(store["night-A"].n == 3, "A now has 3")
	-- the claim holds through B's next refresh, before the new player arrives
	Match._set("night-B", 4, 2)
	players = { "B1", "B2" }
	Match._publish()
	assert(store["night-B"].n == 3, "a fresh claim isn't overwritten by the old count, got " .. store["night-B"].n)
	-- the next lone players: the last place in each, then nothing
	local x, y = Match.find(1), Match.find(1)
	assert(x and y and x ~= y and (x == "night-A" or x == "night-B") and (y == "night-A" or y == "night-B"), "the last place in each")
	assert(Match.find(1) == nil, "nothing left")
	assert(Match.find(MAX) == nil, "never more than the server holds")
	print("find + claim ok")

	-- open through act II until bedtime; closed after it, past the time limit, on a skipped night
	Match._set("night-C", 2, 1)
	players = { "C" }
	act = "SmallThings"
	elapsed = 300
	Match._publish()
	assert(store["night-C"], "still open in act II (lock up, the news)")
	bedtime = true
	Match._publish()
	assert(store["night-C"] == nil, "closed once it's bedtime (the blackout is near)")
	assert(H.unwrap(H.workspaceRoot):GetAttribute("OpenNight") == nil, "and the line goes")
	bedtime = false
	Match._publish()
	assert(store["night-C"], "open again")
	elapsed = ctx.Config.Lobby.JoinOpenFor + 1
	Match._publish()
	assert(store["night-C"] == nil, "too late into the night")
	elapsed = 20
	act = "SomeoneElse"
	Match._publish()
	assert(store["night-C"] == nil, "never after the blackout")
	act = "Evening"
	skipping = true
	Match._publish()
	assert(store["night-C"] == nil, "a veterans' night that skips to the blackout")
	skipping = false
	players = { "C", "D", "E", "F" }
	Match._publish()
	assert(store["night-C"] == nil, "full (" .. MAX .. " of " .. MAX .. ")")
	-- a pair that started together in a circle of 2 is never offered, even if one of them leaves
	Match._set("night-P", 2, 2)
	players = { "P1", "P2" }
	Match._publish()
	assert(store["night-P"] == nil, "a full circle's night is theirs")
	players = { "P1" }
	Match._publish()
	assert(store["night-P"] == nil, "still theirs after one leaves")
	Match._set("night-solo", 1, 1)
	players = { "S" }
	Match._publish()
	assert(store["night-solo"] == nil, "PLAY SOLO nights are never offered")
	-- before the night starts (players still arriving, the difficulty vote): open too, counting
	-- everyone on the server (nobody is in the night yet)
	act, elapsed = "Lobby", 0
	players = {}
	H.services.Players.GetPlayers = function() return { "W" } end
	Match._set("night-W", 2, 1)
	Match._publish()
	assert(store["night-W"] and store["night-W"].n == 1, "listed while its players arrive")
	Match._set("night-WF", 2, 2)
	Match._publish()
	assert(store["night-WF"] == nil, "a full circle's night still isn't")
	act, elapsed = "Evening", 20
	-- the lobby lists a short group's fresh house the moment it sends them
	Match.listNew("night-L", 1)
	assert(store["night-L"] and store["night-L"].n == 1 and store["night-L"].cap == MAX and store["night-L"].claimed, "listed at once by the lobby")
	Match.listNew("night-LF", MAX)
	assert(store["night-LF"] == nil, "never a full one")
	Match._set(nil, nil)
	Match._publish()
	print("closed cases ok")
end)
print(ok and "MATCH OK" or ("MATCH FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
