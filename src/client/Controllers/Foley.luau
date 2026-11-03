--[[
	Foley (v139, the owner: "Add more sound effects for the smaller things too"): the little sounds of
	your own hands, played only for you and kept quiet (the house's big sounds stay the server's):
	  • a prompt you use: a click, a rummage, a page, a keypad beep... by what it says (holds start
	    with their sound, quick ones sound when done)
	  • taking an item out of your pocket / putting it back (the flashlight clicks, the rest rustle)
	  • the phone coming out and going away
	  • crouching and standing (a floorboard under a knee)
	  • landing from a jump or a drop (a thud, louder the further you fell)
	Never while hiding, tied up or out of the night; at most one every 0.12 s.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Foley = {}
local ctx
local player = Players.LocalPlayer
local lastAt = 0

-- what a prompt's action sounds like (lowercase keyword in its ActionText -> sound, volume, when)
Foley.Prompt = {
	{ "search", "DrawerOpen", 0.35, "Hold" },
	{ "look", "Paper", 0.3 },
	{ "inspect", "Paper", 0.3 },
	{ "read", "Paper", 0.4 },
	{ "enter code", "CountBeep", 0.25 },
	{ "press", "SwitchClick", 0.35 },
	{ "flip", "BreakerClick", 0.4 },
	{ "light switch", "SwitchClick", 0.35 },
	{ "turn on", "SwitchClick", 0.35 },
	{ "splice", "TapeRip", 0.35, "Hold" },
	{ "cut", "ScissorsSnip", 0.4, "Hold" },
	{ "take", "Pickup", 0.25 },
	{ "pick up", "Pickup", 0.25 },
	{ "put down", "ToolDrop", 0.2 },
	{ "sit", "BedCreak", 0.25 },
	{ "drive", "KeysJingle", 0.35 },
}
-- prompts whose own sounds come from the server (doors, hiding spots, the 911 call...)
local SKIP = { open = true, close = true, hide = true, ["call 911"] = true, knock = true, ["answer the door"] = true }

local ITEM = {
	Flashlight = { "FlashlightOn", 0.25 },
	NightVision = { "SwitchClick", 0.35 },
	Taser = { "SwitchClick", 0.35 },
	Rocket = { "ToolDrop", 0.2 },
}

local function ok(): boolean
	return player:GetAttribute("InGame") == true and not player:GetAttribute("Hiding") and not player:GetAttribute("Captured")
		and not player:GetAttribute("Dead") and not player:GetAttribute("Escaped")
end

function Foley.play(name: string, volume: number?, pitch: number?)
	if os.clock() - lastAt < 0.12 or not ctx.Effects or not ok() then
		return false
	end
	lastAt = os.clock()
	ctx.Effects.playSound(name, nil, { Volume = volume or 0.3, Caption = false })
	return true
end

-- the sound for a prompt's action text, or nil
function Foley.forAction(text: string?): (string?, number?, string?)
	local t = string.lower(tostring(text or ""))
	if SKIP[t] then
		return nil
	end
	for _, e in Foley.Prompt do
		if string.find(t, e[1], 1, true) then
			return e[2], e[3], e[4]
		end
	end
	return nil
end

function Foley.phone(open: boolean)
	Foley.play(open and "Pickup" or "ToolDrop", open and 0.22 or 0.14)
end

function Foley.crouch(down: boolean)
	Foley.play("Floorboard", down and 0.2 or 0.14)
end

local function watchCharacter(char: Model)
	-- items out of your pocket and back
	char.ChildAdded:Connect(function(c)
		if c:IsA("Tool") then
			local s = ITEM[tostring(c:GetAttribute("ItemId") or c.Name)]
			Foley.play(s and s[1] or "Pickup", s and s[2] or 0.22)
		end
	end)
	char.ChildRemoved:Connect(function(c)
		if c:IsA("Tool") and c.Parent and c.Parent:IsA("Backpack") then
			Foley.play("ToolDrop", 0.1)
		end
	end)
	-- landing: a thud for a real drop (stairs don't count)
	local hum = char:WaitForChild("Humanoid", 10)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not hum or not root then
		return
	end
	local fallFrom: number? = nil
	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Freefall then
			fallFrom = (root :: BasePart).Position.Y
		elseif new == Enum.HumanoidStateType.Landed and fallFrom then
			local drop = fallFrom - (root :: BasePart).Position.Y
			fallFrom = nil
			if drop > 2.5 then
				Foley.play("Footstep", math.clamp(0.25 + drop * 0.05, 0.25, 0.7))
			end
		end
	end)
end

function Foley.init(c)
	ctx = c
	ctx.Foley = Foley
end

function Foley.start()
	if ctx.Mode == "Lobby" then
		return
	end
	pcall(function()
		ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
			local name, vol, when = Foley.forAction(prompt.ActionText)
			if name and when == "Hold" then
				Foley.play(name, vol)
			end
		end)
	end)
	pcall(function() -- (the test harness has no prompt service events)
		ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
			if who ~= nil and who ~= player then
				return
			end
			local name, vol, when = Foley.forAction(prompt.ActionText)
			if name and when ~= "Hold" then
				Foley.play(name, vol)
			end
		end)
	end)
	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
	player.CharacterAdded:Connect(watchCharacter)
end

return Foley
