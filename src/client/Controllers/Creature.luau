--[[
	Creature — makes Curtis move like something that shouldn't (shared/CreaturePose), on every
	client: a run on all fours, a slow hunched walk with the head lolling, the head snapping (and
	now and then turning right round), all of it played back in jerky stop-motion steps. The server only moves his root and says
	which gait he's in (model attribute "Gait").

	And what being near him does: your flashlight stutters, lights around him flicker, the
	floor shakes with his strides when he's running at you.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Creature = {}
local ctx
local Pose
local Skin

local model: Model? = nil
local motors: { [string]: Motor6D } = {}
local current: { [string]: CFrame } = {}
local root: BasePart? = nil
local phase = 0
local seed = math.random() * 100
local lookClock = 0
local jawList = {}
local jaw = 0
local screamUntil = 0
-- (v112) the skinned body: its rig (SkinPose.rig), the gait it's blending out of, how far along
local skin = nil
local skinFromGait = ""
local skinGait = ""
local skinBlend = 1
local look = { 0, 0 }
local scream = 0
local skinRigs: { [Instance]: any } = setmetatable({}, { __mode = "k" }) :: any

-- the skeleton of a model's skinned body (cached), or nil if it's the part-built figure
local function skinOf(m: Instance): any
	local cached = skinRigs[m]
	if cached ~= nil then
		return cached or nil
	end
	local body = m:FindFirstChild("Body")
	local rig = false
	if body and body:IsA("MeshPart") and m:GetAttribute("Skinned") then
		local ok, r = pcall(Skin.rig, body)
		rig = ok and r or false
	end
	-- (v114) the porcelain mask and hair (the part-built Head and what's welded to it) ride the head
	-- bone: where the Head part sits relative to the bone at rest, both worked out from rest frames
	local head = m:FindFirstChild("Head")
	local neck = head and head:FindFirstChild("Neck")
	local bone = body and body:FindFirstChild("spine_006_0", true)
	if rig and m:GetAttribute("Masked") and neck and neck:IsA("Motor6D") and neck.Part0 and bone and bone:IsA("Bone") then
		local restHead = neck.Part0.CFrame * neck.C0 * neck.C1:Inverse()
		rig.Mask = { Neck = neck, Bone = bone, Rel = bone.WorldCFrame:ToObjectSpace(restHead), Jaw = Pose.jawMeshes(m) }
	end
	skinRigs[m] = rig
	return rig or nil
end

local function applySkin(rig, pose)
	for bone, cf in Skin.transforms(rig, pose) do
		bone.Transform = cf
	end
	local mk = rig.Mask
	if mk then
		-- the neck joint turned so the Head part lands where the posed head bone puts it
		local neck: Motor6D = mk.Neck
		local p0 = neck.Part0
		if p0 then
			local want = mk.Bone.TransformedWorldCFrame * mk.Rel
			neck.Transform = neck.C0:Inverse() * p0.CFrame:Inverse() * want * neck.C1
		end
		Pose.setJaw(mk.Jaw, math.clamp((pose.Mouth or 0) * 1.2, 0, 1))
	end
end

local function bind(m: Model?)
	model = m
	motors = {}
	current = {}
	root = nil
	jawList = {}
	skin = nil
	skinGait = ""
	if not m then
		return
	end
	jawList = Pose.jawMeshes(m)
	skin = skinOf(m)
	-- (v102: in the house he wears a faint pale outline and fill wherever you can actually see
	-- him, never through walls, so he reads in the dark; not in the lobby, where he's a shape in
	-- the fog)
	if ctx.Mode ~= "Lobby" and not m:FindFirstChild("SeeHim") then
		local hl = Instance.new("Highlight")
		hl.Name = "SeeHim"
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.FillColor = Color3.fromRGB(120, 128, 155)
		hl.FillTransparency = 0.82
		hl.OutlineColor = Color3.fromRGB(190, 198, 222)
		hl.OutlineTransparency = 0.45
		hl.Adornee = m
		hl.Parent = m
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
local frameHold = 0
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
	Skin = ctx.SkinPose
	ctx.Creature = Creature
end

-- his mouth wide open for a moment (the jumpscare)
function Creature.scream(duration: number)
	screamUntil = os.clock() + duration
end

-- (v112) where the jumpscare camera looks, as a function returning a frame that faces out of
-- him: the skinned body's maw (from the face down the throat), following its bones; nil for the
-- part-built figure (the camera uses its Head)
function Creature.focusFor(part: Instance?): (() -> CFrame)?
	local m = part and part:FindFirstAncestorOfClass("Model")
	local rig = m and skinOf(m)
	if not rig then
		return nil
	end
	local body = (m :: Model):FindFirstChild("Body") :: BasePart
	local neck = body:FindFirstChild("spine_004_2", true) :: Bone?
	local head = body:FindFirstChild("spine_006_0", true) :: Bone?
	if not neck or not head then
		return nil
	end
	local mask = (m :: Model):GetAttribute("Masked") and (m :: Model):FindFirstChild("Head") :: BasePart?
	return function()
		-- (v114: his face is the mask again; before, the maw down his throat)
		local at = mask and mask.Position or neck.TransformedWorldCFrame.Position:Lerp(head.TransformedWorldCFrame.Position, 0.35)
		local fwd = body.CFrame.LookVector
		return CFrame.lookAt(at, at + Vector3.new(fwd.X, 0, fwd.Z))
	end
end

-- (v112) pose a copy of him (a figure only you see): true if it has the skinned body
function Creature.poseCopy(copy: Instance, gait: string, t: number, seed: number): boolean
	local rig = skinOf(copy)
	if not rig then
		return false
	end
	applySkin(rig, Skin.get(gait, 0, t, seed, { Scale = Skin.Scale }))
	return true
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
		local t = os.clock()
		if skin then
			phase += speed * dt * Skin.phaseRate(gait)
			-- (v112) the skinned body: smooth, every frame, blending from one gait into the next
			if gait ~= skinGait then
				if skinGait ~= "" then
					skinFromGait = skinGait
					skinBlend = 0
				end
				skinGait = gait
			end
			-- stooping under door frames and low ceilings
			duckClock -= dt
			if duckClock <= 0 then
				duckClock = 0.1
				rayParams.FilterDescendantsInstances = { model }
				local top = root.Position.Y + 4.4 -- (the top of his head, hunched)
				local hit = workspace:Raycast(root.Position, Vector3.new(0, 5.4, 0), rayParams)
					or workspace:Raycast(root.Position + root.CFrame.LookVector * 1.6, Vector3.new(0, 5.4, 0), rayParams)
				duckWant = hit and math.clamp(top - hit.Position.Y + 0.35, 0, 3.0) or 0
			end
			duck += (duckWant - duck) * (1 - math.exp(-dt * 8))
			-- his head turns to follow you when you're near and he isn't running
			local wantYaw, wantPitch = 0, 0
			local rel = root.CFrame:PointToObjectSpace(cam.CFrame.Position)
			if dist < 45 and gait ~= "Chase" and gait ~= "Stunned" and rel.Z < 2 then
				wantYaw = math.clamp(math.atan2(-rel.X, -rel.Z), -1.3, 1.3)
				wantPitch = math.clamp(math.atan2(rel.Y - 3.6, math.sqrt(rel.X * rel.X + rel.Z * rel.Z)), -0.6, 0.5)
			end
			local kl = 1 - math.exp(-dt * 3.5)
			look[1] += (wantYaw - look[1]) * kl
			look[2] += (wantPitch - look[2]) * kl
			local screaming = os.clock() < screamUntil
			scream += ((screaming and 1 or 0) - scream) * (1 - math.exp(-dt * (screaming and 30 or 4)))
			local opts = { Look = look, Duck = math.clamp(duck / 1.6, 0, 1.6), Scream = scream }
			local P = Skin.sample(gait, phase, t, seed, opts)
			if skinBlend < 1 then
				skinBlend = math.min(1, skinBlend + dt / 0.3)
				local w = skinBlend * skinBlend * (3 - 2 * skinBlend)
				P = Skin.blend(Skin.sample(skinFromGait, phase, t, seed, opts), P, w)
			end
			-- (far off, a few times a second is plenty)
			frameHold -= dt
			if dist < 70 or frameHold <= 0 then
				frameHold = 1 / 12
				applySkin(skin, Skin.toPose(P, Skin.Scale))
			end
		else
			phase += speed * dt * Pose.phaseRate(gait)
			local target = Pose.get(gait, phase, t, seed)
			-- he has to stoop under door frames and low ceilings: bend at the hips and knees
			duckClock -= dt
			if duckClock <= 0 then
				duckClock = 0.1
				rayParams.FilterDescendantsInstances = { model }
				local top = root.Position.Y + 4.6 -- the top of his head, walking hunched (Rig.Height 9.9 standing)
				local hit = workspace:Raycast(root.Position, Vector3.new(0, 5.4, 0), rayParams)
					or workspace:Raycast(root.Position + root.CFrame.LookVector * 1.6, Vector3.new(0, 5.4, 0), rayParams)
				duckWant = hit and math.clamp(top - hit.Position.Y + 0.35, 0, 3.0) or 0
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
			-- played back like stop-motion: each pose held for a few frames, then the next (12-18 a
			-- second, unevenly), so his limbs jerk from one position to the next like a puppet's
			-- while he glides along
			frameHold -= dt
			if frameHold <= 0 then
				frameHold = 1 / 18 + math.random() * (1 / 12 - 1 / 18)
				for name, motor in motors do
					local want = target[name] or CFrame.identity
					local cur = current[name] or CFrame.identity
					cur = cur:Lerp(want, 0.8)
					current[name] = cur
					motor.Transform = cur
				end
				-- the mouth: snapping between positions with everything else
				local want = os.clock() < screamUntil and 1 or Pose.jaw(gait, t, seed)
				jaw += (want - jaw) * 0.7
				Pose.setJaw(jawList, jaw)
			end
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
