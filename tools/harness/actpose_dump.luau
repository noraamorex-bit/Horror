-- actpose_dump: the action poses' joint positions (LowerTorso space, a standard R15) for
-- tools/creature/actpose_view.py. usage: lune run actpose_dump.luau out.json
local H = require("./env")
local AP = H.load("RS/Shared/ActPose")
local fs = require("@lune/fs")
local process = require("@lune/process")
local CFrame = H.roblox.CFrame
local rig = AP.StandardRig
local function p3(v) return { v.X, v.Y, v.Z } end
local out = {}
local kinds = {}
for k in AP.Kinds do table.insert(kinds, k) end
table.sort(kinds)
for _, kind in kinds do
	local def = AP.Kinds[kind]
	for _, fp in { false, true } do
		local t = def.Hold and 0.55 or def.Time * 0.45
		local tg = AP.targets(kind, t, fp)
		local tr = AP.solve(rig, tg)
		local upper = rig.Waist.C0 * (tr.Waist or CFrame.identity) * rig.Waist.C1:Inverse()
		local head = upper * rig.Neck.C0 * (tr.Neck or CFrame.identity) * rig.Neck.C1:Inverse()
		local e = { kind = kind, fp = fp, upper = { p3(upper.Position), p3(upper.UpVector), p3(upper.LookVector) }, head = { p3(head.Position), p3(head.LookVector) } }
		for _, side in { "R", "L" } do
			local S, E, W = rig[side .. "S"], rig[side .. "E"], rig[side .. "W"]
			local sh = side == "R" and "RightShoulder" or "LeftShoulder"
			local el = side == "R" and "RightElbow" or "LeftElbow"
			local wr = side == "R" and "RightWrist" or "LeftWrist"
			local ua = upper * S.C0 * (tr[sh] or CFrame.identity) * S.C1:Inverse()
			local la = ua * E.C0 * (tr[el] or CFrame.identity) * E.C1:Inverse()
			local hand = la * W.C0 * (tr[wr] or CFrame.identity) * W.C1:Inverse()
			e[side] = { p3((upper * S.C0).Position), p3((ua * E.C0).Position), p3((la * W.C0).Position), p3((hand * CFrame.new(0, -0.15, 0)).Position) }
		end
		table.insert(out, e)
	end
end
fs.writeFile(process.args[1], H.json and H.json(out) or require("@lune/serde").encode("json", out))
print("wrote", #out)
