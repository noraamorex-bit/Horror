--[[
	Builder — geometry primitives for the procedural house.
	Every helper returns the created instance(s). All parts are anchored.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = require(ReplicatedStorage.Shared.Util)

local Builder = {}

Builder.M = {
	Wall = Util.material("Plaster", "SmoothPlastic"),
	Siding = Enum.Material.WoodPlanks,
	Wood = Enum.Material.Wood,
	Planks = Enum.Material.WoodPlanks,
	Carpet = Util.material("Carpet", "Fabric"),
	Tile = Util.material("CeramicTiles", "Slate"),
	Concrete = Enum.Material.Concrete,
	Brick = Enum.Material.Brick,
	Metal = Enum.Material.Metal,
	Glass = Enum.Material.Glass,
	Fabric = Enum.Material.Fabric,
	Leather = Util.material("Leather", "Fabric"),
	Plastic = Enum.Material.SmoothPlastic,
	Marble = Enum.Material.Marble,
	Roof = Util.material("RoofShingles", "Slate"),
	Asphalt = Util.material("Asphalt", "Concrete"),
	Cardboard = Util.material("Cardboard", "Fabric"),
	Neon = Enum.Material.Neon,
	Insulation = Enum.Material.Fabric,
}

Builder.C = {
	Drywall = Color3.fromRGB(222, 216, 202),
	WarmWall = Color3.fromRGB(205, 190, 165),
	GreenWall = Color3.fromRGB(150, 160, 140),
	BlueWall = Color3.fromRGB(150, 165, 180),
	PinkWall = Color3.fromRGB(215, 185, 190),
	Siding = Color3.fromRGB(120, 130, 135),
	Trim = Color3.fromRGB(235, 232, 225),
	Oak = Color3.fromRGB(140, 100, 65),
	DarkWood = Color3.fromRGB(80, 55, 38),
	Walnut = Color3.fromRGB(100, 70, 48),
	Carpet = Color3.fromRGB(120, 110, 100),
	BlueCarpet = Color3.fromRGB(80, 90, 110),
	Tile = Color3.fromRGB(215, 215, 210),
	Concrete = Color3.fromRGB(125, 125, 120),
	Roof = Color3.fromRGB(55, 52, 50),
	Black = Color3.fromRGB(20, 20, 22),
	White = Color3.fromRGB(240, 240, 238),
	Steel = Color3.fromRGB(160, 162, 165),
	Fabric = Color3.fromRGB(95, 85, 75),
	Red = Color3.fromRGB(140, 40, 35),
	Glass = Color3.fromRGB(160, 185, 200),
}

function Builder.part(parent: Instance, props: { [string]: any }): BasePart
	local className = props.ClassName or "Part"
	local p = Instance.new(className) :: BasePart
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		if k ~= "ClassName" then
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

-- Axis-aligned box from two corners.
function Builder.box(parent: Instance, name: string, a: Vector3, b: Vector3, color: Color3?, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local min = Vector3.new(math.min(a.X, b.X), math.min(a.Y, b.Y), math.min(a.Z, b.Z))
	local max = Vector3.new(math.max(a.X, b.X), math.max(a.Y, b.Y), math.max(a.Z, b.Z))
	local size = max - min
	local props = {
		Name = name,
		Size = Vector3.new(math.max(size.X, 0.05), math.max(size.Y, 0.05), math.max(size.Z, 0.05)),
		CFrame = CFrame.new((min + max) / 2),
		Color = color or Builder.C.Drywall,
		Material = material or Enum.Material.SmoothPlastic,
	}
	if extra then
		for k, v in extra do
			props[k] = v
		end
	end
	return Builder.part(parent, props)
end

-- Box by center + size (+ optional yaw in degrees).
function Builder.block(parent: Instance, name: string, center: Vector3, size: Vector3, color: Color3?, material: Enum.Material?, yaw: number?, extra: { [string]: any }?): BasePart
	local props = {
		Name = name,
		Size = size,
		CFrame = CFrame.new(center) * CFrame.Angles(0, math.rad(yaw or 0), 0),
		Color = color or Builder.C.Drywall,
		Material = material or Enum.Material.SmoothPlastic,
	}
	if extra then
		for k, v in extra do
			props[k] = v
		end
	end
	return Builder.part(parent, props)
end

function Builder.cylinder(parent: Instance, name: string, center: Vector3, length: number, diameter: number, color: Color3?, material: Enum.Material?, orientation: CFrame?): BasePart
	return Builder.part(parent, {
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(length, diameter, diameter),
		-- cylinders extend along X; default: stand upright
		CFrame = CFrame.new(center) * (orientation or CFrame.Angles(0, 0, math.rad(90))),
		Color = color or Builder.C.Steel,
		Material = material or Enum.Material.SmoothPlastic,
	})
end

--[[
	Axis-aligned wall with openings.
	spec = {
		x1, z1, x2, z2 : endpoints (must share X or Z)
		y0, h          : base and height
		t              : thickness (default 0.6)
		color, material
		openings = { { at = world coord along the wall, w = width, bottom = offset from y0, h = height, kind = "door"|"window"|"arch", ... } }
	}
	Returns the list of openings with computed world data:
		opening.Center  (bottom-center of the hole, on the wall plane)
		opening.Axis    ("X" if the wall runs along X, else "Z")
]]
function Builder.wall(parent: Instance, spec)
	local t = spec.t or 0.6
	local alongX = spec.z1 == spec.z2
	local a0 = alongX and math.min(spec.x1, spec.x2) or math.min(spec.z1, spec.z2)
	local a1 = alongX and math.max(spec.x1, spec.x2) or math.max(spec.z1, spec.z2)
	local fixed = alongX and spec.z1 or spec.x1
	local y0, h = spec.y0, spec.h
	local color = spec.color or Builder.C.Drywall
	local material = spec.material or Builder.M.Wall
	local name = spec.name or "Wall"

	local function piece(s0, s1, yb, yt)
		if s1 - s0 < 0.02 or yt - yb < 0.02 then
			return
		end
		local a, b
		if alongX then
			a = Vector3.new(s0, yb, fixed - t / 2)
			b = Vector3.new(s1, yt, fixed + t / 2)
		else
			a = Vector3.new(fixed - t / 2, yb, s0)
			b = Vector3.new(fixed + t / 2, yt, s1)
		end
		Builder.box(parent, name, a, b, color, material)
	end

	local openings = spec.openings or {}
	table.sort(openings, function(p, q)
		return p.at < q.at
	end)

	local cursor = a0
	for _, op in openings do
		local s0 = op.at - op.w / 2
		local s1 = op.at + op.w / 2
		local bottom = op.bottom or 0
		local top = bottom + op.h
		piece(cursor, s0, y0, y0 + h)
		piece(s0, s1, y0, y0 + bottom)
		piece(s0, s1, y0 + top, y0 + h)
		cursor = s1
		if alongX then
			op.Center = Vector3.new(op.at, y0 + bottom, fixed)
			op.Axis = "X"
		else
			op.Center = Vector3.new(fixed, y0 + bottom, op.at)
			op.Axis = "Z"
		end
		op.Thickness = t
	end
	piece(cursor, a1, y0, y0 + h)
	return openings
end

--[[
	Horizontal slab with rectangular holes.
	holes = { {x0, x1, z0, z1} }
	Uses a grid of the cut coordinates, drops cells inside holes, and merges runs along X.
]]
function Builder.slab(parent: Instance, name: string, x0: number, x1: number, z0: number, z1: number, yTop: number, thick: number, holes, color: Color3?, material: Enum.Material?)
	holes = holes or {}
	local xs, zs = { x0, x1 }, { z0, z1 }
	for _, hole in holes do
		table.insert(xs, math.clamp(hole[1], x0, x1))
		table.insert(xs, math.clamp(hole[2], x0, x1))
		table.insert(zs, math.clamp(hole[3], z0, z1))
		table.insert(zs, math.clamp(hole[4], z0, z1))
	end
	local function uniq(list)
		table.sort(list)
		local out = {}
		for _, v in list do
			if #out == 0 or math.abs(out[#out] - v) > 1e-3 then
				table.insert(out, v)
			end
		end
		return out
	end
	xs, zs = uniq(xs), uniq(zs)

	local function inHole(cx, cz)
		for _, hole in holes do
			if cx > hole[1] and cx < hole[2] and cz > hole[3] and cz < hole[4] then
				return true
			end
		end
		return false
	end

	local parts = {}
	for j = 1, #zs - 1 do
		local runStart = nil
		for i = 1, #xs do
			local solid = false
			if i < #xs then
				solid = not inHole((xs[i] + xs[i + 1]) / 2, (zs[j] + zs[j + 1]) / 2)
			end
			if solid and not runStart then
				runStart = xs[i]
			elseif not solid and runStart then
				table.insert(parts, Builder.box(parent, name,
					Vector3.new(runStart, yTop - thick, zs[j]),
					Vector3.new(xs[i], yTop, zs[j + 1]), color, material))
				runStart = nil
			end
		end
	end
	return parts
end

--[[
	Straight staircase along Z.
	Visual treads (non-colliding) + an invisible collision ramp that pathfinding and players use.
]]
function Builder.stairs(parent: Instance, name: string, x0: number, x1: number, zStart: number, zEnd: number, yStart: number, yEnd: number, color: Color3?)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	local steps = math.max(1, math.floor(math.abs(yEnd - yStart) + 0.5))
	local rise = (yEnd - yStart) / steps
	local run = (zEnd - zStart) / steps
	for i = 1, steps do
		local zA = zStart + run * (i - 1)
		local zB = zStart + run * i
		local yTop = yStart + rise * i
		if rise < 0 then
			-- descending: tread i is at the lower level
			yTop = yStart + rise * i
		end
		Builder.box(model, "Tread", Vector3.new(x0, yTop - 0.4, zA), Vector3.new(x1, yTop, zB), color or Builder.C.Oak, Builder.M.Wood, { CanCollide = false })
		-- riser
		local zr = rise > 0 and zA or zB
		Builder.box(model, "Riser", Vector3.new(x0, yTop - math.abs(rise), zr - 0.1), Vector3.new(x1, yTop - 0.4, zr + 0.1), Builder.C.Trim, Builder.M.Wood, { CanCollide = false })
	end
	-- stringers
	local low = math.min(yStart, yEnd)
	local lowZ = yStart < yEnd and zStart or zEnd
	local highZ = yStart < yEnd and zEnd or zStart
	local high = math.max(yStart, yEnd)

	-- collision ramp through the step nosings (raised half a step)
	local p0 = Vector3.new((x0 + x1) / 2, low, lowZ)
	local p1 = Vector3.new((x0 + x1) / 2, high, highZ)
	local len = (p1 - p0).Magnitude
	local mid = (p0 + p1) / 2
	local cf = CFrame.lookAt(mid, p1)
	local ramp = Builder.part(model, {
		Name = "Ramp",
		Size = Vector3.new(x1 - x0, 1, len + 1.2),
		CFrame = cf * CFrame.new(0, -0.5 + math.abs(rise) * 0.5, 0),
		Transparency = 1,
		CanCollide = true,
	})
	-- underside stringer for looks
	Builder.part(model, {
		Name = "Stringer",
		Size = Vector3.new(x1 - x0, 0.6, len),
		CFrame = cf * CFrame.new(0, -1.4, 0),
		Color = Builder.C.Trim,
		Material = Builder.M.Wood,
		CanCollide = false,
	})
	return model, ramp
end

function Builder.railing(parent: Instance, a: Vector3, b: Vector3, height: number?, color: Color3?)
	height = height or 3.4
	local dir = b - a
	local len = dir.Magnitude
	local model = Instance.new("Model")
	model.Name = "Railing"
	model.Parent = parent
	local top = Builder.part(model, {
		Name = "Handrail",
		Size = Vector3.new(0.5, 0.35, len),
		CFrame = CFrame.lookAt((a + b) / 2 + Vector3.new(0, height, 0), b + Vector3.new(0, height, 0)),
		Color = color or Builder.C.DarkWood,
		Material = Builder.M.Wood,
	})
	-- invisible blocker so nobody falls through the balusters
	Builder.part(model, {
		Name = "Blocker",
		Size = Vector3.new(0.4, height, len),
		CFrame = CFrame.lookAt((a + b) / 2 + Vector3.new(0, height / 2, 0), b + Vector3.new(0, height / 2, 0)),
		Transparency = 1,
		CanQuery = false, -- you can see through balusters
	})
	local count = math.floor(len / 1.4)
	for i = 0, count do
		local p = a + dir * (i / math.max(count, 1))
		Builder.block(model, "Baluster", p + Vector3.new(0, height / 2, 0), Vector3.new(0.25, height, 0.25), Builder.C.Trim, Builder.M.Wood)
	end
	return model, top
end

-- Window glass + frame into a wall opening (from Builder.wall).
function Builder.window(parent: Instance, op, opts)
	opts = opts or {}
	local model = Instance.new("Model")
	model.Name = opts.name or "Window"
	model.Parent = parent
	local c = op.Center + Vector3.new(0, op.h / 2, 0)
	local alongX = op.Axis == "X"
	local t = op.Thickness or 0.6
	local glassSize = alongX and Vector3.new(op.w, op.h, 0.15) or Vector3.new(0.15, op.h, op.w)
	local glass = Builder.part(model, {
		Name = "Glass",
		Size = glassSize,
		CFrame = CFrame.new(c),
		Color = Builder.C.Glass,
		Material = Builder.M.Glass,
		Transparency = 0.55,
		Reflectance = 0.15,
		CanQuery = false, -- sight passes through glass
		CastShadow = false,
	})
	-- frame
	local ft = 0.35
	local frameDepth = t + 0.3
	local function frame(offsetAlong, offsetY, w, h)
		local size = alongX and Vector3.new(w, h, frameDepth) or Vector3.new(frameDepth, h, w)
		local off = alongX and Vector3.new(offsetAlong, offsetY, 0) or Vector3.new(0, offsetY, offsetAlong)
		Builder.part(model, { Name = "Frame", Size = size, CFrame = CFrame.new(c + off), Color = Builder.C.Trim, Material = Builder.M.Wood, CanCollide = false })
	end
	frame(0, op.h / 2 - ft / 2, op.w, ft)
	frame(0, -op.h / 2 + ft / 2, op.w, ft)
	frame(op.w / 2 - ft / 2, 0, ft, op.h)
	frame(-op.w / 2 + ft / 2, 0, ft, op.h)
	frame(0, 0, 0.2, op.h) -- mullion
	-- sill
	local sillSize = alongX and Vector3.new(op.w + 0.8, 0.3, t + 1) or Vector3.new(t + 1, 0.3, op.w + 0.8)
	Builder.part(model, { Name = "Sill", Size = sillSize, CFrame = CFrame.new(op.Center + Vector3.new(0, -0.15, 0)), Color = Builder.C.Trim, Material = Builder.M.Wood })
	return model, glass
end

-- A ceiling fixture with a light. Returns bulb part and light object.
function Builder.ceilingLight(parent: Instance, pos: Vector3, opts)
	opts = opts or {}
	local model = Instance.new("Model")
	model.Name = "CeilingLight"
	model.Parent = parent
	Builder.cylinder(model, "Base", pos + Vector3.new(0, -0.15, 0), 0.3, 2.4, Builder.C.White, Builder.M.Plastic)
	local bulb = Builder.part(model, {
		Name = "Bulb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.4, 1.4, 1.4),
		CFrame = CFrame.new(pos + Vector3.new(0, -0.7, 0)),
		Color = Color3.fromRGB(255, 236, 200),
		Material = Enum.Material.Neon,
		CastShadow = false,
		CanCollide = false,
	})
	local light = Instance.new("PointLight")
	light.Range = opts.range or 24
	light.Brightness = opts.brightness or 1.1
	light.Color = opts.color or Color3.fromRGB(255, 220, 175)
	light.Shadows = opts.shadows ~= false
	light.Parent = bulb
	return bulb, light, model
end

-- Tree: trunk + canopy balls
function Builder.tree(parent: Instance, pos: Vector3, height: number?)
	height = height or 22
	local model = Instance.new("Model")
	model.Name = "Tree"
	model.Parent = parent
	Builder.cylinder(model, "Trunk", pos + Vector3.new(0, height / 2, 0), height, 2.2, Color3.fromRGB(60, 45, 35), Builder.M.Wood)
	local rng = Random.new(math.floor(pos.X * 13 + pos.Z * 7))
	for i = 1, 4 do
		local off = Vector3.new(rng:NextNumber(-4, 4), height - 2 + rng:NextNumber(-3, 4), rng:NextNumber(-4, 4))
		local s = rng:NextNumber(9, 14)
		Builder.part(model, {
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(s, s * 0.8, s),
			CFrame = CFrame.new(pos + off),
			Color = Color3.fromRGB(35 + rng:NextInteger(0, 12), 50 + rng:NextInteger(0, 12), 35),
			Material = Enum.Material.Grass,
			CanCollide = false,
			CastShadow = true,
		})
	end
	return model
end

return Builder
