-- lune run avatar_items.luau <cacheDir> <id>...  -> <cacheDir>/<id>.json for each catalog item:
-- a face (its decal texture), a shirt / pants (the template image), an accessory (the handle's mesh,
-- texture, size and its attachment). Used to dress film2's Roblox avatars in real catalog items.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local process = require("@lune/process")

local dir = process.args[1]
local function content(v)
	if v == nil then return nil end
	local s = tostring(v)
	return string.match(s, "rbxassetid://(%d+)") or string.match(s, "[?&]id=(%d+)") or string.match(s, "^(%d+)$")
end
local function get(inst, prop)
	local ok, v = pcall(function() return inst[prop] end)
	return ok and v or nil
end
local function cf(c) return c and { c:GetComponents() } or nil end
for i = 2, #process.args do
	local id = process.args[i]
	local roots = roblox.deserializeModel(fs.readFile(dir .. "/" .. id .. ".bin"))
	local out = { id = id }
	for _, root in roots do
		local list = { root }
		for _, d in root:GetDescendants() do table.insert(list, d) end
		for _, d in list do
			if d:IsA("Decal") then out.kind = "face"; out.texture = content(get(d, "Texture") or get(d, "TextureContent"))
			elseif d.ClassName == "Shirt" then out.kind = "shirt"; out.texture = content(get(d, "ShirtTemplate") or get(d, "ShirtTemplateContent"))
			elseif d.ClassName == "Pants" then out.kind = "pants"; out.texture = content(get(d, "PantsTemplate") or get(d, "PantsTemplateContent"))
			elseif d:IsA("Accessory") then out.kind = "accessory"; out.name = d.Name
			elseif d:IsA("BasePart") and d.Name == "Handle" then
				out.size = { d.Size.X, d.Size.Y, d.Size.Z }
				if d:IsA("MeshPart") then
					out.mesh = content(get(d, "MeshId") or get(d, "MeshContent")); out.texture = content(get(d, "TextureID") or get(d, "TextureContent"))
					local ms = get(d, "MeshSize"); out.meshSize = ms and { ms.X, ms.Y, ms.Z } or nil
				end
			elseif d.ClassName == "SpecialMesh" then
				out.mesh = content(get(d, "MeshId") or get(d, "MeshContent")); out.texture = content(get(d, "TextureId") or get(d, "TextureContent"))
				out.scale = { d.Scale.X, d.Scale.Y, d.Scale.Z }; out.offset = { d.Offset.X, d.Offset.Y, d.Offset.Z }
			elseif d:IsA("Attachment") and d.Parent and d.Parent.Name == "Handle" then
				out.attachment = d.Name; out.attachCF = cf(d.CFrame)
			end
		end
	end
	fs.writeFile(dir .. "/" .. id .. ".json", serde.encode("json", out, true))
	print(id, out.kind, out.name or "", out.mesh or "", out.texture or "", out.attachment or "")
end
