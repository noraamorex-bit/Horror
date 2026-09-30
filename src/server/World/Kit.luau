--[[
	Kit — the model library. Detailed, part-built furniture, props, vehicles and plants.

	Every model is placed with a CFrame `cf` at floor level in the middle of its footprint,
	facing cf.LookVector (so the model's front is local -Z, its right is local +X).
	Decorative parts never collide or block raycasts; each model adds one or two invisible
	"Collider" boxes instead, so players bump into a clean shape and the physics stays cheap.

	Shape helpers:
		box, solid, collider, ball, ellipsoid, cyl (along local X), vcyl (upright), wedge,
		soft (a box whose four edges along local X are rounded), softZ (rounded along local Z),
		taper (a stack of discs), lathe (a turned profile), ring, cone
]]

local CollectionService = game:GetService("CollectionService")

local Kit = {}

local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad

local function mat(name: string, fallback: string): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	if ok and m then
		return m
	end
	return (Enum.Material :: any)[fallback]
end

local M = {
	Wood = Enum.Material.Wood,
	Planks = Enum.Material.WoodPlanks,
	Fabric = Enum.Material.Fabric,
	Plastic = Enum.Material.SmoothPlastic,
	Metal = Enum.Material.Metal,
	Glass = Enum.Material.Glass,
	Marble = Enum.Material.Marble,
	Granite = Enum.Material.Granite,
	Concrete = Enum.Material.Concrete,
	Neon = Enum.Material.Neon,
	Brick = Enum.Material.Brick,
	Cobble = Enum.Material.Cobblestone,
	Slate = Enum.Material.Slate,
	Grass = Enum.Material.Grass,
	Leafy = Enum.Material.LeafyGrass,
	Leather = mat("Leather", "Fabric"),
	Rubber = mat("Rubber", "SmoothPlastic"),
	Cardboard = mat("Cardboard", "Fabric"),
	Plaster = mat("Plaster", "SmoothPlastic"),
	Asphalt = mat("Asphalt", "Concrete"),
	Tile = mat("CeramicTiles", "Slate"),
	Siding = Enum.Material.WoodPlanks,
	Roof = mat("RoofShingles", "Slate"),
}
Kit.M = M

local C = {
	WoodDark = Color3.fromRGB(74, 52, 38),
	WoodMid = Color3.fromRGB(128, 92, 62),
	WoodLight = Color3.fromRGB(176, 138, 98),
	Cream = Color3.fromRGB(236, 230, 214),
	Brass = Color3.fromRGB(196, 168, 104),
	Chrome = Color3.fromRGB(196, 198, 202),
	Steel = Color3.fromRGB(170, 172, 176),
	Black = Color3.fromRGB(22, 22, 24),
	Porcelain = Color3.fromRGB(244, 244, 240),
	Paper = Color3.fromRGB(238, 234, 220),
	Rubber = Color3.fromRGB(28, 28, 30),
}
Kit.C = C

local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

local function darker(c: Color3, k: number): Color3
	return c:Lerp(BLACK, k)
end
local function lighter(c: Color3, k: number): Color3
	return c:Lerp(WHITE, k)
end
Kit.darker = darker
Kit.lighter = lighter

---------------------------------------------------------------------------
-- Primitives
---------------------------------------------------------------------------
local function new(className: string, parent: Instance, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, opts): BasePart
	local p = Instance.new(className) :: BasePart
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or M.Plastic
	if size.X * size.Y * size.Z < 0.03 then
		p.CastShadow = false
	end
	if opts then
		for k, v in opts do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

function Kit.model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function Kit.box(parent, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, opts): BasePart
	return new("Part", parent, name, cf, size, color, material, opts)
end

-- a visible part that collides and can be targeted by prompts
function Kit.solid(parent, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, opts): BasePart
	local p = new("Part", parent, name, cf, size, color, material, opts)
	p.CanCollide = true
	p.CanQuery = true
	return p
end

function Kit.collider(parent, cf: CFrame, size: Vector3, name: string?): BasePart
	local p = new("Part", parent, name or "Collider", cf, size, BLACK, M.Plastic)
	p.Transparency = 1
	p.CanCollide = true
	p.CanQuery = true
	p.CastShadow = false
	return p
end

function Kit.ball(parent, name: string, pos: Vector3, d: number, color: Color3, material: Enum.Material?, opts): BasePart
	local p = new("Part", parent, name, CF(pos), V(d, d, d), color, material, opts)
	p.Shape = Enum.PartType.Ball
	return p
end

-- a true ellipsoid of any proportions (a Ball part is always round)
function Kit.ellipsoid(parent, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, opts): BasePart
	local p = new("Part", parent, name, cf, size, color, material, opts)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- cylinder along cf's local X axis
function Kit.cyl(parent, name: string, cf: CFrame, length: number, d: number, color: Color3, material: Enum.Material?, opts): BasePart
	local p = new("Part", parent, name, cf, V(length, d, d), color, material, opts)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- upright cylinder centred on cf
function Kit.vcyl(parent, name: string, cf: CFrame, h: number, d: number, color: Color3, material: Enum.Material?, opts): BasePart
	return Kit.cyl(parent, name, cf * ANG(0, 0, rad(90)), h, d, color, material, opts)
end

-- wedge: full height at local +Z, sloping down to local -Z
function Kit.wedge(parent, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, opts): BasePart
	return new("WedgePart", parent, name, cf, size, color, material, opts)
end

-- a box with its four edges along local X rounded to radius r (cushions, mattresses, rails)
function Kit.soft(parent, name: string, cf: CFrame, size: Vector3, r: number, color: Color3, material: Enum.Material?, opts): BasePart
	r = math.min(r, size.Y / 2 - 0.01, size.Z / 2 - 0.01)
	if r <= 0.02 then
		return Kit.box(parent, name, cf, size, color, material, opts)
	end
	local core = Kit.box(parent, name, cf, V(size.X, size.Y - 2 * r, size.Z), color, material, opts)
	Kit.box(parent, name, cf, V(size.X, size.Y, size.Z - 2 * r), color, material, opts)
	for _, sy in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Kit.cyl(parent, name, cf * CF(0, sy * (size.Y / 2 - r), sz * (size.Z / 2 - r)), size.X, 2 * r, color, material, opts)
		end
	end
	return core
end

-- same, rounded along local Z (size is still given in local X/Y/Z)
function Kit.softZ(parent, name: string, cf: CFrame, size: Vector3, r: number, color: Color3, material: Enum.Material?, opts): BasePart
	return Kit.soft(parent, name, cf * ANG(0, rad(90), 0), V(size.Z, size.Y, size.X), r, color, material, opts)
end

-- stacked discs from diameter d0 (bottom) to d1 (top); cf = centre of the base
function Kit.taper(parent, name: string, cf: CFrame, h: number, d0: number, d1: number, n: number, color: Color3, material: Enum.Material?, opts): BasePart?
	local first
	n = math.max(1, n)
	for i = 0, n - 1 do
		local t = (i + 0.5) / n
		local p = Kit.vcyl(parent, name, cf * CF(0, h * t, 0), h / n + 0.01, d0 + (d1 - d0) * t, color, material, opts)
		first = first or p
	end
	return first
end

-- a turned profile { {y, diameter}, ... } bottom to top; cf = centre of the base
function Kit.lathe(parent, name: string, cf: CFrame, profile, color: Color3, material: Enum.Material?, opts)
	for i = 1, #profile - 1 do
		local a, b = profile[i], profile[i + 1]
		local h = b[1] - a[1]
		if h > 0.001 then
			local n = math.clamp(math.ceil(math.abs(b[2] - a[2]) / 0.07), 1, 8)
			Kit.taper(parent, name, cf * CF(0, a[1], 0), h, a[2], b[2], n, color, material, opts)
		end
	end
end

-- a ring of n blocks in cf's XZ plane
function Kit.ring(parent, name: string, cf: CFrame, radius: number, thick: number, height: number, n: number, color: Color3, material: Enum.Material?, opts)
	local w = 2 * radius * math.tan(math.pi / n) + 0.02
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		Kit.box(parent, name, cf * ANG(0, a, 0) * CF(0, 0, -radius), V(w, height, thick), color, material, opts)
	end
end

-- a cone of n wedges; cf = centre of the base
function Kit.cone(parent, name: string, cf: CFrame, h: number, r: number, n: number, color: Color3, material: Enum.Material?, opts)
	local w = 2 * r * math.tan(math.pi / n) + 0.05
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		Kit.wedge(parent, name, cf * ANG(0, a, 0) * CF(0, h / 2, -r / 2), V(w, h, r), color, material, opts)
	end
end

-- oriented placement helper: CFrame at `pos` facing `dir` (horizontal)
function Kit.facing(pos: Vector3, dir: Vector3): CFrame
	return CFrame.lookAt(pos, pos + V(dir.X, 0, dir.Z))
end

---------------------------------------------------------------------------
-- Seating
---------------------------------------------------------------------------
function Kit.sofa(parent, cf: CFrame, length: number, color: Color3, pillow: Color3?, opts)
	opts = opts or {}
	local m = Kit.model(parent, opts.Name or "Sofa")
	local depth = opts.Depth or 3.8
	local dark = darker(color, 0.16)
	local armW = 0.8
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Kit.taper(m, "Leg", cf * CF(sx * (length / 2 - 0.4), 0, sz * (depth / 2 - 0.4)), 0.45, 0.24, 0.34, 2, C.WoodDark, M.Wood)
		end
	end
	Kit.soft(m, "SofaBase", cf * CF(0, 0.88, 0), V(length, 0.86, depth), 0.18, dark, M.Fabric)
	local inner = length - 2 * armW
	local n = math.max(1, math.floor(inner / 2.9 + 0.5))
	local cw = inner / n
	local seatD = depth - 1.0
	for i = 1, n do
		local x = -inner / 2 + cw * (i - 0.5)
		Kit.soft(m, "SeatCushion", cf * CF(x, 1.64, -depth / 2 + seatD / 2 + 0.04), V(cw - 0.08, 0.66, seatD), 0.24, color, M.Fabric)
		Kit.soft(m, "BackCushion", cf * CF(x, 2.95, depth / 2 - 0.95) * ANG(rad(11), 0, 0), V(cw - 0.1, 1.85, 0.72), 0.28, color, M.Fabric)
	end
	Kit.soft(m, "SofaBack", cf * CF(0, 2.56, depth / 2 - 0.3), V(length, 2.62, 0.6), 0.24, dark, M.Fabric)
	for _, s in { -1, 1 } do
		local ax = s * (length / 2 - armW / 2)
		Kit.box(m, "Arm", cf * CF(ax, 1.98, 0.02), V(armW, 1.5, depth - 0.12), dark, M.Fabric)
		Kit.cyl(m, "ArmRoll", cf * CF(ax, 2.73, 0.02) * ANG(0, rad(90), 0), depth - 0.12, armW + 0.14, dark, M.Fabric)
		Kit.cyl(m, "ArmFace", cf * CF(ax, 2.73, -depth / 2 + 0.02) * ANG(0, rad(90), 0), 0.06, armW + 0.2, darker(color, 0.28), M.Fabric)
	end
	if pillow then
		for _, s in { -1, 1 } do
			Kit.soft(m, "Pillow", cf * CF(s * (inner / 2 - 0.8), 2.62, depth / 2 - 1.5) * ANG(rad(16), rad(s * -10), rad(s * -6)), V(1.35, 1.3, 0.42), 0.2, pillow, M.Fabric)
		end
	end
	Kit.collider(m, cf * CF(0, 1.02, 0), V(length, 2.04, depth))
	Kit.collider(m, cf * CF(0, 3.0, depth / 2 - 0.45), V(length, 1.9, 0.9))
	return m
end

function Kit.armchair(parent, cf: CFrame, color: Color3, pillow: Color3?)
	return Kit.sofa(parent, cf, 3.9, color, nil, { Name = "Armchair" })
end

function Kit.chair(parent, cf: CFrame, color: Color3?, cushion: Color3?)
	color = color or C.WoodMid
	local m = Kit.model(parent, "Chair")
	local dark = darker(color :: Color3, 0.12)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Kit.taper(m, "ChairLeg", cf * CF(sx * 0.72, 0, sz * 0.72), 1.9, 0.18, 0.24, 2, dark, M.Wood)
		end
		Kit.box(m, "Stretcher", cf * CF(sx * 0.72, 0.6, 0), V(0.12, 0.12, 1.4), dark, M.Wood)
	end
	Kit.soft(m, "Seat", cf * CF(0, 2.02, 0), V(1.95, 0.22, 1.9), 0.1, color :: Color3, M.Wood)
	if cushion then
		Kit.soft(m, "SeatPad", cf * CF(0, 2.2, 0.05), V(1.72, 0.16, 1.62), 0.08, cushion, M.Fabric)
	end
	local back = cf * CF(0, 0, 0.8) * ANG(rad(7), 0, 0)
	for _, sx in { -1, 1 } do
		Kit.taper(m, "BackPost", back * CF(sx * 0.72, 2.1, 0), 2.6, 0.22, 0.17, 2, dark, M.Wood)
		Kit.ball(m, "Finial", (back * CF(sx * 0.72, 4.78, 0)).Position, 0.24, dark, M.Wood)
	end
	Kit.soft(m, "TopRail", back * CF(0, 4.35, 0), V(1.62, 0.5, 0.2), 0.08, color :: Color3, M.Wood)
	for k = -1, 1 do
		Kit.vcyl(m, "Spindle", back * CF(k * 0.36, 3.2, 0), 1.9, 0.11, dark, M.Wood)
	end
	Kit.box(m, "BackRail", back * CF(0, 2.35, 0), V(1.5, 0.14, 0.14), dark, M.Wood)
	Kit.collider(m, cf * CF(0, 1.1, 0), V(1.9, 2.2, 1.9), "ChairBlock")
	return m
end

function Kit.stool(parent, cf: CFrame, color: Color3)
	local m = Kit.model(parent, "Stool")
	Kit.vcyl(m, "StoolSeat", cf * CF(0, 3.25, 0), 0.25, 1.45, color, M.Wood)
	Kit.vcyl(m, "StoolPad", cf * CF(0, 3.42, 0), 0.12, 1.3, darker(color, 0.2), M.Leather)
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		local leg = cf * CF(math.cos(a) * 0.35, 1.6, math.sin(a) * 0.35) * ANG(math.sin(a) * rad(-6), 0, math.cos(a) * rad(6))
		Kit.vcyl(m, "StoolLeg", leg, 3.2, 0.12, C.Black, M.Metal)
	end
	Kit.ring(m, "FootRing", cf * CF(0, 1.1, 0), 0.52, 0.08, 0.08, 10, C.Black, M.Metal)
	Kit.collider(m, cf * CF(0, 1.7, 0), V(1.3, 3.4, 1.3))
	return m
end

function Kit.officeChair(parent, cf: CFrame, color: Color3)
	local m = Kit.model(parent, "OfficeChair")
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		local dir = V(math.cos(a), 0, math.sin(a))
		Kit.box(m, "Spoke", CFrame.lookAt((cf * CF(0, 0.45, 0)).Position + dir * 0.55, (cf * CF(0, 0.45, 0)).Position + dir * 2), V(0.16, 0.12, 1.1), C.Black, M.Plastic)
		Kit.ball(m, "Caster", (cf * CF(0, 0.2, 0)).Position + dir * 1.05, 0.34, C.Black, M.Plastic)
	end
	Kit.vcyl(m, "GasLift", cf * CF(0, 1.2, 0), 1.5, 0.22, C.Chrome, M.Metal)
	Kit.soft(m, "Seat", cf * CF(0, 2.05, 0), V(2, 0.4, 2), 0.18, color, M.Fabric)
	local back = cf * CF(0, 0, 0.95) * ANG(rad(10), 0, 0)
	Kit.box(m, "BackStem", back * CF(0, 2.5, 0.05), V(0.3, 0.9, 0.12), C.Black, M.Plastic)
	Kit.soft(m, "Backrest", back * CF(0, 3.55, 0), V(1.9, 2.1, 0.32), 0.15, color, M.Fabric)
	for _, s in { -1, 1 } do
		Kit.box(m, "ArmPost", cf * CF(s * 1.02, 2.5, 0.1), V(0.12, 0.8, 0.12), C.Black, M.Plastic)
		Kit.soft(m, "ArmPad", cf * CF(s * 1.02, 2.95, 0), V(0.25, 0.14, 1.1), 0.06, C.Black, M.Plastic)
	end
	Kit.collider(m, cf * CF(0, 1.1, 0), V(2, 2.2, 2))
	return m
end

function Kit.beanbag(parent, cf: CFrame, color: Color3, s: number?)
	local k = s or 1
	local m = Kit.model(parent, "BeanBag")
	Kit.ellipsoid(m, "BeanBag", cf * CF(0, 1.05 * k, 0.1 * k), V(3.4, 2.2, 3.3) * k, color, M.Fabric)
	Kit.ellipsoid(m, "BeanBagBack", cf * CF(0, 1.9 * k, 0.9 * k) * ANG(rad(20), 0, 0), V(2.8, 1.4, 1.4) * k, darker(color, 0.06), M.Fabric)
	Kit.ellipsoid(m, "Dent", cf * CF(0, 1.9 * k, -0.25 * k), V(1.8, 0.4, 1.5) * k, darker(color, 0.14), M.Fabric)
	Kit.collider(m, cf * CF(0, 0.9 * k, 0), V(3, 1.8, 3) * k)
	return m
end

---------------------------------------------------------------------------
-- Tables and case goods
---------------------------------------------------------------------------
function Kit.coffeeTable(parent, cf: CFrame, w: number, d: number, h: number, color: Color3)
	local m = Kit.model(parent, "CoffeeTable")
	local dark = darker(color, 0.14)
	local top = Kit.soft(m, "TableTop", cf * CF(0, h - 0.14, 0), V(w, 0.28, d), 0.1, color, M.Wood)
	Kit.box(m, "Apron", cf * CF(0, h - 0.46, 0), V(w - 0.5, 0.36, d - 0.5), dark, M.Wood)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Kit.taper(m, "Leg", cf * CF(sx * (w / 2 - 0.4), 0, sz * (d / 2 - 0.4)), h - 0.28, 0.2, 0.34, 3, dark, M.Wood)
		end
	end
	Kit.box(m, "Shelf", cf * CF(0, 0.55, 0), V(w - 0.7, 0.12, d - 0.7), dark, M.Wood)
	Kit.collider(m, cf * CF(0, h / 2, 0), V(w, h, d))
	return m, top
end

function Kit.diningTable(parent, cf: CFrame, w: number, d: number, color: Color3)
	local m = Kit.model(parent, "DiningTable")
	local dark = darker(color, 0.14)
	local h = 3.8
	Kit.soft(m, "TableTop", cf * CF(0, h - 0.17, 0), V(w, 0.34, d), 0.12, color, M.Wood)
	Kit.box(m, "Apron", cf * CF(0, h - 0.55, 0), V(w - 0.8, 0.45, d - 0.8), dark, M.Wood)
	local leg = { { 0, 0.34 }, { 0.25, 0.4 }, { 0.4, 0.28 }, { 1.6, 0.26 }, { 1.85, 0.42 }, { 2.1, 0.3 }, { 3.0, 0.3 }, { 3.35, 0.42 } }
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Kit.lathe(m, "Leg", cf * CF(sx * (w / 2 - 0.55), 0, sz * (d / 2 - 0.55)), leg, dark, M.Wood)
		end
	end
	Kit.collider(m, cf * CF(0, h / 2, 0), V(w, h, d))
	return m, h
end

function Kit.nightstand(parent, cf: CFrame, color: Color3)
	local m = Kit.model(parent, "Nightstand")
	local dark = darker(color, 0.14)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Kit.taper(m, "Foot", cf * CF(sx * 0.9, 0, sz * 0.8), 0.35, 0.16, 0.24, 1, dark, M.Wood)
		end
	end
	Kit.box(m, "Case", cf * CF(0, 1.33, 0), V(2.1, 1.96, 1.9), color, M.Wood)
	Kit.soft(m, "Top", cf * CF(0, 2.38, 0), V(2.3, 0.14, 2.05), 0.06, color, M.Wood)
	Kit.box(m, "Cubby", cf * CF(0, 0.95, -0.9), V(1.75, 0.95, 0.12), darker(color, 0.45), M.Wood)
	local drawer = Kit.box(m, "Drawer", cf * CF(0, 1.88, -0.98), V(1.85, 0.66, 0.08), lighter(color, 0.08), M.Wood)
	Kit.box(m, "DrawerPanel", cf * CF(0, 1.88, -1.03), V(1.5, 0.4, 0.04), color, M.Wood)
	Kit.ball(m, "Knob", (cf * CF(0, 1.88, -1.1)).Position, 0.2, C.Brass, M.Metal)
	Kit.collider(m, cf * CF(0, 1.2, 0), V(2.3, 2.4, 2.05))
	return m, drawer, 2.45
end

function Kit.dresser(parent, cf: CFrame, w: number, color: Color3)
	local m = Kit.model(parent, "Dresser")
	local dark = darker(color, 0.14)
	local d, h = 1.9, 3.9
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Kit.ball(m, "BunFoot", (cf * CF(sx * (w / 2 - 0.35), 0.18, sz * (d / 2 - 0.3))).Position, 0.36, dark, M.Wood)
		end
	end
	Kit.box(m, "Case", cf * CF(0, 0.35 + (h - 0.5) / 2, 0), V(w, h - 0.5, d), color, M.Wood)
	Kit.soft(m, "Top", cf * CF(0, h - 0.07, 0), V(w + 0.25, 0.16, d + 0.15), 0.07, color, M.Wood)
	Kit.box(m, "Plinth", cf * CF(0, 0.45, -0.02), V(w + 0.08, 0.22, d + 0.04), dark, M.Wood)
	local rowH = (h - 1.0) / 3
	for r = 0, 2 do
		local y = 0.65 + rowH * (r + 0.5)
		local cols = r == 2 and 2 or 1
		for c = 1, cols do
			local cwid = (w - 0.3) / cols
			local x = -(w - 0.3) / 2 + cwid * (c - 0.5)
			Kit.box(m, "Drawer", cf * CF(x, y, -d / 2 - 0.03), V(cwid - 0.1, rowH - 0.12, 0.08), lighter(color, 0.07), M.Wood)
			Kit.box(m, "Pull", cf * CF(x, y + rowH * 0.12, -d / 2 - 0.13), V(math.min(0.9, cwid * 0.3), 0.08, 0.08), C.Brass, M.Metal)
		end
	end
	Kit.collider(m, cf * CF(0, h / 2, 0), V(w, h, d))
	return m, h
end

function Kit.desk(parent, cf: CFrame, w: number, d: number, color: Color3)
	local m = Kit.model(parent, "Desk")
	local dark = darker(color, 0.14)
	local h = 3.7
	Kit.soft(m, "DeskTop", cf * CF(0, h - 0.14, 0), V(w, 0.28, d), 0.08, color, M.Wood)
	local pedW = 1.9
	Kit.box(m, "Pedestal", cf * CF(w / 2 - pedW / 2 - 0.05, (h - 0.28) / 2, 0), V(pedW, h - 0.28, d - 0.2), color, M.Wood)
	for r = 0, 2 do
		local y = 0.45 + r * 1.05
		Kit.box(m, "DeskDrawerFace", cf * CF(w / 2 - pedW / 2 - 0.05, y + 0.45, -d / 2 + 0.06), V(pedW - 0.2, 0.9, 0.08), lighter(color, 0.08), M.Wood)
		Kit.box(m, "Pull", cf * CF(w / 2 - pedW / 2 - 0.05, y + 0.7, -d / 2 - 0.02), V(0.6, 0.08, 0.08), C.Brass, M.Metal)
	end
	Kit.box(m, "Panel", cf * CF(-w / 2 + 0.12, (h - 0.28) / 2, 0), V(0.2, h - 0.28, d - 0.2), color, M.Wood)
	Kit.box(m, "Modesty", cf * CF(-0.9, h - 1.1, d / 2 - 0.2), V(w - pedW - 0.4, 1.4, 0.12), dark, M.Wood)
	Kit.collider(m, cf * CF(0, h / 2, 0), V(w, h, d))
	return m, h
end

-- bed: head at local +Z; `open` is the local side you crawl under from (a unit axis)
function Kit.bed(parent, cf: CFrame, w: number, l: number, duvet: Color3, frameColor: Color3, open: Vector3)
	local m = Kit.model(parent, "Bed")
	local dark = darker(frameColor, 0.12)
	local sheet = Color3.fromRGB(246, 244, 238)
	-- rails (the collision body you hide under)
	local frame = Kit.solid(m, "BedFrame", cf * CF(0, 1.9, 0), V(w, 0.6, l), frameColor, M.Wood)
	Kit.box(m, "RailLip", cf * CF(0, 1.62, 0), V(w + 0.08, 0.1, l + 0.08), dark, M.Wood)
	-- posts: tall at the head, short at the foot
	for _, e in { 1, -1 } do
		for _, s in { -1, 1 } do
			local top = e == 1 and 6.6 or 4.2
			local p = cf * CF(s * (w / 2 - 0.02), 0, e * (l / 2 - 0.02))
			Kit.box(m, "BedPost", p * CF(0, top / 2, 0), V(0.5, top, 0.5), dark, M.Wood)
			Kit.box(m, "PostCap", p * CF(0, top + 0.06, 0), V(0.62, 0.12, 0.62), frameColor, M.Wood)
			Kit.ball(m, "Finial", (p * CF(0, top + 0.35, 0)).Position, 0.45, frameColor, M.Wood)
		end
	end
	-- headboard: frame, upholstered panel, top rail
	local hb = cf * CF(0, 0, l / 2 - 0.12)
	Kit.box(m, "Headboard", hb * CF(0, 4.3, 0), V(w - 0.4, 4.1, 0.22), frameColor, M.Wood)
	Kit.soft(m, "HeadboardPanel", hb * CF(0, 4.3, -0.14), V(w - 1.1, 3.1, 0.2), 0.08, darker(duvet, 0.35):Lerp(Color3.fromRGB(120, 110, 100), 0.5), M.Fabric)
	Kit.cyl(m, "HeadRail", hb * CF(0, 6.4, 0), w - 0.4, 0.34, frameColor, M.Wood)
	-- footboard
	local fb = cf * CF(0, 0, -l / 2 + 0.12)
	Kit.box(m, "Footboard", fb * CF(0, 3.05, 0), V(w - 0.4, 1.7, 0.2), frameColor, M.Wood)
	Kit.cyl(m, "FootRail", fb * CF(0, 3.95, 0), w - 0.4, 0.3, frameColor, M.Wood)
	-- mattress, sheet, duvet with drape, turned-down edge
	Kit.softZ(m, "Mattress", cf * CF(0, 2.78, 0.05), V(w - 0.35, 1.16, l - 0.45), 0.32, sheet, M.Fabric)
	local duvetLen = (l - 0.45) * 0.7
	local dz = -(l - 0.45) / 2 + duvetLen / 2
	Kit.softZ(m, "Duvet", cf * CF(0, 3.46, dz), V(w - 0.1, 0.34, duvetLen), 0.16, duvet, M.Fabric)
	for _, s in { -1, 1 } do
		Kit.soft(m, "DuvetDrape", cf * CF(s * (w / 2 - 0.08), 2.9, dz), V(0.14, 1.2, duvetLen), 0.06, darker(duvet, 0.06), M.Fabric)
	end
	Kit.soft(m, "DuvetFoot", cf * CF(0, 2.95, -(l - 0.45) / 2 - 0.02), V(w - 0.1, 1.1, 0.14), 0.06, darker(duvet, 0.06), M.Fabric)
	Kit.soft(m, "Turndown", cf * CF(0, 3.66, dz + duvetLen / 2 - 0.45), V(w - 0.08, 0.14, 0.9), 0.06, sheet, M.Fabric)
	Kit.soft(m, "Throw", cf * CF(0, 3.66, dz - duvetLen / 2 + 1.0), V(w + 0.02, 0.12, 1.5), 0.05, duvet:Lerp(Color3.fromRGB(226, 214, 190), 0.6), M.Fabric)
	-- pillows leaning on the headboard
	local nP = w > 5.5 and 2 or 1
	for i = 1, nP do
		local x = nP == 1 and 0 or (i == 1 and -w / 4 or w / 4)
		local pw = math.min(2.7, w / nP - 0.5)
		local pc = cf * CF(x, 3.75, l / 2 - 1.05) * ANG(rad(60), 0, 0)
		Kit.soft(m, "Pillow", pc, V(pw, 1.4, 0.55), 0.26, sheet, M.Fabric)
		Kit.soft(m, "AccentPillow", cf * CF(x, 3.7, l / 2 - 1.7) * ANG(rad(72), 0, 0), V(pw * 0.62, 0.95, 0.38), 0.17, lighter(duvet, 0.3), M.Fabric)
	end
	-- skirt on every side except where you crawl under
	for _, dir in { V(1, 0, 0), V(-1, 0, 0), V(0, 0, 1), V(0, 0, -1) } do
		if (dir - open).Magnitude > 0.1 then
			local half = math.abs(dir.X) > 0 and w / 2 or l / 2
			local size = math.abs(dir.X) > 0 and V(0.1, 1.55, l - 0.5) or V(w - 0.5, 1.55, 0.1)
			Kit.box(m, "BedSkirt", cf * CF(dir * (half - 0.05)) * CF(0, 0.85, 0), size, darker(duvet, 0.22), M.Fabric)
		end
	end
	return m, frame
end

function Kit.wardrobe(parent, cf: CFrame, w: number, d: number, color: Color3)
	local m = Kit.model(parent, "Wardrobe")
	local h = 8.6
	local dark = darker(color, 0.1)
	Kit.solid(m, "WardrobeBack", cf * CF(0, h / 2, d / 2 - 0.15), V(w, h, 0.3), color, M.Wood)
	for _, s in { -1, 1 } do
		Kit.solid(m, "WardrobeSide", cf * CF(s * (w / 2 - 0.15), h / 2, 0), V(0.3, h, d), color, M.Wood)
	end
	Kit.solid(m, "WardrobeTop", cf * CF(0, h - 0.15, 0), V(w, 0.3, d), color, M.Wood)
	Kit.box(m, "Plinth", cf * CF(0, 0.25, -0.05), V(w + 0.1, 0.5, d + 0.05), dark, M.Wood)
	Kit.box(m, "Crown", cf * CF(0, h + 0.12, -0.05), V(w + 0.45, 0.25, d + 0.3), dark, M.Wood)
	Kit.soft(m, "CrownLip", cf * CF(0, h + 0.3, -0.08), V(w + 0.6, 0.14, d + 0.4), 0.06, color, M.Wood)
	local doors = Kit.solid(m, "WardrobeDoors", cf * CF(0, h / 2 + 0.2, -d / 2 + 0.12), V(w - 0.2, h - 0.8, 0.24), lighter(color, 0.05), M.Wood)
	Kit.box(m, "DoorSeam", cf * CF(0, h / 2 + 0.2, -d / 2 - 0.01), V(0.06, h - 1, 0.04), darker(color, 0.4), M.Wood)
	for _, s in { -1, 1 } do
		local dx = s * (w / 4 - 0.02)
		for k = 0, 1 do
			local ph = k == 0 and 3.2 or 2.6
			local py = k == 0 and 2.4 or 6.0
			Kit.box(m, "DoorPanel", cf * CF(dx, py, -d / 2 - 0.02), V(w / 2 - 0.9, ph, 0.05), darker(color, 0.07), M.Wood)
			Kit.box(m, "PanelInset", cf * CF(dx, py, -d / 2 - 0.035), V(w / 2 - 1.2, ph - 0.3, 0.04), lighter(color, 0.04), M.Wood)
		end
		Kit.box(m, "Handle", cf * CF(s * 0.3, h / 2 + 0.3, -d / 2 - 0.08), V(0.1, 0.9, 0.1), C.Brass, M.Metal)
	end
	return m, doors, h
end

-- bookcase against a wall; books fill the shelves, with the odd ornament
function Kit.bookcase(parent, cf: CFrame, w: number, d: number, h: number, levels: number, color: Color3?, seed: number?)
	color = color or C.WoodDark
	local m = Kit.model(parent, "Bookcase")
	local col = color :: Color3
	Kit.box(m, "ShelfBack", cf * CF(0, h / 2, d / 2 - 0.06), V(w, h, 0.12), darker(col, 0.2), M.Wood)
	for _, s in { -1, 1 } do
		Kit.box(m, "ShelfSide", cf * CF(s * (w / 2 - 0.1), h / 2, 0), V(0.2, h, d), col, M.Wood)
	end
	Kit.box(m, "ShelfTop", cf * CF(0, h + 0.1, -0.03), V(w + 0.2, 0.2, d + 0.1), col, M.Wood)
	Kit.box(m, "ShelfKick", cf * CF(0, 0.25, -d / 2 + 0.08), V(w, 0.5, 0.12), col, M.Wood)
	local rng = Random.new(seed or math.floor(cf.Position.X * 7 + cf.Position.Z * 3))
	local levelH = (h - 0.5) / levels
	for i = 0, levels - 1 do
		local yb = 0.5 + i * levelH
		Kit.box(m, "ShelfBoard", cf * CF(0, yb, 0), V(w - 0.3, 0.14, d - 0.1), col, M.Wood)
		local cursor = -w / 2 + 0.35
		while cursor < w / 2 - 0.6 do
			local roll = rng:NextNumber()
			if roll < 0.08 then
				-- a small vase
				local vc = Color3.fromHSV(rng:NextNumber(), 0.35, 0.7)
				Kit.lathe(m, "Vase", cf * CF(cursor + 0.35, yb + 0.07, 0), { { 0, 0.3 }, { 0.3, 0.55 }, { 0.7, 0.4 }, { 1.0, 0.22 }, { 1.1, 0.3 } }, vc, M.Plastic)
				cursor += 0.9
			elseif roll < 0.13 then
				-- books lying flat
				for k = 0, 2 do
					Kit.box(m, "Book", cf * CF(cursor + 0.55, yb + 0.14 + k * 0.18, 0) * ANG(0, rng:NextNumber(-0.2, 0.2), 0), V(1.0, 0.16, d - 0.35), Color3.fromHSV(rng:NextNumber(), rng:NextNumber(0.3, 0.6), rng:NextNumber(0.3, 0.65)), M.Cardboard)
				end
				cursor += 1.2
			else
				local bw = rng:NextNumber(0.22, 0.42)
				local bh = rng:NextNumber(math.min(1.2, levelH - 0.5), math.min(2.1, levelH - 0.3))
				local bd = d - rng:NextNumber(0.25, 0.45)
				local hue = rng:NextNumber()
				local bc = Color3.fromHSV(hue, rng:NextNumber(0.3, 0.6), rng:NextNumber(0.25, 0.6))
				local lean = (rng:NextNumber() < 0.07) and rng:NextNumber(0.15, 0.3) or 0
				local b = cf * CF(cursor + bw / 2, yb + 0.07 + bh / 2, 0) * ANG(0, 0, -lean)
				Kit.box(m, "Book", b, V(bw, bh, bd), bc, M.Cardboard)
				Kit.box(m, "Spine", b * CF(0, bh * 0.25, -bd / 2 - 0.005), V(bw * 0.9, 0.08, 0.02), lighter(bc, 0.5), M.Plastic)
				cursor += bw + 0.03 + lean * bh
			end
		end
	end
	Kit.collider(m, cf * CF(0, h / 2, 0), V(w, h, d))
	return m
end

---------------------------------------------------------------------------
-- Lighting fixtures (return bulb part + light)
---------------------------------------------------------------------------
local function bulbLight(m, pos: Vector3, range: number, brightness: number)
	local bulb = Kit.ball(m, "LampBulb", pos, 0.5, Color3.fromRGB(255, 206, 150), M.Plastic)
	local light = Instance.new("PointLight")
	light.Range = range
	light.Brightness = brightness
	light.Color = Color3.fromRGB(255, 180, 112)
	light.Shadows = true
	light.Parent = bulb
	return bulb, light
end

function Kit.floorLamp(parent, cf: CFrame, shadeColor: Color3?)
	local m = Kit.model(parent, "FloorLamp")
	local shade = shadeColor or Color3.fromRGB(232, 214, 182)
	Kit.vcyl(m, "LampBase", cf * CF(0, 0.06, 0), 0.12, 1.3, C.Brass, M.Metal)
	Kit.ellipsoid(m, "LampBaseDome", cf * CF(0, 0.12, 0), V(1.1, 0.35, 1.1), C.Brass, M.Metal)
	Kit.vcyl(m, "LampPole", cf * CF(0, 3.1, 0), 5.3, 0.14, C.Brass, M.Metal)
	Kit.vcyl(m, "Knuckle", cf * CF(0, 3.2, 0), 0.2, 0.24, C.Brass, M.Metal)
	-- a drum shade
	Kit.vcyl(m, "LampShade", cf * CF(0, 6.1, 0), 1.35, 1.9, shade, M.Fabric)
	Kit.vcyl(m, "ShadeTrim", cf * CF(0, 5.45, 0), 0.08, 1.94, darker(shade, 0.25), M.Fabric)
	Kit.vcyl(m, "ShadeTrim", cf * CF(0, 6.76, 0), 0.08, 1.94, darker(shade, 0.25), M.Fabric)
	Kit.ball(m, "Finial", (cf * CF(0, 7.1, 0)).Position, 0.18, C.Brass, M.Metal)
	local bulb, light = bulbLight(m, (cf * CF(0, 5.8, 0)).Position, 22, 1.35)
	Kit.collider(m, cf * CF(0, 3.5, 0), V(0.6, 7, 0.6))
	return m, bulb, light
end

function Kit.tableLamp(parent, cf: CFrame, baseColor: Color3?, shadeColor: Color3?)
	local m = Kit.model(parent, "TableLamp")
	local bc = baseColor or Color3.fromRGB(70, 110, 130)
	local shade = shadeColor or Color3.fromRGB(236, 222, 196)
	-- a ceramic gourd base and a drum shade
	Kit.vcyl(m, "LampFoot", cf * CF(0, 0.05, 0), 0.1, 0.6, C.Brass, M.Metal)
	Kit.ellipsoid(m, "LampBase", cf * CF(0, 0.62, 0), V(0.95, 1.15, 0.95), bc, M.Plastic)
	Kit.vcyl(m, "LampCollar", cf * CF(0, 1.25, 0), 0.14, 0.32, C.Brass, M.Metal)
	Kit.vcyl(m, "Neck", cf * CF(0, 1.62, 0), 0.6, 0.1, C.Brass, M.Metal)
	Kit.vcyl(m, "LampShade", cf * CF(0, 2.45, 0), 1.0, 1.4, shade, M.Fabric)
	Kit.vcyl(m, "ShadeTrim", cf * CF(0, 1.96, 0), 0.06, 1.44, darker(shade, 0.25), M.Fabric)
	local bulb, light = bulbLight(m, (cf * CF(0, 2.2, 0)).Position, 16, 1.0)
	return m, bulb, light
end

-- a bell-shaped pendant hanging `drop` studs below the ceiling point `top`
function Kit.pendant(parent, top: Vector3, drop: number, color: Color3?)
	local m = Kit.model(parent, "Pendant")
	local c = color or Color3.fromRGB(46, 60, 52)
	Kit.vcyl(m, "Canopy", CF(top - V(0, 0.08, 0)), 0.16, 0.7, c, M.Metal)
	Kit.vcyl(m, "PendantCord", CF(top - V(0, drop / 2, 0)), drop, 0.06, C.Black, M.Plastic)
	local base = CF(top - V(0, drop + 1.0, 0))
	Kit.lathe(m, "PendantShade", base, { { 0, 1.6 }, { 0.12, 1.55 }, { 0.45, 1.2 }, { 0.75, 0.7 }, { 0.95, 0.35 }, { 1.0, 0.2 } }, c, M.Metal)
	Kit.vcyl(m, "ShadeRim", base * CF(0, 0.02, 0), 0.05, 1.64, C.Brass, M.Metal)
	local bulb = Kit.ball(m, "PendantBulb", (base * CF(0, 0.15, 0)).Position, 0.5, Color3.fromRGB(255, 214, 160), M.Plastic)
	local light = Instance.new("PointLight")
	light.Range = 18
	light.Brightness = 1.15
	light.Color = Color3.fromRGB(255, 190, 125)
	light.Shadows = true
	light.Parent = bulb
	return m, bulb, light
end

function Kit.ceilingFan(parent, pos: Vector3, bladeColor: Color3?)
	local fan = Kit.model(parent, "CeilingFan")
	local metal = Color3.fromRGB(60, 52, 44)
	Kit.vcyl(fan, "Canopy", CF(pos - V(0, 0.1, 0)), 0.2, 0.8, metal, M.Metal)
	Kit.vcyl(fan, "FanRod", CF(pos - V(0, 0.65, 0)), 1.1, 0.16, metal, M.Metal)
	local hub = Kit.vcyl(fan, "FanHub", CF(pos - V(0, 1.4, 0)), 0.5, 1.2, metal, M.Metal)
	Kit.ellipsoid(fan, "LightBowl", CF(pos - V(0, 1.75, 0)), V(0.9, 0.5, 0.9), Color3.fromRGB(236, 224, 204), M.Glass, { Transparency = 0.2 })
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		local arm = CF(pos - V(0, 1.45, 0)) * ANG(0, a, 0)
		Kit.box(fan, "BladeIron", arm * CF(0.9, 0, 0), V(0.9, 0.08, 0.25), metal, M.Metal)
		Kit.soft(fan, "Blade", arm * CF(2.55, -0.02, 0) * ANG(rad(8), 0, 0), V(2.8, 0.07, 0.95), 0.03, bladeColor or C.WoodMid, M.Wood)
	end
	fan.PrimaryPart = hub
	fan:SetAttribute("Speed", 3.2)
	CollectionService:AddTag(fan, "Spinner")
	return fan
end

---------------------------------------------------------------------------
-- Screens and electronics
---------------------------------------------------------------------------
-- flat TV; cf = bottom centre of the panel. The screen's SurfaceGui face is Front.
function Kit.tv(parent, cf: CFrame, w: number, h: number, stand: boolean?)
	local m = Kit.model(parent, "TV")
	local y0 = stand and 0.35 or 0
	local frame = Kit.solid(m, "TV", cf * CF(0, y0 + h / 2, 0), V(w, h, 0.18), Color3.fromRGB(16, 16, 18), M.Plastic)
	Kit.box(m, "TVBack", cf * CF(0, y0 + h / 2 - 0.2, 0.18), V(w * 0.6, h * 0.55, 0.2), Color3.fromRGB(24, 24, 26), M.Plastic)
	local screen = Kit.box(m, "Screen", cf * CF(0, y0 + h / 2 + 0.05, -0.1), V(w - 0.22, h - 0.3, 0.03), Color3.fromRGB(8, 10, 14), M.Glass, { Reflectance = 0.12 })
	Kit.box(m, "Logo", cf * CF(0, y0 + 0.08, -0.1), V(0.3, 0.05, 0.02), Color3.fromRGB(120, 120, 125), M.Metal)
	if stand then
		for _, s in { -1, 1 } do
			Kit.box(m, "StandFoot", cf * CF(s * (w / 2 - 0.8), 0.18, 0) * ANG(0, 0, rad(s * 20)), V(0.12, 0.45, 0.9), Color3.fromRGB(30, 30, 32), M.Metal)
		end
	end
	return m, frame, screen
end

function Kit.monitor(parent, cf: CFrame, w: number, h: number)
	local m = Kit.model(parent, "Monitor")
	Kit.box(m, "MonitorBase", cf * CF(0, 0.04, 0.2), V(1.2, 0.08, 0.8), Color3.fromRGB(30, 30, 32), M.Plastic)
	Kit.box(m, "MonitorNeck", cf * CF(0, 0.6, 0.35), V(0.2, 1.1, 0.12), Color3.fromRGB(30, 30, 32), M.Plastic)
	local frame = Kit.box(m, "MonitorPanel", cf * CF(0, 0.7 + h / 2, 0.2), V(w, h, 0.14), Color3.fromRGB(20, 20, 22), M.Plastic)
	local screen = Kit.box(m, "MonitorScreen", cf * CF(0, 0.72 + h / 2, 0.12), V(w - 0.15, h - 0.2, 0.02), Color3.fromRGB(10, 14, 20), M.Glass, { Reflectance = 0.1 })
	return m, frame, screen
end

function Kit.keyboard(parent, cf: CFrame)
	local m = Kit.model(parent, "Keyboard")
	Kit.soft(m, "KeyboardBase", cf * CF(0, 0.05, 0), V(2.2, 0.1, 0.75), 0.04, Color3.fromRGB(34, 34, 36), M.Plastic)
	for r = 0, 3 do
		Kit.box(m, "KeyRow", cf * CF(0, 0.12, -0.25 + r * 0.17), V(2.0, 0.05, 0.12), Color3.fromRGB(56, 56, 60), M.Plastic)
	end
	Kit.ellipsoid(m, "Mouse", cf * CF(1.6, 0.08, 0.05), V(0.36, 0.18, 0.55), Color3.fromRGB(34, 34, 36), M.Plastic)
	return m
end

function Kit.laptop(parent, cf: CFrame, screenOn: boolean?)
	local m = Kit.model(parent, "Laptop")
	local shell = Color3.fromRGB(150, 152, 158)
	Kit.soft(m, "LaptopBase", cf * CF(0, 0.05, 0), V(2.2, 0.1, 1.5), 0.04, shell, M.Metal)
	Kit.box(m, "LaptopKeys", cf * CF(0, 0.105, -0.1), V(1.9, 0.02, 0.8), Color3.fromRGB(40, 40, 44), M.Plastic)
	Kit.box(m, "Trackpad", cf * CF(0, 0.105, 0.5), V(0.7, 0.02, 0.35), lighter(shell, 0.1), M.Plastic)
	local lid = cf * CF(0, 0.1, 0.75) * ANG(rad(105), 0, 0)
	Kit.box(m, "LaptopLid", lid * CF(0, 0, -0.72), V(2.2, 0.06, 1.45), shell, M.Metal)
	local screen = Kit.box(m, "LaptopScreen", lid * CF(0, -0.035, -0.72), V(2.0, 0.02, 1.25), screenOn and Color3.fromRGB(60, 90, 130) or Color3.fromRGB(10, 12, 16), screenOn and M.Neon or M.Glass)
	return m, screen
end

function Kit.gameConsole(parent, cf: CFrame)
	local m = Kit.model(parent, "Console")
	Kit.soft(m, "ConsoleBody", cf * CF(0, 0.2, 0), V(1.8, 0.4, 1.2), 0.08, Color3.fromRGB(26, 26, 30), M.Plastic)
	Kit.box(m, "ConsoleLED", cf * CF(0.7, 0.2, -0.61), V(0.12, 0.04, 0.02), Color3.fromRGB(80, 160, 255), M.Neon)
	return m
end

function Kit.controller(parent, cf: CFrame, color: Color3?)
	local m = Kit.model(parent, "Controller")
	local c = color or Color3.fromRGB(32, 32, 36)
	Kit.ellipsoid(m, "PadBody", cf * CF(0, 0.08, 0), V(0.9, 0.16, 0.45), c, M.Plastic)
	for _, s in { -1, 1 } do
		Kit.ellipsoid(m, "Grip", cf * CF(s * 0.34, 0.07, 0.18) * ANG(0, rad(s * 20), 0), V(0.28, 0.16, 0.45), c, M.Plastic)
	end
	return m
end

function Kit.phone(parent, cf: CFrame, color: Color3?)
	local m = Kit.model(parent, "Landline")
	local c = color or Color3.fromRGB(215, 210, 195)
	local body = Kit.solid(m, "Landline", cf * CF(0, 0.2, 0.05), V(1.0, 0.4, 1.3), c, M.Plastic)
	body.CFrame = cf * CF(0, 0.2, 0.05) * ANG(rad(-8), 0, 0)
	for r = 0, 3 do
		for k = -1, 1 do
			Kit.box(m, "Key", cf * CF(k * 0.22, 0.43 - r * 0.02, -0.15 + r * 0.18) * ANG(rad(-8), 0, 0), V(0.16, 0.05, 0.13), darker(c, 0.2), M.Plastic)
		end
	end
	Kit.ellipsoid(m, "Handset", cf * CF(-0.05, 0.55, 0.05) * ANG(0, rad(90), 0), V(1.35, 0.22, 0.32), c, M.Plastic)
	for _, s in { -1, 1 } do
		Kit.ellipsoid(m, "Cup", cf * CF(-0.05, 0.6, 0.05 + s * 0.55), V(0.42, 0.3, 0.36), c, M.Plastic)
	end
	return m, body
end

---------------------------------------------------------------------------
-- Kitchen
---------------------------------------------------------------------------
-- lower cabinets: cf = floor centre of the run, fronts face -Z. Returns the carcass.
function Kit.cabinets(parent, cf: CFrame, w: number, d: number, color: Color3, top: Color3?, h: number?, opts)
	opts = opts or {}
	h = h or 3.5
	local hh = h :: number
	local m = Kit.model(parent, "Cabinets")
	local carcass = Kit.solid(m, "Cabinet", cf * CF(0, 0.35 + (hh - 0.35) / 2, 0.08), V(w, hh - 0.35, d - 0.16), color, M.Wood)
	Kit.box(m, "ToeKick", cf * CF(0, 0.175, 0.25), V(w, 0.35, d - 0.5), Color3.fromRGB(40, 36, 32), M.Wood)
	if top then
		Kit.solid(m, "Countertop", cf * CF(0, hh + 0.15, -0.1), V(w + (opts.NoSideOverhang and 0 or 0.1), 0.3, d + 0.2), top, opts.TopMat or M.Granite)
	end
	local n = math.max(1, math.floor(w / 2.3 + 0.5))
	local dw = w / n
	local front = -d / 2 + 0.02
	local doorC = lighter(color, 0.06)
	for i = 0, n - 1 do
		local x = -w / 2 + dw * (i + 0.5)
		-- drawer
		local dy = hh - 0.5
		Kit.box(m, "Drawer", cf * CF(x, dy, front - 0.03), V(dw - 0.14, 0.62, 0.07), doorC, M.Wood)
		Kit.box(m, "Pull", cf * CF(x, dy, front - 0.12), V(math.min(0.9, dw * 0.4), 0.07, 0.07), C.Steel, M.Metal)
		-- shaker door: flat centre panel inside a raised frame
		local doorH = hh - 1.35
		local cy = 0.5 + doorH / 2
		Kit.box(m, "Door", cf * CF(x, cy, front - 0.02), V(dw - 0.14, doorH, 0.06), darker(doorC, 0.04), M.Wood)
		for _, s in { -1, 1 } do
			Kit.box(m, "Stile", cf * CF(x + s * (dw / 2 - 0.25), cy, front - 0.08), V(0.24, doorH, 0.06), doorC, M.Wood)
			Kit.box(m, "Rail", cf * CF(x, cy + s * (doorH / 2 - 0.13), front - 0.08), V(dw - 0.4, 0.24, 0.06), doorC, M.Wood)
		end
		local hx = (i % 2 == 0) and (dw / 2 - 0.45) or -(dw / 2 - 0.45)
		Kit.box(m, "Handle", cf * CF(x + hx, cy + doorH / 2 - 0.55, front - 0.16), V(0.07, 0.65, 0.07), C.Steel, M.Metal)
	end
	return m, carcass
end

function Kit.upperCabinets(parent, cf: CFrame, w: number, d: number, h: number, color: Color3)
	local m = Kit.model(parent, "UpperCabinets")
	Kit.solid(m, "UpperCabinet", cf * CF(0, h / 2, 0), V(w, h, d), color, M.Wood)
	Kit.box(m, "CabinetCrown", cf * CF(0, h + 0.1, -0.06), V(w + 0.2, 0.2, d + 0.12), lighter(color, 0.05), M.Wood)
	Kit.box(m, "LightRail", cf * CF(0, 0.05, -0.04), V(w, 0.1, d + 0.08), lighter(color, 0.05), M.Wood)
	local n = math.max(1, math.floor(w / 2.1 + 0.5))
	local dw = w / n
	local front = -d / 2
	local doorC = lighter(color, 0.06)
	for i = 0, n - 1 do
		local x = -w / 2 + dw * (i + 0.5)
		Kit.box(m, "Door", cf * CF(x, h / 2, front - 0.03), V(dw - 0.12, h - 0.25, 0.06), darker(doorC, 0.04), M.Wood)
		for _, s in { -1, 1 } do
			Kit.box(m, "Stile", cf * CF(x + s * (dw / 2 - 0.24), h / 2, front - 0.08), V(0.22, h - 0.25, 0.05), doorC, M.Wood)
			Kit.box(m, "Rail", cf * CF(x, h / 2 + s * ((h - 0.25) / 2 - 0.12), front - 0.08), V(dw - 0.5, 0.22, 0.05), doorC, M.Wood)
		end
		local hx = (i % 2 == 0) and (dw / 2 - 0.4) or -(dw / 2 - 0.4)
		Kit.box(m, "Handle", cf * CF(x + hx, 0.7, front - 0.14), V(0.07, 0.6, 0.07), C.Steel, M.Metal)
	end
	return m
end

function Kit.sink(parent, cf: CFrame, w: number, d: number)
	-- cf = centre of the countertop surface over the sink
	local m = Kit.model(parent, "Sink")
	Kit.box(m, "SinkRim", cf * CF(0, 0.01, 0), V(w, 0.03, d), C.Steel, M.Metal)
	Kit.box(m, "SinkBasin", cf * CF(0, 0.02, 0), V(w - 0.3, 0.03, d - 0.3), Color3.fromRGB(96, 100, 104), M.Metal)
	Kit.vcyl(m, "Drain", cf * CF(0, 0.04, 0), 0.02, 0.35, Color3.fromRGB(60, 60, 62), M.Metal)
	-- gooseneck faucet at the back
	local back = cf * CF(0, 0, d / 2 + 0.15)
	Kit.vcyl(m, "FaucetBase", back * CF(0, 0.08, 0), 0.16, 0.4, C.Chrome, M.Metal)
	Kit.vcyl(m, "Faucet", back * CF(0, 0.9, 0), 1.6, 0.18, C.Chrome, M.Metal)
	local r = 0.45
	local prev = (back * CF(0, 1.7, 0)).Position
	for k = 1, 6 do
		local a = k / 6 * math.pi
		local p = (back * CF(0, 1.7 + math.sin(a) * r, -(1 - math.cos(a)) * r)).Position
		Kit.cyl(m, "Gooseneck", CFrame.lookAt((prev + p) / 2, p) * ANG(0, rad(90), 0), (p - prev).Magnitude + 0.04, 0.18, C.Chrome, M.Metal)
		Kit.ball(m, "Gooseneck", p, 0.18, C.Chrome, M.Metal)
		prev = p
	end
	Kit.vcyl(m, "Spout", back * CF(0, 1.62, -0.9), 0.2, 0.2, C.Chrome, M.Metal)
	Kit.box(m, "Lever", back * CF(0.35, 0.45, 0) * ANG(0, 0, rad(-25)), V(0.5, 0.08, 0.1), C.Chrome, M.Metal)
	return m
end

function Kit.fridge(parent, cf: CFrame, w: number, d: number, h: number, color: Color3?)
	local m = Kit.model(parent, "Fridge")
	local c = color or Color3.fromRGB(206, 208, 210)
	local body = Kit.solid(m, "Fridge", cf * CF(0, h / 2, 0.1), V(w, h, d - 0.2), c, M.Metal)
	local fz = -d / 2 + 0.05
	local split = 3.3
	-- freezer drawer
	Kit.box(m, "FreezerDrawer", cf * CF(0, 0.35 + (split - 0.45) / 2, fz), V(w - 0.08, split - 0.5, 0.18), c, M.Metal)
	Kit.box(m, "DrawerHandle", cf * CF(0, split - 0.55, fz - 0.28), V(w - 1.2, 0.12, 0.12), C.Chrome, M.Metal)
	for _, s in { -1, 1 } do
		Kit.box(m, "Standoff", cf * CF(s * (w / 2 - 0.65), split - 0.55, fz - 0.16), V(0.1, 0.1, 0.2), C.Chrome, M.Metal)
	end
	-- french doors
	for _, s in { -1, 1 } do
		local dx = s * (w / 4 + 0.01)
		Kit.box(m, "FridgeDoor", cf * CF(dx, split + (h - split) / 2 - 0.05, fz), V(w / 2 - 0.06, h - split - 0.2, 0.18), c, M.Metal)
		Kit.box(m, "FridgeHandle", cf * CF(s * 0.28, split + (h - split) / 2, fz - 0.3), V(0.12, 3.2, 0.12), C.Chrome, M.Metal)
		for _, e in { -1, 1 } do
			Kit.box(m, "Standoff", cf * CF(s * 0.28, split + (h - split) / 2 + e * 1.45, fz - 0.17), V(0.1, 0.1, 0.22), C.Chrome, M.Metal)
		end
	end
	Kit.box(m, "Dispenser", cf * CF(-w / 4, split + 2.8, fz - 0.1), V(1.0, 1.4, 0.04), Color3.fromRGB(34, 36, 40), M.Glass)
	Kit.box(m, "Grille", cf * CF(0, 0.2, fz + 0.05), V(w - 0.3, 0.3, 0.06), Color3.fromRGB(40, 40, 42), M.Metal)
	-- the right door's surface, where notes and magnets go
	local noteFace = cf * CF(w / 4 + 0.01, 0, fz - 0.1)
	return m, body, noteFace
end

function Kit.range(parent, cf: CFrame, w: number, d: number)
	local m = Kit.model(parent, "Range")
	local body = Kit.solid(m, "Range", cf * CF(0, 1.8, 0), V(w, 3.6, d), C.Steel, M.Metal)
	local fz = -d / 2
	Kit.box(m, "OvenDoor", cf * CF(0, 1.55, fz - 0.05), V(w - 0.2, 2.1, 0.1), Color3.fromRGB(46, 48, 52), M.Metal)
	Kit.box(m, "OvenWindow", cf * CF(0, 1.5, fz - 0.11), V(w - 1.2, 1.1, 0.03), Color3.fromRGB(14, 14, 16), M.Glass, { Reflectance = 0.1 })
	Kit.cyl(m, "OvenHandle", cf * CF(0, 2.75, fz - 0.28), w - 0.8, 0.14, C.Chrome, M.Metal)
	for _, s in { -1, 1 } do
		Kit.box(m, "Standoff", cf * CF(s * (w / 2 - 0.5), 2.75, fz - 0.16), V(0.1, 0.1, 0.22), C.Chrome, M.Metal)
	end
	Kit.box(m, "StorageDrawer", cf * CF(0, 0.3, fz - 0.04), V(w - 0.2, 0.45, 0.08), Color3.fromRGB(46, 48, 52), M.Metal)
	Kit.box(m, "Cooktop", cf * CF(0, 3.62, 0), V(w - 0.1, 0.05, d - 0.2), Color3.fromRGB(18, 18, 20), M.Glass, { Reflectance = 0.1 })
	for _, p in { { -0.9, -0.6 }, { 0.9, -0.6 }, { -0.9, 0.55 }, { 0.9, 0.55 } } do
		Kit.ring(m, "Burner", cf * CF(p[1], 3.66, p[2]), 0.45, 0.06, 0.03, 12, Color3.fromRGB(120, 60, 50), M.Metal)
	end
	Kit.box(m, "Backguard", cf * CF(0, 4.05, d / 2 - 0.2), V(w, 0.9, 0.35), C.Steel, M.Metal)
	for k = -1.5, 1.5 do
		Kit.cyl(m, "Knob", cf * CF(k * 0.8, 4.05, d / 2 - 0.42) * ANG(0, rad(90), 0), 0.16, 0.34, C.Black, M.Plastic)
	end
	Kit.box(m, "Clock", cf * CF(0, 4.25, d / 2 - 0.4), V(0.7, 0.25, 0.02), Color3.fromRGB(60, 200, 120), M.Neon)
	return m, body
end

function Kit.hood(parent, cf: CFrame, w: number, d: number, ceilingY: number)
	-- cf = centre of the underside of the hood
	local m = Kit.model(parent, "Hood")
	Kit.box(m, "Hood", cf * CF(0, 0.2, 0), V(w, 0.4, d), C.Steel, M.Metal)
	-- sloped canopy up to the flue
	Kit.wedge(m, "HoodCanopy", cf * CF(0, 0.85, -0.25), V(w, 0.9, d - 0.5), C.Steel, M.Metal)
	Kit.box(m, "HoodCanopyBack", cf * CF(0, 0.85, d / 2 - 0.12), V(w, 0.9, 0.24), C.Steel, M.Metal)
	local top = ceilingY - cf.Position.Y
	Kit.box(m, "HoodFlue", cf * CF(0, 1.3 + (top - 1.3) / 2, 0.45), V(1.6, top - 1.3, 1.3), C.Steel, M.Metal)
	Kit.box(m, "HoodFilter", cf * CF(0, -0.01, 0), V(w - 0.4, 0.02, d - 0.4), Color3.fromRGB(80, 82, 86), M.Metal)
	return m
end

function Kit.microwave(parent, cf: CFrame)
	local m = Kit.model(parent, "Microwave")
	local w, d, h = 2.6, 1.7, 1.5
	local body = Kit.solid(m, "Microwave", cf * CF(0, h / 2, 0), V(w, h, d), Color3.fromRGB(30, 30, 32), M.Metal)
	local fz = -d / 2
	Kit.box(m, "MicrowaveDoor", cf * CF(-0.35, h / 2, fz - 0.03), V(w - 0.8, h - 0.16, 0.06), Color3.fromRGB(40, 40, 44), M.Metal)
	Kit.box(m, "MicrowaveWindow", cf * CF(-0.4, h / 2, fz - 0.065), V(w - 1.3, h - 0.55, 0.02), Color3.fromRGB(12, 16, 16), M.Glass, { Reflectance = 0.1 })
	Kit.box(m, "Panel", cf * CF(w / 2 - 0.37, h / 2, fz - 0.03), V(0.6, h - 0.16, 0.06), Color3.fromRGB(24, 24, 26), M.Plastic)
	Kit.box(m, "Display", cf * CF(w / 2 - 0.37, h - 0.3, fz - 0.065), V(0.45, 0.16, 0.02), Color3.fromRGB(60, 200, 120), M.Neon)
	for r = 0, 3 do
		for c = 0, 2 do
			Kit.box(m, "Button", cf * CF(w / 2 - 0.52 + c * 0.15, h - 0.55 - r * 0.15, fz - 0.07), V(0.1, 0.1, 0.02), Color3.fromRGB(90, 90, 96), M.Plastic)
		end
	end
	Kit.box(m, "MicrowaveHandle", cf * CF(w / 2 - 0.72, h / 2, fz - 0.14), V(0.08, h - 0.5, 0.1), C.Steel, M.Metal)
	return m, body
end

function Kit.dishwasher(parent, cf: CFrame, w: number, d: number, h: number)
	local m = Kit.model(parent, "Dishwasher")
	local body = Kit.solid(m, "Dishwasher", cf * CF(0, 0.35 + (h - 0.35) / 2, 0), V(w, h - 0.35, d), C.Steel, M.Metal)
	Kit.box(m, "ControlStrip", cf * CF(0, h - 0.25, -d / 2 - 0.02), V(w - 0.1, 0.35, 0.04), Color3.fromRGB(40, 40, 44), M.Plastic)
	Kit.cyl(m, "DWHandle", cf * CF(0, h - 0.7, -d / 2 - 0.18), w - 0.6, 0.12, C.Chrome, M.Metal)
	Kit.box(m, "ToeKick", cf * CF(0, 0.175, 0.25), V(w, 0.35, d - 0.5), Color3.fromRGB(40, 36, 32), M.Wood)
	return m, body
end

---------------------------------------------------------------------------
-- Bathroom
---------------------------------------------------------------------------
function Kit.toilet(parent, cf: CFrame)
	local m = Kit.model(parent, "Toilet")
	local P = C.Porcelain
	-- the bowl sits toward the front, the cistern at the back (local +Z)
	Kit.ellipsoid(m, "Pedestal", cf * CF(0, 0.7, 0.1), V(1.05, 1.5, 1.5), P, M.Plastic)
	Kit.box(m, "PedestalFoot", cf * CF(0, 0.08, 0.1), V(1.0, 0.16, 1.4), P, M.Plastic)
	Kit.ellipsoid(m, "Bowl", cf * CF(0, 1.45, -0.25), V(1.75, 0.85, 2.2), P, M.Plastic)
	Kit.ellipsoid(m, "Seat", cf * CF(0, 1.86, -0.25), V(1.85, 0.14, 2.3), Color3.fromRGB(250, 250, 248), M.Plastic)
	Kit.ellipsoid(m, "Water", cf * CF(0, 1.9, -0.3), V(1.1, 0.1, 1.45), Color3.fromRGB(150, 176, 186), M.Glass)
	Kit.soft(m, "Lid", cf * CF(0, 2.75, 0.72) * ANG(rad(12), 0, 0), V(1.75, 1.75, 0.12), 0.05, Color3.fromRGB(250, 250, 248), M.Plastic)
	Kit.soft(m, "Tank", cf * CF(0, 2.6, 1.15), V(2.0, 1.9, 0.75), 0.12, P, M.Plastic)
	Kit.soft(m, "TankLid", cf * CF(0, 3.6, 1.15), V(2.15, 0.16, 0.9), 0.06, Color3.fromRGB(250, 250, 248), M.Plastic)
	Kit.box(m, "FlushLever", cf * CF(-0.7, 3.25, 0.74), V(0.45, 0.09, 0.09), C.Chrome, M.Metal)
	Kit.vcyl(m, "SupplyPipe", cf * CF(0.6, 0.85, 1.45), 1.4, 0.1, C.Chrome, M.Metal)
	Kit.collider(m, cf * CF(0, 1.0, 0.2), V(2.0, 2.0, 2.8), "ToiletBlock")
	return m
end

function Kit.vanity(parent, cf: CFrame, w: number, d: number, color: Color3, top: Color3, basins: number?)
	local m, carcass = Kit.cabinets(parent, cf, w, d, color, top, 3.1, { TopMat = M.Marble })
	m.Name = "Vanity"
	local n = basins or 1
	for i = 1, n do
		local x = n == 1 and 0 or (i == 1 and -w / 4 or w / 4)
		Kit.ellipsoid(m, "Basin", cf * CF(x, 3.32, -0.1), V(1.7, 0.2, 1.25), Color3.fromRGB(226, 228, 230), M.Plastic)
		Kit.ellipsoid(m, "BasinInner", cf * CF(x, 3.36, -0.1), V(1.4, 0.14, 1.0), Color3.fromRGB(200, 206, 210), M.Plastic)
		local back = cf * CF(x, 3.25, d / 2 - 0.35)
		Kit.vcyl(m, "Faucet", back * CF(0, 0.5, 0), 0.8, 0.14, C.Chrome, M.Metal)
		Kit.cyl(m, "Spout", back * CF(0, 0.85, -0.25) * ANG(0, rad(90), 0), 0.55, 0.12, C.Chrome, M.Metal)
		Kit.box(m, "Lever", back * CF(0, 1.0, 0.05), V(0.08, 0.08, 0.4), C.Chrome, M.Metal)
	end
	return m, carcass
end

function Kit.mirror(parent, cf: CFrame, w: number, h: number, frameColor: Color3)
	-- cf = centre of the mirror, facing out from the wall
	local m = Kit.model(parent, "Mirror")
	Kit.box(m, "MirrorFrame", cf * CF(0, 0, 0.04), V(w + 0.4, h + 0.4, 0.1), frameColor, M.Wood)
	Kit.box(m, "Mirror", cf, V(w, h, 0.04), Color3.fromRGB(190, 200, 205), M.Glass, { Reflectance = 0.45 })
	return m
end

function Kit.bathtub(parent, cf: CFrame, l: number, w: number)
	-- length along local X; the faucet end is -X
	local m = Kit.model(parent, "Bathtub")
	local tub = Kit.solid(m, "Tub", cf * CF(0, 1.05, 0), V(l, 2.1, w), C.Porcelain, M.Plastic)
	Kit.soft(m, "TubRim", cf * CF(0, 2.12, 0), V(l + 0.1, 0.18, w + 0.1), 0.08, C.Porcelain, M.Plastic)
	Kit.box(m, "TubInner", cf * CF(0.1, 2.2, 0), V(l - 0.9, 0.04, w - 0.8), Color3.fromRGB(214, 224, 230), M.Plastic)
	Kit.box(m, "TubApron", cf * CF(0, 1.0, -w / 2 - 0.02), V(l - 0.2, 1.7, 0.04), Color3.fromRGB(236, 236, 232), M.Plastic)
	local e = cf * CF(-l / 2 + 0.3, 2.2, 0)
	Kit.vcyl(m, "TubFaucet", e * CF(0, 0.5, 0), 1.0, 0.16, C.Chrome, M.Metal)
	Kit.cyl(m, "TubSpout", e * CF(0.3, 0.95, 0), 0.6, 0.14, C.Chrome, M.Metal)
	for _, s in { -1, 1 } do
		Kit.cyl(m, "TubTap", e * CF(0, 0.65, s * 0.45) * ANG(0, 0, rad(90)), 0.2, 0.3, C.Chrome, M.Metal)
	end
	Kit.vcyl(m, "TubDrain", cf * CF(-l / 2 + 0.9, 2.23, 0), 0.02, 0.3, C.Chrome, M.Metal)
	return m, tub
end

function Kit.towel(parent, cf: CFrame, w: number, color: Color3)
	-- a towel over a bar; cf = centre of the bar, the wall at local +Z
	local m = Kit.model(parent, "Towel")
	Kit.cyl(m, "TowelBar", cf, w + 0.8, 0.1, C.Chrome, M.Metal)
	for _, s in { -1, 1 } do
		Kit.box(m, "BarPost", cf * CF(s * (w / 2 + 0.3), 0, 0.12), V(0.1, 0.1, 0.25), C.Chrome, M.Metal)
	end
	Kit.cyl(m, "TowelFold", cf, w, 0.3, color, M.Fabric)
	Kit.soft(m, "TowelFront", cf * CF(0, -0.95, -0.1), V(w, 1.9, 0.08), 0.03, color, M.Fabric)
	Kit.soft(m, "TowelBack", cf * CF(0, -0.8, 0.08), V(w, 1.6, 0.08), 0.03, darker(color, 0.06), M.Fabric)
	Kit.box(m, "TowelBand", cf * CF(0, -1.55, -0.15), V(w + 0.01, 0.18, 0.02), lighter(color, 0.35), M.Fabric)
	return m
end

---------------------------------------------------------------------------
-- Small props
---------------------------------------------------------------------------
function Kit.book(parent, cf: CFrame, size: Vector3, color: Color3)
	local m = Kit.model(parent, "Book")
	-- covers top and bottom, the spine on -X, pages showing on the other three edges
	for _, y in { 0.015, size.Y - 0.015 } do
		Kit.box(m, "Cover", cf * CF(0, y, 0), V(size.X, 0.03, size.Z), color, M.Cardboard)
	end
	Kit.box(m, "Spine", cf * CF(-size.X / 2 + 0.02, size.Y / 2, 0), V(0.04, size.Y, size.Z), color, M.Cardboard)
	Kit.box(m, "Pages", cf * CF(0.01, size.Y / 2, 0), V(size.X - 0.1, size.Y - 0.05, size.Z - 0.08), C.Paper, M.Plastic)
	return m
end

function Kit.bookStack(parent, cf: CFrame, n: number, seed: number?)
	local rng = Random.new(seed or 7)
	local y = 0
	for i = 1, n do
		local s = V(rng:NextNumber(1.1, 1.5), rng:NextNumber(0.14, 0.26), rng:NextNumber(0.8, 1.05))
		Kit.book(parent, cf * CF(0, y, 0) * ANG(0, rng:NextNumber(-0.25, 0.25), 0), s, Color3.fromHSV(rng:NextNumber(), rng:NextNumber(0.3, 0.6), rng:NextNumber(0.3, 0.7)))
		y += s.Y
	end
	return y
end

function Kit.mug(parent, cf: CFrame, color: Color3)
	local m = Kit.model(parent, "Mug")
	local body = Kit.vcyl(m, "Mug", cf * CF(0, 0.25, 0), 0.5, 0.42, color, M.Plastic)
	Kit.vcyl(m, "MugInside", cf * CF(0, 0.48, 0), 0.03, 0.34, Color3.fromRGB(40, 26, 18), M.Plastic)
	for k = 0, 4 do
		local a = -math.pi / 2 + k / 4 * math.pi
		Kit.ball(m, "MugHandle", (cf * CF(0.21 + math.cos(a) * 0.14, 0.25 + math.sin(a) * 0.14, 0)).Position, 0.07, color, M.Plastic)
	end
	return m, body
end

function Kit.plate(parent, cf: CFrame, d: number, color: Color3?)
	local m = Kit.model(parent, "Plate")
	Kit.lathe(m, "Plate", cf, { { 0, d * 0.55 }, { 0.03, d * 0.6 }, { 0.06, d * 0.95 }, { 0.08, d } }, color or C.Porcelain, M.Plastic)
	return m
end

-- a bowl: cf = centre of the base; returns the height of the rim
function Kit.bowl(parent, cf: CFrame, d: number, color: Color3, band: Color3?)
	local m = Kit.model(parent, "Bowl")
	local h = d * 0.42
	Kit.lathe(m, "Bowl", cf, { { 0, d * 0.45 }, { 0.06, d * 0.5 }, { h * 0.35, d * 0.78 }, { h * 0.7, d * 0.93 } }, color, M.Plastic)
	Kit.lathe(m, "BowlBand", cf * CF(0, h * 0.7, 0), { { 0, d * 0.93 }, { h * 0.22, d * 0.99 } }, band or color, M.Plastic)
	Kit.lathe(m, "BowlRim", cf * CF(0, h * 0.92, 0), { { 0, d * 0.99 }, { h * 0.08, d * 1.0 } }, color, M.Plastic)
	return m, h
end

function Kit.popcornBowl(parent, cf: CFrame, d: number?)
	local dd = d or 1.8
	local m, h = Kit.bowl(parent, cf, dd, Color3.fromRGB(246, 244, 238), Color3.fromRGB(196, 44, 40))
	m.Name = "PopcornBowl"
	local rng = Random.new(42)
	local R = dd * 0.48
	local colors = { Color3.fromRGB(252, 246, 226), Color3.fromRGB(250, 238, 200), Color3.fromRGB(246, 228, 176), Color3.fromRGB(252, 250, 240) }
	for _ = 1, 70 do
		local rr = R * math.sqrt(rng:NextNumber())
		local a = rng:NextNumber() * math.pi * 2
		local mound = (1 - (rr / R) ^ 2) * dd * 0.28
		local y = h * 0.82 + mound + rng:NextNumber(-0.04, 0.06)
		local k = rng:NextNumber(0.17, 0.27)
		Kit.ball(m, "Kernel", (cf * CF(math.cos(a) * rr, y, math.sin(a) * rr)).Position, k, colors[rng:NextInteger(1, #colors)], M.Fabric)
	end
	for _ = 1, 5 do
		local a = rng:NextNumber() * math.pi * 2
		Kit.ball(m, "Hull", (cf * CF(math.cos(a) * R * 0.6, h * 0.9 + rng:NextNumber(0, 0.2), math.sin(a) * R * 0.6)).Position, 0.1, Color3.fromRGB(200, 150, 70), M.Plastic)
	end
	return m
end

function Kit.candle(parent, cf: CFrame, h: number, d: number, lit: boolean?)
	local m = Kit.model(parent, "Candle")
	Kit.vcyl(m, "Candle", cf * CF(0, h / 2, 0), h, d, C.Cream, M.Plastic)
	Kit.vcyl(m, "Wick", cf * CF(0, h + 0.06, 0), 0.12, 0.03, C.Black, M.Plastic)
	if lit ~= false then
		local flame = Kit.ellipsoid(m, "Flame", cf * CF(0, h + 0.2, 0), V(0.12, 0.26, 0.12), Color3.fromRGB(255, 196, 96), M.Neon)
		-- a small warm pool of light that flickers (client Ambience, "Flicker" tag)
		local glow = Instance.new("PointLight")
		glow.Range = 7
		glow.Brightness = 0.55
		glow.Color = Color3.fromRGB(255, 168, 90)
		glow.Shadows = false
		glow.Parent = flame
		CollectionService:AddTag(glow, "Flicker")
	end
	return m
end

function Kit.vaseFlowers(parent, cf: CFrame, h: number, vaseColor: Color3, bloom: Color3, seed: number?)
	local m = Kit.model(parent, "Flowers")
	Kit.lathe(m, "Vase", cf, { { 0, h * 0.3 }, { h * 0.1, h * 0.36 }, { h * 0.5, h * 0.42 }, { h * 0.85, h * 0.22 }, { h, h * 0.26 } }, vaseColor, M.Glass, { Transparency = 0.15 })
	local rng = Random.new(seed or 3)
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local tilt = rng:NextNumber(0.1, 0.35)
		local len = h * rng:NextNumber(0.8, 1.2)
		local stem = cf * CF(0, h * 0.9, 0) * ANG(0, a, 0) * ANG(tilt, 0, 0)
		Kit.vcyl(m, "Stem", stem * CF(0, len / 2, 0), len, 0.05, Color3.fromRGB(70, 110, 60), M.Plastic)
		Kit.ball(m, "Bloom", (stem * CF(0, len, 0)).Position, rng:NextNumber(0.3, 0.45), bloom:Lerp(WHITE, rng:NextNumber(0, 0.3)), M.Fabric)
		Kit.ellipsoid(m, "Leaf", stem * CF(0, len * 0.5, -0.1) * ANG(rad(40), 0, 0), V(0.14, 0.04, 0.4), Color3.fromRGB(70, 120, 60), M.Plastic)
	end
	return m
end

function Kit.fruitBowl(parent, cf: CFrame)
	local m, h = Kit.bowl(parent, cf, 1.9, Color3.fromRGB(150, 110, 70), nil)
	m.Name = "FruitBowl"
	local fruit = {
		{ Color3.fromRGB(190, 36, 36), V(0.55, 0.52, 0.55), V(-0.3, 0, 0.1) },
		{ Color3.fromRGB(230, 150, 30), V(0.6, 0.58, 0.6), V(0.3, 0, -0.1) },
		{ Color3.fromRGB(120, 170, 60), V(0.52, 0.5, 0.52), V(0.05, 0.1, 0.35) },
		{ Color3.fromRGB(180, 30, 40), V(0.5, 0.48, 0.5), V(0.0, 0.3, -0.05) },
	}
	for _, f in fruit do
		Kit.ellipsoid(m, "Fruit", cf * CF(f[3].X, h * 0.75 + f[2].Y / 2 + f[3].Y, f[3].Z), f[2], f[1], M.Plastic)
	end
	for k = 0, 2 do
		Kit.ellipsoid(m, "Banana", cf * CF(-0.1, h + 0.25 + k * 0.05, -0.3 + k * 0.1) * ANG(0, rad(30 + k * 8), rad(12)), V(1.3, 0.25, 0.28), Color3.fromRGB(240, 210, 60), M.Plastic)
	end
	return m
end

function Kit.remote(parent, cf: CFrame)
	local m = Kit.model(parent, "Remote")
	local body = Kit.soft(m, "Remote", cf * CF(0, 0.06, 0), V(0.35, 0.12, 1.1), 0.05, Color3.fromRGB(26, 26, 28), M.Plastic)
	Kit.box(m, "PowerButton", cf * CF(0, 0.13, -0.4), V(0.1, 0.03, 0.1), Color3.fromRGB(190, 40, 40), M.Plastic)
	for r = 0, 3 do
		Kit.box(m, "Buttons", cf * CF(0, 0.13, -0.15 + r * 0.15), V(0.22, 0.03, 0.08), Color3.fromRGB(90, 90, 96), M.Plastic)
	end
	return m, body
end

function Kit.magazines(parent, cf: CFrame, n: number, seed: number?)
	local rng = Random.new(seed or 11)
	for i = 0, n - 1 do
		local c = Color3.fromHSV(rng:NextNumber(), 0.5, 0.75)
		local p = cf * CF(rng:NextNumber(-0.15, 0.15), 0.03 + i * 0.05, rng:NextNumber(-0.15, 0.15)) * ANG(0, rng:NextNumber(-0.5, 0.5), 0)
		Kit.box(parent, "Magazine", p, V(1.1, 0.04, 1.45), c, M.Plastic)
		Kit.box(parent, "MagazineTitle", p * CF(0, 0.025, -0.5), V(0.9, 0.01, 0.25), lighter(c, 0.6), M.Plastic)
	end
end

-- a framed picture; cf = centre of the picture, facing out from the wall
function Kit.picture(parent, cf: CFrame, w: number, h: number, frameColor: Color3, seed: number?)
	local m = Kit.model(parent, "Picture")
	local rng = Random.new(seed or 5)
	Kit.box(m, "PictureFrame", cf * CF(0, 0, 0.05), V(w + 0.3, h + 0.3, 0.1), frameColor, M.Wood)
	Kit.box(m, "Mat", cf * CF(0, 0, 0), V(w, h, 0.02), Color3.fromRGB(238, 234, 224), M.Plastic)
	-- a little landscape: sky, hills, ground
	local iw, ih = w - 0.5, h - 0.5
	local sky = Color3.fromHSV(rng:NextNumber(0.5, 0.65), rng:NextNumber(0.2, 0.5), rng:NextNumber(0.6, 0.9))
	Kit.box(m, "Canvas", cf * CF(0, ih * 0.15, -0.02), V(iw, ih * 0.7, 0.02), sky, M.Fabric)
	Kit.box(m, "Canvas", cf * CF(0, -ih * 0.35, -0.02), V(iw, ih * 0.3, 0.02), Color3.fromHSV(rng:NextNumber(0.2, 0.35), 0.4, 0.45), M.Fabric)
	for k = 0, 1 do
		Kit.ellipsoid(m, "Hill", cf * CF((k - 0.5) * iw * 0.45, -ih * 0.18, -0.025), V(iw * 0.55, ih * 0.45, 0.02), Color3.fromHSV(rng:NextNumber(0.22, 0.38), 0.35, 0.35 + k * 0.1), M.Fabric)
	end
	return m
end

function Kit.photoFrame(parent, cf: CFrame, w: number, h: number, frameColor: Color3, seed: number?)
	-- a small frame standing on a surface, leaning back
	local p = cf * CF(0, h / 2 + 0.05, 0) * ANG(rad(12), 0, 0)
	local m = Kit.picture(parent, p, w, h, frameColor, seed)
	Kit.box(m, "Stand", cf * CF(0, h * 0.3, 0.3) * ANG(rad(-25), 0, 0), V(0.1, h * 0.6, 0.05), frameColor, M.Wood)
	return m
end

function Kit.plant(parent, cf: CFrame, size: number, kind: string?, potColor: Color3?)
	local m = Kit.model(parent, "Plant")
	local s = size
	local pc = potColor or Color3.fromRGB(176, 98, 66)
	Kit.lathe(m, "Pot", cf, { { 0, 0.62 * s }, { 0.08 * s, 0.66 * s }, { 0.62 * s, 0.84 * s }, { 0.66 * s, 0.9 * s }, { 0.76 * s, 0.9 * s } }, pc, M.Concrete)
	Kit.vcyl(m, "Soil", cf * CF(0, 0.72 * s, 0), 0.04, 0.8 * s, Color3.fromRGB(52, 38, 28), M.Fabric)
	local rng = Random.new(math.floor(cf.Position.X * 31 + cf.Position.Z * 17))
	local base = cf * CF(0, 0.72 * s, 0)
	kind = kind or "leafy"
	if kind == "snake" then
		for i = 1, 9 do
			local a = i * 2.4
			local tilt = rng:NextNumber(0.05, 0.25)
			local len = s * rng:NextNumber(1.4, 2.4)
			local leaf = base * ANG(0, a, 0) * CF(0, 0, -0.12 * s) * ANG(-tilt, 0, 0)
			Kit.ellipsoid(m, "Leaf", leaf * CF(0, len / 2, 0), V(0.32 * s, len, 0.06), Color3.fromRGB(40 + rng:NextInteger(0, 25), 96 + rng:NextInteger(0, 30), 52), M.Plastic)
		end
	elseif kind == "tree" then
		local trunkH = s * 3.4
		Kit.taper(m, "Trunk", base, trunkH, 0.18 * s, 0.1 * s, 3, Color3.fromRGB(96, 72, 50), M.Wood)
		for i = 1, 22 do
			local t = rng:NextNumber(0.35, 1)
			local a = rng:NextNumber() * math.pi * 2
			local p = base * CF(0, trunkH * t, 0) * ANG(0, a, 0) * CF(0, 0, -rng:NextNumber(0.2, 0.7) * s) * ANG(rng:NextNumber(0.2, 0.9), 0, 0)
			Kit.ellipsoid(m, "Leaf", p, V(0.55 * s, 0.05, 0.75 * s), Color3.fromRGB(46 + rng:NextInteger(0, 20), 100 + rng:NextInteger(0, 30), 50), M.Plastic)
		end
	else
		for i = 1, 14 do
			local a = i * 2.39996
			local tilt = rng:NextNumber(0.35, 1.05)
			local len = s * rng:NextNumber(0.7, 1.3)
			local stem = base * ANG(0, a, 0) * ANG(-tilt, 0, 0)
			Kit.vcyl(m, "Stem", stem * CF(0, len / 2, 0), len, 0.05 * s, Color3.fromRGB(60, 100, 50), M.Plastic)
			local tip = stem * CF(0, len, 0) * ANG(tilt * 0.6, 0, 0)
			Kit.ellipsoid(m, "Leaf", tip * CF(0, 0, -0.35 * s), V(0.45 * s, 0.05, 0.85 * s), Color3.fromRGB(44 + rng:NextInteger(0, 22), 104 + rng:NextInteger(0, 30), 52 + rng:NextInteger(0, 12)), M.Plastic)
		end
	end
	Kit.collider(m, cf * CF(0, 0.4 * s, 0), V(0.9 * s, 0.8 * s, 0.9 * s))
	return m
end

function Kit.rug(parent, cf: CFrame, w: number, d: number, color: Color3, border: Color3?)
	local m = Kit.model(parent, "Rug")
	local b = border or lighter(color, 0.3)
	Kit.box(m, "Rug", cf * CF(0, 0.025, 0), V(w, 0.05, d), b, M.Fabric)
	Kit.box(m, "RugField", cf * CF(0, 0.055, 0), V(w - 1.0, 0.03, d - 1.0), color, M.Fabric)
	Kit.box(m, "RugInner", cf * CF(0, 0.075, 0), V(w - 2.2, 0.02, d - 2.2), lighter(color, 0.12), M.Fabric)
	Kit.box(m, "RugCore", cf * CF(0, 0.09, 0), V(math.max(0.5, w - 3.2), 0.02, math.max(0.5, d - 3.2)), color, M.Fabric)
	for _, s in { -1, 1 } do
		Kit.box(m, "Fringe", cf * CF(0, 0.02, s * (d / 2 + 0.12)), V(w - 0.2, 0.03, 0.24), lighter(b, 0.3), M.Fabric)
	end
	return m
end

function Kit.teddy(parent, cf: CFrame, s: number, color: Color3)
	local m = Kit.model(parent, "Teddy")
	local muzzle = lighter(color, 0.35)
	Kit.ellipsoid(m, "TeddyBody", cf * CF(0, 0.55 * s, 0), V(0.9, 1.05, 0.75) * s, color, M.Fabric)
	Kit.ellipsoid(m, "TeddyBelly", cf * CF(0, 0.5 * s, -0.3 * s), V(0.55, 0.65, 0.2) * s, muzzle, M.Fabric)
	Kit.ball(m, "TeddyHead", (cf * CF(0, 1.3 * s, -0.05 * s)).Position, 0.78 * s, color, M.Fabric)
	Kit.ellipsoid(m, "Muzzle", cf * CF(0, 1.22 * s, -0.38 * s), V(0.36, 0.26, 0.2) * s, muzzle, M.Fabric)
	Kit.ball(m, "Nose", (cf * CF(0, 1.28 * s, -0.48 * s)).Position, 0.1 * s, C.Black, M.Plastic)
	for _, x in { -1, 1 } do
		Kit.ball(m, "Ear", (cf * CF(x * 0.3 * s, 1.65 * s, -0.02 * s)).Position, 0.28 * s, color, M.Fabric)
		Kit.ball(m, "Eye", (cf * CF(x * 0.15 * s, 1.42 * s, -0.36 * s)).Position, 0.08 * s, C.Black, M.Plastic)
		Kit.ellipsoid(m, "Arm", cf * CF(x * 0.48 * s, 0.7 * s, -0.12 * s) * ANG(0, 0, rad(x * 25)), V(0.3, 0.6, 0.3) * s, color, M.Fabric)
		Kit.ellipsoid(m, "Leg", cf * CF(x * 0.28 * s, 0.15 * s, -0.3 * s), V(0.34, 0.3, 0.55) * s, color, M.Fabric)
	end
	return m
end

function Kit.clothesPile(parent, cf: CFrame, seed: number?)
	local rng = Random.new(seed or 9)
	for _ = 1, 6 do
		local c = Color3.fromHSV(rng:NextNumber(), rng:NextNumber(0.2, 0.5), rng:NextNumber(0.3, 0.7))
		Kit.ellipsoid(parent, "Clothes", cf * CF(rng:NextNumber(-0.8, 0.8), rng:NextNumber(0.1, 0.35), rng:NextNumber(-0.6, 0.6)) * ANG(0, rng:NextNumber(0, 6), rng:NextNumber(-0.2, 0.2)), V(rng:NextNumber(1.2, 1.8), 0.28, rng:NextNumber(0.8, 1.3)), c, M.Fabric)
	end
end

function Kit.shoe(parent, cf: CFrame, color: Color3)
	Kit.soft(parent, "Sole", cf * CF(0, 0.06, 0), V(0.42, 0.12, 1.05), 0.05, Color3.fromRGB(230, 226, 220), M.Rubber)
	Kit.soft(parent, "Upper", cf * CF(0, 0.26, 0.12), V(0.4, 0.3, 0.75), 0.12, color, M.Fabric)
	Kit.ellipsoid(parent, "Toe", cf * CF(0, 0.2, -0.3), V(0.4, 0.26, 0.5), color, M.Fabric)
end

-- a coat hanging from a hook point (the wall at local +Z)
function Kit.coat(parent, cf: CFrame, color: Color3)
	Kit.box(parent, "Hook", cf * CF(0, 0, 0.1), V(0.08, 0.08, 0.25), C.Brass, M.Metal)
	Kit.ellipsoid(parent, "Shoulders", cf * CF(0, -0.35, -0.1), V(1.4, 0.5, 0.45), color, M.Fabric)
	Kit.soft(parent, "CoatBody", cf * CF(0, -1.7, -0.12) * ANG(rad(-4), 0, 0), V(1.35, 2.6, 0.4), 0.14, color, M.Fabric)
	Kit.box(parent, "Placket", cf * CF(0, -1.7, -0.33) * ANG(rad(-4), 0, 0), V(0.06, 2.5, 0.02), darker(color, 0.25), M.Fabric)
end

function Kit.cardboardBox(parent, cf: CFrame, size: Vector3, color: Color3?, collide: boolean?)
	local c = color or Color3.fromRGB(176, 138, 92)
	local body = Kit.box(parent, "Box", cf * CF(0, size.Y / 2, 0), size, c, M.Cardboard)
	if collide ~= false then
		body.CanCollide = true
		body.CanQuery = true
	end
	Kit.box(parent, "Tape", cf * CF(0, size.Y + 0.005, 0), V(size.X + 0.01, 0.02, 0.35), Color3.fromRGB(200, 170, 110), M.Plastic)
	Kit.box(parent, "Flap", cf * CF(0, size.Y + 0.004, 0), V(0.03, 0.02, size.Z + 0.01), darker(c, 0.3), M.Cardboard)
	Kit.box(parent, "Label", cf * CF(size.X * 0.15, size.Y * 0.6, -size.Z / 2 - 0.01), V(size.X * 0.35, size.Y * 0.2, 0.02), C.Paper, M.Plastic)
	return body
end

function Kit.paintCan(parent, cf: CFrame, color: Color3)
	Kit.vcyl(parent, "Can", cf * CF(0, 0.5, 0), 1.0, 0.85, C.Steel, M.Metal)
	Kit.vcyl(parent, "CanLabel", cf * CF(0, 0.45, 0), 0.5, 0.87, color, M.Plastic)
	Kit.vcyl(parent, "CanLid", cf * CF(0, 1.02, 0), 0.05, 0.8, C.Chrome, M.Metal)
	Kit.vcyl(parent, "Drip", cf * CF(0, 0.85, 0), 0.25, 0.88, lighter(color, 0.2), M.Plastic)
end

function Kit.trashBin(parent, cf: CFrame, color: Color3)
	-- a wheelie bin, hinge + handle at local +Z
	local m = Kit.model(parent, "TrashBin")
	local body = Kit.solid(m, "TrashBin", cf * CF(0, 1.95, 0), V(2.2, 3.5, 2.3), color, M.Plastic)
	Kit.box(m, "BinTaper", cf * CF(0, 0.2, 0), V(1.9, 0.4, 2.0), color, M.Plastic)
	Kit.soft(m, "BinLid", cf * CF(0, 3.8, -0.03), V(2.35, 0.18, 2.5), 0.08, darker(color, 0.12), M.Plastic)
	Kit.cyl(m, "BinHandle", cf * CF(0, 3.5, 1.3), 1.8, 0.16, darker(color, 0.2), M.Plastic)
	for _, s in { -1, 1 } do
		Kit.cyl(m, "BinWheel", cf * CF(s * 0.9, 0.35, 1.0), 0.3, 0.75, C.Rubber, M.Rubber)
	end
	return m, body
end

function Kit.washer(parent, cf: CFrame, dryer: boolean?)
	local m = Kit.model(parent, dryer and "Dryer" or "Washer")
	local body = Kit.solid(m, dryer and "Dryer" or "Washer", cf * CF(0, 2.05, 0), V(3.6, 4.1, 3.3), C.Porcelain, M.Plastic)
	Kit.box(m, "ControlPanel", cf * CF(0, 3.7, -1.62), V(3.5, 0.6, 0.1), Color3.fromRGB(210, 212, 216), M.Plastic)
	Kit.cyl(m, "Dial", cf * CF(1.1, 3.7, -1.72) * ANG(0, rad(90), 0), 0.14, 0.42, C.Chrome, M.Metal)
	Kit.box(m, "Display", cf * CF(-0.5, 3.7, -1.69), V(0.8, 0.22, 0.02), Color3.fromRGB(40, 160, 200), M.Neon)
	Kit.cyl(m, "DoorRing", cf * CF(0, 1.9, -1.66) * ANG(0, rad(90), 0), 0.1, 2.3, C.Chrome, M.Metal)
	Kit.cyl(m, "DoorGlass", cf * CF(0, 1.9, -1.72) * ANG(0, rad(90), 0), 0.04, 1.8, Color3.fromRGB(40, 50, 60), M.Glass, { Transparency = 0.2 })
	return m, body
end

function Kit.lantern(parent, cf: CFrame)
	local m = Kit.model(parent, "Lantern")
	local metal = Color3.fromRGB(46, 56, 50)
	Kit.vcyl(m, "LanternBase", cf * CF(0, 0.1, 0), 0.2, 0.85, metal, M.Metal)
	local glow = Kit.vcyl(m, "Lantern", cf * CF(0, 0.7, 0), 1.0, 0.6, Color3.fromRGB(255, 214, 140), M.Neon)
	for k = 0, 3 do
		local a = k * math.pi / 2
		Kit.box(m, "Bar", cf * CF(math.cos(a) * 0.36, 0.7, math.sin(a) * 0.36), V(0.06, 1.0, 0.06), metal, M.Metal)
	end
	Kit.lathe(m, "LanternTop", cf * CF(0, 1.2, 0), { { 0, 0.85 }, { 0.2, 0.6 }, { 0.35, 0.2 } }, metal, M.Metal)
	Kit.ring(m, "LanternHandle", cf * CF(0, 1.8, 0) * ANG(rad(90), 0, 0), 0.3, 0.05, 0.05, 8, metal, M.Metal)
	return m, glow
end

function Kit.bottle(parent, cf: CFrame, color: Color3)
	Kit.lathe(parent, "Bottle", cf, { { 0, 0.34 }, { 0.65, 0.34 }, { 0.8, 0.16 }, { 1.05, 0.13 }, { 1.1, 0.15 } }, color, M.Glass, { Transparency = 0.25 })
end

function Kit.sleepingBag(parent, cf: CFrame, color: Color3)
	local m = Kit.model(parent, "SleepingBag")
	Kit.softZ(m, "SleepingBag", cf * CF(0, 0.28, 0), V(2.6, 0.56, 6.4), 0.26, color, M.Fabric)
	Kit.box(m, "Zip", cf * CF(1.25, 0.35, 0), V(0.04, 0.06, 6.2), Color3.fromRGB(30, 30, 30), M.Metal)
	Kit.softZ(m, "FoldedTop", cf * CF(0, 0.6, -1.2), V(2.5, 0.2, 2.4), 0.09, lighter(color, 0.15), M.Fabric)
	Kit.soft(m, "Pillow", cf * CF(0, 0.7, 2.6), V(1.9, 0.45, 1.1), 0.2, Color3.fromRGB(150, 140, 120), M.Fabric)
	return m
end

function Kit.guitar(parent, cf: CFrame)
	-- leaning against a wall (local +Z); cf = floor point under the body
	local m = Kit.model(parent, "Guitar")
	local g = cf * ANG(rad(-12), 0, 0)
	local wood = Color3.fromRGB(170, 96, 44)
	Kit.ellipsoid(m, "GuitarBody", g * CF(0, 1.05, 0), V(1.7, 1.9, 0.45), wood, M.Wood)
	Kit.ellipsoid(m, "GuitarWaist", g * CF(0, 2.2, 0), V(1.3, 1.35, 0.43), wood, M.Wood)
	Kit.cyl(m, "SoundHole", g * CF(0, 1.9, -0.22) * ANG(0, rad(90), 0), 0.02, 0.5, Color3.fromRGB(20, 12, 8), M.Plastic)
	Kit.box(m, "Bridge", g * CF(0, 1.2, -0.23), V(0.6, 0.12, 0.04), Color3.fromRGB(40, 24, 16), M.Wood)
	Kit.box(m, "Neck", g * CF(0, 3.6, 0), V(0.28, 2.6, 0.16), Color3.fromRGB(90, 56, 30), M.Wood)
	Kit.box(m, "Headstock", g * CF(0, 5.1, 0.02), V(0.38, 0.6, 0.12), Color3.fromRGB(40, 24, 16), M.Wood)
	for k = -1, 1 do
		Kit.box(m, "String", g * CF(k * 0.06, 3.1, -0.1), V(0.015, 3.9, 0.015), C.Chrome, M.Metal)
	end
	return m
end

function Kit.fishTank(parent, cf: CFrame, w: number, d: number, h: number, standColor: Color3)
	local m = Kit.model(parent, "FishTank")
	local standH = 3.0
	Kit.solid(m, "TankStand", cf * CF(0, standH / 2, 0), V(w, standH, d), standColor, M.Wood)
	Kit.box(m, "StandDoor", cf * CF(0, standH / 2, -d / 2 - 0.03), V(w - 0.3, standH - 0.4, 0.05), lighter(standColor, 0.05), M.Wood)
	local base = cf * CF(0, standH, 0)
	Kit.box(m, "FishTank", base * CF(0, h / 2, 0), V(w - 0.1, h, d - 0.1), Color3.fromRGB(170, 210, 230), M.Glass, { Transparency = 0.55 })
	Kit.box(m, "Water", base * CF(0, h * 0.44, 0), V(w - 0.25, h * 0.82, d - 0.25), Color3.fromRGB(80, 150, 180), M.Glass, { Transparency = 0.6 })
	Kit.box(m, "Gravel", base * CF(0, 0.15, 0), V(w - 0.25, 0.3, d - 0.25), Color3.fromRGB(150, 130, 110), M.Slate)
	Kit.box(m, "TankLid", base * CF(0, h + 0.08, 0), V(w, 0.16, d), C.Black, M.Plastic)
	local rng = Random.new(8)
	for k = 1, 5 do
		Kit.ellipsoid(m, "Weed", base * CF(rng:NextNumber(-w / 2 + 0.4, w / 2 - 0.4), 0.8, rng:NextNumber(-0.3, 0.3)), V(0.15, 1.2, 0.08), Color3.fromRGB(60, 140 + k * 10, 70), M.Plastic)
	end
	local fish = Kit.ellipsoid(m, "Fish", base * CF(0.3, h * 0.55, 0), V(0.45, 0.25, 0.15), Color3.fromRGB(255, 140, 40), M.Neon)
	return m, fish
end

function Kit.dollhouse(parent, cf: CFrame)
	local m = Kit.model(parent, "Dollhouse")
	local wall = Color3.fromRGB(250, 222, 230)
	local roof = Color3.fromRGB(200, 90, 110)
	Kit.solid(m, "Dollhouse", cf * CF(0, 1.4, 0), V(4, 2.8, 2.2), wall, M.Wood)
	Kit.box(m, "Floor2", cf * CF(0, 1.45, -1.12), V(3.9, 0.1, 0.04), darker(wall, 0.2), M.Wood)
	for k = 0, 1 do
		-- each half rises toward the ridge in the middle
		Kit.wedge(m, "DollRoof", cf * CF(0, 3.35, k == 0 and -0.55 or 0.55) * ANG(0, k == 0 and 0 or math.pi, 0), V(4.3, 1.1, 1.15), roof, M.Wood)
	end
	Kit.box(m, "Chimney", cf * CF(1.2, 3.7, 0.4), V(0.35, 0.8, 0.35), Color3.fromRGB(170, 70, 60), M.Brick)
	for r = 0, 1 do
		for c = -1, 1 do
			if not (r == 0 and c == 0) then
				Kit.box(m, "DollWindow", cf * CF(c * 1.2, 0.75 + r * 1.35, -1.11), V(0.6, 0.6, 0.02), Color3.fromRGB(255, 232, 170), M.Plastic)
			end
		end
	end
	Kit.box(m, "DollDoor", cf * CF(0, 0.5, -1.11), V(0.55, 0.9, 0.02), Color3.fromRGB(120, 70, 60), M.Wood)
	return m
end

function Kit.grandfatherClock(parent, cf: CFrame, color: Color3)
	local m = Kit.model(parent, "GrandfatherClock")
	local dark = darker(color, 0.15)
	Kit.solid(m, "ClockPlinth", cf * CF(0, 1.0, 0), V(2.1, 2.0, 1.7), color, M.Wood)
	Kit.box(m, "ClockPlinthTrim", cf * CF(0, 2.05, -0.03), V(2.25, 0.15, 1.8), dark, M.Wood)
	Kit.solid(m, "ClockCase", cf * CF(0, 4.6, 0.05), V(1.7, 5.0, 1.5), color, M.Wood)
	Kit.box(m, "ClockGlass", cf * CF(0, 4.3, -0.72), V(1.1, 3.8, 0.04), Color3.fromRGB(40, 36, 30), M.Glass, { Transparency = 0.5 })
	Kit.box(m, "ClockDoorFrame", cf * CF(0, 4.3, -0.7), V(1.35, 4.05, 0.04), dark, M.Wood)
	Kit.solid(m, "ClockHood", cf * CF(0, 8.1, 0), V(2.0, 2.0, 1.7), color, M.Wood)
	Kit.cyl(m, "ClockArch", cf * CF(0, 9.1, 0) * ANG(0, rad(90), 0), 1.7, 2.0, color, M.Wood)
	Kit.box(m, "ClockCornice", cf * CF(0, 7.1, -0.02), V(2.2, 0.16, 1.85), dark, M.Wood)
	local face = cf * CF(0, 8.3, -0.86)
	local faceP = Kit.cyl(m, "ClockFace", face * ANG(0, rad(90), 0), 0.04, 1.45, C.Cream, M.Plastic)
	Kit.cyl(m, "ClockBezel", face * CF(0, 0, 0.02) * ANG(0, rad(90), 0), 0.03, 1.6, C.Brass, M.Metal)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		Kit.box(m, "Tick", face * CF(math.sin(a) * 0.58, math.cos(a) * 0.58, -0.03) * ANG(0, 0, -a), V(0.04, 0.14, 0.02), C.Black, M.Plastic)
	end
	Kit.box(m, "HourHand", face * CF(0.12, 0.12, -0.04) * ANG(0, 0, rad(-45)), V(0.05, 0.4, 0.02), C.Black, M.Metal)
	Kit.box(m, "MinuteHand", face * CF(0, 0.26, -0.05), V(0.04, 0.55, 0.02), C.Black, M.Metal)
	return m, faceP
end

-- a stone fireplace against a wall; cf = floor centre of the hearth's back edge (the wall), facing into the room
function Kit.fireplace(parent, cf: CFrame, ceilingH: number)
	local m = Kit.model(parent, "Fireplace")
	local stone = Color3.fromRGB(150, 140, 128)
	local sooty = Color3.fromRGB(28, 24, 22)
	-- depth into the room is local -Z
	Kit.solid(m, "Hearth", cf * CF(0, 0.25, -2.1), V(10.4, 0.5, 4.2), Color3.fromRGB(128, 120, 110), M.Slate)
	for _, s in { -1, 1 } do
		Kit.solid(m, "Surround", cf * CF(s * 3.8, 4, -1.05), V(2.4, 8, 2.1), stone, M.Cobble)
	end
	Kit.solid(m, "Surround", cf * CF(0, 7, -1.05), V(5.2, 2, 2.1), stone, M.Cobble)
	Kit.box(m, "Firebox", cf * CF(0, 3.25, -0.15), V(5.2, 5.5, 0.3), sooty, M.Brick)
	for _, s in { -1, 1 } do
		Kit.box(m, "FireboxSide", cf * CF(s * 2.5, 3.25, -1.05), V(0.2, 5.5, 1.8), sooty, M.Brick)
	end
	Kit.box(m, "FireboxTop", cf * CF(0, 5.9, -1.05), V(5.2, 0.2, 1.8), sooty, M.Brick)
	Kit.box(m, "Ash", cf * CF(0, 0.55, -1.0), V(4.6, 0.1, 1.6), Color3.fromRGB(70, 66, 62), M.Concrete)
	-- mantel on corbels
	Kit.soft(m, "Mantel", cf * CF(0, 8.3, -1.35), V(11.2, 0.6, 2.7), 0.12, C.WoodDark, M.Wood)
	for _, s in { -1, 1 } do
		Kit.box(m, "Corbel", cf * CF(s * 4.4, 7.6, -2.25), V(0.5, 0.8, 0.6), C.WoodDark, M.Wood)
	end
	Kit.solid(m, "Chimneybreast", cf * CF(0, 8.6 + (ceilingH - 8.6) / 2, -0.6), V(8.8, ceilingH - 8.6, 1.2), Color3.fromRGB(168, 158, 144), M.Cobble)
	-- iron grate
	local IRON = Color3.fromRGB(30, 28, 28)
	for _, z in { -0.55, -1.4 } do
		Kit.box(m, "GrateBar", cf * CF(0, 1.02, z), V(3.6, 0.15, 0.16), IRON, M.Metal)
	end
	for k = 0, 4 do
		Kit.box(m, "GrateRib", cf * CF(-1.6 + k * 0.8, 1.15, -0.97), V(0.14, 0.4, 1.05), IRON, M.Metal)
	end
	for _, x in { -1.7, 1.7 } do
		for _, z in { -0.55, -1.4 } do
			Kit.box(m, "GrateLeg", cf * CF(x, 0.72, z), V(0.2, 0.45, 0.2), IRON, M.Metal)
		end
		Kit.box(m, "Firedog", cf * CF(x, 1.4, -1.5), V(0.24, 0.95, 0.2), IRON, M.Metal)
		Kit.ball(m, "FiredogTop", (cf * CF(x, 1.95, -1.5)).Position, 0.3, C.Brass, M.Metal)
	end
	-- a folding screen in front
	for k = -1, 1 do
		Kit.box(m, "FireScreen", cf * CF(k * 1.55, 2.2, -2.35 + math.abs(k) * 0.25) * ANG(0, rad(k * 18), 0), V(1.6, 3.4, 0.06), C.Black, M.Metal, { Transparency = 0.45 })
		Kit.box(m, "ScreenFrame", cf * CF(k * 1.55, 3.9, -2.35 + math.abs(k) * 0.25) * ANG(0, rad(k * 18), 0), V(1.6, 0.1, 0.1), C.Brass, M.Metal)
	end
	return m, cf * CF(0, 0, -1.0) -- where the logs and the fire go
end

---------------------------------------------------------------------------
-- Vehicles
---------------------------------------------------------------------------
local function wheel(m, cf: CFrame, d: number, w: number, rim: Color3)
	-- cf's local X is the axle, pointing outward
	Kit.cyl(m, "Tire", cf, w, d, C.Rubber, M.Rubber)
	Kit.cyl(m, "Rim", cf * CF(w / 2 - 0.02, 0, 0), 0.06, d * 0.62, rim, M.Metal)
	Kit.cyl(m, "Hub", cf * CF(w / 2 + 0.02, 0, 0), 0.05, d * 0.22, darker(rim, 0.3), M.Metal)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		Kit.box(m, "Spoke", cf * CF(w / 2 + 0.01, math.cos(a) * d * 0.17, math.sin(a) * d * 0.17) * ANG(a, 0, 0), V(0.04, d * 0.22, 0.12), rim, M.Metal)
	end
end

-- a sedan; front is local -Z. Returns model, body (PrimaryPart) and the driver's door.
function Kit.sedan(parent, cf: CFrame, color: Color3)
	local m = Kit.model(parent, "Sedan")
	local L, W = 15, 6.6
	local paint = color
	local trim = Color3.fromRGB(26, 26, 28)
	local glass = Color3.fromRGB(34, 40, 48)
	local body = Kit.softZ(m, "Body", cf * CF(0, 2.05, 0), V(W, 1.7, L), 0.5, paint, M.Metal)
	body.CanCollide = true
	body.CanQuery = true
	Kit.softZ(m, "Sill", cf * CF(0, 1.25, 0), V(W - 0.2, 0.4, L - 2.4), 0.15, trim, M.Plastic)
	-- hood and trunk decks
	Kit.soft(m, "Hood", cf * CF(0, 2.95, -L / 2 + 2.3) * ANG(rad(-5), 0, 0), V(W - 0.3, 0.3, 4.4), 0.12, paint, M.Metal)
	Kit.soft(m, "Trunk", cf * CF(0, 3.0, L / 2 - 1.5), V(W - 0.3, 0.3, 2.8), 0.12, paint, M.Metal)
	-- cabin: glasshouse with sloped windscreens
	Kit.soft(m, "Roof", cf * CF(0, 4.75, 0.6), V(W - 1.1, 0.25, 4.2), 0.1, paint, M.Metal)
	-- windscreen rises from the hood to the roof; the rear window falls to the trunk
	Kit.wedge(m, "Windshield", cf * CF(0, 3.9, -2.4), V(W - 1.2, 1.6, 2.1), glass, M.Glass, { Reflectance = 0.15 })
	Kit.wedge(m, "RearWindow", cf * CF(0, 3.9, 3.5) * ANG(0, math.pi, 0), V(W - 1.2, 1.6, 1.6), glass, M.Glass, { Reflectance = 0.15 })
	Kit.box(m, "Cabin", cf * CF(0, 3.9, 0.55), V(W - 1.3, 1.6, 4.0), glass, M.Glass, { Reflectance = 0.1 })
	for _, s in { -1, 1 } do
		Kit.box(m, "BPillar", cf * CF(s * (W / 2 - 0.62), 3.9, 0.4), V(0.1, 1.6, 0.35), trim, M.Plastic)
		Kit.box(m, "DoorLine", cf * CF(s * (W / 2 + 0.01), 2.1, 0.4), V(0.02, 1.5, 0.05), darker(paint, 0.45), M.Metal)
		Kit.box(m, "DoorLine", cf * CF(s * (W / 2 + 0.01), 2.1, -2.2), V(0.02, 1.5, 0.05), darker(paint, 0.45), M.Metal)
		for _, z in { -1.4, 1.4 } do
			Kit.box(m, "DoorHandle", cf * CF(s * (W / 2 + 0.03), 2.55, z), V(0.06, 0.12, 0.55), Color3.fromRGB(190, 190, 195), M.Metal)
		end
		Kit.ellipsoid(m, "Mirror", cf * CF(s * (W / 2 + 0.25), 3.3, -2.2), V(0.5, 0.35, 0.3), paint, M.Metal)
		-- wheel arches and wheels
		for _, z in { -L / 2 + 2.9, L / 2 - 2.7 } do
			Kit.cyl(m, "WheelArch", cf * CF(s * (W / 2 - 0.2), 1.35, z), 0.45, 3.0, trim, M.Plastic)
			wheel(m, cf * CF(s * (W / 2 - 0.35), 1.15, z) * ANG(0, s > 0 and 0 or math.pi, 0), 2.3, 0.9, Color3.fromRGB(190, 192, 196))
		end
	end
	-- lights, grille, bumpers, plates
	for _, s in { -1, 1 } do
		Kit.ellipsoid(m, "Headlight", cf * CF(s * (W / 2 - 1.1), 2.45, -L / 2 + 0.05), V(1.4, 0.45, 0.25), Color3.fromRGB(230, 230, 215), M.Glass)
		Kit.box(m, "Taillight", cf * CF(s * (W / 2 - 1.0), 2.6, L / 2 - 0.02), V(1.5, 0.4, 0.1), Color3.fromRGB(150, 24, 24), M.Glass)
	end
	Kit.box(m, "Grille", cf * CF(0, 2.2, -L / 2 - 0.02), V(2.6, 0.55, 0.08), trim, M.Plastic)
	Kit.box(m, "GrilleBar", cf * CF(0, 2.25, -L / 2 - 0.07), V(2.6, 0.08, 0.04), Color3.fromRGB(190, 190, 195), M.Metal)
	for _, e in { -1, 1 } do
		Kit.soft(m, "Bumper", cf * CF(0, 1.45, e * (L / 2 + 0.05)), V(W - 0.1, 0.55, 0.45), 0.18, trim, M.Plastic)
		Kit.box(m, "Plate", cf * CF(0, 1.55, e * (L / 2 + 0.3)), V(1.3, 0.55, 0.03), Color3.fromRGB(236, 236, 230), M.Plastic)
	end
	local driverDoor = Kit.box(m, "DriverDoor", cf * CF(-(W / 2 + 0.05), 2.4, -0.9), V(0.1, 2.0, 2.6), paint, M.Metal, { Transparency = 1, CanQuery = true })
	-- an invisible root, oriented like the car, so PivotTo moves it along its own axes
	local rootPart = Kit.box(m, "CarRoot", cf * CF(0, 2, 0), V(1, 1, 1), paint, M.Plastic, { Transparency = 1 })
	m.PrimaryPart = rootPart
	return m, body, driverDoor
end

-- a panel van; front is local -Z
function Kit.van(parent, cf: CFrame, color: Color3)
	local m = Kit.model(parent, "Van")
	local L, W = 17, 7
	local trim = Color3.fromRGB(34, 34, 36)
	local glass = Color3.fromRGB(30, 35, 40)
	local body = Kit.softZ(m, "VanBody", cf * CF(0, 4.6, 2.15), V(W, 6.6, 12.7), 0.45, color, M.Metal)
	body.CanCollide = true
	body.CanQuery = true
	Kit.soft(m, "VanNose", cf * CF(0, 2.9, -6.35), V(W - 0.1, 3.2, 4.3), 0.4, color, M.Metal)
	Kit.wedge(m, "VanWindshield", cf * CF(0, 5.9, -5.1), V(W - 0.5, 2.8, 1.8), glass, M.Glass, { Reflectance = 0.15 })
	for _, s in { -1, 1 } do
		Kit.box(m, "CabWindow", cf * CF(s * (W / 2 + 0.01), 5.7, -3.0), V(0.02, 1.8, 2.0), glass, M.Glass)
		Kit.box(m, "SlideTrack", cf * CF(s * (W / 2 + 0.01), 6.8, 1.0), V(0.03, 0.1, 6), trim, M.Metal)
		Kit.box(m, "DoorSeam", cf * CF(s * (W / 2 + 0.01), 4.2, -0.8), V(0.02, 5.2, 0.05), darker(color, 0.4), M.Metal)
		Kit.ellipsoid(m, "Mirror", cf * CF(s * (W / 2 + 0.35), 5.4, -L / 2 + 3.6), V(0.4, 0.7, 0.3), trim, M.Plastic)
		Kit.box(m, "RustStreak", cf * CF(s * (W / 2 + 0.01), 3.0, 4.5), V(0.02, 1.4, 0.3), Color3.fromRGB(110, 70, 45), M.Metal)
		for _, z in { -L / 2 + 3.0, L / 2 - 3.0 } do
			Kit.cyl(m, "WheelArch", cf * CF(s * (W / 2 - 0.2), 1.5, z), 0.45, 3.3, trim, M.Plastic)
			wheel(m, cf * CF(s * (W / 2 - 0.35), 1.3, z) * ANG(0, s > 0 and 0 or math.pi, 0), 2.6, 1.0, Color3.fromRGB(150, 152, 156))
		end
		Kit.ellipsoid(m, "Headlight", cf * CF(s * (W / 2 - 1.0), 3.3, -L / 2 + 0.05), V(1.1, 0.6, 0.2), Color3.fromRGB(210, 210, 195), M.Glass)
		Kit.box(m, "Taillight", cf * CF(s * (W / 2 - 0.35), 3.5, L / 2 + 0.02), V(0.5, 1.4, 0.08), Color3.fromRGB(130, 22, 22), M.Glass)
	end
	Kit.box(m, "Grille", cf * CF(0, 2.9, -L / 2 - 0.02), V(3.2, 1.0, 0.08), trim, M.Plastic)
	Kit.box(m, "RearDoorSeam", cf * CF(0, 4.6, L / 2 + 0.02), V(0.05, 5.8, 0.02), darker(color, 0.4), M.Metal)
	for _, e in { -1, 1 } do
		Kit.soft(m, "Bumper", cf * CF(0, 1.5, e * (L / 2 + 0.1)), V(W, 0.6, 0.5), 0.2, trim, M.Plastic)
	end
	Kit.box(m, "Plate", cf * CF(0, 2.1, L / 2 + 0.06), V(1.3, 0.55, 0.03), Color3.fromRGB(236, 236, 230), M.Plastic)
	local rootPart = Kit.box(m, "VanRoot", cf * CF(0, 2, 0), V(1, 1, 1), color, M.Plastic, { Transparency = 1 })
	m.PrimaryPart = rootPart
	return m, body
end

---------------------------------------------------------------------------
-- Outdoors
---------------------------------------------------------------------------
local LEAF = { Color3.fromRGB(46, 70, 38), Color3.fromRGB(56, 82, 44), Color3.fromRGB(40, 62, 36), Color3.fromRGB(64, 88, 48) }

-- a broad-leaved tree: flared trunk, a few limbs, a crown of overlapping leaf masses
function Kit.tree(parent, pos: Vector3, height: number, seed: number?)
	local m = Kit.model(parent, "Tree")
	local rng = Random.new(seed or math.floor(pos.X * 13 + pos.Z * 7))
	local bark = Color3.fromRGB(62 + rng:NextInteger(0, 12), 48, 36)
	local trunkH = height * 0.5
	local base = CF(pos) * ANG(0, rng:NextNumber(0, 6.28), 0)
	local trunkD = height * 0.075
	Kit.lathe(m, "Trunk", base, { { 0, trunkD * 1.6 }, { 0.6, trunkD * 1.1 }, { trunkH * 0.5, trunkD }, { trunkH, trunkD * 0.8 } }, bark, M.Wood)
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		Kit.box(m, "Root", base * ANG(0, a, 0) * CF(0, 0.25, -trunkD * 0.8) * ANG(rad(-20), 0, 0), V(trunkD * 0.35, 0.5, trunkD * 0.9), bark, M.Wood)
	end
	local crownC = base * CF(0, trunkH + height * 0.22, 0)
	local limbs = rng:NextInteger(3, 5)
	for k = 1, limbs do
		local a = k / limbs * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
		local len = height * rng:NextNumber(0.28, 0.4)
		local limb = base * CF(0, trunkH * rng:NextNumber(0.8, 1.0), 0) * ANG(0, a, 0) * ANG(-rng:NextNumber(0.5, 0.9), 0, 0)
		Kit.taper(m, "Limb", limb, len, trunkD * 0.55, trunkD * 0.25, 2, bark, M.Wood)
		local tip = (limb * CF(0, len, 0)).Position
		Kit.ellipsoid(m, "Leaves", CF(tip) * ANG(0, rng:NextNumber(0, 6), 0), V(1, 0.75, 1) * height * rng:NextNumber(0.3, 0.42), LEAF[rng:NextInteger(1, #LEAF)], M.Leafy)
	end
	for _ = 1, 7 do
		local off = V(rng:NextNumber(-1, 1), rng:NextNumber(-0.4, 0.7), rng:NextNumber(-1, 1)) * height * 0.22
		Kit.ellipsoid(m, "Leaves", crownC * CF(off) * ANG(0, rng:NextNumber(0, 6), 0), V(1, 0.72, 1) * height * rng:NextNumber(0.28, 0.4), LEAF[rng:NextInteger(1, #LEAF)], M.Leafy)
	end
	Kit.collider(m, CF(pos + V(0, trunkH / 2, 0)), V(trunkD * 1.3, trunkH, trunkD * 1.3))
	return m
end

-- a conifer: straight trunk, stacked tiers of eight-sided cones
function Kit.pine(parent, pos: Vector3, height: number, seed: number?)
	local m = Kit.model(parent, "Pine")
	local rng = Random.new(seed or math.floor(pos.X * 11 + pos.Z * 5))
	local bark = Color3.fromRGB(70, 50, 36)
	local base = CF(pos) * ANG(0, rng:NextNumber(0, 6.28), 0)
	Kit.taper(m, "Trunk", base, height * 0.3, height * 0.07, height * 0.05, 2, bark, M.Wood)
	-- four tiers of cones, each one's skirt overlapping the tier below
	local tiers = { { 0.14, 0.27, 0.42 }, { 0.34, 0.22, 0.36 }, { 0.54, 0.16, 0.3 }, { 0.72, 0.1, 0.28 } }
	for i, t in tiers do
		local col = Color3.fromRGB(30 + i * 4, 58 + i * 5 + rng:NextInteger(0, 8), 38)
		Kit.cone(m, "Needles", base * CF(0, height * t[1], 0) * ANG(0, i * 0.35, 0), height * t[3], height * t[2], 10, col, M.Leafy)
	end
	Kit.collider(m, CF(pos + V(0, height * 0.2, 0)), V(height * 0.08, height * 0.4, height * 0.08))
	return m
end

function Kit.shrub(parent, cf: CFrame, size: number, seed: number?)
	local m = Kit.model(parent, "Shrub")
	local rng = Random.new(seed or math.floor(cf.Position.X * 5 + cf.Position.Z * 9))
	-- a low, wide base clump so the bush sits on the ground, then smaller clumps piled on top
	Kit.ellipsoid(m, "Shrub", cf * CF(0, size * 0.28, 0), V(1.1, 0.62, 1.1) * size, LEAF[rng:NextInteger(1, #LEAF)], M.Leafy)
	for _ = 1, 5 do
		local off = V(rng:NextNumber(-0.45, 0.45), rng:NextNumber(0.4, 0.72), rng:NextNumber(-0.45, 0.45)) * size
		Kit.ellipsoid(m, "Shrub", cf * CF(off), V(1, 0.8, 1) * size * rng:NextNumber(0.6, 0.85), LEAF[rng:NextInteger(1, #LEAF)], M.Leafy)
	end
	Kit.collider(m, cf * CF(0, size * 0.5, 0), V(size, size, size) * 0.8)
	return m
end

-- a clipped hedge along local X
function Kit.hedge(parent, cf: CFrame, length: number, h: number, d: number)
	local m = Kit.model(parent, "Hedge")
	local green = Color3.fromRGB(42, 64, 36)
	Kit.soft(m, "Hedge", cf * CF(0, h / 2, 0), V(length, h, d), math.min(0.7, d / 2 - 0.05), green, M.Leafy)
	local rng = Random.new(math.floor(cf.Position.X * 3 + cf.Position.Z))
	for x = -length / 2 + 0.8, length / 2 - 0.8, 1.6 do
		Kit.ellipsoid(m, "Tuft", cf * CF(x + rng:NextNumber(-0.3, 0.3), h - 0.1, rng:NextNumber(-0.2, 0.2)), V(1.8, 0.8, d * 0.8), LEAF[rng:NextInteger(1, #LEAF)], M.Leafy)
	end
	Kit.collider(m, cf * CF(0, h / 2, 0), V(length, h, d))
	return m
end

-- a white picket fence from a to b (ground level)
function Kit.picketFence(parent, a: Vector3, b: Vector3, h: number, color: Color3?)
	local m = Kit.model(parent, "Fence")
	local c = color or Color3.fromRGB(232, 230, 222)
	local span = b - a
	local len = span.Magnitude
	local cf = CFrame.lookAt(a, b) -- local -Z runs along the fence
	for d = 0, len, 6 do
		Kit.box(m, "FencePost", cf * CF(0, h / 2 + 0.2, -d), V(0.45, h + 0.4, 0.45), c, M.Wood)
		Kit.box(m, "PostCap", cf * CF(0, h + 0.45, -d), V(0.6, 0.12, 0.6), c, M.Wood)
	end
	for _, y in { h * 0.3, h * 0.78 } do
		Kit.box(m, "FenceRail", cf * CF(0.25, y, -len / 2), V(0.12, 0.3, len), c, M.Wood)
	end
	for d = 0.3, len - 0.2, 0.7 do
		Kit.box(m, "Picket", cf * CF(0.36, h / 2, -d), V(0.08, h - 0.2, 0.4), c, M.Wood)
		Kit.wedge(m, "PicketTip", cf * CF(0.36, h - 0.05, -d - 0.1) * ANG(0, math.pi / 2, 0), V(0.2, 0.3, 0.08), c, M.Wood)
		Kit.wedge(m, "PicketTip", cf * CF(0.36, h - 0.05, -d + 0.1) * ANG(0, -math.pi / 2, 0), V(0.2, 0.3, 0.08), c, M.Wood)
	end
	Kit.collider(m, cf * CF(0.2, h / 2, -len / 2), V(0.5, h, len))
	return m
end

-- a board fence (privacy) from a to b
function Kit.boardFence(parent, a: Vector3, b: Vector3, h: number, color: Color3?)
	local m = Kit.model(parent, "BoardFence")
	local c = color or Color3.fromRGB(116, 96, 74)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt(a, b)
	Kit.box(m, "Boards", cf * CF(0, h / 2, -len / 2), V(0.2, h, len), c, M.Planks)
	for d = 0, len, 8 do
		Kit.box(m, "FencePost", cf * CF(0.25, h / 2 + 0.15, -d), V(0.5, h + 0.3, 0.5), darker(c, 0.15), M.Wood)
	end
	for _, y in { h * 0.2, h * 0.85 } do
		Kit.box(m, "FenceRail", cf * CF(0.2, y, -len / 2), V(0.16, 0.35, len), darker(c, 0.1), M.Wood)
	end
	Kit.box(m, "FenceCap", cf * CF(0, h + 0.05, -len / 2), V(0.4, 0.1, len), darker(c, 0.2), M.Wood)
	Kit.collider(m, cf * CF(0, h / 2, -len / 2), V(0.6, h, len))
	return m
end

function Kit.mailbox(parent, cf: CFrame, color: Color3?)
	local m = Kit.model(parent, "Mailbox")
	local c = color or Color3.fromRGB(30, 34, 40)
	Kit.box(m, "MailPost", cf * CF(0, 2.0, 0), V(0.4, 4.0, 0.4), Color3.fromRGB(236, 232, 224), M.Wood)
	Kit.box(m, "MailArm", cf * CF(0, 3.9, -0.4), V(0.35, 0.25, 1.4), Color3.fromRGB(236, 232, 224), M.Wood)
	Kit.box(m, "MailBody", cf * CF(0, 4.3, -0.4), V(1.1, 0.6, 1.9), c, M.Metal)
	Kit.cyl(m, "MailTop", cf * CF(0, 4.6, -0.4) * ANG(0, rad(90), 0), 1.9, 1.1, c, M.Metal)
	Kit.box(m, "MailFlag", cf * CF(0.6, 4.7, -0.1), V(0.06, 0.8, 0.12), Color3.fromRGB(190, 30, 30), M.Metal)
	Kit.box(m, "FlagTip", cf * CF(0.6, 5.0, -0.25), V(0.06, 0.3, 0.35), Color3.fromRGB(190, 30, 30), M.Metal)
	Kit.box(m, "Number", cf * CF(0.56, 4.25, -0.4), V(0.02, 0.3, 0.9), Color3.fromRGB(230, 200, 120), M.Metal)
	Kit.collider(m, cf * CF(0, 2.4, -0.3), V(1.1, 4.8, 1.9))
	return m
end

-- a cast-iron street lamp; returns the glowing head for a light
function Kit.streetLamp(parent, cf: CFrame, height: number?)
	local m = Kit.model(parent, "StreetLamp")
	local h = height or 16
	local iron = Color3.fromRGB(34, 38, 40)
	Kit.lathe(m, "LampBase", cf, { { 0, 1.4 }, { 0.5, 1.3 }, { 0.8, 0.9 }, { 2.2, 0.7 }, { 2.5, 0.55 } }, iron, M.Metal)
	Kit.taper(m, "LampPole", cf * CF(0, 2.5, 0), h - 2.5, 0.5, 0.32, 3, iron, M.Metal)
	Kit.ring(m, "PoleCollar", cf * CF(0, h * 0.55, 0), 0.25, 0.1, 0.25, 8, iron, M.Metal)
	-- lantern head
	local top = cf * CF(0, h, 0)
	Kit.lathe(m, "LanternBase", top, { { 0, 0.5 }, { 0.3, 1.1 } }, iron, M.Metal)
	local head = Kit.taper(m, "LampHead", top * CF(0, 0.3, 0), 1.6, 1.0, 1.5, 3, Color3.fromRGB(255, 226, 170), M.Neon) :: BasePart
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		Kit.box(m, "LanternBar", top * CF(math.cos(a) * 0.6, 1.1, math.sin(a) * 0.6), V(0.08, 1.6, 0.08), iron, M.Metal)
	end
	Kit.cone(m, "LanternCap", top * CF(0, 1.9, 0), 0.9, 1.1, 8, iron, M.Metal)
	Kit.ball(m, "Finial", (top * CF(0, 2.9, 0)).Position, 0.3, iron, M.Metal)
	Kit.collider(m, cf * CF(0, h / 2, 0), V(0.8, h, 0.8))
	return m, head
end

-- a wall-mounted porch lantern; cf = on the wall, facing out. Returns the glass.
function Kit.wallLantern(parent, cf: CFrame)
	local m = Kit.model(parent, "WallLantern")
	local iron = Color3.fromRGB(30, 32, 34)
	Kit.box(m, "Backplate", cf * CF(0, 0, 0.05), V(0.5, 1.2, 0.1), iron, M.Metal)
	Kit.box(m, "Arm", cf * CF(0, 0.1, -0.35), V(0.12, 0.12, 0.6), iron, M.Metal)
	local lamp = cf * CF(0, -0.2, -0.75)
	local glow = Kit.box(m, "PorchLamp", lamp, V(0.6, 0.9, 0.6), Color3.fromRGB(255, 226, 170), M.Neon)
	Kit.box(m, "LampFrame", lamp * CF(0, 0.5, 0), V(0.8, 0.1, 0.8), iron, M.Metal)
	Kit.box(m, "LampBottom", lamp * CF(0, -0.5, 0), V(0.7, 0.1, 0.7), iron, M.Metal)
	Kit.cone(m, "LampCap", lamp * CF(0, 0.55, 0), 0.45, 0.55, 4, iron, M.Metal)
	return m, glow
end

function Kit.hydrant(parent, cf: CFrame)
	local m = Kit.model(parent, "Hydrant")
	local red = Color3.fromRGB(170, 34, 30)
	Kit.lathe(m, "Hydrant", cf, { { 0, 1.0 }, { 0.2, 1.0 }, { 0.3, 0.75 }, { 2.0, 0.7 }, { 2.1, 0.9 }, { 2.3, 0.6 }, { 2.7, 0.35 } }, red, M.Metal)
	for _, s in { -1, 1 } do
		Kit.cyl(m, "Nozzle", cf * CF(s * 0.45, 1.5, 0), 0.35, 0.35, red, M.Metal)
	end
	Kit.collider(m, cf * CF(0, 1.3, 0), V(0.9, 2.6, 0.9))
	return m
end

function Kit.woodpile(parent, cf: CFrame, rows: number)
	local m = Kit.model(parent, "Woodpile")
	local rng = Random.new(21)
	for row = 0, rows - 1 do
		for k = 0, 3 - math.floor(row / 2) do
			local c = Color3.fromRGB(110 + rng:NextInteger(-15, 15), 76 + rng:NextInteger(-10, 10), 48)
			local z = -1.3 + k * 0.85 + (row % 2) * 0.42
			local log = cf * CF(0, 0.42 + row * 0.78, z)
			Kit.cyl(m, "Log", log, 3.2, 0.8, c, M.Wood)
			for _, e in { -1, 1 } do
				Kit.cyl(m, "LogEnd", log * CF(e * 1.61, 0, 0), 0.03, 0.66, Color3.fromRGB(196, 160, 112), M.Wood)
			end
		end
	end
	return m
end

function Kit.shelving(parent, cf: CFrame, w: number, d: number, h: number, levels: number, seed: number?)
	-- metal utility shelving with boxes and cans
	local m = Kit.model(parent, "Shelving")
	local steel = Color3.fromRGB(120, 122, 126)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Kit.box(m, "Upright", cf * CF(sx * (w / 2 - 0.1), h / 2, sz * (d / 2 - 0.1)), V(0.16, h, 0.16), steel, M.Metal)
		end
	end
	local rng = Random.new(seed or 4)
	for i = 0, levels - 1 do
		local y = 0.4 + i * (h - 0.6) / (levels - 1)
		Kit.box(m, "ShelfDeck", cf * CF(0, y, 0), V(w, 0.1, d), steel, M.Metal)
		if i < levels - 1 then
			local x = -w / 2 + 0.3
			while x < w / 2 - 1.2 do
				if rng:NextNumber() < 0.5 then
					local s = V(rng:NextNumber(1.0, 1.6), rng:NextNumber(0.8, 1.3), d - 0.3)
					Kit.cardboardBox(m, cf * CF(x + s.X / 2, y + 0.05, 0), s, nil, false)
					x += s.X + 0.15
				else
					Kit.paintCan(m, cf * CF(x + 0.45, y + 0.05, 0), Color3.fromHSV(rng:NextNumber(), 0.6, 0.7))
					x += 1.0
				end
			end
		end
	end
	Kit.collider(m, cf * CF(0, h / 2, 0), V(w, h, d))
	return m
end

function Kit.tool(parent, cf: CFrame, kind: string)
	-- hanging on a pegboard; cf = on the board, facing out
	local handle = Color3.fromRGB(170, 60, 40)
	local steel = Color3.fromRGB(150, 152, 156)
	if kind == "hammer" then
		Kit.box(parent, "HammerHandle", cf * CF(0, -0.5, -0.1), V(0.14, 1.3, 0.1), Color3.fromRGB(150, 110, 70), M.Wood)
		Kit.box(parent, "HammerHead", cf * CF(0, 0.2, -0.1), V(0.7, 0.2, 0.16), steel, M.Metal)
	elseif kind == "wrench" then
		Kit.box(parent, "WrenchShaft", cf * CF(0, 0, -0.08), V(0.14, 1.4, 0.05), steel, M.Metal)
		Kit.cyl(parent, "WrenchEnd", cf * CF(0, 0.75, -0.08) * ANG(0, rad(90), 0), 0.06, 0.4, steel, M.Metal)
		Kit.cyl(parent, "WrenchEnd", cf * CF(0, -0.75, -0.08) * ANG(0, rad(90), 0), 0.06, 0.34, steel, M.Metal)
	elseif kind == "saw" then
		Kit.wedge(parent, "SawBlade", cf * CF(0, 0, -0.06) * ANG(0, 0, rad(90)), V(0.03, 1.8, 0.6), steel, M.Metal)
		Kit.soft(parent, "SawHandle", cf * CF(0, 1.05, -0.08), V(0.5, 0.4, 0.12), 0.05, handle, M.Plastic)
	else
		Kit.box(parent, "Screwdriver", cf * CF(0, -0.3, -0.08), V(0.05, 0.8, 0.05), steel, M.Metal)
		Kit.soft(parent, "ScrewdriverGrip", cf * CF(0, 0.3, -0.08), V(0.18, 0.5, 0.18), 0.07, Color3.fromRGB(230, 190, 40), M.Plastic)
	end
end

---------------------------------------------------------------------------
-- More furniture
---------------------------------------------------------------------------
function Kit.mediaConsole(parent, cf: CFrame, w: number, d: number, h: number, color: Color3)
	local m = Kit.model(parent, "MediaConsole")
	local dark = darker(color, 0.15)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Kit.taper(m, "Leg", cf * CF(sx * (w / 2 - 0.35), 0, sz * (d / 2 - 0.3)), 0.5, 0.18, 0.26, 2, dark, M.Wood)
		end
	end
	Kit.box(m, "ConsoleBody", cf * CF(0, 0.5 + (h - 0.62) / 2, 0), V(w, h - 0.62, d), color, M.Wood)
	Kit.soft(m, "ConsoleTop", cf * CF(0, h - 0.06, 0), V(w + 0.1, 0.12, d + 0.06), 0.05, color, M.Wood)
	local third = w / 3
	for _, s in { -1, 1 } do
		local x = s * third
		Kit.box(m, "ConsoleDoor", cf * CF(x, 0.5 + (h - 0.62) / 2, -d / 2 - 0.03), V(third - 0.15, h - 0.8, 0.06), lighter(color, 0.06), M.Wood)
		for k = -2, 2 do
			Kit.box(m, "Slat", cf * CF(x + k * (third - 0.4) / 5, 0.5 + (h - 0.62) / 2, -d / 2 - 0.07), V(0.08, h - 1.0, 0.03), dark, M.Wood)
		end
		Kit.box(m, "Knob", cf * CF(x - s * (third / 2 - 0.35), 0.5 + (h - 0.62) / 2, -d / 2 - 0.1), V(0.1, 0.3, 0.06), C.Brass, M.Metal)
	end
	Kit.box(m, "OpenShelf", cf * CF(0, 0.5 + (h - 0.62) / 2, -d / 2 + 0.3), V(third - 0.2, h - 0.8, 0.02), darker(color, 0.5), M.Wood)
	Kit.box(m, "MidShelf", cf * CF(0, 0.5 + (h - 0.62) / 2, -0.1), V(third - 0.2, 0.08, d - 0.3), dark, M.Wood)
	-- the game console sits on top, beside the TV
	Kit.gameConsole(m, cf * CF(w / 2 - 1.3, h, 0.1))
	Kit.box(m, "CableBox", cf * CF(0, 0.5 + (h - 0.62) / 2 + 0.2, -0.2), V(1.6, 0.35, 1.0), Color3.fromRGB(22, 22, 24), M.Plastic)
	Kit.box(m, "CableBoxLED", cf * CF(0.55, 0.5 + (h - 0.62) / 2 + 0.2, -0.71), V(0.3, 0.08, 0.02), Color3.fromRGB(60, 200, 90), M.Neon)
	Kit.collider(m, cf * CF(0, h / 2, 0), V(w, h, d))
	return m, h
end

function Kit.speaker(parent, cf: CFrame, h: number)
	local m = Kit.model(parent, "Speaker")
	Kit.solid(m, "Speaker", cf * CF(0, h / 2, 0), V(1.1, h, 1.1), Color3.fromRGB(26, 24, 22), M.Wood)
	Kit.box(m, "Grille", cf * CF(0, h / 2, -0.56), V(0.95, h - 0.2, 0.02), Color3.fromRGB(40, 40, 42), M.Fabric)
	Kit.cyl(m, "Woofer", cf * CF(0, h * 0.3, -0.58) * ANG(0, rad(90), 0), 0.04, 0.75, Color3.fromRGB(20, 20, 22), M.Plastic)
	Kit.cyl(m, "Tweeter", cf * CF(0, h * 0.72, -0.58) * ANG(0, rad(90), 0), 0.04, 0.35, Color3.fromRGB(20, 20, 22), M.Plastic)
	return m
end

function Kit.bench(parent, cf: CFrame, w: number, color: Color3, cushion: Color3?)
	local m = Kit.model(parent, "Bench")
	local dark = darker(color, 0.14)
	for _, sx in { -1, 1 } do
		Kit.box(m, "BenchEnd", cf * CF(sx * (w / 2 - 0.12), 1.0, 0), V(0.24, 2.0, 1.8), color, M.Wood)
	end
	Kit.soft(m, "BenchSeat", cf * CF(0, 2.0, 0), V(w, 0.2, 1.9), 0.08, color, M.Wood)
	Kit.box(m, "BenchShelf", cf * CF(0, 0.45, 0), V(w - 0.4, 0.12, 1.6), dark, M.Wood)
	if cushion then
		Kit.soft(m, "BenchCushion", cf * CF(0, 2.25, 0), V(w - 0.2, 0.3, 1.75), 0.13, cushion, M.Fabric)
	end
	Kit.collider(m, cf * CF(0, 1.1, 0), V(w, 2.2, 1.9))
	return m
end

function Kit.coatRack(parent, cf: CFrame, coats)
	local m = Kit.model(parent, "CoatRack")
	local wood = C.WoodDark
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		Kit.box(m, "RackFoot", cf * ANG(0, a, 0) * CF(0, 0.2, -0.55) * ANG(rad(-25), 0, 0), V(0.16, 0.16, 1.3), wood, M.Wood)
	end
	Kit.vcyl(m, "RackPole", cf * CF(0, 3.6, 0), 7.2, 0.24, wood, M.Wood)
	Kit.ball(m, "RackTop", (cf * CF(0, 7.3, 0)).Position, 0.4, wood, M.Wood)
	for k = 0, 3 do
		local a = k * math.pi / 2
		Kit.box(m, "RackHook", cf * CF(0, 6.7, 0) * ANG(0, a, 0) * CF(0, 0.1, -0.35) * ANG(rad(35), 0, 0), V(0.08, 0.08, 0.6), C.Brass, M.Metal)
	end
	for i, col in coats or {} do
		local a = (i - 1) * math.pi / 2 + math.pi / 4
		Kit.coat(m, cf * CF(0, 6.8, 0) * ANG(0, a + math.pi, 0) * CF(0, 0, -0.55), col)
	end
	Kit.collider(m, cf * CF(0, 3.6, 0), V(1.2, 7.2, 1.2))
	return m
end

function Kit.consoleTable(parent, cf: CFrame, w: number, d: number, color: Color3)
	local m = Kit.model(parent, "ConsoleTable")
	local dark = darker(color, 0.14)
	local h = 3.3
	Kit.soft(m, "ConsoleTop", cf * CF(0, h - 0.1, 0), V(w, 0.2, d), 0.08, color, M.Wood)
	Kit.box(m, "ConsoleApron", cf * CF(0, h - 0.45, 0), V(w - 0.4, 0.5, d - 0.3), dark, M.Wood)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Kit.taper(m, "Leg", cf * CF(sx * (w / 2 - 0.3), 0, sz * (d / 2 - 0.25)), h - 0.2, 0.16, 0.26, 3, dark, M.Wood)
		end
	end
	Kit.box(m, "ConsoleShelf", cf * CF(0, 0.6, 0), V(w - 0.5, 0.1, d - 0.4), dark, M.Wood)
	Kit.collider(m, cf * CF(0, h / 2, 0), V(w, h, d))
	return m, h
end

function Kit.filingCabinet(parent, cf: CFrame, drawers: number)
	local m = Kit.model(parent, "FilingCabinet")
	local steel = Color3.fromRGB(128, 132, 136)
	local h = drawers * 1.5 + 0.3
	Kit.solid(m, "FilingCabinet", cf * CF(0, h / 2, 0), V(2.4, h, 2.4), steel, M.Metal)
	for r = 0, drawers - 1 do
		local y = 0.25 + r * 1.5 + 0.7
		Kit.box(m, "FileDrawer", cf * CF(0, y, -1.22), V(2.2, 1.35, 0.06), lighter(steel, 0.1), M.Metal)
		Kit.box(m, "FilePull", cf * CF(0, y + 0.35, -1.3), V(0.8, 0.1, 0.1), C.Chrome, M.Metal)
		Kit.box(m, "FileLabel", cf * CF(0, y + 0.1, -1.26), V(0.5, 0.25, 0.02), C.Paper, M.Plastic)
	end
	return m, h
end

function Kit.chestFreezer(parent, cf: CFrame, w: number)
	local m = Kit.model(parent, "Freezer")
	Kit.solid(m, "Freezer", cf * CF(0, 1.7, 0), V(w, 3.4, 3.2), C.Porcelain, M.Plastic)
	Kit.soft(m, "FreezerLid", cf * CF(0, 3.5, 0), V(w + 0.05, 0.2, 3.25), 0.08, Color3.fromRGB(236, 236, 234), M.Plastic)
	Kit.box(m, "FreezerHandle", cf * CF(0, 3.2, -1.65), V(1.4, 0.15, 0.15), Color3.fromRGB(150, 150, 150), M.Plastic)
	Kit.box(m, "FreezerLED", cf * CF(w / 2 - 0.4, 2.8, -1.61), V(0.1, 0.1, 0.02), Color3.fromRGB(60, 220, 90), M.Neon)
	return m
end

function Kit.boiler(parent, cf: CFrame)
	local m = Kit.model(parent, "Boiler")
	local body = Color3.fromRGB(116, 110, 100)
	local pipe = Color3.fromRGB(120, 80, 60)
	Kit.solid(m, "Boiler", cf * CF(0, 3.3, 0), V(5, 6.6, 5), body, M.Metal)
	Kit.box(m, "BoilerBase", cf * CF(0, 0.2, 0), V(5.4, 0.4, 5.4), Color3.fromRGB(70, 66, 60), M.Concrete)
	Kit.box(m, "BurnerDoor", cf * CF(0, 1.4, -2.52), V(2.2, 1.6, 0.06), darker(body, 0.25), M.Metal)
	Kit.box(m, "PilotWindow", cf * CF(0, 1.4, -2.57), V(0.5, 0.3, 0.02), Color3.fromRGB(255, 140, 50), M.Neon)
	Kit.cyl(m, "Gauge", cf * CF(1.4, 4.6, -2.55) * ANG(0, rad(90), 0), 0.12, 0.8, C.Cream, M.Plastic)
	Kit.cyl(m, "GaugeRim", cf * CF(1.4, 4.6, -2.53) * ANG(0, rad(90), 0), 0.1, 0.92, C.Brass, M.Metal)
	Kit.vcyl(m, "Flue", cf * CF(0, 6.6 + 2.5, 0.8), 5, 1.2, Color3.fromRGB(150, 150, 150), M.Metal)
	for _, s in { -1, 1 } do
		Kit.vcyl(m, "Riser", cf * CF(s * 1.6, 6.6 + 2.5, -0.8), 5, 0.4, pipe, M.Metal)
		Kit.cyl(m, "Valve", cf * CF(s * 1.6, 7.6, -0.8) * ANG(0, 0, rad(90)), 0.1, 0.7, Color3.fromRGB(170, 30, 30), M.Metal)
	end
	return m
end

function Kit.waterHeater(parent, cf: CFrame)
	local m = Kit.model(parent, "WaterHeater")
	local c = Color3.fromRGB(196, 196, 190)
	Kit.vcyl(m, "WaterHeater", cf * CF(0, 3.4, 0), 6.4, 3.4, c, M.Metal)
	Kit.ellipsoid(m, "HeaterTop", cf * CF(0, 6.6, 0), V(3.4, 0.8, 3.4), c, M.Metal)
	Kit.vcyl(m, "HeaterBase", cf * CF(0, 0.15, 0), 0.3, 3.5, Color3.fromRGB(60, 60, 60), M.Metal)
	Kit.box(m, "HeaterLabel", cf * CF(0, 3.8, -1.7), V(1.2, 1.6, 0.04), Color3.fromRGB(220, 210, 180), M.Plastic)
	Kit.box(m, "Thermostat", cf * CF(0, 1.2, -1.72), V(0.8, 0.6, 0.2), Color3.fromRGB(40, 40, 40), M.Plastic)
	for _, s in { -1, 1 } do
		Kit.vcyl(m, "HeaterPipe", cf * CF(s * 0.8, 9.0, 0), 4.2, 0.35, Color3.fromRGB(184, 115, 70), M.Metal)
	end
	Kit.collider(m, cf * CF(0, 3.4, 0), V(3.4, 6.8, 3.4))
	return m
end

function Kit.umbrellaStand(parent, cf: CFrame)
	local m = Kit.model(parent, "UmbrellaStand")
	Kit.lathe(m, "UmbrellaStand", cf, { { 0, 1.0 }, { 0.1, 1.05 }, { 2.2, 0.95 }, { 2.4, 1.05 } }, Color3.fromRGB(40, 60, 70), M.Plastic)
	for k, col in { Color3.fromRGB(20, 20, 24), Color3.fromRGB(150, 30, 40) } do
		local u = cf * CF((k - 1.5) * 0.3, 0.3, 0) * ANG(0, 0, rad((k - 1.5) * 12))
		Kit.vcyl(m, "UmbrellaShaft", u * CF(0, 1.8, 0), 3.6, 0.08, C.Chrome, M.Metal)
		Kit.lathe(m, "Umbrella", u * CF(0, 0.6, 0), { { 0, 0.15 }, { 0.3, 0.4 }, { 2.2, 0.3 }, { 2.4, 0.1 } }, col, M.Fabric)
		Kit.ring(m, "UmbrellaHandle", u * CF(0, 3.7, 0.12) * ANG(0, rad(90), 0) * ANG(rad(90), 0, 0), 0.15, 0.08, 0.08, 6, Color3.fromRGB(80, 50, 30), M.Wood)
	end
	return m
end

function Kit.workbench(parent, cf: CFrame, w: number, d: number)
	local m = Kit.model(parent, "Workbench")
	local top = Color3.fromRGB(176, 138, 98)
	local frame = Color3.fromRGB(96, 70, 50)
	Kit.solid(m, "Workbench", cf * CF(0, 3.2, 0), V(w, 0.4, d), top, M.Wood)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Kit.box(m, "BenchLeg", cf * CF(sx * (w / 2 - 0.3), 1.5, sz * (d / 2 - 0.3)), V(0.4, 3.0, 0.4), frame, M.Wood)
		end
	end
	Kit.box(m, "BenchShelf", cf * CF(0, 0.9, 0), V(w - 0.4, 0.15, d - 0.3), frame, M.Wood)
	Kit.box(m, "Vise", cf * CF(w / 2 - 0.8, 3.65, -d / 2 + 0.3), V(0.9, 0.5, 0.7), Color3.fromRGB(40, 70, 120), M.Metal)
	Kit.box(m, "ViseJaw", cf * CF(w / 2 - 0.8, 3.65, -d / 2 - 0.1), V(0.9, 0.5, 0.15), Color3.fromRGB(40, 70, 120), M.Metal)
	Kit.cyl(m, "ViseHandle", cf * CF(w / 2 - 0.8, 3.5, -d / 2 - 0.3), 1.2, 0.08, C.Chrome, M.Metal)
	Kit.collider(m, cf * CF(0, 1.7, 0), V(w, 3.4, d))
	return m
end

---------------------------------------------------------------------------
-- People
---------------------------------------------------------------------------
-- the pizza delivery man: too tall, too thin, too pale. cf = between his feet, facing forward.
-- Returns the model, the head model (to turn and tilt), its neck CFrame relative to cf, and the pizza box.
function Kit.deliveryMan(parent, cf: CFrame, faceImage: string?)
	-- stand-in for the avatar, in the same uniform: red shirt with the TONY'S patch, dark jeans,
	-- red cap, a classic Roblox head and face, carrying two pizza boxes in both hands
	local m = Kit.model(parent, "PizzaGuy")
	local skin = Color3.fromRGB(234, 190, 152)
	local jacket = Color3.fromRGB(196, 32, 28)
	local tee = Color3.fromRGB(250, 240, 214)
	local pants = Color3.fromRGB(44, 50, 66)
	-- legs and shoes
	for _, s in { -1, 1 } do
		Kit.soft(m, "Leg", cf * CF(s * 0.42, 1.65, 0), V(0.62, 3.2, 0.62), 0.18, pants, M.Fabric)
		Kit.soft(m, "Shoe", cf * CF(s * 0.42, 0.14, -0.15), V(0.6, 0.28, 1.05), 0.12, C.Black, M.Leather)
	end
	-- torso: the red uniform shirt with a cream TONY'S patch
	Kit.soft(m, "Torso", cf * CF(0, 4.45, 0), V(1.7, 2.6, 0.85), 0.25, jacket, M.Fabric)
	Kit.box(m, "Tee", cf * CF(0.35, 5.0, -0.43), V(0.6, 0.3, 0.03), tee, M.Fabric)
	-- arms down at his sides, forearms level, hands under the boxes
	for _, s in { -1, 1 } do
		local shoulder = cf * CF(s * 1.05, 5.45, 0) * ANG(rad(14), 0, 0)
		Kit.soft(m, "UpperArm", shoulder * CF(0, -0.85, 0), V(0.5, 1.8, 0.5), 0.2, jacket, M.Fabric)
		local elbow = shoulder * CF(0, -1.75, 0) * ANG(rad(76), 0, 0)
		Kit.soft(m, "Forearm", elbow * CF(0, -0.75, 0), V(0.44, 1.5, 0.44), 0.18, skin, M.Plastic)
		Kit.ellipsoid(m, "Hand", elbow * CF(0, -1.62, 0), V(0.42, 0.5, 0.3), skin, M.Plastic)
	end
	-- the pizza: two boxes flat on his hands
	local boxCF = cf * CF(0, 3.95, -1.95)
	local box = Kit.box(m, "PizzaBag", boxCF, V(2.2, 0.34, 2.2), Color3.fromRGB(206, 182, 142), M.Cardboard)
	Kit.box(m, "PizzaBag", boxCF * CF(0, 0.36, 0) * ANG(0, 0.1, 0), V(2.2, 0.34, 2.2), Color3.fromRGB(206, 182, 142), M.Cardboard)
	Kit.box(m, "BagLogo", boxCF * CF(0, 0.54, 0) * ANG(0, 0.1, 0), V(1.1, 0.01, 1.1), Color3.fromRGB(170, 36, 32), M.Plastic)
	-- neck and a classic head carrying the face texture
	Kit.vcyl(m, "Neck", cf * CF(0, 5.95, 0.05), 0.7, 0.5, skin, M.Plastic)
	local head = Kit.model(m, "Head")
	local neck = CF(0, 6.3, 0.05)
	local skull = Kit.box(head, "Skull", cf * neck * CF(0, 0.7, 0), V(1.2, 1.2, 1.2), skin, M.Plastic)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = V(1.25, 1.25, 1.25)
	mesh.Parent = skull
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = faceImage or "rbxasset://textures/face.png"
	face.Parent = skull
	-- the red cap
	local h = cf * neck
	Kit.ellipsoid(head, "Cap", h * CF(0, 1.25, 0.02), V(1.55, 0.7, 1.55), jacket, M.Fabric)
	Kit.box(head, "CapBrim", h * CF(0, 1.08, -0.85) * ANG(rad(-8), 0, 0), V(1.1, 0.07, 0.7), darker(jacket, 0.15), M.Fabric)
	head.PrimaryPart = skull
	Kit.collider(m, cf * CF(0, 3.6, 0), V(1.8, 7.2, 1.2))
	m.PrimaryPart = Kit.box(m, "Root", cf, V(0.2, 0.2, 0.2), skin, M.Plastic, { Transparency = 1 })
	return m, head, neck, box
end

---------------------------------------------------------------------------
-- Cozy things
---------------------------------------------------------------------------

-- a knitted throw draped over a sofa or armchair back; sofaCF/depth as passed to Kit.sofa,
-- x = offset along the sofa, w = width of the throw
function Kit.throwBlanket(parent, sofaCF: CFrame, depth: number, x: number, w: number, color: Color3, stripe: Color3?)
	local m = Kit.model(parent, "Throw")
	local back = depth / 2 - 0.3
	local st = stripe or lighter(color, 0.35)
	-- over the top of the back, down in front of the back cushions, and down behind
	local fz = back - 1.2 -- the front drape hangs just in front of the back cushions
	local function frontZ(y: number): number
		return fz + (y - 3.15) * 0.194 -- the drape leans back with the cushions (11 degrees)
	end
	Kit.soft(m, "ThrowTop", sofaCF * CF(x, 3.95, back - 0.45), V(w, 0.16, 1.6), 0.07, color, M.Fabric)
	Kit.soft(m, "ThrowFront", sofaCF * CF(x, 3.15, fz) * ANG(rad(11), 0, 0), V(w, 1.7, 0.12), 0.05, color, M.Fabric)
	Kit.soft(m, "ThrowBack", sofaCF * CF(x, 3.1, back + 0.38), V(w, 1.7, 0.12), 0.05, darker(color, 0.05), M.Fabric)
	for _, y in { 3.5, 2.6 } do
		Kit.box(m, "ThrowStripe", sofaCF * CF(x, y, frontZ(y) - 0.07) * ANG(rad(11), 0, 0), V(w + 0.01, 0.16, 0.02), st, M.Fabric)
	end
	-- a tassel fringe along the hanging edge
	for k = 0, math.floor(w / 0.3) do
		Kit.box(m, "Fringe", sofaCF * CF(x - w / 2 + 0.15 + k * 0.3, 2.2, frontZ(2.2)) * ANG(rad(11), 0, 0), V(0.05, 0.25, 0.05), st, M.Fabric)
	end
	return m
end

-- a folded throw across the foot of a bed (bedCF, w, l as passed to Kit.bed)
function Kit.bedThrow(parent, bedCF: CFrame, w: number, l: number, color: Color3, stripe: Color3?)
	local m = Kit.model(parent, "BedThrow")
	local z = -(l - 0.45) / 2 + 1.2
	Kit.soft(m, "ThrowFold", bedCF * CF(0, 3.72, z), V(w + 0.08, 0.2, 2), 0.08, color, M.Fabric)
	for _, s in { -1, 1 } do
		Kit.soft(m, "ThrowDrape", bedCF * CF(s * (w / 2 + 0.1), 3.1, z), V(0.12, 1.3, 2), 0.05, darker(color, 0.06), M.Fabric)
	end
	Kit.box(m, "ThrowStripe", bedCF * CF(0, 3.83, z + 0.6), V(w + 0.1, 0.02, 0.25), stripe or lighter(color, 0.35), M.Fabric)
	return m
end

-- a plump square cushion; cf = centre, facing out along -Z
function Kit.cushion(parent, cf: CFrame, size: number, color: Color3, piping: Color3?)
	local m = Kit.model(parent, "Cushion")
	Kit.soft(m, "Cushion", cf, V(size, size, size * 0.34), size * 0.16, color, M.Fabric)
	Kit.box(m, "CushionButton", cf * CF(0, 0, -size * 0.17), V(size * 0.12, size * 0.12, 0.04), piping or darker(color, 0.25), M.Fabric)
	return m
end

-- a round wicker basket with rolled-up blankets (or logs) standing in it
function Kit.basket(parent, cf: CFrame, d: number, h: number, fill: string?, colors)
	local m = Kit.model(parent, "Basket")
	local wicker = Color3.fromRGB(176, 136, 86)
	Kit.lathe(m, "Basket", cf, { { 0, d * 0.82 }, { 0.1, d * 0.9 }, { h, d } }, wicker, M.Fabric)
	for k = 0, 3 do
		Kit.vcyl(m, "BasketWeave", cf * CF(0, h * (0.2 + k * 0.22), 0), 0.06, d * (0.9 + k * 0.03) + 0.02, darker(wicker, 0.18), M.Fabric)
	end
	Kit.vcyl(m, "BasketFill", cf * CF(0, h - 0.1, 0), 0.08, d * 0.94, darker(wicker, 0.45), M.Fabric)
	colors = colors or { Color3.fromRGB(196, 72, 60), Color3.fromRGB(226, 214, 190), Color3.fromRGB(80, 110, 90) }
	for k, c in colors do
		local a = k / #colors * math.pi * 2
		local p = cf * CF(math.cos(a) * d * 0.2, h + 0.35, math.sin(a) * d * 0.2)
		if fill == "logs" then
			Kit.vcyl(m, "BasketLog", p * ANG(rad(8), a, 0), 1.6, 0.5, Color3.fromRGB(96, 70, 46), M.Wood)
		else
			Kit.vcyl(m, "BlanketRoll", p * ANG(rad(10), a, 0), 1.9, d * 0.34, c, M.Fabric)
		end
	end
	return m
end

-- warm fairy lights hanging in a curve from a to b; every few bulbs carries a real light.
-- Returns the bulbs and the lights (each light's bulb is lights[i].Parent).
function Kit.stringLights(parent, a: Vector3, b: Vector3, sag: number, n: number, color: Color3?)
	local m = Kit.model(parent, "FairyLights")
	local c = color or Color3.fromRGB(255, 198, 130)
	local function at(t: number): Vector3
		return a:Lerp(b, t) - V(0, math.sin(t * math.pi) * sag, 0)
	end
	local segs = n * 2
	for k = 0, segs - 1 do
		local p0, p1 = at(k / segs), at((k + 1) / segs)
		Kit.box(m, "LightWire", CFrame.lookAt((p0 + p1) / 2, p1), V(0.04, 0.04, (p1 - p0).Magnitude + 0.02), Color3.fromRGB(40, 50, 40), M.Plastic)
	end
	local bulbs, lights = {}, {}
	for k = 0, n - 1 do
		local p = at((k + 0.5) / n) - V(0, 0.12, 0)
		local bulb = Kit.ellipsoid(m, "FairyBulb", CF(p), V(0.16, 0.24, 0.16), c, M.Neon)
		table.insert(bulbs, bulb)
		if k % 4 == 1 then
			local l = Instance.new("PointLight")
			l.Range = 8
			l.Brightness = 0.55
			l.Color = c
			l.Shadows = false
			l.Parent = bulb
			table.insert(lights, l)
		end
	end
	return m, bulbs, lights
end

-- a wall sconce with a small fabric shade; cf on the wall face, facing into the room
function Kit.sconce(parent, cf: CFrame, shadeColor: Color3?)
	local m = Kit.model(parent, "Sconce")
	Kit.box(m, "SconcePlate", cf * CF(0, 0, 0.03), V(0.5, 0.9, 0.06), C.Brass, M.Metal)
	Kit.cyl(m, "SconceArm", cf * CF(0, -0.1, -0.3) * ANG(0, rad(90), 0), 0.55, 0.1, C.Brass, M.Metal)
	Kit.vcyl(m, "SconceCup", cf * CF(0, 0.0, -0.6), 0.2, 0.3, C.Brass, M.Metal)
	Kit.lathe(m, "SconceShade", cf * CF(0, 0.15, -0.6), { { 0, 0.9 }, { 0.75, 0.6 } }, shadeColor or Color3.fromRGB(240, 222, 190), M.Fabric)
	local bulb = Kit.ball(m, "SconceBulb", (cf * CF(0, 0.35, -0.6)).Position, 0.3, Color3.fromRGB(255, 206, 150), M.Neon)
	local light = Instance.new("PointLight")
	light.Range = 13
	light.Brightness = 0.8
	light.Color = Color3.fromRGB(255, 184, 116)
	light.Shadows = false
	light.Parent = bulb
	return m, bulb, light
end

-- a mug of hot cocoa with marshmallows and a thin curl of steam
function Kit.cocoa(parent, cf: CFrame, color: Color3)
	local m, body = Kit.mug(parent, cf, color)
	Kit.vcyl(m, "Cocoa", cf * CF(0, 0.49, 0), 0.03, 0.34, Color3.fromRGB(96, 58, 36), M.Plastic)
	for k = 0, 2 do
		Kit.box(m, "Marshmallow", cf * CF(-0.07 + k * 0.07, 0.5, (k % 2) * 0.06 - 0.03) * ANG(0, k, 0), V(0.08, 0.06, 0.08), Color3.fromRGB(250, 246, 238), M.Plastic)
	end
	local steam = Instance.new("ParticleEmitter")
	steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
	steam.Color = ColorSequence.new(Color3.fromRGB(245, 245, 245))
	steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.85), NumberSequenceKeypoint.new(1, 1) })
	steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 0.45) })
	steam.Lifetime = NumberRange.new(1.2, 1.8)
	steam.Rate = 4
	steam.Speed = NumberRange.new(0.5, 0.8)
	steam.SpreadAngle = Vector2.new(8, 8)
	steam.EmissionDirection = Enum.NormalId.Top
	steam.LightInfluence = 0.6
	steam.Parent = body
	return m, body
end

-- a plate of cookies
function Kit.cookies(parent, cf: CFrame)
	local m = Kit.plate(parent, cf, 1.1)
	m.Name = "CookiePlate" -- keeps its hand-made cookies (Props leaves it alone)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		local c = Kit.vcyl(m, "Cookie", cf * CF(math.cos(a) * 0.26, 0.1 + (k % 2) * 0.04, math.sin(a) * 0.26) * ANG(rad((k % 2) * 8), 0, 0), 0.07, 0.36, Color3.fromRGB(196, 146, 84), M.Plastic)
		Kit.box(m, "ChocChip", c.CFrame * CF(0.06, 0.04, 0.02), V(0.06, 0.02, 0.06), Color3.fromRGB(70, 40, 24), M.Plastic)
	end
	Kit.vcyl(m, "Cookie", cf * CF(0, 0.2, 0), 0.07, 0.36, Color3.fromRGB(200, 150, 88), M.Plastic)
	return m
end

-- a stovetop kettle
function Kit.kettle(parent, cf: CFrame, color: Color3)
	local m = Kit.model(parent, "Kettle")
	Kit.lathe(m, "Kettle", cf, { { 0, 0.9 }, { 0.12, 1.0 }, { 0.45, 0.95 }, { 0.75, 0.55 }, { 0.82, 0.3 } }, color, M.Metal)
	Kit.vcyl(m, "KettleKnob", cf * CF(0, 0.88, 0), 0.1, 0.16, C.Black, M.Plastic)
	Kit.cyl(m, "KettleSpout", cf * CF(0.55, 0.45, 0) * ANG(0, 0, rad(40)), 0.55, 0.13, color, M.Metal)
	for k = 0, 4 do
		local a = math.pi * (0.15 + k * 0.175)
		Kit.ball(m, "KettleHandle", (cf * CF(math.cos(a) * 0.36, 0.8 + math.sin(a) * 0.3, 0)).Position, 0.1, C.Black, M.Plastic)
	end
	return m
end

-- a pumpkin: ribbed body and a curly stem; cf = where it sits
function Kit.pumpkin(parent, cf: CFrame, d: number, color: Color3?)
	local m = Kit.model(parent, "Pumpkin")
	local c = color or Color3.fromRGB(226, 120, 36)
	local h = d * 0.72
	for k = 0, 5 do
		Kit.ellipsoid(m, "PumpkinRib", cf * CF(0, h / 2, 0) * ANG(0, k * math.pi / 6, 0), V(d, h, d * 0.62), k % 2 == 0 and c or darker(c, 0.08), M.Plastic)
	end
	Kit.vcyl(m, "PumpkinStem", cf * CF(0, h + 0.12, 0) * ANG(rad(12), 0, 0), 0.34, d * 0.12, Color3.fromRGB(92, 110, 60), M.Wood)
	return m
end

-- a pot of autumn chrysanthemums
function Kit.mums(parent, cf: CFrame, d: number, bloom: Color3)
	local m = Kit.model(parent, "Mums")
	Kit.lathe(m, "MumPot", cf, { { 0, d * 0.62 }, { d * 0.7, d * 0.8 }, { d * 0.78, d * 0.84 } }, Color3.fromRGB(150, 84, 58), M.Plastic)
	Kit.ellipsoid(m, "MumLeaves", cf * CF(0, d * 0.9, 0), V(d * 1.05, d * 0.6, d * 1.05), Color3.fromRGB(56, 82, 44), M.Fabric)
	local rng = Random.new(math.floor(d * 100))
	for _ = 1, 14 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(0, d * 0.42)
		Kit.ball(m, "Mum", (cf * CF(math.cos(a) * r, d * 1.08 + rng:NextNumber(0, 0.1) - r * 0.25, math.sin(a) * r)).Position, d * 0.2, bloom, M.Fabric)
	end
	return m
end

---------------------------------------------------------------------------
-- The neighborhood
---------------------------------------------------------------------------

-- A suburban house seen from the street (not enterable). cf = centre of the footprint at
-- ground level, front facing local -Z. opts: W, D, Stories (1|2), Siding, Roof, Trim, Door,
-- Shutter, Lit = { [windowIndex] = true } (front windows numbered left to right, ground floor
-- first), Garage (bool, on the right), Porch (bool), Chimney (bool), Seed
function Kit.suburbHouse(parent, cf: CFrame, opts)
	local m = Kit.model(parent, opts.Name or "House")
	local W, D = opts.W or 34, opts.D or 24
	local stories = opts.Stories or 2
	local H = stories * 11
	local siding = opts.Siding or Color3.fromRGB(150, 160, 170)
	local trim = opts.Trim or Color3.fromRGB(236, 232, 224)
	local roof = opts.Roof or Color3.fromRGB(52, 50, 54)
	local shutter = opts.Shutter or Color3.fromRGB(40, 44, 50)
	local base = 1.2
	-- foundation, body, band between floors
	Kit.box(m, "Foundation", cf * CF(0, base / 2, 0), V(W + 0.8, base, D + 0.8), Color3.fromRGB(120, 116, 110), M.Concrete)
	Kit.solid(m, "Body", cf * CF(0, base + H / 2, 0), V(W, H, D), siding, M.Siding)
	Kit.box(m, "Corner", cf * CF(-W / 2, base + H / 2, -D / 2), V(0.6, H, 0.6), trim, M.Wood)
	Kit.box(m, "Corner", cf * CF(W / 2, base + H / 2, -D / 2), V(0.6, H, 0.6), trim, M.Wood)
	if stories == 2 then
		Kit.box(m, "Band", cf * CF(0, base + 11, -D / 2 - 0.1), V(W + 0.2, 0.4, 0.3), trim, M.Wood)
	end
	-- gable roof along X with a little overhang
	local rise = 7
	for _, s in { -1, 1 } do
		Kit.wedge(m, "Roof", cf * CF(0, base + H + rise / 2, s * (D / 4 + 0.5)) * ANG(0, s < 0 and 0 or math.pi, 0), V(W + 2, rise, D / 2 + 1), roof, M.Roof, { CanCollide = true })
	end
	Kit.box(m, "Fascia", cf * CF(0, base + H - 0.2, -D / 2 - 1.05), V(W + 2, 0.5, 0.2), trim, M.Wood)
	if opts.Chimney then
		Kit.box(m, "Chimney", cf * CF(W / 2 - 4, base + H + rise - 1, D / 6), V(2.6, 9, 2.6), Color3.fromRGB(116, 62, 50), M.Brick)
	end
	-- front windows (left to right, ground floor first), the door in the middle
	local lit = opts.Lit or {}
	local garage = opts.Garage == true
	local usable = garage and (W - 12) or W
	local x0 = -W / 2
	local cols = math.max(2, math.floor(usable / 8))
	local idx = 0
	for floor = 1, stories do
		for c = 1, cols do
			local x = x0 + usable * (c - 0.5) / cols
			-- the door takes the middle of the ground floor
			if not (floor == 1 and math.abs(x - (x0 + usable / 2)) < 3) then
				idx += 1
				local y = base + (floor - 1) * 11 + 6
				local wcf = cf * CF(x, y, -D / 2 - 0.15)
				Kit.box(m, "WindowFrame", wcf, V(3.8, 5, 0.3), trim, M.Wood)
				if lit[idx] then
					Kit.box(m, "WindowLit", wcf * CF(0, 0, -0.1), V(3.2, 4.4, 0.1), Color3.fromRGB(255, 196, 132), M.Neon)
					Kit.box(m, "Curtain", wcf * CF(-1.1, 0, -0.16), V(0.9, 4.4, 0.05), Color3.fromRGB(170, 110, 80), M.Fabric)
				else
					Kit.box(m, "WindowDark", wcf * CF(0, 0, -0.1), V(3.2, 4.4, 0.1), Color3.fromRGB(22, 26, 32), M.Glass, { Reflectance = 0.2 })
				end
				Kit.box(m, "Mullion", wcf * CF(0, 0, -0.17), V(0.18, 4.4, 0.05), trim, M.Wood)
				Kit.box(m, "Mullion", wcf * CF(0, 0, -0.17), V(3.2, 0.18, 0.05), trim, M.Wood)
				for _, sx in { -1, 1 } do
					Kit.box(m, "Shutter", wcf * CF(sx * 2.45, 0, -0.05), V(1.1, 5, 0.12), shutter, M.Wood)
				end
			end
		end
	end
	-- the back of the house isn't a blank wall: plain windows on every floor and a back door
	local backCols = math.max(2, math.floor(W / 9))
	for floor = 1, stories do
		for c = 1, backCols do
			local x = -W / 2 + W * (c - 0.5) / backCols
			local y = base + (floor - 1) * 11 + 6
			if floor == 1 and c == backCols then
				local bcf = cf * CF(x, base + 4.3, D / 2 + 0.15)
				Kit.box(m, "BackDoorFrame", bcf, V(4.2, 8.6, 0.3), trim, M.Wood)
				Kit.box(m, "BackDoor", bcf * CF(0, -0.2, 0.12), V(3.4, 8, 0.12), trim:Lerp(Color3.new(0, 0, 0), 0.25), M.Wood)
			else
				local wcf = cf * CF(x, y, D / 2 + 0.15)
				Kit.box(m, "WindowFrame", wcf, V(3.6, 4.6, 0.3), trim, M.Wood)
				Kit.box(m, "WindowDark", wcf * CF(0, 0, 0.1), V(3.0, 4.0, 0.1), Color3.fromRGB(22, 26, 32), M.Glass, { Reflectance = 0.2 })
				Kit.box(m, "Mullion", wcf * CF(0, 0, 0.17), V(3.0, 0.18, 0.05), trim, M.Wood)
			end
		end
	end
	-- the door, steps and a porch light
	local dx = x0 + usable / 2
	local dcf = cf * CF(dx, base + 4.3, -D / 2 - 0.15)
	Kit.box(m, "DoorFrame", dcf, V(4.4, 8.8, 0.3), trim, M.Wood)
	Kit.box(m, "Door", dcf * CF(0, -0.2, -0.12), V(3.6, 8.2, 0.12), opts.Door or Color3.fromRGB(110, 40, 36), M.Wood)
	Kit.ball(m, "Knob", (dcf * CF(1.2, -0.4, -0.25)).Position, 0.3, C.Brass, M.Metal)
	Kit.box(m, "Step", cf * CF(dx, 0.3, -D / 2 - 1.4), V(6, 0.6, 2.6), Color3.fromRGB(140, 136, 130), M.Concrete)
	if opts.Porch then
		Kit.box(m, "PorchRoof", cf * CF(dx, base + 9.6, -D / 2 - 2.6), V(8, 0.5, 5.2), roof, M.Roof)
		for _, sx in { -1, 1 } do
			Kit.vcyl(m, "PorchPost", cf * CF(dx + sx * 3.6, base + 4.7, -D / 2 - 4.8), 9.4, 0.5, trim, M.Wood)
		end
	end
	local lamp = Kit.box(m, "PorchLamp", dcf * CF(-3, 1.2, -0.4), V(0.6, 0.9, 0.6), lit.Porch == false and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(255, 200, 130), lit.Porch == false and M.Plastic or M.Neon)
	if opts.PorchLight ~= false then
		local l = Instance.new("PointLight")
		l.Range = 14
		l.Brightness = 1
		l.Color = Color3.fromRGB(255, 190, 120)
		l.Shadows = false
		l.Parent = lamp
	end
	if garage then
		local gx = W / 2 - 6
		Kit.box(m, "GarageFrame", cf * CF(gx, base + 4, -D / 2 - 0.15), V(10.6, 8.4, 0.3), trim, M.Wood)
		local gd = Kit.box(m, "GarageDoor", cf * CF(gx, base + 3.9, -D / 2 - 0.25), V(10, 7.8, 0.12), Color3.fromRGB(226, 222, 214), M.Metal)
		for k = 1, 3 do
			Kit.box(m, "GarageSeam", gd.CFrame * CF(0, -3.9 + k * 1.95, -0.07), V(10, 0.08, 0.03), Color3.fromRGB(180, 176, 168), M.Metal)
		end
	end
	return m
end

-- a wooden telephone pole with a crossarm; returns the model and the two wire points
function Kit.telephonePole(parent, pos: Vector3, h: number?)
	local m = Kit.model(parent, "TelephonePole")
	local height = h or 26
	Kit.vcyl(m, "Pole", CF(pos + V(0, height / 2, 0)), height, 0.9, Color3.fromRGB(88, 70, 52), M.Wood, { CanCollide = true })
	Kit.box(m, "Crossarm", CF(pos + V(0, height - 2, 0)), V(0.5, 0.5, 7), Color3.fromRGB(88, 70, 52), M.Wood)
	for _, z in { -3, 3 } do
		Kit.vcyl(m, "Insulator", CF(pos + V(0, height - 1.55, z)), 0.5, 0.3, Color3.fromRGB(120, 160, 140), M.Glass)
	end
	Kit.vcyl(m, "Transformer", CF(pos + V(0.9, height - 6, 0)), 2.6, 1.6, Color3.fromRGB(110, 114, 118), M.Metal)
	return m, pos + V(0, height - 1.3, -3), pos + V(0, height - 1.3, 3)
end

-- a sagging overhead wire from a to b
function Kit.wire(parent, a: Vector3, b: Vector3, sag: number)
	local m = Kit.model(parent, "Wire")
	local n = 8
	local function at(t: number): Vector3
		return a:Lerp(b, t) - V(0, math.sin(t * math.pi) * sag, 0)
	end
	for k = 0, n - 1 do
		local p0, p1 = at(k / n), at((k + 1) / n)
		Kit.box(m, "WireSeg", CFrame.lookAt((p0 + p1) / 2, p1), V(0.08, 0.08, (p1 - p0).Magnitude + 0.05), Color3.fromRGB(20, 20, 22), M.Plastic, { CastShadow = false })
	end
	return m
end

-- a striped road barricade with two amber blinkers; returns the blinker parts
function Kit.barricade(parent, cf: CFrame, w: number)
	local m = Kit.model(parent, "Barricade")
	local blinkers = {}
	for _, s in { -1, 1 } do
		for _, e in { -1, 1 } do
			Kit.box(m, "BarricadeLeg", cf * CF(s * (w / 2 - 0.4), 1.9, e * 0.8) * ANG(e * 0.25, 0, 0), V(0.3, 3.9, 0.3), Color3.fromRGB(230, 230, 226), M.Wood)
		end
	end
	for k, y in { 3.2, 2.1 } do
		local board = Kit.box(m, "BarricadeBoard", cf * CF(0, y, 0), V(w, 0.7, 0.2), Color3.fromRGB(236, 236, 232), M.Wood, { CanCollide = true })
		for i = 0, math.floor(w / 1.2) - 1 do
			Kit.box(m, "Stripe", board.CFrame * CF(-w / 2 + 0.6 + i * 1.2, 0, -0.11) * ANG(0, 0, rad(k == 1 and 40 or -40)), V(0.35, 0.95, 0.02), Color3.fromRGB(220, 110, 30), M.Plastic)
		end
	end
	for _, s in { -1, 1 } do
		local b = Kit.ball(m, "Blinker", (cf * CF(s * (w / 2 - 0.4), 4.1, 0)).Position, 0.5, Color3.fromRGB(255, 170, 40), M.Neon)
		table.insert(blinkers, b)
	end
	return m, blinkers
end

-- a road sign on a post; `text` on both faces
function Kit.roadSign(parent, cf: CFrame, text: string, color: Color3?, textColor: Color3?, w: number?, h: number?)
	local m = Kit.model(parent, "RoadSign")
	local sw, sh = w or 5, h or 1.4
	Kit.vcyl(m, "SignPost", cf * CF(0, 4.5, 0), 9, 0.25, Color3.fromRGB(140, 140, 144), M.Metal)
	local sign = Kit.box(m, "Sign", cf * CF(0, 8.4, 0), V(sw, sh, 0.12), color or Color3.fromRGB(30, 110, 60), M.Metal)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.CanvasSize = Vector2.new(sw * 50, sh * 50)
		gui.LightInfluence = 1
		gui.Parent = sign
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = textColor or Color3.new(1, 1, 1)
		label.Text = text
		label.Parent = gui
	end
	return m
end

-- a bus shelter with a bench and a timetable
function Kit.busStop(parent, cf: CFrame)
	local m = Kit.model(parent, "BusStop")
	local metal = Color3.fromRGB(60, 64, 70)
	for _, s in { -1, 1 } do
		for _, e in { -1, 1 } do
			Kit.vcyl(m, "ShelterPost", cf * CF(s * 4.5, 4, e * 1.6), 8, 0.25, metal, M.Metal, { CanCollide = true })
		end
		Kit.box(m, "ShelterSide", cf * CF(s * 4.5, 4.3, 0), V(0.1, 5.5, 3), Color3.fromRGB(170, 190, 200), M.Glass, { Transparency = 0.6 })
	end
	Kit.box(m, "ShelterBack", cf * CF(0, 4.3, 1.6), V(9, 5.5, 0.1), Color3.fromRGB(170, 190, 200), M.Glass, { Transparency = 0.6 })
	Kit.box(m, "ShelterRoof", cf * CF(0, 8.1, 0), V(10, 0.3, 4), metal, M.Metal, { CanCollide = true })
	Kit.bench(m, cf * CF(0, 0, 0.9), 6, Color3.fromRGB(90, 70, 50))
	Kit.box(m, "Timetable", cf * CF(-3.2, 5, 1.52), V(1.6, 2.2, 0.05), Color3.fromRGB(236, 236, 230), M.Plastic)
	return m
end

-- a bicycle standing on its wheels; cf = between the wheels at ground level, facing local -Z
function Kit.bicycle(parent, cf: CFrame, color: Color3)
	local m = Kit.model(parent, "Bicycle")
	local r = 1.25
	for _, z in { -1.7, 1.7 } do
		Kit.ring(m, "Tyre", cf * CF(0, r, z) * ANG(0, 0, rad(90)), r, 0.14, 0.14, 16, C.Black, M.Rubber)
		Kit.cyl(m, "Hub", cf * CF(0, r, z), 0.3, 0.2, C.Chrome, M.Metal)
	end
	local tube = function(a: Vector3, b: Vector3)
		local pa, pb = (cf * CF(a)).Position, (cf * CF(b)).Position
		Kit.box(m, "Frame", CFrame.lookAt((pa + pb) / 2, pb), V(0.14, 0.14, (pb - pa).Magnitude), color, M.Metal)
	end
	local bb, seat, head = V(0, 0.95, 0.2), V(0, 2.9, 0.7), V(0, 2.7, -1.2)
	tube(bb, seat)
	tube(bb, head)
	tube(seat, head)
	tube(bb, V(0, r, 1.7))
	tube(seat, V(0, r, 1.7))
	tube(head, V(0, r, -1.7))
	Kit.box(m, "Saddle", cf * CF(0, 3.05, 0.75), V(0.35, 0.14, 0.9), C.Black, M.Leather)
	Kit.cyl(m, "Handlebar", cf * CF(0, 3.2, -1.25), 1.6, 0.12, C.Chrome, M.Metal)
	Kit.vcyl(m, "Stem", cf * CF(0, 2.95, -1.23), 0.5, 0.12, C.Chrome, M.Metal)
	return m
end

return Kit
