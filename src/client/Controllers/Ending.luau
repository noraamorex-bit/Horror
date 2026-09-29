--[[
	Ending — the ending card, everyone's fate, and "What Really Happened".
]]

local Ending = {}
local ctx

function Ending.init(c)
	ctx = c
end

local function show(payload)
	local UI = ctx.UI
	local screen = UI.new("Frame", {
		Name = "Ending",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(6, 6, 8),
		BackgroundTransparency = 1,
		Parent = UI.Top,
	})
	UI.modal(screen)
	UI.tween(screen, 2, { BackgroundTransparency = 0.05 })
	local scroll = UI.new("ScrollingFrame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 40),
		Size = UDim2.new(0, 760, 1, -80),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 5,
		Parent = screen,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = scroll })
	local order = 0
	local function add(props)
		order += 1
		props.LayoutOrder = order
		props.Size = props.Size or UDim2.new(1, -20, 0, 0)
		props.AutomaticSize = Enum.AutomaticSize.Y
		props.Parent = scroll
		return UI.label(props)
	end
	add({ Text = payload.Title, Font = UI.Font.Title, TextSize = 64, TextColor3 = payload.Bad and UI.Color.Danger or UI.Color.Text })
	local me = game:GetService("Players").LocalPlayer
	if table.find(payload.FirstFor or {}, me.UserId) then
		local found, total = me:GetAttribute("StatEndings"), me:GetAttribute("StatEndingTotal")
		add({ Text = "NEW ENDING FOUND" .. (found and total and ("  ·  " .. found .. " / " .. total) or ""), Font = UI.Font.Bold, TextSize = 18, TextColor3 = UI.Color.Accent })
	end
	add({ Text = payload.Body, Font = UI.Font.Title, TextSize = 19, RichText = false })
	add({ Text = "Survived " .. tostring(payload.Duration), TextSize = 14, TextColor3 = UI.Color.Dim })

	add({ Text = "WHO MADE IT", Font = UI.Font.Bold, TextSize = 16, TextColor3 = UI.Color.Accent })
	for _, f in payload.Fates or {} do
		add({
			Text = string.format("<b>%s</b> (%s) — %s%s", f.Name, f.Role, f.Fate, f.WasCaptured and "  <font color=\"#8a8a8a\">· taken to the boiler room</font>" or ""),
			TextSize = 17,
		})
	end

	add({ Text = "WHAT REALLY HAPPENED", Font = UI.Font.Bold, TextSize = 16, TextColor3 = UI.Color.Accent })
	local truths = payload.Truths or {}
	if #truths == 0 then
		add({ Text = "(Nothing strange happened that anyone noticed.)", TextSize = 16, TextColor3 = UI.Color.Dim })
	end
	for _, t in truths do
		add({
			Text = string.format("<font color=\"#8a8a8a\">%s</font>   %s", t.Time, t.Text),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end
	-- play it again with more friends, and keep the game one tap away
	order += 1
	local row = UI.new("Frame", { LayoutOrder = order, Size = UDim2.new(1, -20, 0, 60), BackgroundTransparency = 1, Parent = scroll })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = row })
	if ctx.Social then
		ctx.Social.button(row, "invite")
		ctx.Social.button(row, "favorite", { Size = UDim2.fromOffset(160, 54) })
		task.delay(8, function()
			if screen.Parent then
				ctx.Social.maybeAskFavorite()
			end
		end)
	end
	local countdown = add({ Text = "", TextSize = 14, TextColor3 = UI.Color.Dim })
	task.spawn(function()
		local left = payload.RestartIn or 60
		while left > 0 and screen.Parent do
			countdown.Text = (payload.ReturnToLobby and "Back to the lobby in " or "The house resets in ") .. left .. "s"
			task.wait(1)
			left -= 1
		end
		if screen.Parent then
			screen:Destroy()
		end
	end)
	-- the next lobby clears it
	local conn
	conn = workspace:GetAttributeChangedSignal("Act"):Connect(function()
		if workspace:GetAttribute("Act") == "Lobby" then
			conn:Disconnect()
			if screen.Parent then
				screen:Destroy()
			end
		end
	end)
end

function Ending.start()
	ctx.Remotes.Ending.OnClientEvent:Connect(show)
end

return Ending
