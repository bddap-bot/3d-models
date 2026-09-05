# Green-cheek conure plane-flow hopper

## Approach and tools

This is a three-part, top-loading plane-flow hopper sized to replace a 140 × 170 mm cage door. I used OpenSCAD because the dimensions and clearances remain directly editable in one short source file, OpenSCAD/CGAL for STL generation, trimesh for independent mesh inspection, and PrusaSlicer for a command-line FFF dry-run on a 180 × 180 mm bed. The design deliberately avoids a funnel, hinge, screws, magnets, and small removable pieces.

The hopper is a constant-width wedge. Its full 130 mm internal width never converges; only the front wall changes depth. The clear discharge is 130 × 54 mm. The external lid is a large press-fit cap with a rear stop and two retaining ears, unreachable by the bird from inside. The body flange fills the closed door aperture; four integral 3.6 mm lashing holes accept bird-safe stainless wire at the cage-frame side if the particular cage jamb needs retention. The large tray/perch part slides against the lower body stops, catches hulls in a rounded basin, and cannot be mistaken for a small ingestible part.

## Steps actually taken

Start: 2026-09-05 07:54:10 PDT. End: 2026-09-05 08:01 PDT. Wall time: about 7 minutes.

1. Set a four-solid concept, then simplified it to three solids by integrating the perch and tray.
2. Wrote `hopper.scad` with exposed dimensional parameters and per-part/assembly selectors.
3. Exported each part through OpenSCAD/CGAL. The first hand-authored prism had an invalid face orientation; I replaced it with a 2D polygon plus linear extrusion.
4. The first valid volume calculation was 1.394 L, larger than “about 1 litre.” I reduced the upper depth and obtained 1.042 L while increasing the flow angle.
5. Render attempts initially failed because OpenSCAD had no display. I installed Xvfb through nix-shell and rendered under a temporary virtual display.
6. Flipped the lid into its intended print orientation and changed the perch from a round cylinder to a support-friendlier 45-degree octagonal section.
7. Regenerated meshes and ran independent mesh checks and no-support slicer dry-runs.

Regenerate an STL with, for example:

```sh
openscad -o hopper_body.stl -D 'part="hopper_body"' hopper.scad
```

Valid `part` values are `hopper_body`, `lid`, `tray_perch`, and `assembly`. The exported hopper is intentionally on its side: layer planes then run through the front-to-back flow cross-section. The assembly selector displays it in service orientation.

## Final design

| Part | STL bounding box (mm) | Function |
|---|---:|---|
| hopper_body | 170 × 89 × 140 | 1.042 L reservoir, 140 × 170 flange, 130 × 54 outlet |
| lid | 140 × 85 × 11 | outside-only refill cap with retaining ears |
| tray_perch | 136 × 105 × 32.996 | removable rounded hull tray and integral 136 mm perch |

All axes are at most 175 mm, so every part fits the A1 mini's 180 mm cube. Use PETG, 0.4 mm nozzle, 0.20 mm layers, four perimeters, five top/bottom layers, and 15% infill. Print the supplied orientations. All nominal food-contact walls are 3 mm or more; the sloped front wall has a calculated worst perpendicular thickness of 2.83 mm at its upper end. Round external tray/lid edges are modeled at 2–4 mm radius. Wash PETG parts before use and inspect regularly for chewing damage.

The 12 mm bar pitch does not divide the 140 mm opening evenly and cage frame details vary, so the flange is intentionally continuous rather than depending on a particular bar phase. The 140 × 170 mm flange fills the stated opening exactly; confirm the real aperture and scale/edit `door_w`/flange clearance before printing if its measured opening is undersize.

## VERIFICATION

### Mesh, bounds, capacity, outlet, angle, wall, and fit

Command actually run:

```sh
nix-shell -p python3Packages.trimesh python3Packages.networkx --run 'python validate.py'
```

Final output:

```text
hopper_body: watertight=True winding=True components=1 bbox_mm=[170.0, 89.0, 140.0] max_mm=170.000
lid: watertight=True winding=True components=1 bbox_mm=[140.0, 85.0, 11.0] max_mm=140.000
tray_perch: watertight=True winding=True components=1 bbox_mm=[136.0, 105.0, 32.996] max_mm=136.000
analytic_capacity_L=1.0425
clear_outlet_mm=130.0x54.0 banana_ratio_min_dimension=2.16x
flow_wall_angle_deg_from_horizontal=75.353
minimum_nominal_wall_mm=3.0 requirement_mm=2.4
door_flange_mm=140.0x170.0 opening_mm=140.0x170.0 bar_pitch_mm=12.0
OVERALL=PASS
```

Capacity is the exact internal 2D polygon area times the constant 130 mm width: `130 × (55 × 49 + 88 × (49 + 72) / 2) = 1,042,470 mm³`, or 1.0425 L. It excludes the lid headspace. The front flow plane is `atan2(88,23) = 75.353°` from horizontal. The outlet's limiting dimension is 54 mm, 2.16 times a 25 mm banana slice. The constant width is 130 mm.

Wall thickness was checked analytically against source dimensions, not with a mesh wall-thickness heat map. Side and back walls are 3.0 mm; floor is 7 mm; lid rim is 3.2 mm and top is 4 mm; tray base is 6 mm. The nonparallel sloped front wall has the smaller 2.83 mm perpendicular separation at its upper endpoint. Thus the calculated minimum is 2.83 mm, above 2.4 mm. `validate.py` prints the conservative nominal parameter of 3.0 mm; it does not itself calculate the 2.83 mm oblique distance.

Fit was dimensional only: the exported service flange is exactly 140 × 170 mm and the body is 136 mm wide. Bar pitch was recorded as 12 mm and the four integral retention points lie at the flange edges, independent of pitch phase. No physical cage fit test was possible.

### Slicer dry-run and supports

Command actually run for each STL (with the part name substituted):

```sh
prusa-slicer --export-gcode --bed-shape 0x0,180x0,180x180,0x180 --center 90,90 --layer-height 0.20 --first-layer-height 0.20 --nozzle-diameter 0.4 --filament-diameter 1.75 --perimeters 4 --top-solid-layers 5 --bottom-solid-layers 5 --fill-density 15% --no-support-material --output PART.gcode PART.stl
```

All three completed with `Slicing result exported`. PrusaSlicer 2.9.4 also warned about floating bridge anchors/long bridges for the hopper and lid, and floating bridge anchors/long bridges for the revised tray. Therefore I do **not** claim support-free printing. Use painted build-plate-only supports beneath the hopper's far side skin and the small retaining/stop features; do not fill the reservoir. The primary 75.35° flow face and the octagonal perch use support-friendly angles. This was a generic 180 mm PrusaSlicer dry-run, not a Bambu Studio A1 mini PETG profile, and no physical print was made. G-code is supplied as dry-run evidence only; reslice the STL in Bambu Studio with the PETG manufacturer's temperature and flow calibration.

No physical banana flow test, bird-use test, pull test, food-safety certification, or tolerance test was performed. The anti-clog conclusion is geometric (54 mm minimum clear opening and no width convergence), not empirical.
