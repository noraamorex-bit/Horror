#!/bin/bash
# assemble.sh <frames-prefix-dir> <frame-letter> <video-seconds> <title-seconds> <wav> <out> caption:start:end ...
FF=/usr/local/lib/python3.11/dist-packages/imageio_ffmpeg/binaries/ffmpeg-linux-x86_64-v7.0.2
DIR=$1; L=$2; VS=$3; TS=$4; WAV=$5; OUT=$6; shift 6
TOTAL=$(python3 -c "print($VS+$TS)")
inputs=(-framerate 24 -i "$DIR/${L}%04d.png" -i "$WAV")
filter="[0]scale=1080:1920:flags=lanczos,noise=alls=7:allf=t,vignette=angle=PI/4.2,tpad=stop_mode=add:stop_duration=$TS:color=black,format=yuv420p[v0]"
last="v0"; i=2; n=0
for spec in "$@"; do
  IFS=: read -r png st en <<< "$spec"
  inputs+=(-loop 1 -t "$TOTAL" -framerate 24 -i "$png")
  fo=$(python3 -c "print($en-0.35)")
  filter="$filter;[$i]format=rgba,fade=in:st=$st:d=0.35:alpha=1,fade=out:st=$fo:d=0.35:alpha=1[c$n];[$last][c$n]overlay=0:0:enable='between(t,$st,$en)'[v$((n+1))]"
  last="v$((n+1))"; i=$((i+1)); n=$((n+1))
done
$FF -hide_banner -loglevel error -y "${inputs[@]}" -filter_complex "$filter" -map "[$last]" -map 1:a -t "$TOTAL" \
  -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -r 24 -c:a aac -b:a 192k -movflags +faststart "$OUT"
echo "wrote $OUT"
