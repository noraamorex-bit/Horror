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
