--[[
	Shop — the lobby's SHOP button (with a pulsing "!" until you've had a look) and the shop
	panel: game passes (Config.Shop.Passes) and donations (Config.Shop.Donations) with the top
	supporters. The donation board in the lobby opens it on the Support tab.

	Purchases are prompted here; the server (ShopService) grants them. Also shows the lobby's
	notifications (thank-yous, unlocks) as a short toast at the top.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local Shop = {}
local ctx

local GOLD = Color3.fromRGB(255, 214, 120)
local player = Players.LocalPlayer

local panel: Frame
local badge: Frame
local tabs = {}
local pages = {}
local passRows = {}
local donorList: Frame
local toastBox: Frame
local toastText: TextLabel
local toastSeq = 0

local function toast(text: string)
	if not toastBox then
		return
	end
	toastSeq += 1
	local seq = toastSeq
	toastText.Text = text
	toastBox.Visible = true
	task.delay(4, function()
		if seq == toastSeq then
			toastBox.Visible = false
		end
	end)
end

local function refreshPasses()
	for _, r in passRows do
		local owned = player:GetAttribute("Pass_" .. r.Pass.Key) == true
		if owned then
			r.Buy.Text = "OWNED"
			r.Buy.AutoButtonColor = false
			r.Buy.BackgroundTransparency = 0.8
		elseif r.Pass.Id == 0 then
			r.Buy.Text = "SOON"
			r.Buy.AutoButtonColor = false
			r.Buy.BackgroundTransparency = 0.8
		else
			r.Buy.Text = "R$ " .. tostring(r.Price or r.Pass.Price)
			r.Buy.AutoButtonColor = true
			r.Buy.BackgroundTransparency = 0
		end
	end
end

local function refreshDonors()
	if not donorList then
		return
	end
	for _, c in donorList:GetChildren() do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	local ok, top = pcall(function()
		return HttpService:JSONDecode(workspace:GetAttribute("TopDonors") or "[]")
	end)
	if not ok or type(top) ~= "table" then
		top = {}
	end
	if #top == 0 then
		ctx.UI.label({ LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 22), Text = "No supporters yet. Be the first!", TextSize = 14, TextColor3 = ctx.UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = donorList })
	end
	for i, e in top do
		ctx.UI.label({
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 22),
			Text = string.format("%d.  %s   <font color=\"#9a968e\">%d R$</font>", i, tostring(e.Name), tonumber(e.Amount) or 0),
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 43,
			Parent = donorList,
		})
	end
end

local function select(name: string)
	for k, page in pages do
		page.Visible = k == name
		tabs[k].BackgroundTransparency = k == name and 0 or 0.85
		tabs[k].TextColor3 = k == name and Color3.fromRGB(14, 14, 16) or ctx.UI.Color.Text
	end
end

function Shop.open(tab: string?)
	if not panel then
		return
	end
	panel.Visible = true
	badge.Visible = false
	select(tab or "Passes")
	refreshPasses()
	refreshDonors()
end

function Shop.init(c)
	ctx = c
	ctx.ShopUI = Shop
end

function Shop.toast(text: string)
	toast(text)
end

function Shop.start()
	if ctx.Mode ~= "Lobby" then
		return
	end
	local UI = ctx.UI
	local inset = GuiService:GetGuiInset()

	-- the button: an icon in the lobby dock, with a "!" until you've had a look
	local _
	_, badge = ctx.Dock.add({ Order = 4, Glyph = "R$", Label = "SHOP", Color = GOLD, OnClick = function()
		if panel.Visible then
			panel.Visible = false
		else
			Shop.open()
		end
	end })
	badge.Visible = true

	-- the panel
	panel = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.92, 0.84),
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.05,
		Visible = false,
		ZIndex = 40,
		Parent = UI.Root,
	})
	UI.corner(panel, 14)
	UI.stroke(panel, Color3.new(1, 1, 1), 1, 0.78)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(560, 470), Parent = panel })
	UI.label({ Position = UDim2.fromOffset(18, 12), Size = UDim2.new(1, -80, 0, 30), Text = "SHOP", Font = UI.Font.Bold, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 41, Parent = panel })
	local close = UI.new("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(40, 36),
		Text = "X",
		Font = UI.Font.Bold,
		TextSize = 18,
		TextColor3 = UI.Color.Text,
		BackgroundColor3 = Color3.fromRGB(40, 40, 44),
		ZIndex = 41,
		Parent = panel,
	})
	UI.corner(close, 8)
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	for i, name in { "Passes", "Support" } do
		local t = UI.new("TextButton", {
			Position = UDim2.fromOffset(18 + (i - 1) * 132, 50),
			Size = UDim2.fromOffset(124, 32),
			Text = name == "Passes" and "GAME PASSES" or "SUPPORT",
			Font = UI.Font.Bold,
			TextSize = 14,
			TextColor3 = UI.Color.Text,
			BackgroundColor3 = Color3.fromRGB(240, 238, 232),
			BackgroundTransparency = 0.85,
			ZIndex = 41,
			Parent = panel,
		})
		UI.corner(t, 8)
		t.Activated:Connect(function()
			select(name)
		end)
		tabs[name] = t
		local page = UI.new("ScrollingFrame", {
			Position = UDim2.fromOffset(14, 92),
			Size = UDim2.new(1, -28, 1, -104),
			BackgroundTransparency = 1,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 4,
			Visible = false,
			ZIndex = 41,
			Parent = panel,
		})
		UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
		pages[name] = page
	end

	-- game passes
	for i, pass in ctx.Config.Shop.Passes do
		local row = UI.new("Frame", { LayoutOrder = i, Size = UDim2.new(1, -6, 0, 76), BackgroundColor3 = Color3.fromRGB(26, 26, 30), BackgroundTransparency = 0.1, ZIndex = 42, Parent = pages.Passes })
		UI.corner(row, 10)
		UI.label({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -140, 0, 24), Text = pass.Name, Font = UI.Font.Bold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = row })
		UI.label({ Position = UDim2.fromOffset(14, 32), Size = UDim2.new(1, -140, 0, 38), Text = pass.Desc, TextSize = 13, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 43, Parent = row })
		local buy = UI.new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(108, 40),
			Text = "",
			Font = UI.Font.Bold,
			TextSize = 16,
			TextColor3 = Color3.fromRGB(14, 14, 16),
			BackgroundColor3 = GOLD,
			ZIndex = 43,
			Parent = row,
		})
		UI.corner(buy, 8)
		local r = { Pass = pass, Buy = buy, Price = nil }
		table.insert(passRows, r)
		buy.Activated:Connect(function()
			if player:GetAttribute("Pass_" .. pass.Key) then
				return
			end
			if pass.Id == 0 then
				toast("Coming soon!")
				return
			end
			pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			end)
		end)
		if pass.Id ~= 0 then
			task.spawn(function()
				local ok, info = pcall(function()
					return MarketplaceService:GetProductInfo(pass.Id, Enum.InfoType.GamePass)
				end)
				if ok and type(info) == "table" and tonumber(info.PriceInRobux) then
					r.Price = info.PriceInRobux
					refreshPasses()
				end
			end)
		end
		player:GetAttributeChangedSignal("Pass_" .. pass.Key):Connect(refreshPasses)
	end
	refreshPasses()

	-- support: a line about why, the amounts, the top supporters
	UI.label({ LayoutOrder = 1, Size = UDim2.new(1, -6, 0, 40), Text = "This game is made by one person. Every Robux helps keep it going, and puts your name on the board in the lobby.", TextSize = 14, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, Parent = pages.Support })
	local amounts = UI.new("Frame", { LayoutOrder = 2, Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 42, Parent = pages.Support })
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(96, 44), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = amounts })
	for i, d in ctx.Config.Shop.Donations do
		local b = UI.new("TextButton", {
			LayoutOrder = i,
			Text = "R$ " .. d.Amount,
			Font = UI.Font.Bold,
			TextSize = 16,
			TextColor3 = Color3.fromRGB(14, 14, 16),
			BackgroundColor3 = GOLD,
			BackgroundTransparency = d.Id == 0 and 0.6 or 0,
			ZIndex = 43,
			Parent = amounts,
		})
		UI.corner(b, 8)
		b.Activated:Connect(function()
			if d.Id == 0 then
				toast("Donations are coming soon!")
				return
			end
			pcall(function()
				MarketplaceService:PromptProductPurchase(player, d.Id)
			end)
		end)
	end
	UI.label({ LayoutOrder = 3, Size = UDim2.new(1, -6, 0, 26), Text = "TOP SUPPORTERS", Font = UI.Font.Bold, TextSize = 15, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Bottom, ZIndex = 42, Parent = pages.Support })
	donorList = UI.new("Frame", { LayoutOrder = 4, Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 42, Parent = pages.Support })
	UI.new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = donorList })
	workspace:GetAttributeChangedSignal("TopDonors"):Connect(refreshDonors)
	select("Passes")

	-- the donation board on the lawn
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == "DonatePrompt" then
			Shop.open("Support")
		end
	end)

	-- lobby notifications (thank-yous, unlocked colours, busy circles) as a toast at the top
	toastBox = UI.box({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, inset.Y + 74),
		Visible = false,
		ZIndex = 50,
		Parent = UI.Root,
	}, { 8, 16 })
	toastText = UI.fitLabel({ Text = "", TextSize = 16, ZIndex = 51, Parent = toastBox }, 520)
	ctx.Remotes.Notify.OnClientEvent:Connect(function(text)
		if type(text) == "string" then
			toast(text)
		end
	end)
end

return Shop
