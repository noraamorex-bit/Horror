--[[
	CaptureService — being taken, and being rescued.

	Captured players are zip-tied to the pipes in the boiler room. Friends can free them
	(hold prompt), or they can struggle free themselves (mash Space) — slow and noisy.
]]

local Capture = {}
local ctx

local slots = {} -- index -> player
local captives = {} -- player -> {Slot, Prompt, Progress, Presses}
local everCaptured = {} -- player -> true

function Capture.init(c)
	ctx = c
end

function Capture.reset()
	for p in captives do
		p:SetAttribute("Captured", nil)
		p:SetAttribute("StruggleProgress", nil)
	end
	for _, p in game:GetService("Players"):GetPlayers() do
		p:SetAttribute("Dead", nil)
	end
	slots = {}
	captives = {}
	everCaptured = {}
end

local function freeSlot(): number?
	for i = 1, #ctx.Layout.RestraintSlots do
		if not slots[i] then
			return i
		end
	end
	return nil
end

function Capture.isCaptured(player: Player): boolean
	return captives[player] ~= nil
end

function Capture.wasEverCaptured(player: Player): boolean
	return everCaptured[player] == true
end

function Capture.captiveCount(): number
	local n = 0
	for _ in captives do
		n += 1
	end
	return n
end

function Capture.captives(): { Player }
	local out = {}
	for p in captives do
		table.insert(out, p)
	end
	return out
end

function Capture.release(player: Player, by: Player?)
	if by and by ~= player then
		by:SetAttribute("NightRescues", (tonumber(by:GetAttribute("NightRescues")) or 0) + 1)
		if ctx.Badges then
			ctx.Badges.award(by, "Rescuer")
		end
	end
	local data = captives[player]
	if not data then
		return
	end
	captives[player] = nil
	slots[data.Slot] = nil
	if data.Prompt then
		data.Prompt:Destroy()
	end
	player:SetAttribute("Captured", nil)
	player:SetAttribute("StruggleProgress", nil)
	ctx.PlayerState.setFrozen(player, false)
	ctx.Audio.playAt(by and "ScissorsSnip" or "ZipTie", ctx.Layout.RestraintSlots[data.Slot].Pos, { CaptionText = "[Snip]" })
	if by then
		ctx.Audio.caption((by:GetAttribute("RoleName") or by.Name) .. " cut you free. Don't get caught again.", nil, nil, { player })
		ctx.PlayerState.addNerve(player, 25)
	else
		ctx.Audio.caption("The zip tie finally snaps! You won't get a second chance.", nil, nil, { player })
	end
	if ctx.Director then
		ctx.Director.onRescue(player, by)
	end
end

-- what the others hear when he takes someone: a heavy thud, a scream cut short
function Capture.takenSounds(player: Player)
	local root = ctx.Util.getRoot(player)
	if not root then
		return
	end
	local at = root.Position
	local others = {}
	for _, p in ctx.Util.sessionPlayers() do
		if p ~= player then
			table.insert(others, p)
		end
	end
	task.delay(0.5, function()
		ctx.Audio.playAt("MuffledScream", at, { Only = others })
		ctx.Audio.playAt("BodyFall", at, { Caption = false })
	end)
end

-- Caught a second time: no zip ties. He doesn't make the same mistake twice.
-- The player is out of the night and watches the others (client Spectate).
function Capture.kill(player: Player): boolean
	if player:GetAttribute("Dead") or player:GetAttribute("Escaped") or player:GetAttribute("AdminGod") then
		return false
	end
	if ctx.Hiding.spotOf(player) then
		ctx.Hiding.exit(player, true)
	end
	ctx.Util.unseat(player)
	ctx.PlayerState.setFlashlight(player, false)
	player:SetAttribute("NightCaught", (tonumber(player:GetAttribute("NightCaught")) or 0) + 1)
	if ctx.Inventory.take(player, "CarKeys") then
		ctx.Escape.returnCarKeysToNest()
	end
	player:SetAttribute("Dead", true)
	player:SetAttribute("Captured", true)
	player:SetAttribute("StruggleProgress", nil)
	local head = ctx.Intruder and ctx.Intruder.getHead and ctx.Intruder.getHead()
	local scareTime = 0
	if head and head.Parent then
		ctx.Remotes.Jumpscare:FireClient(player, head)
		scareTime = 0.9
	end
	Capture.takenSounds(player)
	task.delay(scareTime, function()
		ctx.Remotes.Fade:FireClient(player, true, 0.3)
		ctx.Remotes.Shake:FireClient(player, 1.2, 0.6)
		ctx.Audio.caption("He doesn't bother with zip ties this time.", nil, nil, { player })
	end)
	task.delay(1.6 + scareTime, function()
		-- the body is gone from the house; you watch your friends from here on
		local char = player.Character
		if char and player:GetAttribute("Dead") then -- (unless they've been revived already)
			ctx.PlayerState.setFrozen(player, true)
			char:PivotTo(CFrame.new(220, -60, 220))
		end
		ctx.Remotes.Fade:FireClient(player, false, 2)
	end)
	for _, other in ctx.Util.sessionPlayers() do
		if other ~= player then
			ctx.PlayerState.addNerve(other, -ctx.Config.Nerve.FriendCaptured * 1.5)
			ctx.Remotes.Notify:FireClient(other, tostring(player:GetAttribute("RoleName") or player.Name) .. " is gone. Don't get caught twice.", "danger")
		end
	end
	if ctx.Director then
		ctx.Director.logTruthRaw(tostring(player:GetAttribute("RoleName") or player.Name) .. " was caught a second time. Curtis didn't take any chances.")
		ctx.Director.checkAllCaptured()
	end
	if ctx.Ending.playerDone then
		ctx.Ending.playerDone(player, "Died")
	end
	return true
end

-- back from the dead (ReviveService): a clean slate for the rest of the night
function Capture.revived(player: Player)
	player:SetAttribute("Dead", nil)
	player:SetAttribute("Captured", nil)
	player:SetAttribute("StruggleProgress", nil)
	everCaptured[player] = nil
end

function Capture.capture(player: Player)
	-- (AdminGod: the owner's "can't be caught" switch in the admin panel)
	if captives[player] or player:GetAttribute("Escaped") or player:GetAttribute("Dead") or player:GetAttribute("AdminGod") then
		return false
	end
	-- you only get away once
	if everCaptured[player] then
		return Capture.kill(player)
	end
	local slotIndex = freeSlot()
	if not slotIndex then
		slotIndex = 1
	end
	if ctx.Hiding.spotOf(player) then
		ctx.Hiding.exit(player, true)
	end
	ctx.Util.unseat(player)
	player:SetAttribute("NightCaught", (tonumber(player:GetAttribute("NightCaught")) or 0) + 1)
	ctx.PlayerState.setFlashlight(player, false)

	-- he takes what matters
	if ctx.Inventory.take(player, "CarKeys") then
		ctx.Escape.returnCarKeysToNest()
	end
	while ctx.Inventory.take(player, "PepperSpray") do
	end

	slots[slotIndex] = player
	everCaptured[player] = true
	captives[player] = { Slot = slotIndex, Progress = 0, Presses = 0 }
	player:SetAttribute("Captured", true)
	player:SetAttribute("StruggleProgress", 0)

	-- the jumpscare: his face, right there, then darkness
	local head = ctx.Intruder and ctx.Intruder.getHead and ctx.Intruder.getHead()
	local scareTime = 0
	if head and head.Parent then
		ctx.Remotes.Jumpscare:FireClient(player, head)
		scareTime = 0.9
	end
	Capture.takenSounds(player)
	task.delay(scareTime, function()
		ctx.Remotes.Fade:FireClient(player, true, 0.4)
		ctx.Remotes.Shake:FireClient(player, 1, 0.5)
		ctx.Audio.caption("A hand clamps over your mouth. Everything goes dark.", nil, nil, { player })
	end)

	task.delay(1.2 + scareTime, function()
		if not captives[player] then
			return
		end
		local slot = ctx.Layout.RestraintSlots[slotIndex]
		local char = player.Character
		if char then
			ctx.PlayerState.setFrozen(player, false)
			ctx.PlayerState.placeStanding(player, CFrame.lookAt(slot.Pos, slot.Face))
			task.wait()
			ctx.PlayerState.setFrozen(player, true)
		end
		ctx.Audio.playAt("ZipTie", slot.Pos)
		ctx.Remotes.Fade:FireClient(player, false, 2.5)
		local alone = #ctx.Util.sessionPlayers() <= 1
		local line = alone and "Your wrists are zip-tied to a pipe. Keep pressing STRUGGLE to break free."
			or "Your wrists are zip-tied to a pipe. Keep pressing STRUGGLE, or wait for your friends."
		-- a look at yourself, tied to the pipes (Cutscene); the line is its subtitle
		if ctx.Cutscene and ctx.Cutscene.tiedUp then
			ctx.Cutscene.tiedUp(player, slot, line)
		else
			ctx.Audio.caption(line, nil, nil, { player })
		end

		local root = ctx.Util.getRoot(player)
		if root then
			local prompt = ctx.Interaction.prompt(root, {
				Name = "Rescue",
				Action = "Cut free",
				Object = player:GetAttribute("RoleName") or player.Name,
				Hold = ctx.Config.Capture.RescueHold,
				Distance = 7,
			}, function(rescuer)
				if rescuer == player then
					return
				end
				Capture.release(player, rescuer)
			end)
			captives[player].Prompt = prompt
			-- Tinkerer / tools make it faster: adjust per trigger attempt
			prompt.PromptButtonHoldBegan:Connect(function(rescuer)
				-- cutting zip ties isn't quiet: he hears it from a fair way off
				local at = ctx.Layout.RestraintSlots[slotIndex].Pos
				ctx.Noise.emit(at, 25, "Rescue", rescuer)
				if ctx.Intruder and ctx.Intruder.onRescueAttempt then
					ctx.Intruder.onRescueAttempt(at, rescuer)
				end
				local fast = rescuer:GetAttribute("Role") == "Tinkerer"
					or ctx.Inventory.has(rescuer, "Multitool")
					or ctx.Inventory.has(rescuer, "Scissors")
				prompt.HoldDuration = fast and ctx.Config.Capture.RescueHoldTool or ctx.Config.Capture.RescueHold
			end)
		end
	end)

	for _, other in ctx.Util.sessionPlayers() do
		if other ~= player then
			ctx.PlayerState.addNerve(other, -ctx.Config.Nerve.FriendCaptured)
			ctx.Remotes.Notify:FireClient(other, (player:GetAttribute("RoleName") or player.Name) .. " has gone quiet.", "danger")
		end
	end

	if ctx.Director then
		ctx.Director.onCapture(player)
	end
	return true
end

function Capture.start()
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		local data = captives[p]
		if data then
			captives[p] = nil
			slots[data.Slot] = nil
			if data.Prompt then
				data.Prompt:Destroy()
			end
		end
		everCaptured[p] = nil
	end)
	ctx.Remotes.Struggle.OnServerEvent:Connect(function(player)
		local data = captives[player]
		if not data or not data.Prompt then
			return
		end
		local now = os.clock()
		if data.Last and now - data.Last < 0.08 then
			return -- rate limit
		end
		data.Last = now
		data.Presses += 1
		data.Progress += ctx.Config.Capture.StrugglePerPress
		player:SetAttribute("StruggleProgress", data.Progress / 100)
		if data.Presses % ctx.Config.Capture.StruggleNoiseEvery == 0 then
			local pos = ctx.Layout.RestraintSlots[data.Slot].Pos
			ctx.Audio.playAt("Struggle", pos)
			ctx.Noise.emit(pos, ctx.Config.Noise.Struggle, "Struggle", player)
		end
		if data.Progress >= 100 then
			Capture.release(player, nil)
		end
	end)
end

return Capture
