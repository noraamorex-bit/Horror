--[[
	Depth — removes z-fighting from the built level.

	Two boxes whose faces lie in the same plane, facing the same way and overlapping, flicker
	against each other on screen (the "glitchy stripes" on walls, floors and trim). After the
	level is built this pass finds every such pair among the axis-aligned blocks and pulls the
	smaller face (the trim, the rug, the panel) a hair outward, so one surface always wins.

	Faces that look identical (same colour and material, no textures) are left alone: their
	fighting can't be seen. Moving and animated parts (doors, characters) are skipped.
]]

local Depth = {}

local PLANE_TOL = 0.025 -- faces this close together fight
local PUSH = 0.03 -- how far the smaller face is pulled out
local MIN_OVERLAP = 0.04

local AXES = { "X", "Y", "Z" }

local function hasSurfaceDetail(p: BasePart): boolean
	for _, c in p:GetChildren() do
		if c:IsA("Decal") or c:IsA("SurfaceGui") or c:IsA("DataModelMesh") then
			return true
		end
	end
	return false
end

local function hasMesh(p: BasePart): boolean
	for _, c in p:GetChildren() do
		if c:IsA("DataModelMesh") then
			return true
		end
	end
	return false
end

local function skipModel(p: Instance): boolean
	local m = p.Parent
	while m and not m:IsA("Workspace") do
		if m:IsA("Model") then
			if m:FindFirstChildOfClass("Humanoid") or string.sub(m.Name, 1, 5) == "Door_" then
				return true
			end
		end
		m = m.Parent
	end
	return false
end

-- world axis (1..3) and sign that a local direction points along, or nil if it's tilted
local function worldAxis(v: Vector3): (number?, number)
	local x, y, z = math.abs(v.X), math.abs(v.Y), math.abs(v.Z)
	if x > 0.999 then
		return 1, 0
	elseif y > 0.999 then
		return 2, 0
	elseif z > 0.999 then
		return 3, 0
	end
	return nil, 0
end

type Box = {
	Part: BasePart,
	Center: { number },
	Half: { number },
	LocalOf: { number }, -- world axis -> local axis (1 = X, 2 = Y, 3 = Z)
	Look: string,
}

local function describe(p: BasePart): Box?
	local cf = p.CFrame
	local ax = worldAxis(cf.RightVector)
	local ay = worldAxis(cf.UpVector)
	local az = worldAxis(cf.LookVector)
	if not ax or not ay or not az or ax == ay or ay == az or ax == az then
		return nil
	end
	local size = p.Size
	local localSize = { size.X, size.Y, size.Z }
	local half = { 0, 0, 0 }
	local localOf = { 0, 0, 0 }
	half[ax] = localSize[1] / 2
	localOf[ax] = 1
	half[ay] = localSize[2] / 2
	localOf[ay] = 2
	half[az] = localSize[3] / 2
	localOf[az] = 3
	local pos = cf.Position
	local look = hasSurfaceDetail(p) and "detail" or string.format("%d,%d,%d|%s|%.2f", math.floor(p.Color.R * 255 + 0.5), math.floor(p.Color.G * 255 + 0.5), math.floor(p.Color.B * 255 + 0.5), p.Material.Name, p.Transparency)
	for _, c in p:GetChildren() do
		if c:IsA("Texture") then
			look = "detail"
		end
	end
	return { Part = p, Center = { pos.X, pos.Y, pos.Z }, Half = half, LocalOf = localOf, Look = look }
end

local function collect(root: Instance): { Box }
	local boxes = {}
	for _, d in root:GetDescendants() do
		if d:IsA("Part") and d.Shape == Enum.PartType.Block and d.Anchored and d.Transparency < 0.98 and not hasMesh(d) and not skipModel(d) then
			local b = describe(d)
			if b then
				table.insert(boxes, b)
			end
		end
	end
	return boxes
end

-- one pass: returns the number of faces pulled out
local function pass(root: Instance, dryRun: boolean?): (number, { any })
	local boxes = collect(root)
	local buckets = {}
	local faces = {}
	for bi, b in boxes do
		for a = 1, 3 do
			for _, s in { -1, 1 } do
				local c = b.Center[a] + s * b.Half[a]
				local key = math.floor(c / PLANE_TOL + 0.5)
				local f = { Box = bi, Axis = a, Sign = s, C = c, Key = key }
				table.insert(faces, f)
				local k = a * s .. ":" .. key
				local list = buckets[k]
				if not list then
					list = {}
					buckets[k] = list
				end
				table.insert(list, f)
			end
		end
	end
	local pushed = {}
	local found = {}
	local count = 0
	for _, f in faces do
		local b = boxes[f.Box]
		local a = f.Axis
		local t1, t2 = a % 3 + 1, (a + 1) % 3 + 1
		for dk = 0, 1 do
			local list = buckets[a * f.Sign .. ":" .. (f.Key + dk)]
			if not list then
				continue
			end
			for _, g in list do
				if g.Box <= f.Box and dk == 0 then
					continue
				end
				if g.Box == f.Box or math.abs(g.C - f.C) > PLANE_TOL then
					continue
				end
				local o = boxes[g.Box]
				if o.Look == b.Look and b.Look ~= "detail" then
					continue
				end
				local ov1 = math.min(b.Center[t1] + b.Half[t1], o.Center[t1] + o.Half[t1]) - math.max(b.Center[t1] - b.Half[t1], o.Center[t1] - o.Half[t1])
				local ov2 = math.min(b.Center[t2] + b.Half[t2], o.Center[t2] + o.Half[t2]) - math.max(b.Center[t2] - b.Half[t2], o.Center[t2] - o.Half[t2])
				if ov1 < MIN_OVERLAP or ov2 < MIN_OVERLAP then
					continue
				end
				-- the smaller face moves (ties: the thinner box)
				local areaB = b.Half[t1] * b.Half[t2]
				local areaO = o.Half[t1] * o.Half[t2]
				local mover, face = b, f
				if areaO < areaB or (areaO == areaB and o.Half[a] < b.Half[a]) then
					mover, face = o, g
				end
				local id = tostring(mover.Part) .. tostring(mover) .. face.Axis .. face.Sign
				if pushed[id] then
					continue
				end
				pushed[id] = true
				count += 1
				table.insert(found, { mover.Part, (mover == b) and o.Part or b.Part, AXES[a] })
				if not dryRun then
					local p = mover.Part
					local la = mover.LocalOf[a]
					local grow = Vector3.new(la == 1 and PUSH or 0, la == 2 and PUSH or 0, la == 3 and PUSH or 0)
					local shift = Vector3.new(a == 1 and 1 or 0, a == 2 and 1 or 0, a == 3 and 1 or 0) * face.Sign * PUSH / 2
					local cf = p.CFrame
					p.Size += grow
					p.CFrame = cf + shift
				end
			end
		end
	end
	return count, found
end

-- returns how many faces were separated
function Depth.resolve(root: Instance): number
	local total = 0
	for _ = 1, 8 do
		local n = pass(root)
		total += n
		if n == 0 then
			break
		end
	end
	return total
end

-- for tests: the fighting pairs that are left
function Depth.find(root: Instance): (number, { any })
	return pass(root, true)
end

return Depth
