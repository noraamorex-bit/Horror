--[[
	Story — every word of narrative content in the game.
	Keeping writing out of code lets it be edited (and localized) in one place.
]]

local Story = {}

Story.Title = "someone lives in our attic."
Story.Address = "14 Alder Lane, Hollis Creek"

---------------------------------------------------------------------------
-- Roles (dealt in this order, so a Host always exists)
---------------------------------------------------------------------------
Story.Roles = {
	{
		Id = "Host",
		Name = "Jamie Whitaker",
		Blurb = "It's your house. Your parents trusted you with it for the weekend. You know where everything is.",
		Perk = "Carries the house keys (dad's office, the basement lock). Sees room names.",
		Items = { HouseKeys = 1 },
	},
	{
		Id = "Tinkerer",
		Name = "Riley Chen",
		Blurb = "If it's broken, you can fix it. You never go anywhere without your multitool.",
		Perk = "Starts with a multitool. Repairs and frees friends twice as fast.",
		Items = { Multitool = 1 },
	},
	{
		Id = "Runner",
		Name = "Morgan Hale",
		Blurb = "Varsity cross-country. You came for the pizza and you're staying for the pizza.",
		Perk = "More stamina. Sprinting is quieter.",
		Items = {},
	},
	{
		Id = "Observer",
		Name = "Casey Brooks",
		Blurb = "You notice things. The problem has always been getting anyone to listen.",
		Perk = "Hears sounds from farther away. Notices extra details on clues.",
		Items = {},
	},
}

---------------------------------------------------------------------------
-- Chapter cards
---------------------------------------------------------------------------
Story.Chapters = {
	Evening = { Title = "I. Friday Night", Sub = "Parents away until Sunday." },
	SmallThings = { Title = "II. Small Things", Sub = "The storm is getting worse." },
	SomeoneElse = { Title = "III. Someone Else", Sub = "Breakers don't flip themselves." },
	Guest = { Title = "IV. The Guest", Sub = "He knows you found him." },
	Below = { Title = "V. Down Here", Sub = "Dinner is served." },
}

---------------------------------------------------------------------------
-- Objectives
---------------------------------------------------------------------------
Story.Objectives = {
	OrderPizza = "Order pizza (kitchen phone)",
	Popcorn = "Make popcorn (microwave)",
	Bedtime = "Get ready for bed (upstairs bathroom)",
	Windows = "Close the upstairs windows before the storm",
	Fire = "Get the fire going (firewood in the garage)",
	Movie = "Put a movie on (find the remote)",

	Explore = "Figure out what that noise was",

	Power = "Restore the power (breaker panel, garage)",
	Phone = "Call someone for help",
	Attic = "Find out what's in the attic",

	Call911 = "Call 911 (upstairs bathroom window)",
	Neighbor = "Get to Mrs. Okafor's house next door",
	Car = "Find the car keys and drive for help",
	Trap = "(Optional) Lock him in the basement",
	Rescue = "Free anyone he takes (boiler room, basement)",
	Survive = "Survive until the police arrive",
}

---------------------------------------------------------------------------
-- Tasks: each objective is a few steps. Target = where the "!" marker goes (a name the
-- world build registers with Objectives.setTarget), or a list of alternatives.
---------------------------------------------------------------------------
Story.Tasks = {
	-- Act I
	OrderPizza = { Title = "Order pizza", Steps = {
		{ Key = "Menu", Text = "Find the pizza menu (fridge)", Target = "Fridge" },
		{ Key = "Call", Text = "Call Tony's (kitchen phone)", Target = "Phone" },
	} },
	Popcorn = { Title = "Make popcorn", Steps = {
		{ Key = "Bag", Text = "Get a bag of popcorn from the kitchen cupboard", Target = "Cupboard" },
		{ Key = "Cook", Text = "Pop it in the microwave", Target = "Microwave" },
	} },
	Windows = { Title = "Close the upstairs windows", Steps = {
		{ Key = "GuestFront", Text = "Close the window in the guest room", Target = "GuestWindow" },
		{ Key = "LilyBack", Text = "Close the window in Lily's room", Target = "LilyWindow" },
	} },
	-- (repeat nights draw two of Popcorn / Windows / Fire / Movie: Director/NightPlan)
	Fire = { Title = "Get the fire going", Steps = {
		{ Key = "Wood", Text = "Grab some firewood from the pile in the garage", Target = "Woodpile" },
		{ Key = "Light", Text = "Put it in the fireplace and light it", Target = "Fireplace" },
	} },
	Movie = { Title = "Movie night", Steps = {
		{ Key = "Remote", Text = "Find the TV remote (try the couch)", Target = "Couch" },
		{ Key = "Movie", Text = "Put the movie on: channel 4", Target = "TV" },
	} },
	Door = { Title = "Answer the door", Steps = {
		{ Key = "Answer", Text = "Answer the front door", Target = "Door_FrontDoor" },
	} },
	-- Act II
	News = { Title = "Watch the news", Steps = {
		{ Key = "TV", Text = "Turn on the living room TV", Target = "TV" },
		{ Key = "Ch7", Text = "Channel 7", Target = "TV" },
		{ Key = "Watch", Text = "Watch the report", Target = "TV" },
	} },
	LockUp = { Title = "Lock up for the night", Steps = {
		{ Key = "BackDoor", Text = "Lock the back door in the kitchen", Target = "Door_BackDoor" },
		{ Key = "GarageSide", Text = "Lock the garage side door", Target = "Door_GarageSide" },
	} },
	-- (after the news: the wait for the blackout used to be 2.5 minutes of nothing; now it sends
	-- everyone upstairs, past the one bar of signal by the bathroom window, and the lights go there)
	Bedtime = { Title = "Get ready for bed", Steps = {
		{ Key = "Teeth", Text = "Brush your teeth (upstairs bathroom)", Target = "BathSink" },
	} },
	Investigate = { Title = "Check upstairs", Steps = {
		{ Key = "Look", Text = "Check the noise upstairs", Target = "Hatch" },
	} },
	-- Act III
	-- the secret ending (FinaleService)
	FinaleDinner = { Title = "Get free", Steps = {
		{ Key = "Struggle", Text = "Break your zip tie: struggle ONLY while his back is turned" },
		{ Key = "Cut", Text = "Cut your friends loose (hold at their chair while he isn't looking)" },
	} },
	FinaleBurrow = { Title = "Get out from under the house", Steps = {
		{ Key = "Code", Text = "Read his 3 notes for the lock code: PANTRY, NURSERY, HIS ROOM", Target = { "FinaleNote1", "FinaleNote2", "FinaleNote3" } },
		{ Key = "Unlock", Text = "Enter the code on the keypad in the STORM CELLAR (north)", Target = "FinaleKeypad" },
		{ Key = "Climb", Text = "Push the hatch open, then climb the ladder out", Target = "FinaleLadder" },
	} },
	Power = { Title = "Get the power back on", Steps = {
		{ Key = "Flashlight", Text = "Find a flashlight (drawers, shelves)", Target = { "Flashlight1", "Flashlight2" } },
		{ Key = "Flip", Text = "Flip the MAIN breaker back on", Target = "Breaker" },
	} },
	Phone = { Title = "Call for help", Steps = {
		{ Key = "Box", Text = "Check the phone box outside the garage", Target = "JunctionBox" },
		{ Key = "Tape", Text = "Find electrical tape (search the drawers, or the garage)", Target = { "Tape1", "Tape2" } },
		{ Key = "Splice", Text = "Splice the cut phone wires", Target = "JunctionBox" },
		{ Key = "Call", Text = "Call 911 from the kitchen phone", Target = "Phone" },
	} },
	Attic = { Title = "Find out what's in the attic", Steps = {
		{ Key = "Hatch", Text = "Pull down the attic hatch in the upstairs hall", Target = "Hatch" },
		{ Key = "Search", Text = "Climb up and search the attic", Target = "Nest" },
	} },
	-- Act IV
	Call911 = { Title = "Call 911", Steps = {
		{ Key = "Call", Text = "Call from the upstairs bathroom window, or fix the phone line outside", Target = { "SignalSpot", "JunctionBox" } },
	} },
	Neighbor = { Title = "Get to Mrs. Okafor's house", Steps = {
		{ Key = "Knock", Text = "Knock on her door next door, and wait", Target = "NeighborDoor" },
	} },
	Car = { Title = "Escape in the car", Steps = {
		{ Key = "Keys", Text = "Find the car keys (his attic hideout, or dad's office)", Target = { "Nest", "OfficeKeys" } },
		{ Key = "Garage", Text = "Open the garage door", Target = "GarageButton" },
		{ Key = "Drive", Text = "Drive away", Target = "Car" },
	} },
	Trap = { Title = "(Optional) Lock him in the basement", Steps = {
		{ Key = "Lock", Text = "Lure him down, then lock the basement door", Target = "Door_Basement" },
	} },
	Rescue = { Title = "Free your friend", Steps = {
		{ Key = "Free", Text = "Cut them loose in the boiler room", Target = "Boiler" },
	} },
	Survive = { Title = "Survive until the police arrive" },
}

---------------------------------------------------------------------------
-- Readable documents (Id -> content). ObserverExtra is only shown to the Observer role.
---------------------------------------------------------------------------
Story.Documents = {
	Menu = {
		Title = "Tony's Pizza - menu",
		Body = "TONY'S PIZZA  ·  Hollis Creek\n\nLarge cheese ........ 14.99\nLarge pepperoni ..... 16.99\nHalf & half ......... 17.49\n\nWE DELIVER!  555-0142\n\n(Mom's handwriting in the corner: 'the usual - 2 large, half mushroom')",
	},
	FridgeNote = {
		Title = "Note on the fridge",
		Body = "Jamie -\n\nBack Sunday night. Pizza money is in the drawer by the phone. Friends are FINE, parties are NOT.\n\nLock up. Don't let Lily's fish die.\n\nLove, Mom\n\nP.S. The garage keypad is acting up again. Don't use it, Dad will call the company Monday.",
		ObserverExtra = "The keypad has been 'acting up' for weeks. The note says so like it's old news.",
	},
	WarmMug = {
		Title = "A mug in the sink",
		Body = "A chipped mug with an inch of black coffee in it.\n\nIt's still warm.",
		ObserverExtra = "Nobody here drinks black coffee. Jamie's parents left at noon.",
	},
	Invoice = {
		Title = "Invoice - Vane Home Services",
		Body = "VANE HOME SERVICES\nInvoice #0412 - April 9\n\n14 Alder Ln - Attic insulation, soffit vent repair,\nhatch weatherstrip (main hall + garage)\n\nTechnician: Curtis Vane\n\nNote: Garage keypad temp code set to 4-1-9-7 for crew access. PLEASE RESET after job completion.",
		ObserverExtra = "There's no sign anyone ever reset it. Mom's note says the keypad is 'acting up'.",
	},
	LilyDrawing = {
		Title = "Lily's drawing",
		Body = "A crayon drawing. Lily in her bed. The ceiling is drawn as a thick brown line, and above it is a tall gray man lying flat, looking down through a square.\n\nIn careful letters: 'THE CEILING MAN SAYS SHHH'",
		ObserverExtra = "The square in the drawing is exactly where the attic hatch is.",
	},
	Notebook = {
		Title = "A spiral notebook",
		Body = "DAY 1. Code still works. Nobody changed it. Nobody ever changes it.\n\nDAY 4. Tues/Thurs swim 5-7. Mon trash. He leaves at 6:40. She leaves at 7:55. The house is empty 8:10 - 2:50.\n\nDAY 9. The little one saw me. Stood in the hall in the dark and looked right at me. She thinks I'm a dream. Her mother told her so. Good.\n\nDAY 17. I fixed the dripping tap in the upstairs bath. Nobody noticed. It's MY house more than theirs. I take care of it.\n\nDAY 19. Wedding in Ohio. All four of them, Fri-Sun. THREE DAYS.\n\nFRIDAY. Car in the driveway 8:39. Voices. Not them. KIDS.\nWhy are there kids.",
		ObserverExtra = "The last line is pressed so hard the pen tore the paper.",
		Discovery = true,
	},
	Polaroids = {
		Title = "Polaroids, pinned to a rafter",
		Body = "Dozens of photos. The family at dinner, shot from the dark top of the stairs. Dad asleep on the couch. Mom in the kitchen. Lily asleep, taken from above, through a gap.\n\nThe newest one is of the driveway tonight. Your friends, getting out of the car.",
		Discovery = true,
	},
	Footprints = {
		Title = "Muddy footprints",
		Body = "Boot prints in drying mud, from the side door to the stepladder under the ceiling hatch.\n\nBig ones. Size 12, maybe 13.",
		ObserverExtra = "Nobody in this house wears a size 12. Jamie's dad is a size 9.",
	},
	Breaker = {
		Title = "Breaker panel",
		Body = "The MAIN switch at the top of the panel is in the OFF position.\n\nIndividual breakers trip in a storm. The main doesn't flip itself.",
	},
	JunctionBox = {
		Title = "Phone junction box",
		Body = "The gray box on the garage wall is hanging open.\n\nThe phone line has been cut clean through. Not torn - cut.",
	},
	TrashCan = {
		Title = "Kitchen trash",
		Body = "On top of the trash: the glass lasagna dish Mom left for you. Scraped completely clean.",
		ObserverExtra = "It was full when Jamie checked the fridge at 7.",
	},
	WetShower = {
		Title = "Upstairs shower",
		Body = "The shower walls are beaded with water. The bath mat is damp. There's a single long gray hair in the drain.",
		ObserverExtra = "Nobody's showered here since this morning. Water doesn't stay on tiles for twelve hours.",
	},
	EmptyHook = {
		Title = "The key hook",
		Body = "Four hooks by the back door. The one labeled HONDA is empty.",
	},
	Lanyard = {
		Title = "A worn lanyard",
		Body = "A laminated contractor ID: CURTIS VANE - VANE HOME SERVICES. The photo is of a clean-shaven, smiling man. Someone has scratched out the eyes.",
		Discovery = true,
	},
}

---------------------------------------------------------------------------
-- Phone texts. Delivered over Wi-Fi (they stop when the power goes out).
-- At = seconds since the act started. Role = only this role gets it (nil = everyone).
---------------------------------------------------------------------------
-- (They wait for a quiet moment: never on top of a thought line or a conversation.)
-- sent only on a solo night, a little after it starts
Story.SoloTexts = {
	{ From = "Riley", Body = "creek rd is flooded, we had to turn around" },
	{ From = "Morgan", Body = "sorry!! next weekend" },
}

Story.Texts = {
	Evening = {
		{ At = 60, From = "Hollis Creek Alerts", Body = "FLASH FLOOD WARNING until 6 AM. Creek Rd closed." },
	},
	SmallThings = {
		{ At = 50, From = "Mrs. Okafor (next door)", Body = "Jamie is your dad's friend still staying with you? I saw a man at your side door Tuesday", Role = "Host" },
	},
}

---------------------------------------------------------------------------
-- Act II: Mom texts about the news. You answer on your phone (pick a reply), then go and watch.
---------------------------------------------------------------------------
Story.MomNews = {
	Texts = {
		"Are you watching the news? Put channel 7 on",
		"A man has been getting into houses in Hollis Creek. Living in them while the families are away",
	},
	Ask = {
		"We're fine. Doors are locked",
		"Mom you're scaring me",
	},
	Answers = {
		"Good. Keep them locked. Watch 7",
		"I'm sorry honey. Just watch 7. Please",
	},
	After = "Text me after. Love you",
	-- once the report has been on for a while (one round of replies is enough: 13 Oct, "too much text")
	Thoughts = {
		"For weeks. And nobody noticed.",
	},
}

---------------------------------------------------------------------------
-- Banter: the friends talking to each other out loud (dialogue box, no choices).
-- Slots are filled with different players standing near each other: "Host" is whoever
-- plays Jamie, numbers are anyone else. A scene needs at least two people; lines whose
-- slot can't be filled are dropped when Optional, otherwise the scene waits for later.
---------------------------------------------------------------------------
Story.Banter = {
	-- (13 Oct, "the writing feels fake": fewer, shorter lines, said the way people actually talk)
	Evening = {},
	SmallThings = {
		{ At = 40, Lines = {
			{ 1, "Did you hear that? Upstairs." },
			{ 2, "It's the storm." },
			{ 1, "That was footsteps." },
		} },
		{ At = 140, Lines = {
			{ 1, "Who's upstairs?" },
			{ 2, "Nobody. We're all here." },
		} },
	},
	Guest = {
		{ At = 25, Lines = {
			{ 1, "He's in the house." },
			{ 2, "Bathroom window. Call 911." },
		} },
		{ At = 100, Lines = {
			{ 1, "Keep your voice down." },
			{ 2, "He hears everything." },
		} },
	},
	-- said a few seconds after an event, if two people are standing together
	React = {
		PlateCrash = { Lines = {
			{ 1, "What was that?" },
			{ 2, "The kitchen. Nobody's in there." },
		} },
		CeilingThud = { Lines = {
			{ 1, "That was the ceiling." },
			{ 2, "Don't." },
		} },
		WindSlam = { Lines = {
			{ 1, "Jesus." },
			{ 2, "Just a door. Just the wind." },
		} },
		FootstepsUpstairs = { Lines = {
			{ 1, "Someone's upstairs." },
			{ 2, "We're all down here." },
		} },
		TVAlert = { Lines = {
			{ 1, "Who touched the TV?" },
			{ 2, "Nobody." },
		} },
		Flicker = { Lines = {
			{ 1, "Don't go out. Don't go out." },
		} },
		DoorRattle = { Lines = {
			{ 1, "Someone's trying the door." },
			{ 2, "It's locked. Right?" },
		} },
		ChairDrop = { Lines = {
			{ 1, "You go look." },
			{ 2, "No way." },
		} },
		MusicBox = { Lines = {
			{ 1, "That's Lily's music box." },
			{ 2, "Someone has to wind it." },
		} },
		ShowerRan = { Lines = {
			{ 1, "Why is the shower on?" },
			{ 2, "I'm not going up there." },
		} },
		LightUpstairs = { Lines = {
			{ 1, "That light was off." },
		} },
		BackDoorOpen = { Lines = {
			{ 1, "Who opened the back door?" },
			{ 2, "Those aren't our footprints." },
		} },
		WindowBang = { Lines = {
			{ 1, "Get away from the window." },
		} },
	},
	SomeoneElse = {
		{ At = 20, Lines = {
			{ 1, "That wasn't the storm." },
			{ 2, "Stay close." },
		} },
	},
}

---------------------------------------------------------------------------
-- Scripted phone calls (landline). Lines are captions shown to people near the phone.
---------------------------------------------------------------------------
Story.Calls = {
	OrderPizza = {
		"Tony's, hold on...",
		"Two large, half mushroom, 14 Alder? About an hour with this rain.",
	},
	Silent = {
		"...",
		"(Nobody speaks. Just breathing. And, faintly, your own TV. Through the line.)",
		"(Click.)",
	},
	Dead = {
		"(No dial tone. The line's dead.)",
	},
	Dispatch = {
		"911, what's your emergency?",
		"Someone's in your house. Okay. Can you hide somewhere?",
		"Officers are on the way. Creek Road's flooded, so it'll be a few minutes. Stay hidden.",
	},
	NotYet = {
		"(And say what? \"I heard a noise\"?)",
	},
}

---------------------------------------------------------------------------
-- TV channels
---------------------------------------------------------------------------
Story.TV = {
	{ Name = "Ch 4 - Movie", Screen = "Movie", Line = "An old black-and-white movie. A couple hear noises upstairs." },
	{ Name = "Ch 7 - News", Screen = "News", Line = "Channel 7. A news anchor, and a photo box that just says SUSPECT." },
	{ Name = "Ch 11 - Weather", Screen = "Weather", Line = "Channel 11. The weather, and a lot of red on the map." },
	{ Name = "Ch 12 - Static", Screen = "Static", Line = "No signal. The cable box can't find anything.", Sound = "TVStatic" },
}

--[[
	What the people on TV say (client TVVoice: Roblox text-to-speech, max 300 characters a line).
	Voices: "3" US male, "4" US female, "1" British male, "2" British female. Each line is also
	captioned when spoken.
]]
Story.TVVoice = {
	News = {
		{ Voice = "3", Text = "Good evening. Our top story tonight: police in Hollis Creek are searching for a man they believe has been living inside people's homes, sometimes for weeks, while the families were out." },
		{ Voice = "3", Text = "Residents describe food going missing, doors found unlocked, and noises in the walls and the ceiling at night. In every case, nothing of value was taken." },
		{ Voice = "3", Text = "Police describe him as a tall man in his forties, last seen driving a gray panel van. If you see him, do not approach him. Lock your doors, and call nine one one." },
		{ Voice = "3", Text = "And with Creek Road closed by flooding, officers say response times tonight may be longer than usual. Stay inside. Stay safe. Back after this." },
	},
	Weather = {
		{ Voice = "4", Text = "Here's your storm update. Heavy rain continues across Hollis County tonight, with another four inches expected before morning." },
		{ Voice = "4", Text = "A flash flood warning is in effect until six A M. Creek Road is closed in both directions. If you don't have to go out tonight, please don't." },
	},
	Movie = {
		{ Voice = "1", Text = "Did you hear that, Margaret?" },
		{ Voice = "2", Text = "It's the house settling. Old houses settle." },
		{ Voice = "1", Text = "Houses don't breathe." },
		{ Voice = "2", Text = "Then who's been eating the bread?" },
		{ Voice = "1", Text = "Go back to sleep. Nobody's up there." },
	},
}

---------------------------------------------------------------------------
-- Dialogue. Each node: Speaker + Lines, then either Choices ({ Say, Next }) or Next, or End.
-- Speaker "" is narration.
---------------------------------------------------------------------------
Story.Dialogue = {
	Pizza = {
		Start = "hello",
		Nodes = {
			hello = {
				Speaker = "Delivery man",
				Lines = {
					"Whitaker? Two large. Half mushroom.",
				},
				Choices = {
					{ Say = "That's us. How much?", Next = "paid" },
					{ Say = "You're not the usual guy.", Next = "usual" },
				},
			},
			paid = {
				Speaker = "Delivery man",
				Lines = {
					"Your mom paid on the phone.",
					"He looks past you, down the dark hallway.",
					"Big house.",
				},
				Narrate = { [2] = true },
				Next = "alone",
			},
			usual = {
				Speaker = "Delivery man",
				Lines = {
					"Nobody else would drive out here tonight.",
					"He looks past you, down the dark hallway.",
					"Big house.",
				},
				Narrate = { [2] = true },
				Next = "alone",
			},
			alone = {
				Speaker = "Delivery man",
				Lines = { "Just you kids in there?" },
				Choices = {
					{ Say = "No. My dad's upstairs.", Next = "dad" },
					{ Say = "...Yeah. Just us.", Next = "justus" },
				},
			},
			dad = {
				Speaker = "Delivery man",
				Lines = {
					"He looks up at the dark windows.",
					"Sure he is.",
					"Lock your doors.",
				},
				Narrate = { [1] = true },
				Next = "leave",
			},
			justus = {
				Speaker = "Delivery man",
				Lines = {
					"Huh.",
					"Lock your doors. All of them.",
				},
				Next = "leave",
			},
			leave = {
				Speaker = "",
				Lines = {
					"He backs down the steps, still looking up at the house.",
				},
				End = true,
			},
		},
	},
}

---------------------------------------------------------------------------
-- What Really Happened — explanations logged when events actually fire.
---------------------------------------------------------------------------
Story.Truths = {
	BackDoorUnlocked = "The back door was unlocked because Curtis came back in through it at 8:30 PM. When headlights swept the kitchen, he ran for the attic and forgot it.",
	WarmMug = "The coffee was Curtis's. He made it at 8:15 and left it in the sink when he heard the car.",
	HatchStuck = "The attic hatch was stuck because Curtis had bungee-corded it shut from above.",
	CordSwing = "The hatch cord was swinging because Curtis had just climbed up and pulled the hatch closed behind him.",
	FootstepsUpstairs = "The footsteps upstairs were Curtis, crossing from Lily's room to the hatch. He'd been watching you from the top of the stairs.",
	DoorAjar = "The door that opened was Curtis, moving between rooms while nobody was looking.",
	FoodMissing = "The lasagna was eaten by Curtis. He hadn't eaten since Thursday.",
	MusicBox = "Lily's music box was wound by Curtis from inside her closet. He wanted to see which of you would come up to check, and who would come alone.",
	LightUpstairs = "The light that came on in Lily's room was Curtis, searching her dresser for the spare house key she keeps in a jewelry box.",
	BackDoorOpen = "The back door blew open because Curtis went out to the van for his tools and came back in through it, leaving it unlatched. Those were his wet boot prints.",
	WetShower = "The shower was wet because Curtis showered at 7:50 PM, the way he did every Friday while the family was at swim practice.",
	SilentCall = "The silent call was Curtis, on his prepaid phone in the attic, counting your voices through the line.",
	WindSlam = "The door that slammed upstairs really was the storm - the draft from the windows nobody had closed yet.",
	PlateCrash = "The plate that shattered in the kitchen was knocked off the table by Curtis, crossing to the back door in the dark. He stood perfectly still until you stopped looking.",
	CeilingThud = "The thud in the ceiling was Curtis, shifting his weight on the attic joists to watch you through the vent.",
	WindowBang = "The bang on the window was Curtis, outside after moving his van. He wanted to see which way you'd run.",
	DoorRattle = "The rattling door handle was Curtis, outside, testing whether you'd locked up.",
	ChairDrop = "The chair that fell over was Curtis, knocking it flying as he bolted after you spotted him.",
	Thunderclap = "The crack that shook the house was lightning hitting the Hendersons' oak across the street. Just the storm.",
	DoorHeld = "The door that was yanked shut in your face was Curtis, holding the handle from the other side. He ran the moment you let go.",
	FigureWindow = "The figure at the window was Curtis. He went out the garage side door to move his van before anyone noticed it, and stopped when he saw you.",
	DogBark = "Biscuit was barking at Curtis walking along the side yard.",
	TVAlert = "The TV changed on its own because an Emergency Alert System broadcast (a real flash-flood warning) overrode the channel.",
	Flicker = "The lights flickered because of the storm. Not everything was him.",
	PowerOut = "The power went out because Curtis flipped the main breaker in the garage so he could move through the house in the dark.",
	LineCut = "The phone was dead because Curtis cut the line at the junction box on the garage wall.",
	KeysTaken = "The car keys disappeared because Curtis took them off the hook so nobody could drive for help.",
	Glimpse = "The shape at the end of the hall was Curtis. He was deciding what to do about you.",
	PizzaGuy = "The delivery man was Ray Tolliver, Tony's nephew, on his last run before the creek closed the road. He was strange, and he stared too long, but he had nothing to do with any of it. The real stranger had been above your heads the whole time.",
	Floorboard = "The floorboard creak overhead was Curtis shifting his weight in the attic, directly above you.",
	LilyNightlight = "Lily's nightlight was on because Lily always leaves it on. The ceiling man never bothered to turn it off.",
}

---------------------------------------------------------------------------
-- Inner monologue. Lines are "text|hint": the hint key becomes a control tip for the
-- player's device (keyboard, touch or gamepad) on a smaller second line.
---------------------------------------------------------------------------
-- First time someone walks into a room during the first act (one line each, only when quiet).
-- Host lines are Jamie's own house; Guest lines are a friend visiting.
Story.RoomThoughts = {
	-- (empty since 13 Oct: a line for every room was "too much text")
	Host = {},
	Guest = {},
}

Story.Thoughts = {
	Intro = {
		Host = {
			"Pizza first. The menu's on the fridge.|journal",
		},
		Guest = {
			"Pizza first. The menu's on the fridge.|journal",
		},
	},
	-- a solo night: the friends never make it
	SoloIntro = {
		"Pizza first. The menu's on the fridge.|journal",
		"The others should be here soon.",
	},
	SoloFriendsStuck = "They're not coming. It's just me.",
	Objectives = {
		OrderPizza = "The menu's on the fridge. Then the kitchen phone.",
		Popcorn = "Popcorn's in the kitchen cupboard.",
		LockUp = "Back door. Garage door. Lock them.",
		Windows = "The windows upstairs are open.",
		Fire = "Firewood's in the garage.",
		Movie = "Where's the remote?",
		Door = "The doorbell. Pizza.",
		Investigate = "Someone has to go up and look.",
		Bedtime = "Teeth. Then bed.",
		Power = "The breaker panel's in the garage.",
		Phone = "The phone's dead. The line outside?",
		Attic = "What's in the attic?",
		Call911 = "Call 911. One bar by the upstairs bathroom window.|phone",
		Neighbor = "Mrs. Okafor's next door.",
		Car = "Car keys. Then we drive.",
		Rescue = "He took someone. The boiler room.",
	},
	Acts = {
		SmallThings = {
			"That guy was weird.",
		},
		SomeoneElse = {
			"The power's out. All of it.",
			"Only signal's by the upstairs bathroom window.|phone",
		},
		Guest = {
			"He's been living up there.",
			"Get help. If he comes, hide.",
		},
	},
	Events = {
		FootstepsUpstairs = "Someone's walking upstairs.",
		DoorAjar = "That door was shut.",
		CordSwing = "The attic cord's swinging.",
		FigureWindow = "Someone was at the window.",
		TVAlert = "The TV changed by itself.",
		SilentCall = "Someone's just... breathing.",
		Glimpse = "Someone's at the end of the hall.",
		WindSlam = "A door. Upstairs.",
		PlateCrash = "Something broke in the kitchen.",
		CeilingThud = "That was right above me.",
		WindowBang = "Get away from the window.",
		DoorRattle = "Someone's trying the door.",
		ChairDrop = "That chair just fell over.",
		MusicBox = "Lily's music box. Lily isn't home.",
		ShowerRan = "The shower just came on.",
		LightUpstairs = "Lily's light just came on.",
		BackDoorOpen = "The back door's open. Footprints.",
		WallKnock = "Something's knocking. In the wall.",
		InvestigateDone = "Nothing. Just the attic cord, swinging.",
	},
	-- only the ones that tell you what an item is for
	Items = {
		Flashlight = "A flashlight.|light",
		PepperSpray = "Pepper spray. Only if he's close.|spray",
		CarKeys = "The car keys.",
		ElectricalTape = "Tape. For the phone line.",
		BasementKey = "The basement key.",
		Scissors = "Scissors. For zip ties.",
	},
	Hide = "Stay quiet.|breath",
	Captured = "Tied to a pipe. Get loose, or wait for help.|struggle",
}

---------------------------------------------------------------------------
-- Endings
---------------------------------------------------------------------------
Story.Endings = {
	CaseClosed = {
		Short = "The police arrived, and you'd already worked out who he was.",
		Title = "CASE CLOSED",
		Body = "The police find four soaked, shaking teenagers who have already solved it.\n\nThe coffee in the sink. The invoice from VANE HOME SERVICES. The lanyard with the eyes scratched out. The photos from the top of the stairs. Nineteen days of it, laid out on the kitchen table.\n\nCurtis Vane is picked up at the van before he can start the engine. Detective Ruiz reads your notes twice.\n\n'You kids did half my job,' she says. 'Go home. Well. Stay home.'",
	},
	Sirens = {
		Short = "The police arrived in time. Curtis Vane was arrested.",
		Title = "SIRENS",
		Body = "Blue and red light floods the rain. Two cruisers, then a third.\n\nCurtis Vane is arrested forty minutes later, sitting in a gray van two streets away, soaked through, with nowhere left to go.\n\nOn Monday, Jamie's dad resets the garage code. It had been 4-1-9-7 since April.",
	},
	LockedIn = {
		Short = "You locked him in the basement until the police came.",
		Title = "LOCKED IN",
		Body = "When the officers open the basement door, Curtis Vane is sitting on the bottom step with his hands already raised.\n\n'It's my house too,' he tells them. 'I take care of it.'\n\nNineteen days. Nobody ever changed the code.",
	},
	Taillights = {
		Short = "You drove away in Mom's car and brought the police back.",
		Title = "TAILLIGHTS",
		Body = "The Honda fishtails down the flooded hill, headlights full of rain, and doesn't stop until the gas station on Route 9.\n\nThe police go up to 14 Alder Lane without you. They find an attic full of photographs of a family who never knew they had a guest.",
	},
	NextDoor = {
		Short = "Mrs. Okafor let you in and called the police.",
		Title = "NEXT DOOR",
		Body = "Mrs. Okafor opens the door in her robe, takes one look at your face and pulls you in out of the rain.\n\n'I KNEW that wasn't your father's friend,' she says, already dialing.\n\nBiscuit doesn't stop barking at the Whitaker house until the police arrive.",
	},
	GoneQuiet = {
		Short = "Nobody came. He took everyone.",
		Title = "GONE QUIET",
		Body = "Nobody calls. Nobody comes.\n\nJamie's parents come home on Sunday night to a dark house and a basement door locked from the outside. Everyone inside is alive: cold, terrified, zip-tied to the pipes.\n\nCurtis Vane's van is found abandoned at a rest stop in Indiana. He is still out there. Somewhere with an attic.",
		Bad = true,
	},
	GotAway = {
		Short = "Help came too late. He got away.",
		Title = "HE GOT AWAY",
		Body = "By the time the police kick in the front door, the house is silent.\n\nThe back door is open. Rain on the kitchen floor. Muddy prints going out, none coming back.\n\nThey search the house room by room. The attic is empty, except for the photographs. Hundreds of them. Every one of you.\n\nCurtis Vane was never found.",
		Bad = true,
	},
	NotYourFamily = {
		Short = "You found the old storm cellar and climbed out of what he dug under the house.",
		Title = "NOT YOUR FAMILY",
		Body = "You come up through the grate into the wet grass of the back yard, gasping, filthy, alive.\n\nThe police find the tunnels by noon: a dining room under the boiler, a nursery, a pantry of food stolen a meal at a time, nineteen tally marks on a wall of dirt.\n\nThey find Curtis Vane at the head of the table, in Jamie's dad's sweater, waiting for everyone to come back for dessert.",
		Secret = true,
	},
	ForeverFamily = {
		Short = "Nobody left the table. Nobody ever left the table again.",
		Title = "FOREVER FAMILY",
		Body = "The candles burn down. He tucks you in, one by one, under the house.\n\nOn Sunday night Jamie's parents come home to a quiet house and a note on the fridge in handwriting that isn't theirs: GONE TO GRANDMA'S. DON'T WORRY ABOUT US.\n\nThe police search for a month. The tunnels are found in the spring, when the lawn caves in by the swing set. The table is still set.",
		Bad = true,
		Secret = true,
	},
	Dawn = {
		Short = "You lasted the whole night.",
		Title = "DAWN",
		Body = "The rain stops a little after five. Gray light, a dripping gutter, and then - finally - sirens.\n\nA neighbor on Birch Street had called about a gray van that hadn't moved in three weeks. The officer who ran the plate made the connection to the break-ins.\n\nYou lasted the whole night.",
	},
}

-- shown once, the first night someone plays, when he starts moving around the house
Story.SurvivalTipsVersion = 4 -- (bump when the tips change: everyone sees them once more)
Story.SurvivalTips = {
	Title = "HE'S IN THE HOUSE",
	Body = "• CALL 911 from the upstairs bathroom window. Then hide.\n• He hunts by sound. Crouch near him. Never run near him.\n• Floor shaking? He's close. Hide: closets, wardrobes, under beds, the shower.\n• If he stops at your spot, keep your heartbeat steady.",
	Button = "GOT IT",
}

-- The hunt (server/Intruder): what your character thinks when he starts coming
Story.Hunt = {
	First = {
		"He's running. He heard us.",
	},
	FirstNotice = "He follows sound. Crouch. Never run near him.",
	Wave = {
		"A door slammed.",
		"He's coming. Hide.",
		"Footsteps. Closer.",
	},
	Seen = "He saw me. Run. Then hide.",
}

-- Evidence: the clue documents that tell you who he is. Read enough of them (between you)
-- before the police arrive and "Sirens" becomes the secret ending "Case Closed".
Story.Evidence = { "WarmMug", "Invoice", "LilyDrawing", "Notebook", "Polaroids", "Footprints", "TrashCan", "WetShower", "EmptyHook", "Lanyard" }
Story.EvidenceNeeded = 7

-- The lobby's endings collection: display order and a hint for the ones not found yet
Story.EndingOrder = { "Sirens", "CaseClosed", "NextDoor", "Taillights", "LockedIn", "Dawn", "GoneQuiet", "GotAway", "NotYourFamily", "ForeverFamily" }
Story.EndingHints = {
	Sirens = "Get a call through to 911 and hold out until they come.",
	CaseClosed = "When the police come, have the whole story ready. Read everything.",
	NextDoor = "Someone next door is still awake.",
	Taillights = "Mom's car is in the garage. The keys are not where they should be.",
	LockedIn = "The basement door locks from the outside.",
	Dawn = "Just... last until morning.",
	GoneQuiet = "Tied up, alone, and nobody coming.",
	NotYourFamily = "What if he takes ALL of you at once? (2+ players) ...and you get out.",
	ForeverFamily = "What if he takes ALL of you at once? (2+ players) ...and you don't.",
	GotAway = "Help is on the way. Don't let him take everyone before it arrives.",
}

-- the headline on your own result card, by how your night ended
Story.Results = {
	Survived = { Title = "YOU SURVIVED", Good = true },
	Escaped = { Title = "YOU ESCAPED", Good = true },
	Died = { Title = "YOU DIED", Good = false },
	Taken = { Title = "YOU WERE TAKEN", Good = false },
}
-- the death card's tip: how he got you, and how to get away next time (CaptureService.kill)
Story.DeathTips = {
	Open = "He's slower than you. Run, break his line of sight, then hide.",
	Hiding = "When he checks your spot, press each side as it reaches the heart.",
	Call = "The call is loud and he comes running. Hide the second it goes through.",
	Default = "His footsteps get louder as he gets closer. Hide before he turns the corner.",
}
-- the one line under it when you're out before the night is over (co-op)
Story.ResultLines = {
	Burrow = "You climbed out through the grate in the back yard. Your friends are still down there.",
	Car = "You drove away in Mom's car. Your friends are still inside.",
	Neighbor = "Mrs. Okafor pulled you inside. Your friends are still in the house.",
	Died = "He caught you a second time. Your friends are still in the house.",
}

--[[
	The secret ending (FinaleService): everyone tied up at once, and he takes you all down to
	the family he's made under the house. %d marks are the lock code's digits (a new code every time).
]]
Story.Finale = {
	Intro = {
		"He doesn't take you to the boiler room. Not this time.",
		"Behind the boiler there's a hole in the wall. A ladder. Candlelight.",
	},
	Seated = "You're zip-tied to a chair at a long table. There's a card with your name on it.",
	Rules = "FAMILY DINNER. NOBODY LEAVES THE TABLE. FATHER IS WATCHING.",
	Tips = "When his back is turned: STRUGGLE to break the zip tie. When he turns around: DON'T MOVE.",
	Strike = { "He slams his hand down on the table. The plates jump.", "He leans over you and breathes, slow, through his teeth.", "He pulls your chair back in. Tighter this time." },
	FreeSelf = "The zip tie snaps!",
	FreeTip = "You're free. While he WATCHES: stand still by your chair. While his BACK is turned: go to a friend and HOLD to cut them loose.",
	AllFree = "He picks up a candle. \"Dessert,\" he says, the only word all night, and climbs the ladder up into the house.",
	Away = "He's gone up to the house. Get the lock code from his 3 NOTES (pantry, nursery, his room), then get out through the STORM CELLAR. Follow the signs.",
	Back = "The hatch creaks. He's coming back down. Keep out of his sight: crouch behind a hanging blanket to hide.",
	NoteFound = "%s read the note in the %s. The code so far: %s",
	CodeDone = "That's the whole code: %s. Go to the STORM CELLAR (north tunnel) and type it on the keypad.",
	Caught = "He carries you back to the table, humming. Somebody cut you loose. Please.",
	WrongCode = "[The lock buzzes. Loud.]",
	Unlocked = "The lock clicks open. The hatch above is stiff with rust: push it open!",
	DoorBarred = "You drop the bar across the door.",
	DoorBreaks = "[The door splinters]",
	Bedtime = "The candles are guttering. It's bedtime.",
	Out = "Rain on your face. Grass under your hands. You're out.",
	Notes = {
		Pantry = { Title = "A shopping list", Body = "DINNER FOR SIX\n\n- pizza (they ordered it themselves! good kids)\n- milk for the little one\n- the lasagna Margaret made (she won't mind)\n- candles. LOTS of candles\n\n\nfor the cellar lock, so I don't forget again:\nthe FIRST number is %d" },
		Nursery = { Title = "A card in the crib", Body = "For the little one.\n\nI made a doll for each of them, so nobody is ever alone down here. The blue one is Jamie. Jamie doesn't like me yet. Jamie will.\n\nShe has her mother's eyes.\n\n\n(on the back, in pencil)\nlock: the SECOND number is %d" },
		HisRoom = { Title = "A page torn from a notebook", Body = "Day 19.\n\nMargaret took the kids to Ohio in March. The bank took Birch Street in May. I fixed this family's furnace in April and I never really left.\n\nThey're out all day. The house is so empty. Houses shouldn't be empty.\n\nTonight we eat together. Tonight we are a family again.\n\nNobody leaves the table.\n\n\nthe last two numbers of the lock: %d and %d" },
	},
	Photo = { Title = "A burnt photograph", Body = "A family on a porch: a man in a VANE HOME SERVICES cap, a woman, a boy, a girl.\n\nSomeone has burned the woman's face out with a cigarette, very carefully." },
	Grate = { Title = "An old storm cellar grate", Body = "A rusted grate in the lawn. It doesn't move.\n\nBut somebody has scraped the rust off the hinges. From underneath." },
}

Story.Fates = {
	Escaped = "Escaped",
	Safe = "Safe",
	Rescued = "Found by police",
	Captured = "Captured",
	Dead = "Didn't make it",
}

return Story
