--[[
	Remotes — the single registry of RemoteEvents.
	The server creates them; clients wait for them. Use Remotes.<Name>.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NAMES = {
	-- server -> client
	"Caption", -- (text, position?, style?)
	"Objectives", -- (list)
	"Chapter", -- (title, subtitle)
	"Document", -- (docId)
	"Notify", -- (text, kind?)
	"Lightning", -- (intensity, thunderDelay)
	"PlaySound", -- (soundName, position?, opts?) local-only sound for one player
	"Fade", -- (toBlack: boolean, duration)
	"Shake", -- (magnitude, duration)
	"Ending", -- (payload)
	"Texts", -- (list of phone messages)
	"Lobby", -- (state)
	"Figure", -- (cframe, duration) a figure only this player sees

	-- client -> server
	"Movement", -- ({Sprint, Crouch})
	"Flashlight", -- ()
	"UseItem", -- (itemName)
	"Ready", -- (bool)
	"Hide", -- ("Exit")
	"HoldBreath", -- (bool)
	"Struggle", -- ()
	"Phone", -- (action)
}

local Remotes = {}

if RunService:IsServer() then
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in NAMES do
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
		Remotes[name] = remote
	end
else
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	for _, name in NAMES do
		Remotes[name] = folder:WaitForChild(name)
	end
end

return Remotes
