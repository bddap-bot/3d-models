import json, numpy as np, trimesh
from trimesh import proximity
out = {}
parts = ["body_R","body_L","lid","bracket","tray"]
meshes = {}
for p in parts:
    m = trimesh.load(f"{p}.stl", process=True); m.merge_vertices(); meshes[p] = m
    ext = m.bounding_box.extents
    r = {"watertight": bool(m.is_watertight), "winding_consistent": bool(m.is_winding_consistent),
         "euler": int(m.euler_number), "volume_mm3": round(float(m.volume),1),
         "extents_mm": [round(float(e),2) for e in ext], "max_extent_ok_175": bool(ext.max() <= 175.0)}
    from thick import thickness
    pts, th = thickness(m)
    thin = th < 2.39
    # a ray fired from a point within 0.6 mm of a convex edge hits the neighbouring face immediately; those are edge artifacts, not walls
    from trimesh.proximity import ProximityQuery
    edges = m.face_adjacency_edges
    conv = m.face_adjacency_convex
    sharp = edges[conv & (m.face_adjacency_angles > np.radians(30))]
    seg = m.vertices[sharp]
    def dist_to_edges(P):
        a = seg[:,0]; b = seg[:,1]; ab = b-a
        d = []
        for q in P:
            tt = np.clip(np.einsum('ij,ij->i', q-a, ab)/np.einsum('ij,ij->i', ab, ab), 0, 1)
            d.append(np.linalg.norm(a + tt[:,None]*ab - q, axis=1).min())
        return np.array(d)
    de = dist_to_edges(pts[thin]) if thin.any() else np.array([])
    real_thin = thin.copy(); real_thin[np.where(thin)[0][de < 1.0]] = False
    r["thickness_ray_mm"] = {"n": int(len(th)), "min_all": round(float(th.min()),2),
        "below_2.4_all": int(thin.sum()), "below_2.4_farther_than_1mm_from_any_convex_edge": int(real_thin.sum()),
        "min_away_from_edges": round(float(th[~(thin & ~real_thin)].min()),2) if (~(thin & ~real_thin)).any() else None,
        "median": round(float(np.median(th)),2)}
    if real_thin.any():
        r["thin_sample_points"] = [[round(float(v),1) for v in q] for q in pts[real_thin][:8]]
    out[p] = r

body = trimesh.util.concatenate([meshes["body_R"], meshes["body_L"]])
sec = body.section(plane_origin=[0,0,0.5], plane_normal=[0,0,1])
v = sec.vertices; ys = v[(np.abs(v[:,0]) < 60),1]
out["slot_width_mm_at_z0.5"] = round(float(ys[ys>30].min() - ys[(ys>0)&(ys<30)].max()), 2)
sec5 = body.section(plane_origin=[0,0,50], plane_normal=[0,0,1])
v = sec5.vertices; ys = v[(np.abs(v[:,0]) < 60),1]
out["cavity_depth_mm_at_z50"] = round(float(ys[ys>30].min() - ys[(ys<0)].max()), 2)

up = body.face_normals[:,2] > 0.05
cen = body.triangles_center
inside = (cen[:,1] > -50) & (cen[:,1] < 55) & (cen[:,2] > 0.5) & (cen[:,2] < 116) & (np.abs(cen[:,0]) < 67.3)
sel = up & inside
angs = np.degrees(np.arccos(np.clip(body.face_normals[sel][:,2],-1,1)))
bins = {}
for a, ar in zip(angs, body.area_faces[sel]):
    k = f"{round(float(a),1)} deg"; bins[k] = round(bins.get(k,0)+float(ar),1)
out["interior_upward_facing_faces__angle_from_horizontal__area_mm2"] = bins

lo = np.array([-500,-2.5,-500.]); hi = np.array([500,0,500.])
thr = body.slice_plane(lo, [0,1,0], cap=True).slice_plane(hi, [0,-1,0], cap=True)
b = thr.bounding_box.bounds
out["through_section_in_bar_plane_y[-2.5,0]"] = {"w": round(float(b[1][0]-b[0][0]),2), "h": round(float(b[1][2]-b[0][2]),2),
    "z_range": [round(float(b[0][2]),2), round(float(b[1][2]),2)], "fits_140x170": bool((b[1][0]-b[0][0] <= 140) and (b[1][2]-b[0][2] <= 170))}

import shapely.geometry as sg
th_y = 2.4/np.sin(np.radians(66.17))
prof = sg.Polygon([(5-th_y,0),(57.4,0),(57.4,116.7),(-46.5-th_y,116.7)])
prism = trimesh.creation.extrude_polygon(prof, 134.8)
prism.apply_transform(trimesh.transformations.rotation_matrix(np.radians(90),[1,0,0]))
prism.apply_transform(trimesh.transformations.rotation_matrix(np.radians(90),[0,0,1]))
prism.apply_translation([-67.4,0,0])
pb = prism.bounds
cav = prism.difference(body, engine="manifold")
out["cavity_boolean"] = {"prism_bounds": [[round(float(x),1) for x in r] for r in pb], "cavity_volume_L": round(float(cav.volume)/1e6, 3),
                         "cavity_watertight": bool(cav.is_watertight)}
out["capacity_analytic_L"] = round(129.8*0.5*((55-5)+(55-(-46.5)))*116.7/1e6, 3)

clash = {}
names = list(meshes)
for i in range(len(names)):
    for j in range(i+1, len(names)):
        inter = meshes[names[i]].intersection(meshes[names[j]], engine="manifold")
        clash[f"{names[i]}∩{names[j]}"] = round(float(inter.volume),3) if inter is not None and len(inter.faces) else 0.0
out["assembly_pairwise_intersection_volume_mm3"] = clash
for p in names:
    m = meshes[p]; c = m.triangles_center; nn = m.face_normals
    out[p]["internal_faces"] = int((m.contains(c+nn*0.2) & m.contains(c-nn*0.2)).sum())

R = trimesh.transformations.rotation_matrix
orient = {"body_R": R(np.radians(90),[0,1,0]), "body_L": R(np.radians(-90),[0,1,0]),
          "lid": np.eye(4), "bracket": R(np.radians(-90),[0,1,0]), "tray": np.eye(4)}
pr = {}
for p, T in orient.items():
    m = meshes[p].copy(); m.apply_transform(T); m.apply_translation(-m.bounds[0])
    m.export(f"print_{p}.stl")
    fl = m.section(plane_origin=[0,0,0.1], plane_normal=[0,0,1])
    down = m.face_normals[:,2] < -0.01
    offbed = m.triangles_center[:,2] > 0.3
    sel = down & offbed
    ang = np.degrees(np.arccos(np.clip(-m.face_normals[sel][:,2],-1,1)))
    area = m.area_faces[sel]
    ov = {}
    for a, ar in zip(ang, area):
        k = "flat ceiling (bridge)" if a < 1 else f"{int(a//15)*15}-{int(a//15)*15+15} deg from vertical-down"
        ov[k] = round(ov.get(k,0)+float(ar),1)
    pr[p] = {"print_extents_mm": [round(float(e),2) for e in m.extents], "height_mm": round(float(m.extents[2]),2),
             "downward_faces_off_bed_area_mm2_by_overhang": ov,
             "first_layer_outline_length_mm": round(float(fl.length),1) if fl is not None else None}
out["print_orientation"] = pr
print(json.dumps(out, indent=1, ensure_ascii=False))
