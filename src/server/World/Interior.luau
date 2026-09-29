--[[
	Interior — furniture, props, items, clues, task props and hiding spots for 14 Alder Lane.
	Wall finishes (paint, wainscoting, trim, curtains, pictures) come from World/Finish;
	the models themselves come from World/Kit.

	Adds to refs: Kitchen, TV, Fire, Footprints, Stepladder.
	Registers objective marker targets with Objectives.setTarget.
]]

local CollectionService = game:GetService("CollectionService")

local Kit = require(script.Parent.Kit)
local Textures = require(script.Parent.Textures)

local Interior = {}

local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad

local PX, NX, PZ, NZ = V(1, 0, 0), V(-1, 0, 0), V(0, 0, 1), V(0, 0, -1)

-- a CFrame at (x, y, z) facing a horizontal direction
local function F(x: number, y: number, z: number, dir: Vector3): CFrame
	return CFrame.lookAt(V(x, y, z), V(x + dir.X, y, z + dir.Z))
end

function Interior.build(ctx, root: Instance, refs)
	local B = ctx.Builder
	local C, M = B.C, B.M
	local L = ctx.Layout
	local G, U, BS, A = L.Y.Ground, L.Y.Upstairs, L.Y.Basement, 29.4
	local target = ctx.Objectives.setTarget
	local KM = Kit.M

	local function folder(name: string): Folder
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = root
		return f
	end

	-- an invisible part for a prompt (drawers, cupboards, search spots)
	local function spot(parent, name: string, cf: CFrame, size: Vector3): BasePart
		local p = Kit.box(parent, name, cf, size, Color3.new(), KM.Plastic)
		p.Transparency = 1
		p.CanQuery = true
		return p
	end

	-- Stashes: drawers and shelves that can hold a useful item. Each night the flashlights, tape
	-- and batteries go into different ones (see the end of the build); the rest are empty.
	local stashes = {}
	local function stash(name: string, part: BasePart, label: string, floor: string, visible: boolean?)
		table.insert(stashes, { Name = name, Part = part, Label = label, Floor = floor, Visible = visible == true })
	end

	local function paper(parent, name, cf: CFrame, size: Vector3)
		local p = Kit.box(parent, name, cf, size, Color3.fromRGB(238, 234, 220), KM.Plastic)
		p.CanQuery = true
		return p
	end

	local function item(parent, name, pos: Vector3, size: Vector3, color, itemId: string, label: string, count: number?)
		local p = Kit.box(parent, name, CF(pos), size, color, KM.Plastic)
		p.CanQuery = true
		ctx.Interaction.pickup(p, itemId, { Object = label, Count = count })
		return p
	end

	local WOOD_DARK = Kit.C.WoodDark
	local WOOD_MID = Kit.C.WoodMid
	local WOOD_LIGHT = Kit.C.WoodLight
	local BRASS = Kit.C.Brass
	local COUNTER = Color3.fromRGB(58, 58, 62)
	local WHITE_WOOD = Color3.fromRGB(236, 232, 222)

	local function lamp(parent, room: string, cf: CFrame, kind: string, color: Color3?)
		local _, bulb, light
		if kind == "floor" then
			_, bulb, light = Kit.floorLamp(parent, cf)
		else
			_, bulb, light = Kit.tableLamp(parent, cf, color)
		end
		ctx.Power.registerLight(room, bulb, light)
	end

	-- decorative lights (sconces, fairy lights, under-cabinet strips) are on their own circuit,
	-- on from the start and dead when the breaker goes
	local function decor(bulb: BasePart, light: Light?)
		ctx.Power.registerLight("Decor", bulb, light)
	end
	local function sconce(parent, cf: CFrame, shade: Color3?)
		local _, bulb, light = Kit.sconce(parent, cf, shade)
		decor(bulb, light)
	end
	local function fairyLights(parent, a: Vector3, b: Vector3, sag: number, n: number, color: Color3?)
		local _, bulbs = Kit.stringLights(parent, a, b, sag, n, color)
		for _, bulb in bulbs do
			decor(bulb, bulb:FindFirstChildOfClass("PointLight"))
		end
	end

	local function pendant(parent, room: string, top: Vector3, drop: number, color: Color3?)
		local _, bulb, light = Kit.pendant(parent, top, drop, color)
		ctx.Power.registerLight(room, bulb, light)
	end

	-- bed with an under-bed hiding spot. `open` = side you crawl in from, `head` = headboard side
	local function bed(parent, name, x0, z0, x1, z1, y, duvet: Color3, open: Vector3, head: Vector3, room: string, frameColor: Color3?)
		local center = V((x0 + x1) / 2, y, (z0 + z1) / 2)
		local hx = math.abs(head.X) > 0.5
		local l = hx and (x1 - x0) or (z1 - z0)
		local w = hx and (z1 - z0) or (x1 - x0)
		local cf = CFrame.lookAt(center, center - head)
		local ol = cf:VectorToObjectSpace(open)
		local openLocal = V(math.round(ol.X), 0, math.round(ol.Z))
		local _, frame = Kit.bed(parent, cf, w, l, duvet, frameColor or WOOD_MID, openLocal)
		local half = math.abs(open.X) > 0 and (x1 - x0) / 2 or (z1 - z0) / 2
		local edge = center + open * half
		local inside = center + open * 0.5 + V(0, 0.9, 0)
		ctx.Hiding.register(frame, {
			Name = name,
			Room = room,
			Inside = CFrame.lookAt(inside, inside + open) * ANG(-rad(90), 0, 0),
			View = CFrame.lookAt(edge - open * 0.6 + V(0, 0.8, 0), edge + open * 10 + V(0, 1.6, 0)),
			Exit = CFrame.lookAt(edge + open * 2.8 + V(0, 3, 0), edge + open * 6 + V(0, 3, 0)),
			PromptOffset = frame.CFrame:PointToObjectSpace(edge + V(0, 1.2, 0)),
		})
		return frame, cf
	end

	-- wardrobe / closet you can hide in: footprint + the direction its doors face
	local function wardrobe(parent, name, x0, z0, x1, z1, y, facing: Vector3, room: string, color: Color3?)
		local center = V((x0 + x1) / 2, y, (z0 + z1) / 2)
		local alongX = math.abs(facing.Z) > 0
		local w = alongX and (x1 - x0) or (z1 - z0)
		local d = alongX and (z1 - z0) or (x1 - x0)
		local _, doors = Kit.wardrobe(parent, CFrame.lookAt(center, center + facing), w, d, color or WOOD_MID)
		local frontPos = center + facing * (d / 2 - 0.1)
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

	---------------------------------------------------------------------------
	-- LIVING ROOM — fireplace on the west wall, TV on the front wall, sofa between
	---------------------------------------------------------------------------
	local living = folder("Living")
	local SOFA = Color3.fromRGB(92, 102, 96)
	Kit.rug(living, F(-24, G, -21, NZ), 15, 11, Color3.fromRGB(122, 58, 50), Color3.fromRGB(196, 166, 124))
	Kit.sofa(living, F(-24, G, -15.5, NZ), 10, SOFA, Color3.fromRGB(196, 156, 92))
	Kit.armchair(living, F(-34, G, -21.5, PX), Color3.fromRGB(132, 86, 62))
	Kit.armchair(living, F(-15.2, G, -22.4, NX), Color3.fromRGB(132, 86, 62))
	Kit.coffeeTable(living, F(-24, G, -21, NZ), 5.2, 3, 2.1, WOOD_MID)
	Kit.magazines(living, F(-22.2, G + 2.1, -21.3, NZ), 3)
	Kit.candle(living, F(-25.9, G + 2.1, -21.7, NZ), 0.7, 0.45)
	Kit.bookStack(living, F(-26, G + 2.1, -20.4, NZ), 2, 12)
	-- end table + lamp at the sofa's left, floor lamp at its right
	local _, livingDrawer = Kit.nightstand(living, F(-30.9, G, -15.5, NZ), WOOD_MID)
	stash("LivingDrawer", spot(living, "EndTableDrawer", livingDrawer.CFrame, livingDrawer.Size + V(0.1, 0.1, 0.1)), "End table drawer", "Ground")
	lamp(living, "Living", F(-30.9, G + 2.45, -15.4, NZ), "table", Color3.fromRGB(160, 120, 80))
	lamp(living, "Living", F(-17.6, G, -15.6, NZ), "floor")
	target("Couch", V(-24, G + 2.5, -16))
	target("CoffeeTable", V(-24, G + 2.4, -21))
	Kit.plant(living, F(-38.2, G, -28.4, PX), 1.6, "tree")
	Kit.plant(living, F(-10.6, G, -0.6, NX), 1.3, "leafy")
	Kit.bookcase(living, F(-9.3, G, -6.5, NX), 6, 1.2, 8.5, 4)
	Kit.ceilingFan(living, V(-24, G + 13, -14))

	-- cozy: knitted throws, extra cushions, two mugs of cocoa still steaming, a basket of blankets
	-- by the fire, warm sconces either side of the TV
	local sofaCF = F(-24, G, -15.5, NZ)
	Kit.throwBlanket(living, sofaCF, 3.8, -2.6, 2.4, Color3.fromRGB(226, 214, 190), Color3.fromRGB(170, 60, 50))
	Kit.throwBlanket(living, F(-34, G, -21.5, PX), 3.8, 0, 2.2, Color3.fromRGB(150, 50, 44), Color3.fromRGB(230, 200, 150))
	Kit.cushion(living, sofaCF * CF(1.2, 2.72, 0.45) * ANG(rad(14), rad(8), rad(5)), 1.2, Color3.fromRGB(226, 196, 140))
	Kit.cushion(living, F(-15.2, G, -22.4, NX) * CF(0, 2.62, 0.45) * ANG(rad(14), 0, rad(-6)), 1.15, Color3.fromRGB(70, 96, 84))
	Kit.cocoa(living, F(-21.9, G + 2.1, -22.0, NZ), Color3.fromRGB(190, 60, 50))
	Kit.cocoa(living, F(-25.0, G + 2.1, -22.1, NZ) * ANG(0, rad(140), 0), Color3.fromRGB(236, 230, 214))
	Kit.basket(living, F(-37.3, G, -5.4, PX), 1.9, 1.5)
	for _, x in { -30.6, -17.4 } do
		sconce(living, F(x, G + 8.4, -29.62, PZ))
	end

	-- grandfather clock in the corner, pendulum swinging behind the glass
	local clockCF = F(-11.4, G, -28.25, PZ)
	local _, clockFace = Kit.grandfatherClock(living, clockCF, WOOD_DARK)
	ctx.Audio.loopOn("ClockTick", clockFace, { Caption = false })
	local pendulum = Instance.new("Model")
	pendulum.Name = "Pendulum"
	pendulum.Parent = living
	local pivot = clockCF * CF(0, 6.6, -0.3)
	Kit.box(pendulum, "Rod", pivot * CF(0, -1.7, 0), V(0.08, 3.3, 0.06), BRASS, KM.Metal)
	Kit.cyl(pendulum, "Bob", pivot * CF(0, -3.45, 0) * ANG(0, rad(90), 0), 0.08, 0.8, BRASS, KM.Metal)
	pendulum:SetAttribute("Pivot", pivot.Position)
	pendulum:SetAttribute("Axis", "Z")
	pendulum:SetAttribute("Amplitude", 12)
	pendulum:SetAttribute("Period", 2)
	CollectionService:AddTag(pendulum, "Swing")

	-- TV on a media console against the front wall, speakers either side
	local _, consoleH = Kit.mediaConsole(living, F(-24, G, -28.2, PZ), 8, 1.8, 2.3, WOOD_DARK)
	for _, x in { -29.4, -18.6 } do
		Kit.speaker(living, F(x, G, -28.5, PZ), 3.6)
	end
	local _, _, screen = Kit.tv(living, F(-24, G + consoleH, -28.55, PZ), 6.4, 3.7, true)
	target("TV", screen.Position)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(560, 340)
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.Parent = screen
	local tvLabel = Instance.new("TextLabel")
	tvLabel.Size = UDim2.fromScale(1, 1)
	tvLabel.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
	tvLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
	tvLabel.Font = Enum.Font.Arcade
	tvLabel.TextScaled = true
	tvLabel.TextWrapped = true
	tvLabel.Text = ""
	tvLabel.Parent = gui
	local tvGlow = Instance.new("SurfaceLight")
	tvGlow.Face = Enum.NormalId.Front
	tvGlow.Range = 18
	tvGlow.Brightness = 0.9
	tvGlow.Angle = 120
	tvGlow.Color = Color3.fromRGB(160, 190, 255)
	tvGlow.Enabled = false
	tvGlow.Parent = screen
	CollectionService:AddTag(tvGlow, "Flicker")

	-- fireplace on the west wall (the chimney is outside that wall)
	local fpCF = F(-39.2, G, -12, PX)
	local _, fireCF = Kit.fireplace(living, fpCF, 13)
	for _, lz in { -4.9, 4.9 } do
		Kit.candle(living, fpCF * CF(lz, 8.6, -1.4), 1.3, 0.4)
	end
	for i, lx in { -2.6, 0.2, 2.8 } do
		Kit.photoFrame(living, fpCF * CF(lx, 8.6, -1.85), 1.1 - i * 0.1, 0.9, WOOD_DARK, i)
	end
	Kit.picture(living, fpCF * CF(0, 10.9, -1.25), 4.2, 2.6, WOOD_DARK, 17)
	-- warm fairy lights draped along the mantel edge
	fairyLights(living, (fpCF * CF(-5.3, 8.45, -2.25)).Position, (fpCF * CF(5.3, 8.45, -2.25)).Position, 0.7, 16)
	-- fire tools, the poker you can take
	local toolBase = fpCF * CF(-6.1, 0, -1.2)
	Kit.lathe(living, "ToolStand", toolBase, { { 0, 0.8 }, { 0.12, 0.8 }, { 0.2, 0.2 } }, C.Black, KM.Metal)
	Kit.vcyl(living, "ToolStandPost", toolBase * CF(0, 1.9, 0), 3.4, 0.12, C.Black, KM.Metal)
	Kit.box(living, "Shovel", toolBase * CF(0.25, 1.9, 0.1) * ANG(0, 0, rad(-6)), V(0.08, 3.2, 0.08), C.Black, KM.Metal)
	Kit.box(living, "ShovelBlade", toolBase * CF(0.33, 0.45, 0.1), V(0.45, 0.5, 0.05), C.Black, KM.Metal)
	local poker = item(living, "FirePoker", (toolBase * CF(-0.3, 1.9, 0.1)).Position, V(0.2, 3.6, 0.2), C.Black, "Poker", "Fire poker")
	poker.CFrame *= ANG(0, 0, rad(8))

	local fireSpot = spot(living, "FireSpot", fireCF * CF(0, 2, 0), V(3.2, 1, 1.2))
	target("Fireplace", (fireCF * CF(0, 3, -1.5)).Position)
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
	local flames = Instance.new("Fire")
	flames.Size = 4
	flames.Heat = 7
	flames.Color = Color3.fromRGB(255, 140, 50)
	flames.SecondaryColor = Color3.fromRGB(255, 60, 20)
	flames.Enabled = false
	flames.Parent = fireSpot
	local fireLight = Instance.new("PointLight")
	fireLight.Color = Color3.fromRGB(255, 150, 70)
	fireLight.Range = 30
	fireLight.Brightness = 2
	fireLight.Shadows = true
	fireLight.Enabled = false
	fireLight.Parent = fireSpot
	local fire = { Lit = false, Logs = false }
	refs.Fire = fire
	local BARK = { Color3.fromRGB(78, 56, 38), Color3.fromRGB(96, 70, 46), Color3.fromRGB(66, 48, 34) }
	-- a log lying across the grate; lx along the firebox, lz toward the back wall
	local function log(lx, ly, lz, len, dia, yaw, k)
		local cf = fireCF * CF(lx, ly, lz) * ANG(0, rad(yaw), 0)
		Kit.cyl(living, "Log", cf, len, dia, BARK[k % 3 + 1], KM.Wood)
		for _, e in { -1, 1 } do
			Kit.cyl(living, "LogEnd", cf * CF(e * (len / 2 + 0.01), 0, 0), 0.04, dia - 0.12, Color3.fromRGB(196, 160, 112), KM.Wood)
		end
	end
	local function stackLogs()
		fire.Logs = true
		-- a proper stack: two logs on the grate, one across them, two crossed on top, kindling
		log(-0.1, 1.5, 0.35, 3.4, 0.62, 4, 1)
		log(0.1, 1.5, -0.25, 3.2, 0.58, -3, 2)
		log(0, 2.0, 0.05, 3.0, 0.55, 2, 3)
		log(-0.7, 2.45, 0, 1.9, 0.45, 38, 4)
		log(0.7, 2.45, 0, 1.9, 0.45, -38, 5)
		for k = 1, 6 do
			local stick = Kit.box(living, "Kindling", fireCF * CF(-0.6 + k * 0.2, 2.25 + (k % 2) * 0.1, 0.05) * ANG(0, rad(20 + k * 27), 0), V(1.3, 0.1, 0.1), Color3.fromRGB(150, 118, 80), KM.Wood)
			stick.CFrame *= ANG(0, 0, rad(k % 2 == 0 and 15 or -12))
		end
	end
	local function lightFire()
		fire.Lit = true
		fireEmitter.Enabled = true
		flames.Enabled = true
		fireLight.Enabled = true
		for k = 0, 5 do
			Kit.box(living, "Ember", fireCF * CF(-1.4 + k * 0.55, 1.0, 0.05 - (k % 2) * 0.3) * ANG(0, rad(k * 31), 0), V(0.5, 0.12, 0.35), Color3.fromRGB(255, 110, 30), KM.Neon)
		end
		ctx.Audio.loopOn("FireCrackle", fireSpot, { Caption = false })
		ctx.Power.setStaticLit("Living", true)
		-- the firelight breathes (client-side flicker)
		CollectionService:AddTag(fireLight, "Flicker")
	end
	-- Jamie got a fire going before everyone arrived: the living room glows from the start.
	-- It's still the light that stays on when the power dies.
	stackLogs()
	lightFire()

	-- the remote is lost in the couch
	local remoteFound = false
	local couchSeat = spot(living, "CouchSearch", CF(-24, G + 2.2, -16), V(8, 0.6, 2.6))
	local couchPrompt
	couchPrompt = ctx.Interaction.prompt(couchSeat, { Action = "Search the cushions", Object = "Couch", Hold = 1, Distance = 7 }, function(player)
		if remoteFound then
			return
		end
		remoteFound = true
		couchPrompt.Enabled = false
		ctx.Inventory.give(player, "Remote")
		ctx.Audio.playAt("Pickup", couchSeat.Position, { Caption = false })
	end)

	local tvState = { Channel = 0, Alert = false, Sound = nil :: Sound?, On = false }
	refs.TV = tvState
	local function tvShow(text: string, bg: Color3, sound: string?)
		if tvState.Sound then
			tvState.Sound:Destroy()
			tvState.Sound = nil
		end
		if text == "" then
			tvLabel.Text = ""
			tvLabel.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
			tvGlow.Enabled = false
			return
		end
		tvLabel.Text = text
		tvLabel.BackgroundColor3 = bg
		tvGlow.Enabled = true
		tvGlow.Color = bg:Lerp(Color3.new(1, 1, 1), 0.5)
		if sound then
			tvState.Sound = ctx.Audio.loopOn(sound, screen, { Caption = false })
		end
	end
	function tvState.setChannel(i: number)
		local ch = ctx.Story.TV[i]
		tvState.Channel = i
		if not ch then
			tvShow("", Color3.new(), nil)
			return
		end
		local bg = ch.Sound == "TVStatic" and Color3.fromRGB(90, 90, 90) or Color3.fromRGB(25, 35, 60)
		tvShow(ch.Name, bg, ch.Sound)
		ctx.Audio.caption(ch.Line, screen.Position, 30)
	end
	function tvState.emergencyAlert(duration: number)
		if not ctx.Power.isOn() then
			return false
		end
		tvState.Alert = true
		tvShow("EMERGENCY ALERT SYSTEM\nFLASH FLOOD WARNING\nHOLLIS COUNTY", Color3.fromRGB(150, 20, 20), "TVAlert")
		ctx.Audio.caption("[The TV switches channels by itself - a loud alert tone]", screen.Position, 70)
		task.delay(duration, function()
			tvState.Alert = false
			if screen.Parent and ctx.Power.isOn() then
				tvState.setChannel(tvState.Channel)
			end
		end)
		return true
	end
	local tvPrompt
	tvPrompt = ctx.Interaction.prompt(screen, { Action = "Turn on", Object = "TV", Distance = 14 }, function(player)
		if not ctx.Power.isOn() then
			ctx.Audio.caption("Dead black screen. No power.", nil, nil, { player })
			return
		end
		if tvState.Alert then
			ctx.Audio.caption("The alert won't let you change the channel.", nil, nil, { player })
			return
		end
		if not tvState.On then
			if not ctx.Inventory.has(player, "Remote") then
				ctx.Audio.caption("No remote. You press the button on the TV itself.", nil, nil, { player })
			end
			tvState.On = true
			tvPrompt.ActionText = "Change channel"
		end
		tvState.setChannel((tvState.Channel % #ctx.Story.TV) + 1)
	end)
	ctx.Power.onChanged(function(on)
		if not on then
			tvShow("", Color3.new(), nil)
		elseif tvState.Channel > 0 then
			tvState.setChannel(tvState.Channel)
		end
	end, screen)

	-- popcorn goes on the coffee table
	local tableSpot = spot(living, "TableSpot", CF(-24, G + 2.4, -21), V(4.4, 0.4, 2.6))
	local servePrompt
	servePrompt = ctx.Interaction.prompt(tableSpot, { Action = "Put down popcorn", Object = "Coffee table", Distance = 7 }, function(player)
		if not ctx.Inventory.take(player, "PopcornBowl") then
			ctx.Audio.caption("The coffee table. Something to eat would go nicely here.", nil, nil, { player })
			return
		end
		servePrompt.Enabled = false
		Kit.popcornBowl(living, F(-24.4, G + 2.1, -21, NZ), 1.8)
		ctx.Objectives.complete("Popcorn")
	end)

	---------------------------------------------------------------------------
	-- KITCHEN
	---------------------------------------------------------------------------
	local kitchen = folder("Kitchen")
	local CAB = Color3.fromRGB(236, 232, 222)
	-- west run (fronts face +X): cabinets with the sink under the window, dishwasher, cabinets, range, cabinets
	local WX = -37.95 -- centre line of the west run (back at -39.15, depth 2.4)
	Kit.cabinets(kitchen, F(WX, G, 10, PX), 12, 2.4, CAB, COUNTER)
	Kit.sink(kitchen, F(WX - 0.15, G + 3.8, 14, PX), 3, 1.8)
	Kit.dishwasher(kitchen, F(WX, G, 17.2, PX), 2.4, 2.4, 3.5)
	Kit.box(kitchen, "Countertop", F(WX - 0.1, G + 3.65, 17.2, PX), V(2.4, 0.3, 2.6), COUNTER, KM.Granite)
	Kit.cabinets(kitchen, F(WX, G, 19.7, PX), 2.6, 2.4, CAB, COUNTER)
	Kit.range(kitchen, F(WX + 0.1, G, 23, PX), 4, 2.6)
	Kit.hood(kitchen, F(WX - 0.1, G + 8.6, 23, PX), 4.4, 2.2, G + 13)
	Kit.cabinets(kitchen, F(WX, G, 26.6, PX), 3.2, 2.4, CAB, COUNTER)
	-- subway tile backsplash behind the counters
	for _, span in { { 4, 11.2 }, { 16.8, 28.2 } } do
		local splash = Kit.box(kitchen, "Backsplash", CF(-39.1, G + 5.9, (span[1] + span[2]) / 2), V(0.08, 4.2, span[2] - span[1]), Color3.fromRGB(240, 240, 236), KM.Tile)
		Textures.apply(splash, "TileWhite", { Enum.NormalId.Right }, Color3.fromRGB(236, 240, 236))
	end
	-- the warm mug in the sink
	local _, mug = Kit.mug(kitchen, F(-38.2, G + 3.82, 13.4, PX), Color3.fromRGB(200, 190, 170))
	mug.CanQuery = true
	ctx.Interaction.document(mug, "WarmMug", { Action = "Look", Object = "Mug in the sink", Distance = 6 }, function()
		ctx.Director.logTruth("WarmMug")
	end)
	-- upper cabinets; the first one is the cupboard with the popcorn
	for _, span in { { 4, 10.8 }, { 17.2, 20.6 }, { 25.4, 28.2 } } do
		Kit.upperCabinets(kitchen, F(-38.35, G + 8, (span[1] + span[2]) / 2, PX), span[2] - span[1], 1.6, 4.4, CAB)
	end
	-- warm light strips under the upper cabinets
	for _, span in { { 4.2, 10.6 }, { 17.4, 20.4 }, { 25.6, 28.0 } } do
		local strip = Kit.box(kitchen, "UnderCabinetLight", CF(-37.85, G + 7.93, (span[1] + span[2]) / 2), V(0.18, 0.05, span[2] - span[1] - 0.4), Color3.fromRGB(255, 214, 160), KM.Neon)
		local l = Instance.new("PointLight")
		l.Range = 9
		l.Brightness = 0.75
		l.Color = Color3.fromRGB(255, 196, 130)
		l.Shadows = false
		l.Parent = strip
		decor(strip, l)
	end
	Kit.kettle(kitchen, F(-37.3, G + 3.65, 22.1, PX), Color3.fromRGB(190, 60, 50))
	for i, z in { 11.6, 16.4 } do
		Kit.plant(kitchen, F(-38.9, G + 3.8, z, PX), 0.4, "leafy", i == 1 and Color3.fromRGB(190, 110, 70) or Color3.fromRGB(230, 226, 214))
	end
	local cupboard = spot(kitchen, "Cupboard", CF(-37.45, G + 10.2, 5.7), V(0.2, 4, 3))
	target("Cupboard", cupboard.Position)
	local popcornTaken = false
	ctx.Interaction.prompt(cupboard, { Action = "Open", Object = "Cupboard", Distance = 8 }, function(player)
		if popcornTaken or ctx.Objectives.isDone("Popcorn") then
			ctx.Audio.caption("Cereal, crackers, a jar of peanut butter.", nil, nil, { player })
			return
		end
		popcornTaken = true
		ctx.Audio.playAt("Pickup", cupboard.Position, { Caption = false })
		ctx.Inventory.give(player, "PopcornBag")
		ctx.Objectives.step("Popcorn", "Bag")
	end)
	-- matches in the drawer beside the range
	local matchDrawer = spot(kitchen, "MatchDrawer", CF(WX + 1.28, G + 3.0, 19.7), V(0.2, 0.7, 2.3))
	target("Matches", matchDrawer.Position)
	ctx.Interaction.pickup(matchDrawer, "Matches", { Action = "Search", Object = "Drawer (matches)", Keep = true })

	-- island with stools on the far side, pendants above, a fruit bowl
	Kit.cabinets(kitchen, F(-25, G, 14.6, NZ), 6, 4.2, Color3.fromRGB(64, 84, 96), COUNTER)
	Kit.box(kitchen, "IslandOverhang", F(-25, G + 3.65, 16.8, NZ), V(6.2, 0.3, 1.3), COUNTER, KM.Granite)
	Kit.fruitBowl(kitchen, F(-24.2, G + 3.8, 14.4, NZ))
	Kit.cookies(kitchen, F(-22.9, G + 3.8, 15.3, NZ))
	Kit.vaseFlowers(kitchen, F(-26.6, G + 3.8, 14.2, NZ), 1.1, Color3.fromRGB(230, 230, 226), Color3.fromRGB(240, 200, 80), 5)
	for _, x in { -27, -25, -23 } do
		Kit.stool(kitchen, F(x, G, 18.6, NZ), WOOD_DARK)
	end
	pendant(kitchen, "Kitchen", V(-26.5, G + 13, 14.6), 2.6)
	pendant(kitchen, "Kitchen", V(-23.5, G + 13, 14.6), 2.6)

	-- dining table with four chairs, place settings and flowers
	-- a warm rug under the dining table takes the chill off the tile
	Kit.rug(kitchen, F(-15, G, 17.5, PX), 12, 9, Color3.fromRGB(140, 62, 48), Color3.fromRGB(206, 176, 128))
	local _, tableH = Kit.diningTable(kitchen, F(-15, G, 17.5, PX), 9, 6, WOOD_MID)
	for _, z in { 15.4, 19.6 } do
		Kit.chair(kitchen, F(-19.4, G, z, PX), WOOD_MID, Color3.fromRGB(150, 60, 50))
		Kit.chair(kitchen, F(-10.6, G, z, NX), WOOD_MID, Color3.fromRGB(150, 60, 50))
		for _, x in { -17, -13 } do
			Kit.box(kitchen, "Placemat", CF(x, G + tableH + 0.01, z), V(1.6, 0.02, 1.2), Color3.fromRGB(190, 170, 130), KM.Fabric)
			Kit.plate(kitchen, F(x, G + tableH + 0.02, z, NZ), 0.9)
		end
	end
	Kit.box(kitchen, "TableRunner", CF(-15, G + tableH + 0.005, 17.5), V(1.6, 0.02, 8), Color3.fromRGB(130, 50, 44), KM.Fabric)
	Kit.vaseFlowers(kitchen, F(-15, G + tableH, 17.5, NZ), 1.3, Color3.fromRGB(70, 110, 140), Color3.fromRGB(220, 80, 110), 7)
	for _, z in { 15.6, 19.4 } do
		Kit.candle(kitchen, F(-15, G + tableH + 0.02, z, NZ), 0.9, 0.32)
	end
	pendant(kitchen, "Kitchen", V(-15, G + 13, 17.5), 3.2, Color3.fromRGB(150, 110, 60))

	-- phone counter against the hall wall: landline, microwave, drawers
	local PCX = -9.9
	Kit.cabinets(kitchen, F(PCX, G, 7, NX), 7, 2.4, CAB, COUNTER)
	local _, phone = Kit.phone(kitchen, F(PCX - 0.2, G + 3.8, 4.8, NX))
	target("Phone", phone.Position)
	ctx.Escape.setupLandline(phone)
	local _, microwave = Kit.microwave(kitchen, F(PCX + 0.2, G + 3.8, 8.6, NX))
	target("Microwave", microwave.Position)
	local mwState = "Empty" -- Empty -> Cooking -> Ready -> Done
	local mwPrompt
	mwPrompt = ctx.Interaction.prompt(microwave, { Action = "Make popcorn", Object = "Microwave", Hold = 0.5, Distance = 7 }, function(player)
		if mwState == "Cooking" then
			return
		end
		if mwState == "Ready" then
			mwState = "Done"
			ctx.Inventory.give(player, "PopcornBowl")
			mwPrompt.Enabled = false
			return
		end
		if not ctx.Power.isOn() then
			ctx.Audio.caption("The microwave is dead. No power.", nil, nil, { player })
			return
		end
		if not ctx.Inventory.take(player, "PopcornBag") then
			ctx.Director.think(player, "I need a bag of popcorn first. They're in the cupboard.")
			return
		end
		mwState = "Cooking"
		mwPrompt.Enabled = false
		local hum = ctx.Audio.loopOn("MicrowaveHum", microwave, { Caption = false })
		ctx.Audio.caption("[Popcorn popping]", microwave.Position, 35)
		for _ = 1, 8 do
			ctx.Noise.emit(microwave.Position, ctx.Config.Noise.Microwave, "Microwave", player)
			task.wait(1)
		end
		if hum then
			hum:Destroy()
		end
		ctx.Audio.playAt("MicrowaveBeep", microwave.Position)
		ctx.Objectives.step("Popcorn", "Cook")
		mwState = "Ready"
		mwPrompt.ActionText = "Take the popcorn"
		mwPrompt.HoldDuration = 0
		mwPrompt.Enabled = true
	end)
	stash("JunkDrawer", spot(kitchen, "JunkDrawer", CF(PCX - 1.28, G + 3.0, 4.67), V(0.2, 0.7, 2.1)), "Junk drawer", "Ground")
	stash("KitchenDrawer", spot(kitchen, "Drawer", CF(PCX - 1.28, G + 3.0, 9.33), V(0.2, 0.7, 2.1)), "Kitchen drawer", "Ground")
	Kit.box(kitchen, "Corkboard", CF(-8.42, G + 7, 7), V(0.1, 2.4, 3.4), Color3.fromRGB(176, 136, 90), KM.Cardboard)
	for i = 0, 3 do
		Kit.box(kitchen, "Note", CF(-8.48, G + 6.4 + (i % 2) * 1.0, 5.9 + i * 0.7) * ANG(rad(i * 4 - 6), 0, 0), V(0.02, 0.8, 0.6), Color3.fromHSV(i * 0.15 + 0.1, 0.25, 0.95), KM.Plastic)
	end

	-- fridge on the back wall, with Mom's note and the pizza menu under magnets
	local _, fridge, noteFace = Kit.fridge(kitchen, F(-27.1, G, 27.5, NZ), 5, 3.2, 10.4)
	Kit.upperCabinets(kitchen, F(-27.1, G + 10.8, 28.3, NZ), 5.2, 1.6, 1.6, CAB)
	ctx.Audio.loopOn("FridgeHum", fridge, { Caption = false })
	local note = paper(kitchen, "FridgeNote", noteFace * CF(-0.2, 5.8, -0.02), V(1.4, 1.8, 0.04))
	ctx.Interaction.document(note, "FridgeNote", { Object = "Note on the fridge", Distance = 6 })
	local menu = paper(kitchen, "PizzaMenu", noteFace * CF(0.25, 8.4, -0.02) * ANG(0, 0, rad(-4)), V(1.3, 1.9, 0.04))
	menu.Color = Color3.fromRGB(200, 60, 45)
	Kit.box(kitchen, "MenuBand", noteFace * CF(0.25, 9.0, -0.045) * ANG(0, 0, rad(-4)), V(1.2, 0.35, 0.01), Color3.fromRGB(245, 230, 190), KM.Plastic)
	for _, p in { V(-0.2, 6.6, 0), V(0.25, 9.25, 0), V(-0.4, 4.4, 0) } do
		Kit.cyl(kitchen, "Magnet", noteFace * CF(p.X, p.Y, -0.07) * ANG(0, rad(90), 0), 0.06, 0.26, Color3.fromRGB(60, 120, 200), KM.Plastic)
	end
	Kit.box(kitchen, "Drawing", noteFace * CF(-0.3, 4.1, -0.02), V(1.2, 0.9, 0.02), Color3.fromRGB(250, 250, 244), KM.Plastic)
	target("Fridge", menu.Position)
	ctx.Interaction.document(menu, "Menu", { Object = "Pizza menu", Distance = 6 }, function()
		ctx.Objectives.step("OrderPizza", "Menu")
	end)
	local kitchenRefs = { LasagnaGone = false, FridgePos = fridge.Position }
	refs.Kitchen = kitchenRefs
	ctx.Interaction.prompt(fridge, { Action = "Open", Object = "Fridge", Distance = 6 }, function(player)
		ctx.Audio.playAt("DoorClose", fridge.Position, { Caption = false, Volume = 0.3 })
		if kitchenRefs.LasagnaGone then
			ctx.Audio.caption("Soda, eggs, condiments. The lasagna Mom left for you is gone. Dish and all.", nil, nil, { player })
		else
			ctx.Audio.caption("Soda, eggs, condiments - and the lasagna Mom left, under foil.", nil, nil, { player })
		end
	end)
	-- step-on trash can by the back door
	local trashCF = F(-14.2, G, 28.1, NZ)
	Kit.lathe(kitchen, "TrashCan", trashCF, { { 0, 1.8 }, { 0.15, 1.9 }, { 2.9, 2.0 } }, C.Steel, KM.Metal)
	Kit.box(kitchen, "Pedal", trashCF * CF(0, 0.12, -1.05), V(0.8, 0.1, 0.4), C.Black, KM.Plastic)
	local trashLid = Kit.ellipsoid(kitchen, "TrashLid", trashCF * CF(0, 3.0, 0), V(2.05, 0.5, 2.05), C.Steel, KM.Metal)
	trashLid.CanQuery = true
	local trashDoc = ctx.Interaction.document(trashLid, "TrashCan", { Action = "Look", Object = "Kitchen trash", Distance = 6 })
	trashDoc.Enabled = false
	function kitchenRefs.takeLasagna()
		kitchenRefs.LasagnaGone = true
		trashDoc.Enabled = true
		Kit.box(kitchen, "LasagnaDish", trashCF * CF(0.1, 3.35, 0) * ANG(rad(20), rad(30), 0), V(1.4, 0.3, 1.0), Color3.fromRGB(220, 230, 235), KM.Glass, { Transparency = 0.3 })
	end

	-- key hooks beside the back door
	local hookBoard = Kit.solid(kitchen, "KeyHooks", CF(-15.9, G + 6, 29.35), V(2.2, 0.8, 0.14), WOOD_DARK, KM.Wood)
	for k = 0, 3 do
		Kit.box(kitchen, "Hook", CF(-16.7 + k * 0.55, G + 5.7, 29.2), V(0.08, 0.08, 0.2), BRASS, KM.Metal)
	end
	local keys = Kit.box(kitchen, "CarKeysOnHook", CF(-15.85, G + 5.3, 29.18), V(0.35, 0.6, 0.08), Color3.fromRGB(190, 190, 195), KM.Metal)
	keys.CanQuery = true
	ctx.Escape.setupKeyHook(keys, hookBoard)
	Kit.rug(kitchen, F(-20, G, 27.6, NZ), 5, 3, Color3.fromRGB(80, 70, 60))
	Kit.plant(kitchen, F(-33.5, G, 28.3, NZ), 1.2, "snake", Color3.fromRGB(236, 236, 232))

	---------------------------------------------------------------------------
	-- HALLWAY / FOYER
	---------------------------------------------------------------------------
	local hall = folder("Hallway")
	Kit.rug(hall, F(2, G, -18, NZ), 5, 18, Color3.fromRGB(112, 50, 46), Color3.fromRGB(204, 172, 120))
	Kit.bench(hall, F(10.3, G, -26.6, NX), 5, WOOD_MID, Color3.fromRGB(122, 60, 50))
	for i, col in { Color3.fromRGB(40, 40, 46), Color3.fromRGB(120, 60, 40), Color3.fromRGB(200, 200, 205) } do
		Kit.shoe(hall, F(8.8, G, -28.6 + i * 1.3, NX), col)
		Kit.shoe(hall, F(8.8, G, -28.1 + i * 1.3, NX), col)
	end
	Kit.coatRack(hall, F(10.8, G, -12.6, NX), { Color3.fromRGB(60, 70, 90), Color3.fromRGB(140, 110, 70) })
	local _, conH = Kit.consoleTable(hall, F(-6.55, G, -26, PX), 5.4, 1.5, WOOD_DARK)
	Kit.mirror(hall, F(-7.62, G + 7.2, -26, PX), 3.4, 4.2, BRASS)
	Kit.bowl(hall, F(-6.5, G + conH, -24.6, PX), 1.1, Color3.fromRGB(70, 110, 140))
	lamp(hall, "Hallway", F(-6.55, G + conH, -27.7, PX), "table", Color3.fromRGB(200, 190, 170))
	stash("HallConsole", spot(hall, "ConsoleDrawer", CF(-5.9, G + conH - 0.45, -26), V(0.2, 0.5, 2.6)), "Hall table drawer", "Ground")
	Kit.umbrellaStand(hall, F(8, G, -28.5, NZ))
	Kit.plant(hall, F(-6.6, G, -11.4, PX), 1.4, "snake")
	sconce(hall, F(11.62, G + 7.8, -14.4, NX))
	sconce(hall, F(-7.62, G + 7.8, -9.4, PX))
	-- family photos climbing the stairs with the treads
	for i, z in { -3, 1.5, 6, 10.5 } do
		local y = G + (z + 6) / 22.4 * 14 + 5.4
		local w, h = (i % 2 == 0) and 1.7 or 2.2, (i % 2 == 0) and 2.2 or 1.7
		Kit.picture(hall, F(-7.6, y, z, PX), w, h, i % 2 == 0 and WOOD_DARK or BRASS, 60 + i)
	end

	---------------------------------------------------------------------------
	-- OFFICE (key-locked)
	---------------------------------------------------------------------------
	local office = folder("Office")
	Kit.rug(office, F(26, G, -20, NZ), 16, 12, Color3.fromRGB(58, 68, 92), Color3.fromRGB(172, 150, 110))
	local _, deskH = Kit.desk(office, F(32, G, -21.5, PX), 6.8, 3.4, WOOD_DARK)
	Kit.officeChair(office, F(35.2, G, -21.5, NX), Color3.fromRGB(46, 40, 38))
	Kit.monitor(office, F(31.0, G + deskH, -21.8, PX), 2.8, 1.8)
	Kit.keyboard(office, F(32.6, G + deskH, -21.8, PX))
	local invoice = paper(office, "Invoice", CF(32.4, G + deskH + 0.02, -19.6) * ANG(0, rad(12), 0), V(1.5, 0.03, 1.9))
	ctx.Interaction.document(invoice, "Invoice", { Object = "Invoice on the desk", Distance = 6 })
	Kit.mug(office, F(31.4, G + deskH, -19.1, PX), Color3.fromRGB(60, 80, 120))
	lamp(office, "Office", F(31.1, G + deskH, -24.1, PX), "table", Color3.fromRGB(40, 60, 50))
	local deskDrawer = spot(office, "DeskDrawer", CF(33.8, G + 3.0, -19.1), V(0.2, 0.9, 1.7))
	target("OfficeKeys", deskDrawer.Position)
	ctx.Interaction.pickup(deskDrawer, "CarKeys", { Action = "Search", Object = "Desk drawer (spare keys)", Keep = true })
	Kit.bookcase(office, F(38.5, G, -25.8, NX), 6.5, 1.2, 10, 5)
	Kit.bookcase(office, F(38.5, G, -16.5, NX), 6.5, 1.2, 10, 5)
	Kit.filingCabinet(office, F(14.1, G, -27.9, PZ), 3)
	Kit.sofa(office, F(19.6, G, -27.2, PZ), 5, Color3.fromRGB(96, 52, 40), nil, { Name = "Loveseat" })
	Kit.plant(office, F(37.9, G, -11.3, NZ), 1.4, "tree")

	---------------------------------------------------------------------------
	-- DOWNSTAIRS BATHROOM
	---------------------------------------------------------------------------
	local bath = folder("Bathroom")
	-- door on the south wall (from the back hall); vanity north, toilet east, towel west
	Kit.vanity(bath, F(19.3, G, 2.3, NZ), 4.2, 2, Color3.fromRGB(70, 90, 110), Color3.fromRGB(235, 235, 232), 1)
	Kit.mirror(bath, F(19.3, G + 6.6, 3.62, NZ), 3.2, 3.4, WOOD_DARK)
	item(bath, "Scissors", V(17.7, G + 3.45, 2.1), V(0.8, 0.1, 0.35), Color3.fromRGB(210, 60, 60), "Scissors", "Scissors")
	Kit.toilet(bath, F(19.8, G, -1.6, NX))
	Kit.towel(bath, F(12.55, G + 5.6, 1.2, PX), 2.4, Color3.fromRGB(120, 160, 190))
	Kit.rug(bath, F(16.3, G, 0.2, PX), 3, 2.4, Color3.fromRGB(110, 140, 160))
	Kit.plant(bath, F(21.0, G + 3.4, 2.6, NZ), 0.6, "snake", Color3.fromRGB(240, 240, 236))

	---------------------------------------------------------------------------
	-- BACK HALL (front hall -> mudroom -> garage)
	---------------------------------------------------------------------------
	local mudHall = folder("MudHall")
	Kit.rug(mudHall, F(18, G, -7, PX), 7, 3, Color3.fromRGB(96, 80, 64))

	---------------------------------------------------------------------------
	-- MUDROOM
	---------------------------------------------------------------------------
	local mud = folder("Mudroom")
	Kit.bench(mud, F(28, G, -8.35, PZ), 8, WOOD_LIGHT, Color3.fromRGB(70, 90, 110))
	for i = 0, 3 do
		Kit.box(mud, "Basket", CF(25.2 + i * 1.9, G + 0.98, -8.35), V(1.5, 0.9, 1.4), Color3.fromRGB(170, 130, 80), KM.Fabric)
	end
	Kit.box(mud, "HookRail", CF(28, G + 7.8, -9.55), V(8, 0.5, 0.2), WOOD_LIGHT, KM.Wood)
	for i = 0, 3 do
		Kit.coat(mud, F(25 + i * 2, G + 7.6, -9.4, PZ), Color3.fromHSV(i * 0.22, 0.35, 0.42))
	end
	Kit.box(mud, "Shelf", CF(37, G + 5.15, -8.75), V(5, 0.3, 1.8), WOOD_LIGHT, KM.Wood, { CanCollide = true })
	for _, x in { 35, 39 } do
		Kit.box(mud, "ShelfBracket", CF(x, G + 4.7, -9.4), V(0.2, 0.7, 0.6), WOOD_DARK, KM.Wood)
	end
	Kit.box(mud, "Basket", CF(35.6, G + 5.8, -8.8), V(1.6, 1.0, 1.5), Color3.fromRGB(170, 130, 80), KM.Fabric)
	stash("MudShelf", spot(mud, "ShelfSpot", CF(38.3, G + 5.6, -8.6), V(1.6, 0.7, 1.2)), "Mudroom shelf", "Ground", true)
	Kit.box(mud, "KeyBoard", CF(35.5, G + 7.6, -9.55), V(2, 1, 0.14), WOOD_DARK, KM.Wood)
	local bkey = Kit.box(mud, "BasementKey", CF(35.4, G + 6.9, -9.42), V(0.35, 0.6, 0.08), BRASS, KM.Metal)
	bkey.CanQuery = true
	ctx.Interaction.pickup(bkey, "BasementKey", { Object = "Key tagged 'BSMT'" })
	for i = 0, 1 do
		Kit.shoe(mud, F(26 + i * 0.6, G, -7.1, NZ), C.Black)
	end
	Kit.box(mud, "BootTray", CF(27, G + 0.04, -7.1), V(3, 0.08, 1.6), Color3.fromRGB(40, 40, 40), KM.Rubber)
	Kit.rug(mud, F(31, G, -2, PX), 8, 5, Color3.fromRGB(70, 60, 50))

	---------------------------------------------------------------------------
	-- DEN
	---------------------------------------------------------------------------
	local den = folder("Den")
	Kit.rug(den, F(21.5, G, 13, NZ), 16, 13, Color3.fromRGB(60, 72, 64), Color3.fromRGB(170, 150, 110))
	Kit.sofa(den, F(21.5, G, 17.5, NZ), 10, Color3.fromRGB(110, 86, 64), Color3.fromRGB(60, 90, 70))
	Kit.coffeeTable(den, F(21.5, G, 11.8, NZ), 5.6, 2.6, 2, WOOD_MID)
	Kit.remote(den, F(20.6, G + 2, 11.6, NZ) * ANG(0, rad(20), 0))
	Kit.controller(den, F(22.6, G + 2, 11.9, NZ) * ANG(0, rad(-15), 0))
	local _, denConsoleH = Kit.mediaConsole(den, F(21.5, G, 5.6, PZ), 9, 1.8, 2.3, WOOD_DARK)
	Kit.tv(den, F(21.5, G + denConsoleH, 5.3, PZ), 7, 4.1, true)
	for _, x in { 15.7, 27.3 } do
		Kit.speaker(den, F(x, G, 5.35, PZ), 3.2)
	end
	local _, endDrawer = Kit.nightstand(den, F(15.2, G, 17.3, PX), WOOD_MID)
	stash("DenDrawer", spot(den, "EndTableDrawer", endDrawer.CFrame, endDrawer.Size + V(0.1, 0.1, 0.1)), "End table drawer", "Ground")
	lamp(den, "Den", F(15.2, G + 2.45, 17.3, PX), "table", Color3.fromRGB(180, 150, 90))
	Kit.beanbag(den, F(31, G, 11, NX) * ANG(0, rad(30), 0), Color3.fromRGB(150, 50, 50))
	Kit.bookcase(den, F(38.5, G, 10, NX), 6, 1.2, 8, 4)
	wardrobe(den, "Den closet", 36.35, 23, 39.15, 28.4, G, NX, "Den", WHITE_WOOD)
	lamp(den, "Den", F(28.2, G, 18.8, NZ), "floor")
	Kit.ceilingFan(den, V(24, G + 13, 15))
	Kit.plant(den, F(37, G, 7.2, NX), 1.4, "leafy")
	-- cozy: throw and cushion on the sofa, cocoa and cookies for movie night, blanket basket
	local denSofa = F(21.5, G, 17.5, NZ)
	Kit.throwBlanket(den, denSofa, 3.8, 2.8, 2.4, Color3.fromRGB(196, 150, 90), Color3.fromRGB(120, 60, 40))
	Kit.cushion(den, denSofa * CF(-1.4, 2.72, 0.45) * ANG(rad(14), rad(-8), rad(-5)), 1.2, Color3.fromRGB(190, 120, 70))
	Kit.cocoa(den, F(19.5, G + 2, 12.4, NZ), Color3.fromRGB(70, 100, 140))
	Kit.cookies(den, F(23.6, G + 2, 12.5, NZ))
	Kit.basket(den, F(14.2, G, 21.4, PX), 1.9, 1.5, nil, { Color3.fromRGB(120, 60, 40), Color3.fromRGB(226, 214, 190), Color3.fromRGB(196, 150, 90) })

	---------------------------------------------------------------------------
	-- GARAGE
	---------------------------------------------------------------------------
	local garage = folder("Garage")
	-- Mom's Honda, parked nose-in (its local +Z points out through the garage door)
	local car, _, driverDoor = Kit.sedan(garage, F(53, G - 0.05, -17, PZ), Color3.fromRGB(110, 28, 30))
	car.Name = "Honda"
	target("Car", driverDoor.Position)
	ctx.Escape.setupCar(car, driverDoor, {})

	-- breaker panel on the house wall
	local panel = Kit.solid(garage, "BreakerPanel", CF(40.7, G + 6.2, -12.75), V(0.4, 4.5, 3.5), Color3.fromRGB(150, 150, 150), KM.Metal)
	Kit.box(garage, "PanelDoorSeam", CF(40.92, G + 6.2, -12.75), V(0.02, 4.3, 0.04), Color3.fromRGB(90, 90, 90), KM.Metal)
	Kit.box(garage, "PanelConduit", CF(40.7, G + 11.2, -12.75), V(0.3, 5.5, 0.3), Color3.fromRGB(130, 130, 130), KM.Metal)
	target("Breaker", panel.Position)
	local leverOn = CF(41.05, G + 7.8, -12.75)
	local leverOff = CF(41.05, G + 7.2, -12.75)
	local lever = B.part(garage, { Name = "MainLever", Size = V(0.3, 0.6, 0.9), CFrame = leverOn, Color = Color3.fromRGB(200, 40, 30), CanCollide = false })
	ctx.Escape.setupBreaker(panel, lever, leverOn, leverOff)
	local opener = Kit.solid(garage, "OpenerButton", CF(40.65, G + 4.85, -8.55), V(0.3, 0.7, 0.7), C.White, KM.Plastic)
	Kit.box(garage, "OpenerLight", CF(40.82, G + 4.95, -8.55), V(0.02, 0.2, 0.2), Color3.fromRGB(80, 200, 90), KM.Neon)
	target("GarageButton", opener.Position)
	Kit.box(garage, "OpenerRail", CF(53, G + 10.65, -17.75), V(0.4, 0.3, 23.5), C.Steel, KM.Metal)
	Kit.box(garage, "OpenerMotor", CF(53, G + 10.3, -5.75), V(3, 1.4, 2.5), Color3.fromRGB(220, 220, 214), KM.Plastic)
	Kit.box(garage, "OpenerBulb", CF(53, G + 9.55, -5.75), V(1.2, 0.1, 1.2), Color3.fromRGB(250, 240, 210), KM.Plastic)
	local cord = Kit.box(garage, "ReleaseCord", CF(53, G + 9.15, -26.1), V(0.1, 2.7, 0.1), Color3.fromRGB(200, 40, 30), KM.Fabric)
	cord.CanQuery = true
	Kit.ball(garage, "CordHandle", V(53, G + 7.7, -26.1), 0.35, Color3.fromRGB(200, 40, 30), KM.Plastic)
	ctx.Escape.setupGarageDoor(refs.GarageDoor, opener, cord)

	-- workbench: walkies + tape, pegboard tools
	Kit.workbench(garage, F(63.3, G, -21.5, NX), 11, 3.4)
	Kit.box(garage, "Pegboard", CF(65.45, G + 6.8, -21.5), V(0.2, 4.5, 11), Color3.fromRGB(170, 140, 100), KM.Wood)
	for i, kind in { "hammer", "wrench", "saw", "screwdriver", "wrench", "hammer" } do
		Kit.tool(garage, F(65.3, G + 6.8 + (i % 2) * 0.6, -26 + i * 1.6, NX), kind)
	end
	item(garage, "Walkie", V(63.2, G + 3.9, -24.6), V(0.6, 1, 0.35), Color3.fromRGB(40, 40, 45), "Walkie", "Walkie-talkie")
	item(garage, "Walkie", V(63.2, G + 3.9, -23.4), V(0.6, 1, 0.35), Color3.fromRGB(40, 40, 45), "Walkie", "Walkie-talkie")
	stash("Workbench", spot(garage, "BenchSpot", CF(63.5, G + 3.7, -19.5), V(1.6, 0.6, 1.6)), "Workbench", "Ground", true)
	Kit.paintCan(garage, F(62.3, G + 3.4, -17.6, NX), Color3.fromRGB(60, 110, 160))
	Kit.shelving(garage, F(43, G, 4.5, NZ), 4.6, 1.8, 7.5, 4, 6)
	Kit.cardboardBox(garage, F(60.5, G, 3.9, NZ), V(4, 3.2, 2.8))
	Kit.cardboardBox(garage, F(64, G, 4.1, NZ), V(2.6, 2.4, 2.4))
	Kit.cardboardBox(garage, F(60.8, G + 3.2, 4.0, NZ) * ANG(0, rad(8), 0), V(2.6, 2.0, 2.2))
	for i = 0, 1 do
		Kit.trashBin(garage, F(47.3 + i * 2.6, G, 4.2, NZ), Color3.fromRGB(40, 70, 50))
	end

	-- the woodpile (for the fireplace)
	Kit.woodpile(garage, F(62.5, G, -10.5, NX), 4)
	local pileSpot = spot(garage, "PileSpot", CF(62.5, G + 1.6, -10.5), V(3.4, 3.2, 3.9))
	target("Woodpile", pileSpot.Position)
	ctx.Interaction.prompt(pileSpot, { Action = "Take firewood", Object = "Woodpile", Hold = 0.6, Distance = 7 }, function(player)
		if ctx.Inventory.has(player, "Firewood") then
			ctx.Audio.caption("Your arms are full already.", nil, nil, { player })
			return
		end
		if refs.Fire and refs.Fire.Logs then
			ctx.Audio.caption("The fire's already going. There's plenty of wood in it.", nil, nil, { player })
			return
		end
		ctx.Audio.playAt("LogDrop", pileSpot.Position, { Caption = false, Volume = 0.4 })
		ctx.Inventory.give(player, "Firewood")
	end)

	-- his route: stepladder under the hatch, muddy prints from the side door
	local gh = L.GarageHatch
	local ladderModel = Instance.new("Model")
	ladderModel.Name = "Stepladder"
	ladderModel.Parent = garage
	local lx, lz = (gh.x0 + gh.x1) / 2, (gh.z0 + gh.z1) / 2
	local ladderColor = Color3.fromRGB(190, 190, 180)
	for _, s in { -1, 1 } do
		for _, e in { -1, 1 } do
			local foot = V(lx + s * 1, G, lz + e * 1.6)
			local top = V(lx + s * 0.8, G + 11.8, lz + e * 0.25)
			B.part(ladderModel, { Name = "LadderLeg", Size = V(0.25, (top - foot).Magnitude, 0.3), CFrame = CFrame.lookAt((foot + top) / 2, top) * ANG(rad(90), 0, 0), Color = ladderColor, Material = KM.Metal })
		end
	end
	for k = 1, 5 do
		local t = k / 6
		B.part(ladderModel, { Name = "Rung", Size = V(2, 0.15, 0.5), CFrame = CF(lx, G + 11.8 * t, lz - 1.6 + 1.35 * t), Color = ladderColor, Material = KM.Metal })
	end
	B.part(ladderModel, { Name = "LadderTop", Size = V(2.1, 0.25, 0.9), CFrame = CF(lx, G + 11.9, lz), Color = Color3.fromRGB(200, 60, 40), Material = KM.Plastic })
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
	Kit.rug(master, F(-30, U, -14.5, PX), 12, 16, Color3.fromRGB(150, 140, 120))
	local _, masterBedCF = bed(master, "Under the master bed", -39.15, -18.25, -30.15, -10.75, U, Color3.fromRGB(62, 76, 110), PX, NX, "Master", WOOD_DARK)
	Kit.bedThrow(master, masterBedCF, 7.5, 9, Color3.fromRGB(196, 170, 130), Color3.fromRGB(140, 60, 50))
	for i, z in { -20.1, -8.9 } do
		local _, md = Kit.nightstand(master, F(-38.1, U, z, PX), WOOD_DARK)
		stash("MasterDrawer" .. i, spot(master, "NightstandDrawer", md.CFrame, md.Size + V(0.1, 0.1, 0.1)), "Nightstand drawer", "Upstairs")
		lamp(master, "Master", F(-38.1, U + 2.45, z, PX), "table", Color3.fromRGB(200, 196, 188))
	end
	wardrobe(master, "Master wardrobe", -27.5, -29.15, -20.5, -26.35, U, PZ, "Master", WOOD_DARK)
	local _, dresserH = Kit.dresser(master, F(-9.6, U, -24.5, NX), 6, WOOD_DARK)
	Kit.mirror(master, F(-8.45, U + dresserH + 2.3, -24.5, NX), 4, 3.4, WOOD_DARK)
	item(master, "Purse", V(-9.6, U + dresserH + 0.55, -26.3), V(1.4, 1.1, 0.7), Color3.fromRGB(110, 60, 45), "PepperSpray", "Pepper spray (mom's old purse)", ctx.Config.PepperSpray.Uses)
	Kit.photoFrame(master, F(-9.8, U + dresserH, -23, NX), 0.9, 0.7, BRASS, 21)
	Kit.vaseFlowers(master, F(-9.6, U + dresserH, -21.9, NX), 0.9, Color3.fromRGB(240, 240, 236), Color3.fromRGB(230, 140, 170), 9)
	Kit.armchair(master, F(-36.9, U, -27.2, PZ), Color3.fromRGB(200, 190, 170))
	Kit.throwBlanket(master, F(-36.9, U, -27.2, PZ), 3.8, 0, 2.2, Color3.fromRGB(120, 130, 150), Color3.fromRGB(230, 226, 214))
	Kit.candle(master, F(-9.4, U + dresserH, -24.6, NX), 0.8, 0.4)
	Kit.ceilingFan(master, V(-24, U + 13, -12))
	Kit.plant(master, F(-10.6, U, -2.6, NX), 1.3, "leafy")

	local mbath = folder("MasterBath")
	Kit.bathtub(mbath, F(-35.15, U, 9.3, NZ), 8, 3.6)
	Kit.vanity(mbath, F(-16, U, 10.2, NZ), 8, 2, WOOD_DARK, Color3.fromRGB(235, 235, 232), 2)
	Kit.mirror(mbath, F(-16, U + 6.6, 11.6, NZ), 7, 3.4, WOOD_DARK)
	Kit.toilet(mbath, F(-10.3, U, 2.3, PZ))
	Kit.towel(mbath, F(-24, U + 5.6, 11.55, NZ), 2.6, Color3.fromRGB(230, 226, 214))
	Kit.rug(mbath, F(-21, U, 6, PX), 4, 6, Color3.fromRGB(200, 200, 196))
	Kit.plant(mbath, F(-38.2, U, 2.2, PX), 1.1, "snake", Color3.fromRGB(240, 240, 236))

	---------------------------------------------------------------------------
	-- JAMIE'S ROOM
	---------------------------------------------------------------------------
	local jamie = folder("Jamie")
	Kit.rug(jamie, F(-24, U, 20, PX), 10, 12, Color3.fromRGB(40, 50, 70))
	local _, jamieBedCF = bed(jamie, "Under Jamie's bed", -39.15, 13.3, -31.35, 18.3, U, Color3.fromRGB(40, 70, 120), PX, NX, "Jamie", WOOD_MID)
	Kit.bedThrow(jamie, jamieBedCF, 5, 7.8, Color3.fromRGB(150, 60, 50), Color3.fromRGB(230, 220, 200))
	-- fairy lights along the wall over the bed, with polaroids clipped to the wire
	do
		local a, b, sag = V(-39.5, U + 10.6, 12.8), V(-39.5, U + 10.6, 29.2), 1.0
		fairyLights(jamie, a, b, sag, 20)
		for i, t in { 0.08, 0.17, 0.27, 0.82, 0.92 } do
			local p = a:Lerp(b, t) - V(0, math.sin(t * math.pi) * sag + 0.5, 0)
			local tilt = ANG(0, rad(90), rad((i % 2 == 0 and 6 or -5)))
			Kit.box(jamie, "Polaroid", CF(p) * tilt, V(0.55, 0.66, 0.03), Color3.fromRGB(246, 244, 238), KM.Plastic)
			Kit.box(jamie, "PolaroidPhoto", CF(p + V(0.02, 0.06, 0)) * tilt, V(0.45, 0.42, 0.02), Color3.fromHSV((i * 0.17) % 1, 0.35, 0.7), KM.Plastic)
		end
	end
	local _, jd = Kit.nightstand(jamie, F(-38.1, U, 20.4, PX), WOOD_MID)
	stash("JamieDrawer", spot(jamie, "NightstandDrawer", jd.CFrame, jd.Size + V(0.1, 0.1, 0.1)), "Nightstand drawer", "Upstairs")
	Kit.laptop(jamie, F(-38.1, U + 2.45, 20.4, PX) * ANG(0, rad(15), 0), false)
	wardrobe(jamie, "Jamie's closet", -19.5, 26.35, -13.5, 29.15, U, NZ, "Jamie", WHITE_WOOD)
	local _, jDeskH = Kit.desk(jamie, F(-31.5, U, 27.6, NZ), 6, 3, WOOD_LIGHT)
	Kit.officeChair(jamie, F(-31.9, U, 25.1, PZ), Color3.fromRGB(30, 30, 34))
	lamp(jamie, "Jamie", F(-29.1, U + jDeskH, 28.3, NZ), "table", Color3.fromRGB(30, 30, 34))
	Kit.laptop(jamie, F(-32.1, U + jDeskH, 27.6, NZ), true)
	Kit.bookStack(jamie, F(-33.9, U + jDeskH, 28.3, NZ), 3, 31)
	Kit.bookcase(jamie, F(-38.55, U, 27.4, PX), 3.4, 1.2, 7, 3)
	Kit.beanbag(jamie, F(-22, U, 17, NX) * ANG(0, rad(-20), 0), Color3.fromRGB(40, 90, 150))
	Kit.guitar(jamie, F(-9.7, U, 15, NX))
	Kit.clothesPile(jamie, F(-23.5, U, 22.5, NZ), 5)
	Kit.controller(jamie, F(-21.5, U + 2.2, 16.6, NX))

	---------------------------------------------------------------------------
	-- UPSTAIRS HALL
	---------------------------------------------------------------------------
	local uhall = folder("UpperHall")
	wardrobe(uhall, "Linen wardrobe", 9.2, -8.5, 11.35, -3.5, U, NX, "UpperHall", WHITE_WOOD)
	Kit.rug(uhall, F(3, U, -18, NZ), 5, 18, Color3.fromRGB(112, 50, 46), Color3.fromRGB(204, 172, 120))
	local _, htH = Kit.consoleTable(uhall, F(10.6, U, -25, NX), 4, 1.4, WOOD_DARK)
	Kit.plant(uhall, F(10.6, U + htH, -25.9, NX), 0.9, "leafy", Color3.fromRGB(240, 240, 236))
	Kit.photoFrame(uhall, F(10.8, U + htH, -24.1, NX), 0.8, 0.6, WOOD_DARK, 41)
	target("SignalSpot", V(37, U + 3, 1))
	sconce(uhall, F(11.62, U + 7.8, -20, NX))
	sconce(uhall, F(11.62, U + 7.8, 10, NX))

	---------------------------------------------------------------------------
	-- GUEST ROOM
	---------------------------------------------------------------------------
	local guest = folder("Guest")
	Kit.rug(guest, F(21, U, -17, NZ), 11, 8, Color3.fromRGB(150, 120, 90))
	local _, guestBedCF = bed(guest, "Under the guest bed", 14.1, -29.15, 20.6, -21.6, U, Color3.fromRGB(150, 130, 100), PZ, NZ, "Guest", WOOD_LIGHT)
	Kit.bedThrow(guest, guestBedCF, 6.5, 7.55, Color3.fromRGB(110, 130, 110), Color3.fromRGB(230, 220, 200))
	local _, gd = Kit.nightstand(guest, F(21.8, U, -28.1, PZ), WOOD_LIGHT)
	stash("GuestDrawer", spot(guest, "NightstandDrawer", gd.CFrame, gd.Size + V(0.1, 0.1, 0.1)), "Nightstand drawer", "Upstairs")
	lamp(guest, "Guest", F(21.8, U + 2.45, -28.1, PZ), "table", Color3.fromRGB(190, 170, 130))
	wardrobe(guest, "Guest wardrobe", 32, -9.15, 38, -6.35, U, NZ, "Guest", WOOD_LIGHT)
	Kit.cardboardBox(guest, F(37.4, U, -27.6, PZ), V(3, 2.8, 2.6))
	Kit.cardboardBox(guest, F(37.6, U + 2.8, -27.8, PZ) * ANG(0, rad(-10), 0), V(2.2, 1.8, 2))
	Kit.cardboardBox(guest, F(33.6, U, -28.2, PZ), V(2.2, 1.6, 1.8))
	local _, sewH = Kit.consoleTable(guest, F(31.5, U, -24.8, PX), 4, 1.6, WOOD_LIGHT)
	Kit.box(guest, "SewingMachine", CF(31.5, U + sewH + 0.55, -24.8), V(0.8, 1.1, 2), C.White, KM.Metal)
	Kit.box(guest, "SewingArm", CF(31.5, U + sewH + 1.2, -24.3), V(0.7, 0.35, 1.2), C.White, KM.Metal)
	Kit.chair(guest, F(33.2, U, -24.8, NX), WOOD_LIGHT)
	Kit.plant(guest, F(38.3, U, -12, NX), 1.4, "tree")

	---------------------------------------------------------------------------
	-- UPSTAIRS BATHROOM (shower, signal at the window)
	---------------------------------------------------------------------------
	local hbath = folder("HallBath")
	Kit.vanity(hbath, F(17.5, U, -4.3, PZ), 5.6, 2, WHITE_WOOD, Color3.fromRGB(60, 60, 62), 1)
	Kit.mirror(hbath, F(17.5, U + 6.6, -5.62, PZ), 4, 3.4, Color3.fromRGB(200, 200, 196))
	Kit.toilet(hbath, F(24, U, -3.75, PZ))
	Kit.box(hbath, "ShowerBase", CF(36.3, U + 0.2, 5.35), V(5.7, 0.4, 4.7), Color3.fromRGB(230, 230, 228), KM.Tile, { CanCollide = true, CanQuery = true })
	Kit.box(hbath, "ShowerWall", CF(36.3, U + 5.5, 7.6), V(5.8, 11, 0.2), Color3.fromRGB(230, 230, 228), KM.Tile, { CanCollide = true })
	Kit.box(hbath, "ShowerWall", CF(36.3, U + 5.5, 2.95), V(5.8, 11, 0.2), Color3.fromRGB(230, 230, 228), KM.Tile, { CanCollide = true })
	Kit.cyl(hbath, "CurtainRod", CF(33.4, U + 10.1, 5.3) * ANG(0, rad(90), 0), 4.8, 0.12, Kit.C.Chrome, KM.Metal)
	local curtain = Kit.solid(hbath, "ShowerCurtain", CF(33.3, U + 5.5, 5.3), V(0.12, 9, 4.5), Color3.fromRGB(180, 200, 190), KM.Fabric)
	for k = 0, 5 do
		Kit.box(hbath, "CurtainFold", CF(33.2, U + 5.5, 3.4 + k * 0.75), V(0.16, 9, 0.12), Color3.fromRGB(160, 184, 172), KM.Fabric)
	end
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
	Kit.box(hbath, "ShowerPipe", CF(38.95, U + 8.3, 5.3), V(0.12, 1.6, 0.12), Kit.C.Chrome, KM.Metal)
	local head = Kit.cyl(hbath, "ShowerHead", CF(38.75, U + 9.05, 5.3) * ANG(0, 0, rad(-60)), 0.25, 0.7, Kit.C.Chrome, KM.Metal)
	drips.Parent = head
	local base = hbath:FindFirstChild("ShowerBase") :: BasePart
	base.Reflectance = 0.35
	ctx.Interaction.document(base, "WetShower", { Action = "Look", Object = "Shower", Distance = 8 }, function()
		ctx.Director.logTruth("WetShower")
	end)
	Kit.towel(hbath, F(27.8, U + 5.6, -5.55, PZ), 2.6, Color3.fromRGB(230, 200, 120))
	Kit.rug(hbath, F(31.2, U, 5.2, PX), 3.2, 2.4, Color3.fromRGB(110, 130, 150))

	---------------------------------------------------------------------------
	-- LILY'S ROOM
	---------------------------------------------------------------------------
	local lily = folder("Lily")
	Kit.vcyl(lily, "RoundRug", CF(24, U + 0.03, 17), 0.06, 11, Color3.fromRGB(240, 190, 210), KM.Fabric)
	Kit.vcyl(lily, "RoundRugInner", CF(24, U + 0.06, 17), 0.03, 8, Color3.fromRGB(250, 220, 232), KM.Fabric)
	local _, lilyBedCF = bed(lily, "Under Lily's bed", 32, 22.2, 38.5, 29.15, U, Color3.fromRGB(235, 160, 195), NZ, PZ, "Lily", Color3.fromRGB(240, 236, 230))
	Kit.bedThrow(lily, lilyBedCF, 6.5, 6.95, Color3.fromRGB(250, 236, 200), Color3.fromRGB(230, 150, 180))
	wardrobe(lily, "Lily's closet", 13.2, 8.65, 18.2, 11.45, U, PZ, "Lily", Color3.fromRGB(240, 236, 230))
	-- toy chest
	Kit.solid(lily, "ToyBox", CF(17.5, U + 1.1, 28.1), V(4, 2.2, 1.9), Color3.fromRGB(230, 200, 120), KM.Wood)
	Kit.soft(lily, "ToyBoxLid", CF(17.5, U + 2.3, 28.1), V(4.15, 0.22, 2.05), 0.08, Color3.fromRGB(210, 90, 90), KM.Wood)
	for _, x in { 16.2, 18.8 } do
		Kit.box(lily, "ToyBoxPanel", CF(x, U + 1.1, 27.14), V(1.1, 1.5, 0.04), Color3.fromRGB(120, 170, 210), KM.Wood)
	end
	Kit.ball(lily, "Ball", V(15.1, U + 0.55, 26.4), 1.1, Color3.fromRGB(220, 70, 70), KM.Plastic)
	Kit.teddy(lily, F(16.3, U + 2.41, 28.3, NZ), 0.8, Color3.fromRGB(170, 130, 90))
	-- her music box (it starts playing on its own one night: Events.MusicBox)
	local musicBox = Kit.box(lily, "MusicBox", CF(18.9, U + 2.72, 28.1), V(1.1, 0.6, 0.8), Color3.fromRGB(236, 200, 214), KM.Wood)
	Kit.box(lily, "MusicBoxLid", CF(18.9, U + 3.05, 28.1), V(1.16, 0.08, 0.86), Color3.fromRGB(214, 160, 190), KM.Wood)
	Kit.vcyl(lily, "MusicBoxKey", CF(19.55, U + 2.72, 28.1) * ANG(0, 0, rad(90)), 0.2, 0.18, BRASS, KM.Metal)
	musicBox.CanQuery = true
	Kit.fishTank(lily, F(37.3, U, 9.7, PZ), 3.6, 2, 2.4, Color3.fromRGB(240, 236, 230))
	Kit.dollhouse(lily, F(30.4, U, 9.8, PZ))
	Kit.teddy(lily, F(34.2, U + 3.7, 27.4, NZ), 0.9, Color3.fromRGB(200, 160, 120))
	Kit.teddy(lily, F(36.2, U + 3.7, 27.6, NZ) * ANG(0, rad(-20), 0), 0.75, Color3.fromRGB(235, 235, 235))
	-- string lights along the back wall
	fairyLights(lily, V(19.4, U + 10.6, 29.4), V(37.8, U + 10.6, 29.4), 0.9, 16, Color3.fromRGB(255, 196, 176))
	local drawing = paper(lily, "Drawing", CF(24, U + 5.5, 8.42), V(2.2, 1.6, 0.05))
	drawing.Color = Color3.fromRGB(250, 248, 240)
	Kit.box(lily, "DrawingTape", CF(24, U + 6.25, 8.46), V(0.5, 0.15, 0.02), Color3.fromRGB(230, 220, 170), KM.Plastic)
	ctx.Interaction.document(drawing, "LilyDrawing", { Object = "A crayon drawing", Distance = 7 })
	local nightlight = Kit.ellipsoid(lily, "Nightlight", CF(31, U + 1.2, 29.35), V(0.8, 0.8, 0.3), Color3.fromRGB(255, 220, 150), KM.Neon)
	nightlight.CanQuery = true
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
	Kit.boiler(base0, F(-24.5, BS, 14.8, PX))
	Kit.waterHeater(base0, F(-23.8, BS, 26.2, PX))
	target("Boiler", V(-32, BS + 3, 19))
	-- pipes the captives are tied to
	local PIPE = Color3.fromRGB(120, 80, 60)
	Kit.cyl(base0, "Pipe", CF(-39.2, BS + 5.75, 20) * ANG(0, rad(90), 0), 19, 0.5, PIPE, KM.Metal)
	Kit.cyl(base0, "Pipe", CF(-39.2, BS + 1.75, 20) * ANG(0, rad(90), 0), 19, 0.5, PIPE, KM.Metal)
	Kit.cyl(base0, "Pipe", CF(-30, BS + 8.25, 29.2), 19, 0.5, PIPE, KM.Metal)
	for _, z in { 13, 19, 25 } do
		Kit.vcyl(base0, "PipeRiser", CF(-39.2, BS + 5.5, z), 11, 0.5, PIPE, KM.Metal)
		Kit.vcyl(base0, "PipeCollar", CF(-39.2, BS + 5.75, z), 0.35, 0.7, PIPE, KM.Metal)
	end
	Kit.washer(base0, F(-37.2, BS, -27.8, PZ))
	Kit.washer(base0, F(-33.2, BS, -27.8, PZ), true)
	Kit.box(base0, "LaundryBasket", CF(-29.8, BS + 0.9, -27.8), V(1.8, 1.8, 1.4), Color3.fromRGB(220, 220, 214), KM.Plastic)
	Kit.clothesPile(base0, F(-29.8, BS + 1.6, -27.8, PZ), 13)
	Kit.shelving(base0, F(-38.5, BS, -13, PX), 12, 1.8, 7.5, 4, 9)
	Kit.cardboardBox(base0, F(-16, BS, -28.1, PZ), V(3.5, 3, 2.6))
	Kit.cardboardBox(base0, F(-12.5, BS, -28.3, PZ), V(3, 2.2, 2.2))
	Kit.cardboardBox(base0, F(-14.3, BS + 3, -28.2, PZ) * ANG(0, rad(12), 0), V(2.6, 1.8, 2.2))
	Kit.cardboardBox(base0, F(-3.5, BS, 28.1, NZ), V(3.5, 2.8, 2.4))
	Kit.cardboardBox(base0, F(0.2, BS, 28.3, NZ), V(2.8, 2.2, 2.2))
	Kit.chestFreezer(base0, F(-11, BS, 27.8, NZ), 5.5)
	Kit.sofa(base0, F(-8, BS, -4.3, NZ), 8, Color3.fromRGB(90, 80, 60), Color3.fromRGB(110, 70, 60), { Name = "OldCouch" })
	Kit.workbench(base0, F(-38.1, BS, 0, PX), 8, 2.6)
	Kit.box(base0, "Pegboard", CF(-39.45, BS + 6, 0), V(0.15, 3.5, 7.5), Color3.fromRGB(170, 140, 100), KM.Wood)
	for i, kind in { "wrench", "hammer", "screwdriver", "saw" } do
		Kit.tool(base0, F(-39.35, BS + 6.2 + (i % 2) * 0.5, -3 + i * 1.4, PX), kind)
	end
	-- a bare bulb hanging over the couch area
	Kit.vcyl(base0, "BulbCord", CF(-8, BS + 11.4, -2), 1.2, 0.05, C.Black, KM.Plastic)
	Kit.ball(base0, "BareBulb", V(-8, BS + 10.7, -2), 0.45, Color3.fromRGB(250, 240, 210), KM.Glass)
	-- under-stairs nook, behind a tarp
	local tarp = Kit.solid(base0, "Tarp", CF(5.9, BS + 3, 15.75), V(0.2, 6, 8.5), Color3.fromRGB(60, 80, 90), KM.Fabric)
	for k = 0, 4 do
		Kit.box(base0, "TarpFold", CF(5.8, BS + 3, 12.2 + k * 1.7) * ANG(0, 0, rad(3)), V(0.12, 5.9, 0.3), Color3.fromRGB(50, 68, 78), KM.Fabric)
	end
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
	Kit.sleepingBag(nest, F(n0.X, A, n0.Z - 0.4, PX), Color3.fromRGB(60, 75, 55))
	local _, lanternGlow = Kit.lantern(nest, F(n0.X + 5, A, n0.Z - 4, NZ))
	local ll = Instance.new("PointLight")
	ll.Range = 16
	ll.Brightness = 0.9
	ll.Color = Color3.fromRGB(255, 190, 110)
	ll.Shadows = true
	ll.Parent = lanternGlow
	ctx.Power.setStaticLit("Attic", true)
	local rng = Random.new(77)
	for i = 1, 9 do
		local a = i * 0.9
		Kit.box(nest, "Wrapper", CF(n0.X - 4.6 + math.cos(a) * 2.5, A + 0.04, n0.Z + 3.3 + math.sin(a)) * ANG(0, rng:NextNumber(0, 6), rng:NextNumber(-0.1, 0.1)), V(0.8, 0.06, 0.55), Color3.fromHSV(i / 9, 0.6, 0.8), KM.Plastic)
	end
	for i = 1, 4 do
		Kit.bottle(nest, F(n0.X - 2 + i * 0.6, A, n0.Z + 2.5, NZ), Color3.fromRGB(120, 160, 120))
	end
	Kit.box(nest, "TippedBottle", CF(n0.X + 1.2, A + 0.18, n0.Z + 3.4) * ANG(0, rad(30), rad(90)), V(1.0, 0.34, 0.34), Color3.fromRGB(110, 140, 110), KM.Glass, { Transparency = 0.25 })
	local notebook = Kit.box(nest, "Notebook", CF(n0.X + 1.6, A + 0.06, n0.Z + 2.7) * ANG(0, rad(-12), 0), V(1.2, 0.12, 1.4), Color3.fromRGB(40, 60, 120), KM.Cardboard)
	notebook.CanQuery = true
	for k = 0, 5 do
		Kit.cyl(nest, "Spiral", notebook.CFrame * CF(-0.62, 0.02, -0.55 + k * 0.22) * ANG(0, rad(90), 0), 0.04, 0.16, Kit.C.Chrome, KM.Metal)
	end
	target("Nest", notebook.Position)
	local polaroids = Kit.box(nest, "Polaroids", CF(-28.3, A + 3, n0.Z + 0.5), V(0.1, 3, 5), Color3.fromRGB(120, 100, 80), KM.Wood)
	polaroids.CanQuery = true
	for r = 0, 2 do
		for c = 0, 4 do
			Kit.box(nest, "Photo", CF(-28.22, A + 2.0 + r * 1.0, n0.Z - 1.6 + c * 1.0) * ANG(rad(rng:NextNumber(-8, 8)), 0, 0), V(0.02, 0.85, 0.7), Color3.fromRGB(226, 222, 212), KM.Plastic)
			Kit.box(nest, "PhotoImage", CF(-28.2, A + 2.08 + r * 1.0, n0.Z - 1.6 + c * 1.0), V(0.02, 0.55, 0.55), Color3.fromHSV(rng:NextNumber(0.05, 0.15), 0.3, rng:NextNumber(0.2, 0.5)), KM.Plastic)
		end
	end
	local lanyard = Kit.box(nest, "Lanyard", CF(n0.X - 1, A + 0.05, n0.Z - 3.6), V(1.0, 0.08, 0.8), Color3.fromRGB(40, 90, 160), KM.Plastic)
	lanyard.CanQuery = true
	Kit.box(nest, "IDCard", CF(n0.X - 1, A + 0.1, n0.Z - 3.6), V(0.6, 0.02, 0.8), Color3.fromRGB(236, 236, 230), KM.Plastic)
	for part, doc in { [notebook] = "Notebook", [polaroids] = "Polaroids", [lanyard] = "Lanyard" } do
		ctx.Interaction.document(part, doc, { Distance = 7 }, function(player)
			ctx.Director.onDiscovery(player, doc)
		end)
	end
	ctx.Escape.setNest(nest, V(n0.X - 3.5, A + 0.3, n0.Z - 3))

	---------------------------------------------------------------------------
	-- Lobby spawn (living room, behind the sofa)
	---------------------------------------------------------------------------
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.Transparency = 1
	spawn.Size = V(6, 0.2, 5)
	spawn.CFrame = CF(-24, G + 0.2, -8)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = root
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end

	---------------------------------------------------------------------------
	-- Tonight's stashes: two flashlights (at least one downstairs, for the breaker), two rolls
	-- of electrical tape and a pack of batteries, each in a different drawer or shelf.
	---------------------------------------------------------------------------
	do
		local stashRng = Random.new()
		local pool = table.clone(stashes)
		local function take(pred): any
			local options = {}
			for i, s in pool do
				if not pred or pred(s) then
					table.insert(options, i)
				end
			end
			if #options == 0 then
				return nil
			end
			return table.remove(pool, options[stashRng:NextInteger(1, #options)])
		end
		local ITEM_LOOK = {
			Flashlight = "Flashlight",
			ElectricalTape = "Electrical tape",
			Batteries = "Batteries",
		}
		local function visual(s, itemId: string)
			if not s.Visible then
				return nil
			end
			local m = Instance.new("Model")
			m.Name = "StashItem"
			m.Parent = s.Part.Parent
			local at = s.Part.CFrame * CF(0, -s.Part.Size.Y / 2, 0)
			if itemId == "Flashlight" then
				Kit.cyl(m, "Flashlight", at * CF(0, 0.23, 0), 1.2, 0.45, Color3.fromRGB(200, 170, 40), KM.Plastic)
				Kit.cyl(m, "FlashlightHead", at * CF(0.65, 0.23, 0), 0.3, 0.62, Color3.fromRGB(40, 40, 40), KM.Plastic)
			elseif itemId == "ElectricalTape" then
				Kit.vcyl(m, "Tape", at * CF(0, 0.15, 0), 0.3, 0.9, C.Black, KM.Plastic)
			else
				Kit.box(m, "BatteryPack", at * CF(0, 0.3, 0), V(0.9, 0.6, 0.25), Color3.fromRGB(220, 160, 40), KM.Plastic)
			end
			return m
		end
		local function place(s, itemId: string, targetName: string?)
			if targetName then
				target(targetName, s.Part.Position)
			end
			local look = visual(s, itemId)
			ctx.Interaction.pickup(s.Part, itemId, { Action = look and "Take" or "Search", Object = look and ITEM_LOOK[itemId] or (s.Label .. " (" .. ITEM_LOOK[itemId]:lower() .. ")"), Keep = true }, function()
				if look then
					look:Destroy()
				end
			end)
		end
		local f1 = take(function(s)
			return s.Floor == "Ground"
		end)
		if f1 then
			place(f1, "Flashlight", "Flashlight1")
		end
		local f2 = take(nil)
		if f2 then
			place(f2, "Flashlight", "Flashlight2")
		end
		for i = 1, 2 do
			local t = take(nil)
			if t then
				place(t, "ElectricalTape", "Tape" .. i)
			end
		end
		local b = take(nil)
		if b then
			place(b, "Batteries", nil)
		end
		-- the rest turn up nothing (once)
		for _, s in pool do
			local p
			p = ctx.Interaction.prompt(s.Part, { Action = "Search", Object = s.Label, Distance = 7 }, function(player)
				ctx.Audio.playAt("Pickup", s.Part.Position, { Caption = false, Volume = 0.3 })
				ctx.Audio.caption("Nothing useful in here.", nil, nil, { player })
				p:Destroy()
			end)
		end
	end

	return refs
end

return Interior
