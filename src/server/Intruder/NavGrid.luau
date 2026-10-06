--[[
	NavGrid — the intruder's own map of where he can walk, measured from the real house.

	PathfindingService's navmesh is coarse: it loses narrow doorways, and with no path the old
	navigator walked him face-first into walls. So the house is surveyed once, on a 1-stud grid:

	• every column is probed straight down for the surfaces in it (floors, stairs, furniture tops),
	• a surface is standable if a box the size of his body (2.2 wide, 1.2 to 8 studs above the
	  surface) touches nothing he collides with: that keeps him off furniture, out of walls, and
	  a body's width away from every edge,
	• neighbouring standable surfaces within a step's height are linked (stairs are ramps).

	Then paths are A* on that grid, pulled taut into straight runs, so he walks the way a person
	would: through the middle of doorways and round the furniture, never into it.

	Only CanCollide parts in collision groups he collides with count (door leaves don't: he
	opens them on the way, see Navigator), and characters are ignored.

		NavGrid.build(exclude)                 -- surveys the house (yields; once is enough)
		NavGrid.ready()
		NavGrid.findPath(from, to)             -- { Vector3 } floor-level waypoints, or nil
		NavGrid.straight(from, to)             -- can he walk this in a straight line?
		NavGrid.nearest(pos, radius?)          -- the closest spot he can stand (floor level)
		NavGrid.randomNear(center, rMin, rMax) -- a spot near `center` he can walk straight to
]]

local NavGrid = {}

local V = Vector3.new
local CELL = 1
local STEP = 0.9 -- most a surface can rise or fall between neighbouring cells
local BODY = 1.1 -- half the width of the box that must be clear
local CLEAR_LOW, CLEAR_HIGH = 1.2, 8.0 -- the band above a surface that must be clear
local MAX_LEVELS = 8
local ROOT_ABOVE_FEET = 4.9 -- (his HumanoidRootPart centre above the floor: Rig.RootY)

-- the surveyed area: the house, the garage and the basement (outside, PathfindingService does)
NavGrid.Bounds = { X0 = -41, X1 = 67, Z0 = -31, Z1 = 31, Top = 27.5, Bottom = -16 }

local G: any = nil -- the built grid
local building = false

function NavGrid.ready(): boolean
	return G ~= nil
end

function NavGrid.reset()
	G = nil
end

---------------------------------------------------------------------------
-- Geometry
---------------------------------------------------------------------------

-- does an axis-aligned box (centre c, half extents h) overlap a part (as its oriented box)?
function NavGrid.boxHitsPart(c: Vector3, h: Vector3, cf: CFrame, size: Vector3): boolean
	local p = cf.Position
	local tx, ty, tz = p.X - c.X, p.Y - c.Y, p.Z - c.Z
	local hx, hy, hz = h.X, h.Y, h.Z
	local e0, e1, e2 = size.X / 2, size.Y / 2, size.Z / 2
	local R, U, L = cf.RightVector, cf.UpVector, cf.LookVector
	-- the part's axes as rows: a[i][j] = component j of part axis i
	local a00, a01, a02 = R.X, R.Y, R.Z
	local a10, a11, a12 = U.X, U.Y, U.Z
	local a20, a21, a22 = -L.X, -L.Y, -L.Z
	local abs = math.abs
	local EPS = 1e-3
	-- the box's own axes (world X, Y, Z)
	if abs(tx) > hx + e0 * abs(a00) + e1 * abs(a10) + e2 * abs(a20) - EPS then
		return false
	end
	if abs(ty) > hy + e0 * abs(a01) + e1 * abs(a11) + e2 * abs(a21) - EPS then
		return false
	end
	if abs(tz) > hz + e0 * abs(a02) + e1 * abs(a12) + e2 * abs(a22) - EPS then
		return false
	end
	-- the part's axes
	local axes = { { a00, a01, a02, e0 }, { a10, a11, a12, e1 }, { a20, a21, a22, e2 } }
	for _, ax in axes do
		local x, y, z = ax[1], ax[2], ax[3]
		if abs(tx * x + ty * y + tz * z) > hx * abs(x) + hy * abs(y) + hz * abs(z) + ax[4] - EPS then
			return false
		end
	end
	-- cross products of a world axis with a part axis
	local ex = { e0, e1, e2 }
	for i = 1, 3 do
		for j = 1, 3 do
			local px, py, pz = axes[j][1], axes[j][2], axes[j][3]
			local x, y, z
			if i == 1 then
				x, y, z = 0, -pz, py
			elseif i == 2 then
				x, y, z = pz, 0, -px
			else
				x, y, z = -py, px, 0
			end
			local len = math.sqrt(x * x + y * y + z * z)
			if len > 1e-4 then
				x, y, z = x / len, y / len, z / len
				local ra = hx * abs(x) + hy * abs(y) + hz * abs(z)
				local rb = 0
				for k = 1, 3 do
					rb += ex[k] * abs(axes[k][1] * x + axes[k][2] * y + axes[k][3] * z)
				end
				if abs(tx * x + ty * y + tz * z) > ra + rb - EPS then
					return false
				end
			end
		end
	end
	return true
end

local rayParams: RaycastParams? = nil
local overlapParams: OverlapParams? = nil

local function raycast(origin: Vector3, dir: Vector3, filter: { Instance }): RaycastResult?
	local rp = rayParams :: RaycastParams
	rp.FilterDescendantsInstances = filter
	return workspace:Raycast(origin, dir, rp)
end

-- anything he'd bump into inside this box?
local function boxBlocked(c: Vector3, h: Vector3): boolean
	local parts = workspace:GetPartBoundsInBox(CFrame.new(c), h * 2, overlapParams :: OverlapParams)
	for _, part in parts do
		if NavGrid.boxHitsPart(c, h, part.CFrame, part.Size) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------------
-- Survey
---------------------------------------------------------------------------
local function nodePos(id: number): Vector3
	return V(G.NX_[id], G.NY_[id], G.NZ_[id])
end
NavGrid._nodePos = function(id)
	return nodePos(id)
end
NavGrid._comp = function(id)
	return G.Comp[id]
end
NavGrid._nbr = function(id)
	return G.Nbr[id] or {}
end

-- `exclude`: things not to survey (characters, him). `budget`: seconds of work per frame.
function NavGrid.build(exclude: { Instance }?, budget: number?)
	if building then
		return
	end
	building = true
	local B = NavGrid.Bounds
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.RespectCanCollide = true
	pcall(function()
		rp.CollisionGroup = "Intruder"
	end)
	rayParams = rp
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = exclude or {}
	op.RespectCanCollide = true
	pcall(function()
		op.CollisionGroup = "Intruder"
	end)
	overlapParams = op

	local g = {
		X0 = B.X0,
		Z0 = B.Z0,
		NX = math.floor((B.X1 - B.X0) / CELL) + 1,
		NZ = math.floor((B.Z1 - B.Z0) / CELL) + 1,
		Ys = {}, -- col -> { surface y, ... } (only standable ones, highest first)
		Nbr = {}, -- node -> { node, ... }
		Comp = {}, -- node -> connected area id
		Edge = {}, -- node -> true when it has fewer than 8 neighbours (next to a wall or edge)
	}
	local half = V(BODY, (CLEAR_HIGH - CLEAR_LOW) / 2, BODY)
	local t0 = os.clock()
	local function breathe()
		if budget and os.clock() - t0 > budget then
			task.wait()
			t0 = os.clock()
		end
	end
	local base = exclude or {}
	for ix = 0, g.NX - 1 do
		for iz = 0, g.NZ - 1 do
			local x, z = g.X0 + ix * CELL, g.Z0 + iz * CELL
			local filter = table.clone(base)
			local ys = {}
			local above = math.huge -- (the last surface found, standable or not)
			for _ = 1, 24 do
				local hit = raycast(V(x, B.Top, z), V(0, B.Bottom - B.Top, 0), filter)
				if not hit then
					break
				end
				table.insert(filter, hit.Instance)
				local y = hit.Position.Y
				-- (a surface with something lying right on it, a rug, a stair tread over the
				-- ramp: the thing on top is the floor)
				local covered = above - y < CLEAR_LOW
				above = math.min(above, y)
				if hit.Normal.Y > 0.6 and not covered then
					if not boxBlocked(V(x, y + (CLEAR_LOW + CLEAR_HIGH) / 2, z), half) then
						if #ys < MAX_LEVELS then
							table.insert(ys, y)
						end
					end
				end
			end
			if #ys > 0 then
				g.Ys[ix * g.NZ + iz] = ys
			end
		end
		breathe()
	end

	-- links between neighbouring cells (diagonals only when both sides are open too)
	local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
	-- every level in a neighbouring column within a step of `y`, closest first
	local function levelsNear(ix: number, iz: number, y: number, maxDy: number): { number }
		local out = {}
		if ix < 0 or iz < 0 or ix >= g.NX or iz >= g.NZ then
			return out
		end
		local col = ix * g.NZ + iz
		local ys = g.Ys[col]
		if not ys then
			return out
		end
		for li, yy in ys do
			if math.abs(yy - y) <= maxDy then
				table.insert(out, col * MAX_LEVELS + li - 1)
			end
		end
		if #out > 1 then
			table.sort(out, function(a, b)
				return math.abs(ys[a % MAX_LEVELS + 1] - y) < math.abs(ys[b % MAX_LEVELS + 1] - y)
			end)
		end
		return out
	end
	for col, ys in g.Ys do
		local ix, iz = col // g.NZ, col % g.NZ
		for li, y in ys do
			local id = col * MAX_LEVELS + li - 1
			local list = {}
			local orth = {}
			for k = 1, 4 do
				local d = DIRS[k]
				local ns = levelsNear(ix + d[1], iz + d[2], y, STEP)
				orth[k] = #ns > 0
				for _, n in ns do
					table.insert(list, n)
				end
			end
			local count = 0
			for k = 1, 4 do
				if orth[k] then
					count += 1
				end
			end
			for k = 5, 8 do
				local d = DIRS[k]
				local a = d[1] > 0 and orth[1] or orth[2]
				local b = d[2] > 0 and orth[3] or orth[4]
				if a and b then
					local ns = levelsNear(ix + d[1], iz + d[2], y, STEP * 1.42)
					if #ns > 0 then
						count += 1
					end
					for _, n in ns do
						table.insert(list, n)
					end
				end
			end
			g.Nbr[id] = list
			if count < 8 then
				g.Edge[id] = true
			end
		end
		breathe()
	end
	-- node coordinates as plain numbers (A* reads them a lot)
	g.NX_, g.NY_, g.NZ_ = {}, {}, {}
	for col, ys in g.Ys do
		local ix, iz = col // g.NZ, col % g.NZ
		for li, y in ys do
			local id = col * MAX_LEVELS + li - 1
			g.NX_[id], g.NY_[id], g.NZ_[id] = g.X0 + ix * CELL, y, g.Z0 + iz * CELL
		end
	end
	-- (links go both ways)
	for id, list in g.Nbr do
		for _, n in list do
			local back = g.Nbr[n]
			if back and not table.find(back, id) then
				table.insert(back, id)
			end
		end
	end
	-- connected areas (a bed top is its own little island: nothing is ever routed to it)
	local comp = 0
	for id in g.Nbr do
		if not g.Comp[id] then
			comp += 1
			g.Comp[id] = comp
			local stack = { id }
			while #stack > 0 do
				local cur = table.remove(stack)
				for _, n in g.Nbr[cur] do
					if not g.Comp[n] then
						g.Comp[n] = comp
						table.insert(stack, n)
					end
				end
			end
		end
	end
	-- (found nothing at all: no house here, leave it to PathfindingService)
	G = next(g.Nbr) ~= nil and g or nil
	building = false
end

---------------------------------------------------------------------------
-- Queries
---------------------------------------------------------------------------

-- the node for a position: the standable surface under it (pos may be anywhere from the floor
-- to his root height above it), within `radius` studs sideways; optionally in one area only
local function snap(pos: Vector3, radius: number?, comp: number?): number?
	if not G then
		return nil
	end
	local r = math.ceil((radius or 3) / CELL)
	local cx = math.floor((pos.X - G.X0) / CELL + 0.5)
	local cz = math.floor((pos.Z - G.Z0) / CELL + 0.5)
	local best, bestScore = nil, math.huge
	for dx = -r, r do
		for dz = -r, r do
			local ix, iz = cx + dx, cz + dz
			if ix >= 0 and iz >= 0 and ix < G.NX and iz < G.NZ then
				local col = ix * G.NZ + iz
				local ys = G.Ys[col]
				if ys then
					local fx, fz = G.X0 + ix * CELL - pos.X, G.Z0 + iz * CELL - pos.Z
					local flat = math.sqrt(fx * fx + fz * fz)
					if flat <= (radius or 3) + 0.01 then
						for li, y in ys do
							local above = pos.Y - y -- (how far the position is above that surface)
							if above > -2 and above < 9.5 then
								local id = col * MAX_LEVELS + li - 1
								if not comp or G.Comp[id] == comp then
									local score = flat + math.abs(above - 3) * 0.15 + (G.Edge[id] and 0.3 or 0)
									if score < bestScore then
										best, bestScore = id, score
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return best
end
NavGrid._snap = snap

function NavGrid.nearest(pos: Vector3, radius: number?): Vector3?
	local id = snap(pos, radius or 4)
	return id and nodePos(id) or nil
end

-- the level in a column within `maxDy` of y (closest), or nil
local function levelAt(ix: number, iz: number, y: number, maxDy: number): number?
	if ix < 0 or iz < 0 or ix >= G.NX or iz >= G.NZ then
		return nil
	end
	local col = ix * G.NZ + iz
	local ys = G.Ys[col]
	if not ys then
		return nil
	end
	local best, bd = nil, maxDy
	for li, yy in ys do
		local d = math.abs(yy - y)
		if d <= bd then
			best, bd = yy, d
		end
	end
	return best
end

--[[
	Can his body travel the straight line (x0, z0) -> (x1, z1) starting from floor height y0?
	Every point on the line must sit inside a square of four standable cells at about the same
	height: each cell's clear box is 2.2 wide, so together they hold his 2-wide body wherever it
	is in the square (no clipping a door jamb or a table corner on the way past).
]]
local function clearLine(x0: number, z0: number, y0: number, x1: number, z1: number): boolean
	local dx, dz = x1 - x0, z1 - z0
	local len = math.sqrt(dx * dx + dz * dz)
	local steps = math.max(1, math.ceil(len / 0.25))
	local y = y0
	local lastKey = -1
	for i = 0, steps do
		local t = i / steps
		local fx = (x0 + dx * t - G.X0) / CELL
		local fz = (z0 + dz * t - G.Z0) / CELL
		local ix, iz = math.floor(fx), math.floor(fz)
		-- (exactly on a grid line: the square on either side will do; use the lower one)
		local key = ix * 100000 + iz
		if key ~= lastKey then
			lastKey = key
			local sum, n = 0, 0
			for ox = 0, 1 do
				for oz = 0, 1 do
					local ly = levelAt(ix + ox, iz + oz, y, STEP * 1.5)
					if not ly then
						-- (a point right on a grid line only needs the cells on that line)
						local onX = math.abs(fx - math.floor(fx + 0.5)) < 1e-6 and (ix + ox) ~= math.floor(fx + 0.5)
						local onZ = math.abs(fz - math.floor(fz + 0.5)) < 1e-6 and (iz + oz) ~= math.floor(fz + 0.5)
						if not (onX or onZ) then
							return false
						end
					else
						sum += ly
						n += 1
					end
				end
			end
			if n == 0 then
				return false
			end
			y = sum / n
		end
	end
	return true
end

local function straightIds(a: number, b: number): boolean
	if a == b then
		return true
	end
	return clearLine(G.NX_[a], G.NZ_[a], G.NY_[a], G.NX_[b], G.NZ_[b])
end

-- can he walk straight from `from` (where he stands, or any point above a floor) to `to`?
function NavGrid.straight(from: Vector3, to: Vector3): boolean
	if not G then
		return false
	end
	local a = snap(from, 1.5)
	if not a then
		return false
	end
	local b = snap(to, 1.5, G.Comp[a])
	if not b then
		return false
	end
	return clearLine(from.X, from.Z, G.NY_[a], G.NX_[b], G.NZ_[b])
end

-- a binary heap of node ids by score
local function heapPush(h, f, id, score)
	table.insert(h, id)
	f[#h] = score
	local i = #h
	while i > 1 do
		local p = i // 2
		if f[p] <= f[i] then
			break
		end
		h[p], h[i] = h[i], h[p]
		f[p], f[i] = f[i], f[p]
		i = p
	end
end
local function heapPop(h, f)
	local top = h[1]
	local n = #h
	h[1], f[1] = h[n], f[n]
	h[n], f[n] = nil, nil
	n -= 1
	local i = 1
	while true do
		local l, r = i * 2, i * 2 + 1
		local m = i
		if l <= n and f[l] < f[m] then
			m = l
		end
		if r <= n and f[r] < f[m] then
			m = r
		end
		if m == i then
			break
		end
		h[m], h[i] = h[i], h[m]
		f[m], f[i] = f[i], f[m]
		i = m
	end
	return top
end

local function astar(a: number, b: number): { number }?
	if a == b then
		return { a }
	end
	local NXs, NYs, NZs, Nbr, Edge = G.NX_, G.NY_, G.NZ_, G.Nbr, G.Edge
	local bx, by, bz = NXs[b], NYs[b], NZs[b]
	local gScore = { [a] = 0 }
	local from = {}
	local closed = {}
	local heap, fs = {}, {}
	local abs, max, min = math.abs, math.max, math.min
	local function h(id: number): number
		local dx, dz = abs(NXs[id] - bx), abs(NZs[id] - bz)
		return max(dx, dz) + 0.414 * min(dx, dz) + abs(NYs[id] - by) * 0.5
	end
	heapPush(heap, fs, a, h(a))
	local expanded = 0
	while #heap > 0 do
		local cur = heapPop(heap, fs)
		if cur == b then
			local path = { b }
			while from[cur] do
				cur = from[cur]
				table.insert(path, cur)
			end
			-- (reversed: start first)
			local n = #path
			for i = 1, n // 2 do
				path[i], path[n - i + 1] = path[n - i + 1], path[i]
			end
			return path
		end
		if not closed[cur] then
			closed[cur] = true
			expanded += 1
			if expanded > 60000 then
				return nil
			end
			local cx, cy, cz = NXs[cur], NYs[cur], NZs[cur]
			local gc = gScore[cur]
			for _, n in Nbr[cur] do
				if not closed[n] then
					local nx, nz = NXs[n], NZs[n]
					local diag = nx ~= cx and nz ~= cz
					-- (hugging a wall costs a little: he keeps to the middle of halls and doorways)
					local ng = gc + (diag and 1.414 or 1) + abs(NYs[n] - cy) * 0.5 + (Edge[n] and 1.5 or 0)
					local old = gScore[n]
					if not old or ng < old then
						gScore[n] = ng
						from[n] = cur
						heapPush(heap, fs, n, ng + h(n))
					end
				end
			end
		end
	end
	return nil
end

-- pull the cell path taut: keep only the corners
local function smooth(path: { number }): { number }
	if #path <= 2 then
		return path
	end
	local out = { path[1] }
	local i = 1
	while i < #path do
		local j = i + 1
		-- (step through the path a few cells at a time, then back off to the last straight one)
		local k = j
		while k + 1 <= #path and straightIds(path[i], path[k + 1]) do
			k += 1
		end
		j = k
		table.insert(out, path[j])
		i = j
	end
	return out
end

-- A path from `from` (his root, or any point above the floor) to `to`. When `to` itself can't
-- be stood on (inside a cupboard, on a bed), it ends at the closest spot he can reach within
-- `reach` studs. Waypoints are at floor level; the first one is where he stands.
function NavGrid.findPath(from: Vector3, to: Vector3, reach: number?): { Vector3 }?
	if not G then
		return nil
	end
	local a = snap(from, 2.5)
	if not a then
		return nil
	end
	local b = snap(to, reach or 6, G.Comp[a])
	if not b then
		return nil
	end
	local cells = astar(a, b)
	if not cells then
		return nil
	end
	local out = {}
	for _, id in smooth(cells) do
		table.insert(out, nodePos(id))
	end
	return out
end

-- somewhere `rMin`..`rMax` studs from `center` that he can walk to in a straight line from it
function NavGrid.randomNear(center: Vector3, rMin: number, rMax: number, rng: Random?): Vector3?
	if not G then
		return nil
	end
	local c = snap(center, 4)
	if not c then
		return nil
	end
	local pc = nodePos(c)
	for _ = 1, 16 do
		local a = (rng and rng:NextNumber() or math.random()) * math.pi * 2
		local r = rMin + (rng and rng:NextNumber() or math.random()) * (rMax - rMin)
		local p = V(pc.X + math.cos(a) * r, pc.Y + 3, pc.Z + math.sin(a) * r)
		local id = snap(p, 1.2, G.Comp[c])
		if id and straightIds(c, id) then
			return nodePos(id)
		end
	end
	return pc
end

-- (for him standing at a floor-level point)
function NavGrid.rootAt(floor: Vector3): Vector3
	return floor + V(0, ROOT_ABOVE_FEET, 0)
end

-- (tests: save a survey and load it back instead of surveying again)
function NavGrid._export()
	return G
end
function NavGrid._import(g)
	G = g
end

function NavGrid.stats()
	if not G then
		return nil
	end
	local nodes, comps, sizes = 0, 0, {}
	for id, c in G.Comp do
		nodes += 1
		sizes[c] = (sizes[c] or 0) + 1
	end
	local biggest = 0
	for _, n in sizes do
		comps += 1
		biggest = math.max(biggest, n)
	end
	return { Nodes = nodes, Areas = comps, Biggest = biggest }
end

return NavGrid
