#!/bin/bash
# Updates the game passes' names, descriptions, prices and icons on Roblox (Open Cloud, game-passes
# scope). Run from this folder when the game code that grants them is published.
set -e
U=$ROBLOX_UNIVERSE_ID
api() { curl -s -o /dev/null -w "%{http_code} $1\n" -X PATCH "https://apis.roblox.com/game-passes/v1/universes/$U/game-passes/$1" -H "x-api-key: $ROBLOX_API_KEY" "${@:2}"; }
# the pepper spray pass is the taser now (same pass: whoever bought it has the taser)
api 2006030307 -F "name=Taser" -F "description=Start every night with a taser: 3 shots. A hit stuns him, then slows him right down." -F "price=49" -F "imageFile=@taser.png;type=image/png"
api 2036510399 -F "isForSale=true"
api 2008280313 -F "description=+20% coins every night, a SUPPORTER tag, a gold flashlight and a star on the donation board."
api 2005053525 -F "description=Sprint for longer and get your breath back twice as fast."
api 2005388315 -F "description=Your flashlight never runs out."
api 2006721483 -F "description=Start every night with a flashlight and a can of pepper spray."
# v92 (15 Oct): the rocket launcher on sale; roles start with items, so picking one is worth more;
# VIP includes picking your role; Head Start's old description came back filtered ("####")
api 2039534472 -F "isForSale=true"
api 2006193593 -F "price=25" -F "description=Choose who you play every night, and what you start with: Jamie's flashlight, Riley's toolkit, Morgan's energy drinks or Casey's firecrackers."
api 2036510399 -F "description=Everything in one: +50% coins every night, a VIP tag, pick your role, every flashlight colour, Marathon stamina and a battery that never dies."
api 2006721483 -F "description=Start every night with a flashlight in your pocket, plus a spray can to keep him back." # ("pepper spray" comes back filtered)
# v106 (21 Oct): the admin panel pass (created with POST .../game-passes, id 2044988494, 249 R$)
api 2044988494 -F "isForSale=true" -F "imageFile=@admin_panel.png;type=image/png"
