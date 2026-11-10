--[[
	Surfaces (v153, the owner after a playthrough: screenshots of a knitted-looking beanbag, nightstand and pizza
	shirt, and of striped pendant shades: "so many models that are bugged"). Two things fixed for every part that
	appears in the world, ours or a Creator Store model's, in the lobby or the house:
	  • Roblox's Fabric material renders as chunky knitted wool. Rugs become Carpet; everything else (sofas,
	    cushions, bedding, curtains, wallpaper, clothes) a smooth matte finish in the same colour.
	  • Lamp shades don't cast shadows: a bulb inside one threw radial streaks across its inside.
]]

local Players = game:GetService("Players")

local Surfaces = {}

local RUG = { "Rug", "Carpet", "Runner", "DoorMat", "Doormat", "BathMat" }

local function isRug(name: string): boolean
	if string.find(name, "Mattress") then
		return false
	end
	for _, k in RUG do
		if string.find(name, k) then
			return true
		end
	end
	return false
end

local function playerOwned(p: Instance): boolean
	local model = p:FindFirstAncestorOfClass("Model")
	while model do
		local ok, owner = pcall(function()
			return Players:GetPlayerFromCharacter(model)
		end)
		if ok and owner then
			return true
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return false
end

function Surfaces.fix(p: Instance)
	if not p:IsA("BasePart") then
		return
	end
	if p.Material == Enum.Material.Fabric and not playerOwned(p) then
		local m = p:FindFirstAncestorOfClass("Model")
		p.Material = (isRug(p.Name) or (m and isRug(m.Name))) and Enum.Material.Carpet or Enum.Material.SmoothPlastic
	end
	if string.find(p.Name, "Shade") then
		p.CastShadow = false
	end
end

function Surfaces.sweep(root: Instance)
	for _, d in root:GetDescendants() do
		Surfaces.fix(d)
	end
end

-- everything already there, and everything added later (a material set after parenting is caught on the defer)
function Surfaces.watch()
	Surfaces.sweep(workspace)
	workspace.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			task.defer(Surfaces.fix, d)
		end
	end)
end

return Surfaces
