--[[
	ToolService — the usable items are Roblox tools in your hotbar (the owner: the action buttons were
	"so crowded, just use the Roblox inventory"). Equip one (1-9, or tap it), click / tap to use it.

	• Flashlight, Taser, Pepper spray, Rocket launcher, Energy drink, Firecracker: each is a Tool in the
	  Backpack while InventoryService says you have one (Inventory.sync calls Tools.refresh), named
	  with what's left ("Taser (3)"), with a small model in the hand.
	• Using one: the client sends the use with where you're aiming (Remotes.UseItem, client Gear); a
	  click switches the flashlight on and off (put away, it goes off).
	• Hiding, tied up, dead, out of the house or being him: nothing in your hands.
	Keys, tape, the remote and the other story items stay in the HUD's list: you don't use those by hand.
]]

local Players = game:GetService("Players")

local Tools = {}
local ctx

Tools.Items = { "Flashlight", "Taser", "PepperSpray", "Rocket", "EnergyDrink", "Firecracker", "NightVision" }
local IS_TOOL = {}
for _, k in Tools.Items do
	IS_TOOL[k] = true
end

-- Icon: the hotbar picture (v100), one set of plain white silhouettes from the Creator Store (public
-- images: "flashlight GUI", a white taser, "Graffiti Spray Can White", "Rocket Launcher", a white
-- can, "Bomb" as a firecracker). With a picture the hotbar shows no name, so what's left goes in the
-- tool's Count attribute and the client shows it above the hotbar while it's in your hand (Gear).
local INFO = {
	Flashlight = { Name = "Flashlight", Icon = 11697193612, Tip = "Click to switch it on and off. A lit flashlight shows him where you are." },
	Taser = { Name = "Taser", Icon = 113603668207377, Unit = "shot", Tip = "Click where he is: stuns him, then he can only limp after you." },
	PepperSpray = { Name = "Pepper spray", Icon = 127709193173096, Tip = "Click when he's close: he can't see, and backs off." },
	Rocket = { Name = "Rocket launcher", Icon = 13577018040, Unit = "rocket", Tip = "Click where he is: knocks him flat. It's LOUD." },
	EnergyDrink = { Name = "Energy drink", Icon = 9307558976, Tip = "Click to drink: 10 s of sprinting that never tires you." },
	Firecracker = { Name = "Firecracker", Icon = 13590809075, Tip = "Click where to throw it: the bang draws him away." },
	-- (v108, the Night Vision pass: "Night Vision Button On" by The Art Of Battles, public domain)
	NightVision = { Name = "Night vision", Icon = 114274096276149, Tip = "Click to see in the dark. 60 seconds of charge a night." },
}
Tools.Info = INFO -- (tests)

function Tools.isTool(item: string): boolean
	return IS_TOOL[item] == true
end

local function piece(tool: Tool, handle: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, mat: Enum.Material?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = handle.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = handle
	w.Part1 = p
	w.Parent = p
	p.Parent = tool
	return p
end

-- (v161) the rolled weapons' models: blades and the bat stand up from the grip (+Y), guns point ahead (-Z)
local function buildWeapon(tool: Tool, handle: BasePart, item: string)
	local wood = Color3.fromRGB(150, 104, 62)
	local steel = Color3.fromRGB(196, 200, 210)
	local black = Color3.fromRGB(24, 24, 28)
	handle.Size = Vector3.new(0.26, 0.9, 0.26)
	handle.Color = black
	if item == "Bat" then
		handle.Color = Color3.fromRGB(40, 36, 34)
		piece(tool, handle, "Barrel", Vector3.new(0.38, 2.2, 0.38), CFrame.new(0, 1.5, 0), wood, Enum.Material.Wood)
		piece(tool, handle, "End", Vector3.new(0.44, 0.5, 0.44), CFrame.new(0, 2.7, 0), wood, Enum.Material.Wood)
		piece(tool, handle, "Knob", Vector3.new(0.34, 0.1, 0.34), CFrame.new(0, -0.48, 0), black)
	elseif item == "Axe" then
		handle.Color = wood
		handle.Material = Enum.Material.Wood
		piece(tool, handle, "Haft", Vector3.new(0.22, 2.2, 0.22), CFrame.new(0, 1.4, 0), wood, Enum.Material.Wood)
		piece(tool, handle, "Head", Vector3.new(0.14, 0.7, 0.9), CFrame.new(0, 2.25, -0.4), steel, Enum.Material.Metal)
		piece(tool, handle, "Edge", Vector3.new(0.06, 0.9, 0.12), CFrame.new(0, 2.25, -0.9), Color3.fromRGB(235, 238, 245), Enum.Material.Metal)
		piece(tool, handle, "Back", Vector3.new(0.2, 0.4, 0.3), CFrame.new(0, 2.25, 0.2), Color3.fromRGB(60, 60, 66), Enum.Material.Metal)
	elseif item == "Dagger" then
		handle.Size = Vector3.new(0.2, 0.6, 0.2)
		piece(tool, handle, "Guard", Vector3.new(0.6, 0.1, 0.18), CFrame.new(0, 0.35, 0), Color3.fromRGB(80, 150, 255), Enum.Material.Metal)
		piece(tool, handle, "Blade", Vector3.new(0.18, 1.0, 0.05), CFrame.new(0, 0.9, 0), steel, Enum.Material.Metal)
		piece(tool, handle, "Tip", Vector3.new(0.1, 0.2, 0.05), CFrame.new(0, 1.48, 0), steel, Enum.Material.Metal)
	elseif item == "Katana" then
		handle.Color = Color3.fromRGB(30, 30, 60)
		piece(tool, handle, "Tsuba", Vector3.new(0.5, 0.08, 0.5), CFrame.new(0, 0.5, 0), Color3.fromRGB(80, 150, 255), Enum.Material.Metal)
		piece(tool, handle, "Blade", Vector3.new(0.06, 3.2, 0.2), CFrame.new(0, 2.15, -0.06) * CFrame.Angles(math.rad(-3), 0, 0), steel, Enum.Material.Metal)
		piece(tool, handle, "Edge", Vector3.new(0.03, 3.1, 0.04), CFrame.new(0, 2.15, -0.2) * CFrame.Angles(math.rad(-3), 0, 0), Color3.fromRGB(150, 200, 255), Enum.Material.Neon)
	elseif item == "Gun" then
		handle.Size = Vector3.new(0.24, 0.6, 0.32)
		handle.CFrame = CFrame.new()
		piece(tool, handle, "Slide", Vector3.new(0.26, 0.3, 1.1), CFrame.new(0, 0.38, -0.32), Color3.fromRGB(46, 46, 52), Enum.Material.Metal)
		piece(tool, handle, "Barrel", Vector3.new(0.12, 0.12, 0.2), CFrame.new(0, 0.42, -0.95), black, Enum.Material.Metal)
		piece(tool, handle, "Sight", Vector3.new(0.06, 0.08, 0.08), CFrame.new(0, 0.57, -0.8), Color3.fromRGB(176, 90, 255), Enum.Material.Neon)
	elseif item == "Scythe" then
		handle.Color = Color3.fromRGB(46, 30, 24)
		piece(tool, handle, "Pole", Vector3.new(0.2, 4.6, 0.2), CFrame.new(0, 2.2, 0), Color3.fromRGB(46, 30, 24), Enum.Material.Wood)
		piece(tool, handle, "Blade", Vector3.new(0.06, 0.5, 2.6), CFrame.new(0, 4.25, -1.25) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(150, 150, 160), Enum.Material.Metal)
		piece(tool, handle, "Edge", Vector3.new(0.04, 0.1, 2.5), CFrame.new(0, 4.0, -1.25) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(176, 90, 255), Enum.Material.Neon)
	elseif item == "SlapGlove" then
		local gold = Color3.fromRGB(255, 196, 40)
		handle.Size = Vector3.new(0.4, 0.5, 0.4)
		handle.Color = Color3.fromRGB(200, 140, 30)
		piece(tool, handle, "Palm", Vector3.new(1.3, 1.3, 0.4), CFrame.new(0, 0.95, -0.1), gold)
		for i, x in { -0.45, -0.15, 0.15, 0.45 } do
			local len = (i == 2 or i == 3) and 0.85 or 0.7
			piece(tool, handle, "Finger", Vector3.new(0.26, len, 0.34), CFrame.new(x, 1.6 + len / 2, -0.1), gold)
		end
		piece(tool, handle, "Thumb", Vector3.new(0.3, 0.6, 0.34), CFrame.new(-0.8, 1.0, -0.1) * CFrame.Angles(0, 0, math.rad(35)), gold)
		piece(tool, handle, "Cuff", Vector3.new(0.9, 0.3, 0.6), CFrame.new(0, 0.3, -0.1), Color3.fromRGB(150, 30, 30))
	elseif item == "PlasmaCannon" then
		local cyan = Color3.fromRGB(80, 230, 255)
		handle.Size = Vector3.new(0.26, 0.6, 0.3)
		piece(tool, handle, "Body", Vector3.new(0.7, 0.7, 2.6), CFrame.new(0, 0.55, -0.6), Color3.fromRGB(40, 40, 54), Enum.Material.Metal)
		for k = 0, 2 do
			piece(tool, handle, "Coil", Vector3.new(0.82, 0.82, 0.14), CFrame.new(0, 0.55, -0.9 - k * 0.45), cyan, Enum.Material.Neon)
		end
		piece(tool, handle, "Muzzle", Vector3.new(0.5, 0.5, 0.3), CFrame.new(0, 0.55, -2.0), Color3.fromRGB(255, 196, 40), Enum.Material.Neon)
		piece(tool, handle, "Tank", Vector3.new(0.4, 0.4, 0.8), CFrame.new(0, 1.05, 0.2), cyan, Enum.Material.Glass)
	end
end

-- the model in your hand: the Handle is the grip; -Z points where you face, +Y up (Roblox's
-- tool-holding pose)
local function build(item: string): Tool
	local tool = Instance.new("Tool")
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = INFO[item].Tip
	if INFO[item].Icon then
		tool.TextureId = "rbxassetid://" .. INFO[item].Icon
	end
	tool:SetAttribute("ItemId", item)
	-- (v161 rolled weapons: an emoji for the hotbar slot and the tier's colour round it, client Gear)
	tool:SetAttribute("Emoji", INFO[item].Emoji)
	tool:SetAttribute("Tier", INFO[item].Tier)
	tool:SetAttribute("Label", INFO[item].Name)
	tool:SetAttribute("Unit", INFO[item].Unit)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	handle.CastShadow = false
	handle.CFrame = CFrame.new()
	handle.Parent = tool
	local dark = Color3.fromRGB(28, 28, 32)
	if item == "Flashlight" then
		handle.Size = Vector3.new(0.32, 0.32, 1.1)
		handle.Color = Color3.fromRGB(34, 34, 38)
		handle.Material = Enum.Material.Metal
		piece(tool, handle, "Head", Vector3.new(0.46, 0.46, 0.36), CFrame.new(0, 0, -0.68), Color3.fromRGB(46, 46, 52), Enum.Material.Metal)
		piece(tool, handle, "Lens", Vector3.new(0.38, 0.38, 0.05), CFrame.new(0, 0, -0.88), Color3.fromRGB(255, 244, 214), Enum.Material.Neon)
		tool.Grip = CFrame.new(0, 0, 0.15)
	elseif item == "Taser" then
		handle.Size = Vector3.new(0.28, 0.55, 0.3)
		handle.Color = dark
		piece(tool, handle, "Body", Vector3.new(0.32, 0.38, 0.95), CFrame.new(0, 0.32, -0.32), Color3.fromRGB(250, 200, 30))
		piece(tool, handle, "Muzzle", Vector3.new(0.3, 0.3, 0.14), CFrame.new(0, 0.32, -0.84), Color3.fromRGB(30, 30, 34))
		piece(tool, handle, "Light", Vector3.new(0.08, 0.06, 0.2), CFrame.new(0, 0.53, -0.1), Color3.fromRGB(120, 200, 255), Enum.Material.Neon)
	elseif item == "PepperSpray" then
		handle.Size = Vector3.new(0.34, 0.8, 0.34)
		handle.Color = Color3.fromRGB(200, 40, 34)
		piece(tool, handle, "Cap", Vector3.new(0.26, 0.2, 0.26), CFrame.new(0, 0.5, 0), dark)
		piece(tool, handle, "Nozzle", Vector3.new(0.1, 0.08, 0.16), CFrame.new(0, 0.55, -0.14), dark)
		piece(tool, handle, "Label", Vector3.new(0.35, 0.3, 0.35), CFrame.new(0, -0.05, 0), Color3.fromRGB(245, 240, 230))
	elseif item == "Rocket" then
		local olive = Color3.fromRGB(84, 98, 56)
		handle.Size = Vector3.new(0.26, 0.6, 0.3)
		handle.Color = Color3.fromRGB(36, 40, 28)
		piece(tool, handle, "Tube", Vector3.new(0.62, 0.62, 3.6), CFrame.new(0, 0.55, -0.5), olive, Enum.Material.Metal)
		piece(tool, handle, "Front", Vector3.new(0.74, 0.74, 0.3), CFrame.new(0, 0.55, -2.35), Color3.fromRGB(36, 40, 28))
		piece(tool, handle, "Back", Vector3.new(0.74, 0.74, 0.3), CFrame.new(0, 0.55, 1.35), Color3.fromRGB(36, 40, 28))
		piece(tool, handle, "Sight", Vector3.new(0.12, 0.28, 0.4), CFrame.new(-0.36, 0.88, -0.6), Color3.fromRGB(36, 40, 28))
		piece(tool, handle, "Warhead", Vector3.new(0.4, 0.4, 0.5), CFrame.new(0, 0.55, -2.65), Color3.fromRGB(190, 40, 30))
	elseif item == "EnergyDrink" then
		handle.Size = Vector3.new(0.36, 0.7, 0.36)
		handle.Color = Color3.fromRGB(60, 210, 90)
		handle.Material = Enum.Material.Metal
		piece(tool, handle, "Top", Vector3.new(0.3, 0.06, 0.3), CFrame.new(0, 0.38, 0), Color3.fromRGB(200, 200, 205), Enum.Material.Metal)
		piece(tool, handle, "Stripe", Vector3.new(0.37, 0.14, 0.37), CFrame.new(0, 0.05, 0), Color3.fromRGB(20, 20, 24))
	elseif item == "NightVision" then
		handle.Size = Vector3.new(0.7, 0.3, 0.3)
		handle.Color = dark
		for _, x in { -0.18, 0.18 } do
			piece(tool, handle, "Tube", Vector3.new(0.22, 0.22, 0.34), CFrame.new(x, 0, -0.28), Color3.fromRGB(36, 38, 36), Enum.Material.Metal)
			piece(tool, handle, "Lens", Vector3.new(0.18, 0.18, 0.04), CFrame.new(x, 0, -0.46), Color3.fromRGB(90, 255, 120), Enum.Material.Neon)
		end
	elseif ctx and ctx.Config.Weapons and ctx.Config.Weapons.List[item] then
		buildWeapon(tool, handle, item)
	elseif item == "Firecracker" then
		handle.Size = Vector3.new(0.22, 0.22, 0.8)
		handle.Color = Color3.fromRGB(200, 30, 30)
		piece(tool, handle, "Band", Vector3.new(0.23, 0.23, 0.12), CFrame.new(0, 0, -0.2), Color3.fromRGB(240, 200, 60))
		piece(tool, handle, "Fuse", Vector3.new(0.05, 0.05, 0.3), CFrame.new(0, 0, -0.55), Color3.fromRGB(60, 50, 40))
	end
	return tool
end

local function blocked(p: Player): boolean
	return not p:GetAttribute("InGame") or p:GetAttribute("Hiding") == true or p:GetAttribute("Captured") == true
		or p:GetAttribute("Dead") == true or p:GetAttribute("Escaped") == true or p:GetAttribute("Monster") == true
end

local function find(p: Player, item: string): Tool?
	for _, holder in { p.Character, p:FindFirstChildOfClass("Backpack") } do
		if holder then
			for _, t in holder:GetChildren() do
				if t:IsA("Tool") and t:GetAttribute("ItemId") == item then
					return t
				end
			end
		end
	end
	return nil
end
Tools.find = find

-- the flashlight goes off when it goes back in your pocket (a click switches it on: v95; on by
-- itself the moment it was in your hand, everyone walked around lit up for him to see)
local function wire(p: Player, tool: Tool, item: string)
	tool.Equipped:Connect(function()
		if blocked(p) then
			task.defer(function()
				local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:UnequipTools()
				end
			end)
			return
		end
	end)
	tool.Unequipped:Connect(function()
		if item == "Flashlight" then
			ctx.PlayerState.setFlashlight(p, false)
		elseif item == "NightVision" and ctx.PlayerState.setNightVision then
			ctx.PlayerState.setNightVision(p, false)
		end
	end)
end

-- make the hotbar match what you have of `item`
function Tools.refresh(p: Player, item: string)
	if not IS_TOOL[item] or not p.Parent then
		return
	end
	local n = ctx.Inventory.count(p, item)
	local tool = find(p, item)
	if n <= 0 then
		if tool then
			if item == "Flashlight" then
				ctx.PlayerState.setFlashlight(p, false)
			end
			tool:Destroy()
		end
		return
	end
	if not tool then
		local backpack = p:FindFirstChildOfClass("Backpack")
		if not backpack then
			return
		end
		tool = build(item)
		wire(p, tool, item)
		tool.Parent = backpack
	end
	local name = INFO[item].Name
	local single = item == "Flashlight" or item == "NightVision" or (INFO[item].Emoji ~= nil and not INFO[item].Unit)
	tool.Name = (single or n <= 1) and name or (name .. " (" .. n .. ")")
	tool:SetAttribute("Count", (not single) and n or nil)
end

function Tools.refreshAll(p: Player)
	for _, item in Tools.Items do
		Tools.refresh(p, item)
	end
end

local function unequip(p: Player)
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:UnequipTools()
	end
end

function Tools.init(c)
	ctx = c
	ctx.Tools = Tools
	-- (v161) the rolled weapons are tools too
	local Wp = ctx.Config.Weapons
	if Wp then
		for _, k in Wp.Order do
			local spec = Wp.List[k]
			if not IS_TOOL[k] then
				table.insert(Tools.Items, k)
				IS_TOOL[k] = true
			end
			INFO[k] = { Name = spec.Name, Emoji = spec.Emoji, Tier = spec.Tier, Unit = spec.Ammo and "shot" or nil, Tip = spec.Tip }
		end
	end
end

function Tools.start()
	local function added(p: Player)
		p.CharacterAdded:Connect(function()
			-- (a new character comes with an empty backpack)
			task.defer(Tools.refreshAll, p)
		end)
		for _, a in { "Hiding", "Captured", "Dead", "Escaped", "Monster", "InGame" } do
			p:GetAttributeChangedSignal(a):Connect(function()
				if blocked(p) then
					unequip(p)
				end
			end)
		end
	end
	for _, p in Players:GetPlayers() do
		added(p)
	end
	Players.PlayerAdded:Connect(added)
end

Tools._build = build -- (tests)

return Tools
