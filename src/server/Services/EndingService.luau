--[[
	EndingService — how the night ends.

	• When someone is out early (escaped in the car or next door, or caught a second time) while
	  friends are still in the house, they get their own result card at once (Remotes.Result) and
	  can watch the others.
	• When nobody is left in the house, the night ends right away; otherwise it ends when help
	  arrives or everyone still inside is taken.
	• Ending.trigger plays every player a short cutscene for the ending (the shots are built
	  here, from the map), then their result card: YOU SURVIVED / ESCAPED / DIED / WERE TAKEN, the
	  ending's name and one line of what happened. Then the house restarts.
]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local Ending = {}
local ctx
local over = false
local ended: { [Player]: string } = {} -- player -> "Escaped" | "Died": already shown their result
local reviveUntil = 0 -- the last one standing died: the night waits this long for a revive
local seq = 0 -- bumped on every death / revive, so a stale timer from an earlier death does nothing
local doneSeq: { [Player]: number } = {}
local stayers: { [Player]: boolean } = {} -- "another night": stay together in this server
local restartSeq = 0

function Ending.init(c)
	ctx = c
end

function Ending.reset()
	over = false
	ended = {}
	reviveUntil = 0
	seq += 1
	doneSeq = {}
	stayers = {}
	restartSeq += 1
	workspace:SetAttribute("EndingActive", nil)
end

-- the night's over: back to the lobby (or, for whoever asked for another night, a fresh house here)
local function finishNight()
	restartSeq += 1
	local stay = {}
	for p in stayers do
		if p.Parent then
			stay[p] = true
		end
	end
	ctx.restart(false, stay)
end
Ending._finishNight = finishNight

function Ending.isOver(): boolean
	return over
end

-- the night is holding for someone deciding whether to revive
function Ending.reviveOpen(): boolean
	return os.clock() < reviveUntil
end

-- ReviveService brought them back: they're in the night again
function Ending.revived(player: Player)
	ended[player] = nil
	reviveUntil = 0
	seq += 1
	doneSeq[player] = nil
end

---------------------------------------------------------------------------
-- Cutscenes: a few slow camera moves around the house, built from the map
---------------------------------------------------------------------------
local V = Vector3.new
local function look(from: Vector3, at: Vector3): CFrame
	return CFrame.lookAt(from, at)
end

local function shotsFor(kind: string)
	local L = ctx.Layout
	local O = L.Outside
	local houseFront = V(2, 14, -30)
	local attic = V(-6, 24, -24)
	local police = O.PoliceStop
	local street = {
		{ From = look(V(-46, 9, -96), houseFront), To = look(V(-16, 8, -84), houseFront), Time = 4.5 },
	}
	local policeShots = {
		{ From = look(V(-46, 9, -96), houseFront), To = look(V(-22, 8, -86), houseFront), Time = 4 },
		{ From = look(police + V(22, 6, -16), police + V(0, 2, 0)), To = look(police + V(14, 4, -12), police + V(0, 2, 0)), Time = 3.5 },
	}
	local S = {
		Sirens = policeShots,
		CaseClosed = policeShots,
		LockedIn = policeShots,
		Taillights = {
			-- from the end of the driveway, watching the car go
			{ From = look(V(30, 7, -62), V(40, 4, -40)), To = look(V(26, 6, -64), V(40, 4, -40)), Time = 4.5, Track = "Car" },
			{ From = look(V(-46, 9, -96), houseFront), To = look(V(-20, 8, -86), houseFront), Time = 3 },
		},
		NextDoor = {
			-- from Mrs. Okafor's porch, back at the dark house
			{ From = look(O.NeighborPorch + V(-2, 6, 4), houseFront), To = look(O.NeighborPorch + V(-6, 5, 2), houseFront), Time = 4.5 },
			{ From = look(police + V(22, 6, -16), police + V(0, 2, 0)), To = look(police + V(14, 4, -12), police + V(0, 2, 0)), Time = 3 },
		},
		Dawn = {
			{ From = look(V(-46, 7, -100), houseFront), To = look(V(-20, 9, -86), houseFront), Time = 6, Dawn = true },
		},
		GoneQuiet = {
			{ From = look(V(-30, 8, -96), houseFront), To = look(V(-8, 12, -70), attic), Time = 6 },
		},
		GotAway = {
			-- down the empty street, the van gone
			{ From = look(V(-10, 7, -80), O.Van + V(-60, 3, 0)), To = look(V(-20, 6, -78), O.Van + V(-90, 3, 0)), Time = 4 },
			{ From = look(V(-30, 8, -96), houseFront), To = look(V(-10, 11, -74), attic), Time = 3.5 },
		},
	}
	if ctx.Finale and ctx.Finale.shots then
		local f = ctx.Finale.shots(kind)
		if f then
			return f
		end
	end
	return S[kind] or street
end

---------------------------------------------------------------------------
-- Out early: escaped or dead while the night goes on for the others
---------------------------------------------------------------------------
local function inPlay(): { Player }
	local list = {}
	for _, p in ctx.Util.sessionPlayers() do
		if not p:GetAttribute("Escaped") and not p:GetAttribute("Dead") then
			table.insert(list, p)
		end
	end
	return list
end

-- nobody left in the house: which ending is it?
local function earlyKind(): string
	local car, door = false, false
	for _, p in ctx.Util.sessionPlayers() do
		local where = p:GetAttribute("Escaped")
		if where == "Car" then
			car = true
		elseif where then
			door = true
		end
	end
	if car then
		return "Taillights"
	elseif door then
		return "NextDoor"
	end
	return ctx.Director.lostEnding()
end

--[[
	A player is out of the house for good (outcome "Escaped" with where = "Car"/"Neighbor", or
	"Died"). If that leaves nobody inside, the night ends now (after the escape fade or the
	jumpscare); otherwise they get their own result card and can watch the others.
]]
function Ending.playerDone(player: Player, outcome: string, where: string?)
	if over or ended[player] then
		return
	end
	ended[player] = outcome
	seq += 1
	local mine = seq
	doneSeq[player] = mine
	local delay = outcome == "Died" and 2.8 or 1.4
	task.delay(delay, function()
		if over or doneSeq[player] ~= mine then
			return -- (over, or revived in the meantime)
		end
		local canRevive = outcome == "Died" and ctx.Revive ~= nil and ctx.Revive.offered(player) and player.Parent ~= nil
		if #inPlay() == 0 then
			if not canRevive then
				Ending.trigger(earlyKind())
				return
			end
			-- the last one standing: a few seconds to come back before the night ends
			local window = ctx.Revive.window()
			reviveUntil = os.clock() + window
			local windowSeq = seq
			task.delay(window, function()
				if not over and seq == windowSeq and #inPlay() == 0 then
					reviveUntil = 0
					Ending.trigger(earlyKind())
				end
			end)
		end
		local R = ctx.Story.Results
		local res = outcome == "Died" and R.Died or R.Escaped
		local winTime = outcome ~= "Died" and player:GetAttribute("WinTime") or nil
		-- your coins for the night (the bonus for a new ending comes with the ending itself)
		local coins = nil
		if ctx.Economy then
			local ok, c = pcall(ctx.Economy.nightRewards, player, {
				Seconds = ctx.Director.elapsedSeconds and ctx.Director.elapsedSeconds() or 0,
				Survived = outcome ~= "Died",
			})
			coins = ok and c or nil
		end
		ctx.Remotes.Result:FireClient(player, {
			Outcome = outcome,
			Time = winTime and ctx.Util.formatSeconds(winTime) or nil,
			NewBest = player:GetAttribute("NewBest") == true,
			Title = res.Title,
			Good = res.Good,
			Line = ctx.Story.ResultLines[outcome == "Died" and "Died" or (where or "Car")],
			CanRevive = canRevive,
			ReviveIn = (canRevive and reviveUntil > os.clock()) and math.ceil(reviveUntil - os.clock()) or nil,
			RevivePrice = ctx.Config.Shop.Revive and ctx.Config.Shop.Revive.Price or nil,
			ReviveProduct = canRevive and ctx.Revive.productId() or nil,
			CanSpectate = #inPlay() > 0,
			ReturnToLobby = ctx.Reserved == true,
			Coins = coins,
		})
	end)
end

---------------------------------------------------------------------------
-- The end of the night, for everyone
---------------------------------------------------------------------------
local function resultFor(p: Player, kind: string, bad: boolean)
	local R = ctx.Story.Results
	if p:GetAttribute("Escaped") then
		return R.Escaped
	elseif p:GetAttribute("Dead") then
		return R.Died
	elseif p:GetAttribute("Captured") and bad then
		return R.Taken
	end
	return bad and R.Taken or R.Survived
end

function Ending.trigger(kind: string)
	if over then
		return
	end
	over = true
	-- the secret ending: the police arrive and you've already worked out who he is
	if kind == "Sirens" and ctx.Director.evidenceCount and ctx.Director.evidenceCount() >= ctx.Story.EvidenceNeeded then
		kind = "CaseClosed"
	end
	workspace:SetAttribute("EndingActive", kind)
	local story = ctx.Story.Endings[kind]
	if ctx.Intruder then
		ctx.Intruder.stop()
	end
	local bad = story.Bad == true

	-- fates (kept as attributes: stats and badges read them)
	for _, p in ctx.Util.sessionPlayers() do
		local fate
		if p:GetAttribute("Escaped") then
			fate = ctx.Story.Fates.Escaped
		elseif p:GetAttribute("Dead") then
			fate = ctx.Story.Fates.Dead
		elseif p:GetAttribute("Captured") then
			fate = bad and ctx.Story.Fates.Captured or ctx.Story.Fates.Rescued
		else
			fate = ctx.Story.Fates.Safe
		end
		p:SetAttribute("Fate", fate)
	end

	-- badges (Config.Badges; 0 = not set up yet)
	if ctx.Badges then
		ctx.Badges.onEnding(kind)
	else
		local badges = ctx.Config.Badges or {}
		for _, p in ctx.Util.sessionPlayers() do
			for _, id in { badges.FirstNight, badges[kind] } do
				if type(id) == "number" and id > 0 then
					task.spawn(function()
						pcall(function()
							game:GetService("BadgeService"):AwardBadge(p.UserId, id)
						end)
					end)
				end
			end
		end
	end

	-- fastest wins: everyone still standing at a good ending (escapers were timed on the way out)
	local seconds = ctx.Director.elapsedSeconds and math.floor(ctx.Director.elapsedSeconds()) or 0
	for _, p in ctx.Util.sessionPlayers() do
		if not bad and not p:GetAttribute("Escaped") and not p:GetAttribute("Dead") and seconds > 0 then
			p:SetAttribute("WinTime", seconds)
			if ctx.Stats and ctx.Stats.recordWin(p, seconds) then
				p:SetAttribute("NewBest", true)
			end
		end
	end

	-- saved stats; who saw this ending for the first time
	local firstFor = {}
	if ctx.Stats then
		local ok, firsts = pcall(ctx.Stats.recordNight, ctx.Util.sessionPlayers(), kind)
		if ok then
			for userId in firsts do
				table.insert(firstFor, userId)
			end
		end
	end

	-- coins and quest progress for the night (EconomyService)
	local coinsFor: { [Player]: any } = {}
	if ctx.Economy then
		local firstSet = {}
		for _, id in firstFor do
			firstSet[id] = true
		end
		local seconds2 = ctx.Director.elapsedSeconds and ctx.Director.elapsedSeconds() or 0
		for _, p in ctx.Util.sessionPlayers() do
			local ok, c = pcall(ctx.Economy.nightRewards, p, {
				Seconds = seconds2,
				Survived = p:GetAttribute("Escaped") ~= nil or (not bad and not p:GetAttribute("Dead") and not p:GetAttribute("Captured")),
				NewEnding = firstSet[p.UserId] == true,
				Secret = story.Secret == true and not bad and not p:GetAttribute("Dead"),
			})
			if ok then
				coinsFor[p] = c
			end
		end
		pcall(ctx.Economy.nightEnded, ctx.Util.sessionPlayers(), kind, firstSet)
		-- the secret ending's own title (not in any crate)
		if kind == "NotYourFamily" then
			for _, p in ctx.Util.sessionPlayers() do
				if not p:GetAttribute("Dead") and ctx.Economy.grantCosmetic(p, "Title_Family") then
					ctx.Remotes.Notify:FireClient(p, "Title unlocked: Not Your Family (equip it in the lobby LOCKER)", "done")
				end
			end
		end
	end

	-- the car leaving is part of the shot when the night ends on it
	local car = ctx.Escape.carModel and ctx.Escape.carModel() or nil
	local shots = shotsFor(kind)
	local restartIn = ctx.Reserved and ctx.Config.Lobby.ReturnDelay or 60
	for _, p in Players:GetPlayers() do
		local res = resultFor(p, kind, bad)
		ctx.Remotes.Ending:FireClient(p, {
			Kind = kind,
			FirstFor = firstFor,
			Headline = res.Title,
			Good = res.Good,
			Title = story.Title,
			Short = story.Short,
			Bad = bad,
			Shots = shots,
			Car = car,
			Duration = ctx.Director.elapsedString(),
			WinTime = p:GetAttribute("WinTime") and ctx.Util.formatSeconds(p:GetAttribute("WinTime")) or nil,
			NewBest = p:GetAttribute("NewBest") == true,
			RestartIn = restartIn,
			ReturnToLobby = ctx.Reserved == true,
			InGame = p:GetAttribute("InGame") == true,
			Coins = coinsFor[p],
		})
	end

	local mySeq = restartSeq
	task.delay(restartIn, function()
		if restartSeq == mySeq then
			finishNight()
		end
	end)
end

function Ending.start()
	-- "Another night" from the ending card: the group stays together (no trip through the lobby).
	-- Everyone still here asks: it starts right away.
	ctx.Remotes.PlayAgain.OnServerEvent:Connect(function(player)
		if not over or stayers[player] then
			return
		end
		stayers[player] = true
		local want, total = 0, 0
		for _, p in Players:GetPlayers() do
			total += 1
			if stayers[p] then
				want += 1
			end
		end
		for _, p in Players:GetPlayers() do
			ctx.Remotes.Notify:FireClient(p, string.format("%s wants another night (%d/%d)", player.DisplayName, want, total), "info")
		end
		if want >= total then
			task.delay(1.5, function()
				if over then
					finishNight()
				end
			end)
		end
	end)
	-- "Back to the lobby" from a result card
	ctx.Remotes.LeaveGame.OnServerEvent:Connect(function(player)
		if not ctx.Reserved then
			return
		end
		if not (over or player:GetAttribute("Escaped") or player:GetAttribute("Dead")) then
			return
		end
		pcall(function()
			TeleportService:TeleportAsync(ctx.Mode.lobbyPlaceId(), { player })
		end)
	end)
end

return Ending
