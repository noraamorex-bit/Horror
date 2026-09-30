# Store page

Paste these into **Creator Hub → Creations → Home Alone**. The images are in `marketing/`.

## Title (max 50 characters)

**Home Alone 🏠 Horror**

Alternatives to A/B test later (Creator Hub → Thumbnails & title experiments):
- `Home Alone 🏠 [Horror Story]`
- `Home Alone 🔦 Co-op Horror`

Keep "Home Alone" first: it's what people search for. A short emoji tag reads well on phones, where most players browse. Avoid long bracket strings like "[🎃UPD] [2X] [NEW]": they look spammy and cut off on mobile.

## Description (paste as is, under the 1000-character limit)

```
Your parents are gone for the weekend. The fire is lit, the pizza is ordered, your friends are over. It's the coziest night of the year... until the lights go out.

Someone has been living in your attic for nineteen days. Tonight he comes down.

🔦 A story horror game for 1-4 players. Play solo or co-op with friends
🏠 Explore a whole house at night, from the basement to the attic
🙈 Hide in closets and under beds and hold your breath. Don't let him see you
🍕 Answer the door to a very strange pizza guy and choose what you say
🤝 Rescue your friends, fix the phone line, call 911 or escape in the car
🔎 No ghosts. Every creak has a real cause, and the ending shows what really happened
🏆 7 endings to find, one of them secret

Scary but fair: jumpscares, stealth and survival, with no gore.
Plays on phone, tablet, PC and controller.

⭐ Favorite the game and invite your friends. It's scarier together.
```

This covers the words people search for: *horror, scary, story, co-op, friends, hide, stealth, survival, escape, jumpscare, attic, house, night, pizza, mystery*. They're worked into real sentences, because Roblox demotes keyword lists.

## Tags, genre and settings

Roblox no longer has free-form tags. Discovery comes from the **title, description, genre and engagement**. Set these:

- **Genre:** Horror. **Subgenre:** Story (or Survival if Story isn't offered).
- **Max players:** 4 per server (the game already reserves private servers per group).
- **Devices:** Phone, Tablet, Computer, Console. **VR:** off.
- **Maturity / Content Maturity questionnaire:** answer honestly: *fear/violence: mild* (no blood). The likely result is **Mild 9+**, which keeps the game visible to most players.
- **Allow Loading Third Party Assets:** **On** (Game Settings → Security). The props from the Creator Store need it.
- **Enable Spatial Voice:** On. Proximity voice makes co-op horror much scarier.
- **Private servers:** Free (friends groups are the main audience).

## Icon and thumbnails (upload in this order)

| Slot | File | Why |
|---|---|---|
| Icon | `marketing/icon_512.png` | A face at the end of a dark hallway reads well at tiny sizes |
| Thumbnail 1 | `thumbnail_1_home_alone.png` | Title and hook: the house at night, with someone in the upstairs window |
| Thumbnail 2 | `thumbnail_2_hallway.png` | The monster moment: him at the end of your flashlight beam |
| Thumbnail 3 | `thumbnail_3_cozy.png` | The twist: a cozy night, and a sack mask peeking over the armchair |
| Thumbnail 4 | `thumbnail_4_nineteen_days.png` | The mystery hook: the attic nest |
| Thumbnail 5 | `thumbnail_5_coop.png` | The features: co-op, hiding, rescues, 7 endings, all devices |

Icons are 512×512 and thumbnails are 1920×1080 PNGs, all rendered from the actual game map.

Once you have ~1,000 visits, run a **Thumbnail experiment** (Creator Hub → Analytics → Experiments) of thumbnail 1 against thumbnail 3 as the first image. Keep whichever gets the higher click-through rate.

## Also worth doing (can't be done from code with this API key)

- **Badges:** create one per ending (Sirens, CaseClosed, NextDoor, Taillights, LockedIn, Dawn, GoneQuiet) plus "FirstNight". Paste the IDs into `Config.Badges` in `src/shared/Config.luau`. Badges are a strong reason for players to come back.
- **Social links:** add a Roblox group (and Discord/TikTok if you have them) under Social Links. Players who join a group come back more.
- **Sponsored ads:** a small budget on thumbnail 3 or thumbnail 2 once the game's retention is known.
