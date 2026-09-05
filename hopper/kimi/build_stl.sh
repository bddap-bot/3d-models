#!/usr/bin/env bash
set -e
cd /home/bot/.cache/botq-wt/3279
OUT="$BOTQ_ARTIFACTS_DIR"
for p in body lid tray interior; do
  openscad -o "$OUT/$p.stl" -D "part=\"$p\"" hopper.scad 2>&1 | grep -Ei 'error|warn|cavity|outlet' || true
done
ls -la "$OUT"
