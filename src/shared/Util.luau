--[[
	Util — small helpers shared by server and client.
]]

local Players = game:GetService("Players")

local Util = {}

function Util.new(className: string, props: { [string]: any }?, parent: Instance?)
	local inst = Instance.new(className)
	if props then
		for k, v in props do
			(inst :: any)[k] = v
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function Util.getRoot(player: Player): BasePart?
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function Util.getHumanoid(player: Player): Humanoid?
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChildOfClass("Humanoid")
end

-- get up off any seat (before we move the character somewhere else)
function Util.unseat(player: Player)
	local hum = Util.getHumanoid(player)
	if hum and hum.SeatPart then
		local weld = hum.SeatPart:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		hum.Sit = false
	end
end

function Util.isAlive(player: Player): boolean
	local hum = Util.getHumanoid(player)
	return hum ~= nil and hum.Health > 0 and Util.getRoot(player) ~= nil
end

-- players that are in the session and able to act (not captured / escaped)
function Util.activePlayers(): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("InGame") and not p:GetAttribute("Captured") and not p:GetAttribute("Escaped") and Util.isAlive(p) then
			table.insert(list, p)
		end
	end
	return list
end

function Util.sessionPlayers(): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("InGame") then
			table.insert(list, p)
		end
	end
	return list
end

function Util.flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

function Util.choice<T>(list: { T }, rng: Random?): T?
	if #list == 0 then
		return nil
	end
	local r = rng or Random.new()
	return list[r:NextInteger(1, #list)]
end

-- entries: { {item, weight} }
function Util.weighted(entries: { { any } }, rng: Random?): any
	local total = 0
	for _, e in entries do
		total += e[2]
	end
	if total <= 0 then
		return nil
	end
	local r = (rng or Random.new()):NextNumber() * total
	for _, e in entries do
		r -= e[2]
		if r <= 0 then
			return e[1]
		end
	end
	return entries[#entries][1]
end

function Util.shuffle<T>(list: { T }, rng: Random?): { T }
	local r = rng or Random.new()
	for i = #list, 2, -1 do
		local j = r:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

function Util.clockString(totalMinutes: number): string
	local m = math.floor(totalMinutes) % (24 * 60)
	local h = math.floor(m / 60)
	local mins = m % 60
	local suffix = h >= 12 and "PM" or "AM"
	local h12 = h % 12
	if h12 == 0 then
		h12 = 12
	end
	return string.format("%d:%02d %s", h12, mins, suffix)
end

function Util.formatSeconds(s: number): string
	s = math.max(0, math.floor(s))
	return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

-- safe material lookup (newer materials fall back gracefully)
function Util.material(name: string, fallback: string?): Enum.Material
	local ok, mat = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	if ok and mat then
		return mat
	end
	return (Enum.Material :: any)[fallback or "SmoothPlastic"]
end

return Util
