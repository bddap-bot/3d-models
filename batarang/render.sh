#!/usr/bin/env bash
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
frames="${BOTQ_JOB_DIR:-$dir}/batarang-frames"
mkdir -p "$frames"
printf 'color([0.16,0.18,0.22]) import("%s/out/batarang.stl");\n' "$dir" > "$frames/scene.scad"

xvfb-run -a openscad -q --viewall --autocenter --projection=p --imgsize=1200,900 --camera=0,0,0,24,0,0,180 -o "$dir/still.png" "$frames/scene.scad"
xvfb-run -a openscad -q --viewall --autocenter --projection=p --imgsize=1200,900 --camera=0,0,0,0,0,0,180 -o "$dir/above.png" "$frames/scene.scad"

for angle in $(seq 0 10 350); do
  frame=$(printf '%03d' "$((angle / 10))")
  xvfb-run -a openscad -q --viewall --autocenter --projection=p --imgsize=800,600 --camera=0,0,0,30,0,"$angle",180 -o "$frames/$frame.png" "$frames/scene.scad"
done

ffmpeg -y -framerate 12 -i "$frames/%03d.png" -vf "fps=12,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" "$dir/turntable.gif"
