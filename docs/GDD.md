# HOME ALONE — Game Design Document

*A realistic psychological horror game for Roblox · 2–4 players · 30–60 minutes*

---

## 1. Pitch

It's a cold, rainy Friday night in November. Jamie Whitaker's parents are out of state at a wedding, and three friends have come over to eat bad food, watch a movie and stay up too late.

Somebody else is already in the house. He has been living there for nineteen days.

**Home Alone** is a slow-burn thriller with nothing supernatural in it. Every creak, open door and missing plate of leftovers has a real cause. The game shows every one of those causes at the end.

### Design pillars

1. **Everything is real.** No ghosts and no monsters. Every event is caused by the intruder, the storm, the house or the players. The ending screen, "What Really Happened", shows the real explanation for every strange event that happened in *your* session.
2. **Presence over pursuit.** The intruder mostly stays unseen. Tension comes from not knowing where he is. He chases rarely, for a short time, and only when the odds are on his side.
3. **Together is safe.** He is one desperate man, not a slasher. He avoids groups and lit rooms. He hunts people who are alone. So the multiplayer game is about how the group splits up, talks and trusts each other.
4. **Your choices change the night.** Whoever grabs the house keys, whoever walks out into the rain to splice the phone line, whether you stay in the light: each of these changes what the intruder does and which ending you get.
5. **Cinematic pacing.** Four acts with a director that adapts to the players. Quiet stretches are part of the design.

---

## 2. Story

### Setting
**14 Alder Lane, Hollis Creek.** A two-storey suburban colonial with a basement, an attic and an attached garage. The houses are far apart. Old Mrs. Okafor lives next door with her dog, Biscuit. The creek at the bottom of the hill floods every November. There's a flash-flood warning tonight, and the cell tower on Route 9 has been down since the afternoon.

### The friends (player roles)
Roles are dealt when the night starts. Each role has a personality blurb, a perk and **its own starting item** (v92: the owner found picking a role "so useless": it was a name and nothing else). The vote screen shows all four with what they start with (`Story.Roles` Gear); pass owners tap one, anyone else gets the pass offered. A few seconds into the night, a notice says who you are and what you start with.

| Role | Character | Starts with | Perk |
|---|---|---|---|
| Host | **Jamie Whitaker**, 17. It's their house. Responsible, but out of their depth. | 🔦 Dad's **flashlight** + the **house keys** | Keys open dad's office and the basement deadlock. Sees room names. |
| Tinkerer | **Riley Chen**, 17. Fixes things. Has always got a multitool. | 🔧 **Multitool** + electrical tape | Repairs and frees captured friends twice as fast. |
| Runner | **Morgan Hale**, 16. Cross-country varsity. | 🥤 **2 energy drinks** (X / R1 / DRINK): 10 s of sprinting that never tires you, at 19 (`Config.EnergyDrink`) | More stamina, and sprinting is quieter. |
| Observer | **Casey Brooks**, 17. Notices everything. Nobody listens. | 🧨 **2 firecrackers** (V / Y / THROW): thrown where you look (34 studs), a 1.4 s fuse, then a string of bangs (a 75-stud noise) | Hears sounds from farther away. Gets extra detail when examining clues. |

**Firecrackers** pull him to the bang from anything but a chase, a stun or a retreat, even from a hiding spot he's listening at (the heartbeat minigame stops: "The bang pulled him away"): a friend's way to save you.

### The intruder — Curtis Vane
In game (`server/Intruder/Rig`, built from parts, no catalog dependency; v99, after the owner pointed at Roblox's Locust / THRESHOLD monsters) he is nearly ten feet of black, oil-dull jointed limbs as thin as broom handles, joined at swollen ball joints like a mannequin left out in the rain: a ribcage you can count, a visible spine, shoulder blades, rags of the shirt he came in with. His arms hang past his knees and end in long black fingers (two joints each) with pale split nails; long narrow three-toed feet. His face is a long porcelain mask: two big round sockets sunk deep with a grey bruise round each and a tiny pale pupil far inside, not quite level, and a grin stretched cheek to cheek, curling up at the corners, two rows of small teeth; cracks, streaks run down from the eyes; wet black hair in clumps from the crown, down past his shoulders and down the edges of the mask. The clients animate him procedurally (`shared/CreaturePose`, `client/Controllers/Creature`) and play it back in stop-motion (each pose held for a few frames, 12-18 a second, unevenly), so his limbs jerk from one position to the next like a puppet's while he glides: he walks hunched with his head hanging forward and lolling, arms swinging loose; he runs on all fours, the long arms thrown out and slapped down like front legs, head craned up at you; standing still his head lies over on one side, snaps, and now and then turns right round to look behind him (and back); searching, one hand feels the air; stunned, he claws at his mask; a Peek pose leans out from behind a door frame with the head laid flat. He stoops under door frames (9.5 studs). **v100**: the limb bones taper (three stacked segments, thick at the top), with bare tendons strung down the forearms and the backs of the calves; each finger hangs on its own joint (`LeftFinger1`..), so the fingers claw as his hands slap down running, spread and close reaching for you, drum one after another while he stares, and clench at his mask stunned; and **the mouth opens** (`CreaturePose.jaw`/`setJaw`: the black of the grin stretches down the face from a still top edge and the lower teeth drop with it, through the meshes' scale and offset, client-side): gaping and panting as he runs, slowly opening while he stares at you, then snapping shut, now and then a silent yawn as he walks, wide open screaming in the jumpscare (`Creature.scream`) and when stunned. The two hair strips across the mask moved out to its edges (they read as bars), and the pale pupils sit proud of the sockets so both catch the light. **v102 (the owner: "I can't even see the monster… because of how dark it is")**: his body is charcoal (38,36,36), not black; the face glow is brighter and wider (1.3, 7 studs) and a faint cold light off his chest (0.8, 11 studs) lights the walls and floor around him; in the house the clients give him a faint pale outline and fill wherever he's actually in view (a Highlight, occluded: never through walls; not in the lobby fog). After the blackout the dark house is moonlit: a cold blue ambient (70,76,100) and a slightly lifted grade instead of near-black, so you can find your way and see him coming; your flashlight still matters for detail. The server judges sight and sound from an invisible "Eyes" point at the old head height (7.8 studs), so door headers and tunnel roofs never block it; the jumpscare looks at the real head. Near him your flashlight stutters, lights flicker, and his running footfalls shake the screen.
Curtis Vane, 41, is a laid-off insulation contractor. In April his company re-insulated the Whitakers' attic. The invoice has a temporary garage keypad code on it. **Nobody ever reset it.**

After he lost his job and then his apartment, Curtis came back. For nineteen days he has lived in the crawl space above the garage and the main attic. This is called *phrogging*. He comes down when the house is empty. He eats a little from the fridge, showers while the family is at Lily's swim practice, and keeps a notebook of their schedule. Lily, who is seven, saw him once at night. Her parents told her it was a dream.

The Whitakers were meant to take the kids to the wedding. Curtis expected three days alone in an empty house. Then a car pulled into the driveway.

He isn't a murderer. He is frightened, possessive and desperate, and that makes him dangerous. At first he just wants to wait them out. Once they find his nest, he wants to keep them from telling anyone. He takes people down to the basement boiler room and zip-ties them to the pipes while he decides what to do.

### Why every "strange" thing happens

| What players experience | What really happened |
|---|---|
| The back door is unlocked | Curtis came back in through the back door at 8:30 PM and forgot to lock it when he heard the car. |
| A mug of coffee in the sink is still warm | He made coffee at 8:15. He ran for the attic when headlights hit the kitchen window. |
| The attic hatch won't open | He latched it from above with a bungee cord. |
| The hatch's pull cord is swinging on its own | He had just climbed up and pulled the hatch shut. |
| Footsteps upstairs while everyone is downstairs | He crossed the upstairs hall from Lily's room back to the hatch. |
| A door that was closed is open | He moved between rooms while nobody was looking. |
| The leftover lasagna is gone | He was hungry. He'd been waiting for the house to empty. |
| The upstairs shower is wet | He showered at 7:50 PM, just before you arrived. |
| The landline rings and nobody speaks | Curtis called from his prepaid phone in the attic to hear how many voices were downstairs. |
| A figure outside the window during a lightning flash | He went out through the garage side door to move his van off the street. He stopped when he saw you. |
| Biscuit is barking next door | Curtis walked along the side yard. |
| The TV switches channels on its own | An Emergency Alert System broadcast overrode the channel, a real flash-flood warning. |
| The lights flicker | The storm. Not everything was him. |
| The power goes out completely | Curtis flipped the main breaker in the garage so he could move in the dark. |
| The landline is dead | He cut the line at the junction box outside the garage. |
| The car keys are gone from the hook | He took them so nobody could drive for help. |
| Muddy footprints in the garage | His boots, size 12. Nobody in the house wears size 12. |

The Director logs each event that actually fires, with the in-game clock time. The ending screen then plays these back as **"What Really Happened"**.

---

## 3. Structure & Pacing

Real minutes are shown on an in-game clock that starts at **8:47 PM** and runs 1.5× faster than real time. Act lengths flex with what the players are doing (min/max in `Config.Acts`).

### A different house every night
Eleven drawers and shelves are **stashes** (end tables, kitchen drawers, the hall console, the mudroom shelf, the garage workbench, the bedroom nightstands). Each night two flashlights (one always downstairs), two rolls of electrical tape and a pack of batteries go into different ones; the objective markers point at wherever they ended up. Searching an empty one says "Nothing useful in here."

### More small things (Act II/III)
- **The music box:** Lily's music box starts playing upstairs while nobody is in her room.
- **The shower:** the upstairs shower turns itself on and runs for twenty seconds.
- **The light upstairs:** with everyone downstairs, the light in Lily's room clicks on.
- **The back door:** the unlocked back door is found swinging open, rain blowing in, a line of wet boot prints across the kitchen tile.
- **Knocking in the wall:** three slow knocks inside the wall right next to someone who is alone.
Each has its own line in the truth log, a thought, and a spoken reaction if friends are together.

### Furniture from the Creator Store (`World/Props`, v85)
The house is built from parts first (Kit), so it always works; then the big pieces are swapped for checked Creator Store models in the background: the living room's patterned three-seater, the den's worn leather sofa (taped up), wingback armchairs, painted-book bookcases (tall old ones in Dad's office), Doors-style wooden dining chairs, Dad's old leather office chair, and big house plants (a palm, a monstera on a stand, a dracaena). Each model's facing was checked (`tools/assets/preview.mjs`), turned to face the way our furniture faces (`Yaw`), scaled into the old piece's box (`Fit`), set against the wall (`Back`) and stood on the floor; the old piece's parts go invisible but stay, so collisions, seats and prompts don't change. Throws and cushions now belong to their sofa, so they go with it. A model that fails to load leaves ours in place. Things you hide in or use, and things with objects on top, stay hand-built. v90 adds the basement's washer, dryer and water heater, floor lamps, the kitchen bar stools and Jamie's guitar, and swapped furniture now casts shadows. The whole layout is checked in renders of the real house first (`tools/assets/stage.mjs`). See `tools/assets/README.md`.

### The lived-in layer (`World/Dress`, v100)
Rooms that read empty got the things a family leaves about at night, built after Interior into its room folders (about 40 placements, ~850 parts, no new lights): on the kitchen counters a paper-towel roll, a knife block, a toaster, a coffee maker, a utensil crock and a cutting board; in the master bedroom a bench under the front window with a folded throw, a laundry basket heaped with clothes by the dresser, a side table with books and a mug by the reading chair, a console under the painting (flowers, photos, a jewellery box), slippers by the bed and a palm; in Jamie's room a dresser with an old TV and the console, three posters (a basketball tournament, a galaxy print, "Flight to Mars"; free Creator Store decals put on by `World/Props`), a basketball, dumbbells, sneakers and a skateboard; in Lily's room a play tent, a rocking horse, a tea party (a little table, three chairs, two of her bears sat at it with a pink toy tea set), building blocks and a low toy shelf; in the den a wingback by the side window with a side table and a console behind the sofa; at the back of the upstairs hall a low bookcase and a laundry basket, a palm at the front; in the garage storage totes, a shelf of paint over the bins, a camping cooler and a fuel can; in the bathrooms folded towels, toothbrush cups, a soap pump and lidded hampers. Creator Store pieces (toaster, knife block, paper towels, coffee maker, laundry basket, tent, rocking horse, tea set, two teddies, cooler) are stand-ins swapped by `Props.Models` like the furniture. Everything keeps clear of doorways, door swings, open windows, hiding spots (their exits and the view from inside), prompts, his nav nodes and the candy spots: `tools/harness/dress_test.luau`.

### Music and sound
A quiet music box in the rain in the lobby ("Eerie Music Box", APM, volume 0.06); soft piano indoors in Act I; no chase or tension music (it used to slam in whenever he chased anyone nearby, even a friend in another room: the hunt is his footsteps, his breathing and your heartbeat); and from Act II the house creaks somewhere near you every 20-50 s.

**The dark house** (client `Dread`, v104; a player: '"horror game" but almost no audio for it'). Still no music. Once the power's gone, an eerie room tone sits under everything indoors (ProSoundEffects "Eerie Ambience 1"), a little louder while he hunts. As he gets close (within 55 studs, half as much through a floor) a low rumble swells ("Hollow Rumble 1"), your heartbeat starts and quickens with it (also when your nerve is fine), and your flashlight stutters now and then. While he hunts and isn't on you, every 14-30 s there's a noise off 18-34 studs away, maybe a floor up or down: creaks, a floorboard, the stairs, a thud upstairs, wood splintering, his joints, a door handle, a whisper, and rarely a shriek far off.
**Loudness** (v104, `tools/audio_audit.py`): every sound in the library was downloaded and measured. They all play, but many were mastered very quiet (his footsteps peaked at -18 dB, the tunnel ones at -43, the house creaks at -21 played at a third of the volume). Each sound now has a `Gain`, a correction for its file, applied on top of whatever volume it's played at (`Sounds.volume`, up to Roblox's 10): his footsteps, breathing (heard from 26 studs now) and listening breath, the creaks, closets, drawers and beds he rips open, the light switches, the rumble of the storm.

**Acoustics** (client `Acoustics`, v84). The reverb follows the room you're in (tiled bathrooms ring, the basement, boiler room and garage are stone, halls are halls, the living room and den are soft, the tunnels under the house echo). A sound in the world with something solid between you and it (a wall, a floor, a closed door; not glass) loses its highs and some body, eased in and out, so his footsteps behind a wall sound behind a wall and turn sharp the moment there's nothing between you; shut in a hiding spot, everything outside is muffled. Only sounds placed in the world are touched (not your own footsteps, the UI, the heartbeat or the music). The grandfather clock now ticks (Creator Store "Clock Tick (1 Second Long, Loopable)") and texts buzz like a phone on a table.

### Hanging out
The living-room sofa, both armchairs and the den sofa have seats: a **Sit** prompt puts you on the nearest free cushion (walking into them does nothing), jump to get up. Hiding or getting caught pulls you off the seat first.

### Night recap
The ending card adds a line under each player: how many times they hid, were spotted, got caught and freed a friend (or "never saw him coming").

### The secret ending: Case Closed
Ten clue documents are **evidence** (`Story.Evidence`): the warm mug, the invoice, Lily's drawing, the notebook, the polaroids, the footprints, the trash can, the wet shower, the empty key hook and the lanyard. Reading a new one shows "Evidence n / 10" to everyone. If the group has read at least 7 (`Story.EvidenceNeeded`) when the police arrive, SIRENS becomes **CASE CLOSED**: the kids have already worked out who he is.

### He's hiding, not haunting
Before the hunt, Curtis is trying not to be found. Anything he does in person (a door easing open, food gone from the fridge, the music box) can only happen where he actually is, and only when nobody can see him (`Where` on an event in `Director/Events.luau`). He doesn't knock on walls or throw chairs for effect. The one loud thing he does by accident: if you spot him, he bolts, and sometimes knocks a chair flying on the way. Walk right up to him in the dark and he shoves you to the floor and runs. Open a door he's standing behind and it gets yanked shut in your face (a few minutes apart at most). Door leaves never trap him: he pushes half-open doors wide and walks through them.
Once the hunt begins he is physically in the house, so the house's tricks stop: only events marked `DuringHunt` (storm, the neighbour's dog, floorboards, and the second breaker flip when he's really at the panel) still play.

### Surprises during the hunt (v104)
A player: "no surprise factor to scare you". A minute into the hunt, then every 75-120 s, instead of just patrolling he does one of these (`trySurprise`, alternating):
- **In a closet.** He slips unseen into an empty hiding spot 14-32 studs from someone out in the open and waits there (out of sight, silent). Come within 15 studs and it creaks (the warning); within 7.5 and he bursts out at you (a slam, his screech, the sting, the screen jolts), screams for 0.7 s, then chases. Nobody comes in 40 s: he slips out. Climb into it and he has you (Normal: thrown out with a beat to run; Hard: caught).
- **Behind you.** Someone alone (nobody within 25 studs), out in the open: he's suddenly standing 5.5-8 studs behind them in the same room, breathing. Turn round and he screams and comes for you (0.7 s to run); don't, and after 7 s there's a whisper and he's gone.
Both count in the night log (`Surprised` per player). (v105: the first comes 35 s into the hunt, then every 55-90 s: v104 logged 0.07 per player, the hunt is only ~3 minutes.)

### After the 911 call (v105)
v104 logs: 23 of 45 captures were in the upstairs bathroom, 5-35 s after the call, and almost none through the heartbeat minigame: friends standing at the window in the open, one shower to hide in. Now everyone within 14 studs of the caller gets the caller's head start (`Help.CallerGrace`) and the "HIDE. NOW." thought names the places ("The shower, the cupboard, anywhere."), and the bathroom has a second hiding spot, a tall linen cupboard on the north wall.

### Over the furniture (v104)
A player: "most loopable enemy in horror games". He's slower than your sprint by design, so circling the dining table, a bed or the kitchen island kept him going round forever. Chasing someone in sight with something low between them (anything under his chest, never a wall, never onto another floor) when going round is 1.3x the distance or more, he pounces over it in stop-motion and lands on the far side with a thud (`leapOver` / `leap`; every 3 s at most; `Leaps` in the night log). And running dry winds you: no sprint until your breath is back to 35% (`Movement.WindedRecover`; the stamina bar goes red). Before, a sprint at 0 flickered back on at 1, so you could stutter-sprint forever at about his speed.

### Sudden scares, rarely
A loud musical sting (APM "Fear Hit") lands with the big scares: a door slam, the plate smashing, the window bang, a thunderclap right on top of the house. It plays at most once every 2½ minutes, so it stays a shock.

### One message at a time
Thoughts, notifications and sound captions share the screen (`ctx.Pace` in `Thoughts.luau`). Each message waits its turn, sound captions are dropped while something else is being said, and the Director only fires a new event when nothing is being said (`Director.isQuiet`).

### Safety nets
- **I'm stuck** (in the journal): moves you to the nearest open spot on your floor, 15 s cooldown. Reset stays off because it would break captures.
- A player who leaves mid-night frees their hiding spot and restraint slot, and their phone call.
- Hidden players are invisible to everyone, so nothing pokes through the bed or the wardrobe door.
- Characters are placed feet-on-floor whatever their height when they're captured, leave a hiding spot, escape, climb through a window or use "I'm stuck".
- If Curtis wedges on furniture while nobody can see him, he slips along to his next waypoint.
- The police timer belongs to its night, and calling for help completes only the route that was used.

### He likes the dark
While lurking, patrolling or searching, if he passes through a lit room that nobody is in and nobody can see him, he sometimes switches the light off (at most every 45 s). Rooms you left lit go dark one by one. The truth log explains it once.

### Fairness
- **Last chance:** when everyone is tied up (always true when playing alone), the bad ending waits 45 s (`Config.Capture.LastChance`) so captives can struggle free; anyone getting loose cancels it.
- **Alone:** he chases a step slower (`SoloChaseSlowdown`) and gives up a quarter sooner.
- **First night:** the first time someone plays, a "HE'S IN THE HOUSE" card explains hiding, breath, light and noise, friends and the ways out, right after the power dies.

### Getting caught
When he grabs you, your camera snaps onto his masked face as it lunges at you (from 3.6 studs to 1.3, fast then slow, the picture jerking between angles like his stop-motion), with an inhuman screech (PSE "Creature Screech Pterodactyl Vocals"), the scream hit ("Eyes Scream Horror Hit", APM), a red flash and a hard shake. Then the hand over your mouth and the fade to black. His footsteps are loud and carry (full volume within 10 studs, fading out by 60 walking or 110 running), louder the closer he gets, and heavier on the dirt under the house. He also breathes: a slow, wet, rasping loop on him (v99: PSE "Creature Dying Pterodactyl Breathing 2", slowed; it was a man's breath) that you only hear from a few steps away, which is how you know he is right outside your hiding spot. v99 sounds: when he charges, a shrill screech (PSE "Creature Vocal Spider Screech (attack)", was a roar); running on all fours, his hands slap down a beat after his feet ("Creature Footsteps Clacky Claw"); standing still within 30 studs of someone, his joints crack every 6-14 s (PSE "Squishy Bone Cracks 4" / "Bone Cracks 22"); listening at your hiding spot, wet monster breathing ("Monster Breathing 3"); a deep wordless whisper for the hall figure; fingernails tapping the glass before the window figure; and the house settles now and then ("House Creaks 12/13", client ambience).

**v99 scares** (each once a night, `Director/Events`): **YardFigure** (first act): looking out of a ground-floor window (or a second after you close one of the open windows upstairs, `Director.windowGlance`), lightning, and for a second something impossibly tall stands out in the yard (14 studs past the window's watch spot), head on one side. **HallStare** (acts II-III, before he's in for good): at the far end of the hall you're looking down (a Layout node 16-40 studs ahead, clear sight of his whole height, nobody near it), he stands dead still in the dark with his head laid over; a whisper; 1.7 s later he's gone and something cracks like a knuckle. **FigureWindow** now starts with a tap, tap on the glass so you're looking right at it when the lightning comes; **WindowBang** shows him with both long hands slammed flat on the glass (Reach). Every figure is a posed copy of the real rig (`Effects.figure(cf, duration, gait)`) that twitches in stop-motion while it's there. At the blackout, his wet footprints (`World/Signs`: long, narrow, three toes, too far apart) lie on the upstairs hall floor from under the attic hatch towards the front. In your flashlight, dust hangs in the air (a local particle box, indoors only); the dark house is graded colder and more contrasty. In the lobby he stands across the street under the far streetlamp in the fog (`Watcher`: the same rig, the clients animate it; Stare, sometimes Idle so the head turns round), never closer.

### Badges (`BadgeService`)
`Config.Badges` holds one badge ID per ending, plus FirstNight (finish any night), HardSurvivor (make it through a Hard night) and Rescuer (cut a friend free). Create the badges in Creator Hub (icons in `marketing/badges/`), paste the IDs, and the game awards them. An ID of 0 is skipped.

### Solo nights: a friend who made it (v105, `Director/Companion`)
The v104 logs: nights alone were abandoned 13 times out of 15, many brand-new solo players within the first ten seconds; with two players 21%, with three 6%. So a night that starts with one player gets one friend who made it before Creek Road flooded (the others turned back): an NPC friend, whichever of Riley / Morgan / Casey / Jamie the player isn't, in a blue hoodie, the same height as the players.
- **Before the blackout** they follow you a step behind (walking, running to catch up, slipping round a corner out of your sight if they get stuck or fall 60 studs behind), say hello in the dialogue box, chatter now and then while it's quiet (`Story.Companion.Chatter`), react once to each scare (`React`), and answer a **Talk** prompt (`Talk`, by act). They never do the chores.
- **The blackout**: "The breaker's in the garage, right? Stay here, I'll flip it." They walk off; out of sight round a corner (or at the panel, or 20 s later) there's a scream and they're gone.
- **The hunt**: they're zip-tied in the boiler room; an optional objective, "(Optional) Free your friend" ("It came from under the house"). **Cut loose** (a 3 s hold, and it's loud: he hears it like a rescue) they run up the basement stairs and out: 35 s later Mrs. Okafor calls the police (help method `Companion`). A second way out for someone alone, and a reason to go down there.
- Never on a night that starts with two or more; someone joining later doesn't send them home. The friends' texts ("creek rd is underwater") don't come when the friend is there. 14 s in the invite nudge still comes ("More is scarier. ➕ INVITE A FRIEND").
- Logged per player: `Mate` events (Taken, Freed); pull_stats prints them.

### Invite a friend into your night (v95)
Solo nights are abandoned 82% of the time, nights with two 30%. The in-game invite used to land a friend in the lobby (game servers are reserved), so they started a night of their own. Now the game server knows its own access code (`NightCode`, from the lobby's TeleportData) and, while the night can still take a player (lobby vote, act I, act II until bedtime, room left: `InviteOpen`, MatchService), a small **➕ INVITE A FRIEND** button sits in the HUD's left column (client `Offers`). The invite carries `LaunchData = "night:<code>"`; the lobby reads it on arrival (`LobbyServer` `invited`) and teleports them straight into that house (2 tries, then "That night has ended. Step into a circle to start your own."). The game side treats them as a late arrival ("X made it here. You're not alone tonight.").

### First impression, sharing and records
- **Loading screen** (`src/first/Loading.client.luau`, ReplicatedFirst): replaces Roblox's default. Rain streaks down a black screen, one warm window glows, and every few seconds a figure is standing in it. Title, a one-line hook, a gameplay tip and a progress bar; it fades out once the game has loaded.
- **Lobby menu:** a small, plain column in the top-left corner (dark glass, thin outline, white text): PLAY SOLO and FIND PLAYERS, then three small links: Endings, How to play, Settings. While you're queued, your queue status takes the play buttons' place.
- **Lobby dock** (`client/Controllers/Dock`): a slim column of icons on the right edge with your coin balance on top: 🎁 REWARDS, 🛒 STORE, 🔦 LOCKER, ⭐ SHOP. Each opens one panel; a dot pulses on REWARDS while today's reward is unclaimed. Play solo / Find players put you straight into a queue circle (FIND PLAYERS picks the group circle with the most people waiting, or the smallest when all are empty); walking into a circle still works.
- **Invite, favorite and remind** (`client/Controllers/Social`): on the ending screen; the favorite prompt also appears once, 8 s into the first ending of a session. **🔔 Remind me** is Roblox's experience-notification opt-in, shown only when Roblox can ask (not opted in yet); it's also in the lobby's REWARDS panel in the claim button's place once today's reward is claimed. Opted-in players get "Your daily reward is ready. Don't break your streak!" once a day (`tools/notify.py`, run daily at ~22:53 UTC by a Claude Code routine: players who claimed yesterday or the day before). After a good ending one small line asks for a 👍 on the game page (likes decide how often Roblox recommends it). (The lobby no longer has these buttons: inviting lives in the Locker, where a locked invite colour asks you to bring a friend.)
- **Saved records** (`Services/StatsService`, DataStore `PlayerStats_v1`): nights played, nights survived, and endings found. The lobby shows `NIGHTS · SURVIVED · ENDINGS x / y`; the ending card says NEW ENDING FOUND the first time you see one.
- **Endings collection:** an ENDINGS button in the lobby lists all six endings; found ones by name, the rest as ??? with a hint.
- **Survivors' board:** a lit sign beside the queue circles shows the top 10 players by nights survived (OrderedDataStore `NightsSurvived_v1`). Beside it, FASTEST WINS. The survivors' board is a little taller (still the top 10), with one small line at the bottom: "Secret ending: found by N players" (each player counted once, the owner never; DataStore `Global_v1` key `SecretFound`).
- Store page text: `docs/STORE_PAGE.md`.

### Act 0 — Lobby
Players land in the **lobby** (third-person camera): Alder Lane on a rainy, foggy night — the street, lawns and woods run on past the invisible walls and fade into thick fog, so the town never seems to end — in front of the Whitaker house (porch light on, two windows lit), with the neighbors, street lamps and the gray van at the curb. A welcome notice (until your first finished night) explains the one thing to do; its button is **▶ PLAY**, which puts you in a group circle with whoever's there (FIND PLAYERS). (New players took a median 39 s to queue and a third never did; solo nights were abandoned 7 times out of 8, nights of three or four almost never.) Four **white outline circles** on the front patio queue **1, 2, 3 and 4 players**. Stand in a circle to queue and step off (or tap LEAVE) to cancel. **Every circle counts down 10 s from the moment someone steps in, and drops to 3 s once it's full** (a solo circle is full at once); at 0 it reserves a private game server and teleports whoever's on it (the owner's rule: no waiting for players, no START NOW). The panel says "Starting in 7... step off to cancel". A circle frees up the moment its group has left for the house. **Joining a night in progress** (`MatchService`): a group night that started short (fewer players than its circle) lists itself in a MemoryStore map, with room up to 4, while late arrivals can still join (`Director.lateJoinOpen`: acts I and II until bedtime, at most `Lobby.JoinOpenFor` = 420 s); every group circle that reaches 0, full or not, joins one of those with room for all of them instead of a fresh house ("Joining a night that's under way..."; they arrive with "You made it just in time", and the ones already there are told "<name> made it here. You're not alone tonight."); if the join fails, a fresh house straight away. A short group sent to a fresh house is listed by the lobby the moment it leaves (`Match.listNew`), and its game server keeps it listed while its players arrive and vote, so the next lone circle joins it from the very start (v88-90: 43 of 70 lone nights had another night start within a minute; only 8 got company). PLAY SOLO nights, nights that started full and veterans' skip-to-the-blackout nights are never offered. A lone player who could still get company doesn't get the friends' "we had to turn around" texts until nobody else can come (and never, once someone has). (v78 logs: the 150 s window caught 1 of 68 teleports, while 44 of 57 lone departures had someone else leave the lobby within 8 minutes; 14 of 15 solo nights were abandoned.) (Logs, v77: 92% of solo nights were abandoned, 18 of 52 solo players in the first minute; 127 of 568 new players queued and left before teleporting.)

In the game server the group spawns in the living room. Once everyone has arrived (or after 20 s without stragglers; they can still join the night) the **CHOOSE MODE** screen opens: NORMAL or HARD, live vote counts, a 12 s countdown (ends early when everyone has voted). More votes for HARD makes it a Hard night; a tie stays Normal. The result shows for 2 s, then the night starts and roles are dealt. (No music on this screen, and none on the result card at the end of the night: they used to blare a track and a sting.) The four roles and what each starts with show on the same screen: owners of the "Pick your role" pass tap one; for everyone else the cards are locked (🔒) and tapping one offers the pass.

**Hard** (`Config.Difficulty.Hard`): he is faster, senses you sooner, checks more hiding spots and rests less; flashlight batteries last 70%; help takes 25% longer; the everyone-captured last chance is 30 s. The HUD shows "· HARD" next to the act. After the ending, everyone is teleported back to the lobby.

How it works: one place serves both. Public servers run the lobby (`server/Lobby/LobbyServer`); reserved servers created by `TeleportService:ReserveServer` run the house (`shared/Mode`). Studio can't teleport, so a Studio test runs the house directly with the old in-house READY screen (`Config.ForceMode = "Lobby"` shows the lobby instead). To split them into two places later, set `Config.Lobby.GamePlaceId` / `LobbyPlaceId`. Because lobby and game share one place, **Server Size also caps the lobby**: set it higher than 4 (e.g. 20) so more people can gather; a game server only ever receives one group, and the game caps a night at 4.

### Onboarding: one notice, then your own thoughts
When the night starts each player sees **one notice** (who they are, their perk) with an **OK** button. Nothing else competes with it: the chapter card and everything after wait until it's dismissed, and the journal stays closed until the player opens it.

After that the character **thinks out loud** (`Story.Thoughts`, `client/Controllers/Thoughts`): big text, one line at a time, 5 seconds each. It points the way ("Mom left me a couple of things to do. It's in my journal." / "I'm starving. Mom keeps the pizza menu on the fridge."), reacts to strange events ("Footsteps... upstairs? But we're all down here."), and comments on first pickups, hiding and being captured. A line can carry a control tip that matches the device (keyboard, touch or gamepad). If nobody makes progress for 35 s, someone remembers the next task.

**Nothing talks over anything else.** Phone texts, toasts and the friends' banter wait until no thought line is on screen and no conversation is running, plus a short gap (`Config.Thoughts.QuietGap`); texts arrive at least 8 s apart. Only the instant "task done" tick skips the queue.

**The friends talk out loud.** They also react a few seconds after a scare if two of them are standing together ("WHAT was that?!" / "Kitchen. Something fell in the kitchen."), once per event, and they talk in the final act too. Friends in the house don't text each other — they speak, in the same dialogue box as the delivery man but in green, with no choices and without hiding the touch controls (`Story.Banter`, `Dialogue.say`). Each scene is cast from players standing together (Jamie takes the "Host" lines); with fewer than two people together it waits, and it never plays solo.

**Others can join your night.** A night that started short (a group circle that left with fewer players than it was for) shows a slim line at the top while late arrivals can still come in: "Others can join your night · 1/4" (`MatchService` sets `OpenNight`; v87 logs: alone in such a night, 23 of 52 players left within 45 s, while another group teleported within a minute half of the time).

### Monetization (v89)
- **Taser** (the old pepper-spray pass, 49 R$): 3 shots a night (`Config.Taser`), fired where the camera looks (T, a left click, R2 or the TASER button), with a little aim assist (9°) up to 45 studs. A hit: stunned 4 s, then every one of his speeds at 55% for 14 s (`Intruder` tune() while `SlowUntil`). Everyone sees the blue bolt (Remotes.Zap) and the yellow-and-black taser in your right hand while it has shots.
- **VIP** (99 R$): +50% night coins, a ★ VIP tag (lobby and chat), every flashlight colour (Gold too), Marathon, endless battery. **Supporter** now also +20% coins; **Marathon** regains breath twice as fast; **Long-life battery** never runs out; **Head start** adds a can of pepper spray.
- **Become him** (developer product, 50 R$, bought again every night; `MonsterService`, client `Monster`): co-op only (2+ survivors). A small 😈 BECOME HIM button under the inventory while it's on sale. Bought before the blackout, you become him when the hunt starts; during the hunt, at once. Your character is parked out of sight; your controls steer him through the puppet (a little under a survivor's walk), LUNGE (Shift / button: 17 for 1.4 s, every 9 s), SEARCH (E / button: the hiding spot in front of you; whoever's inside gets the heartbeat minigame). Anyone in the open you touch is caught (6 s cooldown). Every survivor noise shows as a red ping. A taser or spray stuns you. Survivors are told "X has become HIM". Your card says YOU WERE HIM. If it can't happen (someone else already is, you're out), it's saved as a free credit for another night. The secret ending is off on such a night.

### Monetization (v92: the owner had 300 of the 1,000 R$ needed to publish for all ages)
- **Rocket Launcher** (game pass 2039534472, 99 R$): 2 rockets every night (`Config.Rocket`), fired where the camera looks (R, L2 or the ROCKET button; 2.5 s reload). An olive tube with a red warhead in your hand (it takes the taser's place there). The rocket flies at 120 studs/s with a smoke trail (Remotes.Rocket) and goes off where it hits: a Roblox Explosion that never hurts or moves anyone (BlastPressure 0). Within 12 studs of him: knocked flat for 7 s (a taser is 4), then slowed to 55% for 20 s while he limps away (Stunned with Rocket → retreat). Only during the hunt (not a glimpse before it). A miss is a 90-stud noise: he comes to see. Bought mid-night, its rockets come at once.
- **Rocket (tonight)** (developer product 3718739690, 25 R$): one rocket for this night. A small 🚀 ROCKET R$ 25 button under the inventory during the hunt for anyone without a rocket in hand (client `Offers`). Bought where it can't be used, it's saved (RocketCredits) and comes with the next night. When anyone hits him with a rocket, everyone sees "X knocked him flat with a ROCKET LAUNCHER!" and the button pulses.
- **Pick your role** 15 → 25 R$ (roles now start with items); **VIP** now includes it.
- **Sales log**: every pass and product sold is counted per UTC day in `Sales_v1` (`pull_stats.py` prints it), and each player's owned passes go in the night log (`Pass`). Before this there was no way to see what sold except Creator Hub.
- **Admin SHOP tab** (owner only): every pass on/off for yourself (this server, not saved), the paid gear (rocket, taser, spray, energy drinks, firecrackers), become him (or stop), a saved rocket or revive.

### Monetization (v98: 291 R$ in three days, falling; nothing showed how often anything was offered)
- **The funnel**: every purchase window that closes, bought or not, counts as `Ask:<key>` on the day's `Sales_v1` row and goes in the night log (`Ask`, "Revive+" / "Revive-"). `pull_stats.py` prints "bought / asked" per product. Read it before changing a price or an offer.
- **Starter Pack** (developer product, `Config.Shop.Starter`, 19 R$, once per player): 500 coins, a rocket for the next night (RocketCredits) and a revive (ReviveCredits), worth 60 R$ bought apart. Saved as `Owned.StarterPack` in Economy_v1, in the same write as its coins and receipt; `StarterOffer` is on until then. Shown at the top of the SHOP's passes and as a small gold button on every result card. Off (hidden everywhere) while `Id = 0`: the product has to be made on Roblox first.
- **BE HIM NEXT NIGHT**: a small red button on the result card when a group stays for another night. It buys Become him now (the night being over, it's saved as a free credit) and the client uses it as soon as the next night opens it (it asks on every change until the server says MonsterPending); with a saved one it's free.
- **STOP HIM**: while he chases or charges within 70 studs of you, the 🚀 ROCKET button flashes and says STOP HIM.

### NIGHTMARE mode (v103)
A third choice in the vote, for people who know the house (locked until you've finished a night; the server ignores a vote from anyone who hasn't). It's a Hard night (every Hard rule: batteries, police, heartbeat, last chance) with `Config.Difficulty.Nightmare.Intruder` laid over Hard's settings: walk 9, patrol 10, charge 14.5, chase 15, lunge 16, cap 16.5 (you sprint at 17: you still get away running, for as long as your stamina lasts), sharper sight (36 lit / 14 dark / 50 at your beam), he feels you 1.5 s late, 5 s of grace after you leave a hiding spot, opens the right spot 90% of the time, three checks per search, ambushes more, short breaks. **Caught once and you're dead**: no boiler room, no struggling free (the revive offer is right there). The night pays **2x coins** (instead of Hard's 1.5x), surviving it earns the title **Nightmare Survivor** and the **Nightmare** badge. The vote's most votes win; a tie goes to the easier mode. Workspace `Difficulty` = "Hard" plus `Nightmare` = true (the HUD's act line says NIGHTMARE; the night log's Diff says "Nightmare").

### The revive offer (v103)
Dead, the revive is the first thing under the headline on your card: a big green pulsing "⟳ REVIVE · 10 R$" (or USE REVIVE with a saved one), with why it matters right now ("Your friends are still in there. Get back in and help them." in co-op, "Back on your feet, far from him. The night goes on." for the last one standing, with the night's countdown under it). Before, it sat at the bottom under the coin breakdown, off the screen on a phone: 2 of 74 deaths bought one.

### Repeat nights
Every night has the full build-up (a shorter one for repeat groups, `Config.VeteranPace`, is off: the owner found a 7-minute night too fast).

**A different first act** (`Director/NightPlan`, v84). Anyone's first night gets the chores the act was tuned around (pizza, popcorn, the upstairs windows). Every other night keeps the pizza (the delivery man is the act's story) and draws two of four chores: **popcorn**, **the upstairs windows**, **get the fire going** (it went out before anyone arrived: firewood from the pile in the garage, into the fireplace and light it) and **movie night** (the remote is in the couch, then channel 4), never the same two as the server's last night, so at least one chore is new every time and all six pairs come round. A fire nobody lit is lit when Act II starts (it's the living room's light in the blackout). Each night's set is logged (`NightLog_v1.Plan`, e.g. "Fire+Movie"). (Logs, v81: 12 of 60 players who pressed ANOTHER NIGHT left within two minutes of the same chores again.)

**Skip to the blackout.** On the CHOOSE MODE screen such a group also gets a toggle, **⏩ SKIP TO THE BLACKOUT** (with the count, e.g. 1 / 2): if more than half of them want it, the night starts straight at Act III (no first chapter card, intro thoughts or solo texts; the truth log says you skipped ahead) and the power goes 8 s later. The result shows "Skipping to the blackout." (The logs showed a whole group of returning players leaving 40 s into a night they'd already played.)

### Act I — "Friday Night" (4–7 min)
*Social and cozy, with something slightly off.*
- Only three short objectives (`Story.Tasks`) — this is a horror game, not a chore list (repeat nights swap two of them, see Repeat nights):
  - **Order pizza:** find the menu on the fridge → call Tony's on the kitchen phone.
  - **Make popcorn:** take a bag from the kitchen cupboard → microwave it.
  - **Close the upstairs windows:** guest room, Lily's room (a storm is coming).
  - (repeat nights) **Get the fire going:** firewood from the garage → into the fireplace and light it.
  - (repeat nights) **Movie night:** the remote in the couch → channel 4.
- **A warm, cozy house.** The night starts as a good night in: the fire is already burning (it's also the light that stays on when the power dies), lamps glow amber, wall sconces light the hall and the TV wall, fairy lights hang along the mantel and in Jamie's and Lily's rooms, strips glow under the kitchen cabinets, candles flicker on the mantel, coffee table, dining table and dresser, knitted throws hang over the sofas and chairs and lie folded on the beds, mugs of cocoa steam next to plates of cookies, baskets of blankets sit by the fire and the den sofa, and family photos climb the stairs. Indoors (ground floor and upstairs, power on) the picture shifts warm and golden and a soft licensed piano track ("Solo Piano - Gentle Rain", APM) plays through the first act. It fades when the pizza car's headlights come up the street. Outside, the basement and the attic stay cold and blue, and when the breaker goes, the warmth drains out of everything.
- **Outside:** it's November: pumpkins on the porch steps and by the columns, pots of rust and gold mums, fallen leaves over the lawns, woodsmoke drifting off the chimney (the fire is lit), puddles on the drive, and rain splashing on the ground around you.
- **First visits:** the first time someone walks into a room in Act I they think a line about it (Jamie knows the house; the friends see it for the first time).
- Things you *can* do but don't have to: put on the TV (the remote is in the couch, or press the button on the set), set the popcorn on the coffee table.
- **Jump scare:** while the windows are still open, the draft slams an upstairs door (loud bang, lightning, screen shake).
- The top-right **OBJECTIVE** panel shows the current task and step; a bobbing **"!"** marks where each step happens (yellow and large for the current task), with the distance. The journal lists every step.
- Clues planted: the unlocked back door, the warm mug, Mom's note on the fridge ("don't use the garage keypad, it's acting up"), the attic hatch that is "stuck".
- Phone texts from Mom and Dad over Wi-Fi; the friends argue about the movie and the pizza out loud.
- **The delivery.** A few seconds after the three tasks are done (or when the act runs out of time) a little Tony's Pizza car pulls up in the rain. The delivery man walks up and rings the bell, and a new objective appears: **Answer the door**. He is a Roblox avatar: Roblox's Man Face head, short brown hair, a red pizza-place visor (UGC, Russ UGC) and a bright red shirt with a TONY'S patch, dark jeans. He carries the two pizza boxes flat in both hands and hands them over at the end. The strangeness is in how he acts: he stands too still with his head a little lowered, walks with a slow, stiff stride (procedural hips and knees so his arms stay on the boxes), his head bobs as he talks, and it follows whoever answers and slowly tilts (`Director/Delivery`; a part-built stand-in, `Kit.deliveryMan`, is used if the avatar can't load).
- **Dialogue with choices.** Whoever answers talks to him in a dialogue box (`Services/DialogueService`, `client/Controllers/Dialogue`, script in `Story.Dialogue.Pizza`). Three times the player picks one of two lines to say ("You're not the usual guy." / "What's that supposed to mean?" / "No. My dad's upstairs."); everyone else reads along. He says Creek Road is going under and he's the last one getting through — the house is now cut off — and tells you to keep every door locked, "even the ones you don't use." Then he backs down the steps, still smiling, and drives away; the pizza ends up on the dining table. If nobody answers he knocks (15 s), rings again (32 s), and after 50 s leaves the boxes on the porch.
- He is a red herring: the truth log reveals he was Tony's nephew on his last run, and the real stranger was above your heads the whole time.
- Act II starts as soon as he turns to go (v91: the walk back to his car and the drive off were 78 s of nothing, the longest wait of the night, and a run of act I quits sat right there); the house stays quiet until his car has gone.

### Act II — "Small Things" (5–8 min)
*Did you hear that?*
The Director plays low-intensity events. Each one needs conditions to be met, for example "every player is on the ground floor", "one player is alone near a window" or "nobody can see this door".
- Objective: **Lock up for the night** (back door, garage side door). After the footsteps upstairs, a second one appears: **Check upstairs** — walk up to the attic hatch.
- Footsteps upstairs, a door left ajar, the attic cord swinging, the lasagna gone, the wet shower, a silent phone call, Biscuit barking, the emergency alert on TV, the storm flickering the lights.
- **Loud, sudden noises** (each with a real cause in the truth log, each shakes the screen and costs nerve): a plate **smashes** in the empty kitchen (the shards stay on the floor), a heavy **thud in the ceiling** right above an upstairs player (dust rains down), someone **bangs on the window** next to a lone player, a door handle is **yanked** hard, a chair **crashes over** in an empty room.
- **The Window.** A lone player near a ground-floor window sees Curtis outside, lit for a moment by lightning. Nobody else sees it.
- Texts: Mrs. Okafor asks whether "your dad's friend" is still staying with them, because she saw a man at the side door on Tuesday.
- **Mom and the news.** A few seconds after the doors are locked, Mom texts: *turn on channel 7*, a man has been living inside houses in Hollis Creek. You **text back** from your phone (two reply choices; the phone shows the whole conversation as chat bubbles). A new objective appears: **Watch the news** (turn on the TV → channel 7 → watch the report). Sitting through ~8 s of the report in front of the screen completes it; your character reacts, the truth log notes it, and later Mom asks if you saw it (another reply). Act II can't end until the news has been watched (or a hard time limit passes). **One thing at a time** (`Config.Director.BeatSpacing`, `AfterNews`, `AfterScare`): a scripted scare waits until the last one is 35 s back, never fires while Mom is texting, and the TV's emergency alert never cuts in while someone's meant to be watching the news (it comes after). Mom's texts start once the house is locked *and* nothing else is going on (no scare in the last 15 s, nobody still meant to be checking upstairs; partway through the act at the latest). The lights go no sooner than 40 s after the news was watched and 30 s after the last scare. **Then bed**: 8 s after the news, "Get ready for bed: brush your teeth in the upstairs bathroom" (a hold prompt at the sink); brushing, your phone notices one bar of signal by that window ("Nowhere else in the house gets any"), and the lights go 12 s later (act II still runs at least 150 s, so its scares have room). Everyone is upstairs, by the 911 window, when the blackout comes. (Logs, v77: the last act II task to the blackout was a median 149 s of nothing to do, and players quit in it: "News", "Door" and "Investigate" were the last steps before most early quits.) (A version that rushed the remaining scares 12 s apart once the tasks were done made the whole night 7 minutes, with "check upstairs", Mom's texts and the emergency alert all at once and the blackout straight after: the owner found it far too fast.)
- **The TV.** Every channel is a real broadcast on the screen: 7 News (BREAKING NEWS bar, suspect silhouette "MALE · 40s · 6'4\"", scrolling ticker, live clock), 11 Weather (radar, FLASH FLOOD WARNING), Ch 4's 1958 black-and-white film with subtitles, Ch 12 colour bars and NO SIGNAL, and the red Emergency Alert screen. The prompt names the channel you're on.

### Act III — "Someone Else" (6–9 min)
*This isn't the storm.*
- **The power dies**, and it's the main breaker, not the storm. Wi-Fi goes with it, so no more texts.
- **The landline is dead.** The car keys are gone. The attic hatch now opens.
- Curtis is now physically in the house. He **lurks**: he moves only while unobserved, watches from doorways, and walks away when someone spots him. Players get glimpses at the end of a hall or in a doorway. He does not attack yet.
- **Objectives arrive with the blackout** (before it, the act shows none): every way out is open from that moment, the quickest first. **Call 911** is the main goal: "Call from the upstairs bathroom window (one bar of signal), or fix the phone line outside". A standard **Call 911** prompt sits right by the bathroom window (only where the bar is, only while a call can be made): press it and stay put for the call. **Normal: a whispered 10 s call** (a 16-stud "Voice" noise every 3 s); **Hard: 15 s at full voice** (30 studs every 2 s, the old version). (Logs, v77: 36% of nights that reached the blackout never got help called, and the upstairs bathroom was one of his top capture spots: standing at the window, talking loud enough for him to charge every 2 s.) **If nobody gets help out**, 100 s into the last act Mrs. Okafor next door sees the van and calls the police herself (they come 80 s later; ending Sirens), so no night drags on (some ran past 20 minutes until everyone left); act III is 6–7 min (was up to 9). **The moment the call goes through he screams and charges the caller** (`Intruder.onHelpCalled`): the caller gets an urgent thought, "He heard that. He's coming. HIDE. NOW." with how to hide on their device, and on Normal **10 s where he can't grab them** (`Help.CallerGrace`; Hard 0), enough to get behind the shower curtain two steps away; while that lasts he charges at the call but **doesn't go straight to the caller's hiding spot** (he searches around). (v81 logs: most of the 42 captures in the upstairs bathroom came 3–12 s after the call ended, the caller still standing at the window. v87: 29 of 50 captures came within 25 s of a call, there: he arrived as the 6 s ran out and went straight to the shower they'd hidden in, and the heartbeat did the rest.) Optional alongside it: Mrs. Okafor's, the car, the attic, the power (flashlight → the **breaker puzzle** at the panel). The act's thoughts come the moment the lights go (they used to start under the cutscene, "the power's out" with the lights still on): whoever is at the bathroom window (most nights: brushing their teeth) gets one line, "Those footsteps... the man from the news is IN the house. One bar, right here: call 911. NOW.", before the first-timers' tips card; everyone else is told where the bar is. **The police take 120 s** (`Help.PhoneResponse`; v91's 200 was "too long", the owner; Hard ×1.25). **Why 911** (v94; the owner: "it seems we are just randomly calling the police when the electricity goes out"): a second after the lights die, a door slams at whichever outside door is farthest from everyone, and heavy footsteps cross the floor ("[Heavy footsteps. Someone is walking around downstairs]"); then the thought ties it to the news: "Someone switched the power off. And those footsteps... the man from the news. He's IN the house." / "Call 911!"; the objective reads "Call 911: he's in the house". Less waiting before it: bedtime comes 4 s after the news (was 8), the lights go 5 s after brushing (was 12) and 5 s after the chapter card (was 8). (Before, Act III only offered the four-step landline repair: find tape in a random drawer while he hunts you. Half the players who reached the blackout left before the night ended.)
- Environmental story: an open hatch in the garage ceiling with a stepladder under it, muddy size-12 prints, the contractor invoice in the office (Host key), Lily's drawing of "the ceiling man".
- **Discovery.** When someone reads Curtis's notebook in the attic nest, Act IV starts at once. Otherwise it starts when the act times out.

### Act IV — "The Guest" (until an ending, ~15–20 min)
*He knows you know.*
The intruder **hunts**. Objectives change to escape and survival:
- **Call 911.** Either splice the cut line at the junction box outside (electrical tape, then the **wires puzzle**) and use the landline, or find the one flickering bar of cell signal at the upstairs bathroom window and hold a 15-second call. Talking makes noise.
- **Reach Mrs. Okafor's house.** Knock, then survive 15 seconds on her porch in the rain until she opens the door.
- **Escape in the car.** The car keys are in the attic nest (or the spare set is in dad's locked office). The garage door needs power, or the loud manual release.
- **Lock him in the basement.** Lure him down and lock the basement door (house keys or the basement key from the mudroom). This buys time and changes the ending.
- **Free your friends.** Anyone captured is zip-tied in the boiler room. Friends can free them with a 5-second hold, faster with the multitool or scissors. A captive can struggle free alone, but slowly and loudly.

When help has been called, a police timer starts (150 s by phone, 120 s via neighbor, 60 s via car). Curtis panics: for about a minute he goes looking for the caller, then he tries to leave the house.

**Hard cap:** at 60 real minutes, "Dawn" ends the session. Another neighbor reported the van, and the police arrive anyway.

### Endings
| Ending | Condition |
|---|---|
| **Sirens** | The police arrive with at least one player alive (free or zip-tied). Curtis is arrested near his van. |
| **Locked In** | The police arrive while Curtis is trapped in the basement. He is arrested in the house. |
| **Taillights** | Players drove out and brought help. |
| **Next Door** | Mrs. Okafor made the call. |
| **Gone Quiet** (bad) | Every player still in the house was captured before help was called. |
| **He Got Away** (bad) | Help was called, but everyone was taken before it arrived: all dead, or all zip-tied with nobody breaking free in the 45 s last chance. Ends at once; the police timer doesn't run out on an empty house. |
| **Dawn** | The session hit the 60-minute cap. |
| **Not Your Family** (secret) | Everyone was zip-tied at the same time (2+ players)... and at least one of you got out of the burrow under the house. See *The secret ending: Down Here*. |
| **Forever Family** (bad, secret) | Same, but nobody got out before bedtime (or before he had everyone back at the table). |

Paintings are real public-domain artworks: free Creator Store decals (`World/Art`), loaded onto the canvases at runtime by `World/Props`. Wall spans with furniture or fixtures in front are listed in `Layout.NoArt`.

Every ending plays a short letterboxed cutscene for that ending (the car's taillights going down the road, the police at the van, dawn over the house...) with one line of what happened (`Story.Endings[kind].Short`), skippable with SKIP. Then a simple result card: **YOU SURVIVED / YOU ESCAPED / YOU DIED / YOU WERE TAKEN**, the ending's name, that one line, on a win in your first 5 nights a small "Liked tonight? A 👍 on the game page helps a lot." (20 votes, 45%: happy players rarely vote unless asked), and if he killed you **a TIP: how he got you and how not to next time** (like DOORS' guiding light; `Story.DeathTips`: caught in the open, pulled out of a hiding spot, or right after the 911 call), a NEW ENDING tag when it's your first time, the **coins** you earned (counting up, with the reasons and your new balance), and **ANOTHER NIGHT** / LOBBY. ANOTHER NIGHT keeps you in this server: everyone who presses it plays the next night together in a fresh house ("Sam wants another night (1/3)"); once everyone has chosen, it starts at once. **When the countdown ends (35 s, "Next night in 35s · LOBBY to leave"), everyone still there plays the next night together**; only LOBBY takes you back. (It used to send whoever hadn't pressed anything to the lobby: half the players never touched the card, and most of them left the game from the lobby.) Out early (escaped or dead, friends still inside), your own card already has **ANOTHER NIGHT** and LOBBY under SPECTATE: say yes there and the ending card shows WAITING FOR FRIENDS. (In the logs, players who died almost always left alone for the lobby, and the group was gone.) LOBBY says GOING TO THE LOBBY... the moment it's tapped (the teleport takes a few seconds; people tapped it six times).

**Chat tags** (client `ChatTags`, `TextChatService.OnIncomingMessage`): in the chat, a player's name carries ★ (supporter) and their equipped title in its colour, e.g. ★ [Attic Explorer] Sam, in the lobby and the house.

**Player list** (Roblox's own, top right in the lobby; `StatsService` leaderstats): each player's **Level** and **Survived** (nights survived), kept up to date. The owner has none (off every board). The house hides the list, as before.

Out early: escaping in the car or next door, or dying, while friends are still inside gives you your own card straight away (Remotes.Result) with a SPECTATE button. Solo, an escape or death ends the night on the spot. Escaped players wait at Mrs. Okafor's (frozen, out of sight) and watch their friends from there: the spectate camera follows anyone still in the house, including friends tied up at the dinner table. (They used to be left standing in a bare room inside her house.)

### The secret ending: Down Here (`FinaleService`, `World/Burrow`, client `Finale`)
If **every** player in a 2+ player night is zip-tied at the same moment (in Act III or IV, nobody escaped), the bad ending doesn't come. The screen goes black and everyone wakes up **under the house**: the burrow Curtis has dug beneath the basement, 30 studs down. It's a 10–15 minute act of its own (the police and dawn wait while it runs).

**1. Dinner (5½ min to bedtime).** Everyone is zip-tied to a chair at a long table set with place cards ("Jamie", "Riley"...), a chalkboard of "family rules" and a wall of stolen photos. He calls himself the dad. Each player's chair: struggle (tap/press) only while **his back is turned** (he's at the stove, 6–9 s). A creak warns that he's **turning around** (1.1 s), then he **watches** the table for 3½–5½ s. Struggling while he watches is a **strike**: a line from him, the tie tightens (a quarter of the struggle undone; Hard: half) and bedtime comes 20 s sooner (Hard: 30 s). On Normal the first strike of the night is only a warning (no time lost), and the first 0.8 s after he turns round don't count (Hard: 0.3 s): a press that late is a reaction (v97: 13 of 35 secret endings had ended in Forever Family, many inside 60-80 s, about 9 strikes each, and 12 more were abandoned about 100 s in). Struggling takes about 83 presses (1.2% each; was 0.8%). Sometimes the creak comes and he doesn't turn (a fake-out). Free players must stay by their chair while he watches, or that's a strike too (Normal: pushed back to the chair; Hard: tied up again); while his back is turned they can sneak to a friend and cut them loose (2½ s hold). When everyone is free, he unbolts the dining-room door, says "Dessert" and climbs the ladder up into the house: he is really gone (off the map) for 75 s (Hard: 56 s), and the card counts down until he comes back.

**2. The tunnels (11 min to bedtime).** Dirt corridors join the dining room, a nursery, his room, a pantry and the cellar. Every doorway has a plank sign over it (PANTRY, NURSERY, HIS ROOM, STORM CELLAR, DINING ROOM) and each junction has a signpost with an arrow-shaped board per way out. The task names the rooms ("Read his 3 notes for the lock code: PANTRY, NURSERY, HIS ROOM"), each note has a marker until someone reads it and glows a little, and the card shows the code tiles and which notes are left. After the dessert break he comes back down the dining-room ladder (a hatch creak, a warning) and patrols them with his own senses (sight cone of 110°, 22 studs, 34 if your flashlight is on; he always sees you within 3½ studs; he hears noises at 80% range and investigates, never twice the same spot). Hide behind a blanket and crouch: four **blanket nooks** across room corners and seven **alcoves** dug into the tunnel walls (3 wide, 3 deep, a blanket across the opening that blocks his view). He only finds you if he walks right up to it. If he catches you, you're back at the table, tied, and only a friend can cut you loose (3 s). Three **notes** give the cellar's **4-digit lock code** (pantry: the first digit, nursery: the second, his room: the last two) and a piece of who he is. Everyone is told who read which note and the code so far; when it's complete: "Go to the STORM CELLAR (north tunnel) and type it on the keypad". The keypad screen shows the code from the notes too. In the last 70 s it's **bedtime**: he stops patrolling and hunts at a run (still slower than you walk).

**3. Out.** Type the code at the cellar keypad (a wrong code buzzes and he hears it). Bar the cellar door behind you (each plank holds him ~18 s while he bangs on it), push the hatch up (4 loud pushes) and climb the ladder out to the lawn grate. Once nobody is left loose below (everyone either out or tied back at the table), or at bedtime: if **anyone** got out, **Not Your Family** (they bring help); if nobody did, **Forever Family**. Bedtime at the dinner table is always Forever Family. Each has its own cameras and badge, the secret one pays +150 coins and gives the title "Not Your Family".

A grate on the lawn has a prompt with a hint, so people who never saw the ending wonder what's under it.

**The bar** (client `Finale`, top centre) is one slim line: a coloured dot and where he is (HIS BACK IS TURNED / HE'S TURNING / HE'S WATCHING · DON'T MOVE; later HE'S UPSTAIRS · 0:52 / HE'S IN THE TUNNELS / HE'S HUNTING YOU), the lock code so far (CODE 4 _ _ _), and bedtime, free players, strikes, the hatch. A short line of what to do appears under it only when it matters (at the table, or tied back up); in the tunnels the objective panel says where to go. The edges of the screen breathe red while he watches the table. No music plays in the finale (no stings when he turns, no music box).

### Halloween 2026 (`HalloweenService`, `Economy.Halloween`, until 2 Nov 12:00 UTC)
Halloween is when Roblox horror gets searched most, and traffic had fallen to ~5 visits an hour between reels. During the event:
- **Candy hunt:** 5 wrapped candies (orange, foil ends, a faint glow so they can be found in the dark) at random spots each night, at least 12 studs apart, picked from `Layout.CandySpots` (24 floor/rug/table/hearth/bed/desk spots computed from the world dump with nothing in the way, at most 5 studs above the floor, checked in renders). "Take Candy" prompt; "🍬 Candy! 12 in all · Candy Corn at 15 · 3 more in the house". Surviving the night adds 2. Told once, 40 s into the night.
- **Saved candy** (`Economy_v1` field `Candy`, added through the pending delta like coins) unlocks limited cosmetics at 5 / 15 / 30: the **Pumpkin** flashlight colour, the **Candy Corn** trail and the title **Trick or Treat** (earned in the game, never in crates). After the event they show "Halloween 2026 event" and can't be earned. Reaching 5 also gives the free **Halloween 2026** badge.
- **Jack-o'-lanterns:** the big porch pumpkins are carved (triangle eyes and nose, a grin, glowing Neon, a candle PointLight; `Kit.jackFace`), two more light the front walk, and the lobby's big pumpkins grin at the queue circles. Carved pumpkins keep the Kit shape (`PropKey = "JackOLantern"`, so the Creator Store pumpkin swap skips them).
- **Where you see it:** a small orange line under PLAY in the lobby ("🎃 HALLOWEEN · 🍬 7 · Candy Corn at 15"), the candy line on the result card, progress on locked Locker rows, and an admin COINS-tab candy button. Logged as `Candy` events.
- **For the owner:** `marketing/attic/icon_halloween_512.png` (the icon with a HALLOWEEN ribbon and a jack-o'-lantern) and the title "someone lives in our attic. [🎃 HALLOWEEN]" until 2 Nov.

### Coins (`EconomyService`, `shared/Economy`, client `Store`, `Locker`, `Rewards`)
Every player has a coin balance (DataStore `Economy_v1`; 100 welcome coins). Saves are merges: pending changes are added onto whatever another server saved, owned cosmetics are a union, and Robux receipts are recorded in the same document, so a coin pack pays exactly once.

**Earning, per night** (shown on the result card): 20 for playing, 1 per minute you lasted, 40 for surviving, 15 per friend you freed, 50 for an ending you hadn't seen, 150 for the secret ending. Hard nights ×1.5; the Lucky charm ×1.5.

**Night streak:** start another night within 15 minutes of the last one ending and it pays more: the 2nd night in a row +25%, the 3rd and on +50% (a "Night streak ×N" line on the card). Saved with the coins (merged: the latest night wins). The result card says "Play another night in the next 15 min: +25% coins" under ANOTHER NIGHT, and the lobby shows "NIGHT STREAK +25% coins · 12:31" under the play buttons while it's alive.

**Daily reward:** a 7-day streak (25, 40, 60, 80, 100, 130, 200 coins, plus an Attic Crate on day 7). Missing a day starts it over. The panel opens by itself when you join with a reward waiting (players who have finished a night). **It also comes with the night:** finishing a night (2+ min) claims today's reward if it's still waiting ("Daily reward, day 1" on the card), so everyone who plays a night has a streak to keep; day 7 (the crate) is left for the lobby, where its reel plays. The card then says what tomorrow's is. (Half the players never opened the panel: it doesn't open for brand-new players.)

**Quests:** 3 a day out of 12 (survive a night, cut a friend free, hide from him, solve the electrics, read clues, play on Hard, find a new ending...), 40–120 coins each, progress shown in REWARDS.

**Store, Items tab:** one-night gear, bought in the lobby and handed to you when the next night starts (one of each kind per night): Flashlight 60, Walkie-talkie 40, Multitool 70, Pepper spray 90, Energy drink 50 (more stamina), Lucky charm 80. (No revive for coins: revives are Robux only.)

**Store, Crates tab:** Attic Crate 150 (62% common, 27% rare, 9% epic, 2% legendary) and Midnight Crate 450 (rare or better). A crate spins a reel and lands on a flashlight colour or a trail (no titles: those are earned, below). A duplicate pays back coins by rarity. Odds are printed on each crate.

**Store, Coins tab:** Robux coin packs (developer products): 250 coins for 25 R$, 650 for 49, 1,500 for 99, 4,000 for 199.

**Locker:** equip flashlight colours (invite rewards, passes, crate colours incl. the rainbow one), a title shown above your name in the lobby (and in the chat), and a lobby trail. Locked items say how to get them (crates, "Reach level 10", "Climb into the attic"); tapping a locked title does nothing (it isn't for sale).

**Titles are earned, never in crates** (`Economy.Special`, `EconomyService.achieve`: granted once, with "Title unlocked: ... (equip it in the lobby LOCKER)"). Anyone who got one from a crate before keeps it (same ids).

| Title | How |
|---|---|
| Pizza Lover | Answer the door to the pizza man |
| Attic Explorer | Climb into the attic |
| Scaredy Cat | Hide from him 5 times in one night (while he hunts) |
| Survivor | Survive a night (escape, or still standing at a good ending) |
| Night Owl | Play 3 nights in a row (night streak ×3) |
| Phrogger | Find his nest in the attic (read his notebook or polaroids) |
| The Quiet One | Survive a night without him ever seeing you |
| Legend of Alder Lane | Survive a Hard night without being caught |
| Not Your Family | The secret ending |
| Insomniac, Still Breathing, Attic Veteran, He Can't Catch Me | Levels 5, 10, 20, 30 |

**Levels.** XP is every coin earned by playing (nights, quests, daily rewards; never bought coins). Level L takes 50·L·(L−1) XP in all (level 2 at 100, 5 at 1,000, 10 at 4,500). Each level up pays 20 × level coins (level-up coins aren't XP), and some levels give more: 3 an Attic Crate, 5 the title "Insomniac", 8 an Attic Crate, 10 "Still Breathing" + a Midnight Crate, 15 a Midnight Crate, 20 "Attic Veteran" + Midnight, 25 Midnight, 30 "He Can't Catch Me" + Midnight. Rewards are paid once per level (`LevelPaid`, merged as the highest across servers); a player counted for the first time gets the titles of the levels they already have, no back pay. Shown as "LV 7" before your title over your head in the lobby, with an XP bar under the coin balance, and on the result card: the XP bar fills with the night's coins and LEVEL UP if it goes over. The card also says what tomorrow's daily reward is ("Don't break your streak!").

---

## 4. Core Mechanics

### Movement & stealth
- First-person camera, locked.
- Walk 10 · Crouch 5 (**C**) · Sprint 17 (**Shift**, uses stamina; run dry and you're winded until it's back to 35%).
- **Footstep noise is calculated on the server** from real velocity: crouch 4, walk 16, sprint 38 studs.
- Noise is heard at ~55% range through floors.

### Noise system
Everything loud emits a noise event (position, radius, kind): doors, the microwave, knocking, breaking glass, phone calls, struggling, the manual garage release. The intruder hears events inside the radius and investigates. Interactions are designed around the trade-off between noise and speed.

### Light & darkness
- Every room has a switch. Lit rooms make players visible from much farther away, but they also make Curtis cautious before Act IV.
- **Flashlight** (**F**; two in the house, in different drawers or shelves every night: one is always downstairs). Its battery drains. You see farther, and you are **visible from across the house**.
- After the breaker is flipped, only flashlights, phone screens, the fireplace, Lily's battery nightlight and lightning light the house.

### Nerve (composure)
0–100 per player. It falls when you are alone in the dark, when you see the intruder, when you hear scary events and when a friend is caught. It recovers near friends and in light (your flashlight counts). **The dark alone only takes you down to 50** (`Config.Nerve.DarkFloor`): below that it takes seeing him or having him close. (Logs, v77: 55 of the 102 players who quit alive during the hunt had nerve under 20. Alone in the dark it used to drain 0.55/s, so everyone hit 0 about three minutes into the hunt: half the screen black, a pounding heart, and panicked breathing he could hear.) The low-nerve vignette closes to 0.6 at most (it was 0.85).

Low nerve causes heavy breathing he can hear (louder when crouched or hiding), camera tremor, a darkening vignette, a faster heartbeat and faster stamina drain. (You don't hear your own breathing: the only licensed clip was a man grunting and coughing, which players heard as someone coughing and saying "hello" every few seconds.)

### Hiding
Wardrobes, closets, under beds, behind the shower curtain, under the basement stairs.
- Hiding switches to a fixed peek camera.
- Hold **Space** to hold your breath for up to 8 s. This matters when he's close.
- If Curtis **saw you hide**, he goes straight to that spot. Otherwise he checks nearby spots at random while searching. Lower nerve makes him more likely to find you.

### Capture & rescue
If Curtis grabs you, the screen fades and you wake zip-tied in the boiler room. He takes your pepper spray and car keys (the keys go back to his nest).
- **Rescue**: a friend holds the prompt for 5 s, or 2.5 s with the multitool.
- **Struggle**: mash **Space** (about 63 presses, 1.6% each: doable in the 45 s last chance on a phone). It's noisy.
- Curtis comes back regularly to check on his captives.
- **A head start once you're free.** Breaking your zip tie (or being cut loose) gives you 40 s (Hard: 20 s) in which he can't see, hear or grab you, and he forgets your trail: "Get out of the basement. Quietly." (The logs: 9 of 35 deaths came within a minute of getting free, often still in the basement.)
- **One second chance only.** Getting caught a second time is fatal: a jumpscare, then you're out of the night and **spectate** your friends (tap to switch; with nobody left, the camera watches the house from the street). Your fate on the recap reads *Didn't make it*.

### The electrics puzzles (`PuzzleService`, client `Puzzle`)
Two small hands-on puzzles, in a panel in the middle of the screen (big targets for thumbs). You stay at the box while you do them, and he can still find you there.
- **Splice the phone line** (junction box, with tape): four cut wires (three for the Tinkerer) on the left, their ends in a different order on the right. Tap a wire, then the end of the same colour; each one you join is drawn across. A wrong end **sparks** (a 22-stud noise he can hear) and you try again.
- **Reset the breakers** (the MAIN, with the power off): three of eight circuits (KITCHEN, LIVING RM, HALL, BEDROOMS, BATHS, GARAGE, BASEMENT, PORCH) have tripped. Tap them back ON (tap a good one by mistake and it goes off too), then throw the MAIN. The MAIN with anything still off just **clunks** (30-stud noise). Turning the power *off* is still one flip.
- The server deals each puzzle and checks the answer (the breaker taps are replayed in order). Walking more than 10 studs away, hiding, or being caught closes it; slips are limited to one noise every 0.6 s.

### The intruder AI (`src/server/Intruder`)
**The Figure brain** (`Config.Intruder.Brain = "Figure"`, the default; modelled on the Figure in DOORS). He hunts by **sound**, not by a sixth sense:
- **Patrol**: room to room between nav nodes (weighted to the floors players are on), stopping to listen; now and then he stops at a hiding spot and listens.
- **Investigate**: a quiet noise (a door, a lock, the microwave, a tied-up friend struggling, at most once a minute) makes him growl and walk over, then pace around where it came from before going back to his patrol.
- **Charge**: a loud one (anyone walking within 16 studs or running within 38, glass, a slam, a phone call, someone being cut free) makes him roar and go for it (9 studs/s, 9.6 on Hard), re-aiming at every new footstep; then he thrashes about where it was. Anyone he runs into, he grabs. Louder (its reach minus its distance) beats quieter. **Crouching is silent** (4 studs).
- **Inspect + heartbeat minigame**: hide near him (or let him walk right past you without holding your breath) and he stops at your hiding spot, swaying, listening, for 7 to 10 s, ignoring everything else. Half-hearts fly in from the left and right; press that side as each reaches the heart (the big LEFT/RIGHT buttons on every device, Q/E, A/D, arrows, LB/RB or the d-pad). Three misses (two on Hard, beats faster and a tighter window) and he rips the door open. The heart shows 2.4 s before the first half arrives (v91; it was 1.4 s, barely time to read it: v88-90 Normal still passed only 28 of 60), he listens 7-10 s (was 6-9), and the last half lands at least 1.2 s before he decides, so it counts (unanswered, it's a miss: doing nothing always fails). Each beat counts if pressed within 0.42 s (0.22 on Hard); the halves take 1.3 s to fly in, about one every 1.25 s (Hard: 0.9 s, every 0.8 s). (v81: Normal still failed 34 times in 61, so it got wider and slower again. v87: 35 of 50 failed on Normal; PC players only had Q/E named and no buttons, so the buttons show everywhere now, and on Normal the first wrong-side press on a beat is forgiven: the other side in time still counts. Doing nothing still fails; more misses allowed would have let a player who pressed nothing outlast his 6 s listen.) Step out while he's there and he has you. The server deals the beats and counts misses; unanswered beats are misses. When he walks off without hearing you, it's a **pass** ("He's moving away...", and the heartbeat quest counts it). (The first day of logs had 0 passes in 22: he walked off a moment before the session's own end and every success was recorded as a plain stop; Normal was also failed 14 times out of 22, so it got a wider window and slower halves.)
- **Sight** is short (28 studs in a lit room, 10 in the dark, 40 with your flashlight on; Hard: 32 / 10 / 45): close up he sees you and follows you (9 studs/s, 9.6 on Hard); he saw you get in a hiding spot = found. Grab range 4.5 (5 on Hard).
- **After a capture** (the captive is already zip-tied in the boiler room) he doesn't go down there: he walks off to a dark spot on another floor, far from the boiler room, and for **45 s** (30 on Hard) nothing from the basement brings him back (struggling, a friend cutting them free) and his patrols skip it. The captive hears him go: "His footsteps are going back up the stairs. Struggle. NOW." (Before, he walked the captive's way to the boiler room and was standing right there while they struggled.) He ignores people only for the first **4 s** of walking off (10 s after pepper spray); after that anyone he sees within 30 studs gets chased (the owner stood right in front of him while he walked away). **He enters the house far from everyone**: down the garage hatch, or (someone near it) the shadow spot farthest from all players; caught mid-glimpse near someone when the hunt starts, he slips away first. **Drift**: when nobody has run into him for 60 s of the hunt, his patrol routes lean toward players who are out in the open (not hiding), so the dark never goes dead (v87: 42 of 48 who quit in the dark never got help called; 27 never saw him).
- **v102: he's faster than your walk, slower than your sprint** (the owner: "make him faster"). Chasing 12.5, charging 12, the last lunge 13.5, patrol 8.5 (Hard 13.5 / 13 / 14.5 / 9), capped at 14.5 (`Config.Intruder.MaxSpeed`); you walk at 10 and sprint at 17, so once he's seen you, you run and break line of sight, then hide. Alone he's 1 stud/s slower. The secret ending's tunnels: 11; a player who has become him: 11.5.
- His footsteps shake your screen, harder the closer he is. The first hunt starts with him charging the nearest player (he heard the whole house).
- `Brain = "Classic"` keeps the older brain (he always feels roughly where you are, a few seconds late).

**How he walks** (`NavGrid.luau`, `Navigator.luau`). PathfindingService's navmesh lost narrow doorways, and with no path he used to walk face-first into walls, furniture and doors. Now, a couple of seconds after the server starts, the house is **surveyed on a 1-stud grid** (a few ms a frame): each column is probed for its surfaces, and a surface counts only if a box the size of his body (2.2 wide, 1.2 to 8 studs up) touches nothing he collides with (CanCollide, Intruder collision group: door leaves don't count, characters don't count). Neighbouring cells within a step's height are linked, so the stairs are ramps and a bed top is an island nothing is routed to. Routes are A* on that grid (a small cost for hugging walls keeps him mid-hall and mid-doorway), pulled taut into straight runs whose every point sits in a square of four standable cells, so his body never clips a jamb or a table corner. He steers every frame: the moment the next corner is in a clear straight line from where he actually is, he heads for it. A goal nobody can stand on (in a cupboard, on a bed) ends at the closest reachable spot. Chasing or charging, he runs straight at you only when the grid says the straight line is clear; otherwise he takes the route. Pacing about a noise picks points he can walk to. Closed doors on the route are opened (forced, if locked). Wedged for a second: re-route; still wedged and unseen: he slips to the next corner. Outside the surveyed area (the yard), PathfindingService. A patrol leg gives up after 40 s.
- **v100 ("improve pathfinding a lot")**: routes keep their distance. After the survey every cell gets its **clearance** (0 = against a wall or furniture, 1, 2, more), and A* pays 1.5 / 0.5 / 0.15 to step on them, so routes run mid-room and give corners and jambs room; the taut-pulling may not cut across a cell the route itself kept off (a doorway is all clearance 0, so it's on the route and allowed), and his look-ahead takes a shortcut only when it doesn't brush past anything either. In plain sight with room either side, no search at all (two waypoints). Of a route's length, 23% ran against a wall before, 5.5% now (`navai_test bench`). **Wedged twice**: he steps back off whatever caught him (2-3 studs, straight back or fanning to the sides, a spot with room) and goes round again; still wedged and unseen, he slips. **Chase bug**: a chase re-routes every second, and each re-route used to reset his wedge count and his "last moved" clock, so a wedged chase never got to a step back or a slip, he just stood there re-routing; the same errand now keeps both, and a door he's waiting for or a step back finishes first. **Telemetry**: how he got about each night goes in the night log (`Nav`: wedged, step-backs, slips, failed routes, routes and ms each; pull_stats prints it).
- **Tested in the real house** (`tools/harness/navsim.luau`: the built house's parts, ray and box queries, and a body that collides with them, floats over the floor and gives up a MoveTo after 8 s; `navgrid_test.luau`: every nav node and hiding-spot exit reachable; `navai_test.luau sweep`: 450 random trips between rooms and hiding spots, none failed, none wedged; `navai_test.luau brain`: the Figure brain hunting three players for 5 minutes, worst stall under 3 s).
- The survey found the coat closet hanging over the basement stairs (he couldn't get down them under it); it's now in the front hall against the office wall.

Newest behaviour: he **investigates noises** when nobody is out in the open (a door, the microwave, someone running, a friend being cut free): goes there, stands and listens, may tear open a nearby hiding spot; a loud noise elsewhere pulls him off a search (players can lure him). His rest is the players' window: footsteps don't end it, but a door slammed or the microwave right next to him does. He **hears breathing**: walk past a hiding spot and, unless its occupant is holding their breath, he may hear them (more likely the more scared they are); they get a "He's right outside. Hold your breath." warning first. Holding your breath runs out after 8 s, with a gasp he can hear. He **prefers the one on their own** and the one waving a flashlight.

A state machine with perception:
- **Vision**: a 100° cone, raycast line of sight. Range depends on light: 80 studs lit, 22 dark, 110 if the target's flashlight is on. Crouching shortens it. Hidden players are invisible. Up close he doesn't need to face you: within 7 studs always, 11 if you're walking upright, 12 with your flashlight on, 16 if you're sprinting. Only a player who is crouched and still can stay right behind him (4 studs). If he's opening a cupboard and someone in the open is within 10 studs and in his senses, he drops the cupboard and goes for them.
- **He always knows roughly where you are** (the hunt): every half second he feels where each player who isn't hiding is, and acts on where they were **3 s ago** (a bloodhound on your trail). Hiding makes the trail go cold; after you leave a hiding spot he can't feel you for **8 s**. Loud noises (sprinting, slammed doors, trying the exits) are felt immediately.
- **Hearing**: noise events, reduced across floors; a loud noise ends his break early.

| State | Behaviour |
|---|---|
| `Offstage` | Acts I–II. In the attic. The Director fakes his presence with real, logged events. |
| `Lurk` | After the blackout, for ~35 s before the hunt starts. Hidden most of the time. He picks a spot 14–38 studs from the loneliest player, in their line of sight but not where they're looking, and **stands there staring**. Once seen he holds the stare for a beat and slips away. Walk up to him and he shoves you and bolts. |
| `Prowl` | The hunt. A door slams and he **runs** (15 studs/s; you sprint at 17 for ~7 s) to where he feels the nearest player is, heavy footsteps thundering through the house. |
| `Chase` | He can see you: **18 studs/s, 22 lunging** in the last 10 studs, and he doesn't tire. Lose his sight for 2.5 s and he's back on your trail. |
| `Search` | His target hid. He goes to where he last felt them, stands and listens, then tears open up to **2 hiding spots** nearby (the one you're really in 1.5x as likely; one he saw you use always first). |
| `CheckSpot` | Opens a spot. Saw you get in: caught. Otherwise 75% you're found, 30% if you're holding your breath. |
| `Ambush` | 40% of the time after a failed search he only pretends to leave: creeps off silently (too slow for footsteps) to a spot 8–20 studs away with a view of the area, stands there 9–14 s, then comes back for one more look at a spot he hasn't opened. Leave your hiding place too soon and he's right there. |
| `Withdraw` | Gives up for now: walks off somewhere dark and stands there 22–34 s (half that once help is called). This is when you move. Seen within 30 studs, he comes anyway. |
| `Retreat` | After pepper spray or a capture. |
| `Trapped` | Locked in the basement. Tries to force the door (~90 s). |

**Balance check** (`tools/harness/sim_test.luau`, bots on the ground floor, room-based line of sight, 3 runs x 5 min): a bot that never hides is caught 17 times (about once a minute); one that hides when he's coming and holds its breath when he's close is caught twice in 20 hides.

**Hiding spots (19):** every bedroom has a bed and a closet; upstairs linen wardrobe and shower curtain; downstairs the den closet, a coat closet at the back of the front hall, a utility closet in the mudroom, a storage cabinet in the garage, under the dining table, under the office desk, and behind the long curtains in the living room and the den; under the basement stairs. When he searches he looks at up to two spots within 18 studs, so a room with several spots is safer than a dead end.

The loop is **hear him coming → break line of sight → hide → hold your breath when the doors open → move while it's quiet**. If you don't hide, he gets you. There is no safety in numbers any more; friends matter because they can cut you loose (once: a second capture kills). Calling for help makes him frantic: shorter breaks, and he goes straight for the caller. He opens doors, and locked doors cost him 5 s.

### The Director (`src/server/Director`)
- It tracks **tension** (0–100), which rises with events, sightings and chases and decays over time.
- It schedules events only when tension is below the act's ceiling, so quiet stretches happen by design.
- It picks targets that are alone or near windows, and only fires events whose conditions hold, for example that nobody is looking.
- Each act has **guaranteed beats** (footsteps upstairs, the window figure, the power cut) with deadlines, plus a pool of weighted optional events.
- It writes the Truth log for the ending screen.

### Communication
- **Proximity text chat**, 50 studs (`TextChatService.ShouldDeliverCallback`).
- **Walkie-talkies** (a pair on the garage workbench) extend chat to anywhere between holders.
- Enable **Spatial Voice** in Game Settings for proximity voice.

### Items
**Usable items are Roblox tools in the hotbar** (v94, `ToolService`, client `Gear`; the owner found eight round action buttons "so crowded"): the flashlight, taser, pepper spray, rocket launcher, energy drink and firecracker each appear in the Roblox hotbar while you have one, named with what's left ("Taser (3)"), with a small model in the hand. Pick one (1-9, tap it, L1/R1), then click / tap / R2 to use it, aimed at the point under the mouse or finger. The flashlight stays off when you take it out (v95: on by itself the moment it was in your hand, everyone walked around lit up for him); a click switches it on and off, F takes it out lit or puts it away. Your own beam casts shadows only on PC, and drops them after three seconds under 40 fps (v94 logs: PC nights under 30 fps 18 of 55, was 7 of 70). The hotbar hides while you hide, are tied up, dead, him, in a cutscene, a conversation or the heartbeat minigame, and the bottom-centre HUD (stamina, hints, subtitles) moves up above it while it shows. Keys, tape and the other story items stay in the HUD list. Taser: aim assist 30° (was 9°: "I don't even think the taser works"), and since v102 within 26 studs with him in plain sight **every shot hits**, wherever you point ("too hard to aim"); range 50, stun 5 s with blue sparks crawling over him; before the hunt a click keeps the shot ("Save your shots for him"), a miss says so. Rocket: aim assist 15°, no rocket wasted before the hunt. Pepper spray: aimed where you click, 45° cone, 15 studs, a visible cloud.

**Item icons (v100)**: each tool shows its own picture in the hotbar slot (`ToolService.Info`: Creator Store images, checked by eye: flashlight, taser, pepper spray, rocket launcher, energy drink, firecracker) with its name under it, and while one is in your hand a small line above the hotbar says what it is and what's left ("TASER · 3 SHOTS", "TASER · LAST SHOT").

Flashlight ×2, Walkie ×2, Pepper Spray (mom's purse, 2 uses), House Keys (Host), Multitool (Tinkerer), Car Keys (hook → attic nest; spare in office), Basement Key (mudroom), Electrical Tape (two rolls, random drawers each night), Fire Poker (breaks ground-floor windows, very loud), Scissors (bathroom).

### PC and phone layouts (v104)
A player: "unnecessary mobile UI for pc players". The HUD is designed for a phone; on a 1080p monitor `UI.rescale` blew it up 1.3x (chunky buttons, huge text). With a mouse and keyboard it now stays at about its real size (`min(w/1320, h/742)`, 0.72-1.05); phones and consoles on a TV keep the big layout. The heartbeat minigame shows two small **Q / E** key caps at the ends of the lane (LB / RB on a pad; still clickable) instead of the phone's big LEFT / RIGHT pads, and no message tells a PC player to "tap". To look at a layout without the Roblox client: `lune run ui_dump <lobby|night|hunt|heartbeat|hiding|captured> <pc|touch> out.json` (tools/harness) then `node tools/assets/ui_preview.mjs out.json out.png pc|phone|tablet [backdrop.png]`.

### Controls
| Key | Touch (phone / tablet) | Gamepad | Action |
|---|---|---|---|
| E | Tap the prompt | X | Interact (press and hold the prompt for hold actions) |
| R | Tap the blue prompt | Y | Lock / unlock (doors), secondary actions |
| 1-9 / click | Tap the item in the hotbar, then tap | L1/R1, R2 | Pick an item, use it (v94) |
| F | (hotbar) | D-pad up | Flashlight out / away |
| C | CROUCH | B | Crouch toggle |
| Shift | SPRINT (toggle; turns off when you stop or run out of stamina) | L3 | Sprint |
| Tab | JOURNAL (top right) | D-pad left | Journal (objectives) |
| P | PHONE (top right) | D-pad down | Phone |
| Space | BREATH (hold) / STRUGGLE (mash) | A | Hold breath (hiding) / struggle (captured) |
| E | LEAVE | B | Leave a hiding spot |

**Mobile layout.** Roblox's own thumbstick (move), camera drag (look) and jump button stay. The action buttons sit in an arc around the jump button and change with context: exploring shows SPRINT and CROUCH (items are in the Roblox hotbar since v94); hiding swaps them for a big BREATH button and LEAVE (drag anywhere to peek around); captured shows one big STRUGGLE button. Interactions use the standard Roblox ProximityPrompt, which only fires on a deliberate tap (dragging the camera across it does nothing). Roblox shows only one prompt per key at a time, so a prompt right next to a task's prompt takes the secondary key and sits just below it (the drawers under the microwave and the kitchen phone, the note beside the pizza menu, Sit on the sofa next to Search the cushions, double light switches): on phones the drawer kept winning over "Make popcorn" and phone groups lost 2-3 minutes there. `prompts_test` fails on any such pair. Phones get a lighter rain density, and panels (phone, documents) move off the right side so they never cover the buttons. Every touch button fires the same input action as its key, so there is one code path for all devices (`client/Controllers/Input` → `MobileControls`).

---

### Cutscenes (`CutsceneService`, client `Cutscene`)
Short letterboxed moments in the middle of the night, like the endings': **Lights out** (Act III: from across the street, the lit house goes dark all at once as the breaker drops), **He comes down** (the first hunt: him standing under the garage hatch, a slow push-in on his face), and **Tied up** (your first capture: a look at yourself zip-tied to the boiler-room pipes, just for you). Shared cutscenes hold the players and him still, so nobody can be caught while the camera is away. The HUD and touch buttons step aside while one plays. The admin panel can replay each one.

### The TV (World `TVScreens`, client `TVVoice`)
No laugh track. Channel 7 is a real broadcast: an anchor (Dan Whitlock) at the desk, the SUSPECT box over his shoulder, a BREAKING bar and ticker. Channel 11 has a weather presenter beside the radar. Both read their bulletin aloud with Roblox text-to-speech (`Story.TVVoice`), their mouths move while they talk, and they blink. Channel 4's old film speaks each subtitle as it appears. Louder the closer you are; each line is generated once per player and replayed. The voice isn't positioned in the world (text-to-speech plays straight to the speakers), so it is only heard while you can see the screen, within 34 studs: never through walls or floors, and never during the secret ending under the house (it used to carry through the whole ground floor and down into the burrow, a stray "Good evening..." like a radio).

### Owner admin panel (`AdminService`, client `Admin`)
Only for `Config.Admins` (the owner's UserId), the experience owner, and Studio; every command is checked on the server. An ADMIN pill at the top (or F2) opens: start the night now (Normal/Hard), jump to any act, next act, restart the act or the house, call any kind of help, police in 5 s, preview the cutscenes; hunt / hunt me / lurk / offstage / show himself / freeze / bring him behind me / trap / X-ray; invisible to him, all items, battery, nerve, free me, revive me, teleport to any room; fire any scripted event; trigger any ending. A debug line shows the act, his state, the difficulty and the police timer. **Can't be caught** (ME tab, `AdminGod`): he still hunts, chases and grabs at you, but every capture, death and hiding-spot rip-out does nothing (a growl, a shake and "[He grabs you. Nothing happens.]"); the debug line shows CAN'T BE CAUGHT. **COINS** tab (also the only tab in the lobby, where the panel opens too): +100 / +1,000 / +10,000 / +100,000, -1,000 or any amount typed in. Saved like any other coins; it can't take you below 0.

### Quality of life
- **Settings** (lobby menu, and the journal in the house): music volume, sound volume, camera shake on/off. Saved with your stats. Every sound is routed into a music or an effects SoundGroup on the client.
- **Friend tags**: each friend's name and distance over their head, through walls, hidden when they're close. A captured friend's tag turns red: "TIED UP".
- **Skip** on ending cutscenes.
- **Messages never overlap**: everything said at the bottom of the screen (sound captions, spoken lines, your thoughts) is one stack; chapter cards hold the queue; nothing talks over a notice, a conversation, a cutscene, the vote or a result card; a line from an earlier act is dropped instead of arriving late; "New objective" is skipped when "Done" beats it to the screen.
- **The yanked door**: after something yanks at an outside door, the first person to open it gets a loud hit. Nothing is there.
- **Lobby**: big PLAY SOLO / FIND PLAYERS buttons, a How to play card, everyone carries their flashlight in the colour they picked, and now and then a light comes on in the dark upstairs window of the house with someone standing in it.
- **Fastest wins**: every win is timed (an escape at the moment you get out; everyone still standing at a good ending at the moment it ends). The result card shows YOUR TIME and ★ NEW PERSONAL BEST; your best shows on the lobby record line; the top 10 go on the FASTEST WINS sign beside NIGHTS SURVIVED (`FastestWin_v1` OrderedDataStore, lowest first). The game's owner (and `Config.Admins`) never go on either board: their nights aren't written, the signs skip them, and on start the server removes any old entries of theirs. **Nights that start at the blackout (⏩ SKIP TO THE BLACKOUT) never count** (no board time, no personal best), and neither does any win under 6:00 (`Config.MinBoardWin`): a full night can't be won that fast (the fastest real one in the logs: 7:21, by car). Every board time under 5:20 had come from a skip night (the owner saw a 0:51); servers remove entries under 6:00 on start, and saved personal bests under it are ignored.
- **Things open**: the kitchen fridge swings open on both doors (the light comes on with the power; soda, eggs, milk, ketchup, leftovers, juice, and Mom's lasagna until he takes it; Mom's note and the menu ride on the door), and the oven door drops open on its bottom hinge. Each makes a small noise.
- **Props sit on their surfaces**: the Creator Store models (plates, mugs, bowls...) are fitted to their placeholders, then measured with rays (the model's real underside, the real tabletop) and set down exactly on it, so nothing sinks into a table.
- Every button clicks; notifications have their own sounds by kind; the police countdown beeps for its last 10 s.

### Opening shot (client `Intro`)
At the start of each night, for a player's first 3 nights, the camera holds on the house from across the street for 4.6 seconds:
- black bars top and bottom, and the caption "14 Alder Lane · Friday, 8:47 PM";
- at 1.5 seconds, lightning, and for 0.55 seconds he stands in the upstairs front window;
- then a cut inside.

Notices and the chapter card wait until the shot ends (`Notice.hold`). It exists for retention: players see the threat in the first seconds, while the acts keep their slow build.

### Shop & donations (`ShopService`, client `Shop`)
A **SHOP** button sits on the right edge of the lobby screen. A gold "!" pulses on it until you open it. The panel has two tabs:

| Game pass | Price | What it does |
|---|---|---|
| Supporter | 10 R$ | A ★ SUPPORTER tag above you in the lobby, the Gold flashlight, and a star on the donation board |
| Flashlight colours | 15 R$ | Every invite colour, plus the Ghost beam |
| Rocket Launcher | 99 R$ | 2 rockets every night (v92) |
| Pick your role | 25 R$ | Choose Jamie, Riley, Morgan or Casey, and so your starting item (was 15 before roles had items) |
| Marathon | 20 R$ | Stamina drains 40% slower |
| Long-life battery | 25 R$ | Your flashlight battery lasts twice as long |
| Head start | 25 R$ | You start every night with a flashlight |
| Pepper spray | 35 R$ | You start every night with a can of pepper spray (one use) |

**Revive** (developer product, 10 R$, `ReviveService`; was 25 R$ and sold 0 of the first 35 deaths. The card reads the live price with `GetProductInfo`, so a regional price shows correctly): when you die, your result card (and the spectate view) offers REVIVE. Buying it puts you back on your feet in this night, on the ground floor or upstairs as far from him as possible, and he can't feel you for 10 s. Your slate is clean: the next catch zip-ties you again. In co-op you can revive any time while the night goes on; if you were the last one standing, the night waits 15 s ("The night ends in 15s") before it ends. A revive bought when it can't be used is saved and offered next time as USE REVIVE.

**Support** takes donations of 5, 10, 25, 50, 75, 100, 150, 250, 500 or 1000 R$ (developer products) and shows the top 10 supporters. The **donation board** on the front lawn of the lobby lists them too, and its DONATE prompt opens this tab.
- Each receipt is counted once: a DataStore key per purchase id, then a total in the `Donations_v1` OrderedDataStore.
- Everyone in the server sees a thank-you message.
- Ownership becomes `Pass_<Key>` player attributes, checked on join and set right after a purchase.
- Pass and product IDs go in `Config.Shop`. An ID of 0 shows the item as "Soon".

## 5. Level Layout — 14 Alder Lane

All coordinates are in studs. The front of the house faces −Z (toward the street).

```
                         BACK YARD (fenced)
  z=30 ┌──────────────────┬────────────┬──────────────────┐
       │ KITCHEN / DINING │  HALLWAY   │       DEN        │
       │  sink  stove     │  basement▼ │  couch  console  │
       │  island  table   │   door     ├──────┬───────────┤ z=4
  z=2  ├───────arch───────┤  stairs▲   │ BATH │ MUDROOM   ├─────────────┐
       │                  │ (x -8..-2) ├─door─┘ back hall │  GARAGE     │
       │  LIVING ROOM     │            │   DAD'S OFFICE   │  car        │
       │  TV couch fire   │   foyer    │   (locked)       │  breaker    │
  z=-30└──────────────────┴──front─────┴──────────────────┴──door───────┘
     x=-40              x=-8  door   x=12               x=40          x=66
                          PORCH · DRIVEWAY · STREET (z=-80)
                    Mrs. Okafor's house →  x≈95..130
```

- **Ground floor (y 1–14):** Living, Kitchen/Dining, Hallway/Foyer (main stairs up, basement door), Office (key-locked), Downstairs Bath (its door opens off the back hall, x≈15.6 on the z=−4 wall), Mudroom (door to garage), Den.
- **Stairs** are solid flights: each step is a painted body under an oak tread with a nosing, on a sloped stringer. Players walk an invisible ramp through the middle of the treads that meets both floors flush (no lip), and the top tread collides so the ramp joins the landing. The basement stairwell is an open hole through every slab (the foundation is only a ring round the footprint), boxed in by headers; floor-level trim stops at stairwells.
- **No flicker**: after the build, `World/Depth.luau` finds surfaces that sit in the same plane and face the same way (trim flush with walls, paint layers, window glass and frames, curtain folds) and pulls the smaller one out by 0.03 studs.
- **Scale**: player avatars are scaled up to about 6.1 studs, adult height for the house's 13-stud ceilings. Curtis is 9.9 studs standing (v99), about 9.3 walking hunched: a black jointed body and a porcelain grin (see The intruder).
- **Structure audit** (harness): every door and arch needs floor underfoot and open air on both sides; furniture may not intrude into doorways, stair ends or walls.
- **Upstairs (y 15–28):** Master Bedroom (+ en-suite), Jamie's Room, Upstairs Hall (attic hatch, linen wardrobe), Guest Room, Hall Bath (**cell signal at the window**), Lily's Room.
- **Basement (y −13–0):** open storage, under-stairs hiding nook, **Boiler Room** (captives). Unfinished and lived-in: exposed joists on a steel girder with lally columns, a sheet-metal duct, bare bulbs with pull cords, an old rec corner (sagging couch, tube TV, a sheeted ping-pong table and chair), stacked holiday tubs, the kids' bikes, a spare mattress against the wall, the sump pit, puddles, water stains and cobwebs.
- **Attic (y 29+):** plywood walkway over insulation to **the nest**: sleeping bag (with Lily's pink ribbon on the pillow), lantern, wrappers, a propped-up sheet of plywood with the polaroids and nineteen tally marks, a family photo with the parents' faces scratched out, the notebook, stolen keys.
- **Garage:** car, breaker panel, workbench (walkies, tape), manual release cord, ceiling hatch with stepladder (his route), side door. **Phone junction box on the outside wall**, with the phone line dropping to it from the street pole. Also an oil stain, spare tyres, the mower, rake, shovel and broom, an old fridge and the recycling bin.
- **Exterior:** rain, porch (pumpkins and mums on the steps), chimney smoke, driveway, street lamp, the gray van down the street, fenced back yard, Mrs. Okafor's lit porch, fallen leaves.
- **Alder Lane** (`src/server/World/Neighborhood.luau`): ten neighbours' houses line both sides of the street (one and two storeys, varied siding and roofs, garages, porches, chimneys, a few windows still lit), each with a front walk, a driveway, a mailbox, shrubs and sometimes a car. Telephone poles run along the north side with sagging wires. A bus stop, hydrants, street signs (ALDER LN, CREEK RD, SPEED LIMIT 25).
- **Creek Road** turns south at the west end and runs into the flood: dark water over the road and verges, ripples, branches caught at the edge, a barricade with blinking amber lights, a ROAD CLOSED / FLOODING sign and a stalled sedan up to its doors. It's why nobody is coming quickly.
- **The woods** behind the back fence: dense pines and oaks with undergrowth, fading into fog.

### Sight lines designed on purpose
- From the living room you can see down the hallway to the kitchen arch, the spot where he peeks in Act III.
- The upstairs hall railing overlooks the foyer.
- From the ground-floor windows you can see the side yard and the driveway, where the figure appears in Act II.
- The basement stairs are the single choke point for rescues. That makes "Locked In" possible, and makes rescues risky.

---

### Our own logs (`JourneyService`, client `Diagnostics`, `tools/pull_stats.py`)
Creator Hub's charts are slow and coarse, so the game also writes its own logs to DataStores the owner's read-only Open Cloud key can read:
- **Script errors** (v82+): each device's script errors (`ScriptContext.Error`, up to 5 different, with counts) ride along with its performance report (`Perf.Err`), and each game server's go on the night record (`SErr`); `pull_stats.py` lists the most common. (Before, a bug players hit in the real client was invisible to us.)
- **NightLog_v1**, one record per night: the acts and when they started, each objective step the group finished, help called (how), the ending; and per player: first night or not, nights before, role, device, captures (where), frees (friend or self), deaths, heartbeat minigame results, hides and sightings, ANOTHER NIGHT / LOBBY pressed, and **if they left mid-night: when, in which act, tied up / dead / hiding / free, his state and distance, their nerve**. Also nights nobody started (they left while arriving or voting).
- **LobbyLog_v1**: each lobby visit: brand new or not, nights played, level, came with a friend, how long they stayed, seconds until they first queued (and which circle), teleported.
- Every client reports its device (Phone / Tablet / PC / Console), memory, frame rate and graphics quality every 15 s: a quitter's last frame rate and peak memory show whether they crashed or gave up on lag.
- `python3 tools/pull_stats.py <dump.json>` prints it all: lobby conversion, quit points by act and state, first-nighters vs veterans, devices, objectives reached, plus the player records.

A night now counts the moment a player is out early (escaped, or caught twice while friends play on): it used to be counted only when the whole group's night ended, so anyone who left from their own result card never got the night, the escape, the coins' streak or the FirstNight badge.

### Analytics (`TelemetryService`)
Creator Hub → Analytics shows where players drop off. **Onboarding funnel** (first-time players): 1 Joined lobby, 2 Queued, 3 Arrived at the house, 4 Night started, 5 Act II, 6 Act III, 7 The hunt, 8 Saw an ending, 9 Second night. **Night funnel** (every night): Started, Act II, Act III, The hunt, Ending. **Custom events:** Ending (which), SecretEnding, QuitDuringNight (the act they left in), LevelUp. **Economy events:** every coin in and out, with the reason (Gameplay, TimedReward, IAP, Shop, Onboarding; admin coins aren't logged). All calls are wrapped: analytics can never break the game.

## 6. Technical Architecture

```
src/
├─ shared/            → ReplicatedStorage.Shared
│  ├─ Config          all tunables (timings, speeds, ranges)
│  ├─ Remotes         RemoteEvent registry (server creates, client waits)
│  ├─ Rooms           room volumes + lookup by position
│  ├─ Sounds          audio library (asset ids, fallbacks, captions)
│  ├─ Story           roles, documents, texts, chapter cards, endings, truths
│  └─ Util            helpers
├─ server/            → ServerScriptService.Server (bootstrap: init.server.luau)
│  ├─ World/          Builder (primitives), Layout (data), House, Interior, Exterior
│  ├─ Services/       Audio, Noise, Interaction, Doors, Power, Inventory, PlayerState,
│  │                  Hiding, Capture, Objectives, Phone, Escape, Chat, Ending
│  ├─ Director/       Director (acts, tension, beats), Events (event library)
│  └─ Intruder/       Intruder (rig, states), NavGrid (house survey + A*), Navigator (walking), Perception
└─ client/            → StarterPlayerScripts.Client (bootstrap: init.client.luau)
   └─ Controllers/    UI, Input (keyboard/gamepad/touch actions), MobileControls, Atmosphere
                      (rain, lightning, audio), Movement (+ flashlight aim), HUD, Prompts,
                      Documents, Phone, HidingCam, Effects (nerve), Lobby, Ending
```

### Principles
- **Server-authoritative.** Movement speed, stamina, noise, perception, inventory and all interactions (ProximityPrompts) live on the server. The client only sends *intents* (sprint, crouch, flashlight, use item, struggle, hold breath, phone call).
- **State replicates through attributes.** Per-player values (Role, Nerve, Stamina, Battery, Signal, Hiding, Captured, Escaped, items) are Player attributes, so late-joining clients and UIs read one source of truth.
- **Procedural world.** The house is built by code from `World/Layout` data. It's deterministic, reviewable in diffs, and can be rebuilt for a restart without reloading the server.
- **Context injection.** Every service gets `init(ctx)`. The bootstrap wires them, builds the world, then calls `start()`. No circular requires.
- **Restartable sessions.** After an ending, `ctx.restart()` resets every service and rebuilds the world.

### Performance
- Rain is emitted on the client from a few large particle volumes around the house. It never renders inside the house. Low ground mist (big faint smoke puffs) follows the camera outdoors; Atmosphere fog does the rest.
- Walls and floors carry tiled image textures (`World/Textures`): damask, striped and floral wallpaper tinted per room, dark hardwood and parquet, marble and white tile, carpet, a subway-tile backsplash.
- Every model is built from parts by `World/Kit` (sofas with soft cushions, turned table legs, drum lamps, shaker cabinets, fridge, range, toilets, beds, trees, cars, the delivery man...). Decorative parts never collide or block raycasts; each model adds one or two invisible colliders instead.
- The AI thinks at 10 Hz. Paths are recomputed only on goal change, when blocked, or every 1.5 s during a chase.
- Light fixtures use `Shadows` selectively. Parts are anchored with minimal collision geometry.

### Audio
`Shared/Sounds.luau` holds the library. The storm is loud on purpose: heavy rain outdoors, rain drumming on the windows indoors, and close thunder cracks after lightning (three variations; the lobby runs its own storm). Almost every sound uses a Roblox-licensed **ProSoundEffects** asset (usable in any experience); the few still marked `Id = ""` (clock tick, popcorn, dog, heartbeat) are captions-only until chosen. The game falls back to built-in engine sounds where one fits, and **always shows a caption** (`[Footsteps above you]`). That keeps the game playable and accessible before any audio is imported.

---

## 7. Building & running

1. Install [Rokit](https://github.com/rojo-rbx/rokit) (or Aftman) and run `rokit install` to get Rojo 7.4.4.
2. `rojo build -o HomeAlone.rbxlx` then open it in Roblox Studio. Or run `rojo serve` and connect with the Rojo plugin.
3. Game Settings: set **Max Players = 4**, enable **Spatial Voice** (optional) and **Studio Access to API Services** (not required).
4. Fill the empty `Id` fields in `src/shared/Sounds.luau` with audio from the Creator Store (rain loop, thunder, door creak, and so on).
5. Test: **Studio → Test → Clients and Servers → 2 players**. Set `Config.Debug = true` for fast acts and debug logging.

### Publishing
`rojo build -o HomeAlone.rbxl`, then upload it with the Open Cloud Place Publishing API
(`POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published`,
header `x-api-key`, body = the .rbxl as `application/octet-stream`). Before uploading, run
`python3 tools/place_flags.py HomeAlone.rbxl`: it sets `AssetService.AllowInsertFreeAssets`, which Rojo
can't write yet. The game needs that setting to load free Creator Store models for props
(`World/Props.luau`: the popcorn bowl, the broken plate, plates, mugs, the fruit bowl, pumpkins,
flowers and the kettle). Anything that fails to load keeps its hand-built version. Use `versionType=Saved` to upload
without making the version live.

### Tuning quick reference (`src/shared/Config.luau`)
- `TimeScale`: multiply all act durations (0.25 for fast test runs).
- `Acts`: min/max minutes per act.
- `Intruder.*`: speeds, sight ranges, chase limits, grab range.
- `Help.*`: police response timers.
