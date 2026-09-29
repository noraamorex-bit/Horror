--[[
	PowerService — the house's electricity.

	Main breaker (garage) + per-room switches. Anything electric registers here and
	reacts to power changes: lights, TV, microwave, fridge hum, garage opener, Wi-Fi.
]]

local Power = {}
local ctx

local mainOn = true
local switches = {} -- room -> bool
local lights = {} -- { {Room, Bulb, Light, Brightness} }
local listeners = {}
local staticLit = {} -- room -> true (battery lanterns, fire, etc.)
local flickering = false

local OFF_COLOR = Color3.fromRGB(90, 88, 84)
local ON_COLOR = Color3.fromRGB(255, 236, 200)

function Power.init(c)
	ctx = c
end

function Power.reset()
	mainOn = true
	switches = {}
	lights = {}
	staticLit = {}
	flickering = false
	workspace:SetAttribute("Power", true)
	-- drop listeners that belonged to the old world
	local kept = {}
	for _, l in listeners do
		if not l.Owner then
			table.insert(kept, l)
		end
	end
	listeners = kept
end

local function applyLight(entry)
	local on = mainOn and switches[entry.Room] == true
	entry.Light.Enabled = on
	entry.Bulb.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
	entry.Bulb.Color = on and ON_COLOR or OFF_COLOR
end

local function refreshRoom(room)
	for _, entry in lights do
		if entry.Room == room then
			applyLight(entry)
		end
	end
end

local function refreshAll()
	for _, entry in lights do
		applyLight(entry)
	end
end

function Power.registerLight(room: string, bulb: BasePart, light: Light)
	local entry = { Room = room, Bulb = bulb, Light = light, Brightness = light.Brightness }
	table.insert(lights, entry)
	applyLight(entry)
end

function Power.registerSwitch(room: string, plate: BasePart)
	local prompt
	prompt = ctx.Interaction.prompt(plate, {
		Action = "Light switch",
		Object = ctx.Rooms.ByName[room] and ctx.Rooms.ByName[room].Display or room,
		Distance = 6,
	}, function(player)
		Power.setSwitch(room, not switches[room], player)
	end)
	return prompt
end

function Power.setSwitch(room: string, on: boolean, player: Player?)
	switches[room] = on
	refreshRoom(room)
	local r = ctx.Rooms.ByName[room]
	if r then
		ctx.Audio.playAt("LightSwitch", r.Center + Vector3.new(0, 5, 0), { Caption = false })
	end
	if player and not mainOn then
		ctx.Audio.caption("The switch clicks. Nothing happens.", nil, nil, { player })
	end
end

function Power.isOn(): boolean
	return mainOn
end

function Power.isRoomSwitchOn(room: string): boolean
	return switches[room] == true
end

function Power.setMain(on: boolean, reason: string?)
	if mainOn == on then
		return
	end
	mainOn = on
	refreshAll()
	workspace:SetAttribute("Power", on)
	for _, l in listeners do
		if not l.Owner or l.Owner.Parent then
			task.spawn(l.Fn, on, reason)
		end
	end
end

-- owner: optional world Instance; the listener is dropped when the world is rebuilt
function Power.onChanged(fn, owner: Instance?)
	table.insert(listeners, { Fn = fn, Owner = owner })
end

function Power.setStaticLit(room: string, lit: boolean)
	staticLit[room] = lit or nil
end

-- Is this position lit by the house lighting (not counting flashlights)?
function Power.isLit(pos: Vector3): boolean
	local room = ctx.Rooms.find(pos)
	if not room then
		return false
	end
	if staticLit[room.Name] then
		return true
	end
	return mainOn and switches[room.Name] == true and not flickering
end

-- Storm flicker: lights stutter, then return. Does not change the main breaker.
function Power.flicker(duration: number)
	if not mainOn or flickering then
		return
	end
	flickering = true
	local t0 = os.clock()
	local rng = Random.new()
	while os.clock() - t0 < duration and mainOn do
		local off = rng:NextNumber() < 0.55
		for _, entry in lights do
			if switches[entry.Room] then
				entry.Light.Enabled = not off
				entry.Bulb.Material = off and Enum.Material.SmoothPlastic or Enum.Material.Neon
			end
		end
		task.wait(rng:NextNumber(0.05, 0.25))
	end
	flickering = false
	refreshAll()
end

function Power.start()
	workspace:SetAttribute("Power", mainOn)
end

return Power
