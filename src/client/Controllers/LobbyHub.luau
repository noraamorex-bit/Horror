--[[
	LobbyHub — the lobby place's UI: title, how to queue, your circle's status with a LEAVE
	button (big enough for thumbs), and the loading screen shown while teleporting.
]]

local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

local LobbyHub = {}
local ctx

local panel: Frame
local queueTitle: TextLabel
local queueStatus: TextLabel

local function teleportScreen(): ScreenGui
	local UI = ctx.UI
	local gui = UI.new("ScreenGui", { Name = "HomeAloneTeleport", IgnoreGuiInset = true, DisplayOrder = 100 })
	local bg = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 6, 8), Parent = gui })
	UI.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.8, 0.14), Text = "14 Alder Lane", Font = UI.Font.Title, TextScaled = true, Parent = bg })
	UI.label({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.54), Size = UDim2.fromScale(0.8, 0.06), Text = "Friday, November. 8:47 PM. It's raining.", TextScaled = true, TextColor3 = UI.Color.Dim, Parent = bg })
	return gui
end

local function render(state)
	if not state then
		panel.Visible = false
		return
	end
	panel.Visible = true
	queueTitle.Text = (state.Size == 1 and "SOLO" or (state.Size .. "-PLAYER")) .. " QUEUE  ·  " .. state.Count .. " / " .. state.Size
	if state.Status == "Teleporting" then
		queueStatus.Text = "Heading to the house..."
	elseif state.Status == "Full" then
		queueStatus.Text = "This circle is full. Try another one."
	elseif state.Status == "Starting" then
		queueStatus.Text = "Starting in " .. tostring(state.Countdown or 0) .. "... step off to cancel"
	else
		local need = state.Size - state.Count
		queueStatus.Text = "Waiting for " .. need .. " more player" .. (need == 1 and "" or "s") .. ". Invite a friend!"
	end
end

function LobbyHub.init(c)
	ctx = c
end

function LobbyHub.start()
	local UI = ctx.UI
	local inset = GuiService:GetGuiInset()
	local title = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, inset.Y + 10),
		Size = UDim2.fromOffset(620, 84),
		BackgroundTransparency = 1,
		Parent = UI.Root,
	})
	UI.label({ Size = UDim2.new(1, 0, 0, 50), Text = ctx.Story.Title, Font = UI.Font.Title, TextSize = 46, TextStrokeTransparency = 0.5, Parent = title })
	-- bring friends, and keep the game one tap away
	local row = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, inset.Y + 64),
		Size = UDim2.fromOffset(420, 54),
		BackgroundTransparency = 1,
		Parent = UI.Root,
	})
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = row })
	ctx.Social.button(row, "invite")
	ctx.Social.button(row, "favorite", { Size = UDim2.fromOffset(160, 54) })
	-- your record, saved between visits
	local player = game:GetService("Players").LocalPlayer
	local record = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, inset.Y + 126),
		Size = UDim2.fromOffset(520, 26),
		Text = "",
		Font = UI.Font.Bold,
		TextSize = 17,
		TextColor3 = UI.Color.Dim,
		TextStrokeTransparency = 0.5,
		Parent = UI.Root,
	})
	local function showRecord()
		local nights = player:GetAttribute("StatNights")
		if nights == nil then
			record.Text = ""
			return
		end
		record.Text = string.format("NIGHTS %d   ·   SURVIVED %d   ·   ENDINGS %d / %d", nights, player:GetAttribute("StatEscapes") or 0, player:GetAttribute("StatEndings") or 0, player:GetAttribute("StatEndingTotal") or 0)
	end
	for _, a in { "StatNights", "StatEscapes", "StatEndings" } do
		player:GetAttributeChangedSignal(a):Connect(showRecord)
	end
	showRecord()

	ctx.Notice.show({
		Title = "Welcome to Hollis Creek",
		Body = "Walk into one of the white circles to queue for 1, 2, 3 or 4 players.\n\nWhen a circle is full, your group goes to the house together.",
		Button = "OK",
	})

	panel = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(520, 116),
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.2,
		Visible = false,
		Parent = UI.Root,
	})
	UI.corner(panel, 12)
	UI.stroke(panel, UI.Color.Accent, 1.5, 0.5)
	queueTitle = UI.label({ Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -150, 0, 32), Text = "", Font = UI.Font.Bold, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel })
	queueStatus = UI.label({ Position = UDim2.fromOffset(16, 46), Size = UDim2.new(1, -150, 0, 58), Text = "", TextSize = 19, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = panel })
	local leave = UI.new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(118, 60),
		Text = "LEAVE",
		Font = UI.Font.Bold,
		TextSize = 20,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = Color3.fromRGB(150, 45, 40),
		Parent = panel,
	})
	UI.corner(leave, 10)
	leave.Activated:Connect(function()
		ctx.Remotes.LeaveQueue:FireServer()
	end)

	ctx.Remotes.Queue.OnClientEvent:Connect(render)
	ctx.Remotes.Notify.OnClientEvent:Connect(function(text)
		queueStatus.Text = text
	end)
	pcall(function()
		TeleportService:SetTeleportGui(teleportScreen())
	end)
end

return LobbyHub
