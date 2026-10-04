--[[
	Lobby (inside the house) — a small "waiting for your group" card before the night starts,
	then one notice with your role and an OK button.
	(In Studio / non-reserved servers the card has a READY button instead.)
]]

local Players = game:GetService("Players")

local Lobby = {}
local ctx
local player = Players.LocalPlayer

local card: Frame
local status: TextLabel
local readyButton: TextButton
local ready = false
local lastState = nil

local function render(state)
	lastState = state
	if not state then
		return
	end
	local inGame = player:GetAttribute("InGame") == true
	card.Visible = state.Phase ~= "InGame" and not inGame
	if state.Phase == "Arriving" then
		status.Text = state.Countdown and ("The night begins in " .. tostring(state.Countdown) .. "...")
			or string.format("Waiting for your friends...  %d / %d", state.Players or 0, state.Expected or state.Players or 1)
	elseif state.Phase == "Countdown" then
		status.Text = "The night begins in " .. tostring(state.Countdown) .. "..."
	elseif state.Phase == "InGame" then
		status.Text = "A night is under way. You'll join the next one."
	else
		status.Text = string.format("%d / %d ready", state.ReadyCount or 0, state.Players or 0)
	end
	ready = table.find(state.Ready or {}, player.UserId) ~= nil
	readyButton.Text = ready and "READY ✓" or "READY"
	readyButton.BackgroundColor3 = ready and Color3.fromRGB(70, 130, 80) or Color3.fromRGB(240, 236, 228)
	readyButton.TextColor3 = ready and Color3.new(1, 1, 1) or Color3.fromRGB(15, 15, 15)
	readyButton.Visible = state.Phase == "Waiting" or state.Phase == "Countdown"
end

local function showRole()
	local roleId = player:GetAttribute("Role")
	if not roleId then
		return
	end
	for _, r in ctx.Story.Roles do
		if r.Id == roleId then
			ctx.Notice.show({
				Title = "You are " .. r.Name,
				Body = r.Blurb .. "\n\n" .. r.Perk,
				Button = "OK",
			})
			return
		end
	end
end

function Lobby.init(c)
	ctx = c
end

function Lobby.start()
	local UI = ctx.UI
	card = UI.new("Frame", {
		Name = "Lobby",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(520, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.12,
		Parent = UI.Root,
	})
	UI.corner(card, 14)
	UI.stroke(card, Color3.new(1, 1, 1), 1.5, 0.75)
	UI.padding(card, 24)
	UI.modal(card)
	UI.new("UIListLayout", { Padding = UDim.new(0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
	UI.label({ Size = UDim2.new(1, 0, 0, 52), Text = ctx.Story.Title, Font = UI.Font.Title, TextSize = 40, LayoutOrder = 1, Parent = card })
	status = UI.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = "", TextSize = 24, LayoutOrder = 2, Parent = card })
	readyButton = UI.new("TextButton", {
		Size = UDim2.fromOffset(220, 64),
		Text = "READY",
		Font = UI.Font.Bold,
		TextSize = 26,
		BackgroundColor3 = Color3.fromRGB(240, 236, 228),
		LayoutOrder = 3,
		Visible = false,
		Parent = card,
	})
	UI.corner(readyButton, 12)
	readyButton.Activated:Connect(function()
		ctx.Remotes.Ready:FireServer(not ready)
	end)

	ctx.Remotes.Lobby.OnClientEvent:Connect(render)
	-- waiting outside before the night: third person; in the house: first person
	local function camera()
		if player:GetAttribute("InGame") then
			player.CameraMinZoomDistance = 0.5
			player.CameraMaxZoomDistance = 0.5
			player.CameraMode = Enum.CameraMode.LockFirstPerson
		else
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMaxZoomDistance = 22
			player.CameraMinZoomDistance = 9
		end
	end
	camera()
	player.CharacterAdded:Connect(function()
		task.defer(camera)
	end)
	player:GetAttributeChangedSignal("InGame"):Connect(function()
		render(lastState)
		camera()
	end)
	player:GetAttributeChangedSignal("Role"):Connect(showRole)
end

return Lobby
