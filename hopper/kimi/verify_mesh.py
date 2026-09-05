import sys
import numpy as np
import trimesh

OUT = sys.argv[1]
ok = True
for name in ["body", "lid", "tray", "interior"]:
    m = trimesh.load(f"{OUT}/{name}.stl")
    bb = m.bounds
    size = bb[1] - bb[0]
    wt = bool(m.is_watertight)
    ok = ok and wt
    vol = m.volume if wt else float("nan")
    print(f"{name}: watertight={wt} winding={bool(m.is_winding_consistent)} "
          f"size={np.round(size,2)} maxdim={size.max():.1f} "
          f"vol_mm3={vol:.0f} euler={m.euler_number} faces={len(m.faces)}")
print("ALL_WATERTIGHT" if ok else "NOT_ALL_WATERTIGHT")
