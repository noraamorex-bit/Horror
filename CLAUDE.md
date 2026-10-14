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
- **Admin tools are only for the owner** — UserId **915496194** (`Config.Admins`), checked on the server
  for every command. Nobody else, ever.
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
- Secret-ending HUD is one slim bar at the top (it was "way too big" before).

**Pacing / story**
- It's a horror game, not a chore simulator: few tasks, multi-step, no dead time. No "stay together"
  task that solo can't do.
- Friends speak in dialogue boxes (not texts). Pizza delivery with two dialogue choices; delivery man is
  a normal Roblox avatar in a red pizza shirt, creepy not goofy.
- Mom texts about the news → phone chat with replies → "watch the news" task; the TV has a real news
  presenter with text-to-speech (no laugh track). TV voice only heard when you can see the TV.
- Endings: short cutscene + simple result card (no logs). Solo: escape/death ends it. Co-op: your own
  card with SPECTATE (spectating must work, also from the neighbour's after escaping — no bare rooms).
- Second capture = death. ANOTHER NIGHT button keeps a group together.

**The intruder (Curtis)**
- Genuinely scary creature; smart (Doors' "Figure"-style: hunts by sound and sight, charges, inspects
  hiding spots, heartbeat minigame). Players must **hide**.
- **Slower than the player's walk speed.** Not too hard (owner worried about rage-quits); after a capture
  he leaves so friends get a rescue window.
- Before the hunt he stays hidden — no pointless noises or knocked-over chairs in front of you.
- **He enters the house far from everyone** when the hunt starts (the owner: "why does he spawn
  upstairs. Spawn him far away").
- Never stuck on doors/walls (NavGrid survey + navigator).
- Footsteps clearly audible and louder the closer he is.

**Audio**
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

**Secret ending "Down Here"** (2+ players, everyone zip-tied at once): the dinner (struggle while his back
is turned), he really leaves up the ladder for a while, signposted tunnels, notes give the cellar code,
alcoves to hide in, cellar hatch out. Endings Not Your Family / Forever Family.

## Marketing (Instagram reels)

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
  `github.com/rojo-rbx/rojo/releases/download/v7.4.4/rojo-7.4.4-linux-x86_64.zip`,
  `github.com/lune-org/lune/releases/download/v0.10.4/lune-0.10.4-linux-x86_64.zip`,
  `github.com/JohnnyMorganz/luau-lsp/releases/download/1.53.0/luau-lsp-linux-x86_64.zip`).
- **Tests** (Lune harness, runs straight from the repo): `cd tools/harness && ./runall.sh` — every
  `*_test.luau` (finale_test with escape|bedtime|patrol). Add/extend a test for each feature.
- **Build + publish:**
  `rojo build -o HomeAlone.rbxl && python3 tools/place_flags.py HomeAlone.rbxl` (needs `pip install lz4`) then
  `curl -X POST "https://apis.roblox.com/universes/v1/$ROBLOX_UNIVERSE_ID/places/$ROBLOX_PLACE_ID/versions?versionType=Published" -H "x-api-key: $ROBLOX_API_KEY" -H "Content-Type: application/octet-stream" --data-binary @HomeAlone.rbxl`
  (last published: version 88).
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
