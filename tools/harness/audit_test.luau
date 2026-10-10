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
	local n, prompts, doors = 0, 0, 0
	for _, d in H.unwrap(ctx.World.folder()):GetDescendants() do
		if d:IsA("BasePart") then n += 1 end
		if d:IsA("ProximityPrompt") then prompts += 1 end
	end
	print("parts", n, "prompts", prompts, "doors", #ctx.Doors.all(), "hiding spots", #ctx.Hiding.all())
	local keys = {}
	for k in refs do table.insert(keys, k) end
	print(table.concat(keys, " "))
	-- CLEARANCE AUDIT: furniture intruding into doorways, arches, stair ends, ladder
	do
		local R = H.roblox
		local world = H.unwrap(ctx.World.folder())
		local zones = {}
		local function zone(name, x0, y0, z0, x1, y1, z1)
			table.insert(zones, { Name = name, Min = R.Vector3.new(math.min(x0, x1), y0, math.min(z0, z1)), Max = R.Vector3.new(math.max(x0, x1), y1, math.max(z0, z1)) })
		end
		local L = ctx.Layout
		for _, list in { L.InteriorWalls, L.ExteriorWalls } do
			for _, spec in list do
				local alongX = spec.z1 == spec.z2
				local fixed = alongX and spec.z1 or spec.x1
				local y = L.Y[spec.floor]
				for _, op in spec.openings or {} do
					if op.kind == "window" and op.open then
						local a0, a1 = op.at - (op.w or 4) / 2, op.at + (op.w or 4) / 2
						if alongX then
							zone(spec.floor .. ":window " .. op.id, a0, y + 0.3, fixed - 2.5, a1, y + 7, fixed + 2.5)
						else
							zone(spec.floor .. ":window " .. op.id, fixed - 2.5, y + 0.3, a0, fixed + 2.5, y + 7, a1)
						end
					end
					if op.kind == "door" or op.kind == "arch" then
						local nm = spec.floor .. ":" .. (op.id or ("arch@" .. op.at))
						local a0, a1 = op.at - op.w / 2 + 0.2, op.at + op.w / 2 - 0.2
						if alongX then
							zone(nm, a0, y + 0.3, fixed - 4.5, a1, y + 7, fixed + 4.5)
						else
							zone(nm, fixed - 4.5, y + 0.3, a0, fixed + 4.5, y + 7, a1)
						end
					end
				end
			end
		end
		zone("MainStairs bottom", -8, 1.3, -10, -2, 8, -6)
		zone("MainStairs top", -8, 15.3, 16.4, -2, 22, 20)
		zone("BasementStairs top", 6.2, 1.3, 22, 11.8, 8, 26)
		zone("BasementStairs bottom", 6.2, -12.7, -4.5, 11.8, -6, -0.4)
		zone("Attic ladder", 3.5, 15.3, 10, 8.5, 22, 15.5)
		local skip = { Structure = true, Doors = true, Windows = true, Lights = true, Finishes = true, Exterior = true, AtticHatch = true, Nest = true }
		local offenders = {}
		for _, top in world:GetChildren() do
			if skip[top.Name] then continue end
			for _, d in top:GetDescendants() do
				if d:IsA("BasePart") and d.Transparency < 0.99 then
					local cf, s = d.CFrame, d.Size
					local mn, mx = cf.Position, cf.Position
					for _, sx in { -1, 1 } do for _, sy in { -1, 1 } do for _, sz in { -1, 1 } do
						local p = cf:PointToWorldSpace(R.Vector3.new(sx * s.X / 2, sy * s.Y / 2, sz * s.Z / 2))
						mn = R.Vector3.new(math.min(mn.X, p.X), math.min(mn.Y, p.Y), math.min(mn.Z, p.Z))
						mx = R.Vector3.new(math.max(mx.X, p.X), math.max(mx.Y, p.Y), math.max(mx.Z, p.Z))
					end end end
					for _, z in zones do
						if mx.X > z.Min.X and mn.X < z.Max.X and mx.Y > z.Min.Y and mn.Y < z.Max.Y and mx.Z > z.Min.Z and mn.Z < z.Max.Z then
							local key = z.Name .. " <- " .. top.Name .. "/" .. d.Name
							if not offenders[key] then
								offenders[key] = string.format("%s  [%.1f..%.1f, %.1f..%.1f]", key, mn.X, mx.X, mn.Z, mx.Z)
							end
						end
					end
				end
			end
		end
		local list = {}
		for _, v in offenders do table.insert(list, v) end
		table.sort(list)
		print("AUDIT offenders:", #list)
		for _, v in list do print("  AUDIT", v) end
	end
	-- POINT AUDIT: places a body must stand (nav nodes, hide exits, peek spots, spawns) must be free
	do
		local R = H.roblox
		local world = H.unwrap(ctx.World.folder())
		local solids = {}
		for _, d in world:GetDescendants() do
			if d:IsA("BasePart") and d.CanCollide and not (d.Parent and d.Parent.Name == "Doors") and not (d:FindFirstAncestor("Doors")) then
				table.insert(solids, d)
			end
		end
		local bad = {}
		local function check(label, pos)
			for _, off in { R.Vector3.new(0, -1.6, 0), R.Vector3.new(0, 0, 0), R.Vector3.new(0, 1.5, 0), R.Vector3.new(0.8, 0, 0), R.Vector3.new(-0.8, 0, 0), R.Vector3.new(0, 0, 0.8), R.Vector3.new(0, 0, -0.8) } do
				local p = pos + off
				for _, s in solids do
					local lp = s.CFrame:PointToObjectSpace(p)
					local h = s.Size / 2
					if math.abs(lp.X) < h.X and math.abs(lp.Y) < h.Y and math.abs(lp.Z) < h.Z then
						bad[label .. " in " .. s:GetFullName()] = true
						return
					end
				end
			end
		end
		local L = ctx.Layout
		for i, nd in L.Nodes do check("Node" .. i .. "(" .. nd.Room .. ")", nd.Pos) end
		for i, sp in L.PeekSpots do check("Peek" .. i, sp.Pos) end
		for i, sp in L.RestraintSlots do check("Restraint" .. i, sp.Pos) end
		for i, sp in L.LobbySpawns do check("Spawn" .. i, sp) end
		for i, sp in L.FootstepPath do check("Footstep" .. i, sp + R.Vector3.new(0, 2.5, 0)) end
		for _, spot in ctx.Hiding.all() do check("HideExit " .. spot.Name, spot.Exit.Position) end
		-- DOORWAY AUDIT: both sides of every door/arch need floor underfoot and open air (walls, stairwells)
		local function solidAt(p)
			for _, s in solids do
				local lp = s.CFrame:PointToObjectSpace(p)
				local h = s.Size / 2
				if math.abs(lp.X) < h.X and math.abs(lp.Y) < h.Y and math.abs(lp.Z) < h.Z then
					return s
				end
			end
			return nil
		end
		local doorBad = 0
		for _, list2 in { L.InteriorWalls, L.ExteriorWalls } do
			for _, w in list2 do
				local alongX = w.z1 == w.z2
				local f = alongX and w.z1 or w.x1
				local y = L.Y[w.floor]
				for _, op in w.openings or {} do
					if op.kind ~= "door" and op.kind ~= "arch" then continue end
					for _, side in { -1, 1 } do
						for _, depth in { 1.2, 2.6 } do
							for _, a in { op.at - op.w / 2 + 0.6, op.at, op.at + op.w / 2 - 0.6 } do
								local pz = f + side * depth
								local base = alongX and R.Vector3.new(a, y, pz) or R.Vector3.new(pz, y, a)
								local label = string.format("%s:%s side %d d%.1f a%.1f", w.floor, op.id or ("arch@" .. op.at), side, depth, a)
								local exterior = list2 == L.ExteriorWalls and side == (w.out == "+" and 1 or -1)
								-- the basement door opens straight onto the descending flight
								exterior = exterior or (op.id == "Basement" and side == -1 and depth > 2)
								if not exterior and not solidAt(base - R.Vector3.new(0, 0.05, 0)) then
									bad["DOOR no floor " .. label] = true
									doorBad += 1
								end
								for _, hgt in { 1.5, 4, 6.5 } do
									local s = solidAt(base + R.Vector3.new(0, hgt, 0))
									if s and not s:FindFirstAncestor("Doors") then
										bad["DOOR blocked " .. label .. " by " .. s:GetFullName()] = true
										doorBad += 1
										break
									end
								end
							end
						end
					end
				end
			end
		end
		print("DOORWAY offenders:", doorBad)
		local list = {}
		for k2 in bad do table.insert(list, k2) end
		table.sort(list)
		print("POINT offenders:", #list)
		for _, v in list do print("  POINT", v) end
		-- WALL AUDIT: furniture clipping into walls
		local clips = {}
		local skip = { Structure = true, Doors = true, Windows = true, Lights = true, Finishes = true, Exterior = true, AtticHatch = true, Nest = true }
		for _, top in world:GetChildren() do
			if skip[top.Name] then continue end
			for _, d in top:GetDescendants() do
				if d:IsA("BasePart") and d.Transparency < 0.99 then
					local cf, sz = d.CFrame, d.Size
					local mn, mx = cf.Position, cf.Position
					for _, sx in { -1, 1 } do for _, sy in { -1, 1 } do for _, sz2 in { -1, 1 } do
						local p = cf:PointToWorldSpace(R.Vector3.new(sx * sz.X / 2, sy * sz.Y / 2, sz2 * sz.Z / 2))
						mn = R.Vector3.new(math.min(mn.X, p.X), math.min(mn.Y, p.Y), math.min(mn.Z, p.Z))
						mx = R.Vector3.new(math.max(mx.X, p.X), math.max(mx.Y, p.Y), math.max(mx.Z, p.Z))
					end end end
					for _, list2 in { L.InteriorWalls, L.ExteriorWalls } do
						for _, w in list2 do
							local y0 = L.Y[w.floor]
							if mx.Y <= y0 + 0.2 or mn.Y >= y0 + L.WallH then continue end
							local alongX = w.z1 == w.z2
							local f = alongX and w.z1 or w.x1
							local lo, hi = alongX and math.min(w.x1, w.x2) or math.min(w.z1, w.z2), alongX and math.max(w.x1, w.x2) or math.max(w.z1, w.z2)
							local a0, a1 = alongX and mn.X or mn.Z, alongX and mx.X or mx.Z
							local b0, b1 = alongX and mn.Z or mn.X, alongX and mx.Z or mx.X
							if a1 <= lo + 0.3 or a0 >= hi - 0.3 then continue end
							local t = 0.3
							local c = (b0 + b1) / 2
							local pen = c < f and (b1 - (f + t)) or ((f - t) - b0)
							if pen > 0.05 and not d.Name:match("Chimney") and not d.Name:match("Firebox") and not d.Name:match("Surround") and not d.Name:match("Mantel") then
								-- inside an opening?
								local inOpen = false
								for _, op in w.openings or {} do
									if a0 >= op.at - op.w / 2 - 0.1 and a1 <= op.at + op.w / 2 + 0.1 then inOpen = true end
								end
								if not inOpen then
									clips[string.format("%s/%s wall %s%.0f pen %.2f", top.Name, d.Name, alongX and "z=" or "x=", f, pen)] = true
								end
							end
						end
					end
				end
			end
		end
		local cl = {}
		for k2 in clips do table.insert(cl, k2) end
		table.sort(cl)
		print("WALL clips:", #cl)
		for _, v in cl do print("  CLIP", v) end
	end
	-- every task step must have a marker target
	local ids = {}
	for id in ctx.Story.Tasks do table.insert(ids, id) end
	ctx.Objectives.set(ids)
	local missing = {}
	for _, id in ids do
		local def = ctx.Story.Tasks[id]
		for _, st in def.Steps or {} do
			local names = type(st.Target) == "table" and st.Target or { st.Target }
			for _, n in names do
				-- probe by completing earlier steps is overkill: check resolve via a fresh objective
				ctx.Objectives.set({ id })
				-- mark steps before this one done
				for _, prev in def.Steps do
					if prev == st then break end
					ctx.Objectives.step(id, prev.Key)
				end
				local o = lastObjectives[1]
				if not o.Targets or #o.Targets == 0 then
					table.insert(missing, id .. "." .. st.Key .. " -> " .. tostring(n))
				end
			end
		end
	end
	print("missing targets:", #missing, table.concat(missing, ", "))
	-- exercise some runtime paths
	refs.Footprints.show()
	refs.Kitchen.takeLasagna()
	refs.openGarageHatch()
	refs.AtticHatch.open()
	ctx.Escape.cutLine()
	print("stealKeys", ctx.Escape.stealKeys())
	ctx.Power.setMain(false)
	ctx.Power.setMain(true)
	-- rebuild (restart path)
	for _, k in { "Doors", "Power", "Hiding", "Escape", "Capture", "Inventory" } do
		if ctx[k].reset then ctx[k].reset() end
	end
	ctx.World.build()
	print("rebuild ok, doors", #ctx.Doors.all())
end)
print(ok and "WORLD OK" or ("WORLD FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
