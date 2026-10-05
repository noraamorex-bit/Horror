--[[
	Director — the night's pacing.

	• Lobby: ready-up, countdown, roles.
	• Acts: Evening -> SmallThings -> SomeoneElse -> Guest, each with Min/Max lengths.
	• Tension (0-100): rises with events, sightings and chases, decays over time. Events are only
	  scheduled while tension is under the act's ceiling, so quiet stretches happen on purpose.
	• Guaranteed beats have deadlines; the rest come from a weighted pool whose conditions hold.
	• The truth log: every strange thing that actually happened, with the in-game time.
]]

local Players = game:GetService("Players")

local Events = require(script.Parent.Events)
local Delivery = require(script.Parent.Delivery)
local Perception = require(script.Parent.Parent.Intruder.Perception)

local Director = {}
local ctx
local D: any = Director

Director.Perception = Perception

local ACT_ORDER = { "Evening", "SmallThings", "SomeoneElse", "Guest" }

-- guaranteed beats per act: { event id, deadline as a fraction of the act's Max }
local BEATS = {
	Evening = { { "WindSlam", 0.45 } },
	SmallThings = { { "PlateCrash", 0.2 }, { "FootstepsUpstairs", 0.35 }, { "TVAlert", 0.55 }, { "FigureWindow", 0.7 } },
}

local state: any = {}

local function fresh()
	return {
		Act = "Lobby",
		ActStart = os.clock(),
		GameStart = nil,
		Tension = 0,
		Truth = {},
		Logged = {},
		Fired = {},
		LastFired = {},
		NextEventAt = 0,
		NextLightning = os.clock() + 15,
		Ready = {},
		Countdown = nil,
		Discovered = false,
		ActEnding = false,
		Participants = {},
		ThinkBusyUntil = 0,
		BanterDone = {},
		Evidence = {},
	}
end

function Director.init(c)
	ctx = c
	Perception.init(c)
	state = fresh()
end

function Director.reset()
	state = fresh()
	workspace:SetAttribute("Act", "Lobby")
	workspace:SetAttribute("ClockMinutes", ctx.Config.ClockStartMinutes)
end

---------------------------------------------------------------------------
-- Queries
---------------------------------------------------------------------------
function Director.getAct(): string
	return state.Act
end

local function scaled(minutes: number): number
	return minutes * 60 * ctx.Config.TimeScale
end

local function elapsed(): number
	return state.GameStart and (os.clock() - state.GameStart) or 0
end

function Director.clockMinutes(): number
	return ctx.Config.ClockStartMinutes + elapsed() / 60 * ctx.Config.ClockRate / ctx.Config.TimeScale
end

function Director.clockString(): string
	return ctx.Util.clockString(Director.clockMinutes())
end

function Director.elapsedSeconds(): number
	return elapsed()
end

function Director.elapsedString(): string
	return ctx.Util.formatSeconds(elapsed())
end

function Director.getTruthLog()
	return state.Truth
end

function Director.tension(): number
	return state.Tension
end

function Director.addTension(n: number)
	state.Tension = math.clamp(state.Tension + n, 0, 100)
end

---------------------------------------------------------------------------
-- Truth log
---------------------------------------------------------------------------
function Director.logTruth(id: string)
	if state.Logged[id] or state.Act == "Lobby" then
		return
	end
	local text = ctx.Story.Truths[id]
	if not text then
		return
	end
	state.Logged[id] = true
	table.insert(state.Truth, { Time = Director.clockString(), Text = text, Id = id })
	if ctx.Config.Debug then
		print("[Truth] " .. id)
	end
end

function Director.logTruthRaw(text: string)
	if state.Act == "Lobby" then
		return
	end
	table.insert(state.Truth, { Time = Director.clockString(), Text = text })
end

---------------------------------------------------------------------------
-- Inner monologue
---------------------------------------------------------------------------
-- players: a list, a single Player, or nil for everyone in the night
function Director.think(players, line: string?)
	if not line then
		return
	end
	local text, hint = line:match("^(.-)|(%w+)$")
	text = text or line
	local list = players
	if list == nil then
		list = ctx.Util.sessionPlayers()
	elseif typeof(list) == "Instance" then
		list = { list }
	end
	local sent = false
	for _, p in list do
		if p:GetAttribute("InGame") and not p:GetAttribute("Escaped") then
			ctx.Remotes.Thought:FireClient(p, text, hint)
			sent = true
		end
	end
	if sent then
		-- each line holds the screen for a while; texts and banter wait for it to clear
		state.ThinkBusyUntil = math.max(state.ThinkBusyUntil or 0, os.clock()) + ctx.Config.Thoughts.Duration + 0.5
	end
end

-- nothing is being said: no thought line on screen and no conversation for a moment
function Director.isQuiet(): boolean
	local gap = ctx.Config.Thoughts.QuietGap or 2.5
	if os.clock() < (state.ThinkBusyUntil or 0) + gap then
		return false
	end
	return not ctx.Dialogue or ctx.Dialogue.quietFor() >= gap
end

-- once per player per key
function Director.thinkOnce(player: Player, key: string, line: string?)
	state.Thought = state.Thought or {}
	local seen = state.Thought[player] or {}
	state.Thought[player] = seen
	if seen[key] then
		return
	end
	seen[key] = true
	Director.think(player, line)
end

-- everyone within `radius` of a point
function Director.thinkNear(position: Vector3, radius: number, line: string?)
	local list = {}
	for _, p in ctx.Util.activePlayers() do
		local root = ctx.Util.getRoot(p)
		if root and (root.Position - position).Magnitude <= radius then
			table.insert(list, p)
		end
	end
	Director.think(list, line)
end

-- items that tick off a step of a task
local ITEM_STEPS = {
	Flashlight = { "Power", "Flashlight" },
	ElectricalTape = { "Phone", "Tape" },
	CarKeys = { "Car", "Keys" },
}

local function checkHeldItems()
	for item, st in ITEM_STEPS do
		if #ctx.Inventory.holders(item) > 0 then
			ctx.Objectives.step(st[1], st[2])
		end
	end
end

function Director.onItem(player: Player, item: string)
	Director.thinkOnce(player, "Item_" .. item, ctx.Story.Thoughts.Items[item])
	local st = ITEM_STEPS[item]
	if st then
		ctx.Objectives.step(st[1], st[2])
	end
end

function Director.onHide(player: Player)
	Director.thinkOnce(player, "Hide", ctx.Story.Thoughts.Hide)
end

function Director.onObjectiveDone()
	state.NextHintAt = os.clock() + 8
end

local function hintTick()
	if not state.NextHintAt or os.clock() < state.NextHintAt then
		return
	end
	state.NextHintAt = os.clock() + ctx.Config.Thoughts.IdleHint
	for _, id in ctx.Objectives.pending() do
		local line = ctx.Story.Thoughts.Objectives[id]
		local step = ctx.Objectives.currentText(id)
		if line or step then
			-- the first reminder is in their own words, later ones name the exact next step
			state.Hinted = state.Hinted or {}
			if line and not state.Hinted[id] then
				state.Hinted[id] = true
				Director.think(nil, line)
			elseif step then
				Director.think(nil, "What next... " .. step:sub(1, 1):lower() .. step:sub(2) .. ".")
			end
			return
		end
	end
end

---------------------------------------------------------------------------
-- Storm
---------------------------------------------------------------------------
function Director.lightning(intensity: number?)
	local i = intensity or (0.6 + math.random() * 0.5)
	ctx.Remotes.Lightning:FireAllClients(i, 0.6 + math.random() * 2.5)
	workspace:SetAttribute("LastLightning", workspace:GetServerTimeNow())
end

---------------------------------------------------------------------------
-- Lobby
---------------------------------------------------------------------------
local function lobbyPayload()
	local ready = {}
	local count = 0
	for _, p in Players:GetPlayers() do
		if state.Ready[p] then
			table.insert(ready, p.UserId)
			count += 1
		end
	end
	return {
		Phase = state.Act ~= "Lobby" and "InGame" or (state.Vote and "Vote") or (ctx.Reserved and "Arriving") or (state.Countdown and "Countdown" or "Waiting"),
		Expected = state.Expected,
		Ready = ready,
		ReadyCount = count,
		Players = #Players:GetPlayers(),
		Needed = ctx.Config.MinPlayers,
		Countdown = state.Countdown,
	}
end

local function broadcastLobby()
	ctx.Remotes.Lobby:FireAllClients(lobbyPayload())
end

local function spawnFor(player: Player): CFrame?
	local L = ctx.Layout
	if player:GetAttribute("Escaped") or (state.Act ~= "Lobby" and not player:GetAttribute("InGame")) then
		return CFrame.new(L.Outside.NeighborSafe + Vector3.new(math.random(-4, 4), 0, math.random(-3, 3)))
	end
	local spawns = L.LobbySpawns
	local i = math.random(1, #spawns)
	return CFrame.lookAt(spawns[i], spawns[i] + Vector3.new(-1, 0, 0))
end

function Director.enterLobby()
	state = fresh()
	workspace:SetAttribute("Difficulty", nil)
	workspace:SetAttribute("Act", "Lobby")
	workspace:SetAttribute("ClockMinutes", ctx.Config.ClockStartMinutes)
	broadcastLobby()
end

local function startGame()
	state.Countdown = nil
	local participants = {}
	for _, p in Players:GetPlayers() do
		if #participants < ctx.Config.MaxPlayers then
			table.insert(participants, p)
		end
	end
	state.Participants = participants
	for _, p in participants do
		ctx.PlayerState.resetPlayer(p)
		p:SetAttribute("InGame", true)
	end
	ctx.PlayerState.assignRoles(participants)
	for _, p in Players:GetPlayers() do
		if not p:GetAttribute("InGame") then
			ctx.Remotes.Notify:FireClient(p, "The house is full tonight. You're watching from next door.", "info")
			local char = p.Character
			if char then
				char:PivotTo(spawnFor(p) :: CFrame)
			end
		end
	end
	state.GameStart = os.clock()
	broadcastLobby()
	-- the opening shot (client Intro): the house from the street, a flash of lightning, and for
	-- an instant someone standing in the upstairs window. He's been here all along.
	if ctx.Intruder.prepare then
		ctx.Intruder.prepare()
	end
	for _, p in participants do
		ctx.Remotes.Intro:FireClient(p)
	end
	Director.startAct("Evening")
end

---------------------------------------------------------------------------
-- The difficulty vote: NORMAL or HARD, before the night starts (Config.Difficulty)
---------------------------------------------------------------------------
local function tally(): (number, number, number)
	local normal, hard = 0, 0
	local v = state.Vote
	for p, choice in (v and v.Votes) or {} do
		if p.Parent then
			if choice == "Hard" then
				hard += 1
			else
				normal += 1
			end
		end
	end
	return normal, hard, #Players:GetPlayers()
end

local function sendVote(target: Player?)
	local v = state.Vote
	if not v then
		return
	end
	local normal, hard, total = tally()
	local left = math.max(0, v.Ends - os.clock())
	for _, p in target and { target } or Players:GetPlayers() do
		ctx.Remotes.Vote:FireClient(p, {
			Ends = workspace:GetServerTimeNow() + left,
			Normal = normal,
			Hard = hard,
			Total = total,
			Mine = v.Votes[p],
		})
	end
end

local function beginVote()
	state.Countdown = nil
	state.Vote = { Ends = os.clock() + ((ctx.Config.Difficulty and ctx.Config.Difficulty.VoteTime) or 12), Votes = {} }
	broadcastLobby()
	sendVote()
end

local function voteTick(): boolean
	local v = state.Vote
	if not v then
		return false
	end
	if v.Result then
		-- (the result shows for a moment, then the night starts)
		if os.clock() >= v.StartAt then
			state.Vote = nil
			startGame()
		end
		return true
	end
	local normal, hard, total = tally()
	if total == 0 then
		state.Vote = nil -- everyone left: back to waiting
		return false
	end
	if os.clock() < v.Ends and normal + hard < total then
		sendVote()
		return true
	end
	-- more votes for HARD than NORMAL makes it a hard night (a tie stays normal)
	local diff = hard > normal and "Hard" or "Normal"
	workspace:SetAttribute("Difficulty", diff)
	v.Result = diff
	v.StartAt = os.clock() + 2
	for _, p in Players:GetPlayers() do
		ctx.Remotes.Vote:FireClient(p, { Result = diff, Normal = normal, Hard = hard, Total = total })
	end
	return true
end
Director._voteTick = voteTick -- (tests)
Director._beginVote = beginVote

-- a group's own server: start as soon as the whole group has arrived (or after a timeout)
local function arrivalTick()
	local players = Players:GetPlayers()
	if #players == 0 then
		return
	end
	state.FirstArrival = state.FirstArrival or os.clock()
	local expected = math.max(state.Expected or 1, 1)
	if not state.Countdown then
		if #players >= expected or os.clock() - state.FirstArrival >= ctx.Config.Lobby.ArrivalTimeout then
			state.Countdown = 4
		end
	else
		state.Countdown -= 1
	end
	broadcastLobby()
	if state.Countdown and state.Countdown <= 0 then
		beginVote()
	end
end

local function lobbyTick()
	if voteTick() then
		return
	end
	if ctx.Reserved then
		arrivalTick()
		return
	end
	local players = Players:GetPlayers()
	local readyCount = 0
	for _, p in players do
		if state.Ready[p] then
			readyCount += 1
		end
	end
	local allReady = #players > 0 and readyCount >= math.min(#players, ctx.Config.MaxPlayers) and readyCount >= ctx.Config.MinPlayers
	if allReady then
		if not state.Countdown then
			state.Countdown = ctx.Config.Debug and 3 or ctx.Config.LobbyCountdown
		else
			state.Countdown -= 1
		end
		broadcastLobby()
		if state.Countdown <= 0 then
			beginVote()
		end
	elseif state.Countdown then
		state.Countdown = nil
		broadcastLobby()
	end
end

---------------------------------------------------------------------------
-- Acts
---------------------------------------------------------------------------
local function setGap()
	local gap = ctx.Config.Director.Gap[state.Act]
	if gap then
		state.NextEventAt = os.clock() + (gap[1] + math.random() * (gap[2] - gap[1])) * math.max(ctx.Config.TimeScale, 0.35)
	end
end

function Director.startAct(name: string, cause: Player?)
	state.Act = name
	state.ActStart = os.clock()
	state.ActEnding = false
	workspace:SetAttribute("Act", name)
	local card = ctx.Story.Chapters[name]
	if card then
		ctx.Remotes.Chapter:FireAllClients(card.Title, card.Sub)
	end
	ctx.Escape.refreshLandline()
	setGap()

	state.NextHintAt = os.clock() + ctx.Config.Thoughts.FirstHint + 10
	local actLines = ctx.Story.Thoughts.Acts[name]
	if actLines then
		-- act II waits for the pizza place's call; the others start right after the chapter card
		task.delay(name == "SmallThings" and 5 or 7, function()
			for _, line in actLines do
				Director.think(nil, line)
			end
		end)
	end

	if name == "Evening" then
		workspace:SetAttribute("Delivery", nil)
		for _, p in ctx.Util.sessionPlayers() do
			for _, a in { "NightHides", "NightSpotted", "NightCaught", "NightRescues" } do
				p:SetAttribute(a, 0)
			end
		end
		ctx.Objectives.set({ "OrderPizza", "Popcorn", "Windows" })
		ctx.Intruder.setMode("Offstage")
		state.NextHintAt = os.clock() + ctx.Config.Thoughts.FirstHint
		local session = ctx.Util.sessionPlayers()
		local solo = #session == 1
		for _, p in session do
			local lines = solo and ctx.Story.Thoughts.SoloIntro or ctx.Story.Thoughts.Intro[p:GetAttribute("Role") == "Host" and "Host" or "Guest"]
			for _, line in lines do
				Director.think(p, line)
			end
		end
		-- alone: the friends text that the flooded road turned them back
		if solo then
			local myState = state
			task.delay(24, function()
				if state ~= myState or state.Act ~= "Evening" then
					return
				end
				for _, t in ctx.Story.SoloTexts do
					for _, p in ctx.Util.sessionPlayers() do
						ctx.Phone.deliver(p, t.From, t.Body)
					end
					task.wait(6)
				end
				task.wait(4)
				Director.think(nil, ctx.Story.Thoughts.SoloFriendsStuck)
			end)
		end
	elseif name == "SmallThings" then
		ctx.Objectives.set({ "LockUp" })
	elseif name == "SomeoneElse" then
		ctx.Objectives.set({ "Phone", "Attic", "Power" }, { Power = true })
		checkHeldItems()
		task.delay(7, function()
			if state.Act ~= "SomeoneElse" then
				return
			end
			-- the breaker: all at once, no flicker
			ctx.Power.setMain(false, "Intruder")
			ctx.Audio.playAt("Breaker", Vector3.new(41, 8, -12.7))
			ctx.Audio.playAt("PowerDown", Vector3.new(0, 8, 0))
			ctx.PlayerState.scareNear(Vector3.new(0, 8, 0), 300, 8)
			Director.logTruth("PowerOut")
			ctx.Escape.cutLine()
			if ctx.Escape.stealKeys() then
				Director.logTruth("KeysTaken")
			end
			local refs = ctx.World.refs()
			if refs.openGarageHatch then
				refs.openGarageHatch()
			end
			if refs.Footprints then
				refs.Footprints.show()
			end
			task.wait(4)
			ctx.Intruder.setMode("Lurk")
			-- first night ever: how to survive, once
			for _, p in ctx.Util.sessionPlayers() do
				if (tonumber(p:GetAttribute("StatNights")) or 0) == 0 and not p:GetAttribute("SawSurvivalTips") then
					p:SetAttribute("SawSurvivalTips", true)
					ctx.Remotes.Notice:FireClient(p, ctx.Story.SurvivalTips)
				end
			end
			task.wait(6)
			ctx.Remotes.Notify:FireAllClients("That wasn't the storm. Something flipped the main breaker.", "danger")
			-- a glimpse or two of him in the dark, then the hunt begins
			local myState = state
			task.wait(ctx.Config.Director.HuntDelay or 35)
			if state == myState and state.Act == "SomeoneElse" then
				ctx.Intruder.setMode("Hunt")
				Director.addTension(30)
			end
		end)
	elseif name == "Guest" then
		ctx.Objectives.set({ "Call911", "Neighbor", "Car", "Trap" }, { Neighbor = true, Car = true, Trap = true })
		checkHeldItems()
		if ctx.Capture.captiveCount() > 0 then
			ctx.Objectives.add("Rescue", true)
		end
		ctx.Intruder.setMode("Hunt", cause)
		Director.addTension(30)
		Director.think(nil, "Somewhere in the house, something heavy hits the floor.")
		Director.think(nil, "He knows.")
	end
end

local function nextAct()
	local i = table.find(ACT_ORDER, state.Act)
	if i and ACT_ORDER[i + 1] then
		Director.startAct(ACT_ORDER[i + 1])
	end
end

-- a clue read by anyone in the group counts toward the secret ending
function Director.onDocument(player: Player, docId: string)
	if not table.find(ctx.Story.Evidence, docId) or state.Evidence[docId] then
		return
	end
	state.Evidence[docId] = true
	local n = Director.evidenceCount()
	for _, p in ctx.Util.sessionPlayers() do
		ctx.Remotes.Notify:FireClient(p, string.format("Evidence %d / %d", n, #ctx.Story.Evidence), n >= ctx.Story.EvidenceNeeded and "done" or "info")
	end
end

function Director.evidenceCount(): number
	local n = 0
	for _ in state.Evidence do
		n += 1
	end
	return n
end

function Director.onDiscovery(player: Player, docId: string)
	ctx.Objectives.step("Attic", "Search")
	Director.logTruthRaw((player:GetAttribute("RoleName") or player.Name) .. " found the nest in the attic.")
	if state.Act == "SomeoneElse" and not state.Discovered and not ctx.Escape.helpCalled() then
		state.Discovered = true
		task.delay(4, function()
			if state.Act == "SomeoneElse" then
				Director.startAct("Guest", player)
			end
		end)
	end
end

---------------------------------------------------------------------------
-- Hooks from services
---------------------------------------------------------------------------
function Director.onCapture(player: Player)
	Director.addTension(25)
	if state.Act == "Guest" then
		ctx.Objectives.add("Rescue", true)
	end
	task.delay(4, function()
		Director.think(player, ctx.Story.Thoughts.Captured)
	end)
	Director.logTruthRaw("Curtis took " .. (player:GetAttribute("RoleName") or player.Name) .. " down to the boiler room.")
	task.delay(2, Director.checkAllCaptured)
end

function Director.onRescue(player: Player, by: Player?)
	if by then
		Director.logTruthRaw((by:GetAttribute("RoleName") or by.Name) .. " cut " .. (player:GetAttribute("RoleName") or player.Name) .. " free.")
	else
		Director.logTruthRaw((player:GetAttribute("RoleName") or player.Name) .. " broke free of the zip ties.")
	end
	ctx.Objectives.complete("Rescue")
end

function Director.onSighting(player: Player)
	Director.addTension(15)
	player:SetAttribute("NightSpotted", (tonumber(player:GetAttribute("NightSpotted")) or 0) + 1)
	if state.Act == "SomeoneElse" then
		Director.logTruth("Glimpse")
		Director.thinkOnce(player, "Glimpse", ctx.Story.Thoughts.Events.Glimpse)
	end
end

function Director.onDoorOpened(door, player: Player)
	if door.Id == "BackDoor" and (state.Act == "Evening" or state.Act == "SmallThings") then
		Director.logTruth("BackDoorUnlocked")
	end
	-- he's right on the other side, holding the handle: the door is torn back out of your hand
	-- (rare: once every few minutes at most, and only if he really is there, unseen)
	local ip = ctx.Intruder.position()
	local lurking = ctx.Intruder.getState() == "Lurk" and os.clock() >= (state.NextDoorHeld or 0)
	-- right there and unseen, or hidden somewhere in the house (then only now and then, and only
	-- an inside door: that's where he moves between rooms)
	local behindIt = ip and (ip - door.Position).Magnitude < 14 and not Perception.anyoneSees(ip)
	local hiddenNear = not ip and not door.Exterior and math.random() < 0.18
	if lurking and (behindIt or hiddenNear) then
		state.NextDoorHeld = os.clock() + 240
		task.delay(0.4, function()
			if not door.IsOpen then
				return
			end
			ctx.Doors.slamShut(door)
			ctx.Remotes.PlaySound:FireClient(player, "Stinger", nil, { Volume = 1 })
			ctx.Remotes.Shake:FireClient(player, 0.7, 0.6)
			ctx.PlayerState.addNerve(player, -18)
			ctx.Intruder.spook()
			Director.logTruth("DoorHeld")
		end)
	end
end

-- Act II: Mom texts about the news report, you text back, then go watch channel 7
function Director.startMomNews()
	if state.MomNews or state.Act ~= "SmallThings" then
		return
	end
	state.MomNews = true
	local M = ctx.Story.MomNews
	local myState = state
	task.spawn(function()
		for _, line in M.Texts do
			if state ~= myState then
				return
			end
			for _, p in ctx.Util.sessionPlayers() do
				ctx.Phone.deliver(p, "Mom", line)
			end
			task.wait(5.5)
		end
		if state ~= myState then
			return
		end
		ctx.Objectives.add("News")
		-- the TV may already be on (or even on 7): tick off what's already done
		local tv = ctx.World.refs().TV
		if tv and tv.On then
			ctx.Objectives.step("News", "TV")
		end
		for _, p in ctx.Util.sessionPlayers() do
			ctx.Phone.ask(p, "Mom", M.Ask, function(i)
				task.wait(2.5)
				if state == myState then
					ctx.Phone.deliver(p, "Mom", M.Answers[i] or M.Answers[1])
					task.wait(3)
					ctx.Phone.deliver(p, "Mom", M.After)
				end
			end)
		end
	end)
end

-- the report has been on long enough for the people in front of the TV to take it in
function Director.onNewsWatched(watchers: { Player })
	local M = ctx.Story.MomNews
	local myState = state
	for _, line in M.Thoughts do
		Director.think(watchers, line)
	end
	Director.logTruthRaw("You watched the 7 News report about a man living inside Hollis Creek homes.")
	task.delay(14, function()
		if state ~= myState then
			return
		end
		for _, p in ctx.Util.sessionPlayers() do
			ctx.Phone.ask(p, "Mom", M.AskAfter, function(i)
				task.wait(2.5)
				if state == myState then
					ctx.Phone.deliver(p, "Mom", M.AnswersAfter[i] or M.AnswersAfter[1])
				end
			end)
		end
	end)
end

function Director.onDoorLockChanged(door, player: Player)
	if door.Locked and (door.Id == "BackDoor" or door.Id == "GarageSide") then
		ctx.Objectives.step("LockUp", door.Id)
		if ctx.Objectives.isDone("LockUp") and state.Act == "SmallThings" then
			task.delay(5, Director.startMomNews)
		end
	end
	if door.Id == "BackDoor" and door.Locked and (state.Act == "Evening" or state.Act == "SmallThings") then
		Director.logTruth("BackDoorUnlocked")
	end
	if door.Id == "Basement" and door.Locked and not door.IsOpen and ctx.Intruder.isInBasement() then
		if ctx.Intruder.trap() then
			ctx.Objectives.complete("Trap")
			Director.logTruthRaw((player:GetAttribute("RoleName") or player.Name) .. " locked Curtis in the basement.")
			ctx.Remotes.Notify:FireAllClients("He's locked in the basement. It won't hold him forever.", "objective")
		end
	end
end

function Director.checkAllCaptured()
	if state.Act == "Lobby" or ctx.Ending.isOver() then
		return
	end
	local session = ctx.Util.sessionPlayers()
	if #session == 0 then
		return
	end
	local anyCaptured, anyEscaped = false, false
	for _, p in session do
		if p:GetAttribute("Captured") then
			anyCaptured = true
		end
		if p:GetAttribute("Escaped") then
			anyEscaped = true
		end
	end
	-- someone got out (the car, next door): their ending is already on its way
	if #ctx.Util.activePlayers() == 0 and anyCaptured and not anyEscaped then
		-- everyone is tied up: one last chance to struggle free before it's over (nobody left who
		-- can struggle: it's over now, police on the way or not)
		local canStruggle = false
		for _, p in session do
			if p:GetAttribute("Captured") and not p:GetAttribute("Dead") then
				canStruggle = true
			end
		end
		if not canStruggle then
			-- (cuts short a last chance already running: the last one who could struggle is gone)
			state.GoneQuietAt = math.min(state.GoneQuietAt or math.huge, os.clock() + 4)
			return
		end
		if not state.GoneQuietAt then
			local hard = ctx.Config.Difficulty and ctx.Config.Difficulty.Hard
			local lastChance = (workspace:GetAttribute("Difficulty") == "Hard" and hard and hard.LastChance) or ctx.Config.Capture.LastChance or 45
			state.GoneQuietAt = os.clock() + lastChance
			local line = ctx.Escape.helpCalled() and "He's getting away. Struggle free before he's gone!"
				or "Nobody's coming. Struggle free before he comes back!"
			for _, p in session do
				if not p:GetAttribute("Dead") then
					ctx.Remotes.Notify:FireClient(p, line, "danger")
				end
			end
		end
	else
		state.GoneQuietAt = nil
	end
end

-- everyone taken: with help on the way he slips out before it arrives; without, nobody comes
function Director.lostEnding(): string
	return ctx.Escape.helpCalled() and "GotAway" or "GoneQuiet"
end

local function lastChanceTick()
	if state.GoneQuietAt then
		if #ctx.Util.activePlayers() > 0 then
			state.GoneQuietAt = nil
		elseif os.clock() >= state.GoneQuietAt and not ctx.Ending.isOver() and not (ctx.Ending.reviveOpen and ctx.Ending.reviveOpen()) then
			state.GoneQuietAt = nil
			ctx.Ending.trigger(Director.lostEnding())
		end
	end
end
Director._lastChanceTick = lastChanceTick -- (tests)

---------------------------------------------------------------------------
-- Scheduling
---------------------------------------------------------------------------
local function eventById(id: string)
	for _, e in Events.List do
		if e.Id == id then
			return e
		end
	end
	return nil
end

local function canFire(e): boolean
	if not e.Acts[state.Act] then
		return false
	end
	-- once he's out hunting, the house stops playing tricks: he can't be in two places at once
	if not e.DuringHunt and ctx.Intruder.isHunting() then
		return false
	end
	if e.Once and state.Fired[e.Id] then
		return false
	end
	if e.Cooldown and state.LastFired[e.Id] and os.clock() - state.LastFired[e.Id] < e.Cooldown * math.max(ctx.Config.TimeScale, 0.35) then
		return false
	end
	return true
end

local function fire(e, data)
	state.Fired[e.Id] = true
	state.LastFired[e.Id] = os.clock()
	Director.addTension(e.Tension or 5)
	if ctx.Config.Debug then
		print("[Director] event " .. e.Id)
	end
	task.spawn(function()
		local ok, err = pcall(e.Run, ctx, D, data)
		if not ok then
			warn("[Director] event " .. e.Id .. " failed: " .. tostring(err))
		end
	end)
	-- friends standing together react out loud a moment later (Story.Banter.React)
	if Director.reactBanter then
		task.delay(7, function()
			if Director.isQuiet() then
				Director.reactBanter(e.Id)
			end
		end)
	end
end

local function tryEvent(e, force: boolean?): boolean
	local ok, data = pcall(e.Cond, ctx, D)
	if (not ok or data == nil) and force and e.Force then
		ok, data = pcall(e.Force, ctx, D)
	end
	if ok and data ~= nil then
		-- something he does in person: it only happens where he really is, and never in view
		if e.Where and ctx.Intruder.isInHouse() then
			local ip = ctx.Intruder.position()
			local okW, where = pcall(e.Where, ctx, data)
			if not ip or not okW or not where or (where - ip).Magnitude > (e.Reach or 18) or D.Perception.anyoneSees(ip) then
				return false
			end
		end
		fire(e, data)
		return true
	end
	return false
end

local function beatsDone(): boolean
	for _, b in BEATS[state.Act] or {} do
		if not state.Fired[b[1]] then
			return false
		end
	end
	return true
end

local function schedule(actTime: number)
	local maxT = scaled(ctx.Config.Acts[state.Act] and ctx.Config.Acts[state.Act].Max or 15)
	-- overdue guaranteed beats go first (and ignore the ceiling)
	for _, b in BEATS[state.Act] or {} do
		local e = eventById(b[1])
		if e and not state.Fired[e.Id] and actTime >= b[2] * maxT and canFire(e) then
			if tryEvent(e, true) then
				setGap()
				return
			end
		end
	end
	if os.clock() < state.NextEventAt or not Director.isQuiet() then
		return
	end
	local ceiling = ctx.Config.Director.Ceiling[state.Act] or 50
	if state.Tension >= ceiling then
		return
	end
	local pool = {}
	for _, e in Events.List do
		if canFire(e) then
			table.insert(pool, { e, e.Weight or 1 })
		end
	end
	-- try up to three picks until one's conditions hold
	for _ = 1, 3 do
		local e = ctx.Util.weighted(pool)
		if not e then
			break
		end
		if tryEvent(e) then
			break
		end
		for i, entry in pool do
			if entry[1] == e then
				table.remove(pool, i)
				break
			end
		end
	end
	setGap()
end

-- "Check upstairs": done once somebody walks up to the attic hatch
local function investigateTick()
	if not ctx.Objectives.has("Investigate") or ctx.Objectives.isDone("Investigate") then
		return
	end
	local h = ctx.Layout.AtticHatch
	local spot = Vector3.new((h.x0 + h.x1) / 2, ctx.Layout.Y.Upstairs + 3, (h.z0 + h.z1) / 2)
	for _, p in ctx.Util.activePlayers() do
		local root = ctx.Util.getRoot(p)
		if root and (root.Position - spot).Magnitude < 10 then
			ctx.Objectives.complete("Investigate")
			Director.think(p, ctx.Story.Thoughts.Events.InvestigateDone)
			task.delay(2.5, function()
				ctx.Audio.playAt("HatchCreak", spot + Vector3.new(0, 11, 0), { Volume = 1 })
			end)
			return
		end
	end
end

-- The friends talking among themselves (Story.Banter): cast the scene's slots from players
-- standing together, then play it in the dialogue box for everyone nearby.
local function castBanter(scene)
	local players = ctx.Util.activePlayers()
	if #players < 2 then
		return nil
	end
	for _, anchor in players do
		local aRoot = ctx.Util.getRoot(anchor)
		if not aRoot then
			continue
		end
		local group = {}
		for _, p in players do
			local r = ctx.Util.getRoot(p)
			if r and (r.Position - aRoot.Position).Magnitude <= 45 then
				table.insert(group, p)
			end
		end
		if #group < 2 then
			continue
		end
		local free = table.clone(group)
		local cast = {}
		local function take(pred)
			for i, p in free do
				if pred(p) then
					table.remove(free, i)
					return p
				end
			end
			return nil
		end
		local ok = true
		local lines = {}
		for _, l in scene.Lines do
			local slot = l[1]
			if not cast[slot] then
				if slot == "Host" then
					cast[slot] = take(function(p)
						return p:GetAttribute("Role") == "Host"
					end) or take(function()
						return true
					end)
				else
					-- numbered slots prefer the friends, so Jamie is free for the "Host" lines
					cast[slot] = take(function(p)
						return p:GetAttribute("Role") ~= "Host"
					end) or take(function()
						return true
					end)
				end
			end
			if cast[slot] then
				table.insert(lines, { Speaker = cast[slot], Text = l[2] })
			elseif not l.Optional then
				ok = false
				break
			end
		end
		local speakers = {}
		for _, l in lines do
			speakers[l.Speaker] = true
		end
		local n = 0
		for _ in speakers do
			n += 1
		end
		if ok and n >= 2 then
			local audience = {}
			for _, p in ctx.Util.sessionPlayers() do
				local r = ctx.Util.getRoot(p)
				if r and (r.Position - aRoot.Position).Magnitude <= 70 then
					table.insert(audience, p)
				end
			end
			return lines, audience
		end
	end
	return nil
end

-- a spoken reaction to an event, if people are together to say it (once per event per night)
function Director.reactBanter(id: string)
	local react = ctx.Story.Banter and ctx.Story.Banter.React
	local scene = react and react[id]
	if not scene or state.BanterDone["React" .. id] or (ctx.Dialogue and ctx.Dialogue.isActive()) then
		return
	end
	local lines, audience = castBanter(scene)
	if lines then
		state.BanterDone["React" .. id] = true
		task.spawn(ctx.Dialogue.say, lines, audience)
	end
end

function Director.banterTick(actTime: number)
	local scenes = ctx.Story.Banter and ctx.Story.Banter[state.Act]
	if not scenes or not Director.isQuiet() then
		return
	end
	for i, scene in scenes do
		local key = state.Act .. i
		if state.BanterDone[key] or actTime < scene.At * ctx.Config.TimeScale then
			continue
		end
		local lines, audience = castBanter(scene)
		if lines then
			state.BanterDone[key] = true
			task.spawn(ctx.Dialogue.say, lines, audience)
		elseif actTime > (scene.At + 120) * ctx.Config.TimeScale then
			state.BanterDone[key] = true -- nobody was together to say it; let it go
		end
		return
	end
end

local function actTick()
	local actTime = os.clock() - state.ActStart
	local cfg = ctx.Config.Acts[state.Act]
	workspace:SetAttribute("ClockMinutes", Director.clockMinutes())
	ctx.Phone.update(state.Act, actTime, Director.isQuiet())
	Director.banterTick(actTime)

	-- tension decays
	state.Tension = math.max(0, state.Tension - ctx.Config.Director.TensionDecay)
	workspace:SetAttribute("Tension", math.floor(state.Tension))

	-- storm
	if os.clock() >= state.NextLightning then
		local L = ctx.Config.Director.Lightning
		state.NextLightning = os.clock() + L[1] + math.random() * (L[2] - L[1])
		Director.lightning()
	end

	schedule(actTime)
	hintTick()
	lastChanceTick()
	-- first visits to each room in the first act get a line of their own
	if state.Act == "Evening" and Director.isQuiet() then
		for _, p in ctx.Util.activePlayers() do
			local root = ctx.Util.getRoot(p)
			local room = root and ctx.Rooms.find(root.Position)
			local set = ctx.Story.RoomThoughts[p:GetAttribute("Role") == "Host" and "Host" or "Guest"]
			local line = room and set and set[room.Name]
			if line then
				local seen = state.Thought and state.Thought[p]
				if not (seen and seen["Room_" .. room.Name]) then
					Director.thinkOnce(p, "Room_" .. room.Name, line)
					break -- one at a time
				end
			end
		end
	end
	investigateTick()

	-- hard cap
	if elapsed() >= scaled(ctx.Config.HardCapMinutes) and not ctx.Escape.helpCalled() then
		Director.logTruthRaw("Dawn. A neighbor on Birch Street reported the van.")
		ctx.Escape.dawn()
		return
	end

	if state.ActEnding or not cfg then
		return
	end
	local minT, maxT = scaled(cfg.Min), scaled(cfg.Max)
	local done = false
	if state.Act == "Evening" then
		-- once the chores are done (or it's getting late) the pizza arrives; the act ends when
		-- the delivery man has gone
		if not state.Delivery and ((ctx.Objectives.allRequiredDone() and actTime >= 10) or actTime >= maxT) then
			state.Delivery = true
			state.DeliveryAt = os.clock()
			local myState = state
			task.delay(5, function()
				if state ~= myState then
					return
				end
				local ok, err = pcall(Delivery.run, ctx, D, function()
					myState.DeliveryDone = true
				end)
				if not ok then
					warn("[Director] delivery failed: " .. tostring(err))
					myState.DeliveryDone = true
				end
			end)
		end
		done = state.DeliveryDone == true or (state.DeliveryAt ~= nil and os.clock() - state.DeliveryAt > 240)
	elseif state.Act == "SmallThings" then
		-- Mom's news texts come once the house is locked (or, if nobody gets round to it, partway
		-- through the act); the act waits for the report to be watched
		if not state.MomNews and actTime >= maxT * 0.55 then
			Director.startMomNews()
		end
		local newsDone = state.MomNews and (not ctx.Objectives.has("News") or ctx.Objectives.isDone("News"))
		done = (actTime >= minT and beatsDone() and state.Tension < ctx.Config.Director.SmallThingsQuiet and newsDone) or (actTime >= maxT and newsDone) or actTime >= maxT + 120
	elseif state.Act == "SomeoneElse" then
		done = actTime >= maxT and not ctx.Escape.helpCalled()
	end
	if done then
		state.ActEnding = true
		nextAct()
	end
end

---------------------------------------------------------------------------
function Director.start()
	ctx.PlayerState.setSpawnResolver(spawnFor)
	workspace:SetAttribute("Act", "Lobby")
	workspace:SetAttribute("ClockMinutes", ctx.Config.ClockStartMinutes)

	ctx.Remotes.CastVote.OnServerEvent:Connect(function(player, choice)
		local v = state.Vote
		if not v or v.Result or (choice ~= "Normal" and choice ~= "Hard") then
			return
		end
		v.Votes[player] = choice
		sendVote()
	end)
	-- the "pick your role" pass: which friend you want to be tonight
	ctx.Remotes.PickRole.OnServerEvent:Connect(function(player, roleId)
		if player:GetAttribute("Pass_ChooseRole") ~= true or type(roleId) ~= "string" then
			return
		end
		for _, r in ctx.Story.Roles do
			if r.Id == roleId then
				player:SetAttribute("WantRole", roleId)
				return
			end
		end
	end)
	ctx.Remotes.Ready.OnServerEvent:Connect(function(player, ready)
		if state.Act ~= "Lobby" then
			return
		end
		state.Ready[player] = ready == true or nil
		broadcastLobby()
	end)

	local function readPartySize(p: Player)
		local ok, data = pcall(function()
			return p:GetJoinData()
		end)
		local td = ok and data and data.TeleportData
		if type(td) == "table" and tonumber(td.PartySize) then
			state.Expected = math.max(state.Expected or 0, math.clamp(tonumber(td.PartySize) :: number, 1, ctx.Config.MaxPlayers))
		end
	end
	for _, p in Players:GetPlayers() do
		readPartySize(p)
	end
	Players.PlayerAdded:Connect(function(p)
		readPartySize(p)
		task.wait(1.5)
		ctx.Remotes.Lobby:FireClient(p, lobbyPayload())
		if state.Act == "Evening" and #ctx.Util.sessionPlayers() < ctx.Config.MaxPlayers then
			-- late arrival during the cozy part: join the night
			p:SetAttribute("InGame", true)
			ctx.PlayerState.assignRoles({ p })
			local char = p.Character
			if char then
				char:PivotTo(spawnFor(p) :: CFrame)
			end
			ctx.Remotes.Notify:FireClient(p, "You made it just in time. The others are inside.", "info")
		elseif state.Act ~= "Lobby" then
			ctx.Remotes.Notify:FireClient(p, "A night is already under way. You'll join the next one.", "info")
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		state.Ready[p] = nil
		if state.Act == "Lobby" then
			task.defer(broadcastLobby)
			return
		end
		task.defer(function()
			if #Players:GetPlayers() == 0 or #ctx.Util.sessionPlayers() == 0 then
				ctx.restart()
			else
				Director.checkAllCaptured()
			end
		end)
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			local ok, err = pcall(function()
				if state.Act == "Lobby" then
					lobbyTick()
				elseif not ctx.Ending.isOver() then
					actTick()
				end
			end)
			if not ok then
				warn("[Director] " .. tostring(err))
			end
		end
	end)
end

return Director
