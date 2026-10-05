--[[
	Items — proper little models for the things you can pick up (scissors, the fire poker,
	walkie-talkies, mom's purse with the pepper spray, car keys, the basement key).

	Items.dress(hitbox, kind) keeps the existing part as an invisible hit box (the prompt, the
	pickup and every bit of game logic stay on it) and builds the model as its children, in its
	local space, so taking it (World/Anim.vanish) or Curtis stealing it carries the whole model.
]]

local Items = {}

local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad

local METAL = Color3.fromRGB(196, 198, 204)
local DARK_METAL = Color3.fromRGB(46, 46, 50)
local BRASS = Color3.fromRGB(196, 160, 82)
local BLACK = Color3.fromRGB(24, 24, 26)

local function part(parent: BasePart, name: string, local_: CFrame, size: Vector3, color: Color3, material: Enum.Material, shape: Enum.PartType?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = parent.CFrame * local_
	p.Parent = parent
	return p
end

-- a cylinder standing up (Roblox cylinders run along X)
local function vcyl(parent: BasePart, name: string, at: CFrame, length: number, d: number, color: Color3, material: Enum.Material): BasePart
	return part(parent, name, at * ANG(0, 0, rad(90)), V(length, d, d), color, material, Enum.PartType.Cylinder)
end
-- a flat disc lying in the XZ plane
local function disc(parent: BasePart, name: string, at: CFrame, d: number, thick: number, color: Color3, material: Enum.Material): BasePart
	return vcyl(parent, name, at, thick, d, color, material)
end
-- a disc facing along Z (hanging rings, key heads)
local function zdisc(parent: BasePart, name: string, at: CFrame, d: number, thick: number, color: Color3, material: Enum.Material): BasePart
	return part(parent, name, at * ANG(0, rad(90), 0), V(thick, d, d), color, material, Enum.PartType.Cylinder)
end

local BUILD = {}

-- scissors lying flat (long axis X, tips toward +X)
function BUILD.Scissors(h: BasePart)
	local red = Color3.fromRGB(205, 50, 50)
	for _, s in { -1, 1 } do
		part(h, "Blade", CF(0.16, 0, 0) * ANG(0, rad(s * 5), 0) * CF(0, 0.01 * s, 0), V(0.5, 0.03, 0.07), METAL, Enum.Material.Metal)
		disc(h, "Handle", CF(-0.24, 0, s * 0.085), 0.2, 0.05, red, Enum.Material.SmoothPlastic)
		disc(h, "HandleHole", CF(-0.24, 0.03, s * 0.085), 0.11, 0.02, Color3.fromRGB(235, 235, 232), Enum.Material.SmoothPlastic)
	end
	disc(h, "Pivot", CF(-0.08, 0.03, 0), 0.06, 0.03, DARK_METAL, Enum.Material.Metal)
end

-- the fire poker standing in its stand (long axis Y): a loop handle, the shaft, a hooked tip
function BUILD.Poker(h: BasePart)
	vcyl(h, "Shaft", CF(0, -0.1, 0), 3.2, 0.09, BLACK, Enum.Material.Metal)
	part(h, "Knob", CF(0, 1.55, 0), V(0.18, 0.18, 0.18), BRASS, Enum.Material.Metal, Enum.PartType.Ball)
	zdisc(h, "Loop", CF(0, 1.72, 0), 0.32, 0.05, BLACK, Enum.Material.Metal)
	zdisc(h, "LoopHole", CF(0, 1.72, 0), 0.2, 0.06, Color3.fromRGB(10, 10, 10), Enum.Material.Metal)
	part(h, "Hook", CF(0.1, -1.62, 0) * ANG(0, 0, rad(-40)), V(0.07, 0.36, 0.07), BLACK, Enum.Material.Metal)
	part(h, "Point", CF(-0.02, -1.74, 0), V(0.06, 0.2, 0.06), BLACK, Enum.Material.Metal)
end

-- a walkie-talkie standing up (front is -Z): body, grille, antenna, knob, a little light
function BUILD.Walkie(h: BasePart)
	local body = Color3.fromRGB(38, 40, 44)
	part(h, "Body", CF(0, -0.08, 0), V(0.5, 0.8, 0.28), body, Enum.Material.SmoothPlastic)
	part(h, "Grille", CF(0, 0.06, -0.145), V(0.38, 0.32, 0.02), Color3.fromRGB(20, 20, 22), Enum.Material.DiamondPlate)
	part(h, "Screen", CF(0, -0.24, -0.145), V(0.3, 0.12, 0.02), Color3.fromRGB(150, 190, 120), Enum.Material.Neon)
	vcyl(h, "Antenna", CF(0.14, 0.55, 0.02), 0.5, 0.06, BLACK, Enum.Material.SmoothPlastic)
	vcyl(h, "Knob", CF(-0.13, 0.36, 0.02), 0.1, 0.1, BLACK, Enum.Material.SmoothPlastic)
	part(h, "Light", CF(0, 0.36, 0.02), V(0.05, 0.03, 0.05), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
	part(h, "Clip", CF(0, 0.05, 0.16), V(0.16, 0.5, 0.04), Color3.fromRGB(28, 28, 30), Enum.Material.SmoothPlastic)
end

-- mom's old leather purse, a red can of pepper spray poking out of the top
function BUILD.Purse(h: BasePart)
	local leather = Color3.fromRGB(110, 62, 44)
	part(h, "Bag", CF(0, -0.18, 0), V(1.25, 0.72, 0.55), leather, Enum.Material.Leather)
	part(h, "Flap", CF(0, 0.12, -0.05) * ANG(rad(-12), 0, 0), V(1.27, 0.3, 0.58), Color3.fromRGB(92, 50, 36), Enum.Material.Leather)
	part(h, "Clasp", CF(0, 0.02, -0.31), V(0.16, 0.12, 0.04), BRASS, Enum.Material.Metal)
	for _, s in { -1, 1 } do
		part(h, "Strap", CF(s * 0.42, 0.42, 0) * ANG(0, 0, rad(s * 28)), V(0.07, 0.5, 0.05), Color3.fromRGB(80, 44, 32), Enum.Material.Leather)
	end
	part(h, "Strap", CF(0, 0.64, 0), V(0.42, 0.07, 0.05), Color3.fromRGB(80, 44, 32), Enum.Material.Leather)
	vcyl(h, "SprayCan", CF(0.36, 0.3, 0.08), 0.5, 0.2, Color3.fromRGB(200, 30, 30), Enum.Material.SmoothPlastic)
	vcyl(h, "SprayCap", CF(0.36, 0.6, 0.08), 0.12, 0.16, Color3.fromRGB(235, 235, 232), Enum.Material.SmoothPlastic)
end

-- car keys hanging from a hook (flat side facing Z): ring, two keys, the fob
function BUILD.CarKeys(h: BasePart)
	zdisc(h, "Ring", CF(0, 0.2, 0), 0.22, 0.03, METAL, Enum.Material.Metal)
	zdisc(h, "RingHole", CF(0, 0.2, 0), 0.15, 0.04, Color3.fromRGB(60, 50, 40), Enum.Material.Metal)
	part(h, "Key", CF(-0.05, -0.04, 0) * ANG(0, 0, rad(6)), V(0.07, 0.34, 0.02), METAL, Enum.Material.Metal)
	part(h, "KeyHead", CF(-0.06, 0.1, 0), V(0.14, 0.1, 0.025), BLACK, Enum.Material.SmoothPlastic)
	part(h, "Fob", CF(0.08, -0.08, 0), V(0.15, 0.24, 0.06), BLACK, Enum.Material.SmoothPlastic)
	part(h, "FobButton", CF(0.08, -0.04, -0.032), V(0.07, 0.05, 0.01), Color3.fromRGB(200, 40, 40), Enum.Material.SmoothPlastic)
end

-- the same keys dropped flat (on his pillow in the attic)
function BUILD.CarKeysFlat(h: BasePart)
	disc(h, "Ring", CF(-0.2, 0, 0), 0.24, 0.03, METAL, Enum.Material.Metal)
	part(h, "Key", CF(0.05, 0, -0.06) * ANG(0, rad(12), 0), V(0.36, 0.02, 0.07), METAL, Enum.Material.Metal)
	part(h, "Fob", CF(0.08, 0.02, 0.1), V(0.24, 0.06, 0.15), BLACK, Enum.Material.SmoothPlastic)
	part(h, "FobButton", CF(0.06, 0.055, 0.1), V(0.05, 0.01, 0.07), Color3.fromRGB(200, 40, 40), Enum.Material.SmoothPlastic)
end

-- an old brass key with a paper tag reading BSMT
function BUILD.BasementKey(h: BasePart)
	zdisc(h, "Ring", CF(0, 0.22, 0), 0.16, 0.03, BRASS, Enum.Material.Metal)
	zdisc(h, "Bow", CF(0, 0.07, 0), 0.17, 0.04, BRASS, Enum.Material.Metal)
	part(h, "Shaft", CF(0, -0.12, 0), V(0.05, 0.28, 0.03), BRASS, Enum.Material.Metal)
	for i = 0, 1 do
		part(h, "Tooth", CF(0.045, -0.2 + i * 0.07, 0), V(0.05, 0.04, 0.03), BRASS, Enum.Material.Metal)
	end
	local tag = part(h, "Tag", CF(0.14, 0.12, -0.01) * ANG(0, 0, rad(-12)), V(0.2, 0.13, 0.01), Color3.fromRGB(236, 230, 212), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(100, 65)
	gui.LightInfluence = 1
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = "BSMT"
	l.Font = Enum.Font.SpecialElite
	l.TextScaled = true
	l.TextColor3 = Color3.fromRGB(40, 36, 30)
	l.Parent = gui
	gui.Parent = tag
end

function Items.dress(hitbox: BasePart?, kind: string)
	local build = BUILD[kind]
	if not hitbox or not build then
		return
	end
	hitbox.Transparency = 1
	build(hitbox)
end

return Items
