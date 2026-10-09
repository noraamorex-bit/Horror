--[[
	Navigator — walks a Humanoid to a goal.

	Inside the house the routes come from NavGrid (surveyed from the real walls and furniture,
	so a route never runs into either); outside it, or before the survey is done, from
	PathfindingService. Call update() every frame: he turns each corner the moment he reaches
	it, so he never stops between waypoints.

	• Closed doors on the way are opened (DoorService decides how long that takes).
	• A goal nobody can stand on (inside a cupboard, on a bed) ends at the nearest spot he can.
	• Wedged (no progress for a moment): re-route from where he is; still wedged, and nobody's
	  looking, he slips to the next corner. isStuck() tells the brain to give up on the goal.
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

function Navigator:_fail()
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
	if not path then
		self:_fail()
		return true
	end
	self.Waypoints = path
	self.End = path[#path]
	self.Index = math.min(2, #path)
	self.LastProgress = os.clock()
	self:_step()
	return true
end

-- PathfindingService (outside the house)
function Navigator:_compute()
	self.Version += 1
	local version = self.Version
	local from, goal = self.Root.Position, self.Goal
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
			self.Waypoints = list
			self.End = list[#list]
			self.Index = math.min(2, #list)
			self.LastProgress = os.clock()
			self:_step()
		else
			self:_fail()
		end
	end)
end

function Navigator:_plan()
	if not self:_planGrid() then
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
	self.Goal = goal
	self.Tolerance = opts.Tolerance or 3
	self.Hurry = opts.Hurry == true
	self.Reach = opts.Reach
	if opts.Speed then
		self:_setSpeed(opts.Speed)
	end
	self.Arrived = false
	self.Failed = false
	self.Stuck = 0
	self.WaitUntil = 0
	self.Resume = false
	self.LastPos = self.Root.Position
	self.LastProgress = os.clock()
	self:_plan()
end

-- straight there (the caller has checked he can walk it: NavGrid.straight)
function Navigator:moveDirect(goal: Vector3, speed: number?)
	self.Version += 1
	self.Computing = false
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
		while self.Index < #wps and NavGrid.straight(pos, wps[self.Index + 1]) do
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
		local nextWp = wps[math.min(self.Index, #wps)]
		if self.Stuck >= 3 and nextWp and unseen(self.ctx, pos) and unseen(self.ctx, nextWp + Vector3.new(0, ROOT, 0)) then
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
		elseif self.Goal then
			self:_plan()
		end
	end
end

function Navigator:isStuck(): boolean
	return self.Failed or self.Stuck >= 5
end

return Navigator
