--[[
	Spectate — caught twice, you're out of the night: the camera follows the friends still
	playing (tap / click to switch). With nobody left, it looks at the house from the street.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Spectate = {}
local ctx
local player = Players.LocalPlayer

local label: TextLabel
local watching: Player? = nil
local active = false

local function living(): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p ~= player and p:GetAttribute("InGame") and not p:GetAttribute("Captured") and not p:GetAttribute("Escaped") then
			table.insert(list, p)
		end
	end
	return list
end

local function follow(p: Player?)
	local cam = workspace.CurrentCamera
	watching = p
	local hum = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = hum
		label.Text = "You didn't make it   ·   watching " .. (p :: Player).DisplayName .. "   ·   tap to switch"
	else
		-- nobody left inside: the house from across the street
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(Vector3.new(2, 9, -78), Vector3.new(2, 15, -30))
		label.Text = "You didn't make it"
	end
end

local function nextTarget()
	local list = living()
	if #list == 0 then
		follow(nil)
		return
	end
	local i = watching and table.find(list, watching) or 0
	follow(list[(i % #list) + 1])
end

local function refresh()
	local dead = player:GetAttribute("Dead") == true
	if dead == active then
		return
	end
	active = dead
	label.Visible = dead
	if dead then
		-- third person while watching
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMaxZoomDistance = 16
		player.CameraMinZoomDistance = 8
		task.delay(1.8, nextTarget)
	else
		watching = nil
		-- back in your own body: first person again
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 0.5
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Custom
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			cam.CameraSubject = hum
		end
	end
end

function Spectate.init(c)
	ctx = c
end

function Spectate.start()
	label = ctx.UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -36),
		Size = UDim2.new(0.9, 0, 0, 30),
		Text = "",
		TextSize = 18,
		TextColor3 = ctx.UI.Color.Text,
		TextStrokeTransparency = 0.4,
		Visible = false,
		Parent = ctx.UI.Root,
	})
	player:GetAttributeChangedSignal("Dead"):Connect(refresh)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not active or processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
			or input.KeyCode == Enum.KeyCode.ButtonA then
			nextTarget()
		end
	end)
	-- whoever we're watching gets caught or escapes: move on
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if not active or acc < 1 then
			return
		end
		acc = 0
		if watching and (not watching.Parent or watching:GetAttribute("Captured") or watching:GetAttribute("Escaped")) then
			nextTarget()
		elseif not watching and #living() > 0 then
			nextTarget()
		end
	end)
	refresh()
end

return Spectate
