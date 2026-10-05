--[[
	BadgeService — badges for the night (IDs in Config.Badges; 0 = not created yet, skipped).

	• every ending has its own badge, for everyone there when it happens
	• FirstNight: finish any night
	• HardSurvivor: make it through a night on Hard (escaped, or still alive when it ends well)
	• Rescuer: cut a friend free in the boiler room
]]

local BadgeService = game:GetService("BadgeService")

local Badges = {}
local ctx

function Badges.init(c)
	ctx = c
end

function Badges.award(player: Player, key: string)
	local id = (ctx.Config.Badges or {})[key]
	if type(id) ~= "number" or id <= 0 or not player.Parent then
		return
	end
	task.spawn(function()
		pcall(function()
			if not BadgeService:UserHasBadgeAsync(player.UserId, id) then
				BadgeService:AwardBadge(player.UserId, id)
			end
		end)
	end)
end

function Badges.onEnding(kind: string)
	local bad = ctx.Story.Endings[kind] and ctx.Story.Endings[kind].Bad == true
	local hard = workspace:GetAttribute("Difficulty") == "Hard"
	for _, p in ctx.Util.sessionPlayers() do
		Badges.award(p, "FirstNight")
		Badges.award(p, kind)
		local made = p:GetAttribute("Escaped") or (not bad and not p:GetAttribute("Dead"))
		if hard and made then
			Badges.award(p, "HardSurvivor")
		end
	end
end

return Badges
