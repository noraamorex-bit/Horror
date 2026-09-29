--[[
	Sounds — the audio library.

	Id       : your uploaded / Creator Store asset ("rbxassetid://123"). Leave "" until imported.
	Fallback : a built-in engine sound used when Id is empty (may be nil).
	Caption  : shown to players who hear it. Captions always show, so the game is fully
	           playable (and accessible) before any audio is imported.

	Suggested searches for the Creator Store are in the Note fields.
]]

local Sounds = {}

local ENGINE_STEP = "rbxasset://sounds/action_footsteps_plastic.mp3"
local ENGINE_THUD = "rbxasset://sounds/action_jump_land.mp3"
local ENGINE_WIND = "rbxasset://sounds/action_falling.mp3"
local ENGINE_BEEP = "rbxasset://sounds/electronicpingshort.wav"
local ENGINE_SPLASH = "rbxasset://sounds/impact_water.mp3"

Sounds.Library = {
	-- Ambience (client, looped)
	Rain = { Id = "", Volume = 0.5, Looped = true, Note = "heavy rain loop" },
	Wind = { Id = "", Fallback = ENGINE_WIND, Volume = 0.15, Looped = true, Note = "wind howl loop" },
	Thunder = { Id = "", Fallback = ENGINE_THUD, Volume = 1, Pitch = 0.3, Caption = "[Thunder]", Note = "distant thunder" },
	ClockTick = { Id = "", Volume = 0.25, Looped = true, Range = 30, Note = "grandfather clock tick" },
	ClockChime = { Id = "", Fallback = ENGINE_BEEP, Pitch = 0.4, Volume = 0.5, Range = 120, Caption = "[The grandfather clock chimes]" },
	FridgeHum = { Id = "", Volume = 0.2, Looped = true, Range = 20, Note = "refrigerator hum" },
	FireCrackle = { Id = "", Volume = 0.5, Looped = true, Range = 30, Note = "fireplace crackle" },

	-- House
	Footstep = { Id = "", Fallback = ENGINE_STEP, Volume = 0.9, Range = 70, Caption = "[Footsteps]" },
	FootstepsAbove = { Id = "", Fallback = ENGINE_STEP, Volume = 1, Range = 90, Pitch = 0.8, Caption = "[Footsteps... above you]" },
	DoorOpen = { Id = "", Volume = 0.6, Range = 45, Caption = "[A door creaks]", Note = "door creak open" },
	DoorClose = { Id = "", Fallback = ENGINE_THUD, Volume = 0.6, Range = 45, Caption = "[A door closes]" },
	DoorSlam = { Id = "", Fallback = ENGINE_THUD, Volume = 1, Range = 110, Caption = "[A door SLAMS]" },
	DoorRattle = { Id = "", Fallback = ENGINE_THUD, Volume = 0.7, Pitch = 1.6, Range = 50, Caption = "[A door handle rattles]" },
	Deadbolt = { Id = "", Fallback = ENGINE_THUD, Pitch = 2, Volume = 0.6, Range = 30, Caption = "[Click of a deadbolt]" },
	DoorForce = { Id = "", Fallback = ENGINE_THUD, Volume = 1, Pitch = 0.7, Range = 80, Caption = "[Someone is forcing a door]" },
	Knock = { Id = "", Fallback = ENGINE_THUD, Volume = 1, Pitch = 1.3, Range = 60, Caption = "[Knocking]" },
	LightSwitch = { Id = "", Fallback = ENGINE_THUD, Pitch = 3, Volume = 0.3, Range = 16 },
	Breaker = { Id = "", Fallback = ENGINE_THUD, Pitch = 0.6, Volume = 1, Range = 70, Caption = "[A heavy clunk from the garage]" },
	PowerDown = { Id = "", Volume = 0.6, Range = 200, Caption = "[Everything goes silent]" },
	PowerUp = { Id = "", Volume = 0.6, Range = 200, Caption = "[The fridge hums back to life]" },
	MicrowaveHum = { Id = "", Volume = 0.4, Looped = true, Range = 30, Caption = "[Microwave humming]" },
	MicrowaveBeep = { Id = "", Fallback = ENGINE_BEEP, Volume = 0.6, Range = 50, Caption = "[Beep beep beep]" },
	Popcorn = { Id = "", Volume = 0.6, Range = 35, Caption = "[Popcorn popping]" },
	Faucet = { Id = "", Fallback = ENGINE_SPLASH, Volume = 0.3, Range = 20, Caption = "[Running water]" },
	Toilet = { Id = "", Fallback = ENGINE_SPLASH, Volume = 0.6, Pitch = 0.6, Range = 40, Caption = "[A toilet flushes]" },
	PhoneRing = { Id = "", Fallback = ENGINE_BEEP, Volume = 1, Looped = true, Range = 120, Caption = "[The landline is ringing]" },
	DialTone = { Id = "", Fallback = ENGINE_BEEP, Volume = 0.4, Pitch = 0.5, Range = 8 },
	TVStatic = { Id = "", Volume = 0.35, Looped = true, Range = 40, Caption = "[TV static]" },
	TVShow = { Id = "", Volume = 0.35, Looped = true, Range = 40, Caption = "[TV murmuring]" },
	TVAlert = { Id = "", Fallback = ENGINE_BEEP, Volume = 0.8, Pitch = 0.7, Looped = true, Range = 60, Caption = "[EMERGENCY ALERT TONE]" },
	GarageMotor = { Id = "", Volume = 0.8, Range = 120, Caption = "[Garage door motor grinding]" },
	GarageManual = { Id = "", Fallback = ENGINE_THUD, Volume = 1, Range = 100, Caption = "[Metal screeching - the garage door]" },
	GlassBreak = { Id = "", Fallback = ENGINE_THUD, Volume = 1, Pitch = 1.8, Range = 160, Caption = "[GLASS SHATTERS]" },
	CarEngine = { Id = "", Volume = 0.8, Range = 150, Caption = "[A car engine starts]" },
	Siren = { Id = "", Fallback = ENGINE_WIND, Volume = 1, Pitch = 2, Looped = true, Range = 400, Caption = "[Sirens]" },
	DogBark = { Id = "", Volume = 0.8, Range = 180, Caption = "[A dog barking next door]" },
	Floorboard = { Id = "", Fallback = ENGINE_STEP, Volume = 0.8, Pitch = 0.5, Range = 60, Caption = "[A floorboard creaks]" },
	HatchCreak = { Id = "", Fallback = ENGINE_THUD, Pitch = 0.5, Volume = 0.6, Range = 60, Caption = "[Something creaks in the ceiling]" },

	-- People
	Breathing = { Id = "", Volume = 0.35, Looped = true, Range = 12, Note = "heavy nervous breathing" },
	Heartbeat = { Id = "", Fallback = ENGINE_THUD, Volume = 0.6, Pitch = 0.5 },
	Cough = { Id = "", Fallback = ENGINE_THUD, Pitch = 0.4, Volume = 1, Range = 60, Caption = "[A man coughing and choking]" },
	Spray = { Id = "", Fallback = ENGINE_SPLASH, Pitch = 2.5, Volume = 0.8, Range = 30, Caption = "[Pssshhht]" },
	ZipTie = { Id = "", Fallback = ENGINE_THUD, Pitch = 2.5, Volume = 0.6, Range = 25, Caption = "[Zip ties ratchet]" },
	Struggle = { Id = "", Fallback = ENGINE_THUD, Pitch = 1.4, Volume = 0.7, Range = 35, Caption = "[Muffled struggling]" },
	ManWhisper = { Id = "", Volume = 0.5, Range = 14, Caption = "[A man's voice, very close]" },
	PhoneVibrate = { Id = "", Fallback = ENGINE_BEEP, Volume = 0.3, Pitch = 1.5 },
}

function Sounds.get(name: string)
	return Sounds.Library[name]
end

function Sounds.resolve(name: string): string?
	local def = Sounds.Library[name]
	if not def then
		return nil
	end
	if def.Id ~= nil and def.Id ~= "" then
		return def.Id
	end
	return def.Fallback
end

return Sounds
