--[[
	Exterior — the lot around 14 Alder Lane: lawn, porch, driveway, street, the gray van,
	the fenced back yard, the phone junction box, and Mrs. Okafor's house next door.
	Models come from World/Kit.
]]

local Kit = require(script.Parent.Kit)

local Exterior = {}

local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad

local function F(x: number, y: number, z: number, dir: Vector3): CFrame
	return CFrame.lookAt(V(x, y, z), V(x + dir.X, y, z + dir.Z))
end
local PX, NX, PZ, NZ = V(1, 0, 0), V(-1, 0, 0), V(0, 0, 1), V(0, 0, -1)

function Exterior.build(ctx, root: Instance, refs)
	local B = ctx.Builder
	local C, M = B.C, B.M
	local L = ctx.Layout
	local KM = Kit.M

	local f = Instance.new("Folder")
	f.Name = "Exterior"
	f.Parent = root

	local function box(name, x0, y0, z0, x1, y1, z1, color, mat, extra)
		return B.box(f, name, V(x0, y0, z0), V(x1, y1, z1), color, mat, extra)
	end

	local GRASS = Color3.fromRGB(52, 66, 44)
	local grass = Enum.Material.Grass
	local CONCRETE = Color3.fromRGB(135, 135, 130)
	local TRIM = C.Trim

	---------------------------------------------------------------------------
	-- Ground: lawns, sidewalk, curb, street
	---------------------------------------------------------------------------
	-- lawn with a hole for the house footprint (so it never pokes into the basement)
	B.slab(f, "Lawn", -260, 260, -62, 200, 0.5, 3, { { -40.6, 66.6, -30.6, 30.6 }, { 94, 131, -31, 1 } }, GRASS, grass)
	box("Sidewalk", -260, -2.5, -68, 260, 0.6, -62, CONCRETE, M.Concrete)
	for x = -258, 258, 6 do
		box("SidewalkJoint", x, 0.6, -68, x + 0.12, 0.62, -62, Color3.fromRGB(110, 110, 106), M.Concrete, { CanCollide = false, CanQuery = false })
	end
	box("Street", -260, -2.5, -96, 260, 0.45, -68, Color3.fromRGB(38, 38, 42), M.Asphalt)
	box("Curb", -260, -2.5, -68.4, 260, 0.75, -68, CONCRETE, M.Concrete)
	box("Curb", -260, -2.5, -96.5, 260, 0.75, -96, CONCRETE, M.Concrete)
	box("Sidewalk", -260, -2.5, -102, 260, 0.6, -96.5, CONCRETE, M.Concrete)
	B.slab(f, "LawnAcross", -260, 260, -200, -102, 0.5, 3, {}, GRASS, grass)
	for x = -250, 250, 16 do
		box("LaneMark", x, 0.45, -82.3, x + 8, 0.5, -81.7, Color3.fromRGB(200, 180, 90), M.Plastic, { CanCollide = false })
	end
	-- storm drain and puddles
	box("StormDrain", 30, 0.44, -68.9, 34, 0.47, -68.4, Color3.fromRGB(20, 20, 22), M.Metal, { CanCollide = false })
	for _, p in { { -20, -75, 6, 3 }, { 45, -90, 4, 5 }, { 120, -80, 7, 3 }, { -110, -86, 5, 4 } } do
		Kit.ellipsoid(f, "Puddle", CF(p[1], 0.46, p[2]), V(p[3], 0.02, p[4]), Color3.fromRGB(30, 34, 40), KM.Glass, { Reflectance = 0.35 })
	end

	---------------------------------------------------------------------------
	-- Porch, walk, driveway, steps
	---------------------------------------------------------------------------
	local deck = Color3.fromRGB(128, 116, 104)
	box("Porch", -5, 0, -38, 9, 1, -30.5, deck, M.Planks)
	box("PorchSkirt", -5, 0, -38.1, 9, 0.9, -38, Color3.fromRGB(236, 232, 224), M.Wood)
	box("PorchStep", -1, 0, -40, 5, 0.5, -38, deck, M.Planks)
	box("PorchStep", -1, 0.5, -39, 5, 1.0, -38, deck, M.Planks)
	box("Walk", 0, 0, -62, 4, 0.6, -40, Color3.fromRGB(150, 146, 140), M.Concrete)
	for z = -61, -41, 2.5 do
		box("WalkJoint", 0, 0.6, z, 4, 0.62, z + 0.1, Color3.fromRGB(110, 110, 106), M.Concrete, { CanCollide = false, CanQuery = false })
	end
	-- porch roof with a pediment
	box("PorchRoof", -6, 12.5, -39, 10, 13, -30.5, C.Roof, M.Roof)
	box("PorchBeam", -6, 11.6, -38.9, 10, 12.5, -38.3, TRIM, M.Wood)
	-- the pediment: two wedges rising to a point over the steps
	B.part(f, { ClassName = "WedgePart", Name = "Pediment", Size = V(0.4, 2.4, 8), CFrame = CF(-2, 14.2, -38.8) * ANG(0, math.pi / 2, 0), Color = TRIM, Material = M.Wood })
	B.part(f, { ClassName = "WedgePart", Name = "Pediment", Size = V(0.4, 2.4, 8), CFrame = CF(6, 14.2, -38.8) * ANG(0, -math.pi / 2, 0), Color = TRIM, Material = M.Wood })
	for _, x in { -5.4, -1.2, 5.2, 9.4 } do
		Kit.vcyl(f, "PorchColumn", CF(x, 6.3, -38.4), 10.6, 0.85, TRIM, KM.Wood, { CanCollide = true })
		Kit.box(f, "ColumnBase", CF(x, 1.2, -38.4), V(1.2, 0.4, 1.2), TRIM, KM.Wood)
		Kit.box(f, "ColumnCap", CF(x, 11.5, -38.4), V(1.2, 0.3, 1.2), TRIM, KM.Wood)
	end
	for _, span in { { -5.4, -1.2 }, { 5.2, 9.4 } } do
		box("PorchRail", span[1], 3.6, -38.5, span[2], 3.9, -38.1, TRIM, M.Wood)
		box("PorchRailBottom", span[1], 1.25, -38.5, span[2], 1.45, -38.1, TRIM, M.Wood)
		for x = span[1] + 0.5, span[2] - 0.4, 0.55 do
			box("Baluster", x - 0.08, 1.45, -38.4, x + 0.08, 3.6, -38.2, TRIM, M.Wood, { CanCollide = false })
		end
	end
	-- porch lantern by the door, on the house power
	local _, porchLamp = Kit.wallLantern(f, F(-1.2, 8.2, -30.55, NZ))
	local pl = Instance.new("PointLight")
	pl.Range = 22
	pl.Brightness = 1.2
	pl.Color = Color3.fromRGB(255, 196, 130)
	pl.Shadows = true
	pl.Parent = porchLamp
	ctx.Power.onChanged(function(on)
		pl.Enabled = on
		porchLamp.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end, porchLamp)
	-- welcome mat, potted plants by the door, house number
	box("WelcomeMat", 0.5, 1, -32.6, 3.5, 1.05, -31, Color3.fromRGB(90, 70, 50), M.Fabric, { CanCollide = false })
	Kit.plant(f, F(-3.6, 1, -31.6, NZ), 1.2, "leafy", Color3.fromRGB(60, 60, 64))
	Kit.plant(f, F(7.6, 1, -31.6, NZ), 1.2, "leafy", Color3.fromRGB(60, 60, 64))
	box("HouseNumber", 5, 8.5, -30.62, 6.6, 9.3, -30.55, Color3.fromRGB(40, 40, 40), M.Metal, { CanCollide = false })

	box("Driveway", 43, 0, -62, 63, 1, -30.5, Color3.fromRGB(96, 96, 96), M.Concrete)
	for z = -58, -34, 6 do
		box("DriveJoint", 43, 1, z, 63, 1.02, z + 0.12, Color3.fromRGB(80, 80, 80), M.Concrete, { CanCollide = false, CanQuery = false })
	end
	box("DriveJoint", 52.94, 1, -62, 53.06, 1.02, -30.5, Color3.fromRGB(80, 80, 80), M.Concrete, { CanCollide = false, CanQuery = false })
	box("BackStep", -24, 0, 30.5, -16, 0.75, 34, deck, M.Planks)
	box("SideStep", 66.5, 0, -5, 69.5, 0.75, 1, CONCRETE, M.Concrete)
	Kit.mailbox(f, F(6.2, 0.5, -63.2, NZ))
	Kit.hydrant(f, F(-30, 0.6, -64.5, NZ))
	for i = 0, 1 do
		Kit.trashBin(f, F(40.3 + i * 2.6, 0.6, -64.8, NZ), Color3.fromRGB(40, 70, 50))
	end

	---------------------------------------------------------------------------
	-- Garden: foundation hedges, shrubs, flower beds, trees
	---------------------------------------------------------------------------
	for _, span in { { -39, -22 }, { -22, -7 } } do
		Kit.hedge(f, F((span[1] + span[2]) / 2, 0.5, -32.6, NZ), span[2] - span[1] - 0.4, 3.2, 2.4)
	end
	box("Mulch", -40, 0.5, -34.2, -6, 0.62, -30.6, Color3.fromRGB(70, 50, 36), M.Fabric, { CanCollide = false })
	box("Mulch", 10.5, 0.5, -34.2, 40, 0.62, -30.6, Color3.fromRGB(70, 50, 36), M.Fabric, { CanCollide = false })
	for i, x in { 13, 18, 23, 29, 35 } do
		Kit.shrub(f, F(x, 0.55, -32.6, NZ), 2.6 + (i % 2) * 0.5, i)
	end
	-- side-yard shrubs along the living room and garage
	for i, z in { -24, 0, 16 } do
		Kit.shrub(f, F(-43.5, 0.55, z, PX), 3.2, 20 + i)
	end
	-- trees: a big maple by the drive, oaks and pines around the lots
	local trees = {
		{ "tree", 30, -50, 26 }, { "tree", -55, -50, 24 }, { "pine", -80, 10, 30 }, { "tree", -45, 72, 26 },
		{ "pine", 85, 40, 28 }, { "tree", 30, 96, 24 }, { "pine", -110, -40, 32 }, { "tree", 150, -45, 25 },
		{ "pine", -140, 60, 30 }, { "tree", 75, -50, 22 }, { "pine", 150, 30, 34 }, { "tree", -150, -20, 26 },
		{ "pine", -60, 110, 30 }, { "pine", 60, 120, 32 }, { "tree", 0, 130, 28 }, { "pine", 190, -10, 30 },
		{ "tree", -30, -130, 26 }, { "pine", 40, -140, 30 }, { "tree", 110, -130, 24 }, { "pine", -110, -125, 32 },
		{ "tree", 175, 90, 28 }, { "pine", -190, 100, 34 }, { "pine", -200, -60, 30 },
	}
	for i, t in trees do
		if t[1] == "pine" then
			Kit.pine(f, V(t[2], 0.5, t[3]), t[4], i)
		else
			Kit.tree(f, V(t[2], 0.5, t[3]), t[4], i)
		end
	end

	---------------------------------------------------------------------------
	-- Street lamps
	---------------------------------------------------------------------------
	for _, x in { 22, -95, 140 } do
		local _, head = Kit.streetLamp(f, F(x, 0.6, -64.2, NZ), 17)
		local sl = Instance.new("SpotLight")
		sl.Face = Enum.NormalId.Bottom
		sl.Range = 45
		sl.Angle = 110
		sl.Brightness = 2.2
		sl.Color = Color3.fromRGB(255, 200, 140)
		sl.Parent = head
	end

	---------------------------------------------------------------------------
	-- Back yard: board fence, shed, swing set, patio
	---------------------------------------------------------------------------
	local fenceColor = Color3.fromRGB(116, 96, 74)
	Kit.boardFence(f, V(-60, 0.5, 30), V(-60, 0.5, 80), 6, fenceColor)
	Kit.boardFence(f, V(-60, 0.5, 80), V(70, 0.5, 80), 6, fenceColor)
	Kit.boardFence(f, V(70, 0.5, 80), V(70, 0.5, 6), 6, fenceColor)
	Kit.boardFence(f, V(-60, 0.5, 30), V(-40.5, 0.5, 30), 6, fenceColor)
	Kit.boardFence(f, V(66.5, 0.5, 6), V(70, 0.5, 6), 6, fenceColor)
	-- patio off the back door with a grill and chairs
	box("Patio", -30, 0.5, 34, -10, 0.7, 46, Color3.fromRGB(150, 140, 128), M.Slate)
	local grill = Kit.model(f, "Grill")
	Kit.ellipsoid(grill, "GrillBowl", CF(-13, 3.4, 42), V(2.2, 1.6, 2.2), C.Black, KM.Metal)
	Kit.ellipsoid(grill, "GrillLid", CF(-13, 3.8, 42), V(2.1, 1.4, 2.1), Color3.fromRGB(30, 30, 32), KM.Metal)
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		Kit.box(grill, "GrillLeg", CF(-13 + math.cos(a) * 0.7, 1.8, 42 + math.sin(a) * 0.7) * ANG(math.sin(a) * 0.15, 0, -math.cos(a) * 0.15), V(0.12, 2.6, 0.12), C.Black, KM.Metal)
	end
	Kit.collider(grill, CF(-13, 2.2, 42), V(2.2, 3.4, 2.2))
	for i = 0, 1 do
		Kit.chair(f, F(-24 + i * 4, 0.7, 42, NZ), Color3.fromRGB(236, 232, 224), Color3.fromRGB(60, 90, 120))
	end
	-- the shed
	local shed = Kit.model(f, "Shed")
	local shedWall = Color3.fromRGB(110, 96, 82)
	Kit.solid(shed, "ShedWalls", CF(53.5, 5.25, 69), V(17, 9.5, 14), shedWall, KM.Planks)
	for _, s in { -1, 1 } do
		Kit.wedge(shed, "ShedRoof", CF(53.5, 11.25, 69 + s * 3.75) * ANG(0, s > 0 and math.pi or 0, 0), V(18, 2.5, 7.5), C.Roof, KM.Slate)
	end
	Kit.box(shed, "ShedDoor", CF(53.5, 4.5, 61.95), V(5, 8, 0.15), Color3.fromRGB(150, 60, 50), KM.Wood)
	Kit.box(shed, "ShedDoorX", CF(53.5, 4.5, 61.85) * ANG(0, 0, rad(58)), V(8.5, 0.35, 0.08), Color3.fromRGB(236, 232, 224), KM.Wood)
	Kit.box(shed, "ShedWindow", CF(47.5, 6.5, 61.95), V(2.6, 2, 0.12), Color3.fromRGB(30, 34, 38), KM.Glass)
	Kit.box(shed, "ShedTrim", CF(53.5, 10.1, 61.9), V(17.2, 0.3, 0.2), Color3.fromRGB(236, 232, 224), KM.Wood)
	-- swing set
	local swing = Kit.model(f, "SwingSet")
	local steel = Color3.fromRGB(150, 60, 50)
	for _, x in { -32, -19 } do
		for _, s in { -1, 1 } do
			Kit.box(swing, "SwingLeg", CF(x, 5, 60 + s * 1.6) * ANG(s * rad(-17), 0, 0), V(0.3, 9.6, 0.3), steel, KM.Metal)
		end
	end
	Kit.cyl(swing, "SwingBar", CF(-25.5, 9.5, 60), 13.4, 0.35, steel, KM.Metal)
	for _, x in { -28.5, -22.5 } do
		for _, s in { -1, 1 } do
			Kit.box(swing, "Chain", CF(x + s * 0.8, 6.2, 60), V(0.06, 6.5, 0.06), Color3.fromRGB(170, 170, 170), KM.Metal)
		end
		Kit.soft(swing, "SwingSeat", CF(x, 2.9, 60), V(2, 0.18, 0.8), 0.07, Color3.fromRGB(30, 30, 32), KM.Rubber)
	end
	Kit.collider(swing, CF(-25.5, 4.5, 60), V(14, 9, 3.4))

	---------------------------------------------------------------------------
	-- The gray van, parked a little too long
	---------------------------------------------------------------------------
	local vp = L.Outside.Van
	local van = Kit.van(f, F(vp.X, 0.45, vp.Z, PX), Color3.fromRGB(122, 124, 126))
	van.Name = "GrayVan"
	refs.Van = van

	-- a neighbor's car across the street, for scale and life
	Kit.sedan(f, F(-10, 0.45, -90, NX), Color3.fromRGB(40, 60, 90))

	---------------------------------------------------------------------------
	-- Phone junction box on the garage's east wall
	---------------------------------------------------------------------------
	local jb = L.Outside.JunctionBox
	local jm = Instance.new("Model")
	jm.Name = "JunctionBox"
	jm.Parent = f
	B.box(jm, "Box", V(66.5, jb.Y - 1.2, jb.Z - 1), V(67.2, jb.Y + 1.2, jb.Z + 1), Color3.fromRGB(150, 150, 145), M.Metal)
	local wire = B.box(jm, "Wire", V(66.7, jb.Y + 1.2, jb.Z - 0.1), V(66.9, 15, jb.Z + 0.1), C.Black, M.Plastic, { CanCollide = false })
	local cut = B.box(jm, "CutWire", V(66.7, jb.Y + 1.2, jb.Z - 0.1), V(66.9, jb.Y + 3, jb.Z + 0.1), C.Black, M.Plastic, { CanCollide = false, Transparency = 1 })
	local door = B.box(jm, "BoxDoor", V(67.2, jb.Y - 1.2, jb.Z - 1), V(67.35, jb.Y + 1.2, jb.Z + 1), Color3.fromRGB(160, 160, 155), M.Metal)
	B.box(jm, "Conduit", V(66.6, 0.5, jb.Z - 0.15), V(66.9, jb.Y - 1.2, jb.Z + 0.15), Color3.fromRGB(120, 120, 118), M.Metal, { CanCollide = false })
	local openCF = CFrame.new(V(67.2, jb.Y, jb.Z - 1)) * CFrame.Angles(0, math.rad(-100), 0) * CFrame.new(0.07, 0, 1)
	ctx.Escape.setupJunctionBox(jm, door, openCF, wire, cut)
	ctx.Objectives.setTarget("JunctionBox", door.Position + V(1, 0, 0))

	---------------------------------------------------------------------------
	-- Mrs. Okafor's house (x 95..130): lit windows, a real porch, warm inside
	---------------------------------------------------------------------------
	local nx0, nx1, nz0, nz1 = 95, 130, -30, 0
	local ncol = Color3.fromRGB(176, 160, 132)
	local nhouse = Kit.model(f, "NeighborHouse")
	local function nbox(name, x0, y0, z0, x1, y1, z1, color, mat, extra)
		return B.box(nhouse, name, V(x0, y0, z0), V(x1, y1, z1), color, mat, extra)
	end
	nbox("NFloor", nx0, -1, nz0, nx1, 1, nz1, Color3.fromRGB(130, 100, 70), M.Planks)
	nbox("NFoundation", nx0 - 0.6, 0, nz0 - 0.6, nx1 + 0.6, 1.2, nz1 + 0.6, Color3.fromRGB(120, 118, 112), M.Concrete, { CanCollide = false })
	nbox("NWall", nx0, 1, nz0 - 0.5, 107.5, 13, nz0, ncol, M.Siding)
	nbox("NWall", 112.5, 1, nz0 - 0.5, nx1, 13, nz0, ncol, M.Siding)
	nbox("NWall", 107.5, 10, nz0 - 0.5, 112.5, 13, nz0, ncol, M.Siding)
	nbox("NWall", nx0, 1, nz1, nx1, 13, nz1 + 0.5, ncol, M.Siding)
	nbox("NWall", nx0 - 0.5, 1, nz0, nx0, 13, nz1, ncol, M.Siding)
	nbox("NWall", nx1, 1, nz0, nx1 + 0.5, 13, nz1, ncol, M.Siding)
	for _, x in { nx0 - 0.55, nx1 + 0.05 } do
		nbox("NCorner", x, 1, nz0 - 0.55, x + 0.5, 13, nz0 - 0.05, TRIM, M.Wood, { CanCollide = false })
	end
	nbox("NCeiling", nx0, 13, nz0, nx1, 13.5, nz1, C.Drywall, M.Wall)
	nbox("NFascia", nx0 - 1, 12.6, nz0 - 1.1, nx1 + 1, 13.4, nz0 - 0.5, TRIM, M.Wood)
	nbox("NFascia", nx0 - 1, 12.6, nz1 + 0.5, nx1 + 1, 13.4, nz1 + 1.1, TRIM, M.Wood)
	B.part(nhouse, { ClassName = "WedgePart", Name = "NRoof", Size = V(38, 8, 16.2), CFrame = CFrame.new((nx0 + nx1) / 2, 17.4, nz0 + 7.5) * CFrame.Angles(0, math.pi, 0), Color = C.Roof, Material = M.Roof })
	B.part(nhouse, { ClassName = "WedgePart", Name = "NRoof", Size = V(38, 8, 16.2), CFrame = CFrame.new((nx0 + nx1) / 2, 17.4, nz1 - 7.5), Color = C.Roof, Material = M.Roof })
	for _, x in { nx0 - 0.25, nx1 + 0.25 } do
		B.part(nhouse, { ClassName = "WedgePart", Name = "NGable", Size = V(0.5, 8, 15), CFrame = CFrame.new(x, 17.4, nz0 + 7.5) * CFrame.Angles(0, math.pi, 0), Color = ncol, Material = M.Siding })
		B.part(nhouse, { ClassName = "WedgePart", Name = "NGable", Size = V(0.5, 8, 15), CFrame = CFrame.new(x, 17.4, nz1 - 7.5), Color = ncol, Material = M.Siding })
	end
	nbox("NChimney", 124, 10, -12, 127, 24, -9, Color3.fromRGB(116, 62, 50), M.Brick)
	-- porch, steps, columns, railing
	nbox("NPorch", 102, 0, -38, 118, 1.2, nz0 - 0.5, Color3.fromRGB(128, 116, 104), M.Planks)
	nbox("NPorchStep", 107, 0, -40, 113, 0.6, -38, Color3.fromRGB(128, 116, 104), M.Planks)
	nbox("NPorchRoof", 101, 11.5, -38.8, 119, 12, nz0 - 0.5, C.Roof, M.Roof)
	for _, x in { 102.6, 117.4 } do
		Kit.vcyl(nhouse, "NColumn", CF(x, 6.35, -38), 10.3, 0.7, TRIM, KM.Wood, { CanCollide = true })
	end
	for _, span in { { 102.6, 107 }, { 113, 117.4 } } do
		nbox("NRail", span[1], 3.4, -38.2, span[2], 3.65, -37.8, TRIM, M.Wood)
		for x = span[1] + 0.5, span[2] - 0.3, 0.6 do
			nbox("NBaluster", x - 0.07, 1.2, -38.1, x + 0.07, 3.4, -37.9, TRIM, M.Wood, { CanCollide = false })
		end
	end
	-- windows glowing warm, with shutters
	for _, wx in { 97.5, 121.5 } do
		nbox("NWindowFrame", wx - 0.3, 4.6, nz0 - 0.7, wx + 5.8, 9.9, nz0 - 0.45, TRIM, M.Wood)
		nbox("NWindow", wx, 5, nz0 - 0.75, wx + 5.5, 9.5, nz0 - 0.6, Color3.fromRGB(255, 210, 140), Enum.Material.Neon)
		nbox("NMullion", wx + 2.65, 5, nz0 - 0.8, wx + 2.85, 9.5, nz0 - 0.7, TRIM, M.Wood, { CanCollide = false })
		for _, sx in { wx - 1.8, wx + 5.8 } do
			nbox("NShutter", sx, 4.6, nz0 - 0.75, sx + 1.5, 9.9, nz0 - 0.55, Color3.fromRGB(50, 70, 60), M.Wood, { CanCollide = false })
		end
	end
	local ndoor = nbox("NeighborDoor", 107.5, 1, nz0 - 0.45, 112.5, 10, nz0 - 0.1, Color3.fromRGB(40, 70, 60), M.Wood)
	nbox("NDoorFrame", 107.1, 1, nz0 - 0.6, 107.5, 10.4, nz0 - 0.4, TRIM, M.Wood, { CanCollide = false })
	nbox("NDoorFrame", 112.5, 1, nz0 - 0.6, 112.9, 10.4, nz0 - 0.4, TRIM, M.Wood, { CanCollide = false })
	nbox("NDoorFrame", 107.1, 10, nz0 - 0.6, 112.9, 10.4, nz0 - 0.4, TRIM, M.Wood, { CanCollide = false })
	nbox("NDoorWindow", 108.8, 6.5, nz0 - 0.5, 111.2, 8.8, nz0 - 0.44, Color3.fromRGB(255, 210, 140), Enum.Material.Neon, { CanCollide = false })
	local _, nlamp = Kit.wallLantern(nhouse, F(114, 8, nz0 - 0.5, NZ))
	local npl = Instance.new("PointLight")
	npl.Range = 24
	npl.Brightness = 1.2
	npl.Color = Color3.fromRGB(255, 210, 150)
	npl.Parent = nlamp
	ctx.Escape.setupNeighbor(ndoor)
	ctx.Objectives.setTarget("NeighborDoor", ndoor.Position + V(0, 0, -1))
	for i, x in { 99, 104, 116, 121, 126 } do
		Kit.shrub(nhouse, F(x, 0.55, -32, NZ), 2.4, 40 + i)
	end
	-- inside: warm and safe
	local lamp = Kit.ball(nhouse, "NLamp", V(112, 12.4, -15), 1.4, Color3.fromRGB(255, 230, 190), KM.Neon)
	local il = Instance.new("PointLight")
	il.Range = 30
	il.Brightness = 1.2
	il.Color = Color3.fromRGB(255, 215, 170)
	il.Parent = lamp
	Kit.sofa(nhouse, F(106, 1, -5.5, NZ), 10, Color3.fromRGB(130, 60, 60), Color3.fromRGB(220, 190, 120))
	Kit.rug(nhouse, F(110, 1, -16, NZ), 18, 12, Color3.fromRGB(150, 110, 60))
	Kit.armchair(nhouse, F(122, 1, -12, NX), Color3.fromRGB(110, 90, 60))
	Kit.bookcase(nhouse, F(128.9, 1, -22, NX), 5, 1.2, 8, 4)
	Kit.floorLamp(nhouse, F(98, 1, -4, NZ))
	-- her car in her driveway
	B.box(nhouse, "NDriveway", V(132, 0, -62), V(146, 1, -8), Color3.fromRGB(96, 96, 96), M.Concrete)
	Kit.sedan(nhouse, F(139, 0.95, -24, PZ), Color3.fromRGB(200, 196, 180))
	Kit.picketFence(nhouse, V(90, 0.5, -28), V(90, 0.5, 20), 3.5)

	-- invisible world bounds
	for _, b in { { -262, -200, -260, 200 }, { 260, -200, 262, 200 }, { -262, -202, 262, -200 }, { -262, 200, 262, 202 } } do
		box("Bounds", b[1], -5, b[2], b[3], 80, b[4], C.Black, M.Plastic, { Transparency = 1 })
	end
	return refs
end

return Exterior
