--[[
	Story — every word of narrative content in the game.
	Keeping writing out of code lets it be edited (and localized) in one place.
]]

local Story = {}

Story.Title = "HOME ALONE"
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
	Evening = { Title = "I. Friday Night", Sub = "The Whitaker house. Parents out of state until Sunday." },
	SmallThings = { Title = "II. Small Things", Sub = "The storm is getting worse." },
	SomeoneElse = { Title = "III. Someone Else", Sub = "Breakers don't flip themselves." },
	Guest = { Title = "IV. The Guest", Sub = "He knows you found him." },
}

---------------------------------------------------------------------------
-- Objectives
---------------------------------------------------------------------------
Story.Objectives = {
	OrderPizza = "Order pizza (kitchen phone)",
	Popcorn = "Make popcorn (microwave)",
	Windows = "Close the upstairs windows before the storm",

	Explore = "Figure out what that noise was",

	Power = "Restore the power (breaker panel, garage)",
	Phone = "Call someone for help",
	Attic = "Find out what's in the attic",

	Call911 = "Call 911 - fix the phone line outside, or find a cell signal upstairs",
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
		{ Key = "Menu", Text = "Find the pizza menu on the fridge", Target = "Fridge" },
		{ Key = "Call", Text = "Call Tony's Pizza on the kitchen phone", Target = "Phone" },
	} },
	Popcorn = { Title = "Make popcorn", Steps = {
		{ Key = "Bag", Text = "Get a bag of popcorn from the kitchen cupboard", Target = "Cupboard" },
		{ Key = "Cook", Text = "Pop it in the microwave", Target = "Microwave" },
	} },
	Windows = { Title = "Close the upstairs windows", Steps = {
		{ Key = "GuestFront", Text = "Close the window in the guest room", Target = "GuestWindow" },
		{ Key = "LilyBack", Text = "Close the window in Lily's room", Target = "LilyWindow" },
	} },
	Door = { Title = "Answer the door", Steps = {
		{ Key = "Answer", Text = "The pizza's here. Answer the front door", Target = "Door_FrontDoor" },
	} },
	-- Act II
	News = { Title = "Watch the news", Steps = {
		{ Key = "TV", Text = "Turn on the TV in the living room", Target = "TV" },
		{ Key = "Ch7", Text = "Change to channel 7", Target = "TV" },
		{ Key = "Watch", Text = "Watch the report", Target = "TV" },
	} },
	LockUp = { Title = "Lock up for the night", Steps = {
		{ Key = "BackDoor", Text = "Lock the back door in the kitchen", Target = "Door_BackDoor" },
		{ Key = "GarageSide", Text = "Lock the garage side door", Target = "Door_GarageSide" },
	} },
	Investigate = { Title = "Check upstairs", Steps = {
		{ Key = "Look", Text = "Find out what made that noise upstairs", Target = "Hatch" },
	} },
	-- Act III
	Power = { Title = "Get the power back on", Steps = {
		{ Key = "Flashlight", Text = "Find a flashlight (search the drawers and shelves)", Target = { "Flashlight1", "Flashlight2" } },
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
		{ Key = "Call", Text = "Fix the phone line outside, or find a signal by the upstairs bathroom window", Target = { "JunctionBox", "SignalSpot" } },
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
	{ From = "Riley", Body = "creek rd is literally underwater. we had to turn around 😭" },
	{ From = "Morgan", Body = "so sorry!! next weekend for sure. stay dry, don't get murdered lol" },
}

Story.Texts = {
	Evening = {
		{ At = 35, From = "Mom", Body = "Landed! Hotel is nice. Eat something real please. Love you", Role = "Host" },
		{ At = 150, From = "Dad", Body = "Don't touch the thermostat. And lock the back door, it sticks.", Role = "Host" },
		{ At = 250, From = "Hollis Creek Alerts", Body = "FLASH FLOOD WARNING in effect until 6 AM. Creek Rd closed. Avoid travel." },
	},
	SmallThings = {
		{ At = 60, From = "Mrs. Okafor (next door)", Body = "Hi Jamie honey! Is your dad's friend still staying with you? I saw a man at the side door Tuesday. Stay dry!", Role = "Host" },
		{ At = 230, From = "Riley's mom", Body = "Roads are bad honey, stay over at Jamie's tonight ok?", Role = "Tinkerer" },
	},
}

---------------------------------------------------------------------------
-- Act II: Mom texts about the news. You answer on your phone (pick a reply), then go and watch.
---------------------------------------------------------------------------
Story.MomNews = {
	Texts = {
		"Are you watching the news?? Turn on channel 7 right now.",
		"They're saying a man has been getting into houses here in Hollis Creek. Living in them while the families are out.",
	},
	Ask = {
		"What?? We're fine. The doors are locked.",
		"Mom you're scaring me. What does he look like?",
	},
	Answers = {
		"Good. Keep them locked. Watch channel 7, they're showing what they know.",
		"Tall. They don't have his face. Just watch channel 7, honey. Please.",
	},
	After = "Text me after you've watched it. Love you.",
	-- once the report has been on for a while
	Thoughts = {
		"Living inside houses. For weeks. And nobody noticed.",
		"Mrs. Okafor said she saw a man at our side door on Tuesday...",
	},
	AskAfter = {
		"Watched it. That's really creepy.",
		"Mrs. Okafor saw a man at our side door this week...",
	},
	AnswersAfter = {
		"I know. Stay together tonight, all of you. Call me if anything feels off.",
		"WHAT. Okay. Stay together and keep your phone on you. If anything feels wrong, call 911 first, then me.",
	},
}

---------------------------------------------------------------------------
-- Banter: the friends talking to each other out loud (dialogue box, no choices).
-- Slots are filled with different players standing near each other: "Host" is whoever
-- plays Jamie, numbers are anyone else. A scene needs at least two people; lines whose
-- slot can't be filled are dropped when Optional, otherwise the scene waits for later.
---------------------------------------------------------------------------
Story.Banter = {
	Evening = {
		{ At = 75, Lines = {
			{ 1, "Okay. Who's picking the movie?" },
			{ 2, "Not you. Last time we watched two hours about mold." },
			{ 1, "It was about fungus. It was a thriller." },
		} },
		{ At = 130, Lines = {
			{ 1, "Okay this fire is amazing. I'm never leaving this couch." },
			{ 2, "You say that every time. Then you eat all the popcorn and fall asleep." },
			{ 1, "That's called living my best life." },
		} },
		{ At = 190, Lines = {
			{ 1, "How long till the pizza gets here? I'm actually starving." },
			{ "Host", "Soon. Tony's is always slow when it rains." },
			{ 2, "Is it just me or is it freezing in here?", Optional = true },
		} },
	},
	SmallThings = {
		{ At = 110, Lines = {
			{ 1, "Did you guys lock the back door?" },
			{ "Host", "I... think so?" },
			{ 1, "You think so." },
			{ 2, "Can we please just check." },
		} },
		{ At = 40, Lines = {
			{ 1, "Did anyone else hear that? Upstairs." },
			{ 2, "It's the storm. Old houses creak." },
			{ 1, "Houses don't creak in footsteps." },
		} },
		{ At = 170, Lines = {
			{ 1, "Okay, who keeps walking around upstairs?" },
			{ 2, "Not me." },
			{ 3, "...Not me either.", Optional = true },
			{ "Host", "Everyone's down here. Everyone's been down here." },
		} },
	},
	Guest = {
		{ At = 90, Lines = {
			{ 1, "My phone's at four percent." },
			{ 2, "Then don't waste it. Upstairs bathroom window, that's where the signal is." },
		} },
		{ At = 25, Lines = {
			{ 1, "He's in the house. He is actually in the house." },
			{ 2, "Okay. Nobody panics. We stay together and we get help." },
			{ 3, "And if he finds us?", Optional = true },
			{ 2, "Then we run. Different directions." },
		} },
		{ At = 150, Lines = {
			{ 1, "Keep your voice down. He hears everything." },
			{ 2, "The car. If we get the keys we can just drive." },
		} },
	},
	-- said a few seconds after an event, if two people are standing together
	React = {
		PlateCrash = { Lines = {
			{ 1, "WHAT was that?!" },
			{ 2, "Kitchen. Something fell in the kitchen." },
			{ 1, "Nothing just falls." },
		} },
		CeilingThud = { Lines = {
			{ 1, "That came from the ceiling." },
			{ 2, "Raccoons. It's... it's probably raccoons." },
		} },
		WindSlam = { Lines = {
			{ 1, "Jeez! Just the wind. Right?" },
			{ 2, "Somebody left a window open upstairs." },
		} },
		FootstepsUpstairs = { Lines = {
			{ 1, "Did you hear that? Someone's walking upstairs." },
			{ 2, "Everybody's down here though." },
			{ 1, "Yeah. That's what I mean." },
		} },
		TVAlert = { Lines = {
			{ 1, "Who touched the TV?" },
			{ 2, "Nobody. It changed by itself." },
		} },
		Flicker = { Lines = {
			{ 1, "Please don't go out, please don't go out..." },
			{ 2, "It's the storm. The lines are swinging." },
		} },
		DoorRattle = { Lines = {
			{ 1, "Someone's trying the door." },
			{ 2, "It's locked. It's locked, right?" },
		} },
		ChairDrop = { Lines = {
			{ 1, "What knocked that over?" },
			{ 2, "I'm not going to look. You look." },
		} },
		MusicBox = { Lines = {
			{ 1, "Is that... a music box?" },
			{ 2, "Lily's. It only plays if someone winds it." },
			{ 1, "Then who wound it?" },
		} },
		ShowerRan = { Lines = {
			{ 1, "Why is the shower running?" },
			{ 2, "I'm not going up there. Nope." },
		} },
		LightUpstairs = { Lines = {
			{ 1, "Look. The light's on upstairs." },
			{ 2, "That was off. I swear that was off." },
		} },
		BackDoorOpen = { Lines = {
			{ 1, "Who left the back door open?!" },
			{ 2, "Those aren't our footprints." },
		} },
		WindowBang = { Lines = {
			{ 1, "Something hit the window!" },
			{ 2, "Get away from the glass." },
		} },
	},
	SomeoneElse = {
		{ At = 30, Lines = {
			{ 1, "The whole house doesn't just go dark on its own. Not like that." },
			{ 2, "Stay close. Phones out. Nobody goes anywhere alone." },
		} },
	},
}

---------------------------------------------------------------------------
-- Scripted phone calls (landline). Lines are captions shown to people near the phone.
---------------------------------------------------------------------------
Story.Calls = {
	OrderPizza = {
		"Tony's Pizza, hold please...",
		"...ok, go ahead.",
		"Two large, pepperoni and half-mushroom? 14 Alder. Forty-five minutes, maybe an hour with this rain.",
	},
	Silent = {
		"...",
		"(Nobody speaks. You can hear breathing, and very faintly - your own TV. Through the line.)",
		"(Click.)",
	},
	Dead = {
		"(Nothing. No dial tone. The line is dead.)",
	},
	Dispatch = {
		"911, what's your emergency?",
		"Someone's in your house - okay. Stay on the line. Are you in a safe place?",
		"Units are on the way to 14 Alder Lane. Creek Road is flooded so they're coming around by Route 9. Stay together. Stay hidden.",
	},
	NotYet = {
		"(You hold the phone for a second. What would you even say? 'I heard a noise'?)",
	},
}

---------------------------------------------------------------------------
-- TV channels
---------------------------------------------------------------------------
Story.TV = {
	{ Name = "Ch 4 - Movie", Screen = "Movie", Line = "An old black-and-white movie. A couple hear noises upstairs.", Sound = "TVShow" },
	{ Name = "Ch 7 - News", Screen = "News", Line = "'...a man police believe has been living inside homes in Hollis Creek, sometimes for weeks, while families were out. Food taken. Nothing valuable. Do not approach him...'", Sound = "TVShow" },
	{ Name = "Ch 11 - Weather", Screen = "Weather", Line = "'...four more inches tonight. Creek Road is closed. If you don't have to go out, don't.'", Sound = "TVShow" },
	{ Name = "Ch 12 - Static", Screen = "Static", Line = "No signal. The cable box can't find anything.", Sound = "TVStatic" },
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
					"Delivery for... Whitaker.",
					"Two large. Pepperoni. Half mushroom.",
				},
				Choices = {
					{ Say = "That's us. How much do we owe you?", Next = "paid" },
					{ Say = "You're not the usual guy.", Next = "usual" },
				},
			},
			paid = {
				Speaker = "Delivery man",
				Lines = {
					"Already paid for. Your mom's card.",
					"She was very specific. Two large. Half mushroom.",
				},
				Next = "creek",
			},
			usual = {
				Speaker = "Delivery man",
				Lines = {
					"Tony's nephew. Ray.",
					"The usual guy doesn't like coming out this far at night. Neither do I.",
				},
				Next = "creek",
			},
			creek = {
				Speaker = "Delivery man",
				Lines = {
					"Creek Road's going under. I'm the last one getting through tonight.",
					"He looks past you, into the dark hallway, for a long time.",
					"Nice house. Big. Lots of places to be.",
				},
				Narrate = { [2] = true },
				Choices = {
					{ Say = "Uh... thanks. Drive safe.", Next = "safe" },
					{ Say = "What's that supposed to mean?", Next = "mean" },
				},
			},
			safe = {
				Speaker = "Delivery man",
				Lines = {
					"I always drive safe.",
					"He holds the box out, and doesn't let go of it right away.",
					"Is it just you kids in there?",
				},
				Narrate = { [2] = true },
				Next = "alone",
			},
			mean = {
				Speaker = "Delivery man",
				Lines = {
					"Nothing. Old houses. They creak. They settle.",
					"He tilts his head, like he's listening to something upstairs.",
					"Sometimes it isn't the house. Is it just you kids in there?",
				},
				Narrate = { [2] = true },
				Next = "alone",
			},
			alone = {
				Speaker = "Delivery man",
				Lines = { "..." },
				Choices = {
					{ Say = "No. My dad's upstairs.", Next = "dad" },
					{ Say = "...Yeah. Just us.", Next = "justus" },
				},
			},
			dad = {
				Speaker = "Delivery man",
				Lines = {
					"His eyes go to the dark windows upstairs, and stay there.",
					"Sure he is.",
					"Keep the doors locked. All of them.",
				},
				Narrate = { [1] = true },
				Next = "leave",
			},
			justus = {
				Speaker = "Delivery man",
				Lines = {
					"Huh.",
					"Then you should really keep the doors locked. All of them.",
					"Even the ones you don't use.",
				},
				Next = "leave",
			},
			leave = {
				Speaker = "",
				Lines = {
					"He hands you the pizza. He backs down the steps without turning around, still smiling, until the rain swallows him.",
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
	Host = {
		Living = "The fire's going. This is the best room in the house on a night like this.",
		Kitchen = "Mom stocked the fridge like we're getting snowed in for a month.",
		Den = "Movie night headquarters. Blankets, snacks, the big TV.",
		Jamie = "My room. Home sweet home.",
		Lily = "Lily's room. She'd kill me if she knew we were in here.",
		Master = "Mom and Dad's room. Feels weird being in here without them.",
		Garage = "Freezing in here. Mom's car, Dad's workbench.",
		Basement = "The basement. I never come down here if I can help it.",
		Office = "Dad's office. Everything exactly where he left it.",
	},
	Guest = {
		Living = "Okay, this is cozy. A real fire and everything.",
		Kitchen = "Jamie's mom definitely bought snacks for an army.",
		Den = "Perfect movie spot. I'm claiming the beanbag.",
		Jamie = "Jamie's room. Messier than I expected.",
		Lily = "Jamie's little sister's room. Better not touch anything.",
		Master = "This is Jamie's parents' room. I shouldn't really be in here.",
		Garage = "It's so cold out here.",
		Basement = "Nope. Basements in storms are how movies start.",
	},
}

Story.Thoughts = {
	Intro = {
		Host = {
			"Mom left me a couple of things to do. It's in my journal.|journal",
			"Parents gone for the weekend, friends over. This is going to be a good night.",
		},
		Guest = {
			"Jamie's mom left us a couple of things to do. I should check the journal.|journal",
			"Pizza, a movie, no parents. This is going to be a good night.",
		},
	},
	-- a solo night: the friends never make it
	SoloIntro = {
		"Mom left me a couple of things to do. It's in my journal.|journal",
		"Parents gone for the weekend. Riley and the others should be here any minute.",
	},
	SoloFriendsStuck = "They're not coming. It's just me tonight. Just me and the storm.",
	Objectives = {
		OrderPizza = "I'm starving. Mom keeps the pizza menu on the fridge.",
		Popcorn = "We can't watch a movie without popcorn. There's some in the kitchen cupboard.",
		LockUp = "Dad always says to lock up at night. The back door and the garage door.",
		Windows = "The storm's getting worse. Somebody left the windows open upstairs.",
		Door = "The doorbell. That's the pizza. Somebody get the front door.",
		Investigate = "Someone has to go up there and look. It's probably nothing.",
		Power = "The breaker panel is in the garage. Maybe I can get the power back on.",
		Phone = "The phone's dead. Did something happen to the line outside?",
		Attic = "The attic hatch in the upstairs hall... what's actually up there?",
		Call911 = "We need help. Fix the phone line outside, or find a signal by the upstairs bathroom window.|phone",
		Neighbor = "Mrs. Okafor lives next door. If I can make it to her porch...",
		Car = "If we find the car keys, we can drive out of here.",
		Rescue = "He took someone down to the basement. We can't leave them there.",
	},
	Acts = {
		SmallThings = {
			"That guy was so weird. And if the creek road's closed, nobody's getting in or out tonight.",
			"It's just the storm. Old houses make noise.",
		},
		SomeoneElse = {
			"The power's out. All of it. That wasn't the storm.",
			"I should find a flashlight before I go anywhere dark.",
		},
		Guest = {
			"Someone has been living in the attic. And he's still in the house.",
			"We need to get help. And when we hear him coming, we hide.",
		},
	},
	Events = {
		FootstepsUpstairs = "Footsteps... upstairs? But we're all down here.",
		DoorAjar = "Was that door open before?",
		CordSwing = "Why is the attic cord swinging on its own?",
		FigureWindow = "There was someone out there. Right outside the window.",
		TVAlert = "The TV just changed by itself.",
		SilentCall = "Who calls and doesn't say anything?",
		Glimpse = "There's someone at the end of the hall.",
		WindSlam = "WHAT was that?! ...A door, upstairs. It's those open windows.",
		PlateCrash = "Something just smashed in the kitchen. Nobody's in there. Nobody should be in there.",
		CeilingThud = "Something heavy just hit the floor right above me. That's the attic.",
		WindowBang = "Someone just slammed on the window! Get away from the window!",
		DoorRattle = "Someone's trying the door. Someone's outside trying to get in.",
		ChairDrop = "Did a chair just fall over? In an empty room?",
		MusicBox = "That's Lily's music box. Lily isn't even home.",
		ShowerRan = "The shower just turned on. Upstairs. Who is in the shower?",
		LightUpstairs = "The light just came on in Lily's room. We're all down here.",
		BackDoorOpen = "The back door is wide open. Rain's blowing in... and those are footprints.",
		WallKnock = "Something is knocking. Inside the wall. Right next to me.",
		InvestigateDone = "Just the attic hatch. The cord is swinging... it's nothing. It has to be nothing.",
	},
	Items = {
		Flashlight = "A flashlight. This could save my life tonight.|light",
		PepperSpray = "Mom's pepper spray. Only if he gets close.|spray",
		Walkie = "A walkie-talkie. Whoever has the other one can hear me anywhere.",
		CarKeys = "The car keys! Now I just need to get the garage open.",
		ElectricalTape = "Electrical tape. That could fix a cut wire.",
		BasementKey = "A key marked BSMT. The basement door.",
		Poker = "A fire poker. Heavy enough to break a window.",
		Scissors = "Scissors. Sharp enough to cut through a zip tie.",
		Batteries = "Fresh batteries. The flashlight is full again.",
		Remote = "Found it. In the couch cushions, obviously.",
		PopcornBag = "Microwave popcorn. Extra butter. Now the microwave.",
		PopcornBowl = "Smells amazing. The coffee table in the living room.",
		Firewood = "Heavy. Okay, to the fireplace.",
		Matches = "Matches. Good to have if the lights go out.",
	},
	Hide = "I have to stay quiet in here.|breath",
	Captured = "My hands are tied to a pipe. I have to get loose, or wait for the others.|struggle",
}

---------------------------------------------------------------------------
-- Endings
---------------------------------------------------------------------------
Story.Endings = {
	CaseClosed = {
		Title = "CASE CLOSED",
		Body = "The police find four soaked, shaking teenagers who have already solved it.\n\nThe coffee in the sink. The invoice from VANE HOME SERVICES. The lanyard with the eyes scratched out. The photos from the top of the stairs. Nineteen days of it, laid out on the kitchen table.\n\nCurtis Vane is picked up at the van before he can start the engine. Detective Ruiz reads your notes twice.\n\n'You kids did half my job,' she says. 'Go home. Well. Stay home.'",
	},
	Sirens = {
		Title = "SIRENS",
		Body = "Blue and red light floods the rain. Two cruisers, then a third.\n\nCurtis Vane is arrested forty minutes later, sitting in a gray van two streets away, soaked through, with nowhere left to go.\n\nOn Monday, Jamie's dad resets the garage code. It had been 4-1-9-7 since April.",
	},
	LockedIn = {
		Title = "LOCKED IN",
		Body = "When the officers open the basement door, Curtis Vane is sitting on the bottom step with his hands already raised.\n\n'It's my house too,' he tells them. 'I take care of it.'\n\nNineteen days. Nobody ever changed the code.",
	},
	Taillights = {
		Title = "TAILLIGHTS",
		Body = "The Honda fishtails down the flooded hill, headlights full of rain, and doesn't stop until the gas station on Route 9.\n\nThe police go up to 14 Alder Lane without you. They find an attic full of photographs of a family who never knew they had a guest.",
	},
	NextDoor = {
		Title = "NEXT DOOR",
		Body = "Mrs. Okafor opens the door in her robe, takes one look at your face and pulls you in out of the rain.\n\n'I KNEW that wasn't your father's friend,' she says, already dialing.\n\nBiscuit doesn't stop barking at the Whitaker house until the police arrive.",
	},
	GoneQuiet = {
		Title = "GONE QUIET",
		Body = "Nobody calls. Nobody comes.\n\nJamie's parents come home on Sunday night to a dark house and a basement door locked from the outside. Everyone inside is alive: cold, terrified, zip-tied to the pipes.\n\nCurtis Vane's van is found abandoned at a rest stop in Indiana. He is still out there. Somewhere with an attic.",
		Bad = true,
	},
	GotAway = {
		Title = "HE GOT AWAY",
		Body = "By the time the police kick in the front door, the house is silent.\n\nThe back door is open. Rain on the kitchen floor. Muddy prints going out, none coming back.\n\nThey search the house room by room. The attic is empty, except for the photographs. Hundreds of them. Every one of you.\n\nCurtis Vane was never found.",
		Bad = true,
	},
	Dawn = {
		Title = "DAWN",
		Body = "The rain stops a little after five. Gray light, a dripping gutter, and then - finally - sirens.\n\nA neighbor on Birch Street had called about a gray van that hadn't moved in three weeks. The officer who ran the plate made the connection to the break-ins.\n\nYou lasted the whole night.",
	},
}

-- shown once, the first night someone plays, when he starts moving around the house
Story.SurvivalTips = {
	Title = "HE'S IN THE HOUSE",
	Body = "• He always knows roughly where you are. When you hear him running, HIDE: closets, wardrobes, under beds, the shower.\n• Don't let him see you get in. Run, break his line of sight, then hide.\n• When he opens the doors around you, hold your BREATH.\n• Once he sees you, you can't outrun him for long.\n• When it goes quiet, he's resting. That's when you move: fix the phone line, find a signal, reach the neighbor, or take the car.",
	Button = "GOT IT",
}

-- The hunt (server/Intruder): what your character thinks when he starts coming
Story.Hunt = {
	First = {
		"Footsteps. Running. He knows where we are.",
	},
	FirstNotice = "He's hunting you. Hide before he sees you.",
	Wave = {
		"A door slammed. He's moving again.",
		"He's coming. Find somewhere to hide. Now.",
		"Those footsteps again. Getting closer.",
	},
	Seen = "He saw me. RUN. Get out of his sight and hide.",
}

-- Evidence: the clue documents that tell you who he is. Read enough of them (between you)
-- before the police arrive and "Sirens" becomes the secret ending "Case Closed".
Story.Evidence = { "WarmMug", "Invoice", "LilyDrawing", "Notebook", "Polaroids", "Footprints", "TrashCan", "WetShower", "EmptyHook", "Lanyard" }
Story.EvidenceNeeded = 7

-- The lobby's endings collection: display order and a hint for the ones not found yet
Story.EndingOrder = { "Sirens", "CaseClosed", "NextDoor", "Taillights", "LockedIn", "Dawn", "GoneQuiet", "GotAway" }
Story.EndingHints = {
	Sirens = "Get a call through to 911 and hold out until they come.",
	CaseClosed = "When the police come, have the whole story ready. Read everything.",
	NextDoor = "Someone next door is still awake.",
	Taillights = "Mom's car is in the garage. The keys are not where they should be.",
	LockedIn = "The basement door locks from the outside.",
	Dawn = "Just... last until morning.",
	GoneQuiet = "What happens if he takes everyone?",
	GotAway = "Help is on the way. Don't let him take everyone before it arrives.",
}

Story.Fates = {
	Escaped = "Escaped",
	Safe = "Safe",
	Rescued = "Found by police",
	Captured = "Captured",
	Dead = "Didn't make it",
}

return Story
