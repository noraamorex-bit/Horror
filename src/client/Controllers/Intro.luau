--[[
	Intro — the night's opening shot (Remotes.Intro, at the start of the Evening).

	Four seconds from across the street in the rain: the house with its lamps on, a slow push in,
	a flash of lightning, and for half a second someone standing in the upstairs window. Then
	the cut inside, to the warm living room, as if nothing happened. Notices and the chapter card
	wait until it's over.

	Only for a player's first few nights: after that they know who's upstairs.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Intro = {}
local ctx

local DURATION = 4.6
local FROM = Vector3.new(2, 7.8, -92)
local TO = Vector3.new(2, 8.8, -80)
local LOOK = Vector3.new(2, 15.6, -30)
-- standing just inside the upstairs front window, looking out at the street
local WINDOW = CFrame.lookAt(Vector3.new(2, 18, -28.4), Vector3.new(2, 18, -60))
local MAX_NIGHTS = 3

local playing = false

local function ease(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function Intro.play()
	if playing then
		return
	end
	local player = Players.LocalPlayer
	if (tonumber(player:GetAttribute("StatNights")) or 0) >= MAX_NIGHTS then
		return
	end
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	playing = true
	if ctx.Notice and ctx.Notice.hold then
		ctx.Notice.hold(DURATION + 0.6)
	end
	local UI = ctx.UI
	local black = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0, ZIndex = 100, Parent = UI.Top })
	local bars = {}
	for _, top in { true, false } do
		table.insert(bars, UI.new("Frame", {
			AnchorPoint = Vector2.new(0, top and 0 or 1),
			Position = UDim2.fromScale(0, top and 0 or 1),
			Size = UDim2.fromScale(1, 0.11),
			BackgroundColor3 = Color3.new(0, 0, 0),
			ZIndex = 99,
			Parent = UI.Top,
		}))
	end
	local caption = UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.86, 0),
		Size = UDim2.fromOffset(600, 26),
		Text = "14 Alder Lane  ·  Friday, 8:47 PM",
		Font = UI.Font.Bold,
		TextSize = 16,
		TextColor3 = UI.Color.Dim,
		TextTransparency = 1,
		ZIndex = 101,
		Parent = UI.Top,
	})
	local prevType = cam.CameraType
	cam.CameraType = Enum.CameraType.Scriptable
	UI.tween(black, 0.5, { BackgroundTransparency = 1 })
	UI.tween(caption, 0.8, { TextTransparency = 0.1 })

	local t0 = os.clock()
	local flashed = false
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local k = ease(t / DURATION)
		local pos = FROM:Lerp(TO, k)
		-- a held camera in the rain, and a jolt with the thunder
		local jolt = flashed and math.max(0, 1 - (t - 1.55) / 0.5) or 0
		local drift = Vector3.new(math.sin(t * 1.3) * 0.06 + (math.random() - 0.5) * 0.3 * jolt, math.sin(t * 1.7) * 0.05 + (math.random() - 0.5) * 0.3 * jolt, 0)
		cam.CFrame = CFrame.lookAt(pos + drift, LOOK)
		if not flashed and t >= 1.5 then
			flashed = true
			-- lightning: and there he is, in the window, looking down at the street
			if ctx.Atmosphere and ctx.Atmosphere.lightning then
				ctx.Atmosphere.lightning(1.4, 0.7)
			end
			if ctx.Effects and ctx.Effects.figure then
				ctx.Effects.figure(WINDOW, 0.55)
			end
		end
	end)
	task.delay(DURATION - 0.35, function()
		UI.tween(black, 0.3, { BackgroundTransparency = 0 })
		UI.tween(caption, 0.3, { TextTransparency = 1 })
	end)
	task.delay(DURATION, function()
		conn:Disconnect()
		cam.CameraType = prevType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or prevType
		for _, b in bars do
			b:Destroy()
		end
		caption:Destroy()
		UI.tween(black, 0.6, { BackgroundTransparency = 1 })
		task.delay(0.7, function()
			black:Destroy()
		end)
		playing = false
	end)
end

function Intro.init(c)
	ctx = c
end

function Intro.start()
	ctx.Remotes.Intro.OnClientEvent:Connect(Intro.play)
end

return Intro
