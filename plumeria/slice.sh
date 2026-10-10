#!/usr/bin/env bash
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
scratch="${SCRATCH_DIR:-$dir}/plumeria-slice"
mkdir -p "$scratch"

exe=$(readlink -f "$(command -v orca-slicer)")
profiles=${exe%%/bin/*}/share/OrcaSlicer/profiles/BBL

flatten() {
    local f="$profiles/$1/$2.json" parent
    parent=$(jq -r '.inherits // empty' "$f")
    if [ -n "$parent" ]; then
        jq -s '.[0] * .[1] | del(.inherits)' <(flatten "$1" "$parent") "$f"
    else
        cat "$f"
    fi
}

flatten machine "Bambu Lab A1 mini 0.4 nozzle" > "$scratch/machine.json"
flatten process "0.16mm Optimal @BBL A1M" \
    | jq '. + {curr_bed_type: "Textured PEI Plate", wall_loops: "3", top_shell_layers: "5", bottom_shell_layers: "4", sparse_infill_density: "15%", sparse_infill_pattern: "gyroid", enable_support: "0"}' \
    > "$scratch/process.json"
flatten filament "Generic PLA @BBL A1M" | jq '. + {filament_colour: ["#FFFFFF"]}' > "$scratch/filament.json"

python3 - "$dir/source/Plumeria_Single_Piece_165mm.stl" "$scratch/plumeria.stl" <<'PY'
import struct, sys
data = bytearray(open(sys.argv[1], "rb").read())
for t in range(struct.unpack_from("<I", data, 80)[0]):
    for v in range(3):
        o = 84 + 50 * t + 12 + 12 * v
        x, y, z = struct.unpack_from("<3f", data, o)
        struct.pack_into("<3f", data, o, x + 90, y + 90, z)
open(sys.argv[2], "wb").write(data)
PY

(cd "$scratch" && xvfb-run -a orca-slicer \
    --load-settings "$scratch/machine.json;$scratch/process.json" \
    --load-filaments "$scratch/filament.json" \
    --ensure-on-bed --arrange 0 --slice 0 \
    --export-3mf plumeria-a1-mini.gcode.3mf \
    --outputdir . \
    "$scratch/plumeria.stl")
mv "$scratch/plumeria-a1-mini.gcode.3mf" "$dir/"
unzip -p "$dir/plumeria-a1-mini.gcode.3mf" Metadata/plate_1.gcode > "$scratch/plate_1.gcode"
grep -E '^; (model printing time|total estimated time|filament used \[g\]|layer_height|wall_loops|top_shell_layers|bottom_shell_layers|sparse_infill_density|sparse_infill_pattern|enable_support|brim_type|curr_bed_type) ' "$scratch/plate_1.gcode"
