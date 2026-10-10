local H = require("./env")
local roblox = H.roblox
local touch = require("@lune/process").args[1] == "touch"
local ok, err = pcall(function()
	local S = H.services
	local player = H.wrap(roblox.Instance.new("Player"))
	player.Name = "Tester"
	local pg = H.wrap(roblox.Instance.new("PlayerGui"))
	pg.Parent = player
	S.Players.LocalPlayer = player
	S.Players.GetPlayers = function() return { player } end
	S.UserInputService = {
		TouchEnabled = touch, KeyboardEnabled = not touch, MouseBehavior = nil,
		LastInputTypeChanged = H.signal(), InputBegan = H.signal(), InputEnded = H.signal(), InputChanged = H.signal(),
		GetLastInputType = function() return touch and roblox.Enum.UserInputType.Touch or roblox.Enum.UserInputType.Keyboard end,
		GetMouseDelta = function() return roblox.Vector2.new() end,
	}
	S.GuiService = { GetGuiInset = function() return roblox.Vector2.new(0, 36), roblox.Vector2.new() end }
	S.ProximityPromptService = { PromptShown = H.signal(), PromptHidden = H.signal(), Enabled = true }
	S.SoundService = H.wrap(roblox.Instance.new("SoundService"))
	S.Lighting = H.wrap(roblox.Instance.new("Lighting"))
	S.StarterGui = { SetCoreGuiEnabled = function() end, SetCore = function() end }
	S.RunService.IsServer = function() return false end

	local ctx: any = { Player = player, Mode = "Game" }
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Rooms = H.load("RS/Shared/Rooms")
	ctx.Sounds = H.load("RS/Shared/Sounds")
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Util = H.load("RS/Shared/Util")
	ctx.CreaturePose = H.load("RS/Shared/CreaturePose")
	local sent = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { OnClientEvent = H.signal(), FireServer = function(_, ...) table.insert(sent, k) end }
		rawset(t, k, r)
		return r
	end })
	local ORDER = { "UI", "Input", "Notice", "Social", "Thoughts", "Effects", "Atmosphere", "Movement", "Prompts", "HUD", "Documents", "Phone", "HidingCam", "Lobby", "Ending", "MobileControls", "Markers", "Ambience", "Dialogue", "Spectate", "Creature", "Intro", "Vote", "Friends", "Settings", "Admin", "TVVoice", "Cutscene", "HeartbeatGame", "Puzzle", "Finale" }
	local mods = {}
	for _, n in ORDER do mods[n] = H.load("Client/Controllers/" .. n) end
	for _, n in ORDER do if mods[n].init then mods[n].init(ctx) end end
	for _, n in ORDER do
		if mods[n].start then
			local ok2, e2 = pcall(mods[n].start)
			if not ok2 then error(n .. ".start: " .. tostring(e2)) end
		end
	end
	print("controllers started (touch=" .. tostring(touch) .. ")")
	local R = ctx.Remotes
	-- the difficulty vote, the role picker, settings
	R.Vote.OnClientEvent:Fire({ Ends = os.clock() + 10, Normal = 0, Hard = 1, Total = 2 })
	S.RunService.Heartbeat:Fire(0.1)
	local top = H.unwrap(pg):FindFirstChild("HomeAloneTop")
	local vote = top and top:FindFirstChild("Vote")
	assert(vote and vote.Visible, "vote screen opens")
	player:SetAttribute("Pass_ChooseRole", true)
	R.Vote.OnClientEvent:Fire({ Result = "Hard", Normal = 0, Hard = 2, Total = 2 })
	ctx.Settings.open()
	assert(top:FindFirstChild("Settings").Visible, "settings open")
	assert(ctx.Settings.shakeOn() == true, "shake on by default") -- (attribute signals are stubs here)
	ctx.Settings.close()
	print("vote + settings ok, sent:", table.concat(sent, ","))
	R.Lobby.OnClientEvent:Fire({ Phase = "Countdown", Ready = { 1 }, ReadyCount = 1, Players = 1, Needed = 1, Countdown = 5 })
	player:SetAttribute("InGame", true)
	player:SetAttribute("Role", "Observer")
	player:SetAttribute("Item_Flashlight", 1)
	player:SetAttribute("Item_PepperSpray", 2)
	player:SetAttribute("Battery", 50)
	R.Chapter.OnClientEvent:Fire("I. Friday Night", "sub")
	ctx.Notice.show({ Title = "You are Casey Brooks", Body = "x" })
	R.Thought.OnClientEvent:Fire("Mom left me a list of chores.", "journal")
	R.Thought.OnClientEvent:Fire("A flashlight.", "light")
	print("notice open:", ctx.Notice.isOpen())
	ctx.Input.fire("Close", true)
	print("notice open after OK:", ctx.Notice.isOpen())
	R.Caption.OnClientEvent:Fire("[Footsteps]")
	R.Notify.OnClientEvent:Fire("Hello", "danger")
	R.Objectives.OnClientEvent:Fire({ { Id = "A", Text = "Make popcorn", Done = false, Steps = { { Text = "Get a bag", Done = true }, { Text = "Microwave", Done = false } }, StepsDone = 1, Current = "Microwave", Targets = { roblox.Vector3.new(1, 2, 3) } }, { Id = "B", Text = "Done thing", Done = true, Optional = true, Steps = {}, Targets = {} } })
	R.Dialogue.OnClientEvent:Fire({ Speaker = "Delivery man", Text = "Delivery for... Whitaker.", ChooserId = 1, ChooserName = "Tester" })
	R.Dialogue.OnClientEvent:Fire({ Speaker = "Delivery man", Text = "Two large.", Choices = { "That's us.", "You're not the usual guy." }, ChooserId = 1, ChooserName = "Tester", Timeout = 30 })
	print("dialogue open", ctx.Dialogue.isOpen())
	R.Dialogue.OnClientEvent:Fire({ Speaker = "Tester", IsPlayer = true, Text = "You're not the usual guy.", ChooserId = 1 })
	R.Dialogue.OnClientEvent:Fire({ Speaker = "", Text = "He smiles.", ChooserId = 2, Choices = { "a", "b" }, ChooserName = "Other" })
	R.Dialogue.OnClientEvent:Fire(nil)
	print("dialogue closed", not ctx.Dialogue.isOpen())
	R.Document.OnClientEvent:Fire("Notebook")
	R.Texts.OnClientEvent:Fire({ Messages = { { From = "Mom", Thread = "Mom", Body = "hi", Time = "8:50 PM" }, { From = "You", Thread = "Mom", Mine = true, Body = "ok" } }, Reply = { Thread = "Mom", Options = { "a", "b" } } })
	ctx.Phone.toggle(true)
	R.Texts.OnClientEvent:Fire({ Messages = {} })
	R.Lightning.OnClientEvent:Fire(1, 0)
	R.Figure.OnClientEvent:Fire(roblox.CFrame.new(), 1)
	-- the secret ending's card, through every phase (tied up and free)
	local now = os.clock()
	local card = nil
	local function cardText()
		card = card or H.unwrap(player):FindFirstChild("FinaleCard", true)
		local out = {}
		for _, d in card:GetDescendants() do
			if d:IsA("TextLabel") and d.Visible and d.Text ~= "" then table.insert(out, d.Text) end
		end
		return table.concat(out, " | ")
	end
	player:SetAttribute("FinaleTied", true)
	for _, mode in { "Back", "Warn", "Watching" } do
		R.Finale.OnClientEvent:Fire({ Phase = "Dinner", Mode = mode, Strikes = 1, Ends = now + 200, Free = 0, Total = 2 })
		print("finale dinner (tied, " .. mode .. "): " .. cardText())
	end
	player:SetAttribute("FinaleTied", nil)
	R.Finale.OnClientEvent:Fire({ Phase = "Dinner", Mode = "Back", Strikes = 0, Ends = now + 200, Free = 1, Total = 2 })
	print("finale dinner (free): " .. cardText())
	R.Finale.OnClientEvent:Fire({ Phase = "Tunnels", Ends = now + 600, Away = now + 60, Code = "4 _ _ _", Notes = { Pantry = true, Nursery = false, HisRoom = false }, Free = 2, Total = 2 })
	print("finale tunnels (he's away): " .. cardText())
	R.Finale.OnClientEvent:Fire({ Phase = "Tunnels", Ends = now + 600, Code = "4 7 1 9", Notes = { Pantry = true, Nursery = true, HisRoom = true }, Free = 2, Total = 2 })
	print("finale tunnels (code): " .. cardText())
	R.Finale.OnClientEvent:Fire({ Phase = "Out", Ends = now + 50, Code = "4 7 1 9", Hatch = 2, Barred = true, Bars = 1, Notes = { Pantry = true, Nursery = true, HisRoom = true }, Free = 2, Total = 2 })
	print("finale out: " .. cardText())
	R.Finale.OnClientEvent:Fire(nil)
	assert(not card.Visible, "the card goes away")
	R.Shake.OnClientEvent:Fire(1, 1)
	R.Fade.OnClientEvent:Fire(true, 1)
	R.PlaySound.OnClientEvent:Fire("PhoneVibrate")
	R.Ending.OnClientEvent:Fire({ Kind = "Sirens", Title = "SIRENS", Headline = "YOU SURVIVED", Good = true, Short = "x", Shots = {}, Duration = "10:00", RestartIn = 3 })
	R.Result.OnClientEvent:Fire({ Outcome = "Died", Title = "YOU DIED", Good = false, Line = "y", CanSpectate = true, ReturnToLobby = true })
	R.Result.OnClientEvent:Fire({ Outcome = "Died", Title = "YOU DIED", Good = false, Line = "y", CanRevive = true, ReviveIn = 12, CanSpectate = false, ReturnToLobby = true })
	assert(ctx.EndingUI.reviveLabel():find("25"), "revive priced on the card")
	R.Revived.OnClientEvent:Fire()
	print("revive card ok")
	-- the heartbeat minigame: opens, takes presses, closes on the result
	player:SetAttribute("Hiding", "Closet")
	R.Heartbeat.OnClientEvent:Fire({ Id = 7, Start = os.clock(), Beats = { { T = 1.2, Side = "L" }, { T = 2.2, Side = "R" } }, Travel = 0.9, Window = 0.22, Misses = 3 })
	assert(ctx.HeartbeatUI.isActive(), "heartbeat game open")
	S.RunService.RenderStepped:Fire(0.1)
	R.Heartbeat.OnClientEvent:Fire({ Id = 7, Result = "Pass" })
	assert(not ctx.HeartbeatUI.isActive(), "heartbeat game closed")
	player:SetAttribute("Hiding", nil)
	print("heartbeat ui ok")
	-- a prompt appears
	local part = H.Instance.new("Part")
	local prompt = H.Instance.new("ProximityPrompt", part)
	prompt.Style = roblox.Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Open"
	S.ProximityPromptService.PromptShown:Fire(prompt, touch and roblox.Enum.ProximityPromptInputType.Touch or roblox.Enum.ProximityPromptInputType.Keyboard)
	-- input actions
	for _, a in { "Sprint", "Crouch", "Flashlight", "Spray", "Journal", "Phone", "Close" } do
		ctx.Input.fire(a, true)
		ctx.Input.fire(a, false)
	end
	for _, fn in H.renderSteps do fn(0.016) end
	S.RunService.RenderStepped:Fire(0.2)
	local function dumpTouch(label)
		S.RunService.RenderStepped:Fire(3)
		local g = H.unwrap(pg):FindFirstChild("HomeAloneTouch")
		local vis = {}
		for _, b in g:GetChildren() do
			if b:IsA("TextButton") and b.Visible then
				table.insert(vis, b.Name .. "@" .. tostring(b.Position))
			end
		end
		print(label, "touch gui enabled:", g.Enabled, table.concat(vis, " | "))
	end
	dumpTouch("explore")
	player:SetAttribute("Hiding", "Closet")
	player:SetAttribute("HideView", roblox.CFrame.new())
	S.RunService.RenderStepped:Fire(0.2)
	dumpTouch("hiding")
	player:SetAttribute("Hiding", nil)
	player:SetAttribute("Captured", true)
	S.RunService.RenderStepped:Fire(0.2)
	dumpTouch("captured")
	do
		local Builder = H.load("Server/World/Builder")
		local Rig = H.load("Server/Intruder/Rig")
		local curtis = Rig.build(Builder)
		curtis.Parent = H.workspaceRoot
		H.camera = { CFrame = H.roblox.CFrame.new(0, 5, -20) }
		local ok3, e3 = pcall(function()
			for _, gait in { "Idle", "Walk", "Chase", "Reach", "Stunned", "Search" } do
				curtis:SetAttribute("Gait", gait)
				for _ = 1, 3 do S.RunService.Stepped:Fire(0, 0.1) end
			end
			S.RunService.Stepped:Fire(0, 2) -- lookClock refresh
			for _ = 1, 3 do S.RunService.Stepped:Fire(0, 0.1) end
		end)
		H.camera = nil
		local neck = H.unwrap(curtis):FindFirstChild("Neck", true)
		print("creature anim ok", ok3, e3, "animated", _G.ANIMATED, "neck", neck ~= nil, "errors so far", #H.errors)
	end
	print("remotes sent:", table.concat(sent, ","))
	-- count UI objects
	local n = 0
	for _ in H.unwrap(pg):GetDescendants() do n += 1 end
	print("gui objects", n)
end)
print(ok and "CLIENT OK" or ("CLIENT FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
