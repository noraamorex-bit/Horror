--[[
	NoiseService — gameplay noise (what the intruder can hear), separate from audio playback.
	Noise.emit(position, radius, kind, sourcePlayer?)
	Noise.listen(fn(event))
]]

local Noise = {}
local listeners = {}
local ctx

function Noise.init(c)
	ctx = c
end

function Noise.emit(position: Vector3, radius: number, kind: string, source: Player?)
	if radius <= 0 then
		return
	end
	local event = {
		Position = position,
		Radius = radius,
		Kind = kind,
		Source = source,
		Time = os.clock(),
	}
	for _, fn in listeners do
		task.spawn(fn, event)
	end
end

function Noise.listen(fn)
	table.insert(listeners, fn)
end

-- Effective radius at a listener position (floors dampen sound)
function Noise.heardAt(event, listenerPos: Vector3): boolean
	local r = event.Radius
	if ctx.Rooms.floorOf(event.Position) ~= ctx.Rooms.floorOf(listenerPos) then
		r *= ctx.Config.Noise.FloorDropMultiplier
	end
	return (event.Position - listenerPos).Magnitude <= r
end

return Noise
