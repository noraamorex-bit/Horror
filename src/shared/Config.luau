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
	FillWait = 45, -- a group circle that isn't full starts anyway, with whoever's there, after this long
	StartNowAfter = 8, -- (and anyone in it can press START NOW after this long)
	ArrivalTimeout = 30, -- game server: start without stragglers after this long
	ReturnDelay = 45, -- game server: seconds on the ending screen before going back to the lobby
}

-- The owner's test panel (AdminService): these UserIds (plus the experience owner, plus Studio).
Config.Admins = { 915496194 }

Config.MinPlayers = 1 -- 2-4 recommended; 1 is allowed so the game can be tested solo
Config.MaxPlayers = 4
Config.LobbyCountdown = 10

-- Act lengths in minutes. An act ends at Max, or earlier once its exit condition is met (never before Min).
Config.TimeScale = 1
Config.Acts = {
	-- (kept short: the cozy part sets the mood, but players came for him)
	Evening = { Min = 2.5, Max = 5 },
	SmallThings = { Min = 4, Max = 6 },
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
	--[[
		Brain = "Figure": the hunt works like the Figure in DOORS. He hunts by SOUND. He walks a
		patrol between rooms; a quiet noise (a door, a lock, the microwave) makes him growl and come
		to look; a loud one (anyone walking or running near him, glass, a slam) makes him roar and
		CHARGE at it, re-aiming at every new footstep, then thrash around where it came from,
		grabbing whatever he runs into. Crouch and you're silent. Hide near him and he stops at your
		hiding spot to listen: keep your heartbeat steady (the heartbeat minigame) or he rips the
		door open. His sight is short (a dark house, a mask): close up, or your flashlight.
		"Classic" is the older brain (he always feels roughly where you are).
	]]
	Brain = "Figure",
	-- (his speeds: all of them a little under your walking pace, 10. He gets you by surprise, in a dead
	-- end, in your hiding spot, or because you froze; not by outrunning you)
	ChargeSpeed = 9, -- going for a sound he's sure of (you walk at 10, sprint at 17)
	InvestigateSpeed = 8,
	ChargeSearchTime = 5, -- thrashing about where the noise was, after a charge
	InvestigateSearchTime = 6,
	InspectTime = { 6, 9 }, -- standing at your hiding spot, listening
	InspectNearChance = 0.25, -- walking right past an occupied spot (not holding breath): he stops
	WalkSpeed = 7, -- lying low between hunts
	SneakSpeed = 5,
	ProwlSpeed = 9, -- (Classic brain) going to where he feels you are
	ChaseSpeed = 9, -- he can see you: just under your walking pace, and he never stops
	LungeSpeed = 9.5, -- the last few steps
	MaxSpeed = 9.8, -- a hard cap on all of the above: never as fast as your walk
	GrabRange = 4.5,
	FOV = 90, -- degrees
	-- (short sight: he hunts by sound. Lit rooms and your beam still give you away)
	SightLit = 28,
	SightDark = 10,
	SightFlashlight = 40, -- a flashlight in the dark gives you away
	CrouchSightMultiplier = 0.6,
	PeripheralRange = 7, -- sensed regardless of facing
	HearWalk = 10, -- walking (not crouched) this close: he notices you behind him
	HearSprint = 16, -- running
	HearFlashlight = 12, -- your beam on the walls around him
	SoloChaseSlowdown = 0.5, -- studs/s slower when playing alone
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
	-- between hunts: a short breather near the players' floor, then he patrols
	WithdrawMin = 14,
	WithdrawMax = 22,
	WithdrawNotice = 30, -- seen this close while he's lying low, and he comes anyway
	StunTime = 7,
	RetreatAfterStun = 30,
	RetreatAfterCapture = 14, -- after a capture he walks off somewhere far from the boiler room
	CaptiveGrace = 45, -- and for this long ignores the basement (struggling, rescues): the rescue window
	-- patrolling (nobody to sense): he sweeps the rooms you were last in, listening
	PatrolSpeed = 7.5,
	PatrolPause = { 1.5, 3 },
	PatrolCheckChance = 0.25, -- at each stop: tear open a hiding spot nearby
	PatrolCaptiveCheck = 90, -- with someone tied up: back past the boiler room this often
	RescueNoise = 45, -- cutting a friend free: he hears it this far away
	StuckRelocate = 20, -- no real progress this long (nobody watching): he moves through the walls
	BasementIdle = 40, -- in the basement with nobody (and no captive) there: he comes back up
	CaptiveCheckInterval = 150,
	ForceLockTime = 5,
	TrappedEscapeTime = 90,
	ThinkRate = 0.1,
}

-- Difficulty (voted before the night): Hard overrides these. Intruder keys override Config.Intruder.
Config.Difficulty = {
	VoteTime = 12,
	Hard = {
		Intruder = {
			WalkSpeed = 7.5,
			PatrolSpeed = 8,
			ProwlSpeed = 9.6,
			ChaseSpeed = 9.6, -- (Hard: a hair under your walking pace; stop or stumble and he's on you)
			LungeSpeed = 9.9,
			SenseDelay = 2,
			HideGrace = 6,
			OpenFindChance = 0.85,
			SearchChecks = 3,
			AmbushChance = 0.55,
			WithdrawMin = 8,
			WithdrawMax = 14,
			RetreatAfterCapture = 8,
			CaptiveGrace = 30,
			-- (Hard keeps the sharper senses Normal had before it was eased)
			SightLit = 32,
			SightFlashlight = 45,
			GrabRange = 5,
			HearWalk = 11,
			PatrolCheckChance = 0.4,
			SoloChaseSlowdown = 0.3,
			ChargeSpeed = 9.6,
			InvestigateSpeed = 8.5,
			InspectNearChance = 0.5,
		},
		Heartbeat = { Interval = 0.8, Misses = 2, Window = 0.22 },
		BatteryMultiplier = 0.7, -- flashlights die faster
		PoliceMultiplier = 1.25, -- help takes longer to arrive
		LastChance = 30,
	},
}

-- The heartbeat minigame (DOORS-style): he's listening at your hiding spot. Half-hearts fly in
-- from the left and the right; press that side as each one reaches the heart. Miss too many and
-- he hears you. (Hard: Config.Difficulty.Hard.Heartbeat overrides.)
Config.Heartbeat = {
	Interval = 1.0, -- seconds between beats
	Travel = 0.9, -- how long a half-heart takes to fly in
	Window = 0.26, -- seconds either side of arrival that count (a little forgiving on touch screens)
	Lead = 1.2, -- the heart shows this long before the first beat
	Misses = 3, -- this many misses and he hears you
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
	FirstNight = 409399923712093,
	Sirens = 3788492021707417,
	CaseClosed = 1030736154491153,
	NextDoor = 3075408998090267,
	Taillights = 907725296038042,
	LockedIn = 846738538364517,
	Dawn = 4397989281257179,
	GoneQuiet = 2732889922402301,
	GotAway = 1526454404455151,
	HardSurvivor = 3696145087218819, -- survived a night on Hard
	Rescuer = 1978303375336712, -- cut a friend free
	NotYourFamily = 892775622827536, -- the secret ending, out from under the house
	ForeverFamily = 2482890253693907, -- the secret ending, nobody left the table
}

--[[
	Shop (server/Services/ShopService, client/Controllers/Shop). Game passes and donation products
	are created in the Creator Hub (Monetization); paste their IDs here. Id 0 = not set up yet:
	the item still shows in the shop, marked "Soon". Price is only shown until Roblox reports the
	real one.
]]
Config.Shop = {
	Passes = {
		{ Key = "Supporter", Id = 2008280313, Price = 10, Name = "Supporter", Desc = "A SUPPORTER tag in the lobby, a gold flashlight and a star on the donation board." },
		{ Key = "Colours", Id = 2005832310, Price = 15, Name = "Flashlight colours", Desc = "Every flashlight colour, plus the pale Ghost beam." },
		{ Key = "ChooseRole", Id = 2006193593, Price = 15, Name = "Pick your role", Desc = "Choose who you play each night: Jamie, Riley, Morgan or Casey." },
		{ Key = "Marathon", Id = 2005053525, Price = 20, Name = "Marathon", Desc = "Sprint for longer: your stamina drains much slower." },
		{ Key = "Battery", Id = 2005388315, Price = 25, Name = "Long-life battery", Desc = "Your flashlight battery lasts twice as long." },
		{ Key = "HeadStart", Id = 2006721483, Price = 25, Name = "Head start", Desc = "Start every night with a flashlight in your pocket." },
		{ Key = "PepperSpray", Id = 2006030307, Price = 35, Name = "Pepper spray", Desc = "Start every night with a can of pepper spray (one use)." },
	},
	-- bought on the spot after you die: back into this night, somewhere away from him
	Revive = { Id = 3716706476, Price = 25, Window = 15, Grace = 10 },
	Donations = {
		{ Id = 3716700047, Amount = 5 },
		{ Id = 3715928524, Amount = 10 },
		{ Id = 3716700049, Amount = 25 },
		{ Id = 3715928529, Amount = 50 },
		{ Id = 3716700052, Amount = 75 },
		{ Id = 3715928536, Amount = 100 },
		{ Id = 3716700054, Amount = 150 },
		{ Id = 3716700057, Amount = 250 },
		{ Id = 3715928539, Amount = 500 },
		{ Id = 3715928542, Amount = 1000 },
	},
}

--[[
	The secret ending (FinaleService): everyone (2+ players) tied up at once, and he takes you all
	down to the "family" he's made under the house. Times in seconds, distances in studs.
]]
Config.Finale = {
	Enabled = true,
	MinPlayers = 2,
	-- the dinner: struggle while his back is turned, freeze while he watches
	DinnerTime = 330, -- free everyone before bedtime
	StrikePenalty = 30, -- every time he catches someone moving: this much less time
	StrugglePerPress = 0.8, -- % of the zip tie per press (Hard: about 0.6): a few back-turned spells each
	FakeOut = 0.25, -- sometimes the creak comes, and he doesn't turn round
	BackTurned = { 6, 9 }, -- he faces the stove this long
	Warning = 1.1, -- the creak before he turns round
	Watching = { 3.5, 5.5 }, -- then he watches the table this long
	CutHold = 2.5, -- a free player cutting someone loose
	MoveTolerance = 3.5, -- a free player this far from their chair while he watches: caught
	-- the tunnels
	DessertTime = 75, -- he climbs up to the house "for dessert" this long before he comes back down (Hard: 3/4)
	BurrowTime = 660, -- find the way out before bedtime
	BedtimeHunt = 70, -- the last stretch: he hunts at a run
	PatrolSpeed = 6.5,
	InvestigateSpeed = 8,
	ChaseSpeed = 9.2, -- still under your walk (10)
	Sight = 22,
	SightFlashlight = 34,
	FOV = 110,
	CatchRange = 4.2,
	HearScale = 0.8, -- a noise's radius, times this, down here
	RescueHold = 3, -- cutting a recaptured friend loose at the table
	-- the way out
	HatchPushes = 4, -- each one a loud scrape
	HatchHold = 1.6,
	ClimbHold = 1.2,
	Bars = 2, -- planks to bar the cellar door with
	BarHolds = 18, -- each bar holds him this long
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
