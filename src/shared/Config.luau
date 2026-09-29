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
	Countdown = 6, -- seconds a full circle waits before teleporting (lets people step off)
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
	Evening = { Min = 6, Max = 10 },
	SmallThings = { Min = 10, Max = 13 },
	SomeoneElse = { Min = 8, Max = 13 },
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
	WalkSpeed = 9,
	SneakSpeed = 6.5,
	ChaseSpeed = 16.5,
	GrabRange = 5,
	FOV = 100, -- degrees
	SightLit = 80,
	SightDark = 22,
	SightFlashlight = 110,
	CrouchSightMultiplier = 0.6,
	PeripheralRange = 7, -- sensed regardless of facing
	ChaseMaxTime = 15,
	ChaseLoseSightTime = 4,
	StunTime = 7,
	RetreatAfterStun = 35,
	RetreatAfterCapture = 40,
	CaptiveCheckInterval = 150,
	ForceLockTime = 5,
	GroupWitnesses = 2, -- he won't grab in front of this many lit, alert witnesses
	SeeHideCheckChance = 1,
	RandomHideCheckChance = 0.3,
	LowNerveHideBonus = 0.25,
	FranticTime = 60,
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
	Ceiling = { Evening = 20, SmallThings = 55, SomeoneElse = 75, Guest = 100 },
	Gap = {
		Evening = { 60, 110 },
		SmallThings = { 28, 55 },
		SomeoneElse = { 30, 60 },
		Guest = { 45, 90 },
	},
	TensionDecay = 0.5, -- per second
	Lightning = { 20, 50 },
	SmallThingsQuiet = 40, -- act II ends (after Min) once tension falls below this
}

Config.ChatRange = 50

Config.PepperSpray = {
	Uses = 2,
	Range = 12,
	ConeDegrees = 35,
}

if Config.Debug then
	Config.TimeScale = 0.25
end

return Config
