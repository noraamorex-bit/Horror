--[[
	EndingService — resolves the night, shows every player the ending, their fates and the
	"What Really Happened" timeline, then restarts the house.
]]

local Ending = {}
local ctx
local over = false

function Ending.init(c)
	ctx = c
end

function Ending.reset()
	over = false
	workspace:SetAttribute("EndingActive", nil)
end

function Ending.isOver(): boolean
	return over
end

function Ending.trigger(kind: string)
	if over then
		return
	end
	over = true
	workspace:SetAttribute("EndingActive", kind)
	local story = ctx.Story.Endings[kind]
	if ctx.Intruder then
		ctx.Intruder.stop()
	end

	-- fates
	local fates = {}
	for _, p in ctx.Util.sessionPlayers() do
		local fate
		if p:GetAttribute("Escaped") then
			fate = ctx.Story.Fates.Escaped
		elseif p:GetAttribute("Captured") then
			fate = kind == "GoneQuiet" and ctx.Story.Fates.Captured or ctx.Story.Fates.Rescued
		else
			fate = ctx.Story.Fates.Safe
		end
		table.insert(fates, {
			Name = p.DisplayName,
			Role = p:GetAttribute("RoleName") or "",
			Fate = fate,
			WasCaptured = ctx.Capture.wasEverCaptured(p),
		})
		p:SetAttribute("Fate", fate)
	end

	-- saved stats; who saw this ending for the first time
	local firstFor = {}
	if ctx.Stats then
		local ok, firsts = pcall(ctx.Stats.recordNight, ctx.Util.sessionPlayers(), kind)
		if ok then
			for userId in firsts do
				table.insert(firstFor, userId)
			end
		end
	end

	local payload = {
		Kind = kind,
		FirstFor = firstFor,
		Title = story.Title,
		Body = story.Body,
		Bad = story.Bad == true,
		Fates = fates,
		Truths = ctx.Director.getTruthLog(),
		Duration = ctx.Director.elapsedString(),
		RestartIn = ctx.Reserved and ctx.Config.Lobby.ReturnDelay or 60,
		ReturnToLobby = ctx.Reserved == true,
	}
	ctx.Remotes.Ending:FireAllClients(payload)

	task.delay(payload.RestartIn, function()
		ctx.restart()
	end)
end

return Ending
