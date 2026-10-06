--[[
	Perception — who can see whom.

	Perception.intruderSees(headCFrame, player, model)   Curtis -> a player (FOV cone, light-based range, LOS)
	Perception.playerSees(player, position, model?)       a player -> a point (their facing, light, flashlight, LOS)
	Perception.anyoneSees(position, model?)
]]

local Players = game:GetService("Players")

local Perception = {}
local ctx

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = true

function Perception.init(c)
	ctx = c
end

local function lightningNow(): boolean
	local t = workspace:GetAttribute("LastLightning")
	return t ~= nil and workspace:GetServerTimeNow() - t < 0.6
end

-- raycast; true if nothing (other than `target`) is in the way
function Perception.clear(from: Vector3, to: Vector3, ignore: { Instance }, target: Instance?): boolean
	params.FilterDescendantsInstances = ignore
	local result = workspace:Raycast(from, to - from, params)
	if not result then
		return true
	end
	return target ~= nil and result.Instance:IsDescendantOf(target)
end

local function otherCharacters(except: Player?): { Instance }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p ~= except and p.Character then
			table.insert(list, p.Character)
		end
	end
	return list
end

-- The eye of a player: their head, facing where their character faces (or their hiding peek view)
function Perception.eyeOf(player: Player): (Vector3?, Vector3?)
	local view = player:GetAttribute("HideView")
	if typeof(view) == "CFrame" then
		return view.Position, view.LookVector
	end
	local char = player.Character
	local head = char and char:FindFirstChild("Head") :: BasePart?
	local root = ctx.Util.getRoot(player)
	if not head or not root then
		return nil, nil
	end
	return head.Position, root.CFrame.LookVector
end

function Perception.intruderSightRange(player: Player): number
	local I = ctx.Config.Intruder
	local range
	if player:GetAttribute("FlashlightOn") then
		range = I.SightFlashlight
	elseif ctx.PlayerState.isLit(player) then
		range = I.SightLit
	else
		range = I.SightDark
		if player:GetAttribute("Crouching") then
			range *= I.CrouchSightMultiplier
		end
	end
	if lightningNow() then
		range = math.max(range, 60)
	end
	return range
end

function Perception.intruderSees(head: CFrame, player: Player, model: Instance): boolean
	if not player:GetAttribute("InGame") or player:GetAttribute("Captured") or player:GetAttribute("Escaped") or player:GetAttribute("Hiding") or player:GetAttribute("AdminGhost") then
		return false
	end
	local char = player.Character
	local target = char and char:FindFirstChild("Head") :: BasePart?
	if not char or not target then
		return false
	end
	local to = target.Position - head.Position
	local d = to.Magnitude
	if d > Perception.intruderSightRange(player) then
		return false
	end
	local I = ctx.Config.Intruder
	-- up close he doesn't need to be facing you: he hears footsteps, breathing, sees the beam
	-- swing across the wall. Only someone crouched and keeping still can stay behind him.
	local aware = I.PeripheralRange
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local v = root and root.AssemblyLinearVelocity or Vector3.zero
	local moving = Vector3.new(v.X, 0, v.Z).Magnitude > 2
	if player:GetAttribute("Sprinting") and moving then
		aware = math.max(aware, I.HearSprint or 16)
	elseif moving and not player:GetAttribute("Crouching") then
		aware = math.max(aware, I.HearWalk or 11)
	end
	if player:GetAttribute("FlashlightOn") then
		aware = math.max(aware, I.HearFlashlight or 12)
	end
	if player:GetAttribute("Crouching") and not moving then
		aware = math.min(aware, 4)
	end
	if d > aware then
		local flat = Vector3.new(to.X, 0, to.Z)
		local look = Vector3.new(head.LookVector.X, 0, head.LookVector.Z)
		if flat.Magnitude > 0.01 and look.Magnitude > 0.01 and look.Unit:Dot(flat.Unit) < math.cos(math.rad(I.FOV / 2)) then
			return false
		end
	end
	local ignore = otherCharacters(player)
	table.insert(ignore, model)
	return Perception.clear(head.Position, target.Position, ignore, char)
end

function Perception.playerSees(player: Player, pos: Vector3, model: Instance?): boolean
	if player:GetAttribute("Escaped") or not player:GetAttribute("InGame") then
		return false
	end
	local eye, look = Perception.eyeOf(player)
	if not eye or not look then
		return false
	end
	local to = pos - eye
	local d = to.Magnitude
	if d < 2 then
		return true
	end
	local dir = to / d
	local flatLook = Vector3.new(look.X, 0, look.Z)
	local flatDir = Vector3.new(dir.X, 0, dir.Z)
	if flatLook.Magnitude < 0.01 or flatDir.Magnitude < 0.01 then
		return false
	end
	local dot = flatLook.Unit:Dot(flatDir.Unit)
	if dot < math.cos(math.rad(58)) then
		return false
	end
	local range
	if ctx.Power.isLit(pos) then
		range = 110
	elseif lightningNow() then
		range = 140
	elseif player:GetAttribute("FlashlightOn") and dot > math.cos(math.rad(26)) then
		range = ctx.Config.Flashlight.Range + 6
	else
		range = 18
	end
	if d > range then
		return false
	end
	local ignore = otherCharacters(nil)
	if model then
		table.insert(ignore, model)
	end
	return Perception.clear(eye, pos, ignore)
end

function Perception.anyoneSees(pos: Vector3, model: Instance?): boolean
	for _, p in ctx.Util.sessionPlayers() do
		if not p:GetAttribute("Captured") and Perception.playerSees(p, pos, model) then
			return true
		end
	end
	return false
end

return Perception
