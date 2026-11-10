-- surfaces_test (v153): no knitted-wool Fabric anywhere (rugs become Carpet, the rest a smooth matte finish),
-- and lamp shades cast no shadows (the bulb's light streaked across them). Checked on the whole built house.
local H = require("./env")
local ok, err = pcall(function()
	local Surfaces = H.load("Server/World/Surfaces")
	local R = H.roblox
	local m = H.Instance.new("Model")
	m.Name = "Sofa"
	local a = H.Instance.new("Part", m); a.Name = "Cushion"; a.Material = R.Enum.Material.Fabric
	local rug = H.Instance.new("Part", m); rug.Name = "LivingRug"; rug.Material = R.Enum.Material.Fabric
	local mat = H.Instance.new("Part", m); mat.Name = "Mattress"; mat.Material = R.Enum.Material.Fabric
	local shade = H.Instance.new("Part", m); shade.Name = "PendantShade"; shade.CastShadow = true
	Surfaces.sweep(m)
	assert(a.Material == R.Enum.Material.SmoothPlastic, "cushion: smooth, got " .. tostring(a.Material))
	assert(rug.Material == R.Enum.Material.Carpet, "rug: carpet")
	assert(mat.Material == R.Enum.Material.SmoothPlastic, "a mattress isn't a mat")
	assert(shade.CastShadow == false, "shades cast no shadow")
	-- the real house: nothing Fabric left once swept
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
	ctx.World.build()
	local folder = H.unwrap(ctx.World.folder())
	local before = 0
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") and d.Material == R.Enum.Material.Fabric then before += 1 end
	end
	Surfaces.sweep(H.wrap(folder))
	local after, shades = 0, 0
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Material == R.Enum.Material.Fabric then after += 1 end
			if string.find(d.Name, "Shade") and d.CastShadow then shades += 1 end
		end
	end
	print("fabric parts in the house:", before, "->", after, " shadow-casting shades:", shades)
	assert(before > 0 and after == 0 and shades == 0, "the house is swept")
end)
print(ok and "SURFACES OK" or ("SURFACES FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
