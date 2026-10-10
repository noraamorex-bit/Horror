--[[
	Settings — music volume, sound volume and camera shake, saved with your stats
	(Remotes.SaveSettings; the server mirrors them back as SetMusic / SetSfx / SetShake).

	Every sound goes through one of two SoundGroups: music (the score and stings) or effects
	(everything else, his footsteps included), so the sliders cover sounds made anywhere.
	Opened from the lobby menu and from the journal in the house.
]]

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local Settings = {}
local ctx
local player = Players.LocalPlayer

local MUSIC = {
	LobbyMusic = true,
	CozyPiano = true,
	VictorySting = true,
	DeathSting = true,
	SadPiano = true,
	VoteMusic = true,
	Riser = true,
}
local STEPS = { 0, 0.25, 0.5, 0.75, 1 }

local musicGroup: SoundGroup
local sfxGroup: SoundGroup
local panel: Frame
local rows: { [string]: { [number]: TextButton } } = {}
local shakeButton: TextButton
local current = { Music = 1, Sfx = 1, Shake = true }

local function sort(s: Instance)
	if s:IsA("Sound") and s.SoundGroup == nil then
		s.SoundGroup = MUSIC[s.Name] and musicGroup or sfxGroup
	end
end

local function apply()
	musicGroup.Volume = current.Music
	sfxGroup.Volume = current.Sfx
end

local function refresh()
	local UI = ctx.UI
	for key, buttons in rows do
		for i, b in buttons do
			local on = math.abs(STEPS[i] - current[key]) < 0.01
			b.BackgroundColor3 = on and Color3.fromRGB(240, 236, 228) or Color3.fromRGB(28, 28, 32)
			b.TextColor3 = on and Color3.fromRGB(15, 15, 15) or UI.Color.Text
		end
	end
	shakeButton.Text = current.Shake and "ON" or "OFF"
	shakeButton.BackgroundColor3 = current.Shake and Color3.fromRGB(240, 236, 228) or Color3.fromRGB(28, 28, 32)
	shakeButton.TextColor3 = current.Shake and Color3.fromRGB(15, 15, 15) or UI.Color.Text
end

local function save()
	apply()
	refresh()
	ctx.Remotes.SaveSettings:FireServer(current.Music, current.Sfx, current.Shake)
end

-- the saved values, once the server has loaded them
local function fromAttributes()
	local m, s, sh = player:GetAttribute("SetMusic"), player:GetAttribute("SetSfx"), player:GetAttribute("SetShake")
	if type(m) == "number" then
		current.Music = m
	end
	if type(s) == "number" then
		current.Sfx = s
	end
	if type(sh) == "boolean" then
		current.Shake = sh
	end
	apply()
	if panel then
		refresh()
	end
end

function Settings.shakeOn(): boolean
	return current.Shake
end

function Settings.open()
	refresh()
	panel.Visible = true
end

function Settings.close()
	panel.Visible = false
end

local function build()
	local UI = ctx.UI
	panel = UI.new("Frame", {
		Name = "Settings",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(460, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UI.Color.Panel,
		BackgroundTransparency = 0.08,
		Visible = false,
		ZIndex = 30,
		Parent = UI.Top,
	})
	UI.corner(panel, 12)
	UI.stroke(panel, Color3.new(1, 1, 1), 1.5, 0.75)
	UI.padding(panel, 20)
	UI.modal(panel)
	UI.new("UIListLayout", { Padding = UDim.new(0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	UI.label({ Size = UDim2.new(1, 0, 0, 34), Text = "SETTINGS", Font = UI.Font.Bold, TextSize = 26, LayoutOrder = 0, ZIndex = 31, Parent = panel })

	local function row(order: number, text: string): Frame
		local r = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 31, Parent = panel })
		UI.label({ Size = UDim2.new(0, 130, 1, 0), Text = text, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 31, Parent = r })
		local right = UI.new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(1, -134, 1, 0), BackgroundTransparency = 1, ZIndex = 31, Parent = r })
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = right })
		return right
	end
	local function pill(parent: Instance, text: string, order: number, width: number): TextButton
		local b = UI.new("TextButton", {
			Size = UDim2.fromOffset(width, 40),
			Text = text,
			Font = UI.Font.Bold,
			TextSize = 15,
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(28, 28, 32),
			TextColor3 = UI.Color.Text,
			LayoutOrder = order,
			ZIndex = 32,
			Parent = parent,
		})
		UI.corner(b, 8)
		UI.stroke(b, Color3.new(1, 1, 1), 1, 0.7)
		return b
	end
	for order, spec in { { "Music", "Music" }, { "Sfx", "Sounds" } } do
		local key = spec[1]
		local right = row(order, spec[2])
		rows[key] = {}
		for i, v in STEPS do
			local b = pill(right, v == 0 and "OFF" or (tostring(math.floor(v * 100)) .. "%"), i, 56)
			b.Activated:Connect(function()
				current[key] = v
				save()
				if key == "Sfx" and v > 0 then
					ctx.Effects.playSound("UISelect", nil, { Caption = false })
				end
			end)
			rows[key][i] = b
		end
	end
	local shakeRow = row(3, "Camera shake")
	shakeButton = pill(shakeRow, "ON", 1, 90)
	shakeButton.Activated:Connect(function()
		current.Shake = not current.Shake
		save()
	end)

	local done = pill(panel, "DONE", 10, 180)
	done.Size = UDim2.fromOffset(180, 48)
	done.TextSize = 20
	done.Activated:Connect(Settings.close)
end

function Settings.init(c)
	ctx = c
	ctx.Settings = Settings
end

function Settings.start()
	musicGroup = Instance.new("SoundGroup")
	musicGroup.Name = "MusicGroup"
	musicGroup.Parent = SoundService
	sfxGroup = Instance.new("SoundGroup")
	sfxGroup.Name = "EffectsGroup"
	sfxGroup.Parent = SoundService
	for _, root in { SoundService, workspace } do
		for _, d in root:GetDescendants() do
			sort(d)
		end
		root.DescendantAdded:Connect(sort)
	end
	build()
	fromAttributes()
	for _, a in { "SetMusic", "SetSfx", "SetShake" } do
		player:GetAttributeChangedSignal(a):Connect(fromAttributes)
	end
end

return Settings
