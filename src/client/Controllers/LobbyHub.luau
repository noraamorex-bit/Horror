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
	if (tonumber(player:GetAttribute("StatEscapes")) or 0) >= 1 and #lines < 4 then
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
		Position = UDim2.new(0.5, 0, 0, inset.Y + 78),
		Size = UDim2.fromOffset(400, 64 + 20 * #lines),
		BackgroundColor3 = Color3.fromRGB(12, 12, 14),
		BackgroundTransparency = 0.15,
		Parent = UI.Root,
	})
	UI.corner(card, 10)
	UI.stroke(card, Color3.new(1, 1, 1), 1, 0.75)
	UI.label({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -150, 0, 22), Text = "BACK FOR ANOTHER NIGHT?", Font = UI.Font.Bold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
	for i, line in lines do
		UI.label({
			Position = UDim2.fromOffset(14, 32 + (i - 1) * 20),
			Size = UDim2.new(1, -28, 0, 20),
			Text = line,
			RichText = true,
			TextSize = 13,
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

function LobbyHub.start()
	local UI = ctx.UI
	thirdPerson()
	local lp = game:GetService("Players").LocalPlayer
	lp.CharacterAdded:Connect(function()
		task.defer(thirdPerson)
		task.delay(1, thirdPerson)
	end)
	task.delay(2, thirdPerson)
	local inset = GuiService:GetGuiInset()
	local title = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, inset.Y + 10),
		Size = UDim2.fromOffset(620, 84),
		BackgroundTransparency = 1,
		Parent = UI.Root,
	})
	UI.label({ Size = UDim2.new(1, 0, 0, 50), Text = ctx.Story.Title, Font = UI.Font.Title, TextSize = 34, TextStrokeTransparency = 0.6, Parent = title })
	-- a menu down the left side: the two ways to play first (big, bright), then the extras.
	-- Sized for thumbs: the whole UI is scaled down on phones (UIScale), so these stay tappable.
	local MENU_W = 200
	local function menuButton(parent, text: string, order: number, primary: boolean?): TextButton
		local b = UI.new("TextButton", {
			LayoutOrder = order,
			Size = UDim2.fromOffset(MENU_W, primary and 54 or 38),
			Text = text,
			Font = primary and UI.Font.Bold or Enum.Font.GothamMedium,
			TextSize = primary and 21 or 16,
			TextColor3 = primary and Color3.fromRGB(12, 12, 14) or Color3.fromRGB(235, 232, 226),
			BackgroundColor3 = primary and Color3.fromRGB(240, 236, 228) or Color3.fromRGB(12, 12, 14),
			BackgroundTransparency = primary and 0 or 0.35,
			Parent = parent,
		})
		UI.corner(b, primary and 10 or 8)
		UI.stroke(b, Color3.new(1, 1, 1), 1, primary and 0.5 or 0.8)
		return b
	end
	local menu = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, math.max(16, inset.X + 16), 0, inset.Y + 10),
		Size = UDim2.fromOffset(MENU_W, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = UI.Root,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menu })
	-- one-tap play (hidden while you're in a queue)
	quick = UI.new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(MENU_W, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = menu })
	UI.new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = quick })
	for i, spec in { { "▶  PLAY SOLO", "Solo" }, { "FIND PLAYERS", "Group" } } do
		local b = menuButton(quick, spec[1], i, true)
		b.Activated:Connect(function()
			ctx.Remotes.QuickPlay:FireServer(spec[2])
			if ctx.Effects then
				ctx.Effects.playSound("UISelect", nil, { Caption = false })
			end
		end)
	end
	-- the night streak: start another night soon and it pays more (EconomyService)
	local streak = UI.label({ LayoutOrder = 3, Size = UDim2.fromOffset(MENU_W, 16), Text = "", Font = UI.Font.Bold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 205, 90), TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.5, Visible = false, Parent = quick })
	task.spawn(function()
		local me = game:GetService("Players").LocalPlayer
		while streak.Parent do
			local untilT = tonumber(me:GetAttribute("ChainUntil"))
			local bonus = tonumber(me:GetAttribute("ChainNext")) or 0
			local left = untilT and math.floor(untilT - workspace:GetServerTimeNow()) or 0
			streak.Visible = left > 0 and bonus > 0
			if streak.Visible then
				streak.Text = string.format("NIGHT STREAK  +%d%% coins  ·  %d:%02d", bonus, left // 60, left % 60)
			end
			task.wait(1)
		end
	end)
	-- Halloween (until 2 Nov): candy hidden in the house, and what it unlocks
	local Cat = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Economy"))
	local event = UI.label({ LayoutOrder = 4, Size = UDim2.fromOffset(MENU_W, 16), AutomaticSize = Enum.AutomaticSize.Y, Text = "", Font = UI.Font.Bold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 150, 50), TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.5, Visible = false, Name = "HalloweenLine", Parent = quick })
	local function eventLine()
		local me = game:GetService("Players").LocalPlayer
		local live = Cat.halloweenLive(workspace:GetServerTimeNow())
		event.Visible = live
		if live then
			local candy = tonumber(me:GetAttribute("Candy")) or 0
			local nxt = Cat.nextCandyReward(candy)
			event.Text = "🎃 HALLOWEEN  ·  🍬 " .. candy .. (nxt and ("  ·  next: " .. nxt.Name .. " (" .. nxt.Candy .. ")") or "  ·  all unlocked")
		end
	end
	eventLine()
	game:GetService("Players").LocalPlayer:GetAttributeChangedSignal("Candy"):Connect(eventLine)
	UI.new("Frame", { LayoutOrder = 2, Size = UDim2.fromOffset(MENU_W, 6), BackgroundTransparency = 1, Parent = menu })
	-- (just the three extras; coins, the locker, rewards and the shop are icons on the right: Dock)
	local endingsBtn = menuButton(menu, "Endings", 3)
	menuButton(menu, "How to play", 8).Activated:Connect(function()
		ctx.Notice.show({
			Title = "HOW TO PLAY",
			Body = "It's a normal Friday night at the Whitaker house: pizza, chores, the storm. Then the power goes out, and you find out someone has been living in your attic.\n\n"
				.. "• Do your tasks (the ! markers and the panel at the top right show what's next).\n"
				.. "• When he's hunting, he hunts by SOUND: crouch and he can't hear you, run and he will. Or HIDE: closets, wardrobes, under beds.\n"
				.. "• If he stops at your hiding spot to listen, keep your heartbeat steady (press the side each half-heart flies in from).\n"
				.. "• Get help: call 911 from the one bar of signal by the upstairs bathroom window (or fix the phone line outside), reach the neighbor, or take the car.\n"
				.. "• Caught once, you're tied up in the boiler room: struggle free, or a friend can cut you loose. Caught twice and you're out.\n"
				.. "• Every night pays COINS. Spend them in the STORE on gear for your next night, or on crates.\n\n"
				.. #ctx.Story.EndingOrder .. " endings to find. Some of them are secret.",
			Button = "GOT IT",
		})
	end)
	menuButton(menu, "Settings", 7).Activated:Connect(function()
		if ctx.Settings then
			ctx.Settings.open()
		end
	end)
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
		local best = player:GetAttribute("StatBest")
		if type(best) == "number" and best > 0 then
			record.Text ..= "   ·   BEST " .. ctx.Util.formatSeconds(best)
		end
	end
	for _, a in { "StatNights", "StatEscapes", "StatEndings", "StatBest" } do
		player:GetAttributeChangedSignal(a):Connect(showRecord)
	end
	showRecord()

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
	panel = UI.new("Frame", {
		LayoutOrder = 0,
		Size = UDim2.fromOffset(MENU_W, 112),
		BackgroundColor3 = Color3.fromRGB(12, 12, 14),
		BackgroundTransparency = 0.3,
		Visible = false,
		Parent = lobbyMenu,
	})
	UI.corner(panel, 8)
	UI.stroke(panel, Color3.new(1, 1, 1), 1, 0.8)
	queueTitle = UI.label({ Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 20), Text = "", Font = UI.Font.Bold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel })
	queueStatus = UI.label({ Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 0, 34), Text = "", TextSize = 13, TextWrapped = true, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = panel })
	-- (v118) the only way out of a circle once you're in it: the walls hold queued players in
	local leave = UI.new("TextButton", {
		Name = "LeaveQueue",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -8, 1, -8),
		Size = UDim2.fromOffset(110, 38),
		Text = "✕  LEAVE",
		Font = UI.Font.Bold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 236, 232),
		BackgroundColor3 = Color3.fromRGB(120, 28, 30),
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
