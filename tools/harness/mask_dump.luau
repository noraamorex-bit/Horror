-- mask_dump.luau <out.json> — (v114) the porcelain mask and wet hair the skinned creature wears, as the server
-- builds them (Rig.build + Rig.MaskParts): every part's look and its frame relative to the Head part, the Head
-- part's rest frame (model space, Rig.MaskOffset applied) and the body's tint. tools/creature/skin_frames.luau
-- reads it to put the mask on the posed head for the reels (film2). Run from tools/harness.
local H = require("./env")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")
local ok, err = pcall(function()
	local Builder = H.load("Server/World/Builder")
	local Rig = H.load("Server/Intruder/Rig")
	local m = H.unwrap(Rig.build(Builder))
	local head = m:FindFirstChild("Head")
	local keep = Rig.maskLayout(m)
	local list = { head }
	for p in keep do
		if p ~= head then
			table.insert(list, p)
		end
	end
	local function c12(cf)
		local c = { cf:GetComponents() }
		for j = 1, 12 do c[j] = math.floor(c[j] * 100000 + 0.5) / 100000 end
		return c
	end
	local parts, rel = {}, {}
	for _, d in list do
		local shape = "Block"
		if d.ClassName == "WedgePart" then shape = "Wedge" elseif d.ClassName == "Part" then shape = d.Shape.Name end
		local mesh = d:FindFirstChildOfClass("SpecialMesh")
		table.insert(parts, {
			n = d.Name, sh = shape, s = { d.Size.X, d.Size.Y, d.Size.Z },
			col = { math.floor(d.Color.R * 255), math.floor(d.Color.G * 255), math.floor(d.Color.B * 255) },
			mat = d.Material.Name, tr = 0,
			m = mesh and { t = mesh.MeshType.Name, s = { 1, 1, 1 }, o = { 0, 0, 0 } } or nil,
		})
		table.insert(rel, c12(head.CFrame:Inverse() * d.CFrame))
	end
	local o = Rig.MaskOffset
	local t = Rig.SkinColor
	fs.writeFile(process.args[1], serde.encode("json", {
		parts = parts, rel = rel, head = c12(head.CFrame + o),
		color = { math.floor(t.R * 255 + 0.5), math.floor(t.G * 255 + 0.5), math.floor(t.B * 255 + 0.5) },
	}))
	print("MASK", #parts, "parts")
end)
if not ok then print("FAIL", err) end
