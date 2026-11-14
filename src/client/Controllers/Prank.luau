--[[
	Prank — "😱 JUMPSCARE EVERYONE" (v115, the owner: "add something like this for 10 Robux"): a
	developer product (Config.Shop.JumpscareAll) that, the moment it's bought, jumpscares every other
	player in the server, in the house or in the lobby (ShopService fires Remotes.JumpscareAll).

	What they get (v165): a few seconds of dread, two glimpses of his face in the black, then his face slams into the
	lens screaming (Prank.scare: the beats are written out there); then a line at the bottom saying who did it, so they
	can pay them back. The buyer sees it too (v165), then "You jumpscared N players".

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
	-- (v145) a free one first (the Starter Pack's), straight away, no purchase window
	if (tonumber(player:GetAttribute("PrankCredits")) or 0) > 0 then
		ctx.Remotes.PrankFree:FireServer()
		return
	end
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
	-- (v145) the Starter Pack's free one shows as FREE
	if button:IsA("TextButton") and button.Name == "PrankOffer" then
		local free = (tonumber(player:GetAttribute("PrankCredits")) or 0) > 0
		button.Text = "😱 JUMPSCARE EVERYONE  " .. (free and "FREE" or ("R$ " .. tostring(product() and product().Price or 10)))
	end
end
Prank._refresh = refresh -- (tests)
Prank.buy = buy -- (v137: also offered on the result card while you watch the others)
Prank.others = others

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
	-- (v149: no mask any more: his own face, the skinned body copied in at rest with its eyes at the middle; the
	-- scare poses it, the maw tearing open)
	local body = him and not him:GetAttribute("Masked") and him:FindFirstChild("Body") :: MeshPart?
	if body and body:IsA("MeshPart") then
		local eyeL = body:FindFirstChild("EyeShineL", true) :: Bone?
		local eyeR = body:FindFirstChild("EyeShineR", true) :: Bone?
		local mid = (eyeL and eyeR) and body.CFrame:PointToObjectSpace((eyeL.WorldPosition + eyeR.WorldPosition) / 2) or Vector3.new(0, body.Size.Y * 0.4, -0.4)
		local m = Instance.new("Model")
		m:SetAttribute("Skinned", true)
		local c = body:Clone()
		for _, x in c:GetDescendants() do
			if not (x:IsA("Bone") or x:IsA("SurfaceAppearance") or x:IsA("BillboardGui") or x:IsA("Frame") or x:IsA("UICorner")) then
				x:Destroy()
			end
		end
		c.Anchored = true
		-- (the eyes a little above the middle of the picture, the maw below them)
		c.CFrame = CFrame.new(-mid + Vector3.new(0, 0.35, 0))
		c.Parent = m
		-- (v156: his body is 14 skinned pieces around an invisible holder for the bones: each copied in where it sits)
		for _, piece in him:GetChildren() do
			if piece:IsA("MeshPart") and piece:GetAttribute("SkinPiece") then
				local pc = piece:Clone()
				for _, x in pc:GetChildren() do
					if not x:IsA("SurfaceAppearance") then
						x:Destroy()
					end
				end
				pc.Anchored = true
				pc.CFrame = c.CFrame * body.CFrame:ToObjectSpace(piece.CFrame)
				pc.Parent = m
			end
		end
		return m, c.CFrame
	end
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

-- one sound, played now (looped ones stop when told)
local function play(name: string, volume: number?, speed: number?): Sound?
	local snd = ctx.Effects and ctx.Effects.localSound(name)
	if not snd then
		return nil
	end
	if volume then
		snd.Volume = volume
	end
	if speed then
		snd.PlaybackSpeed = speed
	end
	snd:Play()
	if not snd.Looped then
		game:GetService("Debris"):AddItem(snd, 10)
	end
	return snd
end

-- a buzz in the hands (a controller's motors; a phone where Roblox allows it)
local function buzz(strength: number, seconds: number)
	pcall(function()
		local HS = game:GetService("HapticService")
		for _, input in { Enum.UserInputType.Gamepad1, Enum.UserInputType.Touch } do
			if HS:IsVibrationSupported(input) then
				for _, motor in { Enum.VibrationMotor.Large, Enum.VibrationMotor.Small } do
					if HS:IsMotorSupported(input, motor) then
						HS:SetMotor(input, motor, strength)
						task.delay(seconds, function()
							pcall(function()
								HS:SetMotor(input, motor, 0)
							end)
						end)
					end
				end
			end
		end
	end)
end

--[[
	The scare itself (v165, the owner: "make the jumpscare everyone much scarier"). Three beats, ~2.6 s:
	1. the dread: the screen dims and creeps with static, a low rumble and a heartbeat speeding up;
	2. the glimpses: dead black and silence, then his face far off in a cold light for two frames, black, closer, black;
	3. the slam: his face rushes the lens and fills the screen screaming, jaw dropped, the picture shaking itself apart,
	   a white hit-frame, red pulses and static tearing across, three screams layered, the controller / phone buzzing;
	   then a hard cut to black and the line saying who did it.
]]
function Prank.scare(from: string, text: string?)
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
	local dim = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1, Parent = gui })
	local vp = UI.new("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ImageTransparency = 1,
		Ambient = Color3.fromRGB(70, 80, 100),
		LightColor = Color3.fromRGB(200, 220, 255),
		LightDirection = Vector3.new(0.2, -0.9, -0.6),
		ZIndex = 2,
		Parent = gui,
	})
	-- static: a few grey bars that jump about
	local bars = {}
	for i = 1, 7 do
		bars[i] = UI.new("Frame", {
			Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Color3.fromRGB(200, 200, 200), BackgroundTransparency = 1,
			BorderSizePixel = 0, ZIndex = 4, Parent = gui,
		})
	end
	local red = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(160, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3, Parent = gui })
	local white = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5, Parent = gui })
	local cam = Instance.new("Camera")
	cam.FieldOfView = 55
	cam.Parent = vp
	vp.CurrentCamera = cam
	local mask = maskCopy()
	local jaws = {}
	if mask then
		mask.Parent = vp
		jaws = ctx.CreaturePose.jawMeshes(mask)
	end
	local rumble = play("Presence", 1.6)
	local heart = play("Heartbeat", 1, 1.1)
	-- the timeline (seconds from the start)
	local DREAD, BLACK, FAR, FAR_END, NEAR, NEAR_END, SLAM, CUT = 0, 0.85, 1.1, 1.18, 1.38, 1.46, 1.66, 2.55
	local slammed = false
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not gui.Parent then
			conn:Disconnect()
			return
		end
		local k = os.clock() - t0
		-- static bars: a little in the dread, a lot in the slam
		local staticAmt = (k < BLACK and math.clamp(k / BLACK, 0, 1) * 0.35) or (k >= SLAM and k < CUT and 0.8) or 0
		for _, b in bars do
			b.Visible = math.random() < staticAmt
			b.Position = UDim2.fromScale(0, math.random())
			b.Size = UDim2.new(1, 0, 0, math.random(2, 10))
			b.BackgroundTransparency = 0.35 + math.random() * 0.5
		end
		if k < BLACK then
			-- 1. the dread
			dim.BackgroundTransparency = 1 - 0.7 * math.clamp((k - DREAD) / BLACK, 0, 1)
			if heart then
				heart.PlaybackSpeed = 1.1 + k
			end
			vp.ImageTransparency = 1
		elseif k < SLAM then
			-- 2. black, silence, then the glimpses
			dim.BackgroundTransparency = 0
			if rumble and rumble.IsPlaying then
				rumble:Stop()
			end
			if heart and heart.IsPlaying then
				heart:Stop()
			end
			local d = nil
			if k >= FAR and k < FAR_END then
				d = 14
			elseif k >= NEAR and k < NEAR_END then
				d = 6.5
			end
			vp.ImageTransparency = d and 0 or 1
			if d then
				cam.CFrame = CFrame.lookAt(Vector3.new(0.3, 0.1, -d), Vector3.new(0, 0, 0))
				if mask and mask:FindFirstChild("Body") and ctx.Creature and ctx.Creature.poseCopy then
					ctx.Creature.poseCopy(mask, "Stare", k, 4, { Scream = 0 })
				end
				ctx.CreaturePose.setJaw(jaws, 0)
			end
		elseif k < CUT then
			-- 3. the slam
			if not slammed then
				slammed = true
				for _, name in { "Screech", "DemonScreech", "Jumpscare", "HorrorHitLow", "BoneRun" } do
					play(name)
				end
				buzz(1, 0.7)
				white.BackgroundTransparency = 0
				task.delay(0.05, function()
					white.BackgroundTransparency = 1
				end)
				if ctx.Effects then
					ctx.Effects.shake(1.6, 1)
				end
			end
			local s2 = k - SLAM
			vp.ImageTransparency = 0
			local lunge = 1 - (1 - math.min(s2 / 0.12, 1)) ^ 3
			local d = 5 - 3.5 * lunge
			local shakeA = 0.09 * (1 - math.min(s2 / 0.9, 1)) + 0.02
			local jerk = CFrame.Angles((math.random() - 0.5) * shakeA, (math.random() - 0.5) * shakeA, (math.random() - 0.5) * shakeA * 3)
			cam.CFrame = CFrame.lookAt(Vector3.new(0, -0.05, -d), Vector3.new(0, -0.05, 0)) * jerk
			cam.FieldOfView = 55 + 25 * (1 - lunge) - 6 * math.sin(s2 * 40)
			ctx.CreaturePose.setJaw(jaws, math.clamp(s2 / 0.1, 0, 1))
			if mask and mask:FindFirstChild("Body") and ctx.Creature and ctx.Creature.poseCopy then
				ctx.Creature.poseCopy(mask, "Stare", k, 4, { Scream = 1 })
			end
			-- the picture itself jumps about, and goes red in pulses
			local px = math.floor((math.random() - 0.5) * 40 * (1 - math.min(s2, 1)))
			local py = math.floor((math.random() - 0.5) * 30 * (1 - math.min(s2, 1)))
			vp.Position = UDim2.new(0.5, px, 0.5, py)
			vp.Size = UDim2.new(1.08, 0, 1.08, 0)
			vp.ImageColor3 = (math.floor(s2 * 14) % 2 == 0) and Color3.fromRGB(255, 200, 200) or Color3.new(1, 1, 1)
			red.BackgroundTransparency = 1 - 0.5 * math.max(0, math.sin(s2 * 22))
		else
			-- the hard cut
			vp.ImageTransparency = 1
			red.BackgroundTransparency = 1
			dim.BackgroundTransparency = 0
			for _, b in bars do
				b.Visible = false
			end
		end
	end)
	task.wait(CUT + 0.3)
	conn:Disconnect()
	if rumble then
		rumble:Destroy()
	end
	if heart then
		heart:Destroy()
	end
	UI.tween(dim, 0.45, { BackgroundTransparency = 1 })
	banner(gui, text or ("😱 " .. from .. " jumpscared everyone!"), 4)
	task.delay(5, function()
		gui:Destroy()
	end)
	task.wait(0.5)
	scaring = false
end
Prank._timeline = 2.85 -- (tests: how long the scare runs)

function Prank.init(c)
	ctx = c
	ctx.Prank = Prank
end

function Prank.start()
	local UI = ctx.UI
	if ctx.Mode == "Lobby" then
		if ctx.Dock then
			button = ctx.Dock.add({ Order = ctx.Dock.Order.Scare, Glyph = "😱", Label = "SCARE", Color = Color3.fromRGB(255, 96, 90), OnClick = buy })
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
			Parent = ctx.HUD and (ctx.HUD.OfferColumn or ctx.HUD.LeftColumn) or UI.Root,
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
	player:GetAttributeChangedSignal("PrankCredits"):Connect(refresh)
	workspace:GetAttributeChangedSignal("EndingActive"):Connect(refresh)
	ctx.Remotes.JumpscareAll.OnClientEvent:Connect(function(fromName: string, fromId: number, count: number?)
		if fromId == player.UserId then
			-- (v165, the owner: "make it so I can be jumpscared I can't even see how it is") the buyer gets it too, then the count
			local n = tostring(count or others())
			task.spawn(Prank.scare, fromName, "😈 You jumpscared " .. n .. (count == 1 and " player!" or " players!"))
			return
		end
		task.spawn(Prank.scare, fromName)
	end)
end

return Prank
