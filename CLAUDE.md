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
- **Revives are Robux only** (25 R$ product). No coin revive — it would kill Robux revive sales.
- Git: develop on the designated branch, `git push -u origin <branch>`. **No PRs unless asked.** No model
  names in commits/code. End commit messages with the Co-Authored-By / Claude-Session lines the session
  gives.

## Game decisions to keep (the owner asked for each of these)

**Lobby**
- Third-person, foggy (feels endless), minimal and monochrome. Quiet music.
- Menu on the left side, not the middle: PLAY SOLO, FIND PLAYERS, then only Endings, How to play,
  Settings. Everything else is a small **icon dock** on the right (Rewards, Store, Locker, Shop) with the
  coin balance. Don't add big buttons back.
- Queue circles: white **outline** only, spread out so labels don't overlap. Queue countdown 10 s.
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
- Never stuck on doors/walls (NavGrid survey + navigator).
- Footsteps clearly audible and louder the closer he is.

**Audio**
- Lots of small sounds (doors, items, sirens, jumpscares…). **Occasional** sudden loud stingers are
  wanted (the owner liked the door-yank scare) — rare only.
- **No loud music**: none at night start/end, no chase/tension music, no music in the secret ending.
- No coughing/grunting breath loop on the player (it sounded like someone saying "hello").

**World**
- Warm, cozy, polished interior; real textures; models from anywhere (Creator Store/UGC) when they look
  better; no z-fighting, floating/sunken props, blocked doorways or 90° flipped props. Taller players.
- Rain sound and occasional thunder; fog outside.

**Retention (the 250 highly-engaged goal)**
- Group queue circles start with whoever's there (45 s, or START NOW) — never wait forever at low CCU.
- Levels (XP = coins earned playing) with rewards at milestones; LV on the lobby tag, XP bar on the
  result card; tomorrow's daily reward shown at the end of every night.
- Analytics funnels (TelemetryService): check Creator Hub → Analytics → Funnels to find where new
  players quit, and fix that step first.
- Lobby board "THE SECRET ENDING — found by N players" with a hint.

**Economy / monetization**
- Coins from playing (daily streak, quests, night pay); store with one-night gear (no revive), crates
  with cosmetics (beams, titles, trails), Robux coin packs. Cheap passes starting at 10 R$; donations.
- Admin COINS tab (lobby + game) for the owner.

**Secret ending "Down Here"** (2+ players, everyone zip-tied at once): the dinner (struggle while his back
is turned), he really leaves up the ladder for a while, signposted tunnels, notes give the cellar code,
alcoves to hide in, cellar hatch out. Endings Not Your Family / Forever Family.

## Marketing (Instagram reels)

- **Winning format: "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #N"** — orange, plain outlined captions,
  case-file card (FEAR LEVEL 10/10), escalating captions ("night 1… night 19… tonight he's coming down"),
  RUN. + flash, end card "SEARCH IT ON ROBLOX". #2 got **115k** views, #5 61k, #7 did well. Latest: **#8**
  (the secret ending). Keep #2's slot lengths so the cuts and **the same music** land identically;
  change the story/clips each time.
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

## Workflow and commands

Paths: repo `/home/user/Horror`. `/tmp` scratch space does **not** survive sessions — anything worth
keeping goes in the repo.

- **Typecheck** (baseline = same error count as HEAD, currently 46; never add new ones):
  `rojo sourcemap -o sm.json && luau-lsp analyze --definitions=globalTypes.d.luau --sourcemap=sm.json src`
  (`globalTypes.d.luau` from the luau-lsp repo's `scripts/globalTypes.d.luau`; tools in `/root/bin`).
- **Tests** (Lune harness, runs straight from the repo): `cd tools/harness && ./runall.sh` — every
  `*_test.luau` (finale_test with escape|bedtime|patrol). Add/extend a test for each feature.
- **Build + publish:**
  `rojo build -o HomeAlone.rbxl && python3 tools/place_flags.py HomeAlone.rbxl` then
  `curl -X POST "https://apis.roblox.com/universes/v1/$ROBLOX_UNIVERSE_ID/places/$ROBLOX_PLACE_ID/versions?versionType=Published" -H "x-api-key: $ROBLOX_API_KEY" -H "Content-Type: application/octet-stream" --data-binary @HomeAlone.rbxl`
  (last published: version 63).
- **Dev products:** POST `https://apis.roblox.com/developer-products/v2/universes/$ROBLOX_UNIVERSE_ID/developer-products`.
- **Reels / renders:** sources per reel in `marketing/reel_source/reelN/` (scene.py → shots, edit.py →
  edit.json, audio.py → music). Shared tools in `marketing/reel_source/tools/`: `film2.mjs` (three.js
  render of the world dump + creature + avatars), `comp_cantplay.mjs` (the #N caption format),
  `render.mjs` (quick previews), `dump_world_b.luau` / `dump.luau` (world → JSON, run from
  tools/harness), `creature_frames2.luau` (poses him per frame). Encode with
  `ffmpeg -framerate 30 -i final/%04d.png -i reel_audio.wav -c:v libx264 -crf 17 -pix_fmt yuv420p -c:a aac -b:a 192k -shortest -movflags +faststart`.
  Finished reels go in `marketing/attic/`.
