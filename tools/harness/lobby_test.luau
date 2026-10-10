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
	local realNew = H.Instance.new
	H.Instance.new = function(className, parent)
		if className == "TeleportOptions" then
			return { SetTeleportData = function() end }
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
		local r = { FireClient = function(_, p, payload) table.insert(fired, k .. ":" .. (payload and (payload.Status .. " " .. payload.Count .. "/" .. payload.Size) or "nil")) end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	local Lobby = H.load("Server/Lobby/LobbyServer")
	Lobby.run(ctx)
	local lobby = H.unwrap(H.workspaceRoot):FindFirstChild("Lobby")
	local n = 0
	for _, d in lobby:GetDescendants() do if d:IsA("BasePart") then n += 1 end end
	print("lobby parts", n)
	-- two players step onto the 2-player circle
	local pad2 = lobby:FindFirstChild("Pad2")
	local a, ra = makePlayer("A")
	local b, rb = makePlayer("B")
	ra.CFrame = roblox.CFrame.new(pad2.CFrame.Position + roblox.Vector3.new(0, 3, 0))
	local hb = S.RunService.Heartbeat
	hb:Fire(0.3)
	print("after A only:", fired[#fired])
	rb.CFrame = roblox.CFrame.new(pad2.CFrame.Position + roblox.Vector3.new(1, 3, 1))
	hb:Fire(0.3)
	print("after B joins:", fired[#fired])
	-- wait out the countdown (os.clock based)
	local t0 = os.clock()
	while os.clock() - t0 < ctx.Config.Lobby.Countdown + 0.5 do end
	hb:Fire(0.3)
	assert(#teleports == 1 and teleports[1][2] == 2, "the full 2-player circle left with both")
	print("teleports:", #teleports, teleports[1] and ("place " .. teleports[1][1] .. " players " .. teleports[1][2]) or "")
	-- solo circle
	local c, rc = makePlayer("C")
	rc.CFrame = roblox.CFrame.new(lobby:FindFirstChild("Pad1").CFrame.Position + roblox.Vector3.new(0, 3, 0))
	hb:Fire(0.3)
	t0 = os.clock()
	while os.clock() - t0 < ctx.Config.Lobby.SoloCountdown + 0.5 do end
	hb:Fire(0.3)
	print("teleports after solo:", #teleports)
	-- quick play: a player taps FIND PLAYERS and lands in a group circle
	local d, rd = makePlayer("D")
	rd.CFrame = roblox.CFrame.new(0, 3, 408)
	ctx.Remotes.QuickPlay.OnServerEvent:Fire(d, "Group")
	hb:Fire(0.3)
	print("quickplay moved to", rd.Position, "queued:", fired[#fired])
	-- nobody else coming: START NOW (after a short wait) takes whoever's on the circle
	local L = ctx.Config.Lobby
	L.StartNowAfter, L.FillWait, L.Countdown = 0.4, 100, 1
	local before = #teleports
	t0 = os.clock()
	while os.clock() - t0 < 0.5 do end
	hb:Fire(0.3)
	ctx.Remotes.StartNow.OnServerEvent:Fire(d)
	hb:Fire(0.3)
	t0 = os.clock()
	while os.clock() - t0 < 3.3 do end
	hb:Fire(0.3)
	assert(#teleports == before + 1 and teleports[#teleports][2] == 1, "START NOW: off with 1 player (" .. #teleports .. ")")
	print("start now ok:", #teleports - before, "group of", teleports[#teleports][2])
	-- (D has gone to the house: the circle is free again straight away)
	rawset(d, "Parent", nil)
	table.remove(players, table.find(players, d))
	-- and a circle that never fills starts on its own after FillWait
	local e, re = makePlayer("E")
	re.CFrame = roblox.CFrame.new(lobby:FindFirstChild("Pad3").CFrame.Position + roblox.Vector3.new(0, 3, 0))
	L.FillWait = 0.5
	hb:Fire(0.3)
	t0 = os.clock()
	while os.clock() - t0 < 0.6 do end
	hb:Fire(0.3)
	assert(string.find(fired[#fired], "Starting"), "auto-start countdown, got " .. tostring(fired[#fired]))
	t0 = os.clock()
	while os.clock() - t0 < 1.3 do end
	hb:Fire(0.3)
	assert(#teleports == before + 2 and teleports[#teleports][2] == 1, "the 3-player circle left with 1 after the wait")
	print("auto start ok")
end)
print(ok and "LOBBY OK" or ("LOBBY FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
