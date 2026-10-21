--[[
	NightVision — the Night Vision pass's goggles (v108). While the player attribute NightVision is
	on (the server sets it from the goggles tool and drains NVLeft, 60 s a night), the screen goes
	the old green: brighter, high contrast, washed out, with a soft light around you that only you
	see (a light made here is local). Off again the moment the charge runs out or you put them away.
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local NightVision = {}
local ctx
local player = Players.LocalPlayer

local grade: ColorCorrectionEffect? = nil
local glow: PointLight? = nil
local on = false

local GREEN = Color3.fromRGB(120, 255, 140)

local function attachGlow()
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then
		return
	end
	if glow and glow.Parent == head then
		return
	end
	if glow then
		glow:Destroy()
	end
	local l = Instance.new("PointLight")
	l.Name = "NightVisionGlow"
	l.Color = GREEN
	l.Range = 34
	l.Brightness = 0
	l.Shadows = false
	l.Parent = head
	glow = l
end

function NightVision.set(want: boolean)
	if want == on then
		return
	end
	on = want
	local g = grade :: ColorCorrectionEffect
	attachGlow()
	local info = TweenInfo.new(want and 0.25 or 0.4)
	TweenService:Create(g, info, {
		Brightness = want and 0.22 or 0,
		Contrast = want and 0.35 or 0,
		Saturation = want and -0.75 or 0,
		TintColor = want and GREEN or Color3.new(1, 1, 1),
	}):Play()
	if glow then
		TweenService:Create(glow, info, { Brightness = want and 1.6 or 0 }):Play()
	end
	if want and ctx.Effects then
		pcall(ctx.Effects.playSound, "SwitchClick")
	end
end

function NightVision.isOn(): boolean
	return on
end

function NightVision.init(c)
	ctx = c
	ctx.NightVision = NightVision
end

function NightVision.start()
	local g = Instance.new("ColorCorrectionEffect")
	g.Name = "NightVision"
	g.Parent = Lighting
	grade = g
	local function sync()
		NightVision.set(player:GetAttribute("NightVision") == true)
	end
	player:GetAttributeChangedSignal("NightVision"):Connect(sync)
	player.CharacterAdded:Connect(function()
		glow = nil
		on = false
		task.defer(sync)
	end)
	sync()
end

return NightVision
