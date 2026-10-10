--[[
	TelemetryService — what Creator Hub's Analytics shows (Roblox AnalyticsService), so we can see
	where players drop off and fix exactly that. Every call is wrapped: analytics can never break
	the game, and in Studio or a test it does nothing.

	Onboarding funnel (Creator Hub → Analytics → Funnels → Onboarding; first-time players):
		1 Joined the lobby · 2 Queued · 3 Arrived at the house · 4 Night started · 5 Act II ·
		6 Act III · 7 The hunt · 8 Saw an ending · 9 Played a second night
	"Night" funnel (every night, one session per player per night):
		1 Started · 2 Act II · 3 Act III · 4 The hunt · 5 Ending
	Custom events: Ending (which one), QuitDuringNight (which act), SecretEnding, LevelUp.
	Economy events: coins in and out (Creator Hub → Analytics → Economy), with the reason.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Telemetry = {}
local ctx
local AS: any = nil

local ONBOARD = { "Joined lobby", "Queued", "Arrived at the house", "Night started", "Act II", "Act III", "The hunt", "Saw an ending", "Second night" }
local NIGHT = { "Started", "Act II", "Act III", "The hunt", "Ending" }
local ACT_STEP = { SmallThings = 2, SomeoneElse = 3, Guest = 4 } -- (Night funnel steps; onboarding is +3)

local nightId: { [Player]: string } = {}
local nightStep: { [Player]: number } = {}
local onboarded: { [Player]: { [number]: boolean } } = {}
local nightCount = 0

-- custom fields (the one we use: CustomField01), built safely
local function field(v: string?): any
	if not v then
		return nil
	end
	local ok, key = pcall(function()
		return Enum.AnalyticsCustomFieldKeys.CustomField01.Name
	end)
	return ok and { [key] = v } or nil
end

local function call(method: string, ...)
	if not AS then
		return
	end
	local args = table.pack(...)
	pcall(function()
		AS[method](AS, table.unpack(args, 1, args.n))
	end)
end

function Telemetry.init(c)
	ctx = c
	ctx.Telemetry = Telemetry
	if RunService:IsStudio() then
		return
	end
	local ok, svc = pcall(function()
		return game:GetService("AnalyticsService")
	end)
	AS = ok and svc or nil
end

-- the first-time player funnel (each step once per server; Roblox counts it for new players)
function Telemetry.onboard(player: Player, step: number)
	local done = onboarded[player]
	if not done then
		done = {}
		onboarded[player] = done
	end
	if done[step] or not ONBOARD[step] then
		return
	end
	done[step] = true
	call("LogOnboardingFunnelStepEvent", player, step, ONBOARD[step])
end

-- the night funnel: a new session when a night starts, then each step once
function Telemetry.nightStart(players: { Player })
	nightCount += 1
	for _, p in players do
		nightId[p] = string.format("%s-%d-%d", string.sub(game.JobId ~= "" and game.JobId or "local", 1, 12), nightCount, p.UserId)
		nightStep[p] = 0
		Telemetry.nightStep(p, 1)
		Telemetry.onboard(p, 3)
		Telemetry.onboard(p, 4)
		if (tonumber(p:GetAttribute("StatNights")) or 0) >= 1 then
			Telemetry.onboard(p, 9)
		end
	end
end

function Telemetry.nightStep(player: Player, step: number)
	if not nightId[player] or (nightStep[player] or 0) >= step then
		return
	end
	nightStep[player] = step
	call("LogFunnelStepEvent", player, "Night", nightId[player], step, NIGHT[step])
end

-- the Director moved to a new act
function Telemetry.act(name: string)
	local step = ACT_STEP[name]
	if not step then
		return
	end
	for p in nightId do
		if p.Parent and p:GetAttribute("InGame") then
			Telemetry.nightStep(p, step)
			Telemetry.onboard(p, step + 3)
		end
	end
end

-- a player's night is over (their own result card, or the ending)
function Telemetry.ended(player: Player, kind: string)
	if nightId[player] and (nightStep[player] or 0) < 5 then
		Telemetry.nightStep(player, 5)
		Telemetry.onboard(player, 8)
		call("LogCustomEvent", player, "Ending", 1, field(kind))
		if kind == "NotYourFamily" or kind == "ForeverFamily" or kind == "CaseClosed" then
			call("LogCustomEvent", player, "SecretEnding", 1, field(kind))
		end
	end
end

function Telemetry.custom(player: Player, name: string, value: number?, f: string?)
	call("LogCustomEvent", player, name, value or 1, field(f))
end

-- coins in (n > 0) or out (n < 0). reason: "Gameplay" | "TimedReward" | "IAP" | "Shop" | "Onboarding"
function Telemetry.coins(player: Player, n: number, balance: number, reason: string?, sku: string?)
	if n == 0 then
		return
	end
	if not AS then
		return
	end
	pcall(function()
		local flow = n > 0 and Enum.AnalyticsEconomyFlowType.Source or Enum.AnalyticsEconomyFlowType.Sink
		AS:LogEconomyEvent(player, flow, "Coins", math.abs(n), balance, reason or (n > 0 and "Gameplay" or "Shop"), sku)
	end)
end

function Telemetry.start()
	-- whoever leaves in the middle of a night: in which act
	Players.PlayerRemoving:Connect(function(p)
		if nightId[p] and (nightStep[p] or 0) < 5 then
			local act = workspace:GetAttribute("Act")
			call("LogCustomEvent", p, "QuitDuringNight", 1, field(tostring(act)))
		end
		nightId[p], nightStep[p], onboarded[p] = nil, nil, nil
	end)
end

return Telemetry
