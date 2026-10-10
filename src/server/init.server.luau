--[[
	Server bootstrap — builds the context, wires every service, builds the house,
	then starts everything. Services never require each other; they use ctx.
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Services = script:WaitForChild("Services")

local ctx: any = {}
ctx.Config = require(Shared.Config)
ctx.Remotes = require(Shared.Remotes)
ctx.Rooms = require(Shared.Rooms)
ctx.Sounds = require(Shared.Sounds)
ctx.Story = require(Shared.Story)
ctx.Util = require(Shared.Util)
ctx.Builder = require(script.World.Builder)
ctx.Layout = require(script.World.Layout)
ctx.Mode = require(Shared.Mode)

-- Atmosphere: a wet, dark November night
local function setupLighting()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	-- thick fog: the street and the neighbors' lights fade out into it
	atmosphere.Density = 0.52
	atmosphere.Offset = 0.18
	atmosphere.Color = Color3.fromRGB(86, 94, 110)
	atmosphere.Decay = Color3.fromRGB(46, 52, 64)
	atmosphere.Glare = 0
	atmosphere.Haze = 2.6
	atmosphere.Parent = Lighting
	local cc = Lighting:FindFirstChild("Grade") or Instance.new("ColorCorrectionEffect")
	cc.Name = "Grade";
	(cc :: ColorCorrectionEffect).Saturation = -0.25;
	(cc :: ColorCorrectionEffect).Contrast = 0.08;
	(cc :: ColorCorrectionEffect).TintColor = Color3.fromRGB(235, 240, 255)
	cc.Parent = Lighting
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.4
	bloom.Size = 20
	bloom.Threshold = 1.4
	bloom.Parent = Lighting
	local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
	sky.StarCount = 0
	sky.CelestialBodiesShown = false
	sky.Parent = Lighting
	-- moonlight high overhead, a cool outdoor fill, and interiors that stay dark without lamps
	Lighting.ClockTime = 0.2
	Lighting.Brightness = 0.9
	Lighting.Ambient = Color3.fromRGB(16, 16, 22)
	Lighting.OutdoorAmbient = Color3.fromRGB(52, 58, 76)
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.7
	Lighting.ExposureCompensation = 0.1
end

setupLighting()

-- saved stats (nights, survivals, endings found), in the lobby and in the house
local Stats = require(Services.StatsService)
Stats.init(ctx)
Stats.start()
-- coins, gear, crates, the daily reward and quests (both places)
local Economy = require(Services.EconomyService)
Economy.init(ctx)
Economy.start()

-- Lobby servers: queue circles that teleport groups into their own game server
local mode = ctx.Mode.get()
workspace:SetAttribute("Mode", mode)

-- game passes and donations (both places: a purchase can land wherever the player is)
local Shop = require(Services.ShopService)
Shop.init(ctx)
Shop.start()
if mode == "Lobby" then
	-- the owner's panel works here too, for the coins tab
	local LobbyAdmin = require(Services.AdminService)
	LobbyAdmin.init(ctx)
	LobbyAdmin.start()
	require(script.Lobby.LobbyServer).run(ctx)
	return
end
ctx.Reserved = ctx.Mode.isReserved()

ctx.Audio = require(Services.AudioService)
ctx.Noise = require(Services.NoiseService)
ctx.Interaction = require(Services.InteractionService)
ctx.Inventory = require(Services.InventoryService)
ctx.Power = require(Services.PowerService)
ctx.Doors = require(Services.DoorService)
ctx.PlayerState = require(Services.PlayerStateService)
ctx.Hiding = require(Services.HidingService)
ctx.Capture = require(Services.CaptureService)
ctx.Objectives = require(Services.ObjectiveService)
ctx.Dialogue = require(Services.DialogueService)
ctx.Phone = require(Services.PhoneService)
ctx.Escape = require(Services.EscapeService)
ctx.Chat = require(Services.ChatService)
ctx.Ending = require(Services.EndingService)
ctx.Revive = require(Services.ReviveService)
ctx.Admin = require(Services.AdminService)
ctx.Cutscene = require(Services.CutsceneService)
ctx.Heartbeat = require(Services.HeartbeatService)
ctx.Puzzle = require(Services.PuzzleService)
ctx.Finale = require(Services.FinaleService)
ctx.Badges = require(Services.BadgeService)
ctx.Badges.init(ctx)
ctx.World = require(script.World.World)
ctx.Director = require(script.Director.Director)
ctx.Intruder = require(script.Intruder.Intruder)

local ORDER = {
	"Audio", "Noise", "Interaction", "Inventory", "Power", "Doors", "PlayerState", "Hiding", "Capture",
	"Objectives", "Dialogue", "Phone", "Escape", "Chat", "Ending", "Revive", "Admin", "Cutscene", "Heartbeat", "Puzzle", "Finale", "World", "Director", "Intruder",
}

for _, name in ORDER do
	local s = ctx[name]
	if s.init then
		s.init(ctx)
	end
end

ctx.World.build()

-- After an ending: a group's own server sends everyone back to the lobby place;
-- otherwise (Studio, or if that fails) the house is rebuilt and the in-house lobby reopens.
local restarting = false
function ctx.restart(stayHere: boolean?, stayers: { [Player]: boolean }?)
	if restarting then
		return
	end
	restarting = true
	-- a group's own server: everyone goes back to the lobby together, except whoever asked for
	-- another night here (the ending card's ANOTHER NIGHT): they get a fresh house in this server
	local players = Players:GetPlayers()
	local leaving = {}
	for _, p in players do
		if not (stayers and stayers[p]) then
			table.insert(leaving, p)
		end
	end
	if ctx.Reserved and #leaving > 0 and #leaving < #players and not stayHere then
		for _, p in leaving do
			p:SetAttribute("Leaving", true) -- on their way out: not part of the next night here
		end
		pcall(function()
			TeleportService:TeleportAsync(ctx.Mode.lobbyPlaceId(), leaving)
		end)
		stayHere = true
	elseif ctx.Reserved and #leaving == 0 and #players > 0 then
		stayHere = true
	end
	if ctx.Reserved and #players > 0 and not stayHere then
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(ctx.Mode.lobbyPlaceId(), players)
		end)
		if ok then
			-- anyone the teleport didn't take gets a fresh night here instead of a frozen screen
			task.delay(25, function()
				if #Players:GetPlayers() > 0 then
					restarting = false
					ctx.restart(true)
				end
			end)
			return
		end
		warn("[Restart] couldn't return to the lobby, resetting the house instead: " .. tostring(err))
	end
	for _, name in ORDER do
		local s = ctx[name]
		if s.reset then
			local ok, err = pcall(s.reset)
			if not ok then
				warn("[Restart] " .. name .. ": " .. tostring(err))
			end
		end
	end
	ctx.World.build()
	for _, p in Players:GetPlayers() do
		ctx.PlayerState.resetPlayer(p)
		p:SetAttribute("InGame", nil)
		if p:GetAttribute("Leaving") then
			continue
		end
		task.spawn(function()
			p:LoadCharacter()
		end)
	end
	ctx.Director.enterLobby()
	restarting = false
end

for _, name in ORDER do
	local s = ctx[name]
	if s.start then
		s.start()
	end
end

print("[HomeAlone] server ready")
