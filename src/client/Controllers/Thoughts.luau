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

-- full-screen moments nothing should talk over: a notice card, a conversation, a cutscene or
-- the ending, a result card, the difficulty vote
function Pace.blocked(): boolean
	return (ctx.Notice ~= nil and ctx.Notice.isOpen())
		or (ctx.Dialogue ~= nil and ctx.Dialogue.isOpen())
		or workspace:GetAttribute("EndingActive") ~= nil
		or (ctx.Cutscene ~= nil and ctx.Cutscene.isPlaying())
		or (ctx.EndingUI ~= nil and ctx.EndingUI.isShowing())
		or (ctx.VoteUI ~= nil and ctx.VoteUI.isOpen())
end

-- a message from an earlier act no longer fits the moment
function Pace.stale(act: string?): boolean
	return act ~= nil and workspace:GetAttribute("Act") ~= act
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
		Pace.take(ctx.Config.Thoughts.Duration + 0.8)
		-- a thought that waited too long no longer fits the moment: let it go
		local item = table.remove(queue, 1)
		while item and (os.clock() - item.Time > (item.Hint and 20 or 9) or Pace.stale(item.Act)) do
			item = table.remove(queue, 1)
		end
		if not item then
			Pace.FreeAt = 0
			break
		end
		line.Text = item.Text
		tip.Text = hintText(item.Hint)
		tip.Visible = tip.Text ~= ""
		frame.Visible = true
		local stroke = frame:FindFirstChildOfClass("UIStroke")
		line.TextTransparency = 1
		tip.TextTransparency = 1
		frame.BackgroundTransparency = 1
		if stroke then
			stroke.Transparency = 1
			ctx.UI.tween(stroke, 0.3, { Transparency = 0.88 })
		end
		ctx.UI.tween(frame, 0.3, { BackgroundTransparency = 0.3 })
		ctx.UI.tween(line, 0.4, { TextTransparency = 0 })
		ctx.UI.tween(tip, 0.4, { TextTransparency = 0.1 })
		task.wait(ctx.Config.Thoughts.Duration)
		ctx.UI.tween(line, 0.4, { TextTransparency = 1 })
		ctx.UI.tween(tip, 0.4, { TextTransparency = 1 })
		ctx.UI.tween(frame, 0.4, { BackgroundTransparency = 1 })
		if stroke then
			ctx.UI.tween(stroke, 0.4, { Transparency = 1 })
		end
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
	local item = { Text = text, Hint = hint, Time = os.clock(), Act = workspace:GetAttribute("Act") }
	if hint == "breath" then
		-- (urgent: he's right outside. It goes next, not after whatever was queued)
		table.insert(queue, 1, item)
	else
		table.insert(queue, item)
	end
	task.spawn(run)
end

function Thoughts.init(c)
	ctx = c
	ctx.Thoughts = Thoughts
	ctx.Pace = Pace
end

function Thoughts.start()
	local UI = ctx.UI
	-- everything said at the bottom of the screen shares one stack, so it can never overlap:
	-- sound captions and spoken lines above (HUD), your own thought at the bottom
	local stack = UI.new("Frame", {
		Name = "Subtitles",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -104),
		Size = UDim2.fromOffset(720, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = UI.Root,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = stack })
	UI.Subtitles = stack
	frame = UI.box({
		Name = "Thought",
		BackgroundTransparency = 0.3,
		Visible = false,
		LayoutOrder = 1000,
		Parent = stack,
	}, { 8, 16 })
	UI.new("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })
	line = UI.fitLabel({
		Text = "",
		Font = UI.Font.Body,
		TextSize = 25,
		TextColor3 = Color3.fromRGB(245, 240, 228),
		RichText = false,
		LayoutOrder = 1,
		Parent = frame,
	}, 680)
	tip = UI.fitLabel({
		Text = "",
		Font = UI.Font.Bold,
		TextSize = 17,
		TextColor3 = UI.Color.Dim,
		LayoutOrder = 2,
		Parent = frame,
	}, 680)
	ctx.Remotes.Thought.OnClientEvent:Connect(Thoughts.say)
end

return Thoughts
