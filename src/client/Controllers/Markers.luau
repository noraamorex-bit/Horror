--[[
	Markers — a bobbing "!" over where each task's current step happens, with the distance.
	The current objective's marker is big and yellow; other tasks' markers are small and white.
	When the current one is off screen, a small arrow at the edge points the way (the logs: half of
	the solo phone players never found the pizza menu on the fridge).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Markers = {}
local ctx
local player = Players.LocalPlayer

local folder: Folder
local active = {} -- { {Part, Gui, Dist, Big} }
local pointer: Frame? = nil -- the edge arrow for the current objective
local chevron: TextLabel? = nil

local function makePointer()
	local UI = ctx.UI
	local f = UI.new("Frame", {
		Name = "ObjectivePointer",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Color3.fromRGB(14, 14, 16),
		BackgroundTransparency = 0.25,
		Visible = false,
		Parent = UI.Root,
	})
	UI.corner(f, 999)
	UI.stroke(f, Color3.new(1, 1, 1), 1.5, 0.35)
	chevron = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Text = ">",
		Font = UI.Font.Bold,
		TextSize = 22,
		TextColor3 = Color3.fromRGB(240, 240, 240),
		Parent = f,
	})
	pointer = f
end

-- where the arrow goes: on an ellipse near the screen's edges, in the target's direction (kept off
-- the objective panel at the top and the touch controls at the bottom); nil when it's on screen
function Markers.pointerFor(camCF: CFrame, viewport: Vector2, target: Vector3, onScreen: boolean, screenPos: Vector3): (number?, number?, number?)
	local margin = 0.07
	if onScreen and screenPos.Z > 0 and screenPos.X > viewport.X * margin and screenPos.X < viewport.X * (1 - margin)
		and screenPos.Y > viewport.Y * margin and screenPos.Y < viewport.Y * (1 - margin) then
		return nil
	end
	local rel = camCF:PointToObjectSpace(target)
	local dx, dy = rel.X, -rel.Y
	if math.abs(dx) < 1e-3 and math.abs(dy) < 1e-3 then
		dx = 1
	end
	-- (behind you: point to the side to turn towards, never straight up or down)
	if rel.Z > 0 and math.abs(dx) < math.abs(dy) then
		dx = if dx >= 0 then math.abs(dy) else -math.abs(dy)
	end
	local a = math.atan2(dy, dx)
	local x = 0.5 + 0.42 * math.cos(a)
	local y = math.clamp(0.5 + 0.32 * math.sin(a), 0.24, 0.8)
	return x, y, math.deg(a)
end

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
	makePointer()
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
		local pointTo = nil
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
				if m.Big and d > 10 and (not pointTo or d < pointTo.D) then
					pointTo = { Pos = m.Base + Vector3.new(0, 1.6, 0), D = d }
				end
			end
		end
		if pointer then
			local x, y, rot = nil, nil, nil
			if pointTo then
				local sp, on = cam:WorldToViewportPoint(pointTo.Pos)
				x, y, rot = Markers.pointerFor(cam.CFrame, cam.ViewportSize, pointTo.Pos, on, sp)
			end
			pointer.Visible = x ~= nil
			if x and y and rot and chevron then
				pointer.Position = UDim2.fromScale(x, y)
				chevron.Rotation = rot
			end
		end
	end)
end

return Markers
