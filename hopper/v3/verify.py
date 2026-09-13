import json
import math
import os
import subprocess
import tempfile
from pathlib import Path

import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parents[2]
V3 = ROOT / "hopper" / "v3"
SCRATCH = Path(os.environ.get("BOTQ_JOB_DIR", V3))

CANDIDATES = {
    "candidate-a": {
        "name": "candidate_a",
        "escape": ["pull_interference", "lift_interference"],
        "capacity_range": (0.95, 1.08),
        "door_min_clearance": 2.7,
        "probes": [
            ((-60, -50, 100), (1, 0, 0), 3.15),
            ((0, 5, 100), (0, -1, 0), 3.15),
            ((-60, 25, 18), (1, 0, 0), 3.15),
        ],
    },
    "candidate-b": {
        "name": "candidate_b",
        "escape": ["pull_interference"],
        "capacity_range": (0.95, 1.08),
        "door_min_clearance": 2.7,
        "probes": [
            ((-60, -70, 100), (1, 0, 0), 3.15),
            ((-60, 25, 18), (1, 0, 0), 3.15),
            ((60, -70, 100), (-1, 0, 0), 3.15),
        ],
    },
}


def export(source, output, part, allow_empty=False):
    result = subprocess.run(
        ["openscad", "-q", f'-Dpart="{part}"', "-o", str(output), str(source)],
        check=False,
    )
    if result.returncode and not allow_empty:
        raise subprocess.CalledProcessError(result.returncode, result.args)


def mesh(path):
    loaded = trimesh.load(path, force="mesh")
    loaded.merge_vertices()
    return loaded


def first_wall_span(model, origin, direction):
    origin = np.asarray(origin, dtype=float)
    direction = np.asarray(direction, dtype=float)
    locations, _, _ = model.ray.intersects_location(
        ray_origins=[origin], ray_directions=[direction], multiple_hits=True
    )
    distances = sorted(
        {
            round(float(np.dot(location - origin, direction)), 5)
            for location in locations
            if np.dot(location - origin, direction) >= 0
        }
    )
    if len(distances) < 2:
        raise AssertionError(f"wall probe has {len(distances)} intersections")
    return distances[1] - distances[0]


def overhang_area(model):
    bed = model.bounds[0, 2]
    airborne = model.triangles_center[:, 2] > bed + 0.3
    downward = model.face_normals[:, 2] < -math.sin(math.radians(45))
    return float(model.area_faces[airborne & downward].sum())


def bed_contact_area(model):
    bed = model.bounds[0, 2]
    on_bed = np.all(np.abs(model.triangles[:, :, 2] - bed) < 0.001, axis=1)
    return float(model.area_faces[on_bed].sum())


results = {}
with tempfile.TemporaryDirectory(dir=SCRATCH) as tmp_name:
    tmp = Path(tmp_name)
    for directory, spec in CANDIDATES.items():
        source = V3 / directory / "hopper.scad"
        final_path = V3 / directory / "out" / f'{spec["name"]}.stl'
        final = mesh(final_path)
        assert final.is_watertight
        assert final.body_count == 1
        assert float(final.extents.max()) <= 180

        capacity_path = tmp / f"{directory}-capacity.stl"
        door_path = tmp / f"{directory}-door.stl"
        outlet_path = tmp / f"{directory}-outlet.stl"
        inlet_path = tmp / f"{directory}-inlet.stl"
        export(source, capacity_path, "capacity")
        export(source, door_path, "door_section")
        export(source, outlet_path, "outlet_probe")
        export(source, inlet_path, "inlet_probe")
        capacity_mesh = mesh(capacity_path)
        capacity_l = abs(capacity_mesh.volume) / 1_000_000
        assert spec["capacity_range"][0] <= capacity_l <= spec["capacity_range"][1]
        door_width = float(mesh(door_path).extents[0])
        clearance = (110 - door_width) / 2
        assert clearance >= spec["door_min_clearance"]
        outlet = mesh(outlet_path)
        inlet = mesh(inlet_path)
        outlet_width = float(outlet.extents[0])
        outlet_depth = abs(float(outlet.volume)) / outlet_width / 0.5
        assert min(outlet_width, outlet_depth) >= 50
        inlet_width = float(inlet.extents[0])
        inlet_depth = abs(float(inlet.volume)) / inlet_width / 0.5
        assert min(inlet_width, inlet_depth) >= 70
        inclinations = np.degrees(np.arccos(np.clip(np.abs(capacity_mesh.face_normals[:, 2]), 0, 1)))
        flow_wall_angle = float(inclinations[inclinations > 45].min())
        assert flow_wall_angle >= 65

        static_path = tmp / f"{directory}-static.stl"
        export(source, static_path, "static_interference", allow_empty=True)
        assert not static_path.exists()
        for part in ["inlet_blockage", "outlet_blockage"]:
            blockage_path = tmp / f"{directory}-{part}.stl"
            export(source, blockage_path, part, allow_empty=True)
            assert not blockage_path.exists()

        if directory == "candidate-a":
            install_path = tmp / f"{directory}-install.stl"
            export(source, install_path, "hook_snap_interference")
            hook_snap_interference = abs(mesh(install_path).volume)
            assert hook_snap_interference > 0

        escape_volumes = {}
        for part in spec["escape"]:
            escape_path = tmp / f"{directory}-{part}.stl"
            export(source, escape_path, part)
            assert escape_path.exists()
            escape_volume = abs(mesh(escape_path).volume)
            assert escape_volume > 1
            escape_volumes[part] = round(escape_volume, 3)

        thicknesses = [
            first_wall_span(final, origin, direction)
            for origin, direction, _ in spec["probes"]
        ]
        for thickness, (_, _, minimum) in zip(thicknesses, spec["probes"]):
            assert thickness >= minimum

        results[directory] = {
            "watertight": final.is_watertight,
            "bodies": final.body_count,
            "bbox_mm": [round(float(value), 3) for value in final.extents],
            "capacity_l": round(capacity_l, 4),
            "outlet_mm": [round(outlet_width, 3), round(outlet_depth, 3)],
            "inlet_mm": [round(inlet_width, 3), round(inlet_depth, 3)],
            "inlet_and_outlet_blockage": "empty",
            **(
                {"hook_snap_interference_mm3": round(hook_snap_interference, 3)}
                if directory == "candidate-a"
                else {}
            ),
            "outlet_to_25_mm_slice_ratio": round(min(outlet_width, outlet_depth) / 25, 2),
            "shallowest_flow_wall_deg": round(flow_wall_angle, 2),
            "door_section_width_mm": round(door_width, 3),
            "clearance_each_side_at_110_mm": round(clearance, 3),
            "static_cage_intersection": "empty",
            "escape_intersection_mm3": escape_volumes,
            "wall_probe_mm": [round(value, 3) for value in thicknesses],
            "overhang_area_over_45_deg_mm2": round(overhang_area(final), 1),
            "bed_contact_area_mm2": round(bed_contact_area(final), 1),
        }

expected = json.loads((V3 / "verification.json").read_text())
print(json.dumps(results, indent=2))
assert results == expected
