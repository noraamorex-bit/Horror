local H = require("./env")
local ok, err = pcall(function()
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Config.Intruder.Brain = "Classic" -- (this test covers the classic brain; figure_test covers the Figure one)
	ctx.Rooms = H.load("RS/Shared/Rooms")
	ctx.Sounds = H.load("RS/Shared/Sounds")
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Util = H.load("RS/Shared/Util")
	ctx.Builder = H.load("Server/World/Builder")
	ctx.Layout = H.load("Server/World/Layout")
	local voiced = {} -- (v106: what he said: {text, kind})
	ctx.Remotes = setmetatable({}, { __index = function(_, k) return { FireClient = function() end, FireAllClients = function(_, a, b) if k == "HisVoice" then table.insert(voiced, { a, b }) end end, OnServerEvent = H.signal() } end })
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
	ctx.restart = function() print("restart called") end
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	print("started")
	assert(not ctx.Intruder._speak("Murmur", true), "he says nothing before the hunt")
	local R = H.roblox
	-- a controllable clock: waits advance it, so spawned loops run straight through
	local T = 5000
	local R = H.roblox
	H.clock = function() return T end
	H.task.wait = function(s) T += (s or 0.03); return s or 0.03 end
	local hb = H.services.RunService.Heartbeat
	-- straight-line paths (there's no navmesh in here)
	rawset(H.services.PathfindingService, "CreatePath", function()
		local path = { Status = H.roblox.Enum.PathStatus.Success }
		function path:ComputeAsync(a, b) self.A, self.B = a, b end
		function path:GetWaypoints() return { { Position = self.A }, { Position = self.B } } end
		return path
	end)
	local function tick(seconds)
		for _ = 1, math.floor(seconds / 0.1) do
			T += 0.1
			-- walk him toward his navigation goal (no physics in here)
			local st = ctx.Intruder._state()
			if st.Root and st.Nav and st.Nav.Goal and not st.Root.Anchored then
				local p = st.Root.Position
				local g = st.Nav.Goal
				local step = (st.Humanoid.WalkSpeed or 10) * 0.1
				local dv = g - p
				if dv.Magnitude > 0.1 then
					local np = dv.Magnitude <= step and g or p + dv.Unit * step
					st.Root.CFrame = R.CFrame.lookAt(np, np + R.Vector3.new(dv.X, 0, dv.Z + 1e-4))
				end
			end
			hb:Fire(0.1)
		end
	end
	local function mkPlayer(name, at)
		local p = H.wrap(R.Instance.new("Player"))
		p.Name = name
		local char = H.Instance.new("Model")
		local rootPart = H.Instance.new("Part", char)
		rootPart.Name = "HumanoidRootPart"
		local head = H.Instance.new("Part", char)
		head.Name = "Head"
		local hum = H.Instance.new("Humanoid", char)
		hum.Health = 100
		rawset(p, "Character", char)
		rawset(p, "Parent", H.workspaceRoot)
		p:SetAttribute("InGame", true)
		rootPart.CFrame = R.CFrame.new(at)
		head.CFrame = R.CFrame.new(at + R.Vector3.new(0, 1.5, 0))
		return p, rootPart, head
	end
	local a, aRoot, aHead = mkPlayer("Alex", R.Vector3.new(-22, 4, -18))
	local b, bRoot, bHead = mkPlayer("Bo", R.Vector3.new(-30, 22, 20))
	H.services.Players.GetPlayers = function() return { a, b } end
	print("hiding spots", #ctx.Hiding.all())
	local I = ctx.Intruder
	ctx.Config.Intruder.AmbushChance = 1
	ctx.Director.startAct("SomeoneElse")
	I.setMode("Hunt")
	-- (no v104 surprises in here: they move him about on their own clock; leap_test covers them)
	ctx.Intruder._state().NextSurprise = math.huge
	print("placed at", I.position(), "alex", aRoot.Position, ctx.Util.getRoot(a) and ctx.Util.getRoot(a).Position)
	tick(0.3)
	-- he comes in far from everyone (the owner: "why does he spawn upstairs. Spawn him far away")
	local entry = ctx.Intruder._state().EntrySpot
	local dmin = math.min((entry - aRoot.Position).Magnitude, (entry - bRoot.Position).Magnitude)
	print("came in at", entry, ("%.0f studs from the nearest"):format(dmin))
	assert(dmin >= 30, ("he comes in far from everyone (%.0f studs)"):format(dmin))
	print("captured?", a:GetAttribute("Captured"), b:GetAttribute("Captured"))
	print("1 state", I.getState(), "inHouse", I.isInHouse())
	assert(I.getState() == "Prowl", "starts prowling")
	tick(1)
	-- he should be heading for the nearest felt player
	local ip = I.position()
	print("2 intruder at", ip, "dist to Alex", (ip - aRoot.Position).Magnitude, "to Bo", (ip - bRoot.Position).Magnitude)
	-- Alex hides in the nearest spot, out of his sight
	local spots = ctx.Hiding.spotsNear(aRoot.Position, 40)
	local spot = spots[1]
	print("Alex hides in", spot and spot.Name)
	-- make sure he isn't 'seeing' it: move him far away first
	ctx.Intruder.position()
	ctx.Hiding.enter(a, spot)
	-- Bo hides too, so nobody is left to feel
	local bspot = ctx.Hiding.spotsNear(bRoot.Position, 60)[1]
	ctx.Hiding.enter(b, bspot)
	tick(0.5)
	print("3 after both hid:", I.getState())
	-- let the search run its course
	local seen = {}
	for _ = 1, 400 do
		tick(0.1)
		local st = I.getState()
		if seen[#seen] ~= st then table.insert(seen, st) end
		if a:GetAttribute("Captured") or b:GetAttribute("Captured") then break end
	end
	print("4 states:", table.concat(seen, " > "))
	print("   captured: Alex", a:GetAttribute("Captured"), "Bo", b:GetAttribute("Captured"))
	-- out of hiding: grace, then he feels them again
	if not a:GetAttribute("Captured") then ctx.Hiding.exit(a) end
	if not b:GetAttribute("Captured") then ctx.Hiding.exit(b) end
	local t0 = T
	local back
	for _ = 1, 700 do
		tick(0.1)
		if I.getState() == "Prowl" or I.getState() == "Chase" then back = T - t0 break end
	end
	print("5 hunting again after", back, "s, state", I.getState())
	-- a help call in Withdraw: frenzy, hunts immediately
	I.onHelpCalled(a)
	print("6 after help call", I.getState())
	-- seen up close: chase, grab
	local ipos = I.position()
	aRoot.CFrame = R.CFrame.lookAt(ipos + R.Vector3.new(0, -0.9, -4), ipos)
	aHead.CFrame = aRoot.CFrame + R.Vector3.new(0, 1.5, 0)
	for _ = 1, 30 do
		tick(0.1)
		if a:GetAttribute("Captured") then break end
	end
	print("8 grabbed when close:", a:GetAttribute("Captured"), I.getState())
	-- walking off after the capture: he ignores people only for a few seconds, then anyone he
	-- sees close gets chased (the owner stood in front of him while he walked away)
	if a:GetAttribute("Captured") then
		assert(I.getState() == "Retreat", "after a capture he walks off")
		local function standInFront()
			local head = ctx.Intruder.getHead()
			local hp = head.Position
			local look = head.CFrame.LookVector
			local at = R.Vector3.new(hp.X + look.X * 9, hp.Y - 1.5, hp.Z + look.Z * 9)
			bRoot.CFrame = R.CFrame.new(at)
			bHead.CFrame = R.CFrame.new(at + R.Vector3.new(0, 1.5, 0))
		end
		if b:GetAttribute("Captured") then ctx.Capture.release(b) end -- (Bo may have been caught earlier on)
		local spared = ctx.Intruder._state().Spared
		if spared then spared[b] = nil end -- (and then freed: the just-freed grace isn't what this checks)
		if b:GetAttribute("Hiding") then ctx.Hiding.exit(b) end
		b:SetAttribute("FlashlightOn", true)
		standInFront()
		tick(1)
		assert(I.getState() == "Retreat", "the first seconds: he walks on")
		local chased = false
		for _ = 1, 80 do
			standInFront()
			tick(0.1)
			if I.getState() == "Chase" then chased = true break end
		end
		print("8b seen close while walking off:", I.getState())
		assert(chased, "seen close while walking off: he comes for you")
		b:SetAttribute("FlashlightOn", nil)
		bRoot.CFrame = R.CFrame.new(-30, 22, 20)
		bHead.CFrame = R.CFrame.new(-30, 23.5, 20)
	end
	-- seen getting into a hiding spot: he opens that one
	ctx.Capture.release(a)
	aRoot.CFrame = R.CFrame.new(60, 4, 60)
	aHead.CFrame = R.CFrame.new(60, 5.5, 60)
	ctx.Hiding.enter(a, ctx.Hiding.spotsNear(R.Vector3.new(0, 0, 0), 200)[5])
	for _ = 1, 400 do tick(0.1) if I.getState() ~= "Retreat" then break end end
	print("9 after retreat", I.getState())
	local near = ctx.Hiding.spotsNear(I.position(), 60)
	local close = near[1]
	bRoot.CFrame = R.CFrame.lookAt(I.position() + R.Vector3.new(0, -0.9, -12), I.position())
	bHead.CFrame = bRoot.CFrame + R.Vector3.new(0, 1.5, 0)
	tick(0.3)
	print("   Bo visible? state", I.getState())
	-- (no physics here: put him at the spot, as if he'd walked over)
	local hrp = H.unwrap(ctx.World.folder()):FindFirstChild("Curtis", true):FindFirstChild("HumanoidRootPart")
	hrp.CFrame = R.CFrame.new(close.Exit.Position + R.Vector3.new(0, 2, 0))
	ctx.Hiding.enter(b, close)
	tick(0.2)
	print("10 Bo hid in view; state", I.getState(), "Alex captured", a:GetAttribute("Captured"), "dead", a:GetAttribute("Dead"))
	for _ = 1, 300 do tick(0.1) if b:GetAttribute("Captured") then break end end
	print("   Bo captured:", b:GetAttribute("Captured"))
	-- client gait attribute
	local model = H.unwrap(ctx.World.folder()):FindFirstChild("Curtis", true)
	print("7 gait attr", model and model:GetAttribute("Gait"), "creature", model and model:GetAttribute("Creature"))
	-- a 911 caller does as told and hides in the spot right by the phone: while their head start
	-- lasts he charges at the call but doesn't go straight to their spot (v87: the bathroom trap)
	do
		ctx.Capture.release(a)
		if a:GetAttribute("Hiding") then ctx.Hiding.exit(a) end
		local spared = ctx.Intruder._state().Spared
		local hs = ctx.Hiding.spotsNear(R.Vector3.new(35, 18, -11), 14)[1]
		ctx.Hiding.enter(a, hs)
		local hrp = H.unwrap(ctx.World.folder()):FindFirstChild("Curtis", true):FindFirstChild("HumanoidRootPart")
		local function arrive()
			I._charge(hs.Exit.Position, a)
			for _ = 1, 30 do
				hrp.CFrame = R.CFrame.new(hs.Exit.Position + R.Vector3.new(0, 2.5, 0))
				tick(0.1)
				if I.getState() ~= "Charge" or ctx.Intruder._state().Data.Searching then break end
			end
			return I.getState()
		end
		ctx.Intruder.spare(a, 10)
		local s1 = arrive()
		assert(s1 == "Charge" and ctx.Intruder._state().Data.Searching, "in the head start: he arrives and searches around, not straight to their spot (" .. s1 .. ")")
		spared[a] = nil
		I.setMode("Hunt")
		-- (wherever the earlier steps left him, he may already have listened at this spot or seen
		-- them get in: start this check clean)
		ctx.Intruder._state().SpotCooldown[hs] = nil
		ctx.Intruder._state().SawHide[hs] = nil
		local s2 = arrive()
		print("12 caller in the shower: head start", s1, "/ none", s2)
		assert(s2 == "Inspect", "no head start: he heard them get in (" .. s2 .. ")")
		ctx.Hiding.exit(a)
	end
	-- the taser: a shot where you're looking stuns him, then he moves slowly for a while; a miss doesn't
	do
		local st = ctx.Intruder._state()
		if b:GetAttribute("Hiding") then ctx.Hiding.exit(b) end
		ctx.Capture.release(b)
		st.Spared[b] = nil
		I.setMode("Hunt")
		tick(0.5)
		ctx.Inventory.give(b, "Taser", ctx.Config.Taser.Charges)
		local head = ctx.Intruder.getHead()
		-- (far off, beyond the auto-hit range, pointing the wrong way: a miss)
		local far = head.Position + head.CFrame.LookVector * (ctx.Config.Taser.AutoRange + 8) + R.Vector3.new(0, -1.5, 0)
		bRoot.CFrame = R.CFrame.new(far)
		bHead.CFrame = R.CFrame.new(far + R.Vector3.new(0, 1.5, 0))
		ctx.Intruder.onTaser(b, (bHead.Position - head.Position).Unit)
		assert(I.getState() ~= "Stunned", "a miss doesn't stun")
		assert(ctx.Inventory.count(b, "Taser") == ctx.Config.Taser.Charges - 1, "a miss still uses a shot")
		T += ctx.Config.Taser.Cooldown + 0.1
		local at = head.Position + head.CFrame.LookVector * 10 + R.Vector3.new(0, -1.5, 0)
		bRoot.CFrame = R.CFrame.new(at)
		bHead.CFrame = R.CFrame.new(at + R.Vector3.new(0, 1.5, 0))
		local aim = (head.Position + R.Vector3.new(0, -1.2, 0) - (bHead.Position + R.Vector3.new(0, -0.6, 0))).Unit
		local normalChase = ctx.Intruder._tune().ChaseSpeed
		-- (v102: 10 studs off and in plain sight, pointing the wrong way still hits)
		ctx.Intruder.onTaser(b, (bHead.Position - head.Position).Unit)
		print("14 tasered close, aimed away:", I.getState(), "shots left", ctx.Inventory.count(b, "Taser"))
		assert(I.getState() == "Stunned" and st.Data.Taser, "close up, every shot hits")
		ctx.Intruder.onTaser(b, aim)
		assert(ctx.Inventory.count(b, "Taser") == ctx.Config.Taser.Charges - 2, "the cooldown: no double shot")
		tick(ctx.Config.Taser.Stun + 0.5)
		assert(I.getState() ~= "Stunned", "back up after the stun (" .. I.getState() .. ")")
		local slowChase = ctx.Intruder._tune().ChaseSpeed
		print("   chase speed while slowed", slowChase, "normal", normalChase)
		assert(slowChase < normalChase * 0.7, "slowed afterwards")
		tick(ctx.Config.Taser.Slow + 0.5)
		assert(ctx.Intruder._tune().ChaseSpeed == normalChase, "and back to normal later")
		bRoot.CFrame = R.CFrame.new(-30, 22, 20)
		bHead.CFrame = R.CFrame.new(-30, 23.5, 20)
	end
	-- the rocket launcher: a rocket uses a charge; the blast knocks him flat if it reaches him, then he
	-- limps away slowly; a blast far from him is a big noise, not a stun
	do
		local st = ctx.Intruder._state()
		if b:GetAttribute("Hiding") then ctx.Hiding.exit(b) end
		ctx.Capture.release(b)
		st.Spared[b] = nil
		I.setMode("Hunt")
		tick(0.5)
		ctx.Inventory.give(b, "Rocket", ctx.Config.Rocket.Charges)
		local head = ctx.Intruder.getHead()
		local at = head.Position + head.CFrame.LookVector * 20 + R.Vector3.new(0, -1.5, 0)
		bRoot.CFrame = R.CFrame.new(at)
		bHead.CFrame = R.CFrame.new(at + R.Vector3.new(0, 1.5, 0))
		local chest = head.Position + R.Vector3.new(0, -1.6, 0)
		ctx.Intruder.onRocket(b, (chest - bHead.Position).Unit)
		assert(ctx.Inventory.count(b, "Rocket") == ctx.Config.Rocket.Charges - 1, "a rocket uses a charge")
		ctx.Intruder.onRocket(b, (chest - bHead.Position).Unit)
		assert(ctx.Inventory.count(b, "Rocket") == ctx.Config.Rocket.Charges - 1, "the reload: no double shot")
		-- (the harness never runs delays: the blast, as it lands next to him)
		local normalChase = ctx.Intruder._tune().ChaseSpeed
		local hit = ctx.Intruder._explode(chest + R.Vector3.new(4, 0, 0), b)
		print("15 rocket:", hit, I.getState())
		assert(hit and I.getState() == "Stunned" and st.Data.Rocket, "the blast knocks him flat")
		tick(ctx.Config.Rocket.Stun - 1)
		assert(I.getState() == "Stunned", "down for a good while (longer than a taser)")
		tick(1.5)
		assert(I.getState() ~= "Stunned", "then up (" .. I.getState() .. ")")
		assert(ctx.Intruder._tune().ChaseSpeed < normalChase * 0.7, "and slow afterwards")
		tick(ctx.Config.Rocket.Slow + 0.5)
		I.setMode("Hunt")
		tick(0.3)
		local h2 = ctx.Intruder.getHead()
		local heard = {}
		ctx.Noise.listen(function(ev) if ev.Kind == "Explosion" then table.insert(heard, ev) end end)
		local miss = ctx.Intruder._explode(h2.Position + R.Vector3.new(60, 0, 0), b)
		assert(not miss and I.getState() ~= "Stunned", "far from him: no stun")
		assert(#heard == 1 and heard[1].Radius == ctx.Config.Rocket.Noise, "but the whole house hears it")
		bRoot.CFrame = R.CFrame.new(-30, 22, 20)
		bHead.CFrame = R.CFrame.new(-30, 23.5, 20)
	end
	-- a firecracker: he goes to the bang, even from a hiding spot he's listening at
	do
		local st = ctx.Intruder._state()
		I.setMode("Hunt")
		for _ = 1, 120 do
			if I.getState() ~= "Retreat" then break end
			tick(0.5)
		end
		tick(0.3)
		local bang = ctx.Intruder.position() + R.Vector3.new(0, 0, 25)
		ctx.Noise.emit(bang, ctx.Config.Firecracker.Noise, "Firecracker", nil)
		local s1 = I.getState()
		print("16 firecracker: he", s1)
		assert(s1 == "Charge" or s1 == "Investigate", "he goes to the bang, got " .. s1)
		assert(st.Data.Pos and (st.Data.Pos - bang).Magnitude < 1, "to where it went off")
	end
	-- a quiet minute with nobody running into him: his patrols lean toward whoever's out and about
	do
		local st = ctx.Intruder._state()
		if a:GetAttribute("Hiding") then ctx.Hiding.exit(a) end
		if b:GetAttribute("Hiding") then ctx.Hiding.exit(b) end
		ctx.Capture.release(a); ctx.Capture.release(b)
		st.Spared[a] = nil
		st.Spared[b] = nil
		local spot = R.Vector3.new(-30, 4, 24) -- (downstairs, one corner)
		aRoot.CFrame = R.CFrame.new(spot)
		bRoot.CFrame = R.CFrame.new(spot + R.Vector3.new(2, 0, 0))
		table.clear(st.LastFelt)
		table.clear(st.Noises)
		local function nearShare(): number
			local hits = 0
			for _ = 1, 200 do
				for _, at in I._patrolRoute() do
					if (at - spot).Magnitude < 22 then hits += 1 break end
				end
			end
			return hits / 200
		end
		st.LastContact = T
		local fresh = nearShare()
		st.LastContact = T - 120
		local quiet = nearShare()
		print(("13 patrols passing them: just met him %.2f, a quiet two minutes %.2f"):format(fresh, quiet))
		assert(quiet > fresh + 0.15, "after a quiet while he drifts toward them")
	end
	-- someone standing right under the garage hatch: he comes in somewhere else, far off
	ctx.Capture.release(a); ctx.Capture.release(b)
	if a:GetAttribute("Hiding") then ctx.Hiding.exit(a) end
	if b:GetAttribute("Hiding") then ctx.Hiding.exit(b) end
	I.setMode("Offstage")
	local hatch = ctx.Layout.Attic.GarageHatchBelow
	aRoot.CFrame = R.CFrame.new(hatch + R.Vector3.new(4, 0, 0))
	bRoot.CFrame = R.CFrame.new(hatch + R.Vector3.new(-4, 0, 6))
	I.setMode("Hunt")
	tick(1)
	local e2 = ctx.Intruder._state().EntrySpot
	local d2 = math.min((e2 - aRoot.Position).Magnitude, (e2 - bRoot.Position).Magnitude)
	print("11 with them at the hatch he came in at", e2, ("%.0f studs away"):format(d2))
	-- v106: he talks during the hunt (a grab always), never the same line twice in a row
	local kinds = {}
	for i, v in voiced do
		kinds[v[2]] = (kinds[v[2]] or 0) + 1
		assert(type(v[1]) == "string" and v[1] ~= "", "a line")
		assert(i == 1 or voiced[i - 1][1] ~= v[1], "never the same line twice in a row: " .. v[1])
	end
	local list = {}
	for k, n in kinds do table.insert(list, k .. "=" .. n) end
	table.sort(list)
	print("12 he said", #voiced, "lines:", table.concat(list, " "))
	assert((kinds.Grab or 0) >= 1, "a grab comes with a line")
	local st = ctx.Intruder._state()
	if st.Mode == "Hunt" and st.InHouse then
		st.LastSpoke, st.SpokeAt = -1e9, {}
		assert(ctx.Intruder._speak("Murmur"), "a murmur")
		assert(not ctx.Intruder._speak("Lost"), "not right after another line (Gap)")
		assert(ctx.Intruder._speak("Behind", true), "a moment that can't wait")
		assert(not ctx.Intruder._speak("Behind", true) or ctx.Story.HisLines.Every.Behind == 0, "per kind")
		print("   speak gating ok")
	end
	assert(e2 ~= hatch and d2 >= 45, "not down the hatch on top of them")
end)
print(ok and "HUNT OK" or ("HUNT FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
