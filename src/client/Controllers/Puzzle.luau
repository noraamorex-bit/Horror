--[[
	Puzzle — the hands-on puzzles at the electrics (server: PuzzleService). Big targets for touch;
	mouse and gamepad work too.

	Wires     tap a cut wire on the left, then the end of the same colour on the right. A wrong end
	          sparks (he can hear it) and the wire drops back.
	Breakers  tap the tripped circuits to reset them (a good one tapped goes off and needs resetting),
	          then throw the MAIN. The MAIN with anything still off just clunks.

	It sits in the middle of the screen and you can still be caught while you're at it.
]]

local Players = game:GetService("Players")

local Puzzle = {}
local ctx
local player = Players.LocalPlayer

local COLORS = {
	Red = Color3.fromRGB(214, 58, 52),
	Blue = Color3.fromRGB(56, 116, 226),
	Yellow = Color3.fromRGB(236, 196, 52),
	Green = Color3.fromRGB(62, 172, 86),
}

local root: Frame
local title: TextLabel
local hint: TextLabel
local body: Frame
local session: any = nil

function Puzzle.isOpen(): boolean
	return session ~= nil
end

local function send(action: string, payload: any?)
	if session then
		ctx.Remotes.PuzzleInput:FireServer(session.Id, action, payload)
	end
end

local function close()
	session = nil
	if root then
		root.Visible = false
		for _, c in body:GetChildren() do
			c:Destroy()
		end
	end
end

local function button(props: { [string]: any }): TextButton
	local b = ctx.UI.new("TextButton", {
		AutoButtonColor = true,
		Font = ctx.UI.Font.Bold,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 22,
		Parent = body,
	})
	for k, v in props do
		(b :: any)[k] = v
	end
	ctx.UI.corner(b, 10)
	return b
end

-- a straight wire drawn between two points in `body` space
local function wireLine(a: Vector2, b: Vector2, color: Color3): Frame
	local mid = (a + b) / 2
	local d = b - a
	return ctx.UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(mid.X, mid.Y),
		Size = UDim2.fromOffset(d.Magnitude, 10),
		Rotation = math.deg(math.atan2(d.Y, d.X)),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 31,
		Parent = body,
	})
end

---------------------------------------------------------------------------
local function openWires(data)
	title.Text = "SPLICE THE PHONE LINE"
	hint.Text = "Tap a cut wire, then the end of the same colour. Sparks are loud."
	local n = #data.Left
	local W, H = 520, 360
	local rowH = H / n
	local leftX, rightX = 90, W - 90
	local done, links, used = {}, {}, {}
	local picked: number? = nil
	local leftBtn, rightBtn = {}, {}
	for i, c in data.Left do
		local y = rowH * (i - 0.5)
		-- the cut stub coming in from the left
		ctx.UI.new("Frame", { Position = UDim2.fromOffset(0, y - 5), Size = UDim2.fromOffset(leftX, 10), BackgroundColor3 = COLORS[c], BorderSizePixel = 0, ZIndex = 31, Parent = body })
		leftBtn[i] = button({
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(leftX, y), Size = UDim2.fromOffset(84, 64),
			BackgroundColor3 = COLORS[c], Text = string.sub(c, 1, 1), ZIndex = 32,
		})
	end
	for j, c in data.Right do
		local y = rowH * (j - 0.5)
		ctx.UI.new("Frame", { Position = UDim2.fromOffset(rightX, y - 5), Size = UDim2.fromOffset(W - rightX, 10), BackgroundColor3 = COLORS[c], BorderSizePixel = 0, ZIndex = 31, Parent = body })
		rightBtn[j] = button({
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(rightX, y), Size = UDim2.fromOffset(84, 64),
			BackgroundColor3 = COLORS[c], Text = string.sub(c, 1, 1), ZIndex = 32,
		})
	end
	local strokes = {}
	for i, b in leftBtn do
		strokes[i] = ctx.UI.stroke(b, Color3.new(1, 1, 1), 0, 0)
	end
	local function mark()
		for i, b in leftBtn do
			strokes[i].Thickness = (picked == i) and 5 or 0
			b.BackgroundTransparency = done[i] and 0.55 or 0
		end
		for j, b in rightBtn do
			b.BackgroundTransparency = used[j] and 0.55 or 0
		end
	end
	for i, b in leftBtn do
		b.Activated:Connect(function()
			if done[i] then
				return
			end
			picked = i
			mark()
		end)
	end
	for j, b in rightBtn do
		b.Activated:Connect(function()
			if not picked or used[j] then
				return
			end
			local i = picked :: number
			picked = nil
			if data.Right[j] == data.Left[i] then
				done[i] = true
				links[i] = j
				used[j] = true
				send("Click")
				wireLine(Vector2.new(leftX, rowH * (i - 0.5)), Vector2.new(rightX, rowH * (j - 0.5)), COLORS[data.Left[i]])
				local all = true
				for k = 1, n do
					all = all and done[k] == true
				end
				if all then
					hint.Text = "Taping it up..."
					send("Submit", links)
				end
			else
				send("Slip")
				hint.Text = "<font color=\"#ff8a7a\">Sparks!</font> Wrong end. Try again, quietly."
				ctx.UI.tween(b, 0.08, { Rotation = 6 })
				task.delay(0.08, function()
					ctx.UI.tween(b, 0.12, { Rotation = 0 })
				end)
			end
			mark()
		end)
	end
	mark()
end

---------------------------------------------------------------------------
local function openBreakers(data)
	title.Text = "BREAKER PANEL"
	hint.Text = "Reset the TRIPPED circuits, then throw the MAIN."
	local on = {}
	for i = 1, #data.Labels do
		on[i] = not table.find(data.Tripped, i)
	end
	local taps = {}
	local W = 520
	local btns = {}
	local function paint(i: number)
		local b = btns[i]
		b.Text = data.Labels[i] .. "\n" .. (on[i] and "ON" or "TRIPPED")
		b.BackgroundColor3 = on[i] and Color3.fromRGB(46, 54, 50) or Color3.fromRGB(150, 92, 20)
		b.TextColor3 = on[i] and Color3.fromRGB(170, 220, 180) or Color3.new(1, 1, 1)
	end
	for i = 1, #data.Labels do
		local col = (i - 1) % 2
		local row = (i - 1) // 2
		btns[i] = button({
			Position = UDim2.fromOffset(col * (W / 2) + 8, row * 72 + 4), Size = UDim2.fromOffset(W / 2 - 16, 62),
			TextSize = 17, ZIndex = 32,
		})
		paint(i)
		btns[i].Activated:Connect(function()
			on[i] = not on[i]
			table.insert(taps, i)
			send("Click")
			paint(i)
		end)
	end
	local main = button({
		Position = UDim2.fromOffset(W / 2 - 150, 4 * 72 + 14), Size = UDim2.fromOffset(300, 70),
		BackgroundColor3 = Color3.fromRGB(150, 30, 30), Text = "MAIN", TextSize = 30, ZIndex = 32,
	})
	main.Activated:Connect(function()
		table.insert(taps, 0)
		local all = true
		for i = 1, #on do
			all = all and on[i]
		end
		if all then
			hint.Text = "The house hums back to life..."
			send("Submit", taps)
		else
			send("Slip")
			hint.Text = "<font color=\"#ff8a7a\">CLUNK.</font> Something's still tripped."
		end
	end)
end

---------------------------------------------------------------------------
function Puzzle.init(c)
	ctx = c
	ctx.PuzzleUI = Puzzle
end

function Puzzle.start()
	local UI = ctx.UI
	root = UI.new("Frame", {
		Name = "Puzzle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(580, 560),
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.08,
		Visible = false,
		ZIndex = 30,
		Parent = UI.Top,
	})
	UI.corner(root, 16)
	UI.stroke(root, Color3.new(1, 1, 1), 1, 0.75)
	UI.modal(root)
	title = UI.label({ Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -90, 0, 30), Text = "", Font = UI.Font.Bold, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 31, Parent = root })
	hint = UI.label({ Position = UDim2.fromOffset(20, 48), Size = UDim2.new(1, -40, 0, 40), Text = "", TextSize = 16, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 31, Parent = root })
	body = UI.new("Frame", { Position = UDim2.fromOffset(30, 100), Size = UDim2.fromOffset(520, 440), BackgroundTransparency = 1, ZIndex = 31, Parent = root })
	local x = UI.new("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(56, 44),
		Text = "X", Font = UI.Font.Bold, TextSize = 22, TextColor3 = UI.Color.Text, BackgroundColor3 = Color3.fromRGB(40, 40, 46), ZIndex = 32, Parent = root,
	})
	UI.corner(x, 10)
	x.Activated:Connect(function()
		send("Cancel")
		close()
	end)

	ctx.Remotes.Puzzle.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			close()
			return
		end
		if payload.Result then
			if session and session.Id == payload.Id then
				if payload.Result == "Solved" then
					hint.Text = "Done."
					task.delay(0.5, function()
						if session == nil or session.Id == payload.Id then
							close()
						end
					end)
					session = nil
				else
					close()
				end
			end
			return
		end
		close()
		session = { Id = payload.Id, Kind = payload.Kind }
		if payload.Kind == "Wires" then
			openWires(payload.Data)
		elseif payload.Kind == "Breakers" then
			openBreakers(payload.Data)
		end
		root.Visible = true
		if ctx.Effects then
			ctx.Effects.playSound("UIWhoosh", nil, { Caption = false })
		end
	end)
	-- caught, hiding or out of the night: it goes away
	for _, attr in { "Captured", "Hiding", "Dead", "InGame" } do
		player:GetAttributeChangedSignal(attr):Connect(function()
			if session and (player:GetAttribute("Captured") or player:GetAttribute("Hiding") or player:GetAttribute("Dead") or not player:GetAttribute("InGame")) then
				close()
			end
		end)
	end
end

return Puzzle
