--[[
	LobbyServer — the lobby that players land in.

	A rainy dead end at the bottom of Alder Lane, with the Whitaker house dark on the hill. Four
	glowing circles queue groups of 1, 2, 3 and 4. When a circle is full it counts down, reserves
	a private game server and teleports the group there together.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local LobbyServer = {}

local V = Vector3.new
local ORIGIN = V(0, 0, 400) -- far from the house coordinates, so nothing mistakes it for a room
local PAD_RADIUS = 5.5
local PAD_COLORS = {
	Color3.fromRGB(235, 190, 90),
	Color3.fromRGB(110, 200, 190),
	Color3.fromRGB(235, 130, 70),
	Color3.fromRGB(215, 70, 60),
}

local ctx
local pads = {}
local teleporting: { [Player]: boolean } = {}
local lastSent: { [Player]: string } = {}
local spawnCF: CFrame

---------------------------------------------------------------------------
-- The place
---------------------------------------------------------------------------
local function build(root: Folder)
	local B = ctx.Builder
	local C, M = B.C, B.M
	local function box(name, a: Vector3, b: Vector3, color, mat, extra)
		return B.box(root, name, ORIGIN + a, ORIGIN + b, color, mat, extra)
	end

	box("Ground", V(-90, -3, -90), V(90, 0.5, 90), Color3.fromRGB(52, 66, 44), Enum.Material.Grass)
	box("Street", V(-90, 0.5, 8), V(90, 0.55, 26), Color3.fromRGB(38, 38, 42), M.Asphalt)
	box("Sidewalk", V(-90, 0.5, 2), V(90, 0.8, 8), Color3.fromRGB(135, 135, 130), M.Concrete)
	box("Plaza", V(-36, 0.5, -24), V(36, 0.8, 2), Color3.fromRGB(110, 108, 104), M.Concrete)
	for x = -80, 80, 16 do
		box("LaneMark", V(x, 0.55, 16.7), V(x + 8, 0.6, 17.3), Color3.fromRGB(200, 180, 90), M.Plastic, { CanCollide = false })
	end

	-- the Whitaker house, dark on the hill (scenery only)
	local house = Instance.new("Model")
	house.Name = "HouseOnTheHill"
	house.Parent = root
	B.box(house, "Hill", ORIGIN + V(-70, 0, -90), ORIGIN + V(70, 4, -40), Color3.fromRGB(45, 58, 40), Enum.Material.Grass)
	B.box(house, "House", ORIGIN + V(-30, 4, -82), ORIGIN + V(30, 26, -58), C.Siding, M.Siding)
	B.box(house, "Garage", ORIGIN + V(30, 4, -80), ORIGIN + V(46, 16, -62), Color3.fromRGB(125, 132, 136), M.Siding)
	B.part(house, { ClassName = "WedgePart", Name = "Roof", Size = V(62, 10, 13), CFrame = CFrame.new(ORIGIN + V(0, 31, -64.5)), Color = C.Roof, Material = M.Roof })
	B.part(house, { ClassName = "WedgePart", Name = "Roof", Size = V(62, 10, 13), CFrame = CFrame.new(ORIGIN + V(0, 31, -75.5)) * CFrame.Angles(0, math.pi, 0), Color = C.Roof, Material = M.Roof })
	for _, w in { { -20, 8, false }, { 18, 8, false }, { -20, 18, true }, { 18, 18, false }, { 0, 18, false } } do
		local lit = w[3]
		local win = B.box(house, "Window", ORIGIN + V(w[1] - 3, w[2], -57.9), ORIGIN + V(w[1] + 3, w[2] + 4.5, -57.6), lit and Color3.fromRGB(255, 200, 130) or Color3.fromRGB(20, 22, 28), lit and Enum.Material.Neon or M.Glass)
		if lit then
			local l = Instance.new("PointLight")
			l.Range = 14
			l.Brightness = 0.6
			l.Color = Color3.fromRGB(255, 190, 120)
			l.Parent = win
		end
	end
	B.box(house, "FrontDoor", ORIGIN + V(-2.5, 4, -57.9), ORIGIN + V(2.5, 13, -57.6), Color3.fromRGB(70, 40, 35), M.Wood)

	-- trees, lamps, the gray van at the curb
	for _, t in { { -60, -20 }, { 58, -28 }, { -75, 50 }, { 70, 55 }, { -45, 60 } } do
		B.tree(root, ORIGIN + V(t[1], 0.5, t[2]), 22)
	end
	for _, x in { -44, 44 } do
		box("LampPole", V(x - 0.3, 0.5, 3), V(x + 0.3, 18, 3.6), Color3.fromRGB(60, 60, 62), M.Metal)
		local head = box("LampHead", V(x - 2, 18, 2), V(x + 2, 18.8, 4.5), Color3.fromRGB(255, 220, 160), Enum.Material.Neon)
		local sl = Instance.new("SpotLight")
		sl.Face = Enum.NormalId.Bottom
		sl.Range = 40
		sl.Angle = 120
		sl.Brightness = 2
		sl.Color = Color3.fromRGB(255, 200, 140)
		sl.Parent = head
	end
	local van = Instance.new("Model")
	van.Name = "GrayVan"
	van.Parent = root
	B.box(van, "VanBody", ORIGIN + V(55, 1.5, 11), ORIGIN + V(71, 8.5, 18), Color3.fromRGB(125, 128, 130), M.Metal)
	B.box(van, "VanHood", ORIGIN + V(71, 1.5, 11), ORIGIN + V(74, 5.5, 18), Color3.fromRGB(125, 128, 130), M.Metal)

	-- title sign
	local sign = box("Sign", V(-14, 1, -26), V(14, 11, -25), Color3.fromRGB(25, 24, 28), M.Wood)
	for _, x in { -13, 13 } do
		box("SignPost", V(x - 0.4, 0.5, -25.8), V(x + 0.4, 11, -25.2), Color3.fromRGB(25, 24, 28), M.Wood)
	end
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.CanvasSize = Vector2.new(840, 300)
	sg.LightInfluence = 0
	sg.Parent = sign
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.Font = Enum.Font.SpecialElite
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(235, 228, 215)
	title.Text = "HOME ALONE"
	title.Parent = sg
	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromScale(0.05, 0.58)
	sub.Size = UDim2.new(0.9, 0, 0.36, 0)
	sub.Font = Enum.Font.GothamMedium
	sub.TextScaled = true
	sub.TextWrapped = true
	sub.TextColor3 = Color3.fromRGB(180, 175, 165)
	sub.Text = "Stand in a circle to queue. The night starts when the circle is full."
	sub.Parent = sg

	-- queue circles
	for i, size in ctx.Config.Lobby.QueueSizes do
		local x = (i - (#ctx.Config.Lobby.QueueSizes + 1) / 2) * 16
		local center = ORIGIN + V(x, 0.8, -8)
		local color = PAD_COLORS[i] or PAD_COLORS[1]
		B.cylinder(root, "PadBase", center + V(0, 0.1, 0), 0.2, PAD_RADIUS * 2 + 1.2, Color3.fromRGB(30, 30, 34), M.Concrete, CFrame.Angles(0, 0, math.rad(90)))
		local disc = B.cylinder(root, "Pad" .. size, center + V(0, 0.25, 0), 0.12, PAD_RADIUS * 2, color, Enum.Material.Neon, CFrame.Angles(0, 0, math.rad(90)))
		disc.CanCollide = false
		disc.Transparency = 0.55
		local glow = Instance.new("PointLight")
		glow.Range = 12
		glow.Brightness = 0.8
		glow.Color = color
		glow.Parent = disc

		local bb = Instance.new("BillboardGui")
		bb.Name = "QueueSign"
		bb.Size = UDim2.fromScale(9, 4.5)
		bb.StudsOffset = V(0, 6.5, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 150
		bb.Parent = disc
		local function line(name, y, h, font, color3)
			local l = Instance.new("TextLabel")
			l.Name = name
			l.BackgroundTransparency = 1
			l.Position = UDim2.fromScale(0, y)
			l.Size = UDim2.fromScale(1, h)
			l.Font = font
			l.TextScaled = true
			l.TextColor3 = color3
			l.TextStrokeTransparency = 0.4
			l.Text = ""
			l.Parent = bb
			return l
		end
		local head = line("Title", 0, 0.4, Enum.Font.SpecialElite, color)
		head.Text = size == 1 and "1 PLAYER" or (size .. " PLAYERS")
		local count = line("Count", 0.42, 0.3, Enum.Font.GothamBold, Color3.fromRGB(235, 230, 220))
		local status = line("Status", 0.74, 0.24, Enum.Font.GothamMedium, Color3.fromRGB(190, 185, 175))

		table.insert(pads, {
			Size = size,
			Center = center,
			Disc = disc,
			Color = color,
			Count = count,
			Status = status,
			Members = {},
			CountdownEnd = nil,
			Teleporting = false,
			CooldownUntil = 0,
		})
	end

	-- spawn, facing the circles
	spawnCF = CFrame.lookAt(ORIGIN + V(0, 3.5, 12), ORIGIN + V(0, 3.5, -8))
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Size = V(10, 0.2, 6)
	spawn.CFrame = CFrame.new(ORIGIN + V(0, 0.9, 12))
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = root
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end

	-- invisible walls
	for _, b in { { V(-91, -5, -91), V(-90, 60, 91) }, { V(90, -5, -91), V(91, 60, 91) }, { V(-91, -5, -91), V(91, 60, -90) }, { V(-91, -5, 90), V(91, 60, 91) } } do
		box("Bounds", b[1], b[2], C.Black, M.Plastic, { Transparency = 1 })
	end
end

---------------------------------------------------------------------------
-- Queues
---------------------------------------------------------------------------
local function padOf(player: Player)
	for _, pad in pads do
		if table.find(pad.Members, player) then
			return pad
		end
	end
	return nil
end

local function send(player: Player, payload)
	local key = payload and string.format("%d|%d|%s|%s", payload.Size, payload.Count, tostring(payload.Countdown), payload.Status) or "none"
	if lastSent[player] == key then
		return
	end
	lastSent[player] = key
	ctx.Remotes.Queue:FireClient(player, payload)
end

local function teleportGroup(pad, group: { Player })
	pad.Teleporting = true
	for _, p in group do
		teleporting[p] = true
	end
	task.spawn(function()
		local placeId = ctx.Mode.gamePlaceId()
		local ok, err = pcall(function()
			if RunService:IsStudio() then
				error("Teleports don't work in a Studio test. Publish, then play in the Roblox app.")
			end
			local code = TeleportService:ReserveServer(placeId)
			local options = Instance.new("TeleportOptions")
			options.ReservedServerAccessCode = code
			options:SetTeleportData({ PartySize = #group, Mode = "Game" })
			TeleportService:TeleportAsync(placeId, group, options)
		end)
		if not ok then
			warn("[Lobby] teleport failed: " .. tostring(err))
			for _, p in group do
				teleporting[p] = nil
				if p.Parent then
					ctx.Remotes.Notify:FireClient(p, "Couldn't start the night: " .. tostring(err), "danger")
				end
			end
			pad.Teleporting = false
			pad.CountdownEnd = nil
			pad.CooldownUntil = os.clock() + 8
		else
			-- if they're somehow still here a while later, free the circle
			task.delay(30, function()
				pad.Teleporting = false
				for _, p in group do
					teleporting[p] = nil
				end
			end)
		end
	end)
end

local function tick()
	local now = os.clock()
	for _, pad in pads do
		-- who is standing on it
		local inside = {}
		for _, p in Players:GetPlayers() do
			local root = ctx.Util.getRoot(p)
			if root and not teleporting[p] then
				local d = root.Position - pad.Center
				if V(d.X, 0, d.Z).Magnitude <= PAD_RADIUS and math.abs(d.Y) < 8 then
					inside[p] = true
				end
			end
		end
		-- keep queue order: people already queued stay ahead of newcomers
		local members = {}
		for _, p in pad.Members do
			if inside[p] or (pad.Teleporting and teleporting[p]) then
				table.insert(members, p)
				inside[p] = nil
			end
		end
		for p in inside do
			if not padOf(p) or padOf(p) == pad then
				table.insert(members, p)
			end
		end
		pad.Members = members

		local counted = math.min(#members, pad.Size)
		if pad.Teleporting then
			pad.Status.Text = "Heading to 14 Alder Lane..."
		elseif counted >= pad.Size and now >= pad.CooldownUntil then
			if not pad.CountdownEnd then
				pad.CountdownEnd = now + (pad.Size == 1 and ctx.Config.Lobby.SoloCountdown or ctx.Config.Lobby.Countdown)
			end
			local left = math.max(0, math.ceil(pad.CountdownEnd - now))
			pad.Status.Text = "Starting in " .. left .. "..."
			if now >= pad.CountdownEnd then
				local group = {}
				for i = 1, pad.Size do
					table.insert(group, members[i])
				end
				teleportGroup(pad, group)
			end
		else
			pad.CountdownEnd = nil
			pad.Status.Text = counted == 0 and "Step in to queue" or ("Waiting for " .. (pad.Size - counted) .. " more")
		end
		pad.Count.Text = counted .. " / " .. pad.Size
		pad.Disc.Transparency = counted > 0 and 0.2 or 0.55

		for i, p in members do
			local status
			if pad.Teleporting then
				status = "Teleporting"
			elseif i > pad.Size then
				status = "Full"
			elseif pad.CountdownEnd then
				status = "Starting"
			else
				status = "Waiting"
			end
			send(p, {
				Size = pad.Size,
				Count = counted,
				Countdown = pad.CountdownEnd and math.max(0, math.ceil(pad.CountdownEnd - now)) or nil,
				Status = status,
			})
		end
	end
	for _, p in Players:GetPlayers() do
		if not padOf(p) then
			send(p, nil)
		end
	end
end

---------------------------------------------------------------------------
function LobbyServer.run(c)
	ctx = c
	local root = Instance.new("Folder")
	root.Name = "Lobby"
	root.Parent = workspace
	build(root)

	local function setup(player: Player)
		-- third person here; the house itself is first person
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 18
		player.CharacterAdded:Connect(function(char)
			local hum = char:WaitForChild("Humanoid") :: Humanoid
			hum.WalkSpeed = 16
			task.defer(function()
				char:PivotTo(spawnCF * CFrame.new(math.random(-4, 4), 0, math.random(-2, 2)))
			end)
		end)
	end
	for _, p in Players:GetPlayers() do
		setup(p)
	end
	Players.PlayerAdded:Connect(setup)
	Players.PlayerRemoving:Connect(function(p)
		teleporting[p] = nil
		lastSent[p] = nil
	end)

	ctx.Remotes.LeaveQueue.OnServerEvent:Connect(function(player)
		if teleporting[player] then
			return
		end
		local char = player.Character
		if char and padOf(player) then
			char:PivotTo(spawnCF * CFrame.new(math.random(-4, 4), 0, 3))
		end
	end)
	TeleportService.TeleportInitFailed:Connect(function(player, result, message)
		teleporting[player] = nil
		if player.Parent then
			ctx.Remotes.Notify:FireClient(player, "Teleport failed (" .. tostring(result) .. "). Step back into a circle to try again.", "danger")
		end
		warn("[Lobby] TeleportInitFailed " .. player.Name .. ": " .. tostring(message))
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		local ok, err = pcall(tick)
		if not ok then
			warn("[Lobby] " .. tostring(err))
		end
	end)
	print("[HomeAlone] lobby ready")
end

return LobbyServer
