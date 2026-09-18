import re
import zipfile
from pathlib import Path

import numpy as np
import trimesh
from shapely.affinity import scale

root = Path(__file__).resolve().parent
mesh = trimesh.load(root / "out/batarang.stl", force="mesh")
assert mesh.is_watertight and mesh.is_winding_consistent
assert len(mesh.split()) == 1
assert mesh.volume > 0
assert 93 <= mesh.extents[0] <= 97
assert abs(mesh.extents[2] - 4) < 0.001
assert abs(mesh.bounds[0, 2]) < 0.001
section = mesh.section(plane_origin=[0, 0, 2], plane_normal=[0, 0, 1])
polygon = section.to_2D(to_2D=np.eye(4))[0].polygons_full[0]
error = polygon.symmetric_difference(scale(polygon, xfact=-1, origin=(0, 0))).area
assert error < 0.1, error
section = mesh.section(plane_origin=[0, 0, 0.1], plane_normal=[0, 0, 1])
planar, _ = section.to_2D(to_2D=np.eye(4))
area = sum(p.area for p in planar.polygons_full)
assert area > 1000, area
with zipfile.ZipFile(root / "batarang-a1-mini.gcode.3mf") as package:
    assert package.testzip() is None
    gcode = package.read("Metadata/plate_1.gcode").decode()
    for setting in ["enable_support = 0", "brim_type = no_brim", "brim_width = 0", "filament_type = PLA", "printer_model = Bambu Lab A1 mini", "nozzle_diameter = 0.4", "layer_height = 0.2"]:
        assert "; " + setting + "\n" in gcode, setting
    assert "Support material" not in gcode
    assert re.search(r"; total layer number: 20\b", gcode)
print(f"PASS: watertight, one solid; dimensions {mesh.extents.round(3)} mm; symmetry area error {error:.5f} mm²")
print(f"PASS: first-layer section {area:.1f} mm²; flat base; 20 layers; A1 mini/0.4 mm/PLA; no supports or brim")
for line in gcode.splitlines():
    if line.startswith(("; model printing time:", "; filament used [g]")):
        print(line)
