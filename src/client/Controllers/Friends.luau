--[[
	Friends — a small name tag over each friend in the house, seen through walls, so a group
	can find each other in the dark. It fades out up close (you can see them), and turns red
	("TIED UP") when he's taken them, so the others know where to go.
	Nothing for friends who are out of the night (escaped / dead).
	(v160) In the lobby: a "👥 Name" tag over each of your Roblox friends, so you can find them and step into their circle
	(players: "let people join with friends first").
]]

local Players = game:GetService("Players")

local Friends = {}
local ctx
local player = Players.LocalPlayer

local NEAR = 14 -- closer than this: no tag (you can see them)
local tags: { [Player]: { Gui: BillboardGui, Name: TextLabel, Info: TextLabel } } = {}
local robloxFriend: { [Player]: boolean } = {} -- (lobby: who's a Roblox friend)
local folder: Folder

local function make(p: Player)
	local gui = Instance.new("BillboardGui")
	gui.Name = "FriendTag_" .. p.Name
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Size = UDim2.fromOffset(170, 44)
	gui.StudsOffset = Vector3.new(0, 2.8, 0)
	gui.MaxDistance = 400
	gui.ResetOnSpawn = false
	gui.Enabled = false
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, 0, 0, 22)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 16
	name.TextColor3 = Color3.fromRGB(235, 232, 226)
	name.TextStrokeTransparency = 0.4
	name.Text = p.DisplayName
	name.Parent = gui
	local info = Instance.new("TextLabel")
	info.BackgroundTransparency = 1
	info.Position = UDim2.fromOffset(0, 21)
	info.Size = UDim2.new(1, 0, 0, 18)
	info.Font = Enum.Font.GothamMedium
	info.TextSize = 13
	info.TextColor3 = Color3.fromRGB(190, 186, 178)
	info.TextStrokeTransparency = 0.5
	info.Text = ""
	info.Parent = gui
	gui.Parent = folder
	tags[p] = { Gui = gui, Name = name, Info = info }
end

-- (v160) the lobby: only Roblox friends, "👥 Name", whatever circle they're in
local function updateLobby()
	local cam = workspace.CurrentCamera
	local from = cam and cam.CFrame.Position or Vector3.zero
	for p, t in tags do
		local char = p.Character
		local head = char and char:FindFirstChild("Head") :: BasePart?
		local show = robloxFriend[p] == true and head ~= nil
		if show and head then
			t.Gui.Adornee = head
			t.Name.Text = "👥 " .. p.DisplayName
			t.Name.TextColor3 = Color3.fromRGB(150, 220, 255)
			t.Info.Text = "FRIEND"
			show = (head.Position - from).Magnitude > 6
		end
		t.Gui.Enabled = show == true
	end
end

local function update()
	local act = workspace:GetAttribute("Act")
	local live = act ~= nil and act ~= "Lobby" and not workspace:GetAttribute("EndingActive")
	local cam = workspace.CurrentCamera
	local from = cam and cam.CFrame.Position or Vector3.zero
	for p, t in tags do
		local char = p.Character
		local head = char and char:FindFirstChild("Head") :: BasePart?
		local show = live and head ~= nil and p:GetAttribute("InGame") == true
			and not p:GetAttribute("Escaped") and not p:GetAttribute("Dead")
		if show and head then
			local captured = p:GetAttribute("Captured") == true
			local dist = (head.Position - from).Magnitude
			show = captured or dist > NEAR
			t.Gui.Adornee = head
			t.Name.TextColor3 = captured and Color3.fromRGB(255, 80, 70) or Color3.fromRGB(235, 232, 226)
			t.Info.TextColor3 = captured and Color3.fromRGB(255, 120, 110) or Color3.fromRGB(190, 186, 178)
			t.Info.Text = (captured and "TIED UP · " or "") .. tostring(math.floor(dist)) .. "m"
		end
		t.Gui.Enabled = show == true
	end
end

function Friends.init(c)
	ctx = c
end

function Friends.start()
	folder = Instance.new("Folder")
	folder.Name = "FriendTags"
	folder.Parent = ctx.UI.PlayerGui
	local function added(p: Player)
		if p ~= player then
			make(p)
			if ctx.Mode == "Lobby" then
				task.spawn(function()
					local ok, yes = pcall(function()
						return player:IsFriendsWith(p.UserId)
					end)
					robloxFriend[p] = ok and yes == true
				end)
			end
		end
	end
	for _, p in Players:GetPlayers() do
		added(p)
	end
	Players.PlayerAdded:Connect(added)
	Players.PlayerRemoving:Connect(function(p)
		local t = tags[p]
		if t then
			t.Gui:Destroy()
			tags[p] = nil
		end
		robloxFriend[p] = nil
	end)
	task.spawn(function()
		while true do
			-- (only while you're still in the night yourself: spectating has its own labels)
			if ctx.Mode == "Lobby" then
				updateLobby()
			elseif player:GetAttribute("InGame") and not player:GetAttribute("Dead") and not player:GetAttribute("Escaped") then
				update()
			else
				for _, t in tags do
					t.Gui.Enabled = false
				end
			end
			task.wait(0.2)
		end
	end)
end

return Friends
