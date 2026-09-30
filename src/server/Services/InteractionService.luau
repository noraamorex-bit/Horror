--[[
	InteractionService — every interactable in the house is a ProximityPrompt created here.
	Prompts use Roblox's default style; secondary (R) prompts are offset below the main one.

	Interaction.prompt(part, opts, callback(player, prompt)) -> ProximityPrompt
	opts: Action, Object, Hold, Distance, Key, LOS, AllowCaptured, AllowHiding, Name
]]

local Interaction = {}
local ctx

function Interaction.init(c)
	ctx = c
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
function Interaction.pickup(part: BasePart, item: string, opts, onTaken)
	opts = opts or {}
	local prompt
	prompt = Interaction.prompt(part, {
		Action = opts.Action or "Take",
		Object = opts.Object or item,
		Hold = opts.Hold or 0,
		Distance = opts.Distance or 7,
		Offset = opts.Offset,
	}, function(player)
		ctx.Audio.playAt("Pickup", part.Position, { Caption = false })
		ctx.Inventory.give(player, item, opts.Count or 1)
		ctx.Audio.caption("Picked up: " .. (opts.Object or item), nil, nil, { player })
		if onTaken then
			onTaken(player)
		end
		if opts.Keep then
			-- a drawer or cupboard stays put; only the prompt goes
			prompt:Destroy()
		else
			local target = opts.Destroy or part
			target:Destroy()
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
