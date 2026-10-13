--[[
	NightPlan — what the first act asks of you tonight.

	A first night (anyone in the group who hasn't seen one through) always gets the chores the
	night was tuned around: order pizza, popcorn, close the upstairs windows. After that, pizza
	stays (the delivery man is the act's story) and the other two are drawn from the pool, never
	the same two as this server's last night. (Logs, v81: 12 of 60 players who pressed ANOTHER
	NIGHT left within two minutes of the same chores again.)

		NightPlan.choose(anyNew, lastSet, random?) -> { "Popcorn", "Windows" } (sorted)
		NightPlan.evening(chores) -> the act's objective list (pizza first)
]]

local NightPlan = {}

NightPlan.Pool = { "Popcorn", "Windows", "Fire", "Movie" }
NightPlan.Classic = { "Popcorn", "Windows" }

local function key(set: { string }): string
	local c = table.clone(set)
	table.sort(c)
	return table.concat(c, "+")
end
NightPlan.key = key

function NightPlan.choose(anyNew: boolean, lastSet: { string }?, rand: ((number) -> number)?): { string }
	if anyNew then
		local c = table.clone(NightPlan.Classic)
		table.sort(c)
		return c
	end
	local pick = rand or function(n: number): number
		return math.random(n)
	end
	-- any pair from the pool except last night's (so at least one chore is new every time)
	local last = lastSet and key(lastSet) or ""
	local list = {}
	local pool = NightPlan.Pool
	for i = 1, #pool do
		for j = i + 1, #pool do
			local pair = { pool[i], pool[j] }
			table.sort(pair)
			if key(pair) ~= last then
				table.insert(list, pair)
			end
		end
	end
	return list[pick(#list)]
end

function NightPlan.evening(chores: { string }): { string }
	local list = { "OrderPizza" }
	for _, id in chores do
		table.insert(list, id)
	end
	return list
end

return NightPlan
