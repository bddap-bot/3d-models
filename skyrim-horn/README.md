# Skyrim-inspired tea-light horn

An original, smooth curved horn LED tea-light holder and separate wall bracket sized for a standard 39 × 16 mm tea-light. The hexagonal plate, dark ring, and long rising horn evoke a Nordic fantasy prop without reproducing a specific product.

## Design note

The simplest reliable assembly is two parts: the unchanged support-friendly horn and a wall mount made from a regular 104 mm hexagonal plaque, a centered 50 mm raised hexagon, a straight arm, and a captive ring. The arm starts at the raised hexagon's center and places the ring center 86 mm from the wall, matching the long-clearance proportions of the design reference. The horn drops into the 52.2 mm ring from above. Its 51–52 mm lower guide passes through with at least 0.1 mm radial clearance, then a 56 mm seating flange rests on the ring. The 40.8 mm socket leaves at least 5.6 mm of radial PLA at the rim and a 14 mm floor over the curved core. Use an LED tea-light only; PLA is not suitable for a live flame.

The 8 mm plaque has two 4.8 mm through holes on its visible centerline, 66 mm apart. Each has a 9.6 mm, 90° countersink for a flush #6 or #8 flat-head wood screw. Both screws are required for stable installation.

## Printing and assembly

Print the horn upright with its mouth on the build plate and supports under the rising curve, using tan PLA from the external spool. Print the mount separately on its flat back with supports under the arm and ring, using black PLA from one AMS slot. Defaults target a 0.4 mm nozzle, 0.20 mm layers, and the Bambu A1 mini 180 × 180 mm bed. Insert the horn down through the bracket ring after mounting the plaque.

`./render.sh` creates an LED-tea-light-loaded still and a 36-frame turntable GIF. `./slice.sh` creates an editable combined 3MF and independent PrusaSlicer estimates. `./slice-a1-mini.sh`, run with OpenSCAD, jq, OrcaSlicer, and xvfb available, creates separate native A1 mini `.gcode.3mf` files for the horn and mount, each with normal auto supports.

The horn plate uses tan PLA from the external spool and estimates 2 h 25 m 43 s model time, 2 h 31 m 17 s total, and 60.18 g. The mount plate uses black PLA from one AMS slot and estimates 2 h 18 m 53 s model time, 2 h 24 m 26 s total, and 47.63 g. The editable 3MF retains both correctly oriented parts for inspection, while the printer-ready packages separate the two colors.

## Critic review

Round 1: 7.3/10. The horn silhouette scored 8/10 and A1 mini printability scored 8/10. The critic confirmed the requested hexagonal plaque, centered raised hexagon, centered long arm, and paired holes, but found that the countersinks had a 75.5° included angle and flagged the live-flame depiction. The countersinks were corrected to 90° and the presentation and guidance changed to LED-only. Round 1 was rejected.

Round 2: 7.8/10. Horn readability and mount credibility each scored 8/10. The critic found that the mount slice stood the plaque on edge, the arm-to-ring overlap was only 0.5 mm, and the per-plate estimates were missing from this note. The mount was rotated flat-back-down, its solid overlap with the ring increased to 4.3 mm without entering the bore, and both slice estimates were added. Round 2 was rejected.

Round 3: 8.3/10, pass. Horn readability scored 8/10, mount credibility 8.5/10, and A1 mini printability 8.5/10. The critic verified the 90° countersinks, 4.3 mm arm-to-ring overlap, retained seating flange, correct separate-part orientations, and supported A1 mini slices. Remaining cautions are support cleanup and the tight 0.1 mm nominal radial ring clearance; a physical fit and load test was not performed. This was the best and final capped round.
