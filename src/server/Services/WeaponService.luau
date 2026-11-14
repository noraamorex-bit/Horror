--[[
	WeaponService (v161) — the Weapon Roll (developer product, 10 R$, Config.Shop.WeaponRoll; weapons in Config.Weapons).

	• Bought in a live night: the server rolls at once (its own RNG, the odds shown in the roll's window) and tells the buyer
	  (Remotes.WeaponRoll); the client spins a strip of cards that stops on that result. The strip's other cards are drawn at
	  the same odds: nothing is staged to look like a near miss.
	• Guarantees, shown in the window: Epic or better at least every Pity.EpicBy rolls, a Legendary every Pity.LegendaryBy
	  (StatsService WeaponPity, saved).
	• A weapon is for tonight (the inventory empties at the next night). A Legendary comes back for LegendaryNights nights.
	  The same melee weapon twice pays DuplicateCoins; a gun or the cannon twice adds its shots.
	• Bought where it can't be used (a night that's over, the lobby): saved, rolled when your next night starts.
	• Where paid random items aren't allowed for a player (PolicyService ArePaidRandomItemsRestricted) the roll isn't offered
	  (attribute RollRestricted) and a purchase is refused.
	• Using one (Remotes.UseItem → Weapons.use): each has its cooldown; Shot / Beam spend a shot; a miss only costs a short
	  cooldown. Hits go through Intruder.weaponTarget / weaponHit. The Slap Glove also sends flying every player
	  whose body it touches (v162: a hitbox in front of you and round the glove; client Troll "slap"), PlayerCooldown apart,
	  never the owner, never someone hiding / tied up / out.
]]

local Players = game:GetService("Players")

local Weapons = {}
local ctx

local rng = Random.new()
local cooldown: { [Player]: { [string]: number } } = {}
local slapAt: { [Player]: number } = {}
local busy: { [Player]: boolean } = {} -- (a charge in progress)

local function W()
	return ctx.Config.Weapons
end

local function now()
	return os.clock()
end

function Weapons.isWeapon(item: any): boolean
	return type(item) == "string" and W().List[item] ~= nil
end

function Weapons.spec(item: string)
	return W().List[item]
end

local function tierRank(tier: string): number
	for i, t in W().Tiers do
		if t.Id == tier then
			return i
		end
	end
	return 1
end
Weapons._tierRank = tierRank

-- pick a kind among `pool` (or every weapon) by Odds
local function pick(minRank: number?): string
	local list = {}
	local total = 0
	for _, k in W().Order do
		local s = W().List[k]
		if tierRank(s.Tier) >= (minRank or 1) then
			table.insert(list, k)
			total += s.Odds
		end
	end
	local x = rng:NextNumber() * total
	for _, k in list do
		x -= W().List[k].Odds
		if x <= 0 then
			return k
		end
	end
	return list[#list]
end

-- one roll for `player`: the kind, with the guarantees applied and the counters moved on
function Weapons.roll(player: Player): string
	local pity = (ctx.Stats and ctx.Stats.weaponPity and ctx.Stats.weaponPity(player)) or { E = 0, L = 0 }
	local P = W().Pity
	local e, l = (pity.E or 0) + 1, (pity.L or 0) + 1
	local kind
	if l >= P.LegendaryBy then
		kind = pick(4)
	elseif e >= P.EpicBy then
		kind = pick(3)
	else
		kind = pick(1)
	end
	local rank = tierRank(W().List[kind].Tier)
	if rank >= 3 then
		e = 0
	end
	if rank >= 4 then
		l = 0
	end
	if ctx.Stats and ctx.Stats.setWeaponPity then
		ctx.Stats.setWeaponPity(player, e, l)
	else
		player:SetAttribute("RollsSinceEpic", e)
		player:SetAttribute("RollsSinceLegendary", l)
	end
	return kind
end

local function live(player: Player): boolean
	local act = workspace:GetAttribute("Act")
	return ctx.Director ~= nil and act ~= nil and act ~= "Lobby" and not workspace:GetAttribute("EndingActive")
		and player:GetAttribute("InGame") == true and not player:GetAttribute("Dead") and not player:GetAttribute("Escaped")
		and not player:GetAttribute("Monster")
end
Weapons.live = live

-- put `kind` in their hands; returns what it came to ("new", "ammo" or "dupe")
local function grant(player: Player, kind: string): string
	local s = W().List[kind]
	local had = ctx.Inventory.has(player, kind)
	if s.Ammo then
		ctx.Inventory.give(player, kind, s.Ammo)
	elseif not had then
		ctx.Inventory.give(player, kind, 1)
	end
	if s.Tier == "Legendary" and ctx.Stats and ctx.Stats.setLegend then
		ctx.Stats.setLegend(player, kind, W().LegendaryNights - 1)
	end
	if had and not s.Ammo then
		if ctx.Economy and ctx.Economy.addCoins then
			ctx.Economy.addCoins(player, W().DuplicateCoins, false, "Weapon roll: duplicate", "WeaponDupe")
		end
		return "dupe"
	end
	return had and "ammo" or "new"
end

local function tierName(tier: string): string
	for _, t in W().Tiers do
		if t.Id == tier then
			return t.Name
		end
	end
	return tier
end

-- roll and show it (the spin), then put it in their hands when the spin stops
function Weapons.rollNow(player: Player, why: string?): string
	local kind = Weapons.roll(player)
	local s = W().List[kind]
	local pity = (ctx.Stats and ctx.Stats.weaponPity and ctx.Stats.weaponPity(player)) or {
		E = player:GetAttribute("RollsSinceEpic") or 0, L = player:GetAttribute("RollsSinceLegendary") or 0 }
	ctx.Remotes.WeaponRoll:FireClient(player, kind, s.Tier, pity.E or 0, pity.L or 0, why)
	if ctx.Journey then
		ctx.Journey.event(player, "Roll", kind)
	end
	task.delay(W().SpinTime, function()
		if not player.Parent then
			return
		end
		local got = live(player) and grant(player, kind) or nil
		if not got then
			-- (the night ended under the spin: it waits for the next one)
			if ctx.Stats and ctx.Stats.addRollCredit then
				ctx.Stats.addRollCredit(player)
			end
			return
		end
		if got == "dupe" then
			ctx.Remotes.Notify:FireClient(player, "You already had the " .. s.Name .. ": +" .. W().DuplicateCoins .. " coins.", "info")
		end
		if tierRank(s.Tier) >= 3 then
			local line = (s.Tier == "Legendary" and "🌟 " or "⚡ ") .. player.DisplayName .. " rolled a " .. tierName(s.Tier) .. " " .. s.Name .. "!"
			for _, q in Players:GetPlayers() do
				if q ~= player and q:GetAttribute("InGame") then
					ctx.Remotes.Notify:FireClient(q, line, "info")
				end
			end
			ctx.Director.logTruthRaw(player.DisplayName .. " rolled a " .. s.Name .. ".")
		end
	end)
	return kind
end

function Weapons.receipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if live(player) then
		Weapons.rollNow(player, "bought")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if ctx.Stats and ctx.Stats.addRollCredit and ctx.Stats.addRollCredit(player) then
		ctx.Remotes.Notify:FireClient(player, "Saved: your weapon roll spins when your next night starts.", "info")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- the night starts: the Legendary's nights left, and any rolls saved for now (one spin each, a few seconds apart)
function Weapons.nightStart(player: Player)
	local legend = ctx.Stats and ctx.Stats.takeLegendNight and ctx.Stats.takeLegendNight(player)
	if legend and W().List[legend] then
		local s = W().List[legend]
		ctx.Inventory.give(player, legend, s.Ammo or 1)
		task.delay(4, function()
			if player.Parent and player:GetAttribute("InGame") then
				ctx.Remotes.Notify:FireClient(player, "🌟 Your " .. s.Name .. " is back for tonight.", "done")
			end
		end)
	end
	local n = ctx.Stats and ctx.Stats.spendRollCredits and ctx.Stats.spendRollCredits(player) or 0
	for i = 1, n do
		task.delay(8 + (i - 1) * (W().SpinTime + 2), function()
			if player.Parent and live(player) then
				Weapons.rollNow(player, "saved")
			elseif player.Parent and ctx.Stats and ctx.Stats.addRollCredit then
				ctx.Stats.addRollCredit(player)
			end
		end)
	end
end

local function ready(player: Player, kind: string): boolean
	local t = cooldown[player] and cooldown[player][kind]
	return not t or now() >= t
end

local function setCooldown(player: Player, kind: string, seconds: number)
	cooldown[player] = cooldown[player] or {}
	cooldown[player][kind] = now() + seconds
	-- (the client draws the cooldown on the hotbar slot)
	local tool = ctx.Tools and ctx.Tools.find and ctx.Tools.find(player, kind)
	if tool then
		tool:SetAttribute("ReadyAt", workspace:GetServerTimeNow() + seconds)
	end
end
Weapons._cooldown = function(player, kind) return cooldown[player] and cooldown[player][kind] end -- (tests)

local function slappable(target: Player, by: Player): boolean
	return target ~= by and target:GetAttribute("InGame") == true and not target:GetAttribute("Hiding")
		and not target:GetAttribute("Captured") and not target:GetAttribute("Dead") and not target:GetAttribute("Escaped")
		and not target:GetAttribute("Monster") and not table.find(ctx.Config.Admins or {}, target.UserId)
end

-- (v162) whoever the glove touches: every player whose body is inside the space the glove sweeps through in front of you
-- (a box HitBox wide/high/deep, HitAhead in front of your chest, turned the way you swing) or around the glove itself
local function slapTargets(player: Player, aim: Vector3, s): { Player }
	local r = ctx.Util.getRoot(player)
	if not r then
		return {}
	end
	local look = Vector3.new(aim.X, 0, aim.Z)
	look = look.Magnitude > 0.01 and look.Unit or Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z).Unit
	local chars = {}
	local owner: { [Instance]: Player } = {}
	for _, q in Players:GetPlayers() do
		if slappable(q, player) and q.Character then
			table.insert(chars, q.Character)
			owner[q.Character] = q
		end
	end
	if #chars == 0 then
		return {}
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = chars
	local box = s.HitBox or Vector3.new(6, 6, 6)
	local centre = r.Position + Vector3.new(0, 0.5, 0) + look * (s.HitAhead or 3.5)
	local found = workspace:GetPartBoundsInBox(CFrame.lookAt(centre, centre + look), box, params)
	-- (the glove in your hand: a little box round its palm)
	local tool = ctx.Tools and ctx.Tools.find and ctx.Tools.find(player, "SlapGlove")
	local palm = tool and tool.Parent == player.Character and tool:FindFirstChild("Palm") :: BasePart?
	if palm then
		for _, part in workspace:GetPartBoundsInBox(palm.CFrame, palm.Size + Vector3.new(2, 2, 2), params) do
			table.insert(found, part)
		end
	end
	local out, seen = {}, {}
	for _, part in found do
		local model = part:FindFirstAncestorOfClass("Model")
		local q = model and owner[model]
		if q and not seen[q] then
			seen[q] = true
			table.insert(out, q)
		end
	end
	return out
end
Weapons._slapTargets = slapTargets -- (tests)

local function fx(player: Player, kind: string, what: string, a: any?, b: any?)
	ctx.Remotes.WeaponFx:FireAllClients(player.UserId, kind, what, a, b)
end

local function swingSound(s, at: Vector3)
	ctx.Audio.playAt(rng:NextNumber() < 0.5 and "WeaponSwing" or "WeaponSwing2", at, { Caption = false })
end

-- use `kind` aimed along `aim` (a unit vector, or nil: where they face)
function Weapons.use(player: Player, kind: string, aim: Vector3?): string
	local s = W().List[kind]
	if not s or not ctx.Inventory.has(player, kind) or busy[player] then
		return "no"
	end
	if not ready(player, kind) then
		return "cooldown"
	end
	local r = ctx.Util.getRoot(player)
	local head = player.Character and player.Character:FindFirstChild("Head") :: BasePart?
	if not r or not head then
		return "no"
	end
	local look = aim or r.CFrame.LookVector
	local ranged = s.Kind == "Shot" or s.Kind == "Beam"
	-- (no shot wasted before he's out hunting: same as the taser)
	if ranged and not ctx.Intruder.weaponable() then
		ctx.Audio.caption("Save it for him.", nil, nil, { player })
		return "saved"
	end
	-- (the body moves on every screen: client Actions)
	if ctx.Interaction and ctx.Interaction.act then
		ctx.Interaction.act(player, ranged and "Shoot" or (s.Kind == "Slap" and "Slap" or "Swing"))
	end
	local function finish(): string
		local hit, at = ctx.Intruder.weaponTarget(player, look, s)
		local result = "miss"
		if hit then
			result = ctx.Intruder.weaponHit(player, s)
		end
		local from = head.Position + Vector3.new(0, -0.4, 0) + look * 1.5
		if ranged then
			ctx.Inventory.take(player, kind)
			local to = at
			if not to then
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { (player.Character :: any) :: Instance }
				local res = workspace:Raycast(from, look * s.Range, params)
				to = res and res.Position or (from + look * s.Range)
			end
			ctx.Audio.playAt(s.Kind == "Beam" and "PlasmaBlast" or "GunShot", from, { Caption = false })
			ctx.Noise.emit(r.Position, s.Noise or 40, kind, player)
			fx(player, kind, s.Kind == "Beam" and "beam" or "shot", from, to)
			local left = ctx.Inventory.count(player, kind)
			if left <= 0 then
				ctx.Audio.caption(s.Name .. ": empty.", nil, nil, { player })
			end
		else
			swingSound(s, r.Position)
			fx(player, kind, s.Kind == "Slap" and "slap" or "swing", r.Position, look)
			if hit then
				ctx.Audio.playAt(s.Kind == "Slap" and "Slap" or (kind == "Bat" and "BatHit" or "BladeHit"), at or r.Position, { Caption = false })
				if s.Kind == "Slap" then
					ctx.Audio.playAt("SlapCrack", at or r.Position, { Caption = false })
				end
			end
		end
		-- the glove on players: everyone it touches goes flying (him too, in the same swing)
		local slapped = 0
		if s.Kind == "Slap" and now() >= (slapAt[player] or 0) then
			for _, q in slapTargets(player, look, s) do
				local qr = ctx.Util.getRoot(q)
				local dir = qr and (qr.Position - r.Position) or look
				dir = Vector3.new(dir.X, 0, dir.Z)
				-- (flung away from you, a little along your swing so a friend right beside you still flies forward)
				local fling = (dir.Magnitude > 0.01 and dir.Unit or look) + look * 0.6
				ctx.Remotes.Troll:FireClient(q, "slap", player.DisplayName, fling)
				ctx.Audio.playAt("Slap", qr and qr.Position or r.Position, { Caption = false })
				slapped += 1
				if ctx.Journey then
					ctx.Journey.event(player, "WeaponHit", kind .. ":player")
				end
			end
			if slapped > 0 then
				slapAt[player] = now() + (s.PlayerCooldown or 3)
				ctx.Audio.playAt("SlapCrack", r.Position + look * 3, { Caption = false })
				if not hit then
					setCooldown(player, kind, s.PlayerCooldown or 3)
					return "slapped"
				end
			end
		end
		if hit and result ~= "none" then
			setCooldown(player, kind, s.Cooldown)
			ctx.Remotes.Shake:FireClient(player, 0.35, 0.3)
			if result == "stun" then
				ctx.Remotes.Notify:FireClient(player, "Hit! He's down. RUN.", "objective")
			else
				ctx.Audio.caption("He shrugged it off. Run!", nil, nil, { player })
			end
			ctx.Director.logTruthRaw((player:GetAttribute("RoleName") or player.Name) .. " hit Curtis with the " .. s.Name .. ".")
			if ctx.Journey then
				ctx.Journey.event(player, "WeaponHit", kind .. ":" .. result)
			end
			return result
		end
		-- (a miss: only a short wait; ranged weapons keep their own cooldown so nobody empties one in a second)
		setCooldown(player, kind, ranged and math.min(s.Cooldown, 1.5) or 1.2)
		return "miss"
	end
	if s.Charge and s.Charge > 0 then
		-- (the cannon winds up: everyone sees it charge)
		busy[player] = true
		fx(player, kind, "charge", s.Charge)
		task.delay(s.Charge, function()
			busy[player] = nil
			if player.Parent and ctx.Inventory.has(player, kind) and player:GetAttribute("InGame")
				and not player:GetAttribute("Hiding") and not player:GetAttribute("Captured") then
				finish()
			end
		end)
		return "charging"
	end
	return finish()
end

-- paid random items: offered only where they're allowed
local function policy(p: Player)
	task.spawn(function()
		local ok, info = pcall(function()
			return game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(p)
		end)
		if ok and type(info) == "table" and info.ArePaidRandomItemsRestricted then
			p:SetAttribute("RollRestricted", true)
		end
	end)
end
Weapons._policy = policy

function Weapons.restricted(p: Player): boolean
	return p:GetAttribute("RollRestricted") == true
end

function Weapons.reset()
	cooldown = {}
	slapAt = {}
	busy = {}
end

function Weapons.init(c)
	ctx = c
	ctx.Weapons = Weapons
end

function Weapons.start()
	for _, p in Players:GetPlayers() do
		policy(p)
	end
	Players.PlayerAdded:Connect(policy)
	Players.PlayerRemoving:Connect(function(p)
		cooldown[p] = nil
		slapAt[p] = nil
		busy[p] = nil
	end)
end

return Weapons
