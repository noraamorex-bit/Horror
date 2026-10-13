--[[
	Props — swaps some of the hand-built small props for nicer free models from the Creator Store.

	The level is built from parts first (Kit), so everything works even if a model can't load.
	Then, in the background, each placeholder model with a name listed below gets the Creator
	Store model loaded into it (AssetService:LoadAssetAsync, allowed by the place setting
	AllowInsertFreeAssets, see tools/place_flags.py), scaled to fit the placeholder's size and
	sat on the same spot. The placeholder's own parts turn invisible but stay, so prompts,
	lights and particles on them keep working.

	Every model is stripped of scripts, sounds and physics before use.
]]

local AssetService = game:GetService("AssetService")

local Props = {}

-- placeholder model name -> Creator Store model (free, public)
Props.Models = {
	PopcornBowl = 5500390682, -- "Bowl of Popcorn" (NightBawnana)
	BrokenPlate = 105938394147326, -- "Broken Plate 2" (Mental_Name)
	Plate = 8279305093, -- "Dinner Plate" (5vx7)
	Mug = 90427741343379, -- a mug with a hot drink
	FruitBowl = 16177301112, -- wooden bowl of fruit
	Pumpkin = 11600489662, -- a plain pumpkin
	Flowers = 5675479692, -- pink flowers in a white vase
	Kettle = 17604332991, -- stovetop kettle
	-- furniture (front = -Z after Yaw; checked with tools/assets/preview.mjs and stage.mjs)
	Sofa = { Id = 11290198233, Yaw = 0 }, -- "Couch (Old Sofa)": a patterned three-seater, cushions
	DenSofa = { Id = 14393549681, Yaw = 0, Fit = "width" }, -- "Realistic Sofa": worn brown leather, taped up (a two-seater: as wide as the old one)
	Armchair = { Id = 11213986020, Yaw = 180 }, -- "Regal_Chair": a wingback (built facing +Z)
	Bookcase = { Id = 15077805709, Yaw = 0, Fit = "width", Back = true }, -- "Bookshelf (For Libraries)": painted books, four shelves
	OfficeBookcase = { Id = 9914694425, Yaw = 0, Fit = "width", Back = true }, -- "Bookshelf (With Books)": tall, two columns of old books
	DiningChair = { Id = 17056776920, Yaw = 180 }, -- "Wooden Chair (Doors)" (built facing +Z)
	DadChair = { Id = 17056797478, Yaw = 180 }, -- "Office Chair (Doors)": old leather, swivel (built facing +Z)
	Plant_tree = { Id = 8704290264, Yaw = 0 }, -- a palm in a clay pot
	Plant_leafy = { Id = 14278794019, Yaw = 0 }, -- a monstera on a wooden stand
	Plant_snake = { Id = 10508319719, Yaw = 0 }, -- a spiky dracaena in a tall white pot
}

-- flat things are fitted by their width only (a scattered heap of shards is only a few
-- hundredths of a stud tall)
local FLAT = { BrokenPlate = true, Plate = true }

local cache = {} -- assetId -> Model template | false (failed)
local loading = {} -- assetId -> true while a load is in flight

local STRIP = { "Script", "LocalScript", "ModuleScript", "Sound", "ProximityPrompt", "ClickDetector", "Tool", "Humanoid", "Light", "Constraint", "JointInstance", "WeldConstraint", "BodyMover" }

local function strip(root: Instance)
	for _, d in root:GetDescendants() do
		for _, cls in STRIP do
			if d:IsA(cls) then
				d:Destroy()
				break
			end
		end
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
			d.Massless = true
		end
	end
end

local function template(assetId: number): Model?
	if cache[assetId] ~= nil then
		return cache[assetId] or nil
	end
	while loading[assetId] do
		task.wait(0.2)
	end
	if cache[assetId] ~= nil then
		return cache[assetId] or nil
	end
	loading[assetId] = true
	local ok, container = pcall(function()
		return (AssetService :: any):LoadAssetAsync(assetId)
	end)
	loading[assetId] = nil
	if not ok or not container then
		cache[assetId] = false
		return nil
	end
	local model = Instance.new("Model")
	model.Name = "Prop" .. assetId
	for _, c in (container :: Instance):GetChildren() do
		c.Parent = model
	end
	strip(model)
	local parts = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	if parts == 0 then
		cache[assetId] = false
		return nil
	end
	cache[assetId] = model
	return model
end

-- put the loaded model where the placeholder is, as big as it is
-- the world-space box around a model's visible parts (min corner, max corner)
local function worldBox(model: Instance): (Vector3?, Vector3?)
	local mn, mx
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.99 then
			local cf, sz = d.CFrame, d.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz2 in { -1, 1 } do
						local p = cf:PointToWorldSpace(Vector3.new(sx * sz.X, sy * sz.Y, sz2 * sz.Z))
						mn = mn and mn:Min(p) or p
						mx = mx and mx:Max(p) or p
					end
				end
			end
		end
	end
	return mn, mx
end

-- the lowest point of the prop's actual geometry around the middle of its footprint, and the top of
-- whatever it stands on; then move it so the one rests on the other
local function settle(prop: Model, placeholder: Model, centre: Vector3, size: Vector3)
	local parts = {}
	for _, d in prop:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			d.CanQuery = true -- (just while measuring)
		end
	end
	local up = RaycastParams.new()
	up.FilterType = Enum.RaycastFilterType.Include
	up.FilterDescendantsInstances = { prop }
	local low = math.huge
	local rx, rz = size.X * 0.25, size.Z * 0.25
	for _, o in { Vector3.zero, Vector3.new(rx, 0, 0), Vector3.new(-rx, 0, 0), Vector3.new(0, 0, rz), Vector3.new(0, 0, -rz) } do
		local from = Vector3.new(centre.X + o.X, centre.Y - size.Y - 2, centre.Z + o.Z)
		local hit = workspace:Raycast(from, Vector3.new(0, size.Y * 3 + 4, 0), up)
		if hit then
			low = math.min(low, hit.Position.Y)
		end
	end
	local down = RaycastParams.new()
	down.FilterType = Enum.RaycastFilterType.Exclude
	down.FilterDescendantsInstances = { prop, placeholder }
	local floor = workspace:Raycast(Vector3.new(centre.X, centre.Y + size.Y, centre.Z), Vector3.new(0, -(size.Y * 2 + 3), 0), down)
	for _, d in parts do
		d.CanQuery = false
	end
	if low < math.huge and floor then
		local dy = floor.Position.Y + 0.01 - low
		if math.abs(dy) < 1.5 then
			prop:PivotTo(prop:GetPivot() + Vector3.new(0, dy, 0))
		end
	end
end

-- the box around a model's visible parts in a frame's own axes (min, max)
local function localBox(model: Instance, frame: CFrame): (Vector3?, Vector3?)
	local mn, mx
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.99 then
			local cf, sz = d.CFrame, d.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz2 in { -1, 1 } do
						local p = frame:PointToObjectSpace(cf:PointToWorldSpace(Vector3.new(sx * sz.X, sy * sz.Y, sz2 * sz.Z)))
						mn = mn and mn:Min(p) or p
						mx = mx and mx:Max(p) or p
					end
				end
			end
		end
	end
	return mn, mx
end
Props._localBox = localBox

-- Props.Models entries: an asset id, or { Id, Yaw = degrees (turns the model about the vertical
-- so its front faces -Z, the way our furniture faces), Fit = "inside" (default: as big as fits
-- inside the placeholder's box) | "width" (as wide as the placeholder, height allowed 25% over),
-- Back = true (its back lines up with the placeholder's back: against a wall, a deeper model
-- reaches into the room instead of into the wall) }
local function entryOf(v: any): any
	if type(v) == "number" then
		return { Id = v }
	end
	return v
end

-- Put the loaded model where the placeholder is, in the placeholder's frame. Creators build their
-- models upright in the world but rarely facing a known way, so each entry says how far to turn it
-- (checked with tools/assets/preview.mjs); furniture from Kit carries its frame as its WorldPivot
-- (front = local -Z). Then it's scaled to the placeholder's box and stood on the floor under it.
local function fit(placeholder: Model, raw: any)
	local entry = entryOf(raw)
	local tpl = template(entry.Id)
	if not tpl or not placeholder.Parent or placeholder:GetAttribute("PropSwapped") then
		return
	end
	-- (upright only: its turn about the vertical, from where it looks. Not ToOrientation, whose Y
	-- comes out 0 for a frame turned right round, as (180, 0, 180))
	local pivot = placeholder:GetPivot()
	local look = pivot.LookVector
	local frame = CFrame.new(pivot.Position) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
	local pmn, pmx = localBox(placeholder, frame)
	if not pmn or not pmx then
		return
	end
	local psize = pmx - pmn
	local prop = tpl:Clone()
	prop.Name = "Prop"
	-- 1. turn it about its own centre so its front faces -Z
	local bmn, bmx = worldBox(prop)
	if not bmn or not bmx then
		prop:Destroy()
		return
	end
	prop.WorldPivot = CFrame.new((bmn + bmx) / 2)
	prop:PivotTo(prop.WorldPivot * CFrame.Angles(0, math.rad(entry.Yaw or 0), 0))
	bmn, bmx = worldBox(prop)
	if not bmn or not bmx then
		prop:Destroy()
		return
	end
	prop.WorldPivot = CFrame.new((bmn + bmx) / 2)
	local bsize = bmx - bmn
	-- 2. its size
	local rx, ry, rz = psize.X / math.max(bsize.X, 0.01), psize.Y / math.max(bsize.Y, 0.01), psize.Z / math.max(bsize.Z, 0.01)
	local s
	if FLAT[placeholder.Name] then
		s = math.max(rx, rz)
	elseif entry.Fit == "width" then
		s = math.min(rx, ry * 1.25)
	else
		s = math.min(rx, ry, rz)
	end
	s = math.clamp(s, 0.02, 50)
	pcall(function()
		prop:ScaleTo(prop:GetScale() * s)
	end)
	local nmn, nmx = worldBox(prop)
	local h = (nmn and nmx) and (nmx.Y - nmn.Y) or bsize.Y * s
	-- 3. in the placeholder's frame: centred on its footprint, standing on its base
	local c = (pmn + pmx) / 2
	local cz = c.Z
	if entry.Back then
		local lmn, lmx = localBox(prop, prop.WorldPivot)
		local d = (lmn and lmx) and (lmx.Z - lmn.Z) or bsize.Z * s
		cz = pmx.Z - d / 2
	end
	local at = frame:PointToWorldSpace(Vector3.new(c.X, pmn.Y + h / 2, cz))
	prop:PivotTo(CFrame.new(at) * frame.Rotation)
	-- 4. then sit it exactly on the surface under it: a model's box isn't always where its mesh is
	local wmn, wmx = worldBox(placeholder)
	settle(prop, placeholder, at, (wmn and wmx) and (wmx - wmn) or psize)
	for _, d in placeholder:GetDescendants() do
		if d:IsA("BasePart") then
			d.Transparency = 1
			d.CastShadow = false
		elseif d:IsA("Decal") or d:IsA("Texture") then
			d.Transparency = 1
		end
	end
	placeholder:SetAttribute("PropSwapped", true)
	prop.Parent = placeholder
end
Props._fit = fit

-- Paintings: a canvas part with an "ArtDecal" attribute (World/Finish) gets the decal's picture
local textures = {} -- decal asset id -> image content id | false
local function decalTexture(assetId: number): string?
	if textures[assetId] ~= nil then
		return textures[assetId] or nil
	end
	while loading[assetId] do
		task.wait(0.2)
	end
	if textures[assetId] ~= nil then
		return textures[assetId] or nil
	end
	loading[assetId] = true
	local ok, container = pcall(function()
		return (AssetService :: any):LoadAssetAsync(assetId)
	end)
	loading[assetId] = nil
	local tex = nil
	if ok and container then
		local d = (container :: Instance):FindFirstChildWhichIsA("Decal", true)
		if d and d.Texture ~= "" then
			tex = d.Texture
		end
		(container :: Instance):Destroy()
	end
	textures[assetId] = tex or false
	return tex
end

local function paint(canvas: BasePart)
	-- (a string: numeric attributes can't be trusted to keep every digit of a long asset id)
	local id = tonumber(canvas:GetAttribute("ArtDecal"))
	if not id then
		return
	end
	local tex = decalTexture(id)
	if not tex or not canvas.Parent then
		return
	end
	local face = canvas:GetAttribute("ArtFace")
	local decal = Instance.new("Decal")
	decal.Name = "Art"
	decal.Texture = tex
	decal.Face = (Enum.NormalId :: any)[type(face) == "string" and face or "Front"]
	-- a touch of age on the varnish
	decal.Color3 = Color3.fromRGB(235, 228, 212)
	decal.Parent = canvas
end

local function consider(inst: Instance)
	if inst:IsA("BasePart") and inst:GetAttribute("ArtDecal") then
		task.spawn(paint, inst)
		return
	end
	if inst:IsA("Model") and inst.Name ~= "Prop" and not inst:FindFirstAncestor("Prop") then
		-- (a placement can name its own model: the den's sofa isn't the living room's)
		local key = inst:GetAttribute("PropKey")
		local entry = Props.Models[type(key) == "string" and key or inst.Name]
		if entry then
			task.spawn(fit, inst, entry)
		end
	end
end

-- swap everything under root now, and anything placed there later (the popcorn on the coffee
-- table, the broken plate on the kitchen floor)
function Props.watch(root: Instance)
	for _, d in root:GetDescendants() do
		consider(d)
	end
	root.DescendantAdded:Connect(function(d)
		-- let the builder finish filling the model first
		task.defer(consider, d)
	end)
end

return Props
