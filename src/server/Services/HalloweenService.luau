--[[
	HalloweenService — Halloween 2026 in the house (until Economy.Halloween.Until, 2 Nov).
	• Every night five wrapped candies sit somewhere in the house (Layout.CandySpots, never two in
	  the same room-sized spot), each with a faint glow so they can be found in the dark too. Whoever
	  takes one gets it (Economy.addCandy: saved, and 5 / 15 / 30 unlock the Pumpkin flashlight colour,
	  the Candy Corn trail and the "Trick or Treat" title). Surviving the night adds two more.
	• At the start of the night everyone is told once (after the onboarding has had its say).
	• The jack-o'-lanterns on the porch glow (Exterior), and in the lobby (LobbyServer).
	Outside the event: nothing at all.
]]

local Players = game:GetService("Players")

local Halloween = {}
local ctx
local Cat
local folder: Instance? = nil

local ORANGE = Color3.fromRGB(255, 122, 24)
local WRAP = { Color3.fromRGB(150, 60, 220), Color3.fromRGB(60, 190, 90), Color3.fromRGB(230, 40, 60), Color3.fromRGB(250, 200, 40) }

function Halloween.live(): boolean
	return Cat.halloweenLive()
end

-- a wrapped sweet: an orange middle with twisted ends, lying on the surface at `at`
local function candyModel(parent: Instance, at: Vector3, yaw: number, wrap: Color3): BasePart
	local B = ctx.Builder
	local m = Instance.new("Model")
	m.Name = "Candy"
	m.Parent = parent
	local cf = CFrame.new(at + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, yaw, 0)
	local body = B.part(m, { Name = "CandyBody", Shape = Enum.PartType.Ball, Size = Vector3.new(0.42, 0.42, 0.42), CFrame = cf, Color = ORANGE,
		Material = Enum.Material.SmoothPlastic, CanCollide = false, CanQuery = true, CastShadow = false })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1.35, 0.9, 0.9)
	mesh.Parent = body
	for _, side in { -1, 1 } do
		B.part(m, { Name = "CandyWrap", Size = Vector3.new(0.2, 0.3, 0.3), CFrame = cf * CFrame.new(side * 0.36, 0, 0) * CFrame.Angles(math.rad(45), 0, 0),
			Color = wrap, Material = Enum.Material.Foil, CanCollide = false, CanQuery = false, CastShadow = false })
	end
	-- a faint glow: findable once the lights are out, not a beacon
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 150, 60)
	glow.Range = 5
	glow.Brightness = 0.5
	glow.Shadows = false
	glow.Parent = body
	m.PrimaryPart = body
	return body
end

-- tonight's candies, placed when the house is built (World.build)
function Halloween.place(root: Instance)
	folder = nil
	if not Halloween.live() then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "HalloweenCandy"
	f.Parent = root
	folder = f
	local rng = Random.new()
	local pool = table.clone(ctx.Layout.CandySpots)
	local chosen = {}
	while #chosen < Cat.Halloween.PerNight and #pool > 0 do
		local at = table.remove(pool, rng:NextInteger(1, #pool))
		local apart = true
		for _, c in chosen do
			if (c - at).Magnitude < 12 then
				apart = false
				break
			end
		end
		if apart then
			table.insert(chosen, at)
		end
	end
	for i, at in chosen do
		local body = candyModel(f, at, rng:NextNumber(0, math.pi * 2), WRAP[(i - 1) % #WRAP + 1])
		ctx.Interaction.prompt(body, { Action = "Take", Object = "Candy", Distance = 6, Name = "CandyPrompt" }, function(player, prompt)
			if not body.Parent then
				return
			end
			prompt:Destroy()
			local model = body.Parent
			if model then
				model:Destroy()
			end
			-- (an admin panel pass night: the candy's gone, nothing counted)
			local credited = not (ctx.Admin and ctx.Admin.uncredited(player))
			local total = credited and ctx.Economy and ctx.Economy.addCandy(player, 1) or 0
			if ctx.Audio then
				ctx.Audio.playAt("Pickup", at, { Caption = false })
			end
			if not credited then
				ctx.Remotes.Notify:FireClient(player, "🍬 Candy doesn't count on an admin panel night.", "info")
				return
			end
			local nxt = Cat.nextCandyReward(total)
			local left = 0
			for _, d in f:GetChildren() do
				if d.Name == "Candy" then
					left += 1
				end
			end
			ctx.Remotes.Notify:FireClient(player, string.format("🍬 Candy! %d in all%s%s", total,
				nxt and string.format(" · %s at %d", nxt.Name, nxt.Candy) or "",
				left > 0 and string.format(" · %d more in the house", left) or ""), "info")
			if ctx.Journey then
				ctx.Journey.event(player, "Candy", total)
			end
		end)
	end
end

function Halloween.count(): number
	local n = 0
	if folder then
		for _, d in folder:GetChildren() do
			if d.Name == "Candy" then
				n += 1
			end
		end
	end
	return n
end

function Halloween.init(c)
	ctx = c
	ctx.Halloween = Halloween
	Cat = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Economy"))
end

function Halloween.start()
	-- the night starts: tell everyone once, after the onboarding's first lines
	local told = false
	workspace:GetAttributeChangedSignal("Act"):Connect(function()
		local act = workspace:GetAttribute("Act")
		if act == "Lobby" then
			told = false
		elseif act == "Evening" and not told and Halloween.live() then
			told = true
			task.delay(40, function()
				if workspace:GetAttribute("Act") ~= "Evening" or Halloween.count() == 0 then
					return
				end
				for _, p in Players:GetPlayers() do
					if p:GetAttribute("InGame") then
						ctx.Remotes.Notify:FireClient(p, "🎃 HALLOWEEN: 5 candies are hidden in the house tonight. Find them for Halloween rewards!", "info")
					end
				end
			end)
		end
	end)
end

return Halloween
