# Infant medicine dose dial

Directive (verbatim): "That model has issues. Kill the print job. I'll clear the print bed later for a reprint. In the meantime, many of the holes are covered, they'll need some clearance to fit those syringes. Let's make those holes a little deeper too to be safe. They look shallow."

## Revision 3 geometry

The support-free body is a 126 mm diameter disc with a flat bottom. The ring area is 14 mm thick. Its only socket ring has 24 positions at a 47 mm radius. The central bottle pad is a 77 × 41 mm stadium, 7 mm above the disc, and follows the compact rounded shape visible in the photograph. Its two 35 mm diameter wells are 5 mm deep, have 0.5 mm diametral clearance around the modeled 34.5 mm bottle bodies, and retain a 3 mm outside rim and 2 mm floor.

The 126 mm diameter is set by the outside numeral band: a 47 mm socket radius, 7 mm barrel radius, 1.5 mm required gap, 3.3 mm radial numeral half-height and outline, and a small outside edge margin. The pad alone would not require a disc this large. The result remains below the 140 mm cap.

## Socket clearance proof

Each blind socket is a 12 mm self-centering cone, 8.6 mm at the disc surface and 4.5 mm at its floor. The 14 mm disc leaves exactly 2 mm of tan below every socket. A 6 mm syringe nose enters the cone while its 14 mm barrel stands above the surface; the context model also includes the 20 mm top flange at 90 mm.

The source evaluates all 24 socket centers with OpenSCAD `assert` statements. For each position it computes planar clearance from the 14 mm barrel envelope to the exact stadium footprint, both 34.5 mm bottle envelopes, and the conservative inner edge of the complete numeral band. The minimum is 1.5 mm, occurring at the pad ends and numeral band. The nearest bottle clearance is 4.75 mm. The flange is above the 74 mm bottles and the 1 mm numerals, so it has no vertical intersection with either.

## Photo reading and labels

The photograph shows one ring of 24 holes. The apparent second ring in revision 2 was the central pad covering those inner holes. The two syringe tips in the photograph terminate in front ring holes; their tall barrels project inward in perspective. No distinct parking sockets are visible in the pad, so this model adds none.

The outside labels are blue 1–12 for AM and green 1–12 for PM. Bold Liberation Sans glyphs are 6 mm high with a 0.3 mm outline expansion, giving at least 1.2 mm strokes, and are raised 1 mm. `img_top3b.png` is a straight-down orthographic view rendered at 10 pixels per millimeter across the 126 mm body (0.1 mm per pixel). The shared `render` entry point sends the top, oblique, and loaded views through the same color-preserving `assembly()` scene, and the body keeps the disc and pad differences separate so the top view cannot lose raised detail to coplanar preview ordering.

## Print plan

The A1 mini plate uses the 0.20 mm standard profile, three walls, 15% sparse infill, and no supports. Logical extruder 1 is tan PLA, logical extruder 2 is blue PLA, and logical extruder 3 is green PLA; they map to AMS slots 2, 1, and 4. Slot 3 PETG is unused. The slice estimates 2 h 42 m 32 s and 71.91 g tan, 0.33 g blue, and 0.67 g green, 72.91 g total.

## Changes and fit risks

Revision 3 deletes the obstructed inner ring, replaces the tall rectangular platform with the minimal 7 mm stadium pad, moves the remaining sockets to a clearance-proven radius, deepens them from 8 to 12 mm, thickens the socket floor to 2 mm, and adds new revision-3 renders including six worst-axis syringe envelopes. Open fit risks are package molding and label thickness, syringe nose taper, first-layer expansion, and printer-specific XY compensation. The 0.5 mm diametral bottle clearance is intentionally close; test the exact bottles and syringes before routine use.
