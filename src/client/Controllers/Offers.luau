--[[
	Offers — things you can buy on the spot, in the night.
	• 🚀 ROCKET (R$ 25, "Rocket (tonight)"): during the hunt, for anyone without a rocket in hand. A
	  small button under the inventory (never in the middle of the screen).
	• When someone knocks him flat with a rocket, everyone hears about it ("Sam knocked him flat with a
	  ROCKET LAUNCHER!") and the button pulses for a moment.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Offers = {}
local ctx
local player = Players.LocalPlayer

local rocketButton: TextButton

local HUNT = { SomeoneElse = true, Guest = true }

local function refresh()
	if not rocketButton then
		return
	end
	local p = ctx.Config.Shop.RocketNight
	local canAct = player:GetAttribute("InGame") == true and not player:GetAttribute("Captured") and not player:GetAttribute("Dead")
		and not player:GetAttribute("Escaped") and not player:GetAttribute("Monster")
	local hunt = HUNT[workspace:GetAttribute("Act") or ""] == true and not workspace:GetAttribute("EndingActive")
	rocketButton.Visible = p ~= nil and p.Id > 0 and canAct and hunt and not player:GetAttribute("Item_Rocket")
	rocketButton.Text = "🚀 ROCKET  R$ " .. tostring(p and p.Price or 25)
end

Offers._refresh = refresh -- (tests)

function Offers.isRocketShown(): boolean
	return rocketButton ~= nil and rocketButton.Visible
end

-- someone hit him with a rocket
function Offers.rocketHit(shooter: string)
	if shooter == player.DisplayName then
		return
	end
	if ctx.HUD then
		ctx.HUD.notify(shooter .. " knocked him flat with a ROCKET LAUNCHER!", "info")
	end
	refresh()
	if rocketButton and rocketButton.Visible then
		local base = rocketButton.BackgroundColor3
		rocketButton.BackgroundColor3 = Color3.fromRGB(230, 120, 30)
		ctx.UI.tween(rocketButton, 1.2, { BackgroundColor3 = base })
	end
end

function Offers.init(c)
	ctx = c
	ctx.Offers = Offers
end

function Offers.start()
	local UI = ctx.UI
	rocketButton = UI.new("TextButton", {
		Name = "RocketOffer",
		Size = UDim2.fromOffset(190, 34),
		Text = "",
		Font = UI.Font.Bold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 236, 214),
		BackgroundColor3 = Color3.fromRGB(110, 52, 10),
		BackgroundTransparency = 0.15,
		AutoButtonColor = true,
		LayoutOrder = 8,
		Visible = false,
		Parent = ctx.HUD and ctx.HUD.LeftColumn or UI.Root,
	})
	UI.corner(rocketButton, 8)
	UI.stroke(rocketButton, Color3.fromRGB(255, 180, 110), 1, 0.5)
	rocketButton.Activated:Connect(function()
		local p = ctx.Config.Shop.RocketNight
		if p and p.Id > 0 then
			pcall(function()
				MarketplaceService:PromptProductPurchase(player, p.Id)
			end)
		end
	end)
	for _, a in { "InGame", "Captured", "Dead", "Escaped", "Monster", "Item_Rocket" } do
		player:GetAttributeChangedSignal(a):Connect(refresh)
	end
	workspace:GetAttributeChangedSignal("Act"):Connect(refresh)
	workspace:GetAttributeChangedSignal("EndingActive"):Connect(refresh)
	refresh()
end

return Offers
