#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
output=${BOTQ_JOB_DIR:-$root/hopper/v3}/slices
mkdir -p "$output"

for candidate in a b; do
  stl="$root/hopper/v3/candidate-$candidate/out/candidate_$candidate.stl"
  gcode="$output/candidate_$candidate.gcode"
  prusa-slicer --export-gcode --load "$root/hopper/v3/slicer.ini" --center 90,90 --output "$gcode" "$stl"
  grep -E '^; (filament used \[g\]|estimated printing time)' "$gcode"
done
