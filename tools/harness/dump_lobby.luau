local H = require("./env")
local roblox = H.roblox
local ok, err = pcall(function()
	local S = H.services
	S.TeleportService = { ReserveServer = function() return "x" end, TeleportAsync = function() end, TeleportInitFailed = H.signal() }
	S.RunService.IsStudio = function() return false end
	S.Lighting = H.wrap(roblox.Instance.new("Lighting"))
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Util = H.load("RS/Shared/Util")
	ctx.Builder = H.load("Server/World/Builder")
	ctx.Mode = { gamePlaceId = function() return 123 end }
	ctx.Remotes = setmetatable({}, { __index = function(t, k) local r = { FireClient = function() end, OnServerEvent = H.signal() }; rawset(t, k, r); return r end })
	local Shop = H.load("Server/Services/ShopService"); Shop.init(ctx)
	local Lobby = H.load("Server/Lobby/LobbyServer")
	Lobby.run(ctx)
	local lobby = H.unwrap(H.workspaceRoot):FindFirstChild("Lobby")
	require("./dump")(lobby, "../render/lobby.json")
end)
print(ok and "LOBBY DUMP OK" or ("FAIL " .. tostring(err)))
for _, e in H.errors do print(e) end
