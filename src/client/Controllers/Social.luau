--[[
	Social — the buttons that help the game spread: invite friends (Roblox's invite prompt) and
	favorite the game (Roblox's favorite prompt). Both fail quietly where Roblox doesn't allow
	them (Studio, a player who can't send invites, etc).
]]

local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local AvatarEditorService = game:GetService("AvatarEditorService")

local Social = {}
local ctx
local player = Players.LocalPlayer
local favoritePrompted = false

function Social.invite()
	task.spawn(function()
		local ok, can = pcall(function()
			return SocialService:CanSendGameInviteAsync(player)
		end)
		if ok and can then
			pcall(function()
				local options = Instance.new("ExperienceInviteOptions")
				options.PromptMessage = "Survive the night at 14 Alder Lane with me"
				SocialService:PromptGameInvite(player, options)
			end)
		elseif ctx.Notice then
			ctx.Notice.show({ Title = "Invites", Body = "Invites aren't available right now.", Button = "OK" })
		end
	end)
end

function Social.favorite()
	favoritePrompted = true
	pcall(function()
		AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
	end)
end

-- asks once per session, after a finished night
function Social.maybeAskFavorite()
	if favoritePrompted then
		return
	end
	Social.favorite()
end

-- a pill button; `kind` = "invite" | "favorite"
function Social.button(parent: Instance, kind: string, props): TextButton
	local UI = ctx.UI
	local isInvite = kind == "invite"
	local b = UI.new("TextButton", {
		Size = UDim2.fromOffset(200, 54),
		Text = isInvite and "INVITE FRIENDS" or "FAVORITE",
		Font = UI.Font.Bold,
		TextSize = 19,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = isInvite and Color3.fromRGB(40, 110, 70) or Color3.fromRGB(170, 120, 30),
		AutoButtonColor = true,
		Parent = parent,
	})
	for k, v in props or {} do
		(b :: any)[k] = v
	end
	UI.corner(b, 12)
	UI.stroke(b, Color3.new(1, 1, 1), 1.5, 0.6)
	b.Activated:Connect(function()
		if isInvite then
			Social.invite()
		else
			Social.favorite()
		end
	end)
	return b
end

function Social.init(c)
	ctx = c
	ctx.Social = Social
end

function Social.start() end

return Social
