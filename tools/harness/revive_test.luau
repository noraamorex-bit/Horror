-- revive_test: dying and coming back. Solo: the night waits Config.Shop.Revive.Window seconds,
-- a revive puts you back on your feet away from him; no revive and the night ends.
-- Co-op: the dead player's card offers REVIVE while the others play on.
-- Run with arg "solo", "nobuy", "coop" or "credit".
local H = require("./env")
local Enum = H.roblox.Enum
local T = 1000
H.clock = function() return T end
H.schedule = true
function H.flush(sec) for _ = 1, math.ceil(sec / 0.1) do T += 0.1; H.runDue() end end
local function setup()
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
		local r = { FireClient = function(_, p, a) table.insert(fired, { k, p, a }) end, FireAllClients = function() end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService", "Revive=ReviveService" }
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
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	return ctx, fired
end
local function mkPlayer(name, id)
	local roblox = H.roblox
	local p = H.wrap(roblox.Instance.new("Player"))
	p.Name = name
	rawset(p, "UserId", id)
	local char = H.Instance.new("Model")
	local rootPart = H.Instance.new("Part", char)
	rootPart.Name = "HumanoidRootPart"
	local hum = H.Instance.new("Humanoid", char)
	hum.Health = 100
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	p:SetAttribute("InGame", true)
	return p
end
local function kinds(fired, kind)
	local out = {}
	for _, f in fired do if f[1] == kind then table.insert(out, f) end end
	return out
end
local function receipt(ctx, p, n)
	local MS = H.services.MarketplaceService
	return ctx.Revive.onReceipt({ PlayerId = p.UserId, ProductId = ctx.Config.Shop.Revive.Id, PurchaseId = "buy" .. n })
end
local MODE = require("@lune/process").args[1] or "solo"
local ok, err = pcall(function()
	local ctx, fired = setup()
	local W = ctx.Config.Shop.Revive.Window
	if MODE == "solo" or MODE == "nobuy" or MODE == "credit" then
		local a = mkPlayer("Solo", 11)
		H.services.Players.GetPlayers = function() return { a } end
		H.services.Players.GetPlayerByUserId = function(_, id) return id == 11 and a or nil end
		ctx.Director.startAct("Guest")
		ctx.Capture.kill(a)
		H.flush(3)
		local res = kinds(fired, "Result")
		assert(#res == 1 and res[1][3].CanRevive and res[1][3].ReviveIn and res[1][3].ReviveIn > 0, "solo death offers a revive with a countdown")
		assert(not ctx.Ending.isOver(), "the night waits")
		H.flush(5)
		assert(not ctx.Ending.isOver(), "still waiting (last chance held)")
		if MODE == "nobuy" then
			H.flush(W)
			assert(ctx.Ending.isOver(), "no revive: the night ends after the window")
			print("nobuy: ended", ctx.Ending.isOver())
		elseif MODE == "credit" then
			-- the night ended before the purchase went through: it's saved
			H.flush(W)
			assert(ctx.Ending.isOver())
			local stats = { credits = 0 }
			ctx.Stats = { addReviveCredit = function() stats.credits += 1; a:SetAttribute("ReviveCredits", stats.credits); return true end, spendReviveCredit = function() return false end }
			assert(receipt(ctx, a, 1) == Enum.ProductPurchaseDecision.PurchaseGranted and stats.credits == 1, "saved as a credit")
			assert(receipt(ctx, a, 1) == Enum.ProductPurchaseDecision.PurchaseGranted and stats.credits == 1, "same receipt not counted twice")
			print("credit: saved", stats.credits)
		else
			assert(receipt(ctx, a, 1) == Enum.ProductPurchaseDecision.PurchaseGranted, "receipt granted")
			assert(not a:GetAttribute("Dead") and not a:GetAttribute("Captured"), "back alive")
			assert(#kinds(fired, "Revived") == 1, "client told")
			H.flush(W + 5)
			assert(not ctx.Ending.isOver(), "the stale timer doesn't end the night")
			-- clean slate: next catch is a zip-tie, not death
			local co = coroutine.create(function() ctx.Capture.capture(a) end); H.ours[co] = true; coroutine.resume(co)
			assert(a:GetAttribute("Captured") and not a:GetAttribute("Dead"), "next catch ties you up")
			print("solo: revived, revives", a:GetAttribute("Revives"))
		end
	elseif MODE == "coop" then
		local a, b = mkPlayer("Dead", 21), mkPlayer("Alive", 22)
		H.services.Players.GetPlayers = function() return { a, b } end
		H.services.Players.GetPlayerByUserId = function(_, id) return id == 21 and a or (id == 22 and b or nil) end
		ctx.Director.startAct("Guest")
		ctx.Capture.kill(a)
		H.flush(3)
		local res = kinds(fired, "Result")
		assert(#res == 1 and res[1][3].CanRevive and res[1][3].ReviveIn == nil and res[1][3].CanSpectate, "co-op: revive + spectate, no countdown")
		H.flush(60)
		assert(not ctx.Ending.isOver())
		assert(receipt(ctx, a, 2) == Enum.ProductPurchaseDecision.PurchaseGranted and not a:GetAttribute("Dead"), "revived mid-night")
		-- a living player can't be 'revived'
		assert(ctx.Revive.revive(b) == false, "only the dead")
		print("coop: revived")
	end
end)
print(ok and ("REVIVE OK " .. MODE) or ("REVIVE FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
