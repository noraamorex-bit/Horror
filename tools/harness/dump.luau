-- dump every visible BasePart under `root` into a compact JSON for the three.js previewer
local fs = require("@lune/fs")
local serde = require("@lune/serde")
return function(root, path, extraRoots)
	local out = {}
	local lights = {}
	local function walk(r)
		for _, d in r:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 0.98 then
				local cf = d.CFrame
				local c = { cf:GetComponents() }
				local shape = "Block"
				if d.ClassName == "WedgePart" then
					shape = "Wedge"
				elseif d.ClassName == "CornerWedgePart" then
					shape = "CornerWedge"
				elseif d.ClassName == "Part" then
					shape = d.Shape.Name
				elseif d.ClassName == "TrussPart" then
					shape = "Block"
				end
				local mesh = d:FindFirstChildOfClass("SpecialMesh")
				local m
				if mesh then
					m = { t = mesh.MeshType.Name, s = { mesh.Scale.X, mesh.Scale.Y, mesh.Scale.Z }, o = { mesh.Offset.X, mesh.Offset.Y, mesh.Offset.Z } }
				end
				local sg = d:FindFirstChildOfClass("SurfaceGui")
				local sgc
				if sg then
					local f = sg:FindFirstChildWhichIsA("GuiObject")
					if f then
						sgc = { f.BackgroundColor3.R, f.BackgroundColor3.G, f.BackgroundColor3.B, sg.Face.Name }
					end
				end
				table.insert(out, {
					n = d.Name,
					sh = shape,
					s = { d.Size.X, d.Size.Y, d.Size.Z },
					c = c,
					col = { math.floor(d.Color.R * 255), math.floor(d.Color.G * 255), math.floor(d.Color.B * 255) },
					mat = d.Material.Name,
					tr = d.Transparency,
					m = m,
					sg = sgc,
					art = d:GetAttribute("ArtDecal"),
				})
			elseif (d:IsA("PointLight") or d:IsA("SpotLight")) and d.Enabled and d.Parent and d.Parent:IsA("BasePart") then
				local p = d.Parent.CFrame.Position
				table.insert(lights, { p = { p.X, p.Y, p.Z }, col = { d.Color.R, d.Color.G, d.Color.B }, r = d.Range, b = d.Brightness })
			end
		end
	end
	walk(root)
	for _, r in extraRoots or {} do
		walk(r)
	end
	fs.writeFile(path, serde.encode("json", { parts = out, lights = lights }))
	print("dumped", #out, "parts", #lights, "lights ->", path)
end
