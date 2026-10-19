--[[
	Dress — the lived-in layer: what a family leaves lying about a house at night. Toaster and
	coffee maker on the counter, a laundry basket by the dresser, posters and a games console in
	Jamie's room, a tea party for Lily's teddies, totes and a cooler in the garage, towels and
	hampers in the bathrooms.

	Built after Interior, into its room folders. Nothing here is used, hidden in or picked up:
	it all stays clear of doorways, door swings, hiding spots and their views, prompts, his
	walkways and the Halloween candy spots (tools/harness/dress_test.luau checks).

	Some pieces are stand-ins for Creator Store models (World/Props swaps them by PropKey, see
	Props.Models): plain Kit parts the model takes the place of once it loads, and what stays if
	it can't. A stand-in's box is the size and place the model gets.
]]

local Kit = require(script.Parent.Kit)

local Dress = {}

local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad

local PX, NX, PZ, NZ = V(1, 0, 0), V(-1, 0, 0), V(0, 0, 1), V(0, 0, -1)

-- a CFrame at (x, y, z) facing a horizontal direction (the front of a Kit model is local -Z)
local function F(x: number, y: number, z: number, dir: Vector3): CFrame
	return CFrame.lookAt(V(x, y, z), V(x + dir.X, y, z + dir.Z))
end

-- the posters on Jamie's walls: free Creator Store decals (World/Props puts the picture on)
Dress.Posters = {
	Basketball = 104507877605439, -- a flaming basketball, "BASKETBALL TOURNAMENT" (808 x 1024)
	Space = 97712165328370, -- a blue galaxy print, "SPACE EXPLORATION" (723 x 1023)
	Mars = 15957284733, -- the old "Flight to Mars" film poster (532 x 1023)
}

-- returns every part it added (World keeps them as refs.Dressing; dress_test checks them)
function Dress.build(ctx, root: Instance): { BasePart }
	local existing = {}
	for _, d in root:GetDescendants() do
		existing[d] = true
	end
	local L = ctx.Layout
	local G, U = L.Y.Ground, L.Y.Upstairs
	local KM, KC = Kit.M, Kit.C

	local function room(name: string): Instance
		return root:FindFirstChild(name) or root
	end

	-- a Creator Store stand-in: one box (the model's size and place) in a model named for its
	-- Props entry; `collide` adds an invisible collider of the same size
	local function holder(parent, key: string, cf: CFrame, size: Vector3, color: Color3, mat: Enum.Material?, collide: boolean?): Model
		local m = Kit.model(parent, key)
		Kit.box(m, key, cf * CF(0, size.Y / 2, 0), size, color, mat or KM.Plastic)
		if collide then
			Kit.collider(m, cf * CF(0, size.Y / 2, 0), size)
		end
		m:SetAttribute("PropKey", key)
		m.WorldPivot = cf -- (Props: the front is local -Z)
		return m
	end

	-- a round side table: a disc top on a turned stem (cf at the floor)
	local function sideTable(parent, cf: CFrame, d: number, h: number, color: Color3): Model
		local m = Kit.model(parent, "SideTable")
		local dark = Kit.darker(color, 0.15)
		Kit.vcyl(m, "TableTop", cf * CF(0, h - 0.07, 0), 0.14, d, color, KM.Wood)
		Kit.vcyl(m, "TableEdge", cf * CF(0, h - 0.17, 0), 0.08, d - 0.12, dark, KM.Wood)
		Kit.taper(m, "TableStem", cf * CF(0, 0.12, 0), h - 0.3, 0.32, 0.2, 3, dark, KM.Wood)
		Kit.vcyl(m, "TableFoot", cf * CF(0, 0.06, 0), 0.12, d * 0.55, dark, KM.Wood)
		Kit.collider(m, cf * CF(0, h / 2, 0), V(d * 0.8, h, d * 0.8))
		return m
	end

	-- a wicker hamper with its lid on and a sleeve hanging out (cf at the floor)
	local function hamper(parent, cf: CFrame, d: number, h: number, sleeve: Color3): Model
		local m = Kit.model(parent, "Hamper")
		local wicker = Color3.fromRGB(184, 150, 104)
		Kit.lathe(m, "Hamper", cf, { { 0, d * 0.84 }, { 0.08, d * 0.9 }, { h, d } }, wicker, KM.Fabric)
		for k = 0, 3 do
			Kit.vcyl(m, "HamperWeave", cf * CF(0, h * (0.18 + k * 0.22), 0), 0.07, d * (0.9 + k * 0.025) + 0.03, Kit.darker(wicker, 0.2), KM.Fabric)
		end
		Kit.vcyl(m, "HamperLid", cf * CF(0, h + 0.07, 0), 0.14, d + 0.08, Kit.darker(wicker, 0.1), KM.Fabric)
		Kit.ball(m, "HamperKnob", (cf * CF(0, h + 0.2, 0)).Position, 0.22, Kit.darker(wicker, 0.3), KM.Wood)
		-- (pinched under the lid at the front)
		Kit.soft(m, "Sleeve", cf * CF(0.15, h - 0.45, -d / 2 - 0.02) * ANG(rad(-6), 0, rad(8)), V(0.36, 0.95, 0.08), 0.03, sleeve, KM.Fabric)
		Kit.collider(m, cf * CF(0, h / 2, 0), V(d, h, d))
		return m
	end

	-- folded towels stacked on a surface (cf at the surface)
	local function towels(parent, cf: CFrame, w: number, d: number, colors: { Color3 })
		local y = 0
		for i, c in colors do
			local t = 0.2
			Kit.soft(parent, "FoldedTowel", cf * CF(0, y + t / 2, 0) * ANG(0, rad((i % 2 == 0) and 3 or -2), 0), V(w, t, d), 0.07, c, KM.Fabric)
			Kit.box(parent, "TowelBand", cf * CF(0, y + t / 2, -d / 2 + 0.02) * ANG(0, rad((i % 2 == 0) and 3 or -2), 0), V(w * 0.94, 0.05, 0.02), Kit.lighter(c, 0.4), KM.Fabric)
			y += t
		end
	end

	-- a cup with toothbrushes, and a soap pump (cf at the surface)
	local function toothbrushCup(parent, cf: CFrame, cup: Color3)
		Kit.lathe(parent, "BrushCup", cf, { { 0, 0.26 }, { 0.42, 0.32 } }, cup, KM.Plastic)
		for i, c in { Color3.fromRGB(60, 140, 220), Color3.fromRGB(230, 90, 120) } do
			local s = i == 1 and 1 or -1
			Kit.box(parent, "Toothbrush", cf * CF(s * 0.04, 0.5, 0) * ANG(0, 0, rad(s * 12)), V(0.06, 0.75, 0.05), c, KM.Plastic)
		end
	end
	local function soapPump(parent, cf: CFrame, color: Color3)
		Kit.vcyl(parent, "SoapBottle", cf * CF(0, 0.25, 0), 0.5, 0.3, color, KM.Plastic)
		Kit.vcyl(parent, "PumpNeck", cf * CF(0, 0.58, 0), 0.16, 0.08, KC.Chrome, KM.Metal)
		Kit.box(parent, "PumpHead", cf * CF(0, 0.68, -0.06), V(0.08, 0.06, 0.2), KC.Chrome, KM.Metal)
	end

	-- a poster pinned to the wall (cf = its centre, facing out of the wall)
	local function poster(parent, cf: CFrame, w: number, h: number, decal: number, fallback: Color3)
		local m = Kit.model(parent, "Poster")
		local paper = Kit.box(m, "PosterPaper", cf, V(w, h, 0.03), fallback, KM.Plastic)
		paper:SetAttribute("ArtDecal", string.format("%d", decal))
		paper:SetAttribute("ArtFace", "Front")
		for _, sx in { -1, 1 } do
			Kit.box(m, "Tape", cf * CF(sx * (w / 2 - 0.12), h / 2 - 0.08, -0.02) * ANG(0, 0, rad(sx * 35)), V(0.32, 0.1, 0.01), Color3.fromRGB(236, 230, 200), KM.Plastic)
		end
		return m
	end

	-- a child's chair (cf at the floor, facing the way you'd sit)
	local function kidChair(parent, cf: CFrame, color: Color3): Model
		local m = Kit.model(parent, "KidChair")
		local seatY = 0.85
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				Kit.box(m, "ChairLeg", cf * CF(sx * 0.4, (seatY - 0.06) / 2, sz * 0.4), V(0.12, seatY - 0.06, 0.12), color, KM.Wood)
			end
		end
		Kit.soft(m, "ChairSeat", cf * CF(0, seatY - 0.04, 0), V(1.0, 0.2, 1.0), 0.05, color, KM.Wood)
		Kit.soft(m, "ChairBack", cf * CF(0, seatY + 0.6, 0.44), V(1.0, 0.9, 0.1), 0.05, color, KM.Wood)
		for _, sx in { -1, 1 } do
			Kit.box(m, "BackPost", cf * CF(sx * 0.4, seatY + 0.3, 0.44), V(0.1, 0.5, 0.1), color, KM.Wood)
		end
		Kit.collider(m, cf * CF(0, 0.75, 0), V(1.0, 1.5, 1.0))
		return m
	end

	---------------------------------------------------------------------------
	-- KITCHEN: the counters (west run, top at G + 3.8, fronts facing +X)
	---------------------------------------------------------------------------
	do
		local kitchen = room("Kitchen")
		local top = G + 3.8
		local towelHolder = holder(kitchen, "PaperTowels", F(-38.5, top, 4.75, PX), V(0.8, 1.3, 0.8), Color3.fromRGB(240, 238, 232))
		Kit.vcyl(towelHolder, "HolderBase", F(-38.5, top, 4.75, PX) * CF(0, 0.03, 0), 0.06, 0.8, KC.WoodMid, KM.Wood)
		local block = holder(kitchen, "KnifeBlock", F(-38.55, top, 6.6, PX), V(0.6, 1.3, 0.6), KC.WoodMid, KM.Wood)
		for k = -1, 1 do
			Kit.box(block, "KnifeHandle", F(-38.55, top, 6.6, PX) * CF(k * 0.15, 1.15, 0.1) * ANG(rad(-15), 0, 0), V(0.1, 0.4, 0.14), KC.Black, KM.Plastic)
		end
		local toaster = holder(kitchen, "Toaster", F(-38.1, top, 9.0, PX), V(1.5, 0.95, 0.75), Color3.fromRGB(196, 198, 202), KM.Metal)
		for k = -1, 1, 2 do
			Kit.box(toaster, "ToasterSlot", F(-38.1, top, 9.0, PX) * CF(0, 0.951, k * 0.15), V(1.0, 0.01, 0.12), KC.Black, KM.Plastic)
		end
		local coffee = holder(kitchen, "CoffeeMaker", F(-38.25, top, 19.7, PX), V(1.2, 1.5, 0.8), Color3.fromRGB(30, 30, 32), KM.Plastic)
		Kit.vcyl(coffee, "CoffeePot", F(-38.25, top, 19.7, PX) * CF(0, 0.35, -0.42), 0.6, 0.5, Color3.fromRGB(70, 50, 40), KM.Glass)
		-- the utensil crock by the range, and a cutting board leant on the backsplash
		local crock = F(-38.45, top, 25.75, PX)
		Kit.lathe(kitchen, "Crock", crock, { { 0, 0.26 }, { 0.62, 0.32 }, { 0.7, 0.3 } }, Color3.fromRGB(226, 220, 204), KM.Plastic)
		for i, tool in { { 0.9, Color3.fromRGB(150, 110, 70) }, { 1.0, Color3.fromRGB(40, 40, 44) }, { 0.85, Color3.fromRGB(150, 110, 70) } } do
			local a = (i - 2) * 0.32
			Kit.box(kitchen, "Utensil", crock * CF(math.sin(a) * 0.1, 0.62 + tool[1] / 2 - 0.25, math.cos(a) * 0.06) * ANG(0, 0, -a), V(0.08, tool[1], 0.05), tool[2], KM.Wood)
			Kit.ellipsoid(kitchen, "UtensilHead", crock * CF(math.sin(a) * (0.1 + tool[1] * 0.45), 0.62 + tool[1] - 0.2, math.cos(a) * 0.06) * ANG(0, 0, -a), V(0.2, 0.3, 0.06), tool[2], KM.Wood)
		end
		Kit.soft(kitchen, "CuttingBoard", CF(-38.8, top + 0.8, 27.25) * ANG(0, 0, rad(8)), V(0.08, 1.6, 1.15), 0.04, Color3.fromRGB(176, 130, 82), KM.Wood)
	end

	---------------------------------------------------------------------------
	-- MASTER BEDROOM
	---------------------------------------------------------------------------
	do
		local master = room("Master")
		-- a bench under the front window, a folded throw and a paperback on it
		Kit.bench(master, F(-16, U, -28.2, PZ), 5.4, Kit.C.WoodDark, Color3.fromRGB(158, 146, 124))
		Kit.soft(master, "FoldedThrow", F(-14.4, U + 2.4, -28.2, PZ) * ANG(0, rad(4), 0), V(1.7, 0.28, 1.4), 0.1, Color3.fromRGB(120, 130, 150), KM.Fabric)
		Kit.book(master, F(-17.6, U + 2.4, -28.1, PZ) * ANG(0, rad(-18), 0), V(0.9, 0.16, 1.2), Color3.fromRGB(140, 50, 44))
		-- the laundry basket by the dresser, clothes heaped in it
		holder(master, "LaundryBasket", F(-10.1, U, -19.4, NX) * ANG(0, rad(8), 0), V(1.8, 1.1, 2.3), Color3.fromRGB(236, 236, 232), KM.Plastic, true)
		for i, c in { Color3.fromRGB(70, 90, 130), Color3.fromRGB(226, 220, 206), Color3.fromRGB(150, 60, 60), Color3.fromRGB(90, 110, 90) } do
			Kit.ellipsoid(master, "Clothes", F(-10.1, U, -19.4, NX) * CF(((i % 2) - 0.5) * 0.6, 0.95 + i * 0.03, (i - 2.5) * 0.4) * ANG(0, i * 1.3, rad(i * 4)), V(1.2, 0.3, 0.8), c, KM.Fabric)
		end
		-- a side table by the reading chair: books and a mug
		sideTable(master, F(-33.5, U, -28.0, PZ), 1.6, 2.0, Kit.C.WoodDark)
		Kit.bookStack(master, F(-33.6, U + 2.0, -28.05, PZ), 2, 41)
		Kit.mug(master, F(-33.0, U + 2.0, -27.55, PZ), Color3.fromRGB(226, 220, 206))
		-- a console under the painting on the bathroom wall: flowers, photos, a jewellery box
		local _, conH = Kit.consoleTable(master, F(-17.9, U, -1.35, NZ), 5, 1.3, Kit.C.WoodDark)
		Kit.vaseFlowers(master, F(-19.5, U + conH, -1.4, NZ), 1.0, Color3.fromRGB(70, 110, 140), Color3.fromRGB(240, 236, 226), 13)
		Kit.photoFrame(master, F(-17.9, U + conH, -1.5, NZ), 0.9, 1.1, Kit.C.Brass, 33)
		Kit.photoFrame(master, F(-16.8, U + conH, -1.35, NZ) * ANG(0, rad(-14), 0), 0.8, 0.6, Kit.C.WoodDark, 34)
		Kit.box(master, "JewelleryBox", F(-15.9, U + conH + 0.22, -1.3, NZ) * ANG(0, rad(10), 0), V(0.9, 0.44, 0.6), Color3.fromRGB(110, 40, 46), KM.Fabric)
		Kit.box(master, "JewelleryLid", F(-15.9, U + conH + 0.47, -1.3, NZ) * ANG(0, rad(10), 0), V(0.94, 0.06, 0.64), Kit.C.Brass, KM.Metal)
		-- her slippers beside the bed (on the rug)
		for i, x in { -33.6, -33.0 } do
			local s = F(x, U + 0.1, -18.75, PX) * ANG(0, rad(i == 1 and 6 or -4), 0)
			Kit.soft(master, "Slipper", s * CF(0, 0.08, 0), V(0.95, 0.16, 0.4), 0.07, Color3.fromRGB(196, 170, 150), KM.Fabric)
			Kit.soft(master, "SlipperToe", s * CF(-0.25, 0.2, 0), V(0.45, 0.12, 0.38), 0.05, Color3.fromRGB(210, 186, 168), KM.Fabric)
		end
		Kit.plant(master, F(-38.3, U, -6.3, PX), 1.4, "tree")
	end

	---------------------------------------------------------------------------
	-- JAMIE'S ROOM: a teenager's
	---------------------------------------------------------------------------
	do
		local jamie = room("Jamie")
		-- a dresser with the old TV and the console on it
		local dcf = F(-16.4, U, 13.7, PZ)
		local _, dH = Kit.dresser(jamie, dcf, 5.0, Kit.C.WoodMid)
		Kit.tv(jamie, F(-17.4, U + dH, 13.5, PZ), 2.8, 1.7, true)
		Kit.gameConsole(jamie, F(-14.9, U + dH, 13.6, PZ))
		Kit.controller(jamie, F(-14.8, U + dH + 0.4, 13.75, PZ) * ANG(0, rad(20), 0))
		-- posters
		poster(jamie, F(-16.4, U + 8.0, 12.395, PZ), 2.2, 2.8, Dress.Posters.Basketball, Color3.fromRGB(40, 30, 30))
		poster(jamie, F(-8.43, U + 7.4, 16.0, NX), 2.3, 3.25, Dress.Posters.Space, Color3.fromRGB(150, 170, 200))
		poster(jamie, F(-8.43, U + 7.4, 19.3, NX) * ANG(0, 0, rad(2)), 1.75, 3.35, Dress.Posters.Mars, Color3.fromRGB(200, 120, 60))
		-- a basketball in the corner
		local ball = V(-10.3, U + 0.52, 13.3)
		Kit.ball(jamie, "Basketball", ball, 1.0, Color3.fromRGB(214, 108, 44), KM.Rubber)
		Kit.vcyl(jamie, "BallSeam", CF(ball), 0.04, 1.01, Color3.fromRGB(30, 22, 20), KM.Rubber)
		Kit.vcyl(jamie, "BallSeam", CF(ball) * ANG(0, rad(30), rad(90)), 0.04, 1.01, Color3.fromRGB(30, 22, 20), KM.Rubber)
		-- dumbbells by the wall
		for i, p in { V(-27.0, 0, 13.3), V(-25.7, 0, 13.7) } do
			local d = CF(p.X, U + 0.24, p.Z) * ANG(0, rad(i * 14), 0)
			Kit.cyl(jamie, "DumbbellBar", d, 1.3, 0.14, KC.Steel, KM.Metal)
			for _, s in { -1, 1 } do
				Kit.cyl(jamie, "DumbbellPlate", d * CF(s * 0.5, 0, 0), 0.22, 0.48, Color3.fromRGB(34, 34, 38), KM.Metal)
			end
		end
		-- his sneakers by the closet
		for i = 0, 1 do
			Kit.shoe(jamie, F(-20.6 - i * 0.55, U, 28.3 - i * 0.15, NZ) * ANG(0, rad(i * 12 - 4), 0), Color3.fromRGB(230, 230, 232))
		end
		-- a skateboard on the floor
		local sk = F(-13.6, U, 18.2, NZ) * ANG(0, rad(25), 0)
		Kit.soft(jamie, "SkateDeck", sk * CF(0, 0.34, 0), V(0.8, 0.07, 2.7), 0.03, Color3.fromRGB(28, 28, 30), KM.Wood)
		Kit.box(jamie, "SkateGraphic", sk * CF(0, 0.303, 0), V(0.7, 0.01, 2.2), Color3.fromRGB(196, 60, 50), KM.Plastic)
		for _, z in { -0.85, 0.85 } do
			Kit.box(jamie, "SkateTruck", sk * CF(0, 0.24, z), V(0.7, 0.1, 0.14), KC.Steel, KM.Metal)
			for _, x in { -0.36, 0.36 } do
				Kit.cyl(jamie, "SkateWheel", sk * CF(x, 0.13, z), 0.14, 0.26, Color3.fromRGB(236, 224, 190), KM.Plastic)
			end
		end
	end

	---------------------------------------------------------------------------
	-- LILY'S ROOM: a play tent, a rocking horse, a tea party for her bears
	---------------------------------------------------------------------------
	do
		local lily = room("Lily")
		local rugY = U + 0.075 -- (the top of the round rug's inner disc, 4 studs round (24, 17))
		local tent = holder(lily, "Tipi", F(20.2, U, 10.6, PZ), V(3.6, 4.6, 3.6), Color3.fromRGB(232, 220, 196), KM.Fabric)
		Kit.collider(tent, F(20.2, U, 10.6, PZ) * CF(0, 1.6, 0), V(2.6, 3.2, 2.6))
		holder(lily, "RockingHorse", F(30.3, U, 17.5, NX), V(3.3, 2.4, 1.1), Color3.fromRGB(176, 120, 70), KM.Wood, true)
		-- the tea party: a little table, three chairs, two of her bears and the tea set
		local tc = V(24, rugY, 15.2)
		local tcf = CF(tc)
		Kit.vcyl(lily, "TeaTableTop", tcf * CF(0, 1.44, 0), 0.12, 2.3, Color3.fromRGB(246, 240, 236), KM.Wood)
		Kit.vcyl(lily, "TeaTableStem", tcf * CF(0, 0.72, 0), 1.32, 0.3, Color3.fromRGB(236, 190, 206), KM.Wood)
		Kit.vcyl(lily, "TeaTableFoot", tcf * CF(0, 0.05, 0), 0.1, 1.2, Color3.fromRGB(236, 190, 206), KM.Wood)
		Kit.collider(lily, tcf * CF(0, 0.75, 0), V(2.0, 1.5, 2.0))
		local chairs = {
			{ F(22.35, rugY, 15.2, PX), Color3.fromRGB(150, 200, 230), "TeddyPink" },
			{ F(25.65, rugY, 15.2, NX), Color3.fromRGB(250, 214, 120), "TeddyBrown" },
			{ F(24, rugY, 13.55, PZ), Color3.fromRGB(196, 230, 190), nil },
		}
		for _, c in chairs do
			kidChair(lily, c[1], c[2])
			local key = c[3]
			if key then
				-- (a Kit bear sat on the seat; Props puts the store bear in its place)
				local at = c[1] * CF(0, 0.91, 0.05)
				local bear = Kit.teddy(lily, at, 0.8, key == "TeddyPink" and Color3.fromRGB(230, 180, 190) or Color3.fromRGB(150, 110, 80))
				bear:SetAttribute("PropKey", key)
				bear.WorldPivot = at
			end
		end
		holder(lily, "TeaSet", CF(tc + V(0, 1.5, 0)) * ANG(0, rad(30), 0), V(1.3, 0.8, 1.2), Color3.fromRGB(240, 200, 214), KM.Plastic)
		-- building blocks on the rug, two stacked
		for i, b in { { V(21.3, 0, 18.4), Color3.fromRGB(220, 70, 70), 0 }, { V(21.9, 0, 18.9), Color3.fromRGB(70, 120, 220), 0 }, { V(21.9, 0.45, 18.9), Color3.fromRGB(240, 200, 60), 1 }, { V(21.1, 0, 19.3), Color3.fromRGB(80, 180, 100), 0 } } do
			Kit.box(lily, "ToyBlock", CF(b[1].X, rugY + b[1].Y + 0.225, b[1].Z) * ANG(0, rad(i * 23), 0), V(0.45, 0.45, 0.45), b[2], KM.Wood)
		end
		-- a low toy shelf by the fish tank, a bear and a ball on top
		-- (its own key: the store bookshelf that replaces the house's bookcases is dark wood and full of old books)
		Kit.bookcase(lily, F(38.5, U, 13.6, NX), 3.6, 1.1, 3.6, 2, Color3.fromRGB(240, 236, 230), 77):SetAttribute("PropKey", "ToyShelf")
		Kit.teddy(lily, F(38.55, U + 3.8, 12.7, NX), 0.6, Color3.fromRGB(240, 220, 180))
		Kit.ball(lily, "Ball", V(38.5, U + 3.8 + 0.35, 14.6), 0.7, Color3.fromRGB(110, 170, 230), KM.Plastic)
	end

	---------------------------------------------------------------------------
	-- DEN: an armchair by the side window, a console behind the sofa
	---------------------------------------------------------------------------
	do
		local den = room("Den")
		Kit.armchair(den, F(37.0, G, 18.6, NX), Color3.fromRGB(120, 70, 50))
		sideTable(den, F(37.6, G, 21.75, NX), 1.5, 2.1, Kit.C.WoodMid)
		Kit.mug(den, F(37.4, G + 2.1, 21.55, NX), Color3.fromRGB(190, 70, 60))
		Kit.book(den, F(37.8, G + 2.1, 22.0, NX) * ANG(0, rad(25), 0), V(0.8, 0.14, 1.0), Color3.fromRGB(40, 70, 110))
		local _, conH = Kit.consoleTable(den, F(21.5, G, 20.3, PZ), 7, 1.2, Kit.C.WoodDark)
		Kit.photoFrame(den, F(19.2, G + conH, 20.35, PZ), 1.0, 0.8, Kit.C.Brass, 51)
		Kit.photoFrame(den, F(20.4, G + conH, 20.2, PZ) * ANG(0, rad(12), 0), 0.7, 0.9, Kit.C.WoodDark, 52)
		Kit.vaseFlowers(den, F(23.2, G + conH, 20.3, PZ), 1.0, Color3.fromRGB(226, 220, 206), Color3.fromRGB(210, 120, 60), 17)
		Kit.bookStack(den, F(24.6, G + conH, 20.3, PZ), 3, 53)
	end

	---------------------------------------------------------------------------
	-- UPSTAIRS HALL: a low bookcase and the laundry at the back, a plant at the front
	---------------------------------------------------------------------------
	do
		local uhall = room("UpperHall")
		-- (kept Kit-built: the store bookshelf would be taller than this and swallow what stands on top)
		Kit.bookcase(uhall, F(-4.6, U, 28.6, NZ), 4.6, 1.1, 4.4, 2, Kit.C.WoodMid, 61):SetAttribute("PropKey", "LowBookcase")
		Kit.photoFrame(uhall, F(-5.6, U + 4.6, 28.7, NZ), 0.9, 0.7, Kit.C.WoodDark, 62)
		Kit.plant(uhall, F(-3.3, U + 4.6, 28.7, NZ), 0.6, "leafy", Color3.fromRGB(236, 232, 222))
		holder(uhall, "LaundryBasket", F(1.4, U, 28.05, NZ) * ANG(0, rad(-6), 0), V(2.3, 1.1, 1.8), Color3.fromRGB(236, 236, 232), KM.Plastic, true)
		for i, c in { Color3.fromRGB(226, 220, 206), Color3.fromRGB(230, 180, 190), Color3.fromRGB(110, 140, 170) } do
			Kit.ellipsoid(uhall, "Clothes", F(1.4, U, 28.05, NZ) * CF((i - 2) * 0.5, 0.95 + i * 0.03, ((i % 2) - 0.5) * 0.4) * ANG(0, i * 1.1, rad(i * 5)), V(1.1, 0.3, 0.8), c, KM.Fabric)
		end
		Kit.plant(uhall, F(-6.7, U, -28.6, PX), 1.3, "tree")
	end

	---------------------------------------------------------------------------
	-- GARAGE: storage totes, a shelf of paint over the bins, the camping cooler
	---------------------------------------------------------------------------
	do
		local garage = room("Garage")
		for i = 0, 1 do
			local t = F(41.8, G + i * 1.35, 1.6, PX) * ANG(0, rad(i * 5), 0)
			Kit.box(garage, "Tote", t * CF(0, 0.6, 0), V(2.5, 1.2, 1.7), Color3.fromRGB(120, 130, 140), KM.Plastic)
			Kit.soft(garage, "ToteLid", t * CF(0, 1.27, 0), V(2.6, 0.14, 1.8), 0.05, Color3.fromRGB(60, 90, 140), KM.Plastic)
		end
		Kit.collider(garage, F(41.8, G, 1.6, PX) * CF(0, 1.35, 0), V(2.6, 2.7, 1.8))
		-- a shelf on the back wall over the bins
		local shelfY = G + 6.0
		Kit.box(garage, "WallShelf", CF(48.6, shelfY, 5.05), V(4.6, 0.18, 0.86), Kit.C.WoodLight, KM.Wood)
		for _, x in { 46.8, 50.4 } do
			Kit.box(garage, "ShelfBracket", CF(x, shelfY - 0.4, 5.38), V(0.14, 0.62, 0.2), Color3.fromRGB(70, 70, 74), KM.Metal)
		end
		Kit.paintCan(garage, F(47.3, shelfY + 0.09, 5.05, NZ), Color3.fromRGB(230, 228, 220))
		Kit.paintCan(garage, F(48.3, shelfY + 0.09, 5.0, NZ), Color3.fromRGB(150, 60, 50))
		Kit.vcyl(garage, "SprayCan", CF(49.3, shelfY + 0.09 + 0.45, 5.1), 0.9, 0.3, Color3.fromRGB(40, 120, 60), KM.Metal)
		Kit.cardboardBox(garage, F(50.2, shelfY + 0.09, 5.05, NZ), V(0.9, 0.7, 0.7), nil, false)
		-- the camping cooler and a fuel can by the tyres
		holder(garage, "Cooler", F(41.6, G, -24.6, PX), V(2.4, 1.35, 1.5), Color3.fromRGB(190, 40, 40), KM.Plastic, true)
		local can = F(43.25, G, -25.7, PX) * ANG(0, rad(-20), 0)
		Kit.soft(garage, "FuelCan", can * CF(0, 0.5, 0), V(0.5, 1.0, 0.85), 0.08, Color3.fromRGB(196, 36, 30), KM.Plastic)
		Kit.box(garage, "FuelCanHandle", can * CF(0, 1.05, 0.1), V(0.12, 0.12, 0.5), Color3.fromRGB(150, 28, 24), KM.Plastic)
		Kit.box(garage, "FuelCanSpout", can * CF(0, 1.1, -0.32) * ANG(rad(-35), 0, 0), V(0.12, 0.35, 0.12), KC.Black, KM.Plastic)
	end

	---------------------------------------------------------------------------
	-- BATHROOMS: towels, toothbrushes, hampers
	---------------------------------------------------------------------------
	do
		local mbath = room("MasterBath")
		local vTop = U + 3.4
		towels(mbath, F(-12.55, vTop, 10.25, NZ), 0.8, 1.0, { Color3.fromRGB(236, 232, 222), Color3.fromRGB(236, 232, 222), Color3.fromRGB(176, 196, 206) })
		soapPump(mbath, F(-16.2, vTop, 10.65, NZ), Color3.fromRGB(190, 220, 210))
		toothbrushCup(mbath, F(-15.75, vTop, 10.7, NZ), Color3.fromRGB(226, 226, 222))
		hamper(mbath, F(-14.0, U, 1.3, PZ), 1.4, 2.3, Color3.fromRGB(110, 130, 160))

		local hbath = room("HallBath")
		towels(hbath, F(15.3, vTop, -4.4, PZ), 0.8, 0.9, { Color3.fromRGB(230, 200, 120), Color3.fromRGB(236, 232, 222) })
		toothbrushCup(hbath, F(19.6, vTop, -4.85, PZ), Color3.fromRGB(150, 190, 220))
		hamper(hbath, F(14.3, U, 6.55, NZ), 1.3, 2.2, Color3.fromRGB(200, 90, 90))
	end

	local added = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and not existing[d] then
			table.insert(added, d)
		end
	end
	return added
end

return Dress
