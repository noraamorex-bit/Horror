-- tools_test: the usable items are Roblox tools in the hotbar (ToolService). Given an item, a tool
-- appears in the backpack, named with what's left; used up, it goes; the flashlight is on while it's
-- in your hand; the taser doesn't waste a shot when he isn't there to hit.
local H = require("./env")
local R = H.roblox
local ok, err = pcall(function()
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Rooms = H.load("RS/Shared/Rooms")
	ctx.Sounds = H.load("RS/Shared/Sounds")
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Util = H.load("RS/Shared/Util")
	ctx.Builder = H.load("Server/World/Builder")
	ctx.Layout = H.load("Server/World/Layout")
	local captions = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { FireClient = function(_, p, a) if k == "Caption" then table.insert(captions, tostring(a)) end end, FireAllClients = function() end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Tools=ToolService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService" }
	local names = {}
	for _, name in ORDER do
		local key, file = name:match("(%w+)=(%w+)")
		ctx[key] = H.load("Server/Services/" .. file)
		table.insert(names, key)
	end
	ctx.World = H.load("Server/World/World")
	ctx.Director = H.load("Server/Director/Director")
	ctx.Intruder = H.load("Server/Intruder/Intruder")
	for _, k in { "World", "Director", "Intruder" } do table.insert(names, k) end
	for _, k in names do if ctx[k].init then ctx[k].init(ctx) end end
	ctx.World.build()
	ctx.restart = function() end
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	local p = H.wrap(R.Instance.new("Player"))
	p.Name = "Holder"
	local backpack = H.Instance.new("Backpack")
	backpack.Parent = p
	local char = H.Instance.new("Model")
	local root = H.Instance.new("Part", char)
	root.Name = "HumanoidRootPart"
	local head = H.Instance.new("Part", char)
	head.Name = "Head"
	local light = H.Instance.new("SpotLight", head)
	light.Name = "Flashlight"
	H.Instance.new("Humanoid", char)
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	p:SetAttribute("InGame", true)
	H.services.Players.GetPlayers = function() return { p } end
	local function tool(item)
		return ctx.Tools.find(p, item)
	end
	-- each usable item: a tool in the backpack, with a handle and its model
	for _, item in ctx.Tools.Items do
		ctx.Inventory.give(p, item, 2)
		local t = tool(item)
		assert(t and t:IsA("Tool") and t:FindFirstChild("Handle"), item .. ": a tool with a handle")
		assert(t.Parent == H.unwrap(backpack) or t.Parent == backpack, item .. ": in the backpack")
		assert(t:GetAttribute("ItemId") == item and #t.ToolTip > 10, item .. ": knows what it is and says how to use it")
		-- (v100) a picture in the hotbar, and the count for the line above it
		assert(string.match(t.TextureId, "^rbxassetid://%d+$"), item .. ": has its hotbar icon")
		assert(t:GetAttribute("Label") and (item == "Flashlight" or item == "NightVision" or t:GetAttribute("Count") == 2), item .. ": its name and what's left")
	end
	local icons = {}
	for _, item in ctx.Tools.Items do
		local id = ctx.Tools.Info[item].Icon
		assert(not icons[id], "every item its own icon")
		icons[id] = true
	end
	assert(tool("Taser").Name == "Taser (2)", "named with what's left: " .. tool("Taser").Name)
	ctx.Inventory.take(p, "Taser")
	assert(tool("Taser").Name == "Taser", "one left: just the name")
	ctx.Inventory.take(p, "Taser")
	assert(tool("Taser") == nil, "used up: gone from the hotbar")
	-- the story items are not tools
	ctx.Inventory.give(p, "HouseKeys", 1)
	assert(tool("HouseKeys") == nil and not ctx.Tools.isTool("HouseKeys"), "keys stay in the list")
	-- the flashlight: in your hand it stays dark until you click (v95), off when you put it away
	local fl = H.wrap(tool("Flashlight"))
	p:SetAttribute("Battery", 80)
	rawget(fl, "__signals").Equipped:Fire()
	assert(not p:GetAttribute("FlashlightOn"), "in your hand: still off")
	ctx.Remotes.UseItem.OnServerEvent:Fire(p, "Flashlight")
	assert(p:GetAttribute("FlashlightOn") == true, "click: on")
	ctx.Remotes.UseItem.OnServerEvent:Fire(p, "Flashlight")
	assert(not p:GetAttribute("FlashlightOn"), "click: off")
	ctx.Remotes.UseItem.OnServerEvent:Fire(p, "Flashlight")
	assert(p:GetAttribute("FlashlightOn") == true, "click: on again")
	rawget(fl, "__signals").Unequipped:Fire()
	assert(not p:GetAttribute("FlashlightOn"), "put away: off")
	-- the taser before he's hunting: no shot wasted, and a reason
	ctx.Inventory.give(p, "Taser", 3)
	ctx.Remotes.UseItem.OnServerEvent:Fire(p, "Taser", R.Vector3.new(0, 0, -1))
	assert(ctx.Inventory.count(p, "Taser") == 3, "nothing to shoot: the shot is kept")
	local said = false
	for _, c in captions do if c:find("Save your shots") then said = true end end
	assert(said, "and they're told to save it for him")
	-- v108, the Night Vision pass: the goggles, one tool without a count; a click turns them on while
	-- there's charge, putting them away turns them off, the charge drains and they die at 0
	ctx.Inventory.give(p, "NightVision", 1)
	local nv = tool("NightVision")
	assert(nv and nv.Name == "Night vision" and nv:GetAttribute("Count") == nil, "the goggles: " .. tostring(nv and nv.Name))
	p:SetAttribute("NVLeft", 0)
	ctx.Remotes.UseItem.OnServerEvent:Fire(p, "NightVision")
	assert(not p:GetAttribute("NightVision"), "no charge: they stay off")
	p:SetAttribute("NVLeft", ctx.Config.NightVision.Seconds)
	ctx.Remotes.UseItem.OnServerEvent:Fire(p, "NightVision")
	assert(p:GetAttribute("NightVision") == true, "click: on")
	rawget(nv, "__signals").Unequipped:Fire()
	assert(not p:GetAttribute("NightVision"), "put away: off")
	ctx.Remotes.UseItem.OnServerEvent:Fire(p, "NightVision")
	p:SetAttribute("NVLeft", 0.4)
	ctx.PlayerState.drainNightVision(p, 0.3)
	assert(p:GetAttribute("NightVision") == true and math.abs(p:GetAttribute("NVLeft") - 0.1) < 1e-6, "draining")
	ctx.PlayerState.drainNightVision(p, 0.5)
	assert(p:GetAttribute("NVLeft") == 0 and not p:GetAttribute("NightVision"), "out of charge: off")
	p:SetAttribute("NightVision", nil)
	p:SetAttribute("NVLeft", nil)
	-- v108, Silent Steps: footsteps carry half as far, and you hold your breath 50% longer
	local walk = ctx.PlayerState.stepRadius(p, false, false, nil)
	local sprint = ctx.PlayerState.stepRadius(p, false, true, nil)
	local hold = ctx.Hiding._breathMax(p)
	p:SetAttribute("Pass_Silent", true)
	assert(ctx.PlayerState.stepRadius(p, false, false, nil) == walk * 0.5 and ctx.PlayerState.stepRadius(p, false, true, nil) == sprint * 0.5, "silent steps")
	assert(ctx.Hiding._breathMax(p) == hold * 1.5, "a longer breath")
	p:SetAttribute("Pass_Silent", nil)
	assert(walk == ctx.Config.Noise.Walk, "without it, the usual")
	-- a new character: the tools come back
	ctx.Inventory.clear(p)
	assert(tool("Flashlight") == nil and tool("Rocket") == nil, "cleared: no tools")
	print("tools ok")
end)
print(ok and "TOOLS OK" or ("TOOLS FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
