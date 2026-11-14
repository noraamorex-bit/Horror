--[[
	WeaponRoll (v161) — the Weapon Roll in the house (server WeaponService, Config.Weapons, product Config.Shop.WeaponRoll).

	• 🎲 WEAPON  R$10, a small button under the inventory (HUD.LeftColumn) while you're free in a night. It opens the roll's
	  window first: every weapon with its real chance, what each tier does, and the guarantees ("Epic or better in N rolls ·
	  Legendary in N"). ROLL opens Roblox's purchase window. Never shown where paid random items aren't allowed
	  (RollRestricted, from the server's PolicyService check).
	• The spin (Remotes.WeaponRoll): a strip of weapon cards slides under a marker and slows to a stop on what the server
	  rolled. Every other card on the strip is drawn at the same odds as the roll, so what you see going past is what the odds
	  look like: nothing is placed to look like a near miss. Sits in the top third, never over the middle of the screen,
	  and doesn't take input (you can still move).
	• Remotes.WeaponFx: what a weapon does, for everyone: a swing's arc, the glove's flash, a shot's tracer, the cannon's
	  charge and beam.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local WeaponRoll = {}
local ctx
local player = Players.LocalPlayer

local button: TextButton? = nil
local panel: Frame? = nil
local pityLine: TextLabel? = nil
local spinning = false
local queue: { any } = {}

local function W()
	return ctx.Config.Weapons
end

local function tierOf(id: string)
	for _, t in W().Tiers do
		if t.Id == id then
			return t
		end
	end
	return W().Tiers[1]
end

local function sound(name: string, pitch: number?)
	local s = ctx.Effects and ctx.Effects.localSound and ctx.Effects.localSound(name)
	if s then
		if pitch then
			s.PlaybackSpeed = pitch
		end
		s:Play()
		Debris:AddItem(s, 8)
	end
end

local function canRoll(): boolean
	local act = workspace:GetAttribute("Act")
	return player:GetAttribute("InGame") == true and act ~= nil and act ~= "Lobby"
		and not workspace:GetAttribute("EndingActive") and not player:GetAttribute("Dead")
		and not player:GetAttribute("Escaped") and not player:GetAttribute("Monster")
		and not player:GetAttribute("RollRestricted")
		and not (ctx.Ending and ctx.Ending.isShowing and ctx.Ending.isShowing())
end
WeaponRoll._canRoll = canRoll -- (tests)

local function pityText(): string
	local P = W().Pity
	local e = tonumber(player:GetAttribute("RollsSinceEpic")) or 0
	local l = tonumber(player:GetAttribute("RollsSinceLegendary")) or 0
	return string.format("EPIC or better within %d rolls  ·  LEGENDARY within %d", math.max(1, P.EpicBy - e), math.max(1, P.LegendaryBy - l))
end
WeaponRoll._pityText = pityText

local function refresh()
	if button then
		local p = ctx.Config.Shop.WeaponRoll
		button.Visible = p ~= nil and p.Id > 0 and canRoll() and not player:GetAttribute("Captured")
		button.Text = "🎲 WEAPON  R$" .. tostring(p and p.Price or 10)
	end
	if pityLine then
		pityLine.Text = pityText()
	end
	if panel and panel.Visible and not canRoll() then
		panel.Visible = false
	end
end
WeaponRoll._refresh = refresh

local function buy()
	local p = ctx.Config.Shop.WeaponRoll
	if p and p.Id > 0 and canRoll() then
		pcall(function()
			MarketplaceService:PromptProductPurchase(player, p.Id)
		end)
	end
end

-- the roll's window: the odds, the guarantees, ROLL
local function buildPanel()
	local UI = ctx.UI
	local f = UI.new("Frame", {
		Name = "WeaponRollPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(340, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UI.Color.Glass,
		BackgroundTransparency = 0.06,
		Visible = false,
		ZIndex = 20,
		Parent = UI.Root,
	})
	UI.corner(f, 10)
	UI.stroke(f, Color3.new(1, 1, 1), 1, 0.8)
	UI.padding(f, 12)
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = f })
	local head = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 20, Parent = f })
	UI.new("TextLabel", {
		Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1, Text = "🎲 WEAPON ROLL", Font = UI.Font.Title, TextSize = 20,
		TextColor3 = UI.Color.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 20, Parent = head,
	})
	local close = UI.new("TextButton", {
		Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(26, 26),
		Text = "✕", Font = UI.Font.Bold, TextSize = 16, TextColor3 = UI.Color.Text, BackgroundTransparency = 1, ZIndex = 20, Parent = head,
	})
	close.Activated:Connect(function()
		f.Visible = false
	end)
	UI.new("Frame", { Size = UDim2.fromOffset(40, 2), BackgroundColor3 = UI.Color.Blood, BorderSizePixel = 0, LayoutOrder = 2, ZIndex = 20, Parent = f })
	UI.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 3, TextWrapped = true, ZIndex = 20,
		Text = "One random weapon for tonight. These are the real chances.", Font = UI.Font.Body, TextSize = 12,
		TextColor3 = UI.Color.Dim, Parent = f,
	})
	-- one row per tier: its name and chance, its weapons and theirs
	local order = 4
	for _, tier in W().Tiers do
		local total = 0
		local names = {}
		for _, k in W().Order do
			local s = W().List[k]
			if s.Tier == tier.Id then
				total += s.Odds
				table.insert(names, s.Emoji .. " " .. s.Name .. " " .. s.Odds .. "%")
			end
		end
		local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = tier.Color, BackgroundTransparency = 0.85, LayoutOrder = order, ZIndex = 20, Parent = f })
		order += 1
		UI.corner(row, 6)
		UI.stroke(row, tier.Color, 1, 0.3)
		UI.new("TextLabel", {
			Position = UDim2.fromOffset(8, 3), Size = UDim2.new(1, -16, 0, 16), BackgroundTransparency = 1, ZIndex = 20,
			Text = tier.Name .. "  " .. total .. "%", Font = UI.Font.Bold, TextSize = 13, TextColor3 = tier.Color,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
		})
		UI.new("TextLabel", {
			Position = UDim2.fromOffset(8, 20), Size = UDim2.new(1, -16, 0, 16), BackgroundTransparency = 1, ZIndex = 20,
			Text = table.concat(names, "   "), Font = UI.Font.Body, TextSize = 12, TextColor3 = UI.Color.Text,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
		})
	end
	pityLine = UI.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 20,
		Text = pityText(), Font = UI.Font.Bold, TextSize = 12, TextColor3 = tierOf("Legendary").Color, Parent = f,
	})
	UI.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = order + 1, TextWrapped = true, ZIndex = 20,
		Text = "Weapons stun him for a moment, then he's back. A Legendary stays for " .. W().LegendaryNights .. " nights.",
		Font = UI.Font.Body, TextSize = 11, TextColor3 = UI.Color.Dim, Parent = f,
	})
	local roll = UI.new("TextButton", {
		Name = "Roll", Size = UDim2.new(1, 0, 0, 38), LayoutOrder = order + 2, ZIndex = 20,
		Text = "ROLL  R$" .. tostring(ctx.Config.Shop.WeaponRoll.Price), Font = UI.Font.Bold, TextSize = 17,
		TextColor3 = Color3.fromRGB(20, 16, 6), BackgroundColor3 = tierOf("Legendary").Color, AutoButtonColor = true, Parent = f,
	})
	UI.corner(roll, 8)
	roll.Activated:Connect(function()
		buy()
	end)
	return f
end

function WeaponRoll.open()
	if not canRoll() then
		return
	end
	panel = panel or buildPanel()
	refresh()
	;(panel :: Frame).Visible = true
end

function WeaponRoll.isOpen(): boolean
	return panel ~= nil and panel.Visible
end

-- a filler card for the strip, drawn at the same odds as the roll itself
local rng = Random.new()
local function drawKind(): string
	local total = 0
	for _, k in W().Order do
		total += W().List[k].Odds
	end
	local x = rng:NextNumber() * total
	for _, k in W().Order do
		x -= W().List[k].Odds
		if x <= 0 then
			return k
		end
	end
	return W().Order[1]
end
WeaponRoll._drawKind = drawKind

local CARD, GAP, COUNT, LAND = 78, 6, 44, 38

-- the strip: COUNT cards, the rolled one at LAND (the rest at the real odds)
function WeaponRoll._strip(kind: string): { string }
	local list = {}
	for i = 1, COUNT do
		list[i] = i == LAND and kind or drawKind()
	end
	return list
end

local function card(parent: Instance, kind: string, x: number): Frame
	local UI = ctx.UI
	local s = W().List[kind]
	local tier = tierOf(s.Tier)
	local c = UI.new("Frame", {
		Position = UDim2.fromOffset(x, 6), Size = UDim2.fromOffset(CARD, CARD + 8),
		BackgroundColor3 = Color3.fromRGB(16, 16, 20), BackgroundTransparency = 0.05, Parent = parent,
	})
	UI.corner(c, 8)
	UI.stroke(c, tier.Color, 2, 0)
	UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = tier.Color, BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = c,
	})
	UI.new("TextLabel", {
		Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Text = s.Emoji,
		TextScaled = true, Font = UI.Font.Bold, TextColor3 = Color3.new(1, 1, 1), Parent = c,
	})
	UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 2, 1, -3), Size = UDim2.new(1, -4, 0, 16), BackgroundTransparency = 1,
		Text = string.upper(s.Name), TextScaled = true, Font = UI.Font.Bold, TextColor3 = Color3.new(1, 1, 1), Parent = c,
	})
	return c
end

local function ease(x: number): number
	-- quartic out: fast, then a long slow-down to the stop
	return 1 - (1 - x) ^ 4
end
WeaponRoll._ease = ease

local function spin(kind: string, tierId: string, pityE: number?, pityL: number?)
	spinning = true
	if panel then
		panel.Visible = false
	end
	local UI = ctx.UI
	local s = W().List[kind]
	local tier = tierOf(tierId or s.Tier)
	local width = 4 * (CARD + GAP) + CARD -- (five cards in view)
	local holder = UI.new("Frame", {
		Name = "WeaponSpin", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.1, 0),
		Size = UDim2.fromOffset(width + 16, CARD + 58), BackgroundColor3 = UI.Color.Glass, BackgroundTransparency = 0.12,
		Active = false, ZIndex = 30, Parent = UI.Root,
	})
	UI.corner(holder, 10)
	UI.stroke(holder, Color3.new(1, 1, 1), 1, 0.8)
	local title = UI.new("TextLabel", {
		Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "🎲 ROLLING...",
		Font = UI.Font.Bold, TextSize = 14, TextColor3 = UI.Color.Text, ZIndex = 31, Parent = holder,
	})
	local clip = UI.new("Frame", {
		Position = UDim2.fromOffset(8, 24), Size = UDim2.fromOffset(width, CARD + 20), BackgroundTransparency = 1,
		ClipsDescendants = true, ZIndex = 31, Parent = holder,
	})
	local strip = UI.new("Frame", { Size = UDim2.fromOffset(COUNT * (CARD + GAP), CARD + 20), BackgroundTransparency = 1, ZIndex = 31, Parent = clip })
	local kinds = WeaponRoll._strip(kind)
	for i, k in kinds do
		card(strip, k, (i - 1) * (CARD + GAP))
	end
	-- the marker down the middle
	UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 22), Size = UDim2.fromOffset(3, CARD + 24),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 34, Parent = holder,
	})
	local foot = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
		Text = "", Font = UI.Font.Body, TextSize = 11, TextColor3 = UI.Color.Dim, ZIndex = 31, Parent = holder,
	})
	-- where it stops: somewhere inside the rolled card (not always its middle)
	local landAt = (LAND - 1) * (CARD + GAP) + CARD / 2 + rng:NextNumber(-0.32, 0.32) * CARD
	local endX = width / 2 - landAt
	local startX = 0
	local T = W().SpinTime - 1.2
	local t0 = os.clock()
	local lastCard = -1
	sound("RollDice")
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local x = math.clamp((os.clock() - t0) / T, 0, 1)
		local off = startX + (endX - startX) * ease(x)
		strip.Position = UDim2.fromOffset(off, 0)
		-- a tick each time a card passes the marker
		local under = math.floor((width / 2 - off) / (CARD + GAP))
		if under ~= lastCard then
			lastCard = under
			sound("UIClick", 1.1 + 0.3 * (1 - x))
		end
		if x >= 1 then
			conn:Disconnect()
		end
	end)
	task.delay(T, function()
		-- the result
		title.Text = tier.Name .. "!  " .. s.Emoji .. " " .. string.upper(s.Name)
		title.TextColor3 = tier.Color
		title.TextSize = 16
		local stroke = holder:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = tier.Color
			stroke.Transparency = 0
			stroke.Thickness = 2
		end
		local legendary = (tierId or s.Tier) == "Legendary"
		sound(legendary and "RollLegendary" or ((tierId == "Epic" or tierId == "Rare") and "RollWin" or "UISelect"))
		if legendary or tierId == "Epic" then
			-- a flash of its colour behind the cards
			local glow = UI.new("Frame", {
				Size = UDim2.fromScale(1, 1), BackgroundColor3 = tier.Color, BackgroundTransparency = 0.4, ZIndex = 30, Parent = holder,
			})
			UI.corner(glow, 10)
			UI.tween(glow, 1.2, { BackgroundTransparency = 1 })
		end
		local P = W().Pity
		if pityE and pityL then
			foot.Text = string.format("EPIC+ within %d  ·  LEGENDARY within %d", math.max(1, P.EpicBy - pityE), math.max(1, P.LegendaryBy - pityL))
		end
		task.delay(0.8, function()
			if ctx.HUD and ctx.HUD.notify then
				ctx.HUD.notify(s.Emoji .. " " .. s.Name .. " in your items: pick it, then click or tap to use it."
					.. (legendary and (" It's yours for " .. W().LegendaryNights .. " nights.") or ""), "done")
			end
		end)
		task.delay(2.6, function()
			UI.tween(holder, 0.35, { BackgroundTransparency = 1 })
			task.delay(0.4, function()
				holder:Destroy()
				spinning = false
				local nextOne = table.remove(queue, 1)
				if nextOne then
					spin(table.unpack(nextOne))
				end
			end)
		end)
	end)
end
WeaponRoll._spin = spin

function WeaponRoll.onResult(kind: string, tierId: string, pityE: number?, pityL: number?)
	if type(kind) ~= "string" or not W().List[kind] then
		return
	end
	if spinning then
		table.insert(queue, { kind, tierId, pityE, pityL })
		return
	end
	spin(kind, tierId, pityE, pityL)
end

-- what a weapon does, seen by everyone
local function neon(size: Vector3, cf: CFrame, color: Color3, life: number, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = size
	if shape then
		p.Shape = shape
	end
	p.CFrame = cf
	p.Parent = workspace
	ctx.UI.tween(p, life, { Transparency = 1 })
	Debris:AddItem(p, life + 0.1)
	return p
end

function WeaponRoll.fx(userId: number, kind: string, what: string, a: any, b: any)
	local s = W().List[kind]
	if not s then
		return
	end
	local color = tierOf(s.Tier).Color
	local who = Players:GetPlayerByUserId(userId)
	local root = who and who.Character and who.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if what == "swing" or what == "slap" then
		if not root then
			return
		end
		-- an arc of light in front of them, sweeping right to left
		local look = typeof(b) == "Vector3" and Vector3.new(b.X, 0, b.Z) or root.CFrame.LookVector
		look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
		local base = CFrame.lookAt(root.Position + Vector3.new(0, 0.6, 0), root.Position + Vector3.new(0, 0.6, 0) + look)
		local reach = math.min(s.Range, what == "slap" and 5 or 6)
		local half = math.rad((s.Cone or 60) / 2)
		for i = 0, 6 do
			local ang = half - (2 * half) * (i / 6)
			task.delay(i * 0.025, function()
				local cf = base * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0.6 - i * 0.15, -reach * 0.75)
				neon(Vector3.new(0.15, 0.15, reach * 0.4), cf, color, 0.22)
			end)
		end
		if what == "slap" then
			local at = base * CFrame.new(0, 0.5, -4)
			local ring = neon(Vector3.new(1, 1, 1), at, color, 0.35, Enum.PartType.Ball)
			ctx.UI.tween(ring, 0.35, { Size = Vector3.new(7, 7, 7), Transparency = 1 })
		end
	elseif what == "shot" or what == "beam" then
		if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then
			return
		end
		local len = (b - a).Magnitude
		local thick = what == "beam" and 0.9 or 0.12
		local col = what == "beam" and Color3.fromRGB(80, 230, 255) or Color3.fromRGB(255, 236, 160)
		neon(Vector3.new(thick, thick, len), CFrame.lookAt(a, b) * CFrame.new(0, 0, -len / 2), col, what == "beam" and 0.5 or 0.08)
		local flash = neon(Vector3.new(thick * 2.5, thick * 2.5, thick * 2.5), CFrame.new(a), col, 0.15, Enum.PartType.Ball)
		local light = Instance.new("PointLight")
		light.Color = col
		light.Range = what == "beam" and 26 or 14
		light.Brightness = what == "beam" and 6 or 4
		light.Parent = flash
		if what == "beam" then
			local hit = neon(Vector3.new(2, 2, 2), CFrame.new(b), col, 0.5, Enum.PartType.Ball)
			ctx.UI.tween(hit, 0.5, { Size = Vector3.new(9, 9, 9), Transparency = 1 })
		end
		if who == player and ctx.Effects and ctx.Effects.shake then
			pcall(ctx.Effects.shake, what == "beam" and 0.6 or 0.2, 0.2)
		end
	elseif what == "charge" then
		if not root then
			return
		end
		-- a growing glow at the cannon's mouth while it winds up
		local seconds = tonumber(a) or 0.8
		local ball = neon(Vector3.new(0.3, 0.3, 0.3), root.CFrame * CFrame.new(0.8, 0.6, -2.2), Color3.fromRGB(80, 230, 255), seconds, Enum.PartType.Ball)
		ball.Transparency = 0.2
		ctx.UI.tween(ball, seconds, { Size = Vector3.new(1.6, 1.6, 1.6) })
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(80, 230, 255)
		light.Range = 12
		light.Brightness = 3
		light.Parent = ball
	end
end

function WeaponRoll.init(c)
	ctx = c
	ctx.WeaponRoll = WeaponRoll
end

function WeaponRoll.start()
	local UI = ctx.UI
	button = UI.new("TextButton", {
		Name = "WeaponRollOffer",
		Size = UDim2.fromOffset(150, 30),
		Text = "",
		Font = UI.Font.Bold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 236, 190),
		BackgroundColor3 = Color3.fromRGB(70, 50, 8),
		BackgroundTransparency = 0.15,
		AutoButtonColor = true,
		LayoutOrder = 7,
		Visible = false,
		Parent = ctx.HUD and ctx.HUD.LeftColumn or UI.Root,
	})
	UI.corner(button :: TextButton, 8)
	UI.stroke(button :: TextButton, tierOf("Legendary").Color, 1, 0.4)
	;(button :: TextButton).Activated:Connect(function()
		if WeaponRoll.isOpen() then
			(panel :: Frame).Visible = false
		else
			WeaponRoll.open()
		end
	end)
	for _, a in { "InGame", "Captured", "Dead", "Escaped", "Monster", "RollRestricted", "RollsSinceEpic", "RollsSinceLegendary" } do
		player:GetAttributeChangedSignal(a):Connect(refresh)
	end
	workspace:GetAttributeChangedSignal("Act"):Connect(refresh)
	workspace:GetAttributeChangedSignal("EndingActive"):Connect(refresh)
	ctx.Remotes.WeaponRoll.OnClientEvent:Connect(WeaponRoll.onResult)
	ctx.Remotes.WeaponFx.OnClientEvent:Connect(function(...)
		pcall(WeaponRoll.fx, ...)
	end)
	refresh()
end

return WeaponRoll
