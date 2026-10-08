--[[
	AdminService — the owner's test panel. Skip and replay acts, fire any event or ending, call
	help, boss the intruder around, teleport, give yourself items, become invisible to him.

	Only for the people in Config.Admins (and the experience's owner, and anyone in Studio).
	Every command is checked here, on the server, against the player's UserId: the client panel
	only exists for admins, but even a hand-made remote call from anyone else does nothing.
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

local ITEMS = { "Flashlight", "Walkie", "PepperSpray", "HouseKeys", "CarKeys", "BasementKey", "ElectricalTape", "Poker", "Multitool", "Scissors", "Batteries" }

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
		return "Night started (" .. (arg == "Hard" and "Hard" or "Normal") .. ")."
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
		for _, item in ITEMS do
			if not ctx.Inventory.has(player, item) then
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
COMMANDS.events = function()
	return "Events: " .. table.concat(ctx.Director.adminEventIds(), ", ")
end

function Admin.start()
	local function mark(player: Player)
		if Admin.isAdmin(player) then
			player:SetAttribute("IsAdmin", true)
		end
	end
	for _, p in Players:GetPlayers() do
		mark(p)
	end
	Players.PlayerAdded:Connect(mark)
	ctx.Remotes.Admin.OnServerEvent:Connect(function(player, cmd, arg)
		if not Admin.isAdmin(player) then
			return -- (not the owner: ignored)
		end
		if type(cmd) ~= "string" or (arg ~= nil and type(arg) ~= "string") then
			return
		end
		if cmd == "info" then
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
			})
			return
		end
		local fn = COMMANDS[cmd]
		if not fn then
			reply(player, "Unknown command.")
			return
		end
		local ok, result = pcall(fn, player, arg)
		reply(player, ok and tostring(result or "Done.") or ("Error: " .. tostring(result)))
	end)
end

return Admin
