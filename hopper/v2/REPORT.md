Evolved design derived from the [fable submission](../fable/REPORT.md): the same five parts, with the body seam turned from a butt joint into a self-locating lap.

# Green-cheek conure seed hopper v2 — design report

Directive (verbatim): "it's not realy clear how this fable bird hopper submission is meant to hold together. did your worker... cut to hopper in half to avoid needing supports? if so it succeed in not needing supports, but a sliced-in half hopper doesn't hold bird seed ;)"

## (a) Approach and tools

**Tools:** OpenSCAD 2021.01 (parametric source; STLs and previews through the root `./build`; section renders via xvfb), Python 3.13 + trimesh 4.9 / manifold3d / shapely / scipy (mesh validity, thickness, sections, booleans, the seam-void raster, print-orientation overhang audit), PrusaSlicer 2.9.4 (slicer dry run, PETG, 180 mm bed). All from nixpkgs via `nix-shell -p`.

**Design in one sentence:** a plane-flow wedge (one vertical wall, one wall at 66°, parallel end walls) whose whole cross-section passes through the door opening, refilled through a sliding lid outside the cage and dispensing through a 50 mm × 130 mm slot into a hull-lipped tray inside, with the perch below the tray's front edge; the body is two halves split on the mid-plane so each prints end-wall-down, and the halves meet on a lap joint.

**Why two halves, still:** printing the body on its end wall (X axis vertical) puts every hopper wall in the layer plane, so layer lines run along the flow; a one-piece body in that orientation has a 110 × 130 mm ceiling. Two mirror halves have no overhang beyond a 3.6 mm bridge. The fable submission left the seam a plain butt joint: nothing located one half to the other, and the gap was whatever the bracket and lid tolerances gave.

**The seam (v2):** a half-lap along the whole seam. Each 2.4 mm wall is split at its mid-surface; on `body_R` the outer half (the tongue, `t/2 − seam_clr` = 1.0 mm thick) runs `seam_lap` = 6 mm past the seam plane, on `body_L` the outer half is cut back by `seam_lap + seam_clr` (the pocket) while its inner half runs to the seam. The tongue sits in the pocket with `seam_clr` = 0.2 mm on every face: 0.2 mm between the inner skins at the seam plane, 0.2 mm between tongue and pocket floor, 0.2 mm at the tongue's end. Seed leaving the cavity would have to pass a 0.2 mm slit, turn 90°, run 6 mm along the lap, and turn again: seed-tight by geometry, not by clamping. The lap on the 66° back wall, the vertical front wall and the horizontal roof locates the halves in Y and Z; the bracket window and lid channels hold them together in X as before. The stop lip is lapped the same way (split in Y). The bottom flange is outside the cavity and carries no seed, so it is wholly on the tongue side (an offset butt with the same 0.2 mm gap): a lap there would put the flange's inner half under the wall's tongue with zero clearance.

**Why a lap and not:** a tongue-and-groove (a groove in a 2.4 mm wall leaves 0.6 mm cheeks; the tongue would be under 1 mm anyway); a cover strip (a sixth part, and the seam is still a butt joint under it); a full nesting sleeve (one half's cavity shrinks by a wall thickness, the halves stop being mirror images and the flow section steps at the seam); pins (extra parts, no seal). The lap is the one joint that seals, locates, needs no new part, and in the existing print orientation is nothing but a wall that stops 6 mm short or runs 6 mm long.

**In the source** the joint is one 2D feature, `seam_lap(g)`: the outer half of the body's cross-section (outer profile minus the interior profile offset by `t/2 + g`, plus the lip's outer half and the flange). `body_half(tongue)` intersects the full `body()` with the half-space beyond the seam plane, unions `seam_lap(seam_clr)` over the tongue's length for `body_R`, or subtracts `seam_lap(0)` over the pocket's length for `body_L`. `seam_clr` and `seam_lap` are the only new parameters.

**Parts (5):**

| part | role | print orientation | filament (PrusaSlicer) |
|---|---|---|---|
| body_R | wedge half with the tongue; through the door; outer bottom flange bears on bars below the opening | end wall on bed, seam up (tongue is the top 6 mm) | 108 g, 8.8 h |
| body_L | wedge half with the pocket | end wall on bed, seam up (outer skin stops 6.2 mm below the top) | 100 g, 8.2 h |
| lid | slides out (away from cage) to refill; headboard bears on bars above/beside the opening and is the body's inward stop | flat, headboard up | 51 g, 4.4 h |
| bracket | inside the cage: plate bears on bars, window edges sit in grooves in the body end walls (Y-lock), shelf + guide rails + front ridge for the tray, perch | on its X end (perch = vertical column) | 112 g, 7.7 h |
| tray | removable, hull lip on front and sides; slides in from the cage side over the ridge (lift front 7 mm) | floor down | 70 g, 6.6 h |

**Mounting / assembly:** slide the two halves together on the lap (tongue into pocket, 0.2 mm play) and push them through the door opening from outside, seam vertical; from inside drop the bracket down over the body so its window edges enter the vertical grooves in the end walls (grooves at Y 0–3.6, plate at Y 0.3–3.3, bars sandwiched between the lid headboard / bottom flange at Y ≤ −2.5 and the plate); slide the lid in from outside until it hits the stop lip; slide the tray onto the shelf. Outward pull (bird) → grooves push the plate against the bars. Inward push (human) → stop lip → lid headboard → bars, plus bottom flange → bars. Lid opens only by sliding outward, outside the cage. Nothing smaller than a 129 × 48 mm plate is detachable; there are no screws, pins or glue.

## (b) Steps taken, including dead ends

1. Restructured the source so the whole body is one `body()` and a half is `body()` cut by a seam shape, then wrote the lap as a 2D cross-section feature applied over a length in X. A plain minimum-distance check between the halves could not serve as the seam-gap check: at the tongue's root a 0.2 mm step faces down a 6 mm channel, so a ray across the seam reads 6.3 mm there, and the Euclidean closest-point distance reads 0.28 mm at re-entrant corners. The check that measures what matters (can anything wider than the clearance sit anywhere in the void) is the widest square that fits in the seam void, from a 0.01 mm raster of the two halves' sections.
2. First lap put the flange's outer half on the tongue and its inner half on the pocket side; the wall's tongue then rested on the flange's inner half with zero clearance (manifold reported a 5e-5 mm³ contact). Moved the whole flange to the tongue side.
3. The pocket cutter's outer boundary coincided with the body's outer face and CGAL left a zero-thickness sheet on `body_L` (one internal face, +1460 mm² of surface). The cutter now extends 1 mm past the outer face.
4. The flange's rectangle in `seam_lap` swept up into the back wall where the wall crosses the flange's Y range, making the wall's tongue full-thickness for a few mm of height. Bounded it by the wall's outer face, the same half-plane that trims the flange itself.
5. Section renders of a CSG intersection in preview mode show z-fighting; the seam figure is a full `--render`.

## (c) Final dimensions, part list, capacity

Coordinates: X across the door, Y through it (negative = outside cage, bars at Y ∈ [−2.5, 0]), Z up, Z = 0 at the outlet, seam plane at X = 0.

- Hopper interior: width 130, height 120 (usable to 116.7 under the lid), depth 50 at the outlet → 101.9 at the top; back wall at **66.2°** from horizontal, front wall vertical, end walls vertical and parallel (plane flow, no convergence in X). Unchanged from fable.
- Seam: lap 6 mm, clearance 0.2 mm; tongue 1.0 mm, inner skin under the pocket 1.2 mm; the tongue's tip is at X = −6.0, the pocket's floor ends at X = −6.2, the inner skins end at X = ±0.1.
- Outlet slot: **50.2 × 130 mm**, full width, at Z = 0; tray floor 10 mm below it.
- Through-section in the bar plane: **134.8 × 117.0 mm** in a 140 × 170 door.
- Capacity: **1.145 L** by boolean (interior prism minus both halves), 1.147 L analytic.
- Per-part bounding boxes (mm): body_R 73.4 × 109.1 × 161.2 (the tongue adds 6 in X), body_L 67.3 × 109.1 × 161.2; lid 165.4 × 52.2 × 44.2; bracket 165.4 × 113.8 × 59.0; tray 144 × 100 × 30. Largest axis 165.4 < 175.
- Walls: 2.4 mm plates everywhere on the body, lid and tray, except the lap skins (1.0 / 1.2 mm over the 6 mm lap); bracket plate 3.0; lid headboard 4.0 + 2.4; perch Ø16 solid.
- Tray and perch unchanged from fable.

Files: `hopper.scad` (source; `part=` selects; `part="seam"` is the exploded seam section), `out/` (STL + preview per part, written by the root `./build`), `render_png.sh` + `crop.py` (the `img_*.png` figures), `verify2.py` + `thick.py` (checks; output `verify.json`, plus `print_<part>.stl` in print orientation), `slicer.ini` + `slice.sh` (slicer dry run over `print_*.stl`; output `slice.log`; the G-code is regenerated locally and not committed).

## (d) VERIFICATION

Every number below is copied from `verify.json` (`python3 verify2.py > verify.json` on the STLs in `out/`) or `slice.log`. `verify2.py` asserts the seam checks and the clash check and exits non-zero on failure. Sampling: 8000 surface points per part.

**Seam gap vs 0.2 mm clearance:** five sections through the seam, each perpendicular to the wall it cuts (front wall at Z = 60, back wall at Z = 60 in the plane normal to the 66° wall, roof at Y = 20, stop lip at Z = 118, flange at Z = −20), each rasterised at 0.01 mm with both halves in assembly position; the widest axis-aligned square that fits in the void between the halves is **0.20 mm in every section** (asserted ≤ 0.22). Inner-skin butt gap at Z = 60: 0.2 mm; lap overlap (tongue tip to inner-skin end): 5.9 mm (asserted ≥ 5.8). Falsified in a scratch copy of this directory: `body_L` shifted 1 mm away from `body_R` → `AssertionError: seam void wider than seam_clr=0.2: widest square by section {… 1.2 …} mm`; shifted 1 mm towards it → `AssertionError: assembly clash {'body_R∩body_L': 683.117, …}`; restored → exit 0 with a byte-identical `verify.json`.

![exploded section through the back wall at Z = 50–60: pocket half left, tongue half right](img_seam.png)

**Mesh validity** (trimesh, after `merge_vertices`): all five parts `watertight: true`, `winding_consistent: true`, Euler number 2, zero internal faces, positive volumes. The interior cavity boolean is also watertight.

**Bounding box vs 175 mm:** extents above; `max_extent_ok_175: true` for every part.

**Wall thickness vs 2.4 mm** (inward ray from each sampled point, min hit distance; samples within 1 mm of a convex edge are reported separately because a ray next to an edge measures the corner, not the wall):

| part | median | samples < 2.4 (all) | < 2.4 and > 1 mm from any convex edge | min there | those points |
|---|---|---|---|---|---|
| body_R | 2.4 | 296 / 8000 | 210 | 1.0 | the tongue (1.0 mm by design), all at X ∈ [−6, 0] |
| body_L | 2.4 | 363 / 8000 | 269 | 1.2 | the inner skin under the pocket (1.2 mm by design), all at X ∈ [−6.2, 0] |
| lid | 6.4 | 0 | 0 | — | — |
| bracket | 3.0 | 42 | 4 | 1.07 | tips of the 1.2 mm tray guide rails |
| tray | 2.4 | 13 | 10 | 2.33 | front corners where the 45° lip underside and the 1.2 mm bottom chamfer meet the r=6 corner arc |

So: every plate outside the lap measures 2.4 or more; the lap skins are the stated 1.0 / 1.2 and together with the 0.2 mm gap make up the 2.4 mm wall.

**Capacity vs 1 L:** cavity boolean 1.145 L (prism Y −49.1…57.4, Z 0…116.7 minus both halves, manifold engine), analytic 1.147 L. Unchanged: the lap lives inside the wall thickness.

**Slot width vs 50 mm:** section of both halves at Z = 0.5: back-wall inner face to front-wall inner face = **50.22 mm**; interior depth at Z = 50 is 72.1 mm.

**Wall angle vs 60°:** every upward-facing face inside the cavity is at **66.2°** from horizontal, total area 17207 mm² (the back wall, now including the lap channel's faces on it). No other interior face faces upward.

**Fit to 140 × 170 with 12 mm bars:** the body sliced to the bar-plane slab Y ∈ [−2.5, 0] has bounding box 134.8 × 117.0 → `fits_140x170: true`. Bearing overlaps as in fable (each ≥ one bar pitch). Not verified: an actual cage.

**Assembly clash check:** pairwise manifold booleans of all 10 part pairs in assembly position: every intersection volume **0.0 mm³**, `body_R ∩ body_L` included.

**Printability:** per part, in the shipped print orientation (`print_*.stl`), the area of downward-facing faces off the bed by overhang angle:
- body halves: only the 434 mm² "flat ceiling" = the roof of the 3.6 mm-wide bracket groove on the bed face (a 3.6 mm bridge); no other overhangs. The lap adds none: the tongue is a 1.0 mm wall rising 6 mm above the rest of body_R (height 73.4 mm), the pocket is body_L's outer skin stopping 6.2 mm below its top (height 67.3 mm).
- lid: 417 mm² of ceilings, all bridges ≤ 6.4 mm wide.
- bracket: 133 mm² flat (rail undersides and stubs), 177 mm² at 30–45°, 74 mm² at 45–60°. Height 165.4 mm; needs a brim.
- tray: only 30–60° overhangs (hull-lip undersides and bottom chamfer).
- **PrusaSlicer dry run** (`slice.sh`, PETG 250/70 °C, 0.2 mm layers, 3 perimeters, 20% gyroid, supports OFF, bed 180 × 180): all five parts sliced without error or warning. Times 8.8 / 8.2 / 4.4 / 7.7 / 6.6 h, hand-written profile, indicative only.

**Not verified / known gaps (plain statement):**
- No physical print, no physical cage; the 0.2 mm lap clearance and the 1.0 mm tongue (two or three PETG perimeters) are untested on an A1 mini.
- "Rounded edges" is only partly met: tray vertical corners r = 6, bracket plate corners r = 4, perch round; the body halves and lid are square-cut 2.4 mm plates.
- Lid has no detent; it is held closed by friction, gravity, and being outside the cage. Tray retention is a 7 mm ridge.
- Flow of dried banana was reasoned (slot 2× slice width, 66° wall, plane flow, layers along flow), not simulated or tested.
- The bracket's 62 mm-tall plate is a lone 3 mm wall in print; it may need a brim and slow first layers.
