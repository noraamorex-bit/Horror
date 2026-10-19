--[[
	Signs — what he leaves behind (v99). At the blackout, wet footprints appear on the upstairs
	hall floor, coming from under the attic hatch: long and narrow, three toes, far too far apart
	for anyone in this family. Built into the night's World folder, so the next night starts clean.

		Signs.footprints(parent) -> Folder
]]

local Signs = {}

local V = Vector3.new
local CF = CFrame.new

local WET = Color3.fromRGB(30, 25, 21)
local FLOOR_TOP = 15.0 -- the upstairs hall floor (Layout.Y.Upstairs; its planks' top face)

-- the trail: from under the hatch (Layout.AtticHatch, x 4-8, z 8-14) along the hall towards the
-- front of the house, stopping short of the rug (x 0.5-5.5, z -27..-9)
local FROM, TO = V(6.0, 0, 10.5), V(4.0, 0, -7.6)
local STRIDE = 2.3

function Signs.footprints(parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Footprints"
	local dir = Vector3.new(TO.X - FROM.X, 0, TO.Z - FROM.Z)
	local len = dir.Magnitude
	local fwd = dir.Unit
	local right = V(-fwd.Z, 0, fwd.X)
	local yaw = math.atan2(-fwd.X, -fwd.Z)
	local function print1(at: Vector3, fade: number)
		local base = CF(at.X, FLOOR_TOP + 0.011, at.Z) * CFrame.Angles(0, yaw, 0)
		local function bit(name: string, size: Vector3, cf: CFrame)
			local p = Instance.new("Part")
			p.Name = name
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Material = Enum.Material.SmoothPlastic
			p.Reflectance = 0.08
			p.Color = WET
			p.Transparency = 0.12 + fade
			p.Size = size
			p.CFrame = cf
			p.Parent = folder
		end
		-- the sole: long and narrow, the heel a little wider
		bit("Print", V(0.32, 0.02, 0.85), base * CF(0, 0, 0.05))
		bit("Print", V(0.38, 0.02, 0.32), base * CF(0, 0, 0.42))
		-- three toes, splayed, each ending in a scrape
		for i, a in { -0.32, 0, 0.32 } do
			local toe = base * CFrame.Angles(0, -a, 0) * CF(0, 0, -0.62 - (i == 2 and 0.06 or 0))
			bit("Print", V(0.08, 0.02, 0.42), toe)
		end
	end
	local i = 0
	local d = 0.6
	while d < len - 0.3 do
		local side = i % 2 == 0 and -1 or 1
		local at = FROM + fwd * d + right * side * 0.38
		-- (drying out as they go: the last few are fainter)
		print1(at, math.clamp((d / len - 0.6) * 1.2, 0, 0.45))
		d += STRIDE
		i += 1
	end
	folder.Parent = parent
	return folder
end

return Signs
