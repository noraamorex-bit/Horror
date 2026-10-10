--[[
	PuzzleService — the small hands-on puzzles at the electrics (client: Puzzle).

	"Wires"     the phone junction box: the cut pair is 4 coloured wires (3 for the Tinkerer);
	            the ends on the far side are in a different order. Join each wire to its colour.
	"Breakers"  the breaker panel after the power's gone: a few circuits have tripped. Reset them,
	            then throw the MAIN. Flip a good one by mistake and it needs resetting too; throw
	            the MAIN with anything still off and it just clunks.
	"Code"      a keypad lock (the secret ending's cellar hatch): type the digits. The answer stays
	            on the server (the client only gets the length); a wrong code buzzes, loud.

	It isn't safe while you're at it: every slip (a wrong wire, a dead MAIN) sparks or clunks, and
	he hears it. The server deals each puzzle and checks the answer (the breaker taps are replayed);
	you have to stay at the box.

		Puzzle.open(player, kind, part, data, onSolved, clientData?)   -- data: from Puzzle.wires(n) / Puzzle.breakers() / Puzzle.code(s)
		Puzzle.close(player)
		Puzzle.isOpen(player)
]]

local Players = game:GetService("Players")

local Puzzle = {}
local ctx
local sessions: { [Player]: any } = {}
local seq = 0
local REACH = 10 -- studs from the box: walk away and the puzzle closes

Puzzle.Colors = { "Red", "Blue", "Yellow", "Green" }
Puzzle.Circuits = { "KITCHEN", "LIVING RM", "HALL", "BEDROOMS", "BATHS", "GARAGE", "BASEMENT", "PORCH" }

function Puzzle.init(c)
	ctx = c
	ctx.Puzzle = Puzzle
end

local function shuffle(t)
	for i = #t, 2, -1 do
		local j = math.random(1, i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

-- n wires: the left side in one order, the right side in another (never the same)
function Puzzle.wires(n: number)
	local left = shuffle(table.clone(Puzzle.Colors))
	while #left > n do
		table.remove(left)
	end
	local right = table.clone(left)
	repeat
		shuffle(right)
		local same = true
		for i = 1, n do
			if right[i] ~= left[i] then
				same = false
			end
		end
	until not same
	return { Left = left, Right = right }
end

-- 3 tripped circuits out of 8
function Puzzle.breakers(tripped: number?)
	local idx = {}
	for i = 1, #Puzzle.Circuits do
		table.insert(idx, i)
	end
	shuffle(idx)
	local out = {}
	for i = 1, (tripped or 3) do
		table.insert(out, idx[i])
	end
	table.sort(out)
	return { Labels = Puzzle.Circuits, Tripped = out }
end

-- a keypad code (the answer never goes to the client: open with clientData = { Len })
function Puzzle.code(answer: string)
	return { Answer = answer, Len = #answer }
end

function Puzzle.isOpen(player: Player): boolean
	return sessions[player] ~= nil
end

function Puzzle.close(player: Player, result: string?)
	local s = sessions[player]
	if not s then
		return
	end
	sessions[player] = nil
	if player.Parent then
		ctx.Remotes.Puzzle:FireClient(player, { Id = s.Id, Result = result or "Closed" })
	end
end

function Puzzle.open(player: Player, kind: string, part: BasePart, data, onSolved: (Player) -> (), clientData: any?)
	Puzzle.close(player)
	seq += 1
	local s = { Id = seq, Kind = kind, Part = part, Data = data, OnSolved = onSolved, LastSlip = 0 }
	sessions[player] = s
	ctx.Remotes.Puzzle:FireClient(player, { Id = s.Id, Kind = kind, Data = clientData or data })
	return s
end

-- is this answer right? (Wires: the right-hand index each left wire went to; Breakers: every tap, in
-- order, 0 = MAIN)
function Puzzle.check(kind: string, data, answer): boolean
	if kind == "Code" then
		return type(answer) == "string" and answer == data.Answer
	end
	if type(answer) ~= "table" then
		return false
	end
	if kind == "Wires" then
		local n = #data.Left
		if #answer ~= n then
			return false
		end
		local used = {}
		for i = 1, n do
			local j = answer[i]
			if type(j) ~= "number" or used[j] or data.Right[j] ~= data.Left[i] then
				return false
			end
			used[j] = true
		end
		return true
	elseif kind == "Breakers" then
		local on = {}
		for i = 1, #data.Labels do
			on[i] = not table.find(data.Tripped, i)
		end
		if #answer > 200 then
			return false
		end
		for k, tap in answer do
			if type(tap) ~= "number" or tap % 1 ~= 0 or tap < 0 or tap > #data.Labels then
				return false
			end
			if tap == 0 then
				local all = true
				for i = 1, #on do
					all = all and on[i]
				end
				if all then
					return k == #answer -- (the MAIN, with everything on, is the last tap)
				end
			else
				on[tap] = not on[tap]
			end
		end
		return false
	end
	return false
end

local function slip(player: Player, s)
	local now = os.clock()
	if now - s.LastSlip < 0.6 then
		return
	end
	s.LastSlip = now
	local at = s.Part.Position
	if s.Kind == "Wires" then
		ctx.Audio.playAt("BreakerClick", at, { Caption = false, Pitch = 1.6 })
		ctx.Audio.caption("[A crackle of sparks]", at, 30)
		ctx.Noise.emit(at, 22, "Spark", player)
	elseif s.Kind == "Code" then
		ctx.Audio.playAt("Breaker", at, { Volume = 0.8, Pitch = 1.8, Caption = false })
		ctx.Audio.caption(ctx.Story.Finale and ctx.Story.Finale.WrongCode or "[The lock buzzes]", at, 40)
		ctx.Noise.emit(at, 45, "Buzz", player)
	else
		ctx.Audio.playAt("Breaker", at, { Volume = 0.7 })
		ctx.Noise.emit(at, 30, "Breaker", player)
	end
	ctx.Remotes.Shake:FireClient(player, 0.25, 0.2)
end

function Puzzle.start()
	ctx.Remotes.PuzzleInput.OnServerEvent:Connect(function(player, id, action, payload)
		local s = sessions[player]
		if not s or id ~= s.Id or type(action) ~= "string" then
			return
		end
		local root = ctx.Util.getRoot(player)
		local away = not root or (root.Position - s.Part.Position).Magnitude > REACH
		if away or player:GetAttribute("Captured") or player:GetAttribute("Hiding") or player:GetAttribute("Dead") then
			Puzzle.close(player, "Closed")
			return
		end
		if action == "Cancel" then
			Puzzle.close(player, "Closed")
		elseif action == "Slip" then
			slip(player, s)
		elseif action == "Click" then
			ctx.Audio.playAt("BreakerClick", s.Part.Position, { Caption = false, Volume = 0.5 })
		elseif action == "Submit" then
			if Puzzle.check(s.Kind, s.Data, payload) then
				Puzzle.close(player, "Solved")
				task.spawn(s.OnSolved, player)
				if ctx.Economy then
					ctx.Economy.track(player, "Puzzles", 1)
				end
			else
				slip(player, s)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		sessions[p] = nil
	end)
	-- caught, hidden or gone while at it: the puzzle closes
	task.spawn(function()
		while true do
			task.wait(0.5)
			for p, s in sessions do
				local root = ctx.Util.getRoot(p)
				if not p.Parent or p:GetAttribute("Captured") or p:GetAttribute("Dead") or not root
					or (root.Position - s.Part.Position).Magnitude > REACH then
					Puzzle.close(p, "Closed")
				end
			end
		end
	end)
end

function Puzzle.reset()
	for p in sessions do
		Puzzle.close(p, "Closed")
	end
	sessions = {}
end

return Puzzle
