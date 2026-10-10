--[[
	Rewards — the daily reward (a 7-day streak: miss a day and it starts over) and today's three
	quests (dock icon REWARDS, with a dot when the daily reward is waiting). Opens on its own the
	first time you come back to the lobby with a reward to claim.
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rewards = {}
local ctx
local Cat
local player = Players.LocalPlayer
local P
local badge: Frame
local tiles = {}
local claim: TextButton
local claimNote: TextLabel
local questRows = {}
local autoOpened = false

local function eco(): any
	local ok, t = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute("Eco") or "{}")
	end)
	return ok and type(t) == "table" and t or {}
end

local function hms(s: number): string
	s = math.max(0, math.floor(s))
	return string.format("%dh %02dm", s // 3600, (s % 3600) // 60)
end

local function refresh()
	local e = eco()
	local d = type(e.Daily) == "table" and e.Daily or {}
	local can = d.CanClaim == true
	badge.Visible = can
	local nextDay = tonumber(d.Next) or 1
	local streak = tonumber(d.Streak) or 0
	for i, t in tiles do
		local done = (not can and i <= streak) or (can and i < nextDay)
		local today = can and i == nextDay
		t.Frame.BackgroundColor3 = today and ctx.Dock.Gold or (done and Color3.fromRGB(46, 70, 52) or Color3.fromRGB(26, 26, 30))
		t.Day.TextColor3 = today and Color3.fromRGB(14, 14, 16) or ctx.UI.Color.Dim
		t.Amount.TextColor3 = today and Color3.fromRGB(14, 14, 16) or (done and Color3.fromRGB(150, 230, 160) or ctx.UI.Color.Text)
		t.Amount.Text = (done and "✓ " or "") .. tostring(Cat.Daily[i]) .. (i == Cat.DailyCrateDay and " +📦" or "")
	end
	claim.Visible = can
	claimNote.Text = can and ("Day " .. nextDay .. " of 7. Come back tomorrow for day " .. (nextDay % 7 + 1) .. ".")
		or ("Claimed. Next reward in " .. hms((Cat.day() + 1) * 86400 - os.time()) .. ". Don't break your streak!")
	-- quests
	local quests = type(e.Quests) == "table" and e.Quests or {}
	for i, r in questRows do
		local q = quests[i]
		r.Row.Visible = q ~= nil
		if q then
			r.Text.Text = tostring(q.Text)
			local p, g = tonumber(q.Progress) or 0, math.max(1, tonumber(q.Goal) or 1)
			r.Fill.Size = UDim2.new(math.clamp(p / g, 0, 1), 0, 1, 0)
			r.Fill.BackgroundColor3 = q.Done and Color3.fromRGB(120, 230, 150) or ctx.Dock.Gold
			r.Count.Text = q.Done and "DONE ✓" or (p .. " / " .. g)
			r.Reward.Text = "+" .. tostring(q.Coins)
			r.Reward.TextTransparency = q.Done and 0.5 or 0
		end
	end
end

function Rewards.open()
	if P then
		P.open()
	end
end

function Rewards.init(c)
	ctx = c
	ctx.RewardsUI = Rewards
	Cat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Economy"))
end

function Rewards.start()
	if ctx.Mode ~= "Lobby" then
		return
	end
	local UI = ctx.UI
	local Dock = ctx.Dock
	P = Dock.panel("REWARDS")
	P.OnOpen = refresh
	local _
	_, badge = Dock.add({ Order = 2, Glyph = "🎁", Label = "REWARDS", Color = Color3.fromRGB(255, 140, 120), OnClick = function()
		P.toggle()
	end })
	local page = P.Pages.Main
	UI.label({ LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 22), Text = "DAILY REWARD", Font = UI.Font.Bold, TextSize = 16, TextColor3 = Dock.Gold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, Parent = page })
	local strip = UI.new("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1, ZIndex = 42, Parent = page })
	UI.new("UIGridLayout", { CellSize = UDim2.new(1 / 7, -6, 1, 0), CellPadding = UDim2.fromOffset(6, 0), SortOrder = Enum.SortOrder.LayoutOrder, Parent = strip })
	for i = 1, 7 do
		local f = UI.new("Frame", { LayoutOrder = i, BackgroundColor3 = Color3.fromRGB(26, 26, 30), ZIndex = 43, Parent = strip })
		UI.corner(f, 8)
		local day = UI.label({ Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 16), Text = "DAY " .. i, Font = UI.Font.Bold, TextSize = 11, ZIndex = 44, Parent = f })
		local amount = UI.label({ Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 30), Text = "", Font = UI.Font.Bold, TextSize = 15, ZIndex = 44, Parent = f })
		tiles[i] = { Frame = f, Day = day, Amount = amount }
	end
	local claimRow = UI.new("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, ZIndex = 42, Parent = page })
	claim = Dock.button(claimRow, "CLAIM", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(140, 42) })
	claimNote = UI.label({ Position = UDim2.fromOffset(152, 0), Size = UDim2.new(1, -152, 1, 0), Text = "", TextSize = 13, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = claimRow })
	claim.Activated:Connect(function()
		ctx.Remotes.Economy:FireServer("Daily")
	end)
	UI.label({ LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 30), Text = "TODAY'S QUESTS", Font = UI.Font.Bold, TextSize = 16, TextColor3 = Dock.Gold, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Bottom, ZIndex = 42, Parent = page })
	for i = 1, Cat.QuestsPerDay do
		local row = Dock.row(page, 4 + i, 56)
		local text = UI.label({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -110, 0, 22), Text = "", Font = UI.Font.Bold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = row })
		local bar = UI.new("Frame", { Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -110, 0, 10), BackgroundColor3 = Color3.fromRGB(50, 50, 56), ZIndex = 43, Parent = row })
		UI.corner(bar, 5)
		local fill = UI.new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Dock.Gold, ZIndex = 44, Parent = bar })
		UI.corner(fill, 5)
		local count = UI.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(86, 20), Text = "", Font = UI.Font.Bold, TextSize = 12, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 43, Parent = row })
		local rewardBox = UI.new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 28), Size = UDim2.fromOffset(86, 22), BackgroundTransparency = 1, ZIndex = 43, Parent = row })
		Dock.coin(rewardBox, 16, 44).Position = UDim2.fromOffset(20, 3)
		local reward = UI.label({ Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -40, 1, 0), Text = "", Font = UI.Font.Bold, TextSize = 14, TextColor3 = Dock.Gold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44, Parent = rewardBox })
		questRows[i] = { Row = row, Text = text, Fill = fill, Count = count, Reward = reward }
	end
	UI.label({ LayoutOrder = 20, Size = UDim2.new(1, 0, 0, 34), Text = "New quests every day. Coins are paid the moment a quest is done.", TextSize = 12, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, Parent = page })

	ctx.Remotes.EconomyResult.OnClientEvent:Connect(function(res)
		if type(res) == "table" and res.Kind == "Daily" and ctx.ShopUI and ctx.ShopUI.toast then
			ctx.ShopUI.toast("Day " .. tostring(res.Streak) .. " reward: +" .. tostring(res.Coins) .. " coins!")
		end
	end)
	player:GetAttributeChangedSignal("Eco"):Connect(function()
		refresh()
		-- back in the lobby with a reward waiting: show it (once a visit)
		local d = eco().Daily
		if not autoOpened and type(d) == "table" and d.CanClaim and (tonumber(player:GetAttribute("StatNights")) or 0) > 0 then
			autoOpened = true
			task.delay(2.5, function()
				if not P.Frame.Visible then
					P.open()
				end
			end)
		end
	end)
	if player:GetAttribute("Eco") then
		refresh()
	end
	-- the countdown ticks while it's open
	task.spawn(function()
		while true do
			task.wait(30)
			if P.Frame.Visible then
				refresh()
			end
		end
	end)
end

return Rewards
