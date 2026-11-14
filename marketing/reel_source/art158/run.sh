#!/bin/bash
# ./run.sh thumb|thumb2|icon -> raw/<kind>.png (the v157 house: tools/harness stage_dump.luau $S/stage157.json)
S=/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad
STAGE=${STAGE:-$S/stage157.json}
HERE=$(cd "$(dirname "$0")" && pwd)
W=$S/art158/$1; mkdir -p $W && cd $W && python3 $HERE/scene.py $1 >/dev/null || exit 1
(cd /home/user/Horror && /root/bin/lune run tools/creature/skin_frames.luau $W/frames_in.json $W/creature_frames.json 2>&1 | tail -1)
rm -rf $W/raw; cd $HERE/../tools && node film2.mjs $STAGE $W/creature_frames.json $W/spec.json $W/raw 2>&1 | grep -iv "^frame\|triangles\|^models" | tail -2
mkdir -p $HERE/raw && cp $W/raw/0000.png $HERE/raw/$1.png && echo "-> raw/$1.png"
