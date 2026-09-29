--[[
	Ambience — small motions that make the house feel alive, animated locally:
	  Spinner (Model)       ceiling fans turning (attribute Speed, radians/s)
	  Swing (Model)         the grandfather clock's pendulum (Pivot, Axis, Amplitude, Period)
	  Sway (BasePart)       curtains moving at the open windows (Pivot = top edge)
	  Flicker (Light)       the TV's glow flickering while it's on
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Ambience = {}

local spinners = {}
local swings = {}
local sways = {}
local flickers = {}

local function partsOf(model: Instance)
	local out = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(out, d)
		end
	end
	return out
end

local function addSpinner(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local hub = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if not hub then
		return
	end
	-- spin about the world's vertical axis through the hub (the hub part itself is rotated)
	local base = CFrame.new(hub.Position)
	local rel = {}
	for _, p in partsOf(model) do
		if p.Name == "Blade" or p == hub then
			rel[p] = base:ToObjectSpace(p.CFrame)
		end
	end
	table.insert(spinners, { Model = model, Base = base, Rel = rel, Angle = math.random() * 6, Speed = model:GetAttribute("Speed") or 3 })
end

local function addSwing(model: Instance)
	local pivot = model:GetAttribute("Pivot")
	if typeof(pivot) ~= "Vector3" then
		return
	end
	local rel = {}
	for _, p in partsOf(model) do
		rel[p] = CFrame.new(-pivot) * p.CFrame
	end
	table.insert(swings, {
		Model = model,
		Pivot = pivot,
		Rel = rel,
		Axis = model:GetAttribute("Axis") or "X",
		Amp = math.rad(model:GetAttribute("Amplitude") or 10),
		Period = model:GetAttribute("Period") or 2,
	})
end

local function addSway(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local pivot = part:GetAttribute("Pivot")
	if typeof(pivot) ~= "Vector3" then
		pivot = part.Position + Vector3.new(0, part.Size.Y / 2, 0)
	end
	table.insert(sways, { Part = part, Pivot = pivot, Rel = CFrame.new(-pivot) * part.CFrame, Phase = math.random() * 6 })
end

local function addFlicker(light: Instance)
	if light:IsA("Light") then
		table.insert(flickers, { Light = light, Base = (light :: Light).Brightness })
	end
end

local function watch(tag: string, fn)
	for _, inst in CollectionService:GetTagged(tag) do
		fn(inst)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(fn)
end

local function prune(list, key)
	for i = #list, 1, -1 do
		if not list[i][key].Parent then
			table.remove(list, i)
		end
	end
end

function Ambience.init() end

function Ambience.start()
	watch("Spinner", addSpinner)
	watch("Swing", addSwing)
	watch("Sway", addSway)
	watch("Flicker", addFlicker)

	local pruneClock = 0
	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		local cam = workspace.CurrentCamera
		local camPos = cam and cam.CFrame.Position or Vector3.zero
		pruneClock += dt
		if pruneClock > 2 then
			pruneClock = 0
			prune(spinners, "Model")
			prune(swings, "Model")
			prune(sways, "Part")
			prune(flickers, "Light")
		end
		for _, s in spinners do
			s.Angle += s.Speed * dt
			if (s.Base.Position - camPos).Magnitude < 120 then
				local cf = s.Base * CFrame.Angles(0, s.Angle, 0)
				for p, rel in s.Rel do
					p.CFrame = cf * rel
				end
			end
		end
		for _, s in swings do
			local a = s.Amp * math.sin(t * math.pi * 2 / s.Period)
			local rot = s.Axis == "Z" and CFrame.Angles(0, 0, a) or CFrame.Angles(a, 0, 0)
			local cf = CFrame.new(s.Pivot) * rot
			for p, rel in s.Rel do
				p.CFrame = cf * rel
			end
		end
		for _, s in sways do
			local a = math.rad(5) * math.sin(t * 1.4 + s.Phase) + math.rad(2) * math.sin(t * 3.1 + s.Phase)
			s.Part.CFrame = CFrame.new(s.Pivot) * CFrame.Angles(a, 0, a * 0.6) * s.Rel
		end
		for _, f in flickers do
			if f.Light.Enabled then
				f.Light.Brightness = f.Base * (0.7 + math.noise(t * 4, f.Base) * 0.6 + 0.2)
			end
		end
	end)
end

return Ambience
