--[[
	Delivery — the pizza arrives. A little car pulls up in the rain, the delivery man walks up
	to the porch and rings, and whoever answers talks to him through a dialogue with choices.
	He is just a strange man on his last run of the night (see Story.Truths.PizzaGuy).

	Delivery.run(ctx, D, onDone)  -- yields until he has driven away (or the world is rebuilt)
]]

local TweenService = game:GetService("TweenService")

local Kit = require(script.Parent.Parent.World.Kit)

local Delivery = {}

local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles

local PORCH = V(2, 1, -34.3)
local ANSWER_TIMEOUT = 75

-- the route from the car door to the porch (feet positions)
local ROUTE = { V(-5, 0.45, -71.4), V(1.2, 0.75, -67), V(2, 0.6, -61), V(2, 0.6, -41), V(2, 1, -38.4), PORCH }

local function alive(folder: Instance): boolean
	return folder.Parent ~= nil
end

local function tweenModel(model: Model, goal: CFrame, t: number, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local value = Instance.new("CFrameValue")
	value.Value = model:GetPivot()
	value.Changed:Connect(function(cf)
		if model.Parent then
			model:PivotTo(cf)
		end
	end)
	local tw = TweenService:Create(value, TweenInfo.new(t, style or Enum.EasingStyle.Linear, dir or Enum.EasingDirection.Out), { Value = goal })
	tw:Play()
	tw.Completed:Wait()
	value:Destroy()
end

-- walk a list of points at a steady pace, facing where he's going
local function walk(model: Model, points, speed: number, folder: Instance)
	for i = 2, #points do
		if not alive(folder) then
			return
		end
		local a, b = points[i - 1], points[i]
		local flat = V(b.X - a.X, 0, b.Z - a.Z)
		local look = flat.Magnitude > 0.05 and flat.Unit or V(0, 0, 1)
		model:PivotTo(CFrame.lookAt(a, a + look))
		tweenModel(model, CFrame.lookAt(b, b + look), (b - a).Magnitude / speed)
	end
end

-- The delivery man is a real R15 Rthro avatar (Roblox's "City Life Man" body, pale, stretched
-- tall and thin, a red cap, arms held out with the pizza bag, and a fixed wide grin on the
-- dynamic head). If the avatar can't be loaded, the part-built Kit model stands in.
local AVATAR = {
	Head = 71693744825093, -- City Life Man - Head (dynamic)
	Torso = 2490661289,
	LeftArm = 2490651894,
	RightArm = 2490659002,
	LeftLeg = 2490653036,
	RightLeg = 2490660219,
	Hair = 2490665888,
	Hat = 1028606, -- Red Baseball Cap
}
local WALK_ANIM = "rbxassetid://2510202577" -- Rthro Walk
local SKIN = Color3.fromRGB(196, 190, 184)
-- the face he holds the whole time: a wide, unblinking grin
local FACE = {
	LeftLipCornerPuller = 1, RightLipCornerPuller = 1,
	LeftLipStretcher = 0.6, RightLipStretcher = 0.6,
	LeftUpperLipRaiser = 0.45, RightUpperLipRaiser = 0.45,
	LeftEyeUpperLidRaiser = 1, RightEyeUpperLidRaiser = 1,
	LeftInnerBrowRaiser = 0.5, RightInnerBrowRaiser = 0.5,
	LeftCheekRaiser = 0.35, RightCheekRaiser = 0.35,
}

local function avatarActor(folder: Instance, start: CFrame)
	local Players = game:GetService("Players")
	local desc = Instance.new("HumanoidDescription")
	desc.Head = AVATAR.Head
	desc.Torso = AVATAR.Torso
	desc.LeftArm = AVATAR.LeftArm
	desc.RightArm = AVATAR.RightArm
	desc.LeftLeg = AVATAR.LeftLeg
	desc.RightLeg = AVATAR.RightLeg
	desc.HairAccessory = tostring(AVATAR.Hair)
	desc.HatAccessory = tostring(AVATAR.Hat)
	desc.HeadColor = SKIN
	desc.TorsoColor = SKIN
	desc.LeftArmColor = SKIN
	desc.RightArmColor = SKIN
	desc.LeftLegColor = SKIN
	desc.RightLegColor = SKIN
	desc.HeightScale = 1.12
	desc.WidthScale = 0.84
	desc.DepthScale = 0.9
	desc.HeadScale = 1
	desc.BodyTypeScale = 1
	desc.ProportionScale = 1
	local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local head = model:FindFirstChild("Head") :: BasePart
	local torso = model:FindFirstChild("UpperTorso") :: BasePart
	assert(hum and root and head and torso, "avatar is missing parts")
	model.Name = "PizzaGuy"
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.WalkSpeed = 6.5
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	local feetOffset = hum.HipHeight + root.Size.Y / 2
	model:PivotTo(start * CFrame.new(0, feetOffset, 0))
	model.Parent = folder
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	-- the face
	local fc = head:FindFirstChildWhichIsA("FaceControls", true)
	if fc then
		for k, v in FACE do
			pcall(function()
				(fc :: any)[k] = v
			end)
		end
	end
	-- arms held out in front, carrying the insulated bag
	for _, name in { "RightShoulder", "LeftShoulder" } do
		local joint = model:FindFirstChild(name, true)
		if joint and joint:IsA("Motor6D") then
			joint.C0 = joint.C0 * ANG(math.rad(78), 0, 0)
		end
	end
	for _, name in { "RightElbow", "LeftElbow" } do
		local joint = model:FindFirstChild(name, true)
		if joint and joint:IsA("Motor6D") then
			joint.C0 = joint.C0 * ANG(math.rad(12), 0, 0)
		end
	end
	Kit.soft(model, "PizzaBag", torso.CFrame * CF(0, -0.9, -2.3), V(2.5, 0.6, 2.5), 0.1, Color3.fromRGB(150, 28, 26), Kit.M.Fabric)
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") and p.Name == "PizzaBag" then
			p.Anchored = false
			p.Massless = true
			p.CanCollide = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = torso
			weld.Part1 = p
			weld.Parent = p
		end
	end
	local neck = head:FindFirstChild("Neck") :: Motor6D?
	local neckC0 = neck and neck.C0
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local walkTrack
	pcall(function()
		local anim = Instance.new("Animation")
		anim.AnimationId = WALK_ANIM
		walkTrack = (animator :: Animator):LoadAnimation(anim)
		walkTrack.Looped = true
	end)

	local actor = { Model = model }
	function actor.pivot(): CFrame
		return root.CFrame * CFrame.new(0, -feetOffset, 0)
	end
	local function moveTo(target: Vector3)
		local flat = V(target.X, root.Position.Y, target.Z)
		local dist = (flat - root.Position).Magnitude
		hum:MoveTo(target)
		local deadline = os.clock() + dist / hum.WalkSpeed + 3
		while folder.Parent and os.clock() < deadline do
			if (V(target.X, 0, target.Z) - V(root.Position.X, 0, root.Position.Z)).Magnitude < 1.2 then
				break
			end
			task.wait(0.1)
		end
	end
	function actor.walk(points)
		hum.AutoRotate = true
		if walkTrack then
			walkTrack:Play(0.2)
			walkTrack:AdjustSpeed(0.8)
		end
		for i = 2, #points do
			moveTo(points[i])
		end
		if walkTrack then
			walkTrack:Stop(0.3)
		end
	end
	function actor.face(dir: Vector3)
		hum.AutoRotate = false
		root.CFrame = CFrame.lookAt(root.Position, root.Position + V(dir.X, 0, dir.Z))
	end
	function actor.head(yaw: number, tilt: number)
		if neck and neckC0 then
			neck.C0 = neckC0 * ANG(0, yaw, tilt)
		end
	end
	function actor.backAway(dist: number)
		hum.AutoRotate = false
		local target = root.Position - root.CFrame.LookVector * dist
		if walkTrack then
			walkTrack:Play(0.2)
			walkTrack:AdjustSpeed(-0.6)
		end
		moveTo(target)
		if walkTrack then
			walkTrack:Stop(0.3)
		end
	end
	return actor
end

local function partsActor(folder: Instance, start: CFrame)
	local man, headModel, neck = Kit.deliveryMan(folder, start)
	local actor = { Model = man }
	function actor.pivot(): CFrame
		return man:GetPivot()
	end
	function actor.walk(points)
		walk(man, points, 5.5, folder)
	end
	function actor.face(dir: Vector3)
		local p = man:GetPivot().Position
		man:PivotTo(CFrame.lookAt(p, p + V(dir.X, 0, dir.Z)))
	end
	function actor.head(yaw: number, tilt: number)
		headModel:PivotTo(man:GetPivot() * neck * ANG(0, yaw, tilt) * CF(0, 0.75, 0))
	end
	function actor.backAway(dist: number)
		tweenModel(man, man:GetPivot() * CF(0, 0, dist), dist)
	end
	return actor
end

local function pizzaBoxes(parent: Instance, base: CFrame)
	for k = 0, 1 do
		local cf = base * CF(0, 0.18 + k * 0.36, 0) * ANG(0, k * 0.12, 0)
		Kit.box(parent, "PizzaBox", cf, V(2.4, 0.34, 2.4), Color3.fromRGB(214, 190, 150), Kit.M.Cardboard, { CanCollide = true, CanQuery = true })
		Kit.box(parent, "PizzaLogo", cf * CF(0, 0.175, 0), V(1.2, 0.01, 1.2), Color3.fromRGB(190, 40, 36), Kit.M.Plastic)
	end
end

function Delivery.run(ctx, D, onDone)
	local world = ctx.World.folder()
	local folder = Instance.new("Folder")
	folder.Name = "PizzaDelivery"
	folder.Parent = world
	local finished = false
	local function finish()
		if not finished then
			finished = true
			onDone()
		end
	end

	-- the car pulls up in front of the house
	local car = Kit.sedan(folder, CFrame.lookAt(V(-220, 0.45, -75.5), V(-219, 0.45, -75.5)), Color3.fromRGB(230, 226, 214))
	car.Name = "DeliveryCar"
	local sign = Kit.box(car, "RoofSign", car:GetPivot() * CF(0, 3.25, 0.6) * ANG(0, math.pi / 2, 0), V(3.2, 1.0, 0.4), Color3.fromRGB(190, 36, 32), Kit.M.Neon)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.CanvasSize = Vector2.new(320, 100)
		gui.LightInfluence = 0
		gui.Parent = sign
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 240, 200)
		label.Text = "TONY'S PIZZA"
		label.Parent = gui
	end
	for _, d in car:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Headlight" then
			d.Material = Enum.Material.Neon
			local beam = Instance.new("SpotLight")
			beam.Face = Enum.NormalId.Front
			beam.Range = 50
			beam.Angle = 50
			beam.Brightness = 3
			beam.Color = Color3.fromRGB(255, 240, 210)
			beam.Parent = d
		end
	end
	ctx.Audio.playAt("CarEngine", V(-60, 3, -75), { Caption = false, Volume = 0.6 })
	ctx.Audio.caption("[Headlights sweep across the front windows]", V(2, 5, -30), 90)
	tweenModel(car, CFrame.lookAt(V(-7, 0.45, -75.5), V(-6, 0.45, -75.5)), 8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	if not alive(folder) then
		finish()
		return
	end
	ctx.Audio.playAt("DoorClose", V(-5, 3, -72), { Caption = false })

	-- he gets out and walks up to the porch
	local startCF = CFrame.lookAt(ROUTE[1], ROUTE[2])
	local okAvatar, actor = pcall(avatarActor, folder, startCF)
	if not okAvatar then
		warn("[Delivery] avatar unavailable, using the stand-in: " .. tostring(actor))
		for _, c in folder:GetChildren() do
			if c.Name == "PizzaGuy" then
				c:Destroy()
			end
		end
		actor = partsActor(folder, startCF)
	end
	local man = actor.Model
	actor.walk(ROUTE)
	if not alive(folder) then
		finish()
		return
	end
	actor.face(V(0, 0, 1))

	-- head: slowly tilts, and follows whoever he is talking to
	local watch: Player? = nil
	local tilt, yaw = 0, 0
	task.spawn(function()
		local t = 0
		while alive(folder) and man.Parent do
			t += 0.1
			local want = math.sin(t * 0.7) * 0.12
			local wantYaw = 0
			if watch then
				local root = ctx.Util.getRoot(watch)
				if root then
					local rel = actor.pivot():PointToObjectSpace(root.Position)
					wantYaw = math.clamp(math.atan2(-rel.X, -rel.Z), -0.8, 0.8)
					want = 0.28 -- the tilt gets stronger while he's looking at you
				end
			end
			tilt += (want - tilt) * 0.15
			yaw += (wantYaw - yaw) * 0.2
			actor.head(yaw, tilt)
			task.wait(0.1)
		end
	end)

	-- the doorbell
	local door = ctx.Doors.get("FrontDoor")
	ctx.Audio.playAt("Doorbell", V(2, 6, -30.5))
	ctx.Objectives.add("Door")
	D.think(nil, ctx.Story.Thoughts.Objectives.Door)

	local answeredBy: Player? = nil
	local answerSpot = Kit.box(folder, "AnswerDoor", CF(2, 5.5, -28.6), V(4, 6, 0.5), Color3.new(), Kit.M.Plastic, { Transparency = 1, CanQuery = true })
	local prompt = ctx.Interaction.prompt(answerSpot, { Action = "Answer the door", Object = "Front door", Distance = 9 }, function(player)
		answeredBy = answeredBy or player
	end)
	local waited = 0
	while not answeredBy and waited < ANSWER_TIMEOUT and alive(folder) do
		task.wait(0.25)
		waited += 0.25
		-- somebody opened it the normal way
		if door and door.IsOpen and not answeredBy then
			local best, bestD = nil, math.huge
			for _, p in ctx.Util.activePlayers() do
				local root = ctx.Util.getRoot(p)
				if root and (root.Position - V(2, 4, -30)).Magnitude < bestD then
					best, bestD = p, (root.Position - V(2, 4, -30)).Magnitude
				end
			end
			answeredBy = best
		end
		if waited == 25 then
			ctx.Audio.playAt("Knock", V(2, 5, -30.5), { CaptionText = "[Slow knocking at the front door]" })
		elseif waited == 48 then
			ctx.Audio.playAt("Doorbell", V(2, 6, -30.5))
		end
	end
	if prompt then
		prompt.Enabled = false
	end
	if not alive(folder) then
		finish()
		return
	end

	if answeredBy then
		ctx.Objectives.complete("Door")
		if door then
			ctx.Doors.setLocked(door, false)
			ctx.Doors.open(door, "Pizza")
		end
		watch = answeredBy
		task.wait(0.8)
		ctx.Audio.playAt("Sting", PORCH + V(0, 5, 0), { Caption = false })
		local audience = ctx.Util.sessionPlayers()
		ctx.Dialogue.run({
			Script = ctx.Story.Dialogue.Pizza,
			Chooser = answeredBy,
			Audience = audience,
		})
		if not alive(folder) then
			finish()
			return
		end
		-- the pizza ends up on the dining table
		pizzaBoxes(world, CF(-15, 4.8, 20.4))
		-- he backs away, still watching, then turns and goes
		actor.backAway(2.4)
		watch = nil
		if door and door.IsOpen then
			ctx.Doors.close(door)
		end
		D.think(answeredBy, "Okay. That was... weird. Lock the door.")
	else
		-- nobody came: he leaves the pizza on the porch
		pizzaBoxes(world, CF(4.2, 1, -33.2))
		D.think(nil, "The pizza guy gave up. He left the boxes on the porch.")
	end
	D.logTruth("PizzaGuy")

	local back = {}
	for i = #ROUTE, 1, -1 do
		table.insert(back, ROUTE[i])
	end
	back[1] = actor.pivot().Position
	actor.walk(back)
	if not alive(folder) then
		finish()
		return
	end
	man:Destroy()
	ctx.Audio.playAt("DoorClose", V(-5, 3, -72), { Caption = false })
	task.wait(1)
	ctx.Audio.playAt("CarEngine", V(-7, 3, -75.5), { Caption = false, Volume = 0.5 })
	finish()
	tweenModel(car, CFrame.lookAt(V(240, 0.45, -75.5), V(241, 0.45, -75.5)), 9, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	folder:Destroy()
end

return Delivery
