--[[
	ChatDodge (v164, the owner: "the chat box hides some UI when opened. Make it so that that UI moves up/down when chat box is
	closed/opened"). Roblox's chat window opens at the top left, over our top-left UI: the house's clock / act / items column (and
	the 🎲 / 🚀 / 😱 buttons under it), the lobby's ▶ PLAY and its two icons. While the chat window is open those slide down to just
	under it; closed, they slide back.

	Is it open? StarterGui:GetCore("ChatActive") (works with TextChatService in the live client); where that isn't available, the
	chat window's own size (ChatWindowConfiguration.AbsoluteSize). Where it is: ChatWindowConfiguration / ChatInputBarConfiguration
	AbsolutePosition + AbsoluteSize (the lower of the two), turned into our UI's units (UI.Root's UIScale, the top bar inset).
	Only things that sit in the same columns as the chat window move.

		ChatDodge.register(gui)   -- remember gui's Position and keep it under the chat window while it's open
		ChatDodge.offsetFor(gui, baseTop) -- for things placed every frame (the house's clock column): the push down
		ChatDodge.bottom()        -- the chat window's lower edge in UI units (0 = closed)
]]

local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local GuiService = game:GetService("GuiService")

local ChatDodge = {}
local ctx

local GAP = 8
local items: { { Gui: GuiObject, Base: UDim2 } } = {}
local current = { Bottom = 0, Left = 0, Right = 0 }

local function scale(): number
	if ctx and ctx.UI and type(ctx.UI.Scale) == "number" and ctx.UI.Scale > 0 then
		return ctx.UI.Scale
	end
	local s = ctx and ctx.UI and ctx.UI.Root and ctx.UI.Root:FindFirstChildOfClass("UIScale")
	return (s and s.Scale > 0) and s.Scale or 1
end

-- is the chat window open right now?
local function isOpen(): boolean
	local cfg = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
	if cfg and not cfg.Enabled then
		return false
	end
	local okCore, coreOn = pcall(function()
		return StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
	end)
	if okCore and coreOn == false then
		return false
	end
	local ok, active = pcall(function()
		return StarterGui:GetCore("ChatActive")
	end)
	if ok and type(active) == "boolean" then
		return active
	end
	-- (no ChatActive here: the window's own size)
	local okSize, size = pcall(function()
		return cfg and cfg.AbsoluteSize
	end)
	return okSize and typeof(size) == "Vector2" and size.Y > 1
end

-- the chat window's box in our UI's units: top-left x, right x, bottom y
local function rect(): (number, number, number)
	local inset = GuiService:GetGuiInset()
	local bottom, left, right = 0, math.huge, -math.huge
	for _, className in { "ChatWindowConfiguration", "ChatInputBarConfiguration" } do
		local cfg = TextChatService:FindFirstChildOfClass(className)
		local ok, pos, size = pcall(function()
			return (cfg :: any).AbsolutePosition, (cfg :: any).AbsoluteSize
		end)
		if ok and typeof(pos) == "Vector2" and typeof(size) == "Vector2" and size.Y > 1 then
			-- (measured under the top bar; our ScreenGuis ignore the inset)
			local y = pos.Y < inset.Y * 0.5 and pos.Y + inset.Y or pos.Y
			bottom = math.max(bottom, y + size.Y)
			left = math.min(left, pos.X)
			right = math.max(right, pos.X + size.X)
		end
	end
	if bottom <= 0 then
		-- (nothing measured: Roblox's default window, top left, about a third of the screen tall)
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(844, 390)
		bottom = inset.Y + math.max(160, vp.Y * 0.36)
		left, right = 0, math.min(vp.X * 0.45, 420)
	end
	local s = scale()
	return left / s, right / s, bottom / s
end
ChatDodge._rect = rect
ChatDodge._items = function() return items end -- (tests)

function ChatDodge.bottom(): number
	return current.Bottom
end

-- how far down `gui` (its top at baseTop, in UI units) must go to sit under the open chat window (0 if closed or not under it)
function ChatDodge.offsetFor(gui: GuiObject, baseTop: number): number
	if current.Bottom <= 0 then
		return 0
	end
	-- (only what sits under the chat window's columns moves)
	local x = gui.AbsolutePosition.X / scale()
	local w = math.max(1, gui.AbsoluteSize.X / scale())
	if x < current.Right and x + w >= current.Left then
		return math.max(0, current.Bottom + GAP - baseTop)
	end
	return 0
end

local function place(item, animate: boolean)
	local g = item.Gui
	if not g.Parent then
		return
	end
	local target = item.Base + UDim2.fromOffset(0, ChatDodge.offsetFor(g, item.Base.Y.Offset))
	if g.Position ~= target then
		if animate and ctx.UI.tween then
			ctx.UI.tween(g, 0.2, { Position = target })
		else
			g.Position = target
		end
	end
end

function ChatDodge.register(gui: GuiObject)
	local item = { Gui = gui, Base = gui.Position }
	table.insert(items, item)
	place(item, false)
end

-- check the chat window and move things (the tests call this directly)
local forced: { any }? = nil -- (tests / ui_dump: a chat window that stays as given)
function ChatDodge._force(open: boolean, r: { number }?)
	forced = { open, r }
	ChatDodge.refresh(open, r, true)
end

function ChatDodge.refresh(open: boolean?, r: { number }?, instant: boolean?)
	if open == nil and forced then
		open, r = forced[1], forced[2]
	end
	local o = open
	if o == nil then
		o = isOpen()
	end
	local was = current.Bottom
	if o then
		local left, right, bottom
		if r then
			left, right, bottom = r[1], r[2], r[3]
		else
			left, right, bottom = rect()
		end
		current = { Bottom = bottom, Left = left, Right = right }
	else
		current = { Bottom = 0, Left = 0, Right = 0 }
	end
	if current.Bottom ~= was then
		for i = #items, 1, -1 do
			if not items[i].Gui.Parent then
				table.remove(items, i)
			else
				place(items[i], not instant)
			end
		end
	end
end

function ChatDodge.init(c)
	ctx = c
	ctx.ChatDodge = ChatDodge
end

function ChatDodge.start()
	task.spawn(function()
		while true do
			pcall(ChatDodge.refresh)
			task.wait(0.25)
		end
	end)
end

return ChatDodge
