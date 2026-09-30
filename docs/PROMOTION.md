# Getting the first players (no Robux needed)

Everything here is free. The goal is the first few hundred real players. Roblox then starts recommending games whose players stay a long time and come back, and around 250 "highly engaged players" (people who have spent money on Roblox in the last 60 days, anywhere) opens up the younger "Roblox Kids and Select" audience.

## 1. Settings that only you can change (5 minutes, Creator Hub)

- **Maturity questionnaire.** The game's age rating is currently *unspecified*, which limits who can see and play it. Go to Audience → Maturity & Compliance and answer: mild fear/violence, no blood, no gore.
- **Private servers: free**, not 100 Robux (Monetization → Private Servers).
- **Console: on**, and **Spatial voice: on** (Places → Settings / Communication).
- **Allow Loading Third Party Assets: on** (Settings → Security). The new props need it.
- Paste the **title, description, icon and thumbnails** from `docs/STORE_PAGE.md` and `marketing/`.

**Want me to do these settings for you next time?** Open Creator Hub → Open Cloud → API Keys, edit the key this project uses, and add the **universe** API with **write** access for this experience. Then I can change the price, console setting and description myself. The maturity questionnaire and the icon/thumbnails still have to be done by you in Creator Hub.

## 2. Short videos (the main way new Roblox games grow)

Two ready-made vertical teasers are in `marketing/`: `teaser_hallway.mp4` and `teaser_house.mp4` (1080×1920, about 13–15 s). The sound is original and synthesized, so you can post them anywhere. They also work with a trending sound added on top.

Post the same video to **TikTok, YouTube Shorts and Instagram Reels**. Each week, post 3–5 more clips recorded in the game. Use the Roblox screen recorder, or your phone's screen recording while playing. The clips that do best:

- Getting shoved in the dark before the hunt starts.
- The door being yanked shut in your face.
- The strange pizza guy conversation.
- A friend screaming on voice chat when Curtis finds them in the closet.
- Opening the attic and finding the nest.

Captions to paste:

> POV: your parents left you home alone and the attic door was open 😳 #roblox #robloxhorror #horror #scary #robloxgames #homealone #fyp

> A man has been living in this family's attic for 19 days. Game: Home Alone on Roblox 🏠 #roblox #robloxhorror #phrogging #scarygames #horrortok

> Me and the boys trying to survive Home Alone on Roblox 💀 #roblox #robloxfunny #robloxhorror #gaming

Pin a comment: **"Search HOME ALONE on Roblox 🔦 free, play with friends"**.

## 3. Friends first (this is where the first 50 players come from)

- Play a night with 3 friends. In the lobby, tap **Invite friends**. Anyone who joins from your invite, or comes in alongside you as a Roblox friend on their first visit, counts toward the **flashlight colours**: Ember (1 friend), Moonlight (3), Blood moon (5). New players get Ember too.
- Ask everyone to **favorite** the game (the button is in the lobby and on the ending screen). Favorites put it in their friends' feeds.

## 4. Free posting spots

- **Roblox DevForum → Creations Feedback** (you need to be a Member there). Post the thumbnails with this text:

  > **Home Alone: co-op horror where every creak has a real cause**
  > You and up to 3 friends are home alone on a stormy night. Someone has been living in the attic for 19 days. No ghosts: every strange thing has a real explanation, shown to you at the end. There's hiding, rescuing captured friends, and 7 endings. Plays well on phones.
  > I'd love feedback on the scares and the pacing: [link]

- **Reddit:** r/robloxgamedev (a "I made this" post with the hallway teaser) and r/RobloxHorror.
- **Roblox group:** create a free group called "Home Alone Game" and link it on the game page (Social Links). Post in its shout when you update.
- **Discord:** Roblox horror game servers usually have a #self-promo channel.

## 5. When the game has players

- Watch **Creator Hub → Analytics**: session length, day-1 retention and where players quit. Tell me what the numbers are and I'll fix the part where people drop off.
- Once there are ~1,000 visits, run the **thumbnail experiment** described in `docs/STORE_PAGE.md`.
- Create **badges** for each ending (Roblox lets you create a few badges per game for free each day; paste their IDs into `Config.Badges`). Hunting badges keeps players coming back.
