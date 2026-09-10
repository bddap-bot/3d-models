run-id: B1

# Green-cheek conure seed hopper, small feeder door

Four printed parts, no fasteners, no glue: `base`, `tank`, `tray`, `lid`.
Source of truth is `hopper.scad`; every number below is a parameter in it or is
measured from the exported meshes.

## (a) Approach and tools

Requirement in one sentence: a ~1 L wedge hopper that hangs on the outside of a
110 x 110 mm feeder door and presents non-clogging seed to a bird standing inside.

The dumbest design that satisfies it is a rectangular tank hanging outside the cage,
its bottom open as a full-width slot, discharging into a shallow open trough that sits
at the doorway. No moving parts, no funnel, no valve. Everything else in this design is
retention (how it stays on the door) and printability (how it fits a 180 mm bed).

Tools, and why:

- **OpenSCAD 2021.01** (`nix-shell -p openscad`) for the model. The geometry is one
  two-dimensional wedge profile extruded across the width plus rectangular features;
  that is exactly what a CSG script is good at, and a single `part` variable gives the
  per-part exports the brief asks for. Parametric by construction: every dimension is a
  named top-level variable.
- **trimesh 4.9.0 / numpy 2.3.4** (`nix-shell -p 'python3.withPackages(...)'`) for
  verification: watertightness, Euler number, bounding boxes, ray-cast wall thickness,
  face-normal overhang analysis, cross-sections, and volume.
- **OpenSCAD boolean intersection of exported STLs** for fit checks. Part-vs-part and
  part-vs-cage interference is a boolean question, so I answered it with a boolean:
  `intersection() { import("a.stl"); import("b.stl"); }` and measured the volume of the
  result. A cage model (`part="cage"`, vertical bars at 12 mm pitch, 3 mm wire, with the
  door opening and its top and bottom rails) exists purely so this check has something
  to intersect against.
- **xvfb-run + OpenSCAD** for the renders in `img/`.

No slicer was run. See VERIFICATION for what that means.

## (b) Steps actually taken, including dead ends

1. Sized the wedge from the capacity target: constant 104 mm width (plane flow, no
   convergence across the width), vertical front wall, rear wall at 70 degrees, outlet
   slot spanning the full width. Solved the trapezoid area for ~1 L.
2. **Dead end: retention by hooking the wall above the doorway.** The first scheme put
   fins through the doorway that rose behind the wall above it. It cannot be installed:
   to get the fin inside, the whole body has to drop far enough for the fin to clear the
   top rail, and the same fin then has nothing to rest on. Abandoned.
3. **Dead end: a toggle bar or backing plate clamped behind the bar wall.** Anything that
   catches the frame from inside has to be wider than 110 mm, which either violates the
   fit rule outright or relies on inserting it diagonally. Abandoned.
4. **Settled retention: hang on the door's top rail, from outside, threading between the
   vertical bars.** Two 6 mm fingers pass between bars above the rail and hook down
   behind it; two more pass between bars below the doorway and carry barbs that rise
   behind the wall. Both pairs are 60 mm apart, which is 5 x 12 mm, so they see the same
   phase in the bar pattern whatever the phase is; you slide the hopper sideways until
   both drop into gaps. Install by lifting ~20 mm, pushing in, and lowering.
5. **Dead end: one-piece body.** A single body was 136 x 136 x 173 mm. It fits the bed
   upright, but then the sloped wall's layer lines run across the flow. Laying the rear
   wall flat (rotate -70 degrees about X) puts the layer lines along the flow, but the
   part then measures 208 mm in one axis and does not fit a 180 mm bed; and in that
   orientation the vertical front wall becomes a 20-degree roof over the cavity, which
   would need full support. Split into `base` + `tank` instead, which also halves the
   longest print.
6. **Dead end: perch on the tray.** With the perch hanging below the tray floor, the tray
   can only rest on the perch when printed, leaving its 95 cm2 floor as an airborne
   overhang. Moved the perch onto the `base`, below the tray and forward of it, where it
   is a cantilever off the drawer-bay side walls, does not move when the tray is pulled,
   and carries the bird's weight into the fixed part.
7. **Fixed after measuring, not after guessing:** a 2.0 mm socket wall on the base and a
   1.0 mm rim above the lid groove on the tank were both found by the thickness ray-cast,
   not by eye; both were widened. The bay floor was initially 4 mm above the faceplate's
   bottom edge, which made a 145 cm2 airborne ceiling; dropping it to the same plane
   removed that.
8. Re-exported, re-verified, rendered, wrote this.

## (c) Final dimensions, part list, capacity

Coordinates: X across the door, Y depth (negative = inside the cage, the bar wall
occupies y = -3..0), Z up from the bottom edge of the doorway.

| part | function | bbox (mm) | volume of material |
|---|---|---|---|
| `base` | faceplate, retention hooks, perch, drawer bay, tank socket | 136.0 x 151.1 x 150.0 | 235.8 cm3 |
| `tank` | the wedge hopper itself, with the lid groove | 120.0 x 116.6 x 115.5 | 163.9 cm3 |
| `tray` | removable feed trough with a rolled (`hull`) lip | 103.0 x 92.0 x 27.0 | 59.0 cm3 |
| `lid` | slides into the tank's side grooves from the back | 111.2 x 118.3 x 10.0 | 55.3 cm3 |

Key dimensions:

- Doorway assumed 110 x 110 mm, bars 3 mm at 12 mm pitch (9 mm gaps), rails along the
  top and bottom edges of the opening.
- Faceplate 136 x 150 mm, 4 mm thick, bearing on the outside of the bar wall; it
  overlaps the opening by 13 mm on each side and 20 mm below, 20 mm above.
- Feeding window in the faceplate 96 x 64 mm, corners rounded R6.
- Wedge cavity: 104 mm wide (constant), front wall vertical at y = 16, rear wall at
  70 degrees from horizontal, from z = 46 to z = 152.
- Outlet slot: 104 x 72 mm at z = 46, the full width of the hopper. 72 mm is 2.9 x the
  25 mm banana-slice diameter.
- Trough: 97 x 88 mm inside, floor at z = 17, front lip 19 mm tall with a rolled lip.
- Perch: 11 mm diameter, 88 mm long, axis 16 mm inside the cage at z = 8.3, i.e. below
  the tray floor and forward of the lip.
- Wall thickness 3 mm typical, 4 mm faceplate and lid, 2.6 mm minimum anywhere.
- Measured capacity of the wedge above the outlet: **1006 cm3**.

Assembly: hang the `base` on the door (lift ~20 mm, push in, lower); drop the `tank`
into the socket on the base's top rim; slide the `tray` in from the back of the bay;
slide the `lid` into its grooves from the back. Refilling is lid-off from outside; the
lid is 156 mm up and entirely outside the bar wall, and its front edge is captured under
a rim, so it can only leave by sliding 120 mm backwards away from the cage.

## (d) VERIFICATION

Regenerate everything:

```
for p in base tank tray lid cavity cage; do
  openscad -D "part=\"$p\"" -o $p.stl hopper.scad
done
```

All checks below were run with
`nix-shell -p 'python3.withPackages(ps: with ps; [numpy trimesh scipy networkx rtree shapely])'`.
Raw outputs are kept in `v_basic.txt`, `v_thick.txt`, `v_slot.txt`, `v_door.txt`,
`v_fit.txt`; the scripts are `check.py`, `check2.py`, `check3.py`, `check5.py`, `m.py`.

### Mesh validity and bounding box (`python3 check.py`, `v_basic.txt`)

```
== base: watertight=True winding=True euler=-4 faces=972 volume=235.8 cm3
   bbox 136.0 x 151.1 x 150.0 mm; max 151.1 (limit 175)
== tank: watertight=True winding=True euler=-4 faces=236 volume=163.9 cm3
   bbox 120.0 x 116.6 x 115.5 mm; max 120.0 (limit 175)
== tray: watertight=True winding=True euler=2 faces=136 volume=59.0 cm3
   bbox 103.0 x 92.0 x 27.0 mm; max 103.0 (limit 175)
== lid: watertight=True winding=True euler=2 faces=20 volume=55.3 cm3
   bbox 111.2 x 118.3 x 10.0 mm; max 118.3 (limit 175)
```

All four watertight with consistent winding. Euler -4 on `base` and `tank` is genus 3
(through-holes: the window, the drawer bay, the lid groove), not a defect. Largest
dimension of any part is 151.1 mm against the 175 mm limit, and each part also fits a
180 mm cube in its print orientation.

### Wall thickness (`python3 check2.py`, `v_thick.txt`)

Method: sample 80 000 points on the surface, cast a ray inward along the reverse normal,
keep only hits on a face whose normal is anti-parallel (dot < -0.95) to the start face.
That excludes the short chords across convex edges that make a naive ray cast report
false thin spots.

```
   base: n=79098 parallel-pair samples, min 2.70 mm, 1st pct 2.70, median 4.00, frac<2.4mm 0.00%
   tank: n=77175 parallel-pair samples, min 2.60 mm, 1st pct 2.98, median 3.00, frac<2.4mm 0.00%
   tray: n=74863 parallel-pair samples, min 3.00 mm, 1st pct 3.00, median 3.00, frac<2.4mm 0.00%
   lid:  n=80000 parallel-pair samples, min 4.00 mm, 1st pct 4.00, median 4.00, frac<2.4mm 0.00%
```

Minimum wall anywhere: **2.60 mm**, requirement 2.4 mm.

### Capacity, slot width, wall angle (`python3 check3.py`, `v_slot.txt`)

`cavity.stl` is generated by the same source (`part="cavity"`) as the wedge prism minus
the `tank` and `base` solids, so it is the actual void, not a hand calculation.

```
   cavity at z= 46.5: width(x)  104.0 mm, depth(y)   72.2 mm
   cavity at z= 60.0: width(x)  104.0 mm, depth(y)   77.1 mm
   cavity at z=100.0: width(x)  104.0 mm, depth(y)   91.7 mm
   cavity at z=151.0: width(x)  104.0 mm, depth(y)  110.2 mm
   cavity boundary faces that are not horizontal: min inclination from horizontal = 70.0 deg (requirement >= 60)
   front (normal -y):  110.2 cm2, inclination 90.0..90.0 deg
   rear (normal +y):  117.3 cm2, inclination 70.0..70.0 deg
   sides (normal +-x):  193.5 cm2, inclination 90.0..90.0 deg
   cavity volume = 1006.4 cm3 (target ~1000)
```

Capacity **1006 cm3** against ~1 L. Outlet slot **72 mm** against the 50 mm minimum
(2 x 25 mm slice). Shallowest wall **70 degrees** against the 60 degree minimum. The
cross-sections show the width constant at 104 mm from the outlet to the top and the
depth increasing monotonically upward: plane flow, no convergence in the second
direction, so no funnel.

### Fit through the doorway and past the bars (`python3 check5.py`, `v_door.txt`)

Method: sample the plane of the bar wall (y = -1.5) on a 0.25 mm grid with
`trimesh.contains`, and group the occupied columns into fingers.

```
   base in the doorway 0<=z<=110: 2 finger(s) width mm [9.2, 9.2]; centres x [-48.8, 48.8]; z 3.0..13.5
   base above the doorway z>110: 2 finger(s) width mm [6.2, 6.2]; centres x [-30.0, 30.0]; z 113.0..118.0
   base below the doorway z<0: 2 finger(s) width mm [6.2, 6.2]; centres x [-30.0, 30.0]; z -19.0..-13.0
   tank: no material in the wall plane
   tray: no material in the wall plane
   lid: no material in the wall plane
```

Only the `base` crosses the wall. What crosses inside the doorway spans 108.2 x 10.5 mm,
inside 110 x 110. What crosses outside the doorway is four 6.2 mm fingers, which pass
through the 9 mm gaps between 3 mm bars at 12 mm pitch with 1.4 mm clearance each side.
The two fingers of each pair are centred 60 mm apart, which is exactly 5 bar pitches, so
one lateral position satisfies all four regardless of where the bars fall.

Independent confirmation, boolean rather than sampled: intersecting the base with the
cage model gives an empty solid.

```
$ openscad -D 'pair="bc"' -o ix_bc.stl ix.scad   # intersection(base.stl, cage.stl)
$ stat -c%s ix_bc.stl
45                                               # an empty STL; no material in common
```

The `tank`, `tray` and `lid` never intersect the cage either (`ix_kc.stl`, `ix_tc.stl`
are not produced at all: OpenSCAD writes no file for an empty result).

Note on the fit rule: the `base` as a whole is 136 mm wide and does not pass through the
opening. It is not meant to: it mounts from outside, and only its perch, arms, hooks and
barbs enter the cage. Those are the numbers given above and they are all inside the
110 x 110 envelope. The `tray`, which is the part a keeper actually handles, fits through
the opening whole at 103 x 27 mm.

### Part-to-part fit (`python3 m.py ix_bt.stl ix_kb.stl`, `v_fit.txt`)

```
ix_bt.stl vol_cm3=0.00  bounds x[-51.5,51.5] y[4.0,96.0] z[14.0,41.0]   # base and tray
ix_kb.stl vol_cm3=0.00  bounds x[-55.0,55.0] y[13.0,91.2] z[46.0,46.0]  # tank and base
```

Zero intersection volume with a non-degenerate contact patch means the parts touch and
do not interfere. The tank/base contact is the plane z = 46 across the full 110 mm width
and 78 mm depth, which is the socket rim the tank sits in. Base/tray contact is the
drawer rails and the faceplate stop. The tray's front wall is 103 mm wide against a
96 mm window, so it cannot pass through the window: that is its front stop.

### Printability (`python3 check2.py`, `v_thick.txt`)

Method: rotate the mesh into its stated print orientation, then measure the area of
downward-facing facets steeper than 45 degrees from vertical, excluding facets lying on
the bed plane.

```
   base: airborne 29.30 cm2 (2.70% of total area) over 116 facets; largest single facet 2.45 cm2
   tank: airborne 27.21 cm2 (2.66% of total area) over 22 facets; largest single facet 2.79 cm2
   tray: airborne  9.39 cm2 (2.40% of total area) over 18 facets; largest single facet 3.78 cm2
   lid:  airborne 0.00 cm2
```

Print orientations: all four as modelled, i.e. no rotation, `base` and `tank` upright on
their own bottom faces, `tray` floor down, `lid` flat. The airborne area that remains is
in narrow strips: the drawer rails' 4 mm undersides, the 5 mm step where the tank's side
walls thicken for the lid groove, the top edge of the feeding window, the perch's
underside, and the tray's rolled lip. Each is a short bridge, not a plateau; the largest
single downward facet on any part is 3.8 cm2. I would print all four without support and
expect only cosmetic droop on the perch underside.

Layer lines and flow: the requirement cannot be met for both faces of a wedge at once,
and I did not meet it in the strict sense. Aligning layer lines with the flow on the
70-degree rear wall means laying that wall on the bed, which (i) makes the part 208 mm
long, past the 180 mm bed, and (ii) turns the vertical front wall into a 20-degree
overhang needing full support. I printed the tank upright instead. In that orientation
the front wall and both side walls are vertical, so they have no stair-stepping at all,
and the 70-degree rear wall steps 0.2/tan(70) = **0.073 mm** horizontally per layer,
about a seventh of a banana slice's minimum thickness. This is a deliberate trade, and
the stated requirement is not satisfied as written.

### What I did not verify

- **No slicer dry-run.** I did not run Bambu Studio, PrusaSlicer or any slicer, so I have
  no G-code, no printed time or filament estimate, and no slicer's own support/overhang
  verdict. The overhang numbers above are my own face-normal analysis of the meshes.
- **Nothing was printed and nothing was tried on a real cage.** Bar pitch, wire diameter,
  the presence of rails at the top and bottom edges of the opening, and the 110 x 110
  opening itself are all taken from the brief; the cage model is my reconstruction of
  them, so the empty base/cage intersection proves consistency with the brief, not with a
  particular cage.
- **Flow behaviour is argued, not simulated.** I ran no discrete-element or physical test
  of sticky slices in the slot. The design leans entirely on the geometric rules given in
  the brief (plane flow, 72 mm slot, no convergence, 70-degree minimum wall).
- **Bird-proofing is argued, not tested.** The claim that a conure cannot lift the
  assembly 19 mm to disengage the barbs is an inference from the mass of the loaded
  hopper, not a measurement.
- **The tank is retained in its socket by gravity only.** No snap, no fastener. It is
  outside the cage and weighs about 1.2 kg loaded; I did not verify it against being
  knocked sideways by a person.
- Fillets: edges that face the bird are rounded (window R6, faceplate corners R8, perch
  cylindrical, tray lip rolled with `hull`), but I did not run a systematic
  minimum-edge-radius check over every edge of every part.

## Clean room

I designed from the brief and my own knowledge. I did not open, list, search or fetch any
other hopper design, repository, transcript, note or memory file. No such material was
encountered accidentally.

## (e) Wall time

Start 2026-09-08 18:16 -0700, finish 2026-09-09 05:0x -0700. The elapsed clock is about
10 h 45 m, but that is not working time: this worker session was suspended and resumed
several times, and long stretches of that span had no work in progress. Actual work is
roughly 2 h of modelling, verification and rendering, dominated by nix-shell environment
builds and the two rounds of rework in step 5 and step 6 above.

## Files

- `hopper.scad` — the source; `part` selects `assembly`, `assembly_nocage`, `base`,
  `tank`, `tray`, `lid`, plus the diagnostic solids `cavity` and `cage`.
- `base.stl`, `tank.stl`, `tray.stl`, `lid.stl` — the four printed parts.
- `cavity.stl`, `cage.stl` — diagnostic solids used by the checks, not printed.
- `ix.scad`, `ix_*.stl` — pairwise boolean intersections used for the fit checks.
- `check.py`, `check2.py`, `check3.py`, `check4.py`, `check5.py`, `m.py`, `verify.py` —
  the verification scripts; `v_*.txt` their captured output.
- `img/` — renders: four views of the assembly in the cage, four of each part.
- `critic/round-1.md` … — the critic rounds.
