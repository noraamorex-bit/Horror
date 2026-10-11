-- prompts_test: Roblox shows one prompt per key (Exclusivity OnePerButton). Two prompts with the
-- same key right next to each other: only one shows, and on a phone it was the drawer under the
-- microwave instead of "Make popcorn" (phone groups took 2-3 min on that step). No such pairs.
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
	local fired = {}
	ctx.Remotes = setmetatable({}, { __index = function(t, k)
		local r = { FireClient = function(_, _, a) table.insert(fired, k) end, FireAllClients = function() end, OnServerEvent = H.signal() }
		rawset(t, k, r)
		return r
	end })
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
	ctx.restart = function() end
	for _, k in names do if ctx[k].start then ctx[k].start() end end

	local list = {}
	for _, d in H.workspaceRoot:GetDescendants() do
		if d.ClassName == "ProximityPrompt" and d.Enabled then
			local par = d.Parent
			local pos = par.ClassName == "Attachment" and (par.Parent.CFrame * par.Position) or par.Position
			table.insert(list, { P = d, Pos = pos })
		end
	end
	print("prompts", #list)
	local bad = 0
	for i = 1, #list do
		for j = i + 1, #list do
			local a, b = list[i], list[j]
			local dd = (a.Pos - b.Pos).Magnitude
			-- (two identical walkie-talkies side by side: either is fine)
			if dd < 2.5 and a.P.KeyboardKeyCode == b.P.KeyboardKeyCode and a.P.ObjectText ~= b.P.ObjectText then
				bad += 1
				print(string.format("CLASH %.1f  [%s / %s]  <->  [%s / %s]", dd, a.P.ObjectText, a.P.ActionText, b.P.ObjectText, b.P.ActionText))
			end
		end
	end
	assert(bad == 0, bad .. " prompts hide a neighbour with the same key")
	-- the ones the logs caught: the kitchen drawer under the microwave, the junk drawer under the phone
	local keys = {}
	for _, e in list do keys[e.P.ObjectText .. "/" .. e.P.ActionText] = e.P.KeyboardKeyCode end
	assert(keys["Microwave/Make popcorn"] == H.roblox.Enum.KeyCode.E, "popcorn on the main key")
	assert(keys["Kitchen phone/Pick up"] == H.roblox.Enum.KeyCode.E, "phone on the main key")
	print("no clashes")
end)
print(ok and "PROMPTS OK" or ("PROMPTS FAIL: " .. tostring(err)))
