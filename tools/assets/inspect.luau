-- lune run tools/assets/inspect.luau <model.bin> <out.json>
-- A downloaded model (rbxm) → JSON for checking and rendering: every part's class, size, CFrame,
-- colour, material, transparency, mesh (MeshPart MeshId / SpecialMesh) and textures, plus the
-- model's bounding box and anything that would need stripping (scripts, sounds, lights...).
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local process = require("@lune/process")

local path, out = process.args[1], process.args[2]
local roots = roblox.deserializeModel(fs.readFile(path))

local function get(inst, prop)
	local ok, v = pcall(function()
		return inst[prop]
	end)
	return ok and v or nil
end
local function v3(v)
	return v and { v.X, v.Y, v.Z } or nil
end
local function cf(c)
	if not c then
		return nil
	end
	local comps = { c:GetComponents() }
	return comps
end
-- "rbxassetid://123", "http://www.roblox.com/asset/?id=123" or Content(Uri=...) → "123"
local function content(v)
	if v == nil then
		return nil
	end
	local s = tostring(v)
	local id = string.match(s, "rbxassetid://(%d+)") or string.match(s, "[?&]id=(%d+)") or string.match(s, "^(%d+)$")
	if id then
		return id
	end
	return (s ~= "" and not string.find(s, "None", 1, true)) and s or nil
end

local parts, extras = {}, {}
local minV, maxV = { math.huge, math.huge, math.huge }, { -math.huge, -math.huge, -math.huge }
for _, root in roots do
	local list = { root }
	for _, d in root:GetDescendants() do
		table.insert(list, d)
	end
	for _, d in list do
		if d:IsA("BasePart") then
			local p = {
				Class = d.ClassName,
				Name = d.Name,
				Size = v3(d.Size),
				CFrame = cf(d.CFrame),
				Color = d.Color and { math.floor(d.Color.R * 255), math.floor(d.Color.G * 255), math.floor(d.Color.B * 255) } or nil,
				Material = tostring(get(d, "Material")),
				Transparency = get(d, "Transparency"),
				Shape = d:IsA("Part") and tostring(get(d, "Shape")) or nil,
			}
			if d:IsA("MeshPart") then
				p.MeshId = content(get(d, "MeshId") or get(d, "MeshContent"))
				p.TextureID = content(get(d, "TextureContent") or get(d, "TextureID"))
				p.MeshId = content(get(d, "MeshContent") or get(d, "MeshId"))
				p.InitialSize = v3(get(d, "InitialSize"))
			end
			for _, c in d:GetChildren() do
				if c:IsA("SpecialMesh") then
					p.Special = { Type = tostring(c.MeshType), MeshId = content(c.MeshId), TextureId = content(c.TextureId), Scale = v3(c.Scale), Offset = v3(c.Offset) }
				elseif c:IsA("Decal") or c:IsA("Texture") then
					p.Decals = p.Decals or {}
					table.insert(p.Decals, { Class = c.ClassName, Face = tostring(c.Face), Texture = content(get(c, "Texture") or get(c, "ColorMapContent")) })
				elseif c.ClassName == "SurfaceAppearance" then
					p.Surface = {
						Color = content(get(c, "ColorMapContent") or get(c, "ColorMap")),
						Normal = content(get(c, "NormalMapContent") or get(c, "NormalMap")),
						Pack = content(get(c, "TexturePack")),
					}
				end
			end
			table.insert(parts, p)
			-- bounding box (corners of every part)
			local half = d.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local w = d.CFrame * roblox.Vector3.new(half.X * sx, half.Y * sy, half.Z * sz)
						minV = { math.min(minV[1], w.X), math.min(minV[2], w.Y), math.min(minV[3], w.Z) }
						maxV = { math.max(maxV[1], w.X), math.max(maxV[2], w.Y), math.max(maxV[3], w.Z) }
					end
				end
			end
		elseif not (d:IsA("Model") or d:IsA("Folder") or d:IsA("SpecialMesh") or d:IsA("Decal") or d:IsA("Texture") or d:IsA("Weld") or d:IsA("WeldConstraint") or d:IsA("Motor6D") or d.ClassName == "SurfaceAppearance") then
			extras[d.ClassName] = (extras[d.ClassName] or 0) + 1
		end
	end
end
local res = {
	Roots = #roots,
	RootClass = roots[1] and roots[1].ClassName,
	RootName = roots[1] and roots[1].Name,
	Parts = parts,
	Min = minV,
	Max = maxV,
	Size = { maxV[1] - minV[1], maxV[2] - minV[2], maxV[3] - minV[3] },
	Extras = extras,
}
if out then
	fs.writeFile(out, serde.encode("json", res))
end
print(("%s '%s': %d parts, size %.1f x %.1f x %.1f"):format(tostring(res.RootClass), tostring(res.RootName), #parts, res.Size[1], res.Size[2], res.Size[3]))
local meshes = 0
for _, p in parts do
	if p.MeshId or (p.Special and p.Special.MeshId) then
		meshes += 1
	end
end
print("meshes", meshes, "other:", serde.encode("json", extras))
