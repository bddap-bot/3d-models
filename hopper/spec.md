Design task, self-contained. No workflow and no tools are prescribed: choose whatever approach you judge best and say why. Nothing is installed for you; `nix-shell -p <pkg>` (nixpkgs) is available for any tool you want, no sudo, no system-wide installs.

Build a print-ready, parametric seed hopper for a green-cheek conure, printed on a Bambu Lab A1 mini (180 mm cube bed, PETG). It mounts in a standard birdcage door opening and must not clog on dried banana slices.

Requirements (defaults stand):
- Door opening 140 x 170 mm, 12 mm bar spacing; the hopper occupies the door opening; that door need not open.
- Capacity about 1 litre (10-day refill).
- Seed mix contains dried banana slices, about 25 mm diameter, 3-6 mm thick, sticky: wedge (plane-flow) hopper, full-width slot outlet at least 2x slice width, walls at least 60 degrees from horizontal, no converging funnel, print orientation with layer lines along the flow.
- Refill from OUTSIDE the cage without opening it; lid the bird cannot open from inside.
- Bird-safe: PETG, walls at least 2.4 mm, rounded edges, no detachable small parts.
- Removable feed tray with a hull lip; integrated perch below the tray.
- Every part at most 175 mm on each axis, minimal supports.

Deliverables, all under OUT=__OUT__ (create it; if that path is not writable in your environment, use a directory under your working directory and name it in the result):
1. One STL or 3MF per part, plus the source (script, CAD file, parameters) that generates them.
2. At least one rendered image of the assembled model and one per part (any renderer).
3. REPORT.md: (a) the approach and tools you chose and why; (b) the steps you actually took, including dead ends; (c) final dimensions, part list, estimated capacity; (d) VERIFICATION, the section that matters most: exactly how you checked your own work, with the commands you ran and their outputs: mesh validity (watertight/manifold), bounding box per part vs 175 mm, wall thickness vs 2.4 mm, capacity vs 1 L, slot width vs 50 mm, wall angle vs 60 degrees, fit to 140x170 with 12 mm bars, printability (overhangs, supports; a slicer dry-run if you used one). Anything you did not verify, say so plainly; do not claim a check you did not run. (e) wall time, start to finish.

Constraints: budget 90 minutes of wall time, then deliver whatever exists and mark what is missing. Do not commit to any git repository, do not open or comment on issues, do not message anyone. No code comments in generated source beyond a why the code cannot show.

Result (first line): `DELIVERED: <n> parts, watertight <yes/no/partial>, tools: <list>, wall <min>` or `NOT DELIVERED: <why>`. Then the OUT path and the file list.
