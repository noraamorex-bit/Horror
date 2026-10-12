-- hunt_goal_test: when the power dies, the objectives become the ways out, the quickest first
-- (Call 911 from the one bar of signal upstairs); a Call 911 prompt waits by the bathroom window
-- and only works there; holding the call brings the police (Survive). Plus the veteran pacing:
-- a group that has all played before gets one chore fewer.
local H = require("./env")
local T = 1000
H.clock = function() return T end
H.schedule = true
function H.flush(sec) for _ = 1, math.ceil(sec / 0.1) do T += 0.1; H.runDue() end end
local R = H.roblox
local function setup()
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Rooms = H.load("RS/Shared/Rooms")
	ctx.Sounds = H.load("RS/Shared/Sounds")
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Util = H.load("RS/Shared/Util")
	ctx.Builder = H.load("Server/World/Builder")
	ctx.Layout = H.load("Server/World/Layout")
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { FireClient = function() end, FireAllClients = function() end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService" }
	local names = {}
	for _, name in ORDER do
		local key, file = name:match("(%w+)=(%w+)")
		ctx[key] = H.load("Server/Services/" .. file)
		table.insert(names, key)
	end
	ctx.World = H.load("Server/World/World")
	ctx.Director = H.load("Server/Director/Director")
	ctx.Intruder = H.load("Server/Intruder/Intruder")
	for _, k in { "World", "Director", "Intruder" } do table.insert(names, k) end
	for _, k in names do if ctx[k].init then ctx[k].init(ctx) end end
	ctx.World.build()
	ctx.restart = function() end
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	return ctx
end
local function mkPlayer(name)
	local p = H.wrap(R.Instance.new("Player"))
	p.Name = name
	local char = H.Instance.new("Model")
	local rootPart = H.Instance.new("Part", char)
	rootPart.Name = "HumanoidRootPart"
	local hum = H.Instance.new("Humanoid", char)
	hum.Health = 100
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	p:SetAttribute("InGame", true)
	return p, rootPart
end
local function has(list, id)
	for _, o in list do if o.Id == id then return o end end
	return nil
end
local ok, err = pcall(function()
	local ctx = setup()
	local p, root = mkPlayer("Caller")
	H.services.Players.GetPlayers = function() return { p } end
	local sent = nil
	ctx.Remotes.Objectives.FireAllClients = function(_, list) sent = list end

	-- the act starts: nothing to run from yet, so no objectives
	ctx.Director.startAct("SomeoneElse")
	assert(sent and #sent == 0, "no objectives before the blackout")
	-- the breaker drops (8 s after the chapter card): the ways out
	H.flush(10)
	assert(not ctx.Power.isOn(), "the power is off")
	local call = has(sent, "Call911")
	assert(call and not call.Optional, "Call 911 is the main goal")
	for _, id in { "Neighbor", "Car", "Attic", "Power" } do
		local o = has(sent, id)
		assert(o and o.Optional, id .. " is there, optional")
	end
	assert(sent[1].Id == "Call911", "Call 911 first")
	assert(call.Current and call.Current:find("bathroom window"), "the step says where the signal is")
	assert(#call.Targets >= 1, "a marker for it")

	-- the Call 911 prompt by the bathroom window
	local world = H.unwrap(ctx.World.folder())
	local prompt = nil
	for _, d in world:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "Call911" then prompt = H.wrap(d) end
	end
	assert(prompt, "a Call 911 prompt exists")
	H.flush(0.5)
	assert(prompt.Enabled == true, "it's on once he's in the house")
	local spot = prompt.Parent.Position
	assert(ctx.Rooms.find(spot) and ctx.Rooms.find(spot).Name == "HallBath" and spot.X > 33, "it sits where the bar of signal is")
	-- not standing in the signal: it says so, no call
	root.CFrame = R.CFrame.new(0, 20, 0)
	p:SetAttribute("Signal", 0)
	rawget(prompt, "__signals").Triggered:Fire(p)
	assert(not p:GetAttribute("Calling"), "no call without signal")
	-- in the signal: the call goes through after CellCallDuration
	root.CFrame = R.CFrame.new(spot)
	p:SetAttribute("Signal", 1)
	rawget(prompt, "__signals").Triggered:Fire(p)
	assert(p:GetAttribute("Calling") == true, "calling")
	-- (PlayerState recomputes Signal from the position every tick: keep it there)
	-- Normal: a whispered call (quieter, less often) that takes CellCallDurationNormal
	local voices = {}
	ctx.Noise.listen(function(ev) if ev.Kind == "Voice" and ev.Source == p then table.insert(voices, ev.Radius) end end)
	local need = ctx.Config.Help.CellCallDurationNormal
	for _ = 1, need - 1 do p:SetAttribute("Signal", 1); H.flush(1) end
	assert(not ctx.Escape.helpCalled(), "not through yet")
	for _ = 1, 3 do p:SetAttribute("Signal", 1); H.flush(1) end
	assert(ctx.Escape.helpCalled(), "help is on the way after " .. need .. " s")
	assert(#voices >= 2 and #voices <= math.ceil(need / 3) + 1, "a whisper every 3 s, got " .. #voices)
	for _, r in voices do assert(r == ctx.Config.Noise.PhoneWhisper, "whispering, not talking out loud") end
	assert(has(sent, "Survive"), "survive until they come")
	assert(not has(sent, "Neighbor") and not has(sent, "Car"), "the other ways out are gone")
	H.flush(0.5)
	assert(prompt.Enabled == false, "the prompt goes once help is called")

	-- veteran pacing: a group that has all played before
	-- titles earned in the house: Scaredy Cat (5 hides while he hunts), Phrogger (his nest),
	-- Attic Explorer (climbing into the attic)
	local earned = {}
	ctx.Economy = { achieve = function(pl, id) earned[id] = pl return true end, track = function() end, resetNight = function() end }
	p:SetAttribute("NightHuntHides", 0)
	local realHunting = ctx.Intruder.isHunting
	ctx.Intruder.isHunting = function() return false end
	for _ = 1, 6 do ctx.Director.onHide(p) end
	assert(not earned.Title_Scaredy, "hiding before the hunt doesn't count")
	ctx.Intruder.isHunting = function() return true end
	for _ = 1, 4 do ctx.Director.onHide(p) end
	assert(not earned.Title_Scaredy, "not after four")
	ctx.Director.onHide(p)
	assert(earned.Title_Scaredy == p, "five hides from him: Scaredy Cat")
	ctx.Intruder.isHunting = realHunting
	ctx.Director.onDiscovery(p, "Notebook")
	assert(earned.Title_Phrogger == p, "his nest: Phrogger")
	root.CFrame = R.CFrame.new(0, ctx.Layout.Y and ctx.Layout.Y.Attic and ctx.Layout.Y.Attic + 2 or 32, 0)
	assert(ctx.Rooms.floorOf(root.Position) == "Attic", "standing in the attic (" .. ctx.Rooms.floorOf(root.Position) .. ")")
	H.flush(2)
	assert(earned.Title_Attic == p, "in the attic: Attic Explorer")
	ctx.Economy = nil

	-- (one world per test file: modules are shared; back to the house's own lobby state)
	local ctx2 = ctx
	ctx2.Director.enterLobby()
	local a = mkPlayer("Vet1")
	local b = mkPlayer("Vet2")
	a:SetAttribute("StatNights", 3); b:SetAttribute("StatNights", 1)
	H.services.Players.GetPlayers = function() return { a, b } end
	local list2 = nil
	ctx2.Remotes.Objectives.FireAllClients = function(_, l) list2 = l end
	ctx2.Director.adminStart("Normal")
	assert(H.unwrap(H.workspaceRoot):GetAttribute("VeteranNight") == true, "a veteran night")
	assert(list2 and #list2 == 3 and has(list2, "Popcorn"), "the full build-up for veterans too (the owner found it too fast)")
	-- a first-timer joins the group: the full build-up
	local ctx3 = ctx
	ctx3.Director.enterLobby()
	local c = mkPlayer("New")
	H.services.Players.GetPlayers = function() return { a, c } end
	local list3 = nil
	ctx3.Remotes.Objectives.FireAllClients = function(_, l) list3 = l end
	ctx3.Director.adminStart("Normal")
	assert(H.unwrap(H.workspaceRoot):GetAttribute("VeteranNight") == nil, "not with a first-timer")
	assert(list3 and has(list3, "Popcorn"), "all three chores")
	print("hunt goal ok")

	-- act II: one thing at a time, and a breather before the lights go
	ctx.Director.enterLobby()
	ctx.Intruder.setMode("Offstage") -- (he was hunting in the part above: back in the attic)
	-- (and the police came for that night: a fresh night's state)
	for _, k in { "Ending", "Escape", "Objectives", "Capture" } do
		if ctx[k].reset then ctx[k].reset() end
	end
	assert(not ctx.Ending.isOver(), "a fresh night")
	local solo = mkPlayer("Pace")
	H.services.Players.GetPlayers = function() return { solo } end
	-- (record when each scare fires and when Mom's texts arrive)
	local scares, texts = {}, {}
	local realDeliver = ctx.Phone.deliver
	ctx.Phone.deliver = function(pl, from, body)
		table.insert(texts, { T = T, From = from })
		return realDeliver(pl, from, body)
	end
	ctx.Director.startAct("SmallThings")
	local t0 = T
	local seen = {}
	ctx.Objectives.complete("LockUp")
	ctx.Director.onDoorLockChanged({ Locked = true, Id = "BackDoor" }, solo)
	local newsAt, tvDuringNews = nil, false
	local bedAt, brushedAt = nil, nil
	-- a late arrival 30 s into act II still joins the night (MatchService keeps it open until bedtime)
	local notes = {}
	ctx.Remotes.Notify.FireClient = function(_, pl, text) table.insert(notes, { P = pl, Text = text }) end
	local late = nil
	local openBeforeBed, openAfterBed = nil, nil
	while H.unwrap(H.workspaceRoot):GetAttribute("Act") == "SmallThings" and T - t0 < 700 do
		H.flush(1)
		if not late and T - t0 >= 30 then
			assert(ctx.Director.lateJoinOpen(), "act II, before bedtime: open to late arrivals")
			late = mkPlayer("Late")
			late:SetAttribute("InGame", nil)
			H.services.Players.GetPlayers = function() return { solo, late } end
			H.services.Players.PlayerAdded:Fire(late)
		end
		if late and openBeforeBed == nil then openBeforeBed = ctx.Director.lateJoinOpen() end
		if ctx.Objectives.has("Bedtime") and openAfterBed == nil then openAfterBed = ctx.Director.lateJoinOpen() end
		local st = ctx.Director._state()
		for id in st.Fired do
			if not seen[id] then
				seen[id] = true
				table.insert(scares, { Id = id, T = T })
				if id == "TVAlert" and ctx.Objectives.has("News") and not ctx.Objectives.isDone("News") then tvDuringNews = true end
			end
		end
		if ctx.Objectives.has("Investigate") and not ctx.Objectives.isDone("Investigate") and T - (st.LastScareAt or T) > 20 then
			ctx.Objectives.complete("Investigate")
		end
		if ctx.Objectives.has("News") and not ctx.Objectives.isDone("News") and not newsAt then
			newsAt = T + 25
		end
		if newsAt and T >= newsAt and not ctx.Objectives.isDone("News") then
			ctx.Objectives.complete("News")
		end
		-- then bed: someone goes up and brushes their teeth 20 s later
		if ctx.Objectives.has("Bedtime") and not bedAt then
			bedAt = T
		end
		if bedAt and T >= bedAt + 20 and not ctx.Objectives.isDone("Bedtime") then
			ctx.Objectives.step("Bedtime", "Teeth")
			brushedAt = T
		end
	end
	ctx.Phone.deliver = realDeliver
	local actLen = T - t0
	local names = {}
	for _, sc in scares do table.insert(names, ("%s@%.0f"):format(sc.Id, sc.T - t0)) end
	assert(late:GetAttribute("InGame") == true, "the late arrival joined the night")
	local toLate, toSolo = false, false
	for _, n in notes do
		if n.P == late and string.find(n.Text, "just in time") then toLate = true end
		if n.P == solo and string.find(n.Text, "not alone tonight") then toSolo = true end
	end
	assert(toLate and toSolo, "both told: the arrival and the one already there")
	assert(openBeforeBed == true and openAfterBed == false, "closed to late arrivals once it's bedtime")
	H.services.Players.GetPlayers = function() return { solo } end
	print("late join in act II ok")
	print(("act II lasted %.0f s; scares: %s"):format(actLen, table.concat(names, " ")))
	assert(H.unwrap(H.workspaceRoot):GetAttribute("Act") == "SomeoneElse", "on to act III")
	assert(bedAt and newsAt and bedAt >= newsAt, "after the news: get ready for bed")
	assert(brushedAt and T - brushedAt <= ctx.Config.Director.AfterBedtime + 17, ("the lights go soon after (%.0f s)"):format(T - (brushedAt or T)))
	assert(actLen >= ctx.Config.Director.BedtimeMinAct, "no rushing: act II still runs a few minutes")
	assert(not tvDuringNews, "the emergency alert never cuts in while they're watching the news")
	-- scripted beats never land on top of each other
	local beatIds = { PlateCrash = true, FootstepsUpstairs = true, TVAlert = true, FigureWindow = true }
	local lastBeat = nil
	for _, sc in scares do
		if beatIds[sc.Id] then
			if lastBeat then assert(sc.T - lastBeat >= 30, "two beats too close: " .. sc.Id) end
			lastBeat = sc.T
		end
	end
	-- Mom's texts came (after the house was locked), and no text lands within a few seconds of a scare
	local moms = 0
	for _, tx in texts do if tx.From == "Mom" then moms += 1 end end
	assert(moms >= 3 and newsAt ~= nil, "mom texted about the news, and the news task came")
	for _, tx in texts do
		for _, sc in scares do
			assert(math.abs(tx.T - sc.T) >= 3, ("a text from %s at %.0f on top of %s at %.0f"):format(tx.From, tx.T - t0, sc.Id, sc.T - t0))
		end
	end
	print("act II pacing ok")

	-- nobody got help out: a while into the last act, Mrs. Okafor calls the police herself
	for _, k in { "Ending", "Escape", "Objectives" } do
		if ctx[k].reset then ctx[k].reset() end
	end
	local notes = {}
	local realNotify = ctx.Remotes.Notify.FireAllClients
	ctx.Remotes.Notify.FireAllClients = function(_, text) table.insert(notes, text) end
	ctx.Director.startAct("Guest")
	local tg = T
	while not ctx.Escape.helpCalled() and T - tg < 300 do H.flush(1) end
	ctx.Remotes.Notify.FireAllClients = realNotify
	local after = T - tg
	assert(ctx.Escape.helpCalled(), "help was called for them")
	assert(math.abs(after - ctx.Config.Help.OkaforCallsAfter) <= 3, ("after OkaforCallsAfter (%.0f s)"):format(after))
	local told = false
	for _, n in notes do if string.find(n, "Okafor") then told = true end end
	assert(told, "and everyone is told")
	print(("okafor called after %.0f s ok"):format(after))

	-- nerve: alone in the dark (power out, him nowhere near) wears you down to DarkFloor, no further
	H.flush(ctx.Config.Help.OkaforResponse + 5) -- (the police come for that night)
	for _, k in { "Ending", "Escape" } do
		if ctx[k].reset then ctx[k].reset() end
	end
	ctx.Intruder.setMode("Offstage")
	ctx.Power.setMain(false, "Test")
	local lone, lroot = mkPlayer("Lone")
	H.services.Players.GetPlayers = function() return { lone } end
	lroot.CFrame = R.CFrame.new(-30, 17, -20) -- (the master bedroom, upstairs)
	lone:SetAttribute("Nerve", 100)
	local realAct = ctx.Director.getAct
	ctx.Director.getAct = function() return "Guest" end -- (the hunt, without him in it)
	for _ = 1, 480 do H.services.RunService.Heartbeat:Fire(0.5); T += 0.5 end
	ctx.Director.getAct = realAct
	local nerve = lone:GetAttribute("Nerve")
	local floor = ctx.Config.Nerve.DarkFloor
	assert(nerve <= floor + 2 and nerve >= floor - 1, ("the dark alone stops at %d, got %.1f"):format(floor, nerve))
	print(("nerve in the dark settles at %.0f ok"):format(nerve))

	-- alone from a group circle: "they're not coming" waits while someone could still join, and never
	-- comes once someone has (PLAY SOLO: right away, as before)
	ctx.Power.setMain(true, "Test")
	local function soloNight(openFor, joinAt)
		local open = openFor ~= nil
		ctx.Match = { isOpen = function() return open end }
		local me = mkPlayer("Alone")
		local list = { me }
		H.services.Players.GetPlayers = function() return list end
		local got = {}
		ctx.Phone.deliver = function(_, from) table.insert(got, { From = from, T = T }) end
		local t0 = T
		ctx.Director.startAct("Evening")
		for _ = 1, 120 do
			H.flush(1)
			if openFor and T - t0 >= openFor then open = false end
			if joinAt and T - t0 >= joinAt and #list == 1 then table.insert(list, (mkPlayer("Joiner"))) end
		end
		ctx.Phone.deliver = realDeliver
		local first = nil
		for _, g in got do if g.From == "Riley" then first = first or (g.T - t0) end end
		return first
	end
	local soloAt = soloNight(nil, nil)
	assert(soloAt and soloAt < 30, "PLAY SOLO: the friends text at 24 s, got " .. tostring(soloAt))
	local openAt = soloNight(60, nil)
	assert(openAt and openAt >= 60 and openAt < 70, "open to joiners: the text waits until it closes, got " .. tostring(openAt))
	local joined = soloNight(60, 40)
	assert(joined == nil, "someone joined: no 'we had to turn around'")
	ctx.Match = nil
	print(("solo texts: %.0f s, %.0f s once closed, none after a join ok"):format(soloAt, openAt))
end)
print(ok and "HUNTGOAL OK" or ("HUNTGOAL FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
