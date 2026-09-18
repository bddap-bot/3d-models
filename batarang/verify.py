import re
import zipfile
from itertools import combinations
from pathlib import Path

import numpy as np
import trimesh
from shapely.affinity import scale, translate
from shapely.geometry import LineString
from shapely.ops import unary_union
from PIL import Image, ImageDraw

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


def package(name, layers, brim=False):
    with zipfile.ZipFile(root / name) as archive:
        assert archive.testzip() is None
        gcode = archive.read("Metadata/plate_1.gcode").decode()
    for setting in ["enable_support = 0", "printer_model = Bambu Lab A1 mini", "nozzle_diameter = 0.4", "layer_height = 0.2"]:
        assert "; " + setting + "\n" in gcode, setting
    settings = ["curr_bed_type = Textured PEI Plate"]
    if brim:
        settings += ["brim_type = outer_only", "brim_width = 5", "brim_object_gap = 0",
                     "filament_type = PLA;PLA;PLA", "filament_colour = #000000;#000000;#000000",
                     "initial_layer_speed = 50", "initial_layer_infill_speed = 50"]
        assert "\nM620 S2A" in gcode and "\nT2\n" in gcode
        assert re.search(r"; filament used \[g\] = 0.00, 0.00, [1-9]", gcode)
    else:
        settings += ["brim_type = no_brim", "brim_width = 0", "filament_type = PLA"]
    for setting in settings:
        assert "; " + setting + "\n" in gcode, setting
    assert "Support material" not in gcode
    assert re.search(rf"; total layer number: {layers}\b", gcode)
    printing = gcode[gcode.index("; CHANGE_LAYER"):]
    xy = np.array([(float(x), float(y)) for x, y in re.findall(r"^G1 X([-\d.]+) Y([-\d.]+) .*E[\d.]", printing, re.M)])
    assert xy.min() >= (0.25 if brim else MARGIN) and xy.max() <= BED - (0.25 if brim else MARGIN), (xy.min(axis=0), xy.max(axis=0))
    estimate = [line for line in gcode.splitlines() if line.startswith(("; model printing time:", "; filament used [g]"))]
    return xy, estimate, gcode


mesh = trimesh.load(root / "out/batarang.stl", force="mesh")
flat(mesh)
assert len(mesh.split()) == 1
assert 93 <= mesh.extents[0] <= 97
polygon = footprint(mesh, 2)
error = polygon.symmetric_difference(scale(polygon, xfact=-1, origin=(0, 0))).area
assert error < 0.1, error
area = footprint(mesh, 0.1).area
assert area > 1000, area
xy, estimate, gcode = package("batarang-a1-mini.gcode.3mf", 20)
print(f"PASS: watertight, one solid; dimensions {mesh.extents.round(3)} mm; symmetry area error {error:.5f} mm²")
print(f"PASS: first-layer section {area:.1f} mm²; flat base; 20 layers; A1 mini/0.4 mm/PLA; no supports or brim")
print(*estimate, sep="\n")

plate = trimesh.load(root / "out/plate.stl", force="mesh")
copies = plate.split()
assert len(copies) == 8
for copy in copies:
    flat(copy)
    assert abs(copy.volume - mesh.volume) < 0.01 * mesh.volume
    assert abs(copy.area - mesh.area) < 0.01 * mesh.area
assert np.all(plate.extents[:2] <= BED - 2 * MARGIN), plate.extents
outlines = [footprint(copy, 2) for copy in copies]
clearance = min(a.distance(b) for a, b in combinations(outlines, 2))
assert clearance >= GAP - 0.01, clearance
xy, estimate, gcode = package("batarang-a1-mini-plate.gcode.3mf", 20, brim=True)
print(f"PASS: plate of {len(copies)} copies, each flat and identical to the single; footprint {plate.extents[:2].round(2)} mm; clearance {clearance:.2f} mm; extrusion within {xy.min(axis=0).round(1)}..{xy.max(axis=0).round(1)}")
print(*estimate, sep="\n")

# Preview the actual first-layer extrusion paths, not a model-only render.
first = gcode.split("; CHANGE_LAYER")[1]
position = None
feature = ""
segments = []
brim_lines = []
feed = 0
for line in first.splitlines():
    if line.startswith("; FEATURE: "):
        feature = line.removeprefix("; FEATURE: ")
    command = line.split(" ")[0]
    if command not in ("G0", "G1", "G2", "G3"):
        continue
    values = {k: float(v) for k, v in re.findall(r"([XYEFIJ])(-?(?:\d+(?:\.\d*)?|\.\d+))", line)}
    feed = values.get("F", feed)
    if "X" not in values and "Y" not in values:
        continue
    point = (values.get("X", position[0] if position else 0), values.get("Y", position[1] if position else 0))
    if values.get("E", 0) > 0 and position is not None:
        assert feed <= 50 * 60, feed
        points = [position, point]
        if command in ("G2", "G3"):
            center = np.array(position) + [values.get("I", 0), values.get("J", 0)]
            start = np.array(position) - center
            end = np.array(point) - center
            angle = np.arctan2(start[1], start[0])
            sweep = (np.arctan2(end[1], end[0]) - angle) % (2 * np.pi)
            if command == "G2":
                sweep -= 2 * np.pi
            radius = np.linalg.norm(start)
            angles = np.linspace(angle, angle + sweep, max(2, int(abs(sweep) * radius / 0.1) + 2))
            points = [position, *(center + radius * np.array([np.cos(a), np.sin(a)]) for a in angles[1:-1]), point]
        assert np.min(points) >= 0.25 and np.max(points) <= BED - 0.25
        for a, b in zip(points, points[1:]):
            segments.append((a, b, feature))
        if feature == "Brim":
            brim_lines.append(LineString(points))
    position = point
assert brim_lines
# The slicer recentres the unchanged mesh onto the bed.
shift = np.array([90, 90]) - plate.bounds.mean(axis=0)[:2]
brim_area = unary_union(brim_lines).buffer(0.251)
for copy in copies:
    base = translate(footprint(copy, 0.1), *shift)
    coverage = base.boundary.intersection(brim_area.buffer(0.03)).length / base.length
    assert coverage > 0.98, coverage
print("PASS: continuous zero-gap brim contacts >98% of every copy perimeter; all first-layer extrusion <=50 mm/s; black PLA tool T2 (AMS slot 3)")
image = Image.new("RGB", (1200, 1260), "white")
draw = ImageDraw.Draw(image)
def pixel(p):
    return (60 + p[0] * 6, 1140 - p[1] * 6)
draw.rectangle((60, 60, 1140, 1140), fill="#ececec", outline="#777777", width=2)
for a, b, role in segments:
    draw.line((pixel(a), pixel(b)), fill="#c57c17" if role == "Brim" else "#20252b", width=3)
draw.text((60, 1170), "A1 mini | 180 x 180 mm | first-layer toolpaths | 8 copies", fill="black")
draw.text((60, 1200), "Gold: 5 mm outer brim, zero gap | Black: PLA, AMS slot 3 | Textured PEI | 50 mm/s", fill="black")
image.save(root / "plate.png")
print("PASS: plate.png generated from packaged first-layer G-code")
