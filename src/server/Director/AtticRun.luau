--[[
	AtticRun (v154, the owner: "The whole experience is still very short and just gets it over with... add new parts to make
	it longer"; of the parts offered, the owner picked "Into the attic").

	The first 911 call from the upstairs bathroom window gets through to the dispatcher, then drops: zero bars. The one bar
	by that window came from Dad's signal booster in the attic, and someone has pulled its plug. The way out is up through
	the hatch, into his nest (the photos of the family, the tally marks, his bed), to plug the booster back in. Its light
	goes green, full bars up there... and the ladder creaks. His head comes up through the hatch; he hunts whoever is in
	the attic. Hide (under the dust sheet, in the old trunk), then make the call from up there.

	• PhoneService asks `onCallThrough` before a cell call becomes help; the first one from the window drops instead.
	• `SignalDead` (workspace) zeroes every bar while the booster is out; `BoosterOn` gives full bars in the attic
	  (PlayerState computeSignal).
	• He can't walk up the ladder (no route), so he comes up through the hatch as a scene; once nobody's left up there
	  he's put back down it.
	• The landline, next door and the car still work as before; Mrs. Okafor still calls if nobody does.
]]

local AtticRun = {}
local ctx
local state
local booster: BasePart? = nil
local led: BasePart? = nil
local plugPrompt: ProximityPrompt? = nil
local callPrompt: ProximityPrompt? = nil

local RED = Color3.fromRGB(220, 40, 30)
local GREEN = Color3.fromRGB(60, 230, 90)

local function cfg()
	return ctx.Config.Attic or {}
end

function AtticRun.init(c)
	ctx = c
	ctx.AtticRun = AtticRun
	AtticRun.reset()
end

local function refresh()
	if led then
		led.Color = state.Fixed and GREEN or RED
		led.Material = Enum.Material.Neon
	end
	if plugPrompt then
		plugPrompt.Enabled = state.Dropped and not state.Fixed
	end
	if callPrompt then
		callPrompt.Enabled = state.Fixed and not ctx.Escape.helpCalled()
	end
end

function AtticRun.reset()
	state = { Dropped = false, Fixed = false, HeUp = false, Night = {}, Searched = {}, HideUntil = nil }
	workspace:SetAttribute("SignalDead", nil)
	workspace:SetAttribute("BoosterOn", nil)
	refresh()
end

function AtticRun.enabled(): boolean
	return cfg().Enabled ~= false
end

-- the call from the window has dropped and the booster is still out
function AtticRun.pending(): boolean
	return state.Dropped and not state.Fixed
end

function AtticRun.state()
	return state
end

local function inAttic(p: Player): boolean
	local root = ctx.Util.getRoot(p)
	return root ~= nil and ctx.Rooms.floorOf(root.Position) == "Attic"
end

local function everyone(): { Player }
	return ctx.Util.sessionPlayers()
end

-- (v157) will this call be the one that drops? (PhoneService cuts it off partway through instead of playing it all out: the owner,
-- "you're having a conversation with 911 and then they start again from 911 what's your emergency just to cut off")
function AtticRun.willDrop(player: Player): boolean
	return AtticRun.enabled() and not state.Dropped and not state.Fixed and not ctx.Escape.helpCalled() and not inAttic(player)
end

-- (v157) the call from the attic is the dispatcher calling back where she lost you, not a new call
function AtticRun.redial(): boolean
	return state.Dropped == true
end

-- PhoneService: a cell call has just got through (or, v157, been cut off partway). true = it dropped (the attic part begins)
-- instead of bringing help
function AtticRun.onCallThrough(player: Player): boolean
	if not AtticRun.willDrop(player) then
		return false
	end
	state.Dropped = true
	workspace:SetAttribute("SignalDead", true)
	-- (v155) a head start for everyone at the window: the drop is where they died (the bathroom: 1,393 captures)
	local grace = if workspace:GetAttribute("Difficulty") == "Hard" then (cfg().DropGraceHard or 0) else (cfg().DropGrace or 0)
	local here = ctx.Util.getRoot(player)
	if grace > 0 and ctx.Intruder and ctx.Intruder.spare then
		for _, p in ctx.Util.activePlayers() do
			local r = ctx.Util.getRoot(p)
			if p == player or (here and r and (r.Position - here.Position).Magnitude < 14) then
				ctx.Intruder.spare(p, grace)
			end
		end
	end
	ctx.Audio.caption("[Static] CALL DROPPED. No Service.", nil, nil, { player })
	task.delay(2.4, function()
		if state.Dropped and not state.Fixed then
			ctx.Director.think(nil, ctx.Story.Thoughts.BoosterDead)
		end
	end)
	-- the window's call is off; the attic's is on
	ctx.Objectives.dismiss("Call911")
	ctx.Objectives.dismiss("Attic")
	ctx.Objectives.add("Booster")
	if workspace:GetAttribute("AtticHatchOpen") then
		ctx.Objectives.step("Booster", "Hatch")
	end
	if ctx.Journey and ctx.Journey.team then
		ctx.Journey.team("AtticDrop")
	end
	ctx.Director.logTruthRaw("The call dropped: the booster in the attic had been unplugged.")
	refresh()
	return true
end

-- the hatch came down (House)
function AtticRun.hatchOpened()
	workspace:SetAttribute("AtticHatchOpen", true)
	if AtticRun.pending() then
		ctx.Objectives.step("Booster", "Hatch")
	end
end

-- (the Director's objective lists: while the booster's out, "call 911" means the attic)
function AtticRun.callObjective(): string
	return AtticRun.pending() and "Booster" or "Call911"
end

-- put him back down the hatch (nobody left up there to hunt)
local function bringDown()
	local I = ctx.Intruder
	local L = ctx.Layout
	local below = L.Attic.HatchBelow or Vector3.new(6, 18.2, 4)
	if I and I.climbInto then
		ctx.Audio.playAt("HatchCreak", L.Attic.HatchTop, { CaptionText = "[The ladder creaks. Something going down]", CaptionRange = 40 })
		I.climbInto(below, below + Vector3.new(0, 0, -10), nil)
	end
	state.HeUp = false -- (v155: he can come up again)
	state.Searched = {}
	if state.HideUntil then
		state.HideUntil = nil
		ctx.Objectives.dismiss("AtticHide")
	end
end

-- (v158) he's on the ladder on his own (the navigator routes through the hatch now): warn whoever's up there, once a climb
function AtticRun.ladder()
	if not state or state.HeUp then
		return
	end
	state.HeUp = true
	local up = {}
	for _, p in everyone() do
		if inAttic(p) then
			table.insert(up, p)
		end
	end
	if #up > 0 then
		ctx.Director.think(up, ctx.Story.Thoughts.OnTheLadder)
		ctx.Objectives.add("AtticHide", nil, up) -- (v160: only for whoever is up there)
		state.HideUntil = os.clock() + (cfg().LadderUp or 3) + (cfg().HideMarkers or 22)
		ctx.Director.logTruth("AtticHunt")
	end
end

-- (v158) he went back down the ladder by himself
function AtticRun.downAgain()
	if not state then
		return
	end
	state.HeUp = false
	state.Searched = {}
	if state.HideUntil then
		state.HideUntil = nil
		ctx.Objectives.dismiss("AtticHide")
	end
end

-- he heard the booster: up the ladder, through the hatch, into the attic after whoever's there
local function heComes(by: Player)
	if state.HeUp then
		return
	end
	state.HeUp = true
	local night = state
	local L = ctx.Layout
	local top = L.Attic.HatchTop
	ctx.Audio.playAt("HatchCreak", top, { CaptionText = "[The ladder creaks. Someone is climbing up]", CaptionRange = 60 })
	local up = {}
	for _, p in everyone() do
		if inAttic(p) then
			table.insert(up, p)
		end
	end
	if #up > 0 then
		ctx.Director.think(up, ctx.Story.Thoughts.OnTheLadder)
		-- (v157) the "!" on every hiding spot up here until he's been up a while
		ctx.Objectives.add("AtticHide", nil, up) -- (v160: only for whoever is up there)
		state.HideUntil = os.clock() + (cfg().ClimbDelay or 4) + (cfg().HideMarkers or 22)
	end
	task.delay(cfg().ClimbDelay or 4, function()
		if state ~= night or ctx.Ending.isOver() then
			return
		end
		local target = nil
		for _, p in everyone() do
			if inAttic(p) and not p:GetAttribute("Captured") then
				target = p
				break
			end
		end
		if not target then
			-- (they got down in time: he doesn't come up)
			state.HeUp = false
			return
		end
		local I = ctx.Intruder
		if I and I.climbInto then
			-- his head and shoulders up through the hatch, a beat, then all of him
			ctx.Audio.playAt("DeepGrowl", top, { Caption = false })
			I.climbInto(top + Vector3.new(0, 0.2, 0), (ctx.Util.getRoot(target) :: BasePart).Position, target)
			ctx.Director.logTruth("AtticHunt")
			if ctx.Journey and ctx.Journey.event then
				ctx.Journey.event(target, "AtticHunt")
			end
		end
	end)
end

-- the booster in his nest: plug it in (while the call has dropped), then call from it
function AtticRun.setup(part: BasePart, light: BasePart)
	booster, led = part, light
	ctx.Objectives.setTarget("Booster", part.Position)
	plugPrompt = ctx.Interaction.prompt(part, {
		Name = "PlugBooster",
		Action = "Plug in",
		Object = "Signal booster",
		Hold = cfg().PlugHold or 1.2,
		Distance = 7,
	}, function(player)
		if not AtticRun.pending() then
			return
		end
		state.Fixed = true
		workspace:SetAttribute("SignalDead", nil)
		workspace:SetAttribute("BoosterOn", true)
		ctx.Audio.playAt("CountBeep", part.Position, { Caption = false })
		ctx.Objectives.step("Booster", "Plug")
		local here = {}
		for _, p in everyone() do
			if inAttic(p) then
				table.insert(here, p)
			end
		end
		ctx.Director.think(#here > 0 and here or { player }, ctx.Story.Thoughts.BoosterBack)
		ctx.Director.logTruth("BoosterOn")
		if ctx.Journey and ctx.Journey.team then
			ctx.Journey.team("BoosterOn")
		end
		refresh()
		task.delay(cfg().HeHearsAfter or 2.5, function()
			heComes(player)
		end)
	end)
	callPrompt = ctx.Interaction.prompt(part, {
		Name = "Call911",
		Action = "Call 911",
		Object = "Full bars",
		Hold = 0.3,
		Distance = 7,
	}, function(player)
		if ctx.Phone then
			ctx.Phone.startCall(player) -- (v157: no extra line: the call bar and the dispatcher say it)
		end
	end)
	refresh()
end

function AtticRun.start()
	-- he's up there with nobody left to hunt: back down the ladder; and the prompts follow the night
	-- (v155, the logs: his routes to the attic failed ~1.7 times a night, he can't walk the ladder, so the attic was a safe
	-- room) anyone who stays up there CampAfter s (longer while the booster's still to plug) and he comes up after them
	local CLIMB_FROM = { Patrol = true, Investigate = true, Search = true, Prowl = true, Withdraw = true, CheckSpot = true, Chase = true,
		Charge = true, Inspect = true, Lurk = true, Stalk = true }
	task.spawn(function()
		local empty = 0
		local upFor: { [Player]: number } = {}
		while true do
			task.wait(1)
			refresh()
			local I = ctx.Intruder
			local pos = I and I.position and I.position()
			-- (v155) camping in the attic
			if AtticRun.enabled() and not state.HeUp and pos and ctx.Rooms.floorOf(pos) ~= "Attic" and I.isHunting and I.isHunting()
				and CLIMB_FROM[I.getState and I.getState() or ""] and workspace:GetAttribute("AtticHatchOpen") and not ctx.Ending.isOver() then
				local need = AtticRun.pending() and (cfg().CampPending or 30) or (cfg().CampAfter or 18)
				if workspace:GetAttribute("Difficulty") == "Hard" then
					need = math.max(6, need * 0.6)
				end
				local who = nil
				for _, p in everyone() do
					if inAttic(p) and not p:GetAttribute("Captured") and not p:GetAttribute("Dead") then
						upFor[p] = (upFor[p] or 0) + 1
						if upFor[p] >= need then
							who = p
						end
					else
						upFor[p] = nil
					end
				end
				if who then
					upFor = {}
					ctx.Director.logTruthRaw("Someone stayed in the attic: he came up the ladder after them.")
					heComes(who)
				end
			else
				upFor = {}
			end
			-- (v157) the hide markers come down once he's been up a while
			if state.HideUntil and os.clock() > state.HideUntil then
				state.HideUntil = nil
				ctx.Objectives.dismiss("AtticHide")
			end
			local up = pos and ctx.Rooms.floorOf(pos) == "Attic" and I.isHunting and I.isHunting()
				and not (I.getState and I.getState() == "Offstage")
			-- (v157, the owner: "he should come and really check") up here, he goes through the hiding spots: the ones with someone in
			-- them first, then the rest, listening at each (the heartbeat if you're in it); anyone in the open he goes straight for
			if up and I.inspectSpot and CLIMB_FROM[I.getState and I.getState() or ""] then
				local hidden, open = {}, nil
				for _, p in everyone() do
					if inAttic(p) and not p:GetAttribute("Captured") and not p:GetAttribute("Dead") then
						local sp = ctx.Hiding and ctx.Hiding.spotOf(p)
						if sp then
							hidden[sp] = true
						elseif not open then
							open = p
						end
					end
				end
				local nextSpot = nil
				local best = math.huge
				for _, sp in (ctx.Hiding and ctx.Hiding.all() or {}) do
					if sp.Room == "Attic" and not state.Searched[sp] then
						local d = (sp.Position - pos).Magnitude - (hidden[sp] and 1000 or 0)
						if d < best then
							best, nextSpot = d, sp
						end
					end
				end
				if open and not next(hidden) then
					if I.adminHunt then
						I.adminHunt(open)
					end
				elseif nextSpot and (next(hidden) or open == nil) then
					state.Searched[nextSpot] = true
					I.inspectSpot(nextSpot)
				end
			end
			if up then
				local anyone = false
				for _, p in everyone() do
					if inAttic(p) and not p:GetAttribute("Captured") and not p:GetAttribute("Dead") then
						anyone = true
					end
				end
				empty = anyone and 0 or empty + 1
				if empty >= (cfg().LeaveAfter or 6) then
					empty = 0
					bringDown()
				end
			else
				empty = 0
			end
		end
	end)
end

AtticRun._heComes = heComes -- (tests)

return AtticRun
