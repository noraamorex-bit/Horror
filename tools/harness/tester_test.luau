-- tester_test (v163): the owner's testers. Only the owner adds/removes them (by username, from the panel); a tester gets the full
-- panel (IsAdmin, every tab and command incl. coins) and every pass switched on; taken off the list, the panel and the passes go
-- back to normal; testers can't troll the owner, aren't on the boards, can't manage testers; strangers get nothing.
local H = require("./env")
local T = 1000
H.clock = function() return T end
H.schedule = true
function H.flush(sec) for _ = 1, math.ceil(sec / 0.1) do T += 0.1; H.runDue() end end
local R = H.roblox

local ctx: any = {}
ctx.Config = H.load("RS/Shared/Config")
ctx.Rooms = H.load("RS/Shared/Rooms")
ctx.Sounds = H.load("RS/Shared/Sounds")
ctx.Story = H.load("RS/Shared/Story")
ctx.Util = H.load("RS/Shared/Util")
ctx.Builder = H.load("Server/World/Builder")
ctx.Layout = H.load("Server/World/Layout")
local fired = {}
ctx.Remotes = setmetatable({}, { __index = function(t, k)
	local r = { FireClient = function(_, p, a, b) table.insert(fired, { k, p, a, b }) end, FireAllClients = function() end, OnServerEvent = H.signal() }
	rawset(t, k, r)
	return r
end })
local coins = {}
ctx.Economy = setmetatable({ addCoins = function(p, n) coins[p] = (coins[p] or 0) + n; return true end, coins = function(p) return coins[p] or 0 end }, { __index = function() return function() end end })

local players = {}
local function mkPlayer(name, id)
	local p = H.wrap(R.Instance.new("Player"))
	p.Name = name
	rawset(p, "UserId", id)
	rawset(p, "DisplayName", name)
	local char = H.Instance.new("Model")
	local root = H.Instance.new("Part", char); root.Name = "HumanoidRootPart"
	local hum = H.Instance.new("Humanoid", char); hum.Health = 100
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	p:SetAttribute("InGame", true)
	table.insert(players, p)
	return p
end

local ok, err = pcall(function()
	H.services.RunService.IsStudio = function() return false end
	local owner, friend, rando = mkPlayer("Owner", 915496194), mkPlayer("Sam", 4242), mkPlayer("Rando", 777)
	H.services.Players.GetPlayers = function() return players end
	H.services.Players.GetPlayerByUserId = function(_, id) for _, q in players do if q.UserId == id then return q end end return nil end
	H.services.Players.GetUserIdFromNameAsync = function(_, name) if string.lower(name) == "farfriend" then return 999 end error("no such user") end
	H.services.Players.GetNameFromUserIdAsync = function(_, id) return "User" .. id end

	local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService", "Revive=ReviveService", "Testers=TesterService", "Shop=ShopService", "Admin=AdminService", "Stats=StatsService" }
	local names = {}
	for _, name in ORDER do
		local key, file = name:match("(%w+)=(%w+)")
		ctx[key] = H.load("Server/Services/" .. file)
		table.insert(names, key)
	end
	ctx.World = H.load("Server/World/World")
	ctx.Director = H.load("Server/Director/Director")
	ctx.Intruder = H.load("Server/Intruder/Intruder")
	for _, k in { "World", "Director", "Intruder" } do table.insert(names, k) end
	for _, k in names do if ctx[k].init then ctx[k].init(ctx) end end
	ctx.World.build()
	ctx.restart = function() end
	for _, k in names do if ctx[k].start then local ok2, e2 = pcall(ctx[k].start); if not ok2 then print("(start " .. k .. ": " .. tostring(e2) .. ")") end end end
	H.flush(1)

	local function cmd(p, c, a) ctx.Remotes.Admin.OnServerEvent:Fire(p, c, a) end
	local function lastReply(p) local r = nil; for _, f in fired do if f[1] == "AdminReply" and f[2] == p and type(f[3]) == "string" then r = f[3] end end; return r end
	local function lastList(p) local r = nil; for _, f in fired do if f[1] == "AdminReply" and f[2] == p and type(f[4]) == "table" and f[4].TesterList then r = f[4].TesterList end end; return r end

	assert(owner:GetAttribute("IsOwner") == true and owner:GetAttribute("IsAdmin") == true, "the owner is marked")
	assert(not friend:GetAttribute("IsAdmin") and not ctx.Admin.isAdmin(friend), "a friend starts as a normal player")

	-- nobody but the owner manages testers
	cmd(rando, "testeradd", "Rando")
	assert(not ctx.Testers.is(rando) and not rando:GetAttribute("IsAdmin"), "a stranger can't make themself a tester")
	friend:SetAttribute("Pass_AdminPanel", true)
	cmd(friend, "testeradd", "Sam")
	assert(not ctx.Testers.is(friend), "the admin pass can't make testers")
	friend:SetAttribute("Pass_AdminPanel", nil)

	-- the owner adds Sam by name: the full panel and every pass, right away
	cmd(owner, "testeradd", "sam")
	H.flush(1)
	print("add:", lastReply(owner))
	assert(ctx.Testers.is(friend) and friend:GetAttribute("IsTester") == true, "Sam is a tester")
	assert(friend:GetAttribute("IsAdmin") == true and not friend:GetAttribute("IsOwner"), "the full panel, not the owner's")
	for _, pass in ctx.Config.Shop.Passes do
		assert(friend:GetAttribute("Pass_" .. pass.Key) == true, "every pass on: " .. pass.Key)
	end
	local list = lastList(owner)
	assert(list and #list == 1 and list[1].Id == 4242, "the panel gets the list back")
	-- by a username of someone not in the server
	cmd(owner, "testeradd", "FarFriend")
	assert(ctx.Testers.isId(999), "added by username from anywhere")
	cmd(owner, "testeradd", "nobody_at_all")
	assert(lastReply(owner):find("No Roblox user"), "an unknown name says so")

	-- a tester uses the owner-only bits: coins, passes, gear, a night-wide command (no strangers check)
	local c0 = coins[friend] or 0
	cmd(friend, "coins", "1000")
	assert((coins[friend] or 0) == c0 + 1000, "the COINS tab works for a tester: " .. tostring(lastReply(friend)))
	cmd(friend, "start", "Normal")
	assert(H.unwrap(H.workspaceRoot):GetAttribute("Act") ~= nil and H.unwrap(H.workspaceRoot):GetAttribute("Act") ~= "Lobby", "a tester can start a night with a stranger here (like the owner)")
	cmd(friend, "give", "Rocket")
	assert(friend:GetAttribute("Item_Rocket"), "the paid gear: " .. tostring(lastReply(friend)))
	assert(not ctx.Admin.uncredited(friend), "a tester's night isn't marked as a pass holder's")
	-- but never the tester list, and never trolling the owner
	cmd(friend, "testerremove", "999")
	assert(ctx.Testers.isId(999) and lastReply(friend):find("owner"), "testers can't manage testers")
	H.flush(2)
	cmd(friend, "troll", "spin|" .. owner.UserId)
	assert(lastReply(friend):find("owner"), "a tester can't troll the owner: " .. tostring(lastReply(friend)))
	H.flush(2)
	cmd(owner, "troll", "spin|" .. friend.UserId)
	assert(lastReply(owner):find("spin"), "the owner can troll a tester: " .. tostring(lastReply(owner)))
	-- off the boards
	assert(ctx.Stats.offBoards(4242) and ctx.Stats.offBoards(999) and not ctx.Stats.offBoards(777), "testers are off the boards")

	-- removed: the panel goes, the passes go back to what they own
	cmd(owner, "testerremove", "4242")
	H.flush(1)
	print("remove:", lastReply(owner))
	assert(not ctx.Testers.is(friend) and not friend:GetAttribute("IsTester") and not friend:GetAttribute("IsAdmin"), "Sam's panel is gone")
	for _, pass in ctx.Config.Shop.Passes do
		assert(not friend:GetAttribute("Pass_" .. pass.Key), "passes back off: " .. pass.Key)
	end
	cmd(owner, "testers")
	assert(lastReply(owner):find("User999") or lastReply(owner):find("FarFriend"), "the list: " .. tostring(lastReply(owner)))
	-- Config.Testers works too
	table.insert(ctx.Config.Testers, 777)
	ctx.Testers._apply(rando)
	assert(rando:GetAttribute("IsAdmin") == true, "a Config tester gets the panel")
	print("testers ok")
end)
local errs = {}
for _, e in H.errors do if not string.find(tostring(e), "TextChannels", 1, true) then table.insert(errs, tostring(e)) end end
print(ok and (#errs == 0 and "TESTER OK" or "TESTER FAIL: errors") or ("TESTER FAIL: " .. tostring(err)))
for _, e in errs do print(e:sub(1, 600)) end
