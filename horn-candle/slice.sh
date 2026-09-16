#!/usr/bin/env bash
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
work=${BOTQ_JOB_DIR:-$dir}
scratch="$work/horn-candle-slice"
mkdir -p "$scratch"

exe=$(readlink -f "$(command -v orca-slicer)")
profiles=${exe%%/bin/*}/share/OrcaSlicer/profiles/BBL
jq -s 'add | del(.inherits) | .enable_support = "1" | .support_type = "tree(auto)" | .support_style = "organic" | .curr_bed_type = "Textured PEI Plate" | .brim_type = "outer_only" | .brim_width = "5" | .brim_object_gap = "0" | .initial_layer_speed = "20" | .initial_layer_infill_speed = "20"' \
    "$profiles/process/fdm_process_common.json" \
    "$profiles/process/fdm_process_single_common.json" \
    "$profiles/process/fdm_process_single_0.20.json" \
    "$profiles/process/0.20mm Standard @BBL P1P.json" \
    "$profiles/process/0.20mm Standard @BBL A1M.json" > "$scratch/process.json"
jq -s 'add | del(.inherits) | .layer_change_gcode = ("G92 E0\n" + .layer_change_gcode)' \
    "$profiles/machine/fdm_machine_common.json" \
    "$profiles/machine/fdm_bbl_3dp_001_common.json" \
    "$profiles/machine/Bambu Lab A1 mini 0.4 nozzle.json" > "$scratch/machine.json"
jq -s 'add | del(.inherits) | .filament_colour = ["#000000"] | .filament_settings_id = ["Generic PLA @BBL A1M"] | .textured_plate_temp = ["65"] | .textured_plate_temp_initial_layer = ["65"] | .hot_plate_temp = ["65"] | .hot_plate_temp_initial_layer = ["65"] | .close_fan_the_first_x_layers = ["5"] | .notes = "black PLA; external spool"' \
    "$profiles/filament/fdm_filament_common.json" \
    "$profiles/filament/fdm_filament_pla.json" \
    "$profiles/filament/Generic PLA @base.json" \
    "$profiles/filament/Generic PLA @BBL A1M.json" > "$scratch/filament.json"

for plate in 1 2; do
    plate_dir="$scratch/plate-$plate"
    mkdir -p "$plate_dir"
    (cd "$plate_dir" && xvfb-run -a orca-slicer \
        --load-settings "$scratch/process.json;$scratch/machine.json" \
        --load-filaments "$scratch/filament.json" \
        --ensure-on-bed --arrange 1 --slice 0 \
        --export-3mf "horn-candle-plate-$plate.gcode.3mf" \
        --outputdir . \
        "$dir/source/unpacked/candle bottom.stl" \
        "$dir/source/unpacked/candle top.stl")
    mv "$plate_dir/horn-candle-plate-$plate.gcode.3mf" "$dir/"
    mv "$plate_dir/plate_1.gcode" "$scratch/plate-$plate.gcode"
    grep -E '^(; model printing time|; total estimated time|; printer_model|; filament used \[g\]|; filament_type|; filament_colour|; enable_support|; support_type|; support_style|; layer_height|; notes|; curr_bed_type|; brim_type|; brim_width|; initial_layer_speed|; initial_layer_infill_speed|; textured_plate_temp|; textured_plate_temp_initial_layer|; close_fan_the_first_x_layers)' "$scratch/plate-$plate.gcode"
done
