--[[
	Starter — the one-time Starter Pack (Config.Shop.Starter: 500 coins + a rocket + a revive), out where
	people see it while it's on offer (the player attribute StarterOffer; v120, the owner: "put the starter
	pack on the side and prompt them to buy it"):
	• on the side: a 🎁 STARTER icon in the lobby's dock; in the house a small button in the left column
	  before the hunt (during the hunt that column is the rocket's and the night vision's)
	• its purchase window also opens by itself, at most once a visit, on the result card when a night is
	  over for you (not with a revive on offer: that window comes first). (v124: the lobby's window, as you
	  stepped into a circle, went: 0 bought of 197 auto windows in v120-122)
	• never under a finger: it waits until nothing has been pressed for a moment and gives up if that
	  doesn't come, so a tap meant for the game can't land on Buy (Roblox treats tricking people into a
	  purchase as a scam). The server logs these windows as Ask:StarterAuto (ShopService).
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

local Starter = {}
local ctx
local player = Players.LocalPlayer

Starter.IdleFor = 1.2 -- nothing pressed for this long before the window opens by itself
Starter.WaitMax = 8 -- (and if that never happens, it doesn't open)

local button: GuiButton? = nil
local asked = false -- (it opens by itself once a visit)
local held = 0 -- fingers / mouse buttons down right now
local lastInput = -math.huge

local HUNT = { SomeoneElse = true, Guest = true }

local function product(): any
	local st = ctx.Config.Shop.Starter
	return (st and st.Id > 0) and st or nil
end

function Starter.onOffer(): boolean
	return product() ~= nil and player:GetAttribute("StarterOffer") == true
end

local function prompt()
	local st = product()
	if st then
		pcall(function()
			MarketplaceService:PromptProductPurchase(player, st.Id)
		end)
	end
end

-- nobody's touching or clicking anything right now, and hasn't for a moment
function Starter.idle(now: number?): boolean
	return held <= 0 and (now or os.clock()) - lastInput >= Starter.IdleFor
end

local function refresh()
	if not button then
		return
	end
	if ctx.Mode == "Lobby" then
		button.Visible = Starter.onOffer()
		return
	end
	local canAct = player:GetAttribute("InGame") == true and not player:GetAttribute("Captured") and not player:GetAttribute("Dead")
		and not player:GetAttribute("Escaped") and not player:GetAttribute("Monster")
	button.Visible = Starter.onOffer() and canAct and not HUNT[workspace:GetAttribute("Act") or ""] and not workspace:GetAttribute("EndingActive")
end
Starter._refresh = refresh -- (tests)

--[[
	Open the window by itself (where: "Lobby" | "Card"), once a visit, when nobody's pressing anything.
	Returns whether it went ahead (tests: now = a fake clock, and it doesn't wait).
]]
function Starter.auto(where: string, now: number?): boolean
	if asked or not Starter.onOffer() then
		return false
	end
	if now ~= nil then
		if not Starter.idle(now) then
			return false
		end
	else
		local t0 = os.clock()
		while not Starter.idle() do
			if os.clock() - t0 > Starter.WaitMax then
				return false
			end
			task.wait(0.2)
		end
		if asked or not Starter.onOffer() then
			return false
		end
	end
	asked = true
	ctx.Remotes.StarterAuto:FireServer(where)
	prompt()
	return true
end

function Starter._reset() -- (tests)
	asked = false
	held = 0
	lastInput = -math.huge
end

function Starter.init(c)
	ctx = c
	ctx.Starter = Starter
end

function Starter.start()
	local UI = ctx.UI
	local function press(input: InputObject): boolean
		local t = input.UserInputType
		return t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2
	end
	UserInputService.InputBegan:Connect(function(input)
		lastInput = os.clock()
		if press(input) then
			held += 1
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		lastInput = os.clock()
		if press(input) then
			held = math.max(0, held - 1)
		end
	end)

	if ctx.Mode == "Lobby" then
		if ctx.Dock then
			local b, badge = ctx.Dock.add({ Order = 0, Glyph = "⭐", Label = "STARTER", Color = Color3.fromRGB(255, 205, 90), OnClick = prompt })
			b.Name = "StarterDock"
			badge.Visible = true
			button = b
		end
		-- (v124: no window by itself in the lobby any more: 0 bought of 197 auto windows, lobby and card
		-- together, v120-122; it opens by itself only on the result card now)
	else
		local st = ctx.Config.Shop.Starter
		local b = UI.new("TextButton", {
			Name = "StarterSide",
			Size = UDim2.fromOffset(190, 30),
			Text = "🎁 STARTER PACK  R$ " .. tostring(st and st.Price or 19),
			Font = UI.Font.Bold,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(16, 14, 10),
			BackgroundColor3 = Color3.fromRGB(255, 205, 90),
			BackgroundTransparency = 0.1,
			AutoButtonColor = true,
			LayoutOrder = 10,
			Visible = false,
			Parent = ctx.HUD and ctx.HUD.LeftColumn or UI.Root,
		})
		UI.corner(b, 8)
		b.Activated:Connect(prompt)
		button = b
		for _, a in { "InGame", "Captured", "Dead", "Escaped", "Monster" } do
			player:GetAttributeChangedSignal(a):Connect(refresh)
		end
		workspace:GetAttributeChangedSignal("Act"):Connect(refresh)
		workspace:GetAttributeChangedSignal("EndingActive"):Connect(refresh)
	end
	player:GetAttributeChangedSignal("StarterOffer"):Connect(refresh)
	refresh()
end

return Starter
