import json
import sys
from pathlib import Path

import numpy as np
import trimesh

OUT = Path(__file__).resolve().parent.parent / "fable" / "out"


def load(name):
    m = trimesh.load(OUT / f"{name}.stl", force="mesh")
    m.merge_vertices()
    return m


def overlap(a, b, shift):
    b = b.copy()
    b.apply_translation(shift)
    return round(trimesh.boolean.intersection([a, b], engine="manifold").volume, 3)


def probe(m, lo, hi):
    lo, hi = np.array(lo, float), np.array(hi, float)
    box = trimesh.creation.box(extents=hi - lo, transform=trimesh.transformations.translation_matrix((lo + hi) / 2))
    hit = trimesh.boolean.intersection([m, box], engine="manifold")
    return None if hit.is_empty else np.round(hit.bounds, 3).tolist()


body_R, body_L, lid, bracket, tray = map(load, ["body_R", "body_L", "lid", "bracket", "tray"])
parts = {"body_R": body_R, "body_L": body_L, "lid": lid, "bracket": bracket, "tray": tray}
r = {}

on_seam = np.isclose(body_R.face_normals[:, 0], -1) & np.all(np.isclose(body_R.triangles[:, :, 0], 0), axis=1)
r["seam"] = {
    "body_R_xmin": float(body_R.bounds[0, 0]),
    "body_L_xmax": float(body_L.bounds[1, 0]),
    "seam_plane_face_area_mm2": round(float(body_R.area_faces[on_seam].sum()), 1),
    "body_R_minus_x_faces_off_plane": int((np.isclose(body_R.face_normals[:, 0], -1) & ~on_seam).sum()),
    "parts_crossing_seam": [n for n, m in parts.items() if m.bounds[0, 0] < 0 < m.bounds[1, 0]],
}
r["lid_clamp_probe"] = {n: probe(m, [61, -4.5, 118], [90, -3, 122]) for n, m in [("body_R", body_R), ("lid", lid)]}
r["bracket_window_probe"] = {n: probe(m, [61, 0.3, 0], [90, 3.3, 3]) for n, m in [("body_R", body_R), ("bracket", bracket)]}
r["lid_slot_probe"] = {n: probe(m, [61, -30, 100], [64, -20, 130]) for n, m in [("body_R", body_R), ("lid", lid)]}
r["body_L_shifted_minus_x"] = {str(dx): {n: overlap(m, body_L, (-dx, 0, 0)) for n, m in [("lid", lid), ("bracket", bracket)]} for dx in [0.3, 0.4]}
r["bracket_shifted_z"] = {str(dz): {n: overlap(m, bracket, (0, 0, dz)) for n, m in [("body_R", body_R), ("body_L", body_L), ("lid", lid)]} for dz in [0.4, 0.6, -0.5, -2, -6, -12]}
r["bracket_bounds"] = np.round(bracket.bounds, 3).tolist()
r["lid_shifted_minus_y"] = {str(dy): {n: overlap(m, lid, (0, -dy, 0)) for n, m in [("body_R", body_R), ("body_L", body_L), ("bracket", bracket)]} for dy in [1, 5, 20]}
r["tray_shifted"] = {
    f"z+{dz}": {n: overlap(m, tray, (0, 0, dz)) for n, m in [("body_R", body_R), ("body_L", body_L), ("bracket", bracket)]} for dz in [1, 3, 7]
}
r["tray_shifted"]["y+1"] = {n: overlap(m, tray, (0, 1, 0)) for n, m in [("body_R", body_R), ("bracket", bracket)]}
r["tray_shifted"]["y+1_z+7"] = {n: overlap(m, tray, (0, 1, 7)) for n, m in [("body_R", body_R), ("bracket", bracket)]}

n = bracket.face_normals
cyl = np.isclose(n[:, 0], 0, atol=1e-6) & ~np.isclose(np.abs(n[:, 1]), 1, atol=1e-6) & ~np.isclose(np.abs(n[:, 2]), 1, atol=1e-6) & ~np.isclose(n[:, 1], 0, atol=1e-6) & ~np.isclose(n[:, 2], 0, atol=1e-6)
rim = bracket.vertices[np.unique(bracket.faces[cyl])]
A = np.c_[2 * rim[:, 1], 2 * rim[:, 2], np.ones(len(rim))]
yc, zc, c = np.linalg.lstsq(A, rim[:, 1] ** 2 + rim[:, 2] ** 2, rcond=None)[0]
rad = np.linalg.norm(rim[:, 1:] - [yc, zc], axis=1)
axis = np.linalg.eigh(np.cov(rim.T))[1][:, -1]
r["perch"] = {
    "axis_y": round(float(yc), 3),
    "axis_z": round(float(zc), 3),
    "radius_min_max": [round(float(rad.min()), 3), round(float(rad.max()), 3)],
    "axis_dir_xyz": [round(abs(float(x)), 4) for x in axis],
    "axis_angle_from_horizontal_deg": round(float(np.degrees(np.arcsin(abs(axis[2])))), 3),
    "x_span": [round(float(rim[:, 0].min()), 3), round(float(rim[:, 0].max()), 3)],
    "rim_vertices": int(len(rim)),
}
front = probe(tray, [29, 90, -20], [31, 120, 40])
lip = probe(tray, [29, 90, 15], [31, 101, 40])
r["tray_front_x30"] = {"outer_face_y": front[1][1], "lip_tip_y": lip[0][1], "lip_top_z": front[1][2], "floor_z": probe(tray, [29, 40, -20], [31, 60, 40])[0][2]}
p, f = r["perch"], r["tray_front_x30"]
rp = max(p["radius_min_max"])
r["perch_vs_lip"] = {
    "axis_forward_of_outer_face": round(p["axis_y"] - f["outer_face_y"], 3),
    "axis_forward_of_lip_tip": round(p["axis_y"] - f["lip_tip_y"], 3),
    "axis_below_lip_top": round(f["lip_top_z"] - p["axis_z"], 3),
    "perch_top_below_lip_top": round(f["lip_top_z"] - (p["axis_z"] + rp), 3),
    "perch_diameter_under_tray_footprint": round(f["outer_face_y"] - (p["axis_y"] - rp), 3),
}
json.dump(r, sys.stdout, indent=1)
print()
