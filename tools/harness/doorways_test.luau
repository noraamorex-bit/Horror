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
	for _, id in { "Lily", "FrontDoor", "Basement", "BackDoor" } do
		local d = ctx.Doors.get(id)
		if d then print("door", id, d.Position, d.Size, d.Hinge and d.Hinge.Position) end
	end
	local R = H.roblox
	local all = {}
	for _, d in H.unwrap(ctx.World.folder()):GetDescendants() do
		if d:IsA("BasePart") then table.insert(all, d) end
	end
	local function aabb(p)
		local cf, sz = p.CFrame, p.Size
		local mn, mx = R.Vector3.new(1e9, 1e9, 1e9), R.Vector3.new(-1e9, -1e9, -1e9)
		for _, sx in { -1, 1 } do for _, sy in { -1, 1 } do for _, sz2 in { -1, 1 } do
			local w = cf * R.Vector3.new(sx * sz.X / 2, sy * sz.Y / 2, sz2 * sz.Z / 2)
			mn = R.Vector3.new(math.min(mn.X, w.X), math.min(mn.Y, w.Y), math.min(mn.Z, w.Z))
			mx = R.Vector3.new(math.max(mx.X, w.X), math.max(mx.Y, w.Y), math.max(mx.Z, w.Z))
		end end end
		return mn, mx
	end
	local boxes = {}
	for _, p in all do local a, b = aabb(p); table.insert(boxes, { p, a, b }) end
	local function check(label, a, b)
		local hits = {}
		for _, e in boxes do
			local p, mn, mx = e[1], e[2], e[3]
			if mn.X < b.X and mx.X > a.X and mn.Y < b.Y and mx.Y > a.Y and mn.Z < b.Z and mx.Z > a.Z then
				table.insert(hits, p.Name .. "(" .. (p.Parent and p.Parent.Name or "?") .. ")")
			end
		end
		print(label, #hits, table.concat(hits, ", "):sub(1, 400))
	end
	local L = ctx.Layout
	local offenders = 0
	local skipName = { Floor = true, GroundSlab = true, Baseboard = true, Casing = true, Threshold = true, Rug = true, RugCore = true, RugInner = true, RugField = true, Fringe = true, Paint = true, Wainscot = true, ChairRail = true, Wall = true, Header = true, StairHeader = true }
	local function clearBox(label, a, b)
		for _, e in boxes do
			local p, mn, mx = e[1], e[2], e[3]
			if p.CanCollide and not skipName[p.Name] and not (p.Parent and tostring(p.Parent.Name):sub(1, 5) == "Door_")
				and mn.X < b.X and mx.X > a.X and mn.Y < b.Y and mx.Y > a.Y and mn.Z < b.Z and mx.Z > a.Z then
				offenders += 1
				print("BLOCKED", label, p.Name, "(" .. tostring(p.Parent and p.Parent.Name) .. ")")
			end
		end
	end
	for _, list in { L.ExteriorWalls, L.InteriorWalls } do
		for _, w in list do
			local fy = L.Y[w.floor]
			for _, op in w.openings or {} do
				if op.kind == "door" or op.kind == "arch" then
					local half = (op.w or 5) / 2 - 0.4
					local alongX = w.z1 == w.z2
					for _, side in { -1, 1 } do
						local a, b
						if alongX then
							local z = w.z1
							a = R.Vector3.new(op.at - half, fy + 0.4, math.min(z + side * 0.6, z + side * 3.2))
							b = R.Vector3.new(op.at + half, fy + 7, math.max(z + side * 0.6, z + side * 3.2))
						else
							local x = w.x1
							a = R.Vector3.new(math.min(x + side * 0.6, x + side * 3.2), fy + 0.4, op.at - half)
							b = R.Vector3.new(math.max(x + side * 0.6, x + side * 3.2), fy + 7, op.at + half)
						end
						clearBox(string.format("%s %s@%s side %d", w.floor, op.kind, tostring(op.id or op.at), side), a, b)
					end
				end
			end
		end
	end
	print("DOORWAY offenders:", offenders)
end)
print(ok and "DUMP OK" or ("DUMP FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
