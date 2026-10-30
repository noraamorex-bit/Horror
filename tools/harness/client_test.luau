local H = require("./env")
local roblox = H.roblox
local touch = require("@lune/process").args[1] == "touch"
local ok, err = pcall(function()
	local S = H.services
	local player = H.wrap(roblox.Instance.new("Player"))
	player.Name = "Tester"
	player:SetAttribute("IsAdmin", true) -- (the owner's panel gets built too: its SHOP tab is checked below)
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
	local promptsMade = {}
	S.MarketplaceService = setmetatable({ PromptProductPurchase = function(_, _, id) table.insert(promptsMade, id) end }, { __index = function(_, k)
		if string.find(k, "Finished$") then return H.signal() end
		return function() return nil end
	end })

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
	local ORDER = { "UI", "Input", "Notice", "Social", "Thoughts", "Effects", "Atmosphere", "Dread", "Movement", "Prompts", "HUD", "Monster", "Offers", "Prank", "Starter", "Gear", "NightVision", "Documents", "Phone", "HidingCam", "Lobby", "Ending", "MobileControls", "Markers", "Acoustics", "Ambience", "Dialogue", "Spectate", "Creature", "Intro", "Vote", "Friends", "Settings", "Admin", "TVVoice", "Voices", "Cutscene", "HeartbeatGame", "Puzzle", "Finale" }
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
	-- v104 Dread: noises off are picked by weight and placed 18-34 studs away; nothing near him
	do
		local D = mods.Dread
		local RB = H.roblox
		assert(D.proximity() == 0, "he's nowhere near")
		local seen = {}
		for i = 0, 20 do
			local name = D.pick(i / 20)
			seen[name] = true
			assert(ctx.Sounds.get(name), "a real sound: " .. name)
		end
		assert(seen.HouseCreak1 and seen.DistantShriek, "the whole range gets picked")
		for _ = 1, 30 do
			local p = D.spot(RB.Vector3.new(0, 5, 0), math.random(), math.random(), math.random())
			local flat = RB.Vector3.new(p.X, 0, p.Z).Magnitude
			assert(flat >= 18 and flat <= 34.01, "18-34 studs off: " .. flat)
		end
		-- Gain: the file's loudness correction, capped at Roblox's 10
		assert(ctx.Sounds.volume("Footstep", 1.6) > 1.6 * 3, "his footsteps get their gain")
		assert(ctx.Sounds.volume("FootstepDirt1", 2) == 10, "capped at 10")
		assert(ctx.Sounds.volume("Thunder") == ctx.Sounds.get("Thunder").Volume, "no gain: as asked")
		print("dread ok")
	end
	-- the objective arrow: hidden when the "!" is on screen; at the edge pointing the way when it isn't
	do
		local M = mods.Markers
		local RB = H.roblox
		local cam = RB.CFrame.new(0, 5, 0) -- (looking down -Z)
		local vp = RB.Vector2.new(1000, 600)
		assert(M.pointerFor(cam, vp, RB.Vector3.new(0, 5, -20), true, RB.Vector3.new(500, 300, 20)) == nil, "on screen: no arrow")
		local x, y = M.pointerFor(cam, vp, RB.Vector3.new(30, 5, -1), false, RB.Vector3.new(1400, 300, 1))
		assert(x and x > 0.85 and math.abs(y - 0.5) < 0.05, "off to the right: arrow at the right edge")
		x, y = M.pointerFor(cam, vp, RB.Vector3.new(-30, 5, 2), false, RB.Vector3.new(-400, 300, -2))
		assert(x and x < 0.15, "behind, to the left: arrow at the left edge")
		x, y = M.pointerFor(cam, vp, RB.Vector3.new(0.5, 5, 20), false, RB.Vector3.new(500, 300, -20))
		assert(x and (x > 0.85 or x < 0.15) and y >= 0.24 and y <= 0.8, "straight behind: to a side, never under the panel or the controls")
		x, y = M.pointerFor(cam, vp, RB.Vector3.new(0, 60, -5), false, RB.Vector3.new(500, -900, 5))
		assert(x and y >= 0.24, "upstairs: up, but below the objective panel")
		print("objective arrow ok")
	end
	-- acoustics: room reverb, and a sound behind a wall loses its highs (eased in and out)
	do
		local A = mods.Acoustics
		local RB = H.roblox
		assert(A.reverbFor("HallBath", RB.Vector3.new()) == RB.Enum.ReverbType.Bathroom, "bathrooms ring")
		assert(A.reverbFor("Basement", RB.Vector3.new()) == RB.Enum.ReverbType.StoneRoom, "the basement is stone")
		assert(A.reverbFor(nil, RB.Vector3.new(0, 20, 0)) == RB.Enum.ReverbType.NoReverb, "outside: none")
		local part = H.Instance.new("Part", H.workspaceRoot)
		part.Position = RB.Vector3.new(0, 5, -30)
		local snd = H.Instance.new("Sound", part)
		rawset(snd, "IsPlaying", true)
		A._track(snd)
		local realCam = H.camera
		H.camera = { CFrame = RB.CFrame.new(0, 5, 0) }
		local wall = H.Instance.new("Part", H.workspaceRoot)
		H.raycast = function() return { Instance = wall, Position = RB.Vector3.new(0, 5, -10) } end
		local ok3, e3 = pcall(function()
			for _ = 1, 8 do A._update() end
		end)
		assert(ok3, "update runs: " .. tostring(e3))
		local eq = H.unwrap(snd):FindFirstChild("Occlusion")
		assert(eq and eq.HighGain < -12, "behind a wall: muffled, got " .. tostring(eq and eq.HighGain))
		H.raycast = nil
		for _ = 1, 12 do A._update() end
		assert(math.abs(eq.HighGain) < 0.5, "in the open again: clear")
		H.camera = realCam
		print("acoustics ok")
	end
	-- script errors on the device are counted for the logs (5 different at most)
	do
		local D = H.load("Client/Controllers/Diagnostics")
		D._onError("attempt to index nil", "Players.X.PlayerScripts.Client.Controllers.HUD:120: function x")
		D._onError("attempt to index nil", "Players.X.PlayerScripts.Client.Controllers.HUD:120: function x")
		for i = 1, 8 do D._onError("other " .. i, "") end
		local errs = D._errors()
		assert(#errs == 5 and errs[1].N == 2 and string.find(errs[1].M, "HUD:120", 1, true), "errors counted, capped at 5")
		print("client error log ok")
	end
	local R = ctx.Remotes
	-- the difficulty vote, the role picker, settings
	R.Vote.OnClientEvent:Fire({ Ends = os.clock() + 10, Normal = 0, Hard = 1, Total = 2 })
	S.RunService.Heartbeat:Fire(0.1)
	local top = H.unwrap(pg):FindFirstChild("HomeAloneTop")
	local vote = top and top:FindFirstChild("Vote")
	assert(vote and vote.Visible, "vote screen opens")
	-- the four roles, each with what it starts with, shown to everyone (locked without the pass)
	do
		local cards = 0
		for _, d in vote:GetDescendants() do
			if d:IsA("TextButton") and string.find(d.Text, "firecrackers", 1, true) then
				cards += 1
				assert(string.find(d.Text, "🔒", 1, true), "locked without the pass: " .. d.Text)
			end
		end
		assert(cards == 1, "Casey's card says what she starts with")
	end
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
	-- v107: a slow device goes light: a thinner storm, no dust
	do
		local ws = H.unwrap(H.workspaceRoot)
		local mistPart = ws:FindFirstChild("ClientMist")
		local mist = mistPart and mistPart:FindFirstChildWhichIsA("ParticleEmitter")
		local rain = ws:FindFirstChild("ClientRain")
		local e = rain and rain:FindFirstChildWhichIsA("ParticleEmitter", true)
		local r0 = e and e.Rate
		mods.Atmosphere.lighten()
		mods.Atmosphere.lighten() -- (once only)
		assert(mist and mist.Rate <= 3, "thinner mist: " .. tostring(mist and mist.Rate))
		assert(e and e.Rate < r0, "thinner rain")
		print("low perf mode ok")
	end
	-- v106 Voices: who sounds like what; lines and his voice never break anything (silent here)
	do
		local Vo = mods.Voices
		assert(Vo.forSpeaker("Delivery man") == "Delivery" and Vo.forSpeaker("Nobody") == "Default", "speaker voices")
		assert(Vo.forPlayer(nil) == "Default", "no player: the default voice")
		R.Dialogue.OnClientEvent:Fire({ Speaker = "Delivery man", Text = "Nice house. Big. Lots of places to be.", Choices = { "Thanks.", "Here's the money." }, ChooserId = 1, Anyone = true })
		R.Dialogue.OnClientEvent:Fire(nil)
		R.HisVoice.OnClientEvent:Fire("I can hear you breathing.", "Murmur")
		R.HisVoice.OnClientEvent:Fire("Sweetie?", { Voice = "Mom", From = H.roblox.Vector3.new(0, 18, 0), Range = 60, Caption = "[From upstairs] \"Sweetie?\"" })
		Vo.say("[A stage direction] \"Hello.\"", "Him", { Channel = "Him" })
		print("voices ok")
	end
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
	local card, todo = nil, nil
	local function cardText()
		card = card or H.unwrap(player):FindFirstChild("FinaleBar", true)
		todo = todo or H.unwrap(player):FindFirstChild("FinaleTodo", true)
		local out = {}
		for _, d in card:GetChildren() do
			if d:IsA("TextLabel") and d.Visible and d.Text ~= "" then table.insert(out, (d.Text:gsub("<[^>]+>", ""))) end
		end
		if todo.Visible then table.insert(out, "[" .. todo.Text .. "]") end
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
	do
		local asked = false
		for _ = 1, 40 do
			for _, d in H.unwrap(pg):GetDescendants() do
				if d:IsA("TextLabel") and string.find(d.Text, "on the game page", 1, true) then asked = true end
			end
			if asked then break end
			task.wait(0.1)
		end
		assert(asked, "a win asks for a like")
		print("like ask ok")
	end
	player:SetAttribute("DeathTip", "Hide before he turns the corner.")
	R.Result.OnClientEvent:Fire({ Outcome = "Died", Title = "YOU DIED", Good = false, Line = "y", CanSpectate = true, ReturnToLobby = true })
	do
		local found = false
		for _, d in H.unwrap(pg):GetDescendants() do
			if d:IsA("TextLabel") and string.find(d.Text, "Hide before he turns the corner", 1, true) and string.find(d.Text, "TIP", 1, true) then found = true end
		end
		assert(found, "the death card shows how not to die next time")
		print("death tip ok")
	end
	player:SetAttribute("DeathTip", nil)
	-- Halloween: the candy line on the card
	R.Result.OnClientEvent:Fire({ Outcome = "Escaped", Title = "YOU GOT OUT", Good = true, Line = "y", ReturnToLobby = true,
		Coins = { Total = 40, Lines = { { Text = "Played a night", Amount = 40 } }, Candy = { Tonight = 3, Total = 12, Next = "Candy Corn", NextAt = 15 } } })
	do
		local found = false
		for _, d in H.unwrap(pg):GetDescendants() do
			if d:IsA("TextLabel") and string.find(d.Text, "+3 candy tonight", 1, true) and string.find(d.Text, "Candy Corn at 15", 1, true) then found = true end
		end
		assert(found, "the card's candy line")
		print("candy line ok")
	end
	-- v98: the card's offers: the Starter Pack while it's on offer (and made on Roblox); BE HIM NEXT
	-- NIGHT when a group stays for another night
	do
		local function find(name)
			return H.unwrap(pg):FindFirstChild(name, true)
		end
		local st = ctx.Config.Shop.Starter
		local wasId = st.Id
		local wasGet = S.Players.GetPlayers
		st.Id = 0
		player:SetAttribute("StarterOffer", true)
		R.Ending.OnClientEvent:Fire({ Kind = "Sirens", Title = "SIRENS", Headline = "YOU SURVIVED", Good = true, Short = "x", Shots = {}, Duration = "10:00", RestartIn = 30, ReturnToLobby = true })
		assert(not find("StarterOffer") and not find("BeHimOffer"), "no product made yet, and alone: no offers")
		st.Id = 123
		local other = H.wrap(roblox.Instance.new("Player"))
		S.Players.GetPlayers = function() return { player, other } end
		R.Ending.OnClientEvent:Fire({ Kind = "Sirens", Title = "SIRENS", Headline = "YOU SURVIVED", Good = true, Short = "x", Shots = {}, Duration = "10:00", RestartIn = 30, ReturnToLobby = true })
		local so, bh = find("StarterOffer"), find("BeHimOffer")
		assert(so and string.find(so.Text, "R$ " .. st.Price, 1, true), "the Starter Pack on the card")
		assert(bh and string.find(bh.Text, "R$", 1, true), "BE HIM NEXT NIGHT with its price: " .. tostring(bh and bh.Text))
		-- pressed (and bought: a saved one): next night it's used as soon as it opens
		local sent = {}
		local realFire = R.MonsterAction.FireServer
		R.MonsterAction.FireServer = function(_, a) table.insert(sent, a) end
		ctx.MonsterUI.wantNext()
		assert(ctx.MonsterUI.wantsNext(), "wanted")
		player:SetAttribute("MonsterCredits", 1)
		ctx.MonsterUI._refresh()
		assert(#sent == 0, "not while the night's over")
		local ws = H.unwrap(H.workspaceRoot)
		local wasIn = player:GetAttribute("InGame")
		player:SetAttribute("InGame", true)
		ws:SetAttribute("BecomeHimOpen", true)
		ctx.MonsterUI._refresh()
		assert(sent[1] == "UseCredit", "used as soon as the next night opens it")
		player:SetAttribute("MonsterPending", true)
		ctx.MonsterUI._refresh()
		assert(not ctx.MonsterUI.wantsNext() and #sent == 1, "done once the server says yes")
		player:SetAttribute("MonsterPending", nil)
		player:SetAttribute("MonsterCredits", nil)
		ws:SetAttribute("BecomeHimOpen", nil)
		player:SetAttribute("InGame", wasIn)
		R.MonsterAction.FireServer = realFire
		-- bought it: no more Starter offer
		player:SetAttribute("StarterOffer", nil)
		S.Players.GetPlayers = wasGet
		R.Ending.OnClientEvent:Fire({ Kind = "Sirens", Title = "SIRENS", Headline = "YOU SURVIVED", Good = true, Short = "x", Shots = {}, Duration = "10:00", RestartIn = 30, ReturnToLobby = true })
		assert(not find("StarterOffer"), "once bought, it's gone")
		-- v110: 2x Coins on the card for anyone without it (never a third offer in the row)
		assert(find("DoubleCoinsOffer") and string.find(find("DoubleCoinsOffer").Text, "R$", 1, true), "2x Coins offered on the card")
		player:SetAttribute("Pass_DoubleCoins", true)
		R.Ending.OnClientEvent:Fire({ Kind = "Sirens", Title = "SIRENS", Headline = "YOU SURVIVED", Good = true, Short = "x", Shots = {}, Duration = "10:00", RestartIn = 30, ReturnToLobby = true })
		assert(not find("DoubleCoinsOffer"), "not once they have it")
		player:SetAttribute("Pass_DoubleCoins", nil)
		st.Id = wasId
		print("card offers ok")
	end
	R.Result.OnClientEvent:Fire({ Outcome = "Died", Title = "YOU DIED", Good = false, Line = "y", CanRevive = true, ReviveIn = 12, CanSpectate = false, ReturnToLobby = true })
	assert(ctx.EndingUI.reviveLabel():find(tostring(ctx.Config.Shop.Revive.Price) .. " R$", 1, true), "revive priced on the card (Config's price until the live one loads)")
	R.Revived.OnClientEvent:Fire()
	print("revive card ok")
	-- the heartbeat minigame: opens, takes presses, closes on the result
	player:SetAttribute("Hiding", "Closet")
	R.Heartbeat.OnClientEvent:Fire({ Id = 7, Start = os.clock(), Beats = { { T = 1.2, Side = "L" }, { T = 2.2, Side = "R" } }, Travel = 0.9, Window = 0.22, Misses = 3 })
	assert(ctx.HeartbeatUI.isActive(), "heartbeat game open")
	S.RunService.RenderStepped:Fire(0.1)
	R.Heartbeat.OnClientEvent:Fire({ Id = 7, Result = "Pass" })
	assert(not ctx.HeartbeatUI.isActive(), "heartbeat game closed")
	-- Normal forgives the first wrong side on a beat; the other side in time still counts
	do
		local got = {}
		local realFire = R.HeartbeatInput.FireServer
		R.HeartbeatInput.FireServer = function(_, id, i, hit) table.insert(got, { id, i, hit }) end
		R.Heartbeat.OnClientEvent:Fire({ Id = 8, Start = os.clock() - 1.0, Beats = { { T = 1.0, Side = "L" }, { T = 3.0, Side = "R" } }, Travel = 1.3, Window = 0.42, Misses = 3, Forgive = true })
		ctx.HeartbeatUI._press("R")
		assert(#got == 0, "a wrong side is forgiven once")
		ctx.HeartbeatUI._press("L")
		assert(#got == 1 and got[1][3] == true, "then the right side counts")
		R.Heartbeat.OnClientEvent:Fire({ Id = 9, Start = os.clock() - 1.0, Beats = { { T = 1.0, Side = "L" } }, Travel = 1.3, Window = 0.42, Misses = 3 })
		ctx.HeartbeatUI._press("R")
		assert(#got == 2 and got[2][3] == false, "Hard (no forgiveness): a wrong side is a miss")
		R.Heartbeat.OnClientEvent:Fire({ Id = 9, Result = "Stop" })
		R.HeartbeatInput.FireServer = realFire
	end
	player:SetAttribute("Hiding", nil)
	print("heartbeat ui ok")
	-- "Become him": the small button while it's on sale; the bar once you're him
	do
		local ws = H.unwrap(H.workspaceRoot)
		local wasIn = player:GetAttribute("InGame")
		local refresh = ctx.MonsterUI._refresh -- (the harness doesn't fire these attribute signals)
		ws:SetAttribute("BecomeHimOpen", true)
		player:SetAttribute("InGame", true)
		refresh()
		local btn = H.unwrap(pg):FindFirstChild("BecomeHim", true)
		assert(btn and btn.Visible, "BECOME HIM button shows in co-op")
		assert(string.find(btn.Text, "R$", 1, true), "with its price: " .. btn.Text)
		player:SetAttribute("MonsterCredits", 1)
		refresh()
		assert(string.find(btn.Text, "free", 1, true), "a saved one: free")
		player:SetAttribute("MonsterCredits", nil)
		player:SetAttribute("Captured", true)
		refresh()
		assert(not btn.Visible, "not while you're tied up")
		player:SetAttribute("Captured", nil)
		ws:SetAttribute("BecomeHimOpen", nil)
		refresh()
		assert(not btn.Visible, "gone when it's not on sale")
		local cr = H.Instance.new("Model", H.workspaceRoot)
		H.Instance.new("Humanoid", cr)
		R.Monster.OnClientEvent:Fire({ Active = true, Captures = 2, Model = cr })
		local bar = H.unwrap(pg):FindFirstChild("MonsterBar", true)
		assert(bar and bar.Visible, "the monster bar")
		assert(ctx.MonsterUI.isActive(), "active")
		R.Monster.OnClientEvent:Fire({ Ping = roblox.Vector3.new(1, 2, 3), Radius = 10 })
		R.Monster.OnClientEvent:Fire(nil)
		assert(not bar.Visible and not ctx.MonsterUI.isActive(), "and off again")
		cr:Destroy()
		player:SetAttribute("InGame", wasIn)
		print("become him ui ok")
	end
	-- (v115) JUMPSCARE EVERYONE: only with someone else to scare; the scare covers the screen and
	-- names who did it; the buyer is told how many they got
	do
		local wasIn = player:GetAttribute("InGame")
		player:SetAttribute("InGame", true)
		ctx.Prank._refresh()
		local btn = H.unwrap(pg):FindFirstChild("PrankOffer", true)
		assert(btn and not btn.Visible, "alone: nobody to scare")
		local other = H.wrap(roblox.Instance.new("Player"))
		local wasGet = S.Players.GetPlayers
		S.Players.GetPlayers = function() return { player, other } end
		ctx.Prank._refresh()
		assert(btn.Visible and string.find(btn.Text, "R$ 10", 1, true), "with someone else, at 10 R$: " .. btn.Text)
		ctx.Remotes.JumpscareAll.OnClientEvent:Fire("Sam", 99, 1)
		local gui = H.unwrap(pg):FindFirstChild("Prank")
		assert(gui and gui:FindFirstChildOfClass("ViewportFrame"), "the scare covers the screen")
		gui:Destroy()
		S.Players.GetPlayers = wasGet
		ctx.Prank._refresh()
		player:SetAttribute("InGame", wasIn)
		print("jumpscare everyone ok")
	end
	-- (v122) alone in a night that can take players: who was left in the lobby, then who's on the way
	do
		local ws = H.unwrap(H.workspaceRoot)
		local wasIn = player:GetAttribute("InGame")
		player:SetAttribute("InGame", true)
		ws:SetAttribute("OpenNight", "1/4")
		ws:SetAttribute("LobbyBehindNames", "Sam")
		ctx.HUD._update()
		assert(string.find(ctx.HUD._eta(), "Waiting for Sam", 1, true), "who can follow: " .. ctx.HUD._eta())
		ws:SetAttribute("OnTheirWay", 1)
		ctx.HUD._update()
		assert(string.find(ctx.HUD._eta(), "1 player on their way", 1, true), "someone's coming: " .. ctx.HUD._eta())
		for _, a in { "OpenNight", "LobbyBehindNames", "OnTheirWay" } do ws:SetAttribute(a, nil) end
		-- (v124) a friend in a lobby has been offered this house (any night they can still come into)
		ws:SetAttribute("FriendInLobby", "Bo")
		ctx.HUD._update()
		assert(string.find(ctx.HUD._eta(), "Bo is in the lobby", 1, true), "a friend can join: " .. ctx.HUD._eta())
		ws:SetAttribute("FriendComing", true)
		ctx.HUD._update()
		assert(string.find(ctx.HUD._eta(), "Bo is on the way", 1, true), "and is coming: " .. ctx.HUD._eta())
		ws:SetAttribute("FriendInLobby", nil)
		ws:SetAttribute("FriendComing", nil)
		ctx.HUD._update()
		assert(ctx.HUD._eta() == "", "gone with them")
		player:SetAttribute("InGame", wasIn)
		print("lone night hud ok")
	end
	-- (v120) the Starter Pack: a small button on the side before the hunt, and its window by itself once a
	-- visit, never while a finger is down or right after one lifts
	do
		local St = ctx.Starter
		local ws = H.unwrap(H.workspaceRoot)
		local sid = ctx.Config.Shop.Starter.Id
		ctx.Config.Shop.Starter.Id = 4242
		local wasAct, wasIn = ws:GetAttribute("Act"), player:GetAttribute("InGame")
		player:SetAttribute("InGame", true)
		player:SetAttribute("StarterOffer", true)
		ws:SetAttribute("Act", "SmallThings")
		St._refresh()
		local side = H.unwrap(pg):FindFirstChild("StarterSide", true)
		assert(side and side.Visible and string.find(side.Text, "R$ 19", 1, true), "on the side before the hunt")
		ws:SetAttribute("Act", "SomeoneElse")
		St._refresh()
		assert(not side.Visible, "not during the hunt (the rocket's place)")
		ws:SetAttribute("Act", "SmallThings")
		St._reset()
		local TOUCH = { UserInputType = roblox.Enum.UserInputType.Touch }
		S.UserInputService.InputBegan:Fire(TOUCH)
		assert(not St.auto("Card", os.clock() + 10), "a finger's down: not now")
		S.UserInputService.InputEnded:Fire(TOUCH)
		assert(not St.auto("Card", os.clock() + 0.3), "a finger just lifted: not yet")
		local n = #promptsMade
		assert(St.auto("Card", os.clock() + 5), "still for a moment: it opens")
		assert(#promptsMade == n + 1 and promptsMade[#promptsMade] == 4242 and table.find(sent, "StarterAuto"), "the window, and the server's told")
		assert(not St.auto("Card", os.clock() + 20) and #promptsMade == n + 1, "once a visit")
		St._reset()
		player:SetAttribute("StarterOffer", nil)
		assert(not St.auto("Card", os.clock() + 5) and not side.Visible, "bought: never again")
		ctx.Config.Shop.Starter.Id = sid
		ws:SetAttribute("Act", wasAct)
		player:SetAttribute("InGame", wasIn)
		St._refresh()
		print("starter pack ok")
	end
	-- the one-night rocket: a small button during the hunt, for anyone without a rocket in hand
	do
		local ws = H.unwrap(H.workspaceRoot)
		local wasAct, wasIn = ws:GetAttribute("Act"), player:GetAttribute("InGame")
		local refresh = ctx.Offers._refresh
		player:SetAttribute("InGame", true)
		ws:SetAttribute("Act", "SmallThings")
		refresh()
		local btn = H.unwrap(pg):FindFirstChild("RocketOffer", true)
		assert(btn and not btn.Visible, "not before the hunt")
		ws:SetAttribute("Act", "SomeoneElse")
		refresh()
		assert(btn.Visible and string.find(btn.Text, "R$", 1, true), "during the hunt, with its price: " .. btn.Text)
		player:SetAttribute("Item_Rocket", 1)
		refresh()
		assert(not btn.Visible, "not while you have one")
		player:SetAttribute("Item_Rocket", nil)
		ctx.Offers.rocketHit("Someone")
		player:SetAttribute("Dead", true)
		refresh()
		assert(not btn.Visible, "not once you're out")
		player:SetAttribute("Dead", nil)
		-- ➕ INVITE A FRIEND while the night can take them, with this house's code in the invite
		local inv = H.unwrap(pg):FindFirstChild("InviteOffer", true)
		assert(inv and not inv.Visible, "no invite button while the night is closed")
		ws:SetAttribute("NightCode", "abc123")
		ws:SetAttribute("InviteOpen", true)
		refresh()
		assert(inv.Visible, "invite button while friends can still come in")
		local wasMode = ctx.Mode
		ctx.Mode = "Game"
		assert(ctx.Social.inviteData() == "night:abc123", "the invite carries the night's code")
		ctx.Mode = "Lobby"
		assert(ctx.Social.inviteData() == "ref:" .. tostring(player.UserId), "from the lobby: it says who invited them (v121: coins for both)")
		assert(string.find(inv.Text, "+" .. ctx.Config.Referral.Coins, 1, true), "the invite button says what a friend is worth: " .. inv.Text)
		ctx.Mode = wasMode
		ws:SetAttribute("InviteOpen", nil)
		ws:SetAttribute("NightCode", nil)
		refresh()
		assert(not inv.Visible, "gone once the night closes")
		-- v98: he's chasing someone near you: the button says STOP HIM; far away, it doesn't
		do
			local me = H.Instance.new("Model", H.workspaceRoot)
			local myRoot = H.Instance.new("Part", me)
			myRoot.Name = "HumanoidRootPart"
			myRoot.Position = roblox.Vector3.new(0, 3, 0)
			H.unwrap(player).Character = H.unwrap(me)
			local cr = H.Instance.new("Model", H.workspaceRoot)
			local hr = H.Instance.new("Part", cr)
			hr.Name = "HumanoidRootPart"
			hr.Position = roblox.Vector3.new(40, 3, 0)
			S.CollectionService:AddTag(cr, "Creature")
			ws:SetAttribute("IntruderState", "Chase")
			ctx.Offers._chaseChanged()
			assert(btn.Visible and string.find(btn.Text, "STOP HIM", 1, true), "chased: " .. btn.Text)
			ws:SetAttribute("IntruderState", "Patrol")
			ctx.Offers._chaseChanged()
			assert(not string.find(btn.Text, "STOP HIM", 1, true), "not once he stops")
			hr.Position = roblox.Vector3.new(200, 3, 0)
			ws:SetAttribute("IntruderState", "Charge")
			ctx.Offers._chaseChanged()
			assert(not string.find(btn.Text, "STOP HIM", 1, true), "not when he's after someone far away")
			ws:SetAttribute("IntruderState", nil)
			ctx.Offers._chaseChanged()
			S.CollectionService:RemoveTag(cr, "Creature")
			cr:Destroy()
			me:Destroy() -- (the harness can't set Character back to nil)
		end
		-- v108: the night vision offer for a minute after the power goes out, unless you have the pass
		do
			local nv = H.unwrap(pg):FindFirstChild("NightVisionOffer", true)
			assert(nv and not nv.Visible, "no night vision offer before the blackout")
			ctx.Offers._offerNightVision()
			assert(nv.Visible and string.find(nv.Text, "NIGHT VISION", 1, true) and string.find(nv.Text, "R$", 1, true), "offered at the blackout: " .. nv.Text)
			player:SetAttribute("Pass_NightVision", true)
			refresh()
			assert(not nv.Visible, "not if you have it")
			player:SetAttribute("Pass_NightVision", nil)
			player:SetAttribute("NightVision", true)
			ctx.NightVision.set(true)
			assert(ctx.NightVision.isOn(), "the goggles' grade comes on")
			ctx.NightVision.set(false)
			assert(not ctx.NightVision.isOn(), "and off")
			player:SetAttribute("NightVision", nil)
			print("night vision ok")
		end
		ws:SetAttribute("Act", wasAct)
		player:SetAttribute("InGame", wasIn)
		refresh()
		-- the effects don't fall over
		R.Rocket.OnClientEvent:Fire(roblox.Vector3.new(0, 5, 0), roblox.Vector3.new(30, 5, 0), 0.25)
		R.Throw.OnClientEvent:Fire(roblox.Vector3.new(0, 5, 0), roblox.Vector3.new(10, 1, 0), 1.4)
		for _ = 1, 30 do S.RunService.Heartbeat:Fire(0.1) end
		print("rocket offer ui ok")
	end
	-- the hotbar (client Gear): shown in the night, hidden while hiding; a tool's click uses it, aimed
	do
		local wasIn = player:GetAttribute("InGame")
		player:SetAttribute("InGame", true)
		ctx.Gear._refresh()
		assert(ctx.Gear.isShown(), "the hotbar shows in the night")
		player:SetAttribute("Hiding", true)
		ctx.Gear._refresh()
		assert(not ctx.Gear.isShown(), "hidden while hiding")
		player:SetAttribute("Hiding", nil)
		ctx.Gear._refresh()
		local used = nil
		local realFire = R.UseItem.FireServer
		R.UseItem.FireServer = function(_, item, aim) used = { item, aim } end
		local t = H.Instance.new("Tool")
		t:SetAttribute("ItemId", "Taser")
		t.TextureId = "rbxassetid://2"
		ctx.Gear.use(t)
		assert(used and used[1] == "Taser", "a click on the taser asks the server to fire it")
		-- (v100) in your hand: one line above the hotbar with what's left
		local me = H.Instance.new("Model", H.workspaceRoot)
		H.unwrap(player).Character = H.unwrap(me)
		t:SetAttribute("Label", "Taser")
		t:SetAttribute("Unit", "shot")
		t:SetAttribute("Count", 3)
		t.Parent = me
		assert(ctx.Gear.heldLine() == "TASER  ·  3 SHOTS", "held line: " .. tostring(ctx.Gear.heldLine()))
		t:SetAttribute("Count", 1)
		assert(ctx.Gear.heldLine() == "TASER  ·  LAST SHOT", "the last one")
		t:SetAttribute("ItemId", "NightVision")
		t:SetAttribute("Label", "Night vision")
		t:SetAttribute("Unit", nil)
		t:SetAttribute("Count", nil)
		player:SetAttribute("NVLeft", 41.3)
		assert(ctx.Gear.heldLine() == "NIGHT VISION  ·  42 S", "goggles' charge: " .. tostring(ctx.Gear.heldLine()))
		player:SetAttribute("NVLeft", 0)
		assert(ctx.Gear.heldLine() == "NIGHT VISION  ·  NO CHARGE", "out of charge")
		player:SetAttribute("NVLeft", nil)
		t:SetAttribute("ItemId", "Taser")
		ctx.Gear._refresh()
		local box = H.unwrap(pg):FindFirstChild("HeldItem", true)
		assert(box and box.Visible, "shown above the hotbar")
		-- (v109) our own hotbar: every item gets a slot (Roblox's showed 3 on a phone), in the bar's
		-- order, the one in your hand outlined, with what's left on it
		do
			local bp = H.Instance.new("Backpack")
			bp.Parent = player
			local made = {}
			for _, id in { "Firecracker", "NightVision", "Rocket", "Flashlight", "EnergyDrink", "PepperSpray" } do
				local x = H.Instance.new("Tool")
				x.Name = id
				x:SetAttribute("ItemId", id)
				x:SetAttribute("Count", id == "Firecracker" and 2 or nil)
				x.TextureId = "rbxassetid://1"
				x.Parent = bp
				table.insert(made, x)
			end
			player:SetAttribute("NVLeft", 60)
			ctx.Gear._refresh()
			local list = ctx.Gear._tools()
			assert(#list == 7, "all seven items: " .. #list)
			local want = { "Flashlight", "Taser", "PepperSpray", "Rocket", "EnergyDrink", "Firecracker", "NightVision" }
			for i, x in list do
				assert(x:GetAttribute("ItemId") == want[i], "the bar's order: " .. i .. " " .. tostring(x:GetAttribute("ItemId")))
			end
			local bar = ctx.Gear._bar()
			assert(bar and bar.Visible, "the hotbar is drawn")
			local shownSlots = 0
			for _, c in bar:GetChildren() do
				if c:IsA("ImageButton") and c.Visible then
					shownSlots += 1
				end
			end
			assert(shownSlots == 7, "a slot for every item, not 3: " .. shownSlots)
			local s2 = bar:FindFirstChild("Slot2")
			assert(s2:FindFirstChildOfClass("UIStroke").Thickness == 2, "the taser in your hand is outlined")
			assert(bar:FindFirstChild("Slot1"):FindFirstChildOfClass("UIStroke").Thickness == 1, "the others aren't")
			assert(bar:FindFirstChild("Slot6"):FindFirstChild("Count").Text == "x2", "firecrackers left: x2")
			assert(bar:FindFirstChild("Slot7"):FindFirstChild("Count").Text == "60s", "the goggles' charge")
			assert(s2:FindFirstChild("Icon").Image ~= nil, "each slot has its picture")
			player:SetAttribute("Hiding", true)
			ctx.Gear._refresh()
			assert(not bar.Visible, "hidden while hiding")
			player:SetAttribute("Hiding", nil)
			for _, x in made do x:Destroy() end
			ctx.Gear._refresh()
			assert(#ctx.Gear._tools() == 1, "the slots go with the items")
			player:SetAttribute("NVLeft", nil)
			print("custom hotbar ok")
		end
		t.Parent = nil
		ctx.Gear._refresh()
		assert(not box.Visible, "gone when nothing's in your hand")
		R.UseItem.FireServer = realFire
		player:SetAttribute("InGame", wasIn)
		ctx.Gear._refresh()
		print("hotbar ok")
	end
	-- the owner's panel: a SHOP tab with every pass, the paid gear and become him
	do
		local function click(inst)
			local w = H.wrap(inst)
			local sigs = rawget(w, "__signals")
			assert(sigs and sigs.Activated, "clickable: " .. inst.Name)
			sigs.Activated:Fire()
		end
		local pill = H.unwrap(pg):FindFirstChild("AdminPill", true)
		assert(pill, "the admin pill (owner)")
		click(pill)
		local panel = H.unwrap(pg):FindFirstChild("AdminPanel", true)
		assert(panel and panel.Visible, "the panel opens")
		local shopTab = nil
		for _, d in panel:GetDescendants() do
			if d:IsA("TextButton") and d.Text == "SHOP" then shopTab = d end
		end
		assert(shopTab, "a SHOP tab")
		click(shopTab)
		local texts = {}
		for _, d in panel:GetDescendants() do
			if d:IsA("TextButton") then table.insert(texts, d.Text) end
		end
		local all = table.concat(texts, " | ")
		for _, want in { "Rocket Launcher", "VIP", "Taser", "Pick your role", "Rocket launcher ×2", "Energy drink", "Firecracker", "Become him" } do
			assert(string.find(all, want, 1, true), "the SHOP tab lists " .. want)
		end
		print("admin shop tab ok")
	end
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
