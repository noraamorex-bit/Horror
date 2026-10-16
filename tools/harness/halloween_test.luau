-- halloween_test: Halloween 2026 (HalloweenService, EconomyService candy). Candy is saved and added
-- onto what another server saved; 5 / 15 / 30 unlock the Pumpkin colour, the Candy Corn trail and the
-- "Trick or Treat" title (the first with the badge); surviving pays 2 more; the result card gets its
-- line. In the house: 5 candies a night, apart, at the checked spots; taking one pays it and says so.
-- After the event: no candy, no rewards.
local H = require("./env")
local R = H.roblox

local function copy(v)
	if type(v) ~= "table" then return v end
	local t = {}
	for k, x in v do t[k] = copy(x) end
	return t
end
local saved = {}
local fakeStore = {
	GetAsync = function(_, key) return copy(saved[key]) end,
	UpdateAsync = function(_, key, fn)
		local new = fn(copy(saved[key]))
		if new ~= nil then saved[key] = copy(new) end
		return copy(saved[key])
	end,
}
H.services.DataStoreService = { GetDataStore = function() return fakeStore end, GetOrderedDataStore = function() return nil end }

local ok, err = pcall(function()
	local fired = {}
	local badges = {}
	local ctx: any = {}
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { FireClient = function(_, p, a) table.insert(fired, { k, p, a }) end, FireAllClients = function() end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	ctx.Stats = { addReviveCredit = function() return true end, refresh = function() end, setBeam = function() end }
	ctx.Inventory = { give = function() end }
	ctx.Badges = { award = function(_, key) table.insert(badges, key) end }
	local E = H.load("Server/Services/EconomyService")
	E.init(ctx)
	local Cat = E.Catalog
	assert(Cat.halloweenLive(os.time()) or os.time() >= Cat.Halloween.Until, "(the clock)")
	local liveUntil = Cat.Halloween.Until
	Cat.Halloween.Until = os.time() + 86400 -- (the event is on, whatever today is)
	local p = H.wrap(R.Instance.new("Player"))
	rawset(p, "UserId", 31)
	H.services.Players.GetPlayers = function() return { p } end
	H.services.Players.GetPlayerByUserId = function(_, id) return id == 31 and p or nil end
	E._load(p)

	-- the rewards, in order
	assert(#Cat.Halloween.Steps == 3, "three rewards")
	local prev = 0
	for _, id in Cat.Halloween.Steps do
		local c = Cat.cosmetic(id)
		assert(c and c.Event == "Halloween" and c.Candy > prev and c.How, id .. ": an earned Halloween cosmetic")
		prev = c.Candy
	end
	assert(Cat.nextCandyReward(0).Id == "Beam_Pumpkin" and Cat.nextCandyReward(5).Id == "Trail_CandyCorn" and Cat.nextCandyReward(30) == nil, "next reward")

	-- candy adds up, and is saved
	assert(E.addCandy(p, 3) == 3 and p:GetAttribute("Candy") == 3, "3 candy")
	assert(not E.owns(p, "Beam_Pumpkin"), "not yet")
	E._save(31)
	assert(saved.u31.Candy == 3, "saved")
	-- another server found 4 meanwhile: ours lands on top
	saved.u31.Candy += 4
	E.addCandy(p, 1)
	E._save(31)
	assert(saved.u31.Candy == 8 and E.candy(p) == 8, "added onto what's saved: " .. tostring(saved.u31.Candy))
	print("candy saved ok")
	-- (the 5 was crossed in that merge: the next pickup hands the reward over)
	fired = {}
	E.addCandy(p, 1)
	assert(E.owns(p, "Beam_Pumpkin"), "5+: the Pumpkin colour")
	assert(table.find(badges, "Halloween2026"), "and the Halloween badge")
	local said = false
	for _, f in fired do if f[1] == "Notify" and string.find(f[3], "Pumpkin", 1, true) then said = true end end
	assert(said, "and they're told")
	E.addCandy(p, 6)
	assert(E.owns(p, "Trail_CandyCorn") and not E.owns(p, "Title_TrickOrTreat"), "15: the trail")
	E.addCandy(p, 15)
	assert(E.owns(p, "Title_TrickOrTreat"), "30: the title")
	-- the Pumpkin colour is a flashlight colour you can pick once owned
	local Stats = H.load("Server/Services/StatsService")
	local found = false
	for _, b in Stats.Beams do if b.Id == "Beam_Pumpkin" and b.Crate then found = true end end
	assert(found, "the Pumpkin colour is in the flashlight list (owned = usable)")
	print("rewards ok")

	-- the night's pay: surviving adds 2 candy, and the card gets the Halloween line
	E.resetNight()
	local before = E.candy(p)
	local r = E.nightRewards(p, { Seconds = 600, Survived = true })
	assert(E.candy(p) == before + Cat.Halloween.Survive, "surviving: +" .. Cat.Halloween.Survive)
	assert(type(r.Candy) == "table" and r.Candy.Total == E.candy(p) and r.Candy.Tonight == Cat.Halloween.Survive, "the card's candy line")
	E.resetNight()
	local r2 = E.nightRewards(p, { Seconds = 600, Survived = false })
	assert(r2.Candy and r2.Candy.Tonight == 0, "caught: no bonus candy")
	print("night pay ok")

	-- in the house: tonight's candies
	ctx.Economy = E
	ctx.Builder = H.load("Server/World/Builder")
	ctx.Layout = H.load("Server/World/Layout")
	local prompts = {}
	ctx.Interaction = { prompt = function(part, opts, cb)
		local pr = H.wrap(R.Instance.new("ProximityPrompt"))
		pr.Parent = part
		table.insert(prompts, { part = part, opts = opts, cb = cb, pr = pr })
		return pr
	end }
	local played = 0
	ctx.Audio = { playAt = function() played += 1 end }
	local events = {}
	ctx.Journey = { event = function(_, code, x) table.insert(events, { code, x }) end }
	local Hw = H.load("Server/Services/HalloweenService")
	Hw.init(ctx)
	assert(ctx.Halloween == Hw and Hw.live(), "on ctx, live")
	assert(#ctx.Layout.CandySpots >= 20, "enough spots")
	local root = H.Instance.new("Folder")
	for night = 1, 6 do
		prompts = {}
		Hw.place(root)
		assert(#prompts == Cat.Halloween.PerNight and Hw.count() == Cat.Halloween.PerNight, "five candies a night, got " .. #prompts)
		for i, a in prompts do
			assert(a.opts.Action == "Take" and a.opts.Object == "Candy", "a Take Candy prompt")
			local pos = H.unwrap(a.part).CFrame.Position
			local onSpot = false
			for _, s in ctx.Layout.CandySpots do
				if math.abs(pos.X - s.X) < 0.01 and math.abs(pos.Z - s.Z) < 0.01 and pos.Y > s.Y and pos.Y < s.Y + 0.5 then onSpot = true end
			end
			assert(onSpot, "sits on a checked spot")
			for j = i + 1, #prompts do
				assert((H.unwrap(prompts[j].part).CFrame.Position - pos).Magnitude >= 12, "spread out")
			end
		end
		H.unwrap(root):ClearAllChildren()
	end
	-- taking one
	prompts = {}
	Hw.place(root)
	fired = {}
	local c0 = E.candy(p)
	local first = prompts[1]
	first.cb(p, first.pr)
	assert(E.candy(p) == c0 + 1, "taking one pays one")
	assert(Hw.count() == Cat.Halloween.PerNight - 1, "and it's gone from the house")
	assert(played == 1 and events[#events][1] == "Candy", "a sound, and the log")
	local note = nil
	for _, f in fired do if f[1] == "Notify" then note = f[3] end end
	assert(note and string.find(note, "Candy!", 1, true) and string.find(note, "4 more", 1, true), "told: " .. tostring(note))
	first.cb(p, first.pr)
	assert(E.candy(p) == c0 + 1, "can't take the same one twice")
	print("house candy ok")

	-- the jack-o'-lantern face: glowing pieces and one light
	local Kit = H.load("Server/World/Kit")
	local face = H.unwrap(Kit.jackFace(root, R.CFrame.new(0, 1, 0), 1.2, R.Vector3.new(0, 0, -1)))
	local neon, lights = 0, 0
	for _, d in face:GetDescendants() do
		if d:IsA("BasePart") and d.Material == R.Enum.Material.Neon then neon += 1 end
		if d:IsA("PointLight") then lights += 1 end
	end
	assert(neon >= 9 and lights == 1, "carved and lit: " .. neon .. " pieces, " .. lights .. " light")
	for _, d in face:GetDescendants() do
		if d:IsA("BasePart") then
			assert(d.CFrame.Position.Z < -0.3 and math.abs(d.CFrame.Position.X) < 0.6, "on the front, facing the way asked")
		end
	end
	print("jack-o'-lantern ok")

	-- after the event: nothing
	Cat.Halloween.Until = os.time() - 1
	prompts = {}
	H.unwrap(root):ClearAllChildren()
	Hw.place(root)
	assert(#prompts == 0 and Hw.count() == 0, "no candy after Halloween")
	E.resetNight()
	local r3 = E.nightRewards(p, { Seconds = 600, Survived = true })
	assert(r3.Candy == nil, "no candy line after Halloween")
	Cat.Halloween.Until = liveUntil
	print("after the event ok")
end)
print(ok and "HALLOWEEN OK" or ("HALLOWEEN FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
