-- dress_test: the lived-in layer (World/Dress) stays out of the way. Every part it adds keeps clear of
-- doorways and door swings, hiding spots (their exits and what you see from inside), prompts, his nav
-- nodes, the Halloween candy spots and the open windows, and doesn't sink into other furniture; its
-- Creator Store stand-ins all have a Props entry; and it stays a modest number of parts (phones).
local H = require("./env")
local ok, err = pcall(function()
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Rooms = H.load("RS/Shared/Rooms")
	ctx.Sounds = H.load("RS/Shared/Sounds")
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Util = H.load("RS/Shared/Util")
	ctx.Builder = H.load("Server/World/Builder")
	ctx.Layout = H.load("Server/World/Layout")
	ctx.Remotes = setmetatable({}, { __index = function() return { FireClient = function() end, FireAllClients = function() end, OnServerEvent = H.signal() } end })
	for _, name in { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "Hiding=HidingService", "Escape=EscapeService", "Capture=CaptureService", "PlayerState=PlayerStateService", "Phone=PhoneService" } do
		local key, file = name:match("(%w+)=(%w+)")
		ctx[key] = H.load("Server/Services/" .. file)
	end
	ctx.Objectives = H.load("Server/Services/ObjectiveService")
	ctx.Director = { getAct = function() return "Evening" end, logTruth = function() end, onDiscovery = function() end, think = function() end, onItem = function() end, onHide = function() end }
	ctx.World = H.load("Server/World/World")
	for _, k in { "Audio", "Noise", "Interaction", "Inventory", "Power", "Doors", "Hiding", "Escape", "Capture", "PlayerState", "Phone", "World", "Objectives" } do
		ctx[k].init(ctx)
	end
	local refs = ctx.World.build()
	local R = H.roblox
	local V3 = R.Vector3.new
	local L = ctx.Layout
	local Props = H.load("Server/World/Props")
	local root = H.unwrap(ctx.World.folder())

	local function aabb(p)
		local cf, s = p.CFrame, p.Size
		local mn, mx
		for _, sx in { -1, 1 } do for _, sy in { -1, 1 } do for _, sz in { -1, 1 } do
			local q = cf:PointToWorldSpace(V3(sx * s.X / 2, sy * s.Y / 2, sz * s.Z / 2))
			mn = mn and V3(math.min(mn.X, q.X), math.min(mn.Y, q.Y), math.min(mn.Z, q.Z)) or q
			mx = mx and V3(math.max(mx.X, q.X), math.max(mx.Y, q.Y), math.max(mx.Z, q.Z)) or q
		end end end
		return mn, mx
	end
	-- distance from a point to a box
	local function dist(p, mn, mx)
		local dx = math.max(mn.X - p.X, 0, p.X - mx.X)
		local dy = math.max(mn.Y - p.Y, 0, p.Y - mx.Y)
		local dz = math.max(mn.Z - p.Z, 0, p.Z - mx.Z)
		return math.sqrt(dx * dx + dy * dy + dz * dz), math.sqrt(dx * dx + dz * dz)
	end
	-- does the segment a->b pass through the box (slab test)?
	local function segHits(a, b, mn, mx)
		local t0, t1 = 0, 1
		for _, ax in { "X", "Y", "Z" } do
			local d = b[ax] - a[ax]
			if math.abs(d) < 1e-9 then
				if a[ax] < mn[ax] or a[ax] > mx[ax] then return false end
			else
				local u, v = (mn[ax] - a[ax]) / d, (mx[ax] - a[ax]) / d
				if u > v then u, v = v, u end
				t0, t1 = math.max(t0, u), math.min(t1, v)
				if t0 > t1 then return false end
			end
		end
		return true
	end

	local list = refs.Dressing
	assert(list and #list > 0, "World keeps the dressing's parts as refs.Dressing")
	local dress = {}
	for _, w in list do
		local p = H.unwrap(w)
		local mn, mx = aabb(p)
		table.insert(dress, { P = p, Mn = mn, Mx = mx })
		p:SetAttribute("_Dress", true) -- (lune hands out fresh userdata for the same instance: mark it instead)
	end
	local bad = {}
	local function fail(msg)
		table.insert(bad, msg)
	end
	local function label(e)
		local par = e.P.Parent
		return e.P.Name .. "(" .. tostring(par and par.Name) .. string.format(" @ %.1f,%.1f,%.1f)", (e.Mn.X + e.Mx.X) / 2, e.Mn.Y, (e.Mn.Z + e.Mx.Z) / 2)
	end

	-- 1. door swings: every door's leaf sweeps a quarter circle round its hinge (floor to head height)
	local doorCount = 0
	for _, d in ctx.Doors.all() do
		doorCount += 1
		local hinge = d.Hinge
		local closed = hinge + d.Offset
		local r = V3(closed.X - hinge.X, 0, closed.Z - hinge.Z).Magnitude + 0.3
		local a0 = math.atan2(closed.Z - hinge.Z, closed.X - hinge.X)
		local openCF = R.CFrame.new(hinge) * R.CFrame.Angles(0, d.OpenAngle * d.Sign, 0) * R.CFrame.new(d.Offset)
		local a1 = math.atan2(openCF.Position.Z - hinge.Z, openCF.Position.X - hinge.X)
		local function inSweep(x, z)
			local dx, dz = x - hinge.X, z - hinge.Z
			if dx * dx + dz * dz > r * r then return false end
			local a = math.atan2(dz, dx)
			-- the angle from a0 towards a1, the short way round
			local span = (a1 - a0 + math.pi) % (2 * math.pi) - math.pi
			local rel = (a - a0 + math.pi) % (2 * math.pi) - math.pi
			if span >= 0 then return rel >= -0.15 and rel <= span + 0.15 end
			return rel <= 0.15 and rel >= span - 0.15
		end
		for _, e in dress do
			if e.Mx.Y > hinge.Y - 4.5 and e.Mn.Y < hinge.Y + 5 then
				local hit = false
				for _, fx in { 0, 0.25, 0.5, 0.75, 1 } do
					for _, fz in { 0, 0.25, 0.5, 0.75, 1 } do
						if inSweep(e.Mn.X + (e.Mx.X - e.Mn.X) * fx, e.Mn.Z + (e.Mx.Z - e.Mn.Z) * fz) then hit = true end
					end
				end
				if hit then fail("in the swing of door " .. d.Id .. ": " .. label(e)) end
			end
		end
	end
	assert(doorCount > 10, "doors built")

	-- 2. doorways and arches: 2.6 studs clear either side of every opening (as doorways_test)
	for _, wl in { L.ExteriorWalls, L.InteriorWalls } do
		for _, w in wl do
			local fy = L.Y[w.floor]
			for _, op in w.openings or {} do
				if op.kind == "door" or op.kind == "arch" or op.kind == "garage" or (op.kind == "window" and op.open) then
					local half = (op.w or 5) / 2
					local alongX = w.z1 == w.z2
					local fixed = alongX and w.z1 or w.x1
					local mn = alongX and V3(op.at - half, fy + 0.2, fixed - 2.6) or V3(fixed - 2.6, fy + 0.2, op.at - half)
					local mx = alongX and V3(op.at + half, fy + 8, fixed + 2.6) or V3(fixed + 2.6, fy + 8, op.at + half)
					for _, e in dress do
						if e.Mn.X < mx.X and e.Mx.X > mn.X and e.Mn.Y < mx.Y and e.Mx.Y > mn.Y and e.Mn.Z < mx.Z and e.Mx.Z > mn.Z then
							fail("in front of " .. op.kind .. " " .. tostring(op.id or op.at) .. ": " .. label(e))
						end
					end
				end
			end
		end
	end

	-- 3. hiding spots: keep their exits clear and the view from inside open
	local spots = 0
	for _, s in ctx.Hiding.all() do
		spots += 1
		local exitP = s.Exit.Position
		local eye = s.View.Position
		local look = eye + s.View.LookVector * 9
		for _, e in dress do
			local _, flat = dist(exitP, e.Mn, e.Mx)
			if flat < 1.2 and e.Mn.Y < exitP.Y + 3 and e.Mx.Y > exitP.Y - 3.5 then
				fail("on the way out of " .. s.Name .. ": " .. label(e))
			end
			if segHits(eye, look, e.Mn - V3(0.15, 0.15, 0.15), e.Mx + V3(0.15, 0.15, 0.15)) then
				fail("in the view from " .. s.Name .. ": " .. label(e))
			end
		end
	end
	assert(spots >= 15, "hiding spots registered")

	-- 4. prompts: nothing of ours on or around a prompt's part
	local prompts = 0
	for _, pr in root:GetDescendants() do
		if pr:IsA("ProximityPrompt") and pr.Parent and pr.Parent:IsA("BasePart") and not pr.Parent:GetAttribute("_Dress") then
			prompts += 1
			local pp = pr.Parent
			local pmn, pmx = aabb(pp)
			local c = (pmn + pmx) / 2 + (pr.UIOffset and V3(0, 0, 0) or V3(0, 0, 0))
			for _, e in dress do
				local d3 = dist(c, e.Mn, e.Mx)
				local overlap = e.Mn.X < pmx.X and e.Mx.X > pmn.X and e.Mn.Y < pmx.Y and e.Mx.Y > pmn.Y and e.Mn.Z < pmx.Z and e.Mx.Z > pmn.Z
				if d3 < 0.6 or (overlap and pp.Transparency > 0.9) then
					fail("on the prompt " .. pr.ActionText .. " " .. pr.ObjectText .. ": " .. label(e))
				end
			end
		end
	end
	assert(prompts > 50, "prompts found")

	-- 5. his nav nodes and the Halloween candy spots
	for i, n in L.Nodes do
		for _, e in dress do
			local _, flat = dist(n.Pos, e.Mn, e.Mx)
			if e.P.CanCollide and flat < 2.4 and e.Mn.Y < n.Pos.Y + 3 and e.Mx.Y > n.Pos.Y - 3.5 then
				fail("by nav node " .. i .. " (" .. n.Room .. "): " .. label(e))
			end
		end
	end
	for i, c in L.CandySpots or {} do
		for _, e in dress do
			if dist(c, e.Mn, e.Mx) < 0.7 then
				fail("on candy spot " .. i .. ": " .. label(e))
			end
		end
	end

	-- 6. not sunk into the rest of the house: our solid parts don't overlap anything that collides,
	-- and nothing of ours pokes into the house's furniture by more than a sliver
	local others = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and not d:GetAttribute("_Dress") and (d.CanCollide or d.Transparency < 0.98) then
			local mn, mx = aabb(d)
			table.insert(others, { P = d, Mn = mn, Mx = mx })
		end
	end
	local SLIVER = 0.04
	for _, e in dress do
		for _, o in others do
			local ox = math.min(e.Mx.X, o.Mx.X) - math.max(e.Mn.X, o.Mn.X)
			local oy = math.min(e.Mx.Y, o.Mx.Y) - math.max(e.Mn.Y, o.Mn.Y)
			local oz = math.min(e.Mx.Z, o.Mx.Z) - math.max(e.Mn.Z, o.Mn.Z)
			-- (World/Depth grows a panel a few hundredths to part coplanar faces: into the floor is fine)
			local floor = o.P.Name == "Floor" or o.P.Name:find("Slab") ~= nil
			if ox > SLIVER and oy > (floor and 0.1 or SLIVER) and oz > SLIVER then
				-- (boxes of rotated parts are loose: only flag an overlap that's real for a box-shaped part
				-- that isn't turned)
				local square = e.P.CFrame.UpVector.Y > 0.999 and o.P.CFrame.UpVector.Y > 0.999
				if square and (o.P.CanCollide or e.P.CanCollide) and o.P.Transparency < 0.98 then
					fail("overlaps " .. o.P.Name .. "(" .. tostring(o.P.Parent and o.P.Parent.Name) .. "): " .. label(e))
				elseif square and e.P.CanCollide and o.P.CanCollide then
					fail("collider overlaps " .. o.P.Name .. "(" .. tostring(o.P.Parent and o.P.Parent.Name) .. "): " .. label(e))
				end
			end
		end
	end

	-- 7. every stand-in has a Creator Store model behind it, and the layer stays light
	local keys = {}
	for _, e in dress do
		local m = e.P:FindFirstAncestorWhichIsA("Model")
		local k = m and m:GetAttribute("PropKey")
		-- (small plants on shelves and counters, the low hall bookcase and Lily's toy shelf stay Kit-built on purpose)
		if type(k) == "string" and k:sub(1, 11) ~= "PlantSmall_" and k ~= "LowBookcase" and k ~= "ToyShelf" then
			keys[k] = true
			assert(Props.Models[k] ~= nil, "a stand-in without a Props entry: " .. k)
		end
	end
	for _, k in { "Toaster", "KnifeBlock", "PaperTowels", "CoffeeMaker", "LaundryBasket", "Tipi", "RockingHorse", "TeaSet", "TeddyPink", "TeddyBrown", "Cooler" } do
		assert(keys[k], "placed: " .. k)
	end
	print(("dressing: %d parts"):format(#dress))
	assert(#dress < 1200, "the dressing is too heavy for phones: " .. #dress .. " parts")

	table.sort(bad)
	for _, b in bad do print("  DRESS", b) end
	print("DRESS offenders:", #bad)
	assert(#bad == 0, #bad .. " dressing problems")
end)
print(ok and "DRESS OK" or ("DRESS FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
