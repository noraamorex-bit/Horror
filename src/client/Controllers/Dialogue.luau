--[[
	Dialogue — the conversation box at the bottom of the screen.

	The server sends one line at a time: who is speaking, the text (typed out), and on the last
	line of a turn two things you could say back. Only the player who answered picks; everyone
	else reads along. Press 1 / 2 or tap a choice.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Dialogue = {}
local ctx
local player = Players.LocalPlayer

local panel: Frame
local speakerLabel: TextLabel
local textLabel: TextLabel
local choiceFrame: Frame
local waitingLabel: TextLabel
local buttons: { TextButton } = {}
local open = false
local typing = 0
local canChoose = false

local NPC_COLOR = Color3.fromRGB(245, 245, 245)
local YOU_COLOR = Color3.fromRGB(190, 190, 190)
local FRIEND_COLOR = Color3.fromRGB(220, 220, 220)

local ambient = false -- friends talking among themselves: the controls stay up

function Dialogue.isOpen(): boolean
	return open
end

-- a real conversation (someone at the door) takes over the bottom of the screen
function Dialogue.blocksControls(): boolean
	return open and not ambient
end

local function choose(i: number)
	if not canChoose or not buttons[i].Visible then
		return
	end
	canChoose = false
	for _, b in buttons do
		b.AutoButtonColor = false
	end
	buttons[i].BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	ctx.Remotes.DialogueChoice:FireServer(i)
end

local function typeOut(text: string)
	typing += 1
	local mine = typing
	textLabel.Text = text
	textLabel.MaxVisibleGraphemes = 0
	task.spawn(function()
		local n = utf8.len(text) or #text
		local shown = 0
		while shown < n and typing == mine do
			shown = math.min(n, shown + 2)
			textLabel.MaxVisibleGraphemes = shown
			task.wait(0.025)
		end
		if typing == mine then
			textLabel.MaxVisibleGraphemes = -1
		end
	end)
end

local function show(line)
	local wasBlocking = Dialogue.blocksControls()
	task.defer(function()
		if ctx.MobileControls and Dialogue.blocksControls() ~= wasBlocking then
			ctx.MobileControls.refresh()
		end
	end)
	if not line then
		open = false
		ambient = false
		canChoose = false
		ctx.UI.tween(panel, 0.25, { BackgroundTransparency = 1 })
		task.delay(0.25, function()
			if not open then
				panel.Visible = false
			end
		end)
		return
	end
	open = true
	ambient = line.Ambient == true
	panel.Visible = true
	panel.BackgroundTransparency = 0.12
	-- friends' chatter sits a little higher and narrower, clear of the touch buttons
	if ambient then
		panel.Position = UDim2.new(0.5, 0, 1, ctx.UI.isTouch() and -190 or -120)
		panel.Size = UDim2.new(ctx.UI.isTouch() and 0.5 or 0.56, 0, 0, 0)
	else
		panel.Position = UDim2.new(0.5, 0, 1, -28)
		panel.Size = UDim2.new(0.62, 0, 0, 0)
	end
	local mine = line.ChooserId == player.UserId
	if line.Ambient then
		local me = line.SpeakerId == player.UserId
		speakerLabel.Text = me and "YOU" or string.upper(line.Speaker or "")
		speakerLabel.TextColor3 = me and YOU_COLOR or FRIEND_COLOR
		textLabel.Font = ctx.UI.Font.Body
		textLabel.TextColor3 = Color3.fromRGB(235, 235, 228)
	elseif line.IsPlayer then
		speakerLabel.Text = mine and "YOU" or string.upper(line.Speaker or "")
		speakerLabel.TextColor3 = YOU_COLOR
		textLabel.Font = ctx.UI.Font.Body
		textLabel.TextColor3 = Color3.fromRGB(215, 225, 240)
	elseif line.Speaker == "" then
		speakerLabel.Text = ""
		textLabel.Font = Enum.Font.GothamMedium
		textLabel.TextColor3 = Color3.fromRGB(175, 170, 162)
	else
		speakerLabel.Text = string.upper(line.Speaker)
		speakerLabel.TextColor3 = NPC_COLOR
		textLabel.Font = ctx.UI.Font.Body
		textLabel.TextColor3 = Color3.fromRGB(240, 236, 228)
	end
	speakerLabel.Visible = speakerLabel.Text ~= ""
	typeOut((line.IsPlayer or line.Ambient) and ("\"" .. line.Text .. "\"") or line.Text)
	-- choices
	local choices = line.Choices
	canChoose = choices ~= nil and mine
	choiceFrame.Visible = choices ~= nil and mine
	waitingLabel.Visible = choices ~= nil and not mine
	if choices and not mine then
		waitingLabel.Text = (line.ChooserName or "Someone") .. " is answering..."
	end
	for i, b in buttons do
		local c = choices and choices[i]
		b.Visible = c ~= nil
		b.AutoButtonColor = true
		b.BackgroundColor3 = Color3.fromRGB(34, 32, 30)
		if c then
			b.Text = i .. ".  " .. c
		end
	end
end

function Dialogue.init(c)
	ctx = c
	ctx.Dialogue = Dialogue
end

function Dialogue.start()
	local UI = ctx.UI
	panel = UI.new("Frame", {
		Name = "Dialogue",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -28),
		Size = UDim2.new(0.62, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(10, 9, 9),
		BackgroundTransparency = 0.12,
		Visible = false,
		ZIndex = 20,
		Parent = UI.Root,
	})
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(820, math.huge), MinSize = Vector2.new(420, 0), Parent = panel })
	UI.corner(panel, 12)
	UI.stroke(panel, Color3.new(1, 1, 1), 1, 0.8)
	UI.padding(panel, 16)
	UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	speakerLabel = UI.label({
		Size = UDim2.new(1, 0, 0, 22),
		Text = "",
		Font = UI.Font.Bold,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		ZIndex = 21,
		Parent = panel,
	})
	textLabel = UI.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		TextSize = 26,
		TextWrapped = true,
		RichText = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
		ZIndex = 21,
		Parent = panel,
	})
	choiceFrame = UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Visible = false,
		ZIndex = 21,
		Parent = panel,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = choiceFrame })
	for i = 1, 2 do
		local b = UI.new("TextButton", {
			Name = "Choice" .. i,
			Size = UDim2.new(1, 0, 0, 54),
			BackgroundColor3 = Color3.fromRGB(34, 32, 30),
			Text = "",
			Font = UI.Font.Bold,
			TextSize = 22,
			TextColor3 = Color3.fromRGB(245, 236, 220),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = i,
			ZIndex = 22,
			Parent = choiceFrame,
		})
		UI.corner(b, 8)
		UI.stroke(b, Color3.new(1, 1, 1), 1, 0.7)
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = b })
		-- Activated only fires for a deliberate tap or click, never a camera drag across it
		b.Activated:Connect(function()
			choose(i)
		end)
		buttons[i] = b
	end
	waitingLabel = UI.label({
		Size = UDim2.new(1, 0, 0, 22),
		Text = "",
		TextSize = 18,
		TextColor3 = UI.Color.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 4,
		Visible = false,
		ZIndex = 21,
		Parent = panel,
	})
	UserInputService.InputBegan:Connect(function(io, processed)
		if processed or not canChoose then
			return
		end
		if io.KeyCode == Enum.KeyCode.One or io.KeyCode == Enum.KeyCode.ButtonX then
			choose(1)
		elseif io.KeyCode == Enum.KeyCode.Two or io.KeyCode == Enum.KeyCode.ButtonY then
			choose(2)
		end
	end)
	ctx.Remotes.Dialogue.OnClientEvent:Connect(show)
end

return Dialogue
