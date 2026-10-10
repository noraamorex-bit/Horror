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
	local ORDER = { "UI", "Input", "Notice", "Social", "Effects", "Settings", "Atmosphere", "Dock", "Shop", "Store", "Locker", "Rewards", "LobbyHub", "Admin" }
	player:SetAttribute("IsAdmin", true)
	player:SetAttribute("Coins", 1234)
	S.TeleportService = { SetTeleportGui = function() end }
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
	-- count UI objects
	local n = 0
	for _ in H.unwrap(pg):GetDescendants() do n += 1 end
	print("gui objects", n)
end)
print(ok and "CLIENT OK" or ("CLIENT FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
