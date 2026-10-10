--[[
	Burrow — what Curtis dug under the house in nineteen days (the secret ending, FinaleService).

	Under the basement, reached by a hole behind the boiler: a candlelit "dining room" with a
	table set for the family, tunnels shored up with stolen lumber, a pantry of food taken from
	the kitchen, a nursery of dolls dressed like the kids, his own room (the tally marks, the
	newspaper cuttings), and the old storm cellar under the back yard, whose grate opens onto the
	lawn. Floors at y = -30, ceilings at -20: far below anything else, so nothing above notices.

	Built with the house (it costs nothing until the finale). Returns everything FinaleService
	needs: seats, his spots, doors, the keypad, notes, the patrol graph, the hiding nooks, lights.
	The grate on the lawn is there every night (with a note of its own: a hint).
]]

local Burrow = {}

local V = Vector3.new
local CF = CFrame.new
local rad = math.rad

Burrow.FloorY = -30
Burrow.Height = 10
Burrow.Grate = V(4, 0.5, 52)

local EARTH = Color3.fromRGB(74, 58, 44)
local EARTH_DARK = Color3.fromRGB(56, 44, 34)
local MUD = Color3.fromRGB(62, 50, 39)
local TIMBER = Color3.fromRGB(96, 72, 50)
local CONCRETE = Color3.fromRGB(112, 110, 104)

--[[
	A room: floor, ceiling and four walls with doorways cut out.
	openings: { { Side = "N"|"S"|"E"|"W", At = coordinate along the wall, W = width } }
	N/S walls run along X at z1/z0; E/W walls along Z at x1/x0 (each 1 thick, outside the room).
	opts.Tunnel = "X" | "Z": a tunnel between two rooms' outer wall faces: only its two long
	walls, floor and ceiling (its open ends are the rooms' doorways). opts.Gaps: openings in the
	long walls for alcoves, { { Side = "N"|"S" (X tunnel) or "E"|"W" (Z tunnel), At, W } }.
]]
local function space(B, parent, name: string, x0: number, x1: number, z0: number, z1: number, openings, opts)
	opts = opts or {}
	if opts.Tunnel then
		local Y0 = Burrow.FloorY
		local H0 = opts.Height or 9
		local wc, wm = opts.Wall or EARTH, opts.WallMat or Enum.Material.Ground
		-- a long wall from a0 to a1 (along the tunnel), with any alcove openings cut out of it
		local GAP_H = 7
		local function longWall(side: string, a0: number, a1: number, box: (number, number, number, number) -> ())
			local gaps = {}
			for _, g in opts.Gaps or {} do
				if g.Side == side then
					table.insert(gaps, { g.At - g.W / 2, g.At + g.W / 2 })
				end
			end
			table.sort(gaps, function(p, q)
				return p[1] < q[1]
			end)
			local cursor = a0
			for _, g in gaps do
				box(cursor, g[1], Y0, Y0 + H0)
				box(g[1], g[2], Y0 + GAP_H, Y0 + H0) -- (the lintel over the alcove)
				cursor = g[2]
			end
			box(cursor, a1, Y0, Y0 + H0)
		end
		if opts.Tunnel == "X" then
			B.box(parent, name .. "Floor", V(x0, Y0 - 1, z0 - 1), V(x1, Y0, z1 + 1), MUD, Enum.Material.Mud)
			B.box(parent, name .. "Ceiling", V(x0, Y0 + H0, z0 - 1), V(x1, Y0 + H0 + 1, z1 + 1), EARTH_DARK, Enum.Material.Ground)
			longWall("S", x0, x1, function(a, b, y0, y1)
				if b - a > 0.05 then
					B.box(parent, name .. "Wall", V(a, y0, z0 - 1), V(b, y1, z0), wc, wm)
				end
			end)
			longWall("N", x0, x1, function(a, b, y0, y1)
				if b - a > 0.05 then
					B.box(parent, name .. "Wall", V(a, y0, z1), V(b, y1, z1 + 1), wc, wm)
				end
			end)
		else
			B.box(parent, name .. "Floor", V(x0 - 1, Y0 - 1, z0), V(x1 + 1, Y0, z1), MUD, Enum.Material.Mud)
			B.box(parent, name .. "Ceiling", V(x0 - 1, Y0 + H0, z0), V(x1 + 1, Y0 + H0 + 1, z1), EARTH_DARK, Enum.Material.Ground)
			longWall("W", z0, z1, function(a, b, y0, y1)
				if b - a > 0.05 then
					B.box(parent, name .. "Wall", V(x0 - 1, y0, a), V(x0, y1, b), wc, wm)
				end
			end)
			longWall("E", z0, z1, function(a, b, y0, y1)
				if b - a > 0.05 then
					B.box(parent, name .. "Wall", V(x1, y0, a), V(x1 + 1, y1, b), wc, wm)
				end
			end)
		end
		return
	end
	local Y = Burrow.FloorY
	local H = opts.Height or Burrow.Height
	local wallC = opts.Wall or EARTH
	local wallM = opts.WallMat or Enum.Material.Ground
	local floorC = opts.Floor or MUD
	local floorM = opts.FloorMat or Enum.Material.Mud
	local T = 1
	B.box(parent, name .. "Floor", V(x0 - T, Y - 1, z0 - T), V(x1 + T, Y, z1 + T), floorC, floorM)
	B.box(parent, name .. "Ceiling", V(x0 - T, Y + H, z0 - T), V(x1 + T, Y + H + 1, z1 + T), opts.Ceiling or EARTH_DARK, opts.CeilingMat or Enum.Material.Ground)
	local DOOR_H = opts.DoorH or 8
	local function wall(side: string, a0: number, a1: number, fixed: number)
		local gaps = {}
		for _, o in openings or {} do
			if o.Side == side then
				table.insert(gaps, { o.At - o.W / 2, o.At + o.W / 2 })
			end
		end
		table.sort(gaps, function(p, q)
			return p[1] < q[1]
		end)
		local function seg(s0: number, s1: number, y0: number, y1: number)
			if s1 - s0 < 0.05 then
				return
			end
			if side == "N" or side == "S" then
				local z = fixed
				local zz = side == "N" and z + T or z - T
				B.box(parent, name .. "Wall", V(s0, y0, math.min(z, zz)), V(s1, y1, math.max(z, zz)), wallC, wallM)
			else
				local x = fixed
				local xx = side == "E" and x + T or x - T
				B.box(parent, name .. "Wall", V(math.min(x, xx), y0, s0), V(math.max(x, xx), y1, s1), wallC, wallM)
			end
		end
		local cursor = a0
		for _, g in gaps do
			seg(cursor, g[1], Y, Y + H)
			seg(g[1], g[2], Y + DOOR_H, Y + H) -- (the lintel over the doorway)
			cursor = g[2]
		end
		seg(cursor, a1, Y, Y + H)
	end
	wall("N", x0 - T, x1 + T, z1)
	wall("S", x0 - T, x1 + T, z0)
	wall("E", z0, z1, x1)
	wall("W", z0, z1, x0)
end

-- timber shoring every few studs along a tunnel (posts on both walls, a beam overhead)
local function shoring(Kit, parent, a: Vector3, b: Vector3, width: number, step: number)
	local d = b - a
	local len = d.Magnitude
	local dir = d.Unit
	local across = V(-dir.Z, 0, dir.X)
	local Y = Burrow.FloorY
	local n = math.floor(len / step)
	for i = 1, n - 1 do
		local p = a + dir * (i * step)
		for _, s in { -1, 1 } do
			local q = p + across * s * (width / 2 - 0.35)
			Kit.box(parent, "Post", CF(q.X, Y + 3.9, q.Z), V(0.7, 7.8, 0.7), TIMBER, Enum.Material.Wood)
		end
		local beam = CFrame.lookAt(V(p.X, Y + 8.15, p.Z), V(p.X, Y + 8.15, p.Z) + across)
		Kit.box(parent, "Beam", beam, V(0.7, 0.7, width - 0.2), TIMBER, Enum.Material.Wood)
	end
end

-- a bare bulb on a cord, dim and warm (some of them flicker)
local function bulb(Kit, parent, at: Vector3, lights: { PointLight }, flicker: boolean?)
	local Y = Burrow.FloorY
	Kit.box(parent, "Cord", CF(at.X, Y + 8.6, at.Z), V(0.05, 2.8, 0.05), Color3.fromRGB(20, 20, 20))
	local b = Kit.ball(parent, "Bulb", V(at.X, Y + 7.1, at.Z), 0.36, Color3.fromRGB(255, 200, 130), Enum.Material.Neon)
	local l = Instance.new("PointLight")
	l.Range = 18
	l.Brightness = 1
	l.Color = Color3.fromRGB(255, 176, 100)
	l.Shadows = true
	l.Parent = b
	if flicker then
		game:GetService("CollectionService"):AddTag(l, "Flicker")
	end
	table.insert(lights, l)
	return b
end

local function sign(parent: BasePart, face: Enum.NormalId, text: string, size: number, color: Color3, font: Enum.Font?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 1
	gui.Parent = parent
	local l = Instance.new("TextLabel")
	l.Name = "Text"
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = font or Enum.Font.PermanentMarker
	l.TextColor3 = color
	l.TextSize = size
	l.TextWrapped = true
	l.Text = text
	l.Parent = gui
	return l
end

function Burrow.build(ctx, parent: Instance)
	local B = ctx.Builder
	local Kit = require(script.Parent.Kit)
	local f = Instance.new("Folder")
	f.Name = "Burrow"
	f.Parent = parent
	local Y = Burrow.FloorY
	local lights: { PointLight } = {}
	local R: any = { Folder = f, FloorY = Y, Lights = lights, Notes = {}, Lore = {}, Seats = {}, Rooms = {}, Nooks = {} }

	---------------------------------------------------------------------------
	-- The spaces
	---------------------------------------------------------------------------
	space(B, f, "Dining", -38, -16, 6, 28, { { Side = "E", At = 17, W = 5 } }, { Wall = Color3.fromRGB(84, 66, 50), Floor = Color3.fromRGB(70, 56, 42), FloorMat = Enum.Material.WoodPlanks })
	space(B, f, "Junction1", 0, 8, 13, 21, { { Side = "W", At = 17, W = 6 }, { Side = "N", At = 4, W = 6 }, { Side = "S", At = 4, W = 6 }, { Side = "E", At = 17, W = 6 } }, { Height = 9 })
	space(B, f, "Junction2", 0, 8, -9, -1, { { Side = "N", At = 4, W = 6 }, { Side = "W", At = -5, W = 6 }, { Side = "E", At = -5, W = 6 } }, { Height = 9 })
	space(B, f, "Cellar", -6, 14, 40, 58, { { Side = "S", At = 4, W = 5 } }, { Wall = CONCRETE, WallMat = Enum.Material.Concrete, Floor = Color3.fromRGB(96, 94, 88), FloorMat = Enum.Material.Concrete, Ceiling = Color3.fromRGB(90, 88, 84), CeilingMat = Enum.Material.Concrete })
	space(B, f, "Nursery", -30, -12, -14, 4, { { Side = "E", At = -5, W = 5 } }, { Wall = Color3.fromRGB(150, 120, 120), WallMat = Enum.Material.Fabric })
	space(B, f, "HisRoom", 18, 34, -14, 4, { { Side = "W", At = -5, W = 5 } })
	space(B, f, "Pantry", 18, 30, 10, 24, { { Side = "W", At = 17, W = 5 } })
	-- the tunnels between them (each from one room's outer wall face to the next)
	-- (each tunnel has an alcove or two dug into its wall: ALCOVES, below)
	local ALCOVES = {
		{ Tunnel = "TunnelA", Side = "N", At = -8 },
		{ Tunnel = "TunnelNorth", Side = "W", At = 34.5 },
		{ Tunnel = "TunnelNorth", Side = "E", At = 25 },
		{ Tunnel = "TunnelSouth", Side = "W", At = 3.5 },
		{ Tunnel = "TunnelWest", Side = "S", At = -8.5 },
		{ Tunnel = "TunnelEast", Side = "N", At = 13 },
		{ Tunnel = "TunnelPantry", Side = "S", At = 13 },
	}
	local function gapsFor(t: string)
		local out = {}
		for _, a in ALCOVES do
			if a.Tunnel == t then
				table.insert(out, { Side = a.Side, At = a.At, W = 3 })
			end
		end
		return out
	end
	local TUNNELS = {
		TunnelA = { -15, -1, 14, 20, "X" },
		TunnelNorth = { 1, 7, 22, 39, "Z" },
		TunnelSouth = { 1, 7, 0, 12, "Z" },
		TunnelWest = { -11, -1, -8, -2, "X" },
		TunnelEast = { 9, 17, -8, -2, "X" },
		TunnelPantry = { 9, 17, 14, 20, "X" },
	}
	for tname, t in TUNNELS do
		space(B, f, tname, t[1], t[2], t[3], t[4], nil, { Tunnel = t[5], Gaps = gapsFor(tname) })
	end
	R.Rooms = {
		Dining = { Min = V(-38, Y, 6), Max = V(-16, Y + 10, 28) },
		Pantry = { Min = V(18, Y, 10), Max = V(30, Y + 10, 24) },
		Nursery = { Min = V(-30, Y, -14), Max = V(-12, Y + 10, 4) },
		HisRoom = { Min = V(18, Y, -14), Max = V(34, Y + 10, 4) },
		Cellar = { Min = V(-6, Y, 40), Max = V(14, Y + 10, 58) },
	}
	R.Bounds = { Min = V(-40, Y - 2, -16), Max = V(36, Y + 12, 60) }

	-- shoring and bulbs down every tunnel
	for _, t in {
		{ V(-15, 0, 17), V(-1, 0, 17), 6 },
		{ V(4, 0, 22), V(4, 0, 39), 6 },
		{ V(4, 0, 12), V(4, 0, 0), 6 },
		{ V(-1, 0, -5), V(-11, 0, -5), 6 },
		{ V(9, 0, -5), V(17, 0, -5), 6 },
		{ V(9, 0, 17), V(17, 0, 17), 6 },
	} do
		local a, b = V(t[1].X, Y, t[1].Z), V(t[2].X, Y, t[2].Z)
		shoring(Kit, f, a, b, t[3], 5)
	end
	for i, p in { V(-8, 0, 17), V(4, 0, 17), V(4, 0, 30), V(4, 0, 5), V(4, 0, -5), V(-6, 0, -5), V(13, 0, -5), V(13, 0, 17) } do
		bulb(Kit, f, p, lights, i % 3 == 0)
	end
	-- roots through the ceiling, puddles, a few planks on the tunnel floors
	local rng = Random.new(1919)
	for _ = 1, 26 do
		local spots = { { -14, -2, 15, 19 }, { 2, 6, 23, 38 }, { 2, 6, 1, 11 }, { -10, -2, -7, -3 }, { 10, 16, -7, -3 }, { 10, 16, 15, 19 } }
		local s = spots[rng:NextInteger(1, #spots)]
		local x, z = rng:NextNumber(s[1], s[2]), rng:NextNumber(s[3], s[4])
		Kit.box(f, "Root", CF(x, Y + 8.6, z) * CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)), V(0.18, rng:NextNumber(1.2, 2.6), 0.18), Color3.fromRGB(60, 44, 32), Enum.Material.Wood)
	end
	for _, p in { { -6, 16 }, { 4, 34 }, { 3, 2 }, { -9, -4 } } do
		Kit.ellipsoid(f, "Puddle", CF(p[1], Y + 0.02, p[2]), V(rng:NextNumber(2, 3.5), 0.03, rng:NextNumber(1.5, 2.5)), Color3.fromRGB(34, 32, 30), Enum.Material.Glass, { Reflectance = 0.3 })
	end

	---------------------------------------------------------------------------
	-- The dining room: the family dinner
	---------------------------------------------------------------------------
	local TC = V(-27, Y, 17)
	R.TableCenter = TC + V(0, 3.8, 0)
	Kit.rug(f, CF(TC.X, Y, TC.Z), 18, 9, Color3.fromRGB(96, 40, 36))
	Kit.diningTable(f, CF(TC.X, Y, TC.Z), 14, 4.6, Color3.fromRGB(110, 76, 50))
	local tableTop = Y + 3.8
	-- four places for the kids, and his at the head
	local seatSpots = {
		{ V(-31, Y, 20.4), V(0, 0, -1) },
		{ V(-23, Y, 20.4), V(0, 0, -1) },
		{ V(-31, Y, 13.6), V(0, 0, 1) },
		{ V(-23, Y, 13.6), V(0, 0, 1) },
	}
	local cardColor = Color3.fromRGB(240, 232, 214)
	for i, sp in seatSpots do
		local pos, dir = sp[1], sp[2]
		local cf = CFrame.lookAt(pos, pos + dir)
		local chair = Kit.chair(f, cf, Color3.fromRGB(120, 90, 62), Color3.fromRGB(140, 50, 46))
		local seat = Instance.new("Seat")
		seat.Name = "FinaleSeat" .. i
		seat.Size = V(1.9, 0.3, 1.9)
		seat.CFrame = cf * CF(0, 2.0, 0)
		seat.Anchored = true
		seat.CanCollide = false
		seat.CanQuery = false
		seat.CanTouch = false
		seat.Transparency = 1
		seat.Disabled = true
		seat.Parent = chair
		-- the place setting, and a folded card with a name on it
		local plateAt = pos + dir * 1.55
		Kit.plate(f, CF(plateAt.X, tableTop + 0.02, plateAt.Z), 1.1)
		for _, s in { -1, 1 } do
			local side = V(dir.Z, 0, -dir.X) * s * 0.95
			Kit.box(f, s < 0 and "Fork" or "Knife", CF(plateAt.X + side.X, tableTop + 0.03, plateAt.Z + side.Z) * CFrame.Angles(0, dir.X ~= 0 and 0 or rad(90), 0), V(0.08, 0.03, 0.9), Color3.fromRGB(190, 190, 194), Enum.Material.Metal)
		end
		local cardAt = pos + dir * 2.3
		local card = Kit.box(f, "PlaceCard", CFrame.lookAt(V(cardAt.X, tableTop + 0.3, cardAt.Z), V(cardAt.X, tableTop + 0.3, cardAt.Z) - dir) * CFrame.Angles(rad(-15), 0, 0), V(1.1, 0.55, 0.04), cardColor, Enum.Material.Fabric)
		local label = sign(card, Enum.NormalId.Front, "", 18, Color3.fromRGB(120, 20, 20))
		table.insert(R.Seats, { Index = i, Chair = chair, Seat = seat, Pos = pos, Dir = dir, Card = label })
	end
	-- his chair, at the head of the table
	local headPos = V(-35.2, Y, 17)
	Kit.chair(f, CFrame.lookAt(headPos, headPos + V(1, 0, 0)), Color3.fromRGB(70, 50, 36), Color3.fromRGB(40, 40, 44))
	R.Head = headPos
	-- the food: the pizza you ordered (two slices gone), candles, glasses of milk
	local box = Kit.box(f, "PizzaBox", CF(TC.X, tableTop + 0.12, TC.Z), V(2.6, 0.22, 2.6), Color3.fromRGB(196, 170, 130), Enum.Material.Cardboard)
	sign(box, Enum.NormalId.Top, "TONY'S", 40, Color3.fromRGB(190, 40, 30), Enum.Font.GothamBlack)
	for _, x in { -32.5, -27, -21.5 } do
		Kit.candle(f, CF(x, tableTop, TC.Z + (x == -27 and 1.7 or 0)), 1.2, 0.3, true)
	end
	for i, sp in seatSpots do
		local g = sp[1] + sp[2] * 1.6 + V(i % 2 == 0 and 0.9 or -0.9, 0, 0)
		Kit.vcyl(f, "Glass", CF(g.X, tableTop + 0.35, g.Z), 0.7, 0.36, Color3.fromRGB(240, 240, 236), Enum.Material.Glass, { Transparency = 0.2 })
	end
	-- a bare bulb over the table and fairy lights strung across
	bulb(Kit, f, V(TC.X, 0, TC.Z), lights, false).Parent = f
	Kit.stringLights(f, V(-37, Y + 9.3, 9), V(-17, Y + 9.3, 25), 1.2, 22, Color3.fromRGB(255, 190, 120))
	Kit.stringLights(f, V(-37, Y + 9.3, 25), V(-17, Y + 9.3, 9), 1.2, 22, Color3.fromRGB(255, 190, 120))
	-- the chalkboard: the rules
	local board = Kit.solid(f, "Chalkboard", CF(-37.45, Y + 5.2, 17) * CFrame.Angles(0, rad(90), 0), V(10, 5.5, 0.25), Color3.fromRGB(30, 40, 34), Enum.Material.Slate)
	Kit.box(f, "ChalkFrame", CF(-37.4, Y + 5.2, 17) * CFrame.Angles(0, rad(90), 0), V(10.6, 6.1, 0.15), TIMBER, Enum.Material.Wood)
	R.Chalk = sign(board, Enum.NormalId.Front, "FAMILY DINNER\n\n1. NOBODY LEAVES THE TABLE\n2. NO SQUIRMING\n3. FATHER IS WATCHING", 30, Color3.fromRGB(235, 235, 225), Enum.Font.PermanentMarker)
	-- the photo wall: the family, nineteen days of it
	for row = 0, 3 do
		for col = 0, 7 do
			local x = -35 + col * 2.4 + rng:NextNumber(-0.2, 0.2)
			local yy = Y + 3.3 + row * 1.6
			local frame = Kit.box(f, "Polaroid", CF(x, yy, 27.45) * CFrame.Angles(0, 0, rad(rng:NextNumber(-8, 8))), V(1.3, 1.5, 0.04), Color3.fromRGB(240, 238, 230), Enum.Material.Plastic)
			Kit.box(f, "PolaroidImage", frame.CFrame * CF(0, 0.12, -0.03), V(1.1, 1.0, 0.02), Color3.fromRGB(rng:NextInteger(40, 90), rng:NextInteger(40, 80), rng:NextInteger(40, 80)), Enum.Material.Plastic)
		end
	end
	-- the stove corner: where he stands with his back to you
	local stoveAt = V(-18.5, Y, 25.6)
	Kit.cardboardBox(f, CF(stoveAt.X, Y, stoveAt.Z), V(3.4, 3, 2.4), Color3.fromRGB(120, 92, 60), true)
	Kit.box(f, "CampStove", CF(stoveAt.X, Y + 3.2, stoveAt.Z), V(2, 0.4, 1.4), Color3.fromRGB(40, 70, 50), Enum.Material.Metal)
	Kit.vcyl(f, "Pot", CF(stoveAt.X - 0.4, Y + 3.8, stoveAt.Z), 0.9, 1.1, Color3.fromRGB(80, 80, 84), Enum.Material.Metal)
	local flame = Kit.ball(f, "StoveFlame", V(stoveAt.X + 0.55, Y + 3.5, stoveAt.Z), 0.35, Color3.fromRGB(80, 140, 255), Enum.Material.Neon)
	local fl = Instance.new("PointLight")
	fl.Range = 9
	fl.Brightness = 0.8
	fl.Color = Color3.fromRGB(120, 160, 255)
	fl.Parent = flame
	R.Stove = V(-19.5, Y, 22.6)
	R.StoveLook = V(-19.5, Y, 30)
	-- the way you came down: a ladder to a hatch in the boiler room floor (locked from above)
	for _, s in { -1, 1 } do
		Kit.box(f, "LadderRail", CF(-34 + s * 0.9, Y + 5, 26.6), V(0.2, 10, 0.2), TIMBER, Enum.Material.Wood)
	end
	for k = 1, 9 do
		Kit.box(f, "Rung", CF(-34, Y + k, 26.6), V(1.8, 0.16, 0.16), TIMBER, Enum.Material.Wood)
	end
	Kit.box(f, "HatchUnderside", CF(-34, Y + 9.9, 26.2), V(3, 0.2, 3), Color3.fromRGB(60, 50, 40), Enum.Material.WoodPlanks)
	R.Ladder = V(-34, Y, 25)
	-- the door out of the dining room: heavy planks, barred from the tunnel side
	local door = Kit.solid(f, "DiningDoor", CF(-16, Y + 4, 17), V(0.6, 8, 5), Color3.fromRGB(80, 60, 42), Enum.Material.WoodPlanks)
	R.DiningDoor = { Part = door, Closed = door.CFrame, Open = CF(-16, Y + 4, 17) * CF(0, 0, -2.5) * CFrame.Angles(0, rad(-95), 0) * CF(0, 0, 2.5) }

	---------------------------------------------------------------------------
	-- The pantry: everything that went missing from the kitchen
	---------------------------------------------------------------------------
	Kit.shelving(f, CFrame.lookAt(V(29, Y, 17), V(20, Y, 17)), 10, 2, 8, 4, 7)
	Kit.shelving(f, CFrame.lookAt(V(24, Y, 23.2), V(24, Y, 14)), 9, 2, 8, 4, 11)
	for k = 0, 4 do
		Kit.box(f, "PizzaBox", CF(21.5, Y + 0.12 + k * 0.24, 11.8) * CFrame.Angles(0, rad(k * 7), 0), V(2.6, 0.22, 2.6), Color3.fromRGB(196, 170, 130), Enum.Material.Cardboard)
	end
	local lasagna = Kit.box(f, "LasagnaDish", CF(25, Y + 3.3, 13.2), V(1.6, 0.36, 0.9), Color3.fromRGB(210, 214, 218), Enum.Material.Metal)
	R.Lasagna = lasagna
	Kit.cardboardBox(f, CF(26, Y, 12), V(3, 3, 2.4), Color3.fromRGB(150, 120, 80), true)
	R.Notes.Pantry = Kit.solid(f, "Note1", CF(26, Y + 3.05, 12) * CFrame.Angles(0, rad(20), 0), V(1.3, 0.04, 1.7), Color3.fromRGB(236, 230, 210), Enum.Material.Fabric)
	bulb(Kit, f, V(24, 0, 17), lights, true)

	---------------------------------------------------------------------------
	-- The nursery: dolls dressed like the kids
	---------------------------------------------------------------------------
	local crib = Kit.model(f, "Crib")
	local cribAt = V(-26, Y, -10)
	for _, s in { -1, 1 } do
		for k = -3, 3 do
			Kit.box(crib, "CribBar", CF(cribAt.X + k * 0.6, Y + 2.2, cribAt.Z + s * 1.4), V(0.12, 2.6, 0.12), Color3.fromRGB(236, 230, 220), Enum.Material.Wood)
		end
		Kit.box(crib, "CribRail", CF(cribAt.X, Y + 3.5, cribAt.Z + s * 1.4), V(4.4, 0.2, 0.2), Color3.fromRGB(236, 230, 220), Enum.Material.Wood)
	end
	Kit.box(crib, "CribBase", CF(cribAt.X, Y + 1.2, cribAt.Z), V(4.4, 0.4, 3), Color3.fromRGB(236, 230, 220), Enum.Material.Wood)
	Kit.box(crib, "CribMattress", CF(cribAt.X, Y + 1.55, cribAt.Z), V(4.1, 0.3, 2.6), Color3.fromRGB(220, 200, 210), Enum.Material.Fabric)
	R.Notes.Nursery = Kit.solid(f, "Note2", CF(cribAt.X + 0.6, Y + 1.75, cribAt.Z) * CFrame.Angles(0, rad(-12), 0), V(1.3, 0.04, 1.7), Color3.fromRGB(236, 230, 210), Enum.Material.Fabric)
	-- the dolls, sat in a row against the wall
	local dollColors = { Color3.fromRGB(60, 120, 220), Color3.fromRGB(220, 60, 60), Color3.fromRGB(60, 180, 90), Color3.fromRGB(230, 200, 60) }
	for i, c in dollColors do
		local at = V(-27 + i * 2.2, Y, 3.2)
		local doll = Kit.model(f, "Doll")
		Kit.ellipsoid(doll, "DollBody", CF(at.X, Y + 0.8, at.Z), V(1, 1.3, 0.7), c, Enum.Material.Fabric)
		Kit.ball(doll, "DollHead", V(at.X, Y + 1.8, at.Z), 0.8, Color3.fromRGB(236, 214, 190), Enum.Material.Fabric)
		for _, s in { -1, 1 } do
			Kit.box(doll, "DollEye", CF(at.X + s * 0.18, Y + 1.88, at.Z - 0.38), V(0.12, 0.12, 0.04), Color3.fromRGB(10, 10, 10), Enum.Material.Plastic)
		end
		Kit.box(doll, "DollStitch", CF(at.X, Y + 1.62, at.Z - 0.39), V(0.4, 0.05, 0.03), Color3.fromRGB(120, 20, 20), Enum.Material.Plastic)
	end
	Kit.teddy(f, CFrame.lookAt(V(-14.5, Y, -12), V(-20, Y, -6)), 1.4, Color3.fromRGB(140, 100, 70))
	local rocker = Kit.chair(f, CFrame.lookAt(V(-15, Y, 1), V(-22, Y, -6)), Color3.fromRGB(150, 120, 90))
	rocker.Name = "RockingChair"
	-- the music box on a crate (it starts on its own when someone comes in: FinaleService)
	Kit.cardboardBox(f, CF(-28, Y, -1), V(2.2, 2, 2.2), Color3.fromRGB(160, 120, 90), true)
	R.MusicBox = Kit.solid(f, "FinaleMusicBox", CF(-28, Y + 2.3, -1), V(1.1, 0.6, 0.8), Color3.fromRGB(236, 200, 214), Enum.Material.Wood)
	bulb(Kit, f, V(-21, 0, -5), lights, true)
	-- a mobile of paper birds over the crib
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		Kit.box(f, "PaperBird", CF(cribAt.X + math.cos(a) * 1.1, Y + 6.2, cribAt.Z + math.sin(a) * 1.1) * CFrame.Angles(0, a, rad(20)), V(0.6, 0.04, 0.3), Color3.fromRGB(240, 236, 226), Enum.Material.Fabric)
	end

	---------------------------------------------------------------------------
	-- His room: where he sleeps, and what he lost
	---------------------------------------------------------------------------
	Kit.box(f, "Mattress", CF(30, Y + 0.4, -10), V(5.5, 0.8, 7.5), Color3.fromRGB(120, 116, 100), Enum.Material.Fabric)
	Kit.sleepingBag(f, CF(30, Y + 0.8, -10), Color3.fromRGB(70, 80, 60))
	local tally = Kit.solid(f, "TallyWall", CF(33.45, Y + 5, -6) * CFrame.Angles(0, rad(-90), 0), V(6, 3.2, 0.1), EARTH, Enum.Material.Ground)
	sign(tally, Enum.NormalId.Front, "|||| |||| |||| ||||", 70, Color3.fromRGB(230, 225, 210), Enum.Font.PermanentMarker)
	local clips = Kit.solid(f, "Clippings", CF(26, Y + 5.2, 3.45) * CFrame.Angles(0, rad(180), 0), V(9, 4.6, 0.08), Color3.fromRGB(220, 214, 196), Enum.Material.Fabric)
	sign(clips, Enum.NormalId.Front, "VANE HOME SERVICES CLOSES AFTER 31 YEARS\n\nBANK TAKES FAMILY HOME ON BIRCH ST\n\nWIFE AND CHILDREN MOVE TO OHIO", 24, Color3.fromRGB(30, 28, 26), Enum.Font.Merriweather)
	Kit.lantern(f, CF(24, Y, -12.5))
	local desk = Kit.cardboardBox(f, CF(21.5, Y, -11), V(3.2, 3, 2.2), Color3.fromRGB(110, 86, 60), true)
	R.Notes.HisRoom = Kit.solid(f, "Note3", CF(21.5, Y + 3.05, -11) * CFrame.Angles(0, rad(8), 0), V(1.3, 0.04, 1.7), Color3.fromRGB(236, 230, 210), Enum.Material.Fabric)
	-- the photo of his own family, burnt at the edges
	local photo = Kit.solid(f, "HisFamily", CF(21.5, Y + 3.3, -12) * CFrame.Angles(rad(-70), 0, 0), V(1.4, 1.1, 0.06), Color3.fromRGB(60, 50, 40), Enum.Material.Plastic)
	R.Lore.Photo = photo
	R.Lore.Desk = desk
	bulb(Kit, f, V(26, 0, -5), lights, false)

	---------------------------------------------------------------------------
	-- The storm cellar: the way out (a ladder to the grate on the lawn, padlocked)
	---------------------------------------------------------------------------
	Kit.shelving(f, CFrame.lookAt(V(-5, Y, 49), V(4, Y, 49)), 10, 2, 7, 3, 21)
	Kit.workbench(f, CFrame.lookAt(V(12.6, Y, 47), V(4, Y, 47)), 6, 2.4)
	for k = 0, 2 do
		Kit.bottle(f, CF(-4.4, Y + 2.6 + k * 0.01, 45 + k * 1.2), Color3.fromRGB(120, 80, 40))
	end
	-- the shaft: ladder up to the grate
	local shaftX, shaftZ = 4, 54
	for _, s in { -1, 1 } do
		Kit.box(f, "CellarLadderRail", CF(shaftX + s * 0.9, Y + 5, shaftZ + 2.6), V(0.2, 10, 0.2), Color3.fromRGB(110, 100, 90), Enum.Material.Metal)
	end
	for k = 1, 9 do
		Kit.box(f, "CellarRung", CF(shaftX, Y + k, shaftZ + 2.6), V(1.8, 0.14, 0.14), Color3.fromRGB(110, 100, 90), Enum.Material.Metal)
	end
	local ladder = Kit.solid(f, "CellarLadder", CF(shaftX, Y + 2.5, shaftZ + 2.3), V(2.2, 5, 0.6), Color3.fromRGB(110, 100, 90), Enum.Material.Metal, { Transparency = 1 })
	R.LadderOut = ladder
	-- the padlock on the hatch above (a keypad lock; the code is in his notes)
	local lock = Kit.solid(f, "Keypad", CF(shaftX + 1.8, Y + 4.4, shaftZ + 3.2), V(1, 1.4, 0.3), Color3.fromRGB(46, 46, 50), Enum.Material.Metal)
	Kit.box(f, "KeypadScreen", lock.CFrame * CF(0, 0.38, -0.16), V(0.7, 0.3, 0.02), Color3.fromRGB(200, 40, 30), Enum.Material.Neon)
	R.Keypad = lock
	Kit.box(f, "Chain", CF(shaftX, Y + 9.4, shaftZ + 2.4), V(2.4, 0.3, 0.3), Color3.fromRGB(140, 140, 146), Enum.Material.Metal)
	local cellarLight = bulb(Kit, f, V(4, 0, 48), lights, true)
	cellarLight.Name = "CellarBulb"
	-- the cellar door: heavy, and it can be held shut from inside
	local cdoor = Kit.solid(f, "CellarDoor", CF(4, Y + 4, 40), V(5, 8, 0.6), Color3.fromRGB(80, 62, 44), Enum.Material.WoodPlanks)
	Kit.box(f, "CellarDoorBand", CF(4, Y + 2, 39.65), V(5, 0.4, 0.1), Color3.fromRGB(60, 60, 64), Enum.Material.Metal)
	Kit.box(f, "CellarDoorBand", CF(4, Y + 6, 39.65), V(5, 0.4, 0.1), Color3.fromRGB(60, 60, 64), Enum.Material.Metal)
	R.CellarDoor = { Part = cdoor, Closed = cdoor.CFrame, Open = CF(4, Y + 4, 40) * CF(-2.5, 0, 0) * CFrame.Angles(0, rad(100), 0) * CF(2.5, 0, 0), Inside = V(4, Y, 42.5), Outside = V(4, Y, 37) }

	---------------------------------------------------------------------------
	-- The grate on the lawn (every night: rusted shut... from this side)
	---------------------------------------------------------------------------
	local G = Burrow.Grate
	local grate = Kit.model(f, "CellarGrate")
	Kit.box(grate, "GrateFrame", CF(G.X, G.Y + 0.15, G.Z + 2.6), V(4.4, 0.3, 4.4), Color3.fromRGB(80, 70, 60), Enum.Material.Concrete)
	for k = -3, 3 do
		Kit.box(grate, "GrateBar", CF(G.X + k * 0.55, G.Y + 0.34, G.Z + 2.6), V(0.18, 0.1, 3.8), Color3.fromRGB(110, 70, 40), Enum.Material.CorrodedMetal)
	end
	local hint = Kit.solid(grate, "GrateHint", CF(G.X, G.Y + 0.4, G.Z + 2.6), V(4, 0.2, 4), Color3.new(), Enum.Material.Plastic, { Transparency = 1 })
	R.GrateHint = hint
	if ctx.Interaction and ctx.Story.Finale then
		ctx.Interaction.prompt(hint, { Action = "Look", Object = "Rusted grate", Distance = 8 }, function(player)
			ctx.Remotes.Document:FireClient(player, "FinaleGrate", ctx.Story.Finale.Grate)
		end)
	end
	R.Surface = V(G.X, G.Y + 3, G.Z - 1)

	---------------------------------------------------------------------------
	-- Finding your way: a sign over every doorway (his handwriting), and a signpost in each
	-- junction pointing the way. The notes glow a little, so they're seen from the doorway.
	---------------------------------------------------------------------------
	local PLANK = Color3.fromRGB(150, 116, 78)
	local INK = Color3.fromRGB(30, 22, 16)
	-- a plank over a doorway, readable from the tunnel side (facing = the way it reads from)
	local function doorSign(at: Vector3, facing: Vector3, text: string, w: number)
		local cf = CFrame.lookAt(at, at + facing)
		local plank = Kit.box(f, "DoorSign", cf, V(w, 0.9, 0.1), PLANK, Enum.Material.Wood)
		sign(plank, Enum.NormalId.Front, text, 30, INK, Enum.Font.PermanentMarker)
	end
	doorSign(V(16.9, Y + 8.5, 17), V(-1, 0, 0), "PANTRY", 4)
	doorSign(V(16.9, Y + 8.5, -5), V(-1, 0, 0), "HIS ROOM", 4)
	doorSign(V(-10.9, Y + 8.5, -5), V(1, 0, 0), "NURSERY", 4)
	doorSign(V(4, Y + 8.5, 38.9), V(0, 0, -1), "STORM CELLAR", 4.6)
	doorSign(V(-14.9, Y + 8.5, 17), V(1, 0, 0), "DINING ROOM", 4.6)
	-- a signpost: a post, and an arrow-shaped board per way out, the name on both faces
	local function signpost(at: Vector3, ways: { { any } })
		Kit.box(f, "SignPost", CF(at.X, Y + 3.6, at.Z), V(0.35, 7.2, 0.35), TIMBER, Enum.Material.Wood)
		for i, w in ways do
			local dir: Vector3, text: string = w[1], w[2]
			local h = Y + 6.7 - (i - 1) * 0.75
			local len = 3
			local center = V(at.X, h, at.Z) + dir * (len / 2 + 0.2)
			local cf = CFrame.fromMatrix(center, dir, V(0, 1, 0))
			local board = Kit.box(f, "SignBoard", cf, V(len, 0.6, 0.1), PLANK, Enum.Material.Wood)
			-- the arrow's point
			Kit.box(f, "SignTip", cf * CF(len / 2, 0, 0) * CFrame.Angles(0, 0, rad(45)), V(0.43, 0.43, 0.1), PLANK, Enum.Material.Wood)
			sign(board, Enum.NormalId.Front, text, 22, INK, Enum.Font.PermanentMarker)
			sign(board, Enum.NormalId.Back, text, 22, INK, Enum.Font.PermanentMarker)
		end
	end
	signpost(V(6.4, 0, 14.9), {
		{ V(0, 0, 1), "STORM CELLAR" },
		{ V(1, 0, 0), "PANTRY" },
		{ V(0, 0, -1), "NURSERY / HIS ROOM" },
		{ V(-1, 0, 0), "DINING ROOM" },
	})
	signpost(V(6.4, 0, -2.6), {
		{ V(-1, 0, 0), "NURSERY" },
		{ V(1, 0, 0), "HIS ROOM" },
		{ V(0, 0, 1), "CELLAR / DINING" },
	})
	-- each note: a small warm light on it, so it's seen from across the room
	for _, note in R.Notes do
		local glow = Instance.new("PointLight")
		glow.Range = 7
		glow.Brightness = 1.4
		glow.Color = Color3.fromRGB(255, 226, 160)
		glow.Shadows = false
		glow.Parent = note
	end

	---------------------------------------------------------------------------
	-- Hiding nooks: a blanket hung across a dark corner. Crouch behind one and he walks right past
	---------------------------------------------------------------------------
	for i, n in { { V(30, Y, 24), -1, -1 }, { V(-30, Y, -14), 1, 1 }, { V(34, Y, 4), -1, -1 }, { V(-6, Y, 58), 1, -1 } } do
		local corner, sx, sz = n[1], n[2], n[3]
		-- (the blanket hangs on the diagonal, 3.2 studs out from the corner)
		local mid = corner + V(sx * 1.6, 0, sz * 1.6)
		local look = corner + V(sx * 4, 0, sz * 4)
		local cf = CFrame.lookAt(V(mid.X, Y + 3.2, mid.Z), V(look.X, Y + 3.2, look.Z))
		local blanket = Kit.box(f, "NookBlanket", cf, V(4.6, 6.4, 0.12), ({ Color3.fromRGB(110, 50, 46), Color3.fromRGB(60, 80, 110), Color3.fromRGB(80, 90, 60), Color3.fromRGB(120, 100, 70) })[i], Enum.Material.Fabric)
		blanket.CanQuery = true -- (it blocks his view)
		Kit.box(f, "NookRope", cf * CF(0, 3.3, 0), V(4.8, 0.08, 0.08), Color3.fromRGB(150, 130, 100), Enum.Material.Fabric)
		local a, b = corner, corner + V(sx * 3, 0, sz * 3)
		table.insert(R.Nooks, { Min = V(math.min(a.X, b.X), Y, math.min(a.Z, b.Z)), Max = V(math.max(a.X, b.X), Y + 6, math.max(a.Z, b.Z)), Blanket = blanket })
	end
	-- the alcoves: a pocket dug into a tunnel wall (3 wide, 3 deep, 7 high), a blanket across the
	-- opening. Step in behind it and crouch: he walks right past.
	for i, a in ALCOVES do
		local t = TUNNELS[a.Tunnel]
		local tx0, tx1, tz0, tz1 = t[1], t[2], t[3], t[4]
		local w0, w1 = a.At - 1.5, a.At + 1.5
		-- out: which way the pocket goes; face: the tunnel's inner wall face on that side
		local out, face
		if a.Side == "N" then
			out, face = V(0, 0, 1), tz1
		elseif a.Side == "S" then
			out, face = V(0, 0, -1), tz0
		elseif a.Side == "E" then
			out, face = V(1, 0, 0), tx1
		else
			out, face = V(-1, 0, 0), tx0
		end
		-- a box in "along / out" coordinates: along = [p0, p1], out = [d0, d1] studs past the face
		local function pbox(nm: string, p0: number, p1: number, d0: number, d1: number, y0: number, y1: number, color, mat)
			local o0, o1 = face + (out.X + out.Z) * d0, face + (out.X + out.Z) * d1
			if out.X ~= 0 then
				B.box(f, nm, V(math.min(o0, o1), y0, p0), V(math.max(o0, o1), y1, p1), color, mat)
			else
				B.box(f, nm, V(p0, y0, math.min(o0, o1)), V(p1, y1, math.max(o0, o1)), color, mat)
			end
		end
		pbox("AlcoveFloor", w0, w1, 1, 4, Y - 1, Y, MUD, Enum.Material.Mud)
		pbox("AlcoveCeiling", w0, w1, 1, 4, Y + 7, Y + 8, EARTH_DARK, Enum.Material.Ground)
		pbox("AlcoveBack", w0 - 1, w1 + 1, 4, 5, Y - 1, Y + 8, EARTH, Enum.Material.Ground)
		pbox("AlcoveSide", w0 - 1, w0, 1, 4, Y, Y + 7, EARTH, Enum.Material.Ground)
		pbox("AlcoveSide", w1, w1 + 1, 1, 4, Y, Y + 7, EARTH, Enum.Material.Ground)
		-- the blanket, hung in the opening
		local mid = face + (out.X + out.Z) * 0.5
		local center = out.X ~= 0 and V(mid, Y + 3.3, a.At) or V(a.At, Y + 3.3, mid)
		local cf = CFrame.lookAt(center, center + out)
		local blanket = Kit.box(f, "NookBlanket", cf, V(3, 6.6, 0.12), ({ Color3.fromRGB(110, 50, 46), Color3.fromRGB(60, 80, 110), Color3.fromRGB(80, 90, 60), Color3.fromRGB(120, 100, 70) })[(i % 4) + 1], Enum.Material.Fabric)
		blanket.CanQuery = true -- (it blocks his view)
		Kit.box(f, "NookRope", cf * CF(0, 3.4, 0), V(3.2, 0.08, 0.08), Color3.fromRGB(150, 130, 100), Enum.Material.Fabric)
		local o0, o1 = face, face + (out.X + out.Z) * 4
		local lo, hi = math.min(o0, o1), math.max(o0, o1)
		if out.X ~= 0 then
			table.insert(R.Nooks, { Min = V(lo, Y, w0), Max = V(hi, Y + 6, w1), Blanket = blanket })
		else
			table.insert(R.Nooks, { Min = V(w0, Y, lo), Max = V(w1, Y + 6, hi), Blanket = blanket })
		end
	end

	---------------------------------------------------------------------------
	-- His patrol graph (every edge is a straight, clear walk)
	---------------------------------------------------------------------------
	local N = {
		DinE = V(-20, Y, 17), DinNW = V(-34, Y, 23.5), DinNE = V(-20, Y, 23.5), DinSW = V(-34, Y, 10.5), DinSE = V(-20, Y, 10.5),
		DinDoor = V(-14, Y, 17), TunA = V(-6, Y, 17), J1 = V(4, Y, 17),
		TunN = V(4, Y, 30), CelDoorOut = V(4, Y, 37), CelDoorIn = V(4, Y, 43), Cel1 = V(4, Y, 49), Cel2 = V(-2, Y, 53), Cel3 = V(10, Y, 53),
		TunS = V(4, Y, 6), J2 = V(4, Y, -5),
		TunW = V(-6, Y, -5), NurDoor = V(-13, Y, -5), Nur1 = V(-18, Y, -9), Nur2 = V(-24, Y, -2), Nur3 = V(-17, Y, 1),
		TunE = V(13, Y, -5), HisDoor = V(19, Y, -5), His1 = V(24, Y, -8), His2 = V(28, Y, 0), His3 = V(25, Y, -12),
		TunP = V(13, Y, 17), PanDoor = V(19, Y, 17), Pan1 = V(23, Y, 15), Pan2 = V(23, Y, 21),
	}
	R.Nodes = N
	R.Edges = {
		{ "DinE", "DinNE" }, { "DinE", "DinSE" }, { "DinNE", "DinNW" }, { "DinSE", "DinSW" }, { "DinNW", "DinSW" }, { "DinE", "DinDoor" },
		{ "DinDoor", "TunA" }, { "TunA", "J1" },
		{ "J1", "TunN" }, { "TunN", "CelDoorOut" }, { "CelDoorOut", "CelDoorIn" }, { "CelDoorIn", "Cel1" }, { "Cel1", "Cel2" }, { "Cel1", "Cel3" },
		{ "J1", "TunS" }, { "TunS", "J2" },
		{ "J2", "TunW" }, { "TunW", "NurDoor" }, { "NurDoor", "Nur1" }, { "NurDoor", "Nur3" }, { "Nur1", "Nur2" }, { "Nur3", "Nur2" },
		{ "J2", "TunE" }, { "TunE", "HisDoor" }, { "HisDoor", "His1" }, { "His1", "His2" }, { "His1", "His3" },
		{ "J1", "TunP" }, { "TunP", "PanDoor" }, { "PanDoor", "Pan1" }, { "PanDoor", "Pan2" },
	}
	R.Patrol = { "Pan1", "Pan2", "Nur1", "Nur2", "Nur3", "His1", "His2", "His3", "J1", "J2", "TunN", "TunA", "DinE", "Cel1" }
	return R
end

return Burrow
