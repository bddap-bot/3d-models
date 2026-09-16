#!/usr/bin/env python3
import re
import sys
import zipfile
from math import atan2, ceil, cos, hypot, pi, sin

import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection
from matplotlib.patches import Rectangle

source, target = sys.argv[1:]
with zipfile.ZipFile(source) as archive:
    gcode = archive.read("Metadata/plate_1.gcode").decode("utf-8")

groups = {"model": [], "support": [], "brim": []}
feature = "model"
x = y = None
for line in gcode.splitlines():
    if line.startswith("; FEATURE:"):
        name = line.partition(":")[2].strip().lower()
        feature = "support" if "support" in name else "brim" if name == "brim" else "model"
        continue
    if not line.startswith(("G0 ", "G1 ", "G2 ", "G3 ")):
        continue
    nx = re.search(r"(?:^| )X(-?(?:\d+(?:\.\d+)?|\.\d+))", line)
    ny = re.search(r"(?:^| )Y(-?(?:\d+(?:\.\d+)?|\.\d+))", line)
    ne = re.search(r"(?:^| )E(-?(?:\d+(?:\.\d+)?|\.\d+))", line)
    next_x = float(nx.group(1)) if nx else x
    next_y = float(ny.group(1)) if ny else y
    if x is not None and y is not None and next_x is not None and next_y is not None and ne:
        if line.startswith(("G2 ", "G3 ")):
            ni = re.search(r"(?:^| )I(-?(?:\d+(?:\.\d+)?|\.\d+))", line)
            nj = re.search(r"(?:^| )J(-?(?:\d+(?:\.\d+)?|\.\d+))", line)
            if ni and nj:
                cx, cy = x + float(ni.group(1)), y + float(nj.group(1))
                radius = hypot(x - cx, y - cy)
                start, end = atan2(y - cy, x - cx), atan2(next_y - cy, next_x - cx)
                delta = end - start
                if line.startswith("G2 ") and delta >= 0:
                    delta -= 2 * pi
                if line.startswith("G3 ") and delta <= 0:
                    delta += 2 * pi
                count = max(2, ceil(abs(delta) * radius))
                points = [(cx + radius * cos(start + delta * index / count), cy + radius * sin(start + delta * index / count)) for index in range(count + 1)]
                groups[feature].extend(zip(points, points[1:]))
        elif hypot(next_x - x, next_y - y) <= 5:
            groups[feature].append(((x, y), (next_x, next_y)))
    x, y = next_x, next_y

fig, axis = plt.subplots(figsize=(8, 8), dpi=180)
axis.add_patch(Rectangle((0, 0), 180, 180, facecolor="#f4f5f6", edgecolor="#343a40", linewidth=1.6))
for name, color, width, alpha in (("brim", "#6c757d", 0.3, 0.7), ("support", "#f59f00", 0.24, 0.35), ("model", "#111111", 0.18, 0.22)):
    axis.add_collection(LineCollection(groups[name], colors=color, linewidths=width, alpha=alpha, rasterized=True))
axis.set(xlim=(-5, 185), ylim=(-5, 185), aspect="equal", xlabel="X (mm)", ylabel="Y (mm)", title="Bambu A1 mini — OrcaSlicer plate")
axis.set_xticks(range(0, 181, 30))
axis.set_yticks(range(0, 181, 30))
axis.grid(color="#ced4da", linewidth=0.35)
fig.tight_layout()
fig.savefig(target)
