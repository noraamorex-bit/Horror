--[[
	Effects — how fear feels: nerve vignette, desaturation, camera tremor and heartbeat; screen
	shake and fades; local-only sounds; the figure at the window.
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
		-- (Length: only the first part of a long file, faded out at the end)
		local def = ctx.Sounds.get(name)
		local len = opts.Length or (def and def.Length)
		if len then
			task.delay(len, function()
				if s.Parent then
					ctx.UI.tween(s, 0.15, { Volume = 0 })
				end
			end)
		end
	elseif att then
		att:Destroy()
	end
	local def = ctx.Sounds.get(name)
	if def and def.Caption and opts.Caption ~= false and ctx.HUD then
		ctx.HUD.caption(def.Caption)
	end
end

-- a taser shot: a jagged blue bolt from the muzzle to where it landed, a flash of light there
function Effects.zap(from: Vector3, to: Vector3, hit: boolean)
	local folder = Instance.new("Folder")
	folder.Name = "Zap"
	local d = to - from
	local n = math.clamp(math.floor(d.Magnitude / 2.5), 3, 18)
	local prev = from
	local side = d.Magnitude > 0.1 and d.Unit:Cross(Vector3.yAxis) or Vector3.xAxis
	if side.Magnitude < 0.1 then
		side = Vector3.xAxis
	end
	side = side.Unit
	for i = 1, n do
		local k = i / n
		local p = from + d * k
		if i < n then
			p += side * (math.random() - 0.5) * 0.9 + Vector3.yAxis * (math.random() - 0.5) * 0.9
		end
		local seg = Instance.new("Part")
		seg.Anchored = true
		seg.CanCollide = false
		seg.CanQuery = false
		seg.CanTouch = false
		seg.CastShadow = false
		seg.Material = Enum.Material.Neon
		seg.Color = Color3.fromRGB(150, 210, 255)
		local len = (p - prev).Magnitude
		seg.Size = Vector3.new(0.12, 0.12, len)
		seg.CFrame = CFrame.lookAt((prev + p) / 2, p)
		seg.Parent = folder
		prev = p
	end
	local glow = Instance.new("Part")
	glow.Anchored = true
	glow.CanCollide = false
	glow.CanQuery = false
	glow.Transparency = 1
	glow.Size = Vector3.one * 0.2
	glow.Position = to
	glow.Parent = folder
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(150, 210, 255)
	light.Range = hit and 22 or 12
	light.Brightness = hit and 6 or 3
	light.Parent = glow
	folder.Parent = workspace
	for _, c in folder:GetChildren() do
		if c:IsA("BasePart") and c ~= glow then
			ctx.UI.tween(c, 0.22, { Transparency = 1 })
		end
	end
	ctx.UI.tween(light, 0.3, { Brightness = 0 })
	Debris:AddItem(folder, 0.4)
end

local function fxPart(parent: Instance, size: Vector3, color: Color3, mat: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

-- a rocket in flight: a red-tipped rocket with a smoke trail and a glow, from the tube to where it
-- goes off (the server makes the explosion itself, which everyone sees)
function Effects.rocket(from: Vector3, to: Vector3, seconds: number)
	local folder = Instance.new("Folder")
	folder.Name = "RocketFx"
	local body = fxPart(folder, Vector3.new(0.45, 0.45, 1.6), Color3.fromRGB(215, 215, 220))
	local tip = fxPart(folder, Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(200, 40, 30))
	local flame = fxPart(folder, Vector3.new(0.35, 0.35, 0.5), Color3.fromRGB(255, 170, 60), Enum.Material.Neon)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.2, 0.8)
	a0.Parent = body
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.2, 0.8)
	a1.Parent = body
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.8
	trail.Color = ColorSequence.new(Color3.fromRGB(230, 225, 215))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.WidthScale = NumberSequence.new(1, 3)
	trail.Parent = body
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 160, 70)
	light.Range = 14
	light.Brightness = 4
	light.Parent = flame
	folder.Parent = workspace
	local dir = (to - from)
	local look = dir.Magnitude > 0.01 and dir.Unit or Vector3.zAxis
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local k = seconds > 0 and math.clamp((os.clock() - t0) / seconds, 0, 1) or 1
		local p = from + dir * k
		local cf = CFrame.lookAt(p, p + look)
		body.CFrame = cf
		tip.CFrame = cf * CFrame.new(0, 0, -1)
		flame.CFrame = cf * CFrame.new(0, 0, 1.05)
		if k >= 1 then
			conn:Disconnect()
			body.Transparency, tip.Transparency, flame.Transparency = 1, 1, 1
			light.Range = 30
			light.Brightness = 8
			ctx.UI.tween(light, 0.6, { Brightness = 0 })
			Debris:AddItem(folder, 1)
		end
	end)
end

-- a firecracker: a red stick arcs to where it lands, fizzes with sparks, then a burst of light
function Effects.firecracker(from: Vector3, to: Vector3, fuse: number)
	local folder = Instance.new("Folder")
	folder.Name = "FirecrackerFx"
	local stick = fxPart(folder, Vector3.new(0.25, 0.25, 0.9), Color3.fromRGB(200, 30, 30))
	local spark = Instance.new("Sparkles")
	spark.SparkleColor = Color3.fromRGB(255, 210, 120)
	spark.Parent = stick
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 120)
	light.Range = 8
	light.Brightness = 2
	light.Parent = stick
	folder.Parent = workspace
	local flight = math.min(0.7, fuse * 0.6)
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local k = math.clamp(t / flight, 0, 1)
		local p = from:Lerp(to, k) + Vector3.new(0, math.sin(k * math.pi) * 3, 0)
		stick.CFrame = CFrame.new(p) * CFrame.Angles(t * 9, t * 5, 0)
		light.Brightness = 1.5 + math.random() * 1.5
		if t >= fuse then
			conn:Disconnect()
			spark.Enabled = false
			stick.Transparency = 1
			light.Range = 26
			light.Brightness = 7
			light.Color = Color3.fromRGB(255, 240, 200)
			ctx.UI.tween(light, 0.5, { Brightness = 0 })
			Debris:AddItem(folder, 0.8)
		end
	end)
end

-- pepper spray: a cone of orange-tinted mist puffing out in front of you
function Effects.spray(from: Vector3, dir: Vector3)
	local folder = Instance.new("Folder")
	folder.Name = "SprayFx"
	folder.Parent = workspace
	for k = 1, 9 do
		local puff = fxPart(folder, Vector3.one * 0.6, Color3.fromRGB(245, 200, 150), Enum.Material.SmoothPlastic)
		puff.Shape = Enum.PartType.Ball
		puff.Transparency = 0.45
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local to = from + dir * (6 + k * 1.1) + side * (math.random() - 0.5) * k * 0.6 + Vector3.new(0, (math.random() - 0.5) * 1.2, 0)
		puff.Position = from + dir * 1.2
		local t = 0.35 + k * 0.04
		ctx.UI.tween(puff, t, { Position = to, Size = Vector3.one * (1.6 + k * 0.35) })
		task.delay(t * 0.5, function()
			if puff.Parent then
				ctx.UI.tween(puff, 0.6, { Transparency = 1 })
			end
		end)
	end
	Debris:AddItem(folder, 1.6)
end

function Effects.fade(toBlack: boolean, duration: number)
	ctx.UI.tween(fadeFrame, duration or 0.5, { BackgroundTransparency = toBlack and 0 or 1 })
end

-- he got you: the camera snaps onto his face, a scream hit, a red flash, then the capture fade
local scaring = false
function Effects.jumpscare(head: BasePart?)
	if scaring or not head or not head.Parent then
		return
	end
	scaring = true
	local cam = workspace.CurrentCamera
	local oldType, oldFov = cam.CameraType, cam.FieldOfView
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = 48
	-- the scream, a low hit under it, and your own gasp
	for _, name in { "Jumpscare", "HorrorHitLow", "Gasp" } do
		local s = localSound(name)
		if s then
			s:Play()
			game:GetService("Debris"):AddItem(s, 14)
		end
	end
	local flash = Instance.new("ColorCorrectionEffect")
	flash.TintColor = Color3.fromRGB(255, 120, 110)
	flash.Contrast = 0.4
	flash.Brightness = 0.12
	flash.Parent = Lighting
	ctx.UI.tween(flash, 0.9, { TintColor = Color3.new(1, 1, 1), Contrast = 0, Brightness = 0 })
	Effects.shake(1.4, 0.9)
	local t0 = os.clock()
	while os.clock() - t0 < 0.85 and head.Parent do
		-- right in front of his face, lunging a little closer
		local k = (os.clock() - t0) / 0.85
		local hcf = head.CFrame
		cam.CFrame = CFrame.lookAt(hcf.Position + hcf.LookVector * (2.6 - k * 0.9) + Vector3.new(0, 0.1, 0), hcf.Position)
		task.wait()
	end
	flash:Destroy()
	cam.FieldOfView = oldFov
	cam.CameraType = oldType
	scaring = false
end

function Effects.shake(mag: number, duration: number)
	if ctx.Settings and not ctx.Settings.shakeOn() then
		return
	end
	shakeMag = math.max(shakeMag, mag)
	shakeUntil = math.max(shakeUntil, os.clock() + duration)
end

-- a figure only you can see (built locally, gone in a moment)
function Effects.figure(cf: CFrame, duration: number)
	-- him: a still copy of the real thing, frozen mid-stare (the old block man if he isn't loaded)
	local real = ctx.Util.creature()
	if real and real:IsA("Model") and real:GetAttribute("Creature") then
		local ok, copy = pcall(function()
			return real:Clone()
		end)
		if ok and copy then
			for _, d in copy:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CanQuery = false
				elseif d:IsA("Sound") or d:IsA("Humanoid") then
					d:Destroy()
				end
			end
			copy.Name = "Figure"
			copy:SetAttribute("Creature", nil)
			game:GetService("CollectionService"):RemoveTag(copy, "Creature")
			copy:PivotTo(cf * CFrame.new(0, 2.3, 0))
			copy.Parent = workspace
			task.delay(duration, function()
				copy:Destroy()
			end)
			return
		end
	end
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
	-- (no breathing loop of your own: the only licensed clip was a man grunting and coughing, which
	-- came across as somebody coughing and saying "hello" every few seconds. The heartbeat carries it.)

	ctx.Remotes.Fade.OnClientEvent:Connect(Effects.fade)
	ctx.Remotes.Shake.OnClientEvent:Connect(Effects.shake)
	ctx.Remotes.Jumpscare.OnClientEvent:Connect(function(head)
		task.spawn(Effects.jumpscare, head)
	end)
	ctx.Remotes.Figure.OnClientEvent:Connect(Effects.figure)
	ctx.Remotes.PlaySound.OnClientEvent:Connect(Effects.playSound)
	ctx.Remotes.Zap.OnClientEvent:Connect(function(from, to, hit)
		if typeof(from) == "Vector3" and typeof(to) == "Vector3" then
			Effects.zap(from, to, hit == true)
		end
	end)
	ctx.Remotes.Rocket.OnClientEvent:Connect(function(from, to, seconds, hit, shooter)
		if typeof(from) == "Vector3" and typeof(to) == "Vector3" then
			Effects.rocket(from, to, tonumber(seconds) or 0.5)
		elseif hit == true and type(shooter) == "string" and ctx.Offers and ctx.Offers.rocketHit then
			-- someone knocked him flat: everyone hears about it (and can get one)
			ctx.Offers.rocketHit(shooter)
		end
	end)
	ctx.Remotes.SprayFx.OnClientEvent:Connect(function(from, dir)
		if typeof(from) == "Vector3" and typeof(dir) == "Vector3" and dir.Magnitude > 0.1 then
			Effects.spray(from, dir.Unit)
		end
	end)
	ctx.Remotes.Throw.OnClientEvent:Connect(function(from, to, fuse)
		if typeof(from) == "Vector3" and typeof(to) == "Vector3" then
			Effects.firecracker(from, to, tonumber(fuse) or 1.4)
		end
	end)
	-- shoved off your feet: fall, slide back a little, get up
	ctx.Remotes.Knockdown.OnClientEvent:Connect(function(dir: Vector3)
		local char = game:GetService("Players").LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hum or not root or typeof(dir) ~= "Vector3" then
			return
		end
		hum:ChangeState(Enum.HumanoidStateType.FallingDown)
		root.AssemblyLinearVelocity = dir * 26 + Vector3.new(0, 10, 0)
		task.delay(1.2, function()
			if hum.Parent and hum:GetState() == Enum.HumanoidStateType.FallingDown then
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)
	end)

	-- his footsteps through the floor: each step jolts the screen, harder the closer he is (and
	-- harder still when he's running). You can feel where he is before you see him.
	local curtis: Model? = nil
	local stepClock = 0
	local findClock = 0
	RunService.Heartbeat:Connect(function(dt)
		if not player:GetAttribute("InGame") then
			return
		end
		findClock -= dt
		if (not curtis or not curtis.Parent) and findClock <= 0 then
			findClock = 2
			curtis = workspace:FindFirstChild("Curtis", true) :: Model?
		end
		local root = curtis and curtis:FindFirstChild("HumanoidRootPart") :: BasePart?
		local cam = workspace.CurrentCamera
		if not root or not cam then
			return
		end
		local v = root.AssemblyLinearVelocity
		local speed = Vector3.new(v.X, 0, v.Z).Magnitude
		if speed < 2 then
			stepClock = 0
			return
		end
		local running = speed > 12
		stepClock += dt
		local interval = running and math.max(3.75 / speed, 0.18) or math.max(2.6 / speed, 0.3)
		if stepClock < interval then
			return
		end
		stepClock = 0
		local d = (root.Position - cam.CFrame.Position).Magnitude
		local k = math.clamp(1 - d / 45, 0, 1)
		if k > 0 then
			Effects.shake((running and 0.5 or 0.28) * k * k, 0.14)
		end
	end)

	RunService:BindToRenderStep("HomeAloneEffects", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local nerve = player:GetAttribute("Nerve") or 100
		local fear = 1 - nerve / 100
		local inGame = player:GetAttribute("InGame") == true
		if not inGame then
			fear = 0
		end
		setVignette(0.15 + fear * 0.45) -- (it used to close to 0.85: half a phone screen black at low nerve)
		grade.Saturation = -fear * 0.5
		grade.Contrast = fear * 0.15

		-- heartbeat below Heavy
		local heavy = ctx.Config.Nerve.Heavy
		if heartbeat then
			local want = inGame and nerve < heavy
			if want then
				heartbeat.Looped = true
				-- 96 bpm at the edge of panic, up to ~150 at the bottom
				heartbeat.PlaybackSpeed = 1 + (1 - nerve / heavy) * 0.6
				heartbeat.Volume = 0.25 + fear * 0.5
				if not heartbeat.IsPlaying then
					heartbeat:Play()
				end
			elseif heartbeat.IsPlaying then
				heartbeat:Stop()
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
		if mag > 0.001 and (not ctx.Settings or ctx.Settings.shakeOn()) then
			local rx = math.noise(t * 7, 0, 0) * mag * 0.05
			local ry = math.noise(0, t * 7, 0) * mag * 0.05
			cam.CFrame = cam.CFrame * CFrame.Angles(rx, ry, 0)
		end
	end)
end

return Effects
