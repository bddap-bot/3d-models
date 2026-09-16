#!/usr/bin/env bash
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
work=${BOTQ_JOB_DIR:-$dir}
scratch="$work/slice-a1-mini"
mkdir -p "$scratch"

exe=$(readlink -f "$(command -v orca-slicer)")
profiles=${exe%%/bin/*}/share/OrcaSlicer/profiles/BBL
jq -s 'add | del(.inherits) | .enable_support = "1" | .support_type = "normal(auto)"' "$profiles/process/fdm_process_common.json" "$profiles/process/fdm_process_single_common.json" "$profiles/process/fdm_process_single_0.20.json" "$profiles/process/0.20mm Standard @BBL P1P.json" "$profiles/process/0.20mm Standard @BBL A1M.json" > "$scratch/process.json"
jq -s 'add | del(.inherits) | .layer_change_gcode = ("G92 E0\n" + .layer_change_gcode)' "$profiles/machine/fdm_machine_common.json" "$profiles/machine/fdm_bbl_3dp_001_common.json" "$profiles/machine/Bambu Lab A1 mini 0.4 nozzle.json" > "$scratch/machine.json"
jq -s 'add | del(.inherits)' "$profiles/filament/fdm_filament_common.json" "$profiles/filament/fdm_filament_pla.json" "$profiles/filament/Generic PLA @base.json" "$profiles/filament/Generic PLA @BBL A1M.json" > "$scratch/filament.json"

slice_part() {
    local name=$1
    local source=$2
    local colour=$3
    openscad -q -o "$scratch/$name.stl" -D "part=\"${name}_print\"" "$dir/skyrim-horn.scad"
    jq --arg colour "$colour" --arg source "$source" '.filament_colour = [$colour] | .filament_settings_id = ["Generic PLA @BBL A1M"] | .notes = $source' "$scratch/filament.json" > "$scratch/$name-filament.json"
    jq --arg source "$source" '.notes = $source' "$scratch/process.json" > "$scratch/$name-process.json"
    if [ "$name" = mount ]; then
        jq '.textured_plate_temp = ["65"] | .textured_plate_temp_initial_layer = ["65"] | .hot_plate_temp = ["65"] | .hot_plate_temp_initial_layer = ["65"] | .close_fan_the_first_x_layers = ["5"]' "$scratch/$name-filament.json" > "$scratch/$name-filament.tmp"
        mv "$scratch/$name-filament.tmp" "$scratch/$name-filament.json"
        jq '.curr_bed_type = "Textured PEI Plate" | .brim_type = "outer_only" | .brim_width = "5" | .brim_object_gap = "0" | .initial_layer_speed = "25" | .initial_layer_infill_speed = "25"' "$scratch/$name-process.json" > "$scratch/$name-process.tmp"
        mv "$scratch/$name-process.tmp" "$scratch/$name-process.json"
    fi
    xvfb-run -a orca-slicer --load-settings "$scratch/$name-process.json;$scratch/machine.json" --load-filaments "$scratch/$name-filament.json" --slice 0 --export-3mf "skyrim-horn-$name-a1-mini.gcode.3mf" --outputdir "$dir" "$scratch/$name.stl"
    mv "$dir/plate_1.gcode" "$scratch/$name.gcode"
    grep -E '^(; model printing time|; printer_model|; filament used \[g\]|; filament_type|; filament_colour|; enable_support|; support_type|; layer_height|; notes|; curr_bed_type|; brim_type|; brim_width|; initial_layer_speed|; initial_layer_infill_speed|; textured_plate_temp|; textured_plate_temp_initial_layer|; close_fan_the_first_x_layers)' "$scratch/$name.gcode"
}

slice_part horn "tan PLA; external spool" "#D7B982"
slice_part mount "black PLA; AMS slot" "#25211F"
