-- ui_dump: the game's own HUD, built by the real client controllers (as client_test does), put in
-- a scene and written out as JSON for tools/ui_preview.mjs to draw at phone and PC sizes. There is no
-- Roblox client here: this is how we look at the layout (what shows on which device, what overlaps).
--   lune run ui_dump <scene> <pc|touch> <out.json>
-- scenes: lobby, night (act I with an objective, items, a thought), hunt (the blackout: stamina, a notice,
-- captions), heartbeat (the minigame at your hiding spot), hiding, captured
local H = require("./env")
local roblox = H.roblox
local process = require("@lune/process")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local SCENE = process.args[1] or "night"
local touch = process.args[2] == "touch"
local OUT = process.args[3] or "ui.json"

local S = H.services
local player = H.wrap(roblox.Instance.new("Player"))
player.Name = "Tester"
local pg = H.wrap(roblox.Instance.new("PlayerGui"))
pg.Parent = player
S.Players.LocalPlayer = player
S.Players.GetPlayers = function() return { player } end
S.UserInputService = {
	TouchEnabled = touch, KeyboardEnabled = not touch, MouseBehavior = nil,
	LastInputTypeChanged = H.signal(), InputBegan = H.signal(), InputEnded = H.signal(), InputChanged = H.signal(),
	GetLastInputType = function() return touch and roblox.Enum.UserInputType.Touch or roblox.Enum.UserInputType.Keyboard end,
	GetMouseDelta = function() return roblox.Vector2.new() end,
}
S.GuiService = { GetGuiInset = function() return roblox.Vector2.new(0, 36), roblox.Vector2.new() end }
S.ProximityPromptService = { PromptShown = H.signal(), PromptHidden = H.signal(), PromptTriggered = H.signal(), Enabled = true }
S.MarketplaceService = { PromptGamePassPurchaseFinished = H.signal(), PromptProductPurchaseFinished = H.signal(), PromptGamePassPurchase = function() end, PromptProductPurchase = function() end }
S.SoundService = H.wrap(roblox.Instance.new("SoundService"))
S.Lighting = H.wrap(roblox.Instance.new("Lighting"))
S.StarterGui = { SetCoreGuiEnabled = function() end, SetCore = function() end }
S.RunService.IsServer = function() return false end

local LOBBY = SCENE == "lobby"
player:SetAttribute("StarterOffer", true) -- (v120: the Starter Pack on the side, while it's on offer)
local ctx: any = { Player = player, Mode = LOBBY and "Lobby" or "Game" }
ctx.Config = H.load("RS/Shared/Config")
ctx.Rooms = H.load("RS/Shared/Rooms")
ctx.Sounds = H.load("RS/Shared/Sounds")
ctx.Story = H.load("RS/Shared/Story")
ctx.Util = H.load("RS/Shared/Util")
ctx.CreaturePose = H.load("RS/Shared/CreaturePose")
ctx.Remotes = setmetatable({}, { __index = function(t, k)
	local r = { OnClientEvent = H.signal(), FireServer = function() end }
	rawset(t, k, r)
	return r
end })
local ORDER = LOBBY and { "UI", "Input", "Notice", "Social", "Effects", "Settings", "Atmosphere", "Dock", "Shop", "Starter", "Store", "Locker", "Rewards", "Prank", "LobbyHub" } or { "UI", "Input", "Notice", "Social", "Thoughts", "Effects", "Atmosphere", "Dread", "Movement", "Prompts", "HUD", "Monster", "Offers", "Prank", "Starter", "Gear", "Documents", "Phone", "HidingCam", "Lobby", "Ending", "MobileControls", "Markers", "Acoustics", "Ambience", "Dialogue", "Spectate", "Creature", "Intro", "Vote", "Friends", "Settings", "TVVoice", "Cutscene", "HeartbeatGame", "Puzzle", "Finale" }
local mods = {}
for _, n in ORDER do mods[n] = H.load("Client/Controllers/" .. n) end
for _, n in ORDER do if mods[n].init then mods[n].init(ctx) end end
for _, n in ORDER do
	if mods[n].start then
		local ok, e = pcall(mods[n].start)
		if not ok then print("start failed: " .. n .. ": " .. tostring(e)) end
	end
end
local R = ctx.Remotes
local function frames(n)
	for _ = 1, n or 10 do
		S.RunService.Heartbeat:Fire(0.1)
		S.RunService.RenderStepped:Fire(0.1)
		H.task.wait(0.05)
	end
end

if LOBBY then
	player:SetAttribute("Coins", 1234)
	player:SetAttribute("Level", 4)
	frames(10)
else
-- into the house, a night under way
R.Lobby.OnClientEvent:Fire({ Phase = "InGame" })
player:SetAttribute("InGame", true)
player:SetAttribute("Role", "Observer")
player:SetAttribute("RoleName", "Casey Brooks")
player:SetAttribute("Item_Flashlight", 1)
-- (v109) a full set of items in our own hotbar (client Gear), the taser in your hand
do
	local bp = H.Instance.new("Backpack")
	bp.Parent = player
	local me = H.Instance.new("Model", H.workspaceRoot)
	H.unwrap(player).Character = H.unwrap(me)
	for _, id in { "Flashlight", "Taser", "PepperSpray", "Rocket", "EnergyDrink", "Firecracker", "NightVision" } do
		local t = H.Instance.new("Tool")
		t.Name = id
		t:SetAttribute("ItemId", id)
		t:SetAttribute("Label", id)
		t:SetAttribute("Count", (id == "Taser" and 3) or (id == "Firecracker" and 2) or nil)
		t.TextureId = "rbxassetid://1"
		t.Parent = id == "Taser" and me or bp
	end
	player:SetAttribute("NVLeft", 60)
end
player:SetAttribute("Battery", 72)
player:SetAttribute("Nerve", 80)
player:SetAttribute("Stamina", 100)
H.unwrap(H.workspaceRoot):SetAttribute("Act", SCENE == "night" and "SmallThings" or "Guest")
H.unwrap(H.workspaceRoot):SetAttribute("Clock", "9:42 PM")
R.Chapter.OnClientEvent:Fire("II. Small Things", "sub")
R.Objectives.OnClientEvent:Fire({
	{ Id = "A", Text = SCENE == "night" and "Make popcorn for the movie" or "Call 911", Done = false,
		Steps = { { Text = "Get a bag from the pantry", Done = true }, { Text = "Microwave it", Done = false } }, StepsDone = 1, Current = "Microwave it", Targets = { roblox.Vector3.new(1, 2, 3) } },
	{ Id = "B", Text = "Get out through the garage", Done = false, Optional = true, Steps = {}, Targets = {} },
})
frames(5)
-- (the side offers: attribute signals don't fire here, so they're refreshed by hand)
for _, m in { "Offers", "Prank", "Starter" } do
	if ctx[m] and ctx[m]._refresh then
		ctx[m]._refresh()
	end
end
if SCENE == "night" then
	R.Thought.OnClientEvent:Fire("The popcorn's in the pantry. Then the microwave.", nil)
elseif SCENE == "hunt" then
	H.unwrap(H.workspaceRoot):SetAttribute("Power", false)
	player:SetAttribute("Stamina", 38)
	player:SetAttribute("Sprinting", true)
	player:SetAttribute("Nerve", 30)
	R.Notify.OnClientEvent:Fire("He's in the house. Call 911 from the bathroom window upstairs.", "danger")
	R.Caption.OnClientEvent:Fire("[Heavy footsteps, running]")
elseif SCENE == "heartbeat" then
	player:SetAttribute("Hiding", "Hall closet")
	R.Heartbeat.OnClientEvent:Fire({ Id = 7, Start = os.clock() - 1.4, Beats = { { T = 1.2, Side = "L" }, { T = 2.2, Side = "R" }, { T = 3.0, Side = "L" } }, Travel = 1.3, Window = 0.4, Misses = 3, Forgive = true })
elseif SCENE == "hiding" then
	player:SetAttribute("Hiding", "Hall closet")
	R.Caption.OnClientEvent:Fire("[Wet, rasping breathing, very close]")
elseif SCENE == "captured" then
	player:SetAttribute("Captured", true)
	R.Notify.OnClientEvent:Fire("He's got you. STRUGGLE to get free, or wait for a friend.", "danger")
end
frames(12)
end

-- the tree, as plain data
local function udim2(u) return { u.X.Scale, u.X.Offset, u.Y.Scale, u.Y.Offset } end
local function col(c) return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) } end
local function get(i, k)
	local ok, v = pcall(function() return i[k] end)
	return ok and v or nil
end
local function node(i)
	local n: any = { c = i.ClassName, n = i.Name, ch = {} }
	if i:IsA("GuiObject") then
		n.vis = i.Visible
		n.pos = udim2(i.Position)
		n.size = udim2(i.Size)
		n.anchor = { i.AnchorPoint.X, i.AnchorPoint.Y }
		n.bg = col(i.BackgroundColor3)
		n.bgT = i.BackgroundTransparency
		n.z = i.ZIndex
		n.order = i.LayoutOrder
		n.auto = tostring(i.AutomaticSize):match("%.(%w+)$")
		n.rot = i.Rotation
		n.clip = get(i, "ClipsDescendants")
		if i:IsA("TextLabel") or i:IsA("TextButton") or i:IsA("TextBox") then
			n.text = i.Text
			n.ts = i.TextSize
			n.tc = col(i.TextColor3)
			n.tt = i.TextTransparency
			n.scaled = i.TextScaled
			n.wrap = i.TextWrapped
			n.rich = i.RichText
			n.xa = tostring(i.TextXAlignment):match("%.(%w+)$")
			n.ya = tostring(i.TextYAlignment):match("%.(%w+)$")
			local f = get(i, "Font") or get(i, "FontFace")
			n.font = f and (tostring(f):match("%.(%w+)$") or tostring(f)) or nil
			n.stroke = get(i, "TextStrokeTransparency")
		end
		if i:IsA("ImageLabel") or i:IsA("ImageButton") then
			n.img = i.Image
			n.ic = col(i.ImageColor3)
			n.it = i.ImageTransparency
		end
	elseif i:IsA("ScreenGui") then
		n.en = i.Enabled
		n.order = i.DisplayOrder
		n.inset = i.IgnoreGuiInset
	elseif i:IsA("UIListLayout") then
		n.dir = tostring(i.FillDirection):match("%.(%w+)$")
		n.pad = { i.Padding.Scale, i.Padding.Offset }
		n.ha = tostring(i.HorizontalAlignment):match("%.(%w+)$")
		n.va = tostring(i.VerticalAlignment):match("%.(%w+)$")
		n.sort = tostring(i.SortOrder):match("%.(%w+)$")
	elseif i:IsA("UIGridLayout") then
		n.cell = udim2(i.CellSize)
		n.cpad = udim2(i.CellPadding)
		n.dir = tostring(i.FillDirection):match("%.(%w+)$")
		n.max = i.FillDirectionMaxCells
		n.corner = tostring(i.StartCorner):match("%.(%w+)$")
		n.sort = tostring(i.SortOrder):match("%.(%w+)$")
	elseif i:IsA("UIPadding") then
		n.p = { i.PaddingTop.Offset, i.PaddingRight.Offset, i.PaddingBottom.Offset, i.PaddingLeft.Offset }
	elseif i:IsA("UICorner") then
		n.r = { i.CornerRadius.Scale, i.CornerRadius.Offset }
	elseif i:IsA("UIStroke") then
		n.sc = col(i.Color)
		n.th = i.Thickness
		n.st = i.Transparency
	elseif i:IsA("UIScale") then
		n.scale = i.Scale
	elseif i:IsA("UIGradient") then
		n.grot = i.Rotation
		n.gt = {}
		for _, k in i.Transparency.Keypoints do table.insert(n.gt, { k.Time, k.Value }) end
		n.gc = {}
		for _, k in i.Color.Keypoints do table.insert(n.gc, { k.Time, col(k.Value) }) end
	elseif i:IsA("UISizeConstraint") then
		n.max = { i.MaxSize.X, i.MaxSize.Y }
		n.min = { i.MinSize.X, i.MinSize.Y }
	end
	for _, c in i:GetChildren() do
		if c:IsA("GuiBase2d") or c:IsA("UIComponent") or c:IsA("UIBase") then
			table.insert(n.ch, node(c))
		end
	end
	return n
end
local out = {}
for _, g in H.unwrap(pg):GetChildren() do
	if g:IsA("ScreenGui") then
		table.insert(out, node(g))
	end
end
fs.writeFile(OUT, serde.encode("json", { scene = SCENE, touch = touch, hotbar = false, guis = out }))
print("wrote " .. OUT .. " (" .. #out .. " screens)")
