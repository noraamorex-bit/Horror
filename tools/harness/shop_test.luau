-- ShopService: passes granted (and what they unlock), donations counted once, the lobby board
local H = require("./env")
local ok, err = pcall(function()
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Builder = H.load("Server/World/Builder")
	-- passes 101..104, donation products 201..205
	local PID, DID = {}, {}
	for i, p in ctx.Config.Shop.Passes do p.Id = 100 + i; PID[p.Key] = p.Id end
	for i, d in ctx.Config.Shop.Donations do d.Id = 200 + i; DID[d.Amount] = d.Id end
	local notes = {}
	local scares = {}
	local setBeam
	ctx.Remotes = setmetatable({}, { __index = function(_, k)
		return {
			FireClient = function(_, p, text) if k == "Notify" then table.insert(notes, p.Name .. ": " .. tostring(text)) end end,
			FireAllClients = function(_, ...) if k == "JumpscareAll" then table.insert(scares, { ... }) end end,
			OnServerEvent = { Connect = function(_, fn) if k == "SetBeam" then setBeam = fn end end },
		}
	end })
	-- fake marketplace + datastores
	local finished = H.signal()
	local productFinished = H.signal()
	local MS = { PromptGamePassPurchaseFinished = finished, PromptProductPurchaseFinished = productFinished, UserOwnsGamePassAsync = function(_, uid, id) return uid == 1 and id == PID.Battery end }
	H.services.MarketplaceService = MS
	local serde = require("@lune/serde")
	H.services.HttpService = { JSONEncode = function(_, v) return serde.encode("json", v) end, JSONDecode = function(_, v) return serde.decode("json", v) end }
	local kv, ordered = {}, {}
	H.services.DataStoreService = {
		GetDataStore = function(_, name)
			kv[name] = kv[name] or {}
			local t = kv[name]
			return {
				GetAsync = function(_, k) return t[k] end,
				SetAsync = function(_, k, v) t[k] = v end,
				RemoveAsync = function(_, k) t[k] = nil end,
				UpdateAsync = function(_, k, fn) local v = fn(t[k]); if v ~= nil then t[k] = v end; return t[k] end,
			}
		end,
		GetOrderedDataStore = function(_, name)
			ordered[name] = ordered[name] or {}
			local t = ordered[name]
			return {
				IncrementAsync = function(_, k, n) t[k] = (t[k] or 0) + n; return t[k] end,
				UpdateAsync = function(_, k, fn) local v = fn(t[k]); if v ~= nil then t[k] = v end; return t[k] end,
				GetSortedAsync = function()
					local list = {}
					for k, v in t do table.insert(list, { key = k, value = v }) end
					table.sort(list, function(a, b) return a.value > b.value end)
					return { GetCurrentPage = function() return list end }
				end,
			}
		end,
	}
	local roblox = H.roblox
	local a = H.wrap(roblox.Instance.new("Player")); a.Name = "Alex"; rawset(a, "UserId", 1); rawset(a, "DisplayName", "Alex")
	local b = H.wrap(roblox.Instance.new("Player")); b.Name = "Bo"; rawset(b, "UserId", 2); rawset(b, "DisplayName", "Bo")
	for _, p in { a, b } do
		rawset(p, "GetJoinData", function() return {} end)
		rawset(p, "IsFriendsWithAsync", function() return false end)
		rawset(p, "CharacterAdded", H.signal())
		rawset(p, "Parent", H.workspaceRoot)
	end
	local list = { a, b }
	H.services.Players.GetPlayers = function() return list end
	H.services.Players.GetPlayerByUserId = function(_, id) for _, p in list do if p.UserId == id then return p end end return nil end
	H.workspaceRoot:SetAttribute("Mode", "Lobby")
	local Stats = H.load("Server/Services/StatsService")
	Stats.init(ctx); Stats.start()
	local Shop = H.load("Server/Services/ShopService")
	Shop.init(ctx); Shop.start()
	H.task.wait(0.1)
	print("Alex owns battery on join:", a:GetAttribute("Pass_Battery"), "Bo:", b:GetAttribute("Pass_Battery"))
	assert(a:GetAttribute("Pass_Battery") == true and b:GetAttribute("Pass_Battery") == nil)

	-- Ghost is locked until the colours pass
	setBeam(b, "Ghost"); print("Bo ghost before pass ->", b:GetAttribute("StatBeam"))
	assert(b:GetAttribute("StatBeam") ~= "Ghost")
	finished:Fire(b, PID.Colours, true)
	print("Bo bought colours:", b:GetAttribute("Pass_Colours"))
	setBeam(b, "Ghost"); print("Bo ghost after pass ->", b:GetAttribute("StatBeam"))
	assert(b:GetAttribute("StatBeam") == "Ghost")
	setBeam(b, "Blood"); print("Bo blood moon (colours pass) ->", b:GetAttribute("StatBeam"))
	assert(b:GetAttribute("StatBeam") == "Blood")
	setBeam(b, "Gold"); print("Bo gold with only the colours pass (expect Blood) ->", b:GetAttribute("StatBeam"))
	assert(b:GetAttribute("StatBeam") == "Blood")
	finished:Fire(b, PID.Supporter, false)
	print("cancelled supporter purchase not granted:", b:GetAttribute("Pass_Supporter"))
	assert(b:GetAttribute("Pass_Supporter") == nil)

	-- the board
	local root = H.Instance.new("Folder")
	Shop.buildBoard(root, roblox.CFrame.new(0, 0, 0))
	H.task.wait(0.1)
	-- donations: the same receipt twice counts once; unknown products are left alone
	local MSr = H.services.MarketplaceService
	local r1 = MSr.ProcessReceipt({ ProductId = DID[100], PlayerId = 2, PurchaseId = "p1" })
	local r2 = MSr.ProcessReceipt({ ProductId = DID[100], PlayerId = 2, PurchaseId = "p1" })
	local r3 = MSr.ProcessReceipt({ ProductId = DID[1000], PlayerId = 1, PurchaseId = "p2" })
	local r4 = MSr.ProcessReceipt({ ProductId = 999, PlayerId = 1, PurchaseId = "p3" })
	print("receipts:", r1, r2, r3, r4)
	local thanks = 0
	for _, n in notes do if n:find("Bo: Thank you so much") then thanks += 1 end end
	print("Bo thanked", thanks, "time(s)")
	assert(thanks == 1)
	print("totals Bo", ordered.Donations_v1.u2, "Alex", ordered.Donations_v1.u1)
	assert(ordered.Donations_v1.u2 == 100 and ordered.Donations_v1.u1 == 1000)
	assert(tostring(r4):find("NotProcessedYet"))
	H.task.wait(0.1)
	print("top donors:", H.workspaceRoot:GetAttribute("TopDonors"))
	local board = root:FindFirstChild("DonationBoard", true)
	print("board built:", board ~= nil, "prompt:", board and board:FindFirstChild("DonatePrompt", true) ~= nil)
	-- stats save keeps invites and the beam
	print("saved:", kv.PlayerStats_v1 and kv.PlayerStats_v1.u2 and kv.PlayerStats_v1.u2.Beam)
	assert(H.workspaceRoot:GetAttribute("TopDonors") ~= nil)
	-- every sale is counted per UTC day (Sales_v1), passes at their price, products at what was spent
	local day = kv.Sales_v1 and kv.Sales_v1[os.date("!%Y%m%d")]
	print("sales today:", day and day.Colours and day.Colours[1], day and day.Donate100 and day.Donate100[1])
	local colours = 0
	for _, p in ctx.Config.Shop.Passes do if p.Key == "Colours" then colours = p.Price end end
	assert(day and day.Colours and day.Colours[1] == 1 and day.Colours[2] == colours, "a pass sale is logged at its price")
	assert(day.Donate100 and day.Donate100[1] == 1, "a donation is logged once (the repeat receipt isn't)")
	assert(day.Supporter == nil, "a cancelled purchase isn't")
	-- "Rocket (tonight)" bought in the lobby: saved, it comes with the next night
	local RID = ctx.Config.Shop.RocketNight.Id
	local r5 = MSr.ProcessReceipt({ ProductId = RID, PlayerId = 2, PurchaseId = "p5", CurrencySpent = 25 })
	print("rocket in the lobby:", r5, "credits", b:GetAttribute("RocketCredits"))
	assert(tostring(r5):find("PurchaseGranted") and b:GetAttribute("RocketCredits") == 1, "saved for the next night")
	assert(kv.Sales_v1[os.date("!%Y%m%d")].RocketNight[2] == 25, "and logged with its price")
	assert(Stats.spendRocketCredits(b) == 1 and Stats.spendRocketCredits(b) == 0, "used once, all at once")
	-- v98: the funnel: every purchase window that closes counts as asked, bought or not
	local today = kv.Sales_v1[os.date("!%Y%m%d")]
	assert(today["Ask:Colours"] and today["Ask:Colours"][1] == 1, "a pass window that sold")
	assert(today["Ask:Supporter"] and today["Ask:Supporter"][1] == 1 and today["Ask:Supporter"][2] == 0, "a pass window closed without buying")
	productFinished:Fire(2, RID, false)
	productFinished:Fire(2, ctx.Config.Shop.Revive.Id, true)
	assert(today["Ask:RocketNight"][1] == 1 and today["Ask:Revive"][1] == 1, "product windows")
	assert(today.RocketNight[1] == 1, "asking isn't selling")
	print("funnel ok")
	-- (v115) JUMPSCARE EVERYONE: everyone else in the server is scared at once, named, and it's logged
	local JID = ctx.Config.Shop.JumpscareAll.Id
	assert(JID > 0 and ctx.Config.Shop.JumpscareAll.Price == 10, "the product exists, at 10 R$")
	local r6 = MSr.ProcessReceipt({ ProductId = JID, PlayerId = 1, PurchaseId = "p6", CurrencySpent = 10 })
	assert(tostring(r6):find("PurchaseGranted"), "granted")
	assert(#scares == 1 and scares[1][1] == "Alex" and scares[1][2] == 1 and scares[1][3] == 1, "everyone told who did it, and how many were scared")
	assert(today.JumpscareAll and today.JumpscareAll[1] == 1 and today.JumpscareAll[2] == 10, "logged with its price")
	print("jumpscare everyone ok")
	-- the rocket launcher pass, bought: the pass is theirs
	finished:Fire(a, PID.Rocket, true)
	assert(a:GetAttribute("Pass_Rocket") == true, "rocket launcher granted")
	-- VIP brings pick-your-role with it now
	finished:Fire(a, PID.VIP, true)
	assert(a:GetAttribute("Pass_ChooseRole") == true, "VIP includes picking your role")
	for _, n in notes do print("  note", n) end
end)
print(ok and "SHOP OK" or ("SHOP FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
