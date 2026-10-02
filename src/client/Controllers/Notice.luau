--[[
	Notice — one message at a time, in a card with a big OK button.
	Other messages (chapter cards, thoughts) wait until it's dismissed.

	Notice.show({ Title, Body, Button? }, onClose?)
	Notice.isOpen()
	Notice.whenClear(fn)   runs fn now, or right after the last notice is closed
]]

local Notice = {}
local ctx

local queue = {}
local waiting = {}
local card: Frame
local titleLabel: TextLabel
local bodyLabel: TextLabel
local okButton: TextButton
local current = nil

local function flushWaiting()
	local list = waiting
	waiting = {}
	for _, fn in list do
		task.spawn(fn)
	end
end

local function showNext()
	current = table.remove(queue, 1)
	if not current then
		card.Visible = false
		flushWaiting()
		return
	end
	titleLabel.Text = current.Title or ""
	bodyLabel.Text = current.Body or ""
	okButton.Text = current.Button or "OK"
	card.Visible = true
	card.Position = UDim2.fromScale(0.5, 0.53)
	ctx.UI.tween(card, 0.35, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Back)
end

local function close()
	if not current then
		return
	end
	local done = current.OnClose
	current = nil
	if done then
		task.spawn(done)
	end
	showNext()
end

-- held back (the night's opening shot is playing): cards wait, then come in order
local holdUntil = 0

function Notice.hold(seconds: number)
	holdUntil = os.clock() + seconds
	task.delay(seconds + 0.05, function()
		if not current and os.clock() >= holdUntil then
			showNext()
		end
	end)
end

function Notice.show(data, onClose: (() -> ())?)
	data.OnClose = onClose
	table.insert(queue, data)
	if not current and os.clock() >= holdUntil then
		showNext()
	end
end

function Notice.isOpen(): boolean
	return current ~= nil or os.clock() < holdUntil
end

function Notice.whenClear(fn: () -> ())
	if current or os.clock() < holdUntil then
		table.insert(waiting, fn)
	else
		task.spawn(fn)
	end
end

function Notice.init(c)
	ctx = c
	ctx.Notice = Notice
end

function Notice.start()
	if ctx.Remotes.Notice then
		ctx.Remotes.Notice.OnClientEvent:Connect(function(data)
			if type(data) == "table" then
				Notice.show(data)
			end
		end)
	end
	local UI = ctx.UI
	card = UI.new("Frame", {
		Name = "Notice",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(560, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.08,
		Visible = false,
		ZIndex = 50,
		Parent = UI.Top,
	})
	UI.corner(card, 14)
	UI.stroke(card, Color3.new(1, 1, 1), 1.5, 0.75)
	UI.padding(card, 26)
	UI.modal(card)
	UI.new("UIListLayout", { Padding = UDim.new(0, 16), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
	titleLabel = UI.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = UI.Font.Title, TextSize = 30, LayoutOrder = 1, ZIndex = 51, Parent = card })
	bodyLabel = UI.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 18, TextColor3 = Color3.fromRGB(215, 210, 200), LayoutOrder = 2, ZIndex = 51, Parent = card })
	okButton = UI.new("TextButton", {
		Size = UDim2.fromOffset(220, 64),
		Text = "OK",
		Font = UI.Font.Bold,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(15, 15, 15),
		BackgroundColor3 = Color3.fromRGB(240, 236, 228),
		LayoutOrder = 3,
		ZIndex = 51,
		Parent = card,
	})
	UI.corner(okButton, 12)
	okButton.Activated:Connect(close)
	ctx.Input.on("Close", function(began)
		if began then
			close()
		end
	end)
end

return Notice
