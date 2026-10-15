--[[
	Vote — the CHOOSE MODE screen before the night: NORMAL or HARD, everyone votes, the counts
	update live, a countdown runs. More votes for HARD makes it a hard night (a tie stays normal).

	The four roles and what each starts with show here for everyone (Story.Roles Gear); owners of
	the "pick your role" pass tap one to play it tonight, anyone else gets the pass offered.

	When everyone here has finished a night before, a toggle offers to SKIP TO THE BLACKOUT (the
	cozy part they've already seen); more than half of them must want it.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local Vote = {}
local ctx
local player = Players.LocalPlayer

local screen: Frame
local title: TextLabel
local timer: TextLabel
local footer: TextLabel
local boxes: { [string]: { Frame: TextButton, Stroke: UIStroke, Count: TextLabel, Color: Color3 } } = {}
local roleRow: Frame
local roleButtons: { [string]: TextButton } = {}
local roleHint: TextLabel
local skipButton: TextButton
local mySkip = false
local ends = 0
local mine: string? = nil
local open = false
local lastBeep = -1
local closing: thread? = nil

local MODES = {
	{ Key = "Normal", Text = "NORMAL", Sub = "The way the night is meant to be.", Color = Color3.fromRGB(245, 245, 245) },
	{ Key = "Hard", Text = "HARD", Sub = "He's faster, smarter and angrier. Batteries die sooner. Help takes longer.", Color = Color3.fromRGB(235, 45, 45) },
}

local function passId(key: string): number
	for _, p in ctx.Config.Shop.Passes do
		if p.Key == key then
			return p.Id
		end
	end
	return 0
end

local function refreshRoles()
	local owns = player:GetAttribute("Pass_ChooseRole") == true
	local price = 25
	for _, p in ctx.Config.Shop.Passes do
		if p.Key == "ChooseRole" then
			price = p.Price
		end
	end
	roleHint.Text = owns and "WHO DO YOU PLAY TONIGHT? (what you start with)"
		or string.format("Your role is random tonight · tap one to choose yours (R$ %d)", price)
	local want = player:GetAttribute("WantRole")
	for id, b in roleButtons do
		local on = owns and want == id
		b.BackgroundColor3 = on and Color3.fromRGB(240, 236, 228) or Color3.fromRGB(28, 28, 32)
		b.TextColor3 = on and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(232, 228, 218)
		local first = tostring(b:GetAttribute("First") or "")
		local gear = tostring(b:GetAttribute("Gear") or "")
		b.Text = string.format("%s%s\n<font size=\"14\">%s</font>", owns and "" or "🔒 ", first, gear)
	end
end

local function render(payload)
	for _, m in MODES do
		local b = boxes[m.Key]
		local n = payload[m.Key] or 0
		b.Count.Text = "(" .. tostring(n) .. ")"
		local picked = (payload.Mine or mine) == m.Key
		b.Stroke.Thickness = picked and 5 or 2
		b.Stroke.Transparency = picked and 0 or 0.55
		b.Frame.BackgroundTransparency = picked and 0.55 or 0.8
	end
	footer.Text = string.format("%d / %d voted", (payload.Normal or 0) + (payload.Hard or 0), payload.Total or #Players:GetPlayers())
	-- skip the build-up (only offered when everyone has played a night before)
	skipButton.Visible = payload.CanSkip == true and payload.Result == nil
	if payload.CanSkip then
		mySkip = payload.MySkip == true
		local need = tonumber(payload.SkipNeed) or 1
		skipButton.Text = string.format("%s  SKIP TO THE BLACKOUT   %d / %d", mySkip and "✓" or "⏩", tonumber(payload.Skip) or 0, need)
		skipButton.BackgroundColor3 = mySkip and Color3.fromRGB(240, 236, 228) or Color3.fromRGB(28, 28, 32)
		skipButton.TextColor3 = mySkip and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(232, 228, 218)
	end
end

local function show()
	if closing then
		pcall(task.cancel, closing)
		closing = nil
	end
	if open then
		return
	end
	open = true
	mine = nil
	lastBeep = -1
	title.Text = "CHOOSE MODE"
	title.TextColor3 = Color3.new(1, 1, 1)
	for _, m in MODES do
		boxes[m.Key].Frame.Visible = true
		boxes[m.Key].Frame.Active = true
	end
	timer.Visible = true
	roleRow.Visible = true
	roleHint.Visible = true
	refreshRoles()
	screen.Visible = true
	screen.BackgroundTransparency = 1
	ctx.UI.tween(screen, 0.35, { BackgroundTransparency = 0.25 })
	ctx.Effects.playSound("UIWhoosh", nil, { Caption = false })
	-- (no music here: it blared over the start of every night)
end

local function close(result: string?, skip: boolean?)
	if not open then
		return
	end
	timer.Visible = false
	roleRow.Visible = false
	roleHint.Visible = false
	skipButton.Visible = false
	if result then
		-- the winning mode, big, for a moment
		local m = result == "Hard" and MODES[2] or MODES[1]
		title.Text = m.Text .. " MODE"
		title.TextColor3 = m.Color
		for _, mm in MODES do
			boxes[mm.Key].Frame.Active = false
			boxes[mm.Key].Frame.Visible = mm.Key == result
		end
		footer.Text = result == "Hard" and "Good luck." or "Stay quiet. Stay together."
		if skip then
			footer.Text = "Skipping to the blackout."
		end
		ctx.Effects.playSound(result == "Hard" and "HorrorHitLow" or "UISelect", nil, { Caption = false })
	end
	closing = task.delay(result and 1.6 or 0, function()
		closing = nil
		open = false
		ctx.UI.tween(screen, 0.4, { BackgroundTransparency = 1 })
		task.wait(0.4)
		if not open then
			screen.Visible = false
		end
	end)
end

local function build()
	local UI = ctx.UI
	screen = UI.new("Frame", {
		Name = "Vote",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.25,
		Visible = false,
		ZIndex = 5,
		Parent = UI.Top,
	})
	UI.modal(screen)
	local col = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(760, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = screen,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 18), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = col })
	title = UI.label({ Size = UDim2.new(1, 0, 0, 64), Text = "CHOOSE MODE", Font = Enum.Font.Arcade, TextSize = 60, LayoutOrder = 1, ZIndex = 5, Parent = col })
	UI.new("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0), Parent = title })

	local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 190), BackgroundTransparency = 1, LayoutOrder = 2, ZIndex = 5, Parent = col })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 30), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	for i, m in MODES do
		local b = UI.new("TextButton", {
			Name = m.Key,
			Size = UDim2.fromOffset(330, 190),
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = m.Color,
			BackgroundTransparency = 0.8,
			LayoutOrder = i,
			ZIndex = 5,
			Parent = row,
		})
		UI.corner(b, 6)
		local stroke = UI.new("UIStroke", { Color = m.Color, Thickness = 2, Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
		local name = UI.label({ Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 56), Text = m.Text, Font = Enum.Font.Arcade, TextSize = 56, TextColor3 = m.Color, ZIndex = 6, Parent = b })
		UI.new("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0), Parent = name })
		local count = UI.label({ Position = UDim2.fromOffset(0, 82), Size = UDim2.new(1, 0, 0, 36), Text = "(0)", Font = Enum.Font.Arcade, TextSize = 34, TextColor3 = m.Color, ZIndex = 6, Parent = b })
		UI.label({ Position = UDim2.new(0, 16, 0, 124), Size = UDim2.new(1, -32, 0, 54), Text = m.Sub, TextSize = 17, TextWrapped = true, TextColor3 = UI.Color.Dim, ZIndex = 6, Parent = b })
		b.Activated:Connect(function()
			if not open or not b.Active then
				return
			end
			mine = m.Key
			ctx.Remotes.CastVote:FireServer(m.Key)
			ctx.Effects.playSound("UISelect", nil, { Caption = false })
			b.Size = UDim2.fromOffset(316, 182)
			UI.tween(b, 0.25, { Size = UDim2.fromOffset(330, 190) }, Enum.EasingStyle.Back)
		end)
		boxes[m.Key] = { Frame = b, Stroke = stroke, Count = count, Color = m.Color }
	end

	timer = UI.label({ Size = UDim2.new(1, 0, 0, 44), Text = "(12)", Font = Enum.Font.Arcade, TextSize = 40, LayoutOrder = 4, ZIndex = 5, Parent = col })
	UI.new("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0), Parent = timer })

	-- who you play, and what each one starts with: everyone sees it; the pass lets you pick
	roleHint = UI.label({ Size = UDim2.new(1, 0, 0, 20), Text = "", TextSize = 16, TextColor3 = UI.Color.Dim, LayoutOrder = 5, ZIndex = 5, Parent = col })
	roleRow = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, LayoutOrder = 6, ZIndex = 5, Parent = col })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = roleRow })
	for i, r in ctx.Story.Roles do
		local first = string.match(r.Name, "^(%S+)") or r.Name
		local b = UI.new("TextButton", {
			Size = UDim2.fromOffset(172, 58),
			Text = "",
			RichText = true,
			Font = UI.Font.Bold,
			TextSize = 18,
			LineHeight = 1.05,
			BackgroundColor3 = Color3.fromRGB(28, 28, 32),
			TextColor3 = UI.Color.Text,
			LayoutOrder = i,
			ZIndex = 5,
			Parent = roleRow,
		})
		b:SetAttribute("First", first)
		b:SetAttribute("Gear", r.Gear or "")
		UI.corner(b, 10)
		UI.stroke(b, Color3.new(1, 1, 1), 1.5, 0.6)
		b.Activated:Connect(function()
			if player:GetAttribute("Pass_ChooseRole") then
				ctx.Remotes.PickRole:FireServer(r.Id)
				ctx.Effects.playSound("UISelect", nil, { Caption = false })
			else
				local id = passId("ChooseRole")
				if id > 0 then
					MarketplaceService:PromptGamePassPurchase(player, id)
				end
			end
		end)
		roleButtons[r.Id] = b
	end

	footer = UI.label({ Size = UDim2.new(1, 0, 0, 26), Text = "", TextSize = 18, TextColor3 = UI.Color.Dim, LayoutOrder = 7, ZIndex = 5, Parent = col })

	-- skip the cozy part (repeat groups)
	skipButton = UI.new("TextButton", {
		Size = UDim2.fromOffset(420, 48),
		Text = "⏩  SKIP TO THE BLACKOUT",
		Font = UI.Font.Bold,
		TextSize = 19,
		BackgroundColor3 = Color3.fromRGB(28, 28, 32),
		TextColor3 = UI.Color.Text,
		LayoutOrder = 3,
		Visible = false,
		ZIndex = 5,
		Parent = col,
	})
	UI.corner(skipButton, 10)
	UI.stroke(skipButton, Color3.new(1, 1, 1), 1.5, 0.6)
	skipButton.Activated:Connect(function()
		if not open then
			return
		end
		mySkip = not mySkip
		ctx.Remotes.CastVote:FireServer(mySkip and "Skip" or "NoSkip")
		ctx.Effects.playSound("UISelect", nil, { Caption = false })
	end)
end

function Vote.init(c)
	ctx = c
	ctx.VoteUI = Vote
end

function Vote.isOpen(): boolean
	return open
end

function Vote.start()
	build()
	ctx.Remotes.Vote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			close(nil)
			return
		end
		if payload.Result then
			render(payload)
			close(payload.Result, payload.Skip == true)
			return
		end
		ends = payload.Ends or ends
		if payload.Mine then
			mine = payload.Mine
		end
		show()
		render(payload)
	end)
	player:GetAttributeChangedSignal("Pass_ChooseRole"):Connect(refreshRoles)
	player:GetAttributeChangedSignal("WantRole"):Connect(refreshRoles)
	RunService.Heartbeat:Connect(function()
		if not open or not timer.Visible then
			return
		end
		local left = math.max(0, math.ceil(ends - workspace:GetServerTimeNow()))
		timer.Text = "(" .. tostring(left) .. ")"
		if left ~= lastBeep then
			lastBeep = left
			if left <= 5 and left > 0 then
				ctx.Effects.playSound("CountBeep", nil, { Caption = false })
			end
		end
	end)
end

return Vote
