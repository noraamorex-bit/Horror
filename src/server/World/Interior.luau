--[[
	Interior — furniture, props, items, clues, task props and hiding spots for 14 Alder Lane.
	Wall finishes (paint, wainscoting, trim, curtains, pictures) come from World/Finish.

	Adds to refs: Kitchen, TV, Fire, Footprints, Stepladder.
	Registers objective marker targets with Objectives.setTarget.
]]

local CollectionService = game:GetService("CollectionService")

local Interior = {}

local V = Vector3.new

function Interior.build(ctx, root: Instance, refs)
	local B = ctx.Builder
	local C, M = B.C, B.M
	local L = ctx.Layout
	local G, U, BS, A = L.Y.Ground, L.Y.Upstairs, L.Y.Basement, 29.4
	local target = ctx.Objectives.setTarget

	local function folder(name: string): Folder
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = root
		return f
	end

	local function box(parent, name, x0, y0, z0, x1, y1, z1, color, mat, extra)
		return B.box(parent, name, V(x0, y0, z0), V(x1, y1, z1), color, mat, extra)
	end

	-- decorative (no collision, no raycasts)
	local DECOR = { CanCollide = false, CanQuery = false }

	--[[ A box in "furniture space": centred on (cx, cz), `f` is the axis-aligned direction the
	     piece faces. offF moves it along f, offS along the side axis; w = width across the side
	     axis, d = depth along f; y0..y1 vertical. ]]
	local function fbox(parent, name, cx, cz, f: Vector3, offF, offS, w, d, y0, y1, color, mat, extra)
		local side = V(f.Z, 0, -f.X)
		local c = V(cx, (y0 + y1) / 2, cz) + f * offF + side * offS
		local size = math.abs(f.X) > 0.5 and V(d, y1 - y0, w) or V(w, y1 - y0, d)
		return B.block(parent, name, c, size, color, mat, 0, extra)
	end

	local function paper(parent, name, pos: Vector3, size: Vector3)
		return B.block(parent, name, pos, size, Color3.fromRGB(238, 234, 220), M.Plastic, 0, { CanCollide = false })
	end

	local function item(parent, name, pos: Vector3, size: Vector3, color, itemId: string, label: string, count: number?)
		local p = B.block(parent, name, pos, size, color, M.Plastic, 0, { CanCollide = false })
		ctx.Interaction.pickup(p, itemId, { Object = label, Count = count })
		return p
	end

	local WOOD_DARK = Color3.fromRGB(74, 52, 38)
	local WOOD_MID = Color3.fromRGB(128, 92, 62)
	local WOOD_LIGHT = Color3.fromRGB(176, 138, 98)
	local CREAM = Color3.fromRGB(236, 230, 214)
	local BRASS = Color3.fromRGB(196, 168, 104)
	local COUNTER = Color3.fromRGB(58, 58, 62)

	---------------------------------------------------------------------------
	-- Furniture
	---------------------------------------------------------------------------
	local function sofa(parent, cx, cz, y, length, f: Vector3, color: Color3, pillow: Color3?)
		local depth = 3.8
		local dark = color:Lerp(Color3.new(), 0.18)
		-- legs + base
		for _, s in { -1, 1 } do
			for _, ff in { -1, 1 } do
				fbox(parent, "Leg", cx, cz, f, ff * (depth / 2 - 0.4), s * (length / 2 - 0.4), 0.4, 0.4, y, y + 0.5, WOOD_DARK, M.Wood, DECOR)
			end
		end
		fbox(parent, "SofaBase", cx, cz, f, 0, 0, length, depth, y + 0.5, y + 1.6, dark, M.Fabric)
		-- seat cushions
		local n = math.max(1, math.floor(length / 3.2))
		local inner = length - 1.8
		for i = 1, n do
			local off = -inner / 2 + inner / n * (i - 0.5)
			fbox(parent, "SeatCushion", cx, cz, f, 0.25, off, inner / n - 0.12, depth - 1.1, y + 1.6, y + 2.35, color, M.Fabric)
			fbox(parent, "BackCushion", cx, cz, f, -depth / 2 + 0.75, off, inner / n - 0.12, 0.9, y + 2.35, y + 4.2, color, M.Fabric, DECOR)
		end
		fbox(parent, "SofaBack", cx, cz, f, -depth / 2 + 0.3, 0, length, 0.6, y + 1.6, y + 4.4, dark, M.Fabric)
		-- arms
		for _, s in { -1, 1 } do
			fbox(parent, "Arm", cx, cz, f, 0, s * (length / 2 - 0.45), 0.9, depth, y + 1.6, y + 3.1, dark, M.Fabric)
		end
		-- throw pillows
		if pillow then
			for _, s in { -1, 1 } do
				local p = fbox(parent, "Pillow", cx, cz, f, -depth / 2 + 1.35, s * (inner / 2 - 0.8), 1.3, 0.35, y + 2.35, y + 3.6, pillow, M.Fabric, DECOR)
				p.CFrame *= CFrame.Angles(0, 0, math.rad(s * 8))
			end
		end
	end

	local function coffeeTable(parent, x0, z0, x1, z1, y, h, color)
		box(parent, "TableTop", x0, y + h - 0.3, z0, x1, y + h, z1, color, M.Wood)
		box(parent, "TableShelf", x0 + 0.3, y + 0.5, z0 + 0.3, x1 - 0.3, y + 0.7, z1 - 0.3, color:Lerp(Color3.new(), 0.1), M.Wood, DECOR)
		for _, c in { { x0 + 0.1, z0 + 0.1 }, { x1 - 0.5, z0 + 0.1 }, { x0 + 0.1, z1 - 0.5 }, { x1 - 0.5, z1 - 0.5 } } do
			box(parent, "Leg", c[1], y, c[2], c[1] + 0.4, y + h - 0.3, c[2] + 0.4, color:Lerp(Color3.new(), 0.2), M.Wood)
		end
	end

	local function chair(parent, x, z, y, f: Vector3, color: Color3?)
		color = color or WOOD_MID
		fbox(parent, "Seat", x, z, f, 0, 0, 1.9, 1.9, y + 1.9, y + 2.2, color, M.Wood)
		for _, s in { -1, 1 } do
			for _, ff in { -1, 1 } do
				fbox(parent, "ChairLeg", x, z, f, ff * 0.75, s * 0.75, 0.25, 0.25, y, y + 1.9, color, M.Wood, DECOR)
			end
			fbox(parent, "BackPost", x, z, f, -0.85, s * 0.75, 0.25, 0.25, y + 2.2, y + 4.8, color, M.Wood, DECOR)
		end
		for k = 0, 2 do
			fbox(parent, "BackSlat", x, z, f, -0.85, 0, 1.4, 0.15, y + 2.8 + k * 0.7, y + 3.05 + k * 0.7, color, M.Wood, DECOR)
		end
		box(parent, "ChairBlock", x - 0.9, y, z - 0.9, x + 0.9, y + 2, z + 0.9, color, M.Wood, { Transparency = 1 })
	end

	local function diningTable(parent, x0, z0, x1, z1, y, color)
		box(parent, "TableTop", x0, y + 3.5, z0, x1, y + 3.85, z1, color, M.Wood)
		box(parent, "Apron", x0 + 0.3, y + 3.1, z0 + 0.3, x1 - 0.3, y + 3.5, z1 - 0.3, color:Lerp(Color3.new(), 0.15), M.Wood, DECOR)
		for _, c in { { x0 + 0.3, z0 + 0.3 }, { x1 - 0.8, z0 + 0.3 }, { x0 + 0.3, z1 - 0.8 }, { x1 - 0.8, z1 - 0.8 } } do
			box(parent, "Leg", c[1], y, c[2], c[1] + 0.5, y + 3.5, c[2] + 0.5, color:Lerp(Color3.new(), 0.15), M.Wood)
		end
	end

	local function plant(parent, pos: Vector3, size: number)
		B.cylinder(parent, "Pot", pos + V(0, size * 0.35, 0), size * 0.7, size * 0.8, Color3.fromRGB(170, 96, 64), M.Concrete, CFrame.Angles(0, 0, math.rad(90)))
		B.cylinder(parent, "Soil", pos + V(0, size * 0.7, 0), 0.05, size * 0.7, Color3.fromRGB(50, 36, 26), M.Fabric, CFrame.Angles(0, 0, math.rad(90)))
		local rng = Random.new(math.floor(pos.X * 31 + pos.Z * 17))
		for _ = 1, 5 do
			B.part(parent, {
				Name = "Leaves",
				Shape = Enum.PartType.Ball,
				Size = V(1, 1, 1) * size * rng:NextNumber(0.55, 0.85),
				CFrame = CFrame.new(pos + V(rng:NextNumber(-0.35, 0.35) * size, size * rng:NextNumber(1.0, 1.7), rng:NextNumber(-0.35, 0.35) * size)),
				Color = Color3.fromRGB(46 + rng:NextInteger(0, 20), 90 + rng:NextInteger(0, 25), 50),
				Material = Enum.Material.LeafyGrass,
				CanCollide = false,
				CanQuery = false,
			})
		end
	end

	local function rug(parent, x0, z0, x1, z1, y, color: Color3, border: Color3?)
		box(parent, "Rug", x0, y, z0, x1, y + 0.05, z1, border or color:Lerp(Color3.new(1, 1, 1), 0.25), M.Fabric, DECOR)
		box(parent, "RugField", x0 + 0.6, y + 0.05, z0 + 0.6, x1 - 0.6, y + 0.08, z1 - 0.6, color, M.Fabric, DECOR)
	end

	-- lower kitchen/bathroom cabinets along a wall: fronts face f
	local function cabinets(parent, x0, z0, x1, z1, y, f: Vector3, color: Color3, top: Color3?, h: number?)
		h = h or 3.5
		box(parent, "Cabinet", x0, y + 0.35, z0, x1, y + h, z1, color, M.Wood)
		box(parent, "ToeKick", x0 + (f.X > 0 and 0 or 0), y, z0, x1, y + 0.35, z1, Color3.fromRGB(40, 36, 32), M.Wood, DECOR)
		if top then
			local pad = 0.25
			box(parent, "Countertop", x0 - (f.X < 0 and pad or 0), y + h, z0 - (f.Z < 0 and pad or 0), x1 + (f.X > 0 and pad or 0), y + h + 0.3, z1 + (f.Z > 0 and pad or 0), top, M.Marble)
		end
		-- door fronts with handles
		local alongX = math.abs(f.Z) > 0.5
		local a0, a1 = alongX and x0 or z0, alongX and x1 or z1
		local face = alongX and (f.Z > 0 and z1 or z0) or (f.X > 0 and x1 or x0)
		local n = math.max(1, math.floor((a1 - a0) / 2.2))
		local w = (a1 - a0) / n
		for i = 0, n - 1 do
			local s0, s1 = a0 + i * w + 0.12, a0 + (i + 1) * w - 0.12
			local fz = face + (alongX and f.Z or f.X) * 0.06
			if alongX then
				box(parent, "Door", s0, y + 0.55, math.min(face, fz), s1, y + h - 0.9, math.max(face, fz), color:Lerp(Color3.new(1, 1, 1), 0.08), M.Wood, DECOR)
				box(parent, "Drawer", s0, y + h - 0.8, math.min(face, fz), s1, y + h - 0.15, math.max(face, fz), color:Lerp(Color3.new(1, 1, 1), 0.08), M.Wood, DECOR)
				box(parent, "Handle", (s0 + s1) / 2 - 0.4, y + h - 0.52, fz, (s0 + s1) / 2 + 0.4, y + h - 0.42, fz + f.Z * 0.1, BRASS, M.Metal, DECOR)
				box(parent, "Handle", s1 - 0.25, y + 1.4, fz, s1 - 0.15, y + 2.2, fz + f.Z * 0.1, BRASS, M.Metal, DECOR)
			else
				box(parent, "Door", math.min(face, fz), y + 0.55, s0, math.max(face, fz), y + h - 0.9, s1, color:Lerp(Color3.new(1, 1, 1), 0.08), M.Wood, DECOR)
				box(parent, "Drawer", math.min(face, fz), y + h - 0.8, s0, math.max(face, fz), y + h - 0.15, s1, color:Lerp(Color3.new(1, 1, 1), 0.08), M.Wood, DECOR)
				box(parent, "Handle", fz, y + h - 0.52, (s0 + s1) / 2 - 0.4, fz + f.X * 0.1, y + h - 0.42, (s0 + s1) / 2 + 0.4, BRASS, M.Metal, DECOR)
				box(parent, "Handle", fz, y + 1.4, s1 - 0.25, fz + f.X * 0.1, y + 2.2, s1 - 0.15, BRASS, M.Metal, DECOR)
			end
		end
	end

	local function upperCabinets(parent, x0, z0, x1, z1, y0, y1, f: Vector3, color: Color3)
		box(parent, "UpperCabinet", x0, y0, z0, x1, y1, z1, color, M.Wood)
		local alongX = math.abs(f.Z) > 0.5
		local a0, a1 = alongX and x0 or z0, alongX and x1 or z1
		local face = alongX and (f.Z > 0 and z1 or z0) or (f.X > 0 and x1 or x0)
		local n = math.max(1, math.floor((a1 - a0) / 2.2))
		local w = (a1 - a0) / n
		for i = 0, n - 1 do
			local s0, s1 = a0 + i * w + 0.12, a0 + (i + 1) * w - 0.12
			local fz = face + (alongX and f.Z or f.X) * 0.06
			if alongX then
				box(parent, "Door", s0, y0 + 0.15, math.min(face, fz), s1, y1 - 0.15, math.max(face, fz), color:Lerp(Color3.new(1, 1, 1), 0.08), M.Wood, DECOR)
				box(parent, "Handle", s1 - 0.25, y0 + 0.4, fz, s1 - 0.15, y0 + 1.1, fz + f.Z * 0.1, BRASS, M.Metal, DECOR)
			else
				box(parent, "Door", math.min(face, fz), y0 + 0.15, s0, math.max(face, fz), y1 - 0.15, s1, color:Lerp(Color3.new(1, 1, 1), 0.08), M.Wood, DECOR)
				box(parent, "Handle", fz, y0 + 0.4, s1 - 0.25, fz + f.X * 0.1, y0 + 1.1, s1 - 0.15, BRASS, M.Metal, DECOR)
			end
		end
	end

	local function nightstand(parent, x, z, y, f: Vector3, color: Color3)
		fbox(parent, "Nightstand", x, z, f, 0, 0, 2.2, 2, y, y + 2.4, color, M.Wood)
		fbox(parent, "Drawer", x, z, f, 1.02, 0, 1.8, 0.06, y + 1.4, y + 2.1, color:Lerp(Color3.new(1, 1, 1), 0.1), M.Wood, DECOR)
		fbox(parent, "Knob", x, z, f, 1.1, 0, 0.25, 0.15, y + 1.65, y + 1.85, BRASS, M.Metal, DECOR)
	end

	local function dresser(parent, x, z, y, f: Vector3, width: number, color: Color3)
		fbox(parent, "Dresser", x, z, f, 0, 0, width, 1.8, y, y + 3.8, color, M.Wood)
		for r = 0, 2 do
			fbox(parent, "Drawer", x, z, f, 0.92, 0, width - 0.4, 0.06, y + 0.4 + r * 1.1, y + 1.35 + r * 1.1, color:Lerp(Color3.new(1, 1, 1), 0.1), M.Wood, DECOR)
			for _, s in { -1, 1 } do
				fbox(parent, "Knob", x, z, f, 1.0, s * width / 4, 0.25, 0.15, y + 0.8 + r * 1.1, y + 1.0 + r * 1.1, BRASS, M.Metal, DECOR)
			end
		end
	end

	-- a toilet whose bowl faces f; (x, z) is the centre of its 3-stud footprint
	local function toilet(parent, x, z, y, f: Vector3)
		local PORCELAIN = Color3.fromRGB(242, 242, 238)
		local UP = CFrame.Angles(0, 0, math.rad(90))
		local bowl = V(x, 0, z) + f * 0.35
		-- one simple collider so nobody clips into the porcelain
		fbox(parent, "ToiletBlock", x, z, f, 0, 0, 2, 3, y, y + 1.9, PORCELAIN, M.Plastic, { Transparency = 1 })
		-- pedestal and an oval bowl (two overlapping discs)
		B.cylinder(parent, "Pedestal", V(bowl.X, y + 0.7, bowl.Z) - f * 0.15, 1.4, 1.1, PORCELAIN, M.Plastic, UP).CanCollide = false
		B.cylinder(parent, "Bowl", V(bowl.X, y + 1.5, bowl.Z), 0.6, 1.8, PORCELAIN, M.Plastic, UP).CanCollide = false
		B.cylinder(parent, "BowlFront", V(bowl.X, y + 1.5, bowl.Z) + f * 0.3, 0.6, 1.5, PORCELAIN, M.Plastic, UP).CanCollide = false
		-- seat ring, the dark opening and a little water
		B.cylinder(parent, "Seat", V(bowl.X, y + 1.86, bowl.Z) + f * 0.12, 0.12, 1.95, Color3.fromRGB(250, 250, 248), M.Plastic, UP).CanCollide = false
		B.cylinder(parent, "BowlOpening", V(bowl.X, y + 1.93, bowl.Z) + f * 0.12, 0.03, 1.25, Color3.fromRGB(150, 170, 176), M.Glass, UP).CanCollide = false
		-- lid standing up against the tank
		fbox(parent, "Lid", x, z, f, -0.62, 0, 1.8, 0.12, y + 1.95, y + 3.45, Color3.fromRGB(250, 250, 248), M.Plastic, DECOR)
		-- cistern with a lid and a chrome lever
		fbox(parent, "Tank", x, z, f, -1.1, 0, 2.1, 0.8, y + 1.7, y + 3.7, PORCELAIN, M.Plastic)
		fbox(parent, "TankLid", x, z, f, -1.1, 0, 2.3, 0.95, y + 3.7, y + 3.9, Color3.fromRGB(250, 250, 248), M.Plastic, DECOR)
		fbox(parent, "FlushLever", x, z, f, -0.68, 0.7, 0.5, 0.1, y + 3.3, y + 3.42, C.Steel, M.Metal, DECOR)
		-- supply pipe to the wall
		fbox(parent, "SupplyPipe", x, z, f, -1.3, -0.7, 0.12, 0.12, y + 0.3, y + 1.7, C.Steel, M.Metal, DECOR)
		-- toilet paper holder beside it
		fbox(parent, "PaperRoll", x, z, f, -0.4, 1.6, 0.5, 0.5, y + 2.2, y + 2.7, Color3.fromRGB(248, 248, 244), M.Fabric, DECOR)
	end

	-- bed with an under-bed hiding spot. `open` = side you crawl in from, `head` = headboard side
	local function bed(parent, name, x0, z0, x1, z1, y, duvet: Color3, open: Vector3, head: Vector3, room: string, frameColor: Color3?)
		frameColor = frameColor or WOOD_MID
		local center = V((x0 + x1) / 2, y, (z0 + z1) / 2)
		local frame = box(parent, "BedFrame", x0, y + 1.6, z0, x1, y + 2.2, z1, frameColor, M.Wood)
		for _, c in { { x0, z0 }, { x1 - 0.5, z0 }, { x0, z1 - 0.5 }, { x1 - 0.5, z1 - 0.5 } } do
			box(parent, "BedLeg", c[1], y, c[2], c[1] + 0.5, y + 1.6, c[2] + 0.5, frameColor, M.Wood)
		end
		box(parent, "Mattress", x0 + 0.2, y + 2.2, z0 + 0.2, x1 - 0.2, y + 3.3, z1 - 0.2, Color3.fromRGB(245, 243, 238), M.Fabric)
		-- headboard
		local hx = math.abs(head.X) > 0.5
		local len = hx and (z1 - z0) or (x1 - x0)
		local headPos = center + head * ((hx and (x1 - x0) or (z1 - z0)) / 2 - 0.2)
		local hbSize = hx and V(0.4, 5.5, len + 0.4) or V(len + 0.4, 5.5, 0.4)
		B.block(parent, "Headboard", headPos + V(0, 2.75, 0), hbSize, frameColor, M.Wood)
		local panelSize = hx and V(0.1, 3.2, len - 1.2) or V(len - 1.2, 3.2, 0.1)
		B.block(parent, "HeadboardPanel", headPos - head * 0.25 + V(0, 3.6, 0), panelSize, frameColor:Lerp(Color3.new(), 0.15), M.Fabric, 0, DECOR)
		-- corner posts, and a low footboard opposite the headboard
		local bedLen = hx and (x1 - x0) or (z1 - z0)
		local sideAxis = hx and V(0, 0, 1) or V(1, 0, 0)
		for _, e in { 1, -1 } do
			for _, s in { -1, 1 } do
				local p = center + head * e * (bedLen / 2 - 0.2) + sideAxis * s * (len / 2 - 0.05)
				local top = e == 1 and 6.4 or 4.2
				B.block(parent, "BedPost", p + V(0, top / 2, 0), V(0.5, top, 0.5), frameColor:Lerp(Color3.new(), 0.1), M.Wood, 0, DECOR)
				B.part(parent, { Name = "PostFinial", Shape = Enum.PartType.Ball, Size = V(0.6, 0.6, 0.6), CFrame = CFrame.new(p + V(0, top + 0.2, 0)), Color = frameColor, Material = M.Wood, CanCollide = false, CanQuery = false })
			end
		end
		local footPos = center - head * (bedLen / 2 - 0.2)
		B.block(parent, "Footboard", footPos + V(0, 3, 0), hx and V(0.3, 1.8, len - 0.4) or V(len - 0.4, 1.8, 0.3), frameColor, M.Wood, 0, DECOR)
		-- fitted sheet, then a duvet that drapes over both long sides and the foot
		local sheet = Color3.fromRGB(246, 244, 238)
		local duvetLen = bedLen * 0.72
		local duvetCenter = center - head * (bedLen / 2 - duvetLen / 2 - 0.35) + V(0, 3.47, 0)
		B.block(parent, "Duvet", duvetCenter, hx and V(duvetLen, 0.4, len + 0.3) or V(len + 0.3, 0.4, duvetLen), duvet, M.Fabric, 0, DECOR)
		for _, s in { -1, 1 } do
			local drape = duvetCenter + sideAxis * s * (len / 2 + 0.12) - V(0, 0.75, 0)
			B.block(parent, "DuvetDrape", drape, hx and V(duvetLen, 1.2, 0.14) or V(0.14, 1.2, duvetLen), duvet:Lerp(Color3.new(), 0.08), M.Fabric, 0, DECOR)
		end
		B.block(parent, "DuvetFoot", duvetCenter - head * (duvetLen / 2 + 0.05) - V(0, 0.55, 0), hx and V(0.14, 1.0, len + 0.3) or V(len + 0.3, 1.0, 0.14), duvet:Lerp(Color3.new(), 0.08), M.Fabric, 0, DECOR)
		-- turned-down top edge showing the sheet
		B.block(parent, "DuvetFold", duvetCenter + head * (duvetLen / 2 - 0.45) + V(0, 0.24, 0), hx and V(0.9, 0.18, len + 0.32) or V(len + 0.32, 0.18, 0.9), sheet, M.Fabric, 0, DECOR)
		-- a knitted throw across the foot
		B.block(parent, "Throw", duvetCenter - head * (duvetLen / 2 - 1.1) + V(0, 0.24, 0), hx and V(1.6, 0.14, len + 0.36) or V(len + 0.36, 0.14, 1.6), duvet:Lerp(Color3.fromRGB(230, 220, 200), 0.55), M.Fabric, 0, DECOR)
		-- plump pillows leaning on the headboard
		local pillows = len > 6 and { -len / 4, len / 4 } or { 0 }
		for _, o in pillows do
			local pw = math.min(2.8, len / #pillows - 0.4)
			local pos = headPos - head * 1.0 + sideAxis * o + V(0, 3.75, 0)
			local cf = CFrame.lookAt(pos, pos - head) * CFrame.Angles(math.rad(-25), 0, 0)
			B.part(parent, { Name = "Pillow", Size = V(pw, 0.7, 1.5), CFrame = cf, Color = sheet, Material = M.Fabric, CanCollide = false, CanQuery = false })
			B.part(parent, { Name = "AccentPillow", Size = V(pw * 0.6, 0.5, 1.0), CFrame = cf * CFrame.new(0, 0.15, -0.95) * CFrame.Angles(math.rad(10), 0, 0), Color = duvet:Lerp(Color3.new(1, 1, 1), 0.45), Material = M.Fabric, CanCollide = false, CanQuery = false })
		end
		-- skirt on the closed sides hides whoever is under it
		for _, dir in { V(1, 0, 0), V(-1, 0, 0), V(0, 0, 1), V(0, 0, -1) } do
			if dir ~= open then
				local half = math.abs(dir.X) > 0 and (x1 - x0) / 2 or (z1 - z0) / 2
				local p = center + dir * half + V(0, 0.8, 0)
				local size = math.abs(dir.X) > 0 and V(0.1, 1.6, z1 - z0) or V(x1 - x0, 1.6, 0.1)
				B.block(parent, "BedSkirt", p, size, duvet:Lerp(Color3.new(), 0.25), M.Fabric, 0, DECOR)
			end
		end
		local half = math.abs(open.X) > 0 and (x1 - x0) / 2 or (z1 - z0) / 2
		local edge = center + open * half
		local inside = center + open * 0.5 + V(0, 0.9, 0)
		ctx.Hiding.register(frame, {
			Name = name,
			Room = room,
			Inside = CFrame.lookAt(inside, inside + open) * CFrame.Angles(-math.rad(90), 0, 0),
			View = CFrame.lookAt(edge - open * 0.6 + V(0, 0.8, 0), edge + open * 10 + V(0, 1.6, 0)),
			Exit = CFrame.lookAt(edge + open * 2.8 + V(0, 3, 0), edge + open * 6 + V(0, 3, 0)),
			PromptOffset = frame.CFrame:PointToObjectSpace(edge + V(0, 1.2, 0)),
		})
		return frame
	end

	-- wardrobe / closet: footprint + the direction its doors face
	local function wardrobe(parent, name, x0, z0, x1, z1, y, facing: Vector3, room: string, color: Color3?)
		color = color or WOOD_MID
		local h = 8.5
		local center = V((x0 + x1) / 2, y, (z0 + z1) / 2)
		local alongX = math.abs(facing.Z) > 0
		local width = alongX and (x1 - x0) or (z1 - z0)
		local depth = alongX and (z1 - z0) or (x1 - x0)
		local back = center - facing * (depth / 2 - 0.15)
		B.block(parent, "WardrobeBack", back + V(0, h / 2, 0), alongX and V(width, h, 0.3) or V(0.3, h, width), color, M.Wood)
		for s = -1, 1, 2 do
			local side = center + (alongX and V(s * (width / 2 - 0.15), 0, 0) or V(0, 0, s * (width / 2 - 0.15)))
			B.block(parent, "WardrobeSide", side + V(0, h / 2, 0), alongX and V(0.3, h, depth) or V(depth, h, 0.3), color, M.Wood)
		end
		B.block(parent, "WardrobeTop", center + V(0, h - 0.15, 0), alongX and V(width, 0.3, depth) or V(depth, 0.3, width), color, M.Wood)
		B.block(parent, "WardrobeCrown", center + V(0, h + 0.15, 0), alongX and V(width + 0.4, 0.3, depth + 0.4) or V(depth + 0.4, 0.3, width + 0.4), color:Lerp(Color3.new(), 0.1), M.Wood, 0, DECOR)
		local frontPos = center + facing * (depth / 2 - 0.1)
		local doors = B.block(parent, "WardrobeDoors", frontPos + V(0, h / 2, 0), alongX and V(width, h - 0.4, 0.25) or V(0.25, h - 0.4, width), color:Lerp(Color3.new(1, 1, 1), 0.05), M.Wood)
		B.block(parent, "DoorSeam", frontPos + facing * 0.14 + V(0, h / 2, 0), alongX and V(0.08, h - 0.6, 0.05) or V(0.05, h - 0.6, 0.08), color:Lerp(Color3.new(), 0.4), M.Wood, 0, DECOR)
		for s = -1, 1, 2 do
			local off = alongX and V(s * 0.35, 0, 0) or V(0, 0, s * 0.35)
			B.block(parent, "Handle", frontPos + facing * 0.2 + off + V(0, h / 2, 0), V(0.15, 0.9, 0.15), BRASS, M.Metal, 0, DECOR)
			for k = 0, 1 do
				local panelOff = alongX and V(s * width / 4, 0, 0) or V(0, 0, s * width / 4)
				B.block(parent, "DoorPanel", frontPos + facing * 0.14 + panelOff + V(0, 2 + k * 4, 0), alongX and V(width / 2 - 0.8, 3.2, 0.05) or V(0.05, 3.2, width / 2 - 0.8), color:Lerp(Color3.new(), 0.08), M.Wood, 0, DECOR)
			end
		end
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

	local function shelf(parent, x0, z0, x1, z1, y, h, levels, color: Color3?)
		color = color or WOOD_DARK
		box(parent, "Shelf", x0, y, z0, x1, y + h, z1, color, M.Wood, { Transparency = 0.999 })
		local alongX = (x1 - x0) > (z1 - z0)
		-- sides
		if alongX then
			box(parent, "ShelfSide", x0, y, z0, x0 + 0.2, y + h, z1, color, M.Wood, DECOR)
			box(parent, "ShelfSide", x1 - 0.2, y, z0, x1, y + h, z1, color, M.Wood, DECOR)
		else
			box(parent, "ShelfSide", x0, y, z0, x1, y + h, z0 + 0.2, color, M.Wood, DECOR)
			box(parent, "ShelfSide", x0, y, z1 - 0.2, x1, y + h, z1, color, M.Wood, DECOR)
		end
		for i = 0, levels do
			box(parent, "ShelfBoard", x0, y + i * h / levels, z0, x1, y + i * h / levels + 0.25, z1, color, M.Wood, DECOR)
		end
		local rng = Random.new(math.floor(x0 * 7 + z0 * 3))
		for i = 0, levels - 1 do
			local yb = y + i * h / levels + 0.25
			local len = alongX and (x1 - x0) or (z1 - z0)
			local cursor = 0.4
			while cursor < len - 1 do
				local w = rng:NextNumber(0.25, 0.5)
				local bh = rng:NextNumber(1, math.min(2.2, h / levels - 0.4))
				local col = Color3.fromHSV(rng:NextNumber(), rng:NextNumber(0.25, 0.55), rng:NextNumber(0.25, 0.6))
				if rng:NextNumber() < 0.12 then
					cursor += 0.8 -- a gap, sometimes a knick-knack
				elseif alongX then
					box(parent, "Book", x0 + cursor, yb, z0 + 0.15, x0 + cursor + w, yb + bh, z1 - 0.15, col, M.Cardboard, DECOR)
				else
					box(parent, "Book", x0 + 0.15, yb, z0 + cursor, x1 - 0.15, yb + bh, z0 + cursor + w, col, M.Cardboard, DECOR)
				end
				cursor += w + 0.03
			end
		end
	end

	-- a lamp that follows its room's light switch (and the breaker)
	local function lamp(parent, room: string, pos: Vector3, kind: string)
		local shadeSize = kind == "floor" and V(1.8, 1.4, 1.8) or V(1.3, 1, 1.3)
		local height = kind == "floor" and 6 or 1.6
		B.cylinder(parent, "LampBase", pos + V(0, 0.1, 0), 0.2, kind == "floor" and 1.2 or 0.8, C.Black, M.Metal, CFrame.Angles(0, 0, math.rad(90)))
		B.block(parent, "LampPole", pos + V(0, height / 2, 0), V(0.15, height, 0.15), BRASS, M.Metal, 0, DECOR)
		local shade = B.block(parent, "LampShade", pos + V(0, height + shadeSize.Y / 2, 0), shadeSize, Color3.fromRGB(235, 215, 180), M.Fabric, 0, DECOR)
		local light = Instance.new("PointLight")
		light.Range = kind == "floor" and 20 or 14
		light.Brightness = kind == "floor" and 1.1 or 0.8
		light.Color = Color3.fromRGB(255, 190, 125)
		light.Shadows = true
		-- the glowing bulb sits inside the fabric shade, so the shade itself keeps its colour
		local bulb = B.part(parent, { Name = "LampBulb", Shape = Enum.PartType.Ball, Size = V(0.5, 0.6, 0.5), CFrame = CFrame.new(pos + V(0, height + 0.25, 0)), Color = Color3.fromRGB(255, 214, 160), CanCollide = false, CanQuery = false })
		light.Parent = bulb
		ctx.Power.registerLight(room, bulb, light)
		shade.Transparency = 0.08
	end

	-- pendant over an island/table, on its room's switch
	local function pendant(parent, room: string, pos: Vector3, drop: number)
		B.block(parent, "PendantCord", pos - V(0, drop / 2, 0), V(0.08, drop, 0.08), C.Black, M.Plastic, 0, DECOR)
		local shade = B.part(parent, {
			Name = "PendantShade",
			Shape = Enum.PartType.Ball,
			Size = V(1.4, 1.4, 1.4),
			CFrame = CFrame.new(pos - V(0, drop + 0.5, 0)),
			Color = Color3.fromRGB(214, 190, 150),
			Material = Enum.Material.Glass,
			Transparency = 0.35,
			CanCollide = false,
			CanQuery = false,
		})
		local bulb = B.part(parent, { Name = "PendantBulb", Shape = Enum.PartType.Ball, Size = V(0.45, 0.55, 0.45), CFrame = shade.CFrame, Color = Color3.fromRGB(255, 214, 160), CanCollide = false, CanQuery = false })
		local light = Instance.new("PointLight")
		light.Range = 16
		light.Brightness = 1
		light.Color = Color3.fromRGB(255, 200, 140)
		light.Shadows = true
		light.Parent = bulb
		ctx.Power.registerLight(room, bulb, light)
	end

	-- a ceiling fan: the client spins the blades (CollectionService "Spinner")
	local function ceilingFan(parent, pos: Vector3)
		local fan = Instance.new("Model")
		fan.Name = "CeilingFan"
		fan.Parent = parent
		B.block(fan, "FanRod", pos - V(0, 0.6, 0), V(0.18, 1.2, 0.18), WOOD_DARK, M.Metal, 0, DECOR)
		local hub = B.cylinder(fan, "FanHub", pos - V(0, 1.4, 0), 0.6, 1.2, WOOD_DARK, M.Metal, CFrame.Angles(0, 0, math.rad(90)))
		hub.CanCollide = false
		hub.CanQuery = false
		for k = 0, 4 do
			local a = k / 5 * math.pi * 2
			B.part(fan, {
				Name = "Blade",
				Size = V(3.4, 0.08, 0.9),
				CFrame = CFrame.new(pos - V(0, 1.45, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(2.1, 0, 0) * CFrame.Angles(math.rad(8), 0, 0),
				Color = WOOD_MID,
				Material = M.Wood,
				CanCollide = false,
				CanQuery = false,
			})
		end
		fan.PrimaryPart = hub
		fan:SetAttribute("Speed", 3.2)
		CollectionService:AddTag(fan, "Spinner")
		return fan
	end

	local function tv(parent, center: Vector3, f: Vector3, w: number, h: number)
		local frame = fbox(parent, "TV", center.X, center.Z, f, 0, 0, w, 0.35, center.Y, center.Y + h, Color3.fromRGB(16, 16, 18), M.Plastic)
		local screen = fbox(parent, "Screen", center.X, center.Z, f, 0.2, 0, w - 0.3, 0.05, center.Y + 0.15, center.Y + h - 0.15, Color3.fromRGB(8, 10, 14), Enum.Material.Glass, { CanCollide = false, Reflectance = 0.15 })
		return frame, screen
	end

	---------------------------------------------------------------------------
	-- LIVING ROOM
	---------------------------------------------------------------------------
	local living = folder("Living")
	rug(living, -37, -21, -19, -2, G, Color3.fromRGB(120, 60, 52), Color3.fromRGB(190, 160, 120))
	sofa(living, -30, -10, G, 10, V(-1, 0, 0), Color3.fromRGB(96, 104, 98), Color3.fromRGB(190, 150, 90))
	sofa(living, -24, -18, G, 7, V(0, 0, -1), Color3.fromRGB(96, 104, 98), Color3.fromRGB(150, 70, 60))
	sofa(living, -13, -24.5, G, 3.8, V(-1, 0, 0), Color3.fromRGB(128, 84, 62))
	coffeeTable(living, -37.2, -12.6, -33.6, -7.4, G, 2.2, WOOD_MID)
	box(living, "Magazines", -36.6, G + 2.2, -9.2, -35.2, G + 2.4, -7.9, Color3.fromRGB(180, 60, 50), M.Cardboard, DECOR)
	B.cylinder(living, "Candle", V(-34.4, G + 2.6, -11.6), 0.8, 0.5, CREAM, M.Plastic, CFrame.Angles(0, 0, math.rad(90)))
	box(living, "SideTable", -39.5, G, -18.5, -37.6, G + 2.6, -16.5, WOOD_MID, M.Wood)
	plant(living, V(-38.6, G, -27.6), 1.6)
	plant(living, V(-10.2, G, -4.5), 1.3)
	lamp(living, "Living", V(-38.5, G, -2.5), "floor")
	lamp(living, "Living", V(-15.6, G, -28.4), "floor")
	shelf(living, -9.6, -12.5, -8.4, -3, G, 8.5, 4)
	target("Couch", V(-30, G + 2.5, -10))
	target("CoffeeTable", V(-35.4, G + 2.6, -10))

	-- grandfather clock with a swinging pendulum
	box(living, "ClockCase", -10.2, G, -28.8, -8.5, G + 9.5, -26.8, WOOD_DARK, M.Wood)
	box(living, "ClockHood", -10.4, G + 9.5, -29, -8.5, G + 10.3, -26.6, WOOD_DARK, M.Wood)
	box(living, "ClockGlass", -10.25, G + 2, -28.4, -10.2, G + 7, -27.2, Color3.fromRGB(40, 36, 30), M.Glass, { Transparency = 0.4, CanCollide = false })
	local clockFace = B.cylinder(living, "ClockFace", V(-10.25, G + 8.4, -27.8), 0.1, 1.4, CREAM, M.Plastic, CFrame.new())
	ctx.Audio.loopOn("ClockTick", clockFace, { Caption = false })
	local pendulum = Instance.new("Model")
	pendulum.Name = "Pendulum"
	pendulum.Parent = living
	B.block(pendulum, "Rod", V(-9.8, G + 5.2, -27.8), V(0.08, 3.2, 0.08), BRASS, M.Metal, 0, DECOR)
	B.cylinder(pendulum, "Bob", V(-9.8, G + 3.4, -27.8), 0.1, 0.8, BRASS, M.Metal, CFrame.new())
	pendulum:SetAttribute("Pivot", V(-9.8, G + 6.8, -27.8))
	pendulum:SetAttribute("Axis", "X")
	pendulum:SetAttribute("Amplitude", 12)
	pendulum:SetAttribute("Period", 2)
	CollectionService:AddTag(pendulum, "Swing")

	ceilingFan(living, V(-24, G + 13, -11))

	-- fireplace: stone surround, mantel with candles and photos, a screen
	local stone = Color3.fromRGB(150, 140, 128)
	box(living, "Hearth", -30.2, G, -30, -19.8, G + 0.5, -26.4, stone, M.Concrete)
	box(living, "Surround", -30, G, -30.3, -27.6, G + 8, -28.2, stone, Enum.Material.Cobblestone)
	box(living, "Surround", -22.4, G, -30.3, -20, G + 8, -28.2, stone, Enum.Material.Cobblestone)
	box(living, "Surround", -27.6, G + 6, -30.3, -22.4, G + 8, -28.2, stone, Enum.Material.Cobblestone)
	box(living, "Firebox", -27.6, G + 0.5, -30.3, -22.4, G + 6, -29.8, Color3.fromRGB(20, 18, 18), M.Brick)
	box(living, "Mantel", -30.6, G + 8, -30.3, -19.4, G + 8.6, -27.6, WOOD_DARK, M.Wood)
	box(living, "Chimneybreast", -29.4, G + 8.6, -30.3, -20.6, G + 13, -29.3, Color3.fromRGB(170, 160, 146), Enum.Material.Cobblestone)
	for _, x in { -29.6, -20.4 } do
		B.cylinder(living, "MantelCandle", V(x, G + 9.3, -29.2), 1.4, 0.4, CREAM, M.Plastic, CFrame.Angles(0, 0, math.rad(90)))
		B.part(living, { Name = "Flame", Shape = Enum.PartType.Ball, Size = V(0.2, 0.3, 0.2), CFrame = CFrame.new(x, G + 10.15, -29.2), Color = Color3.fromRGB(255, 190, 90), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false })
	end
	for i, x in { -27.5, -25.6, -23.6 } do
		box(living, "PhotoFrame", x - 0.6, G + 8.6, -29.6, x + 0.6, G + 10 - i * 0.15, -29.4, WOOD_DARK, M.Wood, DECOR)
	end
	-- sooty firebox sides and an iron grate on a bed of ash
	box(living, "FireboxSide", -27.6, G + 0.5, -29.8, -27.4, G + 6, -28.2, Color3.fromRGB(28, 24, 22), M.Brick, DECOR)
	box(living, "FireboxSide", -22.6, G + 0.5, -29.8, -22.4, G + 6, -28.2, Color3.fromRGB(28, 24, 22), M.Brick, DECOR)
	box(living, "Ash", -27.3, G + 0.5, -29.8, -22.7, G + 0.6, -28.3, Color3.fromRGB(70, 66, 62), M.Concrete, DECOR)
	local IRON = Color3.fromRGB(30, 28, 28)
	for _, z in { -29.45, -28.6 } do
		box(living, "GrateBar", -26.8, G + 0.95, z - 0.08, -23.2, G + 1.1, z + 0.08, IRON, M.Metal, DECOR)
	end
	for k = 0, 4 do
		local x = -26.6 + k * 0.8
		box(living, "GrateRib", x - 0.07, G + 0.95, -29.55, x + 0.07, G + 1.35, -28.5, IRON, M.Metal, DECOR)
	end
	for _, x in { -26.7, -23.3 } do
		for _, z in { -29.45, -28.6 } do
			box(living, "GrateLeg", x - 0.1, G + 0.5, z - 0.1, x + 0.1, G + 0.95, z + 0.1, IRON, M.Metal, DECOR)
		end
		box(living, "Firedog", x - 0.12, G + 0.95, -28.55, x + 0.12, G + 1.9, -28.35, IRON, M.Metal, DECOR)
	end
	box(living, "FireScreen", -27.4, G + 0.5, -27.95, -22.6, G + 4, -27.85, C.Black, M.Metal, { Transparency = 0.35, CanCollide = false })
	-- fire tools, the poker you can take
	box(living, "ToolStand", -19.6, G, -29.6, -19.2, G + 4, -29.2, C.Black, M.Metal, DECOR)
	local poker = item(living, "FirePoker", V(-19.2, G + 2.2, -28.9), V(0.25, 4, 0.25), C.Black, "Poker", "Fire poker")
	poker.CFrame *= CFrame.Angles(0, 0, math.rad(10))

	local fireSpot = B.block(living, "FireSpot", V(-25, G + 2, -29), V(3.2, 1, 1.2), C.Black, M.Plastic, 0, { Transparency = 1, CanCollide = false })
	target("Fireplace", fireSpot.Position + V(0, 1, 1))
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
	fireLight.Range = 26
	fireLight.Brightness = 1.6
	fireLight.Shadows = true
	fireLight.Enabled = false
	fireLight.Parent = fireSpot
	local fire = { Lit = false, Logs = false }
	refs.Fire = fire
	local firePrompt
	firePrompt = ctx.Interaction.prompt(fireSpot, { Action = "Put in firewood", Object = "Fireplace", Hold = 1, Distance = 8 }, function(player)
		if fire.Lit then
			return
		end
		if not fire.Logs then
			if not ctx.Inventory.take(player, "Firewood") then
				ctx.Director.think(player, "No wood in here. There's a pile of firewood in the garage.")
				return
			end
			fire.Logs = true
			ctx.Audio.playAt("LogDrop", fireSpot.Position, { Caption = false })
			-- a proper stack: two logs on the grate, one across them, two crossed on top, kindling
			local BARK = { Color3.fromRGB(78, 56, 38), Color3.fromRGB(96, 70, 46), Color3.fromRGB(66, 48, 34) }
			local function log(x, y, z, len, dia, yaw, k)
				local l = B.cylinder(living, "Log", V(x, y, z), len, dia, BARK[k % 3 + 1], M.Wood, CFrame.Angles(0, math.rad(yaw), 0))
				l.CanCollide = false
				l.CanQuery = false
				for _, e in { -1, 1 } do
					B.cylinder(living, "LogEnd", V(x, y, z) + CFrame.Angles(0, math.rad(yaw), 0):VectorToWorldSpace(V(e * (len / 2 + 0.01), 0, 0)), 0.04, dia - 0.12, Color3.fromRGB(196, 160, 112), M.Wood, CFrame.Angles(0, math.rad(yaw), 0)).CanCollide = false
				end
			end
			log(-25.1, G + 1.45, -29.35, 3.4, 0.62, 4, 1)
			log(-24.9, G + 1.45, -28.75, 3.2, 0.58, -3, 2)
			log(-25, G + 1.95, -29.05, 3.0, 0.55, 2, 3)
			log(-25.7, G + 2.4, -29.0, 1.9, 0.45, 38, 4)
			log(-24.3, G + 2.4, -29.0, 1.9, 0.45, -38, 5)
			for k = 1, 6 do
				local stick = B.block(living, "Kindling", V(-25.6 + k * 0.2, G + 2.2 + (k % 2) * 0.1, -29.05), V(1.3, 0.1, 0.1), Color3.fromRGB(150, 118, 80), M.Wood, 20 + k * 27, DECOR)
				stick.CFrame *= CFrame.Angles(0, 0, math.rad(k % 2 == 0 and 15 or -12))
			end
			firePrompt.ActionText = "Light the fire"
			firePrompt.HoldDuration = 2
			return
		end
		if not ctx.Inventory.take(player, "Matches") then
			ctx.Director.think(player, "I need matches. There's a box in the kitchen drawer by the stove.")
			return
		end
		fire.Lit = true
		firePrompt.Enabled = false
		ctx.Audio.playAt("Matches", fireSpot.Position, { Caption = false })
		fireEmitter.Enabled = true
		flames.Enabled = true
		fireLight.Enabled = true
		for k = 0, 5 do
			B.block(living, "Ember", V(-26.4 + k * 0.55, G + 0.95, -29.05 + (k % 2) * 0.3), V(0.5, 0.12, 0.35), Color3.fromRGB(255, 110, 30), Enum.Material.Neon, k * 31, DECOR)
		end
		ctx.Audio.loopOn("FireCrackle", fireSpot, { Caption = false })
		ctx.Power.setStaticLit("Living", true)
		task.spawn(function()
			while fireSpot.Parent do
				fireLight.Brightness = 1.3 + math.random() * 0.6
				task.wait(0.12 + math.random() * 0.15)
			end
		end)
	end)

	-- the remote is lost in the couch
	local remoteFound = false
	local couchSeat = B.block(living, "CouchSearch", V(-30, G + 2.2, -10), V(2.6, 0.6, 8), C.Black, M.Plastic, 0, { Transparency = 1, CanCollide = false })
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

	-- TV on a media console against the west wall
	box(living, "MediaConsole", -40, G, -14.5, -37.6, G + 2.4, -5.5, WOOD_DARK, M.Wood)
	for _, z in { -12.2, -7.8 } do
		box(living, "ConsoleDoor", -37.66, G + 0.4, z - 2, -37.56, G + 2.1, z + 2, WOOD_MID, M.Wood, DECOR)
	end
	box(living, "Speaker", -39.6, G + 2.4, -14.2, -38.4, G + 4.2, -13.2, C.Black, M.Plastic, DECOR)
	box(living, "Speaker", -39.6, G + 2.4, -6.8, -38.4, G + 4.2, -5.8, C.Black, M.Plastic, DECOR)
	local _, screen = tv(living, V(-39.3, G + 3, -10), V(1, 0, 0), 6.2, 3.8)
	target("TV", screen.Position)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right
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
	tvGlow.Face = Enum.NormalId.Right
	tvGlow.Range = 18
	tvGlow.Brightness = 0.9
	tvGlow.Angle = 120
	tvGlow.Color = Color3.fromRGB(160, 190, 255)
	tvGlow.Enabled = false
	tvGlow.Parent = screen
	CollectionService:AddTag(tvGlow, "Flicker")

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
	local tableSpot = B.block(living, "TableSpot", V(-35.4, G + 2.5, -10), V(3, 0.4, 4.4), C.Black, M.Plastic, 0, { Transparency = 1, CanCollide = false })
	local servePrompt
	servePrompt = ctx.Interaction.prompt(tableSpot, { Action = "Put down popcorn", Object = "Coffee table", Distance = 7 }, function(player)
		if not ctx.Inventory.take(player, "PopcornBowl") then
			ctx.Audio.caption("The coffee table. Something to eat would go nicely here.", nil, nil, { player })
			return
		end
		servePrompt.Enabled = false
		B.cylinder(living, "PopcornBowl", V(-35.4, G + 2.6, -10.3), 0.6, 1.8, Color3.fromRGB(180, 40, 40), M.Plastic, CFrame.Angles(0, 0, math.rad(90)))
		B.part(living, { Name = "Popcorn", Shape = Enum.PartType.Ball, Size = V(1.7, 0.7, 1.7), CFrame = CFrame.new(-35.4, G + 2.95, -10.3), Color = Color3.fromRGB(250, 238, 200), Material = M.Fabric, CanCollide = false })
		ctx.Objectives.complete("Popcorn")
	end)

	---------------------------------------------------------------------------
	-- KITCHEN
	---------------------------------------------------------------------------
	local kitchen = folder("Kitchen")
	local CAB = Color3.fromRGB(236, 232, 222)
	-- west run: cabinets, sink under the window, dishwasher, range
	cabinets(kitchen, -40, 4, -37.3, 16, G, V(1, 0, 0), CAB, COUNTER)
	box(kitchen, "Dishwasher", -40, G + 0.35, 16, -37.25, G + 3.5, 18.2, C.Steel, M.Metal)
	box(kitchen, "DishwasherHandle", -37.2, G + 3, 16.3, -37.1, G + 3.15, 17.9, C.Steel, M.Metal, DECOR)
	box(kitchen, "Countertop", -40, G + 3.5, 16, -37.05, G + 3.8, 18.2, COUNTER, M.Marble)
	cabinets(kitchen, -40, 18.2, -37.3, 21, G, V(1, 0, 0), CAB, COUNTER)
	cabinets(kitchen, -40, 25, -37.3, 28, G, V(1, 0, 0), CAB, COUNTER)
	-- range + hood
	box(kitchen, "Range", -40, G, 21, -37.2, G + 3.7, 25, C.Steel, M.Metal)
	box(kitchen, "OvenDoor", -37.2, G + 0.6, 21.3, -37.1, G + 2.7, 24.7, Color3.fromRGB(30, 30, 32), M.Glass)
	box(kitchen, "OvenHandle", -37.1, G + 2.8, 21.6, -36.95, G + 2.95, 24.4, C.Steel, M.Metal, DECOR)
	for _, z in { 21.8, 23, 24.2 } do
		B.cylinder(kitchen, "Knob", V(-37.1, G + 3.25, z), 0.15, 0.3, C.Black, M.Plastic, CFrame.new())
	end
	for _, c in { { 22, -39.2 }, { 24, -39.2 }, { 22, -38 }, { 24, -38 } } do
		B.cylinder(kitchen, "Burner", V(c[2], G + 3.72, c[1]), 0.05, 1, C.Black, M.Metal, CFrame.Angles(0, 0, math.rad(90)))
	end
	box(kitchen, "Hood", -40, G + 9, 20.8, -37.6, G + 10.2, 25.2, C.Steel, M.Metal)
	box(kitchen, "HoodFlue", -40, G + 10.2, 21.9, -38.8, G + 13, 24.1, C.Steel, M.Metal)
	-- sink + faucet + the warm mug
	box(kitchen, "Sink", -39.6, G + 3.4, 12.5, -37.6, G + 3.85, 15.5, C.Steel, M.Metal, DECOR)
	B.block(kitchen, "Faucet", V(-39.4, G + 4.6, 14), V(0.25, 1.6, 0.25), C.Steel, M.Metal, 0, DECOR)
	B.block(kitchen, "Spout", V(-39, G + 5.3, 14), V(0.9, 0.2, 0.2), C.Steel, M.Metal, 0, DECOR)
	local mug = B.cylinder(kitchen, "Mug", V(-38.4, G + 3.75, 13.6), 0.6, 0.5, Color3.fromRGB(200, 190, 170), M.Plastic, CFrame.Angles(0, 0, math.rad(90)))
	mug.CanCollide = false
	ctx.Interaction.document(mug, "WarmMug", { Action = "Look", Object = "Mug in the sink", Distance = 6 }, function()
		ctx.Director.logTruth("WarmMug")
	end)
	-- subway tile backsplash
	local TILE = M.Tile
	box(kitchen, "Backsplash", -39.5, G + 3.8, 4, -39.4, G + 8, 11, Color3.fromRGB(240, 240, 236), TILE, DECOR)
	box(kitchen, "Backsplash", -39.5, G + 3.8, 17, -39.4, G + 8, 28, Color3.fromRGB(240, 240, 236), TILE, DECOR)
	box(kitchen, "Backsplash", -39.5, G + 3.8, 11, -39.4, G + 5.4, 17, Color3.fromRGB(240, 240, 236), TILE, DECOR)
	-- upper cabinets; the left one is the cupboard with the popcorn
	upperCabinets(kitchen, -40, 4, -38.2, 10.8, G + 8, G + 12.4, V(1, 0, 0), CAB)
	upperCabinets(kitchen, -40, 17.2, -38.2, 20.6, G + 8, G + 12.4, V(1, 0, 0), CAB)
	upperCabinets(kitchen, -40, 25.4, -38.2, 28, G + 8, G + 12.4, V(1, 0, 0), CAB)
	local cupboard = box(kitchen, "Cupboard", -38.2, G + 8.2, 4.2, -38.1, G + 12.2, 7.2, CAB, M.Wood, { Transparency = 1, CanCollide = false })
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
	-- matches in the drawer by the stove
	local matchDrawer = box(kitchen, "MatchDrawer", -37.28, G + 2.75, 18.4, -37.1, G + 3.35, 20.8, CAB:Lerp(Color3.new(1, 1, 1), 0.1), M.Wood)
	target("Matches", matchDrawer.Position)
	ctx.Interaction.pickup(matchDrawer, "Matches", { Action = "Search", Object = "Drawer (matches)", Keep = true })

	-- island with stools, pendants above, fruit bowl
	cabinets(kitchen, -28, 12, -22, 18, G, V(0, 0, -1), Color3.fromRGB(64, 84, 96), COUNTER)
	B.cylinder(kitchen, "FruitBowl", V(-25, G + 4, 15), 0.4, 1.8, CREAM, M.Plastic, CFrame.Angles(0, 0, math.rad(90)))
	for i, c in { Color3.fromRGB(200, 40, 40), Color3.fromRGB(240, 180, 40), Color3.fromRGB(120, 180, 60) } do
		B.part(kitchen, { Name = "Fruit", Shape = Enum.PartType.Ball, Size = V(0.55, 0.55, 0.55), CFrame = CFrame.new(-25.5 + i * 0.3, G + 4.4, 15 + (i % 2) * 0.3), Color = c, CanCollide = false })
	end
	for _, x in { -27, -25, -23 } do
		B.cylinder(kitchen, "StoolSeat", V(x, G + 3.2, 19.3), 0.3, 1.4, WOOD_DARK, M.Wood, CFrame.Angles(0, 0, math.rad(90)))
		B.block(kitchen, "StoolLeg", V(x, G + 1.5, 19.3), V(0.25, 3.1, 0.25), C.Black, M.Metal)
	end
	pendant(kitchen, "Kitchen", V(-26.5, G + 13, 15), 2.6)
	pendant(kitchen, "Kitchen", V(-23.5, G + 13, 15), 2.6)

	-- dining table
	diningTable(kitchen, -18, 13, -12, 22, G, WOOD_MID)
	for _, z in { 15.5, 19.5 } do
		chair(kitchen, -19.4, z, G, V(1, 0, 0))
		chair(kitchen, -10.6, z, G, V(-1, 0, 0))
	end
	B.cylinder(kitchen, "Vase", V(-15, G + 4.6, 17.5), 1.5, 0.7, Color3.fromRGB(70, 110, 140), M.Glass, CFrame.Angles(0, 0, math.rad(90)))
	pendant(kitchen, "Kitchen", V(-15, G + 13, 17.5), 3.2)

	-- phone counter against the hall wall: landline, microwave, drawers
	cabinets(kitchen, -11, 3.5, -8.3, 10.5, G, V(-1, 0, 0), CAB, COUNTER)
	local phone = box(kitchen, "Landline", -9.8, G + 3.8, 5, -8.8, G + 4.3, 6.4, Color3.fromRGB(215, 210, 195), M.Plastic)
	target("Phone", phone.Position)
	ctx.Escape.setupLandline(phone)
	local microwave = box(kitchen, "Microwave", -10.9, G + 3.8, 7.3, -8.5, G + 5.4, 10.2, Color3.fromRGB(26, 26, 28), M.Metal)
	box(kitchen, "MicrowaveWindow", -10.95, G + 4.1, 7.6, -10.9, G + 5.1, 9.3, Color3.fromRGB(20, 30, 30), M.Glass, DECOR)
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
	local drawer1 = box(kitchen, "JunkDrawer", -11.25, G + 2.6, 3.8, -11.1, G + 3.3, 6.4, CAB:Lerp(Color3.new(1, 1, 1), 0.1), M.Wood)
	target("TapeKitchen", drawer1.Position)
	ctx.Interaction.pickup(drawer1, "ElectricalTape", { Action = "Search", Object = "Junk drawer", Keep = true })
	local drawer2 = box(kitchen, "Drawer", -11.25, G + 1.4, 3.8, -11.1, G + 2.4, 6.4, CAB:Lerp(Color3.new(1, 1, 1), 0.1), M.Wood)
	ctx.Interaction.pickup(drawer2, "Batteries", { Action = "Search", Object = "Drawer (batteries)", Keep = true })

	-- fridge with the note and the pizza menu under magnets
	local fridge = box(kitchen, "Fridge", -29.6, G, 26.4, -24.6, G + 10.5, 29.6, Color3.fromRGB(220, 220, 218), M.Metal)
	box(kitchen, "FridgeSeam", -29.6, G + 6.9, 26.35, -24.6, G + 7.05, 26.4, Color3.fromRGB(150, 150, 150), M.Metal, DECOR)
	box(kitchen, "FridgeHandle", -25.4, G + 3, 26.1, -25.2, G + 6.4, 26.35, C.Steel, M.Metal, DECOR)
	box(kitchen, "FreezerHandle", -25.4, G + 7.5, 26.1, -25.2, G + 9.5, 26.35, C.Steel, M.Metal, DECOR)
	ctx.Audio.loopOn("FridgeHum", fridge, { Caption = false })
	local note = paper(kitchen, "FridgeNote", V(-28.0, G + 5.6, 26.37), V(1.4, 1.8, 0.05))
	ctx.Interaction.document(note, "FridgeNote", { Object = "Note on the fridge", Distance = 6 })
	local menu = paper(kitchen, "PizzaMenu", V(-26.7, G + 8.4, 26.37), V(1.3, 1.9, 0.05))
	menu.Color = Color3.fromRGB(200, 60, 45)
	for _, p in { V(-28.0, G + 6.4, 26.33), V(-26.7, G + 9.3, 26.33) } do
		B.block(kitchen, "Magnet", p, V(0.25, 0.25, 0.08), Color3.fromRGB(60, 120, 200), M.Plastic, 0, DECOR)
	end
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
	B.cylinder(kitchen, "TrashCan", V(-15.6, G + 1.6, 28.4), 3.2, 2.2, Color3.fromRGB(150, 150, 150), M.Metal, CFrame.Angles(0, 0, math.rad(90)))
	local trashLid = B.cylinder(kitchen, "TrashLid", V(-15.6, G + 3.25, 28.4), 0.15, 2.3, C.Steel, M.Metal, CFrame.Angles(0, 0, math.rad(90)))
	local trashDoc = ctx.Interaction.document(trashLid, "TrashCan", { Action = "Look", Object = "Kitchen trash", Distance = 6 })
	trashDoc.Enabled = false
	function kitchenRefs.takeLasagna()
		kitchenRefs.LasagnaGone = true
		trashDoc.Enabled = true
	end

	-- key hook by the back door
	local hookBoard = box(kitchen, "KeyHooks", -26.5, G + 5.5, 29.25, -24, G + 6.5, 29.5, WOOD_DARK, M.Wood)
	local keys = box(kitchen, "CarKeysOnHook", -25.6, G + 4.9, 29.05, -25.1, G + 5.6, 29.2, Color3.fromRGB(190, 190, 195), M.Metal, { CanCollide = false })
	ctx.Escape.setupKeyHook(keys, hookBoard)
	rug(kitchen, -22.5, 25.5, -17.5, 29.5, G, Color3.fromRGB(80, 70, 60))
	plant(kitchen, V(-33.5, G, 28.3), 1.3)

	---------------------------------------------------------------------------
	-- HALLWAY / FOYER
	---------------------------------------------------------------------------
	local hall = folder("Hallway")
	rug(hall, -0.5, -28.5, 4.5, -8, G, Color3.fromRGB(110, 50, 48), Color3.fromRGB(200, 170, 120))
	box(hall, "Bench", 8.8, G, -29.2, 11.6, G + 2.2, -24, WOOD_MID, M.Wood)
	box(hall, "BenchCushion", 8.9, G + 2.2, -29, 11.5, G + 2.6, -24.2, Color3.fromRGB(120, 60, 50), M.Fabric, DECOR)
	for i = 0, 2 do
		box(hall, "Shoes", 9.2 + i * 0.8, G, -28.6, 9.8 + i * 0.8, G + 0.5, -27.6, Color3.fromRGB(40 + i * 30, 30, 30), M.Fabric, DECOR)
	end
	box(hall, "CoatRack", 11.1, G, -13, 11.6, G + 8.5, -12.5, WOOD_DARK, M.Wood)
	for i, col in { Color3.fromRGB(60, 70, 90), Color3.fromRGB(140, 110, 70) } do
		box(hall, "Coat", 10.4, G + 4.5, -13.6 + i * 0.4, 11.1, G + 8, -12.8 + i * 0.4, col, M.Fabric, DECOR)
	end
	box(hall, "ConsoleTable", -7.6, G, -28.8, -6, G + 3.4, -23, WOOD_DARK, M.Wood)
	box(hall, "Mirror", -7.7, G + 5, -28.3, -7.6, G + 9, -23.5, Color3.fromRGB(190, 200, 205), M.Glass, { Reflectance = 0.5, CanCollide = false })
	box(hall, "MirrorFrame", -7.72, G + 4.8, -28.5, -7.64, G + 9.2, -23.3, BRASS, M.Metal, DECOR)
	B.cylinder(hall, "KeyBowl", V(-6.8, G + 3.6, -26), 0.3, 1.2, Color3.fromRGB(70, 110, 140), M.Glass, CFrame.Angles(0, 0, math.rad(90)))
	B.cylinder(hall, "UmbrellaStand", V(7.5, G + 1.3, -28.8), 2.6, 1, C.Black, M.Metal, CFrame.Angles(0, 0, math.rad(90)))
	plant(hall, V(-6.9, G, -12.6), 1.3)

	---------------------------------------------------------------------------
	-- OFFICE (key-locked)
	---------------------------------------------------------------------------
	local office = folder("Office")
	rug(office, 19, -27, 36, -13, G, Color3.fromRGB(60, 70, 90), Color3.fromRGB(170, 150, 110))
	box(office, "DeskTop", 29, G + 3.4, -25, 35.5, G + 3.8, -18, WOOD_DARK, M.Wood)
	box(office, "DeskPedestal", 29, G, -25, 31.2, G + 3.4, -18, WOOD_DARK, M.Wood)
	box(office, "DeskPedestal", 33.3, G, -25, 35.5, G + 3.4, -18, WOOD_DARK, M.Wood)
	for r = 0, 2 do
		box(office, "DeskDrawerFace", 28.9, G + 0.3 + r * 1, -24.6, 29, G + 1.1 + r * 1, -18.4, WOOD_MID, M.Wood, DECOR)
	end
	tv(office, V(30.2, G + 3.8, -21.5), V(1, 0, 0), 3.2, 2.2)
	box(office, "Keyboard", 32.2, G + 3.8, -22.6, 32.8, G + 3.9, -20.4, Color3.fromRGB(40, 40, 42), M.Plastic, DECOR)
	chair(office, 36.6, -21.5, G, V(-1, 0, 0), Color3.fromRGB(40, 36, 34))
	local invoice = paper(office, "Invoice", V(33.8, G + 3.83, -19.4), V(1.6, 0.04, 2))
	ctx.Interaction.document(invoice, "Invoice", { Object = "Invoice on the desk", Distance = 6 })
	local deskDrawer = box(office, "DeskDrawer", 28.85, G + 2.3, -22.6, 28.95, G + 3.1, -20.4, WOOD_MID, M.Wood)
	target("OfficeKeys", deskDrawer.Position)
	ctx.Interaction.pickup(deskDrawer, "CarKeys", { Action = "Search", Object = "Desk drawer (spare keys)", Keep = true })
	shelf(office, 38.6, -29.5, 39.8, -12, G, 10, 5)
	box(office, "FilingCabinet", 13, G, -29.5, 16, G + 5, -27, C.Steel, M.Metal)
	for r = 0, 2 do
		box(office, "FileDrawer", 13.2, G + 0.4 + r * 1.5, -27, 15.8, G + 1.6 + r * 1.5, -26.9, Color3.fromRGB(140, 142, 145), M.Metal, DECOR)
	end
	sofa(office, 21, -27.4, G, 4, V(0, 0, 1), Color3.fromRGB(90, 50, 40))
	lamp(office, "Office", V(35, G + 3.8, -24.3), "table")
	plant(office, V(37.8, G, -11.2), 1.4)

	---------------------------------------------------------------------------
	-- DOWNSTAIRS BATHROOM
	---------------------------------------------------------------------------
	local bath = folder("Bathroom")
	-- vanity on the north wall, toilet on the east wall, towel on the south wall
	cabinets(bath, 17.2, 2.3, 21.7, 3.7, G, V(0, 0, -1), Color3.fromRGB(70, 90, 110), Color3.fromRGB(235, 235, 232), 3)
	B.cylinder(bath, "Basin", V(19.45, G + 3.35, 3), 0.3, 1.6, C.White, M.Marble, CFrame.Angles(0, 0, math.rad(90)))
	B.block(bath, "Faucet", V(19.45, G + 3.9, 3.5), V(0.2, 0.8, 0.2), C.Steel, M.Metal, 0, DECOR)
	box(bath, "Mirror", 17.7, G + 5, 3.62, 21.2, G + 8.5, 3.7, Color3.fromRGB(190, 200, 205), M.Glass, { Reflectance = 0.45, CanCollide = false })
	box(bath, "MirrorFrame", 17.5, G + 4.8, 3.66, 21.4, G + 8.7, 3.72, WOOD_DARK, M.Wood, DECOR)
	item(bath, "Scissors", V(18, G + 3.35, 2.9), V(0.8, 0.1, 0.35), Color3.fromRGB(210, 60, 60), "Scissors", "Scissors")
	toilet(bath, 20.2, -1.8, G, V(-1, 0, 0))
	box(bath, "TowelBar", 16, G + 5.5, -3.7, 19.4, G + 5.7, -3.6, C.Steel, M.Metal, DECOR)
	box(bath, "Towel", 16.4, G + 3.6, -3.72, 19, G + 5.6, -3.57, Color3.fromRGB(120, 160, 190), M.Fabric, DECOR)
	rug(bath, 16, -1.5, 19.5, 1.5, G, Color3.fromRGB(110, 140, 160))

	---------------------------------------------------------------------------
	-- MUDROOM
	---------------------------------------------------------------------------
	local mud = folder("Mudroom")
	box(mud, "Bench", 24, G, -9.6, 32, G + 2, -7.6, WOOD_LIGHT, M.Wood)
	box(mud, "BenchCushion", 24.1, G + 2, -9.5, 31.9, G + 2.4, -7.7, Color3.fromRGB(70, 90, 110), M.Fabric, DECOR)
	for i = 0, 3 do
		box(mud, "Cubby", 24.3 + i * 1.95, G + 0.3, -9.5, 25.9 + i * 1.95, G + 1.7, -7.75, WOOD_DARK, M.Wood, DECOR)
	end
	box(mud, "HookRail", 24, G + 7.5, -9.8, 32, G + 8, -9.6, WOOD_LIGHT, M.Wood, DECOR)
	for i = 0, 3 do
		box(mud, "Coat", 24.5 + i * 2, G + 3.8, -9.6, 25.9 + i * 2, G + 7.6, -9, Color3.fromHSV(i * 0.22, 0.35, 0.4), M.Fabric, DECOR)
	end
	box(mud, "Shelf", 34.5, G + 5, -9.7, 39.7, G + 5.3, -7.8, WOOD_LIGHT, M.Wood)
	for i = 0, 1 do
		box(mud, "Basket", 35 + i * 2.6, G + 5.3, -9.5, 36.6 + i * 2.6, G + 6.3, -8, Color3.fromRGB(170, 130, 80), M.Fabric, DECOR)
	end
	local fl1 = B.cylinder(mud, "Flashlight", V(38.9, G + 5.55, -8.4), 1.2, 0.45, Color3.fromRGB(200, 170, 40), M.Plastic, CFrame.new())
	fl1.CanCollide = false
	target("FlashlightMud", fl1.Position)
	ctx.Interaction.pickup(fl1, "Flashlight", { Object = "Flashlight" })
	box(mud, "KeyBoard", 34.5, G + 7, -9.75, 36.5, G + 8, -9.6, WOOD_DARK, M.Wood)
	local bkey = box(mud, "BasementKey", 35.2, G + 6.3, -9.55, 35.6, G + 7, -9.45, BRASS, M.Metal, { CanCollide = false })
	ctx.Interaction.pickup(bkey, "BasementKey", { Object = "Key tagged 'BSMT'" })
	box(mud, "Boots", 26, G, -7.4, 28, G + 1.2, -6.2, C.Black, M.Fabric, DECOR)
	rug(mud, 27, -6, 35, 2, G, Color3.fromRGB(70, 60, 50))

	---------------------------------------------------------------------------
	-- DEN
	---------------------------------------------------------------------------
	local den = folder("Den")
	rug(den, 16, 8, 32, 21, G, Color3.fromRGB(60, 72, 64), Color3.fromRGB(170, 150, 110))
	sofa(den, 21.5, 17.5, G, 10, V(0, 0, -1), Color3.fromRGB(110, 86, 64), Color3.fromRGB(60, 90, 70))
	coffeeTable(den, 18.5, 10.5, 24.5, 13, G, 2, WOOD_MID)
	box(den, "TVCabinet", 16.5, G, 4.4, 26.5, G + 2.4, 6.4, WOOD_DARK, M.Wood)
	tv(den, V(21.5, G + 2.4, 5), V(0, 0, 1), 7, 4.2)
	box(den, "Console", 23.5, G + 2.4, 5.4, 25.5, G + 2.9, 6.3, C.Black, M.Plastic, DECOR)
	for _, x in { 18.8, 20.2 } do
		box(den, "Controller", x, G + 2.4, 5.6, x + 0.9, G + 2.6, 6.2, Color3.fromRGB(30, 30, 34), M.Plastic, DECOR)
	end
	box(den, "EndTable", 14, G, 14.5, 16.5, G + 2.8, 17, WOOD_MID, M.Wood)
	local denDrawer = box(den, "EndTableDrawer", 14.2, G + 1.6, 17, 16.3, G + 2.5, 17.15, WOOD_DARK, M.Wood)
	target("FlashlightDen", denDrawer.Position)
	ctx.Interaction.pickup(denDrawer, "Flashlight", { Action = "Search", Object = "Drawer (flashlight)", Keep = true })
	lamp(den, "Den", V(15.2, G + 2.8, 15.2), "table")
	B.part(den, { Name = "BeanBag", Shape = Enum.PartType.Ball, Size = V(3.4, 2.6, 3.4), CFrame = CFrame.new(33, G + 1.3, 12), Color = Color3.fromRGB(150, 50, 50), Material = M.Fabric })
	shelf(den, 38.8, 18, 39.8, 25.5, G, 8, 4)
	wardrobe(den, "Den closet", 32, 26.6, 37, 29.8, G, V(0, 0, -1), "Den", Color3.fromRGB(236, 232, 222))
	ceilingFan(den, V(24, G + 13, 17))
	plant(den, V(38.6, G, 5.6), 1.5)

	---------------------------------------------------------------------------
	-- GARAGE
	---------------------------------------------------------------------------
	local garage = folder("Garage")
	local car = Instance.new("Model")
	car.Name = "Honda"
	car.Parent = garage
	local body = box(car, "Body", 46.5, G + 1, -25, 53.5, G + 4, -10, Color3.fromRGB(95, 30, 30), M.Metal)
	box(car, "Cabin", 47, G + 4, -21, 53, G + 7, -14, Color3.fromRGB(40, 45, 55), M.Glass, { Transparency = 0.3 })
	box(car, "Bumper", 46.4, G + 1, -25.3, 53.6, G + 2, -25, Color3.fromRGB(40, 40, 42), M.Plastic)
	box(car, "Bumper", 46.4, G + 1, -10, 53.6, G + 2, -9.7, Color3.fromRGB(40, 40, 42), M.Plastic)
	for _, w in { { 46.2, -22 }, { 53.8, -22 }, { 46.2, -13 }, { 53.8, -13 } } do
		B.cylinder(car, "Wheel", V(w[1], G + 1.2, w[2]), 1, 2.4, C.Black, M.Plastic, CFrame.new())
	end
	for _, x in { 47.5, 52.5 } do
		box(car, "Headlight", x - 0.8, G + 2.4, -25.1, x + 0.8, G + 3, -25, Color3.fromRGB(220, 220, 200), M.Glass)
		box(car, "Taillight", x - 0.8, G + 2.4, -10, x + 0.8, G + 3, -9.9, Color3.fromRGB(160, 30, 30), M.Glass)
	end
	car.PrimaryPart = body
	local driverDoor = box(car, "DriverDoor", 53.5, G + 1.5, -19, 53.7, G + 5, -15, Color3.fromRGB(90, 28, 28), M.Metal)
	-- parked nose-in: turn it round so it backs out through the garage door (local +Z = out)
	car:PivotTo(car:GetPivot() * CFrame.Angles(0, math.pi, 0))
	target("Car", driverDoor.Position)
	ctx.Escape.setupCar(car, driverDoor, {})

	-- breaker panel on the house wall
	local panel = box(garage, "BreakerPanel", 40.5, G + 4, -14.5, 40.9, G + 8.5, -11, Color3.fromRGB(150, 150, 150), M.Metal)
	target("Breaker", panel.Position)
	local leverOn = CFrame.new(41.05, G + 7.8, -12.75)
	local leverOff = CFrame.new(41.05, G + 7.2, -12.75)
	local lever = B.part(garage, { Name = "MainLever", Size = V(0.3, 0.6, 0.9), CFrame = leverOn, Color = Color3.fromRGB(200, 40, 30), CanCollide = false })
	ctx.Escape.setupBreaker(panel, lever, leverOn, leverOff)
	local opener = box(garage, "OpenerButton", 40.5, G + 4.5, -8.9, 40.8, G + 5.2, -8.2, C.White, M.Plastic)
	target("GarageButton", opener.Position)
	box(garage, "OpenerRail", 52.8, G + 10.5, -29.5, 53.2, G + 10.8, -6, C.Steel, M.Metal, DECOR)
	box(garage, "OpenerMotor", 51.5, G + 9.6, -7, 54.5, G + 11, -4.5, C.Steel, M.Metal)
	local cord = box(garage, "ReleaseCord", 52.9, G + 7.8, -26.2, 53.1, G + 10.5, -26, Color3.fromRGB(200, 40, 30), M.Fabric, { CanCollide = false })
	ctx.Escape.setupGarageDoor(refs.GarageDoor, opener, cord)

	-- workbench: walkies + tape, pegboard tools
	box(garage, "Workbench", 61.5, G + 3, -27, 65.6, G + 3.4, -16, WOOD_LIGHT, M.Wood)
	for _, z in { -26.6, -16.4 } do
		box(garage, "BenchLeg", 61.7, G, z - 0.2, 62.1, G + 3, z + 0.2, WOOD_DARK, M.Wood)
		box(garage, "BenchLeg", 65, G, z - 0.2, 65.4, G + 3, z + 0.2, WOOD_DARK, M.Wood)
	end
	box(garage, "BenchShelf", 61.6, G + 0.8, -26.8, 65.5, G + 1, -16.2, WOOD_DARK, M.Wood, DECOR)
	box(garage, "Pegboard", 65.5, G + 4.5, -27, 65.7, G + 9, -16, Color3.fromRGB(170, 140, 100), M.Wood)
	for i = 0, 5 do
		box(garage, "Tool", 65.3, G + 5.5 + (i % 2) * 1.5, -26 + i * 1.6, 65.5, G + 7 + (i % 2) * 1.5, -25.6 + i * 1.6, Color3.fromHSV(i * 0.15, 0.5, 0.5), M.Metal, DECOR)
	end
	item(garage, "Walkie", V(63, G + 3.9, -24), V(0.6, 1, 0.35), Color3.fromRGB(40, 40, 45), "Walkie", "Walkie-talkie")
	item(garage, "Walkie", V(63, G + 3.9, -22.8), V(0.6, 1, 0.35), Color3.fromRGB(40, 40, 45), "Walkie", "Walkie-talkie")
	B.cylinder(garage, "Tape", V(63.5, G + 3.55, -19.5), 0.3, 0.9, C.Black, M.Plastic, CFrame.new())
	local tape2 = B.block(garage, "TapeRoll", V(63.5, G + 3.6, -19.5), V(0.9, 0.35, 0.9), C.Black, M.Plastic, 0, { Transparency = 1, CanCollide = false })
	target("TapeGarage", tape2.Position)
	ctx.Interaction.pickup(tape2, "ElectricalTape", { Object = "Electrical tape" }, function()
		for _, p in garage:GetChildren() do
			if p.Name == "Tape" then
				p:Destroy()
			end
		end
	end)
	shelf(garage, 40.5, 1, 45, 5.6, G, 8, 3, Color3.fromRGB(110, 110, 112))
	box(garage, "Boxes", 58, G, 1, 65, G + 4, 5.5, Color3.fromRGB(160, 130, 90), M.Cardboard)
	box(garage, "Boxes", 59, G + 4, 2, 63, G + 6.5, 5, Color3.fromRGB(150, 120, 85), M.Cardboard)
	for i = 0, 1 do
		B.cylinder(garage, "TrashBin", V(56.4, G + 2, -0.6 + i * 2.6), 4, 2.2, Color3.fromRGB(40, 70, 50), M.Plastic, CFrame.Angles(0, 0, math.rad(90)))
	end

	-- the woodpile (for the fireplace)
	local pile = Instance.new("Model")
	pile.Name = "Woodpile"
	pile.Parent = garage
	for row = 0, 3 do
		for k = 0, 3 - math.floor(row / 2) do
			B.cylinder(pile, "Log", V(62.5, G + 0.45 + row * 0.8, -12 + k * 0.85 + (row % 2) * 0.4), 3.2, 0.8, Color3.fromRGB(110 + row * 5, 76, 48), M.Wood, CFrame.new())
		end
	end
	local pileSpot = box(garage, "PileSpot", 60.8, G, -12.5, 64.2, G + 3.2, -8.6, C.Black, M.Plastic, { Transparency = 1, CanCollide = false })
	target("Woodpile", pileSpot.Position)
	ctx.Interaction.prompt(pileSpot, { Action = "Take firewood", Object = "Woodpile", Hold = 0.6, Distance = 7 }, function(player)
		if ctx.Inventory.has(player, "Firewood") then
			ctx.Audio.caption("Your arms are full already.", nil, nil, { player })
			return
		end
		if refs.Fire and refs.Fire.Logs then
			ctx.Audio.caption("There's already wood in the fireplace.", nil, nil, { player })
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
	box(ladderModel, "LadderLeg", lx - 1, G, lz - 1.6, lx + 1, G + 12, lz - 1.3, Color3.fromRGB(180, 180, 170), M.Metal)
	box(ladderModel, "LadderLeg", lx - 1, G, lz + 1.3, lx + 1, G + 12, lz + 1.6, Color3.fromRGB(180, 180, 170), M.Metal)
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
	rug(master, -34, -22, -22, -7, U, Color3.fromRGB(150, 140, 120))
	bed(master, "Under the master bed", -40, -19, -31, -10, U, Color3.fromRGB(62, 76, 110), V(1, 0, 0), V(-1, 0, 0), "Master", WOOD_DARK)
	nightstand(master, -39, -7.6, U, V(1, 0, 0), WOOD_DARK)
	nightstand(master, -39, -21.4, U, V(1, 0, 0), WOOD_DARK)
	lamp(master, "Master", V(-39, U + 2.4, -7.6), "table")
	lamp(master, "Master", V(-39, U + 2.4, -21.4), "table")
	wardrobe(master, "Master wardrobe", -27.5, -30, -20.5, -27, U, V(0, 0, 1), "Master", WOOD_DARK)
	dresser(master, -9.3, -25.2, U, V(-1, 0, 0), 6, WOOD_DARK)
	box(master, "DresserMirror", -8.9, U + 4.8, -27.2, -8.8, U + 9, -23.2, Color3.fromRGB(190, 200, 205), M.Glass, { Reflectance = 0.45, CanCollide = false })
	item(master, "Purse", V(-9.3, U + 4.35, -26.8), V(1.4, 1.1, 0.7), Color3.fromRGB(110, 60, 45), "PepperSpray", "Pepper spray (mom's old purse)", ctx.Config.PepperSpray.Uses)
	sofa(master, -35, -27.3, U, 3.8, V(0, 0, 1), Color3.fromRGB(200, 190, 170))
	ceilingFan(master, V(-24, U + 13, -12))
	plant(master, V(-10, U, -3), 1.4)

	local mbath = folder("MasterBath")
	box(mbath, "Tub", -40, U, 8.5, -31, U + 2.2, 12, C.White, M.Marble)
	box(mbath, "TubInner", -39.4, U + 1.4, 9, -31.6, U + 2.25, 11.6, Color3.fromRGB(215, 225, 230), M.Marble, DECOR)
	box(mbath, "TubFaucet", -39.8, U + 2.2, 10, -39.4, U + 3.4, 10.6, C.Steel, M.Metal, DECOR)
	cabinets(mbath, -20, 10.5, -12, 12, U, V(0, 0, -1), WOOD_DARK, Color3.fromRGB(235, 235, 232), 3)
	for _, x in { -18, -14 } do
		B.cylinder(mbath, "Basin", V(x, U + 3.35, 11.2), 0.3, 1.5, C.White, M.Marble, CFrame.Angles(0, 0, math.rad(90)))
	end
	box(mbath, "Mirror", -19.5, U + 5, 11.85, -12.5, U + 8.5, 11.95, Color3.fromRGB(190, 200, 205), M.Glass, { Reflectance = 0.45, CanCollide = false })
	toilet(mbath, -10, 1.9, U, V(0, 0, 1))
	rug(mbath, -24, 5, -18, 9, U, Color3.fromRGB(200, 200, 196))

	---------------------------------------------------------------------------
	-- JAMIE'S ROOM
	---------------------------------------------------------------------------
	local jamie = folder("Jamie")
	rug(jamie, -30, 15, -18, 25, U, Color3.fromRGB(40, 50, 70))
	bed(jamie, "Under Jamie's bed", -40, 12.8, -34, 19, U, Color3.fromRGB(40, 70, 120), V(1, 0, 0), V(-1, 0, 0), "Jamie")
	nightstand(jamie, -39, 21, U, V(1, 0, 0), WOOD_MID)
	wardrobe(jamie, "Jamie's closet", -19.5, 26.8, -13.5, 29.8, U, V(0, 0, -1), "Jamie", Color3.fromRGB(236, 232, 222))
	box(jamie, "Desk", -31, U + 3.1, 26.5, -25.2, U + 3.4, 29.6, WOOD_LIGHT, M.Wood)
	box(jamie, "DeskLeg", -31, U, 26.6, -30.6, U + 3.1, 29.5, WOOD_LIGHT, M.Wood)
	box(jamie, "DeskDrawers", -27.2, U, 26.6, -25.2, U + 3.1, 29.5, WOOD_LIGHT, M.Wood)
	chair(jamie, -28.8, 25, U, V(0, 0, 1), Color3.fromRGB(30, 30, 34))
	lamp(jamie, "Jamie", V(-26.2, U + 3.4, 28.6), "table")
	box(jamie, "Laptop", -30, U + 3.4, 27.4, -27.8, U + 3.5, 29, Color3.fromRGB(70, 70, 75), M.Metal, DECOR)
	box(jamie, "LaptopScreen", -30, U + 3.5, 28.9, -27.8, U + 5, 29, Color3.fromRGB(40, 60, 90), Enum.Material.Neon, DECOR)
	shelf(jamie, -39.8, 23.5, -38.6, 29.5, U, 7, 3)
	B.part(jamie, { Name = "BeanBag", Shape = Enum.PartType.Ball, Size = V(3, 2.3, 3), CFrame = CFrame.new(-22, U + 1.15, 17), Color = Color3.fromRGB(40, 90, 150), Material = M.Fabric })
	local guitar = box(jamie, "Guitar", -10.2, U, 14, -9.8, U + 4.6, 15.6, Color3.fromRGB(140, 70, 30), M.Wood)
	guitar.CFrame *= CFrame.Angles(0, 0, math.rad(-8))
	box(jamie, "Clothes", -24, U, 21, -21.5, U + 0.6, 23, Color3.fromRGB(80, 80, 110), M.Fabric, DECOR)

	---------------------------------------------------------------------------
	-- UPSTAIRS HALL
	---------------------------------------------------------------------------
	local uhall = folder("UpperHall")
	wardrobe(uhall, "Linen wardrobe", 9.2, -8.5, 11.8, -3.5, U, V(-1, 0, 0), "UpperHall", Color3.fromRGB(236, 232, 222))
	rug(uhall, 0.5, -27, 5.5, -9, U, Color3.fromRGB(110, 50, 48), Color3.fromRGB(200, 170, 120))
	box(uhall, "HallTable", 10, U, -27, 11.7, U + 3, -23, WOOD_DARK, M.Wood)
	plant(uhall, V(10.8, U + 3, -25), 0.9)
	target("SignalSpot", V(37, U + 3, 1))

	---------------------------------------------------------------------------
	-- GUEST ROOM
	---------------------------------------------------------------------------
	local guest = folder("Guest")
	rug(guest, 15, -21, 27, -12, U, Color3.fromRGB(150, 120, 90))
	bed(guest, "Under the guest bed", 14, -29.6, 20.5, -22, U, Color3.fromRGB(150, 130, 100), V(0, 0, 1), V(0, 0, -1), "Guest", WOOD_LIGHT)
	nightstand(guest, 21.7, -28.8, U, V(0, 0, 1), WOOD_LIGHT)
	lamp(guest, "Guest", V(22, U + 2.4, -28.8), "table")
	wardrobe(guest, "Guest wardrobe", 32, -9.2, 38, -6.4, U, V(0, 0, -1), "Guest", WOOD_LIGHT)
	box(guest, "Boxes", 36, U, -29.5, 39.6, U + 3, -25, Color3.fromRGB(160, 130, 90), M.Cardboard)
	box(guest, "Boxes", 36.6, U + 3, -29, 39.2, U + 5, -26.5, Color3.fromRGB(150, 120, 85), M.Cardboard)
	box(guest, "SewingTable", 30.2, U + 3, -29.5, 35.2, U + 3.3, -27.2, WOOD_LIGHT, M.Wood)
	box(guest, "SewingLeg", 30.3, U, -29.4, 30.7, U + 3, -27.3, WOOD_LIGHT, M.Wood)
	box(guest, "SewingLeg", 34.7, U, -29.4, 35.1, U + 3, -27.3, WOOD_LIGHT, M.Wood)
	box(guest, "SewingMachine", 31.7, U + 3.3, -29, 33.7, U + 4.6, -28, C.White, M.Metal, DECOR)
	plant(guest, V(38.5, U, -12), 1.4)

	---------------------------------------------------------------------------
	-- UPSTAIRS BATHROOM (shower, signal at the window)
	---------------------------------------------------------------------------
	local hbath = folder("HallBath")
	cabinets(hbath, 14, -5.6, 21, -4, U, V(0, 0, 1), Color3.fromRGB(236, 232, 222), Color3.fromRGB(60, 60, 62), 3)
	B.cylinder(hbath, "Basin", V(17.5, U + 3.35, -4.8), 0.3, 1.6, C.White, M.Marble, CFrame.Angles(0, 0, math.rad(90)))
	box(hbath, "Mirror", 15.5, U + 5, -5.72, 19.5, U + 8.5, -5.62, Color3.fromRGB(190, 200, 205), M.Glass, { Reflectance = 0.45, CanCollide = false })
	toilet(hbath, 24, -4.3, U, V(0, 0, 1))
	box(hbath, "ShowerBase", 33.5, U, 3, 39.7, U + 0.4, 7.7, Color3.fromRGB(230, 230, 228), M.Tile)
	box(hbath, "ShowerWall", 33.4, U, 7.6, 39.7, U + 11, 7.8, Color3.fromRGB(230, 230, 228), M.Tile)
	box(hbath, "ShowerWall", 33.3, U, 2.8, 39.7, U + 11, 3, Color3.fromRGB(230, 230, 228), M.Tile)
	box(hbath, "CurtainRod", 33.3, U + 10, 2.8, 33.45, U + 10.2, 7.8, C.Steel, M.Metal, DECOR)
	local curtain = box(hbath, "ShowerCurtain", 33.2, U + 1, 3, 33.35, U + 10, 7.6, Color3.fromRGB(180, 200, 190), M.Fabric)
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
	local head = box(hbath, "ShowerHead", 39.3, U + 9, 5, 39.7, U + 9.4, 5.6, C.Steel, M.Metal, DECOR)
	drips.Parent = head
	local base = hbath:FindFirstChild("ShowerBase") :: BasePart
	base.Reflectance = 0.35
	ctx.Interaction.document(base, "WetShower", { Action = "Look", Object = "Shower", Distance = 8 }, function()
		ctx.Director.logTruth("WetShower")
	end)
	box(hbath, "TowelBar", 26, U + 5.5, -5.75, 29.5, U + 5.7, -5.65, C.Steel, M.Metal, DECOR)
	box(hbath, "Towel", 26.4, U + 3.6, -5.7, 29.1, U + 5.6, -5.55, Color3.fromRGB(230, 200, 120), M.Fabric, DECOR)
	rug(hbath, 29.5, 3.6, 32.8, 6.8, U, Color3.fromRGB(110, 130, 150))

	---------------------------------------------------------------------------
	-- LILY'S ROOM
	---------------------------------------------------------------------------
	local lily = folder("Lily")
	B.cylinder(lily, "RoundRug", V(24, U + 0.03, 17), 0.06, 11, Color3.fromRGB(240, 190, 210), M.Fabric, CFrame.Angles(0, 0, math.rad(90))).CanCollide = false
	bed(lily, "Under Lily's bed", 32, 23.5, 38.5, 29.6, U, Color3.fromRGB(235, 160, 195), V(0, 0, -1), V(0, 0, 1), "Lily", Color3.fromRGB(240, 236, 230))
	wardrobe(lily, "Lily's closet", 13.2, 8.3, 18.2, 11.2, U, V(0, 0, 1), "Lily", Color3.fromRGB(240, 236, 230))
	box(lily, "ToyBox", 15.5, U, 27.5, 19.5, U + 2.2, 29.6, Color3.fromRGB(230, 200, 120), M.Wood)
	box(lily, "ToyBoxLid", 15.4, U + 2.2, 27.4, 19.6, U + 2.5, 29.7, Color3.fromRGB(210, 90, 90), M.Wood)
	box(lily, "FishTank", 36, U + 3, 9, 39.6, U + 5.4, 11, Color3.fromRGB(120, 170, 200), M.Glass, { Transparency = 0.4 })
	box(lily, "TankStand", 36, U, 9, 39.6, U + 3, 11, Color3.fromRGB(240, 236, 230), M.Wood)
	B.part(lily, { Name = "Fish", Shape = Enum.PartType.Ball, Size = V(0.4, 0.25, 0.25), CFrame = CFrame.new(37.5, U + 4.2, 10), Color = Color3.fromRGB(255, 140, 40), Material = Enum.Material.Neon, CanCollide = false })
	-- dollhouse
	box(lily, "Dollhouse", 28.4, U, 8.4, 32.4, U + 3.6, 10.7, Color3.fromRGB(250, 220, 230), M.Wood)
	B.part(lily, { ClassName = "WedgePart", Name = "DollRoof", Size = V(4, 1.2, 1.15), CFrame = CFrame.new(30.4, U + 4.2, 10.125), Color = Color3.fromRGB(200, 90, 110), Material = M.Wood })
	B.part(lily, { ClassName = "WedgePart", Name = "DollRoof", Size = V(4, 1.2, 1.15), CFrame = CFrame.new(30.4, U + 4.2, 8.975) * CFrame.Angles(0, math.pi, 0), Color = Color3.fromRGB(200, 90, 110), Material = M.Wood })
	for i = 0, 2 do
		box(lily, "DollWindow", 28.9 + i * 1.2, U + 1.6, 10.7, 29.6 + i * 1.2, U + 2.5, 10.75, Color3.fromRGB(255, 230, 160), M.Plastic, DECOR)
	end
	for i, col in { Color3.fromRGB(200, 160, 120), Color3.fromRGB(230, 230, 230), Color3.fromRGB(140, 110, 90) } do
		B.part(lily, { Name = "Plush", Shape = Enum.PartType.Ball, Size = V(1, 1, 1) * (0.8 + i * 0.1), CFrame = CFrame.new(33.5 + i * 1.2, U + 3.9, 28.6), Color = col, Material = M.Fabric, CanCollide = false })
	end
	-- string lights along the wall
	for i = 0, 11 do
		B.part(lily, { Name = "FairyLight", Shape = Enum.PartType.Ball, Size = V(0.3, 0.3, 0.3), CFrame = CFrame.new(20 + i * 1.6, U + 10.5 - math.sin(i / 11 * math.pi) * 0.8, 29.55), Color = Color3.fromRGB(255, 200, 150), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false })
	end
	local drawing = paper(lily, "Drawing", V(24, U + 5.5, 8.42), V(2.2, 1.6, 0.05))
	drawing.Color = Color3.fromRGB(250, 248, 240)
	ctx.Interaction.document(drawing, "LilyDrawing", { Object = "A crayon drawing", Distance = 7 })
	local nightlight = B.block(lily, "Nightlight", V(31, U + 1.2, 29.5), V(0.8, 0.8, 0.3), Color3.fromRGB(255, 220, 150), Enum.Material.Neon, 0, { CanCollide = false })
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
	box(base0, "Boiler", -27, BS, 12, -22, BS + 7, 17, Color3.fromRGB(110, 105, 95), M.Metal)
	B.cylinder(base0, "WaterHeater", V(-24, BS + 3.5, 26), 7, 3.5, Color3.fromRGB(190, 190, 185), M.Metal)
	target("Boiler", V(-32, BS + 3, 19))
	-- pipes the captives are tied to
	box(base0, "Pipe", -39.6, BS + 5.5, 10.5, -39.1, BS + 6, 29.5, Color3.fromRGB(120, 80, 60), M.Metal)
	box(base0, "Pipe", -39.6, BS + 1.5, 10.5, -39.1, BS + 2, 29.5, Color3.fromRGB(120, 80, 60), M.Metal)
	box(base0, "Pipe", -39.5, BS + 8, 29.1, -20.5, BS + 8.5, 29.6, Color3.fromRGB(120, 80, 60), M.Metal)
	for _, z in { 13, 19, 25 } do
		box(base0, "PipeRiser", -39.6, BS, z - 0.25, -39.1, BS + 11, z + 0.25, Color3.fromRGB(120, 80, 60), M.Metal)
	end
	box(base0, "Washer", -38.5, BS, -29.5, -34.5, BS + 4, -26, C.White, M.Metal)
	box(base0, "Dryer", -34, BS, -29.5, -30, BS + 4, -26, C.White, M.Metal)
	shelf(base0, -39.6, -20, -38, -6, BS, 8, 4, Color3.fromRGB(110, 110, 112))
	box(base0, "Boxes", -18, BS, -29.5, -10, BS + 5, -25, Color3.fromRGB(160, 130, 90), M.Cardboard)
	box(base0, "Boxes", -6, BS, 24, 2, BS + 4, 29.5, Color3.fromRGB(160, 130, 90), M.Cardboard)
	box(base0, "Freezer", -14, BS, 26, -8, BS + 3.5, 29.5, C.White, M.Metal)
	box(base0, "OldCouch", -12, BS, -6, -4, BS + 2.6, -2.5, Color3.fromRGB(90, 80, 60), M.Fabric)
	box(base0, "Workbench", -39.6, BS + 3, -4, -37, BS + 3.3, 4, WOOD_LIGHT, M.Wood)
	box(base0, "BenchBase", -39.6, BS, -3.8, -37.2, BS + 3, 3.8, WOOD_DARK, M.Wood)
	-- under-stairs nook, behind a tarp
	local tarp = box(base0, "Tarp", 5.8, BS, 11.5, 6, BS + 6, 20, Color3.fromRGB(60, 80, 90), M.Fabric)
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
	box(nest, "SleepingBag", n0.X - 3, A, n0.Z - 2, n0.X + 3, A + 0.5, n0.Z + 1.2, Color3.fromRGB(60, 75, 55), M.Fabric)
	box(nest, "Pillow", n0.X + 2, A + 0.5, n0.Z - 1.6, n0.X + 3, A + 0.9, n0.Z + 0.8, Color3.fromRGB(150, 140, 120), M.Fabric)
	local lantern = B.block(nest, "Lantern", V(n0.X + 5, A + 0.8, n0.Z - 4), V(0.8, 1.6, 0.8), Color3.fromRGB(230, 200, 120), Enum.Material.Neon, 0, { CanCollide = false })
	local ll = Instance.new("PointLight")
	ll.Range = 16
	ll.Brightness = 0.9
	ll.Color = Color3.fromRGB(255, 190, 110)
	ll.Shadows = true
	ll.Parent = lantern
	ctx.Power.setStaticLit("Attic", true)
	for i = 1, 7 do
		local a = i * 0.9
		box(nest, "Wrapper", n0.X - 5 + math.cos(a) * 2.5, A, n0.Z + 3 + math.sin(a), n0.X - 4.2 + math.cos(a) * 2.5, A + 0.08, n0.Z + 3.6 + math.sin(a), Color3.fromHSV(i / 7, 0.6, 0.8), M.Plastic, DECOR)
	end
	for i = 1, 4 do
		B.cylinder(nest, "Bottle", V(n0.X - 2 + i * 0.6, A + 0.6, n0.Z + 2.5), 1.2, 0.4, Color3.fromRGB(120, 160, 120), M.Glass, CFrame.new())
	end
	local notebook = box(nest, "Notebook", n0.X + 1, A + 0.5, n0.Z + 2, n0.X + 2.2, A + 0.62, n0.Z + 3.4, Color3.fromRGB(40, 60, 120), M.Cardboard, { CanCollide = false })
	target("Nest", notebook.Position)
	local polaroids = box(nest, "Polaroids", -28.4, A + 1.5, n0.Z - 2, -28.2, A + 4.5, n0.Z + 3, Color3.fromRGB(220, 215, 205), M.Plastic, { CanCollide = false })
	local lanyard = box(nest, "Lanyard", n0.X - 1.5, A + 0.5, n0.Z - 4, n0.X - 0.5, A + 0.58, n0.Z - 3.2, Color3.fromRGB(40, 90, 160), M.Plastic, { CanCollide = false })
	for part, doc in { [notebook] = "Notebook", [polaroids] = "Polaroids", [lanyard] = "Lanyard" } do
		ctx.Interaction.document(part, doc, { Distance = 7 }, function(player)
			ctx.Director.onDiscovery(player, doc)
		end)
	end
	ctx.Escape.setNest(nest, V(n0.X - 3.5, A + 0.3, n0.Z - 3))

	---------------------------------------------------------------------------
	-- Lobby spawn (living room)
	---------------------------------------------------------------------------
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.Transparency = 1
	spawn.Size = V(6, 0.2, 6)
	spawn.CFrame = CFrame.new(-24, G + 0.2, -12)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = root
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end

	return refs
end

return Interior
