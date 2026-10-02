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
	"Knockdown", -- (direction: Vector3) shoved off your feet (your client owns your physics)
	"Queue", -- (state | nil) lobby: your queue circle
	"Thought", -- (text, hintKey?) your character thinking out loud
	"Dialogue", -- (line | nil) a conversation line, maybe with choices; nil closes the box
	"Intro", -- () the night's opening shot: the house from the street, and him in the window

	-- client -> server
	"Movement", -- ({Sprint, Crouch})
	"Flashlight", -- ()
	"UseItem", -- (itemName)
	"Ready", -- (bool)
	"Hide", -- ("Exit")
	"HoldBreath", -- (bool)
	"Struggle", -- ()
	"Phone", -- (action)
	"LeaveQueue", -- () lobby: step off your circle
	"DialogueChoice", -- (index) the line you picked
	"Jumpscare", -- (head part) he got you: the camera snaps to his face
	"Notice", -- ({Title, Body, Button}) a one-button card (first-night tips)
	"QuickPlay", -- (kind) lobby: "Solo" or "Group" walks you into a queue circle
	"SetBeam", -- (beamId) pick an unlocked flashlight colour
	"Unstuck", -- () wedged in the scenery: move me to the nearest open spot
	"PhoneReply", -- (index) the text you picked to send back
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
