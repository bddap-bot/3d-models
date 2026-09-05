import json, re, numpy as np, trimesh
import shapely
from shapely.ops import unary_union
from scipy.ndimage import distance_transform_cdt
scad = open("hopper.scad").read()
param = lambda k: float(re.search(rf"^{k}\s*=\s*(-?[0-9.]+);", scad, re.M).group(1))
seam_clr, seam_lap, t, H, y_back0, y_backT = (param(k) for k in ("seam_clr", "seam_lap", "t", "H", "y_back0", "y_backT"))
lap_band = lambda x: (x > -seam_lap - seam_clr - 0.5) & (x < 0.5)
px = 0.01
out = {}
parts = ["body_R","body_L","lid","bracket","tray"]
meshes = {}
for p in parts:
    m = trimesh.load(f"out/{p}.stl", process=True); m.merge_vertices(); meshes[p] = m
    ext = m.bounding_box.extents
    r = {"watertight": bool(m.is_watertight), "winding_consistent": bool(m.is_winding_consistent),
         "euler": int(m.euler_number), "volume_mm3": round(float(m.volume),1),
         "extents_mm": [round(float(e),2) for e in ext], "max_extent_ok_175": bool(ext.max() <= 175.0)}
    from thick import thickness
    pts, th = thickness(m)
    thin = th < 2.39
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
    lap = real_thin & lap_band(pts[:,0]) if p.startswith("body") else np.zeros_like(real_thin)
    r["thickness_ray_mm"] = {"n": int(len(th)), "min_all": round(float(th.min()),2),
        "below_2.4_all": int(thin.sum()), "below_2.4_farther_than_1mm_from_any_convex_edge": int(real_thin.sum()),
        "of_those_in_the_seam_lap": int(lap.sum()), "min_in_the_seam_lap": round(float(th[lap].min()),2) if lap.any() else None,
        "min_away_from_edges_outside_the_lap": round(float(th[~(thin & ~real_thin) & ~lap].min()),2) if (~(thin & ~real_thin) & ~lap).any() else None,
        "median": round(float(np.median(th)),2)}
    if (real_thin & ~lap).any():
        r["thin_sample_points_outside_the_lap"] = [[round(float(v),1) for v in q] for q in pts[real_thin & ~lap][:8]]
    out[p] = r

R, L = meshes["body_R"], meshes["body_L"]
def box(m, lo, hi):
    for ax in range(3):
        e = np.eye(3)[ax]
        m = m.slice_plane(lo, e, cap=True).slice_plane(hi, -e, cap=True)
    return m
def seam_gap(origin, normal, lo, hi):
    normal = np.array(normal, float)
    T = np.eye(4); T[:3,:3] = [[1,0,0], np.cross(normal, [1,0,0]), normal]; T[:3,3] = -T[:3,:3] @ origin
    polys = []
    for m in (R, L):
        s = box(m, lo, hi).section(plane_origin=origin, plane_normal=normal)
        assert s is not None, f"a cut at {origin} misses {'body_R' if m is R else 'body_L'}"
        polys += list(s.to_2D(to_2D=T)[0].polygons_full)
    u = unary_union(polys)
    b = u.bounds
    X, Y = np.meshgrid(np.arange(b[0]+px/2, b[2], px), np.arange(b[1]+px/2, b[3], px))
    solid = shapely.contains_xy(u, X.ravel(), Y.ravel()).reshape(X.shape)
    return 2*px*distance_transform_cdt(~solid, metric="chessboard").max()
wall = np.array([0, y_backT - y_back0, H])
xw = [-seam_lap-2, 2]
cuts = {"front_wall_z60": ([0,0,60],[0,0,1],[xw[0],50,-100],[xw[1],60,300]),
        "back_wall_z60": ([0, y_back0 + 60*(y_backT-y_back0)/H, 60],wall/np.linalg.norm(wall),[xw[0],-30,-100],[xw[1],-15,300]),
        "roof_y20": ([0,20,0],[0,1,0],[xw[0],-100,110],[xw[1],100,300]),
        "lip_z118": ([0,0,118],[0,0,1],[xw[0],-6,-100],[xw[1],-2,300]),
        "flange_z-20": ([0,0,-20],[0,0,1],[xw[0],-7,-100],[xw[1],-1,300])}
gap = {k: round(float(seam_gap(*c)), 3) for k, c in cuts.items()}
vr = R.section(plane_origin=[0,0,60], plane_normal=[0,0,1]).vertices
vl = L.section(plane_origin=[0,0,60], plane_normal=[0,0,1]).vertices
overlap = {}
for wall_name, sel in (("back_wall", lambda v: v[:,1] < 0), ("front_wall", lambda v: v[:,1] > 50)):
    xr, xl = vr[sel(vr)][:,0], vl[sel(vl)][:,0]
    overlap[wall_name] = round(float(xl.max() - xr.min()),3)
out["seam"] = {"clearance_mm": seam_clr, "lap_mm": seam_lap,
    "widest_square_in_seam_void_mm_by_section": gap, "raster_px_mm": px, "lap_overlap_mm_at_z60": overlap}
assert max(gap.values()) <= seam_clr + 2*px, f"seam void wider than seam_clr={seam_clr}: widest square by section {gap} mm"
for wall_name, o in overlap.items():
    assert o >= seam_lap - seam_clr, f"{wall_name} lap overlap {o} mm below seam_lap-seam_clr"
body = trimesh.util.concatenate([R, L])
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
        assert inter is not None, f"boolean failed for {names[i]}∩{names[j]}"
        clash[f"{names[i]}∩{names[j]}"] = float(inter.volume) if len(inter.faces) else 0.0
assert all(c == 0.0 for c in clash.values()), f"assembly clash {clash}"
out["assembly_pairwise_intersection_volume_mm3"] = {k: round(c, 3) for k, c in clash.items()}
for p in names:
    m = meshes[p]; c = m.triangles_center; nn = m.face_normals
    out[p]["internal_faces"] = int((m.contains(c+nn*0.2) & m.contains(c-nn*0.2)).sum())

rot = trimesh.transformations.rotation_matrix
orient = {"body_R": rot(np.radians(90),[0,1,0]), "body_L": rot(np.radians(-90),[0,1,0]),
          "lid": np.eye(4), "bracket": rot(np.radians(-90),[0,1,0]), "tray": np.eye(4)}
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
