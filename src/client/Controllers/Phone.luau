--[[
	Phone — your cell: texts (over Wi-Fi, until the power dies), signal bars, and a
	press-and-hold "Call 911" that only connects where there's a bar of signal.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Phone = {}
local ctx
local player = Players.LocalPlayer

local panel: Frame
local list: ScrollingFrame
local signalLabel: TextLabel
local callButton: TextButton
local open = false
local calling = false

local function setCalling(on: boolean)
	if on == calling then
		return
	end
	calling = on
	ctx.Remotes.Phone:FireServer(on and "CallStart" or "CallStop")
end

function Phone.toggle(force: boolean?)
	if force ~= nil then
		open = force
	else
		open = not open
	end
	-- on touch screens the right side belongs to the action buttons
	if ctx.UI.isTouch() then
		panel.AnchorPoint = Vector2.new(0, 0.5)
		panel.Position = UDim2.new(0, 24, 0.5, 0)
	else
		panel.AnchorPoint = Vector2.new(1, 1)
		panel.Position = UDim2.new(1, -24, 1, -24)
	end
	panel.Visible = open
	if not open then
		setCalling(false)
	end
end

local function render(texts)
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local UI = ctx.UI
	for i, t in texts do
		local bubble = UI.new("Frame", {
			Size = UDim2.new(1, -6, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(38, 40, 48),
			LayoutOrder = -i,
			Parent = list,
		})
		UI.corner(bubble, 10)
		UI.padding(bubble, 8)
		UI.new("UIListLayout", { Padding = UDim.new(0, 2), Parent = bubble })
		UI.label({ Size = UDim2.new(1, 0, 0, 16), Text = "<b>" .. t.From .. "</b>  <font color=\"#8a8a8a\">" .. (t.Time or "") .. "</font>", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = bubble })
		UI.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = t.Body, RichText = false, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = bubble })
	end
end

function Phone.init(c)
	ctx = c
	ctx.Phone = Phone
end

function Phone.start()
	local UI = ctx.UI
	panel = UI.new("Frame", {
		Name = "Phone",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(280, 470),
		BackgroundColor3 = Color3.fromRGB(10, 10, 12),
		Visible = false,
		Parent = UI.Root,
	})
	UI.corner(panel, 24)
	UI.stroke(panel, Color3.fromRGB(80, 80, 90), 3, 0.2)
	UI.modal(panel)
	local screen = UI.new("Frame", { Position = UDim2.fromOffset(12, 14), Size = UDim2.new(1, -24, 1, -28), BackgroundColor3 = Color3.fromRGB(20, 22, 28), Parent = panel })
	UI.corner(screen, 16)
	signalLabel = UI.label({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -60, 0, 20), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = screen })
	local close = UI.new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 0), Size = UDim2.fromOffset(36, 32), Text = "✕", TextSize = 18, Font = UI.Font.Bold, TextColor3 = UI.Color.Dim, BackgroundTransparency = 1, Parent = screen })
	close.Activated:Connect(function()
		Phone.toggle(false)
	end)
	list = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 32),
		Size = UDim2.new(1, -16, 1, -110),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		Parent = screen,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	UI.label({ Size = UDim2.new(1, 0, 0, 40), Text = "No messages", TextColor3 = UI.Color.Dim, TextSize = 14, LayoutOrder = 1000, Name = "Empty", Parent = list })

	callButton = UI.new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(1, -24, 0, 58),
		Text = "HOLD TO CALL 911",
		Font = UI.Font.Bold,
		TextSize = 17,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		AutoButtonColor = false,
		Parent = screen,
	})
	UI.corner(callButton, 12)
	-- hold to call: only a touch that starts on the button, until that finger lifts
	local holding: InputObject? = nil
	callButton.InputBegan:Connect(function(io)
		if holding or io.UserInputState ~= Enum.UserInputState.Begin then
			return
		end
		if io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then
			holding = io
			setCalling(true)
		end
	end)
	game:GetService("UserInputService").InputEnded:Connect(function(io)
		if holding and (io == holding or io.UserInputType == Enum.UserInputType.MouseButton1 and holding.UserInputType == Enum.UserInputType.MouseButton1) then
			holding = nil
			setCalling(false)
		end
	end)

	ctx.Remotes.Texts.OnClientEvent:Connect(function(texts)
		render(texts)
		local empty = list:FindFirstChild("Empty")
		if empty then
			(empty :: TextLabel).Visible = #texts == 0
		end
	end)
	ctx.Input.on("Phone", function(began)
		if began and player:GetAttribute("InGame") and not player:GetAttribute("Captured") then
			Phone.toggle()
		end
	end)
	ctx.Input.on("Close", function(began)
		if began and open then
			Phone.toggle(false)
		end
	end)
	player:GetAttributeChangedSignal("Captured"):Connect(function()
		if player:GetAttribute("Captured") then
			Phone.toggle(false)
		end
	end)

	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		if acc < 0.2 or not open then
			return
		end
		acc = 0
		local signal = player:GetAttribute("Signal") or 0
		local bars = string.rep("▮", signal) .. string.rep("▯", 4 - signal)
		local wifi = workspace:GetAttribute("Power") ~= false and "Wi-Fi" or "<font color=\"#8a8a8a\">no Wi-Fi</font>"
		signalLabel.Text = bars .. (signal == 0 and "  No Service" or "  1 bar") .. "   " .. wifi
		if player:GetAttribute("Calling") then
			callButton.Text = string.format("CALLING... %d%%", math.floor((player:GetAttribute("CallProgress") or 0) * 100))
			callButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		else
			callButton.Text = signal > 0 and "HOLD TO CALL 911" or "CALL 911 (no signal)"
			callButton.BackgroundColor3 = signal > 0 and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(34, 34, 34)
		end
	end)
end

return Phone
