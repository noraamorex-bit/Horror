# someone lives in our attic. [HORROR] — project memory

Read this first, every session. It is the owner's standing instructions: what they want and how they
want it. It overrides habit and defaults. When something here and a later message disagree, the later
message wins — then update this file.

Design detail lives in `docs/GDD.md` (keep it current). Test notes in `tools/harness/README.md`.

---

## The owner, and the goal

- **You're in charge of the whole game.** The owner said so. Make the calls a good lead dev would make.
- The owner **plays on a phone (mobile)** and tests with friends. Judge every UI change at phone size:
  small, out of the way, nothing covering the middle of the screen, touch buttons tap-only (dragging the
  camera across a button must never press it).
- The owner posts reels on **Instagram** (several accounts) to bring players.
- **Goal: maximize players and engagement** ("a game that will get millions of visits"). Numbers so far:
  0 → 500 → 850 → 1.1k → 1.8k visits; **62 / 250 highly engaged players** (Roblox's 250-highly-engaged
  requirement for all-ages play). Reels are what brought the traffic.

## How the owner wants work done

- **Go all out.** Big, thorough passes. Don't stop at the minimum; keep going until it's genuinely done.
  ("I ask you to go all out and you use only 9% of usage.")
- **Don't ask permission.** "Assume what I would ask for and improve it… do what you think is right."
  Only stop to ask when it's truly the owner's decision.
- **Make no mistakes / perfection.** Fix any bug or anything visually off you run into along the way,
  even if it wasn't in the request. Test properly before calling it done.
- Big requests: work **in sections**, carefully.
- **After every game change: test → typecheck → build → publish to Roblox → commit → push.** Every time.
- Be honest about what couldn't be checked here (you can't hear audio or see the real Roblox client).
- Replies: short and direct. Captions short and simple ("shorter like the original ones").

## Hard rules (never break)

- **Never spend Robux.** Badges only from the free quota: `tools/mkbadge.sh <Key>` (checks the quota,
  `expectedCost=0`). Icons in `marketing/badges/`, names in `tools/badges.tsv`.
- **The full admin panel is only for the owner** — UserId **915496194** (`Config.Admins`), checked on the
  server for every command. **Admin panel pass (v106**, the owner: "a new gamepass for 249 Robux called
  admin panel… except maybe not the coins part and some other unfair stuff"): id 2044988494, 249 R$;
  buyers get the panel in a night without COINS/SHOP (no coins, candy, passes, paid gear, Become Him,
  saved credits) and no free revive; anything that changes the night only when everyone else in the
  server is a friend or has the pass; a night it's used on pays nothing and counts for nothing
  (`Admin.uncredited`: coins, quests, titles, badges, candy, nights, boards) and strangers can't
  match into it. Lobby: no panel for buyers.
- **The owner is left off all leaderboards.**
- **Revives are Robux only** (10 R$ product since 11 Oct; 25 R$ sold 0 of 35 deaths). No coin revive — it would kill Robux revive sales.
- Git: develop on the designated branch, `git push -u origin <branch>`. **No PRs unless asked.** No model
  names in commits/code. End commit messages with the Co-Authored-By / Claude-Session lines the session
  gives.

## Game decisions to keep (the owner asked for each of these)

**Lobby**
- Third-person, foggy (feels endless), minimal and monochrome. Quiet music.
- Menu on the left side, not the middle: PLAY SOLO, FIND PLAYERS, then only Endings, How to play,
  Settings. Everything else is a small **icon dock** on the right (Rewards, Store, Locker, Shop) with the
  coin balance. Don't add big buttons back.
- Queue circles: white **outline** only, spread out so labels don't overlap. **Every circle counts down
  10 s from the moment someone steps in, 3 s once full; at 0 it teleports whoever's on it** (the owner's
  rule; no START NOW, no waiting for players).
- Shop has a pulsing "!" to attract; donation board on the lawn.

**HUD / text**
- Monochrome, bold but smaller text on dark boxes. One message at a time — never several in a couple of
  seconds; lines must not arrive late or out of order.
- Onboarding: one notice with OK, then the character **thinks out loud** (big text, ~5 s each) to say
  what to do. Objective panel top-right ("OBJECTIVE"), multi-step tasks, "!" markers where to go.
- Roblox's standard ProximityPrompts for interactions.
- **PC is not a big phone (v104**, a player: "unnecessary mobile UI for pc"): with mouse and keyboard
  the HUD stays ~real size (`UI.rescale`; touch/console keep the big one), the heartbeat shows Q / E key
  caps, no "tap" wording. Look at layouts with `ui_dump.luau` + `tools/assets/ui_preview.mjs`.
- **Usable items are Roblox tools in the hotbar** (equip, click / tap to use; v94, the owner). **Our own
  hotbar since v109** (the owner: "only 3 items got in hotbar"; Roblox's shows 3 on a phone): client
  `Gear` draws a slot for every item, sized to fit; Roblox's backpack stays off.
  Touch buttons are only SPRINT and CROUCH (plus BREATH/LEAVE/STRUGGLE in context).
- Secret-ending HUD is one slim bar at the top (it was "way too big" before).

**Pacing / story**
- It's a horror game, not a chore simulator: few tasks, multi-step, no dead time. No "stay together"
  task that solo can't do.
- Friends speak in dialogue boxes (not texts), **out loud (v106: Roblox text-to-speech, client
  `Voices`, `Story.Voices`)**: the delivery man, friends' chatter, your picked lines, your thoughts
  (quieter). Voices setting in Settings. **Anyone in the conversation can answer the delivery man:
  the first click moves it on** (v106). Pizza delivery with two dialogue choices; delivery man is
  a normal Roblox avatar in a red pizza shirt, creepy not goofy.
- Mom texts about the news → phone chat with replies → "watch the news" task; the TV has a real news
  presenter with text-to-speech (no laugh track). TV voice only heard when you can see the TV.
- Endings: short cutscene + simple result card (no logs). Solo: escape/death ends it. Co-op: your own
  card with SPECTATE (spectating must work, also from the neighbour's after escaping — no bare rooms).
- Second capture = death. ANOTHER NIGHT button keeps a group together.

**The intruder (Curtis)**
- Genuinely scary creature; smart (Doors' "Figure"-style: hunts by sound and sight, charges, inspects
  hiding spots, heartbeat minigame). Players must **hide**.
- **Faster than your walk, slower than your sprint** (v102, the owner: "make him faster"; until v101 he
  was always under the walk speed): chase 12.5 / charge 12 (Hard 13.5 / 13), cap 14.5; you walk 10,
  sprint 17. Not too hard (owner worried about rage-quits); after a capture he leaves so friends get a
  rescue window.
- **You must be able to see him** (v102: "I can't even see the monster… because of how dark it is"):
  charcoal body, brighter face glow + a cold chest light, a faint outline/fill in the house (client
  Highlight, occluded, not in the lobby), and the dark house after the blackout is moonlit
  (Atmosphere OUTAGE_AMBIENT). Don't make him or the blackout pitch black again.
- **NIGHTMARE mode** (v103, the owner asked whether a much harder monster would sell more revives:
  forced difficulty would mostly add quits; an opt-in mode instead): a third vote box, locked until
  you've finished a night (the server checks too); Hard plus `Config.Difficulty.Nightmare.Intruder`
  on top (chase 15, still under your sprint 17; sharper senses, shorter breaks); **caught once =
  dead** (a revive is offered); **2x coins** (`Economy.Night.NightmareMultiplier`); title "Nightmare
  Survivor"; badge Nightmare 3428208981624377. Workspace `Difficulty` stays "Hard" so every Hard rule
  applies, plus `Nightmare` = true; the night log's Diff says "Nightmare".
- **The revive offer sits right under the death card's headline** (v103; it was at the bottom under
  the coins, off a phone's screen): big, green, pulsing, with why ("Your friends are still in there"
  / "Back on your feet, far from him"), the last one standing's countdown under it.
- **Unloopable (v104**, a player: "most loopable enemy in horror games"): his run speed stays under
  your sprint, but chasing you round something low (a table, a bed, the kitchen island; never a wall,
  never another floor) he pounces over it (`leapOver`/`leap`, 3 s apart); run dry and you're
  **winded** (no sprint until 35%: `Movement.WindedRecover`, red bar).
- **Surprises in the hunt (v104**, a player: "no surprise factor"): from a minute in, every 75-120 s
  he either waits in an empty hiding spot near someone (a creak at 15 studs, bursts out at 7.5) or
  appears behind someone alone (turn round: he screams and chases; don't: gone in 7 s). 0.7 s
  scream before he runs, so it's a scare, not a free catch.
- **Taser auto-hits up close** (`Taser.AutoRange` 26, in plain sight, wherever you point; aim cone 30°
  further out).
- Before the hunt he stays hidden — no pointless noises or knocked-over chairs in front of you.
- **He enters the house far from everyone** when the hunt starts (the owner: "why does he spawn
  upstairs. Spawn him far away").
- Never stuck on doors/walls (NavGrid survey + navigator).
- Footsteps clearly audible and louder the closer he is.
- **He talks (v106**, the owner: "make it scarier, like actually creepy"): his voice (TTS, slowed and
  pitched down, reverb; only heard near him, quieter through walls) during the hunt only
  (`Intruder.speak`, `Story.HisLines`): murmurs while he searches near you, "There you are." /
  "Found you.", "I can hear your heart." at your hiding spot, "Turn around." when he's behind you,
  "Come closer..." from a closet, "We're a family now." when he grabs you. Also **the mimic** (act
  II-III event: a friend's voice, or Mom's, calling you to the other floor) and **the mirror** (after
  brushing teeth the bathroom mirror steams up: "I WATCH YOU SLEEP").
- **Look (v99, the owner: "look at the Locust or Threshold games… their monster is actually creepy"):**
  a ~10-ft black jointed mannequin (ball joints, ribcage, long two-jointed fingers, pale nails), a
  long porcelain mask with big round sockets, pinprick pupils and a stretched toothy grin, wet black
  hair; played in **stop-motion** (12-18 poses/s); runs on all fours; head lolls 90°, now and then
  turns right round (`Rig`, `CreaturePose`, client `Creature`). The server sees from an invisible
  `Eyes` point at the old head height (7.8). He stands across the street in the lobby fog (Watcher).
  Previews: the creature studio in the scratchpad (`cstudio/run.sh <gaits> lit|dark`, film2).
  v100: tapered limbs, jointed fingers, a mouth that opens (gaping as he runs, screaming in the
  jumpscare); stills can hide parts (`hideParts`) and set joints (`joints`) in creature_frames2.
- **v112 look (the owner, at a 36% rating: "Reword the monster… proper animation… blender level"):**
  a sculpted, textured **skinned mesh** (`assets/Creature.rbxm`, Creator Store 17737124382: pale,
  skinless, the face and chest splitting into a vertical maw of teeth; 68 bones) replaces the
  mannequin's look (`Rig.skin`; the part figure stays as the invisible frame). **Smooth procedural
  animation** (`shared/SkinPose`, client `Creature`): blended gaits, all fours in the chase, feet
  planted by FK, the head following you, the maw tearing open in the scream/jumpscare. Needs
  **Rojo 7.5.1+**. Previews: `tools/creature/pose_dump.luau` + `skinview.mjs`; test `skin_test`.
  GDD "The creature, v112". Reels: film2 draws it from `tools/creature/skin_frames.luau` (reel 43 on).
- **v114 (the owner: the v112 monster was "a bit too much. Make it simpler but not that simple"):** the
  sculpted body and its animation stay, the gore goes: no colour map (`tools/creature/plain_skin.luau`:
  charcoal `Rig.SkinColor` + the normal map's sculpted detail), and he wears the **porcelain mask and wet
  hair** again (`Rig.MaskParts` / `Rig.maskLayout`: the part-built Head and what's welded to it, 1.2x,
  moved onto the new face by `Rig.MaskOffset`; the client turns the Neck joint so they ride the head
  bone, `Creature` applySkin). The chest maw only opens in the scream; his mouth is the mask's again.
  Reels: `tools/harness/mask_dump.luau` → `skin_frames.luau ... mask.json` (third argument).

**Audio**
- **v104** (a player: '"horror game" but almost no audio'): every sound file was measured
  (`tools/audio_audit.py`): many were mastered very quiet → per-sound `Gain` on top of any volume
  (`Sounds.volume`). Client `Dread`: eerie room tone in the dark house, a rumble + heartbeat as he
  gets close, noises off during the hunt. Still no music.
- Lots of small sounds (doors, items, sirens, jumpscares…). **Occasional** sudden loud stingers are
  wanted (the owner liked the door-yank scare) — rare only.
- **No loud music**: none at night start/end, no chase/tension music, no music in the secret ending.
- No coughing/grunting breath loop on the player (it sounded like someone saying "hello").
- The text-message buzz is one short quiet buzz (the 3 s one was "so loud, long and annoying").

**World**
- Warm, cozy, polished interior; real textures; models from anywhere (Creator Store/UGC) when they look
  better; no z-fighting, floating/sunken props, blocked doorways or 90° flipped props. Taller players.
- Rain sound and occasional thunder; fog outside.

**Retention (the 250 highly-engaged goal)**
- Every group circle at 0 first tries to join a group night that started short (MatchService; open through
  acts I-II until bedtime, up to 4 players). An arrow at the screen edge points to the current task when its "!" is off screen.
- Levels (XP = coins earned playing) with rewards at milestones; LV on the lobby tag, XP bar on the
  result card; tomorrow's daily reward shown at the end of every night.
- Analytics funnels (TelemetryService): check Creator Hub → Analytics → Funnels to find where new
  players quit, and fix that step first. **Our own logs** (JourneyService → NightLog_v1 / LobbyLog_v1)
  say exactly when, where and in what state each player left, with device and frame rate:
  `python3 tools/pull_stats.py <scratch>/dump.json --logs-only [--since=VERSION]` (logs carry the place
  version from v74). Read them before every big change.
- The hunt's main goal from the blackout is **Call 911** from the one bar of signal at the upstairs
  bathroom window (a prompt sits there); every other way out is listed as optional.
- The result card's countdown starts the next night with everyone still there (LOBBY to leave):
  half the players never touched the card and most left from the lobby. The welcome card's button
  is ▶ PLAY (into a group circle): abandonment falls with group size (solo 88%, 2: 31%, 3: 7%, 4: 0%).
- Night streak: another night within 15 min of the last pays +25% / +50%. Groups where everyone has
  finished a night can vote ⏩ SKIP TO THE BLACKOUT. 🔔 Remind me (notification opt-in) on the result
  card. Out early, you can already press ANOTHER NIGHT.
- **Don't rush the night** (owner: a 7-minute night was "too fast"; ~13 min is right; v86's 8-10 min nights were "way too short" and got reverted). Every night
  gets the full build-up. Act II events take turns: scares 35 s apart, Mom's texts only when nothing
  else is going on, the TV alert never during the news, a breather before the blackout.
- The heartbeat minigame must stay passable (logs: 0/22 passes before the fix); Normal is
  forgiving, Hard is tight.
- Chat: name tags ★ (supporter) and the equipped title in its colour; no level (the owner asked).
  Level and nights survived are in the server's player list (leaderstats; not for the owner).
- FASTEST WINS: skip-to-the-blackout nights never count, nor any win under 6:00 (`Config.MinBoardWin`);
  old entries like that are removed (the owner saw a 0:51).
- "Secret ending: found by N players" is one small line at the bottom of the NIGHTS SURVIVED board
  (the owner found a separate board "too much").

**Economy / monetization**
- Coins from playing (daily streak, quests, night pay); store with one-night gear (no revive), crates
  with cosmetics (beams, trails), Robux coin packs. Cheap passes starting at 10 R$; donations.
- **Titles are never in crates** (the owner asked): each is earned in the game (Attic Explorer =
  climb into the attic, Pizza Lover, Scaredy Cat, Survivor, Night Owl, Phrogger, The Quiet One,
  Legend of Alder Lane, levels). Old crate titles stay with whoever has them.
- Admin COINS tab (lobby + game) for the owner.
- **14 Oct (v89), the owner: "I want Robux, I need 1000 to make the game available to all ages."**
  The pepper spray pass (id 2006030307) is a **Taser** now (49 R$; owners keep it): 3 shots a night,
  aim with the camera (T / click / TASER button), a hit stuns him 4 s then slows him to 55% for 14 s;
  a yellow-and-black taser shows in your hand. **VIP** pass (2036510399, 99 R$): +50% coins, VIP tag,
  all colours, Marathon, endless battery. Supporter +20% coins; Marathon also regains breath 2x;
  Battery never runs out; Head start adds a pepper spray. **Become him** (dev product 3718593338,
  50 R$, bought again every night, co-op only): the buyer drives Curtis (MonsterService, the
  puppet): before the blackout it waits for the hunt; LUNGE / SEARCH; survivors' noises ping for
  them; a taser stuns them; survivors are told; it can't be used → saved as a free credit
  (MonsterCredits). Icons + `update_passes.sh` in `marketing/passes/`.

- **15 Oct (v92)**, the owner: 240/250 highly engaged, 300 of 1,000 R$: "capitalize more", roles
  were "so useless", "add a rocket launcher or something people will buy", everything in the admin
  panel. **Rocket Launcher** pass (2039534472, 99 R$: 2 rockets a night, knocked flat 7 s then slowed
  20 s; a miss is a big noise) and **Rocket (tonight)** product (3718739690, 15 R$ since v110, a button during
  the hunt). **Roles start with items** (Jamie flashlight+keys, Riley multitool+tape, Morgan 2 energy
  drinks, Casey 2 firecrackers that lure him); Pick your role 25 R$, in VIP. Sales logged in
  `Sales_v1` (pull_stats prints them). Admin SHOP tab. Head Start's description had been filtered ("pepper spray" gets hashed on the pass page).

- **18 Oct (v98)**, the owner: "I need more Robux." 291 R$ in three days (Rocket pass 99, Become Him 2x,
  Pick your role, donations, 2 revives of 74 deaths), falling; no data on how often anything was offered.
  Done: **funnel** (every purchase window: `Ask:<key>` in Sales_v1 + `Ask` in the night log; pull_stats
  prints bought / asked); **Starter Pack** (`Config.Shop.Starter`, 19 R$ once: 500 coins + a rocket + a
  revive; top of the SHOP and a small button on the result card); **live since v110**
  (product 3721088307, made through the API);
  **😈 BE HIM NEXT NIGHT** on a group's result card (bought now, used when the next night opens);
  the 🚀 button says **STOP HIM** and flashes while he chases you. Also fixed: Mom's texts (and her
  replies) wait until a scare is 4 s back (hunt_goal_test caught one landing 2 s after the music box).

- **21 Oct (v108)**, the owner: "Change the gamepass prices and add new ones… maximizing sales." ~8 of
  2,714 players owned a pass. Prices now: Supporter 10; Pick your role, Marathon, Battery, Colours 15;
  Head start 19; Silent Steps 29; Taser 39; 2x Coins 39; Night Vision 49; Rocket 79; VIP 99; Admin 249;
  Become Him 25 (was 50, 0 of 49 bought). New: **Night Vision** (2045276660: goggles, 60 s of green
  sight a night, offered for a minute after the blackout), **2x Coins** (2045798689: the night's pay
  doubled), **Silent Steps** (2044448668: half the footstep noise, 50% longer breath). GDD
  "Monetization (v108)".

- **25 Oct (v115)**, the owner (a screenshot of another game's "Jumpscare Everyone" for 19 R$): "Add
  something like this for 10 Robux". **Jumpscare Everyone** (developer product 3722081951, 10 R$,
  `Config.Shop.JumpscareAll`, icon `marketing/passes/jumpscare_all.png` from `make_jumpscare.py`): bought,
  it scares everyone else in the server at once, house or lobby (ShopService → Remotes.JumpscareAll →
  client `Prank`: black screen, his mask lunging at you in a ViewportFrame, jaw dropping, screech + hit,
  red flash, shake; then "😱 <name> jumpscared everyone!"; the buyer gets "You jumpscared N players").
  Bought from a small 😱 button under the inventory in the house and a 😱 SCARE dock icon in the lobby,
  only while someone else is in the server. Logged in Sales_v1 as JumpscareAll, night log event Prank.

**Secret ending "Down Here"** (2+ players, everyone zip-tied at once): the dinner (struggle while his back
is turned), he really leaves up the ladder for a while, signposted tunnels, notes give the cellar code,
alcoves to hide in, cellar hatch out. Endings Not Your Family / Forever Family.

## Marketing (Instagram reels)

- **WHAT THE NUMBERS SAY (23 Oct, the owner's screenshot; build every reel from this):**
  | reel | views | sends |
  |---|---|---|
  | #2 "you can't play alone" (`cant_play_alone_2.mp4`, 4 Oct, caption "he's still up there 👀") | **314K** | **26K** |
  | PEAK Part 1 (13 Oct) | 63K | 4.4K |
  | PEAK Part 5, "he was right outside the curtain" (15 Oct) | 24K | 2.7K |
  | PEAK Part 9, "he left you tied up down here" | 8.2K | 296 |
  | #N "never sleep over at jake's" (5 Oct) | 7.5K | 457 |
  | PEAK Part 7, candy trail | 5.4K | 236 |
  | PEAK "peak roblox horror game t..." (12 Oct) | 5.4K | 284 |
  | the gameplay series with HUDs and avatars (reels 36-41, 20-22 Oct) | under 5.4K each | |
  What won: **the game's own premise as a mystery told night by night** ("night 1: footsteps in the
  ceiling" → "night 4: the food goes missing" → "night 9: we found the hatch" → "someone's been sleeping up
  here" → "photos. of us." → "he's been counting the days." → "and tonight he's coming down."), the
  case-file card (TITLE / FEAR LEVEL 10/10 / SQUAD 1-4 / GOAL), a caption that implies he's still there
  (people send it to a friend: 8% send rate), real dread before one big scare, no HUD, no friends on screen.
  What didn't: other stories in the same format (jake's sleepover 7.5K), gameplay montages, HUDs, text
  overload, many small scares. **Rule: every new reel is a chapter of the attic mystery in #2's exact
  format (`comp_cantplay.mjs`, #2's slots and track), with a caption that leaves him still in the house.**
  Reel 42 = #11, its sequel: "he isn't up there anymore 👀". Reel 43 = #12 (`cant_play_alone_12.mp4`, 23 Oct):
  he's living in the house now (the TV on by itself, him at the top of the stairs, watching from the bedroom
  doorway, crawling down the upstairs hall, the lights out, behind the sofa: the maw tears open on the hit;
  RUN down the stairs), the **first reel with the v112 creature** (film2 draws the skinned mesh from
  `tools/creature/skin_frames.luau`, the game's own SkinPose). Caption: `he's not hiding anymore 👀 game in comments`.
- **Winning format: "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #N"** — orange, plain outlined captions,
  case-file card (FEAR LEVEL 10/10), escalating captions ("night 1… night 19… tonight he's coming down"),
  RUN. + flash, end card "SEARCH IT ON ROBLOX". #2 got **115k** views, #5 61k, #7 did well. #8: the secret
  ending. #9: the pizza man → the 911 call (`reel20`). Latest: **#10** (bedtime: brushing teeth, lights out, the hall
  closet, "don't breathe."; `reel_source/reel21`). Keep #2's slot lengths so the cuts and **the same music** land identically;
  change the story/clips each time.
- **Second format: "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 1)"** (reel23, built to match the
  owner's reference reel instagram.com/reel/Dd4Lknqg4hh as closely as possible): slow first-person
  handheld walk through dark rooms (porch in the rain → lights out → hall → him), the hook word by word
  in the middle (PEAK yellow, ROBLOX red, HORROR GAME white, TO PLAY WITH / FRIENDS green, "(Part 1)"),
  then a small three-line card at the top (NAME / GAMEPLAY 10.5/10 / GENRE Survival Horror) and one
  spaced line low ("OUT NOW"), a pixelated grey jumpscare, a stretched blue glitch line, a noise-block
  glitch into a black end card. Music: **dark phonk** (`reel23/audio.py`, 112 BPM, E Phrygian: distorted
  808, cowbell riff, choir, a half-beat gated drop on the scare). Tools: `comp_peak.mjs`.
  reel22's version (third person, upbeat 128 BPM track, name banner on top, `comp_gameplay.mjs`) was
  rejected: "not at all what I wanted", and the upbeat song "sounded Christmas, not horror". Keep music
  dark; when copying a reference, match it closely (watch it frame by frame first).
  **Part 2** (`reel24`, `peak_horror_game_friends_2.mp4`): the owner asked for this format with **#2's
  song**: the clips keep #2's slot lengths (105/120/72/33/90/60/60/60/75/30 + 180 end) so #2's track
  (`reel24/audio.py`, a copy of #10's) lands identically; hook words on the music-box notes, the card's
  lines pop with the track's four pops after the drop, the scare on #2's 22.15 s hit, the glitch on
  RUN. Story: hiding under the dining table, he drops in upside down. The renders now include the
  Creator Store furniture (film2 `spec.props`, world = a stage.json).
  **Part 3** (`reel25`, `peak_horror_game_friends_3.mp4`; the owner: Part 2 "did really well, more
  like that"): same format and #2's track, new story: hiding in the upstairs linen closet, watching
  him through the crack (film2 `door` rig swings one wardrobe leaf), he leans to the gap, backs off,
  then the door is torn open on the 22.15 s hit; RUN: he comes up the stairs. Glitch "he's listening".
  (film2 now renders twice after a light-rig change: the first frame of every shot came out dark.)
  **Part 4** (`reel26`, `peak_horror_game_friends_4.mp4`): same format and track; hiding under the
  master bed, the room seen through the slit between frame and floor: the bedroom door swings open
  (film2 `door` rig on the door), his legs cross the room to the bed, walk off round the side, and on
  the 22.15 s hit the bed is torn up off you (the rig tilts the whole bed around z: film2 rigs take
  axis x / y / z). Card shot: the living-room fire; the far shot: him on the front lawn in a
  lightning flash, from the bedroom window. RUN: him coming down the stairs. Glitch "he can hear you"
  (longer lines run off the screen).
  **Part 5** (`reel27`, `peak_horror_game_friends_5.mp4`): the game's own big moment: the bathroom
  window with the one bar (rain on the glass), him at the bottom of the stairs in a lightning flash,
  hiding in the shower: his shape and glowing mask through the curtain (film2 `translucent` parts
  per shot), the curtain ripped open on the hit (curtain rig), RUN: he bursts out of the bathroom
  after you. Glitch "stay quiet".
  **Part 6** (`reel28`, `peak_horror_game_friends_6.mp4`): the game's name, the attic: the hatch open
  with the ladder down (film2 `door` rig on HatchPanel, axis x; ladder + boxes as `extras`), the climb
  looking up through the hole, his nest in his lantern's light (sleeping bag, bottles), the tally
  marks, his photos of the family and the scratched portrait, his head rising through the hatch,
  hiding behind a box while he goes to his photo wall, the lunge on the hit, RUN: he slides down
  the ladder after you. Glitch "don't go up". (He's taller than the attic's roof ties: stand him
  between them, x = -36 + 3.79n.)
  **Part 7** (`reel29`, `peak_horror_game_friends_7.mp4`): Halloween (the v96 event): the front walk
  of glowing jack-o'-lanterns, the candy hunt (a candy in the dark hall, taken: film2 `hideExtras`),
  a jack-o'-lantern on the top step and a trail of candy up the stairs, his legs in its glow, the
  tilt up to his mask (he looks down at you), the lunge on the hit, RUN: he comes down the stairs.
  Glitch "trick or treat". Pumpkin + candies are film2 `extras`; the world is a Halloween stage dump.
  **Part 8** (`reel30`, `peak_horror_game_friends_8.mp4`): the secret ending's family dinner under
  the house: zip-tied at his candlelit table, two friends (film2 `avatars`, seated pose, scared
  faces) across from you, him at the camping stove with his back turned, he turns and watches,
  walks round behind your friends and leans in over one, the struggle (shaky view), the stove's
  empty... he's beside you on the hit; RUN: out the dining-room door (rig on DiningDoor). Glitch
  "don't move". Place cards hidden (their names are SurfaceGui text, which film2 can't draw).
  **Part 9** (`reel31`, `peak_horror_game_friends_9.mp4`): the boiler room (what a capture is): you
  and a friend (avatar, arms behind, turned towards you) zip-tied to the pipes; the door opens, him
  in the doorway, he goes; you struggle free, the friend shakes their head; hide at the boiler's back
  corner; he comes back round past the water heater to your empty pipe, his head turns to the
  boiler... and he's at you on the hit; RUN out the door. Glitch "he heard that". (The boiler's
  burner faces +x: light our side of the room too or its back is a black block.)
  **Part 10** (`reel32`, `peak_horror_game_friends_10.mp4`): the garage: the red car under a dim
  bulb, the car keys on the pegboard (extras), the door from the house creaks open (rig on its
  Panel/Inset/Knob), crouched behind the car's trunk while he walks down its far side, bends to look
  in the back window, his head turns to the back of the car... he's round the corner on the hit; RUN
  out the side door. Glitch "he's in here". (The sedan is solid inside: no shots from its seats.)
- **The gameplay series** (`reel36`, `peak_gameplay_part1.mp4`, 20 Oct; the owner: the peak format "was
  better. But I don't want this whole story thing… I want gameplay… scenes like hiding, monster finding
  you, chasing you, scary jumpscare", "call it part 1"): the PEAK format numbered from (Part 1) again, on
  #2's track and slot lengths, no story text; a night as you'd play it, first person with two friend
  avatars (Riley blue, Jamie green): the living room → he's by the fireplace, they bolt → the chase up the
  stairs → the linen closet → Riley grabbed and dragged off ("Riley was caught!") → he folds down to the
  crack (the heartbeat minigame, "He's moving away...") → the doors torn open on 22.15 s → RUN. comp_peak
  now draws the **game's HUD** from `fr.hud` (objective, hotbar flashlight/taser, sprint bar, chat with
  the friends, notice, heartbeat lane), the **brand** (red tag every clip, name under it on the hook,
  the search-bar end card; `text.brand`, default on) and a stronger scare (`scareI`: 3 pixelated frames,
  then the real frame punched in, shaking, red flash). Fonts now from `marketing/fonts` (Outfit added).
  **Part 2** (`reel37`, `peak_gameplay_part2.mp4`, 21 Oct; the owner: "Make the next reel. I want it to be
  perfect."): same format and track; the 911 call at the bathroom window (call bar), a lightning flash:
  him standing on the garage roof right outside the glass (the roof is 3 studs under the sill) → the
  call goes through ("Police: 2:00" counting under the objective), running footsteps, the door bursts
  open, "[A voice, close] There you are." → he charges, the taser (held bottom right, mirrored; the bolt
  drawn to where he is on screen, projected from the shot's camera in edit.py) → into the shower (the
  translucent curtain) → Riley runs for it, "Riley was caught!" → boiler room: Riley zip-tied, the
  "Cut free" ProximityPrompt filling → "We're a family now." → turn round to the doorway → the lunge on
  22.15 s → RUN, glitch "he heard the call". comp_peak gained: `meter`, `cap`, `police`, `cnt`,
  `prompt`, per-frame `vm` and `zap` (header). Lightning seen through a window: a spotlight outside
  (`flash`) + a sky colour (`bg`), not film2's `lightning` (it lights the room). His face glow
  (`glow`) lights ceilings/floors near him: keep it low (0.5-2) when he's near a surface.
  Caption: `he heard the call game in comments` + the hashtags.
  **Part 3** (`reel38`, `peak_gameplay_part3.mp4`, 21 Oct; the owner on Part 2: "too much text… reduce
  text, increase gameplay and scares. Try using actual Roblox characters instead of your blocky thing"):
  **real Roblox avatars** in Roblox's own catalog items (film2 `avatar_rbx.js` + `avatar_items.luau`: the
  classic shirt/pants templates mapped onto the R15 block body, the classic head with real face decals
  (Smile, ZOMG, Uh Oh, :-o), real hair meshes on their attachments; spec avatar `rbx: { cache, skin,
  shirt, pants, faces, hats }`, per-frame `face`): Riley = Pal Hair (bacon hair) + Blue and Black
  Motorcycle Shirt + Black Jeans, yellow skin; Jamie = Orange Beanie with Black Hair + Denim Jacket with
  White Hoodie + Black Jeans with White Shoes. **Text cut to the hook, the tag + NAME line
  (`cardLines: 1`), the glitch line and the end card; HUD only the hotbar and the stamina bar.**
  **Four scares**: he climbs onto the kitchen island and pounces (comp_peak `jolt`: punched in, shaking,
  red flash, a hit + screech in audio.py), he grabs Riley in the front hall, he takes Jamie while you
  hide under the master bed (seen through the slit: his legs, Jamie lifted away kicking, the dropped
  flashlight), the turn-round lunge on 22.15 s; RUN. Glitch "he saw you". Portrait frames: friends
  10-15 studs away and fov ~70, or they fill the frame; his face glow near a ceiling makes a halo
  (glow 0.25 there). `reel38/probe.sh <frames>` renders single frames at full size.
  **Part 4** (`reel39`, `peak_gameplay_part4.mp4`, 21 Oct): same style as Part 3 (real avatars, little
  text). The upstairs hall → Jamie opens the linen closet, he's folded up inside and bursts out (jolt) →
  the chase down the hall, Riley and Jamie dive aside → **the ROCKET LAUNCHER** (the pass in action:
  comp_peak `vm: {item: 'rocket', kick, loaded}` on your shoulder, `rocket: {from, to, k}` trail projected
  to him, `boom: {at, k}`; film2 per-frame `burst` light paints the hall orange) → he's down; into Lily's
  play tent → through the flap: Riley crouched by the tea chair, he comes in and lifts Riley away (jolt)
  → he comes back, folds down to the flap, his face at the gap on 22.15 s → RUN. Glitch "he came back".
  Hotbar text.items flashlight + rocket. Caption: `he came back game in comments` + the hashtags.
  **Part 5** (`reel40`, `peak_gameplay_part5.mp4`, 22 Oct): **Become Him** (the 25 R$ product, the one that
  sells: 4 of 76): you play him, the camera behind him up under the ceiling (a 10-ft body indoors), his
  vision (the game's MonsterVision: comp_peak `fr.mv`, desaturated first so the tint reads red-grey, not
  purple), the YOU ARE HIM bar + LUNGE / SEARCH buttons (`hud.mon {caught, lunge, search}`) and red pings
  where a noise came from (`fr.pings`, projected in edit.py). Upstairs hall: Riley and Jamie ahead, Riley's
  flashlight swings onto him, they split; the lunge (jolt) → after Riley into the bathroom, the shower
  curtain pulled shut → a ping behind it → the curtain ripped open (jolt), Riley lifted kicking ("caught
  1") → out in the hall the linen closet door eases shut, a ping → Jamie's eyes in the closet: he folds
  down to the crack, backs off, the doors torn open on 22.15 s → RUN. Glitch "you are him". film2 `hide`
  takes `{names, near: [x, z], r}` (the bathroom door hidden, not every Panel). Caption: `you are him
  game in comments` + the hashtags.
  **Part 6** (`reel41`, `peak_gameplay_part6.mp4`, 22 Oct): the garage and **the TASER** (the 39 R$ pass): Riley
  and Jamie at the side door, the door from the house swings open behind you, him in the doorway, he comes on
  all fours (jolt) → the taser (comp_peak `vm` + `zap`, the slot's count 3 → 2), he goes down in the rig's
  `Stunned` gait, his head turns right round → he gets up and goes over the car (an arc of Chase poses
  in stop-motion steps) onto Riley (jolt) → Riley carried off → into the storage cabinet (rig on its left
  WardrobeLeaf, hinge z -16.1; the eye right behind the gap at z -18.7) → the heartbeat lane while he
  stands at it; his mask fills the crack (`Stare` with `duck` 3.4 and neck [0.9, 0, -0.4], ~5 studs out:
  the `Peek` gait leans him sideways out of a crack's view) → the doors torn open on 22.15 s → RUN.
  Glitch "he got back up". Caption: `he got back up game in comments` + the hashtags. (In the garage keep
  cameras off the workbench: x 61.6..65, z -27..-16.)
- **Third format: the "story" reel** (`reel33`, `someone_lives_story_1.mp4`, 19 Oct; the owner: "different
  style now (same sound but better writing)", not Part 11): a first-person story in short typed lines
  over found footage, on **#2's track and slot lengths**. Lowercase serif captions (Libre Baskerville)
  typed in the lower middle with one word in red, a soft dark backdrop; a camcorder overlay (● REC,
  "OCT 31 2026", a running clock, PLAY ▶ for the first second, scanlines, colour bleed); the scare as a
  negative flash into a shaking red frame; "RUN." huge and red; a black end card ("someone lives in our
  attic." / "search it on roblox."). The writing: "my sister kept saying / someone lives in our attic."
  (chunks on the music-box notes) → "we laughed at her. / every night." (on the drop's pops) → "then the
  power went out." → "those aren't ours." (his footprints) → "that's not a man." → "and it heard me."
  (his head turns right round) → "so i hid." → "i didn't breathe." → "it stopped." → the doors torn
  open on 22.15 s → "RUN." (up the stairs on all fours). Tools: `comp_story.mjs`; store art from the same
  renders: `reel33/stills.py icon|thumb` → `marketing/attic/icon_v99_*.png`, `thumbnail_v99_1920.png`.
  **Story #2** (`reel34`, `someone_lives_story_2.mp4`, 20 Oct): same format, branded, the v102 creature
  (his mouth opens; visible in the moonlit dark). "something has been / eating our food." → the fridge
  door swings open (film2 rig on the left leaf; its insides are `extras`, hidden while shut with
  `hideExtras`): "mom's lasagna was gone. / licked clean." → "the back door was open." (rig on its
  Panel) → "it never left." (wet prints between the island and the table) → "it stood in the dark."
  (living room) → "and it smiled." (close-up, the jaw opening in stop-motion) → "so i hid." (behind the
  living-room curtain, the hiding spot's view) → "it could smell me." (he creeps across the gap) →
  "i held my breath." (he leans down to the gap, reel 33's pitch trick; the curtain torn away on the
  22.15 s hit) → RUN. down the front hall.
  **Story #3** (`reel35`, `someone_lives_story_3.mp4`, 20 Oct): Lily's room (the v101 tea party):
  "my little sister / set a place for a guest." → "we thought he was / imaginary." (the empty chair)
  → "her music box opened." (rig on MusicBoxLid, axis x) → "the door creaked." (her door's rig) →
  "he came for tea." (him folded on the floor at her tea table: film2 `joints` with a Root
  translation, `[rx,ry,rz,tx,ty,tz]`) → "and he saw me." (head turns, mouth opens) → "so i hid in her
  tent." (the camera at the tipi's flap, two canvas `extras` framing it: the store tipi is one-sided)
  → "he knew i was there." → "don't. move." (his face folds down into the flap: from a flap at
  eye height 1.75 he stands ~10.5 studs out, pitch -1.36) → RUN. into the upstairs hall.
- **Every reel says plainly it's a new Roblox game, with the name** (19 Oct, the owner: the story
  reel "is barely advertising a new Roblox game to play… make sure people clearly see that"): a red
  **NEW ROBLOX HORROR GAME** tag + the name on screen from the first frame to the last clip, and an
  end card with the name big, "SEARCH IT ON ROBLOX" and a search bar typing the name, "FREE · 1-4
  PLAYERS · WITH FRIENDS" (`comp_story.mjs` `text.brand`, on by default). Reel 33 rebranded:
  `someone_lives_story_1_branded.mp4`. Do the same in any new format.
- Reels that show little of the game didn't work ("the goal is to maximize players"). Don't copy other
  creators' reels; vary colours; avoid AI-looking purple.
- **Caption format:**
  ```
  <short hook> game in comments

  #roblox #robloxhorror #horror #fyp
  ```
  **Pinned comment:** `someone lives in our attic. [HORROR]`
- **The beat** is original (synthesized in code, no samples): "someone lives in our attic". Viewers ask
  for it — `marketing/beat/` has the 64 s MP3/WAV and a video to post it as Instagram audio (rename the
  audio to the game's name).

## Where we left off (update this at the end of every session)

- **25 Oct (v115 = place version 114, reel 44)**, the owner: "Add something like this [Jumpscare Everyone]
  for 10 Robux or smth. Also make next reel." Done: Jumpscare Everyone (see Economy, v115). Reel 44 = #13
  (`cant_play_alone_13.mp4`): the first reel with the v114 masked creature (see Marketing). SkinPose got a
  `Sit` gait (reels only). Can't see the real client: check the scare on a phone (the mask fills the
  screen, the banner reads) and that the 😱 button doesn't crowd the left column. Next: `pull_stats.py`
  `== SALES` JumpscareAll bought / asked; reel 45 = #14.

- **24 Oct (v114 = place version 113)**, the owner: the new monster is "a bit too much. Make it simpler but
  not that simple." Done: the body without its bloody colour map (charcoal + sculpted normal detail), the
  porcelain mask and hair back on his head, the chest maw only in the scream (see The intruder, v114).
  Can't see the real client: check on a phone that the mask sits on his face (not floating or inside the
  head) while he walks, runs on all fours and turns his head, and that the body reads charcoal, not
  black. Reel 43 still shows the v112 look (rendered before this change).

- **23 Oct (v113 = place version 112)**, the owner (screenshot: First Night badge won yesterday 67, "300 at
  one point. Do better."). The badge follows traffic × conversion. Daily lobby visits 981 (12 Oct) → 377
  (22 Oct); first-nighters who finished: 22% on 21 Oct → 14% on 22 Oct (the v110 prompt regression, fixed
  in v111). By place version, first-nighters who finished: 104 70%, 108 47%, 109 52%, 110 75% (n=20).
  **Solo is the leak**: group first nights finish 55-83%, solo ~11% (114 solo player-nights on 108-110,
  60 left within 60 s); 20 of 38 lone quitters went straight back to the lobby (half then played a group
  night): they wanted players. Done: alone in an open night the HUD reads like matchmaking ("Finding
  players... 0:23 · N in the lobby": lobby servers pulse their head count into MemoryStore
  `LobbyPulse_v1`, MatchService `LobbyNow`), the notice at 7 s (was 14) says anyone who presses PLAY
  lands here; **footsteps cross the ceiling ~20 s in** (`Director.ceilingSteps`, `Config.Director.CeilingSteps`;
  the first minute had nothing in it). Next: `--since=112`: solo early quits (want well under 60 of 114),
  first-night finish rate by size; reel 44 = #13, the next chapter (film2 now draws the new creature: frames from `tools/creature/skin_frames.luau`).

- **23 Oct (v112 = place version 111)**, the owner: "36% rating right now. Seriously improve the build, map,
  monster, jumpscare and everything… high tier blender level work… perfect cutscenes." Done: the skinned
  creature + smooth procedural animation (see The intruder, v112), the jumpscare on his maw, cutscenes shot
  like a film (lens, handheld drift, autofocus DOF, grade, per-shot sound/scream; He comes down = 3 shots).
  Can't see the real client here: check on a phone that he loads (not the old mannequin), stands on the
  floor, his gallop reads, the head-follow isn't silly, the jumpscare framing, and his frame rate. Next:
  `--since=111`: rating trend, quits right after first seeing him, phone fps with him on screen; move
  film2 (reels/store art) to the new creature; the house lighting pass (not done this round).

- **23 Oct (v111 = place version 110, reel 42)**, the owner: "Game statistics have dropped and also the reel views…
  construct much better reels… elite game design." Reels: see Marketing, WHAT THE NUMBERS SAY (#2's
  attic-mystery format is the only big winner; the HUD gameplay series flopped). Reel 42 = #11 in #2's exact
  format, its sequel: `cant_play_alone_11.mp4`, caption `he isn't up there anymore 👀 game in comments`.
  Logs since 109 (~1 day: 197 lobby visits, 71 nights, 11.6k visits, 18 up / 29 down): first-nighters quit
  mid-night 44% (was 54%); 33 of 48 of those quits in act I, 21 of 45 act I quits in the first 30 s; solo
  nights 90% no ending, 15 of 34 lone players gone within 26 s (new, queued for "2 players", landed alone);
  **v110 regression: time to the first task doubled** (the menu's prompt didn't reach the new spawn). Sales
  610 R$ total: Become Him 6/83 (the earner), nothing else since v108. Done: menu/note reach 10 + test; the
  short-circle line in the lobby. Next: `--since=110`: time to OrderPizza:Menu (want back to ~12 s), act I
  quits in the first 30 s, solo arrivals' quit times; reel 43 = #12, the next chapter of the attic story.

- **22 Oct (v110 = place version 109)**, the owner: "Analyze all game statistics and improve the game… gamepass
  prices and purchases." Logs since 106 (241 nights, 560 lobby visits, 11.2k visits, 18 up / 26 down):
  first-nighters quit mid-night 54% (v104 27%), act I quits in the first minute 22% of players (was 8%),
  phones 68%; 65 of 123 act I quitters never found the menu on the fridge (phones median 55 s to it);
  20 left while loading. Sales 560 R$: Become Him 4/76 at 25 (keep), revive 3/11, Pick your role 0/18,
  Rocket (tonight) 0/10 at 25; no pass sold since v108 (passes are only in the lobby shop; median lobby
  visit 28 s). Done: spawn in the kitchen facing the fridge, the night waits for every client (12 s max),
  the intro hands the camera over facing forward; Starter Pack live (19 R$), Rocket (tonight) 15 R$, a
  2x Coins offer on the result card. Other prices kept (too few sales to tell). Next: `--since=109`:
  first-step time on phones, act I quits in the first minute, Ask/bought for Starter, DoubleCoins, RocketNight.

- **22 Oct (reels 40-41)**: the gameplay series Part 5 (Become Him) and Part 6 (the garage, the taser, the
  heartbeat at the cabinet; see Marketing). Next reel: Part 7 (ideas: the secret ending's dinner with real
  avatars, Night Vision in the dark house, the 911 call at the window with friends, NIGHTMARE mode).

- **21 Oct (reels 38-39)**: the gameplay series Parts 3 and 4 with real Roblox avatars, little text,
  several scares; Part 4 shows the rocket launcher pass (see Marketing). Next reel: Part 5 in the same
  style (ideas: the taser up close, the shower, Become Him from his side, the heartbeat minigame, the
  secret ending's dinner with real avatars).

- **21 Oct (v109 = place version 108)**, the owner: "only 3 items got in hot bar and rest sit in
  inventory. Increase hot bar size." Roblox's hotbar can't show more than 3 on a phone, so it's
  replaced by our own (see HUD; GDD "Our own hotbar"). Can't see the real client here: check on a
  phone that all slots show, the taps equip, and nothing overlaps the thumbstick / jump button.

- **21 Oct (v108 = place version 107)**: the pass prices + three new passes (see Economy, v108). Can't
  see the green grade in the real client here: check that Night Vision reads well (not too bright) on
  a phone. Next: `pull_stats.py` `== SALES` bought / asked for NightVision, DoubleCoins, Silent and
  the cheaper tiers; keep the prices that sell more R$ in total, not more units.

- **21 Oct (v107 = place version 106)**, the owner: "Deeply analyze game statistics and improve the game." Logs v104-v105
  (94 nights, 238 lobby visits): brand-new players queued 93% but only 71% got teleported (37 of 168
  stepped off the ring on a phone or waited on a hung MatchService lookup); new solo players waited
  ~20 s (countdown + a vote with nothing to choose) and 14 of 25 act I quits were in the first 30 s;
  phones reached the first task in 47 s (PC 19 s), phones quit mid-night 53% (PC 12%), solo nights
  81% no ending; sales: Become Him opened 49 times, bought 0 (50 R$), Pick your role 0/18, revive 2/8;
  joins in progress are rare because traffic is low (not a bug). HallBath captures fell after v105
  (26 of 57 → 2 of 12, small sample). Done: sticky queue + lookup timeout + teleport retry (lobby),
  no countdown/vote for first nights, the first task before the journal (GDD "From PLAY to the first
  task, fast"), a light mode for slow devices (thinner rain/mist, no dust under 28 fps for 4 s;
  logged as Perf.Low). **Published as place version 106** (logs say 106). Become Him went to 25 R$ in
  v108. Next: `--since=106`: "queued but never sent" and its Off/TpFail/MatchSlow, act I quits in the first 30 s,
  phone time to OrderPizza:Menu.

- **21 Oct (reel 37)**: the gameplay series Part 2 (see Marketing). Next reel: Part 3 (ideas: the
  mimic calling you upstairs, the mirror "I WATCH YOU SLEEP", hiding under a bed while he says "I can
  hear you breathing", the rocket launcher, Become Him from his side).

- **21 Oct (v106)**, the owner: "Remove that npc thing. Add a new gamepass for 249 Robux called admin
  panel… let both players chat with the guy… text to speech to almost everything… Make it scarier."
  Done: the v105 NPC friend removed; anyone can answer a dialogue; the Admin panel pass (see Hard
  rules); TTS voices + a Voices setting; his voice lines, the mimic, the mirror (see The intruder).
  Can't hear the voices here (TTS only runs in the real client): check the volumes and that his
  voice reads as creepy, not silly. **Published as place version 105** (the v105 work was never
  published on its own, so "v106" in these notes = place version 105 in the logs). Next: `--since=105`: AdminPanel events / pass sales, quits right
  after the mimic, captures after his lines.

- **21 Oct (v105, unpublished; went live inside place version 105 with v106)**, "improve the game further", from the v104 logs (67 nights): (1) solo nights 13 of 15
  abandoned → an NPC friend for nights alone was built, then **removed at the owner's request**
  ("Remove that npc thing"): don't add NPC companions; (2) 23 of 45 captures in the upstairs bathroom after
  the 911 call → the whole group at the window gets the head start + a linen cupboard there;
  (3) live nav logged ~32 failed routes/night (0 in the sim) → routes to a goal he can't stand on end as
  near as he can get, and failures are logged by kind and room (`FailGrid_<Room>`, pull_stats);
  (4) surprises sooner (35 s, every 55-90 s). MatchService: 0 of 114 joined a night in progress, but
  traffic is so low that overlaps are rare (couldn't read MemoryStore: the key lacks the scope).
  Next: `--since=105`: bathroom captures, failed routes by room, surprised/player.

- **20 Oct (v104)**, the owner forwarded a review: "Unpolished, unnecessary mobile UI for pc players,
  most loopable enemy in horror games, no surprise factor to scare you, 'horror game' but almost no
  audio for it." → "Improve the game." Done: audio gains + Dread, the leap + winded, the two hunt
  surprises, the PC layout (see the sections above; GDD "The dark house", "Surprises during the
  hunt", "Over the furniture", "PC and phone layouts"). Can't hear the mix here: the gains come from
  measured peaks. Next: `--since=104`: surprised/player and leaps/player (pull_stats), quits right after
  a surprise, PC quits vs phone.

- **20 Oct (reel 36)**: the gameplay series Part 1 (see Marketing). Next reel: Part 2 of it (new
  gameplay beats: the taser, the 911 call, a friend's rescue, the shower/bed hides).

- **20 Oct (v103)**: NIGHTMARE mode + the revive panel (see The intruder). Next: `--since=103`:
  revive bought / asked (want well above 2 of 74), how many groups pick NIGHTMARE and how they do,
  quits right after a death.

- **19 Oct (v101)**: the lived-in layer (`World/Dress`, GDD "The lived-in layer"): ~40 placements
  in rooms that read empty (kitchen counters, master bedroom, Jamie's and Lily's rooms, den, upstairs
  hall, garage, bathrooms), Creator Store stand-ins swapped by `Props.Models`; all clear of doorways,
  door swings, hiding spots, prompts, nav nodes and candy spots (`dress_test`); nav sweep 60/60 on
  the new layout.

- **19 Oct (v100)**, the owner (after showing a reel of another game: raw first-person gameplay, a
  black spindly monster in a doorway): "Make proper icon and thumbnail. Make the monster even better
  and improve pathfinding a lot. Make icons for inventory items." Done: **store art**
  (`marketing/reel_source/art100/`: scene.py icon|thumb|thumb2 → run.sh (film2) → post.py grade +
  title, Lora Bold in `marketing/fonts/`): `marketing/attic/icon_v100_1024/512.png` (him leaning
  over a kid who hasn't seen him), `thumbnail_v100_1.png` / `_2.png` — the owner uploads them (the
  key has no asset:write). **Monster**: tapered bones + tendons, jointed fingers, the mouth opens
  (see GDD). **Pathfinding**: clearance-aware routes (wall-hugging 23% → 5.5%), step back when
  wedged, the chase re-route bug (wedges never escalated), nav stats in the night log (`Nav`,
  pull_stats). **Item icons** in the hotbar + a held-item line. navai_test: the police fallback
  ended its night 3 sim-minutes in (every later trip "failed"): it now stubs the ending; `bench`
  mode. Next: `--since=100`: `his navigation` line (wedged / slips per night), phone quits in
  SmallThings (v99: 4 of 5 phones quit mid-night).

- **19 Oct (v99)**, the owner: comments say "this game sucks dont play it"; "the monster and builds
  especially need reworking", Locust / THRESHOLD-level creepy, proper scares, better sounds, top build,
  and a new-style reel. Stats since v98 (103 nights, 269 lobby visits, rating 18 up / 24 down = 43%):
  first-nighters quit while he was **offstage** 27 of 64 (acts I and the blackout act: nothing scary
  yet), console quits 46%; sales 0 of 10 Become Him windows bought. Done: the new creature (see The
  intruder), stop-motion animation, new jumpscare (lunge + screech), new scares (**YardFigure** in act I,
  also when you close an upstairs window; **HallStare** before he's in; tap on the glass before the
  window figure; hands slammed on the glass), new licensed sounds (screech, bone cracks, claw steps,
  wet breathing, whisper, glass taps, house creaks), his wet footprints at the blackout (`World/Signs`),
  flashlight dust, colder grade in the dark, him watching from the lobby fog. Reel 33: the new "story"
  format (see Marketing). Next: `--since=99`: quits while Offstage in Evening, YardFigure/HallStare in
  the truth logs, rating trend.

- **18 Oct (v98)**, stats since v97 (140 nights, 424 lobby visits, 8,275 visits, votes 18/20): solo
  nights 94% no ending (size 2: 33%, 4: 0%); first nights saw the end 69%; veterans quit 49% (median
  minute 1.1); heartbeat 35/49 passed; secret ending 2 Not Your Family / 2 Forever Family. Sales: see
  Economy (v98). Owner to do: make the Starter Pack product (Creator Hub → Monetization → Developer
  Products: "Starter Pack", 19 R$, icon `marketing/passes/starter_pack.png`) and send the id, or allow
  the developer-products API call. Next: `--since=98`: bought / asked per product, then tune prices.

- **17 Oct (v97)**, stats on v96 (113 nights, 350 lobby visits, 233 players-in-a-night): first-nighters
  quit mid-night 31% (was 42%), saw their night's end 72% (was 62%); heartbeat 24/35 passed; the
  Halloween candy: 156 of 239 player-nights took some, 25 players reached 5 (Pumpkin), 1 reached 15;
  joins in progress 6 of 206; invites used 0; solo nights still 87% no ending (size 2: 30%, 3: 17%,
  4: 0%); median night 10.1 min (police 120 s since v94). Found: the **secret ending** lost players:
  of 35 nights that reached it, 13 ended Forever Family (many in 60-80 s: ~9 strikes from mashing
  STRUGGLE into his turn) and 12 were abandoned ~100 s in. v97: Normal forgives a 0.8 s reaction,
  the first strike only warns, strikes cost 20 s and a quarter of the struggle, a free player caught
  is put back at their chair (Hard unchanged: 30 s, half, re-tied), struggle 1.2%/press (was 0.8).
  Next: `--since=97`: secret-ending outcomes, candy totals, solo nights.

- **16 Oct (v96)**, the owner: "these reels are losing their effect. 0 ccu". Logs: traffic only in
  reel spikes (150-250 visits in ~2 h each: 13 Oct 20:00, 14 Oct 16:00, 15 Oct 01:00 UTC), ~5/h
  otherwise; nothing organic. Solo nights 86% abandoned (26 of 98 solo quits in the first minute);
  with so few players almost everyone plays alone. Done: **Halloween event until 2 Nov** (GDD
  "Halloween 2026": candy hunt, Pumpkin beam / Candy Corn trail / Trick or Treat title at 5/15/30
  candy, badge Halloween2026 1401087647562759, jack-o'-lanterns at the house and in the lobby).
  Owner to do: Halloween icon (`marketing/attic/icon_halloween_512.png`) + title "[🎃 HALLOWEEN]",
  cross-post every reel to TikTok and YouTube Shorts, send the game to small Roblox horror
  YouTubers/TikTokers. Next: `--since=96`: Candy events, solo abandonment; after 2 Nov swap the
  icon and title back.

- **16 Oct (v95)**, the owner: "players have reduced more than 5x". Numbers: daily visits 981 (12 Oct,
  after reel #2-style posts) → 422 → 513 → 371; returning visits 135 → 5; rating 14 up / 17 down
  (45%), 7.0k visits. Traffic comes only in bursts after a reel, so no reel = no players: post
  Parts 4/5, schedule posts (~20:00 and ~01:00 UTC), spread over the accounts. In the game (v94 logs):
  solo nights 82% abandoned vs 30% with two, but only 1 of 124 teleports joined a night in progress,
  and the old invite dropped friends in the lobby. Done: **invite straight into your night**
  (NightCode / InviteOpen, LaunchData "night:<code>", lobby `invited`, ➕ INVITE A FRIEND button,
  solo nudge at 14 s); the flashlight no longer switches on when taken out (click / F); own beam
  shadows off on phones and on slow PCs (PC fps < 30 nights 18/55 in v94, was 7/70). Next:
  `--since=95`: invites used (`Invited` arrivals in the logs), solo abandonment, FpsMin on PC.

- **15 Oct (v94)**, the owner (after reel 26): "make the game more fun", police too long, less time
  before the blackout, the 911 call felt random, "I don't even think taser works", the item
  buttons "so crowded: use the Roblox inventory". Done: items → Roblox tools (ToolService / client
  Gear); taser aim assist 24°, sparks, no shots wasted before the hunt; spray aimed + cloud; police
  120 s; bedtime/blackout gaps shorter; at the blackout a door slams + footsteps far from everyone,
  then "the man from the news is in the house: call 911". Can't see the real hotbar here: check
  the tools' grip/orientation and the HUD lift on a phone.
- **15 Oct (v92)**: monetization pass 2 (see Economy: rocket launcher, Rocket (tonight), role items,
  sales log, admin SHOP tab). Next: `pull_stats.py` (no --logs-only needed for sales) to see what
  sells (`== SALES`), then tune prices; check rocket hits/misses in the logs (events Rocket, Tase,
  Drink, Firecracker).
- **15 Oct (v91)**, stats pass on v88-90 (216 nights, 568 lobby visits, 411 players-in-a-night;
  no script errors). Better than v87: heartbeat Normal 28/60 passed (was 15/50), joins in progress
  37 of 387 teleports (was 9), solo nights 74% abandoned (was 84%). Found: (1) the longest dead time
  of nearly every night was pizza delivered → act II, median 78 s (the man walking back and driving
  off), with a run of act I quits there → act II starts as he turns to go; (2) only 7 of 200 players
  quit while waiting for the police, but 48 of 328 between the blackout and the call (1 min median);
  act III's thoughts started under the cutscene ("the power's out" with the lights on) → they come
  with the dark, and whoever's at the bathroom window (bedtime) is told to call right there; police
  150 → 200 s (nights ran ~11 min, not ~13); (3) 43 of 70 lone nights had another night start within
  a minute → the lobby lists a short group's house at once (`Match.listNew`) and the game server
  stays listed while players arrive/vote; (4) heartbeat lead-in 1.4 → 2.4 s, listen 7-10 s, the last beat always counts. Still open: phones quit
  52% (solo phones 22 of 24), 43 captures in the upstairs bathroom (most 10-50 s after the call).
  Monetization since v89: 2 Become Him, 1 revive, 0 taser uses logged. Next: `--since=91`.
- **14 Oct (v90)**: looks pass: Creator Store washer/dryer, water heater, floor lamps, bar stools,
  guitar (Kit pieces record their frame as WorldPivot); swapped furniture casts shadows. Skipped on
  purpose: stove/fridge/TV/beds (used or hidden in), the car (only script-carrying or union models).
- **14 Oct (v89)**: monetization pass (see Economy: Taser, VIP, Become him, better passes).
  The free creature models found all carry the same hidden ScreenGui/RemoteFunction/Script bundle
  (a backdoor pattern): not used. Next: check Become Him / Taser sales and the v88 numbers
  (`--since=88`).

- **14 Oct (v88)**: spawn-far + short text buzz back (the owner wanted them). Deep stats pass (v87:
  224 nights, 443 players, rating 10 up / 15 down, 5,744 visits): solo nights 84% no ending (23 of
  52 lone players left within 45 s; another group teleported within 60 s half the time, but only 9
  joins); heartbeat passed 15 / 50 on Normal; 29 of 50 captures came within 25 s of a 911 call in
  the bathroom (he charged and went straight to the caller's shower); 42 of 48 act III quitters never
  got help called and 27 never saw him (he patrolled empty rooms); 21 players left a game server
  whose night never started. Fixed: heartbeat buttons on every device (PC had only Q/E), A/D + d-pad,
  Normal forgives the first wrong side per beat (not more misses: doing nothing would pass); caller grace 10 s and no beeline to the caller's spot while it lasts;
  "Others can join your night · 1/4" line (MatchService OpenNight); ArrivalTimeout 20 s; drift
  (after 60 s without contact his patrols lean toward players out in the open). Night length kept.
  Next: re-check these numbers with `--since=88`.

- **13 Oct (v87)**: v86 (pizza-only act I, 8-10 min nights, rewritten short text, tension drone, glimpses
  in act II, he enters far from players, short text buzz) was **"way too short… literally undo that
  entire update"**: v87 reverts all of v86. **Don't shorten the night again.** The owner also said
  the AI is "still bad": standing right in front of him while he walked off after a capture, he
  ignored them (Retreat was blind for its whole length) → v87: blind only 4 s after a capture
  (10 s after pepper spray), then anyone he sees within 30 studs gets chased (hunt_test 8b).

- **13 Oct (v85)**: the owner added `legacy-asset:manage` to the key: models can be downloaded,
  inspected and rendered before use (`tools/assets/`, README there). v85 swaps the big furniture for
  checked Creator Store models (sofas, armchairs, bookcases, dining chairs, Dad's office chair, big
  plants) with a new fitter (facing via WorldPivot + Yaw, Fit width/inside, Back to the wall;
  props_test). Not swapped: beds, wardrobes, desks, appliances, tables with things on them. The
  creature is still part-built: free R15 creature rigs were private meshes or carried hidden
  scripts. Next visual steps: beds with open space under them (check the hiding camera), a better
  creature (needs a model we can actually load), kitchen appliances.
- **13 Oct (v84)**: the owner: comments say "bad" / "AI slop", nothing specific. v84: **night variety**
  (NightPlan: first nights pizza+popcorn+windows; repeat nights pizza + 2 of popcorn/windows/fire/
  movie, never last night's pair; logged as Plan) and **acoustics** (room reverb, muffled through
  walls and while hiding). The game page description can't be changed through the API: new plain
  text in `marketing/attic/description.txt` for the owner to paste (old one saved). Visual pass
  (Creator Store models for the house, a better creature) needs the API key to download assets
  (the asset delivery API answers "Scope not authorized"): ask the owner to add it, then inspect
  models with lune before placing them (no flipped/floating props).
- Owner said NO to skip-to-blackout by default for veterans.
- **13 Oct (v82)**: rating 9 up / 11 down (45%), 4.8k visits. 17 h of v81 logs (194 nights, 520 lobby
  visits, 399 players): late joins 15 of 354 teleports (lone nights grew to 3-4 and ended in Sirens);
  solo nights 38, 82% abandoned; solo first-nighters 22 of 57 quit before the first task (groups 3-4%);
  first-nighters quit mid-night 38% (was 45%), now mostly in act III (54) and act I (36). 152 of 178
  captures were in the open, 42 in the upstairs bathroom, most of them 3-12 s after the 911 call
  (he screams and charges the caller); heartbeat failed 34 of 61 on Normal; 'Again' pressers: 12 of 60
  quit the next night within 2 min (the same chores again); skip-to-blackout used in 9 of 46
  all-veteran nights. Fixed in v82: caller grace (6 s Normal) + urgent "HIDE. NOW." thought with the
  how-to; heartbeat wider/slower; death card TIP (how he got you); script error logging (client
  Perf.Err, server SErr; pull_stats lists them); winning cards (first 5 nights) ask for a 👍.
- **12 Oct (v81)**, from 4.5 h of v78-80 logs (46 nights, 101 lobby visits): new players queue 97%; the
  quit rate per minute is ~7x higher before the first task than after; **solo nights: 14 of 15
  abandoned** (11 in act I), and half of solo phone players never found the pizza menu. Groups of 2
  and 3: 40% / 20% no ending. Help got called in 22 of 25 blackouts (cell 14, neighbour 5, Okafor 3).
  Fixed in v81: (1) MatchService only caught 1 of 68 teleports (150 s window; only short circles
  looked) while 44 of 57 lone departures had another departure within 8 min → open until bedtime
  (max 420 s), room up to 4, full circles look too, "X made it here" notice, solo "not coming" texts
  wait until nobody can join; (2) edge arrow to the current task when its "!" is off screen.
- **12 Oct (v78)**, from 17 h of v77 logs (292 nights, 1,038 lobby visits, 1,275 players):
  - **Highly engaged player = a user who spent a minimum amount anywhere on Roblox in the last 60
    days and plays our game** (Roblox's Kids/Select page). So it's unique paying players over a rolling
    60 days: more players who stay and play is the lever, not returns.
  - Worked: ▶ PLAY (new players queue 91%, bounce 7%); the phone prompt fix (touch groups' popcorn
    step 104 s → 20 s); revive at 10 R$ sold 2 (0 at 25).
  - Fixed in v78: (1) nerve: the dark alone drained everyone to 0 three minutes into the hunt
    (55/102 alive hunt quitters had nerve < 20) → floor 50 (`Nerve.DarkFloor`), softer vignette;
    (2) the 911 call: 36% of nights never got help → Normal whispers a 10 s call (Hard unchanged);
    Mrs. Okafor calls the police 100 s into the last act if nobody did; act III max 7 min;
    (3) "Get ready for bed" (brush teeth upstairs, the phone finds the bar) fills the 149 s of nothing
    before the blackout; (4) **MatchService**: lone/short circles join a group night that started
    short (92% of solo nights abandoned, 18/52 in the first minute); alone in the lobby, circles
    start after 20 s.
- **Next:** `pull_stats.py --logs-only --since=82`: read the script errors first and fix them; bathroom
  captures after the call, heartbeat pass rate (want > 60% on Normal), deaths per player. Then: "joined a night in progress" (v78: 1 of 68), solo
  night count and abandonment (v78: 14/15), solo phone players reaching OrderPizza:Menu (v77-80: 20/40),
  night length (should stay ~12-13 min). Phones still quit most (62% vs PC 30%).
- Daily reminder routine's first send (11 Oct 22:53) failed on the usage limit; it retries daily.
- Coming back another day is ~1%; veterans quit at minute 1 (mostly auto-continued nights they didn't want).

## Workflow and commands

Paths: repo `/home/user/Horror`. `/tmp` scratch space does **not** survive sessions — anything worth
keeping goes in the repo.

- **Typecheck** (baseline = same error count as HEAD, currently 101 lines matching `Error|Warn` with luau-lsp 1.53; never add new ones):
  `rojo sourcemap -o sm.json && luau-lsp analyze --definitions=globalTypes.d.luau --sourcemap=sm.json src`
  (`globalTypes.d.luau` from the luau-lsp repo's `scripts/globalTypes.d.luau`, e.g.
  `curl -sL https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau -o globalTypes.d.luau`
  (gitignored-worthy, don't commit); tools in `/root/bin`. A fresh container may lack them: download
  the release zips (the API is blocked, direct downloads work) into /root/bin:
  `github.com/rojo-rbx/rojo/releases/download/v7.5.1/rojo-7.5.1-linux-x86_64.zip` (7.5.1 or newer: 7.4.4 silently drops Content-typed properties such as the creature's MeshContent and SurfaceAppearance maps),
  `github.com/lune-org/lune/releases/download/v0.10.4/lune-0.10.4-linux-x86_64.zip`,
  `github.com/JohnnyMorganz/luau-lsp/releases/download/1.53.0/luau-lsp-linux-x86_64.zip`).
- **Tests** (Lune harness, runs straight from the repo): `cd tools/harness && ./runall.sh` — every
  `*_test.luau` (finale_test with escape|bedtime|patrol). Add/extend a test for each feature.
- **Build + publish:**
  `rojo build -o HomeAlone.rbxl && python3 tools/place_flags.py HomeAlone.rbxl` (needs `pip install lz4`) then
  `curl -X POST "https://apis.roblox.com/universes/v1/$ROBLOX_UNIVERSE_ID/places/$ROBLOX_PLACE_ID/versions?versionType=Published" -H "x-api-key: $ROBLOX_API_KEY" -H "Content-Type: application/octet-stream" --data-binary @HomeAlone.rbxl`
  (last published: version 114; the notes' "v115" = place version 114, "v114" = place version 113, "v113" = place version 112, "v112" = place version 111, "v111" = place version 110, "v110" = 109, "v109" = 108, "v108" = 107, "v107" = 106).
- **Player data** (read-only key scopes added by the owner): `python3 tools/pull_stats.py <scratch>/dump.json`
  dumps PlayerStats_v1 + Economy_v1 and prints nights played, endings, returners. Snapshot 10 Oct (680
  records): 56% never finished a night; of those who reached the hunt, ~half quit before the night ended;
  only 14% of finishers played a 2nd night; ~2% came back another day; 58% came with a Roblox friend.
  First logs (11 Oct, 52 nights): new players 71% queue and 68% reach the house; first-nighters 82%
  see their night's end; phones/tablets quit mid-night ~42% vs PC 26% (mostly in Act I); deaths
  are caught → struggled free → caught again; Call 911 via the bathroom bar is the main way out.
- **Daily reminder notification** (Roblox experience notifications; string "Your daily reward is ready.
  Don't break your streak!", id `4b35088f-90bc-7d4e-9361-d9ba1176dd42`): `python3 tools/notify.py
  [--dry-run]` sends it to players who claimed their daily reward yesterday or the day before (Roblox
  delivers only to opted-in 13+, max 1/day). A daily Claude Code routine runs it at ~22:53 UTC (an
  hour before the US-evening peak, 00-04 UTC). The key has `user.user-notification:write`.
- **Dev products:** POST `https://apis.roblox.com/developer-products/v2/universes/$ROBLOX_UNIVERSE_ID/developer-products`.
- **Creator Store models:** `tools/assets/` (search → fetch/inspect → preview → Props.Models →
  stage_dump + stage render; README there). Check every model's facing and look before it goes in.
- **Reels / renders:** sources per reel in `marketing/reel_source/reelN/` (scene.py → shots, edit.py →
  edit.json, audio.py → music). Shared tools in `marketing/reel_source/tools/`: `film2.mjs` (three.js
  render of the world dump + creature + avatars), `comp_cantplay.mjs` (the #N caption format),
  `render.mjs` (quick previews), `dump_world_b.luau` / `dump.luau` (world → JSON, run from
  tools/harness), `creature_frames2.luau` (poses him per frame). Encode with
  New reel: `npm install` in tools; dump the world (dump_world_b.luau from tools/harness); scene.py
  preview → contact sheet → fix → full render in 4 parallel `film2.mjs <from> <to>` runs (the street shot is
  slow); edit.py → `comp_cantplay.mjs` (4 parallel); audio.py (#2's track); encode with
  `ffmpeg -framerate 30 -i final/%04d.png -i reel_audio.wav -c:v libx264 -crf 17 -pix_fmt yuv420p -c:a aac -b:a 192k -shortest -movflags +faststart`.
  Finished reels go in `marketing/attic/`.
