#!/usr/bin/env bash
set -euo pipefail
dir=$(cd "$(dirname "$0")" && pwd)
scratch="${BOTQ_JOB_DIR:-$dir}/batarang-slice"
mkdir -p "$scratch"
exe=$(readlink -f "$(command -v orca-slicer)")
profiles=${exe%%/bin/*}/share/OrcaSlicer/profiles/BBL
jq -s 'add | del(.inherits) | .enable_support = "0" | .brim_type = "outer_only" | .brim_width = "5" | .brim_object_gap = "0" | .initial_layer_infill_speed = .initial_layer_speed | .curr_bed_type = "Textured PEI Plate"' "$profiles/process/fdm_process_common.json" "$profiles/process/fdm_process_single_common.json" "$profiles/process/fdm_process_single_0.20.json" "$profiles/process/0.20mm Standard @BBL P1P.json" "$profiles/process/0.20mm Standard @BBL A1M.json" > "$scratch/process.json"
jq -s 'add | del(.inherits) | .layer_change_gcode = ("G92 E0\n" + .layer_change_gcode)' "$profiles/machine/fdm_machine_common.json" "$profiles/machine/fdm_bbl_3dp_001_common.json" "$profiles/machine/Bambu Lab A1 mini 0.4 nozzle.json" > "$scratch/machine.json"
jq -s 'add | del(.inherits) | .filament_colour = ["#000000"] | .filament_settings_id = ["Generic PLA @BBL A1M"]' "$profiles/filament/fdm_filament_common.json" "$profiles/filament/fdm_filament_pla.json" "$profiles/filament/Generic PLA @base.json" "$profiles/filament/Generic PLA @BBL A1M.json" > "$scratch/filament.json"
slice() {
    (cd "$scratch" && xvfb-run -a orca-slicer --load-settings "$scratch/process.json;$scratch/machine.json" --load-filaments "$scratch/filament.json;$scratch/filament.json;$scratch/filament.json" --load-filament-ids "3" --slice 0 --export-3mf "$1.gcode.3mf" --outputdir "$scratch" "$dir/out/$2.stl")
    mv "$scratch/$1.gcode.3mf" "$dir/"
    mv "$scratch/plate_1.gcode" "$scratch/$2.gcode"
    grep -E '^(; model printing time|; total estimated time|; printer_model|; filament used \[g\]|; filament_type|; filament_colour|; enable_support|; layer_height|; curr_bed_type|; brim_type|; brim_width|; brim_object_gap|; initial_layer_speed|; initial_layer_infill_speed)' "$scratch/$2.gcode"
}
slice batarang-a1-mini-plate plate
