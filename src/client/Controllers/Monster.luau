--[[
	Monster (client) — "Become him" (MonsterService).
	• The small BECOME HIM button under the inventory, while someone could buy it this night
	  (workspace BecomeHimOpen; free when you have a saved one: MonsterCredits). BE HIM NEXT NIGHT on
	  a co-op result card (Ending) buys one for the next night and uses it as soon as that night opens.
	• Once you're him: the camera follows him, your controls steer him (the move direction goes to
	  the server ten times a second), LUNGE / SEARCH (Shift / E, or the touch buttons), a slim bar
	  at the top, the dark lit up a little for you, and every noise a survivor makes shows up as a
	  red ping where it came from.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Monster = {}
local ctx
local player = Players.LocalPlayer

local state: any = nil
local buyButton: TextButton
local bar: Frame
local barLabel: TextLabel
local vision: ColorCorrectionEffect
local controls: any = nil
local lastSent = Vector3.zero
local sendClock = 0
local wantNext = false -- (BE HIM NEXT NIGHT, pressed on the result card)

function Monster.isActive(): boolean
	return state ~= nil and state.Active == true
end

local function moveVector(): Vector3
	if not controls then
		pcall(function()
			local pm = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: any)
			controls = pm:GetControls()
		end)
	end
	local mv = Vector3.zero
	if controls then
		pcall(function()
			mv = controls:GetMoveVector()
		end)
	end
	local cam = workspace.CurrentCamera
	if not cam or mv.Magnitude < 0.05 then
		return Vector3.zero
	end
	local w = cam.CFrame:VectorToWorldSpace(Vector3.new(mv.X, 0, mv.Z))
	local flat = Vector3.new(w.X, 0, w.Z)
	if flat.Magnitude < 0.01 then
		return Vector3.zero
	end
	return flat.Unit * math.min(1, mv.Magnitude)
end

local function ping(at: Vector3, radius: number?)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.2
	holder.Position = at
	local bb = Instance.new("BillboardGui")
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(46, 46)
	bb.LightInfluence = 0
	bb.Parent = holder
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromScale(0.4, 0.4)
	ring.BackgroundTransparency = 1
	ring.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 60, 60)
	stroke.Thickness = 3
	stroke.Parent = ring
	holder.Parent = workspace
	ctx.UI.tween(ring, 1.4, { Size = UDim2.fromScale(1, 1) })
	ctx.UI.tween(stroke, 1.4, { Transparency = 1 })
	Debris:AddItem(holder, 1.5)
end

local function refreshBuy()
	local open = workspace:GetAttribute("BecomeHimOpen") == true
	local canAct = player:GetAttribute("InGame") == true and not player:GetAttribute("Captured") and not player:GetAttribute("Dead")
		and not player:GetAttribute("Escaped") and not player:GetAttribute("Monster") and not player:GetAttribute("MonsterPending")
	buyButton.Visible = open and canAct
	local saved = (tonumber(player:GetAttribute("MonsterCredits")) or 0) > 0
	local price = ctx.Config.Shop.BecomeHim and ctx.Config.Shop.BecomeHim.Price or 50
	buyButton.Text = saved and "😈 BECOME HIM  (free)" or ("😈 BECOME HIM  R$ " .. tostring(price))
	-- said yes on last night's result card (BE HIM NEXT NIGHT): the saved one is used as soon as it can be
	-- (asked again on every change until the server says yes: MonsterPending / Monster)
	if player:GetAttribute("MonsterPending") or player:GetAttribute("Monster") then
		wantNext = false
	elseif wantNext and open and canAct and saved then
		ctx.Remotes.MonsterAction:FireServer("UseCredit")
	end
end

-- the result card's BE HIM NEXT NIGHT: free with a saved one, otherwise bought now (the server keeps
-- it as a saved one, the night being over) and used when the next night opens it
function Monster.wantNext()
	wantNext = true
	if (tonumber(player:GetAttribute("MonsterCredits")) or 0) <= 0 then
		local p = ctx.Config.Shop.BecomeHim
		if p and p.Id > 0 then
			pcall(function()
				MarketplaceService:PromptProductPurchase(player, p.Id)
			end)
		end
	end
	refreshBuy()
end

function Monster.wantsNext(): boolean
	return wantNext
end

local function render()
	local s = state
	local on = s ~= nil and s.Active == true
	bar.Visible = s ~= nil
	if not s then
		return
	end
	if s.Pending then
		barLabel.Text = "When the lights go out, you become HIM."
		return
	end
	local touch = ctx.UI.isTouch()
	local hint = touch and "LUNGE · SEARCH" or "Shift: LUNGE · E: SEARCH"
	barLabel.Text = string.format("YOU ARE HIM · caught %d · %s", s.Captures or 0, hint)
	vision.Enabled = on
end

Monster._refresh = function() -- (tests)
	refreshBuy()
end

function Monster.init(c)
	ctx = c
	ctx.MonsterUI = Monster
end

function Monster.start()
	local UI = ctx.UI
	buyButton = UI.new("TextButton", {
		Name = "BecomeHim",
		Size = UDim2.fromOffset(190, 34),
		Text = "",
		Font = UI.Font.Bold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 225, 225),
		BackgroundColor3 = Color3.fromRGB(110, 14, 18),
		BackgroundTransparency = 0.15,
		AutoButtonColor = true,
		LayoutOrder = 9,
		Visible = false,
		Parent = ctx.HUD and ctx.HUD.LeftColumn or UI.Root,
	})
	UI.corner(buyButton, 8)
	UI.stroke(buyButton, Color3.fromRGB(255, 120, 120), 1, 0.5)
	buyButton.Activated:Connect(function()
		if (tonumber(player:GetAttribute("MonsterCredits")) or 0) > 0 then
			ctx.Remotes.MonsterAction:FireServer("UseCredit")
			return
		end
		local p = ctx.Config.Shop.BecomeHim
		if p and p.Id > 0 then
			pcall(function()
				MarketplaceService:PromptProductPurchase(player, p.Id)
			end)
		end
	end)

	bar = UI.new("Frame", {
		Name = "MonsterBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 52),
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(70, 6, 10),
		BackgroundTransparency = 0.2,
		Visible = false,
		Parent = UI.Root,
	})
	UI.corner(bar, 8)
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = bar })
	barLabel = UI.new("TextLabel", {
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "",
		Font = UI.Font.Bold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 220, 220),
		Parent = bar,
	})

	vision = Instance.new("ColorCorrectionEffect")
	vision.Name = "MonsterVision"
	vision.Brightness = 0.12
	vision.Contrast = 0.15
	vision.Saturation = -0.4
	vision.TintColor = Color3.fromRGB(255, 205, 205)
	vision.Enabled = false
	vision.Parent = Lighting

	ctx.Remotes.Monster.OnClientEvent:Connect(function(s)
		if s == nil then
			state = nil
			vision.Enabled = false
			local cam = workspace.CurrentCamera
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if cam and hum then
				cam.CameraSubject = hum
			end
			render()
			refreshBuy()
			return
		end
		if s.Ping then
			if Monster.isActive() then
				ping(s.Ping, s.Radius)
			end
			return
		end
		state = s
		if s.Say and ctx.HUD then
			ctx.HUD.notify(s.Say, "info")
		end
		if s.Stunned and ctx.HUD then
			ctx.HUD.notify("Tasered! You can't move for a moment.", "danger")
		end
		local model = s.Model
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		local cam = workspace.CurrentCamera
		if s.Active and hum and cam then
			cam.CameraSubject = hum
			cam.CameraType = Enum.CameraType.Custom
		end
		render()
		refreshBuy()
	end)

	ctx.Input.on("Sprint", function(began)
		if began and Monster.isActive() then
			ctx.Remotes.MonsterAction:FireServer("Lunge")
		end
	end)
	ctx.Input.on("ExitHide", function(began)
		if began and Monster.isActive() then
			ctx.Remotes.MonsterAction:FireServer("Search")
		end
	end)
	ctx.Input.on("Lunge", function(began)
		if began and Monster.isActive() then
			ctx.Remotes.MonsterAction:FireServer("Lunge")
		end
	end)
	ctx.Input.on("Search", function(began)
		if began and Monster.isActive() then
			ctx.Remotes.MonsterAction:FireServer("Search")
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		if not Monster.isActive() then
			return
		end
		sendClock += dt
		local v = moveVector()
		if sendClock >= 0.1 and ((v - lastSent).Magnitude > 0.05 or (sendClock > 1 and v.Magnitude > 0)) then
			sendClock = 0
			lastSent = v
			ctx.Remotes.MonsterAction:FireServer("Move", v)
		end
	end)

	for _, a in { "InGame", "Captured", "Dead", "Escaped", "Monster", "MonsterPending", "MonsterCredits" } do
		player:GetAttributeChangedSignal(a):Connect(refreshBuy)
	end
	workspace:GetAttributeChangedSignal("BecomeHimOpen"):Connect(refreshBuy)
	refreshBuy()
	render()
end

return Monster
