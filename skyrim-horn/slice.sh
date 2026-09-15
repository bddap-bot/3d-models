#!/usr/bin/env bash
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
work=${BOTQ_JOB_DIR:-$dir}
mkdir -p "$work/slice"

openscad -q -o "$work/slice/horn-print.stl" -D 'part="horn_print"' "$dir/skyrim-horn.scad"
openscad -q -o "$work/slice/mount-print.stl" -D 'part="mount_print"' "$dir/skyrim-horn.scad"
openscad -q -o "$work/slice/plate-print.stl" -D 'part="plate_print"' "$dir/skyrim-horn.scad"
prusa-slicer --export-gcode --load "$dir/slicer.ini" --center 90,90 --output "$work/slice/horn.gcode" "$work/slice/horn-print.stl"
prusa-slicer --export-gcode --load "$dir/slicer.ini" --center 90,90 --output "$work/slice/mount.gcode" "$work/slice/mount-print.stl"
prusa-slicer --export-gcode --load "$dir/slicer.ini" --output "$work/slice/plate.gcode" "$work/slice/plate-print.stl"
prusa-slicer --export-3mf --load "$dir/slicer.ini" --output "$dir/skyrim-horn-a1-mini.3mf" "$work/slice/plate-print.stl"
grep -E '^; (filament used \[g\]|estimated printing time)' "$work/slice/horn.gcode" "$work/slice/mount.gcode"
