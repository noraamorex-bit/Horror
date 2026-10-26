--[[
	Navigator — walks a Humanoid to a goal.

	Inside the house the routes come from NavGrid (surveyed from the real walls and furniture,
	so a route never runs into either); outside it, or before the survey is done, from
	PathfindingService. Call update() every frame: he turns each corner the moment he reaches
	it, so he never stops between waypoints.

	• Closed doors on the way are opened (DoorService decides how long that takes).
	• A goal nobody can stand on (inside a cupboard, on a bed) ends at the nearest spot he can.
	• Wedged (no progress for a moment): re-route from where he is; still wedged, he steps back
	  off whatever caught him and goes round again; still wedged, and nobody's looking, he slips
	  to the next corner. isStuck() tells the brain to give up on the goal.
	• In and out of the house (v118): PathfindingService can't get through the house's closed doors, so
	  once he'd gone outside (to a knock at Mrs. Okafor's, the car, the junction box) he could never get
	  back in, and nobody outside could be followed: 31 of 205 nights logged hundreds of failed routes
	  each, him stuck retrying one impossible route. A route from inside to outside (or back) now goes
	  through the best exterior door: the survey to the door, PathfindingService beyond it.
	• A route that has just failed isn't worked out again for the same errand a moment later.
	• Stats (wedges, step-backs, slips, failed routes, routes planned and the time spent on
	  them) go into the night log (JourneyService), so we can see how he gets about in real games.
]]

local PathfindingService = game:GetService("PathfindingService")
local NavGrid = require(script.Parent.NavGrid)

local Navigator = {}
Navigator.__index = Navigator

local AGENT = {
	AgentRadius = 1.8,
	AgentHeight = 7.5,
	AgentCanJump = false,
	AgentCanClimb = false,
	WaypointSpacing = 4,
	Costs = { Door = 2 },
}
local ROOT = 4.9 -- (his root above his feet: Rig.RootY)
-- the ways in and out of the house: the exterior doors, and which way is outside
local EXITS = {
	{ Id = "FrontDoor", Out = Vector3.new(0, 0, -1) },
	{ Id = "BackDoor", Out = Vector3.new(0, 0, 1) },
	{ Id = "GarageSide", Out = Vector3.new(1, 0, 0) },
}
local GARAGE_DOOR = Vector3.new(53, 1, -30) -- (the big door, when it's up)

local function flat(v: Vector3): number
	return Vector3.new(v.X, 0, v.Z).Magnitude
end

local function inGrid(p: Vector3): boolean
	local B = NavGrid.Bounds
	return p.X >= B.X0 and p.X <= B.X1 and p.Z >= B.Z0 and p.Z <= B.Z1 and p.Y > B.Bottom and p.Y < B.Top + 6
end

function Navigator.new(ctx, humanoid: Humanoid, root: BasePart)
	local self = setmetatable({}, Navigator)
	self.ctx = ctx
	self.Humanoid = humanoid
	self.Root = root
	self.Goal = nil :: Vector3?
	self.End = nil :: Vector3? -- where the route actually ends (floor level)
	self.Waypoints = nil :: { Vector3 }?
	self.Index = 1
	self.Version = 0
	self.Computing = false
	self.Arrived = true
	self.Failed = false
	self.Tolerance = 3
	self.WaitUntil = 0
	self.Resume = false
	self.LastPos = root.Position
	self.LastProgress = os.clock()
	self.LastMoveTo = 0
	self.Stuck = 0
	self.Hurry = false
	self.DoorFilter = nil :: ((any) -> boolean)?
	self.Stats = { Wedged = 0, StepBack = 0, Slip = 0, Fail = 0, Plans = 0, PlanMs = 0 }
	return self
end

function Navigator:_moveTo(p: Vector3)
	self.LastMoveTo = os.clock()
	self.Humanoid:MoveTo(p)
end

function Navigator:_step()
	local wps = self.Waypoints
	if wps and wps[self.Index] then
		self:_moveTo(wps[self.Index])
	elseif self.End then
		self:_moveTo(self.End)
	end
end

function Navigator:_fail(kind: string?)
	-- (the same errand failing again from the same spot: no new route, no new count)
	local goal0, pos0 = self.Goal, self.Root.Position
	local last = self.LastFail
	if last and goal0 and os.clock() - last.At < 2.5 and (last.Goal - goal0).Magnitude < 4 and (last.From - pos0).Magnitude < 3 then
		self.Stats.Repeat = (self.Stats.Repeat or 0) + 1
		self.Waypoints = nil
		self.Failed = true
		self.Arrived = true
		self.Humanoid:MoveTo(pos0)
		return
	end
	if goal0 then
		self.LastFail = { At = os.clock(), Goal = goal0, From = pos0 }
	end
	self.Stats.Fail += 1
	-- (where: the night log sums these, so the next stats pass can see which goals can't be reached)
	local goal = self.Goal
	local where = "?"
	if goal then
		local room = self.ctx and self.ctx.Rooms and self.ctx.Rooms.find(goal)
		where = room and room.Name or (inGrid(goal) and "House" or "Outside")
	end
	-- (and from where: v118, to see what's left)
	local from = self.Root.Position
	local fromRoom = self.ctx and self.ctx.Rooms and self.ctx.Rooms.find(from)
	local key = "Fail" .. (kind or "") .. "_" .. where .. "_" .. (fromRoom and fromRoom.Name or (inGrid(from) and "House" or (from.Y > NavGrid.Bounds.Top + 2 and "High" or "Out")))
	self.Stats[key] = (self.Stats[key] or 0) + 1
	self.Waypoints = nil
	self.Failed = true
	self.Arrived = true
	self.Humanoid:MoveTo(self.Root.Position)
end

-- a route on the survey; false when the survey can't answer (not built yet, or outside it)
function Navigator:_planGrid(): boolean
	local goal = self.Goal :: Vector3
	local from = self.Root.Position
	if not NavGrid.ready() or not inGrid(from) or not inGrid(goal) then
		return false
	end
	self.Version += 1
	self.Computing = false
	self.SideUntil = nil
	local t0 = os.clock()
	local path = NavGrid.findPath(from, goal, self.Reach)
		or NavGrid.findPath(from - Vector3.new(0, 1, 0), goal, self.Reach)
	if not path then
		-- (standing somewhere odd: route from the nearest spot he can stand)
		local near = NavGrid.nearest(from, 6)
		path = near and NavGrid.findPath(near + Vector3.new(0, ROOT, 0), goal, self.Reach) or nil
		if path then
			table.insert(path, 1, near)
		end
	end
	if not path and (self.Reach or 0) < 6 then
		-- (v105: the goal itself is somewhere he can't stand: on a bed, in a gap between furniture,
		-- up the attic ladder. Go as near as he can get instead of failing: live nights logged ~32
		-- failed routes each, a chase re-planning the same impossible route every second)
		path = NavGrid.findPath(from, goal, 6)
	end
	self.Stats.Plans += 1
	self.Stats.PlanMs += (os.clock() - t0) * 1000
	if not path then
		self:_fail("Grid")
		return true
	end
	self.Waypoints = path
	self.End = path[#path]
	self.Index = math.min(2, #path)
	-- (no fresh start for the wedge check here: a re-route doesn't move him; goTo sets it for a
	-- new errand)
	self:_step()
	return true
end

-- PathfindingService (outside the house)
function Navigator:_compute(subGoal: Vector3?, tail: { Vector3 }?)
	self.Version += 1
	local version = self.Version
	local from, goal = self.Root.Position, subGoal or self.Goal
	if not goal then
		return
	end
	self.Computing = true
	task.spawn(function()
		local path = PathfindingService:CreatePath(AGENT)
		local ok = pcall(function()
			path:ComputeAsync(from, goal)
		end)
		if version ~= self.Version then
			return
		end
		self.Computing = false
		if ok and path.Status == Enum.PathStatus.Success then
			local list = {}
			for _, wp in path:GetWaypoints() do
				table.insert(list, wp.Position)
			end
			-- (then on through the door and the house: _planCross)
			for _, p in tail or {} do
				table.insert(list, p)
			end
			self.Waypoints = list
			self.End = list[#list]
			self.Index = math.min(2, #list)
			self.LastProgress = os.clock()
			self:_step()
		else
			self:_fail("PF")
		end
	end)
end

-- the doors he can go in and out by right now: { Inside, Outside } floor points
function Navigator:_exits(): { { Inside: Vector3, Outside: Vector3 } }
	local list = {}
	local Doors = self.ctx and self.ctx.Doors
	local function add(at: Vector3, out: Vector3)
		local inside = NavGrid.nearest(at - out * 2.2, 2.5)
		if inside then
			table.insert(list, { Inside = inside, Outside = Vector3.new(at.X, inside.Y, at.Z) + out * 3.5 })
		end
	end
	for _, e in EXITS do
		local d = Doors and Doors.get(e.Id)
		if d and d.Position then
			add(Vector3.new(d.Position.X, 1, d.Position.Z), e.Out)
		end
	end
	local Escape = self.ctx and self.ctx.Escape
	if Escape and Escape.isGarageOpen and Escape.isGarageOpen() then
		add(GARAGE_DOOR, Vector3.new(0, 0, -1))
	end
	return list
end
Navigator._EXITS = EXITS -- (tests)

local function pathLength(from: Vector3, path: { Vector3 }): number
	local len, last = 0, from
	for _, p in path do
		len += flat(p - last)
		last = p
	end
	return len
end

-- in to out, or out to in: through the best exterior door. Returns false if it can't help.
function Navigator:_planCross(): boolean
	local goal = self.Goal :: Vector3
	local from = self.Root.Position
	if not NavGrid.ready() then
		return false
	end
	local fromIn, goalIn = inGrid(from), inGrid(goal)
	if fromIn == goalIn then
		return false
	end
	-- (somewhere neither leg can start from: up in the attic, on a roof)
	if not fromIn and from.Y > NavGrid.Bounds.Top + 2 then
		return false
	end
	local t0 = os.clock()
	local best, bestCost, bestPath = nil, math.huge, nil
	for _, exit in self:_exits() do
		if fromIn then
			local path = NavGrid.findPath(from, exit.Inside + Vector3.new(0, ROOT, 0), 2)
			if path then
				local cost = pathLength(from, path) + flat(exit.Outside - goal)
				if cost < bestCost then
					best, bestCost, bestPath = exit, cost, path
				end
			end
		else
			local path = NavGrid.findPath(exit.Inside + Vector3.new(0, ROOT, 0), goal, self.Reach or 6)
			if path then
				local cost = flat(from - exit.Outside) + pathLength(exit.Inside, path)
				if cost < bestCost then
					best, bestCost, bestPath = exit, cost, path
				end
			end
		end
	end
	self.Stats.Plans += 1
	self.Stats.PlanMs += (os.clock() - t0) * 1000
	if not best then
		return false
	end
	self.Stats.Cross = (self.Stats.Cross or 0) + 1
	self.Version += 1
	self.Computing = false
	self.SideUntil = nil
	if fromIn then
		-- the survey to the door, out, then (out in the open) straight on; a fence on the way and he
		-- re-routes from out there with PathfindingService
		local list = table.clone(bestPath :: { Vector3 })
		table.insert(list, best.Outside)
		table.insert(list, goal)
		self.Waypoints = list
		self.End = goal
		self.Index = math.min(2, #list)
		self:_step()
	else
		-- PathfindingService to the door from outside, then in, then the survey
		local tail = { best.Inside }
		for _, p in bestPath :: { Vector3 } do
			table.insert(tail, p)
		end
		self:_compute(best.Outside, tail)
	end
	return true
end

function Navigator:_plan()
	if not self:_planGrid() and not self:_planCross() then
		self:_compute()
	end
end

-- (never as fast as your walk, whatever asked: Config.Intruder.MaxSpeed)
function Navigator:_setSpeed(speed: number)
	local cfg = self.ctx and self.ctx.Config
	local cap = cfg and cfg.Intruder and cfg.Intruder.MaxSpeed
	self.Humanoid.WalkSpeed = cap and math.min(speed, cap) or speed
end

-- opts: Speed, Tolerance, Hurry, Reach (how far from the goal the route may end)
function Navigator:goTo(goal: Vector3, opts)
	opts = opts or {}
	-- (the same errand again, as a chase re-routes every second: keep counting how long he's been
	-- wedged, and let a door he's waiting on or a step back finish; otherwise a wedge never
	-- added up to a step back or a slip, and he stood there re-routing until the chase ended)
	local same = self.Goal ~= nil and not self.Arrived and not self.Failed and (goal - self.Goal).Magnitude < 8
	self.Goal = goal
	self.Tolerance = opts.Tolerance or 3
	self.Hurry = opts.Hurry == true
	self.Reach = opts.Reach
	if opts.Speed then
		self:_setSpeed(opts.Speed)
	end
	self.Arrived = false
	self.Failed = false
	if not same then
		self.Stuck = 0
		self.WaitUntil = 0
		self.Resume = false
		self.LastPos = self.Root.Position
		self.LastProgress = os.clock()
	elseif os.clock() < self.WaitUntil or (self.SideUntil and os.clock() < self.SideUntil) then
		return -- (re-routes from there when it's done)
	end
	self:_plan()
end

-- straight there (the caller has checked he can walk it: NavGrid.straight)
function Navigator:moveDirect(goal: Vector3, speed: number?)
	self.Version += 1
	self.Computing = false
	self.SideUntil = nil
	self.Goal = goal
	self.End = goal
	self.Waypoints = { goal }
	self.Index = 1
	if self.Arrived or self.Failed then
		self.Stuck = 0
		self.LastPos = self.Root.Position
		self.LastProgress = os.clock()
	end
	self.Arrived = false
	self.Failed = false
	if speed then
		self:_setSpeed(speed)
	end
	self:_step()
end

function Navigator:stop()
	self.Version += 1
	self.Computing = false
	self.SideUntil = nil
	self.Goal = nil
	self.End = nil
	self.Waypoints = nil
	self.Arrived = true
	self.Humanoid:MoveTo(self.Root.Position)
end

-- a closed (or barely open) door on the next stretch of the route
function Navigator:_doorAhead()
	local wps = self.Waypoints
	if not wps then
		return nil
	end
	local pos = self.Root.Position
	for _, door in self.ctx.Doors.all() do
		local dp = door.Position
		if (not door.IsOpen or (door.Target or door.Angle) < door.OpenAngle * 0.75)
			and math.abs(dp.Y - pos.Y) < 6 and flat(dp - pos) < 8 then
			for i = self.Index, math.min(self.Index + 1, #wps) do
				local a = i == self.Index and pos or wps[i - 1]
				local b = wps[i]
				local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
				local ap = Vector3.new(dp.X - a.X, 0, dp.Z - a.Z)
				local len = ab.Magnitude
				local t = len > 0.01 and math.clamp(ap:Dot(ab) / (len * len), 0, 1) or 0
				local closest = Vector3.new(a.X, 0, a.Z) + ab * t
				-- (only ahead of him, and within reach along the route)
				if (Vector3.new(dp.X, 0, dp.Z) - closest).Magnitude < 2.6 and (i > self.Index or t * len < 6) then
					return door
				end
			end
		end
	end
	return nil
end

-- wedged on a corner or a table leg: a spot a couple of studs off, that he can walk straight to,
-- away from where he was trying to go (or to the side of it). Steps there, then goes round again.
function Navigator:_stepBack(pos: Vector3, toward: Vector3?): boolean
	if not NavGrid.ready() or not inGrid(pos) then
		return false
	end
	local dir = toward and Vector3.new(toward.X - pos.X, 0, toward.Z - pos.Z) or Vector3.zero
	local base = dir.Magnitude > 0.1 and math.atan2(-dir.Z, -dir.X) or math.random() * math.pi * 2
	-- (straight back first, then fanning out to the sides)
	for _, da in { 0, 0.6, -0.6, 1.2, -1.2, 1.7, -1.7 } do
		for _, r in { 3, 2 } do
			local a = base + da
			local probe = pos + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			local floor = NavGrid.nearest(probe, 0.9)
			if floor and NavGrid.straight(pos, floor + Vector3.new(0, ROOT, 0)) and (NavGrid.clearance(floor) or 0) >= 1 then
				self.SideTo = floor
				self.SideUntil = os.clock() + 0.8
				self.Stats.StepBack += 1
				self:_moveTo(floor)
				return true
			end
		end
	end
	return false
end

local function unseen(ctx, p: Vector3): boolean
	local perception = ctx.Director and ctx.Director.Perception
	return perception == nil or not perception.anyoneSees(p + Vector3.new(0, 2, 0))
end

-- call every frame
function Navigator:update()
	local goal = self.Goal
	if not goal or self.Arrived then
		return
	end
	local now = os.clock()
	local pos = self.Root.Position
	local target = self.End or goal
	if flat(pos - target) <= self.Tolerance and math.abs(pos.Y - target.Y) < 7 then
		self.Arrived = true
		self.Humanoid:MoveTo(pos)
		return
	end
	if now < self.WaitUntil or self.Computing or not self.Waypoints then
		self.LastProgress = now
		return
	end
	-- (stepping back off a corner he caught: then a fresh route from there)
	if self.SideUntil then
		if now < self.SideUntil and flat(pos - (self.SideTo :: Vector3)) > 0.5 then
			self.LastProgress = now
			return
		end
		self.SideUntil = nil
		self.LastPos = pos
		self.LastProgress = now
		self:_plan()
		return
	end

	local door = self:_doorAhead()
	if door then
		if self.DoorFilter and not self.DoorFilter(door) then
			-- not allowed through: give up on this goal
			self:stop()
			self.Failed = true
			return
		end
		local wait = self.ctx.Doors.intruderOpen(door, self.Hurry)
		if wait > 0 then
			self.WaitUntil = now + wait
			self.Humanoid:MoveTo(pos)
			self.Resume = true
			return
		end
	end
	if self.Resume then
		self.Resume = false
		self.LastProgress = now
		self.LastPos = pos
		self:_step()
	end

	-- corners: the moment the one after next is in a clear straight line from where he is, he
	-- heads for it (so he rounds corners smoothly, and never clips one)
	local wps = self.Waypoints :: { Vector3 }
	if now - (self.LookAhead or 0) > 0.1 and NavGrid.ready() and inGrid(pos) then
		self.LookAhead = now
		local changed = false
		while self.Index < #wps and NavGrid.straight(pos, wps[self.Index + 1], true) do
			self.Index += 1
			changed = true
		end
		if changed then
			self:_step()
		end
	end
	local wp = wps[self.Index]
	while wp and flat(pos - wp) < 0.4 and math.abs(pos.Y - ROOT - wp.Y) < 4 do
		self.Index += 1
		wp = wps[self.Index]
		self:_step()
	end
	-- (Roblox gives up on a MoveTo after 8 s)
	if now - self.LastMoveTo > 2.5 then
		self:_step()
	end

	-- stuck?
	if (pos - self.LastPos).Magnitude > 0.6 then
		self.LastPos = pos
		self.LastProgress = now
		if self.Stuck > 0 and now - (self.StuckAt or 0) > 3 then
			self.Stuck = 0
		end
	elseif now - self.LastProgress > 0.9 then
		self.LastProgress = now
		self.Stuck += 1
		self.StuckAt = now
		self.Stats.Wedged += 1
		-- (where: v118, to find the corners that catch him in real games)
		local room = self.ctx and self.ctx.Rooms and self.ctx.Rooms.find(pos)
		local wkey = "Wedge_" .. (room and room.Name or (inGrid(pos) and "House" or "Out"))
		self.Stats[wkey] = (self.Stats[wkey] or 0) + 1
		local nextWp = wps[math.min(self.Index, #wps)]
		if self.Stuck >= 3 and nextWp and unseen(self.ctx, pos) and unseen(self.ctx, nextWp + Vector3.new(0, ROOT, 0)) then
			self.Stats.Slip += 1
			-- properly wedged and nobody's looking: slip along to the next corner
			local model = self.Root:FindFirstAncestorWhichIsA("Model")
			local at = nextWp + Vector3.new(0, ROOT + 0.1, 0)
			if model and flat(nextWp - pos) < 12 then
				local look = Vector3.new(nextWp.X - pos.X, 0, nextWp.Z - pos.Z)
				if look.Magnitude < 0.1 then
					look = Vector3.new(0, 0, -1)
				end
				model:PivotTo(CFrame.lookAt(at, at + look.Unit))
			end
			self:_plan()
		elseif self.Stuck >= 2 and self:_stepBack(pos, nextWp) then
			return
		elseif self.Goal then
			self:_plan()
		end
	end
end

function Navigator:isStuck(): boolean
	return self.Failed or self.Stuck >= 5
end

return Navigator
