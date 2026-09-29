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

function Movement.start()
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
	ctx.Input.on("Flashlight", function(began)
		if began and player:GetAttribute("InGame") then
			ctx.Remotes.Flashlight:FireServer()
		end
	end)
	ctx.Input.on("Spray", function(began)
		if began and player:GetAttribute("Item_PepperSpray") then
			ctx.Remotes.UseItem:FireServer("PepperSpray")
		end
	end)
	for _, attr in { "Hiding", "Captured", "InGame", "Escaped" } do
		player:GetAttributeChangedSignal(attr):Connect(function()
			if blocked() then
				sprintToggled = false
				crouch = false
			end
			send()
		end)
	end

	RunService.RenderStepped:Connect(function(dt)
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

		-- flashlight follows the camera's pitch
		local head = char:FindFirstChild("Head")
		local mount = head and head:FindFirstChild("FlashlightMount") :: Attachment?
		if mount then
			local look = cam.CFrame.LookVector
			mount.Orientation = Vector3.new(math.deg(math.asin(math.clamp(look.Y, -1, 1))), 0, 0)
		end
	end)
end

return Movement
