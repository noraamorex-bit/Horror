#!/bin/bash
# ./render.sh preview  -> $S/reel38p/raw + sheet.png (a few frames per shot; DENSE=shot:step[:from],... for more)
# ./render.sh full     -> $S/reel38/raw (every frame, 4 parallel film2 runs)
S=/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad
HERE=$(cd "$(dirname "$0")" && pwd)
TOOLS=$HERE/../tools
STAGE=$S/reel38/stage.json     # (tools/harness: lune run stage_dump.luau $S/reel38/stage.json)
if [ "$1" = "preview" ]; then W=$S/reel38p; else W=$S/reel38; fi
mkdir -p $W && cd $W
if [ "$1" = "preview" ]; then python3 $HERE/scene.py preview; rm -rf raw; else python3 $HERE/scene.py; fi
cp $TOOLS/creature_frames2.luau /home/user/Horror/tools/harness/zz_cf2_r38.luau
(cd /home/user/Horror/tools/harness && /root/bin/lune run zz_cf2_r38 $W 2>&1 | tail -1; rm -f zz_cf2_r38.luau)
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
