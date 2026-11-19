#!/usr/bin/env bash
# Turns six short screen recordings of Sova into an App Store App Preview:
# 886 x 1920, 30 fps, H.264, stereo AAC, 15-30 seconds, with a short
# caption on each clip in Allo.
#
#   ./make-preview.sh            reads clips/1.mov … clips/6.mov
#   ./make-preview.sh --plain    same, without captions
#
# Record the clips first: see PREVIEW.md next to this script.
set -euo pipefail
cd "$(dirname "$0")"

FONT="../../../Shared/Fonts/Allo-ExtraBold.otf"
OUT="Sova-App-Preview.mp4"
CAPTIONS=1
[ "${1:-}" = "--plain" ] && CAPTIONS=0

# clip  seconds  caption
SHOTS=(
  "1|4.5|Your day, at a glance"
  "2|5|Just type it"
  "3|4|Habits that fill up"
  "4|3.5|Every task has a home"
  "5|4.5|Big goals, small steps"
  "6|5|Finish your day with a smile"
)

command -v ffmpeg >/dev/null || { echo "Install ffmpeg first: brew install ffmpeg"; exit 1; }
mkdir -p build
parts=()
total=0
for shot in "${SHOTS[@]}"; do
  IFS='|' read -r n secs caption <<<"$shot"
  src=$(ls clips/"$n".* 2>/dev/null | head -1 || true)
  [ -n "$src" ] || { echo "Missing clips/$n.mov (or .mp4)"; exit 1; }
  text=""
  if [ "$CAPTIONS" = 1 ]; then
    safe=${caption//\'/\\\'}
    text=",drawbox=x=0:y=0:w=iw:h=210:color=0x15102E@0.0:t=fill,drawtext=fontfile=$FONT:text='$safe':fontsize=58:fontcolor=0x15102E:x=(w-text_w)/2:y=96:box=1:boxcolor=0xFFE94D:boxborderw=26"
  fi
  ffmpeg -loglevel error -y -i "$src" -t "$secs" \
    -vf "scale=886:1920:force_original_aspect_ratio=increase,crop=886:1920,fps=30,format=yuv420p$text" \
    -an -c:v libx264 -preset slow -crf 16 -r 30 "build/part$n.mp4"
  parts+=("build/part$n.mp4")
  total=$(echo "$total + $secs" | bc)
done

# Join the clips with quick cross-fades.
inputs=(); for p in "${parts[@]}"; do inputs+=(-i "$p"); done
filter=""; prev="[0:v]"; offset=0; fade=0.35
for i in $(seq 1 $((${#parts[@]} - 1))); do
  IFS='|' read -r _ secs _ <<<"${SHOTS[$((i - 1))]}"
  offset=$(echo "$offset + $secs - $fade" | bc)
  filter+="$prev[$i:v]xfade=transition=fade:duration=$fade:offset=$offset[v$i];"
  prev="[v$i]"
done
filter=${filter%;}
length=$(echo "$total - $fade * (${#parts[@]} - 1)" | bc)

ffmpeg -loglevel error -y "${inputs[@]}" -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=44100" \
  -filter_complex "$filter" -map "$prev" -map "${#parts[@]}:a" -t "$length" \
  -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -r 30 -b:v 10M -maxrate 12M -bufsize 20M \
  -c:a aac -b:a 256k -ar 44100 -ac 2 -movflags +faststart "$OUT"

echo "Made $OUT ($length s). Upload it in App Store Connect under App Previews (6.9\")."
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate,channels -show_entries format=duration -of compact "$OUT"
