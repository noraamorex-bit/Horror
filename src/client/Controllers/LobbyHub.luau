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
			table.insert(lines, "<b>DAILY REWARD</b> ready: open REWARDS on the right")
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
			table.insert(lines, string.format("<font color=\"#ffcd5a\"><b>CODE %s</b></font>  +%d coins and a title: tap CODES", c.Code, c.Coins or 0))
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
		Size = UDim2.fromOffset(410, 64 + 20 * #lines),
		BackgroundColor3 = UI.Color.Glass,
		BackgroundTransparency = 0.16,
		Parent = UI.Root,
	})
	UI.corner(card, 10)
	UI.stroke(card, Color3.new(1, 1, 1), 1, 0.8)
	-- (v138) a red edge, like the lobby's other cards' accent bars
	local edge = UI.new("Frame", { Position = UDim2.fromOffset(0, 12), Size = UDim2.new(0, 3, 1, -24), BackgroundColor3 = UI.Color.Blood, Parent = card })
	UI.corner(edge, 2)
	UI.label({ Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -150, 0, 22), Text = "BACK FOR ANOTHER NIGHT?", Font = UI.Font.Bold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
	for i, line in lines do
		UI.label({
			Position = UDim2.fromOffset(16, 32 + (i - 1) * 20),
			Size = UDim2.new(1, -28, 0, 20),
			Text = line,
			RichText = true,
			TextSize = 13,
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
	if ctx.Social then
		ctx.Social.dockIcon()
	end
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
	-- column: the name, your record, the two ways to play, then the three extras. The top centre is
	-- left free (a friend's house card, the welcome-back card, toasts) and the middle stays clear.
	local MENU_W = 236
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

	-- the name, typed out, a short red bar, and your record under it
	local brand = UI.new("Frame", { Name = "Brand", LayoutOrder = 1, Size = UDim2.fromOffset(MENU_W, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = menu })
	UI.new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = brand })
	UI.label({ Name = "GameTitle", LayoutOrder = 1, Size = UDim2.fromOffset(MENU_W, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = (string.gsub(ctx.Story.Title, " in our ", "\nin our ")), Font = UI.Font.Title, TextSize = 29, TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.55, Parent = brand })
	UI.new("Frame", { LayoutOrder = 2, Size = UDim2.fromOffset(40, 3), BackgroundColor3 = UI.Color.Blood, Parent = brand })
	local record = UI.label({ Name = "Record", LayoutOrder = 3, Size = UDim2.fromOffset(MENU_W, 16), Text = "HORROR  ·  1-4 PLAYERS", Font = UI.Font.Bold, TextSize = 11, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.6, Parent = brand })
	local function showRecord()
		local nights = tonumber(player:GetAttribute("StatNights"))
		if not nights or nights == 0 then
			record.Text = "HORROR  ·  1-4 PLAYERS"
			return
		end
		record.Text = string.format("NIGHTS %d  ·  SURVIVED %d  ·  ENDINGS %d/%d", nights, tonumber(player:GetAttribute("StatEscapes")) or 0, tonumber(player:GetAttribute("StatEndings")) or 0, tonumber(player:GetAttribute("StatEndingTotal")) or #ctx.Story.EndingOrder)
	end
	for _, a in { "StatNights", "StatEscapes", "StatEndings", "StatEndingTotal" } do
		player:GetAttributeChangedSignal(a):Connect(showRecord)
	end
	showRecord()

	-- the two ways to play: big, bright, a line under each (hidden while you're in a queue)
	quick = UI.new("Frame", { Name = "Quick", LayoutOrder = 3, Size = UDim2.fromOffset(MENU_W, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = menu })
	UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = quick })
	local function playButton(name: string, text: string, sub: string, order: number): (TextButton, TextLabel)
		local b = UI.new("TextButton", {
			Name = name,
			LayoutOrder = order,
			Size = UDim2.fromOffset(MENU_W, 60),
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(240, 236, 228),
			Parent = quick,
		})
		UI.corner(b, 10)
		UI.stroke(b, Color3.new(1, 1, 1), 1, 0.5)
		UI.label({ Name = "Text", Position = UDim2.fromOffset(18, 9), Size = UDim2.new(1, -30, 0, 24), Text = text, Font = UI.Font.Bold, TextSize = 21, TextColor3 = Color3.fromRGB(12, 12, 14), TextXAlignment = Enum.TextXAlignment.Left, Parent = b })
		local subL = UI.label({ Name = "Sub", Position = UDim2.fromOffset(18, 34), Size = UDim2.new(1, -30, 0, 16), Text = sub, Font = UI.Font.Body, TextSize = 12, TextColor3 = Color3.fromRGB(96, 92, 86), TextXAlignment = Enum.TextXAlignment.Left, Parent = b })
		local press = UI.new("UIScale", { Parent = b })
		b.Activated:Connect(function()
			press.Scale = 0.95
			UI.tween(press, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
		end)
		return b, subL
	end
	local solo = playButton("PlaySolo", "▶  PLAY SOLO", "just you and him", 1)
	local group, groupSub = playButton("FindPlayers", "FIND PLAYERS", "", 2)
	for b, kind in { [solo] = "Solo", [group] = "Group" } do
		b.Activated:Connect(function()
			ctx.Remotes.QuickPlay:FireServer(kind)
			if ctx.Effects then
				ctx.Effects.playSound("UISelect", nil, { Caption = false })
			end
		end)
	end
	-- (groups finish their nights far more often than solo players: say who's here to play with)
	local function showHere()
		local n = #Players:GetPlayers()
		groupSub.Text = n > 1 and string.format("%d players here now  ·  up to 4", n) or "1-4 players  ·  best with friends"
	end
	Players.PlayerAdded:Connect(showHere)
	Players.PlayerRemoving:Connect(function()
		task.defer(showHere)
	end)
	showHere()
	-- the night streak: start another night soon and it pays more (EconomyService)
	local streak = UI.label({ Name = "StreakLine", LayoutOrder = 3, Size = UDim2.fromOffset(MENU_W, 16), Text = "", Font = UI.Font.Bold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 205, 90), TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.5, Visible = false, Parent = quick })
	task.spawn(function()
		while streak.Parent do
			local untilT = tonumber(player:GetAttribute("ChainUntil"))
			local bonus = tonumber(player:GetAttribute("ChainNext")) or 0
			local left = untilT and math.floor(untilT - workspace:GetServerTimeNow()) or 0
			streak.Visible = left > 0 and bonus > 0
			if streak.Visible then
				streak.Text = string.format("🔥 NIGHT STREAK  +%d%% coins  ·  %d:%02d", bonus, left // 60, left % 60)
			end
			task.wait(1)
		end
	end)
	-- Halloween (until 2 Nov): candy hidden in the house, and what it unlocks
	local Cat = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Economy"))
	local event = UI.label({ LayoutOrder = 4, Size = UDim2.fromOffset(MENU_W, 16), AutomaticSize = Enum.AutomaticSize.Y, Text = "", Font = UI.Font.Bold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 150, 50), TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.5, Visible = false, Name = "HalloweenLine", Parent = quick })
	local function eventLine()
		local live = Cat.halloweenLive(workspace:GetServerTimeNow())
		event.Visible = live
		if live then
			local candy = tonumber(player:GetAttribute("Candy")) or 0
			local nxt = Cat.nextCandyReward(candy)
			event.Text = "🎃 HALLOWEEN  ·  🍬 " .. candy .. (nxt and ("  ·  next: " .. nxt.Name .. " (" .. nxt.Candy .. ")") or "  ·  all unlocked")
		end
	end
	eventLine()
	player:GetAttributeChangedSignal("Candy"):Connect(eventLine)

	-- the three extras: one glass card, a row each, hairlines between
	local extras = glass(UI, { Name = "Extras", LayoutOrder = 5, Size = UDim2.fromOffset(MENU_W, 3 * 40 + 2), Parent = menu })
	UI.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = extras })
	local function extraRow(name: string, text: string, order: number): (TextButton, TextLabel)
		if order > 1 then
			UI.new("Frame", { LayoutOrder = order * 2 - 1, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.88, Parent = extras })
		end
		local b = UI.new("TextButton", { Name = name, LayoutOrder = order * 2, Size = UDim2.new(1, 0, 0, 40), Text = "", BackgroundTransparency = 1, Parent = extras })
		UI.label({ Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -60, 1, 0), Text = text, Font = UI.Font.Body, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = b })
		local right = UI.label({ Name = "Right", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0, 70, 1, 0), Text = "›", Font = UI.Font.Bold, TextSize = 16, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Right, Parent = b })
		UI.hover(b, function()
			b.BackgroundTransparency = 0.92
		end, function()
			b.BackgroundTransparency = 1
		end)
		return b, right
	end
	local endingsBtn, endingsCount = extraRow("Endings", "Endings", 1)
	local howBtn = extraRow("HowToPlay", "How to play", 2)
	local settingsBtn = extraRow("Settings", "Settings", 3)
	local function showEndingCount()
		local n = tonumber(player:GetAttribute("StatEndings"))
		endingsCount.Text = n and string.format("%d / %d  ›", n, #ctx.Story.EndingOrder) or "›"
	end
	player:GetAttributeChangedSignal("StatEndings"):Connect(showEndingCount)
	showEndingCount()
	howBtn.Activated:Connect(function()
		ctx.Notice.show({
			Title = "HOW TO PLAY",
			Body = "It's a normal Friday night at the Whitaker house: pizza, chores, the storm. Then the power goes out, and you find out someone has been living in your attic.\n\n"
				.. "• Do your tasks (the ! markers and the panel at the top right show what's next).\n"
				.. "• When he's hunting, he hunts by SOUND: crouch and he can't hear you, run and he will. Or HIDE: closets, wardrobes, under beds. Keep still and he loses you.\n"
				.. "• If he stops at your hiding spot to listen, keep your heartbeat steady (press the side each half-heart flies in from).\n"
				.. "• Get help: call 911 from the one bar of signal by the upstairs bathroom window, reach the neighbor, or take the car.\n"
				.. "• Caught once, you're tied up in the boiler room: struggle free, or a friend can cut you loose. Caught twice and you're out.\n"
				.. "• Every night pays COINS. Spend them in the STORE on gear for your next night, or on crates.\n\n"
				.. #ctx.Story.EndingOrder .. " endings to find. Some of them are secret.",
			Button = "GOT IT",
		})
	end)
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
				Body = "Someone lives in the attic. Survive the night, alone or with friends.\n\nPLAY puts you in a group with whoever's here. Here are 100 coins to start: the STORE is on the right.",
				Button = "▶  PLAY",
			}, function()
				ctx.Remotes.QuickPlay:FireServer("Group") -- (ignored if they've already stepped into a circle)
			end)
		end
	end)

	-- your queue: at the top of the left-hand menu, in place of the play buttons
	panel = glass(UI, { Name = "QueuePanel", LayoutOrder = 2, Size = UDim2.fromOffset(MENU_W, 124), BackgroundTransparency = 0.18, Visible = false, Parent = lobbyMenu })
	queueTitle = UI.label({ Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 20), Text = "", Font = UI.Font.Bold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel })
	queueStatus = UI.label({ Position = UDim2.fromOffset(14, 32), Size = UDim2.new(1, -28, 0, 34), Text = "", TextSize = 12, TextWrapped = true, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = panel })
	-- (v138) the countdown as a bar draining under the text
	local track = UI.new("Frame", { Name = "CountdownBar", Position = UDim2.fromOffset(14, 70), Size = UDim2.new(1, -28, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85, Parent = panel })
	queueBar = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track })
	-- (v118) the only way out of a circle once you're in it: the walls hold queued players in
	local leave = UI.new("TextButton", {
		Name = "LeaveQueue",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -10, 1, -10),
		Size = UDim2.fromOffset(110, 36),
		Text = "✕  LEAVE",
		Font = UI.Font.Bold,
		TextSize = 14,
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
