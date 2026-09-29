--[[
	Rooms — named volumes of the Whitaker house.
	Rooms.find(position) returns the room a position is in (or nil when outside).
	Smaller rooms that sit inside larger volumes are listed first.
]]

local Rooms = {}

-- Floor slab tops. Walls are 13 studs tall between slabs.
Rooms.Floors = {
	Basement = -13,
	Ground = 1,
	Upstairs = 15,
	Attic = 29,
}

local function room(name, display, floor, x0, x1, z0, z1, y0, y1)
	return {
		Name = name,
		Display = display,
		Floor = floor,
		Min = Vector3.new(x0, y0, z0),
		Max = Vector3.new(x1, y1, z1),
		Center = Vector3.new((x0 + x1) / 2, y0, (z0 + z1) / 2),
	}
end

local B0, B1 = -14, 0.5
local G0, G1 = 0.5, 14.5
local U0, U1 = 14.5, 28.5
local A0, A1 = 28.5, 45

Rooms.List = {
	-- Basement
	room("Boiler", "Boiler Room", "Basement", -40, -20, 10, 30, B0, B1),
	room("Basement", "Basement", "Basement", -40, 12, -30, 30, B0, B1),

	-- Ground floor
	room("Living", "Living Room", "Ground", -40, -8, -30, 2, G0, G1),
	room("Kitchen", "Kitchen", "Ground", -40, -8, 2, 30, G0, G1),
	room("Office", "Dad's Office", "Ground", 12, 40, -30, -10, G0, G1),
	room("Bathroom", "Downstairs Bathroom", "Ground", 12, 22, -10, 4, G0, G1),
	room("Mudroom", "Mudroom", "Ground", 22, 40, -10, 4, G0, G1),
	room("Den", "Den", "Ground", 12, 40, 4, 30, G0, G1),
	room("Hallway", "Front Hall", "Ground", -8, 12, -30, 30, G0, G1),
	room("Garage", "Garage", "Ground", 40, 66, -30, 6, G0, G1),

	-- Upstairs
	room("Master", "Master Bedroom", "Upstairs", -40, -8, -30, 0, U0, U1),
	room("MasterBath", "Master Bathroom", "Upstairs", -40, -8, 0, 12, U0, U1),
	room("Jamie", "Jamie's Room", "Upstairs", -40, -8, 12, 30, U0, U1),
	room("Guest", "Guest Room", "Upstairs", 12, 40, -30, -6, U0, U1),
	room("HallBath", "Upstairs Bathroom", "Upstairs", 12, 40, -6, 8, U0, U1),
	room("Lily", "Lily's Room", "Upstairs", 12, 40, 8, 30, U0, U1),
	room("UpperHall", "Upstairs Hall", "Upstairs", -8, 12, -30, 30, U0, U1),

	-- Attic
	room("Attic", "Attic", "Attic", -40, 40, -30, 30, A0, A1),
}

Rooms.ByName = {}
for _, r in Rooms.List do
	Rooms.ByName[r.Name] = r
end

function Rooms.contains(r, pos: Vector3): boolean
	return pos.X >= r.Min.X and pos.X <= r.Max.X
		and pos.Y >= r.Min.Y and pos.Y <= r.Max.Y
		and pos.Z >= r.Min.Z and pos.Z <= r.Max.Z
end

function Rooms.find(pos: Vector3)
	for _, r in Rooms.List do
		if Rooms.contains(r, pos) then
			return r
		end
	end
	return nil
end

function Rooms.floorOf(pos: Vector3): string
	local r = Rooms.find(pos)
	if r then
		return r.Floor
	end
	return "Outside"
end

function Rooms.isInside(pos: Vector3): boolean
	return Rooms.find(pos) ~= nil
end

return Rooms
