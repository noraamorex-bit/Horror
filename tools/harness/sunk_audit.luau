local H = require("./env")
local Sim = require("./navsim")
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
Sim.install(H)
local R = H.roblox
local V = R.Vector3.new
local root = H.unwrap(H.workspaceRoot)
local results = {}
local function modelOf(p)
	local m = p.Parent
	while m and m.Parent and not m:IsA("Model") do m = m.Parent end
	return m
end
local count = 0
for _, p in root:GetDescendants() do
	if p:IsA("BasePart") and p.Transparency < 0.9 then
		local sz = p.Size
		if math.max(sz.X, sz.Y, sz.Z) < 3 and sz.Y > 0.05 then
			local cf = p.CFrame
			-- world AABB bottom
			local ex = math.abs(cf.RightVector.Y) * sz.X / 2 + math.abs(cf.UpVector.Y) * sz.Y / 2 + math.abs(cf.LookVector.Y) * sz.Z / 2
			local bottom = cf.Position.Y - ex
			local m = modelOf(p)
			local params = { FilterType = R.Enum.RaycastFilterType.Exclude, FilterDescendantsInstances = { H.wrap(m and m ~= root and m or p) } }
			local hit = Sim.raycast(cf.Position, V(0, -(ex + 3), 0), params)
			if hit then
				local top = hit.Position.Y
				local sink = top - bottom
				if sink > 0.06 and cf.Position.Y > top + 0.01 and hit.Normal.Y > 0.7 then
					count += 1
					local key = p.Name .. " in " .. (m and m.Name or "?") .. " on " .. hit.Instance.Name
					results[key] = results[key] or { n = 0, max = 0, at = cf.Position }
					results[key].n += 1
					results[key].max = math.max(results[key].max, sink)
				end
			end
		end
	end
end
local list = {}
for k, v in results do table.insert(list, { k, v }) end
table.sort(list, function(a, b) return a[2].max > b[2].max end)
for _, e in list do print(("%.2f x%d  %s  %s"):format(e[2].max, e[2].n, e[1], tostring(e[2].at))) end
print("SUNK", count)
