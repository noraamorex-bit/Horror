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
	local lastObjectives
	ctx.Remotes = setmetatable({}, { __index = function(_, k) return { FireClient = function() end, FireAllClients = function(_, payload) if k == "Objectives" then lastObjectives = payload end end, OnServerEvent = H.signal() } end })
	for _, name in { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "Hiding=HidingService", "Escape=EscapeService", "Capture=CaptureService", "PlayerState=PlayerStateService", "Phone=PhoneService" } do
		local key, file = name:match("(%w+)=(%w+)")
		ctx[key] = H.load("Server/Services/" .. file)
	end
	ctx.Objectives = H.load("Server/Services/ObjectiveService")
	ctx.Director = { getAct = function() return "Evening" end, logTruth = function() end, onDiscovery = function() end }
	ctx.World = H.load("Server/World/World")
	ctx.Director.think = function() end
	ctx.Director.onItem = function() end
	ctx.Director.onHide = function() end
	for _, k in { "Audio", "Noise", "Interaction", "Inventory", "Power", "Doors", "Hiding", "Escape", "Capture", "PlayerState", "Phone", "World", "Objectives" } do
		ctx[k].init(ctx)
	end
	local refs = ctx.World.build()
	local R = H.roblox
	local V3 = R.Vector3.new
	local world = H.unwrap(ctx.World.folder())
	-- every visible part, with its world AABB, in a coarse XZ grid
	local CELL = 6
	local grid = {}
	local all = {}
	local function aabb(p)
		local cf, s = p.CFrame, p.Size
		local mn, mx = cf.Position, cf.Position
		for _, sx in { -1, 1 } do for _, sy in { -1, 1 } do for _, sz in { -1, 1 } do
			local q = cf:PointToWorldSpace(V3(sx * s.X / 2, sy * s.Y / 2, sz * s.Z / 2))
			mn = V3(math.min(mn.X, q.X), math.min(mn.Y, q.Y), math.min(mn.Z, q.Z))
			mx = V3(math.max(mx.X, q.X), math.max(mx.Y, q.Y), math.max(mx.Z, q.Z))
		end end end
		return mn, mx
	end
	for _, d in world:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.99 then
			local mn, mx = aabb(d)
			local e = { P = d, Mn = mn, Mx = mx }
			table.insert(all, e)
			for gx = math.floor(mn.X / CELL), math.floor(mx.X / CELL) do
				for gz = math.floor(mn.Z / CELL), math.floor(mx.Z / CELL) do
					local k = gx .. "," .. gz
					grid[k] = grid[k] or {}
					table.insert(grid[k], e)
				end
			end
		end
	end
	local function partsAt(p)
		return grid[math.floor(p.X / CELL) .. "," .. math.floor(p.Z / CELL)] or {}
	end
	local function inside(p, part)
		local lp = part.CFrame:PointToObjectSpace(p)
		local h = part.Size / 2
		return math.abs(lp.X) <= h.X + 0.02 and math.abs(lp.Y) <= h.Y + 0.02 and math.abs(lp.Z) <= h.Z + 0.02
	end

	-- FLOAT AUDIT: furniture and props must rest on something
	local MOUNTED = { Picture = true, Sconce = true, Pendant = true, CeilingFan = true, Curtain = true, Mirror = true, FairyLights = true,
		StringLights = true, Towel = true, WallLantern = true, Wire = true, UpperCabinets = true, Hood = true, Shelving = true, Clock = true,
		TelephonePole = true, StreetLamp = true, RoadSign = true, Speaker = true, Monitor = true, TV = true, Lantern = true, Keyboard = true }
	local skipTop = { Structure = true, Doors = true, Windows = true, Lights = true, Finishes = true }
	local floats = {}
	for _, top in world:GetChildren() do
		if skipTop[top.Name] then continue end
		for _, m in top:GetDescendants() do
			if not m:IsA("Model") or MOUNTED[m.Name] or m:FindFirstAncestorWhichIsA("Model") ~= nil and m:FindFirstAncestorWhichIsA("Model").Parent ~= top and m.Parent ~= top then
				continue
			end
			local mn, mx
			local mine = {}
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") and d.Transparency < 0.99 then
					mine[d] = true
					local a, b = aabb(d)
					mn = mn and V3(math.min(mn.X, a.X), math.min(mn.Y, a.Y), math.min(mn.Z, a.Z)) or a
					mx = mx and V3(math.max(mx.X, b.X), math.max(mx.Y, b.Y), math.max(mx.Z, b.Z)) or b
				end
			end
			if not mn or mn.Y < -30 then continue end
			local c = (mn + mx) / 2
			local ix, iz = (mx.X - mn.X) * 0.3, (mx.Z - mn.Z) * 0.3
			local supported = false
			for _, off in { V3(0, 0, 0), V3(ix, 0, iz), V3(-ix, 0, iz), V3(ix, 0, -iz), V3(-ix, 0, -iz) } do
				local p = V3(c.X + off.X, mn.Y - 0.15, c.Z + off.Z)
				for _, e in partsAt(p) do
					if not mine[e.P] and inside(p, e.P) then
						supported = true
						break
					end
				end
				if supported then break end
			end
			if not supported then
				table.insert(floats, string.format("%s/%s at (%.1f, %.1f, %.1f) bottom %.2f", top.Name, m:GetFullName():match("[^%.]+$"), c.X, c.Y, c.Z, mn.Y))
			end
		end
	end
	table.sort(floats)
	print("FLOAT offenders:", #floats)
	for _, f in floats do if not f:match("Shrub") then print("  FLOAT", f) end end

	-- PROMPT AUDIT: prompts buried in walls, or too high to reach from the floor
	local bad = {}
	for _, pr in world:GetDescendants() do
		if pr:IsA("ProximityPrompt") then
			local par = pr.Parent
			local okP, pos = pcall(function()
				if par:IsA("Attachment") then
					return (par.Parent.CFrame * par.CFrame).Position
				elseif par:IsA("BasePart") then
					return par.CFrame.Position
				end
				return nil
			end)
			if not okP then pos = nil end
			if not pos then continue end
			local owner = par:IsA("Attachment") and par.Parent or par
			local model = owner:FindFirstAncestorWhichIsA("Model")
			-- floor under it
			local floorTop = -1e9
			for _, e in partsAt(pos) do
				if e.P.CanCollide and e.Mx.Y <= pos.Y + 0.01 and e.Mn.X <= pos.X and e.Mx.X >= pos.X and e.Mn.Z <= pos.Z and e.Mx.Z >= pos.Z and (e.Mx.X - e.Mn.X) > 3 and (e.Mx.Z - e.Mn.Z) > 3 then
					floorTop = math.max(floorTop, e.Mx.Y)
				end
			end
			local reach = pr.MaxActivationDistance
			PCOUNT = (PCOUNT or 0) + 1
			if floorTop > -1e8 then
				HS = HS or {}
				table.insert(HS, { pos.Y - floorTop, pr.ActionText .. " / " .. owner.Name })
			end
			local rootH = 3.6 -- a scaled-up player's root height
			local h = pos.Y - floorTop
			if floorTop > -1e8 and h - rootH > reach - 1.5 then
				table.insert(bad, string.format("TOO HIGH %s '%s' h=%.1f reach=%.1f", owner:GetFullName():match("[^%.]+%.[^%.]+$") or owner.Name, pr.ActionText, h, reach))
			end
			-- buried: the point is deep inside another model's solid part
			for _, e in partsAt(pos) do
				if e.P ~= owner and e.P.CanCollide and (not model or not e.P:IsDescendantOf(model)) then
					local lp = e.P.CFrame:PointToObjectSpace(pos)
					local hs = e.P.Size / 2
					local depth = math.min(hs.X - math.abs(lp.X), hs.Y - math.abs(lp.Y), hs.Z - math.abs(lp.Z))
					if depth > 0.6 then
						table.insert(bad, string.format("BURIED %s '%s' in %s (%.1f deep)", owner:GetFullName():match("[^%.]+%.[^%.]+$") or owner.Name, pr.ActionText, e.P:GetFullName():match("[^%.]+%.[^%.]+$"), depth))
						break
					end
				end
			end
		end
	end
	table.sort(bad)
	table.sort(HS, function(a, b) return a[1] > b[1] end)
	print("prompts checked", PCOUNT, "with floor", #HS)
	for i = 1, 8 do if HS[i] then print(string.format("   highest %.1f  %s", HS[i][1], HS[i][2])) end end
	print("PROMPT offenders:", #bad)
	for _, b in bad do print("  PROMPT", b) end

	-- HEADROOM AUDIT: a 6.1-stud player walking up every ramp must not hit anything solid
	local head = {}
	for _, d in world:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Ramp" then
			local cf, s = d.CFrame, d.Size
			for t = -0.45, 0.45, 0.05 do
				local top = cf:PointToWorldSpace(V3(0, s.Y / 2, t * s.Z))
				for _, hgt in { 4.5, 5.5, 6.3 } do
					local p = top + V3(0, hgt, 0)
					for _, e in partsAt(p) do
						if e.P.CanCollide and e.P ~= d and e.P.Name ~= "Ramp" and inside(p, e.P) then
							head[string.format("%s over ramp at (%.1f, %.1f, %.1f) +%.1f", e.P:GetFullName():match("[^%.]+%.[^%.]+$"), top.X, top.Y, top.Z, hgt)] = true
						end
					end
				end
			end
		end
	end
	local hl = {}
	for k in head do table.insert(hl, k) end
	table.sort(hl)
	print("HEADROOM offenders:", #hl)
	for _, v in hl do print("  HEAD", v) end
end)
print(ok and "AUDIT2 OK" or ("AUDIT2 FAIL: " .. tostring(err)))
