#!/usr/bin/env bash
set -e
cd /home/bot/.cache/botq-wt/3279
OUT="$BOTQ_ARTIFACTS_DIR"
openscad -o "$OUT/assembly.png" --render -D 'part="assembly"' \
  --camera=180,-40,60,55,0,25,420 --imgsize=1200,900 --colorscheme=Tomorrow hopper.scad 2>&1 | tail -2
for p in body lid tray; do
  openscad -o "$OUT/$p.png" --render -D "part=\"$p\"" \
    --autocenter --viewall --imgsize=1000,800 --colorscheme=Tomorrow hopper.scad 2>&1 | tail -1
done
ls -la "$OUT"/*.png
