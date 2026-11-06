--[[
	InteractionService — every interactable in the house is a ProximityPrompt created here.
	Prompts use Roblox's default style; secondary (R) prompts are offset below the main one.

	Interaction.prompt(part, opts, callback(player, prompt)) -> ProximityPrompt
	opts: Action, Object, Hold, Distance, Key, LOS, AllowCaptured, AllowHiding, Name
]]

local Anim = require(script.Parent.Parent.World.Anim)
local ActPose: any = nil -- (loaded in init: shared ActPose)

local Interaction = {}
local ctx

function Interaction.init(c)
	ctx = c
	ActPose = c.ActPose or require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ActPose"))
end

local function blocked(player: Player, opts): boolean
	if not player:GetAttribute("InGame") then
		return true
	end
	if player:GetAttribute("Escaped") then
		return true
	end
	if player:GetAttribute("Captured") and not opts.AllowCaptured then
		return true
	end
	if player:GetAttribute("Hiding") and not opts.AllowHiding then
		return true
	end
	if ctx.Ending and ctx.Ending.isOver() then
		return true
	end
	return false
end

--[[
	v147: what your body does while you use something (shared ActPose; client Actions poses it on
	every screen). Player attributes: "Act" = kind, "ActAt" = server time it began, "ActHold" while a
	hold prompt is held. One-shots clear themselves after their time.
]]
local actSeq = {}
function Interaction.act(player: Player, kind: string?, hold: boolean?)
	local def = kind and ActPose.Kinds[kind]
	if not def or not player:GetAttribute("InGame") or player:GetAttribute("Hiding") then
		return
	end
	actSeq[player] = (actSeq[player] or 0) + 1
	local seq = actSeq[player]
	player:SetAttribute("Act", kind)
	player:SetAttribute("ActAt", workspace:GetServerTimeNow())
	player:SetAttribute("ActHold", hold or nil)
	if not hold then
		task.delay(def.Time + 0.1, function()
			if actSeq[player] == seq then
				player:SetAttribute("Act", nil)
				player:SetAttribute("ActHold", nil)
			end
		end)
	end
end

-- let go of a hold (finished or not): the pose winds down over its Time
function Interaction.release(player: Player, kind: string?)
	if player:GetAttribute("Act") ~= kind or not player:GetAttribute("ActHold") then
		return
	end
	local def = ActPose.Kinds[kind :: string]
	actSeq[player] = (actSeq[player] or 0) + 1
	local seq = actSeq[player]
	player:SetAttribute("ActHold", nil)
	task.delay((def and def.Time or 0.3) + 0.1, function()
		if actSeq[player] == seq then
			player:SetAttribute("Act", nil)
		end
	end)
end

function Interaction.start()
	local PPS = game:GetService("ProximityPromptService")
	PPS.PromptButtonHoldBegan:Connect(function(prompt, player)
		local kind = ActPose.kindFor(prompt.ActionText)
		local def = kind and ActPose.Kinds[kind]
		if def and def.Hold then
			Interaction.act(player, kind, true)
		end
	end)
	PPS.PromptButtonHoldEnded:Connect(function(prompt, player)
		Interaction.release(player, ActPose.kindFor(prompt.ActionText))
	end)
	PPS.PromptTriggered:Connect(function(prompt, player)
		local kind = ActPose.kindFor(prompt.ActionText)
		local def = kind and ActPose.Kinds[kind]
		if not def then
			return
		end
		if def.Hold then
			if player:GetAttribute("ActHold") and player:GetAttribute("Act") == kind then
				Interaction.release(player, kind)
			else
				-- (a hold kind on a quick prompt: a short burst of it)
				Interaction.act(player, kind, true)
				Interaction.release(player, kind)
			end
		else
			Interaction.act(player, kind)
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		actSeq[p] = nil
	end)
end

function Interaction.prompt(parent: Instance, opts, callback)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = opts.Name or "Interact"
	prompt.ActionText = opts.Action or "Use"
	prompt.ObjectText = opts.Object or ""
	prompt.HoldDuration = opts.Hold or 0
	-- a little extra reach: phones and big rooms make "just out of range" frustrating
	prompt.MaxActivationDistance = (opts.Distance or 7) + 1.5
	prompt.KeyboardKeyCode = opts.Key or Enum.KeyCode.E
	prompt.GamepadKeyCode = opts.Key == Enum.KeyCode.R and Enum.KeyCode.ButtonY or Enum.KeyCode.ButtonX
	prompt.RequiresLineOfSight = if opts.LOS == nil then false else opts.LOS
	-- Roblox's standard prompt: familiar to players and properly tap-safe on phones
	prompt.Style = Enum.ProximityPromptStyle.Default
	if opts.Key == Enum.KeyCode.R then
		-- secondary actions (lock, splice, smash...) sit just below the main prompt
		prompt.UIOffset = Vector2.new(0, 80)
	end
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	if opts.Offset then
		local att = Instance.new("Attachment")
		att.Name = "PromptAttachment"
		att.Position = opts.Offset
		att.Parent = parent
		prompt.Parent = att
	else
		prompt.Parent = parent
	end
	local busy = false
	prompt.Triggered:Connect(function(player)
		if busy or blocked(player, opts) then
			return
		end
		busy = true
		local ok, err = pcall(callback, player, prompt)
		busy = false
		if not ok then
			warn("[Interaction] " .. prompt.ObjectText .. " / " .. prompt.ActionText .. ": " .. tostring(err))
		end
	end)
	return prompt
end

-- A readable document (fires the reader UI). onRead(player, firstTime) is optional.
function Interaction.document(part: BasePart, docId: string, opts, onRead)
	opts = opts or {}
	local readers = {}
	return Interaction.prompt(part, {
		Action = opts.Action or "Read",
		Object = opts.Object or ctx.Story.Documents[docId].Title,
		Distance = opts.Distance or 7,
		Offset = opts.Offset,
		Key = opts.Key,
	}, function(player)
		ctx.Remotes.Document:FireClient(player, docId)
		local first = not readers[player]
		readers[player] = true
		if ctx.Director and ctx.Director.onDocument then
			ctx.Director.onDocument(player, docId)
		end
		if onRead then
			onRead(player, first)
		end
	end)
end

-- A pickup: gives item(s), destroys the world part (or a whole model).
-- what picking something up sounds like (keys jingle, a drawer slides, tape tears...)
local PICKUP_SOUND = {
	CarKeys = "KeysJingle",
	HouseKeys = "KeysJingle",
	BasementKey = "KeysJingle",
	Scissors = "ScissorsSnip",
	ElectricalTape = "TapeRip",
	Batteries = "SwitchClick",
	Walkie = "WalkieChirp",
}
function Interaction.pickupSound(item: string, action: string?): string
	if PICKUP_SOUND[item] then
		return PICKUP_SOUND[item]
	end
	if action == "Search" then
		return "DrawerOpen"
	end
	return "Pickup"
end

function Interaction.pickup(part: BasePart, item: string, opts, onTaken)
	opts = opts or {}
	local prompt
	prompt = Interaction.prompt(part, {
		Action = opts.Action or "Take",
		Object = opts.Object or item,
		Hold = opts.Hold or 0,
		Distance = opts.Distance or 7,
		Offset = opts.Offset,
		Key = opts.Key,
	}, function(player)
		ctx.Audio.playAt(opts.Sound or Interaction.pickupSound(item, opts.Action), part.Position, { Caption = false })
		ctx.Inventory.give(player, item, opts.Count or 1)
		ctx.Audio.caption("Picked up: " .. (opts.Object or item), nil, nil, { player })
		if onTaken then
			onTaken(player)
		end
		if opts.Keep then
			-- a drawer or cupboard stays put; only the prompt goes
			prompt:Destroy()
		else
			-- it lifts a little and fades away rather than blinking out
			prompt:Destroy()
			Anim.vanish(opts.Destroy or part)
		end
	end)
	return prompt
end

-- Prevent a prompt from being triggered (used for dynamic availability)
function Interaction.setEnabled(prompt: ProximityPrompt, enabled: boolean)
	if prompt then
		prompt.Enabled = enabled
	end
end

return Interaction
