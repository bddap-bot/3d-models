# Infant medicine dose dial

Directive (verbatim): "Model me one of these. Slice for ams so the numbers are readable. Add it to rainbow's queue."

## Geometry

The support-free body is a 158 mm diameter, 8 mm thick disk with a 20 mm raised organizer, for a total height of 28 mm. The organizer has two 38 mm diameter × 5 mm deep bottle wells and two 13.5 mm through-holes. The two peg rings are at 53 mm and 63 mm radii, each with 24 positions at 15° and 4.2 mm diameter × 5 mm deep holes.

The wells use the nominal 36 mm bottle diameter with 1 mm clearance per wall. Manufacturer drug labeling confirms that both products are sold in 1 fl oz (30 mL) bottles with enclosed syringes, but does not publish container diameter; the nominal diameter and 12.5 mm syringe barrel measurement therefore remain the fit-critical measurements to verify on the exact packages. The through-holes provide the syringe barrels the full 28 mm depth and avoid an unsupported blind-hole roof.

Each peg has a 4.35 mm diameter × 8 mm shank and a 7 mm diameter × 3 mm cap. The 0.15 mm diametral interference against the 4.2 mm hole is intended as a finger-pressure PLA fit. Four pegs are included, two per time color.

## Legibility and color

The 24 rim labels are 9 mm high bold Liberation Sans glyphs with a 0.35 mm outline expansion and 1 mm raised relief, arranged as blue 1–12 and green 1–12. The outline expansion keeps glyph strokes at least 1.6 mm in the exported meshes. `img_top.png` frames the full 158 mm part at 10 pixels per millimeter so the shipped-size type can be judged without enlarging the model.

The project uses logical extruder 1 for the tan body, 2 for blue AM numbers and pegs, and 3 for green PM numbers and pegs. The print mapping is logical extruders 1,2,3 to AMS slots 2,1,4. All three are PLA; slot 3 PETG is unused.

## Print plan

The disk and all four pegs fit one A1 mini plate. The slice uses the 0.20 mm standard profile, three walls, 15% sparse infill, and no supports. OrcaSlicer uses the A1 mini purge mechanism and leaves its prime tower disabled for this geometry. Estimated print time is 5 h 54 m 28 s. Estimated filament is 99.80 g tan, 1.33 g blue, and 4.29 g green, 105.42 g total.

## Reference deviation

The reference has a gray body, a tighter asymmetric organizer, smaller colored type, and differently colored medicine accessories. This version follows its two-ring last-dose tracking function but uses the requested tan/blue/green palette, symmetric wells, separate syringe holes, larger readable numerals, and four matching pegs.
