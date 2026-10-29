--[[
	Social — the buttons that help the game spread and bring players back: invite friends
	(Roblox's invite prompt), favorite the game (Roblox's favorite prompt) and REMIND ME (Roblox's
	experience-notification opt-in: the game can then tell them when their daily reward is ready).
	All fail quietly where Roblox doesn't allow them (Studio, a player who can't send invites,
	already opted in, etc); REMIND ME only shows when Roblox says it can ask. In the lobby, the
	feedback mailbox opens Roblox's feedback window (v123).
]]

local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Social = {}
local ctx
local player = Players.LocalPlayer
local favoritePrompted = false

-- (in the house, the invite carries this night's server code: the lobby sends whoever accepts
-- straight here, into the same house, instead of into a night of their own; in the lobby it says who
-- invited them, v121: StatsService pays you both for it)
function Social.inviteData(): string?
	local code = workspace:GetAttribute("NightCode")
	if ctx.Mode ~= "Lobby" and type(code) == "string" and #code > 0 then
		return "night:" .. code
	end
	if ctx.Mode == "Lobby" then
		return "ref:" .. tostring(player.UserId)
	end
	return nil
end

-- (v121) what a friend who joins pays you (Config.Referral), for the buttons
function Social.bonus(): number
	return (ctx.Config.Referral and ctx.Config.Referral.Coins) or 0
end

function Social.invite()
	task.spawn(function()
		local ok, can = pcall(function()
			return SocialService:CanSendGameInviteAsync(player)
		end)
		if ok and can then
			pcall(function()
				local options = Instance.new("ExperienceInviteOptions")
				local launch = Social.inviteData()
				local night = launch ~= nil and string.sub(launch, 1, 6) == "night:"
				options.PromptMessage = (night and "He's in the house. Come hide with me, right now" or "Survive the night at 14 Alder Lane with me")
					.. (Social.bonus() > 0 and ("  (+" .. Social.bonus() .. " coins for every friend who joins)") or "")
				if launch then
					options.LaunchData = launch
				end
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

-- (v123) Roblox's own feedback window, from the mailbox on the lobby lawn (LobbyServer): what's sent
-- shows in Creator Hub → Audience → Feedback (Roblox allows one a day per player per game)
function Social.feedback()
	task.spawn(function()
		local ok = pcall(function()
			(SocialService :: any):PromptFeedbackSubmissionAsync()
		end)
		if not ok and ctx.Notice then
			ctx.Notice.show({ Title = "Feedback", Body = "Feedback isn't available right now. Try again later.", Button = "OK" })
		end
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
		Text = isInvite and (Social.bonus() > 0 and ("Invite  ·  +" .. Social.bonus() .. " coins") or "Invite friends") or (isRemind and "🔔 Remind me" or "Favorite"),
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

function Social.start()
	if ctx.Mode == "Lobby" then
		ProximityPromptService.PromptTriggered:Connect(function(prompt)
			if prompt.Name == "FeedbackPrompt" then
				Social.feedback()
			end
		end)
	end
end

-- (v121) the lobby: a small INVITE icon in the dock (a friend who joins pays you both). Called by
-- LobbyHub, once the dock is up.
function Social.dockIcon()
	if ctx.Mode == "Lobby" and ctx.Dock then
		-- (no pulsing "!": the shop and rewards have those; the coins are on the invite prompt itself)
		local b = ctx.Dock.add({ Order = 6, Glyph = "👥", Label = "INVITE", Color = Color3.fromRGB(120, 230, 150), OnClick = Social.invite })
		b.Name = "InviteDock"
	end
end

return Social
