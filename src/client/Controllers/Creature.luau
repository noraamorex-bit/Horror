--[[
	Creature — makes Curtis move like something that shouldn't (shared/CreaturePose), on every
	client, every frame: a bent-double sprint with flailing arms, a slow walk with the head
	cocked, the head snapping round for no reason. The server only moves his root and says
	which gait he's in (model attribute "Gait").

	And what being near him does: your flashlight stutters, lights around him flicker, the
	floor shakes with his strides when he's running at you.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Creature = {}
local ctx
local Pose

local model: Model? = nil
local motors: { [string]: Motor6D } = {}
local current: { [string]: CFrame } = {}
local root: BasePart? = nil
local phase = 0
local seed = math.random() * 100
local lookClock = 0

local function bind(m: Model?)
	model = m
	motors = {}
	current = {}
	root = nil
	if not m then
		return
	end
	for _, d in m:GetDescendants() do
		if d:IsA("Motor6D") then
			motors[d.Name] = d
		end
	end
	root = m:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function find()
	if model and model.Parent then
		return
	end
	local found = ctx.Util.creature()
	if found and found:IsA("Model") and found:GetAttribute("Creature") then
		bind(found)
	else
		bind(nil)
	end
end

-- brief stutters of a light, then back exactly as it was
local flickering: { [Light]: boolean } = {}
local function flicker(light: Light, strength: number)
	if flickering[light] then
		return
	end
	flickering[light] = true
	local base = light.Brightness
	task.spawn(function()
		local n = math.random(1, 3)
		for _ = 1, n do
			if not light.Parent then
				break
			end
			light.Brightness = base * (math.random() * (1 - strength))
			task.wait(0.04 + math.random() * 0.09)
			light.Brightness = base
			task.wait(0.03 + math.random() * 0.08)
		end
		light.Brightness = base
		flickering[light] = nil
	end)
end

local nearbyLights: { Light } = {}
local lightScan = 0
local duck, duckWant, duckClock = 0, 0, 0
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude

local function scanLights(at: Vector3)
	nearbyLights = {}
	local ok, parts = pcall(function()
		return workspace:GetPartBoundsInRadius(at, 26, overlap)
	end)
	if not ok then
		return
	end
	for _, p in parts do
		for _, c in p:GetChildren() do
			if c:IsA("Light") and c.Enabled then
				table.insert(nearbyLights, c)
			end
		end
	end
end

function Creature.init(c)
	ctx = c
	Pose = ctx.CreaturePose
end

function Creature.start()
	local lastStride = 0
	RunService.Stepped:Connect(function(_, dt)
		lookClock -= dt
		if lookClock <= 0 then
			lookClock = 1.5
			find()
		end
		if not model or not root or not root.Parent then
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local dist = (root.Position - cam.CFrame.Position).Magnitude
		if dist > 260 then
			return
		end
		local v = root.AssemblyLinearVelocity
		local speed = Vector3.new(v.X, 0, v.Z).Magnitude
		local gait = model:GetAttribute("Gait")
		if type(gait) ~= "string" then
			gait = speed > 12 and "Chase" or (speed > 0.6 and "Walk" or "Idle")
		end
		if (gait == "Walk") and speed < 0.4 then
			gait = "Idle"
		elseif gait == "Chase" and speed < 2 then
			gait = "Reach"
		end
		phase += speed * dt * Pose.phaseRate(gait)
		local t = os.clock()
		local target = Pose.get(gait, phase, t, seed)
		-- he has to stoop under door frames and low ceilings: bend at the hips and knees
		duckClock -= dt
		if duckClock <= 0 then
			duckClock = 0.1
			rayParams.FilterDescendantsInstances = { model }
			local top = root.Position.Y + 4.0 -- his hood, standing straight
			local hit = workspace:Raycast(root.Position, Vector3.new(0, 4.6, 0), rayParams)
				or workspace:Raycast(root.Position + root.CFrame.LookVector * 1.4, Vector3.new(0, 4.6, 0), rayParams)
			duckWant = hit and math.clamp(top - hit.Position.Y + 0.35, 0, 2.2) or 0
		end
		duck += (duckWant - duck) * (1 - math.exp(-dt * 10))
		if duck > 0.02 then
			local root0 = target.Root or CFrame.identity
			target.Root = CFrame.new(0, -duck * 0.45, 0) * root0 * CFrame.Angles(-duck * 0.3, 0, 0)
			target.Neck = (target.Neck or CFrame.identity) * CFrame.Angles(duck * 0.25, 0, 0)
			for _, hip in { "LeftHip", "RightHip" } do
				target[hip] = (target[hip] or CFrame.identity) * CFrame.Angles(duck * 0.3, 0, 0)
			end
		end
		local alpha = 1 - math.exp(-dt * 14)
		for name, motor in motors do
			local want = target[name] or CFrame.identity
			local cur = current[name] or CFrame.identity
			cur = cur:Lerp(want, alpha)
			current[name] = cur
			motor.Transform = cur
		end

		-- what it's like to be near him
		local player = Players.LocalPlayer
		if not player:GetAttribute("InGame") or player:GetAttribute("Captured") then
			return
		end
		-- every footfall shakes the floor when he's running at you
		if gait == "Chase" and dist < 34 then
			local stride = math.floor(phase / math.pi)
			if stride ~= lastStride then
				lastStride = stride
				if ctx.Effects then
					ctx.Effects.shake(0.35 * (1 - dist / 34) + 0.05, 0.12)
				end
			end
		end
		-- lights stutter around him; your flashlight too, when he's close
		lightScan -= dt
		if lightScan <= 0 then
			lightScan = 0.5
			overlap.FilterDescendantsInstances = { model }
			scanLights(root.Position)
		end
		for _, l in nearbyLights do
			if l.Parent and math.random() < dt * 1.6 then
				flicker(l, 0.9)
			end
		end
		if dist < 22 then
			local beamPart = workspace:FindFirstChild("LocalFlashlight")
			local beam = beamPart and beamPart:FindFirstChildOfClass("SpotLight")
			if beam and beam.Enabled and math.random() < dt * (gait == "Chase" and 5 or 2.2) * (1 - dist / 22) then
				flicker(beam, 0.95)
			end
		end
	end)
end

return Creature
