--[[
	Exterior — the lot around 14 Alder Lane: lawn, porch, driveway, street, the gray van,
	the fenced back yard, the phone junction box, and Mrs. Okafor's house next door.
]]

local Exterior = {}

local V = Vector3.new

function Exterior.build(ctx, root: Instance, refs)
	local B = ctx.Builder
	local C, M = B.C, B.M
	local L = ctx.Layout

	local f = Instance.new("Folder")
	f.Name = "Exterior"
	f.Parent = root

	local function box(name, x0, y0, z0, x1, y1, z1, color, mat, extra)
		return B.box(f, name, V(x0, y0, z0), V(x1, y1, z1), color, mat, extra)
	end

	local GRASS = Color3.fromRGB(52, 66, 44)
	local grass = Enum.Material.Grass

	-- lawn with a hole for the house footprint (so it never pokes into the basement)
	B.slab(f, "Lawn", -260, 260, -62, 200, 0.5, 3, { { -40.6, 66.6, -30.6, 30.6 }, { 94, 131, -31, 1 } }, GRASS, grass)
	box("Sidewalk", -260, -2.5, -68, 260, 0.6, -62, Color3.fromRGB(135, 135, 130), M.Concrete)
	box("Street", -260, -2.5, -96, 260, 0.45, -68, Color3.fromRGB(38, 38, 42), M.Asphalt)
	box("Curb", -260, -2.5, -96.5, 260, 0.7, -96, Color3.fromRGB(135, 135, 130), M.Concrete)
	B.slab(f, "LawnAcross", -260, 260, -200, -96.5, 0.5, 3, {}, GRASS, grass)
	for x = -250, 250, 16 do
		box("LaneMark", x, 0.45, -82.3, x + 8, 0.5, -81.7, Color3.fromRGB(200, 180, 90), M.Plastic, { CanCollide = false })
	end

	-- porch, steps, walkway, driveway
	box("Porch", -5, 0, -38, 9, 1, -30.5, Color3.fromRGB(120, 110, 100), M.Wood)
	box("PorchStep", -2, 0, -40, 6, 0.75, -38, Color3.fromRGB(120, 110, 100), M.Wood)
	box("Walk", 0, 0, -62, 4, 0.6, -40, Color3.fromRGB(135, 135, 130), M.Concrete)
	box("PorchRoof", -6, 12.5, -39, 10, 13, -30.5, C.Roof, M.Roof)
	for _, x in { -5.5, 9.5 } do
		box("PorchPost", x - 0.3, 1, -38.6, x + 0.3, 12.5, -38, C.Trim, M.Wood)
	end
	local porchLamp = B.block(f, "PorchLamp", V(-1, 8, -30.9), V(0.8, 1.2, 0.6), Color3.fromRGB(255, 230, 180), Enum.Material.Neon)
	local pl = Instance.new("PointLight")
	pl.Range = 18
	pl.Brightness = 0.7
	pl.Color = Color3.fromRGB(255, 210, 150)
	pl.Parent = porchLamp
	ctx.Power.onChanged(function(on)
		pl.Enabled = on
		porchLamp.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end, porchLamp)

	box("Driveway", 43, 0, -62, 63, 1, -30.5, Color3.fromRGB(95, 95, 95), M.Concrete)
	box("BackStep", -24, 0, 30.5, -16, 0.75, 34, Color3.fromRGB(120, 110, 100), M.Wood)
	box("SideStep", 66.5, 0, -5, 69.5, 0.75, 1, Color3.fromRGB(120, 110, 100), M.Concrete)
	box("Mailbox", 6, 0.5, -63.5, 6.4, 4, -63.1, C.Black, M.Metal)
	box("MailboxBox", 5.4, 4, -64.2, 7, 5.2, -62.4, C.Black, M.Metal)

	-- fenced back yard
	local fenceColor = Color3.fromRGB(110, 95, 75)
	box("Fence", -60, 0.5, 30, -59.6, 6.5, 80, fenceColor, M.Planks)
	box("Fence", -60, 0.5, 79.6, 70, 6.5, 80, fenceColor, M.Planks)
	box("Fence", 69.6, 0.5, 6, 70, 6.5, 80, fenceColor, M.Planks)
	box("Fence", -60, 0.5, 30, -40.5, 6.5, 30.4, fenceColor, M.Planks)
	box("Fence", 66.5, 0.5, 6, 70, 6.5, 6.4, fenceColor, M.Planks)
	box("Shed", 45, 0.5, 62, 62, 10, 76, Color3.fromRGB(100, 90, 80), M.Planks)
	box("Swing", -30, 0.5, 60, -29.6, 9, 60.4, C.Steel, M.Metal)
	box("Swing", -22, 0.5, 60, -21.6, 9, 60.4, C.Steel, M.Metal)
	box("SwingTop", -30, 9, 60, -21.6, 9.4, 60.4, C.Steel, M.Metal)

	-- trees and hedges
	for _, t in { { -55, -50 }, { -80, 10 }, { -45, 70 }, { 85, 40 }, { 30, 95 }, { -110, -40 }, { 150, -45 }, { -140, 60 }, { 75, -50 } } do
		B.tree(f, V(t[1], 0.5, t[2]), 20 + (t[1] % 7))
	end
	for x = -38, -8, 6 do
		box("Hedge", x, 0.5, -34, x + 5, 3.5, -31, Color3.fromRGB(40, 60, 35), grass)
	end

	-- street lamp
	box("LampPole", 21.7, 0.5, -64.3, 22.3, 18, -63.7, Color3.fromRGB(60, 60, 62), M.Metal)
	local head = box("LampHead", 20, 18, -65, 24, 18.8, -63, Color3.fromRGB(255, 220, 160), Enum.Material.Neon)
	local sl = Instance.new("SpotLight")
	sl.Face = Enum.NormalId.Bottom
	sl.Range = 45
	sl.Angle = 110
	sl.Brightness = 2.2
	sl.Color = Color3.fromRGB(255, 200, 140)
	sl.Parent = head

	-- the gray van, parked a little too long
	local vp = L.Outside.Van
	local van = Instance.new("Model")
	van.Name = "GrayVan"
	van.Parent = f
	B.box(van, "VanBody", vp + V(-8, 1.5, -3.5), vp + V(8, 8.5, 3.5), Color3.fromRGB(125, 128, 130), M.Metal)
	B.box(van, "VanHood", vp + V(8, 1.5, -3.5), vp + V(11, 5.5, 3.5), Color3.fromRGB(125, 128, 130), M.Metal)
	B.box(van, "Windshield", vp + V(8, 5.5, -3.2), vp + V(8.3, 8, 3.2), Color3.fromRGB(30, 35, 40), M.Glass)
	for _, w in { { -5, -3.6 }, { 6, -3.6 }, { -5, 3.6 }, { 6, 3.6 } } do
		B.cylinder(van, "Wheel", vp + V(w[1], 1.5, w[2]), 1, 3, C.Black, M.Plastic, CFrame.new())
	end
	refs.Van = van

	-- phone junction box on the garage's east wall
	local jb = L.Outside.JunctionBox
	local jm = Instance.new("Model")
	jm.Name = "JunctionBox"
	jm.Parent = f
	B.box(jm, "Box", V(66.5, jb.Y - 1.2, jb.Z - 1), V(67.2, jb.Y + 1.2, jb.Z + 1), Color3.fromRGB(150, 150, 145), M.Metal)
	local wire = B.box(jm, "Wire", V(66.7, jb.Y + 1.2, jb.Z - 0.1), V(66.9, 15, jb.Z + 0.1), C.Black, M.Plastic, { CanCollide = false })
	local cut = B.box(jm, "CutWire", V(66.7, jb.Y + 1.2, jb.Z - 0.1), V(66.9, jb.Y + 3, jb.Z + 0.1), C.Black, M.Plastic, { CanCollide = false, Transparency = 1 })
	local door = B.box(jm, "BoxDoor", V(67.2, jb.Y - 1.2, jb.Z - 1), V(67.35, jb.Y + 1.2, jb.Z + 1), Color3.fromRGB(160, 160, 155), M.Metal)
	local openCF = CFrame.new(V(67.2, jb.Y, jb.Z - 1)) * CFrame.Angles(0, math.rad(-100), 0) * CFrame.new(0.07, 0, 1)
	ctx.Escape.setupJunctionBox(jm, door, openCF, wire, cut)

	---------------------------------------------------------------------------
	-- Mrs. Okafor's house (x 95..130)
	---------------------------------------------------------------------------
	local nx0, nx1, nz0, nz1 = 95, 130, -30, 0
	local ncol = Color3.fromRGB(150, 140, 120)
	box("NFloor", nx0, -1, nz0, nx1, 1, nz1, Color3.fromRGB(130, 100, 70), M.Planks)
	box("NWall", nx0, 1, nz0 - 0.5, 107.5, 13, nz0, ncol, M.Siding)
	box("NWall", 112.5, 1, nz0 - 0.5, nx1, 13, nz0, ncol, M.Siding)
	box("NWall", 107.5, 10, nz0 - 0.5, 112.5, 13, nz0, ncol, M.Siding)
	box("NWall", nx0, 1, nz1, nx1, 13, nz1 + 0.5, ncol, M.Siding)
	box("NWall", nx0 - 0.5, 1, nz0, nx0, 13, nz1, ncol, M.Siding)
	box("NWall", nx1, 1, nz0, nx1 + 0.5, 13, nz1, ncol, M.Siding)
	box("NCeiling", nx0, 13, nz0, nx1, 13.5, nz1, C.Drywall, M.Wall)
	B.part(f, { ClassName = "WedgePart", Name = "NRoof", Size = V(37, 8, 16), CFrame = CFrame.new((nx0 + nx1) / 2, 17.5, nz0 + 7.5) * CFrame.Angles(0, math.pi, 0), Color = C.Roof, Material = M.Roof })
	B.part(f, { ClassName = "WedgePart", Name = "NRoof", Size = V(37, 8, 16), CFrame = CFrame.new((nx0 + nx1) / 2, 17.5, nz1 - 7.5), Color = C.Roof, Material = M.Roof })
	box("NPorch", 102, 0, -38, 118, 1.2, nz0 - 0.5, Color3.fromRGB(120, 110, 100), M.Wood)
	for _, wx in { 99, 122 } do
		box("NWindow", wx, 5, nz0 - 0.6, wx + 5, 9, nz0 - 0.45, Color3.fromRGB(255, 210, 140), Enum.Material.Neon)
	end
	local ndoor = box("NeighborDoor", 107.5, 1, nz0 - 0.45, 112.5, 10, nz0 - 0.1, Color3.fromRGB(40, 70, 60), M.Wood)
	local nlamp = B.block(f, "NPorchLight", V(114, 8, nz0 - 0.8), V(0.8, 1.2, 0.6), Color3.fromRGB(255, 230, 180), Enum.Material.Neon)
	local npl = Instance.new("PointLight")
	npl.Range = 24
	npl.Brightness = 1.2
	npl.Color = Color3.fromRGB(255, 210, 150)
	npl.Parent = nlamp
	ctx.Escape.setupNeighbor(ndoor)
	-- inside: warm and safe
	local lamp = B.block(f, "NLamp", V(112, 12.5, -15), V(1.5, 0.6, 1.5), Color3.fromRGB(255, 230, 190), Enum.Material.Neon)
	local il = Instance.new("PointLight")
	il.Range = 30
	il.Brightness = 1.2
	il.Color = Color3.fromRGB(255, 215, 170)
	il.Parent = lamp
	box("NCouch", 100, 1, -8, 112, 3.5, -4, Color3.fromRGB(130, 60, 60), M.Fabric)
	box("NRug", 100, 1, -24, 120, 1.06, -10, Color3.fromRGB(150, 110, 60), M.Fabric, { CanCollide = false })
	box("NFence", 90, 0.5, -30, 90.4, 4, 20, fenceColor, M.Planks)

	-- invisible world bounds
	for _, b in { { -262, -200, -260, 200 }, { 260, -200, 262, 200 }, { -262, -202, 262, -200 }, { -262, 200, 262, 202 } } do
		box("Bounds", b[1], -5, b[2], b[3], 80, b[4], C.Black, M.Plastic, { Transparency = 1 })
	end
	return refs
end

return Exterior
