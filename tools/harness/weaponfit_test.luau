-- weaponfit_test (v166): the rolled weapons' meshes. shared/WeaponFit turns a model into the tool's frame (grip at the origin, a blade
-- up +Y, a gun ahead -Z, Len studs long, Pre straightens a crooked one); ToolService welds the fitted copy onto the handle (the
-- glove keeps a Palm box for its slap) and falls back to the block model when no mesh loaded; every weapon has a Model spec.
local H = require("./env")
local R = H.roblox
local V, CF = R.Vector3.new, R.CFrame.new
local Fit = H.load("RS/Shared/WeaponFit")
local Config = H.load("RS/Shared/Config")

local function near(a, b, e) return math.abs(a - b) < (e or 0.02) end
local ok, err = pcall(function()
	-- a 1 x 1 x 6 stick along Z, its tip at +Z, held at the -Z end
	local boxes = { { CFrame = CF(10, 3, -4), Size = V(1, 1, 6) } }
	local map, k = Fit.solve(boxes, { Axis = "Z", Tip = 1, Len = 3, Grip = { 0, 0, -1 } })
	assert(near(k, 0.5), "scaled to Len: " .. k)
	local cf = map(boxes[1].CFrame)
	assert(near(cf.Position.X, 0) and near(cf.Position.Y, 1.5) and near(cf.Position.Z, 0), "stands up from the hand: " .. tostring(cf.Position))
	local mn, mx = Fit.bounds({ { CFrame = cf, Size = boxes[1].Size * k } })
	assert(near(mn.Y, 0) and near(mx.Y, 3) and near(mx.X - mn.X, 0.5), "0 to Len up +Y")
	-- the same stick as a gun, tip at -Z: points ahead, untouched
	local gmap = Fit.solve(boxes, { Axis = "Z", Tip = -1, Len = 6, Grip = { 0, 0, 1 }, Gun = true })
	local g = gmap(boxes[1].CFrame)
	assert(near(g.Position.Z, -3) and near(g.Position.Y, 0), "a gun reaches ahead: " .. tostring(g.Position))
	-- tip at +Z as a gun: turned round
	local g2 = Fit.solve(boxes, { Axis = "Z", Tip = 1, Len = 6, Grip = { 0, 0, -1 }, Gun = true })(boxes[1].CFrame)
	assert(near(g2.Position.Z, -3), "turned round to point ahead: " .. tostring(g2.Position))
	-- Pre: a stick leaning 90 degrees (along Z) straightened up first, then measured along Y
	local pmap, pk = Fit.solve(boxes, { Axis = "Y", Tip = 1, Len = 6, Grip = { 0, -1, 0 }, Pre = { 90, 0, 0 } })
	local p = pmap(boxes[1].CFrame)
	assert(near(pk, 1) and near(p.Position.Y, 3), "Pre straightens before measuring: " .. tostring(p.Position) .. " k " .. pk)
	-- every weapon has a sane spec
	for _, item in Config.Weapons.Order do
		local m = Config.Weapons.List[item].Model
		assert(m and type(m.Id) == "number" and m.Len > 0.5 and m.Len < 8 and (m.Axis == "X" or m.Axis == "Y" or m.Axis == "Z") and math.abs(m.Tip) == 1, item .. ": a Model spec")
	end

	-- ToolService: a fitted mesh is welded on, the block model otherwise
	local ctx: any = { Config = Config, WeaponFit = Fit }
	local Tools = H.load("Server/Services/ToolService")
	Tools.init(ctx)
	local blocks = Tools._build("Katana")
	assert(blocks:FindFirstChild("Blade"), "no mesh loaded: the block katana")
	local m = H.Instance.new("Model")
	local blade = H.Instance.new("Part", m)
	blade.Name = "Sword"
	blade.Size = V(0.2, 4, 0.4)
	blade.CFrame = CF(0, 2.2, 0)
	Tools._fitted.Katana = m
	local t = Tools._build("Katana")
	local handle = t:FindFirstChild("Handle")
	local sword = t:FindFirstChild("Sword")
	assert(sword and not t:FindFirstChild("Blade"), "the mesh, not the blocks")
	assert(handle.Transparency == 1, "the handle hides")
	assert(near((sword.CFrame.Position - handle.CFrame.Position).Y, 2.2) and sword:FindFirstChildOfClass("WeldConstraint"), "welded where it was fitted")
	local gm = H.Instance.new("Model")
	local glove = H.Instance.new("Part", gm)
	glove.Size = V(1, 2, 1.5)
	glove.CFrame = CF(0, 1, 0)
	Tools._fitted.SlapGlove = gm
	local gt = Tools._build("SlapGlove")
	local palm = gt:FindFirstChild("Palm")
	assert(palm and palm.Transparency == 1 and near(palm.Size.Y, 2) and near(palm.CFrame.Position.Y, 1), "the glove keeps a Palm box for its slap")
	print("weaponfit ok")
end)
local errs = {}
for _, e in H.errors do table.insert(errs, tostring(e)) end
print(ok and (#errs == 0 and "WEAPONFIT OK" or "WEAPONFIT FAIL: errors") or ("WEAPONFIT FAIL: " .. tostring(err)))
for _, e in errs do print(e:sub(1, 400)) end
