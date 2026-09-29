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
	Movie = "Pick a movie (living room TV)",
	Fire = "Light the fireplace",
	Windows = "Close the upstairs windows before the storm",

	Explore = "Figure out what that noise was",
	Stay = "Stay together",

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
		{ Key = "Serve", Text = "Put the bowl on the living room coffee table", Target = "CoffeeTable" },
	} },
	Movie = { Title = "Pick a movie", Steps = {
		{ Key = "Remote", Text = "Find the TV remote (try the couch cushions)", Target = "Couch" },
		{ Key = "Watch", Text = "Put a movie on the living room TV", Target = "TV" },
	} },
	Fire = { Title = "Light the fireplace", Steps = {
		{ Key = "Wood", Text = "Grab firewood from the pile in the garage", Target = "Woodpile" },
		{ Key = "Logs", Text = "Stack the logs in the fireplace", Target = "Fireplace" },
		{ Key = "Matches", Text = "Find matches in the kitchen drawer by the stove", Target = "Matches" },
		{ Key = "Light", Text = "Light the fire", Target = "Fireplace" },
	} },
	Windows = { Title = "Close the upstairs windows", Steps = {
		{ Key = "GuestFront", Text = "Close the window in the guest room", Target = "GuestWindow" },
		{ Key = "LilyBack", Text = "Close the window in Lily's room", Target = "LilyWindow" },
	} },
	-- Act II
	LockUp = { Title = "Lock up for the night", Steps = {
		{ Key = "BackDoor", Text = "Lock the back door in the kitchen", Target = "Door_BackDoor" },
		{ Key = "GarageSide", Text = "Lock the garage side door", Target = "Door_GarageSide" },
	} },
	Stay = { Title = "Stay together" },
	-- Act III
	Power = { Title = "Get the power back on", Steps = {
		{ Key = "Flashlight", Text = "Find a flashlight (mudroom shelf or den drawer)", Target = { "FlashlightMud", "FlashlightDen" } },
		{ Key = "Panel", Text = "Check the breaker panel in the garage", Target = "Breaker" },
		{ Key = "Flip", Text = "Flip the MAIN breaker back on", Target = "Breaker" },
	} },
	Phone = { Title = "Call for help", Steps = {
		{ Key = "Landline", Text = "Try the kitchen phone", Target = "Phone" },
		{ Key = "Box", Text = "Check the phone box outside the garage", Target = "JunctionBox" },
		{ Key = "Tape", Text = "Find electrical tape (kitchen drawer or garage bench)", Target = { "TapeKitchen", "TapeGarage" } },
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
Story.Texts = {
	Evening = {
		{ At = 40, From = "Mom", Body = "Landed! Hotel is nice. Eat something real please. Love you", Role = "Host" },
		{ At = 150, From = "Group chat", Body = "Riley: who's bringing the movie\nMorgan: we're literally at the house" },
		{ At = 300, From = "Dad", Body = "Don't touch the thermostat. And lock the back door, it sticks.", Role = "Host" },
		{ At = 420, From = "Hollis Creek Alerts", Body = "FLASH FLOOD WARNING in effect until 6 AM. Creek Rd closed. Avoid travel." },
	},
	SmallThings = {
		{ At = 120, From = "Mrs. Okafor (next door)", Body = "Hi Jamie honey! Is your dad's friend still staying with you? I saw a man at the side door Tuesday. Stay dry!", Role = "Host" },
		{ At = 260, From = "Mom", Body = "Everything ok? Did you lock up?", Role = "Host" },
		{ At = 400, From = "Riley's mom", Body = "Roads are bad honey, stay over at Jamie's tonight ok?", Role = "Tinkerer" },
		{ At = 480, From = "Group chat", Body = "Casey: ok who keeps walking around upstairs\nMorgan: not me lol" },
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
	PizzaCancel = {
		"Hi, this is Tony's calling for 14 Alder?",
		"Real sorry, hon. Creek Road's flooded out, police closed it. My driver can't get up the hill.",
		"No charge. Stay dry, okay?",
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
	{ Name = "Ch 4 - Movie", Line = "The movie starts. Somebody groans at the cheesy opening credits.", Sound = "TVShow", Objective = true },
	{ Name = "Ch 7 - News", Line = "'...police in Hollis County say a string of odd break-ins - food taken, nothing valuable - may be linked. Residents are asked to report any vehicle that seems out of place...'", Sound = "TVShow" },
	{ Name = "Ch 11 - Weather", Line = "'...four inches of rain overnight. Creek Road is now closed. If you don't have to go out tonight, don't.'", Sound = "TVShow" },
	{ Name = "Ch 12 - Static", Line = "Snow. The cable box can't find a signal.", Sound = "TVStatic" },
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
	WetShower = "The shower was wet because Curtis showered at 7:50 PM, the way he did every Friday while the family was at swim practice.",
	SilentCall = "The silent call was Curtis, on his prepaid phone in the attic, counting your voices through the line.",
	FigureWindow = "The figure at the window was Curtis. He went out the garage side door to move his van before anyone noticed it, and stopped when he saw you.",
	DogBark = "Biscuit was barking at Curtis walking along the side yard.",
	TVAlert = "The TV changed on its own because an Emergency Alert System broadcast (a real flash-flood warning) overrode the channel.",
	Flicker = "The lights flickered because of the storm. Not everything was him.",
	PowerOut = "The power went out because Curtis flipped the main breaker in the garage so he could move through the house in the dark.",
	LineCut = "The phone was dead because Curtis cut the line at the junction box on the garage wall.",
	KeysTaken = "The car keys disappeared because Curtis took them off the hook so nobody could drive for help.",
	Glimpse = "The shape at the end of the hall was Curtis. He was deciding what to do about you.",
	PizzaCancel = "The pizza never came because Creek Road really did flood. That part was just bad luck.",
	Floorboard = "The floorboard creak overhead was Curtis shifting his weight in the attic, directly above you.",
	LilyNightlight = "Lily's nightlight was on because Lily always leaves it on. The ceiling man never bothered to turn it off.",
}

---------------------------------------------------------------------------
-- Inner monologue. Lines are "text|hint": the hint key becomes a control tip for the
-- player's device (keyboard, touch or gamepad) on a smaller second line.
---------------------------------------------------------------------------
Story.Thoughts = {
	Intro = {
		Host = {
			"Mom left me a list of chores before she went. I should look at it.|journal",
			"Parents gone for the weekend, friends over. This is going to be a good night.",
		},
		Guest = {
			"Jamie's mom left a whole list of stuff for us to do. I should check it.|journal",
			"Pizza, a movie, no parents. This is going to be a good night.",
		},
	},
	Objectives = {
		OrderPizza = "I'm starving. Mom keeps the pizza menu on the fridge.",
		Popcorn = "We can't watch a movie without popcorn. There's some in the kitchen cupboard.",
		Movie = "I should probably put something on the TV. Where's the remote?",
		Fire = "It's freezing in here. There's firewood in the garage for the fireplace.",
		LockUp = "Dad always says to lock up at night. The back door and the garage door.",
		Windows = "The storm's getting worse. Somebody left the windows open upstairs.",
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
			"The pizza's not coming. The creek flooded. We're stuck here tonight.",
			"It's just the storm. Old houses make noise.",
		},
		SomeoneElse = {
			"The power's out. All of it. That wasn't the storm.",
			"I should find a flashlight before I go anywhere dark.",
		},
		Guest = {
			"Someone has been living in the attic. And he's still in the house.",
			"We need to get help. Stay together. Stay in the light.",
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
		Matches = "Matches. Now I can light the fire.",
	},
	Hide = "I have to stay quiet in here.|breath",
	Captured = "My hands are tied to a pipe. I have to get loose, or wait for the others.|struggle",
}

---------------------------------------------------------------------------
-- Endings
---------------------------------------------------------------------------
Story.Endings = {
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
	Dawn = {
		Title = "DAWN",
		Body = "The rain stops a little after five. Gray light, a dripping gutter, and then - finally - sirens.\n\nA neighbor on Birch Street had called about a gray van that hadn't moved in three weeks. The officer who ran the plate made the connection to the break-ins.\n\nYou lasted the whole night.",
	},
}

Story.Fates = {
	Escaped = "Escaped",
	Safe = "Safe",
	Rescued = "Found by police",
	Captured = "Captured",
}

return Story
