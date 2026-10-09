--[[
	Anim — small server-side animations for the house: drawers sliding out, wardrobe doors
	swinging, things lifting away when picked up. Everything tweens a NumberValue and applies
	CFrames to anchored parts (the same way doors swing), and never yields the caller.
]]

local TweenService = game:GetService("TweenService")

local Anim = {}

-- tween 0 -> 1 and call apply(k) on every step; done() at the end
local function drive(time: number, style: Enum.EasingStyle, dir: Enum.EasingDirection, apply: (number) -> (), done: (() -> ())?)
	local value = Instance.new("NumberValue")
	value.Value = 0
	local conn = value.Changed:Connect(apply)
	local tw = TweenService:Create(value, TweenInfo.new(time, style, dir), { Value = 1 })
	tw:Play()
	-- finish on a timer, not on Completed: the end state always lands, even if the tween is cut short
	task.delay(time + 0.03, function()
		conn:Disconnect()
		tw:Cancel()
		apply(1)
		value:Destroy()
		if done then
			done()
		end
	end)
end
Anim.drive = drive

---------------------------------------------------------------------------
-- Drawers: the parts that make up a drawer front slide out along the face, then back
---------------------------------------------------------------------------
local busy: { [Instance]: boolean } = {}

local function drawerParts(spot: BasePart): ({ BasePart }, Vector3?)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { spot }
	local ok, hits = pcall(function()
		return workspace:GetPartBoundsInBox(spot.CFrame, spot.Size + Vector3.new(0.05, 0.05, 0.05), params)
	end)
	if not ok or not hits then
		return {}, nil
	end
	local spotVol = spot.Size.X * spot.Size.Y * spot.Size.Z
	local small, body = {}, nil
	for _, p in hits do
		if p:IsA("BasePart") and p.Anchored and p.Transparency < 1 then
			local vol = p.Size.X * p.Size.Y * p.Size.Z
			-- the drawer front and its handle fit inside the hit box; the cabinet around it doesn't
			local rel = spot.CFrame:PointToObjectSpace(p.Position)
			local half = spot.Size / 2 + Vector3.new(0.1, 0.1, 0.1)
			local inside = math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z
			if inside and vol <= spotVol * 1.6 then
				table.insert(small, p)
			elseif math.max(p.Size.X, p.Size.Y, p.Size.Z) < 12 and (not body or vol > body.Size.X * body.Size.Y * body.Size.Z) then
				-- (the cabinet the drawer is in, not a wall or the floor behind it)
				body = p
			end
		end
	end
	if #small == 0 or not body then
		return {}, nil
	end
	-- the drawer comes out along the spot's thinnest axis, away from the cabinet's middle
	local s = spot.Size
	local axis = s.X <= s.Y and s.X <= s.Z and spot.CFrame.RightVector
		or (s.Y <= s.Z and spot.CFrame.UpVector or spot.CFrame.LookVector)
	local away = spot.Position - body.Position
	if away:Dot(axis) < 0 then
		axis = -axis
	end
	return small, axis
end

function Anim.drawer(spot: BasePart, distance: number?, hold: number?)
	if busy[spot] then
		return
	end
	local parts, axis = drawerParts(spot)
	if not axis or #parts == 0 then
		return
	end
	busy[spot] = true
	local d = axis * (distance or 0.9)
	local base = {}
	for i, p in parts do
		base[i] = p.CFrame
	end
	local function set(k: number)
		for i, p in parts do
			if p.Parent then
				p.CFrame = base[i] + d * k
			end
		end
	end
	drive(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, set, function()
		task.delay(hold or 1.1, function()
			drive(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, function(k)
				set(1 - k)
			end, function()
				busy[spot] = nil
			end)
		end)
	end)
end

---------------------------------------------------------------------------
-- Wardrobe doors: two leaves (parts tagged with a "Leaf" side and a "Hinge" CFrame by
-- Kit.wardrobe) swing out, then shut again
---------------------------------------------------------------------------
function Anim.leaves(model: Instance?, openFor: number?, degrees: number?)
	if not model or busy[model] then
		return
	end
	local parts, closed, hinges, sides = {}, {}, {}, {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Leaf") then
			local c = d:GetAttribute("Closed")
			local h = d:GetAttribute("Hinge")
			if typeof(c) == "CFrame" and typeof(h) == "CFrame" then
				table.insert(parts, d)
				closed[d] = c
				hinges[d] = h
				sides[d] = d:GetAttribute("Leaf")
			end
		end
	end
	if #parts == 0 then
		return
	end
	busy[model] = true
	local ang = math.rad(degrees or 95)
	local function set(k: number)
		for _, p in parts do
			if p.Parent then
				local h = hinges[p]
				-- the left leaf (-1) swings one way, the right (+1) the other: both outward
				local rot = CFrame.Angles(0, -sides[p] * ang * k, 0)
				p.CFrame = h * rot * h:Inverse() * closed[p]
			end
		end
	end
	drive(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, set, function()
		task.delay(openFor or 0.5, function()
			drive(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function(k)
				set(1 - k)
			end, function()
				busy[model] = nil
			end)
		end)
	end)
end

---------------------------------------------------------------------------
-- Hinged doors that stay where you leave them (the fridge, the oven). groups: { { Parts, Hinge = CFrame,
-- Sign = 1 | -1, Axis = "Y" (default, a side hinge) | "X" (a bottom hinge) } }; the parts' current
-- CFrames are the closed ones. Returns a handle:
-- handle.set(open) swings them (false while a swing is still going), handle.Open
---------------------------------------------------------------------------
function Anim.hinged(groups, degrees: number?)
	for _, g in groups do
		g.Closed = {}
		for _, p in g.Parts do
			g.Closed[p] = p.CFrame
		end
	end
	local handle = { Open = false, Busy = false }
	local ang = math.rad(degrees or 100)
	function handle.set(open: boolean, time: number?): boolean
		if handle.Busy or handle.Open == open then
			return false
		end
		handle.Busy = true
		handle.Open = open
		local function apply(k: number)
			local kk = open and k or 1 - k
			for _, g in groups do
				local a = g.Sign * ang * kk
				local rot = g.Axis == "X" and CFrame.Angles(a, 0, 0) or CFrame.Angles(0, a, 0)
				for _, p in g.Parts do
					if p.Parent then
						p.CFrame = g.Hinge * rot * g.Hinge:Inverse() * g.Closed[p]
					end
				end
			end
		end
		drive(time or 0.45, Enum.EasingStyle.Quad, open and Enum.EasingDirection.Out or Enum.EasingDirection.In, apply, function()
			handle.Busy = false
		end)
		return true
	end
	return handle
end

---------------------------------------------------------------------------
-- Picked up: it lifts a little and fades, then it's gone
---------------------------------------------------------------------------
function Anim.vanish(target: Instance)
	local parts = {}
	if target:IsA("BasePart") then
		table.insert(parts, target)
	end
	for _, d in target:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		elseif d:IsA("ProximityPrompt") then
			d.Enabled = false
		end
	end
	local base, transp = {}, {}
	for i, p in parts do
		base[i] = p.CFrame
		transp[i] = p.Transparency
		p.CanCollide = false
		p.CanQuery = false
	end
	drive(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function(k)
		for i, p in parts do
			if p.Parent then
				p.CFrame = base[i] + Vector3.new(0, 0.6 * k, 0)
				p.Transparency = transp[i] + (1 - transp[i]) * k
			end
		end
	end, function()
		if target.Parent then
			target:Destroy()
		end
	end)
end

return Anim
