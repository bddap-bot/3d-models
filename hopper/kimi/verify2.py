import sys
import numpy as np
import trimesh

OUT = sys.argv[1]

def load(n):
    return trimesh.load(f"{OUT}/{n}.stl")

body, lid, tray, interior = load("body"), load("lid"), load("tray"), load("interior")

print("== wall thickness (ray through both skins, expect >= 2.4 mm) ==")
def thick(mesh, origin, direction, label):
    origin = np.array(origin, float)
    direction = np.array(direction, float)
    locs, _, _ = mesh.ray.intersects_location(
        [origin], [direction], multiple_hits=True)
    t = (locs - origin) @ direction
    t = np.sort(t[t > 1e-6])
    if len(t) < 2:
        print(f"  {label}: FAIL only {len(t)} hits")
        return
    d = t[1] - t[0]
    print(f"  {label}: {d:.2f} mm  {'OK' if d >= 2.4 else 'FAIL'}")

thick(body, (69, 20, 90), (0, -1, 0), "body plate @z=90")
thick(body, (69, 20, 60), (0, -1, 0), "body plate @z=60")
thick(body, (20, -30, 100), (-1, 0, 0), "body left cheek")
thick(body, (69, -30, 100), (0, -1, 0), "body back wall")
thick(body, (69, -30, 150), (0, 0, 1), "body roof")
thick(tray, (65, 30, -5), (0, 0, 1), "tray floor")
thick(tray, (65, 10, 10), (0, -1, 0), "tray front wall")
thick(tray, (65, 70, 10), (0, 1, 0), "tray back wall")
thick(lid, (65, 20, 10), (0, 0, -1), "lid slab")

print("== outlet / wall angle / capacity (cavity mesh) ==")
size = interior.bounds[1] - interior.bounds[0]
print(f"  cavity XxYxZ = {size[0]:.0f} x {size[1]:.0f} x {size[2]:.0f} mm")
print(f"  outlet = {size[0]:.0f} x {size[1]:.0f} mm (need >= 50 x 50)")
n = interior.face_normals
walls = np.abs(n[:, 2]) < 0.01
ang = np.degrees(np.arccos(np.clip(np.abs(n[walls, 2]), 0, 1)))
print(f"  vertical-flow wall faces: {walls.sum()} faces, all "
      f"{ang.min():.0f}..{ang.max():.0f} deg from horizontal (need >= 60)")
print(f"  capacity = {interior.volume/1e6:.3f} L (need ~1)")

print("== fit ==")
v = body.vertices
p = v[(v[:, 1] >= 0) & (v[:, 1] <= 3) & (v[:, 0] >= 0) & (v[:, 0] <= 138)]
print(f"  plate extents X {p[:,0].min():.0f}..{p[:,0].max():.0f} "
      f"Z {p[:,2].min():.0f}..{p[:,2].max():.0f} (opening 140x170)")
c = v[(v[:, 0] < 0) | (v[:, 0] > 138)]
print(f"  bar clips span X {c[:,0].min():.0f}..{c[:,0].max():.0f}, "
      f"Z rows {np.unique(np.round(c[:,2],0))}")

print("== print-orientation overhangs (part frame) ==")
def region(mesh, mask, label):
    a = mesh.area_faces[mask].sum()
    print(f"  {label}: area {a:.0f} mm2")
    if a > 1:
        pts = mesh.vertices[mesh.faces[mask].reshape(-1)]
        print(f"    span X {pts[:,0].min():.0f}..{pts[:,0].max():.0f} "
              f"Y {pts[:,1].min():.0f}..{pts[:,1].max():.0f} "
              f"Z {pts[:,2].min():.0f}..{pts[:,2].max():.0f}")

print(" body printed X-up, part X=0 side on bed (part -X faces = down-facing):")
m = body.face_normals[:, 0] < -0.9
m &= body.triangles_center[:, 0] > 0.5
region(body, m, "  down-facing off-bed (needs support)")
big = m & (body.area_faces > 1000)
region(body, big, "  main support region")
print(" tray printed flat Z-up (part -Z faces off-bed):")
m = tray.face_normals[:, 2] < -0.9
m &= tray.triangles_center[:, 2] > 0.5
region(tray, m, "  down-facing off-bed (perch underside etc.)")
print(" lid printed ridge-up:")
lidup = lid.copy()
lidup.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [1, 0, 0]))
m = lidup.face_normals[:, 2] < -0.9
m &= lidup.triangles_center[:, 2] > lidup.bounds[0][2] + 0.5
region(lidup, m, "  down-facing off-bed")
