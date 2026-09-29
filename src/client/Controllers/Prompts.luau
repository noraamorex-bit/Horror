--[[
	Prompts — the diegetic interaction prompt (all server prompts use the Custom style).

	Keyboard/gamepad: the engine handles the key; we only draw.
	Touch: the whole prompt is a button. Press-and-hold it (InputHoldBegin/End) to interact.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")

local Prompts = {}
local ctx
local player = Players.LocalPlayer
local folder: ScreenGui

local GAMEPAD_LABEL = { ButtonX = "X", ButtonY = "Y", ButtonA = "A", ButtonB = "B" }

local function keyLabel(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
	if inputType == Enum.ProximityPromptInputType.Touch or ctx.UI.isTouch() then
		return prompt.HoldDuration > 0 and "HOLD" or "TAP"
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		return GAMEPAD_LABEL[prompt.GamepadKeyCode.Name] or prompt.GamepadKeyCode.Name
	end
	return prompt.KeyboardKeyCode.Name
end

local function build(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	local UI = ctx.UI
	local secondary = prompt.KeyboardKeyCode == Enum.KeyCode.R
	local touch = ctx.UI.isTouch() or inputType == Enum.ProximityPromptInputType.Touch
	local scale = touch and 1.25 or 1

	local bb = UI.new("BillboardGui", {
		Name = "Prompt",
		AlwaysOnTop = true,
		LightInfluence = 0,
		Size = UDim2.fromOffset(250 * scale, 54 * scale),
		StudsOffset = Vector3.new(0, secondary and -1.3 or 0.5, 0),
		Adornee = prompt.Parent,
		Active = true,
		Parent = folder,
	})
	local button = UI.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.35,
		Active = true,
		Parent = bb,
	})
	UI.corner(button, 10)
	UI.stroke(button, secondary and UI.Color.Info or UI.Color.Accent, 1.5, 0.45)
	local key = UI.new("Frame", {
		Size = UDim2.new(0, 44 * scale, 1, -12 * scale),
		Position = UDim2.fromOffset(6 * scale, 6 * scale),
		BackgroundColor3 = secondary and UI.Color.Info or UI.Color.Accent,
		BackgroundTransparency = 0.1,
		Parent = button,
	})
	UI.corner(key, 8)
	local keyText = UI.label({
		Size = UDim2.fromScale(1, 1),
		Text = keyLabel(prompt, inputType),
		Font = UI.Font.Bold,
		TextColor3 = Color3.fromRGB(20, 20, 20),
		TextScaled = true,
		Parent = key,
	})
	UI.new("UITextSizeConstraint", { MaxTextSize = 18 * scale, Parent = keyText })
	local action = UI.label({
		Size = UDim2.new(1, -62 * scale, 0.55, 0),
		Position = UDim2.fromOffset(56 * scale, 3 * scale),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = UI.Font.Bold,
		TextSize = 17 * scale,
		Text = prompt.ActionText,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = button,
	})
	local object = UI.label({
		Size = UDim2.new(1, -62 * scale, 0.4, 0),
		Position = UDim2.new(0, 56 * scale, 0.55, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = UI.Color.Dim,
		TextSize = 13 * scale,
		Text = prompt.ObjectText,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = button,
	})
	local bar = UI.new("Frame", {
		Size = UDim2.new(0, 0, 0, 3),
		Position = UDim2.new(0, 0, 1, -3),
		BackgroundColor3 = secondary and UI.Color.Info or UI.Color.Accent,
		Parent = button,
	})

	local conns = {}
	local holdTween: Tween? = nil
	local function refresh()
		action.Text = prompt.ActionText
		object.Text = prompt.ObjectText
		keyText.Text = keyLabel(prompt, inputType)
	end
	table.insert(conns, prompt:GetPropertyChangedSignal("ActionText"):Connect(refresh))
	table.insert(conns, prompt:GetPropertyChangedSignal("ObjectText"):Connect(refresh))
	table.insert(conns, prompt:GetPropertyChangedSignal("HoldDuration"):Connect(refresh))
	table.insert(conns, prompt.PromptButtonHoldBegan:Connect(function()
		if holdTween then
			holdTween:Cancel()
		end
		bar.Size = UDim2.new(0, 0, 0, 3)
		holdTween = TweenService:Create(bar, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), { Size = UDim2.new(1, 0, 0, 3) })
		holdTween:Play()
	end))
	table.insert(conns, prompt.PromptButtonHoldEnded:Connect(function()
		if holdTween then
			holdTween:Cancel()
		end
		bar.Size = UDim2.new(0, 0, 0, 3)
	end))
	table.insert(conns, prompt.Triggered:Connect(function()
		button.BackgroundTransparency = 0
		UI.tween(button, 0.3, { BackgroundTransparency = 0.35 })
	end))

	-- touch: press and hold the prompt itself
	local holding = false
	table.insert(conns, button.InputBegan:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then
			holding = true
			prompt:InputHoldBegin()
		end
	end))
	table.insert(conns, button.InputEnded:Connect(function(io)
		if holding and (io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1) then
			holding = false
			prompt:InputHoldEnd()
		end
	end))

	return function()
		if holding then
			pcall(function()
				prompt:InputHoldEnd()
			end)
		end
		for _, c in conns do
			c:Disconnect()
		end
		bb:Destroy()
	end
end

local function updateEnabled()
	local enabled = player:GetAttribute("InGame") == true
		and not player:GetAttribute("Hiding")
		and not player:GetAttribute("Captured")
		and not player:GetAttribute("Escaped")
		and not workspace:GetAttribute("EndingActive")
		and not ctx.UIOpen
	ProximityPromptService.Enabled = enabled
end

function Prompts.refresh()
	updateEnabled()
end

function Prompts.init(c)
	ctx = c
	ctx.Prompts = Prompts
end

function Prompts.start()
	folder = ctx.UI.new("ScreenGui", {
		Name = "HomeAlonePrompts",
		ResetOnSpawn = false,
		DisplayOrder = 4,
		Parent = ctx.UI.PlayerGui,
	})
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
			return
		end
		-- never show a prompt that's on your own body (e.g. "Cut free" while you're the captive)
		local char = player.Character
		if char and prompt:IsDescendantOf(char) then
			return
		end
		local cleanup = build(prompt, inputType)
		local conn
		conn = prompt.PromptHidden:Connect(function()
			conn:Disconnect()
			cleanup()
		end)
	end)
	for _, attr in { "InGame", "Hiding", "Captured", "Escaped" } do
		player:GetAttributeChangedSignal(attr):Connect(updateEnabled)
	end
	workspace:GetAttributeChangedSignal("EndingActive"):Connect(updateEnabled)
	updateEnabled()
end

return Prompts
