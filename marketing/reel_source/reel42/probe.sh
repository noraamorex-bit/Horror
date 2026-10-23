#!/bin/bash
# ./probe.sh 420 500 ...  -> $S/reel42probe/raw/NNNN.png at full size (just those frames), + sheet.png
S=/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad
HERE=$(cd "$(dirname "$0")" && pwd)
W=$S/reel42probe; mkdir -p $W && cd $W && rm -rf raw
python3 $HERE/scene.py > /dev/null
python3 - "$@" <<'PY'
import json, sys
want = set(int(a) for a in sys.argv[1:])
sp = json.load(open("spec.json")); sp["frames"] = [f for f in sp["frames"] if f["f"] in want]; json.dump(sp, open("spec.json", "w"))
cr = json.load(open("frames_in.json")); json.dump([c for c in cr if c["f"] in want], open("frames_in.json", "w"))
PY
cp $HERE/../tools/creature_frames2.luau /home/user/Horror/tools/harness/zz_cf2_p42.luau
(cd /home/user/Horror/tools/harness && /root/bin/lune run zz_cf2_p42 $W > /dev/null 2>&1; rm -f zz_cf2_p42.luau)
cd $HERE/../tools && node film2.mjs $S/reel42/stage.json $W/creature_frames.json $W/spec.json $W/raw 2>&1 | grep -i "error" | head -3
python3 $HERE/sheet.py $W/raw $W/sheet.png 4 > /dev/null
