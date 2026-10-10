--[[
	Finale — the secret ending's HUD (server: FinaleService, Remotes.Finale).
	The dinner: a banner that says whether he's watching (red: DON'T MOVE), turning (amber) or
	has his back to you (green: STRUGGLE), the strikes and the time to bedtime. The tunnels: the
	lock code found so far and the time to bedtime. The way out: the hatch and the door.
]]

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Finale = {}
local ctx
local player = Players.LocalPlayer

local box: Frame
local big: TextLabel
local small: TextLabel
local vignette: Frame
local state: any = nil
local lastMode: string? = nil

local MODES = {
	Back = { Text = "HIS BACK IS TURNED · STRUGGLE!", Color = Color3.fromRGB(120, 230, 140) },
	Warn = { Text = "HE'S TURNING AROUND...", Color = Color3.fromRGB(255, 190, 80) },
	Watching = { Text = "HE'S WATCHING · DON'T MOVE", Color = Color3.fromRGB(255, 70, 60) },
}

local function clock(endsAt: number?): string
	if not endsAt then
		return ""
	end
	local left = math.max(0, math.floor(endsAt - workspace:GetServerTimeNow()))
	return string.format("%d:%02d", left // 60, left % 60)
end

local function render()
	if not state or state.Phase == "End" then
		box.Visible = false
		vignette.Visible = false
		return
	end
	box.Visible = true
	local tied = player:GetAttribute("FinaleTied") == true
	if state.Phase == "Intro" or state.Phase == "Leaving" then
		big.Text = state.Phase == "Leaving" and "HE'S GONE FOR DESSERT. GET OUT." or "..."
		big.TextColor3 = Color3.new(1, 1, 1)
		small.Text = ""
		vignette.Visible = false
	elseif state.Phase == "Dinner" then
		local m = MODES[state.Mode or "Back"] or MODES.Back
		big.Text = m.Text
		big.TextColor3 = m.Color
		local strikes = string.rep("✕ ", state.Strikes or 0)
		small.Text = string.format("Free %d / %d     Bedtime in %s%s", state.Free or 0, state.Total or 0, clock(state.Ends), strikes ~= "" and ("     <font color=\"#ff6a5a\">" .. strikes .. "</font>") or "")
		vignette.Visible = state.Mode == "Watching"
	else
		big.Text = tied and "YOU'RE BACK AT THE TABLE · STRUGGLE (it's loud)" or ("LOCK CODE   " .. tostring(state.Code or "_ _ _ _"))
		big.TextColor3 = tied and Color3.fromRGB(255, 120, 100) or Color3.fromRGB(255, 220, 140)
		local extra = ""
		if state.Phase == "Out" then
			extra = string.format("     Hatch %d / 4", state.Hatch or 0) .. (state.Barred and "     DOOR BARRED" or "")
		end
		small.Text = "Bedtime in " .. clock(state.Ends) .. extra
		vignette.Visible = false
	end
	if state.Mode ~= lastMode then
		lastMode = state.Mode
		if state.Phase == "Dinner" and ctx.Effects then
			if state.Mode == "Warn" then
				ctx.Effects.playSound("HeartHit", nil, { Caption = false, Volume = 0.6 })
			elseif state.Mode == "Watching" then
				ctx.Effects.playSound("HorrorHitLow", nil, { Caption = false, Volume = 0.35 })
			end
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
	vignette = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(120, 0, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 2, Parent = UI.Root })
	UI.new("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.25, 1), NumberSequenceKeypoint.new(0.75, 1), NumberSequenceKeypoint.new(1, 0.55) }),
		Parent = vignette,
	})
	vignette.BackgroundTransparency = 0
	box = UI.box({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, inset.Y + 64),
		Visible = false,
		ZIndex = 20,
		Parent = UI.Root,
	}, { 8, 18 })
	UI.new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })
	big = UI.label({ LayoutOrder = 1, Size = UDim2.fromOffset(560, 32), Text = "", Font = UI.Font.Bold, TextSize = 26, ZIndex = 21, Parent = box })
	small = UI.label({ LayoutOrder = 2, Size = UDim2.fromOffset(560, 20), Text = "", TextSize = 15, TextColor3 = UI.Color.Dim, ZIndex = 21, Parent = box })
	ctx.Remotes.Finale.OnClientEvent:Connect(function(payload)
		state = type(payload) == "table" and payload or nil
		render()
	end)
	player:GetAttributeChangedSignal("FinaleTied"):Connect(render)
	-- the clock ticks, the red edges breathe while he's watching
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		if vignette.Visible then
			vignette.BackgroundTransparency = 0.25 + 0.2 * math.sin(os.clock() * 5)
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
			render()
		end
	end)
end

return Finale
