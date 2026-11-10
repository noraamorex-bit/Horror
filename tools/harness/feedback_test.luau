-- feedback_test (v150): our own 📝 box. What a player writes is filtered by Roblox and kept in Feedback_v1 under
-- the day's key (tools/pull_feedback.py reads it); nothing unfiltered is ever kept; too short, too soon or
-- too many in a day are refused; what's too long is cut.
local H = require("./env")
local roblox = H.roblox
local T = 5000
H.clock = function() return T end
local ok, err = pcall(function()
	local saved = {}
	local filterOk = true
	H.services.DataStoreService = { GetDataStore = function(_, name)
		assert(name == "Feedback_v1", "the store: " .. tostring(name))
		return { UpdateAsync = function(_, key, fn)
			local v = fn(saved[key])
			if v ~= nil then saved[key] = v end
			return v
		end }
	end }
	H.services.TextService = { FilterStringAsync = function(_, text, uid)
		if not filterOk then error("filter down") end
		return { GetNonChatStringForBroadcastAsync = function() return (string.gsub(text, "%d%d%d%d+", "####")) end }
	end }
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Mode = { get = function() return "Game" end }
	local fired = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { FireClient = function(_, p, a, b) table.insert(fired, { k, p, a, b }) end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	local events = {}
	ctx.Journey = { event = function(p, code, x) table.insert(events, { code, x }) end, lobbyMark = function() end }
	local F = H.load("Server/Services/FeedbackService")
	F.init(ctx)
	F.start()
	assert(ctx.Feedback == F, "on ctx")
	local p = H.wrap(roblox.Instance.new("Player"))
	rawset(p, "UserId", 4242)
	p:SetAttribute("StatNights", 3)
	H.unwrap(H.workspaceRoot):SetAttribute("Act", "Guest")
	local function send(text, where)
		ctx.Remotes.SendFeedback.OnServerEvent:Fire(p, text, where)
		local last = fired[#fired]
		assert(last[1] == "FeedbackResult" and last[2] == p, "an answer comes back")
		return last[3], last[4]
	end
	local function all()
		local out = {}
		for _, list in saved do for _, e in list do table.insert(out, e) end end
		return out
	end
	-- too short: refused, nothing kept
	local good, msg = send("  ", "Card")
	assert(not good and #all() == 0, "too short: " .. tostring(msg))
	-- a real one: filtered, kept under today's key with who / where / nights / act
	good, msg = send("  the monster is too fast, my number is 5551234  ", "Card")
	assert(good, "sent: " .. tostring(msg))
	local list = all()
	assert(#list == 1, "kept")
	local e = list[1]
	assert(e.txt == "the monster is too fast, my number is ####", "filtered and trimmed: " .. tostring(e.txt))
	assert(e.u == 4242 and e.w == "Card" and e.n == 3 and e.a == "Guest", "who, where, nights, act")
	assert(saved[F.dayKey(e.t)] and string.match(F.dayKey(e.t), "^d:%d%d%d%d%-%d%d%-%d%d$"), "under the day's key: " .. F.dayKey(e.t))
	assert(events[#events][1] == "FeedbackSent" and events[#events][2] == "Card", "in the night log")
	-- straight away again: too soon
	good, msg = send("another thing", "Card")
	assert(not good and #all() == 1, "too soon: " .. tostring(msg))
	-- (the gap runs on the real clock: from here on, no gap)
	F.Gap = 0
	-- the filter is down: nothing is kept, unfiltered or otherwise
	filterOk = false
	good, msg = send("this should not be stored raw", "Lobby")
	assert(not good and #all() == 1, "filter down: not kept: " .. tostring(msg))
	filterOk = true
	-- too long: cut to MaxLen; an unknown "where" is Other
	good = send(string.rep("a", F.MaxLen + 200), "Somewhere")
	list = all()
	assert(good and #list == 2 and #list[2].txt == F.MaxLen and list[2].w == "Other", "cut to " .. F.MaxLen)
	-- a day's limit
	for _ = 1, F.PerDay do
		T += F.Gap + 1
		send("more feedback here", "Lobby")
	end
	assert(#all() == F.PerDay, "at most " .. F.PerDay .. " a day: " .. #all())
	-- not text at all
	T += F.Gap + 1
	good = send({ "nope" }, "Card")
	assert(not good, "not text: refused")
	print("feedback ok")
end)
print(ok and "FEEDBACK OK" or ("FEEDBACK FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
