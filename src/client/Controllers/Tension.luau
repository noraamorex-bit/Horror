--[[
	Tension — the sound of him getting close (13 Oct, the owner: "not scary"; asked for tension
	when he's near). A low drone (APM "Horror Tools": Dark Drone 13) fades in as he gets closer,
	louder still while he's chasing or charging; the heartbeat (Effects) joins in when he's very
	close. Nothing at all while he's out of the picture: no music at night start/end, none in the
	secret ending.

	Tension.level() -> 0..1, how close he is (Effects uses it for the heartbeat).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Tension = {}
local ctx
local player = Players.LocalPlayer

local FAR = 70 -- studs: silent beyond this
local NEAR = 14 -- full volume this close
local QUIET = { Offstage = true, Puppet = true, Trapped = true, Stopped = true }
local HOT = { Chase = true, Charge = true, Ambush = true }

local level = 0
local drone: Sound?

function Tension.level(): number
	return level
end

-- how much he should be felt right now (0..1), before smoothing
local function target(curtis: Model?): number
	if not player:GetAttribute("InGame") then
		return 0
	end
	local act = workspace:GetAttribute("Act")
	if act == "Lobby" or act == "Below" or act == "Ended" then
		return 0
	end
	local st = workspace:GetAttribute("IntruderState")
	if not st or QUIET[st] then
		return 0
	end
	local root = curtis and curtis:FindFirstChild("HumanoidRootPart") :: BasePart?
	local cam = workspace.CurrentCamera
	if not root or not cam then
		return 0
	end
	local d = (root.Position - cam.CFrame.Position).Magnitude
	local k = math.clamp((FAR - d) / (FAR - NEAR), 0, 1)
	k = k * k
	-- (a glimpse of him before the hunt: only a breath of it, so it doesn't give him away)
	if st == "Lurk" then
		k *= 0.35
	end
	-- he's after someone: the whole house feels it a little, the one he's after a lot
	if HOT[st] then
		k = math.max(k, d < FAR * 1.4 and 0.45 or 0.15)
	end
	return k
end

function Tension.init(c)
	ctx = c
	ctx.Tension = Tension
end

function Tension.start()
	drone = ctx.Effects and ctx.Effects.localSound("TensionDrone") or nil
	if drone then
		drone.Volume = 0
		drone.Looped = true
		-- (the file fades in over its first seconds and out over its last: loop the steady middle)
		pcall(function()
			(drone :: any).PlaybackRegionsEnabled = true;
			(drone :: any).LoopRegion = NumberRange.new(6, 40)
		end)
	end
	local base = ctx.Sounds.get("TensionDrone")
	local maxVol = base and base.Volume or 0.5
	local curtis: Model? = nil
	local findClock = 0
	RunService.Heartbeat:Connect(function(dt)
		findClock -= dt
		if (not curtis or not curtis.Parent) and findClock <= 0 then
			findClock = 2
			curtis = workspace:FindFirstChild("Curtis", true) :: Model?
		end
		local want = target(curtis)
		-- swells in over a second or two, lets go slowly
		local rate = want > level and 0.7 or 0.25
		level += math.clamp(want - level, -rate * dt, rate * dt)
		if not drone then
			return
		end
		local vol = maxVol * level
		if vol > 0.005 then
			drone.Volume = vol
			drone.PlaybackSpeed = 0.94 + level * 0.1
			if not drone.IsPlaying then
				drone:Play()
			end
		elseif drone.IsPlaying then
			drone:Stop()
		end
	end)
end

return Tension
