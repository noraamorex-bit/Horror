--[[
	TVScreens — what's actually on the living-room TV, channel by channel, drawn on the
	screen's SurfaceGui: a real-looking broadcast with a background picture and big, readable
	text, not just a channel name.

		local screens = TVScreens.build(surfaceGui)
		screens.show("News" | "Movie" | "Weather" | "Static" | "Alert")
		screens.off()

	Pictures are public Creator Store decals (their image ids):
		news background  "news screen background" (07_blissevol)  18973596135
		weather radar    "Hook echo on radar" (99Babycakes)        17440373515
		no signal        "tv static" colour bars                   7851707548
]]

local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local TVScreens = {}

local IMG = {
	News = "rbxassetid://18973596135",
	Radar = "rbxassetid://17440373515",
	Bars = "rbxassetid://7851707548",
}

local WHITE = Color3.fromRGB(250, 250, 250)
local RED = Color3.fromRGB(196, 22, 28)
local BLACK = Color3.fromRGB(8, 8, 10)

local function new(className: string, props, parent: Instance?)
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	if inst:IsA("GuiObject") then
		(inst :: GuiObject).BorderSizePixel = 0
	end
	inst.Parent = parent
	return inst
end

local function text(parent: Instance, props)
	local base = {
		BackgroundTransparency = 1,
		TextColor3 = WHITE,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextWrapped = true,
	}
	for k, v in props do
		if k ~= "Max" then
			base[k] = v
		end
	end
	local l = new("TextLabel", base, parent)
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = props.Max or 60
	c.Parent = l
	return l
end

local function box(parent: Instance, pos: UDim2, size: UDim2, color: Color3, transparency: number?)
	return new("Frame", { Position = pos, Size = size, BackgroundColor3 = color, BackgroundTransparency = transparency or 0 }, parent)
end

local function px(x: number, y: number): UDim2
	return UDim2.fromOffset(x, y)
end

-- Channel 7: the report about him
local function buildNews(root: Frame, clock: () -> string)
	local f = box(root, px(0, 0), UDim2.fromScale(1, 1), BLACK)
	new("ImageLabel", { Size = UDim2.fromScale(1, 1), Image = IMG.News, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop }, f)
	-- channel bug and LIVE
	local bug = box(f, px(14, 12), px(92, 30), RED)
	text(bug, { Size = UDim2.fromScale(1, 1), Text = "7 NEWS", Font = Enum.Font.GothamBlack, Max = 22 })
	local live = box(f, px(474, 12), px(72, 28), RED)
	text(live, { Size = UDim2.fromScale(1, 1), Text = "LIVE", Font = Enum.Font.GothamBlack, Max = 20 })
	-- the suspect: a silhouette in a box
	local panel = box(f, px(22, 56), px(150, 178), Color3.fromRGB(16, 22, 40), 0.1)
	new("UIStroke", { Color = WHITE, Thickness = 2, Transparency = 0.3 }, panel)
	text(panel, { Position = px(0, 4), Size = UDim2.new(1, 0, 0, 22), Text = "SUSPECT", Font = Enum.Font.GothamBlack, Max = 18 })
	local headShape = box(panel, px(48, 34), px(54, 64), Color3.fromRGB(40, 44, 54))
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, headShape)
	local shoulders = box(panel, px(18, 94), px(114, 52), Color3.fromRGB(40, 44, 54))
	new("UICorner", { CornerRadius = UDim.new(0.35, 0) }, shoulders)
	text(headShape, { Size = UDim2.fromScale(1, 1), Text = "?", TextColor3 = Color3.fromRGB(120, 126, 140), Max = 34 })
	text(panel, { Position = px(4, 150), Size = UDim2.new(1, -8, 0, 24), Text = "MALE · 40s · 6'4\"", Font = Enum.Font.GothamMedium, Max = 16 })
	-- the headline
	text(f, { Position = px(190, 60), Size = px(352, 112), Text = "MAN SOUGHT IN HOLLIS CREEK BREAK-INS", Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Max = 40, TextStrokeTransparency = 0.5 })
	text(f, { Position = px(190, 176), Size = px(352, 56), Text = "Police say he may have been living inside homes while the families were out.", Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Max = 20, TextStrokeTransparency = 0.6 })
	-- BREAKING NEWS bar and the ticker under it
	local breaking = box(f, px(0, 246), px(560, 40), RED)
	text(breaking, { Position = px(14, 0), Size = px(300, 40), Text = "BREAKING NEWS", Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Max = 30 })
	local clockLabel = text(breaking, { Position = px(440, 0), Size = px(106, 40), Text = clock(), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, Max = 24 })
	local tickerBar = box(f, px(0, 286), px(560, 54), WHITE)
	tickerBar.ClipsDescendants = true
	local tickerText = "LAST SEEN DRIVING A GRAY PANEL VAN  ·  DO NOT APPROACH  ·  REPORT SIGHTINGS: (555) 0142  ·  FLASH FLOOD WARNING UNTIL 6 AM  ·  CREEK ROAD CLOSED  ·  "
	-- one long line at a fixed size (scaled text would wrap and shrink to nothing)
	local tickerWidth = 2600
	pcall(function()
		tickerWidth = TextService:GetTextSize(tickerText, 26, Enum.Font.GothamBold, Vector2.new(100000, 42)).X + 20
	end)
	local ticker = new("TextLabel", {
		Position = px(560, 6),
		Size = px(tickerWidth, 42),
		BackgroundTransparency = 1,
		Text = tickerText,
		TextColor3 = BLACK,
		Font = Enum.Font.GothamBold,
		TextSize = 26,
		TextScaled = false,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, tickerBar)
	return f, function(alive: () -> boolean)
		task.spawn(function()
			while alive() do
				ticker.Position = px(560, 6)
				-- a steady 90 px a second, whatever the text's length
				local dur = (560 + tickerWidth) / 90
				local tw = TweenService:Create(ticker, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Position = px(-tickerWidth, 6) })
				tw:Play()
				local t0 = os.clock()
				while alive() and os.clock() - t0 < dur do
					clockLabel.Text = clock()
					task.wait(1)
				end
				tw:Cancel()
			end
		end)
	end
end

-- Channel 11: the storm
local function buildWeather(root: Frame)
	local f = box(root, px(0, 0), UDim2.fromScale(1, 1), BLACK)
	new("ImageLabel", { Size = UDim2.fromScale(1, 1), Image = IMG.Radar, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop }, f)
	local bug = box(f, px(14, 12), px(132, 30), Color3.fromRGB(20, 60, 140))
	text(bug, { Size = UDim2.fromScale(1, 1), Text = "11 WEATHER", Font = Enum.Font.GothamBlack, Max = 20 })
	local warn = box(f, px(0, 236), px(560, 46), RED)
	text(warn, { Position = px(14, 0), Size = px(532, 46), Text = "FLASH FLOOD WARNING", Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Max = 34 })
	local sub = box(f, px(0, 282), px(560, 58), BLACK, 0.15)
	text(sub, { Position = px(14, 4), Size = px(532, 50), Text = "Hollis County until 6 AM · Creek Road closed · 4 more inches tonight", Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Max = 22 })
	return f
end

-- Channel 4: an old black-and-white film, a little too close to home
local SUBTITLES = {
	"\"Did you hear that, Margaret?\"",
	"\"It's the house settling. Old houses settle.\"",
	"\"Houses don't breathe.\"",
	"\"Then who's been eating the bread?\"",
	"\"Go back to sleep. Nobody's up there.\"",
}
local function buildMovie(root: Frame)
	local f = box(root, px(0, 0), UDim2.fromScale(1, 1), BLACK)
	local film = box(f, px(0, 38), px(560, 264), Color3.fromRGB(46, 46, 48))
	-- a doorway at the end of a hall, and something in it
	box(film, px(232, 40), px(96, 190), Color3.fromRGB(16, 16, 18))
	box(film, px(262, 70), px(36, 120), Color3.fromRGB(6, 6, 6))
	local head = box(film, px(268, 52), px(24, 26), Color3.fromRGB(6, 6, 6))
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, head)
	box(film, px(0, 230), px(560, 34), Color3.fromRGB(30, 30, 32))
	new("ImageLabel", { Size = UDim2.fromScale(1, 1), Image = IMG.Bars, ImageTransparency = 0.92, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop }, film)
	text(f, { Position = px(14, 6), Size = px(300, 26), Text = "CH 4 · THE NIGHT VISITOR (1958)", Font = Enum.Font.Garamond, TextXAlignment = Enum.TextXAlignment.Left, Max = 20, TextColor3 = Color3.fromRGB(200, 200, 200) })
	local sub = text(f, { Position = px(20, 304), Size = px(520, 34), Text = SUBTITLES[1], Font = Enum.Font.Garamond, Max = 26, TextColor3 = Color3.fromRGB(240, 236, 210) })
	return f, function(alive: () -> boolean)
		task.spawn(function()
			local i = 1
			while alive() do
				task.wait(4)
				i = i % #SUBTITLES + 1
				sub.Text = SUBTITLES[i]
			end
		end)
	end
end

-- Channel 12: nothing
local function buildStatic(root: Frame)
	local f = box(root, px(0, 0), UDim2.fromScale(1, 1), BLACK)
	new("ImageLabel", { Size = UDim2.fromScale(1, 1), Image = IMG.Bars, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Stretch }, f)
	local tag = box(f, px(170, 140), px(220, 56), BLACK, 0.2)
	text(tag, { Size = UDim2.fromScale(1, 1), Text = "NO SIGNAL", Font = Enum.Font.GothamBlack, Max = 34 })
	return f
end

-- the Emergency Alert System breaking in
local function buildAlert(root: Frame)
	local f = box(root, px(0, 0), UDim2.fromScale(1, 1), Color3.fromRGB(150, 16, 20))
	text(f, { Position = px(20, 30), Size = px(520, 60), Text = "EMERGENCY ALERT SYSTEM", Font = Enum.Font.GothamBlack, Max = 44 })
	text(f, { Position = px(20, 120), Size = px(520, 70), Text = "FLASH FLOOD WARNING", Font = Enum.Font.GothamBlack, Max = 52 })
	text(f, { Position = px(20, 210), Size = px(520, 90), Text = "HOLLIS COUNTY · UNTIL 6 AM\nAVOID ALL TRAVEL", Font = Enum.Font.GothamBold, Max = 30 })
	return f
end

function TVScreens.build(gui: SurfaceGui, clock: (() -> string)?)
	clock = clock or function()
		return ""
	end
	local root = new("Frame", { Name = "Screens", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, ClipsDescendants = true }, gui)
	local current: string? = nil
	local token = 0
	local frames = {}
	local animators = {}
	frames.News, animators.News = buildNews(root, clock :: () -> string)
	frames.Weather = buildWeather(root)
	frames.Movie, animators.Movie = buildMovie(root)
	frames.Static = buildStatic(root)
	frames.Alert = buildAlert(root)
	for _, fr in frames do
		fr.Visible = false
	end
	root.Visible = false
	local screens = {}
	function screens.show(kind: string)
		token += 1
		local mine = token
		current = kind
		root.Visible = true
		for k, fr in frames do
			fr.Visible = k == kind
		end
		local anim = animators[kind]
		if anim then
			anim(function()
				return token == mine and current == kind and root.Parent ~= nil
			end)
		end
	end
	function screens.off()
		token += 1
		current = nil
		root.Visible = false
	end
	function screens.current(): string?
		return current
	end
	return screens
end

return TVScreens
