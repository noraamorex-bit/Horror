--[[
	DialogueService — conversations with a character, shown in a dialogue box.

	Dialogue.run({ Script = Story.Dialogue.X, Chooser = player, Audience = { players } }) -> { choice keys }
	Blocks until the conversation ends. Only the Chooser picks lines (two options per turn);
	everyone in the Audience reads along. If the chooser doesn't pick in time, the first
	option is taken so the night keeps moving.

	Dialogue.say({ {Speaker = player, Text = "..."}, ... }, audience) -> bool
	Players talking among themselves: the same box, no choices, and it leaves the controls
	alone (Ambient). Returns false without saying anything if a conversation is running.
]]

local Players = game:GetService("Players")

local Dialogue = {}
local ctx

local CHOICE_TIMEOUT = 30

local current = nil -- { Chooser, Options, Picked }
local ambient = nil -- { Cancel } while players are talking among themselves
local lastEnded = 0

local function lineTime(text: string): number
	return 1.8 + #text * 0.042
end
Dialogue.lineTime = lineTime

local function send(audience, payload)
	for _, p in audience do
		if p.Parent then
			ctx.Remotes.Dialogue:FireClient(p, payload)
		end
	end
end

function Dialogue.isActive(): boolean
	return current ~= nil or ambient ~= nil
end

-- seconds since the last line of any conversation left the screen (0 while one is running)
function Dialogue.quietFor(): number
	if current or ambient then
		return 0
	end
	return os.clock() - lastEnded
end

function Dialogue.say(lines, audience): boolean
	if current or ambient then
		return false
	end
	local me = { Cancel = false }
	ambient = me
	for _, line in lines do
		if me.Cancel then
			break
		end
		local speaker: Player = line.Speaker
		local roleName = speaker:GetAttribute("RoleName")
		send(audience, {
			-- friends go by first name ("Riley Chen" -> "Riley")
			Speaker = type(roleName) == "string" and string.split(roleName, " ")[1] or speaker.DisplayName,
			SpeakerId = speaker.UserId,
			Text = line.Text,
			Ambient = true,
		})
		task.wait(lineTime(line.Text))
	end
	send(audience, nil)
	if ambient == me then
		ambient = nil
	end
	lastEnded = os.clock()
	return true
end

function Dialogue.run(opts)
	local script = opts.Script
	local chooser: Player = opts.Chooser
	local audience = opts.Audience or { chooser }
	local path = {}
	-- let the friends finish their sentence first
	if ambient then
		ambient.Cancel = true
		while ambient do
			task.wait(0.1)
		end
	end
	local node = script.Nodes[script.Start]
	current = { Chooser = chooser, Options = nil, Picked = nil }
	while node do
		local nextNode = nil
		for i, text in node.Lines do
			local narration = node.Speaker == "" or (node.Narrate and node.Narrate[i]) or false
			local last = i == #node.Lines
			local options = nil
			if last and node.Choices then
				options = {}
				for _, c in node.Choices do
					table.insert(options, c.Say)
				end
			end
			send(audience, {
				Speaker = narration and "" or node.Speaker,
				Text = text,
				Choices = options,
				ChooserId = chooser.UserId,
				ChooserName = chooser.DisplayName,
				Timeout = options and CHOICE_TIMEOUT or nil,
			})
			if opts.OnLine then
				task.spawn(opts.OnLine, node, i)
			end
			if options then
				current.Options = options
				current.Picked = nil
				local deadline = os.clock() + CHOICE_TIMEOUT
				while not current.Picked and not current.Cancel and os.clock() < deadline and chooser.Parent do
					task.wait(0.1)
				end
				local pick = current.Picked or 1
				current.Options = nil
				local choice = node.Choices[pick]
				table.insert(path, choice.Next)
				-- the player's own line
				send(audience, {
					Speaker = chooser.DisplayName,
					IsPlayer = true,
					Text = choice.Say,
					ChooserId = chooser.UserId,
				})
				task.wait(lineTime(choice.Say) * 0.8)
				nextNode = script.Nodes[choice.Next]
			else
				task.wait(lineTime(text))
			end
			if current.Cancel then
				break
			end
		end
		if current.Cancel then
			break
		end
		if not node.Choices then
			if node.End then
				break
			end
			nextNode = node.Next and script.Nodes[node.Next] or nil
		end
		node = nextNode
	end
	send(audience, nil)
	current = nil
	lastEnded = os.clock()
	return path
end

-- a rebuild (restart) cuts any conversation short
function Dialogue.reset()
	if current then
		current.Cancel = true
	end
	if ambient then
		ambient.Cancel = true
	end
end

function Dialogue.init(c)
	ctx = c
	ctx.Dialogue = Dialogue
end

function Dialogue.start()
	ctx.Remotes.DialogueChoice.OnServerEvent:Connect(function(player, index)
		if not current or current.Chooser ~= player or not current.Options then
			return
		end
		if type(index) == "number" and current.Options[index] then
			current.Picked = index
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		if current and current.Chooser == p then
			current.Picked = 1
		end
	end)
end

return Dialogue
