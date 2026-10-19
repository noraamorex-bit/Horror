#!/bin/bash
# ./run.sh icon|thumb|thumb2 -> raw/<kind>.png (stage: the world dump used by the reels)
S=/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad
STAGE=${STAGE:-$S/reel32/stage.json}
HERE=$(cd "$(dirname "$0")" && pwd)
W=$S/art100/$1; mkdir -p $W && cd $W && python3 $HERE/scene.py $1 >/dev/null || exit 1
cp $HERE/../tools/creature_frames2.luau /home/user/Horror/tools/harness/zz_cf2_$1.luau
(cd /home/user/Horror/tools/harness && /root/bin/lune run zz_cf2_$1 $W 2>&1 | tail -1; rm -f zz_cf2_$1.luau)
rm -rf $W/raw; cd $HERE/../tools && node film2.mjs $STAGE $W/creature_frames.json $W/spec.json $W/raw 2>&1 | grep -iv "^frame\|triangles\|^models" | tail -2
mkdir -p $HERE/raw && cp $W/raw/0000.png $HERE/raw/$1.png && echo "-> raw/$1.png"
