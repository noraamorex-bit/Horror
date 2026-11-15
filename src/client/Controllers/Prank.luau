--[[
	Prank — "😱 JUMPSCARE EVERYONE" (v115, the owner: "add something like this for 10 Robux"): a
	developer product (Config.Shop.JumpscareAll) that, the moment it's bought, jumpscares every other
	player in the server, in the house or in the lobby (ShopService fires Remotes.JumpscareAll).

	What they get (v167, the owner: "Jumpscare looks terrible i don't even see him. Make it so that he comes up to your face and
	shakes and screams"): the lights die, he's standing there in the dark in front of you, he rushes up to your face and shakes
	and screams right into the lens (Prank.scare: the beats are written out there), a hard cut to black, then a line at the bottom
	saying who did it, so they can pay them back. The buyer isn't scared (v170; v165-169 scared them too), only told "You jumpscared N players!".
	(v165-166 drew him in a ViewportFrame from a copy of whichever model of him was nearby: in the lobby only the far-off
	watcher, maybe not streamed in, and his skinned body didn't show there: the owner saw nothing. Now he's his real 3D model,
	built on this device from ReplicatedStorage.Assets.Creature, in the world right in front of your camera.)

	Where you buy it: a small 😱 button under the inventory in the house and a 😱 SCARE icon in the
	lobby's dock, both only while someone else is in the server to scare.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local Prank = {}
-- (tests: a stand-in body, a clock to drive, frames to step)
Prank._testSource = nil :: Instance?
Prank._clock = nil :: (() -> number)?
Prank._testSteps = nil :: { (any) -> () }?
local ctx
local player = Players.LocalPlayer

local button: GuiButton? = nil
local scaring = false

local function product()
	local p = ctx.Config.Shop.JumpscareAll
	return (p and p.Id > 0) and p or nil
end

local function buy()
	-- (v145) a free one first (the Starter Pack's), straight away, no purchase window
	if (tonumber(player:GetAttribute("PrankCredits")) or 0) > 0 then
		ctx.Remotes.PrankFree:FireServer()
		return
	end
	local p = product()
	if p then
		pcall(function()
			MarketplaceService:PromptProductPurchase(player, p.Id)
		end)
	end
end

local function others(): number
	return #Players:GetPlayers() - 1
end

local function refresh()
	if not button then
		return
	end
	local show = product() ~= nil and others() > 0
	if ctx.Mode ~= "Lobby" then
		show = show and player:GetAttribute("InGame") == true and not workspace:GetAttribute("EndingActive")
	end
	button.Visible = show
	-- (v145) the Starter Pack's free one shows as FREE
	if button:IsA("TextButton") and button.Name == "PrankOffer" then
		local free = (tonumber(player:GetAttribute("PrankCredits")) or 0) > 0
		button.Text = "😱 JUMPSCARE EVERYONE  " .. (free and "FREE" or ("R$ " .. tostring(product() and product().Price or 10)))
	end
end
Prank._refresh = refresh -- (tests)
Prank.buy = buy -- (v137: also offered on the result card while you watch the others)
Prank.others = others

-- a banner low on the screen for a few seconds (works in the lobby and in the house)
local function banner(gui: ScreenGui, text: string, seconds: number)
	local UI = ctx.UI
	local b = UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(520, 40),
		Text = text,
		Font = UI.Font.Bold,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(255, 236, 228),
		BackgroundColor3 = Color3.fromRGB(70, 10, 12),
		BackgroundTransparency = 0.15,
		ZIndex = 5,
		Parent = gui,
	})
	UI.corner(b, 10)
	task.delay(seconds, function()
		if b.Parent then
			UI.tween(b, 0.5, { BackgroundTransparency = 1, TextTransparency = 1 })
			task.delay(0.6, function()
				b:Destroy()
			end)
		end
	end)
end

local function overlay(): ScreenGui
	return ctx.UI.new("ScreenGui", {
		Name = "Prank",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 60,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = ctx.UI.PlayerGui,
	})
end

-- his mask and hair, copied into a viewport: the Head part and what's on it (whatever's visible
-- within reach of it), placed relative to the head
local function maskCopy(): (Model?, CFrame?)
	local him = ctx.Util.creature and ctx.Util.creature()
	-- (v149: no mask any more: his own face, the skinned body copied in at rest with its eyes at the middle; the
	-- scare poses it, the maw tearing open)
	local body = him and not him:GetAttribute("Masked") and him:FindFirstChild("Body") :: MeshPart?
	if body and body:IsA("MeshPart") then
		local eyeL = body:FindFirstChild("EyeShineL", true) :: Bone?
		local eyeR = body:FindFirstChild("EyeShineR", true) :: Bone?
		local mid = (eyeL and eyeR) and body.CFrame:PointToObjectSpace((eyeL.WorldPosition + eyeR.WorldPosition) / 2) or Vector3.new(0, body.Size.Y * 0.4, -0.4)
		local m = Instance.new("Model")
		m:SetAttribute("Skinned", true)
		local c = body:Clone()
		for _, x in c:GetDescendants() do
			if not (x:IsA("Bone") or x:IsA("SurfaceAppearance") or x:IsA("BillboardGui") or x:IsA("Frame") or x:IsA("UICorner")) then
				x:Destroy()
			end
		end
		c.Anchored = true
		-- (the eyes a little above the middle of the picture, the maw below them)
		c.CFrame = CFrame.new(-mid + Vector3.new(0, 0.35, 0))
		c.Parent = m
		-- (v156: his body is 14 skinned pieces around an invisible holder for the bones: each copied in where it sits)
		for _, piece in him:GetChildren() do
			if piece:IsA("MeshPart") and piece:GetAttribute("SkinPiece") then
				local pc = piece:Clone()
				for _, x in pc:GetChildren() do
					if not x:IsA("SurfaceAppearance") then
						x:Destroy()
					end
				end
				pc.Anchored = true
				pc.CFrame = c.CFrame * body.CFrame:ToObjectSpace(piece.CFrame)
				pc.Parent = m
			end
		end
		return m, c.CFrame
	end
	local head = him and him:FindFirstChild("Head") :: BasePart?
	if not head then
		return nil, nil
	end
	local m = Instance.new("Model")
	local hcf = head.CFrame
	for _, d in him:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Body" and d.Name ~= "HumanoidRootPart" and d.Name ~= "FaceGlow"
			and (d == head or d.Transparency < 0.95) and (d.Position - head.Position).Magnitude < 2.6 then
			local c = d:Clone()
			for _, x in c:GetChildren() do
				if not x:IsA("SpecialMesh") and not x:IsA("Decal") then
					x:Destroy()
				end
			end
			c.Anchored = true
			c.CFrame = hcf:ToObjectSpace(d.CFrame)
			c.Transparency = d == head and 0 or d.Transparency
			c.Parent = m
		end
	end
	return m, hcf
end

-- one sound, played now (looped ones stop when told)
local function play(name: string, volume: number?, speed: number?): Sound?
	local snd = ctx.Effects and ctx.Effects.localSound(name)
	if not snd then
		return nil
	end
	if volume then
		snd.Volume = volume
	end
	if speed then
		snd.PlaybackSpeed = speed
	end
	snd:Play()
	if not snd.Looped then
		game:GetService("Debris"):AddItem(snd, 10)
	end
	return snd
end

-- a buzz in the hands (a controller's motors; a phone where Roblox allows it)
local function buzz(strength: number, seconds: number)
	pcall(function()
		local HS = game:GetService("HapticService")
		for _, input in { Enum.UserInputType.Gamepad1, Enum.UserInputType.Touch } do
			if HS:IsVibrationSupported(input) then
				for _, motor in { Enum.VibrationMotor.Large, Enum.VibrationMotor.Small } do
					if HS:IsMotorSupported(input, motor) then
						HS:SetMotor(input, motor, strength)
						task.delay(seconds, function()
							pcall(function()
								HS:SetMotor(input, motor, 0)
							end)
						end)
					end
				end
			end
		end
	end)
end

-- (v167) his real body for the scare: ReplicatedStorage.Assets.Creature, scaled as the server's Rig does (Rig.SkinScale), every
-- piece anchored, in the world on this device only; with where his eyes are relative to its pivot
local SKIN_SCALE = 0.05485 -- (= server Intruder/Rig.SkinScale)
local function bodyCopy(): (Model?, Vector3?)
	local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
	local src = Prank._testSource or (assets and assets:FindFirstChild("Creature"))
	if not src or typeof(src) ~= "Instance" or not src:FindFirstChild("Body") then
		return nil, nil
	end
	local ok, m = pcall(function()
		local c = (src :: Model):Clone()
		c:ScaleTo(SKIN_SCALE)
		return c
	end)
	if not ok or not m then
		return nil, nil
	end
	local model = m :: Model
	model.Name = "PrankHim"
	model:SetAttribute("Skinned", true)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
		elseif d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") then
			d:Destroy()
		end
	end
	local body = model:FindFirstChild("Body") :: BasePart
	model.PrimaryPart = body
	body.Transparency = 1
	local eyeL = body:FindFirstChild("Base HumanLEye", true) :: Bone?
	local eyeR = body:FindFirstChild("Base HumanHeadREye", true) :: Bone?
	local pivot = model:GetPivot()
	local eyes
	if eyeL and eyeR then
		eyes = pivot:PointToObjectSpace((eyeL.WorldPosition + eyeR.WorldPosition) / 2)
	else
		eyes = Vector3.new(0, body.Size.Y * 0.44, -0.5)
	end
	return model, eyes
end
Prank._bodyCopy = bodyCopy -- (tests)

-- where your eyes are and which way you look: your head in the house; in the lobby's third person, from your head along the
-- camera's look (so your own avatar isn't between you and him)
local function viewpoint(): CFrame
	local cam = workspace.CurrentCamera
	local char = player.Character
	local head = char and char:FindFirstChild("Head") :: BasePart?
	if head and (cam.CFrame.Position - head.Position).Magnitude > 2 then
		local look = cam.CFrame.LookVector
		return CFrame.lookAt(head.Position + Vector3.new(0, 0.3, 0), head.Position + Vector3.new(0, 0.3, 0) + look)
	end
	return cam.CFrame
end

--[[
	(v167) The scare, in the world (v168: faster, ~1.5 s; the beats below in the code).
	1. the lights die: the room goes dark around you, a low rumble and a heartbeat; he's standing a few steps in front of you
	   in a cold light, twitching in stop-motion;
	2. he rushes you: 0.28 s, faster and faster, a screech;
	3. in your face: his face an arm's length from the lens, jaw torn open, shaking violently and screaming (five sounds
	   layered), the picture jerking with him, a white hit-frame, red pulses, the controller / phone buzzing;
	4. a hard cut to black, everything put back, then who did it.
	False if he can't be built here (the old viewport scare runs instead).
]]
local function scareWorld(from: string, text: string?): boolean
	if not workspace.CurrentCamera then
		return false
	end
	local model, eyes = bodyCopy()
	if not model or not eyes then
		return false
	end
	local UI = ctx.UI
	local Lighting = game:GetService("Lighting")
	local cam = workspace.CurrentCamera
	local gui = overlay()
	local black = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5, Parent = gui })
	local red = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(170, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3, Parent = gui })
	local white = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4, Parent = gui })
	-- the dark: the world's light drops away (put back after), a cold grade
	local saved = { Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, ExposureCompensation = Lighting.ExposureCompensation }
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	local savedAtmo = atmo and { Density = atmo.Density, Color = atmo.Color, Decay = atmo.Decay, Haze = atmo.Haze, Glare = atmo.Glare } or nil
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "PrankGrade"
	grade.Saturation = -0.5
	grade.Contrast = 0.35
	grade.Parent = Lighting
	local function darken(k: number)
		Lighting.Brightness = saved.Brightness * (1 - k)
		Lighting.Ambient = saved.Ambient:Lerp(Color3.new(0, 0, 0), k)
		Lighting.OutdoorAmbient = saved.OutdoorAmbient:Lerp(Color3.new(0, 0, 0), k)
		Lighting.ExposureCompensation = saved.ExposureCompensation - 1.2 * k
		if atmo and savedAtmo then
			atmo.Density = savedAtmo.Density + (0.62 - savedAtmo.Density) * k
			atmo.Color = savedAtmo.Color:Lerp(Color3.new(0, 0, 0), k)
			atmo.Decay = savedAtmo.Decay:Lerp(Color3.new(0, 0, 0), k)
			atmo.Glare, atmo.Haze = savedAtmo.Glare * (1 - k), savedAtmo.Haze * (1 - k)
		end
	end
	-- the camera holds still where you're looking (moved only by the shaking)
	local oldType, oldFov = cam.CameraType, cam.FieldOfView
	local base = viewpoint()
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = base
	local char = player.Character
	local hidden = {}
	if char then
		for _, d in char:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				hidden[d] = d.LocalTransparencyModifier
			end
		end
	end
	-- how far in front of you he starts: never inside a wall
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, model }
	local hit = workspace:Raycast(base.Position, base.LookVector * 9, params)
	local startD = hit and math.clamp(hit.Distance - 1, 2.6, 7.5) or 7.5
	local NEAR = 1.25
	-- his light: a cold lamp from just over your shoulder, so he reads in the dark
	local lamp = Instance.new("Part")
	lamp.Name = "PrankLamp"
	lamp.Anchored, lamp.CanCollide, lamp.CanQuery, lamp.CanTouch = true, false, false, false
	lamp.Transparency = 1
	lamp.Size = Vector3.one * 0.2
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Front
	spot.Brightness = 7
	spot.Range = 18
	spot.Angle = 55
	spot.Color = Color3.fromRGB(200, 215, 255)
	spot.Shadows = false
	spot.Parent = lamp
	local fill = Instance.new("PointLight")
	fill.Brightness = 1.4
	fill.Range = 6
	fill.Color = Color3.fromRGB(255, 120, 110)
	lamp.Parent = workspace
	model.Parent = workspace
	Prank._him = model -- (tests)
	fill.Parent = model.PrimaryPart
	-- put him so his eyes are at `d` studs in front of you (a touch below the middle), facing you
	local function stand(d: number, jerk: CFrame)
		local target = (base * CFrame.new(0, -0.12, -d)).Position
		local face = CFrame.lookAt(target, base.Position)
		local pivotAt = face * CFrame.new(-eyes) -- (the pivot placed so its eyes land on the target)
		model:PivotTo(pivotAt * jerk)
	end
	-- (v168, the owner: "Make the jumpscare faster and scarier") ~1.5 s: no slow build. The lights stutter and show him in flashes,
	-- he's at your face in a blink, then he screams and thrashes right against the lens
	local heart = play("Heartbeat", 1.2, 1.9)
	local RUSH, FACE, CUT = 0.26, 0.38, 1.5
	local clock = Prank._clock or os.clock -- (tests drive it)
	local t0 = clock()
	local hitDone, screeched, screamed2 = false, false, false
	local jerk, camJerk, nextJerk = CFrame.identity, CFrame.identity, 0
	local stop = false
	local warned = false
	local blur = Instance.new("BlurEffect")
	blur.Name = "PrankBlur"
	blur.Size = 0
	blur.Parent = Lighting
	local frame
	RunService:BindToRenderStep("PrankScare", Enum.RenderPriority.Last.Value, function()
		if stop then
			return
		end
		local ok, err = pcall(frame)
		Prank._frames = (Prank._frames or 0) + 1
		if not ok and not warned then
			warned = true
			Prank._frameError = err
			warn("[Prank] " .. tostring(err))
		end
	end)
	frame = function()
		local k = clock() - t0
		for d in hidden do
			if d.Parent then
				d.LocalTransparencyModifier = 1
			end
		end
		local d, gait, scream
		if k < RUSH then
			-- 1. the lights stutter: dark, him lit, dark, him lit
			local on = (k < 0.07) or (k > 0.13 and k < 0.19)
			darken(1)
			spot.Brightness = on and 9 or 0
			fill.Brightness = on and 1.6 or 0
			d, gait, scream = startD, "Stare", 0
		elseif k < FACE then
			-- 2. the lunge: a blink, faster and faster
			spot.Brightness, fill.Brightness = 9, 1.6
			if not screeched then
				screeched = true
				play("Screech", 1.8)
				play("HorrorHitLow", 1.4)
				if heart then
					heart:Stop()
				end
			end
			local u = (k - RUSH) / (FACE - RUSH)
			d, gait, scream = startD - (startD - NEAR) * (u * u * u), "Stare", u
			cam.FieldOfView = oldFov + 12 * u
		else
			-- 3. in your face: thrashing, screaming
			local s2 = k - FACE
			if not hitDone then
				hitDone = true
				for _, name in { "DemonScreech", "Jumpscare", "HorrorHitLow", "BoneRun", "Screech" } do
					play(name, 1.8)
				end
				buzz(1, 1)
				white.BackgroundTransparency = 0
				task.delay(0.04, function()
					white.BackgroundTransparency = 1
				end)
				blur.Size = 22
				grade.Brightness = 0.4
				ctx.UI.tween(blur, 0.3, { Size = 3 })
				ctx.UI.tween(grade, 0.25, { Brightness = 0, TintColor = Color3.fromRGB(255, 190, 186) })
			end
			if not screamed2 and s2 > 0.5 then
				-- (again: he isn't done with you)
				screamed2 = true
				play("DemonScreech", 1.6, 1.15)
				play("Screech", 1.4, 0.9)
				blur.Size = 14
				ctx.UI.tween(blur, 0.25, { Size = 3 })
			end
			-- lunging at the lens again and again
			d = NEAR - 0.35 * math.abs(math.sin(s2 * 16)) - 0.05
			gait, scream = "Stare", 1
			-- (the FOV slams in on contact, then pumps)
			cam.FieldOfView = oldFov - 22 + 6 * math.sin(s2 * 50) + 30 * math.max(0, 0.08 - s2) / 0.08
			red.BackgroundTransparency = 1 - 0.5 * math.max(0, math.sin(s2 * 28))
			spot.Brightness = (math.random() < 0.12) and 2 or 9 -- (the light buzzing as he thrashes)
		end
		-- the shaking: him and the picture, in fits
		if clock() >= nextJerk then
			local amt = (k >= FACE) and 1.4 or (k >= RUSH and 0.3 or 0.08)
			nextJerk = clock() + (k >= FACE and 0.03 or 0.06) + math.random() * 0.025
			-- (his head whipping side to side, the picture jerking with him)
			jerk = CFrame.new((math.random() - 0.5) * 0.35 * amt, (math.random() - 0.5) * 0.3 * amt, 0)
				* CFrame.Angles((math.random() - 0.5) * 0.35 * amt, (math.random() - 0.5) * 0.5 * amt, (math.random() - 0.5) * 0.7 * amt)
			camJerk = CFrame.Angles((math.random() - 0.5) * 0.07 * amt, (math.random() - 0.5) * 0.07 * amt, (math.random() - 0.5) * 0.14 * amt)
		end
		if ctx.Creature and ctx.Creature.poseCopy then
			pcall(ctx.Creature.poseCopy, model, gait, k, 4, { Scream = scream })
		end
		stand(d, jerk)
		cam.CFrame = base * camJerk
		lamp.CFrame = base * CFrame.new(0.4, 0.5, 0.3)
	end
	if Prank._clock then
		-- (tests: every beat stepped through by hand)
		for _, fn in Prank._testSteps or {} do
			fn(frame)
		end
	end
	task.wait(CUT)
	-- 4. the hard cut
	stop = true
	black.BackgroundTransparency = 0
	RunService:UnbindFromRenderStep("PrankScare")
	model:Destroy()
	lamp:Destroy()
	grade:Destroy()
	blur:Destroy()
	if heart then
		heart:Destroy()
	end
	darken(0)
	Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.ExposureCompensation = saved.Brightness, saved.Ambient, saved.OutdoorAmbient, saved.ExposureCompensation
	for dd, v in hidden do
		if dd.Parent then
			dd.LocalTransparencyModifier = v
		end
	end
	cam.FieldOfView = oldFov
	cam.CameraType = oldType
	red.BackgroundTransparency = 1
	task.wait(0.25)
	UI.tween(black, 0.35, { BackgroundTransparency = 1 })
	banner(gui, text or ("😱 " .. from .. " jumpscared everyone!"), 4)
	task.delay(5, function()
		gui:Destroy()
	end)
	task.wait(0.5)
	return true
end
Prank._scareWorld = scareWorld

--[[
	The scare itself (v165, the owner: "make the jumpscare everyone much scarier"). Three beats, ~2.6 s:
	1. the dread: the screen dims and creeps with static, a low rumble and a heartbeat speeding up;
	2. the glimpses: dead black and silence, then his face far off in a cold light for two frames, black, closer, black;
	3. the slam: his face rushes the lens and fills the screen screaming, jaw dropped, the picture shaking itself apart,
	   a white hit-frame, red pulses and static tearing across, three screams layered, the controller / phone buzzing;
	   then a hard cut to black and the line saying who did it.
]]
function Prank.scare(from: string, text: string?)
	if scaring then
		return
	end
	-- (never on top of the real thing)
	if workspace:GetAttribute("EndingActive") or player:GetAttribute("Captured") then
		return
	end
	scaring = true
	-- (v167) his real body, in front of you; the old viewport scare only if he can't be built here
	local okW, done = pcall(scareWorld, from, text)
	if okW and done then
		scaring = false
		return
	elseif not okW then
		warn("[Prank] " .. tostring(done))
		pcall(function()
			RunService:UnbindFromRenderStep("PrankScare")
		end)
	end
	local UI = ctx.UI
	local gui = overlay()
	local dim = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1, Parent = gui })
	local vp = UI.new("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ImageTransparency = 1,
		Ambient = Color3.fromRGB(70, 80, 100),
		LightColor = Color3.fromRGB(200, 220, 255),
		LightDirection = Vector3.new(0.2, -0.9, -0.6),
		ZIndex = 2,
		Parent = gui,
	})
	-- static: a few grey bars that jump about
	local bars = {}
	for i = 1, 7 do
		bars[i] = UI.new("Frame", {
			Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Color3.fromRGB(200, 200, 200), BackgroundTransparency = 1,
			BorderSizePixel = 0, ZIndex = 4, Parent = gui,
		})
	end
	local red = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(160, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3, Parent = gui })
	local white = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5, Parent = gui })
	local cam = Instance.new("Camera")
	cam.FieldOfView = 55
	cam.Parent = vp
	vp.CurrentCamera = cam
	local mask = maskCopy()
	local jaws = {}
	if mask then
		mask.Parent = vp
		jaws = ctx.CreaturePose.jawMeshes(mask)
	end
	local rumble = play("Presence", 1.6)
	local heart = play("Heartbeat", 1, 1.1)
	-- the timeline (seconds from the start)
	local DREAD, BLACK, FAR, FAR_END, NEAR, NEAR_END, SLAM, CUT = 0, 0.85, 1.1, 1.18, 1.38, 1.46, 1.66, 2.55
	local slammed = false
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not gui.Parent then
			conn:Disconnect()
			return
		end
		local k = os.clock() - t0
		-- static bars: a little in the dread, a lot in the slam
		local staticAmt = (k < BLACK and math.clamp(k / BLACK, 0, 1) * 0.35) or (k >= SLAM and k < CUT and 0.8) or 0
		for _, b in bars do
			b.Visible = math.random() < staticAmt
			b.Position = UDim2.fromScale(0, math.random())
			b.Size = UDim2.new(1, 0, 0, math.random(2, 10))
			b.BackgroundTransparency = 0.35 + math.random() * 0.5
		end
		if k < BLACK then
			-- 1. the dread
			dim.BackgroundTransparency = 1 - 0.7 * math.clamp((k - DREAD) / BLACK, 0, 1)
			if heart then
				heart.PlaybackSpeed = 1.1 + k
			end
			vp.ImageTransparency = 1
		elseif k < SLAM then
			-- 2. black, silence, then the glimpses
			dim.BackgroundTransparency = 0
			if rumble and rumble.IsPlaying then
				rumble:Stop()
			end
			if heart and heart.IsPlaying then
				heart:Stop()
			end
			local d = nil
			if k >= FAR and k < FAR_END then
				d = 14
			elseif k >= NEAR and k < NEAR_END then
				d = 6.5
			end
			vp.ImageTransparency = d and 0 or 1
			if d then
				cam.CFrame = CFrame.lookAt(Vector3.new(0.3, 0.1, -d), Vector3.new(0, 0, 0))
				if mask and mask:FindFirstChild("Body") and ctx.Creature and ctx.Creature.poseCopy then
					ctx.Creature.poseCopy(mask, "Stare", k, 4, { Scream = 0 })
				end
				ctx.CreaturePose.setJaw(jaws, 0)
			end
		elseif k < CUT then
			-- 3. the slam
			if not slammed then
				slammed = true
				for _, name in { "Screech", "DemonScreech", "Jumpscare", "HorrorHitLow", "BoneRun" } do
					play(name)
				end
				buzz(1, 0.7)
				white.BackgroundTransparency = 0
				task.delay(0.05, function()
					white.BackgroundTransparency = 1
				end)
				if ctx.Effects then
					ctx.Effects.shake(1.6, 1)
				end
			end
			local s2 = k - SLAM
			vp.ImageTransparency = 0
			local lunge = 1 - (1 - math.min(s2 / 0.12, 1)) ^ 3
			local d = 5 - 3.5 * lunge
			local shakeA = 0.09 * (1 - math.min(s2 / 0.9, 1)) + 0.02
			local jerk = CFrame.Angles((math.random() - 0.5) * shakeA, (math.random() - 0.5) * shakeA, (math.random() - 0.5) * shakeA * 3)
			cam.CFrame = CFrame.lookAt(Vector3.new(0, -0.05, -d), Vector3.new(0, -0.05, 0)) * jerk
			cam.FieldOfView = 55 + 25 * (1 - lunge) - 6 * math.sin(s2 * 40)
			ctx.CreaturePose.setJaw(jaws, math.clamp(s2 / 0.1, 0, 1))
			if mask and mask:FindFirstChild("Body") and ctx.Creature and ctx.Creature.poseCopy then
				ctx.Creature.poseCopy(mask, "Stare", k, 4, { Scream = 1 })
			end
			-- the picture itself jumps about, and goes red in pulses
			local px = math.floor((math.random() - 0.5) * 40 * (1 - math.min(s2, 1)))
			local py = math.floor((math.random() - 0.5) * 30 * (1 - math.min(s2, 1)))
			vp.Position = UDim2.new(0.5, px, 0.5, py)
			vp.Size = UDim2.new(1.08, 0, 1.08, 0)
			vp.ImageColor3 = (math.floor(s2 * 14) % 2 == 0) and Color3.fromRGB(255, 200, 200) or Color3.new(1, 1, 1)
			red.BackgroundTransparency = 1 - 0.5 * math.max(0, math.sin(s2 * 22))
		else
			-- the hard cut
			vp.ImageTransparency = 1
			red.BackgroundTransparency = 1
			dim.BackgroundTransparency = 0
			for _, b in bars do
				b.Visible = false
			end
		end
	end)
	task.wait(CUT + 0.3)
	conn:Disconnect()
	if rumble then
		rumble:Destroy()
	end
	if heart then
		heart:Destroy()
	end
	UI.tween(dim, 0.45, { BackgroundTransparency = 1 })
	banner(gui, text or ("😱 " .. from .. " jumpscared everyone!"), 4)
	task.delay(5, function()
		gui:Destroy()
	end)
	task.wait(0.5)
	scaring = false
end
Prank._timeline = 2.3 -- (tests: how long the scare runs)

function Prank.init(c)
	ctx = c
	ctx.Prank = Prank
end

function Prank.start()
	local UI = ctx.UI
	if ctx.Mode == "Lobby" then
		if ctx.Dock then
			button = ctx.Dock.add({ Order = ctx.Dock.Order.Scare, Glyph = "😱", Label = "SCARE", Color = Color3.fromRGB(255, 96, 90), OnClick = buy })
		end
	else
		local b = UI.new("TextButton", {
			Name = "PrankOffer",
			Size = UDim2.fromOffset(190, 30),
			Text = "😱 JUMPSCARE EVERYONE  R$ " .. tostring(product() and product().Price or 10),
			Font = UI.Font.Bold,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(255, 228, 224),
			BackgroundColor3 = Color3.fromRGB(80, 14, 16),
			BackgroundTransparency = 0.2,
			AutoButtonColor = true,
			LayoutOrder = 11,
			Visible = false,
			Parent = ctx.HUD and (ctx.HUD.OfferColumn or ctx.HUD.LeftColumn) or UI.Root,
		})
		UI.corner(b, 8)
		UI.stroke(b, Color3.fromRGB(255, 120, 110), 1, 0.55)
		b.Activated:Connect(buy)
		button = b
	end
	refresh()
	Players.PlayerAdded:Connect(refresh)
	Players.PlayerRemoving:Connect(function()
		task.defer(refresh)
	end)
	player:GetAttributeChangedSignal("InGame"):Connect(refresh)
	player:GetAttributeChangedSignal("PrankCredits"):Connect(refresh)
	workspace:GetAttributeChangedSignal("EndingActive"):Connect(refresh)
	ctx.Remotes.JumpscareAll.OnClientEvent:Connect(function(fromName: string, fromId: number, count: number?)
		if fromId == player.UserId then
			-- (v170, the owner: "Make jumpscare everyone jumpscare other people in the server only, not the user": v165 scared the buyer
			-- too. The buyer only hears how many they got; the admin panel's "Jumpscare Everyone (just me)" still shows what it looks like.)
			local n = tonumber(count) or others()
			if ctx.HUD and ctx.HUD.notify then
				ctx.HUD.notify("😈 You jumpscared " .. n .. (n == 1 and " player!" or " players!"), "done")
			end
			return
		end
		task.spawn(Prank.scare, fromName)
	end)
end

return Prank
