--[[
	Haunt — what he's done to the house, and what the house does back (v131, the owner: "Make the map
	(house) much better. Seriously rework the whole map and perfect it. Add way more scares. Actually
	scary and creepy stuff.")

	Built after Dress, into the same room folders, under the same rules (tools/harness/dress_test.luau
	checks every part: clear of doorways, door swings, hiding spots and their views, prompts, his nav
	nodes and the candy spots).

	The static layer: the attic as a real attic (sheeted furniture, a dress form, a trunk, a crib, a
	rocking chair, a row of old dolls, boxes, bare bulbs, cobwebs); the back of the front hall (a runner
	and the family's photos, one of them with Grandma's face scratched out); the child's drawing
	on the fridge (the family, and something tall in the attic window); Lily's "me and my friend"; long
	scratches round the attic hatch; a little chair in the basement facing the wall.

	And the pieces the new scares use (Director/Events): Haunt.hand (his hand, out from under a bed),
	Haunt.scrawl (red writing on a wall), Haunt.rocker (the attic rocking chair, by name).

		Haunt.build(ctx, root) -> { BasePart }
		Haunt.hand(parent, cf) -> Model          cf: on the floor at the bed's edge, -Z = out from under it
		Haunt.scrawl(parent, cf, w, h, text) -> BasePart    cf: on the wall, -Z = into the room
]]

local Kit = require(script.Parent.Kit)

local Haunt = {}

local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad

local PX, NX, PZ, NZ = V(1, 0, 0), V(-1, 0, 0), V(0, 0, 1), V(0, 0, -1)

local function F(x: number, y: number, z: number, dir: Vector3): CFrame
	return CFrame.lookAt(V(x, y, z), V(x + dir.X, y, z + dir.Z))
end

local SKIN = Color3.fromRGB(52, 49, 49) -- (Rig.SkinColor: his charcoal skin)
local NAIL = Color3.fromRGB(214, 206, 188)
local SHEET = Color3.fromRGB(206, 202, 192)
local BLOOD = Color3.fromRGB(96, 8, 8)

---------------------------------------------------------------------------
-- children's drawings: crayon on paper, drawn with frames on a SurfaceGui (front face of the paper)
---------------------------------------------------------------------------
local function drawingGui(paper: BasePart, ppu: number): (SurfaceGui, number, number)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Crayon"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = ppu
	gui.LightInfluence = 1
	gui.Brightness = 1
	gui.MaxDistance = 60
	gui.Parent = paper
	return gui, paper.Size.X * ppu, paper.Size.Y * ppu
end

-- a crayon stroke from (x0, y0) to (x1, y1), in 0..1 of the paper (y down)
local function stroke(gui: SurfaceGui, W: number, H: number, x0: number, y0: number, x1: number, y1: number, thick: number, color: Color3)
	local ax, ay, bx, by = x0 * W, y0 * H, x1 * W, y1 * H
	local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromOffset((ax + bx) / 2, (ay + by) / 2)
	f.Size = UDim2.fromOffset(len + thick * 0.6, thick)
	f.Rotation = math.deg(math.atan2(by - ay, bx - ax))
	f.BackgroundColor3 = color
	f.BackgroundTransparency = 0.08
	f.BorderSizePixel = 0
	f.Parent = gui
	return f
end

-- a filled crayon blob (round)
local function blob(gui: SurfaceGui, W: number, H: number, x: number, y: number, d: number, color: Color3)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromOffset(x * W, y * H)
	f.Size = UDim2.fromOffset(d, d)
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = f
	f.Parent = gui
	return f
end

local function crayonText(gui: SurfaceGui, W: number, H: number, x: number, y: number, w: number, h: number, text: string, color: Color3, rot: number)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromOffset(x * W, y * H)
	t.Size = UDim2.fromOffset(w * W, h * H)
	t.Rotation = rot
	t.Font = Enum.Font.IndieFlower
	t.TextScaled = true
	t.TextColor3 = color
	t.Text = text
	t.Parent = gui
	return t
end

-- a stick person: head at (x, y), height h (0..1 of the paper's height)
local function stickPerson(gui, W, H, x, y, h, color: Color3, thick: number, opts)
	opts = opts or {}
	local head = h * 0.22
	blob(gui, W, H, x, y, head * H * 0.95, opts.face or color)
	local neck, hip = y + head * 0.5, y + h * 0.58
	stroke(gui, W, H, x, neck, x, hip, thick, color)
	local arm = opts.arms or 0.22
	local sh = y + h * 0.3
	stroke(gui, W, H, x, sh, x - arm * h * (H / W), sh + (opts.armsDown or 0.12) * h, thick, color)
	stroke(gui, W, H, x, sh, x + arm * h * (H / W), sh + (opts.armsDown or 0.12) * h, thick, color)
	local leg = h * 0.42
	stroke(gui, W, H, x, hip, x - leg * 0.35 * (H / W), hip + leg, thick, color)
	stroke(gui, W, H, x, hip, x + leg * 0.35 * (H / W), hip + leg, thick, color)
	if opts.eyes then
		-- two white dots: it looks back at you
		blob(gui, W, H, x - head * 0.18 * (H / W), y - head * 0.05, math.max(2, head * H * 0.18), Color3.new(1, 1, 1))
		blob(gui, W, H, x + head * 0.18 * (H / W), y - head * 0.05, math.max(2, head * H * 0.18), Color3.new(1, 1, 1))
	end
end

-- the fridge drawing (1.2 x 0.9): MY FAMILY, the house with Mom, Jamie and Lily in front of it, and
-- in the little attic window up under the roof, something black and tall with white eyes
function Haunt.familyDrawing(paper: BasePart)
	local gui, W, H = drawingGui(paper, 160)
	local brown, red, green = Color3.fromRGB(120, 72, 40), Color3.fromRGB(210, 40, 40), Color3.fromRGB(60, 160, 70)
	local th = 3.2
	crayonText(gui, W, H, 0.5, 0.09, 0.62, 0.14, "MY FAMLY", Color3.fromRGB(40, 90, 200), -3)
	-- the house: walls, roof, door, the round attic window
	stroke(gui, W, H, 0.16, 0.42, 0.16, 0.86, th, brown)
	stroke(gui, W, H, 0.84, 0.42, 0.84, 0.86, th, brown)
	stroke(gui, W, H, 0.14, 0.86, 0.86, 0.86, th, green)
	stroke(gui, W, H, 0.12, 0.44, 0.5, 0.18, th, red)
	stroke(gui, W, H, 0.5, 0.18, 0.88, 0.44, th, red)
	stroke(gui, W, H, 0.12, 0.44, 0.88, 0.44, th, red)
	stroke(gui, W, H, 0.46, 0.86, 0.46, 0.68, th * 0.8, brown)
	stroke(gui, W, H, 0.46, 0.68, 0.56, 0.68, th * 0.8, brown)
	stroke(gui, W, H, 0.56, 0.68, 0.56, 0.86, th * 0.8, brown)
	blob(gui, W, H, 0.5, 0.33, H * 0.15, Color3.fromRGB(250, 220, 90))
	-- him, in the window, filling it
	blob(gui, W, H, 0.5, 0.32, H * 0.105, Color3.fromRGB(14, 14, 16))
	blob(gui, W, H, 0.485, 0.31, 2.4, Color3.new(1, 1, 1))
	blob(gui, W, H, 0.515, 0.31, 2.4, Color3.new(1, 1, 1))
	-- Mom, Jamie and Lily, smiling, outside
	stickPerson(gui, W, H, 0.27, 0.6, 0.3, Color3.fromRGB(200, 60, 140), 2.6, { face = Color3.fromRGB(240, 200, 160) })
	stickPerson(gui, W, H, 0.69, 0.62, 0.27, Color3.fromRGB(40, 90, 200), 2.6, { face = Color3.fromRGB(240, 200, 160) })
	stickPerson(gui, W, H, 0.77, 0.69, 0.19, Color3.fromRGB(240, 120, 170), 2.4, { face = Color3.fromRGB(240, 200, 160) })
	crayonText(gui, W, H, 0.79, 0.55, 0.12, 0.08, "me", Color3.fromRGB(240, 120, 170), 4)
	crayonText(gui, W, H, 0.5, 0.215, 0.34, 0.07, "and HIM", Color3.fromRGB(14, 14, 16), -6)
end

-- Lily's drawing on her wall (1.6 x 1.2): ME AND MY FRIEND. Her, small, holding the hand of something
-- black that's three times her height, its arms down to its knees
function Haunt.friendDrawing(paper: BasePart)
	local gui, W, H = drawingGui(paper, 120)
	crayonText(gui, W, H, 0.5, 0.1, 0.8, 0.15, "ME AND MY FREND", Color3.fromRGB(240, 110, 170), 2)
	stroke(gui, W, H, 0.05, 0.9, 0.95, 0.9, 3.4, Color3.fromRGB(60, 160, 70))
	blob(gui, W, H, 0.86, 0.22, H * 0.12, Color3.fromRGB(250, 210, 60))
	stickPerson(gui, W, H, 0.3, 0.66, 0.24, Color3.fromRGB(240, 120, 170), 3, { face = Color3.fromRGB(240, 200, 160) })
	stickPerson(gui, W, H, 0.55, 0.26, 0.64, Color3.fromRGB(14, 14, 16), 4.5, { arms = 0.16, armsDown = 0.42, eyes = true })
	-- the hands meet
	stroke(gui, W, H, 0.36, 0.73, 0.47, 0.73, 3, Color3.fromRGB(14, 14, 16))
	-- a smile scrawled on it, too wide
	stroke(gui, W, H, 0.52, 0.315, 0.58, 0.315, 2, Color3.fromRGB(200, 30, 30))
end

---------------------------------------------------------------------------
-- red writing on a wall: a flat part flush with the wall, the words on its front, drips under them
---------------------------------------------------------------------------
function Haunt.scrawl(parent: Instance, cf: CFrame, w: number, h: number, text: string): BasePart
	local p = Instance.new("Part")
	p.Name = "Scrawl"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = V(w, h, 0.05)
	p.CFrame = cf
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 1
	gui.MaxDistance = 90
	gui.Parent = p
	local W, H = w * 40, h * 40
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromOffset(W, H * 0.8)
	t.Rotation = math.random(-4, 4)
	t.Font = Enum.Font.Creepster
	t.TextScaled = true
	t.TextColor3 = BLOOD
	t.TextTransparency = 0.05
	t.Text = text
	t.Parent = gui
	-- runs where it was put on too thick
	local rng = Random.new(#text * 31 + math.floor(cf.Position.X * 7))
	for _ = 1, math.clamp(#text // 2, 4, 12) do
		local d = Instance.new("Frame")
		d.BorderSizePixel = 0
		d.BackgroundColor3 = BLOOD
		d.BackgroundTransparency = 0.15
		local len = rng:NextNumber(0.08, 0.3) * H
		d.Size = UDim2.fromOffset(rng:NextNumber(2, 4), len)
		d.Position = UDim2.fromOffset(rng:NextNumber(0.08, 0.92) * W, H * rng:NextNumber(0.55, 0.7))
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Transparency = NumberSequence.new(0, 0.9)
		g.Parent = d
		d.Parent = gui
	end
	p.Parent = parent
	return p
end

---------------------------------------------------------------------------
-- his hand: a long charcoal palm, five jointed fingers with pale nails, the wrist trailing back under
-- the bed. cf on the floor at the bed's edge, -Z pointing out from under it.
---------------------------------------------------------------------------
function Haunt.hand(parent: Instance, cf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Hand"
	local function bit(name: string, at: CFrame, size: Vector3, color: Color3, ball: boolean?)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = color
		p.Size = size
		p.CFrame = at
		if ball then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = p
		end
		p.Parent = m
		return p
	end
	local base = cf * CF(0, 0.16, 0)
	bit("Forearm", base * CF(0, 0.06, 1.6), V(0.42, 0.3, 2.6), SKIN, true)
	bit("Wrist", base * CF(0, 0.04, 0.35), V(0.4, 0.26, 0.5), SKIN, true)
	bit("Palm", base * CF(0, 0, -0.15), V(0.62, 0.16, 0.75), SKIN, true)
	-- four long fingers, splayed, each bent down at the knuckle and again at the tip
	for i, sx in { -0.24, -0.08, 0.08, 0.24 } do
		local yaw = rad(sx * 40)
		local len = i == 1 and 0.75 or (i == 4 and 0.7 or 0.95)
		local k = base * CF(sx, 0, -0.5) * ANG(0, -yaw, 0)
		bit("Finger", k * ANG(rad(-6), 0, 0) * CF(0, 0, -len / 2), V(0.1, 0.09, len), SKIN, true)
		local k2 = k * ANG(rad(-6), 0, 0) * CF(0, 0, -len) * ANG(rad(-28), 0, 0)
		bit("Finger", k2 * CF(0, 0, -len * 0.4), V(0.09, 0.08, len * 0.8), SKIN, true)
		local tip = k2 * CF(0, 0, -len * 0.8) * ANG(rad(-35), 0, 0)
		bit("Nail", tip * CF(0, 0, -0.1), V(0.08, 0.03, 0.22), NAIL)
	end
	local th = base * CF(-0.32, 0, -0.1) * ANG(0, rad(55), 0)
	bit("Thumb", th * CF(0, 0, -0.3), V(0.11, 0.1, 0.6), SKIN, true)
	bit("Nail", th * CF(0, -0.02, -0.62), V(0.08, 0.03, 0.18), NAIL)
	m.WorldPivot = cf
	m.Parent = parent
	return m
end

---------------------------------------------------------------------------
-- the static layer
---------------------------------------------------------------------------
function Haunt.build(ctx, root: Instance): { BasePart }
	local existing = {}
	for _, d in root:GetDescendants() do
		existing[d] = true
	end
	local L = ctx.Layout
	local G, U, B = L.Y.Ground, L.Y.Upstairs, L.Y.Basement
	local AY = 29.2 -- (the attic insulation's top; the plywood walkway is 29.4)
	local KM, KC = Kit.M, Kit.C

	local function room(name: string): Instance
		return root:FindFirstChild(name) or root
	end
	local function paper(parent, name: string, cf: CFrame, size: Vector3): BasePart
		return Kit.box(parent, name, cf, size, Color3.fromRGB(250, 249, 242), KM.Plastic)
	end

	---------------------------------------------------------------------------
	-- THE ATTIC: everything the family put up here and forgot, under sheets and dust, and him living
	-- among it. (The roof's underside is at about y 41.6 - 0.44 |z|: keep tall things near the ridge.)
	---------------------------------------------------------------------------
	do
		local attic = Instance.new("Folder")
		attic.Name = "AtticJunk"
		attic.Parent = root
		-- a sheeted armchair and a sheeted standing mirror, east of the hatch (ghosts in the torchlight)
		Kit.soft(attic, "SheetedChair", CF(17, AY + 1.6, -3), V(3.4, 3.2, 3.2), 0.6, SHEET, KM.Fabric)
		Kit.soft(attic, "SheetedChairBack", CF(17, AY + 3.6, -1.8), V(3.4, 1.6, 0.9), 0.4, SHEET, KM.Fabric)
		Kit.collider(attic, CF(17, AY + 2, -2.6), V(3.2, 4, 3.2))
		Kit.soft(attic, "SheetedMirror", CF(22.5, AY + 3.1, 4.5) * ANG(0, rad(-15), 0), V(2.6, 6.2, 1.0), 0.3, SHEET, KM.Fabric)
		Kit.collider(attic, CF(22.5, AY + 3.1, 4.5) * ANG(0, rad(-15), 0), V(2.4, 6.2, 0.9))
		-- the dress form, a headless torso on a pole, turned to the hatch
		do
			local df = Kit.model(attic, "DressForm")
			local dcf = F(13.5, AY, 10.5, NX)
			Kit.vcyl(df, "FormFoot", dcf * CF(0, 0.08, 0), 0.16, 1.6, KC.WoodDark, KM.Wood)
			Kit.vcyl(df, "FormPole", dcf * CF(0, 1.9, 0), 3.6, 0.16, KC.WoodDark, KM.Wood)
			Kit.ellipsoid(df, "FormHips", dcf * CF(0, 3.9, 0), V(1.5, 1.1, 1.05), Color3.fromRGB(196, 176, 150), KM.Fabric)
			Kit.ellipsoid(df, "FormTorso", dcf * CF(0, 4.9, 0), V(1.45, 1.7, 1.0), Color3.fromRGB(196, 176, 150), KM.Fabric)
			Kit.vcyl(df, "FormNeck", dcf * CF(0, 5.95, 0), 0.4, 0.42, Color3.fromRGB(196, 176, 150), KM.Fabric)
			Kit.vcyl(df, "FormKnob", dcf * CF(0, 6.22, 0), 0.16, 0.2, KC.WoodDark, KM.Wood)
			-- a wedding dress, yellowed, half on it
			Kit.soft(df, "Dress", dcf * CF(0, 3.3, 0) * ANG(rad(4), 0, 0), V(1.7, 1.8, 1.25), 0.45, Color3.fromRGB(226, 218, 196), KM.Fabric)
			Kit.collider(df, dcf * CF(0, 3.1, 0), V(1.4, 6.2, 1.2))
			df.WorldPivot = dcf
		end
		-- an old steamer trunk by the walkway, lid open a crack
		do
			local tcf = F(-6, AY, 4.2, PZ)
			Kit.solid(attic, "Trunk", tcf * CF(0, 0.9, 0), V(3.2, 1.8, 1.8), Color3.fromRGB(90, 62, 40), KM.Wood)
			for _, sx in { -1.2, 1.2 } do
				Kit.box(attic, "TrunkStrap", tcf * CF(sx, 0.96, 0), V(0.22, 1.7, 1.84), Color3.fromRGB(60, 40, 28), KM.Leather)
			end
			Kit.box(attic, "TrunkLid", tcf * CF(0, 1.98, 0.08) * ANG(rad(-8), 0, 0), V(3.25, 0.2, 1.85), Color3.fromRGB(84, 58, 38), KM.Wood)
			Kit.box(attic, "TrunkLatch", tcf * CF(0, 1.45, -0.93), V(0.3, 0.35, 0.06), KC.Brass, KM.Metal)
		end
		-- the baby's crib, with one of Lily's old dolls in it, face down
		do
			local ccf = F(26, AY, -4.5, NX)
			local wood = Color3.fromRGB(236, 230, 220)
			for _, sx in { -2.1, 2.1 } do
				for _, sz in { -1.1, 1.1 } do
					Kit.box(attic, "CribPost", ccf * CF(sx, 1.6, sz), V(0.22, 3.2, 0.22), wood, KM.Wood)
				end
			end
			for _, sz in { -1.1, 1.1 } do
				Kit.box(attic, "CribRail", ccf * CF(0, 3.05, sz), V(4.2, 0.16, 0.16), wood, KM.Wood)
				for k = -7, 7 do
					Kit.box(attic, "CribBar", ccf * CF(k * 0.27, 2.05, sz), V(0.08, 1.9, 0.08), wood, KM.Wood)
				end
			end
			for _, sx in { -2.1, 2.1 } do
				Kit.box(attic, "CribEnd", ccf * CF(sx, 2.0, 0), V(0.16, 2.0, 2.2), wood, KM.Wood)
			end
			Kit.box(attic, "CribMattress", ccf * CF(0, 1.15, 0), V(4.0, 0.3, 2.0), Color3.fromRGB(200, 214, 228), KM.Fabric)
			Kit.collider(attic, ccf * CF(0, 1.6, 0), V(4.4, 3.2, 2.4))
			local doll = ccf * CF(0.4, 1.36, 0.1) * ANG(rad(90), 0, rad(20))
			Kit.ball(attic, "DollHead", (doll * CF(0, 0.45, 0)).Position, 0.42, Color3.fromRGB(236, 214, 196), KM.Plastic)
			Kit.ellipsoid(attic, "DollBody", doll, V(0.5, 0.7, 0.3), Color3.fromRGB(150, 60, 70), KM.Fabric)
		end
		-- the rocking chair, facing the nest (Events: "Rocker" rocks it)
		do
			local rk = Kit.model(attic, "Rocker")
			local rcf = F(-13, AY + 0.2, 10.4, NX) -- (on the walkway's level: its runners rest on the boards' edge)
			local wood = Color3.fromRGB(96, 66, 44)
			for _, sx in { -0.75, 0.75 } do
				-- the runners: three pieces bent into an arc
				for k, a in { -18, 0, 18 } do
					Kit.box(rk, "Runner", rcf * CF(sx, 0.18 + math.abs(a) / 100, (k - 2) * 0.95) * ANG(rad(a), 0, 0), V(0.14, 0.14, 1.0), wood, KM.Wood)
				end
				Kit.box(rk, "ChairLeg", rcf * CF(sx, 0.95, -0.55), V(0.14, 1.5, 0.14), wood, KM.Wood)
				Kit.box(rk, "ChairLeg", rcf * CF(sx, 0.95, 0.55), V(0.14, 1.5, 0.14), wood, KM.Wood)
				Kit.box(rk, "BackPost", rcf * CF(sx, 2.75, 0.68) * ANG(rad(-10), 0, 0), V(0.16, 3.6, 0.16), wood, KM.Wood)
				Kit.box(rk, "Arm", rcf * CF(sx, 2.35, 0) , V(0.14, 0.12, 1.4), wood, KM.Wood)
			end
			Kit.box(rk, "Seat", rcf * CF(0, 1.75, 0), V(1.65, 0.16, 1.4), wood, KM.Wood)
			for k = -2, 2 do
				Kit.box(rk, "Spindle", rcf * CF(k * 0.28, 2.95, 0.72) * ANG(rad(-10), 0, 0), V(0.08, 2.3, 0.08), wood, KM.Wood)
			end
			Kit.box(rk, "BackRail", rcf * CF(0, 4.35, 0.98) * ANG(rad(-10), 0, 0), V(1.7, 0.3, 0.12), wood, KM.Wood)
			-- a knitted blanket over the arm
			Kit.soft(rk, "Afghan", rcf * CF(0.85, 2.0, 0.1) * ANG(0, 0, rad(-80)), V(1.0, 0.1, 1.3), 0.04, Color3.fromRGB(150, 70, 60), KM.Fabric)
			rk.WorldPivot = rcf
		end
		-- a row of old porcelain dolls on a plank between two boxes, all looking at the hatch
		do
			local pcf = F(10.5, AY, -3.5, NX)
			Kit.cardboardBox(attic, pcf * CF(0, 0, -2.2), V(1.6, 1.6, 1.6), Color3.fromRGB(160, 130, 90), true)
			Kit.cardboardBox(attic, pcf * CF(0, 0, 2.2), V(1.6, 1.6, 1.6), Color3.fromRGB(150, 120, 84), true)
			Kit.box(attic, "Plank", pcf * CF(0, 1.68, 0), V(1.2, 0.16, 6.2), Color3.fromRGB(140, 110, 76), KM.Wood)
			local dresses = { Color3.fromRGB(140, 40, 50), Color3.fromRGB(60, 80, 140), Color3.fromRGB(230, 220, 200), Color3.fromRGB(90, 120, 80), Color3.fromRGB(180, 140, 170) }
			for i, c in dresses do
				local dz = -2.4 + (i - 1) * 1.2
				local d = pcf * CF(0, 1.76, dz)
				Kit.ellipsoid(attic, "DollDress", d * CF(0, 0.32, 0), V(0.5, 0.64, 0.42), c, KM.Fabric)
				Kit.ball(attic, "DollHead", (d * CF(0, 0.82, 0)).Position, 0.4, Color3.fromRGB(240, 226, 214), KM.Plastic)
				Kit.box(attic, "DollEye", d * CF(-0.08, 0.86, -0.19), V(0.06, 0.06, 0.02), Color3.fromRGB(20, 20, 24), KM.Plastic)
				Kit.box(attic, "DollEye", d * CF(0.08, 0.86, -0.19), V(0.06, 0.06, 0.02), Color3.fromRGB(20, 20, 24), KM.Plastic)
				Kit.ellipsoid(attic, "DollHair", d * CF(0, 0.98, 0.05), V(0.42, 0.22, 0.42), i % 2 == 0 and Color3.fromRGB(60, 40, 28) or Color3.fromRGB(200, 170, 110), KM.Fabric)
			end
		end
		-- boxes: moving boxes stacked, Christmas, "LILY BABY CLOTHES", a lamp without a shade
		for _, b in {
			{ 30, -9, V(2.2, 1.8, 2), 0 }, { 30.2, -9, V(1.8, 1.5, 1.7), 1.8 }, { 33, -6.5, V(2.4, 2, 2), 0 },
			{ 29.5, 2, V(2, 1.6, 2), 0 }, { 32.2, 2.6, V(2.2, 2.2, 2.2), 0 }, { 32.2, 2.6, V(1.6, 1.2, 1.6), 2.2 },
			{ -2, -6.5, V(2.2, 1.6, 1.8), 0 }, { 1, -7.5, V(1.8, 1.4, 1.8), 0 }, { -14, -7.5, V(2.4, 1.8, 2), 0 },
		} do
			Kit.cardboardBox(attic, F(b[1], AY + b[4], b[2], NX) * ANG(0, rad((b[1] * 7) % 20 - 10), 0), b[3], nil, true)
		end
		for _, t in { { 26, 8.5 }, { 28.4, 8.8 } } do
			Kit.box(attic, "XmasTub", CF(t[1], AY + 0.8, t[2]), V(2.2, 1.6, 1.6), Color3.fromRGB(200, 200, 196), KM.Plastic, { Transparency = 0.25 })
			Kit.box(attic, "XmasLid", CF(t[1], AY + 1.65, t[2]), V(2.3, 0.12, 1.7), Color3.fromRGB(160, 36, 34), KM.Plastic)
		end
		-- an old portrait leaning on the boxes: a man and a woman, their eyes scratched out
		do
			local pcf = F(31.6, AY + 1.6, -6.4, NX) * ANG(rad(-14), 0, 0)
			Kit.picture(attic, pcf, 2.4, 1.8, KC.WoodDark, 13)
			for _, dx in { -0.5, 0.5 } do
				for _, e in { -0.12, 0.12 } do
					Kit.box(attic, "Scratch", pcf * CF(dx + e, 0.25, -0.09) * ANG(0, 0, rad(e > 0 and 40 or -40)), V(0.3, 0.05, 0.02), Color3.fromRGB(240, 236, 228), KM.Plastic)
				end
			end
		end
		-- bare bulbs hanging from the ridge on long cords (lit: the attic was always lit by something)
		for _, b in { V(-8, 0, 9), V(16, 0, 3), V(-22, 0, 6) } do
			local top = 41.2 - 0.44 * math.abs(b.Z)
			local y = AY + 6.8
			Kit.box(attic, "BulbCord", CF(b.X, (top + y) / 2 + 0.25, b.Z), V(0.05, top - y - 0.5, 0.05), Color3.fromRGB(30, 28, 26), KM.Plastic)
			Kit.vcyl(attic, "BulbSocket", CF(b.X, y + 0.3, b.Z), 0.3, 0.24, Color3.fromRGB(40, 38, 34), KM.Metal)
			local bulb = Kit.ball(attic, "Bulb", V(b.X, y, b.Z), 0.36, Color3.fromRGB(255, 226, 170), KM.Neon)
			local l = Instance.new("PointLight")
			l.Range = 14
			l.Brightness = 0.55
			l.Color = Color3.fromRGB(255, 196, 130)
			l.Shadows = true
			l.Parent = bulb
		end
		-- cobwebs where the rafters meet the boards
		for _, c in { V(-36, AY + 1.2, 13), V(-28, AY + 1.2, -12), V(12, AY + 1.2, 13), V(20, AY + 1.2, -12), V(28, AY + 1.2, 12), V(36, AY + 1.2, -11) } do
			Kit.wedge(attic, "Cobweb", CF(c) * ANG(0, c.Z > 0 and 0 or math.pi, 0), V(0.02, 2.2, 2.2), Color3.fromRGB(226, 226, 226), KM.Fabric, { Transparency = 0.72 })
		end
	end

	---------------------------------------------------------------------------
	-- THE FRONT HALL, BACK HALF: a runner past the stairs, the family's photos on the wall by the
	-- basement stairs. In one, Grandma's face is scratched out.
	---------------------------------------------------------------------------
	do
		local hall = room("Hallway")
		-- (one layer, a field with its border beside it, not stacked: World/Depth thickens stacked rug layers)
		local rcf = F(2.2, G, 9.5, NZ)
		local field, edge = Color3.fromRGB(112, 50, 46), Color3.fromRGB(204, 172, 120)
		Kit.box(hall, "Runner", rcf * CF(0, 0.03, 0), V(3.6, 0.06, 14.2), field, KM.Fabric)
		for _, sx in { -1, 1 } do
			Kit.box(hall, "RunnerEdge", rcf * CF(sx * 2.0, 0.03, 0), V(0.4, 0.06, 15), edge, KM.Fabric)
		end
		for _, sz in { -1, 1 } do
			Kit.box(hall, "RunnerEdge", rcf * CF(0, 0.03, sz * 7.3), V(3.6, 0.06, 0.4), edge, KM.Fabric)
		end
		local frames = { { 4.5, 2.2, 1.7, 71 }, { 8.6, 1.7, 2.2, 72 }, { 12.4, 2.4, 1.8, 73 }, { 16.4, 1.7, 2.2, 74 } }
		for i, f in frames do
			Kit.picture(hall, F(5.6, G + 6.4 + ((i % 2 == 0) and 0.3 or 0), f[1], NX), f[2], f[3], i % 2 == 0 and KC.WoodDark or KC.Brass, f[4])
		end
		-- Grandma's portrait: her face gouged out, four nails at a time
		local s = F(5.6, G + 6.7, 16.4, NX)
		for k = -1.5, 1.5 do
			Kit.box(hall, "Scratch", s * CF(k * 0.1, 0.32 + k * 0.03, -0.11) * ANG(0, 0, rad(62)), V(0.8, 0.045, 0.02), Color3.fromRGB(236, 230, 220), KM.Plastic)
		end
		local _, bulb, light = Kit.sconce(hall, F(5.62, G + 7.8, 20.4, NX))
		ctx.Power.registerLight("Decor", bulb, light)
	end

	---------------------------------------------------------------------------
	-- THE KITCHEN: the drawing on the fridge (it rides the door when it opens)
	---------------------------------------------------------------------------
	do
		local kitchen = room("Kitchen")
		local d = kitchen:FindFirstChild("Drawing", true)
		if d and d:IsA("BasePart") then
			Haunt.familyDrawing(d)
		end
	end

	---------------------------------------------------------------------------
	-- LILY'S ROOM: her drawing taped to the wall by the door
	---------------------------------------------------------------------------
	do
		local lily = room("Lily")
		local cf = F(31.2, U + 5.0, 8.28, PZ)
		local p = paper(lily, "FriendDrawing", cf, V(1.6, 1.2, 0.02))
		Haunt.friendDrawing(p)
		for _, sx in { -1, 1 } do
			Kit.box(lily, "Tape", cf * CF(sx * 0.68, 0.52, -0.02) * ANG(0, 0, rad(sx * 35)), V(0.3, 0.1, 0.01), Color3.fromRGB(236, 230, 200), KM.Plastic)
		end
	end

	---------------------------------------------------------------------------
	-- THE UPSTAIRS HALL: long scratches in the ceiling round the attic hatch, four at a time
	---------------------------------------------------------------------------
	do
		local uh = room("UpperHall")
		local h = L.AtticHatch
		local y = 27.98 -- (just under the ceiling: the attic slab's underside is at 28)
		-- (yaw 0: a scratch runs along Z, beside the hatch's long sides; 90: along X, past its end)
		for g, at in { { h.x0 - 0.7, (h.z0 + h.z1) / 2, 0 }, { (h.x0 + h.x1) / 2, h.z1 + 0.8, 90 }, { h.x1 + 0.7, h.z0 + 2, 0 } } do
			for k = -1.5, 1.5 do
				local yaw = rad(at[3] + g * 7)
				Kit.box(uh, "CeilingScratch", CF(at[1], y, at[2]) * ANG(0, yaw, 0) * CF(k * 0.22, 0, 0), V(0.05, 0.02, 1.9 - math.abs(k) * 0.3), Color3.fromRGB(70, 56, 46), KM.Plastic)
			end
		end
	end

	---------------------------------------------------------------------------
	-- THE BASEMENT: a child's chair against the far wall, turned to face it, a doll sat on it
	---------------------------------------------------------------------------
	do
		local base = room("Basement")
		local ccf = F(-26.5, B, -28.9, NZ)
		local c = Color3.fromRGB(196, 214, 230)
		for _, sx in { -0.4, 0.4 } do
			for _, sz in { -0.4, 0.4 } do
				Kit.box(base, "CornerChairLeg", ccf * CF(sx, 0.4, sz), V(0.12, 0.8, 0.12), c, KM.Wood)
			end
		end
		Kit.box(base, "CornerChairSeat", ccf * CF(0, 0.85, 0), V(1.0, 0.12, 1.0), c, KM.Wood)
		Kit.box(base, "CornerChairBack", ccf * CF(0, 1.5, 0.44), V(1.0, 1.2, 0.1), c, KM.Wood)
		Kit.ellipsoid(base, "DollDress", ccf * CF(0, 1.25, 0.05), V(0.5, 0.65, 0.42), Color3.fromRGB(150, 40, 50), KM.Fabric)
		Kit.ball(base, "DollHead", (ccf * CF(0, 1.75, 0.05)).Position, 0.4, Color3.fromRGB(240, 226, 214), KM.Plastic)
		Kit.ellipsoid(base, "DollHair", ccf * CF(0, 1.86, 0.1), V(0.42, 0.24, 0.42), Color3.fromRGB(60, 40, 28), KM.Fabric)
	end

	local out = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and not existing[d] then
			table.insert(out, d)
		end
	end
	return out
end

return Haunt
