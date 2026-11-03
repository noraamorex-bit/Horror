--[[
	LobbyHub — the lobby place's UI: title, how to queue, your circle's status with a LEAVE
	button (big enough for thumbs), and the loading screen shown while teleporting.
]]

local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local LobbyHub = {}
local ctx

local panel: Frame
local queueTitle: TextLabel
local queueStatus: TextLabel

local TIPS = {
	"Crouch and he can't hear you. Run and he will.",
	"Keep still in the dark and he loses you.",
	"The one bar of signal is at the upstairs bathroom window.",
	"Caught once, a friend can cut you loose.",
	"A hiding spot goes stale. Move before he comes to listen.",
	"He goes over low furniture. Don't run circles round the table.",
}

local function teleportScreen(): ScreenGui
	local UI = ctx.UI
	local gui = UI.new("ScreenGui", { Name = "HomeAloneTeleport", IgnoreGuiInset = true, DisplayOrder = 100 })
	local bg = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 6, 8), Parent = gui })
	UI.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.8, 0.13), Text = "14 Alder Lane", Font = UI.Font.Title, TextScaled = true, Parent = bg })
	UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.505), Size = UDim2.new(0, 60, 0, 3), BackgroundColor3 = UI.Color.Blood, Parent = bg })
	UI.label({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromScale(0.8, 0.05), Text = "Friday, November. 8:47 PM. It's raining.", TextScaled = true, TextColor3 = UI.Color.Dim, Parent = bg })
	UI.label({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.92), Size = UDim2.fromScale(0.8, 0.04), Text = "TIP:  " .. TIPS[math.random(1, #TIPS)], TextScaled = true, Font = UI.Font.Body, TextColor3 = Color3.fromRGB(120, 116, 110), Parent = bg })
	return gui
end

local quick: Frame
local lobbyMenu: Frame
local queueBar: Frame?


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
	-- (v138) the countdown drains a bar: 10 s from the first step in, 3 once the circle's full
	if queueBar then
		local full = state.Count >= state.Size
		local k = state.Status == "Teleporting" and 0 or (state.Countdown and math.clamp(state.Countdown / (full and 3 or 10), 0, 1) or 1)
		ctx.UI.tween(queueBar, 0.9, { Size = UDim2.fromScale(k, 1) }, Enum.EasingStyle.Linear)
	end
	if state.Status == "Teleporting" then
		queueStatus.Text = "Heading to the house..."
	elseif state.Status == "Full" then
		queueStatus.Text = "This circle is full. Try another one."
	else
		-- (every circle counts down from 10 the moment someone steps in; 3 once it's full)
		queueStatus.Text = state.Countdown and ("Starting in " .. tostring(state.Countdown) .. "...  LEAVE to step out") or "Starting soon..."
		-- (v111) a short circle goes anyway (the owner's rule), so say so: 15 of 34 lone players left
		-- their house within 26 s, nearly all brand new: they'd queued for "2 players" and landed alone
		if state.Countdown and state.Size > 1 and state.Count < state.Size then
			queueStatus.Text = "Starting in " .. tostring(state.Countdown) .. "... the next player to queue joins your house"
		end
	end
end

function LobbyHub.init(c)
	ctx = c
end

-- (v118) back in the lobby after a night, or on another day: 70% of returning players left the lobby
-- within a minute without queueing (since v112, 56 visits). A small card at the top: what tonight is
-- worth (the night streak, today's quests, the daily reward, NIGHTMARE), and one tap to play.
local function backLines(player: Player): { string }
	local lines = {}
	local untilT, bonus = player:GetAttribute("ChainUntil"), player:GetAttribute("ChainNext")
	if type(untilT) == "number" and type(bonus) == "number" and bonus > 0 then
		local left = math.max(0, math.floor(untilT - os.time()))
		if left > 0 then
			table.insert(lines, string.format("<font color=\"#ffcd5a\"><b>NIGHT STREAK</b>  +%d%% coins if you play in the next %d:%02d</font>", bonus, left // 60, left % 60))
		end
	end
	local eco = player:GetAttribute("Eco")
	local ok, data = pcall(function()
		return HttpService:JSONDecode(eco)
	end)
	if ok and type(data) == "table" then
		if type(data.Daily) == "table" and data.Daily.CanClaim then
			table.insert(lines, "<b>DAILY REWARD</b> ready: tap 🎁 on the right")
		end
		local n = 0
		for _, q in (type(data.Quests) == "table" and data.Quests or {}) do
			if not q.Done and n < 2 then
				n += 1
				table.insert(lines, string.format("□  %s  <font color=\"#9a968e\">%d/%d</font>  <font color=\"#ffcd5a\">+%d</font>", tostring(q.Text), q.Progress or 0, q.Goal or 1, q.Coins or 0))
			end
		end
	end
	-- (v138) a code they haven't used yet
	if ctx and ctx.Codes and ctx.Codes.featured and #lines < 4 then
		local c = ctx.Codes.featured()
		if c and not ctx.Codes._used(c.Code) then
			table.insert(lines, string.format("<font color=\"#ffcd5a\"><b>CODE %s</b></font>  +%d coins and a title: tap 🎟️", c.Code, c.Coins or 0))
		end
	end
	if (tonumber(player:GetAttribute("StatEscapes")) or 0) >= 1 and #lines < 5 then
		table.insert(lines, "<b>NIGHTMARE</b> is open to you: vote for it in the house, 2x coins")
	end
	return lines
end
LobbyHub._backLines = backLines -- (tests)

function LobbyHub.welcomeBack()
	local UI = ctx.UI
	local player = game:GetService("Players").LocalPlayer
	-- (the coins and quests come with the economy record: give it a moment)
	local t0 = os.clock()
	while player:GetAttribute("Eco") == nil and os.clock() - t0 < 5 do
		task.wait(0.25)
	end
	local lines = backLines(player)
	local inset = GuiService:GetGuiInset()
	local card = UI.new("Frame", {
		Name = "WelcomeBack",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, inset.Y + 62),
		Size = UDim2.fromOffset(360, 52 + 18 * #lines),
		BackgroundColor3 = UI.Color.Glass,
		BackgroundTransparency = 0.16,
		Parent = UI.Root,
	})
	UI.corner(card, 10)
	UI.stroke(card, Color3.new(1, 1, 1), 1, 0.8)
	-- (v138) a red edge, like the lobby's other cards' accent bars
	local edge = UI.new("Frame", { Position = UDim2.fromOffset(0, 12), Size = UDim2.new(0, 3, 1, -24), BackgroundColor3 = UI.Color.Blood, Parent = card })
	UI.corner(edge, 2)
	UI.label({ Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -150, 0, 22), Text = "BACK FOR ANOTHER NIGHT?", Font = UI.Font.Bold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
	for i, line in lines do
		UI.label({
			Position = UDim2.fromOffset(16, 42 + (i - 1) * 18),
			Size = UDim2.new(1, -28, 0, 18),
			Text = line,
			RichText = true,
			TextSize = 11,
			TextWrapped = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = card,
		})
	end
	local play = UI.new("TextButton", {
		Name = "Play",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -44, 0, 8),
		Size = UDim2.fromOffset(96, 30),
		Text = "▶  PLAY",
		Font = UI.Font.Bold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(20, 20, 20),
		BackgroundColor3 = Color3.fromRGB(240, 238, 232),
		Parent = card,
	})
	UI.corner(play, 6)
	local close = UI.new("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(30, 30),
		Text = "✕",
		Font = UI.Font.Bold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(235, 232, 226),
		BackgroundColor3 = Color3.fromRGB(40, 40, 44),
		Parent = card,
	})
	UI.corner(close, 6)
	play.Activated:Connect(function()
		card:Destroy()
		ctx.Remotes.QuickPlay:FireServer("Group")
	end)
	close.Activated:Connect(function()
		card:Destroy()
	end)
	-- (it goes by itself after a while, and the moment you're in a circle)
	task.delay(25, function()
		if card.Parent then
			card:Destroy()
		end
	end)
	ctx.Remotes.Queue.OnClientEvent:Connect(function(state)
		if state and card.Parent then
			card:Destroy()
		end
	end)
	return card
end

-- The lobby is third person (the house is first person, and StarterPlayer is set up for that).
-- The server asks for it too, but the client applies it itself, on every spawn, so a slow
-- property replication can never leave a phone stuck in first person.
local function thirdPerson()
	local player = game:GetService("Players").LocalPlayer
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 22
	player.CameraMinZoomDistance = 9
	local cam = workspace.CurrentCamera
	if cam then
		cam.CameraType = Enum.CameraType.Custom
	end
end

-- (v138) the lobby's look: dark glass, hairlines, one dried-blood red for accents
local GLASS_T = 0.24

local function glass(UI, props): Frame
	local f = UI.new("Frame", props)
	f.BackgroundColor3 = UI.Color.Glass
	f.BackgroundTransparency = props.BackgroundTransparency or GLASS_T
	UI.corner(f, 10)
	UI.stroke(f, Color3.new(1, 1, 1), 1, 0.84)
	return f
end

function LobbyHub.start()
	local UI = ctx.UI
	thirdPerson()
	-- (v140, the owner: "Cut invite": no INVITE icon in the dock)
	local Players = game:GetService("Players")
	local lp = Players.LocalPlayer
	lp.CharacterAdded:Connect(function()
		task.defer(thirdPerson)
		task.delay(1, thirdPerson)
	end)
	task.delay(2, thirdPerson)
	local inset = GuiService:GetGuiInset()
	local player = lp
	-- (v138, the owner: "heavily rework the UI... particularly lobby") everything on the left in one
	-- column (v140: only PLAY and two icons). The top centre is
	-- left free (a friend's house card, the welcome-back card, toasts) and the middle stays clear.
	local MENU_W = 136
	local ICON = 40
	local menu = UI.new("Frame", {
		Name = "LobbyMenu",
		Position = UDim2.new(0, math.max(16, inset.X + 16), 0, inset.Y + 8),
		Size = UDim2.fromOffset(MENU_W, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = UI.Root,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menu })
	lobbyMenu = menu

	-- (v140, the owner, crossing out the title, FIND PLAYERS and How to play: "Do UI properly this is so bad.. Make
	-- everything smaller… Use only icons..") one small PLAY, then two icons: the endings and the settings
	quick = UI.new("Frame", { Name = "Quick", LayoutOrder = 3, Size = UDim2.fromOffset(MENU_W, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = menu })
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = quick })
	local play = UI.new("TextButton", {
		Name = "Play",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(MENU_W, 42),
		Text = "▶  PLAY",
		Font = UI.Font.Bold,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(12, 12, 14),
		BackgroundColor3 = Color3.fromRGB(240, 236, 228),
		Parent = quick,
	})
	UI.corner(play, 10)
	local press = UI.new("UIScale", { Parent = play })
	play.Activated:Connect(function()
		press.Scale = 0.94
		UI.tween(press, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
		-- (into a group circle with whoever's here: alone, the countdown still takes you in)
		ctx.Remotes.QuickPlay:FireServer("Group")
		if ctx.Effects then
			ctx.Effects.playSound("UISelect", nil, { Caption = false })
		end
	end)
	-- the night streak: start another night soon and it pays more (EconomyService)
	local streak = UI.label({ Name = "StreakLine", LayoutOrder = 2, Size = UDim2.fromOffset(MENU_W, 14), Text = "", Font = UI.Font.Bold, TextSize = 11, TextColor3 = Color3.fromRGB(255, 205, 90), TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.5, Visible = false, Parent = quick })
	task.spawn(function()
		while streak.Parent do
			local untilT = tonumber(player:GetAttribute("ChainUntil"))
			local bonus = tonumber(player:GetAttribute("ChainNext")) or 0
			local left = untilT and math.floor(untilT - workspace:GetServerTimeNow()) or 0
			streak.Visible = left > 0 and bonus > 0
			if streak.Visible then
				streak.Text = string.format("🔥 +%d%%  %d:%02d", bonus, left // 60, left % 60)
			end
			task.wait(1)
		end
	end)
	local icons = UI.new("Frame", { Name = "Icons", LayoutOrder = 5, Size = UDim2.fromOffset(MENU_W, ICON), BackgroundTransparency = 1, Parent = menu })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = icons })
	local function iconButton(name: string, glyph: string, order: number): TextButton
		local b = UI.new("TextButton", {
			Name = name,
			LayoutOrder = order,
			Size = UDim2.fromOffset(ICON, ICON),
			Text = glyph,
			Font = UI.Font.Bold,
			TextSize = 20,
			TextColor3 = Color3.fromRGB(235, 232, 226),
			AutoButtonColor = false,
			BackgroundColor3 = UI.Color.Glass,
			BackgroundTransparency = GLASS_T,
			Parent = icons,
		})
		UI.corner(b, 10)
		local st = UI.stroke(b, Color3.new(1, 1, 1), 1, 0.84)
		UI.hover(b, function()
			st.Transparency = 0.5
		end, function()
			st.Transparency = 0.84
		end)
		local sc = UI.new("UIScale", { Parent = b })
		b.Activated:Connect(function()
			sc.Scale = 0.9
			UI.tween(sc, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
		end)
		return b
	end
	local endingsBtn = iconButton("Endings", "🏆", 1)
	local settingsBtn = iconButton("Settings", "⚙️", 2)
	settingsBtn.Activated:Connect(function()
		if ctx.Settings then
			ctx.Settings.open()
		end
	end)

	-- the endings: a panel like the dock's (found ones by name, the rest as hints)
	local endings = ctx.Dock and ctx.Dock.panel("Endings")
	local function fillEndings()
		if not endings then
			return
		end
		local list = endings.Pages.Main
		for _, ch in list:GetChildren() do
			if ch:IsA("Frame") then
				ch:Destroy()
			end
		end
		local found = {}
		for _, k in string.split(tostring(player:GetAttribute("StatEndingList") or ""), ",") do
			found[k] = true
		end
		for i, key in ctx.Story.EndingOrder do
			local e = ctx.Story.Endings[key]
			if e then
				local row = ctx.Dock.row(list, i, 46)
				UI.label({ Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0), Text = found[key] and string.format("<b>✓  %s</b>", e.Title) or string.format("<font color=\"#77736c\">???   %s</font>", ctx.Story.EndingHints[key] or ""), RichText = true, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 43, Parent = row })
				if found[key] then
					UI.stroke(row, Color3.new(1, 1, 1), 1, 0.75)
				end
			end
		end
	end
	endingsBtn.Activated:Connect(function()
		fillEndings()
		if endings then
			endings.toggle()
		end
	end)

	-- (only the first time: returning players go straight to playing)
	task.spawn(function()
		local nights = player:GetAttribute("StatNights")
		if nights == nil then
			local t0 = os.clock()
			repeat
				task.wait(0.2)
				nights = player:GetAttribute("StatNights")
			until nights ~= nil or os.clock() - t0 > 4
		end
		if (tonumber(nights) or 0) > 0 then
			LobbyHub.welcomeBack()
		elseif (tonumber(nights) or 0) == 0 then
			-- (one tap and you're in: new players took a median 39 s to queue, a third never did)
			ctx.Notice.show({
				Title = "Welcome to Hollis Creek",
				Body = "Someone lives in the attic. Survive the night, alone or with friends.\n\nPLAY puts you in a group with whoever's here. Here are 100 coins to start: spend them at 🛒 on the right.",
				Button = "▶  PLAY",
			}, function()
				ctx.Remotes.QuickPlay:FireServer("Group") -- (ignored if they've already stepped into a circle)
			end)
		end
	end)

	-- your queue: at the top of the left-hand menu, in place of the play buttons
	panel = glass(UI, { Name = "QueuePanel", LayoutOrder = 2, Size = UDim2.fromOffset(190, 108), BackgroundTransparency = 0.18, Visible = false, Parent = lobbyMenu })
	queueTitle = UI.label({ Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 18), Text = "", Font = UI.Font.Bold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel })
	queueStatus = UI.label({ Position = UDim2.fromOffset(12, 27), Size = UDim2.new(1, -24, 0, 28), Text = "", TextSize = 11, TextWrapped = true, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = panel })
	-- (v138) the countdown as a bar draining under the text
	local track = UI.new("Frame", { Name = "CountdownBar", Position = UDim2.fromOffset(12, 59), Size = UDim2.new(1, -24, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85, Parent = panel })
	queueBar = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track })
	-- (v118) the only way out of a circle once you're in it: the walls hold queued players in
	local leave = UI.new("TextButton", {
		Name = "LeaveQueue",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -10, 1, -10),
		Size = UDim2.fromOffset(96, 32),
		Text = "✕  LEAVE",
		Font = UI.Font.Bold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 236, 232),
		BackgroundColor3 = Color3.fromRGB(120, 24, 26),
		Parent = panel,
	})
	UI.corner(leave, 8)
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
