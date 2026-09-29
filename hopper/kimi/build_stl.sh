#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
OUT="${1:?usage: $0 OUTPUT_DIR}"
mkdir -p "$OUT"
for p in body lid tray interior; do
  openscad -o "$OUT/$p.stl" -D "part=\"$p\"" hopper.scad 2>&1 | grep -Ei 'error|warn|cavity|outlet' || true
done
ls -la "$OUT"
