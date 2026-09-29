--[[
	Client bootstrap — builds the client context and starts every controller.
	The client only draws and sends intents; the server decides everything.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Controllers = script:WaitForChild("Controllers")

local ctx: any = { Player = Players.LocalPlayer }
ctx.Config = require(Shared.Config)
ctx.Remotes = require(Shared.Remotes)
ctx.Rooms = require(Shared.Rooms)
ctx.Sounds = require(Shared.Sounds)
ctx.Story = require(Shared.Story)
ctx.Util = require(Shared.Util)

-- the server tells us whether this is the lobby or a night in the house
local mode = workspace:GetAttribute("Mode")
while not mode do
	workspace:GetAttributeChangedSignal("Mode"):Wait()
	mode = workspace:GetAttribute("Mode")
end
ctx.Mode = mode

local ORDER = if mode == "Lobby"
	then { "UI", "Input", "Notice", "Effects", "Atmosphere", "LobbyHub" }
	else {
		"UI", "Input", "Notice", "Thoughts", "Effects", "Atmosphere", "Movement", "Prompts", "HUD",
		"Documents", "Phone", "HidingCam", "Lobby", "Ending", "MobileControls", "Markers", "Ambience",
	}

local modules = {}
for _, name in ORDER do
	modules[name] = require(Controllers:WaitForChild(name))
end
for _, name in ORDER do
	local m = modules[name]
	if m.init then
		m.init(ctx)
	end
end
for _, name in ORDER do
	local m = modules[name]
	if m.start then
		local ok, err = pcall(m.start)
		if not ok then
			warn("[HomeAlone] " .. name .. " failed to start: " .. tostring(err))
		end
	end
end

-- Core UI: no backpack or health bar, and no reset (it would break captures and hiding)
task.spawn(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, mode == "Lobby")
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCore("ResetButtonCallback", false)
		end)
		if ok then
			break
		end
		task.wait(0.5)
	end
end)
