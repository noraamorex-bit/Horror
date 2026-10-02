--[[
	ShopService — game passes and donations (Config.Shop), in the lobby and in the house.

	Passes: who owns what is mirrored into player attributes ("Pass_<Key>" = true) that the rest of
	the game reads: Supporter (lobby tag, gold beam), Colours (every beam), Battery (half drain,
	PlayerStateService), PepperSpray (a can every night, PlayerStateService.assignRoles).

	Donations: developer products. Each receipt is recorded once (a DataStore key per purchase id)
	and added to the donor's total in an OrderedDataStore; the lobby's board (buildBoard) and the
	shop's Support tab show the top ten (workspace attribute "TopDonors", JSON).
	Everything is best-effort without DataStore access: purchases still go through.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local Shop = {}
local ctx

local receipts = nil -- DataStore: purchase id -> true (each donation counted once)
local totals = nil -- OrderedDataStore: "u<userId>" -> Robux donated
local names: { [number]: string } = {}
local boardRows: { TextLabel } = {}

local function passByKey(key: string)
	for _, p in ctx.Config.Shop.Passes do
		if p.Key == key then
			return p
		end
	end
	return nil
end

local function passById(id: number)
	for _, p in ctx.Config.Shop.Passes do
		if p.Id == id and id ~= 0 then
			return p
		end
	end
	return nil
end

local function donationById(id: number)
	for _, d in ctx.Config.Shop.Donations do
		if d.Id == id and id ~= 0 then
			return d
		end
	end
	return nil
end

function Shop.owns(player: Player, key: string): boolean
	return player:GetAttribute("Pass_" .. key) == true
end

---------------------------------------------------------------------------
-- The supporter tag (lobby only: in the house you're just a kid in the dark)
---------------------------------------------------------------------------
local function tag(player: Player)
	if workspace:GetAttribute("Mode") ~= "Lobby" or not Shop.owns(player, "Supporter") then
		return
	end
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head or head:FindFirstChild("SupporterTag") then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "SupporterTag"
	bb.Size = UDim2.fromOffset(140, 26)
	bb.StudsOffset = Vector3.new(0, 2.4, 0)
	bb.MaxDistance = 70
	bb.LightInfluence = 0
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextScaled = true
	l.Text = "★ SUPPORTER"
	l.TextColor3 = Color3.fromRGB(255, 214, 120)
	l.TextStrokeTransparency = 0.4
	l.Parent = bb
	bb.Parent = head
end

local function grant(player: Player, pass, fresh: boolean)
	if player:GetAttribute("Pass_" .. pass.Key) then
		return
	end
	player:SetAttribute("Pass_" .. pass.Key, true)
	if ctx.Stats and ctx.Stats.refresh then
		ctx.Stats.refresh(player)
	end
	tag(player)
	if fresh then
		ctx.Remotes.Notify:FireClient(player, "Thank you! " .. pass.Name .. " is yours.", "done")
	end
end

local function checkPasses(player: Player)
	for _, pass in ctx.Config.Shop.Passes do
		if pass.Id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
			end)
			if ok and owns and player.Parent then
				grant(player, pass, false)
			end
		end
	end
end

---------------------------------------------------------------------------
-- Donations
---------------------------------------------------------------------------
local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local p = Players:GetPlayerByUserId(userId)
	if p then
		names[userId] = p.DisplayName
		return p.DisplayName
	end
	local ok, n = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	names[userId] = ok and n or "Someone"
	return names[userId]
end

local function refreshTop()
	if not totals then
		return
	end
	local ok, page = pcall(function()
		return totals:GetSortedAsync(false, 10):GetCurrentPage()
	end)
	if not ok or type(page) ~= "table" then
		return
	end
	local top = {}
	for _, e in page do
		local id = tonumber(tostring(e.key):match("^u(%d+)$"))
		if id and (tonumber(e.value) or 0) > 0 then
			table.insert(top, { Name = nameOf(id), Amount = e.value, UserId = id })
		end
	end
	workspace:SetAttribute("TopDonors", HttpService:JSONEncode(top))
	for i, row in boardRows do
		local e = top[i]
		if e then
			local star = ""
			local p = Players:GetPlayerByUserId(e.UserId)
			if p and Shop.owns(p, "Supporter") then
				star = "★ "
			end
			row.Text = string.format("%d.  %s%s   ·   %d R$", i, star, e.Name, e.Amount)
		else
			row.Text = i == 1 and #top == 0 and "Be the first." or ""
		end
	end
end

local function onReceipt(info)
	local product = donationById(info.ProductId)
	if not product then
		-- not ours to grant (nothing else is sold yet): leave it for a server that knows it
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local already = false
	if receipts and totals then
		local key = tostring(info.PurchaseId)
		local ok = pcall(function()
			receipts:UpdateAsync(key, function(old)
				if old then
					already = true
					return nil
				end
				return true
			end)
		end)
		if not ok then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if not already then
			local okInc = pcall(function()
				totals:IncrementAsync("u" .. info.PlayerId, product.Amount)
			end)
			if not okInc then
				pcall(function()
					receipts:RemoveAsync(key)
				end)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
		end
	end
	if already then
		-- (a repeat of a receipt we've already counted and thanked them for)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- thank them, and let everyone see it
	local who = player and player.DisplayName or nameOf(info.PlayerId)
	if player then
		ctx.Remotes.Notify:FireClient(player, "Thank you so much for supporting the game!", "done")
	end
	for _, p in Players:GetPlayers() do
		if p ~= player then
			ctx.Remotes.Notify:FireClient(p, who .. " donated " .. product.Amount .. " Robux to the game!", "info")
		end
	end
	task.spawn(refreshTop)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

---------------------------------------------------------------------------
-- The board in the lobby (built by LobbyServer)
---------------------------------------------------------------------------
function Shop.buildBoard(parent: Instance, cf: CFrame)
	local B = ctx.Builder
	local model = Instance.new("Model")
	model.Name = "DonationBoard"
	model.Parent = parent
	local wood = Color3.fromRGB(44, 34, 28)
	for _, x in { -4.6, 4.6 } do
		B.part(model, { Name = "Post", Size = Vector3.new(0.6, 9, 0.6), CFrame = cf * CFrame.new(x, 4.5, 0.4), Color = wood, Material = Enum.Material.Wood })
	end
	local board = B.part(model, { Name = "Board", Size = Vector3.new(9.8, 7, 0.4), CFrame = cf * CFrame.new(0, 5.6, 0), Color = Color3.fromRGB(16, 16, 18), Material = Enum.Material.SmoothPlastic })
	B.part(model, { Name = "Trim", Size = Vector3.new(10.4, 0.35, 0.6), CFrame = cf * CFrame.new(0, 9.2, 0), Color = wood, Material = Enum.Material.Wood })
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Front
	light.Range = 10
	light.Brightness = 1.2
	light.Angle = 100
	light.Color = Color3.fromRGB(255, 230, 190)
	light.Parent = board

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 0.2
	gui.Parent = board
	local function line(y: number, h: number, text: string, font: Enum.Font, color: Color3): TextLabel
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0.06, y)
		l.Size = UDim2.fromScale(0.88, h)
		l.Font = font
		l.TextScaled = true
		l.Text = text
		l.TextColor3 = color
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Parent = gui
		return l
	end
	line(0.05, 0.1, "SUPPORT THE GAME", Enum.Font.GothamBlack, Color3.fromRGB(245, 242, 235)).TextXAlignment = Enum.TextXAlignment.Center
	line(0.16, 0.06, "Home Alone is made by one person. Every Robux helps.", Enum.Font.GothamMedium, Color3.fromRGB(170, 166, 158)).TextXAlignment = Enum.TextXAlignment.Center
	line(0.25, 0.055, "TOP SUPPORTERS", Enum.Font.GothamBold, Color3.fromRGB(255, 214, 120))
	boardRows = {}
	for i = 1, 10 do
		table.insert(boardRows, line(0.32 + (i - 1) * 0.058, 0.05, i == 1 and "Be the first." or "", Enum.Font.GothamMedium, Color3.fromRGB(232, 228, 218)))
	end
	line(0.91, 0.06, "Walk up and press DONATE", Enum.Font.GothamBold, Color3.fromRGB(170, 166, 158)).TextXAlignment = Enum.TextXAlignment.Center

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DonatePrompt"
	prompt.ActionText = "Donate"
	prompt.ObjectText = "Support the game"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = board
	-- (the client opens the shop on its Support tab when this triggers)
	task.spawn(refreshTop)
	return model
end

function Shop.init(c)
	ctx = c
	ctx.Shop = Shop
end

function Shop.start()
	pcall(function()
		receipts = DataStoreService:GetDataStore("DonationReceipts_v1")
		totals = DataStoreService:GetOrderedDataStore("Donations_v1")
	end)
	MarketplaceService.ProcessReceipt = onReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local pass = passById(passId)
		if purchased and pass then
			grant(player, pass, true)
		end
	end)
	local function added(player: Player)
		task.spawn(checkPasses, player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			tag(player)
		end)
	end
	for _, p in Players:GetPlayers() do
		added(p)
	end
	Players.PlayerAdded:Connect(added)
	-- the board refreshes now and then (another server may have taken a donation)
	if workspace:GetAttribute("Mode") == "Lobby" then
		task.spawn(function()
			while true do
				task.wait(90)
				refreshTop()
			end
		end)
	end
end

Shop._passByKey = passByKey -- (tests)

return Shop
