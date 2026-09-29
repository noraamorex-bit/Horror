--[[
	ChatService — proximity text chat.
	Messages reach players within Config.ChatRange, or anyone if both hold a walkie-talkie.
	(Enable Spatial Voice in Game Settings for proximity voice.)
]]

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local Chat = {}
local ctx

function Chat.init(c)
	ctx = c
end

local function canHear(sender: Player, receiver: Player): boolean
	if sender == receiver then
		return true
	end
	-- lobby / ending: everyone hears everyone
	if not ctx.Director or ctx.Director.getAct() == "Lobby" or (ctx.Ending and ctx.Ending.isOver()) then
		return true
	end
	-- escaped players are safe together (and with 911 on the line), they can talk to each other
	if sender:GetAttribute("Escaped") and receiver:GetAttribute("Escaped") then
		return true
	end
	if ctx.Inventory.has(sender, "Walkie") and ctx.Inventory.has(receiver, "Walkie") and not sender:GetAttribute("Captured") then
		return true
	end
	local a = ctx.Util.getRoot(sender)
	local b = ctx.Util.getRoot(receiver)
	if not a or not b then
		return false
	end
	local range = ctx.Config.ChatRange
	if sender:GetAttribute("Captured") then
		range = 18 -- muffled
	end
	return (a.Position - b.Position).Magnitude <= range
end

function Chat.start()
	task.spawn(function()
		local channels = TextChatService:WaitForChild("TextChannels", 30)
		if not channels then
			warn("[Chat] TextChannels not found; proximity chat disabled")
			return
		end
		local general = channels:WaitForChild("RBXGeneral", 30) :: TextChannel?
		if not general then
			return
		end
		general.ShouldDeliverCallback = function(message: TextChatMessage, target: TextSource)
			local src = message.TextSource
			if not src then
				return true
			end
			local sender = Players:GetPlayerByUserId(src.UserId)
			local receiver = Players:GetPlayerByUserId(target.UserId)
			if not sender or not receiver then
				return true
			end
			return canHear(sender, receiver)
		end
	end)
end

return Chat
