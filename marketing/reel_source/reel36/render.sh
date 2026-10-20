#!/bin/bash
# ./render.sh preview -> $S/reel36/sheet.png ; ./render.sh full [from to] -> $S/reel36/raw
S=/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad
HERE=$(cd "$(dirname "$0")" && pwd)
W=$S/reel36; mkdir -p $W && cd $W
if [ "$1" = "preview" ]; then python3 $HERE/scene.py preview; else python3 $HERE/scene.py; fi
cp $HERE/../tools/creature_frames2.luau /home/user/Horror/tools/harness/zz_cf2_r36.luau
(cd /home/user/Horror/tools/harness && /root/bin/lune run zz_cf2_r36 $W 2>&1 | tail -1; rm -f zz_cf2_r36.luau)
