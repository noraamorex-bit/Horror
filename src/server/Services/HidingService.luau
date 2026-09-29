--[[
	HidingService — closets, wardrobes, under beds, behind shower curtains.

	Hiding.register(part, {Name, Room, Inside: CFrame, View: CFrame, Exit: CFrame})
	While hidden, the player's root is anchored at Inside; the client switches to a fixed
	peek camera at View (published via the "HideView" attribute).
]]

local Hiding = {}
local ctx

local spots = {} -- list
local occupantOf = {} -- spot -> player
local spotOf = {} -- player -> spot
local breath = {} -- player -> seconds of breath remaining

function Hiding.init(c)
	ctx = c
end

function Hiding.reset()
	for p in spotOf do
		p:SetAttribute("Hiding", nil)
		p:SetAttribute("HideView", nil)
	end
	spots = {}
	occupantOf = {}
	spotOf = {}
end

function Hiding.register(part: BasePart, opts)
	local spot = {
		Name = opts.Name,
		Room = opts.Room,
		Part = part,
		Inside = opts.Inside,
		View = opts.View or opts.Inside * CFrame.new(0, 1.5, 0),
		Exit = opts.Exit,
		Position = opts.Inside.Position,
	}
	table.insert(spots, spot)
	spot.Prompt = ctx.Interaction.prompt(part, {
		Name = "Hide",
		Action = "Hide",
		Object = opts.Name,
		Distance = 6,
		Hold = 0.4,
		Offset = opts.PromptOffset,
	}, function(player)
		if occupantOf[spot] then
			ctx.Audio.caption("Someone's already in there.", nil, nil, { player })
			return
		end
		Hiding.enter(player, spot)
	end)
	return spot
end

function Hiding.enter(player: Player, spot)
	local char = player.Character
	local root = ctx.Util.getRoot(player)
	if not char or not root then
		return
	end
	if player:GetAttribute("FlashlightOn") then
		ctx.PlayerState.setFlashlight(player, false)
	end
	occupantOf[spot] = player
	spotOf[player] = spot
	breath[player] = ctx.Config.Hiding.HoldBreathMax
	ctx.PlayerState.setFrozen(player, true)
	char:PivotTo(spot.Inside)
	player:SetAttribute("HideView", spot.View)
	player:SetAttribute("Hiding", spot.Name)
	spot.Prompt.Enabled = false
	ctx.Noise.emit(spot.Position, 8, "Hide", player)
	if ctx.Intruder then
		ctx.Intruder.onPlayerHid(player, spot)
	end
end

function Hiding.exit(player: Player, forced: boolean?)
	local spot = spotOf[player]
	if not spot then
		return
	end
	occupantOf[spot] = nil
	spotOf[player] = nil
	player:SetAttribute("Hiding", nil)
	player:SetAttribute("HideView", nil)
	player:SetAttribute("HoldingBreath", nil)
	spot.Prompt.Enabled = true
	local char = player.Character
	if char and not forced then
		char:PivotTo(spot.Exit)
		ctx.PlayerState.setFrozen(player, false)
	end
end

function Hiding.spotOf(player: Player)
	return spotOf[player]
end

function Hiding.occupant(spot): Player?
	return occupantOf[spot]
end

function Hiding.spotsNear(pos: Vector3, radius: number)
	local out = {}
	for _, s in spots do
		if (s.Position - pos).Magnitude <= radius then
			table.insert(out, s)
		end
	end
	return out
end

function Hiding.all()
	return spots
end

function Hiding.isHoldingBreath(player: Player): boolean
	return player:GetAttribute("HoldingBreath") == true
end

function Hiding.start()
	ctx.Remotes.Hide.OnServerEvent:Connect(function(player, action)
		if action == "Exit" then
			Hiding.exit(player)
		end
	end)
	ctx.Remotes.HoldBreath.OnServerEvent:Connect(function(player, holding)
		if not spotOf[player] then
			return
		end
		if holding and (breath[player] or 0) > 0.5 then
			player:SetAttribute("HoldingBreath", true)
		else
			player:SetAttribute("HoldingBreath", nil)
		end
	end)
	-- breath bookkeeping
	task.spawn(function()
		while true do
			local dt = task.wait(0.2)
			for player, spot in spotOf do
				local b = breath[player] or 0
				if player:GetAttribute("HoldingBreath") then
					b -= dt
					if b <= 0 then
						b = 0
						player:SetAttribute("HoldingBreath", nil)
						-- gasp!
						ctx.Audio.playAt("Breathing", spot.Position, { CaptionText = "[A sharp gasp]", Range = 20, Duration = 2 })
						ctx.Noise.emit(spot.Position, 18, "Gasp", player)
					end
				else
					b = math.min(ctx.Config.Hiding.HoldBreathMax, b + dt / ctx.Config.Hiding.HoldBreathRecover)
				end
				breath[player] = b
				player:SetAttribute("Breath", b / ctx.Config.Hiding.HoldBreathMax)
			end
		end
	end)
end

return Hiding
