# Green-cheek conure seed hopper — design report

Wall time, start to finish: **31 min** (07:54 → 08:25 PDT, 2026-09-05; budget 90).

## (a) Approach and tools

**Tools:** OpenSCAD 2021.01 (parametric source, STL export, PNG renders via xvfb), Python 3.13 + trimesh 4.9 / manifold3d / shapely (mesh validity, thickness, sections, booleans, print-orientation overhang audit), PrusaSlicer (slicer dry run, PETG, 180 mm bed). All from nixpkgs via `nix-shell -p`, nothing installed.

**Why OpenSCAD:** the part is all plates and prisms; a 150-line script with every dimension as a named parameter is the smallest thing that regenerates all five STLs, and its CSG tree is easy to audit. CadQuery would give fillets for free but costs a heavier toolchain; time budget said no.

**Design in one sentence:** a plane-flow wedge (one vertical wall, one wall at 66°, parallel end walls) whose whole cross-section passes through the door opening, refilled through a sliding lid outside the cage and dispensing through a 50 mm × 130 mm slot into a hull-lipped tray inside, with the perch below the tray's front edge.

Dumbest design that satisfies the brief, and why this isn't quite it: a single-piece wedge printed upright would be dumber, but layer lines would then cross the flow on the sloped wall (0.09 mm steps every layer, exactly where sticky banana slides). Printing the body on its end wall (X axis vertical) puts every hopper wall in the layer plane — but a one-piece body then has a 110 × 130 mm ceiling. So the body is **two mirror halves split on the mid-plane**, each printed end-wall-down with zero overhangs beyond a 3.6 mm bridge. The halves are located and clamped by the other parts (bracket window, lid channels, cage bars), not by fasteners. That is the one non-obvious trade.

**Parts (5):**

| part | role | print orientation | filament (PrusaSlicer) |
|---|---|---|---|
| body_R, body_L | wedge halves, through the door; outer bottom flange bears on bars below the opening | end wall on bed, seam up | 105 g each, ~8.5 h each |
| lid | slides out (away from cage) to refill; headboard bears on bars above/beside the opening and is the body's inward stop | flat, headboard up | 51 g, 4.4 h |
| bracket | inside the cage: plate bears on bars, window edges sit in grooves in the body end walls (Y-lock), shelf + guide rails + front ridge for the tray, perch | on its X end (perch = vertical column) | 112 g, 7.7 h |
| tray | removable, hull lip on front and sides; slides in from the cage side over the ridge (lift front 7 mm) | floor down | 70 g, 6.5 h |

**Mounting / assembly:** push the two halves through the door opening from outside (seam vertical); from inside drop the bracket down over the body so its window edges enter the vertical grooves in the end walls (grooves at Y 0–3.6, plate at Y 0.3–3.3, bars sandwiched between the lid headboard / bottom flange at Y ≤ −2.5 and the plate); slide the lid in from outside until it hits the stop lip; slide the tray onto the shelf. Outward pull (bird) → grooves push the plate against the bars. Inward push (human) → stop lip → lid headboard → bars, plus bottom flange → bars. Lid opens only by sliding outward, outside the cage. Nothing smaller than a 129 × 48 mm plate is detachable; there are no screws, pins or glue.

## (b) Steps taken, including dead ends

1. Wrote the parametric SCAD, rendered STLs, ran trimesh checks. First round found: **lid headboard intersecting the body rim (90 mm³ per half)**, **tray rear corners intersecting the body end walls (70 mm³)**, and a bracket U-frame whose upper arm would be a 62 mm unsupported cantilever in its print orientation.
2. Fixed: headboard split into three blocks clearing the rim; tray rear corners cut down below the outlet; **U-arms replaced by 45° corners** (the window edge engages the grooves for ~6 mm, which is plenty in shear; the plate is now 63 mm tall).
3. Thickness audit then showed the **back wall was 1.6 mm at the top, not 2.4** — the outer profile's top corner was offset only horizontally so the two faces diverged; this also left a 0.13 mm sliver between the flange trim plane and the wall. Fixed by offsetting the outer corner along the wall. That audit itself first used trimesh's built-in ray thickness and returned garbage (min 0.0); replaced with an explicit inward ray cast from a 0.05 mm inset origin (`thick.py`).
4. Tray lip was a knife edge (wedge tapering to zero at the inner edge) → made it a solid inward block, 3.4 mm thick at the edge. Tray bottom chamfer 2.4 → 1.2 mm because a 2.4 chamfer thinned the floor/wall corner to 1.7 mm.
5. Lid print orientation was first set upside-down (would have made the plate a 5800 mm² ceiling); the finger tab was moved to the top face so the lid prints flat.
6. Dead ends on orientation, decided on paper before modelling: sloped-wall-on-bed (front wall and flange become ~24°-from-horizontal plates), one-piece X-axis print (110 × 130 ceiling), perch on the tray (below the floor = below the bed), bracket plate-down (perch = 165 mm bridge).

## (c) Final dimensions, part list, capacity

Coordinates: X across the door, Y through it (negative = outside cage, bars at Y ∈ [−2.5, 0]), Z up, Z = 0 at the outlet.

- Hopper interior: width 130, height 120 (usable to 116.7 under the lid), depth 50 at the outlet → 101.9 at the top; back wall at **66.2°** from horizontal, front wall vertical, end walls vertical and parallel (plane flow, no convergence in X).
- Outlet slot: **50.2 × 130 mm**, full width, at Z = 0; tray floor 10 mm below it.
- Through-section in the bar plane: **134.8 × 117.0 mm** in a 140 × 170 door (2.6 mm play per side in X; offset so the flange/headboard overlap the bars by ≥ 12.7 mm — one bar pitch — on every bearing edge).
- Capacity: **1.145 L** by boolean (interior prism minus body), 1.147 L analytic. Cavity check (see below) confirms the interior is one watertight void.
- Per-part bounding boxes (mm): body halves 67.4 × 109.1 × 161.2 each; lid 165.4 × 52.2 × 44.2; bracket 165.4 × 113.8 × 59.0; tray 144 × 100 × 30. Largest axis 165.4 < 175.
- Walls: 2.4 mm plates everywhere on the body, lid and tray; bracket plate 3.0; lid headboard 4.0 + 2.4; perch Ø16 solid.
- Tray: 100 deep, 30 tall, 8 mm inward hull lip along the front and the front 40 mm of each side (the rear 60 mm of the sides sit under the hopper, where a lip would collide with the body); the rear wall is 8 mm tall and the rear corners are cut to the outlet level so they clear the body; the bracket plate closes the back.
- Perch: Ø16 × 165 mm, axis 25 mm below the outlet and 2 mm in front of the tray's front wall; the bird stands ~37 mm below the lip top.

Files: `hopper.scad` (source; `part=` selects), `render.sh` (STLs), `render_png.sh` + `crop.py` (images), `verify2.py` + `thick.py` + `debug.py` (checks; output `verify.json`), `slicer.ini` + `slice.sh` (slicer dry run; output `slice.log`, `print_*.gcode`), `print_*.stl` (each part already in its print orientation, on Z = 0), `<part>.stl` (assembly coordinates), `assembly.stl`, `img_*.png`.

## (d) VERIFICATION

Every number below is copied from `verify.json` (produced by `python3 verify2.py` on the final STLs) or `slice.log`; the commands are in the named scripts. Sampling: 8000 surface points per part.

**Mesh validity** (trimesh, after `merge_vertices`): all five parts `watertight: true`, `winding_consistent: true`, Euler number 2, zero internal faces (faces with solid on both sides), positive volumes. The interior cavity boolean is also watertight.

**Bounding box vs 175 mm:** extents above; `max_extent_ok_175: true` for every part.

**Wall thickness vs 2.4 mm** (inward ray from each sampled point, min hit distance; samples within 1 mm of a convex edge are reported separately because a ray next to an edge measures the corner, not the wall):

| part | median | samples < 2.4 (all) | < 2.4 and > 1 mm from any convex edge | those points |
|---|---|---|---|---|
| body_R | 2.4 | 28 / 8000 | 1 (2.34) | flange–wall junction |
| body_L | 2.4 | 30 / 8000 | 2 (2.32) | back-wall top edge (acute 66° cut), outlet bottom edge (acute) |
| lid | 6.4 | 0 | 0 | — |
| bracket | 3.0 | 42 | 4 (1.07) | tips of the 1.2 mm tray guide rails |
| tray | 2.4 | 12 | 9 (1.43) | front corners where the 45° lip underside and the 1.2 mm bottom chamfer meet the r=6 corner arc |

So: every plate measures 2.4 or more; the sub-2.4 readings are the acute corners where a sloped wall is cut square (the wall's top and bottom edges) and the 1.2 mm guide rails, which are deliberate small features, not walls. The back wall thinning to 1.6 mm found mid-way through was fixed and is gone (median 2.4, no thin samples on the wall face).

**Capacity vs 1 L:** cavity boolean 1.145 L (prism Y −49.1…57.4, Z 0…116.7 minus both halves, manifold engine), analytic 1.147 L. Target "about 1 L" met with 15% margin for a 10-day refill.

**Slot width vs 50 mm:** section of both halves at Z = 0.5: back-wall inner face to front-wall inner face = **50.22 mm**; interior depth at Z = 50 is 72.1 mm (widening upward, no converging funnel).

**Wall angle vs 60°:** every upward-facing face inside the cavity (normal z > 0.05, centroid inside the interior box) is at **66.2°** from horizontal, total area 16454 mm²: that is the back wall alone. No other interior face faces upward (no shelves, no ledges below the lid).

**Fit to 140 × 170 with 12 mm bars:** the body sliced to the bar-plane slab Y ∈ [−2.5, 0] has bounding box 134.8 × 117.0 → `fits_140x170: true`. Bearing overlaps beyond the opening: bottom flange 15 mm below, lid headboard 15 mm above and 12.7 mm beside, bracket plate 12.7 mm beside and 14 mm below — each ≥ one 12 mm bar pitch, so each bearing edge crosses at least one bar regardless of phase. Not verified: an actual cage (no physical door here); bar diameter assumed 2.5 mm (parameter `bar_d`).

**Assembly clash check:** pairwise manifold booleans of all 10 part pairs in assembly position: every intersection volume **0.0 mm³** (three earlier clashes fixed as described in (b)).

**Printability:** per part, in the shipped print orientation (`print_*.stl`), the area of downward-facing faces off the bed by overhang angle:
- body halves: only a 434 mm² "flat ceiling" = the roof of the 3.6 mm-wide bracket groove on the bed face (a 3.6 mm bridge); no other overhangs. Height 67.4 mm.
- lid: 417 mm² of ceilings, all bridges ≤ 6.4 mm wide (headboard block over the rim clearance gap).
- bracket: 133 mm² flat = the 1.2 mm-wide underside of the bed-side guide rail plus two 3 × 4 mm stubs; 177 mm² at 30–45° (rail ramps, plate corner roundings), 74 mm² at 45–60° (rounded plate corners near the bed). Height 165.4 mm; footprint is an F of 3 mm walls plus the Ø16 perch column — needs a brim.
- tray: only 30–60° overhangs (the 45° hull-lip undersides and the bottom chamfer); nothing flat.
- **PrusaSlicer dry run** (`slice.sh`, PETG 250/70 °C, 0.2 mm layers, 3 perimeters, 20% gyroid, supports OFF, bed 180 × 180): all five parts sliced without error or warning on the bed; output in `print_*.gcode`. I used a hand-written minimal profile, not Bambu's A1 mini profile, so times (8.5 / 8.5 / 4.4 / 7.7 / 6.5 h) are indicative only. Elephant-foot and PETG bridging quality are not modelled by the slicer.

**Not verified / known gaps (plain statement):**
- No physical print, no physical cage; clearances (0.3 mm) are untested for PETG on an A1 mini.
- "Rounded edges" is only partly met: tray vertical corners r = 6, bracket plate corners r = 4, perch round; the body halves and lid are square-cut 2.4 mm plates. The body's outlet edges inside the cage are sharp-cornered.
- Lid has no detent; it is held closed by friction, gravity, and being outside the cage. Tray retention is a 7 mm ridge the bird would have to lift-and-pull over.
- The seam between the two body halves is a plain butt joint held to ≤ 0.6 mm by the bracket window and lid channels; seed dust can pass it, seed cannot.
- Flow of dried banana was reasoned (slot 2× slice width, 66° wall, plane flow, layers along flow), not simulated or tested.
- The bracket's 62 mm-tall plate is a lone 3 mm wall in print; it may need a brim and slow first layers. Not tested.
