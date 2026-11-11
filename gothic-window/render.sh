#!/usr/bin/env nix-shell
#!nix-shell shell.nix -i bash
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
stl=$(mktemp -d)
trap 'rm -rf "$stl"' EXIT

for part in pane rim tracery_a leading_a cells_a; do
    openscad -q -o "$stl/row-${part%_a}.stl" -Dbed=1000 -Dgap=8 -D'plates=[[0,1,2,3,4,5,6,7]]' -Dpart="\"$part\"" "$dir/gothic-window.scad"
    openscad -q -o "$stl/pair-${part%_a}.stl" -Dbed=1000 -Dgap=8 -D'plates=[[3,5]]' -Dpart="\"$part\"" "$dir/gothic-window.scad"
done
blender -b --factory-startup --python-exit-code 1 -P "$dir/render.py" -- "$stl" "$dir"
