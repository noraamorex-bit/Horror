-- "Become him" (MonsterService): a player drives Curtis for the rest of the night
local H = require("./env")
local ok, err = pcall(function()
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Config.Intruder.Brain = "Classic"
	ctx.Rooms = H.load("RS/Shared/Rooms")
	ctx.Sounds = H.load("RS/Shared/Sounds")
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Util = H.load("RS/Shared/Util")
	ctx.Builder = H.load("Server/World/Builder")
	ctx.Layout = H.load("Server/World/Layout")
	local sent = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = {
			FireClient = function(_, p, ...) table.insert(sent, { k, p, ... }) end,
			FireAllClients = function(_, ...) table.insert(sent, { k, "all", ... }) end,
			OnServerEvent = H.signal(),
		}
		rawset(t, k, r)
		return r
	end })
	local credits = {}
	ctx.Stats = {
		addMonsterCredit = function(p) credits[p] = (credits[p] or 0) + 1; p:SetAttribute("MonsterCredits", credits[p]); return true end,
		spendMonsterCredit = function(p) if (credits[p] or 0) > 0 then credits[p] -= 1; p:SetAttribute("MonsterCredits", credits[p] > 0 and credits[p] or nil); return true end return false end,
	}
	local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService", "Heartbeat=HeartbeatService", "Monster=MonsterService" }
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
	local R = H.roblox
	local T = 5000
	H.clock = function() return T end
	H.task.wait = function(s) T += (s or 0.03); return s or 0.03 end
	local hb = H.services.RunService.Heartbeat
	rawset(H.services.PathfindingService, "CreatePath", function()
		local path = { Status = H.roblox.Enum.PathStatus.Success }
		function path:ComputeAsync(a, b) self.A, self.B = a, b end
		function path:GetWaypoints() return { { Position = self.A }, { Position = self.B } } end
		return path
	end)
	local function tick(seconds)
		for _ = 1, math.floor(seconds / 0.1) do
			T += 0.1
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
		rawset(p, "DisplayName", name)
		rawset(p, "UserId", #name * 1000 + string.byte(name))
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
	local a = mkPlayer("Ash", R.Vector3.new(-22, 4, -18))
	local b, bRoot, bHead = mkPlayer("Bea", R.Vector3.new(-30, 22, 20))
	local all = { a, b }
	H.services.Players.GetPlayers = function() return all end
	H.services.Players.GetPlayerByUserId = function(_, id) for _, p in all do if p.UserId == id then return p end end return nil end
	local M = ctx.Monster
	local W = H.unwrap(H.workspaceRoot)

	-- alone it's not for sale; with a friend, during a night, it is
	ctx.Director.startAct("SmallThings")
	H.services.Players.GetPlayers = function() return { a } end
	assert(not M.canBuy(a), "solo: no")
	H.services.Players.GetPlayers = function() return all end
	assert(M.canBuy(a), "co-op, act II: yes")
	tick(2.5)
	assert(W:GetAttribute("BecomeHimOpen") == true, "the buy button is on")

	-- bought before the blackout: it waits for the hunt
	local okGrant = M.grant(a)
	assert(okGrant and M.pending() and not M.active(), "waiting for the hunt")
	assert(not M.canBuy(b), "only one of them a night")
	-- a second purchase meanwhile (Bea's receipt): saved for another night, never lost
	local decision = M.onReceipt({ PlayerId = b.UserId })
	assert(decision == R.Enum.ProductPurchaseDecision.PurchaseGranted and credits[b] == 1, "the second buyer's is saved")
	assert(not b:GetAttribute("Monster"), "and Bea stays a survivor")

	-- the hunt starts: Ash is him
	ctx.Intruder.setMode("Hunt")
	tick(0.5)
	assert(M.active() and a:GetAttribute("Monster") == true, "Ash became him")
	assert(ctx.Intruder.getState() == "Puppet", "the AI is off, got " .. ctx.Intruder.getState())
	local survivors = ctx.Util.activePlayers()
	assert(#survivors == 1 and survivors[1] == b, "the monster isn't a survivor")
	assert(#ctx.Util.sessionPlayers() == 1, "nor in the night's survivor list")
	local told = false
	for _, s in sent do if s[1] == "Notify" and s[2] == b and string.find(tostring(s[3]), "has become HIM") then told = true end end
	assert(told, "Bea is told")
	-- the AI asking to hunt again doesn't take him back
	ctx.Intruder.setMode("Hunt")
	assert(ctx.Intruder.getState() == "Puppet", "still theirs")

	-- steering: the move direction walks him
	local start = ctx.Intruder.position()
	ctx.Remotes.MonsterAction.OnServerEvent:Fire(a, "Move", R.Vector3.new(1, 0, 0))
	tick(1)
	local moved = ctx.Intruder.position() - start
	print("moved", moved)
	assert(moved.X > 3, "he walks where they steer")
	-- (Bea can't send moves for him)
	ctx.Remotes.MonsterAction.OnServerEvent:Fire(b, "Move", R.Vector3.new(-1, 0, 0))
	assert(M._state().Dir.X > 0, "only the buyer steers")
	ctx.Remotes.MonsterAction.OnServerEvent:Fire(a, "Move", R.Vector3.zero)
	tick(0.3)

	-- a survivor's noise shows up for them as a ping
	local pings = 0
	for _, s in sent do if s[1] == "Monster" and s[2] == a and type(s[3]) == "table" and s[3].Ping then pings += 1 end end
	ctx.Noise.emit(bRoot.Position, 20, "Footstep", b)
	tick(0.1)
	local pings2 = 0
	for _, s in sent do if s[1] == "Monster" and s[2] == a and type(s[3]) == "table" and s[3].Ping then pings2 += 1 end end
	assert(pings2 == pings + 1, "survivor noise pinged")

	-- SEARCH: Bea hides right in front of him; she gets the heartbeat minigame
	local pos = ctx.Intruder.position()
	local spot = ctx.Hiding.spotsNear(pos, 400)[1]
	local hrp = H.unwrap(ctx.World.folder()):FindFirstChild("Curtis", true):FindFirstChild("HumanoidRootPart")
	hrp.CFrame = R.CFrame.new(spot.Exit.Position + R.Vector3.new(0, 2, 0))
	bRoot.CFrame = R.CFrame.new(spot.Exit.Position)
	ctx.Hiding.enter(b, spot)
	T += 3
	local before = 0
	for _, x in sent do if x[1] == "Heartbeat" and x[2] == b and type(x[3]) == "table" and x[3].Beats then before += 1 end end
	M._search()
	local after = 0
	for _, x in sent do if x[1] == "Heartbeat" and x[2] == b and type(x[3]) == "table" and x[3].Beats then after += 1 end end
	assert(after == before + 1, "whoever's inside gets the heartbeat minigame")
	-- (the harness's clock runs the minigame straight through: nobody pressed anything, so he heard her)
	print("   after the minigame: Bea captured", b:GetAttribute("Captured"), "catches", M._state().Captures)
	assert(b:GetAttribute("Captured") == true and M._state().Captures == 1, "a failed heartbeat: pulled out and caught")
	ctx.Capture.release(b)
	if b:GetAttribute("Hiding") then ctx.Hiding.exit(b) end

	-- a grab: Bea out in the open, right next to him
	T += ctx.Config.Monster.GrabCooldown + 1
	hrp.CFrame = R.CFrame.new(bRoot.Position + R.Vector3.new(2, 2, 0))
	tick(0.3)
	assert(b:GetAttribute("Captured") == true, "touched in the open: caught")
	assert(M._state().Captures == 2, "counted")

	-- tasered: he can't move for a while
	ctx.Capture.release(b)
	ctx.Monster.stun(ctx.Config.Monster.TaserStun)
	ctx.Remotes.MonsterAction.OnServerEvent:Fire(a, "Move", R.Vector3.new(0, 0, 1))
	local p0 = ctx.Intruder.position()
	tick(1)
	assert((ctx.Intruder.position() - p0).Magnitude < 0.5, "stunned: he doesn't move")

	-- the buyer leaves: the AI takes over again
	all = { b }
	H.services.Players.GetPlayers = function() return all end
	rawset(a, "Parent", nil)
	tick(0.3)
	assert(not M.active(), "released")
	assert(ctx.Intruder.getState() ~= "Puppet", "the AI hunts again, got " .. ctx.Intruder.getState())

	-- (v137) dead, with a friend still in the hunt: become him and hunt them
	do
		local d = mkPlayer("Dee", R.Vector3.new(-24, 4, 6))
		b:SetAttribute("Dead", nil)
		b:SetAttribute("Captured", nil)
		all = { b, d }
		d:SetAttribute("Dead", true)
		assert(M.canBuy(d), "dead, Bea still in there: yes")
		b:SetAttribute("Dead", true)
		assert(not M.canBuy(d), "nobody left alive: no")
		b:SetAttribute("Dead", nil)
		assert(M.grant(d) and M.active() and d:GetAttribute("Monster") == true, "Dee hunts Bea")
		if ctx.Revive and ctx.Revive.canRevive then
			assert(not ctx.Revive.canRevive(d), "no revive out of him")
		end
		all = { b }
		rawset(d, "Parent", nil)
		tick(0.3)
		assert(not M.active(), "Dee leaves: the AI again")
		print("revenge ok")
	end

	-- a saved one: Bea can use it on another night with friends, for free
	local c = mkPlayer("Cy", R.Vector3.new(-20, 4, 10))
	all = { b, c }
	b:SetAttribute("Dead", nil) -- (caught twice above: a fresh night for her)
	b:SetAttribute("Captured", nil)
	ctx.Remotes.MonsterAction.OnServerEvent:Fire(b, "UseCredit")
	assert(credits[b] == 0 and (b:GetAttribute("MonsterPending") or b:GetAttribute("Monster")), "the saved one is used")
	print("become him ok")
end)
print(ok and "MONSTER OK" or ("MONSTER FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
