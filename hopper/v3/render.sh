#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)

render_candidate() {
  local dir=$1
  local name=$2
  mkdir -p "$dir/previews"
  xvfb-run -a openscad -q --render --viewall --autocenter --projection=p --imgsize=1200,900 \
    --camera=0,0,0,68,0,35,500 -D "part=\"$name\"" -o "$dir/previews/outside.png" "$dir/hopper.scad"
  xvfb-run -a openscad -q --render --viewall --autocenter --projection=p --imgsize=1200,900 \
    --camera=0,0,0,68,0,215,500 -D "part=\"$name\"" -o "$dir/previews/inside.png" "$dir/hopper.scad"
  xvfb-run -a openscad -q --render --viewall --autocenter --projection=p --imgsize=1200,900 \
    --camera=0,0,0,90,0,90,500 -D 'part="section"' -o "$dir/previews/section.png" "$dir/hopper.scad"
}

render_candidate "$root/hopper/v3/candidate-a" candidate_a
render_candidate "$root/hopper/v3/candidate-b" candidate_b
