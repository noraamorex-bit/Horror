-- match_test: no lonely nights when someone else's has just started (MatchService).
-- Game side: a group night that started short lists itself (its access code, how many, the circle's
-- size) during the cozy first part only; solo circles and full nights never do. Lobby side: find()
-- takes the fullest night with room and claims the places, so the next lobby can't overfill it; a
-- claim made moments ago survives the game server's next refresh.
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
	local act, elapsed, skipping = "Evening", 20, false
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Util = { sessionPlayers = function() return players end }
	ctx.Director = { getAct = function() return act end, elapsedSeconds = function() return elapsed end, isSkipping = function() return skipping end }
	local Match = H.load("Server/Services/MatchService")
	Match.init(ctx)
	assert(ctx.Match == Match, "on ctx")

	-- a circle of 2 that started with one player
	players = { "A" }
	Match._set("night-A", 2)
	Match._publish()
	assert(store["night-A"] and store["night-A"].n == 1 and store["night-A"].cap == 2, "listed with 1 of 2")
	-- a circle of 4 that started with two
	Match._set("night-B", 4)
	players = { "B1", "B2" }
	Match._publish()
	assert(store["night-B"] and store["night-B"].n == 2, "listed with 2 of 4")

	-- the lobby: a lone player gets the fuller night first
	local code = Match.find(1)
	assert(code == "night-B", "fullest night with room first, got " .. tostring(code))
	assert(store["night-B"].n == 3 and store["night-B"].claimed, "the place is claimed")
	-- a group of two doesn't fit B (3 + 2 > 4) or A (1 + 2 > 2)
	assert(Match.find(2) == nil, "no room for two")
	-- the claim holds through B's next refresh, before the new player arrives
	Match._publish()
	assert(store["night-B"].n == 3, "a fresh claim isn't overwritten by the old count, got " .. store["night-B"].n)
	-- the next lone player: B has one place left, then A
	assert(Match.find(1) == "night-B", "B's last place")
	assert(Match.find(1) == "night-A", "then A")
	assert(Match.find(1) == nil, "nothing left")
	print("find + claim ok")

	-- closed: after the cozy part, after the first act, on a skipped night, when full, for PLAY SOLO
	Match._set("night-C", 2)
	players = { "C" }
	elapsed = ctx.Config.Lobby.JoinOpenFor + 1
	Match._publish()
	assert(store["night-C"] == nil, "too late into the evening")
	elapsed = 20
	Match._publish()
	assert(store["night-C"], "open")
	act = "SmallThings"
	Match._publish()
	assert(store["night-C"] == nil, "taken off the list once the first act is over")
	act = "Evening"
	skipping = true
	Match._publish()
	assert(store["night-C"] == nil, "a veterans' night that skips to the blackout")
	skipping = false
	players = { "C", "D" }
	Match._publish()
	assert(store["night-C"] == nil, "full (2 of 2)")
	Match._set("night-solo", 1)
	players = { "S" }
	Match._publish()
	assert(store["night-solo"] == nil, "PLAY SOLO nights are never offered")
	Match._set(nil, nil)
	Match._publish()
	print("closed cases ok")
end)
print(ok and "MATCH OK" or ("MATCH FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
