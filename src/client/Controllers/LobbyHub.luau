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

local quick: Frame
local lobbyMenu: Frame

local function render(state)
	if quick then
		quick.Visible = state == nil
	end
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
	UI.label({ Size = UDim2.new(1, 0, 0, 50), Text = ctx.Story.Title, Font = UI.Font.Title, TextSize = 34, TextStrokeTransparency = 0.6, Parent = title })
	-- a small menu down the left side: play first, then the extras
	local function menuButton(parent, text: string, order: number): TextButton
		local b = UI.new("TextButton", {
			LayoutOrder = order,
			Size = UDim2.fromOffset(150, 30),
			Text = text,
			Font = Enum.Font.GothamMedium,
			TextSize = 15,
			TextColor3 = Color3.fromRGB(235, 232, 226),
			BackgroundColor3 = Color3.fromRGB(12, 12, 14),
			BackgroundTransparency = 0.4,
			Parent = parent,
		})
		UI.corner(b, 6)
		UI.stroke(b, Color3.new(1, 1, 1), 1, 0.8)
		return b
	end
	local menu = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, math.max(16, inset.X + 16), 0, inset.Y + 10),
		Size = UDim2.fromOffset(150, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = UI.Root,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menu })
	-- one-tap play (hidden while you're in a queue)
	quick = UI.new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(150, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = menu })
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = quick })
	for i, spec in { { "Play solo", "Solo" }, { "Find players", "Group" } } do
		menuButton(quick, spec[1], i).Activated:Connect(function()
			ctx.Remotes.QuickPlay:FireServer(spec[2])
		end)
	end
	UI.new("Frame", { LayoutOrder = 2, Size = UDim2.fromOffset(150, 4), BackgroundTransparency = 1, Parent = menu })
	local endingsBtn = menuButton(menu, "Endings", 3)
	ctx.Social.button(menu, "invite", { LayoutOrder = 4, Size = UDim2.fromOffset(150, 30) })
	ctx.Social.button(menu, "favorite", { LayoutOrder = 5, Size = UDim2.fromOffset(150, 30) })
	lobbyMenu = menu
	local collection = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromScale(0.92, 0.8),
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.08,
		Visible = false,
		ZIndex = 30,
		Parent = UI.Root,
	})
	UI.corner(collection, 14)
	UI.stroke(collection, Color3.new(1, 1, 1), 1, 0.8)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(560, 420), Parent = collection })
	UI.label({ Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 34), Text = "Endings", Font = Enum.Font.GothamMedium, TextSize = 22, ZIndex = 31, Parent = collection })
	local list = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(18, 56),
		Size = UDim2.new(1, -36, 1, -130),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ZIndex = 31,
		Parent = collection,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local close = UI.new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(120, 34),
		Text = "Close",
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(235, 232, 226),
		BackgroundColor3 = Color3.fromRGB(40, 40, 44),
		ZIndex = 31,
		Parent = collection,
	})
	UI.corner(close, 6)
	local function fillCollection()
		for _, c in list:GetChildren() do
			if c:IsA("TextLabel") then
				c:Destroy()
			end
		end
		local found = {}
		for _, k in string.split(tostring(game:GetService("Players").LocalPlayer:GetAttribute("StatEndingList") or ""), ",") do
			found[k] = true
		end
		for i, key in ctx.Story.EndingOrder do
			local e = ctx.Story.Endings[key]
			if e then
				local text = found[key] and string.format("<b>%s</b>", e.Title)
					or string.format("<font color=\"#77736c\">???   %s</font>", ctx.Story.EndingHints[key] or "")
				UI.label({
					LayoutOrder = i,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Text = text,
					RichText = true,
					TextWrapped = true,
					TextSize = 19,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 32,
					Parent = list,
				})
			end
		end
	end
	endingsBtn.Activated:Connect(function()
		fillCollection()
		collection.Visible = not collection.Visible
	end)
	close.Activated:Connect(function()
		collection.Visible = false
	end)
	-- your record, saved between visits
	local player = game:GetService("Players").LocalPlayer
	local record = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, inset.Y + 50),
		Size = UDim2.fromOffset(520, 22),
		Text = "",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
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
		Body = "Tap PLAY SOLO to start right away, or FIND PLAYERS to team up with others.\n\nYou can also walk into a white circle to queue for 1, 2, 3 or 4 players. Invite friends to play together!",
		Button = "OK",
	})

	-- your queue: at the top of the left-hand menu, in place of the play buttons
	panel = UI.new("Frame", {
		LayoutOrder = 0,
		Size = UDim2.fromOffset(280, 70),
		BackgroundColor3 = Color3.fromRGB(12, 12, 14),
		BackgroundTransparency = 0.4,
		Visible = false,
		Parent = lobbyMenu,
	})
	UI.corner(panel, 8)
	UI.stroke(panel, Color3.new(1, 1, 1), 1, 0.8)
	queueTitle = UI.label({ Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -96, 0, 20), Text = "", Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel })
	queueStatus = UI.label({ Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -96, 0, 34), Text = "", TextSize = 13, TextWrapped = true, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = panel })
	local leave = UI.new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(72, 34),
		Text = "Leave",
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(235, 232, 226),
		BackgroundColor3 = Color3.fromRGB(40, 40, 44),
		Parent = panel,
	})
	UI.corner(leave, 6)
	UI.stroke(leave, Color3.new(1, 1, 1), 1, 0.8)
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
