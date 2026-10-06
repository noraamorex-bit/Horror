--[[
	Admin — the owner's test panel (server: AdminService). Only built when the server has marked
	this player IsAdmin; every button just asks the server, which checks the UserId again.

	A small ADMIN pill at the top of the screen (or F2) opens it. Tabs:
		NIGHT     start now (Normal / Hard), jump to any act, next act, restart act / house,
		          call help, police in 5 s
		HIM       hunt / hunt me / lurk / offstage / appear / freeze / bring him to me / trap,
		          X-ray (see him through walls)
		ME        invisible to him, all items, battery, nerve, free, revive, teleport to a room
		EVENTS    fire any scripted event
		ENDINGS   trigger any ending
	A line of live debug (act, his state, difficulty, police timer) sits under the pill.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Admin = {}
local ctx
local player = Players.LocalPlayer

local panel: Frame
local body: ScrollingFrame
local status: TextLabel
local debugLine: TextLabel
local tabs: { [string]: TextButton } = {}
local current = "NIGHT"
local info = { Rooms = {}, Events = {}, Endings = {}, Acts = { "Evening", "SmallThings", "SomeoneElse", "Guest" } }
local xray: Highlight? = nil
local built = false

local function send(cmd: string, arg: string?)
	status.Text = "…"
	ctx.Remotes.Admin:FireServer(cmd, arg)
end

local function clear()
	for _, c in body:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function section(text: string, order: number)
	ctx.UI.label({
		Size = UDim2.new(1, 0, 0, 22),
		Text = text,
		Font = ctx.UI.Font.Bold,
		TextSize = 13,
		TextColor3 = ctx.UI.Color.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order,
		Parent = body,
	})
end

local function row(order: number): Frame
	local r = ctx.UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order, Parent = body })
	ctx.UI.new("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 38), CellPadding = UDim2.fromOffset(8, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = r })
	return r
end

local function btn(parent: Instance, text: string, onClick: () -> (), danger: boolean?)
	local b = ctx.UI.new("TextButton", {
		Text = text,
		Font = ctx.UI.Font.Bold,
		TextSize = 14,
		TextWrapped = true,
		TextColor3 = danger and Color3.fromRGB(255, 120, 110) or ctx.UI.Color.Text,
		BackgroundColor3 = Color3.fromRGB(30, 30, 36),
		AutoButtonColor = true,
		Parent = parent,
	})
	ctx.UI.corner(b, 8)
	ctx.UI.stroke(b, Color3.new(1, 1, 1), 1, 0.8)
	b.Activated:Connect(onClick)
	return b
end

local function setXray(on: boolean)
	if xray then
		xray:Destroy()
		xray = nil
	end
	if on then
		local curtis = workspace:FindFirstChild("Curtis", true)
		if curtis then
			local h = Instance.new("Highlight")
			h.FillColor = Color3.fromRGB(255, 60, 60)
			h.FillTransparency = 0.6
			h.OutlineColor = Color3.fromRGB(255, 200, 200)
			h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			h.Adornee = curtis
			h.Parent = curtis
			xray = h
		end
	end
end

local RENDER = {}
RENDER.NIGHT = function()
	section("START (from the waiting room)", 1)
	local r1 = row(2)
	btn(r1, "Start: Normal", function() send("start", "Normal") end)
	btn(r1, "Start: Hard", function() send("start", "Hard") end)
	section("JUMP TO ACT", 3)
	local r2 = row(4)
	for _, a in info.Acts do
		btn(r2, a, function() send("act", a) end)
	end
	local r3 = row(5)
	btn(r3, "Next act ▸", function() send("nextact") end)
	btn(r3, "Restart this act", function() send("restartact") end)
	section("HELP", 6)
	local r4 = row(7)
	btn(r4, "Call police (phone)", function() send("help", "Phone") end)
	btn(r4, "Neighbor calls", function() send("help", "Neighbor") end)
	btn(r4, "Car escape help", function() send("help", "Car") end)
	btn(r4, "Police in 5s", function() send("police") end)
	section("CUTSCENES (preview)", 10)
	local r6 = row(11)
	for _, c in { "LightsOut", "HeComesDown", "TiedUp" } do
		btn(r6, c, function() send("cut", c) end)
	end
	section("RESET", 8)
	local r5 = row(9)
	btn(r5, "Reset the house", function() send("restart") end, true)
end
RENDER.HIM = function()
	local r = row(1)
	btn(r, "Hunt", function() send("ai", "hunt") end)
	btn(r, "Hunt ME", function() send("ai", "huntme") end)
	btn(r, "Lurk", function() send("ai", "lurk") end)
	btn(r, "Offstage", function() send("ai", "offstage") end)
	btn(r, "Show himself now", function() send("ai", "appear") end)
	btn(r, "Freeze / unfreeze", function() send("ai", "freeze") end)
	btn(r, "Bring him behind me", function() send("ai", "bring") end, true)
	btn(r, "Trap (basement)", function() send("ai", "trap") end)
	btn(r, "X-ray on/off", function()
		setXray(xray == nil)
		status.Text = xray and "X-ray on." or "X-ray off."
	end)
end
RENDER.ME = function()
	local r = row(1)
	btn(r, "Invisible to him", function() send("me", "ghost") end)
	btn(r, "All items", function() send("me", "items") end)
	btn(r, "Full battery", function() send("me", "battery") end)
	btn(r, "Full nerve + stamina", function() send("me", "heal") end)
	btn(r, "Free me", function() send("me", "free") end)
	btn(r, "Revive me (free)", function() send("me", "revive") end)
	section("TELEPORT", 2)
	local r2 = row(3)
	for _, room in info.Rooms do
		btn(r2, room, function() send("tp", room) end)
	end
end
RENDER.EVENTS = function()
	local r = row(1)
	for _, id in info.Events do
		btn(r, id, function() send("event", id) end)
	end
end
RENDER.ENDINGS = function()
	local r = row(1)
	for _, k in info.Endings do
		btn(r, k, function() send("ending", k) end, true)
	end
end

local function show(tab: string)
	current = tab
	for name, b in tabs do
		b.BackgroundColor3 = name == tab and Color3.fromRGB(240, 236, 228) or Color3.fromRGB(30, 30, 36)
		b.TextColor3 = name == tab and Color3.fromRGB(15, 15, 15) or ctx.UI.Color.Text
	end
	clear()
	RENDER[tab]()
end

local function build()
	if built then
		return
	end
	built = true
	local UI = ctx.UI
	local pill = UI.new("TextButton", {
		Name = "AdminPill",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, -170, 0, 6),
		Size = UDim2.fromOffset(74, 26),
		Text = "ADMIN",
		Font = UI.Font.Bold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(255, 200, 120),
		BackgroundColor3 = Color3.fromRGB(20, 20, 24),
		BackgroundTransparency = 0.2,
		ZIndex = 50,
		Parent = UI.Top,
	})
	UI.corner(pill, 13)
	UI.stroke(pill, Color3.fromRGB(255, 200, 120), 1, 0.4)
	debugLine = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, -170, 0, 34),
		Size = UDim2.fromOffset(320, 16),
		Text = "",
		TextSize = 11,
		TextColor3 = Color3.fromRGB(255, 200, 120),
		TextStrokeTransparency = 0.4,
		ZIndex = 50,
		Parent = UI.Top,
	})

	panel = UI.new("Frame", {
		Name = "AdminPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(540, 520),
		BackgroundColor3 = Color3.fromRGB(12, 12, 15),
		BackgroundTransparency = 0.05,
		Visible = false,
		ZIndex = 40,
		Parent = UI.Top,
	})
	UI.corner(panel, 12)
	UI.stroke(panel, Color3.fromRGB(255, 200, 120), 1.5, 0.5)
	UI.padding(panel, 14)
	UI.modal(panel)
	local head = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = panel })
	UI.label({ Size = UDim2.new(1, -40, 1, 0), Text = "ADMIN  ·  owner only", Font = UI.Font.Bold, TextSize = 18, TextColor3 = Color3.fromRGB(255, 200, 120), TextXAlignment = Enum.TextXAlignment.Left, Parent = head })
	local close = UI.new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(30, 30), Text = "✕", Font = UI.Font.Bold, TextSize = 16, TextColor3 = UI.Color.Text, BackgroundColor3 = Color3.fromRGB(30, 30, 36), Parent = head })
	UI.corner(close, 8)
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	local tabRow = UI.new("Frame", { Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = panel })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabRow })
	for i, name in { "NIGHT", "HIM", "ME", "EVENTS", "ENDINGS" } do
		local b = UI.new("TextButton", { Size = UDim2.fromOffset(96, 32), Text = name, Font = UI.Font.Bold, TextSize = 13, BackgroundColor3 = Color3.fromRGB(30, 30, 36), TextColor3 = UI.Color.Text, LayoutOrder = i, Parent = tabRow })
		UI.corner(b, 8)
		b.Activated:Connect(function()
			show(name)
		end)
		tabs[name] = b
	end
	body = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 80),
		Size = UDim2.new(1, 0, 1, -116),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = panel,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
	status = UI.label({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 28), Text = "", TextSize = 14, TextColor3 = Color3.fromRGB(255, 200, 120), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = panel })

	local function toggle()
		panel.Visible = not panel.Visible
		if panel.Visible then
			show(current)
		end
	end
	pill.Activated:Connect(toggle)
	UserInputService.InputBegan:Connect(function(io, processed)
		if not processed and io.KeyCode == Enum.KeyCode.F2 then
			toggle()
		end
	end)

	ctx.Remotes.AdminReply.OnClientEvent:Connect(function(text, data)
		if type(data) == "table" then
			info = data
			if panel.Visible then
				show(current)
			end
		end
		if type(text) == "string" then
			status.Text = text
		end
	end)
	ctx.Remotes.Admin:FireServer("info")

	-- live debug line
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		local eta = workspace:GetAttribute("PoliceETA")
		local etaText = typeof(eta) == "number" and ("  ·  police " .. math.max(0, math.ceil(eta - workspace:GetServerTimeNow())) .. "s") or ""
		debugLine.Text = string.format("%s  ·  %s  ·  %s%s%s",
			tostring(workspace:GetAttribute("Act") or "-"),
			tostring(workspace:GetAttribute("IntruderState") or "-"),
			tostring(workspace:GetAttribute("Difficulty") or "Normal"),
			etaText,
			player:GetAttribute("AdminGhost") and "  ·  GHOST" or "")
		-- (the X-ray follows him if his model is rebuilt)
		if xray and not xray.Parent then
			setXray(true)
		end
	end)
end

function Admin.init(c)
	ctx = c
end

function Admin.start()
	if player:GetAttribute("IsAdmin") then
		build()
	end
	player:GetAttributeChangedSignal("IsAdmin"):Connect(function()
		if player:GetAttribute("IsAdmin") then
			build()
		end
	end)
end

return Admin
