--[[
	WeaponFit (v166, the owner: "the weapon models look bad make it look much better and proper"). The rolled weapons are textured
	Creator Store meshes (Config.Weapons.List[k].Model); this turns one, as it was built, into the tool's frame: the grip at the
	origin, a blade / bat / glove standing up from it (+Y), a gun pointing ahead (-Z), scaled to Len studs along its length.
	Pure maths on { CFrame, Size } boxes, so the server (ToolService) and the check script (tools/assets/fit_weapon.luau) agree.

		spec = { Axis = "X"|"Y"|"Z",  -- the model's own axis its length runs along
		         Tip = 1 | -1,         -- which end of that axis is the tip (the barrel, the blade's point)
		         Len = studs,          -- its length in your hand
		         Grip = { x, y, z },   -- where the hand holds it, in the model's box: -1..1 of each half-extent
		         Spin = degrees,       -- a turn about its length (an axe's edge, a glove's palm, a gun's top: forward / up)
		         Gun = true?,          -- points ahead instead of standing up
		         Pre = { rx, ry, rz }? } -- degrees: a model built crooked, straightened first (the box is measured after)
		WeaponFit.solve(boxes, spec) -> map(cf) -> CFrame, k (the scale)
]]

local WeaponFit = {}

local AXES = { X = Vector3.new(1, 0, 0), Y = Vector3.new(0, 1, 0), Z = Vector3.new(0, 0, 1) }

-- the world box round a set of { CFrame, Size } boxes
function WeaponFit.bounds(boxes: { { CFrame: CFrame, Size: Vector3 } }): (Vector3, Vector3)
	local mn, mx = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, b in boxes do
		local h = b.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local p = b.CFrame:PointToWorldSpace(Vector3.new(sx * h.X, sy * h.Y, sz * h.Z))
					mn = mn:Min(p)
					mx = mx:Max(p)
				end
			end
		end
	end
	return mn, mx
end

-- the turn that takes direction a onto direction b
local function turn(a: Vector3, b: Vector3): CFrame
	local d = math.clamp(a:Dot(b), -1, 1)
	if d > 0.9999 then
		return CFrame.new()
	elseif d < -0.9999 then
		local perp = math.abs(a.X) < 0.9 and Vector3.new(1, 0, 0) or Vector3.new(0, 1, 0)
		return CFrame.fromAxisAngle(a:Cross(perp).Unit, math.pi)
	end
	return CFrame.fromAxisAngle(a:Cross(b).Unit, math.acos(d))
end

function WeaponFit.solve(boxes, spec): ((CFrame) -> CFrame, number)
	local pre = CFrame.new()
	if spec.Pre then
		pre = CFrame.Angles(math.rad(spec.Pre[1] or 0), math.rad(spec.Pre[2] or 0), math.rad(spec.Pre[3] or 0))
		local turned = {}
		for _, b in boxes do
			table.insert(turned, { CFrame = pre * b.CFrame, Size = b.Size })
		end
		boxes = turned
	end
	local mn, mx = WeaponFit.bounds(boxes)
	local c, h = (mn + mx) / 2, (mx - mn) / 2
	local axis = AXES[spec.Axis or "Y"]
	local length = 2 * axis:Dot(h)
	local k = (spec.Len or length) / math.max(length, 1e-3)
	local g = spec.Grip or { 0, 0, 0 }
	local grip = c + Vector3.new(g[1] * h.X, g[2] * h.Y, g[3] * h.Z)
	local target = spec.Gun and Vector3.new(0, 0, -1) or Vector3.new(0, 1, 0)
	local rot = CFrame.fromAxisAngle(target, math.rad(spec.Spin or 0)) * turn(axis * (spec.Tip or 1), target)
	return function(cf: CFrame): CFrame
		cf = pre * cf
		local p = rot:VectorToWorldSpace(cf.Position - grip) * k
		return CFrame.new(p) * rot * cf.Rotation
	end, k
end

return WeaponFit
