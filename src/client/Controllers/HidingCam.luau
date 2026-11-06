--[[
	HidingCam — the fixed peek camera while hidden (look around a little with the mouse
	or by dragging), hold breath, leave; and struggling while captured.

	v147 PEEK (hold R / the PEEK button): the eye eases out from HideView to HidePeek (a lean with
	a tilt of the head and a breath held, wider to look round), the server opens a wardrobe a
	crack. While his eyes are on you ("PeekWatched") the screen bleeds red and your heart thumps:
	duck back in before he's sure.
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
local peekWant = false -- the key / button is held
local peekK = 0 -- how far out the eye is (0 in, 1 out)
local peekSide = 1 -- which way the head tilts as you lean (by where the way out is)
local watchTint: ColorCorrectionEffect? = nil
local watchK = 0
local thump: Sound? = nil
local enterFrom: CFrame? = nil -- (getting in: the eye eases from where it was into the spot)
local enterAt = 0

local function setPeek(on: boolean)
	if on and (not player:GetAttribute("Hiding") or (ctx.HeartbeatUI and ctx.HeartbeatUI.isActive())) then
		on = false
	end
	if on == peekWant then
		return
	end
	peekWant = on
	ctx.Remotes.Peek:FireServer(on)
end

local function onHideChanged()
	local view = player:GetAttribute("HideView")
	local cam = workspace.CurrentCamera
	if typeof(view) == "CFrame" then
		if not active then
			enterFrom = cam.CFrame
			enterAt = os.clock()
		end
		active = true
		yaw, pitch = 0, 0
		peekK = 0
		local peek = player:GetAttribute("HidePeek")
		if typeof(peek) == "CFrame" then
			local side = view:PointToObjectSpace(peek.Position).X
			peekSide = side < -0.2 and -1 or 1
		end
		cam.CameraType = Enum.CameraType.Scriptable
		cam.FieldOfView = 62
	elseif active then
		active = false
		peekWant = false
		peekK = 0
		watchK = 0
		if watchTint then
			watchTint:Destroy()
			watchTint = nil
		end
		if thump then
			thump:Destroy()
			thump = nil
		end
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
	ctx.Input.on("Peek", function(began)
		setPeek(began)
	end)
	-- (he stopped at your door: the server pulls you back in; keep the client in step)
	player:GetAttributeChangedSignal("Peeking"):Connect(function()
		if not player:GetAttribute("Peeking") then
			peekWant = false
		end
	end)
	ctx.Input.on("ExitHide", function(began)
		-- (not while he's listening at the door: E is a heartbeat key then, and stepping out
		-- right in front of him would be the end)
		if ctx.HeartbeatUI and ctx.HeartbeatUI.isActive() then
			return
		end
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

	RunService:BindToRenderStep("HomeAloneHideCam", Enum.RenderPriority.Camera.Value, function(frameDt: number)
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
		local dt = math.min(frameDt, 0.1)
		-- lean out slowly (careful), duck back fast
		local want = (peekWant and player:GetAttribute("Peeking")) and 1 or 0
		local rate = want > peekK and 2.6 or 5
		peekK = math.clamp(peekK + math.sign(want - peekK) * rate * dt, 0, 1)
		if math.abs(want - peekK) < 0.01 then
			peekK = want
		end
		local e = peekK * peekK * (3 - 2 * peekK) -- smoothstep
		local yawMax = math.rad(40 + 30 * e)
		local pitchMax = math.rad(22 + 14 * e)
		yaw = math.clamp(yaw, -yawMax, yawMax)
		pitch = math.clamp(pitch, -pitchMax, pitchMax)
		local t = os.clock()
		local breathe = player:GetAttribute("HoldingBreath") and 0 or math.sin(t * 1.6) * 0.03 * (1 - 0.6 * e)
		local base = view
		local peek = player:GetAttribute("HidePeek")
		if typeof(peek) == "CFrame" and e > 0 then
			base = view:Lerp(peek, e)
		end
		-- the lean: the head tilts towards the way out and dips a touch at the middle of the move
		local roll = -peekSide * math.rad(9) * math.sin(e * math.pi) + -peekSide * math.rad(3) * e
		local dip = -0.12 * math.sin(e * math.pi)
		-- a tremble while he's looking straight at you
		local tremble = watchK > 0 and CFrame.new(math.noise(t * 9, 1) * 0.03 * watchK, math.noise(t * 9, 2) * 0.03 * watchK, 0) or CFrame.new()
		-- (ducking in: 0.4 s from where you stood, down into the spot)
		if enterFrom then
			local k = math.clamp((os.clock() - enterAt) / 0.4, 0, 1)
			if k >= 1 then
				enterFrom = nil
			else
				base = enterFrom:Lerp(base, 1 - (1 - k) ^ 3)
			end
		end
		workspace.CurrentCamera.CFrame = base * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, 0, roll) * CFrame.new(0, breathe + dip, 0) * tremble
		-- his eyes on you: a red bleed and a heart that won't slow down
		local watched = player:GetAttribute("PeekWatched") == true
		watchK = math.clamp(watchK + (watched and 4 or -2.5) * dt, 0, 1)
		if watchK > 0 and not watchTint then
			local cc = Instance.new("ColorCorrectionEffect")
			cc.Name = "PeekWatch"
			cc.Parent = game:GetService("Lighting")
			watchTint = cc
		end
		if watchTint then
			watchTint.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(255, 150, 150), watchK)
			watchTint.Saturation = -0.3 * watchK
			watchTint.Contrast = 0.15 * watchK
			if watchK <= 0 then
				watchTint:Destroy()
				watchTint = nil
			end
		end
		if watched and not thump then
			local def = ctx.Sounds.get("Heartbeat")
			if def then
				local snd = Instance.new("Sound")
				snd.Name = "PeekHeart"
				snd.SoundId = ctx.Sounds.resolve("Heartbeat")
				snd.Looped = true
				snd.PlaybackSpeed = 1.35
				snd.Volume = ctx.Sounds.volume("Heartbeat", 0.9)
				snd.Parent = game:GetService("SoundService")
				snd:Play()
				thump = snd
			end
		elseif not watched and thump then
			thump:Destroy()
			thump = nil
		end
	end)
end

return HidingCam
