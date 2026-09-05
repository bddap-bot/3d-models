# Seed hopper for a green-cheek conure — design report

Print-ready parametric hopper for a Bambu Lab A1 mini (180 mm bed), PETG,
mounting in a 140×170 mm cage-door opening (12 mm bar spacing, door stays shut).

## (a) Approach and tools — and why

- **OpenSCAD 2021.01** (via `nix-shell -p openscad`) for the parametric solid
  model: one file (`hopper.scad`), a `part` selector exports each part plus the
  cavity solid (`interior`) used for capacity measurement and an assembly view.
  Chosen because the whole design is parametric box/cylinder CSG — exact,
  diffable, and its CGAL export is watertight when unions are overlapped.
- **Python + trimesh/numpy** (nixpkgs) for verification: watertightness,
  bounding boxes, volumes, ray-cast wall-thickness probes, face-normal angle
  and overhang analysis.
- **matplotlib** for renders — OpenSCAD's offscreen GL is unavailable in this
  sandbox ("Can't create OpenGL OffscreenView"), so PNGs are mesh plots of the
  actual exported STLs (which is arguably better: what you see is the mesh).
- No slicer dry-run (no GUI slicer usable headless here); printability was
  checked analytically per face orientation instead — see VERIFICATION.

**Form choice (the important decision).** The brief asks for a wedge
(plane-flow) hopper, full-width slot ≥ 2× slice width (≥ 50 mm), walls ≥ 60°
from horizontal, no converging funnel, ~1 L, inside a 140×170 envelope. A
literal 60° sloped-wall wedge cannot hold 1 L in this envelope: a full-height
single-slope (chisel) wedge caps at ~0.6 L (a 60° wall over 128 mm of height
halves the footprint), and a straddling two-slope wedge with the slot crossing
the cage plane either spills seed outside the cage or opens the whole seed
column to the bird (worked through three variants; all dead ends — see (b)).
The design therefore uses the degenerate-wedge limit that still satisfies
every stated anti-clog rule: a **straight mass-flow chute** — vertical walls
(90° ≥ 60°), outlet = the *entire open bottom* of the bin (132×60 mm, full
width, ≥ 2× the 25 mm banana slices), zero convergence anywhere, so there is
no shoulder a sticky slice can bridge on and no rathole geometry. The bin
hangs *inside* the cage on the door plate; the plate carries a top fill port
with a sliding lid captured in rails on the **outside** face only, so refill
is from outside and the bird cannot open it from inside (flush, rail-captured,
gravity-closed; only reachable surface is the port face).

## (b) What I actually did, including dead ends

1. Drafted a straddling symmetric wedge (bin crossing the cage plane, floor
   slot into an inside tray). Dead end: any cavity crossing the plate plane
   opens the plate along the full chute height — the bird gets the whole
   column face and can reach the lid.
2. Tried a chisel (single 60° slope) with the slot fully inside the cage.
   Dead end: 0.61 L max in the envelope; raising capacity needs depth/height
   the door doesn't have.
3. Tried a chisel with a vertical feed window in the plate. Dead end: a 60°
   slope from a bottom window needs 133 mm of rise over the needed depth —
   0.2–0.65 L depending on window height.
4. Settled on the inside-hung mass-flow chute (90° walls, full-bottom outlet,
   fill port in the plate). This is the geometry commercial "no-mess" hoppers
   approximate with smaller windows; here the outlet *is* the whole floor.
5. Modeled in OpenSCAD; fixed two classes of mesh defects found by
   verification: tangent-face unions (non-2-manifold) → gave every attachment
   ≥ 1 mm volumetric overlap (cheeks/roof/rails/sill/clip posts, tray arms);
   a cylinder tangent to a wall plane (perch) → offset 0.5 mm.
6. First render caught the lid lying flat instead of standing in the plate
   plane → fixed the assembly transform and moved the grip ridge to the
   outside face (and verified the ridge can't be hooked by a beak through the
   port: it sits above the port's top edge).
7. Verified everything in section (d); renders from the exported STLs.

## (c) Final dimensions, parts, capacity

Coordinate frame: X across the door, Y depth (+Y outside the cage), Z up.

- **body.stl** — door plate 138×168×3 mm (1 mm clearance per side in the
  140×170 opening) with the seed bin hung on the inside face: cavity
  132 (X) × 60 (Y) × 130 (Z) mm, walls 3 mm, roof 4 mm, open bottom outlet
  132×60 mm at z=35 mm. Six bar clips (3 Z-rows × 2 sides) reach past the
  plate edges to wrap the vertical bars flanking the opening (bar X positions
  and clip rows parametric: `bar_lx`, `bar_rx`, `side_clips(z)` calls; bars
  assumed Ø3 mm). Fill port 120×40 mm in the plate top, with lid rails + sill
  on the outside face. Overall part envelope 156×79×168 mm (clips included) —
  all axes ≤ 175 mm.
- **lid.stl** — sliding fill-port lid, 130×56×3 mm, rounded corners (r=2),
  outside grip ridge; drops into the outside rails from above, rests on the
  sill, fully captured against outward push; flush face gives no beak purchase.
- **tray.stl** — feed tray 130×76 mm, floor 3 mm, front/side walls 15 mm and
  back wall 22 mm above the floor (hull lip), rounded floor corners (r=3),
  rounded rim rods on the front and back walls, pull tab outside the cage;
  integrated perch Ø16 mm × 98 mm below the tray front on two arms. Envelope
  133×98.5×26.5 mm. Slides through a plate cutout onto two inside ledges.
- **Capacity: 1.030 L** (volume of `interior.stl`, the exact cavity solid).
- PETG throughout; every structural wall 3 mm (min allowed 2.4 mm).
- No small detachable parts: 3 parts total; lid and tray are large; clips and
  perch are integral.

Print orientation: **body with part X vertical** (left cheek on the bed) so
layer planes contain the (vertical) seed-flow direction — layer lines run
along the flow on every flow-contact wall. Tray flat (Z-up; not a flow
surface), lid flat ridge-up. Supports: one region under the body's outer bin
wall over the cavity (~7,500 mm², removed through the fully open bottom), and
small supports under the tray's perch rod (~930 mm²). Everything else is
support-free.

## (d) VERIFICATION

All run under `nix-shell -p openscad python3 python3Packages.trimesh
python3Packages.numpy python3Packages.rtree python3Packages.networkx
python3Packages.matplotlib`. Scripts are in this directory
(`build_stl.sh`, `verify_mesh.py`, `verify2.py`, `render.py`).

### Mesh validity (watertight/manifold) — `python3 verify_mesh.py $OUT`

```
body: watertight=True winding=True size=[156.  79. 168.] maxdim=168.0 vol_mm3=193646 euler=-2 faces=496
lid: watertight=True winding=True size=[130.  56.   5.] maxdim=130.0 vol_mm3=21946 euler=2 faces=60
tray: watertight=True winding=True size=[133.  98.5  26.5] maxdim=133.0 vol_mm3=82109 euler=-2 faces=622
interior: watertight=True watertight winding=True size=[132.  60. 130.] vol_mm3=1029600 faces=12
ALL_WATERTIGHT
```

All four STLs watertight with consistent winding (body/tray euler −2 reflects
the rail/ledge channel topology; trimesh reports closed, consistently oriented
surfaces — slicers accept these).

### Bounding box vs 175 mm — same output

body 156×79×168, lid 130×56×5(+ridge), tray 133×98.5×26.5 — every axis of
every part ≤ 175 mm. PASS.

### Wall thickness vs 2.4 mm — ray probes (`verify2.py`)

```
body plate @z=90: 3.00 mm  OK
body plate @z=60: 3.00 mm  OK
body left cheek: 3.00 mm  OK
body back wall: 3.00 mm  OK
body roof: 4.00 mm  OK
tray floor: 3.00 mm  OK
tray front wall: 3.00 mm  OK
tray back wall: 5.00 mm  OK (3 mm wall + modeled overlap at tab)
lid slab: 3.00 mm  OK
```

Probes are point samples on each distinct wall, not an exhaustive minimum —
by construction every wall is the same 3 mm parameter, and no probe found
less. PASS at probe points; not a full-field minimum measurement.

### Capacity vs 1 L — volume of the exact cavity solid

`interior.stl` (exported from the same parameters): volume 1,029,600 mm³ =
**1.030 L**. PASS ("about 1 litre").

### Slot/outlet width vs 50 mm — cavity mesh bounds

```
cavity XxYxZ = 132 x 60 x 130 mm
outlet (full open bottom) = 132 x 60 mm (need >= 50 x 50, full width)
```

PASS: 60 ≥ 2× the 25 mm slice width, and the outlet is the full 132 mm
cavity width. Banana slices 25 mm Ø × 3–6 mm cannot bridge a 132×60 opening.

### Wall angle vs 60° — cavity face normals

```
vertical-flow wall faces: 8 faces, all 90..90 deg from horizontal (need >= 60)
```

PASS (interpretation stated in (a): vertical mass-flow walls, no convergence
at all — the 60° minimum and "no converging funnel" are both satisfied with
margin; a literal sloped wedge cannot meet 1 L in this envelope).

### Fit to 140×170 with 12 mm bars

```
plate extents X 0..138 Z 0..168 (opening 140x170)
bar clips span X -9..147, Z rows [36 44 84 92 132 140]
```

Plate fits the opening with 1 mm clearance per side. Clips assume **vertical**
bars flanking the opening at X=−6 and X=+144 (Ø3 mm); bar positions and the
three clip rows are parameters in `hopper.scad`. NOT verified against a real
cage: if the door's surrounding bars are horizontal, the clip layout must be
re-generated (parameters only) — stated plainly as unverified fit.

### Printability (overhangs/supports) — face-orientation analysis

```
body printed X-up (part X=0 side on bed; layer planes contain the flow):
  down-facing off-bed total: 9,737 mm2
  main support region: 7,527 mm2 at the bin's outer side wall (span 63x~120 mm),
    removable through the fully open bin bottom; remainder is <=3 mm-wide
    end-face slivers that bridge trivially.
tray printed flat Z-up: 932 mm2 (perch-rod underside + rim slivers) -> small supports.
lid printed ridge-up: 0 mm2 off-bed down-facing -> no supports.
```

No slicer dry-run was performed (no headless slicer in this environment);
this is an analytic per-face check, not a sliced validation. Overhangs other
than the two support regions are vertical walls or ≤3 mm bridges.

### Bird-safety (design review, not mesh-checkable)

PETG only; walls ≥ 3 mm; bird-contact edges rounded (tray rims r=1.5 rods,
tray floor r=3, lid r=2, perch Ø16 round); perch has no detachable parts;
lid is captive in outside rails and flush — no inside beak purchase;
bar clips are 3×8 mm PETG sections (a green cheek cannot sever them, but
chew-wear should be inspected periodically — noted, not verified).
One honest functional note: with the tray removed the open-bottom bin will
drain into the cage — remove the tray only when the seed is low.

## (e) Wall time

Start 11:39, end 12:09 PDT — **30 minutes** total.
