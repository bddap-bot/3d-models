# Infant medicine dose dial

Directive (verbatim): "This print turned out great. Two changes for next version:
- Add am and pm labels across from eachother.
- The numbers are offset from the holes so its unclear which number represents which hole. Shift the numbers a tad so they appear next to holes instead of between them."

## Revision 4 geometry

The support-free body remains a 126 mm diameter disc with a flat bottom and a 14 mm thick ring area. Its single ring retains 24 positions at a 47 mm radius, with 12 mm deep self-centering sockets tapering from 8.6 mm at the surface to 4.5 mm at the floor. The 77 × 41 × 7 mm stadium pad, two 35 mm diameter by 5 mm deep wells, 2 mm socket and well floors, socket radius, numeral radius, and all frozen dimensions are unchanged from revision 3.

Each blue and green numeral moved angularly by 7.5° from the gap between sockets onto the exact radial centerline of its own socket. Numeral radius, 6 mm glyph height, 0.3 mm outline, 1 mm relief, bold face, tangential orientation, and colors did not change. The source asserts that every numeral angle equals its corresponding socket angle within 0.01°.

## AM and PM labels

AM is centered at 7.5°, the midpoint of the blue 1–12 run, and PM is centered at 187.5°, the midpoint of the green run. Their center angles are asserted to be diametrically opposite within 0.01°. Both labels use bold Liberation Sans at 7.3 mm text size, whose 5.02 mm cap height exceeds 5 mm. The 0.3 mm outline produces at least 1.2 mm strokes, and their 1 mm relief matches the numerals. AM is blue and PM is green.

The labels fit inside the socket ring at a 33.5 mm radius, so the numeral band and the 126 mm plate did not widen. Each label is enclosed conservatively by a 12.5 × 6.2 mm bounding box. Assertions test each box against all 24 socket openings, the exact rotated pad footprint, and both 34.5 mm bottle envelopes. Minimum clearances are 3.19 mm to a socket, 6.75 mm to the pad, and 13.81 mm to a bottle, all exceeding the required 1.5 mm.

## Pad rotation and loaded view

The AM–PM axis is 7.5°/187.5°. The stadium's long axis is rotated to 97.5°, exactly perpendicular to that axis, placing the wells across the two 12/1 boundaries. The pad, wells, modeled bottles, and all their dimensions are otherwise unchanged. The loaded render places six syringe cylinders with flanges in the sockets nearest that long axis, at 75°, 90°, 105°, 255°, 270°, and 285°.

`img_top4.png` is the true-scale orthographic top presentation at 10 pixels per millimeter across the 126 mm body, with a slight lighting tilt that preserves the socket contours. At 1:1, all 24 sockets are visible, each numeral is unambiguously centered on its socket, and AM and PM are readable in their AMS colors. `img_oblique4.png` and `img_loaded4.png` use the same color-preserving `assembly()` scene and the same `render` entry point.

## Print plan

The A1 mini plate uses the 0.20 mm standard profile, three walls, 15% sparse infill, and no supports. Logical extruder 1 is tan PLA, logical extruder 2 is blue PLA, and logical extruder 3 is green PLA; they map to AMS slots 2, 1, and 4. Slot 3 PETG is unused. The revision-4 slice estimates 2 h 44 m 39 s and 71.90 g tan, 0.42 g blue, and 0.77 g green, 73.09 g total.

## Changes and fit risks

Only the requested numeral alignment, AM/PM labels, and required pad assembly rotation changed from revision 3. The disc, socket count and geometry, pad and well geometry, floors, printable bottom, materials, and colors remain frozen. No diameter increase was required. Open fit risks remain package molding and label thickness, syringe nose taper, first-layer expansion, and printer-specific XY compensation. The 0.5 mm diametral bottle clearance remains intentionally close; test the exact bottles and syringes before routine use.
