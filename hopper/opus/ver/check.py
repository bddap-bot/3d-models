import json
import numpy as np, trimesh
LIMIT=175.0
parts=["mount","shell_left","shell_right","lid","tray","perch","seedvol"]
print(f"{'part':12} {'wtight':7} {'wind':5} {'euler':6} {'bodies':6} {'vol_cm3':9} {'bbox (mm)':28} {'<=175'}")
for p in parts:
    m=trimesh.load(f"stl/{p}.stl", process=True); m.merge_vertices()
    e=m.extents
    print(f"{p:12} {str(m.is_watertight):7} {str(m.is_winding_consistent):5} {m.euler_number:6d} {m.body_count:6d} {m.volume/1000:9.2f} "
          f"{'x'.join(f'{v:.1f}' for v in e):28} {max(e)<=LIMIT}")
