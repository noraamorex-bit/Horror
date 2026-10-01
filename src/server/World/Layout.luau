--[[
	Layout — the architectural data for 14 Alder Lane.

	Coordinates are studs. Front of house faces -Z (street at z = -80).
	Floor slab tops: Basement -13, Ground 1, Upstairs 15, Attic 29. Walls are 13 tall.

	Opening fields:
		at      world coordinate along the wall axis (X for walls along X, Z for walls along Z)
		w, h    size; bottom = sill height above the wall base
		kind    "door" | "arch" | "window" | "garage"
	Door fields:
		id, name, lock ("Privacy" | "Key" | "Deadbolt"), key (item), locked (start state),
		hinge ("min"|"max" end of the opening), into ("+"|"-" side it swings toward), exterior
]]

local Layout = {}

Layout.WallH = 13
Layout.Y = { Basement = -13, Ground = 1, Upstairs = 15, Attic = 29 }

local function door(at, id, name, o)
	o = o or {}
	o.kind = "door"
	o.at = at
	o.w = o.w or 5
	o.h = o.h or 9.5
	o.id = id
	o.name = name
	o.hinge = o.hinge or "min"
	o.into = o.into or "+"
	return o
end

local function arch(at, w, h)
	return { kind = "arch", at = at, w = w or 6, h = h or 10 }
end

local function win(at, id, o)
	o = o or {}
	o.kind = "window"
	o.at = at
	o.w = o.w or 6
	o.h = o.h or 5.5
	o.bottom = o.bottom or 3.5
	o.id = id
	return o
end

-- Exterior walls: two layers (siding outside, drywall inside). out = side facing outdoors.
Layout.ExteriorWalls = {
	-- Ground floor
	{ floor = "Ground", x1 = -40, z1 = -30, x2 = 40, z2 = -30, out = "-", openings = {
		win(-34, "LivingFront1", { breakable = true }),
		win(-14, "LivingFront2", { breakable = true }),
		door(2, "FrontDoor", "Front Door", { lock = "Deadbolt", locked = true, exterior = true, into = "+", hinge = "min" }),
		win(26, "OfficeFront", { breakable = true }),
	} },
	{ floor = "Ground", x1 = -40, z1 = 30, x2 = 40, z2 = 30, out = "+", openings = {
		win(-32, "KitchenBack", { breakable = true }),
		door(-20, "BackDoor", "Back Door", { lock = "Deadbolt", locked = false, exterior = true, into = "-", hinge = "max" }),
		win(2, "HallBack", { breakable = true }),
		win(20, "DenBack1", { breakable = true }),
		win(32, "DenBack2", { breakable = true }),
	} },
	{ floor = "Ground", x1 = -40, z1 = -30, x2 = -40, z2 = 30, out = "-", openings = {
		win(-22, "LivingSide", { breakable = true }),
		win(14, "KitchenSink", { bottom = 4.5, h = 4.5, breakable = true }),
	} },
	{ floor = "Ground", x1 = 40, z1 = -30, x2 = 40, z2 = 30, out = "+", openings = {
		door(-3, "GarageEntry", "Garage Entry", { lock = "Deadbolt", locked = false, into = "-", hinge = "min" }),
		win(18, "DenSide", { breakable = true }),
	} },

	-- Garage
	{ floor = "Ground", x1 = 40, z1 = -30, x2 = 66, z2 = -30, out = "-", garage = true, openings = {
		{ kind = "garage", at = 53, w = 18, h = 10 },
	} },
	{ floor = "Ground", x1 = 66, z1 = -30, x2 = 66, z2 = 6, out = "+", garage = true, openings = {
		door(-2, "GarageSide", "Garage Side Door", { lock = "Deadbolt", locked = false, exterior = true, into = "-", hinge = "min" }),
	} },
	{ floor = "Ground", x1 = 40, z1 = 6, x2 = 66, z2 = 6, out = "+", garage = true, openings = {
		win(53, "GarageBack", { bottom = 5, h = 4 }),
	} },

	-- Upstairs
	{ floor = "Upstairs", x1 = -40, z1 = -30, x2 = 40, z2 = -30, out = "-", openings = {
		win(-32, "MasterFront1"),
		win(-16, "MasterFront2"),
		win(2, "UpperHallFront"),
		win(26, "GuestFront", { open = true }),
	} },
	{ floor = "Upstairs", x1 = -40, z1 = 30, x2 = 40, z2 = 30, out = "+", openings = {
		win(-24, "JamieBack"),
		win(26, "LilyBack", { open = true }),
	} },
	{ floor = "Upstairs", x1 = -40, z1 = -30, x2 = -40, z2 = 30, out = "-", openings = {
		win(-24, "MasterSide"),
		win(6, "MasterBathWin", { w = 4, bottom = 6, h = 3.5 }),
		win(22, "JamieSide"),
	} },
	{ floor = "Upstairs", x1 = 40, z1 = -30, x2 = 40, z2 = 30, out = "+", openings = {
		win(-18, "GuestSide"),
		win(1, "HallBathWin", { w = 4, bottom = 5, h = 4 }),
		win(20, "LilySide"),
	} },

	-- Basement (concrete, single material)
	{ floor = "Basement", x1 = -40, z1 = -30, x2 = 12, z2 = -30, out = "-", concrete = true, openings = {} },
	{ floor = "Basement", x1 = -40, z1 = 30, x2 = 12, z2 = 30, out = "+", concrete = true, openings = {} },
	{ floor = "Basement", x1 = -40, z1 = -30, x2 = -40, z2 = 30, out = "-", concrete = true, openings = {
		win(-10, "BasementWin1", { w = 4, h = 2, bottom = 9.5 }),
		win(-24, "BasementWin2", { w = 4, h = 2, bottom = 9.5 }),
	} },
	{ floor = "Basement", x1 = 12, z1 = -30, x2 = 12, z2 = 30, out = "+", concrete = true, openings = {} },
}

Layout.InteriorWalls = {
	-- Ground floor
	{ floor = "Ground", x1 = -8, z1 = -30, x2 = -8, z2 = 30, openings = { arch(-18, 8, 10), arch(26, 5, 9.5) } },
	{ floor = "Ground", x1 = -40, z1 = 2, x2 = -8, z2 = 2, openings = { arch(-24, 10, 10) } },
	{ floor = "Ground", x1 = 12, z1 = -30, x2 = 12, z2 = 30, openings = {
		door(-20, "Office", "Dad's Office", { lock = "Key", key = "HouseKeys", locked = true, into = "+" }),
		door(-7, "BackHall", "Back Hall", { into = "+" }),
		door(26, "Den", "Den", { into = "+" }),
	} },
	{ floor = "Ground", x1 = 6, z1 = -0.4, x2 = 6, z2 = 22, openings = {} },
	{ floor = "Ground", x1 = 6, z1 = -0.4, x2 = 12, z2 = -0.4, openings = {} },
	{ floor = "Ground", x1 = 6, z1 = 22, x2 = 12, z2 = 22, openings = {
		door(9, "Basement", "Basement Door", { w = 4.4, lock = "Key", key = "BasementKey", into = "-", hinge = "max", openDeg = 84 }),
	} },
	{ floor = "Ground", x1 = 12, z1 = -10, x2 = 40, z2 = -10, openings = {} },
	-- the back hall (front hall -> mudroom -> garage) runs along the office wall; the bathroom opens off it to the north
	{ floor = "Ground", x1 = 22, z1 = -4, x2 = 22, z2 = 4, openings = {} },
	{ floor = "Ground", x1 = 12, z1 = -4, x2 = 22, z2 = -4, openings = {
		door(15.6, "Bathroom", "Bathroom", { w = 3.8, lock = "Privacy", into = "+" }),
	} },
	{ floor = "Ground", x1 = 12, z1 = 4, x2 = 40, z2 = 4, openings = { door(31, "Mudroom", "Mudroom", { into = "-" }) } },

	-- Upstairs
	{ floor = "Upstairs", x1 = -8, z1 = -30, x2 = -8, z2 = 30, openings = {
		door(-10, "Master", "Master Bedroom", { lock = "Privacy", into = "-" }),
		door(24, "Jamie", "Jamie's Room", { lock = "Privacy", into = "-" }),
	} },
	{ floor = "Upstairs", x1 = -40, z1 = 0, x2 = -8, z2 = 0, openings = {
		door(-30, "MasterBath", "Master Bathroom", { lock = "Privacy", into = "+" }),
	} },
	{ floor = "Upstairs", x1 = -40, z1 = 12, x2 = -8, z2 = 12, openings = {} },
	{ floor = "Upstairs", x1 = 12, z1 = -30, x2 = 12, z2 = 30, openings = {
		door(-14, "Guest", "Guest Room", { into = "+" }),
		door(1, "HallBath", "Upstairs Bathroom", { lock = "Privacy", into = "+" }),
		door(20, "Lily", "Lily's Room", { into = "+" }),
	} },
	{ floor = "Upstairs", x1 = 12, z1 = -6, x2 = 40, z2 = -6, openings = {} },
	{ floor = "Upstairs", x1 = 12, z1 = 8, x2 = 40, z2 = 8, openings = {} },

	-- Basement
	{ floor = "Basement", x1 = -20, z1 = 10, x2 = -20, z2 = 30, openings = { door(20, "Boiler", "Boiler Room", { into = "+" }) } },
	{ floor = "Basement", x1 = -40, z1 = 10, x2 = -20, z2 = 10, openings = {} },
}

-- Floor finishes per room: {x0,x1,z0,z1, color key, material key, texture key (World/Textures)}
Layout.FloorFinish = {
	Ground = {
		{ -40, -8, -30, 2, "Oak", "Planks", "WoodDark" }, -- living
		{ -40, -8, 2, 30, "Tile", "Tile", "Marble" }, -- kitchen
		{ 12, 40, -30, -10, "Walnut", "Planks", "Parquet" }, -- office
		{ 12, 22, -10, 4, "Tile", "Tile", "TileWhite" }, -- bath
		{ 22, 40, -10, 4, "Tile", "Tile", "Marble" }, -- mudroom
		{ 12, 40, 4, 30, "Carpet", "Carpet", "Carpet" }, -- den
	},
	Upstairs = {
		{ -40, -8, -30, 0, "Carpet", "Carpet", "Carpet" },
		{ -40, -8, 0, 12, "Tile", "Tile", "TileWhite" },
		{ -40, -8, 12, 30, "BlueCarpet", "Carpet", "Carpet" },
		{ 12, 40, -30, -6, "Carpet", "Carpet", "Carpet" },
		{ 12, 40, -6, 8, "Tile", "Tile", "TileWhite" },
		{ 12, 40, 8, 30, "Carpet", "Carpet", "Carpet" },
	},
}

-- Hallway floors (with stair holes)
Layout.HallFloor = {
	Ground = { x0 = -8, x1 = 12, z0 = -30, z1 = 30, holes = { { 6, 12, -0.4, 22 } } },
	Upstairs = { x0 = -8, x1 = 12, z0 = -30, z1 = 30, holes = { { -8, -2, -6, 16.4 } } },
}

Layout.Stairs = {
	Main = { x0 = -8, x1 = -2, zStart = -6, zEnd = 16.4, yStart = 1, yEnd = 15 },
	Basement = { x0 = 6, x1 = 12, zStart = 22, zEnd = -0.4, yStart = 1, yEnd = -13 },
}

-- Under the ridge side of the roof, so there is headroom above it in the attic.
Layout.AtticHatch = { x0 = 4, x1 = 8, z0 = 8, z1 = 14 }
Layout.GarageHatch = { x0 = 50, x1 = 54, z0 = -3, z1 = 1 }

-- Wall colors per floor section (interior)
Layout.WallColor = {
	Ground = "WarmWall",
	Upstairs = "Drywall",
	Basement = "Concrete",
}

---------------------------------------------------------------------------
-- Lighting: ceiling fixtures and switches per room
---------------------------------------------------------------------------
Layout.Lights = {
	Living = { Vector3.new(-30, 14, -18), Vector3.new(-18, 14, -4) },
	Kitchen = { Vector3.new(-30, 14, 10), Vector3.new(-20, 14, 22) },
	Hallway = { Vector3.new(2, 14, -20), Vector3.new(2, 14, 4), Vector3.new(0, 14, 26) },
	Office = { Vector3.new(26, 14, -20) },
	Bathroom = { Vector3.new(17, 14, 0) },
	MudHall = { Vector3.new(17, 14, -7) },
	Mudroom = { Vector3.new(31, 14, -3) },
	Den = { Vector3.new(26, 14, 17) },
	Garage = { Vector3.new(53, 14, -12) },
	Master = { Vector3.new(-24, 28, -15) },
	MasterBath = { Vector3.new(-24, 28, 6) },
	Jamie = { Vector3.new(-24, 28, 21) },
	UpperHall = { Vector3.new(4, 28, -20), Vector3.new(0, 28, 20) },
	Guest = { Vector3.new(26, 28, -18) },
	HallBath = { Vector3.new(26, 28, 1) },
	Lily = { Vector3.new(26, 28, 19) },
	Basement = { Vector3.new(-14, 0, -14), Vector3.new(-4, 0, 18) },
	Boiler = { Vector3.new(-30, 0, 20) },
}

-- Switch plates: position + the axis-aligned direction the plate faces
Layout.Switches = {
	{ Room = "Living", Pos = Vector3.new(-8.35, 5.5, -23), Face = "-X" },
	{ Room = "Kitchen", Pos = Vector3.new(-8.35, 5.5, 22.5), Face = "-X" },
	{ Room = "Hallway", Pos = Vector3.new(5.5, 5.5, -29.45), Face = "+Z" },
	{ Room = "Office", Pos = Vector3.new(12.35, 5.5, -16.8), Face = "+X" },
	{ Room = "Bathroom", Pos = Vector3.new(18.7, 5.5, -3.65), Face = "+Z" },
	{ Room = "MudHall", Pos = Vector3.new(14.5, 5.5, -9.65), Face = "+Z" },
	{ Room = "Mudroom", Pos = Vector3.new(34.5, 5.5, 3.65), Face = "-Z" },
	{ Room = "Den", Pos = Vector3.new(12.35, 5.5, 22.5), Face = "+X" },
	{ Room = "Garage", Pos = Vector3.new(40.55, 5.5, -6.5), Face = "+X" },
	{ Room = "Master", Pos = Vector3.new(-8.35, 19.5, -13.5), Face = "-X" },
	{ Room = "MasterBath", Pos = Vector3.new(-26.5, 19.5, 0.35), Face = "+Z" },
	{ Room = "Jamie", Pos = Vector3.new(-8.35, 19.5, 20.5), Face = "-X" },
	{ Room = "UpperHall", Pos = Vector3.new(-7.65, 19.5, 18.5), Face = "+X" },
	{ Room = "Guest", Pos = Vector3.new(12.35, 19.5, -10.8), Face = "+X" },
	{ Room = "HallBath", Pos = Vector3.new(12.35, 19.5, 4.2), Face = "+X" },
	{ Room = "Lily", Pos = Vector3.new(12.35, 19.5, 23.2), Face = "+X" },
	{ Room = "Basement", Pos = Vector3.new(11.6, 5.5, 22.35), Face = "+Z" },
	{ Room = "Boiler", Pos = Vector3.new(-20.35, -8.5, 16), Face = "-X" },
}

-- Rooms whose lights start ON when the night begins
-- "Decor" is the circuit for sconces, fairy lights and under-cabinet strips (always on until the breaker goes)
Layout.StartLit = { Living = true, Kitchen = true, Hallway = true, UpperHall = true, Den = true, Jamie = true, Decor = true }

---------------------------------------------------------------------------
-- Intruder navigation nodes (root height). Tag = room name.
---------------------------------------------------------------------------
local function n(room, x, y, z, dark)
	return { Room = room, Pos = Vector3.new(x, y, z), Shadow = dark or false }
end

Layout.Nodes = {
	n("Living", -18, 4, -26, true), n("Living", -37, 4, 0, true),
	n("Kitchen", -14, 4, 6), n("Kitchen", -20, 4, 26, true),
	n("Hallway", 2, 4, 28, true), n("Hallway", 2, 4, -26),
	n("Office", 37, 4, -13, true),
	n("Bathroom", 17, 4, 0, true),
	n("MudHall", 18, 4, -7),
	n("Mudroom", 36, 4, 0, true),
	n("Den", 31, 4, 26, true), n("Den", 15, 4, 8),
	n("Garage", 62, 4, -6, true), n("Garage", 43.5, 4, -20, true), n("Garage", 52, 4, 3),
	n("Master", -37, 18, -3, true), n("Master", -14, 18, -22),
	n("MasterBath", -30, 18, 6, true),
	n("Jamie", -11, 18, 28, true),
	n("UpperHall", 8, 18, 28, true), n("UpperHall", 2, 18, -26), n("UpperHall", 9, 18, -8),
	n("Guest", 32, 18, -12, true),
	n("HallBath", 37, 18, -3, true),
	n("Lily", 14.5, 18, 25, true),
	n("Basement", -32, -10, -22, true), n("Basement", -4, -10, -22), n("Basement", -10, -10, 25, true), n("Basement", 3, -10, 5),
	n("Boiler", -30, -10, 20, true),
}

-- Peek spots: places he stands to watch players in Act III (end of halls, doorways)
Layout.PeekSpots = {
	{ Pos = Vector3.new(2, 4, 28.5), Look = Vector3.new(2, 4, -20) }, -- back of front hall
	{ Pos = Vector3.new(-20, 4, 26.5), Look = Vector3.new(-24, 4, -10) }, -- kitchen back door, looking through arch
	{ Pos = Vector3.new(9, 18, 28.5), Look = Vector3.new(2, 18, -20) }, -- upstairs hall end
	{ Pos = Vector3.new(0, 18, -28), Look = Vector3.new(2, 18, 20) }, -- upstairs hall front
	{ Pos = Vector3.new(38, 4, -2), Look = Vector3.new(26, 4, -2) }, -- mudroom
	{ Pos = Vector3.new(9, -10, -26), Look = Vector3.new(-20, -10, 10) }, -- basement
}

-- Positions where the Act II "figure at the window" can stand (outside, facing in)
Layout.WindowWatch = {
	{ Window = "LivingSide", Stand = Vector3.new(-50, 4, -22), Face = Vector3.new(-40, 4, -22), Room = "Living" },
	{ Window = "LivingFront1", Stand = Vector3.new(-34, 4, -40), Face = Vector3.new(-34, 4, -30), Room = "Living" },
	{ Window = "LivingFront2", Stand = Vector3.new(-14, 4, -41), Face = Vector3.new(-14, 4, -30), Room = "Living" },
	{ Window = "KitchenSink", Stand = Vector3.new(-50, 4, 14), Face = Vector3.new(-40, 4, 14), Room = "Kitchen" },
	{ Window = "KitchenBack", Stand = Vector3.new(-32, 4, 41), Face = Vector3.new(-32, 4, 30), Room = "Kitchen" },
	{ Window = "DenBack1", Stand = Vector3.new(20, 4, 41), Face = Vector3.new(20, 4, 30), Room = "Den" },
	{ Window = "DenSide", Stand = Vector3.new(50, 4, 18), Face = Vector3.new(40, 4, 18), Room = "Den" },
	{ Window = "OfficeFront", Stand = Vector3.new(26, 4, -41), Face = Vector3.new(26, 4, -30), Room = "Office" },
}

-- Upstairs path for the phantom footsteps (Lily's room -> hall -> hatch)
Layout.FootstepPath = {
	Vector3.new(26, 15.5, 20), Vector3.new(18, 15.5, 20), Vector3.new(12, 15.5, 20),
	Vector3.new(8, 15.5, 16), Vector3.new(4, 15.5, 8), Vector3.new(4, 15.5, 0),
	Vector3.new(4, 15.5, 6), Vector3.new(6, 15.5, 10), Vector3.new(6, 15.5, 12),
}

Layout.RestraintSlots = {
	{ Pos = Vector3.new(-37.5, -10, 13), Face = Vector3.new(-30, -10, 13) },
	{ Pos = Vector3.new(-37.5, -10, 19), Face = Vector3.new(-30, -10, 19) },
	{ Pos = Vector3.new(-37.5, -10, 25), Face = Vector3.new(-30, -10, 25) },
	{ Pos = Vector3.new(-30, -10, 28.5), Face = Vector3.new(-30, -10, 20) },
}

Layout.LobbySpawns = {
	Vector3.new(-22, 4, -10), Vector3.new(-26, 4, -10), Vector3.new(-22, 4, -6), Vector3.new(-26, 4, -6),
}

-- Wall spans that already have a feature on them (no framed pictures there): floor, x0, x1, z0, z1
Layout.NoArt = {
	{ "Ground", -40.6, -36, -19, -5 }, -- living-room fireplace and chimney breast
	{ "Ground", -32, -16, -30.6, -26 }, -- TV wall
	{ "Ground", 15, 28, 3.4, 6.6 }, -- den TV wall
	{ "Ground", -40.6, -36, 3, 29 }, -- kitchen counters and upper cabinets
	{ "Ground", -12, -8, 3, 11 }, -- phone counter / corkboard
	{ "Ground", -32, -22, 29, 30.6 }, -- fridge
	{ "Ground", 16, 23, 3, 4.4 }, -- bathroom mirror
	{ "Ground", 34, 40.6, -10.6, -7 }, -- mudroom shelf and key board
	{ "Ground", 23, 33, -10.6, -8.5 }, -- mudroom coat hooks
	{ "Ground", -8.4, -5, -29, -23 }, -- hall mirror
	{ "Ground", -8.4, -5, -12, 12 }, -- stair photo gallery and sconce
	{ "Ground", 8, 12.6, 5, 13 }, -- coat closet
	{ "Ground", 36, 40.6, 6.5, 13.5 }, -- den bookcase
	{ "Ground", 36, 40.6, -29.5, -12.5 }, -- office bookcases
	{ "Upstairs", -28.5, -19.5, -30.6, -25 }, -- master wardrobe
	{ "Upstairs", -8.4, -5, -7, 17 }, -- the gallery continues up the stairwell
	{ "Ground", 10, 12.4, -16.5, -12.3 }, -- hall sconce
	{ "Upstairs", 10, 12.4, -22, -18 }, -- upstairs hall sconce
	{ "Upstairs", 10, 12.4, 8, 12 }, -- upstairs hall sconce
	{ "Upstairs", -10, -7.6, -27, -21 }, -- master dresser mirror
	{ "Upstairs", -21, -11, 11, 12.6 }, -- master bath mirrors
	{ "Upstairs", 14, 21, -6.6, -5 }, -- upstairs bath mirror
}

Layout.Attic = {
	Nest = Vector3.new(-24, 29, 0),
	HatchTop = Vector3.new(2, 32, 11),
	GarageHatchBelow = Vector3.new(52, 4, 3),
	IntruderOffstage = Vector3.new(-26, 32, 3),
}

Layout.Outside = {
	NeighborPorch = Vector3.new(110, 2, -34),
	NeighborDoor = Vector3.new(110, 1, -30.5),
	NeighborSafe = Vector3.new(110, 4, -20),
	Van = Vector3.new(-70, 0, -74),
	PoliceStop = Vector3.new(0, 0, -70),
	JunctionBox = Vector3.new(66.6, 5, -12),
}

return Layout
