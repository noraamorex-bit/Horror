--[[
	HeartbeatService — the heartbeat minigame (like DOORS): he has stopped right outside your
	hiding spot and is listening. Half-hearts fly in from the left and the right; press that side
	as each one reaches the heart. Miss too many (Config.Heartbeat.Misses) and he hears you.

	The server deals the beats (times and sides) and counts the misses. The client draws them and
	reports each beat as hit or missed; a beat that isn't reported in time counts as a miss, so
	going quiet (or leaving the game) never gets you through.

		Heartbeat.begin(player, seconds, onFail)  -- onFail(): he heard them
		Heartbeat.stop(player)                    -- he walked away (or the moment's over)
		Heartbeat.isActive(player)
]]

local Players = game:GetService("Players")

local Heartbeat = {}
local ctx
local sessions: { [Player]: any } = {}
local seq = 0

function Heartbeat.init(c)
	ctx = c
	ctx.Heartbeat = Heartbeat
end

local function settings()
	local cfg = table.clone(ctx.Config.Heartbeat)
	local hard = ctx.Config.Difficulty and ctx.Config.Difficulty.Hard
	if workspace:GetAttribute("Difficulty") == "Hard" and hard and hard.Heartbeat then
		for k, v in hard.Heartbeat do
			cfg[k] = v
		end
	end
	return cfg
end

local function finish(s, result: string)
	if sessions[s.Player] ~= s then
		return
	end
	sessions[s.Player] = nil
	if s.Player.Parent then
		ctx.Remotes.Heartbeat:FireClient(s.Player, { Id = s.Id, Result = result })
	end
	if result == "Pass" and ctx.Economy then
		ctx.Economy.track(s.Player, "Heartbeats", 1)
	end
end

local function record(s, i: number, hit: boolean)
	if sessions[s.Player] ~= s or s.Results[i] ~= nil then
		return
	end
	s.Results[i] = hit
	if hit then
		return
	end
	s.Misses += 1
	ctx.Remotes.Shake:FireClient(s.Player, 0.35, 0.3)
	ctx.PlayerState.addNerve(s.Player, -6)
	if s.Misses >= s.Limit then
		finish(s, "Fail")
		task.spawn(s.OnFail)
	end
end

function Heartbeat.isActive(player: Player): boolean
	return sessions[player] ~= nil
end

function Heartbeat.begin(player: Player, seconds: number, onFail: () -> ())
	Heartbeat.stop(player)
	local cfg = settings()
	local beats = {}
	local t = cfg.Lead
	while t <= seconds - 0.3 do
		table.insert(beats, { T = t, Side = math.random() < 0.5 and "L" or "R" })
		t += cfg.Interval * (0.9 + math.random() * 0.25)
	end
	seq += 1
	local s = {
		Id = seq,
		Player = player,
		Beats = beats,
		Results = {},
		Misses = 0,
		Limit = cfg.Misses,
		Start = os.clock(),
		Window = cfg.Window,
		OnFail = onFail,
	}
	sessions[player] = s
	ctx.Remotes.Heartbeat:FireClient(player, {
		Id = s.Id,
		Start = workspace:GetServerTimeNow(),
		Beats = beats,
		Travel = cfg.Travel,
		Window = cfg.Window,
		Misses = cfg.Misses,
	})
	-- beats nobody answered for count as misses; the whole thing ends when he walks off
	task.spawn(function()
		while sessions[player] == s do
			task.wait(0.2)
			local now = os.clock() - s.Start
			for i, b in beats do
				if s.Results[i] == nil and now > b.T + cfg.Window + 1.5 then
					record(s, i, false)
				end
			end
			if sessions[player] ~= s then
				return
			end
			if now > seconds + 0.5 then
				finish(s, "Pass")
			end
		end
	end)
	return s
end

function Heartbeat.stop(player: Player)
	local s = sessions[player]
	if s then
		finish(s, "Stop")
	end
end

function Heartbeat.reset()
	for p, s in sessions do
		finish(s, "Stop")
	end
	sessions = {}
end

function Heartbeat.start()
	-- the client's verdict on each beat: (sessionId, beatIndex, hit)
	ctx.Remotes.HeartbeatInput.OnServerEvent:Connect(function(player, id, index, hit)
		local s = sessions[player]
		if not s or id ~= s.Id or type(index) ~= "number" or type(hit) ~= "boolean" then
			return
		end
		local b = s.Beats[index]
		if not b then
			return
		end
		-- (a hit can't be claimed before that half-heart could have arrived)
		if hit and os.clock() - s.Start < b.T - s.Window - 0.4 then
			return
		end
		record(s, index, hit)
	end)
	Players.PlayerRemoving:Connect(function(p)
		sessions[p] = nil
	end)
end

return Heartbeat
