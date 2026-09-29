--[[
	Effects — how fear feels: nerve vignette, desaturation, camera tremor, heartbeat and
	breathing; screen shake and fades; local-only sounds; the figure at the window.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local Effects = {}
local ctx
local player = Players.LocalPlayer

local vignette = {}
local fadeFrame: Frame
local grade: ColorCorrectionEffect
local shakeMag, shakeUntil = 0, 0
local heartbeat: Sound?
local breathing: Sound?

local function localSound(name: string, parent: Instance?): Sound?
	local def = ctx.Sounds.get(name)
	local id = ctx.Sounds.resolve(name)
	if not def or not id then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Volume = def.Volume or 0.5
	s.PlaybackSpeed = def.Pitch or 1
	s.Looped = def.Looped or false
	s.Parent = parent or SoundService
	return s
end
Effects.localSound = localSound

function Effects.playSound(name: string, position: Vector3?, opts)
	opts = opts or {}
	local parent: Instance = SoundService
	local att
	if position then
		att = Instance.new("Attachment")
		att.Position = position
		att.Parent = workspace.Terrain
		parent = att
	end
	local s = localSound(name, parent)
	if s then
		if opts.Volume then
			s.Volume = opts.Volume
		end
		s:Play()
		Debris:AddItem(att or s, 10)
	elseif att then
		att:Destroy()
	end
	local def = ctx.Sounds.get(name)
	if def and def.Caption and opts.Caption ~= false and ctx.HUD then
		ctx.HUD.caption(def.Caption)
	end
end

function Effects.fade(toBlack: boolean, duration: number)
	ctx.UI.tween(fadeFrame, duration or 0.5, { BackgroundTransparency = toBlack and 0 or 1 })
end

function Effects.shake(mag: number, duration: number)
	shakeMag = math.max(shakeMag, mag)
	shakeUntil = math.max(shakeUntil, os.clock() + duration)
end

-- a figure only you can see (built locally, gone in a moment)
function Effects.figure(cf: CFrame, duration: number)
	local model = Instance.new("Model")
	model.Name = "Figure"
	local dark = Color3.fromRGB(18, 18, 20)
	local function part(size, offset)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CastShadow = false
		p.Color = dark
		p.Material = Enum.Material.SmoothPlastic
		p.Size = size
		p.CFrame = cf * offset
		p.Parent = model
		return p
	end
	part(Vector3.new(2.2, 2.4, 1.1), CFrame.new(0, 1.2, 0))
	part(Vector3.new(1.3, 1.3, 1.3), CFrame.new(0, 3.1, 0))
	part(Vector3.new(0.9, 2.4, 0.9), CFrame.new(-1.55, 1, 0))
	part(Vector3.new(0.9, 2.4, 0.9), CFrame.new(1.55, 1, 0))
	part(Vector3.new(0.95, 2.6, 1), CFrame.new(-0.55, -1.3, 0))
	part(Vector3.new(0.95, 2.6, 1), CFrame.new(0.55, -1.3, 0))
	model.Parent = workspace
	task.delay(duration, function()
		model:Destroy()
	end)
end

local function buildVignette()
	local UI = ctx.UI
	local holder = UI.new("Frame", { Name = "Vignette", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = ctx.UI.Root, ZIndex = 0 })
	local sides = {
		{ UDim2.new(1, 0, 0.35, 0), UDim2.fromScale(0, 0), 90 },
		{ UDim2.new(1, 0, 0.35, 0), UDim2.fromScale(0, 0.65), -90 },
		{ UDim2.new(0.3, 0, 1, 0), UDim2.fromScale(0, 0), 0 },
		{ UDim2.new(0.3, 0, 1, 0), UDim2.fromScale(0.7, 0), 180 },
	}
	for _, s in sides do
		local f = UI.new("Frame", { Size = s[1], Position = s[2], BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0, Parent = holder })
		local g = UI.new("UIGradient", {
			Rotation = s[3],
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			Parent = f,
		})
		table.insert(vignette, { Frame = f, Gradient = g })
	end
end

local function setVignette(strength: number)
	for _, v in vignette do
		v.Frame.BackgroundTransparency = 1 - math.clamp(strength, 0, 0.95)
	end
end

function Effects.init(c)
	ctx = c
	ctx.Effects = Effects
end

function Effects.start()
	buildVignette()
	fadeFrame = ctx.UI.new("Frame", { Name = "Fade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Parent = ctx.UI.Top })
	grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "Nerve"
	grade.Parent = Lighting

	heartbeat = localSound("Heartbeat")
	breathing = localSound("Breathing")
	if breathing then
		breathing.Looped = true
	end

	ctx.Remotes.Fade.OnClientEvent:Connect(Effects.fade)
	ctx.Remotes.Shake.OnClientEvent:Connect(Effects.shake)
	ctx.Remotes.Figure.OnClientEvent:Connect(Effects.figure)
	ctx.Remotes.PlaySound.OnClientEvent:Connect(Effects.playSound)

	local beatClock = 0
	RunService:BindToRenderStep("HomeAloneEffects", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local nerve = player:GetAttribute("Nerve") or 100
		local fear = 1 - nerve / 100
		local inGame = player:GetAttribute("InGame") == true
		if not inGame then
			fear = 0
		end
		setVignette(0.15 + fear * 0.7)
		grade.Saturation = -fear * 0.5
		grade.Contrast = fear * 0.15

		-- heartbeat below Heavy
		local heavy = ctx.Config.Nerve.Heavy
		if inGame and nerve < heavy and heartbeat then
			beatClock += dt
			local interval = 0.45 + (nerve / heavy) * 0.6
			if beatClock >= interval then
				beatClock = 0
				heartbeat.Volume = 0.3 + fear * 0.5
				heartbeat:Play()
			end
		end
		if breathing then
			local want = inGame and nerve < heavy and not player:GetAttribute("HoldingBreath")
			if want and not breathing.IsPlaying then
				breathing:Play()
			elseif not want and breathing.IsPlaying then
				breathing:Stop()
			end
		end

		-- tremor + shake
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local t = os.clock()
		local mag = 0
		if inGame and nerve < heavy then
			mag += (1 - nerve / heavy) * 0.25
		end
		if t < shakeUntil then
			mag += shakeMag * ((shakeUntil - t) / 0.6)
		else
			shakeMag = 0
		end
		if mag > 0.001 then
			local rx = math.noise(t * 7, 0, 0) * mag * 0.05
			local ry = math.noise(0, t * 7, 0) * mag * 0.05
			cam.CFrame = cam.CFrame * CFrame.Angles(rx, ry, 0)
		end
	end)
end

return Effects
