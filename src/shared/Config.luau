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
	-- every circle: a 10 s countdown from the moment someone steps in, 3 s once it's full; at 0 it
	-- goes with whoever's on it (into a group night that started short and has room, if there's one)
	Countdown = 10,
	FullCountdown = 3,
	-- game server: a group night that started short takes late arrivals (up to MaxPlayers) through the
	-- first two acts, until bedtime, and never past this many seconds. (v78 logs: 150 s caught 1 of 68
	-- teleports, while 44 of 57 lone departures had someone else leave the lobby within 8 minutes.)
	JoinOpenFor = 420,
	ArrivalTimeout = 20, -- game server: start without stragglers after this long (v87: 21 players left a
	-- server whose night never started, within 2-17 s of arriving; latecomers can still join the night)
	ReturnDelay = 35, -- game server: seconds on the ending screen before the next night starts (LOBBY to leave)
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
	SomeoneElse = { Min = 6, Max = 7 }, -- (9 left nights without a call dragging past 20 minutes)
}
-- a night where everyone has played before: the build-up acts could run shorter (this much of
-- their length). Off: the owner found the night too fast; repeat groups can SKIP TO THE BLACKOUT.
Config.VeteranPace = {}
Config.HardCapMinutes = 60
-- the FASTEST WINS board (and personal bests) ignore anything faster: a full night can't be won
-- that quickly (the fastest real one in the logs: 7:21, by car), and skip-to-the-blackout nights
-- never count at all (they put a 0:51 on the board)
Config.MinBoardWin = 360

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
	-- (v104, a player: "most loopable enemy in horror games". Run dry and you're winded: no sprint
	-- until your breath is back to this much. Before, a sprint at 0 stamina flickered back on at 1,
	-- so you could stutter-sprint forever at about his chase speed and circle a table all night.)
	WindedRecover = 35,
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
	PhoneCall = 30, -- (Hard: a 911 call at full voice)
	PhoneWhisper = 16, -- (Normal: whispering into the phone at the window)
	Struggle = 30,
	GarageRelease = 70,
	GarageMotor = 90,
	Breathing = 9,
	Cough = 35,
	FloorDropMultiplier = 0.55,
}

Config.Nerve = {
	Max = 100,
	AloneDarkDrain = 0.3, -- per second, acts 2+ (with your flashlight on: AloneDrain)
	DarkFloor = 50, -- the dark alone drains you down to here; below it, only he does
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
	-- (his speeds. v102, the owner: "make him faster": chasing or charging he now outpaces your walk
	-- (10) but not your sprint (17): seen, you run (and hide). Before, everything sat under 10.)
	ChargeSpeed = 12, -- going for a sound he's sure of (you walk at 10, sprint at 17)
	InvestigateSpeed = 9,
	ChargeSearchTime = 5, -- thrashing about where the noise was, after a charge
	InvestigateSearchTime = 6,
	InspectTime = { 7, 10 }, -- standing at your hiding spot, listening (v91: +1 s for the heartbeat's longer lead-in)
	InspectNearChance = 0.25, -- walking right past an occupied spot (not holding breath): he stops
	WalkSpeed = 8, -- lying low between hunts
	SneakSpeed = 5,
	ProwlSpeed = 11, -- (Classic brain) going to where he feels you are
	ChaseSpeed = 12.5, -- he can see you: faster than you walk, slower than you sprint, and he never stops
	LungeSpeed = 13.5, -- the last few steps
	MaxSpeed = 14.5, -- a hard cap on all of the above: never as fast as your sprint
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
	-- between hunts: a short breather near the players' floor, then he patrols
	WithdrawMin = 14,
	WithdrawMax = 22,
	WithdrawNotice = 30, -- seen this close while he's lying low, and he comes anyway
	StunTime = 7,
	RetreatAfterStun = 30,
	RetreatAfterCapture = 14, -- after a capture he walks off somewhere far from the boiler room
	RetreatBlind = 4, -- ...ignoring everyone only this long; then whoever he sees close, he chases
	RetreatBlindStun = 10, -- (pepper-sprayed: a longer head start)
	CaptiveGrace = 45, -- and for this long ignores the basement (struggling, rescues): the rescue window
	FreedGrace = 40, -- just got free (yourself or a friend): he can't see, hear or grab you for this long
	-- patrolling (nobody to sense): he sweeps the rooms you were last in, listening
	PatrolSpeed = 8.5,
	PatrolPause = { 1.5, 3 },
	PatrolCheckChance = 0.25, -- at each stop: tear open a hiding spot nearby
	DriftAfter = 60, -- nobody has met him this long: his patrols lean toward people out in the open
	DriftWeight = 14,
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
			WalkSpeed = 8.5,
			PatrolSpeed = 9,
			ProwlSpeed = 12,
			ChaseSpeed = 13.5, -- (Hard: only a sprint gets away)
			LungeSpeed = 14.5,
			SenseDelay = 2,
			HideGrace = 6,
			OpenFindChance = 0.85,
			SearchChecks = 3,
			AmbushChance = 0.55,
			WithdrawMin = 8,
			WithdrawMax = 14,
			RetreatAfterCapture = 8,
			CaptiveGrace = 30,
			FreedGrace = 20,
			-- (Hard keeps the sharper senses Normal had before it was eased)
			SightLit = 32,
			SightFlashlight = 45,
			GrabRange = 5,
			HearWalk = 11,
			PatrolCheckChance = 0.4,
			SoloChaseSlowdown = 0.6,
			ChargeSpeed = 13,
			InvestigateSpeed = 9.5,
			InspectNearChance = 0.5,
		},
		Heartbeat = { Interval = 0.8, Misses = 2, Window = 0.22, Travel = 0.9, Lead = 1.2, ForgiveWrong = false },
		BatteryMultiplier = 0.7, -- flashlights die faster
		PoliceMultiplier = 1.25, -- help takes longer to arrive
		LastChance = 30,
	},
	-- NIGHTMARE (v103, opt-in, for players who've finished a night): everything Hard has, plus this
	-- laid over it (workspace "Nightmare" = true, "Difficulty" stays "Hard"). Caught once and you're
	-- dead (a revive brings you back); 2x coins; its own title and badge.
	Nightmare = {
		Intruder = {
			WalkSpeed = 9,
			PatrolSpeed = 10,
			ProwlSpeed = 14,
			InvestigateSpeed = 10.5,
			ChargeSpeed = 14.5,
			ChaseSpeed = 15, -- (your sprint is 17: you get away only running, and only so long)
			LungeSpeed = 16,
			MaxSpeed = 16.5,
			SightLit = 36,
			SightDark = 14,
			SightFlashlight = 50,
			SenseDelay = 1.5,
			HideGrace = 5,
			OpenFindChance = 0.9,
			SearchChecks = 3,
			AmbushChance = 0.65,
			WithdrawMin = 6,
			WithdrawMax = 10,
			InspectNearChance = 0.6,
			SoloChaseSlowdown = 0.4,
			GrabRange = 5.2,
		},
	},
}

-- The heartbeat minigame (DOORS-style): he's listening at your hiding spot. Half-hearts fly in
-- from the left and the right; press that side as each one reaches the heart. Miss too many and
-- he hears you. (Hard: Config.Difficulty.Hard.Heartbeat overrides.)
-- (Normal was failed 14 times out of 22 in the first day of logs, and no pass ever counted: it's
-- meant to be tense, not a wall. Hard keeps the tight version.)
-- (v81: still failed 34 times out of 61 on Normal; wider and slower again. Normal should be passed
-- most of the time by anyone who tries.)
Config.Heartbeat = {
	Interval = 1.25, -- seconds between beats
	Travel = 1.3, -- how long a half-heart takes to fly in (easier to read)
	Window = 0.42, -- seconds either side of arrival that count (forgiving on touch screens)
	Lead = 2.4, -- the heart shows this long before the first beat (time to read it: v88-90 Normal passed 28 of 60)
	Misses = 3, -- this many misses and he hears you (more and doing nothing could outlast him)
	-- (v87 logs: passed only 15 times out of 50 on Normal, and that failure was most of the upstairs
	-- bathroom captures. The side buttons now show on every device, not just touch (PC players had
	-- only Q / E to go on), and on Normal the first wrong-side press on a beat is forgiven: press
	-- the other side in time and it still counts. Doing nothing still fails. Hard: no forgiveness.)
	ForgiveWrong = true,
}

Config.Hiding = {
	HoldBreathMax = 8,
	HoldBreathRecover = 1.5, -- seconds of recovery per second of breath
}

Config.Capture = {
	RescueHold = 5,
	RescueHoldTool = 2.5,
	StrugglePerPress = 1.6, -- percent (about 63 presses: doable in the 45 s last chance on a phone)
	StruggleNoiseEvery = 12, -- presses
	LastChance = 45, -- seconds everyone-captured players get to struggle free before the bad ending
}

Config.Help = {
	-- (v88-90 logs: once help was called only 7 of 200 players left before the police came, while the
	-- hunt is the game; nights ran ~11 min against the ~13 the owner wants: a longer hold-out)
	PhoneResponse = 120, -- (v94: 200 was "too long", the owner; 150 before that)
	NeighborResponse = 120,
	CarResponse = 60,
	CellCallDuration = 15, -- (Hard)
	CellCallDurationNormal = 10,
	OkaforCallsAfter = 100, -- seconds into the last act with no help called: Mrs. Okafor sees the van and calls the police
	OkaforResponse = 80,
	-- the call goes through and he hears it (he screams and charges the caller): on Normal the caller
	-- gets this head start to hide (v81 logs: most upstairs-bathroom captures came 3-12 s after the
	-- call ended, the caller still at the window). Hard: none.
	CallerGrace = 10, -- (v87: 6 s ran out just as he arrived; most bathroom captures followed a call)
	CallerGraceHard = 0,
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
	BeatSpacing = 35, -- a scripted scare waits this long after the last one (one thing at a time)
	AfterNews = 28, -- act II ends this long after the news was watched at the soonest...
	BedtimeAfterNews = 4, -- (then "Get ready for bed" comes; brushed, the lights go AfterBedtime later)
	AfterBedtime = 5, -- (v94: 12; the owner wanted less waiting before the blackout)
	BedtimeMinAct = 150, -- (but act II still runs at least this long: its scares need room)
	AfterScare = 30, -- ...and this long after the last scare
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
	Nightmare = 3428208981624377, -- survived a NIGHTMARE night (v103)
	Rescuer = 1978303375336712, -- cut a friend free
	NotYourFamily = 892775622827536, -- the secret ending, out from under the house
	ForeverFamily = 2482890253693907, -- the secret ending, nobody left the table
	Halloween2026 = 1401087647562759, -- found 5 candies during Halloween 2026 (EconomyService.addCandy)
}

--[[
	Shop (server/Services/ShopService, client/Controllers/Shop). Game passes and donation products
	are created in the Creator Hub (Monetization); paste their IDs here. Id 0 = not set up yet:
	the item still shows in the shop, marked "Soon". Price is only shown until Roblox reports the
	real one.
]]
Config.Shop = {
	Passes = {
		-- (14 Oct: the owner wants Robux for all-ages access. Every pass does more now, the pepper spray
		-- pass is a taser, and VIP bundles the perks)
		{ Key = "Rocket", Id = 2039534472, Price = 99, Name = "Rocket Launcher", Desc = "Start every night with a rocket launcher: 2 rockets. A hit blows him off his feet, then he limps away." },
		{ Key = "VIP", Id = 2036510399, Price = 99, Name = "VIP", Desc = "Everything in one: +50% coins every night, a VIP tag, pick your role, every flashlight colour, Marathon stamina and a battery that never dies." },
		{ Key = "PepperSpray", Id = 2006030307, Price = 49, Name = "Taser", Desc = "Start every night with a taser: 3 shots. A hit stuns him, then slows him right down." },
		{ Key = "Supporter", Id = 2008280313, Price = 10, Name = "Supporter", Desc = "+20% coins every night, a SUPPORTER tag, a gold flashlight and a star on the donation board." },
		{ Key = "Colours", Id = 2005832310, Price = 15, Name = "Flashlight colours", Desc = "Every flashlight colour, plus the pale Ghost beam." },
		{ Key = "ChooseRole", Id = 2006193593, Price = 25, Name = "Pick your role", Desc = "Choose who you play every night, and what you start with: Jamie's flashlight, Riley's toolkit, Morgan's energy drinks or Casey's firecrackers." },
		{ Key = "Marathon", Id = 2005053525, Price = 20, Name = "Marathon", Desc = "Sprint for longer and get your breath back twice as fast." },
		{ Key = "Battery", Id = 2005388315, Price = 25, Name = "Long-life battery", Desc = "Your flashlight never runs out." },
		{ Key = "HeadStart", Id = 2006721483, Price = 25, Name = "Head start", Desc = "Start every night with a flashlight in your pocket, plus a spray can to keep him back." },
	},
	-- bought on the spot after you die: back into this night, somewhere away from him
	-- (Price: the default the product is set to on Roblox, shown until the live price loads; the card
	-- shows each player's own price. 25 R$ sold 0 of 35 deaths; DOORS sells its death-screen revive for
	-- 40 R$ with a far bigger brand. 10 R$ = the cheapest pass, an impulse buy for a leftover balance)
	Revive = { Id = 3716706476, Price = 10, Window = 15, Grace = 10 },
	-- co-op only, bought again every night: you become him for the rest of the night (MonsterService)
	BecomeHim = { Id = 3718593338, Price = 50 },
	-- one rocket for this night only (the hunt): for anyone without the pass, bought on the spot
	RocketNight = { Id = 3718739690, Price = 25 },
	-- one time only, for everyone who hasn't had it: coins, a rocket for the next night and a revive
	-- (worth 25 + 25 + 10 R$+ bought apart). Offered at the top of the SHOP and on the result card.
	-- Id 0 = the product isn't made on Roblox yet: hidden everywhere.
	Starter = { Id = 0, Price = 19, Coins = 500, Rockets = 1, Revives = 1 },
	-- the passes VIP includes (it sets their attributes too)
	VIPIncludes = { "Colours", "Marathon", "Battery", "ChooseRole" },
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
	-- (v97: 13 of 35 secret endings were Forever Family, many inside 60-80 s, about 9 strikes each:
	-- mashing STRUGGLE runs into his turn. Normal now forgives a reaction and warns once)
	StrikePenalty = 20, -- every time he catches someone moving: this much less time (Hard: HardStrikePenalty)
	HardStrikePenalty = 30,
	StrikeGrace = 0.8, -- after he turns round, this long to stop (Hard: 0.3)
	FreeWarnings = 1, -- Normal: the first strikes of the night only warn (no time lost)
	StrugglePerPress = 1.2, -- % of the zip tie per press (Hard: x0.78): a couple of back-turned spells each
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
	ChaseSpeed = 11, -- (v102: faster than your walk, like upstairs)
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

-- "Become him" (MonsterService): a player drives Curtis for the rest of the night. A little under a
-- survivor's walk (10), like him; LUNGE is the burst that makes it a game
Config.Monster = {
	MinPlayers = 2, -- survivors in the night (it's co-op only)
	WalkSpeed = 11.5,
	LungeSpeed = 17,
	LungeTime = 1.4,
	LungeCooldown = 9,
	GrabRange = 4.5,
	GrabCooldown = 6, -- after a catch (so a group isn't wiped in a second)
	SearchRange = 7,
	SearchCooldown = 2,
	ListenTime = 7, -- the heartbeat minigame for whoever's inside
	TaserStun = 6,
}

-- the taser (the old pepper spray pass): aim and shoot. A hit stuns him, then he limps after you slowly
Config.Taser = {
	Charges = 3,
	Range = 50,
	AimCone = 30, -- degrees either side of where you aim (v94: 9 felt like it didn't work at all)
	AutoRange = 26, -- (v102, the owner: "too hard to aim, just make it autohit when you are close") this
	-- close and in plain sight, every shot hits wherever you point
	Stun = 5,
	Slow = 14, -- seconds he moves at SlowFactor afterwards
	SlowFactor = 0.55,
	Cooldown = 1.2,
}

Config.PepperSpray = {
	Uses = 2,
	Range = 15,
	ConeDegrees = 45,
}

-- the rocket launcher (pass: 2 rockets a night; "Rocket (tonight)": 1). The rocket flies where you
-- aim; anywhere within Blast of him when it goes off knocks him flat, then he limps away slowly.
-- It's loud: a miss brings him to the bang (the explosion never hurts anyone else)
Config.Rocket = {
	Charges = 2,
	Range = 160,
	Speed = 120, -- studs per second
	AimCone = 15, -- degrees: aim assist toward him
	Blast = 12, -- studs
	Stun = 7,
	Slow = 20,
	Cooldown = 2.5,
	Noise = 90,
	MonsterStun = 8, -- a player who's become him
}

-- the role items (Story.Roles): Morgan's energy drinks and Casey's firecrackers
Config.EnergyDrink = {
	Time = 10, -- seconds: sprint without tiring, a little faster
	Sprint = 19,
}
Config.Firecracker = {
	Range = 34, -- how far you can throw one
	Fuse = 1.4,
	Noise = 75, -- the bang: he goes to see (and leaves whoever he was listening for)
}

if Config.Debug then
	Config.TimeScale = 0.25
end

return Config
