--[[
	LobbyServer — the lobby that players land in.

	Alder Lane on a rainy night: the Whitaker house with its porch light on, the neighbors, the
	street and the gray van. Four white circles on the front patio queue groups of 1, 2, 3 and 4. When a circle is full it counts down, reserves
	a private game server and teleports the group there together.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Kit = require(script.Parent.Parent.World.Kit)

local LobbyServer = {}

local V = Vector3.new
local ORIGIN = V(0, 0, 400) -- far from the house coordinates, so nothing mistakes it for a room
local PAD_RADIUS = 5.5

local ctx
local pads = {}
local teleporting: { [Player]: boolean } = {}
local lastSent: { [Player]: string } = {}
local spawnCF: CFrame

---------------------------------------------------------------------------
-- The place
---------------------------------------------------------------------------
local TRIM = Color3.fromRGB(236, 233, 226)

-- A two-storey colonial. Front wall at z = frontZ (faces +Z), centered on cx.
-- opts: Width, Depth, Siding, Shutter, Door, Lit = { [windowIndex] = true }, Garage, Porch, Detail
local function buildHouse(parent: Instance, cx: number, frontZ: number, opts)
	local B = ctx.Builder
	local M = B.M
	local model = Instance.new("Model")
	model.Name = opts.Name or "House"
	model.Parent = parent
	local W, D = opts.Width or 52, opts.Depth or 24
	local x0, x1 = cx - W / 2, cx + W / 2
	local zb, zf = frontZ - D, frontZ
	local base, f1, f2 = 1.5, 13.5, 25.5
	local siding = opts.Siding or Color3.fromRGB(150, 162, 172)
	local function box(name, a: Vector3, b: Vector3, color, mat, extra)
		return B.box(model, name, ORIGIN + a, ORIGIN + b, color, mat, extra)
	end
	local DECOR = { CanCollide = false, CanQuery = false }

	-- foundation, walls, lap-siding lines, corner boards and bands
	box("Foundation", V(x0 - 0.3, 0, zb - 0.3), V(x1 + 0.3, base, zf + 0.3), Color3.fromRGB(120, 72, 60), Enum.Material.Brick)
	box("Walls", V(x0, base, zb), V(x1, f2, zf), siding, M.Siding)
	if opts.Detail then
		for y = base + 1.2, f2 - 0.6, 1.2 do
			box("Lap", V(x0, y, zf), V(x1, y + 0.12, zf + 0.08), siding:Lerp(Color3.new(), 0.18), M.Plastic, DECOR)
		end
	end
	for _, x in { x0 - 0.2, x1 - 0.8 } do
		box("CornerBoard", V(x, base, zf - 0.4), V(x + 1, f2, zf + 0.25), TRIM, M.Wood, DECOR)
	end
	box("Band", V(x0 - 0.2, f1 - 0.3, zf), V(x1 + 0.2, f1 + 0.4, zf + 0.25), TRIM, M.Wood, DECOR)
	box("Frieze", V(x0 - 0.2, f2 - 0.8, zb - 0.2), V(x1 + 0.2, f2, zf + 0.3), TRIM, M.Wood, DECOR)

	-- roof: a gable along X with overhangs, fascia boards and gable ends
	local rise, run = 10, D / 2 + 1.5
	local slope = math.sqrt(rise * rise + run * run)
	local angle = math.atan2(rise, run)
	local midZ = (zb + zf) / 2
	local roofColor = opts.Roof or Color3.fromRGB(52, 50, 52)
	for sgn = -1, 1, 2 do
		B.part(model, {
			Name = "Roof",
			Size = V(W + 3, 0.8, slope),
			CFrame = CFrame.new(ORIGIN + V(cx, f2 + rise / 2 + 0.3, midZ + sgn * run / 2)) * CFrame.Angles(sgn * angle, 0, 0),
			Color = roofColor,
			Material = M.Roof,
		})
		box("Fascia", V(x0 - 1.5, f2 - 0.2, midZ + sgn * (run + 0.1) - 0.3), V(x1 + 1.5, f2 + 0.6, midZ + sgn * (run + 0.1) + 0.3), TRIM, M.Wood, DECOR)
	end
	box("Ridge", V(x0 - 1.5, f2 + rise + 0.3, midZ - 0.6), V(x1 + 1.5, f2 + rise + 1, midZ + 0.6), roofColor, M.Roof)
	for _, x in { x0 + 0.3, x1 - 0.3 } do
		-- each half of the gable rises toward the ridge in the middle
		B.part(model, { ClassName = "WedgePart", Name = "Gable", Size = V(0.6, rise, D / 2), CFrame = CFrame.new(ORIGIN + V(x, f2 + rise / 2, midZ + D / 4)) * CFrame.Angles(0, math.pi, 0), Color = siding, Material = M.Siding })
		B.part(model, { ClassName = "WedgePart", Name = "Gable", Size = V(0.6, rise, D / 2), CFrame = CFrame.new(ORIGIN + V(x, f2 + rise / 2, midZ - D / 4)), Color = siding, Material = M.Siding })
	end
	-- chimney
	local chx = x0 + 6
	box("Chimney", V(chx - 2, f2, midZ - 4), V(chx + 2, f2 + rise + 5, midZ), Color3.fromRGB(125, 70, 58), Enum.Material.Brick)
	box("ChimneyCap", V(chx - 2.4, f2 + rise + 5, midZ - 4.4), V(chx + 2.4, f2 + rise + 5.6, midZ + 0.4), Color3.fromRGB(90, 88, 86), M.Concrete)

	-- windows with frames, muntins, sills, shutters; some glow warm
	local shutter = opts.Shutter or Color3.fromRGB(38, 56, 48)
	local wz = zf
	local function window(i: number, x: number, sill: number, w: number, h: number)
		local lit = opts.Lit and opts.Lit[i]
		local glass = box("Glass", V(x - w / 2, sill, wz - 0.1), V(x + w / 2, sill + h, wz + 0.05),
			lit and Color3.fromRGB(205, 150, 88) or Color3.fromRGB(24, 28, 36),
			lit and Enum.Material.Neon or M.Glass, lit and DECOR or { Reflectance = 0.25 })
		if lit then
			local l = Instance.new("PointLight")
			l.Range = 10
			l.Brightness = 0.9
			l.Color = Color3.fromRGB(255, 185, 120)
			l.Parent = glass
			-- a curtain drawn half across
			box("Curtain", V(x - w / 2, sill, wz + 0.06), V(x - w / 2 + w * 0.3, sill + h, wz + 0.1), Color3.fromRGB(170, 110, 80), M.Fabric, DECOR)
		end
		local t = 0.35
		box("Frame", V(x - w / 2 - t, sill + h, wz), V(x + w / 2 + t, sill + h + t, wz + 0.35), TRIM, M.Wood, DECOR)
		box("Frame", V(x - w / 2 - t, sill - t, wz), V(x + w / 2 + t, sill, wz + 0.35), TRIM, M.Wood, DECOR)
		box("Frame", V(x - w / 2 - t, sill, wz), V(x - w / 2, sill + h, wz + 0.35), TRIM, M.Wood, DECOR)
		box("Frame", V(x + w / 2, sill, wz), V(x + w / 2 + t, sill + h, wz + 0.35), TRIM, M.Wood, DECOR)
		box("Muntin", V(x - 0.08, sill, wz), V(x + 0.08, sill + h, wz + 0.2), TRIM, M.Wood, DECOR)
		box("Muntin", V(x - w / 2, sill + h / 2 - 0.08, wz), V(x + w / 2, sill + h / 2 + 0.08, wz + 0.2), TRIM, M.Wood, DECOR)
		box("Sill", V(x - w / 2 - 0.7, sill - t - 0.25, wz), V(x + w / 2 + 0.7, sill - t, wz + 0.7), TRIM, M.Wood, DECOR)
		box("Head", V(x - w / 2 - 0.7, sill + h + t, wz), V(x + w / 2 + 0.7, sill + h + t + 0.45, wz + 0.55), TRIM, M.Wood, DECOR)
		for sgn = -1, 1, 2 do
			local sx = x + sgn * (w / 2 + t + 1.05)
			box("Shutter", V(sx - 0.9, sill - 0.1, wz), V(sx + 0.9, sill + h + 0.1, wz + 0.25), shutter, M.Wood, DECOR)
			for k = 1, 3 do
				box("Louver", V(sx - 0.7, sill + k * h / 4 - 0.06, wz + 0.25), V(sx + 0.7, sill + k * h / 4 + 0.06, wz + 0.32), shutter:Lerp(Color3.new(), 0.3), M.Wood, DECOR)
			end
		end
	end
	local i = 0
	for _, x in opts.GroundWindows or { cx - 19, cx - 11, cx + 11, cx + 19 } do
		i += 1
		window(i, x, base + 3, 4.2, 6.5)
	end
	for _, x in opts.UpperWindows or { cx - 19, cx - 11, cx, cx + 11, cx + 19 } do
		i += 1
		window(i, x, f1 + 2.5, 4.2, 6.5)
	end

	-- front door with sidelights and a glowing transom
	box("DoorCasing", V(cx - 3.6, base, wz), V(cx + 3.6, base + 10.2, wz + 0.4), TRIM, M.Wood, DECOR)
	box("Door", V(cx - 2.1, base, wz + 0.2), V(cx + 2.1, base + 8.4, wz + 0.5), opts.Door or Color3.fromRGB(125, 32, 30), M.Wood)
	for _, dy in { 2.2, 5.6 } do
		box("DoorPanel", V(cx - 1.6, base + dy - 1.2, wz + 0.5), V(cx + 1.6, base + dy + 1.2, wz + 0.58), (opts.Door or Color3.fromRGB(125, 32, 30)):Lerp(Color3.new(), 0.2), M.Wood, DECOR)
	end
	box("Knob", V(cx + 1.3, base + 4, wz + 0.5), V(cx + 1.7, base + 4.4, wz + 0.8), Color3.fromRGB(200, 170, 100), M.Metal, DECOR)
	box("Transom", V(cx - 2.1, base + 8.6, wz + 0.2), V(cx + 2.1, base + 9.9, wz + 0.45), Color3.fromRGB(215, 160, 95), Enum.Material.Neon, DECOR)
	for sgn = -1, 1, 2 do
		box("Sidelight", V(cx + sgn * 2.4 - 0.5, base + 1, wz + 0.2), V(cx + sgn * 2.4 + 0.5, base + 8, wz + 0.45), Color3.fromRGB(190, 140, 85), Enum.Material.Neon, DECOR)
	end

	-- porch: deck, steps, columns, railing, roof and a warm light
	if opts.Porch ~= false then
		local px0, px1 = cx - 10, cx + 10
		local pz = zf + 7
		box("PorchDeck", V(px0, 0, zf), V(px1, base, pz), Color3.fromRGB(128, 122, 116), M.Wood)
		for k = 1, 3 do
			box("Step", V(cx - 4, 0, pz + (k - 1) * 1.1), V(cx + 4, base - (k - 1) * 0.5, pz + k * 1.1), Color3.fromRGB(128, 122, 116), M.Wood)
		end
		for _, x in { px0 + 0.8, cx - 4.4, cx + 4.4, px1 - 0.8 } do
			B.cylinder(model, "Column", ORIGIN + V(x, base + 5.4, pz - 0.8), 10.8, 1.1, TRIM, M.Wood)
			box("ColumnBase", V(x - 0.8, base, pz - 1.6), V(x + 0.8, base + 0.6, pz), TRIM, M.Wood, DECOR)
		end
		box("PorchBeam", V(px0 - 0.3, base + 10.8, pz - 1.6), V(px1 + 0.3, base + 11.8, pz), TRIM, M.Wood)
		box("PorchRoof", V(px0 - 0.8, base + 11.8, zf), V(px1 + 0.8, base + 12.5, pz + 0.8), opts.Roof or Color3.fromRGB(52, 50, 52), M.Roof)
		for _, span in { { px0 + 0.8, cx - 4.4 }, { cx + 4.4, px1 - 0.8 } } do
			box("Rail", V(span[1], base + 3, pz - 1), V(span[2], base + 3.35, pz - 0.6), TRIM, M.Wood)
			for x = span[1] + 0.8, span[2] - 0.5, 0.9 do
				box("Baluster", V(x - 0.1, base, pz - 0.9), V(x + 0.1, base + 3, pz - 0.7), TRIM, M.Wood, DECOR)
			end
		end
		local lamp = box("PorchLight", V(cx + 4.2, base + 6.4, zf + 0.3), V(cx + 4.9, base + 7.6, zf + 0.9), Color3.fromRGB(255, 205, 140), Enum.Material.Neon, DECOR)
		local pl = Instance.new("PointLight")
		pl.Range = 20
		pl.Brightness = 1.3
		pl.Color = Color3.fromRGB(255, 190, 120)
		pl.Shadows = true
		pl.Parent = lamp
	end

	-- attached garage
	if opts.Garage then
		local g0, g1 = x1, x1 + 20
		local gz0 = zf - 20
		box("GarageWalls", V(g0, base, gz0), V(g1, f1, zf), siding, M.Siding)
		box("GarageFrieze", V(g0, f1 - 0.6, gz0), V(g1 + 0.2, f1, zf + 0.3), TRIM, M.Wood, DECOR)
		B.part(model, { ClassName = "WedgePart", Name = "GarageRoof", Size = V(21.5, 6, 21.5), CFrame = CFrame.new(ORIGIN + V((g0 + g1) / 2, f1 + 3, (gz0 + zf) / 2)), Color = opts.Roof or Color3.fromRGB(52, 50, 52), Material = M.Roof })
		box("GarageDoor", V(g0 + 2.5, base, zf), V(g1 - 2.5, base + 9, zf + 0.3), TRIM, M.Metal)
		for r = 1, 3 do
			box("GarageSeam", V(g0 + 2.5, base + r * 2.25, zf + 0.3), V(g1 - 2.5, base + r * 2.25 + 0.12, zf + 0.36), Color3.fromRGB(190, 188, 182), M.Metal, DECOR)
		end
		box("GarageWindows", V(g0 + 4, base + 6.8, zf + 0.3), V(g1 - 4, base + 8, zf + 0.34), Color3.fromRGB(30, 34, 40), M.Glass, DECOR)
		for _, x in { g0 + 1.4, g1 - 1.4 } do
			local cl = box("CoachLight", V(x - 0.35, base + 6, zf + 0.3), V(x + 0.35, base + 7.2, zf + 0.9), Color3.fromRGB(255, 205, 140), Enum.Material.Neon, DECOR)
			local l = Instance.new("PointLight")
			l.Range = 12
			l.Brightness = 0.8
			l.Color = Color3.fromRGB(255, 190, 120)
			l.Parent = cl
		end
	end
	return model
end

local function lampPost(root: Instance, pos: Vector3, lit: boolean?)
	local _, head = Kit.streetLamp(root, CFrame.lookAt(ORIGIN + pos, ORIGIN + pos + V(0, 0, 1)), 16)
	if lit ~= false then
		local pl = Instance.new("PointLight")
		pl.Range = 32
		pl.Brightness = 1.4
		pl.Color = Color3.fromRGB(255, 196, 130)
		pl.Shadows = true
		pl.Parent = head
	end
end

-- a white outline ring on the ground (the queue circle)
local function ring(root: Instance, center: Vector3, radius: number): { BasePart }
	local B = ctx.Builder
	local parts = {}
	local n = 40
	local chord = 2 * math.pi * radius / n + 0.08
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		local p = center + V(math.cos(a) * radius, 0, math.sin(a) * radius)
		local t = V(-math.sin(a), 0, math.cos(a))
		table.insert(parts, B.part(root, {
			Name = "Ring",
			Size = V(0.35, 0.1, chord),
			CFrame = CFrame.lookAt(p, p + t),
			Color = Color3.new(1, 1, 1),
			Material = Enum.Material.Neon,
			CanCollide = false,
			CanQuery = false,
			CastShadow = false,
			Transparency = 0.3,
		}))
	end
	return parts
end

local function setupLighting()
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 0.2 -- the moon high overhead
	Lighting.Brightness = 1.2
	Lighting.Ambient = Color3.fromRGB(34, 36, 46)
	Lighting.OutdoorAmbient = Color3.fromRGB(72, 80, 104)
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.8
	Lighting.ExposureCompensation = 0.25
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		-- thick, cold fog: past the street everything fades out, so the town never ends
		atmo.Density = 0.58
		atmo.Offset = 0.22
		atmo.Color = Color3.fromRGB(100, 108, 124)
		atmo.Decay = Color3.fromRGB(58, 64, 80)
		atmo.Haze = 2.8
	end
end

local function build(root: Folder)
	local B = ctx.Builder
	local C, M = B.C, B.M
	local function box(name, a: Vector3, b: Vector3, color, mat, extra)
		return B.box(root, name, ORIGIN + a, ORIGIN + b, color, mat, extra)
	end
	local GRASS = Color3.fromRGB(48, 64, 42)
	local CONCRETE = Color3.fromRGB(128, 128, 124)

	-- ground, sidewalks, the wet street
	-- the ground, street and sidewalks run on far past the invisible walls, into the fog
	local FAR = 900
	-- (the grass stops at the sidewalks, so it never covers the street)
	box("Ground", V(-FAR, -3, -FAR), V(FAR, 0.5, 20), GRASS, Enum.Material.Grass)
	box("Ground", V(-FAR, -3, 54), V(FAR, 0.5, FAR), GRASS, Enum.Material.Grass)
	box("Subgrade", V(-FAR, -3, 20), V(FAR, 0.3, 54), Color3.fromRGB(40, 40, 40), M.Concrete)
	box("Sidewalk", V(-FAR, 0.5, 20), V(FAR, 0.75, 28), CONCRETE, M.Concrete)
	box("Curb", V(-FAR, 0.3, 27.6), V(FAR, 0.85, 28.2), Color3.fromRGB(150, 150, 146), M.Concrete)
	box("Street", V(-FAR, 0.3, 28.2), V(FAR, 0.45, 46), Color3.fromRGB(30, 31, 35), M.Asphalt, { Reflectance = 0.08 })
	box("Curb", V(-FAR, 0.3, 46), V(FAR, 0.85, 46.6), Color3.fromRGB(150, 150, 146), M.Concrete)
	box("SidewalkFar", V(-FAR, 0.5, 46.6), V(FAR, 0.75, 54), CONCRETE, M.Concrete)
	for x = -600, 600, 16 do
		box("LaneMark", V(x, 0.45, 36.8), V(x + 8, 0.5, 37.4), Color3.fromRGB(205, 185, 95), M.Plastic, { CanCollide = false })
	end
	for _, pd in { { -30, 31, 9, 6 }, { 12, 39, 7, 4 }, { 55, 32, 10, 5 }, { -70, 40, 8, 5 } } do
		box("Puddle", V(pd[1], 0.45, pd[2]), V(pd[1] + pd[3], 0.47, pd[2] + pd[4]), Color3.fromRGB(40, 46, 58), M.Glass, { Reflectance = 0.45, Transparency = 0.2, CanCollide = false })
	end

	-- front walk and the patio where the circles are
	box("Walk", V(-3, 0.5, -30), V(3, 0.72, 20), Color3.fromRGB(140, 134, 126), M.Concrete)
	box("Patio", V(-34, 0.5, -22), V(34, 0.7, -4), Color3.fromRGB(110, 106, 100), Enum.Material.Pebble)
	box("PatioEdge", V(-34.4, 0.5, -22.4), V(34.4, 0.78, -21.9), Color3.fromRGB(150, 146, 140), M.Concrete)
	box("PatioEdge", V(-34.4, 0.5, -4.1), V(34.4, 0.78, -3.6), Color3.fromRGB(150, 146, 140), M.Concrete)
	box("Driveway", V(28, 0.5, -40), V(44, 0.7, 28), Color3.fromRGB(100, 100, 98), M.Concrete)

	-- the Whitaker house and the neighbors
	buildHouse(root, 0, -40, {
		Name = "WhitakerHouse",
		Detail = true,
		Garage = true,
		Lit = { [2] = true, [7] = true },
	})
	buildHouse(root, -96, -34, {
		Name = "NeighborLeft",
		Width = 36,
		Siding = Color3.fromRGB(176, 160, 132),
		Shutter = Color3.fromRGB(60, 40, 30),
		Door = Color3.fromRGB(40, 60, 70),
		GroundWindows = { -108, -84 },
		UpperWindows = { -108, -96, -84 },
		Lit = { [1] = true, [4] = true },
	})
	buildHouse(root, 92, -34, {
		Name = "NeighborRight",
		Width = 36,
		Siding = Color3.fromRGB(120, 130, 120),
		Shutter = Color3.fromRGB(30, 30, 34),
		GroundWindows = { 80, 104 },
		UpperWindows = { 80, 92, 104 },
		Lit = { [2] = true },
	})

	-- hedges, flower beds, picket fence, mailbox, trees
	for _, span in { { -26, -11 }, { 11, 26 } } do
		box("Mulch", V(span[1], 0.5, -40), V(span[2], 0.62, -36), Color3.fromRGB(60, 40, 30), M.Fabric)
		Kit.hedge(root, CFrame.lookAt(ORIGIN + V((span[1] + span[2]) / 2, 0.6, -38.2), ORIGIN + V((span[1] + span[2]) / 2, 0.6, -37)), span[2] - span[1] - 1, 3, 2.4)
	end
	for _, span in { { -130, -5 }, { 5, 26 }, { 46, 130 } } do
		Kit.picketFence(root, ORIGIN + V(span[1], 0.5, 18.8), ORIGIN + V(span[2], 0.5, 18.8), 3.4)
	end
	-- autumn on the Whitaker porch and fallen leaves on the lawns (matches the game)
	local toStreet = CFrame.Angles(0, math.pi, 0)
	for _, p in { { -6.5, 1.5, -35.2, 1.3 }, { -7.7, 1.5, -35.8, 0.8 }, { 6.8, 1.5, -35.3, 1.1 }, { -3.4, 1.5, -32.4, 0.8 }, { 3.4, 1.5, -32.5, 0.9 }, { -3.4, 1.0, -31.3, 0.7 } } do
		Kit.pumpkin(root, CFrame.new(ORIGIN + V(p[1], p[2], p[3])) * toStreet * CFrame.Angles(0, p[4] * 2, 0), p[4])
	end
	Kit.mums(root, CFrame.new(ORIGIN + V(8.4, 1.5, -37.6)), 1.3, Color3.fromRGB(200, 90, 40))
	Kit.mums(root, CFrame.new(ORIGIN + V(-8.4, 1.5, -37.6)), 1.3, Color3.fromRGB(230, 180, 60))
	do
		local rng = Random.new(77)
		local LEAVES = { Color3.fromRGB(196, 96, 36), Color3.fromRGB(170, 60, 32), Color3.fromRGB(210, 150, 50), Color3.fromRGB(120, 76, 40) }
		for _, ar in { { -60, -34, -30, 18 }, { -34, -3, -3.5, 18 }, { 3, 27, -3.5, 18 }, { 45, 60, -30, 18 } } do
			for _ = 1, math.floor((ar[2] - ar[1]) * (ar[4] - ar[3]) / 7) do
				local x, z = rng:NextNumber(ar[1], ar[2]), rng:NextNumber(ar[3], ar[4])
				Kit.box(root, "Leaf", CFrame.new(ORIGIN + V(x, 0.53, z)) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(0, 6.28), 0), V(0.42, 0.03, 0.3), LEAVES[rng:NextInteger(1, #LEAVES)], Kit.M.Fabric, { CanCollide = false, CanQuery = false, CastShadow = false })
			end
		end
	end
	Kit.mailbox(root, CFrame.lookAt(ORIGIN + V(5.4, 0.5, 20.6), ORIGIN + V(5.4, 0.5, 22)))
	-- the survivors' board beside the queue circles (top 10 by nights survived, refreshed)
	do
		local boardCF = CFrame.lookAt(ORIGIN + V(-39, 7, -13), ORIGIN + V(0, 7, -13))
		for _, s in { -1, 1 } do
			Kit.box(root, "BoardPost", boardCF * CFrame.new(s * 5.2, -3.3, 0.3), V(0.5, 7.4, 0.5), Color3.fromRGB(60, 44, 32), Kit.M.Wood, { CanCollide = true })
		end
		local sign = Kit.box(root, "SurvivorBoard", boardCF, V(11, 7, 0.4), Color3.fromRGB(26, 22, 20), Kit.M.Wood, { CanCollide = true })
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(550, 350)
		gui.LightInfluence = 0.2
		gui.Parent = sign
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 56)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.Merriweather
		title.TextScaled = true
		title.TextColor3 = Color3.fromRGB(255, 200, 130)
		title.Text = "NIGHTS SURVIVED"
		title.Parent = gui
		local body = Instance.new("TextLabel")
		body.Position = UDim2.fromOffset(24, 64)
		body.Size = UDim2.new(1, -48, 1, -76)
		body.BackgroundTransparency = 1
		body.Font = Enum.Font.GothamMedium
		body.TextSize = 24
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.TextColor3 = Color3.fromRGB(230, 224, 212)
		body.Text = "Survive a night to get on the board."
		body.Parent = gui
		local lamp = Kit.box(root, "BoardLamp", boardCF * CFrame.new(0, 4, -0.6), V(3, 0.3, 0.6), Color3.fromRGB(255, 210, 150), Enum.Material.Neon)
		local l = Instance.new("SpotLight")
		l.Face = Enum.NormalId.Bottom
		l.Range = 12
		l.Brightness = 2
		l.Angle = 80
		l.Color = Color3.fromRGB(255, 200, 140)
		l.Parent = lamp
		task.spawn(function()
			while sign.Parent do
				local top = ctx.Stats and ctx.Stats.top(10) or {}
				if #top > 0 then
					local lines = {}
					for i, e in top do
						table.insert(lines, string.format("%d.  %s  —  %d", i, e.Name, e.Value))
					end
					body.Text = table.concat(lines, "\n")
				end
				task.wait(90)
			end
		end)
	end
	Kit.hydrant(root, CFrame.new(ORIGIN + V(-34, 0.75, 22.5)))
	for i, t in { { -48, -50 }, { 58, -52 }, { -58, 2 }, { 62, 4 }, { -118, 8 }, { 118, 10 }, { -20, 70 }, { 40, 72 }, { -90, 72 } } do
		if i % 3 == 0 then
			Kit.pine(root, ORIGIN + V(t[1], 0.5, t[2]), 28, i)
		else
			Kit.tree(root, ORIGIN + V(t[1], 0.5, t[2]), 24, i)
		end
	end
	-- beyond the walls: woods and more street lamps fading into the fog
	local rng = Random.new(4242)
	for i = 1, 70 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(150, 420)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if z > 14 and z < 60 then
			z += 60 -- keep the street clear
		end
		if rng:NextNumber() < 0.55 then
			Kit.pine(root, ORIGIN + V(x, 0.5, z), rng:NextNumber(26, 40), i)
		else
			Kit.tree(root, ORIGIN + V(x, 0.5, z), rng:NextNumber(22, 30), i)
		end
	end
	for x = -420, 420, 70 do
		if math.abs(x) > 130 then
			lampPost(root, V(x, 0.75, 24), false)
		end
	end

	-- street lamps and the gray van at the curb across the street
	for _, x in { -60, -16, 16, 60 } do
		lampPost(root, V(x, 0.75, 24))
	end
	lampPost(root, V(-40, 0.75, 50))
	lampPost(root, V(40, 0.75, 50))
	local van = Kit.van(root, CFrame.lookAt(ORIGIN + V(68, 0.45, 41.5), ORIGIN + V(60, 0.45, 41.5)), Color3.fromRGB(122, 125, 128))
	van.Name = "GrayVan"
	Kit.sedan(root, CFrame.lookAt(ORIGIN + V(-50, 0.45, 32.5), ORIGIN + V(-40, 0.45, 32.5)), Color3.fromRGB(110, 28, 30))
	Kit.sedan(root, CFrame.lookAt(ORIGIN + V(37.6, 0.7, -18), ORIGIN + V(37.6, 0.7, -28)), Color3.fromRGB(40, 60, 90))

	-- queue circles on the patio: plain white outlines
	for i, size in ctx.Config.Lobby.QueueSizes do
		local x = (i - (#ctx.Config.Lobby.QueueSizes + 1) / 2) * 16
		local center = ORIGIN + V(x, 0.72, -13)
		local segments = ring(root, center, PAD_RADIUS)
		local anchor = B.part(root, {
			Name = "Pad" .. size,
			Size = V(1, 1, 1),
			CFrame = CFrame.new(center + V(0, 0.5, 0)),
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
		})
		local bb = Instance.new("BillboardGui")
		bb.Name = "QueueSign"
		bb.Size = UDim2.fromScale(10, 4.6)
		bb.StudsOffset = V(0, 6, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 160
		bb.Parent = anchor
		local function line(name, y, h, font, color3)
			local l = Instance.new("TextLabel")
			l.Name = name
			l.BackgroundTransparency = 1
			l.Position = UDim2.fromScale(0, y)
			l.Size = UDim2.fromScale(1, h)
			l.Font = font
			l.TextScaled = true
			l.TextColor3 = color3
			l.TextStrokeTransparency = 0.5
			l.Text = ""
			l.Parent = bb
			return l
		end
		local head = line("Title", 0, 0.42, Enum.Font.GothamBold, Color3.new(1, 1, 1))
		head.Text = size == 1 and "1 PLAYER" or (size .. " PLAYERS")
		local count = line("Count", 0.44, 0.3, Enum.Font.GothamBold, Color3.fromRGB(235, 235, 235))
		local status = line("Status", 0.76, 0.24, Enum.Font.GothamMedium, Color3.fromRGB(190, 190, 190))

		table.insert(pads, {
			Size = size,
			Center = center,
			Anchor = anchor,
			Segments = segments,
			Count = count,
			Status = status,
			Members = {},
			CountdownEnd = nil,
			Teleporting = false,
			CooldownUntil = 0,
		})
	end

	-- spawn on the front walk, facing the circles and the house
	spawnCF = CFrame.lookAt(ORIGIN + V(0, 3.5, 8), ORIGIN + V(0, 3.5, -13))
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Size = V(10, 0.2, 6)
	spawn.CFrame = CFrame.new(ORIGIN + V(0, 0.9, 8))
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = root
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end

	-- invisible walls
	for _, b in { { V(-126, -5, -126), V(-125, 60, 126) }, { V(125, -5, -126), V(126, 60, 126) }, { V(-126, -5, -126), V(126, 60, -125) }, { V(-126, -5, 125), V(126, 60, 126) } } do
		box("Bounds", b[1], b[2], C.Black, M.Plastic, { Transparency = 1 })
	end
	setupLighting()
end

---------------------------------------------------------------------------
-- Queues
---------------------------------------------------------------------------
local function padOf(player: Player)
	for _, pad in pads do
		if table.find(pad.Members, player) then
			return pad
		end
	end
	return nil
end

local function send(player: Player, payload)
	local key = payload and string.format("%d|%d|%s|%s", payload.Size, payload.Count, tostring(payload.Countdown), payload.Status) or "none"
	if lastSent[player] == key then
		return
	end
	lastSent[player] = key
	ctx.Remotes.Queue:FireClient(player, payload)
end

local function teleportGroup(pad, group: { Player })
	pad.Teleporting = true
	for _, p in group do
		teleporting[p] = true
	end
	task.spawn(function()
		local placeId = ctx.Mode.gamePlaceId()
		local ok, err = pcall(function()
			if RunService:IsStudio() then
				error("Teleports don't work in a Studio test. Publish, then play in the Roblox app.")
			end
			local code = TeleportService:ReserveServer(placeId)
			local options = Instance.new("TeleportOptions")
			options.ReservedServerAccessCode = code
			options:SetTeleportData({ PartySize = #group, Mode = "Game" })
			TeleportService:TeleportAsync(placeId, group, options)
		end)
		if not ok then
			warn("[Lobby] teleport failed: " .. tostring(err))
			for _, p in group do
				teleporting[p] = nil
				if p.Parent then
					ctx.Remotes.Notify:FireClient(p, "Couldn't start the night: " .. tostring(err), "danger")
				end
			end
			pad.Teleporting = false
			pad.CountdownEnd = nil
			pad.CooldownUntil = os.clock() + 8
		else
			-- if they're somehow still here a while later, free the circle
			task.delay(30, function()
				pad.Teleporting = false
				for _, p in group do
					teleporting[p] = nil
				end
			end)
		end
	end)
end

local function tick()
	local now = os.clock()
	for _, pad in pads do
		-- who is standing on it
		local inside = {}
		for _, p in Players:GetPlayers() do
			local root = ctx.Util.getRoot(p)
			if root and not teleporting[p] then
				local d = root.Position - pad.Center
				if V(d.X, 0, d.Z).Magnitude <= PAD_RADIUS and math.abs(d.Y) < 8 then
					inside[p] = true
				end
			end
		end
		-- keep queue order: people already queued stay ahead of newcomers
		local members = {}
		for _, p in pad.Members do
			if inside[p] or (pad.Teleporting and teleporting[p]) then
				table.insert(members, p)
				inside[p] = nil
			end
		end
		for p in inside do
			if not padOf(p) or padOf(p) == pad then
				table.insert(members, p)
			end
		end
		pad.Members = members

		local counted = math.min(#members, pad.Size)
		if pad.Teleporting then
			pad.Status.Text = "Heading to 14 Alder Lane..."
		elseif counted >= pad.Size and now >= pad.CooldownUntil then
			if not pad.CountdownEnd then
				pad.CountdownEnd = now + (pad.Size == 1 and ctx.Config.Lobby.SoloCountdown or ctx.Config.Lobby.Countdown)
			end
			local left = math.max(0, math.ceil(pad.CountdownEnd - now))
			pad.Status.Text = "Starting in " .. left .. "..."
			if now >= pad.CountdownEnd then
				local group = {}
				for i = 1, pad.Size do
					table.insert(group, members[i])
				end
				teleportGroup(pad, group)
			end
		else
			pad.CountdownEnd = nil
			pad.Status.Text = counted == 0 and "Step in to queue" or ("Waiting for " .. (pad.Size - counted) .. " more")
		end
		pad.Count.Text = counted .. " / " .. pad.Size
		local glow = counted > 0 and 0 or 0.3
		if pad.Segments[1].Transparency ~= glow then
			for _, seg in pad.Segments do
				seg.Transparency = glow
			end
		end

		for i, p in members do
			local status
			if pad.Teleporting then
				status = "Teleporting"
			elseif i > pad.Size then
				status = "Full"
			elseif pad.CountdownEnd then
				status = "Starting"
			else
				status = "Waiting"
			end
			send(p, {
				Size = pad.Size,
				Count = counted,
				Countdown = pad.CountdownEnd and math.max(0, math.ceil(pad.CountdownEnd - now)) or nil,
				Status = status,
			})
		end
	end
	for _, p in Players:GetPlayers() do
		if not padOf(p) then
			send(p, nil)
		end
	end
end

---------------------------------------------------------------------------
function LobbyServer.run(c)
	ctx = c
	local root = Instance.new("Folder")
	root.Name = "Lobby"
	root.Parent = workspace
	build(root)

	local function setup(player: Player)
		-- third person here; the house itself is first person
		player.CameraMode = Enum.CameraMode.Classic
		-- a minimum zoom forces the camera out behind the character (the game itself is first person)
		player.CameraMaxZoomDistance = 22
		player.CameraMinZoomDistance = 9
		player.CharacterAdded:Connect(function(char)
			local hum = char:WaitForChild("Humanoid") :: Humanoid
			hum.WalkSpeed = 16
			task.defer(function()
				char:PivotTo(spawnCF * CFrame.new(math.random(-4, 4), 0, math.random(-2, 2)))
			end)
		end)
	end
	for _, p in Players:GetPlayers() do
		setup(p)
	end
	Players.PlayerAdded:Connect(setup)
	Players.PlayerRemoving:Connect(function(p)
		teleporting[p] = nil
		lastSent[p] = nil
	end)

	-- one-tap queueing (phones): put the player in the right circle
	ctx.Remotes.QuickPlay.OnServerEvent:Connect(function(player, kind)
		if teleporting[player] or padOf(player) then
			return
		end
		local char = player.Character
		if not char then
			return
		end
		local target
		if kind == "Solo" then
			for _, pad in pads do
				if pad.Size == 1 and not pad.Teleporting then
					target = pad
				end
			end
		else
			-- the group circle with the most people waiting; when they're all empty, the
			-- smallest one (quickest to fill)
			local best = -math.huge
			for _, pad in pads do
				if pad.Size > 1 and not pad.Teleporting and #pad.Members < pad.Size then
					local score = #pad.Members * 10 - pad.Size
					if score > best then
						best, target = score, pad
					end
				end
			end
		end
		if target then
			local a = math.random() * math.pi * 2
			local root = ctx.Util.getRoot(player)
			if root then
				-- moving the root part carries the whole character
				root.CFrame = CFrame.new(target.Center + V(math.cos(a) * 2, 3.2, math.sin(a) * 2))
			end
		else
			ctx.Remotes.Notify:FireClient(player, "Every circle is busy. Try again in a moment.", "info")
		end
	end)
	ctx.Remotes.LeaveQueue.OnServerEvent:Connect(function(player)
		if teleporting[player] then
			return
		end
		local char = player.Character
		if char and padOf(player) then
			char:PivotTo(spawnCF * CFrame.new(math.random(-4, 4), 0, 3))
		end
	end)
	TeleportService.TeleportInitFailed:Connect(function(player, result, message)
		teleporting[player] = nil
		if player.Parent then
			ctx.Remotes.Notify:FireClient(player, "Teleport failed (" .. tostring(result) .. "). Step back into a circle to try again.", "danger")
		end
		warn("[Lobby] TeleportInitFailed " .. player.Name .. ": " .. tostring(message))
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		local ok, err = pcall(tick)
		if not ok then
			warn("[Lobby] " .. tostring(err))
		end
	end)
	print("[HomeAlone] lobby ready")
end

return LobbyServer
