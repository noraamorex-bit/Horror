--[[
	Finale — the secret ending's HUD (server: FinaleService, Remotes.Finale).

	One card at the top of the screen that always answers two questions: where is he, and what
	do I do right now?
		STATUS       a coloured dot and a word or two: his back is turned (green), he's turning
		             (amber), he's watching (red); later: he's upstairs (with the time until he
		             comes back), he's in the tunnels, he's hunting everyone
		WHAT TO DO   one line for you (tied up or free, keyboard or touch)
		THE CODE     four tiles, filled in as his notes are read, and which notes are left
		CHIPS        bedtime, how many are free, strikes, the hatch, the barred door
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

local card: Frame
local dot: Frame
local status: TextLabel
local todo: TextLabel
local codeRow: Frame
local tiles: { TextLabel } = {}
local noteRow: Frame
local noteChips: { [string]: TextLabel } = {}
local chipRow: Frame
local chips: { TextLabel } = {}
local vignette: Frame
local state: any = nil
local lastMode: string? = nil
local lastCode = ""

local NOTE_ORDER = { { "Pantry", "PANTRY" }, { "Nursery", "NURSERY" }, { "HisRoom", "HIS ROOM" } }

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

local function setChips(list: { { any } })
	for i, c in chips do
		local item = list[i]
		c.Visible = item ~= nil
		if item then
			c.Text = item[1]
			c.TextColor3 = item[2] or WHITE
		end
	end
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
		card.Visible = false
		vignette.Visible = false
		return
	end
	card.Visible = true
	local tied = player:GetAttribute("FinaleTied") == true
	local phase = state.Phase
	codeRow.Visible = false
	noteRow.Visible = false
	vignette.Visible = false
	if phase == "Intro" then
		setStatus("UNDER THE HOUSE", WHITE)
		todo.Text = ""
		setChips({})
	elseif phase == "Dinner" then
		local mode = state.Mode or "Back"
		if mode == "Watching" then
			setStatus("HE'S WATCHING  ·  DON'T MOVE", RED)
			todo.Text = tied and "Don't touch anything until he turns back to the stove." or "Stand still by your chair."
			vignette.Visible = true
		elseif mode == "Warn" then
			setStatus("HE'S TURNING AROUND", AMBER)
			todo.Text = tied and "Stop struggling!" or "Back to your chair, now!"
		else
			setStatus("HIS BACK IS TURNED", GREEN)
			if tied then
				todo.Text = "STRUGGLE NOW: " .. struggleHow() .. " to break the zip tie."
			elseif (state.Free or 0) < (state.Total or 0) then
				todo.Text = "Quick: go to a tied friend and HOLD to cut them loose."
			else
				todo.Text = ""
			end
		end
		local list = { { "BEDTIME " .. clock(left(state.Ends)) }, { string.format("FREE %d / %d", state.Free or 0, state.Total or 0), GREEN } }
		if (state.Strikes or 0) > 0 then
			table.insert(list, { string.rep("✕", math.min(state.Strikes, 6)) .. "  STRIKES", RED })
		end
		setChips(list)
	elseif phase == "Leaving" then
		setStatus("HE'S LEAVING...", WHITE)
		todo.Text = "Let him go. He's climbing up to the house."
		setChips({})
	else
		-- the tunnels, and the way out
		local away = left(state.Away)
		local toBed = left(state.Ends)
		if tied then
			setStatus("BACK AT THE TABLE", RED)
			todo.Text = "Struggle (" .. struggleHow() .. ", it's LOUD) or wait for a friend to cut you loose."
		else
			if away and away > 0 then
				setStatus("HE'S UPSTAIRS  ·  BACK IN " .. clock(away), GREEN)
			elseif toBed and toBed <= 70 then
				setStatus("HE'S HUNTING EVERYONE", RED)
			else
				setStatus("HE'S IN THE TUNNELS", AMBER)
			end
			if phase == "Out" then
				local hatch = state.Hatch or 0
				if hatch >= 4 then
					todo.Text = "The hatch is open: CLIMB THE LADDER OUT!"
				else
					todo.Text = string.format("Push the hatch (%d / 4). It's loud: bar the cellar door first%s.", hatch, ctx.UI.isTouch() and "" or " (R)")
				end
			else
				local missing = {}
				for _, n in NOTE_ORDER do
					if not (state.Notes and state.Notes[n[1]]) then
						table.insert(missing, n[2])
					end
				end
				if #missing > 0 then
					todo.Text = "Read his notes for the lock code: " .. table.concat(missing, ", ") .. ". Follow the signs."
				else
					todo.Text = "Go to the STORM CELLAR (north) and type the code on the keypad."
				end
			end
		end
		-- the code
		codeRow.Visible = phase == "Tunnels" or phase == "Out"
		local code = tostring(state.Code or "_ _ _ _")
		local digits = string.split(code, " ")
		for i, t in tiles do
			local d = digits[i]
			local known = d ~= nil and d ~= "_" and d ~= ""
			t.Text = known and d or "?"
			t.TextColor3 = known and Color3.fromRGB(255, 220, 140) or Color3.fromRGB(110, 106, 100)
		end
		if code ~= lastCode then
			-- a new digit: the tiles pop
			if lastCode ~= "" then
				for _, t in tiles do
					t.TextSize = 40
					ctx.UI.tween(t, 0.35, { TextSize = 30 }, Enum.EasingStyle.Back)
				end
			end
			lastCode = code
		end
		noteRow.Visible = phase == "Tunnels" and not tied
		for key, chip in noteChips do
			local done = state.Notes and state.Notes[key]
			local name = chip:GetAttribute("Name")
			chip.Text = (done and "✓ " or "· ") .. tostring(name)
			chip.TextColor3 = done and GREEN or ctx.UI.Color.Dim
		end
		local list = { { "BEDTIME " .. clock(toBed), (toBed and toBed <= 70) and RED or WHITE } }
		if phase == "Out" then
			local pips = string.rep("●", math.min(state.Hatch or 0, 4)) .. string.rep("○", math.max(0, 4 - (state.Hatch or 0)))
			table.insert(list, { "HATCH " .. pips, AMBER })
			if state.Barred then
				table.insert(list, { "DOOR BARRED", GREEN })
			elseif (state.Bars or 0) > 0 then
				table.insert(list, { string.format("BARS LEFT %d", state.Bars) })
			end
		end
		setChips(list)
	end
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

	card = UI.box({
		Name = "FinaleCard",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, inset.Y + 58),
		BackgroundTransparency = 0.2,
		Visible = false,
		ZIndex = 20,
		Parent = UI.Root,
	}, { 10, 16 })
	UI.new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

	-- 1. status: a dot and a few words
	local statusRow = UI.new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(460, 30), BackgroundTransparency = 1, ZIndex = 21, Parent = card })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10), Parent = statusRow })
	dot = UI.new("Frame", { Size = UDim2.fromOffset(14, 14), BackgroundColor3 = WHITE, ZIndex = 22, Parent = statusRow })
	UI.corner(dot, 7)
	status = UI.label({ Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, Text = "", Font = UI.Font.Bold, TextSize = 24, TextWrapped = false, ZIndex = 22, Parent = statusRow })

	-- 2. what to do
	todo = UI.label({ LayoutOrder = 2, Size = UDim2.fromOffset(460, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = "", TextSize = 15, TextColor3 = WHITE, ZIndex = 21, Parent = card })

	-- 3. the code: four tiles, and the notes still to read
	codeRow = UI.new("Frame", { LayoutOrder = 3, Size = UDim2.fromOffset(460, 54), BackgroundTransparency = 1, Visible = false, ZIndex = 21, Parent = card })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = codeRow })
	UI.label({ LayoutOrder = 0, Size = UDim2.fromOffset(90, 54), Text = "LOCK\nCODE", Font = UI.Font.Bold, TextSize = 13, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 22, Parent = codeRow })
	for i = 1, 4 do
		local t = UI.label({ LayoutOrder = i, Size = UDim2.fromOffset(42, 52), Text = "?", Font = UI.Font.Mono, TextSize = 30, BackgroundTransparency = 0.1, BackgroundColor3 = Color3.fromRGB(26, 22, 18), ZIndex = 22, Parent = codeRow })
		UI.corner(t, 6)
		UI.stroke(t, Color3.fromRGB(255, 220, 140), 1, 0.6)
		tiles[i] = t
	end
	noteRow = UI.new("Frame", { LayoutOrder = 4, Size = UDim2.fromOffset(460, 20), BackgroundTransparency = 1, Visible = false, ZIndex = 21, Parent = card })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 18), SortOrder = Enum.SortOrder.LayoutOrder, Parent = noteRow })
	for i, n in NOTE_ORDER do
		local chip = UI.label({ LayoutOrder = i, Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, Text = "", Font = UI.Font.Bold, TextSize = 13, TextWrapped = false, ZIndex = 22, Parent = noteRow })
		chip:SetAttribute("Name", n[2])
		noteChips[n[1]] = chip
	end

	-- 4. chips
	chipRow = UI.new("Frame", { LayoutOrder = 5, Size = UDim2.fromOffset(460, 24), BackgroundTransparency = 1, ZIndex = 21, Parent = card })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = chipRow })
	for i = 1, 4 do
		local c = UI.label({ LayoutOrder = i, Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, Text = "", Font = UI.Font.Bold, TextSize = 13, TextWrapped = false, BackgroundTransparency = 0.35, BackgroundColor3 = Color3.fromRGB(34, 32, 30), Visible = false, ZIndex = 22, Parent = chipRow })
		UI.corner(c, 12)
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = c })
		chips[i] = c
	end

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
		if card.Visible then
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
