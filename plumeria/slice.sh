#!/usr/bin/env bash
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
scratch="${SCRATCH_DIR:-$dir}/plumeria-slice"
mkdir -p "$scratch"

case "${1:-single}" in
    single) plate=plumeria-a1-mini; bodies=("Single_Piece:#FFFFFF") ;;
    two-colour) plate=plumeria-two-colour-a1-mini; bodies=("Flowers:#FFFFFF" "Leaves:#057748") ;;
    *) echo "usage: $0 [single|two-colour]" >&2; exit 2 ;;
esac

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
    | jq '. + {curr_bed_type: "Textured PEI Plate", wall_loops: "3", top_shell_layers: "5", bottom_shell_layers: "4", sparse_infill_density: "15%", sparse_infill_pattern: "gyroid", enable_support: "0", enable_prime_tower: "0"}' \
    > "$scratch/process.json"
filaments=()
for i in "${!bodies[@]}"; do
    flatten filament "Generic PLA @BBL A1M" | jq --arg c "${bodies[$i]#*:}" '. + {filament_colour: [$c]}' > "$scratch/filament$i.json"
    filaments+=("$scratch/filament$i.json")
done

python3 - "$dir/source" "$scratch/plumeria.3mf" "${bodies[@]%%:*}" <<'PY'
import struct, sys, zipfile
src, out, names = sys.argv[1], sys.argv[2], sys.argv[3:]
meshes, parts, config = [], [], []
for i, name in enumerate(names, 1):
    data = open(f"{src}/Plumeria_{name}_165mm.stl", "rb").read()
    verts, index, tris = [], {}, []
    for t in range(struct.unpack_from("<I", data, 80)[0]):
        tri = []
        for v in range(3):
            x, y, z = struct.unpack_from("<3f", data, 84 + 50 * t + 12 + 12 * v)
            key = (x + 90, y + 90, z)
            if key not in index:
                index[key] = len(verts)
                verts.append(key)
            tri.append(index[key])
        tris.append(tri)
    meshes.append(
        f'<object id="{i}" type="model"><mesh><vertices>'
        + "".join(f'<vertex x="{x:.6f}" y="{y:.6f}" z="{z:.6f}"/>' for x, y, z in verts)
        + "</vertices><triangles>"
        + "".join(f'<triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in tris)
        + "</triangles></mesh></object>"
    )
    parts.append(f'<component objectid="{i}"/>')
    config.append(
        f'<part id="{i}" subtype="normal_part"><metadata key="name" value="{name}"/>'
        f'<metadata key="extruder" value="{i}"/></part>'
    )
top = len(names) + 1
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/></Types>')
    z.writestr("_rels/.rels", '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/></Relationships>')
    z.writestr("3D/3dmodel.model", '<?xml version="1.0" encoding="UTF-8"?><model unit="millimeter" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02"><resources>'
        + "".join(meshes) + f'<object id="{top}" type="model"><components>' + "".join(parts)
        + f'</components></object></resources><build><item objectid="{top}"/></build></model>')
    z.writestr("Metadata/model_settings.config", f'<?xml version="1.0" encoding="UTF-8"?><config><object id="{top}"><metadata key="name" value="plumeria"/><metadata key="extruder" value="1"/>'
        + "".join(config) + "</object></config>")
PY

(cd "$scratch" && xvfb-run -a orca-slicer \
    --load-settings "$scratch/machine.json;$scratch/process.json" \
    --load-filaments "$(IFS=';'; echo "${filaments[*]}")" \
    --ensure-on-bed --arrange 0 --slice 0 \
    --export-3mf "$plate.gcode.3mf" \
    --outputdir . \
    "$scratch/plumeria.3mf")
mv "$scratch/$plate.gcode.3mf" "$dir/"
unzip -p "$dir/$plate.gcode.3mf" Metadata/plate_1.gcode > "$scratch/plate_1.gcode"
grep -E '^; (model printing time|total estimated time|filament used \[(g|mm)\]|layer_height|wall_loops|top_shell_layers|bottom_shell_layers|sparse_infill_density|sparse_infill_pattern|enable_support|brim_type|curr_bed_type|filament_colour)[ :]' "$scratch/plate_1.gcode"
