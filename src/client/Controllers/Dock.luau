--[[
	Dock — the lobby's compact icons down the right edge (STORE, REWARDS, LOCKER, SHOP...) and
	your coin count at the top right. Other controllers add their icon (Dock.add) and build their
	panel with Dock.panel, so every panel looks and closes the same way (one open at a time).
]]

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local Dock = {}
local ctx
local player = Players.LocalPlayer

Dock.Gold = Color3.fromRGB(255, 205, 80)
Dock.Icon = 48 -- (v140, the owner: "Make everything smaller… Use only icons")
-- (v143, the owner: "UI should have names under them": each icon's name, small, under its tile)
Dock.LabelH = 14
Dock.CellW = 58
-- the dock's icon order (a second column wraps in after four)
Dock.Order = { Starter = 0, Store = 10, Rewards = 20, Codes = 25, Locker = 30, Shop = 40, Scare = 50, Invite = 60 }
local column: Frame
local openPanel: Frame? = nil

function Dock.init(c)
	ctx = c
	ctx.Dock = Dock
end

-- a little gold coin, drawn (no image needed)
function Dock.coin(parent: Instance, size: number, z: number?): Frame
	local UI = ctx.UI
	local c = UI.new("Frame", { Size = UDim2.fromOffset(size, size), BackgroundColor3 = Dock.Gold, ZIndex = z or 1, Parent = parent })
	UI.corner(c, size)
	UI.new("UIStroke", { Color = Color3.fromRGB(170, 110, 20), Thickness = math.max(1, size / 10), Parent = c })
	UI.label({ Size = UDim2.fromScale(1, 1), Text = "◆", TextSize = size * 0.55, TextColor3 = Color3.fromRGB(150, 96, 18), Font = Enum.Font.GothamBlack, ZIndex = (z or 1) + 1, Parent = c })
	return c
end

function Dock.format(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return out
end

--[[
	An icon in the dock. spec: { Order, Glyph, Label, Color?, OnClick }. Returns the button and
	its badge (a dot to show when something's waiting).
]]
function Dock.add(spec): (TextButton, Frame)
	local UI = ctx.UI
	-- (v138) one look for every icon: dark glass, a hairline, the glyph (its own colour) and a
	-- small label; it dips when pressed
	local b = UI.new("TextButton", {
		Name = "Dock_" .. tostring(spec.Label or "Icon"),
		LayoutOrder = spec.Order or 100,
		Size = UDim2.fromOffset(Dock.CellW, Dock.Icon + Dock.LabelH + 2),
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		ZIndex = 30,
		Parent = column,
	})
	-- the tile: dark glass, a hairline, the glyph in its own colour
	local tile = UI.new("Frame", {
		Name = "Tile",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(Dock.Icon, Dock.Icon),
		BackgroundColor3 = UI.Color.Glass,
		BackgroundTransparency = 0.22,
		ZIndex = 30,
		Parent = b,
	})
	UI.corner(tile, 10)
	local st = UI.stroke(tile, Color3.new(1, 1, 1), 1, 0.82)
	UI.label({ Name = "Glyph", Size = UDim2.fromScale(1, 1), Text = spec.Glyph, Font = UI.Font.Bold, TextSize = 22, TextColor3 = spec.Color or Color3.new(1, 1, 1), ZIndex = 31, Parent = tile })
	b:SetAttribute("Label", spec.Label)
	-- and its name under it (v143)
	UI.label({
		Name = "Name",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, Dock.Icon + 2),
		Size = UDim2.new(1, 8, 0, Dock.LabelH),
		Text = string.upper(tostring(spec.Label or "")),
		Font = UI.Font.Bold,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(226, 222, 214),
		TextStrokeTransparency = 0.45,
		ZIndex = 31,
		Parent = b,
	})
	local badge = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = UI.Color.Blood,
		Visible = false,
		ZIndex = 33,
		Parent = tile,
	})
	UI.corner(badge, 6)
	UI.stroke(badge, Color3.new(0, 0, 0), 1.5, 0.3)
	UI.label({ Name = "Text", Size = UDim2.fromScale(1, 1), Text = "", Font = UI.Font.Bold, TextSize = 9, ZIndex = 34, Parent = badge })
	local press = UI.new("UIScale", { Parent = b })
	UI.hover(b, function()
		st.Transparency = 0.45
	end, function()
		st.Transparency = 0.82
	end)
	b.Activated:Connect(function()
		press.Scale = 0.9
		UI.tween(press, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
		spec.OnClick()
	end)
	-- the badge pulses while it's showing
	local scale = UI.new("UIScale", { Parent = badge })
	task.spawn(function()
		local t = 0
		while badge.Parent do
			t += task.wait(1 / 20)
			if badge.Visible then
				scale.Scale = 1 + 0.2 * math.abs(math.sin(t * 3))
			end
		end
	end)
	return b, badge
end

--[[
	A panel: title, close button, optional tabs (each with a scrolling page). Returns
	{ Frame, Pages = { [tab] = ScrollingFrame }, select(tab), open(tab?), close(), Header (Frame) }.
]]
function Dock.panel(title: string, tabNames: { string }?, tabLabels: { [string]: string }?)
	local UI = ctx.UI
	local frame = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromScale(0.92, 0.84),
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.04,
		Visible = false,
		ZIndex = 40,
		Parent = UI.Root,
	})
	UI.corner(frame, 14)
	UI.stroke(frame, Color3.new(1, 1, 1), 1, 0.8)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(600, 480), Parent = frame })
	UI.modal(frame)
	-- (v138) the title in the house's typewriter face over a short red bar
	UI.label({ Name = "Title", Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -200, 0, 30), Text = title, Font = UI.Font.Title, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 41, Parent = frame })
	UI.new("Frame", { Position = UDim2.fromOffset(19, 41), Size = UDim2.fromOffset(34, 3), BackgroundColor3 = UI.Color.Blood, ZIndex = 41, Parent = frame })
	-- your coins, in every panel
	local wallet = UI.new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -62, 0, 14), Size = UDim2.fromOffset(120, 30), BackgroundTransparency = 1, ZIndex = 41, Parent = frame })
	Dock.coin(wallet, 22, 42).Position = UDim2.fromOffset(0, 4)
	local walletText = UI.label({ Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -28, 1, 0), Text = "", Font = UI.Font.Bold, TextSize = 18, TextColor3 = Dock.Gold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, Parent = wallet })
	local function showWallet()
		walletText.Text = Dock.format(tonumber(player:GetAttribute("Coins")) or 0)
	end
	showWallet()
	player:GetAttributeChangedSignal("Coins"):Connect(showWallet)
	local close = UI.new("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(44, 38),
		Text = "✕",
		Font = UI.Font.Bold,
		TextSize = 17,
		TextColor3 = UI.Color.Text,
		BackgroundColor3 = Color3.fromRGB(40, 40, 44),
		ZIndex = 41,
		Parent = frame,
	})
	UI.corner(close, 8)
	local P: any = { Frame = frame, Pages = {}, Tabs = {} }
	local names = tabNames or { "Main" }
	local top = tabNames and 92 or 52
	for i, name in names do
		if tabNames then
			local t = UI.new("TextButton", {
				Position = UDim2.fromOffset(18 + (i - 1) * 124, 52),
				Size = UDim2.fromOffset(116, 30),
				Text = (tabLabels and tabLabels[name]) or string.upper(name),
				Font = UI.Font.Bold,
				TextSize = 13,
				TextColor3 = UI.Color.Text,
				BackgroundColor3 = Color3.fromRGB(240, 238, 232),
				BackgroundTransparency = 0.85,
				ZIndex = 41,
				Parent = frame,
			})
			UI.corner(t, 8)
			t.Activated:Connect(function()
				P.select(name)
			end)
			P.Tabs[name] = t
		end
		local page = UI.new("ScrollingFrame", {
			Position = UDim2.fromOffset(14, top),
			Size = UDim2.new(1, -28, 1, -top - 12),
			BackgroundTransparency = 1,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 4,
			Visible = false,
			ZIndex = 41,
			Parent = frame,
		})
		UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
		UI.new("UIPadding", { PaddingRight = UDim.new(0, 6), Parent = page })
		P.Pages[name] = page
	end
	P.Current = names[1]
	function P.select(name: string)
		P.Current = name
		for k, page in P.Pages do
			page.Visible = k == name
			local t = P.Tabs[k]
			if t then
				t.BackgroundTransparency = k == name and 0 or 0.88
				t.TextColor3 = k == name and Color3.fromRGB(14, 14, 16) or UI.Color.Text
			end
		end
		if P.OnSelect then
			P.OnSelect(name)
		end
	end
	function P.open(tab: string?)
		if openPanel and openPanel ~= frame then
			openPanel.Visible = false
		end
		openPanel = frame
		frame.Visible = true
		P.select(tab or P.Current)
		if P.OnOpen then
			P.OnOpen()
		end
	end
	function P.close()
		frame.Visible = false
		if openPanel == frame then
			openPanel = nil
		end
	end
	function P.toggle(tab: string?)
		if frame.Visible then
			P.close()
		else
			P.open(tab)
		end
	end
	close.Activated:Connect(P.close)
	P.select(names[1])
	return P
end

-- a row card for lists: dark rounded frame
function Dock.row(parent: Instance, order: number, height: number): Frame
	local UI = ctx.UI
	local r = UI.new("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Color3.fromRGB(26, 26, 30), BackgroundTransparency = 0.1, ZIndex = 42, Parent = parent })
	UI.corner(r, 10)
	return r
end

-- a gold action button
function Dock.button(parent: Instance, text: string, props: { [string]: any }?): TextButton
	local UI = ctx.UI
	local b = UI.new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(112, 40),
		Text = text,
		Font = UI.Font.Bold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(14, 14, 16),
		BackgroundColor3 = Dock.Gold,
		ZIndex = 43,
		Parent = parent,
	})
	for k, v in (props or {}) :: any do
		(b :: any)[k] = v
	end
	UI.corner(b, 8)
	return b
end

function Dock.start()
	if ctx.Mode ~= "Lobby" then
		return
	end
	local UI = ctx.UI
	local inset = GuiService:GetGuiInset()
	-- (four icons down the right edge, then a second column to their left: v118's six didn't fit a
	-- phone's height in one)
	column = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -math.max(14, inset.X + 14), 0.5, 10),
		Size = UDim2.fromOffset(2 * Dock.CellW + 4, 4 * (Dock.Icon + Dock.LabelH + 2) + 3 * 6),
		BackgroundTransparency = 1,
		ZIndex = 30,
		Parent = UI.Root,
	})
	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(Dock.CellW, Dock.Icon + Dock.LabelH + 2),
		CellPadding = UDim2.fromOffset(4, 6),
		FillDirection = Enum.FillDirection.Vertical,
		FillDirectionMaxCells = 4,
		StartCorner = Enum.StartCorner.TopRight,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = column,
	})
	-- the coin count, top right (tap: the store)
	local pill = UI.new("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -math.max(14, inset.X + 14), 0, inset.Y + 10),
		Size = UDim2.fromOffset(102, 30),
		Text = "",
		BackgroundColor3 = UI.Color.Glass,
		BackgroundTransparency = 0.22,
		ZIndex = 30,
		Parent = UI.Root,
	})
	UI.corner(pill, 15)
	UI.stroke(pill, Dock.Gold, 1, 0.55)
	Dock.coin(pill, 20, 31).Position = UDim2.fromOffset(6, 5)
	local amount = UI.label({ Position = UDim2.fromOffset(31, 0), Size = UDim2.new(1, -36, 1, 0), Text = "0", Font = UI.Font.Bold, TextSize = 15, TextColor3 = Dock.Gold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 31, Parent = pill })
	local shown = tonumber(player:GetAttribute("Coins")) or 0
	amount.Text = Dock.format(shown)
	-- counts up (or down) when it changes
	player:GetAttributeChangedSignal("Coins"):Connect(function()
		local target = tonumber(player:GetAttribute("Coins")) or 0
		local from = shown
		shown = target
		task.spawn(function()
			local t0 = os.clock()
			while os.clock() - t0 < 0.6 and shown == target do
				local k = (os.clock() - t0) / 0.6
				amount.Text = Dock.format(from + (target - from) * k)
				task.wait()
			end
			if shown == target then
				amount.Text = Dock.format(target)
			end
		end)
		if target > from and ctx.Effects then
			ctx.Effects.playSound("UISelect", nil, { Caption = false })
		end
	end)
	-- your level, under the coins: a thin XP bar and "LV 7"
	local lvl = UI.new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 1, 4), Size = UDim2.fromOffset(98, 13), BackgroundTransparency = 1, ZIndex = 30, Parent = pill })
	local lvText = UI.label({ Size = UDim2.new(0, 38, 1, 0), Text = "", Font = UI.Font.Bold, TextSize = 11, TextColor3 = Dock.Gold, TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.5, ZIndex = 31, Parent = lvl })
	local track = UI.new("Frame", { Position = UDim2.new(0, 40, 0.5, -2), Size = UDim2.new(1, -42, 0, 4), BackgroundColor3 = Color3.fromRGB(40, 38, 36), BackgroundTransparency = 0.2, ZIndex = 31, Parent = lvl })
	UI.corner(track, 3)
	local fill = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Dock.Gold, ZIndex = 32, Parent = track })
	UI.corner(fill, 3)
	local function showLevel()
		local l = tonumber(player:GetAttribute("Level"))
		lvl.Visible = l ~= nil
		if l then
			lvText.Text = "LV " .. l
			local k = (tonumber(player:GetAttribute("XP")) or 0) / math.max(1, tonumber(player:GetAttribute("XPNext")) or 1)
			UI.tween(fill, 0.4, { Size = UDim2.fromScale(math.clamp(k, 0, 1), 1) })
		end
	end
	showLevel()
	for _, a in { "Level", "XP", "XPNext" } do
		player:GetAttributeChangedSignal(a):Connect(showLevel)
	end
	pill.Activated:Connect(function()
		if ctx.StoreUI then
			ctx.StoreUI.open("Items")
		end
	end)
	Dock.Pill = pill
	-- (v138) what sits under the coins and the level, top right (the codes chip)
	Dock.UnderPill = UDim2.new(1, -math.max(14, inset.X + 14), 0, inset.Y + 10 + 30 + 24)
end

return Dock
