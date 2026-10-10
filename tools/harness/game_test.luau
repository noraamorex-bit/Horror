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
	ctx.Remotes = setmetatable({}, { __index = function() return { FireClient = function() end, FireAllClients = function() end, OnServerEvent = H.signal() } end })
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
	print("started")
	for _, act in { "Evening", "SmallThings", "SomeoneElse", "Guest" } do
		ctx.Director.startAct(act)
		print("act", ctx.Director.getAct(), "intruder", ctx.Intruder.getState())
	end
	-- every event's conditions
	local Events = H.load("Server/Director/Events")
	for _, e in Events.List do
		local ok1, e1 = pcall(e.Cond, ctx, ctx.Director)
		if not ok1 then print("COND FAIL", e.Id, e1) end
		if e.Force then
			local ok2, e2 = pcall(e.Force, ctx, ctx.Director)
			if not ok2 then print("FORCE FAIL", e.Id, e2) end
		end
	end
	-- runnable events without data
	for _, id in { "FootstepsUpstairs", "DogBark", "TVAlert", "Flicker", "CordSwing", "SilentCall", "LightUpstairs" } do
		for _, e in Events.List do
			if e.Id == id then
				local okr, er = pcall(e.Run, ctx, ctx.Director, true)
				print("run", id, okr, er)
			end
		end
	end
	do
		local R = H.roblox
		local p1 = ctx.Util.sessionPlayers()[1]
		local data = {
			WindSlam = ctx.Doors.get("Lily"),
			PlateCrash = R.Vector3.new(-16.5, 1, 22.6),
			CeilingThud = { Player = p1, Pos = R.Vector3.new(0, 28.8, 0) },
			WindowBang = { Player = p1, Watch = ctx.Layout.WindowWatch[1] },
			DoorRattle = ctx.Doors.get("FrontDoor"),
			ChairDrop = ctx.Rooms.ByName.Den,
			MusicBox = ctx.World.folder():FindFirstChild("MusicBox", true),
			ShowerRan = ctx.World.folder():FindFirstChild("ShowerHead", true),
			BackDoorOpen = ctx.Doors.get("BackDoor"),
			WallKnock = { Player = p1, Pos = R.Vector3.new(-39.6, 18, 20) },
		}
		for id, d in data do
			for _, e in Events.List do
				if e.Id == id then
					local okr, er = pcall(e.Run, ctx, ctx.Director, d)
					print("scare", id, okr, er)
				end
			end
		end
	end
	local hb = H.services.RunService.Heartbeat
	for i = 1, 40 do
		hb:Fire(0.1)
		task_clock = i
	end
	print("after ticks intruder", ctx.Intruder.getState())
	ctx.Intruder.onPepperSpray(nil :: any)
	print("trap", ctx.Intruder.trap(), "inBasement", ctx.Intruder.isInBasement())
	ctx.Director.logTruth("WarmMug")
	print("truths", #ctx.Director.getTruthLog(), ctx.Director.clockString())
	ctx.Escape.callForHelp("Cell", nil)
	print("help", ctx.Escape.helpCalled())
	ctx.Ending.trigger("Sirens")
	print("ending over", ctx.Ending.isOver())
	for _, k in names do if ctx[k].reset then ctx[k].reset() end end
	ctx.World.build()
	ctx.Director.enterLobby()
	print("lobby again", ctx.Director.getAct())
end)
print(ok and "GAME OK" or ("GAME FAIL: " .. tostring(err)))
for _, e in H.errors do print(e) end
