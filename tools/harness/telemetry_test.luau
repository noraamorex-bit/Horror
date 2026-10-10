-- telemetry_test: what Creator Hub's analytics receives (TelemetryService). A stand-in
-- AnalyticsService records every call: the onboarding funnel (each step once), the night funnel
-- (one session per player per night, steps in order, never twice), endings, quits, coins.
local H = require("./env")
local R = H.roblox
local ok, err = pcall(function()
	local calls = {}
	local function rec(name)
		return function(_, ...) table.insert(calls, { name, ... }) end
	end
	H.services.AnalyticsService = {
		LogOnboardingFunnelStepEvent = rec("Onboard"),
		LogFunnelStepEvent = rec("Funnel"),
		LogCustomEvent = rec("Custom"),
		LogEconomyEvent = rec("Economy"),
	}
	H.services.RunService.IsStudio = function() return false end
	local players = {}
	H.services.Players.GetPlayers = function() return players end
	local ctx: any = {}
	local T = H.load("Server/Services/TelemetryService")
	T.init(ctx)
	T.start()
	local function mk(id)
		local p = H.wrap(R.Instance.new("Player"))
		rawset(p, "UserId", id)
		rawset(p, "Parent", H.workspaceRoot)
		p:SetAttribute("InGame", true)
		table.insert(players, p)
		return p
	end
	local a, b = mk(1), mk(2)
	b:SetAttribute("StatNights", 3)
	local function count(kind, p, step)
		local n = 0
		for _, c in calls do
			if c[1] == kind and c[2] == p and (step == nil or (kind == "Onboard" and c[3] == step) or (kind == "Funnel" and c[5] == step)) then n += 1 end
		end
		return n
	end
	T.onboard(a, 1); T.onboard(a, 1); T.onboard(a, 2)
	assert(count("Onboard", a, 1) == 1 and count("Onboard", a, 2) == 1, "onboarding steps once each")
	T.nightStart({ a, b })
	assert(count("Funnel", a, 1) == 1 and count("Onboard", a, 4) == 1, "night started")
	assert(count("Onboard", b, 9) == 1 and count("Onboard", a, 9) == 0, "second night only for b")
	T.act("SmallThings"); T.act("SmallThings"); T.act("SomeoneElse")
	assert(count("Funnel", a, 2) == 1 and count("Funnel", a, 3) == 1 and count("Onboard", a, 6) == 1, "acts, once each")
	T.ended(a, "Sirens"); T.ended(a, "Sirens")
	assert(count("Funnel", a, 5) == 1 and count("Onboard", a, 8) == 1, "ending once")
	-- b leaves in the middle of the night: a quit, with the act
	H.unwrap(H.workspaceRoot):SetAttribute("Act", "SomeoneElse")
	H.services.Players.PlayerRemoving:Fire(b)
	local quit = nil
	for _, c in calls do if c[1] == "Custom" and c[2] == b and c[3] == "QuitDuringNight" then quit = c end end
	assert(quit, "a quit during the night is logged")
	-- a's leaving after the ending is not a quit
	H.services.Players.PlayerRemoving:Fire(a)
	for _, c in calls do assert(not (c[1] == "Custom" and c[2] == a and c[3] == "QuitDuringNight"), "no quit after the ending") end
	-- coins
	T.coins(a, 50, 150, "Gameplay", "Night"); T.coins(a, -60, 90, nil, "Flashlight"); T.coins(a, 0, 90)
	assert(count("Economy", a) == 2, "coins in and out (not zero)")
	print(("telemetry ok: %d calls"):format(#calls))
end)
print(ok and "TELEMETRY OK" or ("TELEMETRY FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
