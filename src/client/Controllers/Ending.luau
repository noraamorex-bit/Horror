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
end

local function stopMusic()
	if music then
		music:Destroy()
		music = nil
	end
end

local function playMusic(good: boolean)
	stopMusic()
	if not ctx.Effects then
		return
	end
	if good then
		ctx.Effects.playSound("VictorySting", nil, { Caption = false })
	else
		ctx.Effects.playSound("DeathSting", nil, { Caption = false })
		music = ctx.Effects.localSound("SadPiano")
		if music then
			music.Looped = true
			music:Play()
		end
	end
end

local function closeCard()
	if card then
		card:Destroy()
		card = nil
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
	opts: Headline, Good, Line, EndingTitle?, NewEnding?, Duration?, WinTime?, NewBest?, Spectate?, Lobby?, RestartIn?,
	ReturnToLobby?
]]
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

	-- the buttons
	order += 1
	local row = UI.new("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Parent = col })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	if opts.Spectate then
		button(row, "SPECTATE", true, 1, function()
			closeCard()
			stopMusic()
			if ctx.Spectate then
				ctx.Spectate.begin()
			end
		end)
	end
	if opts.ReturnToLobby then
		button(row, opts.Spectate and "BACK TO LOBBY" or "PLAY AGAIN", not opts.Spectate, 2, function()
			ctx.Remotes.LeaveGame:FireServer()
		end)
	end

	-- invite / favorite, and the countdown
	order += 1
	local social = UI.new("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = col })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = social })
	if ctx.Social then
		ctx.Social.button(social, "invite")
		ctx.Social.button(social, "favorite")
	end
	if opts.RestartIn then
		local countdown = line({ Text = "", TextSize = 14, TextColor3 = UI.Color.Dim })
		task.spawn(function()
			local left = opts.RestartIn
			while left > 0 and screen.Parent do
				countdown.Text = (opts.ReturnToLobby and "Back to the lobby in " or "The house resets in ") .. left .. "s"
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
		Spectate = payload.CanSpectate,
		ReturnToLobby = payload.ReturnToLobby,
	})
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
		})
		task.delay(8, function()
			if card and ctx.Social then
				ctx.Social.maybeAskFavorite()
			end
		end)
	end)
end

function Ending.start()
	ctx.Remotes.Result.OnClientEvent:Connect(onResult)
	ctx.Remotes.Ending.OnClientEvent:Connect(onEnding)
	-- the next lobby clears it all
	workspace:GetAttributeChangedSignal("Act"):Connect(function()
		if workspace:GetAttribute("Act") == "Lobby" then
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
