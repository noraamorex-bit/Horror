--[[
	Store — the lobby's coin store (dock icon STORE): ITEMS (one-use gear for your next night),
	CRATES (a random cosmetic, with an opening reel) and COINS (Robux packs). The server
	(EconomyService) does every purchase; this only asks and shows what happened.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Store = {}
Store.CrateRows = {} :: { any }
local ctx
local Cat
local player = Players.LocalPlayer

local P -- the panel
local itemRows = {}
local overlay: Frame? = nil
local waitingCrate = false

local function eco(): any
	local ok, t = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute("Eco") or "{}")
	end)
	return ok and type(t) == "table" and t or {}
end

local function coins(): number
	return tonumber(player:GetAttribute("Coins")) or 0
end

local function price(b: TextButton, n: number)
	b.Text = "◆ " .. ctx.Dock.format(n)
	local can = coins() >= n
	b.BackgroundTransparency = can and 0 or 0.55
	b.AutoButtonColor = can
end

local function refresh()
	local e = eco()
	local items = type(e.Items) == "table" and e.Items or {}
	for _, r in itemRows do
		local n = tonumber(items[r.Item.Id]) or 0
		if r.Item.Id == "Revive" then
			n = tonumber(player:GetAttribute("ReviveCredits")) or 0
		end
		r.Have.Text = n > 0 and ("READY ×" .. n) or ""
		price(r.Buy, r.Item.Price)
	end
	for _, r in Store.CrateRows or {} do
		price(r.Buy, r.Crate.Price)
	end
end

---------------------------------------------------------------------------
-- The crate reel
---------------------------------------------------------------------------
local openCrate: (any) -> ()

local function closeOverlay()
	if overlay then
		overlay:Destroy()
		overlay = nil
	end
	waitingCrate = false
end

local function cosmeticsOf(rarity: string?): { any }
	local out = {}
	for _, c in Cat.Cosmetics do
		if not rarity or c.Rarity == rarity then
			table.insert(out, c)
		end
	end
	return out
end

local KIND = { Beam = "FLASHLIGHT COLOUR", Title = "TITLE", Trail = "LOBBY TRAIL" }

local function showOverlay(): Frame
	closeOverlay()
	local UI = ctx.UI
	local o = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(4, 4, 6), BackgroundTransparency = 0.15, ZIndex = 60, Parent = UI.Root })
	UI.modal(o)
	overlay = o
	return o
end

local function reel(res)
	local UI = ctx.UI
	local o = showOverlay()
	local window = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(560, 120),
		BackgroundColor3 = Color3.fromRGB(16, 16, 20),
		ClipsDescendants = true,
		ZIndex = 61,
		Parent = o,
	})
	UI.corner(window, 12)
	UI.stroke(window, Color3.new(1, 1, 1), 1, 0.7)
	-- the marker in the middle
	UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = ctx.Dock.Gold, ZIndex = 65, Parent = window })
	local strip = UI.new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 62, Parent = window })
	local W = 140
	local cards = {}
	local all = cosmeticsOf(nil)
	local N = 34
	local target = N - 4
	for i = 1, N do
		local c = i == target and Cat.cosmetic(res.Id) or all[math.random(1, #all)]
		local rar = Cat.Rarity[c.Rarity]
		local card = UI.new("Frame", { Position = UDim2.fromOffset((i - 1) * W + 6, 8), Size = UDim2.fromOffset(W - 12, 104), BackgroundColor3 = Color3.fromRGB(28, 28, 34), ZIndex = 63, Parent = strip })
		UI.corner(card, 10)
		UI.new("UIStroke", { Color = rar.Color, Thickness = 2, Parent = card })
		local swatch = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = c.Color, ZIndex = 64, Parent = card })
		UI.corner(swatch, 17)
		UI.label({ Position = UDim2.fromOffset(4, 48), Size = UDim2.new(1, -8, 0, 30), Text = c.Name, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), ZIndex = 64, Parent = card })
		UI.label({ Position = UDim2.fromOffset(4, 78), Size = UDim2.new(1, -8, 0, 18), Text = string.upper(c.Rarity), Font = UI.Font.Bold, TextSize = 11, TextColor3 = rar.Color, ZIndex = 64, Parent = card })
		cards[i] = card
	end
	strip.Size = UDim2.new(0, N * W, 1, 0)
	local endX = -((target - 1) * W + W / 2) + 280 + math.random(-40, 40)
	strip.Position = UDim2.fromOffset(0, 0)
	local duration = 3.2
	local t0 = os.clock()
	local lastTick = 0
	while overlay == o and os.clock() - t0 < duration do
		local k = (os.clock() - t0) / duration
		local e = 1 - (1 - k) ^ 4
		strip.Position = UDim2.fromOffset(endX * e, 0)
		local idx = math.floor(-strip.Position.X.Offset / W)
		if idx ~= lastTick then
			lastTick = idx
			if ctx.Effects then
				ctx.Effects.playSound("UIClick", nil, { Caption = false, Volume = 0.25 })
			end
		end
		task.wait()
	end
	if overlay ~= o then
		return
	end
	strip.Position = UDim2.fromOffset(endX, 0)
	-- the reveal
	local def = Cat.cosmetic(res.Id)
	local rar = Cat.Rarity[res.Rarity]
	if ctx.Effects then
		ctx.Effects.playSound(rar.Order >= 3 and "RisingWhoosh" or "UISelect", nil, { Caption = false })
	end
	local col = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromOffset(560, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 61, Parent = o })
	UI.new("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = col })
	UI.label({ LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 22), Text = string.upper(res.Rarity) .. "  ·  " .. (KIND[res.CosmeticKind] or ""), Font = UI.Font.Bold, TextSize = 16, TextColor3 = rar.Color, ZIndex = 62, Parent = col })
	local name = UI.label({ LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 44), Text = res.Name, Font = UI.Font.Bold, TextSize = 38, TextColor3 = def and def.Color or Color3.new(1, 1, 1), ZIndex = 62, Parent = col })
	local s = UI.new("UIScale", { Scale = 1.4, Parent = name })
	UI.tween(s, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	UI.label({ LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 22), Text = res.Dup and ("You already have this one.  +" .. tostring(res.Refund) .. " coins back") or "NEW!", Font = UI.Font.Bold, TextSize = 16, TextColor3 = res.Dup and ctx.UI.Color.Dim or ctx.Dock.Gold, ZIndex = 62, Parent = col })
	local row = UI.new("Frame", { LayoutOrder = 4, Size = UDim2.fromOffset(400, 50), BackgroundTransparency = 1, ZIndex = 61, Parent = col })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = row })
	local function btn(text: string, gold: boolean, fn)
		local b = UI.new("TextButton", { Size = UDim2.fromOffset(150, 46), Text = text, Font = UI.Font.Bold, TextSize = 16, TextColor3 = gold and Color3.fromRGB(14, 14, 16) or UI.Color.Text, BackgroundColor3 = gold and ctx.Dock.Gold or Color3.fromRGB(40, 40, 44), ZIndex = 62, Parent = row })
		UI.corner(b, 10)
		b.Activated:Connect(fn)
	end
	if not res.Dup then
		btn("EQUIP", true, function()
			ctx.Remotes.Economy:FireServer("Equip", res.Id)
			closeOverlay()
		end)
	end
	local crate = res.Crate and Cat.crate(res.Crate)
	if crate and coins() >= crate.Price then
		btn("OPEN ANOTHER", false, function()
			closeOverlay()
			openCrate(crate)
		end)
	end
	btn("DONE", false, closeOverlay)
end

openCrate = function(crate)
	if waitingCrate then
		return
	end
	if coins() < crate.Price then
		P.select("Coins")
		return
	end
	waitingCrate = true
	ctx.Remotes.Economy:FireServer("Crate", crate.Id)
	task.delay(6, function()
		waitingCrate = false
	end)
end

function Store.open(tab: string?)
	if P then
		P.open(tab)
	end
end

function Store.init(c)
	ctx = c
	ctx.StoreUI = Store
	Cat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Economy"))
end

function Store.start()
	if ctx.Mode ~= "Lobby" then
		return
	end
	local UI = ctx.UI
	local Dock = ctx.Dock
	P = Dock.panel("STORE", { "Items", "Crates", "Coins" }, { Items = "ITEMS", Crates = "CRATES", Coins = "GET COINS" })
	P.OnOpen = refresh
	Dock.add({ Order = 1, Glyph = "🛒", Label = "STORE", Color = Dock.Gold, OnClick = function()
		P.toggle()
	end })

	-- items
	UI.label({ LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 34), Text = "Gear for your <b>next night</b>. You start with it in your pocket; it's used up after that night.", TextSize = 13, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, Parent = P.Pages.Items })
	for i, item in Cat.Items do
		local row = Dock.row(P.Pages.Items, i, 70)
		UI.label({ Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(44, 70), Text = item.Glyph, TextSize = 30, ZIndex = 43, Parent = row })
		UI.label({ Position = UDim2.fromOffset(60, 8), Size = UDim2.new(1, -190, 0, 22), Text = item.Name, Font = UI.Font.Bold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = row })
		UI.label({ Position = UDim2.fromOffset(60, 30), Size = UDim2.new(1, -190, 0, 34), Text = item.Desc, TextSize = 12, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 43, Parent = row })
		local have = UI.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -130, 0, 8), Size = UDim2.fromOffset(80, 16), Text = "", Font = UI.Font.Bold, TextSize = 11, TextColor3 = Color3.fromRGB(120, 230, 150), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 43, Parent = row })
		local buy = Dock.button(row, "")
		buy.Activated:Connect(function()
			if coins() < item.Price then
				P.select("Coins")
				return
			end
			ctx.Remotes.Economy:FireServer("Buy", item.Id)
		end)
		table.insert(itemRows, { Item = item, Buy = buy, Have = have })
	end

	-- crates
	UI.label({ LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 34), Text = "Flashlight colours (everyone sees them in the house), titles over your name and glowing trails in the lobby.", TextSize = 13, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, Parent = P.Pages.Crates })
	Store.CrateRows = {}
	for i, crate in Cat.Crates do
		local row = Dock.row(P.Pages.Crates, i, 96)
		UI.label({ Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(56, 96), Text = crate.Glyph, TextSize = 40, ZIndex = 43, Parent = row })
		UI.label({ Position = UDim2.fromOffset(72, 10), Size = UDim2.new(1, -200, 0, 24), Text = crate.Name, Font = UI.Font.Bold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = row })
		UI.label({ Position = UDim2.fromOffset(72, 34), Size = UDim2.new(1, -200, 0, 18), Text = crate.Desc, TextSize = 12, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = row })
		local odds = {}
		for _, r in { "Common", "Rare", "Epic", "Legendary" } do
			local w = crate.Odds[r] or 0
			if w > 0 then
				local c = Cat.Rarity[r].Color
				table.insert(odds, string.format('<font color="#%02x%02x%02x">%s %d%%</font>', c.R * 255, c.G * 255, c.B * 255, r, w))
			end
		end
		UI.label({ Position = UDim2.fromOffset(72, 56), Size = UDim2.new(1, -200, 0, 30), Text = table.concat(odds, "  "), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = row })
		local buy = Dock.button(row, "")
		buy.Activated:Connect(function()
			openCrate(crate)
		end)
		table.insert(Store.CrateRows, { Crate = crate, Buy = buy })
	end
	-- what's in them
	local list = {}
	for _, r in { "Legendary", "Epic", "Rare", "Common" } do
		local names = {}
		for _, c in cosmeticsOf(r) do
			table.insert(names, c.Name)
		end
		local col = Cat.Rarity[r].Color
		table.insert(list, string.format('<font color="#%02x%02x%02x"><b>%s</b></font>  %s', col.R * 255, col.G * 255, col.B * 255, string.upper(r), table.concat(names, ", ")))
	end
	UI.label({ LayoutOrder = 10, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = table.concat(list, "\n"), TextSize = 12, TextColor3 = UI.Color.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, Parent = P.Pages.Crates })

	-- coins for Robux
	UI.label({ LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 34), Text = "You earn coins every night you play, from the daily reward and from daily quests. Or grab a pack:", TextSize = 13, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, Parent = P.Pages.Coins })
	for i, pack in Cat.Packs do
		local row = Dock.row(P.Pages.Coins, i, 64)
		Dock.coin(row, 34, 43).Position = UDim2.fromOffset(14, 15)
		UI.label({ Position = UDim2.fromOffset(60, 0), Size = UDim2.new(1, -190, 1, 0), Text = Dock.format(pack.Coins) .. " coins" .. (pack.Tag and ("   <font color=\"#78e696\" size=\"13\">" .. pack.Tag .. "</font>") or ""), Font = UI.Font.Bold, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = row })
		local buy = Dock.button(row, "R$ " .. pack.Robux, { BackgroundColor3 = Color3.fromRGB(120, 230, 150) })
		buy.Activated:Connect(function()
			if pack.Id == 0 then
				return
			end
			pcall(function()
				MarketplaceService:PromptProductPurchase(player, pack.Id)
			end)
		end)
	end

	ctx.Remotes.EconomyResult.OnClientEvent:Connect(function(res)
		if type(res) ~= "table" then
			return
		end
		if res.Kind == "Crate" then
			waitingCrate = false
			task.spawn(reel, res)
		elseif res.Kind == "Buy" then
			if ctx.Effects then
				ctx.Effects.playSound("Pickup", nil, { Caption = false })
			end
			refresh()
		elseif res.Kind == "Error" then
			waitingCrate = false
			if ctx.ShopUI and ctx.ShopUI.toast then
				ctx.ShopUI.toast(tostring(res.Text or "Couldn't do that."))
			end
		end
	end)
	for _, a in { "Coins", "Eco", "ReviveCredits" } do
		player:GetAttributeChangedSignal(a):Connect(function()
			if P.Frame.Visible then
				refresh()
			end
		end)
	end
	refresh()
end

return Store
