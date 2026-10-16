--[[
	Movement — sprint / crouch intents (the server decides the real speed), crouch camera,
	sprint FOV and a gentle head bob. Also drives the flashlight's pitch so the beam
	follows where you look.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Movement = {}
local ctx
local player = Players.LocalPlayer

local sprintHeld = false
local sprintToggled = false
local crouch = false
local lastSent = { Sprint = false, Crouch = false }
local bobT = 0
local offsetY = 0

local function blocked(): boolean
	return not player:GetAttribute("InGame") or player:GetAttribute("Hiding") ~= nil or player:GetAttribute("Captured") == true
		or player:GetAttribute("Escaped") ~= nil
end

local function send()
	local sprint = (sprintHeld or sprintToggled) and not blocked()
	local c = crouch and not blocked()
	if sprint ~= lastSent.Sprint or c ~= lastSent.Crouch then
		lastSent = { Sprint = sprint, Crouch = c }
		ctx.Remotes.Movement:FireServer(lastSent)
	end
end

function Movement.isSprinting(): boolean
	return sprintHeld or sprintToggled
end

function Movement.isCrouching(): boolean
	return crouch
end

function Movement.setSprintToggle(on: boolean)
	sprintToggled = on
	if on then
		crouch = false
	end
	send()
end

function Movement.init(c)
	ctx = c
	ctx.Movement = Movement
end

local beamPart: Part
local localBeam: SpotLight
local localGlow: PointLight

local function buildLocalFlashlight()
	beamPart = Instance.new("Part")
	beamPart.Name = "LocalFlashlight"
	beamPart.Anchored = true
	beamPart.CanCollide = false
	beamPart.CanQuery = false
	beamPart.CanTouch = false
	beamPart.Transparency = 1
	beamPart.Size = Vector3.new(0.2, 0.2, 0.2)
	beamPart.Parent = workspace
	localBeam = Instance.new("SpotLight")
	localBeam.Face = Enum.NormalId.Front
	localBeam.Range = 60
	localBeam.Angle = 55
	localBeam.Brightness = 3.2
	localBeam.Color = Color3.fromRGB(255, 244, 222)
	-- shadow-casting lights are the heaviest thing we draw: phones never get them, and a PC drops
	-- them when the frame rate sinks (v94 logs: PC nights under 30 fps 18 of 55, was 7 of 70)
	localBeam.Shadows = not game:GetService("UserInputService").TouchEnabled
	localBeam.Enabled = false
	localBeam.Parent = beamPart
	-- a little spill so the edges of the beam aren't pitch black
	localGlow = Instance.new("PointLight")
	localGlow.Range = 9
	localGlow.Brightness = 0.35
	localGlow.Color = Color3.fromRGB(255, 244, 222)
	localGlow.Enabled = false
	localGlow.Parent = beamPart
end

function Movement.start()
	buildLocalFlashlight()
	local function tint()
		local c = player:GetAttribute("StatBeamColor")
		local col = typeof(c) == "Color3" and c or Color3.fromRGB(255, 244, 222)
		localBeam.Color = col
		localGlow.Color = col
	end
	tint()
	player:GetAttributeChangedSignal("StatBeamColor"):Connect(tint)
	player:GetAttributeChangedSignal("FlashlightOn"):Connect(function()
		if ctx.Effects then
			ctx.Effects.playSound(player:GetAttribute("FlashlightOn") and "FlashlightOn" or "FlashlightOff", nil, { Caption = false })
		end
	end)
	ctx.Input.on("Sprint", function(began)
		sprintHeld = began
		if began then
			crouch = false
		end
		send()
	end)
	ctx.Input.on("Crouch", function(began)
		if not began or blocked() then
			return
		end
		crouch = not crouch
		if crouch then
			sprintToggled = false
		end
		send()
	end)
	-- (the flashlight, the spray, the taser and the rest are tools in the hotbar now: client Gear)
	for _, attr in { "Hiding", "Captured", "InGame", "Escaped" } do
		player:GetAttributeChangedSignal(attr):Connect(function()
			if blocked() then
				sprintToggled = false
				crouch = false
			end
			send()
		end)
	end

	local slowSeconds, fpsClock, frames = 0, 0, 0
	RunService.RenderStepped:Connect(function(dt)
		-- frame rate once a second: three slow seconds in a row with the light on → no more shadows
		fpsClock += dt
		frames += 1
		if fpsClock >= 1 then
			local fps = frames / fpsClock
			fpsClock, frames = 0, 0
			if localBeam.Shadows and localBeam.Enabled then
				slowSeconds = fps < 40 and slowSeconds + 1 or 0
				if slowSeconds >= 3 then
					localBeam.Shadows = false
				end
			end
		end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local cam = workspace.CurrentCamera
		if not hum or not cam then
			return
		end
		-- mobile sprint switches itself off when you stop or run out of breath
		if sprintToggled and ((player:GetAttribute("Stamina") or 100) < 3 or hum.MoveDirection.Magnitude < 0.05) then
			sprintToggled = false
			send()
		end
		local crouched = player:GetAttribute("Crouching") == true
		local target = crouched and ctx.Config.Movement.CrouchCameraOffset or 0
		offsetY += (target - offsetY) * math.min(1, dt * 10)
		local moving = hum.MoveDirection.Magnitude > 0.1 and not blocked()
		local speed = hum.WalkSpeed
		if moving then
			bobT += dt * (speed * 0.9)
		end
		local bobAmp = moving and math.clamp(speed / 60, 0.05, 0.28) or 0
		hum.CameraOffset = Vector3.new(math.cos(bobT * 0.5) * bobAmp * 0.5, offsetY + math.abs(math.sin(bobT)) * bobAmp, 0)
		local fov = player:GetAttribute("Sprinting") and 78 or 70
		if cam.CameraType ~= Enum.CameraType.Scriptable then
			cam.FieldOfView += (fov - cam.FieldOfView) * math.min(1, dt * 6)
		end

		-- your own flashlight: a local light that follows the camera exactly
		local on = player:GetAttribute("FlashlightOn") == true
		localBeam.Enabled = on
		localGlow.Enabled = on
		if on then
			beamPart.CFrame = cam.CFrame * CFrame.new(0.7, -0.6, -0.4)
		end
		-- the server's copy (so others see your beam) stays off for you, and aims with your pitch
		local head = char:FindFirstChild("Head")
		local mount = head and head:FindFirstChild("FlashlightMount") :: Attachment?
		if mount then
			local look = cam.CFrame.LookVector
			mount.Orientation = Vector3.new(math.deg(math.asin(math.clamp(look.Y, -1, 1))), 0, 0)
			local serverLight = mount:FindFirstChildOfClass("SpotLight")
			if serverLight then
				serverLight.Enabled = false
			end
		end
	end)
end

return Movement
