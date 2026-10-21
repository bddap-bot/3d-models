import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def check_rim(path):
    vertices = [
        tuple(map(float, line.split()[1:]))
        for line in path.read_text().splitlines()
        if line.lstrip().startswith("vertex")
    ]
    assert vertices and len(vertices) % 3 == 0, f"{path}: missing triangles"
    top = max(v[2] for v in vertices)
    caps = sum(
        all(v[2] == top for v in vertices[i:i + 3])
        for i in range(0, len(vertices), 3)
    )
    assert caps == 0, f"{path}: {caps} flat triangles at the cone's top edge"


check_rim(ROOT / "out/spool_small.stl")
with tempfile.TemporaryDirectory() as tmp:
    for attempt in range(3):
        fresh = Path(tmp) / f"small-{attempt}.stl"
        subprocess.run([
            "openscad", "-q", "-o", str(fresh), '-Dpart="spool_small"',
            str(ROOT / "cable-spool.scad"),
        ], check=True)
        check_rim(fresh)
print("small spool: committed mesh and 3 fresh exports have no flat top-edge triangles")
