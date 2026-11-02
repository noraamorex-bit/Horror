--[[
	Codes (v138, the owner: "Like ratio is really low. Create a code section in lobby in the UI and make
	it say 'Use Code RELEASE'... Make the code give coins and a title"): the lobby's 🎟 CODES icon and
	panel, and a small gold "USE CODE: RELEASE" chip under the coins until it's used. Type a code (or
	tap USE on the one shown) and the server checks it (EconomyService.redeem: once per player, coins +
	a title). The panel asks for a 👍: new codes come out at like milestones (Economy.LikeMilestones).
	Nothing checks who liked (Roblox can't tell a game that), so nothing is held back for it.
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Codes = {}
local ctx
local Cat
local player = Players.LocalPlayer
local P
local badge: Frame?
local chip: TextButton?
local box: TextBox
local status: TextLabel
local useBtn: TextButton
local waiting = false

local function used(code: string): boolean
	local ok, t = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute("Eco") or "{}")
	end)
	if not ok or type(t) ~= "table" or type(t.Owned) ~= "table" then
		return false
	end
	for _, id in t.Owned do
		if id == "Code_" .. code then
			return true
		end
	end
	return false
end
Codes._used = used -- (tests)

-- the code we show (the newest one still working)
local function featured(): any
	return Cat and Cat.code(Cat.Codes[#Cat.Codes] and Cat.Codes[#Cat.Codes].Code)
end
Codes.featured = featured

local function refresh()
	local c = featured()
	local done = c and used(c.Code)
	if badge then
		badge.Visible = c ~= nil and not done
	end
	if chip then
		chip.Visible = c ~= nil and not done
	end
	if useBtn then
		useBtn.Text = done and "✓ USED" or "USE"
		useBtn.AutoButtonColor = not done
		useBtn.BackgroundTransparency = done and 0.75 or 0
	end
end
Codes._refresh = refresh

local function say(text: string, good: boolean?)
	status.Text = text
	status.TextColor3 = good and ctx.Dock.Gold or Color3.fromRGB(255, 150, 140)
end

function Codes.redeem(text: string)
	if waiting then
		return
	end
	text = string.upper((string.gsub(text or "", "%s", "")))
	if text == "" then
		say("Type a code first.")
		return
	end
	waiting = true
	say("Checking...", true)
	status.TextColor3 = ctx.UI.Color.Dim
	ctx.Remotes.Economy:FireServer("Code", text)
	-- (no answer: let them try again)
	task.delay(6, function()
		if waiting then
			waiting = false
			say("No answer. Try again in a moment.")
		end
	end)
end

function Codes.open()
	if P then
		P.open()
	end
end

function Codes.init(c)
	ctx = c
	ctx.Codes = Codes
	Cat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Economy"))
end

function Codes.start()
	if ctx.Mode ~= "Lobby" or not ctx.Dock then
		return
	end
	local UI, Dock = ctx.UI, ctx.Dock
	local b
	b, badge = Dock.add({ Order = Dock.Order.Codes, Glyph = "🎟️", Label = "CODES", Color = Dock.Gold, OnClick = Codes.open })
	b.Name = "CodesDock"
	P = Dock.panel("Codes")
	local page = P.Pages.Main
	local c = featured()

	-- the code of the moment, big
	local hero = Dock.row(page, 1, 104)
	hero.Name = "Featured"
	UI.stroke(hero, Dock.Gold, 1, 0.6)
	UI.label({ Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -150, 0, 16), Text = "USE CODE", Font = UI.Font.Bold, TextSize = 13, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = hero })
	UI.label({ Name = "Code", Position = UDim2.fromOffset(14, 26), Size = UDim2.new(1, -150, 0, 42), Text = c and c.Code or "", Font = UI.Font.Bold, TextSize = 38, TextColor3 = Dock.Gold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = hero })
	local title = c and c.Title and Cat.cosmetic(c.Title)
	local reward = c and string.format("+%d coins%s", c.Coins or 0, title and string.format("  ·  the title <font color=\"#%s\"><b>%s</b></font>", title.Color:ToHex(), title.Name) or "") or ""
	UI.label({ Position = UDim2.fromOffset(16, 72), Size = UDim2.new(1, -150, 0, 20), Text = reward, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = hero })
	useBtn = Dock.button(hero, "USE")
	useBtn.Name = "Use"
	useBtn.Activated:Connect(function()
		if c and not used(c.Code) then
			box.Text = c.Code
			Codes.redeem(c.Code)
		end
	end)

	-- type one in
	local entry = Dock.row(page, 2, 56)
	box = UI.new("TextBox", {
		Name = "CodeBox",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.new(1, -144, 0, 38),
		Text = "",
		PlaceholderText = "Enter a code",
		PlaceholderColor3 = Color3.fromRGB(120, 116, 110),
		ClearTextOnFocus = false,
		Font = UI.Font.Bold,
		TextSize = 18,
		TextColor3 = UI.Color.Text,
		BackgroundColor3 = Color3.fromRGB(8, 8, 10),
		ZIndex = 43,
		Parent = entry,
	})
	UI.corner(box, 8)
	UI.stroke(box, Color3.new(1, 1, 1), 1, 0.8)
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = box })
	local go = Dock.button(entry, "REDEEM")
	go.Name = "Redeem"
	go.Activated:Connect(function()
		Codes.redeem(box.Text)
	end)
	pcall(function() -- (Enter on a keyboard; the harness has no FocusLost)
		box.FocusLost:Connect(function(enter)
			if enter then
				Codes.redeem(box.Text)
			end
		end)
	end)
	status = UI.label({ Name = "Status", LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 22), Text = "", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, Parent = page })

	-- the ask: a like (new codes come with them)
	local like = Dock.row(page, 4, 74)
	like.Name = "LikeAsk"
	UI.label({ Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 22), Text = "👍  LIKE THE GAME", Font = UI.Font.Bold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = like })
	local steps = {}
	for _, n in Cat.LikeMilestones do
		table.insert(steps, tostring(n))
	end
	UI.label({
		Position = UDim2.fromOffset(16, 34),
		Size = UDim2.new(1, -32, 0, 34),
		Text = "New codes come out at <b>" .. table.concat(steps, " · ") .. " likes</b>. Tap 👍 on the game's page, under PLAY.",
		TextSize = 13,
		TextColor3 = UI.Color.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 43,
		Parent = like,
	})

	-- the chip under the coins, top right, until the code's used
	if c then
		chip = UI.new("TextButton", {
			Name = "CodeChip",
			AnchorPoint = Vector2.new(1, 0),
			Position = Dock.UnderPill or UDim2.new(1, -14, 0, 116),
			Size = UDim2.fromOffset(176, 30),
			Text = "🎟️ USE CODE: <b>" .. c.Code .. "</b>",
			RichText = true,
			Font = UI.Font.Body,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(20, 16, 8),
			BackgroundColor3 = Dock.Gold,
			ZIndex = 30,
			Parent = UI.Root,
		})
		UI.corner(chip, 15)
		local s = UI.new("UIScale", { Parent = chip })
		chip.Activated:Connect(Codes.open)
		-- (a slow breath, so it's noticed without nagging)
		task.spawn(function()
			local t = 0
			while chip and chip.Parent do
				t += task.wait(1 / 15)
				if chip.Visible then
					s.Scale = 1 + 0.04 * math.sin(t * 2.4)
				end
			end
		end)
	end

	ctx.Remotes.EconomyResult.OnClientEvent:Connect(function(res)
		if type(res) ~= "table" or res.Kind ~= "Code" then
			return
		end
		waiting = false
		if res.Ok then
			say(string.format("✓ %s: +%d coins%s", tostring(res.Code), tonumber(res.Coins) or 0, res.Title and (" and the title " .. tostring(res.Title) .. " (it's on: LOCKER to change it)") or ""), true)
			box.Text = ""
			if ctx.Effects then
				ctx.Effects.playSound("UISelect", nil, { Caption = false })
			end
		else
			say(tostring(res.Text or "That code doesn't work."))
		end
		refresh()
	end)
	player:GetAttributeChangedSignal("Eco"):Connect(refresh)
	refresh()
end

return Codes
