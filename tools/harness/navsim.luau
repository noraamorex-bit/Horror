-- navsim: a wall-aware physical world for the harness.
--
-- After the house is built, Sim.install(H) indexes every BasePart and gives the harness:
--   workspace:Raycast            ray vs every part's oriented box (CanQuery / RespectCanCollide,
--                                CollisionGroup "Intruder" skips door leaves, filters honoured,
--                                a ray starting inside a part doesn't hit it: like Roblox)
--   workspace:GetPartBoundsInBox the parts whose bounding boxes overlap (like Roblox)
--   Humanoid:MoveTo              a walking body: his HumanoidRootPart is the only part that
--                                collides (2 x 2 studs, 3.9..5.9 above his feet); it slides
--                                along what it hits, floats HipHeight over the highest thing
--                                under it (so he really can end up on a table) and gives up
--                                after 8 s like Roblox's MoveTo
--   Model:PivotTo                moves the model's parts (doors swing, he gets teleported)
-- Sim.step(dt) moves every walking humanoid.
local Sim = {}
local H
local roblox
local V

local recs = {} -- static parts: arrays of numbers for speed
local dyn = {} -- part records re-read every query (doors, characters)
local BUCKET = 8
local buckets = {}
local stamp = 0
local seen = {}

local function key(ix, iz) return ix * 65536 + iz end

local function readPart(real)
	local cf = real.CFrame
	local size = real.Size
	local p = cf.Position
	local r0, r1, r2 = cf.RightVector, cf.UpVector, -cf.LookVector
	local rec = {
		real = real,
		px = p.X, py = p.Y, pz = p.Z,
		ax = { r0.X, r0.Y, r0.Z }, ay = { r1.X, r1.Y, r1.Z }, az = { r2.X, r2.Y, r2.Z },
		hx = size.X / 2, hy = size.Y / 2, hz = size.Z / 2,
		cf = cf, size = size,
	}
	-- AABB
	local ex = math.abs(r0.X) * rec.hx + math.abs(r1.X) * rec.hy + math.abs(r2.X) * rec.hz
	local ey = math.abs(r0.Y) * rec.hx + math.abs(r1.Y) * rec.hy + math.abs(r2.Y) * rec.hz
	local ez = math.abs(r0.Z) * rec.hx + math.abs(r1.Z) * rec.hy + math.abs(r2.Z) * rec.hz
	rec.minx, rec.maxx = p.X - ex, p.X + ex
	rec.miny, rec.maxy = p.Y - ey, p.Y + ey
	rec.minz, rec.maxz = p.Z - ez, p.Z + ez
	return rec
end

local function flags(rec, real)
	rec.collide = real.CanCollide
	local okq, q = pcall(function() return real.CanQuery end)
	rec.query = (not okq) or q
	local okg, g = pcall(function() return real.CollisionGroup end)
	rec.group = okg and g or "Default"
	rec.name = real.Name
end

local function isDynamic(real)
	local p = real.Parent
	while p do
		local okn, name = pcall(function() return p.Name end)
		if okn and type(name) == "string" and name:sub(1, 5) == "Door_" then return true end
		if p:FindFirstChildOfClass("Humanoid") then return true end
		p = p.Parent
	end
	return false
end

function Sim.index()
	recs, dyn, buckets = {}, {}, {}
	local root = H.unwrap(H.workspaceRoot)
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			local rec = readPart(d)
			flags(rec, d)
			rec.id = #recs + #dyn + 1
			d:SetAttribute("__sid", rec.id)
			if isDynamic(d) then
				table.insert(dyn, rec)
			else
				table.insert(recs, rec)
				local x0, x1 = math.floor(rec.minx / BUCKET), math.floor(rec.maxx / BUCKET)
				local z0, z1 = math.floor(rec.minz / BUCKET), math.floor(rec.maxz / BUCKET)
				if (x1 - x0 + 1) * (z1 - z0 + 1) > 20000 then
					rec.huge = true
					table.insert(dyn, rec) -- (the street, the ground plane: always checked)
					rec.static = true
				else
					for ix = x0, x1 do
						for iz = z0, z1 do
							local k = key(ix, iz)
							local b = buckets[k]
							if not b then b = {}; buckets[k] = b end
							table.insert(b, rec)
						end
					end
				end
			end
		end
	end
	return #recs, #dyn
end

-- a model's parts move (characters added after indexing, him)
function Sim.track(model)
	local real = H.unwrap(model)
	local list = real:IsA("BasePart") and { real } or real:GetDescendants()
	for _, d in list do
		if d:IsA("BasePart") then
			local rec = readPart(d)
			flags(rec, d)
			rec.id = 100000 + #dyn
			d:SetAttribute("__sid", rec.id)
			table.insert(dyn, rec)
		end
	end
	Sim.filterCache = {}
end

local function refresh(rec)
	if rec.static then return rec end
	local real = rec.real
	if not real.Parent then rec.gone = true return rec end
	local n = readPart(real)
	for k, v in n do rec[k] = v end
	return rec
end

-- filter: set of __sid that are excluded (or included)
Sim.filterCache = {}
local function descSet(real)
	local okp, pid = pcall(function() return real:GetAttribute("__pid") end)
	local k = okp and pid or nil
	if k and Sim.filterCache[k] then return Sim.filterCache[k] end
	local set = {}
	local all = real:GetDescendants()
	table.insert(all, real)
	for _, d in all do
		if d:IsA("BasePart") then
			local sid = d:GetAttribute("__sid")
			if sid then set[sid] = true end
		end
	end
	if k then Sim.filterCache[k] = set end
	return set
end
local function filterSet(list)
	if not list or #list == 0 then return nil end
	local set = {}
	for _, inst in list do
		local real = H.unwrap(inst)
		if real and typeof(real) == "Instance" then
			if real:IsA("BasePart") then
				local sid = real:GetAttribute("__sid")
				if sid then set[sid] = true end
			else
				for sid in descSet(real) do set[sid] = true end
			end
		end
	end
	return set
end

local function usable(rec, params, set, include)
	if rec.gone then return false end
	if params and params.RespectCanCollide then
		if not rec.collide then return false end
	elseif not rec.query then
		return false
	end
	if params and params.CollisionGroup == "Intruder" and (rec.group == "Doors" or rec.group == "Intruder") then
		return false
	end
	if set then
		local inSet = set[rec.id] == true
		if include then return inSet end
		return not inSet
	end
	return not include
end

-- ray (o + d*t, t in [0,1]) vs oriented box; returns tEnter and normal axis or nil
local function rayBox(rec, ox, oy, oz, dx, dy, dz)
	local rx, ry, rz = ox - rec.px, oy - rec.py, oz - rec.pz
	local tmin, tmax = -math.huge, math.huge
	local nAxis, nSign = 0, 0
	local axes = { rec.ax, rec.ay, rec.az }
	local hs = { rec.hx, rec.hy, rec.hz }
	for i = 1, 3 do
		local a = axes[i]
		local lo = rx * a[1] + ry * a[2] + rz * a[3]
		local ld = dx * a[1] + dy * a[2] + dz * a[3]
		local h = hs[i]
		if math.abs(ld) < 1e-9 then
			if lo < -h or lo > h then return nil end
		else
			local t1, t2 = (-h - lo) / ld, (h - lo) / ld
			local s = -1
			if t1 > t2 then t1, t2 = t2, t1; s = 1 end
			if t1 > tmin then tmin = t1; nAxis = i; nSign = s * (ld > 0 and 1 or -1) * -1 end
			if t2 < tmax then tmax = t2 end
			if tmin > tmax then return nil end
		end
	end
	if tmin < 0 or tmin > 1 then return nil end -- (starting inside: not hit, like Roblox)
	local a = axes[nAxis]
	-- outward normal of the face entered: opposite the ray along that axis
	local ld = dx * a[1] + dy * a[2] + dz * a[3]
	local sgn = ld > 0 and -1 or 1
	return tmin, a[1] * sgn, a[2] * sgn, a[3] * sgn
end

Sim.rays = 0
function Sim.raycast(o, d, params)
	Sim.rays += 1
	local set = params and filterSet(params.FilterDescendantsInstances)
	local include = params and params.FilterType == roblox.Enum.RaycastFilterType.Include
	local ox, oy, oz, dx, dy, dz = o.X, o.Y, o.Z, d.X, d.Y, d.Z
	local best, bt, bnx, bny, bnz = nil, math.huge, 0, 0, 0
	local function test(rec)
		if usable(rec, params, set, include) then
			local t, nx, ny, nz = rayBox(rec, ox, oy, oz, dx, dy, dz)
			if t and t < bt then best, bt, bnx, bny, bnz = rec, t, nx, ny, nz end
		end
	end
	stamp += 1
	-- buckets along the ray
	local len = math.sqrt(dx * dx + dz * dz)
	local n = math.max(1, math.ceil(len / (BUCKET * 0.5)))
	for i = 0, n do
		local t = i / n
		local bx, bz = math.floor((ox + dx * t) / BUCKET), math.floor((oz + dz * t) / BUCKET)
		for ddx = -1, 1 do
			for ddz = -1, 1 do
				local b = buckets[key(bx + ddx, bz + ddz)]
				if b then
					for _, rec in b do
						if seen[rec] ~= stamp then
							seen[rec] = stamp
							test(rec)
						end
					end
				end
			end
		end
	end
	for _, rec in dyn do
		refresh(rec)
		test(rec)
	end
	if not best then return nil end
	return {
		Instance = H.wrap(best.real),
		Position = V(ox + dx * bt, oy + dy * bt, oz + dz * bt),
		Normal = V(bnx, bny, bnz),
		Distance = math.sqrt(dx * dx + dy * dy + dz * dz) * bt,
		Material = roblox.Enum.Material.Plastic,
	}
end

local function candidates(minx, maxx, minz, maxz, fn)
	stamp += 1
	for ix = math.floor(minx / BUCKET), math.floor(maxx / BUCKET) do
		for iz = math.floor(minz / BUCKET), math.floor(maxz / BUCKET) do
			local b = buckets[key(ix, iz)]
			if b then
				for _, rec in b do
					if seen[rec] ~= stamp then
						seen[rec] = stamp
						fn(rec)
					end
				end
			end
		end
	end
	for _, rec in dyn do
		refresh(rec)
		fn(rec)
	end
end

function Sim.boundsInBox(cf, size, params)
	local set = params and filterSet(params.FilterDescendantsInstances)
	local include = params and params.FilterType == roblox.Enum.RaycastFilterType.Include
	local c = cf.Position
	local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	local out = {}
	candidates(c.X - hx, c.X + hx, c.Z - hz, c.Z + hz, function(rec)
		if rec.maxx >= c.X - hx and rec.minx <= c.X + hx and rec.maxy >= c.Y - hy and rec.miny <= c.Y + hy
			and rec.maxz >= c.Z - hz and rec.minz <= c.Z + hz and usable(rec, params, set, include) then
			table.insert(out, { CFrame = rec.cf, Size = rec.size, Name = rec.name })
		end
	end)
	return out
end

-- exact: does the axis-aligned box hit anything he collides with (except `skip` set)?
local NavGrid
function Sim.bodyBlocked(c, h, skip)
	local hit = nil
	candidates(c.X - h.X, c.X + h.X, c.Z - h.Z, c.Z + h.Z, function(rec)
		if hit or rec.gone or not rec.collide or rec.group == "Doors" or rec.group == "Intruder" or (skip and skip[rec.id]) then return end
		if rec.maxx >= c.X - h.X and rec.minx <= c.X + h.X and rec.maxy >= c.Y - h.Y and rec.miny <= c.Y + h.Y
			and rec.maxz >= c.Z - h.Z and rec.minz <= c.Z + h.Z then
			if NavGrid.boxHitsPart(c, h, rec.cf, rec.size) then hit = rec end
		end
	end)
	return hit
end

---------------------------------------------------------------------------
-- Walking humanoids
---------------------------------------------------------------------------
Sim.walkers = {} -- humanoid proxy -> state
local walkerOf = {}

local function modelOf(hum)
	return hum.Parent
end

function Sim.addWalker(model, opts)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	local w = { Model = model, Hum = hum, Root = root, Target = nil, Since = 0, Vel = V(0, 0, 0),
		RootY = opts.RootY or 4.9, Skip = filterSet({ model }), Log = {}, Climbs = 0, Blocked = 0 }
	table.insert(Sim.walkers, w)
	walkerOf[H.unwrap(root)] = w
	return w
end

function Sim.velocityOf(p)
	local real = H.unwrap(p)
	for _, w in Sim.walkers do
		if H.unwrap(w.Root) == real then return w.Vel end
	end
	return nil
end

local function groundUnder(x, y, z, w)
	-- the highest thing under his footprint (centre and corners), down to a step below his feet
	local best = nil
	local params = { RespectCanCollide = true, CollisionGroup = "Intruder", FilterDescendantsInstances = { w.Model }, FilterType = roblox.Enum.RaycastFilterType.Exclude }
	for _, off in { { 0, 0 }, { 0.8, 0.8 }, { -0.8, 0.8 }, { 0.8, -0.8 }, { -0.8, -0.8 } } do
		local hit = Sim.raycast(V(x + off[1], y - 1.05, z + off[2]), V(0, -(w.RootY - 1 + 3.5), 0), params)
		if hit and (not best or hit.Position.Y > best) then best = hit.Position.Y end
	end
	return best
end

function Sim.step(dt)
	for _, w in Sim.walkers do
		local root = H.unwrap(w.Root)
		if root.Anchored then
			w.Vel = V(0, 0, 0)
		else
			local cf = root.CFrame
			local p = cf.Position
			local speed = w.Hum.WalkSpeed
			local moved = V(0, 0, 0)
			if w.Target then
				w.Since += dt
				local to = V(w.Target.X - p.X, 0, w.Target.Z - p.Z)
				if to.Magnitude < 0.25 or w.Since > 8 then
					w.Target = nil
				else
					local stepLen = math.min(speed * dt, to.Magnitude)
					local dir = to.Unit
					local half = V(1, 1, 1)
					local function free(at)
						return not Sim.bodyBlocked(at, half, w.Skip)
					end
					local tries = { dir * stepLen, V(dir.X * stepLen, 0, 0), V(0, 0, dir.Z * stepLen) }
					for _, mv in tries do
						if mv.Magnitude > 1e-4 and free(p + mv) then
							moved = mv
							break
						end
					end
					if moved.Magnitude < 1e-4 then
						w.Blocked += dt
						local hit = Sim.bodyBlocked(p + dir * stepLen, V(1, 1, 1), w.Skip)
						w.LastBlock = ("at %s toward %s by %s"):format(tostring(p), tostring(w.Target), hit and (hit.name .. " " .. tostring(hit.cf.Position) .. " size " .. tostring(hit.size)) or "?")
					end
				end
			end
			local np = p + moved
			-- float over the ground
			local g = groundUnder(np.X, np.Y, np.Z, w)
			local ny = np.Y
			if g then
				local want = g + w.RootY
				if want > ny + 1.3 then w.Climbs += 1 end
				ny = want > ny and math.min(want, ny + 30 * dt) or math.max(want, ny - 40 * dt)
			else
				ny -= 40 * dt
			end
			np = V(np.X, ny, np.Z)
			local look = moved.Magnitude > 1e-3 and V(moved.X, 0, moved.Z).Unit or cf.LookVector
			look = V(look.X, 0, look.Z)
			if look.Magnitude < 1e-3 then look = V(0, 0, -1) end
			local ncf = roblox.CFrame.lookAt(np, np + look.Unit)
			-- move the whole model with the root
			local delta = ncf * cf:Inverse()
			local model = H.unwrap(w.Model)
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") then d.CFrame = delta * d.CFrame end
			end
			w.Vel = moved / dt
		end
	end
end

function Sim.install(h)
	H = h
	roblox = H.roblox
	V = roblox.Vector3.new
	NavGrid = H.load("Server/Intruder/NavGrid")
	H.raycast = Sim.raycast
	H.boundsInBox = Sim.boundsInBox
	H.velocityOf = Sim.velocityOf
	H.onMoveTo = function(hum, pos)
		for _, w in Sim.walkers do
			if w.Hum == hum or H.unwrap(w.Hum) == H.unwrap(hum) then
				w.Target = pos
				w.Since = 0
				return
			end
		end
	end
	H.onPivotTo = function(model, cf)
		local real = H.unwrap(model)
		local prim = real:IsA("Model") and (real.PrimaryPart or real:FindFirstChild("HumanoidRootPart")) or nil
		if not prim then return end
		local delta = cf * prim.CFrame:Inverse()
		for _, d in real:GetDescendants() do
			if d:IsA("BasePart") then d.CFrame = delta * d.CFrame end
		end
		for _, w in Sim.walkers do
			if H.unwrap(w.Model) == real then w.Target = nil; w.Vel = V(0, 0, 0) end
		end
	end
	return Sim.index()
end

-- survey the house with NavGrid, or load the survey saved by an earlier run (delete the cache
-- file after changing the house)
function Sim.navGrid(NavGrid, cachePath)
	local fs = require("@lune/fs")
	local serde = require("@lune/serde")
	if cachePath and fs.isFile(cachePath) then
		local raw = serde.decode("json", fs.readFile(cachePath))
		local function intKeys(t)
			local out = {}
			for k, v in t do out[tonumber(k)] = v end
			return out
		end
		local g = { X0 = raw.X0, Z0 = raw.Z0, NX = raw.NX, NZ = raw.NZ }
		for _, f in { "Ys", "Nbr", "Comp", "Edge", "NX_", "NY_", "NZ_" } do g[f] = intKeys(raw[f]) end
		NavGrid._import(g)
		return false
	end
	NavGrid.build({})
	if cachePath then
		local g = NavGrid._export()
		local out = { X0 = g.X0, Z0 = g.Z0, NX = g.NX, NZ = g.NZ }
		for _, f in { "Ys", "Nbr", "Comp", "Edge", "NX_", "NY_", "NZ_" } do
			local t = {}
			for k, v in g[f] do t[tostring(k)] = v end
			out[f] = t
		end
		fs.writeFile(cachePath, serde.encode("json", out))
	end
	return true
end

return Sim
