--[[
	ReviveService — died? Buy a revive (developer product, Config.Shop.Revive) and you're back in
	this night: on your feet somewhere away from him, with a few seconds before he can feel you.
	It's only for the night you're in; the next night starts like any other.

	• In co-op the offer is on your result card for as long as the night goes on.
	• The last one standing (solo, or everyone else gone) gets Config.Shop.Revive.Window seconds
	  to decide before the night ends (EndingService holds the ending for it).
	• A revive bought when it can't be used (the night ended meanwhile, or bought in the lobby) is
	  saved (StatsService credits) and offered the next time you die, as USE REVIVE.
]]

local Players = game:GetService("Players")

local Revive = {}
local ctx
local processed: { [string]: boolean } = {} -- purchase ids already handled on this server

function Revive.init(c)
	ctx = c
	ctx.Revive = Revive
end

local function cfg()
	return ctx.Config.Shop.Revive or { Id = 0, Price = 0, Window = 15, Grace = 10 }
end

function Revive.productId(): number
	return cfg().Id or 0
end

function Revive.window(): number
	return cfg().Window or 15
end

-- can this player be brought back right now?
function Revive.canRevive(player: Player): boolean
	return player.Parent ~= nil
		and player:GetAttribute("InGame") == true
		and player:GetAttribute("Dead") == true
		and not player:GetAttribute("Escaped")
		and not ctx.Ending.isOver()
		and workspace:GetAttribute("Act") ~= "Lobby"
end

-- is a revive on offer for them (the product exists, or they have one saved)?
function Revive.offered(player: Player): boolean
	return Revive.productId() > 0 or (tonumber(player:GetAttribute("ReviveCredits")) or 0) > 0
end

-- somewhere on the ground floor or upstairs, as far from him as the house allows
local function spot(): Vector3
	local L = ctx.Layout
	local him = ctx.Intruder and ctx.Intruder.position and ctx.Intruder.position()
	local list = {}
	for _, n in L.Nodes do
		local floor = ctx.Rooms.floorOf(n.Pos)
		if floor == "Ground" or floor == "Upstairs" then
			local d = him and (n.Pos - him).Magnitude + math.abs(n.Pos.Y - him.Y) * 2 or math.random() * 100
			table.insert(list, { Pos = n.Pos, D = d })
		end
	end
	if #list == 0 then
		return L.LobbySpawns[1]
	end
	table.sort(list, function(a, b)
		return a.D > b.D
	end)
	return list[math.random(1, math.min(4, #list))].Pos
end

function Revive.revive(player: Player): boolean
	if not Revive.canRevive(player) then
		return false
	end
	ctx.Capture.revived(player)
	ctx.Ending.revived(player)
	local at = spot()
	ctx.PlayerState.setFrozen(player, false)
	ctx.PlayerState.placeStanding(player, CFrame.new(at + Vector3.new(0, 0.5, 0)))
	local hum = ctx.Util.getHumanoid(player)
	if hum then
		hum.Health = hum.MaxHealth
	end
	player:SetAttribute("Nerve", ctx.Config.Nerve.Max)
	player:SetAttribute("Stamina", ctx.Config.Movement.StaminaMax)
	player:SetAttribute("Revives", (tonumber(player:GetAttribute("Revives")) or 0) + 1)
	if ctx.Intruder and ctx.Intruder.grace then
		ctx.Intruder.grace(player, cfg().Grace or 10)
	end
	ctx.Remotes.Revived:FireClient(player)
	ctx.Remotes.Fade:FireClient(player, false, 1.5)
	ctx.Audio.caption("You're back. He doesn't know yet. Move.", nil, nil, { player })
	local name = tostring(player:GetAttribute("RoleName") or player.DisplayName)
	for _, other in ctx.Util.sessionPlayers() do
		if other ~= player then
			ctx.Remotes.Notify:FireClient(other, name .. " is back!", "objective")
		end
	end
	if ctx.Director then
		ctx.Director.logTruthRaw(name .. " came back.")
		ctx.Director.checkAllCaptured()
	end
	return true
end

-- ProcessReceipt for the revive product (ShopService hands it over)
function Revive.onReceipt(info): Enum.ProductPurchaseDecision
	local key = tostring(info.PurchaseId)
	if processed[key] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		-- (left before we could deliver it: Roblox tries again when they're next in a server)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if Revive.revive(player) then
		processed[key] = true
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- too late for this night: keep it for next time
	if ctx.Stats and ctx.Stats.addReviveCredit(player) then
		processed[key] = true
		ctx.Remotes.Notify:FireClient(player, "Revive saved. It'll be offered the next time you die.", "info")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function Revive.start()
	ctx.Remotes.UseRevive.OnServerEvent:Connect(function(player)
		if not Revive.canRevive(player) then
			return
		end
		if ctx.Stats and ctx.Stats.spendReviveCredit(player) then
			if not Revive.revive(player) then
				ctx.Stats.addReviveCredit(player) -- (give it back)
			end
		end
	end)
end

return Revive
