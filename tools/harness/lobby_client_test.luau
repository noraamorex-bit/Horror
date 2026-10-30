local H = require("./env")
local roblox = H.roblox
local touch = require("@lune/process").args[1] == "touch"
local ok, err = pcall(function()
	local S = H.services
	local player = H.wrap(roblox.Instance.new("Player"))
	player.Name = "Tester"
	local pg = H.wrap(roblox.Instance.new("PlayerGui"))
	pg.Parent = player
	S.Players.LocalPlayer = player
	S.Players.GetPlayers = function() return { player } end
	S.UserInputService = {
		TouchEnabled = touch, KeyboardEnabled = not touch, MouseBehavior = nil,
		LastInputTypeChanged = H.signal(), InputBegan = H.signal(), InputEnded = H.signal(), InputChanged = H.signal(),
		GetLastInputType = function() return touch and roblox.Enum.UserInputType.Touch or roblox.Enum.UserInputType.Keyboard end,
		GetMouseDelta = function() return roblox.Vector2.new() end,
	}
	S.GuiService = { GetGuiInset = function() return roblox.Vector2.new(0, 36), roblox.Vector2.new() end }
	S.ProximityPromptService = { PromptShown = H.signal(), PromptTriggered = H.signal(), Enabled = true }
	S.MarketplaceService = S.MarketplaceService or { PromptGamePassPurchaseFinished = H.signal(), PromptProductPurchaseFinished = H.signal(), PromptGamePassPurchase = function() end, PromptProductPurchase = function() end }
	S.SoundService = H.wrap(roblox.Instance.new("SoundService"))
	S.Lighting = H.wrap(roblox.Instance.new("Lighting"))
	S.StarterGui = { SetCoreGuiEnabled = function() end, SetCore = function() end }
	S.RunService.IsServer = function() return false end
	-- (v123) Roblox's feedback window, opened from the lobby's mailbox
	local feedbackAsked = 0
	S.SocialService = setmetatable({ PromptFeedbackSubmissionAsync = function() feedbackAsked += 1 end }, { __index = function() return function() return nil end end })

	local ctx: any = { Player = player, Mode = "Lobby" }
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Rooms = H.load("RS/Shared/Rooms")
	ctx.Sounds = H.load("RS/Shared/Sounds")
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Util = H.load("RS/Shared/Util")
	local sent = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { OnClientEvent = H.signal(), FireServer = function(_, ...) table.insert(sent, k) end }
		rawset(t, k, r)
		return r
	end })
	-- (the client's lobby list, init.client.luau; the owner's panel too)
	local ORDER = { "UI", "Input", "Notice", "Social", "Effects", "Settings", "Atmosphere", "Dock", "Shop", "Starter", "Store", "Locker", "Rewards", "Prank", "LobbyHub", "Admin" }
	player:SetAttribute("IsAdmin", true)
	player:SetAttribute("Coins", 1234)
	player:SetAttribute("Candy", 7)
	S.TeleportService = { SetTeleportGui = function() end }
	-- (v98: the Starter Pack row, once the product exists and while it's on offer)
	local starterId = ctx.Config.Shop.Starter.Id
	ctx.Config.Shop.Starter.Id = 4242
	player:SetAttribute("StarterOffer", true)
	local serde = require("@lune/serde")
	H.services.HttpService = { JSONEncode = function(_, v) return serde.encode("json", v) end, JSONDecode = function(_, v) return serde.decode("json", v) end }
	local mods = {}
	for _, n in ORDER do mods[n] = H.load("Client/Controllers/" .. n) end
	for _, n in ORDER do if mods[n].init then mods[n].init(ctx) end end
	for _, n in ORDER do
		if mods[n].start then
			local ok2, e2 = pcall(mods[n].start)
			if not ok2 then error(n .. ".start: " .. tostring(e2)) end
		end
	end
	print("lobby controllers started")
	ctx.Remotes.Queue.OnClientEvent:Fire({ Size = 2, Count = 1, Status = "Waiting" })
	ctx.Remotes.Queue.OnClientEvent:Fire({ Size = 2, Count = 2, Status = "Starting", Countdown = 4 })
	ctx.Remotes.Queue.OnClientEvent:Fire(nil)
	print("remotes sent:", table.concat(sent, ","))
	-- the owner's panel in the lobby: a COINS tab only, and its buttons ask the server
	local panel = H.unwrap(pg):FindFirstChild("AdminPanel", true)
	assert(panel, "admin panel built in the lobby")
	local pill = H.unwrap(pg):FindFirstChild("AdminPill", true)
	assert(pill, "admin pill")
	-- Halloween: the event line under PLAY, with your candy and the next reward
	local Cat = H.load("RS/Shared/Economy")
	local hl = H.unwrap(pg):FindFirstChild("HalloweenLine", true)
	assert(hl, "the Halloween line")
	if Cat.halloweenLive(os.time()) then
		assert(hl.Visible and string.find(hl.Text, "7", 1, true) and string.find(hl.Text, "Candy Corn (15)", 1, true), "candy and the next reward: " .. hl.Text)
	end
	local row = H.unwrap(pg):FindFirstChild("StarterRow", true)
	assert(row and row.Visible, "the Starter Pack at the top of the shop")
	-- (v120) and in the dock, and its window by itself when someone who's played steps into a circle
	-- (v121) an INVITE icon in the dock too (a friend who joins pays you both)
	assert(H.unwrap(pg):FindFirstChild("InviteDock", true), "an INVITE icon in the dock")
	assert(ctx.Social.inviteData() == "ref:" .. tostring(player.UserId), "a lobby invite says who sent it")
	local dockIcon = H.unwrap(pg):FindFirstChild("StarterDock", true)
	assert(dockIcon and dockIcon.Visible, "a STARTER icon in the dock")
	ctx.Starter._reset()
	local before = 0
	for _, k in sent do if k == "StarterAuto" then before += 1 end end
	player:SetAttribute("StatNights", 0)
	ctx.Remotes.Queue.OnClientEvent:Fire({ Size = 2, Count = 1, Status = "Waiting" })
	local after = 0
	for _, k in sent do if k == "StarterAuto" then after += 1 end end
	assert(after == before, "a first-timer isn't asked (the first night comes first)")
	player:SetAttribute("StatNights", 2)
	ctx.Remotes.Queue.OnClientEvent:Fire({ Size = 2, Count = 1, Status = "Waiting" })
	after = 0
	for _, k in sent do if k == "StarterAuto" then after += 1 end end
	assert(after == before, "(v124) no window by itself in the lobby any more (0 of 197 sold)")
	player:SetAttribute("StarterOffer", nil)
	ctx.Starter._refresh()
	assert(not dockIcon.Visible, "bought: the icon goes")
	player:SetAttribute("StarterOffer", true)
	player:SetAttribute("StatNights", nil)
	ctx.Config.Shop.Starter.Id = starterId
	-- (v118) a returning player: the welcome-back card with what tonight is worth, and one tap to play
	player:SetAttribute("StatNights", 3)
	player:SetAttribute("StatEscapes", 1)
	player:SetAttribute("ChainUntil", os.time() + 400)
	player:SetAttribute("ChainNext", 25)
	player:SetAttribute("Eco", '{"Daily":{"CanClaim":true},"Quests":[{"Text":"Survive a night","Progress":0,"Goal":1,"Coins":60,"Done":false},{"Text":"Hide 5 times","Progress":5,"Goal":5,"Coins":40,"Done":true}]}')
	local lines = mods.LobbyHub._backLines(player)
	local all = table.concat(lines, "\n")
	assert(string.find(all, "+25%", 1, true) and string.find(all, "DAILY REWARD", 1, true) and string.find(all, "Survive a night", 1, true)
		and not string.find(all, "Hide 5 times", 1, true) and string.find(all, "NIGHTMARE", 1, true), "the card's lines: " .. all)
	local card = mods.LobbyHub.welcomeBack()
	assert(card and card.Parent and card:FindFirstChild("Play"), "the card, with PLAY")
	local before = #sent
	H.wrap(H.unwrap(card):FindFirstChild("Play")).Activated:Fire()
	assert(sent[#sent] == "QuickPlay" and not card.Parent, "PLAY: into a circle, card gone")
	print("welcome back ok")
	-- (v119, the owner: "dont offer become him in lobby")
	for _, d in H.unwrap(pg):GetDescendants() do
		assert(not (d:IsA("TextLabel") and d.Text == "BE HIM"), "no BE HIM in the lobby")
	end
	assert(H.unwrap(pg):FindFirstChildWhichIsA("UIGridLayout", true), "the dock wraps into a second column")
	-- (v124) a friend's house: a small JOIN card at the top; JOIN asks the server, the card goes
	local fc0 = H.unwrap(pg):FindFirstChild("FriendHouse", true)
	assert(not fc0 or not fc0.Visible, "no card without a friend's house")
	player:SetAttribute("FriendHouse", "Sam")
	ctx.Social._friendHouse()
	local fcard = H.unwrap(pg):FindFirstChild("FriendHouse", true)
	assert(fcard and fcard.Visible and string.find(fcard:FindFirstChild("Text").Text, "Sam"), "the card names the friend")
	local nsent = #sent
	H.wrap(fcard:FindFirstChild("Join")).Activated:Fire()
	assert(sent[#sent] == "JoinFriend" and #sent == nsent + 1 and not fcard.Visible, "JOIN: the server takes them there")
	player:SetAttribute("FriendHouse", nil)
	ctx.Social._friendHouse()
	assert(not fcard.Visible, "gone with the house")
	-- (v123) the feedback mailbox's prompt opens Roblox's feedback window; other prompts don't
	S.ProximityPromptService.PromptTriggered:Fire({ Name = "DonatePrompt" })
	S.ProximityPromptService.PromptTriggered:Fire({ Name = "FeedbackPrompt" })
	H.task.wait(0.05)
	assert(feedbackAsked == 1, "the mailbox opens the feedback window once, got " .. feedbackAsked)
	-- count UI objects
	local n = 0
	for _ in H.unwrap(pg):GetDescendants() do n += 1 end
	print("gui objects", n)
end)
print(ok and "CLIENT OK" or ("CLIENT FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
