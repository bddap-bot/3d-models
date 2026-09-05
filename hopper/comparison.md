# Comparison

Three lanes delivered (codex, fable, opus). The kimi lane is pending; its column is added when it lands.

**Nobody chose FreeCAD, screenshots, or a GUI.** Every model went OpenSCAD source → STL → a Python mesh check, and rendered with OpenSCAD under xvfb or with matplotlib. A prescribed FreeCAD-by-screenshot loop, tried earlier, was strictly worse than what each model reached on its own.

| | codex (gpt-5.6-sol) | fable 5.1 | opus 5 | kimi-k3 |
|---|---|---|---|---|
| wall | 7 min | 31 min | 75 min | pending |
| parts | 3 (body, lid, tray+perch) | 5 (2 mirror body halves, lid, bracket, tray) | 6 (mount plate, 2 shells, lid, tray, perch) | |
| tools | OpenSCAD, trimesh, PrusaSlicer 2.9.4, Xvfb | OpenSCAD, trimesh+manifold3d, PrusaSlicer | OpenSCAD, trimesh+manifold3d, xvfb/llvmpipe | |
| watertight | 3/3 (trimesh) | 5/5 + Euler 2, 0 internal faces | 6/6 (+ mount Euler −2 explained: 2 holes) | |
| capacity | 1.04 L (analytic polygon×width) | 1.145 L (boolean cavity, matches analytic 1.147) | 1.065 L (seed-column solid exported and measured) | |
| slot | 130×54 | 50.2 (section at z=0.5) | 118×70 (sections at 3 heights) | |
| wall angle | 75.4° (from source dims) | 66.2° (every upward interior face measured) | 65° (min over every downward cavity normal) | |
| wall ≥2.4 | **by arithmetic only** (nominal 3.0, oblique 2.83 computed by hand, not from mesh) | inward ray-march 8000 samples/part; sub-2.4 hits itemised (acute cuts, 1.2 mm rails) | 60k-sample ray-march; caveat: 6% of tray, ~1% of shell samples <2.4 at tangency seams, not all inspected | |
| fit 140×170 / 12 mm bars | flange exactly 140×170, dimensional | bar-plane section 134.8×117; every bearing ≥1 bar pitch | plate 156×162 overlaps 8 mm/side; hooks 7 mm between bars; modelled cage render | |
| assembly clash | not checked | 10 pairwise booleans, all 0 mm³ | pairwise, pass | |
| printability | PrusaSlicer dry-run: sliced, **long-bridge warnings → recommends supports** | PrusaSlicer dry-run, supports OFF, all 5 clean; per-part overhang audit | no slicer; overhang % per part (≤0.6%, tray 4.3%) | |
| layer lines along flow | body upright (claimed) | halves printed end-wall-down | shells split on midplane, side-wall-down (also zero-overhang walls) | |
| self-caught defects | none reported | back wall 1.6 mm mid-run, 3 clashes, U-arm ceiling redesign | orientation/split problem (35 min), 7 CGAL-manifold fixes | |
| stated gaps | no physical print/flow; supports needed; wall by calc not mesh | square-cut body/lid edges, no lid detent, butt seam | tray runs brim-full (0.6 mm discharge gap), no slicer, perch load unanalysed | |

## How each checked its work

- **codex**: one `validate.py` (trimesh watertight + bbox) plus arithmetic from the source parameters for capacity, slot, angle, walls; then a real PrusaSlicer dry-run per part. Cheapest and fastest, but the wall-thickness and angle "checks" are restatements of the inputs, not measurements of the output. The slicer run was the one check that actually pushed back (bridges), and it reported that honestly.
- **fable**: every requirement measured on the final STL, not the source: ray-march thickness with an edge-proximity filter, boolean cavity volume vs analytic, sections for slot and bar-plane fit, interior-face angle census, pairwise assembly booleans, overhang audit in the shipped print orientation, then a supports-off slicer run. Iterated: the checks found a 1.6 mm wall and three clashes and it fixed them.
- **opus**: same measurement-first stance with the largest sample counts, plus an exported seed-volume solid and a modelled cage for fit; no slicer. Most explicit about what it did NOT prove (tangency-seam samples, brim-full tray, no beak model). Spent the most time, most of it on the print-orientation/part-split problem.

Ranking by verification rigour: fable ≈ opus > codex. By time: codex ≪ fable < opus. Codex's 7-minute design is the one most likely to need a redesign after the first print (supports, unmeasured walls); fable's is the one that sliced clean support-free with measured walls.
