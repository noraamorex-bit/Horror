--[[
	Rig — what Curtis looks like now. Built from parts so it never depends on the catalog
	loading, and rigged with the standard R15 joint names so the client can animate it
	procedurally (client/Controllers/Creature).

	A head and a half taller than you, starved thin and stooped. A long, torn black coat, the
	hood up. Under the hood a cracked white porcelain mask: two hollow black eyes with a pin of
	light in each, and a grin stitched shut from ear to ear. Arms too long for his body: bare,
	grey forearms and hands whose fingers hang past his knees, nails black.

		local model = Rig.build(Builder)  -- standing on y = 0, facing -Z; HumanoidRootPart is primary
]]

local Rig = {}

local V = Vector3.new
local CF = CFrame.new

Rig.HipHeight = 3.9
Rig.RootY = 4.9 -- HumanoidRootPart centre above the floor

local COAT = Color3.fromRGB(19, 18, 18)
local COAT_EDGE = Color3.fromRGB(28, 26, 25)
local TROUSERS = Color3.fromRGB(23, 22, 22)
local SKIN = Color3.fromRGB(168, 164, 156) -- grey, months without daylight
local MASK = Color3.fromRGB(204, 198, 184)
local HOLE = Color3.fromRGB(4, 4, 4)
local GLINT = Color3.fromRGB(255, 246, 232)
local NAIL = Color3.fromRGB(14, 12, 12)
local HAIR = Color3.fromRGB(10, 10, 10)

function Rig.build(Builder): Model
	local model = Instance.new("Model")
	model.Name = "Curtis"

	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?)
		local props: { [string]: any } = {
			Name = name,
			Size = size,
			CFrame = cf,
			Color = color,
			Material = material or Enum.Material.SmoothPlastic,
			Anchored = false,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Massless = true,
			CastShadow = true,
		}
		if extra then
			for k, v in extra do
				props[k] = v
			end
		end
		return Builder.part(model, props)
	end
	local function ellipsoid(p: BasePart)
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
		return p
	end
	-- decoration stuck to a body part (moves with it)
	local function stick(to: BasePart, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?)
		local p = part(name, size, cf, color, material, extra)
		local w = Instance.new("WeldConstraint")
		w.Part0 = to
		w.Part1 = p
		w.Parent = p
		return p
	end

	-- the body (R15 names: the client's animator looks the joints up by them)
	local root = part("HumanoidRootPart", V(2, 2, 1), CF(0, Rig.RootY, 0), COAT, nil, { Transparency = 1, CanCollide = true, Massless = false, CastShadow = false })
	local lowerTorso = part("LowerTorso", V(1.25, 0.7, 0.72), CF(0, 4.9, 0), COAT, Enum.Material.Fabric)
	local upperTorso = part("UpperTorso", V(1.45, 1.75, 0.8), CF(0, 6.1, 0.02), COAT, Enum.Material.Fabric)
	local head = part("Head", V(1.12, 1.42, 1.16), CF(0, 7.82, 0.06), COAT, Enum.Material.Fabric)
	ellipsoid(head)

	local limbs = {}
	for _, side in { "Left", "Right" } do
		local sx = side == "Left" and -1 or 1
		limbs[side .. "UpperArm"] = part(side .. "UpperArm", V(0.44, 2.05, 0.48), CF(sx * 0.98, 5.78, 0.02), COAT, Enum.Material.Fabric)
		limbs[side .. "LowerArm"] = part(side .. "LowerArm", V(0.32, 2.05, 0.34), CF(sx * 0.98, 3.73, 0.02), SKIN)
		limbs[side .. "Hand"] = part(side .. "Hand", V(0.34, 0.62, 0.2), CF(sx * 0.98, 2.4, 0.02), SKIN)
		limbs[side .. "UpperLeg"] = part(side .. "UpperLeg", V(0.56, 2.1, 0.6), CF(sx * 0.4, 3.5, 0), TROUSERS, Enum.Material.Fabric)
		limbs[side .. "LowerLeg"] = part(side .. "LowerLeg", V(0.42, 2.1, 0.46), CF(sx * 0.4, 1.4, 0), TROUSERS, Enum.Material.Fabric)
		limbs[side .. "Foot"] = part(side .. "Foot", V(0.46, 0.35, 1.1), CF(sx * 0.4, 0.175, -0.16), NAIL, Enum.Material.Leather)
	end
	model.PrimaryPart = root

	-- joints, all at rest pointing straight (identity rotation)
	local function joint(name: string, p0: BasePart, p1: BasePart, at: Vector3)
		local m = Instance.new("Motor6D")
		m.Name = name
		m.Part0 = p0
		m.Part1 = p1
		m.C0 = CF(at - p0.Position)
		m.C1 = CF(at - p1.Position)
		m.Parent = p1
		return m
	end
	joint("Root", root, lowerTorso, V(0, 4.9, 0))
	joint("Waist", lowerTorso, upperTorso, V(0, 5.25, 0))
	joint("Neck", upperTorso, head, V(0, 6.98, 0.04))
	for _, side in { "Left", "Right" } do
		local sx = side == "Left" and -1 or 1
		joint(side .. "Shoulder", upperTorso, limbs[side .. "UpperArm"], V(sx * 0.9, 6.72, 0.02))
		joint(side .. "Elbow", limbs[side .. "UpperArm"], limbs[side .. "LowerArm"], V(sx * 0.98, 4.76, 0.02))
		joint(side .. "Wrist", limbs[side .. "LowerArm"], limbs[side .. "Hand"], V(sx * 0.98, 2.71, 0.02))
		joint(side .. "Hip", lowerTorso, limbs[side .. "UpperLeg"], V(sx * 0.4, 4.55, 0))
		joint(side .. "Knee", limbs[side .. "UpperLeg"], limbs[side .. "LowerLeg"], V(sx * 0.4, 2.45, 0))
		joint(side .. "Ankle", limbs[side .. "LowerLeg"], limbs[side .. "Foot"], V(sx * 0.4, 0.35, 0))
	end

	-- fingers: four long grey ones per hand, black nails, slightly curled
	for _, side in { "Left", "Right" } do
		local sx = side == "Left" and -1 or 1
		local hand = limbs[side .. "Hand"]
		for i, fx in { -0.12, -0.04, 0.04, 0.12 } do
			local len = (i == 2 or i == 3) and 1.0 or 0.82
			local curl = math.rad(6 + i * 3)
			local base = CF(sx * 0.98 + fx * sx, 2.09, 0.02 - 0.02 * i)
			local finger = stick(hand, "Finger", V(0.075, len, 0.075), base * CF(0, -len / 2, 0) * CFrame.Angles(curl, 0, 0), SKIN)
			stick(hand, "Nail", V(0.085, 0.14, 0.085), finger.CFrame * CF(0, -len / 2 - 0.02, -0.01), NAIL)
		end
		-- a knuckly thumb
		stick(hand, "Thumb", V(0.08, 0.55, 0.08), CF(sx * 0.98 - sx * 0.2, 2.2, -0.08) * CFrame.Angles(0.3, 0, sx * 0.35), SKIN)
	end

	-- the coat: a high collar, a gaunt strip of chest showing ribs, long torn tails
	for _, sx in { -1, 1 } do
		stick(upperTorso, "Collar", V(0.5, 0.75, 0.9), CF(sx * 0.42, 7.05, 0.05) * CFrame.Angles(0, 0, sx * -0.28), COAT_EDGE, Enum.Material.Fabric)
		stick(upperTorso, "Lapel", V(0.45, 1.5, 0.08), CF(sx * 0.3, 6.25, -0.43) * CFrame.Angles(0, 0, sx * 0.18), COAT_EDGE, Enum.Material.Fabric)
	end
	local chest = stick(upperTorso, "Chest", V(0.34, 1.2, 0.05), CF(0, 6.3, -0.41), SKIN)
	for i = 0, 3 do
		stick(upperTorso, "Rib", V(0.3, 0.035, 0.03), chest.CFrame * CF(0, 0.35 - i * 0.22, -0.03), Color3.fromRGB(110, 104, 98))
	end
	-- tails hang from the waist: a back panel and two at the sides, ragged at the bottom
	local tails = {
		{ V(1.3, 2.6, 0.1), CF(0, 3.75, 0.42) * CFrame.Angles(math.rad(-6), 0, 0) },
		{ V(0.5, 2.3, 0.1), CF(-0.66, 3.9, 0.08) * CFrame.Angles(0, math.rad(90), math.rad(4)) },
		{ V(0.5, 2.3, 0.1), CF(0.66, 3.9, 0.08) * CFrame.Angles(0, math.rad(90), math.rad(-4)) },
	}
	for _, t in tails do
		local panel = stick(lowerTorso, "CoatTail", t[1], t[2], COAT, Enum.Material.Fabric)
		-- torn strips at the hem, different lengths
		for k = -1, 1 do
			local w = t[1].X / 3
			local len = 0.35 + ((k + 2) * 37 % 5) * 0.12
			stick(lowerTorso, "Rag", V(w * 0.8, len, 0.08), panel.CFrame * CF(k * w, -t[1].Y / 2 - len / 2 + 0.05, 0), COAT, Enum.Material.Fabric)
		end
	end
	-- sleeves end ragged at the elbow
	for _, side in { "Left", "Right" } do
		local arm = limbs[side .. "UpperArm"]
		stick(arm, "Cuff", V(0.5, 0.2, 0.54), arm.CFrame * CF(0, -1.0, 0), COAT_EDGE, Enum.Material.Fabric)
	end
	-- neck: thin, grey
	stick(head, "NeckSkin", V(0.55, 0.38, 0.38), CF(0, 7.05, 0.05) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(96, 92, 86), nil, { Shape = Enum.PartType.Cylinder })

	-- the hood's peak, so the silhouette reads as a hood
	stick(head, "HoodPeak", V(1.0, 0.4, 0.7), CF(0, 8.45, -0.08) * CFrame.Angles(math.rad(-20), 0, 0), COAT, Enum.Material.Fabric, { ClassName = "WedgePart" })
	-- the mask: a long, grimy porcelain face filling the hood's opening. Not a smile: the
	-- eyes are tall hollow drops sagging at the corners, and the mouth hangs open, stretched
	-- down like it's in the middle of a scream that never comes out.
	local maskC = CF(0, 7.78, -0.32)
	ellipsoid(stick(head, "Mask", V(0.8, 1.22, 0.5), maskC, MASK, Enum.Material.SmoothPlastic))
	local ma, mb, mc = 0.4, 0.61, 0.25
	-- a point on the mask's face (x, y from its centre), pushed `out` studs off the surface
	local function onMask(x: number, y: number, out: number): CFrame
		local k = 1 - (x / ma) ^ 2 - (y / mb) ^ 2
		local z = mc * math.sqrt(math.max(k, 0.02))
		-- face the surface normal a little, so features sit flush on the curve
		local nx = x / (ma * ma)
		return maskC * CF(x, y, -z - out) * CFrame.Angles(0, -nx * 0.05, 0)
	end
	for _, sx in { -1, 1 } do
		-- tall hollow eyes, tilted so they droop outward
		ellipsoid(stick(head, "EyeHole", V(0.17, 0.38, 0.1), onMask(sx * 0.16, 0.1, -0.035) * CFrame.Angles(0, 0, sx * 0.32), HOLE))
		-- soot running down from each eye
		stick(head, "Streak", V(0.035, 0.42, 0.03), onMask(sx * 0.19, -0.2, -0.008) * CFrame.Angles(0, 0, sx * 0.08), Color3.fromRGB(58, 54, 50))
	end
	-- a pin of light, deep in each eye, slightly different heights: he is looking at you
	ellipsoid(stick(head, "Glint", V(0.07, 0.07, 0.03), onMask(-0.15, 0.03, 0.0), GLINT, Enum.Material.Neon))
	ellipsoid(stick(head, "Glint", V(0.07, 0.07, 0.03), onMask(0.15, 0.06, 0.0), GLINT, Enum.Material.Neon))
	-- a cold, faint light just in front of the mask: in a pitch-black room you can only just
	-- make out the face
	local glowAt = stick(head, "FaceGlow", V(0.1, 0.1, 0.1), onMask(0, 0.05, 0.75), GLINT, nil, { Transparency = 1, CastShadow = false })
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(196, 206, 232)
	glow.Brightness = 0.6
	glow.Range = 3.4
	glow.Shadows = false
	glow.Parent = glowAt
	-- the mouth: a long black oval hanging open
	ellipsoid(stick(head, "Mouth", V(0.17, 0.4, 0.1), onMask(0, -0.31, -0.035), HOLE))
	-- cracks from the brow down past the left eye
	stick(head, "Crack", V(0.018, 0.3, 0.02), onMask(-0.05, 0.4, -0.004) * CFrame.Angles(0, 0, 0.45), Color3.fromRGB(40, 36, 34))
	stick(head, "Crack", V(0.018, 0.2, 0.02), onMask(-0.13, 0.3, -0.004) * CFrame.Angles(0, 0, -0.35), Color3.fromRGB(40, 36, 34))
	stick(head, "Crack", V(0.016, 0.16, 0.02), onMask(0.08, -0.5, -0.004) * CFrame.Angles(0, 0, -0.2), Color3.fromRGB(40, 36, 34))
	-- lank black hair hanging out of the hood either side of the mask
	for i, a in { -0.5, -0.38, -0.27, 0.27, 0.38, 0.5 } do
		local len = 1.2 + (i % 3) * 0.18
		stick(head, "Hair", V(0.06, len, 0.06), CF(a, 7.75 - len / 2 + 0.45, -0.18 + math.abs(a) * 0.3) * CFrame.Angles(0.05, 0, a * 0.15), HAIR)
	end

	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = Rig.HipHeight
	hum.AutomaticScalingEnabled = false
	hum.RequiresNeck = false
	hum.Parent = model
	model:SetAttribute("Creature", true)
	game:GetService("CollectionService"):AddTag(model, "Creature")
	return model
end

return Rig
