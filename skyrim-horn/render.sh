#!/usr/bin/env bash
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
frames="$dir/turntable-frames"
mkdir -p "$frames"

xvfb-run -a openscad -q --viewall --autocenter --projection=p --imgsize=1200,900 --camera=0,0,0,72,0,28,520 -D 'part="assembly"' -D 'show_candle=true' -o "$dir/still.png" "$dir/skyrim-horn.scad"

for angle in $(seq 0 10 350); do
  frame=$(printf '%03d' "$((angle / 10))")
  xvfb-run -a openscad -q --viewall --autocenter --projection=p --imgsize=800,600 --camera=0,0,0,72,0,"$angle",520 -D 'part="assembly"' -D 'show_candle=true' -o "$frames/$frame.png" "$dir/skyrim-horn.scad"
done

ffmpeg -y -framerate 12 -i "$frames/%03d.png" -vf "fps=12,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" "$dir/turntable.gif"
