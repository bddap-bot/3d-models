# Horn candle decoration

This print package uses `candle bottom.stl` and `candle top.stl` from MyMiniFactory object 490503 to make one complete decoration per plate. `repaired_candle top iron.stl` is an alternate top and is not used. Two identical plates produce two complete decorations.

Each plate is arranged for the 180 × 180 mm Bambu A1 mini bed and sliced at 0.20 mm with organic tree supports. The black PLA on the external spool uses a 65 °C textured PEI bed, 20 mm/s first-layer speeds, no fan for the first five layers, and a 5 mm outer brim.

`horn-candle-plate-1.png` and `horn-candle-plate-2.png` render the extrusion paths embedded in the corresponding OrcaSlicer printer-ready packages.

Run `nix-shell -p orca-slicer jq xvfb-run --run './horn-candle/slice.sh'` from the repository root to regenerate the printer-ready packages.
