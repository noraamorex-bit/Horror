--[[
	Markers — a bobbing "!" over where each task's current step happens, with the distance.
	The current objective's marker is big and yellow; other tasks' markers are small and white.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Markers = {}
local ctx
local player = Players.LocalPlayer

local folder: Folder
local active = {} -- { {Part, Gui, Dist, Big} }

local function clear()
	for _, m in active do
		m.Part:Destroy()
	end
	active = {}
end

local function make(pos: Vector3, big: boolean)
	local UI = ctx.UI
	local part = Instance.new("Part")
	part.Name = "Marker"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(pos)
	part.Parent = folder
	local size = big and 46 or 30
	local gui = UI.new("BillboardGui", {
		Name = "Marker",
		AlwaysOnTop = true,
		LightInfluence = 0,
		Size = UDim2.fromOffset(size + 40, size + 24),
		StudsOffset = Vector3.new(0, 1.6, 0),
		Adornee = part,
		MaxDistance = 400,
		Parent = part,
	})
	local badge = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Color3.fromRGB(235, 235, 235),
		BackgroundTransparency = 0.05,
		Parent = gui,
	})
	UI.corner(badge, 999)
	UI.stroke(badge, Color3.new(0, 0, 0), 2, 0.4)
	UI.label({ Size = UDim2.fromScale(1, 1), Text = "!", Font = UI.Font.Bold, TextScaled = true, TextColor3 = Color3.fromRGB(25, 20, 10), Parent = badge })
	local dist = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, size + 2),
		Size = UDim2.fromOffset(size + 40, 18),
		Text = "",
		Font = UI.Font.Bold,
		TextSize = 14,
		TextStrokeTransparency = 0.3,
		Parent = gui,
	})
	table.insert(active, { Part = part, Gui = gui, Badge = badge, Dist = dist, Big = big, Base = pos, Phase = math.random() * 6 })
end

local function render(list)
	clear()
	local focus = ctx.HUD and ctx.HUD.focusObjective() or nil
	for _, o in list do
		if not o.Done and o.Targets then
			for _, pos in o.Targets do
				make(pos, focus ~= nil and o.Id == focus.Id)
			end
		end
	end
end

function Markers.init(c)
	ctx = c
end

function Markers.start()
	-- a prompt on screen wins: markers step aside so their "!" and distance never sit on top of it
	local PPS = game:GetService("ProximityPromptService")
	local promptsShown = 0
	PPS.PromptShown:Connect(function()
		promptsShown += 1
	end)
	PPS.PromptHidden:Connect(function()
		promptsShown = math.max(0, promptsShown - 1)
	end)
	folder = Instance.new("Folder")
	folder.Name = "ObjectiveMarkers"
	folder.Parent = workspace
	ctx.Remotes.Objectives.OnClientEvent:Connect(function(list)
		-- let the HUD update its focus first
		task.defer(render, list)
	end)
	RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local show = player:GetAttribute("InGame") == true and not player:GetAttribute("Hiding") and not player:GetAttribute("Captured")
			and not workspace:GetAttribute("EndingActive") and promptsShown == 0
		local t = os.clock()
		for _, m in active do
			m.Gui.Enabled = show
			if show then
				local d = (cam.CFrame.Position - m.Base).Magnitude
				m.Gui.StudsOffset = Vector3.new(0, 1.6 + math.sin(t * 3 + m.Phase) * 0.25, 0)
				m.Dist.Text = d > 8 and (math.floor(d) .. "m") or ""
				-- fade out when you're right on top of it, so it never hides what you're looking at
				local near = math.clamp((d - 4) / 6, 0.25, 1)
				m.Badge.BackgroundTransparency = 1 - near * 0.95
				for _, c in m.Badge:GetChildren() do
					if c:IsA("TextLabel") then
						c.TextTransparency = 1 - near
					end
				end
			end
		end
	end)
end

return Markers
