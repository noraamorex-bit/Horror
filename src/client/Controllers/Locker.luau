--[[
	Locker — what you wear (dock icon LOCKER, the flashlight): FLASHLIGHT colours (by bringing
	friends, with a game pass, or out of crates), TITLES over your name and lobby TRAILS (from
	crates). Tap one you have to use it; tap one you don't to see how to get it.
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locker = {}
local ctx
local Cat
local player = Players.LocalPlayer
local P
local rows = {} -- { Def, Kind, Row, Label, Sub, Stroke, Swatch }

-- the colours you don't get from crates (StatsService.Beams)
local BEAMS = {
	{ Id = "Classic", Name = "Classic", Need = 0, Color = Color3.fromRGB(255, 244, 222) },
	{ Id = "Ember", Name = "Ember", Need = 1, Color = Color3.fromRGB(255, 140, 50) },
	{ Id = "Moonlight", Name = "Moonlight", Need = 3, Color = Color3.fromRGB(130, 175, 255) },
	{ Id = "Blood", Name = "Blood moon", Need = 5, Color = Color3.fromRGB(255, 45, 40) },
	{ Id = "Gold", Name = "Gold", Pass = "Supporter", PassName = "Supporter pass", Color = Color3.fromRGB(255, 196, 60) },
	{ Id = "Ghost", Name = "Ghost", Pass = "Colours", PassName = "Colours pass", Color = Color3.fromRGB(120, 255, 185) },
}

local function eco(): any
	local ok, t = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute("Eco") or "{}")
	end)
	return ok and type(t) == "table" and t or {}
end

local function ownedSet(): { [string]: boolean }
	local set = {}
	for _, id in (eco().Owned or {}) do
		set[id] = true
	end
	return set
end

local function beamUnlocked(b, owned): (boolean, string)
	if b.Crate then
		return owned[b.Id] == true, "Found in crates"
	end
	if b.Pass then
		return player:GetAttribute("Pass_" .. b.Pass) == true, b.PassName
	end
	local n = tonumber(player:GetAttribute("StatReferrals")) or 0
	local ok = player:GetAttribute("Pass_Colours") == true or n >= b.Need or (b.Need == 1 and player:GetAttribute("StatReferred") == true)
	return ok, "Bring " .. b.Need .. (b.Need == 1 and " friend" or " friends")
end

local function refresh()
	local owned = ownedSet()
	local equip = eco().Equip or {}
	local beam = player:GetAttribute("StatBeam") or "Classic"
	for _, r in rows do
		local unlocked, how, chosen
		if r.Kind == "Beam" then
			unlocked, how = beamUnlocked(r.Def, owned)
			chosen = beam == r.Def.Id
		elseif r.Def.None then
			unlocked, how = true, ""
			chosen = equip[r.Kind] == nil
		else
			unlocked, how = owned[r.Def.Id] == true, "Found in crates"
			chosen = equip[r.Kind] == r.Def.Id
		end
		r.Label.TextTransparency = unlocked and 0 or 0.55
		r.Sub.Text = chosen and "EQUIPPED" or (unlocked and (r.Def.Rarity and string.upper(r.Def.Rarity) or "") or ("🔒 " .. how))
		r.Sub.TextColor3 = chosen and Color3.fromRGB(120, 230, 150) or (r.Def.Rarity and Cat.Rarity[r.Def.Rarity].Color or ctx.UI.Color.Dim)
		r.Stroke.Transparency = chosen and 0.1 or 1
		r.Unlocked = unlocked
	end
end

local function makeRow(page: Instance, order: number, def, kind: string)
	local UI = ctx.UI
	local row = UI.new("TextButton", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 46), Text = "", BackgroundColor3 = Color3.fromRGB(26, 26, 30), BackgroundTransparency = 0.1, ZIndex = 42, Parent = page })
	UI.corner(row, 8)
	local swatch = UI.new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = def.Color or Color3.fromRGB(80, 80, 86), ZIndex = 43, Parent = row })
	UI.corner(swatch, 9)
	if def.Rainbow then
		UI.new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 120)), ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 100, 255)) }), Parent = swatch })
	end
	local label = UI.label({ Position = UDim2.fromOffset(42, 0), Size = UDim2.new(0.55, -42, 1, 0), Text = def.Name, Font = UI.Font.Bold, TextSize = 15, TextColor3 = kind == "Title" and def.Color or UI.Color.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = row })
	local sub = UI.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0.45, -12, 1, 0), Text = "", Font = UI.Font.Bold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 43, Parent = row })
	local stroke = UI.stroke(row, Color3.fromRGB(120, 230, 150), 2, 1)
	local r: any = { Def = def, Kind = kind, Row = row, Label = label, Sub = sub, Stroke = stroke }
	table.insert(rows, r)
	row.Activated:Connect(function()
		if not r.Unlocked then
			if kind ~= "Beam" or def.Crate then
				if ctx.StoreUI then
					ctx.StoreUI.open("Crates")
				end
			elseif def.Pass then
				if ctx.ShopUI then
					ctx.ShopUI.open("Passes")
				end
			elseif ctx.Social then
				ctx.Social.invite()
			end
			return
		end
		if kind == "Beam" then
			if def.Crate then
				ctx.Remotes.Economy:FireServer("Equip", def.Id)
			else
				ctx.Remotes.SetBeam:FireServer(def.Id)
			end
			if ctx.Effects then
				ctx.Effects.playSound("FlashlightOn", nil, { Caption = false })
			end
		elseif def.None then
			ctx.Remotes.Economy:FireServer("Unequip", kind)
		else
			ctx.Remotes.Economy:FireServer("Equip", def.Id)
		end
	end)
end

function Locker.open(tab: string?)
	if P then
		P.open(tab)
	end
end

function Locker.init(c)
	ctx = c
	ctx.LockerUI = Locker
	Cat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Economy"))
end

function Locker.start()
	if ctx.Mode ~= "Lobby" then
		return
	end
	local UI = ctx.UI
	P = ctx.Dock.panel("LOCKER", { "Beam", "Title", "Trail" }, { Beam = "FLASHLIGHT", Title = "TITLES", Trail = "TRAILS" })
	P.OnOpen = refresh
	ctx.Dock.add({ Order = 3, Glyph = "🔦", Label = "LOCKER", Color = Color3.fromRGB(255, 244, 222), OnClick = function()
		P.toggle()
	end })
	UI.label({ LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 20), Text = "Your beam colour. Everyone in the house sees it.", TextSize = 13, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, Parent = P.Pages.Beam })
	local order = 0
	for _, b in BEAMS do
		order += 1
		makeRow(P.Pages.Beam, order, b, "Beam")
	end
	for _, c in Cat.Cosmetics do
		if c.Kind == "Beam" then
			order += 1
			makeRow(P.Pages.Beam, order, { Id = c.Id, Name = c.Name, Color = c.Color, Rarity = c.Rarity, Rainbow = c.Rainbow, Crate = true }, "Beam")
		end
	end
	for _, kind in { "Title", "Trail" } do
		UI.label({ LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 20), Text = kind == "Title" and "A title over your name in the lobby." or "A glowing trail behind you in the lobby.", TextSize = 13, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, Parent = P.Pages[kind] })
		makeRow(P.Pages[kind], 1, { None = true, Name = "None" }, kind)
		local n = 1
		for _, list in { Cat.Special, Cat.Cosmetics } do
			for _, c in list do
				if c.Kind == kind then
					n += 1
					makeRow(P.Pages[kind], n, c, kind)
				end
			end
		end
	end
	for _, a in { "Eco", "StatBeam", "StatReferrals", "StatReferred", "Pass_Colours", "Pass_Supporter" } do
		player:GetAttributeChangedSignal(a):Connect(function()
			if P.Frame.Visible then
				refresh()
			end
		end)
	end
end

return Locker
