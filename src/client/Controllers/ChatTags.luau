--[[
	ChatTags — in the chat, each player's name carries their tags: ★ for supporters and the title
	they've equipped in the LOCKER, in its colour (the same as the tag over their head in the
	lobby). Built from the speaker's attributes (EconomyService mirrors TitleText and TitleColor;
	ShopService sets Pass_Supporter), in the lobby and in the house. (Level and nights survived
	are in the server's player list instead: StatsService leaderstats.)
]]

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local ChatTags = {}
local ctx

local GOLD = "#ffdc8c"

-- (titles are our own names, but never let a stray character break the rich text)
local function escape(s: string): string
	return (string.gsub(s, "[<>&\"']", ""))
end

local function hex(c: any, default: string): string
	if typeof(c) == "Color3" then
		local ok, h = pcall(function()
			return (c :: Color3):ToHex()
		end)
		if ok and type(h) == "string" then
			return "#" .. h
		end
	end
	return default
end

-- the tags for one player, as rich text ("" when they have none)
function ChatTags.prefixFor(p: Player): string
	local parts = {}
	if p:GetAttribute("Pass_VIP") == true then
		table.insert(parts, "<font color=\"" .. GOLD .. "\">★ VIP</font>")
	elseif p:GetAttribute("Pass_Supporter") == true then
		table.insert(parts, "<font color=\"" .. GOLD .. "\">★</font>")
	end
	local title = p:GetAttribute("TitleText")
	if type(title) == "string" and title ~= "" then
		table.insert(parts, "<font color=\"" .. hex(p:GetAttribute("TitleColor"), "#ffffff") .. "\">[" .. escape(title) .. "]</font>")
	end
	return table.concat(parts, " ")
end

function ChatTags.init(c)
	ctx = c
end

function ChatTags.start()
	pcall(function()
		TextChatService.OnIncomingMessage = function(message: TextChatMessage)
			local props = Instance.new("TextChatMessageProperties")
			local src = message.TextSource
			local p = src and Players:GetPlayerByUserId(src.UserId)
			if p then
				local prefix = ChatTags.prefixFor(p)
				if prefix ~= "" then
					props.PrefixText = prefix .. " " .. message.PrefixText
				end
			end
			return props
		end
	end)
end

return ChatTags
