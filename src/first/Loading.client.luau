--[[
	Loading — the first thing anyone sees: a black screen with rain streaking down, the title,
	a one-line hook and a loading bar. Replaces Roblox's default loading screen and fades out
	once the game has loaded (never sooner than a couple of seconds, never later than 15).
]]

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "HomeAloneLoading"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.ResetOnSpawn = false

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(6, 7, 10)
bg.BorderSizePixel = 0
bg.Parent = gui

-- rain: thin streaks falling down the screen
local rain = Instance.new("Frame")
rain.Size = UDim2.fromScale(1, 1)
rain.BackgroundTransparency = 1
rain.ClipsDescendants = true
rain.Parent = bg
local drops = {}
local rng = Random.new()
for _ = 1, 60 do
	local d = Instance.new("Frame")
	d.BorderSizePixel = 0
	d.BackgroundColor3 = Color3.fromRGB(150, 165, 190)
	d.BackgroundTransparency = rng:NextNumber(0.55, 0.85)
	d.Size = UDim2.new(0, 1, rng:NextNumber(0.04, 0.09), 0)
	d.Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber(-0.2, 1))
	d.Parent = rain
	table.insert(drops, { Frame = d, Speed = rng:NextNumber(0.9, 1.6) })
end

-- a warm window glowing in the dark, like the house seen from the street
local window = Instance.new("Frame")
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.3)
window.Size = UDim2.fromOffset(70, 90)
window.BackgroundColor3 = Color3.fromRGB(255, 190, 110)
window.BorderSizePixel = 0
window.Parent = bg
local glow = Instance.new("UIStroke")
glow.Color = Color3.fromRGB(255, 170, 90)
glow.Thickness = 6
glow.Transparency = 0.6
glow.Parent = window
for _, spec in { { UDim2.new(0.5, -2, 0, 0), UDim2.new(0, 4, 1, 0) }, { UDim2.new(0, 0, 0.5, -2), UDim2.new(1, 0, 0, 4) } } do
	local bar = Instance.new("Frame")
	bar.Position = spec[1]
	bar.Size = spec[2]
	bar.BackgroundColor3 = Color3.fromRGB(20, 18, 16)
	bar.BorderSizePixel = 0
	bar.Parent = window
end
-- a silhouette standing in it
local figure = Instance.new("Frame")
figure.AnchorPoint = Vector2.new(0.5, 1)
figure.Position = UDim2.new(0.72, 0, 1, 0)
figure.Size = UDim2.fromOffset(16, 46)
figure.BackgroundColor3 = Color3.fromRGB(12, 10, 10)
figure.BorderSizePixel = 0
figure.BackgroundTransparency = 1
figure.Parent = window
local figHead = Instance.new("Frame")
figHead.AnchorPoint = Vector2.new(0.5, 1)
figHead.Position = UDim2.new(0.5, 0, 0, 1)
figHead.Size = UDim2.fromOffset(12, 12)
figHead.BackgroundColor3 = figure.BackgroundColor3
figHead.BackgroundTransparency = 1
figHead.BorderSizePixel = 0
figHead.Parent = figure
Instance.new("UICorner", figHead).CornerRadius = UDim.new(1, 0)

local function label(text: string, y: number, h: number, font: Enum.Font, color: Color3)
	local l = Instance.new("TextLabel")
	l.AnchorPoint = Vector2.new(0.5, 0)
	l.Position = UDim2.fromScale(0.5, y)
	l.Size = UDim2.fromScale(0.9, h)
	l.BackgroundTransparency = 1
	l.Font = font
	l.TextScaled = true
	l.TextColor3 = color
	l.Text = text
	l.Parent = bg
	return l
end
label("someone lives in our attic.", 0.45, 0.09, Enum.Font.Merriweather, Color3.fromRGB(236, 230, 218))
label("Your parents are gone for the weekend. Your friends are over. You are not alone.", 0.565, 0.04, Enum.Font.GothamMedium, Color3.fromRGB(170, 166, 158))
local status = label("Loading...", 0.8, 0.03, Enum.Font.Gotham, Color3.fromRGB(130, 126, 120))
local barBack = Instance.new("Frame")
barBack.AnchorPoint = Vector2.new(0.5, 0)
barBack.Position = UDim2.fromScale(0.5, 0.75)
barBack.Size = UDim2.new(0.4, 0, 0, 4)
barBack.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
barBack.BorderSizePixel = 0
barBack.Parent = bg
local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = Color3.fromRGB(235, 232, 226)
bar.BorderSizePixel = 0
bar.Parent = barBack

gui.Parent = player:WaitForChild("PlayerGui")
ReplicatedFirst:RemoveDefaultLoadingScreen()

local TIPS = {
	"Tip: hide in closets and under beds. Hold your breath when he's close.",
	"Tip: he hears you run. Crouch when he's near.",
	"Tip: the fire keeps the living room lit when the power dies.",
	"Tip: stick together. Friends can free you if you're taken.",
	"Tip: the upstairs bathroom window gets one bar of signal.",
}
status.Text = TIPS[rng:NextInteger(1, #TIPS)]

local t0 = os.clock()
local running = true
task.spawn(function()
	local last = os.clock()
	while running do
		local now = os.clock()
		local dt = now - last
		last = now
		for _, d in drops do
			local p = d.Frame.Position
			local y = p.Y.Scale + dt * d.Speed
			if y > 1.05 then
				y = -0.1
				d.Frame.Position = UDim2.fromScale(rng:NextNumber(), y)
			else
				d.Frame.Position = UDim2.fromScale(p.X.Scale, y)
			end
		end
		-- the window flickers now and then; for an instant someone is standing in it
		local flick = math.sin(now * 13) > 0.97
		window.BackgroundColor3 = flick and Color3.fromRGB(120, 90, 60) or Color3.fromRGB(255, 190, 110)
		local seen = (now - t0) % 7 > 6.2
		figure.BackgroundTransparency = seen and 0 or 1
		figHead.BackgroundTransparency = seen and 0 or 1
		-- progress: assets still queued, eased toward done
		local queued = ContentProvider.RequestQueueSize
		local target = game:IsLoaded() and 1 or math.clamp(1 - queued / 200, 0.05, 0.9)
		bar.Size = UDim2.fromScale(bar.Size.X.Scale + (target - bar.Size.X.Scale) * 0.1, 1)
		task.wait()
	end
end)

if not game:IsLoaded() then
	game.Loaded:Wait()
end
while os.clock() - t0 < 2.5 or (ContentProvider.RequestQueueSize > 0 and os.clock() - t0 < 15) do
	task.wait(0.2)
end
local info = TweenInfo.new(1.2)
for _, d in bg:GetDescendants() do
	if d:IsA("TextLabel") then
		TweenService:Create(d, info, { TextTransparency = 1 }):Play()
	elseif d:IsA("Frame") then
		TweenService:Create(d, info, { BackgroundTransparency = 1 }):Play()
	elseif d:IsA("UIStroke") then
		TweenService:Create(d, info, { Transparency = 1 }):Play()
	end
end
TweenService:Create(bg, info, { BackgroundTransparency = 1 }):Play()
task.wait(1.3)
running = false
gui:Destroy()
