--[[
	MobileControls — on-screen buttons for phones and tablets.

	The default Roblox thumbstick (move), camera drag (look) and jump button stay. Around the
	jump button sits an arc of action buttons that changes with what you're doing:

		exploring : SPRINT (toggle) · CROUCH (toggle) · LIGHT · SPRAY (when you have it)
		hiding    : BREATH (hold) · LEAVE
		captured  : STRUGGLE (mash)
	plus JOURNAL and PHONE pills in the top-right corner.

	Every button just fires an Input action, so touch goes through exactly the same code
	path as keyboard and gamepad. Interaction prompts are tapped directly (see Prompts).
]]

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MobileControls = {}
local ctx
local player = Players.LocalPlayer

local gui: ScreenGui
local buttons: { [string]: any } = {}
local pills: Frame

-- button definitions: Kind = "press" (fires began on touch down), "hold" (began/ended), "toggle"
local DEFS = {
	Sprint = { Label = "SPRINT", Icon = "»", Kind = "toggle" },
	Crouch = { Label = "CROUCH", Icon = "▼", Kind = "press" },
	Flashlight = { Label = "LIGHT", Icon = "◉", Kind = "press" },
	Spray = { Label = "SPRAY", Icon = "✱", Kind = "press" },
	Breath = { Label = "BREATH", Icon = "◌", Kind = "hold", Big = true },
	ExitHide = { Label = "LEAVE", Icon = "⇱", Kind = "press" },
	Struggle = { Label = "STRUGGLE", Icon = "✊", Kind = "press", Big = true },
}

-- which buttons exist in each context, in arc order (closest to the jump button first)
local function currentSet(): { string }
	if not player:GetAttribute("InGame") or player:GetAttribute("Escaped") or workspace:GetAttribute("EndingActive") then
		return {}
	end
	-- a conversation owns the bottom of the screen
	if ctx.Dialogue and ctx.Dialogue.blocksControls() then
		return {}
	end
	if player:GetAttribute("Captured") then
		return { "Struggle" }
	end
	if player:GetAttribute("Hiding") then
		return { "Breath", "ExitHide" }
	end
	local set = { "Sprint", "Crouch" }
	if player:GetAttribute("Item_Flashlight") then
		table.insert(set, "Flashlight")
	end
	if player:GetAttribute("Item_PepperSpray") then
		table.insert(set, "Spray")
	end
	return set
end

local function isActive(name: string): boolean
	if name == "Sprint" then
		return ctx.Movement.isSprinting()
	elseif name == "Crouch" then
		return player:GetAttribute("Crouching") == true
	elseif name == "Flashlight" then
		return player:GetAttribute("FlashlightOn") == true
	elseif name == "Breath" then
		return player:GetAttribute("HoldingBreath") == true
	end
	return false
end

-- centre of the Roblox jump button (screen px, relative to the bottom-right corner)
local function jumpAnchor(): (Vector2, number)
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(844, 390)
	local small = math.min(vp.X, vp.Y) <= 500
	local touchGui = ctx.UI.PlayerGui:FindFirstChild("TouchGui")
	local jump = touchGui and touchGui:FindFirstChild("JumpButton", true) :: GuiObject?
	local size = small and 70 or 120
	if jump and jump.AbsoluteSize.X > 0 then
		local screen = jump:FindFirstAncestorOfClass("ScreenGui")
		local inset = (screen and screen.IgnoreGuiInset) and Vector2.zero or GuiService:GetGuiInset()
		local c = jump.AbsolutePosition + jump.AbsoluteSize / 2 + inset
		return Vector2.new(c.X - vp.X, c.Y - vp.Y), jump.AbsoluteSize.X
	end
	if small then
		return Vector2.new(-60, -55), size
	end
	return Vector2.new(-110, -150), size
end

local function makeButton(name: string)
	local def = DEFS[name]
	local UI = ctx.UI
	local b = UI.new("TextButton", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = Color3.fromRGB(20, 20, 24),
		BackgroundTransparency = 0.35,
		Visible = false,
		Parent = gui,
	})
	UI.corner(b, 999)
	local stroke = UI.stroke(b, Color3.new(1, 1, 1), 2, 0.55)
	local icon = UI.label({ Size = UDim2.fromScale(1, 0.62), Text = def.Icon, Font = UI.Font.Bold, TextScaled = true, Parent = b })
	UI.new("UIPadding", { PaddingTop = UDim.new(0.12, 0), PaddingLeft = UDim.new(0.2, 0), PaddingRight = UDim.new(0.2, 0), Parent = icon })
	local label = UI.label({ Position = UDim2.fromScale(0, 0.58), Size = UDim2.fromScale(1, 0.26), Text = def.Label, Font = UI.Font.Bold, TextScaled = true, Parent = b })
	UI.new("UIPadding", { PaddingLeft = UDim.new(0.12, 0), PaddingRight = UDim.new(0.12, 0), Parent = label })

	if def.Kind == "hold" then
		-- hold buttons: only a touch that STARTS on the button counts (not a camera drag
		-- sliding across it), and it lasts until that same finger lifts
		local holding: InputObject? = nil
		b.InputBegan:Connect(function(io)
			if holding or io.UserInputState ~= Enum.UserInputState.Begin then
				return
			end
			if io.UserInputType ~= Enum.UserInputType.Touch and io.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			holding = io
			b.BackgroundTransparency = 0.1
			ctx.Input.fire(name, true)
		end)
		UserInputService.InputEnded:Connect(function(io)
			if holding and (io == holding or io.UserInputType == Enum.UserInputType.MouseButton1 and holding.UserInputType == Enum.UserInputType.MouseButton1) then
				holding = nil
				b.BackgroundTransparency = 0.35
				ctx.Input.fire(name, false)
			end
		end)
	else
		-- tap buttons: Activated only fires for a deliberate tap (press and release on the button)
		b.Activated:Connect(function()
			b.BackgroundTransparency = 0.1
			task.delay(0.12, function()
				b.BackgroundTransparency = 0.35
			end)
			if def.Kind == "toggle" and name == "Sprint" then
				ctx.Movement.setSprintToggle(not ctx.Movement.isSprinting())
			else
				ctx.Input.fire(name, true)
				ctx.Input.fire(name, false)
			end
		end)
	end
	buttons[name] = { Button = b, Stroke = stroke, Def = def }
end

local function layout()
	local anchor, jumpSize = jumpAnchor()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(844, 390)
	local small = math.min(vp.X, vp.Y) <= 500
	local size = small and 58 or 84
	local radius = jumpSize / 2 + size / 2 + (small and 20 or 26)
	local set = currentSet()
	-- arc from left of the jump button (180 deg) up to above it (90 deg), then a second ring
	local angles = { 180, 135, 90, 157.5, 112.5 }
	local ring2 = { false, false, false, true, true }
	local big = false
	for _, name in set do
		if DEFS[name].Big then
			big = true
		end
	end
	local smallIndex = 0
	for _, name in set do
		if not DEFS[name].Big then
			smallIndex += 1
			buttons[name].Slot = smallIndex
		end
	end
	for name, entry in buttons do
		local i = table.find(set, name)
		local b = entry.Button
		if not i then
			b.Visible = false
			continue
		end
		local s = entry.Def.Big and size * 1.35 or size
		local r, a
		if entry.Def.Big then
			-- the big contextual button sits just left of the jump button
			r = jumpSize / 2 + s / 2 + 16
			a = math.rad(180)
		elseif big then
			-- with a big button on the left, the small ones stack above the jump button
			r = radius + (entry.Slot - 1) * (size + 10)
			a = math.rad(90)
		else
			r = ring2[i] and radius + size + 8 or radius
			a = math.rad(angles[i] or 90)
		end
		local offset = anchor + Vector2.new(math.cos(a) * r, -math.sin(a) * r)
		b.Size = UDim2.fromOffset(s, s)
		b.Position = UDim2.new(1, offset.X, 1, offset.Y)
		b.Visible = true
	end
	pills.Visible = #set > 0 and not player:GetAttribute("Captured")
end

local function refreshActive()
	for name, entry in buttons do
		local on = isActive(name)
		entry.Stroke.Color = on and ctx.UI.Color.Accent or Color3.new(1, 1, 1)
		entry.Stroke.Transparency = on and 0 or 0.55
		entry.Stroke.Thickness = on and 3 or 2
		entry.Stroke.Transparency = on and 0 or 0.55
	end
end

local function pill(text: string, action: string, order: number)
	local UI = ctx.UI
	local b = UI.new("TextButton", {
		Name = action,
		Size = UDim2.fromOffset(92, 36),
		Text = text,
		Font = UI.Font.Bold,
		TextSize = 14,
		TextColor3 = UI.Color.Text,
		BackgroundColor3 = Color3.fromRGB(20, 20, 24),
		BackgroundTransparency = 0.35,
		LayoutOrder = order,
		Parent = pills,
	})
	UI.corner(b, 18)
	UI.stroke(b, Color3.new(1, 1, 1), 1.5, 0.6)
	b.Activated:Connect(function()
		ctx.Input.fire(action, true)
		ctx.Input.fire(action, false)
	end)
end

local function setVisible(v: boolean)
	gui.Enabled = v
	if v then
		layout()
	end
end

function MobileControls.init(c)
	ctx = c
	ctx.MobileControls = MobileControls
end

function MobileControls.refresh()
	if gui and gui.Enabled then
		layout()
	end
end

function MobileControls.start()
	gui = ctx.UI.new("ScreenGui", {
		Name = "HomeAloneTouch",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 6,
		Enabled = false,
		Parent = ctx.UI.PlayerGui,
	})
	for name in DEFS do
		makeButton(name)
	end
	local inset = GuiService:GetGuiInset()
	pills = ctx.UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, inset.Y + 8),
		Size = UDim2.fromOffset(200, 36),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	ctx.UI.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = pills,
	})
	pill("JOURNAL", "Journal", 1)
	pill("PHONE", "Phone", 2)

	for _, attr in { "InGame", "Hiding", "Captured", "Escaped", "Item_Flashlight", "Item_PepperSpray" } do
		player:GetAttributeChangedSignal(attr):Connect(function()
			if gui.Enabled then
				layout()
			end
		end)
	end
	workspace:GetAttributeChangedSignal("EndingActive"):Connect(function()
		if gui.Enabled then
			layout()
		end
	end)
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if gui.Enabled then
				layout()
			end
		end)
	end

	setVisible(ctx.UI.isTouch())
	ctx.UI.onTouchChanged(setVisible)

	-- the Roblox TouchGui (and its jump button) appears a moment after spawn; re-anchor to it
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		if not gui.Enabled then
			return
		end
		refreshActive()
		acc += dt
		if acc > 2 then
			acc = 0
			layout()
		end
	end)
end

return MobileControls
