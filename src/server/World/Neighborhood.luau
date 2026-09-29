--[[
	Neighborhood — the rest of Alder Lane around the Whitaker house: the neighbours' houses on
	both sides of the street (a few windows still lit), their drives, walks, mailboxes and cars,
	the telephone poles with the line that drops to the Whitakers' garage (the one he cuts),
	street signs and a bus stop, Creek Road flooded and barricaded at the west end, and the woods
	behind the back fence. None of it is enterable; it's there so the night outside feels real.
]]

local CollectionService = game:GetService("CollectionService")

local Kit = require(script.Parent.Kit)

local Neighborhood = {}

local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles

local PZ, NZ = V(0, 0, 1), V(0, 0, -1)

local function F(x: number, y: number, z: number, dir: Vector3): CFrame
	return CFrame.lookAt(V(x, y, z), V(x, y, z) + dir)
end

local CONCRETE = Color3.fromRGB(135, 135, 130)

-- { x, W, D, stories, siding, roof, door, lit windows, garage, porch, chimney, car colour or nil }
local NORTH = {
	{ -115, 34, 24, 2, Color3.fromRGB(176, 160, 132), Color3.fromRGB(58, 50, 46), Color3.fromRGB(40, 60, 70), { [2] = true }, true, false, true, Color3.fromRGB(80, 80, 86) },
	{ -180, 30, 22, 1, Color3.fromRGB(120, 130, 120), Color3.fromRGB(46, 46, 50), Color3.fromRGB(120, 40, 36), {}, false, true, false, nil },
	{ 172, 30, 24, 2, Color3.fromRGB(196, 184, 160), Color3.fromRGB(62, 52, 46), Color3.fromRGB(30, 50, 40), { [4] = true, [5] = true }, true, false, true, Color3.fromRGB(150, 150, 156) },
	{ 232, 32, 22, 1, Color3.fromRGB(150, 110, 90), Color3.fromRGB(50, 46, 44), Color3.fromRGB(236, 232, 224), {}, true, true, false, nil },
}
local SOUTH = {
	{ -150, 32, 24, 2, Color3.fromRGB(140, 150, 166), Color3.fromRGB(46, 48, 54), Color3.fromRGB(120, 40, 36), { [1] = true }, true, false, false, Color3.fromRGB(110, 30, 30) },
	{ -80, 30, 22, 1, Color3.fromRGB(206, 196, 170), Color3.fromRGB(60, 52, 46), Color3.fromRGB(40, 60, 90), {}, false, true, true, nil },
	{ -10, 34, 24, 2, Color3.fromRGB(110, 120, 110), Color3.fromRGB(44, 44, 48), Color3.fromRGB(236, 232, 224), { [3] = true, [6] = true }, true, true, false, nil },
	{ 55, 30, 22, 2, Color3.fromRGB(180, 150, 120), Color3.fromRGB(56, 48, 44), Color3.fromRGB(40, 40, 44), {}, true, false, true, Color3.fromRGB(40, 70, 60) },
	{ 130, 32, 24, 1, Color3.fromRGB(150, 160, 170), Color3.fromRGB(50, 50, 54), Color3.fromRGB(120, 40, 36), { [2] = true }, false, true, false, nil },
	{ 200, 34, 24, 2, Color3.fromRGB(196, 176, 150), Color3.fromRGB(58, 50, 46), Color3.fromRGB(30, 50, 40), {}, true, false, true, nil },
}

function Neighborhood.build(ctx, root: Instance)
	local B = ctx.Builder
	local M = B.M
	local KM = Kit.M
	local f = Instance.new("Folder")
	f.Name = "Neighborhood"
	f.Parent = root

	local function box(name, x0, y0, z0, x1, y1, z1, color, mat, extra)
		return B.box(f, name, V(math.min(x0, x1), y0, math.min(z0, z1)), V(math.max(x0, x1), y1, math.max(z0, z1)), color, mat, extra)
	end

	---------------------------------------------------------------------------
	-- The neighbours' houses
	---------------------------------------------------------------------------
	local function lot(spec, north: boolean, i: number)
		local x, W, D = spec[1], spec[2], spec[3]
		local front = north and -34 or -108 -- the front wall's z
		local cz = north and (front + D / 2) or (front - D / 2)
		local facing = north and NZ or PZ
		Kit.suburbHouse(f, F(x, 0.5, cz, facing), {
			Name = "NeighborHouse",
			W = W,
			D = D,
			Stories = spec[4],
			Siding = spec[5],
			Roof = spec[6],
			Door = spec[7],
			Lit = spec[8],
			Garage = spec[9],
			Porch = spec[10],
			Chimney = spec[11],
			PorchLight = next(spec[8]) ~= nil,
		})
		-- the house's local +X in world X: +X when it faces -Z (north side), -X when it faces +Z
		local side = north and 1 or -1
		local sidewalkEdge = north and -62 or -102
		local doorX = x + side * (spec[9] and -6 or 0)
		-- front walk from the steps to the sidewalk
		local stepZ = front + (north and -2.7 or 2.7)
		box("Walk", doorX - 1.8, 0, stepZ, doorX + 1.8, 0.58, sidewalkEdge, CONCRETE, M.Concrete)
		-- driveway to the garage (or beside the house)
		local gx = spec[9] and (x + side * (W / 2 - 6)) or (x - side * (W / 2 + 6))
		box("Driveway", gx - 5, 0, front, gx + 5, 0.6, sidewalkEdge, Color3.fromRGB(96, 96, 96), M.Concrete)
		if spec[12] then
			local carZ = (front + sidewalkEdge) / 2
			Kit.sedan(f, F(gx, 0.6, carZ, north and PZ or NZ), spec[12])
		end
		-- mailbox by the sidewalk, facing the street
		Kit.mailbox(f, F(doorX + 3.5, 0.5, sidewalkEdge + (north and 1.2 or -1.2), north and NZ or PZ), Color3.fromHSV((i * 0.17) % 1, 0.3, 0.3))
		-- a couple of shrubs along the front
		for k, dx in { -W / 2 + 4, W / 2 - 4 } do
			if not (spec[9] and math.abs((x + side * dx) - gx) < 7) then
				Kit.shrub(f, F(x + side * dx, 0.55, front + (north and -2.4 or 2.4), facing), 2.6, i * 10 + k)
			end
		end
	end
	for i, spec in NORTH do
		lot(spec, true, i)
	end
	for i, spec in SOUTH do
		lot(spec, false, i + 10)
	end

	---------------------------------------------------------------------------
	-- Telephone poles along the north side, and the line down to the Whitakers' garage
	---------------------------------------------------------------------------
	local poles = {}
	for _, x in { -235, -178, -125, -70, -15, 38, 90, 150, 205 } do
		local _, a, b = Kit.telephonePole(f, V(x, 0.5, -60.8), 26)
		table.insert(poles, { a, b })
	end
	for i = 1, #poles - 1 do
		Kit.wire(f, poles[i][1], poles[i + 1][1], 1.6)
		Kit.wire(f, poles[i][2], poles[i + 1][2], 1.8)
	end
	-- the phone drop: from the pole by the drive to the garage's east wall, above the junction box
	local jb = ctx.Layout.Outside.JunctionBox
	Kit.wire(f, poles[6][2], V(jb.X + 0.3, 14.5, jb.Z), 1.4)
	Kit.box(f, "DropConduit", CF(jb.X + 0.25, 10, jb.Z), V(0.2, 9, 0.2), Color3.fromRGB(60, 60, 62), KM.Metal)

	---------------------------------------------------------------------------
	-- Street furniture
	---------------------------------------------------------------------------
	Kit.busStop(f, F(20, 0.6, -100.2, PZ))
	for _, x in { -60, 100, 180 } do
		Kit.hydrant(f, F(x, 0.6, -100.5, PZ))
	end
	Kit.roadSign(f, F(-203, 0.6, -99.5, PZ), "ALDER LN", nil, nil, 5, 1.2)
	Kit.roadSign(f, F(-203.4, 0.6, -99.5, V(1, 0, 0)) * CF(0, 1.5, 0), "CREEK RD", nil, nil, 5, 1.2)
	Kit.roadSign(f, F(-40, 0.6, -63.2, NZ), "SPEED LIMIT\n25", Color3.fromRGB(236, 236, 232), Color3.fromRGB(20, 20, 20), 2.4, 3)

	---------------------------------------------------------------------------
	-- Creek Road: south off Alder Lane, under water past the barricade
	---------------------------------------------------------------------------
	box("CreekRoad", -226, 0, -200, -204, 0.63, -96.5, Color3.fromRGB(38, 38, 42), M.Asphalt)
	for z = -196, -104, 10 do
		box("CreekLane", -215.3, 0.63, z, -214.7, 0.66, z + 5, Color3.fromRGB(200, 180, 90), M.Plastic, { CanCollide = false })
	end
	-- the water: the road dips into it and it spreads over the verges
	local water = box("FloodWater", -250, 0, -205, -180, 1.25, -140, Color3.fromRGB(58, 66, 70), M.Glass, { CanCollide = false, CanQuery = false })
	water.Transparency = 0.25
	water.Reflectance = 0.25
	for k = 0, 5 do
		box("Ripple", -246 + k * 11, 1.26, -146 - k * 9, -236 + k * 11, 1.28, -145.6 - k * 9, Color3.fromRGB(150, 160, 164), M.Plastic, { CanCollide = false, CanQuery = false })
	end
	-- debris caught at the edge
	Kit.box(f, "Branch", CF(-212, 1.3, -142) * ANG(0, 0.6, 0.08), V(7, 0.5, 0.5), Color3.fromRGB(70, 50, 36), KM.Wood)
	Kit.box(f, "Branch", CF(-221, 1.3, -147) * ANG(0, -0.9, 0), V(4, 0.4, 0.4), Color3.fromRGB(80, 60, 40), KM.Wood)
	-- barricade and signs
	local _, blinkers = Kit.barricade(f, F(-215, 0.63, -126, PZ), 18)
	for _, b in blinkers do
		local l = Instance.new("PointLight")
		l.Range = 12
		l.Brightness = 1.4
		l.Color = Color3.fromRGB(255, 160, 40)
		l.Shadows = false
		l.Parent = b
		CollectionService:AddTag(l, "Flicker")
	end
	Kit.roadSign(f, F(-215, 0.63, -123.5, PZ) * CF(0, -3.4, 0), "ROAD CLOSED\nFLOODING", Color3.fromRGB(230, 120, 30), Color3.fromRGB(20, 20, 20), 6, 2.4)
	-- a stalled car, water to its doors
	Kit.sedan(f, F(-218, 0.8, -168, NZ) * ANG(0, 0.3, 0.04), Color3.fromRGB(60, 70, 80))

	---------------------------------------------------------------------------
	-- The woods behind the back fence
	---------------------------------------------------------------------------
	local rng = Random.new(2718)
	local existing = { V(-45, 0, 72), V(30, 0, 96), V(-60, 0, 110), V(60, 0, 120), V(0, 0, 130), V(-140, 0, 60), V(175, 0, 90) }
	local placed = 0
	local tries = 0
	while placed < 34 and tries < 400 do
		tries += 1
		local p = V(rng:NextNumber(-150, 150), 0, rng:NextNumber(92, 175))
		local ok = true
		for _, q in existing do
			if (V(p.X, 0, p.Z) - V(q.X, 0, q.Z)).Magnitude < 13 then
				ok = false
				break
			end
		end
		if ok then
			table.insert(existing, p)
			placed += 1
			if rng:NextNumber() < 0.75 then
				Kit.pine(f, V(p.X, 0.5, p.Z), rng:NextNumber(26, 38), placed)
			else
				Kit.tree(f, V(p.X, 0.5, p.Z), rng:NextNumber(22, 28), placed)
			end
		end
	end
	for k = 1, 16 do
		Kit.shrub(f, F(rng:NextNumber(-140, 140), 0.55, rng:NextNumber(86, 110), PZ), rng:NextNumber(2.4, 4), 300 + k)
	end

	return f
end

return Neighborhood
