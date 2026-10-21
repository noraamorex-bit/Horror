-- dialogue_test (v106): anyone listening can answer; the first click moves it on and that player
-- says the line; later clicks, and clicks from someone who isn't there, do nothing.
local H = require("./env")
local ok, err = pcall(function()
	local R = H.roblox
	local ctx: any = {}
	local sent = {}
	local choice = H.signal()
	ctx.Remotes = {
		Dialogue = { FireClient = function(_, p, line) table.insert(sent, { p, line }) end },
		DialogueChoice = { OnServerEvent = choice },
	}
	local D = H.load("Server/Services/DialogueService")
	D.init(ctx)
	D.start()
	local function mk(name, id)
		local p = H.wrap(R.Instance.new("Player"))
		p.Name = name
		rawset(p, "UserId", id)
		rawset(p, "DisplayName", name)
		rawset(p, "Parent", H.workspaceRoot)
		return p
	end
	local a, b, c = mk("Alex", 1), mk("Bo", 2), mk("Cy", 3)
	local script = {
		Start = "Hi",
		Nodes = {
			Hi = { Speaker = "Delivery man", Lines = { "Nice house." }, Choices = { { Say = "Thanks.", Next = "A" }, { Say = "Who are you?", Next = "B" } } },
			A = { Speaker = "Delivery man", Lines = { "Enjoy." }, End = true },
			B = { Speaker = "Delivery man", Lines = { "Just the pizza guy." }, End = true },
		},
	}
	local path = nil
	local co = coroutine.create(function()
		path = D.run({ Script = script, Chooser = a, Audience = { a, b } })
	end)
	H.ours[co] = true
	local clicked = false
	for i = 1, 20000 do
		if coroutine.status(co) == "dead" then break end
		assert(coroutine.resume(co))
		local last = sent[#sent]
		if not clicked and last and last[2] and last[2].Choices then
			assert(last[2].Anyone == true, "everyone is told they can answer")
			choice:Fire(c, 1) -- (not in the conversation)
			choice:Fire(b, 2) -- (not the chooser, but listening: first click wins)
			choice:Fire(a, 1) -- (too late)
			clicked = true
		end
		if i % 50 == 0 then
			local t = os.clock() + 0.001
			while os.clock() < t do end
		end
	end
	assert(path and path[1] == "B", "Bo's pick moved it on: " .. tostring(path and path[1]))
	local said = nil
	for _, s in sent do
		if s[2] and s[2].IsPlayer then said = s[2] end
	end
	assert(said and said.Text == "Who are you?" and said.ChooserId == 2 and said.Speaker == "Bo", "and Bo says it")
	print("anyone can answer ok")
end)
print(ok and "DIALOGUE OK" or ("DIALOGUE FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
