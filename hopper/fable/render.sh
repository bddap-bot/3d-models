#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
for p in body_R body_L lid bracket tray; do
  openscad -q -D "part=\"$p\"" -o "$p.stl" hopper.scad 2>&1 | grep -v '^$' || true
done
openscad -q -D 'part="assembly"' -o assembly.stl hopper.scad
