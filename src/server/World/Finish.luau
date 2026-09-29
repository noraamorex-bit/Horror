--[[
	Finish — interior finishes, built from the real wall layout so doorways, arches and windows
	stay open: per-room wall paint / wallpaper / tile, wainscoting with a chair rail, baseboards,
	crown molding, curtains on every window, and framed pictures.
]]

local CollectionService = game:GetService("CollectionService")

local Textures = require(script.Parent.Textures)

local Finish = {}

local V = Vector3.new
local WHITE = Color3.fromRGB(238, 234, 226)

-- Wall: paint colour; Mat: material; Wainscot: lower panelling colour (nil = none); Curtain colour
local PALETTE = {
	Living = { Wall = Color3.fromRGB(196, 176, 148), Paper = "Damask", Mat = "Fabric", Wainscot = WHITE, Curtain = Color3.fromRGB(120, 50, 45), Art = 2 },
	Kitchen = { Wall = Color3.fromRGB(176, 190, 164), Mat = "Plaster", Curtain = Color3.fromRGB(215, 205, 170), Art = 1 },
	Hallway = { Wall = Color3.fromRGB(214, 202, 178), Paper = "Stripes", Mat = "Plaster", Wainscot = WHITE, Curtain = Color3.fromRGB(120, 50, 45), Art = 3 },
	Office = { Wall = Color3.fromRGB(52, 64, 88), Paper = "Damask", Mat = "Plaster", Wainscot = Color3.fromRGB(92, 62, 42), WainscotMat = "Wood", Curtain = Color3.fromRGB(150, 120, 80), Art = 2 },
	Bathroom = { Wall = Color3.fromRGB(170, 196, 208), Mat = "Plaster", Wainscot = Color3.fromRGB(236, 236, 232), WainscotMat = "Tile", WainscotH = 5, Art = 0 },
	MudHall = { Wall = Color3.fromRGB(140, 152, 136), Mat = "Plaster", Wainscot = Color3.fromRGB(238, 234, 226), Art = 1 },
	Mudroom = { Wall = Color3.fromRGB(140, 152, 136), Mat = "Plaster", Wainscot = WHITE, Art = 0 },
	Den = { Wall = Color3.fromRGB(68, 88, 72), Paper = "Damask", Mat = "Fabric", Wainscot = Color3.fromRGB(110, 78, 52), WainscotMat = "Wood", Curtain = Color3.fromRGB(200, 180, 140), Art = 2 },
	Master = { Wall = Color3.fromRGB(150, 164, 182), Paper = "Stripes", Mat = "Fabric", Wainscot = WHITE, Curtain = Color3.fromRGB(230, 225, 215), Art = 2 },
	MasterBath = { Wall = Color3.fromRGB(205, 210, 205), Mat = "Plaster", Wainscot = Color3.fromRGB(236, 236, 232), WainscotMat = "Tile", WainscotH = 6, Art = 0 },
	Jamie = { Wall = Color3.fromRGB(78, 124, 134), Mat = "Plaster", Curtain = Color3.fromRGB(40, 50, 70), Art = 3 },
	Guest = { Wall = Color3.fromRGB(214, 198, 150), Paper = "Roses", Mat = "Fabric", Wainscot = WHITE, Curtain = Color3.fromRGB(160, 140, 110), Art = 1 },
	HallBath = { Wall = Color3.fromRGB(176, 214, 196), Mat = "Plaster", Wainscot = Color3.fromRGB(236, 236, 232), WainscotMat = "Tile", WainscotH = 6, Art = 0 },
	Lily = { Wall = Color3.fromRGB(226, 182, 196), Paper = "Floral", Mat = "Fabric", Wainscot = WHITE, Curtain = Color3.fromRGB(250, 235, 240), Art = 2 },
	UpperHall = { Wall = Color3.fromRGB(214, 202, 178), Paper = "Stripes", Mat = "Plaster", Wainscot = WHITE, Curtain = Color3.fromRGB(120, 50, 45), Art = 3 },
}

local ART_COLORS = {
	Color3.fromRGB(70, 90, 120), Color3.fromRGB(150, 110, 70), Color3.fromRGB(60, 100, 80),
	Color3.fromRGB(180, 150, 110), Color3.fromRGB(120, 60, 60), Color3.fromRGB(200, 190, 170),
}

function Finish.build(ctx, root: Instance)
	local B = ctx.Builder
	local L = ctx.Layout
	local Util = ctx.Util
	local folder = Instance.new("Folder")
	folder.Name = "Finishes"
	folder.Parent = root

	local MATS = {
		Fabric = Enum.Material.Fabric,
		Plaster = Util.material("Plaster", "SmoothPlastic"),
		Wood = Enum.Material.Wood,
		Tile = Util.material("CeramicTiles", "Slate"),
	}

	-- every finished wall line: floor, orientation, fixed coord, span, openings, face offset
	local lines = {}
	local function addLine(spec, exterior: boolean)
		if spec.floor == "Basement" then
			return
		end
		local alongX = spec.z1 == spec.z2
		table.insert(lines, {
			Floor = spec.floor,
			AlongX = alongX,
			Fixed = alongX and spec.z1 or spec.x1,
			A0 = alongX and math.min(spec.x1, spec.x2) or math.min(spec.z1, spec.z2),
			A1 = alongX and math.max(spec.x1, spec.x2) or math.max(spec.z1, spec.z2),
			Openings = spec.openings or {},
			Offset = exterior and 0.5 or 0.3,
		})
	end
	for _, spec in L.ExteriorWalls do
		if not spec.concrete and not spec.garage then
			addLine(spec, true)
		end
	end
	for _, spec in L.InteriorWalls do
		addLine(spec, false)
	end

	-- A horizontal band (yb..yt) of finish along a room side, with holes for openings.
	local function band(side, yb: number, yt: number, depth: number, extraOffset: number, color: Color3, mat: Enum.Material, name: string, tag: string?, tex)
		local y0 = side.Y0
		for _, line in side.Lines do
			local s0, s1 = math.max(side.A0, line.A0), math.min(side.A1, line.A1)
			if s1 - s0 < 0.2 then
				continue
			end
			local ops = {}
			-- floor-level trim stops where the side runs past a stairwell (no floor to sit on there)
			if yb < y0 + 6 and name ~= "Paint" then
				for _, h in side.Holes do
					if h[2] > s0 and h[1] < s1 then
						table.insert(ops, { at = (h[1] + h[2]) / 2, w = h[2] - h[1], bottom = 0, h = yt - yb })
					end
				end
			end
			for _, op in line.Openings do
				local o0, o1 = op.at - op.w / 2, op.at + op.w / 2
				local ob, ot = y0 + (op.bottom or 0), y0 + (op.bottom or 0) + op.h
				if o1 > s0 and o0 < s1 and ot > yb and ob < yt then
					local nb = math.max(0, ob - yb)
					local nt = math.min(yt, ot) - yb
					table.insert(ops, { at = op.at, w = op.w, bottom = nb, h = nt - nb })
				end
			end
			local off = line.Offset + extraOffset + depth / 2
			local fixed = side.Fixed + side.Inward * off
			local spec = {
				y0 = yb,
				h = yt - yb,
				t = depth,
				color = color,
				material = mat,
				openings = ops,
				name = name,
			}
			if side.AlongX then
				spec.x1, spec.x2, spec.z1, spec.z2 = s0, s1, fixed, fixed
			else
				spec.x1, spec.x2, spec.z1, spec.z2 = fixed, fixed, s0, s1
			end
			local before = #folder:GetChildren()
			B.wall(folder, spec)
			for i, child in folder:GetChildren() do
				if i > before and child:IsA("BasePart") then
					child.CanCollide = false
					child.CanQuery = false
					child.CastShadow = name ~= "Paint"
					if tag then
						CollectionService:AddTag(child, tag)
					end
					if tex then
						local faces = side.AlongX and { Enum.NormalId.Front, Enum.NormalId.Back } or { Enum.NormalId.Left, Enum.NormalId.Right }
						Textures.apply(child, tex.Key, faces, tex.Color, tex.Transparency)
					end
				end
			end
		end
	end

	local rng = Random.new(1419)
	for roomName, pal in PALETTE do
		local r = ctx.Rooms.ByName[roomName]
		if not r then
			continue
		end
		local y0 = L.Y[r.Floor]
		local r0Floor = r.Floor
		local x0, x1, z0, z1 = r.Min.X, r.Max.X, r.Min.Z, r.Max.Z
		local sides = {
			{ AlongX = true, Fixed = z0, A0 = x0, A1 = x1, Inward = 1 },
			{ AlongX = true, Fixed = z1, A0 = x0, A1 = x1, Inward = -1 },
			{ AlongX = false, Fixed = x0, A0 = z0, A1 = z1, Inward = 1 },
			{ AlongX = false, Fixed = x1, A0 = z0, A1 = z1, Inward = -1 },
		}
		local artLeft = pal.Art or 0
		for _, side in sides do
			side.Y0 = y0
			side.Holes = {}
			local hall = L.HallFloor[r.Floor]
			for _, h in (hall and hall.holes or {}) do
				-- {x0, x1, z0, z1}: a hole touching this side cuts the trim along its span
				local p0, p1, a0, a1 = h[1], h[2], h[3], h[4] -- side along Z: fixed X
				if side.AlongX then
					p0, p1, a0, a1 = h[3], h[4], h[1], h[2]
				end
				if side.Fixed > p0 - 0.8 and side.Fixed < p1 + 0.8 then
					table.insert(side.Holes, { a0, a1 })
				end
			end
			side.Lines = {}
			for _, line in lines do
				if line.Floor == r.Floor and line.AlongX == side.AlongX and math.abs(line.Fixed - side.Fixed) < 0.05
					and line.A1 > side.A0 + 0.1 and line.A0 < side.A1 - 0.1 then
					table.insert(side.Lines, line)
				end
			end
			if #side.Lines == 0 then
				continue
			end
			local wainH = pal.WainscotH or 3.4
			-- paint / wallpaper
			-- paint, or wallpaper tinted to the room's colour
			local paper = pal.Paper and { Key = pal.Paper, Color = pal.Wall:Lerp(Color3.new(1, 1, 1), 0.45), Transparency = 0.1 } or nil
			band(side, y0, y0 + 13, 0.06, 0, pal.Wall, MATS[pal.Mat] or MATS.Plaster, "Paint", nil, paper)
			-- wainscoting + chair rail (tiled in the bathrooms)
			if pal.Wainscot then
				local tile = pal.WainscotMat == "Tile" and { Key = "TileWhite", Color = pal.Wainscot } or nil
				band(side, y0, y0 + wainH, 0.12, 0.06, pal.Wainscot, MATS[pal.WainscotMat or "Wood"], "Wainscot", nil, tile)
				band(side, y0 + wainH, y0 + wainH + 0.3, 0.14, 0.12, WHITE, Enum.Material.Wood, "ChairRail")
			end
			-- baseboard and crown molding
			band(side, y0, y0 + 0.75, 0.16, 0.18, WHITE, Enum.Material.Wood, "Baseboard")
			band(side, y0 + 12.45, y0 + 13, 0.3, 0.06, WHITE, Enum.Material.Wood, "Crown")

			-- framed pictures in the widest gap between openings
			if artLeft > 0 then
				for _, line in side.Lines do
					local s0, s1 = math.max(side.A0, line.A0) + 1.5, math.min(side.A1, line.A1) - 1.5
					local cuts = { s0 }
					local sorted = table.clone(line.Openings)
					table.sort(sorted, function(a, b)
						return a.at < b.at
					end)
					for _, op in sorted do
						table.insert(cuts, op.at - op.w / 2 - 1.2)
						table.insert(cuts, op.at + op.w / 2 + 1.2)
					end
					table.insert(cuts, s1)
					local bestA, bestLen = nil, 5
					for i = 1, #cuts - 1, 2 do
						local a, b = math.max(cuts[i], s0), math.min(cuts[i + 1], s1)
						if b - a > bestLen then
							bestA, bestLen = a, b - a
						end
					end
					local reserved = false
					if bestA then
						local c0 = bestA + bestLen / 2
						local px = side.AlongX and c0 or side.Fixed
						local pz = side.AlongX and side.Fixed or c0
						for _, span in L.NoArt or {} do
							if span[1] == r0Floor and px >= span[2] and px <= span[3] and pz >= span[4] and pz <= span[5] then
								reserved = true
							end
						end
					end
					if bestA and artLeft > 0 and not reserved then
						artLeft -= 1
						local c = bestA + bestLen / 2
						local w, h = math.min(bestLen - 1, 3 + rng:NextNumber() * 2), 2.4 + rng:NextNumber() * 1.2
						local face = side.Fixed + side.Inward * (line.Offset + 0.08)
						local cy = y0 + 7.2
						local function art(nm, along0, along1, yb, yt, depth, color, mat)
							local a, b
							if side.AlongX then
								a = V(along0, yb, face)
								b = V(along1, yt, face + side.Inward * depth)
							else
								a = V(face, yb, along0)
								b = V(face + side.Inward * depth, yt, along1)
							end
							return B.box(folder, nm, a, b, color, mat, { CanCollide = false, CanQuery = false })
						end
						art("PictureFrame", c - w / 2 - 0.25, c + w / 2 + 0.25, cy - h / 2 - 0.25, cy + h / 2 + 0.25, 0.14, Color3.fromRGB(60, 42, 30), Enum.Material.Wood)
						art("Mat", c - w / 2, c + w / 2, cy - h / 2, cy + h / 2, 0.17, Color3.fromRGB(236, 232, 222), Enum.Material.SmoothPlastic)
						art("Canvas", c - w / 2 + 0.35, c + w / 2 - 0.35, cy - h / 2 + 0.35, cy + h / 2 - 0.35, 0.19, ART_COLORS[rng:NextInteger(1, #ART_COLORS)], Enum.Material.Fabric)
					end
				end
			end

			-- curtains on exterior windows
			if pal.Curtain then
				for _, line in side.Lines do
					if line.Offset < 0.45 then
						continue
					end
					for _, op in line.Openings do
						if op.kind ~= "window" or op.at < side.A0 or op.at > side.A1 then
							continue
						end
						local face = side.Fixed + side.Inward * (line.Offset + 0.35)
						local top = y0 + (op.bottom or 0) + op.h + 0.9
						local bottom = y0 + (op.bottom or 0) - 0.8
						local function piece(nm, along0, along1, yb, yt, depth, color, mat)
							local a, b
							if side.AlongX then
								a = V(along0, yb, face)
								b = V(along1, yt, face + side.Inward * depth)
							else
								a = V(face, yb, along0)
								b = V(face + side.Inward * depth, yt, along1)
							end
							return B.box(folder, nm, a, b, color, mat, { CanCollide = false, CanQuery = false })
						end
						piece("CurtainRod", op.at - op.w / 2 - 1.6, op.at + op.w / 2 + 1.6, top, top + 0.18, 0.18, Color3.fromRGB(60, 50, 40), Enum.Material.Metal)
						local sway = op.open == true
						for sgn = -1, 1, 2 do
							-- each panel covers the window's edge and hangs past the frame
							local c0 = sgn < 0 and op.at - op.w / 2 - 1.4 or op.at + op.w / 2 - 0.6
							local c1 = c0 + 2
							local curtain = piece("Curtain", c0, c1, bottom, top, 0.14, pal.Curtain, Enum.Material.Fabric)
							for k = 0, 2 do
								local fx = c0 + 0.3 + k * 0.6
								piece("CurtainFold", fx, fx + 0.12, bottom, top, 0.22, pal.Curtain:Lerp(Color3.new(), 0.18), Enum.Material.Fabric)
							end
							if sway then
								CollectionService:AddTag(curtain, "Sway")
								curtain:SetAttribute("Pivot", V(curtain.Position.X, top, curtain.Position.Z))
							end
						end
					end
				end
			end
		end
	end
	return folder
end

return Finish
