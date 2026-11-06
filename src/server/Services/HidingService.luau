--[[
	HidingService — closets, wardrobes, under beds, behind shower curtains.

	Hiding.register(part, {Name, Room, Inside: CFrame, View: CFrame, Exit: CFrame, Peek: CFrame?})
	While hidden, the player's root is anchored at Inside; the client switches to a fixed
	peek camera at View (published via the "HideView" attribute).

	PEEK (v147, hold R / the PEEK button): the eye leans out to Peek ("HidePeek"; by default
	View moved Config.Hiding.PeekOut studs towards the way out), a wardrobe's doors ease open a
	crack, and "Peeking" is set. While peeking he can see you (Intruder: Perception.peekSeen).
]]

local Anim = require(script.Parent.Parent.World.Anim)

local Hiding = {}
local ctx

-- how long you can hold your breath (the Silent Steps pass, v108: 50% longer)
local function breathMax(player: Player): number
	return ctx.Config.Hiding.HoldBreathMax * (player:GetAttribute("Pass_Silent") and 1.5 or 1)
end

Hiding._breathMax = function(p: Player) return breathMax(p) end -- (tests)

local spots = {} -- list
local occupantOf = {} -- spot -> player
local spotOf = {} -- player -> spot
local breath = {} -- player -> seconds of breath remaining
local hiddenLook = {} -- player -> { [instance] = original Transparency }
local peekAt = {} -- player -> os.clock() of the last peek change (rate limit)

-- tucked away: nothing of the character pokes out through the bed or the closet door
local function setHidden(player: Player, hidden: boolean)
	local char = player.Character
	if hidden then
		if not char then
			return
		end
		local saved = {}
		for _, d in char:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				saved[d] = d.Transparency
				d.Transparency = 1
			end
		end
		hiddenLook[player] = saved
	else
		local saved = hiddenLook[player]
		hiddenLook[player] = nil
		if saved then
			for d, t in saved do
				if d.Parent then
					d.Transparency = t
				end
			end
		end
	end
end

function Hiding.init(c)
	ctx = c
end

function Hiding.reset()
	for p in spotOf do
		p:SetAttribute("Hiding", nil)
		p:SetAttribute("HideView", nil)
		p:SetAttribute("HidePeek", nil)
		p:SetAttribute("Peeking", nil)
		setHidden(p, false)
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
	-- where the eye goes when you lean out: towards the way out, not past it
	if opts.Peek then
		spot.Peek = opts.Peek
	else
		local out = (opts.Exit.Position - spot.View.Position) * Vector3.new(1, 0, 1)
		local dist = math.clamp(out.Magnitude - 0.4, 0, ctx.Config.Hiding.PeekOut or 1.5)
		spot.Peek = out.Magnitude > 0.1 and (spot.View + out.Unit * dist) or spot.View
	end
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

-- what getting in (or out) sounds like: bed springs, a closet door, a shower curtain
function Hiding.sound(spot, entering: boolean): string
	local n = string.lower(spot.Name or "")
	if n:find("bed") or n:find("stairs") then
		return "BedCreak"
	elseif n:find("curtain") then
		return "ClosetClose"
	end
	return entering and "ClosetOpen" or "ClosetClose"
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
	ctx.Util.unseat(player)
	player:SetAttribute("NightHides", (tonumber(player:GetAttribute("NightHides")) or 0) + 1)
	occupantOf[spot] = player
	spotOf[player] = spot
	breath[player] = breathMax(player)
	ctx.PlayerState.setFrozen(player, true)
	char:PivotTo(spot.Inside)
	setHidden(player, true)
	player:SetAttribute("HidePeek", spot.Peek)
	player:SetAttribute("HideView", spot.View)
	player:SetAttribute("Hiding", spot.Name)
	spot.Prompt.Enabled = false
	ctx.Audio.playAt(Hiding.sound(spot, true), spot.Position, { Caption = false, Volume = 0.45 })
	Anim.leaves(spot.Part.Parent, 0.25)
	ctx.Noise.emit(spot.Position, 8, "Hide", player)
	if ctx.Intruder then
		ctx.Intruder.onPlayerHid(player, spot)
	end
	if ctx.Director and ctx.Director.onHide then
		ctx.Director.onHide(player)
	end
end

function Hiding.exit(player: Player, forced: boolean?)
	local spot = spotOf[player]
	if not spot then
		return
	end
	if player:GetAttribute("Peeking") then
		Anim.ajar(spot.Part.Parent, false, nil, true)
	end
	occupantOf[spot] = nil
	spotOf[player] = nil
	player:SetAttribute("Hiding", nil)
	player:SetAttribute("HideView", nil)
	player:SetAttribute("HidePeek", nil)
	player:SetAttribute("Peeking", nil)
	player:SetAttribute("HoldingBreath", nil)
	spot.Prompt.Enabled = true
	setHidden(player, false)
	local char = player.Character
	if char and not forced then
		ctx.Audio.playAt(Hiding.sound(spot, false), spot.Position, { Caption = false, Volume = 0.45 })
		Anim.leaves(spot.Part.Parent, 0.45)
		ctx.PlayerState.placeStanding(player, spot.Exit)
		ctx.PlayerState.setFrozen(player, false)
	end
end

-- lean out (or back in). Not while he's listening right at your spot (the heartbeat): the
-- client doesn't offer it then either
function Hiding.peek(player: Player, on: boolean)
	local spot = spotOf[player]
	if not spot then
		return
	end
	on = on == true
	if on == (player:GetAttribute("Peeking") == true) then
		return
	end
	if on and (os.clock() - (peekAt[player] or 0) < 0.25 or (ctx.Heartbeat and ctx.Heartbeat.isActive(player))) then
		return
	end
	peekAt[player] = os.clock()
	player:SetAttribute("Peeking", on or nil)
	local model = spot.Part.Parent
	Anim.ajar(model, on, ctx.Config.Hiding.PeekAjar)
	if on then
		-- (a soft creak only you and anyone right there hear: not a noise he comes for)
		ctx.Audio.playAt(Hiding.sound(spot, true), spot.Position, { Caption = false, Volume = 0.14, Pitch = 1.25, Range = 10 })
		if ctx.Journey then
			ctx.Journey.count(player, "Peeks")
		end
	end
end

-- the point he has to see to catch you peeking
function Hiding.peekPoint(player: Player): Vector3?
	local spot = spotOf[player]
	if not spot or not player:GetAttribute("Peeking") then
		return nil
	end
	return spot.Peek.Position
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
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		if spotOf[p] then
			Hiding.exit(p, true)
		end
		breath[p] = nil
		hiddenLook[p] = nil
		peekAt[p] = nil
	end)
	ctx.Remotes.Peek.OnServerEvent:Connect(function(player, on)
		Hiding.peek(player, on == true)
	end)
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
						ctx.Audio.playAt("Gasp", spot.Position, { CaptionText = "[A sharp gasp]", Range = 20 })
						ctx.Noise.emit(spot.Position, 18, "Gasp", player)
					end
				else
					b = math.min(breathMax(player), b + dt / ctx.Config.Hiding.HoldBreathRecover)
				end
				breath[player] = b
				player:SetAttribute("Breath", b / breathMax(player))
			end
		end
	end)
end

return Hiding
