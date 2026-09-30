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
local function fit(placeholder: Model, assetId: number)
	local tpl = template(assetId)
	if not tpl or not placeholder.Parent or placeholder:GetAttribute("PropSwapped") then
		return
	end
	local okBox, cf, size = pcall(function()
		return placeholder:GetBoundingBox()
	end)
	if not okBox then
		return
	end
	-- the placeholder's own orientation (its pivot), centred on its box
	local pivot = placeholder:GetPivot()
	local base = CFrame.new(cf.Position) * (pivot - pivot.Position)
	local prop = tpl:Clone()
	prop.Name = "Prop"
	local bcf, bsize = prop:GetBoundingBox()
	prop.WorldPivot = bcf
	local horiz = math.max(size.X, size.Z) / math.max(bsize.X, bsize.Z, 0.01)
	local vert = size.Y / math.max(bsize.Y, 0.01)
	local s = math.clamp(FLAT[placeholder.Name] and horiz or math.min(horiz, vert), 0.02, 50)
	pcall(function()
		prop:ScaleTo(prop:GetScale() * s)
	end)
	local _, nsize = prop:GetBoundingBox()
	-- stand it on the placeholder's base
	prop:PivotTo(base * CFrame.new(0, -size.Y / 2 + nsize.Y / 2, 0))
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

local function consider(inst: Instance)
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
