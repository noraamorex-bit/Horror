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
local ANSWER_TIMEOUT = 50

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

-- The delivery man: a tall, thin R15 man in a black leather jacket and black jeans (Roblox's own
-- classic clothing), bald, with a realistic pale face texture: heavy brows, narrow eyes and a
-- crooked smirk. What makes him wrong is how he holds himself: hunched over the pizza boxes, head
-- lowered, staring from under his brows, and a slow tilt of the head while he talks.
-- The standard R15 body is used on purpose (it always loads); if even that fails, the part-built
-- Kit model with the same face stands in.
local FACE_IMAGE = "rbxassetid://76270804185071" -- "Smirk" face texture (image of decal 134821089038344)
local SHIRT = 382538295 -- Roblox: Guitar Tee with Black Jacket
local PANTS = 382537569 -- Roblox: Black Jeans
-- pale skin to match the face texture
local SKIN = Color3.fromRGB(228, 204, 186)
local HEAD_BOW = math.rad(-12) -- head lowered
local LEAN = math.rad(-7) -- shoulders hunched forward

-- the face texture on a head part (replaces any default face decal)
local function applyFace(head: BasePart)
	for _, d in head:GetChildren() do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = FACE_IMAGE
	face.Parent = head
end
Delivery.applyFace = applyFace

local function avatarActor(folder: Instance, start: CFrame)
	local Players = game:GetService("Players")
	local desc = Instance.new("HumanoidDescription")
	desc.Shirt = SHIRT
	desc.Pants = PANTS
	desc.HeadColor = SKIN
	desc.TorsoColor = SKIN
	desc.LeftArmColor = SKIN
	desc.RightArmColor = SKIN
	desc.LeftLegColor = SKIN
	desc.RightLegColor = SKIN
	-- tall and narrow, with long limbs
	desc.HeightScale = 1.18
	desc.WidthScale = 0.8
	desc.DepthScale = 0.85
	desc.HeadScale = 1
	desc.BodyTypeScale = 0.35
	desc.ProportionScale = 0.6
	local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local head = model:FindFirstChild("Head") :: BasePart
	local torso = model:FindFirstChild("UpperTorso") :: BasePart
	assert(hum and root and head and torso, "avatar is missing parts")
	model.Name = "PizzaGuy"
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.WalkSpeed = 5.5
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
	applyFace(head)
	-- carrying the pizza the ordinary way: upper arms down at his sides, forearms level, the two
	-- boxes flat on his hands in front of his stomach
	for _, name in { "RightShoulder", "LeftShoulder" } do
		local joint = model:FindFirstChild(name, true)
		if joint and joint:IsA("Motor6D") then
			joint.C0 = joint.C0 * ANG(math.rad(16), 0, 0)
		end
	end
	for _, name in { "RightElbow", "LeftElbow" } do
		local joint = model:FindFirstChild(name, true)
		if joint and joint:IsA("Motor6D") then
			joint.C0 = joint.C0 * ANG(math.rad(74), 0, 0)
		end
	end
	-- the elbows sit about level with the bottom of the upper torso; the level forearms keep
	-- the hands there
	local handY = -torso.Size.Y / 2 - 0.15
	for k = 0, 1 do
		local cf = torso.CFrame * CF(0, handY + 0.3 + k * 0.36, -1.45) * ANG(0, k * 0.1, 0)
		Kit.box(model, "PizzaBag", cf, V(2.2, 0.34, 2.2), Color3.fromRGB(206, 182, 142), Kit.M.Cardboard)
		Kit.box(model, "PizzaBag", cf * CF(0, 0.175, 0), V(1.1, 0.01, 1.1), Color3.fromRGB(170, 36, 32), Kit.M.Plastic)
	end
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
	-- hunched: the upper body leans in over the bag
	local waist = model:FindFirstChild("Waist", true)
	if waist and waist:IsA("Motor6D") then
		waist.C0 = waist.C0 * ANG(LEAN, 0, 0)
	end
	local neck = head:FindFirstChild("Neck") :: Motor6D?
	local neckC0 = neck and neck.C0 * ANG(HEAD_BOW, 0, 0)
	if neck and neckC0 then
		neck.C0 = neckC0
	end

	-- Procedural animation (keyframe packs would swing the arms off the box he carries):
	-- a slow, stiff walk from the hips and knees, and when he stands still, deep slow breathing
	-- that lifts the shoulders. The arms never move.
	local joints = {}
	for _, name in { "LeftHip", "RightHip", "LeftKnee", "RightKnee", "Waist" } do
		local j = model:FindFirstChild(name, true)
		if j and j:IsA("Motor6D") then
			joints[name] = { J = j, C0 = j.C0 }
		end
	end
	local walking = false
	local phase = 0
	task.spawn(function()
		local last = os.clock()
		while model.Parent do
			local now = os.clock()
			local dt = now - last
			last = now
			local speed = V(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
			local stride = walking and math.clamp(speed / hum.WalkSpeed, 0, 1) or 0
			phase += dt * (2.2 + speed * 0.35)
			local s = math.sin(phase * 2)
			local function set(name: string, rx: number)
				local e = joints[name]
				if e then
					e.J.C0 = e.C0 * ANG(rx, 0, 0)
				end
			end
			-- legs: long stiff strides, knees barely bending
			set("LeftHip", s * 0.42 * stride)
			set("RightHip", -s * 0.42 * stride)
			set("LeftKnee", -math.max(0, -s) * 0.35 * stride)
			set("RightKnee", -math.max(0, s) * 0.35 * stride)
			-- upper body: a hunch that heaves with slow breaths when he's still
			local breath = math.sin(now * 1.6) * 0.035 * (1 - stride)
			set("Waist", breath)
			task.wait(0.03)
		end
	end)

	local actor = { Model = model }
	local talkBob = 0
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
		walking = true
		for i = 2, #points do
			moveTo(points[i])
		end
		walking = false
	end
	function actor.face(dir: Vector3)
		hum.AutoRotate = false
		root.CFrame = CFrame.lookAt(root.Position, root.Position + V(dir.X, 0, dir.Z))
	end
	function actor.head(yaw: number, tilt: number)
		if neck and neckC0 then
			neck.C0 = neckC0 * ANG(talkBob, yaw, tilt)
		end
	end
	function actor.backAway(dist: number)
		hum.AutoRotate = false
		local target = root.Position - root.CFrame.LookVector * dist
		walking = true
		moveTo(target)
		walking = false
	end
	-- he hands the pizza over: the boxes leave his hands and his arms drop to his sides
	function actor.handOver()
		for _, p in model:GetChildren() do
			if p:IsA("BasePart") and p.Name == "PizzaBag" then
				p:Destroy()
			end
		end
		for _, name in { "RightShoulder", "LeftShoulder", "RightElbow", "LeftElbow" } do
			local joint = model:FindFirstChild(name, true)
			if joint and joint:IsA("Motor6D") then
				joint.C0 = joint.C0 * ANG(math.rad(name:find("Elbow") and -66 or -16), 0, 0)
			end
		end
	end
	-- while he talks his head bobs slightly with the words
	local talking = 0
	function actor.talk(seconds: number)
		talking += 1
		local mine = talking
		task.spawn(function()
			local t0 = os.clock()
			while talking == mine and os.clock() - t0 < seconds and model.Parent do
				local t = os.clock() - t0
				talkBob = (math.sin(t * 7) * 0.5 + math.sin(t * 2.9) * 0.5) * 0.045
				task.wait(0.05)
			end
			if talking == mine then
				talkBob = 0
			end
		end)
	end
	return actor
end

local function partsActor(folder: Instance, start: CFrame)
	local man, headModel, neck = Kit.deliveryMan(folder, start, FACE_IMAGE)
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
		headModel:PivotTo(man:GetPivot() * neck * ANG(HEAD_BOW, yaw, tilt) * CF(0, 0.7, 0))
	end
	function actor.backAway(dist: number)
		tweenModel(man, man:GetPivot() * CF(0, 0, dist), dist)
	end
	function actor.talk(_seconds: number) end
	function actor.handOver()
		for _, p in man:GetChildren() do
			if p.Name == "PizzaBag" or p.Name == "BagLogo" then
				p:Destroy()
			end
		end
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
		if waited == 15 then
			ctx.Audio.playAt("Knock", V(2, 5, -30.5), { CaptionText = "[Slow knocking at the front door]" })
		elseif waited == 32 then
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
			OnLine = function(node, i)
				if node.Speaker ~= "" and not (node.Narrate and node.Narrate[i]) then
					actor.talk(ctx.Dialogue.lineTime(node.Lines[i]) * 0.8)
				end
			end,
		})
		if not alive(folder) then
			finish()
			return
		end
		-- he hands it over; the pizza ends up on the dining table
		actor.handOver()
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
