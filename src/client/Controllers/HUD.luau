--[[
	HUD — clock, room name (Host), captions, notifications, chapter cards, the journal,
	inventory, stamina/battery, police ETA, struggle/call/breath meters and control hints.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local HUD = {}
local ctx
local player = Players.LocalPlayer

local UI
local root: Frame
local captionList: Frame
local notifyList: Frame
local journal: Frame
local journalList: Frame
local journalOpen = false
local objectives = {}

local ITEM_ORDER = { "Flashlight", "PepperSpray", "Walkie", "HouseKeys", "CarKeys", "BasementKey", "ElectricalTape", "Poker", "Multitool", "Scissors", "Remote", "PopcornBag", "PopcornBowl", "Firewood", "Matches" }
local ITEM_NAMES = {
	Flashlight = "Flashlight",
	Walkie = "Walkie-talkie",
	PepperSpray = "Pepper spray",
	HouseKeys = "House keys",
	CarKeys = "Car keys",
	BasementKey = "Basement key",
	ElectricalTape = "Electrical tape",
	Poker = "Fire poker",
	Multitool = "Multitool",
	Scissors = "Scissors",
	Remote = "TV remote",
	PopcornBag = "Bag of popcorn",
	PopcornBowl = "Bowl of popcorn",
	Firewood = "Firewood",
	Matches = "Matches",
}

local ACT_NAMES = {
	Lobby = "",
	Evening = "I. Friday Night",
	SmallThings = "II. Small Things",
	SomeoneElse = "III. Someone Else",
	Guest = "IV. The Guest",
}

---------------------------------------------------------------------------
-- Captions & notifications
---------------------------------------------------------------------------
local recentCaptions = {}

function HUD.caption(text: string, _position: Vector3?)
	if recentCaptions[text] and os.clock() - recentCaptions[text] < 1.5 then
		return
	end
	-- sound captions are extras: skip them while something else is being said
	if ctx.Pace and not ctx.Pace.tryTake(1.6) then
		return
	end
	recentCaptions[text] = os.clock()
	local isSound = text:sub(1, 1) == "["
	local l = UI.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		TextSize = 23,
		Font = isSound and UI.Font.Bold or UI.Font.Body,
		TextColor3 = isSound and Color3.fromRGB(215, 215, 200) or UI.Color.Text,
		TextStrokeTransparency = 0.4,
		TextTransparency = 1,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		LayoutOrder = math.floor(os.clock() * 100),
		Parent = captionList,
	})
	UI.tween(l, 0.25, { TextTransparency = 0 })
	local kids = {}
	for _, c in captionList:GetChildren() do
		if c:IsA("TextLabel") then
			table.insert(kids, c)
		end
	end
	if #kids > 4 then
		table.sort(kids, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		kids[1]:Destroy()
	end
	local life = math.clamp(#text / 18, 3.5, 8)
	task.delay(life, function()
		if l.Parent then
			UI.tween(l, 0.6, { TextTransparency = 1, TextStrokeTransparency = 1 })
			task.wait(0.6)
			l:Destroy()
		end
	end)
end

local KIND_COLOR = {}

-- Toasts don't land on top of a thought line or a conversation: they wait until the screen
-- has been clear for a moment, then come in one by one ("done" ticks are instant feedback).
local pendingNotes = {}
local pumping = false
local showNote

local function screenBusy(): boolean
	return (ctx.Thoughts ~= nil and ctx.Thoughts.isShowing()) or (ctx.Dialogue ~= nil and ctx.Dialogue.isOpen())
end

local function pumpNotes()
	if pumping then
		return
	end
	pumping = true
	while #pendingNotes > 0 do
		if ctx.Pace then
			ctx.Pace.take(3.2)
		else
			local clearFor = 0
			while clearFor < 1.2 do
				task.wait(0.1)
				clearFor = screenBusy() and 0 or clearFor + 0.1
			end
		end
		local n = table.remove(pendingNotes, 1)
		showNote(n[1], n[2])
	end
	pumping = false
end

function HUD.notify(text: string, kind: string?)
	-- every note takes its turn (the same text twice in the queue is noise)
	for _, n in pendingNotes do
		if n[1] == text then
			return
		end
	end
	table.insert(pendingNotes, { text, kind })
	task.spawn(pumpNotes)
end

showNote = function(text: string, kind: string?)
	if kind == "done" and ctx.Effects then
		ctx.Effects.playSound("ObjectiveDone", nil, { Caption = false })
	end
	local color = KIND_COLOR[kind or "info"] or UI.Color.Text
	local frame = UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.25,
		LayoutOrder = math.floor(os.clock() * 100),
		Parent = notifyList,
	})
	UI.corner(frame, 8)
	UI.padding(frame, 8)
	UI.new("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = color, Parent = frame })
	UI.label({
		Size = UDim2.new(1, -10, 0, 0),
		Position = UDim2.fromOffset(10, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	local kids = {}
	for _, c in notifyList:GetChildren() do
		if c:IsA("Frame") then
			table.insert(kids, c)
		end
	end
	if #kids > 3 then
		table.sort(kids, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		kids[1]:Destroy()
	end
	task.delay(6, function()
		if frame.Parent then
			UI.tween(frame, 0.5, { BackgroundTransparency = 1 })
			for _, d in frame:GetDescendants() do
				if d:IsA("TextLabel") then
					UI.tween(d, 0.5, { TextTransparency = 1 })
				elseif d:IsA("Frame") then
					UI.tween(d, 0.5, { BackgroundTransparency = 1 })
				end
			end
			task.wait(0.5)
			frame:Destroy()
		end
	end)
end

---------------------------------------------------------------------------
-- Chapter card
---------------------------------------------------------------------------
local chapterFrame: Frame
local chapterTitle: TextLabel
local chapterSub: TextLabel

function HUD.chapter(title: string, sub: string)
	-- wait for the role notice (or any notice) to be dismissed first
	if ctx.Notice and ctx.Notice.isOpen() then
		ctx.Notice.whenClear(function()
			task.wait(0.3)
			HUD.chapter(title, sub)
		end)
		return
	end
	chapterTitle.Text = title
	chapterSub.Text = sub
	chapterFrame.Visible = true
	chapterTitle.TextTransparency = 1
	chapterSub.TextTransparency = 1
	UI.tween(chapterTitle, 1.5, { TextTransparency = 0 })
	task.delay(0.6, function()
		UI.tween(chapterSub, 1.5, { TextTransparency = 0.15 })
	end)
	task.delay(6, function()
		if chapterTitle.Text == title then
			UI.tween(chapterTitle, 1.5, { TextTransparency = 1 })
			UI.tween(chapterSub, 1.5, { TextTransparency = 1 })
		end
	end)
end

---------------------------------------------------------------------------
-- Journal (objectives)
---------------------------------------------------------------------------
local objPanel: Frame
local objTitle: TextLabel
local objStep: TextLabel
local objProgress: TextLabel
local lastFocus = { Id = nil, Done = -1 }

-- the task the group should do next: the first unfinished required one, else any unfinished one
local function focusObjective()
	-- once help is on the way, staying alive is the only thing that matters
	for _, o in objectives do
		if o.Id == "Survive" and not o.Done then
			return o
		end
	end
	for _, o in objectives do
		if not o.Done and not o.Optional then
			return o
		end
	end
	for _, o in objectives do
		if not o.Done then
			return o
		end
	end
	return nil
end
HUD.focusObjective = focusObjective

local function renderObjectivePanel()
	local o = focusObjective()
	if not o then
		objPanel.Visible = false
		return
	end
	objPanel.Visible = true
	objTitle.Text = o.Text
	objStep.Text = o.Current and ("›  " .. o.Current) or ""
	local total = #(o.Steps or {})
	objProgress.Text = total > 1 and string.format("Step %d of %d", math.min((o.StepsDone or 0) + 1, total), total) or ""
	-- a step just got done: a little flash
	if lastFocus.Id == o.Id and (o.StepsDone or 0) > lastFocus.Done then
		objPanel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		UI.tween(objPanel, 0.8, { BackgroundColor3 = UI.Color.Panel })
		if ctx.Effects then
			ctx.Effects.playSound("ObjectiveDone", nil, { Caption = false, Volume = 0.2 })
		end
	end
	lastFocus = { Id = o.Id, Done = o.StepsDone or 0 }
end

local function renderJournal()
	for _, c in journalList:GetChildren() do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	local order = 0
	local function line(text: string, size: number, color: Color3)
		order += 1
		UI.label({
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = text,
			TextSize = size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = color,
			LayoutOrder = order,
			Parent = journalList,
		})
	end
	for _, o in objectives do
		local mark = o.Done and "<font color=\"#d8d8d8\">✓</font> " or (o.Optional and "◦ " or "• ")
		line(mark .. (o.Done and ("<s>" .. o.Text .. "</s>") or ("<b>" .. o.Text .. "</b>")), 18, o.Done and UI.Color.Dim or UI.Color.Text)
		if not o.Done then
			for _, st in o.Steps or {} do
				line("      " .. (st.Done and "<font color=\"#d8d8d8\">✓</font> <s>" .. st.Text .. "</s>" or "–  " .. st.Text), 15, st.Done and UI.Color.Dim or Color3.fromRGB(205, 200, 190))
			end
		end
	end
	renderObjectivePanel()
end

function HUD.setJournal(open: boolean)
	journalOpen = open
	journal.Visible = open
end

function HUD.toggleJournal()
	HUD.setJournal(not journalOpen)
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------
local clockLabel: TextLabel
local actLabel: TextLabel
local roomLabel: TextLabel
local inventoryLabel: TextLabel
local hintLabel: TextLabel
local staminaBar: Frame
local staminaFill: Frame
local meterFrame: Frame
local meterFill: Frame
local meterLabel: TextLabel
local etaLabel: TextLabel
local crosshair: Frame

local function bar(parent, width, color)
	local frame = UI.new("Frame", {
		Size = UDim2.fromOffset(width, 6),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		Parent = parent,
	})
	UI.corner(frame, 3)
	local fill = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, Parent = frame })
	UI.corner(fill, 3)
	return frame, fill
end

local function build()
	root = UI.new("Frame", { Name = "HUD", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = UI.Root })
	local inset = GuiService:GetGuiInset()

	-- clock (top-left, under the Roblox top bar)
	local clock = UI.new("Frame", {
		Name = "Clock",
		Position = UDim2.fromOffset(18, inset.Y + 10),
		Size = UDim2.fromOffset(260, 70),
		BackgroundTransparency = 1,
		Parent = root,
	})
	clockLabel = UI.label({ Size = UDim2.new(1, 0, 0, 30), Text = "", Font = UI.Font.Title, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.6, Parent = clock })
	actLabel = UI.label({ Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 18), Text = "", TextSize = 15, Font = UI.Font.Bold, TextColor3 = Color3.fromRGB(214, 208, 196), TextStrokeTransparency = 0.45, TextXAlignment = Enum.TextXAlignment.Left, Parent = clock })
	roomLabel = UI.label({ Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, 18), Text = "", TextSize = 15, Font = UI.Font.Bold, TextColor3 = UI.Color.Accent, TextStrokeTransparency = 0.45, TextXAlignment = Enum.TextXAlignment.Left, Parent = clock })

	-- police ETA (top center)
	etaLabel = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, inset.Y + 8),
		Size = UDim2.fromOffset(320, 26),
		Text = "",
		Font = UI.Font.Bold,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(235, 235, 235),
		TextStrokeTransparency = 0.5,
		Parent = root,
	})

	-- notifications (top center)
	notifyList = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, inset.Y + 38),
		Size = UDim2.fromOffset(460, 200),
		BackgroundTransparency = 1,
		Parent = root,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = notifyList })

	-- captions (bottom center)
	captionList = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(620, 160),
		BackgroundTransparency = 1,
		Parent = root,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Parent = captionList })

	-- chapter card
	chapterFrame = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromOffset(800, 120), BackgroundTransparency = 1, Visible = false, Parent = root })
	chapterTitle = UI.label({ Size = UDim2.new(1, 0, 0, 64), Text = "", Font = UI.Font.Title, TextSize = 54, TextTransparency = 1, TextStrokeTransparency = 0.7, Parent = chapterFrame })
	chapterSub = UI.label({ Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 0, 28), Text = "", TextSize = 20, TextColor3 = UI.Color.Dim, TextTransparency = 1, Parent = chapterFrame })

	-- objective panel (top right; below the touch JOURNAL/PHONE buttons on phones)
	local topY = inset.Y + (UI.isTouch() and 54 or 10)
	objPanel = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, topY),
		Size = UDim2.fromOffset(360, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.3,
		Visible = false,
		Parent = root,
	})
	UI.corner(objPanel, 10)
	UI.padding(objPanel, 12)
	UI.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = objPanel })
	UI.label({ Size = UDim2.new(1, 0, 0, 18), Text = "OBJECTIVE", Font = UI.Font.Bold, TextSize = 15, TextColor3 = UI.Color.Accent, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Parent = objPanel })
	objTitle = UI.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = "", Font = UI.Font.Bold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Parent = objPanel })
	objStep = UI.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = "", TextSize = 18, TextColor3 = Color3.fromRGB(215, 210, 200), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 3, Parent = objPanel })
	objProgress = UI.label({ Size = UDim2.new(1, 0, 0, 16), Text = "", TextSize = 13, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 4, Parent = objPanel })

	-- journal (right, under the objective panel)
	journal = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, topY + 140),
		Size = UDim2.fromOffset(330, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.25,
		Visible = false,
		Parent = root,
	})
	UI.corner(journal, 10)
	UI.padding(journal, 12)
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = journal })
	UI.label({ Size = UDim2.new(1, 0, 0, 24), Text = "TONIGHT", Font = UI.Font.Title, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = journal })
	journalList = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = journal })
	UI.new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = journalList })

	-- inventory (bottom-left)
	inventoryLabel = UI.label({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 18, 1, -18),
		Size = UDim2.fromOffset(300, 150),
		Text = "",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		TextStrokeTransparency = 0.6,
		Parent = root,
	})

	-- stamina + context meter + hints (bottom center)
	staminaBar, staminaFill = bar(root, 220, Color3.fromRGB(220, 220, 210))
	staminaBar.AnchorPoint = Vector2.new(0.5, 1)
	staminaBar.Position = UDim2.new(0.5, 0, 1, -28)
	meterFrame = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -60), Size = UDim2.fromOffset(320, 36), BackgroundTransparency = 1, Visible = false, Parent = root })
	meterLabel = UI.label({ Size = UDim2.new(1, 0, 0, 20), Text = "", Font = UI.Font.Bold, TextSize = 16, Parent = meterFrame })
	local mf, fill = bar(meterFrame, 320, UI.Color.Accent)
	mf.Position = UDim2.fromOffset(0, 24)
	meterFill = fill
	hintLabel = UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.fromOffset(700, 24),
		Text = "",
		TextSize = 18,
		TextColor3 = UI.Color.Dim,
		Parent = root,
	})

	crosshair = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.6, Parent = root })
	UI.corner(crosshair, 2)
end

---------------------------------------------------------------------------
-- Per-frame / attribute updates
---------------------------------------------------------------------------
local function updateInventory()
	local lines = {}
	for _, id in ITEM_ORDER do
		local n = player:GetAttribute("Item_" .. id)
		if n then
			local line = ITEM_NAMES[id]
			if id == "Flashlight" then
				local b = math.floor(player:GetAttribute("Battery") or 0)
				line ..= string.format("  <font color=\"#%s\">%d%%</font>", b > 25 and "d8d4c8" or "dc4638", b)
				if player:GetAttribute("FlashlightOn") then
					line ..= "  (on)"
				end
			elseif id == "PepperSpray" then
				line ..= " ×" .. n
			end
			table.insert(lines, line)
		end
	end
	inventoryLabel.Text = table.concat(lines, "\n")
end

local function hintText(): string
	local touch = UI.isTouch()
	if workspace:GetAttribute("EndingActive") then
		return ""
	end
	if player:GetAttribute("Captured") then
		return touch and "Mash STRUGGLE" or "Mash SPACE to struggle"
	end
	if player:GetAttribute("Hiding") then
		return touch and "LEAVE to get out" or "E to leave"
	end
	return ""
end

local function update()
	local act = workspace:GetAttribute("Act") or "Lobby"
	local mins = workspace:GetAttribute("ClockMinutes")
	clockLabel.Text = (act ~= "Lobby" and mins) and ctx.Util.clockString(mins) or ""
	actLabel.Text = ACT_NAMES[act] or ""
	if player:GetAttribute("Role") == "Host" and act ~= "Lobby" then
		local cam = workspace.CurrentCamera
		local r = cam and ctx.Rooms.find(cam.CFrame.Position)
		roomLabel.Text = r and r.Display or "Outside"
	else
		roomLabel.Text = ""
	end

	-- police ETA
	local eta = workspace:GetAttribute("PoliceETA")
	if eta then
		etaLabel.Text = "Police: " .. ctx.Util.formatSeconds(eta - workspace:GetServerTimeNow())
	else
		etaLabel.Text = ""
	end

	-- stamina
	local stamina = player:GetAttribute("Stamina") or 100
	staminaFill.Size = UDim2.fromScale(stamina / 100, 1)
	staminaBar.Visible = stamina < 99 and player:GetAttribute("InGame") == true

	-- context meter
	local label, value, color = nil, 0, UI.Color.Accent
	if player:GetAttribute("Captured") then
		label, value, color = "STRUGGLE", player:GetAttribute("StruggleProgress") or 0, UI.Color.Danger
	elseif player:GetAttribute("Calling") then
		label, value, color = "Calling 911 - keep the signal", player:GetAttribute("CallProgress") or 0, UI.Color.Info
	elseif player:GetAttribute("Hiding") then
		label, value = player:GetAttribute("HoldingBreath") and "Holding your breath" or "Breath", player:GetAttribute("Breath") or 1
		color = player:GetAttribute("HoldingBreath") and UI.Color.Info or Color3.fromRGB(200, 200, 190)
	end
	meterFrame.Visible = label ~= nil
	if label then
		meterLabel.Text = label
		meterFill.Size = UDim2.fromScale(math.clamp(value, 0, 1), 1)
		meterFill.BackgroundColor3 = color
	end

	-- keep the top of the HUD clear of the Roblox top bar (and, on phones, of the JOURNAL/PHONE
	-- buttons). The inset is in screen pixels but our offsets get scaled, so divide it back out.
	local s = UI.Scale or 1
	local insetY = GuiService:GetGuiInset().Y
	local clock = root:FindFirstChild("Clock") :: Frame?
	if clock then
		clock.Position = UDim2.fromOffset(18, (insetY + 8) / s)
	end
	local topY = (insetY + (UI.isTouch() and 52 or 10)) / s
	objPanel.Position = UDim2.new(1, -18, 0, topY)
	if UI.isTouch() then
		-- on phones the right side belongs to the action buttons: the journal opens in the middle
		journal.AnchorPoint = Vector2.new(0.5, 0.5)
		journal.Position = UDim2.fromScale(0.5, 0.45)
	else
		journal.AnchorPoint = Vector2.new(1, 0)
		journal.Position = UDim2.new(1, -18, 0, topY + 140)
	end
	etaLabel.Position = UDim2.new(0.5, 0, 0, (insetY + 8) / s)
	notifyList.Position = UDim2.new(0.5, 0, 0, (insetY + 8) / s + 30)
	-- on touch screens the thumbstick owns the bottom-left corner
	if UI.isTouch() then
		inventoryLabel.AnchorPoint = Vector2.new(0, 0)
		inventoryLabel.Position = UDim2.fromOffset(18, (insetY + 8) / s + 74)
		inventoryLabel.TextYAlignment = Enum.TextYAlignment.Top
	else
		inventoryLabel.AnchorPoint = Vector2.new(0, 1)
		inventoryLabel.Position = UDim2.new(0, 18, 1, -18)
		inventoryLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	end
	hintLabel.Text = hintText()
	crosshair.Visible = player:GetAttribute("InGame") == true and not player:GetAttribute("Hiding")
	root.Visible = not workspace:GetAttribute("EndingActive")
end

function HUD.init(c)
	ctx = c
	UI = ctx.UI
	ctx.HUD = HUD
	KIND_COLOR = {
		objective = UI.Color.Accent,
		done = UI.Color.Good,
		danger = UI.Color.Danger,
		text = UI.Color.Info,
		info = UI.Color.Text,
	}
end

function HUD.start()
	build()
	ctx.Remotes.Caption.OnClientEvent:Connect(HUD.caption)
	ctx.Remotes.Notify.OnClientEvent:Connect(HUD.notify)
	ctx.Remotes.Chapter.OnClientEvent:Connect(HUD.chapter)
	-- the journal stays closed until the player opens it (their thoughts point them to it)
	ctx.Remotes.Objectives.OnClientEvent:Connect(function(list)
		objectives = list
		renderJournal()
	end)
	ctx.Input.on("Journal", function(began)
		if began then
			HUD.toggleJournal()
		end
	end)
	player.AttributeChanged:Connect(function(name)
		if name:sub(1, 5) == "Item_" or name == "Battery" or name == "FlashlightOn" then
			updateInventory()
		end
	end)
	updateInventory()
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		if acc >= 0.1 then
			acc = 0
			update()
		end
	end)
end

return HUD
