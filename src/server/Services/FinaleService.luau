--[[
	FinaleService — the secret ending. Everyone (2+ players) tied up at the same time, and he
	doesn't leave you in the boiler room: he takes you all down to the "family" he has made under
	the house (World/Burrow). About 10-15 minutes, three parts:

	1. DINNER   You wake at a long table, zip-tied to chairs, your names on place cards. He potters
	            at a camping stove with his back to you, then turns round and watches. Struggle only
	            while his back is turned; while he watches, don't move (struggling, or a free player
	            off their chair, is a strike: he drags them back and bedtime comes 30 s sooner).
	            Free yourself, then cut the others loose (also only when he isn't looking).
	            Everyone free: he takes a candle and goes out for "dessert".
	2. TUNNELS  Find the way out: the storm cellar under the back yard, padlocked. The code is in
	            three of his notes (pantry, nursery, his room). He walks the tunnels listening;
	            he hunts by sound and sight like upstairs, but walks slower than you. Caught: he
	            carries you back to your chair; a friend has to cut you loose again. Crouch behind
	            a hanging blanket and he walks past. The music box in the nursery is a trap.
	3. OUT      The lock opens, but the hatch is rusted: push it open (loud, four times) while
	            someone bars the cellar door. Climb out into the back yard.
	Ends: anyone out -> NOT YOUR FAMILY (the police find the rest). Everyone at the table at once,
	or bedtime -> FOREVER FAMILY.

	Remotes.Finale (to every player in the night): { Phase, Mode?, Strikes?, Ends?, Code?, Hatch?,
	Barred?, Free?, Total? } for the HUD (client Finale).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Finale = {}
local ctx
local S: any = nil -- the finale in progress
local V = Vector3.new

local function cfg()
	return ctx.Config.Finale
end

function Finale.init(c)
	ctx = c
	ctx.Finale = Finale
end

function Finale.isActive(): boolean
	return S ~= nil
end

function Finale.phase(): string?
	return S and S.Phase or nil
end

local function burrow()
	local refs = ctx.World.refs()
	return refs and refs.Burrow
end

local function participants(): { Player }
	local out = {}
	for _, p in ctx.Util.sessionPlayers() do
		if p:GetAttribute("FinaleRole") and p.Parent then
			table.insert(out, p)
		end
	end
	return out
end

local function broadcast(extra)
	if not S then
		return
	end
	local payload = {
		Phase = S.Phase,
		Mode = S.Mode,
		Strikes = S.Strikes,
		Ends = S.EndsAt and (workspace:GetServerTimeNow() + (S.EndsAt - os.clock())) or nil,
		Code = S.CodeShown,
		Hatch = S.Hatch,
		Barred = S.BarredUntil and os.clock() < S.BarredUntil or false,
		Bars = S.BarsLeft,
	}
	local free, total = 0, 0
	for p, seat in S.Seats do
		total += 1
		if not seat.Tied then
			free += 1
		end
	end
	payload.Free, payload.Total = free, total
	for k, v in extra or {} do
		payload[k] = v
	end
	for _, p in ctx.Util.sessionPlayers() do
		ctx.Remotes.Finale:FireClient(p, payload)
	end
end

local function say(text: string, players: { Player }?)
	ctx.Audio.caption(text, nil, nil, players)
end

---------------------------------------------------------------------------
-- Who can start it
---------------------------------------------------------------------------
function Finale.eligible(): boolean
	local c = cfg()
	if not c or not c.Enabled or S or ctx.Ending.isOver() then
		return false
	end
	local act = ctx.Director.getAct()
	if act ~= "SomeoneElse" and act ~= "Guest" then
		return false
	end
	if not burrow() then
		return false
	end
	local tied = 0
	for _, p in ctx.Util.sessionPlayers() do
		if p:GetAttribute("Escaped") then
			return false
		end
		if not p:GetAttribute("Dead") then
			if not p:GetAttribute("Captured") then
				return false
			end
			tied += 1
		end
	end
	return tied >= (c.MinPlayers or 2)
end

-- Director.checkAllCaptured: everyone's tied up. Is it the secret ending?
function Finale.tryStart(): boolean
	if not Finale.eligible() then
		return false
	end
	S = { Phase = "Intro", Strikes = 0, Seats = {}, Started = os.clock(), Notes = {}, BarsLeft = cfg().Bars, Hatch = 0 }
	task.spawn(function()
		local ok, err = pcall(Finale._begin)
		if not ok then
			warn("[Finale] failed to start: " .. tostring(err))
		end
	end)
	return true
end

---------------------------------------------------------------------------
-- The table
---------------------------------------------------------------------------
local function seatOf(player: Player)
	return S and S.Seats[player]
end

local function tie(player: Player)
	local seat = seatOf(player)
	if not seat then
		return
	end
	seat.Tied = true
	seat.Progress = 0
	ctx.Util.unseat(player)
	local hum = ctx.Util.getHumanoid(player)
	local sp = seat.Spot
	ctx.PlayerState.setFrozen(player, false)
	ctx.PlayerState.placeStanding(player, CFrame.lookAt(sp.Pos + V(0, 3, 0), sp.Pos + V(0, 3, 0) + sp.Dir))
	if hum then
		pcall(function()
			sp.Seat.Disabled = false
			sp.Seat:Sit(hum)
		end)
	end
	ctx.PlayerState.setFrozen(player, true)
	player:SetAttribute("Captured", true)
	player:SetAttribute("StruggleProgress", 0)
	player:SetAttribute("FinaleTied", true)
	ctx.Audio.playAt("ZipTie", sp.Pos + V(0, 2, 0))
	-- a prompt on you, for a friend to cut you loose
	if seat.Prompt then
		seat.Prompt:Destroy()
	end
	local root = ctx.Util.getRoot(player)
	if root then
		seat.Prompt = ctx.Interaction.prompt(root, {
			Name = "FinaleCut",
			Action = "Cut free",
			Object = tostring(player:GetAttribute("RoleName") or player.Name),
			Hold = S.Phase == "Dinner" and cfg().CutHold or cfg().RescueHold,
			Distance = 7,
		}, function(rescuer)
			if rescuer == player or not S or seatOf(rescuer) == nil or seatOf(rescuer).Tied then
				return
			end
			if S.Phase == "Dinner" and S.Mode == "Watching" then
				Finale._strike(rescuer)
				return
			end
			Finale._free(player, rescuer)
		end)
		seat.Prompt.PromptButtonHoldBegan:Connect(function(rescuer)
			if S and S.Phase ~= "Dinner" then
				ctx.Noise.emit(sp.Pos, 22, "Rescue", rescuer)
			end
		end)
	end
end

function Finale._free(player: Player, by: Player?)
	local seat = seatOf(player)
	if not seat or not seat.Tied then
		return
	end
	seat.Tied = false
	seat.Progress = 0
	if seat.Prompt then
		seat.Prompt:Destroy()
		seat.Prompt = nil
	end
	ctx.Util.unseat(player)
	pcall(function()
		seat.Spot.Seat.Disabled = true
	end)
	player:SetAttribute("Captured", nil)
	player:SetAttribute("StruggleProgress", nil)
	player:SetAttribute("FinaleTied", nil)
	ctx.PlayerState.setFrozen(player, false)
	-- stand up beside the chair
	local sp = seat.Spot
	ctx.PlayerState.placeStanding(player, CFrame.lookAt(sp.Pos + sp.Dir * -1.8 + V(0, 3, 0), sp.Pos + V(0, 3, 0)))
	ctx.Audio.playAt(by and "ScissorsSnip" or "ZipTie", sp.Pos + V(0, 2, 0), { CaptionText = "[Snip]" })
	if by then
		by:SetAttribute("NightRescues", (tonumber(by:GetAttribute("NightRescues")) or 0) + 1)
		if ctx.Economy then
			ctx.Economy.track(by, "Rescues", 1)
		end
		say(tostring(by:GetAttribute("RoleName") or by.Name) .. " cut you loose.", { player })
	elseif S.Phase == "Dinner" then
		say(ctx.Story.Finale.FreeSelf, { player })
	end
	if S.Phase == "Dinner" then
		ctx.Objectives.step("FinaleDinner", "Struggle")
	end
	broadcast()
end

-- he caught someone moving while he watched (or cutting, or struggling)
function Finale._strike(player: Player)
	if not S or S.Phase ~= "Dinner" or (S.LastStrike and os.clock() - S.LastStrike < 2) then
		return
	end
	S.LastStrike = os.clock()
	S.Strikes += 1
	S.EndsAt -= cfg().StrikePenalty
	local seat = seatOf(player)
	local lines = ctx.Story.Finale.Strike
	ctx.Audio.playAt("DoorForce", burrow().TableCenter, { CaptionText = "[He slams his hand down on the table]", CaptionRange = 60 })
	for _, p in participants() do
		ctx.Remotes.Shake:FireClient(p, 0.8, 0.5)
		ctx.PlayerState.addNerve(p, -8)
	end
	say(lines[((S.Strikes - 1) % #lines) + 1])
	if seat then
		if seat.Tied then
			-- tighter: half the struggle undone
			seat.Progress = math.max(0, seat.Progress - 50)
			player:SetAttribute("StruggleProgress", seat.Progress / 100)
		else
			tie(player)
		end
	end
	ctx.Remotes.Notify:FireClient(player, "He saw you. Bedtime comes sooner.", "danger")
	broadcast({ Struck = player.UserId })
end

local function struggle(player: Player)
	if not S or (S.Phase ~= "Dinner" and S.Phase ~= "Tunnels" and S.Phase ~= "Out") then
		return
	end
	local seat = seatOf(player)
	if not seat or not seat.Tied then
		return
	end
	local now = os.clock()
	if seat.Last and now - seat.Last < 0.08 then
		return
	end
	seat.Last = now
	if S.Phase == "Dinner" and S.Mode == "Watching" then
		Finale._strike(player)
		return
	end
	local per = cfg().StrugglePerPress
	if workspace:GetAttribute("Difficulty") == "Hard" then
		per *= 0.78
	end
	-- (in the tunnels, alone at the table: slower, and noisy)
	if S.Phase ~= "Dinner" then
		per *= 0.55
		seat.Presses = (seat.Presses or 0) + 1
		if seat.Presses % 6 == 0 then
			ctx.Audio.playAt("Struggle", seat.Spot.Pos)
			ctx.Noise.emit(seat.Spot.Pos, 26, "Struggle", player)
		end
	end
	seat.Progress += per
	player:SetAttribute("StruggleProgress", math.min(1, seat.Progress / 100))
	if seat.Progress >= 100 then
		Finale._free(player, nil)
	end
end

---------------------------------------------------------------------------
-- Him
---------------------------------------------------------------------------
local function hisPos(): Vector3
	return (S.P and S.P.position()) or V()
end

-- walk him along a list of points, one after another (returns when he's there or gave up)
local function walk(points: { Vector3 }, speed: number, run: boolean?, until_: (() -> boolean)?)
	for _, pt in points do
		local t0 = os.clock()
		local stuckAt, stuckPos = os.clock(), hisPos()
		S.P.moveTo(pt, speed, run)
		while S and S.P do
			local d = hisPos() - pt
			if V(d.X, 0, d.Z).Magnitude < 1.6 then
				break
			end
			if until_ and until_() then
				S.P.stop()
				return false
			end
			if (hisPos() - stuckPos).Magnitude > 1 then
				stuckAt, stuckPos = os.clock(), hisPos()
			elseif os.clock() - stuckAt > 2.5 or os.clock() - t0 > 20 then
				-- wedged: he steps there (nobody's looking at a wall of dirt)
				S.P.place(pt, pt + (pt - hisPos()))
				break
			end
			task.wait(0.1)
		end
		if not S then
			return false
		end
	end
	return true
end

-- the patrol graph: nearest node, and the shortest route between nodes (BFS on a small graph)
local function nearestNode(pos: Vector3): string
	local best, bd = nil, math.huge
	for name, p in burrow().Nodes do
		local d = (p - pos).Magnitude
		if d < bd then
			best, bd = name, d
		end
	end
	return best :: string
end

local adjacency: { [string]: { string } }? = nil
local function route(from: string, to: string): { Vector3 }
	local B = burrow()
	if not adjacency then
		local adj: { [string]: { string } } = {}
		for _, e in B.Edges do
			adj[e[1]] = adj[e[1]] or {}
			adj[e[2]] = adj[e[2]] or {}
			table.insert(adj[e[1]], e[2])
			table.insert(adj[e[2]], e[1])
		end
		adjacency = adj
	end
	local prev = { [from] = from }
	local queue = { from }
	local head = 1
	while head <= #queue do
		local n = queue[head]
		head += 1
		if n == to then
			break
		end
		for _, m in (adjacency :: any)[n] or {} do
			if not prev[m] then
				prev[m] = n
				table.insert(queue, m)
			end
		end
	end
	local path = {}
	local n = to
	if not prev[n] then
		return { B.Nodes[to] }
	end
	while n ~= from do
		table.insert(path, 1, B.Nodes[n])
		n = prev[n]
	end
	return path
end
Finale._route = route

local function lineClear(a: Vector3, b: Vector3): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip = { S.P.model() }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(skip, p.Character)
		end
	end
	params.FilterDescendantsInstances = skip
	local hit = workspace:Raycast(a, b - a, params)
	return hit == nil
end

local function inNook(pos: Vector3): boolean
	for _, n in burrow().Nooks do
		if pos.X >= n.Min.X and pos.X <= n.Max.X and pos.Z >= n.Min.Z and pos.Z <= n.Max.Z and pos.Y <= n.Max.Y + 4 then
			return true
		end
	end
	return false
end

local function freePlayers(): { Player }
	local out = {}
	for p, seat in S.Seats do
		if p.Parent and not seat.Tied and not p:GetAttribute("Escaped") then
			table.insert(out, p)
		end
	end
	return out
end

-- can he see this player?
local function sees(p: Player): boolean
	local c = cfg()
	local root = ctx.Util.getRoot(p)
	local head = S.P.head()
	if not root or not head then
		return false
	end
	local eye = head.Position
	local to = root.Position - eye
	local dist = to.Magnitude
	local range = p:GetAttribute("FlashlightOn") and c.SightFlashlight or c.Sight
	if dist > range then
		return false
	end
	-- right on top of you: blanket or not, he knows
	if dist <= 3.5 then
		return true
	end
	if dist > 3.5 then
		-- crouched behind a blanket: invisible unless he's right on you
		if inNook(root.Position) and p:GetAttribute("Crouching") then
			return false
		end
		local look = head.CFrame.LookVector
		local flat = V(to.X, 0, to.Z)
		if flat.Magnitude > 0.1 and look:Dot(flat.Unit) < math.cos(math.rad(c.FOV / 2)) then
			return false
		end
	end
	return lineClear(eye, root.Position)
end

---------------------------------------------------------------------------
-- Part 1: dinner
---------------------------------------------------------------------------
local function dinnerLoop()
	local c = cfg()
	local B = burrow()
	S.Phase = "Dinner"
	S.EndsAt = os.clock() + c.DinnerTime
	ctx.Objectives.set({ "FinaleDinner" })
	local tableRound = {
		V(-21, B.FloorY, 23.6), V(-31, B.FloorY, 23.6), V(-36.4, B.FloorY, 19.5), V(-36.4, B.FloorY, 14.5), V(-31, B.FloorY, 10.4), V(-21, B.FloorY, 10.4), B.Stove,
	}
	local cycle = 0
	while S and S.Phase == "Dinner" do
		-- back to the table: the stove, back turned
		S.Mode = "Back"
		S.P.gait("Search")
		walk({ B.Stove }, 5)
		if not S or S.Phase ~= "Dinner" then
			break
		end
		S.P.stop()
		S.P.face(B.StoveLook)
		broadcast()
		local backFor = math.random() * (c.BackTurned[2] - c.BackTurned[1]) + c.BackTurned[1]
		local t0 = os.clock()
		while S and S.Phase == "Dinner" and os.clock() - t0 < backFor do
			-- everyone free (while his back's turned): he goes for dessert
			local allFree = true
			for _, seat in S.Seats do
				if seat.Tied then
					allFree = false
				end
			end
			if allFree then
				return "AllFree"
			end
			if os.clock() >= S.EndsAt then
				return "Bedtime"
			end
			task.wait(0.1)
		end
		if not S or S.Phase ~= "Dinner" then
			break
		end
		-- the warning: a creak, a clink, he straightens up
		S.Mode = "Warn"
		ctx.Audio.playAt("Floorboard", B.Stove, { Volume = 0.9, CaptionText = "[He sets down the spoon]", CaptionRange = 40 })
		broadcast()
		task.wait(c.Warning)
		if not S or S.Phase ~= "Dinner" then
			break
		end
		-- (a fake-out: he stirs the pot instead, and keeps his back to you a little longer)
		if math.random() < (c.FakeOut or 0) then
			S.Mode = "Back"
			broadcast()
			task.wait(2 + math.random() * 2)
			continue
		end
		-- watching: he turns round; every other time he walks round the table behind your chairs
		S.Mode = "Watching"
		S.P.gait("Stare")
		S.P.face(B.TableCenter)
		broadcast()
		cycle += 1
		local watchFor = math.random() * (c.Watching[2] - c.Watching[1]) + c.Watching[1]
		local t1 = os.clock()
		local walking = cycle % 2 == 0
		if walking then
			task.spawn(function()
				walk(tableRound, 4.5, false, function()
					return not S or S.Mode ~= "Watching"
				end)
			end)
		end
		while S and S.Phase == "Dinner" and (os.clock() - t1 < watchFor or (walking and (hisPos() - B.Stove).Magnitude > 2.5 and os.clock() - t1 < 20)) do
			-- anyone free and away from their chair, or moving: caught
			for p, seat in S.Seats do
				if not seat.Tied and p.Parent then
					local root = ctx.Util.getRoot(p)
					if root then
						local off = root.Position - seat.Spot.Pos
						local away = V(off.X, 0, off.Z).Magnitude > c.MoveTolerance
						local v = root.AssemblyLinearVelocity
						if away or V(v.X, 0, v.Z).Magnitude > 3 then
							Finale._strike(p)
						end
					end
				end
			end
			if os.clock() >= S.EndsAt then
				return "Bedtime"
			end
			task.wait(0.15)
		end
	end
	return S and "Bedtime" or "Over"
end

---------------------------------------------------------------------------
-- Part 2 and 3: the tunnels, the way out
---------------------------------------------------------------------------
local function catch(p: Player)
	local B = burrow()
	ctx.Remotes.Fade:FireClient(p, true, 0.3)
	ctx.Remotes.Shake:FireClient(p, 1, 0.5)
	local head = S.P.head()
	if head then
		ctx.Remotes.Jumpscare:FireClient(p, head)
	end
	ctx.Audio.playAt("BodyFall", hisPos(), { Caption = false })
	p:SetAttribute("NightCaught", (tonumber(p:GetAttribute("NightCaught")) or 0) + 1)
	task.delay(1.1, function()
		if not S then
			return
		end
		tie(p)
		ctx.Remotes.Fade:FireClient(p, false, 1.5)
		say(ctx.Story.Finale.Caught, { p })
		for _, other in participants() do
			if other ~= p then
				ctx.Remotes.Notify:FireClient(other, tostring(p:GetAttribute("RoleName") or p.Name) .. " is back at the table. Cut them loose!", "danger")
			end
		end
		Finale._checkEnd()
	end)
	-- he takes them back himself: he's at the dining room a moment later
	S.P.place(B.Nodes.DinE, B.TableCenter)
	S.Hunting = nil
	S.Busy = os.clock() + 4
end

-- what he heard (Noise.listen): the loudest recent noise in the burrow
local function onNoise(ev)
	if not S or (S.Phase ~= "Tunnels" and S.Phase ~= "Out") or not S.P then
		return
	end
	local B = burrow()
	-- (down here he goes by footsteps and bangs; breathing would give every hiding place away)
	if ev.Position.Y > B.FloorY + 14 or ev.Kind == "Breathing" then
		return
	end
	local r = (ev.Radius or 0) * cfg().HearScale
	if (ev.Position - hisPos()).Magnitude > r then
		return
	end
	if not S.Heard or (ev.Radius or 0) >= (S.Heard.Radius or 0) or os.clock() - S.Heard.T > 3 then
		S.Heard = { Pos = ev.Position, Radius = ev.Radius or 0, T = os.clock(), Source = ev.Source }
	end
end

local function hunterLoop()
	local c = cfg()
	local B = burrow()
	local patrolGoal: Vector3? = nil
	local path: { Vector3 } = {}
	local mode = "Patrol"
	while S and (S.Phase == "Tunnels" or S.Phase == "Out") do
		task.wait(0.15)
		if not S then
			break
		end
		if S.Busy and os.clock() < S.Busy then
			continue
		end
		local bedtime = S.EndsAt and os.clock() >= S.EndsAt - c.BedtimeHunt
		-- sight: the nearest free player he can see
		local target, td = nil, math.huge
		for _, p in freePlayers() do
			local root = ctx.Util.getRoot(p)
			if root and sees(p) then
				local d = (root.Position - hisPos()).Magnitude
				if d < td then
					target, td = p, d
				end
			end
		end
		-- at bedtime he always knows where the nearest of you is
		if not target and bedtime then
			for _, p in freePlayers() do
				local root = ctx.Util.getRoot(p)
				if root then
					local d = (root.Position - hisPos()).Magnitude
					if d < td then
						target, td = p, d
					end
				end
			end
		end
		if target then
			local root = ctx.Util.getRoot(target)
			if root then
				if mode ~= "Chase" then
					mode = "Chase"
					ctx.Audio.playAt("Growl", hisPos(), { CaptionText = "[A low growl, close]", CaptionRange = 50 })
					S.P.gait(nil)
				end
				if td <= c.CatchRange then
					catch(target)
					mode = "Patrol"
					path = {}
					continue
				end
				if lineClear(hisPos() + V(0, 1, 0), root.Position) then
					S.P.moveTo(root.Position, c.ChaseSpeed, true)
					path = {}
				elseif #path == 0 then
					path = route(nearestNode(hisPos()), nearestNode(root.Position))
					table.insert(path, root.Position)
				end
				S.LastSeen = { Pos = root.Position, T = os.clock() }
			end
		elseif S.Heard and S.Checked and (S.Heard.Pos - S.Checked.Pos).Magnitude < 6 and os.clock() - S.Checked.T < 12 and (S.Heard.Radius or 0) < 40 then
			-- (he already looked there and found nothing: not again so soon)
			S.Heard = nil
		elseif S.Heard and os.clock() - S.Heard.T < 8 then
			-- go and look where the noise was
			if mode ~= "Investigate" or (patrolGoal and (patrolGoal - S.Heard.Pos).Magnitude > 4) then
				mode = "Investigate"
				patrolGoal = S.Heard.Pos
				path = route(nearestNode(hisPos()), nearestNode(S.Heard.Pos))
				table.insert(path, S.Heard.Pos)
				S.P.gait(nil)
			end
		elseif mode ~= "Patrol" or #path == 0 then
			mode = "Patrol"
			S.Heard = nil
			local pick = B.Patrol[math.random(1, #B.Patrol)]
			path = route(nearestNode(hisPos()), pick)
			S.P.gait(nil)
		end
		S.HunterMode, S.HunterPath = mode, #path -- (for tests)
		-- follow the path
		local troot = target and ctx.Util.getRoot(target)
		if #path > 0 and not (troot and lineClear(hisPos() + V(0, 1, 0), troot.Position)) then
			local nextPt = path[1]
			local d = hisPos() - nextPt
			if V(d.X, 0, d.Z).Magnitude < 1.8 then
				table.remove(path, 1)
				if #path == 0 and mode == "Investigate" then
					-- he stands and listens a moment
					S.P.stop()
					S.P.gait("Search")
					S.Busy = os.clock() + 2.5
					S.Checked = { Pos = patrolGoal or hisPos(), T = os.clock() }
					S.Heard = nil
					mode = "Patrol"
				end
			else
				local speed = (mode == "Chase" or bedtime) and c.ChaseSpeed or (mode == "Investigate" and c.InvestigateSpeed or c.PatrolSpeed)
				S.P.moveTo(nextPt, speed, mode == "Chase" or bedtime)
				-- wedged on something for a few seconds: he steps past it
				local here = hisPos()
				if not S.Progress or (here - S.Progress.Pos).Magnitude > 1 then
					S.Progress = { Pos = here, T = os.clock() }
				elseif os.clock() - S.Progress.T > 3 then
					S.Progress = nil
					S.P.place(nextPt, nextPt + (nextPt - here))
				end
			end
		end
		-- the cellar door: barred, he bangs on it until it gives
		local door = B.CellarDoor
		if S.DoorClosed and (hisPos() - door.Outside).Magnitude < 5 then
			if S.BarredUntil and os.clock() < S.BarredUntil then
				S.P.stop()
				if not S.NextBang or os.clock() >= S.NextBang then
					S.NextBang = os.clock() + 1.6
					ctx.Audio.playAt("DoorForce", door.Part.Position, { CaptionText = "[Something slams into the cellar door]", CaptionRange = 60 })
					ctx.Remotes.Shake:FireAllClients(0.4, 0.3)
				end
				S.Busy = os.clock() + 0.5
			else
				Finale._openCellarDoor(true)
			end
		end
	end
end

function Finale._openCellarDoor(broken: boolean?)
	local door = burrow().CellarDoor
	if not S.DoorClosed then
		return
	end
	S.DoorClosed = false
	S.BarredUntil = nil
	door.Part.CanCollide = false
	TweenService:Create(door.Part, TweenInfo.new(broken and 0.25 or 0.8), { CFrame = door.Open }):Play()
	if broken then
		ctx.Audio.playAt("DoorForce", door.Part.Position, { CaptionText = ctx.Story.Finale.DoorBreaks, CaptionRange = 60 })
	end
	broadcast()
end

local function setupTunnels()
	local B = burrow()
	local c = cfg()
	local F = ctx.Story.Finale
	-- the code: four digits, new every time
	local code = {}
	for i = 1, 4 do
		code[i] = math.random(0, 9)
	end
	S.Code = code
	S.CodeShown = "_ _ _ _"
	local function showCode()
		local parts = {}
		for i = 1, 4 do
			local known = (i == 1 and S.Notes.Pantry) or (i == 2 and S.Notes.Nursery) or (i >= 3 and S.Notes.HisRoom)
			table.insert(parts, known and tostring(code[i]) or "_")
		end
		S.CodeShown = table.concat(parts, " ")
		local n = (S.Notes.Pantry and 1 or 0) + (S.Notes.Nursery and 1 or 0) + (S.Notes.HisRoom and 1 or 0)
		if n >= 3 then
			ctx.Objectives.step("FinaleBurrow", "Code")
		end
		broadcast()
	end
	-- the three notes
	local digits = { Pantry = { code[1] }, Nursery = { code[2] }, HisRoom = { code[3], code[4] } }
	for i, key in { "Pantry", "Nursery", "HisRoom" } do
		local part = B.Notes[key]
		ctx.Objectives.setTarget("FinaleNote" .. i, part.Position)
		local doc = F.Notes[key]
		local prompt = ctx.Interaction.prompt(part, { Action = "Read", Object = doc.Title, Distance = 7 }, function(player)
			ctx.Remotes.Document:FireClient(player, "FinaleNote", { Title = doc.Title, Body = string.format(doc.Body, table.unpack(digits[key])) })
			if not S.Notes[key] then
				S.Notes[key] = true
				showCode()
				for _, p in participants() do
					ctx.Remotes.Notify:FireClient(p, (player:GetAttribute("RoleName") or player.Name) .. " found part of the lock code: " .. S.CodeShown, "done")
				end
			end
		end)
		table.insert(S.Prompts, prompt)
	end
	-- the burnt photo
	table.insert(S.Prompts, ctx.Interaction.prompt(B.Lore.Photo, { Action = "Look", Object = F.Photo.Title, Distance = 7 }, function(player)
		ctx.Remotes.Document:FireClient(player, "FinalePhoto", F.Photo)
	end))
	-- the music box: the first one into the nursery sets it off (it carries)
	S.MusicBoxDone = false
	-- the cellar: found when someone walks in
	ctx.Objectives.setTarget("FinaleCellar", B.CellarDoor.Inside)
	ctx.Objectives.setTarget("FinaleKeypad", B.Keypad.Position)
	ctx.Objectives.setTarget("FinaleLadder", B.LadderOut.Position)
	-- the keypad
	table.insert(S.Prompts, ctx.Interaction.prompt(B.Keypad, { Action = "Enter code", Object = "Padlock", Distance = 6 }, function(player)
		if S.Phase ~= "Tunnels" then
			return
		end
		ctx.Puzzle.open(player, "Code", B.Keypad, ctx.Puzzle.code(table.concat(code, "")), function()
			Finale._unlocked(player)
		end, { Len = 4 })
	end))
	-- barring the cellar door (from inside)
	S.DoorClosed = true
	S.DoorPrompt = ctx.Interaction.prompt(B.CellarDoor.Part, { Name = "BarDoor", Action = "Bar the door", Object = "Cellar door", Distance = 6, Hold = 0.8, Key = Enum.KeyCode.R }, function(player)
		if not S or S.BarsLeft <= 0 then
			return
		end
		local root = ctx.Util.getRoot(player)
		if not root or root.Position.Z < B.CellarDoor.Closed.Position.Z then
			say("You'd have to be on the other side to bar it.", { player })
			return
		end
		-- (open: slam it shut first, unless he's right in the doorway)
		if not S.DoorClosed then
			if (hisPos() - B.CellarDoor.Closed.Position).Magnitude < 5 then
				return
			end
			S.DoorClosed = true
			B.CellarDoor.Part.CanCollide = true
			TweenService:Create(B.CellarDoor.Part, TweenInfo.new(0.3), { CFrame = B.CellarDoor.Closed }):Play()
			ctx.Audio.playAt("DoorSlam", B.CellarDoor.Closed.Position)
			ctx.Noise.emit(B.CellarDoor.Closed.Position, 30, "Door", player)
		end
		S.BarsLeft -= 1
		S.BarredUntil = os.clock() + c.BarHolds
		ctx.Audio.playAt("Deadbolt", B.CellarDoor.Part.Position)
		say(F.DoorBarred, { player })
		if S.BarsLeft <= 0 then
			S.DoorPrompt.Enabled = false
		end
		broadcast()
	end)
	-- open the door on the cellar side to walk through it (closed by default; anyone can push it)
	table.insert(S.Prompts, S.DoorPrompt)
	table.insert(S.Prompts, ctx.Interaction.prompt(B.CellarDoor.Part, { Name = "OpenCellar", Action = "Open", Object = "Cellar door", Distance = 6 }, function(player)
		if S.DoorClosed then
			Finale._openCellarDoor(false)
			ctx.Noise.emit(B.CellarDoor.Part.Position, 16, "Door", player)
		end
	end))
	-- the hatch and the ladder
	table.insert(S.Prompts, ctx.Interaction.prompt(B.LadderOut, { Name = "Hatch", Action = "Push the hatch", Object = "Rusted hatch", Distance = 7, Hold = c.HatchHold }, function(player)
		if not S or S.Phase ~= "Out" then
			say("A chain and a padlock. It won't budge.", { player })
			return
		end
		if S.Hatch < c.HatchPushes then
			S.Hatch += 1
			ctx.Audio.playAt("DoorForce", B.LadderOut.Position + V(0, 6, 0), { CaptionText = "[Rusted metal screeches]", CaptionRange = 80 })
			ctx.Noise.emit(B.LadderOut.Position, 60, "Hatch", player)
			broadcast()
			if S.Hatch >= c.HatchPushes then
				ctx.Remotes.Notify:FireAllClients("The hatch is open. CLIMB!", "done")
			end
			return
		end
		Finale._climb(player)
	end))
end

function Finale._unlocked(player: Player)
	if not S or S.Phase ~= "Tunnels" then
		return
	end
	S.Phase = "Out"
	ctx.Objectives.step("FinaleBurrow", "Code")
	ctx.Objectives.step("FinaleBurrow", "Unlock")
	ctx.Audio.playAt("Deadbolt", burrow().Keypad.Position)
	say(ctx.Story.Finale.Unlocked)
	for _, p in participants() do
		ctx.Remotes.Notify:FireClient(p, "The lock is open! Push the hatch (it's loud) and climb out.", "objective")
	end
	broadcast()
end

function Finale._climb(player: Player)
	if not S or player:GetAttribute("Escaped") or (seatOf(player) and seatOf(player).Tied) then
		return
	end
	local B = burrow()
	ctx.Remotes.Fade:FireClient(player, true, 0.4)
	task.delay(0.5, function()
		ctx.PlayerState.placeStanding(player, CFrame.lookAt(B.Surface + V(math.random(-2, 2), 0, 0), B.Surface + V(0, 0, -10)))
		ctx.Remotes.Fade:FireClient(player, false, 1.2)
		say(ctx.Story.Finale.Out, { player })
		ctx.Objectives.step("FinaleBurrow", "Climb")
		-- out: like any escape (timed, a card, spectate the others)
		S.Out = S.Out or {}
		S.Out[player] = true
		player:SetAttribute("Escaped", "Burrow")
		if ctx.Director and ctx.Director.elapsedSeconds then
			local t = math.floor(ctx.Director.elapsedSeconds())
			player:SetAttribute("WinTime", t)
		end
		ctx.PlayerState.setFrozen(player, true)
		Finale._checkEnd()
		if S and not S.Ending and ctx.Ending.playerDone then
			ctx.Ending.playerDone(player, "Escaped", "Burrow")
		end
	end)
end

-- nobody left to play: how does it end?
function Finale._checkEnd()
	if not S or S.Ending or (S.Phase ~= "Tunnels" and S.Phase ~= "Out") then
		return
	end
	local free = #freePlayers()
	local out = 0
	for _ in S.Out or {} do
		out += 1
	end
	if free == 0 then
		Finale._finish(out > 0 and "NotYourFamily" or "ForeverFamily")
	end
end

function Finale._finish(kind: string)
	if not S or S.Ending then
		return
	end
	S.Ending = kind
	S.Phase = "End"
	if kind == "ForeverFamily" then
		say(ctx.Story.Finale.Bedtime)
	end
	broadcast()
	task.delay(kind == "ForeverFamily" and 2 or 1, function()
		if ctx.Escape.suspend then
			ctx.Escape.suspend(false)
		end
		ctx.Ending.trigger(kind)
	end)
end

---------------------------------------------------------------------------
-- The whole thing
---------------------------------------------------------------------------
function Finale._begin()
	local B = burrow()
	local F = ctx.Story.Finale
	local c = cfg()
	S.Prompts = {}
	-- (a moment of black after the last one is taken: the tied-up shot finishes first)
	task.wait(2.5)
	if not S then
		return
	end
	-- the night upstairs stops: no police, no dawn, no last chance
	if ctx.Escape.suspend then
		ctx.Escape.suspend(true)
	end
	ctx.Director.enterBelow()
	ctx.Capture.clearForFinale()
	local people = {}
	for _, p in ctx.Util.sessionPlayers() do
		if not p:GetAttribute("Dead") and not p:GetAttribute("Escaped") then
			table.insert(people, p)
		end
	end
	for _, p in ctx.Util.sessionPlayers() do
		p:SetAttribute("FinaleRole", p:GetAttribute("Dead") and "Watcher" or "Guest")
	end
	-- him
	S.P = ctx.Intruder.puppet()
	-- black, then the table
	for _, p in people do
		ctx.Remotes.Fade:FireClient(p, true, 0.8)
		if ctx.Hiding.spotOf(p) then
			ctx.Hiding.exit(p, true)
		end
	end
	say(F.Intro[1], people)
	task.wait(1.2)
	for i, p in people do
		local spot = B.Seats[((i - 1) % #B.Seats) + 1]
		S.Seats[p] = { Spot = spot, Tied = true, Progress = 0 }
		spot.Card.Text = string.upper(string.split(tostring(p:GetAttribute("RoleName") or p.DisplayName), " ")[1])
		tie(p)
	end
	S.P.place(B.Head + V(1.5, 0, 0), B.TableCenter)
	S.P.gait("Stare")
	task.wait(0.4)
	for _, p in people do
		ctx.Remotes.Fade:FireClient(p, false, 2)
	end
	-- the look around the room (shared, everyone in their chair)
	local Y = B.FloorY
	ctx.Cutscene.play({
		Name = "Dinner",
		Players = people,
		Freeze = false,
		HoldIntruder = false,
		Shots = {
			{ From = CFrame.lookAt(V(-17.5, Y + 6.5, 8), V(-30, Y + 3, 20)), To = CFrame.lookAt(V(-19, Y + 5.6, 10), V(-30, Y + 3.5, 19)), Time = 4 },
			{ From = CFrame.lookAt(V(-30, Y + 5.5, 17), V(-37.4, Y + 5.2, 17)), To = CFrame.lookAt(V(-32, Y + 5.3, 17), V(-37.4, Y + 5.2, 17)), Time = 3.5 },
			{ From = CFrame.lookAt(V(-22, Y + 4.5, 17), B.Head + V(1.5, 5, 0)), To = CFrame.lookAt(V(-26, Y + 4.8, 17), B.Head + V(1.5, 5.2, 0)), Time = 3.5 },
		},
		Subtitle = F.Rules,
	})
	ctx.Audio.playAt("MusicBox", B.TableCenter, { Volume = 0.5, Caption = false })
	task.wait(11.5)
	say(F.Seated, people)
	for _, p in people do
		ctx.Remotes.Notify:FireClient(p, F.Tips, "objective")
	end
	task.wait(2)
	-- 1. dinner
	local outcome = dinnerLoop()
	if not S then
		return
	end
	if outcome == "Bedtime" then
		Finale._finish("ForeverFamily")
		return
	end
	-- everyone's free: he goes out for dessert, and leaves the door open
	S.Phase = "Leaving"
	ctx.Objectives.complete("FinaleDinner")
	say(F.AllFree)
	S.P.gait(nil)
	local door = B.DiningDoor
	door.Part.CanCollide = false
	TweenService:Create(door.Part, TweenInfo.new(1.2), { CFrame = door.Open }):Play()
	ctx.Audio.playAt("DoorOpen", door.Part.Position)
	walk({ B.Nodes.DinE, B.Nodes.DinDoor, B.Nodes.TunA, B.Nodes.J1, B.Nodes.TunS }, 6)
	if not S then
		return
	end
	-- 2. the tunnels
	S.Phase = "Tunnels"
	S.EndsAt = os.clock() + c.BurrowTime
	ctx.Objectives.set({ "FinaleBurrow" })
	setupTunnels()
	broadcast()
	task.spawn(hunterLoop)
	-- the watcher: the music box, the cellar, bedtime
	while S and not S.Ending do
		task.wait(0.5)
		local Rm = B.Rooms
		for _, p in freePlayers() do
			local root = ctx.Util.getRoot(p)
			if root then
				local pos = root.Position
				local function inside(r)
					return pos.X > r.Min.X and pos.X < r.Max.X and pos.Z > r.Min.Z and pos.Z < r.Max.Z and pos.Y < r.Max.Y + 2
				end
				if not S.MusicBoxDone and inside(Rm.Nursery) then
					S.MusicBoxDone = true
					ctx.Audio.playAt("MusicBox", B.MusicBox.Position, { Volume = 1, CaptionText = F.MusicBox, CaptionRange = 80 })
					ctx.Noise.emit(B.MusicBox.Position, 70, "MusicBox")
				end
				if inside(Rm.Cellar) then
					ctx.Objectives.step("FinaleBurrow", "Cellar")
				end
				-- out of the burrow some other way (fell, glitched): back down
				if pos.Y > B.FloorY + 20 and not p:GetAttribute("Escaped") then
					ctx.PlayerState.placeStanding(p, CFrame.new(B.Nodes.J1 + V(0, 3, 0)))
				end
			end
		end
		if S.EndsAt and os.clock() >= S.EndsAt then
			Finale._finish(next(S.Out or {}) ~= nil and "NotYourFamily" or "ForeverFamily")
			break
		end
		if S.EndsAt and not S.WarnedBedtime and os.clock() >= S.EndsAt - c.BedtimeHunt then
			S.WarnedBedtime = true
			for _, p in participants() do
				ctx.Remotes.Notify:FireClient(p, "The candles are burning down. He's coming for everyone. GET OUT.", "danger")
			end
		end
		Finale._checkEnd()
	end
end

-- the ending's camera (EndingService.shotsFor asks for these)
function Finale.shots(kind: string)
	local B = burrow()
	if not B then
		return nil
	end
	local Y = B.FloorY
	if kind == "ForeverFamily" then
		return {
			{ From = CFrame.lookAt(V(-17.5, Y + 6.5, 8), V(-30, Y + 3, 20)), To = CFrame.lookAt(V(-19.5, Y + 5, 11), V(-31, Y + 3.5, 18)), Time = 4.5 },
			{ From = CFrame.lookAt(V(-26, Y + 5, 17), B.Head + V(1.5, 5, 0)), To = CFrame.lookAt(V(-30, Y + 5.2, 17), B.Head + V(1.5, 5.2, 0)), Time = 3.5 },
		}
	elseif kind == "NotYourFamily" then
		local G = B.Surface
		return {
			{ From = CFrame.lookAt(G + V(14, 6, 12), G + V(0, -1, 3)), To = CFrame.lookAt(G + V(9, 4, 9), G + V(0, -1, 3)), Time = 4 },
			{ From = CFrame.lookAt(V(-22, Y + 5, 11), B.Head + V(1.5, 5, 0)), To = CFrame.lookAt(V(-27, Y + 5, 14), B.Head + V(1.5, 5, 0)), Time = 3.5 },
		}
	end
	return nil
end

-- the night is over / the house is reset
function Finale.reset()
	if S then
		for _, pr in S.Prompts or {} do
			pcall(function()
				pr:Destroy()
			end)
		end
		for p, seat in S.Seats do
			if seat.Prompt then
				pcall(function()
					seat.Prompt:Destroy()
				end)
			end
			if p.Parent then
				ctx.Util.unseat(p)
			end
		end
		if S.P then
			pcall(S.P.release)
		end
	end
	S = nil
	adjacency = nil
	for _, p in Players:GetPlayers() do
		p:SetAttribute("FinaleRole", nil)
		p:SetAttribute("FinaleTied", nil)
	end
	ctx.Remotes.Finale:FireAllClients(nil)
end

function Finale.start()
	ctx.Remotes.Struggle.OnServerEvent:Connect(function(player)
		struggle(player)
	end)
	ctx.Noise.listen(onNoise)
	Players.PlayerRemoving:Connect(function(p)
		if S and S.Seats[p] then
			local seat = S.Seats[p]
			if seat.Prompt then
				seat.Prompt:Destroy()
			end
			S.Seats[p] = nil
			task.defer(Finale._checkEnd)
		end
	end)
	-- a tied-up player who hops out of their chair goes straight back in
	RunService.Heartbeat:Connect(function()
		if not S or not S.Seats then
			return
		end
		for p, seat in S.Seats do
			if seat.Tied and p.Parent then
				local hum = ctx.Util.getHumanoid(p)
				if hum and hum.SeatPart == nil and not seat.Reseating then
					seat.Reseating = true
					task.delay(0.3, function()
						seat.Reseating = false
						if S and seat.Tied and hum.Parent and hum.SeatPart == nil then
							pcall(function()
								seat.Spot.Seat:Sit(hum)
							end)
						end
					end)
				end
			end
		end
	end)
end

-- (admin: start it now, with whoever's in the night)
function Finale.adminStart(): boolean
	if S or ctx.Ending.isOver() then
		return false
	end
	for _, p in ctx.Util.sessionPlayers() do
		if not p:GetAttribute("Dead") and not p:GetAttribute("Escaped") then
			p:SetAttribute("Captured", true)
		end
	end
	S = { Phase = "Intro", Strikes = 0, Seats = {}, Started = os.clock(), Notes = {}, BarsLeft = cfg().Bars, Hatch = 0 }
	task.spawn(function()
		local ok, err = pcall(Finale._begin)
		if not ok then
			warn("[Finale] " .. tostring(err))
		end
	end)
	return true
end

Finale._state = function()
	return S
end

return Finale
