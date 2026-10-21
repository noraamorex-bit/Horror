local H = require("./env")
local ok, err = pcall(function()
	local ctx: any = {}
	ctx.Story = H.load("RS/Shared/Story")
	local Stats = H.load("Server/Services/StatsService")
	Stats.init(ctx)
	local roblox = H.roblox
	local p = H.wrap(roblox.Instance.new("Player"))
	rawset(p, "UserId", 42)
	H.services.Players.GetPlayers = function() return { p } end
	Stats.start()
	print("loaded", p:GetAttribute("StatNights"), p:GetAttribute("StatEndingTotal"))
	local firsts = Stats.recordNight({ p }, "Sirens")
	print("first Sirens", firsts[42] == true, "nights", p:GetAttribute("StatNights"), "survived", p:GetAttribute("StatEscapes"), "endings", p:GetAttribute("StatEndings"))
	firsts = Stats.recordNight({ p }, "Sirens")
	print("second Sirens not first", firsts[42] == nil, "nights", p:GetAttribute("StatNights"), "endings", p:GetAttribute("StatEndings"))
	p:SetAttribute("Captured", true)
	firsts = Stats.recordNight({ p }, "GoneQuiet")
	print("captured night", firsts[42] == true, "survived still", p:GetAttribute("StatEscapes"))
	-- settings: defaults, a valid change, junk ignored
	assert(p:GetAttribute("SetMusic") == 1 and p:GetAttribute("SetSfx") == 1 and p:GetAttribute("SetShake") == true, "default settings")
	Stats.setSettings(p, 0.25, 2, false)
	assert(p:GetAttribute("SetMusic") == 0.25 and p:GetAttribute("SetSfx") == 1 and p:GetAttribute("SetShake") == false, "settings saved + clamped")
	Stats.setSettings(p, "loud", 0, true)
	Stats.setSettings(p, 0/0, 0, true)
	assert(p:GetAttribute("SetMusic") == 0.25 and p:GetAttribute("SetShake") == false, "junk settings ignored")
	Stats.setSettings(p, 0.25, 1, false, 0.5)
	assert(p:GetAttribute("SetVoice") == 0.5 and p:GetAttribute("SetMusic") == 0.25, "the voices setting")
	Stats.setSettings(p, 0.25, 1, false)
	assert(p:GetAttribute("SetVoice") == 0.5, "an old client keeps the voices setting")
	print("settings ok")
	-- fastest wins: only a faster time replaces your best
	assert(p:GetAttribute("StatBest") == nil, "no best yet")
	assert(Stats.recordWin(p, 900.7) == true and p:GetAttribute("StatBest") == 900, "first win sets best")
	assert(Stats.recordWin(p, 1200) == false and p:GetAttribute("StatBest") == 900, "slower win keeps best")
	assert(Stats.recordWin(p, 640) == true and p:GetAttribute("StatBest") == 640, "faster win is new best")
	assert(Stats.recordWin(p, 0) == false, "zero ignored")
	-- too fast to be a real night (the owner: a 0:51 on the board), and skip-to-the-blackout nights
	assert(Stats.recordWin(p, 51) == false and p:GetAttribute("StatBest") == 640, "0:51 doesn't count")
	assert(Stats.recordWin(p, 359) == false, "under 6:00 doesn't count")
	ctx.Director = { isSkipping = function() return true end }
	assert(Stats.recordWin(p, 500) == false and p:GetAttribute("StatBest") == 640, "a night that started at the blackout doesn't count")
	ctx.Director = { isSkipping = function() return false end }
	assert(Stats.recordWin(p, 500) == true and p:GetAttribute("StatBest") == 500, "a full night does")
	ctx.Director = nil
	print("fastest ok")
	-- out early (escaped while friends play on): the night counts now, and only once
	local n0 = p:GetAttribute("StatNights")
	local e0 = p:GetAttribute("StatEscapes")
	p:SetAttribute("Captured", nil)
	p:SetAttribute("Escaped", "Car")
	Stats.recordOut(p, true)
	Stats.recordOut(p, true)
	assert(p:GetAttribute("StatNights") == n0 + 1 and p:GetAttribute("StatEscapes") == e0 + 1, "counted once, at once")
	local f = Stats.recordNight({ p }, "Taillights")
	assert(p:GetAttribute("StatNights") == n0 + 1 and p:GetAttribute("StatEscapes") == e0 + 1, "the ending doesn't count it again")
	assert(f[42] == true and p:GetAttribute("NightCounted") == nil, "but the ending is recorded, and the flag cleared")
	Stats.recordNight({ p }, "Taillights")
	assert(p:GetAttribute("StatNights") == n0 + 2, "the next night counts normally")
	-- died early: a night, not an escape
	p:SetAttribute("Escaped", nil)
	Stats.recordOut(p, false)
	assert(p:GetAttribute("StatNights") == n0 + 3 and p:GetAttribute("StatEscapes") == e0 + 2, "a death counts the night only")
	print("out early ok")
	-- the server's player list: level and nights survived
	assert(p:FindFirstChild("leaderstats"), "leaderstats made on start")
	-- (the harness doesn't fire attribute signals: build them again the way a change would sync them)
	p:FindFirstChild("leaderstats").Parent = nil
	p:SetAttribute("Level", 9)
	Stats._leaderstats(p)
	local ls = p:FindFirstChild("leaderstats")
	assert(ls.Level.Value == 9 and ls.Survived.Value == p:GetAttribute("StatEscapes"), "level and nights survived")
	Stats._leaderstats(p)
	local n = 0
	for _, c in p:GetChildren() do if c.Name == "leaderstats" then n += 1 end end
	assert(n == 1, "only one")
	-- the owner is left off every board, this one too
	ctx.Config = { Admins = { 42 } }
	ls.Parent = nil
	Stats._leaderstats(p)
	assert(p:FindFirstChild("leaderstats") == nil, "no stats for the owner")
	ctx.Config = nil
	print("leaderstats ok")
end)
print(ok and "STATS OK" or ("STATS FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
