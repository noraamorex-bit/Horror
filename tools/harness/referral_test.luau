local H = require("./env")
local ok, err = pcall(function()
	local ctx: any = {}
	ctx.Story = H.load("RS/Shared/Story")
	local notes = {}
	local setBeam
	ctx.Remotes = setmetatable({}, { __index = function(_, k)
		return {
			FireClient = function(_, p, text) if k == "Notify" then table.insert(notes, p.Name .. ": " .. tostring(text)) end end,
			FireAllClients = function() end,
			OnServerEvent = { Connect = function(_, fn) if k == "SetBeam" then setBeam = fn end end },
		}
	end })
	local Stats = H.load("Server/Services/StatsService")
	Stats.init(ctx)
	local roblox = H.roblox
	local a = H.wrap(roblox.Instance.new("Player")); a.Name = "Alex"; rawset(a, "UserId", 1); rawset(a, "DisplayName", "Alex")
	local b = H.wrap(roblox.Instance.new("Player")); b.Name = "Bo"; rawset(b, "UserId", 2); rawset(b, "DisplayName", "Bo")
	rawset(a, "GetJoinData", function() return {} end)
	rawset(b, "GetJoinData", function() return { LaunchData = "ref:1" } end)
	rawset(a, "IsFriendsWithAsync", function() return false end)
	rawset(b, "IsFriendsWithAsync", function() return false end)
	local list = { a }
	H.services.Players.GetPlayers = function() return list end
	H.services.Players.GetPlayerByUserId = function(_, id) for _, p in list do if p.UserId == id then return p end end return nil end
	H.workspaceRoot:SetAttribute("Mode", "Lobby")
	Stats.start()
	table.insert(list, b)
	H.services.Players.PlayerAdded:Fire(b)
	H.task.wait(0.1)
	print("A referrals", a:GetAttribute("StatReferrals"), "B referred", b:GetAttribute("StatReferred"))
	setBeam(b, "Ember"); print("B beam", b:GetAttribute("StatBeam"), b:GetAttribute("StatBeamColor"))
	setBeam(a, "Moonlight"); print("A moonlight (locked) ->", a:GetAttribute("StatBeam"))
	setBeam(a, "Ember"); print("A ember ->", a:GetAttribute("StatBeam"))
	-- in a game server nobody is credited
	H.workspaceRoot:SetAttribute("Mode", "Game")
	H.services.Players.PlayerAdded:Fire(b)
	H.task.wait(0.1)
	print("A referrals after B joins a game server", a:GetAttribute("StatReferrals"))
	for _, n in notes do print("  note", n) end
	assert(a:GetAttribute("StatReferrals") == 1 and a:GetAttribute("StatBeam") == "Ember" and #notes == 2)
end)
print(ok and "REFERRAL OK" or ("REFERRAL FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
