#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
xvfb-run -a openscad -q -D 'part="assembly"' --camera=0,0,0,65,0,215,600 --viewall --autocenter --imgsize=1400,1000 --projection=p -o kimi/img_assembly_outside.png kimi/hopper.scad
xvfb-run -a openscad -q -D 'part="assembly"' --camera=0,0,0,65,0,35,600 --viewall --autocenter --imgsize=1400,1000 --projection=p -o kimi/img_assembly_inside.png kimi/hopper.scad
montage -font "$(fc-match -f "%{file}" "DejaVu Sans")" \
  -label 'codex (gpt-5.6-sol): 7 min, 3 parts' codex/assembled.png \
  -label 'fable 5.1: 31 min, 5 parts' fable/img_assembly_front.png \
  -label 'opus 5: 75 min, 6 parts' opus/img/assembly_iso.png \
  -label 'kimi-k3: 30 min, 3 parts' kimi/img_assembly_outside.png \
  -tile 2x2 -geometry 700x560+12+12 -pointsize 22 -background white montage.png
