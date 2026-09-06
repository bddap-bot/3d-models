# Infant medicine dose dial

Directive (verbatim): "That medication organizer that was printing on rainbows way bigger than I expected. I canceled the print job. Have a worker re-examine The source image and note these are small medication bottles. Should be able to see the brand names. We don't need separate pegs. The syringes pictured are what go in the clock holes."

## Photo scale and geometry

The source photograph identifies 1 fl oz / 30 mL Infants' TYLENOL and Infants' MOTRIN Concentrated Drops bottles. DailyMed's current product records confirm both 30 mL presentations and their enclosed dosing syringes: [TYLENOL NDC 50580-433](https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=2143cc16-86db-4060-96da-5c228ae9207b) and [MOTRIN NDC 50580-198](https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=c57f6ded-c0bd-45ae-823a-4c02ce334d98). The [TYLENOL package artwork](https://dailymed.nlm.nih.gov/dailymed/getFile.cfm?setid=2143cc16-86db-4060-96da-5c228ae9207b&type=pdf) includes a side-panel actual-size bottle view. Measuring that scale reference gives approximately 34.5 mm across the cylindrical body and 74 mm to the cap top; those dimensions are used here rather than the much larger revision-1 visual assumption.

Measured on the source image at the shared front plane, the dial is about 3.13 bottle-body widths across. Using the 34.5 mm body ruler gives 107.99 mm, rounded to a 108 mm modeled diameter. The same image reading places the two socket rings at about 0.31 and 0.40 dial diameters in radius, represented by 34 and 43 mm radii. The socket mouth is about one quarter of a bottle width, represented by 8.6 mm. The numeral cap height is about 0.17 bottle width, represented by 6 mm.

The body is a 108 mm diameter × 10 mm disk with a flat bottom. Its raised 76 × 50 × 14 mm platform holds two 35 mm diameter × 5 mm deep bottle wells. A 34.5 mm bottle therefore has 0.5 mm diametral clearance. Overall height is 24 mm, and every surface prints without support.

## Syringe sockets and ring reading

There are no separate markers. The bundled 5 mL oral syringes are the markers and stand tip-down in the selected clock sockets. Each of the 48 blind sockets is an 8 mm deep cone, 8.6 mm at the surface tapering to 4.5 mm at its floor. That range accepts the approximately 4–6 mm nose while the broad mouth guides either approximately 12–14 mm barrel toward center; the blind floor and cone support a syringe upright without depending on a precise press fit.

The photograph supports two complete concentric rings of 24 positions. Each ring is numbered 1–12 twice around the day: blue is AM and green is PM. The inner ring provides an independent last-dose position for one medicine and the outer ring for the other, so both bottles can be tracked without resetting or sharing a socket.

## Legibility and color

The 24 rim labels use 6 mm bold Liberation Sans glyphs with a 0.3 mm outline expansion, producing at least 1.2 mm strokes, and 1 mm raised relief. This is the largest type that keeps two-digit labels inside the 108 mm rim while clearing the outer sockets. `img_top2.png` is rendered at exactly 10 pixels per millimeter: its 1080-pixel body diameter corresponds to the true 108 mm print, allowing legibility to be judged at a known scale rather than by an arbitrary zoom.

Logical extruder 1 is the tan body, logical extruder 2 is blue AM type, and logical extruder 3 is green PM type. They map to AMS slots 2, 1, and 4. All used slots are PLA; slot 3 PETG remains unused.

## Print plan

The single support-free A1 mini plate is sliced at 0.20 mm layer height, three walls, and 15% sparse infill. Estimated print time is 2 h 36 m 36 s. Estimated filament is 59.46 g tan, 0.33 g blue, and 0.67 g green, 60.46 g total. The plate contains `T0`, `T1`, and `T2` changes and identifies the three used filaments as PLA in `#D3B7A7`, `#0085D5`, and `#057748`.

## Revision 2 changes and fit risks

Revision 2 reduces the body from 158 to 108 mm, removes all four peg solids and peg plate placements, changes the tracking holes into self-centering syringe sockets, reduces and reflows the platform around the small 30 mL bottles, and replaces all three shipped views with newly named revision-2 renders. The open fit risks are the exact bottle molding and label thickness, syringe nose taper, first-layer dimensional expansion, and printer-specific XY compensation. The 0.5 mm diametral well clearance is intentionally modest; test one bottle and one syringe before committing to a long unattended print.
