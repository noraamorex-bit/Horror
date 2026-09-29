--[[
	Lobby — title card, who's ready, the Ready button, and your role card when the
	night starts.
]]

local Players = game:GetService("Players")

local Lobby = {}
local ctx
local player = Players.LocalPlayer

local panel: Frame
local status: TextLabel
local roster: TextLabel
local readyButton: TextButton
local controls: TextLabel
local ready = false
local lastState = nil

local function controlsText(): string
	if ctx.UI.isTouch() then
		return "Left stick to move · drag to look · tap prompts to interact\nSPRINT / CROUCH / LIGHT / SPRAY buttons on the right · JOURNAL and PHONE at the top"
	end
	return "WASD move · E interact · R lock/unlock · Shift sprint · C crouch · F flashlight\nG pepper spray · P phone · Tab journal · Space hold breath / struggle"
end

local function render(state)
	lastState = state
	if not state then
		return
	end
	local inGame = player:GetAttribute("InGame") == true
	panel.Visible = state.Phase ~= "InGame" and not inGame
	local names = {}
	for _, p in Players:GetPlayers() do
		local isReady = table.find(state.Ready or {}, p.UserId) ~= nil
		table.insert(names, (isReady and "<font color=\"#78c878\">●</font> " or "<font color=\"#8a8a8a\">○</font> ") .. p.DisplayName)
	end
	roster.Text = table.concat(names, "\n")
	if state.Phase == "Arriving" then
		status.Text = state.Countdown and ("Everyone's here. The night begins in " .. tostring(state.Countdown) .. "...")
			or string.format("Waiting for your group: %d / %d here", state.Players or 0, state.Expected or state.Players or 1)
	elseif state.Phase == "Countdown" then
		status.Text = "The night begins in " .. tostring(state.Countdown) .. "..."
	elseif state.Phase == "InGame" then
		status.Text = "A night is under way. You'll join the next one."
	else
		status.Text = string.format("%d / %d ready  ·  2-4 players recommended", state.ReadyCount or 0, state.Players or 0)
	end
	ready = table.find(state.Ready or {}, player.UserId) ~= nil
	readyButton.Text = ready and "READY ✓" or "READY"
	readyButton.BackgroundColor3 = ready and Color3.fromRGB(60, 120, 70) or ctx.UI.Color.Accent
	readyButton.Visible = state.Phase ~= "InGame" and state.Phase ~= "Arriving"
	controls.Text = controlsText()
end

local function showRole()
	local roleId = player:GetAttribute("Role")
	if not roleId then
		return
	end
	local role
	for _, r in ctx.Story.Roles do
		if r.Id == roleId then
			role = r
		end
	end
	if not role then
		return
	end
	local UI = ctx.UI
	local card = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.62, 0),
		Size = UDim2.fromOffset(560, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.2,
		Parent = UI.Root,
	})
	UI.corner(card, 10)
	UI.padding(card, 16)
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), Parent = card })
	UI.label({ Size = UDim2.new(1, 0, 0, 30), Text = "You are " .. role.Name, Font = UI.Font.Title, TextSize = 28, Parent = card })
	UI.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = role.Blurb, TextSize = 16, TextColor3 = UI.Color.Dim, Parent = card })
	UI.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = "<b>" .. roleId .. ":</b> " .. role.Perk, TextSize = 16, TextColor3 = UI.Color.Accent, Parent = card })
	task.delay(11, function()
		UI.tween(card, 1, { BackgroundTransparency = 1 })
		for _, d in card:GetDescendants() do
			if d:IsA("TextLabel") then
				UI.tween(d, 1, { TextTransparency = 1 })
			end
		end
		task.wait(1)
		card:Destroy()
	end)
end

function Lobby.init(c)
	ctx = c
end

function Lobby.start()
	local UI = ctx.UI
	panel = UI.new("Frame", {
		Name = "Lobby",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(620, 470),
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.12,
		Parent = UI.Root,
	})
	UI.corner(panel, 12)
	UI.stroke(panel, UI.Color.Accent, 1, 0.7)
	UI.modal(panel)
	UI.label({ Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 60), Text = ctx.Story.Title, Font = UI.Font.Title, TextSize = 56, Parent = panel })
	UI.label({ Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 22), Text = ctx.Story.Address .. "  ·  Friday, November  ·  8:47 PM", TextSize = 16, TextColor3 = UI.Color.Dim, Parent = panel })
	UI.label({
		Position = UDim2.fromOffset(40, 112),
		Size = UDim2.new(1, -80, 0, 60),
		Text = "Jamie's parents are away for the weekend. Three friends came over for pizza and a movie.\nSomebody else is already in the house.",
		TextSize = 16,
		Parent = panel,
	})
	roster = UI.label({ Position = UDim2.fromOffset(40, 182), Size = UDim2.new(1, -80, 0, 100), Text = "", TextSize = 17, TextYAlignment = Enum.TextYAlignment.Top, Parent = panel })
	status = UI.label({ Position = UDim2.fromOffset(40, 290), Size = UDim2.new(1, -80, 0, 22), Text = "", TextSize = 16, TextColor3 = UI.Color.Accent, Parent = panel })
	readyButton = UI.new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 322),
		Size = UDim2.fromOffset(240, 54),
		Text = "READY",
		Font = UI.Font.Bold,
		TextSize = 22,
		TextColor3 = Color3.fromRGB(20, 20, 20),
		BackgroundColor3 = UI.Color.Accent,
		Parent = panel,
	})
	UI.corner(readyButton, 10)
	readyButton.Activated:Connect(function()
		ctx.Remotes.Ready:FireServer(not ready)
	end)
	controls = UI.label({ Position = UDim2.fromOffset(24, 392), Size = UDim2.new(1, -48, 0, 60), Text = controlsText(), TextSize = 13, TextColor3 = UI.Color.Dim, Parent = panel })

	ctx.Remotes.Lobby.OnClientEvent:Connect(render)
	player:GetAttributeChangedSignal("InGame"):Connect(function()
		render(lastState)
	end)
	player:GetAttributeChangedSignal("Role"):Connect(showRole)
	ctx.UI.onTouchChanged(function()
		controls.Text = controlsText()
	end)
end

return Lobby
