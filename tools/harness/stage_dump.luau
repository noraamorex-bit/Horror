-- lune run stage_dump.luau <out.json>   (from tools/harness)
-- The built house for tools/assets/stage.mjs: every visible part (as the reel renderer's dump,
-- plus "ph" = the Props key of the furniture it belongs to) and every placeholder Props would swap:
-- its key, its upright frame and its box in that frame (the same maths as World/Props fit()).
local H = require("./env")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")
local out = process.args[1] or "stage.json"
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
	ctx.Halloween = H.load("Server/Services/HalloweenService") -- (its candies and lanterns while the event runs)
	for _, k in { "Audio", "Noise", "Interaction", "Inventory", "Power", "Doors", "Hiding", "Escape", "Capture", "PlayerState", "Phone", "Halloween", "World", "Objectives" } do
		ctx[k].init(ctx)
	end
	ctx.World.build()
	local Props = H.load("Server/World/Props")
	local root = H.unwrap(ctx.World.folder())
	local R = H.roblox
	local function keyOf(m)
		local k = m:GetAttribute("PropKey")
		return type(k) == "string" and k or m.Name
	end
	-- placeholders
	local holders = {}
	local phOf = {}
	for _, d in root:GetDescendants() do
		if d:IsA("Model") and Props.Models[keyOf(d)] then
			local okP, piv = pcall(function() return d.WorldPivot end)
			if not okP then piv = R.CFrame.new() end
			local look = piv.LookVector
			local frame = R.CFrame.new(piv.Position) * R.CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
			local mn, mx
			for _, p in d:GetDescendants() do
				if p:IsA("BasePart") and p.Transparency < 0.99 then
					local half = p.Size / 2
					for _, sx in { -1, 1 } do
						for _, sy in { -1, 1 } do
							for _, sz in { -1, 1 } do
								local w = frame:PointToObjectSpace(p.CFrame:PointToWorldSpace(R.Vector3.new(sx * half.X, sy * half.Y, sz * half.Z)))
								mn = mn and R.Vector3.new(math.min(mn.X, w.X), math.min(mn.Y, w.Y), math.min(mn.Z, w.Z)) or w
								mx = mx and R.Vector3.new(math.max(mx.X, w.X), math.max(mx.Y, w.Y), math.max(mx.Z, w.Z)) or w
							end
						end
					end
				end
			end
			if mn then
				local e = Props.Models[keyOf(d)]
				table.insert(holders, { key = keyOf(d), name = d.Name, entry = type(e) == "number" and { Id = e } or e, frame = { frame:GetComponents() }, min = { mn.X, mn.Y, mn.Z }, max = { mx.X, mx.Y, mx.Z } })
			end
		end
	end
	-- parts (the reel renderer's format)
	local parts, lights = {}, {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.98 then
			local shape = "Block"
			if d.ClassName == "WedgePart" then shape = "Wedge" elseif d.ClassName == "Part" then shape = d.Shape.Name end
			local mesh = d:FindFirstChildOfClass("SpecialMesh")
			table.insert(parts, {
				n = d.Name, sh = shape, s = { d.Size.X, d.Size.Y, d.Size.Z }, c = { d.CFrame:GetComponents() },
				col = { math.floor(d.Color.R * 255), math.floor(d.Color.G * 255), math.floor(d.Color.B * 255) },
				mat = d.Material.Name, tr = d.Transparency,
				art = d:GetAttribute("ArtDecal"), -- (a painting or poster: the decal World/Props puts on its front)
				m = mesh and { t = mesh.MeshType.Name, s = { mesh.Scale.X, mesh.Scale.Y, mesh.Scale.Z }, o = { mesh.Offset.X, mesh.Offset.Y, mesh.Offset.Z } } or nil,
				ph = (function()
					local a = d.Parent
					while a and a ~= root do
						if a:IsA("Model") and Props.Models[keyOf(a)] then
							return keyOf(a)
						end
						a = a.Parent
					end
					return nil
				end)(),
			})
		elseif (d:IsA("PointLight") or d:IsA("SpotLight")) and d.Enabled and d.Parent and d.Parent:IsA("BasePart") then
			local p = d.Parent.CFrame.Position
			table.insert(lights, { p = { p.X, p.Y, p.Z }, col = { d.Color.R, d.Color.G, d.Color.B }, r = d.Range, b = d.Brightness })
		end
	end
	fs.writeFile(out, serde.encode("json", { parts = parts, lights = lights, holders = holders }))
	print("stage:", #parts, "parts,", #holders, "placeholders ->", out)
	for _, h in holders do print("  ", h.key, h.entry.Id, ("%.1f x %.1f x %.1f"):format(h.max[1] - h.min[1], h.max[2] - h.min[2], h.max[3] - h.min[3])) end
end)
print(ok and "STAGE OK" or ("STAGE FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
