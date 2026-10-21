--[[
	Gear — the items you use are Roblox tools (server: ToolService), in our own hotbar.
	• (v109, the owner: "only 3 items got in hotbar and rest sit in inventory". Roblox's hotbar shows
	  3 slots on a phone-sized screen, so it's off: this bar shows every item, the slots shrinking to
	  fit the screen, the one in your hand outlined, with what's left on it.)
	• Pick one (tap its slot, 1-9, or L1/R1 on a pad; again to put it away), then click / tap / R2: the
	  use goes to the server with where you're aiming (the point under the mouse or your finger; the
	  camera's centre otherwise).
	• The hotbar shows only while you can use things: not hiding, tied up, dead, being him, in a
	  cutscene, a conversation or the heartbeat minigame.
	• F (or D-pad up) takes the flashlight out and switches it on, or puts it away.
	• The hotbar shows each item's picture (ToolService Icon); what's in your hand, and how many are
	  left, is one small line just above it ("TASER · 3 SHOTS").
]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Gear = {}
local ctx
local player = Players.LocalPlayer
local shown: boolean? = nil
local hooked: { [Instance]: boolean } = {}

-- where you're aiming, from your head
local function aim(): Vector3?
	local char = player.Character
	local head = char and char:FindFirstChild("Head") :: BasePart?
	local cam = workspace.CurrentCamera
	if not head or not cam then
		return nil
	end
	local target: Vector3? = nil
	pcall(function()
		local hit = player:GetMouse().Hit
		target = hit and hit.Position or nil
	end)
	if target and (target - head.Position).Magnitude > 2 then
		return (target - head.Position).Unit
	end
	return cam.CFrame.LookVector
end
Gear._aim = aim -- (tests)

function Gear.use(tool: Tool)
	local item = tool:GetAttribute("ItemId")
	if type(item) ~= "string" or not player:GetAttribute("InGame") then
		return
	end
	ctx.Remotes.UseItem:FireServer(item, aim())
end

local function hook(tool: Instance)
	if not tool:IsA("Tool") or hooked[tool] or tool:GetAttribute("ItemId") == nil then
		return
	end
	hooked[tool] = true
	tool.Activated:Connect(function()
		Gear.use(tool)
	end)
	tool.Destroying:Connect(function()
		hooked[tool] = nil
	end)
end

local function blocked(): boolean
	if not player:GetAttribute("InGame") then
		return true
	end
	for _, a in { "Hiding", "Captured", "Dead", "Escaped", "Monster" } do
		if player:GetAttribute(a) then
			return true
		end
	end
	if workspace:GetAttribute("EndingActive") then
		return true
	end
	if ctx.Cutscene and ctx.Cutscene.isPlaying and ctx.Cutscene.isPlaying() then
		return true
	end
	if ctx.Dialogue and ctx.Dialogue.blocksControls and ctx.Dialogue.blocksControls() then
		return true
	end
	if ctx.HeartbeatUI and ctx.HeartbeatUI.isActive and ctx.HeartbeatUI.isActive() then
		return true
	end
	return false
end

-- the bar's order (ToolService.Items); anything else after them
local ORDER = { "Flashlight", "Taser", "PepperSpray", "Rocket", "EnergyDrink", "Firecracker", "NightVision" }
local RANK = {}
for i, k in ORDER do
	RANK[k] = i
end

-- every item you carry, in the bar's order, and the one in your hand
local function tools(): ({ Tool }, Tool?)
	local list: { Tool } = {}
	local held: Tool? = nil
	for _, holder in { player.Character, player:FindFirstChildOfClass("Backpack") } do
		for _, t in holder and holder:GetChildren() or {} do
			if t:IsA("Tool") and t:GetAttribute("ItemId") ~= nil then
				table.insert(list, t)
				if holder == player.Character then
					held = t
				end
			end
		end
	end
	table.sort(list, function(a, b)
		local ra, rb = RANK[a:GetAttribute("ItemId")] or 99, RANK[b:GetAttribute("ItemId")] or 99
		if ra ~= rb then
			return ra < rb
		end
		return a.Name < b.Name
	end)
	return list, held
end
Gear._tools = tools -- (tests)

local function hasTools(): boolean
	return #(tools()) > 0
end

-- in your hand, or put away
function Gear.toggle(tool: Tool)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or blocked() then
		return
	end
	if tool.Parent == char then
		hum:UnequipTools()
	else
		hum:EquipTool(tool)
	end
end

-- the slot number (1-9, the pad's L1/R1 steps through them)
function Gear.select(i: number)
	local list = tools()
	if list[i] then
		Gear.toggle(list[i])
	end
end
local function step(dir: number)
	local list, held = tools()
	if #list == 0 then
		return
	end
	local at = 0
	for i, t in list do
		if t == held then
			at = i
		end
	end
	local nxt = at + dir
	if nxt < 1 then
		nxt = #list
	elseif nxt > #list then
		nxt = 1
	end
	Gear.toggle(list[nxt])
end

-- the bar: one slot per item, sized to fit (on a phone the thumbstick and the jump button take the
-- bottom corners, so the slots share what's between them)
local bar: Frame? = nil
local slots: { ImageButton } = {}
local slotTool: { [ImageButton]: Tool } = {}
local barSize = 0 -- (a slot's side, in the HUD's own units)
local SLOT_PX, GAP_PX = 58, 6

local function slotSide(n: number): number
	local cam = workspace.CurrentCamera
	local vx = cam and cam.ViewportSize.X or 1280
	local scale = math.max(0.3, ctx.UI.Scale or 1)
	local touch = ctx.UI.isTouch and ctx.UI.isTouch()
	-- (screen pixels: on a phone keep clear of the thumbstick and the jump button)
	local room = vx - (touch and 300 or 80)
	local px = math.clamp(math.floor(room / math.max(1, n) - GAP_PX), 40, touch and 54 or SLOT_PX)
	return px / scale
end

local function newSlot(i: number): ImageButton
	local UI = ctx.UI
	local b = UI.new("ImageButton", {
		Name = "Slot" .. i,
		LayoutOrder = i,
		BackgroundColor3 = Color3.fromRGB(16, 16, 20),
		BackgroundTransparency = 0.3,
		AutoButtonColor = true,
		Image = "",
		Parent = bar,
	})
	UI.corner(b, 8)
	UI.stroke(b, Color3.new(1, 1, 1), 1, 0.7)
	UI.new("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.74, 0.74),
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		Active = false,
		Parent = b,
	})
	UI.new("TextLabel", {
		Name = "Key",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 4, 0, 2),
		Size = UDim2.fromOffset(14, 14),
		Text = tostring(i),
		Font = UI.Font.Bold,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = b,
	})
	UI.new("TextLabel", {
		Name = "Count",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -4, 1, -2),
		Size = UDim2.fromOffset(30, 14),
		Text = "",
		Font = UI.Font.Bold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = b,
	})
	-- (a tap: press and release on the slot; a camera drag across it doesn't count)
	b.Activated:Connect(function()
		local t = slotTool[b]
		if t then
			Gear.toggle(t)
		end
	end)
	return b
end

local function drawBar(want: boolean)
	if not bar then
		return
	end
	local list, held = tools()
	bar.Visible = want and #list > 0
	if not bar.Visible then
		return
	end
	barSize = slotSide(#list)
	local showKeys = not (ctx.UI.isTouch and ctx.UI.isTouch())
	for i, t in list do
		local b = slots[i] or newSlot(i)
		slots[i] = b
		slotTool[b] = t
		b.Visible = true
		b.Size = UDim2.fromOffset(barSize, barSize)
		local icon = b:FindFirstChild("Icon") :: ImageLabel?
		if icon then
			icon.Image = t.TextureId
		end
		local on = t == held
		b.BackgroundTransparency = on and 0.05 or 0.3
		b.BackgroundColor3 = on and Color3.fromRGB(70, 70, 76) or Color3.fromRGB(16, 16, 20)
		local stroke = b:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = on and 2 or 1
			stroke.Transparency = on and 0 or 0.7
		end
		local key = b:FindFirstChild("Key") :: TextLabel?
		if key then
			key.Visible = showKeys and i <= 9
		end
		local count = b:FindFirstChild("Count") :: TextLabel?
		if count then
			local n = tonumber(t:GetAttribute("Count"))
			if t:GetAttribute("ItemId") == "NightVision" then
				count.Text = math.ceil(tonumber(player:GetAttribute("NVLeft")) or 0) .. "s"
			else
				count.Text = (n and n > 1) and ("x" .. n) or ""
			end
		end
	end
	for i = #list + 1, #slots do
		slots[i].Visible = false
		slotTool[slots[i]] = nil
	end
end
Gear._bar = function() return bar end -- (tests)

-- what's in your hand, just above the hotbar (the hotbar shows pictures, not names): "TASER · 3 SHOTS"
local heldBox: Frame? = nil
local heldText: TextLabel? = nil
function Gear.heldLine(): string?
	local char = player.Character
	local tool = char and char:FindFirstChildOfClass("Tool")
	if not tool or tool:GetAttribute("ItemId") == nil then
		return nil
	end
	local label = string.upper(tostring(tool:GetAttribute("Label") or tool:GetAttribute("ItemId")))
	local n = tonumber(tool:GetAttribute("Count"))
	if n and n > 1 then
		local unit = tool:GetAttribute("Unit")
		label ..= "  ·  " .. n .. (type(unit) == "string" and (" " .. string.upper(unit) .. "S") or " LEFT")
	elseif n == 1 and tool:GetAttribute("Unit") then
		label ..= "  ·  LAST " .. string.upper(tostring(tool:GetAttribute("Unit")))
	end
	if tool:GetAttribute("ItemId") == "NightVision" then
		local left = math.ceil(tonumber(player:GetAttribute("NVLeft")) or 0)
		label ..= left > 0 and ("  ·  " .. left .. " S") or "  ·  NO CHARGE"
	end
	return label
end

local lastLift = -1
local function refresh()
	local want = not blocked()
	shown = want
	drawBar(want)
	-- the hotbar sits at the bottom centre: what's usually there moves up above it
	local lift = (want and hasTools()) and math.ceil(barSize + 16) or 0
	if heldBox and heldText then
		local line = want and Gear.heldLine() or nil
		heldBox.Visible = line ~= nil
		heldBox.Position = UDim2.new(0.5, 0, 1, -lift - 14)
		if line then
			heldText.Text = line
		end
	end
	if lift ~= lastLift then
		lastLift = lift
		if ctx.HUD and ctx.HUD.setBottomLift then
			ctx.HUD.setBottomLift(lift)
		end
		if ctx.UI.Subtitles then
			ctx.UI.Subtitles.Position = UDim2.new(0.5, 0, 1, -104 - lift)
		end
	end
end
Gear._refresh = refresh -- (tests)
function Gear.isShown(): boolean
	return shown == true
end

-- F: the flashlight out of your pocket, or back in
function Gear.toggleFlashlight()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or blocked() then
		return
	end
	for _, t in char:GetChildren() do
		if t:IsA("Tool") and t:GetAttribute("ItemId") == "Flashlight" then
			hum:UnequipTools()
			return
		end
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, t in backpack and backpack:GetChildren() or {} do
		if t:IsA("Tool") and t:GetAttribute("ItemId") == "Flashlight" then
			hum:EquipTool(t)
			-- (F means "light": out and on in one press)
			if not player:GetAttribute("FlashlightOn") then
				ctx.Remotes.UseItem:FireServer("Flashlight")
			end
			return
		end
	end
	if ctx.Thoughts and ctx.Thoughts.say then
		ctx.Thoughts.say("I don't have a flashlight. There's one on the mudroom shelf, and one in the den drawer.")
	end
end

function Gear.init(c)
	ctx = c
	ctx.Gear = Gear
end

function Gear.start()
	local function watch(char: Model)
		for _, t in char:GetChildren() do
			hook(t)
		end
		char.ChildAdded:Connect(hook)
	end
	if player.Character then
		watch(player.Character)
	end
	player.CharacterAdded:Connect(watch)
	ctx.Input.on("Flashlight", function(began)
		if began then
			Gear.toggleFlashlight()
		end
	end)
	-- (Roblox's own hotbar stays off: ours shows everything)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
	bar = ctx.UI.new("Frame", {
		Name = "Hotbar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Visible = false,
		Parent = ctx.UI.Root,
	})
	ctx.UI.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, GAP_PX),
		Parent = bar,
	})
	local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine }
	UserInputService.InputBegan:Connect(function(io, processed)
		if processed or blocked() then
			return
		end
		for i, k in KEYS do
			if io.KeyCode == k then
				Gear.select(i)
				return
			end
		end
		if io.KeyCode == Enum.KeyCode.ButtonL1 then
			step(-1)
		elseif io.KeyCode == Enum.KeyCode.ButtonR1 then
			step(1)
		end
	end)
	heldBox = ctx.UI.box({ Name = "HeldItem", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -86), Visible = false, Parent = ctx.UI.Root }, { 3, 10 })
	heldText = ctx.UI.fitLabel({ Text = "", Font = ctx.UI.Font.Bold, TextSize = 13, Parent = heldBox }, 320)
	local clock = 0
	RunService.Heartbeat:Connect(function(dt)
		clock += dt
		if clock >= 0.2 then
			clock = 0
			refresh()
		end
	end)
	refresh()
end

return Gear
