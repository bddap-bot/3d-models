#!/usr/bin/env bash
cd "$(dirname "$0")"
for p in body_R body_L lid bracket tray; do
  echo "== $p"
  prusa-slicer --export-gcode --load slicer.ini --center 90,90 --output "print_$p.gcode" "print_$p.stl" 2>&1 | grep -v '^$' | tail -4
  grep -E "^; (filament used \[g\]|estimated printing time)" "print_$p.gcode"
done
