--[[
	Cutscene — short cinematics in the middle of the night (server: CutsceneService): the lights
	going out, him under the garage hatch, you tied to the pipes. Letterbox bars, a slow camera
	move per shot, a line of subtitle; the HUD and touch buttons step aside while it plays.
	Afterwards the camera goes back to whatever it was doing (your eyes, or a hiding spot).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
	local top = UI.new("Frame", { Name = "CutTop", Size = UDim2.new(1, 0, 0.12, 0), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 30, Parent = UI.Top })
	local bottom = UI.new("Frame", { Name = "CutBottom", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0.14, 0), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 30, Parent = UI.Top })
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
			local t0 = os.clock()
			while os.clock() - t0 < dur and mine == token and not workspace:GetAttribute("EndingActive") do
				local k = math.clamp((os.clock() - t0) / dur, 0, 1)
				local e = k * k * (3 - 2 * k)
				cam.CFrame = from:Lerp(to, e)
				RunService.RenderStepped:Wait()
			end
		end
	end
	if mine ~= token then
		top:Destroy()
		bottom:Destroy()
		return
	end
	if ctx.Effects then
		ctx.Effects.fade(true, 0.3)
	end
	task.wait(0.3)
	top:Destroy()
	bottom:Destroy()
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
		end
	end)
end

return Cutscene
