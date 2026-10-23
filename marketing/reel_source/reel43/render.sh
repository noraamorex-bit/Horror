#!/bin/bash
# ./render.sh preview  -> $S/reel43p/raw + sheet.png (a few frames per shot; DENSE=shot:step[:from],... for more)
# ./render.sh full     -> $S/reel43/raw (every frame, 4 parallel film2 runs)
# The world: reel 42's stage dump (tools/harness: lune run stage_dump.luau $S/reel42/stage.json). The creature:
# the v112 skinned mesh, posed by tools/creature/skin_frames.luau (the game's own SkinPose).
S=/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad
HERE=$(cd "$(dirname "$0")" && pwd)
TOOLS=$HERE/../tools
STAGE=$S/reel42/stage.json
if [ "$1" = "preview" ]; then W=$S/reel43p; else W=$S/reel43; fi
mkdir -p $W && cd $W
if [ "$1" = "preview" ]; then python3 $HERE/scene.py preview; rm -rf raw; else python3 $HERE/scene.py; fi
(cd /home/user/Horror && /root/bin/lune run tools/creature/skin_frames.luau $W/frames_in.json $W/creature_frames.json 2>&1 | tail -1)
cd $TOOLS
if [ "$1" = "preview" ]; then
  node film2.mjs $STAGE $W/creature_frames.json $W/spec.json $W/raw 2>&1 | grep -iv "^frame" | tail -3
  python3 $HERE/sheet.py $W/raw $W/sheet.png
else
  N=$(python3 -c "import json;print(max(f['f'] for f in json.load(open('$W/spec.json'))['frames']))")
  Q=$(( (N + 4) / 4 ))
  for k in 0 1 2 3; do
    a=$(( k * Q )); b=$(( (k + 1) * Q - 1 ))
    node film2.mjs $STAGE $W/creature_frames.json $W/spec.json $W/raw $a $b > $W/film_$a.log 2>&1 &
  done
  wait
  ls $W/raw | wc -l
fi
