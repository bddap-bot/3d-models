#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
R=(--autocenter --imgsize=1400,1000 --projection=p)
openscad -q -D 'part="assembly"' --camera=0,0,50,65,0,35,470 "${R[@]}" -o img_assembly_front.png hopper.scad
openscad -q -D 'part="assembly"' --camera=0,0,50,65,0,215,470 "${R[@]}" -o img_assembly_back.png hopper.scad
openscad -q -D 'part="section"'  --camera=0,40,40,90,0,90,470 --projection=o --autocenter --imgsize=1400,1000 -o img_assembly_section.png hopper.scad
openscad -q -D 'part="section"'  --camera=0,0,50,65,0,60,470 "${R[@]}" -o img_assembly_cutaway.png hopper.scad
openscad -q -D 'part="perch"' --camera=0,60,30,90,0,90,470 --projection=o --autocenter --imgsize=1400,1000 -o img_perch.png hopper.scad
openscad -q -D 'part="catch"' --camera=66,1.8,10,90,0,0,90 --projection=o --autocenter --imgsize=1000,1000 -o img_catch.png hopper.scad
openscad -q --render -D 'part="seam"' --camera=0,-21,60,50,0,25,80 "${R[@]}" -o img_seam.png hopper.scad
for p in body_R body_L lid bracket tray; do
  openscad -q -D "part=\"$p\"" --camera=0,0,0,60,0,35,400 "${R[@]}" -o "img_$p.png" hopper.scad
done
