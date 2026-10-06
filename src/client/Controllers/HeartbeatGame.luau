--[[
	HeartbeatGame — the heartbeat minigame (server: HeartbeatService), like DOORS. He's standing
	right outside your hiding spot, listening. A heart sits in the middle of the screen; half-
	hearts fly in from the left (blue) and the right (pink). Press that side as each one reaches
	the heart:
		keyboard  Q / E  (or the arrow keys)
		gamepad   LB / RB
		touch     the big LEFT / RIGHT buttons
	Each beat is judged here and reported to the server (hit or miss); the server counts the
	misses. Too many and he hears you.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local HeartbeatGame = {}
local ctx
local player = Players.LocalPlayer

local LEFT = Color3.fromRGB(80, 190, 255)
local RIGHT = Color3.fromRGB(255, 95, 170)

local root: Frame
local heart: TextLabel
local missLabel: TextLabel
local hint: TextLabel
local touchL: TextButton
local touchR: TextButton
local session: any = nil

function HeartbeatGame.isActive(): boolean
	return session ~= nil
end

local function now(): number
	return workspace:GetServerTimeNow()
end

local function report(i: number, hit: boolean)
	local s = session
	if not s or s.Done[i] then
		return
	end
	s.Done[i] = true
	ctx.Remotes.HeartbeatInput:FireServer(s.Id, i, hit)
	local piece = s.Pieces[i]
	if piece then
		piece:Destroy()
		s.Pieces[i] = nil
	end
	if hit then
		if ctx.Effects then
			ctx.Effects.playSound("HeartHit", nil, { Caption = false })
		end
		heart.TextColor3 = Color3.fromRGB(255, 255, 255)
		heart.Size = UDim2.fromOffset(150, 150)
		ctx.UI.tween(heart, 0.25, { Size = UDim2.fromOffset(130, 130), TextColor3 = Color3.fromRGB(230, 40, 60) })
	else
		s.Misses += 1
		missLabel.Text = string.rep("✕ ", s.Misses) .. string.rep("· ", math.max(0, s.Limit - s.Misses))
		heart.TextColor3 = Color3.fromRGB(120, 0, 0)
		ctx.UI.tween(heart, 0.35, { TextColor3 = Color3.fromRGB(230, 40, 60) })
		if ctx.Effects then
			ctx.Effects.playSound("HorrorHitLow", nil, { Caption = false, Volume = 0.6 })
		end
	end
end

-- a press on one side: judged against the nearest beat still in the air
local function press(side: string)
	local s = session
	if not s then
		return
	end
	local t = now() - s.Start
	local best, bestD = nil, math.huge
	for i, b in s.Beats do
		if not s.Done[i] then
			local d = math.abs(t - b.T)
			if d < bestD then
				best, bestD = i, d
			end
		end
	end
	if not best or bestD > s.Window then
		return -- (nothing arriving right now: a stray press doesn't count either way)
	end
	report(best, s.Beats[best].Side == side)
end

local function close(result: string?)
	local s = session
	session = nil
	if s then
		for _, p in s.Pieces do
			p:Destroy()
		end
	end
	if result == "Pass" then
		hint.Text = "He's moving away..."
		task.delay(1.2, function()
			if not session then
				root.Visible = false
			end
		end)
	else
		root.Visible = false
	end
end

local function open(payload)
	close(nil)
	local s = {
		Id = payload.Id,
		Start = payload.Start,
		Beats = payload.Beats or {},
		Travel = payload.Travel or 0.9,
		Window = payload.Window or 0.22,
		Limit = payload.Misses or 3,
		Misses = 0,
		Done = {},
		Pieces = {},
	}
	session = s
	missLabel.Text = string.rep("· ", s.Limit)
	local touch = ctx.UI.isTouch()
	hint.Text = touch and "He's listening. Tap LEFT or RIGHT as each half reaches the heart."
		or (ctx.UI.isGamepad() and "He's listening. Press LB / RB as each half reaches the heart."
			or "He's listening. Press Q / E as each half reaches the heart.")
	touchL.Visible = touch
	touchR.Visible = touch
	root.Visible = true
	if ctx.Effects then
		ctx.Effects.playSound("GaspDeep", nil, { Caption = false, Volume = 0.5 })
	end
end

function HeartbeatGame.init(c)
	ctx = c
	ctx.HeartbeatUI = HeartbeatGame
end

function HeartbeatGame.start()
	local UI = ctx.UI
	root = UI.new("Frame", {
		Name = "HeartbeatGame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromOffset(700, 260),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 25,
		Parent = UI.Top,
	})
	-- the lane the halves fly along
	local lane = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(620, 6), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85, ZIndex = 25, Parent = root })
	UI.corner(lane, 3)
	heart = UI.new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(130, 130),
		BackgroundTransparency = 1,
		Text = "♥",
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.fromRGB(230, 40, 60),
		TextStrokeTransparency = 0.4,
		ZIndex = 27,
		Parent = root,
	})
	missLabel = UI.label({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.42, 70), Size = UDim2.fromOffset(300, 26), Text = "", Font = UI.Font.Bold, TextSize = 22, TextColor3 = Color3.fromRGB(255, 120, 120), ZIndex = 27, Parent = root })
	hint = UI.label({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.42, 100), Size = UDim2.fromOffset(680, 26), Text = "", TextSize = 18, TextColor3 = UI.Color.Text, ZIndex = 27, Parent = root })
	local function sideButton(text: string, color: Color3, anchorX: number, posX: UDim): TextButton
		local b = UI.new("TextButton", {
			AnchorPoint = Vector2.new(anchorX, 1),
			Position = UDim2.new(posX.Scale, posX.Offset, 1, -30),
			Size = UDim2.fromOffset(200, 120),
			Text = text,
			Font = UI.Font.Bold,
			TextSize = 26,
			TextColor3 = Color3.new(1, 1, 1),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.35,
			Visible = false,
			ZIndex = 26,
			Parent = UI.Top,
		})
		UI.corner(b, 18)
		return b
	end
	touchL = sideButton("◀ LEFT", LEFT, 0, UDim.new(0, 30))
	touchR = sideButton("RIGHT ▶", RIGHT, 1, UDim.new(1, -30))
	-- (on touch-down, not release: timing matters)
	for _, pair in { { touchL, "L" }, { touchR, "R" } } do
		pair[1].InputBegan:Connect(function(io: InputObject)
			if io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then
				press(pair[2])
			end
		end)
	end

	UserInputService.InputBegan:Connect(function(io, processed)
		if not session or processed then
			return
		end
		local k = io.KeyCode
		if k == Enum.KeyCode.Q or k == Enum.KeyCode.ButtonL1 or k == Enum.KeyCode.Left then
			press("L")
		elseif k == Enum.KeyCode.E or k == Enum.KeyCode.ButtonR1 or k == Enum.KeyCode.Right then
			press("R")
		end
	end)

	ctx.Remotes.Heartbeat.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			close(nil)
			return
		end
		if payload.Result then
			if session and session.Id == payload.Id then
				close(payload.Result)
			end
			return
		end
		open(payload)
	end)

	-- the halves in flight
	RunService.RenderStepped:Connect(function()
		local s = session
		if not s then
			touchL.Visible = false
			touchR.Visible = false
			return
		end
		local t = now() - s.Start
		for i, b in s.Beats do
			if not s.Done[i] then
				local k = 1 - (b.T - t) / s.Travel -- 0 at the edge, 1 at the heart
				if k >= 0 and not s.Pieces[i] then
					s.Pieces[i] = UI.new("TextLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.fromOffset(64, 64),
						BackgroundTransparency = 1,
						Text = "♥",
						TextScaled = true,
						Font = Enum.Font.GothamBlack,
						TextColor3 = b.Side == "L" and LEFT or RIGHT,
						TextStrokeTransparency = 0.3,
						ZIndex = 26,
						Parent = root,
					})
				end
				local piece = s.Pieces[i]
				if piece then
					local dir = b.Side == "L" and -1 or 1
					local x = dir * 300 * (1 - math.clamp(k, 0, 1.3))
					piece.Position = UDim2.new(0.5, x, 0.42, 0)
				end
				-- flew past without a press: a miss
				if t > b.T + s.Window then
					report(i, false)
				end
			end
		end
	end)

	-- the moment you're out of the hiding spot, the game's over (the server decides the rest)
	player:GetAttributeChangedSignal("Hiding"):Connect(function()
		if not player:GetAttribute("Hiding") and session then
			close(nil)
		end
	end)
end

return HeartbeatGame
