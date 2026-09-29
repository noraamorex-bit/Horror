--[[
	Mode — is this server the lobby or a night in the house?

	Players who press Play land in a normal (public) server: that's the Lobby. Queue circles
	teleport a group into a reserved server of the game place: that's the Game.
	Studio can't teleport, so Studio runs the Game directly (set Config.ForceMode to test the lobby).
]]

local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)

local Mode = {}

-- a reserved server (created by TeleportService:ReserveServer), not a VIP/private server
function Mode.isReserved(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

function Mode.get(): string
	if Config.ForceMode then
		return Config.ForceMode
	end
	if RunService:IsStudio() then
		return "Game"
	end
	if Config.Lobby.GamePlaceId and game.PlaceId == Config.Lobby.GamePlaceId then
		return "Game"
	end
	return Mode.isReserved() and "Game" or "Lobby"
end

-- where queued groups are sent, and where finished groups go back to
function Mode.gamePlaceId(): number
	return Config.Lobby.GamePlaceId or game.PlaceId
end

function Mode.lobbyPlaceId(): number
	return Config.Lobby.LobbyPlaceId or game.PlaceId
end

return Mode
