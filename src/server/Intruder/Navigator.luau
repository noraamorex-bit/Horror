--[[
	Navigator — walks a Humanoid to a goal with PathfindingService.

	• Paths are recomputed only on goal change, when stuck, or when the caller asks.
	• Closed doors along the way are opened (DoorService decides how long that takes).
	• Falls back to a straight MoveTo when no path exists.
]]

local PathfindingService = game:GetService("PathfindingService")

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

local function flat(v: Vector3): number
	return Vector3.new(v.X, 0, v.Z).Magnitude
end

function Navigator.new(ctx, humanoid: Humanoid, root: BasePart)
	local self = setmetatable({}, Navigator)
	self.ctx = ctx
	self.Humanoid = humanoid
	self.Root = root
	self.Goal = nil :: Vector3?
	self.Waypoints = nil :: { Vector3 }?
	self.Index = 1
	self.Version = 0
	self.Computing = false
	self.Arrived = true
	self.Tolerance = 3
	self.WaitUntil = 0
	self.Resume = false
	self.LastPos = root.Position
	self.LastProgress = os.clock()
	self.Fails = 0
	self.Hurry = false
	self.DoorFilter = nil :: ((any) -> boolean)?
	return self
end

function Navigator:_step()
	local wps = self.Waypoints
	if wps and wps[self.Index] then
		self.Humanoid:MoveTo(wps[self.Index])
	end
end

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
			self.Index = math.min(2, #list)
		else
			-- no path (goal inside furniture, off the navmesh): head for the closest known
			-- walkable spot instead of walking face-first into a wall; twice in a row and the
			-- goal is given up so the brain picks something else
			self.PathFails = (self.PathFails or 0) + 1
			local alt = self.PathFails <= 2 and self:_nearestNode(goal) or nil
			if alt and (alt - goal).Magnitude > 0.5 then
				self.Goal = alt
				self:_compute()
				return
			end
			self.Waypoints = nil
			self.Fails = 99
			self.Arrived = true
			self.Humanoid:MoveTo(self.Root.Position)
			return
		end
		self.PathFails = 0
		self.LastProgress = os.clock()
		self:_step()
	end)
end

function Navigator:_nearestNode(p: Vector3): Vector3?
	local best, bd = nil, 18
	for _, n in self.ctx.Layout and self.ctx.Layout.Nodes or {} do
		local d = (n.Pos - p).Magnitude
		if d < bd and math.abs(n.Pos.Y - p.Y) < 8 then
			best, bd = n.Pos, d
		end
	end
	return best
end

-- opts: Speed, Tolerance, Hurry
function Navigator:goTo(goal: Vector3, opts)
	opts = opts or {}
	self.Goal = goal
	self.Tolerance = opts.Tolerance or 3
	self.Hurry = opts.Hurry == true
	if opts.Speed then
		self.Humanoid.WalkSpeed = opts.Speed
	end
	self.Arrived = false
	self.Fails = 0
	self.PathFails = 0
	self.LastProgress = os.clock()
	self:_compute()
end

-- straight line, no pathfinding (clear line of sight, same floor)
function Navigator:moveDirect(goal: Vector3, speed: number?)
	self.Version += 1
	self.Computing = false
	self.Goal = goal
	self.Waypoints = { goal }
	self.Index = 1
	self.Arrived = false
	if speed then
		self.Humanoid.WalkSpeed = speed
	end
	self:_step()
end

function Navigator:stop()
	self.Version += 1
	self.Computing = false
	self.Goal = nil
	self.Waypoints = nil
	self.Arrived = true
	self.Humanoid:MoveTo(self.Root.Position)
end

function Navigator:_doorAhead(door): boolean
	local pos = self.Root.Position
	local wps = self.Waypoints
	if not wps then
		return false
	end
	local dp = door.Position
	for i = self.Index, math.min(self.Index + 2, #wps) do
		local a = i == self.Index and pos or wps[i - 1]
		local b = wps[i]
		local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local ap = Vector3.new(dp.X - a.X, 0, dp.Z - a.Z)
		local len = ab.Magnitude
		local t = len > 0.01 and math.clamp(ap:Dot(ab) / (len * len), 0, 1) or 0
		local closest = Vector3.new(a.X, 0, a.Z) + ab * t
		if (Vector3.new(dp.X, 0, dp.Z) - closest).Magnitude < 3 and math.abs(dp.Y - b.Y) < 8 then
			return true
		end
	end
	return false
end

-- call every think tick
function Navigator:update()
	local goal = self.Goal
	if not goal or self.Arrived then
		return
	end
	local now = os.clock()
	local pos = self.Root.Position
	if flat(pos - goal) <= self.Tolerance and math.abs(pos.Y - goal.Y) < 7 then
		self.Arrived = true
		self.Humanoid:MoveTo(pos)
		return
	end
	if now < self.WaitUntil or self.Computing or not self.Waypoints then
		return
	end

	local door = self.ctx.Doors.nearestClosed(pos, 7)
	if door and self:_doorAhead(door) then
		if self.DoorFilter and not self.DoorFilter(door) then
			-- not allowed through: give up on this goal
			self:stop()
			return
		end
		self.WaitUntil = now + self.ctx.Doors.intruderOpen(door, self.Hurry)
		self.Humanoid:MoveTo(pos)
		self.Resume = true
		return
	end
	if self.Resume then
		self.Resume = false
		self.LastProgress = now
		self:_step()
	end

	local wps = self.Waypoints :: { Vector3 }
	local wp = wps[self.Index]
	if wp and flat(pos - wp) < 2.4 and math.abs(pos.Y - wp.Y) < 6 then
		self.Index += 1
		if self.Index > #wps then
			self.Humanoid:MoveTo(goal)
		else
			self:_step()
		end
	end

	-- stuck?
	if (pos - self.LastPos).Magnitude > 0.8 then
		self.LastPos = pos
		self.LastProgress = now
	elseif now - self.LastProgress > 1.6 then
		self.LastProgress = now
		self.Fails += 1
		-- properly wedged (a chair leg, a bed corner) and nobody's looking: slip him along to the
		-- next waypoint rather than let him grind against the furniture
		local next = wps[math.min(self.Index, #wps)]
		local perception = self.ctx.Director and self.ctx.Director.Perception
		if self.Fails >= 4 and next and perception and not perception.anyoneSees(pos + Vector3.new(0, 2, 0))
			and not perception.anyoneSees(next + Vector3.new(0, 2, 0)) and math.abs(next.Y - pos.Y) < 4 then
			local model = self.Root:FindFirstAncestorWhichIsA("Model")
			if model then
				model:PivotTo(CFrame.lookAt(next + Vector3.new(0, pos.Y - next.Y + 0.2, 0), next + (next - pos) * Vector3.new(1, 0, 1) + Vector3.new(0, pos.Y - next.Y + 0.2, 0.001)))
			end
			self.Fails = 0
			self:_compute()
		elseif self.Fails > 4 then
			self.Humanoid:MoveTo(goal)
		else
			self:_compute()
		end
	end
end

function Navigator:isStuck(): boolean
	return self.Fails > 6
end

return Navigator
