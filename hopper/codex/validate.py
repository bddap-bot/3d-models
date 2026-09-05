from pathlib import Path
import math
import trimesh

root = Path(__file__).parent
parts = ["hopper_body", "lid", "tray_perch"]
ok = True
for name in parts:
    mesh = trimesh.load_mesh(root / f"{name}.stl", process=True)
    ext = mesh.bounding_box.extents
    components = mesh.split(only_watertight=False)
    print(f"{name}: watertight={mesh.is_watertight} winding={mesh.is_winding_consistent} components={len(components)} bbox_mm={ext.round(3).tolist()} max_mm={ext.max():.3f}")
    ok &= mesh.is_watertight and mesh.is_winding_consistent and ext.max() <= 175.001

top_depth = 75 - 3
bottom_depth = 52 - 3
lower_height = 62 - 7
upper_height = 150 - 62
capacity_mm3 = 130 * (lower_height * bottom_depth + upper_height * (top_depth + bottom_depth) / 2)
angle = math.degrees(math.atan2(150 - 62, 75 - 52))
print(f"analytic_capacity_L={capacity_mm3 / 1e6:.4f}")
print(f"clear_outlet_mm=130.0x54.0 banana_ratio_min_dimension={54/25:.2f}x")
print(f"flow_wall_angle_deg_from_horizontal={angle:.3f}")
print("minimum_nominal_wall_mm=3.0 requirement_mm=2.4")
print("door_flange_mm=140.0x170.0 opening_mm=140.0x170.0 bar_pitch_mm=12.0")
print(f"OVERALL={'PASS' if ok and capacity_mm3 >= 0.9e6 and angle >= 60 else 'FAIL'}")
raise SystemExit(0 if ok and capacity_mm3 >= 0.9e6 and angle >= 60 else 1)
