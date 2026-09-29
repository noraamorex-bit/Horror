--[[
	House — builds the shell of 14 Alder Lane from Layout: slabs, walls, doors, windows,
	stairs, railings, roof, ceiling lights, switches and the attic hatch.
	Returns refs used by the interior and the director.
]]

local TweenService = game:GetService("TweenService")

local Textures = require(script.Parent.Textures)

local House = {}

function House.build(ctx, root: Instance)
	local B = ctx.Builder
	local L = ctx.Layout
	local C, M = B.C, B.M
	local refs = { Windows = {}, OpenWindows = {} }

	local shell = Instance.new("Folder")
	shell.Name = "Structure"
	shell.Parent = root
	local doorsFolder = Instance.new("Folder")
	doorsFolder.Name = "Doors"
	doorsFolder.Parent = root
	local windowsFolder = Instance.new("Folder")
	windowsFolder.Name = "Windows"
	windowsFolder.Parent = root
	local lightsFolder = Instance.new("Folder")
	lightsFolder.Name = "Lights"
	lightsFolder.Parent = root

	---------------------------------------------------------------------------
	-- Slabs (structural slab = ceiling below; thin finish on top)
	---------------------------------------------------------------------------
	B.slab(shell, "BasementFloor", -40, 12, -30, 30, -13, 1, {}, C.Concrete, M.Concrete)
	B.slab(shell, "GroundSlab", -40, 40, -30, 30, 0.9, 0.9, { { 6, 12, -0.4, 22 } }, Color3.fromRGB(150, 140, 125), M.Planks)
	B.slab(shell, "UpstairsSlab", -40, 40, -30, 30, 14.9, 0.9, { { -8, -2, -6, 16.4 } }, C.Drywall, M.Wall)
	local h = L.AtticHatch
	B.slab(shell, "AtticSlab", -40, 40, -30, 30, 28.9, 0.9, { { h.x0, h.x1, h.z0, h.z1 } }, C.Drywall, M.Wall)
	B.slab(shell, "GarageFloor", 40, 66, -30, 6, 1, 1, {}, C.Concrete, M.Concrete)
	local gh = L.GarageHatch
	B.slab(shell, "GarageCeiling", 40, 66, -30, 6, 15, 1, { { gh.x0, gh.x1, gh.z0, gh.z1 } }, C.Drywall, M.Wall)
	-- the dark crawl space above the garage hatch
	B.box(shell, "CrawlSpace", Vector3.new(gh.x0 - 1, 15, gh.z0 - 1), Vector3.new(gh.x1 + 1, 19, gh.z1 + 1), C.Black, M.Planks)

	for floorName, list in L.FloorFinish do
		local y = L.Y[floorName]
		for _, f in list do
			local floor = B.box(shell, "Floor", Vector3.new(f[1], y - 0.1, f[3]), Vector3.new(f[2], y, f[4]), C[f[5]], M[f[6]])
			if f[7] then
				-- carpet takes the room's colour; wood and tile show their own
				local tint = f[7] == "Carpet" and C[f[5]]:Lerp(Color3.new(1, 1, 1), 0.35) or nil
				Textures.apply(floor, f[7], { Enum.NormalId.Top }, tint)
			end
		end
	end
	for floorName, hf in L.HallFloor do
		local y = L.Y[floorName]
		local before = {}
		for _, c in shell:GetChildren() do
			before[c] = true
		end
		B.slab(shell, "HallFloor", hf.x0, hf.x1, hf.z0, hf.z1, y, 0.1, hf.holes, C.Oak, M.Planks)
		for _, c in shell:GetChildren() do
			if not before[c] and c:IsA("BasePart") then
				Textures.apply(c, "Parquet", { Enum.NormalId.Top }, Color3.fromRGB(235, 220, 205))
			end
		end
	end
	-- attic: insulation everywhere, plywood walkway from the hatch to the nest
	B.slab(shell, "Insulation", -40, 40, -30, 30, 29.2, 0.3, { { h.x0, h.x1, h.z0, h.z1 } }, Color3.fromRGB(215, 150, 150), M.Insulation)
	B.box(shell, "Walkway", Vector3.new(-30, 29.2, h.z0 - 1), Vector3.new(h.x0, 29.4, h.z1 + 1), Color3.fromRGB(175, 145, 100), M.Planks)
	B.box(shell, "Walkway", Vector3.new(-30, 29.2, -6), Vector3.new(-18, 29.4, h.z0 - 1), Color3.fromRGB(175, 145, 100), M.Planks)

	---------------------------------------------------------------------------
	-- Walls
	---------------------------------------------------------------------------
	local function copyOpenings(list)
		local out = {}
		for _, op in list do
			table.insert(out, table.clone(op))
		end
		return out
	end

	local function handleOpening(op, floorName)
		if op.kind == "door" then
			local door = ctx.Doors.create(doorsFolder, op)
			-- casing
			local alongX = op.Axis == "X"
			local depth = (op.Thickness or 0.6) + 0.3
			for side = -1, 1, 2 do
				local off = alongX and Vector3.new(side * (op.w / 2 + 0.2), op.h / 2, 0) or Vector3.new(0, op.h / 2, side * (op.w / 2 + 0.2))
				local size = alongX and Vector3.new(0.4, op.h, depth) or Vector3.new(depth, op.h, 0.4)
				B.block(shell, "Casing", op.Center + off, size, C.Trim, M.Wood, 0, { CanCollide = false })
			end
			local topSize = alongX and Vector3.new(op.w + 0.8, 0.4, depth) or Vector3.new(depth, 0.4, op.w + 0.8)
			B.block(shell, "Casing", op.Center + Vector3.new(0, op.h + 0.2, 0), topSize, C.Trim, M.Wood, 0, { CanCollide = false })
			return door
		elseif op.kind == "window" then
			local model, glass = B.window(windowsFolder, op, { name = "Window_" .. op.id })
			refs.Windows[op.id] = { Model = model, Glass = glass, Op = op }
			if op.open then
				-- sash raised: the window is open to the storm
				local closedCF = glass.CFrame
				glass.CFrame = closedCF * CFrame.new(0, op.h * 0.45, 0)
				glass.Size = glass.Size * Vector3.new(1, 0.55, 1)
				local entry = { Glass = glass, Closed = false }
				local targetName = op.id == "GuestFront" and "GuestWindow" or (op.id == "LilyBack" and "LilyWindow" or op.id)
				ctx.Objectives.setTarget(targetName, glass.Position)
				table.insert(refs.OpenWindows, entry)
				local prompt
				prompt = ctx.Interaction.prompt(glass, {
					Action = "Close window",
					Object = "Open window",
					Distance = 7,
				}, function(player)
					if entry.Closed then
						return
					end
					entry.Closed = true
					prompt.Enabled = false
					TweenService:Create(glass, TweenInfo.new(0.6), { CFrame = closedCF, Size = glass.Size / Vector3.new(1, 0.55, 1) }):Play()
					ctx.Audio.playAt("WindowClose", glass.Position, { Caption = false })
					ctx.Objectives.step("Windows", op.id)
					local all = true
					for _, w in refs.OpenWindows do
						if not w.Closed then
							all = false
						end
					end
					if all then
						ctx.Objectives.complete("Windows")
					end
				end)
			end
			if op.breakable then
				ctx.Escape.setupBreakableWindow(glass, op)
			end
		elseif op.kind == "garage" then
			local door = B.box(shell, "GarageDoor", Vector3.new(op.at - op.w / 2, 1, -30.3), Vector3.new(op.at + op.w / 2, 11, -29.7), Color3.fromRGB(215, 212, 205), M.Metal)
			for i = 1, 4 do
				B.box(door, "Seam", Vector3.new(op.at - op.w / 2, 1 + i * 2.4, -30.35), Vector3.new(op.at + op.w / 2, 1.1 + i * 2.4, -29.65), Color3.fromRGB(180, 178, 172), M.Metal, { CanCollide = false })
			end
			refs.GarageDoor = door
		end
		return nil
	end

	for _, spec in L.ExteriorWalls do
		local y0 = L.Y[spec.floor]
		local alongX = spec.z1 == spec.z2
		local fixed = alongX and spec.z1 or spec.x1
		local outSign = spec.out == "+" and 1 or -1
		if spec.concrete then
			local ops = B.wall(shell, { x1 = spec.x1, z1 = spec.z1, x2 = spec.x2, z2 = spec.z2, y0 = y0, h = L.WallH, t = 1, color = C.Concrete, material = M.Concrete, openings = spec.openings, name = "BasementWall" })
			for _, op in ops do
				op.Thickness = 1
				handleOpening(op, spec.floor)
			end
		else
			local ext = alongX and 0.5 or 0
			local outer = {
				x1 = alongX and math.min(spec.x1, spec.x2) - ext or fixed + outSign * 0.25,
				x2 = alongX and math.max(spec.x1, spec.x2) + ext or fixed + outSign * 0.25,
				z1 = alongX and fixed + outSign * 0.25 or spec.z1,
				z2 = alongX and fixed + outSign * 0.25 or spec.z2,
				y0 = y0 - (spec.floor == "Ground" and 1 or 0),
				h = L.WallH + (spec.floor == "Ground" and 1 or 0) + 1,
				t = 0.5,
				color = spec.garage and Color3.fromRGB(125, 132, 136) or C.Siding,
				material = M.Siding,
				openings = copyOpenings(spec.openings),
				name = "Siding",
			}
			-- keep openings aligned when the outer layer starts lower
			if spec.floor == "Ground" then
				for _, op in outer.openings do
					op.bottom = (op.bottom or 0) + 1
				end
			end
			B.wall(shell, outer)
			local innerColor = spec.garage and Color3.fromRGB(170, 168, 160) or C[L.WallColor[spec.floor]]
			local inner = {
				x1 = alongX and spec.x1 or fixed - outSign * 0.25,
				x2 = alongX and spec.x2 or fixed - outSign * 0.25,
				z1 = alongX and fixed - outSign * 0.25 or spec.z1,
				z2 = alongX and fixed - outSign * 0.25 or spec.z2,
				y0 = y0,
				h = L.WallH,
				t = 0.5,
				color = innerColor,
				material = spec.garage and M.Concrete or M.Wall,
				openings = spec.openings,
				name = "Wall",
			}
			local ops = B.wall(shell, inner)
			for _, op in ops do
				op.Center = alongX and Vector3.new(op.at, y0 + (op.bottom or 0), fixed) or Vector3.new(fixed, y0 + (op.bottom or 0), op.at)
				op.Thickness = 1
				handleOpening(op, spec.floor)
			end
		end
	end

	for _, spec in L.InteriorWalls do
		local y0 = L.Y[spec.floor]
		local color = C[L.WallColor[spec.floor]]
		local material = spec.floor == "Basement" and M.Concrete or M.Wall
		local ops = B.wall(shell, { x1 = spec.x1, z1 = spec.z1, x2 = spec.x2, z2 = spec.z2, y0 = y0, h = L.WallH, t = 0.6, color = color, material = material, openings = spec.openings })
		for _, op in ops do
			handleOpening(op, spec.floor)
		end
	end

	-- exterior trim: shutters beside every window, corner boards, floor band and frieze
	local TRIM = C.Trim
	local SHUTTER = Color3.fromRGB(38, 56, 48)
	for _, spec in L.ExteriorWalls do
		if spec.concrete or spec.garage then
			continue
		end
		local alongX = spec.z1 == spec.z2
		local fixed = alongX and spec.z1 or spec.x1
		local outSign = spec.out == "+" and 1 or -1
		local face = fixed + outSign * 0.5
		local y0 = L.Y[spec.floor]
		for _, op in spec.openings do
			if op.kind == "window" and op.w >= 5 then
				for sgn = -1, 1, 2 do
					local along = op.at + sgn * (op.w / 2 + 1.2)
					local yb, yt = y0 + (op.bottom or 0), y0 + (op.bottom or 0) + op.h
					if alongX then
						B.box(shell, "Shutter", Vector3.new(along - 0.9, yb, face), Vector3.new(along + 0.9, yt, face + outSign * 0.25), SHUTTER, M.Wood, { CanCollide = false })
					else
						B.box(shell, "Shutter", Vector3.new(face, yb, along - 0.9), Vector3.new(face + outSign * 0.25, yt, along + 0.9), SHUTTER, M.Wood, { CanCollide = false })
					end
				end
			end
		end
	end
	for _, c in { { -40, -30 }, { 40, -30 }, { -40, 30 }, { 40, 30 }, { 66, -30 }, { 66, 6 } } do
		local top = c[1] == 66 and 15 or 28.5
		B.box(shell, "CornerBoard", Vector3.new(c[1] - 0.8, 0, c[2] - 0.8), Vector3.new(c[1] + 0.8, top, c[2] + 0.8), TRIM, M.Wood)
	end
	for _, y in { 14.4 } do
		B.box(shell, "Band", Vector3.new(-40.7, y, -30.8), Vector3.new(40.7, y + 0.7, -30.5), TRIM, M.Wood, { CanCollide = false })
		B.box(shell, "Band", Vector3.new(-40.7, y, 30.5), Vector3.new(40.7, y + 0.7, 30.8), TRIM, M.Wood, { CanCollide = false })
	end
	B.box(shell, "Frieze", Vector3.new(-40.8, 27.6, -30.9), Vector3.new(40.8, 28.6, -30.4), TRIM, M.Wood, { CanCollide = false })
	B.box(shell, "Frieze", Vector3.new(-40.8, 27.6, 30.4), Vector3.new(40.8, 28.6, 30.9), TRIM, M.Wood, { CanCollide = false })

	-- baseboards along the main hallways for a finished look
	for _, y in { L.Y.Ground, L.Y.Upstairs } do
		B.box(shell, "Baseboard", Vector3.new(-7.7, y, -30), Vector3.new(-7.5, y + 0.6, 30), C.Trim, M.Wood, { CanCollide = false })
		B.box(shell, "Baseboard", Vector3.new(11.5, y, -30), Vector3.new(11.7, y + 0.6, 30), C.Trim, M.Wood, { CanCollide = false })
	end

	---------------------------------------------------------------------------
	-- Stairs and railings
	---------------------------------------------------------------------------
	local s = L.Stairs.Main
	B.stairs(shell, "MainStairs", s.x0, s.x1, s.zStart, s.zEnd, s.yStart, s.yEnd, C.Oak)
	B.railing(shell, Vector3.new(-2, 1, -6), Vector3.new(-2, 15, 16.4), 3.4)
	B.railing(shell, Vector3.new(-2, 15, -6), Vector3.new(-2, 15, 16.4), 3.4)
	B.railing(shell, Vector3.new(-8, 15, -6), Vector3.new(-2, 15, -6), 3.4)
	B.block(shell, "Newel", Vector3.new(-2, 3.5, -6), Vector3.new(0.8, 5, 0.8), C.DarkWood, M.Wood)
	local bs = L.Stairs.Basement
	B.stairs(shell, "BasementStairs", bs.x0, bs.x1, bs.zStart, bs.zEnd, bs.yStart, bs.yEnd, Color3.fromRGB(120, 105, 85))
	B.railing(shell, Vector3.new(6, -13, -0.4), Vector3.new(6, 1, 22), 3.2, Color3.fromRGB(90, 80, 70))

	---------------------------------------------------------------------------
	-- Roof
	---------------------------------------------------------------------------
	local rise, run = 14, 32
	local slopeLen = math.sqrt(rise * rise + run * run) + 1
	local angle = math.atan2(rise, run)
	B.part(shell, { Name = "Roof", Size = Vector3.new(86, 0.8, slopeLen), CFrame = CFrame.new(0, 28 + rise / 2 + 0.4, -run / 2) * CFrame.Angles(-angle, 0, 0), Color = C.Roof, Material = M.Roof })
	B.part(shell, { Name = "Roof", Size = Vector3.new(86, 0.8, slopeLen), CFrame = CFrame.new(0, 28 + rise / 2 + 0.4, run / 2) * CFrame.Angles(angle, 0, 0), Color = C.Roof, Material = M.Roof })
	B.part(shell, { Name = "Ridge", Size = Vector3.new(86, 0.6, 1.2), CFrame = CFrame.new(0, 28 + rise + 0.5, 0), Color = C.Roof, Material = M.Roof })
	for _, x in { -40.25, 40.25 } do
		B.part(shell, { ClassName = "WedgePart", Name = "Gable", Size = Vector3.new(0.5, 13, 30), CFrame = CFrame.new(x, 29 + 6.5, -15), Color = C.Siding, Material = M.Siding })
		B.part(shell, { ClassName = "WedgePart", Name = "Gable", Size = Vector3.new(0.5, 13, 30), CFrame = CFrame.new(x, 29 + 6.5, 15) * CFrame.Angles(0, math.pi, 0), Color = C.Siding, Material = M.Siding })
		B.box(shell, "GableBand", Vector3.new(x - 0.3, 28, -30.5), Vector3.new(x + 0.3, 29, 30.5), C.Trim, M.Wood)
	end
	-- attic rafters
	for x = -36, 36, 8 do
		for _, sgn in { -1, 1 } do
			B.part(shell, { Name = "Rafter", Size = Vector3.new(0.6, 0.9, slopeLen - 2), CFrame = CFrame.new(x, 28 + rise / 2 - 0.5, sgn * run / 2) * CFrame.Angles(sgn * angle, 0, 0), Color = Color3.fromRGB(150, 120, 85), Material = M.Wood, CanCollide = false })
		end
	end
	-- garage roof
	B.box(shell, "GarageRoof", Vector3.new(39.5, 16, -31), Vector3.new(67, 16.8, 7), C.Roof, M.Roof)
	B.box(shell, "GarageFascia", Vector3.new(40, 15, -31), Vector3.new(66.5, 16, -30.4), C.Trim, M.Wood)
	-- chimney on the west gable, behind the living-room fireplace: a wide firebox base,
	-- sloped shoulders, then the stack past the ridge with a cap and two flue pots
	local BRICK = Color3.fromRGB(116, 62, 50)
	B.box(shell, "Chimney", Vector3.new(-44.2, 0, -17.2), Vector3.new(-40.4, 12, -6.8), BRICK, M.Brick)
	for _, sgn in { -1, 1 } do
		B.part(shell, { ClassName = "WedgePart", Name = "ChimneyShoulder", Size = Vector3.new(3.8, 3, 3.2), CFrame = CFrame.new(-42.3, 13.5, -12 + sgn * 3.6) * CFrame.Angles(0, sgn > 0 and math.pi or 0, 0), Color = BRICK, Material = M.Brick })
	end
	B.box(shell, "ChimneyStack", Vector3.new(-43.6, 12, -14), Vector3.new(-40.4, 44.5, -10), BRICK, M.Brick)
	B.box(shell, "ChimneyCap", Vector3.new(-44, 44.5, -14.4), Vector3.new(-40, 45.2, -9.6), Color3.fromRGB(120, 116, 110), M.Concrete)
	for _, z in { -13, -11 } do
		B.cylinder(shell, "FluePot", Vector3.new(-42, 45.9, z), 1.4, 0.9, Color3.fromRGB(150, 90, 70), M.Concrete)
	end
	-- foundation skirt
	B.box(shell, "Foundation", Vector3.new(-40.6, -0.5, -30.6), Vector3.new(66.6, 0.2, 30.6), C.Concrete, M.Concrete, { CanCollide = false })

	---------------------------------------------------------------------------
	-- Ceiling lights and switches
	---------------------------------------------------------------------------
	for room, positions in L.Lights do
		for _, pos in positions do
			local range = (room == "Hallway" or room == "UpperHall") and 20 or 26
			local shadows = room ~= "Hallway" and room ~= "UpperHall"
			local bulb, light = B.ceilingLight(lightsFolder, pos, { range = range, shadows = shadows })
			ctx.Power.registerLight(room, bulb, light)
		end
	end
	for _, sw in L.Switches do
		local size = (sw.Face == "+X" or sw.Face == "-X") and Vector3.new(0.12, 0.9, 0.55) or Vector3.new(0.55, 0.9, 0.12)
		-- stand proud of the wall finishes (paint + wainscot) so the plate is never buried
		local out = ({ ["+X"] = Vector3.new(0.14, 0, 0), ["-X"] = Vector3.new(-0.14, 0, 0), ["+Z"] = Vector3.new(0, 0, 0.14), ["-Z"] = Vector3.new(0, 0, -0.14) })[sw.Face] or Vector3.zero
		local plate = B.block(lightsFolder, "Switch_" .. sw.Room, sw.Pos + out, size, C.White, M.Plastic)
		ctx.Power.registerSwitch(sw.Room, plate)
	end
	for room in L.StartLit do
		ctx.Power.setSwitch(room, true)
	end

	---------------------------------------------------------------------------
	-- Attic hatch (upstairs hall): stuck until Act III, then a ladder
	---------------------------------------------------------------------------
	local hatchModel = Instance.new("Model")
	hatchModel.Name = "AtticHatch"
	hatchModel.Parent = root
	local hx, hz = (h.x0 + h.x1) / 2, (h.z0 + h.z1) / 2
	local panelClosed = CFrame.new(hx, 28.15, hz)
	local panel = B.part(hatchModel, { Name = "HatchPanel", Size = Vector3.new(h.x1 - h.x0 - 0.1, 0.3, h.z1 - h.z0 - 0.1), CFrame = panelClosed, Color = C.Drywall, Material = M.Wall })
	local panelOpen = CFrame.new(hx, 28.15 - (h.z1 - h.z0) / 2, h.z0 + 0.3) * CFrame.Angles(math.rad(90), 0, 0)
	local cord = B.part(hatchModel, { Name = "Cord", Size = Vector3.new(0.12, 3, 0.12), CFrame = CFrame.new(hx, 26.5, h.z1 - 1), Color = Color3.fromRGB(230, 230, 220), Material = M.Fabric, CanCollide = false })
	local handle = B.part(hatchModel, { Name = "CordHandle", Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(hx, 24.9, h.z1 - 1), Color = Color3.fromRGB(230, 230, 220), CanCollide = false })
	local ladder = Instance.new("TrussPart")
	ladder.Name = "Ladder"
	ladder.Anchored = true
	ladder.Size = Vector3.new(2, 16, 2)
	ladder.CFrame = CFrame.new(hx, 15 + 8, h.z1 - 1)
	ladder.Color = Color3.fromRGB(150, 120, 80)
	ladder.Material = M.Wood
	ladder.Transparency = 1
	ladder.CanCollide = false
	ladder.CanQuery = false
	ladder.Parent = hatchModel

	local hatch = { Open = false, Panel = panel, Cord = cord, Handle = handle, Ladder = ladder, CordCF = cord.CFrame, HandleCF = handle.CFrame }
	refs.AtticHatch = hatch

	function hatch.open()
		if hatch.Open then
			return
		end
		hatch.Open = true
		TweenService:Create(panel, TweenInfo.new(1.2, Enum.EasingStyle.Bounce), { CFrame = panelOpen }):Play()
		cord.Transparency = 1
		handle.Transparency = 1
		ladder.Transparency = 0
		ladder.CanCollide = true
		ladder.CanQuery = true
		ctx.Audio.playAt("HatchCreak", Vector3.new(hx, 26, hz))
		if hatch.Prompt then
			hatch.Prompt.Enabled = false
		end
	end

	-- a gentle swing, as if someone just pulled it shut from above
	function hatch.swing(duration: number)
		task.spawn(function()
			local t0 = os.clock()
			while os.clock() - t0 < duration and not hatch.Open do
				local t = os.clock() - t0
				local amp = math.rad(22) * (1 - t / duration)
				local a = math.sin(t * 5) * amp
				local pivot = CFrame.new(hx, 28, h.z1 - 1)
				cord.CFrame = pivot * CFrame.Angles(a, 0, 0) * CFrame.new(0, -1.5, 0)
				handle.CFrame = pivot * CFrame.Angles(a, 0, 0) * CFrame.new(0, -3.1, 0)
				task.wait()
			end
			if not hatch.Open then
				cord.CFrame = hatch.CordCF
				handle.CFrame = hatch.HandleCF
			end
		end)
	end

	ctx.Objectives.setTarget("Hatch", handle.Position)
	hatch.Prompt = ctx.Interaction.prompt(handle, {
		Action = "Pull",
		Object = "Attic hatch",
		Hold = 0.5,
		Distance = 8,
	}, function(player)
		local act = ctx.Director.getAct()
		if act == "SomeoneElse" or act == "Guest" then
			hatch.open()
			ctx.Objectives.step("Attic", "Hatch")
		else
			ctx.Audio.caption("It won't budge. Like something's holding it shut from above.", nil, nil, { player })
			ctx.Audio.playAt("HatchCreak", Vector3.new(hx, 28, hz), { Caption = false })
			ctx.Director.logTruth("HatchStuck")
		end
	end)

	-- garage hatch cover (moved aside when he starts using it in Act III)
	local cover = B.box(root, "GarageHatchCover", Vector3.new(gh.x0, 14.7, gh.z0), Vector3.new(gh.x1, 15, gh.z1), C.Drywall, M.Wall)
	refs.GarageHatchCover = cover
	function refs.openGarageHatch()
		if cover.Parent then
			TweenService:Create(cover, TweenInfo.new(0.8), { CFrame = cover.CFrame * CFrame.new(0, 1.2, 4.5) }):Play()
		end
	end

	refs.Shell = shell
	return refs
end

return House
