import numpy as np, trimesh
from thick import thickness
m = trimesh.load("body_R.stl", process=True); m.merge_vertices()
print("faces", len(m.faces), "verts", len(m.vertices), "watertight", m.is_watertight, "volume", m.volume)
pts, fid = trimesh.sample.sample_surface_even(m, 3000, seed=0)
n = m.face_normals[fid]
eps=0.05
origins = pts - n*eps
loc, idx_ray, idx_tri = m.ray.intersects_location(origins, -n, multiple_hits=True)
d = np.linalg.norm(loc - origins[idx_ray], axis=1)
shown=0
for r in range(len(pts)):
    hits = [(dd, t) for rr, dd, t in zip(idx_ray, d, idx_tri) if rr == r]
    hits.sort()
    if hits and hits[0][0] + eps < 2.0 and shown < 6:
        shown += 1
        print("pt", pts[r].round(2), "n", n[r].round(3), "face", fid[r], "hits", [(round(float(dd),3), int(t), m.face_normals[t].round(2).tolist()) for dd,t in hits[:4]])
c = m.triangles_center; nn = m.face_normals
inside_pos = m.contains(c + nn*0.2); inside_neg = m.contains(c - nn*0.2)
print("faces with solid on both sides (internal faces):", int((inside_pos & inside_neg).sum()), "of", len(m.faces))
print("faces with solid on neither side:", int((~inside_pos & ~inside_neg).sum()))
t = trimesh.load("tray.stl"); b = trimesh.load("body_R.stl")
inter = b.intersection(t, engine="manifold")
print("body_R∩tray bounds", inter.bounds.round(2).tolist() if len(inter.faces) else None)
