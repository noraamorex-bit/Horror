--[[
	Furnish (v143, the owner: "Map is still bad. Heavily rework map... Imagine this is Doors and make it as good as that").
	The lit renders (tools/assets stage + film2) showed where the house read as a level instead of a home: the two long
	halls were bare beige tubes with one runner each, the big bedrooms had a bed floating in the middle of a lot of
	floor, and the light was one flat ceiling globe per room. Doors' rooms are full and lit in warm pools.

	So, built after Dress and checked by the same rules (dress_test: clear of doorways, door swings, hiding spots and
	their views, prompts, his walkways, the candy spots):
	  • the front hall: the long stairwell wall gets a console with a lamp under three paintings between two sconce
	    pools; the foyer a painting over the bench; a small lamp table in the nook by the back hall; a painting by the
	    living room arch
	  • the upstairs hall: a console with a lamp, three paintings (one hangs crooked) and two sconces down the long
	    west wall; a lamp chest between the bathroom and Lily's room with a painting and a plant
	  • the master bedroom: a dressing table with a mirror and a lamp on the north wall, a bookcase, and a reading
	    corner (armchair, floor lamp)
	  • the guest room, half storage: a dresser with a lamp and a mirror, an armchair under a floor lamp, and two
	    pieces of furniture under dust sheets
	Lamps are on their room's circuit (they go out with the switch and the breaker), sconces on Decor.
]]

local Kit = require(script.Parent.Kit)

local Furnish = {}

local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad

local PX, NX, PZ, NZ = V(1, 0, 0), V(-1, 0, 0), V(0, 0, 1), V(0, 0, -1)

local function F(x: number, y: number, z: number, dir: Vector3): CFrame
	return CFrame.lookAt(V(x, y, z), V(x + dir.X, y, z + dir.Z))
end

function Furnish.build(ctx, root: Instance): { BasePart }
	local existing = {}
	for _, d in root:GetDescendants() do
		existing[d] = true
	end
	local L = ctx.Layout
	local G, U = L.Y.Ground, L.Y.Upstairs
	local KM, KC = Kit.M, Kit.C
	local WOOD_DARK = KC.WoodDark
	local WOOD_MID = KC.WoodMid
	local WOOD_LIGHT = KC.WoodLight
	local BRASS = KC.Brass

	local function room(name: string): Instance
		return root:FindFirstChild(name) or root
	end
	local function lamp(parent, roomName: string, cf: CFrame, kind: string, base: Color3?, shade: Color3?)
		local _, bulb, light
		if kind == "floor" then
			_, bulb, light = Kit.floorLamp(parent, cf, shade)
		else
			_, bulb, light = Kit.tableLamp(parent, cf, base, shade)
		end
		if ctx.Power and bulb then
			ctx.Power.registerLight(roomName, bulb, light)
		end
	end
	local function sconce(parent, cf: CFrame)
		local _, bulb, light = Kit.sconce(parent, cf)
		if ctx.Power and bulb then
			ctx.Power.registerLight("Decor", bulb, light)
		end
	end
	local seed = 300
	local function painting(parent, cf: CFrame, w: number, h: number, frame: Color3?)
		seed += 7
		return Kit.picture(parent, cf, w, h, frame or WOOD_DARK, seed)
	end
	-- a piece of furniture under a dust sheet: a soft draped block, its hem on the floor (cf at the floor)
	local function sheeted(parent, cf: CFrame, size: Vector3)
		local m = Kit.model(parent, "DustSheet")
		local sheet = Color3.fromRGB(222, 218, 206)
		Kit.soft(m, "Sheet", cf * CF(0, size.Y / 2, 0), size, 0.35, sheet, KM.Fabric)
		Kit.soft(m, "SheetHem", cf * CF(0, 0.12, 0), V(size.X + 0.25, 0.24, size.Z + 0.25), 0.1, Kit.darker(sheet, 0.06), KM.Fabric)
		Kit.collider(m, cf * CF(0, size.Y / 2, 0), size)
		return m
	end

	---------------------------------------------------------------------------
	-- THE FRONT HALL
	---------------------------------------------------------------------------
	local hall = room("Hallway")
	-- the stairwell's long wall (x = 6, facing the stairs): the family photos hang here (World/Haunt: Grandma's portrait
	-- among them), so a console and its lamp under them and two sconce pools in the gaps between the frames
	do
		local _, h = Kit.consoleTable(hall, F(4.4, G, 10, NX), 5, 1.4, WOOD_DARK)
		lamp(hall, "Hallway", F(4.4, G + h, 8.2, NX), "table", Color3.fromRGB(180, 150, 110), Color3.fromRGB(236, 222, 196))
		Kit.vaseFlowers(hall, F(4.4, G + h, 11.6, NX), 1.0, Color3.fromRGB(60, 70, 90), Color3.fromRGB(220, 200, 150), 17)
		Kit.bookStack(hall, F(4.45, G + h, 10.2, NX), 2, 41)
		sconce(hall, F(5.58, G + 7.8, 6.65, NX))
		sconce(hall, F(5.58, G + 7.8, 14.55, NX))
	end
	-- the foyer: a painting over the bench, and one by the living room arch
	painting(hall, F(11.6, G + 7.2, -26.6, NX), 3.4, 2.2)
	painting(hall, F(-7.6, G + 6.9, -12.6, PX), 1.9, 2.5, BRASS)
	-- the nook by the back hall: a small table and its lamp
	do
		local _, h = Kit.consoleTable(hall, F(10.7, G, -2.5, NX), 2.6, 1.2, WOOD_MID)
		lamp(hall, "Hallway", F(10.7, G + h, -2.5, NX), "table", Color3.fromRGB(70, 80, 70), Color3.fromRGB(230, 214, 186))
	end

	-- (the back hall's wall already has Finish's framed picture)

	---------------------------------------------------------------------------
	-- THE LIVING ROOM: a sconce either side of the chimney breast, over the firewood (v145)
	---------------------------------------------------------------------------
	local living = room("Living")
	sconce(living, F(-39.38, G + 7.8, -18.7, PX))
	sconce(living, F(-39.38, G + 7.8, -5.3, PX))

	---------------------------------------------------------------------------
	-- THE UPSTAIRS HALL
	---------------------------------------------------------------------------
	local uhall = room("UpperHall")
	-- the long west wall, by the master bedroom: a console, its lamp, three paintings (the last hangs crooked), two sconces
	do
		local _, h = Kit.consoleTable(uhall, F(-6.55, U, -20, PX), 5, 1.4, WOOD_DARK)
		lamp(uhall, "UpperHall", F(-6.55, U + h, -21.8, PX), "table", Color3.fromRGB(196, 186, 168), Color3.fromRGB(236, 224, 200))
		Kit.photoFrame(uhall, F(-6.7, U + h, -19.6, PX), 0.8, 1.0, BRASS, 77)
		Kit.photoFrame(uhall, F(-6.5, U + h, -18.4, PX), 0.9, 0.7, WOOD_DARK, 78)
		painting(uhall, F(-7.6, U + 7.2, -25.6, PX), 3.0, 2.1)
		painting(uhall, F(-7.6, U + 7.4, -20, PX), 2.2, 3.0, BRASS)
		painting(uhall, F(-7.6, U + 7.0, -14.9, PX) * ANG(0, 0, rad(6)), 2.0, 1.6)
		sconce(uhall, F(-7.62, U + 7.8, -23, PX))
		sconce(uhall, F(-7.62, U + 7.8, -17, PX))
	end
	-- the east wall south of the guest room: a painting either side of the sconce
	painting(uhall, F(11.54, U + 7.0, -22.6, NX), 1.6, 2.2)
	painting(uhall, F(11.54, U + 7.0, -17.6, NX), 1.6, 2.2, BRASS)
	-- past the stairwell, by Jamie's door
	painting(uhall, F(-7.6, U + 7.0, 19.0, PX), 2.4, 1.7)
	-- between the bathroom and Lily's room: a low chest with a lamp, a painting, a plant
	do
		local _, h = Kit.consoleTable(uhall, F(10.6, U, 7.0, NX), 4, 1.4, WOOD_MID)
		lamp(uhall, "UpperHall", F(10.6, U + h, 5.6, NX), "table", Color3.fromRGB(150, 110, 80), Color3.fromRGB(232, 220, 196))
		Kit.bookStack(uhall, F(10.6, U + h, 8.0, NX), 3, 43)
		painting(uhall, F(11.54, U + 7.0, 13.6, NX), 2.2, 3.0)
		Kit.plant(uhall, F(10.6, U, 14.6, NX), 1.0, "snake")
	end

	---------------------------------------------------------------------------
	-- THE MASTER BEDROOM
	---------------------------------------------------------------------------
	local master = room("Master")
	-- (the north wall already has Dress's console under the painting: the bookcase goes past it, toward the hall)
	Kit.bookcase(master, F(-13.4, U + 0.05, -1.3, NZ), 4, 1.2, 8, 4, WOOD_DARK, 53)
	-- a reading corner by the window
	do
		local dir = V(-0.6, 0, -1).Unit
		Kit.armchair(master, CFrame.lookAt(V(-14.4, U, -6.4), V(-14.4, U, -6.4) + dir), Color3.fromRGB(120, 60, 50))
		lamp(master, "Master", F(-17.2, U, -5.0, NX), "floor", nil, Color3.fromRGB(236, 222, 196))
	end

	---------------------------------------------------------------------------
	-- THE GUEST ROOM (half storage)
	---------------------------------------------------------------------------
	local guest = room("Guest")
	do
		local _, h = Kit.dresser(guest, F(21, U, -7.7, NZ), 5, WOOD_LIGHT)
		Kit.mirror(guest, F(21, U + h + 2.1, -6.46, NZ), 3.4, 2.8, WOOD_LIGHT)
		lamp(guest, "Guest", F(19.3, U + h, -7.7, NZ), "table", Color3.fromRGB(190, 170, 130))
		Kit.photoFrame(guest, F(22.6, U + h, -7.6, NZ), 0.8, 1.0, WOOD_DARK, 79)
	end
	do
		local dir = V(-0.5, 0, -1).Unit
		Kit.armchair(guest, CFrame.lookAt(V(26.9, U, -10.4), V(26.9, U, -10.4) + dir), Color3.fromRGB(150, 130, 100))
		lamp(guest, "Guest", F(29.4, U, -7.9, NZ), "floor", nil, Color3.fromRGB(232, 216, 190))
	end
	-- what nobody uses, under dust sheets
	sheeted(guest, F(28.6, U, -16.0, NZ) * ANG(0, rad(14), 0), V(2.8, 3.6, 2.6))
	sheeted(guest, F(36.9, U, -23.5, NX) * ANG(0, rad(-6), 0), V(3.4, 5.2, 1.0))

	local added = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and not existing[d] then
			table.insert(added, d)
		end
	end
	return added
end

return Furnish
