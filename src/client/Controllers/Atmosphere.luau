--[[
	Atmosphere — the storm, on the client: rain volumes around (never inside) the house,
	rain/wind loops that muffle indoors, and lightning with delayed thunder.
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Atmosphere = {}
local ctx

local rainSound: Sound?
local rainWindow: Sound?
local windSound: Sound?
local muffle: EqualizerSoundEffect
local flash: ColorCorrectionEffect

-- rain volumes: {x0, x1, z0, z1} (the house footprint and Mrs. Okafor's house are left out)
local VOLUMES = {
	{ -150, 180, -150, -32 },
	{ -150, 180, 32, 110 },
	{ -150, -42, -32, 32 },
	{ 68, 93, -32, 32 },
	{ 132, 180, -32, 32 },
	{ 93, 132, 2, 32 },
}

-- the lobby sits at z ~400, far from the house: rain over all of it
local LOBBY_VOLUMES = {
	{ -130, 130, 270, 530 },
}

local function buildRain()
	-- phones get a lighter storm
	local density = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and 0.45 or 1
	local folder = Instance.new("Folder")
	folder.Name = "ClientRain"
	folder.Parent = workspace
	for _, v in (ctx.Mode == "Lobby" and LOBBY_VOLUMES or VOLUMES) do
		local sizeX, sizeZ = v[2] - v[1], v[4] - v[3]
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.new(sizeX, 1, sizeZ)
		p.CFrame = CFrame.new((v[1] + v[2]) / 2, 60, (v[3] + v[4]) / 2)
		p.Parent = folder
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(170, 185, 205))
		e.LightEmission = 0.1
		e.LightInfluence = 0.6
		e.Transparency = NumberSequence.new(0.55)
		e.Size = NumberSequence.new(0.18)
		e.Squash = NumberSequence.new(3)
		e.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
		e.EmissionDirection = Enum.NormalId.Bottom
		e.Speed = NumberRange.new(95, 110)
		e.Lifetime = NumberRange.new(0.6, 0.65)
		e.SpreadAngle = Vector2.new(4, 4)
		e.Rate = math.clamp(sizeX * sizeZ / 18, 150, 900) * density
		e.Parent = p
	end
end

-- the lighting the flash returns to (whatever the server set for this mode)
local base = { Ambient = nil :: Color3?, Brightness = 0.4 }

local THUNDER = { "Thunder", "Thunder2", "Thunder3" }

local function thunder(delay: number, intensity: number)
	task.delay(delay, function()
		-- a close crack, loud; the bigger the flash the louder it is
		local s = ctx.Effects.localSound(THUNDER[math.random(1, #THUNDER)])
		if s then
			local inside = ctx.Rooms.isInside(workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or Vector3.zero)
			s.Volume = math.clamp(0.7 + intensity * 0.6, 0.8, 1.8) * (inside and 0.75 or 1)
			s.PlaybackSpeed = 0.9 + math.random() * 0.2
			s:Play()
			game:GetService("Debris"):AddItem(s, 14)
		end
		if ctx.HUD then
			ctx.HUD.caption("[Thunder]")
		end
	end)
end

-- ground mist: big, faint smoke puffs drifting low around the camera when outdoors
local mist: ParticleEmitter
local mistPart: BasePart
local splashPart: Part
local splash: ParticleEmitter
local splashParams = RaycastParams.new()
splashParams.FilterType = Enum.RaycastFilterType.Exclude

local function buildMist()
	mistPart = Instance.new("Part")
	mistPart.Name = "ClientMist"
	mistPart.Anchored = true
	mistPart.CanCollide = false
	mistPart.CanQuery = false
	mistPart.CanTouch = false
	mistPart.Transparency = 1
	mistPart.Size = Vector3.new(140, 1, 140)
	mistPart.Parent = workspace
	mist = Instance.new("ParticleEmitter")
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(Color3.fromRGB(150, 158, 172))
	mist.LightEmission = 0
	mist.LightInfluence = 0.4
	mist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.82),
		NumberSequenceKeypoint.new(0.7, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	})
	mist.Size = NumberSequence.new(18, 26)
	mist.Lifetime = NumberRange.new(10, 14)
	mist.Speed = NumberRange.new(0.5, 1.5)
	mist.SpreadAngle = Vector2.new(180, 10)
	mist.EmissionDirection = Enum.NormalId.Top
	mist.Rotation = NumberRange.new(0, 360)
	mist.RotSpeed = NumberRange.new(-4, 4)
	mist.Rate = UserInputService.TouchEnabled and 5 or 9
	mist.Parent = mistPart

	-- raindrops splashing on the ground around you (placed on the ground under the camera)
	splashPart = Instance.new("Part")
	splashPart.Name = "ClientSplashes"
	splashPart.Anchored = true
	splashPart.CanCollide = false
	splashPart.CanQuery = false
	splashPart.CanTouch = false
	splashPart.Transparency = 1
	splashPart.Size = Vector3.new(50, 0.2, 50)
	splashPart.Parent = workspace
	splash = Instance.new("ParticleEmitter")
	splash.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	splash.Color = ColorSequence.new(Color3.fromRGB(200, 212, 228))
	splash.LightInfluence = 0.7
	splash.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	splash.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.05) })
	splash.Lifetime = NumberRange.new(0.15, 0.25)
	splash.Speed = NumberRange.new(2, 4)
	splash.SpreadAngle = Vector2.new(60, 60)
	splash.Acceleration = Vector3.new(0, -30, 0)
	splash.EmissionDirection = Enum.NormalId.Top
	splash.Rate = UserInputService.TouchEnabled and 70 or 160
	splash.Parent = splashPart
end

function Atmosphere.lightning(intensity: number, thunderDelay: number)
	if intensity <= 0 then
		return
	end
	task.spawn(function()
		for _ = 1, math.random(1, 3) do
			flash.Brightness = 0.35 * intensity
			Lighting.OutdoorAmbient = Color3.fromRGB(190, 200, 230)
			Lighting.Brightness = 3
			task.wait(0.05 + math.random() * 0.06)
			flash.Brightness = 0.05
			Lighting.OutdoorAmbient = base.Ambient :: Color3
			Lighting.Brightness = base.Brightness
			task.wait(0.06 + math.random() * 0.12)
		end
		ctx.UI.tween(flash, 0.8, { Brightness = 0 })
	end)
	thunder(thunderDelay, intensity)
end

function Atmosphere.init(c)
	ctx = c
	ctx.Atmosphere = Atmosphere
end

function Atmosphere.start()
	buildRain()
	buildMist()
	flash = Instance.new("ColorCorrectionEffect")
	flash.Name = "Lightning"
	flash.Parent = Lighting
	-- Inside the lit house everything turns warm and golden (the storm outside stays cold and
	-- blue). The warmth drains away in the basement, the attic, and when the power dies.
	local warmth = Instance.new("ColorCorrectionEffect")
	warmth.Name = "Warmth"
	warmth.Parent = Lighting
	local baseAmbient = Lighting.Ambient
	local WARM_AMBIENT = Color3.fromRGB(40, 30, 22)
	local warmOn: boolean? = nil
	-- soft piano while the evening is still just an evening: indoors, first act, lights on
	-- his music: a driving chase track while he is chasing someone nearby, low dread while he
	-- is searching close by. Volumes follow how close he is to you.
	local chase = ctx.Effects.localSound("ChaseMusic")
	local dread = ctx.Effects.localSound("TensionMusic")
	local chaseVol, dreadVol = 0, 0
	for _, s in { chase, dread } do
		if s then
			s.Volume = 0
			s:Play()
		end
	end
	-- the house settling: a creak somewhere nearby every so often once things start going wrong
	local nextCreak = os.clock() + 30
	local curtis: Model? = nil
	local lookClock = 0
	local piano = ctx.Effects.localSound("CozyPiano")
	local pianoVol = 0
	if piano then
		piano.Volume = 0
		piano:Play()
	end
	base.Ambient = Lighting.OutdoorAmbient
	base.Brightness = Lighting.Brightness

	local group = Instance.new("SoundGroup")
	group.Name = "Weather"
	group.Parent = SoundService
	muffle = Instance.new("EqualizerSoundEffect")
	muffle.HighGain = 0
	muffle.MidGain = 0
	muffle.LowGain = 0
	muffle.Parent = group
	rainSound = ctx.Effects.localSound("Rain")
	rainWindow = ctx.Effects.localSound("RainWindow")
	windSound = ctx.Effects.localSound("Wind")
	for _, s in { rainSound, rainWindow, windSound } do
		if s then
			s.Looped = true
			s.SoundGroup = group
			s:Play()
		end
	end

	ctx.Remotes.Lightning.OnClientEvent:Connect(Atmosphere.lightning)
	-- the lobby has no director: the storm runs itself there (with a music box in the rain)
	if ctx.Mode == "Lobby" then
		local music = ctx.Effects.localSound("LobbyMusic")
		if music then
			music:Play()
		end
		task.spawn(function()
			task.wait(6)
			while true do
				Atmosphere.lightning(0.6 + math.random() * 0.6, 0.6 + math.random() * 2.4)
				task.wait(22 + math.random() * 30)
			end
		end)
	end

	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local inside = ctx.Mode ~= "Lobby" and ctx.Rooms.isInside(cam.CFrame.Position)
		-- indoors the storm is muffled, but you still hear it drumming on the windows
		muffle.HighGain = inside and -14 or 0
		muffle.MidGain = inside and -5 or 0
		if rainSound then
			rainSound.Volume = inside and 0.45 or 0.85
		end
		if rainWindow then
			rainWindow.Volume = inside and 0.55 or 0
		end
		if windSound then
			windSound.Volume = inside and 0.1 or 0.25
		end
		-- warm indoors (ground floor and upstairs) while the lights are on
		local floor = inside and ctx.Rooms.floorOf(cam.CFrame.Position)
		local cozy = inside and workspace:GetAttribute("Power") ~= false and (floor == "Ground" or floor == "Upstairs")
		if cozy ~= warmOn then
			warmOn = cozy
			ctx.UI.tween(warmth, 1.2, cozy and {
				TintColor = Color3.fromRGB(255, 230, 200),
				Saturation = 0.22,
				Contrast = 0.03,
				Brightness = 0.03,
			} or {
				TintColor = Color3.new(1, 1, 1),
				Saturation = 0,
				Contrast = 0,
				Brightness = 0,
			})
			ctx.UI.tween(Lighting, 1.2, { Ambient = cozy and WARM_AMBIENT or baseAmbient })
		end
		if chase and dread and ctx.Mode ~= "Lobby" then
			lookClock -= 0.25
			if (not curtis or not curtis.Parent) and lookClock <= 0 then
				lookClock = 2
				local found = ctx.Util.creature()
				curtis = found and found:IsA("Model") and found or nil
			end
			local state = workspace:GetAttribute("IntruderState")
			local dist = math.huge
			if curtis and curtis.Parent then
				dist = (curtis:GetPivot().Position - cam.CFrame.Position).Magnitude
			end
			local inNight = game:GetService("Players").LocalPlayer:GetAttribute("InGame") == true
			local chasing = inNight and state == "Chase" and dist < 140
			local hunting = inNight and (state == "Prowl" or state == "Search" or state == "CheckSpot" or state == "Patrol" or state == "Investigate") and dist < 80
			local wantChase = chasing and math.clamp(1.2 - dist / 140, 0.35, 1) * 0.5 or 0
			local wantDread = (hunting and not chasing) and math.clamp(1 - dist / 70, 0.2, 1) * 0.3 or 0
			-- the chase slams in; everything else eases
			chaseVol += math.clamp(wantChase - chaseVol, -0.04, 0.25)
			dreadVol += math.clamp(wantDread - dreadVol, -0.03, 0.03)
			chase.Volume = chaseVol
			dread.Volume = dreadVol
		end
		local act = workspace:GetAttribute("Act")
		if inside and (act == "SmallThings" or act == "SomeoneElse" or act == "Guest") and os.clock() > nextCreak then
			nextCreak = os.clock() + 20 + math.random() * 30
			local a = math.random() * math.pi * 2
			local r = 12 + math.random() * 16
			local p = cam.CFrame.Position + Vector3.new(math.cos(a) * r, (math.random() < 0.4) and 9 or -2, math.sin(a) * r)
			ctx.Effects.playSound(math.random() < 0.7 and "Floorboard" or "HatchCreak", p, { Caption = false, Volume = 0.35 + math.random() * 0.25 })
		end
		if piano then
			local want = (cozy and workspace:GetAttribute("Act") == "Evening" and not workspace:GetAttribute("Delivery")) and 0.22 or 0
			pianoVol += math.clamp(want - pianoVol, -0.03, 0.02)
			piano.Volume = pianoVol
		end
		-- the ground mist follows the camera outdoors only
		mistPart.CFrame = CFrame.new(cam.CFrame.Position.X, (inside and -500 or cam.CFrame.Position.Y - 4), cam.CFrame.Position.Z)
		mist.Enabled = not inside
		-- splashes on whatever ground is under the camera
		if splash then
			local ignore: { Instance } = { splashPart, mistPart }
			local character = game:GetService("Players").LocalPlayer.Character
			if character then
				table.insert(ignore, character)
			end
			splashParams.FilterDescendantsInstances = ignore
			local hit = if inside then nil else workspace:Raycast(cam.CFrame.Position, Vector3.new(0, -120, 0), splashParams)
			splash.Enabled = hit ~= nil
			if hit then
				splashPart.CFrame = CFrame.new(cam.CFrame.Position.X, hit.Position.Y + 0.15, cam.CFrame.Position.Z)
			end
		end
	end)
end

return Atmosphere
