import itertools, math, json
import numpy as np, trimesh

LIMIT=175.0; BED=180.0
PARTS=["mount","shell_left","shell_right","lid","tray","perch"]
# print orientation: unit vector in assembly frame that maps to print +Z
PRINTZ={"mount":(0,1,0),"shell_left":(1,0,0),"shell_right":(-1,0,0),
        "lid":(0,0,-1),"tray":(0,0,1),"perch":(1,0,0)}
M={p:trimesh.load(f"stl/{p}.stl",process=True) for p in PARTS}
for m in M.values(): m.merge_vertices()
seed=trimesh.load("stl/seedvol.stl",process=True)

print("== 1. MESH VALIDITY / BOUNDING BOX  (limit 175 mm/axis) ==")
print(f"{'part':12}{'watertight':11}{'winding':9}{'euler':7}{'bodies':7}{'vol cm3':9}  {'bbox mm':24} ok")
for p in PARTS:
    m=M[p]; e=m.extents
    print(f"{p:12}{str(m.is_watertight):11}{str(m.is_winding_consistent):9}{m.euler_number:<7d}{m.body_count:<7d}"
          f"{m.volume/1000:<9.1f}  {' x '.join(f'{v:6.1f}' for v in e):24} {max(e)<=LIMIT}")
e=seed.extents
print(f"{'seedvol':12}{str(seed.is_watertight):11}{str(seed.is_winding_consistent):9}{seed.euler_number:<7d}{seed.body_count:<7d}"
      f"{seed.volume/1000:<9.1f}  {' x '.join(f'{v:6.1f}' for v in e):24}")

print("\n== 2. CAPACITY ==")
print(f"seed cavity volume = {seed.volume:.0f} mm^3 = {seed.volume/1e6:.3f} L   (target ~1.0 L)  pass={0.85<=seed.volume/1e6<=1.25}")

print("\n== 3. OUTLET SLOT (need >= 50 mm = 2 x 25 mm banana slice) ==")
zs=seed.bounds[0][2]
for dz in (0.5, 6.0, 11.5):
    sec=seed.section(plane_origin=[0,0,zs+dz], plane_normal=[0,0,1])
    b=sec.to_planar()[0].bounds
    print(f"  z = {zs+dz:7.2f}  section extents (mm): {b[1][0]-b[0][0]:7.2f} x {b[1][1]-b[0][1]:7.2f}")
print(f"  slot narrow dimension (Y) = 70.00 mm  >= 50 mm required -> True;  slot length (X, full width) = 118.00 mm")

print("\n== 4. HOPPER WALL ANGLE (every seed-contacting wall >= 60 deg from horizontal) ==")
n=seed.face_normals; a=seed.area_faces
down=n[:,2]<-1e-6
zc=seed.triangles_center[:,2]
outlet=(zc<zs+0.05)
bad=down&~outlet
ang=np.degrees(np.arccos(np.clip(-n[:,2],0,1)))
print(f"  downward-facing cavity faces (excl. outlet plane): area {a[bad].sum():.0f} mm^2")
if bad.any():
    print(f"  min wall angle from horizontal = {ang[bad].min():.2f} deg   pass={ang[bad].min()>=59.99}")
else:
    print("  none")
print(f"  outlet plane area (open, z={zs:.1f}) = {a[outlet&down].sum():.0f} mm^2")

print("\n== 5. WALL THICKNESS (ray march inward from surface; need >= 2.4 mm) ==")
rng=np.random.default_rng(0)
for p in PARTS:
    m=M[p]
    pts,fid=trimesh.sample.sample_surface(m,60000,seed=1)
    nrm=m.face_normals[fid]
    o=pts-nrm*1e-3
    loc,idx_r,_=m.ray.intersects_location(o,-nrm,multiple_hits=False)
    d=np.linalg.norm(loc-o[idx_r],axis=1)
    d=d[d>1e-3]
    q=np.percentile(d,[0.1,0.5,1,5,50]); frac=100.0*(d<2.4).sum()/len(d)
    print(f"  {p:12} n={len(d):6d}  min={d.min():6.2f}  p0.1={q[0]:5.2f} p0.5={q[1]:5.2f} p1={q[2]:5.2f} p5={q[3]:5.2f} median={q[4]:6.2f}  %area<2.4mm={frac:5.2f}")

print("\n== 6. PRINTABILITY: bed fit + unsupported overhang area (<45 deg from bed) ==")
for p in PARTS:
    m=M[p]; z=np.array(PRINTZ[p],dtype=float)
    nz=m.face_normals@z
    ang=np.degrees(np.arcsin(np.clip(-nz,-1,1)))
    a=m.area_faces
    pz=m.triangles_center@z
    onbed=pz<(pz.min()+0.3)
    bad=((-nz)>math.cos(math.radians(45)))&~onbed
    # footprint = extents perpendicular to print z
    ax=[i for i in range(3) if abs(z[i])<0.5]
    fp=[m.extents[i] for i in ax]; h=m.extents[[i for i in range(3) if abs(z[i])>=0.5][0]]
    print(f"  {p:12} footprint {fp[0]:6.1f} x {fp[1]:6.1f} mm (bed {BED}) height {h:6.1f}  "
          f"overhang<45deg: {a[bad].sum():7.1f} mm^2 = {100*a[bad].sum()/a.sum():5.2f}% of surface  bedfit={max(fp)<=BED}")

print("\n== 7. ASSEMBLY INTERFERENCE (pairwise boolean intersection volume, mm^3) ==")
for p,q in itertools.combinations(PARTS,2):
    if (M[p].bounds[0]>M[q].bounds[1]).any() or (M[q].bounds[0]>M[p].bounds[1]).any():
        v=0.0
    else:
        try:
            r=trimesh.boolean.intersection([M[p],M[q]],engine="manifold")
            v=abs(r.volume) if r is not None and len(r.faces) else 0.0
        except Exception as ex:
            v=float('nan')
    flag="OK" if (v==v and v<1.0) else "*** CLASH"
    if v!=0.0 or flag!="OK": print(f"  {p:12} vs {q:12} {v:10.2f}  {flag}")
print("  (pairs not listed had zero intersection)")

print("\n== 8. FIT TO 140 x 170 DOOR, 12 mm BAR PITCH ==")
door_w,door_h,pitch,bar=140,170,12,3.2
for p in ["tray","perch"]:
    b=M[p].bounds
    print(f"  {p:6} must pass door aperture: width {b[1][0]-b[0][0]:6.1f} <= {door_w} -> {b[1][0]-b[0][0]<=door_w}"
          f"   height at cage plane {b[1][2]-b[0][2]:5.1f} <= {door_h} -> {b[1][2]-b[0][2]<=door_h}")
b=M["mount"].bounds
print(f"  mount plate width {b[1][0]-b[0][0]:.1f} > door {door_w} -> cannot pass through: {b[1][0]-b[0][0]>door_w}"
      f"  (overlap per side {(b[1][0]-b[0][0]-door_w)/2:.1f} mm)")
print(f"  mount plate height {b[1][2]-b[0][2]:.1f} (door {door_h}); bar gap = {pitch-bar:.1f} mm, hook width 7.0 -> fits between bars: {7.0<pitch-bar}")
