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

-- Put the loaded model where the placeholder is, as big as it is. Creators build their models
-- upright in the world, but the model's own pivot is often turned (that's what laid the plates
-- and the fruit bowl on their sides): so the model keeps its authored world orientation, and
-- only turns about the vertical to match the placeholder.
local function fit(placeholder: Model, assetId: number)
	local tpl = template(assetId)
	if not tpl or not placeholder.Parent or placeholder:GetAttribute("PropSwapped") then
		return
	end
	local pmn, pmx = worldBox(placeholder)
	if not pmn or not pmx then
		return
	end
	local size = pmx - pmn
	local centre = (pmn + pmx) / 2
	local look = placeholder:GetPivot().LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local prop = tpl:Clone()
	prop.Name = "Prop"
	local bmn, bmx = worldBox(prop)
	if not bmn or not bmx then
		prop:Destroy()
		return
	end
	local bsize = bmx - bmn
	prop.WorldPivot = CFrame.new((bmn + bmx) / 2)
	local horiz = math.max(size.X, size.Z) / math.max(bsize.X, bsize.Z, 0.01)
	local vert = size.Y / math.max(bsize.Y, 0.01)
	local s = math.clamp(FLAT[placeholder.Name] and horiz or math.min(horiz, vert), 0.02, 50)
	pcall(function()
		prop:ScaleTo(prop:GetScale() * s)
	end)
	local nmn, nmx = worldBox(prop)
	local h = (nmn and nmx) and (nmx.Y - nmn.Y) or bsize.Y * s
	-- stand it on the placeholder's base, turned only about the vertical
	prop:PivotTo(CFrame.new(centre.X, pmn.Y + h / 2, centre.Z) * CFrame.Angles(0, yaw, 0))
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
		local id = Props.Models[inst.Name]
		if id then
			task.spawn(fit, inst, id)
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
