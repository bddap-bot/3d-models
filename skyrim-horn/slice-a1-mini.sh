#!/usr/bin/env bash
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
work=${BOTQ_JOB_DIR:-$dir}
scratch="$work/slice-a1-mini"
mkdir -p "$scratch"

openscad -q -o "$scratch/plate-print.stl" -D 'part="plate_print"' "$dir/skyrim-horn.scad"
exe=$(readlink -f "$(command -v orca-slicer)")
profiles=${exe%%/bin/*}/share/OrcaSlicer/profiles/BBL
jq -s 'add | del(.inherits) | .enable_support = "1" | .support_type = "normal(auto)"' "$profiles/process/fdm_process_common.json" "$profiles/process/fdm_process_single_common.json" "$profiles/process/fdm_process_single_0.20.json" "$profiles/process/0.20mm Standard @BBL P1P.json" "$profiles/process/0.20mm Standard @BBL A1M.json" > "$scratch/process.json"
jq -s 'add | del(.inherits) | .layer_change_gcode = ("G92 E0\n" + .layer_change_gcode)' "$profiles/machine/fdm_machine_common.json" "$profiles/machine/fdm_bbl_3dp_001_common.json" "$profiles/machine/Bambu Lab A1 mini 0.4 nozzle.json" > "$scratch/machine.json"
jq -s 'add | del(.inherits)' "$profiles/filament/fdm_filament_common.json" "$profiles/filament/fdm_filament_pla.json" "$profiles/filament/Generic PLA @base.json" "$profiles/filament/Generic PLA @BBL A1M.json" > "$scratch/filament.json"
xvfb-run -a orca-slicer --load-settings "$scratch/process.json;$scratch/machine.json" --load-filaments "$scratch/filament.json" --slice 0 --export-3mf skyrim-horn-a1-mini.gcode.3mf --outputdir "$dir" "$scratch/plate-print.stl"
grep -E '^(; model printing time|; printer_model|; filament used \[g\])' "$dir/plate_1.gcode"
