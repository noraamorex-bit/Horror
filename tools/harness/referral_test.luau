local H = require("./env")
local ok, err = pcall(function()
	local ctx: any = {}
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Config = H.load("RS/Shared/Config")
	local notes = {}
	local setBeam
	ctx.Remotes = setmetatable({}, { __index = function(_, k)
		return {
			FireClient = function(_, p, text) if k == "Notify" then table.insert(notes, p.Name .. ": " .. tostring(text)) end end,
			FireAllClients = function() end,
			OnServerEvent = { Connect = function(_, fn) if k == "SetBeam" then setBeam = fn end end },
		}
	end })
	-- (v121) invites pay coins: a fake wallet (EconomyService) and a fake datastore for whoever's away
	local coins = {}
	ctx.Economy = {
		ready = function() return true end,
		addCoins = function(p, n) coins[p.UserId] = (coins[p.UserId] or 0) + n; return true end,
	}
	local kv = {}
	H.services.DataStoreService = {
		GetDataStore = function(_, name)
			kv[name] = kv[name] or {}
			local t = kv[name]
			return {
				GetAsync = function(_, k) return t[k] end,
				SetAsync = function(_, k, v) t[k] = v end,
				UpdateAsync = function(_, k, fn) local v = fn(t[k]); if v ~= nil then t[k] = v end; return t[k] end,
			}
		end,
	}
	local Stats = H.load("Server/Services/StatsService")
	Stats.init(ctx)
	local roblox = H.roblox
	local function mk(id, name, join)
		local p = H.wrap(roblox.Instance.new("Player")); p.Name = name; rawset(p, "UserId", id); rawset(p, "DisplayName", name)
		rawset(p, "GetJoinData", function() return join end)
		rawset(p, "IsFriendsWithAsync", function() return false end)
		return p
	end
	local a = mk(1, "Alex", {})
	local b = mk(2, "Bo", { LaunchData = "ref:1" })
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
	assert(a:GetAttribute("StatReferrals") == 1 and a:GetAttribute("StatBeam") == "Ember" and #notes == 2)
	local R = ctx.Config.Referral
	assert(coins[1] == R.Coins and coins[2] == R.Welcome, "both paid: " .. tostring(coins[1]) .. " / " .. tostring(coins[2]))
	assert(string.find(notes[1], "+" .. R.Coins, 1, true) and string.find(notes[2], "+" .. R.Welcome, 1, true), "and told")
	-- (v121) Roblox's own referral (an invite from the lobby, or into a night): ReferredByPlayerId
	H.workspaceRoot:SetAttribute("Mode", "Lobby")
	local c = mk(3, "Cy", { ReferredByPlayerId = 1 })
	table.insert(list, c)
	H.services.Players.PlayerAdded:Fire(c)
	H.task.wait(0.1)
	assert(a:GetAttribute("StatReferrals") == 2 and coins[1] == 2 * R.Coins and coins[3] == R.Welcome, "ReferredByPlayerId counts")
	-- the one who invited is away: the coins wait for them, and come on their next visit
	local d = mk(4, "Dee", { ReferredByPlayerId = 9 })
	table.insert(list, d)
	H.services.Players.PlayerAdded:Fire(d)
	H.task.wait(0.1)
	local saved = kv.PlayerStats_v1 and kv.PlayerStats_v1.u9
	assert(saved and saved.Referrals == 1 and saved.RefCoins == R.Coins, "kept for them")
	local e = mk(9, "Eve", {})
	table.insert(list, e)
	H.services.Players.PlayerAdded:Fire(e)
	H.task.wait(0.1)
	assert(coins[9] == R.Coins and kv.PlayerStats_v1.u9.RefCoins == nil, "paid once they're back, and cleared")
	-- (a save never wipes coins still owed)
	kv.PlayerStats_v1.u9.RefCoins = 50
	Stats.setBeam(e, "Ember")
	H.task.wait(0.1)
	assert(kv.PlayerStats_v1.u9.RefCoins == 50, "a save keeps RefCoins")
	for _, n in notes do print("  note", n) end
end)
print(ok and "REFERRAL OK" or ("REFERRAL FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
