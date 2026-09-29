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

local function buildRain()
	-- phones get a lighter storm
	local density = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and 0.45 or 1
	local folder = Instance.new("Folder")
	folder.Name = "ClientRain"
	folder.Parent = workspace
	for _, v in VOLUMES do
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

local function thunder(delay: number, intensity: number)
	task.delay(delay, function()
		local s = ctx.Effects.localSound("Thunder")
		if s then
			s.Volume = math.clamp(intensity, 0.3, 1.2)
			s.PlaybackSpeed = 0.25 + math.random() * 0.15
			s:Play()
			game:GetService("Debris"):AddItem(s, 8)
		end
		if intensity > 1 and ctx.HUD then
			ctx.HUD.caption("[Thunder]")
		end
	end)
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
			Lighting.OutdoorAmbient = Color3.fromRGB(18, 20, 28)
			Lighting.Brightness = 0.4
			task.wait(0.06 + math.random() * 0.12)
		end
		ctx.UI.tween(flash, 0.8, { Brightness = 0 })
	end)
	thunder(thunderDelay, intensity)
end

function Atmosphere.init(c)
	ctx = c
end

function Atmosphere.start()
	buildRain()
	flash = Instance.new("ColorCorrectionEffect")
	flash.Name = "Lightning"
	flash.Parent = Lighting
	Lighting.OutdoorAmbient = Color3.fromRGB(18, 20, 28)

	local group = Instance.new("SoundGroup")
	group.Name = "Weather"
	group.Parent = SoundService
	muffle = Instance.new("EqualizerSoundEffect")
	muffle.HighGain = 0
	muffle.MidGain = 0
	muffle.LowGain = 0
	muffle.Parent = group
	rainSound = ctx.Effects.localSound("Rain")
	windSound = ctx.Effects.localSound("Wind")
	for _, s in { rainSound, windSound } do
		if s then
			s.Looped = true
			s.SoundGroup = group
			s:Play()
		end
	end

	ctx.Remotes.Lightning.OnClientEvent:Connect(Atmosphere.lightning)

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
		local inside = ctx.Rooms.isInside(cam.CFrame.Position)
		muffle.HighGain = inside and -30 or 0
		muffle.MidGain = inside and -12 or 0
		if rainSound then
			rainSound.Volume = inside and 0.25 or 0.6
		end
		if windSound then
			windSound.Volume = inside and 0.06 or 0.2
		end
	end)
end

return Atmosphere
