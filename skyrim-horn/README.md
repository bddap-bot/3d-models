# Skyrim-inspired tea-light horn

An original, smooth curved horn LED tea-light holder and separate wall bracket sized for a standard 39 × 16 mm tea-light. The hexagonal plate, dark ring, and long rising horn evoke a Nordic fantasy prop without reproducing a specific product.

## Design note

The simplest reliable assembly is two parts: a support-friendly horn and a wall mount made from a regular 104 mm hexagonal plaque, a centered 50 mm raised hexagon, a straight arm, and a captive ring. The horn follows a 42-span Catmull-Rom curve through its original eight stations, with its radius interpolated on the same curve and a 72-sided cross-section. The arm starts at the raised hexagon's center and places the ring center 86 mm from the wall, matching the long-clearance proportions of the design reference. The horn drops into the 52.2 mm ring from above. Its 51–52 mm lower guide passes through with at least 0.1 mm radial clearance, then a 56 mm seating flange rests on the ring. The 40.8 mm socket leaves at least 5.6 mm of radial PLA at the rim and a 14 mm floor over the curved core. Use an LED tea-light only; PLA is not suitable for a live flame.

The 8 mm plaque has two 4.8 mm through holes on its visible centerline, 66 mm apart. Each has a 9.6 mm, 90° countersink for a flush #6 or #8 flat-head wood screw. Both screws are required for stable installation.

## Printing and assembly

Print the horn upright with its mouth on the build plate and supports under the rising curve, using tan PLA from the external spool. Print the mount separately on its flat back with supports under the arm and ring, using black PLA from one AMS slot. Defaults target a 0.4 mm nozzle, 0.20 mm layers, and the Bambu A1 mini 180 × 180 mm bed. Insert the horn down through the bracket ring after mounting the plaque.

`./render.sh` creates an LED-tea-light-loaded still and a 36-frame turntable GIF. `./slice.sh` creates an editable combined 3MF and independent PrusaSlicer estimates. `./slice-a1-mini.sh`, run with OpenSCAD, jq, OrcaSlicer, and xvfb available, creates separate native A1 mini `.gcode.3mf` files for the horn and mount, each with normal auto supports.

The horn plate uses tan PLA from the external spool and estimates 2 h 26 m 48 s model time, 2 h 32 m 22 s total, and 60.67 g. The mount plate uses black PLA from one AMS slot and estimates 2 h 18 m 53 s model time, 2 h 24 m 26 s total, and 47.63 g. The editable 3MF retains both correctly oriented parts for inspection, while the printer-ready packages separate the two colors.

## Critic review

The fixed visual rubric checks the reference mount language, longitudinal horn smoothness, printability, and wall clearance. The capped rounds scored 7.5, 7.7, and 7.7/10. Each critic recognized the hex plaque, raised center hex, centered long arm, ring, supported printability, and wall clearance, but the flat OpenSCAD rendering still exposes bands from the fixed 72-sided cross-section. Round 3 tied for best and is the final capped round; the renders and exact one-line reasons are in `proofs/rounds/`.
