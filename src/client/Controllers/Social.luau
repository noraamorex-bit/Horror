--[[
	Social — the buttons that help the game spread and bring players back: invite friends
	(Roblox's invite prompt), favorite the game (Roblox's favorite prompt) and REMIND ME (Roblox's
	experience-notification opt-in: the game can then tell them when their daily reward is ready).
	All fail quietly where Roblox doesn't allow them (Studio, a player who can't send invites,
	already opted in, etc); REMIND ME only shows when Roblox says it can ask. In the lobby, the
	feedback mailbox (v123) and every result card's 📝 button (v143) open our own feedback box (v150).
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

--[[
	(v150, the owner: "Is there a way to get you to be able to see the feedback comments") our own feedback box:
	Roblox's window above only reaches Creator Hub, which nothing can read; this one goes to the server
	(FeedbackService: filtered, kept in Feedback_v1, read by tools/pull_feedback.py). Small, in the upper half (a
	phone's keyboard comes up under it), one text box, SEND; Roblox's own window is still a tap away under it.
]]
local box: Frame? = nil
local boxWhere = "Other"
local sending = false
function Social.feedbackBox(where: string?)
	boxWhere = where or "Other"
	local UI = ctx.UI
	if box then
		box.Visible = true
		return box
	end
	local panel = UI.new("Frame", {
		Name = "FeedbackBox",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.06, 0),
		Size = UDim2.new(0.92, 0, 0, 268),
		BackgroundColor3 = Color3.fromRGB(12, 12, 14),
		BackgroundTransparency = 0.04,
		ZIndex = 80,
		Parent = UI.Top,
	})
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(440, 268), Parent = panel })
	UI.corner(panel, 12)
	UI.stroke(panel, Color3.new(1, 1, 1), 1, 0.75)
	UI.modal(panel)
	UI.label({ Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -60, 0, 24), Text = "📝 FEEDBACK", Font = UI.Font.Title, TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 81, Parent = panel })
	UI.new("Frame", { Position = UDim2.fromOffset(16, 38), Size = UDim2.fromOffset(28, 2), BackgroundColor3 = UI.Color.Blood or Color3.fromRGB(170, 20, 24), BorderSizePixel = 0, ZIndex = 81, Parent = panel })
	local close = UI.new("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(30, 30), Text = "✕",
		Font = UI.Font.Bold, TextSize = 15, TextColor3 = UI.Color.Text, BackgroundColor3 = Color3.fromRGB(30, 30, 34), ZIndex = 82, Parent = panel })
	UI.corner(close, 8)
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	UI.label({ Position = UDim2.fromOffset(16, 46), Size = UDim2.new(1, -32, 0, 34), Text = "What should we fix or add? What annoyed you, what scared you? We read every one.",
		TextSize = 13, TextColor3 = UI.Color.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 81, Parent = panel })
	local input = UI.new("TextBox", {
		Name = "FeedbackText",
		Position = UDim2.fromOffset(16, 84),
		Size = UDim2.new(1, -32, 0, 96),
		Text = "",
		PlaceholderText = "Type here...",
		PlaceholderColor3 = Color3.fromRGB(120, 116, 110),
		ClearTextOnFocus = false,
		MultiLine = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = UI.Font.Body,
		TextSize = 15,
		TextColor3 = UI.Color.Text,
		BackgroundColor3 = Color3.fromRGB(6, 6, 8),
		ZIndex = 81,
		Parent = panel,
	})
	UI.corner(input, 8)
	UI.stroke(input, Color3.new(1, 1, 1), 1, 0.82)
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = input })
	local status = UI.label({ Name = "FeedbackStatus", Position = UDim2.fromOffset(16, 184), Size = UDim2.new(1, -32, 0, 18), Text = "", TextSize = 13, TextColor3 = UI.Color.Dim,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 81, Parent = panel })
	local send = UI.new("TextButton", {
		Name = "Send",
		Position = UDim2.new(0, 16, 1, -58),
		Size = UDim2.new(0.5, -22, 0, 42),
		Text = "SEND",
		Font = UI.Font.Bold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(16, 16, 16),
		BackgroundColor3 = Color3.fromRGB(240, 238, 232),
		ZIndex = 81,
		Parent = panel,
	})
	UI.corner(send, 8)
	local rate = UI.new("TextButton", {
		Name = "RateRoblox",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 1, -58),
		Size = UDim2.new(0.5, -22, 0, 42),
		Text = "⭐ Rate on Roblox",
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = UI.Color.Text,
		BackgroundColor3 = Color3.fromRGB(26, 26, 30),
		ZIndex = 81,
		Parent = panel,
	})
	UI.corner(rate, 8)
	UI.stroke(rate, Color3.new(1, 1, 1), 1, 0.8)
	rate.Activated:Connect(function()
		Social.feedback()
	end)
	local function limit()
		local max = 500
		if #input.Text > max then
			input.Text = string.sub(input.Text, 1, max)
		end
	end
	pcall(function()
		input:GetPropertyChangedSignal("Text"):Connect(limit)
	end)
	send.Activated:Connect(function()
		if sending then
			return
		end
		local text = input.Text
		if #(string.gsub(text, "%s", "")) < 3 then
			status.Text = "Type something first."
			return
		end
		sending = true
		send.Text = "..."
		status.Text = "Sending..."
		status.TextColor3 = UI.Color.Dim
		ctx.Remotes.SendFeedback:FireServer(text, boxWhere)
		task.delay(10, function()
			if sending then
				sending = false
				send.Text = "SEND"
				status.Text = "No answer. Try again in a moment."
			end
		end)
	end)
	ctx.Remotes.FeedbackResult.OnClientEvent:Connect(function(ok: boolean, msg: string)
		sending = false
		send.Text = "SEND"
		status.Text = type(msg) == "string" and msg or (ok and "✓ Sent." or "Couldn't send it.")
		status.TextColor3 = ok and Color3.fromRGB(150, 230, 150) or Color3.fromRGB(255, 150, 140)
		if ok then
			input.Text = ""
			task.delay(1.8, function()
				panel.Visible = false
				status.Text = ""
			end)
		end
	end)
	box = panel
	return panel
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
	local isFeedback = kind == "feedback"
	-- minimal: dark glass, thin outline, white text (v143: sized to its text, so four fit on a row)
	local b = UI.new("TextButton", {
		Name = isFeedback and "FeedbackButton" or nil,
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = isInvite and (Social.bonus() > 0 and ("Invite  ·  +" .. Social.bonus() .. " coins") or "Invite friends")
			or (isRemind and "🔔 Remind me" or (isFeedback and "📝 Feedback" or "Favorite")),
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
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = b })
	b.Activated:Connect(function()
		if isFeedback then
			-- (v143, the owner: "add a feedback thing in the result card"; v150: our own box, which we can read)
			Social.feedbackBox("Card")
			if ctx.Remotes and ctx.Remotes.CardFeedback then
				ctx.Remotes.CardFeedback:FireServer()
			end
		elseif isInvite then
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

-- (v124) a Roblox friend's house you can still join: a small card at the top, JOIN ▶ (LobbyServer
-- offers it from MatchService; the attribute is the friend's name)
local friendCard: Frame? = nil
local function friendHouse()
	local name = player:GetAttribute("FriendHouse")
	if type(name) ~= "string" then
		if friendCard then
			friendCard.Visible = false
		end
		return
	end
	local UI = ctx.UI
	if not friendCard then
		local inset = game:GetService("GuiService"):GetGuiInset()
		local card = UI.new("Frame", {
			Name = "FriendHouse",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, inset.Y + 10),
			Size = UDim2.fromOffset(340, 44),
			BackgroundColor3 = Color3.fromRGB(12, 12, 14),
			BackgroundTransparency = 0.15,
			ZIndex = 40,
			Parent = UI.Root,
		})
		UI.corner(card, 10)
		UI.stroke(card, Color3.new(1, 1, 1), 1, 0.75)
		UI.label({ Name = "Text", Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -124, 1, 0), Text = "", Font = UI.Font.Bold, TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 41, Parent = card })
		local join = UI.new("TextButton", {
			Name = "Join",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(100, 30),
			Text = "JOIN  ▶",
			Font = UI.Font.Bold,
			TextSize = 15,
			TextColor3 = Color3.fromRGB(20, 20, 20),
			BackgroundColor3 = Color3.fromRGB(240, 238, 232),
			ZIndex = 41,
			Parent = card,
		})
		UI.corner(join, 6)
		join.Activated:Connect(function()
			card.Visible = false
			ctx.Remotes.JoinFriend:FireServer()
		end)
		friendCard = card
	end
	local card = friendCard :: Frame
	(card:FindFirstChild("Text") :: TextLabel).Text = "👥 " .. name .. " is in a house"
	card.Visible = true
end
Social._friendHouse = friendHouse -- (tests)

function Social.start()
	if ctx.Mode == "Lobby" then
		ProximityPromptService.PromptTriggered:Connect(function(prompt)
			if prompt.Name == "FeedbackPrompt" then
				Social.feedbackBox("Lobby")
			end
		end)
		player:GetAttributeChangedSignal("FriendHouse"):Connect(friendHouse)
		friendHouse()
	end
end

-- (v121) the lobby: a small INVITE icon in the dock (a friend who joins pays you both). Called by
-- LobbyHub, once the dock is up.
function Social.dockIcon()
	if ctx.Mode == "Lobby" and ctx.Dock then
		-- (no pulsing "!": the shop and rewards have those; the coins are on the invite prompt itself)
		local b = ctx.Dock.add({ Order = ctx.Dock.Order.Invite, Glyph = "👥", Label = "INVITE", Color = Color3.fromRGB(120, 230, 150), OnClick = Social.invite })
		b.Name = "InviteDock"
	end
end

return Social
