--[[
	HidingCam — the fixed peek camera while hidden (look around a little with the mouse
	or by dragging), hold breath, leave; and struggling while captured.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local HidingCam = {}
local ctx
local player = Players.LocalPlayer

local yaw, pitch = 0, 0
local active = false
local lastStruggle = 0

local function onHideChanged()
	local view = player:GetAttribute("HideView")
	local cam = workspace.CurrentCamera
	if typeof(view) == "CFrame" then
		active = true
		yaw, pitch = 0, 0
		cam.CameraType = Enum.CameraType.Scriptable
		cam.FieldOfView = 62
	elseif active then
		active = false
		cam.CameraType = Enum.CameraType.Custom
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			cam.CameraSubject = hum
		end
		cam.FieldOfView = 70
	end
end

function HidingCam.init(c)
	ctx = c
end

function HidingCam.start()
	player:GetAttributeChangedSignal("HideView"):Connect(onHideChanged)

	ctx.Input.on("Breath", function(began)
		if player:GetAttribute("Hiding") then
			ctx.Remotes.HoldBreath:FireServer(began)
		end
	end)
	ctx.Input.on("ExitHide", function(began)
		if began and player:GetAttribute("Hiding") then
			ctx.Remotes.HoldBreath:FireServer(false)
			ctx.Remotes.Hide:FireServer("Exit")
		end
	end)
	ctx.Input.on("Struggle", function(began)
		if began and player:GetAttribute("Captured") and os.clock() - lastStruggle > 0.08 then
			lastStruggle = os.clock()
			ctx.Remotes.Struggle:FireServer()
			if ctx.Effects then
				ctx.Effects.shake(0.12, 0.15)
			end
		end
	end)

	-- look around by dragging (touch) — mouse uses the locked-center delta below
	UserInputService.InputChanged:Connect(function(io, processed)
		if not active or processed then
			return
		end
		if io.UserInputType == Enum.UserInputType.Touch then
			yaw -= io.Delta.X * 0.004
			pitch -= io.Delta.Y * 0.004
		end
	end)

	RunService:BindToRenderStep("HomeAloneHideCam", Enum.RenderPriority.Camera.Value, function()
		if not active or (ctx.Cutscene and ctx.Cutscene.isPlaying()) then
			return
		end
		local view = player:GetAttribute("HideView")
		if typeof(view) ~= "CFrame" then
			return
		end
		if not ctx.UI.isTouch() then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			local d = UserInputService:GetMouseDelta()
			yaw -= d.X * 0.003
			pitch -= d.Y * 0.003
		end
		yaw = math.clamp(yaw, -math.rad(40), math.rad(40))
		pitch = math.clamp(pitch, -math.rad(22), math.rad(22))
		local t = os.clock()
		local breathe = player:GetAttribute("HoldingBreath") and 0 or math.sin(t * 1.6) * 0.03
		workspace.CurrentCamera.CFrame = view * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.new(0, breathe, 0)
	end)
end

return HidingCam
