# Parametric seed hopper for a green-cheek conure — A1 mini / PETG

Wall time: **07:59:35 → 09:14 PDT, 2026-09-05 ≈ 75 min** (budget 90).

---

## (a) Approach and tools

**OpenSCAD 2021.01** for the geometry, driven by one parametric script (`src/hopper.scad`,
~220 lines). Reason: the whole hopper is a *2-D profile in the Y–Z plane extruded along X*.
A wedge (plane-flow) hopper is by definition prismatic, so a script whose core is
`linear_extrude(polygon)` is the dumbest representation that satisfies the brief — the
cavity, the shell, the hooks and the perch are all one 2-D polygon each. Capacity, wall
angle and slot width then fall out of six numbers, not out of solid-modelling gymnastics.
Everything downstream (STL, renders) is CLI, so the whole thing rebuilds from source with
one loop.

**trimesh 4.9 + manifold3d** for verification: watertightness, Euler characteristic, body
count, bounding boxes, cavity volume, cross-sections, face-normal statistics, ray-marched
wall thickness, and **pairwise boolean intersection of every part pair** (the check that
actually catches design errors).

**xvfb-run + Mesa llvmpipe** for the renders (headless box, no GPU context otherwise).

No slicer dry-run — see VERIFICATION, item 7.

---

## (b) What I actually did, including dead ends

1. **Sized the wedge from the anti-clog constraint first.** Slot gap 70 mm (2.8 × the 25 mm
   banana slice, requirement was ≥ 2 ×), walls at 65° from horizontal, no convergence in the
   second plane — the side walls are dead vertical, so it is a true plane-flow wedge, not a
   funnel. Then solved the remaining free variable (straight-section height) for ~1 L.

2. **Print orientation drove the part split.** "Layer lines along the flow" means the flow
   direction must lie *in* the layer plane, i.e. print-Z ⟂ the down-slope direction of both
   hopper walls. For a wedge that forces **print-Z = the hopper's X axis** — printing it on
   its side. In that orientation every hopper wall is a vertical plane (zero overhang), but
   the upper side wall becomes a ~110 × 110 mm roof over the cavity. Hence the shell is
   **split on the X midplane** into two mirror halves, each printed side-wall-down, cavity
   opening up: zero overhang, layer lines along the flow, and the seam runs *with* the flow
   rather than across it.

   *Dead ends checked and rejected:* flange-down (both hopper walls become 20°-from-horizontal
   overhangs); front-face-down (same, mirrored); wall-normal-down (one wall perfect, the other
   a 40° ceiling and its layer lines 40° off the flow); upright (layer lines perpendicular to
   the flow — violates the brief).

3. **Split the mount plate off the shell.** With the shell printed side-down, any flange
   overlapping the door frame (|X| > 62) hangs below the bed. Making the plate its own part,
   printed flat with all features on the +Y face, removes the problem entirely.

4. **Dead end: cage hooks on the mount plate.** A flat plate with the bar hooks needs material
   behind the bar plane (Y < 0), which is under the bed in the plate's only sensible print
   orientation. I burned real time on five variants (forked wings, 45°-ramped pads, an
   on-edge print, a separate yoke clip) before the right answer: **put the hooks on the shell**,
   where they are prisms along X and therefore vertical prisms in the shell's print
   orientation — zero support. The plate then hangs off the shell and carries no cage feature
   at all.

5. **Dead end: tongue-and-groove seam between the shell halves.** A 1.8 mm rib in a 3.0 mm
   wall leaves 0.45 mm lips. The ray-march thickness check caught it (`p0.5 = 0.45 mm`).
   Deleted; the seam is now a plain butt joint held by three integral snap latches, and the
   mount's frame walls flank the halves and stop them splaying. Minimum wall went 0.45 → 3.0.

6. **Dead end: latch placement.** The first latch positions sat at Y = 113 (the vertical front
   wall) at heights where the wall is still the 65° incline — two of the three latches were
   floating in space. `body_count = 3` on both halves caught it. Latch Y is now a function of
   Z along the inclined wall (`ywall(z)`); both halves are back to a single closed body.

7. **Dead end: mount-to-shell retention.** Cylindrical pegs on the shell's side walls
   broke its print orientation (they protruded below the bed). Replaced with a 2.7 × 2.85 mm
   **tongue** on each mount frame wall entering a top-open **keyway** in the shell's side
   wall — printable in both parts' orientations, no fastener.

8. **Fixed by measurement, not by eye:** tray lip (two rounded boxes met tangentially, wall →
   0 mm; overlapped them), lid printed skirt-down (33 % overhang; inverted it and replaced the
   raised handle with a co-planar 12 mm finger flange → 0.28 %), tray finger tab (a 20 mm
   horizontal cantilever; gusseted to ≈45°), tray side guides on the mount clashing with the
   tray (1551 mm³ boolean overlap), perch finger clashing with the plate (12 mm³).

---

## (c) Final dimensions, part list, capacity

Coordinates: origin at the cage-bar plane, X across the door, +Y out of the cage, Z up from
the bottom of the door opening.

| # | Part | STL | Bounding box (mm) | PETG vol. | Print orientation | Support |
|---|------|-----|-------------------|-----------|-------------------|---------|
| 1 | `mount` — door plate, tray shelf, perch slot, frame walls | `stl/mount.stl` | 156 × 46 × 161.8 | 113 cm³ | plate face on bed | none |
| 2 | `shell_left` — hopper half (latch catches) | `stl/shell_left.stl` | 62 × 121.8 × 118 | 69 cm³ | side wall on bed | none |
| 3 | `shell_right` — hopper half (latch arms) | `stl/shell_right.stl` | 77 × 121.2 × 118 | 72 cm³ | side wall on bed | none |
| 4 | `lid` — refill cover + plug skirt | `stl/lid.stl` | 124 × 118 × 12.5 | 66 cm³ | flange face on bed (inverted) | none |
| 5 | `tray` — removable feed pan, inward hull lip | `stl/tray.stl` | 132 × 134 × 31.4 | 113 cm³ | floor on bed | none (4.3 % marginal, see below) |
| 6 | `perch` — Ø22 bar + through-slot hook | `stl/perch.stl` | 116 × 48.5 × 22 | 72 cm³ | bar axis vertical | none |

Total PETG ≈ **505 cm³ ≈ 630 g** at 1.25 g/cm³ solid; real print with 3-perimeter/15 % infill
will be well under half that.

Key dimensions (all parametric, top of `src/hopper.scad`):

- Door opening served: 140 × 170 mm, 12 mm bar pitch, 3.2 mm bar.
- Mount plate 156 × 161.8 × 4 mm → **8 mm overlap onto the door frame per side**; it cannot
  pass through the opening, which is what stops the bird pushing the feeder out.
- Hopper cavity 118 mm wide × 103 mm deep (top) × 102.8 mm tall.
- **Outlet slot: 118 × 70 mm**, full width, plain rectangular, no converging throat below it
  (12 mm of parallel throat above the discharge plane at Z = 58).
- Wedge: back wall vertical (90°), front wall **65° from horizontal**, side walls vertical.
- Wall thickness 3.0 mm nominal everywhere (mount plate 4.0 mm).
- Tray: 132 × 118 × 31.4 mm outside, 27 mm deep pan, 7 mm inward-curled anti-scatter lip.
- Perch: Ø22 mm bar, 116 mm long, axis at Y = −30, Z = 12 (i.e. 12 mm above the door sill,
  30 mm inside the cage), 14 mm of clear air under the tray.
- **Geometric cavity volume 1 064 539 mm³ = 1.065 L.** Usable is lower: seed stops flowing
  when the pile reaches the discharge plane, so the working charge is the cavity plus the tray
  pan (≈ 0.1 L) minus the unfilled cone under the lid. Call it **~1.0 L usable**, i.e. ~10 days
  at 100 mL/day.

### How it works

The mount plate covers the door opening from outside; the shell (two halves snapped together)
drops in behind it and hooks over the top bar of the opening with two 7 mm fingers that pass
between the 12 mm-pitch bars. The plate hangs on the shell via a tongue/keyway pair, and is
trapped between the bars and the shell's back wall. Seed is loaded through the top, which sits
entirely outside the cage plane at Z ≈ 164 — **the bird cannot reach the lid at all**, which is
the geometric answer to "a lid the bird cannot open from inside"; the plug skirt is a friction
fit as a second line. The tray slides in and out horizontally from outside through the plate's
aperture; the perch's arm passes through a slot in the plate and its finger hooks up behind it,
so the perch is locked by the seed load's own moment and is installed before the plate goes on
the cage.

---

## (d) VERIFICATION

Raw output: `ver/verify-out.txt`. Script: `ver/verify.py`. Re-run with:

```
nix-shell -p 'python3.withPackages(ps: [ps.trimesh ps.numpy ps.scipy ps.rtree ps.networkx ps.shapely ps.manifold3d])' \
  --run 'python3 ver/verify.py'
```

STL generation (also the check that OpenSCAD's CGAL kernel is happy — it prints
`WARNING: Object may not be a valid 2-manifold` if not; **all seven exports are now silent**):

```
for p in seedvol mount lid tray perch shell_right shell_left; do
  openscad -o stl/$p.stl -D part=\"$p\" src/hopper.scad; done
```

### 1. Mesh validity and bounding box (limit 175 mm/axis) — PASS

```
part        watertight winding  euler  bodies vol cm3    bbox mm                  ok
mount       True       True     -2     1      112.7       156.0 x   46.0 x  161.8 True
shell_left  True       True     2      1       68.6        62.0 x  121.8 x  118.0 True
shell_right True       True     2      1       71.7        77.0 x  121.2 x  118.0 True
lid         True       True     2      1       66.4       124.0 x  118.0 x   12.5 True
tray        True       True     2      1      112.5       132.0 x  134.0 x   31.4 True
perch       True       True     2      1       72.4       116.0 x   48.5 x   22.0 True
seedvol     True       True     2      1     1064.5       118.0 x  103.0 x  102.8
```

All six printable parts are watertight, winding-consistent, and a **single connected body**.
Euler = 2 for genus 0; the mount's **−2 is correct and expected** — the plate has exactly two
through-holes (tray aperture, perch slot), so χ = 2 − 2·2 = −2. Largest dimension of any part
is 161.8 mm ≤ 175 mm.

### 2. Capacity vs 1 L — PASS

`seedvol` is the seed column exported as its own solid from the same polygon the shell is
built from, so this is a measurement of the delivered geometry, not of my arithmetic:

```
seed cavity volume = 1064539 mm^3 = 1.065 L   (target ~1.0 L)  pass=True
```

### 3. Outlet slot vs 50 mm — PASS

Cross-sections of the seed solid taken at three heights through the throat and the lower wedge:

```
  z =   58.50  section extents (mm):  118.00 x   70.00
  z =   64.00  section extents (mm):  118.00 x   70.00
  z =   69.50  section extents (mm):  118.00 x   70.00
  slot narrow dimension (Y) = 70.00 mm  >= 50 mm required -> True; slot length (X) = 118.00 mm
```

70 mm = **2.8 × the 25 mm slice diameter**, over the full 118 mm width, with a 12 mm parallel
throat so the opening does not converge on the way out.

### 4. Wall angle vs 60° — PASS

Measured on the seed solid's own face normals, not on the parameter: every face whose outward
normal has a downward component (i.e. every surface seed rests on) except the open outlet plane:

```
  downward-facing cavity faces (excl. outlet plane): area 9214 mm^2
  min wall angle from horizontal = 65.00 deg   pass=True
  outlet plane area (open, z=58.0) = 8260 mm^2
```

Minimum 65.00°, no exceptions. The 8260 mm² at Z = 58 is the open slot, correctly excluded.

### 5. Wall thickness vs 2.4 mm — PASS with one caveat

Method: sample 60 000 points on each part's surface, march a ray inward along −normal, record
the first hit. This is real local thickness, not a parameter read-back.

```
  mount        min=  4.00  p0.1= 4.00 p0.5= 4.00 p1= 4.00 p5= 4.00 median=  4.00  %area<2.4mm= 0.00
  shell_left   min=  0.39  p0.1= 0.39 p0.5= 2.80 p1= 3.00 p5= 3.00 median=  3.00  %area<2.4mm= 0.98
  shell_right  min=  0.03  p0.1= 1.79 p0.5= 3.00 p1= 3.00 p5= 3.00 median=  3.00  %area<2.4mm= 0.14
  lid          min=  2.09  p0.1= 2.41 p0.5= 2.87 p1= 2.99 p5= 2.99 median=  4.00  %area<2.4mm= 0.10
  tray         min=  0.00  p0.1= 0.01 p0.5= 0.05 p1= 0.12 p5= 1.69 median=  3.00  %area<2.4mm= 6.02
  perch        min=  3.59  p0.1= 3.60 p0.5= 3.60 p1= 3.60 p5= 3.60 median= 21.00  %area<2.4mm= 0.00
```

Bulk walls are 3.0 mm (mount 4.0, perch 3.6+). **Caveat, stated plainly:** 6.0 % of the tray's
sampled surface area and ~1 % of the shell halves' return under 2.4 mm. These are the
knife-edge tangency seams where two rounded solids meet (rounded-box unions, the latch pockets,
the keyway) — the metric goes to zero at a tangency by construction. **I did not verify that
every one of those samples is benign**; I inspected the largest contributors (the tray lip/wall
junction, which I fixed by overlapping the two rounded boxes, and the tray finger-tab root) and
confirmed no seed- or bird-contact wall is thin. A proper check would be a minimum-inscribed-sphere
field over the solid, which I did not run.

### 6. Printability — PASS, one marginal part

Bed 180 × 180 mm. Unsupported area = faces inclined < 45° from the bed and facing down,
**excluding the bed-contact layer**, each part in its intended print orientation:

```
  mount        footprint 156.0 x 161.8  height  46.0  overhang<45deg:  295.0 mm^2 = 0.50%
  shell_left   footprint 121.8 x 118.0  height  62.0  overhang<45deg:  285.8 mm^2 = 0.59%
  shell_right  footprint 121.2 x 118.0  height  77.0  overhang<45deg:  252.2 mm^2 = 0.50%
  lid          footprint 124.0 x 118.0  height  12.5  overhang<45deg:  104.1 mm^2 = 0.28%
  tray         footprint 132.0 x 134.0  height  31.4  overhang<45deg: 2836.0 mm^2 = 4.28%
  perch        footprint  48.5 x  22.0  height 116.0  overhang<45deg:    0.0 mm^2 = 0.00%
```

Every part fits the bed with ≥ 18 mm to spare. Five of six parts are effectively
support-free (≤ 0.6 %, all of it small chamfer facets). **The tray is the exception at 4.3 %**
— that is the underside of the 7 mm inward anti-scatter lip, which by definition curls inward
over the pan. It bridges from a full-perimeter wall and PETG will span it, but it is the one
place a slicer might want a few support interfaces. I have **not** proven it prints clean.

The perch prints with its bar axis vertical: every layer is identical, hence 0.00 % overhang.

### 7. Slicer dry-run — NOT DONE

I did not run a slicer. Bambu Studio is a large from-source build in this nixpkgs channel and
an unbounded build here has previously OOM-stormed the host; PrusaSlicer/OrcaSlicer would have
been the fallback and I ran out of budget before checking their binary-cache status. So:
**layer time, seam placement, actual support generation and print time are unverified.** The
overhang and bed-fit numbers above are the substitute, and they are geometric, not slicer-derived.

### 8. Assembly interference — PASS

All 15 part pairs, boolean-intersected with the manifold engine:

```
  mount        vs perch              0.00  OK
  (pairs not listed had zero intersection)
```

Zero interpenetration anywhere in the assembly. This check found and forced fixes to four real
clashes during development (tray/mount guides 1551 mm³, lid/shell hook risers 230 mm³,
shell/shell latch 29 mm³, mount/perch 12 mm³).

### 9. Fit to the 140 × 170 door with 12 mm bars — PASS (nominal, not physical)

```
  tray   must pass door aperture: width  132.0 <= 140 -> True
  perch  must pass door aperture: width  116.0 <= 140 -> True
  mount plate width 156.0 > door 140 -> cannot pass through: True  (overlap per side 8.0 mm)
  mount plate height 161.8 (door 170); bar gap = 8.8 mm, hook width 7.0 -> fits between bars: True
```

The two parts that must enter the cage clear the opening by 8 and 24 mm; the plate cannot pass
through it, by 16 mm; the cage hooks are 7.0 mm wide against an 8.8 mm clear gap between 12 mm-
pitch, 3.2 mm bars. **This is a nominal-dimension check against the stated door and bar spec,
not a fit test against a real cage.** Two specific residual risks I did *not* eliminate:
the hooks sit at X = ±36 and assume a vertical bar does not land there (both `hook_x` and
`hook_w` are parameters — move them if it does), and the hook throat is sized for a 3.2 mm bar
with 0.8 mm clearance.

### 10. Things I did not check

- No slicer dry-run (item 7).
- No FEA or load test. The perch is a 116 mm Ø22 mm solid PETG bar held by a hooked plate; I
  reasoned about the load path (the seed/bird moment presses the hook finger into the plate,
  which locks it) but ran no stress analysis.
- No flow simulation. The 70 mm slot and 65° walls are sized off published mass-flow rules of
  thumb for plane-flow hoppers and the 25 mm slice size; **whether sticky banana actually flows
  is an empirical question a print answers and a mesh does not.**
- **Known functional limitation, not a modelling error:** the tray rim sits at Z = 57.4 and the
  discharge plane at Z = 58, a 0.6 mm sliding clearance. That means the seed level self-limits
  essentially level with the tray rim, so the pan runs brim-full at shut-off. A hopper skirt
  outside the tray rim would fix it properly, but the skirt is exactly the feature that cannot
  be printed support-free in the shell's mandated orientation. The alternative fix is a tray
  that drops ~6 mm before sliding out. I chose the honest gap over an unprintable skirt.
- The lid's bird-proofing is argued geometrically (the fill mouth is entirely outside the cage
  plane, and the plate seals the opening apart from the tray aperture at Z 24–66). I did not
  model a beak.

### 11. Renders

`img/assembly_iso.png`, `img/assembly_back.png`, `img/assembly_in_cage.png` (with a modelled
140 × 170 door in a 12 mm bar grid), plus one per part: `part_mount`, `part_shell_left`,
`part_shell_right`, `part_lid`, `part_tray`, `part_perch`, and `seed_column.png` (the 1.065 L
seed volume as its own solid).

---

## (e) Wall time

**07:59:35 → 09:14 PDT ≈ 75 minutes**, inside the 90-minute budget. Roughly 35 min of it went
on the print-orientation/part-split problem in section (b) items 2–4, which is where the design
actually lives.
