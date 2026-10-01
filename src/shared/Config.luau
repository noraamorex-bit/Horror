--[[
	Config — every tunable number in one place.
	Times are in seconds unless the name says otherwise.
]]

local Config = {}

Config.Debug = false -- true: act timings x0.25, verbose logging

-- "Lobby" or "Game" to force a server mode (e.g. to try the lobby in Studio). nil = automatic.
Config.ForceMode = nil :: string?

-- The lobby: queue circles that teleport a group into its own reserved game server.
Config.Lobby = {
	-- nil = the same place hosts both the lobby (public servers) and the game (reserved servers).
	-- If you later add a separate game place to this experience, put its PlaceId here.
	GamePlaceId = nil :: number?,
	LobbyPlaceId = nil :: number?,
	QueueSizes = { 1, 2, 3, 4 },
	Countdown = 10, -- seconds a full circle waits before teleporting (lets people step off)
	SoloCountdown = 3,
	ArrivalTimeout = 30, -- game server: start without stragglers after this long
	ReturnDelay = 45, -- game server: seconds on the ending screen before going back to the lobby
}

Config.MinPlayers = 1 -- 2-4 recommended; 1 is allowed so the game can be tested solo
Config.MaxPlayers = 4
Config.LobbyCountdown = 10

-- Act lengths in minutes. An act ends at Max, or earlier once its exit condition is met (never before Min).
Config.TimeScale = 1
Config.Acts = {
	Evening = { Min = 4, Max = 7 },
	SmallThings = { Min = 5, Max = 8 },
	SomeoneElse = { Min = 6, Max = 9 },
}
Config.HardCapMinutes = 60

-- The in-game clock starts at 8:47 PM and runs faster than real time.
Config.ClockStartMinutes = 20 * 60 + 47
Config.ClockRate = 1.5

Config.Movement = {
	Walk = 10,
	Crouch = 5,
	Sprint = 17,
	StaminaMax = 100,
	StaminaDrain = 14, -- per second while sprinting
	StaminaRegen = 9,
	RunnerDrainMultiplier = 0.6,
	CrouchCameraOffset = -1.6,
}

-- Noise radii (studs). The intruder hears anything inside the radius (x0.55 through a floor).
Config.Noise = {
	Crouch = 4,
	Walk = 16,
	Sprint = 38,
	RunnerSprint = 26,
	Door = 14,
	DoorSlam = 45,
	Microwave = 22,
	Knock = 50,
	Deadbolt = 20,
	GlassBreak = 140,
	PhoneCall = 30,
	Struggle = 30,
	GarageRelease = 70,
	GarageMotor = 90,
	Breathing = 9,
	Cough = 35,
	FloorDropMultiplier = 0.55,
}

Config.Nerve = {
	Max = 100,
	AloneDarkDrain = 0.55, -- per second, acts 2+
	AloneDrain = 0.15,
	NearFriendsRegen = 0.9,
	LitRegen = 0.35,
	SeeIntruder = 14, -- one-off hit
	SeeIntruderDrain = 2.5, -- per second while visible
	NearIntruderRadius = 24, -- him this close (same floor), seen or not...
	NearIntruderDrain = 2, -- ...drains up to twice this per second, the closer the more
	FriendCaptured = 20,
	ScareEvent = 6,
	FriendRadius = 28,
	Heavy = 40, -- below this: heavy breathing, tremor
	Panic = 15,
}

Config.Flashlight = {
	BatterySeconds = 480,
	Range = 48,
	Angle = 48,
	Brightness = 3.2,
}

Config.Intruder = {
	WalkSpeed = 9, -- lying low between hunts
	SneakSpeed = 6.5,
	ProwlSpeed = 15, -- running to where he feels you are (you sprint at 17, briefly)
	ChaseSpeed = 18, -- he can see you: faster than you, and he doesn't tire
	LungeSpeed = 22, -- the last few steps
	GrabRange = 5,
	FOV = 100, -- degrees
	SightLit = 80,
	SightDark = 22,
	SightFlashlight = 110, -- a flashlight in the dark gives you away from across the house
	CrouchSightMultiplier = 0.6,
	PeripheralRange = 7, -- sensed regardless of facing
	HearWalk = 11, -- walking (not crouched) this close: he notices you behind him
	HearSprint = 16, -- running
	HearFlashlight = 12, -- your beam on the walls around him
	SoloChaseSlowdown = 1, -- studs/s slower when playing alone
	ChaseLoseSightTime = 2.5, -- out of sight this long and he's back to following your trail
	-- what he knows
	SenseDelay = 3, -- he feels where you were this many seconds ago
	HideGrace = 8, -- after leaving a hiding spot, he can't feel you for this long
	-- searching hiding spots
	SearchChecks = 2,
	TrueSpotWeight = 1.5, -- the spot you're really in is this much likelier to be opened
	SeeHideCheckChance = 1, -- he saw you get in
	OpenFindChance = 0.75, -- he opens your spot without having seen you
	BreathHoldSave = 0.6, -- holding your breath cuts that by this much
	AmbushChance = 0.4, -- after a search: pretend to leave, wait round the corner
	AmbushTime = 9, -- (+0-5 s)
	-- between hunts
	WithdrawMin = 22,
	WithdrawMax = 34,
	WithdrawNotice = 30, -- seen this close while he's lying low, and he comes anyway
	StunTime = 7,
	RetreatAfterStun = 30,
	RetreatAfterCapture = 35,
	CaptiveCheckInterval = 150,
	ForceLockTime = 5,
	TrappedEscapeTime = 90,
	ThinkRate = 0.1,
}

Config.Hiding = {
	HoldBreathMax = 8,
	HoldBreathRecover = 1.5, -- seconds of recovery per second of breath
}

Config.Capture = {
	RescueHold = 5,
	RescueHoldTool = 2.5,
	StrugglePerPress = 1.1, -- percent
	StruggleNoiseEvery = 12, -- presses
	LastChance = 45, -- seconds everyone-captured players get to struggle free before the bad ending
}

Config.Help = {
	PhoneResponse = 150,
	NeighborResponse = 120,
	CarResponse = 60,
	CellCallDuration = 15,
	LandlineCallDuration = 6,
	NeighborWait = 15,
	JunctionRepair = 10,
}

-- The Director: tension ceilings per act, seconds between scheduled events, storm cadence
Config.Director = {
	Ceiling = { Evening = 25, SmallThings = 65, SomeoneElse = 85, Guest = 100 },
	Gap = {
		Evening = { 30, 55 },
		SmallThings = { 30, 50 },
		SomeoneElse = { 32, 55 },
		Guest = { 45, 80 },
	},
	TensionDecay = 0.5, -- per second
	Lightning = { 20, 50 },
	SmallThingsQuiet = 40, -- act II ends (after Min) once tension falls below this
}

-- Inner monologue: the character thinking out loud about what to do next
Config.Thoughts = {
	Duration = 5, -- seconds each line stays on screen
	IdleHint = 35, -- seconds without progress before they remind themselves of the next task
	FirstHint = 12, -- seconds into the night before the first task nudge
	QuietGap = 4, -- seconds of quiet after a thought or conversation before a text or banter comes in
}

Config.ChatRange = 50

-- Badges: create them in Creator Hub (Experience > Associated Items > Badges) and paste the
-- IDs here. Each ending awards its badge to everyone there; FirstNight goes to anyone who
-- finishes a night. Leave 0 to skip.
Config.Badges = {
	FirstNight = 0,
	Sirens = 0,
	CaseClosed = 0,
	NextDoor = 0,
	Taillights = 0,
	LockedIn = 0,
	Dawn = 0,
	GoneQuiet = 0,
	GotAway = 0,
}

Config.PepperSpray = {
	Uses = 2,
	Range = 12,
	ConeDegrees = 35,
}

if Config.Debug then
	Config.TimeScale = 0.25
end

return Config
