--[[
	Rig — what Curtis looks like (v99). Built from parts so it never depends on the catalog
	loading, and rigged with the standard R15 joint names so the client can animate it
	procedurally (client/Controllers/Creature, shared/CreaturePose).

	Whatever he was when he first climbed into the attic, years in the dark have starved him down
	to something jointed: nearly ten feet of black, oil-dull limbs as thin as broom handles, joined
	at swollen knuckle-like balls, like a mannequin someone left out in the rain. A ribcage you can
	count. Arms that hang past his knees and end in long black fingers with pale, split nails. His
	face is a long porcelain mask: two deep sockets that droop at the corners, a pin of light far
	inside each, and a mouth hanging open on a row of small teeth, stretched like he's screaming
	without a sound. Lank black hair hangs down over it. Rags of the shirt he came in with.

	The joint parts are untextured balls/blocks at each joint (identity rotation: the Motor6Ds
	are worked out from positions); the bones between them are cylinders welded on.

		local model = Rig.build(Builder)  -- standing on y = 0, facing -Z; HumanoidRootPart is primary
]]

local Rig = {}

local V = Vector3.new
local CF = CFrame.new

Rig.HipHeight = 3.9
Rig.RootY = 4.9 -- HumanoidRootPart centre above the floor (the navigator and NavGrid use it)
Rig.Height = 9.9 -- standing straight, the top of his head (doors are 9.5: he stoops through)

-- (v102, the owner: "I can't even see the monster": a charcoal you can make out in the dark, not
-- pure black)
local BODY = Color3.fromRGB(38, 36, 36)
local JOINT = Color3.fromRGB(58, 54, 52)
local RIB = Color3.fromRGB(44, 40, 38)
local MASK = Color3.fromRGB(221, 213, 196)
local MASK_DIRT = Color3.fromRGB(150, 140, 124)
local HOLE = Color3.fromRGB(3, 3, 3)
local GLINT = Color3.fromRGB(255, 244, 228)
local TOOTH = Color3.fromRGB(200, 190, 166)
local NAIL = Color3.fromRGB(176, 166, 146)
local HAIR = Color3.fromRGB(7, 7, 7)
local RAG = Color3.fromRGB(46, 42, 38)

-- where everything sits, standing straight (feet on y = 0, facing -Z)
local P = {
	Root = V(0, Rig.RootY, 0),
	Pelvis = V(0, 5.55, 0),
	Waist = V(0, 5.8, 0),
	Chest = V(0, 7.15, 0.04),
	Neck = V(0, 8.0, 0.02),
	Head = V(0, 9.15, -0.04),
	Mask = V(0, 9.12, -0.24),
}
local function side(sx: number)
	return {
		Shoulder = V(sx * 0.66, 7.75, 0.04),
		Elbow = V(sx * 0.72, 5.25, 0.04),
		Wrist = V(sx * 0.74, 2.75, 0.0),
		Hip = V(sx * 0.34, 5.4, 0),
		Knee = V(sx * 0.37, 2.85, -0.06),
		Ankle = V(sx * 0.38, 0.33, 0.04),
	}
end

function Rig.build(Builder): Model
	local model = Instance.new("Model")
	model.Name = "Curtis"
	-- (v133) all of him reaches a client at once: his skinned body, its 68 bones and the mask (streamed in
	-- pieces, a client could start animating a body with no bones yet: him upright in his rest pose)
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)

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
	-- a round part (a joint, a knuckle)
	local function ball(to: BasePart?, name: string, d: number, at: Vector3, color: Color3)
		local props = { Shape = Enum.PartType.Ball }
		if to then
			return stick(to, name, V(d, d, d), CF(at), color, nil, props)
		end
		return part(name, V(d, d, d), CF(at), color, nil, props)
	end
	-- a bone: a cylinder from a to b (Roblox cylinders run along their X axis), welded to `to`
	local function bone(to: BasePart, name: string, a: Vector3, b: Vector3, thick: number, color: Color3?)
		local dir = b - a
		local len = dir.Magnitude
		local x = dir.Unit
		local up = math.abs(x.Y) > 0.95 and V(0, 0, 1) or V(0, 1, 0)
		local z = x:Cross(up).Unit
		local y = z:Cross(x).Unit
		local cf = CFrame.fromMatrix((a + b) / 2, x, y, z)
		return stick(to, name, V(len, thick, thick), cf, color or BODY, nil, { Shape = Enum.PartType.Cylinder })
	end

	-- a long bone that thins from a to b: stacked cylinders, each a little thinner than the last
	local function taper(to: BasePart, a: Vector3, b: Vector3, t0: number, t1: number)
		local n = 3
		for i = 0, n - 1 do
			local k = i / (n - 1)
			bone(to, "Bone", a:Lerp(b, i / n), a:Lerp(b, (i + 1) / n + (i < n - 1 and 0.02 or 0)), t0 + (t1 - t0) * k)
		end
	end

	-- the jointed parts (R15 names: the client's animator looks the joints up by them). Each is the
	-- ball at its own joint; the bone to the next joint is welded on.
	local root = part("HumanoidRootPart", V(2, 2, 1), CF(P.Root), BODY, nil, { Transparency = 1, CanCollide = true, Massless = false, CastShadow = false })
	local lowerTorso = ellipsoid(part("LowerTorso", V(0.95, 0.5, 0.5), CF(P.Pelvis), BODY))
	local upperTorso = ellipsoid(part("UpperTorso", V(1.0, 1.55, 0.58), CF(P.Chest), BODY))
	local head = ellipsoid(part("Head", V(0.8, 1.25, 0.8), CF(P.Head), HAIR))

	local limbs = {}
	for _, s in { "Left", "Right" } do
		local sx = s == "Left" and -1 or 1
		local J = side(sx)
		limbs[s .. "UpperArm"] = ball(nil, s .. "UpperArm", 0.42, J.Shoulder, JOINT)
		limbs[s .. "LowerArm"] = ball(nil, s .. "LowerArm", 0.3, J.Elbow, JOINT)
		limbs[s .. "Hand"] = ellipsoid(part(s .. "Hand", V(0.26, 0.5, 0.11), CF(J.Wrist + V(0, -0.27, -0.01)), BODY))
		limbs[s .. "UpperLeg"] = ball(nil, s .. "UpperLeg", 0.4, J.Hip, JOINT)
		limbs[s .. "LowerLeg"] = ball(nil, s .. "LowerLeg", 0.36, J.Knee, JOINT)
		limbs[s .. "Foot"] = part(s .. "Foot", V(0.3, 0.2, 1.15), CF(J.Ankle + V(0, -0.2, -0.38)), BODY)
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
	joint("Root", root, lowerTorso, P.Root)
	joint("Waist", lowerTorso, upperTorso, P.Waist)
	joint("Neck", upperTorso, head, P.Neck)
	for _, s in { "Left", "Right" } do
		local J = side(s == "Left" and -1 or 1)
		joint(s .. "Shoulder", upperTorso, limbs[s .. "UpperArm"], J.Shoulder)
		joint(s .. "Elbow", limbs[s .. "UpperArm"], limbs[s .. "LowerArm"], J.Elbow)
		joint(s .. "Wrist", limbs[s .. "LowerArm"], limbs[s .. "Hand"], J.Wrist)
		joint(s .. "Hip", lowerTorso, limbs[s .. "UpperLeg"], J.Hip)
		joint(s .. "Knee", limbs[s .. "UpperLeg"], limbs[s .. "LowerLeg"], J.Knee)
		joint(s .. "Ankle", limbs[s .. "LowerLeg"], limbs[s .. "Foot"], J.Ankle)
	end

	-- the bones: long and thin, a little thicker at the top of each
	for _, s in { "Left", "Right" } do
		local sx = s == "Left" and -1 or 1
		local J = side(sx)
		local ua, la, ul, ll = limbs[s .. "UpperArm"], limbs[s .. "LowerArm"], limbs[s .. "UpperLeg"], limbs[s .. "LowerLeg"]
		taper(ua, J.Shoulder, J.Elbow, 0.27, 0.17)
		bone(ua, "Bone", J.Shoulder + V(0, -0.15, 0), J.Shoulder:Lerp(J.Elbow, 0.45), 0.3) -- (what's left of a muscle)
		taper(la, J.Elbow, J.Wrist, 0.2, 0.12)
		bone(la, "Tendon", J.Elbow + V(0, -0.2, -0.09), J.Wrist + V(0, 0.25, -0.06), 0.055) -- (strung like a wire)
		ball(la, "Knuckle", 0.2, J.Wrist, JOINT)
		taper(ul, J.Hip, J.Knee, 0.33, 0.2)
		bone(ul, "Bone", J.Hip + V(0, -0.1, 0), J.Hip:Lerp(J.Knee, 0.5), 0.36)
		taper(ll, J.Knee, J.Ankle, 0.24, 0.13)
		bone(ll, "Tendon", J.Knee + V(0, -0.25, 0.12), J.Ankle + V(0, 0.3, 0.09), 0.07) -- (the back of the calf: nothing but cord)
		ball(ll, "Knuckle", 0.22, J.Ankle, JOINT)
		-- the foot: long, narrow, three toes ending in pale nails
		local foot = limbs[s .. "Foot"]
		for i, tx in { -0.09, 0, 0.09 } do
			local toeAt = J.Ankle + V(tx, -0.27, -0.95 - (i == 2 and 0.08 or 0))
			bone(foot, "Toe", toeAt + V(0, 0, 0.25), toeAt, 0.07)
			stick(foot, "Nail", V(0.07, 0.05, 0.14), CF(toeAt + V(0, -0.01, -0.06)), NAIL)
		end

		-- the hand: a narrow palm, four long fingers (two joints each, curled in) and a thumb.
		-- Every nail pale and split. Each finger hangs on its own joint ("LeftFinger1".. at the
		-- knuckle): they flex, drum one after another, and claw (CreaturePose).
		local hand = limbs[s .. "Hand"]
		local palmBottom = J.Wrist + V(0, -0.52, -0.01)
		for i, fx in { -0.1, -0.035, 0.035, 0.1 } do
			local len = (i == 2 or i == 3) and 0.72 or 0.6
			local a = palmBottom + V(fx * sx, 0, 0)
			local mid = a + V(fx * sx * 0.3, -len, -0.08 - 0.02 * i)
			local tip = mid + V(fx * sx * 0.15, -len * 0.85, -0.3)
			local finger = ball(nil, s .. "Finger" .. i, 0.085, a, BODY)
			joint(s .. "Finger" .. i, hand, finger, a)
			bone(finger, "Finger", a, mid, 0.065)
			ball(finger, "Knuckle", 0.08, mid, BODY)
			bone(finger, "Finger", mid, tip, 0.055)
			local nailDir = (tip - mid).Unit
			bone(finger, "Nail", tip - nailDir * 0.02, tip + nailDir * 0.17, 0.05, NAIL)
		end
		local thumbA = J.Wrist + V(-sx * 0.16, -0.2, -0.06)
		local thumbTip = thumbA + V(-sx * 0.12, -0.55, -0.22)
		bone(hand, "Thumb", thumbA, thumbTip, 0.06)
		bone(hand, "Nail", thumbTip, thumbTip + (thumbTip - thumbA).Unit * 0.14, 0.05, NAIL)
	end

	-- the trunk: a spine you can see between pelvis and ribs, a ribcage, collarbones, shoulder blades
	bone(lowerTorso, "Spine", P.Pelvis, P.Waist + V(0, 0.5, 0.08), 0.22)
	for i = 0, 4 do
		ball(upperTorso, "Vertebra", 0.15, V(0, 6.05 + i * 0.42, 0.33 - i * 0.01), JOINT)
	end
	for i = 0, 4 do
		-- each rib: sternum out to the side, then round towards the back
		local y = 7.55 - i * 0.24
		local w = 0.5 - math.abs(i - 1.5) * 0.04
		for _, sx in { -1, 1 } do
			local a = V(sx * 0.05, y, -0.3)
			local b = V(sx * w, y - 0.06, -0.12)
			local c = V(sx * (w - 0.02), y - 0.1, 0.18)
			bone(upperTorso, "Rib", a, b, 0.055, RIB)
			bone(upperTorso, "Rib", b, c, 0.055, RIB)
		end
	end
	bone(upperTorso, "Sternum", V(0, 7.7, -0.3), V(0, 6.65, -0.28), 0.07, RIB)
	for _, sx in { -1, 1 } do
		bone(upperTorso, "Collarbone", V(sx * 0.06, 7.82, -0.22), V(sx * 0.62, 7.82, 0.0), 0.08, RIB)
		ellipsoid(stick(upperTorso, "ShoulderBlade", V(0.36, 0.55, 0.12), CF(sx * 0.3, 7.35, 0.3) * CFrame.Angles(0, 0, sx * 0.25), BODY))
		bone(lowerTorso, "HipBone", V(sx * 0.1, 5.75, -0.16), V(sx * 0.42, 5.5, -0.05), 0.11, RIB)
	end
	-- rags of the shirt he came in with: a torn collar and strips hanging off the hips
	for i, a in { -0.38, -0.12, 0.16, 0.36 } do
		local len = 0.45 + (i % 3) * 0.22
		stick(lowerTorso, "Rag", V(0.2, len, 0.04), CF(a, 5.55 - len / 2, -0.25) * CFrame.Angles(0.08, 0, a * 0.3), RAG, Enum.Material.Fabric)
	end
	for _, sx in { -1, 1 } do
		stick(upperTorso, "Rag", V(0.32, 0.5, 0.05), CF(sx * 0.33, 7.72, -0.26) * CFrame.Angles(-0.1, 0, sx * 0.4), RAG, Enum.Material.Fabric)
	end

	-- the neck: long, thin, two bones (it bends further than a neck should)
	bone(head, "NeckBone", P.Neck, P.Neck + V(0, 0.62, -0.03), 0.17)
	ball(head, "Knuckle", 0.16, P.Neck + V(0, 0.32, -0.02), JOINT)

	-- the mask: a long, grimy porcelain face over the front of the head
	local maskC = CF(P.Mask)
	ellipsoid(stick(head, "Mask", V(0.78, 1.32, 0.5), maskC, MASK, Enum.Material.SmoothPlastic))
	local ma, mb, mc = 0.39, 0.66, 0.25
	-- a point on the mask's face (x, y from its centre), pushed `out` studs off the surface
	local function onMask(x: number, y: number, out: number): CFrame
		local k = 1 - (x / ma) ^ 2 - (y / mb) ^ 2
		local z = mc * math.sqrt(math.max(k, 0.02))
		local nx = x / (ma * ma)
		return maskC * CF(x, y, -z - out) * CFrame.Angles(0, -nx * 0.05, 0)
	end
	for _, sx in { -1, 1 } do
		-- big round sockets, sunk deep, a grey bruise round each; a tiny pale pupil far inside,
		-- not quite level: staring at you
		ellipsoid(stick(head, "EyeRim", V(0.33, 0.37, 0.1), onMask(sx * 0.155, 0.2, -0.05), MASK_DIRT))
		ellipsoid(stick(head, "EyeHole", V(0.27, 0.31, 0.1), onMask(sx * 0.155, 0.2, -0.03), HOLE))
		ellipsoid(stick(head, "Glint", V(0.055, 0.055, 0.03), onMask(sx * 0.15, sx < 0 and 0.17 or 0.21, 0.03), GLINT, Enum.Material.Neon))
		-- what's run down from them
		stick(head, "Streak", V(0.03, 0.42, 0.03), onMask(sx * 0.2, -0.1, -0.008) * CFrame.Angles(0, 0, sx * 0.06), Color3.fromRGB(40, 36, 34))
	end
	-- the grin: stretched right across the face, cheek to cheek, curling up at the corners, two
	-- rows of small teeth with black between them. It opens: the client stretches the black down
	-- the face and drops the lower teeth with it, through their meshes' scale and offset
	-- (CreaturePose.setJaw), the mask's mouth pulled open like a scream.
	ellipsoid(stick(head, "Maw", V(0.5, 0.17, 0.1), onMask(0, -0.3, -0.03), HOLE))
	for _, sx in { -1, 1 } do
		ellipsoid(stick(head, "Mouth", V(0.16, 0.09, 0.1), onMask(sx * 0.25, -0.22, -0.035) * CFrame.Angles(0, 0, sx * 0.6), HOLE))
	end
	for i = -5, 5 do
		local x = i * 0.04
		local curve = (x / 0.24) ^ 2 * 0.06
		stick(head, "Tooth", V(0.032, 0.075, 0.03), onMask(x, -0.245 + curve, -0.012), TOOTH)
		if math.abs(i) <= 4 then
			local low = stick(head, "LowerTooth", V(0.032, 0.065, 0.03), onMask(x, -0.352 + curve * 0.6, -0.012), TOOTH)
			local m = Instance.new("SpecialMesh")
			m.MeshType = Enum.MeshType.Brick
			m.Parent = low
		end
	end
	-- cracks from the brow down past the left eye, and across the chin
	stick(head, "Crack", V(0.018, 0.34, 0.02), onMask(-0.04, 0.45, -0.004) * CFrame.Angles(0, 0, 0.45), Color3.fromRGB(40, 36, 34))
	stick(head, "Crack", V(0.018, 0.22, 0.02), onMask(-0.12, 0.36, -0.004) * CFrame.Angles(0, 0, -0.35), Color3.fromRGB(40, 36, 34))
	stick(head, "Crack", V(0.016, 0.18, 0.02), onMask(0.1, -0.52, -0.004) * CFrame.Angles(0, 0, -0.9), Color3.fromRGB(40, 36, 34))
	-- a cold, faint light in front of the mask: in a pitch-black room you only just make it out
	local glowAt = stick(head, "FaceGlow", V(0.1, 0.1, 0.1), onMask(0, 0.05, 0.8), GLINT, nil, { Transparency = 1, CastShadow = false })
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(196, 206, 232)
	glow.Brightness = 1.3
	glow.Range = 7
	glow.Shadows = false
	glow.Parent = glowAt
	-- and a faint cold light off his chest onto the walls and floor around him, so his shape shows
	-- against them in a dark room
	local aura = Instance.new("PointLight")
	aura.Name = "Aura"
	aura.Color = Color3.fromRGB(150, 166, 205)
	aura.Brightness = 0.8
	aura.Range = 11
	aura.Shadows = false
	aura.Parent = upperTorso

	-- lank black hair, wet and clumped: flat strips from the crown, over the skull and hanging
	-- straight down to the shoulders at the back and sides; a few across the front of the mask
	local hc = P.Head
	local function strip(name: string, a: Vector3, b: Vector3, width: number, faceOut: Vector3)
		-- a flat ribbon from a to b, its flat side facing `faceOut`
		local dir = b - a
		local y = dir.Unit
		local z = (faceOut - y * faceOut:Dot(y)).Unit
		local x = y:Cross(z).Unit
		return stick(head, name, V(width, dir.Magnitude, 0.035), CFrame.fromMatrix((a + b) / 2, x, y, z), HAIR, Enum.Material.Fabric)
	end
	for i = 0, 13 do
		local a = math.rad(-125 + i * (250 / 13)) -- (0 = straight back)
		local dir = V(math.sin(a), 0, math.cos(a))
		local len = 1.1 + ((i * 7) % 5) * 0.2 + (math.abs(a) < 1.1 and 0.5 or 0)
		local top = hc + V(0, 0.62, 0) + dir * 0.1
		local over = hc + V(0, 0.15, 0) + dir * 0.43
		local fall = over + V(0, -len, 0) + dir * 0.06
		local w = 0.13 + (i % 3) * 0.03
		strip("Hair", top, over, w, dir + V(0, 0.6, 0))
		strip("Hair", over - V(0, 0.04, 0), fall, w * 0.85, dir)
	end
	-- down the edges of the mask, one each side (any further in and they read as bars across it)
	for _, st in { { -0.33, 1.15, -0.02 }, { 0.33, 0.8, 0.02 } } do
		local top = hc + V(st[1] * 0.7, 0.6, -0.16)
		local over = V(P.Mask.X + st[1], P.Mask.Y + 0.42, P.Mask.Z - 0.22)
		local bottom = over + V(st[3], -st[2], -0.06)
		strip("Fringe", top, over, 0.05, V(0, 0.5, -1))
		strip("Fringe", over, bottom, 0.04, V(0, 0, -1))
	end

	-- where the server thinks he sees and hears from (perception, sight lines, his breathing): an
	-- invisible point fixed to the root at about the height of his face as he walks, hunched. (His
	-- real head is up at 9-10 feet standing; the server never animates him, so it would sit inside
	-- door frames and the tunnel roofs.) The jumpscare camera still looks at the real Head.
	stick(root, "Eyes", V(0.4, 0.4, 0.4), CF(0, 7.82, 0.06), BODY, nil, { Transparency = 1, CastShadow = false })

	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = Rig.HipHeight
	hum.AutomaticScalingEnabled = false
	hum.RequiresNeck = false
	hum.Parent = model
	model:SetAttribute("Creature", true)
	game:GetService("CollectionService"):AddTag(model, "Creature")
	local ok, err = pcall(Rig.skin, model, root, upperTorso)
	if not ok then
		warn("[Rig] the skinned body didn't load, keeping the part-built one: " .. tostring(err))
	end
	return model
end

-- (v112) the real body: a sculpted, textured, skinned mesh with a full skeleton
-- (ReplicatedStorage.Assets.Creature.Body, from assets/Creature.rbxm). It takes over the look:
-- the part-built figure above stays as the invisible frame everything else already relies on
-- (the joints, Head for the jumpscare, Eyes, the lights), and the clients drive its bones
-- (client/Controllers/Creature, shared/SkinPose). Without the asset (the test harness) the
-- part-built figure is what you see.
Rig.SkinScale = 0.72 -- (the mesh is 13.66 tall: about 9.8 studs standing, the old figure's 9.9)

-- (v114, the owner: the skinned body was "a bit too much. Make it simpler but not that simple") it
-- wears the porcelain mask and the wet black hair again (the Head part and what's welded to it; the
-- clients keep them on the body's head bone), and the body lost its raw, bloody colour map
-- (tools/creature/plain_skin.luau): charcoal, with the sculpted detail of its normal map. The body and
-- its animation stay, the gore goes
Rig.MaskParts = {
	Mask = true, EyeHole = true, EyeRim = true, Glint = true, Maw = true, Mouth = true, Tooth = true,
	LowerTooth = true, Crack = true, Streak = true, Hair = true, Fringe = true,
}
-- (the new skull is bigger and further forward than the old head: its face is ~0.65 studs out at 9.1 up)
Rig.MaskScale = 1.2
Rig.MaskOffset = Vector3.new(0, -0.08, -0.42)
Rig.SkinColor = Color3.fromRGB(52, 49, 49)

-- the mask and hair grown to fit the new skull (scaled about the head's centre); returns the parts that
-- stay visible (the Head part and everything on it but the old neck)
function Rig.maskLayout(model: Model): { [BasePart]: boolean }
	local keep: { [BasePart]: boolean } = {}
	local head = model:FindFirstChild("Head") :: BasePart?
	if not head then
		return keep
	end
	keep[head] = true
	local hcf = head.CFrame
	local k = Rig.MaskScale
	for _, d in model:GetDescendants() do
		if d:IsA("WeldConstraint") and d.Part0 == head and d.Part1 and Rig.MaskParts[d.Part1.Name] then
			local p = d.Part1 :: BasePart
			keep[p] = true
			local rel = hcf:ToObjectSpace(p.CFrame)
			d.Enabled = false
			-- (the hair keeps its own strip size, only spread to the bigger skull: grown, it read as boards)
			if p.Name ~= "Hair" and p.Name ~= "Fringe" then
				p.Size *= k
			end
			p.CFrame = hcf * CFrame.new(rel.Position * k) * rel.Rotation
			d.Enabled = true
		end
	end
	head.Size *= k
	return keep
end

local function skinAsset(): Instance?
	local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
	local c = assets and assets:FindFirstChild("Creature")
	-- (typeof: the test harness answers every lookup with a stand-in table)
	return (c and typeof(c) == "Instance" and c:FindFirstChild("Body")) and c or nil
end

-- a bone's frame in the body's space, at rest
local function restOf(bone: Instance): CFrame
	local cf = (bone :: Bone).CFrame
	local p = bone.Parent
	while p and p:IsA("Bone") do
		cf = p.CFrame * cf
		p = p.Parent
	end
	return cf
end

function Rig.skin(model: Model, root: BasePart, upperTorso: BasePart): boolean
	local src = skinAsset()
	if not src then
		return false
	end
	local wrap = (src :: Model):Clone()
	-- (scales the mesh and moves its bones with it)
	wrap:ScaleTo(Rig.SkinScale)
	local body = wrap:FindFirstChild("Body") :: MeshPart
	body.Name = "Body"
	body.Anchored = false
	body.CanCollide = false
	body.CanQuery = false
	body.CanTouch = false
	body.Massless = true
	body.CastShadow = true
	-- feet on the floor (the mesh is centred on its own middle; its bottom is the soles)
	body.CFrame = root.CFrame * CFrame.new(0, -Rig.RootY + body.Size.Y / 2, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = body
	weld.Parent = body
	body.Parent = model
	wrap:Destroy()
	-- the part-built figure goes invisible, but for the mask and the hair on its head
	local head = model:FindFirstChild("Head") :: BasePart?
	local keep = Rig.maskLayout(model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= body and not keep[d] then
			d.Transparency = 1
			d.CastShadow = false
		end
	end
	local neck = head and head:FindFirstChild("Neck") :: Motor6D?
	if neck then
		neck.C0 += Rig.MaskOffset
	end
	body.Color = Rig.SkinColor
	-- its lights move onto the bones: the cold glow in front of the face, the faint one off the chest
	local k = Rig.SkinScale
	local head = body:FindFirstChild("spine_006_0", true)
	local chest = body:FindFirstChild("spine_003_51", true)
	local glowPart = model:FindFirstChild("FaceGlow", true)
	local glow = glowPart and glowPart:FindFirstChildOfClass("PointLight")
	if head and glow then
		local at = Instance.new("Bone")
		at.Name = "FaceLight"
		at.CFrame = restOf(head):Inverse() * CFrame.new(0, 5.75 * k, -2.0 * k)
		at.Parent = head
		glow.Parent = at
	end
	local aura = upperTorso:FindFirstChild("Aura")
	if chest and aura then
		local at = Instance.new("Bone")
		at.Name = "ChestLight"
		at.CFrame = restOf(chest):Inverse() * CFrame.new(0, 3.0 * k, -2.4 * k)
		at.Parent = chest
		aura.Parent = at
	end
	model:SetAttribute("Skinned", true)
	model:SetAttribute("Masked", head ~= nil)
	return true
end

return Rig
