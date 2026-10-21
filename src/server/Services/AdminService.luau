--[[
	AdminService — the owner's test panel. Skip and replay acts, fire any event or ending, call
	help, boss the intruder around, teleport, give yourself items, become invisible to him, and the
	shop: any pass on/off, the paid gear, become him, saved rockets/revives (SHOP tab).

	Only for the people in Config.Admins (and the experience's owner, and anyone in Studio).
	Every command is checked here, on the server, against the player's UserId: the client panel
	only exists for admins, but even a hand-made remote call from anyone else does nothing.

	The Admin panel pass (v106, 249 R$, Config.Shop.Passes AdminPanel; the owner: "exactly what I
	have except maybe not the coins part and some other unfair stuff"): in a night, everything
	but the COINS and SHOP tabs (no coins, candy, passes, paid gear, become him, saved credits or
	free revives). What it changes for the whole night (acts, events, endings, him, help,
	cutscenes) only works when everyone else in the server is a friend or has the panel too, so
	nobody matched into a stranger's night gets their night skipped. A night it changes pays no
	coins and counts for nothing (Admin.uncredited: no coins, quests, titles, badges, candy, nights
	or boards), for everyone in it; personal ones (god, ghost, items...) only for the player.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Admin = {}
local ctx

function Admin.init(c)
	ctx = c
	ctx.Admin = Admin
end

function Admin.isAdmin(player: Player): boolean
	if not player or not player.Parent then
		return false
	end
	if table.find(ctx.Config.Admins or {}, player.UserId) then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId ~= 0 and player.UserId == game.CreatorId then
		return true
	end
	return RunService:IsStudio()
end

-- what a pass holder can't use (the owner's "coins part and some other unfair stuff")
local OWNER_ONLY = { coins = true, candy = true, pass = true, give = true, becomehim = true, rocketcredit = true, revivecredit = true }
-- what changes the night for everyone in it
local NIGHT_WIDE = { start = true, act = true, nextact = true, restartact = true, restart = true, event = true, ending = true, help = true, finale = true, police = true, ai = true, cut = true }

function Admin.hasPass(player: Player): boolean
	return player:GetAttribute("Pass_AdminPanel") == true
end

-- no coins, titles, badges or records for this player's night (a pass holder's panel was used)
function Admin.uncredited(player: Player): boolean
	if workspace:GetAttribute("AdminUsed") or player:GetAttribute("AdminUsed") then
		return true
	end
	-- (god / ghost stay on between nights)
	return (player:GetAttribute("AdminGod") or player:GetAttribute("AdminGhost")) and not Admin.isAdmin(player) or false
end

-- everyone else in the server: a friend, an admin or another pass holder?
local friendCache: { [string]: boolean } = {}
local function strangersHere(player: Player): boolean
	for _, o in Players:GetPlayers() do
		if o ~= player and not Admin.isAdmin(o) and not Admin.hasPass(o) then
			local key = player.UserId .. ":" .. o.UserId
			-- (only "yes" is kept: they may become friends mid-night)
			if not friendCache[key] then
				local ok, yes = pcall(function()
					return player:IsFriendsWith(o.UserId)
				end)
				if not ok or yes ~= true then
					return true
				end
				friendCache[key] = true
			end
		end
	end
	return false
end

local ITEMS = { "Flashlight", "Walkie", "PepperSpray", "HouseKeys", "CarKeys", "BasementKey", "ElectricalTape", "Poker", "Multitool", "Scissors", "Batteries" }
-- the shop's things, for the SHOP tab: how many of each a "give" hands over
local GEAR = { Rocket = 2, Taser = 3, PepperSpray = 2, EnergyDrink = 2, Firecracker = 2, Flashlight = 1 }

local function reply(player: Player, text: string)
	ctx.Remotes.AdminReply:FireClient(player, text)
end

local function inNight(): boolean
	local act = workspace:GetAttribute("Act")
	return act ~= nil and act ~= "Lobby"
end

-- a clear spot in a room (the AI's navigation nodes are always walkable)
local function roomSpot(room: string): Vector3?
	local list = {}
	for _, n in ctx.Layout.Nodes do
		if n.Room == room then
			table.insert(list, n.Pos)
		end
	end
	if #list == 0 then
		return nil
	end
	return list[math.random(1, #list)]
end

local COMMANDS = {}

-- the night -------------------------------------------------------------------
COMMANDS.start = function(player, arg)
	if ctx.Director.adminStart(arg) then
		return "Night started (" .. ((arg == "Hard" or arg == "Nightmare") and arg or "Normal") .. ")."
	end
	return "A night is already running."
end
COMMANDS.act = function(player, arg)
	if not table.find(ctx.Director.ActOrder, arg) then
		return "Unknown act."
	end
	if not inNight() then
		ctx.Director.adminStart("Normal")
	end
	ctx.Director.startAct(arg)
	return "Act: " .. arg
end
COMMANDS.nextact = function()
	if not inNight() then
		return "No night running."
	end
	ctx.Director.adminNextAct()
	return "Act: " .. tostring(workspace:GetAttribute("Act"))
end
COMMANDS.restartact = function()
	if not inNight() then
		return "No night running."
	end
	local act = workspace:GetAttribute("Act")
	ctx.Director.startAct(act)
	return "Restarted " .. tostring(act)
end
COMMANDS.restart = function()
	task.defer(function()
		ctx.restart(true)
	end)
	return "Resetting the house..."
end
COMMANDS.event = function(player, arg)
	if not inNight() then
		return "No night running."
	end
	return ctx.Director.adminEvent(arg) and ("Event: " .. arg) or ("Couldn't run " .. tostring(arg) .. " right now.")
end
COMMANDS.ending = function(player, arg)
	if not ctx.Story.Endings[arg] then
		return "Unknown ending."
	end
	if not inNight() then
		return "No night running."
	end
	ctx.Ending.trigger(arg)
	return "Ending: " .. arg
end
COMMANDS.help = function(player, arg)
	if not inNight() then
		return "No night running."
	end
	if ctx.Escape.helpCalled() then
		return "Help is already on the way."
	end
	if arg ~= "Phone" and arg ~= "Neighbor" and arg ~= "Car" then
		return "Unknown method."
	end
	ctx.Escape.callForHelp(arg, player)
	return "Help called (" .. arg .. ")."
end
-- the secret ending, now, with whoever's in the night (FinaleService)
COMMANDS.finale = function()
	if not ctx.Finale then
		return "No finale here."
	end
	return ctx.Finale.adminStart() and "Everyone's going down for dinner." or "Can't start it now (already running, or the night is over)."
end

COMMANDS.police = function()
	return ctx.Escape.adminPoliceSoon(5) and "Police arrive in 5s." or "Call for help first."
end

-- him ---------------------------------------------------------------------------
COMMANDS.ai = function(player, arg)
	if not inNight() then
		return "No night running."
	end
	local I = ctx.Intruder
	if arg == "hunt" then
		I.adminHunt(nil)
		return "He's hunting."
	elseif arg == "huntme" then
		player:SetAttribute("AdminGhost", nil)
		I.adminHunt(player)
		return "He's hunting you."
	elseif arg == "lurk" then
		I.setMode("Lurk")
		return "He's lurking."
	elseif arg == "offstage" then
		I.setMode("Offstage")
		return "He's gone (offstage)."
	elseif arg == "appear" then
		I.appearNow()
		return "Next glimpse: now."
	elseif arg == "freeze" then
		local on = not I.adminIsFrozen()
		I.adminFreeze(on)
		return on and "He's frozen." or "He moves again."
	elseif arg == "bring" then
		return I.adminBring(player) and "He's right behind you." or "Couldn't move him."
	elseif arg == "trap" then
		return I.trap() and "Trapped in the basement." or "Couldn't trap him (he must be in the basement)."
	end
	return "Unknown."
end

-- you ---------------------------------------------------------------------------
COMMANDS.me = function(player, arg)
	if arg == "god" then
		local on = not player:GetAttribute("AdminGod")
		player:SetAttribute("AdminGod", on or nil)
		return on and "He can't catch you (he still comes for you)." or "He can catch you again."
	end
	if arg == "ghost" then
		local on = not player:GetAttribute("AdminGhost")
		player:SetAttribute("AdminGhost", on or nil)
		return on and "He can't see or sense you." or "He can see you again."
	end
	if not inNight() or not player:GetAttribute("InGame") then
		return "Only during a night you're in."
	end
	if arg == "items" then
		local owner = player:GetAttribute("IsAdmin") == true
		if owner then
			for item, n in GEAR do
				if not ctx.Inventory.has(player, item) then
					ctx.Inventory.give(player, item, n)
				end
			end
		end
		for _, item in ITEMS do
			-- (the spray is Head start's: pass holders get the free things only)
			if not ctx.Inventory.has(player, item) and (owner or item ~= "PepperSpray") then
				ctx.Inventory.give(player, item, 1)
			end
		end
		return "Items given."
	elseif arg == "battery" then
		player:SetAttribute("Battery", 100)
		return "Battery full."
	elseif arg == "free" then
		if ctx.Capture.isCaptured(player) then
			ctx.Capture.release(player, nil)
			return "Freed."
		end
		return "You're not tied up."
	elseif arg == "revive" then
		if ctx.Revive and ctx.Revive.revive(player) then
			return "Revived."
		end
		return "You're not dead (or the night is over)."
	elseif arg == "heal" then
		player:SetAttribute("Nerve", ctx.Config.Nerve.Max)
		player:SetAttribute("Stamina", ctx.Config.Movement.StaminaMax)
		return "Nerve and stamina full."
	end
	return "Unknown."
end
COMMANDS.tp = function(player, arg)
	if not player:GetAttribute("InGame") or player:GetAttribute("Captured") or player:GetAttribute("Hiding") then
		return "Can't teleport right now."
	end
	local at = roomSpot(arg)
	if not at then
		return "Unknown room."
	end
	ctx.Util.unseat(player)
	ctx.PlayerState.placeStanding(player, CFrame.new(at + Vector3.new(0, 0.5, 0)))
	return "Teleported: " .. arg
end
COMMANDS.cut = function(player, arg)
	if not inNight() then
		return "No night running."
	end
	local C = ctx.Cutscene
	if arg == "LightsOut" then
		C.lightsOut(function() end)
	elseif arg == "HeComesDown" then
		C.heComesDown(ctx.Layout.Attic.GarageHatchBelow)
	elseif arg == "TiedUp" then
		C.tiedUp(player, ctx.Layout.RestraintSlots[1])
	else
		return "Unknown cutscene."
	end
	return "Cutscene: " .. arg
end
-- coins for yourself (saved like any other coins): "coins 1000"; "coins -500" takes some back
COMMANDS.coins = function(player, arg)
	local E = ctx.Economy
	if not E then
		return "No coins here."
	end
	local n = math.floor(tonumber(arg) or 1000)
	n = math.clamp(n, -1000000, 1000000)
	if n < 0 then
		n = -math.min(-n, E.coins(player))
	end
	if n ~= 0 and not E.addCoins(player, n, nil, "Admin") then
		return "Couldn't change your coins (still loading?)."
	end
	return string.format("%s%d coins. You have %d.", n >= 0 and "+" or "", n, E.coins(player))
end

-- Halloween candy for yourself (saved; unlocks the Halloween rewards like found candy): "candy 5"
COMMANDS.candy = function(player, arg)
	local E = ctx.Economy
	if not E or not E.addCandy then
		return "No candy here."
	end
	local n = math.clamp(math.floor(tonumber(arg) or 1), 1, 100)
	return string.format("+%d candy. You have %d.", n, E.addCandy(player, n))
end

-- the shop (SHOP tab): switch any pass on or off for yourself (this server only, nothing is bought
-- or saved), hand yourself the paid gear, become him, a saved revive
COMMANDS.pass = function(player, arg)
	local pass = nil
	for _, p in ctx.Config.Shop.Passes do
		if p.Key == arg then
			pass = p
		end
	end
	if not pass then
		return "Unknown pass."
	end
	local on = not player:GetAttribute("Pass_" .. pass.Key)
	player:SetAttribute("Pass_" .. pass.Key, on or nil)
	if pass.Key == "VIP" then
		for _, k in ctx.Config.Shop.VIPIncludes or {} do
			player:SetAttribute("Pass_" .. k, on or nil)
		end
	end
	if ctx.Stats and ctx.Stats.refresh then
		ctx.Stats.refresh(player)
	end
	-- (in a night, the pass's gear right away, as if it had been bought mid-night)
	if on and ctx.Inventory and player:GetAttribute("InGame") and inNight() then
		if pass.Key == "Rocket" and not ctx.Inventory.has(player, "Rocket") then
			ctx.Inventory.give(player, "Rocket", ctx.Config.Rocket.Charges)
		elseif pass.Key == "PepperSpray" and not ctx.Inventory.has(player, "Taser") then
			ctx.Inventory.give(player, "Taser", ctx.Config.Taser.Charges)
		elseif pass.Key == "HeadStart" then
			ctx.Inventory.give(player, "PepperSpray", 1)
		elseif pass.Key == "NightVision" and not ctx.Inventory.has(player, "NightVision") then
			player:SetAttribute("NVLeft", ctx.Config.NightVision.Seconds)
			ctx.Inventory.give(player, "NightVision", 1)
		end
	end
	return pass.Name .. (on and ": ON (this server, not saved)" or ": OFF")
end
COMMANDS.give = function(player, arg)
	local n = GEAR[arg]
	if not n then
		return "Unknown item."
	end
	if not inNight() or not player:GetAttribute("InGame") then
		return "Only during a night you're in."
	end
	ctx.Inventory.give(player, arg, n)
	return "+" .. n .. " " .. (ctx.Inventory.Display[arg] or arg)
end
COMMANDS.becomehim = function(player)
	if not ctx.Monster then
		return "Not here."
	end
	if player:GetAttribute("Monster") or player:GetAttribute("MonsterPending") then
		ctx.Monster.adminRelease()
		return "You're you again. He hunts on his own."
	end
	local ok, why = ctx.Monster.canBuy(player)
	if not ok then
		return "Can't: " .. tostring(why)
	end
	return ctx.Monster.grant(player) and "You'll become him (now, or when the lights go)." or "Couldn't."
end
COMMANDS.rocketcredit = function(player)
	if ctx.Stats and ctx.Stats.addRocketCredit and ctx.Stats.addRocketCredit(player) then
		return "A saved rocket: it comes with your next night."
	end
	return "Couldn't (stats not loaded?)."
end
COMMANDS.revivecredit = function(player)
	if ctx.Stats and ctx.Stats.addReviveCredit(player) then
		return "A saved revive: offered the next time you die."
	end
	return "Couldn't (stats not loaded?)."
end

COMMANDS.events = function()
	return "Events: " .. table.concat(ctx.Director.adminEventIds(), ", ")
end

function Admin.start()
	local function mark(player: Player)
		if Admin.isAdmin(player) then
			player:SetAttribute("IsAdmin", true)
		end
	end
	-- the first time a pass holder's panel changes the night: everyone hears it pays nothing
	local function taint(player: Player, nightWide: boolean)
		if Admin.isAdmin(player) then
			return
		end
		player:SetAttribute("AdminUsed", true)
		if nightWide and not workspace:GetAttribute("AdminUsed") then
			workspace:SetAttribute("AdminUsed", true)
			for _, p in Players:GetPlayers() do
				ctx.Remotes.Notify:FireClient(p, player.DisplayName .. " is using the admin panel: no coins or records tonight.", "info")
			end
		end
		if ctx.Journey then
			ctx.Journey.event(player, "AdminPanel")
		end
	end
	for _, p in Players:GetPlayers() do
		mark(p)
	end
	Players.PlayerAdded:Connect(mark)
	ctx.Remotes.Admin.OnServerEvent:Connect(function(player, cmd, arg)
		local owner = Admin.isAdmin(player)
		if not owner and not Admin.hasPass(player) then
			return -- (not the owner and no pass: ignored)
		end
		if type(cmd) ~= "string" or (arg ~= nil and type(arg) ~= "string") then
			return
		end
		if not owner and (not ctx.Director or OWNER_ONLY[cmd]) then
			reply(player, "Not in the admin panel pass.")
			return
		end
		if not owner and cmd == "me" and arg == "revive" then
			reply(player, "Revives are Robux only.")
			return
		end
		if cmd == "info" and not ctx.Director then
			-- the lobby: only the coins tab
			ctx.Remotes.AdminReply:FireClient(player, nil, { Lobby = true })
			return
		elseif cmd == "info" then
			-- what the panel lists: rooms, events, endings, acts
			local rooms, seen = {}, {}
			for _, n in ctx.Layout.Nodes do
				if not seen[n.Room] then
					seen[n.Room] = true
					table.insert(rooms, n.Room)
				end
			end
			local endings = {}
			for k in ctx.Story.Endings do
				table.insert(endings, k)
			end
			table.sort(endings)
			ctx.Remotes.AdminReply:FireClient(player, nil, {
				Rooms = rooms,
				Events = ctx.Director.adminEventIds(),
				Endings = endings,
				Acts = ctx.Director.ActOrder,
				Limited = not owner or nil,
			})
			return
		end
		local fn = COMMANDS[cmd]
		if not fn then
			reply(player, "Unknown command.")
			return
		end
		if not owner and NIGHT_WIDE[cmd] and strangersHere(player) then
			reply(player, "Only with friends: someone in this server isn't your friend. (Your own tools still work: ME tab.)")
			return
		end
		local ok, result = pcall(fn, player, arg)
		if ok and not owner and cmd ~= "events" and inNight() then
			taint(player, NIGHT_WIDE[cmd] == true)
		end
		reply(player, ok and tostring(result or "Done.") or ("Error: " .. tostring(result)))
	end)
end

return Admin
