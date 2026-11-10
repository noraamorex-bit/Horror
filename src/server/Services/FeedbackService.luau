--[[
	FeedbackService (v150, the owner: "Is there a way to get you to be able to see the feedback comments there
	is a lot"). Roblox's own feedback window sends to Creator Hub → Audience → Feedback, which no API can read
	(only its CSV export). So the 📝 buttons (the lobby's mailbox, every result card) open our own box
	(client Social.feedbackBox): what's written goes through Roblox's text filter (the strictest kind, the
	one for everyone to see: no personal details survive it) and is kept in the Feedback_v1 data store, one
	key a day ("d:YYYY-MM-DD", UTC), where tools/pull_feedback.py reads it.

	An entry: { t = os.time(), u = user id, txt = the filtered text, w = where (Lobby / Card),
	v = place version, n = nights played, a = the act (in a night), d = dead (on a death card) }.
	3-500 characters; one every 20 s and 8 a day per player (this server).
]]

local DataStoreService = game:GetService("DataStoreService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local Feedback = {}
local ctx
local store: any = nil
local lastAt: { [Player]: number } = {}
local daily: { [Player]: number } = {}

Feedback.MaxLen = 500
Feedback.MinLen = 3
Feedback.Gap = 20
Feedback.PerDay = 8
Feedback.Store = "Feedback_v1"

function Feedback.init(c)
	ctx = c
	ctx.Feedback = Feedback
end

local function getStore()
	if store == nil then
		local ok, s = pcall(function()
			return DataStoreService:GetDataStore(Feedback.Store)
		end)
		store = ok and s or false
	end
	return store or nil
end

-- Roblox's filter, the version for everyone to see (a retry; nothing unfiltered is ever kept)
local function filtered(text: string, player: Player): string?
	for attempt = 1, 2 do
		local ok, res = pcall(function()
			local r = TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
			return r:GetNonChatStringForBroadcastAsync()
		end)
		if ok and type(res) == "string" then
			return res
		end
		if attempt == 1 then
			task.wait(1)
		end
	end
	return nil
end

function Feedback.dayKey(t: number?): string
	return "d:" .. os.date("!%Y-%m-%d", t or os.time())
end

function Feedback.submit(player: Player, text: any, where: any): (boolean, string)
	if type(text) ~= "string" then
		return false, "Type something first."
	end
	text = (string.gsub(text, "^%s+", ""))
	text = (string.gsub(text, "%s+$", ""))
	if #text < Feedback.MinLen then
		return false, "Type something first."
	end
	if utf8.len(text) == nil then
		return false, "That text couldn't be read."
	end
	if #text > Feedback.MaxLen then
		text = string.sub(text, 1, Feedback.MaxLen)
		-- (never cut a character in half)
		while #text > 0 and utf8.len(text) == nil do
			text = string.sub(text, 1, #text - 1)
		end
	end
	local now = os.clock()
	if now - (lastAt[player] or -1e9) < Feedback.Gap then
		return false, "Thanks! Give it a few seconds before the next one."
	end
	if (daily[player] or 0) >= Feedback.PerDay then
		return false, "Thanks for all of it! That's plenty for today."
	end
	lastAt[player] = now
	local clean = filtered(text, player)
	if not clean then
		lastAt[player] = nil
		return false, "Couldn't send it right now. Try again in a minute."
	end
	local s = getStore()
	if not s then
		lastAt[player] = nil
		return false, "Couldn't send it right now. Try again in a minute."
	end
	local entry = {
		t = os.time(),
		u = player.UserId,
		txt = clean,
		w = (where == "Card" or where == "Lobby") and where or "Other",
		v = game.PlaceVersion,
		n = tonumber(player:GetAttribute("StatNights")) or 0,
		a = ctx.Mode and ctx.Mode.get and ctx.Mode.get() ~= "Lobby" and workspace:GetAttribute("Act") or nil,
		d = player:GetAttribute("Dead") == true or nil,
	}
	local saved = false
	local ok = pcall(function()
		s:UpdateAsync(Feedback.dayKey(entry.t), function(old)
			old = type(old) == "table" and old or {}
			-- (a day's key stays far under the 4 MB limit)
			if #old >= 3000 then
				return nil
			end
			table.insert(old, entry)
			saved = true
			return old
		end)
	end)
	if not ok or not saved then
		lastAt[player] = nil
		return false, "Couldn't send it right now. Try again in a minute."
	end
	daily[player] = (daily[player] or 0) + 1
	if ctx.Journey then
		if ctx.Journey.event then
			ctx.Journey.event(player, "FeedbackSent", entry.w)
		end
		if ctx.Journey.lobbyMark and entry.w == "Lobby" then
			pcall(ctx.Journey.lobbyMark, player, "FeedbackSent")
		end
	end
	return true, "✓ Sent. Thank you! We read every one."
end

function Feedback.start()
	ctx.Remotes.SendFeedback.OnServerEvent:Connect(function(player, text, where)
		local ok, msg = Feedback.submit(player, text, where)
		ctx.Remotes.FeedbackResult:FireClient(player, ok, msg)
	end)
	Players.PlayerRemoving:Connect(function(p)
		lastAt[p] = nil
		daily[p] = nil
	end)
end

return Feedback
