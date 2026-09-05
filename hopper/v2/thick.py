import numpy as np, trimesh
def thickness(m, n_samples=8000, seed=0):
    pts, fid = trimesh.sample.sample_surface_even(m, n_samples, seed=seed)
    n = m.face_normals[fid]
    eps = 0.05
    origins = pts - n*eps
    loc, idx_ray, idx_tri = m.ray.intersects_location(origins, -n, multiple_hits=True)
    d = np.linalg.norm(loc - origins[idx_ray], axis=1)
    th = np.full(len(pts), np.inf)
    for r, dist, tri in zip(idx_ray, d, idx_tri):
        if tri == fid[r] or dist < 1e-3: continue
        if dist < th[r]: th[r] = dist
    th = th + eps
    ok = np.isfinite(th)
    return pts[ok], th[ok]
