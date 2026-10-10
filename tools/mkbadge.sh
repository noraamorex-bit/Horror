#!/bin/bash
# create one FREE badge: refuses unless the free quota is > 0; expectedCost=0 so Roblox rejects any charge
key=$1
q=$(curl -sS "https://badges.roblox.com/v1/universes/$ROBLOX_UNIVERSE_ID/free-badges-quota" -H "x-api-key: $ROBLOX_API_KEY")
if ! [[ "$q" =~ ^[0-9]+$ ]] || [ "$q" -le 0 ]; then echo "NOQUOTA $key ($q)"; exit 2; fi
line=$(grep -P "^$key\t" tools/badges.tsv); name=$(echo "$line"|cut -f2); desc=$(echo "$line"|cut -f3)
r=$(curl -sS -X POST "https://apis.roblox.com/legacy-badges/v1/universes/$ROBLOX_UNIVERSE_ID/badges" -H "x-api-key: $ROBLOX_API_KEY" -F "name=$name" -F "description=$desc" -F "paymentSourceType=User" -F "expectedCost=0" -F "isActive=true" -F "files=@marketing/badges/$key.png;type=image/png")
id=$(echo "$r" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
echo "$key quota-before $q id=$id ${id:+ok}"; [ -z "$id" ] && echo "  $r"
exit 0
