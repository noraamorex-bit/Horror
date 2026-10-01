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
Roles are dealt when the night starts. Each role has a personality blurb and one small perk, so every player has a reason to matter.

| Role | Character | Perk |
|---|---|---|
| Host | **Jamie Whitaker**, 17. It's their house. Responsible, but out of their depth. | Starts with the **house keys** (dad's locked office, the basement deadlock). Sees room names. |
| Tinkerer | **Riley Chen**, 17. Fixes things. Has always got a multitool. | Starts with a **multitool**. Repairs and frees captured friends twice as fast. |
| Runner | **Morgan Hale**, 16. Cross-country varsity. | More stamina, and sprinting is quieter. |
| Observer | **Casey Brooks**, 17. Notices everything. Nobody listens. | Hears sounds from farther away. Gets extra detail when examining clues. |

### The intruder — Curtis Vane
In game (`server/Intruder/Rig`, built from parts, no catalog dependency) he is a head and a half taller than you, starved thin and stooped: a long, torn black coat with the hood up, a strip of bare ribbed chest, and arms too long for his body, with bare grey forearms and fingers that hang past his knees, nails black. Under the hood is a cracked, grimy porcelain mask: tall hollow eyes sagging at the corners with soot running down from them, a pin of light deep in each, and a long black mouth hanging open mid-scream. Lank black hair hangs out of the hood. The clients animate him procedurally (`shared/CreaturePose`, `client/Controllers/Creature`): he runs bent almost double with his head craned up at you and his arms flailing, walks with long slow strides and his head cocked hard to one side, stands dead still and stares, and his head snaps round at random. Near him your flashlight stutters, lights flicker, and his running footfalls shake the screen.
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

### Music and sound
A quiet music box in the rain in the lobby ("Eerie Music Box", APM, volume 0.06); soft piano indoors in Act I; a driving chase track ("Dark Hunter", APM) when he is chasing someone near you, low dread ("Facing the Fear", APM) while he searches close by, both scaled by how close he is; and from Act II the house creaks somewhere near you every 20-50 s.

### Hanging out
The living-room sofa, both armchairs and the den sofa have seats: a **Sit** prompt puts you on the nearest free cushion (walking into them does nothing), jump to get up. Hiding or getting caught pulls you off the seat first.

### Night recap
The ending card adds a line under each player: how many times they hid, were spotted, got caught and freed a friend (or "never saw him coming").

### The secret ending: Case Closed
Ten clue documents are **evidence** (`Story.Evidence`): the warm mug, the invoice, Lily's drawing, the notebook, the polaroids, the footprints, the trash can, the wet shower, the empty key hook and the lanyard. Reading a new one shows "Evidence n / 10" to everyone. If the group has read at least 7 (`Story.EvidenceNeeded`) when the police arrive, SIRENS becomes **CASE CLOSED**: the kids have already worked out who he is.

### He's hiding, not haunting
Before the hunt, Curtis is trying not to be found. Anything he does in person (a door easing open, food gone from the fridge, the music box) can only happen where he actually is, and only when nobody can see him (`Where` on an event in `Director/Events.luau`). He doesn't knock on walls or throw chairs for effect. The one loud thing he does by accident: if you spot him, he bolts, and sometimes knocks a chair flying on the way. Walk right up to him in the dark and he shoves you to the floor and runs. Open a door he's standing behind and it gets yanked shut in your face (a few minutes apart at most). Door leaves never trap him: he pushes half-open doors wide and walks through them.

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
When he grabs you, your camera snaps onto his masked face, inches away and lunging closer, with a scream hit ("Eyes Scream Horror Hit", APM), a red flash and a hard shake. Then the hand over your mouth and the fade to black. He also breathes: a slow, heavy loop on him that you only hear from a few steps away, which is how you know he is right outside your hiding spot.

### Badges
`Config.Badges` holds one badge ID per ending plus FirstNight. Create the badges in Creator Hub, paste the IDs, and the ending awards them.

### Solo nights
Alone, Jamie expects the others any minute; 24 s in, Riley and Morgan text that the creek road flooded and they had to turn around ("stay dry, don't get murdered lol"). Friends' banter never plays solo.

### First impression, sharing and records
- **Loading screen** (`src/first/Loading.client.luau`, ReplicatedFirst): replaces Roblox's default. Rain streaks down a black screen, one warm window glows, and every few seconds a figure is standing in it. Title, a one-line hook, a gameplay tip and a progress bar; it fades out once the game has loaded.
- **Lobby menu:** a small, plain column in the top-left corner (dark glass, thin outline, white text): Play solo, Find players, Endings, Invite friends, Favorite. While you're queued, your queue status takes the play buttons' place. Play solo / Find players put you straight into a queue circle (FIND PLAYERS picks the group circle with the most people waiting, or the smallest when all are empty); walking into a circle still works.
- **Invite and favorite** (`client/Controllers/Social`): an INVITE FRIENDS and a FAVORITE button under the lobby title and on the ending screen; the favorite prompt also appears once, 8 s into the first ending of a session.
- **Saved records** (`Services/StatsService`, DataStore `PlayerStats_v1`): nights played, nights survived, and endings found. The lobby shows `NIGHTS · SURVIVED · ENDINGS x / y`; the ending card says NEW ENDING FOUND the first time you see one.
- **Endings collection:** an ENDINGS button in the lobby lists all six endings; found ones by name, the rest as ??? with a hint.
- **Survivors' board:** a lit sign beside the queue circles shows the top 10 players by nights survived (OrderedDataStore `NightsSurvived_v1`).
- Store page text: `docs/STORE_PAGE.md`.

### Act 0 — Lobby
Players land in the **lobby** (third-person camera): Alder Lane on a rainy, foggy night — the street, lawns and woods run on past the invisible walls and fade into thick fog, so the town never seems to end — in front of the Whitaker house (porch light on, two windows lit), with the neighbors, street lamps and the gray van at the curb. A welcome notice explains the one thing to do, with an OK button. Four **white outline circles** on the front patio queue **1, 2, 3 and 4 players**. Stand in a circle to queue and step off (or tap LEAVE) to cancel. When a circle is full it counts down (10 s, 3 s solo), reserves a private game server and teleports the group there together.

In the game server the group spawns in the living room and the night starts as soon as everyone has arrived (or after 30 s without stragglers). Roles are dealt then. After the ending, everyone is teleported back to the lobby.

How it works: one place serves both. Public servers run the lobby (`server/Lobby/LobbyServer`); reserved servers created by `TeleportService:ReserveServer` run the house (`shared/Mode`). Studio can't teleport, so a Studio test runs the house directly with the old in-house READY screen (`Config.ForceMode = "Lobby"` shows the lobby instead). To split them into two places later, set `Config.Lobby.GamePlaceId` / `LobbyPlaceId`. Because lobby and game share one place, **Server Size also caps the lobby**: set it higher than 4 (e.g. 20) so more people can gather; a game server only ever receives one group, and the game caps a night at 4.

### Onboarding: one notice, then your own thoughts
When the night starts each player sees **one notice** (who they are, their perk) with an **OK** button. Nothing else competes with it: the chapter card and everything after wait until it's dismissed, and the journal stays closed until the player opens it.

After that the character **thinks out loud** (`Story.Thoughts`, `client/Controllers/Thoughts`): big text, one line at a time, 5 seconds each. It points the way ("Mom left me a couple of things to do. It's in my journal." / "I'm starving. Mom keeps the pizza menu on the fridge."), reacts to strange events ("Footsteps... upstairs? But we're all down here."), and comments on first pickups, hiding and being captured. A line can carry a control tip that matches the device (keyboard, touch or gamepad). If nobody makes progress for 35 s, someone remembers the next task.

**Nothing talks over anything else.** Phone texts, toasts and the friends' banter wait until no thought line is on screen and no conversation is running, plus a short gap (`Config.Thoughts.QuietGap`); texts arrive at least 8 s apart. Only the instant "task done" tick skips the queue.

**The friends talk out loud.** They also react a few seconds after a scare if two of them are standing together ("WHAT was that?!" / "Kitchen. Something fell in the kitchen."), once per event, and they talk in the final act too. Friends in the house don't text each other — they speak, in the same dialogue box as the delivery man but in green, with no choices and without hiding the touch controls (`Story.Banter`, `Dialogue.say`). Each scene is cast from players standing together (Jamie takes the "Host" lines); with fewer than two people together it waits, and it never plays solo.

### Act I — "Friday Night" (4–7 min)
*Social and cozy, with something slightly off.*
- Only three short objectives (`Story.Tasks`) — this is a horror game, not a chore list:
  - **Order pizza:** find the menu on the fridge → call Tony's on the kitchen phone.
  - **Make popcorn:** take a bag from the kitchen cupboard → microwave it.
  - **Close the upstairs windows:** guest room, Lily's room (a storm is coming).
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
- The act ends when he has driven away.

### Act II — "Small Things" (5–8 min)
*Did you hear that?*
The Director plays low-intensity events. Each one needs conditions to be met, for example "every player is on the ground floor", "one player is alone near a window" or "nobody can see this door".
- Objective: **Lock up for the night** (back door, garage side door). After the footsteps upstairs, a second one appears: **Check upstairs** — walk up to the attic hatch.
- Footsteps upstairs, a door left ajar, the attic cord swinging, the lasagna gone, the wet shower, a silent phone call, Biscuit barking, the emergency alert on TV, the storm flickering the lights.
- **Loud, sudden noises** (each with a real cause in the truth log, each shakes the screen and costs nerve): a plate **smashes** in the empty kitchen (the shards stay on the floor), a heavy **thud in the ceiling** right above an upstairs player (dust rains down), someone **bangs on the window** next to a lone player, a door handle is **yanked** hard, a chair **crashes over** in an empty room.
- **The Window.** A lone player near a ground-floor window sees Curtis outside, lit for a moment by lightning. Nobody else sees it.
- Texts: Mrs. Okafor asks whether "your dad's friend" is still staying with them, because she saw a man at the side door on Tuesday.
- **Mom and the news.** A few seconds after the doors are locked, Mom texts: *turn on channel 7*, a man has been living inside houses in Hollis Creek. You **text back** from your phone (two reply choices; the phone shows the whole conversation as chat bubbles). A new objective appears: **Watch the news** (turn on the TV → channel 7 → watch the report). Sitting through ~8 s of the report in front of the screen completes it; your character reacts, the truth log notes it, and later Mom asks if you saw it (another reply). Act II can't end until the news has been watched (or a hard time limit passes).
- **The TV.** Every channel is a real broadcast on the screen: 7 News (BREAKING NEWS bar, suspect silhouette "MALE · 40s · 6'4\"", scrolling ticker, live clock), 11 Weather (radar, FLASH FLOOD WARNING), Ch 4's 1958 black-and-white film with subtitles, Ch 12 colour bars and NO SIGNAL, and the red Emergency Alert screen. The prompt names the channel you're on.

### Act III — "Someone Else" (6–9 min)
*This isn't the storm.*
- **The power dies**, and it's the main breaker, not the storm. Wi-Fi goes with it, so no more texts.
- **The landline is dead.** The car keys are gone. The attic hatch now opens.
- Curtis is now physically in the house. He **lurks**: he moves only while unobserved, watches from doorways, and walks away when someone spots him. Players get glimpses at the end of a hall or in a doorway. He does not attack yet.
- Objectives: call for help (phone box outside → tape → splice → call), find out what's in the attic, and (optional) get the power back on (flashlight → flip the main breaker).
- Environmental story: an open hatch in the garage ceiling with a stepladder under it, muddy size-12 prints, the contractor invoice in the office (Host key), Lily's drawing of "the ceiling man".
- **Discovery.** When someone reads Curtis's notebook in the attic nest, Act IV starts at once. Otherwise it starts when the act times out.

### Act IV — "The Guest" (until an ending, ~15–20 min)
*He knows you know.*
The intruder **hunts**. Objectives change to escape and survival:
- **Call 911.** Either splice the cut line at the junction box outside (electrical tape, 10 s) and use the landline, or find the one flickering bar of cell signal at the upstairs bathroom window and hold a 15-second call. Talking makes noise.
- **Reach Mrs. Okafor's house.** Knock, then survive 15 seconds on her porch in the rain until she opens the door.
- **Escape in the car.** The car keys are in the attic nest (or the spare set is in dad's locked office). The garage door needs power, or the loud manual release.
- **Lock him in the basement.** Lure him down and lock the basement door (house keys or the basement key from the mudroom). This buys time and changes the ending.
- **Free your friends.** Anyone captured is zip-tied in the boiler room. Friends can free them with a 5-second hold, faster with the multitool or scissors. A captive can struggle free alone, but slowly and loudly.

When help has been called, a police timer starts (150 s by phone, 120 s via neighbor, 60 s via car). Curtis panics: for about a minute he goes looking for the caller, then he tries to leave the house.

**Hard cap:** at 60 real minutes, "Dawn" ends the session. Another neighbor reported the van, and the police arrive anyway.

### Endings
| Ending | Condition |
|---|---|
| **Sirens** | The police arrive with at least one player free. Curtis is arrested near his van. |
| **Locked In** | The police arrive while Curtis is trapped in the basement. He is arrested in the house. |
| **Taillights** | Players drove out and brought help. |
| **Next Door** | Mrs. Okafor made the call. |
| **Gone Quiet** (bad) | Every player still in the house was captured before help was called. |
| **Dawn** | The session hit the 60-minute cap. |

Every ending shows each player's fate (Escaped / Safe / Rescued / Captured) and the **What Really Happened** timeline.

---

## 4. Core Mechanics

### Movement & stealth
- First-person camera, locked.
- Walk 10 · Crouch 5 (**C**) · Sprint 17 (**Shift**, uses stamina).
- **Footstep noise is calculated on the server** from real velocity: crouch 4, walk 16, sprint 38 studs.
- Noise is heard at ~55% range through floors.

### Noise system
Everything loud emits a noise event (position, radius, kind): doors, the microwave, knocking, breaking glass, phone calls, struggling, the manual garage release. The intruder hears events inside the radius and investigates. Interactions are designed around the trade-off between noise and speed.

### Light & darkness
- Every room has a switch. Lit rooms make players visible from much farther away, but they also make Curtis cautious before Act IV.
- **Flashlight** (**F**; two in the house, in different drawers or shelves every night: one is always downstairs). Its battery drains. You see farther, and you are **visible from across the house**.
- After the breaker is flipped, only flashlights, phone screens, the fireplace, Lily's battery nightlight and lightning light the house.

### Nerve (composure)
0–100 per player. It falls when you are alone in the dark, when you see the intruder, when you hear scary events and when a friend is caught. It recovers near friends and in light.

Low nerve causes heavy breathing (louder when crouched or hiding), camera tremor, a darkening vignette and faster stamina drain.

### Hiding
Wardrobes, closets, under beds, behind the shower curtain, under the basement stairs.
- Hiding switches to a fixed peek camera.
- Hold **Space** to hold your breath for up to 8 s. This matters when he's close.
- If Curtis **saw you hide**, he goes straight to that spot. Otherwise he checks nearby spots at random while searching. Lower nerve makes him more likely to find you.

### Capture & rescue
If Curtis grabs you, the screen fades and you wake zip-tied in the boiler room. He takes your pepper spray and car keys (the keys go back to his nest).
- **Rescue**: a friend holds the prompt for 5 s, or 2.5 s with the multitool.
- **Struggle**: mash **Space**. It's slow and noisy.
- Curtis comes back regularly to check on his captives.
- **One second chance only.** Getting caught a second time is fatal: a jumpscare, then you're out of the night and **spectate** your friends (tap to switch; with nobody left, the camera watches the house from the street). Your fate on the recap reads *Didn't make it*.

### The intruder AI (`src/server/Intruder`)
A state machine with perception:
- **Vision**: a 100° cone, raycast line of sight. Range depends on light: 80 studs lit, 22 dark, 110 if the target's flashlight is on. Crouching shortens it. Hidden players are invisible.
- **He always knows roughly where you are** (the hunt): every half second he feels where each player who isn't hiding is, and acts on where they were **3 s ago** (a bloodhound on your trail). Hiding makes the trail go cold; after you leave a hiding spot he can't feel you for **8 s**. Loud noises (sprinting, slammed doors, trying the exits) are felt immediately.
- **Hearing**: noise events, reduced across floors; a loud noise ends his break early.

| State | Behaviour |
|---|---|
| `Offstage` | Acts I–II. In the attic. The Director fakes his presence with real, logged events. |
| `Lurk` | After the blackout, for ~35 s before the hunt starts. Hidden most of the time. He picks a spot 14–38 studs from the loneliest player, in their line of sight but not where they're looking, and **stands there staring**. Once seen he holds the stare for a beat and slips away. Walk up to him and he shoves you and bolts. |
| `Prowl` | The hunt. A door slams and he **runs** (15 studs/s; you sprint at 17 for ~7 s) to where he feels the nearest player is, heavy footsteps thundering through the house. |
| `Chase` | He can see you: **18 studs/s, 22 lunging** in the last 10 studs, and he doesn't tire. Lose his sight for 2.5 s and he's back on your trail. |
| `Search` | His target hid. He goes to where he last felt them, stands and listens, then tears open up to **2 hiding spots** nearby (the one you're really in a bit more often; one he saw you use always first). |
| `CheckSpot` | Opens a spot. Saw you get in: caught. Otherwise 85% you're found, much less if you're holding your breath. |
| `Withdraw` | Gives up for now: walks off somewhere dark and stands there 22–34 s (half that once help is called). This is when you move. Seen within 30 studs, he comes anyway. |
| `Retreat` | After pepper spray or a capture. |
| `Trapped` | Locked in the basement. Tries to force the door (~90 s). |

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
Flashlight ×2, Walkie ×2, Pepper Spray (mom's purse, 2 uses), House Keys (Host), Multitool (Tinkerer), Car Keys (hook → attic nest; spare in office), Basement Key (mudroom), Electrical Tape (two rolls, random drawers each night), Fire Poker (breaks ground-floor windows, very loud), Scissors (bathroom).

### Controls
| Key | Touch (phone / tablet) | Gamepad | Action |
|---|---|---|---|
| E | Tap the prompt | X | Interact (press and hold the prompt for hold actions) |
| R | Tap the blue prompt | Y | Lock / unlock (doors), secondary actions |
| F | LIGHT | D-pad up | Flashlight |
| G | SPRAY | D-pad right | Pepper spray |
| C | CROUCH | B | Crouch toggle |
| Shift | SPRINT (toggle; turns off when you stop or run out of stamina) | L3 | Sprint |
| Tab | JOURNAL (top right) | D-pad left | Journal (objectives) |
| P | PHONE (top right) | D-pad down | Phone |
| Space | BREATH (hold) / STRUGGLE (mash) | A | Hold breath (hiding) / struggle (captured) |
| E | LEAVE | B | Leave a hiding spot |

**Mobile layout.** Roblox's own thumbstick (move), camera drag (look) and jump button stay. The action buttons sit in an arc around the jump button and change with context: exploring shows SPRINT, CROUCH, LIGHT and SPRAY (the last two only once you carry the item); hiding swaps them for a big BREATH button and LEAVE (drag anywhere to peek around); captured shows one big STRUGGLE button. Interactions use the standard Roblox ProximityPrompt, which only fires on a deliberate tap (dragging the camera across it does nothing). Phones get a lighter rain density, and panels (phone, documents) move off the right side so they never cover the buttons. Every touch button fires the same input action as its key, so there is one code path for all devices (`client/Controllers/Input` → `MobileControls`).

---

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
- **Scale**: player avatars are scaled up to about 6.1 studs, adult height for the house's 13-stud ceilings. Curtis is 7.2 studs, thin and stooped: a sack mask with hollow eyes, a worn black work jacket and dirty jeans.
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
│  └─ Intruder/       Intruder (rig, states), Navigator (pathfinding), Perception
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
