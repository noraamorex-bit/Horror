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
	-- the secret ending: the police arrive and you've already worked out who he is
	if kind == "Sirens" and ctx.Director.evidenceCount and ctx.Director.evidenceCount() >= ctx.Story.EvidenceNeeded then
		kind = "CaseClosed"
	end
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
		elseif p:GetAttribute("Dead") then
			fate = ctx.Story.Fates.Dead
		elseif p:GetAttribute("Captured") then
			fate = (kind == "GoneQuiet" or kind == "GotAway") and ctx.Story.Fates.Captured or ctx.Story.Fates.Rescued
		else
			fate = ctx.Story.Fates.Safe
		end
		-- a one-line recap of their night
		local bits = {}
		local function add(attr, one, many)
			local n = tonumber(p:GetAttribute(attr)) or 0
			if n > 0 then
				table.insert(bits, n == 1 and one or string.format(many, n))
			end
		end
		add("NightHides", "hid once", "hid %d times")
		add("NightSpotted", "was spotted once", "was spotted %d times")
		add("NightCaught", "got caught", "got caught %d times")
		add("NightRescues", "freed a friend", "freed %d friends")
		table.insert(fates, {
			Recap = #bits > 0 and table.concat(bits, " · ") or "never saw him coming",
			Name = p.DisplayName,
			Role = p:GetAttribute("RoleName") or "",
			Fate = fate,
			WasCaptured = ctx.Capture.wasEverCaptured(p),
		})
		p:SetAttribute("Fate", fate)
	end

	-- badges (IDs in Config.Badges; 0 = not set up yet)
	local badges = ctx.Config.Badges or {}
	for _, p in ctx.Util.sessionPlayers() do
		for _, id in { badges.FirstNight, badges[kind] } do
			if type(id) == "number" and id > 0 then
				task.spawn(function()
					pcall(function()
						game:GetService("BadgeService"):AwardBadge(p.UserId, id)
					end)
				end)
			end
		end
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
