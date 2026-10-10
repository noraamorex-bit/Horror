--[[
	Finale — the secret ending's HUD (server: FinaleService, Remotes.Finale).

	A slim bar at the top of the screen, one line:
		● STATUS        where he is: his back is turned (green), he's turning (amber), he's
		                watching (red); later: upstairs (with the time until he comes back), in the
		                tunnels, hunting everyone
		CODE 4 _ _ _    the lock code found so far (tunnels and the way out)
		extras          bedtime, strikes, the hatch
	Under it, only when it matters (at the table, or tied up again), one short line of what to do.
	The objective panel already says where to go in the tunnels, so the bar stays small.
	While he watches the table the edges of the screen go red.
]]

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Finale = {}
local ctx
local player = Players.LocalPlayer

local GREEN = Color3.fromRGB(120, 230, 140)
local AMBER = Color3.fromRGB(255, 190, 80)
local RED = Color3.fromRGB(255, 80, 64)
local WHITE = Color3.fromRGB(236, 232, 224)
local DIM = Color3.fromRGB(160, 156, 148)

local bar: Frame
local dot: Frame
local status: TextLabel
local code: TextLabel
local extra: TextLabel
local todo: TextLabel
local vignette: Frame
local state: any = nil
local lastMode: string? = nil
local lastCode = ""

local function left(endsAt: number?): number?
	if not endsAt then
		return nil
	end
	return math.max(0, math.floor(endsAt - workspace:GetServerTimeNow()))
end

local function clock(secs: number?): string
	if not secs then
		return ""
	end
	return string.format("%d:%02d", secs // 60, secs % 60)
end

local function setStatus(text: string, color: Color3)
	status.Text = text
	status.TextColor3 = color
	dot.BackgroundColor3 = color
end

local function struggleHow(): string
	return ctx.UI.isTouch() and "tap STRUGGLE" or "mash SPACE"
end

local function render()
	if not state or state.Phase == "End" then
		bar.Visible = false
		todo.Visible = false
		vignette.Visible = false
		return
	end
	bar.Visible = true
	local tied = player:GetAttribute("FinaleTied") == true
	local phase = state.Phase
	local line = ""
	local extras = {}
	code.Visible = false
	vignette.Visible = false
	if phase == "Intro" then
		setStatus("UNDER THE HOUSE", WHITE)
	elseif phase == "Dinner" then
		local mode = state.Mode or "Back"
		if mode == "Watching" then
			setStatus("HE'S WATCHING · DON'T MOVE", RED)
			line = tied and "Don't touch anything." or "Stand still by your chair."
			vignette.Visible = true
		elseif mode == "Warn" then
			setStatus("HE'S TURNING", AMBER)
			line = tied and "Stop struggling!" or "Back to your chair!"
		else
			setStatus("HIS BACK IS TURNED", GREEN)
			if tied then
				line = "Struggle now: " .. struggleHow()
			elseif (state.Free or 0) < (state.Total or 0) then
				line = "Cut a friend loose: hold at their chair"
			end
		end
		table.insert(extras, string.format("%d/%d free", state.Free or 0, state.Total or 0))
		if (state.Strikes or 0) > 0 then
			table.insert(extras, string.rep("✕", math.min(state.Strikes, 5)))
		end
		table.insert(extras, "bed " .. clock(left(state.Ends)))
	elseif phase == "Leaving" then
		setStatus("HE'S LEAVING", WHITE)
	else
		-- the tunnels, and the way out
		local away = left(state.Away)
		local toBed = left(state.Ends)
		if tied then
			setStatus("BACK AT THE TABLE", RED)
			line = "Struggle (" .. struggleHow() .. ", loud) or wait for a friend"
		elseif away and away > 0 then
			setStatus("HE'S UPSTAIRS · " .. clock(away), GREEN)
		elseif toBed and toBed <= 70 then
			setStatus("HE'S HUNTING YOU", RED)
		else
			setStatus("HE'S IN THE TUNNELS", AMBER)
		end
		code.Visible = true
		local c = tostring(state.Code or "_ _ _ _")
		code.Text = "CODE <font color=\"#ffdc8c\">" .. c .. "</font>"
		if c ~= lastCode then
			-- a new digit: the code pops
			if lastCode ~= "" then
				code.TextSize = 20
				ctx.UI.tween(code, 0.35, { TextSize = 15 }, Enum.EasingStyle.Back)
			end
			lastCode = c
		end
		if phase == "Out" then
			table.insert(extras, "hatch " .. math.min(state.Hatch or 0, 4) .. "/4")
			if state.Barred then
				table.insert(extras, "door barred")
			end
		end
		table.insert(extras, "bed " .. clock(toBed))
	end
	extra.Text = table.concat(extras, "  ·  ")
	extra.Visible = #extras > 0
	todo.Text = line
	todo.Visible = line ~= ""
	if state.Mode ~= lastMode then
		lastMode = state.Mode
		if phase == "Dinner" and state.Mode == "Warn" and ctx.Effects then
			ctx.Effects.playSound("HeartHit", nil, { Caption = false, Volume = 0.5 })
		end
	end
end

function Finale.init(c)
	ctx = c
	ctx.FinaleUI = Finale
end

function Finale.start()
	local UI = ctx.UI
	local inset = GuiService:GetGuiInset()
	vignette = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(120, 0, 0), BackgroundTransparency = 0, Visible = false, ZIndex = 2, Parent = UI.Root })
	UI.new("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.25, 1), NumberSequenceKeypoint.new(0.75, 1), NumberSequenceKeypoint.new(1, 0.55) }),
		Parent = vignette,
	})

	-- the bar: one line, sized to what it says
	bar = UI.box({
		Name = "FinaleBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, inset.Y + 6),
		BackgroundTransparency = 0.3,
		Visible = false,
		ZIndex = 20,
		Parent = UI.Root,
	}, { 4, 12 })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = bar })
	dot = UI.new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(10, 10), BackgroundColor3 = WHITE, ZIndex = 21, Parent = bar })
	UI.corner(dot, 5)
	local function piece(order: number, size: number, font: Enum.Font, color: Color3): TextLabel
		return UI.label({ LayoutOrder = order, Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, Text = "", Font = font, TextSize = size, TextColor3 = color, TextWrapped = false, ZIndex = 21, Parent = bar })
	end
	status = piece(2, 16, UI.Font.Bold, WHITE)
	code = piece(3, 15, UI.Font.Bold, DIM)
	extra = piece(4, 13, UI.Font.Body, DIM)

	-- what to do, only when it matters: a small line under the bar
	todo = UI.label({
		Name = "FinaleTodo",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, inset.Y + 40),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "",
		Font = UI.Font.Bold,
		TextSize = 14,
		TextWrapped = false,
		TextStrokeTransparency = 0.4,
		Visible = false,
		ZIndex = 20,
		Parent = UI.Root,
	})

	ctx.Remotes.Finale.OnClientEvent:Connect(function(payload)
		state = type(payload) == "table" and payload or nil
		if not state then
			lastCode = ""
		end
		render()
	end)
	player:GetAttributeChangedSignal("FinaleTied"):Connect(render)
	-- the clocks tick, the red edges breathe while he's watching, the dot pulses
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		if vignette.Visible then
			vignette.BackgroundTransparency = 0.25 + 0.2 * math.sin(os.clock() * 5)
		end
		if bar.Visible then
			dot.BackgroundTransparency = 0.5 - 0.5 * math.abs(math.sin(os.clock() * (state and state.Mode == "Watching" and 6 or 2.5)))
		end
		acc += dt
		if acc >= 0.5 then
			acc = 0
			if state then
				render()
			end
		end
	end)
	workspace:GetAttributeChangedSignal("Act"):Connect(function()
		if workspace:GetAttribute("Act") == "Lobby" then
			state = nil
			lastCode = ""
			render()
		end
	end)
end

return Finale
