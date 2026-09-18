import re
import zipfile
from itertools import combinations
from pathlib import Path

import numpy as np
import trimesh
from shapely.affinity import scale

root = Path(__file__).resolve().parent
BED = 180
MARGIN = 5
GAP = 5


def footprint(mesh, z):
    planar, _ = mesh.section(plane_origin=[0, 0, z], plane_normal=[0, 0, 1]).to_2D(to_2D=np.eye(4))
    return max(planar.polygons_full, key=lambda p: p.area)


def flat(body):
    assert body.is_watertight and body.is_winding_consistent
    assert abs(body.extents[2] - 4) < 0.001
    assert abs(body.bounds[0, 2]) < 0.001


def package(name, layers):
    with zipfile.ZipFile(root / name) as archive:
        assert archive.testzip() is None
        gcode = archive.read("Metadata/plate_1.gcode").decode()
    for setting in ["enable_support = 0", "brim_type = no_brim", "brim_width = 0", "filament_type = PLA", "printer_model = Bambu Lab A1 mini", "nozzle_diameter = 0.4", "layer_height = 0.2"]:
        assert "; " + setting + "\n" in gcode, setting
    assert "Support material" not in gcode
    assert re.search(rf"; total layer number: {layers}\b", gcode)
    printing = gcode[gcode.index("; CHANGE_LAYER"):]
    xy = np.array([(float(x), float(y)) for x, y in re.findall(r"^G1 X([-\d.]+) Y([-\d.]+) .*E[\d.]", printing, re.M)])
    assert xy.min() >= MARGIN and xy.max() <= BED - MARGIN, (xy.min(axis=0), xy.max(axis=0))
    estimate = [line for line in gcode.splitlines() if line.startswith(("; model printing time:", "; filament used [g]"))]
    return xy, estimate


mesh = trimesh.load(root / "out/batarang.stl", force="mesh")
flat(mesh)
assert len(mesh.split()) == 1
assert 93 <= mesh.extents[0] <= 97
polygon = footprint(mesh, 2)
error = polygon.symmetric_difference(scale(polygon, xfact=-1, origin=(0, 0))).area
assert error < 0.1, error
area = footprint(mesh, 0.1).area
assert area > 1000, area
xy, estimate = package("batarang-a1-mini.gcode.3mf", 20)
print(f"PASS: watertight, one solid; dimensions {mesh.extents.round(3)} mm; symmetry area error {error:.5f} mm²")
print(f"PASS: first-layer section {area:.1f} mm²; flat base; 20 layers; A1 mini/0.4 mm/PLA; no supports or brim")
print(*estimate, sep="\n")

plate = trimesh.load(root / "out/plate.stl", force="mesh")
copies = plate.split()
assert len(copies) >= 2
for copy in copies:
    flat(copy)
    assert abs(copy.volume - mesh.volume) < 0.01 * mesh.volume
    assert abs(copy.area - mesh.area) < 0.01 * mesh.area
assert np.all(plate.extents[:2] <= BED - 2 * MARGIN), plate.extents
outlines = [footprint(copy, 2) for copy in copies]
clearance = min(a.distance(b) for a, b in combinations(outlines, 2))
assert clearance >= GAP - 0.01, clearance
xy, estimate = package("batarang-a1-mini-plate.gcode.3mf", 20)
print(f"PASS: plate of {len(copies)} copies, each flat and identical to the single; footprint {plate.extents[:2].round(2)} mm; clearance {clearance:.2f} mm; extrusion within {xy.min(axis=0).round(1)}..{xy.max(axis=0).round(1)}")
print(*estimate, sep="\n")
