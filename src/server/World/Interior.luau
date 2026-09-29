--[[
	Interior — furniture, props, items, clues and hiding spots for 14 Alder Lane.
	Wires every interactable to its service (Escape, Hiding, Objectives, Director...).
	Adds to refs: Kitchen, TV, Fire, HallBath, Footprints, Stepladder.
]]

local Interior = {}

local V = Vector3.new

function Interior.build(ctx, root: Instance, refs)
	local B = ctx.Builder
	local C, M = B.C, B.M
	local L = ctx.Layout
	local G, U, BS, A = L.Y.Ground, L.Y.Upstairs, L.Y.Basement, 29.4

	local function folder(name: string): Folder
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = root
		return f
	end

	local function box(parent, name, x0, y0, z0, x1, y1, z1, color, mat, extra)
		return B.box(parent, name, V(x0, y0, z0), V(x1, y1, z1), color, mat, extra)
	end

	-- decorative (no collision, no raycasts)
	local DECOR = { CanCollide = false, CanQuery = false }

	local function paper(parent, name, pos: Vector3, size: Vector3)
		return B.block(parent, name, pos, size, Color3.fromRGB(238, 234, 220), M.Plastic, 0, { CanCollide = false })
	end

	local function item(parent, name, pos: Vector3, size: Vector3, color, itemId: string, label: string, count: number?)
		local p = B.block(parent, name, pos, size, color, M.Plastic, 0, { CanCollide = false })
		ctx.Interaction.pickup(p, itemId, { Object = label, Count = count })
		return p
	end

	---------------------------------------------------------------------------
	-- Furniture helpers
	---------------------------------------------------------------------------
	local function table4(parent, x0, z0, x1, z1, y, h, color)
		box(parent, "TableTop", x0, y + h - 0.35, z0, x1, y + h, z1, color, M.Wood)
		for _, c in { { x0, z0 }, { x1 - 0.4, z0 }, { x0, z1 - 0.4 }, { x1 - 0.4, z1 - 0.4 } } do
			box(parent, "Leg", c[1], y, c[2], c[1] + 0.4, y + h - 0.35, c[2] + 0.4, color, M.Wood)
		end
	end

	local function chair(parent, x, z, y, backDir: Vector3)
		box(parent, "Seat", x - 1, y + 2, z - 1, x + 1, y + 2.3, z + 1, C.Oak, M.Wood)
		box(parent, "ChairLegs", x - 0.9, y, z - 0.9, x + 0.9, y + 2, z + 0.9, C.Oak, M.Wood, { Transparency = 0.999 })
		local b = V(x, y, z) + backDir * 0.9
		local size = math.abs(backDir.X) > 0 and V(0.25, 2.6, 2) or V(2, 2.6, 0.25)
		B.block(parent, "ChairBack", b + V(0, 3.6, 0), size, C.Oak, M.Wood)
	end

	-- facing: unit axis vector the couch's front points toward
	local function couch(parent, cx, cz, y, length, facing: Vector3, color)
		local alongX = math.abs(facing.Z) > 0
		local depth = 3.6
		local function oriented(offF, offS, sF, sS, y0, y1)
			local center = V(cx, 0, cz) + facing * offF + (alongX and V(offS, 0, 0) or V(0, 0, offS))
			local size = alongX and V(sS, y1 - y0, sF) or V(sF, y1 - y0, sS)
			return B.block(parent, "Couch", center + V(0, (y0 + y1) / 2, 0), size, color, M.Fabric)
		end
		oriented(0, 0, depth, length, y, y + 2.2)
		oriented(-depth / 2 + 0.5, 0, 1, length, y + 2.2, y + 4.8)
		oriented(0, -length / 2 + 0.4, depth, 0.8, y + 2.2, y + 3.3)
		oriented(0, length / 2 - 0.4, depth, 0.8, y + 2.2, y + 3.3)
	end

	-- bed with an under-bed hiding spot. `open` = unit vector of the side you crawl in from
	local function bed(parent, name, x0, z0, x1, z1, y, blanket: Color3, open: Vector3, room: string)
		local frame = box(parent, "BedFrame", x0, y + 1.6, z0, x1, y + 2.2, z1, C.Walnut, M.Wood)
		for _, c in { { x0, z0 }, { x1 - 0.5, z0 }, { x0, z1 - 0.5 }, { x1 - 0.5, z1 - 0.5 } } do
			box(parent, "BedLeg", c[1], y, c[2], c[1] + 0.5, y + 1.6, c[2] + 0.5, C.Walnut, M.Wood)
		end
		box(parent, "Mattress", x0 + 0.2, y + 2.2, z0 + 0.2, x1 - 0.2, y + 3.4, z1 - 0.2, C.White, M.Fabric)
		box(parent, "Blanket", x0 + 0.1, y + 3.4, z0 + 0.1, x1 - 0.1, y + 3.6, z1 - 0.1, blanket, M.Fabric, DECOR)
		-- skirt on the three closed sides hides whoever is under it
		local center = V((x0 + x1) / 2, y, (z0 + z1) / 2)
		for _, dir in { V(1, 0, 0), V(-1, 0, 0), V(0, 0, 1), V(0, 0, -1) } do
			if dir ~= open then
				local half = math.abs(dir.X) > 0 and (x1 - x0) / 2 or (z1 - z0) / 2
				local p = center + dir * half + V(0, 0.8, 0)
				local size = math.abs(dir.X) > 0 and V(0.1, 1.6, z1 - z0) or V(x1 - x0, 1.6, 0.1)
				B.block(parent, "BedSkirt", p, size, blanket:Lerp(Color3.new(), 0.25), M.Fabric, 0, DECOR)
			end
		end
		local half = math.abs(open.X) > 0 and (x1 - x0) / 2 or (z1 - z0) / 2
		local edge = center + open * half
		local inside = center + open * 0.5 + V(0, 0.9, 0)
		ctx.Hiding.register(frame, {
			Name = name,
			Room = room,
			Inside = CFrame.lookAt(inside, inside + open) * CFrame.Angles(-math.rad(90), 0, 0),
			View = CFrame.lookAt(edge - open * 0.6 + V(0, 0.8, 0), edge + open * 10 + V(0, 1.6, 0)),
			Exit = CFrame.lookAt(edge + open * 2.8 + V(0, 3, 0), edge + open * 6 + V(0, 3, 0)),
			PromptOffset = frame.CFrame:PointToObjectSpace(edge + V(0, 1.2, 0)),
		})
		return frame
	end

	-- wardrobe / closet: footprint + the direction its doors face
	local function wardrobe(parent, name, x0, z0, x1, z1, y, facing: Vector3, room: string, color: Color3?)
		color = color or C.Oak
		local h = 8.5
		local center = V((x0 + x1) / 2, y, (z0 + z1) / 2)
		local alongX = math.abs(facing.Z) > 0
		local width = alongX and (x1 - x0) or (z1 - z0)
		local depth = alongX and (z1 - z0) or (x1 - x0)
		-- back and sides and top (hollow so a person fits)
		local back = center - facing * (depth / 2 - 0.15)
		B.block(parent, "WardrobeBack", back + V(0, h / 2, 0), alongX and V(width, h, 0.3) or V(0.3, h, width), color, M.Wood)
		for s = -1, 1, 2 do
			local side = center + (alongX and V(s * (width / 2 - 0.15), 0, 0) or V(0, 0, s * (width / 2 - 0.15)))
			B.block(parent, "WardrobeSide", side + V(0, h / 2, 0), alongX and V(0.3, h, depth) or V(depth, h, 0.3), color, M.Wood)
		end
		B.block(parent, "WardrobeTop", center + V(0, h - 0.15, 0), alongX and V(width, 0.3, depth) or V(depth, 0.3, width), color, M.Wood)
		local frontPos = center + facing * (depth / 2 - 0.1)
		local doors = B.block(parent, "WardrobeDoors", frontPos + V(0, h / 2, 0), alongX and V(width, h - 0.4, 0.25) or V(0.25, h - 0.4, width), color:Lerp(Color3.new(), 0.1), M.Wood)
		-- slats
		for i = 1, 5 do
			B.block(parent, "Slat", frontPos + facing * 0.14 + V(0, 4 + i * 0.5, 0), alongX and V(width * 0.8, 0.12, 0.05) or V(0.05, 0.12, width * 0.8), color:Lerp(Color3.new(), 0.35), M.Wood, 0, DECOR)
		end
		local inside = center + V(0, 3, 0)
		ctx.Hiding.register(doors, {
			Name = name,
			Room = room,
			Inside = CFrame.lookAt(inside, inside + facing),
			View = CFrame.lookAt(frontPos - facing * 0.5 + V(0, 4.6, 0), frontPos + facing * 12 + V(0, 4, 0)),
			Exit = CFrame.lookAt(frontPos + facing * 2.5 + V(0, 3, 0), frontPos + facing * 8 + V(0, 3, 0)),
		})
		return doors
	end

	local function shelf(parent, x0, z0, x1, z1, y, h, levels)
		box(parent, "Shelf", x0, y, z0, x1, y + h, z1, C.DarkWood, M.Wood, { Transparency = 0.999 })
		for i = 0, levels do
			box(parent, "ShelfBoard", x0, y + i * h / levels, z0, x1, y + i * h / levels + 0.25, z1, C.DarkWood, M.Wood, DECOR)
		end
		local rng = Random.new(math.floor(x0 * 7 + z0 * 3))
		for i = 0, levels - 1 do
			local yb = y + i * h / levels + 0.25
			local alongX = (x1 - x0) > (z1 - z0)
			local len = alongX and (x1 - x0) or (z1 - z0)
			local cursor = 0.3
			while cursor < len - 1 do
				local w = rng:NextNumber(0.3, 1.4)
				local bh = rng:NextNumber(1, math.min(2.2, h / levels - 0.4))
				local col = Color3.fromHSV(rng:NextNumber(), 0.35, rng:NextNumber(0.3, 0.6))
				if alongX then
					box(parent, "Book", x0 + cursor, yb, z0 + 0.1, x0 + cursor + w, yb + bh, z1 - 0.1, col, M.Cardboard, DECOR)
				else
					box(parent, "Book", x0 + 0.1, yb, z0 + cursor, x1 - 0.1, yb + bh, z0 + cursor + w, col, M.Cardboard, DECOR)
				end
				cursor += w + rng:NextNumber(0, 0.6)
			end
		end
	end

	local function rug(parent, x0, z0, x1, z1, y, color)
		box(parent, "Rug", x0, y, z0, x1, y + 0.06, z1, color, M.Fabric, DECOR)
	end

	-- a lamp that follows its room's light switch (and the breaker)
	local function lamp(parent, room: string, pos: Vector3, kind: string)
		local shadeSize = kind == "floor" and V(1.8, 1.4, 1.8) or V(1.3, 1, 1.3)
		local height = kind == "floor" and 6 or 1.6
		B.cylinder(parent, "LampBase", pos + V(0, 0.1, 0), 0.2, kind == "floor" and 1.2 or 0.8, C.Black, M.Metal, CFrame.Angles(0, 0, math.rad(90)))
		B.block(parent, "LampPole", pos + V(0, height / 2, 0), V(0.15, height, 0.15), Color3.fromRGB(60, 55, 50), M.Metal, 0, DECOR)
		local shade = B.block(parent, "LampShade", pos + V(0, height + shadeSize.Y / 2, 0), shadeSize, Color3.fromRGB(235, 215, 180), M.Fabric, 0, DECOR)
		local light = Instance.new("PointLight")
		light.Range = kind == "floor" and 20 or 14
		light.Brightness = kind == "floor" and 1.1 or 0.8
		light.Color = Color3.fromRGB(255, 190, 125)
		light.Shadows = true
		light.Parent = shade
		ctx.Power.registerLight(room, shade, light)
	end

	---------------------------------------------------------------------------
	-- LIVING ROOM
	---------------------------------------------------------------------------
	local living = folder("Living")
	rug(living, -37, -20, -20, -3, G, Color3.fromRGB(110, 55, 50))
	couch(living, -30, -10, G, 10, V(-1, 0, 0), Color3.fromRGB(85, 95, 90))
	box(living, "CoffeeTable", -37, G, -12.5, -34, G + 2.2, -7.5, C.Walnut, M.Wood)
	box(living, "Remote", -35.8, G + 2.2, -10.5, -35.3, G + 2.35, -9.5, C.Black, M.Plastic, DECOR)
	couch(living, -15, -24, G, 4.5, V(-1, 0, 0), Color3.fromRGB(120, 80, 60))
	box(living, "GrandfatherClock", -10, G, -28.5, -8.5, G + 9, -26.5, C.DarkWood, M.Wood)
	local clockFace = B.cylinder(living, "ClockFace", V(-10.05, G + 7, -27.5), 0.1, 1.2, C.White, M.Plastic, CFrame.new())
	ctx.Audio.loopOn("ClockTick", clockFace, { Caption = false })
	shelf(living, -9.6, -8, -8.4, -3, G, 8, 4)
	lamp(living, "Living", V(-38.5, G, -2.5), "floor")
	lamp(living, "Living", V(-11.5, G, -28.8), "floor")

	-- fireplace on the front wall
	box(living, "Hearth", -29.5, G, -30, -20.5, G + 0.4, -27.5, Color3.fromRGB(95, 55, 45), M.Brick)
	box(living, "Surround", -29.5, G, -30.3, -27.5, G + 8, -29, Color3.fromRGB(110, 60, 50), M.Brick)
	box(living, "Surround", -22.5, G, -30.3, -20.5, G + 8, -29, Color3.fromRGB(110, 60, 50), M.Brick)
	box(living, "Surround", -27.5, G + 6, -30.3, -22.5, G + 8, -29, Color3.fromRGB(110, 60, 50), M.Brick)
	box(living, "Firebox", -27.5, G + 0.4, -30.3, -22.5, G + 6, -29.8, C.Black, M.Brick)
	box(living, "Mantel", -30, G + 8, -30.3, -20, G + 8.6, -28.4, C.DarkWood, M.Wood)
	for i = -1, 1 do
		B.cylinder(living, "Log", V(-25 + i * 0.3, G + 0.9 + math.abs(i) * 0.1, -29.3 + i * 0.3), 3.2, 0.6, Color3.fromRGB(80, 55, 35), M.Wood, CFrame.Angles(0, math.rad(10 * i), 0))
	end
	local fireSpot = B.block(living, "FireSpot", V(-25, G + 1.5, -29.3), V(3, 1, 1.2), C.Black, M.Plastic, 0, { Transparency = 1, CanCollide = false })
	local fireEmitter = Instance.new("ParticleEmitter")
	fireEmitter.Texture = "rbxasset://textures/particles/fire_main.dds"
	fireEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 80, 20))
	fireEmitter.LightEmission = 1
	fireEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0.2) })
	fireEmitter.Lifetime = NumberRange.new(0.6, 1.1)
	fireEmitter.Rate = 30
	fireEmitter.Speed = NumberRange.new(2, 4)
	fireEmitter.SpreadAngle = Vector2.new(15, 15)
	fireEmitter.EmissionDirection = Enum.NormalId.Top
	fireEmitter.Enabled = false
	fireEmitter.Parent = fireSpot
	local fireLight = Instance.new("PointLight")
	fireLight.Color = Color3.fromRGB(255, 150, 70)
	fireLight.Range = 26
	fireLight.Brightness = 1.6
	fireLight.Shadows = true
	fireLight.Enabled = false
	fireLight.Parent = fireSpot
	local fire = { Lit = false }
	refs.Fire = fire
	local firePrompt
	firePrompt = ctx.Interaction.prompt(fireSpot, { Action = "Light the fire", Object = "Fireplace", Hold = 2, Distance = 8 }, function(player)
		if fire.Lit then
			return
		end
		fire.Lit = true
		firePrompt.Enabled = false
		fireEmitter.Enabled = true
		fireLight.Enabled = true
		ctx.Audio.loopOn("FireCrackle", fireSpot, { Caption = false })
		ctx.Power.setStaticLit("Living", true)
		ctx.Objectives.complete("Fire")
		task.spawn(function()
			while fireSpot.Parent do
				fireLight.Brightness = 1.3 + math.random() * 0.6
				task.wait(0.12 + math.random() * 0.15)
			end
		end)
	end)
	local poker = item(living, "FirePoker", V(-19.8, G + 2.2, -29.4), V(0.25, 4, 0.25), C.Black, "Poker", "Fire poker")
	poker.CFrame *= CFrame.Angles(0, 0, math.rad(12))

	-- TV on the west wall
	box(living, "TVStand", -40, G, -14, -37.8, G + 2.6, -6, C.Walnut, M.Wood)
	box(living, "TV", -39.8, G + 2.8, -13, -39.2, G + 7.6, -7, C.Black, M.Plastic)
	local screen = box(living, "Screen", -39.2, G + 3, -12.8, -39.12, G + 7.4, -7.2, Color3.fromRGB(10, 12, 16), M.Plastic, { CanCollide = false })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right
	gui.CanvasSize = Vector2.new(560, 310)
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.Parent = screen
	local tvLabel = Instance.new("TextLabel")
	tvLabel.Size = UDim2.fromScale(1, 1)
	tvLabel.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	tvLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
	tvLabel.Font = Enum.Font.Arcade
	tvLabel.TextScaled = true
	tvLabel.TextWrapped = true
	tvLabel.Text = ""
	tvLabel.Parent = gui
	local tvGlow = Instance.new("SurfaceLight")
	tvGlow.Face = Enum.NormalId.Right
	tvGlow.Range = 16
	tvGlow.Brightness = 0.8
	tvGlow.Angle = 120
	tvGlow.Color = Color3.fromRGB(160, 190, 255)
	tvGlow.Enabled = false
	tvGlow.Parent = screen

	local tv = { Channel = 0, Alert = false, Sound = nil :: Sound? }
	refs.TV = tv
	local function tvShow(text: string, bg: Color3, sound: string?)
		if tv.Sound then
			tv.Sound:Destroy()
			tv.Sound = nil
		end
		if text == "" then
			tvLabel.Text = ""
			tvLabel.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
			tvGlow.Enabled = false
			return
		end
		tvLabel.Text = text
		tvLabel.BackgroundColor3 = bg
		tvGlow.Enabled = true
		tvGlow.Color = bg:Lerp(Color3.new(1, 1, 1), 0.5)
		if sound then
			tv.Sound = ctx.Audio.loopOn(sound, screen, { Caption = false })
		end
	end
	function tv.setChannel(i: number, player: Player?)
		local ch = ctx.Story.TV[i]
		tv.Channel = i
		if not ch then
			tvShow("", Color3.new(), nil)
			return
		end
		local bg = ch.Sound == "TVStatic" and Color3.fromRGB(90, 90, 90) or Color3.fromRGB(25, 35, 60)
		tvShow(ch.Name, bg, ch.Sound)
		ctx.Audio.caption(ch.Line, screen.Position, 30)
		if ch.Objective then
			ctx.Objectives.complete("Movie")
		end
	end
	function tv.emergencyAlert(duration: number)
		if not ctx.Power.isOn() then
			return false
		end
		tv.Alert = true
		tvShow("EMERGENCY ALERT SYSTEM\nFLASH FLOOD WARNING\nHOLLIS COUNTY", Color3.fromRGB(150, 20, 20), "TVAlert")
		ctx.Audio.caption("[The TV switches channels by itself - a loud alert tone]", screen.Position, 70)
		task.delay(duration, function()
			tv.Alert = false
			if screen.Parent and ctx.Power.isOn() then
				tv.setChannel(tv.Channel)
			end
		end)
		return true
	end
	ctx.Interaction.prompt(screen, { Action = "Change channel", Object = "TV", Distance = 12 }, function(player)
		if not ctx.Power.isOn() then
			ctx.Audio.caption("Dead black screen. No power.", nil, nil, { player })
			return
		end
		if tv.Alert then
			ctx.Audio.caption("The alert won't let you change the channel.", nil, nil, { player })
			return
		end
		tv.setChannel((tv.Channel % #ctx.Story.TV) + 1, player)
	end)
	ctx.Power.onChanged(function(on)
		if not on then
			tvShow("", Color3.new(), nil)
		elseif tv.Channel > 0 then
			tv.setChannel(tv.Channel)
		end
	end, screen)

	---------------------------------------------------------------------------
	-- KITCHEN
	---------------------------------------------------------------------------
	local kitchen = folder("Kitchen")
	-- west counters with the sink under the window
	box(kitchen, "Counter", -40, G, 4, -37, G + 3.5, 28, C.White, M.Wood)
	box(kitchen, "Countertop", -40, G + 3.5, 4, -36.8, G + 3.8, 28, Color3.fromRGB(60, 60, 62), M.Marble)
	box(kitchen, "Sink", -39.5, G + 3.4, 12.5, -37.4, G + 3.85, 15.5, C.Steel, M.Metal, DECOR)
	B.block(kitchen, "Faucet", V(-39.6, G + 4.6, 14), V(0.3, 1.6, 0.3), C.Steel, M.Metal, 0, DECOR)
	box(kitchen, "Stove", -40, G, 21, -37, G + 3.9, 25, C.Steel, M.Metal)
	for _, z in { 22, 24 } do
		B.cylinder(kitchen, "Burner", V(-38.5, G + 3.92, z), 0.05, 1.2, C.Black, M.Metal, CFrame.new())
	end
	box(kitchen, "UpperCabinet", -40, G + 8, 4, -38.5, G + 11.5, 10.5, C.White, M.Wood)
	box(kitchen, "UpperCabinet", -40, G + 8, 18, -38.5, G + 11.5, 28, C.White, M.Wood)
	local mug = B.cylinder(kitchen, "Mug", V(-38.4, G + 3.75, 13.6), 0.6, 0.5, Color3.fromRGB(200, 190, 170), M.Plastic, CFrame.new())
	mug.CanCollide = false
	ctx.Interaction.document(mug, "WarmMug", { Action = "Look", Object = "Mug in the sink", Distance = 6 }, function(player, first)
		ctx.Director.logTruth("WarmMug")
	end)

	-- island + dining table
	box(kitchen, "Island", -28, G, 12, -22, G + 3.5, 18, C.Walnut, M.Wood)
	box(kitchen, "IslandTop", -28.3, G + 3.5, 11.7, -21.7, G + 3.8, 18.3, Color3.fromRGB(60, 60, 62), M.Marble)
	table4(kitchen, -18, 13, -12, 22, G, 3.8, C.Oak)
	chair(kitchen, -19.5, 15.5, G, V(-1, 0, 0))
	chair(kitchen, -19.5, 19.5, G, V(-1, 0, 0))
	chair(kitchen, -10.5, 15.5, G, V(1, 0, 0))
	chair(kitchen, -10.5, 19.5, G, V(1, 0, 0))

	-- phone counter against the hall wall: landline, microwave, junk drawer
	box(kitchen, "Counter", -11, G, 3.5, -8.3, G + 3.5, 10.5, C.White, M.Wood)
	box(kitchen, "Countertop", -11.2, G + 3.5, 3.5, -8.3, G + 3.8, 10.5, Color3.fromRGB(60, 60, 62), M.Marble)
	local phone = box(kitchen, "Landline", -9.8, G + 3.8, 5, -8.8, G + 4.3, 6.4, Color3.fromRGB(215, 210, 195), M.Plastic)
	ctx.Escape.setupLandline(phone)
	local microwave = box(kitchen, "Microwave", -10.9, G + 3.8, 7.3, -8.5, G + 5.4, 10.2, C.Black, M.Metal)
	local cooking = false
	local mwPrompt
	mwPrompt = ctx.Interaction.prompt(microwave, { Action = "Make popcorn", Object = "Microwave", Hold = 0.5, Distance = 7 }, function(player)
		if cooking then
			return
		end
		if not ctx.Power.isOn() then
			ctx.Audio.caption("The microwave is dead. No power.", nil, nil, { player })
			return
		end
		if ctx.Objectives.isDone("Popcorn") then
			ctx.Audio.caption("There's already a bowl of popcorn. Nobody's eating it.", nil, nil, { player })
			return
		end
		cooking = true
		mwPrompt.Enabled = false
		local hum = ctx.Audio.loopOn("MicrowaveHum", microwave, { Caption = false })
		ctx.Audio.playAt("Popcorn", microwave.Position, { Duration = 8 })
		for _ = 1, 8 do
			ctx.Noise.emit(microwave.Position, ctx.Config.Noise.Microwave, "Microwave", player)
			task.wait(1)
		end
		if hum then
			hum:Destroy()
		end
		ctx.Audio.playAt("MicrowaveBeep", microwave.Position)
		ctx.Objectives.complete("Popcorn")
		B.block(kitchen, "PopcornBowl", V(-24, G + 4.2, 15), V(2, 0.8, 2), Color3.fromRGB(245, 235, 200), M.Fabric)
		cooking = false
		mwPrompt.Enabled = true
	end)
	local drawer1 = box(kitchen, "JunkDrawer", -11.25, G + 2.4, 4, -11, G + 3.2, 6.5, C.White, M.Wood)
	ctx.Interaction.pickup(drawer1, "ElectricalTape", { Action = "Search", Object = "Junk drawer" }, function()
		box(kitchen, "JunkDrawerEmpty", -11.25, G + 2.4, 4, -11, G + 3.2, 6.5, C.White, M.Wood)
	end)
	local drawer2 = box(kitchen, "Drawer", -11.25, G + 1.2, 4, -11, G + 2.2, 6.5, C.White, M.Wood)
	ctx.Interaction.pickup(drawer2, "Batteries", { Action = "Search", Object = "Drawer (batteries)" }, function()
		box(kitchen, "DrawerEmpty", -11.25, G + 1.2, 4, -11, G + 2.2, 6.5, C.White, M.Wood)
	end)

	-- fridge, note, lasagna, trash
	local fridge = box(kitchen, "Fridge", -14.5, G, 26.5, -9.5, G + 10, 29.6, Color3.fromRGB(215, 215, 212), M.Metal)
	box(kitchen, "FridgeHandle", -10.5, G + 4, 26.3, -10.2, G + 8, 26.5, C.Steel, M.Metal, DECOR)
	ctx.Audio.loopOn("FridgeHum", fridge, { Caption = false })
	local note = paper(kitchen, "FridgeNote", V(-12.5, G + 6.5, 26.45), V(1.4, 1.8, 0.05))
	ctx.Interaction.document(note, "FridgeNote", { Object = "Note on the fridge", Distance = 6 })
	local kitchenRefs = { LasagnaGone = false, FridgePos = fridge.Position }
	refs.Kitchen = kitchenRefs
	ctx.Interaction.prompt(fridge, { Action = "Open", Object = "Fridge", Distance = 6 }, function(player)
		if kitchenRefs.LasagnaGone then
			ctx.Audio.caption("Soda, eggs, condiments. The lasagna Mom left for you is gone. Dish and all.", nil, nil, { player })
		else
			ctx.Audio.caption("Soda, eggs, condiments - and the lasagna Mom left, under foil.", nil, nil, { player })
		end
	end)
	B.cylinder(kitchen, "TrashCan", V(-16, G + 1.6, 28.4), 3.2, 2.2, Color3.fromRGB(150, 150, 150), M.Metal, CFrame.Angles(0, 0, math.rad(90)))
	local trashLid = B.cylinder(kitchen, "TrashLid", V(-16, G + 3.25, 28.4), 0.15, 2.3, C.Steel, M.Metal, CFrame.Angles(0, 0, math.rad(90)))
	local trashDoc = ctx.Interaction.document(trashLid, "TrashCan", { Action = "Look", Object = "Kitchen trash", Distance = 6 })
	trashDoc.Enabled = false
	function kitchenRefs.takeLasagna()
		kitchenRefs.LasagnaGone = true
		trashDoc.Enabled = true
	end

	-- key hook by the back door
	local hookBoard = box(kitchen, "KeyHooks", -26.5, G + 5.5, 29.25, -24, G + 6.5, 29.5, C.DarkWood, M.Wood)
	local keys = box(kitchen, "CarKeysOnHook", -25.6, G + 4.9, 29.05, -25.1, G + 5.6, 29.2, Color3.fromRGB(190, 190, 195), M.Metal, { CanCollide = false })
	ctx.Escape.setupKeyHook(keys, hookBoard)
	box(kitchen, "DoorMat", -22, G, 27, -18, G + 0.08, 29.5, Color3.fromRGB(70, 60, 50), M.Fabric, DECOR)

	---------------------------------------------------------------------------
	-- HALLWAY / FOYER
	---------------------------------------------------------------------------
	local hall = folder("Hallway")
	box(hall, "Bench", 8.5, G, -29.3, 11.5, G + 2.4, -24, C.Walnut, M.Wood)
	box(hall, "CoatRack", 11, G, -22, 11.6, G + 7, -21.4, C.DarkWood, M.Wood)
	box(hall, "ConsoleTable", -7.6, G, -27, -6, G + 3.4, -21, C.Walnut, M.Wood)
	rug(hall, -1, -28, 5, -12, G, Color3.fromRGB(80, 70, 90))
	box(hall, "FamilyPhoto", -7.72, G + 6, -25, -7.62, G + 8, -22.5, C.Black, M.Plastic, DECOR)

	---------------------------------------------------------------------------
	-- OFFICE (key-locked)
	---------------------------------------------------------------------------
	local office = folder("Office")
	box(office, "DeskTop", 29, G + 3.4, -25, 37, G + 3.8, -18, C.Walnut, M.Wood)
	box(office, "DeskPedestal", 29, G, -25, 31.5, G + 3.4, -18, C.Walnut, M.Wood)
	box(office, "DeskPedestal", 35, G, -25, 37, G + 3.4, -18, C.Walnut, M.Wood)
	box(office, "Monitor", 35.5, G + 3.8, -23, 36, G + 6.5, -20, C.Black, M.Plastic)
	chair(office, 33, -21.5, G, V(-1, 0, 0))
	local invoice = paper(office, "Invoice", V(32.5, G + 3.83, -21.5), V(1.6, 0.04, 2))
	ctx.Interaction.document(invoice, "Invoice", { Object = "Invoice on the desk", Distance = 6 })
	local deskDrawer = box(office, "DeskDrawer", 28.85, G + 2.2, -22.5, 29, G + 3.1, -20.5, C.DarkWood, M.Wood)
	ctx.Interaction.pickup(deskDrawer, "CarKeys", { Action = "Search", Object = "Desk drawer (spare keys)" }, function()
		box(office, "DeskDrawerEmpty", 28.85, G + 2.2, -22.5, 29, G + 3.1, -20.5, C.DarkWood, M.Wood)
	end)
	shelf(office, 38.6, -29.5, 39.8, -12, G, 10, 5)
	lamp(office, "Office", V(36.3, G + 3.8, -24.3), "table")
	box(office, "FilingCabinet", 13, G, -29.5, 16, G + 5, -27, C.Steel, M.Metal)
	rug(office, 20, -27, 34, -13, G, Color3.fromRGB(60, 70, 80))

	---------------------------------------------------------------------------
	-- DOWNSTAIRS BATHROOM
	---------------------------------------------------------------------------
	local bath = folder("Bathroom")
	box(bath, "Vanity", 15, G, 2.3, 19.5, G + 3.2, 3.7, C.White, M.Wood)
	box(bath, "Basin", 16.3, G + 3.2, 2.5, 18.2, G + 3.5, 3.5, C.White, M.Marble)
	box(bath, "Mirror", 15.5, G + 5, 3.62, 19, G + 8.5, 3.7, Color3.fromRGB(190, 200, 205), M.Glass, { Reflectance = 0.4 })
	item(bath, "Scissors", V(15.6, G + 3.3, 3), V(0.8, 0.1, 0.35), Color3.fromRGB(210, 60, 60), "Scissors", "Scissors")
	box(bath, "Toilet", 19.5, G, -9.6, 21.6, G + 2.2, -7, C.White, M.Marble)
	box(bath, "ToiletTank", 20.8, G + 2.2, -9.6, 21.6, G + 4, -7, C.White, M.Marble)

	---------------------------------------------------------------------------
	-- MUDROOM
	---------------------------------------------------------------------------
	local mud = folder("Mudroom")
	box(mud, "Bench", 24, G, -9.6, 32, G + 2.2, -7.8, C.Oak, M.Wood)
	for i = 0, 3 do
		box(mud, "Coat", 24.5 + i * 2, G + 4, -9.6, 25.8 + i * 2, G + 8, -9, Color3.fromHSV(i * 0.2, 0.3, 0.35), M.Fabric, DECOR)
	end
	box(mud, "Shelf", 34.5, G + 5, -9.7, 39.7, G + 5.3, -7.8, C.Oak, M.Wood)
	local fl1 = B.cylinder(mud, "Flashlight", V(37, G + 5.6, -8.8), 1.2, 0.45, Color3.fromRGB(200, 170, 40), M.Plastic, CFrame.new())
	fl1.CanCollide = false
	ctx.Interaction.pickup(fl1, "Flashlight", { Object = "Flashlight" })
	box(mud, "KeyBoard", 34.5, G + 7, -9.75, 36.5, G + 8, -9.6, C.DarkWood, M.Wood)
	local bkey = box(mud, "BasementKey", 35.2, G + 6.3, -9.55, 35.6, G + 7, -9.45, Color3.fromRGB(190, 160, 80), M.Metal, { CanCollide = false })
	ctx.Interaction.pickup(bkey, "BasementKey", { Object = "Key tagged 'BSMT'" })
	box(mud, "Boots", 26, G, -7.5, 28, G + 1.2, -6, C.Black, M.Fabric, DECOR)

	---------------------------------------------------------------------------
	-- DEN
	---------------------------------------------------------------------------
	local den = folder("Den")
	rug(den, 16, 8, 32, 20, G, Color3.fromRGB(70, 80, 70))
	couch(den, 24, 17, G, 10, V(0, 0, -1), Color3.fromRGB(70, 70, 85))
	box(den, "TVCabinet", 18, G, 4.4, 30, G + 2.4, 6.4, C.Walnut, M.Wood)
	box(den, "DenTV", 20, G + 2.4, 4.6, 28, G + 7, 5, C.Black, M.Plastic)
	box(den, "Console", 25, G + 2.4, 5.2, 27, G + 2.9, 6.2, C.Black, M.Plastic)
	box(den, "EndTable", 14, G, 14, 16.5, G + 2.8, 16.5, C.Walnut, M.Wood)
	local denDrawer = box(den, "EndTableDrawer", 14.2, G + 1.6, 16.5, 16.3, G + 2.5, 16.65, C.DarkWood, M.Wood)
	ctx.Interaction.pickup(denDrawer, "Flashlight", { Action = "Search", Object = "Drawer (flashlight)" }, function()
		box(den, "EndTableDrawerEmpty", 14.2, G + 1.6, 16.5, 16.3, G + 2.5, 16.65, C.DarkWood, M.Wood)
	end)
	shelf(den, 38.8, 22, 39.8, 29.5, G, 8, 4)
	lamp(den, "Den", V(15.2, G + 2.8, 14.6), "table")
	wardrobe(den, "Den closet", 32, 26.6, 37, 29.8, G, V(0, 0, -1), "Den", C.White)

	---------------------------------------------------------------------------
	-- GARAGE
	---------------------------------------------------------------------------
	local garage = folder("Garage")
	-- the Honda
	local car = Instance.new("Model")
	car.Name = "Honda"
	car.Parent = garage
	local body = box(car, "Body", 46.5, G + 1, -25, 53.5, G + 4, -10, Color3.fromRGB(95, 30, 30), M.Metal)
	box(car, "Cabin", 47, G + 4, -21, 53, G + 7, -14, Color3.fromRGB(40, 45, 55), M.Glass, { Transparency = 0.3 })
	for _, w in { { 46.2, -22 }, { 53.8, -22 }, { 46.2, -13 }, { 53.8, -13 } } do
		B.cylinder(car, "Wheel", V(w[1], G + 1.2, w[2]), 1, 2.4, C.Black, M.Plastic, CFrame.new())
	end
	for _, x in { 47.5, 52.5 } do
		box(car, "Headlight", x - 0.8, G + 2.4, -25.1, x + 0.8, G + 3, -25, Color3.fromRGB(220, 220, 200), M.Glass)
	end
	car.PrimaryPart = body
	local driverDoor = box(car, "DriverDoor", 53.5, G + 1.5, -19, 53.7, G + 5, -15, Color3.fromRGB(90, 28, 28), M.Metal)
	-- parked nose-in: turn it round so it backs out through the garage door (local +Z = out)
	car:PivotTo(car:GetPivot() * CFrame.Angles(0, math.pi, 0))
	ctx.Escape.setupCar(car, driverDoor, {})

	-- breaker panel on the house wall
	local panel = box(garage, "BreakerPanel", 40.5, G + 4, -14.5, 40.9, G + 8.5, -11, Color3.fromRGB(150, 150, 150), M.Metal)
	local leverOn = CFrame.new(41.05, G + 7.8, -12.75)
	local leverOff = CFrame.new(41.05, G + 7.2, -12.75)
	local lever = B.part(garage, { Name = "MainLever", Size = V(0.3, 0.6, 0.9), CFrame = leverOn, Color = Color3.fromRGB(200, 40, 30), CanCollide = false })
	ctx.Escape.setupBreaker(panel, lever, leverOn, leverOff)
	local opener = box(garage, "OpenerButton", 40.5, G + 4.5, -8.9, 40.8, G + 5.2, -8.2, C.White, M.Plastic)
	box(garage, "OpenerRail", 52.8, G + 10.5, -29.5, 53.2, G + 10.8, -6, C.Steel, M.Metal, DECOR)
	box(garage, "OpenerMotor", 51.5, G + 9.6, -7, 54.5, G + 11, -4.5, C.Steel, M.Metal)
	local cord = box(garage, "ReleaseCord", 52.9, G + 7.8, -26.2, 53.1, G + 10.5, -26, Color3.fromRGB(200, 40, 30), M.Fabric, { CanCollide = false })
	ctx.Escape.setupGarageDoor(refs.GarageDoor, opener, cord)

	-- workbench: walkies + tape
	box(garage, "Workbench", 61.5, G, -27, 65.6, G + 3.4, -16, C.Oak, M.Wood)
	box(garage, "Pegboard", 65.5, G + 4.5, -27, 65.7, G + 9, -16, Color3.fromRGB(170, 140, 100), M.Wood)
	item(garage, "Walkie", V(63, G + 3.9, -24), V(0.6, 1, 0.35), Color3.fromRGB(40, 40, 45), "Walkie", "Walkie-talkie")
	item(garage, "Walkie", V(63, G + 3.9, -22.8), V(0.6, 1, 0.35), Color3.fromRGB(40, 40, 45), "Walkie", "Walkie-talkie")
	B.cylinder(garage, "Tape", V(63.5, G + 3.55, -19.5), 0.3, 0.9, C.Black, M.Plastic, CFrame.new())
	local tape2 = B.block(garage, "TapeRoll", V(63.5, G + 3.6, -19.5), V(0.9, 0.35, 0.9), C.Black, M.Plastic, 0, { Transparency = 1, CanCollide = false })
	ctx.Interaction.pickup(tape2, "ElectricalTape", { Object = "Electrical tape" }, function()
		for _, p in garage:GetChildren() do
			if p.Name == "Tape" then
				p:Destroy()
			end
		end
	end)
	shelf(garage, 40.5, 1, 45, 5.6, G, 8, 3)
	box(garage, "Boxes", 58, G, 1, 65, G + 4, 5.5, Color3.fromRGB(160, 130, 90), M.Cardboard)

	-- his route: stepladder under the hatch, muddy prints from the side door
	local gh = L.GarageHatch
	local ladderModel = Instance.new("Model")
	ladderModel.Name = "Stepladder"
	ladderModel.Parent = garage
	local lx, lz = (gh.x0 + gh.x1) / 2, (gh.z0 + gh.z1) / 2
	box(ladderModel, "LadderLeg", lx - 1, G, lz - 1.6, lx + 1, G + 12, lz - 1.3, Color3.fromRGB(180, 180, 170), M.Metal)
	box(ladderModel, "LadderLeg", lx - 1, G, lz + 1.3, lx + 1, G + 12, lz + 1.6, Color3.fromRGB(180, 180, 170), M.Metal)
	for _, p in ladderModel:GetChildren() do
		(p :: BasePart).Transparency = 1;
		(p :: BasePart).CanCollide = false
	end
	refs.Stepladder = ladderModel

	local prints = {}
	local from, to = V(64, G + 0.03, -2), V(lx + 1, G + 0.03, lz + 1)
	local steps = 9
	for i = 0, steps do
		local p = from:Lerp(to, i / steps) + V(0, 0, (i % 2 == 0) and 0.5 or -0.5)
		local fp = B.block(garage, "Footprint", p, V(1.3, 0.04, 0.55), Color3.fromRGB(55, 40, 28), M.Plastic, 0, { CanCollide = false, Transparency = 1 })
		table.insert(prints, fp)
	end
	local printDoc = ctx.Interaction.document(prints[3], "Footprints", { Action = "Look", Object = "Muddy footprints", Distance = 7 })
	printDoc.Enabled = false
	refs.Footprints = {}
	function refs.Footprints.show()
		for _, fp in prints do
			fp.Transparency = 0.15
		end
		printDoc.Enabled = true
		for _, p in ladderModel:GetChildren() do
			(p :: BasePart).Transparency = 0;
			(p :: BasePart).CanCollide = true
		end
	end

	---------------------------------------------------------------------------
	-- MASTER BEDROOM + BATH
	---------------------------------------------------------------------------
	local master = folder("Master")
	rug(master, -30, -26, -14, -4, U, Color3.fromRGB(120, 115, 100))
	bed(master, "Under the master bed", -40, -19, -31, -10, U, Color3.fromRGB(70, 80, 110), V(1, 0, 0), "Master")
	box(master, "Headboard", -40, U, -19.5, -39.4, U + 6, -9.5, C.Walnut, M.Wood)
	wardrobe(master, "Master wardrobe", -27.5, -30, -20.5, -27, U, V(0, 0, 1), "Master", C.Walnut)
	box(master, "Dresser", -10.2, U, -28.5, -8.4, U + 4, -22, C.Walnut, M.Wood)
	item(master, "Purse", V(-9.3, U + 4.6, -25), V(1.4, 1.1, 0.7), Color3.fromRGB(110, 60, 45), "PepperSpray", "Pepper spray (mom's old purse)", ctx.Config.PepperSpray.Uses)
	box(master, "Nightstand", -40, U, -8.8, -38, U + 2.4, -6.5, C.Walnut, M.Wood)
	lamp(master, "Master", V(-39, U + 2.4, -7.6), "table")

	local mbath = folder("MasterBath")
	box(mbath, "Tub", -40, U, 8.5, -31, U + 2.2, 12, C.White, M.Marble)
	box(mbath, "Vanity", -20, U, 10.5, -12, U + 3.2, 12, C.White, M.Wood)
	box(mbath, "Mirror", -19.5, U + 5, 11.85, -12.5, U + 8.5, 11.95, Color3.fromRGB(190, 200, 205), M.Glass, { Reflectance = 0.4 })
	box(mbath, "Toilet", -11, U, 1, -9, U + 2.2, 3.4, C.White, M.Marble)

	---------------------------------------------------------------------------
	-- JAMIE'S ROOM
	---------------------------------------------------------------------------
	local jamie = folder("Jamie")
	bed(jamie, "Under Jamie's bed", -40, 12.8, -34, 19, U, Color3.fromRGB(40, 70, 120), V(1, 0, 0), "Jamie")
	wardrobe(jamie, "Jamie's closet", -19.5, 26.8, -13.5, 29.8, U, V(0, 0, -1), "Jamie", C.White)
	table4(jamie, -31, 26.5, -25.5, 29.5, U, 3.4, C.Oak)
	chair(jamie, -28, 25, U, V(0, 0, -1))
	lamp(jamie, "Jamie", V(-26.2, U + 3.4, 28.6), "table")
	box(jamie, "Laptop", -29.5, U + 3.4, 27.5, -27, U + 3.55, 29, Color3.fromRGB(70, 70, 75), M.Metal, DECOR)
	box(jamie, "Poster", -39.7, U + 6, 25.5, -39.62, U + 10, 28.5, Color3.fromRGB(180, 70, 60), M.Plastic, DECOR)

	---------------------------------------------------------------------------
	-- UPSTAIRS HALL
	---------------------------------------------------------------------------
	local uhall = folder("UpperHall")
	wardrobe(uhall, "Linen wardrobe", 9.2, -8.5, 11.8, -3.5, U, V(-1, 0, 0), "UpperHall", C.White)
	rug(uhall, 0, -26, 6, -10, U, Color3.fromRGB(80, 70, 90))

	---------------------------------------------------------------------------
	-- GUEST ROOM
	---------------------------------------------------------------------------
	local guest = folder("Guest")
	bed(guest, "Under the guest bed", 14, -29.6, 20.5, -22, U, Color3.fromRGB(120, 110, 90), V(0, 0, 1), "Guest")
	wardrobe(guest, "Guest wardrobe", 32, -9.2, 38, -6.4, U, V(0, 0, -1), "Guest", C.Oak)
	box(guest, "Boxes", 36, U, -29.5, 39.6, U + 3, -25, Color3.fromRGB(160, 130, 90), M.Cardboard)

	---------------------------------------------------------------------------
	-- UPSTAIRS BATHROOM (shower, signal at the window)
	---------------------------------------------------------------------------
	local hbath = folder("HallBath")
	box(hbath, "Vanity", 14, U, -5.6, 21, U + 3.2, -4, C.White, M.Wood)
	box(hbath, "Toilet", 23, U, -5.7, 25, U + 2.2, -3.4, C.White, M.Marble)
	box(hbath, "ShowerBase", 33.5, U, 3, 39.7, U + 0.4, 7.7, Color3.fromRGB(230, 230, 228), M.Tile)
	box(hbath, "ShowerWall", 33.4, U, 7.6, 39.7, U + 11, 7.8, Color3.fromRGB(230, 230, 228), M.Tile)
	box(hbath, "ShowerWall", 33.3, U, 2.8, 39.7, U + 11, 3, Color3.fromRGB(230, 230, 228), M.Tile)
	box(hbath, "CurtainRod", 33.3, U + 10, 2.8, 33.45, U + 10.2, 7.8, C.Steel, M.Metal, DECOR)
	local curtain = box(hbath, "ShowerCurtain", 33.2, U + 1, 3, 33.35, U + 10, 7.6, Color3.fromRGB(180, 200, 190), M.Fabric)
	ctx.Hiding.register(curtain, {
		Name = "Behind the shower curtain",
		Room = "HallBath",
		Inside = CFrame.lookAt(V(36.5, U + 3, 5.3), V(30, U + 3, 5.3)),
		View = CFrame.lookAt(V(34, U + 4.6, 4.2), V(20, U + 4.2, 1)),
		Exit = CFrame.lookAt(V(31, U + 3, 5.3), V(24, U + 3, 5.3)),
	})
	local drips = Instance.new("ParticleEmitter")
	drips.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	drips.Color = ColorSequence.new(Color3.fromRGB(190, 210, 230))
	drips.Size = NumberSequence.new(0.08)
	drips.Rate = 3
	drips.Lifetime = NumberRange.new(0.6)
	drips.Speed = NumberRange.new(0)
	drips.Acceleration = V(0, -40, 0)
	drips.Transparency = NumberSequence.new(0.3)
	local head = box(hbath, "ShowerHead", 39.3, U + 9, 5, 39.7, U + 9.4, 5.6, C.Steel, M.Metal, DECOR)
	drips.Parent = head
	local base = hbath:FindFirstChild("ShowerBase") :: BasePart
	base.Reflectance = 0.35
	ctx.Interaction.document(base, "WetShower", { Action = "Look", Object = "Shower", Distance = 8 }, function()
		ctx.Director.logTruth("WetShower")
	end)
	box(hbath, "Mat", 30, U, 4, 32.5, U + 0.08, 6.5, Color3.fromRGB(110, 130, 150), M.Fabric, DECOR)

	---------------------------------------------------------------------------
	-- LILY'S ROOM
	---------------------------------------------------------------------------
	local lily = folder("Lily")
	rug(lily, 18, 12, 30, 24, U, Color3.fromRGB(200, 150, 180))
	bed(lily, "Under Lily's bed", 32, 23.5, 38.5, 29.6, U, Color3.fromRGB(230, 170, 200), V(0, 0, -1), "Lily")
	wardrobe(lily, "Lily's closet", 13.2, 8.3, 18.2, 11.2, U, V(0, 0, 1), "Lily", C.White)
	box(lily, "ToyBox", 21, U, 27.5, 25, U + 2.2, 29.6, Color3.fromRGB(230, 200, 120), M.Wood)
	box(lily, "FishTank", 36, U + 3, 9, 39.6, U + 5.4, 11, Color3.fromRGB(120, 170, 200), M.Glass, { Transparency = 0.4 })
	box(lily, "TankStand", 36, U, 9, 39.6, U + 3, 11, C.White, M.Wood)
	local drawing = paper(lily, "Drawing", V(24, U + 5.5, 8.36), V(2.2, 1.6, 0.05))
	drawing.Color = Color3.fromRGB(250, 248, 240)
	ctx.Interaction.document(drawing, "LilyDrawing", { Object = "A crayon drawing", Distance = 7 })
	local nightlight = B.block(lily, "Nightlight", V(31, U + 1.2, 29.6), V(0.8, 0.8, 0.3), Color3.fromRGB(255, 220, 150), Enum.Material.Neon, 0, { CanCollide = false })
	local nl = Instance.new("PointLight")
	nl.Range = 12
	nl.Brightness = 0.7
	nl.Color = Color3.fromRGB(255, 200, 140)
	nl.Parent = nightlight
	ctx.Interaction.prompt(nightlight, { Action = "Look", Object = "Nightlight", Distance = 6 }, function(player)
		ctx.Audio.caption("A battery nightlight shaped like a moon. Lily always leaves it on.", nil, nil, { player })
		ctx.Director.logTruth("LilyNightlight")
	end)

	---------------------------------------------------------------------------
	-- BASEMENT + BOILER ROOM
	---------------------------------------------------------------------------
	local base0 = folder("Basement")
	box(base0, "Boiler", -27, BS, 12, -22, BS + 7, 17, Color3.fromRGB(110, 105, 95), M.Metal)
	B.cylinder(base0, "WaterHeater", V(-24, BS + 3.5, 26), 7, 3.5, Color3.fromRGB(190, 190, 185), M.Metal)
	-- pipes the captives are tied to
	box(base0, "Pipe", -39.6, BS + 5.5, 10.5, -39.1, BS + 6, 29.5, Color3.fromRGB(120, 80, 60), M.Metal)
	box(base0, "Pipe", -39.6, BS + 1.5, 10.5, -39.1, BS + 2, 29.5, Color3.fromRGB(120, 80, 60), M.Metal)
	box(base0, "Pipe", -39.5, BS + 8, 29.1, -20.5, BS + 8.5, 29.6, Color3.fromRGB(120, 80, 60), M.Metal)
	for _, z in { 13, 19, 25 } do
		box(base0, "PipeRiser", -39.6, BS, z - 0.25, -39.1, BS + 11, z + 0.25, Color3.fromRGB(120, 80, 60), M.Metal)
	end
	box(base0, "Washer", -38.5, BS, -29.5, -34.5, BS + 4, -26, C.White, M.Metal)
	box(base0, "Dryer", -34, BS, -29.5, -30, BS + 4, -26, C.White, M.Metal)
	shelf(base0, -39.6, -20, -38, -6, BS, 8, 4)
	box(base0, "Boxes", -18, BS, -29.5, -10, BS + 5, -25, Color3.fromRGB(160, 130, 90), M.Cardboard)
	box(base0, "Boxes", -6, BS, 24, 2, BS + 4, 29.5, Color3.fromRGB(160, 130, 90), M.Cardboard)
	box(base0, "Freezer", -14, BS, 26, -8, BS + 3.5, 29.5, C.White, M.Metal)
	box(base0, "OldCouch", -12, BS, -6, -4, BS + 2.6, -2.5, Color3.fromRGB(90, 80, 60), M.Fabric)
	-- under-stairs nook, behind a tarp
	local tarp = box(base0, "Tarp", 5.8, BS, 11.5, 6, BS + 6, 20, Color3.fromRGB(60, 80, 90), M.Fabric)
	ctx.Hiding.register(tarp, {
		Name = "Under the basement stairs",
		Room = "Basement",
		Inside = CFrame.lookAt(V(9, BS + 3, 17), V(0, BS + 3, 17)),
		View = CFrame.lookAt(V(6.6, BS + 4, 14), V(-10, BS + 3.5, 6)),
		Exit = CFrame.lookAt(V(3.5, BS + 3, 15), V(-5, BS + 3, 15)),
	})

	---------------------------------------------------------------------------
	-- ATTIC — the nest
	---------------------------------------------------------------------------
	local nest = folder("Nest")
	local n0 = L.Attic.Nest
	box(nest, "SleepingBag", n0.X - 3, A, n0.Z - 2, n0.X + 3, A + 0.5, n0.Z + 1.2, Color3.fromRGB(60, 75, 55), M.Fabric)
	box(nest, "Pillow", n0.X + 2, A + 0.5, n0.Z - 1.6, n0.X + 3, A + 0.9, n0.Z + 0.8, Color3.fromRGB(150, 140, 120), M.Fabric)
	local lantern = B.block(nest, "Lantern", V(n0.X + 5, A + 0.8, n0.Z - 4), V(0.8, 1.6, 0.8), Color3.fromRGB(230, 200, 120), Enum.Material.Neon, 0, { CanCollide = false })
	local ll = Instance.new("PointLight")
	ll.Range = 16
	ll.Brightness = 0.9
	ll.Color = Color3.fromRGB(255, 190, 110)
	ll.Shadows = true
	ll.Parent = lantern
	ctx.Power.setStaticLit("Attic", true)
	for i = 1, 7 do
		local a = i * 0.9
		box(nest, "Wrapper", n0.X - 5 + math.cos(a) * 2.5, A, n0.Z + 3 + math.sin(a), n0.X - 4.2 + math.cos(a) * 2.5, A + 0.08, n0.Z + 3.6 + math.sin(a), Color3.fromHSV(i / 7, 0.6, 0.8), M.Plastic, DECOR)
	end
	for i = 1, 4 do
		B.cylinder(nest, "Bottle", V(n0.X - 2 + i * 0.6, A + 0.6, n0.Z + 2.5), 1.2, 0.4, Color3.fromRGB(120, 160, 120), M.Glass, CFrame.new())
	end
	local notebook = box(nest, "Notebook", n0.X + 1, A + 0.5, n0.Z + 2, n0.X + 2.2, A + 0.62, n0.Z + 3.4, Color3.fromRGB(40, 60, 120), M.Cardboard, { CanCollide = false })
	local polaroids = box(nest, "Polaroids", -28.4, A + 1.5, n0.Z - 2, -28.2, A + 4.5, n0.Z + 3, Color3.fromRGB(220, 215, 205), M.Plastic, { CanCollide = false })
	local lanyard = box(nest, "Lanyard", n0.X - 1.5, A + 0.5, n0.Z - 4, n0.X - 0.5, A + 0.58, n0.Z - 3.2, Color3.fromRGB(40, 90, 160), M.Plastic, { CanCollide = false })
	for part, doc in { [notebook] = "Notebook", [polaroids] = "Polaroids", [lanyard] = "Lanyard" } do
		ctx.Interaction.document(part, doc, { Distance = 7 }, function(player)
			ctx.Director.onDiscovery(player, doc)
		end)
	end
	ctx.Escape.setNest(nest, V(n0.X - 3.5, A + 0.3, n0.Z - 3))

	---------------------------------------------------------------------------
	-- Lobby spawn (living room)
	---------------------------------------------------------------------------
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.Transparency = 1
	spawn.Size = V(6, 0.2, 6)
	spawn.CFrame = CFrame.new(-24, G + 0.2, -12)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = root
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end

	return refs
end

return Interior
