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
	local man, head, neck = Kit.deliveryMan(folder, CFrame.lookAt(ROUTE[1], ROUTE[2]))
	walk(man, ROUTE, 5.5, folder)
	if not alive(folder) then
		finish()
		return
	end
	man:PivotTo(CFrame.lookAt(PORCH, PORCH + V(0, 0, 1)))

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
					local rel = man:GetPivot():PointToObjectSpace(root.Position)
					wantYaw = math.clamp(math.atan2(-rel.X, -rel.Z), -0.8, 0.8)
					want = 0.28 -- the tilt gets stronger while he's looking at you
				end
			end
			tilt += (want - tilt) * 0.15
			yaw += (wantYaw - yaw) * 0.2
			head:PivotTo(man:GetPivot() * neck * ANG(0, yaw, tilt) * CF(0, 0.75, 0))
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
		tweenModel(man, man:GetPivot() * CF(0, 0, 2.4), 2.4)
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
	back[1] = man:GetPivot().Position
	walk(man, back, 5.5, folder)
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
