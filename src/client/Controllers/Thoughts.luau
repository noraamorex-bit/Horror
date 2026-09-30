--[[
	Thoughts — your character thinking out loud, one line at a time, in big text.
	Each line stays for Config.Thoughts.Duration seconds. A hint key adds a small control tip
	for whatever you're playing on (keyboard, touch or gamepad).
]]

local Thoughts = {}
local ctx

--[[
	Pace — one message on screen at a time. Thoughts, notifications and sound captions all
	take turns: each one claims the screen for a while, the next waits (captions, which are
	extra, are simply dropped when the screen is taken).
]]
local Pace = { FreeAt = 0 }

function Pace.blocked(): boolean
	return (ctx.Notice ~= nil and ctx.Notice.isOpen()) or (ctx.Dialogue ~= nil and ctx.Dialogue.isOpen())
end

function Pace.isFree(): boolean
	return os.clock() >= Pace.FreeAt and not Pace.blocked()
end

-- yields until it's this message's turn, then holds the screen for `seconds`
function Pace.take(seconds: number)
	local clearFor = 0
	while clearFor < 0.6 do
		task.wait(0.1)
		clearFor = Pace.isFree() and clearFor + 0.1 or 0
	end
	Pace.FreeAt = os.clock() + seconds
end

-- a non-blocking claim: true (and the screen is held) only if it's free right now
function Pace.tryTake(seconds: number): boolean
	if not Pace.isFree() then
		return false
	end
	Pace.FreeAt = os.clock() + seconds
	return true
end

local queue = {}
local running = false
local frame: Frame
local line: TextLabel
local tip: TextLabel

local HINTS = {
	journal = { Key = "Press Tab to open your journal", Touch = "Tap JOURNAL at the top right", Pad = "Press D-pad left to open your journal" },
	light = { Key = "Press F to turn it on", Touch = "Tap LIGHT to turn it on", Pad = "Press D-pad up to turn it on" },
	spray = { Key = "Press G to spray", Touch = "Tap SPRAY to use it", Pad = "Press D-pad right to spray" },
	breath = { Key = "Hold Space to hold your breath", Touch = "Hold BREATH to hold your breath", Pad = "Hold A to hold your breath" },
	struggle = { Key = "Mash Space to struggle", Touch = "Mash STRUGGLE", Pad = "Mash A to struggle" },
	phone = { Key = "Press P for your phone", Touch = "Tap PHONE at the top right", Pad = "Press D-pad down for your phone" },
}

local function hintText(key: string?): string
	local h = key and HINTS[key]
	if not h then
		return ""
	end
	if ctx.UI.isTouch() then
		return h.Touch
	elseif ctx.UI.isGamepad() then
		return h.Pad
	end
	return h.Key
end

local function run()
	if running then
		return
	end
	running = true
	while #queue > 0 do
		-- never over a notice, a conversation or another message
		Pace.take(ctx.Config.Thoughts.Duration + 2)
		local item = table.remove(queue, 1)
		line.Text = item.Text
		tip.Text = hintText(item.Hint)
		frame.Visible = true
		line.TextTransparency = 1
		tip.TextTransparency = 1
		ctx.UI.tween(line, 0.4, { TextTransparency = 0 })
		ctx.UI.tween(tip, 0.4, { TextTransparency = 0.1 })
		task.wait(ctx.Config.Thoughts.Duration)
		ctx.UI.tween(line, 0.4, { TextTransparency = 1 })
		ctx.UI.tween(tip, 0.4, { TextTransparency = 1 })
		task.wait(0.45)
	end
	frame.Visible = false
	running = false
end

-- a line is on screen (or queued to be)
function Thoughts.isShowing(): boolean
	return running or #queue > 0
end

function Thoughts.say(text: string, hint: string?)
	-- the same line twice in a row is noise
	local last = queue[#queue]
	if last and last.Text == text then
		return
	end
	table.insert(queue, { Text = text, Hint = hint })
	task.spawn(run)
end

function Thoughts.init(c)
	ctx = c
	ctx.Thoughts = Thoughts
	ctx.Pace = Pace
end

function Thoughts.start()
	local UI = ctx.UI
	frame = UI.new("Frame", {
		Name = "Thought",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -150),
		Size = UDim2.fromOffset(900, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		Parent = UI.Root,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })
	line = UI.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		Font = Enum.Font.GothamMedium,
		TextSize = 32,
		TextColor3 = Color3.fromRGB(245, 240, 228),
		TextStrokeTransparency = 0.35,
		RichText = false,
		LayoutOrder = 1,
		Parent = frame,
	})
	tip = UI.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		Font = UI.Font.Bold,
		TextSize = 22,
		TextColor3 = UI.Color.Accent,
		TextStrokeTransparency = 0.4,
		LayoutOrder = 2,
		Parent = frame,
	})
	ctx.Remotes.Thought.OnClientEvent:Connect(Thoughts.say)
end

return Thoughts
