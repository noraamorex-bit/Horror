--[[
	Sounds — the audio library.

	Id       : a Creator Store asset ("rbxassetid://123"). The ones set here are Roblox-licensed
	           ProSoundEffects sounds that any experience may use. "" = not chosen yet.
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
	Rain = { Id = "rbxassetid://9112853287", Volume = 0.8, Looped = true },
	RainWindow = { Id = "rbxassetid://9112856881", Volume = 0.6, Looped = true },
	-- APM (licensed for Roblox): "Solo Piano - Gentle Rain - Remastered", the cozy first act indoors
	CozyPiano = { Id = "rbxassetid://9046644321", Volume = 0.22, Looped = true },
	Wind = { Id = "rbxassetid://9120697823", Fallback = ENGINE_WIND, Volume = 0.12, Looped = true },
	Thunder = { Id = "rbxassetid://9120016037", Fallback = ENGINE_THUD, Volume = 1, Caption = "[Thunder]" },
	Thunder2 = { Id = "rbxassetid://9120016241", Fallback = ENGINE_THUD, Volume = 1, Caption = "[Thunder]" },
	Thunder3 = { Id = "rbxassetid://9120016256", Fallback = ENGINE_THUD, Volume = 1, Caption = "[Thunder]" },
	ThunderRumble = { Id = "rbxassetid://9120018695", Fallback = ENGINE_THUD, Volume = 0.6 },
	ClockTick = { Id = "", Volume = 0.25, Looped = true, Range = 30, Note = "grandfather clock tick" },
	ClockChime = { Id = "rbxassetid://9113816347", Fallback = ENGINE_BEEP, Volume = 0.5, Range = 120, Caption = "[The grandfather clock chimes]" },
	FridgeHum = { Id = "rbxassetid://9112889082", Volume = 0.06, Looped = true, Range = 20 },
	FireCrackle = { Id = "rbxassetid://9112780193", Volume = 0.55, Looped = true, Range = 30 },

	-- House
	Footstep = { Id = "rbxassetid://9120880067", Fallback = ENGINE_STEP, Volume = 0.9, Range = 70, Caption = "[Footsteps]" },
	FootstepsAbove = { Id = "rbxassetid://9114493393", Fallback = ENGINE_STEP, Volume = 1, Range = 90, Caption = "[Footsteps... above you]" },
	DoorOpen = { Id = "rbxassetid://9120839010", Volume = 0.6, Range = 45, Caption = "[A door creaks]" },
	DoorClose = { Id = "rbxassetid://9120839581", Fallback = ENGINE_THUD, Volume = 0.6, Range = 45, Caption = "[A door closes]" },
	DoorSlam = { Id = "rbxassetid://9114153270", Fallback = ENGINE_THUD, Volume = 1, Range = 110, Caption = "[A door SLAMS]" },
	DoorRattle = { Id = "rbxassetid://9114138011", Fallback = ENGINE_THUD, Volume = 0.7, Range = 50, Caption = "[A door handle rattles]" },
	Deadbolt = { Id = "rbxassetid://9114144264", Fallback = ENGINE_THUD, Volume = 0.6, Range = 30, Caption = "[Click of a deadbolt]" },
	DoorForce = { Id = "rbxassetid://9114129501", Fallback = ENGINE_THUD, Volume = 1, Range = 80, Caption = "[Someone is forcing a door]" },
	Knock = { Id = "rbxassetid://9120918417", Fallback = ENGINE_THUD, Volume = 1, Range = 60, Caption = "[Knocking]" },
	LightSwitch = { Id = "rbxassetid://9116284750", Fallback = ENGINE_THUD, Volume = 0.5, Range = 16 },
	Breaker = { Id = "rbxassetid://9119633359", Fallback = ENGINE_THUD, Pitch = 0.8, Volume = 1, Range = 70, Caption = "[A heavy clunk from the garage]" },
	PowerDown = { Id = "rbxassetid://9117871125", Volume = 0.8, Range = 200, Caption = "[Everything goes silent]" },
	PowerUp = { Id = "rbxassetid://9117882503", Volume = 0.6, Range = 200, Caption = "[The fridge hums back to life]" },
	MicrowaveHum = { Id = "rbxassetid://9114258913", Volume = 0.4, Looped = true, Range = 30, Caption = "[Microwave humming]" },
	MicrowaveBeep = { Id = "rbxassetid://9118777437", Fallback = ENGINE_BEEP, Volume = 0.6, Range = 50, Caption = "[Beep beep beep]" },
	Popcorn = { Id = "", Volume = 0.6, Range = 35, Caption = "[Popcorn popping]" },
	Faucet = { Id = "rbxassetid://9119153987", Fallback = ENGINE_SPLASH, Volume = 0.3, Range = 20, Caption = "[Running water]" },
	Toilet = { Id = "rbxassetid://9120106655", Fallback = ENGINE_SPLASH, Volume = 0.6, Range = 40, Caption = "[A toilet flushes]" },
	PhoneRing = { Id = "rbxassetid://9117305259", Fallback = ENGINE_BEEP, Volume = 1, Looped = true, Range = 120, Caption = "[The landline is ringing]" },
	DialTone = { Id = "rbxassetid://9125716553", Fallback = ENGINE_BEEP, Volume = 0.5, Range = 10 },
	TVStatic = { Id = "rbxassetid://9113115842", Volume = 0.3, Looped = true, Range = 40, Caption = "[TV static]" },
	TVShow = { Id = "rbxassetid://9114012077", Volume = 0.3, Looped = true, Range = 40, Caption = "[TV murmuring]" },
	TVAlert = { Id = "rbxassetid://9113089565", Fallback = ENGINE_BEEP, Volume = 0.7, Looped = true, Range = 60, Caption = "[EMERGENCY ALERT TONE]" },
	GarageMotor = { Id = "rbxassetid://9125699768", Volume = 0.8, Range = 120, Caption = "[Garage door motor grinding]" },
	GarageManual = { Id = "rbxassetid://9113560502", Fallback = ENGINE_THUD, Volume = 1, Range = 100, Caption = "[Metal screeching - the garage door]" },
	GlassBreak = { Id = "rbxassetid://9114590297", Fallback = ENGINE_THUD, Volume = 1, Range = 160, Caption = "[GLASS SHATTERS]" },
	CarEngine = { Id = "rbxassetid://9112952489", Volume = 0.8, Range = 150, Caption = "[A car engine starts]" },
	Siren = { Id = "rbxassetid://9117810961", Fallback = ENGINE_WIND, Volume = 1, Looped = true, Range = 400, Caption = "[Sirens]" },
	DogBark = { Id = "", Volume = 0.8, Range = 180, Caption = "[A dog barking next door]" },
	Floorboard = { Id = "rbxassetid://9114496277", Fallback = ENGINE_STEP, Volume = 0.8, Range = 60, Caption = "[A floorboard creaks]" },
	HatchCreak = { Id = "rbxassetid://9126263691", Fallback = ENGINE_THUD, Volume = 0.7, Range = 60, Caption = "[Something creaks in the ceiling]" },
	Doorbell = { Id = "rbxassetid://91808856778507", Fallback = ENGINE_BEEP, Volume = 1, Range = 120, Caption = "[The doorbell rings]" },
	Sting = { Id = "rbxassetid://9120769331", Volume = 0.8, Range = 40 },
	-- jump scares: loud, sudden, close
	PlateCrash = { Id = "rbxassetid://9114592102", Fallback = ENGINE_THUD, Volume = 1, Range = 140, Caption = "[CRASH - something shatters in the kitchen]" },
	CeilingThud = { Id = "rbxassetid://9113437538", Fallback = ENGINE_THUD, Volume = 1, Range = 90, Caption = "[A heavy THUD in the ceiling]" },
	WindowBang = { Id = "rbxassetid://9120752961", Fallback = ENGINE_THUD, Volume = 1, Range = 90, Caption = "[BANG BANG - someone slams on the window]" },
	DoorYank = { Id = "rbxassetid://9114129501", Fallback = ENGINE_THUD, Volume = 1, Range = 110, Caption = "[Someone is yanking at the door handle]" },
	ChairDrop = { Id = "rbxassetid://9113768971", Fallback = ENGINE_THUD, Volume = 1, Range = 100, Caption = "[Something heavy falls over]" },
	WindowClose = { Id = "rbxassetid://9119205658", Fallback = ENGINE_THUD, Volume = 0.6, Range = 30 },

	-- People
	Breathing = { Id = "rbxassetid://9116457539", Volume = 0.25, Looped = true, Range = 12 },
	Heartbeat = { Id = "", Fallback = ENGINE_THUD, Volume = 0.6, Pitch = 0.5 },
	Cough = { Id = "rbxassetid://9113948412", Fallback = ENGINE_THUD, Volume = 1, Range = 60, Caption = "[A man coughing and choking]" },
	Spray = { Id = "rbxassetid://9113044265", Fallback = ENGINE_SPLASH, Volume = 0.8, Range = 30, Caption = "[Pssshhht]" },
	ZipTie = { Id = "rbxassetid://9118047781", Fallback = ENGINE_THUD, Volume = 0.6, Range = 25, Caption = "[Zip ties ratchet]" },
	Struggle = { Id = "rbxassetid://9113535436", Fallback = ENGINE_THUD, Volume = 0.7, Range = 35, Caption = "[Muffled struggling]" },
	ManWhisper = { Id = "rbxassetid://9113585946", Volume = 0.6, Range = 14, Caption = "[A man's breathing, very close]" },
	PhoneVibrate = { Id = "", Fallback = ENGINE_BEEP, Volume = 0.3, Pitch = 1.5 },

	-- Interface / handling (mostly client-side)
	Pickup = { Id = "rbxassetid://9113849306", Volume = 0.5, Range = 20 },
	Paper = { Id = "rbxassetid://9125723307", Volume = 0.6 },
	FlashlightClick = { Id = "rbxassetid://9114479661", Volume = 0.6, Range = 15 },
	Matches = { Id = "rbxassetid://9120930385", Volume = 0.7, Range = 25 },
	LogDrop = { Id = "rbxassetid://9120871246", Volume = 0.7, Range = 30 },
	ObjectiveDone = { Id = "rbxassetid://9126073001", Volume = 0.35 },
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
