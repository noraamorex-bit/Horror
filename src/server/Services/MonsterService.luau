--[[
	MonsterService — "Become him" (a developer product, Config.Shop.BecomeHim, bought again every
	night). Co-op only: one player per night stops being a survivor and drives Curtis for the rest
	of it, through the brain-off puppet the secret ending uses (Intruder.puppet).

	• Bought before the blackout: it waits, and they become him when the hunt starts
	  (Intruder.setMode("Hunt") hands over). Bought during the hunt: right away.
	• Their own character is parked out of sight; their client sends the move direction from their
	  controls (MonsterAction "Move") and the server walks him there, a little under a survivor's
	  walk; LUNGE is a short burst on a cooldown. Anyone out in the open he touches is caught.
	  SEARCH opens the hiding spot in front of him: whoever's inside gets the heartbeat minigame.
	• They hear what he hears: every survivor noise shows up for them as a ping (Remotes.Monster).
	• A taser hit or pepper spray stuns him (Monster.stun).
	• Bought when it can't be used (someone else already is him, the night's over, they're out):
	  saved for a later night (StatsService MonsterCredits) and offered then, for free.
	• Survivors are told someone has become him. Util.activePlayers / sessionPlayers leave the
	  monster out, so everything that counts survivors (endings, the last chance) still works.
	• The player leaves: the AI takes over again.

	Monster.canBuy(player) -> (ok, why)    Monster.pending() / active() / isMonster(player)
	Monster.takeOver() -> bool             Monster.stun(seconds)   Monster.onReceipt(info)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Monster = {}
local ctx

local PARK = Vector3.new(0, -250, 0)

local S: any = {}
local function fresh()
	return {
		Buyer = nil :: Player?,
		Active = false,
		Puppet = nil,
		Dir = Vector3.zero,
		Captures = 0,
		LungeUntil = 0,
		NextLunge = 0,
		GrabReadyAt = 0,
		SearchUntil = 0,
		NextSearch = 0,
		StunUntil = 0,
		Credit = false, -- (they used a saved one: if it can't happen after all, it goes back)
	}
end

local function now()
	return os.clock()
end

local function cfg()
	return ctx.Config.Monster
end

function Monster.init(c)
	ctx = c
	ctx.Monster = Monster
	S = fresh()
end

function Monster.isMonster(p: Player?): boolean
	return p ~= nil and p:GetAttribute("Monster") == true
end

function Monster.active(): boolean
	return S.Active == true
end

function Monster.pending(): boolean
	return S.Buyer ~= nil and not S.Active
end

function Monster.buyer(): Player?
	return S.Buyer
end

local function survivors(): { Player }
	return ctx.Util.sessionPlayers()
end

-- a night is on, it's co-op, nobody is him yet, and this player is still in it
function Monster.canBuy(p: Player): (boolean, string?)
	local act = workspace:GetAttribute("Act")
	if not (act == "Evening" or act == "SmallThings" or act == "SomeoneElse" or act == "Guest") then
		return false, "Only during a night."
	end
	if workspace:GetAttribute("EndingActive") or (ctx.Ending and ctx.Ending.isOver()) then
		return false, "The night is over."
	end
	if S.Buyer then
		return false, "Someone already is."
	end
	if #survivors() < (cfg().MinPlayers or 2) then
		return false, "Only with friends in the house."
	end
	if not p:GetAttribute("InGame") or p:GetAttribute("Captured") or p:GetAttribute("Dead") or p:GetAttribute("Escaped") then
		return false, "Only while you're still in the night."
	end
	return true, nil
end

-- the shop button's switch: on while someone could buy it now
local function publish()
	local open = false
	if not S.Buyer then
		local act = workspace:GetAttribute("Act")
		open = (act == "Evening" or act == "SmallThings" or act == "SomeoneElse" or act == "Guest")
			and not workspace:GetAttribute("EndingActive") and #survivors() >= (cfg().MinPlayers or 2)
	end
	if workspace:GetAttribute("BecomeHimOpen") ~= (open or nil) then
		workspace:SetAttribute("BecomeHimOpen", open or nil)
	end
end

local function tell(p: Player?, state)
	if p and p.Parent then
		ctx.Remotes.Monster:FireClient(p, state)
	end
end

local function hud()
	local p = S.Buyer
	if not p then
		return
	end
	tell(p, {
		Active = S.Active,
		Pending = not S.Active or nil,
		Captures = S.Captures,
		LungeReady = now() >= S.NextLunge,
		Model = S.Puppet and S.Puppet.model() or nil,
	})
end

-- hide the buyer's own character out of the way (and out of every survivor list)
local function park(p: Player)
	local char = p.Character
	if not char then
		return
	end
	for _, d in char:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		char:PivotTo(CFrame.new(PARK))
		root.Anchored = true
	end
end

-- where he comes in: somewhere none of them are (the garage hatch, or the far end of the house)
local function entry(): Vector3
	local best, bestD = nil, -1
	for _, n in ctx.Layout.Nodes do
		local d = math.huge
		for _, p in ctx.Util.activePlayers() do
			local r = ctx.Util.getRoot(p)
			if r then
				d = math.min(d, (r.Position - n.Pos).Magnitude)
			end
		end
		if n.Room ~= "Boiler" and n.Room ~= "Basement" and d > bestD then
			best, bestD = n.Pos, d
		end
	end
	return best or ctx.Layout.Attic.GarageHatchBelow
end

function Monster.takeOver(): boolean
	local p = S.Buyer
	if not p or S.Active then
		return false
	end
	if not p.Parent or not p:GetAttribute("InGame") or p:GetAttribute("Captured") or p:GetAttribute("Dead") or p:GetAttribute("Escaped")
		or #survivors() < 2 then
		-- (they're out of the night before it could happen: the purchase is kept for another night)
		if p.Parent and ctx.Stats and ctx.Stats.addMonsterCredit then
			ctx.Stats.addMonsterCredit(p)
			ctx.Remotes.Notify:FireClient(p, "Saved for another night: BECOME HIM is free next time.", "info")
		end
		p:SetAttribute("MonsterPending", nil)
		S.Buyer = nil
		publish()
		return false
	end
	if p:GetAttribute("Hiding") then
		ctx.Hiding.exit(p)
	end
	S.Active = true
	p:SetAttribute("MonsterPending", nil)
	p:SetAttribute("Monster", true)
	p:SetAttribute("FlashlightOn", nil)
	park(p)
	local wasIn = ctx.Intruder.isInHouse()
	local at = wasIn and ctx.Intruder.position() or nil
	S.Puppet = ctx.Intruder.puppet()
	S.Puppet.place(at or entry())
	S.Puppet.gait(nil)
	S.GrabReadyAt = now() + 3
	ctx.Audio.playAt("Roar", S.Puppet.position() :: Vector3, { Caption = false })
	for _, o in Players:GetPlayers() do
		if o ~= p and o:GetAttribute("InGame") then
			ctx.Remotes.Notify:FireClient(o, (p.DisplayName or p.Name) .. " has become HIM. Hide.", "danger")
		end
	end
	if ctx.Journey then
		ctx.Journey.event(p, "Monster", "On")
	end
	if ctx.Director and ctx.Director.logTruthRaw then
		ctx.Director.logTruthRaw((p:GetAttribute("RoleName") or p.Name) .. " became him.")
	end
	hud()
	publish()
	return true
end

function Monster.grant(p: Player, fromCredit: boolean?): boolean
	local ok = Monster.canBuy(p)
	if not ok then
		return false
	end
	S.Buyer = p
	S.Credit = fromCredit == true
	p:SetAttribute("MonsterPending", true)
	publish()
	if ctx.Intruder.isHunting() or workspace:GetAttribute("Act") == "Guest" then
		Monster.takeOver()
	else
		ctx.Remotes.Notify:FireClient(p, "When the lights go out, you become him.", "objective")
		hud()
	end
	return true
end

-- a taser hit or pepper spray: he can't move for a few seconds
function Monster.stun(seconds: number)
	if not S.Active then
		return
	end
	S.StunUntil = now() + seconds
	if S.Puppet then
		S.Puppet.stop()
	end
	tell(S.Buyer, { Active = true, Stunned = seconds, Captures = S.Captures, Model = S.Puppet and S.Puppet.model() or nil })
end

-- the night's over, or they left: the puppet goes back to the AI (or stops with the ending)
local function release(resumeAI: boolean)
	local p = S.Buyer
	local was = S.Active
	if S.Puppet then
		S.Puppet.release()
	end
	if p then
		p:SetAttribute("Monster", nil)
		p:SetAttribute("MonsterPending", nil)
		if p.Parent then
			tell(p, nil)
		end
	end
	S = fresh()
	if was and resumeAI and not (ctx.Ending and ctx.Ending.isOver()) then
		ctx.Intruder.setMode("Hunt")
	end
	publish()
end

function Monster.reset()
	release(false)
end

-- (the owner's admin panel) stop being him: the AI takes over again and you're back in the house
function Monster.adminRelease(): boolean
	local p = S.Buyer
	if not p then
		return false
	end
	release(true)
	if p.Parent then
		pcall(function()
			p:LoadCharacter()
		end)
	end
	return true
end

-- a survivor out in the open, close enough to grab
local function tryGrab(pos: Vector3)
	if now() < S.GrabReadyAt then
		return
	end
	for _, o in ctx.Util.activePlayers() do
		if not o:GetAttribute("Hiding") then
			local r = ctx.Util.getRoot(o)
			if r and (r.Position - pos).Magnitude <= cfg().GrabRange and math.abs(r.Position.Y - pos.Y) < 5 then
				o:SetAttribute("CaughtHow", "Open")
				if ctx.Capture.capture(o) then
					S.Captures += 1
					S.GrabReadyAt = now() + cfg().GrabCooldown
					hud()
					return
				end
			end
		end
	end
end

-- SEARCH: the hiding spot right in front of him
local function search()
	if not S.Active or now() < S.NextSearch or now() < S.SearchUntil or now() < S.StunUntil then
		return
	end
	local pos = S.Puppet and S.Puppet.position()
	if not pos then
		return
	end
	local best, bestD = nil, cfg().SearchRange
	for _, spot in ctx.Hiding.spotsNear(pos, cfg().SearchRange) do
		local d = (spot.Exit.Position - pos).Magnitude
		if d < bestD then
			best, bestD = spot, d
		end
	end
	S.NextSearch = now() + cfg().SearchCooldown
	if not best then
		tell(S.Buyer, { Active = true, Captures = S.Captures, Model = S.Puppet.model(), Say = "Nowhere to look here." })
		return
	end
	S.Puppet.stop()
	S.Puppet.face(best.Position)
	local who = ctx.Hiding.occupant(best)
	ctx.Audio.playAt("ManWhisper", best.Position, { CaptionText = "[Something right outside. Listening.]", CaptionRange = 18 })
	if not who then
		S.SearchUntil = now() + 1.5
		tell(S.Buyer, { Active = true, Captures = S.Captures, Model = S.Puppet.model(), Say = "Empty." })
		return
	end
	local dur = cfg().ListenTime
	S.SearchUntil = now() + dur + 0.5
	tell(S.Buyer, { Active = true, Captures = S.Captures, Model = S.Puppet.model(), Say = "Someone's in there. Listening..." })
	local myS = S
	ctx.Heartbeat.begin(who, dur, function()
		if S ~= myS or not S.Active then
			return
		end
		if ctx.Hiding.occupant(best) ~= who then
			return
		end
		ctx.Audio.playAt("DoorYank", best.Position, { CaptionText = "[The door is ripped open]", CaptionRange = 50 })
		ctx.Hiding.exit(who, true)
		who:SetAttribute("CaughtHow", "Hiding")
		if ctx.Capture.capture(who) then
			S.Captures += 1
			S.GrabReadyAt = now() + cfg().GrabCooldown
			S.SearchUntil = 0
			hud()
		end
	end)
	task.delay(dur + 0.3, function()
		if S == myS and ctx.Heartbeat.isActive(who) then
			ctx.Heartbeat.pass(who)
		end
	end)
end

local function tick()
	if not S.Active then
		return
	end
	local p = S.Buyer
	if not p or not p.Parent then
		release(true)
		return
	end
	local pos = S.Puppet and S.Puppet.position()
	if not pos then
		return
	end
	if now() < S.StunUntil or now() < S.SearchUntil then
		S.Puppet.stop()
		return
	end
	local dir = S.Dir
	if dir.Magnitude > 0.1 then
		local lunging = now() < S.LungeUntil
		local speed = lunging and cfg().LungeSpeed or cfg().WalkSpeed
		local flat = Vector3.new(dir.X, 0, dir.Z).Unit
		S.Puppet.moveTo(pos + flat * 4, speed, lunging)
	else
		S.Puppet.stop()
	end
	tryGrab(pos)
end

function Monster.onReceipt(info): Enum.ProductPurchaseDecision
	local p = Players:GetPlayerByUserId(info.PlayerId)
	if not p then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if Monster.grant(p) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- (paid but it can't happen now: kept for another night)
	if ctx.Stats and ctx.Stats.addMonsterCredit and ctx.Stats.addMonsterCredit(p) then
		ctx.Remotes.Notify:FireClient(p, "Saved for another night: BECOME HIM is free next time.", "info")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function Monster.start()
	ctx.Remotes.MonsterAction.OnServerEvent:Connect(function(p, action, arg)
		if action == "UseCredit" then
			if (tonumber(p:GetAttribute("MonsterCredits")) or 0) > 0 and Monster.canBuy(p) and ctx.Stats.spendMonsterCredit(p) then
				Monster.grant(p, true)
			end
			return
		end
		if p ~= S.Buyer or not S.Active then
			return
		end
		if action == "Move" then
			if typeof(arg) == "Vector3" and arg.Magnitude < 1.5 then
				S.Dir = arg
			end
		elseif action == "Lunge" then
			if now() >= S.NextLunge and now() >= S.StunUntil then
				S.LungeUntil = now() + cfg().LungeTime
				S.NextLunge = now() + cfg().LungeCooldown
				local at = S.Puppet and S.Puppet.position()
				if at then
					ctx.Audio.playAt("Roar", at, { Caption = true })
				end
				hud()
				task.delay(cfg().LungeCooldown, hud)
			end
		elseif action == "Search" then
			search()
		end
	end)
	-- what he hears, they hear: survivors' noises as pings
	ctx.Noise.listen(function(ev)
		if not S.Active or not ev.Source or ev.Source == S.Buyer or ev.Kind == "Intruder" then
			return
		end
		if typeof(ev.Position) == "Vector3" then
			tell(S.Buyer, { Ping = ev.Position, Radius = ev.Radius })
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		if p == S.Buyer then
			release(true)
		end
	end)
	-- the night's over: he stops (the ending does that), they keep the "Monster" mark until the next
	-- night (their card says YOU WERE HIM, and the survivors' lists still leave them out)
	workspace:GetAttributeChangedSignal("EndingActive"):Connect(function()
		if workspace:GetAttribute("EndingActive") and S.Buyer then
			local p = S.Buyer
			S.Active = false
			S.Dir = Vector3.zero
			if p and p.Parent then
				p:SetAttribute("MonsterPending", nil)
				tell(p, nil)
				ctx.Remotes.Notify:FireClient(p, string.format("You were him tonight. You caught %d.", S.Captures), "done")
			end
		end
	end)
	workspace:GetAttributeChangedSignal("Act"):Connect(publish)
	local lastPublish = 0
	RunService.Heartbeat:Connect(function()
		tick()
		if now() - lastPublish >= 1 then
			lastPublish = now()
			publish()
		end
	end)
end

Monster._state = function()
	return S
end
Monster._tick = tick
Monster._search = search

return Monster
