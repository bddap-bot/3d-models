import sys
import numpy as np
import trimesh
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

OUT = sys.argv[1]

def plot(parts, path, elev=22, azim=-125, title=""):
    fig = plt.figure(figsize=(10, 8))
    ax = fig.add_subplot(111, projection="3d")
    allv = []
    for mesh, color, off in parts:
        v = mesh.vertices + np.array(off)
        allv.append(v)
        tris = v[mesh.faces]
        pc = Poly3DCollection(tris, alpha=1.0)
        pc.set_facecolor(color)
        pc.set_edgecolor((0, 0, 0, 0.15))
        ax.add_collection3d(pc)
    allv = np.concatenate(allv)
    mn, mx = allv.min(0), allv.max(0)
    ctr, r = (mn + mx) / 2, (mx - mn).max() / 2 * 1.1
    ax.set_xlim(ctr[0] - r, ctr[0] + r)
    ax.set_ylim(ctr[1] - r, ctr[1] + r)
    ax.set_zlim(ctr[2] - r, ctr[2] + r)
    ax.set_box_aspect((1, 1, 1))
    ax.view_init(elev=elev, azim=azim)
    ax.set_xlabel("X (door width)"); ax.set_ylabel("Y (+ = outside)")
    ax.set_zlabel("Z (up)"); ax.set_title(title)
    fig.savefig(path, dpi=110, bbox_inches="tight")
    plt.close(fig)
    print("wrote", path)

body = trimesh.load(f"{OUT}/body.stl")
lid = trimesh.load(f"{OUT}/lid.stl")
tray = trimesh.load(f"{OUT}/tray.stl")

lv = lid.vertices
lid_asm = trimesh.Trimesh(
    vertices=np.column_stack([lv[:, 0], -lv[:, 2], lv[:, 1]]) + [4, 6, 114],
    faces=lid.faces, process=False)

plot([(body, "lightsteelblue", (0, 0, 0)),
      (lid_asm, "khaki", (0, 0, 0)),
      (tray, "salmon", (4, -73, 25))],
     f"{OUT}/assembly.png", title="assembled hopper (view from inside cage, front-right)")
plot([(body, "lightsteelblue", (0, 0, 0)),
      (lid_asm, "khaki", (0, 0, 0)),
      (tray, "salmon", (4, -73, 25))],
     f"{OUT}/assembly_outside.png", elev=18, azim=55,
     title="assembled hopper (view from outside cage)")
plot([(body, "lightsteelblue", (0, 0, 0))], f"{OUT}/body.png", title="body")
plot([(lid, "khaki", (0, 0, 0))], f"{OUT}/lid.png", elev=25, azim=-60, title="fill-port lid")
plot([(tray, "salmon", (0, 0, 0))], f"{OUT}/tray.png", elev=25, azim=-120, title="feed tray + perch")
