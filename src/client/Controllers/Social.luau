--[[
	Social — the buttons that help the game spread and bring players back: invite friends
	(Roblox's invite prompt), favorite the game (Roblox's favorite prompt) and REMIND ME (Roblox's
	experience-notification opt-in: the game can then tell them when their daily reward is ready).
	All fail quietly where Roblox doesn't allow them (Studio, a player who can't send invites,
	already opted in, etc); REMIND ME only shows when Roblox says it can ask.
]]

local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")

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

-- Roblox's own opt-in for notifications from this game
function Social.remind()
	task.spawn(function()
		pcall(function()
			ExperienceNotificationService:PromptOptIn()
		end)
	end)
end

-- asks once per session, after a finished night
function Social.maybeAskFavorite()
	if favoritePrompted then
		return
	end
	Social.favorite()
end

-- a pill button; `kind` = "invite" | "favorite" | "remind"
function Social.button(parent: Instance, kind: string, props): TextButton
	local UI = ctx.UI
	local isInvite = kind == "invite"
	local isRemind = kind == "remind"
	-- minimal: dark glass, thin outline, white text
	local b = UI.new("TextButton", {
		Size = UDim2.fromOffset(150, 34),
		Text = isInvite and "Invite friends" or (isRemind and "🔔 Remind me" or "Favorite"),
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(235, 232, 226),
		BackgroundColor3 = Color3.fromRGB(12, 12, 14),
		BackgroundTransparency = 0.4,
		AutoButtonColor = true,
		Parent = parent,
	})
	for k, v in props or {} do
		(b :: any)[k] = v
	end
	UI.corner(b, 6)
	UI.stroke(b, Color3.new(1, 1, 1), 1, 0.8)
	b.Activated:Connect(function()
		if isInvite then
			Social.invite()
		elseif isRemind then
			Social.remind()
			b.Visible = false
		else
			Social.favorite()
		end
	end)
	if isRemind then
		-- (only when Roblox will actually show the prompt: not opted in yet, allowed for this account)
		b.Visible = false
		task.spawn(function()
			local ok, can = pcall(function()
				return ExperienceNotificationService:CanPromptOptInAsync()
			end)
			if ok and can == true and b.Parent then
				b.Visible = true
			end
		end)
	end
	return b
end

function Social.init(c)
	ctx = c
	ctx.Social = Social
end

function Social.start() end

return Social
