--[[
	Prompts — interaction prompts use Roblox's standard ProximityPrompt UI (tap-safe on phones).
	This controller only switches prompts off locally when you can't use them: before the night
	starts, while hiding or captured, after escaping, and on the ending screen.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Prompts = {}
local ctx
local player = Players.LocalPlayer

local function updateEnabled()
	ProximityPromptService.Enabled = player:GetAttribute("InGame") == true
		and not player:GetAttribute("Hiding")
		and not player:GetAttribute("Captured")
		and not player:GetAttribute("Escaped")
		and not workspace:GetAttribute("EndingActive")
end

function Prompts.refresh()
	updateEnabled()
end

function Prompts.init(c)
	ctx = c
	ctx.Prompts = Prompts
end

function Prompts.start()
	for _, attr in { "InGame", "Hiding", "Captured", "Escaped" } do
		player:GetAttributeChangedSignal(attr):Connect(updateEnabled)
	end
	workspace:GetAttributeChangedSignal("EndingActive"):Connect(updateEnabled)
	updateEnabled()
end

return Prompts
