--[[
	Signs — what he leaves behind (v99). At the blackout, wet footprints appear on the upstairs
	hall floor, coming from under the attic hatch: long and narrow, three toes, far too far apart
	for anyone in this family. Built into the night's World folder, so the next night starts clean.

		Signs.footprints(parent) -> Folder

	And (v106) the bathroom mirror after you brush your teeth: the glass steams up, and in the steam,
	written with a finger from the other side of you, a line (Story.Mirror).

		Signs.mirror(glass, viewer, text, hold?)
]]

local Signs = {}

local V = Vector3.new
local CF = CFrame.new

local WET = Color3.fromRGB(30, 25, 21)
local FLOOR_TOP = 15.0 -- the upstairs hall floor (Layout.Y.Upstairs; its planks' top face)

-- the trail: from under the hatch (Layout.AtticHatch, x 4-8, z 8-14) along the hall towards the
-- front of the house, stopping short of the rug (x 0.5-5.5, z -27..-9)
local FROM, TO = V(6.0, 0, 10.5), V(4.0, 0, -7.6)
local STRIDE = 2.3

function Signs.footprints(parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Footprints"
	local dir = Vector3.new(TO.X - FROM.X, 0, TO.Z - FROM.Z)
	local len = dir.Magnitude
	local fwd = dir.Unit
	local right = V(-fwd.Z, 0, fwd.X)
	local yaw = math.atan2(-fwd.X, -fwd.Z)
	local function print1(at: Vector3, fade: number)
		local base = CF(at.X, FLOOR_TOP + 0.011, at.Z) * CFrame.Angles(0, yaw, 0)
		local function bit(name: string, size: Vector3, cf: CFrame)
			local p = Instance.new("Part")
			p.Name = name
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Material = Enum.Material.SmoothPlastic
			p.Reflectance = 0.08
			p.Color = WET
			p.Transparency = 0.12 + fade
			p.Size = size
			p.CFrame = cf
			p.Parent = folder
		end
		-- the sole: long and narrow, the heel a little wider
		bit("Print", V(0.32, 0.02, 0.85), base * CF(0, 0, 0.05))
		bit("Print", V(0.38, 0.02, 0.32), base * CF(0, 0, 0.42))
		-- three toes, splayed, each ending in a scrape
		for i, a in { -0.32, 0, 0.32 } do
			local toe = base * CFrame.Angles(0, -a, 0) * CF(0, 0, -0.62 - (i == 2 and 0.06 or 0))
			bit("Print", V(0.08, 0.02, 0.42), toe)
		end
	end
	local i = 0
	local d = 0.6
	while d < len - 0.3 do
		local side = i % 2 == 0 and -1 or 1
		local at = FROM + fwd * d + right * side * 0.38
		-- (drying out as they go: the last few are fainter)
		print1(at, math.clamp((d / len - 0.6) * 1.2, 0, 0.45))
		d += STRIDE
		i += 1
	end
	folder.Parent = parent
	return folder
end

-- steam on a mirror, and words wiped into it (shown from the side the viewer is on)
function Signs.mirror(glass: BasePart, viewer: Vector3, text: string, hold: number?)
	if glass:FindFirstChild("MirrorWriting") then
		return
	end
	local TweenService = game:GetService("TweenService")
	local gui = Instance.new("SurfaceGui")
	gui.Name = "MirrorWriting"
	gui.Face = glass.CFrame.LookVector:Dot(viewer - glass.Position) >= 0 and Enum.NormalId.Front or Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 80
	gui.LightInfluence = 1
	gui.Adornee = glass
	local fog = Instance.new("Frame")
	fog.Size = UDim2.fromScale(1, 1)
	fog.BackgroundColor3 = Color3.fromRGB(226, 230, 232)
	fog.BackgroundTransparency = 1
	fog.BorderSizePixel = 0
	fog.Parent = gui
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.86, 0.7)
	label.Rotation = -4
	label.Text = text
	label.TextScaled = true
	label.TextWrapped = true
	pcall(function()
		label.Font = Enum.Font.PermanentMarker
	end)
	label.TextColor3 = Color3.fromRGB(62, 70, 76)
	label.TextTransparency = 1
	label.Parent = fog
	gui.Parent = glass
	TweenService:Create(fog, TweenInfo.new(2.4), { BackgroundTransparency = 0.42 }):Play()
	task.delay(2.3, function()
		if label.Parent then
			TweenService:Create(label, TweenInfo.new(1.6), { TextTransparency = 0.15 }):Play()
		end
	end)
	task.delay(hold or 45, function()
		if gui.Parent then
			TweenService:Create(fog, TweenInfo.new(6), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(label, TweenInfo.new(6), { TextTransparency = 1 }):Play()
			task.wait(6.5)
			gui:Destroy()
		end
	end)
	return gui
end

return Signs
