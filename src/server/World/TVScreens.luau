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

--[[
	A presenter, in a ViewportFrame on the screen: a blocky person (like everyone in Hollis Creek)
	from the chest up, behind a desk or standing. The parts the client animates while the voice
	speaks (client TVVoice): "Mouth" (opens and closes), "Head" (a slight nod), "Lids" (blinks).
]]
local function presenter(parent: Instance, pos: UDim2, size: UDim2, look)
	local vp = new("ViewportFrame", {
		Name = "Presenter",
		Position = pos,
		Size = size,
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(170, 170, 180),
		LightColor = Color3.fromRGB(255, 248, 235),
		LightDirection = Vector3.new(-0.4, -0.6, -1),
	}, parent)
	local world = new("WorldModel", {}, vp)
	local model = new("Model", { Name = "Anchor" }, world)
	local function part(name: string, size_: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?)
		return new("Part", { Name = name, Size = size_, CFrame = cf, Color = color, Material = mat or Enum.Material.SmoothPlastic, Anchored = true, CanCollide = false, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth }, model)
	end
	local C = CFrame.new
	part("Torso", Vector3.new(2.1, 2, 1.05), C(0, 0, 0), look.Suit)
	part("ArmL", Vector3.new(0.95, 2, 1), C(-1.55, 0, 0), look.Suit)
	part("ArmR", Vector3.new(0.95, 2, 1), C(1.55, 0, 0), look.Suit)
	part("Shirt", Vector3.new(0.7, 1.2, 0.06), C(0, 0.35, -0.53), look.Shirt)
	if look.Tie then
		part("Tie", Vector3.new(0.22, 1.1, 0.07), C(0, 0.3, -0.57), look.Tie)
	end
	local head = part("Head", Vector3.new(1.25, 1.25, 1.25), C(0, 1.65, 0), look.Skin)
	new("SpecialMesh", { MeshType = Enum.MeshType.Head, Scale = Vector3.new(1, 1, 1) }, head)
	part("Neck", Vector3.new(0.6, 0.3, 0.6), C(0, 1.05, 0), look.Skin)
	part("Hair", Vector3.new(1.32, 0.42, 1.32), C(0, 2.2, 0.04), look.Hair)
	if look.LongHair then
		part("HairBack", Vector3.new(1.34, 1.5, 0.35), C(0, 1.55, 0.5), look.Hair)
		for _, x in { -0.66, 0.66 } do
			part("HairSide", Vector3.new(0.16, 1.35, 1.1), C(x, 1.6, 0.06), look.Hair)
		end
	end
	local eyeY = 1.8
	for _, x in { -0.24, 0.24 } do
		part("Eye", Vector3.new(0.16, 0.2, 0.05), C(x, eyeY, -0.63), Color3.fromRGB(20, 20, 22))
	end
	local lids = part("Lids", Vector3.new(0.7, 0.22, 0.05), C(0, eyeY, -0.64), look.Skin)
	lids.Transparency = 1
	part("Brow", Vector3.new(0.7, 0.06, 0.05), C(0, eyeY + 0.2, -0.635), look.Hair)
	local mouth = part("Mouth", Vector3.new(0.38, 0.06, 0.05), C(0, 1.42, -0.635), Color3.fromRGB(70, 30, 30))
	mouth:SetAttribute("Base", 1.42)
	if look.Desk then
		part("Desk", Vector3.new(7, 1.2, 1.6), C(0, -0.7, -1.2), look.Desk, Enum.Material.SmoothPlastic)
		part("DeskTrim", Vector3.new(7, 0.12, 1.62), C(0, -0.08, -1.2), look.Trim, Enum.Material.Neon)
	end
	model.PrimaryPart = head
	local cam = new("Camera", { FieldOfView = 26, CFrame = CFrame.lookAt(Vector3.new(look.CamX or 0, 1.0, -9.5), Vector3.new(look.CamX or 0, 0.9, 0)) }, vp)
	vp.CurrentCamera = cam
	return vp
end

local ANCHOR = { Suit = Color3.fromRGB(32, 38, 58), Shirt = Color3.fromRGB(236, 236, 240), Tie = Color3.fromRGB(170, 24, 30), Skin = Color3.fromRGB(226, 186, 150), Hair = Color3.fromRGB(70, 52, 40), Desk = Color3.fromRGB(18, 26, 52), Trim = Color3.fromRGB(196, 22, 28), CamX = 0 }
local WEATHER_LADY = { Suit = Color3.fromRGB(140, 30, 40), Shirt = Color3.fromRGB(30, 30, 34), Skin = Color3.fromRGB(150, 104, 76), Hair = Color3.fromRGB(28, 20, 18), LongHair = true, CamX = 0 }

-- Channel 7: the report about him
local function buildNews(root: Frame, clock: () -> string)
	local f = box(root, px(0, 0), UDim2.fromScale(1, 1), BLACK)
	new("ImageLabel", { Size = UDim2.fromScale(1, 1), Image = IMG.News, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop }, f)
	box(f, px(0, 0), UDim2.fromScale(1, 1), Color3.fromRGB(8, 14, 40), 0.35)
	-- the anchor at the desk
	presenter(f, px(0, 34), px(340, 214), ANCHOR)
	-- channel bug and LIVE
	local bug = box(f, px(14, 12), px(92, 30), RED)
	text(bug, { Size = UDim2.fromScale(1, 1), Text = "7 NEWS", Font = Enum.Font.GothamBlack, Max = 22 })
	local live = box(f, px(474, 12), px(72, 28), RED)
	text(live, { Size = UDim2.fromScale(1, 1), Text = "LIVE", Font = Enum.Font.GothamBlack, Max = 20 })
	-- over his shoulder: the suspect, a silhouette in a box
	local panel = box(f, px(356, 54), px(184, 182), Color3.fromRGB(16, 22, 40), 0.1)
	new("UIStroke", { Color = WHITE, Thickness = 2, Transparency = 0.3 }, panel)
	text(panel, { Position = px(0, 4), Size = UDim2.new(1, 0, 0, 22), Text = "SUSPECT", Font = Enum.Font.GothamBlack, Max = 18 })
	local headShape = box(panel, px(65, 34), px(54, 64), Color3.fromRGB(40, 44, 54))
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, headShape)
	local shoulders = box(panel, px(35, 94), px(114, 52), Color3.fromRGB(40, 44, 54))
	new("UICorner", { CornerRadius = UDim.new(0.35, 0) }, shoulders)
	text(headShape, { Size = UDim2.fromScale(1, 1), Text = "?", TextColor3 = Color3.fromRGB(120, 126, 140), Max = 34 })
	text(panel, { Position = px(4, 152), Size = UDim2.new(1, -8, 0, 24), Text = "MALE · 40s · 6'4\"", Font = Enum.Font.GothamMedium, Max = 16 })
	-- the name strap
	local strap = box(f, px(14, 212), px(330, 30), WHITE, 0.05)
	text(strap, { Position = px(10, 0), Size = px(310, 30), Text = "DAN WHITLOCK  ·  7 NEWS", Font = Enum.Font.GothamBold, TextColor3 = BLACK, TextXAlignment = Enum.TextXAlignment.Left, Max = 18 })
	-- BREAKING NEWS bar and the ticker under it
	local breaking = box(f, px(0, 246), px(560, 40), RED)
	text(breaking, { Position = px(14, 0), Size = px(420, 40), Text = "BREAKING: MAN SOUGHT IN BREAK-INS", Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Max = 28 })
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
	-- the weather presenter, standing at the left of the map
	presenter(f, px(-40, 40), px(260, 200), WEATHER_LADY)
	local warn = box(f, px(0, 236), px(560, 46), RED)
	text(warn, { Position = px(14, 0), Size = px(532, 46), Text = "FLASH FLOOD WARNING", Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Max = 34 })
	local sub = box(f, px(0, 282), px(560, 58), BLACK, 0.15)
	text(sub, { Position = px(14, 4), Size = px(532, 50), Text = "Hollis County until 6 AM · Creek Road closed · 4 more inches tonight", Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Max = 22 })
	return f
end

-- Channel 4: an old black-and-white film, a little too close to home. Its lines (Story.TVVoice.Movie)
-- are subtitled here and spoken by the client (TVVoice); the line on screen is the gui's "MovieLine".
local function buildMovie(root: Frame, lines: { { Text: string } })
	local SUBTITLES = {}
	for _, l in lines do
		table.insert(SUBTITLES, "\"" .. l.Text .. "\"")
	end
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
			sub.Text = SUBTITLES[1]
			f:SetAttribute("MovieLine", 1)
			while alive() do
				task.wait(5.5)
				if not alive() then
					break
				end
				i = i % #SUBTITLES + 1
				sub.Text = SUBTITLES[i]
				f:SetAttribute("MovieLine", i)
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

function TVScreens.build(gui: SurfaceGui, clock: (() -> string)?, movieLines: { { Text: string } }?)
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
	frames.Movie, animators.Movie = buildMovie(root, movieLines or { { Text = "..." } })
	frames.Movie.Name = "Movie"
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
