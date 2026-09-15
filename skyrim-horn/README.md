# Skyrim-inspired tea-light horn

An original, smooth curved horn candle holder and separate wall bracket sized for a standard 39 × 16 mm tea-light. The faceted plate, dark ring, and long rising horn evoke a Nordic fantasy prop without reproducing a specific product.

## Design note

The simplest reliable assembly is two parts: a support-friendly solid horn with a generous candle socket, and a wall mount that combines an octagonal plate, straight arm, and captive ring. The horn drops into the 53 mm ring from above. Its 51–52 mm lower guide passes through with at least 0.5 mm radial clearance, then a 56 mm seating flange rests on the ring. The 40.8 mm socket leaves at least 5.6 mm of radial PLA at the rim and a 14 mm floor over the curved core. Use only metal-cupped tea-lights, never leave a flame unattended, and substitute an LED tea-light where heat or supervision is a concern.

The 7 mm plate has two 4.8 mm through holes on its visible centerline, 62 mm apart. Each has a 9.6 mm countersink for a flush #6 or #8 wood-screw head. The upper exposed bore can instead rest on one stout, correctly anchored nail for the screwless display option; two screws are the stable installation.

## Printing and assembly

Print the horn upright with its mouth on the build plate and supports under the rising curve. Print the mount on its flat back with supports under the arm and ring. Defaults target PLA, a 0.4 mm nozzle, 0.20 mm layers, four perimeters, 20% gyroid infill, and the Bambu A1 mini 180 × 180 mm bed. Insert the horn down through the bracket ring after mounting the plate.

`./render.sh` creates a candle-loaded still and a 36-frame turntable GIF. `./slice.sh` creates an editable 3MF and independent PrusaSlicer estimates. `./slice-a1-mini.sh`, run with OpenSCAD, jq, OrcaSlicer, and xvfb available, creates the native A1 mini `.gcode.3mf` with supports.

The final native A1 mini PLA slice estimates 3 h 51 m 47 s of model printing, 3 h 57 m 21 s total, and 104.47 g of filament. The 3MF places both correctly oriented parts on one 180 × 180 mm plate.

## Critic review

Round 1: 5.7/10. The independent critic found that an unnecessary arm boss intruded into the ring opening and that the retention description named the wrong feature. The boss was removed, the arm now ends at the outer ring wall, and the description now identifies the flared mouth as the seating feature. Round 1 was rejected.

Round 2: 4.3/10. A stricter coordinate check found a 4 mm arm-to-plate gap, 1.5 mm of remaining bore intrusion, an ambiguous seat, and incorrect Z normalization on the combined print plate. The final revision overlaps the arm into both solids while ending 0.1 mm before the bore, adds a 56 mm flange directly above the ring, rotates the mount onto its plaque back, and gives both plate bodies an explicit Z=0 datum. Round 2 was rejected.

Round 3: 7.3/10. Horn readability and mechanical believability each scored 8/10, with the 0.1 mm bore clearance, 1.5 mm radial flange retention, two connected exported bodies, and Z=0 placement verified numerically. The generic toolpath crossed the bed only in its skirt/brim and did not identify an A1 mini machine profile, reducing printability to 6/10. The three-round cap was reached, so this best geometry was retained. The final mutation removes the out-of-bounds skirt/brim, overlaps the arm and plaque by 0.5 mm, and replaces the generic package with a successful native OrcaSlicer A1 mini profile slice with supports and no warnings.
