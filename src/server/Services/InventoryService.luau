--[[
	InventoryService — simple counted items per player, replicated as attributes
	("Item_Flashlight" = 1) so the client HUD can read them.
]]

local Players = game:GetService("Players")

local Inventory = {}
local ctx
local bags = {} -- player -> { item -> count }

Inventory.Display = {
	Flashlight = "Flashlight",
	Walkie = "Walkie-talkie",
	PepperSpray = "Pepper spray",
	HouseKeys = "House keys",
	CarKeys = "Car keys",
	BasementKey = "Basement key",
	ElectricalTape = "Electrical tape",
	Poker = "Fire poker",
	Multitool = "Multitool",
	Scissors = "Scissors",
	Batteries = "Batteries",
}

function Inventory.init(c)
	ctx = c
	Players.PlayerRemoving:Connect(function(p)
		bags[p] = nil
	end)
end

local function sync(player: Player, item: string)
	local bag = bags[player]
	local n = bag and bag[item] or 0
	player:SetAttribute("Item_" .. item, n > 0 and n or nil)
end

function Inventory.give(player: Player, item: string, count: number?)
	bags[player] = bags[player] or {}
	local bag = bags[player]
	bag[item] = (bag[item] or 0) + (count or 1)
	if item == "Batteries" then
		-- batteries go straight into the flashlight
		bag[item] = nil
		player:SetAttribute("Battery", 100)
	end
	sync(player, item)
end

function Inventory.take(player: Player, item: string, count: number?): boolean
	local bag = bags[player]
	if not bag or (bag[item] or 0) < (count or 1) then
		return false
	end
	bag[item] -= (count or 1)
	if bag[item] <= 0 then
		bag[item] = nil
	end
	sync(player, item)
	return true
end

function Inventory.has(player: Player, item: string): boolean
	local bag = bags[player]
	return bag ~= nil and (bag[item] or 0) > 0
end

function Inventory.count(player: Player, item: string): number
	local bag = bags[player]
	return bag and bag[item] or 0
end

function Inventory.clear(player: Player)
	local bag = bags[player]
	if bag then
		for item in bag do
			player:SetAttribute("Item_" .. item, nil)
		end
	end
	bags[player] = {}
end

-- Anyone in the session holding an item?
function Inventory.holders(item: string): { Player }
	local out = {}
	for p, bag in bags do
		if (bag[item] or 0) > 0 then
			table.insert(out, p)
		end
	end
	return out
end

function Inventory.reset()
	for p in bags do
		Inventory.clear(p)
	end
	bags = {}
end

return Inventory
