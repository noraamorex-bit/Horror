--[[
	PhoneService — everyone's cell phone.

	• Texts arrive over Wi-Fi (Story.Texts), and stop when the power (router) dies.
	• Cell calls to 911: only possible from Act III onward, only with signal, and the
	  call takes CellCallDuration seconds of holding while standing in signal. Talking is noisy.
]]

local Phone = {}
local ctx

local inbox = {} -- player -> list of {From, Body, Time}
local calling = {} -- player -> progress seconds
local delivered = {} -- key -> true
local lastText = 0
local lineShown = {} -- player -> how many dispatcher lines they've seen this call

function Phone.init(c)
	ctx = c
end

function Phone.reset()
	for p in inbox do
		ctx.Remotes.Texts:FireClient(p, {})
	end
	inbox = {}
	calling = {}
	delivered = {}
	lastText = 0
	lineShown = {}
end

function Phone.deliver(player: Player, from: string, body: string)
	inbox[player] = inbox[player] or {}
	table.insert(inbox[player], { From = from, Body = body, Time = ctx.Director and ctx.Director.clockString() or "" })
	ctx.Remotes.Texts:FireClient(player, inbox[player])
	ctx.Remotes.Notify:FireClient(player, from .. ": " .. body:split("\n")[1], "text")
	ctx.Audio.playFor(player, "PhoneVibrate")
end

-- Called by the Director every second with the current act and act time. A text that is due
-- waits for a quiet moment (quiet = nothing being thought or said), one text at a time.
function Phone.update(act: string, actTime: number, quiet: boolean?)
	local texts = ctx.Story.Texts[act]
	if not texts or quiet == false or os.clock() - lastText < 8 then
		return
	end
	for i, t in texts do
		local key = act .. i
		if not delivered[key] and actTime >= t.At * ctx.Config.TimeScale then
			delivered[key] = true
			local sent = false
			if ctx.Power.isOn() then -- Wi-Fi needs power
				for _, p in ctx.Util.sessionPlayers() do
					if not t.Role or p:GetAttribute("Role") == t.Role then
						Phone.deliver(p, t.From, t.Body)
						sent = true
					end
				end
			end
			if sent then
				lastText = os.clock()
				return
			end
		end
	end
end

local function canCall911(): boolean
	local act = ctx.Director and ctx.Director.getAct()
	return act == "SomeoneElse" or act == "Guest"
end

function Phone.start()
	ctx.Remotes.Phone.OnServerEvent:Connect(function(player, action)
		if not player:GetAttribute("InGame") or player:GetAttribute("Captured") then
			return
		end
		if action == "CallStart" then
			if not canCall911() then
				ctx.Audio.caption(ctx.Story.Calls.NotYet[1], nil, nil, { player })
				return
			end
			if ctx.Escape.helpCalled() then
				ctx.Audio.caption("Help is already on the way.", nil, nil, { player })
				return
			end
			if (player:GetAttribute("Signal") or 0) <= 0 then
				ctx.Audio.caption("No Service. The call won't connect.", nil, nil, { player })
				return
			end
			calling[player] = calling[player] or 0
			player:SetAttribute("Calling", true)
		elseif action == "CallStop" then
			player:SetAttribute("Calling", nil)
		end
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(p)
		calling[p] = nil
		lineShown[p] = nil
		inbox[p] = nil
	end)
	task.spawn(function()
		while true do
			local dt = task.wait(0.25)
			for player, progress in calling do
				if not player.Parent or not player:GetAttribute("Calling") then
					continue
				end
				if player:GetAttribute("Captured") or (player:GetAttribute("Signal") or 0) <= 0 then
					player:SetAttribute("Calling", nil)
					ctx.Audio.caption("Call dropped - you lost the signal.", nil, nil, { player })
					continue
				end
				progress += dt
				calling[player] = progress
				local total = ctx.Config.Help.CellCallDuration
				player:SetAttribute("CallProgress", progress / total)
				-- talking is noisy
				local root = ctx.Util.getRoot(player)
				if root and math.floor(progress * 4) % 8 == 0 then
					ctx.Noise.emit(root.Position, ctx.Config.Noise.PhoneCall, "Voice", player)
				end
				-- dispatcher lines as captions
				local lines = ctx.Story.Calls.Dispatch
				local idx = math.clamp(math.floor(progress / total * #lines) + 1, 1, #lines)
				lineShown[player] = lineShown[player] or 0
				if idx > lineShown[player] then
					lineShown[player] = idx
					ctx.Audio.caption(lines[idx], nil, nil, { player })
				end
				if progress >= total then
					calling[player] = nil
					lineShown[player] = nil
					player:SetAttribute("Calling", nil)
					player:SetAttribute("CallProgress", nil)
					ctx.Escape.callForHelp("Cell", player)
				end
			end
		end
	end)
end

return Phone
