local H = require("./env")
local roblox = H.roblox
local ok, err = pcall(function()
	local S = H.services
	local teleports = {}
	S.TeleportService = {
		ReserveServer = function(_, placeId) return "code-" .. placeId end,
		TeleportAsync = function(_, placeId, players, opts) table.insert(teleports, { placeId, #players }) end,
		TeleportInitFailed = H.signal(),
	}
	S.RunService.IsStudio = function() return false end
	S.Lighting = H.wrap(roblox.Instance.new("Lighting"))
	local players = {}
	local function makePlayer(name)
		local p = H.wrap(roblox.Instance.new("Player"))
		p.Name = name
		local char = H.Instance.new("Model")
		local root = H.Instance.new("Part", char)
		root.Name = "HumanoidRootPart"
		rawset(p, "Character", char) -- lune Player has no Character; shadow it on the proxy
		rawset(p, "Parent", H.workspaceRoot) -- (in the game: still connected)
		table.insert(players, p)
		return p, root
	end
	S.Players.GetPlayers = function() return players end
	S.RunService.IsStudio = function() return false end -- (a live server: teleports really go)
	local lastOptions = nil
	local realNew = H.Instance.new
	H.Instance.new = function(className, parent)
		if className == "TeleportOptions" then
			local o = {}
			o.SetTeleportData = function(_, data) o.Data = data end
			lastOptions = o
			return o
		end
		return realNew(className, parent)
	end
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Util = H.load("RS/Shared/Util")
	ctx.Builder = H.load("Server/World/Builder")
	ctx.Mode = { gamePlaceId = function() return 123 end }
	local fired = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { FireClient = function(_, p, payload) table.insert(fired, k .. ":" .. (type(payload) == "string" and payload or payload and (payload.Status .. " " .. payload.Count .. "/" .. payload.Size) or "nil")) end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	local Lobby = H.load("Server/Lobby/LobbyServer")
	Lobby.run(ctx)
	local lobby = H.unwrap(H.workspaceRoot):FindFirstChild("Lobby")
	local n = 0
	for _, d in lobby:GetDescendants() do if d:IsA("BasePart") then n += 1 end end
	print("lobby parts", n)
	-- (v99) him, across the street under the far streetlamp, posed by the clients like the real one
	local watcher = lobby:FindFirstChild("Watcher")
	assert(watcher and watcher:GetAttribute("Gait") == "Stare", "the watcher across the street")
	local wroot = watcher:FindFirstChild("HumanoidRootPart")
	assert(wroot.Anchored and not wroot.CanCollide and wroot.CFrame.Position.Z > 400 + 46, "on the far sidewalk, out of the way: " .. tostring(wroot.Anchored) .. " " .. tostring(wroot.CanCollide) .. " " .. tostring(wroot.CFrame.Position))
	for _, d in watcher:GetDescendants() do
		if d:IsA("BasePart") then assert(not d.CanCollide, "nothing on him collides") end
	end
	-- (v123) the feedback mailbox on the lawn, across the walk from the donation board
	local fbox = lobby:FindFirstChild("FeedbackBox", true)
	local fprompt = fbox and fbox:FindFirstChild("FeedbackPrompt", true)
	assert(fprompt and fprompt.ActionText == "Send message" and fprompt.HoldDuration == 0, "a feedback mailbox with its prompt")
	local fsign = fbox:FindFirstChild("FeedbackSign", true)
	assert(fsign and string.find(fsign:FindFirstChildWhichIsA("TextLabel").Text, "FEEDBACK"), "and its sign")
	local fpos = fbox:FindFirstChild("MailBody").CFrame.Position
	local spawnPos = lobby:FindFirstChild("LobbySpawn").CFrame.Position
	local d = (fpos - spawnPos).Magnitude
	assert(d > 8 and d < 24 and fpos.Z > spawnPos.Z - 10, "near where you spawn, off the walk, not by the circles: " .. tostring(d))
	-- every circle counts down from Countdown the moment someone steps in; full, it drops to FullCountdown
	local L = ctx.Config.Lobby
	assert(L.Countdown == 10 and L.FullCountdown == 3, "10 s, 3 s when full")
	local function waitFor(sec) local t = os.clock(); while os.clock() - t < sec do end end
	-- (the last queue state sent to anyone on a circle; players off the circles get nil)
	local function lastQueue()
		for i = #fired, 1, -1 do
			if fired[i] ~= "Queue:nil" then return fired[i] end
		end
		return nil
	end
	local pad2 = lobby:FindFirstChild("Pad2")
	local a, ra = makePlayer("A")
	local b, rb = makePlayer("B")
	ra.CFrame = roblox.CFrame.new(pad2.CFrame.Position + roblox.Vector3.new(0, 3, 0))
	local hb = S.RunService.Heartbeat
	hb:Fire(0.3)
	assert(lastQueue() == "Queue:Starting 1/2", "one player: the countdown starts at once, got " .. tostring(lastQueue()))
	-- B steps in: full, so it drops to 3 s
	rb.CFrame = roblox.CFrame.new(pad2.CFrame.Position + roblox.Vector3.new(1, 3, 1))
	hb:Fire(0.3)
	assert(lastQueue() == "Queue:Starting 2/2", "two players, got " .. tostring(lastQueue()))
	waitFor(L.FullCountdown + 0.3)
	hb:Fire(0.3)
	assert(#teleports == 1 and teleports[1][2] == 2, "full: off with both after 3 s, not 10")
	print("full circle drops to 3 s ok")
	-- solo circle: full at once, 3 s
	local c, rc = makePlayer("C")
	rc.CFrame = roblox.CFrame.new(lobby:FindFirstChild("Pad1").CFrame.Position + roblox.Vector3.new(0, 3, 0))
	hb:Fire(0.3)
	waitFor(L.FullCountdown + 0.3)
	hb:Fire(0.3)
	assert(#teleports == 2 and teleports[2][2] == 1, "solo: off after 3 s")
	print("solo ok")
	-- a circle that isn't full goes at 0 with whoever's on it (shortened here: Countdown 1)
	L.Countdown = 1
	local d, rd = makePlayer("D")
	rd.CFrame = roblox.CFrame.new(0, 3, 408)
	ctx.Remotes.QuickPlay.OnServerEvent:Fire(d, "Group")
	hb:Fire(0.3)
	assert(string.find(lastQueue(), "Starting 1/"), "quick play: on a group circle, counting down, got " .. tostring(lastQueue()))
	waitFor(1.2)
	hb:Fire(0.3)
	assert(#teleports == 3 and teleports[3][2] == 1, "not full: off at 0 with one player")
	assert(lastOptions.Data.Code == lastOptions.ReservedServerAccessCode and lastOptions.Data.Cap ~= nil, "a fresh night, offered to the next lobby")
	print("not full at 0 ok")
	rawset(d, "Parent", nil)
	table.remove(players, table.find(players, d))
	-- not full at 0, and a group night elsewhere started short with room: they join it (MatchService)
	local asked = nil
	ctx.Match = { find = function(n) asked = n; return "night-7" end }
	local f, rf = makePlayer("F")
	rf.CFrame = roblox.CFrame.new(lobby:FindFirstChild("Pad4").CFrame.Position + roblox.Vector3.new(0, 3, 0))
	hb:Fire(0.3)
	waitFor(1.2)
	hb:Fire(0.3)
	assert(asked == 1, "looked for a night with room for 1")
	assert(#teleports == 4 and teleports[4][2] == 1, "joined it")
	assert(lastOptions.ReservedServerAccessCode == "night-7", "into that night's server")
	assert(lastOptions.Data and lastOptions.Data.Cap == 4 and lastOptions.Data.Code == "night-7", "teleport data carries the code and the circle size")
	print("join a night in progress ok")
	-- a full circle also tries an open night first (a lone player there gets company); none: a fresh house
	asked = nil
	ctx.Match = { find = function(n) asked = n; return nil end }
	local pad3 = lobby:FindFirstChild("Pad3")
	for i = 1, 3 do
		local _, r = makePlayer("G" .. i)
		r.CFrame = roblox.CFrame.new(pad3.CFrame.Position + roblox.Vector3.new(i - 2, 3, 0))
	end
	hb:Fire(0.3)
	waitFor(L.FullCountdown + 0.3)
	hb:Fire(0.3)
	assert(asked == 3, "a full circle of 3 looked for room for 3, got " .. tostring(asked))
	assert(#teleports == 5 and teleports[5][2] == 3, "then off to a fresh house")
	assert(lastOptions.ReservedServerAccessCode == "code-123" and lastOptions.Data.Cap == 3, "a fresh night")
	-- PLAY SOLO never joins anyone
	asked = nil
	rawset(c, "Parent", nil) -- (the earlier solo player has gone: the circle is free)
	table.remove(players, table.find(players, c))
	hb:Fire(0.3)
	local s1, rs1 = makePlayer("S1")
	rs1.CFrame = roblox.CFrame.new(lobby:FindFirstChild("Pad1").CFrame.Position + roblox.Vector3.new(0, 3, 0))
	hb:Fire(0.3)
	waitFor(L.FullCountdown + 0.3)
	hb:Fire(0.3)
	assert(asked == nil and #teleports == 6, "solo: straight to its own house")
	print("full circles look too, solo never ok")
	-- invited from inside a friend's night: straight into that house (Social.invite carries its code)
	local inv = makePlayer("Invited")
	rawset(inv, "GetJoinData", function() return { LaunchData = "night:abc123" } end)
	local before = #teleports
	Lobby._invited(inv)
	assert(#teleports == before + 1 and teleports[#teleports][2] == 1, "the invited friend goes at once")
	local td = lastOptions and lastOptions.Data
	assert(lastOptions.ReservedServerAccessCode == "abc123" and td and td.Code == "abc123" and td.Invited and td.PartySize == 1,
		"into the friend's own server")
	-- a referral link (ref:...) or nothing: the lobby as usual
	local other = makePlayer("Other")
	rawset(other, "GetJoinData", function() return { LaunchData = "ref:1" } end)
	Lobby._invited(other)
	assert(#teleports == before + 1, "not an invite: stays in the lobby")
	print("invites ok")
	-- (v124) a Roblox friend's house: the lobby offers it (FriendHouse = the friend's name) and tells that
	-- house; JOIN takes them straight there, out of any circle, as an invited player
	local seen = {}
	local savedMatch = ctx.Match
	ctx.Match = {
		friendHouse = function(p) if p.Name == "Bo" then return "night-sam", "Sam" end return nil, nil end,
		friendSeen = function(c, name, coming) table.insert(seen, { c, name, coming }) end,
		forget = function() end,
		find = function() return nil end,
	}
	local bo = makePlayer("Bo")
	Lobby._friendCheck(bo)
	assert(bo:GetAttribute("FriendHouse") == "Sam", "offered Sam's house")
	assert(#seen == 1 and seen[1][1] == "night-sam" and not seen[1][3], "and Sam's house is told Bo is here")
	local loner = makePlayer("Lo")
	Lobby._friendCheck(loner)
	assert(loner:GetAttribute("FriendHouse") == nil, "nobody's friend: nothing")
	local tb = #teleports
	ctx.Remotes.JoinFriend.OnServerEvent:Fire(bo)
	assert(#teleports == tb + 1 and lastOptions.ReservedServerAccessCode == "night-sam", "JOIN: into Sam's house")
	local ftd = lastOptions.Data
	assert(ftd and ftd.Invited and ftd.Code == "night-sam" and ftd.PartySize == 1, "as an invited player")
	assert(seen[#seen][3] == true and bo:GetAttribute("FriendHouse") == nil, "Sam's house hears Bo is on the way")
	ctx.Remotes.JoinFriend.OnServerEvent:Fire(loner)
	assert(#teleports == tb + 1, "no friend's house: nothing happens")
	for _, gone in { bo, loner } do
		rawset(gone, "Parent", nil)
		table.remove(players, table.find(players, gone))
	end
	ctx.Match = savedMatch
	print("friends ok")
	-- (v118) once queued you stay queued until LEAVE: the walls hold you in, anyone pushed out is put back
	L.Countdown = 10
	ctx.Match = { find = function() return nil end }
	for _, gone in { a, b } do -- (the pair sent from Pad2 earlier has left: it's free)
		rawset(gone, "Parent", nil)
		table.remove(players, table.find(players, gone))
	end
	hb:Fire(0.3)
	local walls = 0
	for _, d in lobby:GetDescendants() do
		if d.Name == "QueueWall" then
			walls += 1
			assert(d.CanCollide and d.Transparency == 1 and d.Size.Y >= 12, "walls: solid, invisible, too tall to jump")
		end
	end
	assert(walls >= 24 * #L.QueueSizes, "a wall round every circle: " .. walls)
	local q, rq = makePlayer("Queued")
	local pad2c = lobby:FindFirstChild("Pad2").CFrame.Position
	rq.CFrame = roblox.CFrame.new(pad2c + roblox.Vector3.new(0, 3, 0))
	hb:Fire(0.3)
	assert(string.find(lastQueue(), "Starting 1/2"), "queued: " .. tostring(lastQueue()))
	assert(q.Character:GetAttribute("CollisionGroup") == "Queued", "queued players bump into the walls")
	rq.CFrame = roblox.CFrame.new(pad2c + roblox.Vector3.new(25, 3, 0)) -- (somehow out: flung, glitched)
	hb:Fire(0.3)
	assert(string.find(lastQueue(), "Starting 1/2"), "out of the circle: still queued, got " .. tostring(lastQueue()))
	local back = rq.CFrame.Position - pad2c
	assert(roblox.Vector3.new(back.X, 0, back.Z).Magnitude < 5, "and put back inside: " .. tostring(back))
	-- LEAVE: out, in front of the circle, no longer queued, walls no longer in the way
	ctx.Remotes.LeaveQueue.OnServerEvent:Fire(q)
	hb:Fire(0.3)
	assert(fired[#fired] == "Queue:nil", "pressed LEAVE: not queued, got " .. tostring(fired[#fired]))
	assert(q.Character:GetAttribute("CollisionGroup") == "Default", "free to walk again")
	local out = rq.CFrame.Position - pad2c
	assert(roblox.Vector3.new(out.X, 0, out.Z).Magnitude > 6, "stood outside the circle: " .. tostring(out))
	-- but a newcomer has to actually stand in it
	local w, rw = makePlayer("Walker")
	rw.CFrame = roblox.CFrame.new(pad2c + roblox.Vector3.new(9, 3, 0))
	hb:Fire(0.3)
	assert(fired[#fired] == "Queue:nil", "near isn't in: " .. tostring(fired[#fired]))
	print("queue walls + LEAVE ok")
	-- (v107) the open-night lookup hanging (MemoryStore) never holds the circle: a fresh house after MATCH_WAIT
	ctx.Match = { find = function() coroutine.yield() return "too-late" end }
	local t0 = os.clock()
	assert(Lobby._findWithin(1, 0.3, {}) == nil and os.clock() - t0 < 1.5, "gave up on the lookup in time")
	ctx.Match = { find = function() return "night-9" end }
	assert(Lobby._findWithin(1, 0.3, {}) == "night-9", "a quick answer is used")
	print("match lookup timeout ok")
	-- (v122) a short group to a fresh house: who's still in the lobby rides along in the teleport data
	-- (friends first), and they're told they can follow
	do
		for i = #players, 1, -1 do
			rawset(players[i], "Parent", nil)
			table.remove(players, i)
		end
		hb:Fire(0.3)
		L.Countdown = 1
		ctx.Match = { find = function() return nil end, listNew = function() end }
		local g, rg = makePlayer("Gina")
		local st = makePlayer("Stranger")
		local pal = makePlayer("Pal")
		rawset(g, "UserId", 501); rawset(st, "UserId", 502); rawset(pal, "UserId", 503)
		rawset(g, "DisplayName", "Gina"); rawset(st, "DisplayName", "Stranger"); rawset(pal, "DisplayName", "Pal")
		rawset(g, "IsFriendsWith", function(_, id) return id == 503 end)
		local list = Lobby._leftBehind({ g })
		assert(#list == 2 and list[1] == pal and list[2] == st, "the friend first")
		local nBefore = #fired
		rg.CFrame = roblox.CFrame.new(lobby:FindFirstChild("Pad2").CFrame.Position + roblox.Vector3.new(0, 3, 0))
		hb:Fire(0.3)
		waitFor(1.2)
		hb:Fire(0.3)
		local td = lastOptions and lastOptions.Data
		assert(td and td.Behind == 2 and td.BehindNames == "Pal and Stranger", "who was left behind rides along: " .. tostring(td and td.BehindNames))
		local told = 0
		for i = nBefore + 1, #fired do
			if string.find(fired[i], "Gina just went into a house", 1, true) then told += 1 end
		end
		assert(told == 2, "both told they can follow: " .. told)
		print("left behind ok")
	end
end)
print(ok and "LOBBY OK" or ("LOBBY FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
