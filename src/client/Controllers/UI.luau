--[[
	UI — shared helpers and the root ScreenGui. Everything scales with the screen,
	so the same layout works from a phone in landscape up to a 4K monitor.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UI = {}

UI.Font = {
	Title = Enum.Font.SpecialElite,
	Body = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
	Mono = Enum.Font.Code,
}

UI.Color = {
	Text = Color3.fromRGB(232, 228, 218),
	Dim = Color3.fromRGB(150, 146, 138),
	Panel = Color3.fromRGB(14, 14, 16),
	Paper = Color3.fromRGB(236, 230, 212),
	Ink = Color3.fromRGB(40, 36, 30),
	-- minimal and colourless: "accent" is just brighter white
	Accent = Color3.fromRGB(245, 245, 245),
	Good = Color3.fromRGB(215, 215, 215),
	Danger = Color3.fromRGB(255, 255, 255),
	Info = Color3.fromRGB(200, 200, 200),
}

function UI.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	if inst:IsA("GuiObject") then
		(inst :: GuiObject).BorderSizePixel = 0
	end
	if props then
		local parent = props.Parent
		for k, v in props do
			if k ~= "Parent" then
				(inst :: any)[k] = v
			end
		end
		if children then
			for _, c in children do
				c.Parent = inst
			end
		end
		if parent then
			inst.Parent = parent
		end
	end
	return inst
end

function UI.corner(parent: Instance, radius: number?)
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

function UI.stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?)
	return UI.new("UIStroke", {
		Color = color or Color3.new(1, 1, 1),
		Thickness = thickness or 1,
		Transparency = transparency or 0.8,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function UI.padding(parent: Instance, px: number)
	return UI.new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		Parent = parent,
	})
end

function UI.label(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = UI.Font.Body,
		TextColor3 = UI.Color.Text,
		TextSize = 18,
		TextWrapped = true,
		RichText = true,
	}
	for k, v in props do
		defaults[k] = v
	end
	return UI.new("TextLabel", defaults)
end

function UI.tween(inst: Instance, time: number, props: { [string]: any }, style: Enum.EasingStyle?)
	local tw = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- A button that frees the mouse while visible (first-person locks the cursor otherwise)
function UI.modal(parent: Instance)
	return UI.new("TextButton", {
		Name = "Modal",
		Modal = true,
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(1, 1),
		Parent = parent,
	})
end

-- Touch is the primary input right now (phones/tablets; also true after tapping on a touch laptop)
local touchNow = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local touchListeners = {}

function UI.isTouch(): boolean
	return touchNow
end

function UI.onTouchChanged(fn: (boolean) -> ())
	table.insert(touchListeners, fn)
end

local function setTouch(v: boolean)
	if v ~= touchNow then
		touchNow = v
		for _, fn in touchListeners do
			task.spawn(fn, v)
		end
	end
end

UserInputService.LastInputTypeChanged:Connect(function(t)
	if t == Enum.UserInputType.Touch then
		setTouch(true)
	elseif t == Enum.UserInputType.Keyboard or t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.MouseButton1 or t.Name:find("Gamepad") then
		setTouch(false)
	end
end)

function UI.isGamepad(): boolean
	return UserInputService:GetLastInputType().Name:find("Gamepad") ~= nil
end

function UI.init(ctx)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	UI.PlayerGui = playerGui
	UI.Root = UI.new("ScreenGui", {
		Name = "HomeAlone",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 5,
		Parent = playerGui,
	})
	-- overlays that must sit above everything (fades, ending)
	UI.Top = UI.new("ScreenGui", {
		Name = "HomeAloneTop",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 20,
		Parent = playerGui,
	})
	local scale = UI.new("UIScale", { Parent = UI.Root })
	local topScale = UI.new("UIScale", { Parent = UI.Top })
	local function rescale()
		local cam = workspace.CurrentCamera
		local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local s = math.clamp(math.min(v.X / 1100, v.Y / 620), 0.62, 1.3)
		scale.Scale = s
		topScale.Scale = s
		UI.Scale = s
	end
	UI.Scale = 1
	rescale()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(rescale)
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end
	ctx.UI = UI
end

return UI
