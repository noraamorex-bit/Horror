-- navgrid_test: survey the real built house (navsim geometry), check the walkable map is sane
-- and every navigation node / hiding-spot exit / room is reachable from the hall; dumps a
-- picture of each floor (navgrid_<floor>.txt, rendered by tools/harness/navgrid_png.py).
local H = require("./env")
local Sim = require("./navsim")
local fs = require("@lune/fs")
local T = 1000
H.clock = function() return T end
local ctx: any = {}
ctx.Config = H.load("RS/Shared/Config")
ctx.Rooms = H.load("RS/Shared/Rooms")
ctx.Sounds = H.load("RS/Shared/Sounds")
ctx.Story = H.load("RS/Shared/Story")
ctx.Util = H.load("RS/Shared/Util")
ctx.Builder = H.load("Server/World/Builder")
ctx.Layout = H.load("Server/World/Layout")
ctx.Remotes = setmetatable({}, { __index = function(t, k)
	local r = { FireClient = function() end, FireAllClients = function() end, OnServerEvent = H.signal() }
	rawset(t, k, r)
	return r
end })
local names = {}
for _, name in { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService", "Revive=ReviveService", "Admin=AdminService", "Cutscene=CutsceneService", "Heartbeat=HeartbeatService" } do
	local key, file = name:match("(%w+)=(%w+)")
	ctx[key] = H.load("Server/Services/" .. file)
	table.insert(names, key)
end
ctx.World = H.load("Server/World/World")
ctx.Director = H.load("Server/Director/Director")
ctx.Intruder = H.load("Server/Intruder/Intruder")
for _, k in { "World", "Director", "Intruder" } do table.insert(names, k) end
for _, k in names do if ctx[k].init then ctx[k].init(ctx) end end
ctx.World.build()
local t0 = os.clock()
local ns, nd = Sim.install(H)
print(("indexed %d static + %d moving parts in %.1fs"):format(ns, nd, os.clock() - t0))
local NavGrid = H.load("Server/Intruder/NavGrid")
t0 = os.clock()
NavGrid.build({})
print(("grid built in %.1fs (%d rays)"):format(os.clock() - t0, Sim.rays), H.roblox and "")
local st = NavGrid.stats()
print("nodes", st.Nodes, "areas", st.Areas, "biggest", st.Biggest)
local V = H.roblox.Vector3.new
local hall = V(2, 4, -20)
local failures = {}
local function reach(label, p, radius)
	local path = NavGrid.findPath(hall, p, radius or 6)
	if not path then
		table.insert(failures, label .. " " .. tostring(p))
		return
	end
	local last = path[#path]
	local flat = V(last.X - p.X, 0, last.Z - p.Z).Magnitude
	if flat > (radius or 6) then table.insert(failures, label .. " ends " .. flat .. " away") end
end
for i, n in ctx.Layout.Nodes do reach("node " .. i .. " " .. n.Room, n.Pos, 3) end
for _, s in ctx.Hiding.spotsNear(V(0, 0, 0), 1000) do reach("spot exit " .. tostring(s.Name or s.Id), s.Exit.Position, 4) end
local t1 = os.clock()
local n = 0
for i, a in ctx.Layout.Nodes do
	for j, b in ctx.Layout.Nodes do
		if i < j then n += 1; NavGrid.findPath(a.Pos, b.Pos, 3) end
	end
end
print(("%d node-to-node paths, %.1f ms each"):format(n, (os.clock() - t1) / n * 1000))
for _, f in failures do print("UNREACHABLE: " .. f) end
-- dump the floors
local B = NavGrid.Bounds
for name, y in { Basement = -13, Ground = 1, Upstairs = 15 } do
	local lines = {}
	for iz = B.Z1, B.Z0, -1 do
		local row = {}
		for ix = B.X0, B.X1 do
			local id = NavGrid._snap(V(ix, y + 3, iz), 0.01)
			local c = "#"
			if id then
				local p = NavGrid._nodePos(id)
				c = math.abs(p.Y - y) < 0.4 and "." or (p.Y > y and "^" or "v")
			end
			table.insert(row, c)
		end
		table.insert(lines, table.concat(row))
	end
	fs.writeFile("/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad/navgrid_" .. name .. ".txt", table.concat(lines, "\n"))
end
for _, e in H.errors do print("ERR", e) end
assert(#failures == 0, #failures .. " unreachable")
print("navgrid ok")
