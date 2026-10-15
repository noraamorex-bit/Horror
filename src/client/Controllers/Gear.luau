--[[
	Gear — the items you use are Roblox tools in the hotbar (server: ToolService).
	• Pick one (1-9, tap it, or L1/R1 on a pad), then click / tap / R2: the use goes to the server with
	  where you're aiming (the point under the mouse or your finger; the camera's centre otherwise).
	• The hotbar shows only while you can use things: not hiding, tied up, dead, being him, in a
	  cutscene, a conversation or the heartbeat minigame.
	• F (or D-pad up) takes the flashlight out, or puts it away.
]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local Gear = {}
local ctx
local player = Players.LocalPlayer
local shown: boolean? = nil
local hooked: { [Instance]: boolean } = {}

-- where you're aiming, from your head
local function aim(): Vector3?
	local char = player.Character
	local head = char and char:FindFirstChild("Head") :: BasePart?
	local cam = workspace.CurrentCamera
	if not head or not cam then
		return nil
	end
	local target: Vector3? = nil
	pcall(function()
		local hit = player:GetMouse().Hit
		target = hit and hit.Position or nil
	end)
	if target and (target - head.Position).Magnitude > 2 then
		return (target - head.Position).Unit
	end
	return cam.CFrame.LookVector
end
Gear._aim = aim -- (tests)

function Gear.use(tool: Tool)
	local item = tool:GetAttribute("ItemId")
	if type(item) ~= "string" or not player:GetAttribute("InGame") then
		return
	end
	ctx.Remotes.UseItem:FireServer(item, aim())
end

local function hook(tool: Instance)
	if not tool:IsA("Tool") or hooked[tool] or tool:GetAttribute("ItemId") == nil then
		return
	end
	hooked[tool] = true
	tool.Activated:Connect(function()
		Gear.use(tool)
	end)
	tool.Destroying:Connect(function()
		hooked[tool] = nil
	end)
end

local function blocked(): boolean
	if not player:GetAttribute("InGame") then
		return true
	end
	for _, a in { "Hiding", "Captured", "Dead", "Escaped", "Monster" } do
		if player:GetAttribute(a) then
			return true
		end
	end
	if workspace:GetAttribute("EndingActive") then
		return true
	end
	if ctx.Cutscene and ctx.Cutscene.isPlaying and ctx.Cutscene.isPlaying() then
		return true
	end
	if ctx.Dialogue and ctx.Dialogue.blocksControls and ctx.Dialogue.blocksControls() then
		return true
	end
	if ctx.HeartbeatUI and ctx.HeartbeatUI.isActive and ctx.HeartbeatUI.isActive() then
		return true
	end
	return false
end

local function hasTools(): boolean
	for _, holder in { player.Character, player:FindFirstChildOfClass("Backpack") } do
		if holder and holder:FindFirstChildOfClass("Tool") then
			return true
		end
	end
	return false
end

local lastLift = -1
local function refresh()
	local want = not blocked()
	if want ~= shown then
		shown = want
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, want)
		end)
	end
	-- the hotbar sits at the bottom centre: what's usually there moves up above it (about 72 screen
	-- pixels, whatever the UI's scale)
	local lift = (want and hasTools()) and math.ceil(72 / math.max(0.3, ctx.UI.Scale or 1)) or 0
	if lift ~= lastLift then
		lastLift = lift
		if ctx.HUD and ctx.HUD.setBottomLift then
			ctx.HUD.setBottomLift(lift)
		end
		if ctx.UI.Subtitles then
			ctx.UI.Subtitles.Position = UDim2.new(0.5, 0, 1, -104 - lift)
		end
	end
end
Gear._refresh = refresh -- (tests)
function Gear.isShown(): boolean
	return shown == true
end

-- F: the flashlight out of your pocket, or back in
function Gear.toggleFlashlight()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or blocked() then
		return
	end
	for _, t in char:GetChildren() do
		if t:IsA("Tool") and t:GetAttribute("ItemId") == "Flashlight" then
			hum:UnequipTools()
			return
		end
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, t in backpack and backpack:GetChildren() or {} do
		if t:IsA("Tool") and t:GetAttribute("ItemId") == "Flashlight" then
			hum:EquipTool(t)
			return
		end
	end
	if ctx.Thoughts and ctx.Thoughts.say then
		ctx.Thoughts.say("I don't have a flashlight. There's one on the mudroom shelf, and one in the den drawer.")
	end
end

function Gear.init(c)
	ctx = c
	ctx.Gear = Gear
end

function Gear.start()
	local function watch(char: Model)
		for _, t in char:GetChildren() do
			hook(t)
		end
		char.ChildAdded:Connect(hook)
	end
	if player.Character then
		watch(player.Character)
	end
	player.CharacterAdded:Connect(watch)
	ctx.Input.on("Flashlight", function(began)
		if began then
			Gear.toggleFlashlight()
		end
	end)
	local clock = 0
	RunService.Heartbeat:Connect(function(dt)
		clock += dt
		if clock >= 0.2 then
			clock = 0
			refresh()
		end
	end)
	refresh()
end

return Gear
