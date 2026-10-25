--[[
	Prank — "😱 JUMPSCARE EVERYONE" (v115, the owner: "add something like this for 10 Robux"): a
	developer product (Config.Shop.JumpscareAll) that, the moment it's bought, jumpscares every other
	player in the server, in the house or in the lobby (ShopService fires Remotes.JumpscareAll).

	What they get: the screen goes black, his porcelain mask (a copy of the real one, in a
	ViewportFrame over everything) lunges out of the dark at them with its jaw dropped, the screech and
	a hit, a red flash and a shake; then a line at the bottom saying who did it, so they can pay them
	back. The buyer gets "You jumpscared N players".

	Where you buy it: a small 😱 button under the inventory in the house and a 😱 SCARE icon in the
	lobby's dock, both only while someone else is in the server to scare.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local Prank = {}
local ctx
local player = Players.LocalPlayer

local button: GuiButton? = nil
local scaring = false

local function product()
	local p = ctx.Config.Shop.JumpscareAll
	return (p and p.Id > 0) and p or nil
end

local function buy()
	local p = product()
	if p then
		pcall(function()
			MarketplaceService:PromptProductPurchase(player, p.Id)
		end)
	end
end

local function others(): number
	return #Players:GetPlayers() - 1
end

local function refresh()
	if not button then
		return
	end
	local show = product() ~= nil and others() > 0
	if ctx.Mode ~= "Lobby" then
		show = show and player:GetAttribute("InGame") == true and not workspace:GetAttribute("EndingActive")
	end
	button.Visible = show
end
Prank._refresh = refresh -- (tests)

-- a banner low on the screen for a few seconds (works in the lobby and in the house)
local function banner(gui: ScreenGui, text: string, seconds: number)
	local UI = ctx.UI
	local b = UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(520, 40),
		Text = text,
		Font = UI.Font.Bold,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(255, 236, 228),
		BackgroundColor3 = Color3.fromRGB(70, 10, 12),
		BackgroundTransparency = 0.15,
		ZIndex = 5,
		Parent = gui,
	})
	UI.corner(b, 10)
	task.delay(seconds, function()
		if b.Parent then
			UI.tween(b, 0.5, { BackgroundTransparency = 1, TextTransparency = 1 })
			task.delay(0.6, function()
				b:Destroy()
			end)
		end
	end)
end

local function overlay(): ScreenGui
	return ctx.UI.new("ScreenGui", {
		Name = "Prank",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 60,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = ctx.UI.PlayerGui,
	})
end

-- his mask and hair, copied into a viewport: the Head part and what's on it (whatever's visible
-- within reach of it), placed relative to the head
local function maskCopy(): (Model?, CFrame?)
	local him = ctx.Util.creature and ctx.Util.creature()
	local head = him and him:FindFirstChild("Head") :: BasePart?
	if not head then
		return nil, nil
	end
	local m = Instance.new("Model")
	local hcf = head.CFrame
	for _, d in him:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Body" and d.Name ~= "HumanoidRootPart" and d.Name ~= "FaceGlow"
			and (d == head or d.Transparency < 0.95) and (d.Position - head.Position).Magnitude < 2.6 then
			local c = d:Clone()
			for _, x in c:GetChildren() do
				if not x:IsA("SpecialMesh") and not x:IsA("Decal") then
					x:Destroy()
				end
			end
			c.Anchored = true
			c.CFrame = hcf:ToObjectSpace(d.CFrame)
			c.Transparency = d == head and 0 or d.Transparency
			c.Parent = m
		end
	end
	return m, hcf
end

-- the scare itself
function Prank.scare(from: string)
	if scaring then
		return
	end
	-- (never on top of the real thing)
	if workspace:GetAttribute("EndingActive") or player:GetAttribute("Captured") then
		return
	end
	scaring = true
	local UI = ctx.UI
	local gui = overlay()
	local black = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 1, Parent = gui })
	local vp = UI.new("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(150, 150, 160),
		LightColor = Color3.fromRGB(255, 244, 232),
		LightDirection = Vector3.new(-0.3, -0.6, -1),
		ZIndex = 2,
		Parent = gui,
	})
	local red = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(150, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3, Parent = gui })
	local cam = Instance.new("Camera")
	cam.FieldOfView = 50
	cam.Parent = vp
	vp.CurrentCamera = cam
	local mask = maskCopy()
	local jaws = {}
	if mask then
		mask.Parent = vp
		jaws = ctx.CreaturePose.jawMeshes(mask)
	end
	for _, name in { "Screech", "Jumpscare", "HorrorHitLow" } do
		local s = ctx.Effects and ctx.Effects.localSound(name)
		if s then
			s:Play()
			game:GetService("Debris"):AddItem(s, 10)
		end
	end
	if ctx.Effects then
		ctx.Effects.shake(1.2, 0.9)
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not gui.Parent then
			conn:Disconnect()
			return
		end
		local k = os.clock() - t0
		-- out of the dark at you: fast, then the last stretch slow, the picture jerking
		local lunge = 1 - (1 - math.min(k / 0.32, 1)) ^ 3
		local d = 9 - 6.6 * lunge
		local j = 0.05 * (1 - math.min(k / 1.2, 1))
		local jerk = CFrame.Angles((math.random() - 0.5) * j, (math.random() - 0.5) * j, (math.random() - 0.5) * 0.25 * math.min(k * 4, 1))
		cam.CFrame = CFrame.lookAt(Vector3.new(0, -0.05, -d), Vector3.new(0, -0.05, 0)) * jerk
		ctx.CreaturePose.setJaw(jaws, math.clamp(k / 0.25, 0, 1))
		red.BackgroundTransparency = 1 - 0.45 * math.max(0, 1 - math.abs(k - 0.3) / 0.25)
	end)
	task.wait(1.25)
	conn:Disconnect()
	UI.tween(black, 0.35, { BackgroundTransparency = 1 })
	UI.tween(vp, 0.25, { ImageTransparency = 1 })
	red.BackgroundTransparency = 1
	banner(gui, "😱 " .. from .. " jumpscared everyone!", 4)
	task.delay(5, function()
		gui:Destroy()
	end)
	task.wait(0.4)
	scaring = false
end

function Prank.init(c)
	ctx = c
	ctx.Prank = Prank
end

function Prank.start()
	local UI = ctx.UI
	if ctx.Mode == "Lobby" then
		if ctx.Dock then
			button = ctx.Dock.add({ Order = 5, Glyph = "😱", Label = "SCARE", Color = Color3.fromRGB(255, 96, 90), OnClick = buy })
		end
	else
		local b = UI.new("TextButton", {
			Name = "PrankOffer",
			Size = UDim2.fromOffset(190, 30),
			Text = "😱 JUMPSCARE EVERYONE  R$ " .. tostring(product() and product().Price or 10),
			Font = UI.Font.Bold,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(255, 228, 224),
			BackgroundColor3 = Color3.fromRGB(80, 14, 16),
			BackgroundTransparency = 0.2,
			AutoButtonColor = true,
			LayoutOrder = 11,
			Visible = false,
			Parent = ctx.HUD and ctx.HUD.LeftColumn or UI.Root,
		})
		UI.corner(b, 8)
		UI.stroke(b, Color3.fromRGB(255, 120, 110), 1, 0.55)
		b.Activated:Connect(buy)
		button = b
	end
	refresh()
	Players.PlayerAdded:Connect(refresh)
	Players.PlayerRemoving:Connect(function()
		task.defer(refresh)
	end)
	player:GetAttributeChangedSignal("InGame"):Connect(refresh)
	workspace:GetAttributeChangedSignal("EndingActive"):Connect(refresh)
	ctx.Remotes.JumpscareAll.OnClientEvent:Connect(function(fromName: string, fromId: number, count: number?)
		if fromId == player.UserId then
			local gui = overlay()
			banner(gui, "😈 You jumpscared " .. tostring(count or others()) .. (count == 1 and " player!" or " players!"), 4)
			task.delay(5, function()
				gui:Destroy()
			end)
			return
		end
		task.spawn(Prank.scare, fromName)
	end)
end

return Prank
