local H = require("./env")
local ok, err = pcall(function()
	local ctx: any = {}
	ctx.Config = H.load("RS/Shared/Config")
	ctx.Rooms = H.load("RS/Shared/Rooms")
	ctx.Sounds = H.load("RS/Shared/Sounds")
	ctx.Story = H.load("RS/Shared/Story")
	ctx.Util = H.load("RS/Shared/Util")
	ctx.Builder = H.load("Server/World/Builder")
	ctx.Layout = H.load("Server/World/Layout")
	local lines = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { FireClient = function(_, _, payload) if k == "Dialogue" then table.insert(lines, payload or false) end end, FireAllClients = function() end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
	H.services.TweenService.Create = function() return { Play = function() end, Cancel = function() end, Completed = { Wait = function() end, Connect = function() end } } end
	local ORDER = { "Audio=AudioService", "Noise=NoiseService", "Interaction=InteractionService", "Inventory=InventoryService", "Power=PowerService", "Doors=DoorService", "PlayerState=PlayerStateService", "Hiding=HidingService", "Capture=CaptureService", "Objectives=ObjectiveService", "Dialogue=DialogueService", "Phone=PhoneService", "Escape=EscapeService", "Chat=ChatService", "Ending=EndingService" }
	local names = {}
	for _, name in ORDER do
		local key, file = name:match("(%w+)=(%w+)")
		ctx[key] = H.load("Server/Services/" .. file)
		table.insert(names, key)
	end
	ctx.World = H.load("Server/World/World")
	ctx.Director = H.load("Server/Director/Director")
	ctx.Intruder = H.load("Server/Intruder/Intruder")
	for _, k in { "World", "Director", "Intruder" } do table.insert(names, k) end
	for _, k in names do if ctx[k].init then ctx[k].init(ctx) end end
	ctx.World.build()
	ctx.restart = function() print("restart called") end
	for _, k in names do if ctx[k].start then ctx[k].start() end end
	local roblox = H.roblox
	local p = H.wrap(roblox.Instance.new("Player"))
	p.Name = "Tester"
	local char = H.Instance.new("Model")
	local rootPart = H.Instance.new("Part", char)
	rootPart.Name = "HumanoidRootPart"
	rawset(p, "Character", char)
	rawset(p, "Parent", H.workspaceRoot)
	H.services.Players.GetPlayers = function() return { p } end
	p:SetAttribute("InGame", true)
	p:SetAttribute("Role", "Host")
	ctx.Director.startAct("Evening")
	ctx.Objectives.set({ "OrderPizza" })
	local Delivery = H.load("Server/Director/Delivery")
	local done = false
	local co = coroutine.create(function()
		Delivery.run(ctx, ctx.Director, function() done = true end)
	end)
	H.ours[co] = true
	local world = H.unwrap(ctx.World.folder())
	local answered, choicesMade = false, 0
	local lastChoiceLine = 0
	for i = 1, 20000 do
		if coroutine.status(co) == "dead" then break end
		local ok, err = coroutine.resume(co)
		if not ok then error("delivery: " .. tostring(err)) end
		if not answered then
			for _, d in world:GetDescendants() do
				if d:IsA("ProximityPrompt") and d.ActionText == "Answer the door" then
					local prox = H.wrap(d)
					local sigs = rawget(prox, "__signals")
					if sigs and sigs.Triggered then
						sigs.Triggered:Fire(p)
						answered = true
						print("answered the door at step", i)
					end
				end
			end
		end
		-- answer choices: always the second option
		local last = lines[#lines]
		if last and last.Choices and #lines > lastChoiceLine then
			lastChoiceLine = #lines
			choicesMade += 1
			ctx.Remotes.DialogueChoice.OnServerEvent:Fire(p, 2)
		end
		-- the dialogue's own pacing uses os.clock deadlines; let real time pass a little
		if i % 50 == 0 then
			local t = os.clock() + 0.001
			while os.clock() < t do end
		end
	end
	print("done", done, "lines", #lines, "choices", choicesMade, "door task", ctx.Objectives.isDone("Door"))
	for k, l in lines do
		if l then print(" ", l.IsPlayer and "YOU" or (l.Speaker == "" and "*" or l.Speaker), "|", l.Text, l.Choices and ("[" .. table.concat(l.Choices, " / ") .. "]") or "") else print("  <close>") end
	end
	local boxes = 0
	for _, d in world:GetDescendants() do if d.Name == "PizzaBox" then boxes += 1 end end
	print("pizza boxes", boxes)
end)
print(ok and "DELIVERY OK" or ("DELIVERY FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
