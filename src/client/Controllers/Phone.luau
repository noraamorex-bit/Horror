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

-- Messages, as threads: the inbox lists conversations; a conversation shows the bubbles (theirs
-- on the left, yours on the right) and, when you can answer, your reply choices.
local messages = {}
local reply = nil -- { Thread, Options } when you can text back
local view = "inbox" -- or a thread name
local header: TextLabel
local backButton: TextButton
local replyFrame: Frame

local function clearList()
	for _, c in list:GetChildren() do
		if c:IsA("Frame") or c:IsA("TextButton") then
			c:Destroy()
		end
	end
end

local render

local function threads()
	local order, last = {}, {}
	for i, m in messages do
		local t = m.Thread or m.From
		if not last[t] then
			table.insert(order, t)
		end
		last[t] = { Msg = m, Index = i }
	end
	table.sort(order, function(a, b)
		return last[a].Index > last[b].Index
	end)
	return order, last
end

local function renderInbox()
	local UI = ctx.UI
	header.Text = "Messages"
	backButton.Visible = false
	replyFrame.Visible = false
	callButton.Visible = true
	list.Size = UDim2.new(1, -16, 1, -110)
	local order, last = threads()
	for i, t in order do
		local m = last[t].Msg
		local row = UI.new("TextButton", {
			Size = UDim2.new(1, -6, 0, 54),
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(34, 36, 42),
			LayoutOrder = i,
			Parent = list,
		})
		UI.corner(row, 10)
		local waiting = reply and reply.Thread == t
		UI.label({ Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -60, 0, 18), Text = (waiting and "● " or "") .. "<b>" .. t .. "</b>", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		UI.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 6), Size = UDim2.fromOffset(60, 18), Text = m.Time or "", TextSize = 11, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
		UI.label({ Position = UDim2.fromOffset(10, 26), Size = UDim2.new(1, -20, 0, 20), Text = (m.Mine and "You: " or "") .. m.Body, RichText = false, TextTruncate = Enum.TextTruncate.AtEnd, TextSize = 13, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		row.Activated:Connect(function()
			view = t
			render()
		end)
	end
end

local function renderThread(t: string)
	local UI = ctx.UI
	header.Text = t
	backButton.Visible = true
	callButton.Visible = false
	local canReply = reply and reply.Thread == t
	replyFrame.Visible = canReply == true
	for _, c in replyFrame:GetChildren() do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	if canReply then
		for i, option in reply.Options do
			local b = UI.new("TextButton", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = option,
				TextWrapped = true,
				Font = Enum.Font.GothamMedium,
				TextSize = 14,
				TextColor3 = Color3.fromRGB(20, 20, 22),
				BackgroundColor3 = Color3.fromRGB(232, 230, 226),
				LayoutOrder = i,
				Parent = replyFrame,
			})
			UI.corner(b, 10)
			UI.padding(b, 8)
			b.Activated:Connect(function()
				ctx.Remotes.PhoneReply:FireServer(i)
				reply = nil
				render()
			end)
		end
	end
	list.Size = UDim2.new(1, -16, 1, canReply and -(44 + 64 * #reply.Options) or -40)
	local order = 0
	for _, m in messages do
		if (m.Thread or m.From) ~= t then
			continue
		end
		order += 1
		local mine = m.Mine == true
		local holder = UI.new("Frame", { Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order, Parent = list })
		local bubble = UI.new("Frame", {
			AnchorPoint = Vector2.new(mine and 1 or 0, 0),
			Position = UDim2.new(mine and 1 or 0, 0, 0, 0),
			Size = UDim2.new(0.82, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = mine and Color3.fromRGB(226, 224, 220) or Color3.fromRGB(44, 46, 54),
			Parent = holder,
		})
		UI.corner(bubble, 12)
		UI.padding(bubble, 8)
		UI.label({
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = m.Body,
			RichText = false,
			TextWrapped = true,
			TextSize = 14,
			TextColor3 = mine and Color3.fromRGB(20, 20, 22) or Color3.fromRGB(236, 234, 228),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = bubble,
		})
	end
	task.defer(function()
		list.CanvasPosition = Vector2.new(0, 1e6)
	end)
end

render = function()
	clearList()
	local empty = list:FindFirstChild("Empty")
	if empty then
		(empty :: TextLabel).Visible = #messages == 0 and view == "inbox"
	end
	if view == "inbox" then
		renderInbox()
	else
		renderThread(view)
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
	header = UI.label({ Position = UDim2.fromOffset(40, 30), Size = UDim2.new(1, -80, 0, 22), Text = "Messages", Font = Enum.Font.GothamBold, TextSize = 16, Parent = screen })
	backButton = UI.new("TextButton", { Position = UDim2.fromOffset(4, 28), Size = UDim2.fromOffset(36, 26), Text = "‹", TextSize = 24, Font = UI.Font.Bold, TextColor3 = UI.Color.Text, BackgroundTransparency = 1, Visible = false, Parent = screen })
	backButton.Activated:Connect(function()
		view = "inbox"
		render()
	end)
	replyFrame = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, Parent = screen })
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = replyFrame })
	list = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 56),
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

	ctx.Remotes.Texts.OnClientEvent:Connect(function(payload)
		messages = (type(payload) == "table" and payload.Messages) or {}
		reply = type(payload) == "table" and payload.Reply or nil
		-- a question waiting for you: the phone opens straight to that conversation
		if reply then
			view = reply.Thread
		end
		render()
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
		signalLabel.Text = bars .. (signal == 0 and "  No Service" or ("  " .. signal .. (signal == 1 and " bar" or " bars"))) .. "   " .. wifi
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
