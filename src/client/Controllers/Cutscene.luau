--[[
	Cutscene — short cinematics in the middle of the night (server: CutsceneService): the lights
	going out, him under the garage hatch, you tied to the pipes. Letterbox bars, a slow camera
	move per shot, a line of subtitle; the HUD and touch buttons step aside while it plays.
	Afterwards the camera goes back to whatever it was doing (your eyes, or a hiding spot).

	(v112) Shot like a film: the bars slide in, the lens per shot (Fov), a handheld drift (Shake),
	depth of field that focuses on whatever's in the middle of the frame, a colder grade, and per
	shot a sound (Sound) or him screaming (Scream).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Cutscene = {}
local ctx
local player = Players.LocalPlayer

local playing = false
local token = 0

function Cutscene.isPlaying(): boolean
	return playing
end

local function hudVisible(on: boolean)
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if ctx.UI.Root then
		ctx.UI.Root.Enabled = on
	end
	local touch = pg and pg:FindFirstChild("HomeAloneTouch")
	if touch and touch:IsA("ScreenGui") then
		touch.Enabled = on
	end
end

local function restoreCamera()
	local cam = workspace.CurrentCamera
	if typeof(player:GetAttribute("HideView")) == "CFrame" then
		cam.CameraType = Enum.CameraType.Scriptable -- (HidingCam takes it back)
		return
	end
	cam.CameraType = Enum.CameraType.Custom
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		cam.CameraSubject = hum
	end
end

local function play(payload)
	if type(payload) ~= "table" or type(payload.Shots) ~= "table" or #payload.Shots == 0 then
		return
	end
	if workspace:GetAttribute("EndingActive") then
		return
	end
	token += 1
	local mine = token
	playing = true
	local UI = ctx.UI
	local cam = workspace.CurrentCamera
	if ctx.Effects then
		ctx.Effects.fade(true, 0.35)
	end
	task.wait(0.35)
	if mine ~= token then
		return
	end
	hudVisible(false)
	cam.CameraType = Enum.CameraType.Scriptable
	local oldFov = cam.FieldOfView
	local top = UI.new("Frame", { Name = "CutTop", Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 30, Parent = UI.Top })
	local bottom = UI.new("Frame", { Name = "CutBottom", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 30, Parent = UI.Top })
	UI.tween(top, 0.6, { Size = UDim2.new(1, 0, 0.12, 0) })
	UI.tween(bottom, 0.6, { Size = UDim2.new(1, 0, 0.14, 0) })
	-- the lens: a shallow depth of field and a colder, harder grade
	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "CutsceneDOF"
	dof.FarIntensity = 0.4
	dof.NearIntensity = 0.5
	dof.InFocusRadius = 6
	dof.FocusDistance = 12
	dof.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "CutsceneGrade"
	grade.Contrast = 0.12
	grade.Saturation = -0.18
	grade.TintColor = Color3.fromRGB(232, 238, 255)
	grade.Parent = Lighting
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: any }
	local sub = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.86, 0, 1, 0),
		Text = payload.Subtitle or "",
		Font = UI.Font.Title,
		TextSize = 24,
		TextWrapped = true,
		TextTransparency = 1,
		ZIndex = 31,
		Parent = bottom,
	})
	if ctx.Effects then
		ctx.Effects.fade(false, 0.6)
	end
	if sub.Text ~= "" then
		task.delay(0.6, function()
			UI.tween(sub, 0.6, { TextTransparency = 0 })
		end)
	end
	for _, shot in payload.Shots do
		if mine ~= token or workspace:GetAttribute("EndingActive") then
			break
		end
		local from, to, dur = shot.From, shot.To, shot.Time or 3
		if typeof(from) == "CFrame" and typeof(to) == "CFrame" then
			local fov0 = type(shot.Fov) == "number" and shot.Fov or 58
			local fov1 = type(shot.FovTo) == "number" and shot.FovTo or fov0
			local shake = type(shot.Shake) == "number" and shot.Shake or 0.5
			if type(shot.Sound) == "string" and ctx.Effects then
				local snd = ctx.Effects.localSound(shot.Sound)
				if snd then
					snd:Play()
					game:GetService("Debris"):AddItem(snd, 12)
				end
			end
			if shot.Scream and ctx.Creature then
				task.delay(type(shot.Scream) == "number" and shot.Scream or 0, function()
					ctx.Creature.scream(1.4)
					if ctx.Effects then
						ctx.Effects.shake(0.9, 0.6)
						local snd = ctx.Effects.localSound("Screech")
						if snd then
							snd:Play()
							game:GetService("Debris"):AddItem(snd, 8)
						end
					end
				end)
			end
			local t0 = os.clock()
			local seed = math.random() * 100
			while os.clock() - t0 < dur and mine == token and not workspace:GetAttribute("EndingActive") do
				local k = math.clamp((os.clock() - t0) / dur, 0, 1)
				-- (smootherstep: the move starts and settles without a jolt)
				local e = k * k * k * (k * (k * 6 - 15) + 10)
				local tt = os.clock() - t0 + seed
				-- a camera operator's hands: slow drift, a little breathing
				local drift = CFrame.Angles(
					(math.noise(tt * 0.35, seed) * 0.9 + math.noise(tt * 1.3, seed + 5) * 0.25) * 0.025 * shake,
					(math.noise(seed + 11, tt * 0.3) * 0.9 + math.noise(seed + 2, tt * 1.1) * 0.25) * 0.03 * shake,
					math.noise(tt * 0.25, seed + 7) * 0.02 * shake
				)
				local cf = from:Lerp(to, e) * drift
				cam.CFrame = cf
				cam.FieldOfView = fov0 + (fov1 - fov0) * e
				-- autofocus on what's in the middle of the frame
				local hit = workspace:Raycast(cf.Position, cf.LookVector * 80, params)
				local want = hit and (hit.Position - cf.Position).Magnitude or 40
				dof.FocusDistance += (want - dof.FocusDistance) * 0.15
				dof.InFocusRadius = math.clamp(dof.FocusDistance * 0.35, 2, 14)
				RunService.RenderStepped:Wait()
			end
		end
	end
	if mine ~= token then
		top:Destroy()
		bottom:Destroy()
		dof:Destroy()
		grade:Destroy()
		cam.FieldOfView = oldFov
		return
	end
	if ctx.Effects then
		ctx.Effects.fade(true, 0.3)
	end
	task.wait(0.3)
	top:Destroy()
	bottom:Destroy()
	dof:Destroy()
	grade:Destroy()
	cam.FieldOfView = oldFov
	playing = false
	hudVisible(true)
	if not workspace:GetAttribute("EndingActive") then
		restoreCamera()
	end
	if ctx.Effects then
		ctx.Effects.fade(false, 0.5)
	end
end

function Cutscene.init(c)
	ctx = c
	ctx.Cutscene = Cutscene
end

function Cutscene.start()
	ctx.Remotes.Cutscene.OnClientEvent:Connect(function(payload)
		task.spawn(play, payload)
	end)
	-- the ending takes over the camera: drop out of any cutscene at once
	workspace:GetAttributeChangedSignal("EndingActive"):Connect(function()
		if workspace:GetAttribute("EndingActive") and playing then
			token += 1
			playing = false
			hudVisible(true)
			for _, n in { "CutTop", "CutBottom" } do
				local f = ctx.UI.Top:FindFirstChild(n)
				if f then
					f:Destroy()
				end
			end
			for _, n in { "CutsceneDOF", "CutsceneGrade" } do
				local e = Lighting:FindFirstChild(n)
				if e then
					e:Destroy()
				end
			end
		end
	end)
end

return Cutscene
