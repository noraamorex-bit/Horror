--[[
	Ending — how the night ends on your screen.

	• Remotes.Result: you're out early (escaped / died) and friends are still inside: a result card
	  with SPECTATE (watch them) and BACK TO LOBBY.
	• Remotes.Ending: everyone's night is over. A short cutscene for the ending (letterbox, slow
	  camera moves the server built from the map, one line of what happened), then your result
	  card: YOU SURVIVED / YOU ESCAPED / YOU DIED / YOU WERE TAKEN, the ending's name, and the way
	  back to the lobby.
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local Ending = {}
local ctx
local player = Players.LocalPlayer

local card: Frame? = nil -- the result card on screen
local music: Sound? = nil
local inCutscene = false
local savedClock: { number }? = nil -- the night sky to go back to after a dawn cutscene

local GOOD = Color3.fromRGB(120, 230, 150)
local BAD = Color3.fromRGB(255, 70, 70)
local GOLD = Color3.fromRGB(255, 205, 90)

function Ending.init(c)
	ctx = c
	ctx.EndingUI = Ending
end

-- a result card or the ending cutscene is on screen (Pace holds other messages)
function Ending.isShowing(): boolean
	return card ~= nil or inCutscene
end

local function stopMusic()
	if music then
		music:Destroy()
		music = nil
	end
end

-- (the endings used to slam in a victory or death sting and a looping sad piano: too loud, so the
-- ending scene's own sounds carry it now)
local function playMusic(_good: boolean)
	stopMusic()
end

local function closeCard()
	if card then
		card:Destroy()
		card = nil
	end
end

---------------------------------------------------------------------------
-- Revive (Config.Shop.Revive): a saved one first, otherwise buy one
---------------------------------------------------------------------------
local function reviveCredits(): number
	return tonumber(player:GetAttribute("ReviveCredits")) or 0
end

-- the price this player is actually charged (Roblox can price it lower in some regions), read
-- live from the product rather than hard-coded; Config's price until that answers
local livePrice: number? = nil
local livePriceAt = -1e9
local function revivePrice(): number?
	local r = ctx.Config.Shop.Revive
	if r and r.Id > 0 and os.clock() - livePriceAt > 300 then
		livePriceAt = os.clock()
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(r.Id, Enum.InfoType.Product)
			end)
			if ok and type(info) == "table" and tonumber(info.PriceInRobux) then
				livePrice = tonumber(info.PriceInRobux)
			end
		end)
	end
	return livePrice or (r and r.Price) or nil
end
Ending.revivePrice = revivePrice

function Ending.reviveLabel(): string
	if reviveCredits() > 0 then
		return "USE REVIVE (" .. reviveCredits() .. ")"
	end
	return "REVIVE  ·  " .. tostring(revivePrice() or "") .. " R$"
end

function Ending.revive()
	if reviveCredits() > 0 then
		ctx.Remotes.UseRevive:FireServer()
		return
	end
	local r = ctx.Config.Shop.Revive
	if r and r.Id > 0 then
		pcall(function()
			MarketplaceService:PromptProductPurchase(player, r.Id)
		end)
	end
end

---------------------------------------------------------------------------
-- The result card
---------------------------------------------------------------------------
local function button(parent: Instance, text: string, primary: boolean, order: number, onClick: () -> ())
	local UI = ctx.UI
	local b = UI.new("TextButton", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(primary and 230 or 190, 50),
		Text = text,
		Font = UI.Font.Bold,
		TextSize = 18,
		TextColor3 = primary and Color3.fromRGB(12, 12, 14) or UI.Color.Text,
		BackgroundColor3 = primary and Color3.fromRGB(240, 238, 232) or Color3.fromRGB(20, 20, 24),
		BackgroundTransparency = primary and 0 or 0.2,
		AutoButtonColor = true,
		Parent = parent,
	})
	UI.corner(b, 10)
	if not primary then
		UI.stroke(b, Color3.new(1, 1, 1), 1, 0.75)
	end
	b.Activated:Connect(onClick)
	return b
end

--[[
	opts: Headline, Good, Line, EndingTitle?, NewEnding?, Duration?, WinTime?, NewBest?, Revive?, ReviveIn?, Spectate?, Lobby?, RestartIn?,
	ReturnToLobby?, Coins? ({Total, Lines, Balance, LevelBefore, Level, XP, XPNext})
]]
-- this night: already said yes to another one (from an early card); and on our way to the lobby
local saidAgain = false
local leaving = false

local function showCard(opts)
	closeCard()
	local UI = ctx.UI
	local screen = UI.new("Frame", {
		Name = "Result",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(4, 4, 6),
		BackgroundTransparency = 1,
		Parent = UI.Top,
	})
	card = screen
	UI.modal(screen)
	UI.tween(screen, 0.8, { BackgroundTransparency = 0.12 })
	-- a soft glow behind the headline, red or green
	local accent = opts.Good and GOOD or BAD
	local glow = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(900, 420),
		BackgroundColor3 = accent,
		BackgroundTransparency = 1,
		Parent = screen,
	})
	UI.new("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.82), NumberSequenceKeypoint.new(1, 1) }),
		Parent = glow,
	})
	UI.tween(glow, 1.5, { BackgroundTransparency = 0 })

	local col = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(760, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = screen,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = col })
	local order = 0
	local function line(props)
		order += 1
		props.LayoutOrder = order
		props.Size = props.Size or UDim2.new(1, 0, 0, 0)
		props.AutomaticSize = Enum.AutomaticSize.Y
		props.Parent = col
		return UI.label(props)
	end

	if opts.NewEnding then
		local pill = line({ Text = opts.NewEnding, Font = UI.Font.Bold, TextSize = 15, TextColor3 = GOLD })
		pill.TextTransparency = 1
		task.delay(0.9, function()
			UI.tween(pill, 0.5, { TextTransparency = 0 })
		end)
	end
	local head = line({ Text = opts.Headline, Font = Enum.Font.GothamBlack, TextSize = 76, TextColor3 = opts.Good and Color3.fromRGB(245, 245, 240) or BAD, TextTransparency = 1 })
	UI.new("UIStroke", { Color = accent, Thickness = 2, Transparency = 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = head })
	-- the headline drops in
	local scale = UI.new("UIScale", { Scale = 1.35, Parent = head })
	UI.tween(head, 0.45, { TextTransparency = 0 })
	UI.tween(scale, 0.55, { Scale = 1 }, Enum.EasingStyle.Back)
	if opts.EndingTitle then
		line({ Text = "ENDING  ·  " .. opts.EndingTitle, Font = UI.Font.Bold, TextSize = 18, TextColor3 = accent })
	end
	local body = line({ Text = opts.Line or "", Font = UI.Font.Body, TextSize = 21, TextColor3 = UI.Color.Text, TextTransparency = 1 })
	task.delay(0.4, function()
		UI.tween(body, 0.6, { TextTransparency = 0 })
	end)
	-- a good night: the moment to ask for a like (20 votes so far, 45%: happy players rarely vote
	-- unless asked; only on wins, and only for a player's first few)
	if opts.Good and (tonumber(player:GetAttribute("StatNights")) or 0) < 5 then
		local ask = line({ Text = "Liked tonight? A 👍 on the game page helps a lot.", Font = UI.Font.Body, TextSize = 15, TextColor3 = UI.Color.Dim, TextTransparency = 1 })
		task.delay(1.6, function()
			UI.tween(ask, 0.6, { TextTransparency = 0 })
		end)
	end
	-- he got you: how, and how not to next time
	local tipText = not opts.Good and player:GetAttribute("DeathTip") or nil
	if type(tipText) == "string" and tipText ~= "" then
		local tip = line({ Text = "<font color=\"#d9b45a\"><b>TIP</b></font>   " .. tipText, Font = UI.Font.Body, TextSize = 16, TextColor3 = UI.Color.Dim, TextTransparency = 1 })
		task.delay(0.9, function()
			UI.tween(tip, 0.6, { TextTransparency = 0 })
		end)
	end
	-- (v103) the revive, right under the headline where it can't be missed: it used to sit at the
	-- bottom under the coins (off the screen on a phone), and 2 of 74 deaths bought one. Big,
	-- pulsing, with why it matters right now; the last one standing sees the night's countdown here.
	if opts.Revive then
		order += 1
		local panel = UI.new("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = col })
		UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = panel })
		local rb = button(panel, "⟳  " .. Ending.reviveLabel(), true, 1, Ending.revive)
		rb.BackgroundColor3 = Color3.fromRGB(120, 230, 150)
		rb.Size = UDim2.fromOffset(340, 62)
		rb.TextSize = 22
		local pulse = UI.new("UIScale", { Scale = 1, Parent = rb })
		task.spawn(function()
			while rb.Parent do
				UI.tween(pulse, 0.6, { Scale = 1.06 }, Enum.EasingStyle.Sine)
				task.wait(0.6)
				UI.tween(pulse, 0.6, { Scale = 1 }, Enum.EasingStyle.Sine)
				task.wait(0.6)
			end
		end)
		local why = opts.ReviveIn and "Back on your feet, far from him. The night goes on."
			or "Your friends are still in there. Get back in and help them."
		UI.label({ LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = why, TextSize = 15, TextColor3 = UI.Color.Dim, Parent = panel })
		if opts.ReviveIn then
			-- the last one standing: the night waits a moment for a revive
			local countdown = UI.label({ LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = "", Font = UI.Font.Bold, TextSize = 16, TextColor3 = BAD, Parent = panel })
			task.spawn(function()
				local left = opts.ReviveIn
				while left > 0 and screen.Parent do
					countdown.Text = "The night ends in " .. left .. "s"
					task.wait(1)
					left -= 1
				end
				if screen.Parent then
					countdown.Text = ""
				end
			end)
		end
	end
	if opts.WinTime then
		-- a win: your time, for the fastest-wins board in the lobby
		line({ Text = "YOUR TIME  " .. tostring(opts.WinTime), Font = UI.Font.Bold, TextSize = 20, TextColor3 = UI.Color.Text })
		if opts.NewBest then
			local best = line({ Text = "★ NEW PERSONAL BEST", Font = UI.Font.Bold, TextSize = 15, TextColor3 = GOLD, TextTransparency = 1 })
			task.delay(1.1, function()
				UI.tween(best, 0.5, { TextTransparency = 0 })
			end)
		end
	elseif opts.Duration then
		line({ Text = "Night lasted " .. tostring(opts.Duration), TextSize = 14, TextColor3 = UI.Color.Dim })
	end
	-- the night's coins: the total counts up, the reasons underneath (EconomyService.nightRewards)
	local coins = opts.Coins
	if opts.AdminNight then
		line({ Text = "Admin panel night: no coins or records", TextSize = 14, TextColor3 = UI.Color.Dim })
	end
	if type(coins) == "table" and (tonumber(coins.Total) or 0) > 0 then
		local total = line({ Text = "", Font = UI.Font.Bold, TextSize = 30, TextColor3 = GOLD })
		local parts = {}
		for _, l in (type(coins.Lines) == "table" and coins.Lines or {}) do
			table.insert(parts, string.format("%s +%d", tostring(l.Text), tonumber(l.Amount) or 0))
		end
		local why = line({ Text = table.concat(parts, "   ·   "), TextSize = 13, TextColor3 = UI.Color.Dim, TextTransparency = 1 })
		task.spawn(function()
			task.wait(1.2)
			local n = tonumber(coins.Total) or 0
			local t0 = os.clock()
			while total.Parent and os.clock() - t0 < 1 do
				total.Text = "+" .. math.floor(n * (os.clock() - t0)) .. " COINS"
				task.wait()
			end
			if total.Parent then
				total.Text = "+" .. n .. " COINS" .. (coins.Balance and ("   <font size=\"15\" color=\"#9a968e\">you have " .. tostring(coins.Balance) .. "</font>") or "")
				UI.tween(why, 0.5, { TextTransparency = 0 })
				if ctx.Effects then
					ctx.Effects.playSound("UISelect", nil, { Caption = false })
				end
			end
		end)
	end
	-- your level: the XP bar fills with the night's coins, LEVEL UP if it went over
	if type(coins) == "table" and tonumber(coins.Level) then
		order += 1
		local lvRow = UI.new("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = col })
		local lv = UI.label({ Size = UDim2.new(0, 96, 1, 0), Text = "LEVEL " .. tostring(coins.LevelBefore or coins.Level), Font = UI.Font.Bold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Right, Parent = lvRow })
		local track = UI.new("Frame", { Position = UDim2.new(0, 106, 0.5, -5), Size = UDim2.new(1, -212, 0, 10), BackgroundColor3 = Color3.fromRGB(50, 48, 44), Parent = lvRow })
		UI.corner(track, 5)
		local fill = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, Parent = track })
		UI.corner(fill, 5)
		local xpText = UI.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 96, 1, 0), Text = "", TextSize = 13, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, Parent = lvRow })
		local up = (tonumber(coins.LevelBefore) or 0) < (tonumber(coins.Level) or 0)
		local k = math.clamp((tonumber(coins.XP) or 0) / math.max(1, tonumber(coins.XPNext) or 1), 0, 1)
		task.spawn(function()
			task.wait(2.4)
			if not fill.Parent then
				return
			end
			if up then
				UI.tween(fill, 0.6, { Size = UDim2.fromScale(1, 1) })
				task.wait(0.7)
				lv.Text = "LEVEL " .. tostring(coins.Level)
				lv.TextColor3 = GOLD
				fill.Size = UDim2.fromScale(0, 1)
				if ctx.Effects then
					ctx.Effects.playSound("ObjectiveDone", nil, { Caption = false })
				end
			end
			UI.tween(fill, 0.6, { Size = UDim2.fromScale(k, 1) })
			xpText.Text = tostring(coins.XP or 0) .. " / " .. tostring(coins.XPNext or 0) .. " XP" .. (up and "   LEVEL UP!" or "")
			xpText.TextColor3 = up and GOLD or UI.Color.Dim
		end)
	end
	-- come back tomorrow: the next daily reward
	do
		local ok, eco = pcall(function()
			return game:GetService("HttpService"):JSONDecode(player:GetAttribute("Eco") or "{}")
		end)
		local daily = ok and type(eco) == "table" and eco.Daily or nil
		if type(daily) == "table" and daily.Next then
			local Cat = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Economy"))
			-- (Next is today's day while it's unclaimed; once claimed, tomorrow is the one after it)
			local tomorrow = daily.CanClaim and daily.Next or ((tonumber(daily.Next) or 0) % #Cat.Daily + 1)
			local coinsNext = Cat.Daily[tomorrow] or Cat.Daily[1]
			line({ Text = daily.CanClaim and ("Your daily reward is waiting in the lobby: " .. coinsNext .. " coins") or ("Tomorrow: day " .. tomorrow .. " reward, " .. coinsNext .. " coins" .. (tomorrow == Cat.DailyCrateDay and " + a crate" or "") .. ". Don't break your streak!"), TextSize = 13, TextColor3 = UI.Color.Dim })
		end
	end

	-- the buttons
	order += 1
	local row = UI.new("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Parent = col })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	if opts.Spectate then
		button(row, "SPECTATE", not opts.Revive, 1, function()
			closeCard()
			stopMusic()
			if ctx.Spectate then
				ctx.Spectate.begin()
			end
		end)
	end
	-- back to the lobby: says so at once (the teleport takes a few seconds; people kept tapping)
	local function lobbyButton(parent: Instance, text: string, primary: boolean, order: number)
		local b
		b = button(parent, leaving and "GOING TO THE LOBBY..." or text, primary, order, function()
			if leaving then
				return
			end
			leaving = true
			b.Text = "GOING TO THE LOBBY..."
			b.AutoButtonColor = false
			ctx.Remotes.LeaveGame:FireServer()
			task.delay(15, function()
				-- (the teleport failed: let them try again)
				leaving = false
				if b.Parent then
					b.Text = text
					b.AutoButtonColor = true
				end
			end)
		end)
		return b
	end
	local function againButton(parent: Instance, primary: boolean, order: number)
		local again
		again = button(parent, saidAgain and "WAITING FOR FRIENDS..." or "ANOTHER NIGHT", primary, order, function()
			if saidAgain then
				return
			end
			saidAgain = true
			ctx.Remotes.PlayAgain:FireServer()
			again.Text = "WAITING FOR FRIENDS..."
			again.AutoButtonColor = false
		end)
		return again
	end
	if opts.Again then
		saidAgain = true
	end
	if opts.ReturnToLobby and opts.RestartIn then
		-- the night is over: another one with the same group, right here, or the lobby
		againButton(row, true, 1).Size = UDim2.fromOffset(250, 54)
		lobbyButton(row, "LOBBY", false, 2)
	elseif opts.ReturnToLobby and opts.Spectate then
		-- out early while friends play on: watch them, and say you're in for the next night
		order += 1
		local row2 = UI.new("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Parent = col })
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = row2 })
		againButton(row2, false, 1).Size = UDim2.fromOffset(250, 48)
		lobbyButton(row2, "LOBBY", false, 2)
	elseif opts.ReturnToLobby then
		lobbyButton(row, "PLAY AGAIN", true, 2)
	end

	-- offers (v98), small and under the buttons: the one-time Starter Pack while it's on offer, and in a
	-- group that's staying for another night, being him in it
	do
		local st = ctx.Config.Shop.Starter
		local him = ctx.Config.Shop.BecomeHim
		local starter = st and st.Id > 0 and player:GetAttribute("StarterOffer") == true
		local beHim = opts.ReturnToLobby and opts.RestartIn and him and him.Id > 0 and #Players:GetPlayers() >= 2
			and ctx.MonsterUI ~= nil
		-- (v110: the passes were almost never seen, the shop being in the lobby where players spend
		-- half a minute: 2x Coins is offered here, where the night's coins are paid)
		local dbl = nil
		for _, ps in ctx.Config.Shop.Passes or {} do
			if ps.Key == "DoubleCoins" and ps.Id > 0 and not player:GetAttribute("Pass_DoubleCoins") then
				dbl = ps
			end
		end
		if starter or beHim or dbl then
			order += 1
			local offers = UI.new("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = col })
			UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = offers })
			local function offer(text: string, bg: Color3, fg: Color3, order: number, onClick: () -> ()): TextButton
				local b = UI.new("TextButton", {
					Name = "Offer",
					LayoutOrder = order,
					Size = UDim2.fromOffset(0, 36),
					AutomaticSize = Enum.AutomaticSize.X,
					Text = text,
					Font = UI.Font.Bold,
					TextSize = 14,
					TextColor3 = fg,
					BackgroundColor3 = bg,
					BackgroundTransparency = 0.1,
					AutoButtonColor = true,
					Parent = offers,
				})
				UI.corner(b, 8)
				UI.new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = b })
				b.Activated:Connect(onClick)
				return b
			end
			if starter then
				offer("🎁 STARTER PACK  ·  500 coins + rocket + revive  ·  R$ " .. tostring(st.Price) .. (if st.WasPrice then " (was " .. st.WasPrice .. ")" else ""), Color3.fromRGB(255, 205, 90), Color3.fromRGB(16, 14, 10), 1, function()
					pcall(function()
						MarketplaceService:PromptProductPurchase(player, st.Id)
					end)
				end).Name = "StarterOffer"
			end
			if dbl and not (starter and beHim) then
				offer("💰 2x COINS EVERY NIGHT  ·  R$ " .. tostring(dbl.Price), Color3.fromRGB(40, 36, 18), Color3.fromRGB(255, 226, 120), 3, function()
					pcall(function()
						MarketplaceService:PromptGamePassPurchase(player, dbl.Id)
					end)
				end).Name = "DoubleCoinsOffer"
			end
			if beHim then
				local saved = (tonumber(player:GetAttribute("MonsterCredits")) or 0) > 0
				local b
				-- (it says so once there's one saved for them: bought, or already had)
				local function done()
					if ctx.MonsterUI.wantsNext() and (tonumber(player:GetAttribute("MonsterCredits")) or 0) > 0 and b and b.Parent then
						b.Text = "😈 YOU'LL BE HIM NEXT NIGHT"
						b.AutoButtonColor = false
					end
				end
				b = offer("😈 BE HIM NEXT NIGHT  ·  " .. (saved and "free" or ("R$ " .. tostring(him.Price))), Color3.fromRGB(110, 14, 18), Color3.fromRGB(255, 225, 225), 2, function()
					-- (asks again if the last window was closed without buying)
					ctx.MonsterUI.wantNext()
					done()
				end)
				b.Name = "BeHimOffer"
				local conn = player:GetAttributeChangedSignal("MonsterCredits"):Connect(done)
				b.Destroying:Connect(function()
					conn:Disconnect()
				end)
				done()
			end
		end
	end
	-- the night streak: another night soon pays more (EconomyService.nightRewards)
	if type(coins) == "table" and (tonumber(coins.NextBonus) or 0) > 0 and opts.ReturnToLobby then
		local streak = tonumber(coins.Chain) or 0
		line({
			Text = (streak >= 2 and ("NIGHT STREAK ×" .. streak .. "  ·  ") or "")
				.. "Play another night in the next " .. tostring(coins.ChainMinutes or 15) .. " min: +" .. tostring(coins.NextBonus) .. "% coins",
			Font = UI.Font.Bold,
			TextSize = 14,
			TextColor3 = GOLD,
		})
	end
	-- Halloween: the candy you found tonight, and what's next (EconomyService.nightRewards)
	if type(coins) == "table" and type(coins.Candy) == "table" then
		local c = coins.Candy
		line({
			Text = string.format("🍬 +%d candy tonight  ·  %d in all", tonumber(c.Tonight) or 0, tonumber(c.Total) or 0)
				.. (c.Next and string.format("  ·  %s at %d", tostring(c.Next), tonumber(c.NextAt) or 0) or ""),
			Font = UI.Font.Bold,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(255, 150, 50),
		})
	end
	-- invite / favorite, and the countdown
	order += 1
	local social = UI.new("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = col })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = social })
	if ctx.Social then
		ctx.Social.button(social, "invite")
		ctx.Social.button(social, "favorite")
		ctx.Social.button(social, "remind")
	end
	if opts.Good then
		-- (likes decide how often Roblox recommends the game)
		line({ Text = "Enjoyed it? A 👍 on the game page helps more people find it.", TextSize = 13, TextColor3 = UI.Color.Dim })
	end
	if opts.RestartIn then
		local countdown = line({ Text = "", TextSize = 14, TextColor3 = UI.Color.Dim })
		task.spawn(function()
			local left = opts.RestartIn
			while left > 0 and screen.Parent do
				countdown.Text = (opts.ReturnToLobby and "Next night in " or "The house resets in ") .. left .. "s" .. (opts.ReturnToLobby and "   ·   LOBBY to leave" or "")
				task.wait(1)
				left -= 1
			end
		end)
	end
	return screen
end

---------------------------------------------------------------------------
-- The cutscene
---------------------------------------------------------------------------
local function letterbox(): (Frame, Frame, TextLabel)
	local UI = ctx.UI
	local top = UI.new("Frame", { Name = "BarTop", Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = UI.Top })
	local bottom = UI.new("Frame", { Name = "BarBottom", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = UI.Top })
	local sub = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.8, 0, 1, 0),
		Text = "",
		Font = UI.Font.Title,
		TextSize = 24,
		TextTransparency = 1,
		Parent = bottom,
	})
	UI.tween(top, 0.8, { Size = UDim2.new(1, 0, 0.12, 0) })
	UI.tween(bottom, 0.8, { Size = UDim2.new(1, 0, 0.14, 0) })
	return top, bottom, sub
end

local function playCutscene(payload)
	local shots = payload.Shots or {}
	if #shots == 0 then
		return
	end
	inCutscene = true
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local UI = ctx.UI
	if ctx.Effects then
		ctx.Effects.fade(true, 0.6)
	end
	task.wait(0.7)
	local top, bottom, sub = letterbox()
	-- seen it before? tap to go straight to the result
	local skipped = false
	local skip = UI.new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -24, 0.5, 0),
		Size = UDim2.fromOffset(110, 40),
		Text = "SKIP  ▸",
		Font = UI.Font.Bold,
		TextSize = 17,
		TextColor3 = Color3.fromRGB(235, 232, 226),
		BackgroundColor3 = Color3.fromRGB(30, 30, 34),
		BackgroundTransparency = 0.3,
		ZIndex = 3,
		Parent = bottom,
	})
	UI.corner(skip, 8)
	UI.stroke(skip, Color3.new(1, 1, 1), 1, 0.7)
	skip.Activated:Connect(function()
		skipped = true
	end)
	if ctx.Effects then
		ctx.Effects.fade(false, 1.2)
		ctx.Effects.playSound("RisingWhoosh", nil, { Caption = false })
	end
	-- dawn: the sky lightens through the cutscene
	for i, shot in shots do
		if skipped then
			break
		end
		if shot.Dawn then
			savedClock = savedClock or { Lighting.ClockTime, Lighting.Brightness }
			local tw = game:GetService("TweenService"):Create(Lighting, TweenInfo.new(shot.Time + 1.5), { ClockTime = 6.6, Brightness = 1.2 })
			tw:Play()
		end
		local t0 = os.clock()
		local car = payload.Car
		while os.clock() - t0 < shot.Time and not skipped do
			local k = (os.clock() - t0) / shot.Time
			local e = k * k * (3 - 2 * k)
			local cf = shot.From:Lerp(shot.To, e)
			-- the car's leaving: keep it in the middle of the shot while it's in sight
			if shot.Track == "Car" and car and car.Parent then
				local at = car:GetPivot().Position
				if (at - cf.Position).Magnitude < 260 then
					cf = CFrame.lookAt(cf.Position, at + Vector3.new(0, 2, 0))
				end
			end
			cam.CFrame = cf
			RunService.RenderStepped:Wait()
		end
		if i == 1 then
			sub.Text = payload.Short or ""
			UI.tween(sub, 0.8, { TextTransparency = 0 })
		end
	end
	skip:Destroy()
	task.wait(skipped and 0 or 0.3)
	UI.tween(top, 0.5, { Size = UDim2.new(1, 0, 0, 0) })
	UI.tween(bottom, 0.5, { Size = UDim2.new(1, 0, 0, 0) })
	UI.tween(sub, 0.4, { TextTransparency = 1 })
	task.delay(0.6, function()
		top:Destroy()
		bottom:Destroy()
	end)
	inCutscene = false
end

---------------------------------------------------------------------------
-- Remotes
---------------------------------------------------------------------------
-- out early: your own card, and the way to watch the others
local function onResult(payload)
	if ctx.Spectate then
		ctx.Spectate.stop()
	end
	playMusic(payload.Good == true)
	showCard({
		Headline = payload.Title,
		Good = payload.Good,
		Line = payload.Line,
		WinTime = payload.Time,
		NewBest = payload.NewBest,
		Revive = payload.CanRevive,
		ReviveIn = payload.ReviveIn,
		Spectate = payload.CanSpectate,
		ReturnToLobby = payload.ReturnToLobby,
		Coins = payload.Coins,
		AdminNight = payload.AdminNight,
	})
	-- (v126: the Starter Pack's window no longer opens on the result card: it comes at the start of a night)
end

local function onEnding(payload)
	closeCard()
	stopMusic()
	if ctx.Spectate then
		ctx.Spectate.stop()
	end
	-- the night is over: no more controls, a camera on rails
	task.spawn(function()
		if payload.InGame or player:GetAttribute("InGame") then
			playCutscene(payload)
		end
		local newEnding = nil
		if table.find(payload.FirstFor or {}, player.UserId) then
			local found, total = player:GetAttribute("StatEndings"), player:GetAttribute("StatEndingTotal")
			newEnding = "NEW ENDING FOUND" .. (found and total and ("  ·  " .. found .. " / " .. total) or "")
		end
		playMusic(payload.Good == true)
		showCard({
			Headline = payload.Headline,
			Good = payload.Good,
			EndingTitle = payload.Title,
			Line = payload.Short,
			NewEnding = newEnding,
			Duration = payload.Duration,
			WinTime = payload.WinTime,
			NewBest = payload.NewBest,
			ReturnToLobby = payload.ReturnToLobby,
			RestartIn = payload.RestartIn,
			Coins = payload.Coins,
			AdminNight = payload.AdminNight,
			Again = payload.Again,
		})
		task.delay(8, function()
			if card and ctx.Social then
				ctx.Social.maybeAskFavorite()
			end
		end)
	end)
end

function Ending.start()
	revivePrice() -- (fetch this player's price now, so the first death already shows it)
	ctx.Remotes.Result.OnClientEvent:Connect(onResult)
	ctx.Remotes.Ending.OnClientEvent:Connect(onEnding)
	-- revived: back in your own body, the night goes on
	ctx.Remotes.Revived.OnClientEvent:Connect(function()
		closeCard()
		stopMusic()
		if ctx.Spectate then
			ctx.Spectate.stop()
		end
		if ctx.Effects then
			ctx.Effects.playSound("RisingWhoosh", nil, { Caption = false })
		end
	end)
	-- the next lobby clears it all
	workspace:GetAttributeChangedSignal("Act"):Connect(function()
		if workspace:GetAttribute("Act") == "Lobby" then
			saidAgain = false
			leaving = false
			closeCard()
			stopMusic()
			if savedClock then
				Lighting.ClockTime = savedClock[1]
				Lighting.Brightness = savedClock[2]
				savedClock = nil
			end
			if not inCutscene then
				local cam = workspace.CurrentCamera
				cam.CameraType = Enum.CameraType.Custom
			end
		end
	end)
end

return Ending
