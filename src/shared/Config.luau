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
	ReadyWait = 12, -- game server: wait this long at most for everyone's client to finish loading (v110)
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
	-- (v126, the owner: "The game is too short... I want this to be a fully polished 15-20 minute game where
	-- BPM goes 120+. Make it constantly scary". The owner's later word wins over v117's "10 minutes on
	-- average": a longer build-up with him seen more, and a much longer hunt. Before: v117 ~10 min.)
	Evening = { Min = 2.5, Max = 5 }, -- (v117: 2 / 4)
	SmallThings = { Min = 4.5, Max = 6 }, -- (v117: 3 / 4.5)
	-- (v134, the owner: "Blackout part is too long": with no help called the dark ran 12 minutes before Mrs. Okafor's
	-- part even began. Now 3-4; v126: 10 / 12; v117: 4.5 / 5)
	SomeoneElse = { Min = 2, Max = 2.5 }, -- (v135: 3-4)
}
-- no night ends sooner than this (the police, the car and next door wait for it), except a night
-- that skipped to the blackout. v135 (the owner, a screenshot: "Police: 4:48", "Blackout still too long"): off; the police
-- come PhoneResponse after the call and the exits open ExitsAfter into the hunt, whatever the clock says (v134: 600; v126: 900)
Config.MinNight = 0
-- a night where everyone has played before: the build-up acts could run shorter (this much of
-- their length). Off: the owner found the night too fast; repeat groups can SKIP TO THE BLACKOUT.
Config.VeteranPace = {}
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
	-- (v126, the owner: "Make the monster much scarier and harder... I want him to automatically sprint to my
	-- current location": every speed up a notch, all still under your sprint)
	ChargeSpeed = 13, -- going for a sound he's sure of (you walk at 10, sprint at 17) (v125: 12)
	InvestigateSpeed = 10, -- (v125: 9)
	ChargeSearchTime = 5, -- thrashing about where the noise was, after a charge
	InvestigateSearchTime = 6,
	InspectTime = { 7, 10 }, -- standing at your hiding spot, listening (v91: +1 s for the heartbeat's longer lead-in)
	InspectNearChance = 0.4, -- walking right past an occupied spot (not holding breath): he stops (v125: 0.25)
	WalkSpeed = 8, -- lying low between hunts
	SneakSpeed = 5,
	ProwlSpeed = 11, -- (Classic brain) going to where he feels you are
	ChaseSpeed = 13.5, -- he can see you: faster than you walk, slower than you sprint, and he never stops (v125: 12.5)
	LungeSpeed = 14.5, -- the last few steps (v125: 13.5)
	MaxSpeed = 15, -- a hard cap on all of the above: never as fast as your sprint (v125: 14.5)
	--[[
		(v126) He knows where you are. Every SenseEvery seconds of the hunt (the first SenseFirst in), he
		picks one of you, the one he went for longest ago, and sprints at SenseSpeed to where they are
		RIGHT NOW: out in the open, he charges, re-aiming as they move (SenseHoming s); hiding, he runs
		to their hiding spot and listens at it (the heartbeat). The one he's after is told.
	]]
	SenseFirst = 15,
	SenseEvery = { 24, 34 },
	SenseSpeed = 14,
	SenseHoming = 10,
	-- (v127, the owner: "Make him constantly run after someone") between those, he never just patrols: with
	-- nothing else to do he's running after one of you again within PursueGap s, keeping on the same one for
	-- up to PursueFor s (re-aiming as they move), then the one he went for longest ago. Hiding: he runs to
	-- the spot and listens. (Not while he's carrying someone off, stunned, or listening at a door.)
	PursueGap = 1.2, -- (v135, the owner: "I want him to constantly chase": 2.5)
	PursueFor = 18,
	-- (v128) those quiet runs go at PursueSpeed, under the loud SenseSpeed: still faster than your walk, so
	-- walking away doesn't lose him, but a sprint does (v126-127 logs: first-nighters' captures doubled and
	-- groups of two lost one in three to a second capture)
	PursueSpeed = 11.5,
	-- (v128) just freed: after FreedGrace, neither run picks you for this much longer, and while anyone else
	-- hasn't been caught yet they come first (v126-127: half the deaths came within 60 s of getting free)
	FreedLeaveAlone = 45,
	LastLifeLast = true,
	GrabRange = 4.5,
	FOV = 90, -- degrees
	-- (short sight: he hunts by sound. Lit rooms and your beam still give you away)
	SightLit = 28,
	SightDark = 18, -- (v133, the owner: "he's still so dumb sometimes just walks past me"; v126: 13, v125: 10)
	SightFlashlight = 40, -- a flashlight in the dark gives you away
	CrouchSightMultiplier = 0.6,
	PeripheralRange = 10, -- sensed regardless of facing (v133: 7; only crouched and still beats it)
	HearWalk = 15, -- walking (not crouched) this close: he notices you behind him (v133: 12; v125: 10)
	HearSprint = 16, -- running
	HearFlashlight = 12, -- your beam on the walls around him
	SoloChaseSlowdown = 1, -- studs/s slower when playing alone
	RookieChaseSlowdown = 1.5, -- (v129) and this much slower after someone on their first night (Normal only)
	ChaseLoseSightTime = 2.5, -- out of sight this long and he's back to following your trail
	-- what he knows
	SenseDelay = 3, -- he feels where you were this many seconds ago
	HideGrace = 8, -- after leaving a hiding spot, he can't feel you for this long
	-- (v125, a player: "you can literally just hide and wait 2 mins and you've won") a hiding spot goes
	-- stale: stay in the same one this long and he smells you there. A warning first (HideStaleWarn
	-- before), then he comes and listens at it (the heartbeat). Still there HideStaleAgain after he
	-- left, and he rips it open: move between hiding spots, don't camp one.
	HideStale = 30, -- (v125: 40)
	HideStaleWarn = 8,
	HideStaleAgain = 25, -- (v128: 15; v125: 20)
	-- searching hiding spots
	SearchChecks = 2,
	TrueSpotWeight = 1.5, -- the spot you're really in is this much likelier to be opened
	SeeHideCheckChance = 1, -- he saw you get in
	OpenFindChance = 0.85, -- he opens your spot without having seen you (v125: 0.75)
	BreathHoldSave = 0.6, -- holding your breath cuts that by this much
	AmbushChance = 0.4, -- after a search: pretend to leave, wait round the corner
	AmbushTime = 9, -- (+0-5 s)
	-- between hunts: a short breather near the players' floor, then he patrols
	WithdrawMin = 8, -- (v125: 14)
	WithdrawMax = 14, -- (v125: 22)
	WithdrawNotice = 30, -- seen this close while he's lying low, and he comes anyway
	StunTime = 7,
	RetreatAfterStun = 30,
	RetreatAfterCapture = 10, -- after a capture he walks off somewhere far from the boiler room (v125: 14)
	RetreatBlind = 4, -- ...ignoring everyone only this long; then whoever he sees close, he chases
	RetreatBlindStun = 10, -- (pepper-sprayed: a longer head start)
	CaptiveGrace = 45, -- and for this long ignores the basement (struggling, rescues): the rescue window
	FreedGrace = 60, -- (v128: 40) just got free (yourself or a friend): he can't see, hear or grab you for this long
	-- patrolling (nobody to sense): he sweeps the rooms you were last in, listening
	PatrolSpeed = 9.5, -- (v125: 8.5)
	PatrolPause = { 1.5, 3 },
	PatrolCheckChance = 0.4, -- at each stop: tear open a hiding spot nearby (v125: 0.25)
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
			WalkSpeed = 9.5,
			PatrolSpeed = 10.5,
			ProwlSpeed = 13,
			SenseDelay = 2,
			HideGrace = 6,
			OpenFindChance = 0.92,
			SearchChecks = 3,
			AmbushChance = 0.55,
			WithdrawMin = 5,
			WithdrawMax = 9,
			RetreatAfterCapture = 7,
			CaptiveGrace = 30,
			FreedGrace = 20,
			-- (Hard keeps the sharper senses Normal had before it was eased)
			SightLit = 32,
			SightFlashlight = 45,
			GrabRange = 5,
			HearWalk = 17,
			SightDark = 21,
			PatrolCheckChance = 0.55,
			SoloChaseSlowdown = 0.6,
			RookieChaseSlowdown = 0,
			ChargeSpeed = 14,
			InvestigateSpeed = 11,
			ChaseSpeed = 14.5, -- (Hard: only a sprint gets away)
			LungeSpeed = 15.5,
			MaxSpeed = 16,
			InspectNearChance = 0.55,
			HideStale = 22,
			HideStaleAgain = 12,
			SenseFirst = 10,
			SenseEvery = { 16, 24 },
			SenseSpeed = 15,
			PursueGap = 0.8, -- (v135: 1.5)
			PursueSpeed = 13,
			FreedLeaveAlone = 15,
			LastLifeLast = false,
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
			ChaseSpeed = 15.5, -- (your sprint is 17: you get away only running, and only so long)
			LungeSpeed = 16.5,
			MaxSpeed = 16.8,
			SightLit = 36,
			SightDark = 24, -- (v133: 14, below Hard's by mistake)
			SightFlashlight = 50,
			SenseDelay = 1.5,
			HideGrace = 5,
			OpenFindChance = 0.9,
			SearchChecks = 3,
			AmbushChance = 0.65,
			WithdrawMin = 4,
			WithdrawMax = 7,
			InspectNearChance = 0.6,
			SoloChaseSlowdown = 0.4,
			GrabRange = 5.2,
			HideStale = 18,
			HideStaleAgain = 10,
			SenseFirst = 8,
			SenseEvery = { 11, 17 },
			SenseSpeed = 16,
			PursueGap = 0.6, -- (v135: 1)
			PursueSpeed = 14.5,
			FreedLeaveAlone = 0,
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
	Window = 0.38, -- seconds either side of arrival that count (forgiving on touch screens) (v126: 0.42)
	Lead = 2.4, -- the heart shows this long before the first beat (time to read it: v88-90 Normal passed 28 of 60)
	Misses = 2, -- this many misses and he hears you (v126, the owner: "much harder": 3 -> 2)
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
	PhoneResponse = 75, -- (v135: 90; v134: 150; v126: 100 with MinNight 15 min; v117: 120; v94: 200 was "too long", the owner)
	NeighborResponse = 75, -- (v135: 90; v134: 150)
	CarResponse = 60, -- (v134: 90)
	CellCallDuration = 15, -- (Hard)
	CellCallDurationNormal = 10,
	OkaforCallsAfter = 30, -- (v134: 300; v126: 60) -- seconds into the last act with no help called: Mrs. Okafor sees the van and calls the police
	OkaforResponse = 60, -- (v134: 120)
	-- the call goes through and he hears it (he screams and charges the caller): on Normal the caller
	-- gets this head start to hide (v81 logs: most upstairs-bathroom captures came 3-12 s after the
	-- call ended, the caller still at the window). Hard: none.
	CallerGrace = 10, -- (v87: 6 s ran out just as he arrived; most bathroom captures followed a call)
	CallerGraceHard = 0,
	LandlineCallDuration = 6,
	NeighborWait = 20, -- (was 15)
	-- (v116, a player: "way too short, I escaped in 3 mins": the car and her door worked from the first
	-- second of the hunt; keys grabbed before the blackout meant a drive-off 3 s in) the car won't start
	-- and Mrs. Okafor doesn't wake until the hunt has run this long. Calling 911 is ~130 s anyway.
	ExitsAfter = 60, -- (v135: 90; v134: 240)
	JunctionRepair = 10,
	-- (v125) the police pulling up doesn't end the night by itself: they're at the front, he knows
	-- it's over and comes for whoever is still inside, wherever they are. Get out the front door.
	-- After this long the police come in anyway (whoever's still alive in there is found).
	FinalRun = 30, -- (v134: 45)
	FinalRunHard = 25, -- (v134: 35)
	FinalRunGrace = 3, -- seconds after the door opens before he starts going for you
}

-- The Director: tension ceilings per act, seconds between scheduled events, storm cadence
Config.Director = {
	Ceiling = { Evening = 25, SmallThings = 65, SomeoneElse = 85, Guest = 100 },
	Gap = {
		Evening = { 18, 32 }, -- (v126: 25-45; constantly scary)
		SmallThings = { 16, 30 }, -- (v126: 25-42)
		SomeoneElse = { 32, 55 },
		Guest = { 45, 80 },
	},
	TensionDecay = 0.5, -- per second
	Lightning = { 20, 50 },
	SmallThingsQuiet = 40, -- act II ends (after Min) once tension falls below this
	BeatSpacing = 25, -- a scripted scare waits this long after the last one (one thing at a time) (v126: 35)
	AfterNews = 22, -- (v117: 28) -- act II ends this long after the news was watched at the soonest...
	BedtimeAfterNews = 4, -- (then "Get ready for bed" comes; brushed, the lights go AfterBedtime later)
	AfterBedtime = 5, -- (v94: 12; the owner wanted less waiting before the blackout)
	BedtimeMinAct = 260, -- (v126: 120) -- (but act II still runs at least this long: its scares need room)
	AfterScare = 22, -- (v117: 30) -- ...and this long after the last scare
	-- (v132, the owner: "When a person enters the upstairs room to close the window make the light flicker and let
	-- him show for a sec and then disappear suddenly with a loud sound effect too. These are the types of scares I want
	-- you to add through the game.") Walking into a room: its lights stutter, he's standing there for a second, then
	-- they snap off with a loud hit and he's gone. The first act's open-window rooms always (the first time in);
	-- other rooms by chance, once a night each; in the hunt (power out: your flashlight stutters) less often, and only
	-- when he's really far away.
	Apparition = { Chance = 0.45, Cooldown = 55, Spacing = 10, NotBefore = 25, HuntChance = 0.25, HuntCooldown = 100, HuntFar = 45 },
	CeilingSteps = 20, -- (v113) seconds into the Evening: footsteps cross the ceiling over someone
}

-- Inner monologue: the character thinking out loud about what to do next
Config.Thoughts = {
	Duration = 5, -- seconds each line stays on screen
	IdleHint = 35, -- seconds without progress before they remind themselves of the next task
	FirstHint = 3, -- seconds into the night before the first task nudge (it queues behind the opening line)
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
-- (v121) invites pay: whoever brings a brand-new friend gets Coins (kept for them if they're offline),
-- the friend gets Welcome coins (StatsService checkReferral; on top of the flashlight colours)
Config.Referral = { Coins = 200, Welcome = 100 }

Config.Shop = {
	Passes = {
		-- (14 Oct: the owner wants Robux for all-ages access. Every pass does more now, the pepper spray
		-- pass is a taser, and VIP bundles the perks)
		-- v106 (21 Oct, the owner): the admin panel, most of what the owner's has (not coins, passes,
		-- paid items or revives); a night it's used on pays no coins and counts for no board
		{ Key = "AdminPanel", Id = 2044988494, Price = 249, Name = "Admin panel", Desc = "Run the night: skip acts, set off scares, boss him around, god mode, teleport, pick the ending. (No coins on nights you use it.)" },
		-- (v108, 21 Oct: about 8 of 2,714 players own a pass. More things worth wanting at a price a small
		-- balance covers: the cheap ones down to 15-19, the taser 39, the rocket 79; three new ones)
		{ Key = "NightVision", Id = 2045276660, Price = 49, Name = "Night Vision", Desc = "Night vision goggles every night: see in the dark for 60 seconds. Spot him before he spots you." },
		{ Key = "DoubleCoins", Id = 2045798689, Price = 39, Name = "2x Coins", Desc = "Double the coins from every night you play. Stacks with VIP." },
		{ Key = "Rocket", Id = 2039534472, Price = 79, Name = "Rocket Launcher", Desc = "Start every night with a rocket launcher: 2 rockets. A hit blows him off his feet, then he limps away." },
		{ Key = "VIP", Id = 2036510399, Price = 99, Name = "VIP", Desc = "Everything in one: +50% coins every night, a VIP tag, pick your role, every flashlight colour, Marathon stamina and a battery that never dies." },
		{ Key = "PepperSpray", Id = 2006030307, Price = 39, Name = "Taser", Desc = "Start every night with a taser: 3 shots. A hit stuns him, then slows him right down." },
		{ Key = "Silent", Id = 2044448668, Price = 29, Name = "Silent Steps", Desc = "Your footsteps make half the noise, and you can hold your breath 50% longer while hiding." },
		{ Key = "Supporter", Id = 2008280313, Price = 10, Name = "Supporter", Desc = "+20% coins every night, a SUPPORTER tag, a gold flashlight and a star on the donation board." },
		{ Key = "Colours", Id = 2005832310, Price = 15, Name = "Flashlight colours", Desc = "Every flashlight colour, plus the pale Ghost beam." },
		{ Key = "ChooseRole", Id = 2006193593, Price = 10, Name = "Pick your role", Desc = "Choose who you play every night, and what you start with: Jamie's flashlight, Riley's toolkit, Morgan's energy drinks or Casey's firecrackers." },
		{ Key = "Marathon", Id = 2005053525, Price = 15, Name = "Marathon", Desc = "Sprint for longer and get your breath back twice as fast." },
		{ Key = "Battery", Id = 2005388315, Price = 15, Name = "Long-life battery", Desc = "Your flashlight never runs out." },
		{ Key = "HeadStart", Id = 2006721483, Price = 19, Name = "Head start", Desc = "Start every night with a flashlight in your pocket, plus a spray can to keep him back." },
	},
	-- bought on the spot after you die: back into this night, somewhere away from him
	-- (Price: the default the product is set to on Roblox, shown until the live price loads; the card
	-- shows each player's own price. 25 R$ sold 0 of 35 deaths; DOORS sells its death-screen revive for
	-- 40 R$ with a far bigger brand. 10 R$ = the cheapest pass, an impulse buy for a leftover balance)
	Revive = { Id = 3716706476, Price = 10, Window = 15, Grace = 10 },
	-- co-op only, bought again every night: you become him for the rest of the night (MonsterService)
	BecomeHim = { Id = 3718593338, Price = 25 }, -- (v108: 50 → 25: opened 49 times, bought 0 at 50)
	-- one rocket for this night only (the hunt): for anyone without the pass, bought on the spot
	RocketNight = { Id = 3718739690, Price = 10 }, -- (v110: 25 -> 15, 0 of 10 bought at 25; v118: 15 -> 10, 0 of 13 at 15)
	-- one time only, for everyone who hasn't had it: coins, a rocket for the next night and a revive
	-- (worth 25 + 25 + 10 R$+ bought apart). Offered at the top of the SHOP and on the result card.
	-- Id 0 = the product isn't made on Roblox yet: hidden everywhere.
	-- (v130: 19 -> 9 R$, 2 sold of 906 windows; WasPrice shows struck through in the shop)
	Starter = { Id = 3721088307, Price = 9, WasPrice = 19, Coins = 500, Rockets = 1, Revives = 1 },
	-- (v115, the owner: "add something like this for 10 Robux") jumpscares everyone else in the
	-- server, house or lobby, the moment it's bought (ShopService, client Prank)
	JumpscareAll = { Id = 3722081951, Price = 10 },
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

-- the Night Vision pass (v108): goggles in the hotbar, a green view of the dark for this many seconds
-- a night (on and off as you like; client NightVision)
Config.NightVision = { Seconds = 60 }

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
