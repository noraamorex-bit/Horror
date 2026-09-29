--[[
	Textures — tiled image textures laid over the house's surfaces (wallpaper, hardwood,
	tile, carpet). Every image is a public Creator Store image; the Texture's Color3 tints it
	to fit each room. Parts keep their own material underneath, so if an image ever fails to
	load the surface still looks right.
]]

local Textures = {}

Textures.Id = {
	Damask = "rbxassetid://186378148",
	Stripes = "rbxassetid://2182184288",
	Floral = "rbxassetid://395734636",
	Roses = "rbxassetid://485870294",
	WoodDark = "rbxassetid://833817091",
	Parquet = "rbxassetid://475038838",
	TileWhite = "rbxassetid://748527930",
	Marble = "rbxassetid://958260983",
	Carpet = "rbxassetid://854737488",
}

-- how many studs one repeat of each image covers
Textures.Scale = {
	Damask = 5, Stripes = 4, Floral = 6, Roses = 5,
	WoodDark = 9, Parquet = 8, TileWhite = 3, Marble = 7, Carpet = 6,
}

--[[ Put `key` on the given faces of `part`, tinted by `color`. ]]
function Textures.apply(part: BasePart, key: string, faces: { Enum.NormalId }, color: Color3?, transparency: number?)
	local id = Textures.Id[key]
	if not id then
		return
	end
	local scale = Textures.Scale[key] or 6
	for _, face in faces do
		local t = Instance.new("Texture")
		t.Name = "Tex_" .. key
		t.Texture = id
		t.Face = face
		t.StudsPerTileU = scale
		t.StudsPerTileV = scale
		t.Color3 = color or Color3.new(1, 1, 1)
		t.Transparency = transparency or 0
		t.Parent = part
	end
end

return Textures
